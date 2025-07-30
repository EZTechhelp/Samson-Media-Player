**Selects the log message threshold for the Vlc log. The default is 0 (Info)**

#####__IMPORTANT__

   %{color:#FFFFD265} ❗% This setting normally shouldnt be changed, and is only meant for troubleshooting and/or development
   
   %{color:#FFFFD265} ❗% Setting the log level to anything higher than default 0 (Info), can cause the log to grow in size very quickly. 
   
   %{color:#FFFFD265} ❗% Changes to the log level require a restart of any currently playing media.

######__INFO__

 %{color:cyan} ❓% Available Vlc Log levels are as follows:
 
  - 0: Info
  - 1: Error
  - 2: Warning
  - 3: Debug

 %{color:cyan} ❓% The Vlc log is located at [C:/Users/[USERNAME]/Appdata/Roaming/[appname]/Logs/[appname]-[appversion]-VLC.log](C:/Users/[USERNAME]/Appdata/Roaming/[appname]/Logs/)
 
 %{color:cyan} ❓% For more information about Vlc logging, visit [wiki.videolan.org](https://wiki.videolan.org/VLC_command-line_help/)