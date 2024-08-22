# Changelog

## Unreleased

## 0.9.9 - BETA-003
> - Branch: Samson

### Changes
+ Updated Syncfusion.SfTreeView.WPF.dll with custom patch from Syncfusion
  + Resolves issues with TreeView node content not expanding properly
+ Compiled 1.27 updated MdXaml assemblies from latest repo
  + Adds support for displaying animated gifs and other fixes
+ Spotify desktop client now launches silently when using Spicetify
+ Improved performance for batch lookups of Youtube video ids

### Fixed
+ Fixed #382: Spicetify (Free Spotify) is not working
  + At least until some Spotify update breaks it again..
+ Fixed #383: EQ not working with Non Spotify Webplayer
+ Fixed issue introduced in last update that broke Window helper methods
+ Fixed issue where app would hang during Spicetify install

### Comments
+ The free Spotify/Spicetify solution is a nasty hacky mess, needs re-engineering
+ Will NOT trigger first time setup

## 0.9.9 - BETA-002
> - Branch: Samson

### Changes
+ Updated Syncfusion assemblies to 26.2462.4
+ Mini-player skin now expands horizontally from the display screen
  + The media title and animations in the display does not yet expand dynamically
+ More README.MD updates

### Fixed
+ Samson.exe from previous build was not the latest version
+ An error and potential crash can occur in state changed events for floating windows

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.9 - BETA-001
> - Branch: Samson

### Added
+ New option `Enable High DPI Mode` under Startup/UI settings that forces the app to be Per Monitor DPI aware
  + This can help fix issues with blurry UI elements especially when using multiple monitors
  + Currently considered EXPERIMENTAL, see the options help topic for information including known issues
+ New option `Start Paused` under `Remember Playback Progress` to allow pausing media loaded on startup
  + Start paused was the previous default behavior, but now will play automatically unless enabling this
+ New media object property `TimesPlayed` for tracking number of times media has been played
  + Currently nothing is done with this data, may be added to UI or some future feature
+ API setup instructions for Spotify, Youtube and Twitch
  + Can be accessed from help topic button next to each respective authentication link in settings

### Changes
+ More README.MD updates
+ Increased playback history tracking limit from 5 to 10 media items
  + Improves shuffle as it checks the history list. May make configurable in the future
+ Get-PlayQueue now includes small wait delay on startup to allow playlists to finish loading
  + Helps prevent some cases where media in the queue is missing on startup
+ Toast notifications are now used for available update messages when starting as mini-player
+ Tooltips for Twitch media in playlists or queue now show how long stream has been live for
+ Profile editor details tab now shows all media profile properties
+ Various features and options are now hidden/removed for some builds
  + Applies to update, feedback and VPN features which will be removed from public build
+ Improved text styling for items in the play queue, now matches playlists
+ Minor changes and updates for write-ezlogs

### Fixed
+ Fixed #375: Media does not load on startup with remember progress enabled
+ Fixed #376: Media transport controls overlay not working with PS5
+ Playlist view layout in media library doesn't update properly when refreshed
+ Path error in code for spicetify webnowplaying plugin

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup
+ First public beta release planned for next main version

## 0.9.8 - BETA-010
> - Branch: Samson

### Added
+ Included Airhack control source files to repo

### Changes
+ Updated README.MD
+ Application event log errors for past day are now included when submitting logs from feedback form
+ VPN related settings are now hidden for non-tor enabled builds
+ Minor updates and changes to logs and alert messaging
+ Minor improvements to render performance of Splash Screen UI

### Fixed
+ Fixed error that could occur on first run when initializing webview2 extensions
+ Fixed issue where speaker animations wouldn't play when audio monitor is enabled
+ Fixed #163: Start as MiniPlayer Issues
+ Fixed #263: Very high CPU usage
+ Fixed #351: Crash switching to full player
+ Fixed #354: Crash closing library
+ Fixed #363: Crash after sitting idle for 5 days
+ Fixed #372: Always starts in Mini mode
+ Fixed #374: Seeking of Spotify media not working using overlay progress bar
+ Update to #373: Found and fixed various issues likely (but not confirmed) related to this
+ Fixed issue preventing the ability to manually add Spotify podcast urls to library

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-009
> - Branch: Samson

### Changes
+ Updated README.MD
+ Video Viewer window position is now saved when 'Remember Window Positions' is enabled
+ Minor refactors for module `Get-Twitch` to allow easier updates of single twitch media objects
+ Live status of Twitch media is now updated if not already when attempting playback
+ Updated help documents and flyouts for various settings
+ Minor refactors and formatting changes to logging via `write-ezlogs`
+ Auto-update checks are now disabled by default on new installs
  + The update system will be removed in 1.0 public release, replaced later on
  + Private and QA builds will likely not be effected, at least not for long
+ Reorganized and cleaned up C# source files in repo

### Fixed
+ Fixed some toast notifications not working or causing errors in some situtations
+ Spotify authentication UI in settings stays greyed out or gets stuck if authentication fails

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-008
> - Branch: Samson

### Changes
+ Miniplayer and library window positions are now saved when 'Remember Window Positions' is enabled
+ Various alerts will now use toast notifications if miniplayer is open
+ Re-added display of profile images for top-level youtube comments
+ Improved reliability of installing webview2 extensions for webbrowser
+ Changes to further attempt to prevent UI crashes when using miniplayer
  + UI elements are set to collapsed vs hidden to stop all rendering in some situations
  + Changed how main window is hidden so that total visual tree can still be updated
+ Improved accuracy of global runtime timer

### Fixed
+ Play/Pause status not updating for miniplayer skin buttons
  + Also applies to taskbar item buttons
+ Window position is not saved for main window if miniplayer was last used
+ Main window should no longer show in taskbar while miniplayer is open

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-007
> - Branch: Samson

### Added
+ Enter/Exit Fullscreen option for view viewer floating window context menu

### Changes
+ Greatly improved render performance when scrolling large playlists or queues
+ Changes to help prevent race conditions for the play queue
  + Actions such as drag/drop are now disabled while queue is being updated
  + A UI warning is displayed if queue runspace is started while one is currently executing
+ Additional improvements to prevent UI crashes due to layout measurement override exceptions
  + I'm finally somewhat confident these crashes are all fixed, but will need testing
+ Additional improvements to address airspace issues with video viewer overlays
+ Optimized UI events for miniplayer to prevent event handler leaks
+ Local media urls will now automatically updated on playback if moved and then found within same root directory
  + Ex: If you move media to another folder, Samson will try to search for the file within known directories
  + This occurs even if local file monitoring is disabled
  + A warning or error will be displayed if Samon is unable to find the media
+ Updated Webview2 libraries to version 1.2535.41
+ Updated Streamlink to version 6.7.4.0
+ Disabled swipe navigation and other features of webview2 to prevent accidental user induced issues
+ Warnings in start-media are now displayed via toast notifications if using miniplayer

### Fixed
+ Exceptions in queue update runspace can cause the entire runspace to fail
+ Config file fails to save to disk due to possible race condition
+ Switching to main skin from miniplayer switches back to miniplayer instead
+ `Stay on Top` miniplayer state can sometimes be reset
+ Video player open animation always opens downward instead of from its current position

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-006
> - Branch: Samson

### Added
+ (MiniPlayer) Auto Play and Shuffle toggle buttons to Mini-Player skin
  + Reminder: Other features like the library can be access by right-clicking anywhere on miniplayer
+ (Playback) New 'Repeat' toggle button and functions to allow looping of playing media
+ (Webplayer) Support for Youtube live chat when watching live Youtube streams with Webplayer
  + Requires enabling Youtube Comments options under Youtube settings
  + Youtube live chat also supports BetterTTV as with Twitch chat
+ (Logging) Ability to specify custom datetime format for logging in `write-ezlogs`
  + No UI option, can be set in variable at top of `Samson.ps1`

### Changes
+ (Webplayer) Optimized Youtube `webview2` events to prevent conflicts and loops
+ (Webplayer) Youtube comments (if enabled) now auto refresh on video change
+ (Webplayer) Progress is now saved when playing native Youtube playlists
  + Playback will resume from the last video watched within a YT playlist
+ (Discord) Optimized Discord rich presence updates when using Youtube webplayer
  + Title and artist stay up to date when video content changes dynamically in webplayer
+ (Webview2) `Webview2` extensions are now removed from config when they no longer exist
  + Also improved accuracy of detection and installation for `webview2` extensions
+ (Webview2) All `Webview2` instances now share the same user storage location (in temp)
  + Ensures all webview2 sessions are logged in with same auth/cookies
  + Simplifies Twitch/Youtube chat login, just make sure to add creds in settings and chat will be logged in
+ (Playlists) Custom playlists are now always sorted by name - ability to custom sort is planned
+ (Playlists) Re-implemented ability to reorder items in playlists via drag/drop
  + WIP - there may be some scenerios it doesn't work right  
+ (UI) Various changes to UI to allow adding new repeat button and to improve display clarity
+ (MiniPlayer) Multiple refactors to improve reliability when using the MiniPlayer
+ (General) Improved error handling during startup
+ (General) Reliability improvements to ensure playlist overlay for video viewer window shows on mouse over
+ (General) Multiple changes and refactors to clean/prepare code to be open-source ready
  + Removed Syncfusion license string from code, dlls are pre-licensed
  + Refactors for `Test-Internet` to allow it to function without AbstractAPI
  + Removed unused test assemblies and modules for `TMDbLib` and `Get-OpenBreweryDb`
  + Removed unused packages and assemblies in `EZT_MediaPlayer.dll`
+ (General) Updated Syncfusion libraries to version `25.1.35` - some relavent improvements listed below
  + `SfDataGrid`: Performance improved while grouping and sorting large numbers of records
  + `SfTreeView`: Dragging items will now update properly even after applying a filter
  + `SfTreeView`: SelectedItems will now be properly ordered when performing drag and drop
+ (General) App is now prevented from using IPv6 via appcontext switch `System.Net.DisableIPv6`
  + Helps prevent timeout and other issues when performing network lookups or network scans
+ (General) Various minor refactors, code/comment cleanup and logging changes

### Fixed
+ Fixed #358: Search freezes after each letter typed
+ Fixed #364: Playlist overlay position/size doesnt update when miniplayer is open
+ Fixed #365: Crash occurs when opening video player when starting app as mini-player
+ Fixed #366: Unable to add new playlist if the name was previously used but renamed
+ Fixed #367: `Update-LocalMedia` fails when file monitor updates from a file change
+ Fixed #368: Video player overlay controls missing when opening in miniplayer mode
+ Fixed #369: Large memory leak that occurs after enabling then disabling the specturm analyzer
+ Fixed issue of blurred and overstretched Twitch media images in the system control overlay

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup
+ This version has alot of focus on giving the miniplayer some long overdue attention

## 0.9.8 - BETA-005
> - Branch: Samson

### Added
+ Ability to add multiple media to playlists by album name
  + New context menu option: Add album to...
  + Will add all media with the same album and artist of the item selected

### Changes
+ Refactors for queue logic to ensure item keys always remain in sequential index order
  + This should help solve various queue issues - requires further testing to verify #356
+ Optimized how Webview2 for Spotify is initialized to prevent event handler leaks
+ Applied recent search optimizations to Spotify, Youtube and Twitch libraries

### Fixed
+ Fixed #359: Queue play icon animation still plays when performance mode is enabled
+ Fixed #360: Overlay controls for video player window missing when mini-player is open
+ Fixed #361: Next track sometimes fails to play when using the Spotify webplayer
+ Fixed #362: Some context menu options fail depending on where you right click on an item
+ Fixed an issue where play queue may fail to update due to enumeration error

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Highly recommend clearing the queue before/after installing this update
+ Will NOT trigger first time setup

## 0.9.8 - BETA-004
> - Branch: Samson

### Changes
+ Changes to improve performance for media library global search #358
  + Removed BeginInit and EndInit calls from sfdatagrid.view when applying filter
  + Adjustments to syntax when performing regex
  + RefreshFilter method now called manually on view after applying filter
+ A new ObservableCollection is no longer created each time if no playlists exist
+ Slightly improved response time when using Media Transport Control buttons

### Fixed
+ Fixed #357: Adding to existing queue doesn't work
  + This also partially addresses #356 - Odd Queue behavior

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-003
> - Branch: Samson

### Added
+ First iteration of Twitch intergation with Web Browser
  + Twitch shortcut icon/button added to Web Browser control bar
  + Right-click on Twitch channels: Play with Samson or add to library/playlists
  + Right-click on Twitch channels: Twitch Actions sub-menu to enable/disable live alert or follow/unfollow
  + Selecting follow/unfollow doesnt do anything yet, need to implement API calls to change Twitch follows
  + Twitch Action commands will only be available if Twitch integration is enabled in Settings
+ Ability to play Twitch VODs with full skip forward/backward support
  + Twitch VODs can be played or added to library/playlists via the new Twitch Web Browser integration 
  + PLANNED: Ability to access or import Twitch VODs for followed/subscribed channels

### Changes
+ Various updates to get drag/drop for reorderings items to work again in treeviews
  + Drag from/to other playlists works, only dragging in existing playlist to reorder that is not
+ Increased timeout from 15 to 20 secs when waiting for media to load in Set-ApplicationAudioDevice
+ Removed Samson certificate install (for accessing API creds) from InnoSetup
  + May keep for private builds. Public builds will have instructions on how to add their own API creds
  
### Fixed
+ Various attempts to fix random/hard to reproduce crashes and freezes
  + Removed change notifications from some media object properties
  + What little I got from debugging, seems related to UI render timing vs change notification updates
  + These changes unlikely to help with potential crashes with Mini-player, been so far unable to reproduce
  + Need more testing before changing to much more
+ Fixed #353: Webview2 fails to store new cookie values for youtube to config
+ Fixed #352: Artist = Unknown

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-002
> - Branch: Samson

### Added
+ Instructions in README on how to setup and config API for Spotify, Youtube and Twitch

### Changes
+ Removed dropshadow effect from various textblocks to prevent potential memory leaks
+ Removed extra/unused dependencies from EZT_MediaPlayer assembly
+ Minor syntax refactors and formatting changes

### Fixed
+ Fixed an issue where audio output device for libvlc is not set correctly
+ Fixed a large memory leak that could occur when playing Youtube media with webplayer

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.8 - BETA-001
> - Branch: Samson

### Added
+ First iteration of ability to use Global Hotkeys to control app functions (via `P/Invoke`)
  + Registered hotkeys work even if window is not in focus or in background
  + Assign custom keys (including modifiers) via Settings - General - Media Player Options
  + Enable/disable all hotkeys quickly via keyboard button on title bar menu (Placeholder)
  + Implementation uses `Hotkeys.dll` via github repo Hotkeys (credit: mrousavy)
  + Hotkey registration will fail if already used/registered by another app
  + WARNING: Registering hotkeys will prevent any other app from using them while Samson is open
  + Hotkeys are always unregistered on app shutdown or can be disabled via toggle button
  + Hotkeys are saved to config, and re-registered on app start (if enabled)
  + Currently only functions that can be assigned hotkeys are `Vol Up/Down and Mute`
+ Ability to overlay playlist/queue when using webplayers: #324
  + WIP, currently a bit hacky due to having to deal with WPF airspace issues
  + Open/close button auto appears on mouse over in top right corner of webplayer window
  + Used only top right corner so as to leave the rest of the window available for native Youtube mouse events
+ Ability to start playback of Youtube/Twitch/Spotify media by passing valid url to `Samson.exe`
  + Also triggers when opening media files or shortcuts with Samson
+ Ability to open/play videos urls from Comedy Central via Open media dialog
  + First iteration/WIP. Some videos may have no sound or buffer alot
  + Abliity to download CC videos not yet implemented into UI
+ Added `Live Alert` as available column for Twitch media library UI
+ 2 test buttons to main title bar, used to force manual memory cleanup (for test/dev usage)
  + One forces only GC collection and the other forces GC collection and clears Scriptblock caches
  + Anyone can use, wont break anything. Will also log current memory usage to log file
+ Ability to live edit Title, Artist, Album and Track fields for Local, Youtube and Spotify libraries
  + Live editing also now immediately update any relavent items in playlists or queue
  + Other fields potentially to be added but most of the rest are required to be static or pulled from API's..etc
+ New shortcut buttons for Youtube and Spotify in Webbrowser toolbar
  + Basically just static bookmarks to quickly browse each respective site for browsing/searching
  + Currently only youtube page has direct Samson integration controls (rigth click, play with Samson..etc)
  + Spotify will be tricky or may not be possible as their page locks various native browser controls (such as right-click)
  + The end goal with the Web Browser is still to at least somewhat make it the Search and Discover system for finding new media
