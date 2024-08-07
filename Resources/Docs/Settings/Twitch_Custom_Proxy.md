**Enabling this allows adding custom playlist proxy URLs used by streamlink to block/bypass Twitch ADs. This proxies the playlist request to a country where Twitch does not serve ads**

#####__IMPORTANT__

%{color:#FFFFD265} ❗% %{color:#FFFFD265} Use at your own risk! Seriously make sure you understand all this FIRST!%

%{color:#FFFFD265} ❗% Due to the volatile and unpredictable nature of blocking Twitch ADs, not to mention differences based on where you live, it cannot be guaranteed that this will work. It may break at any time

%{color:#FFFFD265} ❗% This setting has no effect if **Use YTDLP for Twitch Streams** is enabled

%{color:#FFFFD265} ❗% Loading streams may take longer, potentially up to around 10 seconds, depending on the proxy you use. (This doesn't affect the latency.)

%{color:#FFFFD265} ❗% Depending on your connection and where you are, there is a greater chance to experience buffering or stuttering

%{color:#FFFFD265} ❗% Proxy urls added need to support the TTVLOL API

%{color:#FFFFD265} ❗% The proxies are attempted in order that they are added/listed, falling back down the list if one fails

######__Known compatible public proxy servers__

*This list is not guaranteed to be up-to-date*

**Official luminous-ttv servers:**

+ https://eu.luminous.dev (Europe)
+ https://eu2.luminous.dev (Europe 2)
+ https://as.luminous.dev (Asia)

**Official TTV-LOL-PRO v1 servers:**

+ https://lb-eu.cdn-perfprod.com (Europe)
+ https://lb-eu2.cdn-perfprod.com (Europe 2)
+ https://lb-eu3.cdn-perfprod.com (Europe 3)
+ https://lb-eu4.cdn-perfprod.com (Europe 4)
+ https://lb-eu5.cdn-perfprod.com (Europe 5)
+ https://lb-na.cdn-perfprod.com (NA)
+ https://lb-as.cdn-perfprod.com (Asia)


######__INFO__

 %{color:cyan} ❓% This requires using a custom modified Twitch plugin for Streamlink called **streamlink-ttvlol**. When this option is enabled, a file called 'twitch.py' will be copied into the Streamlink plugins folder at [C:\Users\[USERNAME]\AppData\Roaming\streamlink\plugins](C:\Users\[USERNAME]\AppData\Roaming\streamlink\plugins)
 
 %{color:cyan} ❓% Visit [streamlink-ttvlol](https://github.com/2bc4/streamlink-ttvlol) if you want to learn more