<#
    .Name
    Initialize-Vlc

    .Version 
    0.1.1

    .SYNOPSIS
    Creates and initializes controls and events for libvlc

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
#region Initialize-Vlc Function
#----------------------------------------------
Function Initialize-VLC
{
  param (
    $synchash,
    $thisApp,
    [switch]$Initalize_EQ,
    [switch]$Startup,
    [switch]$Startup_Playback,
    $VideoView,
    [switch]$NewMediaPlayer
  ) 
  try{
    #if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> Initializing Libvlc" -showtime}
    #$vlc = [LibVLCSharp.Shared.Core]::Initialize("$($thisApp.Config.Current_folder)\Resources\Libvlc")
    #$videoView = [LibVLCSharp.WPF.VideoView]::new()  
    #$libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($thisapp.config.Vlc_Log_file)","--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
    #$libvlc.SetLogFile("$($logfile_directory)\$($thisScript.Name)-$($thisApp.config.App_Version)-VLC.log")


    <#    [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\VideoViewGrid.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
        $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
        $VideoView_Grid = [Windows.Markup.XamlReader]::Load($reader)
        $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$synchash."$($_.Name)" = $VideoView_Grid.FindName($_.Name)}
        if($VideoView.content -ne $synchash.VideoView_Grid){
        $VideoView.addChild($synchash.VideoView_Grid)
    }#>


    if(!$synchash.VLC -and $Startup_Playback){   
      write-ezlogs ">>>> Initializing new lbivlc media player instance for startup playback" -showtime -logtype Libvlc -loglevel 2
      if($thisApp.Config.Libvlc_Version -eq '4'){        
        $synchash.VLC = [System.WeakReference]::new([LibVLCSharp.MediaPlayer]::new($synchash.libvlc)).Target
        if($thisApp.Config.Enable_ChromeCast){
          $synchash.RendererDiscoverer = [LibVLCSharp.RendererDiscoverer]::new($synchash.libvlc)
        }        
      }else{
        $synchash.VLC = [System.WeakReference]::new([LibVLCSharp.Shared.MediaPlayer]::new($synchash.libvlc)).Target
      }
      #Chromecast
      if($thisApp.Config.Enable_ChromeCast){
        $synchash.RendererDiscoverer = [LibVLCSharp.Shared.RendererDiscoverer]::new($synchash.libvlc)
        $synchash.RendererDiscoverer.add_ItemAdded({
            [LibVLCSharp.Shared.RendererDiscovererItemAddedEventArgs]$e = $args[1]
            try{
              write-ezlogs "RendererDiscoverer Item added $($e.RendererItem | out-string)" -Warning -logtype Libvlc
              [void]$synchash.renderitems.add($e.RendererItem)
            }catch{
              write-ezlogs "An exception occurred in RendererDiscoverer.add_ItemAdded"
            }
        })
        $synchash.RendererDiscoverer.add_ItemDeleted({
            [LibVLCSharp.Shared.RendererDiscovererItemAddedEventArgs]$e = $args[1]
            try{
              write-ezlogs "RendererDiscoverer Item Removed: $($e.RendererItem | out-string)" -Warning -logtype Libvlc
              if($synchash.renderitems -contains $e.RendererItem){
                write-ezlogs "Removing from renderitems list" -Warning
                [void]$synchash.renderitems.Remove($e.RendererItem)
              }           
            }catch{
              write-ezlogs "An exception occurred in RendererDiscoverer.add_ItemDeleted"
            }
        })
        [void]$synchash.RendererDiscoverer.start()
      }

      
      #Prevent vlc from catching input events
      $synchash.VLC.EnableKeyInput = $false
      #$synchash.VLC.EnableMouseInput = $false

      Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp
      if($thisapp.config.Current_Audio_Output -and $synchash.vlc.AudioOutputDeviceEnum){
        $device = $synchash.vlc.AudioOutputDeviceEnum.where({$_.Description -eq $thisapp.config.Current_Audio_Output})
        if($device){
          $setOutputDevice = $synchash.vlc.SetOutputDevice($device.deviceidentifier)
          if($setOutputDevice){
            if($thisApp.Config.Dev_mode){write-ezlogs "Successfully set audio output device for vlc to: $($device.Description)" -logtype Libvlc -Dev_mode}
          }else{
            if($thisApp.Config.Dev_mode){write-ezlogs "Unable to set audio output device for vlc to $($device.Description)" -warning -logtype Libvlc -Dev_mode}
          }
        }     
      }
    }
    if($startup -and $synchash.Volume_Slider -and -not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume)){
      write-ezlogs "[VLC_STARTUP] | Setting Volume_Slider Value to Config.Media_Volume: $($thisapp.Config.Media_Volume)" -loglevel 2 -logtype Libvlc
      $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
    }
    if(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
      if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
        write-ezlogs "[VLC_STARTUP] | Setting vlc volume to Volume_Slider Value: $($synchash.Volume_Slider.value)" -loglevel 2 -logtype Libvlc
        if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
        }else{
          $synchash.vlc.Volume = $synchash.Volume_Slider.value
        }
      }         
    }elseif(-not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume) -and $synchash.vlc -and $synchash.vlc.Volume -ne $thisapp.Config.Media_Volume){
      write-ezlogs "[VLC_STARTUP] | Setting vlc volume to Config Media Volume: $($thisapp.Config.Media_Volume)" -loglevel 2 -logtype Libvlc
      $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
      if($thisApp.Config.Libvlc_Version -eq '4'){
        $synchash.vlc.SetVolume($thisapp.Config.Media_Volume)
      }else{
        $synchash.vlc.Volume = $thisapp.Config.Media_Volume
      }
    }else{
      write-ezlogs "[VLC_STARTUP] | Volume level unknown??: $($synchash.Volume_Slider.value)" -loglevel 2 -Warning -logtype Libvlc
      $thisapp.Config.Media_Volume = 100
    }
    if($synchash.VideoView_Mute_Icon){
      if($synchash.Volume_Slider.value -ge 75){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
        $synchash.MuteButton_ToggleButton.isChecked = $false
      }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
        $synchash.MuteButton_ToggleButton.isChecked = $false
      }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
        $synchash.MuteButton_ToggleButton.isChecked = $false
      }elseif($synchash.Volume_Slider.value -le 0 -or $synchash.vlc.mute -or $thisApp.Config.Media_Muted){
        $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
        $synchash.MuteButton_ToggleButton.isChecked = $true
      }
    }
    if($VideoView -and $synchash.VLC){    
      $VideoView.MediaPlayer = $synchash.VLC
    }
    if($synchash.VLC_Grid.Visibility -ne 'Visible'){
      $synchash.VLC_Grid.Visibility = 'Visible'
    }
    if($Initalize_EQ){
      $synchash.Initialize_EQ_timer.tag = $Startup_Playback
      $synchash.Initialize_EQ_timer.start()
    }
    if($synchash.VideoView){
      $synchash.VideoView_IsVisibleChanged_Command = {
        param($sender)
        try{
          if($synchash.VideoView.Visibility -in 'Hidden','Collapsed'){
            write-ezlogs ">>>> Video View is: $($synchash.VideoView.Visibility)" -showtime -warning
            if($synchash.VideoView_Grid -and $synchash.VideoView_Grid.Visibility -eq 'Visible'){
              write-ezlogs "| hiding VideoView_Grid" -showtime -warning
              $synchash.VideoView_Grid.Visibility = 'Collapsed'        
            }                        
          }elseif($synchash.VideoView.Visibility -eq 'Visible'){            
            if($synchash.VideoView_Grid.Visibility -in 'Hidden','Collapsed'){
              write-ezlogs ">>>> Video View is Visible, setting VideoView_Grid to Visible" -showtime -warning -Dev_mode
              $synchash.VideoView_Grid.Visibility = 'Visible'
            }
            if($synchash.VideoView_Overlay_Grid.Visibility -in 'Hidden','Collapsed'){
              write-ezlogs ">>>> Video View is Visible, setting VideoView_Overlay_Grid to Visible" -showtime -warning
              $synchash.VideoView_Overlay_Grid.Visibility = 'Visible'
            }
            if(!$synchash.vlc.IsPlaying -and !$synchash.VideoView_Grid.Parent.Parent.AllowsTransparency -and $thisApp.Config.Enable_YoutubeComments -and $synchash.VideoView_Grid.Parent.Parent -is [System.Windows.Window]){
              #TODO: Fixes the issue where libvlc video player window background sometimes becomes solid white or flashes white if AllowsTransparency  is false on floating window
              #https://code.videolan.org/videolan/LibVLCSharp/-/issues/555
              write-ezlogs "| Calling Hide() then Show() on VideoView floating window to prevent background from becoming solid white" -showtime -warning
              $synchash.VideoView_Grid.Parent.Parent.hide()
              $synchash.VideoView_Grid.Parent.Parent.Show()
            }
          }
        }catch{
          write-ezlogs "An exception occurred in videoView.add_IsVisibleChanged" -showtime -catcherror $_
        }
      }
      [void]$synchash.VideoView.Remove_IsVisibleChanged($synchash.VideoView_IsVisibleChanged_Command)
      [void]$synchash.VideoView.add_IsVisibleChanged($synchash.VideoView_IsVisibleChanged_Command)
    }
  }catch{
    write-ezlogs 'An exception occurred An exception occurred initializing libvlc' -showtime -catcherror $_
  } 

}
#---------------------------------------------- 
#endregion Initialize-Vlc Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-EQ Function
#----------------------------------------------
Function Initialize-EQ
{
  param (
    $synchash,
    $thisApp,
    [switch]$Startup_Playback
  ) 
  try{
    write-ezlogs ">>>> Initialize-EQ Startup -- Startup_Playback: $Startup_Playback" -loglevel 2 -logtype Libvlc
    #EQ Preset Routed Event
    $audio_media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)flac|(?i)wav|(?i)3gp|(?i)aac))') 
    [System.Windows.RoutedEventHandler]$Synchash.EQPreset_Menuitem_Command = {
      param($sender)
      try{     
        if($sender.parent.parent.PlacementTarget.parent.parent.TemplatedParent.Name -eq 'DeletePreset_Button'){
          if($synchash.AudioOptions_Viewer.isVisible){
            $window = $synchash.AudioOptions_Viewer
          }else{
            $window = $synchash.Window
          }
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_Settings.AffirmativeButtonText = 'Yes'
          $Button_Settings.NegativeButtonText = 'No'  
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Delete Preset $($this.Header)","Are you sure you wish to delete the EQ Preset: $($this.Header)?",$okandCancel,$Button_Settings)
          if($result -eq 'Affirmative'){
            write-ezlogs ">>>> User wishes to delete the preset $($this.Header)" -showtime -logtype Libvlc -loglevel 2
            Remove-EQPreset -PresetName $this.Header -thisApp $thisApp -EQPreset_Profile_Directory $thisApp.config.EQPreset_Profile_Directory -synchash $synchash -Verboselog:$thisApp.Config.Verbose_logging
            if(-not [string]::IsNullOrEmpty($thisapp.config.EQ_Selected_Preset) -and $thisApp.Config.EQ_Selected_Preset -eq $this.Header){
              Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value '' -MemberType NoteProperty -Force
              $synchash.EQ_Timer.start()
            }         
            if($synchash.CurrentSaveMenuItem.Header -eq "Save as '$($this.Header)'"){
              $synchash.CurrentSaveMenuItem.Header = ""
              $synchash.CurrentSaveMenuItem.Height = '0'
              $synchash.CurrentSaveMenuItem.Uid = $Null
            }
            $PresetitemToRemove = $synchash.LoadPreset_Button.items | where {$_.Header -eq $this.Header}
            if($PresetitemToRemove){
              [void]$synchash.LoadPreset_Button.items.remove($PresetitemToRemove)
            }
            [void]$synchash.DeletePreset_Button.items.remove($this)
          }else{
            write-ezlogs "User did not wish to delete the preset $($this.Header)" -warning -showtime -logtype Libvlc
          }
        }else{
          foreach($item in $synchash.LoadPreset_Button.items){
            if($item -eq $this){
              $item.isChecked = $true
            }elseif($item.isChecked){
              $item.isChecked = $false
            }
          }
          Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value $this.Header -MemberType NoteProperty -Force
          $synchash.EQ_Timer.start()
          foreach($preset in $thisapp.config.EQ_Presets){
            if($synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton" -and $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton".IsChecked){                   
              $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton".IsChecked = $false
            }              
          }
          if($synchash.EQ_CustomPreset1_ToggleButton.isChecked){
            $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
          }elseif($synchash.EQ_CustomPreset2_ToggleButton.isChecked){
            $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
          }
          if($synchash.CurrentSaveMenuItem){
            if(-not [string]::IsNullOrEmpty($thisapp.config.EQ_Selected_Preset)){
              $synchash.CurrentSaveMenuItem.Header = "Save as '$($thisapp.config.EQ_Selected_Preset)'"
              $synchash.CurrentSaveMenuItem.Height = [double]::NaN
              $synchash.CurrentSaveMenuItem.Uid = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset}).Preset_ID
            }else{
              $synchash.CurrentSaveMenuItem.Header = ""
              $synchash.CurrentSaveMenuItem.Height = '0'
              $synchash.CurrentSaveMenuItem.Uid = $Null
            }
          }
        }
      }catch{
        write-ezlogs "An exception occurred in EQPreset_Menuitem_Command routed event" -showtime -catcherror $_
      }
    }

    [System.Windows.RoutedEventHandler]$Synchash.EQPreset_Button_Command = {
      param($sender)
      try{                
        if($sender -eq $synchash.EQ_CustomPreset1_ToggleButton -or $sender -eq $synchash.EQ_CustomPreset2_ToggleButton){
          $Selected_Preset = ($thisapp.config.Custom_EQ_Presets | Where-Object {$_.Preset_Name -eq $sender.tag})                 
        }else{
          $Selected_Preset = $thisapp.config.EQ_Presets | Where-Object {$_.Preset_ID -ne $null -and $_.Preset_ID -eq $sender.Uid}
        }        
        if($sender.IsChecked -and $Selected_Preset.Preset_Name){   
          $thisApp.Config.EQ_Selected_Preset = $Selected_Preset.Preset_Name
        }else{
          $sender.IsChecked = $false
          $thisApp.Config.EQ_Selected_Preset = ''
        }       
        foreach($preset in $thisapp.config.EQ_Presets){
          if($synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton" -and $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton" -ne $sender){                  
            $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton".IsChecked = $false
          }              
        }                              
        $synchash.EQ_Timer.start()
        if($sender -eq $synchash.EQ_CustomPreset1_ToggleButton){
          $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
        }else{
          $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
        }
        if($sender -eq $synchash.EQ_CustomPreset2_ToggleButton){
          $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
        }else{
          $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
        }        
        foreach($item in $synchash.LoadPreset_Button.items){
          if($item.isChecked){
            $item.isChecked = $false
          }
        }
        if($synchash.CurrentSaveMenuItem){
          $synchash.CurrentSaveMenuItem.Header = ""
          $synchash.CurrentSaveMenuItem.Height = '0'
          $synchash.CurrentSaveMenuItem.Uid = $Null
        }
      }catch{
        write-ezlogs "An exception occurred in EQPreset_Menuitem_Command routed event" -showtime -catcherror $_
      }
    }

    #EQ Settings
    if($thisApp.Config.Libvlc_Version -eq '4'){
      $Equalizer = [LibVLCSharp.Equalizer]::new()
    }else{
      $Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
    }   
    $bandcount = $Equalizer.BandCount
    $preset_Count = $Equalizer.PresetCount
    [System.Collections.Generic.List[EQ_Preset]]$eq_presets = 0..$preset_Count | & { process {
        if(-not [string]::IsNullOrEmpty($Equalizer.PresetName($_))){
          $PresetName = $Equalizer.PresetName($_)
          $newRow = [EQ_Preset]@{
            'Preset_Name' = $PresetName
            'Preset_ID' = $_
          }
          if($thisApp.Config.Dev_mode){write-ezlogs "Adding Fixed Preset Name: $($PresetName) - Preset ID: $($_)" -showtime -logtype Libvlc -Dev_mode}
          if($synchash."EQ_Preset_$($_)_ToggleButton"){         
            [void]$synchash."EQ_Preset_$($_)_ToggleButton".AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.EQPreset_Button_Command)
            if($thisApp.Config.EQ_Selected_Preset -eq $PresetName){
              $synchash."EQ_Preset_$($_)_ToggleButton".IsChecked = $true
            }
          }
          $newRow
        }
    }}
    $thisapp.config.EQ_Presets = $eq_presets
  
    #eq Bands
    try{
      [System.Collections.Generic.List[EQ_Band]]$eq_bands = 0..$bandcount | & { process {
          $bandvalue = $null
          if($Equalizer.BandFrequency($_) -ne -1){  
            if($thisapp.Config.EQ_Bands){
              $Configured_Band = $thisapp.Config.EQ_Bands[$thisapp.Config.EQ_Bands.Band_ID.IndexOf($_)]
            }
            #$Configured_Band = $thisapp.Config.EQ_Bands | where {$_.Band_ID -eq $band_id}
            if($Configured_Band.Band_Value  -ne $null){$bandvalue = $Configured_Band.Band_Value}else{$bandvalue = 0}
            $newRow = [EQ_Band]@{
              'Band' = $Equalizer.BandFrequency($_)
              'Band_Name' = "EQ_$($_)"
              'Band_ID' = $_
              'Band_Value' = $bandvalue
            }
            $frequency_name = $null
            if($synchash."EQ_$($_)"){            
              if($($Equalizer.BandFrequency($_)  / 1000) -lt 1){$frequency_name = "$([math]::Round($Equalizer.BandFrequency($_),1))Hz"}else{$frequency_name = "$([math]::Round($Equalizer.BandFrequency($_)/1000,1))kHz"}
              write-ezlogs "Setting band frequency $frequency_name" -showtime -logtype Libvlc -loglevel 4
              $synchash."EQ_$($_)_Text".text = $frequency_name
              if($Configured_Band.Band_Value -ne $null){
                $synchash."EQ_$($_)".Value = $Configured_Band.Band_Value
              }else{
                $synchash."EQ_$($_)".Value = 0
              }
              $synchash."EQ_$($_)".Add_ValueChanged({
                  $Band_to_modify = $thisapp.Config.EQ_Bands[$thisapp.Config.EQ_Bands.Band_Name.IndexOf($this.Name)]
                  #$Band_to_modify = $thisapp.config.EQ_Bands | where {$_.Band_Name -eq $this.Name}
                  if($Band_to_modify){ 
                    try{
                      $Band_to_modify.Band_Value = $this.Value
                      if($synchash.Equalizer -ne $null){
                        $current_band_value = $synchash.Equalizer.Amp($Band_to_modify.Band_ID)
                        if($current_band_value -ne $this.Value){
                          [void]$synchash.Equalizer.SetAmp($this.Value,$Band_to_modify.Band_ID)                    
                          write-ezlogs " | Set New value $($this.Value)" -showtime -logtype Libvlc -loglevel 4 
                          if($thisapp.config.Enable_EQ){[void]$synchash.vlc.SetEqualizer($synchash.Equalizer)}                     
                        }
                      }else{
                        write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc
                        if($thisApp.Config.Libvlc_Version -eq '4'){
                          $synchash.Equalizer = [LibVLCSharp.Equalizer]::new()
                        }else{
                          $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
                        } 
                        $synchash.Equalizer.SetAmp($this.Value,$Band_to_modify.Band_ID)                      
                        if($thisapp.Config.EQ_Preamp -ne $null){
                          [void]$synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)
                        }else{
                          [void]$synchash.Equalizer.SetPreamp(12)
                          $synchash.Preamp_Slider.value = 12
                          $thisApp.Config.EQ_Preamp = 12
                        }                 
                        if($thisapp.config.Enable_EQ -and $synchash.vlc){
                          [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)
                        }                  
                      }
                      if($synchash.current_soundout.PlaybackState -eq 'Playing' -and $synchash.Current_VirtualEQ.WaveFormat){
                        try{
                          $Cscore_Band = $synchash.Current_VirtualEQ.SampleFilters.Item($Band_to_modify.Band_ID)
                        }catch{
                          $Cscore_Band = $Null
                        }
                        if($Cscore_Band -ne $Null){
                          $Cscore_Band.AverageGainDB = $this.Value
                        }
                      }
                    }catch{
                      write-ezlogs "An exception occurred changing value in $($synchash."EQ_$($_)") to $($this.Value)" -showtime -catcherror $_
                    }
                  }
              })       
            }
            $newRow
          }
      }}
      $thisapp.config.EQ_Bands = $eq_bands
    }catch{
      write-ezlogs "An exception occurred applying current EQ Bands" -catcherror $_
    }
    if($synchash.Enable_EQ_Toggle){
      if($thisapp.config.Enable_EQ){
        $synchash.Enable_EQ_Toggle.isChecked = $true     
        if($thisApp.Config.Current_Theme.PrimaryAccentColor){
          $synchash.Audio_Flyout.Tag = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
        }else{
          $synchash.Audio_Flyout.Tag = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
        }
      }else{
        $synchash.Enable_EQ_Toggle.isChecked  = $false
        $synchash.Audio_Flyout.Tag = "#FF535455"
      }
      $synchash.Enable_EQ_Toggle.Add_Checked({
          try{
            if($synchash.Enable_EQ_Toggle.isChecked){    
              if(!$synchash.Equalizer){
                write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc
                if($thisApp.Config.Libvlc_Version -eq '4'){
                  $synchash.Equalizer = [LibVLCSharp.Equalizer]::new()
                }else{
                  $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
                } 
              }      
              if($synchash.vlc){
                if($thisapp.Config.EQ_Preamp -ne $null){
                  write-ezlogs "| Setting Preamp to: $($thisapp.Config.EQ_Preamp)" -loglevel 2 -logtype Libvlc
                  $synchash.Preamp_Slider.value = $thisapp.Config.EQ_Preamp
                  [void]$synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)
                }else{
                  write-ezlogs "| Setting Preamp to default: 12" -loglevel 2 -logtype Libvlc
                  [void]$synchash.Equalizer.SetPreamp(12)
                }              
                [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)              
              }else{
                write-ezlogs "Libvlc is not initialized!" -showtime -warning -logtype Libvlc
              }                      
              if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                $synchash.Audio_Flyout.Tag = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
              }else{
                $synchash.Audio_Flyout.Tag = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
              }
              if((($synchash.Spotify_WebPlayer_title -and $thisApp.Config.Spotify_WebPlayer) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title))){
                Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -wait -Startlibvlc
              }elseif($thisapp.Config.Import_Spotify_Media -and $thisApp.Config.Use_Spicetify -and ($synchash.Spicetify.is_playing -or $synchash.Spotify_Status -eq 'Playing')){
                Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -wait -Startlibvlc -ProcessName 'spotify.exe'
              }
              write-ezlogs ">>>> EQ Enabled - Preamp: $($synchash.Equalizer.preamp)" -showtime -logtype Libvlc -loglevel 2
              $thisapp.config.Enable_EQ = $true
            }      
          }catch{
            write-ezlogs "An exception occurred in Enable_EQ_Toggle Checked event" -showtime -catcherror $_
          }
      })
      $synchash.Enable_EQ_Toggle.Add_UnChecked({
          try{
            if($synchash.vlc){
              write-ezlogs ">>>> Disabling EQ!" -showtime -logtype Libvlc
              [void]$synchash.vlc.UnsetEqualizer()
            }else{
              write-ezlogs "Libvlc is not initialized!" -showtime -warning -logtype Libvlc
            }
            $thisapp.config.Enable_EQ = $false
            if($synchash.Audio_Flyout){
              $synchash.Audio_Flyout.Tag = "#FF535455"
            }
            if($synchash.Enable_EQ2Pass_Toggle.isChecked){
              $synchash.Enable_EQ2Pass_Toggle.isChecked  = $false
            }                                  
            if((($synchash.Spotify_WebPlayer_title -and $thisApp.Config.Spotify_WebPlayer) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title))){
              write-ezlogs "| Stopping ApplicationAudioDevice routing for EQ"
              Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -stop -Stoplibvlc
            }
            if($synchash.Equalizer){
              write-ezlogs "| Disposing Equalizer" -showtime -logtype Libvlc
              $synchash.Equalizer.Dispose()
              $synchash.Equalizer = $Null
            }                              
          }catch{
            write-ezlogs "An exception occurred in Enable_EQ_Toggle UnChecked event" -showtime -catcherror $_
          }
      })
    }
    if($synchash.EQPower_ToggleButton){
      $synchash.EQPower_ToggleButton.add_Click({
          Param($sender)
          try{               
            write-ezlogs ">>>> Closing Audio Options Viewer" -showtime
            $synchash.AudioButton_ToggleButton.isChecked = $false
            $synchash.AudioOptions_Viewer.close()
          }catch{
            write-ezlogs "An exception occurred in EQPower_ToggleButton.add_Click" -catcherror $_
          }
      })
    }
    if($synchash.Enable_EQWeb_Toggle){
      if($thisapp.config.Enable_WebEQSupport){
        $synchash.Enable_EQWeb_Toggle.isEnabled = $true
      }else{
        $synchash.Enable_EQWeb_Toggle.isEnabled = $false
      }
      $synchash.Enable_EQWeb_Toggle.Add_Checked({
          try{
            if($synchash.Enable_EQWeb_Toggle.isChecked -and $thisapp.config.Enable_WebEQSupport){    
              if(!$synchash.vlc.isPlaying -and ($synchash.current_soundout.PlaybackState -ne 'Playing' -and !$synchash.Current_VirtualEQ.WaveFormat)){
                try{
                  Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -Startlibvlc
                }catch{
                  write-ezlogs "An exception occurred enabling EQ for Cscore virtual EQ - current soundout: $($synchash.current_soundout | out-string)" -catcherror $_
                }
              }                      
            }      
          }catch{
            write-ezlogs "An exception occurred in Enable_EQWeb_Toggle Checked event" -showtime -catcherror $_
          }
      })
      $synchash.Enable_EQWeb_Toggle.Add_UnChecked({
          try{ 
            if(($synchash.current_soundout.PlaybackState -eq 'Playing' -and $synchash.Current_VirtualEQ.WaveFormat)){
              try{
                Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -stop
              }catch{
                write-ezlogs "An exception occurred disabling EQ for Cscore virtual EQ - current soundout: $($synchash.current_soundout | out-string)" -catcherror $_
              }
            }                                      
          }catch{
            write-ezlogs "An exception occurred in Enable_EQWeb_Toggle Checked event" -showtime -catcherror $_
          }
      })
    }


    #2pass
    if($synchash.Enable_EQ2Pass_Toggle){
      if($thisapp.config.Enable_EQ2Pass){
        $synchash.Enable_EQ2Pass_Toggle.isChecked = $true
      }else{
        $synchash.Enable_EQ2Pass_Toggle.isChecked  = $false
      }
      $synchash.Enable_EQ2Pass_Toggle.Tooltip="Filters the audio twice. This provides a more intense effect.`nEqualizer must be enabled"

      $synchash.Enable_EQ2Pass_Toggle.add_Click({
          try{
            Update-LibVLC -thisApp $thisApp -synchash $synchash                 
          }catch{
            write-ezlogs "An exception occurred in Enable_EQ2Pass_Toggle addclick event" -showtime -catcherror $_
          }
      })
    }

    #Import Presets
    [System.Windows.RoutedEventHandler]$synchash.EQPreset_Import_Command  = {
      param($sender)
      try{
        $synchash = $synchash
        $thisApp = $thisApp
        $result = Open-FileDialog -Title "Select the EQ Preset file you wish to import"  -filter "XML Files (*.xml)|*.xml" -CheckPathExists
        if([system.io.file]::Exists($result)){ 
          $Preset_Directory_Path = [System.IO.Path]::Combine($thisApp.config.EQPreset_Profile_Directory,'Custom-EQPresets')
          if(![System.IO.Directory]::Exists($Preset_Directory_Path)){
            [void][System.IO.Directory]::CreateDirectory($Preset_Directory_Path)
          }
          $EQ_Preset = Import-Clixml $result
          $Preset_Path_Name = "$($EQ_Preset.Preset_Name)-Custom-EQPreset.xml" 
          $Import_Preset_Destination_path =  [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)
          if($synchash.AudioOptions_Viewer.isVisible){
            $window = $synchash.AudioOptions_Viewer
          }else{
            $window = $synchash.Window
          }
          if([string]::IsNullOrEmpty($EQ_Preset.Preset_ID)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Invalid Preset!","The file ($($result)) does not appear to be a valid EQ Preset that can be imported",$okandCancel,$Button_Settings)
            return
          }elseif($thisapp.config.EQ_Presets.Preset_Name -contains  $EQ_Preset.Preset_Name){
            write-ezlogs "The imported preset name ($($EQ_Preset.Preset_Name)) matches the name of one of the Fixed Presets. Fixed Presets cannot be overwritten. Sorry!" -showtime -warning -logtype Libvlc
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Invalid Preset Name!","The preset name you provided ($($EQ_Preset.Preset_Name)) matches the name of one of the Fixed Presets.`n`nFixed Presets cannot be overwritten (Sorry!), please provided a different name",$okandCancel,$Button_Settings) 
            return 
          }elseif($thisapp.config.Custom_EQ_Presets.Preset_Name -contains $EQ_Preset.Preset_Name -or [system.io.file]::Exists($Import_Preset_Destination_path)){       
            $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
            $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
            $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
            $synchash.EQCustomDialog  = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($window)
            [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\Dialog.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
            $reader = [System.Xml.XmlNodeReader]::new($xaml)
            $synchash.EQDialogWindow = [Windows.Markup.XamlReader]::Load($reader)
            $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | & { process {$synchash."$($_.Name)" = $synchash.EQDialogWindow.FindName($_.Name)}}
            $reader.dispose()
            $synchash.EQCustomDialog.AddChild($synchash.EQDialogWindow)
            $synchash.DialogButtonClose.Content = "No"
            $synchash.DialogButtonClose.add_click({
                try{               
                  write-ezlogs "User did not wish to overwrite playlist $($EQ_Preset.Preset_Name)" -showtime -logtype Libvlc
                  $synchash.EQDialogBrowse_Result = $null
                  [void]$synchash.Remove('EQDialogBrowse_Result')
                  $synchash.SetEQasActive = $false
                  $synchash.EQCustomDialog.RequestCloseAsync()
                  return
                }catch{
                  write-ezlogs "An exception occurred in DialogButtonClose.add_click" -catcherror $_
                }
            })
            $synchash.Dialog_Local_File_Textbox.IsEnabled = $false
            $synchash.Dialog_Local_File_Textbox.Visibility = 'Hidden'
            $synchash.Dialog_Remote_URL_Textbox.IsEnabled = $false
            $synchash.Dialog_Remote_URL_Textbox.Visibility = 'Hidden'
            $synchash.Dialog_WebURL_Label.content = ""
            $synchash.Dialog_WebURL_Label.Visibility = 'Hidden'
            $synchash.Dialog_Browse_Label.content = ""
            $synchash.Dialog_Browse_Label.Visibility = 'Hidden'                      
            $synchash.Dialog_Remote_URL_Textbox.MaxWidth="0"
            $synchash.Dialog_Local_File_Textbox.MaxWidth="0"
            $synchash.Dialog_Remote_URL_Textbox.Margin="82,0,0,0"
            $synchash.Dialog_Browse_Label.Visibility = 'Hidden'
            $synchash.Dialog_Browse_Label.Width="0"
            #$synchash.Dialog_RootStackPanel.Width = "500"
            $synchash.Dialog_Local_File_Textbox.Margin="10,0,0,0"
            $synchash.Dialog_Title_Label.content = "A custom preset with name ($($EQ_Preset.Preset_Name)) already exists. Do you wish to overwrite it with the imported preset?"
            $synchash.Dialog_Add_Button.Content="Yes"
            $synchash.Dialog_Browse_Button.Visibility = 'Hidden'
            $synchash.Dialog_StartPlayback_Toggle.Content = "Set as Active Preset"
            $synchash.Dialog_Separator_Label.Content = ''
            $synchash.EQDialogBrowse_Result = $result
            $synchash.Dialog_Add_Button.add_click({
                try{               
                  $EQ_Preset = Import-Clixml $synchash.EQDialogBrowse_Result
                  $Preset_Path_Name = "$($EQ_Preset.Preset_Name)-Custom-EQPreset.xml" 
                  $Import_Preset_Destination_path =  [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)
                  write-ezlogs "User wished to overwrite EQ Preset: $($EQ_Preset.Preset_Name)" -showtime -logtype Libvlc
                  $synchash.SetEQasActive = $synchash.Dialog_StartPlayback_Toggle.isOn
                  $synchash.EQCustomDialog.RequestCloseAsync()
                  write-ezlogs ">>>> Saving imported preset to $Import_Preset_Destination_path" -showtime -logtype Libvlc
                  $new_preset = Add-EQPreset -PresetName $($EQ_Preset.Preset_Name) -EQ_Bands $($EQ_Preset.EQ_Bands) -EQ_Preamp $EQ_Preset.EQ_Preamp -thisApp $thisapp -synchash $synchash -verboselog -Apply_EQ
                  $synchash.EQCustomDialog = $Null
                  if($xaml){                   
                    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | & { process {
                        if($synchash.keys -contains "$($_.Name)"){
                          write-ezlogs " | Removing key from synchash: $($_.Name)" -logtype Libvlc
                          [void]$synchash.Remove($_.Name)                    
                        }  
                    }}
                  }
                  $synchash.EQDialogBrowse_Result = $null
                  [void]$synchash.Remove('EQDialogBrowse_Result')
                }catch{
                  write-ezlogs "An exception occurred in DialogButtonClose.add_click" -catcherror $_
                }
            })
            $dialog = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($window, $synchash.EQCustomDialog, $CustomDialog_Settings)
          }else{
            write-ezlogs ">>>> Saving imported preset to $Import_Preset_Destination_path" -showtime -logtype Libvlc
            $new_preset = Add-EQPreset -PresetName $($EQ_Preset.Preset_Name) -EQ_Bands $($EQ_Preset.EQ_Bands) -EQ_Preamp $EQ_Preset.EQ_Preamp -thisApp $thisapp -synchash $synchash -verboselog -Apply_EQ
          }
        }else{
          write-ezlogs "No valid EQ Preset to import was found at $($result)" -showtime -warning
        }                          
      }catch{
        write-ezlogs "An exception occurred in EQPreset_Import_Command routed event" -showtime -catcherror $_
      }
    }

    if($synchash.LoadPreset_Button -and $synchash.LoadPreset_Button.items.header -notcontains 'Import Preset'){
      $Menuitem = [System.Windows.Controls.MenuItem]::new()
      $Menuitem.IsCheckable = $false
      $Menuitem.Header = 'Import Preset'
      $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
      $menuItem_imagecontrol.Foreground = "White"
      $menuItem_imagecontrol.width = "16"
      $menuItem_imagecontrol.Height = "16"
      $menuItem_imagecontrol.Kind = 'TrayArrowDown'
      $Menuitem.Icon = $menuItem_imagecontrol
      $menuItem_imagecontrol = $Null
      [void]$Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Import_Command)
      [void]$Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Import_Command)
      [void]$synchash.LoadPreset_Button.items.add($Menuitem)
      $menu_separator = [System.Windows.Controls.Separator]::new()
      $menu_separator.OpacityMask = $synchash.Window.TryFindResource('SeparatorGradient')
      if($synchash.LoadPreset_Button.items -notcontains $menu_separator){
        [void]$synchash.LoadPreset_Button.items.add($menu_separator)
      }      
    }
    #custom EQ presets
    if($synchash.LoadPreset){    
      $synchash.LoadPreset.Source = "$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png"
      #$synchash.LoadPreset.Source.Freeze()
    }
    if($synchash.SavePreset){    
      $synchash.SavePreset.Source = "$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png"
      #$synchash.SavePreset.Source.Freeze()
    }
    if($synchash.DeletePreset){    
      $synchash.DeletePreset.Source = "$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png"
      #$synchash.DeletePreset.Source.Freeze()
    }
    if($synchash.ResetEQ){    
      $synchash.ResetEQ.Source = "$($thisApp.Config.Current_Folder)\Resources\Skins\MonitorButton.png"
      #$synchash.ResetEQ.Source.Freeze()
    }
    if($thisapp.config.Custom_EQ_Presets.Preset_Name -and $synchash.LoadPreset_Button){
      foreach($preset in $thisapp.config.Custom_EQ_Presets){
        if($synchash.LoadPreset_Button.items.header -notcontains $preset.Preset_Name -and $preset.Preset_Name -ne 'Memory 1' -and $preset.Preset_Name -ne 'Memory 2' -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $preset.Preset_Name){
          $Menuitem = [System.Windows.Controls.MenuItem]::new()
          $Menuitem.IsCheckable = $true
          $Menuitem.Header = $preset.Preset_Name
          if($thisapp.config.EQ_Selected_Preset -eq $Menuitem.Header){
            $Menuitem.isChecked = $true
          }
          [void]$Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
          [void]$Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
          [void]$synchash.LoadPreset_Button.items.add($Menuitem)     
        }
        if($synchash.DeletePreset_Button.items.header -notcontains $preset.Preset_Name -and $preset.Preset_Name -ne 'Memory 1' -and $preset.Preset_Name -ne 'Memory 2' -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $preset.Preset_Name){
          $deleteMenuitem = [System.Windows.Controls.MenuItem]::new()
          $deleteMenuitem.IsCheckable = $false
          $deleteMenuitem.Header = $preset.Preset_Name
          [void]$deleteMenuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
          [void]$deleteMenuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
          [void]$synchash.DeletePreset_Button.items.add($deleteMenuitem) 
        }                  
      }
      if($synchash.EQ_CustomPreset1_ToggleButton -and $synchash.EQ_CustomPreset2_ToggleButton){
        if($thisapp.config.EQ_Selected_Preset -eq 'Memory 1'){
          $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $true
        }elseif($thisapp.config.EQ_Selected_Preset -eq 'Memory 2'){
          $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $true
        }
      }
    }

    #Save Presets
    [System.Windows.RoutedEventHandler]$synchash.SaveMenuItem_Command  = {
      param($sender)
      try{
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
        $pattern = "[$illegal]"
        write-ezlogs "SaveMenuItem command: $($sender.header)" -showtime -logtype Libvlc
        if($sender -eq $synchash.CurrentSaveMenuItem -and [string]::IsNullOrEmpty($sender.header)){
          write-ezlogs "CurrentSaveMenuItem is currently empty" -showtime -warning -logtype Libvlc
          return
        }elseif($sender -eq $synchash.CurrentSaveMenuItem){          
          $PresetName = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_ID -eq $synchash.CurrentSaveMenuItem.Uid}).Preset_Name
        }elseif($sender.Header -eq 'Save to Memory 1'){
          $PresetName = 'Memory 1'
        }elseif($sender.Header -eq 'Save to Memory 2'){
          $PresetName = 'Memory 2'
        }else{
          if($synchash.AudioOptions_Viewer.isVisible){
            $window = $synchash.AudioOptions_Viewer
          }else{
            $window = $synchash.Window
          }
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
          $PresetName = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($window,'Save Preset','Enter the name for the new preset',$Button_Settings)
          [int]$character_Count = ($PresetName | measure-object -Character -ErrorAction SilentlyContinue).Characters
          if([int]$character_Count -ge 75){
            write-ezlogs "Preset name too long! ($character_Count characters). Please choose a name 75 characters or less " -showtime -warning -logtype Libvlc
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Invalid Preset Name!","The Preset name is too long! (Count: $character_Count). Please choose a name with 100 characters or less",$okandCancel,$Button_Settings) 
            return 
          }
          if($PresetName -match $pattern){
            write-ezlogs "The preset name you provided ($PresetName) contains one or more invalid characters, please provided a different name" -showtime -warning -logtype Libvlc
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Invalid Preset Name!","The preset name you provided ($PresetName) contains one or more invalid characters, please provided a different name",$okandCancel,$Button_Settings) 
            return          
          }   
          if($thisapp.config.EQ_Presets.Preset_Name -contains $PresetName){
            write-ezlogs "The preset name provided ($PresetName) matches the name of one of the Fixed Presets. Fixed Presets cannot be overwritten" -showtime -warning -logtype Libvlc
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($window,"Invalid Preset Name!","The preset name you provided ($PresetName) matches the name of one of the Fixed Presets.`n`nFixed Presets cannot be overwritten, please provided a different name",$okandCancel,$Button_Settings) 
            return        
          }             
        }       
        if(-not [string]::IsNullOrEmpty($PresetName)){      
          write-ezlogs ">>>> Saving new Preset $PresetName" -showtime -color cyan -logtype Libvlc -loglevel 2
          $current_EQ_Bands = $thisapp.Config.EQ_Bands        
          $new_preset = Add-EQPreset -PresetName $PresetName -EQ_Bands $current_EQ_Bands -EQ_Preamp $thisApp.Config.EQ_Preamp -thisApp $thisapp -synchash $synchash -verboselog 
          if($new_preset.Preset_Name){
            if($synchash.LoadPreset_Button.items.header -notcontains $new_preset.Preset_Name -and $new_preset.Preset_Name -ne 'Memory 1' -and $new_preset.Preset_Name -ne 'Memory 2' -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $new_preset.Preset_Name){
              $Menuitem = [System.Windows.Controls.MenuItem]::new()
              $Menuitem.IsCheckable = $true
              $Menuitem.Header = $new_preset.Preset_Name
              if($thisapp.config.EQ_Selected_Preset -eq $Menuitem.Header){
                $Menuitem.isChecked = $true
              }
              [void]$Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
              [void]$Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
              [void]$synchash.LoadPreset_Button.items.add($Menuitem)      
            }else{
              write-ezlogs "An existing preset with name $PresetName already exists -- updated to current values" -showtime -warning -logtype Libvlc
            } 
            foreach($item in $synchash.LoadPreset_Button.items){
              if($item.Header -eq $new_preset.Preset_Name){
                $item.isChecked = $true
              }elseif($item.isChecked){
                $item.isChecked = $false
              }
            }
            foreach($presets in $thisapp.config.EQ_Presets){
              if($synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton" -and $synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton".isChecked -and $presets.Preset_ID -ne $new_preset.Preset_ID){      
                $synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton".IsChecked = $false                           
              }              
            }
            if($synchash."EQ_Preset_$($new_preset.Preset_ID)_ToggleButton" -and !$synchash."EQ_Preset_$($new_preset.Preset_ID)_ToggleButton".isChecked){
              $synchash."EQ_Preset_$($new_preset.Preset_ID)_ToggleButton".isChecked = $true
            }
            if($synchash.CurrentSaveMenuItem){
              if(-not [string]::IsNullOrEmpty($thisapp.config.EQ_Selected_Preset)){
                $synchash.CurrentSaveMenuItem.Header = "Save as '$($thisapp.config.EQ_Selected_Preset)'"
                $synchash.CurrentSaveMenuItem.Height = [double]::NaN
                $synchash.CurrentSaveMenuItem.Uid = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset}).Preset_ID
              }else{
                $synchash.CurrentSaveMenuItem.Header = ""
                $synchash.CurrentSaveMenuItem.Height = '0'
                $synchash.CurrentSaveMenuItem.Uid = $Null
              }
            }
            if($new_preset.Preset_Name -eq 'Memory 1'){
              $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $true
              $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
            }elseif($new_preset.Preset_Name -eq 'Memory 2'){
              $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $true
              $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
            }                                         
          }else{
            write-ezlogs 'Unable to add Preset as no preset profile was returned when adding!' -showtime -warning -logtype Libvlc
          }          
        }else{
          write-ezlogs "The provided name is not valid or was not provided! -- $PresetName" -showtime -warning -logtype Libvlc
        }
      }catch{
        write-ezlogs "An exception occurred in EQPreset_Menuitem_Command routed event" -showtime -catcherror $_
      }
    }

    if($synchash.SavePreset_Button){
      $synchash.CurrentSaveMenuItem = [System.Windows.Controls.MenuItem]::new()
      $synchash.CurrentSaveMenuItem.IsCheckable = $false
      if(-not [string]::IsNullOrEmpty($thisapp.config.EQ_Selected_Preset) -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $thisapp.config.EQ_Selected_Preset){        
        $synchash.CurrentSaveMenuItem.Header = "Save as '$($thisapp.config.EQ_Selected_Preset)'"
        $synchash.CurrentSaveMenuItem.Uid = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset}).Preset_ID
      }else{
        $synchash.CurrentSaveMenuItem.Height = '0'
      }
      [void]$synchash.CurrentSaveMenuItem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      [void]$synchash.CurrentSaveMenuItem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      if($synchash.SavePreset_Button.items -notcontains $synchash.CurrentSaveMenuItem){
        [void]$synchash.SavePreset_Button.items.add($synchash.CurrentSaveMenuItem)
      }
      $menu_separator = [System.Windows.Controls.Separator]::new()
      $menu_separator.OpacityMask = $synchash.Window.TryFindResource('SeparatorGradient')
      if($synchash.SavePreset_Button.items -notcontains $menu_separator){
        [void]$synchash.SavePreset_Button.items.add($menu_separator)
      }
      $synchash.SaveMenuItem_Memory1 = [System.Windows.Controls.MenuItem]::new()
      $synchash.SaveMenuItem_Memory1.IsCheckable = $false
      $synchash.SaveMenuItem_Memory1.Header = "Save to Memory 1"
      [void]$synchash.SaveMenuItem_Memory1.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      [void]$synchash.SaveMenuItem_Memory1.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      if($synchash.SavePreset_Button.items -notcontains $synchash.SaveMenuItem_Memory1){
        [void]$synchash.SavePreset_Button.items.add($synchash.SaveMenuItem_Memory1)
      }

      $synchash.SaveMenuItem_Memory2 = [System.Windows.Controls.MenuItem]::new()
      $synchash.SaveMenuItem_Memory2.IsCheckable = $false
      $synchash.SaveMenuItem_Memory2.Header = "Save to Memory 2"
      [void]$synchash.SaveMenuItem_Memory2.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command) 
      [void]$synchash.SaveMenuItem_Memory2.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)   
      if($synchash.SavePreset_Button.items -notcontains $synchash.SaveMenuItem_Memory2){
        [void]$synchash.SavePreset_Button.items.add($synchash.SaveMenuItem_Memory2)
      }
      $synchash.SaveMenuItem_New = [System.Windows.Controls.MenuItem]::new()
      $synchash.SaveMenuItem_New.IsCheckable = $false
      $synchash.SaveMenuItem_New.Header = "Save as..."
      [void]$synchash.SaveMenuItem_New.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      [void]$synchash.SaveMenuItem_New.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.SaveMenuItem_Command)
      if($synchash.SavePreset_Button.items -notcontains $synchash.SaveMenuItem_New){
        [void]$synchash.SavePreset_Button.items.add($synchash.SaveMenuItem_New)
      }
    }
    
    #Memory Preset Buttons
    if($synchash.EQ_CustomPreset1_ToggleButton){
      $synchash.EQ_CustomPreset1_ToggleButton.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.EQPreset_Button_Command)
      $synchash.EQ_CustomPreset1_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.EQPreset_Button_Command)
    }

    if($synchash.EQ_CustomPreset2_ToggleButton){
      $synchash.EQ_CustomPreset2_ToggleButton.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.EQPreset_Button_Command)
      $synchash.EQ_CustomPreset2_ToggleButton.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.EQPreset_Button_Command)
    }

    #ResetEQ_Button
    if($synchash.ResetEQ_Button){
      $synchash.ResetEQ_Button.add_click({
          try{
            Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value '' -MemberType NoteProperty -Force
            foreach($preset in $thisapp.config.EQ_Presets){
              if($synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton" -and $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton".isChecked){                  
                $synchash."EQ_Preset_$($preset.Preset_ID)_ToggleButton".IsChecked = $false
              }              
            }               
            foreach($item in $synchash.LoadPreset_Button.items){
              if($item.isChecked){
                $item.isChecked = $false
              }
            }
            if($synchash.EQ_CustomPreset1_ToggleButton.isChecked){
              $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
            }elseif($synchash.EQ_CustomPreset2_ToggleButton.isChecked){
              $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
            }
            if($synchash.CurrentSaveMenuItem){
              $synchash.CurrentSaveMenuItem.Header = ""
              $synchash.CurrentSaveMenuItem.Height = '0'
              $synchash.CurrentSaveMenuItem.Uid = $Null
            }
            $thisApp.Config.EQ_Preamp = 12
            $synchash.EQ_Timer.start()
          }catch{
            write-ezlogs "An exception occurred in ResetEQ_Button.add_click" -showtime -catcherror $_
          }
      })
    }

    #Preamp
    if($synchash.Preamp_Slider_Background){
      $EQ_Slider_Back = "$($thisApp.Config.current_folder)\Resources\Skins\Audio\EQ_Slider_Back.png"
      if([system.io.file]::Exists($EQ_Slider_Back)){
        $stream_image = [System.IO.File]::OpenRead($EQ_Slider_Back) 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "56"
        $image.StreamSource = $stream_image
        $image.EndInit()
        [void]$stream_image.Close()
        [void]$stream_image.Dispose()
        $stream_image = $null
        $image.Freeze()
        $synchash.Preamp_Slider_Background.Source = $image
        $image = $Null
      }
    }
    if($synchash.Preamp_Slider){
      $synchash.Preamp_Slider.uid = "$($thisApp.Config.current_folder)\Resources\Skins\Audio\EQ_Slider_Thumb.png"
      if($thisApp.Config.Current_Theme.PrimaryAccentColor){
        $synchash.Preamp_Slider.Tag = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
      }else{
        $synchash.Preamp_Slider.Tag = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
      }
      $Preset_to_Apply = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset})
      if(-not [string]::IsNullOrEmpty($Preset_to_Apply.EQ_Preamp)){
        $synchash.Preamp_Slider.Value = $Preset_to_Apply.EQ_Preamp
      }elseif(-not [string]::IsNullOrEmpty($thisapp.Config.EQ_Preamp)){
        $synchash.Preamp_Slider.Value = $thisapp.Config.EQ_Preamp
      }else{
        $synchash.Preamp_Slider.Value = 12
      } 
      $synchash.Preamp_Slider.Add_ValueChanged({
          try{
            write-ezlogs ">>>> Changing Pre-amp value to $($this.value)" -loglevel 2 -logtype Libvlc         
            $thisapp.Config.EQ_Preamp = $this.value
            if($synchash.Equalizer -ne $null -and $thisapp.config.Enable_EQ){
              write-ezlogs "| Setting EQ Pre-amp value to $($this.value)" -loglevel 2 -logtype Libvlc
              [void]$synchash.Equalizer.SetPreamp($this.value)
            }  
            if($thisapp.config.Enable_EQ -and $synchash.vlc -and $synchash.Equalizer -ne $Null){
              [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)
            } 
            $Preset_to_Modify = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset})
            if([System.IO.File]::Exists($Preset_to_Modify.Preset_Path)){  
              $preset = Import-Clixml $Preset_to_Modify.Preset_Path
            }
            if($preset){
              Add-Member -InputObject $preset -Name 'EQ_Preamp' -Value $this.value -MemberType NoteProperty -Force
            }      
          }catch{
            write-ezlogs "An exception occurred setting the EQ preamp to $($this.value)" -showtime -catcherror $_
          }
      })
    }
    
    $synchash.EQ_Timer = [System.Windows.Threading.DispatcherTimer]::new()
    $synchash.EQ_Timer.Add_tick({
        try{
          write-ezlogs '[EQ_Timer] >>>> Updating EQ settings' -showtime -loglevel 2 -logtype Libvlc
          $EQ_Selected_Preset = $thisapp.config.EQ_Selected_Preset 
          if(-not [string]::IsNullOrEmpty($EQ_Selected_Preset)){
            $new_preset = ($thisapp.config.EQ_Presets | where {$_.preset_name -eq $EQ_Selected_Preset})
            if(!$new_preset){$new_preset = ($thisapp.config.Custom_EQ_Presets | where {$_.preset_name -eq $EQ_Selected_Preset})}
            #Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value $EQ_Selected_Preset -MemberType NoteProperty -Force
            if([System.IO.File]::Exists($new_preset.Preset_Path)){        
              write-ezlogs ">>>> Getting custom EQ Preset profile: $($new_preset.Preset_Path)" -showtime -loglevel 2 -logtype Libvlc
              $preset = Import-Clixml $new_preset.Preset_Path
              if($preset.EQ_Bands){
                if(!$synchash.Equalizer -and $thisapp.config.Enable_EQ){
                  write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.Equalizer = [LibVLCSharp.Equalizer]::new()
                  }else{
                    $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
                  } 
                }
                if($synchash.AudioOptions_Viewer.isVisible -and $this.tag -eq 'StartMedia'){
                  write-ezlogs "| AudioOptions_Viewer is open, setting EQ Preamp to preamp slider value: $($synchash.Preamp_Slider.value)" -loglevel 2 -logtype Libvlc
                  $EQ_Preamp = $synchash.Preamp_Slider.value
                }elseif(-not [string]::IsNullOrEmpty($preset.EQ_Preamp)){
                  write-ezlogs "| Setting Preamp from Preset profile $($preset.EQ_Preamp)" -loglevel 2 -logtype Libvlc
                  $EQ_Preamp = $preset.EQ_Preamp
                }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.EQ_Preamp)){
                  write-ezlogs "| Setting Preamp from config preamp $($preset.EQ_Preamp)" -loglevel 2 -logtype Libvlc
                  $EQ_Preamp = $thisApp.Config.EQ_Preamp                 
                }else{
                  write-ezlogs "| Setting Preamp to default: 12" -loglevel 2 -logtype Libvlc
                  $EQ_Preamp = 12
                }                                       
                Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value $EQ_Preamp -MemberType NoteProperty -Force
                if(!$synchash.AudioOptions_Viewer.isVisible -or $this.tag -ne 'StartMedia'){
                  $synchash.Preamp_Slider.value = $EQ_Preamp
                }                
                foreach($band in $preset.EQ_Bands){
                  if(!$synchash.AudioOptions_Viewer.isVisible -or $this.tag -ne 'StartMedia'){
                    $synchash."$($band.Band_Name)".Value = $band.Band_value
                  }                    
                  if($synchash."$($band.Band_Name)".Value -ne $null -and $synchash.Equalizer){
                    [void]$synchash.Equalizer.SetAmp($synchash."$($band.Band_Name)".Value,$band.Band_ID) 
                    write-ezlogs "| Applying EQ_$($band.Band_ID) to Value: $($band.Band_Value)" -showtime -loglevel 2 -logtype Libvlc -Dev_mode
                  }                         
                }               
                if($synchash.Equalizer -and $thisapp.config.Enable_EQ -and $synchash.vlc){
                  write-ezlogs "| Applying EQ to VLC" -loglevel 2 -logtype Libvlc
                  [void]$synchash.Equalizer.SetPreamp($synchash.Preamp_Slider.value)
                  [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)
                }
              }
            }elseif($new_preset.preset_id -ne $null){
              write-ezlogs ">>>> Setting Equalizer to preset $($new_preset.preset_name) - ID $($new_preset.preset_id)" -showtime -loglevel 2 -logtype Libvlc
              try{
                if($thisapp.config.Enable_EQ){
                  write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.Equalizer = [LibVLCSharp.Equalizer]::new($new_preset.preset_id)
                  }else{
                    $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new($new_preset.preset_id)
                  }
                }              
                if($thisapp.Config.EQ_Preamp -ne $null){
                  $EQ_Preamp = $thisapp.Config.EQ_Preamp
                  if($thisapp.config.Enable_EQ -and $synchash.Equalizer){
                    $synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)
                  }                 
                }else{
                  $EQ_Preamp = 12
                } 
                if($synchash.Preamp_Slider){
                  $synchash.Preamp_Slider.value = $EQ_Preamp
                }                          
                write-ezlogs "| Preamp: $($synchash.Equalizer.preamp)" -showtime -loglevel 2 -logtype Libvlc
                if($thisapp.config.Enable_EQ -and $synchash.VLC -and $synchash.Equalizer){
                  write-ezlogs "| Applying EQ to VLC" -loglevel 2 -logtype Libvlc
                  [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)
                  $synchash.Equalizer.SetPreamp($EQ_Preamp)
                }else{
                  write-ezlogs "[EQ_Timer] EQ is not enabled or VLC is not initialized" -showtime -warning -logtype Libvlc
                }
                foreach($band in $thisapp.config.EQ_Bands){
                  if($synchash.Equalizer){
                    $band.Band_value = $synchash.Equalizer.Amp($band.Band_ID)
                  }
                  if($synchash."$($band.Band_Name)" -and $band.Band_value -ne $null){$synchash."$($band.Band_Name)".Value = $band.Band_value}
                }
              }catch{
                write-ezlogs "[EQ_Timer] An exception occurred attempting to apply new Equalizer preset $($new_preset.preset_name) with id $($new_preset.preset_id)" -showtime -catcherror $_
                $this.Stop()
              }
            }else{write-ezlogs "[EQ_Timer] Unable to determine eq preset $($new_preset | Out-String)" -showtime -warning -logtype Libvlc}        
          }else{
            Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value '' -MemberType NoteProperty -Force
            write-ezlogs '[EQ_Timer] >>>> Resetting Equalizer to default 0 values' -showtime -loglevel 2 -logtype Libvlc
            try{ 
              if($synchash.vlc -and $thisapp.config.Enable_EQ){ 
                write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc              
                if($thisApp.Config.Libvlc_Version -eq '4'){
                  $synchash.Equalizer = [LibVLCSharp.Equalizer]::new()
                }else{
                  $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()                 
                }
                if($thisapp.Config.EQ_Preamp -ne $null){
                  [void]$synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)
                  $synchash.Preamp_Slider.Value = $thisapp.Config.EQ_Preamp 
                }else{
                  [void]$synchash.Equalizer.SetPreamp(12)
                  $synchash.Preamp_Slider.Value = 12 
                }
                [void]$synchash.vlc.SetEqualizer($synchash.Equalizer)                      
              }elseif($synchash.vlc){
                write-ezlogs "| Setting Pre-amp to default (12) and unsetting Eq from VLC" -loglevel 2 -logtype Libvlc
                if($synchash.Equalizer){
                  [void]$synchash.Equalizer.SetPreamp(12)
                }               
                [void]$synchash.vlc.UnsetEqualizer() 
              }                                                    
              foreach($band in $thisapp.config.EQ_Bands){
                if($synchash."$($band.Band_Name)"){$synchash."$($band.Band_Name)".Value = $band.Band_Value}
              }            
            }catch{
              write-ezlogs 'An exception occurred resetting Equalizer to default values' -showtime -catcherror $_
              $this.Stop()
            }        
          }          
          $this.Stop()
        }catch{
          write-ezlogs "An exception occurred in EQ_Timer" -showtime -catcherror $_
        }finally{
          $this.tag = $Null
          $this.Stop()
        }
    })
  
    #apply eq
    <#    if($Equalizer -ne $null -and $thisapp.config.Enable_EQ){
        if(!$synchash.Equalizer){
        write-ezlogs "| Creating new Equalizer" -loglevel 2 -logtype Libvlc
        $synchash.Equalizer = $Equalizer
        }
        if($synchash.vlc){
        $null = $synchash.vlc.SetEqualizer($synchash.Equalizer)
        }else{
        write-ezlogs "[Initialize-EQ] Unable to set Equalizer, libvlc is not initialized!" -showtime -warning -logtype Libvlc
        $synchash.Equalizer.dispose()
        $synchash.Equalizer = $Null
        }
    }#>
    if($Equalizer){
      [void]$Equalizer.dispose()
      $Equalizer = $Null
    }
    $synchash.MediaPlayer_CurrentDuration = 0
    #Audio Option Flyout Controls
    if($synchash.Audio_Flyout){
      $synchash.Audio_Flyout.add_IsOpenChanged({
          if($synchash.Audio_Flyout.isOpen){
            $synchash.AudioButton_ToggleButton.isChecked = $true
            $synchash.AudioOptions_Grid.Visibility = 'Visible'
            $synchash.AudioOptions_Grid.height=[double]::NaN
          }else{
            $synchash.AudioOptions_Grid.height='0'
            $synchash.AudioOptions_Grid.Visibility = 'Hidden'
            $synchash.AudioButton_ToggleButton.isChecked = $false
          }
      })
    }
    #Initialization complete, dispose vlc until we need it again
    if($synchash.vlc -and !$Startup_Playback){
      if($synchash.vlc -is [System.IDisposable]){
        write-ezlogs "| Disposing vlc - Startup_Playback: $Startup_Playback" -logtype Libvlc
        $synchash.vlc.dispose()
        $synchash.vlc = $Null
      }
      if($synchash.VideoView.MediaPlayer -is [System.IDisposable]){
        write-ezlogs "| Disposing VideoView.MediaPlayer" -logtype Libvlc
        $synchash.VideoView.MediaPlayer.dispose()
        $synchash.VideoView.MediaPlayer = $Null
      }
      if($synchash.libvlc -is [System.IDisposable]){
        write-ezlogs ">>>> Disposing Libvlc" -logtype Libvlc
        $synchash.libvlc.dispose()
        $synchash.libvlc = $Null
      }     
    }
  }catch{
    write-ezlogs 'An exception occurred An exception occurred initializing libvlc EQ' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Initialize-EQ Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-LibVLC Function
#----------------------------------------------
Function Update-LibVLC
{
  param (
    $synchash,
    $thisApp,
    [switch]$force,
    [switch]$EnableCasting,
    [switch]$UpdateVideoView
  ) 
  try{
    $audio_media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)flac|(?i)wav|(?i)3gp|(?i)aac))') 
    if($synchash.Equalizer -ne $null -or $force){
      if($synchash.timer.isEnabled){
        $synchash.timer.stop()
      }    
      if($synchash.streamlink -and -not [string]::IsNullOrEmpty($synchash.current_playing_Media.id) -and (Get-Process Streamlink*)){
        write-ezlogs "Playback from Streamlink content requires restarting, executing start_media_timer" -warning -logtype Libvlc -loglevel 2
        $synchash.Start_media = $synchash.current_playing_Media
        if($EnableCasting){
          $synchash.start_media_timer.tag = 'EnableCasting'
        }
        $synchash.start_media_timer.start()  
        return
      }
      $currenttime = $synchash.VLC.Time
      $media_link = $synchash.vlc.media.Mrl
      $synchash.VLC_IsPlaying_State = $false
      Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp -UnregisterOnly
      if($synchash.libvlc){
        write-ezlogs ">>>> Disposing Libvlc" -logtype Libvlc -loglevel 2
        $synchash.libvlc.dispose()
        $synchash.libvlc = $Null
      }
      [void]$synchash.vlc.stop()
      #Recreate new libvlc/media player instance with args
      $vlcArgs = [System.Collections.Generic.List[String]]::new()
      [void]$vlcArgs.add('--file-logging')
      [void]$vlcArgs.add("--logfile=$($thisapp.config.Vlc_Log_file)")
      [void]$vlcArgs.add("--mouse-events")
      [void]$vlcArgs.add("--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
      [void]$vlcArgs.add("--logmode=text")      
      [void]$vlcArgs.add("--osd")
      #TODO: Make global libvlc gain configurable
      [double]$doubleref = [double]::NaN
      if(-not [string]::IsNullOrEmpty($thisApp.Config.Libvlc_Global_Gain) -and [double]::TryParse($thisApp.Config.Libvlc_Global_Gain,[ref]$doubleref)){
        write-ezlogs "| Applying custom global gain for libvlc: $($thisApp.Config.Libvlc_Global_Gain)" -logtype Libvlc -loglevel 2
        [void]$vlcArgs.add("--gain=$($thisApp.Config.Libvlc_Global_Gain)")
      }else{
        write-ezlogs "| Setting default global gain for libvlc: 4" -logtype Libvlc -loglevel 2
        [void]$vlcArgs.add('--gain=4.0') #Set gain to 4 which is default that VLC uses but for some reason libvlc does not
      }
      #TODO: Apparently no audio filters work with libvlc 3 - hoping libvlc 4 will fix
      <#      if($Enable_normalizer){
          $null = $vlcArgs.add("--audio-filter=normalizer")
      }#>
      if($synchash.Enable_EQ2Pass_Toggle.isChecked){
        [void]$vlcArgs.add("--equalizer-2pass")
        write-ezlogs ">>>> EQ2Pass Enabled" -showtime -logtype Libvlc -loglevel 2
        Add-Member -InputObject $thisapp.config -Name 'Enable_EQ2Pass' -Value $true -MemberType NoteProperty -Force
      }else{
        write-ezlogs ">>>> EQ2Pass Disabled" -showtime -logtype Libvlc -loglevel 2
        Add-Member -InputObject $thisapp.config -Name 'Enable_EQ2Pass' -Value $false -MemberType NoteProperty -Force
      }
      if($Loopback_Recording){
        [void]$vlcArgs.add("--wasapi-loopback")
      }
      if($thisApp.Config.Use_Visualizations -and ($media_link -match $audio_media_pattern)){ 
        [void]$vlcArgs.add("--video-on-top")
        [void]$vlcArgs.add("--spect-show-original")
        if($thisApp.Config.Current_Visualization -eq 'Spectrum'){           
          [void]$vlcArgs.add("--audio-visual=Visual")
          [void]$vlcArgs.add("--effect-list=spectrum")
        }else{
          [void]$vlcArgs.add("--audio-visual=$($thisApp.Config.Current_Visualization)")
          [void]$vlcArgs.add("--effect-list=spectrum")
        }
        write-ezlogs "Enabling Visualization plugin '$($thisApp.Config.Current_Visualization)'" -showtime -logtype Libvlc -loglevel 2                                                                    
      }else{  
        [void]$vlcArgs.add("--file-caching=1000")  
        write-ezlogs " | New libvlc instance, no visualization, (file-caching: 1000)" -showtime -loglevel 2 -logtype Libvlc      
      }
      if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
        try{
          $thisapp.config.vlc_Arguments -split ',' | foreach{                  
            if([regex]::Escape($_) -match '--' -and $vlcArgs -notcontains $_){
              write-ezlogs " | Adding custom Libvlc option: $($_)" -loglevel 2 -logtype Libvlc
              [void]$vlcArgs.add("$($_)")
            }else{
              write-ezlogs "Cannot add custom libvlc option $($_) - it does not meet the required format or is already added!" -warning -loglevel 2 -logtype Libvlc
            }
          }
        }catch{
          write-ezlogs "An exception occurred processing custom VLC arguments" -catcherror $_
        }          
      }
      [String[]]$libvlc_arguments = $vlcArgs | foreach{
        if($thisApp.Config.Dev_mode){write-ezlogs " | Applying Libvlc option: $($_)" -loglevel 2 -logtype Libvlc -Dev_mode}
        if([regex]::Escape($_) -match '--'){
          $_
        }else{
          write-ezlogs "Cannot apply libvlc option $($_) - it does not meet the required format!" -warning -loglevel 2 -logtype Libvlc
        }
      }
      if($thisApp.Config.Libvlc_Version -eq '4'){
        $synchash.libvlc = [LibVLCSharp.LibVLC]::new($libvlc_arguments) 
      }else{
        $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new($libvlc_arguments) 
      }
      try{
        $synchash.libvlc.SetUserAgent("$($thisApp.Config.App_Name) Media Player","HTTP/User/Agent")  
        $startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"  
        if($startapp.AppID){
          $synchash.libvlc.SetAppId($startapp.AppID,$thisApp.Config.App_Version,"$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
        }
        if((($synchash.Spotify_WebPlayer_title -and $thisApp.Config.Spotify_WebPlayer) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title))){
          Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -wait -Startlibvlc
          $synchash.Update_Libvlc_Status = $false
          return
        }  
      }catch{
        write-ezlogs "An exception occurred setting Libvlc user agent" -catcherror $_
      } 
      Update-MainPlayer -synchash $synchash -thisApp $thisApp -Now_Playing_Label "PLAYING" -New_MediaPlayer -media_link $media_link -Saved_Media_Progress $currenttime -start_media_Timer -EnableCasting:$EnableCasting
      $synchash.Update_Libvlc_Status = $false
    }else{
      write-ezlogs "Equalizer has not been initialized..unable to enable 2pass" -showtime -warning
    } 
  }catch{
    write-ezlogs 'An exception occurred An exception in Update-LibVLC' -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Update-LibVLC Function
#----------------------------------------------

#---------------------------------------------- 
#region Close-LibVLC Function
#----------------------------------------------
Function Close-LibVLC
{
  param (
    $synchash,
    $thisApp,
    [switch]$DisposeMediaPlayer
  ) 
  try{
    if($synchash.vlc -is [System.IDisposable] -and $DisposeMediaPlayer){
      $synchash.vlc.dispose()
    }
    if($synchash.libvlc){
      write-ezlogs ">>>> Disposing Libvlc" -loglevel 2
      $synchash.libvlc.dispose()
      $synchash.libvlc = $Null
    }
  }catch{
    write-ezlogs 'An exception occurred An exception in Close-LibVLC' -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Close-LibVLC Function
#----------------------------------------------
Export-ModuleMember -Function @('Initialize-Vlc','Initialize-EQ','Update-LibVLC','Close-LibVLC')