+ New setting option `Disable Tray Menu` that allows disabling the icon, mini-player popup and right-click menu from the system tray
  + Enabling this will automatically disable the `Minimize to Tray` and `Start Minimized` options

### Changes
+ Greatly improved performance and memory usage when scanning media tags
  + Avg time reduction: -1min (5k file scan over 1GB network drive)
  + Avg memory reducution: -200MB (5k file scan over 1GB network drive)
  + Achieved by reducing dynamic scriptblock compilation within parallel runspaces
+ The recent jumplist category is now updated when history is updated vs only on startup
  + The recent category is also now sorted properly, with last played at the top
+ Updated `Libvlcsharp` assemblies to 3.8.2.0
+ More refactors and optimizations to improve performance and memory overhead
  + Reduced amount of icons created from `MahApps.Metro.IconPacks`
  + Some runspaces now have only required functions passed vs entire module
  + Changed various UI bindings to `BindingMode` OneTime
  + Replaced `Emoji.WPF` textboxes in large lists/treeviews due to high memory/cpu usage
  + `Start-SplashScreen`, `Start-Streamlink`, `Import-Media`, `Import-Spotify` now use restricted runspaces
  + Slightly improved performance when processing/populating/updating playlist items
  + Images for mini-player skin now loaded with `BitmapImage` streaming
  + Most modules are now only imported into local scope and only when needed
  + Some commonly used scriptblocks are now reused to reduce scriptblock compilation
  + Replaced some Label UI elements that are updated frequently with textblock
  + Internal PS method `ClearScriptblockCache` used to reduce memory especially for long app runtimes
  + Refactored use of `PSCustomObject` to use the 'new' constructor
  + Optimized and improved loading performance for the `Spotishell` module
  + Replaced some uses of `Where-Object` with `Get-IndexOf` for faster filtering
  + Tick events are now removed for various startup `DispatcherTimer` when execution completes
  + Replaced various labels using content binding with textblock 
+ `Start-NewMedia` (opening media from open dialog) now checks for an existing media profile by URL
+ Updated included `UBlock Origin` extension to 1.55.0 - includes fixes for Youtube ADs
  + Extension (with default settings) will normally update on its own
+ Removed no longer used experimental module Invoke-OpenAI
+ Improved formatting and styles when displaying playlist treeview items
  + Implemented new custom wpf control `OutlinedTextBlock` to replace standard textblock
  + Allows outlining text with brushes for improved clarity
  + Duration values are now displayed in a consistent format
+ Media now always moved to top position in queue on playback even if already exists in queue
+ Internet connectivity check now performed before executing lookups in `Get-YoutubeStatus`
+ `Show-SettingsWindow` UI now executes within main UI thread vs separate runspace
  + Greatly reduces memory overhead while open, supports better GC cleanup and overall simplifies code
  + When opening for the first time all UI may seem to freeze very briefly. More optimizations to come
+ Updated streamlink to version 6.6.0 as well as the streamlink-ttvlol twitch.py plugin
  + Update improves initial loading times and reduces total memory consumption
+ Updated `PODE` module to version 2.9.0
+ Manaully compiled updated YT-DLP build adding in some yet non-released fixes
  + These fixes primarily allowed ability to support comedy central videos
+ Reduced compiled size of launcher `Samson.exe` by about 50%
+ Additional improvements of `taglib` scans of open/locked media files
  + Will now wait up to 15 secs before moving on (mostly for file copies)
  + Now monitors file during wait time vs waiting max time before retrying
  + Waiting is skipped if TOR is currently running/downloading files
+ Multiple refactors for Playlist `sfTreeView`, data source binding and events
  + Itemssource now binds to `ObservableCollection` for All_Playlists
  + Data class `Playlist` and `Media` now implement `INotifyPropertyChange`
  + Resolves 1-2MB memory leak in `sfTreeView` when refreshing itemssource
  + Treeview UI's are now updated instantly when sub-item properties change without rebinding
  + Still need to implement `INotifyCollectionChanged` for `SerializeableDictionary`
+ Refactored uninstall process and removed need for `Samson-Uninstall.exe`
  + Uninstall now handled by new module `Uninstall-Application`
  + Uninstall is triggered by passing -Uninstall arg to either `Samson.exe` or `Samson.ps1`
  + InnoSetup will now call `Samson.exe -Uninstall` from its own uninstaller
  + Uninstall-Application handles removal of components like streamlink, chocolately..etc
  + During uninstall prompts user if they also wish to remove all user related data (config/profiles..etc)
+ The main UI title bar is no longer hidden by default on fresh installs
+ Tray icon tooltip now displays the current playing media info during playback
  + Video player floating window title also now updates with current playing media
+ Improvements to playback support of native Youtube playlists when using web player
  + Applies when playing a Youtube video that contains a valid playlist id in the url
  + Native YT playlist controls now appear within web player for plyalist videos
  + Videos now advance automatically within the YT playlist without changing Samson's current playing media
  + Current playing title, artist and YT dislike/like info (if comments enabled) auto update on playlist video change
  + Sponsorblock info is refreshed on playlist video change (if enabled)
+ Consolidatd redundant code for parsing Youtube URLs into new function `Get-YoutubeURL`
+ Refactored and renamed assembly `AnimatedScrollViewer` to `EZT_MediaPlayer`
  + Also added full c# source code to this repo
+ Audio bitrate of media now displays with same formatting and UI location as video quality
  + Display of current playback quality of Youtube videos using the webplayer is also now supported
+ Removed total duration from display panel UI during playback, now only diplays current progress
  + Total duration still displays in video player overlay and in toolip of progress slider
  + Makes display panel UI cleaner and was somewhat redundant since there is a progress bar
+ Improved Spotify Webplayer playback performance when starting or skipping to next media 
  + Existing Spotify webview2 instances are now reused vs destroying and recreating for each media change
  + Start-SpotifyMedia now uses a restricted runspace for improved performance (only when using webplayer for now)
  + First track may still have small delay (to initialize webview) but changing to other Spotify tracks is much faster
+ Refactors and improvements to `SpectrumAnalyzer` view model to prevent event handler memory leaks
+ Minor changes to `EZT-MediaPlayer-Controls` assembly to improve SplashScreen render performance
+ Removed usage of `SetEnvironmentVariable` as it can potentially cause global registry issuse
+ Youtube playlists and Twitch followed channels are now automatically imported after successfully adding credentials
  + Spotify has already done this for a while, so now all are consistent in behaviour
+ DateTime formatting for all logging is now consistent as `MM/DD/YYY hh:mm:ss t`
+ MediaTransportControls overlay now updates faster on media change
  + Refactored and consolidated code into function Update-MediaTransportControls
+ Refactors and optimizations for Set-DiscordPresense, improved time it takes for presense to update
  + There can still be random delays for discord to update which seems to be limitation of DiscordRPC
  + Also fixed issues where Discord presense could sometimes continue to show previous played media
+ Various updates, fixes and other changes to help documents. Many still need to updated and redone

### Fixed
+ Fixed multiple issues in `Start-Media` after changing it to use a restricted runspace
+ Fixed issue where `Skip-Media` sometimes fails to find next item in playlists
  + Effected Youtube media when auto restarting when unable to play as embedded in webplayer
+ Fixed multiple exceptions and other issues found during VS debugging of powershell process
  + Included XAML binding errors and various C# exceptions not thrown/accessible from powershell
+ Fixed #327: Autoplay not advancing when playing from playlists
+ Fixed #326: Twitch library only showing display name column after first run
+ Fixed #328: System media overlay thumbnail/image sometimes doesn't update on track change
+ Fixed #329: Webview2 extensions stop working when moving or reinstalling Samson to new path
+ Fixed #330: App sometimes crashes with index out of range exception when refreshing playlists
+ Fixed #331: App rarely can crash during UI animations when docking video viewer window
+ Fixed #332: `Auto Sync Playlists` option for Youtube doesn't save when interval is set to `On Startup`
+ Fixed #333: Various UI playback animations dont resume after toggling pause on Youtube videos
+ Fixed #334: Capturing Youtube creds fails due to invalid using variable in `PODE` runspaces
+ Fixed #335: FFPROBE fails in `Get-SongInfo` when executed from a restricted runspace
+ Fixed #336: Memory leak can occur when closing a window if a control in window still has keyboard focus
+ Fixed #295: Uninstaller prompts multiple times to remove components
+ Fixed #337: Can't change Spotify Webplayer volume if Web Browser is open
+ Fixed #309: Taginfo fails when media is on a network unc path
+ Fixed #338: Media library remains blank when executing `Rescan Library`
+ Fixed #339: Audio output pauses briefly when opening settings window if media is playing
  + Occurred because setting was always applied to libvlc if it was available on open of settings
  + Will now only occur when clicking `Save` in settings as it applies it to libvlc
  + The pause when changing audio output of libvlc is unavoidable, but its at most 1s in length
  + May try skipping output change if libvlc output and setting value are the same, if that is even feasible
+ Fixed #341: Renaming playlists from context menu not working
+ Fixed #342: Spotify WebPlayer playback fails when starting media from library
+ Fixed #343: Spotify WebPlayer volume when starting playback takes a few secs to update to correct value
  + There may still be a very small delay if WebPlayer EQ is enabled, usually manifests as 200 - 500ms stutter
+ Fixed #344: Items in the queue sometimes missing after app restart or reappear after removing
+ Fixed #345: Playback fails, stops or becomes out of sync when quickly changing media
+ Fixed #346: UI fails to update after fetching subtitles for current playing media
+ Fixed #347: Enabling media casting support in settings doesnt save and causes auto update setting to enable
+ Fixed #348: File Monitor may sometimes immediately stop on startup
+ Fixed #249: Changes made with profile editor dont save or reset on restart
+ Fixed #350: Get My Uploads option for Youtube doesnt import account uploads

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will trigger first time setup, and all media library profiles will be rebuilt

## 0.9.7 - BETA-005
> - Branch: Samson

### Added
+ Ability to set/configure the global gain for libvlc audio output
  + New option 'VLC Global Gain' in settings - general - Advanced media player options
  + Controls the linear gain that will be applied to all output audio
  + Separate from EQ pre-amp, changes take effect on start of playback
  + Valid values 0-8. When not set, defaults to 4. Max values could cause distortion/clipping

### Changes
+ Minor changes to improve memory overhead
+ Local file monitor mode 'Changed Media' now works for more than just file renames
  + Monitor checks for changes in file sizes before re-scanning
  + Some changes to file metadata might not trigger re-scan if file size doesn't change
+ Improved Taglib scanning of files that are currently locked or open in another process
  + A minor delay is added before retrying and moving on
+ UI's for playlist treeviews are now only refreshed when there are source data changes
+ Tooltips now display media description (stream title for twitch) in playlists/queue
+ Profile images no longer display for Youtube comments due to heavy performance cost
  + May bring back if can optimize better or just use a generic placeholder
+ Increased vlc network-caching to 1500 for files located on network drives/shares
  + Value can still be overridden/customized using custom vlc arguments under settings

### Fixed
+ Fixed #323 - Hang adding items to queue
  + Also fixes issues where items are added above vs below existing items
+ YT library may fail to update when adding media to YT playlists via context menus
+ Power button in Audio Options UI doesn't do anything (should close the UI)
+ Skip-Media may sometimes fail when getting the index of next available media
+ Volume icon sometimes flips between mute/non mute state when muting media

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.7 - BETA-004
> - Branch: Samson

### Changes
+ Updated libvlc to version 3.0.20 - relative fixes/changes below (not full list)
 + Fix next-frame freezing in most scenarios
 + Fix FLAC playback quality regression with variable frame size
 + Support RIFF INFO tags for Wav files
 + Fix AVI files with flipped RAW video planes
 + Fix duration on short and small Ogg/Opus files
 + Fix some HLS/TS streams with ID3 prefix
 + Fix some HLS playlist refresh drift
 + Improve FFmpeg-muxed MP4 chapters handling
 + Improve playback for QNap-produced AVI files
 + Improve playback of some old RealVideo files
 + Fix duration probing on some MP4 with missing information
 + Multiple fixes on AAC handling
 + Activate hardware decoding of AV1 on Windows (DxVA)
 + Improve AV1 HDR support with software decoding
 + Fix some AV1 GBRP streams, AV1 super-resolution streams and monochrome ones
 + Fix rawvid video in NV12
 + Fix several issues on Windows hardware decoding (including "too large resolution in DxVA")
 + Super Resolution scaling with nVidia and Intel GPUs
 + Fix for an issue when cropping on Direct3D9
 + Multiple fixes for hardware decoding on D3D11 and OpenGL interop
 + Improvements on the threading of the MMDevice audio output on Window
 + Fix an issue when playing -90°rotated video
 + Fix GOOM visualization
 + Fixes for Youtube playback
 + Fix memory leaks when using the media_list_player libVLC APIs

### Fixed
+ Fixed #321 - Playback stops a specific spots in some FLAC files

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.7 - BETA-003
> - Branch: Samson

### Changed
+ Minor memory overhead improvements for Webbrowser context menu events

### Fixed
+ Fixed #320 - No media is displayed in local library
+ Fixed: Adding media from webbrowser context menu to playlist instead adds to queue

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.7 - BETA-002
> - Branch: Samson

### Added
+ Ability to provide custom Twitch playlist proxy urls used by streamlink to bypass ads
  + New option under Settings - Twitch - Twitch Options - Use Custom Proxies
  + The proxies are attempted in order they are added, falling back down the list if one fails
+ Ability to deserialize a valid string value with Import-SerializedXML vs from file
+ New application certificate that gets installed to user cert store during InnoSetup
  + This is part of VERY early groundwork/testing for potentially including secure API creds
  + The cert would be required to read encrypted files containing API creds
  + PSSerializer updated with ability to decode values from encrypted files

### Changed
+ Updated streamlink and twitch plugin to latest version 6.5
+ Removed PowerShellGet as a required component in InnoSetup
+ Removed no longer used assembly VirtualizingWrapPanel
+ Various startup assemblies are now installed to GAC during InnoSetup to improve startup performance
+ UI syncronized hashtable is now passed a weakreference for Get-Playlist,Get-PlayQueue and Start-Media
  + Improves memory overhead and prevents potential memory leak issues
+ Various minor updates and changes to logging formats and messages
  
### Fixed
+ Fixed issue where only first source directory is processed - #319
  + This also "should" fix issue where a full rescan of library is done when modifying source directories
+ Fixed various issues where playlists are not updated from certain actions (delete,clear, add multiple to..etc)
+ Fixed issue where current playing media is not highlighted in queue/playlists in some cases
+ Fixed issue where redundant errors always get written to error log when exiting streamlink process loop via break
+ Fixed issue where completed runspaces are not fully being disposed by RunspaceJobHandler
+ Set-ApplicationAudioDevice fails when calling Select-Object on ManagementObjectSearcher object with no results

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will NOT trigger first time setup

## 0.9.7 - BETA-001
> - Branch: Samson

### Added
+ #307: First iteration of playback support for Twitch VOD's
  + Currently can only play by manually adding twitch video url via add/open dialog
  + Progress seeking currently doesn't work as its technically still treated as a live stream
  + Planned: Ability to import/add all videos for followed channels to Twitch library
+ TEST - Video quality icon in Display Screen for video playback
  + Currently only displays for Twitch streams. Shows video resolution as reported by streamlink
  + This is only a test and PoC - may or may not stay. Style and location likely to change
+ New module PSSerializedXML, a more performant and memory efficient alternative to Import/Export CLIXML
  + Converts objects to a custom object type called 'Media', serializes and saves to XML files
  + Meant to be a more effecient replacement for CLIXML until any future move to DB
  + Currently applies to library profiles, playlists and other xml files
  + Example profile with Clixml of about 5,014KB, is now only 4,019KB with SerializedXML
  + Example profile with SerializedXML used about 17MB less memory vs Clixml
  + Example profile with Import-SerializedXML on avg was about 200ms faster than Import-clixml
  + Example profile with Export-SerializedXML on avg about 100ms faster than Import-clixml
  + Benefits vs clixml increase the larger the size of the profile
  + Greatly reduces overall memory footprint especially for larger profiles/playlists
+ Ability to use previous buttons and commands for SystemMediaTransportControls (Windows Media Overlay)
+ New module Get-EventHandlers uses reflection to find/remove all routed events registered to a UIElement
   + Very useful to help prevent memory leaks caused by routed events not being removed properly
