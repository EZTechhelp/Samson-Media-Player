### Twitch API Setup and Configuration

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
	+ Open `Twitch-API-Config.xml` file at [[CURRENTFOLDER]\resources\API\Twitch-API-Config.xml]([CURRENTFOLDER]\resources\API\)
	+ Set `RedirectUri` to `http://localhost:8181/Twitch`
	+ Set `ClientID` and `ClientSecret` values to those you generated from the oAuth setup process above
	+ Save file and close