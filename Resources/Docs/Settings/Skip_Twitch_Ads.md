**Enabling instructs streamlink to skip Pre-Roll, Mid-Roll and other ADs when playing Twitch streams**

#####__IMPORTANT__
%{color:#FFFFD265} ❗% It is important to note that this will %{color:#FFFFD265}**NOT BLOCK ADs**%, at least not normally. While ADs are being skipped, playback will pause/stop. The media title/display should change to 'Skipping Ads' or similiar while this happens. 

Sometimes you may see a Purple screen saying 'Commercial Break In Progress', sometimes not. There have even been long stretches where no Ads would play at all. Twitch changes things all the time and there is a forever fight between Twitch and 'AD blockers'

%{color:#FFFFD265} ❗% If you are a subscriber to a channel and want to make sure you dont see ADs, make sure this option is **ENABLED** and follow these steps at least one time successfully:

1. %{color:#FFFFD265}**Enable Twitch Integration**%
2. %{color:#FFFFD265}**Click the Authenticate Link**%
3. %{color:#FFFFD265}**Login with your Twitch Credentials**%
4. %{color:#FFFFD265}**Verify Twitch Credentials shows as [VALID]**%

Doing this will extract the Twitch authentication cookie needed to pass to Twitch streams. The reason for this weird way of authentication is because of how Twitch authorizes streams. Authorization must come from the Twitch.tv website itself vs the API.

######__INFO__
%{color:cyan}❓% The audio can also be muted/unmuted automatically by additionally enabling the 'Mute Twitch Ads' option below this one (default is off)

%{color:cyan}❓% Twitch streams are primarily handled by Streamlink, unless the Force Use YT-DLP option is enabled. Sometimes, a streamlink release seemingly blocks all Twitch Ads, but that usually doesnt last long. 

Visit [https://streamlink.github.io](https://streamlink.github.io) if you want to learn more

######%{color:#FFFFD265}__BLOCKING ADS__%
If you want to try a another method to actually **BLOCK** ADs, review the settings  **Use Twitch TTVLOL Proxy** or **Use Luminous Proxy**