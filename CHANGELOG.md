# Changelog

## Unreleased

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