<#
    .Name
    Add-EQPreset

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and adds EQ Presets

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
#region Add-EQPreset Function
#----------------------------------------------
function Add-EQPreset
{
  Param (
    [string]$PresetName,
    $EQ_Bands,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [string]$EQPreset_Profile_Directory = $thisApp.config.EQPreset_Profile_Directory,
    [switch]$Verboselog
  )
  Add-Type -AssemblyName System.Web
  if($Verboselog){write-ezlogs "#### Adding/Updating EQ Preset $PresetName ####" -enablelogs -color yellow -linesbefore 1}
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]" 
  $Preset_Path_Name = "$($PresetName)-Custom-EQPreset.xml"    
  $Preset_Directory_Path = [System.IO.Path]::Combine($EQPreset_Profile_Directory,'Custom-EQPresets')
  $Preset_File_Path = [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)
  if(![System.IO.File]::Exists($Preset_Directory_Path)){
    $Null = New-Item -Path $Preset_Directory_Path -ItemType directory -Force
  }  
 
  if([System.IO.File]::Exists($Preset_File_Path)){ 
    if($Verboselog){write-ezlogs " | Importing EQ Preset Profile: $Preset_File_Path" -showtime -enablelogs}
    $Preset_to_Update = Import-CliXml -Path $Preset_File_Path   
  }else{
    if($Verboselog){write-ezlogs " | Preset Profile to import not found at $Preset_File_Path....Attempting to build new profile" -showtime -enablelogs -color cyan}
    $Preset_to_Update = Import-Clixml "$($thisApp.Config.Current_Folder)\\Resources\\Templates\\EQPreset_Template.xml"
    $Preset_encodedTitle = $Null  
    $Preset_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($PresetName)-CustomEQPreset")
    $Preset_encodedTitle = [System.Convert]::ToBase64String($Preset_encodedBytes)  
    $Preset_to_Update.Preset_ID = $Preset_encodedTitle
    $Preset_to_Update.Preset_Name = $PresetName  
    $Preset_to_Update.Preset_Date_Added = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
    $Preset_to_Update.type = 'CustomEQPreset'
    $Preset_to_Update.Preset_Path = $Preset_File_Path
  }  
  if(-not [string]::IsNullOrEmpty($Preset_to_Update.Preset_ID) -and $PresetName -and $EQ_Bands){
    $Preset_to_Update.EQ_Bands = $EQ_Bands
    <#    foreach($item in $media){
        if($Preset_to_Update.PlayList_tracks.id -notcontains $item.id){
        if($Verboselog){write-ezlogs " | Adding $($item.title) to Preset $($PresetName)" -showtime}
        #Add-Member -InputObject $item -Name 'Playlist_File_Path' -Value $Playlist_File_Path -MemberType NoteProperty -Force
        $null = $Preset_to_Update.PlayList_tracks.add($item)
        }else{
        write-ezlogs " | $($item.title) has already been added to profile $($PresetName)" -showtime
        }
    }#>
    write-ezlogs ">>>> Exporting updated Preset profile to $Preset_File_Path" -showtime -color cyan
    $Preset_to_Update | Export-Clixml -Path $Preset_File_Path -Force -Encoding UTF8
    write-ezlogs ">>> Updating app config custom eq playlists" -showtime -color cyan
    if($thisApp.Config.Custom_EQ_Presets.Preset_Name -notcontains $PresetName){
      $newRow = New-Object PsObject -Property @{
        'Preset_Name' = $PresetName
        'Preset_ID'   = $Preset_encodedTitle
        'Preset_Path' = $Preset_File_Path
      } 
      $null = $thisApp.Config.Custom_EQ_Presets.add($newRow) 
      $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8  
    }   
    return $Preset_to_Update
  }else{
    write-ezlogs "Could not find Preset to update or no Preset to update was provided" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Add-EQPreset Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-EQPreset')

