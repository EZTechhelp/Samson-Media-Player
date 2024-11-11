<#
    .Name
    Set-WPFControls

    .Version 
    0.1.0

    .SYNOPSIS
    Sets event handlers and properties for various WPF controls

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
#region Set-WPFButtons Function
#----------------------------------------------
function Set-WPFButtons
{
  <#
      .Name
      Set-WPFButtons

      .Version 
      0.1.0

      .SYNOPSIS
      Sets events and properties for WPF Buttons  

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
  Param (
    $thisApp,
    $synchash,
    $hashsetup,
    [switch]$No_SettingsPreload,
    [switch]$Verboselog
  )
  try{
    
    #---------------------------------------------- 
    #region PowerButton_ToggleButton
    #----------------------------------------------
    if($synchash.PowerButton_ToggleButton){
      $synchash.PowerButton_ToggleButton.isChecked = $true
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\PowerButton.png")
      $image = [System.Windows.Media.Imaging.BitmapImage]::new()
      $image.BeginInit();
      $image.CacheOption = "OnLoad"
      $image.DecodePixelWidth = "86"
      $image.StreamSource = $stream_image
      $image.EndInit()
      $stream_image.Close()
      $stream_image.Dispose()
      $stream_image = $null
      $image.Freeze()     
      $synchash.PowerButton.Source = $image
      $image = $Null
      $synchash.PowerButton_ToggleButton.add_UnChecked({
          try{
            if($synchash.TrayPlayer){
              $synchash.TrayPlayer.dispose()
            }
            $syncHash.Window.close()       
          }catch{
            write-ezlogs "An exception occurred in PowerButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
          }  
      })
    }
    #---------------------------------------------- 
    #endregion PowerButton_ToggleButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region LibraryPlaylists_ToggleButton
    #----------------------------------------------
    #Creates and adds custom sytle with animations for playlist_column - was done purely in XAML but issues occured binding the animations to property
    if($synchash.LibraryPlaylists_ToggleButton){
      $synchash.LibraryPlaylists_ToggleButton.add_Checked({
          try{
            $synchash.playlists_column.Style = $null
            $sytle = [System.Windows.Style]::new()
            $playlists_column_trigger = [System.Windows.MultiDataTrigger]::new()
            $Condition = [System.Windows.Condition]::new()
            $Binding = [System.Windows.Data.Binding]::new()
            $Binding.Source = $synchash.LibraryPlaylists_ToggleButton
            $Binding.Path = "IsChecked"
            $Condition.Value = $true
            $Condition.Binding = $Binding
            $null = $playlists_column_trigger.Conditions.add($Condition)
            #$BeginStoryboard = $synchash.Window.TryFindResource('Playlists_Column_BeginStoryboard') 
            $BeginStoryboard = [System.Windows.Media.Animation.BeginStoryboard]::new()
            $BeginStoryboard.Storyboard = [System.Windows.Media.Animation.Storyboard]::new()
            $Animation = [WpfExtensions.GridLengthAnimation]::new()
            $Animation.to = $synchash.LibraryPlaylists_Flyout.ActualWidth
            $Animation.Duration = '0:0:0.2'
            $null = $BeginStoryboard.Storyboard.addChild($Animation)
            $null = [System.Windows.Media.Animation.Storyboard]::SetTargetProperty($BeginStoryboard.Storyboard,"(Width)")
            $null = $playlists_column_trigger.EnterActions.Add($BeginStoryboard)
            $ExitStoryboard = [System.Windows.Media.Animation.BeginStoryboard]::new()
            $ExitStoryboard.Storyboard = [System.Windows.Media.Animation.Storyboard]::new()
            $Animation = [WpfExtensions.GridLengthAnimation]::new()
            $Animation.to = "0*"
            $Animation.Duration = '0:0:0.2'
            $null = $ExitStoryboard.Storyboard.addChild($Animation)
            $null = [System.Windows.Media.Animation.Storyboard]::SetTargetProperty($ExitStoryboard.Storyboard,"(Width)")
            $null = $playlists_column_trigger.ExitActions.Add($ExitStoryboard)
            $null = $sytle.Triggers.add($playlists_column_trigger)
            $MaxWidth = $synchash.MediaLibrary_Grid.ActualWidth / 2
            $synchash.playlists_column.MaxWidth=$MaxWidth
            $synchash.playlists_column.Style = $sytle
          }catch{
            write-ezlogs "An exception occurred in PowerButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
          }  
      })
    }
    if($synchash.LocalMedia_GridSplitter){
      #TODO: Testing gridsplitter handling when using custom animations
      $synchash.LocalMedia_GridSplitter.add_DragDelta({
          try{
            $e = $args[1]
            $synchash.playlists_column.Style = $null
            write-ezlogs "HorizontalChange: $($e.HorizontalChange)" -warning
            write-ezlogs "playlists_column.ActualWidth: $($synchash.playlists_column.ActualWidth)" -warning
            $newvalue = [int]($synchash.playlists_column.ActualWidth + $e.HorizontalChange)
            write-ezlogs "newvalue: $($newvalue)" -warning
            $synchash.playlists_column.Width = $newvalue
            write-ezlogs "After: playlists_column.Width: $($synchash.playlists_column.Width)" -warning
            write-ezlogs "After: playlists_column.ActualWidth: $($synchash.playlists_column.ActualWidth)" -warning
          }catch{
            write-ezlogs "An exception occurred in PowerButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
          }  
      })
    }
    #---------------------------------------------- 
    #endregion LibraryPlaylists_ToggleButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region RestartButton
    #----------------------------------------------
    if($synchash.RestartButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\PauseButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "88"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()      
        $synchash.RestartButton_Image.Source = $image
        $image = $Null
        $null = $synchash.RestartButton.AddHandler([Windows.Controls.Button]::ClickEvent,$Synchash.RestartMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region RestartButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion RestartButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region RecordButton_ToggleButton
    #----------------------------------------------
    if($synchash.RecordButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\RecordButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "88"
        $image.StreamSource = $stream_image
        $image.EndInit() 
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.RecordButton.Source = $image
        $image = $Null
        $synchash.RecordButton_ToggleButton.add_Checked({
            try{
              $synchash.DisplayPanel_RECORD_Border.BorderBrush="Red"
              $synchash.DisplayPanel_RECORD_TextBlock.Foreground="Red"
              $synchash.DisplayPanel_RECORD_Border.Opacity="1"  
            }catch{
              write-ezlogs "An exception occurred in RecordButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
            }  
        })
        $synchash.RecordButton_ToggleButton.add_UnChecked({
            try{
              $synchash.DisplayPanel_RECORD_Border.Opacity="0.9"
              $synchash.DisplayPanel_RECORD_Border.BorderBrush="#FF252525"
              $synchash.DisplayPanel_RECORD_TextBlock.Foreground="#FF252525"    
            }catch{
              write-ezlogs "An exception occurred in RecordButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
            }  
        })
        $null = $synchash.RecordButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.RecordMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region RecordButton_ToggleButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion RecordButton_ToggleButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region StopButton_Button
    #----------------------------------------------
    if($synchash.StopButton_Button){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\StopButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "128"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.StopButton.Source = $image
        $image = $Null
        $null = $synchash.StopButton_Button.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.StopMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region StopButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion StopButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region PlayButton_Button
    #----------------------------------------------
    if($synchash.PlayButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\PlayButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "128"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.PlayButton.Source = $image
        $image = $Null
        $null = $synchash.PlayButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PauseMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region PlayButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion PlayButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region TaskbarItem
    #----------------------------------------------
    if($synchash.TaskbarItem_PlayButton){
      try{
        $TaskbarItem_PlayButton_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.PauseMedia_Command -target $synchash.TaskbarItem_PlayButton 
        $synchash.TaskbarItem_PlayButton.Command = $TaskbarItem_PlayButton_relaycommand
        $TaskbarItem_StopButton_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.StopMedia_Command -target $synchash.TaskbarItem_StopButton
        $synchash.TaskbarItem_StopButton.command = $TaskbarItem_StopButton_relaycommand
        #$synchash.TaskbarItem_StopButton.freeze()
        $TaskbarItem_NextButton_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.NextMedia_Command -target $synchash.TaskbarItem_NextButton
        $synchash.TaskbarItem_NextButton.command = $TaskbarItem_NextButton_relaycommand
        #$synchash.TaskbarItem_NextButton.freeze()
        if($thisApp.Config.Current_Theme.PrimaryAccentColor){
          $color = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
        }else{
          $color = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
        }
        if(!$synchash.PlayIcon_PackIcon){
          $PlayIcon = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $PlayIcon.Foreground = $color
          $PlayIcon.Kind = 'Play'
          $PlayIcon_geo = [System.Windows.Media.Geometry]::Parse($PlayIcon.Data)
          $PlayIcon_gd = [System.Windows.Media.GeometryDrawing]::new()
          $PlayIcon_gd.Geometry = $PlayIcon_geo
          $PlayIcon_gd.Brush = $PlayIcon.Foreground
          $PlayIcon_gd.pen = [System.Windows.Media.Pen]::new("#FF1ED760",0)
          $synchash.PlayIcon_PackIcon = [System.Windows.Media.DrawingImage]::new($PlayIcon_gd)
          $PlayIcon = $Null
          $PlayIcon_geo = $Null
          $PlayIcon_gd = $Null    
        }
        if(!$synchash.PauseIcon_PackIcon){
          $PauseIcon = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $PauseIcon.Foreground = $color
          $PauseIcon.Kind = 'Pause'
          $PauseIcon_geo = [System.Windows.Media.Geometry]::Parse($PauseIcon.Data)
          $PauseIcon_gd = [System.Windows.Media.GeometryDrawing]::new()
          $PauseIcon_gd.Geometry = $PauseIcon_geo
          $PauseIcon_gd.Brush = $PauseIcon.Foreground
          $PauseIcon_gd.pen = [System.Windows.Media.Pen]::new("#FF1ED760",0)
          $synchash.PauseIcon_PackIcon = [System.Windows.Media.DrawingImage]::new($PauseIcon_gd)
          $PlayIcon = $Null
          $PlayIcon_geo = $Null
          $PlayIcon_gd = $Null
        }
        if($synchash.Mini_TaskbarItem_PlayButton){
          $synchash.Mini_TaskbarItem_PlayButton.Command = $TaskbarItem_PlayButton_relaycommand
        }
        if($synchash.Mini_TaskbarItem_StopButton){
          $synchash.Mini_TaskbarItem_StopButton.command = $TaskbarItem_StopButton_relaycommand
        }
      }catch{
        write-ezlogs "An exception occurred in region TaskbarItem of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion TaskbarItem
    #----------------------------------------------


    #---------------------------------------------- 
    #region BackButton_Button
    #----------------------------------------------
    if($synchash.BackButton_Button){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\BackButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "88"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.BackButton.Source = $image
        $synchash.BackButton_Button.tooltip = 'Last Played Media'
        $image = $Null
        $null = $synchash.BackButton_Button.AddHandler([Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PrevMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region BackButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion BackButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region NextButton_Button
    #----------------------------------------------
    if($synchash.NextButton_Button){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\NextButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "88"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.NextButton.Source = $image
        $null = $synchash.NextButton_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.NextMedia_Command)
      }catch{
        write-ezlogs "An exception occurred in region NextButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion NextButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region MonitorButton_Button
    #----------------------------------------------
    if($synchash.MonitorButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "60"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.MonitorButton.Source = $image
        $image = $Null
        $synchash.MonitorButton_ToggleButton.add_Checked({
            try{          
              Add-Member -InputObject $thisapp.config -Name 'Enable_AudioMonitor' -Value $true -MemberType NoteProperty -Force
              Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchash -Action Begin
              if($synchash.MonitorButton_TextBlock){
                if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                  $color = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
                }else{
                  $color = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
                }
                $synchash.MonitorButton_TextBlock.Foreground=$color
              }
            }catch{
              write-ezlogs "An exception occurred in MonitorButton_ToggleButton.add_Checked event" -CatchError $_ -showtime
            }  
        })
        $synchash.MonitorButton_ToggleButton.add_UnChecked({
            try{         
              Add-Member -InputObject $thisapp.config -Name 'Enable_AudioMonitor' -Value $false -MemberType NoteProperty -Force
              Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchash -Action Stop
              if($synchash.MonitorButton_TextBlock){
                $synchash.MonitorButton_TextBlock.Foreground="#FF5D6162"
              }
            }catch{
              write-ezlogs "An exception occurred in MonitorButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
            }  
        })
        $synchash.MonitorButton_ToggleButton.isChecked = $thisapp.config.Enable_AudioMonitor
      }catch{
        write-ezlogs "An exception occurred in region MonitorButton_ToggleButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion MonitorButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region MuteButton_Button
    #----------------------------------------------
    if($synchash.MuteButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\MuteButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "60"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.MuteButton.Source = $image
        $image = $Null
        $null = $synchash.MuteButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.Mute_Command)
      }catch{
        write-ezlogs "An exception occurred in region MuteButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion MuteButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region AudioButton_Button
    #----------------------------------------------
    if($synchash.AudioButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\OptionButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "64"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.AudioButton.Source = $image
        $null = $synchash.AudioButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Audio_Options_Command)
      }catch{
        write-ezlogs "An exception occurred in region AudioButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion AudioButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region SettingsButton_Button
    #----------------------------------------------
    if($synchash.SettingsButton_ToggleButton -and $image){
      try{
        $synchash.SettingsButton.Source = $image
        [System.Windows.RoutedEventHandler]$Synchash.OpenSettings_Command = {
          param($sender)
          try{
            if($hashsetup.Window.isVisible){
              $synchash.SettingsButton_ToggleButton.isChecked = $false
              $hashsetup.Window.Dispatcher.InvokeAsync({
                  $hashsetup.window.close() 
              })        
            }else{   
              $synchash.SettingsButton_ToggleButton.isChecked = $true
              $Reload = ($hashsetup.window.IsInitialized -and $hashsetup.Window.Visibility -in 'Collapsed','Hidden')
              write-ezlogs ">>>> Opening Settings Window -- Reload: $($Reload)" -showtime
              if(!$Reload){
                $Global:hashsetup = [hashtable]::Synchronized(@{})
              }
              Show-SettingsWindow -PageTitle "$($thisApp.Config.App_Name) - Settings" -PageHeader 'Settings' -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -synchash $synchash -thisApp $thisapp -hashsetup $hashsetup -Update -First_Run:$false -Reload:$Reload -No_SettingsPreload:$synchash.No_SettingsPreload #-use_runspace
            }              
          }catch{
            write-ezlogs 'An exception occurred in SettingsButton_ToggleButton click event' -showtime -catcherror $_
            $synchash.Window.Activate()
          }
        }
        $null = $synchash.SettingsButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.OpenSettings_Command)
      }catch{
        write-ezlogs "An exception occurred in region SettingsButton_ToggleButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion SettingsButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region PlayQueueButton_Button
    #----------------------------------------------
    if($synchash.PlayQueueButton_ToggleButton){
      try{
        if($synchash.PlayQueueFlyout.IsOpen){
          $synchash.PlayQueueButton_ToggleButton.isChecked = $true
        }else{
          $synchash.PlayQueueButton_ToggleButton.isChecked = $false
        }
        [System.Windows.RoutedEventHandler]$synchash.PlayQueue_button_Command  = {
          param($sender)
          try{
            if($synchash.PlayQueueFlyout.IsOpen){
              $synchash.PlayQueueFlyout.IsOpen = $false
            }else{
              $synchash.PlayQueueFlyout.IsOpen = $true
            }
          }catch{
            write-ezlogs 'An exception occurred in PlayQueueButton_ToggleButton click event' -showtime -catcherror $_
          }
        }
        #Play Queue Flyout
        $synchash.PlayQueueFlyout.add_IsOpenChanged({
            if($synchash.PlayQueueFlyout.isOpen){
              $synchash.PlayQueueButton_ToggleButton.isChecked = $true
            }else{
              $synchash.PlayQueueButton_ToggleButton.isChecked = $false
            }
        })
        $null = $synchash.PlayQueueButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayQueue_button_Command)
        $null = $synchash.PlayQueueFlyout_button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayQueue_button_Command)
        if($synchash.PlayQueueButton -and $image){
          $synchash.PlayQueueButton.Source = $image
        }
      }catch{
        write-ezlogs "An exception occurred in region PlayQueueButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion PlayQueueButton_Button
    #----------------------------------------------
    
    #---------------------------------------------- 
    #region Clear_Queue_Button
    #----------------------------------------------
    if($synchash.Clear_Queue_Button){
      try{
        $null = $synchash.Clear_Queue_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Clear_Queue_Command)
        if($synchash.Clear_Queue_Button_Library){
          $null = $synchash.Clear_Queue_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Clear_Queue_Command)
        }
        if($synchash.Clear_Queue_Button_VideoView){
          $null = $synchash.Clear_Queue_Button_VideoView.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Clear_Queue_Command)
        }
      }catch{
        write-ezlogs "An exception occurred in region Clear_Queue_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion Clear_Queue_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region Refresh_Queue_Button
    #----------------------------------------------
    if($synchash.Refresh_Queue_Button){
      try{
        $null = $synchash.Refresh_Queue_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_Queue_Command)
        if($synchash.Refresh_Queue_Button_Library){
          $null = $synchash.Refresh_Queue_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_Queue_Command)
        }
        if($synchash.Refresh_Queue_Button_VideoView){
          $null = $synchash.Refresh_Queue_Button_VideoView.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_Queue_Command)
        }
      }catch{
        write-ezlogs "An exception occurred in region Refresh_Queue_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion Refresh_Queue_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region LibraryButton_Button
    #----------------------------------------------
    if($synchash.LibraryButton_ToggleButton -and $image){
      try{
        $synchash.LibraryButton.Source = $image
        $null = $synchash.LibraryButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Detach_Library_button_Command)
      }catch{
        write-ezlogs "An exception occurred in region LibraryButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion LibraryButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region VideoButton_Button
    #----------------------------------------------
    if($synchash.VideoButton_ToggleButton -and $image){
      try{
        $synchash.VideoButton.Source = $image
        $null = $synchash.VideoButton_ToggleButton.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.Show_Video_Button_CLick_Command)
      }catch{
        write-ezlogs "An exception occurred in region VideoButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion VideoButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region ShuffleButton_Button
    #----------------------------------------------
    if($synchash.ShuffleButton){
      try{
        if($thisapp.config.Shuffle_Playback){
          $synchash.ShuffleButton_ToggleButton.ToolTip = 'Shuffle Enabled'
          $synchash.ShuffleButton_ToggleButton.isChecked = $true
          if($synchash.Tray_Shuffle_Icon){
            $synchash.Tray_Shuffle_Icon.Kind = "ShuffleVariant"
          }
        }else{
          $synchash.ShuffleButton_ToggleButton.ToolTip = 'Shuffle Disabled'
          $synchash.ShuffleButton_ToggleButton.isChecked = $false
          if($synchash.Tray_Shuffle_Icon){
            $synchash.Tray_Shuffle_Icon.Kind = "ShuffleDisabled"
          }
        }
        <#        [System.EventHandler]$synchash.Shuffle_Playback_tray_command = {
            param($sender)
            Set-Shuffle -thisApp $thisApp -synchash $synchash
        }#>
        [System.Windows.RoutedEventHandler]$synchash.Shuffle_Playback_Button_command = {
          param($sender)
          Set-Shuffle -thisApp $thisApp -synchash $synchash
        }
        $synchash.ShuffleButton.Source = $image
        $null = $synchash.ShuffleButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.Shuffle_Playback_Button_command)
      }catch{
        write-ezlogs "An exception occurred in region ShuffleButton_Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion ShuffleButton_Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region AutoPlayButton_ToggleButton
    #----------------------------------------------
    if($synchash.AutoPlayButton_ToggleButton){
      try{
        if($thisapp.config.Auto_Playback){
          $synchash.AutoPlayButton_ToggleButton.isChecked = $true
          $synchash.AutoPlayButton_ToggleButton.ToolTip = 'AutoPlay Enabled'
        }else{
          $synchash.AutoPlayButton_ToggleButton.isChecked = $false
          $synchash.AutoPlayButton_ToggleButton.ToolTip = 'AutoPlay Disabled'
        }
        [System.EventHandler]$synchash.AutoPlay_tray_command = {
          param($sender)
          Set-AutoPlay -thisApp $thisApp -synchash $synchash
        }
        [System.Windows.RoutedEventHandler]$synchash.AutoPlay_Button_command = {
          param($sender)
          Set-AutoPlay -thisApp $thisApp -synchash $synchash
        }
        $image = $Null
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\OptionButtonDark.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "64"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.AutoPlayButton.Source = $image
        $image = $Null
        $null = $synchash.AutoPlayButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.AutoPlay_Button_command)
      }catch{
        write-ezlogs "An exception occurred in region AutoPlayButton_ToggleButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion AutoPlayButton_ToggleButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region AutoRepeatButton_ToggleButton
    #TODO: Need to finish - add to XAML/UI/SKIN
    #----------------------------------------------
    if($synchash.AutoRepeatButton_ToggleButton){
      try{
        if($thisapp.config.Auto_Repeat){
          $synchash.AutoRepeatButton_ToggleButton.isChecked = $true
          $synchash.AutoRepeatButton_ToggleButton.ToolTip = 'Repeat Enabled'
        }else{
          $synchash.AutoRepeatButton_ToggleButton.isChecked = $false
          $synchash.AutoRepeatButton_ToggleButton.ToolTip = 'Repeat Disabled'
        }
        [System.EventHandler]$synchash.AutoRepeat_tray_command = {
          param($sender)
          Set-AutoRepeat -thisApp $thisApp -synchash $synchash
        }
        [System.Windows.RoutedEventHandler]$synchash.AutoRepeat_Button_command = {
          param($sender)
          Set-AutoRepeat -thisApp $thisApp -synchash $synchash
        }
        $image = $Null
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\OptionButtonDark.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "64"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.AutoRepeatButton.Source = $image
        $image = $Null
        $null = $synchash.AutoRepeatButton_ToggleButton.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.AutoRepeat_Button_command)
      }catch{
        write-ezlogs "An exception occurred in region AutoRepeatButton_ToggleButton of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion AutoRepeatButton_ToggleButton
    #----------------------------------------------

    #---------------------------------------------- 
    #region MiniPlayer Button
    #----------------------------------------------
    if($synchash.MiniPlayerButton_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "60"
        $image.StreamSource = $stream_image
        $image.EndInit() 
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.MiniPlayerButton.Source = $image
        $image = $Null
        [System.Windows.RoutedEventHandler]$synchash.MiniPlayer_button_Command  = {
          param($sender)
          try{    
            Open-MiniPlayer -thisApp $thisApp -synchash $synchash
          }catch{
            write-ezlogs 'An exception occurred in MiniPlayer_button_Command click event' -showtime -catcherror $_
          }
        }
        $null = $synchash.MiniPlayerButton_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.MiniPlayer_button_Command)
      }catch{
        write-ezlogs "An exception occurred in region MiniPlayer Button of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion MiniPlayer Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region Speaker_ToggleButtons
    #----------------------------------------------
    if($synchash.SpeakerLeft_ToggleButton -and $synchash.SpeakerRight_ToggleButton){
      try{
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\SpeakerButton.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "16"
        $image.StreamSource = $stream_image
        $image.EndInit() 
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.SpeakerLeft_ButtonImage.Source = $image
        $synchash.SpeakerRight_ButtonImage.Source = $image
        [System.Windows.RoutedEventHandler]$synchash.Speakers_button_Command = {
          param($sender)
          try{    
            if($sender.name -eq 'SpeakerLeft_ToggleButton'){
              if($hashSpeakerLeft.Window.isVisible){            
                Update-Speakers -Speaker 'Left' -close
              }else{
                $synchash.SpeakerLeft_ToggleButton.isChecked = $true
                $global:hashSpeakerLeft = [hashtable]::Synchronized(@{})
                Show-LeftSpeaker -SplashTitle "Left Speaker - $($thisApp.Config.App_Name)" -Verboselog -thisApp $thisApp -synchash $synchash -hashSpeakerLeft $hashSpeakerLeft
              } 
            }elseif($sender.name -eq 'SpeakerRight_ToggleButton'){
              if($hashSpeakerRight.Window.isVisible){
                Update-Speakers -Speaker 'Right' -close
              }else{
                $global:hashSpeakerRight = [hashtable]::Synchronized(@{}) 
                $synchash.SpeakerRight_ToggleButton.isChecked = $true
                Show-RightSpeaker -SplashTitle "Right Speaker - $($thisApp.Config.App_Name)" -Verboselog -thisApp $thisApp -synchash $synchash -hashSpeakerRight $hashSpeakerRight
              } 
            }
          }catch{
            write-ezlogs 'An exception occurred in MiniPlayer_button_Command click event' -showtime -catcherror $_
          }
        }
        $null = $synchash.SpeakerLeft_ToggleButton.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.Speakers_button_Command)
        $null = $synchash.SpeakerRight_ToggleButton.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.Speakers_button_Command)
      }catch{
        write-ezlogs "An exception occurred in Speaker_ToggleButtons of Set-WPFButtons" -catcherror $_
      }
    }
    #---------------------------------------------- 
    #endregion Speaker_ToggleButtons
    #----------------------------------------------
  }catch{
    write-ezlogs "An exception occurred in Set-WPFButtons" -CatchError $_ -showtime
  }
}
#---------------------------------------------- 
#endregion Set-WPFButtons Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-VideoPlayer Function
#----------------------------------------------
function Set-VideoPlayer
{
  <#
      .Name
      Open-VideoPlayer

      .Version 
      0.1.0

      .SYNOPSIS
      Opens/displays or closes the Video Player  

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
  Param (
    $thisApp,
    $synchash,
    [ValidateSet('Open','Close','FullScreen','Normal','Maximized')]
    [string]$Action,
    [switch]$Close,
    [switch]$Verboselog
  )
  try{
    switch ($Action) {
      'Open' {    
        if([Double]::IsNaN($synchash.Window.Top)){
          $synchash.Window_Top_OnVideoOpen = 1
        }else{
          $synchash.Window_Top_OnVideoOpen = $synchash.Window.Top
        }        
        $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
        if(!$synchash.VideoButton_ToggleButton.isChecked){
          $synchash.VideoButton_ToggleButton.isChecked = $true
        }      
        $syncHash.MainGrid_Background_Image_Source.Stretch = "Uniform"
        [void]$synchash.videoView.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
        if($synchash.VLC_Grid.children -notcontains $synchash.videoView){
          $synchash.VLC_Grid.children.Add($synchash.videoView)
        }
        $synchash.videoView.IsEnabled = $true
        $synchash.VLC_Grid_Row0.Height="300*"
        $synchash.MediaPlayer_Grid_Row2.Height = "300*"
        $synchash.Window.MaxHeight = $primarymonitor.WorkingArea.Height
        $synchash.RootGrid_Row1.Height="115*"
        if($synchash.vlc.isPlaying -and ($synchash.videoView)){
          if(!$synchash.MiniPlayer_Viewer.isVisible -and $synchash.Window.isVisible -and $synchash.VideoView.Visibility -in 'Hidden','Collapsed' -and (!$synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio) -and $synchash.WebPlayer_State -eq 0 -and !$synchash.Youtube_WebPlayer_title){
            write-ezlogs ">>>> Video view is hidden and Main window is not hidden, MiniPlayer_Viewer not visible, Youtube webplayer not playing, unhiding video view" -Warning
            $synchash.VideoView.Visibility = 'Visible'
          } 
        } 
        if($synchash.VideoViewAirControl.Visibility -in 'Hidden','Collapsed'){
          write-ezlogs "| Unhiding VideoViewAirControl"
          $synchash.VideoViewAirControl.Visibility = 'Visible'
        }
        [Double]$OgPositionDiff = ([int]$synchash.Window_Top_OnVideoOpen - 432)
        if($OgPositionDiff -lt 0){
          [Double]$OgPositionDiff = 0
        }
        #TODO: Lame attempt to fix/troubleshoot crash on open/close when using airhack/controls
        <#        $LibVLCSharpWPFForegroundWindow = Get-VisualParentUp -source $synchash.VideoView_Grid -type ([System.Windows.Window])
            if($LibVLCSharpWPFForegroundWindow -and $LibVLCSharpWPFForegroundWindow.MaxHeight -ne '4000'){       
            write-ezlogs "| Setting LibVLCSharpWPFForegroundWindow MaxHeight and Width"
            $LibVLCSharpWPFForegroundWindow.MaxHeight = '4000'
            $LibVLCSharpWPFForegroundWindow.MaxWidth = '4000'
            $LibVLCSharpWPFForegroundWindow.MinWidth = '0'
            $LibVLCSharpWPFForegroundWindow.MinHeight = '0'
        }#>
        write-ezlogs ">>>> Opening Video Player - Original Window.Top: $($synchash.Window.Top) - RestoreBounds: $($synchash.Window.RestoreBounds.Top) - Working area: $($PrimaryMonitor.WorkingArea.Height) - final: $OgPositionDiff" -loglevel 2

        if($synchash.VideoViewHeightDoubleAnimation){
          $synchash.VideoViewHeightDoubleAnimation.To = '914'
        }                   
        if($synchash.VideoViewHeightstoryboard){
          $synchash.VideoViewHeightstoryboard.Begin()
        }
        if($synchash.Window.Top -ge 0 -and $OgPositionDiff -ge 0){
          if($thisApp.Config.Dev_mode){write-ezlogs "Setting windows Top position to: $OgPositionDiff - Window_Top_OnVideoOpen: $($synchash.Window_Top_OnVideoOpen)" -Dev_mode}
          $synchash.VideoViewDoubleAnimation.To = [Double]$OgPositionDiff
          $synchash.VideoViewstoryboard.Begin()
        }            
      }
      'Close' {
        #$synchash.Window_Top_OnVideoClose = $synchash.Window.Top 
        #$synchash.Window_Top_OnVideoClose = $synchash.Window.RestoreBounds.Top
        write-ezlogs ">>>> Closing Video Player - Current Window.Top: $($synchash.Window.Top) - RestoreBounds: $($synchash.Window.RestoreBounds.Top)" -loglevel 2
        if($synchash.VideoButton_ToggleButton.isChecked){
          $synchash.VideoButton_ToggleButton.isChecked = $false
        }             
        $syncHash.MainGrid_Background_Image_Source.Stretch = "UniformToFill"
        if(!$synchash.MediaViewAnchorable.isfloating -and $synchash.VideoViewAirControl.Visibility -eq 'Visible'){
          write-ezlogs "| Collapsing VideoViewAirControl while closing"
          $synchash.VideoViewAirControl.Visibility = 'Collapsed'
        }
        if(!$synchash.VideoViewFloat.isVisible -and !$synchash.MediaViewAnchorable.isfloating){
          write-ezlogs "| Video Player is not floating, collapsing video view" -loglevel 2 -Dev_mode
          $synchash.videoView.IsEnabled = $false
          $synchash.VLC_Grid_Row0.Height="*"
          $synchash.MediaPlayer_Grid_Row2.Height = "*"
        }            
        $synchash.RootGrid_Row1.Height="0*"         
        $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
        $newPosition = ($synchash.Window.Top + 432)    
        if($synchash.Window.Top -eq $synchash.Window_Top_OnVideoOpen -and $synchash.Window_Top_OnVideoOpen -lt ($PrimaryMonitor.WorkingArea.Height - 432)){
          $newPosition = $synchash.Window_Top_OnVideoOpen
        }
        $synchash.VideoViewHeightDoubleAnimation.To = $synchash.Window.MinHeight
        $synchash.VideoViewHeightstoryboard.Begin()
        if($newPosition -ge 0 -and $synchash.Window.Top -ne $newPosition -and $newPosition -lt ($PrimaryMonitor.WorkingArea.Height - 432)){
          write-ezlogs "| Video View Closed -- Setting windows Top position to: $($newPosition) - Window.Top: $($synchash.Window.Top) - Window_Top_OnVideoOpen: $($synchash.Window_Top_OnVideoOpen)"
          $synchash.VideoViewDoubleAnimation.To = $newPosition
          $synchash.VideoViewstoryboard.Begin()                            
        }
      }
      'FullScreen' {
        write-ezlogs ">>>> Setting Video Player to fullscreen" -loglevel 3
        if($synchash.Window.isVisible){
          $synchash.MediaViewAnchorable.FloatingLeft = $synchash.Window.Left
        }
        write-ezlogs ">>>> Undocking and Maximizing Video Player window" -loglevel 2
        $synchash.MediaViewAnchorable.IsMaximized = $true
        $synchash.VideoView_isFullScreen = $true
        $synchash.VideoView_Dock_Icon.tooltip = 'Dock Window'
        $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenNormal'
        $synchash.MediaViewAnchorable.float()
        $synchash.VideoView_LargePlayer_Button.ToolTip = 'Collapse/Shrink Video Player'        
        if($synchash.VideoViewFloat.WindowState -and $synchash.VideoViewFloat.WindowState -ne [System.Windows.WindowState]::Maximized){
          write-ezlogs "| Setting ViewViewFloat window state to Maximized"          
          $synchash.VideoViewFloat.Visibility = 'Collapsed'
          $synchash.VideoViewFloat.WindowStyle = [System.Windows.WindowStyle]::None
          #$synchash.VideoViewFloat.ResizeMode = 'NoResize'
          $synchash.VideoViewFloat.Visibility = 'Visible'
          $synchash.VideoViewFloat.WindowState = [System.Windows.WindowState]::Maximized
        }
        <#        if($synchash.VideoView_Overlay_Grid){
            write-ezlogs "VideoView_Overlay_Grid.isMouseOver $($synchash.VideoView_Overlay_Grid.isMouseOver)" 
            $mouseevent = [System.Windows.Input.MouseEventArgs]::new([System.Windows.Input.Mouse]::PrimaryDevice,0)
            $mouseevent.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
            $synchash.VideoView_Overlay_Grid.RaiseEvent($mouseevent)
        }#> 
      }
      'Normal' {
        write-ezlogs ">>>> Setting Video Player window state to normal" -loglevel 2
        if($synchash.VideoViewFloat.WindowState -and $synchash.VideoViewFloat.WindowState -ne [System.Windows.WindowState]::Normal){
          $synchash.VideoViewFloat.WindowState = [System.Windows.WindowState]::Normal
        }
        $synchash.MediaViewAnchorable.IsMaximized = $false
        if($synchash.VideoView_LargePlayer_Icon.Kind -ne 'ScreenFull'){
          $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenFull'
        }
        if($synchash.VideoViewFloat.ResizeMode -ne [System.Windows.ResizeMode]::CanResize){
          $synchash.VideoViewFloat.ResizeMode = [System.Windows.ResizeMode]::CanResize
        }
        $synchash.VideoView_isFullScreen = $false         
        $synchash.VideoView_LargePlayer_Button.ToolTip = 'Maximize/Fullscreen Video Player'
        if($synchash.Window.Top -ge 0){
          write-ezlogs " | Setting Video Player window top to main window top: $($synchash.Window.Top)" -loglevel 2
          $synchash.VideoViewFloat.Top = $synchash.Window.Top
        }else{
          $synchash.VideoViewFloat.Top = 0
          write-ezlogs " | Setting Video Player window top to 0" -loglevel 2
        }
      }
      'Maximized' {
        write-ezlogs ">>>> Maximizing Video Player Window" -loglevel 2
        $synchash.MediaViewAnchorable.IsMaximized = $true    
        $synchash.VideoView_isFullScreen = $true
        if($synchash.VideoViewFloat -and $synchash.VideoViewFloat.WindowState -ne [System.Windows.WindowState]::Maximized){
          #$synchash.VideoViewFloat.Visibility = 'Collapsed'
          $synchash.VideoViewFloat.WindowStyle = [System.Windows.WindowStyle]::None
          $synchash.VideoViewFloat.ResizeMode = [System.Windows.ResizeMode]::NoResize
          #$synchash.VideoViewFloat.Visibility = 'Visible'
          $synchash.VideoViewFloat.WindowState = [System.Windows.WindowState]::Maximized
          $synchash.VideoViewFloat.Activate()
        }
        $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenNormal'
        $synchash.VideoView_LargePlayer_Button.ToolTip = 'Collapse/Shrink Video Player'
      }
    }
  }catch{
    write-ezlogs 'An exception occurred in Set-VideoPlayer' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Set-VideoPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Open-MiniPlayer Function
#----------------------------------------------
function Open-MiniPlayer
{
  <#
      .Name
      Open-MiniPlayer

      .Version 
      0.1.0

      .SYNOPSIS
      Opens and displays miniplayer  

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
  Param (
    $thisApp,
    $synchash,
    [switch]$startup,
    [switch]$Verboselog
  )
  try{
    if($synchash.TrayPlayerPopUpGrid.children -contains $synchash.TrayPlayerBorder){
      $null = $synchash.TrayPlayerPopUpGrid.children.remove($synchash.TrayPlayerBorder)
    }
    if(!$synchash.MiniPlayer_Viewer.isVisible){
      write-ezlogs "[Caller: $((Get-PSCallStack)[1].Location):$((Get-PSCallStack)[1].ScriptLineNumber)] >>>> Attempting to open MiniPlayer view: Window.IsLoaded: $($synchash.Window.IsLoaded)" -showtime
      $XamlMiniPlayer_window = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\MiniPlayerViewer.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")   
      $MiniPlayer_windowXaml = [Windows.Markup.XAMLReader]::Parse($XamlMiniPlayer_window)
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XamlMiniPlayer_window)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $synchash.Window){
          $synchash."$($name)" = $MiniPlayer_windowXaml.FindName($name)
        }
      }
      $reader.Dispose()
    }elseif($synchash.MiniPlayer_DockPanel.children -contains $synchash.TrayPlayerBorder){
      $null = $synchash.MiniPlayer_DockPanel.children.Remove($synchash.TrayPlayerBorder)
    }
    if($synchash.MiniPlayer_DockPanel.children -notcontains $synchash.TrayPlayerBorder){
      $null = $synchash.MiniPlayer_DockPanel.children.add($synchash.TrayPlayerBorder)
    }
    $synchash.MiniPlayer_Viewer.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"  
    $synchash.MiniPlayer_Viewer.icon.Freeze()
    $synchash.MiniPlayer_Viewer.Title = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version) - $($synchash.Now_Playing_Label.DataContext) - $($synchash.Now_Playing_Title_Label.DataContext)"  
    $synchash.MiniPlayer_Viewer.TaskbarItemInfo.Description = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version) - $($synchash.Now_Playing_Label.DataContext) - $($synchash.Now_Playing_Title_Label.DataContext)"
    $synchash.MiniPlayer_Viewer.IsWindowDraggable = $true
    $synchash.MiniPlayer_Viewer.WindowStyle = [System.Windows.WindowStyle]::None

           
    if($synchash.Mini_TaskbarItem_PlayButton){
      $TaskbarItem_PlayButton_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.PauseMedia_Command -target $synchash.Mini_TaskbarItem_PlayButton 
      $synchash.Mini_TaskbarItem_PlayButton.Command = $TaskbarItem_PlayButton_relaycommand
      $Binding = [System.Windows.Data.Binding]::new()
      $Binding.Source = $synchash.TaskbarItem_PlayButton
      $Binding.Path = "ImageSource"
      $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_TaskbarItem_PlayButton,[System.Windows.Shell.ThumbButtonInfo]::ImageSourceProperty, $Binding)
    }
    if($synchash.Mini_TaskbarItem_StopButton){
      $TaskbarItem_StopButton_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.StopMedia_Command -target $synchash.Mini_TaskbarItem_StopButton
      $synchash.Mini_TaskbarItem_StopButton.command = $TaskbarItem_StopButton_relaycommand
      $Binding = [System.Windows.Data.Binding]::new()
      $Binding.Source = $synchash.TaskbarItem_StopButton
      $Binding.Path = "ImageSource"
      $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
      [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Mini_TaskbarItem_StopButton,[System.Windows.Shell.ThumbButtonInfo]::ImageSourceProperty, $Binding)
    }
    $synchash.TrayPlayer.PopupActivation = 'None'    
    $synchash.StayOnTopButton_ToggleButton.ToolTip = 'Stay On Top'
    $synchash.MiniPlayer_Viewer.add_MouseLeftButtonDown({
        Param($Sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        try{
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
          {
            $synchash.MiniPlayer_Viewer.DragMove()
            $e.handled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Window MouseLeftButtonDown event" -showtime -catcherror $_
        }
    })
    #$synchash.MiniPlayer_DockPanel.Remove_MouseLeftButtonDown({})
    $synchash.MiniPlayer_DockPanel.add_MouseLeftButtonDown({
        Param($Sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        try{
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
          {
            $synchash.MiniPlayer_Viewer.DragMove()
            $e.handled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Window MouseLeftButtonDown event" -showtime -catcherror $_
        }
    })
    $synchash.MiniPlayer_Viewer.Add_SizeChanged({
        Param($Sender,[System.Windows.SizeChangedEventArgs]$e)
        try{     
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> MiniPlayer_Viewer sized changed from $($e.PreviousSize) to $($e.NewSize)" -Dev_mode}
          if(-not [string]::IsNullOrEmpty($synchash.MiniDisplayPanel_Title_TextBlock.Text)){
            $CurrentMiniDisplayScreenWidth = $synchash.TrayPlayer_Background_TileGrid.ActualWidth + 327
            if($thisApp.Config.Dev_mode){write-ezlogs "| Checking mini display screen current size: $CurrentMiniDisplayScreenWidth - miniSlideText_StackPanel width: $($synchash.miniSlideText_StackPanel.ActualWidth)" -Dev_mode}
            if($synchash.miniDisplayPanel_Storyboard -and $synchash.miniSlideText_StackPanel.ActualWidth -gt $CurrentMiniDisplayScreenWidth){              
              $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
              if(!$target){
                $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
              }
              if($thisApp.Config.Dev_mode){write-ezlogs "| Checking if current media is playing and not paused" -Dev_mode}
              if($synchash.Current_playing_media.id -and !$synchash.PauseButton_ToggleButton.isChecked){
                if($thisApp.Config.Dev_mode){write-ezlogs "| Starting Miniplayer storyboard" -Dev_mode}
                $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $synchash.MiniDisplayPanel_Storyboard.Storyboard.AutoReverse = $false
                if($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){
                  $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,5)
                }else{
                  $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,$null)
                }
                $synchash.MiniDisplayPanel_Storyboard.Storyboard.Begin()
              }
            }elseif($synchash.miniDisplayPanel_Storyboard -and $synchash.Current_playing_media.id){
              $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
              if(!$target){
                $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
              }
              if($thisApp.Config.Dev_mode){write-ezlogs "| Stopping Miniplayer storyboard" -Dev_mode}
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::new(0)
              $synchash.MiniDisplayPanel_Storyboard.Storyboard.Stop()
            }
          }
        }catch{
          write-ezlogs "An exception occurred in TrayPlayerPopUpGrid.Add_SizeChanged event" -CatchError $_ -showtime
        }  
    })

    
    #$synchash.MiniPlayer_Viewer.Remove_Loaded({})
    if(!$Synchash.MiniPlayer_LoadedScriptblock){
      $Synchash.MiniPlayer_LoadedScriptblock = {
        Param($Sender)
        try{
          write-ezlogs ">>>> Miniplayer has loaded - topmost: $($thisApp.Config.Mini_Always_On_Top)"
          if($thisApp.Config.Mini_Always_On_Top){
            $synchash.MiniPlayer_Viewer.TopMost = $true
            $synchash.StayOnTopButton_ToggleButton.isChecked = $true
          }else{            
            $synchash.MiniPlayer_Viewer.TopMost = $false
            $synchash.StayOnTopButton_ToggleButton.isChecked = $false
          }       
          #Register window to installed application ID 
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($Sender)
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
            $thisapp.config.Installed_AppID = $appid
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Registering Miniplayer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode}
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)   
          }
          if($thisApp.Config.Remember_Window_Positions){
            $synchash.MiniPlayer_Viewer.SaveWindowPosition = $true
            if(-not [string]::IsNullOrEmpty($thisApp.Config.MiniWindow_Top) -and $thisApp.Config.MiniWindow_Top -ge 0 -and -not [string]::IsNullOrEmpty($thisApp.Config.MiniWindow_Left)){
              $synchash.MiniPlayer_Viewer.Top = $thisApp.Config.MiniWindow_Top
              $synchash.MiniPlayer_Viewer.Left = $thisApp.Config.MiniWindow_Left
            }
          }
          <#          if((!$synchash.MediaViewAnchorable.isFloating -and !$synchash.Window.isVisible)  -and $synchash.VideoView -and !$synchash.MainWindow_IsClosing){
              write-ezlogs "| Hiding video view as video player is not floating and main player is not visible due to miniplayer being open"
              $synchash.VideoView.Visibility = 'Hidden'
          }#>
        }catch{
          write-ezlogs "An exception occurred in MiniPlayer_Viewer.add_Loaded" -showtime -catcherror $_
        }  
      }
    }
    if(!$Synchash.MiniPlayer_ClosingScriptblock){
      $Synchash.MiniPlayer_ClosingScriptblock = {
        param($sender)
        try{
          [void][System.Windows.Input.FocusManager]::SetFocusedElement([System.Windows.Input.FocusManager]::GetFocusScope($synchash.MiniPlayer_Viewer),$Null)
          [void][System.Windows.Input.Keyboard]::ClearFocus()
          if($thisApp.Config.Remember_Window_Positions){
            write-ezlogs ">>>> Miniplayer is closing, saving top: $($synchash.MiniPlayer_Viewer.Top) -- Left: $($synchash.MiniPlayer_Viewer.Left)"
            $thisapp.config.MiniWindow_Top = $synchash.MiniPlayer_Viewer.Top
            $thisapp.config.MiniWindow_Left = $synchash.MiniPlayer_Viewer.Left
          }
          if($synchash.MiniPlayer_DockPanel.children -contains $synchash.TrayPlayerBorder){
            $null = $synchash.MiniPlayer_DockPanel.children.Remove($synchash.TrayPlayerBorder)
          }
          $synchash.StayOnTopButton_ToggleButton.isChecked = $false
          $synchash.StayOnTopButton_ToggleButton.ToolTip = 'Detach MiniPlayer'
          if($synchash.TrayPlayerPopUpGrid.children -notcontains $synchash.TrayPlayerBorder){
            $synchash.TrayPlayerPopUpGrid.children.add($synchash.TrayPlayerBorder)
          } 
          $synchash.TrayPlayer.PopupActivation = 'LeftClick'
        }catch{
          write-ezlogs "An exception occurred in MiniPlayer_Viewer.add_closing" -showtime -catcherror $_
        } 
      }
    }  
    if(!$Synchash.MiniPlayer_ClosedScriptblock){
      $Synchash.MiniPlayer_ClosedScriptblock = {
        param($sender)
        try{
          write-ezlogs ">>>> Miniplayer window has closed"
          if($synchash.Window.isInitialized){
            $synchash.window.Opacity = 1            
            $synchash.window.ShowActivated = $true
            $synchash.Window.ShowInTaskbar = $true
            $synchash.Window.show()
            $synchash.Window.Activate()
          }
          if($synchash.VideoViewAirControl.Visibility -in 'Hidden','Collapsed'){
            write-ezlogs "| Unhiding VideoViewAirControl"
            $synchash.VideoViewAirControl.Visibility = 'Visible'
          }
        }catch{
          write-ezlogs "An exception occurred in MiniPlayer_Viewer.add_closed" -showtime -catcherror $_
        }
      }
    }
    if(!$Synchash.MiniPlayer_UnLoadedScriptblock){
      $Synchash.MiniPlayer_UnLoadedScriptblock = {
        param($sender)
        try{
          write-ezlogs ">>>> Miniplayer window has unloaded"
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::PreviewGotKeyboardFocusEvent) -RemoveHandlers -VerboseLog:$($thisApp.Config.Dev_mode)
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::SizeChangedEvent) -RemoveHandlers -VerboseLog:$($thisApp.Config.Dev_mode)
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::PreviewGotKeyboardFocusEvent) -RemoveHandlers -VerboseLog:$($thisApp.Config.Dev_mode)
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::loadedEvent) -RemoveHandlers -VerboseLog:$($thisApp.Config.Dev_mode)
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::UnloadedEvent) -RemoveHandlers -VerboseLog:$($thisApp.Config.Dev_mode)        
          [void][System.Windows.Data.BindingOperations]::ClearAllBindings($synchash.TaskbarItem_PlayButton)
          [void][System.Windows.Data.BindingOperations]::ClearAllBindings($synchash.Mini_TaskbarItem_StopButton)         
          $synchash.MiniPlayer_Viewer.Remove_closing($Synchash.MiniPlayer_ClosingScriptblock)
          $synchash.MiniPlayer_Viewer.Remove_closed($Synchash.MiniPlayer_ClosedScriptblock)
          $synchash.MiniPlayer_Viewer = $Null
          if($synchash.Window.isVisible -and $synchash.VideoView.Visibility -in 'Hidden','Collapsed' -and (!$synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio) -and $synchash.WebPlayer_State -eq 0 -and !$synchash.Youtube_WebPlayer_title){
            write-ezlogs ">>>> Video view is hidden, Youtube webplayer not playing, unhiding video view" -Warning
            $synchash.VideoView.Visibility = 'Visible'
          } 
        }catch{
          write-ezlogs "An exception occurred in MiniPlayer_Viewer unloaded event" -showtime -catcherror $_
        }  
      }
    }     
    $synchash.MiniPlayer_Viewer.add_Loaded($Synchash.MiniPlayer_LoadedScriptblock)
    $synchash.MiniPlayer_Viewer.add_UnLoaded($Synchash.MiniPlayer_UnLoadedScriptblock)
    $synchash.MiniPlayer_Viewer.add_closing($Synchash.MiniPlayer_ClosingScriptblock)
    $synchash.MiniPlayer_Viewer.add_closed($Synchash.MiniPlayer_ClosedScriptblock)    
    <#    $synchash.MiniPlayer_Viewer.add_Activated({
        try{
        write-ezlogs ">>>> Miniplayer Viewer activated"
        if($synchash.VideoView_Grid.Parent.Parent.isActive){
        write-ezlogs "Video View content window is active $($synchash.VideoView_Grid.Parent.Parent | out-string)" -warning
        }
        }catch{
        write-ezlogs "An exception occurred in MiniPlayer_Viewer.add_closed" -showtime -catcherror $_
        }
    })#>

    
    if($synchash.TrayPlayerFlyout){
      $synchash.TrayPlayerFlyout.isOpen = $true
    } 
    if(!$synchash.MediaViewAnchorable.isfloating -and $synchash.VideoView.Visibility -eq 'Visible'){
      write-ezlogs "Video Player is not floating, collapsing Video View while Miniplayer visible" -warning
      $synchash.VideoView.Visibility = 'Hidden'
      if($synchash.chat_WebView2.isVisible -or $synchash.Comments_Grid.Visibility -ne 'Collapsed'){
        write-ezlogs "| Hiding chat view" -warning
        Update-ChatView -synchash $synchash -thisApp $thisApp -hide
      }
    } 
    if(!$synchash.MediaViewAnchorable.isfloating -and $synchash.VideoViewAirControl.Visibility -eq 'Visible'){
      write-ezlogs "| hiding VideoViewAirControl"
      $synchash.VideoViewAirControl.Visibility = 'Collapsed'
    }
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Hide
    $synchash.MiniPlayer_Viewer.Show()
    $synchash.MiniPlayer_Viewer.Activate()
  }catch{
    write-ezlogs 'An exception occurred in Open-MiniPlayer' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Open-MiniPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-MainPlayer Function
#----------------------------------------------
function Update-MainPlayer {
  Param (
    $synchash,
    $thisApp,
    [string]$Saved_Media_Progress,
    [switch]$Show,
    [switch]$Hide,
    [switch]$Live_stream,
    [string]$TopMost,
    [string]$video_url,
    [string]$vlcurl,
    [string]$media_link,
    $memory_stream,
    $SponserBlock,
    [string]$audio_url,
    [string]$Subtitles_Path,
    [switch]$close,
    [switch]$screenshot,
    [switch]$startHidden,
    [string]$DisplayPanel_Bitrate,
    [switch]$Clear_DisplayPanel_Bitrate,
    [Switch]$Start_media_Timer,
    [switch]$Remove_VideoView,
    [switch]$Add_VideoView,
    [switch]$start_Paused,
    [switch]$EnableCasting,
    [switch]$Stoplibvlc,
    [string]$Now_Playing_Label,
    [switch]$Clear_Now_Playing_Label,
    [string]$Now_Playing_Artist,
    [switch]$Clear_Now_Playing_Artist,
    [string]$Now_Playing_Title,
    [switch]$Clear_Now_Playing_Title,
    [string]$Visibility,
    [switch]$New_MediaPlayer,
    [int]$delay,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.MainPlayer_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $synchash.MainPlayer_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.MainPlayer_Update_Timer.add_tick({
          try{  
            $MainPlayer_Update_Measure =[system.diagnostics.stopwatch]::StartNew()
            $synchash = $synchash
            $thisApp = $thisApp
            $object = @{}
            $Process = $synchash.MainPlayer_UpdateQueue.TryDequeue([ref]$object)                             
            if($Process -and $object.ProcessObject){
              if($thisApp.Config.Dev_mode){write-ezlogs "[UPDATE-MAINPLAYER] >>>> Updating MainPlayer" -Dev_mode -logtype Libvlc}
              if(-not [string]::IsNullOrEmpty($object.Visibility)){
                $synchash.Window.Visibility = $object.Visibility 
              }   
              if($object.Show){
                $synchash.window.ShowActivated = $true
                $synchash.window.Opacity = 1
                $synchash.window.ShowInTaskbar = $true
                $synchash.Window.show()
                $synchash.Window.Activate() 
              }
              if($object.Hide){
                if($synchash.MiniPlayer_Viewer){
                  $synchash.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
                  $synchash.window.Opacity = 0
                  $synchash.window.ShowInTaskbar = $false
                }else{
                  $synchash.Window.Hide()
                }
              }  
              if($object.Close){
                $synchash.Window.Close() 
              }
              if(-not [string]::IsNullOrEmpty($object.TopMost)){
                $synchash.Window.TopMost = $object.TopMost
              }  
              if(-not [string]::IsNullOrEmpty($object.Now_Playing_Label)){
                $synchash.Now_Playing_Label.DataContext = $object.Now_Playing_Label
                $synchash.Now_Playing_Label.Visibility = 'Visible'             
              } 
              if($object.Clear_Now_Playing_Label){
                $synchash.Now_Playing_Label.DataContext = 'PLAYING'
                $synchash.Now_Playing_Label.Visibility = 'Hidden'
              }
              if($object.Clear_Now_Playing_Title){
                $synchash.Now_Playing_Title_Label.DataContext = ''
              }
              if(-not [string]::IsNullOrEmpty($object.Now_Playing_Title)){
                write-ezlogs "[UPDATE-MAINPLAYER] >>>> Setting Now Playing Title Label: $($object.Now_Playing_Title)" -loglevel 2
                $synchash.Now_Playing_Title_Label.DataContext = $object.Now_Playing_Title
              } 
              if(-not [string]::IsNullOrEmpty($object.Now_Playing_Artist)){
                write-ezlogs "[UPDATE-MAINPLAYER] >>>> Setting Now Playing Artist Label: $($object.Now_Playing_Artist)" -loglevel 2
                $synchash.Now_Playing_Artist_Label.DataContext = $object.Now_Playing_Artist
              }
              if($object.Clear_Now_Playing_Artist){
                $synchash.Now_Playing_Artist_Label.DataContext = ''
              }             
              <#              if(-not [string]::IsNullOrEmpty($object.DisplayPanel_Bitrate)){
                  $synchash.DisplayPanel_Bitrate_TextBlock.text = $object.DisplayPanel_Bitrate
                  $synchash.DisplayPanel_Sep3_Label.Visibility = 'Visible'
              }#>
              if($object.Clear_DisplayPanel_Bitrate -and $synchash.DisplayPanel_Bitrate_TextBlock){
                $synchash.DisplayPanel_Bitrate_TextBlock.text = ''
                $synchash.DisplayPanel_Sep3_Label.Visibility = 'Hidden'
              }    
              if($object.Add_VideoView -and $synchash.VideoView){
                if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
                  write-ezlogs "[UPDATE-MAINPLAYER] Adding VideoView to Vlc_Grid" -showtime -logtype Libvlc
                  $null = $synchash.VLC_Grid.children.add($synchash.VideoView)                
                }
              }
              if($object.Remove_VideoView -and $synchash.VideoView){
                if($synchash.VLC_Grid.children.name -contains 'VideoView'){
                  write-ezlogs "[UPDATE-MAINPLAYER] Removing VideoView from Vlc_Grid" -showtime -logtype Libvlc
                  $null = $synchash.VLC_Grid.children.Remove($synchash.VideoView)
                }
              }
              if($object.Stoplibvlc -and $synchash.libvlc){
                if($synchash.vlc.isPlaying){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Stopping existing vlc session" -warning -logtype Libvlc
                  $synchash.VLC_IsPlaying_State = $false
                  $synchash.vlc.stop()
                }
                Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp -UnregisterOnly
                if($synchash.vlc.media -is [System.IDisposable]){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Disposing existing vlc.media" -logtype Libvlc
                  $synchash.vlc.media.dispose()
                  $synchash.vlc.media = $Null
                }
                if($synchash.VideoView.MediaPlayer.media -is [System.IDisposable]){
                  $synchash.VideoView.MediaPlayer.media.dispose()
                  $synchash.VideoView.MediaPlayer.media = $Null
                }
                if($synchash.vlc -is [System.IDisposable]){                  
                  write-ezlogs "[UPDATE-MAINPLAYER] | Disposing existing vlc session" -warning -logtype Libvlc
                  $synchash.vlc.dispose()
                  $synchash.vlc = $Null
                  $synchash.VideoView.MediaPlayer = $Null
                }
                $this.Stop()
                return    
              }
              if($object.New_MediaPlayer -and $synchash.libvlc){
                if($synchash.vlc.isPlaying){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Stopping existing vlc session" -warning -logtype Libvlc
                  $synchash.VLC_IsPlaying_State = $false
                  $synchash.vlc.stop()
                }
                Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp -UnregisterOnly
                if($synchash.vlc.media -is [System.IDisposable]){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Disposing existing vlc.media" -logtype Libvlc
                  $synchash.vlc.media.dispose()
                  $synchash.vlc.media = $Null
                }
                if($synchash.VideoView.MediaPlayer.media -is [System.IDisposable]){
                  $synchash.VideoView.MediaPlayer.media.dispose()
                  $synchash.VideoView.MediaPlayer.media = $Null
                }
                if(!$synchash.vlc){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Creating new vlc mediaplayer session" -warning -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.VLC = [LibVLCSharp.MediaPlayer]::new($synchash.libvlc)
                  }else{
                    $synchash.VLC = [LibVLCSharp.Shared.MediaPlayer]::new($synchash.libvlc)
                  }
                  $synchash.VideoView.MediaPlayer = $synchash.VLC
                  Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp
                }else{
                  write-ezlogs "[UPDATE-MAINPLAYER] | Using existing vlc mediaplayer session" -logtype Libvlc
                }
                if($thisapp.config.Current_Audio_Output -and $synchash.vlc.AudioOutputDeviceEnum){
                  $device = $synchash.vlc.AudioOutputDeviceEnum.where({$_.Description -eq $thisapp.config.Current_Audio_Output})
                  if($device.Description -ne 'Default'){
                    write-ezlogs "[UPDATE-MAINPLAYER] >>>> Setting Audio Output device: $($device.Description)" -showtime -logtype Libvlc
                    $synchash.vlc.SetOutputDevice($device.deviceidentifier)
                  }     
                }
                if($object.delay){
                  $synchash.vlc.SetAudioDelay(-2000000)
                }
                if($object.memory_stream){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Creating libvlc media from memory stream $($object.memory_stream)" -showtime -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.VLC.Media = [LibVLCSharp.Media]::new([Uri]($object.memory_stream),[LibVLCSharp.FromType]::FromLocation,$null)
                  }else{
                    $synchash.VLC.Media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($object.memory_stream),[LibVLCSharp.Shared.FromType]::FromLocation,$null) 
                  }            
                }elseif($object.video_url -and $object.audio_url){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Set video url $($object.video_url)" -showtime -logtype Libvlc
                  write-ezlogs "[UPDATE-MAINPLAYER] | Set Audio URL input-slave: $($object.audio_url)" -showtime -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseNetwork
                    $synchash.VLC.Media = [LibVLCSharp.Media]::new([Uri]($object.video_url),[LibVLCSharp.FromType]::FromLocation,":input-slave=$($object.audio_url)")
                    [void]$synchash.VLC.Media.AddSlave([LibVLCSharp.MediaSlaveType]::Audio,1,$($object.audio_url))
                  }else{
                    $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork 
                    $synchash.VLC.Media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($object.video_url),[LibVLCSharp.Shared.FromType]::FromLocation,":input-slave=$($object.audio_url)")
                    [void]$synchash.VLC.Media.AddSlave([LibVLCSharp.Shared.MediaSlaveType]::Audio,1,$($object.audio_url))
                  } 
                  if($thisApp.Config.Dev_mode){write-ezlogs "[UPDATE-MAINPLAYER] | Parsed libvlc_media: $($synchash.VLC.Media | out-string)" -showtime -logtype Libvlc -Dev_mode}   
                }elseif($object.vlcurl -or $object.media_link){
                  if($object.media_link){
                    if([System.IO.File]::Exists($object.media_link)){
                      write-ezlogs "[UPDATE-MAINPLAYER] | Medialink is local path link $($object.media_link)" -showtime -logtype Libvlc                      
                      if($thisApp.Config.Libvlc_Version -eq '4'){
                        $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseLocal
                        $from_path = [LibVLCSharp.FromType]::FromPath
                      }else{
                        $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseLocal
                        $from_path = [LibVLCSharp.Shared.FromType]::FromPath
                      }                               
                    }else{
                      write-ezlogs "[UPDATE-MAINPLAYER] | Medialink is URL link $($object.media_link)" -showtime -logtype Libvlc                      
                      if($thisApp.Config.Libvlc_Version -eq '4'){
                        $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseNetwork
                        $from_path = [LibVLCSharp.FromType]::FromLocation
                      }else{
                        $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork
                        $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
                      } 
                    } 
                    if($thisApp.Config.Libvlc_Version -eq '4'){
                      $synchash.VLC.Media = [LibVLCSharp.Media]::new([Uri]($object.media_link),$from_path,$null)
                    }else{
                      $synchash.VLC.Media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($object.media_link),$from_path,$null) 
                    }                                   
                  }else{
                    if($object.vlcurl){
                      write-ezlogs "[UPDATE-MAINPLAYER] | vlcurl is URL link $($object.vlcurl)" -showtime -logtype Libvlc
                      if($thisApp.Config.Libvlc_Version -eq '4'){
                        $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseNetwork
                        $from_path = [LibVLCSharp.FromType]::FromLocation
                      }else{
                        $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork
                        $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
                      } 
                    }else{
                      write-ezlogs "[UPDATE-MAINPLAYER] | vlcurl is local path link $($object.vlcurl)" -showtime -logtype Libvlc
                      
                      if($thisApp.Config.Libvlc_Version -eq '4'){
                        $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseLocal
                        $from_path = [LibVLCSharp.FromType]::FromPath
                      }else{
                        $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseLocal
                        $from_path = [LibVLCSharp.Shared.FromType]::FromPath
                      }
                    }            
                    if($thisApp.Config.Libvlc_Version -eq '4'){
                      $synchash.VLC.Media = [LibVLCSharp.Media]::new([Uri]($object.vlcurl),$from_path,$null)
                    }else{
                      $synchash.VLC.Media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($object.vlcurl),$from_path,$null)
                    }
                  }
                }               
                if(!$thisApp.Config.Use_HardwareAcceleration){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Disabling Hardware Acceleration" -showtime -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":avcodec-hw=none")
                  $synchash.vlc.EnableHardwareDecoding = $false
                }else{
                  #$synchash.VLC.Media.AddOption(":avcodec-hw=any")
                  #$synchash.VLC.Media.AddOption(":avcodec-hw=dxva2")
                  $synchash.vlc.EnableHardwareDecoding = $true
                } 
                
                #$synchash.VLC.Media.AddOption("--glconv=any")
                #$synchash.VLC.Media.AddOption("--tone-mapping=2")
                #$synchash.VLC.Media.AddOption(":gl=any")
                if($thisApp.Config.Enable_EQ -and $([string]$synchash.VLC.Media.Mrl).StartsWith("dshow://")){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Enabling dshow capture for virtual audio cable -- dshow-vdev=none -- dshow-adev=CABLE Output (VB-Audio Virtual Cable)" -Warning -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":dshow-vdev=none")
                  $synchash.VLC.Media.AddOption(":dshow-adev=CABLE Output (VB-Audio Virtual Cable)")
                  $synchash.VLC.Media.AddOption(":live-caching=1")
                  $synchash.VLC.Media.AddOption(":clock-synchro=0")
                  #$synchash.VLC.Media.AddOption(":avcodec-fast")
                }elseif((Test-ValidPath ([uri]$object.vlcurl).LocalPath -Type File)){
                  try{
                    write-ezlogs "[UPDATE-MAINPLAYER] | Set FileCaching to 1000" -showtime -logtype Libvlc
                    $synchash.vlc.FileCaching = 1000
                    if(([uri]$object.vlcurl).LocalPath.StartsWith("\\") -or [system.io.driveinfo]::new(([uri]$object.vlcurl).LocalPath).DriveType -eq 'Network'){
                      if($thisapp.config.vlc_Arguments -notmatch 'network-caching='){
                        write-ezlogs "[UPDATE-MAINPLAYER] | File appears to be located on a network drive/share  - setting network-caching=1500" -logtype Libvlc
                        $synchash.VLC.Media.AddOption(":network-caching=1500")
                        $synchash.vlc.NetworkCaching = 1500
                      }else{
                        write-ezlogs "[UPDATE-MAINPLAYER] | File appears to be located on a network drive/share. Not adjusting cachea as found custom network-caching setting within vlc_Arguments: $($thisapp.config.vlc_Arguments)" -logtype Libvlc
                      }
                    }             
                  }catch{
                    write-ezlogs "[UPDATE-MAINPLAYER] An exception occurred processing file path type for libvlc $($object.vlcurl | out-string)" -catcherror $_
                  }
                }elseif(([uri]$object.vlcurl).LocalPath -eq ([uri]$synchash.streamlink_HTTP_URL).LocalPath -and $object.Live_stream){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Live_Stream: Set clock-jitter and clock-synchro to 0, Network Cache to 1000, rtsp-tcp, and live cache to 500" -showtime -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":clock-jitter=0")
                  $synchash.VLC.Media.AddOption(":clock-synchro=0")
                  $synchash.VLC.Media.AddOption(":live-caching=500")
                  $synchash.VLC.Media.AddOption(":rtsp-tcp")
                  $synchash.vlc.NetworkCaching = 1000
                  $synchash.VLC.Media.AddOption(":network-caching=1000")
                }elseif(([uri]$object.vlcurl).LocalPath -eq ([uri]$synchash.streamlink_HTTP_URL).LocalPath){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Set Network-caching to 1000" -showtime -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":network-caching=1000")
                  $synchash.vlc.NetworkCaching = 1000
                }elseif((Test-URL $object.vlcurl)){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Set Network-caching to 500" -showtime -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":network-caching=500")
                  $synchash.vlc.NetworkCaching = 500
                }elseif(($object.video_url -and $object.audio_url)){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Set Network-caching to 1000" -showtime -logtype Libvlc
                  $synchash.VLC.Media.AddOption(":network-caching=1000")
                  $synchash.vlc.NetworkCaching = 1000
                }
                #TODO: POTENTIAL FEATURE - SCREEN RECORDING
                if($screenrecorder){
                  $synchash.VLC.Media.AddOption(":screen-fps=30")
                  $synchash.VLC.Media.AddOption(":sout=#transcode{vcodec=h264,vb=0,scale=0,acodec=mp4a,ab=128,channels=2,samplerate=44100}:file{dst=c:\test\record.mp4}")
                  $synchash.VLC.Media.AddOption(":sout-keep")
                }
                if($thisApp.Config.Use_MediaCasting -and $object.EnableCasting){
                  if(-not [string]::IsNullOrEmpty($thisapp.config.Cast_HTTPPort)){
                    $CastPort = $thisapp.config.Cast_HTTPPort
                  }else{
                    $CastPort = '8080'
                  }     
                  if($thisApp.Config.Dev_mode){write-ezlogs "[UPDATE-MAINPLAYER] ##### Setting option for casting: #transcode{acodec=mp4a,ab=256,channels=2,samplerate=44100,scodec=none}:duplicate{dst=http{mux=ffmpeg{mux=flv},dst=:$CastPort/},dst=display}" -Dev_mode -logtype Libvlc}
                  $synchash.VLC.Media.AddOption(":sout=#transcode{acodec=mp4a,ab=256,channels=2,samplerate=44100,scodec=none}:duplicate{dst=http{mux=ffmpeg{mux=flv},dst=:$CastPort/},dst=display}");        
                  $synchash.VLC.Media.AddOption(":sout-display")
                  $synchash.VLC.Media.AddOption(":sout-all")
                  $synchash.VLC.Media.AddOption(":sout-keep")
                }else{
                  if($thisApp.Config.Dev_mode){write-ezlogs "[UPDATE-MAINPLAYER] Not enabling casting -- Use_MediaCasting: $($thisApp.Config.Use_MediaCasting) -- tag.EnableCasting: $($object.EnableCasting)" -Dev_mode -logtype Libvlc}
                }

                #Subtitles 
                if(-not [string]::IsNullOrEmpty($object.Subtitles_Path)){
                  if([system.io.file]::Exists($object.Subtitles_Path)){
                    $Subtitles = $synchash.VLC.Media.AddSlave([LibVLCSharp.Shared.MediaSlaveType]::Subtitle,1,$object.Subtitles_Path)
                    if($Subtitles){
                      write-ezlogs "[UPDATE-MAINPLAYER] Loaded Subtitles: $($object.Subtitles_Path)" -logtype Libvlc -Success
                      try{
                        Update-Subtitles -synchash $synchash -thisApp $thisApp -clear
                        Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
                      }catch{
                        write-ezlogs "An exception occurred in Update-Subtitles -clear" -catcherror $_
                      }
                    }else{
                      write-ezlogs "[UPDATE-MAINPLAYER] Loading subtitles not successful for path: $($object.Subtitles_Path)" -logtype Libvlc -warning
                    }
                  }else{
                    write-ezlogs "[UPDATE-MAINPLAYER] Unable to find subtitle file $($object.Subtitles_Path)" -logtype Libvlc -warning
                  }  
                } 
                write-ezlogs "[UPDATE-MAINPLAYER] | VLC Media URL to play: $($synchash.VLC.Media.Mrl)" -logtype Libvlc
                if(-not [string]::IsNullOrEmpty($thisApp.Config.Audio_OutputModule)){
                  Write-ezlogs "[UPDATE-MAINPLAYER] | Setting Audio Output module to: $($thisApp.Config.Audio_OutputModule)" -logtype Libvlc -loglevel 2
                  $setouput = $synchash.vlc.SetAudioOutput($thisApp.Config.Audio_OutputModule)
                }                         
                if($setouput){
                  Write-ezlogs "[UPDATE-MAINPLAYER] | Successfully set audio output module to $($thisApp.Config.Audio_OutputModule)" -logtype Libvlc -loglevel 2
                }elseif($thisApp.Config.Audio_OutputModule){
                  Write-ezlogs "[UPDATE-MAINPLAYER] | Failed to set audio output module to '$($thisApp.Config.Audio_OutputModule)'" -logtype Libvlc -loglevel 2 -Warning
                }                                           
                if($object.start_Paused){
                  write-ezlogs "[UPDATE-MAINPLAYER] Starting VLC playback as paused" -warning -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $null = $synchash.vlc.media.parseasync($synchash.libvlc,$ParseOption)
                  }else{
                    $null = $synchash.vlc.media.parse($ParseOption)
                  }                 
                  $Null = $synchash.vlc.stop()
                  $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying
                  Pause-Media -thisApp $thisApp -synchash $synchash -start_Paused
                }else{
                  write-ezlogs "[UPDATE-MAINPLAYER] >>>> Starting VLC Playback" -logtype Libvlc
                  $null = $synchash.VLC.Play()
                  $synchash.VLC_IsPlaying_State = $synchash.Vlc.State -eq 'Playing' -or $synchash.vlc.isPlaying -or $synchash.vlc.media.state -eq 'Playing'
                  if($thisApp.Config.Dev_mode){write-ezlogs "[UPDATE-MAINPLAYER] VLC Playback $($synchash.VLC | out-string)" -logtype Libvlc -Dev_mode}
                }
                if($thisApp.Config.Remember_Playback_Progress -and -not [string]::IsNullOrEmpty($object.Saved_Media_Progress)){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Saved Progress: $($object.Saved_Media_Progress)" -logtype Libvlc -warning
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.VLC.setTime($object.Saved_Media_Progress)
                  }else{
                    $synchash.VLC.Time = $object.Saved_Media_Progress
                  }
                }
                #Set Volume
                if(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
                  $thisapp.Config.Media_Volume = $synchash.Volume_Slider.value
                  if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
                    write-ezlogs "[UPDATE-MAINPLAYER] | Setting vlc volume to Volume_Slider Value: $($synchash.Volume_Slider.value)" -logtype Libvlc
                    if($thisApp.Config.Libvlc_Version -eq '4'){
                      $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
                    }else{
                      $synchash.vlc.Volume = $synchash.Volume_Slider.value
                    }
                  }         
                }elseif(-not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume) -and $synchash.vlc -and $synchash.vlc.Volume -ne $thisapp.Config.Media_Volume){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Setting vlc volume to Config Media Volume: $($thisapp.Config.Media_Volume)" -logtype Libvlc
                  $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.vlc.SetVolume($thisapp.Config.Media_Volume)
                  }else{
                    $synchash.vlc.Volume = $thisapp.Config.Media_Volume
                  }
                }else{
                  write-ezlogs "[UPDATE-MAINPLAYER] | Volume level unknown??: $($synchash.Volume_Slider.value)" -logtype Libvlc -Warning
                  $thisapp.Config.Media_Volume = 50
                }
                if($thisapp.config.Enable_EQ -and $synchash.vlc -and !$synchash.EQ_Timer.isEnabled){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Executing EQ_Timer" -showtime -loglevel 2 -logtype Libvlc
                  $synchash.EQ_Timer.Start()
                }
                if($object.Start_media_Timer){
                  write-ezlogs "[UPDATE-MAINPLAYER] | Starting Media Timer" -loglevel 2
                  $null = $synchash.timer.Start()
                }
              }
              if($object.SponserBlock.type -eq 'skip'){
                try{
                  $null = $synchash.Timer.stop()
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseNetwork
                    if($synchash.vlc.media.ParsedStatus -ne 'Done'){
                      write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Parsing current vlc media" -loglevel 2 -warning
                      $null = $synchash.vlc.media.parseasync($synchash.libvlc,$ParseOption)                
                    }  
                  }else{
                    $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork
                    #$null = $synchash.VLC.Pause()  
                    if(!$synchash.vlc.media.IsParsed){
                      write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Parsing current vlc media" -loglevel 2 -warning
                      $null = $synchash.vlc.media.parse($ParseOption)                
                    }  
                  }                   
                  $Sponserblock = $object.SponserBlock | Select-Object -first 1
                  write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Skipping sponser from start_time: $($Sponserblock.start_time) to end_time: $($Sponserblock.end_time)" -loglevel 2 -warning
                  $Time = [timespan]::FromSeconds($Sponserblock.end_time)
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.VLC.SeekTo($time)
                    write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Seeking vlc 4 to: $($time.TotalMilliseconds)" -loglevel 2 -warning
                  }else{
                    write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Seeking vlc to: $($time.TotalSeconds)" -loglevel 2 -warning               
                    $synchash.VLC.SeekTo($time)
                  } 
                  if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Duration)){
                    if($synchash.Current_playing_media.Duration -match '\:'){
                      $total_Seconds = [timespan]::Parse($synchash.Current_playing_media.Duration).TotalSeconds
                      [int]$hrs = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Hours)
                      [int]$mins = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Minutes)
                      [int]$secs = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Seconds)
                    }else{
                      $total_Seconds = $([timespan]::FromMilliseconds($synchash.Current_playing_media.Duration)).TotalSeconds
                      [int]$a = $($synchash.Current_playing_media.Duration / 1000)
                      [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                      [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                      [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                    }
                    $synchash.MediaPlayer_TotalDuration = $total_seconds
                    if($hrs -lt 1){
                      $hrs = '0'
                    }
                    $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
                    $synchash.MediaPlayer_CurrentDuration = $total_time
                  }else{
                    $total_time = $synchash.MediaPlayer_CurrentDuration       
                  } 
                  [int]$hrs = $($time.Hours)
                  [int]$mins = $($time.Minutes)
                  [int]$secs = $($time.Seconds)                        
                  if($hrs -lt 1){
                    $hrs = '0'
                  }
                  $current_Length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
                  if($synchash.VideoView_Current_Length_TextBox){
                    $synchash.VideoView_Current_Length_TextBox.text = $current_Length
                  }
                  if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
                    $synchash.VideoView_Total_Length_TextBox.text = $total_time
                  }
                  if($synchash.Media_Current_Length_TextBox -and $synchash.Media_Current_Length_TextBox.DataContext -ne $current_Length){
                    $synchash.Media_Current_Length_TextBox.DataContext = $current_Length
                  }
                  if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.DataContext -ne $total_time){
                    $synchash.Media_Total_Length_TextBox.DataContext = $total_time
                  }
                  if($synchash.MiniPlayer_Media_Length_Label -and $synchash.MiniPlayer_Media_Length_Label.Content -ne $current_Length){
                    $synchash.MiniPlayer_Media_Length_Label.Content = $current_Length
                  }                             
                }catch{
                  write-ezlogs "An exception occurred setting VLC time for sponsperblock: $($object.SponserBlock | out-string)" -catcherror $_
                }finally{
                  write-ezlogs "[UPDATE-MAINPLAYER] | SPONSERBLOCK - Resuming play" -loglevel 2 -warning
                  $null = $synchash.VLC.Play()
                }
              }                                                                                                   
              if($object.screenshot){
                $synchash.Window.TopMost = $object.TopMost
                $synchash.Window.Activate() 
                start-sleep -Milliseconds 500
                write-ezlogs ">>>> Taking Snapshot of Main window" -loglevel 2
                $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$synchash.Window)
                $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
                $synchash.SnapshotPoint = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)
              }                              
              $this.Stop()
            }else{
              $this.Stop()
            }            
          }catch{
            write-ezlogs "An exception occurred in Settings_Update_Timer.add_tick" -showtime -catcherror $_
            $this.Stop()
          }finally{
            if($MainPlayer_Update_Measure){
              $MainPlayer_Update_Measure.stop()
              write-ezlogs "Update-MainPlayer Measure" -PerfTimer $MainPlayer_Update_Measure
              $MainPlayer_Update_Measure = $Null
            }
            $this.Stop()
          }
      }) 
    }else{
      [void]$synchash.MainPlayer_UpdateQueue.Enqueue([PSCustomObject]::new(@{
            'Now_Playing_Label' = $Now_Playing_Label
            'Clear_Now_Playing_Label' = $Clear_Now_Playing_Label
            'DisplayPanel_Bitrate' = $DisplayPanel_Bitrate
            'Clear_DisplayPanel_Bitrate' = $Clear_DisplayPanel_Bitrate
            'TopMost' = $TopMost
            'delay' = $delay
            'memory_stream' = $memory_stream
            'ProcessObject' = $true
            'Start_media_Timer' = $Start_media_Timer
            'Saved_Media_Progress' = $Saved_Media_Progress
            'start_Paused' = $start_Paused
            'Stoplibvlc' = $Stoplibvlc
            'Subtitles_Path' = $Subtitles_Path
            'video_url' = $video_url
            'SponserBlock' = $SponserBlock
            'audio_url' = $audio_url
            'EnableCasting' = $EnableCasting
            'vlcurl' = $vlcurl
            'Live_stream' = $Live_stream
            'media_link' = $media_link
            'New_MediaPlayer' = $New_MediaPlayer
            'Add_VideoView' = $Add_VideoView
            'Remove_VideoView' = $Remove_VideoView
            'Now_Playing_Title' = $Now_Playing_Title
            'Clear_Now_Playing_Title' = $Clear_Now_Playing_Title
            'Now_Playing_Artist' = $Now_Playing_Artist
            'Clear_Now_Playing_Artist' = $Clear_Now_Playing_Artist
            'Visibility' = $Visibility
            'screenshot' = $screenshot
            'Show' = $Show
            'Hide' = $hide
            'Close' = $close
      }))
      if(!$synchash.MainPlayer_Update_Timer.IsEnabled){  
        write-ezlogs ">>>> Starting MainPlayer_Update_Timer" -Dev_mode
        $synchash.MainPlayer_Update_Timer.start() 
      }            
    }
  }catch{
    write-ezlogs "An exception occurred in Update-MainPlayer" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Update-MainPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-MainWindow Function
#----------------------------------------------
function Update-MainWindow {
  Param (
    $synchash,
    $thisApp,
    [string]$Control,
    $controls,
    $value,
    $Toast,
    $ScriptBlock,
    [ValidateSet('ContextIdle','Background','Input','Loaded','Render','DataBind','Normal','Send')]
    [string]$Priority = 'Normal',
    [string]$Method,
    $Method_Value,
    [string]$Property,
    [switch]$Show,
    [switch]$PSGlobalHotkeys,
    [switch]$ClearValue,
    [switch]$NullValue,
    [switch]$Hide,
    [string]$TopMost,
    [switch]$close,
    [switch]$screenshot,
    [string]$Visibility,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.MainWindow_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $synchash.MainWindow_Update_Timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::DataBind)
      $synchash.MainWindow_Update_Timer.add_tick({
          try{  
            $synchash = $synchash
            $thisApp = $thisApp  
            $object = @{}
            $Process = $synchash.MainWindow_UpdateQueue.TryDequeue([ref]$object)
            if($Process -and $object.ProcessObject){
              if(-not [string]::IsNullOrEmpty($object.Visibility)){
                $synchash.Window.Visibility = $object.Visibility 
              }   
              if($object.Show){
                $synchash.window.ShowActivated = $true
                $synchash.window.Opacity = 1
                $synchash.window.ShowInTaskbar = $true
                $synchash.Window.show() 
                $synchash.Window.Activate()
              }
              if($object.Hide){
                if($synchash.MiniPlayer_Viewer){
                  $synchash.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
                  $synchash.window.Opacity = 0
                  $synchash.window.ShowInTaskbar = $false
                }else{
                  $synchash.Window.Hide()
                }
              }  
              if($object.Close){
                $synchash.Window.Close() 
              }
              if(-not [string]::IsNullOrEmpty($object.TopMost)){
                $synchash.Window.TopMost = $object.TopMost
              }              
              if($object.Controls){ 
                foreach($control in $object.Controls){
                  if($thisApp.Config.Dev_mode){
                    write-ezlogs ">>>> Looking for control: $($control.Control)" -loglevel 3  
                    write-ezlogs "| Property: $($control.Property)" -loglevel 3 
                    write-ezlogs "| value: $($control.value)" -loglevel 3
                  }
                  if(-not [string]::IsNullOrEmpty($synchash."$($control.Control)")){ 
                    if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Updating Main Window Control $($synchash."$($control.Control)")" -Dev_mode}
                    if(-not [string]::IsNullOrEmpty($control.Method)){
                      if(-not [string]::IsNullOrEmpty($control.Property)){
                        if(-not [string]::IsNullOrEmpty($control.Method_Value)){
                          $null = $synchash."$($control.Control)"."$($control.Property)".$($control.Method)($control.Method_Value)
                        }else{
                          $null = $synchash."$($control.Control)"."$($control.Property)".$($control.Method)()
                        }                        
                      }else{
                        if(-not [string]::IsNullOrEmpty($control.Method_Value)){
                          $null = $synchash."$($control.Control)".$($control.Method)($control.Method_Value)
                        }else{
                          $null = $synchash."$($control.Control)".$($control.Method)()
                        } 
                      }
                    }elseif(-not [string]::IsNullOrEmpty($control.Value) -or $control.ClearValue -or $control.NullValue){
                      if(-not [string]::IsNullOrEmpty($control.Property)){
                        if($synchash."$($control.Control)"."$($control.Property)" -ne $control.Value -and $control.NullValue){
                          if($thisApp.Config.Dev_mode){write-ezlogs "| Setting property $($control.Property) from $($synchash."$($control.Control)"."$($control.Property)") to Null" -Dev_mode}
                          $synchash."$($control.Control)"."$($control.Property)" = $null
                        }elseif($synchash."$($control.Control)"."$($control.Property)" -ne $control.Value){
                          if($thisApp.Config.Dev_mode){write-ezlogs "| Setting property $($control.Property) from $($synchash."$($control.Control)"."$($control.Property)") to $($control.Value)" -Dev_mode} 
                          $synchash."$($control.Control)"."$($control.Property)" = $control.Value
                        }
                      }else{
                        if($synchash."$($control.Control)" -ne $control.Value){
                          if($thisApp.Config.Dev_mode){write-ezlogs "| Setting $($synchash."$($control.Control)") to $($control.Value)" -Dev_mode}
                          $synchash."$($control.Control)" = $control.Value
                        }                        
                      }
                    }                      
                  }
                }
              }elseif(-not [string]::IsNullOrEmpty($synchash."$($object.Control)")){ 
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Updating Main Window Control: $("$($object.Control)") -- Property: $($object.Property) -- Value: $($object.Value)" -Dev_mode}                                
                if(-not [string]::IsNullOrEmpty($object.Method)){
                  if(-not [string]::IsNullOrEmpty($object.Property)){
                    if(-not [string]::IsNullOrEmpty($object.Method_Value)){
                      $null = $synchash."$($object.Control)"."$($object.Property)".$($object.Method)($object.Method_Value)
                    }else{
                      $null = $synchash."$($object.Control)"."$($object.Property)".$($object.Method)()
                    }                     
                  }else{
                    if(-not [string]::IsNullOrEmpty($object.Method_Value)){
                      $null = $synchash."$($object.Control)".$($object.Method)($object.Method_Value)
                    }else{
                      $null = $synchash."$($object.Control)".$($object.Method)()
                    }    
                  }
                }
                if(-not [string]::IsNullOrEmpty($object.Value) -or $object.ClearValue -or $object.NullValue){
                  if(-not [string]::IsNullOrEmpty($object.Property)){
                    if($synchash."$($object.Control)"."$($object.Property)" -ne $object.Value -and $object.NullValue){
                      if($thisApp.Config.Dev_mode){write-ezlogs "| Setting property $($object.Property) from $($synchash."$($object.Control)"."$($object.Property)") to Null" -Dev_mode}
                      $synchash."$($object.Control)"."$($object.Property)" = $null
                    }elseif($synchash."$($object.Control)"."$($object.Property)" -ne $object.Value){
                      if($thisApp.Config.Dev_mode){write-ezlogs "| Setting property $($object.Property) from $($synchash."$($object.Control)"."$($object.Property)") to $($object.Value)" -Dev_mode}
                      $synchash."$($object.Control)"."$($object.Property)" = $object.Value
                    }
                  }else{
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Setting Control $($object.Control) from $($synchash."$($object.Control)") to $($object.Value)" -Dev_mode}
                    $synchash."$($object.Control)" = $object.Value
                  }
                }                                     
              }
              if(-not [string]::IsNullOrEmpty($object.Toast)){ 
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Creating new toast notification: $($object.Toast)" -loglevel 3 -Dev_mode}
                $ToastSplat = $object.Toast
                New-BurntToastNotification @ToastSplat -ErrorAction SilentlyContinue
              }
              if(-not [string]::IsNullOrEmpty($object.ScriptBlock)){ 
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Executing Scriptblock with priority: $($object.Priority)"-loglevel 3 -Dev_mode}
                if(-not [string]::IsNullOrEmpty($object.Priority)){
                  [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::$($object.Priority),[Action]$object.ScriptBlock)
                }else{
                  [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Normal,[Action]$object.ScriptBlock)
                }
                #Invoke-command -ScriptBlock $object.ScriptBlock
              }                                                                                            
              if($object.screenshot){
                #$hashsetup.Window.TopMost = $true
                $synchash.Window.TopMost = $object.TopMost
                $synchash.Window.Activate() 
                start-sleep -Milliseconds 500
                write-ezlogs ">>>> Taking Snapshot of Main window" -loglevel 2
                $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$synchash.Window)
                $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
                $synchash.SnapshotPoint = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)           
              }
              if($object.PSGlobalHotkeys){
                Get-GlobalHotKeys -thisApp $thisApp -synchash $synchash -UnRegister -Register:$synchash.Hotkeys_Button.isChecked
              }
            }else{
              $this.Stop()
            }                                       
          }catch{
            write-ezlogs "An exception occurred in MainWindow_Update_Timer.add_tick" -showtime -catcherror $_
            $this.stop()
          }
      })
    }else{
      [void]$synchash.MainWindow_UpdateQueue.Enqueue([PSCustomObject]::new(@{
            'Control' = $Control
            'ProcessObject' = $true
            'Value' = $Value
            'ClearValue' = $ClearValue
            'NullValue' = $NullValue
            'Method' = $Method
            'Method_Value' = $Method_Value
            'TopMost' = $TopMost
            'Property' = $Property
            'Priority' = $Priority
            'Visibility' = $Visibility
            'screenshot' = $screenshot
            'controls' = $controls
            'PSGlobalHotkeys' = $PSGlobalHotkeys
            'Show' = $Show
            'Hide' = $hide
            'Toast' = $Toast
            'ScriptBlock' = $ScriptBlock
            'Close' = $close
      }))
      if(!$synchash.MainWindow_Update_Timer.IsEnabled){  
        #write-ezlogs "Starting MainWindow_Update_Timer" -loglevel 3
        $synchash.MainWindow_Update_Timer.start() 
      }    
    }
  }catch{
    write-ezlogs "An exception occurred in Update-MainWindow" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-MainWindow Function
#----------------------------------------------

#---------------------------------------------- 
#region Reset-MainPlayer Function
#----------------------------------------------
function Reset-MainPlayer {
  Param (
    $synchash,
    $thisApp,
    [switch]$verboselog,
    [switch]$OnlyDisposeWebPlayers,
    [switch]$SkipSpotify,
    [switch]$SkipDiscord,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.Reset_MediaPlayer_timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.Reset_MediaPlayer_timer.add_tick({
          try{  
            $synchash = $synchash
            $thisApp = $thisApp   
            #Stop/Reset WebPlayers                         
            Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
            $synchash.WebPlayer_State = 0      
            $synchash.Youtube_WebPlayer_title = $Null
            if($synchash.VLC_Grid.children -contains $synchash.Webview2){
              write-ezlogs "[Reset-MainPlayer] >>>> Removing Webview2 from Vlc_Grid" -showtime
              $synchash.VLC_Grid.children.Remove($synchash.Webview2)         
            }    
            if(!$this.tag.SkipSpotify -and $syncHash.WebView2 -ne $null -and $syncHash.WebView2.CoreWebView2 -ne $null){
              write-ezlogs "[Reset-MainPlayer] >>>> Disposing spotify webplayer Webview2 instance" -showtime 
              $synchash.webview2.dispose()
              $synchash.webview2 = $Null
            }           
            #Dispose Youtube Webview  
            if($synchash.Webview2_Grid.children -contains $synchash.YoutubeWebView2){
              write-ezlogs "[Reset-MainPlayer] | Removing Youtubewebview2 from Webview2_Grid" -showtime
              $null = $synchash.Webview2_Grid.children.Remove($synchash.YoutubeWebView2)
            } 
            if($synchash.VLC_Grid.children -contains $synchash.YoutubeWebView2){
              write-ezlogs "[Reset-MainPlayer] >>>> Removing YoutubeWebView2 from Vlc_Grid" -showtime
              $synchash.VLC_Grid.children.Remove($synchash.YoutubeWebView2)  
            } 
            #Remove playlists overlay from webviews
            if($synchash.VLC_Grid.Children -contains $synchash.VideoViewAirControl){
              Write-EZLogs '[Reset-MainPlayer] | Removing VideoViewAirControl from VLC_Grid'
              $null = $synchash.VLC_Grid.children.Remove($synchash.VideoViewAirControl)
              $VideoViewAirControl = Get-VisualParentUp -source $synchash.VideoViewAirControl.front -type ([System.Windows.Window])
              if($VideoViewAirControl){
                #write-ezlogs "| Closing window of VideoViewAirControl"
                $VideoViewAirControl.Owner = $Null
                $VideoViewAirControl.Close()
              }
              $synchash.VideoViewAirControl.Front = $null
              $synchash.VideoViewAirControl.Back = $null
              $synchash.VideoViewAirControl = $null
            }
            if($syncHash.YoutubeWebView2 -ne $null -and $syncHash.YoutubeWebView2.CoreWebView2 -ne $null){
              write-ezlogs "[Reset-MainPlayer] >>>> Disposing youtube webplayer Webview2 instance" -showtime
              $synchash.YoutubeWebView2.dispose()
              $synchash.YoutubeWebView2 = $Null
            }
            if($synchash.VideoView_Overlay_Grid.children -notcontains $synchash.VideoViewTransparentBackground){
              $null = $synchash.VideoView_Overlay_Grid.AddChild($synchash.VideoViewTransparentBackground)
              $synchash.VideoViewTransparentBackground.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
              #$synchash.VideoViewTransparentBackground.Margin = '0,0,0,35'
              $synchash.TrayPlayerQueue_FlyoutControl.Margin = "0,0,0,35"
              $synchash.OverlayFlyoutBackground.Margin = "0,0,0,35"
              $synchash.VideoViewTransparentBackground.MaxWidth = [Double]::PositiveInfinity
              $synchash.VideoViewTransparentBackground.HorizontalAlignment="Stretch"
              $synchash.OverlayFlyoutBackground.Style = $synchash.Window.TryFindResource('ResetOverlayGridFade')
              $synchash.VideoViewOverlayTopGrid.Visibility = [System.Windows.Visibility]::Collapsed
              $synchash.TrayPlayerQueueFlyout.Remove_IsOpenChanged($synchash.TrayPlayerQueueFlyoutScriptBlock)
              $synchash.VideoViewTransparentBackground.MaxHeight = [Double]::PositiveInfinity
              #$synchash.VideoViewTransparentBackground.MaxWidth = [Double]::PositiveInfinity
              #$synchash.OverlayFlyoutBackground.Style = $null
              #[void][System.Windows.Data.BindingOperations]::ClearAllBindings($synchash.OverlayFlyoutBackground)
              #$synchash.OverlayFlyoutBackground.Opacity='1'
            }
            if($this.Tag.OnlyDisposeWebPlayers){
              $this.tag = $null
              $this.Stop()
              return
            }
                               
            #Stop Dsclient integration
            if(!$this.tag.SkipDiscord -and $thisApp.Config.Discord_Integration){
              Set-DiscordPresense -synchash $synchash -thisapp $thisApp -stop
            } 
                        
            #Clear Media Images    
            if($synchash.MediaView_Image){
              $synchash.MediaView_Image.Source = $Null
            }      
            if($synchash.FullScreen_Player_Button.isEnabled){
              $synchash.FullScreen_Player_Button.isEnabled = $false
            }

            #Reset VideoView Control
            #TODO: Setting as nan is bad!
            if($synchash.VideoView -and $synchash.VideoView.Height -ne [Double]::NaN){
              #$synchash.VideoView.Height=[Double]::NaN
            }
            ######
            #TODO: Setting video view to visible here potentially contributes towards Layout measurement override crash if video view is currently collapsed
            #Mostly only occurs if miniplayer is open but can still occur even if not
            #Does not occur if video view is hidden. If collapsed, it basically sets the height/width to 0 (and any controls inside it, specifically airhack and those used to get around wpf airspace issues)
            #When its set to visible, various layout measurement events trigger but if the height and width is 0 (due to being collapsed) we get the crash
            #There some cases where video view may be collapsed on purpose (so it doesnt take up layout space like hidden does) and we still want to set back to visible so we need this check
            #See related code/comments for window closing event in Set-Avalondock
            #This likely needs a thorough refactor or rethinking to avoid this situation
            if($synchash.VideoView.Visibility -in 'Hidden','Collapsed'){
              write-ezlogs "[Reset-MainPlayer] | Unhiding VideoView" -showtime
              $synchash.VideoView.Visibility = 'Visible'
            }
            ######
            if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
              Write-EZLogs '[Reset-MainPlayer] | Adding VideoView to VideoView_Grid'
              $null = $synchash.VLC_Grid.AddChild($synchash.VideoView)
            } 
            if($synchash.VLC_Grid.Visibility -in 'Hidden','Collapsed'){
              write-ezlogs "[Reset-MainPlayer] | Unhiding VLC_Grid" -showtime
              $synchash.VLC_Grid.Visibility="Visible"
            }                    
            if(-not [string]::IsNullOrEmpty($synchash.VideoView_ViewCount_Label.text)){
              $synchash.VideoView_ViewCount_Label.Visibility = 'Hidden'
              $synchash.VideoView_ViewCount_Label.text = $null      
              $synchash.VideoView_Sep3_Label.Text = $Null    
            }
            #Reset Video/Audio Quality display 
            if($synchash.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_VideoQuality_TextBlock.text)){
              $synchash.DisplayPanel_VideoQuality_TextBlock.text = $Null   
            }
            #TODO: Audio Quality display
            if($synchash.DisplayPanel_AudioQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_AudioQuality_TextBlock.text)){
              $synchash.DisplayPanel_AudioQuality_TextBlock.text = $Null   
            }                                                     
            $this.Stop()
          }catch{
            write-ezlogs "An exception occurred in Reset_MediaPlayer_timer.add_tick" -showtime -catcherror $_
          }finally{
            $this.tag = $null
            $this.Stop()
          }
      }) 
    }else{
      if(!$synchash.Reset_MediaPlayer_timer.isEnabled){
        $synchash.Reset_MediaPlayer_timer.tag = [PSCustomObject]::new(@{
            'OnlyDisposeWebPlayers' = $OnlyDisposeWebPlayers
            'SkipSpotify' = $SkipSpotify
            'SkipDiscord' = $SkipDiscord
        })
        $synchash.Reset_MediaPlayer_timer.start()  
      }else{
        write-ezlogs "[Reset-MediaPlayer] Reset_MediaPlayer_timer is already enabled, not executing start() again" -warning
      }      
    }
  }catch{
    write-ezlogs "An exception occurred in Reset-MainPlayer" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Reset-MainPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-MediaState Function
#----------------------------------------------
function Update-MediaState {
  Param (
    $synchash,
    $thisApp,
    $Background_cached_image,
    $Background_default_image,
    $background_accent_color,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.Update_MediaState_timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
      $synchash.Update_MediaState_timer.add_tick({
          try{
            $Update_MediaState_Measure = [system.diagnostics.stopwatch]::StartNew()
            $Background_cached_image = $this.Tag.Background_cached_image
            $Background_default_image = $this.Tag.Background_default_image
            if($synchash.VideoView_Mute_Icon){
              if($synchash.vlc.mute -or !$synchash.vlc){
                $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
              }elseif($synchash.Volume_Slider.value -ge 75){
                $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
              }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
                $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
              }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
                $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
              }elseif($synchash.Volume_Slider.value -le 0){
                $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
              }
            }
            if($Background_cached_image){
              if($this.tag.DefaultSkin){
                if([system.io.file]::Exists($Background_cached_image)){
                  write-ezlogs ">>>> Opening Media image: $($Background_cached_image)" -showtime
                  $stream_image = [System.IO.File]::OpenRead($Background_cached_image) 
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  $image.BeginInit();
                  $image.CacheOption = "OnLoad"
                  $image.DecodePixelWidth = "500"
                  $image.StreamSource = $stream_image
                  $image.EndInit() 
                  $syncHash.MainGrid_Background_Image_Source.Source = $image
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze()
                }else{
                  $syncHash.MainGrid_Background_Image_Source.Source = $Background_cached_image
                }
                $syncHash.MainGrid_Background_Image_Source.Stretch = "UniformToFill"
                $syncHash.MainGrid_Background_Image_Source.Opacity = 0.25
                $syncHash.MainGrid_Background_Image_Source.Effect.Radius = "15"
              }                                        
              if($syncHash.TrayPlayer_Image){
                $syncHash.TrayPlayer_Image.Opacity = 1
              } 
              $Thumbnail = $Background_cached_image
            }else{  
              if($Background_default_image){
                write-ezlogs "[Update-MediaState] >>>> No Background image provided, setting to Background_default_image: $Background_default_image" -showtime -loglevel 2  
                if($this.tag.DefaultSkin){
                  $syncHash.MainGrid_Background_Image_Source.Source = $Background_default_image
                  $syncHash.MainGrid_Background_Image_Source.Stretch = "Uniform"
                } 
                if($syncHash.TrayPlayer_Image){
                  $syncHash.TrayPlayer_Image.Opacity = 0.3
                }
                if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
                  if(![system.io.file]::Exists($Background_default_image)){
                    $Thumbnail = "$($thisApp.Config.Current_folder)\Resources\Samson_Icon_NoText1.png"
                  }else{
                    $Thumbnail = $Background_default_image
                  }
                }
              }else{
                write-ezlogs "[Update-MediaState] >>>> No Background image provided, setting to default App image" -showtime -loglevel 2
                if($this.tag.DefaultSkin){
                  $syncHash.MainGrid_Background_Image_Source.Source = $null
                }       
                if($syncHash.TrayPlayer_Image){
                  $syncHash.TrayPlayer_Image.Opacity = 1
                }
                $Thumbnail = "$($thisApp.Config.Current_folder)\Resources\Samson_Icon_NoText1.png"
              }
            }
            if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
              Update-MediaTransportControls -synchash $synchash -thisApp $thisApp -Media $synchash.Current_playing_media -thumbnail $Thumbnail
            }
            if($synchash.streamlink.title){
              $synchash.Now_Playing_Label.Visibility = 'Visible'
              $synchash.Now_Playing_Label.DataContext = "PLAYING"
              $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
              if($synchash.streamlink.User_Name){
                $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.streamlink.User_Name)"
                $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.streamlink.title)"
              }else{
                $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.streamlink.User_Name): $($synchash.streamlink.title)"
                $synchash.Now_Playing_Artist_Label.DataContext = ""
              } 
              if(-not [string]::IsNullOrEmpty($synchash.streamlink.viewer_count) -and $synchash.VideoView_ViewCount_Label.text -ne $synchash.streamlink.viewer_count){
                $synchash.VideoView_ViewCount_Label.text = $synchash.streamlink.viewer_count
                $synchash.VideoView_ViewCount_Label.Visibility = 'Visible'
                $synchash.VideoView_Sep3_Label.Text = ' || Viewers: '
              }elseif(-not [string]::IsNullOrEmpty($synchash.streamlink.view_count) -and $synchash.VideoView_ViewCount_Label.text -ne $synchash.streamlink.view_count){
                $synchash.VideoView_ViewCount_Label.text = $synchash.streamlink.view_count
                $synchash.VideoView_ViewCount_Label.Visibility = 'Visible'
                $synchash.VideoView_Sep3_Label.Text = ' || Views: '         
              }elseif(-not [string]::IsNullOrEmpty($synchash.VideoView_ViewCount_Label.text)){
                $synchash.VideoView_ViewCount_Label.Visibility = 'Hidden'
                $synchash.VideoView_Sep3_Label.Text = $Null
                $synchash.VideoView_ViewCount_Label.text = $null          
              }
              if($synchash.streamlink.url -match '\/vidoes\/'){
                $synchash.MediaPlayer_Slider.value = 0
                $synchash.MediaPlayer_Slider.isEnabled = $true     
              }else{
                $synchash.MediaPlayer_Slider.value = 0
                $synchash.MediaPlayer_Slider.isEnabled = $false   
              }      
              if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'None'){
                $synchash.Main_TaskbarItemInfo.ProgressState = 'None'
              }
            }else{
              $synchash.VideoView_ViewCount_Label.text = $null
              $synchash.VideoView_ViewCount_Label.Visibility = 'Hidden'
              $synchash.VideoView_Sep3_Label.Text = $Null 
            }
            if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.Current_playing_media.Bitrate -ne '0'){
              $synchash.DisplayPanel_VideoQuality_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
            }elseif(-not [string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.DisplayPanel_VideoQuality_TextBlock.text -ne $synchash.Current_Video_Quality){
              $synchash.DisplayPanel_VideoQuality_TextBlock.text = $synchash.Current_Video_Quality
            }elseif([string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_VideoQuality_TextBlock.text)){
              $synchash.DisplayPanel_VideoQuality_TextBlock.text = $Null
            }
            <#            if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.Current_playing_media.Bitrate -ne '0'){
                $synchash.DisplayPanel_Bitrate_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
                $synchash.DisplayPanel_Sep3_Label.Visibility = 'Visible'
                }else{
                $synchash.DisplayPanel_Bitrate_TextBlock.text = ""
                $synchash.DisplayPanel_Sep3_Label.Visibility = 'Hidden'
            } #>  
            if($thisApp.Config.Libvlc_Version -eq '4'){
              $vlchasnovideo = $synchash.vlc.Media.DecodedVideo -le 0 -and $synchash.vlc.Role -notmatch 'Video'
            }else{
              $vlchasnovideo = $synchash.vlc.VideoTrackCount -le 0 -and $synchash.vlc.Role -notmatch 'Video'
            }    
            if(($vlchasnovideo -and $synchash.Media_Current_Title -and !$synchash.Youtube_WebPlayer_URL -and !$thisApp.Config.Use_Visualizations -and !$synchash.Current_playing_media.hasvideo) -or ($synchash.Media_Current_Title -and $synchash.Spotify_Status -eq 'Playing')){         
              write-ezlogs "[Update-MediaState] >>>> Media has no video - VideoTrackCount: $($synchash.vlc.VideoTrackCount) - DecodedVideo: $($synchash.vlc.Media.DecodedVideo)" -showtime -LogLevel 2          
              if($synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer -and !$synchash.MediaViewAnchorable.isFloating){
                write-ezlogs "[Update-MediaState] | Media has no video, Closing Video Player -- vlchasvideo: $($vlchasnovideo) -- Media_Current_Title: $($synchash.Media_Current_Title) -- Youtube_WebPlayer_URL: $($synchash.Youtube_WebPlayer_URL) -- Spotify_Status: $($synchash.Spotify_Status) -- Current_playing_media.hasvideo: $($synchash.Current_playing_media.hasvideo)" -showtime -LogLevel 2
                Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Close
              }                  
              $synchash.VLC_Grid_Row2.Height="*"
              $synchash.VLC_Grid_Row0.Height="0"
              if($Background_cached_image){
                $synchash.VLC_Grid_Row1.Height="100*" 
                $synchash.VLC_Grid.Visibility="Visible"   
                $synchash.MediaView_Image.Source = $Background_cached_image
              }else{
                write-ezlogs "[Update-MediaState] | No image, resetting MediaView_image to null" -showtime
                $synchash.MediaView_Image.Source = $null
              }        
            }else{  
              if(!$synchash.Youtube_WebPlayer_URL -or $synchash.Current_playing_media.hasvideo){
                $synchash.VideoView.Visibility="Visible"
                $synchash.VLC_Grid.Visibility="Visible"
                if($synchash.VideoView_Flyout){
                  $synchash.VideoView_Flyout.Visibility = 'Visible'
                }
              }
              if(($synchash.vlc.VideoTrackCount -gt 0 -or $synchash.Current_playing_media.hasVideo) -or ($synchash.Current_playing_media -and $thisApp.Config.Use_Visualizations) -and (!$synchash.Youtube_WebPlayer_URL -and !$synchash.Spotify_WebPlayer_URL)){
                if($synchash.MiniPlayer_Viewer.isVisible -and !$synchash.MediaViewAnchorable.isFloating){
                  write-ezlogs "[Update-MediaState] >>>> Video view is not visible and MiniPlayer is visible, Youtube webplayer not playing, undocking video player" -Warning
                  if($synchash.VideoViewFloat.Height){
                    $synchash.MediaViewAnchorable.FloatingHeight = $synchash.VideoViewFloat.Height
                  }else{
                    $synchash.MediaViewAnchorable.FloatingHeight = '400'
                  }                  
                  $synchash.MediaViewAnchorable.float() 
                }else{
                  write-ezlogs "[Update-MediaState] >>>> Media has video, showing videoview" -showtime
                }
                if($synchash.VideoView_Flyout -and $synchash.VideoView_Flyout.Visibility -ne 'Visible'){
                  $synchash.VideoView_Flyout.Visibility = 'Visible'
                }         
                if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
                  write-ezlogs "[Update-MediaState] | Adding VideoView to Vlc_Grid" -showtime
                  $Null = $synchash.VLC_Grid.children.add($synchash.VideoView)                
                }
                if($synchash.VideoView -and $synchash.VideoView.Visibility -ne 'Visible'){
                  $synchash.VideoView.Visibility="Visible"
                }
                if($synchash.VLC_Grid -and $synchash.VLC_Grid.Visibility -ne 'Visible'){
                  $synchash.VLC_Grid.Visibility="Visible"
                }
                if($synchash.FullScreen_Player_Button -and !$synchash.FullScreen_Player_Button.isEnabled){
                  $synchash.FullScreen_Player_Button.isEnabled = $true
                }
                if(!$synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer -and !$synchash.MediaViewAnchorable.isFloating){
                  if($thisApp.Config.Dev_mode){write-ezlogs "[Update-MediaState] | Mediaview is not floating, toggling VideoButton"  -dev_mode}
                  Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Open
                  if($synchash.MediaViewAnchorable){
                    $synchash.MediaViewAnchorable.isSelected = $true
                  }     
                }
              }
              if($thisapp.config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title){
                if($thisApp.Config.Dev_mode){write-ezlogs "[Update-MediaState] >>>> Media is using Spotify Webplayer, hiding video view" -dev_mode}         
                $synchash.VLC_Grid_Row2.Height="*"
                $synchash.VLC_Grid_Row0.Height="*"   
              }else{
                if($thisApp.Config.Dev_mode){write-ezlogs "[Update-MediaState] >>>> Resetting Media Image, text and VLC_Grid row height" -dev_mode}
                $synchash.VLC_Grid_Row0.Height="100*"
                $synchash.VLC_Grid_Row2.Height="*"
                $synchash.VLC_Grid_Row1.Height="*"
                $synchash.MediaView_Image.Source = $null                          
              }               
            }
            if($thisApp.Config.Discord_Integration){
              Set-DiscordPresense -synchash $synchash -media $synchash.Current_playing_media -thisapp $thisApp -start
            }      
            if($thisApp.Config.Verbose_logging -and $thisApp.Config.dev_Mode){
              write-ezlogs "[Update-MediaState] >>>> Current VLC Media Player instance: $($synchash.Vlc | out-string)" -showtime -Debug -Dev_mode
            }
            <#            if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
                $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
            }#>
            $this.Stop()
          }catch{
            write-ezlogs "[Update-MediaState] An exception occurred in Update_MediaState_timer.add_tick" -showtime -catcherror $_
          }finally{
            $this.tag = $null
            if($Update_MediaState_Measure){
              $Update_MediaState_Measure.stop()
              write-ezlogs "| After Update_MediaState_Measure" -showtime -loglevel 2 -Perf -PerfTimer $Update_MediaState_Measure -GetMemoryUsage -forceCollection  
              $Update_MediaState_Measure = $Null
            }
            $this.Stop()
          }
      }) 
    }else{
      if(!$synchash.Update_MediaState_timer.isEnabled){
        $synchash.Update_MediaState_timer.tag = [PSCustomObject]::new(@{
            'Background_cached_image' = $Background_cached_image
            'Background_default_image' = $Background_default_image
            'background_accent_color' = $background_accent_color
        })
        $synchash.Update_MediaState_timer.start()
      }else{
        write-ezlogs "[Update-MediaState] Update_MediaState_timer is already enabled, not executing start() again" -warning
      }      
    }
  }catch{
    write-ezlogs "[Update-MediaState] An exception occurred in Update-MediaState" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-MediaState Function
#----------------------------------------------

#----------------------------------------------
#region Add-WPFMenu
#----------------------------------------------
function Add-WPFMenu {
  [CmdletBinding()]
  Param(
    $Control,
    $Items,
    $separator,
    $ContextMenuOpening_Command,
    $ContextMenuClosing_Command,
    $sourceWindow = $synchash,
    [switch]$addchild,
    [switch]$AddContextMenu,
    [switch]$AnchorableContextMenu,
    [switch]$TrayMenu
  )
  process {
    try{
      if($AddContextMenu){
        $contextMenu = [System.Windows.Controls.ContextMenu]::new()
        $contextmenu.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty,$true)
        $contextmenu.SetValue([System.Windows.Controls.VirtualizingPanel]::IsVirtualizingProperty,$true)
        $contextmenu.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty,[System.Windows.Controls.VirtualizationMode]::Recycling)
        $contextmenu.SetValue([System.Windows.Controls.VirtualizingPanel]::VirtualizationModeProperty,[System.Windows.Controls.VirtualizationMode]::Recycling)
        $contextmenu.SetValue([System.Windows.Controls.ScrollViewer]::CanContentScrollProperty,$true)
        if(-not [string]::IsNullOrEmpty($ContextMenuOpening_Command)){
          $contextMenu.Add_ContextMenuOpening($ContextMenuOpening_Command)
          $contextMenu.Add_ContextMenuClosing($ContextMenuOpening_Command)
        }   
        if(-not [string]::IsNullOrEmpty($ContextMenuClosing_Command)){
          $contextMenu.Add_ContextMenuOpening($ContextMenuClosing_Command)
        }           
      }
      foreach ($item in $items) {
        if($item.Separator){
          $menu_separator = [System.Windows.Controls.Separator]::new()
          if($trayMenu){
            $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource('SeparatorGradient')
            $menu_separator.BorderThickness = "0"
          }else{
            $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource($item.Style)
          }
          if($addchild){
            $null = $control.AddChild($menu_separator)
          }else{
            $null = $contextMenu.Items.Add($menu_separator)
          }
        }else{
          $menuItem = [System.Windows.Controls.MenuItem]::new()
          $menuItem.Header = $item.Header
          if(-not [string]::IsNullOrEmpty($item.Style)){
            $menuItem.Style = $sourceWindow.Window.TryFindResource($item.Style)
          }elseif($trayMenu){                  
            $menuItem.Style = $sourceWindow.Window.TryFindResource("TrayDropDownMenuitemStyle")
          }else{
            $menuItem.Style = $sourceWindow.Window.TryFindResource("DropDownMenuitemStyle")
          }
          if(-not [string]::IsNullOrEmpty($item.FontWeight)){
            $menuItem.FontWeight = $item.FontWeight
          }
          if(-not [string]::IsNullOrEmpty($item.FontStyle)){
            $menuItem.FontStyle = $item.FontStyle
          }                
          if(-not [string]::IsNullOrEmpty($item.ToolTip)){
            $menuItem.ToolTip = $item.ToolTip
          }
          $menuItem.Foreground = $item.color
          if(-not [string]::IsNullOrEmpty($item.BackGround)){
            $menuItem.BackGround = $item.BackGround
          }
          $menuItem.IsEnabled = $item.enabled
          $menuItem.Tag = $control.datacontext
          if($Item.IsCheckable){
            $menuItem.IsCheckable = $Item.IsCheckable
            if($Item.IsChecked){
              $menuItem.IsChecked = $true
            }
          }elseif(-not [string]::IsNullOrEmpty($item.icon_kind)){
            if(-not [string]::IsNullOrEmpty($item.iconpack)){
              $iconpack = "MahApps.Metro.IconPacks.$($item.iconpack)"
            }else{
              $iconpack = "MahApps.Metro.IconPacks.PackIconMaterial"
            }            
            $menuItem_imagecontrol = ($iconpack -as [type])::new()
            $menuItem_imagecontrol.width = "16"
            $menuItem_imagecontrol.Height = "16"
            $menuItem_imagecontrol.Kind = $item.icon_kind
            $menuItem_imagecontrol.Foreground = $item.icon_color
            if(-not [string]::IsNullOrEmpty($item.icon_margin)){
              $menuItem_imagecontrol.margin = $item.icon_margin
            }
            $menuItem.icon = $menuItem_imagecontrol
          }elseif(-not [string]::IsNullOrEmpty($item.icon_image)){
            #$stream_image = [System.IO.File]::OpenRead($item.icon_image)
            #$image =  [System.Drawing.Image]::FromStream($stream_image)              
            #$menuItem_image = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes($item.icon_image)))
            $stream_image = [System.IO.File]::OpenRead($item.icon_image) 
            $image = [System.Windows.Media.Imaging.BitmapImage]::new()
            $image.BeginInit()
            $image.CacheOption = "OnLoad"    
            $image.StreamSource = $stream_image
            $image.DecodePixelWidth = '18'
            $image.EndInit()
            $menuItem_imagecontrol = [System.Windows.Controls.Image]::new()
            $menuItem_imagecontrol.Width = $image.Width
            $menuItem_imagecontrol.Height = $image.Height
            $menuItem_imagecontrol.Source = $image               
            $image.Freeze()
            if(-not [string]::IsNullOrEmpty($item.icon_margin)){
              $menuItem_imagecontrol.margin = $item.icon_margin
            }
            $menuItem.icon = $menuItem_imagecontrol
            $stream_image.Close()
            $stream_image.Dispose()
            $stream_image = $null
          }
          if(-not [string]::IsNullOrEmpty($item.tag)){
            $menuItem.tag = $item.tag
          }
          if(-not [string]::IsNullOrEmpty($item.Command)){
            $menuItem.RemoveHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$item.Command)
            $menuItem.AddHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$item.Command)          
          }
          if(-not [string]::IsNullOrEmpty($item.binding)){
            $Binding = [System.Windows.Data.Binding]::new()
            $Binding.Source = $item.binding
            $Binding.Path = $item.binding_property_path
            $Binding.Mode = $item.binding_mode
            if($item.binding_property){
              $BindingProperty = $item.binding_property
            }else{
              $BindingProperty = 'IsCheckedProperty'
            }
            $null = [System.Windows.Data.BindingOperations]::SetBinding($menuItem,[System.Windows.Controls.MenuItem]::$BindingProperty, $Binding) 
          }
          if(-not [string]::IsNullOrEmpty($item.Sub_items)){
            foreach($subitem in $item.Sub_items){
              if($subitem.Separator){
                $menu_separator = [System.Windows.Controls.Separator]::new()    
                if($trayMenu){
                  $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource('SeparatorGradient')
                }else{         
                  $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource($subitem.Style)
                }
                $null = $menuItem.Items.Add($menu_separator)
              }else{
                $SubmenuItem = [System.Windows.Controls.MenuItem]::new()
                $SubmenuItem.Header = $SubItem.header
                if(-not [string]::IsNullOrEmpty($subitem.Style)){
                  $SubmenuItem.Style = $sourceWindow.Window.TryFindResource($subitem.Style)
                }
                if(-not [string]::IsNullOrEmpty($subitem.FontWeight)){
                  $SubmenuItem.FontWeight = $subitem.FontWeight
                } 
                if(-not [string]::IsNullOrEmpty($subitem.FontStyle)){
                  $SubmenuItem.FontStyle = $subitem.FontStyle
                }                           
                if(-not [string]::IsNullOrEmpty($subitem.ToolTip)){
                  $SubmenuItem.ToolTip = $subitem.ToolTip
                }
                if(-not [string]::IsNullOrEmpty($subitem.ForegroundStyle)){
                  $SubmenuItem.Foreground = $sourceWindow.Window.TryFindResource($subitem.ForegroundStyle)
                }else{
                  $SubmenuItem.Foreground = $subitem.color
                }
                if(-not [string]::IsNullOrEmpty($subitem.tag)){
                  $SubmenuItem.tag = $subitem.tag
                }
                if(-not [string]::IsNullOrEmpty($subitem.BackGround)){
                  $SubmenuItem.BackGround = $subitem.BackGround
                }
                if(-not [string]::IsNullOrEmpty($subitem.Style)){
                  $SubmenuItem.Style = $sourceWindow.Window.TryFindResource($subitem.Style)
                }elseif($trayMenu){                  
                  $SubmenuItem.Style = $sourceWindow.Window.TryFindResource("TrayDropDownMenuitemStyle")
                }else{
                  $SubmenuItem.Style = $sourceWindow.Window.TryFindResource("DropDownMenuitemStyle")
                }
                $SubmenuItem.IsEnabled = $subitem.enabled
                if($SubItem.IsCheckable){
                  $SubmenuItem.IsCheckable = $SubItem.IsCheckable
                  if($SubItem.IsChecked){
                    $SubmenuItem.IsChecked = $true
                  }
                }elseif(-not [string]::IsNullOrEmpty($Subitem.icon_kind)){
                  if(-not [string]::IsNullOrEmpty($Subitem.iconpack)){
                    $iconpack = "MahApps.Metro.IconPacks.$($Subitem.iconpack)"
                  }else{
                    $iconpack = "MahApps.Metro.IconPacks.PackIconMaterial"
                  }            
                  $SubmenuItem_imagecontrol = ($iconpack -as [type])::new()
                  $SubmenuItem_imagecontrol.width = "16"
                  $SubmenuItem_imagecontrol.Height = "16"
                  $SubmenuItem_imagecontrol.Kind = $Subitem.icon_kind
                  $SubmenuItem_imagecontrol.Foreground = $Subitem.icon_color
                  if($trayMenu){
                    #$SubmenuItem_imagecontrol.margin =  "0"
                    #$SubmenuItem_imagecontrol.width = "15"
                    #$SubmenuItem_imagecontrol.Height = "15"
                  }
                  if($Subitem.icon_margin){
                    $SubmenuItem_imagecontrol.margin = $Subitem.icon_margin
                  }      
                  $SubmenuItem.icon = $SubmenuItem_imagecontrol
                }elseif(-not [string]::IsNullOrEmpty($Subitem.icon_image)){
                  $stream_image = [System.IO.File]::OpenRead($Subitem.icon_image)
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  $image.BeginInit()
                  $image.CacheOption = "OnLoad"    
                  $image.StreamSource = $stream_image
                  $image.DecodePixelWidth = '18'
                  $image.EndInit()       
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze()
                  $SubmenuItem_imagecontrol = [System.Windows.Controls.Image]::new()
                  $SubmenuItem_imagecontrol.Source = $image
                  if($Subitem.icon_margin){
                    $SubmenuItem_imagecontrol.margin = $Subitem.icon_margin
                  }
                  $SubmenuItem.icon = $SubmenuItem_imagecontrol
                }
                if(-not [string]::IsNullOrEmpty($subitem.binding)){
                  $Binding = [System.Windows.Data.Binding]::new()
                  $Binding.Source = $subitem.binding
                  $Binding.Path = $subitem.binding_property_path
                  $Binding.Mode = $subitem.binding_mode
                  [void][System.Windows.Data.BindingOperations]::SetBinding($SubmenuItem,[System.Windows.Controls.MenuItem]::IsCheckedProperty, $Binding)
                }
                if(-not [string]::IsNullOrEmpty($Subitem.Command)){
                  $SubmenuItem.RemoveHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$Subitem.Command)
                  $SubmenuItem.AddHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$Subitem.Command)
                }
                if(-not [string]::IsNullOrEmpty($subitem.Sub_items)){
                  foreach($subitem_lvl2 in $subitem.Sub_items){
                    if($subitem_lvl2.Separator){
                      $menu_separator = [System.Windows.Controls.Separator]::new()          
                      if($trayMenu){
                        $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource('SeparatorGradient')
                        #$menu_separator.BorderThickness = "0"
                      }else{         
                        $menu_separator.OpacityMask = $sourceWindow.Window.TryFindResource($subitem_lvl2.Style)
                      }
                      $null = $SubmenuItem.Items.Add($menu_separator)
                    }else{
                      $SubmenuItem_lvl2 = [System.Windows.Controls.MenuItem]::new()
                      $SubmenuItem_lvl2.Header = $SubItem_lvl2.header
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.Style)){
                        $SubmenuItem_lvl2.Style = $sourceWindow.Window.TryFindResource($subitem_lvl2.Style)
                      }
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.FontWeight)){
                        $SubmenuItem_lvl2.FontWeight = $subitem_lvl2.FontWeight
                      } 
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.FontStyle)){
                        $SubmenuItem_lvl2.FontStyle = $subitem_lvl2.FontStyle
                      }                                   
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.ToolTip)){
                        $SubmenuItem_lvl2.ToolTip = $subitem_lvl2.ToolTip
                      }
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.ForegroundStyle)){
                        $SubmenuItem_lvl2.Foreground = $sourceWindow.Window.TryFindResource($subitem_lvl2.ForegroundStyle)
                      }else{
                        $SubmenuItem_lvl2.Foreground = $subitem_lvl2.color
                      }
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.tag)){
                        $SubmenuItem_lvl2.tag = $subitem_lvl2.tag
                      }
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.BackGround)){
                        $SubmenuItem_lvl2.BackGround = $subitem_lvl2.BackGround
                      }
                      $SubmenuItem_lvl2.IsEnabled = $subitem_lvl2.enabled
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.Style)){
                        $SubmenuItem_lvl2.Style = $sourceWindow.Window.TryFindResource($subitem_lvl2.Style)
                      }elseif($trayMenu){                  
                        $SubmenuItem_lvl2.Style = $sourceWindow.Window.TryFindResource("TrayDropDownMenuitemStyle")
                      }else{
                        $SubmenuItem_lvl2.Style = $sourceWindow.Window.TryFindResource("DropDownMenuitemStyle")
                      }
                      if($SubItem_lvl2.IsCheckable){
                        $SubmenuItem_lvl2.IsCheckable = $SubItem_lvl2.IsCheckable
                      }elseif(-not [string]::IsNullOrEmpty($Subitem_lvl2.icon_kind)){
                        if(-not [string]::IsNullOrEmpty($Subitem_lvl2.iconpack)){
                          $iconpack = "MahApps.Metro.IconPacks.$($Subitem_lvl2.iconpack)"
                        }else{
                          $iconpack = "MahApps.Metro.IconPacks.PackIconMaterial"
                        }          
                        $SubmenuItem_lvl2_imagecontrol = ($iconpack -as [type])::new()
                        $SubmenuItem_lvl2_imagecontrol.width = "16"
                        $SubmenuItem_lvl2_imagecontrol.Height = "16"
                        $SubmenuItem_lvl2_imagecontrol.Kind = $Subitem_lvl2.icon_kind
                        $SubmenuItem_lvl2_imagecontrol.Foreground = $Subitem_lvl2.icon_color
                        if($Subitem_lvl2.icon_margin){
                          $SubmenuItem_lvl2_imagecontrol.margin = $Subitem_lvl2.icon_margin
                        } 
                        if($trayMenu){
                          #$SubmenuItem_lvl2_imagecontrol.width = "15"
                          #$SubmenuItem_lvl2_imagecontrol.Height = "15" 
                          #$SubmenuItem_lvl2_imagecontrol.margin = "0"                
                        }     
                        $SubmenuItem_lvl2.icon = $SubmenuItem_lvl2_imagecontrol
                      }elseif(-not [string]::IsNullOrEmpty($Subitem_lvl2.icon_image)){                                   
                        #$SubmenuItem_lvl2_imagecontrol = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes($Subitem_lvl2.icon_image)))
                        $stream_image = [System.IO.File]::OpenRead($Subitem_lvl2.icon_image) 
                        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                        $image.BeginInit()
                        $image.CacheOption = "OnLoad"    
                        $image.StreamSource = $stream_image
                        $image.DecodePixelWidth = '18'
                        $image.EndInit();        
                        $stream_image.Close()
                        $stream_image.Dispose()
                        $stream_image = $null
                        $image.Freeze();
                        $SubmenuItem_lvl2_imagecontrol = [System.Windows.Controls.Image]::new()
                        $SubmenuItem_lvl2_imagecontrol.Source = $image
                        if($Subitem_lvl2.icon_margin){
                          $SubmenuItem_lvl2_imagecontrol.margin = $Subitem_lvl2.icon_margin
                        }      
                        $SubmenuItem_lvl2.icon = $SubmenuItem_lvl2_imagecontrol
                      }
                      if(-not [string]::IsNullOrEmpty($subitem_lvl2.binding)){
                        $Binding = [System.Windows.Data.Binding]::new()
                        $Binding.Source = $subitem_lvl2.binding
                        $Binding.Path = $subitem_lvl2.binding_property_path
                        $Binding.Mode = $subitem_lvl2.binding_mode
                        $null = [System.Windows.Data.BindingOperations]::SetBinding($SubmenuItem_lvl2,[System.Windows.Controls.MenuItem]::IsCheckedProperty, $Binding) 
                      } 
                      if(-not [string]::IsNullOrEmpty($Subitem_lvl2.Command)){
                        $SubmenuItem_lvl2.RemoveHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$Subitem_lvl2.Command)
                        $SubmenuItem_lvl2.AddHandler([System.Windows.Controls.Menuitem]::PreviewMouseLeftButtonDownEvent,[System.Windows.RoutedEventHandler]$Subitem_lvl2.Command)               
                      }
                      $null = $SubmenuItem.Items.Add($SubmenuItem_lvl2)
                    }
                  }
                }              
                $null = $menuItem.Items.Add($SubmenuItem)           
              }
            }
          }
          if($addchild){
            $null = $control.AddChild($menuItem)
          }else{
            $null = $contextMenu.Items.Add($menuItem)
          }        
        }
      }
      if($TrayMenu){
        $style = $sourceWindow.Window.TryFindResource('TrayDropDownMenuStyle')
      }else{
        $style = $sourceWindow.Window.TryFindResource("DropDownMenuStyle")
      }
      if($AddContextMenu){
        $contextMenu.Style = $null
        $contextMenu.Style =  $style
        if($AnchorableContextMenu){
          if($control.AnchorableContextMenu){
            [void][System.Windows.Data.BindingOperations]::ClearAllBindings($control.AnchorableContextMenu)
            $control.AnchorableContextMenu = $null
          }
          $control.AnchorableContextMenu = $contextMenu
        }else{
          if($control.ContextMenu){
            [void][System.Windows.Data.BindingOperations]::ClearAllBindings($control.ContextMenu)
            $control.ContextMenu = $null
          }
          $control.ContextMenu = $contextMenu
        }   
      }elseif($addchild){
        $contextMenu.Style =  $style
      }
    }catch{
      write-ezlogs "An exception occurred in Add-WPFMenu for control $($Control.name)" -showtime -catcherror $_
    }   
  }
}
#----------------------------------------------
#endregion Add-WPFMenu
#----------------------------------------------
Export-ModuleMember -Function @('Set-WPFButtons','Open-MiniPlayer','Update-MainPlayer','Update-MainWindow','Set-VideoPlayer','Reset-MainPlayer','Update-MediaState','Add-WPFMenu')