# Changelog

## Unreleased

## 0.7.6 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ New separate log files for Performance, Webview2 and Setup
+ New WPF helper function Update-MainWindow
  + Allows updating Main UI controls from other threads with better performance
+ New Option: Notification Audio - plays audio on new notification
  + Test Notification button added to title bar for Dev testing only
  + For easy testing of notification refactor and new notification audio
  + Also plays when doing something else ;)
+ Lock-Object function - prevents simultaneous obj access from another thread
+ Stop-Runspace for 'Safely' stopping background runspaces before they complete
+ Ability to automatically skip or block ads that may appear for Youtube vidoes
  + Applies when using webplayer only, cant guaranteee to skip/block them all

### Changed
+ Spotify and Webview2 are now installed async during Inno Setup
  + If webview2 is still installing on launch, splash message will indicate
+ SecretStore modules are now included as local modules vs remote
  + Greatly improves first run setup time 
  + May also help solve some of the reliability issues when retrieving secrets
+ Restyled Splash Screen images and status text
  + Decreased the size of the splash images based on images used for speakers
  + Simplified splash message text to prevent need to wrap text
  + Updated size, animation and color of progress paws
+ Tray contextmenu now available when right clicking on miniplayer itself
+ Reduced various stutter during some intensive background operations
+ Another refactor pass to update log processing and targeting
+ Multiple improvements to dealing with/preventing runspace race conditions
+ Improved disposal and cleanup of vlc instances or extra external processes
+ Modified Merge-Image so "Stamped" icons more visible over media artwork
  + Image is really only for System Transport Media overlay
+ Spotify Authentication status in Settings updated to match YT/Twitch updates
  + Also changed INVALID status text to NONE when none are provided/available
+ Improved sizing of columns for various grids under settings 
+ Moved text of EQ Preset labels above their button controls 
- Removed (disabled) Get My Subscriptions checkbox under Youtube importing
  + To be re-added later when feature is complete

### Fixed
+ Fixed #89 - Get-LogWriter gets caught in a loop causing crash
+ Libraries dont update/appear if disabling and re-enabling media importing
+ Currently applied filter is lost when sorting columns in Media Libraries
  + Note: Fixed for filter dropdown, to be fixed shortly for filter textbox
+ Fixed #78 - Pre-Amp Value Not Following Presets
+ Fixed #88 - First Run Setup closes after providing Youtube Authentication
+ Fixed #90 - Local Media import stays disabled when canceling browse
  + Also fixes disable issue when trying to add folder that already exists
+ Fixed #84 - Splash Screen text cut off during first run
+ Floating Video View window title doesnt update with main player title labels
+ Dropdown/combobox's keep adjusting width based on content while scrolling
  + Contextmenu is now fixed width based its largest containing item
+ Multiple fixes related to SecretStore and SecretManagement
  + Should improve reliability of Twitch/Youtube/Spotify authentication
  + Should reduce or remove multiple authentication popup windows (needs test)
+ System Media Transport Controls dont update when pausing/playing
+ Mute button toggle status sometimes becomes out of sync with audio state
+ Setup window can freeze when adding multiple local folders at a time
+ Multiple fixes/improvements to prevent streamlink failures due to ADs
+ Audio is never unmuted after muting when skipping Twitch Ads
+ No image/artwork displays/processes when playing Spotify Media
+ App can freeze/crash when executing Stop media in some cases
+ Current progress not remembered for media auto loaded on next app start
+ Fixed #86 - First Run setup not detecting Spotify installation

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.5 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Ability to toggle image grid or table view for Spotify and Youtube media
  + Images are cached on first run to be used in image grid
  + Not fully finished, need to add to Local and Twitch libraries
  + More adjustments to design needed plus need default/placeholder images
+ Ability to 'Refresh' all media in Spotify or Youtube Library
  + New button on each library tab called Refresh
  + Triggers a full reimport from respective API's/rebuilds profiles
  + Not finished, To be added to Local and Twitch libraries
+ Ability to Add/Remove track from Spotify playlists (via API)
  + For playlists on Spotify's end, not local app playlists. 
+ First iteration of ability to manage native Youtube playlists
  + 'Youtube Actions' added to contextmenu with Add/Remove playlist menus
  + Playlists are populated from API, but selecting does nothing yet
+ (WIP) First iteration of self-update management system
  + No usable yet, currently only checks for new builds and displays changelog
  + Option added to main window contextmenu: Check for Updates
  + Child window appears and displays latest version with changelog
  + Currently builds/changelog hosted on Trello, likely change in future
  + Added ability to download Trello Attachments via API
+ New Helper function Test-ValidPath for quick check of file/directory or URL
+ Very early first iteration of new Help Topic system
  + Added new helper assembly MdXaml to display native Markdown in Xaml
  + Updates Child Window uses MdXaml to display changelog
  + Markdown is planned format to try and standardize with
  + Xmls will hold topics and subtopics, button commands will read from these
  + Text to be removed from code and put into files that can be updated easier
+ First iteration of ability to select/change media images in Profile editor
  + Currently can browse for image or paste web image url
  + Image displayed on images tab will update, but currently is not saved yet
+ Ability to merge 'Stamp' an image onto another with new module merge-Images
  + Used only for thumbnails to stamp media type icon over the image
  + Ex: Allows quickly seeing that playing media is Spotify by icon
  + Only applies to images such as in the System Media Transport overlay
  + Still requires final adjustments, doesnt display for all media yet


### Changed
+ Image caching (mostly for Image Grid views) is now decoded in memory
  + This prevents app from locking access to image files in temp folder
  + CacheOption set to Onload to help reduce memory overhead
+ Improved logic to detect and install Spotify client in Get-Spotify
+ Adjusted retry delay when getting secrets for Twitch authentication
+ Youtube webplayer now honors 'Preferred Quality' Setting
  + Youtube stopped native support so this could stop working
  + Best is highest available, medium is usually 420p and low is < 320p
+ Discord presence now shows new icons/text when playing YT TV (vs just YT)
+ Now easier to get returned data from Runspaces with output object
+ Various reliability improvements for playback of non-webplayer Spotify media
+ More Improvements to write-ezlogs formatting and ease of use
+ Various minor optimizations/cleanup and other changes to WPF xaml and styles

### Fixed
+ Matching against Youtube URls sometimes fail due to unescaped chars
+ Refreshing playlists sometimes overwrites recently committed changes
+ Spotify playback sometimes fails when API returns multiple devices
  + Now only the active device or last (if no active) is selected
  + Affected non-webplayer usage mostly
+ Fixed #77 - Spotity Non-Webplayer - Volume/Mute not working
  + To avoid extreme stutter due to API calls, volume only changed on mouse up 
  + Technically no mute with Spotify API, so just setting volume to 0
  + Another reason why using Webplayer is default and best option
+ Profile editor fails when trying to load some properties as hyperlinks 
  + Caused if value passes 'EXISTS' check if they match special folder name!
+ Contextmenu fails to load if adding separator style to sub-level2 menu
+ LordofTerror Easter Egg sometimes fails to load
+ Some Spotify media fail to import if exists in multiple Spotify playlists
+ Album/Images missing for Spotify Media and Profiles
+ Many properties missing in profile editor for Spotify/Youtube/Twitch media
+ Fixed #82 - App Freeze on Media Change when using streamlink
  + Ended up being log output accessing streams property from runspace object
+ Streamlink log monitor sometimes fails to end or hangs
+ Various issues and occasional app freezes when executing Stop Media
+ Playlists not updated when updating media properties with Profile editor
+ Fixed #65 - Local Media Table errors when No Media exists
+ Fixed #57 - Add support for processing youtu.be urls

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.4 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ New Option: Remember Playback Progress for Local Media
  + Saves current playing (or paused) media progress on app close 
  + On next startup, media is loaded automatically (but paused)
  + When resuming, playback continues from last saved progress
  + Only applies to Local media for now, to be added to other media types
+ New Option: Skip Twitch Ads
  + Attempts to skip Pre-Roll, Mid-Roll and other Ads when using streamlink
  + Also passes auth to Twitch streams on playback to skip ads for sub channels
  + Auth pass to streams via streamlink requires logging into Chat view once
  + Chat view login required due to stupid requirement on Twitch's end
+ New Spectrum Analyzer Beats Animation for the Samson Left Speaker ;)

### Changed
+ Refactored Easter Egg: Get-OpenBreweryDB (Now Show-OpenBreweryDB)
  + Added tab 'Beers' which pulls Beer Recipes from BrewDog's Punk API
  + OpenBreweryDB list moved to 'Breweries' tab
  + Not finished, need to design new Xaml skin or make heavy changes
+ Refactored Mute Command, moved into new function Set-Mute
+ Removed various unused/old Routed events, timers and other code
+ Bitrate now only displays in the Display Panel if it is not null or 0
+ Metadata from Taglib is now refreshed from media file on playback
+ Moved various commands into function Update-MainPlayer
  + Uses dispatcher timer to improve performance/reduce stutter of UI updates
+ Updated included build of Streamlink to version 5.1.0-1
+ Various performance improvements for Start-Media (less UI stutter)

### Fixed
+ Volume sometimes does not restore properly to previous values on reload
+ Unnecessary Spotify API lookups attempted when executing Skip-Media
+ Custom Hotkey for muting not working (this feature not fully integrated yet)
+ Write-ezlogs not working or erroring out within Start-Runspace

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.3 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Display of bitrate to the main display panel after artist
  + Only displays for local media that include bitrate in current profile
  + Eventually will be calculated on playback vs whats stored in the profile
  + Eventually will display video bitrate or quality for video or web streams
  + Displays within MiniPlayer Display Panel as well
+ New Beats animation of woofer for the Right speaker window (when opened)
  + Requires enabling Spectrum Analzyer (Monitor),
  + Triggers for low-to-mid range frequencies (kick)
  + Makes it look like speaker is playing audio

### Changed
+ Minor log level and other changes for some log messages

### Fixed
+ Critical error that would crash the log watcher runspace
+ Catcherror param in Write-ezlogs not outputting the errors to log
+ Enumeration errors when refreshing Twitch streams in Get-TwitchStatus
+ Cassette wheel animation doesnt pause when pausing playback of Spotify media

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe
+ No version bump, more of a hotfix

## 0.7.3 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ New Speaker L and Speaker R buttons and graphics for main UI Skin
  + If monitor is 1440p, speakers display on left and right side when opened
  + If monitor is 1080p, speakers display on top of the main UI when opened
  + Easter eggs not added yet, will likely be added close to release
  + Other than slight tweaks, the Main UI skin is now complete! WOOHOO!
+ Ability to edit primary URL of Media in the profile editor
  + Not finalized but allows changing for Spotify, Youtube or Twitch
  + Various checks in place to ensure supported URLS are added only
  + May add "advanced" label as can break things if u dont know what ur doing
+ Streamlink installer included and no longer downloaded via chocolatey

### Changed
+ Refactor pass for Chat View
  + New Module Update-ChatView to consolidate chat related functions
+ Large refactor pass for logging system via write-ezlogs
  + Added new separate log file for Discord logging
  + Added new separate log file for Local Media logging
  + Added new separate log file for Libvlc logging
  + Added new separate log file where all Errors are logged
  + Implemented logtypes to write-ezlogs to redirect to appropriate log files
  + Implemented 4 loglevels for individual log messages in Write-EZLogs
  + Only loglevels equal or less than global config log level are processed
  + Errors are always processed and output to the error log
  + Default loglevel is 2 - write to log only (no console/host output)
  + Replaced write-output with [File]::AppendAllText for logging
  + Write-ezlogs now submits all messages to a synchronized concurrent queue
  + New Get-LogWriter writes to log files messages enqueued from write-ezlogs
  + Get-LogWriter runs in a separate runspace
  + Large performance increases since no waiting for file writes or host output
+ Refactor for Open Media button and commands
  + Now displays custom metro dialog with choice to open URL or local file
  + Only one (URL or file field) can be submitted at a time
  + Its purpose is for opening a single media item (like File - open menus)
+ When notification flyout opens, any controls with airspace issues are hidden
  + Previously notifications appear behind if video is playing for ex
  + Only hidden while notification is open, unhidden when it closes
  + Ability to disable auto notification flyout is planned
  + More changes needed, but this helps with the biggest issue
+ Video quality now auto set to best when playing media via Invidious webplayer
  + Eventually will be tied to the preferred quality setting under Youtube
+ Reduced overall size of some of the Splash Screen startup images
+ Changed icon for local media in Discord presence to harddisk

### Fixed
+ App icon missing from undocked/floating Windows
+ Keyboard input not working for textboxs in the main UI and dialogs
+ Race conditions caused by multi-thread log writing (see above)
  + Full testing needed to be sure, but should solve alot of issues this caused
+ Pressing play button would not do anything in some cases
+ Volume gets reset or doesnt save properly when manually changing media
+ Volume is not set to current app value for Spotify media using the webplayer
+ Volume gets stuck to 0 when playing media via Invidious webplayer
+ VideoView tab sometimes not selected on open if auto open is enabled
+ Loading text animation sometimes start flashing to fast to see
+ Miniplayer progress slider not in sync with playing media or main UI slider
+ App could freeze after media ends when using Invidious and auto play enabled
+ Media is sometimes not removed from Queue after playback ends

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.2 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Global and individual message log levels to replace verbose_logging
  + Not fully implemented yet, will be when doing logging refactor
+ First iteration of LibVLCSharp v4 support (not in full/stable release yet)
  + Allows testing pre-release builds of v4, less headaches if upgraded later
+ Initial framework to support choosing/changing video/audio tracks
  + Not implemented yet, currently can cause issues in libvlc 3 in some cases
+ Convertto-ArrayList function for convering objects to arraylists
+ Set-TaskBarVisiblity to allow hiding/showing windows taskbar
  + Not used for anything yet, maybe never
+ Set-Databinding function for easier/cleaner databinding of UI properties
  + Also added ability to pass binding params/values for Add-WPFMenu
