
- Render: [+]
	Render properties editor [+]
	Render viewer editor [+]
	
	Render video with settings [+]
	
	Fix encoder internal settings: [+]
		- setup encoder profile by other settings [+]
		- support RGBA16 format for input image [+]
		- support alpha [X]
		- fix encoders not working with somes pixel_formats [+]
		- fix color banding [+]
	
	Support hdr2 for viewports textures (Main and Effects viewports) [+]
	Reset Cache when renderer is started [+]
	Reset VideoClipRes's Decoder with render settings when renderer is started [+]
	
	Render audio [+, AAC, Opus]

- Properties:
	same Search System in Media Explorer [+]
	Copy, Past, and Duplicate UsableRes and Component (Unique ID)
	Copy, Past any property
	Save any UsableRes, and load it
	Reset Property [+]
	Transition Component Class [+]
	Animation In-Out Component Class [+]
	Masking [+]

- Controllers:
	Fix float Controllers
	Fix String Controller, and Integrate MultiLine, DisplayFilePath
	Fix Array Controller
	Fix Keyframes Displaying
	Fix Curve Controller in the timeline
	MediaClipRes Controller
	ComponentRes Controller
	Create Preset Font Controller
	Copy Resource or any Value and past it
	Add more int/float Controllers for different editing ways
	Categories Menu to hide properties [+]
	Expand and Collapse Color Palette
	Color Correction Controllers, Editors:
		->
		->
		->
		->
		->

- Player:
	Display Audio
	Create Header Menu Bar
	Fix VolumeControl
	Fix fullscreen

- Media Explorer:
	Fix cards
	Change to the same select system used in timeline and curves
	Check moving files
	Check for delete
	Creating folders

- Components:
	Color:
		ColorCorrection:
			pass
		
		ColorGrading:
			pass

- Project Management:
	- Adding the version panel when the app is started, embedding follow: [+]
		- Create a new project button [+]
		- Load a project, and recent projects [+]
		- Notification if a new version comes [X]
	- Create a new project, with settings [+]
	- Save and Load system [+]
	- Delete an old project [+]
	- Move between projects [+]
	- Undo Redo

- Settings: [+]
	Edit settings [+]
	Performance & Caching settings [+]
	Shortcut settings [+]
	Theme settings [+]
	Save & load [+]
	Search system [+]

- UI & Themes:
	Fix LineEdit and TextEdit theme issue
	Fix LineEdit and TextEdit focus issue
	Fix PopupedMenu font color when it disabled
	Replace some PopupedMenu by built-in one: PopupMenu
	Add name or short-description to ui elements when focus
	Fix window problem: spawn window from shortcuts when can't
	Fix window problem: close window while process states
	Notification: message, warning, error

