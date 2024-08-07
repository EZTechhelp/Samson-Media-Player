**Enables playback of Spotify media using an embedded Web player powered by Microsoft Edge (webview2)** 

#####__IMPORTANT__

These are some of the functionality differences when playing Spotify media vs local media (applies whether using Web Player or not):

%{color:#FFFFD265} ❗% To use EQ and similiar audio filtering settings, you need to enable `Enable EQ Support for Webplayers` on the General tab. 
+ See the help option for `Enable EQ Support for Webplayers` for more info
+ Note: All other native controls should work as normal for things like Volume, Mute, Play, Pause, Stop, Next..etc

%{color:#FFFFD265} ❗% Media played using the Web Players may have a few seconds (or more) delay before starting, which is normal. 
+ If media hasn't started within about 10secs or so, try restarting playback or check for errors in the logs

######__INFO__

 %{color:cyan} ❓% Using the Web Player usually provides improved performance, mostly related to the time between when you press Play to the time playback starts. Its also just works more consistently
 
 %{color:cyan} ❓% When using the Web Player, the audio quality is typically **AAC 256kbit/s** for Spotify Premium or **AAC 128kbit/s** for Spotify free (this app doesnt support free accounts using the web player for playback but just for reference)
 + For free Spotify accounts, you must use and enable the `Use Spicetify` option
 
 
 
