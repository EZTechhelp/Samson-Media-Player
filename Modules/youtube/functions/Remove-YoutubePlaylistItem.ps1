<#
    .Name
    Remove-YoutubePlaylistItem

    .Version 
    0.1.0

    .SYNOPSIS
    Removes playlist items from authenticated Youtube account via Youtube API.

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
#region Remove-YoutubePlaylistItem Function
#----------------------------------------------
function Remove-YoutubePlaylistItem {
  <#
      .SYNOPSIS
      Removes playlist items from authenticated Youtube account via Youtube API.

      .EXAMPLE
      Remove-YoutubePlaylistItem -synchash $synchash -thisapp $thisApp
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
    $Remove_YoutubePlaylistItem_Scriptblock = {
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
          write-ezlogs "[Remove-YoutubePlaylistItem] A valid PlaylistID or VideoID was not provided, cannot continue!" -warning -logtype Youtube
          return
        }
        #$Uri = "https://www.googleapis.com/youtube/v3/playlistItems?part=$Playlistparts"
        $uri = "https://youtube.googleapis.com/youtube/v3/playlistItems?id=$VideoID"
        try{
          $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name) 
        }catch{
          write-ezlogs "[Remove-YoutubePlaylistItem] An exception occurred executing Get-AccessToken" -showtime -catcherror $_
        }
        if($access_Token.Authorization){  
          $Headers = ($access_Token) + @{
            'Content-Type' = 'application/json'
          }
          try{
            $RemovefromPlaylist_Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Delete -UseBasicParsing
          }catch{
            $Failed = $true
            write-ezlogs "An exception occurred deleting youtube video via delete request uri: $Uri" -catcherror $_            
          }
          if($Failed){
            write-ezlogs "[Remove-YoutubePlaylistItem] Youtube video was not successfully removed from playlist with id: $PlaylistID" -warning -logtype Youtube
            return
          }else{
            write-ezlogs "[Remove-YoutubePlaylistItem] Successfully removed video with id: $($VideoID) from playlist with id - $PlaylistID" -Success -logtype Youtube
            return $true
          }                   
        }else{
          write-ezlogs "[Remove-YoutubePlaylistItem] Unable to retrieve proper youtube authentication!" -showtime -warning -logtype Youtube
        }
      }catch{
        write-ezlogs "[Remove-YoutubePlaylistItem] An exception occurred in Remove_YoutubePlaylistItem_Scriptblock" -showtime -catcherror $_
      }     
    }
    if($Use_runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $Remove_YoutubePlaylistItem_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Remove_YoutubePlaylistItem_RUNSPACE' -thisApp $thisApp -synchash $synchash
      Remove-Variable Variable_list
    }else{
      Invoke-Command -ScriptBlock $Remove_YoutubePlaylistItem_Scriptblock
    }
  }catch{
    write-ezlogs "An exception occurred in Remove-YoutubePlaylistItem" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Remove-YoutubePlaylistItem Function
#----------------------------------------------