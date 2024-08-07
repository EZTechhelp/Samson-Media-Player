<#
    .Name
    Start-MediaTransportControls

    .Version 
    0.1.0

    .SYNOPSIS
    Creates connection and integration to SystemMediaTransportControls 

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
#region Start-MediaTransportControls Function
#----------------------------------------------
function Start-MediaTransportControls{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    [switch]$use_Runspace
  )
  $MediaTransportControls_ScriptBlock = {
    [CmdletBinding()]
    param (
      $synchash,
      $thisApp,
      [switch]$use_Runspace
    )
    try{
      $MediaTransportControl_Assemblies = @(
        "$($thisApp.Config.Current_Folder)\Assembly\WinRT\Microsoft.Windows.SDK.NET.dll",
        "$($thisApp.Config.Current_Folder)\Assembly\WinRT\PoshWinRT.dll"
        "$($thisApp.Config.Current_Folder)\Assembly\WinRT\WinRT.Runtime.dll"
      )
      if($psversiontable.PSVersion.Major -gt 5){
        foreach($a in $MediaTransportControl_Assemblies){
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Loading WinRT assembly: $a" -Dev_mode}
          $null = [System.Reflection.Assembly]::LoadFrom($a)
        }   
      }else{
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Loading WinRT assembly: $($thisApp.Config.Current_Folder)\Assembly\WinRT\PoshWinRT.dll" -Dev_mode}
        $null = [System.Reflection.Assembly]::LoadFrom("$($thisApp.Config.Current_Folder)\Assembly\WinRT\PoshWinRT.dll")
        [void][Windows.Media.Playback.MediaPlayer,Windows.Media.Playback,ContentType=WindowsRuntime]
      }
      <#      if($psversiontable.PSVersion.Major -gt 5){
          [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Windows.SDK.NET')
          [void][System.Reflection.Assembly]::LoadWithPartialName('WinRT.Runtime')
          }else{
          [void][Windows.Media.Playback.MediaPlayer,Windows.Media.Playback,ContentType=WindowsRuntime]
      }#> 
      Import-module "$($thisApp.Config.Current_Folder)\Modules\Register-WinRTEvent\Register-WinRTEvent.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module "$($thisApp.Config.Current_Folder)\Modules\EZT-AudioManager\EZT-AudioManager.psm1" -NoClobber -DisableNameChecking
      $synchash.systemmediaplayer = [Windows.Media.Playback.MediaPlayer]::new()
      $synchash.systemmediaplayer.CommandManager.IsEnabled = $false
      $file = New-StorageFile -path "$($thisApp.Config.Current_folder)\Resources\Samson_Icon1.png"
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsNextEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsPreviousEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsPlayEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsPauseEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsStopEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsFastForwardEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsRewindEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.ShuffleEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsChannelUpEnabled = $true
      $synchash.systemmediaplayer.SystemMediaTransportControls.IsChannelDownEnabled = $true
      #$Timeline = [Windows.Media.SystemMediaTransportControlsTimelineProperties]::new()
      #$Timeline.StartTime = [TimeSpan]::FromMinutes(0)
      #$Timeline.EndTime = [TimeSpan]::FromMinutes(5)
      #$Timeline.Position = [TimeSpan]::FromMinutes(1)
      #$synchash.systemmediaplayer.SystemMediaTransportControls.UpdateTimelineProperties($Timeline)
      $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Type = 'Music'
      $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
      Register-WinRTEvent -InputObject $synchash.systemmediaplayer.SystemMediaTransportControls -eventName 'ButtonPressed' -synchash $synchash -thisapp $thisApp  -control 'Windows.Media.SystemMediaTransportControls' -controlType 'Windows.Media.SystemMediaTransportControlsButtonPressedEventArgs'
      $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.artist = "$($thisApp.Config.App_name) Media Player"
      if($file){
        $thumbnail = [Windows.Storage.Streams.RandomAccessStreamReference]::CreateFromFile($file)
        $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Thumbnail = $thumbnail
      }
      $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Stopped'
      $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()

      #---------------------------------------------- 
      #region Get-AudioSessions
      #----------------------------------------------
      Get-AudioSessions -synchash $synchash -thisApp $thisapp -Startup
      #---------------------------------------------- 
      #endregion Get-AudioSessions
      #----------------------------------------------
      if($thisApp.Config.Verbose_logging){
        write-ezlogs "Media Controls: $($synchash.systemmediaplayer.SystemMediaTransportControls)" -showtime
        write-ezlogs "Media Controls: $($synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater)" -showtime
      }
    }catch{
      write-ezlogs "An exception occurred in MediaTransportControls_scriptblock" -showtime -catcherror $_
    }
    if($thisApp.Jobs.Name.IndexOf('MediaTransportControls') -ne -1){
      $waithandle = [System.WeakReference]::new($thisApp.Jobs[$($thisApp.Jobs.Name.IndexOf('MediaTransportControls'))],$false)
      do{
        [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(50)
      }while($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $waithandle.IsAlive)
    }
    write-ezlogs "SystemMediaTransportControls has ended!" -warning
  }
  if($use_Runspace){
    #$Variable_list = Get-Variable -Scope Local | & { process {if (($_.Name -in $PSBoundParameters.keys -or $_.Name -in 'thisApp','synchash','jobs')){$_}}}
    Start-Runspace $MediaTransportControls_ScriptBlock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "MediaTransportControls" -thisApp $thisapp -RestrictedRunspace -function_list 'write-ezlogs' -cancel_runspace
    #$Variable_list = $null
  }else{
    Invoke-Command -ScriptBlock $MediaTransportControls_ScriptBlock -ArgumentList $synchash,$thisApp,$use_Runspace
  }
}
#---------------------------------------------- 
#endregion Start-MediaTransportControls Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-MediaTransportControls Function
#----------------------------------------------
function Update-MediaTransportControls{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    $Media,
    $Thumbnail,
    [switch]$use_Runspace,
    [switch]$Verboselog
  )
  $MediaTransportControls_ScriptBlock = {
    [CmdletBinding()]
    param (
      $synchash,
      $thisApp,
      $Media,
      $Thumbnail,
      [switch]$use_Runspace,
      [switch]$Verboselog
    )
    try{
      <#      if($use_Runspace){
          Import-module "$($thisApp.Config.Current_Folder)\Modules\Register-WinRTEvent\Register-WinRTEvent.psm1" -NoClobber -DisableNameChecking -Scope Local
          Import-Module "$($thisApp.Config.Current_Folder)\Modules\EZT-AudioManager\EZT-AudioManager.psm1" -NoClobber -DisableNameChecking
      }#>
      if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Media.title){
        if($Verboselog){write-ezlogs "[Update-MediaTransportControls] Setting Media properties for SystemMediaTransportcontrols $($synchash.systemmediaplayer.SystemMediaTransportControls)" -showtime}          
        if($synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Type -ne 'Music'){
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Type = 'Music'
          #$synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
        }          
        if($synchash.streamlink.title -or $Media.Stream_title){
          if($Media.Stream_title){
            $title = $Media.Stream_title
          }else{
            $title = $synchash.streamlink.title
          }
        }else{
          $title = $Media.title
        }
        if($synchash.streamlink.User_Name){
          $artist = "$($synchash.streamlink.User_Name)"
        }elseif($Media.artist){
          $artist = "$($Media.artist)"
        }elseif($Media.artist_name){
          $artist = "$($Media.artist_name)"
        }
        if($Media.Album){
          $Album = $Media.Album
        }else{
          $Album = ''
        }
        if($synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.Title -ne $title){
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.Title = $title
        }
        if($synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.Artist -ne $artist){
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.Artist = $artist
        }       
        if($synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.AlbumTitle -ne $Album){
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.Artist = $Album
        }
        $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
      }
      if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Thumbnail){                                        
        try{
          $file = New-StorageFile -path $Thumbnail
        }catch{
          write-ezlogs "An exception occurred executing New-StorageFile for background image" -showtime -catcherror $_
        }
        if($file){
          #$synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
          write-ezlogs "[Update-MediaTransportControls] >>>> Setting Media thumbnail image for SystemMediaTransportcontrols: $($file.path)" -showtime
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Thumbnail = [Windows.Storage.Streams.RandomAccessStreamReference]::CreateFromFile($file)
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
        }      
      }
    }catch{
      write-ezlogs "An exception occurred in MediaTransportControls_scriptblock" -showtime -catcherror $_
    }
  }
  if($use_Runspace){
    Start-Runspace $MediaTransportControls_ScriptBlock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Update_MediaTransportControls_Runspace" -thisApp $thisapp -RestrictedRunspace -function_list 'write-ezlogs'
  }else{
    Invoke-Command -ScriptBlock $MediaTransportControls_ScriptBlock -ArgumentList $synchash,$thisApp,$Media,$Thumbnail,$use_Runspace,$Verboselog
  }
}
#---------------------------------------------- 
#endregion Update-MediaTransportControls Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-MediaTransportControls','Update-MediaTransportControls')