+ Contextmenu for Settings Window with close/TopMost/ShowinTaskbar options
+ New Toggle Option: 'Use YTDLP for Twitch Streams' (default disabled)
  + Streamlink usually best, and is always used by default
  + In some (rare) cases YTDLP may work better or if streamlink not installed
+ Ability to pass Oauth token to Streamlink/YTDLP for Twitch Authentication
  + No UI options yet. Requires logging into Twitch chat at least once
  + Allows authenticating stream to your account, to bypass ads..etc
  + Somewhat in response to Twitch ads problem (see Issues)
+ Ability to detect when streamlink is blocking Twitch adds (see Issues)

### Changed
+ Import-Spotify no longer uses Datatable, uses hash arraylist
  + All profile properties are processed within Get-Spotify
+ MessageBox now used for confirmation messages if Library is undocked
  + Metro ModalMessage still used if docked
+ First iteration of Remove-Media for refactor of media removal commands
  + Contextmenu option renamed to 'Remove from Library'
+ (TEMP) TinyDesk and Beer icons launch Show-Speakers, left/right accordingly
  + Using these buttons just for testing until new ones made
  + Part of easter egg. Speaker images for left/right open in separate windows
  + These speaker windows do nothing right now. Will hold easter egg triggers
  + Removed balance knob from skin. To add controls for left/right speakers
+ Minor adjustments/changes to Splash Screen images and UI
+ Second iteration of Youtube Library view change to use wrappanel
  + Images are now always cached and saved to Profile
  + Decreased image size and more closely matched youtube.com layout
  + Still not finalized and may not even use, will require feedback/testing
  + Maxres images now picked first, then smaller if not available

### Fixed
+ New profile images retrieved for twitch media are not saved in Get-Playlists
+ More issues with retrieving secret vault auth/token keys
+ Invalid images or paths saved to profiles for some Youtube media
+ Various instances of 'Collection of a Fixed size' errors
+ Profile, Audio and settings windows not included in app snapshots if open
+ Video Viewer window/controls flicker when undocking/expanding to fullscreen
+ Youtube TV urls incorrectly processed as Youtube Channels when added
+ Majority of Spotify/Youtube properties not showing in details tab of editor
+ Some property and value types incorrectly detected in Profile editor

### Issues
+ Twitch playback will sometimes not start right away or pause due to ads
  + Since adding the ability to play Twitch streams via streamlink, it was always able to block ads. Twitch finally plugged most of the loopholes used to bypass ads. If a twitch stream stops because of a mid-roll ad, its possible it may not start again and the stream needs to be restarted. At best, there will now be 'Commercial Break' Purple Screen of Death that displays when ads are playing. Hopefully a workaround can be found again

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe


## 0.7.1 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Ability to provided a default path for Youtube videos downloads
  + Settings - Youtube - Youtube Options: Default Download Path
  + If none is provided, app will always prompt for location when downloading
+ Ability to export custom Playlists via contextmenu option 'Export Playlist' 
  + Prompts for file and save path. Exports as XML 
+ Ability to import custom Playlists via 'Import' button under playlists
  + Supports profiles that were exported from app or native profiles
  + Prompts warn of conflicts and ask before overwriting
+ Ability to rename custom Playlists via contextmenu option 'Rename Playlist'
  + Renames both Playlist name and profile file name
  + Name restrictions same as when creating new profiles
+ Ability to refresh/read IDTags for local media file within profile editor
  + Reading will refresh all fields in the editor and on details tab

### Changed
+ [EXPERIMENT] Changed Youtube media browser to virtualized wrap panel
  + Just testing with a possible image grid/panel view
  + Consider it non-working for this build, will be changed
+ Tracks in playlist profiles are now ordered dictionaries like the play queue
  + Allows better management and ordering of tracks and playlists
  + Playlists tracks now show their number based on order in playlist viewer
+ Now possible to play and advance tracks from playlists directly
  + Queue still has priority, if nothing in queue, next track in playlist plays
  + Works with Autoplay enabled, skip/next media commands and shuffle
  + If a track is in multiple playlists, picks the one where playback started
+ Various minor UI adjustments and changes to alignment, text and spacing
+ Refactored Open-FileDialog to support SaveDialogs
+ Next iteration of UI redesign for Sub-Windows (Settings/editor)
  + Not final but now more matches overall theme. More to be tweaked
  + Improved spacing and reduced needed scrollbars for settings/first run
+ Total play duration is now displayed next media in playlists (sans Twitch)
+ Improved error handling and logging in Get-TwitchApplication
+ Enabling/Disabling EQ 2Pass now takes effect immediately
  + Playback will 'pause' or stutter briefly, but will continue
+ Profile editor now displays more properties under details tab
  + Additionally, valid path/urls are now clickable links
+ Renaming of local media files via editor now working
+ Writing metadata properties to IDTags of local media now working
+ Changed libvlc hardware decoding to dxva2 for better performance

### Fixed
+ Unable to reorder playlist items via drag-n-drop
+ When updating media profiles, it is moved to the end of the playlist its in
+ Playlists created via 'Save as new playlist' are blank/dont copy tracks
+ Multiple tracks are sometimes skipped when libvlc playback ends
+ Saving profiles in media editor sometimes doesnt apply or saves wrong values
+ App can hang when closing settings window via the settings toggle button


### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.0 - Samson-Alpha
- Branch: Samson-Alpha

### Changed
+ Greatly improved performance when opening Settings Window (after first run)
  + Show-FirstRun is now preloaded on startup but hidden, displayed when needed
  + Intercepted Window close command (Cancel = true) to hide vs close
  + Refactored Audio Device enumeration which caused significant slowdown
  + CSCore DeviceEnumerator faster than libvlc, for first run anyway
+ Slight log performance improvement, changed Get-Date to [datetime]::Now
  + Very small improvement but every little bit can help collectively
  + Reduced Get-PSCallStack calls for logging (has minor impact on first run)
+ Potentially Improved reliability/error handling for Get-secret calls
  + More to do here but this may be reason for recurring YT/Twitch auth windows
+ Various updates and cleanup to logging, added additional perf logging
- Removed Startup Audio (Setting still there, to be removed or changed)
+ Improved performance for Start-SplashScreen to reduce time to display
  + About avg 1s improvement for first run (will vary)
  + Only minimum required dlls are now loaded for splash vs all of them
  + Reduced as much xaml as possible for splash screen
+ Adjusted SpectrumAnalyzer bass freq observer from 20-200hz to 20-60hz
+ Restyled Main Progress slider to match improved style of Spectrum lines

### Fixed
+ EnableCollectionSynchronization error when MediaTable itemssource is empty
+ Shuffle and Autoplay Display icons do not follow/update with color theme
+ (Maybe?): Pause/Play/Next events do not register all the time
  + So confusing and frustrating. Seems better now but far from consistent
  + Events seem to buffer? One executes then others dont until UI interaction
  + If playing media with video content, seems to work fine? (not sure of this)
+ SpectrumAnalyzer gets "Suck/frozen" if enabled when stopping media
+ YT Auth PODE doesn't close properly or errors after starting first run setup

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe
+ No version bump, incremental commit, no adds

## 0.7.0 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Startup Setting 'Start As Miniplayer'
  + Allows the app to load using the Mini-Player skin on startup
+ Media Player setting 'Auto Open/Close Video Player'
  + Video player will automatically open/close when playing media with video
  + If disabled, Media may not start until video is opened if using Webplayers
+ Dev option 'Verbose_perf_measure', not exposed to UI
  + To be used as part of upcoming performance optimization testing
+ Registered events for libvlc: Muted/UnMuted, Paused, Forward, Backward
+ Description property from taglib for local media
+ (WIP) Ability to rename local media filenames via Profile Editor
  + It 'works' currently but not fully finished, use with caution
  + Logic detects for name conflicts, bad characters, and supported extensions
  + Max file name is 150 characters
+ (WIP) Images tab for Profile editor displays media art/images
  + Only displays, no editing yet
+ Ability to change and save Description field via Profile Editor
+ (WIP) Write-IDTags, ability to write basic metadata to IDTags of local media
  + Not finished, use with caution 
  + Works with basics like Title, Artist, Album, Description, Track, Disc
+ (Dev Testing) Ability to control volume via Numpad +/- keys
  + Only for my internal testing, likely doesnt work if app not in focus
  + May turn into ability to allow mapping custom keys to control media player

### Changed
+ Verbose Logging is now disabled by default
+ Main Display panel text/font now follows the current theme color
+ Splash image now randomly selected from Resources\Images\SplashScreen
  + Testing with new splash images (Credit: Woody) 
  + The last used image is saved so that next one is always different
+ Current playing media is now restarted if pressing 'Play' during playback
+ Mute status is now synced when muting from the Youtube webplayer interface
  + Volume level is also synced
+ Mute status for all media now saved to config as Media_Muted
+ Restyled and updated SpectrumAnalyzer
  + Spectrum Lines now emulate digital display lines better
  + Now follows currently applied UI theme color
  + Reduced bins from 40 to 30
  + New property 'ForegroundImage' to allow providing imagebrush for lines
+ Various improvements to Javascript injection of Youtube webplayer
+ Youtube webplayer is forced to use if media is detected as Youtube TV
+ Adjusted storyboard fade timeout for Video Controls Overlay

### Fixed
+ App volume doesnt save/persist between app restarts or change of media
+ Mute status and related icons sometimes get out of sync
+ Video Overlay controls still slightly visible when playing via webplayers 
+ Pause button checked state sometimes get out of sync with playing state
+ Media not removed from queue after ending if auto play is disabled
+ Duration_ms value not saved for some local media
+ Twitch secret scope sometimes fails to save in Set-TwitchApplication
+ Discord presence sometimes fails to update from youtube webplayer media
+ Profile editor may fail to load if not UI theme is currently selected
+ UI and other elements not reset after timeout if media failed to play
+ VLC_Play_Media runspace can fail due to running under MTA ApartmentState
+ Youtube auth secrets can fail to save to vault if API response had error

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.9 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ First iteration of Profile Editor and property viewer
  + Metadata tab contains fields that can be edited/changed
  + Details tab for displaying readonly fields
  + Very WIP, more fields to be added/changed plus style/UI not finished
  + Right now only basic fields can be changed/saved (Title/Artist/Album)
  + Saving updates media in all lists (media library/playlists..etc)
  + Option to allow writing data to IDtags for local media (Not working yet)
  + (Planned) Ability to attempt auto-lookup via API calls
  + (Planned) Covert Art/Image management
+ Additional properties to local media profiles
  + Samplerate, BitsPerSample,AudioChannels,VideoWidth,VideoHeight
+ Stereo Graphic Equalizer text label to EQ Skinu

### Changed
+ Moved 'Edit Media Properties' menu option to bottom of contextmenu
+ Improved error handling for Spotify webview2 initialization
+ Improved error handling for Set-DiscordPresense and DiscordRPC module
  + If a property has an issue, it is now skipped vs crashing entire presence
+ Spotify process is now only closed (if running) during first time setup
+ Improved CassetteWheel image and animation quality
+ Libvlc instances are now always disposed on Stop-Media
+ Limited potential race conditions in Update-MediaTimer

### Fixed
+ Libvlc video sometimes spawns in a separate window that cant be closed
+ URL property missing from some Spotify media profiles
+ Incomplete/Invalid profile_path value saved to Twitch Media profiles
+ Some Youtube media fails to work with Discord integration presence
+ Update-Playlist fails if media exists in more than 1 playlist

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.8 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Config setting Open_VideoPlayer to control if video player auto opens
  + No UI implementation yet, defaults to true. 
  + Video Player auto opens only if playing media has video content
+ Ability to capture Youtube webplayer fullscreen button click events
  + When clicking fullscreen button in YT player, maximizes and undocks player
  + Works for both regular Youtube videos and Youtube TV content

### Changed
+ Youtube adblocking script now applied to Youtube webplayer webview2 instance
  + Potentially blocks Youtube static and video ads
  + Mostly applies if not using inline mode, so not likely common
+ Improved error handling and user feedback for Youtube web playback errors
+ First iteration (Testing) of skin change to first run/setup UI
  + Just a very basic image/texture to somewhat match main theme

### Fixed
+ Video content not using entire screen when in floating window
+ YoutubeTV content in webplayer randomly invokes playback end event
+ #76 Spotify Loading label display does not change once media starts playing
+ Pausing Spotify media does not update status icons and animations
+ Spotify API calls occur in pause/stop events even if no spotify media playing

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe
+ No version bump


## 0.6.8 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ First iteration of designed and refactored EQ/Audio Options UI
  + Added ability to Remove custom EQ Presets via Delete button
  + Added 2 'Memory' buttons that custom presets can be saved to, aka favorites
  + Save menu to save to current loaded preset, memory 1/2 or as new name
  + Load menu displays all custom presets that can be loaded
  + 12 Fixed Preset buttons, cant be overwritten by or use same name as custom
  + Custom names are checked for invalid characters and max 75 char length
  + Reset button to flatten and reset EQ values
+ Custom FormattedSlider control to allow customizing Autotooltip string format
+ Ability to filter Twitch media library by Live Status or game playing
+ Chat View toggle option in Video View window contextmenu when floating
+ EQ Enable Status indicator for Main Display Panel Screen
+ First iteration of Invoke-MediaFilters module
  + To be used for refactor of all media library filtering controls/events

### Changed
+ Improved memory and disk footprint of Webview2 instances
  + Webview2 instances now share user data folder without conflicts
  + Exception for Show-Weblogin, uses Setup_Webview2 user data folder
+ Various minor code/comment cleanup and optimizations
+ Improved memory overhead and rendering quality of icons for PlayQueue
+ Changed icon for Local Media items to be harddisk vs VLC
+ Implemented EnableCollectionSynchronization for observable collections
  + Allows accessing collections from Non-UI threads
  + Further refactoring needed to take advantage for collection updating
+ Implemented SortDescriptions for ListView/GridView table sorting
+ Various minor styling, font rendering improvements and other UI changes

### Fixed
+ App freezes or doesn't skip/stop media in libvlc EndReached event
+ Rare 'ItemsControl is inconsistent with its items source' fatal error occurs
  + Resolved with EnableCollectionSynchronization implementation
