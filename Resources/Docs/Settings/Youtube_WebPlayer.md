**Enables playback of Youtube media using an embedded Web player powered by Microsoft Edge (webview2), vs the native in app player.** 

**Playback experience will be similiar as when playing Youtube media via a webbrowser, with a few differences as listed below**

#####__IMPORTANT__

Using the Web Player allows generally improved performance, mostly related to the time between when you press Play to the time playback starts

However, you lose some functionality vs the native player, such as:

   %{color:#FFFFD265} ❗% EQ and similiar Audio settings. All audio is output through the web player which is a separate process from the main app.  
- Note: You can still use the apps native controls for things like Volume, Mute, Play, Pause or Stop
   
%{color:#FFFFD265} ❗% Its possible some Youtube ADs may appear that do not when using the native player. This app has a simple custom Youtube AdBlocker that should block most of them, but can't be guaranteed to get them all
   
   %{color:#FFFFD265} ❗% You may see some ADs start and then quickly dissappear, as well as video seemingly switching back and forth rapidly from 'fullscreen' to normal. This may happen due to how the AD blocker works, and from various methods used to get around Youtube's (stupid) restrictions on what videos can and cannot be used with an 'Embedded' player.

%{color:#FFFFD265} ❗% Media played using the Web Players (which is the default for Spotify and Youtube), may not start until the video player is opened
+ This is because the Web Players that play the content don't fully initialize until they are actually shown or become visible
+ Some tricks are used to try and get around this limitation but results vary. Hopefully this can be further improved in the future
+ Enabling the option **Auto Open/Close Video Player** under the General tab helps ensure the media will start playing in these scenerios

######__INFO__

 %{color:cyan} ❓% By default, playback of Youtube media via the Web Player uses the standard (official) Youtube embedded player interface. Alternatively, you can enable the 'Use Invidious' option.
 
 %{color:cyan} ❓% Some info about the 'Use Invidious' option and why you might use it:
 
  - Invidious is Open-Source software, which we like
  - May provide better ability to fully embed videos when the Youtube embedded player wont allow it (such as various restricted videos for age, licensiing..etc)
  - Prevents Google from tracking you or what your watching (if that matters to you). Requests are proxied and anonomized through the Invidious server
  - Most if not all videos are AD free
  
For more information, visit [Invidious.io](https://invidious.io)