+ Ability to add all media items of a specific artist to playlists or queue via contextmenu
   + Right-click on any media - can now select 'Add selected to..' or 'Add Artists to...'
   + Also added options for 'Remove selected from..' and 'Remove Artists From...'
   + Will pull all media of the selected items artist from any library (local/Youtube/Spotify..etc)
   + Additional options planned, such as adding by album or other available metadata
   + Thanks to 'Piscean' for the idea for this feature!

### Changed
+ Webview2 extension support now enabled on all builds without needing MS Edge Dev
  + Updated Webview2 SDK to stable pre-release version 1.0.2194
  + If extensions not showing up or there are errors, may need to update webview2 runtime
  + Any valid extensions that exist in \Resources\Webview2\Extensions are installed
  + Add-Webview2Extension function added for adding extensions to webbrowser menu
  + If an extension doesnt have a home/config page of some kind, may not show in menu
  + Only 2 extensions are approved for use, Ublock Origin (included) and EnhancerforYoutube
  + Other extensions SHOULD work, but can't be guaranteed. All are welcome to test
+ Removed unused test assemblies and modules for sql
+ Assemblies are now grouped into separate folders with their dependencies
+ Only the required assemblies are loaded on startup, with others loaded when needed
+ Reduced compiled size of Samson.exe and improved launch performance
+ Recompiled Emoji.Wpf as release build instead of debug
+ Get-Opensubtitles now tracks and alerts about remaining subtitle API downloads
  + Dev API allows unlimited search but max 20 downloads per day
  + Planned: Ability for users to provide their own credentials for downloads
+ Youtube comments are now sorted by number of likes
  + Takes longer to load, but can't sort them otherwise as they come in unsorted
+ Samson no longer restarts itself as admin when installing required components
  + This fixes a few annoyances, but some UAC prompts may occur during setup
+ Corrupted or any local files with a length of 0 are now skipped from import/scanning
  + To emphasize this only applies if is no data in the file, not metadata
+ Webbrowser webview2 is now suspended when no longer in view, reducing memory usage
+ Can now download YT videos from playlists links via context-menu on webbrowser
+ Replaced VideoButton_ToggleButton checked and unchecked events with single click event
  + Video open/close animation a little smoother as a result, in addition to reducing code
+ Numerous large and small refactors in many areas to improve memory management and performance
  + Added type checks for objects that implement idisposable
  + Reduced variables passed to runspaces by limiting to local scopes or PSBoundParameters
  + Replaced various foreach or other enumerations with pipelining to a process scriptblock
  + Replaced 'New-Object' calls with PSCustomObject for improved speed when creating new objects
  + Replaced Add-Member with psobject.properties.add method when adding properties to objects
  + Libvlc instances are now disposed after initializing on startup and created again when needed
  + Removed extra/unused XAML styles and templates
  + More image files are now loaded using streaming to BitmapImage with 'OnLoad' CacheOption
  + Webview2 custom contextmenu items and events are now reused to reduce memory overhead
  + Await task callbacks in Register-WinRTEvent are now properly disposed
  + Start-TwitchMonitor now uses a dispatchertimer instead of a looping runspace
  + Found and resolved a memory leak issue with output from Get-SecretVault
  + Removed many unnecessary GetNewClosure() calls on various scriptblocks
  + Alot more mostly minor, with larger improvements coming from changes to xml/profiles
+ Second iteration of live editing support for display name in media libraries
  + Re-enabled double-click to play, resolving event conflicts
  + Edit button now only appears when hovering over a row
  + The button will show for Spotify/Youtube/Twitch libraries but doesn't yet do anything
+ Formatting and general code refactor pass for Initialize-Webview2 and other modules
  + Removed extra spacing, standardized titlecase, replaced aliases, and many others
  + Ongoing for all modules/code, definately not yet final
+ General refactors to routed events to help prevent strong references left during GC
  + Allows easily removing routed events after various controls or windows are unloaded
  + This still needs to be applied to ALOT more events
+ Improved performance when adding WPF contextmenu's to Avalondock floating windows/tabs
+ Improved detection of streamlink disconnect and/or process ending
  + In addition, now only 1 runspace remains running for streamlink instead of 2
+ Improved handling when timeouts or other disruptions occur during twitch streams
+ Another optimization, refactor and cleanup pass for Write-EZlogs
+ Simplified and cleaned up Get-thisScriptinfo. Potentially reduced memory overhead slightly
+ Updated streamlink and twitch TTVLOL plugin to latest versions
+ Replaced use of textbox with textblock in various places to potentially reduce memory overhead
+ Updated Avalondock libraries to 4.72.1.0
+ Some functions now use PSCmdlet.WriteObject() to return data vs write-output or return
  + Improves performance and reduces memory by preventing arrays from being unwrapped on return
+ Get-VisualParentUp used to more effeciently and reliably crawl up the visual tree to find UIElements
+ Large changes to playlist profiles and how treeviews are populated
  + No longer separate xml files for each custom playlist. Now just 1 main profile xml for all
  + Playlists are converted into new custom object type and bound to treeviews itemssource
  + Greatly improves performance of adding playlists and items to treeviews, reduces memory overhead
+ InnoSetup installer now compiles most of the included dll assemblies with ngen
  + The final step of install will show a message about optimizing performance for the system
+ Replaced Invoke-WebRequest with Invoke-RestMethod calls in BurntToast
+ Refactored various scriptblocks to execute in a restricted runspace to improve performance/memory
  + Also improved error handling and general optimizations for restricted runspaces
  + Replaced alot of PSCmdlet function calls with .NET to reduce amount of CmdletEntry's
  + Any function/module needs has to be passed to restricted runspaces, none are inherited
+ Replaced various Start-Sleep calls in runspace loops with AsyncWaitHandle.WaitOne()
+ BetterFolderBrowser no longer used by Open-FolderDialog
+ Changed threading priority of Update-MainWindow to DataBind to allow UI updates to occur quicker

### Fixed
+ Fixed #314: History list enumeration error due to incorrect key value type casting
+ Fixed #315: Click event for context menu items activates on right-click
+ Fixed #316: Library play icon doesnt work until scanning is finished
+ Fixed #318: Unhandled exception when expanding artist
+ Enumeration error can occur when updating playlist items during local media scans
+ Fixed issue in BurntToast module when loading WindowsRuntime on Powershell 5
+ Fixed #299: Styles missing for contextmenu submenus for items in video view queue control

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will trigger first time setup, and all media library profiles will be rebuilt
+ NOTE: This version has very large changes to media, config and playlist profiles. 
+ The app will automatically convert exisiting config and playlist files. Media profiles will be rebuilt
+ Main focus of this build was improving performance with a specific focus on memory overhead
+ Previous builds avg idle memory usage after startup with 5-6k library, 1k playlists: 400 - 500MB
+ New build (same config/library/playlists) avg idle memory usage: 200 - 300MB
+ There are alot more changes not noted - lost track as its been a while

## 0.9.6 - BETA-001
> - Branch: Samson

### Added
+ #303: Ability to display comments and likes/dislikes when playing YT videos
  + New option - Settings - YouTube - YouTube Options - Enable YouTube Comments
  + Uses same view as chat view to show comments and their replies
  + Comments update asynchronously, but large amount may take a while
  + Proof of concept stage: Style, formatting and content sizing not final
  + Does not auto-update, can manually update by using refresh button
  + Likes/Dislikes retrieved from ReturnYoutubeDislikes API
+ #291: Ability to access webview2 installed extensions via UI
  + New extensions button in web browser bar that lists each installed extension
  + Selecting extension opens its related UI/settings in a new window/pop-up
  + Extensions are only supported if dev build of MS Edge is installed
  + 'Enhancer for YouTube extension for YT webplayer now included
  + This is for experimentation only using preview build of webview2
+ Ability to add temporary media to queue without adding to a playlist/library
  + New option 'Add to Play Queue' when right-clicking on YT videos in web browser
  + Allows queuing multiple videos without adding them to a playlist or YT library
  + This temporary queue is wiped when app is closed or regular queue is cleared
  + Further uses planned
+ #292: Ability to add YouTube videos to Samson playlists directly from Web Browser
  + Right-click on any valid YouTube link - add to playlist   
+ Chat/Comments and Web Browser buttons in top navigation bar and tray context menus
  + Web Browser will undock into floating window or dock if already open
+ #287: First iteration of 'Display Name' Live Editing support for Media libraries
  + New column 'Display Name' available for local media library only for now
  + Double-clicking allows editing field, hit enter to save
  + Display name will be used in playlists/queue if one is set
  + #305: Specify default name syntax for all media when scanning under local media settings
+ C# source code for SplashScreen/EZT-MediaPlayer-Control resource assembly
+ Convertto-RelativeTime function for converting Date-time into relative strings
+ Ability to cancel in-progress downloads of YouTube videos from download notification
+ Title menu option: 'Show Max/Restore Button' to toggle maximize button for main window 
  + Also disables windows snap, which doesn't work properly with fixed window sizes
+ Title menu option: 'Show Title Bar' to toggle view of the black main window title bar
  + When hiding you loose access to web/comments/snapshots and notification buttons
  + The above buttons/controls will be moved in future iterations
  + Goal is provide option for cleaner more immersive look for skin
+ Get-TwitchVideos function for getting available videos for a provided channel
  + Works but not yet implemented - Will be used to get vods/clips/highlights etc
+ New parameters test-mode and test-mode-path for executing Samson in a test/dev environment
  + Test-Mode-Path defaults to %temp% but any custom path can be supplied
  + Redirects paths for logs, profiles, config and temp folder to Test_Mode_Path
  + Confirm-requirements is skipped - streamlink, spotify, chocolately..etc are not installed
  + If testing those related features, ensure to install those components manually
  + Webview2 still checked/installed - always needed and is installed on newer windows versions anyway
  + Test-mode always enables debug-mode - see updated Samson.ps1 comment-based help for more details
  + This is not to be considered a proper portable mode for normal usage, only for dev testing
+ #313: First round of pester test scripts that will be used for automated testing of functions and modules
+ #300: Ability to add and remove videos from YouTube playlists via API
+ WIP: Special Events! ;)

### Changed
+ Notifications when taking snapshots now include a link to open the files created
+ Changed snapshot button icon to camera icon
+ Now possible to use the Sponsorblock 'Mute' action type for YouTube videos
+ Can now open/play Twitch streams added manually via Open media button
+ Updated help documentation for Web EQ Support
  + Added troubleshooting info on how to improve audio delay/quality in windows
  + Includes link to open VB-Cable control panel directly from help document
+ Web browser window title now updates to match current website document title
+ WRITE-EZLOGS: Improved callpath/stack tracing accuracy and various message cleanup
  + Start-Runspace now passes callpath from calling thread and name of runspace
  + In runspaces, line number in callpath indicates line of the script block
  + Updated formatting to be more consistent, removing extra line breaks..etc
  + Rerouted some logs messages to the appropriate log file type
  + Removed old/nasty hacks to deal with log files not available or set yet
+ VPN/TOR: Updated to support changed paths in newest version of ProtonVPN
+ WEBPLAYER: Webplayer volume is now synced to libvlc volume when using Web EQ
  + Changing volume in webplayer interface changes main app volume and vice-versa
+ SETTINGS: First pass in large refactor to Show-FirstRun module and functions
  + Module and related functions renamed to Show-Settings, Update-Settings..etc
  + Settings are now reloaded/reset when saving/canceling then reopening
  + Previously page was only hidden when saving/canceling, mostly for performance
  + UI is now per-rendered in background on startup to open quicker when used
  + Settings are loaded async to UI, so may see settings update on open
  + More refactors are planned to help improve performance
  + Ability to reset various settings/groups to default is also planned
  + Segmented various setting page/tabs into separate code blocks
+ Improvements to error handling and memory management for YouTube API functions
+ Refactored various UI code-behind into Set-WPFSkin and Set-WPFTheme 
+ LIBRARY: First iteration of new media library filter and actions toolbar controls
  + Buttons such as refresh and others now consolidated to Actions dropdown button
  + Various UI tweaks to accommodate more window sizes when library is undocked
+ Now possible to manually resize width of chat/comments view up to 50% of total window
  + Could be some bugs with resizing due to open/close animation, to be optimized
  + Some comments can get cut off if width too narrow
+ Updated Webview2 SDK to 1.0.21614.0
+ General code refactors: Mostly focused on standardizing routed events
+ Cleaned up various modules, removing unused functions and updating improper verb names
  + Improved performance on avg 100ms when calling functions for the first time
+ Enhanced Webview2 extensions support for automated detection and configuration
  + Configures required reg keys when proper dev build of MS edge is detected/installed
  + Removes reg keys and clears webview2 cache when no longer detecting dev build
+ Improved error handling for webview2 routed events to prevent crashing main thread
+ MONITOR: UI tweaks to improve clarity and spacing of spectrum analyzer frequency bins
+ Updated comment-based help for multiple functions and modules, alot more to do
+ Updated yt-dlp to version: 2023.10.13.0
+ Can now pause/resume playback from contextmenu of current playing media
+ Replaced get-ciminstance calls with ManagementObjectSearcher for improved WMI lookup performance
+ Reduced memory overhead by properly disposing instances of MMDeviceEnumerator
+ Reapplied custom attached behavior to playlists and queue for smooth scrolling with inertia effect
  + Fixed various bugs but need more feedback and testing to weed out scrolling problems
+ Registering window handles to app install id is now skipped if no install id is available
+ Moved Initialize-XAML function into its own module
+ Samson.exe launcher can now be used even if Samson was not installed via Samson-Setup.exe
  + Only works if Samson.exe is located within same folder as Samson.ps1 and required files
  + Doesn't equal a proper portable install, other issues may occur. Full portable support planned
+ Updated youtube.lua script for libvlc to latest available version

### Fixed
+ Fixed #281: Setting Discord title fails if title is more than 124 chars
+ Fixed #282: Media special actions missing from context menu of items in queue
+ Fixed #284: Add/Open media fails to process some YouTube URLs
+ Fixed #285: Browser not supported message sometimes displays when playing YoutubeTV 
+ Fixed #286: Contexmenu not working correctly on Web Browser tab 
+ Fixed #298: Some media is not detected properly as having video
+ Fixed #294: Some properties do nothing when set for emoji textbox controls
+ Fixed #293: Main window takes priority when activating sub windows
+ Samson may fail to launch when install folder is moved to another drive/directory
+ Fixed typos in Export-PlaylistCommand routed event that could cause event not to fire
+ Fixed #302: Getting Twitch followed channels fails with 410 Gone error
+ Fixed #301: Playback fails to start when using youtube playlist urls
+ Fixed #306: Play button in media libraries requires clicking twice to register
+ Fixed #304: Settings window doesn't update when selecting new color UI theme
+ Fixed various WPF xaml binding errors
+ Fixed #310: Twitch library stuck with spinning progress circle on new installs
+ Emoji.Wpf.texblock custom control not inheriting various properties
+ Fixed #311: Local library progress ring sometimes stays active when tasks complete
+ Fixed #312: Download notifications for YouTube videos fail to update progress %
+ Fixed Power button label and headphone skin elements being misaligned

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup

## 0.9.5 - BETA-001
> - Branch: Samson

### Added
+ Ability to monitor file changes for Local Media monitor
  + New option added to "Monitor Mode" : Changed Media
  + Currently only changes to tag/metadata properties will trigger 
  + File renames currently do not trigger yet
+ Column visibility selection dropdown for all media libraries: #276
  + Columns are saved and persist between app restarts
  + Defaults are loaded on startup if no columns are selected
  + Play column cannot be hidden
+ YOUTUBE API: Ability to remove videos from Youtube playlists: #277 
  + Right-click on media, select Youtube Actions - Remove From Playlist - choose playlist

### Changed
+ Playlists/Queue tab in media library can now be collapsed/expanded
  + When collapsed, a small vertical strip of space is still reserved.
  + Width dynamically adjusts to size of content up to max 50% of space with library
  + First iteration, likely will get more tweaks and possibly more flyouts
+ MONITOR: Slightly improved performance for Spectrum analzyer startup
+ Local media tags with multiple artists are now string joined with '/'
+ Adjustments to video button open/close animations and position calculations
  + Improved smoothness slightly by slowing animations by 0.2s
  + Close returns window to original position UNLESS window was moved while open
  + Refactored animation storyboards to be native XAML styles
