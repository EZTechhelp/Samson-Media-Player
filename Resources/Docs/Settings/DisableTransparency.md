**Enabling will disable transparency effects for the Main Window on app startup (Sets AllowsTransparency to false)**

#####__IMPORTANT__
%{color:#FFFFD265} ❗% Changing this setting requires restarting the app, as it can only be applied BEFORE the main window is first rendered 

%{color:#FFFFD265} ❗% Enabling this setting may be required as a workaround to these issues:
 + Audio Visualizations arent visible when video viewer is docked (specifically when using ProjectM)
 + Video Viewer regularly flashes white when resizing or when playback stops
 
%{color:#FFFFD265} ❗% Enabling this will cause the "feet" area at the bottom of the main window UI skin to just be a black background

######__INFO__
%{color:cyan} ❓% This is available mostly as a workaround to a common WPF issue that effects interactions with other windows (such as Winforms). It can also provide some performance benefits though likely very minimal on most systems.

%{color:cyan} ❓% For more technical and indepth explanation, see [WPF and WinForms Interoperation Limitations](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/advanced/wpf-and-win32-interoperation?view=netframeworkdesktop-4.8&redirectedfrom=MSDN).

