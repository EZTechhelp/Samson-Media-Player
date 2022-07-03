<#
    .SYNOPSIS
    Get a list of the playlists owned or followed by the current Spotify user.
    .EXAMPLE
    PS C:\> Get-CurrentUserPlaylists
    Grabs data of all current user's playlists
    .PARAMETER ApplicationName
    Specifies the Spotify Application Name (otherwise default is used)
#>
function Get-CurrentUserPlaylists {
  param(
    [string]
    $ApplicationName,
    $thisScript,
    [switch]$First_Run      
  )

  $Method = 'Get'
  $Uri = 'https://api.spotify.com/v1/me/playlists?limit=50'

  # build a fake Response to start the machine
  $Response = @{next = $Uri }

  While ($Response.next) {
    if($thisApp){
      $Response = Send-SpotifyCall -Method $Method -Uri $Response.next -ApplicationName $ApplicationName -thisScript $thisScript -First_Run $First_Run
    }else{
      $Response = Send-SpotifyCall -Method $Method -Uri $Response.next -ApplicationName $ApplicationName
    }    
    $Response.items # this return items that will be aggregated with items of other loops
  }
}