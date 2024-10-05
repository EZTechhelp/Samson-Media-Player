<#
    .Name
    Get-Twitch

    .Version 
    0.3.0

    .SYNOPSIS
    Retrieves data from Twitch API for stream/broadcast status and performs processing for Twitch profiles 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-TwitchApplication Function
#----------------------------------------------
function Get-TwitchApplication {
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [String]$Name = $thisApp.Config.App_Name,
    $log = $thisApp.Config.TwitchMedia_logfile,
    [switch]$All
  )

  if (!$Name) { $Name = 'Samson' }
  try{
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "[Get-TwitchApplication] An exception occurred getting SecretStore $name" -showtime -catcherror $_
    return
  }
  if($secretstore){
    if([string]::IsNullOrEmpty($thisApp.TwitchAPI.ClientId) -or [string]::IsNullOrEmpty($thisApp.TwitchAPI.ClientSecret) -or [string]::IsNullOrEmpty($thisApp.TwitchAPI.Redirect_URLs)){
      try{
        $APIXML = "$($thisApp.config.Current_Folder)\Resources\API\Twitch-API-Config.xml"
        if([System.IO.File]::Exists($APIXML) -and !$thisApp.TwitchAPI){
          write-ezlogs "[Get-TwitchApplication] >>>> Importing API Config file $APIXML" -showtime -logtype Twitch -Dev_mode
          $thisApp.TwitchAPI = Import-SerializedXML -Path $APIXML -isAPI
        }
      }catch{
        write-ezlogs "An exception occurred getting clientid or clientsecret from API Config file: $APIXML" -catcherror $_
      }
    }  
    try{
      $access_token = Get-secret -name Twitchaccess_token -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "[Get-TwitchApplication] An exception occurred getting Secret Twitchaccess_token" -showtime -catcherror $_
    }finally{
      if(!$access_token){
        try{
          write-ezlogs "[Get-TwitchApplication] Unable to get Twitchaccess_token from vault $Name - trying again in case of transient issue" -showtime -warning -logtype Twitch
          [System.Threading.Thread]::Sleep(500)
          $access_token = Get-secret -name Twitchaccess_token -Vault $Name -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "[Get-TwitchApplication] An exception occurred on the second attempt getting Secret Twitchaccess_token" -showtime -catcherror $_
        }
      }
    }       
    if($access_token -and $thisApp.TwitchAPI.ClientSecret){
      try{
        $expires = Get-secret -name Twitchexpires -Vault $Name -ErrorAction SilentlyContinue
        $scope = Get-secret -name Twitchscope -Vault $Name -ErrorAction SilentlyContinue   
        $refresh_token = Get-secret -name Twitchrefresh_token -Vault $Name -ErrorAction SilentlyContinue
        $token_type = Get-secret -name Twitchtoken_type -Vault $Name -ErrorAction SilentlyContinue
        $Token = [PSCustomObject]::new(@{
            'expires' = $expires
            'scope' = $scope
            'refresh_token' = $refresh_token
            'token_type' = $token_type
            'access_token' = $access_token
        })            
      }catch{
        write-ezlogs "[Get-TwitchApplication] An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
      }        
    }else{
      write-ezlogs "[Get-TwitchApplication] Unable to find Twitch Access Token from Secret Vault $name - Clientid: $($thisApp.TwitchAPI.ClientID)!" -showtime -warning -logtype Twitch
      #write-ezlogs "[Get-TwitchApplication] Secret Store Config: $($Secret_store_config | out-string)" -showtime -logtype Twitch
      $APIXML = "$($thisApp.config.Current_Folder)\Resources\API\Twitch-API-Config.xml"
      if([System.IO.File]::Exists($APIXML)){
        write-ezlogs "[Get-TwitchApplication] >>>> Importing API Config file $APIXML" -showtime -logtype Twitch -Dev_mode
        $thisApp.TwitchAPI = Import-SerializedXML -Path $APIXML -isAPI
      }
    }               
  }else{
    Write-ezlogs "[Get-TwitchApplication] No SecretStore found called $Name" -warning -showtime -logtype Twitch
    $APIXML = "$($thisApp.config.Current_Folder)\Resources\API\Twitch-API-Config.xml"
    if([System.IO.File]::Exists($APIXML)){
      write-ezlogs "[Get-TwitchApplication] >>>> Importing API Config file $APIXML" -showtime -logtype Twitch -Dev_mode
      $thisApp.TwitchAPI = Import-SerializedXML -Path $APIXML -isAPI
    }
    if($thisApp.TwitchAPI.ClientSecret -and $thisApp.TwitchAPI.ClientID){
      write-ezlogs "[Get-TwitchApplication] >>>> Setting new SecretStoreConfiguration with password set to $Name (Scope: CurrentUser)" -showtime -logtype Twitch
      Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
    }else{
      write-ezlogs "[Get-TwitchApplication] API config not found, unable to set secretstoreconfiguration!" -showtime -warning -logtype Twitch
      return
    }
    write-ezlogs "[Get-TwitchApplication] >>>> Registering new SecretVault: $name" -showtime -logtype Twitch
    try{
      $secretstore = Register-SecretVault -Name $Name -ModuleName "$($thisApp.Config.Current_Folder)\Modules\Microsoft.PowerShell.SecretStore" -DefaultVault -Description "Created by $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -PassThru
    }catch{
      write-ezlogs "An exception occurred registering new secretvault with name $Name" -catcherror $_
    }
    #Register-SecretVault -Name $Name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction SilentlyContinue
  }  
  $Auth = [PSCustomObject]::new(@{
      'RedirectUri' = $thisApp.TwitchAPI.Redirect_URLs
      'Name' = $Name
      'ClientId' = $thisApp.TwitchAPI.ClientID
      'ClientSecret' = $thisApp.TwitchAPI.ClientSecret
      'Token' = $Token
  })
  $secretstore = $Null     
  $PSCmdlet.WriteObject($auth)
}
#---------------------------------------------- 
#endregion Get-TwitchApplication Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-TwitchApplication Function
#----------------------------------------------
function Set-TwitchApplication {

  param(
    [string]
    $Name = $thisApp.Config.App_Name,

    [Parameter(Mandatory, ParameterSetName = "ClientIdAndSecret")]
    [String]
    $ClientId,

    [Parameter(Mandatory, ParameterSetName = "ClientIdAndSecret")]
    [String]
    $ClientSecret,

    [String]
    $RedirectUri,

    [Parameter(Mandatory, ParameterSetName = "Token")]
    $Token
  )

  $Application = Get-TwitchApplication -Name $thisApp.Config.App_Name
  
  # Try to save application to file.
  try {
    # Update Application
    if($Application.Name){
      write-ezlogs ">>>> Saving Twitch Secrets for application $($Application.Name)" -showtime -logtype Twitch -LogLevel 2
      $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
      if($secretstore){  
        $Application = Get-TwitchApplication -Name $thisApp.Config.App_Name
        if([string]::IsNullOrEmpty($Application.ClientId) -or [string]::IsNullOrEmpty($Application.ClientSecret)){
          $APIXML = "$($thisApp.config.Current_Folder)\Resources\API\Twitch-API-Config.xml"
          if([System.IO.File]::Exists($APIXML)){
            write-ezlogs "[Set-TwitchApplication] >>>> Importing API Config file $APIXML" -showtime -logtype Twitch -Dev_mode
            $Twitch_API = Import-SerializedXML -Path $APIXML -isAPI
            $clientID = $Twitch_API.ClientID
            $clientsecret = $Twitch_API.ClientSecret
          }
        }else{
          $clientID = $Application.ClientId
          $clientsecret = $Application.ClientSecret
        }
        if ($clientID) { 
          write-ezlogs "[Set-TwitchApplication] | TwitchClientId: $($clientID)" -showtime -logtype Twitch -Dev_mode
          Set-Secret -Name TwitchClientId -Secret "$($clientID)" -Vault $Name
        }
        if ($clientsecret) {   
          write-ezlogs "[Set-TwitchApplication] | TwitchClientSecret: $($clientsecret)" -showtime -logtype Twitch -Dev_mode
          Set-Secret -Name TwitchClientSecret -Secret "$($clientsecret)" -Vault $Name
        }
        if ($RedirectUri) { 
          write-ezlogs "[Set-TwitchApplication] | TwitchRedirectUri: $($RedirectUri)" -showtime -logtype Twitch -LogLevel 2
          Set-Secret -Name TwitchRedirectUri -Secret "$($RedirectUri)" -Vault $Name
        }
        if ($Token.expires) {
          write-ezlogs "[Set-TwitchApplication] | Twitchexpires: $($Token.expires)" -showtime -logtype Twitch -LogLevel 2
          Set-Secret -Name Twitchexpires -Secret "$($Token.expires)" -Vault $Name
        }
        if ($Token.access_token) {
          write-ezlogs "[Set-TwitchApplication] | Twitchaccess_token: $($Token.access_token)" -showtime -logtype Twitch -Dev_mode
          Set-Secret -Name Twitchaccess_token -Secret "$($Token.access_token)" -Vault $Name
        }
        if ($Token.scope) {
          write-ezlogs "[Set-TwitchApplication] | Twitchscope: $($Token.scope)" -showtime -logtype Twitch -LogLevel 2
          Set-Secret -Name Twitchscope -Secret "$($Token.scope)" -Vault $Name
        }
        if ($Token.refresh_token) {
          write-ezlogs "[Set-TwitchApplication] | Twitchrefresh_token: $($Token.refresh_token)" -showtime -logtype Twitch -Dev_mode
          Set-Secret -Name Twitchrefresh_token -Secret "$($Token.refresh_token)" -Vault $Name
        }        
        if ($Token.token_type) {
          write-ezlogs "[Set-TwitchApplication] | Twitchtoken_type: $($Token.token_type)" -showtime -logtype Twitch -LogLevel 2
          Set-Secret -Name Twitchtoken_type -Secret "$($Token.token_type)" -Vault $Name
        }                                   
      }
    }else{
      Write-ezlogs "Unable to find existing Twitch Application $name - Use New-TwitchApplication to create a new one" -showtime -warning -logtype Twitch -LogLevel 2
    }
  }catch {
    write-ezlogs "Failed updating SecretStore $Name : $($PSItem[0].ToString())" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Set-TwitchApplication Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TwitchAccessToken Function
#----------------------------------------------
function Get-TwitchAccessToken {

  [CmdletBinding()]
  param (
    [String]
    $ApplicationName,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $thisScript,
    [switch]$noAuthCapture,
    [switch]$verboselog = $thisApp.Config.Dev_mode,
    [switch]$First_Run,
    [switch]$ForceTokenRefresh
  )

  # Get Application
  if(!$ApplicationName -and $thisApp.Config.App_Name){
    $ApplicationName = $thisApp.Config.App_Name
  }
  try{
    $Application = Get-TwitchApplication -Name $ApplicationName
  }catch{
    write-ezlogs "An exception occurred getting Twitch Application $Application" -showtime -catcherror $_
  }

  # If Token is available
  if (-not [string]::IsNullOrEmpty($Application.Token.access_token) -and -not [string]::IsNullOrEmpty($Application.Token.Expires)) {
    # Check that Access Token is not expired
    try{       
      $Expires = [DateTime]::ParseExact($Application.Token.Expires, 'u', $null)
      $Expire_status = ([DateTime]::Now) -le $Expires.AddSeconds(-10)     
    }catch{
      write-ezlogs "An exception occurred parsing token expiration from application $($application | out-string)" -showtime -catcherror $_
    }
    
    if ($Expire_status -and !$ForceTokenRefresh) {
      # Access Token is still valid, then use it
      if($Verboselog){write-ezlogs "Twitch Access Token is still valid: $($Expires)" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
      return $Application.Token.access_token
    } else {
      # Access Token is expired, need to be refreshed
      write-ezlogs "Refreshing Twitch Access Token -- ForceTokenRefresh: $($ForceTokenRefresh) -- Expires: $($Expires)" -showtime -warning -logtype Twitch -LogLevel 2
      # ------------------------------ Token Refreshed retrieval ------------------------------
      # STEP 1 : Prepare
      $Uri = 'https://id.twitch.tv/oauth2/token'
      $Method = 'Post'
      $Body = @{
        grant_type    = 'refresh_token'
        refresh_token = $Application.Token.refresh_token
        client_id     = $Application.ClientId # alternative way to send the client id and secret
        client_secret = $Application.ClientSecret # alternative way to send the client id and secret
      }

      # STEP 2 : Make request to the Twitch Accounts service
      try {
        Write-ezlogs "Sending request to refresh access token: $($Uri) | Body $($Body)" -showtime -logtype Twitch -LogLevel 2
        $CurrentTime = Get-Date
        $Response = Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -UseBasicParsing
      }catch {
        # Don't throw error if Refresh token is revoked or authentication failed
        if ($_.Exception.Response.StatusCode -ne 400 -and $_.Exception.Response.StatusCode -ne 401) {
          write-ezlogs "Error occured during request of refreshed access token : $([int]$_.Exception.Response.StatusCode) - $($PSItem[0].ToString())" -showtime -catcherror $_
        }
      }

      # STEP 3 : Parse and save response
      if ($Response) {
        $ResponseContent = $Response #| ConvertFrom-Json
        $Token = @{
          access_token  = $ResponseContent.access_token
          token_type    = $ResponseContent.token_type
          scope         = $ResponseContent.scope
          expires       = $CurrentTime.AddSeconds($ResponseContent.expires_in).ToString('u')
          refresh_token = if ($ResponseContent.refresh_token) { $ResponseContent.refresh_token } else { $Application.Token.refresh_token }
        }
        Set-TwitchApplication -Name $ApplicationName -Token $Token -RedirectUri $Application.RedirectUri
        Write-ezlogs '[Get-TwitchAccessToken] Successfully saved Twitch Refreshed Token' -showtime -logtype Twitch -LogLevel 2 -Success
        return $Token.access_token
      }
    }
  }else{
    if($noAuthCapture){
      write-ezlogs "Unable to get Twitch access token" -showtime -warning -logtype Twitch -LogLevel 2
      return
    }else{
      write-ezlogs "Unable to get Twitch access token - Starting Twitch Authentication capture process - Application Token returned: $($Application.Token | out-string)" -showtime -warning -logtype Twitch -LogLevel 2
    } 
  }

  # Starting this point, neither valid access token were found nor successful refresh were done
  # So we start Authorization Code Flow from zero

  # ------------------------------ Authorization Code retrieval ------------------------------
  # STEP 1 : Prepare
  try{
    Add-Type -AssemblyName System.Web
    $EncodedRedirectUri = [System.Web.HTTPUtility]::UrlEncode($Application.RedirectUri)
    $State = (New-Guid).ToString()
    $Uri = 'https://id.twitch.tv/oauth2/authorize'
    $Uri += "?client_id=$($Application.ClientId)"
    $Uri += '&response_type=code'
    $Uri += "&redirect_uri=$EncodedRedirectUri"
    $Uri += "&state=$State"
    $Uri += "&scope=channel%3Amanage%3Apolls+channel%3Aread%3Apolls+user%3aread%3afollows+user%3aread%3aemail"

    # Create an Http Server
    $Listener = [System.Net.HttpListener]::new() 
    if($Application.RedirectUri){
      $Prefix = $Application.RedirectUri.Substring(0, $Application.RedirectUri.LastIndexOf('/') + 1) # keep uri until the last '/' included
      [void]$Listener.Prefixes.Add($Prefix)
    }
    $Listener.Start()
    if ($Listener.IsListening) {
      Write-ezlogs '>>>> HTTP Server is ready to receive Authorization Code' -showtime -logtype Twitch -LogLevel 2
      $HttpServerReady = $true
    }
    else {
      Write-ezlogs 'HTTP Server is not ready. Fall back to manual method' -showtime -warning -logtype Twitch -LogLevel 2
      $HttpServerReady = $false
    } 
  }catch{
    write-ezlogs "An exception occurred Prepare the Twitch Authentication capture process" -showtime -catcherror $_
  }  

  # STEP 2 : Open browser to get Authorization
  if ($IsMacOS) {
    Write-Verbose 'Open Mac OS browser'
    open $URI
  }
  elseif ($IsLinux) {
    Write-Verbose 'Open Linux browser'
    Write-Verbose 'You should have a freedesktop.org-compliant desktop'
    Start-Process xdg-open $URI
  }
  else {
    # So we are on Windows
    Write-ezlogs "[Get-TwitchAccessToken] >>>> Opening Show-Weblogin for capture of Twitch login with URL $URI" -showtime -logtype Twitch -LogLevel 2
    if($thisApp){
      try{
        if($hashsetup.Window.isVisible){
          $hashsetup.Window.hide()
        }     
        $MahDialog_hash = Show-WebLogin -SplashTitle "Twitch Account Login" -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_WebAuth.md"   -SplashLogo "$($thisApp.Config.Current_Folder)\Resources\Twitch\Material-Twitch.png" -WebView2_URL $URI -thisScript $thisScript -thisApp $thisApp -verboselog -Listener $Listener -First_Run $First_Run  -MahDialog_hash $MahDialog_hash     
      }catch{
        write-ezlogs "[Get-TwitchAccessToken] An exception occurred in Show-Weblogin" -showtime -catcherror $_
      }     
    }else{
      write-ezlogs "[Get-TwitchAccessToken] thisApp settings synchashtable not available!! Cant start Show-WebLogin" -showtime -warning -logtype Twitch -LogLevel 2
      $Listener.Stop()
      $Listener.dispose()
      return       
    }        
  }
  # STEP 3 : Get response
  if ($httpServerReady) {
    Write-ezlogs '[Get-TwitchAccessToken] >>>> Waiting 5 min for authorization acceptance' -showtime -logtype Twitch -LogLevel 2
    $Task = $null
    $StartTime = Get-Date
    while ($Listener.IsListening -and (([DateTime]::Now) - $StartTime) -lt '0.00:05:00' ) {   
      try{
        if ($null -eq $Task) {
          $task = $Listener.GetContextAsync()
        }   
        if ($Task.IsCompleted) {
          $Context = $task.Result
          $Task = $null
          $Response = $context.Request.Url
          $ContextResponse = $context.Response  
          [string]$html = '<script>close()</script><h2><font color="#FFA970FF">Thanks! You can close this window now.</font> </h2>'
          $htmlBuffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert html to bytes
          $ContextResponse.ContentLength64 = $htmlBuffer.Length
          $ContextResponse.OutputStream.Write($htmlBuffer, 0, $htmlBuffer.Length)
          $ContextResponse.OutputStream.Close()  
          break
        }
      }catch{
        write-ezlogs "[Get-TwitchAccessToken] An exception occurred in Twitch HTTP listener" -showtime -catcherror $_
      }
    }
    $Listener.Stop()
    $Listener.dispose()
  }
  else {
    $Response = [System.Uri]$Response
  }

  # STEP 4 : Check and Parse response
  # check Response
  if ($Response.OriginalString -eq '') {
    write-ezlogs "[Get-TwitchAccessToken] Response of Authorization Code retrieval can't be empty - Response: $Response"  -showtime -warning -logtype Twitch -LogLevel 2
  }

  # parse query
  try {
    $ResponseQuery = [System.Web.HttpUtility]::ParseQueryString($Response.Query)
  } catch {
    write-ezlogs "[Get-TwitchAccessToken] Error occured in ParseQueryString of query: $($Response.Query)" -showtime -CatchError $_
  }

  # check state
  if ($ResponseQuery['state'] -ne $State) {
    write-ezlogs "[Get-TwitchAccessToken] State returned during Authorization Code retrieval ($($ResponseQuery['state'])) does not match state passed ($State)" -showtime -warning -logtype Twitch -LogLevel 2
  }

  # check if an error has been returned
  if ($ResponseQuery['error']) {
    write-ezlogs "[Get-TwitchAccessToken] [ERROR] Error occured during Authorization Code retrieval : $($ResponseQuery['error'])" -showtime -logtype Twitch -LogLevel 2
  }
    
  # all checks are passed, we should have the code
  if ($ResponseQuery['code']) {
    $AuthorizationCode = $ResponseQuery['code']
  } else {
    write-ezlogs "[Get-TwitchAccessToken] Authorization Code not returned during Authorization Code retrieval" -showtime -warning -logtype Twitch -LogLevel 2
  }

  # Authorization Code is in $AuthorizationCode
  # ------------------------------ Token retrieval ------------------------------
  # STEP 1 : Prepare
  $Uri = 'https://id.twitch.tv/oauth2/token'
  $Method = 'Post'
  $Body = @{
    grant_type    = 'authorization_code'
    code          = $AuthorizationCode
    redirect_uri  = $Application.RedirectUri
    client_id     = $Application.ClientId # alternative way to send the client id and secret
    client_secret = $Application.ClientSecret # alternative way to send the client id and secret
  }

  # STEP 2 : Make request to the Twitch Accounts service
  try {
    Write-ezlogs "[Get-TwitchAccessToken] >>>> Sending request to get access token with AuthorizationCode: $($AuthorizationCode)." -showtime -logtype Twitch -LogLevel 2
    $CurrentTime = Get-Date
    $Response = Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -UseBasicParsing
  } catch {
    write-ezlogs "[Get-TwitchAccessToken] Error occured during request of access token : $($PSItem[0].ToString())" -showtime -CatchError $_
    if($MahDialog_hash.Window){
      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
    }
    return $false
  }
    
  try {
    # STEP 3 : Parse and save response
    $ResponseContent = $Response #| ConvertFrom-Json
    write-ezlogs "[Get-TwitchAccessToken] Parsed response scope: $($ResponseContent.scope) -- expires_in: $($ResponseContent.expires_in)" -showtime -logtype Twitch -LogLevel 2
    $Token = @{
      access_token  = $ResponseContent.access_token
      token_type    = $ResponseContent.token_type
      scope         = $ResponseContent.scope
      expires       = $CurrentTime.AddSeconds($ResponseContent.expires_in).ToString('u')
      refresh_token = $ResponseContent.refresh_token
    } 
    Set-TwitchApplication -Name $ApplicationName -Token $Token -RedirectUri $Application.redirectUri
    if($MahDialog_hash.Window){
      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
    }
    return $Token.access_token
  }
  catch {
    write-ezlogs "[Get-TwitchAccessToken] Error occured in while parsing and saving the response" -showtime -CatchError $_
  }
}

#---------------------------------------------- 
#endregion Get-TwitchAccessToken Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TwitchFollows Function
#----------------------------------------------
function Get-TwitchFollows{
  [CmdletBinding()]
  Param (
    $StreamName,
    [switch]$GetMyFollows,
    [switch]$Import_Profile,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog = $thisApp.Config.Verbose_Logging
  )
  try{
    try{
      $Name = $($thisApp.Config.App_Name)
      $Application = Get-TwitchApplication -Name $Name
      $token_expires = $application.Token.expires
      if(!$token_expires){
        $token_expires = Get-secret -name Twitchexpires  -Vault $Name -ErrorAction SilentlyContinue
      }
      $Twitchaccess_token = $application.Token.access_token
      if(!$Twitchaccess_token){
        $Twitchaccess_token = Get-secret -name Twitchaccess_token  -Vault $Name -ErrorAction SilentlyContinue
      }
      $TwitchClientId = $application.ClientId
      if(!$TwitchClientId){
        $TwitchClientId = Get-secret -name TwitchClientId  -Vault $Name -ErrorAction SilentlyContinue 
      } 
      if($token_expires -as [datetime]){
        $expire_check = [datetime]$token_expires -le (Get-date)
      }else{
        $expire_check = $true
      }
      if($expire_check -or !$Twitchaccess_token -or !$TwitchClientId){
        $Twitchaccess_token  = Get-TwitchAccessToken -thisApp $thisApp -ApplicationName $thisApp.Config.App_Name
        if(!$TwitchClientId){
          $TwitchClientId = Get-secret -name TwitchClientId  -Vault $Name -ErrorAction SilentlyContinue
        }
      }
    }catch{
      write-ezlogs "[Get-TwitchFollows] An exception occurred getting Twitch access tokens" -CatchError $_ -showtime
    }

    if($Twitchaccess_token -and $TwitchClientId){
      try{
        $headers = @{
          "client-id"     = $TwitchClientId
          "Authorization" = "Bearer $Twitchaccess_token"
        }
        $follow_data = [System.Collections.Generic.List[Object]]::new()
        if($GetMyFollows){
          try{
            $TwitchUserId = Get-secret -name TwitchUserId  -Vault $Name -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "[Get-TwitchFollows] An exception occurred getting secret TwitchUserId" -catcherror $_
            if($_.Exception -match 'A valid password is required to access the Microsoft.PowerShell.SecretStore vault'){
              try{
                write-ezlogs "[Get-TwitchFollows] Attempting to unlock SecretStore Vault: $($Name)" -warning -logtype Twitch
                Unlock-SecretVault -VaultName $Name -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
                $TwitchUserId = Get-secret -name TwitchUserId  -Vault $Name -ErrorAction SilentlyContinue
              }catch{
                write-ezlogs "[Get-TwitchFollows] An exception occurred getting Twitch secrets after unlocking SecretVault $Name" -catcherror $_
              }
            }
          }          
          $user_Uri = "https://api.twitch.tv/helix/users"
        }elseif($StreamName){
          $TwitchUserId =  $StreamName
          $user_Uri = "https://api.twitch.tv/helix/users?login=$StreamName"
        }
        if(!$TwitchUserId){
          try{
            $req=[System.Net.HTTPWebRequest]::Create($user_Uri);
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('client-id',$TwitchClientId)
            $headers.add('Authorization',"Bearer $Twitchaccess_token")
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $user_data = $output | ConvertFrom-Json
            $headers.Clear()
            $response.Dispose()
            $strm.Dispose()
            $sr.Dispose()  
            $TwitchUserId = $user_data.data.id
          }catch{
            write-ezlogs "[Get-TwitchFollows] An exception occurred getting Twitch info from url: $user_Uri" -catcherror $_
            $error.clear()
            if($response){
              $response.Dispose()
            }
            if($strm){
              $strm.Dispose()
            }
            if($sr){
              $sr.Dispose()
            }   
            $req = $Null  
          }

          if($user_data.data.id){
            write-ezlogs "[Get-TwitchFollows] >>>> Saving Twitch User data (Username: $($user_data.data.login)) to secret vault" -showtime -logtype Twitch -LogLevel 2
            try{
              Set-Secret -Name TwitchUserId -Secret $user_data.data.id -Vault $Name
              Set-Secret -Name TwitchUsername -Secret $user_data.data.login -Vault $Name
              Set-Secret -Name Twitchprofile_image_url -Secret $user_data.data.profile_image_url -Vault $Name 
            }catch{
              write-ezlogs "[Get-TwitchFollows] An exception occurred saving Twitch secrets" -catcherror $_
              if($_.Exception -match 'A valid password is required to access the Microsoft.PowerShell.SecretStore vault'){
                try{
                  write-ezlogs "[Get-TwitchFollows] Attempting to unlock SecretStore Vault: $($Name)" -warning -logtype Twitch
                  Unlock-SecretVault -VaultName $Name -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
                  Set-Secret -Name TwitchUserId -Secret $user_data.data.id -Vault $Name
                  Set-Secret -Name TwitchUsername -Secret $user_data.data.login -Vault $Name
                  Set-Secret -Name Twitchprofile_image_url -Secret $user_data.data.profile_image_url -Vault $Name 
                }catch{
                  write-ezlogs "[Get-TwitchFollows] An exception occurred saving Twitch secrets after unlocking SecretVault $Name" -catcherror $_
                }
              }
            }         
          }else{
            write-ezlogs "[Get-TwitchFollows] Unable to get user data from Twitch API - cannot continue (https://api.twitch.tv/helix/users)" -showtime -warning -logtype Twitch -LogLevel 2
          }
        } 
        if($TwitchUserId){
          $Uri = "https://api.twitch.tv/helix/channels/followed?user_id=$($TwitchUserId)&first=100"
          #$Uri = "https://api.twitch.tv/helix/users/follows?from_id=$($TwitchUserId)&first=100"
          $result = @{pagination= @{cursor = 1}}   
          While ($result.pagination.cursor){       
            $req=[System.Net.HTTPWebRequest]::Create($Uri)
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('client-id',$TwitchClientId)
            $headers.add('Authorization',"Bearer $Twitchaccess_token")
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $result = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
            $headers.Clear()
            $response.Dispose()
            $strm.Dispose()
            $sr.Dispose()  
            if($result.pagination.cursor){
              $Uri = "https://api.twitch.tv/helix/channels/followed?user_id=$($TwitchUserId)&first=100&after=$($result.pagination.cursor)"
              #$Uri = "https://api.twitch.tv/helix/users/follows?from_id=$($TwitchUserId)&first=100&after=$($result.pagination.cursor)"
            }else{
              $Uri = "https://api.twitch.tv/helix/channels/followed?user_id=$($TwitchUserId)&first=100"
              #$Uri = "https://api.twitch.tv/helix/users/follows?from_id=$($TwitchUserId)&first=100"
            }
            if($result.data){
              foreach($item in $result.data){
                if($follow_data -notcontains $item){        
                  [void]$follow_data.add($item)
                }
              } 
            }
          }
        }
        $PSCmdlet.WriteObject($follow_data)     
      }catch{
        write-ezlogs "[Get-TwitchFollows] An exception occurred with HTTPWebRequest to: $($Uri)" -showtime -catcherror $_
      }  
    }else{
      write-ezlogs "[Get-TwitchFollows] Unable to get access token to Authenticate with Twitch, cannot continue" -showtime -warning -logtype Twitch
      write-ezlogs "[Get-TwitchFollows] (Vault: $Name) - (TwitchClientId: $TwitchClientId) - (Twitchaccess_token: $Twitchaccess_token) - (Application: $($Application | out-string))" -showtime -warning -logtype Twitch -LogLevel 2
    }  
  }catch{
    write-ezlogs "[Get-TwitchFollows] An exception occurred in Get-TwitchFollows" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-TwitchFollows Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TwitchVideos Function
#----------------------------------------------
function Get-TwitchVideos{
  [CmdletBinding()]
  Param (
    $StreamName,
    $TwitchUserId,
    $TwitchVideoId,
    [string]$VideoType,
    [switch]$Import_Profile,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog = $thisApp.Config.Verbose_Logging
  )
  #TODO: Twitch VOD chat replay: https://rechat.twitch.tv/rechat-messages?start=1458316988&video_id=v55153756
  #each query will return a 30 second window of messages
  try{
    try{
      $Name = $($thisApp.Config.App_Name)
      $Application = Get-TwitchApplication -Name $Name
      $token_expires = $application.Token.expires
      if(!$token_expires){
        $token_expires = Get-secret -name Twitchexpires  -Vault $Name -ErrorAction SilentlyContinue
      }
      $Twitchaccess_token = $application.Token.access_token
      if(!$Twitchaccess_token){
        $Twitchaccess_token = Get-secret -name Twitchaccess_token  -Vault $Name -ErrorAction SilentlyContinue
      }
      $TwitchClientId = $application.ClientId
      if(!$TwitchClientId){
        $TwitchClientId = Get-secret -name TwitchClientId  -Vault $Name -ErrorAction SilentlyContinue 
      } 
      if($token_expires -as [datetime]){
        $expire_check = [datetime]$token_expires -le (Get-date)
      }else{
        $expire_check = $true
      }
      if($expire_check -or !$Twitchaccess_token -or !$TwitchClientId){
        $Twitchaccess_token  = Get-TwitchAccessToken -thisApp $thisApp -ApplicationName $thisApp.Config.App_Name
        if(!$TwitchClientId){
          $TwitchClientId = Get-secret -name TwitchClientId  -Vault $Name -ErrorAction SilentlyContinue
        }
      }
    }catch{
      write-ezlogs "An exception occurred getting Twitch access tokens" -CatchError $_ -showtime
    }
    $Video_data = [System.Collections.Generic.List[Object]]::new()
    if($Twitchaccess_token -and $TwitchClientId){
      try{
        $headers = @{
          "client-id"     = $TwitchClientId
          "Authorization" = "Bearer $Twitchaccess_token"
        }
        if($TwitchVideoId){
          try{
            $VideoUrl = "https://api.twitch.tv/helix/videos?id=$($TwitchVideoId)"
            $req=[System.Net.HTTPWebRequest]::Create($VideoUrl);
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('client-id',$TwitchClientId)
            $headers.add('Authorization',"Bearer $Twitchaccess_token")
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream();
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $Video_Json = $output | ConvertFrom-Json -ErrorAction SilentlyContinue                 
            $headers.Clear()
            $response.Dispose()
            $strm.Dispose()
            $sr.Dispose()  
            $Video_data = $Video_Json.data
          }catch{
            write-ezlogs "[Get-TwitchFollows] An exception occurred getting Twitch info from url: $VideoUrl" -catcherror $_
            $error.clear()
            if($response){
              $response.Dispose()
            }
            if($strm){
              $strm.Dispose()
            }
            if($sr){
              $sr.Dispose()
            }   
            $req = $Null  
          }        
        }else{
          if($StreamName){
            $user_Uri = "https://api.twitch.tv/helix/users?login=$StreamName"
          }
          if(!$TwitchUserId){
            try{
              $req=[System.Net.HTTPWebRequest]::Create($user_Uri)
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('client-id',$TwitchClientId)
              $headers.add('Authorization',"Bearer $Twitchaccess_token")
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd()
              $user_data = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
              $headers.Clear()
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()  
              $TwitchUserId = $user_data.data.id
            }catch{
              write-ezlogs "[Get-TwitchFollows] An exception occurred getting Twitch info from url: $user_Uri" -catcherror $_
              $error.clear()
              if($response){
                $response.Dispose()
              }
              if($strm){
                $strm.Dispose()
              }
              if($sr){
                $sr.Dispose()
              }   
              $req = $Null  
            }
          } 
          if($TwitchUserId){
            $Uri =  "https://api.twitch.tv/helix/videos?user_id=$($TwitchUserId)&first=100"
            $result = @{pagination= @{cursor = 1}}   
            While ($result.pagination.cursor){       
              $req=[System.Net.HTTPWebRequest]::Create($Uri)
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('client-id',$TwitchClientId)
              $headers.add('Authorization',"Bearer $Twitchaccess_token")
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd()
              $result = $output | ConvertFrom-Json -ErrorAction SilentlyContinue                
              $headers.Clear()
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()  
              if($result.pagination.cursor){
                $Uri = "https://api.twitch.tv/helix/videos?user_id=$($TwitchUserId)&first=100&after=$($result.pagination.cursor)"
              }else{
                $Uri = "https://api.twitch.tv/helix/videos?user_id=$($TwitchUserId)&first=100"
              }
              if($result.data){
                foreach($item in $result.data){
                  if($Video_data -notcontains $item){        
                    [void]$Video_data.add($item)
                  }
                } 
              }
            }
          }
        }
        $PSCmdlet.WriteObject($Video_data)       
      }catch{
        write-ezlogs "An exception occurred with HTTPWebRequest to: $($Uri)" -showtime -catcherror $_
      }  
    }else{
      write-ezlogs "Unable to get access token to Authenticate with Twitch, cannot continue" -showtime -warning -logtype Twitch
      write-ezlogs "(Vault: $Name) - (TwitchClientId: $TwitchClientId) - (Twitchaccess_token: $Twitchaccess_token) - (Application: $($Application | out-string))" -showtime -warning -logtype Twitch -LogLevel 2
    }  
  }catch{
    write-ezlogs "[Get-TwitchFollows] An exception occurred in Get-TwitchVideos" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-TwitchVideos Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TwitchAPI Function
#----------------------------------------------
function Get-TwitchAPI {
  [CmdletBinding()]
  Param (
    $StreamName,
    [switch]$Import_Profile,
    [switch]$Get_Follows,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $all_installed_apps,
    [switch]$Startup,
    [switch]$ForceTokenRefresh,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog = $thisApp.Config.Dev_mode
  )
  if($Verboselog){write-ezlogs "#### Checking Twitch Stream $StreamName ####" -enablelogs -color yellow -linesbefore 1 -logtype Twitch -VerboseDebug:$Verboselog}
  try{
    $internet_Connectivity = Test-ValidPath -path 'www.twitch.tv' -PingConnection -timeout_milsec 1000
  }catch{
    write-ezlogs "Ping test failed for: www.twitch.tv - trying 1.1.1.1" -Warning -logtype Twitch
  }finally{
    try{
      if(!$internet_Connectivity){
        $internet_Connectivity = Test-ValidPath -path '1.1.1.1' -PingConnection -timeout_milsec 2000
      }
    }catch{
      write-ezlogs "Secondary ping test failed for: 1.1.1.1" -Warning -logtype Twitch
      $internet_Connectivity = $null
    }
  }
  if($internet_Connectivity){
    try{
      $Name = $($thisApp.Config.App_Name)
      $Application = Get-TwitchApplication -Name $thisApp.Config.App_Name
      $token_expires = $Application.token.expires
      $Twitchaccess_token = $Application.token.access_token
      $TwitchClientId = $Application.ClientId
      if(-not [string]::IsNullOrEmpty($token_expires)){
        if([Datetime]::TryParse($token_expires,[ref]([Datetime]::Now))){
          $token_expires = [Datetime]::Parse($token_expires)
        }else{
          $token_expires = Get-Date $token_expires -ErrorAction Continue
        }
      }
      if($token_expires -le ([Datetime]::Now) -or !$Twitchaccess_token -or !$TwitchClientId){
        $Twitchaccess_token  = Get-TwitchAccessToken -thisApp $thisApp -ApplicationName $thisApp.Config.App_Name
        if(!$TwitchClientId){
          $TwitchClientId = Get-secret -name TwitchClientId  -Vault $Name -ErrorAction SilentlyContinue
        }
      }
    }catch{
      write-ezlogs "[Get-TwitchAPI] An exception occurred getting or refreshing Twitch access tokens" -CatchError $_ -showtime
    } 
    if($StreamName -and $Twitchaccess_token -and $TwitchClientId){
      try{
        #Get twitch streamers
        #"https://api.twitch.tv/helix/users?login=Pepp"
        #'https://api.twitch.tv/helix/users/follows?to_id=<user ID>'
        $headers = @{
          "client-id"     = $TwitchClientId
          "Authorization" = "Bearer $Twitchaccess_token"
        } 
        $user_data = [System.Collections.Generic.List[Object]]::new()     
        $streamer_data_output = [System.Collections.Generic.List[Object]]::new()
        if(@($StreamName).count -gt 1){
          $group = 100
          $i = 0       
          do {
            $names = ($StreamName[$i..(($i += $group) - 1)]).replace(" ",[string]::Empty)
            $uri = 'https://api.twitch.tv/helix/users?login=' + "$($names -join "&login=")"
            $streamer_uri = "https://api.twitch.tv/helix/streams?user_login=" + "$($names -join "&user_login=")"
            try{
              $req=[System.Net.HTTPWebRequest]::Create($uri)
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('client-id',$TwitchClientId)
              $headers.add('Authorization',"Bearer $Twitchaccess_token")
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd()
              $data = $output | ConvertFrom-Json
              [void]$user_data.add($data)
              $headers.Clear()
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()
            }catch{
              write-ezlogs "[Get-TwitchAPI] An exception occured when getting user_data with uri: $uri" -showtime -catcherror $_ -callpath $((Get-PSCallStack)[0].FunctionName)
            }finally{
              if($response -is [System.IDisposable]){
                $response.Dispose()
              }
              if($strm -is [System.IDisposable]){
                $strm.Dispose()
              }
              if($sr -is [System.IDisposable]){
                $sr.Dispose()
              }
            }
            try{   
              $req=[System.Net.HTTPWebRequest]::Create($streamer_uri)
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('client-id',$TwitchClientId)
              $headers.add('Authorization',"Bearer $Twitchaccess_token")
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd()
              $stream_data = $output | ConvertFrom-Json
              [void]$streamer_data_output.add($stream_data)   
              $headers.Clear()
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()                             
            }catch{
              write-ezlogs "[Get-TwitchAPI] An exception occurred in getting stream data with streamer_uri: $streamer_uri" -showtime -catcherror $_
            }finally{
              if($response -is [System.IDisposable]){
                $response.Dispose()
              }
              if($strm -is [System.IDisposable]){
                $strm.Dispose()
              }
              if($sr -is [System.IDisposable]){
                $sr.Dispose()
              }
            }
          }
          until ($i -ge $StreamName.count -1)
        }else{
          $uri = 'https://api.twitch.tv/helix/users'
          $streamer_uri = "https://api.twitch.tv/helix/streams"
          $name = $StreamName.replace(" ",[string]::Empty)
          $uri += "?login=$name"
          $streamer_uri += "?user_login=$name"
          try{
            $req=[System.Net.HTTPWebRequest]::Create($uri)
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('client-id',$TwitchClientId)
            $headers.add('Authorization',"Bearer $Twitchaccess_token")
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $data = $output | ConvertFrom-Json
            [void]$user_data.add($data)
            $headers.Clear()
          }catch{
            write-ezlogs "[Get-TwitchAPI] An exception occured with HTTPWebRequest to: $uri" -showtime -catcherror $_
          }finally{
            if($response -is [System.IDisposable]){
              $response.Dispose()
            }
            if($strm -is [System.IDisposable]){
              $strm.Dispose()
            }
            if($sr -is [System.IDisposable]){
              $sr.Dispose()
            }
          }
          try{ 
            $req=[System.Net.HTTPWebRequest]::Create($streamer_uri)
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('client-id',$TwitchClientId)
            $headers.add('Authorization',"Bearer $Twitchaccess_token")
            $req.Headers = $headers
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $stream_data = $output | ConvertFrom-Json
            [void]$streamer_data_output.add($stream_data)     
            $headers.Clear()             
          }catch{
            write-ezlogs "[Get-TwitchAPI] An exception occurred with HTTPWebRequest to: $streamer_uri" -showtime -catcherror $_
          }finally{
            if($response -is [System.IDisposable]){
              $response.Dispose()
            }
            if($strm -is [System.IDisposable]){
              $strm.Dispose()
            }
            if($sr -is [System.IDisposable]){
              $sr.Dispose()
            } 
          }
        }    
        $TwitchData_output = [System.Collections.Generic.List[Object]]::new()
        if($user_data.data){    
          foreach($streamer in $user_data.data){       
            $profile_image_url = $Null
            $offline_image_url = $Null
            $description = $null      
            $id = $null
            $streams_data = $null
            if($streamer.id){
              $id = $streamer.id
            }else{
              $id = $streamer.data.id
            } 
            try{     
              if($streamer_data_output.data.user_id){
                $streams_data = $streamer_data_output.data | & { process {if ($_.user_id -eq $streamer.id){$_}}}
              }
            }catch{
              write-ezlogs "[Get-TwitchAPI] An exception occurred finding streamer data with id $($streamer.id)" -showtime -catcherror $_
            }
            if($id -and $TwitchData_output.user_id -notcontains $id){
              if($streamer.type){
                $type = $((Get-Culture).textinfo.totitlecase(($streamer.type).tolower()))
              }elseif($streams_data.type){
                $type = $streams_data.type
              }else{
                $type = $Null
              }
              if($streamer.profile_image_url){
                $profile_image_url = $streamer.profile_image_url
                $offline_image_url = $streamer.offline_image_url
                $description = $streamer.description
              }else{
                $profile_image_url = $Null
                $offline_image_url = $Null
                $description = $Null
              }
              if($streamer.login){
                $user_login = $streamer.login
              }elseif($streams_data.user_login){
                $user_login = $streams_data.user_login
              }elseif($streams_data.user_name){
                $user_login = $streams_data.user_name
              }else{
                $user_login = $Null
              }
              if($streams_data.user_name){
                $user_name = $streams_data.user_name
              }elseif($streamer.display_name){
                $user_name = $streamer.display_name
              }else{
                $user_name = $Null
              }
              if($Verboselog){write-ezlogs "[Get-TwitchAPI] >>>> Found Stream $($streamer.display_name)`n | $($id)`n | Type $($type)`n | Title $($streams_data.title)`n | Description $description" -showtime -logtype Twitch -VerboseDebug:$Verboselog}       
              $TwitchData = [PSCustomObject]::new(@{
                  'Title' = $streams_data.title
                  'User_id' = $id
                  'user_login' = $user_login
                  'user_name' =  $user_name
                  'game_name' = $streams_data.game_name
                  'type' = $type
                  'description' = $description
                  'profile_image_url' = $profile_image_url
                  'offline_image_url' = $offline_image_url
                  'created_at' = $streamer.created_at
                  'started_at' = $streams_data.started_at
                  'viewer_count' = $streams_data.viewer_count
                  'thumbnail_url' = $streams_data.thumbnail_url
              })
              [void]$TwitchData_output.add($TwitchData)
            }
          }  
        }else{
          write-ezlogs "[Get-TwitchAPI] Unable to get data for stream ($StreamName)" -showtime -enablelogs -warning -logtype Twitch -LogLevel 2
        }
        $PSCmdlet.WriteObject($TwitchData_output)
      }catch{
        write-ezlogs "[Get-TwitchAPI] An exception occurred getting Twitch info for stream $StreamName" -CatchError $_ -showtime -enablelogs
      }   
    }else{
      write-ezlogs "[Get-TwitchAPI] Unable to Authenticate with Twitch, cannot continue - Streamname: $StreamName - Twitch ClientID: $TwitchClientId - TwitchAccess TOken: $Twitchaccess_token" -showtime -warning -logtype Twitch -LogLevel 2
      return
    }
  }else{
    write-ezlogs "Cannot get Twitch streams, unable to connect to 'www.twitch.tv' due to network issue" -warning
    return
  }
}
#---------------------------------------------- 
#endregion Get-TwitchAPI Function
#----------------------------------------------
 
#---------------------------------------------- 
#region Update-TwitchStatus Function
#----------------------------------------------
function Update-TwitchStatus
{
  [cmdletbinding()]
  Param(
    [string]$StreamName,
    $media,
    [switch]$CheckAll,
    [switch]$Test,
    [switch]$Use_runspace,
    $thisApp,
    $synchash,
    $hashsetup,
    [switch]$Startup,
    [switch]$Update_Twitch_Profile,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Refresh_Follows,
    [switch]$Enable_liveAlert,
    [switch]$Verboselog = $thisApp.Config.Dev_mode
  )
  try{
    Import-Module "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
    Import-Module "$($thisApp.Config.Current_Folder)\Modules\Get-Twitch\Get-Twitch.psm1" -NoClobber -DisableNameChecking -Scope Local
    try{
      $internet_Connectivity = Test-ValidPath -path 'www.twitch.tv' -PingConnection -timeout_milsec 1000
    }catch{
      write-ezlogs "Ping test failed for: www.twitch.tv - trying 1.1.1.1" -Warning -logtype Twitch
    }finally{
      try{
        if(!$internet_Connectivity){
          $internet_Connectivity = Test-ValidPath -path '1.1.1.1' -PingConnection -timeout_milsec 2000
        }
      }catch{
        write-ezlogs "Secondary ping test failed for: 1.1.1.1" -Warning -logtype Twitch
        $internet_Connectivity = $null
      }
    }
    if($internet_Connectivity){
      $AllTwitch_Media_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Twitch_MediaProfile","All-Twitch_Media-Profile.xml")
      if($Refresh_Follows){
        try{
          write-ezlogs "[Get-TwitchStatus] >>>> Refreshing all Twitch follows" -logtype Twitch
          try{
            $newtwitchchannels = 0
            $Twitch_playlists = Get-TwitchFollows -GetMyFollows -thisApp $thisApp
          }catch{
            write-ezlogs "[Get-TwitchStatus] An exception occurred retrieving Twitch Follows with Get-TwitchFollows" -showtime -catcherror $_
          } 
          if($Twitch_playlists -and $hashsetup){
            Import-Module "$($thisApp.Config.Current_Folder)\Modules\Show-SettingsWindow\Show-SettingsWindow.psm1" -NoClobber -DisableNameChecking -Scope Local
            foreach($playlist in $Twitch_playlists){
              $playlisturl = "https://www.twitch.tv/$($playlist.broadcaster_login)"
              $playlistName = $playlist.broadcaster_name
              if($playlist.followed_at){
                try{
                  $followed = [DateTime]::Parse($playlist.followed_at)
                  if($followed){
                    $followed = $followed.ToShortDateString()
                  }
                }catch{
                  write-ezlogs "[Get-TwitchStatus] An exception occurred parsing followed_at ($($playlist.followed_at)) for Twitch channel $($playlistName)" -showtime -catcherror $_
                }
              } 
              if($hashsetup.window.IsInitialized -and $hashsetup.TwitchPlaylists_Grid){
                if($hashsetup.TwitchPlaylists_items.path -notcontains $playlisturl){
                  $newtwitchchannels++
                  Update-TwitchPlaylists -thisApp $thisApp -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.to_id -Followed $Followed -type 'TwitchChannel' -VerboseLog:$thisApp.Config.Verbose_logging -add_to_Twitch_Playlists -use_runspace
                }
              }
            }
            if($hashsetup.window.IsInitialized -and $hashsetup.TwitchPlaylists_Grid){
              Update-TwitchPlaylists -thisApp $thisApp -hashsetup $hashsetup -VerboseLog:$thisApp.Config.Verbose_logging -SetItemsSource
            }  
            write-ezlogs "[Get-TwitchStatus] | Found $newtwitchchannels new Twitch Channels" -showtime -logtype Twitch -LogLevel 2
            if($synchash.TwitchTable){
              write-ezlogs "[Get-TwitchStatus] | Updating Twitch Media Library" -showtime -logtype Twitch -LogLevel 2
              Import-Module "$($thisApp.Config.Current_Folder)\Modules\Import-Twitch\Import-Twitch.psm1" -NoClobber -DisableNameChecking -Scope Local
              Import-Twitch -Twitch_playlists $thisapp.Config.Twitch_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh 
            }
          }elseif(!$hashsetup){
            write-ezlogs "[Get-TwitchStatus] Get-TwitchStatus cannot refresh follows under Twitch settings as settings hashsetup is not initialized" -showtime -warning -logtype Twitch
          }else{
            write-ezlogs "[Get-TwitchStatus] Unable to import Followed channels from Twitch - no channels returned" -showtime -warning -logtype Twitch
          }         
        }catch{
          write-ezlogs "[Get-TwitchStatus] An exception occurred in Get-TwitchStatus -refresh_Follows" -showtime -catcherror $_
        }
      }
      try{
        if([System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path) -or [System.IO.File]::Exists($thisApp.Config.Playlists_Profile_Path)){
          if($CheckAll){
            if($syncHash.All_Twitch_Media.count -gt 0){
              $Available_Twitch_Media = $syncHash.All_Twitch_Media
            }elseif([System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path)){
              if($Verboselog){write-ezlogs "[Get-TwitchStatus] | Importing Twitch Media Profile: $AllTwitch_Media_Profile_File_Path" -logtype Twitch -showtime -VerboseDebug:$Verboselog}
              $Available_Twitch_Media = Import-SerializedXML -Path $AllTwitch_Media_Profile_File_Path
            }elseif($synchash.all_playlists.playlist_tracks){
              $Available_Twitch_Media = $synchash.all_playlists.playlist_tracks.values | & { process {if ($_.url -match 'twitch.tv'){$_}}}
            }   
          }elseif($media){
            $Available_Twitch_Media = $media
          }
          if($Verboselog){write-ezlogs "[Get-TwitchStatus] >>>> Checking status for $($Available_Twitch_media.count) Twitch streams" -showtime -color cyan -logtype Twitch -VerboseDebug:$Verboselog}
          try{
            if($Available_Twitch_Media.Channel_Name){
              $TwitchData = Get-TwitchAPI -StreamName $Available_Twitch_Media.Channel_Name -thisApp $thisApp
            }elseif($Available_Twitch_Media.url){
              write-ezlogs "[Get-TwitchStatus] >>>> Getting Twitch Stream names" -showtime -logtype Twitch -LogLevel 2
              $twitch_Streams = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase((($Available_Twitch_Media.url | Where-Object {$_}) | split-path -leaf).tolower()) -split ' '
              write-ezlogs "[Get-TwitchStatus] | Stream names: $twitch_Streams" -showtime -logtype Twitch -LogLevel 2
              $TwitchData = Get-TwitchAPI -StreamName $twitch_Streams -thisApp $thisApp
              write-ezlogs "[Get-TwitchStatus] | Received data: $TwitchData" -showtime -logtype Twitch -LogLevel 2
            }
          }catch{
            write-ezlogs "[Get-TwitchStatus] An exception occurred executing Get-TwitchAPI" -showtime -catcherror $_
          }            
          if(!($TwitchData)){
            write-ezlogs "[Get-TwitchStatus] Unable to get TwitchData, cannot continue. Check logs for more details!" -showtime -warning -logtype Twitch -LogLevel 2
            return
          }
          if($synchash.all_playlists.count -gt 0){
            $all_Playlists = $synchash.all_playlists
          }elseif($synchash.all_playlists.SourceCollection.count -gt 0){
            $all_Playlists = $synchash.all_playlists.SourceCollection
          }
          $changes = 0
          $synchash.Twitch_status_changes = $Null
          $Available_Twitch_Media | & { process {
              try{
                $twitchmedia = $_
                $UpdateAlert = $Null
                $TwitchAPI = $Null
                $Config_index = $null
                $twitch_status = $null
                $playlist_track = $null
                $Playlist_index = $null
                $TwitchAPI = $TwitchData | & { process {if ($_.user_name -eq $twitchmedia.Channel_Name -or $_.user_name -eq $twitchmedia.artist){$_}}}
                if($TwitchAPI.user_name){
                  $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($TwitchAPI.user_name)
                }elseif($TwitchAPI.user_login){
                  $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($TwitchAPI.user_login)
                }else{
                  $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($twitchmedia.Channel_Name)
                }                 
                if($Verboselog){write-ezlogs "[Get-TwitchStatus] >>>> Checking status of Twitch stream $twitch_channel -- $($twitchmedia.url) - Currently playing $($synchash.streamlink.User_Name) - TwitchAPI: $($TwitchAPI | out-string)" -showtime -color cyan -logtype Twitch -Dev_mode}  
                if($all_Playlists.Playlist_tracks.values.url){                                 
                  $Playlist_index = $all_Playlists.Playlist_tracks.values.url.IndexOf($twitchmedia.url)
                  if($Playlist_index -ne -1){
                    $playlist_track = $all_Playlists.Playlist_tracks.values[$Playlist_index]
                  }
                }
                if($synchash.Current_playing_media.User_id -and $twitchApi.User_id -and $synchash.Current_playing_media.User_id -eq $twitchApi.User_id){
                  write-ezlogs "[Get-TwitchStatus] | Updating currently playing Twitch stream $twitch_channel -- View Count: $($TwitchAPI.viewer_count)" -showtime -color cyan -logtype Twitch -LogLevel 2
                  $synchash.streamlink = $TwitchAPI
                }
                if($thisapp.config.Twitch_Playlists.id){
                  $Config_index = $thisapp.config.Twitch_Playlists.id.indexof($twitchmedia.id)
                  if($Config_index -ne -1){
                    $Config_Twitch = $thisapp.config.Twitch_Playlists[$Config_index]
                  }elseif($thisapp.config.Twitch_Playlists.Name.indexof($twitchmedia.Name) -ne -1){
                    $Config_Twitch = $thisapp.config.Twitch_Playlists[$thisapp.config.Twitch_Playlists.Name.indexof($twitchmedia.Name)]
                    if($Config_Twitch){
                      $Config_Twitch.id = $twitchmedia.id
                    }
                  }
                }
                if($twitchmedia.Enable_LiveAlert -or $playlist_track.Enable_LiveAlert -or $Config_Twitch.Enable_LiveAlert){
                  $Enable_LiveAlert = $true
                }else{
                  $Enable_LiveAlert = $false
                }
                if($twitchmedia){
                  $twitchmedia.Enable_LiveAlert = $Enable_LiveAlert
                }
                if($Config_Twitch){
                  $Config_Twitch.Enable_LiveAlert = $Enable_LiveAlert
                }                                  
                if($playlist_track){
                  $playlist_track.Enable_LiveAlert = $Enable_LiveAlert
                }
                if($TwitchAPI.started_at){
                  [TimeSpan]$TimeSpan = [DateTime]::Now - ([DateTime]::Parse($TwitchAPI.started_at).ToLocalTime())
                  write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel started at: '$($TwitchAPI.started_at)' -- Timespan: $TimeSpan" -showtime -logtype Twitch -LogLevel 2 -Dev_mode
                  $TimeLive = " -- Time Live: $($TimeSpan.Hours):$($TimeSpan.Minutes):$($TimeSpan.Seconds)"
                }
                if(!$TwitchAPI.type){
                  $twitch_status = 'Offline'
                  $thumbnail = ''
                  if($Verboselog){write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel`: OFFLINE" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
                  if("$($twitchmedia.Live_Status)" -ne 'Offline' -or $twitchmedia.Status_Msg -ne '' -or ($playlist_track -and ($playlist_track.Live_Status -ne 'Offline' -or $playlist_track.Status_msg -ne ''))){
                    if($twitchmedia.Live_Status -ne 'Offline'){
                      $changes++
                      write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed status from '$($twitchmedia.Live_Status)' to 'Offline'" -showtime -logtype Twitch -LogLevel 2
                    }          
                  }
                }elseif($TwitchAPI.type){
                  $twitch_status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($TwitchAPI.type)
                  if($TwitchAPI.thumbnail_url){
                    $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500' -replace '%{width}x%{height}','500x500')"
                  }else{
                    $thumbnail = ''
                  }
                  if("$twitch_status" -ne "$($twitchmedia.Live_Status)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed status from '$($twitchmedia.Live_Status)' to '$($twitch_status)'" -showtime -logtype Twitch -LogLevel 2
                    $UpdateAlert = $true
                    $changes++
                  }elseif($playlist_track -and "$twitch_status" -ne "$($playlist_track.Live_Status)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed status from '$($playlist_track.Live_Status)' to '$($twitch_status)'" -showtime -logtype Twitch -LogLevel 2
                    $changes++
                  }elseif($playlist_track -and "$($TwitchAPI.game_name)" -ne "$($playlist_track.Status_msg)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed game/category from '$($playlist_track.Status_msg)' to '$($TwitchAPI.game_name)'" -showtime -logtype Twitch -LogLevel 2
                    $changes++
                  }elseif("$($TwitchAPI.game_name)" -ne "$($twitchmedia.Status_msg)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed game/category from '$($twitchmedia.Status_msg)' to '$($TwitchAPI.game_name)'" -showtime -logtype Twitch -LogLevel 2
                    $changes++
                  }elseif($playlist_track -and "$($TwitchAPI.title)" -ne "$($playlist_track.Stream_title)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed title from '$($playlist_track.Stream_title)' to '$($TwitchAPI.title)'" -showtime -logtype Twitch -LogLevel 2
                    $changes++
                  }elseif("$($TwitchAPI.title)" -ne "$($twitchmedia.Stream_title)"){
                    write-ezlogs "[Get-TwitchStatus] | Twitch Channel $twitch_channel has changed title from '$($twitchmedia.Stream_title)' to '$($TwitchAPI.title)'" -showtime -logtype Twitch -LogLevel 2
                    $changes++
                  }
                  if($UpdateAlert -and $thisApp.Config.Enable_Twitch_Notifications -and ($twitchmedia.Enable_LiveAlert -or $playlist_track.Enable_LiveAlert -or $Config_Twitch.Enable_LiveAlert)){
                    try{
                      #Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local
                      $Message = "Twitch Channel '$twitch_channel' is now $twitch_status!`nPlaying: $($TwitchAPI.game_name)$TimeLive"
                      if($TwitchAPI.profile_image_url){
                        $applogo = $TwitchAPI.profile_image_url                           
                      }elseif($twitchmedia.profile_image_url){
                        $applogo = $($twitchmedia.profile_image_url | Select-Object -First 1)
                      }else{
                        $applogo = "$($thisApp.Config.Current_folder)\Resources\Twitch\Material-Twitch.png"
                      }
                      if($thisApp.Config.Installed_AppID){
                        $appid = $thisApp.Config.Installed_AppID
                      }else{
                        $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
                        $thisapp.config.Installed_AppID = $appid
                      }                         
                      if($TwitchAPI.offline_image_url){
                        $heroimage = $TwitchAPI.offline_image_url
                      }elseif($twitchmedia.offline_image_url){
                        $heroimage = $twitchmedia.offline_image_url
                      }else{
                        $heroimage = "$($thisApp.Config.Current_folder)\Resources\Samson_Icon1.png"
                      }
                      $Toast = @{
                        AppID = $appid
                        Text = $Message
                        AppLogo = $applogo
                        HeroImage = $heroimage
                      }
                      Update-MainWindow -synchash $synchash -thisApp $thisApp -Toast $Toast
                    }catch{
                      write-ezlogs "[Get-TwitchStatus] An exception occurred attempting to generate the notification balloon - appid: $($appid) - applogo: $($applogo) - message: $($Message)" -showtime -catcherror $_
                    }
                  }
                }
                if($twitch_status -eq 'Offline'){
                  $fontstyle = 'Italic'
                  $fontcolor = 'Gray'
                  $FontWeight = 'Normal'
                  $FontSize = [Double]'12'   
                  $ToolTip = $TwitchAPI.description 
                  $ViewerCount = 0
                  $Status_Msg = ''
                  $StreamTitle = ''
                }elseif($twitch_status -in 'Online','Live'){
                  $fontstyle = 'Normal'
                  $fontcolor = 'LightGreen'
                  $FontWeight = 'Normal'
                  $FontSize = [Double]'12'
                  $ToolTip = "$($TwitchAPI.title)$TimeLive"
                  $ViewerCount = ([int]$TwitchAPI.viewer_count)
                  $Status_Msg = "$($TwitchAPI.game_name)"
                  $StreamTitle = "$($TwitchAPI.title)"
                }else{
                  $fontstyle = 'Normal'
                  $fontcolor = 'White' 
                  $FontWeight = 'Normal'
                  $FontSize = [Double]'12'
                  $ToolTip = $TwitchAPI.description
                  $ViewerCount = 0
                  $Status_Msg = ''
                  $StreamTitle = ''
                }
                if("$($TwitchAPI.game_name)"){
                  if($twitch_status -eq 'Offline'){
                    $Status_fontcolor = 'Gray'
                    $Status_fontstyle = 'Italic'
                  }else{
                    $Status_fontcolor = 'White'
                    $Status_fontstyle = 'Normal'
                  }                            
                }else{
                  $Status_fontstyle = 'Normal'
                  $Status_fontcolor = 'White' 
                }
                $twitchmedia.Live_Status = $twitch_status
                $twitchmedia.Status_msg = $Status_Msg
                $twitchmedia.Stream_title = $StreamTitle
                $twitchmedia.thumbnail = $thumbnail
                $twitchmedia.viewer_count = $ViewerCount
                $twitchmedia.description = $TwitchAPI.description
                $twitchmedia.Status = $twitch_status
                $twitchmedia.ToolTip = $ToolTip
                if($playlist_track){
                  $playlist_track.Live_Status = $twitch_status
                  $playlist_track.Status = $twitch_status
                  $playlist_track.Status_msg = $Status_Msg
                  $playlist_track.FontStyle = $fontstyle
                  $playlist_track.FontColor = $FontColor
                  $playlist_track.FontWeight = $FontWeight
                  $playlist_track.FontSize = $FontSize
                  $playlist_track.Status_FontStyle = $Status_fontstyle
                  $playlist_track.Status_FontColor = $Status_fontcolor
                  $playlist_track.Stream_title = $StreamTitle
                  $playlist_track.thumbnail = $thumbnail
                  $playlist_track.viewer_count = $ViewerCount
                  $playlist_track.description = $TwitchAPI.description
                  $playlist_track.ToolTip = $ToolTip
                }
                if($changes -gt 0){
                  $synchash.Twitch_status_changes = $changes 
                }
              }catch{
                write-ezlogs "[Get-TwitchStatus] An exception occurred in checktwitch_scriptblock loop" -showtime -catcherror $_
              }
          }}
          if($synchash.Twitch_status_changes){
            try{
              write-ezlogs "[Get-TwitchStatus] >>>> Updated $($synchash.Twitch_status_changes) Twitch streams with changes" -showtime -logtype Twitch -LogLevel 2
              if($Verboselog){write-ezlogs "[Get-TwitchStatus] >>>> Exporting to profile path: $AllTwitch_Media_Profile_File_Path" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
              if($CheckAll){
                Export-SerializedXML -InputObject $Available_Twitch_Media -Path $AllTwitch_Media_Profile_File_Path
              }else{
                Export-SerializedXML -InputObject $synchash.All_Twitch_Media -Path $AllTwitch_Media_Profile_File_Path
              }              
              Export-SerializedXML -InputObject $synchash.all_playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
              if($synchash.update_Queue_timer -and !$synchash.update_Queue_timer.isEnabled){
                $synchash.update_Queue_timer.Tag = 'UpdateQueue'
                $synchash.update_Queue_timer.start()
              }               
            }catch{
              write-ezlogs "[Get-TwitchStatus] An exception occurred exporting to profile path: $AllTwitch_Media_Profile_File_Path" -showtime -catcherror $_
            }
          }else{
            write-ezlogs "[Get-TwitchStatus] No changes were found for any Twitch Streams" -showtime -logtype Twitch -LogLevel 2
          }
          $synchash.Twitch_status_changes = $Null                                               
        }else{
          write-ezlogs "[Get-TwitchStatus] No Twitch Media Profile found at $AllTwitch_Media_Profile_File_Path" -showtime -warning -logtype Twitch -LogLevel 2
        } 
      }catch{
        write-ezlogs "[Get-TwitchStatus] An exception occurred in checktwitch_scriptblock" -showtime -catcherror $_
      } 
    }else{
      if($synchash.MiniPlayer_Viewer.isVisible){
        try{
          $AlertUI = $false
          Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID 
            $thisApp.Config.Installed_AppID = $appid
          }
          $Guid = [System.Guid]::NewGuid()
          if($Guid){
            [string]$Id = 'ID' + ($Guid.Guid -Replace'-','').ToUpper()
          }
          $Title = 'WARNING - Twitch Monitor'
          $Header = [Microsoft.Toolkit.Uwp.Notifications.ToastHeader]::new($Id, ($Title -replace '\x01'), $null)
          $Toast = @{
            AppID = $appid
            Text = "Cannot check status of Twitch streams, unable to connect to 'www.twitch.tv'"
            AppLogo = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
            Header = $Header
          }
          Update-MainWindow -synchash $synchash -thisApp $thisApp -Toast $Toast
        }catch{
          write-ezlogs "An exception occurred attempting to generate the notification balloon - appid: $($appid)" -showtime -catcherror $_
        }     
      }else{
        $AlertUI = $true
      }
      write-ezlogs "Cannot check status of Twitch streams, unable to connect to 'www.twitch.tv'" -warning -AlertUI:$AlertUI
    }
  }catch{
    write-ezlogs "An exception occurred in Update-TwitchStatus" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Update-TwitchStatus Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TwitchStatus Function
#----------------------------------------------
function Get-TwitchStatus
{
  Param (
    [string]$StreamName,
    $media,
    [switch]$CheckAll,
    [switch]$Test,
    [switch]$Use_runspace,
    $thisApp,
    $synchash,
    $hashsetup = $hashsetup,
    [switch]$Startup,
    [switch]$Update_Twitch_Profile,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Refresh_Follows,
    [switch]$Enable_liveAlert,
    [switch]$Verboselog = $thisApp.Config.Dev_Mode
  )
  if($CheckAll -or $media){
    if($Verboselog){write-ezlogs ">>>> Getting Status of all known Twitch Streams" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
    try{      
      if($synchash.All_Twitch_Media.count -gt 0){
        if(!$synchash.checktwitch_scriptblock){
          $synchash.checktwitch_scriptblock = {
            Param(
              [string]$StreamName,
              $media,
              [switch]$CheckAll,
              [switch]$Test,
              [switch]$Use_runspace,
              $thisApp,
              $synchash,
              $hashsetup,
              [switch]$Startup,
              [switch]$Update_Twitch_Profile,
              [switch]$Export_Profile,
              [string]$Media_Profile_Directory,
              [switch]$Refresh_Follows,
              [switch]$Enable_liveAlert,
              [switch]$Verboselog
            )
            try{
              $checktwitch_stopwatch = [system.diagnostics.stopwatch]::StartNew() 
              Update-TwitchStatus @PSBoundParameters
            }catch{
              write-ezlogs "An exception occurred in checktwitch_scriptblock" -catcherror $_
            }finally{
              if($checktwitch_stopwatch){
                $checktwitch_stopwatch.stop()
                write-ezlogs ">>>> Get-TwitchStatus Measure" -PerfTimer $checktwitch_stopwatch -Perf -logtype Twitch
                $GetTwitch_stopwatch = $Null
              }
              if($thisApp.Config.Dev_mode){
                [void][ScriptBlock].GetMethod('ClearScriptBlockCache', [System.Reflection.BindingFlags]'Static,NonPublic').Invoke($Null, $Null)
                write-ezlogs ('Memory: {0:n1} MB' -f $([System.GC]::GetTotalMemory($true) / 1MB)) -logtype Twitch -Dev_mode
              }
            }
          }
        }
        if($Use_runspace){
          Start-Runspace -scriptblock $synchash.checktwitch_scriptblock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "checktwitch_runspace" -thisApp $thisApp -CheckforExisting -function_list 'Write-Ezlogs','Update-MainWindow','Update-TwitchStatus','Test-ValidPath' -RestrictedRunspace -Command_list 'Set-StrictMode','Get-Module' 
        }else{
          Invoke-Command -ScriptBlock $synchash.checktwitch_scriptblock
        }
      }else{
        write-ezlogs "[Get-TwitchStatus] Unable to find any valid twitch media!" -showtime -warning -logtype Twitch -LogLevel 2
      }
    }catch{
      write-ezlogs "[Get-TwitchStatus] An exception occurred getting status of Twitch streams!" -showtime -catcherror $_
      Update-Notifications -Level 'ERROR' -Message "An exception occurred getting status of Twitch streams!" -VerboseLog -Message_color "Red" -thisApp $thisApp -synchash $synchash -Open_Flyout
    }      
    #$twitchStreams = $synchash.
  }elseif($Update_Twitch_Profile){
    if(!$synchash.update_twitch_Profile_scriptblock){
      $synchash.update_twitch_Profile_scriptblock = {
        Param(
          [string]$StreamName,
          $media,
          [switch]$CheckAll,
          [switch]$Use_runspace,
          $thisApp,
          $synchash,
          $hashsetup,
          [switch]$Startup,
          [switch]$Update_Twitch_Profile,
          [switch]$Export_Profile,
          [string]$Media_Profile_Directory,
          [switch]$Refresh_Follows,
          [switch]$Enable_liveAlert,
          [switch]$Verboselog
        )
        try{
          try{
            $internet_Connectivity = Test-ValidPath -path 'www.twitch.tv' -PingConnection -timeout_milsec 1000
          }catch{
            write-ezlogs "Ping test failed for: www.twitch.tv - trying 1.1.1.1" -Warning -logtype Twitch
          }finally{
            try{
              if(!$internet_Connectivity){
                $internet_Connectivity = Test-ValidPath -path '1.1.1.1' -PingConnection -timeout_milsec 2000
              }
            }catch{
              write-ezlogs "Secondary ping test failed for: 1.1.1.1" -Warning -logtype Twitch
              $internet_Connectivity = $null
            }
          }
          if($internet_Connectivity){
            $AllTwitch_Media_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml') 
            $libraryChanges = 0
            $ConfigUpdateChanges = 0
            $PlaylistChanges = 0
            Import-Module "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
            foreach($m in $media){
              if($M.id -and $m.source -eq 'Twitch'){
                if($m.Enable_liveAlert -ne $Enable_liveAlert){
                  $libraryChanges++
                  $m.Enable_liveAlert = $Enable_liveAlert
                }
                write-ezlogs "[Get-TwitchStatus-UpdateProfile] Updating Twitch profiles for ID: $($m.id)"-logtype Twitch
                $Playlist_to_update = $synchash.all_playlists | & { process {if ($_.playlist_tracks.values.id -eq $m.id){$_}}}
                foreach($playlist in  $Playlist_to_update){
                  foreach($track in $playlist.playlist_tracks.values){
                    if($track.id -eq $m.id -and $track.Enable_LiveAlert -ne $m.Enable_LiveAlert){
                      $PlaylistChanges++
                      write-ezlogs ">>>> Updating Twitch Live notifications to: $($m.Enable_LiveAlert) -- for channel: $($track.title) -- in playlist: $($playlist.Name)" -logtype Twitch
                      $track.Enable_LiveAlert = $m.Enable_LiveAlert
                    }
                  }
                }
                if($thisapp.config.Twitch_Playlists.id){
                  $Config_index = $thisapp.config.Twitch_Playlists.id.indexof($m.id)
                  if($Config_index -ne -1){               
                    $Config_Twitch = $thisapp.config.Twitch_Playlists[$Config_index]                      
                  }elseif($thisapp.config.Twitch_Playlists.Name.indexof($m.Name) -ne -1){
                    $Config_Twitch = $thisapp.config.Twitch_Playlists[$thisapp.config.Twitch_Playlists.Name.indexof($m.Name)]
                  }
                  if($Config_Twitch -and $Config_Twitch.Enable_LiveAlert -ne $m.Enable_LiveAlert){
                    $ConfigUpdateChanges++
                    $Config_Twitch.Enable_LiveAlert = $m.Enable_LiveAlert
                  }
                }
                if($synchash.All_Twitch_Media.count -eq 0 -and [System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path)){
                  write-ezlogs "[Get-TwitchStatus-UpdateProfile] >>>> Unable to find twitch media, importing All Twitch Media Profile at $AllTwitch_Media_Profile_File_Path" -logtype Twitch
                  $all_Twitch_profile = Import-SerializedXML -Path $AllTwitch_Media_Profile_File_Path
                  if($all_Twitch_profile.id){
                    $index = $all_Twitch_profile.id.IndexOf($m.id)
                    if($index -ne -1){                 
                      $Library_media_to_update = $all_Twitch_profile[$index]
                    }elseif($all_Twitch_profile.name -and $all_Twitch_profile.name.IndexOf($m.Name) -ne -1){
                      $Library_media_to_update = $all_Twitch_profile[$all_Twitch_profile.name.IndexOf($m.Name)]
                    }
                  }     
                }else{
                  $index = $synchash.All_Twitch_Media.id.IndexOf($m.id)
                  if($index -ne -1){
                    $Library_media_to_update = $synchash.All_Twitch_Media[$index]
                  }elseif($synchash.All_Twitch_Media.name.IndexOf($m.Name) -ne -1){
                    $Library_media_to_update = $synchash.All_Twitch_Media[$synchash.All_Twitch_Media.name.IndexOf($m.Name)]
                  }
                }
                foreach($profile in $Library_media_to_update){
                  if($profile.Enable_LiveAlert -ne $m.Enable_LiveAlert){
                    $libraryChanges++
                    $profile.Enable_LiveAlert = $m.Enable_LiveAlert
                  }
                }
              }else{
                write-ezlogs "[Get-TwitchStatus-UpdateProfile] No Twitch media ID was provided - unable to update profile!" -warning -logtype Twitch
              }
            }
            if($ConfigUpdateChanges -gt 0){
              write-ezlogs ">>>> Saving updated config file to $($thisApp.Config.Config_Path)" -logtype Twitch
              Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
            }
            if($PlaylistChanges -gt 0){
              write-ezlogs ">>>> Saving updated playlists profile to $($thisApp.Config.Playlists_Profile_Path)" -logtype Twitch
              Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
            }
            if($libraryChanges -gt 0 -or $Export_Profile){
              write-ezlogs ">>>> Saving updated Twitch_Media profile to $AllTwitch_Media_Profile_File_Path" -logtype Twitch
              Export-SerializedXML -InputObject $synchash.All_Twitch_Media -path $AllTwitch_Media_Profile_File_Path
              if($synchash.Refresh_TwitchMedia_timer){
                $synchash.Refresh_TwitchMedia_timer.tag = 'QuickRefresh_TwitchMedia_Button'
                $synchash.Refresh_TwitchMedia_timer.start()  
              }
            }
          }else{
            write-ezlogs "Cannot check status of Twitch streams, unable to connect to 'www.twitch.tv'" -warning -AlertUI
          }
        }catch{
          write-ezlogs "An exception occurred in update_twitch_Profile_scriptblock" -catcherror $_
        }   
      }
    }
    Start-Runspace $synchash.update_twitch_Profile_scriptblock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "update_twitch_Profile_runspace" -thisApp $thisApp -RestrictedRunspace -CheckforExisting -function_list 'Write-Ezlogs','Test-ValidPath' -Command_list 'Set-StrictMode','Get-Module'
  }else{
    try{
      write-ezlogs "Get-TwitchStatus currently work with refreshing just one provided stream name!! Needs to be completed! Maybe -  params: $($PSBoundParameters | out-string)" -warning
      return
    }catch{
      write-ezlogs "[Get-TwitchStatus] An exception occurred getting status of Twitch stream $($StreamName)" -showtime -catcherror $_
    }
  }
}
#---------------------------------------------- 
#endregion Get-TwitchStatus Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-TwitchMonitor Function
#----------------------------------------------
function Start-TwitchMonitor
{
  Param (
    [string]$StreamName,
    $Interval,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging
  ) 
  try{
    write-ezlogs "#### Starting Twitch Monitor ####" -color yellow -linesbefore 1 -logtype Twitch -LogLevel 2
    if($synchash.TwitchMonitor_timer.isEnabled){
      write-ezlogs "| Stopping existing TwitchMonitor timer" -logtype Twitch -warning
      $synchash.TwitchMonitor_timer.stop()
    }
    if(-not [bool]($Interval -as [TimeSpan])){
      $interval = [TimeSpan]::FromHours((Convert-TimespanToInt -Timespan $Interval))
    }
    $Sleep_Value = [TimeSpan]::Parse($Interval)
    write-ezlogs " | Interval: $sleep_value" -showtime -logtype Twitch -LogLevel 2
    if($thisApp.config.Twitch_Update -and $Sleep_Value -ne $null){
      if(!$synchash.TwitchMonitor_timer){
        $synchash.TwitchMonitor_timer = [System.Windows.Threading.DispatcherTimer]::new()
        if(!$synchash.TwitchMonitor_timer_ScriptBlock){
          $synchash.TwitchMonitor_timer_ScriptBlock = {
            Param($sender,[System.EventArgs]$e)
            try{
              if($thisApp.config.Twitch_Update -and $thisApp.config.Twitch_Update_Interval -ne $null){
                $checkupdate_timer = [system.diagnostics.stopwatch]::StartNew()
                Write-ezlogs "[Start-TwitchMonitor] >>>> Refreshing status for all Twitch Streams" -showtime -logtype Twitch -LogLevel 2 -linesbefore 1
                Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace #:$false
                $checkupdate_timer.stop()
                Write-ezlogs "[Start-TwitchMonitor] Ran for: $($checkupdate_timer.Elapsed.TotalSeconds) seconds" -showtime -logtype Twitch -LogLevel 2
                $checkupdate_timer = $Null
              }else{
                write-ezlogs "[Start-TwitchMonitor] Twitch Status Monitor has ended - Twitch_Update: $($thisApp.config.Twitch_Update) - Twitch_Update_Interval: $($thisApp.config.Twitch_Update_Interval)" -showtime -warning -logtype Twitch -LogLevel 2
                $sender.Stop()
              }
            }catch{
              $sender.Stop()
              write-ezlogs "An exception occurred in TwitchMonitor_timer_ScriptBlock -- TwitchMonitor has been stopped" -catcherror $_      
            }
          }
        }
      }
      $synchash.TwitchMonitor_timer.Interval = $Sleep_Value
      $synchash.TwitchMonitor_timer.Remove_Tick($synchash.TwitchMonitor_timer_ScriptBlock)
      $synchash.TwitchMonitor_timer.add_Tick($synchash.TwitchMonitor_timer_ScriptBlock)
      $synchash.TwitchMonitor_timer.start()
      Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace #:$false
    }else{
      write-ezlogs "[Start-TwitchMonitor] No interval value was provided or Twitch_Update config value is not enabled, cannot continue" -showtime -warning -logtype Twitch -LogLevel 2
    }
  }catch{
    write-ezlogs "An exception occured in Start-TwitchMonitor" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Start-TwitchMonitor Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-Twitch Function
#----------------------------------------------
function Get-Twitch
{
  Param (
    [string]$Twitch_URL,
    [switch]$Import_Profile,
    $thisApp,
    $log,
    $synchash,
    [switch]$UpdatePlaylists,
    [switch]$refresh,
    [switch]$Startup,
    [switch]$update_global,
    [switch]$Export_Profile,
    [switch]$Get_Playlists,
    [switch]$Export_AllMedia_Profile,
    [string]$Media_Profile_Directory,
    $Twitch_URLs,
    [switch]$Verboselog = $thisApp.Config.Dev_Mode
  )
  $GetTwitch_stopwatch = [system.diagnostics.stopwatch]::StartNew() 
  #$illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
  #$pattern = "[™$illegal]"
  #$pattern2 = "[:$illegal]"
  #Twitch Profile Path
  if($thisApp.TwitchMonitorEnabled){
    write-ezlogs ">>>> Disabling Twitch Monitor" -logtype Twitch
    $thisApp.TwitchMonitorEnabled = $false
  }
  $AllTwitch_Media_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,"All-Twitch_MediaProfile")
  if (!([System.IO.Directory]::Exists($AllTwitch_Media_Profile_Directory_Path))){
    [void][System.IO.Directory]::CreateDirectory($AllTwitch_Media_Profile_Directory_Path)
  }
  $AllTwitch_Media_Profile_File_Path = [System.IO.Path]::Combine($AllTwitch_Media_Profile_Directory_Path,"All-Twitch_Media-Profile.xml")  
  if($Import_Profile -and ([System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path))){ 
    if($Verboselog){write-ezlogs "[Get-Twitch] | Importing Twitch Media Profile: $AllTwitch_Media_Profile_File_Path" -showtime -enablelogs -logtype Twitch -VerboseDebug:$Verboselog}
    try{
      $synchash.All_Twitch_Media = Import-SerializedXML -Path $AllTwitch_Media_Profile_File_Path
    }catch{
      write-ezlogs "[Get-Twitch] An exception occurred importing Twitch media profiles at $AllTwitch_Media_Profile_File_Path" -catcherror $_
    }
    if($Startup -and !$refresh){
      if($GetTwitch_stopwatch){
        $GetTwitch_stopwatch.stop()
        write-ezlogs "####################### Get-Twitch Finished" -PerfTimer $GetTwitch_stopwatch -Perf -logtype Twitch -GetMemoryUsage -forceCollection
        $GetTwitch_stopwatch = $Null
      }
      return   
    }    
  }else{
    write-ezlogs "[Get-Twitch] | Twitch Media Profile to import not found at $AllTwitch_Media_Profile_Directory_Path....Attempting to build new profile" -showtime -logtype Twitch
    $synchash.All_Twitch_Media = [System.Collections.Generic.List[Media]]::new()
  }   
  if($Twitch_URL){
    $twitch_urls = $Twitch_URL
    if(!$synchash.ContainsKey('All_Twitch_Media') -and ([System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path))){ 
      write-ezlogs "[Get-Twitch] | Importing Twitch Media Profile: $AllTwitch_Media_Profile_Directory_Path" -showtime -enablelogs -logtype Twitch -LogLevel 2
      $synchash.All_Twitch_Media = Import-SerializedXML -Path $AllTwitch_Media_Profile_File_Path
    }
  } 
  if(!$refresh -and $synchash.All_Twitch_Media.url){
    $twitch_urls = $twitch_urls | Where-Object {($_.path -and $synchash.All_Twitch_Media.url -notcontains $_.path) -or ($_.path -and $thisApp.Config.Twitch_Playlists.path -notcontains $_.path) -or ((Test-URL $_) -and $thisApp.Config.Twitch_Playlists.path -notcontains $_) -or ((Test-URL $_) -and $synchash.All_Twitch_Media.url -notcontains $_)}    
  }
  if($twitch_urls.Name){
    $twitch_Streams = $(($twitch_urls.Name | Where-Object {$_}))
  }elseif((Test-URL $twitch_urls)){
    $twitch_Streams = $((Get-Culture).textinfo.totitlecase((($twitch_urls | Where-Object {$_}) | split-path -leaf).tolower()).trim())
  }
  write-ezlogs "[Get-Twitch] | Number of Twitch urls to process $(@($twitch_Streams).count)" -showtime -logtype Twitch -LogLevel 2
  $TwitchData = Get-TwitchAPI -StreamName $twitch_Streams -thisApp $thisApp
  $total_channels = @($Twitch_URLs).count
  $synchash.processed_Twitch_Channels = 0
  #$synchash.Temp_TwitchPlaylist_to_Save = [System.Collections.Generic.List[Object]]::new()
  if($synchash.all_playlists -and $synchash.all_playlists -isnot [System.Collections.Generic.List[Playlist]]){
    $synchash.Temp_all_Playlists = $synchash.all_playlists | ConvertTo-Playlists -List
  }elseif($synchash.all_playlists){
    $synchash.Temp_all_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchash.all_playlists)
  }
  foreach($channel in $Twitch_URLs){
    try{
      $id = $Null  
      $twitch_channel = $Null
      $followed = $Null
      $channel_url = $null  
      if($channel.path -match 'twitch\.tv' -or $channel -match 'twitch\.tv'){ 
        if($channel.Name){
          $twitch_channel = $channel.Name
        }elseif(Test-URL $channel){
          $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($channel | split-path -leaf).tolower())
        }
        $synchash.processed_Twitch_Channels++
        if($Verboselog){write-ezlogs "[Get-Twitch] >>>> Processing Twitch Channel $($twitch_channel)" -logtype Twitch -VerboseDebug:$Verboselog}
        if($channel.path){
          $channel_url = $channel.path
        }elseif(Test-URL $channel){
          $channel_url = $channel
        }
        if($TwitchData){
          $TwitchAPI = $TwitchData | & { process {if ($_.user_name -eq $twitch_channel -or $_.user_id -eq $channel.id){$_}}}
        }
        if($TwitchAPI.user_id){
          $id = $TwitchAPI.user_id
        }elseif($channel.id){
          $id = $channel.id
        }elseif($twitch_channel){
          $idbytes = [System.Text.Encoding]::UTF8.GetBytes("$($twitch_channel)-TwitchChannel")
          $id = [System.Convert]::ToBase64String($idbytes)
        }
        if($channel.Followed){
          try{
            if([Datetime]::TryParse($channel.Followed,[ref]([DateTime]::now))){
              $followed = [Datetime]::Parse($channel.Followed)
            }else{
              $followed = Get-Date $channel.Followed -ErrorAction Continue
            }
            if($followed){
              $followed = $followed.ToShortDateString()
            }         
          }catch{
            write-ezlogs "[Get-Twitch] An exception occurred parsing followed date: $($channel.Followed)" -showtime -catcherror $_
          }    
        }else{
          $followed = $Null
        }
        if($synchash.ContainsKey('All_Twitch_Media')){
          #lock-object -InputObject $synchash.All_Twitch_Media.SyncRoot -ScriptBlock {
          if(!$synchash.All_Twitch_Media.id){
            $mediaCheck = $id
          }else{
            $mediaCheck = ($synchash.All_Twitch_Media.id.IndexOf($id) -eq -1)
          }
          #}   
        }    
        if($mediaCheck){
          if($thisApp.Config.Twitch_Playlists.Path -notcontains $channel_url){
            if($channel.Number){
              $number = $channel.Number
            }elseif(@($thisApp.Config.Twitch_Playlists).count -lt 1){
              $Number = 1
            }else{
              $Number = $thisApp.Config.Twitch_Playlists.Number | select-Object -last 1
              $Number++
            }
            $itemssource = [Twitch_Playlist]@{
              Number=$Number
              Name=$twitch_channel
              Path=$channel_url
              Type='TwitchChannel'
              Followed=$followed
              ID = $id
            }
            write-ezlogs "[Get-Twitch] | Adding url to Twitch Channel to thisApp.Config.Twitch_Playlists : $twitch_channel" -showtime -logtype Twitch -LogLevel 2
            [void]$thisApp.Config.Twitch_Playlists.add($itemssource)
          }
          if(!$TwitchAPI.type){          
            $title = "Twitch: $($twitch_channel)"
            $Live_Status = 'Offline'
            $Status_msg = ''
            $Stream_title = ''
            [int]$viewer_count = 0
          }elseif($TwitchAPI.type -match 'live'){
            $title = "Twitch: $($TwitchAPI.user_name)"
            $Live_Status = 'Live'
            $Status_msg = "$($TwitchAPI.game_name)"
            $Stream_title = $TwitchApi.title
            [int]$viewer_count = $TwitchAPI.viewer_count
          }elseif($TwitchAPI.type){
            $title = "Twitch: $($TwitchAPI.user_name)"
            $Live_Status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($TwitchAPI.type).tolower())
            $Status_msg = "$($TwitchAPI.game_name)"
            $Stream_title = $TwitchApi.title
            [int]$viewer_count = $TwitchAPI.viewer_count
          }else{
            $title = "Twitch: $($twitch_channel)"
            $Live_Status = 'Offline'
            $Status_msg = ''
            $Stream_title = ''
            [int]$viewer_count = 0
          }           
          if($TwitchAPI.thumbnail_url){
            $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
          }else{
            $thumbnail = $null
          }
          if($TwitchAPI.profile_image_url){
            $profile_image_url = $TwitchAPI.profile_image_url
            $offline_image_url = $TwitchAPI.offline_image_url
            $description = $TwitchAPI.description
          }else{
            $profile_image_url = $Null
            $offline_image_url = $Null  
            $description = $Null   
          } 
          if($profile_image_url){
            if($Verboselog){write-ezlogs "[Get-Twitch] Profile_Image_url: $($profile_image_url)" -showtime -logtype Twitch -VerboseDebug:$Verboselog}     
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              if($Verboselog){write-ezlogs "[Get-Twitch] Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
              [void][System.IO.Directory]::CreateDirectory($thisApp.config.image_Cache_path)
            }     
            $encodeduri = $Null
            $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$([System.Uri]::new($profile_image_url).Segments | select-Object -last 1)-Twitch")
            $encodeduri = [System.Convert]::ToBase64String($encodedBytes)
            $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
            if([System.IO.File]::Exists($image_Cache_path)){
              $cached_image = $image_Cache_path
            }else{    
              $retry = $false     
              if($Verboselog){write-ezlogs "[Get-Twitch] | Destination path for cached image: $image_Cache_path" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
              try{
                if([System.IO.File]::Exists($profile_image_url)){
                  if($Verboselog){write-ezlogs "[Get-Twitch] | Cached Image not found, copying image $($profile_image_url) to cache path $image_Cache_path"  -showtime -logtype Twitch -VerboseDebug:$Verboselog}
                  [void][system.io.file]::Copy($profile_image_url, $image_Cache_path,$true)
                }elseif((Test-URL $profile_image_url)){
                  $uri = [system.uri]::new($profile_image_url)
                  if($Verboselog){write-ezlogs "[Get-Twitch] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
                  try{
                    $webclient = [System.Net.WebClient]::new()
                    [void]$webclient.DownloadFile($uri,$image_Cache_path)
                    $retry = $false
                  }catch{
                    write-ezlogs "[Get-Twitch] An exception occurred downloading image $uri to path $image_Cache_path" -showtime -catcherror $_
                    $retry = $true
                  }finally{
                    if($webclient){
                      $webclient.Dispose()
                      $webclient = $Null
                    }
                  }
                  if($retry -and $twitch_channel){
                    try{
                      write-ezlogs "[Get-Twitch] Checking Twitch API for possible updated profile_image_url for streamer: $($twitch_channel)" -showtime -warning -LogLevel 2 -logtype Twitch
                      $TwitchData = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
                    }catch{
                      write-ezlogs "[Get-Twitch] An exception occurred executing Get-TwitchAPI for steamname $twitch_channel" -showtime -catcherror $_
                    }
                    if((Test-URL $TwitchData.profile_image_url)){
                      try{
                        write-ezlogs "[Get-Twitch] | Trying again with newly retrieved profile_image url $($TwitchData.profile_image_url)" -showtime -LogLevel 2 -logtype Twitch
                        $webclient = [System.Net.WebClient]::new()
                        [void]$webclient.DownloadFile($TwitchData.profile_image_url,$image_Cache_path)
                      }catch{
                        write-ezlogs "[Get-Twitch] An exception occurred downloading image $($TwitchData.profile_image_url) to path $image_Cache_path" -showtime -catcherror $_
                      }finally{
                        if($webclient){
                          $webclient.Dispose()
                          $webclient = $Null
                        }
                      }
                      $profile_image_url = $TwitchData.profile_image_url
                    }
                  }
                }                          
              }catch{
                $cached_image = $Null
                write-ezlogs "[Get-Twitch] An exception occurred attempting to download $uri to path $image_Cache_path for Twitch channel: $($twitch_channel)" -showtime -catcherror $_
              }           
            }           
          }   
          if(-not [string]::IsNullOrEmpty($thisApp.Config.TwitchMedia_Display_Syntax)){
            $DisplayName = $thisApp.Config.TwitchMedia_Display_Syntax -replace '%channel%',$twitch_channel -replace '%title%',$title -replace '%type%','TwitchChannel' -replace '%live_status%',$Live_Status -replace '%stream_title%',$Stream_title
          }else{
            $DisplayName = $Null
          } 
          $twitch_item = [Media]@{
            'Id' = $id
            'User_id' = $TwitchAPI.user_id
            'Artist' = $twitch_channel
            'Name' = $twitch_channel
            'Title' = $title
            'Playlist' = $twitch_channel
            'Playlist_ID' = $id
            'Playlist_url' = $channel_url
            'Channel_Name' = $twitch_channel
            'Description' =  $description
            'Live_Status' = $Live_Status
            'Stream_title' = $Stream_title
            'Status_msg' = $Status_msg
            'Viewer_Count' = $viewer_count
            'Cached_Image_Path' = $cached_image
            'Profile_Image_Url' = $profile_image_url
            'Offline_Image_Url' = $offline_image_url
            'Chat_Url' = "https://twitch.tv/$($twitch_channel)/chat"
            'Source' = 'Twitch'
            'Followed' = $followed
            'Profile_Date_Added' = [DateTime]::Now.ToString()
            'url' = $channel_url
            'type' = 'TwitchChannel'
            'Duration' = ''
            'Display_Name' = $DisplayName
          }
          if($Verboselog){write-ezlogs "[Get-Twitch] | Adding Twitch stream channel: $twitch_channel - Status: $Live_Status" -showtime -logtype Twitch -VerboseDebug:$Verboselog}
          lock-object -InputObject $synchash.All_Twitch_Media.SyncRoot -ScriptBlock {
            [void]$synchash.All_Twitch_Media.Add($twitch_item)
          }
          try{
            if($UpdatePlaylists -and $synchash.Temp_all_Playlists){
              $synchash.Temp_all_Playlists | & { process {
                  $playlist = $_
                  $synchash.Temp_TwitchPlaylist_to_Save = $false
                  $track_index = $Null
                  $track = $null
                  try{           
                    $urls = [System.Collections.Generic.list[object]]$playlist.PlayList_tracks.values.url
                    if($urls){
                      $track_index = $urls.indexof($twitch_item.url)
                    }
                    if($track_index -ne -1 -and $track_index -ne $null){
                      $track = $playlist.PlayList_tracks[$track_index]
                      if($track){
                        foreach ($property in $twitch_item.psobject.properties.name){
                          if($property -notin 'Enable_LiveAlert','Profile_Date_Added' -and [bool]$track.PSObject.Properties[$property] -and $track.$property -ne $twitch_item.$property){
                            write-ezlogs " | Updating playlist track property: '$($property)' from value: '$($track.$property)' - to: '$($twitch_item.$property)'" -logtype Twitch
                            $track.$property = $twitch_item.$property
                            $synchash.Temp_TwitchPlaylist_to_Save = $true
                          }elseif($property -notin 'Enable_LiveAlert','Profile_Date_Added' -and -not [bool]$track.PSObject.Properties[$property]){
                            write-ezlogs " | Adding playlist track property: '$($property)' with value: $($twitch_item.$property)" -logtype Twitch
                            $synchash.Temp_TwitchPlaylist_to_Save = $true
                            $track.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new($property,$twitch_item.$property))
                          }
                        }
                      }
                    }
                  }catch{
                    write-ezlogs "An exception occurred processing playlist: $($playlist | out-string)" -CatchError $_
                  }finally{
                    $track = $Null
                  }
              }}                     
            } 
          }catch{
            write-ezlogs "An exception occurred updating custom playlists for Twitch items" -showtime -catcherror $_
          }           
          try{
            $Controls_to_Update = [System.Collections.Generic.List[Object]]::new(3)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'TwitchMedia_Progress_Label'
                'Property' = 'Text'
                'Value' = "Imported ($($synchash.processed_Twitch_Channels) of $($total_channels)) Twitch Channels"
            })              
            [void]$Controls_to_Update.Add($newRow) 
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'TwitchMedia_Progress2_Label'
                'Property' = 'Text'
                'Value' = "Current Channel: $twitch_channel"
            })             
            [void]$Controls_to_Update.Add($newRow)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'TwitchMedia_Progress2_Label'
                'Property' = 'Visibility'
                'Value' = "Visible"
            })             
            [void]$Controls_to_Update.Add($newRow)
            Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
          }catch{
            write-ezlogs "An exception occurred updating TwitchMedia_Progress_Ring" -showtime -catcherror $_
          }   
        }
      }
    }catch{
      write-ezlogs "[Get-Twitch] An exception occurred processing twitch url $($channel)" -showtime -catcherror $_
    }
  }
  if($export_profile -and $synchash.All_Twitch_Media.count -gt 1 -and $AllTwitch_Media_Profile_File_Path){
    write-ezlogs "[Get-Twitch] >>>> Saving Available Twitch Media profile to $AllTwitch_Media_Profile_File_Path" -showtime -logtype Twitch -LogLevel 2
    Export-SerializedXML -InputObject $synchash.All_Twitch_Media -path $AllTwitch_Media_Profile_File_Path
  } 
  write-ezlogs "[Get-Twitch] | Number of Twitch Channels found: $($synchash.All_Twitch_Media.Count)" -showtime -logtype Twitch -LogLevel 2
  if($UpdatePlaylists -and $synchash.Temp_TwitchPlaylist_to_Save){ 
    if($synchash.Temp_all_Playlists){
      Export-SerializedXML -InputObject $synchash.Temp_all_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
      [void]$synchash.Temp_all_Playlists.clear()
      $synchash.Temp_all_Playlists = $Null
      [void]$synchash.Remove('Temp_all_Playlists')
    }
    $synchash.Temp_TwitchPlaylist_to_Save = $null
    [void]$synchash.Remove('Temp_TwitchPlaylist_to_Save')
    Get-Playlists -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Import_Playlists_Cache
  }
  if($GetTwitch_stopwatch){
    $GetTwitch_stopwatch.stop()
    write-ezlogs "####################### Get-Twitch Finished" -PerfTimer $GetTwitch_stopwatch -Perf -logtype Twitch -GetMemoryUsage -forceCollection
    $GetTwitch_stopwatch = $Null
  }  
  return  
}
#---------------------------------------------- 
#endregion Get-Twitch Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-TwitchAPI','Get-TwitchStatus','Start-TwitchMonitor','Get-TwitchApplication','Set-TwitchApplication','Get-TwitchAccessToken','Get-TwitchFollows','Get-Twitch','Get-TwitchVideos','Update-TwitchStatus')