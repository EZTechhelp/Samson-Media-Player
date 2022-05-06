<#
    .SYNOPSIS
    Get information about a user's available devices.
    .EXAMPLE
    PS C:\> Get-AvailableDevices
    Retrieves list of available devices
    .PARAMETER ApplicationName
    Specifies the Spotify Application Name (otherwise default is used)
#>
function Get-AvailableDevices {
  param(
    [string]
    $ApplicationName,
    $thisApp,
    $thisScript         
  )

  $Method = 'Get'
  $Uri = 'https://api.spotify.com/v1/me/player/devices'
  if($thisApp){
    $Response = Send-SpotifyCall -Method $Method -Uri $Uri -ApplicationName $ApplicationName -thisApp $thisApp -thisScript $thisScript
  }else{
    $Response = Send-SpotifyCall -Method $Method -Uri $Uri -ApplicationName $ApplicationName
  }
  
  $Response.devices
}