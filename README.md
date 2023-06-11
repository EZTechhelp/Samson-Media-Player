# EZT-MediaPlayer

## IMPORTANT

The full repository and most current source code is currently private as it is not yet ready for public consumption. I am looking for any and all willing testers or those who are interested in contributing to the project. Please contact me here (github) or via email: mdodge@eztechhelp.com if you are interested. Testers and contributors will of course have full access to the latest source code

**DISCLAIMER**

This app is still heavily WIP in relation to any kind of public build. The current build (and example screenshot) is from a very personalized and custom version made in dedication for a very dear friend and his cat Samson

## Synopsis <a name="Synopsis"></a>

EZT-MediaPlayer is a universal media player built in PowerShell that consolidates playback and management of media from multiple sources such as local disk, Spotify, YouTube, Twitch and more. Powered by LibVLCSharp

**Why Powershell?** <a name="Why_Powershell"></a>

Because why not! Ok maybe there are alot of good reasons. This has been a very educational project and also has personal meaning. While yes using a 'proper' programming language would be much better and easier, its fun and interesting to see just how much you really can do with Powershell. Technically there are alot of helpers and other components built in other languages, but the primary core and majority of the app is Powershell

<p align="center">
  <img Height="200" src="/Images/Samson_Logo_Splash.png" />
  <img src="/Images/Example_Image.png" Alt="Example, subject to change"/>
</p>

