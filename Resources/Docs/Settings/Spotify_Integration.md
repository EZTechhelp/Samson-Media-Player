**Enable to use the various Spotify features of this app, including adding, importing and playing Spotify playlists**. 

**You can automatically import all of your playlists from your Spotify account when providing valid Spotify credentials**

#####__IMPORTANT__

   %{color:#FFFFD265} ❗% Valid Spotify Credentials are needed to use the **Import From Spotify** option, which automatically imports playlists from your account
   
   %{color:#FFFFD265} ❗% A **Spotify Premium** account is required to use any Spotify playback features. A non-premium account can import playlists and perform lookups but attempting to control playback will fail
     
   + An experimental option called **Use Spicetify** is available that allows controlling Spotify playback with a non-premium account. Just note that its likely to be a bit buggy.
   
  %{color:#FFFFD265} ❗% For playback of Spotify content, the option **Use Web Player** is enabled by default. Recommend reviewing the help documentation of that setting to decide if you wish to change it. 
   
   %{color:#FFFFD265} ❗% The windows Spotify client does not need to be installed UNLESS you disable the **Use Web Player** option. 
   + The option **Install Spotify** is available to automatically install the windows Spotify client if needed
   
  %{color:#FFFFD265} ❗% If the **Spotify Credentials** status shows anything other than %{color:LightGreen}**VALID**%, you either need to provide your credentials, update them if they have expired or changed, or the provided credentials did not work
   
  %{color:#FFFFD265} ❗% Credentials provided are **encrypted** using .NET crypto APIs and stored via the Microsoft SecretStore Vault
	 
######__HOW TO USE__
 
 %{color:cyan} 1. % After enabling **Enable Spotify Integration**, you will see the current **Spotify Credentials** status. Click the %{color:LightBlue}**AUTHENTICATE**% link to start the authentication process 
 
 %{color:cyan} 2. % A web authentication **login window** should appear (wait a few seconds if it doesnt show right away). Enter your credentials, following the steps of the login process
 
  + This process is all done through Spotify's web authentication system, which is convieniently displayed to you within this window
 
 %{color:cyan} 3. % Once you have entered your authentication, the login window will close and you should be returned to the Spotify settings page with a message displaying whether authenitcation was successfull.
 
 %{color:cyan} 4. % If **Spotify Credentials** status shows %{color:LightGreen}**VALID**%, your Spotify playlists will have imported automatically. If not or you wish to refresh the list, click **Import From Spotify**
 
 %{color:cyan} 5. % Depending on how many playlists and media you have in your account, it may take a few moments for the Spotify list to populate. Once it does you can review the list to add or remove any you dont want to be imported. 
 
 %{color:cyan} 6. % When finished, click **SAVE** or if this is during **First Run Setup** click **Next (>)** button to continue to the next page. Your playlists will start importing in the background. Once finished you can view them under the **Spotify** tab within the **Media Library**
 
 
######__RECORDING__
 
This app provides the ability to sort of simulate 'Downloading' Spotify media to local file by using recording. This option is currently WIP and only available for Spotify media. (Tho Youtube has the ability to download videos directly!)

![recording]([CURRENTFOLDER]\Resources\Docs\Images\Recording.png)

**To record follow these steps:**
 
 
  %{color:cyan} 1. % To record, right-click on any Spotify media track (from library, playlist or queue) and select **Record Media**. You will be prompted for the location where the media will be recorded to.
 
  %{color:cyan} 2. % The track is then loaded and the recorder will begin once playback starts
 
  %{color:cyan} 3. % Once playback finishes, the recorder will stop, convert the recorded media to flac, update metadata and finally save the recording to the locatio you specified. You should receive an notification alert when this is finished
 
 
%{color:#FFFFD265} ❗% **Some important things to be aware of about recording**
 
 + The recorder uses CSCore audio API to listen and record from the systems Loopback Audio. What this means is it records **ANY AUDIO** that is currently being played by Windows using the default audio device.
 + This means that if you have any other audio playing (alerts, web browsers...etc) it will be picked up by the recorder
 + Since it is recording in realtime, if the media is paused or stopped it will interupt or ruin the recording. The recorder monitors the current playing media and stops when it detects the track ended. If you stop the media you will get a warning from the recorder to confirm before stopping
 + The recording ability is still very WIP and new/better methods are being explored to get around this current limitation. These solutions are sort of hacky because Spotify media is DRM protected and encrypted so there is not an easy way to just copy or download the media. 
 + While the recorder saves to a high quality flac, it should be noted that the source audio bitrate is whatever quality Spotify is currently playing as. 
		
	+ With the Web Player this is typically **AAC 256kbit/s** for Spotify Premium
	+ With the Desktop client this ranges from whatever you have configured, from **Low (24kbit/s)** to **Very High (320kbit/s)**
 
 + The ability to choose the recording output format and bitrate is planned (mp3, wav...etc) in addition to hopefully many other improvements
 
 
 
 
