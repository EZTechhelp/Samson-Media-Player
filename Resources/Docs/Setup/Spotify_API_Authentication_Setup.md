### Spotify API Setup and Configuration

**Setup Spotify Web API**
+ Create or use existing Spotify account (free or premium)
+ Follow tutorial to create a Spotify app: [Getting started with Web API](https://developer.spotify.com/documentation/web-api/tutorials/getting-started)
	+ Go to [Spotify Developer Console](https://developer.spotify.com/dashboard)
	+ Click the `Create an app` button
	+ Set `App Name` to `Samson Media Player` (required)
	+ Set `App Description` to whatever you want (required)
	+ Set `Redirect URI` to `http://127.0.0.1:8080/spotishell` (required)
	+ Click the `Developer Terms of Service` checkbox and tap on the `Create` button
+ Once app is created, click on the `Settings` button
+ Click on `View client secret`
+ Use the generated `Client ID` and `Client Secret` values to configure the `Spotify-API-Config.xml` file
+ (Optional - if sharing your build/config with others) Click on `User Management` --> add email of other Spotify accounts that can use your Spotify app to authenticate
	+ Creating a new Spotify app will put it in `Development Mode` which limits the amount of users that can access your app to 25 unless you submit a quota extension request
+ **Modify Spotify API Configuration File**
	+ Open `Spotify-API-Config.xml` file at [[CURRENTFOLDER]\resources\API\Spotify-API-Config.xml]([CURRENTFOLDER]\resources\API\)
	+ Set `RedirectUri` to `http://127.0.0.1:8080/spotishell`
	+ Set `ClientID` and `ClientSecret` values to those you generated from the Web API setup process above
	+ Save file and close