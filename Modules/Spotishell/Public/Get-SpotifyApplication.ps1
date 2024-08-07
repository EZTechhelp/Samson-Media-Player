<#
    .SYNOPSIS
    Retrieves saved spotify credential
    .DESCRIPTION
    Finds saved spotify credential on local machine if there is one.
    .EXAMPLE
    PS C:\> Get-SpotifyApplication
    Looks for a saved spotify application file of the name 'default'
    .EXAMPLE
    PS C:\> Get-SpotifyApplication -Name 'dev'
    Looks for a saved spotify application file of the name 'dev'
    .PARAMETER Name
    Specifies the name of the spotify application you're looking for
    .PARAMETER All
    Specifies that you're looking for all Spotify Application in store
#>
function Get-SpotifyApplication {

  param (
    [String]
    $Name = $thisApp.Config.App_Name,

    [switch]
    $FirstRun
  )

  if (!$Name) { $Name = 'Samson' }
  try{
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "An exception occurred getting SecretStore $name" -showtime -catcherror $_
  }
  if($secretstore){
    try{
      $ClientId = Get-secret -name SpotyClientId  -Vault $Name -ErrorAction Continue
      $ClientSecret = Get-secret -name SpotyClientSecret  -Vault $Name -ErrorAction Continue
      $RedirectUri = Get-secret -name SpotyRedirectUri -Vault $Name -ErrorAction Continue
    }catch{
      write-ezlogs "An exception occurred getting SpotyClientId ($($ClientId)) or SpotyClientSecret ($($ClientSecret)) or SpotyRedirectUri ($($RedirectUri)) from Secret vault $Name" -catcherror $_
      if($_ -match 'A valid password is required to access'){
        $unlock = $true
      }
    }
    if($unlock){
      try{
        write-ezlogs ">>>> Attempting to unlock secret store $Name" -warning -logtype Spotify
        Unlock-SecretStore -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
        $ClientId = Get-secret -name SpotyClientId  -Vault $Name -ErrorAction Continue
        $ClientSecret = Get-secret -name SpotyClientSecret  -Vault $Name -ErrorAction Continue
        $RedirectUri = Get-secret -name SpotyRedirectUri -Vault $Name  -ErrorAction Continue
      }catch{
        write-ezlogs "An exception occurred unlocking secretstore $($Name)" -catcherror $_
      }
    }
    if([string]::IsNullOrEmpty($ClientId) -or [string]::IsNullOrEmpty($ClientSecret) -or [string]::IsNullOrEmpty($RedirectUri)){
      try{
        $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\Spotify-API-Config.xml"
        write-ezlogs "[Get-SpotifyApplication] >>>> Importing API Config file $APIXML" -showtime -logtype Spotify
        if([System.IO.File]::Exists($APIXML)){
          $Spotify_API = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($APIXML))
          $clientID = $Spotify_API.ClientID
          $clientsecret = $Spotify_API.ClientSecret
          $redirecturi = $Spotify_API.Redirect_URLs
        }
        Set-Secret -Name SpotyClientId -Secret $ClientId -Vault $Name
        Set-Secret -Name SpotyClientSecret -Secret $ClientSecret -Vault $Name
        Set-Secret -Name SpotyRedirectUri -Secret $RedirectUri -Vault $Name
      }catch{
        write-ezlogs "An exception occurred getting clientid or clientsecret from API Config file: $APIXML" -catcherror $_
      }
    }   
    try{
      $access_token = Get-secret -name Spotyaccess_token -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting Secret Spotyaccess_token" -showtime -catcherror $_
    }finally{
      if([string]::IsNullOrEmpty($access_token)){
        write-ezlogs "[Get-SpotifyApplication] Unable to get Spotyaccess_token from vault $Name - trying again in case of transient issue" -showtime -warning -logtype Spotify
        start-sleep -Milliseconds 100
        try{
          write-ezlogs "Attempting to access Spotyaccess_token from secret vault again in case of transient issue" -showtime -warning -logtype Spotify
          $access_token = Get-secret -name Spotyaccess_token  -Vault $Name -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occurred getting Secret Spotyaccess_token" -showtime -catcherror $_
        } 
      }
    }    
    if($access_token){
      try{
        $expires = Get-secret -name Spotyexpires  -Vault $Name -ErrorAction Continue
        $scope = Get-secret -name Spotyscope  -Vault $Name -ErrorAction Continue   
        $refresh_token = Get-secret -name Spotyrefresh_token  -Vault $Name -ErrorAction Continue
        $token_type = Get-secret -name Spotytoken_type  -Vault $Name -ErrorAction Continue
        $Token = New-Object PsObject -Property @{
          'expires' = $expires
          'scope' = $scope
          'refresh_token' = $refresh_token
          'token_type' = $token_type
          'access_token' = $access_token
        }             
      }catch{
        write-ezlogs "An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
      }        
    }else{
      try{
        write-ezlogs "Unable to find Spotify Access Token from Secret Vault $name - Clientid $ClientId!" -showtime -warning -logtype Spotify
        $Secret_store_config = Get-SecretStoreConfiguration -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "An exception occurred getting secretstore configuration with Get-SecretStoreConfiguration" -showtime -catcherror $_
      } 
      try{
        write-ezlogs "Secret_store_config: $($Secret_store_config | out-string)" -logtype Spotify -loglevel 2
        $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\Spotify-API-Config.xml"
        write-ezlogs "Importing API XML $APIXML" -showtime -logtype Spotify -loglevel 2
        if([System.IO.File]::Exists($APIXML) -and ([string]::IsNullOrEmpty($ClientId) -or [string]::IsNullOrEmpty($ClientSecret) -or [string]::IsNullOrEmpty($RedirectUri))){
          $Spotify_API = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($APIXML))
          $clientID = $Spotify_API.ClientID
          $clientsecret = $Spotify_API.ClientSecret
          $redirecturi = $Spotify_API.Redirect_URLs
        }

      }catch{
        write-ezlogs "An exception occurred importing $APIXML" -showtime -catcherror $_
      }

    } 
    $Auth = New-Object PsObject -Property @{
      'RedirectUri' = $RedirectUri
      'Name' = $Name
      'ClientId' = $ClientId
      'ClientSecret' = $ClientSecret
      'Token' = $Token
    }    
    return $auth                
  }else{
    Write-ezlogs "No SecretStore found called $Name" -warning -showtime -logtype Spotify
    #write-ezlogs "Unable to find Spotify Access Token from Secret Vault $name - Clientid $ClientId!" -showtime -warning -logtype Spotify
    #$Secret_store_config = Get-SecretStoreConfiguration 
    #write-ezlogs "Secret_store_config: $($Secret_store_config | out-string)" -logtype Spotify -loglevel 2
    if($thisApp.Config.Current_Folder){
      $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\Spotify-API-Config.xml"
    }else{
      $APIXML = "$([System.IO.Directory]::GetParent($PSScriptRoot))\Resources\API\Spotify-API-Config.xml"
    }    
    if([System.IO.File]::Exists($APIXML)){
      write-ezlogs "[Get-SpotifyApplication] >>>> Importing API XML $APIXML" -showtime -logtype Spotify
      $Spotify_API = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($APIXML))
      $clientID = $Spotify_API.ClientID
      $clientsecret = $Spotify_API.ClientSecret
      $redirecturi = $Spotify_API.Redirect_URLs
    }
    if($clientID -and $clientsecret -and $redirecturi){
      New-SpotifyApplication -ClientId $clientID -ClientSecret $clientsecret -Name $thisApp.config.App_Name -RedirectUri $redirecturi
      $Auth = New-Object PsObject -Property @{
        'RedirectUri' = $RedirectUri
        'Name' = $Name
        'ClientId' = $ClientId
        'ClientSecret' = $ClientSecret
        'Token' = $Token
      }       
      return $auth
    }else{
      write-ezlogs "Unable to get Spotify API info from $APIXML -- cannot contineu" -showtime -Warning -logtype Spotify
      return
    }
  }     
    
}