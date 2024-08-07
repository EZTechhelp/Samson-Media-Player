**Enables support for casting media during playback to other UPnP/DLNA supported devices**

#####__IMPORTANT__

%{color:#FFFFD265} ❗% This feature is currently VERY early, VERY WIP and likely wont work or will cause other issues. Only enable if you are ok with the risks, know what you are doing or are helping with testing
   
%{color:#FFFFD265} ❗% The cast media button is currently located within the video player overlay controls. The **Enable Media Casting Support** option must be enabled to use it

%{color:#FFFFD265} ❗% When casting media for steaming video (Twitch streams..etc) it will create an HTTP port on 127.0.0.1. The port defaults to 8080 unless another is provided under **Media Casting HTTP Port**
       
%{color:#FFFFD265} ❗% When casting media or when disabling an existing cast, playback is momentarily paused/disrupted to enable the casting features.	

%{color:#FFFFD265} ❗ While casting, you can no longer mute or change the volume from this media player. Libvlc locks them out while 'Streaming'. Looking into workarounds%
+ This is intentional as with DLNA, the idea is this media player becomes the media source, and control is moved to the device casted to

%{color:#FFFFD265} ❗% Casting only works if there is supported media currently playing and loaded.  
+  A list of supported media for casting is not finalized/ready yet, but generally anything that plays using the native player only. So local media or Youtube without the Web Player enabled.

######__HOW TO USE CASTING__
 
+  When clicking on the cast media button a menu will pop-up displaying all supported devices that can be cast to on your local network
+  Click on **Rescan Now** to refresh the list. Try not to spam the refresh, the probing can sometimes cause timeouts on the devices
+  If a supported device is shown, make sure you are playing media first, then select the device to begin casting to
+  Wait a few moments, depending on the device, the media and other factors it can take a good 5 - 15secs. Media playback may pause/flash a few times
+  To stop casting, just unselect the device from the Casting Button menu or just stop playback
    + %{color:#FFFFD265} ❗ Performing a Rescan of devices while casting might disrupt or end your current cast%
 
######__INFO__
 
%{color:cyan} ❓% A utility called go2tv is used to do the casting to devices, acting as a streaming-bridge
+ To view more info about the go2tv utility, go to [go2tv](https://github.com/alexballas/go2tv)