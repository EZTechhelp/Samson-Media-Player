<#
    .Name
    Import-Twitch

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Twitch Profiles

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
#region Import-Twitch Function
#----------------------------------------------
function Import-Twitch
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$use_Runspace,
    [switch]$refresh,
    $synchash,
    [string]$Twitch_URL,
    $all_available_Media,
    $Twitch_playlists,
    [string]$Media_Profile_Directory,
    $Refresh_All_Twitch_Media,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,    
    [switch]$VerboseLog
  )
  
  $import_TwitchMedia_scriptblock = ({
      $synchash = $synchash
      $thisApp = $thisApp
      $log = $thisApp.Config.TwitchMedia_logfile
      $Twitch_URL = $Twitch_URL
      $Twitch_playlists = $Twitch_playlists
      try{
        $Controls_to_Update = [System.Collections.Generic.List[Object]]::new(2) 
        $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' = 'Twitch_Progress_Ring'
              'Property' = 'isActive'
              'Value' = $true
        }))    
        $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' =  'TwitchTable'
              'Property' = 'isEnabled'
              'Value' =  $false
        }))                 
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update 
      }catch{
        write-ezlogs "An exception occurred updating Twitch_Progress_Ring" -showtime -catcherror $_
      }
      if($thisApp.Config.Verbose_Logging){write-ezlogs "#### Importing Twitch Media ####" -linesbefore 1 -logtype Twitch}
      $Get_Twitch_Measure = [system.diagnostics.stopwatch]::StartNew()
      if($Twitch_URL){         
        Get-Twitch -Twitch_URL $Twitch_URL -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -log:$log -refresh:$refresh -synchash $synchash
      }else{
        Get-Twitch -Twitch_URLs $Twitch_playlists -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -startup:$Startup -log:$log -refresh:$refresh -synchash $synchash -UpdatePlaylists
      }
      $Get_Twitch_Measure.stop()
      if($Get_Twitch_Measure){
        write-ezlogs "Get-Twitch Measure" -PerfTimer $Get_Twitch_Measure -GetMemoryUsage
        $Get_Twitch_Measure = $Null
      } 
      $Get_Twitch_Measure = $Null
      if($synchash.All_Twitch_Media.count -gt 0){ 
        #$View = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.All_Twitch_Media) 
        #$sortdescription = New-Object System.ComponentModel.SortDescription("Live_Status",'Ascending')
        #$synchash.All_Twitch_Media = $synchash.All_Twitch_Media | sort -Property "Live_Status"
        $synchash.TwitchMedia_View = [System.WeakReference]::new([Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Twitch_Media),$false).Target
        #$synchash.TwitchMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Twitch_Media)
        $synchash.TwitchMedia_View.UsePLINQ = $true
      }else{  
        write-ezlogs "[Import-Twitch] All_Twitch_Media was empty!" -showtime -warning -logtype Twitch
      }
      if($synchash.TwitchMedia_TableStartup_timer){
        $synchash.TwitchMedia_TableStartup_timer.start()
      }     
      $synchash.Twitch_Update = $false 
  
  }) 
  $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace -scriptblock $import_TwitchMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Import_TwitchMedia_Runspace' -thisApp $thisApp -synchash $synchash
  $Variable_list = $Null
  $import_TwitchMedia_scriptblock = $Null
}
#---------------------------------------------- 
#endregion Import-Twitch Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Twitch')