+ Get-TwitchStatus updates do not update media in the Twitch Media Library
+ Followed date field in Twitch Media Library does not sort correctly
+ Some Youtube TV urls fail to import or play correctly
  + Issue: Youtube TV playback randomly invoke playback ended event  
+ Webview2 initialization can cause app fatal error in some cases
+ Caching media images fails on PS7 with set-content -encoding byte
+ Playing media fails to highlight if it exists in multiple playlists
+ Uncaught exception can occur when attempting to close YT auth PODESERVER
+ Various binding failures and other errors caught during VS debugging
+ Unable to scroll in nested scrollviewers that use ScrollAnimationBehavior
+ Media Table performance tanks after opening any contextmenu in the app
  + FINALLY ITS FIXED!!

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.7 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Additional verbose and performance measure logging in various areas

### Changed
+ Refactored Media library replacing Datagrids with ListViews with GridView
  + Mostly for testing vs using Datagrids
  + Currently sorting does not work, but filtering and everything else should
  + Individual filters per column removed (not supported with listviews)
  + Overall performance seems slightly improved, but not much
+ Disabled Optimize-Assemblies for now, unsure if worth keeping
+ Improved performance/responsiveness of filtering media libraries with search box
  + Switched to using DeferRefresh() as well as some other cleanup
+ Greatly improved CPU/GPU performance overhead when playing media
  + Reduced by 50% framerate of cassette, displaypanel/other storyboard animations
+ Open media dialog now only allows selecting one media file/vs multiple
  + A window is also now displayed to user if selected media file is invalid
- Removed Fullscreen/pop-out button - docking manager controls replace this
+ Auto Play when enabled, now executes next media via endreached event for vlc 
+ Refactored Open-FolderDialog moving c# code to dll assembly as a helper class
+ Preliminary changes to Splash Screen playback of startup audio
  + Prepping to allow choosing media file that plays on startup
+ Various code and comment cleanup
+ Maximize/Expand video button now undocks and automatically maximizes video window
+ Setup window now uses scrollbars if content is larger than windows max height
+ Improved error handling in various areas

### Fixed
+ Streamlink and other required apps may incorrectly show as installed when not
+ Twitch playback fails when streamlink is not found to be installed
  + App will now fallback to using yt-dlp for when streamlink not found or has error
+ Large freeze/stutter when loading main UI after first run setup
  + Caused by first initialization of libvlc, now runs in a separate runspace
+ Playback may fail for some youtube media if played from Media Library
+ Contextmenu not opening or has incorrect menu options for some media
+ Extra text shows within Display panel when not using text slide animations
+ Discord presense doesnt update or updates incorrectly when using webplayers
+ Unable to use keyboard input in windows undocked from docking manager
+ Set-DiscordPresense may sometimes fail or throw an error under various conditions
+ Number count incorrect for various datatables in Setup window
+ Various sizing issues for UI, text and controls in Setup Window

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.6 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Spotify Client and Webview2 Runtime installer bundled in Inno Setup
  + Spotify : optional component, if selected silent installs after Inno Setup
  + Webview2: required component, installs during Inno setup if not already
  + Webview2 is still verified and installed if needed by app as its crucial
+ 'FreshStart' parameter to allow forcing first time setup on startup
+ Ability to Import followed Twitch Channels into media library
  + Entries added/imported under Twitch tab in setup now work
  + Table sorting still not working correctly, possibly other things
  + Using remove media options still need refactor as well 
  + Using datatable like the others for now, but want to change to new control
+ Text Slide animations to MiniPlayer display panel when text/title is long
+ Ability to 'Close' undocked windows, which will automatically redock them

### Changed
+ Changed installer compiler compression to lzma2/max for better compression
+ Startup log name now follows includes current app version like the other logs
+ PowershellGet no longer auto upgraded during setup
  + No longer needed as the only module to install doesnt require updating
+ Improved error handling and messaging to user if critical error on startup
+ Greatly improved performance of getting Twitch data by batching API lookups
  + Can group up to 100 lookups into one API call
+ Improved first run startup and setup time
+ Updated Drag/Drop to support twitch media urls and importing
  + Play on drop does work but settings need to be decoupled from Youtube still
+ Improved text and font rendering quality in main Display panel
+ Game name for Twitch streams now display within Discord presence
+ Multiple improvements to Docked/Undocked windows behavior and styling
+ Multiple improvements and changes to logging and feedback/messaging to users
+ Various updates/cleanups to xaml styling and skins

### Fixed
+ FINALLY/MAYBE a decent fix for video controls overlay issues
  + Not perfect but MUCH better, as it it works now when video is undocked
  + Still instances where you might have to click in/out of window a few times
+ Optimize-assemblies may fail with ngen not found error
+ Spotify webplayer may fail due to webview2 initialization error/conflict
+ Artist/Channel name not displaying for Youtube media when using webplayer
+ Installing Spotify using setup button fails and causes setup to close
  + This also caused some settings to be lost
+ Spotify auth status not displaying if previously entered during setup
+ Spotishell tries to make api calls when not yet having valid token
+ Play/Pause icons/status not updating/resetting in some cases
+ Audio/EQ window controls change size/move when changing EQ presets

### Issues
+ Fullscreen button still has issues, as do most buttons in the title bar
+ Cassette tape animation may not stop/pause in some cases (maybe others too) 
+ Performance optimization ongoing, should not currently be benchmarked 
+ May consume alot of ram especially when watching high quality streams or when viewing large libraries.
+ Spicetify option is disabled until refactor or possible removal, not sure
+ Other options like Spotify play on drop or Youtube download on play still disabled, maybe be removed soon
+ Help text still only placeholder/inaccurate/unfinished
+ Media library tables have issues especially with sorting/filtering
 + Looking into overhaul, possible change from using datatables
 + Filtering not currently work for any tab yet, due to move to dockable window
+ Volume level does not save/persist between app restarts
+ Back button doesnt do anything yet
+ Drag/Drop likely has issues, especially moving items between playlists
+ Notification flyout sometimes is stuck behind video view or docked windows
+ Docking Pane/Video view may open sometimes when you dont want it too. This is mostly on purpose for now, will be adjusted

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe


## 0.6.5 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Ability to detect failed Youtube playback and auto-restart with Invidious
  + Applies when using native Youtube webplayer, switches to invidious on retry
  + Invidious bypasses most Youtube native player restrictions
+ Dock/UnDock window button for Video View Flyout overlay
+ Ability to choose whether to keep or remove user data during app uninstall
+ New tray menu options to open Media Library, App and Audio Settings
+ Ability to detect program name/title when watching Youtube TV channels

### Changed
+ Updated Splash Screen progress animations and now displays status messages
+ Increased verbose logging output when installing new modules during first run
+ Improved error handling/feedback to user during Load-Modules
+ New version installs now remove all existing folders/files vs just overwrite
+ Restyles and changes to Avalondock manager and float windows
  + Removed Webbrowser from Metro tab control, added as tabbed dockable window
  + Context menu options for float windows: Dock,Stay On Top,Close,Minimize
  + Video Player and Web browser can be tabbed together/split/docked..etc
+ App no longer auto restarts after installing webview2 runtime in first run
+ First refactor pass for Import-Youtube, eliminating use of DataTable
  + Slightly improves performance, but still more cleanup/refactors needed
+ Improved error handling and retries for downloading/processing playlist icons
+ Improved error handling for chat_Webview2 initialization
+ Webplayer for Youtube playback is now enabled by default
+ Improved error and event handling for Spotishell and Youtube modules
+ Improved error handling for Start-Media and streamlink playback
+ Stop-Media now checks for and cancels any media playback runspaces

### Fixed
+ Startup log in missing/wrong folder if app not installed in default location
+ Start-Media could end up in endless loop when auto restarting
+ Null method errors when attempting to refresh itemssources that are not set
+ Rare race condition could occur on startup causing Import-Youtube to fail
+ EQ settings fail to open if no valid AudioSpectrum audio device detected 
+ Optimize-Assemblies gets canceled by Webview2 runtime install
+ Multiple issues with Get-Twitch during first run or for auth capture
+ AudioSpectrum can get 'stuck' on display screen even when disabling
+ Webview2 initialization may fail for Youtube Webplayer or Webbrowser
  + Data folders now separated between webbrowser and youtube instances
+ Pause, mute and other commands not working when playing invidious content
+ Multiple crashes/errors and other issues during First Run Setup
+ Youtube Auth can require recapture even if stored creds are still valid
+ Import Twitch Followed channels fails even with successful auth capture 
+ Some Spotify API calls attempted even if Import_Spotify_Media not enabled
+ Show notifications fail when enabled and playing content with yt_dlp
+ Update-Mediatimer fails when attempting to execute stop on media end 

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.4 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Some kind of Hellish Easter Egg ;)
+ Custom namespace KeyStates.MyHelper to WPFExtensions dll for key capture
  + Allows more performant way to capture key presses with GetAsyncKeyState()
  + Used in some Slider value changed events
+ Custom indeterminate progress indicator animation for Splash screen (meow)
+ Ability to import all followed twitch channels (WIP NOT COMPLETE)

### Changed
+ A dialog now appears if there is a critical error on first setup/startup
+ Open Media buttons now display a file/folder explorer browse dialog
  + Accepts multiple media file selections
  + If single supported media file selected, playback begins immediately
+ First refactor and redesign pass for MiniPlayer (formally TrayPlayer)
  + Redesigned/customized with Denon miniplayer skin as template
  + Most button controls working except for back button.
  + Implemented improved sliders bound to main UI slider and timers
  + Media title/Artist display is working but no scroll animation yet
  + 'Mini' and Detach buttons allow switching from Main to Mini skin
  + (WIP/NOT FINAL) Ability to resize miniplayer width with skin stretch/tiling
+ Further refactors for Get-Twitch/API and Twitch related functions
  + Twitch auth now uses oauth authentication flow to get user tokens
  + Implemented web authentication capture similar to Spotify/Youtube
  + Twitch tab in Setup enabled and can populate with custom/import channels
  + Still WIP, imported channels do not yet add to library
+ Improved Main progress slider design and functionality
  + When hovering over a small thumb icon displays for easier value change
  + Still not final until can find better repeating texture/design
+ Various improvements to error handling for Spotishell and other areas
+ Improved scrolling for media tables in Setup so that headers stay at top
+ Improved WPF rendering quality for various images/skin elements

### Fixed
+ Progress slider not updating after long drag and release
+ Updating theme color causes semi-transparent background under legs of skin
+ Media file count inaccurate for directories under Local Media Setup
+ Unable to remove individual items from Youtube and other tables within Setup
+ Skip to next media fails when using Next button
+ Record button not checked/lit up when audio recording starts
+ Unwanted/extra characters display in media title when Marquee is enabled
+ Write-ezlogs can (rarely) fail when unable to find proper log directory/path

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.3 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ 'Loading' status message displays upon start of any media
  + A loading message replaces the title until media actually starts playing
  + To indicate something is happening especially for long loads or if issues
  + Loading message gradually pulses/flashes while active
  + WIP: May not show (or only briefly) for some media (webplayers)
  + WIP: May be a delay before message updates/disappears for local media  
+ First iteration of Spectrum Analyzer for Digital Display
 + VERY WIP. This pass just gets it working at all in the display
 + Exposed new fields/properties in SpectrumAnalyzer.dll
 + Most styling done was to fix issues, spacing..etc. Not yet styled for skin
 + Ability to toggle/enable/disable Analyzer using the 'Monitor' button
 + Button name is not finalized, nor its function or usage
 + Added beat detection (testing). Shows as 4 boxes that flash per freq update
 + Long way to go, but at least its working in some form now, so there's that

### Changed
+ Multiple improvements to Youtube webplayer when using Invidious
  + Invidious Play state (paused,playing,ended) is now properly tracked
  + Pausing using app controls now works for Invidious web player
  + Auto play now works when using Invidious web player
  + Changing app volume now changes the Invidious player volume
  + Still need to finish and bringing up to native Youtube webplayer parity
  + May become default as native player has issues with licensed content/ads

### Fixed
+ Display Title constantly updated on timer pass when playing Spotify Media
 + Affected Spotify Web player only
+ Multiple fixes applied to SpectrumAnalyzer.dll, mostly for AudioLine

### Builds
+ No version bump, doesn't require re-import/scan or re-setup
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.3 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ New helper function Optimize-Assemblies for improving powershell performance
 + Only runs on first setup or if upgrading to a new version of the app
 + Mostly improves PS startup performance by caching assemblies
+ First iteration of new "Spotify Actions" sub-contextmenu for media 
+ Ability to Add spotify tracks to other Spotify Playlists
  + Accessed from new "Spotify Actions" right click contextmenu on media
  + Does not yet update/reflect within library without full reimport
  + Currently duplicate tracks dont show even if in different playlists (TBC)
+ Ability to Open Spotify tracks within Spotify if installed 
+ Ability to import Subscribed Youtube channels when importing YT media
  + New checkbox option "Get My Subscriptions"
  + Doesnt do much yet other than add to list, will be expanded later
  + Goal is to allow new videos from subscriptions to import
  + Refresh,update/notification for subscriptions planned

### Changed
+ Screenshot button will now include Splash screen in app snapshot if viewable
+ Improved rendering quality and performance for playlist treeview icons
  + Metro IconPack icons are converted to geometry > image source for binding
  + Uses less memory and improves quality when sizing vs static image files
+ Improved performance of updating Youtube lists within First Run/Settings
  + Window no longer locks up when pressing import
  + Button greys out and progress indicator animation shows while working
+ Slight font size and styling changes to digital display to make smaller

### Fixed
+ Youtube API token retrieval sometimes fails when opening first/run settings
+ Get-AccessToken function of Youtube module missing when executed in runspace

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.2 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ First Iteration of Twitch Browser Library (not yet enabled or visible)
  + Added datagrid XAML and initial Import-Twitch code-behind
+ Display Panel Status Indicators for "Shuffle" and "Auto Play"
  + Bound to toggled status of equivalent toggle buttons

