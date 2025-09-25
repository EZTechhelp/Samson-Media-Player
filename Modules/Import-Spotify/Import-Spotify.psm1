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
    [string]$Spotify_URL,
    [switch]$StartPlayback,
    [switch]$FullRefresh,
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
      [string]$Spotify_URL,
      [switch]$StartPlayback,
      [switch]$FullRefresh,
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
      if($Spotify_URL){
        if($StartPlayback){
          write-ezlogs "| Starting new playback for Spotify url: $Spotify_URL" -logtype Spotify
          Add-SpotifyPlayback -synchash $synchash -thisApp $thisApp -LinkUri $Spotify_URL -SpotifyType 'Custom' -StartPlayback
        }
        if($Spotify_URL -notin $thisApp.Config.Spotify_Playlists){
          write-ezlogs "| Adding new Spotify url to library: $Spotify_URL" -logtype Spotify
          [void]$thisApp.Config.Spotify_Playlists.Add($Spotify_URL)
        }else{
          write-ezlogs "Provided Spotify URL already added to library: $Spotify_URL" -Warning -logtype Spotify
          return
        }
      }
      Get-Spotify -Media_directories $Media_directories -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -synchash $synchash -FullRefresh:$FullRefresh
    }catch{
      write-ezlogs "An exception occurred in Get-Spotify" -showtime -catcherror $_
    }
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
    Start-Runspace -scriptblock $import_SpotifyMedia_scriptblock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name 'Import_SpotifyMedia_Runspace' -thisApp $thisApp -synchash $synchash -RestrictedRunspace:$RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable' -Command_list 'Set-StrictMode' -modules_list 'Microsoft.PowerShell.Utility'
  }catch{
    write-ezlogs "An exception occurred executing Start-Runspace for runspace: Import_SpotifyMedia_Runspace" -CatchError $_
  }
  $import_SpotifyMedia_scriptblock = $Null
}
#----------------------------------------------
#endregion Import-Spotify Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Spotify')