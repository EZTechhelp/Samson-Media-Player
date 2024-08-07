<#
    .Name
    New-YoutubePlaylist

    .Version 
    0.1.0

    .SYNOPSIS
    Adds a new playlist to the authenticated Youtube account via Youtube API.

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region New-YoutubePlaylist Function
#----------------------------------------------
function New-YoutubePlaylist {
  <#
      .SYNOPSIS
      Adds a new playlist to the authenticated Youtube account via Youtube API.

      .EXAMPLE
      New-YoutubePlaylist -synchash $synchash -thisapp $thisApp
  #>
  [CmdletBinding()]
  Param (
    $thisApp,
    $synchash,
    $PlaylistName,
    [string]$PlaylistDescription,
    [ValidateSet('public','unlisted','private')]
    [string]$PrivacyStatus,
    [switch]$Use_runspace,
    [switch]$Verboselog
  )
  try{
    $New_YoutubePlaylist_Scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $PlaylistName = $PlaylistName,
        [switch]$Use_runspace = $Use_runspace,
        [string]$PlaylistDescription = $PlaylistDescription,
        [string]$PrivacyStatus = $PrivacyStatus,
        [switch]$Verboselog = $Verboselog
      )
      try{
        if([string]::IsNullOrEmpty($PlaylistName) -or [string]::IsNullOrEmpty($PrivacyStatus)){
          write-ezlogs "[New-YoutubePlaylist] A valid Playlist Name and PrivacyStatus was not provided, cannot continue!" -warning -logtype Youtube
          return
        }
        $Playlistparts = 'contentDetails,id,localizations,player,snippet,status'
        $Uri = "https://www.googleapis.com/youtube/v3/playlists?part=$Playlistparts"
        try{
          $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name) 
        }catch{
          write-ezlogs "[New-YoutubePlaylist] An exception occurred executing Get-AccessToken" -showtime -catcherror $_
        }
        if($access_Token.Authorization){  
          $Headers = ($access_Token) + @{
            'Content-Type' = 'application/json'
          }
          $Body = @{
            snippet = @{
              title = $PlaylistName
              description = $PlaylistDescription
              defaultLanguage = 'en'
            }
            status = @{
              privacyStatus = $PrivacyStatus
            }
          } | ConvertTo-Json
          $NewPlaylist_Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Body $Body -Method Post
          if($NewPlaylist_Response.id){
            write-ezlogs "[New-YoutubePlaylist] Successfully created new playlist with id $($NewPlaylist_Response.id)" -Success -logtype Youtube
            return $NewPlaylist_Response
          }else{
            write-ezlogs "[New-YoutubePlaylist] New Youtube playlist was not created successfully!" -warning -logtype Youtube
            return
          }          
        }else{
          write-ezlogs "[New-YoutubePlaylist] Unable to retrieve proper youtube authentication!" -showtime -warning -logtype Youtube
        }
      }catch{
        write-ezlogs "[New-YoutubePlaylist] An exception occurred in New_YoutubePlaylist_Scriptblock" -showtime -catcherror $_
      }     
    }
    if($Use_runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $New_YoutubePlaylist_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'New_YoutubePlaylist_RUNSPACE' -thisApp $thisApp -synchash $synchash
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $New_YoutubePlaylist_Scriptblock
    }
  }catch{
    write-ezlogs "An exception occurred in New-YoutubePlaylist" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion New-YoutubePlaylist Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-YoutubePlaylistItem Function
#----------------------------------------------
function Add-YoutubePlaylistItem {
  <#
      .SYNOPSIS
      Adds a videos to existing playlist of the authenticated Youtube account via Youtube API.

      .EXAMPLE
      Add-YoutubePlaylistItem -synchash $synchash -thisapp $thisApp
  #>
  [CmdletBinding()]
  Param (
    $thisApp,
    $synchash,
    $PlaylistID,
    [string]$VideoID,
    [switch]$Use_runspace,
    [switch]$Verboselog
  )
  try{
    $Add_YoutubePlaylistItem_Scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $PlaylistID = $PlaylistID,
        [switch]$Use_runspace = $Use_runspace,
        [string]$VideoID = $VideoID,
        [switch]$Verboselog = $Verboselog
      )
      try{
        if([string]::IsNullOrEmpty($PlaylistID) -or [string]::IsNullOrEmpty($VideoID)){
          write-ezlogs "[Add-YoutubePlaylistItem] A valid PlaylistID or VideoID was not provided, cannot continue!" -warning -logtype Youtube
          return
        }
        $Playlistparts = 'contentDetails,id,snippet,status'
        $Uri = "https://www.googleapis.com/youtube/v3/playlistItems?part=$Playlistparts"
        try{
          $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name) 
        }catch{
          write-ezlogs "[Add-YoutubePlaylistItem] An exception occurred executing Get-AccessToken" -showtime -catcherror $_
        }
        if($access_Token.Authorization){  
          $Headers = ($access_Token) + @{
            'Content-Type' = 'application/json'
          }
          $Body = @{
            snippet = @{
              playlistId = $PlaylistID
              position = '0'
              resourceId = @{
                kind =  "youtube#video"
                videoId = $VideoID
              }
            }
          } | ConvertTo-Json
          $AddtoPlaylist_Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Body $Body -Method Post
          if($AddtoPlaylist_Response.contentDetails.videoId){
            write-ezlogs "[Add-YoutubePlaylistItem] Successfully added new video with id: $($AddtoPlaylist_Response.contentDetails.videoId) to playlist with id - $PlaylistID" -Success -logtype Youtube
            return $AddtoPlaylist_Response
          }else{
            write-ezlogs "[Add-YoutubePlaylistItem] New Youtube playlist was not created successfully!" -warning -logtype Youtube
            return
          }          
        }else{
          write-ezlogs "[Add-YoutubePlaylistItem] Unable to retrieve proper youtube authentication!" -showtime -warning -logtype Youtube
        }
      }catch{
        write-ezlogs "[Add-YoutubePlaylistItem] An exception occurred in Add_YoutubePlaylistItem_Scriptblock" -showtime -catcherror $_
      }     
    }
    if($Use_runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $Add_YoutubePlaylistItem_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Add_YoutubePlaylistItem_RUNSPACE' -thisApp $thisApp -synchash $synchash
      Remove-Variable Variable_list
    }else{
      Invoke-Command -ScriptBlock $Add_YoutubePlaylistItem_Scriptblock
    }
  }catch{
    write-ezlogs "An exception occurred in Add-YoutubePlaylistItem" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Add-YoutubePlaylistItem Function
#----------------------------------------------
Export-ModuleMember -Function @('New-YoutubePlaylist','Add-YoutubePlaylistItem')