### Changed
+ Refactored WebPlayer_Playing_timer code into new module Set-WebPlayerTimers
  + Spotify and Youtube webplayer timers to be merged as well
  + Webplayers now controlled via Set-WebPlayerTimer with action parameters
+ Various legacy and/or commented code cleanup
+ Cached XML for playlists now auto rebuilds if it becomes corrupted 
+ Second iteration of Display Panel Progress slider styling and redesign
  + Now more closely matches "Digital" style of Denon skin
  + NOT FINISHED. Still requires more tweaks especially for "slider thumb"
  + c# code added to allow custom formatting of slider autotooltip 
+ Improved javascript injected code for Youtube Webview2 player
  + Player quality should now always choose highest quality by default
  + Initial testing code for handling fullscreen events (not yet working)
+ Improved error handling for CoreWebView2InitializationCompleted events
  + Event 'IsSuccess' property now properly checked before continuing 
- Removed outdated/unused Media_URL textblock from xaml and code behind

### Fixed
+ Some code formatting and region navigation issues
+ Twitch token gets refreshed every call due to invalid expiration processing
+ Status for some Twitch playlist records not updating on Twitch refresh
+ Progress timer in Digital Display gets cut off when value is large/long

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.6.1 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Initial support for processing and playing Youtube TV URLS
  + Very WIP, only processes manually provided YTV URLs
  + No YTV API available to public, gets basic info from standard API
  + (Issue) Playback ends after current 'program' ends on channel
+ Volume control slider in Video View Overlay Controls
+ Registered event 'EndReached' for libvlc playback (testing)

### Changed
- Removed old play controls/buttons, now uses only new skinned controls 
+ Minor design changes to video view overlay controls (made icons smaller)
+ (Testing) Enabled AllowTransparency on main UI window
+ Moved progress slider to digital display, started redesign of styling
  + Current style is heavy WIP, goal is to match Denon skin progress bar
+ Removed duplicate assembly's from module Burnttoast
+ Testing new FindFilesFast.dll compiled from C# rewrite of VS code
  + WIP: Find-FilesFast now uses this and works for both PS 5 and PS7
  + Credit: NaivE
+ Other minor styling and format changes to main UI XAML

### Fixed
+ Playback sometimes fails due to incorrect value set on VideoView.Height
+ Get-TwitchAPI can fail when saving Twitchexpires_in value to secret vault
+ Some properties returned for Get-TwitchAPI are blank or incorrect
+ Twitch playlists/profiles may not update when Twitch Auto-Update is enabled
+ Saving settings can sometimes fail when Start on Windows Logon is enabled

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe


## 0.6.0 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Easter Egg: NPR Tiny Desk Concert browser (WIP)
  + "Desk" button opens a window with wrappanel of concerts from NPR RSS Feed
  + Clicking on image buttons start playback from NPR stream URL
  + This is mostly for R&D and testing using wrappanels/itemcontrols
  + Not meant to be final, final form likely to be much different
+ Clear Queue button on the Queue tab

### Changed
+ Module Burnttoast is now included instead of installed from the internet
+ Refactored MediaTransportControls into module Start-MediaTransportControls
+ Refactored datagrid paging controls which now use Kino Datapager controls
  + Good performance improvement to datagrid paging, reduces code complexity
+ Multiple style and layout changes to the Display Panel (WIP)
  + Media title now only animates if the text is larger than the screen
  + Various changes to font options and styles to make text clearer
  + Status text now closer emulates "status icons" on a real stereo display
  + Heavily WIP and not complete
+ Refactored Find-FilesFast to remove unused parts of VB code
  + Still needs another pass but this cleans it up a bit
+ Improved performance for Twitch API lookups in Get-Twitch
+ Local Media datatable grouping expanders are now expanded by default
+ Cleaned up Start-Keywatcher, not currently used, may remove in the future
  + MediaTransportControls pretty much replaced this, but may have other uses
+ Replaced cassette door background image with bordered one provided by Woody

### Fixed
+ Saving from setup fails with Set-DiscordPresense error even when not enabled
+ First run setup errors related to main UI controls not yet rendered
+ Spotishell module not importing properly using PSModuleAutoLoadingPreference
  + Improves performance where it previously was manually imported
+ UI and title text "flicker" when playing Spotify media with Web Player
+ Pause command makes an a Spotify API call even when nothing is playing
+ Playback fails for temporary media (not in a profile/playlist)
  + Refers to "one-off" playback such as via cli commands, tinydesk..etc
+ Thumbnail/Covert images not displaying in toast notifications and mini-player
+ Spotify media playback sometimes fails when using webplayer
  + Due to incorrect Spotify_WebPlayer_State.playbackstate value
+ Primary background Samon skin sometimes disappears on end of playback
+ Title bar text for floating Anchorables now bound to main Window title

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.5.9 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Mute icon on video view overlay. Full volume slider will be added later 

### Changed
+ Refactored Playlists and Queue view over cassette player in skin
  + Playlists and Queue list now live together within tab control
  + Playlists now default list when opening, and button renamed to 'Playlists'
  + Using blank skin as background for now until further design changes
+ Current playing item is now highlighted if it exists in a playlist
  + First step towards queue refactor. Goal to allow advancing from playlists
  + Added code behind and xml datatemplate for preparation and testing
+ Redesigned volume knob , vertical slider now overlayed on top on mouse over
  + Testing this design. Slider only shows on mouse over, easier to use
+ Slightly decreased animation speed for now playing icon
+ Improved Digital text slide animation and dynamic sizing of content
  + Not perfect yet, but should now be able to handle long text better
+ First refactor and redesign pass for splash screen
  + Testing with mockup splash screen image of Samson made by Woody
  + Replaced cancel button with standard window close button in top right
+ First pass to lay groundwork for Youtube/Twitch refactor
  + Added module and function Get-Twitch with template for profile processing
  + First pass for cleaning up and separating metadata from youtube
+ Consolidated WPF code behind for events/controls to module Set-WPFControls

### Fixed
+ Now playing icon sometimes doesnt appear in queue for playing item

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.5.8 - Samson-Alpha

### Added
+ Ability to enable Discord Presence integration to display playing media 
  + Toggle option added to settings, off by default
  + Shows title, artist, duration and type (youtube, spotify..etc)
  + Youtube,Spotify label buttons (Watch on Youtube..etc) do not work yet
  + Powered by Powershell Module DiscordRPC with customizations
+ First iteration of new Digital Display controls with animations
  + Implemented scrolling text to display current playing media title/artist
  + Text bindings set to title bar label content (for now)
  + Adjusted fontoptions, fontrendermode and added slight blur radious to text
  + Will add toggle for enabling display animations, perhaps types

### Changed
+ Refactored various WPF event handlers into new module Set-WPFControls
+ Further refactors for new skin/replacement button controls
  + Video View toggle button replaced, events moved to new Video button
  + Autoplay button replaced, events moved to new Auto Play button
  + Shuffle button replaced, events moved to new Shuffle button
  + Play Queue button replaced, events moved to new Queue button
  + Audio Options button replaced, events moved to new Audio button
+ Using webplayers no longer show duplicate controls in windows media overlay
  + The native SystemMediaTransportControls replace these from webview2

### Fixed
+ First run window sometimes not opening/crashing when attempting to load XAML
+ (Requires verification) Autoplay not working when using webplayers
+ Video Marquee not displaying for non-twitch media when enabled

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.5.7 - Samson-Alpha

### Added
+ New Buttons for Samson skin completed
  + Back,Next,Monitor,Mute,Main Menu,Settings,Playlists,Library,Video,Shuffle
  + Some may be changed/removed/added, these get base design/template in place
+ Logic and code behind for new Mute button. Old still in place temporarily
+ Logic and code behind for Power button. Always "active", closes app on click
+ Logic and code behind for Play, Pause and Stop buttons.
  + Play button still needs refactor and some fixes

### Changed
+ Refactored Get-LoadScreen to improve performance and reduce UI stutter
  + New function Update-SplashScreen used to manage updating splash screen UI
  + Uses dispatcher timer vs dispatcher invoke for greatly improved performance
+ Removed Media Library toggle button, logic now attached to new Library button
+ Removed old Settings toggle button, logic now attached to new Settings button
+ Slight improvements to volume knob control
  + Still needs alot of work, likely need to refactor whole thing
+ Set additional various log output to be under verbose logging only
+ Splash screen window startup location now set to CenterOwner
+ Media Library viewer window startup location is now top left of screen
+ Mouse over highlight for new buttons now white, with active being theme color
- Removed Entypo Iconpack assembly, not currently used
- Removed other various assemblies that aren't currently used (hopefully)

### Fixed
+ Partial: Video View overlay controls don't show when undocking window
  + It still doesnt always open but its alot better. More improvements needed
+ Progress bar sometimes doesnt appear or causes extra space below video view

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.5.6 - Samson-Alpha

### Added
+ First iteration of Volume knob animation and control
  + Currently tied to existing volume slider, still need to add direct control
+ First test iteration of new WPF button animations
  + Controls not bound to any logic yet, purely for testing skin animations

### Changed
+ Video Viewer/total app height can now extend to use full height of screen
+ Various renaming of controls and resources to better match new skin
+ Refactored avalondock code into new module Set-AvalonDock
+ Main window startup location is now CenterOwner vs CenterScreen
+ Play Queue flyout is now closed by default on startup

### Fixed
+ Video control overlay sometimes stays opens or opens and closes too quickly

### Issues
+ Video control overlay doesnt appear when video viewer is undocked
  + This is due to WPF airspace issue which is really starting to annoy..

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.5.5 - Pre-Alpha

### Added
+ Native custom WPF Spectrum Analyzer for all primary audio output
  + Uses CSCore to capture loopback audio for any media playback
  + For now only added to Audio options window, only active when open
  + Dynamically updates with theme, optimized for low CPU overhead
+ Integration with SystemMediaTransportControls (Windows Volume/media Overlay)
  + Updates Media title, artist and thumbnail (if available) on media playback
  + Button events captured for play/pause/next/stop using Register-WinRTEvent
  + Replaces need for KeyWatcher runspace monitor for captured buttons
+ ReturnYoutubeDislike script for Webview2 to show dislikes on YT videos
+ Help Button and messages for Audio Output Device option

### Changed
+ Testing Skin changes for slider thumbs using custom images (credit Woody)
+ Double-clicking Tray icon now opens/activates main app window
+ Testing Windows Chrome style changes to main window using rounded corners
+ MediaTable items are now collapsed by default
  + Testing for performance reasons related to contextmenus and datagrids
+ Renamed default prefix for Twitch Media from 'Twitch Streams' to 'Twitch'
+ Reduced libvlc file-caching to 1000
+ Small optimizations and performance improvements for Start-Media

### Fixed
+ Some colors in TrayPlayer style not updating with theme change
+ Improvements to UI performance when resizing main Window

## 0.5.4 - Pre-Alpha

### Added
+ Ability to manually select Audio Output device for libvlc playback
  + Dropdown added to Settings - General page that lists all available output devices
  + Changing device updates output immediately (with slight pause to playback)
  + If using non-default output, Windows volume controls will not work, but players will
+ Ability to view Play Queue within Tray Player via mini flyout
  + Tray Datagrid uses databinding to main Queue datagrid itemssource
  + Ability to use contextmenu to manage items, or drag/drop to reorder
  + Contextmenu looks different due to issue with Tray not inheriting default styles 
+ Ability to enable 2Pass sub-option for EQ under Audio Options
  + Basically increases effect/strength of EQ freq band changes
  + Only takes effect on start of playback, cannot change while playing

### Changed
+ First refactor pass for Audio options overhaul/re-design
  + Audio Options/EQ settings now open in separate window
  + Tray Audio options button now bound to main Audio options button
+ Removed PlaySpotify_Media_Command routed event handler, no longer used
+ New playlist dialog now displays within Media library window if open
+ Expand/Shrink Player button now sets window state to Normal when 'Shrinking'
+ Shuffle icon/button in Tray player now works, databinding to main Shuffle button
+ Adjusted main Window MinHeight and MinWidth depending on if MediaLibrary is open
+ Moved Playlists flyout button to follow Media Library 
+ Improved refresh performance of queue items when changing play state 
+ App now restarts (with dialog prompt) if more than 1 uncaught exception occurs
+ Minor cleanup and optimizations to Update-MediaTimer

### Fixed
+ EQ values reset and dont honor new changed values after closing audio options
+ Main background image not updating on playback
+ Current playing queue item doesnt update properly when using Youtube Webplayer
+ Artist and Title labels in main Window title bar not resetting on playback stop

### Build Updates
+ EZT-MediaPlayer-Setup.zip

## 0.5.3 - Pre-Alpha

### Added
+ First prototype for 'TrayPlayer' interface using Hardcodet.NotifyIcon.Wpf
  + Left click brings up mini-ui with basic media controls, artwork..etc
  + Right-click menu to be rebuilt, only Open and Close options currently
  + Controls use databinding bound to primary app controls
  + Still needs alot of refinement and work, add progress bar...etc
  + TaskbarIcon children dont inherit styling in xaml but codebehind works
  + This means styling is a PITA, but still work it IMO
+ AudioDevice VLC registered event for output device eventargs capture
  + To be used for (future) audio device output selection features

### Changed
+ Default image of Media type now displayed when no artwork/images available
  + This is temp solution. Only applied for background and Trayplayer.
  + Local media is VLC logo, Spotify is Spotify..etc until better default found
+ Now Playing label now separated into Playing State, Title and album labels

### Fixed
+ Playback fails due to queue improperly detecting next media type
+ REGRESSION: Chat webview2 doesnt dispose/hide properly on media change

### Build Updates
+ No version bump, repackaging setup file as ZIP
+ EZT-MediaPlayer-Setup.zip

## 0.5.2 - Pre-Alpha

### Added
+ Ability to save/remember the expanded state of Custom playlist views

### Changed
+ Finished first phase of refactor/overhaul for app settings
  + All options from Settings tab moved to appropriate section in setup window
  + Setup window renamed to just Settings, with updated icon 
  + Updated some help messages, but full documentation system will replace
