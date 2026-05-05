<<<<<<< HEAD
# HudMod Video Editor


![HudMod Preview](Asset/Images/Screenshot%202026-05-05%20034051.png)

## About:
HudMod is an open-source video editor under the GPLv3 license. It is fast and equipped with advanced tools. Development began on June 17, 2025, to fill a gap in the video editing software market.

HudMod uses the Godot engine in the background,
It also uses FFmpeg for media decoding and encryption.

## Why HudMod?
As mentioned earlier, I started working on this project to fill a void in current video editors, specifically among free or open-source options. Furthermore, it aims to run natively on Linux without complex technical hurdles.

## What does HudMod offer?
HudMod provides a range of competitive software features and systems in the video world, including:

- Real-time playback and instant preview.
- Effects based on a Components system.
- Animation for all properties.
- An integrated custom interface with Multi-Monitor support.

## The Vision:
We have several objectives currently set that we strive to achieve, most notably:
- Building the first stable version and presenting it to all users.
- Focusing primarily on Linux and a fast workflow (bridging the current major gap in existing video editing environments).
- Building a community of supporters to ensure sustainability (aiming to provide a modest monthly salary for everyone working on it).

## Status:
Under active development,
You can try Alpha from the release menu.

## The Road to the First Release:
The first Alpha version was launched concurrently with the publication of this article. It is expected to have bugs and stability issues. The current plan is to move gradually toward the 1.0.0.release goal, which is expected to be completed by early 2027.

### Missing features in the current version (to be addressed over the next seven months):

- Building an integrated core structure for Transitions.
- Designing various Transitions as a foundation.
- Batch audio decoding, specifically decoding areas where the playhead is located. (Current audio is decoded all at once, which strains memory and causes issues with large files).
- Generating Timeline Waveforms in stages rather than all at once.
- Zoom in-out and navigation for the Viewport.
- Selecting and modifying basic properties (position, rotation, scale, etc.) directly through the Viewport interface.
- Control over basic audio properties and audio effects (infrastructure is already in place).
- Enabling audio/video separation.
- Opening all tracks in a single audio file (currently only the first track is opened).
- Enabling reverse playback for video and audio.
- Adjusting video and audio speed with Curve support.
- Capturing a frame from the video to be reused as a standalone image.
- Proxy video options during import with quality settings.
- Building a Pooling system for reusing previously opened videos instead of repeated opening processes.
- Hardware Acceleration support for video decoding.
- Hardware Acceleration support for video encoding/exporting.
- Improving the Video Caching system to avoid errors (allowing users to set memory consumption limits).
- Supporting up to 12-bit color depth for media at the Shaders/Effects level, Render-Passes, and Generated-Textures.
- Including Polygon drawing (essential for Masking).
- Adding a Render-Pass Object (crucial for building complex effects).
- Resolving UI update issues for Clips when modifying basic properties.
- Adding Rendering Presets.
- Adding Project Settings Presets.
- Saving and loading any resource.
- Adding a Color Palette resource (editors should access their palettes via the color controller and keyboard shortcuts).
- Building the Color Grading interface, including LGG controls and {Value} vs {Value} controls.
- Fundamental adjustments to the project file system (imported files) and Global files.
- Drag N Drop for files from outside the app and for Media onto the Timeline.
- Saving editor states (open/closed categories).
- Control over Resolution settings during export.

## Setup Guide:
- Download HudMod files from this repository to your local machine.
- Download appropriate VideoCodec release for your OS and arch from: [VIDEO_CODEC_LINK].
- Place the VideoCodec binary along with its associated FFmpeg libraries (.dll's or .so's) into the following directory: `addons/ffmpeg_codec/`
- Open HudMod using Godot 4.6+.

---
**Support HudMod:** [PATREON_LINK]
**Join Discord Server:** [DISCORD_SERVER_LINK]
**Download releases from:** [ITCHIO_LINK] or [RELEASES_LINK]
=======
HudMod Video Editor
About:
HudMod is an open-source video editor under the GPLv3 license. It is fast and equipped with advanced tools. Development began on June 17, 2025, to fill a gap in the video editing software market.

HudMod uses the Godot engine in the background,
It also uses FFmpeg for media decoding and encryption.

Why HudMod?
As mentioned earlier, I started working on this project to fill a void in current video editors, specifically among free or open-source options. Furthermore, it aims to run natively on Linux without complex technical hurdles.

What does HudMod offer?
HudMod provides a range of competitive software features and systems in the video world, including:

Real-time playback and instant preview.

Effects based on a Components system.

Animation for all properties.

An integrated custom interface with Multi-Monitor support.

The Vision:
We have several objectives currently set that we strive to achieve, most notably:

Building the first stable version and presenting it to all users.

Focusing primarily on Linux and a fast workflow (bridging the current major gap in existing video editing environments).

Building a community of supporters to ensure sustainability (aiming to provide a modest monthly salary for everyone working on it).

Status:
Under active development,
You can try Alpha from the release menu.

The Road to the First Release:
The first Alpha version was launched concurrently with the publication of this article. It is expected to have bugs and stability issues. The current plan is to move gradually toward the 1.0.0.release goal, which is expected to be completed by early 2027.

Missing features in the current version (to be addressed over the next seven months):

Building an integrated core structure for Transitions.

Designing various Transitions as a foundation.

Batch audio decoding, specifically decoding areas where the playhead is located. (Current audio is decoded all at once, which strains memory and causes issues with large files).

Generating Timeline Waveforms in stages rather than all at once.

Zoom in-out and navigation for the Viewport.

Selecting and modifying basic properties (position, rotation, scale, etc.) directly through the Viewport interface.

Control over basic audio properties and audio effects (infrastructure is already in place).

Enabling audio/video separation.

Opening all tracks in a single audio file (currently only the first track is opened).

Enabling reverse playback for video and audio.

Adjusting video and audio speed with Curve support.

Capturing a frame from the video to be reused as a standalone image.

Proxy video options during import with quality settings.

Building a Pooling system for reusing previously opened videos instead of repeated opening processes.

Hardware Acceleration support for video decoding.

Hardware Acceleration support for video encoding/exporting.

Improving the Video Caching system to avoid errors (allowing users to set memory consumption limits).

Supporting up to 12-bit color depth for media at the Shaders/Effects level, Render-Passes, and Generated-Textures.

Including Polygon drawing (essential for Masking).

Adding a Render-Pass Object (crucial for building complex effects).

Resolving UI update issues for Clips when modifying basic properties.

Adding Rendering Presets.

Adding Project Settings Presets.

Saving and loading any resource.

Adding a Color Palette resource (editors should access their palettes via the color controller and keyboard shortcuts).

Building the Color Grading interface, including LGG controls and {Value} vs {Value} controls.

Fundamental adjustments to the project file system (imported files) and Global files.

Drag N Drop for files from outside the app and for Media onto the Timeline.

Saving editor states (open/closed categories).

Control over Resolution settings during export.

Setup Guide:
Download HudMod files from this repository to your local machine.

Download appropriate VideoCodec release for your OS and arch from: [VIDEO_CODEC_LINK].

Place the VideoCodec binary along with its associated FFmpeg libraries (.dll's or .so's) into the following directory: addons/ffmpeg_codec/

Open HudMod using Godot 4.6+.

Support HudMod: [PATREON_LINK]
Join Discord Server: [DISCORD_SERVER_LINK]
Download releases from: [ITCHIO_LINK] or [RELEASES_LINK]
>>>>>>> b6b3761 (Add README for HudMod video editor)
