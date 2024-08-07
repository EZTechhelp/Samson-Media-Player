**Enables ability to use the Web EQ option under Audio Settings to enable audio equalizer when using Web Players. This allows audio equalization control for Youtube and Spotify playback**

#####__IMPORTANT__

%{color:#FFFFD265} ❗% When enabled, a new Windows virtual audio device (VB-Cable) will be installed which is required to reroute audio from Web Player processes to a device that can be captured and played back using the native libvlc engine

%{color:#FFFFD265} ❗% When the virtual audio device (VB-Cable) is being installed, you may notice your default audio output device may change temporarily to the new virtual device, then back again. This is why/how it works:

 - When installing a new audio device in windows, it automatically sets it as the default. (Windows audio amiright?) 
 - To combat this, this app captures the current default device before installing, installs the virtual audio device, then force changes the default device back to the original. 
 - Its always possible this could somehow not work (Windows audio amiright?). So be sure to check your default audio output device after installing or if you suddenly lose sound

%{color:#FFFFD265} ❗% After enabling this option and the virtual audio device is installed, a restart of your computer **MIGHT** be required. In testing a restart wasnt usually needed but it is still recommended. 

%{color:#FFFFD265} ❗% Disabling this option will prompt permission to uninstall and remove the virtual audio device (VB-Cable), which may also require a restart of your computer. If you want to leave VB-Cable installed (or use it for something else) be sure to select NO when prompted to remove it when disabling this option.

%{color:#FFFFD265} ❗% The Web EQ will only affect audio output/routing for the specific webplayer process that is playing audio and **does not change or otherwise effect audio input/output devices and how they are routed**. However, Windows is notoriously 'touchy' with audio devices (Windows audio amiright?) and potentially even just installing a new audio device could somehow effect systems with custom audio input/output setups. Steps are taken to avoid this and its not likely to be an issue but this is your warning all the same

%{color:#FFFFD265} ❗% The virutal audio device that gets installed is [VB-Cable](https://vb-audio.com/Cable/). If for some reason you already have this installed for other reasons, its possible the Web EQ could conflict or cause issues depending on what your using it for, so fair warning.


#####__TROUBLESHOOTING/TIPS__
%{color:cyan} ❓% If you are experiencing audio stuttering or other quality issues, you may need to adjust the sampling rate for VB-Cable and/or within windows audio properties
 
 - Open the VB-Cable control panel located at: [C:\Program Files\VB\CABLE\VBCABLE_ControlPanel.exe](C:\Program Files\VB\CABLE\VBCABLE_ControlPanel.exe)
 - Check the sample rate (SR) values for Internal SR, Input SR, and Output SR. If they are not all the same value, you may need to adjust them all to match. 
 - To change Interal SR, in the VB-Cable control panel, click options - and choose "Internal Sampling Rate x" where x is the sampling rate you want to set. For example, a common SR would be 48000hz. The biggest thing is that you choose one that matches both Input and Output
 - To change Input or Output SR, go to the windows sound control panel. Easiest way is to right-click on the sound icon in the system tray and select "sounds". In the Playback tab, find "Cable Input" and go to properties - advanced tab and select the Default format
 - When selecting Default Format in the windows sound properties, choose the value that will match all values shown in VB-Cable control panel, also making sure to note the RES (16bit or 24bit) which should also match on both input and output. 
 - Perform the same steps for "Cable Output" under the "Recording" tab of sound properties in windows. 
 - Making these changes (at least in VB-Cable control panel) will require a computer restart. Even if it doesnt prompt its recommended to restart anyway
 
%{color:cyan} ❓% If you are experiencing audio delay/desync when watching videos
 
 - Open the VB-Cable control panel located at: [C:\Program Files\VB\CABLE\VBCABLE_ControlPanel.exe](C:\Program Files\VB\CABLE\VBCABLE_ControlPanel.exe)
 - Check the sample rate (SR) values for Internal SR, Input SR, and Output SR. If they are not all the same value, you may need to adjust them all to match. Follow steps outlined above
 - If all SR values match, you may try adjusting the "Max Latency". The default value varies by system but generally Max Latency defaults to around 7186
 - To change the latency value, click Options - and select a new Max Latency value. Try selecting one value lower than your current setting. So if its currently 7186, try 6144. Every change to this setting requires a computer restart
 - After changing, testing playback and if the audio is not stuttering, crackling or distoring, you can then proceed to try lowering the latency value again to a lower value. Repeat this until you run into audio issues, then revert back to the lowest value that worked without audio issues
 - **NOTE**: Samson cannot reliably set these values by default for you as every audio system and setup is going to be different. While it should be possibe to reduce delay to barely noticable levels, there is always going to be some small delay that is unavoidable. 
 

######__INFO__
 %{color:cyan} ❓% Its not normally possible to use the apps native EQ for playback of web players, which both Spotify and Youtube playback use by default. This is because webplayers play using a separate process (webview2). This is similiar to playing media using a web browser.
 
 %{color:cyan} ❓% Enabling this option allows a way around this limitation by installing a virtual audio device. Then when playing media from webplayers with the EQ enabled, the audio output of the webplayer process (and only the specific web player process producing audio) is rerouted to the virtual audio device input. The apps native audio engine (libvlc) then plays back that audio from the virtual audio device, which allows applying audio and other filters like the EQ