+ TOR features no longer included, are now separated out into a different build
  + To reduce installer bloat, and TOR features are for private/on-request usage only
  + If you would like to use the TOR build, please request installer via Trello dev board
+ Internet connectivity checks now use more general IP connection test to 1.1.1.1
+ Cleaned and removed various properties no longer used from default config template
+ TWITCH: The open/close state of Chat View is now saved to config 
+ Reverted format of VLC log file back to text (.log) instead of HTML
+ Removed checkbox to enable experimental row filter for local media library
+ Main window title bar now changes color tone on focus loss
+ Performance mode is now force enabled on machines with no GPU acceleration available
+ Disabled drag UI popup for media library grids - still works for playlists
+ First run setup no longer prompts to keep or remove custom playlists if found
  + Can still appear if a specific build requires large changes to playlist profiles
+ First run setup now displays a general confirmation prompt before starting setup
+ The friends feature (incomplete) is now only available with Dev_Mode enabled
+ Warning prompts are now shown when attempting to use various WIP features
  
### Fixed
+ Fixed #271: VLC Timeout - Samson appears to launch as admin
+ Fixed other various issues with new launcher when using PS5
+ WEB EQ SUPPORT: VB-Cable is sometimes not properly detected as installed
+ TOR/VPN TOOLS: ProtonVPN is sometimes not properly detected as installed
+ Fixed #272: Some local media artist properties still showing as folder name
+ Fixed #273: EQ band presets cause error when EQ is not enabled or initialized
+ Fixed #270: Search Looses Focus
  + Potentially could still happen, submit new bug report if so
+ Fixed #274: EQ keeps reseting - EQ range change request
  + EQ range change: not currently possible or practical with libvlc 3
+ Fixed #275: Media removed manually from libraries returns after restart
+ Index of out range error occurs during enumeration of history list
+ Fixed #278: Remembered media loaded on startup skips to next item after unpausing  
+ Fixed #279: Media fails to load when using jumplist or passed to exe/cli
+ Fixed #280: Jumplist fails to load when start minimized is enabled

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will trigger first time setup, and all media library profiles will be rebuilt
+ REMINDER: The profile editor (media properties) is incomplete and shouldn't be used

## 0.9.4 - BETA-004
> - Branch: Samson

### Changed
+ Improvements to performance and accuracy of the spectrum analyzer (monitor)
  + Usercontrol xaml now uses virtualizingstackpanel
  + Device objects are now properly disposeda when disabling
  + Improved frequency scaling - should spread more evenly across bins
  + Reminder: Monitor activity strength scales with volume/DB
  + Reminder: Monitor currently captures loopback audio, so any windows audio
  + PLANNED: Monitor refactor to capture activity only for Samson audio
+ Rebuilt Samson.exe launcher as a native C# windows application
  + Should help prevent AV flagging as false positive, at least much lower chance
  + Very first iteration for testing. Exe accepts cli commands but not all have been tested
  + Expect bugs/issues! Primary focus is that it doesnt flag AV, secondary is that it actually launches 
  + Compiled as single exe (.net core 3.0) with dependencies, so exe size is much bigger (30MB) 
  + Will be optmized/expanded on further if testing goes well
+ Disabled some excessive logging for Get-LocalMedia while doing scanning
+ Cleaned up non-normalized line endings in various files - more cleanup needed eventually
+ The root/parent path is now checked when manually adding local media paths to prevent duplication
  + Only very basic check, not finished and only applies when using open/add media button
  
### Fixed
+ Fixed #269: Youtube Auto-sync not syncing new playlists
+ Enumeration error can occur during local media scan or in Import-Media
+ Equalizer errors occur in Initialize-vlc when equalizer not enabled
+ Errors occur in Update_Playing_Playlist_Timer when updating playlist properties

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup
+ This build is primarily just for testing the new Samson.exe launcher

## 0.9.4 - BETA-003
> - Branch: Samson

### Added
+ New "Performance Mode" option in Settings - General - Startup/UI Settings
 + Helps reduce CPU/GPU usage by limiting or disabling UI effects and animations
 + Only applies to UI performance, does not effect playback rendering
 + Sliding text animation reduced to 5fps, mimics older style digital displays

### Changed
+ Changes and improvements to parsing Artist field for local media
  + Artist name now set to "Unknown" if no artist data found in media tags
  + Improved consistency when parsing tags that use multiple tag fields for artist
  + Fixed issue where different titlecases are grouped as separate artists
+ Various refactors and improvements to Samson launcher (Samson.exe)
  + Launch errors are now presented to user
  + Improved ability to relaunch as user when under admin context
+ EXPERIMENTAL: Webview2 extensions can now be automitically installed
  + Any extensions in "%appdir%\Resources\Webview2\Extensions" will be installed
  + Must be valid MS Edge/Chromium extensions with manifest.json
  + Feature requires Microsoft Edge Dev build installed
  + To disable, remove from extensions folder and delete %temp%\Samson\Webview2 folder
  + UI config options are planned, likely when webview2 feature is out of preview
+ Minor cleanup and performance improvements to Spotify modules
+ Twitch Luminous ad blocking now favors US based proxy's, should improve performance
  + Also added additional fallback proxys servers
+ "Modify" button from "Apps & Features" now relaunches First Run Setup
  + This is mostly for testing, behaviour will likely change
+ Display name is now "Samson Media Player" for windows shortcuts/lists
+ SoftwareRender mode is now automatically enabled if no GPU acceleration is detected
  + SoftwareRender mode forces UI rendering to be done via CPU vs GPU

### Fixed
+ Fixed #266: App crashes on next startup after changing color theme
+ Fixed #267: Library global search textbox loses focus as you type
+ Fixed #268: Current playing item fails to highlight in playlists
+ Webview2 instances may fail to initialize with 'Not in ready state' error

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will trigger first time setup, and all media library profiles will be rebuilt

## 0.9.4 - BETA-002
> - Branch: Samson

### Added
+ Ability to add local media files or directories via drag/drop
  + Currently only works when dragging into local media library table
  + The drag tooltip may say 'cannot drop here' but it should still trigger
  + This is just the first test interation, a full refactor is still needed

### Changed
+ Reduced CPU load while scanning local media tags
  + FFProbe fallback no longer used, may speed up scans for media without tags
  + Reduced max number of threads used for CPU's with 4 or less cores
+ Only new directories added to the local media library should now trigger scanning

### Fixed
+ Fixed #264: Add Media button does not work correctly for local media
  + A more complete refactor still needed, but basic functions should now work
+ Spotify playback sometimes gets caught in restart loop when using Spicetify
+ Fixed #265: Spotify playback broken when using spicetify/local client
+ Media library progress indicators sometimes stay active even with no activity
+ Autoplay picks incorrect next song if prev track exist in multiple playlists
+ Fixed #192: Adding new local media sources in settings always triggers full rescan

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, however local library refresh recommended

## 0.9.4 - BETA-001
> - Branch: Samson

### Added
+ Auto-sync feature for Spotify playlists and tracks
  + Supported for both Free and Premium accounts
  + Triggers on add/remove of playlists or tracks within playlists
  + Changes trigger a full re-import of the relavent playlists
  + Sync intervals include: On Startup, 15min, 30min and 1 hour
  + "Quick Refresh" in the Spotify Library manually triggers sync check 
+ First iteration of ability to import and play Spotify podcast episodes
  + Episodes currently must be added to a regular user Spotify playlist
  + Expanded podcast features are planned (syncing subsciptions/shows..etc)
+ New enhancements for managing playlist items via drag-n-drop
  + Ability to reorder playlist items via drag/drop
  + Ability to move/copy items between playlists via drag/drop
  + Now works for multi-selected items!
  + Ability to drag multiple items from library to playlists
  + Playlists themselves cannot (yet) be dragged
+ Experimental support for ublock Origin AD blocking for webview2
  + Uses a pre-release build of webview2 SDK and requires Dev/Canary install of Edge
  + To test, Dev or Canary build of MS Edge must be installed
  + Ublock origin extension and files are included, default extension settings used
  + Cannot access ublock dashboard and settings are preconfigured
  + Initial testing shows greatly improved ad blocking for youtube without added delays
  + Existing custom Ad-Block solution still used, mostly now as a fallback
  + More testing needed, ability to configure/enable/disable extensions planned
+ New module Set-SongInfo for writing metadata to media file tags (not yet used)

### Changed
+ Removed no longer used assembly DataGridExtensions
+ Find-FilesFast now supports regular expression filters
  + Filters against file names only (not full path)
  + Simple filters improve enumeration performance
  + Complex expressions (groupings..etc) can hurt performance
+ Performance improvements for local media enumeration and scanning
  + Improved filter performance via File-FilesFast with simple filters
  + Taglib scanning now uses multi-threading via Invoke-Parallel
  + Taglib scanning improvements heavily dependant on CPU cores available
+ Various improvements to memory overhead and cleanup of objects/events
+ General minor to medium performance improvements in enumeration loops
  + Replaced foreach loops with pipelined processed scripblocks
+ Improvements to load performance and overhead of Splash Screen UI
  + WPF for splash screen UI is now compiled C# in EZT-MediaPlayer-Control.dll
+ Improved compatibility and reliability for Libvlc version 4
+ Minor improvements to XAML loading performance for Show-FirstRun UI
+ Various code, comment and logging cleanup
+ Updated twitch.py streamlink plugin to latest version
  + Installed streamlink plugins now automatically checked and updated if needed
+ Twitch TTVLOL plugin now has multiple proxy servers to fall back to for redundancy
+ Updated libvlc to version 3.0.18  - includes minor performance and bug fixes
+ Updated adblock plugin for Spicetify to latest version
+ Streamlink updated to latest version (6.0.1)
+ Toast notifications are now displayed when a configured Twitch channel goes live
+ Improved performance of Twitch status lookups by about ~20%
+ Refactors to Skip Media commands to streamline and improve lookup performance
+ Refactors to local media profiles and properties to reduce size and overhead
  + Changes will require a full rescan of all local media on version upgrade
  + Changed how ID's for files are generated to reduce string length and collisions
  + Local media in custom playlists profiles are now updated from media scans
  + Removed multiple object properties that are no longer needed
+ If open process is detected upon startup, a choice is now given to force close or exit
  + Prompt now shows more info about existing process including PID and date/time
+ Updated help documentation for various settings

### Fixed
+ Fixed #205: Twitch AD Skip settings dont take effect on reinstall
+ Fixed #258: Playlist numbering doesn't update when removing items
+ Fixed #259: Spotify and Twitch Library UI groupings do not save
+ Fixed #260: Setting Discord presence fails for titles with more than 128 chars
+ Fixed #261: About Me window crashes on opening
+ Fixed #262: Toast Notifications sometimes not working or displaying properly
+ Enumeration errors can occur when processing history list for jump lists
+ Live alert notification settings sometimes lost for configured Twitch channels
+ Youtube urls are sometimes not validated properly preventing webplayer from working
+ Update-LocalMedia can sometimes get caught in a loop if an error is encountered
+ Splash Window handle not properly registered with App ID on first run
+ Logs sometimes written to previous version log files after upgrading

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will trigger first time setup, and all media library profiles will be rebuilt

## 0.9.3 - BETA-002
> - Branch: Samson

### Added
+ New, Import, Export and Refresh buttons for video player overlay playlists view
+ New right-click menu option - Remove From Playlist - All Playlists
  + Supports multi-selected items in library, playlists or play queue

### Changed
+ Refactors and improvements for recently replaced TreeView controls
  + Now possible to use 'Play' and 'Add to Play Queue' options for playlists
  + Now possible to multi-select items when adding to or removing from playlists
  + Now possible to use 'Save as New Playlist' option
  + NOTE: DragDrop features are still WIP and currently broken for playlist views
+ Removed assemblies that are no longer used or required
+ Lookups via Win32.RegistryKey are now properly disposed
+ Video Player is now automatically undocked/opened on playback when using MiniPlayer
+ Improved various WPF style effects to reduce blurriness of icons and buttons
+ Webplayer EQ is now automatically disabled if virtual audio device is not detected
+ Reduced global Libvlc gain from 6 to 4 to prevent clipping in some cases
  + Ability to control global gain via UI is planned
+ Refactored and moved Add-WPF menu function to Set-WPFControls module
+ Reduced latency of audio playback for Webplayer EQ when playing videos
+ Improved performance for lookups and removals of multiple playlists
+ Replaced all uses of StackPanel with VirtualizingStackpanel for improved UI performance
+ Changelog now included within Inno Setup installer

### Fixed
+ Fixed #253: Can't play playlist, but can play files in the playlist
+ Fixed #254: Video player and tray contextmenu's are missing styles for submenus
+ Fixed #255: Video player is blank when manually opening in MiniPlayer mode
+ Fixed #256: Video overlay controls remain visible when closing in MiniPlayer mode
+ Fixed #257: Jumplist tasks stop working after reinstalling Samson to new location

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.3 - BETA-001
> - Branch: Samson

### Added
+ First iteration of new real-time monitor for local media directories
  + New option under Settings - Local Media - Monitor Local Paths
  + Configure monitor mode to watch for events New, Removed or All
  + Events only trigger for supported media files
  + Events trigger respective action to update media library and playlists
  + Events are queued with small delays to prevent race conditions
  + Uses new module EZT-FileWatcher and Get-ProfileManager
  + Additional config options and events planned such as file renames

### Changed
+ Invalid items in history list are now removed during enumeration
+ Improved error handling and accuracy of lookups in Get-MediaProfile
+ Various optimizations to improve memory usage and performance
  + Removed redundant string properties from local media profiles
  + Improved variable scoping and managment for runspaces
  + Improved cleanup operations for events and disposable objects
  + Utilized pipelines for data processing more where possible
+ Lowered Tor Browser UI refresh rate when downloading to reduce UI stutter
+ Moved function Start-WebNavigation to module Initialize-Webview2
+ Internet connectivity checks now performed before API lookups are made
  + A notification is displayed if relavent API domains are not reachable
  + Reduces uneccessary errors and connection attempts if unreachable
+ Refactored Twitch/Youtube status update/refresh monitors
  + Improved loop timing to prevent deadlocks and allow aborting easier
+ Refactors and improvements for Remove-Media
+ Refactored Background_Update_Timer into function Update-MediaState
+ Improved playlist/queue lookup performance in media timers
+ Runspaces now use a more strict InitialSessionState to reduce overhead
+ Minor refactors and improvements to the JobCleanup Runspace
+ FileFilesFast now returns whether a file is a SparseFile
+ Various code cleanup and changes to logging output
+ Improved display target calculations for 'Move Samson to Current Screen' Jumplist task
+ Various XAML optimizations to improve render performance and reduce memory usage
  + Set BitmapScalingMode to LowQuality where appropriate
  + Enabled CacheMode on image and canvas controls
  + Set resource lookups to Static vs Dynamic where possible
  + Reduced FindAncestor binding lookups where possible

### Fixed
+ Fixed #243: Some youtube urls with extra parameters are unable to be played/processed
+ Fixed #244: Incorrect local media profile IDs cause issues with duplicate or failed lookups
+ Fixed #245: Crash/unhandled exception can occur on app close if floating windows are open
+ Fixed #246: Crash recover handling incorrectly attempts to restart app under admin context
+ Fixed #247: Webplayers sometimes have no sound when Web Player EQ is enabled
+ Fixed #248: Twitch icons missing in playlists after first run until manually refreshed
+ Fixed #249: Potential memory leak can occur after displaying Left/Right Speakers
+ Fixed #250: Youtube auth window may come up again after just submitting credentials
+ Fixed #251: Youtube Playlist Auto Sync interval setting fails to save
+ Fixed #252: Video and audio out of sync when using EQ with Youtube webplayer

## 0.9.2 - BETA-002
> - Branch: Samson

### Added
+ First iteration of automatic subtitle support for local media 
  + Click CC icon in video player to see available subtitles or try fetching
  + Can detect and use embedded subtitles in media files that have them
  + Auto-Fetch uses Open Subtitles API to attempt query and download of SRTs
  + File hashes of media files are used to aid API lookup queries
  + Accuracy and proper subtitle timing will vary greatly depending on video
  + Can globally enable/disable using subtitles by default in General Settings
  + Subtitle lookups currently limited to 10 per day while API in testing
  + (TESTING) Added increase/decrease delay buttons for out-of-sync CC adjustment
