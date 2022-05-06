<#
    .Name
    Add-Playlist

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and adds tracks to playlists

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
#region Add-Playlist Function
#----------------------------------------------
function Add-Playlist
{
  Param (
    $Media,
    $Playlist,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog
  )
  Add-Type -AssemblyName System.Web
  if($Verboselog){write-ezlogs "#### Adding/Updating Playlist $Playlist ####" -enablelogs -color yellow -linesbefore 1}
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]" 
  $Playlist_Path_Name = "$($Playlist)-CustomPlaylist.xml"    
  $Playlist_Directory_Path = [System.IO.Path]::Combine($Playlist_Profile_Directory,'Custom-Playlists')
  $Playlist_File_Path = [System.IO.Path]::Combine($Playlist_Directory_Path,$Playlist_Path_Name)
  if(![System.IO.File]::Exists($Playlist_Directory_Path)){
    $Null = New-Item -Path $Playlist_Directory_Path -ItemType directory -Force
  }  
 
  if([System.IO.File]::Exists($Playlist_File_Path)){ 
    if($Verboselog){write-ezlogs " | Importing Playlist Profile: $Playlist_File_Path" -showtime -enablelogs}
    $Playlist_to_Update = Import-CliXml -Path $Playlist_File_Path   
  }else{
    if($Verboselog){write-ezlogs " | Playlist Profile to import not found at $Playlist_File_Path....Attempting to build new profile" -showtime -enablelogs -color cyan}
    $Playlist_to_Update = Import-Clixml "$($thisApp.Config.Current_Folder)\\Resources\\Templates\\Playlists_Template.xml"
    $Playlist_encodedTitle = $Null  
    $Playlist_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Playlist)-CustomPlaylist")
    $Playlist_encodedTitle = [System.Convert]::ToBase64String($Playlist_encodedBytes)  
    $Playlist_to_Update.Playlist_ID = $Playlist_encodedTitle
    $Playlist_to_Update.name = $Playlist  
    $Playlist_to_Update.Playlist_Date_Added = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
    $Playlist_to_Update.type = 'CustomPlaylist'
    $Playlist_to_Update.Playlist_Path = $Playlist_File_Path
  }  
  if(-not [string]::IsNullOrEmpty($Playlist_to_Update.Playlist_ID) -and $Playlist){
    foreach($item in $media){
      if($Playlist_to_Update.PlayList_tracks.id -notcontains $item.id){
        if($Verboselog){write-ezlogs " | Adding $($item.title) to playlist $($Playlist)" -showtime}
        #Add-Member -InputObject $item -Name 'Playlist_File_Path' -Value $Playlist_File_Path -MemberType NoteProperty -Force
        $null = $Playlist_to_Update.PlayList_tracks.add($item)
      }else{
        write-ezlogs " | $($item.title) has already been added to profile $($Playlist)" -showtime
      }
    }
    write-ezlogs ">>>> Exporting updated playlist profile to $Playlist_File_Path" -showtime -color cyan
    $Playlist_to_Update | Export-Clixml -Path $Playlist_File_Path -Force -Encoding UTF8
  }else{
    write-ezlogs "Could not find Playlist to update or no playlist to update was provided" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Add-Playlist Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-Playlist')

