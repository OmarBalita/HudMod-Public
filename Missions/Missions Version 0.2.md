
- Project Management: [+]
	Load project [+]
	Save project [+]
	Manage AppData and global files [+]

- Media Explorer:
	Global, Projects files [+]
	Activate Presets: Global, Project [+]
	Move to Global, Move to Project Options [+]
	Insert a Strong Search system [+]
	
	Fix Selection System [->]
	Error: management when imported media type is not correct [+]
	Error: management when required media are unavailable [+]
	
	Activate all 2D Objects:
		
		Image [+]
		Video [+]
		Audio [+]
		
		Object2D [+]
		Camera2D [+]
		Audio2D [->]
		Shape2D [+]
		Text2D [+]
		RenderPass

- Properties:
	same Search System in Media Explorer
	Copy, Past, and Duplicate UsableRes and Component (Unique ID)
	Copy, Past any property
	Reset Property [+]
	Set Property Transition Quickly
	Transition Component Class
	Animation In-Out Component Class
	Masking

- Components:
	
	Adding:
		
		Display 2D: [+]
			
			Basic:
				CanvasItem [+]
				DrawRect [+]
				DrawCircle [+]
				DrawPolygon [+]
				DrawStar [+]
				DrawArrow [+]
			
			Transform: [+]
				Transform [+]
				Wave [+]
				Shake [+]
				Follow [+]
			
			AnimationInOut: [+]
				Fade [+]
				Popup [+]
				Slide [+]
				Swing [+]
		
		Image: [+]
			
			Basic: [+]
				Invert [+]
				Perspective [+]
			
			Enhance: [+]
				Sharpen [+]
				Denoise [+]
				Kawahara [+]
				Clarity [+]
			
			Cinematic: [+]
				Vignette [+]
				FilmGrain [+]
				Scratches [->]
				Dust [X]
				Bars [+]
			
			Retro:
				CRT and VHS [+]
				LEDGrid [+]
				FilmBurn [X]
				Glich [+]
				GlichWeird [+]
			
			Artistic: [+]
				Pixelate [+]
				Hexagon [+]
				Voronoi [+]
				Halftone [+]
				Posterize [+]
				CartoonEdge [+]
				Sketch [+]
				Emboss [+]
			
			Blur: [+]
				BlurLight [+]
				BlurGaussian [+]
				BlurMotion [+]
				BlurRotational [+]
				BlurRay [+]
				BlurMaximum [+]
				BlurMinimum [+]
			
			Distortion:
				DistLens [+]
				DistRipple [+]
				DistWave [->]
				DistTwirl [+]
				DistBulge [+]
				DistHeat [+]
			
			PostProcessing: [+]
				Glow [+]
				Rays [+]
				LensFlare [+]
				DirectionalChromaticAberration [+]
				RadialChromaticAberration [+]
		
		Color:
			ColorCorrection:
				pass
			
			ColorGrading:
				pass
		
		Text2D: [+]
			
			Basic: [+]
				Transform [+]
				Background [+]
			
			Animation: [+]
				Pulse [+]
				Shake [+]
				Wave [+]
				Bounce [+]
				Flip [+]
				Wind [+]
			
			AnimationInOut: [+]
				InOutType [+]
			
			Shape: [+]
				Curved [+]
				Magnet [+]
				Extrude [+]
			
			Color: [+]
				Rainbow [+]
			
			Generate: [+]
				ExtractShape [+]
		
		Masking:
			pass
		
		Camera:
			
			Basic:
				pass
			
			PostProcessing (Lite):
				pass
		
		Transition:
			pass
	
	SubCategories for Components [+]
	Enable / Disable Component with shader [+]
	Fix Shader Stack Problems [+]
	Complete the ShaderComponent Build Echo-system [+]
	Forced Components [+]

- Player:
	Display Audio [+]
	Create Header Menu Bar (just UI)
	Draw HurtBox for Displayed Media (Image, Video, Object2D ...) when selected
	Select and Interact with Player Viewport

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

- Color Scope Editor: [+]
	Histogram [+]
	Waveform [+]
	Parade [+]
	Vector Scope [X]

- UI & UX:
	Add Scroll Container for each Menu or StringController in Headers [+]
	Replace old Shortcut with the new one
	Flexible Editors: [+]
		Move any Editor Panel and window-it [+]
		Built-in Preset Layout, and Custom Layout [+]
	Fix popuped Menu Problems, with Back Layout, specifically with Timeline

Rewrite:
	MediaClipRes
	Animations
	Timeline: (Timeline, Layer, Clip, curveController)
	Editing
	Playback System

Decoders: [+]
	Video Decoder [+]
	Audio Decoder [+]



