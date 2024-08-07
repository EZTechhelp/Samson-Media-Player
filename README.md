<h1 align="center">Samson Media Player</h1>
<p align="center">
  <img Height="200" src="/Images/Samson_Logo_Splash.png" />
  <img src="/Images/Example_Image.png" Alt="Example, subject to change"/>
</p>

## Synopsis <a name="Synopsis"></a>

Samson Media Player is a universal media player built in PowerShell that allows you to play and manage all of your local or internet based media within a single app. Import playlists and media from Spotify, YouTube, Twitch and more. 

The screenshot above is from a personalized and custom version made as a fun gift for a friend and his cat Samson, hence the name.

# Table of Contents
1. [Synopsis](#synopsis-)
2. [Project Status](#project-status-)
3. [Current Features](#current-features-)
    - [Spotify](#spotify--)
    - [Youtube](#youtube--)
    - [Twitch](#twitch--)
    - [Local Media](#local-media--)
    - [Media Library/Playlists/Queue](#media-libraryplaylistsqueue-)
    - [Mini-Player](#mini-player-)
    - [Discord](#discord-)
4. [Other Features, Notes and Requirements](#other-features-notes-and-requirements-)
5. [Modules, Libraries and Credits](#modules-libraries-and-credits-)
6. [Available Versions](#available-versions-)
    - [Prepackaged/Installer](#prepackagedinstaller)
    - [PowerShell/Source Files](#powershellsource-files)
7. [Installation and Configuration](#installation-and-configuration-)
    1. [Choose/Download Available Version](#1-choosedownload-available-version)
    2. [API Setup and Configuration (Optional)](#2-api-setup-and-configuration-optional)
    3. [Run First Time Setup](#3-run-first-time-setup)
8. [CLI Options](#cli-options-)
9. [Uninstalling](#uninstalling-)
10. [Manually Building Source Files](#manually-building-source-files-)

## Project Status <a name="Project_Status"></a>

This app is still under development and undergoing testing to address issues, so expect some rough edges. However, the app is ready for community testing and feedback to help identify remaining issues.

If you wish to help, see **[TESTERS](/TESTERS.MD)** for more information. Testers will get access to special private builds with extra features to make submitting feedback easier.

<a name="Why_PowerShell">**Why PowerShell?**</a>

This project has been both educational and enjoyable, allowing me to explore the capabilities of PowerShell for complex development. The core functionality and a significant portion of the app are built entirely in PowerShell. While using other common languages would be more practical, this showcases PowerShells potential for unconventional yet powerful applications.

For a code line count and language breakdown, see [Latest Code Count](/CODECOUNT.txt)

## Current Features <a name="Current_Features"></a>

### Spotify <a name="Spotify"></a> <img src="/Resources/Spotify/Material-Spotify.ico" Height="25" Width="25" align="Left" Alt="Ability to import and play Spotify playlists and tracks from valid Spotify Account"/>

<img src="/Images/Spotify.png" Alt="Ability to import and play Spotify playlists and tracks from valid Spotify Account. Playback with Web-Player and audio monitor enabled pictured."/>

- Play Spotify playlists and tracks from a valid Spotify Account
- Premium and free accounts supported (Free accounts require Spotify Windows client)
- Auto-sync Spotify playlists and playlist tracks to the apps media library
- Record Spotify media to local disk. Currently saves as FLAC, further customization options planned. (Basic/WIP)
- Supports EQ and audio filters (requires enabling EQ support for Web Players)

### Youtube <a name="Youtube"></a> <img src="/Resources/Youtube/Material-Youtube.png" Height="25" Width="25" align="Left" Alt="Ability to import and play YouTube playlists and videos"/>

<img src="/Images/Youtube.png" Alt="Ability to import and play YouTube playlists and videos. Web-Player with comments enabled pictured"/>

- Import and play YouTube playlists and videos from a valid YouTube account
- Auto-sync YouTube playlists and playlist videos to the apps media library
- Select preferred quality options, download YouTube videos to local disk (via YT-DLP) and more
- Alternate YouTube Web Player option using Invidious
- Supports playing YoutubeTV channels (currently channels must be added manually)
- Supports Youtube comments and live YouTube streams with chat integration (with built-in support for [BetterTTV](https://github.com/night/betterttv))
- Built-in support for [SponsorBlock](https://github.com/ajayyy/SponsorBlock), with configurable options to skip or mute sponsored segments
- Supports EQ and audio filters when using Web Player

### Twitch <a name="Twitch"></a> <img src="/Resources/Twitch/Material-Twitch.png" Height="25" Width="25" align="Left" Alt="Ability to import and play Twitch live streams with chat integration"/>

<img src="/Images/Twitch.png" Alt="Supports Twitch live streams with chat integration"/>

- Play Twitch live streams with native chat integration
- Import all followed/subscribed channels with valid Twitch account
- Auto-update/refresh followed streams and their status
- Display notifications for configured channels when they go live
- Multiple Twitch AD blocking solutions supported, including [TTVLOL](https://github.com/TTV-LOL/extensions) and [luminous](https://github.com/AlyoshaVasilieva/luminous-ttv)
  - Can provide custom list of proxy servers that support TTVLOL and luminous
- [BetterTTV](https://github.com/night/betterttv) support included for enhanced chat viewer
- Uses [StreamLink](https://github.com/streamlink/streamlink) by default for getting playback streams, with ability to specify preferred quality
  
### Local Media <a name="Local_Media"></a> <img src="/Resources/VLC/Material-Vlc.png" Height="25" Width="25" align="Left" Alt="Supports Twitch live streams with chat integration"/>

- Add directory paths to scan and import all supported media into the apps media library
- Supports most media file types or URLs that VLC player proper supports
- Supports UNC/Network Mapped drives, external storage..etc
- Scan media file IDTags (via [TagLib](https://github.com/mono/taglib-sharp)) to populate library with metadata
  - Configurable scanning modes for 'Fast' import or 'Slow' to assist scanning storage devices that have slow read/write speeds (such as older external USB drives)
  - Option to skip import/scan of duplicates
- Real-time file monitoring of provided directories. Automatically add, remove or update media files as they are changed in the file system when app is running

### Media Library/Playlists/Queue <a name="Media_Library_Playlists_Queue"></a>
<img src="/Images/Media_Library.png" Alt="Media library with dock-able/tabbed UI supporting advanced filtering and multi-level grouping"/>

- Media library data-grids in a dock-able/tabbed UI (powered by AvalonDock) supporting advanced filtering, search and multi-level grouping
- Create custom playlists, combining media from any supported platform
- Playlists can be exported or imported for sharing or backup
- Add media via Drag-n-Drop of media files or URL links directly into app or for moving from library to playlists
  - Drag-n-drop also supported when moving items between playlists or re-ordering within existing
- Start playback directly from playlists, library or add to the playback queue
- Supports auto-play, playback history tracking, shuffle, repeat and other playback options

### Mini-Player <a name="Mini-Player"></a>
<img src="/Images/MiniPlayer.png" Alt="Includes a 'Mini-Player' opened from tray icon/menu. Small skinned UI with only basic playback controls"/>

- A small skinned UI with playback controls and shortcuts to various settings/features
- Can open quickly from system tray icon/menu, switch back and forth with main player skin or set to always start in mini-player mode

### Discord <a name="Discord"></a>

<img src="/Images/Discord_Integration.png" Alt="Discord Rich Presence integration to display media playback info in your Discord status/profile"/>

- Discord Rich Presence integration to display media playback info in your Discord status/profile
- Supports clickable label links when playing Spotify, YouTube and Twitch media 
  
### Other Features, Notes and Requirements <a name="CoreOther"></a>

See **[FEATURES](/FEATURES.MD)** for a more exhaustive list of core features and important requirements

### Modules, Libraries and Credits <a name="Modules_Libraries_and_Credits"></a>

See **[CREDITS](/CREDITS.MD)** for a quick list of the various, external apps, components, modules or libraries used in this project as well as endorsement for each

* * * 

## Available Versions <a name="Available_Versions"></a>

#### <a name="PrepackagedInstaller">**Prepackaged/Installer**</a>

+ **(NOT YET AVAILABLE TO PUBLIC - SOON™)** Available builds will be listed under `Releases` or shared directly/privately to QA Testers
+ Prepackaged installer using Inno setup. Will be the primary and recommended version for regular usage
+ **NOTE**: Using the prepackaged installer is not required, but highly recommended. It is used to provide a convenient way to package, deliver and configure.
+ The installer also performs optimizations to improve app performance, such as installing assembles to the GAC and creating native images via [ngen](https://learn.microsoft.com/en-us/dotnet/framework/tools/ngen-exe-native-image-generator)
+ Using the installer also registers Samson as a 'proper' application which provides a few benefits. For example:
	+ GUI windows will appear in the task bar as its own application/icon. Otherwise all windows would just show as PowerShell.
	+ Samson will be listed in Add/Remove programs and can be uninstalled
	+ Taskbar features such as jump-lists are only available with the installed version

#### <a name="PowershellSource_Files">**Powershell/Source Files**</a>

+ PowerShell source files only version, main script to launch is **Samson.ps1**
+ Source code is available via this repository or from installer once run and you choose an install folder
+ Manually download and extract the files to desired location, then execute the main script `Samson.ps1` within the root folder
  + Alternatively, even without using the installed version, you can use `Samson.exe` in the root folder to launch the application
  + `Samson.exe` is just a simple self-executable launcher built in C#. Source code included under `src\launcher` if you wish to build or inspect yourself
  + `Samson.exe` allows the ability to enable some settings such as `Start on Windows Login` which will not work if the exe is missing
* * * 

## Installation and Configuration <a name="Installation_and_Configuration"></a>

### 1. Choose/Download Available Version
  + If using installer, just run through install wizard, choosing location to install. Let it finish but do not launch yet
  + If downloading source files, extract/copy to desired location

### 2. API Setup and Configuration (Optional)<a name="API_Setup_and_Configuration_Optional"></a>

+ Spotify, YouTube and Twitch features require additional setup for their respective API's.
+ See **[API Setup and Configuration](/Resources/Docs/Setup/API_Authentication_Setup.md)** for set-by-step instructions on how to setup your own API accounts for these services, which are free.
+ I really wanted to make this more seamless by including my own development APIs but there is just no way to do that securely

### 3. Run First Time Setup
  + If using installer, run Samson from shortcut created or via `Samson.exe` in the install folder
  + If you downloaded source files, execute `Samson.ps1` in the root folder from PowerShell (non-admin)
  + Upon running for the first time, the First Run Setup/Settings window will appear. Go through and configure as desired
  + Highly recommend reading the help documentation for each setting, by clicking on the **?** icon next to each
  + After finishing setup, the app may restart. If it closes but doesn't restart on its own, wait a minute or so then just relaunch
* * * 

## Uninstalling <a name="Uninstalling"></a>
+ Uninstall is triggered by passing `-Uninstall` to `Samson.exe` or `Samson.ps1`. It is also triggered when uninstalling the package from windows or via the Inno Setup `unins000.exe`
	+ The uninstaller performs the removal of any installed external components (StreamLink, Chocolatey..etc), removes related files (including temp files) and removes any stored secrets from secure vault
	+ The uninstaller will prompt the user to decide if they also wish to remove user related data, such as media profiles, custom playlists, settings..etc
	+ Log files are NOT removed by the uninstaller
* * * 

## CLI Options <a name="CLI_Options"></a>

See **[CLI Options](/Resources/Docs/Setup/CLI_Options.md)** for available CLI parameters and other advanced options

## Manually Building Source Files <a name="Building_Installer_Launcher"></a>

See **[BUILDING](/BUILDING.MD)** for more information on manually compiling core assemblies and helper components