+ Ability to 'await' tasks asynchronously with new function Wait-Task
+ Initial framework and test modules for integration with The Movie Database API
  + (SOON) Will allow local media metadata lookup for Movies and TV Shows
  + (PLANNED) Allow automatic cataloging and grouping of Movies/Shows/Episodes
  + (PLANNED) Add a 'Netflix' style interface for using with a 'couch/TV' type mode
+ Custom Jumplists tasks when right-clicking icon in tray or start menu
  + Task: Move Samson to current Screen (or launches if not running)
    + Ex: Can help when app window spawns on a monitor/screen no longer connected
  + Task: Start Samson as Miniplayer - See known issues list for Miniplayer
  + Recent: Shows last 5 played media, select starts the media when Samson loads
    + Doesn't work if Samson already running, looking into ways to support this 
  + Others to be added - ideas welcome!
+ Ability to configure in-app notifications when Twitch channels go live
  + Right-click on Twitch channel - Twitch Actions - Enable Live Notifications
  + Can globally disable/enable via Settings - Twitch - Enable Twitch Notifications
+ Ability to pause media when clicking on video player window/overlay

### Changed
+ YT videos can now be played/downloaded at premium quality without YT Premium sub
  + Works by supplying extractor-args in yt-dlp to make YT think device is iOS
  + Not compatible when using Webplayer for playback	
    + But can download at premium quality and play with native player (no ads too!)
  + Must set preferred Youtube quality to Best
  + Very possible Youtube plugs this loophole and can stop working at any time
+ First iteration of TreeView (Playlists) controls overhaul, refactor and redesign
  + Standard TreeView's have been replaced with Syncfusion SfTreeView controls
  + Adds ability to use multi-select of treeview items (finally)
  + Improves UI styling, consistency, quality and usability 
  + Mostly core changes now, redesign of layout and other features to come later  
  + This temporarily breaks drag-n-drop features for playlists, restored next build
+ Updated included Syncfusion assemblies to latest version
+ Further improvements for skipping sponsored YT video segments via Sponsorblock
  + Can now skip sponsored segments using the native player for Youtube videos
  + Using webplayer still recommended, more optimizations are needed
+ Updated function names in Get-HelperFunctions module to use approved verbs
+ Various code/comment cleanup and changes to logging, reduce logging verbosity
+ Further optimizations and improvements for Youtube webplayer Ad Blocking
  + Ads that start playing before they are fully skipped are now muted
  + Ads are now detected and skipped for YoutubeTV VODs
+ Further performance improvements and optimizations for Get-PlayQueue 
+ Updated included winpython package to latest version
  + Also now using the 'dot' package which reduces the total file/install size
+ Updated Microsoft Webview2 assemblies to 1.0.1905.0
+ Blocked 'Fullscreen not available' message that can display in Youtube webplayer
+ All UI window handles now properly registered to installed app id/icon
  + Samson windows should no longer appear to be running from Powershell in taskbar
+ Reduced cases where Get-Playlists needs to scan and reimport all playlists
+ Local media now updated automatically on playback if file path has changed
  + Mostly applies to media that had outdated paths from old/imported playlists
+ Replaced Windows.Forms.ApplicationContext with Windows.Threading.Dispatcher
  + Improves UI thread handling and is more relevant to WPF
  + Needs testing to ensure nothing breaks, especially with multiple sub-windows
+ Local media library now displays file progress during background tag scanning
+ Tor features/support is now optional component in Inno Setup installer
+ Refactores and code optimizations for Get-LocalMedia
+ Set GAIN for new libvlc instances to closer match VLC's default (6.0)
  + THIS was why the default volume always seemed so low compared to VLC
  + This will also seem to increase the effects of EQ band adjustments
+ Preparations, refactors and other changes to support LIBVLC 4
  + v4 support needs more testing is still in pre-release
  + Current v3 doesn't support audio/video filters, an issue hopefully 4 will fix

### Fixed
+ Fixed #236: Playlists collection enumeration error sometimes occurs in Get-Twitch
+ Fixed #237: Fullscreen button within Youtube webplayer sometimes doesnt work
+ Fixed #235: Set-AudioSession loops due to audio sessions not properly registered
+ Fixed #234: Youtube webplayer causes excessive API calls while playing
+ Fixed #134: Youtube ADs play for a few secs before being blocked with WebPlayer
  + Slight delay still possible, best can do with current webview2 implementation
  + Webview2 soon getting proper extension support (ublock!) which should help more
+ Fixed #238: Native Youtube webplayer controls sometimes become inaccessible
+ Fixed regression for #221: Discord presence not always updating
+ Fixed #239: Prev/Last Played commands unable to find media in history list
+ Fixed #240: Media files fail to load when passed with launcher args
+ Fixed #241: VB-Cable fails to uninstall when disabling Web EQ Support
+ Fixed #242: App sometimes crashes when disabling EQ while playing

### Comments
 + Not posting a build for this one, too many core changes that arent finished
 + A usable build will be available with these changes/features in 0.9.3

## 0.9.2 - BETA-001
- Branch: Samson

### Added
+ Ability to manage Youtube account playlists from Samson
  + First iteration allows adding videos to existing or new playlists 
  + Selecting 'Add to New Playlist' will create new playlist on YT side
  + Current incomplete features/limitations:
    + Adding from an existing playlist to another 'moves' it within Samson
    + However on Youtube side, video is 'copied' from existing to new
    + Can only perform action one video at a time via right-click menu (for now)
  + PLANNED: Ability to rename or delete YT playlists and change privacy status
+ Ability to automatically skip sponsored segments of YouTube videos (SponsorBlock)
  + First iteration of integration with the awesome Sponsorblock API
  + Currently only works with Youtube webplayer, native player support WIP
  + Can be enabled under Settings - Youtube - Youtube Options
  + Only the 'Skip' action type works in this build, mute action is WIP
  + This early version may not be consistent in recognizing some segments
+ Preliminary resources and test modules for SQLLite integration
  + Not currently used, for testing for potential migration  
+ Ability to specify local interface Streamlink uses for HTTP server
  + Located under Settings - Twitch - Twitch Advanced Options
  + If left to default option steamlink now only uses loopback vs all

### Changed
+ Improved performance when initializing new libvlc instances
  + Cache for libvlc (plugins.dat) now generated and included in each build
+ Performance and reliability optimizations for update-playqueue
+ Reduced amount of IO import calls needed for Get-Twitch functions
+ Various code/comment cleanup and updates to logging output
+ Invalid/deleted/removed YT playlists are now removed during Youtube sync
+ Existing Youtube profile is now removed if no media was found during import
+ Improved local media path detection and handling during first run setup
+ Next iteration of changes to improve TOR streaming and downloading
  + SOON: UI window to allow viewing and choosing files to download/stream
  + Currently if there are multiple files in torrent, the first is selected
+ First run setup after version upgrade is now only executed if changes require it
  + First run setup normally causes all media profiles to be rebuilt
  + Will likely still occur more often than not, but should become less and less
  + Not executed for build updates, and now only for version updates if needed
+ Reduced amount of manual garbage collection calls used for performance testing
+ Updated and improved Youtube AD Blocker js script
  + Should (hopefully) catch more ads and sooner
+ Registered event 'Opening' for new libvlc instances
  + Used to set various properties while media is in a loading state  
+ Various UI adjustments, additions and optimizations for the video player overlay
  + Now displays current/total duration timer
  + Title/artist label moved up to avoid overlap when having alot of characters
  + Improved visibility of overlay text over brighter/white background content
+ Streamlink package updated to v5.5.1 - existing installs will be updated
  + Adds ability to specify IP via ```--player-external-http-interface```
+ Changes to further limit scenarios were Samson needs to run as admin
  + Chocolatey no longer needs to be installed under administrator permissions
  + Helps simplify installing, updating and removing components
  + Samson now launches under user context after install wizard completes
  + May not work in some scenarios such as if explicitly run as admin by user
+ Improved general error handling in various places
+ Made is easier to build installers for versions with different features included
  + EX: Can build a version that doesn't include any TOR related files/features
+ Updated README and various helper docs - more passes still needed

### Fixed
+ Fixed #222: Video Player background sometimes changes/flashes white
  + More accurately is a workaround to an outstanding bug on libvlcsharp side
+ Fixed #220: Thread access violation errors during .NET debugging
+ Fixed #223: Twitch playback fails if Ipv6 is enabled on main net interface
+ Fixed #207: Crash playing spotify song
+ Fixed #179: Not Responding (related to Media Library sorting/filtering)
+ Fixed #229: Install-ProtonVPN fails to download latest version from Github
  + Also fixes issue with newer installed ProtonVPN versions not being detected
+ Fixed #227: Queue can fail to update when media ends or clicking clear/refresh
+ Fixed various XAML binding errors related to queue and playlists
+ Fixed #224: Selecting STOP doesn't always cancel media if in a loading state
+ Fixed #228: UI hangs at 'Loading...' when encountering unknown media errors 
+ Fixed #226: Streamlink sometime is closed before playback of Twitch streams begin
+ Various UI errors since apparently I can't spell the word 'Visible' correctly
+ Fixed #230: Config file can become corrupt when app restarts after first setup
+ Fixed #231: File browser dialog defaults to broken file path on PS 7
+ Fixed #221: Discord presence not always updating
+ Fixed #232: Chocolatey installs fail due to deprecated listonly parameter

## 0.9.1 - BETA-003
- Branch: Samson

### Added
+ Second iteration of Auto Sync for Youtube playlists
  + Playlists are now checked for new/removed videos against current library
  + Changes trigger a full re-import of the relavent playlists
  + (PLANNED) Sub-option to toggle playlist content syncing

### Changed
+ Updated included 'Return Youtube Dislike' script to latest version
+ Implemented new AD Blocking solution for Youtube webplayer
  + Should be more reliable at stopping/skipping ADs sooner with less overhead
  + Requires more long term testing
+ Various improvements to error handling and stability
+ Changes to threading and file IO activity detection
  + To hopefully prevent import errors accessing open files

### Fixed
+ Fixed #218: Crash during playback
  + Needs more testing to be sure. Report if issue comes back
+ Fixed #219: Youtube library grouping not persisting on app restart
+ Unable to use Youtube webplayer controls when undocking video viewer 

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.1 - BETA-002
- Branch: Samson

### Fixed
+ Partial-Fix #217: Twitch Playback is broken (by Twitch)
  + Twitch added integrity checks which breaks all third-party Twitch apps
  + Implemented workaround by passing client ID of Nintendo Switch
  + Unknown how long this temp fix will last, hopefully until proper solution
+ Fixed #216: Update notification after first install even if on latest version
+ Fixed #190: Monitor/Spectrum Analyzer stops when closing Audio Options Window
+ Saved media library groupings sometimes dont apply on app start

### Comments
+ This update is mostly just to provide a temp fix for Twitch playback issue
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.1 - BETA-001
- Branch: Samson

### Added
+ First iteration of Auto Sync for Youtube playlists
  + Youtube media library is refreshed when playlists found or removed
  + Update intervals include On Startup, 15 mins, 30mins and 1 hr
  + Custom or manually added playlists will NOT be removed or changed
  + Changes to playlists content (add/remove videos) do not yet trigger refresh
  + Ability auto-sync playlist content is planned for future iterations
+ New option 'Import/Scanning Mode' to control local media import speed 
  + 'Fast Importing' toggle is now the 'Fast' drop-down option (Default) 
  + 2 other new options include 'Normal' and 'Slow'
  + Slow mode is intended for storage paths with poor IO latency/throughput
  + Read in-app help description for more detail on each new mode
  
### Changed
+ Custom/User created groups in Media Libraries are now saved/persistent
  + Groups are reapplied on next start, including multi-level groups
+ 'Collapse all groups' setting for Media Libraries is now saved/persistent
+ Improved error handling and reliability of Youtube Oauth capture
+ Twitch library now includes viewer count column for live channels
  + View count only gets updated if 'Auto Stream Update' option is enabled
+ Various code cleanup and updates to logging
+ Various reliability improvements for write-ezlogs
+ Refactored Spotify_WebPlayer_timer into function Set-SpotifyWebPlayerTimer 
+ Refactored Youtube_WebPlayer_timer into function Set-YoutubeWebPlayerTimer 
+ Queue now advances vs stopping if Twitch stream is offline when playing
  + Applies only if Auto Play is enabled
+ Experimental ChatBot is no longer available via DevMode - API trial expired

### Fixed
+ Spotify playback sometimes stops working after 1 or 2 played tracks
+ Fixed #208: App sometimes crashes when closing
+ Fixed #209: Youtube videos sometime get duplicated on import
+ Fixed #167: Library window doesnt open on active screen w/Multi-Monitors
+ Fixed #210: Manually refreshing Twitch can cause library to freeze or crash
+ Fixed #211: Collapse all groups missing for Twitch Media Library
+ Fixed #213: Youtube webplayer not logging in with saved cookies/credentials
+ Fixed #214: Queued messages never get written to logs on app exit
+ Sometimes unable to sort or group by Status in Twitch library after a refresh
+ Playlist/Queue import errors can occur due to thread race conditions
+ Twitch Status monitor runspace may not stop after disabling option
+ App crash can occur when refreshing Youtube library due to incorrect INT cast
+ Fixed #61: Youtube Autoplay
  + Fixes issue where videos dont start playing unless player is in view
  + Finally this long-standing issue should be resolved, but needs more testing
+ Fixed #119: EQ resets on change of media when Audio option window is open  
+ Fixed #157: Child Windows do not activate with Main Window
+ Fixed #215: Youtube webplayer stops playing when no longer visible

## 0.9.0 - BETA-004
- Branch: Samson

### Added
+ Ability to use EQ with Spotify Client for free account playback
  + Requires having 'Enable EQ Support for Webplayers' enabled (WIP)
  + Redirects audio from Spotify to virtual audio device like webplayers
  + First iteration that is heavily WIP along with other free Spotify features
  
### Changed
+ Various minor adjustments to logging and error handling
  
### Fixed
+ Fixed: #206 - Spotify Times out after each song
  + Requires more testing, further improvements planned but should work
+ Fixed: #204 - Spotify Confusion (fixed in BETA-003)
+ Spicetify auto-install sometimes doesnt' trigger properly in Invoke-Spiceitfy

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.0 - BETA-003
- Branch: Samson

### Added
+ 'Collapse all Groups' option for Spotify,Youtube and Twitch libraries
+ Ability to export all custom playlists to specified folder
  + New 'Export' button in UI under playlists, prompts for folder
  + Exports all playlists to separate XML files
  + More options planned such as single file vs multiple, automation..etc
+ Ability to import multiple playlist files at once
  + Prompts to automatically overwrite any existing found or individual
+ Ability to filter local media by file type or video/audio
+ Syncfusion libraries and resources for sfTreeView
  + Will be for upcoming refactors/redesign of playlist UI
  
### Changed
+ Second refactor pass for Spicetify/Spotify Free account support
  + Enabling Spicetify no longer requires running app as admin 
  + Enable Spicetify option now located under Spotify options vs advanced
  + Now only Web Player or Spicetify option can be enabled (Premium vs free)
  + Improved playback response time when using Spicetify
+ Refactored and updated audio monitor logic and UI
  + Audio monitor enabled state now persists/saved to config
  + Monitor display no longer dissappears unless disabled
  + Monitor button now lights up when checked/enabled
+ Removed various duplicate/unnecessary code in some places
+ Various improvements/refactors for removing multiple media from libaries
  + Refactor ongoing, performance improvements coming for large libraries
  
### Fixed
+ Fixed #159: Audio Monitor display stops working after 1 or more media plays
+ Fixed #203: No audio when enabling EQ while playing via webplayers
+ Play queue sometimes doesnt update when playback stops
+ Fixed #164: Playlists are labeled as custom under Youtube Importing
  + Could still be labled as custom if playlist name can't be found
  + Playlists found from custom created lists will have custom in type column
  + Also fixes an issue where duplicates could sometimes appear
+ Fixed #202: Incorrect album/covert art sometimes displayed for media
+ Fixed #191: Nothing happens when trying to remove media from local library

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.0 - BETA-002
- Branch: Samson

### Added
+ Ability to expand or collapse all groups in Local Media Library
  + New checkbox option in library 'Collapse all Groups'
  + Only works if library is currently grouped, applies to all levels
  + Only available for Local Media library currently 

### Changed
+ Group drop header area in local media library now expanded by default

### Fixed
+ Fixed #201 - Album Names show in Artist Column
+ File browse buttons not working in various places

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.9.0 - BETA-001
- Branch: Samson

