<#
    .Name
    Add-TrayMenu

    .Version
    0.1.0

    .SYNOPSIS
    Creates and updates system tray context menus

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
#region Add-TrayMenu Function
#----------------------------------------------
function Add-TrayMenu
{
  Param (
    $thisApp,
    $synchash,
    $all_playlists,
    [switch]$Update_Playlists,
    [switch]$Startup,
    [switch]$StartMini,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$addJumplist,
    [switch]$Verboselog
  )

  try{

    $DigitalDreams_Italic_Font = "$(([uri]"$($thisApp.Config.Current_Folder)\Resources\Fonts\digital-7 (italic).ttf").AbsoluteUri)#Digital-7"
    $DigitalDreams_Font = "$(([uri]"$($thisApp.Config.Current_Folder)\Resources\Fonts\digital-7.ttf").AbsoluteUri)#Digital-7"
    if($synchash.TrayPlayer){
      if($Verboselog){write-ezlogs ">>>> Executing Add-TrayMenu" -showtime}
      [System.Windows.RoutedEventHandler]$Synchash.CloseApp_Command  = {
        param($sender)
        try{
          if($synchash.TrayPlayer){
            $synchash.TrayPlayer.dispose()
          }
          if($synchash.MiniPlayer_Viewer){
            $synchash.MiniPlayer_Viewer.close()
          }
          $syncHash.Window.close()
        }catch{
          write-ezlogs "An exception ocurred in CloseApp_Command event" -showtime -catcherror $_
        }
      }
      $Synchash.OpenTrayPopup_Command  = {
        param($sender)
        try{
          #write-ezlogs "OpenTrayPopup_Command $($sender | out-string)" -showtime
          if($synchash.MiniPlayer_Viewer.isVisible){
            $synchash.MiniPlayer_Viewer.activate()
          }
        }catch{
          write-ezlogs "An exception occurred in EditProfile_Command routed event" -showtime -catcherror $_
        }
      }
      $OpenTrayPopup_Command = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.OpenTrayPopup_Command -target $synchash.TrayPlayer
      [System.Windows.RoutedEventHandler]$Synchash.OpenApp_Command  = {
        param($sender)
        try{
          if($synchash.MiniPlayer_Viewer.isVisible){
            $synchash.MiniPlayer_Viewer.close()
          }
          $synchash.window.Opacity = 1
          $synchash.window.ShowActivated = $true
          $synchash.window.ShowInTaskbar = $true
          $synchash.Window.Show()
          if($SyncHash.Window.WindowState -ne 'Normal'){
            $SyncHash.Window.WindowState = 'Normal'
          }
          if($synchash.MediaLibraryFloat.isVisible){
            $synchash.MediaLibraryFloat.Activate()
          }
          if($synchash.VideoViewFloat.isVisible){
            $synchash.VideoViewFloat.Activate()
          }
          if($hashsetup.window.IsInitialized -and ($hashsetup.Window.Visibility -eq 'Visible')){
            Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Show
          }
          $synchash.Window.Activate()
          write-ezlogs "[TRAYMENU] Open app command executed from tray menu" -GetMemoryUsage -forceCollection
        }catch{
          write-ezlogs "An exception occurred in EditProfile_Command routed event" -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$Synchash.VideoView_Command = {
        param($sender)
        try{
          if($synchash.MediaViewAnchorable.isFloating){
            $synchash.MediaViewAnchorable.dock()
            if($synchash.MiniPlayer_Viewer.isVisible){
              if($synchash.VideoButton_ToggleButton.isChecked){
                Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Close
                #$synchash.VideoButton_ToggleButton.isChecked = $false
              }
              if($synchash.VideoView.Visibility -notin 'Hidden','Collapsed'){
                write-ezlogs ">>>> Video view is visible and MiniPlayer is visible, hiding video view" -Warning
                $synchash.VideoView.Visibility = 'Collapsed'
              }
            }
          }else{
            if(!$synchash.VideoButton_ToggleButton.isChecked){
              if($synchash.VideoViewFloat.Height){
                $synchash.MediaViewAnchorable.FloatingHeight = $synchash.VideoViewFloat.Height
              }else{
                $synchash.MediaViewAnchorable.FloatingHeight = '400'
              }
              if(!$synchash.MiniPlayer_Viewer.isVisible){
                Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Open
              }
            }
            if($synchash.VideoView.Visibility -in 'Hidden','Collapsed' -and (!$synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio) -and $synchash.WebPlayer_State -eq 0 -and !$synchash.Youtube_WebPlayer_title){
              write-ezlogs ">>>> Video view is not visible and MiniPlayer is visible, Youtube webplayer not playing, unhiding video view" -Warning
              $synchash.VideoView.Visibility = 'Visible'
            }
            $synchash.MediaViewAnchorable.float()
          }
        }catch{
          write-ezlogs "An exception occurred in VideoView_Command routed event" -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.QuickSettings_Command = {
        param($sender)
        try{
          switch($sender.Header)
          {
            'Start on Windows Login' {
              if(!$sender.isChecked){
                Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: false"
                $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
                foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {
                  if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
                    $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
                  }
                }
                if(!$install_folder){
                  $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
                  foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {
                    if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
                      $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
                    }
                  }
                }
                [void]$Registry.Dispose()
                if([System.IO.Directory]::Exists($install_folder)){
                  $Main_exe = [System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).exe")
                  if([System.IO.File]::Exists($Main_exe)){
                    $thisapp.config.Start_On_Windows_Login = $true
                    $thisapp.config.App_Exe_Path = $Main_exe
                    $sender.isChecked = $true
                    if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                      write-ezlogs "[Quick Settings] The app $($thisApp.Config.App_Name) is already configured to start on Windows logon" -Warning
                    }else{
                      try{
                        New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Value $Main_exe -Force -ErrorAction SilentlyContinue
                        if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                          write-ezlogs "[Quick Settings] The app $($thisApp.Config.App_Name) has been successfully configured to start automatically upon logon to Windows (current user)" -Success
                        }else{
                          write-ezlogs "[Quick Settings] Unable to verify if $($thisApp.Config.App_Name) was successfully configured to start automatically upon logon to Windows (current user) - List of current user Run reg entries $((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') | out-string)" -Warning
                        }
                      }catch{
                        write-ezlogs "[Quick Settings] An exception occurred attempting to create startup entry for exe path $($Main_exe)" -CatchError $_
                        $thisapp.config.Start_On_Windows_Login = $false
                        $sender.isChecked = $false
                        return
                      }
                    }
                  }else{
                    $thisapp.config.Start_On_Windows_Login = $false
                    $sender.isChecked = $false
                    write-ezlogs "Can't enable option 'Start on Windows Login'. Could not find main exe file for $($thisApp.Config.App_Name) in folder ($install_folder)" -Warning -AlertUI
                    if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                      try{
                        Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force
                        write-ezlogs "[Quick Settings] Removed app $($thisApp.Config.App_Name) from starting on Windows logon." -Warning
                      }catch{
                        write-ezlogs "[Quick Settings] An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_
                      }
                    }
                    return
                  }
                }else{
                  write-ezlogs "Can't enable option 'Start on Windows Login'. Could not find app install folder ($install_folder)" -Warning -AlertUI
                  $thisapp.config.Start_On_Windows_Login = $false
                  $sender.isChecked = $false
                  if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                    try{
                      Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force
                      $thisapp.config.Start_On_Windows_Login = $false
                      write-ezlogs "[Quick Settings] Removed app $($thisApp.Config.App_Name) from starting on Windows logon" -Warning
                    }catch{
                      write-ezlogs "[Quick Settings] An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_
                    }
                  }
                }
              }else{
                Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: true"
                $Sender.isChecked = $false
                $thisapp.config.Start_On_Windows_Login = $false
                if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                  try{
                    write-ezlogs ">>>> Disabling setting: $($sender.Header)"
                    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force -ErrorAction SilentlyContinue
                    write-ezlogs "[Quick Settings] Removed app $($thisApp.Config.App_Name) from starting on Windows logon." -Success
                  }catch{
                    write-ezlogs "[Quick Settings] An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_
                  }
                }else{
                  write-ezlogs "[Quick Settings] The app $($thisApp.Config.App_Name) is not configured to start on Windows logon."
                }
              }
            }
            'Start As MiniPlayer' {
              if($Sender.isChecked){
                $thisApp.Config.Start_Mini_only = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Start_Mini_only = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Use Hardware Acceleration' {
              if($Sender.isChecked){
                $thisApp.Config.Use_HardwareAcceleration = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Use_HardwareAcceleration = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Auto Open/Close Video Player' {
              if($Sender.isChecked){
                $thisApp.Config.Open_VideoPlayer = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Open_VideoPlayer = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Remember Playback Progress' {
              if($Sender.isChecked){
                $thisApp.Config.Remember_Playback_Progress = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Remember_Playback_Progress = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Enable Audio Visualizations' {
              if($Sender.isChecked){
                $thisApp.Config.Use_Visualizations = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Use_Visualizations = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Enable Discord Integration' {
              if(!$Sender.isChecked){
                $Sender.isChecked = $true
                $thisApp.config.Discord_Integration = $true
                if($synchash.Current_playing_media -and $synchash.DSClientTimer){
                  try{
                    Set-DiscordPresense -synchash $synchash -media $synchash.Current_playing_media -thisapp $thisApp -start -Startup
                  }catch{
                    write-ezlogs "An exception occurred executing Set-DiscordPresence" -showtime -catcherror $_
                  }
                }
              }else{
                try{
                  $Sender.isChecked = $false
                  $thisApp.config.Discord_Integration = $false
                  Set-DiscordPresense -synchash $synchash -thisapp $thisApp -stop -runspace
                }catch{
                  write-ezlogs "An exception occurred executing Set-DiscordPresence" -showtime -catcherror $_
                }
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Skip Duplicates' {
              if($Sender.isChecked){
                $thisApp.Config.LocalMedia_SkipDuplicates = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.LocalMedia_SkipDuplicates = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Monitor Local Paths' {
              if($Sender.isChecked){
                $thisApp.Config.Enable_LocalMedia_Monitor = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Enable_LocalMedia_Monitor = $true
                $Sender.isChecked = $true
              }
              if($thisApp.Config.Enable_LocalMedia_Monitor -and $thisApp.Config.Media_Directories -and (!$thisApp.ProfileManagerEnabled -or !$thisApp.LocalMedia_Monitor_Enabled)){
                $thisApp.Config.Media_Directories | & { process {
                    Start-FileWatcher -FolderPath $_ -MonitorSubFolders -use_Runspace -Start_ProfileManager:$(!$thisApp.ProfileManagerEnabled) -synchash $synchash -thisApp $thisApp -Runspace_Guid (New-GUID).Guid
                }}
              }elseif(!$thisApp.Config.Enable_LocalMedia_Monitor -and ($thisApp.ProfileManagerEnabled -or $thisApp.LocalMedia_Monitor_Enabled)){
                Stop-FileWatcher -thisApp $thisApp -synchash $synchash -use_Runspace -Stop_ProfileManager -force
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Auto Sync Spotify Playlists' {
              if($Sender.isChecked){
                $thisApp.Config.Spotify_Update = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Spotify_Update = $true
                $Sender.isChecked = $true
              }
              if($thisapp.config.Spotify_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Spotify_Update_Interval) -and $thisapp.config.Spotify_Update_Interval -ne 'On Startup'){
                try{
                  Start-SpotifyMonitor -Interval $thisapp.config.Spotify_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
                }catch{
                  write-ezlogs 'An exception occurred in Start-SpotifyMonitor' -catcherror $_
                }
              }elseif($thisApp.SpotifyMonitorEnabled -and (!$thisapp.config.Spotify_Update -or [string]::IsNullOrEmpty($thisapp.config.Spotify_Update_Interval)) -and $thisapp.config.Spotify_Update_Interval -ne 'On Startup'){
                try{
                  $thisApp.SpotifyMonitorEnabled = $false
                }catch{
                  write-ezlogs 'An exception occurred in Start-SpotifyMonitor' -catcherror $_
                }
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Use Spotify Web Player' {
              if($Sender.isChecked){
                $thisApp.Config.Spotify_WebPlayer = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Spotify_WebPlayer = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Auto Sync Youtube Playlists' {
              if($Sender.isChecked){
                $thisApp.Config.Youtube_Update = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Youtube_Update = $true
                $Sender.isChecked = $true
              }
              if($thisapp.config.Youtube_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Youtube_Update_Interval) -and $thisapp.config.Youtube_Update_Interval -ne 'On Startup'){
                try{
                  Start-YoutubeMonitor -Interval $thisapp.config.Youtube_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
                }catch{
                  write-ezlogs 'An exception occurred in Start-YoutubeMonitor' -catcherror $_
                }
              }elseif($thisApp.YoutubeMonitorEnabled -and (!$thisapp.config.Youtube_Update -or [string]::IsNullOrEmpty($thisapp.config.Youtube_Update_Interval)) -and $thisapp.config.Youtube_Update_Interval -ne 'On Startup'){
                try{
                  $thisApp.YoutubeMonitorEnabled = $false
                  $Stop_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Youtube_Monitor_Runspace' -force
                }catch{
                  write-ezlogs 'An exception occurred in Start-YoutubeMonitor' -catcherror $_
                }
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Use Youtube Web Player' {
              if($Sender.isChecked){
                $thisApp.Config.Youtube_WebPlayer = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Youtube_WebPlayer = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Enable Sponserblock' {
              if($Sender.isChecked){
                $thisApp.Config.Enable_Sponsorblock = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Enable_Sponsorblock = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Enable Youtube Comments' {
              if($Sender.isChecked){
                $thisApp.Config.Enable_YoutubeComments = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Enable_YoutubeComments = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Start Playback on Drop' {
              if($Sender.isChecked){
                $thisApp.Config.PlayLink_OnDrop = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.PlayLink_OnDrop = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Save Youtube Playback History' {
              if($Sender.isChecked){
                $thisApp.Config.SaveYoutube_History = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.SaveYoutube_History = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Auto Quality' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Youtube_Quality = 'Auto'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Youtube_Quality' to: $($Sender.Header)"
            }
            'Best Quality' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Youtube_Quality = 'Best'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Youtube_Quality' to: $($Sender.Header)"
            }
            'Medium Quality' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Youtube_Quality = 'Medium'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Youtube_Quality' to: $($Sender.Header)"
            }
            'Low Quality' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Youtube_Quality = 'Low'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Youtube_Quality' to: $($Sender.Header)"
            }
            'Auto Sync Twitch Channels' {
              if($Sender.isChecked){
                $thisApp.Config.Twitch_Update = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Twitch_Update = $true
                $Sender.isChecked = $true
              }
              if($thisapp.config.Twitch_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Twitch_Update_Interval)){
                try{
                  Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
                }catch{
                  write-ezlogs 'An exception occurred starting Start-TwitchMonitor' -catcherror $_
                }
              }else{
                try{
                  if($synchash.TwitchMonitor_timer.isEnabled){
                    write-ezlogs ">>>> Stopping existing TwitchMonitor timer"
                    $synchash.TwitchMonitor_timer.stop()
                  }
                }catch{
                  write-ezlogs 'An exception occurred stopping TwitchMonitor_timer' -catcherror $_
                }
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Enable Twitch Notifications' {
              if($Sender.isChecked){
                $thisApp.Config.Enable_Twitch_Notifications = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Enable_Twitch_Notifications = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Skip Twitch Ads' {
              if($Sender.isChecked){
                $thisApp.Config.Skip_Twitch_Ads = $false
                $Sender.isChecked = $false
              }else{
                $thisApp.Config.Skip_Twitch_Ads = $true
                $Sender.isChecked = $true
              }
              Write-EZLogs -text "[Quick Settings] >>>> Setting option '$($Sender.Header)' to: $($Sender.isChecked)"
            }
            'Best' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = 'Best'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
            '1080p' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = '1080p'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
            '720p' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = '720p'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
            '480p' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = '480p'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
            'Worst' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = 'Worst'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
            'Audio_Only' {
              if($Sender.isChecked){
                $Sender.isChecked = $false
              }
              $thisApp.Config.Twitch_Quality = 'Audio_Only'
              Write-EZLogs -text "[Quick Settings] >>>> Setting option 'Twitch_Quality' to: $($Sender.Header)"
              if($synchash.current_playing_Media.Source -eq 'Twitch' -or $synchash.current_playing_Media.url -match 'twitch\.tv'){
                Restart-Media -thisApp $thisApp -synchash $synchash
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred in QuickSettings_Command routed event" -showtime -catcherror $_
        }
      }
      $synchash.TrayPlayer.Icon =  "$($thisApp.Config.current_folder)\Resources\Samson_Icon_NoText1.ico"
      $synchash.TrayPlayer.Visibility = 'Visible'
      $synchash.TrayPlayer.PopupPlacement = 'AbsolutePoint'
      $synchash.TrayPlayer.LeftClickCommand = $OpenTrayPopup_Command
      if($synchash.txtToolTipDetail){
        $Binding = [System.Windows.Data.Binding]::new()
        $Binding.Source = $synchash.TrayPlayer
        $Binding.Path = "ToolTipText"
        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.txtToolTipDetail,[System.Windows.Controls.TextBlock]::TextProperty, $Binding)
      }
      if($synchash.TaskbarIconImage){
        $Binding = [System.Windows.Data.Binding]::new()
        $Binding.Source = $synchash.MediaView_Image
        $Binding.Path = "Source"
        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.TaskbarIconImage,[System.Windows.Controls.Image]::SourceProperty, $Binding)
      }
      if($synchash.TrayPlayer_Background_Left){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniPlayerSkin_Left.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          #$image.DecodePixelWidth = "2"
          #$image.DecodePixelHeight = "494"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $synchash.TrayPlayer_Background_Left.Source = $image
        }catch{
          write-ezlogs "An exception occurred loading image for TrayPlayer_Background_Left" -CatchError $_
        }
      }
      if($synchash.TrayPlayer_Background_TileGrid){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniPlayerSkin_Tile.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit();
          $image.CacheOption = "OnLoad"
          #$image.DecodePixelWidth = "2"
          #$image.DecodePixelHeight = "494"
          $image.StreamSource = $stream_image
          $image.EndInit();
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $imagebrush = [System.Windows.Media.ImageBrush]::new()
          $ImageBrush.ImageSource = $image
          $imagebrush.TileMode = 'Tile'
          $imagebrush.ViewportUnits = "Absolute"
          #$imagebrush.Viewport = "0,0,200,60"
          $imagebrush.Viewport = "0,0,5,60"
          $imagebrush.ImageSource.freeze()
          $synchash.TrayPlayer_Background_TileGrid.Background = $imagebrush
        }catch{
          write-ezlogs "An exception occurred loading image for TrayPlayer_Background_TileGrid" -CatchError $_
        }
      }
      if($synchash.TrayPlayer_Background_Right){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniPlayerSkin_Right.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          #$image.DecodePixelWidth = "2"
          #$image.DecodePixelHeight = "494"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $synchash.TrayPlayer_Background_Right.Source = $image
        }catch{
          write-ezlogs "An exception occurred loading image for TrayPlayer_Background_Right" -CatchError $_
        }
      }
      if($synchash.MiniDisplayPanel_Background){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\DisplayScreen.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $synchash.MiniDisplayPanel_Background.Source = $image
        }catch{
          write-ezlogs "An exception occurred loading image for MiniDisplayPanel_Background" -CatchError $_
        }
      }

      if($synchash.ShowMainButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Button1.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.ShowMainButton.Source = $image
        $null = $synchash.ShowMainButton_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$Synchash.OpenApp_Command)
      }
      if($synchash.StayOnTopButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Button2.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.StayOnTopButton.Source = $image
        $synchash.StayOnTopButton_ToggleButton.add_Click({
            Param($Sender)
            try{
              if($Sender.isChecked){
                if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.StayOnTopButton_ToggleButton.ToolTip -eq 'Stay On Top'){
                  write-ezlogs ">>>> Enabling TopMost for Miniplayer window"
                  $synchash.MiniPlayer_Viewer.Topmost = $true
                  $thisApp.Config.Mini_Always_On_Top = $true
                  Set-WindowTopMost -thisApp $thisApp -Window $synchash.MiniPlayer_Viewer -Force
                }elseif($synchash.TrayPlayer.isVisible){
                  $synchash.TrayPlayer.CloseTrayPopup()
                  Open-MiniPlayer -thisApp $thisApp -synchash $synchash
                }
              }else{
                if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.StayOnTopButton_ToggleButton.ToolTip -eq 'Stay On Top'){
                  write-ezlogs ">>>> Disabling TopMost for Miniplayer window"
                  $synchash.MiniPlayer_Viewer.Topmost = $false
                  $thisApp.Config.Mini_Always_On_Top = $false
                  Set-WindowTopMost -thisApp $thisApp -Window $synchash.MiniPlayer_Viewer -Disable
                }elseif($synchash.Window.isVisible -and $synchash.TrayPlayer.isVisible){
                  $synchash.TrayPlayer.CloseTrayPopup()
                  Open-MiniPlayer -thisApp $thisApp -synchash $synchash
                }
              }
            }catch{
              write-ezlogs "An exception occurred in StayOnTopButton_ToggleButton click event" -CatchError $_ -showtime
            }
        })
      }

      if($synchash.MiniBackButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\BackButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniBackButton.Source = $image
        #$synchash.MiniBackButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\BackButton.png"
        #$synchash.MiniBackButton.Source.freeze()
        $null = $synchash.MiniBackButton_Button.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PrevMedia_Command)
      }

      if($synchash.MiniStopButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\StopButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniStopButton.Source = $image
        #$synchash.MiniStopButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\StopButton.png"
        #$synchash.MiniStopButton.Source.freeze()
        $null = $synchash.MiniStopButton_Button.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.StopMedia_Command)
      }
      if($synchash.MiniPlayButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Playbutton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniPlayButton.Source = $image
        #$synchash.MiniPlayButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Playbutton.png"
        #$synchash.MiniPlayButton.Source.freeze()
        $null = $synchash.MiniPlayButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PauseMedia_Command)
        #MiniPlay Binding
        $MiniPlay_Binding = [System.Windows.Data.Binding]::new()
        $MiniPlay_Binding.Source = $synchash.PlayButton_ToggleButton
        $MiniPlay_Binding.Path = "IsChecked"
        $MiniPlay_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniPlayButton_ToggleButton,[Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty, $MiniPlay_Binding)
      }
      if($synchash.MiniNextButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\ForwardButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniNextButton.Source = $image
        #$synchash.MiniNextButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\ForwardButton.png"
        #$synchash.MiniNextButton.Source.freeze()
        $null = $synchash.MiniNextButton_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.NextMedia_Command)
      }
      if($synchash.MiniOpenButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Openbutton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniOpenButton.Source = $image
        #$synchash.MiniOpenButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Openbutton.png"
        #$synchash.MiniOpenButton.Source.freeze()
        $synchash.MiniOpenButton_Button.add_Click({
            try{
              $peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($syncHash.OpenButton_Button)
              $invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
              $invokeProv.Invoke()
            }catch{
              write-ezlogs "An exception occurred in MiniOpenButton_Button.add_Click" -CatchError $_ -showtime
            }
        })
      }
      if($synchash.MiniAutoPlay_ToggleButton){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\ForwardButton.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $synchash.MiniAutoPlayButton.Source = $image
          if($thisapp.config.Auto_Playback){
            $synchash.MiniAutoPlay_ToggleButton.isChecked = $true
            $synchash.MiniAutoPlay_ToggleButton.ToolTip = 'AutoPlay Enabled'
          }else{
            $synchash.MiniAutoPlay_ToggleButton.isChecked = $false
            $synchash.MiniAutoPlay_ToggleButton.ToolTip = 'AutoPlay Disabled'
          }
          if(!$synchash.AutoPlay_Button_command){
            [System.Windows.RoutedEventHandler]$synchash.AutoPlay_Button_command = {
              param($sender)
              Set-AutoPlay -thisApp $thisApp -synchash $synchash
            }
          }
          [void]$synchash.MiniAutoPlay_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.AutoPlay_Button_command)
        }catch{
          write-ezlogs "An exception occurred initializing MiniAutoPlay_ToggleButton" -CatchError $_
        }
      }
      #Mini Video Viewer Toggle
      if($synchash.MiniVideo_ToggleButton){
        try{
          $synchash.MiniVideoButton.Source = $image
          [void]$synchash.MiniVideo_ToggleButton.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$Synchash.VideoView_Command)
        }catch{
          write-ezlogs "An exception occurrerd initializing MiniShuffle_ToggleButton" -CatchError $_
        }
      }
      #Mini Shuffle Toggle
      if($synchash.MiniShuffle_ToggleButton){
        try{
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Openbutton.png")
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $Null
          $image.Freeze()
          $synchash.MiniShuffleButton.Source = $image
          if($thisapp.config.Shuffle_Playback){
            $synchash.MiniShuffle_ToggleButton.isChecked = $true
            $synchash.MiniShuffle_ToggleButton.ToolTip = 'Shuffle Enabled'
          }else{
            $synchash.MiniShuffle_ToggleButton.isChecked = $false
            $synchash.MiniShuffle_ToggleButton.ToolTip = 'Shuffle Disabled'
          }
          if(!$synchash.Shuffle_Playback_Button_command){
            [System.Windows.RoutedEventHandler]$synchash.Shuffle_Playback_Button_command = {
              param($sender)
              Set-Shuffle -thisApp $thisApp -synchash $synchash
            }
          }
          [void]$synchash.MiniShuffle_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.Shuffle_Playback_Button_command)
        }catch{
          write-ezlogs "An exception occurrerd initializing MiniShuffle_ToggleButton" -CatchError $_
        }
      }
      #Mini Restart Button
      if($synchash.MiniRestartButton_Button){
        try{
          $synchash.MiniRestartButton.Source = $image
          [void]$synchash.MiniRestartButton_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.RestartMedia_Command)
        }catch{
          write-ezlogs "An exception occurrerd initializing MiniShuffle_ToggleButton" -CatchError $_
        }
      }
      if($synchash.MiniCloseButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\CloseButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniCloseButton.Source = $image
        #$synchash.MiniCloseButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\CloseButton.png"
        #$synchash.MiniCloseButton.Source.freeze()
        $null = $synchash.MiniCloseButton_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.CloseApp_Command)
      }
      if($synchash.MiniMuteButton){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Mutebutton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniMuteButton.Source = $image
        #$synchash.MiniMuteButton.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\Mutebutton.png"
        #$synchash.MiniMuteButton.Source.freeze()
        #$null = $synchash.MiniMuteButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.Mute_Command)

        #MiniMute Binding
        if($synchash.MiniMuteButton_ToggleButton){
          $MiniMute_Binding = [System.Windows.Data.Binding]::new()
          $MiniMute_Binding.Source = $synchash.MuteButton_ToggleButton
          $MiniMute_Binding.Path = "IsChecked"
          $MiniMute_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
          [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniMuteButton_ToggleButton,[Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty, $MiniMute_Binding)
          if($Synchash.Mute_Command){
            $null = $synchash.MiniMuteButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.Mute_Command)
          }
        }
      }
      if($synchash.MiniVolumeSlider_Background){
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\VolumeSlider_Back.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $synchash.MiniVolumeSlider_Background.Source = $image
        #$synchash.MiniVolumeSlider_Background.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\VolumeSlider_Back.png"
        #$synchash.MiniVolumeSlider_Background.Source.freeze()
      }

      #MiniPlayer_Media_Length_Label binding
      $synchash.MiniPlayer_Media_Length_Label.FontFamily = $DigitalDreams_Italic_Font
      $MiniPlayer_Media_Length_Label_Binding = [System.Windows.Data.Binding]::new()
      $MiniPlayer_Media_Length_Label_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniPlayer_Media_Length_Label_Binding.Path = "ToolTip"
      $MiniPlayer_Media_Length_Label_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniPlayer_Media_Length_Label,[System.Windows.Controls.Label]::ToolTipProperty, $MiniPlayer_Media_Length_Label_Binding)


      #Volume slider binding
      $synchash.Tray_Volume_Slider.uid = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\VolumeSlider_Thumb.png"
      $synchash.Tray_Volume_Slider.tag = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\VolumeSlider_Front.png"
      $synchash.Mini_Progress_Slider.tag = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniProgressSlider_Front.png"
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniProgressSlider_Back.png")
      $image = [System.Windows.Media.Imaging.BitmapImage]::new()
      $image.BeginInit()
      $image.CacheOption = "OnLoad"
      $image.StreamSource = $stream_image
      $image.EndInit()
      $stream_image.Close()
      $stream_image.Dispose()
      $stream_image = $Null
      $image.Freeze()
      $synchash.MiniProgressSlider_Background.Source = $image
      #$synchash.MiniProgressSlider_Background.Source = "$($thisApp.Config.current_folder)\Resources\Skins\MiniPlayer\MiniProgressSlider_Back.png"
      #$synchash.MiniProgressSlider_Background.Source.freeze()
      $null = $synchash.Mini_Progress_Slider.AddHandler([System.Windows.Controls.Slider]::ValueChangedEvent,$synchash.MediaPlayer_SliderValueChanged_Command)
      $null = $synchash.Mini_Progress_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_SliderMouseUp_Command)

      #MiniProgressSlider binding
      $MiniProgressSlider_Binding = [System.Windows.Data.Binding]::new()
      $MiniProgressSlider_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniProgressSlider_Binding.Path = "Value"
      $MiniProgressSlider_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_Progress_Slider,[System.Windows.Controls.Slider]::ValueProperty, $MiniProgressSlider_Binding)

      #MiniProgressSlider Tooltip binding
      $MiniProgressSliderTooltip_Binding = [System.Windows.Data.Binding]::new()
      $MiniProgressSliderTooltip_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniProgressSliderTooltip_Binding.Path = "ToolTip"
      $MiniProgressSliderTooltip_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_Progress_Slider,[System.Windows.Controls.Slider]::ToolTipProperty, $MiniProgressSliderTooltip_Binding)

      #MiniProgressSlider Tick binding
      $MiniProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
      $MiniProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniProgressSliderTick_Binding.Path = "Ticks"
      $MiniProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_Progress_Slider,[System.Windows.Controls.Slider]::TicksProperty, $MiniProgressSliderTick_Binding)

      #MiniProgressSlider Maximimum binding
      $MiniProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
      $MiniProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniProgressSliderTick_Binding.Path = "Maximum"
      $MiniProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_Progress_Slider,[System.Windows.Controls.Slider]::MaximumProperty, $MiniProgressSliderTick_Binding)

      #MiniProgressSlider IsEnabled binding
      $MiniProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
      $MiniProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
      $MiniProgressSliderTick_Binding.Path = "IsEnabled"
      $MiniProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_Progress_Slider,[System.Windows.Controls.Slider]::IsEnabledProperty, $MiniProgressSliderTick_Binding)


      $Volume_Slider_Icon_Binding = [System.Windows.Data.Binding]::new()
      $Volume_Slider_Icon_Binding.Source = $synchash.Volume_Slider
      $Volume_Slider_Icon_Binding.Path = "Value"
      $Volume_Slider_Icon_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Tray_Volume_Slider,[System.Windows.Controls.Slider]::ValueProperty, $Volume_Slider_Icon_Binding)
      if($synchash.MediaPlayer_Volume_SliderMouseUp_Command){
        $null = $synchash.Tray_Volume_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_Volume_SliderMouseUp_Command)
      }
      if($synchash.MiniDisplayPanel_Title_TextBlock){
        $synchash.MiniDisplayPanel_Title_TextBlock.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel binding
        $MiniDisplayPanel_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanel_Binding.Source = $synchash.Now_Playing_Title_Label
        $MiniDisplayPanel_Binding.Path = "DataContext"
        $MiniDisplayPanel_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Title_TextBlock,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanel_Binding)
      }
      if($synchash.MiniDisplayPanel_Title_TextBlock2){
        $synchash.MiniDisplayPanel_Title_TextBlock2.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel binding
        $MiniDisplayPanel_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanel_Binding.Source = $synchash.Now_Playing_Title_Label
        $MiniDisplayPanel_Binding.Path = "DataContext"
        $MiniDisplayPanel_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanel_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanel_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Title_TextBlock2,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanel_Binding)
      }
      if($synchash.MiniDisplayPanel_Sep2_Label){
        $synchash.MiniDisplayPanel_Sep2_Label.FontFamily = $DigitalDreams_Font
      }
      if($synchash.MiniDisplayPanel_Sep2_Label2){
        $synchash.MiniDisplayPanel_Sep2_Label2.FontFamily = $DigitalDreams_Font
      }
      if($synchash.MiniDisplayPanel_Artist_TextBlock){
        $synchash.MiniDisplayPanel_Artist_TextBlock.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel binding
        $MiniDisplayPanelArtist_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelArtist_Binding.Source = $synchash.Now_Playing_Artist_Label
        $MiniDisplayPanelArtist_Binding.Path = "DataContext"
        $MiniDisplayPanelArtist_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Artist_TextBlock,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanelArtist_Binding)
        $synchash.MiniDisplayPanel_Artist_TextBlock.FontFamily = $DigitalDreams_Font
      }

      if($synchash.MiniDisplayPanel_Artist_TextBlock2){
        $synchash.MiniDisplayPanel_Artist_TextBlock2.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel binding
        $MiniDisplayPanelArtist_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelArtist_Binding.Source = $synchash.Now_Playing_Artist_Label
        $MiniDisplayPanelArtist_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanelArtist_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanelArtist_Binding.Path = "DataContext"
        $MiniDisplayPanelArtist_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Artist_TextBlock2,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanelArtist_Binding)

        $MiniDisplayPanelArtist_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelArtist_Binding.Source = $synchash.DisplayPanel_Sep2_Label
        $MiniDisplayPanelArtist_Binding.Path = "Visibility"
        $MiniDisplayPanelArtist_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanelArtist_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanelArtist_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Sep2_Label,[System.Windows.Controls.TextBlock]::VisibilityProperty, $MiniDisplayPanelArtist_Binding)
        <#    $MiniDisplayPanelArtist_Binding = New-Object System.Windows.Data.Binding
            $MiniDisplayPanelArtist_Binding.Source = $synchash.DisplayPanel_Sep2_Label2
            $MiniDisplayPanelArtist_Binding.Path = "Visibility"
            $MiniDisplayPanelArtist_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Sep2_Label2,[System.Windows.Controls.TextBlock]::VisibilityProperty, $MiniDisplayPanelArtist_Binding)#>
      }

      #Bitrate
      if($synchash.MiniDisplayPanel_Sep3_Label){
        $synchash.MiniDisplayPanel_Sep3_Label.FontFamily = $DigitalDreams_Font
      }
      if($synchash.MiniDisplayPanel_Sep3_Label2){
        $synchash.MiniDisplayPanel_Sep3_Label2.FontFamily = $DigitalDreams_Font
      }
      if($synchash.MiniDisplayPanel_Bitrate_TextBlock){
        $synchash.MiniDisplayPanel_Bitrate_TextBlock.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel Bitrate binding
        $MiniDisplayPanelBitrate_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelBitrate_Binding.Source = $synchash.DisplayPanel_Bitrate_TextBlock
        $MiniDisplayPanelBitrate_Binding.Path = "Text"
        $MiniDisplayPanelBitrate_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Bitrate_TextBlock,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanelBitrate_Binding)
        $synchash.MiniDisplayPanel_Bitrate_TextBlock.FontFamily = $DigitalDreams_Font
      }

      if($synchash.MiniDisplayPanel_Bitrate_TextBlock2){
        $synchash.MiniDisplayPanel_Bitrate_TextBlock2.FontFamily = $DigitalDreams_Font
        #MiniDisplayPanel binding
        $MiniDisplayPanelBitrate_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelBitrate_Binding.Source = $synchash.DisplayPanel_Bitrate_TextBlock
        $MiniDisplayPanelBitrate_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanelBitrate_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanelBitrate_Binding.Path = "Text"
        $MiniDisplayPanelBitrate_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Bitrate_TextBlock2,[System.Windows.Controls.TextBlock]::TextProperty, $MiniDisplayPanelBitrate_Binding)

        $MiniDisplayPanelBitrate_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelBitrate_Binding.Source = $synchash.DisplayPanel_Sep3_Label
        $MiniDisplayPanelBitrate_Binding.Path = "Visibility"
        $MiniDisplayPanelBitrate_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanelBitrate_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanelBitrate_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Sep3_Label,[System.Windows.Controls.TextBlock]::VisibilityProperty, $MiniDisplayPanelBitrate_Binding)

        $MiniDisplayPanelBitrate_Binding = [System.Windows.Data.Binding]::new()
        $MiniDisplayPanelBitrate_Binding.Source = $synchash.MiniDisplayPanel_Sep3_Label
        $MiniDisplayPanelBitrate_Binding.Path = "Visibility"
        $MiniDisplayPanelBitrate_Binding.NotifyOnTargetUpdated = $true
        $MiniDisplayPanelBitrate_Binding.NotifyOnSourceUpdated = $true
        $MiniDisplayPanelBitrate_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.MiniDisplayPanel_Sep3_Label2,[System.Windows.Controls.TextBlock]::VisibilityProperty, $MiniDisplayPanelBitrate_Binding)

      }
      $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
      if(!$target){
        $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
      }
      $synchash.MiniDisplayPanel_Artist_TextBlock.Add_TargetUpdated({
          try{
            if(-not [string]::IsNullOrEmpty($synchash.MiniDisplayPanel_Artist_TextBlock.Text)){
              $synchash.MiniDisplayPanel_Sep2_Label.Visibility="Visible"
            }else{
              $synchash.MiniDisplayPanel_Sep2_Label.Visibility="Hidden"
            }
          }catch{
            write-ezlogs "An exception occurred in MiniDisplayPanel_Title_TextBlock.Add_TargetUpdated event" -CatchError $_ -showtime
          }
      })

      $synchash.MiniDisplayPanel_Title_TextBlock.Add_SizeChanged({
          Param($Sender,[System.Windows.SizeChangedEventArgs]$e)
          try{
            $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
            if(!$target){
              $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
            }
            $synchash.MiniDisplayPanel_Slide_Storyboard.From = $($synchash.MiniSlideText_StackPanel.ActualWidth + 20)
            if($synchash.MiniSlideText_StackPanel2){
              $synchash.MiniSlideText_StackPanel2.SetValue([System.Windows.Controls.Canvas]::LeftProperty,$(-($synchash.MiniSlideText_StackPanel.ActualWidth) -20))
            }
          }catch{
            write-ezlogs "An exception occurred in MiniSlideText_StackPanel.Add_SizeChanged event" -CatchError $_ -showtime
          }
      })
      $synchash.MiniSlideText_StackPanel.Add_SizeChanged({
          try{
            $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
            if(!$target){
              $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
            }
            $synchash.MiniDisplayPanel_Slide_Storyboard.From = $($synchash.MiniSlideText_StackPanel.ActualWidth + 20)
            $synchash.MiniSlideText_StackPanel2.SetValue([System.Windows.Controls.Canvas]::LeftProperty,$(-($synchash.MiniSlideText_StackPanel.ActualWidth) -20))

            $CurrentDisplayScreenWidth = $synchash.TrayPlayer_Background_TileGrid.ActualWidth + 327
            if($synchash.MiniDisplayPanel_Storyboard -and $synchash.MiniSlideText_StackPanel.ActualWidth -gt $CurrentDisplayScreenWidth){
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.AutoReverse = $false
              if($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){
                $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,5)
              }else{
                $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,$null)
              }
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.Begin()
            }elseif($synchash.MiniDisplayPanel_Storyboard){
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = '1x'
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.Stop()
              $synchash.MiniDisplayPanel_Slide_Storyboard.From = '0'
            }
          }catch{
            write-ezlogs "An exception occurred in SlideText_StackPanel.Add_SizeChanged event" -CatchError $_ -showtime
          }
      })


      $synchash.TrayPlayer.add_PreviewTrayPopupOpen({
          try{
            if($synchash.MiniPlayer_Viewer.isVisible){
              $synchash.MiniPlayer_Viewer.activate()
            }
          }catch{
            write-ezlogs "An exception occurred in TrayPlayer.add_PreviewTrayPopupOpen" -showtime -catcherror $_
          }
      })
      $synchash.TrayPlayer.TrayPopup.add_IsVisibleChanged({
          try{
            if($synchash.TrayPlayer.TrayPopup.isVisible -and $synchash.TrayPlayerFlyout){
              $synchash.TrayPlayerFlyout.isOpen = $true
              if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                $color = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
              }else{
                $color = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
              }
              $synchash.TrayPlayer_FlyoutControl.Tag = $color
              $color = $Null
            }else{
              if($synchash.TrayPlayerFlyout.isOpen){
                $synchash.TrayPlayerFlyout.isOpen = $false
              }
              if($synchash.TrayPlayerQueueFlyout.isOpen){
                $synchash.TrayPlayerQueueFlyout.isOpen = $false
              }
            }
          }catch{
            write-ezlogs "An exception occurred in TrayPlayer.TrayPopup.add_IsVisibleChanged" -showtime -catcherror $_
          }
      })

      [System.Windows.RoutedEventHandler]$synchash.MiniPlayer_ContextMenu = {
        param($sender,$e)
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -or $e.RoutedEvent -eq [Hardcodet.Wpf.TaskbarNotification.TaskbarIcon]::TrayRightMouseDownEvent){
          $items = [System.Collections.Generic.List[Object]]::new()
          if($sender.name -eq 'TrayPlayerGrid'){
            $Open_app_header = "Open Main Player"
          }else{
            $Open_app_header = "Open App"
          }
          $Open_App = @{
            'Header' = $Open_app_header
            'Color' = 'White'
            'Command' = $Synchash.OpenApp_Command
            'icon_image' = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_App)
          $Open_Video = @{
            'Header' = "Video Player"
            'Color' = 'White'
            'IconPack' = 'PackIconFontAwesome'
            'ToolTip' = 'Show Video Player'
            'Icon_Color' = 'WhiteSmoke'
            'Command' = $Synchash.VideoView_Command
            'Icon_kind' = 'PhotoVideoSolid'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_Video)
          $Open_MediaLibrary = @{
            'Header' = "Media Library"
            'Color' = 'White'
            'IconPack' = 'PackIconCodicons'
            'Icon_Color' = 'WhiteSmoke'
            'Command' = $synchash.Detach_Library_button_Command
            'Icon_kind' = 'Library'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_MediaLibrary)
          $Open_WebBrowser = @{
            'Header' = "Web Browser"
            'Color' = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Tag' = 'WebBrowser'
            'Command' = $synchash.Float_Command
            'Icon_kind' = 'Web'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_WebBrowser)
          $Open_AudioSettings = @{
            'Header' = "Audio Settings"
            'Color' = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Command' = $synchash.Audio_Options_Command
            'Icon_kind' = 'TuneVerticalVariant'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_AudioSettings)
          $Open_Settings = @{
            'Header' = "App Settings"
            'Color' = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Command' = $synchash.OpenSettings_Command
            'Icon_kind' = 'Cog'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Open_Settings)
          $SettingsSubitems = [System.Collections.Generic.List[object]]::new()
          $GeneralSubitems = [System.Collections.Generic.List[object]]::new()
          $StartOnLogin = @{
            'Header' = "Start on Windows Login"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Start_On_Windows_Login
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($StartOnLogin)
          $StartAsMiniPlayer = @{
            'Header' = "Start As MiniPlayer"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Start_Mini_only
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($StartAsMiniPlayer)
          $HardwareAcceleration = @{
            'Header' = "Use Hardware Acceleration"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Use_HardwareAcceleration
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($HardwareAcceleration)
          $Open_VideoPlayer = @{
            'Header' = "Auto Open/Close Video Player"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Open_VideoPlayer
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($Open_VideoPlayer)
          $RememberProgress = @{
            'Header' = "Remember Playback Progress"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Remember_Playback_Progress
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($RememberProgress)
          $Visualizations = @{
            'Header' = "Enable Audio Visualizations"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Use_Visualizations
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($Visualizations)
          $DiscordIntegration = @{
            'Header' = "Enable Discord Integration"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Discord_Integration
            'IsCheckable' = $True
          }
          $null = $GeneralSubitems.Add($DiscordIntegration)
          $GeneralOptions = @{
            'Header'   = 'General'
            'Color'    = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Icon_kind' = 'Cogs'
            'Enabled'  = $true
            'Sub_items' = $GeneralSubitems
          }
          [Void]$SettingsSubitems.Add($GeneralOptions)
          $LocalSubitems = [System.Collections.Generic.List[object]]::new()
          $SkipDuplicates = @{
            'Header' = "Skip Duplicates"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.LocalMedia_SkipDuplicates
            'IsCheckable' = $True
          }
          $null = $LocalSubitems.Add($SkipDuplicates)
          $MonitorPaths = @{
            'Header' = "Monitor Local Paths"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Enable_LocalMedia_Monitor
            'IsCheckable' = $True
          }
          $null = $LocalSubitems.Add($MonitorPaths)
          $LocalOptions = @{
            'Header'   = 'Local Media'
            'Color'    = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Icon_kind' = 'Harddisk'
            'Enabled'  = $true
            'Sub_items' = $LocalSubitems
          }
          [Void]$SettingsSubitems.Add($LocalOptions)
          if($thisApp.Config.Import_Spotify_Media){
            $SpotifySubitems = [System.Collections.Generic.List[object]]::new()
            $SpotifySync = @{
              'Header' = "Auto Sync Spotify Playlists"
              'Color' = 'White'
              'Command' = $synchash.QuickSettings_Command
              'Enabled' = $true
              'IsChecked' = $thisApp.Config.Spotify_Update
              'IsCheckable' = $True
            }
            $null = $SpotifySubitems.Add($SpotifySync)
            $SpotifyWebPlayer = @{
              'Header' = "Use Spotify Web Player"
              'Color' = 'White'
              'Command' = $synchash.QuickSettings_Command
              'Enabled' = $true
              'IsChecked' = $thisApp.Config.Spotify_WebPlayer
              'IsCheckable' = $True
            }
            $null = $SpotifySubitems.Add($SpotifyWebPlayer)
            $SpotifyOptions = @{
              'Header'   = 'Spotify'
              'Color'    = 'White'
              'Icon_Color' = '#FF1ED760'
              'Icon_kind' = 'Spotify'
              'Enabled'  = $true
              'Sub_items' = $SpotifySubitems
            }
            [Void]$SettingsSubitems.Add($SpotifyOptions)
          }
          $YoutubeSubitems = [System.Collections.Generic.List[object]]::new()
          if($thisApp.Config.Import_Youtube_Media){
            $YoutubeSync = @{
              'Header' = "Auto Sync Youtube Playlists"
              'Color' = 'White'
              'Command' = $synchash.QuickSettings_Command
              'Enabled' = $true
              'IsChecked' = $thisApp.Config.Youtube_Update
              'IsCheckable' = $True
            }
            $null = $YoutubeSubitems.Add($YoutubeSync)
          }
          $YoutubeWebPlayer = @{
            'Header' = "Use Youtube Web Player"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Youtube_WebPlayer
            'IsCheckable' = $True
          }
          $null = $YoutubeSubitems.Add($YoutubeWebPlayer)
          $SponserBlock = @{
            'Header' = "Enable SponserBlock"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Enable_Sponsorblock
            'IsCheckable' = $True
          }
          $null = $YoutubeSubitems.Add($SponserBlock)
          $YoutubeComments = @{
            'Header' = "Enable Youtube Comments"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Enable_YoutubeComments
            'IsCheckable' = $True
          }
          $null = $YoutubeSubitems.Add($YoutubeComments)
          $PlaybackOnDrop = @{
            'Header' = "Start Playback on Drop"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.PlayLink_OnDrop
            'IsCheckable' = $True
          }
          $null = $YoutubeSubitems.Add($PlaybackOnDrop)
          $SaveYoutubeHistory = @{
            'Header' = "Save Youtube Playback History"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.SaveYoutube_History
            'IsCheckable' = $True
          }
          $null = $YoutubeSubitems.Add($SaveYoutubeHistory)
          $YoutubeQualitySubitems = [System.Collections.Generic.List[object]]::new()
          'Auto','Best','Medium','Low' | & { process {
              $Quality = @{
                'Header' = "$_ Quality"
                'Color' = 'White'
                'Command' = $synchash.QuickSettings_Command
                'Enabled' = $true
                'IsChecked' = $thisApp.Config.Youtube_Quality -eq $_
                'IsCheckable' = $True
              }
              $null = $YoutubeQualitySubitems.Add($Quality)
          }}
          $YoutubeQuality = @{
            'Header'   = 'Preferred Playback Quality'
            'Color'    = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Icon_kind' = 'QualityHigh'
            'Enabled'  = $true
            'Sub_items' = $YoutubeQualitySubitems
          }
          [Void]$YoutubeSubitems.Add($YoutubeQuality)
          $YoutubeOptions = @{
            'Header'   = 'Youtube'
            'Color'    = 'White'
            'Icon_Color' = '#FFFF3737'
            'Icon_kind' = 'Youtube'
            'Enabled'  = $true
            'Sub_items' = $YoutubeSubitems
          }
          [Void]$SettingsSubitems.Add($YoutubeOptions)
          $TwitchSubitems = [System.Collections.Generic.List[object]]::new()
          if($thisApp.Config.Import_Twitch_Media){
            $TwitchSync = @{
              'Header' = "Auto Sync Twitch Channels"
              'Color' = 'White'
              'Command' = $synchash.QuickSettings_Command
              'Enabled' = $true
              'IsChecked' = $thisApp.Config.Twitch_Update
              'IsCheckable' = $True
            }
            $null = $TwitchSubitems.Add($TwitchSync)
          }
          $TwitchAds = @{
            'Header' = "Skip Twitch Ads"
            'Color' = 'White'
            'Command' = $synchash.QuickSettings_Command
            'Enabled' = $true
            'IsChecked' = $thisApp.Config.Skip_Twitch_Ads
            'IsCheckable' = $True
          }
          $null = $TwitchSubitems.Add($TwitchAds)
          $TwitchQualitySubitems = [System.Collections.Generic.List[object]]::new()
          'Best','1080p','720p','480p','Worst','Audio_Only' | & { process {
              $Quality = @{
                'Header' = "$_"
                'Color' = 'White'
                'Command' = $synchash.QuickSettings_Command
                'Enabled' = $true
                'IsChecked' = $thisApp.Config.Twitch_Quality -eq $_
                'IsCheckable' = $True
              }
              $null = $TwitchQualitySubitems.Add($Quality)
          }}
          $TwitchQuality = @{
            'Header'   = 'Preferred Stream Quality'
            'Color'    = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Icon_kind' = 'QualityHigh'
            'Enabled'  = $true
            'Sub_items' = $TwitchQualitySubitems
          }
          [Void]$TwitchSubitems.Add($TwitchQuality)
          $TwitchOptions = @{
            'Header'   = 'Twitch'
            'Color'    = 'White'
            'Icon_Color' = '#FFA970FF'
            'Icon_kind' = 'Youtube'
            'Enabled'  = $true
            'Sub_items' = $TwitchSubitems
          }
          [Void]$SettingsSubitems.Add($TwitchOptions)
          $QuickOptions = @{
            'Header'   = 'Quick Settings'
            'Color'    = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Icon_kind' = 'CogTransfer'
            'Enabled'  = $true
            'Sub_items' = $SettingsSubitems
          }
          [Void]$items.Add($QuickOptions)
          $DevCommand = @{
            'Header' = "(Dev) Clear Memory"
            'Color' = 'White'
            'Icon_Color' = 'WhiteSmoke'
            'Command' = $Synchash.ClearMemory_Command
            'Icon_kind' = 'Memory'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($DevCommand)
          $separator = @{
            'Separator' = $true
            'Style' = 'SeparatorGradient'
          }
          $null = $items.Add($separator)
          $Exit_App = @{
            'Header' = "Exit App"
            'Color' = 'White'
            'Icon_Color' = 'White'
            'Command' = $Synchash.CloseApp_Command
            'Icon_kind' = 'Close'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Exit_App)
          if($sender.name -eq 'TrayPlayerGrid'){
            Add-WPFMenu -control $synchash.TrayPlayerGrid -items $items -AddContextMenu -sourceWindow $synchash -TrayMenu
          }else{
            Add-WPFMenu -control $synchash.TrayPlayer -items $items -AddContextMenu -sourceWindow $synchash -TrayMenu
          }
        }else{
          write-ezlogs "Unknown routed event trigger for MiniPlayer_ContextMenu" -Warning
        }
      }
      $null = $synchash.TrayPlayerGrid.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.MiniPlayer_ContextMenu)
      $null = $synchash.TrayPlayer.AddHandler([Hardcodet.Wpf.TaskbarNotification.TaskbarIcon]::TrayRightMouseDownEvent,$synchash.MiniPlayer_ContextMenu)
      $null = $synchash.TrayPlayer.AddHandler([Hardcodet.Wpf.TaskbarNotification.TaskbarIcon]::TrayMouseDoubleClickEvent,$Synchash.OpenApp_Command)
      if($addJumplist){
        Add-JumpList -thisApp $thisApp -synchash $synchash -StartMini:$StartMini -Use_Runspace -Startup
      }
    }
    return
  }catch{
    write-ezlogs "An exception occurred in Add-TrayMenu" -catcherror $_
  }
}
#----------------------------------------------
#endregion Add-TrayMenu Function
#----------------------------------------------

#----------------------------------------------
#region Add-JumpList Function
#----------------------------------------------
function Add-JumpList
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Use_Runspace,
    [switch]$StartMini,
    [switch]$Verboselog
  )
  try{
    if($Startup -or !$synchash.jumplist){
      if($synchash.Window.isInitialized){
        $window = $synchash.Window
      }elseif($synchash.MiniPlayer_Viewer.isInitialized){
        $window = $synchash.Window
        $Window = $synchash.MiniPlayer_Viewer
      }
      if($Window){
        $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($window)
        $Handle = $Window_Helper.EnsureHandle()
      }
      if($thisApp.Config.Installed_AppID){
        $appid = $thisApp.Config.Installed_AppID
      }else{
        $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        $thisApp.Config.Installed_AppID = $appid
      }
      if($appid -and -not [string]::IsNullOrEmpty($Handle) -and $Handle -ne 0){
        write-ezlogs ">>>> Creating new jumplist for window with handle: $($Handle)" -LogLevel 0 -Verboselog:$Verboselog
        $synchash.jumplist = [Microsoft.WindowsAPICodePack.Taskbar.JumpList]::CreateJumpListForIndividualWindow($appid,$Handle)
        #$synchash.jumplist.KnownCategoryToDisplay = [Microsoft.WindowsAPICodePack.Taskbar.JumpListKnownCategoryType]::Recent
        #$synchash.jumplist.KnownCategoryOrdinalPosition = 1
        #JumpListItemsRemoved Event
        if($Verboselog -or $thisApp.Config.Dev_mode){
          try{
            $Registered_Events = Get-EventSubscriber -force
            $JumpListItemsRemoved = $Registered_Events | Where-Object {$_.EventName -eq 'JumpListItemsRemoved'}
            if($JumpListItemsRemoved){
              write-ezlogs "Unregistering existing event: $($JumpListItemsRemoved.EventName)" -LogLevel 0 -Verboselog:$Verboselog
              Unregister-Event -SourceIdentifier $JumpListItemsRemoved.SourceIdentifier -Force
            }
            $Null = Register-ObjectEvent -InputObject $synchash.jumplist -EventName JumpListItemsRemoved -MessageData $synchash  -Action {
              $synchash = $Event.MessageData
              try{
                write-ezlogs ">>>> Jumplist item removed by user - Event: $($Event | out-string) -- SourceEventArgs: $($Event.SourceEventArgs | out-string) -- sender: $($sender | out-string)"
                [void]$synchash.jumplist.Refresh()
              }catch{
                write-ezlogs "An exception occurred in JumpListItemsRemoved event" -showtime -catcherror $_
              }
            }
          }catch{
            write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
          }
        }
        try{
          [void]$synchash.jumplist.Refresh()
        }catch{
          write-ezlogs "An exception occurred refreshing jumplist: $($synchash.jumplist)" -catcherror $_
        }
      }else{
        write-ezlogs "Could not create jumplist - Invalid Window Handle: $($Window_Helper | out-string)" -Warning
      }
    }
  }catch{
    write-ezlogs "An exeception occurred getting current window handle in Add-Jumplist" -CatchError $_
  }finally{
    $Window_Helper = $null
  }
  $add_Jumplist_ScriptBlock = {
    Param (
      $thisApp = $thisApp,
      $synchash = $synchash,
      [switch]$Use_Runspace = $Use_Runspace,
      [switch]$Startup = $Startup,
      [switch]$StartMini = $StartMini,
      [switch]$Verboselog = $Verboselog
    )
    try{
      if($Verboselog -or $thisApp.Config.Dev_mode){
        $add_Jumplist_Measure = [system.diagnostics.stopwatch]::StartNew()
      }
      if($synchash.jumplist){
        #Tasks
        if($Startup -and [System.IO.File]::Exists($thisApp.Config.App_Exe_Path)){
          write-ezlogs ">>>> Adding New Jumplist" -loglevel 0 -Verboselog:$Verboselog
          $category = [Microsoft.WindowsAPICodePack.Taskbar.JumpListCustomCategory]::new('Tasks')
          $jumptask = [Microsoft.WindowsAPICodePack.Taskbar.JumpListLink]::new($($thisApp.Config.App_Exe_Path),"Move $($thisApp.Config.App_Name) to Current Screen")
          #Move/Start app to Primary Monitor
          $jumptask.Arguments = "-OpentoPrimaryScreen"
          $jumptask.WorkingDirectory = $($thisApp.Config.Current_Folder)
          $jumptask.ShowCommand = 'Show'
          $null = $category.AddJumpListItems($jumptask)
          #Start as MiniPlayer Task
          $jumptask2 = [Microsoft.WindowsAPICodePack.Taskbar.JumpListLink]::new($($thisApp.Config.App_Exe_Path),"Start $($thisApp.Config.App_Name) as MiniPlayer")
          $jumptask2.Arguments = "-StartMini"
          $jumptask2.ShowCommand = 'Show'
          $jumptask2.WorkingDirectory = $($thisApp.Config.Current_Folder)
          $null = $category.AddJumpListItems($jumptask2)
          $synchash.jumplist.AddCustomCategories($category)
        }
        #Recent Media
        $jumprecent = $null
        $icon = $Null
        $Last_played = $Null
        $Track = $Null
        if($thisApp.config.History_Playlist.values){
          if($Startup -or !$synchash.jumplist_categoryRecent){
            $synchash.jumplist_categoryRecent = [Microsoft.WindowsAPICodePack.Taskbar.JumpListCustomCategory]::new('Last Played')
          }
          $HistoryList = [SerializableDictionary[int,string]]::new($thisApp.config.History_Playlist)
          #$HistoryList = $thisApp.config.History_Playlist.psobject.Copy()
          $History_items_toremove = [System.Collections.Generic.List[object]]::new()
          $method = $synchash.jumplist_categoryRecent.gettype().GetMethod('get_JumpListItems',[System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
          $JumplistItems = $method.Invoke($synchash.jumplist_categoryRecent,$Null)
          if($thisApp.Config.App_Exe_Path -in $JumplistItems.path){
            write-ezlogs ">>>> Clearing jumpitems with Path: $($thisApp.Config.App_Exe_Path)" -LogLevel 0 -Verboselog:$VerboseLog
            $JumplistItems.clear()
            $Removemethod = $synchash.jumplist_categoryRecent.gettype().GetMethod('RemoveJumpListItem',[System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
            if($Removemethod){
              $Removemethod.invoke($synchash.jumplist_categoryRecent,$thisApp.Config.App_Exe_Path)
            }
          }
          $HistoryList.keys | Sort-Object -Descending | & { process {
              try{
                $index_toget = $_
                if(-not [string]::IsNullOrEmpty($index_toget) -and $index_toget -ge 0){
                  try{
                    $Last_played = (($HistoryList).Item([double]$index_toget))
                  }catch{
                    $Last_played = $Null
                  }finally{
                    if(!$Last_played){
                      try{
                        $Last_played = (($HistoryList).Item([int]$index_toget))
                      }catch{
                        $Last_played = $Null
                      }
                    }
                  }
                  if(!$Last_played){
                    write-ezlogs "Unable to find any valid items in playlist history with key: $($index_toget) - Type: $($index_toget.gettype())" -showtime -warning
                    $null = $History_items_toremove.add($index_toget)
                  }else{
                    $Track = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $Last_played
                    if(@($Track).count -eq 1){
                      if(-not [string]::IsNullOrEmpty($Track.Display_Name)){
                        $title = $Track.Display_Name
                      }elseif(-not [string]::IsNullOrEmpty($Track.artist) -and $Track.title -notmatch "$([regex]::Escape($Track.artist)) -|- $([regex]::Escape($Track.artist))"){
                        $title = "$($Track.artist) - $($Track.title)"
                      }elseif(-not [string]::IsNullOrEmpty($Track.title)){
                        $title = $Track.title
                      }elseif(-not [string]::IsNullOrEmpty($Track.SongInfo.title)){
                        $title = $Track.SongInfo.title
                      }
                      if($Track.source -eq 'Spotify' -or $Track.url -match 'Spotify\:'){
                        $icon = "$($thisApp.Config.Current_Folder)\Resources\Spotify\Material-Spotify.ico"
                      }elseif($Track.source -in 'Youtube','YoutubeChannel','YoutubePlaylist','YoutubeVideo' -or $Track.url -match 'youtube\.com|youtu\.be'){
                        $icon = "$($thisApp.Config.Current_Folder)\Resources\Youtube\Material-Youtube_Auth.ico"
                      }elseif($Track.source -eq 'Twitch' -or $Track.url -match 'twitch\.com'){
                        $icon = "$($thisApp.Config.Current_Folder)\Resources\Twitch\Material-Twitch.ico"
                      }elseif($Track.source -eq 'Local' -or [system.io.file]::Exists($Track.url)){
                        $icon = "$($thisApp.Config.Current_Folder)\Resources\VLC\Material-Harddisk.ico"
                      }else{
                        $icon = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
                      }
                      if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Add recent media to jumplist: $($title) - Index: $index_toget - ID: $($Last_played)" -showtime -Dev_mode}
                      $jumprecent = [Microsoft.WindowsAPICodePack.Taskbar.JumpListLink]::new($($thisApp.Config.App_Exe_Path),$title)
                      $iconref = [Microsoft.WindowsAPICodePack.Shell.IconReference]::new($icon,0)
                      $jumprecent.IconReference = $iconref
                      $jumprecent.Arguments = "-PlayMedia `"$($Track.url)`""
                      $jumprecent.ShowCommand = 'Show'
                      $jumprecent.WorkingDirectory = $($thisApp.Config.Current_Folder)
                      $null = $synchash.jumplist_categoryRecent.AddJumpListItems($jumprecent)
                    }elseif(@($Track).count -gt 1){
                      write-ezlogs "Found multiple ($(@($Track).count)) media when attempting to lookup previous played for id $($Last_played)" -warning
                    }else{
                      write-ezlogs "Unable to find track info last played item: $Last_played - removing from history list" -warning
                      $null = $History_items_toremove.add([double]$index_toget)
                    }
                  }
                }
              }catch{
                write-ezlogs "An exception occurred processing history key: $($index_toget) -- All history: $($HistoryList | out-string)" -CatchError $_
              }finally{

              }
          }}
          if($Startup){
            $synchash.jumplist.AddCustomCategories($synchash.jumplist_categoryRecent)
          }
        }else{
          write-ezlogs "Didnt find any previous media to add to recent jumplist" -warning
        }
        try{
          [void]$synchash.jumplist.Refresh()
        }catch{
          write-ezlogs "An exception occurred refreshing jumplist: $($synchash.jumplist)" -catcherror $_
        }
        if($History_items_toremove.count -gt 0){
          try{
            lock-object -InputObject $thisApp.config.History_Playlist.SyncRoot -ScriptBlock {
              $History_items_toremove | & { process {
                  [void]$thisApp.config.History_Playlist.Remove([double]$_)
                  #write-ezlogs "Removed invalid or duplicate item index from history $($_)" -warning
              }}
            }
          }catch{
            write-ezlogs "An exception occurred removing invalid or duplicate items from history: $($History_items_toremove)" -catcherror $_
          }
        }
        $History_items_toremove = $Null
      }else{
        write-ezlogs "Unable to create Jumplist - missing jumplist: $($synchash.jumplist | out-string)" -warning
      }
    }catch{
      write-ezlogs "An exception occurred in Add-JumpList" -catcherror $_
    }finally{
      if($add_Jumplist_Measure){
        $null = $add_Jumplist_Measure.stop()
        write-ezlogs "Add-JumpList Measure" -PerfTimer $add_Jumplist_Measure
        $add_Jumplist_Measure = $Null
      }
    }
  }
  if($use_Runspace){
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    #$Variable_list = Get-Variable -Scope Local | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant" -and !$_.Name -in $PSBoundParameters.keys}
    Start-Runspace -scriptblock $add_Jumplist_ScriptBlock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'add_Jumplist_RUNSPACE' -thisApp $thisApp -synchash $synchash -ApartmentState STA
    $Variable_list = $Null
  }else{
    Invoke-Command -ScriptBlock $add_Jumplist_ScriptBlock
    $add_Jumplist_ScriptBlock = $null
  }
}
#----------------------------------------------
#endregion Add-JumpList Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-TrayMenu','Add-JumpList')