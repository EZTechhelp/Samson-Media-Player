## Modules, Libraries and other used Components

A quick list of the various apps, external components or libraries used in this project as well as endorsement for each. (WIP - apologies if any are missed)

**[MahApps.Metro](https://github.com/MahApps/MahApps.Metro)**
- A framework that allows developers to cobble together a better UI for their own WPF applications with minimal effort.
- IMO, MahApps is a God send when starting with PowerShell WPF development. I seriously recommend using it. Lots of support, tutorials and help for use with PowerShell specifically as well

**[LibVLCSharp](https://github.com/videolan/libvlcsharp)**
- LibVLCSharp is a cross-platform audio and video API for .NET platforms based on VideoLAN's LibVLC Library. It provides a comprehensive multimedia API that can be used across mobile, server and desktop to render video and output audio as well as encode and stream
- This is the 'Core' audio and video playback engine. It is the engine that makes up VLC itself, though I would never dare compare the holy VLC to this crazy experiment of an app
- Originally used VLC.dot.net but moved to LibVLCSharp as the former is in maintenance mode and no longer updated
- Native WPF control used with LibvlcSharp.WPF. Suffers from infamous WPF Airspace issue, but the workarounds/methods used in LIBVLCSharp.WPF (and some other custom tweaks) so far work well. In truth, WPF probably is just not the best UI framework for media apps, PowerShell or not

**[YT-DLP](https://github.com/yt-dlp/yt-dlp)**
- A YouTube-DL fork with additional features and fixes
- Used for parsing/downloading YouTube videos as well as a ton of other features that I'm not currently tapping into (yet)

**[SpotShell](https://github.com/wardbox/spotishell)**
- A PowerShell module used to interact with the Spotify API
- It handles all Spotify Web API endpoints including control of players
- The version included has been highly customized and integrated specifically for this app. The changes are mostly to Spotify authentication capture, small bug fixes, error handling and others

**[StreamLink](https://github.com/streamlink/streamlink)**
- StreamLink is a CLI utility which pipes video streams from various services into a video player (in this case LIBVLC)
- Currently only used for handling Twitch streams and as a fallback in some rare cases for YouTube (non-web-player). StreamLink grabs and 're-streams' the feed as a local HTTP service, which LIBVLC then plays
- Technically YT-DLP works with twitch streams, but doesn't handle ads very well (or really at all) and its much slower
- Includes some plugins that can be enabled to potentially block ads, and so far has worked very well, but cannot be guaranteed to always work due to the volatile nature of Ad blocking
- Has many other potential use cases not currently tapped into 

**[Spicetify](https://github.com/khanhas/Spicetify)**
- Command-line tool to customize the official Spotify client. Supports Windows, MacOS and Linux
- Long ago Spotify stopped supporting direct programmatic control of the Spotify app, or maybe never really did, thus you must use the Spotify API when controlling playback (which is what the SpotiShell module does)
- This provides an alternative way to directly control the Spotify app (and potentially customize look/features if you wanted). Spicetify injects its own custom code into the player since Spotify itself is basically just a web app
- Samson uses Spicetify along with a customized version of the WebNowPlaying extension (originally used to support using RainMeter with Spotify) in order to allow control of the Spotify app without using the web API
- Basically, the WebNowPlaying extension allows sending/receiving web-socket commands to/from Spotify. For Samson, this is used in combination with the PODE module, which creates a web-socket server and routing points for receiving and sending commands with PowerShell
- This also will allow getting data back from Spotify about currently playing items, especially current progress and duration which would otherwise require a Spotify web API call every second or so (yikes)
- This is VERY WIP, sort of ugly and needs perfecting. Updates to the Spotify client can break Spicetify, though normally can be quickly fixed by just disabling and re-enabling Spicetify (within Samson). The goal is to get rid of the requirement of sending web API calls for playback control/info for the Spotify windows client
- Using this is primarily to allow support of playback features for those with only a free Spotify account, as Spotify Premium is required to the web-player, which is the default, better and recommended method to use
- NOTE: By default, Spotify playback in this app is handled using the web player via webview2 and the Spotify Web Playback SDK. A Spotify Premium account is required to use these features. For free Spotify accounts, the Spicetify/PODE solution can be enabled under the Settings tab. Enabling injects the customization's, disabling removes them and sets Spotify back to default

**[PODE](https://github.com/Badgerati/Pode)**
- PODE is a Cross-Platform PowerShell web framework for creating REST APIs, Web Sites, and TCP/SMTP servers
- This is used in combination with Spicetify customization's to allow direct control of the Spotify app using web-socket commands vs web API calls (PODE calls are all local only)
- Also used for the OAuth capture process for YouTube authentication. The referral link configured via YouTube API is set to LocalHost, where PODE acts as the endpoint for that capture to work
- The PODE 'servers' and routing commands run under their own run-spaces, so as not to tie up the app
- For example, starting playback of a specific Spotify track URL (with Spicetify enabled) is done by using the command 'Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing'. 

**[BurntToast](https://github.com/Windos/BurntToast)**
- Module for creating and displaying Toast Notifications on Microsoft Windows 10.
- Originally used my own/custom module but this one is mature, supports more customization and just works way better, such as changing the name of the app and icon that generates the notification (preventing it from displaying as PowerShell)

**[BetterFolderBrowser](https://github.com/Willy-Kimura/BetterFolderBrowser)**
- A .NET component library that delivers a better folder-browsing and selection experience.
- Provides a better folder-browsing and selection experience to users by employing a similar browser dialog as the standard OpenFileDialog. Supports multi-folder selection..etc

**[GongSolutions.WPF.DragDrop](https://github.com/punker76/gong-wpf-dragdrop)**
- The GongSolutions.WPF.DragDrop library is a drag'n'drop framework for WPF
- Provides a better drag-drop experience in WPF for controls like TreeView (This is mostly obsolete now with the move to SyncFusion controls but still want to credit it)

**EZT_MediaPlayer**
- A custom C# assembly providing various helper classes and features.
- AnimatedScrollViewer - created from a few StackOverflow posts that provides a true "animated smooth scrolling" effect for WPF scroll-viewers
  - https://stackoverflow.com/questions/20731402/animated-smooth-scrolling-on-scrollviewer
- Contains classes that make up the core data types and structure for media profiles, playlists, config and others
- Also includes code to allow scrolling while dragging an item when using drag-drop, a custom OutlineTextblock control and many other tidbits
- Technically these could be put in PowerShell directly via Add-Type and whatnot but having them Precompiled in a helper assembly is much more performant

**[SyncFusion](https://www.syncfusion.com/wpf-controls)**
- The SyncFusion WPF controls is a package of over 100 modern WPF UI controls, 50+ WPF Charts, and document processing libraries
- After struggling with various ways to better handle very large datasets in WPF with lots of custom filtering, I caved and implemented SyncFusion mostly for data virtualization with data-grids
- Also use for tree-views that include many expanded features over the native WPF tree-view control, such as multi-select support or more

**[Chocolatey](https://github.com/chocolatey/choco)**
- Chocolatey is a CLI-based package manager for Windows that is sort of like apt-get.
- Used for silently installing/updating some required external applications/components

**[Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/1.1.1)**
- Used for securely storing and retrieve various credentials/secrets such as for Spotify, YouTube and Twitch accounts
- All data is stored locally only and encrypted 

**[AvalonDock](https://github.com/Dirkster99/AvalonDock)**
- AvalonDock is a WPF Document and Tool Window layout container that is used to arrange documents and tool windows in similar ways than many well known IDEs, such as, Eclipse, Visual Studio, PhotoShop and so forth.
- Used to host the video player, media library and other windows or tabs that support undocking, docking, and floating window control

**[YouTube](https://github.com/pcgeek86/youtube/)**
- A PowerShell module to manage YouTube content via the official REST API.
- This module has been heavily modified and added to for use with this project. But was used as the main template and want to include the credit

**[DiscordRPC](https://github.com/potatoqualitee/discordrpc)**
- Discord Rich Presence Client written in PowerShell.
- Used for Discord Rich Presence integration to display current media playback info. Very slightly modified

**[SoundVolumeCommandLine](https://www.nirsoft.net/utils/sound_volume_command_line.html)**
- SoundVolumeCommandLine (`svcl.exe`) is a console application that allows you to do many actions related to sound volume from command-line
- From the legendary NirSoft tools. Used to route per app audio sessions for capture via [VB-Cable](https://vb-audio.com/Cable/) and output which enables features such as EQ support for web-players

**[CSCORE](https://github.com/filoe/cscore)**
- An advanced audio library, written in C#
- Used for managing, enumerating and controlling Windows Audio Sessions. Also used for the audio spectrum analyzer

**[TagLib](https://github.com/mono/taglib-sharp)**
- A .NET platform-independent library (tested on Windows/Linux) for reading and writing metadata in media files, including video, audio, and photo formats
- Used when scanning local media files for metadata to populate in the Media Library. Also used to write metadata to files. Usually very accurate and fast. Does not grab anything from the web, only what the local files contain

**[Denon Classic Style Skin](https://www.aimp.ru/?do=catalog&rec_id=417)**
- The customized skin for Samson is inspired by this skin which was made by author Black_AVP for AIMP


## Credits and Contributions
<img align="left" src="/Resources/Docs/Images/Woody.png" Width='3%' title="Wøødy"/>**[Wøødy](https://github.com/Woody033)**
<br clear="left"/>

+ MASSIVE thank you to my partner in crime on this project
+ Helped with testing nearly every build up to the latest
+ Helped in many other areas including graphic design (many skin components, including the awesome 'Speakers') and various core code
+ Provided great ideas, feedback and motivation to keep this project going

***

🏆 **Peezy** 

+ Was the very first to help test the earliest builds
+ Provided great ideas, feedback and motivation to keep this project going

***

🏆 **Kakarot (naivE)**

+ Improved on and converted some native vb code into C# for the Find-FilesFast module

***

<img align="left" src="/Resources/Docs/Images/PSDiscord.png" Width='3%' title="Powershell Discord Community"/>[Powershell Discord Community](https://discord.com/invite/BDCr7bEBBb) 
<br clear="left"/>
+ Help with various code bits and testing

***

<img align="left" src="/Resources/Docs/Images/ScoopDoodles.png" Width='3%' title="Scooped Doodles"/> **Grant** ([Scooped Doodles](https://www.artstation.com/scoopeddoodles))
<br clear="left"/>
+ Designed and hand drew the template for the main logo and icon 
<img align="left" src="/Resources/Samson_Icon1.png" Width='5%' title="Scooped Doodles Design (with minor edits by me)"/> 
<br clear="left"/>

***

<img align="left" src="/Resources/Docs/Images/Piscean.png" Width='3%' title="Piscean"/> **Piscean** 
<br clear="left"/>
+ An experienced QA tester who provided invaluable feedback and testing for many builds