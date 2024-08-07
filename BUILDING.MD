## Manually Building Source Files

**Installer**
+ The installer `Samson-Setup.exe` is packaged via [Inno Setup](https://jrsoftware.org/isinfo.php). Once the installer is run, there is a main EXE `Samson.exe` that launches the app
+ Open `Samson-Build-Installer.iss` with `Inno Setup Compiler`. Select `Build` - `Compile` to build `Samson-Setup.exe`
	+ Recommend only editing the Inno script if you are familiar with Inno Setup scripts and know what your doing 
    + _**Note: More detailed instructions and descriptions of the Inno Setup iss script file will eventually be shared and included here for customizing the building of the installer package**_

**Launcher**
+ The launcher is just a small c# compiled self-executable that facilitates detecting the environment (PowerShell version..etc), finding and launching the `Samson.ps1` script, while passing any provided parameters.
	+ The launcher can pass any arguments from the EXE to the main PS script (see [Powershell CLI Options](#powershell-cli-options-))
	+ _**Note: The launcher (`Samson.exe`) detects and defaults to run with PowerShell 7/core if installed (by checking for existence of `pwsh.exe`), otherwise will use `PowerShell.exe`. PS7 is highly recommended for better performance**_
+ Open `Samson.sln` with Visual Studio 2019 or higher and PUBLISH solution to compile `Samson.exe`
	
**SplashScreen**
+ The [SplashScreen](/src/SplashScreen) is just a simple XAML window compiled into `EZT-MediaPlayer-Control.dll`. If this dll is missing, the splash screen will still work (will use native PS code). The dll was added for improved performance and some other now non-relevant reasons.
+ Open `EZT-MediaPlayer-Controls.sln` with Visual Studio 2019 or higher and build solution to compile `EZT-MediaPlayer-Control.dll`

**AirHack**
+ [AirHack](/src/Airhack) is a helper WPF control that draws a separate UIElement over a transparent WPF window. This helps as a workaround to the infamous [WPF Airspace issues](https://github.com/dotnet/wpf/issues/152) 
+ The original author and source code is [AirHack Control](https://github.com/adamfierek/Airhack). It has been modified and now more resembles the method used by [LibVLCSharp](https://code.videolan.org/videolan/LibVLCSharp/-/blob/3.x/src/LibVLCSharp.WPF/)
+ Open `Airhack.sln` with Visual Studio 2019 or higher and build solution to compile `Airhack.dll`. This assembly is required for the app to function

**EZT_MediaPlayer**
+ [EZT_MediaPlayer](/src/EZT_MediaPlayer) is a helper assembly that contains various classes that define some of the core data types and structures for media profiles, playlists, config and others.
+ This assembly sort of became the 'dumping ground' for various C# snippets. Some classes or methods may no longer be used and others definitely need refactors and cleanup
+ The classes/code that make up the primary data types is also included within the module `PSSerializedXML` via Add-Type snippet. Technically that module can function without this assembly (though will be slower). Why is this in 2 places? Good question. Probably left over from early tests
+ Open `ClassLibrary1.sln` with Visual Studio 2019 or higher and build solution to compile `EZT_MediaPlayer.dll`. This assembly is required for the app to function