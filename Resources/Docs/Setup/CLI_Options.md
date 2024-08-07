## CLI Options

+ Parameters can be passed to `Samson.ps1` or `Samson.exe` to override/force some configurations. 
  + **MediaFile** - Allows passing a media file that will begin playing when the app is launched
     + Example: `Samson.ps1 -MediaFile 'c:\music\song.mp3'`
  + **NoSplashUI** - Disables the Splash Screen from displaying on startup
     + Example: `Samson.ps1 -NoSplashUI`
  + **FreshStart** - Forces app to run first time setup on launch (DESTRUCTIVE: Removes profiles/settings)
     + Example: `Samson.ps1 -FreshStart`
  + **StartMini** - Forces app to launch using the Mini-Player skin
     + Example: `Samson.ps1 -StartMini`
  + (WIP) Others yet to be documented/implemented
+ NOTE: There are some configuration variables located in the region **Configurable Script Parameters** located near the top of the main script `Samson.ps1`. These are designed for advanced users, testing or development. Most settings are stored within the config file at `%appdata%/Samson/Samson-SConfig.xml` and can be configured via the in app Settings UI page or by manually editing the XML file (not recommended).
