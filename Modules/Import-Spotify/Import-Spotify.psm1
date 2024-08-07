<#
    .Name
    Import-Spotify

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Spotify Profiles

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
#region Import-Spotify Function
#----------------------------------------------
function Import-Spotify
{
  param (
    [switch]$Startup,
    $synchash,
    $Media_directories,
    $thisApp,
    [switch]$Import_Cache_Profile = $startup,
    [switch]$NoMediaLibrary,
    [switch]$use_runspace,
    [switch]$RestrictedRunspace,
    [switch]$VerboseLog
  )

  $import_SpotifyMedia_scriptblock = {
    param (
      [switch]$Startup,
      $synchash,
      $Media_directories,
      $thisApp,
      [switch]$Import_Cache_Profile,
      [switch]$NoMediaLibrary,
      [switch]$use_runspace,
      [switch]$RestrictedRunspace,
      [switch]$VerboseLog
    )
    $get_Spotify_Measure = [system.diagnostics.stopwatch]::StartNew()
    try{   
      if($RestrictedRunspace){
        Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
        Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
      }
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Spotify\Get-Spotify.psm1" -NoClobber -DisableNameChecking -Scope Local
      write-ezlogs "#### Getting Spotify Media ####" -linesbefore 1 -logtype Spotify
      try{
        $Controls_to_Update = [System.Collections.Generic.List[Object]]::new(4)
        [void]$Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' = 'spotifyMedia_Progress_Ring'
              'Property' = 'isActive'
              'Value' = $true
        }))    
        [void]$Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' =  'SpotifyMedia_Progress_Label'
              'Property' = 'Visibility'
              'Value' =  'Visible'
        }))                 
        [void]$Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' =  'SpotifyMedia_Progress_Label'
              'Property' = 'Text'
              'Value' =  'Importing Spotify Media...'
        }))
        [void]$Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' =  'SpotifyTable'
              'Property' = 'isEnabled'
              'Value' =  $false
        }))
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      }catch{
        write-ezlogs "An exception occurred updating SpotifyMedia_Progress_Ring" -showtime -catcherror $_
      }
      Get-Spotify -Media_directories $Media_directories -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -synchash $synchash
    }catch{
      write-ezlogs "An exception occurred in Get-Spotify" -showtime -catcherror $_
    }             
    <#      if(!$NoMediaLibrary -and $synchash.All_Spotify_Media){
        $synchash.SpotifyMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Spotify_Media)
        $synchash.SpotifyMedia_View.UsePLINQ = $true
        }else{
        write-ezlogs "[Import-Spotify] All_Spotify_Media was empty!" -showtime -warning -logtype Spotify
    } #>
    if($synchash.SpotifyMedia_TableStartup_timer){
      if($Startup){
        $synchash.SpotifyMedia_TableStartup_timer.tag = 'Startup'
      }else{
        $synchash.SpotifyMedia_TableStartup_timer.tag = $Null
      } 
      $synchash.SpotifyMedia_TableStartup_timer.start()
    }                        
    if($get_Spotify_Measure){
      $get_Spotify_Measure.stop()
      write-ezlogs "Get-Spotify Total Startup" -PerfTimer $Get_Spotify_Measure -GetMemoryUsage
      $get_Spotify_Measure = $Null
    } 
  }
  try{
    Start-Runspace -scriptblock $import_SpotifyMedia_scriptblock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name 'Import_SpotifyMedia_Runspace' -thisApp $thisApp -synchash $synchash -RestrictedRunspace:$RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable' -Command_list 'Set-StrictMode'
  }catch{
    write-ezlogs "An exception occurred executing Start-Runspace for runspace: Import_SpotifyMedia_Runspace" -CatchError $_
  }
  $import_SpotifyMedia_scriptblock = $Null
}
#---------------------------------------------- 
#endregion Import-Spotify Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Spotify')

