<#
    .SYNOPSIS
    Removes saved spotify credential
    .DESCRIPTION
    Removes saved spotify credential on local machine if there is one.
    .EXAMPLE
    PS C:\> Remove-SpotifyApplication
    Remove a saved spotify application file of the name 'default'
    .EXAMPLE
    PS C:\> Remove-SpotifyApplication -Name 'dev'
    Remove a saved spotify application file of the name 'dev'
    .PARAMETER Name
    Specifies the name of the spotify application you want to remove
#>
function Remove-SpotifyApplication {
  param (
    [String]
    $Name = $thisapp.Config.Current_Folder
  )
  try{
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "An exception occurred getting SecretStore $($Name)" -showtime -catcherror $_
  }
  write-ezlogs "Removing stored Spotify authentication secrets from vault: $Name" -showtime -warning
  if($secretstore){
    try{
      $null = Remove-secret -name SpotyRedirectUri -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred removing Secret SpotyRedirectUri" -showtime -catcherror $_
    }
    try{
      $null = Remove-secret -name SpotyClientId -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred removing Secret SpotyClientId" -showtime -catcherror $_
    }   
    try{
      $null = Remove-secret -name SpotyClientSecret -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred removing Secret SpotyClientSecret" -showtime -catcherror $_
    }    
    try{
      $null = Remove-secret -name Spotyaccess_token -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred removing Secret Spotyaccess_token" -showtime -catcherror $_
    }                 
  }
}