#!/usr/bin/env bash
#############################################################################
#  This file is part of: HudMod Video Editor                                #
#  https://omar-top.itch.io/hudmod-video-editor                             #
# ------------------------------------------------------------------------- #
#  Copyright © 2026 Omar Mohammed Balita.                                   #
#  This program is free software: you can redistribute it and/or modify it  #
#  under the terms of the GNU General Public License as published by the    #
#  Free Software Foundation, either version 3 of the License, or (at your   #
#  option) any later version.                                               #
#############################################################################
#
# build_deb.sh - Build the HudMod .deb package for Linux (x86_64).
#
# The script:
#   1. Locates (or downloads) a Godot 4.7 editor + Linux export templates.
#   2. Builds the native HudMod-GDExtension library from source
#      (Godot-cpp + FFmpeg), or uses a prebuilt one if provided.
#   3. Exports the Godot project for Linux (x86_64).
#   4. Stages and packages everything into a Debian .deb file.
#
# Requirements: curl/wget, unzip, tar, ar, python3, g++, git, scons
# (scons is installed automatically into a local venv if not present).
#
# Usage:
#   ./packaging/build_deb.sh                # builds with defaults
#
# Optional environment variables:
#   GODOT_BIN     path to a Godot editor binary (otherwise auto-downloaded)
#   VERSION       Debian package version (default: 1.0.0~alpha.2)
#   ARCH          package architecture (default: amd64)
#   BUILD_DIR     scratch directory (default: /tmp/hudmod-build)
#   DIST_DIR      output directory for the .deb (default: ./dist)
#   GDExtENSION_SRC  path to a HudMod-GDExtension checkout (optional)
#   GDExtENSION_BIN  path to prebuilt linux64 dir containing
#                    libhudmod.linux.template_release.x86_64.so (optional)
#
#############################################################################

set -euo pipefail

# ---------------------------------------------------------------- config ---
VERSION="${VERSION:-1.0.0~alpha.2}"
ARCH="${ARCH:-amd64}"
GODOT_VERSION="${GODOT_VERSION:-4.7.1-stable}"
GODOT_REPO_VERSION="4.7.1"
PACKAGE_NAME="hudmod"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-/tmp/hudmod-build}"
DIST_DIR="${DIST_DIR:-$PROJECT_ROOT/dist}"
WORK_DIR="$BUILD_DIR/work"
STAGE_DIR="$BUILD_DIR/pkg"
DOWNLOAD_DIR="$BUILD_DIR/downloads"

GODOT_URL_BASE="https://github.com/godotengine/godot/releases/download/$GODOT_VERSION"
GDExt_REPO_URL="https://github.com/OmarBalita/HudMod-GDExtension.git"
GDExt_RELEASE_URL="https://github.com/OmarBalita/HudMod-GDExtension/releases/download/alpha/linux64.zip"
GODOT_CPP_PIN="9e0650a0ae806367854d50342c4751690a09d521"
FFMPEG_TAR_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-linux64-gpl-shared-8.1.tar.xz"

GODOT_BIN="${GODOT_BIN:-}"
GDExtENSION_SRC="${GDExtENSION_SRC:-}"
GDExtENSION_BIN="${GDExtENSION_BIN:-}"
# Directory containing versioned FFmpeg shared libraries (libavformat.so.62 etc.)
# used so the editor can load the GDExtension during import/export. If empty, a
# best-effort search is done against the GDExtension source tree and $gdext_dir.
FFMPEG_LIBDIR="${FFMPEG_LIBDIR:-}"

# FFmpeg libraries that get bundled into the package.
FFMPEG_LIBS=(libavcodec libavformat libavutil libswscale libswresample
             libavfilter libavdevice libpostproc)

