<#
    .Name
    Get-YouTubePlaylists

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves list of Youtube playlists. Adapted from Module Youtube  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-YouTubePlaylists Function
#----------------------------------------------
function Get-YouTubePlaylists {
  <#
      .SYNOPSIS
      Retrieves list of Youtube playlists.

      .EXAMPLE
      Get-YouTubePlaylists

      .EXAMPLE
      Get-YouTubePlaylists
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'Mine')]
    [switch] $mine,
    [Parameter(ParameterSetName = 'Id')]
    [string] $id
  )
  $results_output = New-Object -TypeName 'System.Collections.ArrayList'
  if($PSCmdlet.ParameterSetName -eq 'Mine'){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
  }elseif($PSCmdlet.ParameterSetName -eq 'id'){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&channelId={1}' -f $Parts,$id
  }
  $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  if($refresh_access_token){
    $access_token_expires = Get-secret -name Youtubeexpires_in -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  }
  if($access_token_expires -le (Get-date) -or !$access_token){
    write-ezlogs "Token has expired, attempting to refresh" -showtime -warning
    try{
      Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript 
      $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
    }
  }
  $Header =  @{
    Authorization = 'Bearer {0}' -f $access_token
  }
  if($access_Token){    
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){       
        $result = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Header
        if($result.nextPageToken){
          $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true&pageToken={1}' -f $Parts,$result.nextPageToken
        }else{
          $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
        }
        if($result.items){
          foreach($item in $result.items){
            if($results_output -notcontains $item){
<#              if($playlistlookup.items -and (!$item.Playlist_info)){
                Add-Member -InputObject $item -Name 'Playlist_info' -Value $playlistlookup.items -MemberType NoteProperty -Force
              }#>           
              $null = $results_output.add($item)
            }
          } 
          #$result # this return items that will be aggregated with items of other loops
        }
      }
    }catch{
      write-ezlogs "An exception occurred invoking url $Uri" -showtime -catcherror $_
    }
    if(!$Result){
      write-ezlogs "Unable to results, starting Youtube authorization capture process" -showtime -warning
    }             
    return $results_output 
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Get-YouTubePlaylists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-YouTubePlaylists')