+ Refactored Spotify setup and profile generation process to match Youtube
  + Import from Spotify button retrieves playlists (with valid auth account)
  + Can now manually add/remove Spotify playlist and track URLs in Setup
  + Profiles now generated for each Spotify playlist added
+ Small updates to profile editor, local media album field now works
  + Not finished. Waiting to finalize metadata and profile structure
+ Minor performance improvements and optimizations for Start-media
- Removed Settings.xaml and a few other non-used/out-of-date files
- Removed and excluded history/versioning zip archives from install package

### Fixed
+ Autoplay setting not applying when using Web players
+ Play Queue entries seem to dissappear for a few secs when queue is updated
+ Use-Runas -Forcereboot fails to detect current script path for restart
+ Multiple fixes when controlling Spotify with Spicetify
  + Debating whether put much more time into this as its prone to error
  + May keep as an "advanced" option as when working well, it is best option
+ Videoview sometimes still visible when playing non-video media content
+ Icons missing for media items in Tray Menus
+ Importing local media fails when adding a single file or directory to library
+ Long media title/names in play queue UI get cut off/can't read

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.5.1 - Pre-Alpha

### Added
+ Ability to toggle Auto Playback of media in the queue
  + New buttons added to play command bar and playback options in tray menu

### Changed
+ Moved Set-Shuffle and Set-AutoPlay into new module Set-PlaybackOptions
+ Updated Youtube and Spotify datatables to use new paging system
+ Removed use of System.Data.DataTable for MediaTable itemssource binding
+ Reduced amount of logging with Verbose Logging disabled

### Fixed
+ Scrolling in datatables become very stuttery after any contextmenu is open
  + Unsure of exact cause, but only happens when CanContentScroll set to true
+ Duration values missing for some media imported from youtube playlists
+ TEMP FIX: Unable to sort datatables using column headers
  + Paging system broke sorting, so this is a temp fix as its pretty hacky
  + Uses Sorting event handler to capture sort events then manually sorts data
+ When filtering with new page system, paging labels and dropdown doesnt update
+ Chat webview2 instance sometimes does not dispose on media change
+ Update_background_timer does not properly detect if current media has video
+ Downloaded youtube media fails to add to existing local media library
+ Media progress slider is still visible after stopping media
+ After playback of last media in queue, the UI doesn't properly reset/update
+ Playlist treeview height stretches beyond viewable area when fully expanded

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.5.0 - Pre-Alpha

### Added
+ Ability to download all Videos in Youtube Playlists when using download media
  + Currently only works when using download command via web browser menu
  + All videos download to chosen folder then tagged with metadata via taglib
  + If download folder is also in a local media library, they are imported

### Changed
+ Greatly improved performance of paging and filter system
  + First iteration of complete refactor and overhaul of paging and filtering
  + Added new assembly Kino.Toolkit.Wpf which provides PagedCollectionView
  + Huge improvements for filter speed, data binding, and page selection
+ Improved performance when removing media from local media library
  + Removal is now executed in a runspace to prevent UI from freezing up
  + More improvements needed, but much better combined with new paging system
+ Improved accuracy of query searches when using 'Find on Youtube'
+ Duration field for local media library now displays in human readable string
+ Improved accuracy of metadata tagged to downloaded youtube videos
  + Links for spotify/bandcamp parsed from video descriptions/comments
  + Found links used to get accurate artist/album and other info
+ Improved memory overhead and performance of Media Library datatables
  + Implemented VirtualizingPanel, mode recycling, for better item draw perf
  + Items may slowly fade in when scrolling, especially if scrolling fast
  + Spotify\Youtube datatables now use DataGridTemplate vs autocolumngeneration

### Fixed
+ Chat webview2 not always disposed after changing media with not chat support
+ Downloaded videos not importing despite being in valid media directory
+ Extra/temp files from yt-dlp downloads not removed after download finishes
+ Local media fields in first run remain disabled if canceling file browse
+ Get-AccessToken for Youtube API fails to properly refresh access tokens

### Added
+ First iteration of quality options and controls for Youtube playback
  + New option 'Preferred Quality'. Applies when NOT using Youtube Web Player
  + Only basic options for now: Low, Medium, Best (best has large overhead)
+ Ability to pause current playing media by clicking on item in queue
  + Uses new module New-Relaycommand for WPF button command bindings
+ Registered event 'EncounteredError' for improved libvlc error handling
+ Support for BetterTTV via custom JS injection for Twitch Chat viewer
+ Ability to cancel audio recorder when invoking Stop Media
  + If recording in progress, prompt displays with choice to cancel or continue

### Changed
+ Refactored vlc and EQ initialization into new module Initialize-VLC
  + Is now also executed from within a dispatcher timer on startup
+ Improved notifications and logging when downloading Youtube media
+ Get-PlayQueue now can now be executed separately from various update timers
+ Chat Webview2 is now only created when used, then disposed after
+ Snapshot button now only enabled if 'Enable Snapshots' is enabled in settings
  + Added extra sub-option to toggle including app screenshots
+ Various small optimizations for memory overhead and startup performance
  + Improved avg startup time by about 1s
  + Improved memory usage for WPF image sources
+ Notification flyout now auto-closes after 10s for new notifications
+ Dismiss All button for Notification flyout now also closes the flyout
+ Refactored Twitch API to use MS SecretStore Vault for auth tokens
+ Improved performance for Twitch API lookups and updates
+ Metadata for downloaded Youtube media is now added via taglib 
+ Increased network-caching for libvlc for web streamed content

### Fixed
+ Unable to add individual Youtube videos via dragdrop and other methods 
+ Twitch Auto-Updates failing or not updating Twitch media items
+ Incorrect binding path set for some datagrid togglebuttons
+ Playlist items now updating/refreshing in some situations
+ Download option missing for Youtube media when in the Queue
+ Play Queue will not advance when playing media with Youtube web player
+ Various wpf binding errors found during VS debugging
+ App freezes or crashes when interacting with the chat webview2 control
+ Downloaded Youtube media does not import into library after finishing
+ Next Media keypress events do not advance the play queue
+ Update-Mediatimer sometimes causes app to stutter or make hard to move UI
+ Play Queue fails to advance if hash dictionary contains a null value


## 0.4.9 - Pre-Alpha

### New Core Feature: Ability to record and save Spotify media to local disk
+ First iteration of Windows loopback audio recording via PSCore assembly
+ App volume effects recorded volume, but windows main volume does not
+ New contextmenu option 'Record Media' available on Spotify media items
+ Currently can select save path, with flac output, full UI options planned
+ Very early implementation, pause/stopping of media wont stop recorder
+ Current supported audio encodings: wav,aac,mp3,wma,flac (Possibly more added)
+ Selecting record starts playback then recorder. Notifications display status
+ Slow flashing recording icon appears in the queue for media being recorded
+ Only available for Spotify Media. Much more to come soon...

### Added
+ Added custom Youtube adblock java script injection for Web Browser
  + Its no Ublock Origin, but greatly improves experience of using YT
+ DEV MODE: Task category for Show-FeedbackForm for dev use

### Changed
+ Updated included TaglibSharp assembly to latest 2.3
  + Fixes bug where ID Tags unable to be written to wav files
+ Load-Modules can now use runspaces to install modules (not yet used)
+ Removed escaped characters from some hardcoded path strings
+ Webview2 Runtime installer now included with package vs downloaded
+ Further adjustments to Window dynamic sizing, minheight, width..etc
+ Streamlink install during first setup now executes in a separate runspace
+ Merged Youtube_datatable into synchash.youtubedatatable for better scoping
+ Further improvements to Spotify Web-player consistency and error handling
  + Added additional retries for 404 errors. Spotify API is dogshit...
+ First iteration of First Run redesign and merge of app setting controls
  + All current options in settings tab eventually will merge with First Run
  + Will be renamed to just 'Settings'
+ Improved wording and clarity of msg when enabling imports that require auth
+ Disabled ability to use autofill for any fields in Web Login captures windows
+ Runspaces now use ImportPSModulesFromPath for passing required modules
+ Progress slider now hidden for media with no total duration (streams..etc)
+ Improved error handling in Write-ezlogs when there are path errors

### Fixed
+ Queue not updating or clearing when using clear queue command
+ Local Media Datatable remains disabled after removing media from app
+ Clearing the queue when using webplayers removes current playing item
+ Removing media from app does not remove it from play queue
+ Now Playing label fails to update in some situations
+ Web Player timer stops due to failing to detect media playing status
+ App freezes when auto advancing queue after end of Spotify web playback
+ Duration metadata missing from local media despite being available from taglib
+ Get-localmedia sometimes fails when no media profile cache file exists
+ Add-TrayMenu continuously updates/refreshes with timer while playing media
+ Adding new YT sources fail to add to Youtube_Playlists sources in app config
+ If providing YT auth after starting setup, finishing returns to setup window
+ Updating media sources crashes app when local media import is not enabled
+ Local Media images sometimes dont display despite being available with taglib 
+ Youtube auth UI reappears after setup completes despite successful capture
+ Pode server for Youtube auth capture doesnt properly close when finished

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.4.8 - Pre-Alpha

### Added
+ Ability to use 'Minimize to Tray' option in settings
+ Ability to use 'Start Minimized' option in settings
+ Reset Media Player dispatcher timer for thread agnostic UI reset
+ New config values for vlc/streamlink log level and log path
  + Will expose via UI/Settings later on

### Changed
+ More improvements to Spotify/Youtube Webplayer reliability and performance
  + Spotify and Youtube now use separate webview2 instances
  + These instances are always disposed when not in use then recreated
  + Added retry for Spotify if API returns 502, so far good results
  + Still small delay on Spotify first start, but quicker when switching after
  + Improved autoplay consistency for Youtube webplayer
  + Improved volume/mute synchronization with slider/icon
+ Spotify Webplayer is now enabled by default and preferred option
  + Plan to add webplayer options to first run setup page
+ Reduced VLC and Streamlink log levels from Debug to Info
+ Renamed 'Get My Videos' button to 'Get My Uploads' on Youtube first run page
+ Various minor tweaks and changes to UI styles, mostly for text readability

### Fixed
+ Spotify webplayer sometimes doesnt detect end of track and advance queue
+ High CPU/GPU usage while playing media with icon animations
+ Media library items become blank or missing when using filter/search
+ Media library always blank when there is only 1 item in datasource
+ Video fails to appear when playing media with very long title names
+ Now playing icon not updating when using webplayers
+ Now playing title bar label not updating for vlc playback
+ Volume value and mute status not always accurate or updated on change
+ Keys with null values sometimes get added to queue hashtable
+ Various issues with UI controls not resetting or updating on media change
+ Errors thrown when parsing some media duration values that are 0
+ Skip media not always advancing the queue properly

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.4.7.1 - Pre-Alpha

### Added
+ 'Find on Youtube' contextmenu option to search Youtube for selected media
  + Opens youtube with internal web browser, searching for media title
+ Ability to download Youtube videos directly from internal web browser
  + While browsing youtube, right click on video and select download
  + Will also add the media to the local library when download finishes
+ First iteration of a Special Easter Egg, that does things and stuff....

### Changed
+ Sys tray icon text now updates in sync with Now Player label
+ Updated editor window sizing and style to adjust better to content

### Fixed
+ Editor window can sometimes freeze or cause whole app to crash
+ Start-Media fails when parsing null media duration time
+ Viewer count changes incorrectly for Twitch media when auto update is on
+ Whole queue disappears until refreshing after removing an item
+ Text input for Media player not working when open in separate window
+ Download menu option missing for youtube items in queue and playlists
+ Downloading Youtube videos can fail under certain situations

### Build Updates
+ EZT-MediaPlayer-Setup.exe
+ No version bump

## 0.4.7 - Pre-Alpha

### Added
+ First iteration of new file scanning with module Find-FilesFast
  + Uses inline VBS to access low-level WIN32_FIND_DATA API for fast enumeration
  + Initial tests show nearly 50% performance boost and better error rates
  + Filters out files with attributes Hidden, System, and Reparse Point
+ Mahapps SimpleChildWindow assembly for potential futuer use
  + Can create independent, movable windows within main UI visual tree (widgets!)

### Changed
+ Improved reliability and start playback speed of Spotify Web player media
 + SDK java now initialized with AddScriptToExecuteOnDocumentCreatedAsync
 + Spotify's API/SDK seem very flaky (many timeouts), lots of similiar reports

### Fixed
+ Restart media skips to next in queue instead of restarting for some media

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.4.6 - Pre-Alpha

### Added
+ Assembly Hardcodet.NotifyIcon.Wpf for potential replacement of NotifyIcon
  + Nothing implemented yet. May provide better control/features for tray menu
+ Ability to take Snapshots of app windows and optionally videos
  + First iteration. New Snapshot button/icon in top right command bar
  + 'Saved Snapshots path' option: Directory where snapshots are saved
  + 'Enable Video Snapshots' option: snapshots any playing video when capturing
  + Takes separate snapshots for each app window that is open
  + Each window is brought into focus quickly to ensure clean snapshot
  + Window captures mostly for testing/support. Video snapshots can have handy uses
+ Ability to 'undock' and move Media Library into a separate window
  + Mimics mini-player behavior, still operates in same UI thread
  + Media player can still be collapsed/expanded when 'docked' into main window
+ Added 'Dismiss All' button for notifications flyout
+ Ability to choose media to play from playlists in system tray menu
  + Limited to the 25 latest playlists and 25 latest tracks for each playlist

### Changed
+ Updated Splash Screen for support of...um...things
+ Further adjustments to dynamic sizing of UI elements under various conditions
+ Separation of GetPlaylists and Get-PlayQueue now completed
+ Restyled Audio and Playlist flyout buttons as Toggle Buttons
+ Improved memory and resource management
+ Various minor adjustments to Show-FeedbackForm and Trello API posting
+ Current playing Spotify track now displayed on windows volume overlay
  + Only works when using Spotify Web Player
