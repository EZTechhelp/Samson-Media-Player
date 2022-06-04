<#
    .SYNOPSIS
    Modifies an aplication credentials
    .DESCRIPTION
    Allows to modify clientId and ClientSecret of an existing Spotify application credentials
    .EXAMPLE
    PS C:\> Set-SpotifyApplication -ClientId 'ClientIdOfSpotifyApplication' -ClientSecret 'ClientSecretOfSpotifyApplication'
    Change the content of the default application credentials json in the store (named default.json) using new ClientId and ClientSecret provided.
    .EXAMPLE
    PS C:\> Set-SpotifyApplication -Name 'dev' -ClientId 'ClientIdOfSpotifyApplication' -ClientSecret 'ClientSecretOfSpotifyApplication'
    Change the content of the application credentials json named dev.json using new ClientId and ClientSecret provided.
    .PARAMETER Name
    Specifies the name of the application credentials you want to modify ('default' if not specified).
    .PARAMETER ClientId
    Specifies the new Client ID of the Spotify Application
    .PARAMETER ClientSecret
    Specifies the new Client Secret of the Spotify Application
    .PARAMETER RedirectUri
    Specifies the new redirect Uri of the Spotify Application
    .PARAMETER Token
    Specifies the new Token retrieved from the Spotify Application
#>
function Set-SpotifyApplication {

  param(
    [string]
    $Name = 'default',

    [Parameter(Mandatory, ParameterSetName = "ClientIdAndSecret")]
    [String]
    $ClientId,

    [Parameter(Mandatory, ParameterSetName = "ClientIdAndSecret")]
    [String]
    $ClientSecret,

    [Parameter(ParameterSetName = "ClientIdAndSecret")]
    [String]
    $RedirectUri,

    [Parameter(Mandatory, ParameterSetName = "Token")]
    $Token
  )

  #$StorePath = Get-StorePath

  $Application = Get-SpotifyApplication -Name $Name

  # Construct filepath
  #$ApplicationFilePath = $StorePath + $Application.Name + ".json"
  
  # Try to save application to file.
  try {
    # Update Application
    if($Application.Name){
      $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
      if($secretstore){
        $secretstore = $secretstore.name  
        if ($ClientId) { 
          #$Application.ClientId = $ClientId 
          Set-Secret -Name SpotyClientId -Secret $ClientId -Vault $secretstore
  
        }
        if ($ClientSecret) {   
          #$Application.ClientSecret = $ClientSecret 
          Set-Secret -Name SpotyClientSecret -Secret $ClientSecret -Vault $secretstore
        }
        if ($RedirectUri) { 
          Set-Secret -Name SpotyRedirectUri -Secret $RedirectUri -Vault $secretstore
          #$Application.RedirectUri = $RedirectUri
        }
        if ($Token.expires) {
          Set-Secret -Name Spotyexpires -Secret $Token.expires -Vault $secretstore
        }
        if ($Token.access_token) {
          Set-Secret -Name Spotyaccess_token -Secret $Token.access_token -Vault $secretstore
        }
        if ($Token.scope) {
          Set-Secret -Name Spotyscope -Secret $Token.scope -Vault $secretstore
        }
        if ($Token.refresh_token) {
          Set-Secret -Name Spotyrefresh_token -Secret $Token.refresh_token -Vault $secretstore
        }        
        if ($Token.token_type) {
          Set-Secret -Name Spotytoken_type -Secret $Token.token_type -Vault $secretstore
        }                                   
      }
      if ($PSCmdlet.ParameterSetName -eq 'ClientIdAndSecret') {
        Write-ezlogs "Don't forget to setup a Redirect URIs on your Spotify Application : $Script:REDIRECT_URI" -showtime -warning
      }
    }else{
      Write-ezlogs "Unable to find existing Spotify Application $name - Use New-SpotifyApplication to create a new one" -showtime -warning
    }
  }
  catch {
    write-ezlogs "Failed updating SecretStore $Name : $($PSItem[0].ToString())" -showtime -catcherror $_
  }
}