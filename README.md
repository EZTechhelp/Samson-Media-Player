# EZT-MediaPlayer

#### IMPORTANT ####
- This app is currently in Pre-Alpha with many features incomplete or broken. Expect many bugs, poor performance and everything associated with a Pre-Alpha. It is not intended for production/public use


### Synopsis ###

Simple media player built in PowerShell and WPF that allows playback and playlist management of media from multiple media sources such as local disk, Spotify, YouTube, Twitch and others. Powered by LibVLCSharp


**Current Features**

- Ability to import and play Spotify playlists and tracks from valid Spotify Account
- Ability to import and play YouTube playlists
  - Playlists currently must be added manually (Youtube API integration planned)
  - Private playlists can still be added if you are logged in with a valid YouTube account with a supported browser (cookies extracted)
- Create custom playlists, combining media from any supported platform
- Playback Queue management, with shuffle playback option
  - When next item is played, the appropriate method is determined to play the media (such as Spotify..etc)
- Add media using Drag-n-Drop of media files or URL links directly into app
  - Drag-n-drop also supported when moving items between lists and re-ordering
- In-app or full-screen pop-out video player, with option to enable/disable Hardware Acceleration
- Supports Twitch live streams and chat display, with ability to track 'Live/Offline' status
- Ability to play or download YouTube videos to local disk using best available quality (via yt-dlp)
- In-App basic WebBrowser (using Webview2) for some reason, seemed like a good idea at the time
  - Youtube URLS are redirected to use Invidious (yewtu.be) because Google ya know what I mean?
- DataGrids use pagination to handle lists with hundreds/thousands of items (WIP)
  - For now defaults to max 50 items displayed per page. Will be adjustable later
- Uses PowerShell RunSpaces (multi-threading and job handling) for improved performance and responsive WPF UI
- Supports limited keyboard capture events for Play, Pause, Stop and Next (volume and others planned probably)
- 10-Band EQ control with ability to save custom presets or use existing defaults
  - Additional audio filters (and video filters) planned down the road  
- Independent volume and mute control
  - Currently only applies to all NON-Spotify Media. Direct control of Spotify volume/audio is planned
- Supports displaying Toast notifications on media playback (can be enabled/disabled in settings)  
- Supports starting app automatically on Windows startup/login (WIP)
- Extensive verbose logging support, for troubleshooting and development.
- Limited support for Audio Visualizations
- Packaged as an install using Inno Setup 
- Other things TBD


## Testing

For those who are part of or wish to be part of internal QA testing, the following lists the current areas of focus.

For this first round of testing, only the most basic functionality is to be tested (such as does it even load at all). You are welcome to test any available feature, but primarily I'm looking for feedback on the following:

- Install the app, launch it and get to the First Run Setup window
- Enable Import Local Media, provide at least 1 directory with media, Enabling Import Youtube, provide at least 1 video or playlist
- Enable Import Spotify, be presented a Window to login with Spotify Account, and successfully authenticate
  - **IMPORTANT** In order to use Spotify features, your spotify account must be added to an approved list for the API. This is only during the development and testing process 
- Start setup and verify that app setup finishes and the main UI opens
- Verify it detects media from directories you provide when importing Local Media
- Verify it detects media when choosing to importing Spotify playlists
- Verify it detects media from playlists/urls you provide when importing Youtube playlists
- Verify playback of audio/video works when playing Local, or Youtube media
- (Optional) Verify playback of Spotify media works. Spotify playback should work but is still heavily WIP
- (Optional) Create at least 1 custom playlist containing at least 1 item from each media source (Local,Youtube,Spotify)

**Important Notes/Requirements**

