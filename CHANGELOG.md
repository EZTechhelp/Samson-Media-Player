# Changelog

## Unreleased

## 0.4.0 - Pre-Alpha

### Added
+ Microsoft SecretManagement and SecretStore to required modules to install
+ WebView2 option '--autoplay-policy=no-user-gesture-required' for auto-play
+ First iteration of framework for using Spotify Web Playback SDK
  + Will allow full integrated control without needing Spotify client installed
  + Will enhance and replace current Spotiy Web Player implementation
+ Progress ring displays while Import-Spotify is processing
+ Refresh_All_Media parameter for Get-LocalMedia and Import-Media

### Changed
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