+ Media Library and Managed sources button moved to top right
+ Refactored Add_to_PlaylistCommand to use dispatcher timer
+ Temp Moved PreviewDrop_command into global for future refactor
+ Main UI window no longer hidden when Show-Weblogin is displayed

### Fixed
+ Duplicate items sometimes can get added to play queue
+ Play icon animation always active even if not playing causing CPU/GPU idle usage
+ Queue disappears until new media is added after media has stopped or ended
+ Unable to dragmove the splash screen under some conditions
+ Notifications with long text cutoff/unable to scroll horizontally to read
+ Navigation with Hyperlink_RequestNavigate fails for some paths 
+ Saved/current volume not applied to some new vlc instances
+ Initialize-webplayer fails when Webbrowser tab not enabled
+ Main UI window resizes incorrectly when starting playback of new media
+ Update-MediaTimer fails on next track selection when chat view is enabled

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.4.5 - Pre-Alpha

### Added
+ Ability to add media to library by opening it with EZT-Mediaplayer.exe
  + First iteration of basic cli support, more features to be added
  + PLANNED: Ability to start playback of file opened with player
  + PLANNED: File association mapping and 'open with' context menu option
+ HasVideo property on media profiles for identifying content type (future)

### Changed
+ Disabled icon animation for current playing item in queue
  + Temporary, animation was causing cpu/gpu resource issues
  + Was always playing for all items in queue, even when icon not in view 
+ Refactored launcher to allow support of cli/parameters passed to main app
  + IEXPRESS no longer used, now built with ISESteriods exe packager
+ First iteration of Datagrid XAML refactor for Media library
  + Only applied to Local media datatable,no longer uses 
  + Autocolumngeneration replaced with XAML datagrid template columns
  + Will allow more flexible styling and data binding vs using code behind
+ Media tables and playlist minheight now bound to tabcontrol height
+ Moved Get-Songinfo from Get-HelperFunctions to Get-LocalMedia module
+ No longer storing picture byte data from taglib in profiles
  + Too much data, no need to store. Data now parsed at playback runtime

### Fixed
+ Entire app freezes when enabling Import Youtube for the first time
  + Enabling still has a sec or 2 lag (to be fixed) but 'should' work now
+ Partial Fix: Media tables blank when there is only 1 media item
  + Row now shows up with play button, but all column fields still missing
  + As soon as there are 2 or more items, all works properly
+ Artist name missing or incorrect even when available from taglib parse
+ Progress indicator not showing when adding local media in first run table
+ First run prompts about keep existing playlists even when none exist
+ All_media cache xml sometimes exports as psobject instead of arraylist
+ Regression: Some youtube media tries to play with streamlink
+ Enumeration failure sometimes occurs when checking existing runspace jobs
+ Youtube auth prompts again after first run even when auth was successful
  + Not 100% on this fix, may still occur under some conditions

### Build Updates
+ EZT-MediaPlayer.exe
+ EZT-MediaPlayer-Setup.exe

## 0.4.4 - Pre-Alpha

### Added
+ EXPERIMENTAL: Taglibsharp assembly for read/write of metadata (Find Credit: Woody)
  + Potentially to replace Shell.Application in Get-Songinfo
  + Initial tests show avg 50% performance improvement vs Shell.Application
  + Now extracting embedded image data from files (directory images now a fallback)
+ Status label text for MediaTable in-progress indicator

### Changed
+ Refactored Chat_Webview2 into Initialize-ChatView function
  + Chat Webview2 instance now only initialized when chat content available
+ Expand/Shrink button now closes fullscreen window if open when 'shrinking'
+ Minor improvements to startup performance via async initialization of webview2 
+ Restyled and moved Playlists flyout button to top control bar
+ Minor changes to themes and style colors
+ Various adjustments to flyout and grid dynamic sizing and animations

### Fixed
+ Play queue, playlists and media library styles don't update when changing theme
+ Adding youtube media via web browser fails when parsing duration timespan
+ Local media table doesnt update when removing directory paths from Manage Sources
+ Spotify auth window randomly pops up with 'missing client_id' message
+ Playing some local media fails due to trying to parse with streamlink
+ Various app freezes when starting playback of some media with invalid duration
+ UI background/cover image, and progress slider doesnt reset when Stopping media

### Build Updates
+ EZT-MediaPlayer-Setup.exe
+ Future compiled builds to be automatically posted to 'Builds' list in Trello

## 0.4.3 - Pre-Alpha

### Added
+ EXPERIMENTAL: Ability to add media directly from Webview2 contextmenu
  + Allows browsing YT web interface to search then add to playlist/library
  + Unsure if will stay, or if Web Browser itself will stay. For science.
+ Ability to play/pause by clicking anywhere in video viewer
+ Ability to collapse Playlist and Media Tables (now called Media library)
  + New Media Library button expands/collapses all bottom tabs
  + New Playlists button to expand/collapse playlist tab (within bottom grid)
  + Current implementation mostly for concept testing, not final design
+ New custom WPF attached behavior for animating resize of grid columns
+ Ability to add entire playlists to queue using drag/drop of playlist header
+ 'Playlists' Menu in Tray for quick playback start of playlists (Max 50)
  + Allows quick way to start playing a playlist without app in focus
+ 'Playback Options' menu in Tray for quick toggle of various settings
  + Currently only Shuffle option available, more to be added
+ Ability to add media to playlists via drag/drop from Media library tables
+ Get-CurrentWindow for finding current active Window properties
  + Not yet used for anything, will be useful for multi-window management

### Changed
+ Greatly improved buffering, stutter and smooth playback for video streams
  + Enabled twitch low latency support in streamlink for Twitch streams
  + Adjusted network/file caching, clock-jitter, and clock-sync for libvlc
+ Refactored Webview2 initialization code into module Initialize-WebView2
  + Web Browser now separate webview2 instance vs sharing with web player
+ Removed 'Select' column and restyled Play column from media datagrids
+ All selected items are now always added to playlists when using context menu
+ Max Height for main UI window now set to detected primary screen Height
+ Chat button now only enabled if playing media with supported chat
+ Refactor and UI style resdesign for First Run Setup window
  + Added Next/Prev button for navigation through tabs/setup options
  + Setup/save button still visible without having to go through all tabs
  + Design/function not final, to help 'Guide' new users through setup
+ Multiple changes, additions and refactor for Show-FeedbackForm
  + Feedback form now sends to Trello via API
  + Option added to allow sending current copy of logs, with link to review
  + Ability to send multiple attachments via multiselect in Browse dialog
+ Removed all_playlists synchashtable and merged into synchash.all_playlists
  + Mostly for easier scoping and general code sanity
+ Add-TrayMenu now executed using dispatcherTimer to prevent thread issues
+ Replaced MediaLibrary and Playlist flyout buttons with ToggleButton
+ Reorganized, consolidated and other changes to Inno Setup pages
  + Changelog and Readme are now links to latest versions on github

### Fixed
+ Unable to sort datagrid columns for media browsers when using paging
+ Open in Webbrowser fails for youtube media
+ Total/Current duration missing or invalid when using YT web player
+ Media starts then immediately skips to next in queue when using web player
+ Various issues with current playing media not adding or updating in queue
+ Youtube web player error/failures when playing embedded playlists
+ First run setup doesn't trigger when running new versions for first time
+ Invalid or blank entries sometimes added to Play Queue/Playlists
+ Adding youtube urls fail when url contains timestamp parameter
+ Various issues with Drag/Drop for Playlist items
+ Existing youtube playlist/sources get cleared upon setup of new version
+ 'Play All' from playlists fails to add media to queue or start playback
+ Various adjustments for grid/flyout sizing issues
+ Get-YouTubePlaylists fails API DNS lookups on some machines
  + Some dns fail for googleapis.com, but youtube.googleapis.com is fine
+ Spotify API calls fail due to weird switch variable issue
  + Strange, somehow a switch param is triggered even when not set
+ 'Import from Youtube' button never enables after Youtube auth capture
+ Show-WebLogin fails to load for Youtube auth capture during First Run

### Build Updates
+ EZT-MediaPlayer-Setup.exe

## 0.4.2 - Pre-Alpha

### Added
+ Ability to automatically import youtube playlists from provided youtube account
  + New button 'Import from Youtube' on Youtube importing tab of setup window
  + Button allows manually importing or refreshing/checking for changes
  + New module Get-YouTubePlaylists, separated from 'Youtube' module
  + Separate profiles now created for each yt playlist (not yet used anywhere)
+ First iteration of new authentication capture for Youtube Oauth2 API integration
  + Presents login web page similar to Spotify, auth and refresh tokens stored in Secure Vault
  + Auth can be removed/updated anytime from Manage Sources
  + Youtube API used for all youtube parsing except during playback/download which requires yt-dlp
  + Ability to automatically import playlists from youtube account not yet implemented (WIP)
+ First iteration of separate Twitch Media import management
  + Twitch import options added to first run (NOT YET FUNCTIONAL)
  + Currently Twitch media is processed as part of youtube, will be separated with own profiles
  + PLANNED: Twitch oauth2 and ability to automatically import subscribed streams
+ 'Show Only' combobox on Spotify and Youtube tables for quick filtering of items by Group/Playlist
+ Datagridextension column filters added to Spotify and Youtube datagrids
+ Pause Media option added to System Tray menu
+ Next Media option added to System Tray menu
+ Next Media button added to primary playback control bar
+ Refactored Show-FeedbackForm with integration with Trello with ability to send attachments

### Changed
+ First iteration of resdesign and refactor of Play Queue and playlists modules
  + Play Queue converted to datagrid as using treeview no longer made sense
  + Queue panel is now a flyout control, with ability to hide/show using button in control bar
  + Ordered Index/key displayed for each item which updates accordingly when rearranging/adding.etc
  + Playlists moved to separate tab control at bottom grid with splitter between media tables
  + Added icon with Storyboard animation for current playing item in queue (record/disk spinning)
  + Refactored drag/drop to support new queue
  + Restyled tab headers for playlist and media tables
  + Still much more to do..
+ Open with Web Browser option added to contextmenu for any media with valid web url
+ Now only new youtube URLs are processed when added instead of reimporting all of them
+ Various updates and changes to WPF styles and controls
+ First iteration of resdesign and refactor for First Run Setup
  + Import options now separated into tabs
  + Setup like navigation planned, with added summary final page 
+ Refactored PauseMedia routed event and moved code into new module Pause-Media
+ Color for Main window Title menu icon now changes to match current selected theme
+ Minor performance improvements to filtering on Spotify and Youtube datagrids
+ Disabled adding EnableLinkedConnections to registry automatically
+ Improved performance when checking for valid media in paths for Import-Media (Credit: Woody)
+ Media tables are now only displayed when its associated import media option is enabled
+ Various adjustments and small changes to UI styles
+ Various code and comment cleanup

### Fixed
+ closing the pop-out player with web player enabled doesnt restore video to the app window
+ Multiple issues with drag/drop for playlists and queue
+ Multiple issues with failed Spotiy API calls due to issues accessing tokens from secure vault
+ Currently playing item in play queue doesnt update properly for Spotify playback
+ Some Spotify media starts playback then stops after a few seconds
+ Spotify app (appx version) pops up and doesnt disappear when starting spotify playback
+ Playing media with web players enabled sometimes fail to load
+ Now Playing title bar doesnt update when playing media with web players enabled
+ Twitch view count display becomes inaccurate after switching between streams or other media
+ Title missing when adding youtube links via drag/drop
+ Stopping or Pausing then Playing media causes media to be removed from Queue
+ Volume resets when using Restart Media button 
+ Various Pagination issues for Spotify and Youtube tables
+ Page combobox for datagrids do not update when changing page via next/prev buttons or filtering
+ App freezes when displaying modal dialogs after using the Profile editor 
+ App freezes when runspace cleanup attempts to close runspaces containing UI threads
+ Some Spotify API calls fail to get current access token from Secret Vault
+ Spotify media playback timer fails to start or times out waiting for playback to begin

### Build Updates

## 0.4.1 - Pre-Alpha

### New Core Feature: Theme System
+ First iteration of UI theme system leveraging Mahapps ThemeManager
+ 'Change theme' menu added to title bar menu with options for both Light and Dark
   + Note: Light themes aren't fully implemented yet and are pretty unusable atm
+ Themes are saved and persist across app restarts
+ Very basic at the moment, but planned to evolve into full skinning customization
+ Some secondary UI windows may not yet update with theme change

### Added
+ Stop Media option added to System Tray Menu (Testing)
+ Convert-Color function for converting RGB to HEX and vice versa
+ First iteration of Youtube API integration, adapted (and fixed) from 'Youtube' PS gallery module
  + Not yet exposed for usage, dev testing only. Initial testing works for dragdrop yt links
  + Youtube auth works similar to Spotishell, capturing via webview2
  + PODE http server is used to capture responses from redirectURI. Tokens stored in Secret Vault
  + Will eventually replace yt-dlp for everything except parsing playback stream urls
+ Dev_Override: variable to override certain defaults or settings not available to users
+ Ability to start playback via double-click on items in datagrids
+ Theme support for Splash Screen
+ InputDialog.xaml for future custom input dialog styling
+ 'Show Only' combobox on LocalMedia table for quick filtering of items by Group/Artist
  + Only for local media table for now while in development/testing.
+ Theme Support for Show-FeedbackForm and Show-WebLogin
+ Support for playback of Youtube live streams with native player
  + WIP and in development. Uses streamlink similar to Twitch streams
+ Get-YouTubePlaylistItems added to Youtube module for parsing youtube playlists and videos

### Changed
+ Improved async binding for datatables
+ Running app conflict detection now occurs both in launcher and main startup
  + Extra safety net and for when launching app directly from script vs exe
+ Various updates to Theme System
  + Improved RGB/HEX color darkening accuracy for background gradients
  + Added theme support for Audio Settings and Help Flyouts
  + Added theme support for First Run Setup UI
  + Button controls now updated with theme appropriately
  + First Run title menu icon now updates with theme change
+ Enabling Import Spotify no longer triggers Spotify login window
  + Message is displayed indicating whether auth needs to be captured with link to open it
  + Login window will display upon Saving/Starting Setup, if not already captured beforehand
