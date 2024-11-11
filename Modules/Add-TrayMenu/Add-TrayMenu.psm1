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
          $synchash.Window.Activate()
          if($SyncHash.Window.WindowState -ne 'Normal'){
            $SyncHash.Window.WindowState = 'Normal'
          }
          $window_active = $synchash.Window.Activate()
          if($synchash.MediaLibraryFloat.isVisible){
            $synchash.MediaLibraryFloat.Activate()
          } 
          if($synchash.VideoViewFloat.isVisible){
            $synchash.VideoViewFloat.Activate()
          }
          if($hashsetup.window.IsInitialized -and ($hashsetup.Window.Visibility -eq 'Visible')){
            Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Show
          }                       
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
      $synchash.TrayPlayer.Icon =  "$($thisApp.Config.current_folder)\Resources\Samson_Icon_NoText1.ico"
      $synchash.TrayPlayer.Visibility = 'Visible'
      $synchash.TrayPlayer.PopupPlacement = 'AbsolutePoint'
      $synchash.TrayPlayer.LeftClickCommand = $OpenTrayPopup_Command

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
                  write-ezlogs "StayOnTopButton_ToggleButton checked"
                  $synchash.MiniPlayer_Viewer.Topmost = $true
                  $thisApp.Config.Mini_Always_On_Top = $true 
                }elseif($synchash.TrayPlayer.isVisible){
                  $synchash.TrayPlayer.CloseTrayPopup()
                  Open-MiniPlayer -thisApp $thisApp -synchash $synchash
                } 
              }else{
                if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.StayOnTopButton_ToggleButton.ToolTip -eq 'Stay On Top'){
                  write-ezlogs "StayOnTopButton_ToggleButton Unchecked"
                  $synchash.MiniPlayer_Viewer.Topmost = $false
                  $thisApp.Config.Mini_Always_On_Top = $false
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
        param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right){
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
        }
      }

      $null = $synchash.TrayPlayerGrid.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.MiniPlayer_ContextMenu)

      $items = [System.Collections.Generic.List[Object]]::new()
      $Open_App = @{
        'Header' = "Open App"
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
      Add-WPFMenu -control $synchash.TrayPlayer -items $items -AddContextMenu -sourceWindow $synchash -TrayMenu

      #$null = $synchash.TrayPlayer.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$OpenApp_Command)
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
      if($StartMini){
        $Window = $synchash.MiniPlayer_Viewer
      }else{
        $window = $synchash.Window
      }
      if(!$synchash.current_Window_Helper -and $Window){
        $synchash.current_Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($window)
      } 
      if($thisApp.Config.Installed_AppID){
        $appid = $thisApp.Config.Installed_AppID
      }else{
        $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID 
        $thisApp.Config.Installed_AppID = $appid
      } 
      if($appid -and -not [string]::IsNullOrEmpty($synchash.current_Window_Helper.Handle) -and $synchash.current_Window_Helper.Handle -ne 0){
        write-ezlogs ">>>> Creating new jumplist for window with handle: $($synchash.current_Window_Helper.Handle)"
        $synchash.jumplist = [Microsoft.WindowsAPICodePack.Taskbar.JumpList]::CreateJumpListForIndividualWindow($appid,$synchash.current_Window_Helper.Handle)
        $synchash.jumplist.KnownCategoryToDisplay = [Microsoft.WindowsAPICodePack.Taskbar.JumpListKnownCategoryType]::Frequent
        $synchash.jumplist.KnownCategoryOrdinalPosition = 1
        #ItemsRemoved Event
        $synchash.jumplist.Add_JumpListItemsRemoved({
            param($sender,[Microsoft.WindowsAPICodePack.Taskbar.UserRemovedJumpListItemsEventArgs]$e)
            try{
              write-ezlogs ">>>> Jumplist item removed by user: $($e | out-string) -- sender: $($sender | out-string)"
            }catch{
              write-ezlogs "An exception occured in jumplist.Add_JumpListItemsRemoved" -catcherror $_
            }
        })
        try{
          [void]$synchash.jumplist.Refresh()
        }catch{
          write-ezlogs "An exception occurred refreshing jumplist: $($synchash.jumplist)" -catcherror $_
        }
      }
    }
  }catch{
    write-ezlogs "An exeception occurred getting current window handle in Add-Jumplist" -CatchError $_
  }finally{
    $synchash.current_Window_Helper = $null
    $synchash.Remove('current_Window_Helper')
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
      $add_Jumplist_Measure = [system.diagnostics.stopwatch]::StartNew()
      if($synchash.jumplist){
        #Tasks
        if($Startup -and [System.IO.File]::Exists($thisApp.Config.App_Exe_Path)){
          write-ezlogs ">>>> Adding New Jumplist" -loglevel 2 
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
            $synchash.jumplist_categoryRecent = [Microsoft.WindowsAPICodePack.Taskbar.JumpListCustomCategory]::new('Recent')
          }
          $HistoryList = [SerializableDictionary[int,string]]::new($thisApp.config.History_Playlist)
          #$HistoryList = $thisApp.config.History_Playlist.psobject.Copy()
          $History_items_toremove = [System.Collections.Generic.List[object]]::new()
          $method = $synchash.jumplist_categoryRecent.gettype().GetMethod('get_JumpListItems',[System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
          $JumplistItems = $method.Invoke($synchash.jumplist_categoryRecent,$Null)
          if($thisApp.Config.App_Exe_Path -in $JumplistItems.path){
            write-ezlogs ">>>> Clearing jumpitems with Path: $($thisApp.Config.App_Exe_Path)"
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
                      if(-not [string]::IsNullOrEmpty($Track.title)){
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
                      #$jumprecent = [Microsoft.WindowsAPICodePack.Taskbar.JumpListLink]::new("$($track.url)",$title)
                      $iconref = [Microsoft.WindowsAPICodePack.Shell.IconReference]::new($icon,0)
                      $jumprecent.IconReference = $iconref
                      $jumprecent.Arguments = "-PlayMedia `"$($Track.url)`""
                      $jumprecent.ShowCommand = 'Show'
                      $jumprecent.WorkingDirectory = $($thisApp.Config.Current_Folder)
                      $null = $synchash.jumplist_categoryRecent.AddJumpListItems($jumprecent) 
                    }elseif(@($Track).count -gt 1){
                      write-ezlogs "Found multiple ($(@($Track).count)) media when attempting to lookup previous played for id $($Last_played)" -warning
                    }else{
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
                  write-ezlogs "Removing invalid or duplicate item index from history $($_)" -warning
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
        write-ezlogs "Add-JumpList Startup" -PerfTimer $add_Jumplist_Measure
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