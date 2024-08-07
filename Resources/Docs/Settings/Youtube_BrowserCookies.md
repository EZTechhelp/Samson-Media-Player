**Enabling this will instruct** [**YT-DLP**](https://github.com/yt-dlp/yt-dlp) **to import cookies from the default profile of the browser you specify to be used for authentication when getting Youtube videos**

#####__IMPORTANT__

   %{color:#FFFFD265} ❗% This setting only applies as a (limited) alternative for Youtube authentication if you do not provide valid Youtube credentials to this app directly
   
   %{color:#FFFFD265} ❗% This setting does not allow you to import Youtube videos from your account
   
   %{color:#FFFFD265} ❗% This setting applies in the following scenarios:
   
- Playback of Youtube videos with the **Web Player disabled** (Web Player is enabled by default) and no Youtube credentials have been provided. [YT-DLP](https://github.com/yt-dlp/yt-dlp) is used in this scenario
	  
- When manually adding Youtube URLs that are marked as private or from private playlists. [YT-DLP](https://github.com/yt-dlp/yt-dlp) is used in this scenario, otherwise if credentials are available the Youtube API is used
	  
- When **downloading any Youtube videos** to a local file that are marked as private or from private playlists. [YT-DLP](https://github.com/yt-dlp/yt-dlp) is always used when downloading Youtube vidoes


######__USE CASE__
 
 %{color:cyan} ❓% The most common use case for this is usually for downloading Youtube videos. [YT-DLP](https://github.com/yt-dlp/yt-dlp) is always used for downloading, and if any video you attempt to download is private or from a private playlist, authentication will be required. In this use case you should enable this setting
 
 %{color:cyan} ❓% Using this could apply if you do not want to provide your Youtube Credentials to this app or import videos from your account, but you do want to manually add a Youtube video(s) that are marked as private or from a private playlist.
	 
	 
######__HOW TO USE__
 
 %{color:cyan} 1. % Navigate to [Youtube](https://www.youtube.com) from your **Preferred Web Browser** and login with your **Youtube credentials**
 
 %{color:cyan} 2. % After you have successfully logged in to Youtube with you browser, you can then **enable this setting**
 
 %{color:cyan} 3. % Select the browser you used to login to Youtube from the **Select Browser** drop-down
 
 %{color:cyan} 4. % Save/Apply. Then you can then add, download or play private Youtube videos
 
 