### Added
+ Ability to use native EQ for Web Players (Youtube and Spotify playback)
  + Must enable setting "Enable EQ Support for Web Players" in Settings
  + Installs new virtual audio device (VB-CABLE) when enabled
  + Routes audio from web player process to a virtual audio device for playback
  + Requires Windows 10 April 2018 Update or later
  + Still WIP. Read help information of setting before using
+ Ability to detect and display chapter info when playing video files
  + Current playing chapter name/number displays with title while playing
  + Naturally only works if played video file contains chapter metadata
  + Chapter support to be expanded to allow selecting and other features
+ Experimental implementation of a TOR Browser
  + EXTREMELY WIP. USE WITH CAUTION. DO NOT SHARE THESE BUILDS
  + Utilizes we-get to search common torrent providers for magnet links
  + Utilizes MonoTorrent Torrent manager to download torrents
  + Requires active VPN connection to use - autochecks if one is active
  + Checks current public IP against known VPN subnets
  + If no VPN detected, warning is displayed to user before continuing
  + If VPN is lost while downloading, all torrents stopped and warning shown
  + If torrent contains supported media, allows playback while downloading
  + If ProtonVPN installed, prompts to launch and wait for connection
  + Playback depends on download speed, usually slow to start
  + Tor results/management via new TOR Browser tab next to webbrowser
+ Ability to auto-install ProtonVPN client via VPN Tools in Settings 
  + Part of TOR Browser feature, to allow easy method of installing a VPN
  + Downloads and installs latest ProtonVPN client
  + Account is needded for ProtonVPN. Free accounts available and are decent
+ First iteration of ability to play media from memory streams
+ First iteration of (very) basic friends and sharing system
  + NOT YET FUNCTIONAL - only basic groundwork in place
  + Will allow sharing playlists/media with friends
  + Maybe some kind of ability to group listen/watch
  + Possible deeper integration with Discord for live sharing features

### Changed
+ First overhaul iteration of playback support using free Spotify accounts
  + Re-awakening this previously abandoned feature
  + Because free Spotify accounts cannot be used with API for playback controls
  + Requires enabling 'Use Spicetify' under Advanced Spotify Options
  + Spicetify used to customize and control playback of the Spotify client
  + Includes adblocker that should block both audio and visual ads in Spotify
  + Added ability to seek, mute and change volume of Spotify from app
  + VERY WIP and likely VERY buggy. Requires alot more work and testing
+ Launcher now allows passing any provided arguments to main script on startup
+ Various improvements to error handling
+ Improved detection, grouping and handling of spawned audio sessions
+ Improved reliability of playback when using Spotify Web Player
+ Improved metadata and property detection of local media files
  + FFROBE used as a fallback to get info if taglib fails to
  + Media file is re-scanned each time its played to refresh info
  + Mostly improves detection of bitrate and duration of media files
+ Improved detection of media that is located on network UNC/Mapped drives
+ Further improvements to performance and reliability of queue and playlists
+ New Twitch followed channels now added when auto update status is enabled
+ Various improvements to performance and reliability of Youtube adblocking
+ Various improvements to cookie handing for Youtube webplayer and webbrowser
+ Improved ad skipping for Twitch media playback
  + Fallback proxy added when using Luminous
  + If ad found using TTVLOL, now attempts to autorestart to get new playlist 
+ Various improvements to memory overhead, logging and performance
+ Check for updates now enabled by default (for new installs only)

### Fixed
+ Fixed #198: Some components are not fully removed when uninstalling app
+ Fixed #199: Miniplayer mute and progress slider not working in some cases
+ Fixed #194: Race condition causes mute state to become out of sync with UI
+ Fixed #133: Sorting and Filtering Slow for Large Media Libraries
  + Hard to say 'Fixed' totally but improved as much as possible for now
+ Fixed #156: Library Filtering and Sorting Issues
+ Fixed #183: Sort by Artist, Album, Track
+ Fixed #189: Settings window doesnt return after providing Spotify creds
+ Fixed #193: App sometimes crashes during window size animations
+ Fixed #195: Endless Install Loop
+ Fixed #196: Accessing or storing secrets in SecureVault will sometimes fail
+ Fixed #197: Existing creds sometimes dont clear when attempting to update
+ Install of app updates fails after downloading latest version
+ Fixed #200: Volume state sometimes becomes out of sync with UI

### Comments
+ This build contains very WIP/experimental changes/features
+ Not recommended to use this build as daily driver, but testing is needed


## 0.8.9 - BETA-003
- Branch: Samson

### Added
+ New credit for QA tester Piscean to about page (thank you!)
+ Progress indicator when adding or updating playlists
+ Refresh button for Play Queue
+ New contextmenu option 'Add/Remove to/From Play Queue' for media items
  + Queue no longer shows as a Playlist under Add/Remove from/to Playlist
  + If item is in queue already the option will be Remove from Play Queue

### Changed
+ Improved performance when adding or updating large playlists
+ Improved performance when starting playback of new media
+ Minor changes to styling and colors for contextmenu's and other areas

### Fixed
+ Fixed #187 - Adding to Queue Hung
  + Duplicate Fixed #186 - Queue Didn't Update
+ Fixed #185 - Slow queue update performance with large amount of items
+ Fixed #184 - UI stutters during playback with large playlists/queue
+ Fixed #180 - No media after upgrade
+ Fixed #188 - AutoPlay from playlists not working

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.8.9 - BETA-002
- Branch: Samson

### Changed
+ Hotfixes and smaller updates are now reflected in build numbers
  + Ex: This build version is 002. Full version and build is 0.8.9_Beta-002
+ Now possible to enable Spotify integration without providing credentials
  + If creds are missing or invalid a warning is displayed
  + No valid creds means most Spotify functions (playback..etc) wont work
  + Will be more relavent in future versions with local only Spotify support
+ Minor improvements to memory overhead when encountering errors

### Fixed
+ Duration sometimes shows as 0:0:0 for local media
+ Fixed #182 - Crash on playing from playlist after update .0.8.9
+ Spotify authentication window sometimes launches multiple times
+ Unable to manually change Youtube quality using webplayer
  + Was locked into quality level set with Preferred Youtube Quality option

### Comments
+ To install, go to title bar menu - check for updates - click install
+ Will not trigger first time setup, will install over existing

## 0.8.9 - BETA
- Branch: Samson

### Primary Feature Overhaul: Media Library V1
+ First iteration (of many) for new Media library system overhaul
+ Implements Data and UI virtualization via Syncfusion WPF libraries
+ Advanced filtering per column with greater granularity
+ Greatly improves sorting, filtering and overall UI performance
+ Existing filter textbox remains as a global filter
+ Paging no longer needed, items are loaded as you scroll
+ Items are no longer grouped by default, left up to user
+ Create groups by dragging column headers into group drop area
+ Can create as many sub-groups as are columns available
+ Can view playlists and queue side-by-side next to libraries, width adjustable
+ Drag/drop from libraries to playlists (need at least 1 playlist) or queue 
+ More improvements/adjustments to come, including more views/filters

### Added
+ New Local Import Option: Fast Importing (Default: Enabled)
  + Drastically improves performance of local media file importing
  + Skips tag metadata scanning until first import is complete
  + After first import, tag scanning is performed in the background
  + Library media info is updated asynchronously as files are scanned
  + Media info will be inaccurate/incomplete until tag scan is finished
+ First (early) iteration of bookmarks system for Web Browser
  + Mostly academic for various techniques that can be used elsewhere
  + Implements custom Airhack assembly to work around WPF airspace issues
  + Ability to add current page or add new with custom dialog
  + Implements Treeview with HierarchicalDataTemplate itemssource binding
  + Likely to be expanded into other systems such as search and discover
+ First (very) early iteration of new Media Casting feature
  + New options added to Settings - General - Media Casting
  + New Media Casting button added to Video View overlay controls
  + Casting button brings up list of detected devices on your network 
  + Helper app called go2tv is used to relay and cast streams
  + Requires devices that support DLNA and on same local network
  + Only working to cast Twitch streams and local media currently
  + Read help topic of Enable Media Casting Support on how to use
+ EXPERIMENTAL implementation of built-in chat bot
  + Only available with Dev mode enabled
  + Powered by OpenAI (ChatGPT), just for fun to see what is possible
  + Please ask before using as API is in trial period with limited usage
+ Helper functions Get-ChildProcesses, Get-VisualParentUp -and Using-Object

### Changed
+ First iteration of core refactor and overhaul for custom playlist and queue
  + Greatly improved performance when processing large playlists and queues
  + Reduces many lag and UI freeze/stutters when playlists/queue are refreshed
  + Can now view and manage playlist/queues from video overlay and library
  + These 'duplicate' views are all synced and updating one updates all
+ Improved ability to open and play network stream URLs
  + Still WIP but now alot more valid network stream URls should work
  + Any media that is unsupported officially gives a warning when adding
  + No way to know if metadata will be accurate or will even have any at all
  + In theory any URL that VLC can open should work
+ Local paths added under settings are no longer enumerated fully for files
  + Up to 50 files are enumerated in paths for validation of supported media
  + Should greatly increase responsiveness and speed when adding paths
+ Various minor styling and label changes for some UI elements such as buttons
+ Second iteration of Feedback system overhaul and refactor
  + Categories have been simplified into issues,Feedback and Log dumps
  + Now possible to select an existing known issue to submit follow-up info
  + Greatly improved performance when fetching Known Issues
  + Small helper text now displays for each category selected
  + Direct links to Logs/attachments now embedded into Trello comments
+ Network interfaces now auto detected for streamlink when playing Twitch media
  + Used to limit # of interfaces where HTTP ports are created
  + If unable to determine, falls back to using default 127.0.0.1
  + This helps in some situations where using loopback causes issues
+ Refactored how Youtube auth cookies are captured, saved and applied
  + Improves reliability in some cases but more for back end optimization
+ Logging option 'Enable Verbose Logging' changed to 'Enable Dev Mode'
  + Should only be used by developers or if requested for troubleshooting
  + Enables extra logging plus enables experimental or test features
+ Greatly improved memory overhead for web-players - Related to issue #169
+ Minor improvements to YT web-player AdBlocker - Related to issue #169
+ Improved responsiveness of progress slider for some situations
+ Improved performance of various media lookups for large library collections
+ Improved error handling for EZT-AudioManager
+ Improved UI item selection and handling for playlists and queue
  + EX: Item you right-click on should be instantly selected in the UI
+ Improved performance of importing and processing of large Spotify profiles
+ Improved handling and prevention of race conditions for Update-MainPlayer
+ Updated yt-dlp to latest version (2023.02.17)
+ Improved playback performance for media files detected on network locations
   + Libvlc network caching now adjusts if file paths are detected as network
   + Should help reduce buffering/skipping of playback over network drives
   + The default before was low (300ms) and is now set to 1000ms 
   + Custom cache settings set from vlc command-line options override this
+ Updated included build of Streamlink (5.3.1-1)
  + Existing installs will be auto-updated on first run
+ Cleaned/consolidated/removed old or ununsed code in many places
+ Improved handling of potential duplicates in playlists or queue
+ Various adjustments and improvements to logging
+ Now possible to use in-app progress slider for Youtube webplayer videos

### Fixed
+ Fixed #165 - Multi-selected items are not added to the queue
  + Note: Playback should now also begin from first item in selection
+ Fixed #162 - MiniPlayer display text visible outside display screen
+ Fixed #166 - Removed local media paths sometimes return when adding new
+ Fixed #136 - Video Player opens downward, pushing down the main receiver
+ Fixed #139 - Visualizations can be enabled without selecting a plugin
+ Partial-Fix #154 - Open Media Issues
  + See change note about supporting more network streams.
  + More testing and work required
+ Fixed #155 - Progress indicator not working when adding Local Paths
+ Some media may fail to add to the play queue or disappear on refresh
+ Playback history fails to enumerate media items or contains blank values
+ Next/Skip media sometimes fails to find the media profile/info
+ Fixed #171 - Progress slider/timer not updating for Youtube webplayer
+ Fixed #170 - Setting YT preferred quality to Auto sometimes fails to save
+ Fixed #169 - Playlist / Queue Hung?
  + Related: Fixed large memory leak issue with Webview2 processes
+ Fixed #158 - Combo box Auto-Width causes scrolling issues
+ Fixed #121 - Enable Twitch toggles off sometimes after capturing auth
+ Fixed #173 - Display sliding text becomes missing or off alignment
+ Fixed #172 - Downloading Youtube videos fail or never finish
+ Fixed #175 - Textboxs in floating windows dont respond to arrow key inputs
+ Fixed #176 - Animated Scrolling jumps to location of the last used
+ Fixed #174 - Folder names with periods are processed as files
+ Secondary powershell.exe process stays open when using app with PS 7
+ Fixed #177 - Youtube auth can launch infinite windows on first import
+ Youtube videos (webplayer) never 'end' causing autoplay to stop working
+ Fixed #160 - Autoplay sometimes plays next media in queue out of order
+ Fixed #168 - Autoplay doesnt continue if encountering an error on next item 
+ Partial-Fix #132 - Unable to reorder playlists with dragdrop
  + Needs more work and testing but should now work for most 'simple' cases 
  
### Issues
+ Potential issues with drag/drop due to refactors of library and playlists
  + Please report any issues with drag/drop, but also expect them

## 0.8.8 - BETA
- Branch: Samson

### Added
+ Initial framework for upcoming feature: Chromecast support
   + Plan is to support casting video/audio to chromecast and DLNA devices
+ Ability to reinstall current version from 'Check for Updates' window
+ Recommended helper app phantomjs for YT-DLP
+ Ability for the app to restart into user context when under admin context
+ Ability to skip duplicate local media files when scanning/importing
   - New option 'Skip Duplicates' under Settings - Local Media tab
   - Read the settings help for more info on what is considered duplicate

### Changed
+ Splash screen image now always set to main logo image vs randomized
+ Improved feedback and progress status when importing media libraries
   + Progress now indicates how many of total have been processed
   + Youtube progress status now shows names of playlists as they are processed
+ Improved performance and memory overhead during import of local media
   + Taglib ReadStyle set to PictureLazy so images arent loaded during scan
+ Greatly improved performance of Youtube media library import process
   + Now uses parallel processing. Avg Before: 18s - Avg After: 6s (177 items)
+ Web browser now supports entering fullscreen for video players
+ Contextmenu for anchor tabs now work and match style of all the others
+ Various improvements and optimizations to memory and performance overhead
+ Improved clarity and smoothness of various UI animations and text
+ Improved and overhauled video Player open/close animation and behavior
   + Open/close now takes into account where app UI is located on the screen
   + Now expands upward so as not to push the app down and off the screen
   + App UI should now try to always stay in the same relative position
   + If not enough space above, moves to Y 0 and expands from there
   + Animations should be much 'smoother' tho some jitter remains
+ Improved playback performance for Youtube media when not using Web Player
   + Reduced amount of buffering that occurs especially with high-bitrate media
+ Replaced/updated sound effect for notification audio
+ Improved animation for opening and closing chat view
- Removed bundled Spotify installer to decrease installer build size
   + An included installer would pretty much always be out of date anyway
+ Improved logic and handling of floating windows
+ Greatly improved playback reliability for Spotify Web Player  
   + Playback should now always start without having to open video player
+ Updated included build of YT-DLP to latest version (2023.1.6.0)
+ App now auto-detects if configured local paths are network/mapped drives
   + Designed to help mitigate issues with net drives when app is run as admin
   + If app detects net drives and is under admin context, a warning is shown
   + The warning includes a link to allow auto-restarting the app as user
   + Main window title now includes 'Administrator' if app is running as admin
+ Changes to feedback/issue submission to help improve troubleshooting
   + Current logged-in username is now included when submitting any feedback
   + Config files and all profiles are now included when sending logs
+ Improvements to the Youtube webplayer Adblocker and embed fallback detection
   + Ads may still show for a brief moment but should be skipped sooner
   + Non-embed videos should switch back and forth to fullscreen less
   + These improvements admittedly small, further enhancements are planned

### Fixed
+ Fixed #140 - Local Media import error occurs with only 1 import source
+ Collection has been modified error sometimes occurs in Get-PlayQueue
+ Fixed #141 - Manually added media doesn't appear until triggering a filter
+ Fixed #142 - Long display titles hard to read with left to right animation
   + Main display screen text now animates from right to left with 3s delay
   + Direction change also applies to Mini Player screen text animations 
