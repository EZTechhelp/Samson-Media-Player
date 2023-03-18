# EZT-MediaPlayer

### IMPORTANT

The full repository and source code is currently private as it is not yet ready for public consumption. I am looking for any and all willing testers. Please contact me here (github) or via email: mdodge@eztechhelp.com if you are interested in being an early tester. Testers will of course have full access to the source code

### Synopsis ###

Universal media player built in PowerShell and WPF that allows playback and management of media from sources such as local disk, Spotify, YouTube, Twitch and more. Main audio engine powered by LibVLCSharp


<p align="center">
  <img Height="200" src="/Images/Samson_Logo_Splash.png" />
  <img src="/Images/Example_Image.png" Alt="Example, subject to change"/>
</p>

**DISCLAIMER**

This app is still heavily WIP in relation to any kind of public build. The current build (and example screenshot) is a very personalized and custom version made in dedication for a very dear friend and his cat Samson

**Why Powershell?**

Because why not! Ok maybe there are alot of good reasons. This has been a very educational project and also has personal meaning. While yes using a 'proper' programming language would be much better and easier, its fun and interesting to see just how much you really can do with Powershell. Granted technically there are alot of helpers and other components that arent Powershell, but the primary core and majority of the app is Powershell

## Current Features

### Discord

<img src="/Images/Discord_Integration.png" Alt="Discord Rich Presense integration to display media playback info in your Discord status/profile"/>

- Discord Rich Presense integration to display media playback info in your Discord status/profile
- Supports clickable label links for Spotify, Youtube and Twitch media 

### Mini-Player
<img src="/Images/MiniPlayer.png" Alt="Includes a 'Mini-Player' opened from tray icon/menu. Small skinned UI with only basic playback controls"/>

- Includes a 'Mini-Player' opened from tray icon/menu. Small skinned UI with basic playback controls
- Tray icon and menu with playback and shortcuts to various settings/features

### Spotify

- Ability to import and play Spotify playlists and tracks from valid Spotify Account
  - Premium and free accounts supported, though playback with free accounts is a bit 'messy' and unreliable at the moment
- Ability to record Spotify media to local disk. Currently saves as flac, futher customization options planned

### Youtube
- Ability to import and play YouTube playlists
  - Playlists from Youtube account can be imported automatically when providing credentials
- Ability to download Youtube videos to local disk (via yt-dlp)
- Alternate Youtube option to use Invidious for the Web Player vs the native Youtube embedded player
- Supports playing YoutubeTV channels (currently channels must be added manually)

### Twitch
<img src="/Images/Twitch.png" Alt="Supports Twitch live streams with chat integration"/>

- Ability to import and play Twitch live streams with chat integration
  - Includes option to enable auto-update/refresh stream status
  - (SOON) Ability to display notifications for configured channels when they go live
  - Ability to import all followed/subscribed channels when providing Twitch account
  - Multiple Twitch AD blocking solutions supported, including [TTVLOL](https://github.com/TTV-LOL/extensions) and [luminous](https://github.com/AlyoshaVasilieva/luminous-ttv)
  - [BetterTTV](https://github.com/night/betterttv) supported for enhancing in-app chat viewer
  
### Media Library/Playlists/Queue
<img src="/Images/Media_Library.png" Alt="Media library with dockable/tabbed UI supporting advanced filtering and multi-level grouping"/>

- Media library with dockable/tabbed UI supporting advanced filtering and multi-level grouping
- Add media using Drag-n-Drop of media files or URL links directly into app or from library to playlists
  - Drag-n-drop also supported when moving items between lists and re-ordering
- Create custom playlists, combining media from any supported platform
- Playback Queue and history, with shuffle, next, prev playback options  
  
### Core/Other

- Limited (very basic/WIP) support for adding and playing of SoundCloud media
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
- Other things TBD

## Important Notes/Requirements

- The app by **default runs under user context**, but requires running as admin in some cases (such as first time setup)
- **Spotify** windows client is required to be installed for free Spotify accounts. 
  - Spotify can be automatically installed if not already. 
  - Spotify playback for free accounts uses a customized version of **Spicetify/PODE Server** (WIP)
  - Premium accounts can use the built-in Spotify Web Player without needing the client app installed (Recommended/Default)	
-  **Spotify accounts must be manually added** to the API approved list for now in order to use Spotify features. 
  - Spotify has a 25 account limit for in-development API usage. Will need your email address for Spotify. Once added you can enable Spotify features	
- **Yt-dlp** used for **Youtube** download features (included)
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
- While improvements have been made to error handling and UI threading, there can still be some uncaught exceptions or other issues that can cause the app to freeze. If it happens, I need to know what specifically you were doing/clicking/viewing when it happened (and log file of course)
- Alot more but this list is long enough for now
* * * 

## Primary Modules/Components

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

* * * 

## Available Versions

**[Inno Setup Installer - BETA - TESTERS/COURAGEOUS ONLY]()**  

- Prepackaged installer using Inno setup. Will be the primary version for regular usage
- A link will be provided to approved Testers

**[Powershell Source Code - BETA - TESTERS/COURAGEOUS ONLY]()** 

- Powershell only version, main dev script
- Source code is naturally available via the repository or once you run the app and choose an install folder

**[C# Source Code - NOT YET AVAILABLE]()**

- TBD/Maybe. May port this project over. Might not

## Installation and Configuration

#### Powershell Configuration

- There are some configuration variables located in the region **Configurable Script Parameters** located near the top of the script. These are designed for advanced users or developement. Most settings stored in `%appdata%/EZT-MediaPlayer/EZT-MediaPlayer-Config.xml` and can be configured via the in app Settings UI page

### Building Installer/Launcher

The installer is packaged via Inno Setup. Once installed there is a main .EXE that launches the app. This launcher is just another powershell script packaged as a self-executable using "Turn Code into Exe" option available with ISESteroids

_**Note: The app detects and defaults to run with Powershell 7/core if installed (by checking for existance of pwsh.exe), otherwise defaults to Powershell.exe. PS7 is recommended for better performance**_

_**Note: Full detailed instructions and the Inno Setup .iss file will eventually be shared and included here for building**_
