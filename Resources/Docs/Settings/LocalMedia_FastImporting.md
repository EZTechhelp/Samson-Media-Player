**When enabled, metadata tag scanning is skipped during initial import for all local media files. Once finished, the files are then scanned for taginfo in the background and updated asyncronously. This is to allow files to be imported as fast as possible so you can begin using/playing them** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% When enabled, local media files in the library will at first show only basic and likely inaccurate info until the background tag scan is complete. Media entries in the library will be updated automatically once metadata info becomes available

%{color:#FFFFD265} ❗% Media info before tag scanning is complete is taken from basic file info. For example:

%{color:#FFFFD265}**Artist**%

+ C:\Music\Funk\\%{color:#FFFFD265}Chris Joss%\Chris Joss-01.mp3 - Artist: %{color:#FFFFD265}Chris Joss%
  
%{color:#FFFFD265}**Title**%

+ C:\Music\Funk\Chris Joss\\%{color:#FFFFD265}Chris Joss-01%.mp3 - Title: %{color:#FFFFD265}Chris Joss-01%

%{color:#FFFFD265} ❗% **Duration** will likely always be 0:0:0:0 until tag info scanning is complete
 
%{color:#FFFFD265} ❗% Be aware that not all media files will have tag info, and therefore even after tag scanning they may show the same information. If that is the case, the file contains no tag metadta
 
######__INFO__

%{color:cyan} ❓%  Tag metadata usually contains info such as Title, Arist, Album, Track, Duration, Images and other information

%{color:cyan} ❓%  If you change this setting after the initial/first time import, you can refresh the library by selecting **REFRESH** button in the Local Media Library tab