log()  { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------- setup dirs ---
mkdir -p "$WORK_DIR" "$DOWNLOAD_DIR" "$DIST_DIR"

# ------------------------------------------------------------- toolchain ---
have curl || have wget || err "curl or wget is required"
have unzip || err "unzip is required"
have tar || err "tar is required"
have ar || err "ar (binutils) is required to build .deb files"
have git || err "git is required"
have python3 || err "python3 is required"
have g++ || err "g++ is required to build the GDExtension"

# scons: use a venv if not available on PATH
if have scons; then
	SCONS="scons"
else
	log "scons not found; installing into a local virtualenv..."
	VENV_DIR="$BUILD_DIR/venv"
	if [ ! -x "$VENV_DIR/bin/scons" ]; then
		python3 -m venv "$VENV_DIR" || err "could not create python venv"
		"$VENV_DIR/bin/pip" install --quiet scons || err "could not install scons"
	fi
	SCONS="$VENV_DIR/bin/scons"
fi

# ---------------------------------------------------------------- godot -----
godot_bin_path() {
	if [ -n "$GODOT_BIN" ]; then
		[ -x "$GODOT_BIN" ] || err "GODOT_BIN is not executable: $GODOT_BIN"
		echo "$GODOT_BIN"
	elif have godot4; then
		echo "$(command -v godot4)"
	elif have godot; then
		echo "$(command -v godot)"
	else
		local zip="$DOWNLOAD_DIR/godot_editor.zip"
		local exe="$WORK_DIR/godot-editor/Godot_v${GODOT_VERSION}_linux.x86_64"
		if [ ! -x "$exe" ]; then
			log "Downloading Godot editor $GODOT_VERSION..."
			curl -L --fail -o "$zip" \
				"$GODOT_URL_BASE/Godot_v${GODOT_VERSION}_linux.x86_64.zip" || err "failed to download Godot editor"
			unzip -q -o "$zip" -d "$WORK_DIR/godot-editor"
		fi
		echo "$exe"
	fi
}

ensure_export_templates() {
	# "4.7.1-stable" -> "4.7.1" (the export template version string)
	local tv="${GODOT_VERSION%-stable}"
	local templates_dir="$HOME/.local/share/godot/export_templates"
	local install_dir="$templates_dir/$tv.stable"
	local tpz="$DOWNLOAD_DIR/export_templates.tpz"
	local marker="$install_dir/.installed"

	if [ -d "$install_dir" ]; then
		touch "$marker"
	fi
	if [ -f "$marker" ]; then
		return
	fi
	log "Downloading Godot export templates $GODOT_VERSION..."
	if [ ! -s "$tpz" ]; then
		curl -L --fail -o "$tpz" \
			"$GODOT_URL_BASE/Godot_v${GODOT_VERSION}_export_templates.tpz" || err "failed to download export templates"
	fi
	mkdir -p "$WORK_DIR/templates"
	unzip -q -o "$tpz" -d "$WORK_DIR/templates"
	# the tpz contains a flat "templates/" dir of per-platform files
	if [ -d "$WORK_DIR/templates/templates" ] && [ -n "$(ls "$WORK_DIR/templates/templates" | head -1)" ]; then
		mkdir -p "$install_dir"
		rm -rf "$install_dir"
		cp -r "$WORK_DIR/templates/templates/." "$install_dir/"
	fi
	[ -f "$install_dir/version.txt" ] || [ -n "$(ls "$install_dir" 2>/dev/null | head -1)" ] \
		|| err "export templates not found after extraction"
	touch "$marker"
}

# -------------------------------------------------------- GDExtension ------
download_gdextension_release() {
	local zip="$DOWNLOAD_DIR/gdext_linux.zip"
	local out="$WORK_DIR/gdext-release"
	if [ ! -f "$zip" ]; then
		log "Downloading HudMod-GDExtension linux64 release..."
		curl -L --fail -o "$zip" "$GDExt_RELEASE_URL" || err "failed to download GDExtension release"
	fi
	unzip -q -o "$zip" -d "$out"
	echo "$out/linux64"
}

build_gdextension_from_source() {
	local src="$1"
	log "Building HudMod-GDExtension from source in $src"

	# godot-cpp at the pinned commit
	if [ ! -d "$src/godot-cpp/.git" ]; then
		mkdir -p "$src/godot-cpp"
		( cd "$src/godot-cpp" \
			&& git init -q \
			&& git remote add origin https://github.com/godotengine/godot-cpp.git \
			&& git fetch -q --depth 1 origin "$GODOT_CPP_PIN" \
			&& git checkout -q FETCH_HEAD )
	fi

	# FFmpeg 8.x (GPL) shared libraries for linking
	local ffmpeg_lib_dir="$src/thirdparty/ffmpeg/lib/linux_x8664"
	if [ ! -f "$ffmpeg_lib_dir/libavcodec.so" ]; then
		mkdir -p "$ffmpeg_lib_dir"
		local ffmpeg_tar="$DOWNLOAD_DIR/ffmpeg8.tar.xz"
		if [ ! -s "$ffmpeg_tar" ]; then
			log "Downloading FFmpeg 8.1 shared build..."
			curl -L --fail -o "$ffmpeg_tar" "$FFMPEG_TAR_URL" || err "failed to download FFmpeg"
		fi
		tar -xJf "$ffmpeg_tar" -C "$DOWNLOAD_DIR"
		local ffmpeg_dir; ffmpeg_dir="$(find "$DOWNLOAD_DIR" -maxdepth 1 -type d -name 'ffmpeg-n8*-shared*' | head -1)"
		[ -n "$ffmpeg_dir" ] || err "could not locate extracted FFmpeg build"
		for lib in "${FFMPEG_LIBS[@]}"; do
			cp "$ffmpeg_dir/lib/lib${lib}.so" "$ffmpeg_lib_dir/" 2>/dev/null || true
		done
	fi

	( cd "$src" && "$SCONS" release=yes platform=linux arch=x86_64 ) || err "GDExtension build failed"

	local out_lib="$src/demo/addons/hudmod-gdextension/linux64/libhudmod.linux.template_release.x86_64.so"
	[ -f "$out_lib" ] || err "GDExtension build produced no release library"
	echo "$src/demo/addons/hudmod-gdextension/linux64"
}

# ---------------------------------------------------------------- export ----
export_game() {
	local godot_bin="$1"
	local export_dir="$WORK_DIR/export-game"

	log "Importing project resources (headless)..."
	( cd "$PROJECT_ROOT" && LD_LIBRARY_PATH="${FFMPEG_LIBDIR:+$FFMPEG_LIBDIR:}${LD_LIBRARY_PATH:-}" \
		"$godot_bin" --headless --import ) || err "project import failed"

	log "Exporting project for Linux x86_64..."
	mkdir -p "$export_dir"
	( cd "$PROJECT_ROOT" && LD_LIBRARY_PATH="${FFMPEG_LIBDIR:+$FFMPEG_LIBDIR:}${LD_LIBRARY_PATH:-}" \
		"$godot_bin" --headless --export-release "Linux" "$export_dir/hudmod" ) \
		|| err "project export failed"

	[ -f "$export_dir/hudmod" ] || err "exported binary not found"
	[ -f "$export_dir/hudmod.pck" ] || err "exported pck not found"
}

# ------------------------------------------------------------ packaging -----
stage_package() {
	local gdext_dir="$1" # dir containing the built libhudmod release .so
	local ffmpeg_dir="$2" # dir containing ffmpeg .so files (BtbN shared build)
	local export_dir="$STAGE_DIR/usr/share/hudmod"

	log "Staging package in $STAGE_DIR"
	rm -rf "$STAGE_DIR"
	mkdir -p "$STAGE_DIR/DEBIAN"
	mkdir -p "$STAGE_DIR/usr/bin"
	mkdir -p "$STAGE_DIR/usr/share/hudmod"
	mkdir -p "$STAGE_DIR/usr/share/applications"
	mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/128x128/apps"
	mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps"
	mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/512x512/apps"
	mkdir -p "$STAGE_DIR/usr/share/metainfo"
	mkdir -p "$STAGE_DIR/usr/share/doc/hudmod"

	# the exported game binary + pck. Godot places GDExtension shared
	# libraries as separate files next to the executable (not inside the
	# pck), so copy those too.
	cp "$WORK_DIR/export-game/hudmod" "$export_dir/hudmod"
	cp "$WORK_DIR/export-game/hudmod.pck" "$export_dir/hudmod.pck"
	cp "$WORK_DIR"/export-game/*.so "$export_dir/" 2>/dev/null || true

	# launcher
	install -m 0755 "$SCRIPT_DIR/hudmod-launcher" "$STAGE_DIR/usr/bin/hudmod"

	# control + metadata
	install -m 0644 "$SCRIPT_DIR/debian/control" "$STAGE_DIR/DEBIAN/control"
	install -m 0644 "$SCRIPT_DIR/debian/hudmod.desktop" "$STAGE_DIR/usr/share/applications/hudmod.desktop"
	install -m 0644 "$SCRIPT_DIR/debian/hudmod.appdata.xml" "$STAGE_DIR/usr/share/metainfo/hudmod.appdata.xml"
	install -m 0644 "$SCRIPT_DIR/debian/copyright" "$STAGE_DIR/usr/share/doc/hudmod/copyright"

	# icons
	install -m 0644 "$PROJECT_ROOT/Asset/Icons/App/logo2-low.png" \
		"$STAGE_DIR/usr/share/icons/hicolor/128x128/apps/hudmod.png"
	install -m 0644 "$PROJECT_ROOT/Asset/Icons/App/logo2-mid.png" \
		"$STAGE_DIR/usr/share/icons/hicolor/256x256/apps/hudmod.png"
	install -m 0644 "$PROJECT_ROOT/Asset/Icons/App/logo.png" \
		"$STAGE_DIR/usr/share/icons/hicolor/512x512/apps/hudmod.png"

	# bundled ffmpeg libs + versioned soname symlinks
	mkdir -p "$export_dir/ffmpeg"
	for lib in "${FFMPEG_LIBS[@]}"; do
		[ -f "$ffmpeg_dir/${lib}.so" ] || continue
		cp "$ffmpeg_dir/${lib}.so" "$export_dir/ffmpeg/"
		local soname
		soname="$(readelf -d "$ffmpeg_dir/${lib}.so" 2>/dev/null | sed -n 's/.*Library soname: \[\(.*\)\].*/\1/p' | head -1)"
		if [ -n "$soname" ]; then
			ln -sf "${lib}.so" "$export_dir/ffmpeg/$soname"
		fi
	done

	# the GDExtension library lives in the exported pck (picked up from the
	# project addons folder during export); nothing extra to install here.
	: "$gdext_dir"
}

build_deb() {
	local deb_path="$DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
	log "Building $deb_path"

	# compute md5sums (data payload only, paths relative to the package root)
	( cd "$STAGE_DIR" && find . -path './DEBIAN' -prune -o -type f -exec md5sum {} + | sed 's|  \./|  |' > DEBIAN/md5sums )

	# Build the .deb as an ar archive (works without dpkg-deb installed).
	# A .deb is: an ar archive containing debian-binary, control.tar.gz and data.tar.gz.
	local control_tar="$WORK_DIR/control.tar.gz"
	local data_tar="$WORK_DIR/data.tar.gz"
	printf '2.0\n' > "$WORK_DIR/debian-binary"

	( cd "$STAGE_DIR/DEBIAN" && tar -czf "$control_tar" control md5sums )
	( cd "$STAGE_DIR" && tar -czf "$data_tar" --exclude=DEBIAN . )

	rm -f "$deb_path"
	ar rcs "$deb_path" "$WORK_DIR/debian-binary" "$control_tar" "$data_tar"

	log "Done: $deb_path"
}

# ================================================================= main =====
main() {
	log "HudMod .deb build"
	log "  version=$VERSION  arch=$ARCH  godot=$GODOT_VERSION"
	log "  project=$PROJECT_ROOT"

	local godot_bin
	godot_bin="$(godot_bin_path)"
	log "Using Godot: $godot_bin"

	ensure_export_templates

	local gdext_dir
	if [ -n "$GDExtENSION_BIN" ]; then
		gdext_dir="$GDExtENSION_BIN"
	elif [ -n "$GDExtENSION_SRC" ]; then
		gdext_dir="$(build_gdextension_from_source "$GDExtENSION_SRC")"
	else
		gdext_dir="$(download_gdextension_release)"
	fi

	# make the GDExtension available to the project so the export packs it
	log "Copying GDExtension library into the project addons folder..."
	mkdir -p "$PROJECT_ROOT/addons/hudmod-gdextension/linux64"
	local release_so; release_so="$(find "$gdext_dir" -maxdepth 1 -name 'libhudmod.linux.template_release.x86_64.so' | head -1)"
	local debug_so; debug_so="$(find "$gdext_dir" -maxdepth 1 -name 'libhudmod.linux.template_debug.x86_64.so' | head -1)"
	if [ -n "$release_so" ]; then
		cp "$release_so" "$PROJECT_ROOT/addons/hudmod-gdextension/linux64/"
	fi
	if [ -n "$debug_so" ]; then
		cp "$debug_so" "$PROJECT_ROOT/addons/hudmod-gdextension/linux64/"
	fi

	export_game "$godot_bin"

	# locate ffmpeg libs (prefer FFMPEG_LIBDIR, else the build tree, else the
	# release zip dir)
	local ffmpeg_dir="$WORK_DIR/ffmpeg-stage"
	mkdir -p "$ffmpeg_dir"
	if [ -n "$FFMPEG_LIBDIR" ] && [ -d "$FFMPEG_LIBDIR" ]; then
		cp "$FFMPEG_LIBDIR"/libav*.so "$ffmpeg_dir/" 2>/dev/null || true
		cp "$FFMPEG_LIBDIR"/libsw*.so "$ffmpeg_dir/" 2>/dev/null || true
		cp "$FFMPEG_LIBDIR"/libpostproc.so "$ffmpeg_dir/" 2>/dev/null || true
	elif [ -n "$GDExtENSION_SRC" ] && [ -d "$GDExtENSION_SRC/thirdparty/ffmpeg/lib/linux_x8664" ]; then
		cp "$GDExtENSION_SRC"/thirdparty/ffmpeg/lib/linux_x8664/libav*.so "$ffmpeg_dir/" 2>/dev/null || true
		cp "$gdext_dir"/libav*.so "$ffmpeg_dir/" 2>/dev/null || true
		cp "$gdext_dir"/libsw*.so "$ffmpeg_dir/" 2>/dev/null || true
		cp "$gdext_dir"/libpostproc.so "$ffmpeg_dir/" 2>/dev/null || true
	fi

	stage_package "$gdext_dir" "$ffmpeg_dir"
	build_deb
}

main "$@"