- The app by **default runs under user context**, but could potentially require running as admin in some cases (such as first time setup)
- **Spotify** app is required for Spotify features. Spotify is automatically installed via **chocolatey** if its not already. A Spotify account also required, but free should work (needs testing as I've only tried with Premium). Spotify app must be launched at least once and logged in with your account
	- Spotify playback powered by customized version of **SpotiShell** module and optionally **Spicetify/PODE Server** (Very WIP)
- **Testers:** I must **manually add your Spotify account**  to the API approved list. 
  - Spotify has a 25 account limit for in-development API usage. Will need your email address for Spotify. Once added you can enable Spotify features	
- **Yt-dlp** used for **Youtube** playback/download features (included)
- **Streamlink** used for (generally) Ad-free Twitch Streaming/Playback (installed automatically)
- Most **Powershell Modules** needed are included, with a few others installed/imported automatically 
- If running under Administrator context, and local media is located on a mapped drive (network/nas..etc) **EnableLinkedConnections** registry setting can be set to allow accessing mapped drives in Windows 
  - This is not applied by default but the code is there (commented out) to check and apply the setting on startup, but recommend doing manually if you need it 
- **Verbose logging** is **enabled by default** for development reasons, which will effect performance and cause log file to grow in size quickly, so heads up. You can disable verbose logging in settings, which doesn't disable logging entirely, just greatly minimizes it, but thats not helpful to me when testing :)
	- The log file is located at **%appdata%\EZT-MediaPlayer\EZT-MediaPlayer-(version).log**. This will be needed when providing feedback 
	- Basic computer info such as name, make, model, cpu, ram, Windows version..etc is included in the log file
	- Log file may also contain details of media you provide, names of playlists, songs..etc. 
	- If you are concerned about what info you share, recommend reviewing the log file and scrubbing anything. 
	- The app has a Feedback/Issue submission form (from title bar dropdown menu). However due to security reasons, I'm not including the creds for test builds in order for it to work, so nothing is sent to me even if you try to use it (will probably just fail)	
- All web API calls are sent encrypted (https) and subject to privacy terms of the services (in this case Spotify and Twitch). 
	- The only data I can see is the public IP address where API calls where made from, when and how many requests made. Not content
	- Spotify creds are captured using Spotify's web auth page (displayed via webview2). An auth token is then stored in $appdata%\SpotiShell 
	- Youtube creds are not stored. Yt-dlp has a feature to authenticate by importing existing cookies from a supported browser if available
	- If logging in to websites using web features, such as Twitch chat, this is all handled by Webview2. See below for storage detail	
- By default, Playlist and Media profiles are stored in **%temp%\EZT-MediaPlayer**. So fair warning if you clear your temp folder. This is temporary...and ability to move/choose location is planned. Just be aware if you delete this folder, the app will automatically run First Time Setup again. Custom playlists will be lost
	- **Temp files for Webview2 controls** (cookies..etc) and any processed/downloaded images are saved into the temp folder as well. These can be deleted anytime (though may increase startup time a little when first processing again)
- Core app settings however are stored in **%appdata%\EZT-MediaPlayer**. There is an **XML config file** that holds the primary settings for the app and EQ settings. Also, **custom EQ presets** created/saved are stored in the **EQPresets** folder in the same directory as the config
- This is at its core a **PowerShell script**. As such this will likely only work on **Windows** endpoints and is untested on other platforms, though it is compatible with PowerShell 7+
- Requires **Powershell v5.1** and .NET 4.5 or higher. Tested on **Windows 10** and **Windows 11**. It may work on Windows 7 but I don't care if it does and you shouldn't either.
- Uses PowerShell RunSpaces for multi-threading, though we still have to deal with 1 UI thread, so UI stutters and momentary freezes can still happen but hopefully limited. Working to improve
  - A Job/cleanup RunSpace is used to manage RunSpace and dispose/close of ones that finish
  - Duplicate RunSpaces are terminated if detected. Ex: if a new playback RunSpace starts but the previous is still running, it will be terminated before starting the new one to keep things tidy
  - Terminating a RunSpace that contains a UI or appcontext thread will freeze the entire app, so those are not ever forced closed (hopefully) 
- When enabling Start on Windows, app creates (or removes if disabling) a Windows scheduled task. Must provide path to main exe when enabling
- A lot of optimization is needed, but early testing shows, on average the app uses about ~600 - 700mb of RAM. CPU should be ~10% depending on what your playing and if you enable Hardware Acceleration under Settings (only applies to video rendering). With HA enabled, GPU usage can be 15 - 20% for high-quality (1080p) video streams.
- While improvements have been made to error handling and UI threading, there can still be some uncaught exceptions or other issues that can cause the app to freeze. If it happens, I need to know what specifically you were doing/clicking/viewing when it happened (and log file of course)
* * * 

**Known Issues**

- So many to list, but will try to highlight the main ones (have I mentioned this is pre-alpha and WIP?)
- Keywatcher/keyboard events can be hit or miss. So for ex: hitting Pause/Play may sometimes not work first try
	- 'Keywatcher' runs under its own runspace, watching for keyboard press events. Its a little buggy and needs improvement, but generally works. 
	- Need to figure out how to deal with conflicts, like block Spotify/web browsers and even windows from capturing them while app is running
- Spotify playback is a PITA. 
	- Generally if your Spotify account and API creds are good, things should work. But a single missed API call/web timeout can cause issues which is why Spicetify is being added as an option. 
	- The biggest issue seen so far is Spotify either just doesn't play, or when playback finishes, Spotify plays whatever the F it wants next and doesn't honor the apps queue list or response to commands. 
	- Admittedly, I'm using some rather nuclear methods to shut Spotify up when it doesn't respond, meaning I force close the process, that'll teach ya!
	- Using the progress slider bar can be laggy, but should work. Works better for local media
- YouTube playback can have a good sized delay before video begins. This is due to yt-dlp, which extracts the best audio/video stream for the video each time. These stream URLs can't be saved to speed things up later since they expire. Its not terrible IMO but perhaps there is some way I don't know yet to improve this. 
- By default I have yt-dlp always extract the best quality video and audio streams and mux them together (cause i'm a snob like that) but using best available single stream or lower quality does greatly improve speed/start time of playback. The ability to choose quality (when playing and downloading) is planned
- Downloading YouTube videos can be hit/miss. By default like playback, the best quality for audio and video is downloaded and combined into an MKV, with a thumbnail. Again additional options are planned. The app uses jobs to monitor a verbose/std output of yt-dlp to a log file, together with the get-content -wait in order to read and log status of downloads (and other things) in near real-time, otherwise you have to wait until its all finished and have no way of knowing if its doing anything. This is all done in a separate runspace tho so you can still use the app while its downloading. A notification displays when its finished
- There is a notification system (separate from toast notifications) and a basic in-app help documentation. These appear at the top as a flyout (or from the side for help). Notifications have a dismiss button. This is in known issues because the notifications can sometimes not be accurate (like showing failed when something is success). This wont be hard to fix I just haven't gotten to that part yet, which also applies to the in-app help documentation system. Some options have a help icon/button which displays a flyout with instructions/info. Its not done and probably doesn't always make sense (since things have changed).
- Various options/controls in the Settings tab don't do anything yet, specifically 'App always on Top', Minimize to tray, start minimized, Download Youtube media on playback, and maybe more.
- When enabling/disabling EQ from the Audio settings flyout, it causes audio to skip/pause for a second or 2. I don't think this is actually an issue (at least with this app) as that is just how it works, considering its changing out audio filters/channels on the fly. This happens with VLC media player in my experience too. 
- The play queue can behave oddly. By that I mean when playback of one item ends, the next item may not play or the app will just skip through the rest of the items without playing. This usually has happened when there are Spotify items in the list (go figure). I have managed to improve this behavior greatly (such as moving to a ordered dictionary list which I should have used from the start) at least in my own testing 
- Performance takes a good sized hit when Verbose Logging is enabled (which it is by default). I need this enabled to get the info I need, but you can try disabling it (from Settings tab) to test without it, then re-enable it again
- The first time importing youtube playlists/videos can take a while, depending on how many videos. I recommend only adding a small amount of videos or playlists with no more than 10 - 20 videos, just for testing. The Youtube processing is done in a runspace so it shouldn't tie up the app. If you go to the Youtube browser tab and see a spinning circle, that means its still working (or potentially failed which the logs should show)
* * * 

## Primary Modules/Components

A quick list of the various pieces I've cobbled together that arent native (ie coded from scratch)

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
- NOTE: By default, Spotify playback is handled entirely by SpotiShell/API calls. Using Spicetify/PODE solution can be enabled under the Settings tab. Enabling adds customization's, disabling removes them/sets Spotify back to default

**[PODE](https://github.com/Badgerati/Pode)**
- Pode is a Cross-Platform PowerShell web framework for creating REST APIs, Web Sites, and TCP/SMTP servers
- This is used in combination with Spicetify customization's to allow direct control of the Spotify app using web-socket commands vs web API calls (PODE call are all localhost)
- The 'servers' and routing commands run under their own runspaces, so as not to tie up the app
- While I'm not aware of any security issues with this, since nothing sensitive (such as account data) is sent, and its confined locally, a full security review/audit of this process isn't complete, nor is the implementation finished. Just need to preface with that
- For example, starting playback of specific Spotify track URL is done by sending 'Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing'. 
- NOTE: By default, Spotify playback is handled entirely by SpotiShell/API calls. Using Spicetify/PODE solution can be enabled under the Settings tab

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
- Not currently used in this project but likely will be to provide better performance and UI virtualization of various WPF controls

**[Chocolatey](https://github.com/chocolatey/choco)**
- Chocolatey is a CLI-based package manager for Windows that is sort of like apt-get.
- Used for silently installing/updating any required external applications/components, such as Spotify

**[Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/1.1.1)**
- Used to securely store and retrieve various credentials/secrets
- Not currently used (yet) in this project. Likely to be used to Store Spotify authentication when moving to published Spotify API and perhaps others
* * * 

## Available Versions

**[Self Executable - Pre-Alpha]()**  

- Its packaged as a self-executable for quick and easy usage, mobility and setup/update management. Will be the primary version for regular usage
- A link will be provided to approved Testers

**[Powershell Source Code - Pre-Alpha]()** 

- Powershell only version, main dev script
- Source code is naturally available once you run the app and choose an install folder

**[Python Source Code - NOT YET AVAILABLE]()**

- TBD

## Installation and Configuration

#### Powershell Configuration

- If you wish to use the pure Powershell shell script version, some configuration variables are located in the region **Configurable Script Parameters** located near the top of the script. Most settings stored in %appdata%/EZT-MediaPlayer/EZT-MediaPlayer-Config.xml

#### Self Executable Configuration

- All configurable options will be set from within the GUI of the app under the Settings tab. (WIP)

### Building Executable

The self-executable is packaged using the classic IEXPRESS self-extracting package manager included in pretty much all Windows versions. IEXPRESS contains the main app files in a ZIP file. Those contents are NOT decompressed every-time the app runs, but only upon first setup and if a new version is to be installed. IEXPRESS extracts basic setup files such as Setup.ps1, which is basically the 'launcher' for the app. It checks/verifies paths, updates..etc, then launches the main app.

_**Note: The app detects and defaults to run with Powershell 7/core if installed (by checking for pwsh.exe), otherwise defaults to Powershell.exe**_

_**Note: Full instructions and SED (Self Extraction Directive File) will eventually be shared and included here**_
