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
    $Name = 'default',

    [switch]
    $All
  )

  if (!$Name) { $Name = 'default' }

  #$StorePath = Get-StorePath
  #$StorePath = $env:LOCALAPPDATA + '\spotishell\'

  <#  if (!(Test-Path -Path $StorePath)) {
      Write-ezlogs "No store folder at $StorePath, you need to create a Spotify Application first" -warning
      }
      else {
      if($thisApp.Config.Verbose_logging){Write-ezlogs ">>>> Spotify Application store exists at $StorePath" -showtime -color cyan}
  }#>

  # if All switch is specified return all applications
  <#  if ($All) {
      Write-ezlogs ' | Read All Spotify Application' -showtime
      return Get-Content -Path ($StorePath + '*') -Filter '*.json' -Raw | ConvertFrom-Json | ConvertTo-Hashtable
  }#>
  
  try{
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
    if($secretstore){
      $secretstore = $secretstore.name  
      $RedirectUri = Get-secret -name SpotyRedirectUri -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
      $ClientId = Get-secret -name SpotyClientId -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
      $ClientSecret = Get-secret -name SpotyClientSecret -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
      $access_token = Get-secret -name Spotyaccess_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
      if($access_token){
        $expires = Get-secret -name Spotyexpires -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
        $scope = Get-secret -name Spotyscope -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue   
        $refresh_token = Get-secret -name Spotyrefresh_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
        $token_type = Get-secret -name Spotytoken_type -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue           
      }
      $Token = New-Object PsObject -Property @{
        'expires' = $expires
        'scope' = $scope
        'refresh_token' = $refresh_token
        'token_type' = $token_type
        'access_token' = $access_token
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
      Write-ezlogs "No SecretStore found called $Name, you need to create a Spotify Application first" -warning -showtime
      return
    }      
  }catch{
    write-ezlogs "An exception occurred getting SecretStore $name" -showtime -catcherror $_
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