+ Fixed #143 - Minor typo in web browser ;)
+ NonWebPlayer playback of YT media fails when preferred quality set to Auto
+ Profile editor fails to load for any media
+ Duration and progress slider sometimes missing during playback of some media
+ Media control overlay sometimes missing when playing Spotify Media
+ Fixed #147 - Mini Player Stay On Top setting isn't retained
   + The setting is now also remembered on app restarts
+ Partial Fix #149 - Mapped network drives inaccessible during setup
   + App will now try to auto-restart into user context once setup is complete
   + Restarting as user from under admin is not normally a supported operation
   + As such, more testing and likely further adjustments will be required
+ Fixed #146 - Video stuck in fullscreen when entered using YT web player
+ Refreshing Local Media library creates duplicate entries and other issues
+ Removing or adding new local paths under settings doesn't update library
+ Partial Fix #150 - Adding media different between settings and Library
   + First refactor pass. Not final. More changes and testing is needed
   + Now possible to browse and add folder paths within the add dialog
   + Folder paths from dialog will add to Local Media settings table
   + Files opened with dialog do not add to Local Media settings table
+ Fixed #135 - Youtube auth for importing doesn't apply to WebPlayer
   + YT webplayer should now be logged in automatically with import account
   + If import account is YT Premium, this should help prevent getting Ads
+ Fixed #138 - Closing child windows with miniplayer open reactivates main window
   + This is a partial fix, may still occur in some cases 
+ Closing the settings window without saving can trigger libraries to refresh
+ Fixed #148 - Restart Media does work when remember playback progress enabled
+ Fixed #144 - Poorly formed file names trip up media import

### Builds
+ Updated /Samson-Setup.exe

## 0.8.7 - BETA
- Branch: Samson

### Added

+ Ability to Automatically check for and optionally install app updates
   + Auto Check\install options added under General-Updates section in settings
   + Updates are checked on startup. Notification displays if update available

### Changed

+ Updated included Avalondock assembly to latest version (4.71.0)
+ Separated various assemblies into .NET4 and .NET5-7 versions
  + Improves compatibility and performance when running on PS7
+ Some notification messages now include action/more detail links
+ Multiple refactors, optimizations and tweaks to XAML views and styles
+ Complete redesign, refactor and overhaul of Video Player and controls overlay
   + Overlay now emulates 'Youtube' style overlay style
   + Now includes progress slider, skip media and chat view buttons
   + Includes current playing title/artist and optionally Twitch viewer count
   + Can now right-click anywhere over video to bring up more options 
   + Allows true fullscreen (no borders/taskbar) with proper working overlay
   + Overlay controls auto fade-in/out much smoother and consistently 
   + Mouse cursor now auto-hides along with overlay controls
   + Includes ability to view current play queue within overlay
+ Improved reliability of Spotify playback using the Web Player
   + More improvements needed but play should start a little more consistently
   + Still possible playback wont start unless video view is open
+ All progress and volume sliders now properly show current value on mouse over
+ Cleaned up and consolidated Update-MediaTimer code
+ Decreased logging verbosity in various areas. Slowly doing more each version
+ Replaced DragMove calls with custom c# AttachedBehavior:EnableDragHelper

### Fixed

+ Fixed #69: Fullscreen Player/Window Issues (FINALLY hallelujah!)
   + This also fixes many issues with the overlay controls among other things
+ Crash or freeze can occur when enabling or disabling EQ or EQ 2PASS
+ Logging into Google using the WebBrowser results in endless refresh loop
+ Spotify.com site in the WebBrowser fails to load properly
+ Playback history never trims and causes issues with shuffle autoplay
+ Changing Group By filter doesnt work for the Twitch Library
+ Profile editor flyout background not applying making it unreadable
+ Autoplay+shuffle sometimes stops advancing after media ends
+ Fixed #131: DragDrop of playlists not working after latest refactor
+ Fixed #80: Progress Bar Display Issues
+ Fixed #125: Pause sometimes doesn't work with Spotify Web Player

### Builds

+ Updated /Samson-Setup.exe

## 0.8.6 - BETA
- Branch: Samson

### Added
+ CLI option NoMediaLibrary for skipping load of library on startup
   + Mostly for dev right now but can be used for future minimal start features
+ First iteration of group by filters for media libraries
   + Group by drop downs added to UI with default choices
   + WIP: Large libraries may update slowly
   + WIP: Some group options may cause blank expander headers
   + PLANNED: Ability to add/choose multi-level grouping
+ Helper module 'PSParallel' for multi-threaded parallel processing
+ Support for adding YoutubeTV urls via drag-n-drop into library
+ Additional support for adding and playing SoundCloud media
   + Right now they can be added manually as a Youtube source/link
   + Soundcloud media in playlists/queue now display with a SoundCloud icon
   + Soundcloud icon now displayed in Discord Integration during playback
+ Ability to manually refresh all custom playlists with 'Refresh' button
+ Ability to clear/empty custom playlists via right-click contextmenu
+ Various helper functions for upcoming features related to VPN usage
   + Test-Internet for connectivity check and auto-repair
   + Check-Subnet for parsing subnets from IP addresses
   + Install-ProtonVPN for automating silent install of ProtonVPN client
+ Helper function Lock-Object for locking during multi-threaded updates
+ Skip media button for TaskbaritemInfo (when hovering over taskbar icon)

### Changed
+ MASSIVE performance improvements when importing large media libraries
   + Now uses multi-threaded parallel processing, so will depend on CPU speed
   + EX: Spotify library of 40K items: 10+mins before now takes avg of 2+mins
   + Improvements are less drastic for smaller libraries 
   + Local media improvements will be very dependent on disk IO availability
   + Caveat: High memory and CPU usage during import, but settles after
   + Caveat: Improvement speed depends on CPU speed and number of cores/threads
   + Please report any issues. Further optimizations are planned
+ Disabled all access to image grid views for media library
   + Currently implementation has too many issues and not sure its useful
+ Minor performance improvements when using filters for large libraries
+ Library search filters now require at least 3 chars to trigger
+ Small improvements to library search filter accuracy
+ Various minor improvements to UI responsiveness and button lag
+ Various changes to logging verbosity and improved call back tracing
+ First iteration of refactor for Get-Playlists and other playlist functions
   + Goal is to improve performance especially for large amount/sized playlists
   + Now using itemssource binding for treeview and other xaml optimizations
+ Improved performance and memory overhead for Trello API calls
   + Effects known issues list, submitting feedback and update checks
+ Second iteration of Auto-Update and related features
   + Now possible to auto-install latest version using Check for Updates option
   + IMPORTANT: The app will automatically close and restart during update
   + Ability to auto check and notify for updates planned for next phase
+ Replaced various Invoke-Restmethod calls with HTTPWebRequest
   + Improves performance and mostly memory overhead
+ Updated included FFMEG resources to latest version
+ Set minwidth for library floating window to avoid 'squished' UI elements 
+ Removed various unused/old resources
+ Optimizations, tweaks and performance improvements for WPF/UI elements
   + Reduced use of FindAncestor in property and data bindings
   + Replaced stackpanel with virtualizingStackpanel in various areas
   + Set VirtualizationMode="Recycling" wherever made sense/able
   + Removed unused or unnecessary WPF styles and resources
   + Consolidated some styles into one, especially for main control bar buttons

### Fixed
+ Items in playlists can appear blurry especially at the top
+ Some modules might not load if not located in module root directory
+ Fixed #130 - Spotify media doesnt start from a playlists or queue
+ Playback doesnt start when adding Youtube links via dragdrop if enabled
+ Fixed #129 - Recorder doesn't record entire Spotify Song
+ Fixed #127 - Discord Presence Label Links for Spotify Not Working
   + Now opens in web browser with prompt to open with client if installed
+ Fixed #122 - Chat view doesn't close if open when changing media
+ UI can freeze and other issues when changing color theme during playback
+ Miniplayer play/pause button state not syncing with main player
+ Spotify Connect device name still shows as EZT-MediaPlayer
+ Downloading YT media sometimes ends prematurely or leaves temp files
+ Multiple notifications are created vs updating single during download media

### Builds
+ Updated /Samson-Setup.exe

## 0.8.5 - BETA
- Branch: Samson

### Added
+ First iteration of playback history and recall via Back button
   + Up to 5 previously played media items are saved in ordered dictionary list
   + Each click of Back button traverses through history list
   + Does not yet honor current playlist unless tracks are in play history
   + Requires testing, tweaking and possible expansion
+ First iteration of support for import and playback of Spotify podcasts/shows
   + Not complete but should allow importing into library
   + Playback is so far untested

### Changed
+ Known Issues list under Feedback page now fully integrated with live list
   + All tracked open issues are imported and displayed on feedback page open
   + Can take a few secs to import, progress bar displays while loading
+ Media library playlists are now honored as playback queues
   + Currently only applies for Spotify and Youtube libraries
   + Playback started from item in library continues from within that playlist
   + If any media is in main playback queue, those are still played first
   + Playback stops on reaching end of a playlist, does not start a new list
+ First iteration of Spotify import refactor and optimizations
   + Greatly reduced total Spotify profile size for large libraries
   + Playlist info now stored in separate profiles, accessed when needed
   + Greatly reduced memory overhead during API lookup and import calls
   + Improved first time and cached startup import performance
   + Greatly improved performance of right-click contextmenus for Spotify media
+ Spotify library tab now displays more detailed progress during import
+ Improved performance when loading large filter dropdown menus
+ Right-click contextmenus no longer generate new menus on every click event
+ Refactored and Restyled various buttons and controls for main button bar
   + Primary Play button now behaves only as Play/Pause vs restart media
   + Pause button replaced with RESTART for restart of playing media
   + Various WPF refactors to consolidate too many separate styles
   + Moved RECORD button to the far left of main button bar
      + RECORD button serves no function currently but will in near future
   + Layout not final, further adjustments and tweaks needed
+ Splash screen no longer displays on startup if Start Minimized is enabled
+ Disabled Spotify image caching until refactor and optimizations are completed
   + This basically breaks ability to use image grid view for now
+ Improved playback stop lag when skipping Spotify media using web player
   + EX: Spotify track would keep playing for a few secs on skip
+ Various performance optimizations for WPF stackpanels and lists
+ Reduced size of and other various changes to primary inno installer

### Fixed
+ Youtube options appear in Webbrowser menus even if YT integration disabled
+ Old logo and app name still showing in Discord presense 
+ Fixed #124 - Full Refresh of Spotify Library occurs when saving settings
+ Fixed #123 - Contextmenu freezes when opening for Spotify tracks
+ 'Content length' errors sometime occur for some Spotify API calls
+ Duplicates of shared images are cached and generated for some Spotify media 
+ Setting user agent title/icon for libvlc sometimes fails on playback
+ D1 easter egg fails to launch due to compressed MPQ file
+ Cassette Wheel animations still play when pausing Spotify media

### Builds
+ Updated /Samson-Setup.exe

## 0.8.4 - BETA
- Branch: Samson

### Milestone - Samson BETA_R1
+ Final build before reveal! 

### Added
+ New About window accessed from main title menu
  + Mostly contains just Credits. Additional info potentially added later
+ New icons for all main title menu options
+ New custom main logo and application icon made by Scooped Doodles
  + Made a couple modifications and added sunglasses
  + Added to splash screen image rotation. Defaults to primary on first run
+ New 'Known Issues' list for the FeedBack/Issues form window
  + Currently its updated manually so goes out of date fast
  + Eventually to be automated and connected to main issue tracking lists
+ Special 'Dedication' window that displays during first run
  + Only included for personal Samson reveal build
  + Displays only on first run. Read state saved to app config
  + Can also be accessed anytime via Dedication option in main title menu
  + Added custom sound effect on loading

### Changed
- Removed unused Mahapps Metro assemblies
+ Improved error handling and filtering of supported urls for media downloads
+ Completed rebranding and testing for Samson BETA release/reveal
  + Updated Discord integration branded and icons from Discord dev portal
