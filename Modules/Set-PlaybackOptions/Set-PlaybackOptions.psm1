<#
    .Name
    Set-PlaybackOptions

    .Version 
    0.1.0

    .SYNOPSIS
    Sets various playback options for media player  

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
#region Set-Shuffle Function
#----------------------------------------------
function Set-Shuffle
{
  <#
      .Name
      Set-Shuffle

      .Version 
      0.1.0

      .SYNOPSIS
      Sets/toggles shuffle state for media player  

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
    [switch]$Verboselog
  )
  try{
    if($thisapp.config.Shuffle_Playback){
      $synchash.ShuffleButton_ToggleButton.ToolTip = 'Shuffle Disabled'
      $synchash.ShuffleButton_ToggleButton.isChecked = $false
      if($synchash.Tray_Shuffle_Icon){
        $synchash.Tray_Shuffle_Icon.Kind = "ShuffleDisabled"
      }
      if($synchash.MiniShuffle_ToggleButton){
        $synchash.MiniShuffle_ToggleButton.isChecked = $false
        $synchash.MiniShuffle_ToggleButton.ToolTip = 'Shuffle Disabled'
      }
      write-ezlogs ">>>> Disabling Shuffle Playback" -LogLevel 2
      $thisapp.config.Shuffle_Playback = $false
    }else{
      $synchash.ShuffleButton_ToggleButton.ToolTip = 'Shuffle Enabled'
      $synchash.ShuffleButton_ToggleButton.isChecked = $true
      if($synchash.Tray_Shuffle_Icon){
        $synchash.Tray_Shuffle_Icon.Kind = "ShuffleVariant"
      }
      if($synchash.MiniShuffle_ToggleButton){
        $synchash.MiniShuffle_ToggleButton.isChecked = $true
        $synchash.MiniShuffle_ToggleButton.ToolTip = 'Shuffle Enabled'
      }
      write-ezlogs ">>>> Enabling Shuffle Playback" -LogLevel 2
      $thisapp.config.Shuffle_Playback = $true
    }
  }catch{
    write-ezlogs "An exception occurred in Set-Shuffle" -CatchError $_ -showtime
  }finally{
    try{
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
    }catch{
      write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
    }   
  }
}
#---------------------------------------------- 
#endregion Set-Shuffle Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-AutoPlay Function
#----------------------------------------------
function Set-AutoPlay
{
  <#
      .Name
      Set-Shuffle

      .Version 
      0.1.0

      .SYNOPSIS
      Sets/toggles AutoPlay state for media player  

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
    [switch]$Verboselog
  )
  try{
    if($thisapp.config.Auto_Playback){
      $synchash.AutoPlayButton_ToggleButton.isChecked = $false
      $synchash.AutoPlayButton_ToggleButton.ToolTip = 'AutoPlay Disabled'
      if($synchash.MiniAutoPlay_ToggleButton){
        $synchash.MiniAutoPlay_ToggleButton.isChecked = $false
        $synchash.MiniAutoPlay_ToggleButton.ToolTip = 'AutoPlay Disabled'
      }
      $thisapp.config.Auto_Playback = $false
    }else{
      $synchash.AutoPlayButton_ToggleButton.isChecked = $true
      $synchash.AutoPlayButton_ToggleButton.ToolTip = 'AutoPlay Enabled'
      if($synchash.MiniAutoPlay_ToggleButton){
        $synchash.MiniAutoPlay_ToggleButton.isChecked = $true
        $synchash.MiniAutoPlay_ToggleButton.ToolTip = 'AutoPlay Enabled'
      }
      $thisapp.config.Auto_Playback = $true
    }
  }catch{
    write-ezlogs "An exception occurred in Set-AutoPlay" -CatchError $_ -showtime
  }finally{
    try{
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
    }catch{
      write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
    }   
  }
}
#---------------------------------------------- 
#endregion Set-AutoPlay Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-AutoRepeat Function
#----------------------------------------------
function Set-AutoRepeat
{
  <#
      .Name
      Set-AutoRepeat

      .Version 
      0.1.0

      .SYNOPSIS
      Sets/toggles AutoRepeat state for media player  

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
    [switch]$Verboselog
  )
  try{
    if($thisapp.config.Auto_Repeat){
      $synchash.AutoRepeatButton_ToggleButton.isChecked = $false
      $synchash.AutoRepeatButton_ToggleButton.ToolTip = 'Repeat Disabled'
      $thisApp.Config.Auto_Repeat = $false
    }else{
      $synchash.AutoRepeatButton_ToggleButton.isChecked = $true
      $synchash.AutoRepeatButton_ToggleButton.ToolTip = 'Repeat Enabled'
      $thisApp.Config.Auto_Repeat = $true
    }
  }catch{
    write-ezlogs "An exception occurred in Set-AutoRepeat" -CatchError $_ -showtime
  }finally{
    try{
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
    }catch{
      write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
    }   
  }
}
#---------------------------------------------- 
#endregion Set-AutoRepeat Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-Mute Function
#----------------------------------------------
function Set-Mute
{
  <#
      .Name
      Set-Mute

      .Version 
      0.1.0

      .SYNOPSIS
      Sets/toggles Mute state for media player  

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
    [switch]$Verboselog
  )
  try{
    if($synchash.vlc -and !$([string]$synchash.vlc.media.Mrl).StartsWith("dshow://")){
      $MuteAction = $true
      if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Current VLC Session $($synchash.vlc | out-string)" -Dev_mode}
      if($synchash.vlc.Mute){
        write-ezlogs ">>>> VLC mute: $($synchash.vlc.Mute) - Unmuting VLC" -loglevel 2 
        if($synchash.MuteButton_ToggleButton.isChecked){
          $synchash.MuteButton_ToggleButton.isChecked = $false 
        }
        $synchash.vlc.Mute = $false
      }else{
        write-ezlogs ">>>> VLC mute: $($synchash.vlc.Mute) - Muting VLC" -loglevel 2
        if($synchash.MuteButton_ToggleButton -and !$synchash.MuteButton_ToggleButton.isChecked){
          $synchash.MuteButton_ToggleButton.isChecked = $true
        }
        $synchash.vlc.mute = $true        
      }
      #$synchash.vlc.ToggleMute()
      if($synchash.VideoView_Mute_Icon){
        if($synchash.vlc.mute){
          $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
        }elseif($synchash.Volume_Slider.value -ge 75){
          #$synchash.MuteButton_ToggleButton.isChecked = $false
          $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
        }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
          $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
          #$synchash.MuteButton_ToggleButton.isChecked = $false
        }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
          $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
          #$synchash.MuteButton_ToggleButton.isChecked = $false
        }elseif($synchash.Volume_Slider.value -le 0){
          $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
          $synchash.MuteButton_ToggleButton.isChecked = $true
        } 
      }   
    }
    if(($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -and !$synchash.Webview2.CoreWebView2.IsMuted) -or ($synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -and !$synchash.YoutubeWebView2.CoreWebView2.IsMuted) -or ($synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title)){
      $MuteAction = $true
      if($synchash.Spotify_WebPlayer_State -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0 -and $synchash.Spotify_WebPlayer_State.current_track.id){
        write-ezlogs ">>>> Executing Webview2_MuteScript for Spotify WebPlayer"
        $synchash.Webview2_MuteScript =  @"
 SpotifyWeb.player.getVolume().then(volume => {
  if (volume == 0){
       console.log('Unmuting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
      SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100));
  } else {
     console.log('Muting Spotify Volume to 0');
     SpotifyWeb.player.setVolume(0);
  }
});

"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_MuteScript      
        )
      }elseif(($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be') -and $synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -and !$synchash.YoutubeWebView2.CoreWebView2.IsMuted){
        write-ezlogs ">>>> Muting YoutubeWebView2.CoreWebView2 for Invidious" -loglevel 2
        $synchash.YoutubeWebView2.CoreWebView2.IsMuted = $true
        $synchash.MuteButton_ToggleButton.isChecked = $true
      }elseif(($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be') -and $synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -and $synchash.YoutubeWebView2.CoreWebView2.IsMuted){
        write-ezlogs ">>>> UnMuting YoutubeWebView2.CoreWebView2 for Invidious" -loglevel 2
        $synchash.YoutubeWebView2.CoreWebView2.IsMuted = $false 
        $synchash.MuteButton_ToggleButton.isChecked = $false
      }else{
        $synchash.YoutubeWebView2_MuteScript =  @"
  var player = document.getElementById('movie_player');
  var isMuted = player.isMuted();
  if (isMuted)
     player.unMute();
  else
    player.mute();
"@             
        $synchash.YoutubeWebView2.ExecuteScriptAsync(
          $synchash.YoutubeWebView2_MuteScript      
        )
      }      
    }elseif($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -and $synchash.Webview2.CoreWebView2.IsMuted){
      $MuteAction = $true
      $synchash.Webview2.CoreWebView2.IsMuted = $false 
      $synchash.MuteButton_ToggleButton.isChecked = $false
    }elseif($synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -and $synchash.YoutubeWebView2.CoreWebView2.IsMuted){
      $MuteAction = $true
      write-ezlogs ">>>> UnMuting YoutubeWebView2.CoreWebView2 for Invidious" -loglevel 2
      $synchash.YoutubeWebView2.CoreWebView2.IsMuted = $false 
      $synchash.MuteButton_ToggleButton.isChecked = $false
    }elseif((Get-Process Spotify*) -and $thisApp.Config.Import_Spotify_Media -and -not [string]::IsNullOrEmpty($synchash.Spotify_Status) -and $synchash.Spotify_Status -ne 'Stopped'){
      $MuteAction = $true
      if($thisApp.Config.Use_Spicetify -and $synchash.Spicetify -and ((NETSTAT.EXE -an) | where {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'})){
        if($synchash.Spicetify.is_Mute){
          write-ezlogs ">>>> UnMuting Spotify with Spicetify by sending TOGGLEMUTE and SETVOLUME?$($synchash.Volume_Slider.Value) -- Spicetify Volume: $($synchash.Spicetify.volume)" -logtype Spotify
          Invoke-RestMethod -Uri "http://127.0.0.1:8974/TOGGLEMUTE" -UseBasicParsing  
          Invoke-RestMethod -Uri "http://127.0.0.1:8974/SETVOLUME?$($synchash.Volume_Slider.Value)" -UseBasicParsing  
          $synchash.MuteButton_ToggleButton.isChecked = $false 
        }else{
          write-ezlogs ">>>> Muting Spotify with Spicetify by sending TOGGLEMUTE:  -- Spicetify Volume: $($synchash.Spicetify.volume)" -logtype Spotify
          Invoke-RestMethod -Uri "http://127.0.0.1:8974/TOGGLEMUTE" -UseBasicParsing      
          $synchash.MuteButton_ToggleButton.isChecked = $true 
        }       
      }else{
        $PlaybackInfo = Get-CurrentPlaybackInfo -ApplicationName $thisapp.config.App_Name
        if($PlaybackInfo.device.volume_percent -ne '0'){
          write-ezlogs ">>>> Muting Spotify playback by setting playback volume to 0 - current $($PlaybackInfo.device.volume_percent)" -loglevel 2 -logtype Spotify
          Set-PlaybackVolume -VolumePercent '0' -ApplicationName $thisapp.config.App_Name 
          $synchash.MuteButton_ToggleButton.isChecked = $true
        }else{
          write-ezlogs ">>>> Unmuting Spotify playback by setting playback volume to $($synchash.Volume_Slider.Value) - current $($volume)" -loglevel 2 -logtype Spotify
          Set-PlaybackVolume -VolumePercent $($synchash.Volume_Slider.Value) -ApplicationName $thisapp.config.App_Name 
          $synchash.MuteButton_ToggleButton.isChecked = $false
        }
      } 
    }
    if(!$MuteAction){
      write-ezlogs "| There was nothing to mute!" -warning
      if($synchash.MuteButton_ToggleButton -and !$synchash.MuteButton_ToggleButton.isChecked){
        $synchash.MuteButton_ToggleButton.isChecked = $true
        $synchash.VideoView_Mute_Icon.kind -eq 'Volumeoff'
      }elseif($synchash.MuteButton_ToggleButton.isChecked){
        $synchash.MuteButton_ToggleButton.isChecked = $false
        if($synchash.Volume_Slider.value -ge 75){
          $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
        }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
          $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
        }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
          $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
        }elseif($synchash.Volume_Slider.value -le 0){
          $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
          $synchash.MuteButton_ToggleButton.isChecked = $true
        }
      }
    }
    $thisApp.Config.Media_Muted = $synchash.MuteButton_ToggleButton.isChecked
    if($synchash.VideoView_Mute_Icon.kind -eq 'Volumeoff'){
      #write-ezlogs "Audio is Muted" -warning -callpath "$((Get-PSCallStack)[0].Command):$((Get-PSCallStack)[0].InvocationInfo.ScriptLineNumber)" -loglevel 3
      #$synchash.MuteButton_ToggleButton.isChecked = $true
    }else{
      #write-ezlogs "Audio is UnMuted" -warning -callpath "$((Get-PSCallStack)[0].Command):$((Get-PSCallStack)[0].InvocationInfo.ScriptLineNumber)" -loglevel 3
      #$synchash.MuteButton_ToggleButton.isChecked = $false
    }
  }catch{
    write-ezlogs "An exception occurred in Set-Mute" -showtime -catcherror $_ -callpath "$((Get-PSCallStack)[0].Command):$((Get-PSCallStack)[0].InvocationInfo.ScriptLineNumber)"
  }
}
#---------------------------------------------- 
#endregion Set-AutoPlay Function
#----------------------------------------------
Export-ModuleMember -Function @('Set-Shuffle','Set-AutoPlay','Set-Mute','Set-AutoRepeat')