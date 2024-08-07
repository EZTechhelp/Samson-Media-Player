**When enabled, the progress of the current playing media is saved when the app is closed.** 

**The next time the app is started, it will begin playback at the saved progress time**

#####__IMPORTANT__

%{color:#FFFFD265} ❗% Right now this only applies when playing **Local Media**. Support for other media types are planned
+ If you have the **Use Web Player** option for Youtube (which is the default), playback progress *MAY* be saved anyway due to the nature of how the web players work
+ Web Players are basically just like most web browsers, and cookies and other temp data is stored in the temp folder. Provided that data isn't deleted, playback of media may resume where you left off

%{color:#FFFFD265} ❗% Progress is only saved if the app is closed while playing or paused. Progress is not saved for media that ends on its own or when manually stopped

%{color:#FFFFD265} ❗% If the loaded media contains video, the video player will automatically open

######__INFO__

%{color:#FFFFD265} ❗% If there is saved media progress upon the next startup of the app, it will automatically load that media and begin playback from the saved progress time. 
 + You can optionally enable the `Start Paused` setting to instead have the media load as paused at the saved progress time

%{color:cyan} ❓% The purpose of this option is to allow you to resume listening to media at the same spot in the event you close the app while playing or perhaps if the app happens to crash (hopefully that doesn't happen!). 

