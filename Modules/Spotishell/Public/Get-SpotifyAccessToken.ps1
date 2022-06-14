<#
    .SYNOPSIS
    Gets a Spotify access token
    .DESCRIPTION
    Gets a Spotify access token using defined SpotifyApplication
    It follows the Authorization Code Flow (https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow)
    .EXAMPLE
    PS C:\> Get-SpotifyAccessToken -ApplicationName 'dev'
    Looks for a saved credential named "dev" and tries to get an access token with it's credentials
    .PARAMETER ApplicationName
    Specifies the Spotify Application Name (otherwise default is used)
#>
function Get-SpotifyAccessToken {

  [CmdletBinding()]
  param (
    [String]
    $ApplicationName,
    $thisApp,
    $thisScript,
    [switch]$First_Run
  )

  # Get Application
  if(!$ApplicationName -and $thisApp.Config.App_Name){
    $ApplicationName = $thisApp.Config.App_Name
  }
  try{
    $Application = Get-SpotifyApplication -Name $ApplicationName
  }catch{
    write-ezlogs "An exception occurred getting Spotify Application $Application" -showtime -catcherror $_
  }
  

  # If Token is available
  if ($Application.Token.access_token) {

    # Check that Access Token is not expired
    try{       
      $Expires = [DateTime]::ParseExact($Application.Token.Expires, 'u', $null)
      $Expire_status = (Get-Date) -le $Expires.AddSeconds(-10)
      
    }catch{
      write-ezlogs "An exception occurred parsing token expiration from application $($application | out-string)" -showtime -catcherror $_
    }
    
    if ($Expire_status) {
      # Access Token is still valid, then use it
      return $Application.Token.access_token
    }
    else {
      # Access Token is expired, need to be refreshed
            
      # ------------------------------ Token Refreshed retrieval ------------------------------
      # STEP 1 : Prepare
      $Uri = 'https://accounts.spotify.com/api/token'
      $Method = 'Post'
      $Body = @{
        grant_type    = 'refresh_token'
        refresh_token = $Application.Token.refresh_token
        client_id     = $Application.ClientId # alternative way to send the client id and secret
        client_secret = $Application.ClientSecret # alternative way to send the client id and secret
      }

      # STEP 2 : Make request to the Spotify Accounts service
      try {
        Write-Verbose 'Send request to refresh access token.'
        $CurrentTime = Get-Date
        $Response = Invoke-WebRequest -Uri $Uri -Method $Method -Body $Body -UseBasicParsing
      }
      catch {
        # Don't throw error if Refresh token is revoked or authentication failed
        if ($_.Exception.Response.StatusCode -ne 400 -and $_.Exception.Response.StatusCode -ne 401) {
          Throw "Error occured during request of refreshed access token : $([int]$_.Exception.Response.StatusCode) - $($PSItem[0].ToString())"
        }
      }

      # STEP 3 : Parse and save response
      if ($Response) {
        $ResponseContent = $Response.Content | ConvertFrom-Json

        $Token = @{
          access_token  = $ResponseContent.access_token
          token_type    = $ResponseContent.token_type
          scope         = $ResponseContent.scope
          expires       = $CurrentTime.AddSeconds($ResponseContent.expires_in).ToString('u')
          refresh_token = if ($ResponseContent.refresh_token) { $ResponseContent.refresh_token } else { $Application.Token.refresh_token }
        }

        Set-SpotifyApplication -Name $ApplicationName -Token $Token
        Write-Verbose 'Successfully saved Refreshed Token'

        return $Token.access_token
      }
    }
  }else{
    write-ezlogs "Unable to get access token - Starting Spotify Authentication capture process - Application Token returned: $($Application.Token | out-string)" -showtime -warning

  }

  # Starting this point, neither valid access token were found nor successful refresh were done
  # So we start Authorization Code Flow from zero

  # ------------------------------ Authorization Code retrieval ------------------------------
  # STEP 1 : Prepare
  $EncodedRedirectUri = [System.Web.HTTPUtility]::UrlEncode($Application.RedirectUri)
  $EncodedScopes = @( # requesting all existing scopes
    'ugc-image-upload',
    'playlist-modify-public',
    'playlist-read-private',
    'playlist-modify-private',
    'playlist-read-collaborative',
    'app-remote-control',
    'streaming',
    'user-read-playback-position',
    'user-read-recently-played',
    'user-top-read',
    'user-follow-modify',
    'user-follow-read',
    'user-read-playback-state',
    'user-read-currently-playing',
    'user-modify-playback-state',
    'user-library-read',
    'user-library-modify',
    'user-read-private',
    'user-read-email'
  ) -join '%20'
  $State = (New-Guid).ToString()

  $Uri = 'https://accounts.spotify.com/authorize'
  $Uri += "?client_id=$($Application.ClientId)"
  $Uri += '&response_type=code'
  $Uri += "&redirect_uri=$EncodedRedirectUri"
  $Uri += "&state=$State"
  $Uri += "&scope=$EncodedScopes"

  # Create an Http Server
  $Listener = [System.Net.HttpListener]::new() 
  if($Application.RedirectUri){
    $Prefix = $Application.RedirectUri.Substring(0, $Application.RedirectUri.LastIndexOf('/') + 1) # keep uri until the last '/' included
    $null = $Listener.Prefixes.Add($Prefix)
  }
  $Listener.Start()
  if ($Listener.IsListening) {
    Write-Verbose 'HTTP Server is ready to receive Authorization Code'
    $HttpServerReady = $true
  }
  else {
    Write-Verbose 'HTTP Server is not ready. Fall back to manual method'
    $HttpServerReady = $false
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
    Write-ezlogs "Opening Show-Weblogin for capture of spotify login with URL $URI" -showtime
    if($thisApp){
      try{
        if($hashsetup.Window.isVisible){
          $hashsetup.Window.hide()
        }      
        Show-WebLogin -SplashTitle "Spotify Account Login" -Message "Please login with your Spotify account. When finished click Close to continue"  -Message_2 "NOTE: You must also login to the Windows Spotify App at least one time before being able to manage music. If spotify is not currently installed, this app will install the latest version" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL $URI -thisScript $thisScript -thisApp $thisApp -verboselog -Listener $Listener -First_Run $First_Run       
      }catch{
        write-ezlogs "[Get-SpotifyAccessToken] An exception occurred in Show-Weblogin" -showtime -catcherror $_
      }     
    }else{
      #rundll32 url.dll, FileProtocolHandler $URI
    }        
  }
  # STEP 3 : Get response
  if ($httpServerReady) {
    Write-Host 'Waiting 1 min for authorization acceptance'
    $Task = $null
    $StartTime = Get-Date
    while ($Listener.IsListening -and ((Get-Date) - $StartTime) -lt '0.00:01:00' ) {
    
      try{
        if ($null -eq $Task) {
          $task = $Listener.GetContextAsync()
        }
    
        if ($Task.IsCompleted) {
          $Context = $task.Result
          $Task = $null
          $Response = $context.Request.Url
          $ContextResponse = $context.Response
    
          [string]$html = '<script>close()</script>Thanks! You can close this window now.'
    
          $htmlBuffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert html to bytes
    
          $ContextResponse.ContentLength64 = $htmlBuffer.Length
          $ContextResponse.OutputStream.Write($htmlBuffer, 0, $htmlBuffer.Length)
          $ContextResponse.OutputStream.Close()               
          break;
        }      
      }catch{
        write-ezlogs "[Get-SpotifyAccessToken] An exception occurred in Spotishell HTTP listener" -showtime -catcherror $_
      }
    }     
    $Listener.Stop()
  }
  else {
    $Response = Read-Host 'Paste the entire URL that it redirects you to'
    $Response = [System.Uri]$Response
  }

  # STEP 4 : Check and Parse response
  # check Response
  if ($Response.OriginalString -eq '') {
    Throw 'Response of Authorization Code retrieval can''t be empty'
  }

  # parse query
  $ResponseQuery = [System.Web.HttpUtility]::ParseQueryString($Response.Query)

  # check state
  if ($ResponseQuery['state'] -ne $State) {
    write-ezlogs "State returned during Authorization Code retrieval doesn''t match state passed" -showtime -warning
    #Throw 'State returned during Authorization Code retrieval doesn''t match state passed'
  }

  # check if an error has been returned
  if ($ResponseQuery['error']) {
    write-ezlogs "Error occured during Authorization Code retrieval : $($ResponseQuery['error'])" -showtime -color red
  }
    
  # all checks are passed, we should have the code
  if ($ResponseQuery['code']) {
    $AuthorizationCode = $ResponseQuery['code']
  }
  else {
    write-ezlogs "Authorization Code not returned during Authorization Code retrieval" -showtime -warning
    #Throw 'Authorization Code not returned during Authorization Code retrieval'
  }

  # Authorization Code is in $AuthorizationCode

  # ------------------------------ Token retrieval ------------------------------
  # STEP 1 : Prepare
  $Uri = 'https://accounts.spotify.com/api/token'
  $Method = 'Post'
  $Body = @{
    grant_type    = 'authorization_code'
    code          = $AuthorizationCode
    redirect_uri  = $Application.RedirectUri
    client_id     = $Application.ClientId # alternative way to send the client id and secret
    client_secret = $Application.ClientSecret # alternative way to send the client id and secret
  }

  # STEP 2 : Make request to the Spotify Accounts service
  try {
    Write-Verbose 'Send request to get access token.'
    $CurrentTime = Get-Date
    $Response = Invoke-WebRequest -Uri $Uri -Method $Method -Body $Body -UseBasicParsing
  }
  catch {
    write-ezlogs "Error occured during request of access token : $($PSItem[0].ToString())" -showtime -color red
    return $false
    #Throw "Error occured during request of access token : $($PSItem[0].ToString())"
  }
    
  try {
    # STEP 3 : Parse and save response
    $ResponseContent = $Response.Content | ConvertFrom-Json

    $Token = @{
      access_token  = $ResponseContent.access_token
      token_type    = $ResponseContent.token_type
      scope         = $ResponseContent.scope
      expires       = $CurrentTime.AddSeconds($ResponseContent.expires_in).ToString('u')
      refresh_token = $ResponseContent.refresh_token
    }
    Set-SpotifyApplication -Name $ApplicationName -Token $Token 
    if($MahDialog_hash.Window){
      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
    }     
    return $Token.access_token
   
  }
  catch {
    write-ezlogs "[Get-SpotifyAccessToken] Error occured in while parsing and saving the response" -showtime -color red
    #Throw "Error occured during request of access token : $($PSItem[0].ToString())"
  }
  #Write-Verbose 'Successfully saved Token'

}