**Determines how scanning and importing of local media files should be handled. The default is 'Fast', which prioritizes import speed over scanning for file metadata. Review detail of each option to best accomodate your file system** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% How much effect these modes have is GREATLY dependant on the machine being run on. Storage/IO performance, CPU, filesystem and many other factors can greatly effect media scanning and import speed

%{color:#FFFFD265} ❗% The import mode affects ALL paths/directories added. So consider which mode to use based on the worse performing drive/path being added. For example, if one path is an SSD and another is high latency, external HDD over USB, you should target the mode that will work best for the slower device. 
 
######__Fast Mode__

%{color:cyan} ❓% When set to **Fast**, metadata tag scanning is skipped during initial import to allow files to be imported as fast as possible so you can begin using/playing them.

%{color:cyan} ❓% Local media files in the library will at first show only basic and likely inaccurate info until a background tag scan is complete. Media entries in the library will be updated automatically once metadata info becomes available. A small progress indicator will be shown within the library to indicate if tag scanning is active

%{color:cyan} ❓% Media info before tag scanning is complete is taken from basic file info. For example:

%{color:#FFFFD265}**Artist = Root Folder Name**%

+ C:\Music\Funk\\%{color:#FFFFD265}Chris Joss%\Chris Joss-01.mp3 - Artist: %{color:#FFFFD265}Chris Joss%
  
%{color:#FFFFD265}**Title = File Name**%

+ C:\Music\Funk\Chris Joss\\%{color:#FFFFD265}Chris Joss-01%.mp3 - Title: %{color:#FFFFD265}Chris Joss-01%

%{color:cyan} ❓% **Duration** will likely always be 0:0:0:0 until tag info scanning is complete
 
%{color:cyan} ❓% Be aware that not all media files will have tag info, and therefore even after tag scanning they may show the same information. If that is the case, the file likely contains no tag metadata 

%{color:cyan} ❓% Parallel threading is used to scan multiple directory/paths for improved performance

######__Normal Mode__

%{color:cyan} ❓% When set to **Normal**, metadata tag scanning is done for each file as they are found. 

%{color:cyan} ❓% Parallel threading is used to scan multiple directory/paths at once for improved performance, but the added metadata scanning can increase import times and IO load. 

 
######__Slow Mode__

%{color:cyan} ❓% When set to **Slow**, metadata tag scanning is done for each file as they are found. Only 1 directory is processed at a time

%{color:cyan} ❓% Parallel threading is NOT used in slow mode. This mode is intended for scanning storage devices with high IO latency or that otherwise can't handle alot of IO requests at one time. Drives with poor IO latency or throughput can cause the import process to fail completely, or greatly increase the amount of missing files or metadata

%{color:cyan} ❓% Examples of potentially high IO latency storage devices include: 

+ Low RPM (5400) externally connected HDDs
+ HDDs or any drive containing disk or file system errors
+ UNC/Network mapped drives over slow/congested networks (Wifi/WAN/100mbps..etc)

%{color:cyan} ❓% There is no guarantee the import will be successful even with Slow mode for the above type of storage systems
 
######__Other INFO__

%{color:cyan} ❓%  Tag metadata usually contains info such as Title, Arist, Album, Track, Duration, Images and other information

%{color:cyan} ❓%  If you change this setting after the initial/first time import, you can refresh the library by selecting **REFRESH** button in the Local Media Library tab