+ Improved parsing/searching of local and remote required modules paths
+ Improved performance of bindings and other updates to the local media datatable
  + Improved search/filter text performance slightly
  + Improved adding/deleting item performance slightly
  + More work to be done here especially with pagination and other datatables
+ Main window no longer hidden when updating media sources
  + Setup window and all actions from it now execute in run-spaces
+ Improved error handling for Get-Songinfo and Spotishell
+ Added theme support to Profile Editor and Weblogon windows
+ Updated Remove-SpotifyApplication to allow removing stored Spotify vault secrets
+ Various optimizations to Start-Runspace for better logging and use of MTA for non UI threads
+ New Playlist names now limited to 100 characters. A warning is displayed if over
+ Removed datagrid Filter option from the 'Play' column of Local Media Browser
+ 'Add Media' button now allows adding multiple comma delimited paths
+ Local Media table is now disabled when adding new media
+ Small changes to datagrid header template bindings for future flexibility
+ Youtube import/scan of video/playlists now use new Youtube API integration
  + Massive performance improvement. Old with yt-dlp avg 3-5mins for 82 items, new avg 4secs!
  + Some meta data like duration missing for playlist videos, but grabbed on playback start
  + Get-youtube requires large refactor to separate Twitch processing and general optimization
+ Minor performance improvements to local media table filter and pagination updates
+ Various changes and cleanup to verbose logging
+ Updated included build of yt-dlp to latest version

### Fixed
+ Browsing local paths via 'Open file Location' fails if invalid path characters
+ Libvlc volume doesn't update to saved/previous value until manually changing
+ Now playing title bar doesn't reset after media stops
+ Filter search fails when searching for items with illegal characters
+ More issues with some local media failing to import/scan due to illegal path characters
+ Theme resets when starting playback of Spotify media
+ Media timer doesnt start for some Spotify media if title contains illegal characters
+ Adding media paths via 'Add Media' fails if path includes quotes (and other illegal chars)
+ Browsing via 'Open File Location' fails for some media
+ Regression: UI Theme resets when starting playback of Spotify media
+ Existing notifications can sometimes be unintentionally overwritten with new ones
+ Setup sometimes never continues after clicking 'Start Setup' in the First Run Setup window
+ Setup does not properly cancel if closing First Run Setup window manually vs Cancel setup button
+ Local media table Page number combobox doesn't update when filtering or changing pages
+ Get-Spotify fails to parse playlists after implementing Secret vault for Spotify authentication

## 0.4.0 - Pre-Alpha

### Added
+ Support for Spotify Windows Store version
  + App now checks for both Appx and normal desktop installs of Spotify
  + Spicetify NOT compatible with Appx version, will not allow enabling if detected
  + Appx version has no cli support so cant start minimized, among other things
  + Seriously dont use the appx version it sucks
+ Assembly and attached property DataGridExtensions for Datagrid filtering
  + Testing for better search ,filter options and performance
  + Only applied to Local Media table
+ New uninstaller script for improved cleanup of components when uninstalled
  + Confirmation Prompt is shown with list components to be removed 
  + Only removes modules and apps that were installed at time of app install
+ Force parameter for Get-InstalledApplications to allow running under user context
+ Microsoft SecretManagement and SecretStore to required modules to install
+ WebView2 option '--autoplay-policy=no-user-gesture-required' for auto-play
+ First iteration of framework for using Spotify Web Playback SDK
  + Will allow full integrated control without needing Spotify client installed
  + Will enhance and replace current Spotiy Web Player implementation
+ Progress ring displays while Import-Spotify is processing
+ Refresh_All_Media parameter for Get-LocalMedia and Import-Media

### Changed
+ Add Youtube Video button now executes in background runspaces
  + Main window no longer hidden and splash screen no longer displayed
+ Refactored Import-Youtube for performance and code consolidation
  + Now always executes in own runspace to free up the UI thread
+ FullScreen pop-out button now disabled if not playing media with video content
+ Improved error handling for Set-WindowState
+ Improved error handling and requirement verification for Invoke-Spicetify
+ Improved error handling for Spotishell
+ Refactored SpotiShell to store and retrieve credentials from encrypted SecretVault
  + Access tokens and other auth data no longer stored in local json file
+ Improved responsiveness when enumerating files/folders in first run setup
  + Enumeration for each folder added now runs in a separate runspace
  + Progress ring displayed and Start Setup button disabled during enumeration
  + Dialog displayed with option to wait if canceling setup during enumeration
+ Import-Media now executed in its own runspace to free up the UI thread
  + Progress ring displays for Media table while import-media is processing
  + Reduces start to UI display time by avg of 3s for 2500 media items
+ Consolidate related RoutedEvent Handlers into Import-Media
+ Various refactors for cleanup and improved organization
+ ReparsePoints and Temporary attributes now skipped when enumerating local files
+ Improved error handling and user notification for Spotify web player
+ Refactored Import-Spotify for performance and code consolidation
+ Improved conflict handling for Runspace job handler
+ Various refactors for cleanup and improved organization
+ Saving changes with Manage Sources no longer initiates first time rescan
  + Main window is no longer hidden and splash screen no longer displayed
  + A rescan of local and Youtube media only occurs if new sources were added
  + Any rescans are done in background runspaces so app can continue to be used
  + Removing sources does not yet remove associated media items (Planned)
+ Local Media browser table is now disabled while scan is in-progress
  + To prevent manipulating the table while its being populated/updated
+ Local media rescans now only scan newly added/detected paths vs everything
  + Separate option to allow full rescan of all is planned to be added
  + Also planned for Spotify/Youtube media rescans
+ Minor adjustments to stacktrace and catcherror log outout

### Fixed
+ Get-playlist fails when attempting to import playlist cache file not yet created
+ Spotify media fails to play when executed from Next keypress event
+ Next keypress events fail when processing Spotify media
+ EQ not applied until enabling then disabling while media is playing
+ Exception can occur when updating current playing item in Queue for some media
+ Current playing item in Queue does not update when using Spotify Web Player
+ Text of various buttons become unreadable when in disabled state
+ Main Window does not maximize, dock or resize properly
  + Caused by AllowTransparency property, also fixes sizing performance issues
+ Video player opens new window that cant be closed on playback of some media
  + Occurred when next queued item to play is audio and previous was video
  + Occurred when 'Enable Audio Visualizations' was enabled
+ Enabling/Disabling shuffle doesnt take affect until app is restarted
+ Using next keypress to play next item in queue restarts/repeats same media
  + Also applies to issue: keypress not advancing queue when using web players
+ Filter/search causes incorrect sorting for Local media table
+ Filter/Search not working for Spotify and Youtube tables
+ Group headers appear blank for Spotify and Youtube tables
+ Enumeration error when updating itemsource for local media and Spotify datatables
+ Spotify browser Progress ring never deactivates when import is finished
+ Thread access violation occurs when updating Groupdescriptions for Spotify table
+ Multiple file enumeration runspaces sometimes cancel out due to the same name
+ Local media paths do not get removed when saving changes to 'manage sources'

## 0.3.9 - Pre-Alpha

### Added
+ New Option: 'Enable Audio Visualizations', available under Media Player Options in Settings tab
  + Enables Visualization in place of video player, for audio only file playback
  + 2 Visualization options available, Groom and Spectrum. More to be added
  + Changing options take affect on the start of the next media.
+ New option: 'Install Spotify' available when enabling Import Spotify Media during First Run
  + Enabling will detect and install latest Spotify client if not already
  + Disabling will prevent auto install, but prevent Spotify features from working
+ License and disclaimer agreements to be read and accepted during setup or upgrade
  + Still mostly placeholder but includes most crucial info for Pre-Alpha usage
+ Help flyouts can now display clickable Web and Local URLs

### Changed
+ Greatly improved reliability and performance of local media file enumeration on PS 5
  + If sub folders/files in path have an error, they are skipped vs entire enumeration canceled
  + Initial tests of entire C drive show enumeration improvement from avg of 5+ mins to 1min
  + Improved accuracy of media file count when adding folders during First Run
+ PODE module is now included directly and no longer is downloaded/installed from gallery
  + PODE is now loaded and started only if 'Use Spicetify' is enabled
  + Using PODE/Spicetify requires running as admin, prompt displayed to user when enabling
  + Option provided to auto run app as admin when enabling PODE/Spicetify
+ Spicetify is now only installed when 'Use Spicetify' option is enabled
+ Path to app exe field no longer required when enabling option 'Start on Windows Logon'
  + Correct path from registry used. If reg path is missing/invalid, path can be provided
+ Updated Startup Audio easter egg video ;)
+ Improved logging and error handling when Applying and Removing Spicetify customization's

### Fixed
+ Some required apps install or update even when option is disabled
+ Local media import fails for all files in provided path if single file or directory has errors
+ Spicetify sometimes doesn't disable/enable properly when applying settings


## 0.3.8 - Pre-Alpha

### Added
+ New System Tray Menu to allow quick access to various controls 
	+ Currently only "Open App" to bring app to front/focus and "Exit" exit, other to be added 
+ Additional performance logging for measuring startup of media import commands/functions
+ First iteration of feature: Spotify Web Player for playback without Spotify Client 
	+ Allows playing Spotify media using the Spotity embedded web player via Webview2 control 
	+ Similar limitations as Youtube web player (no queue management..etc) 
	+ Autoplay 'works' but is inconsistent due to needing javascript to start playback 
	+ Option 'Use Web Player' added to Spotify Options under Settings tab 
+ Ability to save Youtube login credentials from webview2 cookies 
	+ Login persists even after clearing webview2 cache/cookies 
	+ Mostly beneficial for Youtube web player

### Changed
+ Refactored Initialize-XAML to improve performance. Avg improvement around 500ms
+ Renamed Play-SpotifyMedia to Start-SpotifyMedia to align with naming best practices 
+ Various code and comment cleanup

### Fixed
+ When saving a new custom EQ preset, the current selected preset doesn't change to the new one 
+ Unable to login to Google/Youtube via Webview2 
	+ Workaround sets user agent to Android 
+ Unable to click the 'Cancel' button on the splash screen 
+ Album/Artist images and background not displaying when playing Spotify Media 
+ Spicetify currently is broken/can't be applied due to latest Spotify update
+ Not all media is removed when selecting multiple in Spotify or Youtube tables 
+ Refresh/import of media does not start after clicking Save Changes when updating media sources 
+ Newly added Youtube media sources are not imported when updating media sources

## 0.3.7 - Pre-Alpha

### Added
+ Ability to immediately start playback of youtube links added via drag/drop
	+ Requires enabling 'use Web Player' and 'Start Playback Immediately' options for youtube 
	+ Links continue to be processed and added to profiles during playback 
	+ Media will not appear in the Queue or any lists until processing has completed 
+ Ability to cancel startup or close the app by clicking 'Cancel' on the splash screen
+ Ability to enable playback of audio/video clip on the splash screen during startup 
	+ Includes placeholder clip for now ;) 
+ Ability for launcher to detect if existing app process is already running 
	+ Prevents issues with multiple apps running. A warning is displayed if existing detected 
+ First iteration of Profile Editor for editing meta data and other properties of media 
	+ Edit Media option added to contextmenu. Only title/artist/album properties currently 
	+ Runs in separate runspace so main UI is still free while editing 
+ Ability to save cookie authentication for Spotify and Twitch even when clearing cache 
	+ Preserves login to Twitch chat for as long as cookie auth is valid (30 days default) 
	+ Spotify auth saving will be useful in a future Web Player option for Spotify 
	+ Google doesn't allow login from Webview2 officially, but found workaround to test 
	+ Toggle option to be added for this behavior, possibly save in SecretStore Vault 
+ Ability to navigate to log file directory from link in Log options in Settings tab

### Changed
+ Help flyout messages now appear with warnings or critical errors during first run 
+ Improved error handling to prevent First Run window crashing and skipping setup + Improved performance when scanning, enumerating or importing local media 
	+ Performance is further improved when running the app on PS 7 
+ First run window now has X close button and Title Menu with app icon 
+ Can no longer continue setup if at least 1 import option is not enabled in First Run 
+ Various refactors and optimizations for improved startup performance (avg 1s improvement) 
+ Minor improvements to Start-EZLogs by using .NET calls vs Get-CimInstance for log header
+ Refactor of Performance logging for more accurate measurement of startup time 
	+ Now using measure-command for measuring execution of some functions
+ Main window image/background is now reset up starting or stopping playback of any media 
+ Refactored Start-Splashscreen to be consistent with other windows for loading xaml 
+ Using the X close button for First Run now properly exists the app vs just the window
+ Various changes to main theme and UI styles. Increased gradient spread for main background 
+ Various media properties added to local and Spotify media to standardize
+ Replaced robocopy with EnumerateFiles() in Get-Playlist for better performance and less issues
+ Minor performance improvements for Next keypress events in Start-Keywatcher 
+ Spotishell device commands no longer executed when Spotify media is not playing/enabled 
+ Spicetify is no longer auto applied/removed when applying settings 
	+ There are now separate Apply/Remove buttons for Spicetify 
	+ Splash screen is no longer displayed when apply settings as well, only for Spicetify 
	+ Error handling and notification to user improved for applying/removing Spicetify

### Fixed
+ First run crashes if adding paths to files/folders the current user has no permission to
+ Detection/install of Nuget and PowerShellGet fail when running under user context
+ While media is playing, app can sometimes freeze when starting or restarting media
	+ A dispatchertimer is now used to invoke Start-Media from within existing runspaces
+ Removing multiple selected local media only removes the last item in the selection
+ Get-playlists fails if media has no artist or duration properties set
+ Some local media have missing or blank titles in the queue or playlists
+ Multiple Webview2 UserDataFolders get created in the apps temp folder
+ Install of some required modules/apps fail due to launcher using -NonInteractive parameter
+ Exception occurs in Get-LocalMedia due to invalid media profile path
+ Importing Youtube media fails if another video from the same channel exists
+ Start-media can get caught in a loop when attempting to auto-restart 
+ Profile path property missing for Spotify media 
+ Canceling or closing Setup from Manage Sources button causes entire app to quit 
+ Generating titles from directory name fails if local media lives in a drive root 
+ Title property missing/blank for some local media when added to custom playlists 
+ Datagrid results become sorted incorrectly after using filter/search box 
+ Download Media option appears in contextmenu for Twitch Media, which can't be downloaded 
+ Fetching next media to play in queue can fail in Next keypress events for local media

