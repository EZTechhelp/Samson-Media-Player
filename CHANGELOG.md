# Changelog

## Unreleased

## Version: 0.4.7.1
- Branch: Pre-Alpha

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