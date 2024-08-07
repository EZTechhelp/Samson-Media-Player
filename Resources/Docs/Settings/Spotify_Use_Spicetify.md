**Enables use of Spicetify which customizes the Spotify windows client in order to allow direct control of playback and retrieve media status. This option is required when using a free Spotify account.** 

#####__IMPORTANT__

%{color:#FFFFD265} ❗% Using this option requires having the Windows Spotify client installed and you must be logged in to the client with your Spotify account.

%{color:#FFFFD265} ❗% Spicetify makes direct modifications to the Windows Spotify client, injecting custom code. Highly recommend visiting [Spicetify](https://spicetify.app/) to read more about what Spicetify does. If you are not comfortable with these modifications, leave this option disabled. 
+ You may notice a new tab/option in the Spotify client called 'Marketplace' after enabling Spicetify. Here you can install other plugins or extensions to change how Spotify works if you desire.
+ If you wish to revert or remove these changes, click the `Remove From Spotify` button. This will reset Spotify client to its default state

%{color:#FFFFD265} ❗% Updates to the Spotify client may break the customizations made by Spicetify. If this happens, you can re-apply the customizations using the 'Apply to Spotify' button. If Spicetify stops working, [appname] will revert to using the Spotify API if possible, though if your using a free Spotify account that will always fail. 

%{color:#FFFFD265} ❗% To use EQ and similiar audio filtering settings, you need to enable `Enable EQ Support for Webplayers` on the General tab. I should probably rename that setting...
+ See the help option for `Enable EQ Support for Webplayers` for more info
+ Note: All other native controls should work as normal for things like Volume, Mute, Play, Pause, Stop, Next..etc

######__INFO__

 %{color:cyan} ❓% Spicetify can also be used with premium Spotify accounts, though using the Web Player is highly recommended. 
 
 %{color:cyan} ❓% Without using Spicetify (or web player), playback control of the Spotify client can only be handled using Spotify Web API calls (which require Spotify Premium), since Spotify no longer supports direct control of the Windows app programmically. While this works, it can be less reliable, as a web API call is needed anytime a command needs to be sent or when getting playback status/progress. This can result in a delay between issuing a command and Spotify responding or sometimes it can fail alltogether
 
 %{color:cyan} ❓% Spicetify is used by [appname] to inject a customized version of the Webnowplaying extension which originally was designed to allow Spotify to work with Rainmeter. [appname] uses the PowerShell module `PODE` to create a local Websocket server `127.0.0.1` on port `8974`. The customized Webnowplaying extension allows Spotify to connect to this Websocket to relay playback data and accept commands from [appname], such as Play/Pause, next, previous, repeat, loop...etc. This also allows controlling Spotify by sending commands directly to the Spotify client, vs over the web using the API.