**Selects the preferred quality when fetching stream/download URLs for Youtube videos, as well as sets the preferred quality level for playback when using the Youtube Webplayer. The default is 'Auto'**

#####__IMPORTANT__

   %{color:#FFFFD265} ❗% It cannot be guaranteed that the preferred setting will take effect for playback of Youtube videos using the **Web Player**, as the current implementation is dependant on the whims of Youtube
   
   %{color:#FFFFD265} ❗% It may also vary depending on the video being played. As of this app version ([appversion]), it should work most of the time 
   
   %{color:#FFFFD265} ❗% The actual logic used to determine the quality you get is usually up to Youtube. The 'official' method to set video quality via the Youtube API is technically no longer supported. While the method in use here still works, it may stop at any time or not work consistantly 
   
   %{color:#FFFFD265} ❗% If your concerned about playing via 4k which chews up bandwidth and CPU/GPU resources, try setting it to **'Medium'** or lower.

######__INFO__

 %{color:cyan} ❓% The quality set here also determines the quality when **Downloading or Playing Youtube Videos** via [YT-DLP](https://github.com/yt-dlp/yt-dlp), which is used for playback when the Youtube Web Player option is disabled, and always used when downloading videos 
 
