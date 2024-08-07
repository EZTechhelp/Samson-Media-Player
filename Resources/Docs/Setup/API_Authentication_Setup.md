### API Setup and Configuration

**Setup Spotify Web API**
+ Create or use existing Spotify account (free or premium)
+ Follow tutorial to create a Spotify app: [Getting started with Web API](https://developer.spotify.com/documentation/web-api/tutorials/getting-started)
	+ Go to [Spotify Developer Console](https://developer.spotify.com/dashboard)
	+ Click the `Create an app` button
	+ Set `App Name` to `Samson Media Player` (required)
	+ Set `App Description` to whatever you want (required)
	+ Set `Redirect URI` to `http://localhost:8080/spotishell` (required)
	+ Click the `Developer Terms of Service` checkbox and tap on the `Create` button
+ Once app is created, click on the `Settings` button
+ Click on `View client secret`
+ Use the generated `Client ID` and `Client Secret` values to configure the `Spotify-API-Config.xml` file
+ (Optional - if sharing your build/config with others) Click on `User Management` --> add email of other Spotify accounts that can use your Spotify app to authenticate
	+ Creating a new Spotify app will put it in `Development Mode` which limits the amount of users that can access your app to 25 unless you submit a quota extension request
+ **Modify Spotify API Configuration File**
	+ Open `Spotify-API-Config.xml` file at `/resources/API/Spotify-API-Config.xml`
	+ Set `RedirectUri` to `http://localhost:8080/spotishell`
	+ Set `ClientID` and `ClientSecret` values to those you generated from the Web API setup process above
	+ Save file and close

**Setup YouTube API oAuth**
+ Create or use existing Google account (free)
+ Create a [Google Cloud Project](https://console.cloud.google.com/)
+ Add the [YouTube Data API v3](https://console.cloud.google.com/marketplace/product/google/youtube.googleapis.com) to your project
+ Go to `APIs & Services` --> `Credentials`
+ Choose `Create Credentials` --> `oAuth Client ID`
+ For `Application Type`, choose `Web Application`
+ Use the generated `Client ID` and `Client Secret` values to configure the `Youtube-API-Config.xml` file
+ Add the `RedirectURI` of `http://localhost:8000/auth/complete`
+ **Modify YouTube API Configuration File**
	+ Open `Youtube-API-Config.xml` file at `/resources/API/Youtube-API-Config.xml`
	+ Set `RedirectUri` to `http://localhost:8000/auth/complete`
	+ Set `client_id` and `Client_Secret` values to those you generated from the oAuth setup process above
	+ Save file and close
 
**Setup Twitch API oAuth**
+ Create or use existing Twitch account (free)
+ Go to the [Twitch Developer Console](https://dev.twitch.tv/console)
+ Create new application by clicking on `Register Your Application`
	+ Set `Name` to `Samson Media Player` (required)
	+ Add URL `http://localhost:8181/Twitch` to `OAuth Redirect URLs` (required)
	+ Set `Category` to `Application Integration` (required)
	+ Set `Client Type` to `Confidential`
+ Once created, use the generated `Client ID` and `Client Secret` values to configure the `Twitch-API-Config.xml` file
+ **Modify Twitch API Configuration File**
	+ Open `Twitch-API-Config.xml` file at `/resources/API/Twitch-API-Config.xml`
	+ Set `RedirectUri` to `http://localhost:8181/Twitch`
	+ Set `ClientID` and `ClientSecret` values to those you generated from the oAuth setup process above
	+ Save file and close