**Enable to configure the Enablelinkedconnections registry option in order to allow accessing mapped drives when running this app under the administrator context** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% This option is required if you attempting to import media from mapped network drives AND the app is running under the admin context (Run As Administrator). 
+ It is not needed to access media on a local drive (including USB storage..etc)

%{color:#FFFFD265} ❗% This app normally runs under the **User context EXCEPT during First Time Setup**. 
+ First time setup runs as admin in order to complete install and configuration of required components

%{color:#FFFFD265} ❗% Admin permissions are required to fully configure Enablelinkedconnections. 
+ The app will configure Enablelinkedconnections on startup **ONLY if the app is currently running under the admin context**. If not you will get a alert warning to restart the app as admin or restart your computer to complete the configuration. 

%{color:#FFFFD265} ❗% Alternatively, if you are currently running this app after just installing or updating it, you can close and restart the app. 
+ The app will then run under the user context and this option should not be needed. You just need to remember to restart the app at least one extra time anytime after installing or updating

%{color:#FFFFD265} ❗% This option and help documentation is WIP and subject to change

######__INFO__

%{color:cyan} ❓%  For more information about EnableLinkedConnections, visit [Microsoft KB 3035277](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command)