## 0.3.6 - Pre-Alpha

### New Core Feature - Youtube Web Player
+ New Youtube Option 'Use Web Player' allowing playback of youtube media via webview2
+ PRO: GREATLY improves performance of the time from pressing Play to when playback starts
	+ Native playback via yt-dlp avgs 10s for playback to begin, Web Player avg 2s
+ PRO: Download (most) videos by right-clicking on the video and selecting 'Save Video As'
+ PRO: No Google tracking of what your watching (if that matters to you)
+ CON: Volume/EQ, Audio settings and some playback controls unavailable except STOP, MUTE
	+ Mute still works using new isMuted feature of webview2 to mute all webview2 audio
	+ Can use controls within the html web player vs the apps native controls
+ CON: Auto play/tracking of items in the Play Queue is unavailable (shuffle,next/prev..etc)
	+ May have potential workaround solution for this in the future using audio events

### Added
+ New Option 'Enable Marquee Text Overlay' for display info over top of the Video Player
	+ For Twitch media, stream viewer count is displayed, else its media title/artist..etc
+ Ability to display Profile icons/logos for Twitch Channels/Streams in Playlists/Queue
	+ If none available defaults back to using general Twitch logo
+ Expand/Shrink player button next to fullscreen and chat buttons
+ Expand/Shrink button on video overlay panel to make video fill app without going fullscreen
+ Ability to download/generate images when downloading Youtube media

### Changed
+ Updated included Webview2 assemblies to latest stable release
	+ Provides new audio methods and events (mute/unmute) and decent performance improvements
+ Cached image decoding resolution increased to improve quality and reduce pixelation
+ Increased size of icons and spacing slightly for playlist items
+ LocalMedia, Youtube and Spotify log names now include version linked to primary log
+ Minor performance improvements to launcher startup speed.
+ Various improvements, and formatting refactors to verbose logging output
+ LocalMedia filter events moved into a dispatchertimer (and eventually into new module)
+ Improved parsing of local media artist and title names
+ Minor performance improvements for scanning local media
+ Playback of local media with libvlc is now retried if not yet started after 10s

### Fixed
+ Current playing Twitch stream not updated even if 'Auto Stream Updates' option enabled
+ Total/Current playback time missing/incorrect for some youtube media
+ Incorrect icons and titles for Youtube media added to playlists/queue from datagrid
+ Incorrect media image/cover art sometimes used if multiple exist in media's directory
+ Error thrown in Webview2 when navigating due to CoreWebView2 not yet initialized
+ Media removed from local media datagrid reappears after using the filter box
+ Media removed from youtube or spotify datagrids reappears after restarting
+ Invalid text encoding written log files when running on PS7
+ Many duplicate notifications created when downloading youtube media
+ Blank rows in datagrids sometimes appear after removing media


## 0.3.5 - Pre-Alpha

### New Core Feature - Youtube Web Player
+ New Youtube Option 'Use Web Player' allowing playback of youtube media via webview2
+ PRO: GREATLY improves performance of the time from pressing Play to when playback starts
  + Native playback via yt-dlp avgs 10s for playback to begin, Web Player avg 2s
+ PRO: Download (most) videos by right-clicking on the video and selecting 'Save Video As'
+ PRO: No Google tracking of what your watching (if that matters to you)
+ CON: Volume/EQ, Audio settings and some playback controls unavailable except STOP, MUTE
  + Mute still works using new isMuted feature of webview2 to mute all webview2 audio
  + Can use controls within the html web player vs the apps native controls
+ CON: Auto play/tracking of items in the Play Queue is unavailable (shuffle,next/prev..etc)
  + May have potential workaround solution for this in the future using audio events

### Added
+ New Option 'Enable Marquee Text Overlay' for display info over top of the Video Player
  + For Twitch media, stream viewer count is displayed, else its media title/artist..etc
+ Ability to display Profile icons/logos for Twitch Channels/Streams in Playlists/Queue
  + If none available defaults back to using general Twitch logo
+ Expand/Shrink player button next to fullscreen and chat buttons
+ Expand/Shrink button on video overlay panel to make video fill app without going fullscreen
+ Ability to download/generate images when downloading Youtube media

### Changed
+ Updated included Webview2 assemblies to latest stable release
  + Provides new audio methods and events (mute/unmute) and decent performance improvements
+ Cached image decoding resolution increased to improve quality and reduce pixelation
+ Increased size of icons and spacing slightly for playlist items
+ LocalMedia, Youtube and Spotify log names now include version linked to primary log
+ Minor performance improvements to launcher startup speed.
+ Various improvements, and formatting refactors to verbose logging output
+ LocalMedia filter events moved into a dispatchertimer (and eventually into new module)
+ Improved parsing of local media artist and title names
+ Minor performance improvements for scanning local media
+ Playback of local media with libvlc is now retried if not yet started after 10s

### Fixed
+ Current playing Twitch stream not updated even if 'Auto Stream Updates' option enabled
+ Total/Current playback time missing/incorrect for some youtube media
+ Incorrect icons and titles for Youtube media added to playlists/queue from datagrid
+ Incorrect media image/cover art sometimes used if multiple exist in media's directory
+ Error thrown in Webview2 when navigating due to CoreWebView2 not yet initialized
+ Media removed from local media datagrid reappears after using the filter box
+ Media removed from youtube or spotify datagrids reappears after restarting
+ Invalid text encoding written log files when running on PS7
+ Many duplicate notifications created when downloading youtube media
+ Blank rows in datagrids sometimes appear after removing media

### Builds Updated
+ Install\EZT-MediaPlayer-Setup.exe
+ Launcher\EZT-MediaPlayer.exe

## 0.3.5 - Pre-Alpha

### Added
+ Ability to dynamically change background image/colors to match currently playing video
  + Now works with Youtube/Twitch playback along with audio if valid image is found
  + Twitch images are pulled from the channel via the API, Youtube from video thumbnail
+ Display of logo/icon of Twitch channels in Toast Notifications
+ New parameters 'Callpath' and 'Encoding' for Write-EZlogs
  + Callpath allows including the source/callback where it was invoked in the log entry 

### Changed
+ Enabling Start on Windows Logon now uses HKCU Run reg entry vs Scheduled Tasks
  + Schedule tasks required admin rights, and app no longer runs under admin by default
  + More 'Visible' to normal Startup tools such as in Task Manager
+ Media and Playlist profiles are now stored with the apps main config folder in %appdata% 
  + Profiles no longer need to to be rebuilt went temp is cleared
+ Improved error handling and logging of EQ routed event handlers
+ Improved verbose error logging and detail for easier troubleshooting 
  + Log entries now always include callback line number, function or script even from runspaces
+ First iteration for refactor of Specificity settings and application
  + Spicetify commands moved from Apply settings scriptblock to new module Invoke-Spicetify
  + Added Install and Remove buttons under Spicetify option in settings tab (not yet enabled)
  + To allow installing/removing/refreshing customization vs always occurring on settings save
+ App icon now displayed in place of Powershell for Splash and First Setup windows
+ App will now attempt to restart Spotify if not playing/opening 10s
+ App will now attempt to restart Streamlink if not playing/opening 10s

### Fixed
+ Spotify media has missing/incorrect title and icon when added to queue from browser datagrid
+ Some Media in the queue may fail to be highlighted when currently playing
+ Applying saved custom EQ presets may not take effect or cause app to crash 
+ App randomly can crash after pressing the Stop button in the VideoView overlay flyout
+ App randomly can crash after closing the pop-out/fullscreen player

### Builds Updated
+ EZT-MediaPlayer-Setup.exe
+ EZT-MediaPlayer.exe

## 0.3.4 - Pre-Alpha

### Added
+ New module Add-VLCRegisteredEvents for libvlc event callbacks
+ New module Update-Playlist
+ New module Update-MediaTimer
+ Additional verbose error logging added to scriptblocks fpr better uncaught exception logging
+ New launcher source script, build SED and exe included in Installer/
+ Visualization plugins for libvlc (to be added/integrated in the future)

### Changed
+ Removed now ununsed Vlc.DotNet assemblies
+ Removed 'Rounded Corners' styling due to causing performance issues when resizing
  + Was very hacky anyway, perhaps will look more into SetWindowCompositionAttribute()
+ Various code and comment refactors for cleanup and region organization
+ Media Tick timer code block refactored into new module Update-MediaTimer
+ Toast notifications now always display as coming from this app (with proper icon!)
+ Any existing notifications (with same id) are now updated vs creating duplicates
+ Local Media browser datagrid now uses Async binding for reduced load stutter
+ Pressing 'Play' button now begins playback of next item in queue if nothing is playing
+ Chat view is now disabled/closed when playback of Spotify media begins if previously opened

### Fixed
+ Pagination may fail when navigating with next/prev buttons in local media browser grid
+ Error notifications may appear when downloading videos despite completing successfully
+ Crashes with System.AccessViolationException due to threading issues with libvlc event callbacks
  + Always occurred anytime events like EndReached,Ontimechange..etc even if nothing executes
  + Resolved by using Register-ObjectEvent so events dont fire within main thread
  + This fix drastically alters various core systems and many refactors are now needed
+ Corrupted/unreadable text written to log file due to improper encoding output
+ Get-TwitchApi/Get-TwitchStatus fails due to duplicate parameters on write-ezlogs (oops)
+ Adding media via dragdrop fails due to not using invoke on some UI updates in import-media 
+ Pausing playback may fail when using play/pause keyboard events
+ Playback may fail when using next keyboard events due to runspace/thread access issues
+ Total duration and progress timer missing/fails when playing some local media
+ Logging and error handling fails for Start-Runspace due to missing modules/functions
+ Media added to play queue missing title when starting playback from media datagrids
+ Media added to play queue missing title when selecting 'Play All' from a playlist
+ First run setup fails to install required apps when not run as administrator
  + App now detects and restarts as admin if needed when first installing requirements
+ Some local media fails to add to playlists if no title metadata was found for the files
  
### Builds
+ EZT-MediaPlayer-0.3.4.exe
+ Installer/EZT-MediaPlayer-Setup.exe

## 0.3.3 - Pre-Alpha

### Added
+ First iteration of new media control overlay that displays over playing media
  + Uses flyout animation that appears only when mouse enters player and leaves on mouse leave
  + Currently includes play/pause and stop button, other controls to be added
+ First iteration of new of setup and launcher process
  + Migrated to Inno Setup compiler for a more 'Normal/User Friendly' install experience
  + Setup file is now main launcher exe and no longer includes zip archive
  + New installer will re-install existing or upgrade if a new version
  + Now installs like a normal app with its own uninstaller and windows APPID
  + Latest CHANGELOG and README now displayed during the setup process

### Changed
+ Startup splash screen is now loaded/displayed sooner to decrease startup 'dead space'
+ Media playback controls now use routed event handlers for better re-usability
+ Multiple refactors to improve verbose logging detail, accuracy and performance
  + Separate log files are now created for various Spotify, youtube and twitch functions
  + Greatly improved error handling in write-ezlogs to help manage file access errors
  + Each log message now defaults to include the originating function name via PSCallStack
  + If callback is from scriptblock, will also display location line numbers

### Fixed
+ Various errors and occasional crashes due to race conditions and write access to log file

### Issues
+ New video player overlay disappears if using pop-out player after closing
  + Works fine in the fullscreen/pop-out player, but never works again after closing?

### Builds
+ EZT-MediaPlayer-0.3.3.exe
+ EZT-MediaPlayer-Setup.exe

## 0.3.2 - Pre-Alpha

### Added
+ Module Update-Playlist for changing playlist properties and removing media
+ yt-dlp.conf file for applying additional/separate config properties to yt-dlp

### Changed
+ Various UI Design and theme changes
  + Re-Styled scrollbars decreasing width and changing colors to better blend with theme
  + Reduced opacity and other changes to gridsplitters so they blend in better
  + If playing media has images/art, main UI background/theme is now set to match
+ Refactored Start-Keywatcher and moved into separate module
+ Refactored Remove_fromPlaylistCommand to use Update-Playlist module
+ Improved error logging and exception handling in playback dispatch timer
+ Improved error logging and exception handling in Get-Playlists
+ Improved error logging and exception handling in Import-Media
+ Improved error logging and exception handling in Start-Media
+ Spotify, Local Media and Youtube media hashtables merged with main Synchash hashtable
  + Reduces complexity, duplication and issues with scoping between runspaces
+ On playback start, updates to main thread now use a dispatcher timer to reduce UI stutter
+ All media images are now re-encoded to width of 500 to reduce size/memory usage
+ Reduced Spotify playback timer to 250ms to help stop Spotify from playing its own next track
+ Changed yt-dlp parameters to output single json and improve parsing speed of youtube videos
+ Updated included yt-dlp binary to latest version which improves performance slightly
+ Updated Write-EZLogs module with latest improvements to error handling and log detail

### Fixed
+ Volume mute icon becomes out of sync with actual mute status of vlc playback
+ Errors and crashes can occur due to unhandled exceptions when checking for running processes
+ Local media profiles missing 'ID' property, causing mismatched lookups for some functions
+ Re-ordering items with dragdrop may not update playlists despite UI confirmation
+ Get-TwitchStatus may fail with 'collection was modified' error or if no streams found
+ UI may not reflect changes when refreshing Twitch status due to duplicate named variables
+ Duplicate items can appear in lists due to mismatches of ID and encodedtitle properties
+ Playing Spotify media may fail to stop current playing media or skips to next item in queue
+ Unintended items add to queue when playing media if still selected in browser datagrids
+ Duplicates images are cached each time media is played instead of using existing one

### Builds
+ EZT-MediaPlayer-0.3.2.EXE
