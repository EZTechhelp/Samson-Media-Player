**Enable to use the various Twitch features of this app, including adding, and importing Twitch channels you are subscribed to or follow**. 

**You can automatically import all of your followed Twitch channels from your Twitch account when providing valid Twitch credentials**

#####__IMPORTANT__

   %{color:#FFFFD265} ❗% Valid Twitch Credentials are needed to use the **Import Followed Channels** option, which automatically imports your followed Twitch channels from your account
   
   %{color:#FFFFD265} ❗% If you do not wish to provide your Twitch credentials directly to this app, you can manually add Twitch channel urls using the **Add Twitch Channel** button
   
   %{color:#FFFFD265} ❗% If the **Twitch Credentials** status shows anything other than %{color:LightGreen}**VALID**%, you either need to provide your credentials, update them if they have expired or changed, or the provided credentials did not work
   
   %{color:#FFFFD265} ❗% Credentials provided are **encrypted** using .NET crypto APIs and stored via the Microsoft SecretStore Vault
	 
######__HOW TO USE__
 
 %{color:cyan} 1. % After enabling **Enable Twitch Integration**, you will see the current **Twitch Credentials** status. Click the %{color:LightBlue}**AUTHENTICATE**% link to start the authentication process 
 
 %{color:cyan} 2. % A web authentication **login window** should appear (wait a few seconds if it doesnt show right away). Enter your credentials, following the steps of the login process
 
  - This process is all done through Twitch's web authentication system, which is convieniently displayed to you within this window
 
 %{color:cyan} 3. % Once you have entered your authentication, the login window will close and you should be returned to the Twitch settings page with a message displaying whether authenitcation was successfull.
 
 %{color:cyan} 4. % If **Twitch Credentials** status shows %{color:LightGreen}**VALID**%, you can procceed to import your followed channels using the **Import Followed Channels** button
 
 %{color:cyan} 5. % Depending on how many followed channels you have in your account, it may take a few moments for the list to populate. Once it does you can review the list to add or remove any you dont want to be imported. 
 
 %{color:cyan} 6. % When finished, click **SAVE** or if this is during **First Run Setup** click the **START** button. Your channels will start importing in the background. Once finished you can view them under the **Twitch** tab within the **Media Library**