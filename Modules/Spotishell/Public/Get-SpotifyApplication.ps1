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
    $All
  )

  if (!$Name) { $Name = 'EZT-MediaPlayer' }
  try{
    #write-ezlogs "Getting secretvault $Name " -showtime
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "An exception occurred getting SecretStore $name" -showtime -catcherror $_
  }
  if($secretstore){
    $secretstore = $secretstore.name  
    try{
      $RedirectUri = Get-secret -name SpotyRedirectUri -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting Secret SpotyRedirectUri" -showtime -catcherror $_
    }
    try{
      $ClientId = Get-secret -name SpotyClientId -AsPlainText -Vault $secretstore -ErrorAction Continue
    }catch{
      write-ezlogs "An exception occurred getting Secret SpotyClientId" -showtime -catcherror $_
    }   
    try{
      $ClientSecret = Get-secret -name SpotyClientSecret -AsPlainText -Vault $secretstore -ErrorAction Continue
    }catch{
      write-ezlogs "An exception occurred getting Secret SpotyClientSecret" -showtime -catcherror $_
    }    
    try{
      $access_token = Get-secret -name Spotyaccess_token -AsPlainText -Vault $secretstore -ErrorAction Continue
    }catch{
      write-ezlogs "An exception occurred getting Secret Spotyaccess_token" -showtime -catcherror $_
    }    
    
    if($access_token){
      try{
        $expires = Get-secret -name Spotyexpires -AsPlainText -Vault $secretstore -ErrorAction Continue
        $scope = Get-secret -name Spotyscope -AsPlainText -Vault $secretstore -ErrorAction Continue   
        $refresh_token = Get-secret -name Spotyrefresh_token -AsPlainText -Vault $secretstore -ErrorAction Continue
        $token_type = Get-secret -name Spotytoken_type -AsPlainText -Vault $secretstore -ErrorAction Continue
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
      write-ezlogs "Unable to find Spotify Access Token from Secret Vault $name - Clientid $ClientId!" -showtime -warning
      $Secrets = Get-secretinfo -Name $Name
      write-ezlogs "Secrets for $name`: $($Secrets | out-string)"
      $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
      write-ezlogs "Importing API XML $APIXML" -showtime
      if([System.IO.File]::Exists($APIXML)){
        $Spotify_API = Import-Clixml $APIXML
        $clientID = $Spotify_API.ClientID
        $clientsecret = $Spotify_API.ClientSecret
        $redirecturi = $Spotify_API.Redirect_URLs
      }
    } 
    $Auth = New-Object PsObject -Property @{
      'RedirectUri' = $RedirectUri
      'Name' = $Name
      'ClientId' = $ClientId
      'ClientSecret' = $ClientSecret
      'Token' = $Token
    }  
    if($synchash){
      $synchash.Spotify_Current_Auth = $auth  
    }
      
    return $auth                
  }else{
    Write-ezlogs "No SecretStore found called $Name, you need to create a Spotify Application first" -warning -showtime
    return
  }      

  
  # Otherwise find and return the named application
  #$ApplicationFilePath = $StorePath + $Name + ".json"
  <#  if (!(Test-Path -Path $ApplicationFilePath -PathType Leaf)) {
      #write-error 'The specified Application doesn''t exist'
      return
  }#>

  #if($thisApp.Config.Verbose_logging){Write-ezlogs " | Read Spotify Application : $Name" -showtime}
    
  #Return Get-Content -Path $ApplicationFilePath -Raw | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Hashtable
}