<#
    .SYNOPSIS
        Get public profile information about a Spotify user.
    .EXAMPLE
        PS C:\> Get-SpotifyUserProfile 'myusername'
        Gets the public user profile information about myusername
    .PARAMETER UserId
        Specifies the spotify user we want to search for
    .PARAMETER ApplicationName
        Specifies the Spotify Application Name (otherwise default is used)
#>
function Get-SpotifyUserProfile {
    param (
        [String]
        $UserId,

        [string]
        $ApplicationName
    )
    
    $Method = 'Get'
    $Uri = 'https://api.spotify.com/v1/users/' + $UserId

    Send-SpotifyCall -Method $Method -Uri $Uri -ApplicationName $ApplicationName
}