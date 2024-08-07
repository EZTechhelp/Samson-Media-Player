**Enabling forces the app to be Per Monitor DPI aware. This can help fix issues with blurry UI elements especially when using multiple monitors**

#####__IMPORTANT__
%{color:#FFFFD265} ❗% This feature is currently considered EXPERIMENTAL. 
 - On windows 11, with this enabled, if you change the `scaling` setting in windows with the app open, it can cause a crash (but not always)
 - Enabling this can still be beneficial especially if you have multiple monitors, as it can clean up blurry UI elements such as with the video viewer overlay controls when moved to another monitor

%{color:#FFFFD265} ❗% There is currently an issue preventing the ability to properly set Per Monitor DPI awareness when using this app with `Powershell 6+`. 
 - Currently a workaround is used that sets a registry key for the launcher exe to force use of `Per-Monitor` DPI awareness, but it can't use the newest and better `Per-Monitor v2` mode. 
 - The issue relates to how the app is launched. This issue does not occur if you manually open pwsh.exe and then launch the main script.
 - Even in just `Per-Monitor` DPI mode, it does still help clean up blurry UI elements

######__INFO__
%{color:cyan} ❓% Enabling per-monitor DPI awareness mode allows an app to immediately render correctly whenever the windows DPI changes. Otherwise UI elements can appear blurry as Windows will basically "stretch" them

%{color:cyan} ❓% Highly recommend reviewing [High DPI](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/high-dpi-and-windows?view=windows-11) to better understand DPI awareness in Windows.

