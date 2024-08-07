**Enables monitoring for new or removed media files within the directory paths added below, and updates the local media library accordingly** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% By default, monitor mode is set to All, which triggers for both newly added files and file removals. You can change this to only monitor new addtions or only removals

%{color:#FFFFD265} ❗% Events only trigger for supported media files

%{color:#FFFFD265} ❗% Moving a file triggers a remove action (from the old path) and a new action (to the new path). Copying a file only triggers a new action (to new path)

%{color:#FFFFD265} ❗% File change events are monitored and will write to the logs but no action is taken

%{color:#FFFFD265} ❗% Buffering, caching and queue's are used to handle a rapid amount of changes (such as copying thousands of files)

%{color:#FFFFD265} ❗% When dealing with a large of amount of changes, the media library is only updated once all actions are complete (when the queue is empty)
 
%{color:#FFFFD265} ❗% Files can only be monitored while the app is running. If file changes are made while app is off, those changes will NOT be updated within the media library on the next app start

%{color:#FFFFD265}**Note**%

+ To update the libray for 'offline' changes, you can always manually refresh the library by selecting **REFRESH** button in the Local Media Library tab which will perform a full rescan of all directories
	
%{color:#FFFFD265} ❗% This feature is still considered experimental, it is possible some changes could be missed especially with a sudden large amount of file operations

%{color:#FFFFD265} ❗% [Sparse files](https://en.wikipedia.org/wiki/Sparse_file) may cause errors and may not be imported properly. Example of sparse files are those created by torrent downloaders, where the file is created to reserve the disk space but not yet filled with the actual data


######__INFO__

%{color:cyan} ❓%  The file system monitor will be started or stopped upon enabling or disabling this option respectively

%{color:cyan} ❓%  Ability to do a background recan for changes on startup (or other configurable intervals) and other options are planned for future versions



