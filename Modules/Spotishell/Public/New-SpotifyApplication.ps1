<#
    .SYNOPSIS
    Creates a new application
    .DESCRIPTION
    Creates a new application and saves it locally (file) so you may re-use it without setting it every time
    .EXAMPLE
    PS C:\> New-SpotifyApplication -ClientId 'ClientIdOfSpotifyApplication' -ClientSecret 'ClientSecretOfSpotifyApplication'
    Creates the default application json in the store, named default.json and containing default as Name, ClientId and ClientSecret.
    .EXAMPLE
    PS C:\> New-SpotifyApplication -Name 'dev' -ClientId 'ClientIdOfSpotifyApplication' -ClientSecret 'ClientSecretOfSpotifyApplication'
    Creates a new application json in the store, named dev.json and containing Name, ClientId and ClientSecret.
    .PARAMETER Name
    Specifies the name of the application you want to save ('default' if not specified).
    .PARAMETER ClientId
    Specifies the Client ID of the Spotify Application
    .PARAMETER ClientSecret
    Specifies the Client Secret of the Spotify Application
    .PARAMETER RedirectUri
    Specifies the Redirect Uri of the Spotify Application
#>
function New-SpotifyApplication {

  param (
    [String]
    $Name = 'default',

    [Parameter(Mandatory)]
    [String]
    $ClientId,

    [Parameter(Mandatory)]
    [String]
    $ClientSecret,

    [String]
    $RedirectUri = 'http://localhost:8080/spotishell'
  )

  if($RedirectUri -and $Name -and $ClientId -and $ClientSecret){
    # Assemble Application        
    $Application =  @{
      Name         = $Name
      ClientId     = $ClientId
      ClientSecret = $ClientSecret
      RedirectUri  = $RedirectUri
    }
    # Try to save application to file.
    try {
      write-ezlogs "[New-SpotifyApplication] >>>> Attempting to save application to SecretStore $Name" -showtime -logtype Spotify -LogLevel 2
      try{
        Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($Name | ConvertTo-SecureString -AsPlainText -Force)
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
        if(!$secretstore){
          write-ezlogs ">>>> Registrying new Secret Vault: $Name" -showtime -logtype Spotify -LogLevel 2
          $secretstore = Register-SecretVault -Name $Name -ModuleName "$($thisApp.Config.Current_Folder)\Modules\Microsoft.PowerShell.SecretStore" -DefaultVault -Description "Created by $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -PassThru
        }  
        write-ezlogs "| Saving SpotyClientId to vault" -showtime -logtype Spotify -LogLevel 2
        Set-Secret -Name SpotyClientId -Secret $ClientId -Vault $Name
        write-ezlogs "| Saving SpotyClientSecret to vault" -showtime -logtype Spotify -LogLevel 2
        Set-Secret -Name SpotyClientSecret -Secret $ClientSecret -Vault $Name
        write-ezlogs "| Saving SpotyRedirectUri to vault" -showtime -logtype Spotify -LogLevel 2
        Set-Secret -Name SpotyRedirectUri -Secret $RedirectUri -Vault $Name
      }catch{
        write-ezlogs "An exception occurred when setting or configuring the secret store $Name" -CatchError $_         
      }    
      return $Application
    }
    catch {
      write-ezlogs "Failed creating SecretStore $Name : $($PSItem[0].ToString())" -showtime -catcherror $_
    }
  }else{
    write-ezlogs "Cannot create new Spotify Application, must provide values for RedirectUri, Name, ClientId and ClientSecret parameters" -showtime -warning -logtype Spotify
  }
}