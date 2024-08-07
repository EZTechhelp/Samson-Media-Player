**When enabled, any duplicate media files found during the local media scanning and import process are skipped** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% This feature is WIP and not complete

%{color:#FFFFD265} ❗% Media is considered duplicate if it has the exact same file name, file size AND parent folder name as another

%{color:#FFFFD265}**Considered Duplicates**%

1. C:\Music%{color:#FFFFD265}\Funk\Chris Joss-01.mp3% - Size: 8MB
2. C:\Old_Music%{color:#FFFFD265}\Funk\Chris Joss-01.mp3% - Size: 8MB
  
%{color:#FFFFD265}**Not Duplicates**%

1. C:\Music\Funk\Chris Joss-01.mp3 - Size: 8MB
3. C:\Old_Music\Funk\Chris Joss-01.mp3 - Size: 5MB
2. C:\Old_Music\Live\Chris Joss-01.mp3 - Size: 8MB 
 
######__INFO__

%{color:cyan} ❓%  Skipping duplicates may potentially increase performance of the import process as naturally there are potentially fewer files to scan

%{color:cyan} ❓%  If you change this setting after the initial/first time import, you can refresh the library by selecting **REFRESH** button in the Local Media Library tab