# Table of Contents
1. [Synopsis](#synopsis-)
2. [Current Features](#current-features-)
    - [Discord](#discord-)
    - [Mini-Player](#mini-player-)
    - [Spotify](#spotify--)
    - [Youtube](#youtube--)
    - [Twitch](#twitch--)
    - [Local Media](#local-media--)
    - [Media Library/Playlists/Queue](#media-libraryplaylistsqueue-)
    - [Core/Other](#coreother-)
3. [Important Notes/Requirements](#important-notesrequirements-)
4. [Primary Modules/Components](#primary-modulescomponents-)
5. [Available Versions](#available-versions-)
    - [Installer/EXE](#available-versions-)
    - [Powershell Script](#available-versions-)
6. [Installation and Configuration](#installation-and-configuration-)
    - [Powershell Configuration](#powershell-configuration-)
    - [Building Installer/Launcher](#building-installerlauncher-)

## Current Features <a name="Current_Features"></a>

### Discord <a name="Discord"></a>

<img src="/Images/Discord_Integration.png" Alt="Discord Rich Presense integration to display media playback info in your Discord status/profile"/>

- Discord Rich Presense integration to display media playback info in your Discord status/profile
- Supports clickable label links for Spotify, Youtube and Twitch media 

### Mini-Player <a name="Mini-Player"></a>
<img src="/Images/MiniPlayer.png" Alt="Includes a 'Mini-Player' opened from tray icon/menu. Small skinned UI with only basic playback controls"/>

- Includes a 'Mini-Player' opened from tray icon/menu. Small skinned UI with basic playback controls
- Tray icon and menu with playback and shortcuts to various settings/features

### Spotify <a name="Spotify"></a> <img src="/Resources/Material-Spotify.png" Alt="Ability to import and play Spotify playlists and tracks from valid Spotify Account"/>

- Ability to import and play Spotify playlists and tracks from valid Spotify Account
  - Premium and free accounts(WIP) supported, though playback with free accounts requires having the local Spotify client installed
- Ability to record Spotify media to local disk. Currently saves as flac, futher customization options planned
- (WIP) Ability to use apps native EQ and audio filters for Spotify playback

### Youtube <a name="Youtube"></a> <img src="/Resources/Material-Youtube.png" Alt="Ability to import and play YouTube playlists and videos"/>

- Ability to import and play YouTube playlists and videos
  - Playlists from Youtube account can be imported automatically when providing credentials
- Ability to auto-sync Youtube playlists and playlist videos with the apps media library
- Preferred Quality option so videos always play or download at the specified quality
- Ability to download Youtube videos to local disk (via yt-dlp)
- Alternate Youtube player options such as using Invidious for the Web Player vs the native Youtube embedded player
- Supports playing YoutubeTV channels (currently channels must be added manually)
- (WIP) Ability to use apps native EQ and audio filters for Youtube playback

### Twitch <a name="Twitch"></a> <img src="/Resources/Material-Twitch.png" Alt="Ability to import and play Twitch live streams with chat integration"/>
<img src="/Images/Twitch.png" Alt="Supports Twitch live streams with chat integration"/>

- Ability to import and play Twitch live streams with chat integration
  - Ability to import all followed/subscribed channels when providing Twitch account 
  - Includes option to enable auto-update/refresh followed streams and their status
  - (SOON) Ability to display notifications for configured channels when they go live
  - Multiple Twitch AD blocking solutions supported, including [TTVLOL](https://github.com/TTV-LOL/extensions) and [luminous](https://github.com/AlyoshaVasilieva/luminous-ttv)
  - [BetterTTV](https://github.com/night/betterttv) supported for enhancing in-app chat viewer
  
### Local Media <a name="Local_Media"></a> <img src="/Resources/Material-Vlc.png" Alt="Supports Twitch live streams with chat integration"/>

- Add directory paths to scan and import supported media into apps media library
  - Most all common (and some uncommon) audio and video formats supported. (WIP, more likely to be added)
  - Supports UNC/Network Mapped drives, external storage..etc  
- Scans media file IDTags (via Taglib) to populate library with metatdata
  - Customizable scanning modes such as 'Fast' to import as fast as possible or 'Slow' to assist scanning drives with poor IO performance (old external USB drives..etc)
  - Option to skip import/scan of duplicates
- (WIP/Untested) Supports any media file/type or URL that VLC player supports

### Media Library/Playlists/Queue <a name="Media_Library_Playlists_Queue"></a>
<img src="/Images/Media_Library.png" Alt="Media library with dockable/tabbed UI supporting advanced filtering and multi-level grouping"/>

- Media library with dockable/tabbed UI (powered by AvalonDock) supporting advanced filtering and multi-level grouping
- Add media using Drag-n-Drop of media files or URL links directly into app or from library to playlists
  - Drag-n-drop also supported when moving items between lists and re-ordering
- Create custom playlists, combining media from any supported platform
- Playlists can be exported/imported for sharing or backup
- Playback Queue and history, with shuffle, next, prev playback options  
  
### Core/Other <a name="CoreOther"></a>

- Limited (very basic/WIP) support for adding and playing of SoundCloud media
- (WIP) Media Casting Support - casting media during playback to other UPnP/DLNA supported devices
- (WIP) In-app and configurable auto-update system with check only or auto install options
- Real-time graphical spectrum analyzer powered by cscore
- Basic audio visualizations support. Includes vlc plugins for Goom and Spectrum
- In-app or full-screen pop-out video player, with option to enable/disable Hardware Acceleration
- Utilizes Webview2 for various features such as Web Players for Spotify and Youtube playback
  - Also includes a basic in-app web browser wth built-in ad blocker for browsing Youtube.com
  - Can browse youtube and add videos directly into the apps library or download to local file via right-click on youtube videos
- Media Library grids use data and UI virtualization to handle lists with hundreds of thousands of items
- Uses PowerShell RunSpaces (multi-threading and job handling) for improved performance and responsive WPF UI
- Supports SystemMediaTransportControl integration for Play, Pause, Stop, Next, Volume..etc
- 10-Band EQ control with ability to save custom presets or use existing defaults
  - Additional audio filters (and video filters) planned 
- Supports displaying Toast notifications on media playback
- Supports starting app automatically on Windows startup/login, minmize to tray, start minimized and other UI options
- Extensive verbose logging support, for troubleshooting and development.
- Built-in snapshot feature to take screenshots of videos and of the app itself (if so inclined)
- Advanced media player options including Audio Output Device selection, Audio Output module selection (mmdevice/directsound..etc) and more (WIP)
- Remember Playback Progress option - Saves progress of the current playing media when the app is closed. On next start, it will begin playback at the saved progress time
- (WIP) Ability to pass custom VLC command-line options to the libvlc instances (some limits apply)
- Other things TBD

## Important Notes/Requirements <a name="Important_Notes_Requirements"></a>

- The app by **default runs under user context**, but requires running as admin in some cases (such as first time setup)
- **Spotify** windows client is required to be installed for free Spotify accounts. 
  - Spotify can be automatically installed if not already. 
  - Spotify playback for free accounts uses a customized version of **Spicetify/PODE Server** (WIP)
  - Premium accounts can use the built-in Spotify Web Player without needing the client app installed (Recommended/Default)	
-  **Spotify accounts must be manually added** to the API approved list for now in order to use Spotify features. 
  - Spotify has a 25 account limit for in-development API usage. Will need your email address for Spotify. Once added you can enable Spotify features	
- **Streamlink** used for (potentially) Ad-free Twitch Streaming/Playback (installed automatically)
- **Powershell Modules** needed are included vs installed from the PS gallery. Some have been slighted modified 
- If running under Administrator context, and local media is located on a mapped drive (network/nas..etc) **EnableLinkedConnections** registry setting can be set to allow accessing mapped drives in Windows 
  - This is not applied by default but the code is there for checking and applying the setting, just disabled. Recommend doing manually if you need it. An option to enable it for you is planned
  - If app is running as admin and an added network path is unavailable, a warning will be displayed with an option to restart under user context
- The default **logging verbosity** is high for development reasons, which will cause the log files to grow in size quickly, so heads up.
  - The log files are located at `%appdata%\roaming\EZT-MediaPlayer\Logs`
  - Basic computer info such as name, make, model, cpu, ram, Windows version..etc is included in the log file
  - Log file may also contain details of media you provide, names of playlists, songs..etc. 
  - If you are concerned about what info you share, recommend reviewing the log files and scrubbing anything before sharing for support/testing. 
  - The app has a Feedback/Issue submission form (from title bar dropdown menu) where feedback and issues can be submitted with option to include latest logs	
- All web API calls are sent encrypted (https) and subject to privacy terms of the services (in this case Spotify, Youtube and Twitch). 
  - The only data I can see is the public IP address where API calls where made from, when and how many requests made. Not content
  - Spotify, Twitch and Youtube creds are captured using their respective Oauth web auth pages (displayed in-app via webview2).  
    - All credentials and sensitive data (Oauth tokens..etc) are encrypted using .NET crypto APIs and stored locally only via the **Microsoft SecretStore Vault**
- By default, Playlist and Media profiles are stored in `%appdata%\roaming\EZT-MediaPlayer`
  - **Temp files for Webview2 controls** (cookies..etc) and any processed/downloaded images are saved into the **%temp%\EZT-MediaPlayer** folder. These can be deleted anytime
- Core app settings are stored in `%appdata%\Roaming\EZT-MediaPlayer`. There is an **XML config file** that holds the primary settings for the app and EQ settings. Also, **custom EQ presets** created are stored in the **EQPresets** folder in the same directory as the config
- This is at its core a **PowerShell script**. As such this will likely only work on **Windows** endpoints and is untested on other platforms, though it is compatible with PowerShell 7+
- Requires at least **Powershell v5.1** and .NET 4.5 or higher. Tested on **Windows 10** and **Windows 11**. It may work on Windows 7 but I don't care if it does and you shouldn't either.
- Uses PowerShell RunSpaces for multi-threading, though expect UI stutters and momentary freezes can still happen but hopefully limited. Working to improve
- A lot of optimization is still needed, but on average the app uses about ~600 - 700mb of RAM with avg media library containing about 10,000 media items. 
  - CPU usage while playing should be avg ~10% depending on your CPU, what your playing and if you enable Hardware Acceleration under Settings (only applies to video rendering).
  - With HA enabled, GPU usage can be 15 - 20% for high-quality (1080p) video streams. It should be close to the same level of performance of vlc since it uses libvlc
- While improvements have been made to error handling and UI threading, there can still be some uncaught exceptions or other issues that can cause the app to freeze. If it happens, please submit a bug report with logs and detailed description
- Alot more but this list is long enough for now
* * * 

## Primary Modules/Components <a name="Primary_Modules_Components"></a>

A quick list of the various apps, components or libraries used in this project (as well as endoresment for each)

**[MahApps.Metro](https://github.com/MahApps/MahApps.Metro)**
- A framework that allows developers to cobble together a better UI for their own WPF applications with minimal effort.
- Mahapps is a God send for WPF development IMO, seriously consider using it. Lots of tutorials and help for use with PowerShell as well

**[LibVLCSharp](https://github.com/videolan/libvlcsharp)**
- LibVLCSharp is a cross-platform audio and video API for .NET platforms based on VideoLAN's LibVLC Library. It provides a comprehensive multimedia API that can be used across mobile, server and desktop to render video and output audio as well as encode and stream
- Originally used vlc.dot.net but recently moved to libvlcsharp as the former is in maintenance mode, no longer updated
- Supports basically anything that VLC media player also supports
- Native WPF control with LibvlcSharp.WPF. Suffers from infamous WPF Airspace issue, but the workarounds/methods used in libvlcsharp.wpf so far work very well

**[YT-DLP](https://github.com/yt-dlp/yt-dlp)**
- A youtube-dl fork with additional features and fixes
- Used for parsing/downloading Youtube videos as well as a ton of other features that i'm not currently tapping into (yet)

**[Spotshell](https://github.com/wardbox/spotishell)**
- A powershell module used to interact with the Spotify API
- It handles all Spotify Web API endpoints including control of players
- The version included is customized and integrated specifically for this app. The changes arent huge, mostly to Spotify authentication capture, small bug fixes, error hanlding and others

**[Streamlink](https://github.com/streamlink/streamlink)**
- Streamlink is a CLI utility which pipes video streams from various services into a video player (in this case libvlc)
- Currently only used for handling Twitch streams. Streamlink captures and 're-streams' the feed as a local HTTP service, which libvlc then plays.
- Technically yt-dlp works with twitch streams, but doesn't handle ads very well (and its much slower). So far in testing, no ads have come through or have been shown using streamlink, though that cant be guaranteed
- Has many plugins and other potential use cases for this

**[Spicetify](https://github.com/khanhas/Spicetify)**
- Command-line tool to customize the official Spotify client. Supports Windows, MacOS and Linux
- Long ago Spotify stopped supporting direct control of the Spotify app, thus you must use the Spotify API (which is what SpotiShell does)
- This provides an alternative way to directly control the Spotify app (and customize look/features). Spicetify injects custom code into the player. 
- This app uses Spicetify with a customized version of the webnowplaying extension (originally used to support using Rainmeter with Spotify) in order to allow control of the Spotify app without using the web API
- Basically, webnowplaying extension allows sending/receiving websocket commands to/from Spotify. For this app, this is used in combination with the PODE module, which creates a websocket server and routing points for receiving and sending commands
- This also will allow getting data back from Spotify about currently playing items, especially current progress/duration which right now requires a Spotify web API call every second or so. This part is not yet implemented in this app but its planned. 
- This is VERY WIP and needs perfecting. Updates to Spotify break these changes, though can be quickly re-applied/fixed. The goal is to get rid of the requirement of sending web API calls to control a player that is installed locally right in front of your face. Lunacy Spotify, lunacy (but yes I get why this is)
- NOTE: By default, Spotify playback is handled using the web player (via webview2) and the Spotify Web Playback SDK. A Spotify Premium account is required to use these features. For free Spotify accounts, the Spicetify/PODE solution can be enabled under the Settings tab. Enabling injects the customizations, disabling removes them/sets Spotify back to default

**[PODE](https://github.com/Badgerati/Pode)**
- Pode is a Cross-Platform PowerShell web framework for creating REST APIs, Web Sites, and TCP/SMTP servers
- This is used in combination with Spicetify customization's to allow direct control of the Spotify app using web-socket commands vs web API calls (PODE call are all localhost)
- Also used for the Oauth capture process for Youtube authentication
- The 'servers' and routing commands run under their own runspaces, so as not to tie up the app
- While I'm not aware of any security issues with this, a full security review/audit of this process isn't complete, nor is the implementation finished. Just need to preface with that
- For example, starting playback of specific Spotify track URL (with Spicetify enabled) is done by sending 'Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing'. 

**[BurntToast](https://github.com/Windos/BurntToast)**
- Module for creating and displaying Toast Notifications on Microsoft Windows 10.
- Originally used own/custom module but this one is mature and supports way more customization, such as changing the name of the app and icon that generates the notification (aka preventing it from displaying PowerShell)

**[BetterFolderBrowser](https://github.com/Willy-Kimura/BetterFolderBrowser)**
- A .NET component library that delivers a better folder-browsing and selection experience.
- Provides a better folder-browsing and selection experience to users by employing a similar browser dialog as the standard OpenFileDialog. Supports multi-folder selection..etc

**[GongSolutions.WPF.DragDrop](https://github.com/punker76/gong-wpf-dragdrop)**
- The GongSolutions.WPF.DragDrop library is a drag'n'drop framework for WPF
- Provides a better dragdrop experience in WPF for controls like TreeView

**AnimatedScrollViewer**
- Custom assembly compiled from a few StackOverflow posts that provides a true Animated Smooth Scrolling effect for WPF scrollviewers
- Also includes code to allow scrolling while dragging an item when using dragdrop
- Can provide source code at request but basically its this: https://stackoverflow.com/questions/20731402/animated-smooth-scrolling-on-scrollviewer

**[VirtualizingWrapPanel](https://github.com/sbaeumlisberger/VirtualizingWrapPanel)**
- Implementation of a VirtualizingWrapPanel for WPF running .NET Framework 4.5.2+, .NET Core 3.1+ or .NET 5.0+
- Used in very limited/specific cases, but provides better performance and UI virtualization of various WPF controls

**[Chocolatey](https://github.com/chocolatey/choco)**
- Chocolatey is a CLI-based package manager for Windows that is sort of like apt-get.
- Used for silently installing/updating any required external applications/components

**[Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/1.1.1)**
- Used to securely store and retrieve various credentials/secrets
- Used for storing access token data for Spotify, Youtube and Twitch accounts

**[AvalonDock](https://github.com/Dirkster99/AvalonDock)**
- AvalonDock is a WPF Document and Tool Window layout container that is used to arrange documents and tool windows in similar ways than many well known IDEs, such as, Eclipse, Visual Studio, PhotoShop and so forth.
- Used to host the video player, media libary and other windows to allow undocking, docking and floating

**[YouTube](https://github.com/pcgeek86/youtube/)**
- A PowerShell module to manage YouTube content via the official REST API.
- This module has been heavily modified and added to for use with this project. But was used as the main template and want to include the credit

**[DiscordRPC](https://github.com/potatoqualitee/discordrpc)**
- Discord Rich Presence Client written in PowerShell.
- Used for Discord Rich Presense integration to display current media playback info. Very slightly modified

**[SoundVolumeCommandLine](https://www.nirsoft.net/utils/sound_volume_command_line.html)**
- SoundVolumeCommandLine (svcl.exe) is a console application that allows you to do many actions related to sound volume from command-line
- Used to route per app audio sessions for capture and output which enables features such as EQ support for webplayers

**[CSCORE](https://github.com/filoe/cscore)**
- An advanced audio library, written in C#
- Used for managing, enumerating and controlling Windows Audio Sessions
* * * 

## Available Versions <a name="Available_Versions"></a>

**Installer/EXE - BETA - TESTERS/COURAGEOUS ONLY<a name="Inno_Setup_Installer"></a>**  

- Prepackaged installer using Inno setup. Will be the primary version for regular usage
- **NOTE**: Prepackaged installer is not required, it is only used to provide a convienient way to package and deliver. As its Powershell, you can just manually copy the files and execute the main script `EZT-MediaPlayer.ps1`
- A link will be provided to approved Testers

**Powershell Script - BETA - TESTERS/COURAGEOUS ONLY** <a name="Powershell_Script"></a>

- Powershell only version, main dev script
- Source code is naturally available via the repository or once you run the app and choose an install folder

**C# Source Code - NOT YET AVAILABLE**

- TBD/Maybe. May port this project over. Might not

## Installation and Configuration <a name="Installation_and_Configuration"></a>

#### Powershell Configuration <a name="Powershell_Configuration"></a>

- Parameters can be passed to `EZT-MediaPlayer.ps1` to override/force some configurations. 
  - **MediaFile** - Allows passing a media file that will begin playing when the app is launched
     - Example: `EZT-MediaPlayer.ps1 -MediaFile 'c:\music\song.mp3'`
  - **NoSplashUI** - Disables the Splash Screen from displaying on startup
     - Example: `EZT-MediaPlayer.ps1 -NoSplashUI`
  - **FreshStart** - Forces app to run first time setup on launch (DESTRUCTIVE: Removes profiles/settings)
     - Example: `EZT-MediaPlayer.ps1 -FreshStart`
  - **StartMini** - Forces app to launch using the Mini-Player skin
     - Example: `EZT-MediaPlayer.ps1 -StartMini`
  - (WIP) Others yet to be documented/implemented
- There are some configuration variables located in the region **Configurable Script Parameters** located near the top of the main script `EZT-MediaPlayer.ps1`. These are designed for advanced users or developement. Most settings are stored in `%appdata%/EZT-MediaPlayer/EZT-MediaPlayer-Config.xml` and can be configured via the in app Settings UI page or by manually editing the XML file (not recommended)

### Building Installer/Launcher <a name="Building_Installer_Launcher"></a>

 - The installer `EZT-MediaPlayer-Setup.exe` is packaged via `Inno Setup`. Once installed there is a main EXE `EZT-MediaPlayer.exe` that launches the app. This launcher is just another powershell script `EZT-MediaPlayer-Setup.ps1` packaged as a self-executable using "Turn Code into Exe" option available with ISESteroids. 
    - The installer provides the ability to pass arguments from the EXE to the main PS script (see **Parameters** under [Powershell Configuration](#Powershell_Configuration))
    - _**Note: The launcher (`EZT-MediaPlayer.exe`) detects and defaults to run with Powershell 7/core if installed (by checking for existance of `pwsh.exe`), otherwise defaults to `Powershell.exe`. PS7 is recommended for better performance**_
 - An uninstaller script `EZT-MediaPlayer-Uninstall.ps1` is also packaged into a self-executable `EZT-MediaPlayer-Uninstall.exe` which is triggered when uninstalling the package from windows or via the Inno Setup `unins000.exe`
    - The uninstaller performs the removal of any installed components (Streamlink, chocolatey..etc), removes related files (including temp) and removes any stored secrets from secure vault

_**Note: Full detailed instructions and the Inno Setup .iss file will eventually be shared and included here for "building"**_