+ Completed conversion of help topics to new markdown system
+ Updated Prev/Next button icons to SkipPrevious\SkipNext 
  + No time so added message when using prev button that it doesnt work yet :(
+ Restyled help flyouts to match main theme
+ Updated important info page for Inno installer
+ Various updates and changes to performance logging and GC collection
+ Error variables now cleared in catch blocks to prevent memory leaks
+ Various memory and performance optimizations

### Fixed
+ Fixed #115 - Audio Monitor doesn't persist on change of media
+ Fixed #95 - Youtube webplayer fails to play licensed/restricted content
+ Fixed #64 - Mute Status Lost on Playback
+ Some Youtube media shows as local media in playlists and queue
+ EQ sliders missing default theme color and styles when no theme is selected
+ Fullscreen button doesnt work for some Youtube media when using Web Player
+ Feedback form can sometimes freeze after submitting new record
+ UI doesnt fully reset if failure occurs to start media with yt-dlp

### Builds
+ Updated /Samson-Setup.exe


## 0.8.3 - BETA
- Branch: Samson

### Added
+ Option to EQ import dialog to set as active when imported
+ New separate log for threading related messages (runspaces...etc)
+ Ability to refresh and re-import all Twitch media from Twitch library
+ New "About' option in Main app title bar menu
  + Opens new window with various credits and other info about the app
+ VERY early and limited ability to add and play media from Soundcloud
  + Currently processed using the Youtube modules, no auto importing
  + Can play only using yt-dlp. Must be added using add/open media
  + Will be expanded and supported in future builds
+ Limited ability to download Soundcloud media to local file
+ Partial ability to force use of streamlink to play Youtube Content
  + No UI option exposed to enable as its not recommended to use (yet)
  + Streamlink cant handle restricted videos, and performance is not good
  + Mostly for internal testing to see what else streamlink can do
+ New helper assembly Emoji.Wpf to allow full color vector render of emoji

### Changed
+ Refactored D1 easter egg to use devilutionx vs webview2
  + All files (including license) are now bundled locally with app
+ Reduced WPF resource lookup calls for theme color brushes
+ Libvlc registered events now always unregistered before creating new
+ Consolidated and improved performance logging
  + Added GetMemoryUsage and forceCollection switch to write-ezlogs
+ Various updates and refactors for Spotify profiles and properties
+ Various refactors to reduce overall memory footprint
+ Refactored start-runspace with ability to create restricted runspaces
  + Requires more boilerplate but can notably improve runspace performance
+ Twitch profile images are now cached on first import
+ Improved performance when playing high bandwidth streams using yt-dlp
  + Further improvements needed as still alot of buffering with 4k content
+ Refactored reset media player timer into new Reset-MainPlayer function
+ Now possible to drag child windows even if mouse is over title bar text
+ Additional updates and changes to help documentation in various areas
+ Restyled Show-WebLogin to match standard child window template
+ Improved error handling in various areas
+ Filter dropdown for media libraries now sorted alphabetically 

### Fixed
+ Fixed #118 - Some media incorrectly identified as Spotify on change of track
+ Fixed #117 - Process sometimes hangs and doesnt completely close on exit
+ Fixed #103 - Playback doesnt work when pressing buttons in Image Grid View
+ Some imported EQ presets fail to save due to missing preset_id
+ Some playlists fail to save when containing illegal path characters
+ Some webview2 audio sessions not grouping properly with main app session
+ Fixed #120 - Memory leak when using Profile Editor
  + Actually caused by cleanup runspace failing to dispose completed runspaces
+ Twitch auth can sometimes fail after disabling/re-enabling Twitch integration
+ Images missing or incorrect for media after downloading to local file
+ Incorrect Artist label sometimes applied with taglib for downloaded media
+ Sorting Media library tables by 'Added' column doesn't work
+ Various issues with missing or incorrect icons for floating windows
+ Error occurs when attempting to dispose http listeners during web auth
+ Youtube webplayer sometimes not stopped or disposed on media type change
+ Refreshing Spotify media library fails to actually reimport/refresh
+ Duplicate media items sometimes appear for Youtube media library

### Builds
+ Updated /Samson-Setup.exe


## 0.8.2 - BETA
- Branch: Samson

### Added
+ HTML and SVG Plugins for MarkdownScrollViewer
  + Allows displaying native HTML/SVG within Markdown documents
+ CLI command 'No_SettingsPreload' to disable preload of settings UI on start
+ Ability to import custom/backed up EQ Presets from "Load" preset menu
  + Currently there is no 'Export' ability yet, to be added
  + Warnings provided before overwriting existing 
  + Cannot import presets with the same name as a default fixed preset
+ Ability to toggle whether to start playback when opening/adding media
  + Applies to the Open and Add media dialogs
+ Additional Twitch "AD Block' features: "Use Luminous" or "Use TTVLOL" Proxy
  + Potentially more effective at blocking ADs entirely. Read help docs
+ Advanced Setting: "Streamlink Logging Level" to control how verbose log is
  + Read help doc, should normally never be changed

### Changed
+ Large overhaul and refactor for Youtube import and profile generation
  + Greatly improved import performance by avg 50 - 60%  
  + Greatly reduced API calls by batching ID's to single lookups
  + Improved memory overhead by switching Invoke-ResetMethod to .Net calls
  + Greatly reduced total Youtube profile size and stored properties
  + Profiles structure now more uniform to others, reduced nesting
  + Fixed various issues preventing some YT videos from importing
  + Deleted, Hidden or otherwise unavailable videos no longer imported
+ Updated Main App icon with new custom designed by Woody
  + May need some tweaks or potential spots the old one still shows
  + Discord still uses old icon, need to upload new one to Discord dev console
+ Updated Webview2 assemblies to 1.0.1549 pre-release
  + Includes some helpful fixes and much better memory management
  + Implemented new property MemoryUsageTargetLevel to keep memory usage low
  + Disabled auto error report sending to Microsoft
+ Various other resource management and memory overhead improvements  
+ Relocated easter egg button to findable but not super obvious location
- Removed and disabled Tiny Desk and Beer easter eggs
  + Not enough time to finish, will hopefully return in the future
+ Improved error handling and logging in various areas
+ Optimized Filter/sorting, all library tables now use Invoke-MediaFilters
  + Filtering/sorting now honors BOTH filtertextbox and filter dropdown
+ Converted/updated/Added more help documentation for various settings
  + Youtube mostly done, partial for others
+ Improved app responsiveness when clicking Authentication for first time
  + UI no longer freezes and now displays progress ring
  + Still need to implement this for Twitch
+ Renamed Import Enable toggles to 'Enable X Integration'
+ STOP now executed if start playback aborts due to Twitch stream being offline
+ Reduced some extra/bloated logging in various areas
+ Runspaces now only pass provided functions vs always passing all in scope
+ Further improvements to resource cleanup and logging on app exit

### Fixed
+ Audio session icon and text sometimes missing or incorrect
+ Fixed #116 - Cassette color and tape wheels dont look right
+ Fixed #114 - Tray Icon lingers after app close
+ Install checks still occur for Spotify client even when not enabled
+ Fixed #113 - Floating Video Content hidden when closing Video View
+ Fixed #112 - First Run Window Closes Unexpectedly
+ Fixed #109 - Duration format different/incorrect between Libraries
+ Fixed #107 - Volume dont work so well
  + Unable to reproduce issue, all latest logs show no issues
+ Hell easter egg window orphaned from main app group
+ Check for update fails if running newer version than latest update build
+ Monitor sometimes fails to load when no theme has been selected
+ Various issues where filtering stopped working for library tables
+ Vault secrets fail to remove when uninstalling or refreshing authentication
+ Fixed #92 - Manually Adding Spotify URL adds blank line
  + Never able to replicate, may have been fixed as result of previous fixes 
+ Playback of Spotify media sometimes fails due to typo in logging 
+ STOP sometimes partially fails when trying to update Spotify_WebPlayer_State 
+ App sometimes freezes when changing color theme

### Builds
+ Updated /Samson-Setup.exe

## 0.8.1 - BETA
- Branch: Samson

### Milestone - BETA
+ Changed app name from EZT-MediaPlayer to Samson (so far nothing broke!)
+ Name change marks new branch and new milestone. Now officially in BETA!
+ Its more for internal tracking, still a TON to do before and after release

### Added
+ First iteration of new Recording Dialog and logic for Record Button
  + Only displays a notification for now as a placeholder
  + Eventually will present options for recording and source to select
+ First iteration of Optimization Tools and logic
  + Untested as of yet. Provides confirmation and warning when used
  + Added MD help files to explain options
  + Optimize Assemblies works, Optimize Services doesnt do anything yet
+ Added TasbarItemInfo buttons to MiniPlayer Window
  + Play button now updates according to play status (PLAY/PAUSE)
+ Licence file for D1 easter egg - Not fully yet integrated yet

### Changed
+ All child windows now grouped with main app (and not with powershell)
+ Removed remaining calls to measure-command and replaced with stopwatch
+ Further optimizations to reduce memory overhead and improve performance
  + Reduced after memory usable on cached start by 70MB
  + Improved avg startup time by around 1s
+ Newly spawned webbrowser 'Tabs' are now properly disposed when closing
+ Converted more help topics to new Markdown system (a ton to go)

### Fixed
+ Get-AudioSessions sometimes merges incorrect sessions into Main GroupingParam
+ Fixed #105 - Controls Overlay Missing when playing Spotify Web Player
+ Spectrum Analyzer may fail to load if no color theme is selected
+ Logging into google via webbrowser can cause login page to loop indefinitely
+ Regression: Feedback window fails to load if no color theme is selected
+ Right Speaker fails to load after previous builds runspace optimizations
+ Binding errors when VS debugging for GridViewColumn width of Media libraries
+ Uninstaller can get caught in a loop, unable to complete

### Builds
+ Updated /Samson-Setup.exe


## 0.8.0 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Ability to pass more startup arguments via main exe file
  + Allows playback on startup, start as mini, no tray and others
+ New Module: EZT-AudioManager - for hooking into Windows Audio via cscore
+ WindowsAPICodecPack Assembly - Using for TaskbarManager
+ Option to start playback or not when adding/opening new local media
+ Ability to Remember Window Positions on startup
  + New option in main window title menu - Remember Window Positions
  + Applies to Splash Screen and Main Window
+ New Add-JumpList function for for Add-TrayMenu module
  + (FUTURE) To be eventually be used to create taskbar icon jumplists
+ Twitch Option: Mute Twitch Ads
  + Toggle ability to mute player while ads are being skipped (if skip ADs on)
  + Read the help, not guaranteed to work everytime due to how ADs are skipped
+ Advanced Media Player Options added to General Settings tab
  + Audio Output module: Selects output method used by libvlc. Defaults to Auto
  + VLC Commandline: Can add comma-seperated list of cli options to pass to vlc
  + Optimization Tools: Doesnt do anything yet
+ Advanced Twitch Option: Ability to pass custom arguments to Streamlink 

### Changed
+ Removed calls to measure-command. Need to remember never to use this! 
  + As expected, improves startup performance by almost 2s
+ Various other performance optimizations to shave a few ms from startup 
+ Main Window and all child windows now 'Separated' from root PS process
  + Basically means app wont show as running from Powershell anymore in taskbar
+ Potential improvements for Webplayers to start when not visible
  + Relates to issue where webplayers wont start if you dont open video view
  + Webview2 doesnt fully initialize in WPF until content is rendered
  + This 'hack' will try to select the video tab and updatelayout() to trigger
+ Refactored Main App Shutdown and resource disposal on exit
  + Fixes some things and now releases resources better to prevent process hang
+ Various libvlc adjustments to caching buffers to improve live stream stutter
+ First iteration and refactor of profile optimizations to reduce to final size
  + Reduced local media size by 3mb for 3300 items
  + Reduced memory overhead when processing profiles
  + Will start on Spotify/Youtube next build likely
+ Refactored and streamlined libvlc creation when passing arguments
+ First iteration of help documentation system with MarkdownScrollViewer
  + Some (few) help flyouts have been updated to use new system
  + New help lives in .MD markdown files that are read and displayed onclick
- Removed unused and old function Get-AppIcon and some other resources

### Fixed
+ Multiple Audio Sessions for app and sub-processes in Volume Mixer
  + This also potentially related to Audio Conflict issue Woody reported
+ Feedback and Check for Update Window fail to load when no theme is set
+ Potential fixes for # 107 - Issues with volume
  + Requires additional testing with various Audio Output Modules
+ Potential Twitch stream crash when skipping ads due to buffer running dry
+ Various issues caused by MS's own terrible Get-StartApps module
  + Recreated and included as Get-AllStartApps helper function 
+ Partial: Duration formats different between libraries - Spotify
  + Not applied to all libraries yet, just Spotify. Others to follow
+ Twitch token refresh can fail due to incorrect expire date string comparison
+ EQ may fail to initialize/apply in some cases (potential)
  + A bit of a blind fix, as unable to reproduce the issue on all test machines
+ Media timer doesnt restart/continue when enabling 2PASS
+ Fixed #108 - Speakers Render Offscreen When Video View is Open
+ Fixed #110 - Add to New Playlist fails to add media from existing playlist
+ Volume becomes muted or changes unexpectedly when Webplayer media starts
+ Unable to type (but could delete) text in Profile Editor fields

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.9 - Samson-Alpha
- Branch: Samson-Alpha

### Added


### Changed
+ Last played item in queue is now always removed when starting new media
  + Before would stay if media not played till the end, keeps queue clean
+ Set libvlc user agent name to app name
+ Replaced Invoke-RestMethod with HTTPWebRequest for Twitch/Youtube requests
  + Improves memory overhead and non-cached lookup performance
+ Additional improvements and tweaks to Libvlc and EQ management
  + Further reduced/eliminated audio volume jumps to 0 after starting media
  + Explicitly set libvlc output module to ensure it uses mmdevice
+ Improved error handling and user notification on Spotify playback errors
  + Notification should now display if Premium Spotify account required
+ Refactor and enhancements to Webbrowser Webview2
  + WIP: ability to open new windows as new dockable tabs in dockmanager
  + Webview doesnt have native tab ability, so this is custom and very WIP 
+ Greatly improved performance of sorting for Media Library tables
  + Also fixes 'double refresh' on sort issue
  + Current filter text should now be honored when sorting
+ Small update,improvements and fixes when enabling Spicetify 
  + Bulk of refactor will most likely happen post beta release
+ Improved rendering of media images and reduced size of stamped overlay icons
+ Improved wpf virtualization for media library table views
+ Refactored Feedback form, updated to new child window style
  + Progress indicator displays while submitting but no longer locks UI 

### Fixed
+ SystemMedia Overlay Status doesn't update with media state (play/pause)
+ Fixed #63 - System Media Transport Controls, buttons/commands dont work
  + FINALLY! Overlay buttons/keyboard media keys should work more than once 
+ Fixed #91 - Spectrum Analyzer not updating on theme color change
+ Fixed #100 - Youtube Default Download Path not saving
+ Process can hang or cause error when app is closed
+ Enumeration error occurs when building/updating Play Queue
+ Type error sometimes occurs on startup in Import-Spotify
+ EQ Preamp sometimes not unset from libvlc instance when disabled
+ Fixed #101 - Volume jumping when playing Youtube videos
+ Audio is sometimes muted or dropped to 0 when pausing/unpausing
+ Media library tables remain enabled after disabling in Settings
+ Fixed #104 - Video Auto Opens when floating
+ Fixed #81 - Feedback Form Issues, freezes on submit
+ Video control overlay doesnt appear when video viewer is undocked
+ Collection fixed size error when removing Local Media Item

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

## 0.7.8 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ New Helper function: Get-MemoryUsage for performance logging
  + Allows more accurate reporting of actual working set memory
  + Includes parameter to force full gc collection
+ Ability to choose preferred Twitch stream quality
  + The default is 'Best', does not apply when 'Use YTDLP' is enabled
+ New Play and Stop TasbarItemInfo thumb buttons and status
  + Allows controlling player from taskbar thumbnail. Play/Stop only for now
  + Taskbar icon shows current progress as bound to progress slider

### Changed
+ Minor adjustments to column auto sizing for Media library
+ Find-FilesFast can now accept file paths vs just directories
+ Images and webview2 temp folders now removed on first run setup
+ Improved youtube fallback process to make it appear embedded
+ Lowered tolerance for ScrollOnDragDrop to make it less annoying when dragging
+ Added Advanced options in settings for Twitch and Spotify (WIP)
+ First (of many) optimization passes to improve performance and memory usage
  + Splash and profile editor application threads now always disposed on unload
  + Added helper function Clear-WorkingMemory to reset app memory working size
  + Changed DynamicResoure to StaticResource for various wpf styles
  + Replaced += operator with arraylist for local media collection building
  + Handlers are now first removed before adding to prevent duplicates
  + Improved responsiveness when pressing stop button
  + Enabled VirtualizingPanel and CanContentScroll for contextmenus
  + Changed various loops to use pipe-lining to reduce memory overhead
  + Various GeometryDrawing icons now cached once vs recreated on each pass
  + Removed some uneeded dispatcher.invoke calls during startup
  + Calling TrySuspendAsync() in various places to reduce webview2 memory usage
  + Reduced image decoding from 500px to 300 in some areas
  + Replaced Set-content with BinaryWriter when caching images from taglib
+ Other various changes to log output, comment cleanup and code consolidation

### Fixed
+ Images not displaying when playing Twitch Media even if available
+ Notification flyout is unreadable if viewing webbrowser dockable tab
+ Changing color theme sometimes freezes main UI thread
+ Fixed # 73 - Playlists dont update when moving tracks with drag/drop
+ Fixed # 99 - Removing Youtube Media from Library
+ Fixed # 100 - Youtube Default Download Path not saving
+ Fixed # 99 - Removing Youtube media doesn't update dropdown and table
+ Fixed # 66 - Error Removing Local Media item
+ Fixed # 102 -Audio never returns after unmuting playback when using Invidious
+ Spotify library not filtering by artist or album
+ Find on Youtube option doesnt use web browser to load search query
+ Temp files sometimes included in media scans if name also has media ext
+ Youtube webplayer fullscreen issues when playing Youtube TV content
+ Title and icon for some floating windows missing when undocked
+ Media library tab not removed when disabling its import option in settings
+ Volume jumps to 0 or is delayed to update on playback start
  + This is a potential fix, requires testing to confirm

### Issues
+ Floating window icons and other colors dont update with theme until restart

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe


## 0.7.7 - Samson-Alpha
- Branch: Samson-Alpha

### Added
+ Ability to refresh/rescan all local media from library
+ Ability to Save/Remember Window Positions for next startup
  + New title bar menu option 'Remember Window Positions'
  + Remembers position and monitor for Main Window and Splash Window
  + On first run, Splash window is remembered for app restarts during setup
+ Ability to open video player from Mini-player or tray contextmenu
+ Default image for Youtube media with no valid artwork found
+ Total media count added for Local media table in settings tab
+ Ability to display markdown content for Settings help flyouts
  + Prep for help refactor
+ Filter text now auto highlights as matching characters are typed

### Changed
+ Refactored fallback logic for YT videos that fail to play with webplayer
  + Videos now fallback to using non-embed, then invidious after that
  + JS injection sets Fullscreen on player load, captures fullscreen clicks
  + Added/updated ad block JS to block or skip YT Ads that occur with nonembed
  + Good results in early testing, more testing needed to confirm
+ Refactor pass for Local Media library startup, filters and refresh
+ Reduced dispatcher invoke calls when starting media. Reduces UI stutter
+ Update-MainWindow now uses concurrentQueue to avoid race conditions 
+ Refactored FloatFullScreen_command, consolidated into Set-VideoPlayer
+ Improvements to error handling and optimizations for Get-Twitch
+ Various updates, changes and cleanup of log messages
- Removed App exe textbox under Start On Windows Logon setting
- Removed Startup Audio option in settings (may return later)
+ Reduced extra long UI freeze when enabling Import Spotify for the first time
  + Offloaded Secret Vault setup and other operations to new runspace
  + Will likely need to do the same for Youtube/Twitch
- Removed error/info messages from appearing at bottom of Settings UI 
+ Settings and logon capture UI adjustments for smaller resolutions
- Removed Tiny Desk button for now
+ Updated Public changelog link for Inno installer

### Fixed
+ Excessive ram usage during setup or first time caching of media images
  + Taglib and image IO streams not disposed after usage
+ Fixed # 96 - Playlist/Profiles errors after exporting and importing from xml
+ Fixed # 97 - Issues when sorting columns in Media Libraries
+ Fixed # 91 - Spectrum Analyzer not updating on theme color change
+ Streamlink and some vault secrets not removed during uninstall process
+ Log file write conflicts can occur during first run setup
+ Some Youtube URl formats not identified and processed correctly
+ Spotify auth status sometimes shows as valid even when none are available
+ Changes when updating media with Profile Editor are lost on next app start
+ Streamlink log monitor doesnt end properly when streamlink process ends
+ Get-LogWriter sometimes gets stuck in restart loop
+ Title missing from Media Library and Web Browser when floating
+ Floating windows move behind main UI when dragging over

### Builds
+ Updated /EZT-MediaPlayer-Setup.exe

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