### YouTube API Setup and Configuration

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
	+ Open `Youtube-API-Config.xml` file at [[CURRENTFOLDER]\resources\API\Youtube-API-Config.xml]([CURRENTFOLDER]\resources\API\)
	+ Set `RedirectUri` to `http://localhost:8000/auth/complete`
	+ Set `client_id` and `Client_Secret` values to those you generated from the oAuth setup process above
	+ Save file and close