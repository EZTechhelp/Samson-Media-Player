<#
    .Name
    Initialize-WebView2

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and initializes controls and events for WebView2

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
#region Initialize-WebPlayer Function
#----------------------------------------------
Function Initialize-WebPlayer
{
  param (
    $synchash,
    $thisApp,
    $thisScript
  ) 
  try{
    #$synchash.Web_BrowserTab.Visibility = 'Visible'
    <#    if($syncHash.WebView2 -or $synchash.Webview2.CoreWebView2){
        $syncHash.WebView2.dispose()
        } 
        $synchash.WebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
        $synchash.WebView2.Name = 'WebView2'
        $synchash.WebView2.VerticalAlignment="Stretch"
    $null = $synchash.VLC_Grid.addchild($synchash.WebView2)#>
    $synchash.WebView2.Visibility = 'Visible'
    $synchash.Webview2.DefaultBackgroundColor = [System.Drawing.Color]::Transparent
    $synchash.WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new("--autoplay-policy=no-user-gesture-required")
    $synchash.WebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
    $synchash.WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
      [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.WebView2Options
    )
    if(!$synchash.WebView2.CoreWebView2){
      $synchash.WebView2Env.GetAwaiter().OnCompleted(
        [Action]{
          $synchash.WebView2.EnsureCoreWebView2Async( $synchash.WebView2Env.Result )
      
        }
      )
    }
  }catch{
    write-ezlogs "An exception occurred creating webview2e Enviroment" -showtime -catcherror $_
  }


  $synchash.WebView2.Add_NavigationCompleted(
    [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
      #write-ezlogs "Navigation completed: $($synchash.WebView2.source | out-string)" -showtime
      #console.log(document.querySelector('.video-stream').getCurrentTime());
      <#      $synchash.Webview2_Script =  @"
  var player = document.getElementById('movie_player');
var time = player.getCurrentTime();
var sec_num = parseInt(time, 10);
var hours   = Math.floor(sec_num / 3600);
var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
var seconds = sec_num - (hours * 3600) - (minutes * 60);
if (hours < 10)
   hours = '0' + hours;
if (minutes < 10)
   minutes = '0' + minutes;
if (seconds < 10)
   seconds = '0' + seconds;       
   console.log(hours + ':' + minutes + ':' + seconds);  

    window.chrome.webview.postMessage(time);  
          document.addEventListener('click', function (event)
          {

           
          console.log(document.querySelector('.video-stream'));
          let elem = event.target;
          let jsonObject =
          {
          Key: 'time',
          Value: time 
          };
         
          });
"@ #>     


      if($thisApp.Config.Use_invidious){
        $synchash.Webview2_Script = @"
var player_data = JSON.parse(document.getElementById('player_data').textContent);
var video_data = JSON.parse(document.getElementById('video_data').textContent);
var options = {
    preload: 'auto',
    liveui: true,
    playbackRates: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
    controlBar: {
        children: [
            'playToggle',
            'volumePanel',
            'currentTimeDisplay',
            'timeDivider',
            'durationDisplay',
            'progressControl',
            'remainingTimeDisplay',
            'Spacer',
            'captionsButton',
            'qualitySelector',
            'playbackRateMenuButton',
            'fullscreenToggle'
        ]
    },
    html5: {
        preloadTextTracks: false,
        vhs: {
            overrideNative: true
        }
    }
};

var player = videojs('player', options);
console.log(player_data);
console.log(video_data);


var time = player.currentTime();
console.log(time);
  var playerdataJson =
  {
    Key: 'player_data',
    Value: player_data 
  };
  var videodataObject =
  {
    Key: 'video_data',
    Value: video_data 
  };
  var playerObject =
  {
    Key: 'player',
    Value: player 
  };
  var timeJson =
  {
    Key: 'time',
    Value: time 
  };
    window.chrome.webview.postMessage(playerdataJson);  
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(playerObject);
    window.chrome.webview.postMessage(timeJson);
"@
      }else{
        $synchash.Webview2_Script =  @"
  var player = document.getElementById('movie_player');

function onYouTubePlayerStateChange(event) {
    
    console.log(event);
}
function onYoutubePlayerReady(event) {
  console.log('Player is Ready');
}
function onYouTubeError(event) {
  console.log('Youtube ERROR: event');
  console.log(event);
  var ErrorObject =
  {
    Key: 'error',
    Value: event 
  };
  window.chrome.webview.postMessage(ErrorObject);
}
  player.addEventListener("OnReady", "onYoutubePlayerReady");
  player.addEventListener("onStateChange", "onYouTubePlayerStateChange");
  player.addEventListener("onError", "onYouTubeError");
  player.setVolume($($synchash.Volume_Slider.Value));
  var state = player.getPlayerState();
  var videodata = player.getVideoData();
  var videoUrl = player.getVideoUrl();
  var time = player.getCurrentTime();
  var duration = player.getDuration();
  var volume = player.getVolume();
  var timeJson =
  {
    Key: 'time',
    Value: time 
  };
  var jsonObject =
  {
    Key: 'state',
    Value: state 
  };
  var durationObject =
  {
    Key: 'duration',
    Value: duration 
  };
  var volumeObject =
  {
    Key: 'volume',
    Value: volume 
  };
  var videodataObject =
  {
    Key: 'videodata',
    Value: videodata 
  };
  var videoUrlObject =
  {
    Key: 'videoUrl',
    Value: videoUrl
  };
    window.chrome.webview.postMessage(timeJson);  
    window.chrome.webview.postMessage(jsonObject);
    window.chrome.webview.postMessage(durationObject);
    window.chrome.webview.postMessage(volumeObject);
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(videoUrlObject);
"@      
      
      }
      if($thisApp.Config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title){
        $synchash.SpotifyStart_Webview2_Script = @"

// Play a specified track on the Web Playback SDK's device ID
function play(device_id) {
  $.ajax({
   url: "https://api.spotify.com/v1/me/player/play?device_id=" + device_id,
   type: "PUT",
   data: '{"uris": ["spotify:$($synchash.Session_Spotifytype):$($synchash.Session_SpotifyId)"]}',
   beforeSend: function(xhr){xhr.setRequestHeader('Authorization', 'Bearer ' + _token );},
   success: function(data) { 
     console.log(data)
   }
  });
}
function getStatePosition() {
  if (SpotifyWeb.currState.paused) {
     //SpotifyWeb.currState.newposition = SpotifyWeb.currState.position / 1000;
     return SpotifyWeb.currState;
  }

  const position = SpotifyWeb.currState.position + (performance.now() - SpotifyWeb.currState.updateTime);
  SpotifyWeb.currState.newposition = position > SpotifyWeb.currState.duration ? SpotifyWeb.currState.duration : position;
  return SpotifyWeb.currState
}

"@
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.SpotifyStart_Webview2_Script       
        )    
        $synchash.Webview2_VolumeScript =  @"
   console.log('Setting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
  SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100))
"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_VolumeScript      
        )
      }else{
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_Script       
        )   
      }   
                   
    
      #$synchash.WebView2.CoreWebView2.PostWebMessageAsString("copy");  
    }
  )   
  $synchash.WebView2.Add_CoreWebView2InitializationCompleted(
    [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
      #$MainForm.Add_Activated([EventHandler]{ If ( 0 -cne $MODE_FULLSCREEN ) { $MainForm.Add_FormClosing($CloseHandler) } })
      #$MainForm.Add_Deactivate([EventHandler]{ $MainForm.Remove_FormClosing($CloseHandler) })
      #& $ProcessNoDevTools
      try{
        [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.WebView2.CoreWebView2.Settings
        $Settings.AreDefaultContextMenusEnabled  = $true
        $Settings.AreDefaultScriptDialogsEnabled = $true
        $Settings.AreDevToolsEnabled             = $true
        $Settings.AreHostObjectsAllowed          = $true
        $Settings.IsBuiltInErrorPageEnabled      = $false
        $Settings.IsScriptEnabled                = $true
        $Settings.IsStatusBarEnabled             = $true
        $Settings.IsWebMessageEnabled            = $true
        $Settings.IsZoomControlEnabled           = $false
        $Settings.IsGeneralAutofillEnabled       = $false
        $Settings.IsPasswordAutosaveEnabled      = $false   
        $syncHash.WebView2.CoreWebView2.AddWebResourceRequestedFilter("*", [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All);     
        if($thisApp.Config.Spotify_SP_DC){
          write-ezlogs "Adding Spotify Cookie $($thisApp.Config.Spotify_SP_DC)" -showtime
          $OptanonAlertBoxClosed = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), ".spotify.com", "/")
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed)           
          $sp_dc = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('sp_dc', $thisApp.Config.Spotify_SP_DC, ".spotify.com", "/")
          $sp_dc.IsSecure=$true
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($sp_dc)   
        }
        if($thisApp.Config.Youtube_1PSID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_1PSID)" -showtime
          $Youtube_1PSID = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('__Secure-1PSID', $thisApp.Config.Youtube_1PSID, ".youtube.com", "/")
          $Youtube_1PSID.IsSecure=$true
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie( $Youtube_1PSID) 
          $PREF = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('PREF', 'tz=America.New_York&f6=400', ".youtube.com", "/")
          $PREF.IsSecure=$true
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($PREF)                   
        }
        if($thisApp.Config.Youtube_1PAPISID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_1PAPISID)" -showtime
          $Youtube_1PAPISID = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('__Secure-1PAPISID', $thisApp.Config.Youtube_1PAPISID, ".youtube.com", "/")
          $Youtube_1PAPISID.IsSecure=$true
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_1PAPISID)                   
        } 
        if($thisApp.Config.Youtube_3PAPISID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_3PAPISID)" -showtime
          $Youtube_3PAPISID = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('__Secure-3PAPISID', $thisApp.Config.Youtube_3PAPISID, ".youtube.com", "/")
          $Youtube_3PAPISID.IsSecure=$true
          $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_3PAPISID)                   
        } 
                                    
      }catch{
        write-ezlogs "An exception occurred in CoreWebView2InitializationCompleted Event" -showtime -catcherror $_
      } 
      $synchash.Webview2.CoreWebView2.add_WebResourceRequested({
          [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e = $args[1]
          try{

            $Cookies = ($e.Request.Headers | where {$_.key -eq 'cookie'}).value
            if($Cookies){
              if($Cookies -notmatch 'OptanonAlertBoxClosed'){
                $OptanonAlertBoxClosed = $syncHash.WebView2.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), ".spotify.com", "/")
                $syncHash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed) 
              }
              $Cookies = $cookies -split ';'
              $sp_dc = $cookies | where {$_ -match 'sp_dc=(?<value>.*)'}         
              if($sp_dc){
                $existin_sp_dc = ([regex]::matches($sp_dc,  'sp_dc=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Spotify_SP_DC = $existin_sp_dc
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found SP_DC $($existin_sp_dc | out-string)" -showtime}                              
              } 
              $Youtube_1PSID = $cookies | where {$_ -match '__Secure-1PSID=(?<value>.*)'}         
              if($Youtube_1PSID){
                $existin_Youtube_1PSID = ([regex]::matches($Youtube_1PSID,  '__Secure-1PSID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PSID = $existin_Youtube_1PSID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 1PSID: $($existin_Youtube_1PSID | out-string)" -showtime}                              
              }
              $Youtube_1PAPISID = $cookies | where {$_ -match '__Secure-1PAPISID=(?<value>.*)'}         
              if($Youtube_1PAPISID){
                $existin_Youtube_1PAPISID = ([regex]::matches($Youtube_1PAPISID,  '__Secure-1PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PAPISID = $existin_Youtube_1PAPISID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 1PAPISID: $($existin_Youtube_1PAPISID | out-string)" -showtime}                              
              }
              $Youtube_3PAPISID = $cookies | where {$_ -match '__Secure-3PAPISID=(?<value>.*)'}         
              if($Youtube_3PAPISID){
                $existin_Youtube_3PAPISID = ([regex]::matches($Youtube_3PAPISID,  '__Secure-3PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_3PAPISID = $existin_Youtube_3PAPISID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 3PAPISID: $($existin_Youtube_3PAPISID | out-string)" -showtime}                              
              }                                          
            }
          }catch{
            write-ezlogs "An exception occurred in CoreWebView2 WebResourceRequested Event" -showtime -catcherror $_
          }
          #write-ezlogs "WebResourceRequested $($e.Request.Headers | select * | out-string)"
          #$e.Request.Headers.SetHeader("Cookie", 'SID=KQgPGs5UY1PvovZsn6NeF_nWO26TOfYigsbOP7iByFo9AFaD3MmPobrH496G5dBCqgWHPA.');
          #$addedDate = $e.Request.Headers.GetHeader("Cookie");
      })
      if($synchash.Youtube_WebPlayer_URL){
        if($synchash.Youtube_WebPlayer_URL -match 'Spotify Embed'){
          write-ezlogs "Navigating with CoreWebView2.NavigateToString: $($synchash.Youtube_WebPlayer_URL)" -enablelogs -Color cyan -showtime
          $synchash.WebView2.CoreWebView2.NavigateToString($synchash.Youtube_WebPlayer_URL)
        }else{
          write-ezlogs "Navigating with CoreWebView2.Navigate: $($synchash.Youtube_WebPlayer_URLL)" -enablelogs -Color cyan -showtime
          $synchash.WebView2.CoreWebView2.Navigate($synchash.Youtube_WebPlayer_URL)
        }       
      }elseif($synchash.Spotify_WebPlayer_URL){
        if($synchash.Spotify_WebPlayer_URL -match 'Spotify Embed'){
          write-ezlogs "Navigating with CoreWebView2.NavigateToString: $($synchash.Spotify_WebPlayer_URL)" -enablelogs -Color cyan -showtime
          $synchash.WebView2.CoreWebView2.NavigateToString($synchash.Spotify_WebPlayer_URL)
        }else{
          write-ezlogs "Navigating with CoreWebView2.Navigate: $($synchash.Spotify_WebPlayer_URL)" -enablelogs -Color cyan -showtime
          $synchash.WebView2.CoreWebView2.Navigate($synchash.Spotify_WebPlayer_URL)
        }      
      }      
      $synchash.Webview2.CoreWebView2.add_IsDocumentPlayingAudioChanged({
          <#          $synchash.WebView2.ExecuteScriptAsync(
              $synchash.Webview2_Script
        
          )#>
          if($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio){
            #write-ezlogs ">>>> Webview2 Audio has begun playing: Audio: $($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio) Mute: $($synchash.Webview2.CoreWebView2.IsMuted)" -showtime
            $synchash.Timer.Stop() 
            $synchash.WebPlayer_Playing_timer.Start()         

          }elseif(!$synchash.Webview2.CoreWebView2.IsMuted -and !$synchash.WebMessageReceived -and !$synchash.Webview2.IsMouseOver -and !$synchash.Webview2.IsMouseCaptured -and !$synchash.Webview2.IsMouseDirectlyOver -and !$synchash.Webview2.IsMouseCapturedChanged -and !$synchash.VLC_Grid.IsMouseOver -and $synchash.WebMessageReceived -notmatch 'progress-control' -and $synchash.WebMessageReceived -notmatch 'playsinline' -and $synchash.WebMessageReceived -notmatch 'youtube'){        
            #$synchash.WebMessageReceived -notmatch 'progress-control' -and $synchash.WebMessageReceived -notmatch 'playsinline' -and $synchash.WebMessageReceived -notmatch 'youtube'
            if($thisApp.Config.Verbose_Logging){
              write-ezlogs "Webview2 mouse over: $($synchash.Webview2.IsMouseOver)"
              write-ezlogs "Webview2 mouse captured: $($synchash.Webview2.IsMouseCaptured)"
              write-ezlogs "Webview2 mouse directly over: $($synchash.Webview2.IsMouseDirectlyOver)" 
              write-ezlogs "Webview2 mouse captured changed: $($synchash.Webview2.IsMouseCapturedChanged)"
              write-ezlogs "vlc grid mouse over: $($synchash.VLC_Grid.IsMouseOver)"
            }
          }
      })
      
      $synchash.Webview2.CoreWebView2.add_IsMutedChanged({
          if($synchash.Webview2.CoreWebView2.IsMuted){
            write-ezlogs "#### Webview2 Audio has been muted" -showtime       
          }else{
            write-ezlogs "#### Webview2 Audio has been un-muted" -showtime
          }
      })
      
    }.GetNewClosure()
  )
 
  
  $synchash.WebView2.add_WebMessageReceived({
      try{
        $results = $args.WebMessageAsJson | ConvertFrom-Json
        #$synchash.WebMessageReceived = $result.value
        #write-ezlogs "Web message received: $($args | Out-String)" -showtime
        #$synchash.MediaPlayer_CurrentDuration = $result
        foreach($result in $results){
          if($result.key -eq 'time'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received Time: $($result.value)" -showtime}
            $synchash.MediaPlayer_CurrentDuration = $result.value
          }
          if($result.key -eq 'state'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received State: $($result.value)" -showtime}
            $synchash.WebPlayer_State = $result.value
            if($synchash.WebPlayer_State -eq 1){
              $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.Header.id -eq $synchash.Current_playing_media.id} | select -Unique 
              if($current_playing.header.PlayIconVisibility -eq 'Hidden'){
                $Current_playing.Header.FontWeight = 'Bold'
                $Current_playing.Header.FontSize = 16 
                $current_playing.Header.PlayIcon = "CompactDiscSolid"
                $current_playing.Header.PlayIconPause = ""
                $current_playing.Header.NumberVisibility = "Hidden"
                $current_playing.Header.NumberFontSize = 0
                $current_playing.Header.PlayIconPauseVisibility = "Hidden"   
                $current_playing.Header.PlayIconVisibility = "Visibile" 
                $current_playing.Header.PlayIconEnabled = $true  
                $synchash.PlayQueue_TreeView.items.refresh()
              }
            }elseif($synchash.WebPlayer_State -eq 2){
              $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.Header.id -eq $synchash.Current_playing_media.id} | select -Unique 
              if($current_playing.header.PlayIconVisibility -eq 'Visibile'){          
                $Current_playing.Header.FontWeight = 'Bold'
                $Current_playing.Header.FontSize = 16 
                $current_playing.Header.PlayIconPause = "CompactDiscSolid"
                $current_playing.Header.NumberVisibility = "Hidden"
                $current_playing.Header.NumberFontSize = 0
                $current_playing.Header.PlayIconPauseVisibility = "Visibile"   
                $current_playing.Header.PlayIconVisibility = "Hidden" 
                $current_playing.Header.PlayIconEnabled = $true  
                $synchash.PlayQueue_TreeView.items.refresh()
              } 
            }
          }
          if($result.key -eq 'player_data'){
            #if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received Player_data: $($result.value | out-string)" -showtime}
            $synchash.MediaView_TextBlock.text = $result.value.title
            #write-ezlogs "Title: $($result.value.title)" -showtime
          } 
          if($result.key -eq 'video_data'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received video_data: $($result.value | out-string)" -showtime}
            $synchash.Invidious_webplayer_current_Media = $result.value
            #write-ezlogs "Params: $($result.value.params | out-string)" -showtime
          } 
          if($result.key -eq 'duration'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received duration: $($result.value | out-string)" -showtime}
            $synchash.MediaPlayer_TotalDuration = $result.value
          }
          if($result.key -eq 'volume'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received volume: $($result.value | out-string)" -showtime}
            $synchash.MediaPlayer_CurrentVolume = $result.value
          } 
          if($result.key -eq 'videodata'){
            $synchash.Youtube_webplayer_current_Media = $result.value
            #if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received videodata : $($result.value | out-string)" -showtime}
          }
          if($result.key -eq 'videoUrl'){
            #if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received videoUrl : $($result.value | out-string)" -showtime}
          } 
          if($result.key -eq 'error'){
            write-ezlogs "Web message received error : $($result.value | out-string)" -showtime -warning
            if($result.value -eq '150'){
              write-ezlogs "Youtube ERROR 150, usually means this video is not allowed to be played outside of youtube.com, try using invidious instead" -showtime -warning
              Update-Notifications  -Level 'WARNING' -Message "Youtube ERROR 150, usually means this video is not allowed to be played outside of youtube.com, try using invidious instead" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
            }
          } 
          if($result.key -eq 'Spotify_state'){
            if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received Spotify_state: $($result.value)" -showtime}
            #write-ezlogs "Web message received Spotify_state: $($result.value | out-string)" -showtime
            #write-ezlogs "track_window: $($result.value.track_window | out-string)" -showtime
            #write-ezlogs "Position: $($result.value.position | out-string)" -showtime
            $synchash.Spotify_WebPlayer_State = $result.value            
            if($synchash.Spotify_WebPlayer_State.current_track.name){
              $synchash.MediaView_TextBlock.text = $synchash.Spotify_WebPlayer_State.current_track.name
            }
            if($synchash.Spotify_WebPlayer_State.duration){
              $synchash.MediaPlayer_TotalDuration = [timespan]::FromMilliseconds($synchash.Spotify_WebPlayer_State.duration).TotalSeconds
            }  
            if($synchash.Spotify_WebPlayer_State.newposition){
              $synchash.MediaPlayer_CurrentDuration = $synchash.Spotify_WebPlayer_State.newposition
            }
          }
          if($result.key -eq 'Spotify_volume'){
            #write-ezlogs "Web message received Spotify_volume: $($result.value | out-string)" -showtime
            #$synchash.MediaPlayer_CurrentVolume = $result.value
          }                                                                    
        }   
      }catch{
        write-ezlogs 'An exception occurred in Webview2 WebMessageReceived event' -showtime -catcherror $_
      } 
  })

}
#---------------------------------------------- 
#endregion Initialize-WebPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebBrowser Function
#----------------------------------------------
Function Initialize-WebBrowser
{
  param (
    $synchash,
    $thisApp,
    $thisScript
  ) 
  try{
    #$synchash.Web_BrowserTab.Visibility = 'Visible'
    $synchash.WebBrowserOptions = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new("--autoplay-policy=no-user-gesture-required")
    $synchash.WebBrowserOptions.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
    $synchash.WebBrowserEnv = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
      [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.WebBrowserOptions
    )
    $synchash.WebBrowserEnv.GetAwaiter().OnCompleted(
      [Action]{
        $synchash.WebBrowser.EnsureCoreWebView2Async( $synchash.WebBrowserEnv.Result )
      
      }.GetNewClosure() 
    )
  }catch{
    write-ezlogs "An exception occurred creating WebBrowser Enviroment" -showtime -catcherror $_
  }

  $synchash.WebBrowser.Add_NavigationCompleted(
    [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
      #write-ezlogs "Navigation completed: $($synchash.WebView2.source | out-string)" -showtime
      $synchash.WebBrowser_Script = @"
document.addEventListener('click', function (event)
{
    let elem = event.target;
    let jsonObject =
    {
        Key: 'click',
        Value: elem.outerHTML || "Unkown" 
    };
    window.chrome.webview.postMessage(jsonObject);
});
"@      
              
      $synchash.WebBrowser.ExecuteScriptAsync(
        $synchash.WebBrowser_Script       
      )
           
      #$synchash.WebView2.CoreWebView2.PostWebMessageAsString("copy");  
    }
  )   
  $synchash.WebBrowser.Add_CoreWebView2InitializationCompleted(
    [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
      #$MainForm.Add_Activated([EventHandler]{ If ( 0 -cne $MODE_FULLSCREEN ) { $MainForm.Add_FormClosing($CloseHandler) } })
      #$MainForm.Add_Deactivate([EventHandler]{ $MainForm.Remove_FormClosing($CloseHandler) })
      #& $ProcessNoDevTools
      try{
        [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.WebBrowser.CoreWebView2.Settings
        $Settings.AreDefaultContextMenusEnabled  = $true
        $Settings.AreDefaultScriptDialogsEnabled = $true
        $Settings.AreDevToolsEnabled             = $true
        $Settings.AreHostObjectsAllowed          = $true
        $Settings.IsBuiltInErrorPageEnabled      = $false
        $Settings.IsScriptEnabled                = $true
        $Settings.IsStatusBarEnabled             = $true
        $Settings.IsWebMessageEnabled            = $true
        $Settings.IsZoomControlEnabled           = $false
        $Settings.IsGeneralAutofillEnabled       = $false
        $Settings.IsPasswordAutosaveEnabled      = $false   
        $syncHash.WebBrowser.CoreWebView2.AddWebResourceRequestedFilter("*", [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All);     
        if($thisApp.Config.Spotify_SP_DC){
          write-ezlogs "Adding Spotify Cookie $($thisApp.Config.Spotify_SP_DC)" -showtime
          $OptanonAlertBoxClosed = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), ".spotify.com", "/")
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed)           
          $sp_dc = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('sp_dc', $thisApp.Config.Spotify_SP_DC, ".spotify.com", "/")
          $sp_dc.IsSecure=$true
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($sp_dc)   
        }
        if($thisApp.Config.Youtube_1PSID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_1PSID)" -showtime
          $Youtube_1PSID = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('__Secure-1PSID', $thisApp.Config.Youtube_1PSID, ".youtube.com", "/")
          $Youtube_1PSID.IsSecure=$true
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie( $Youtube_1PSID) 
          $PREF = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('PREF', 'tz=America.New_York&f6=400', ".youtube.com", "/")
          $PREF.IsSecure=$true
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($PREF)                   
        }
        if($thisApp.Config.Youtube_1PAPISID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_1PAPISID)" -showtime
          $Youtube_1PAPISID = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('__Secure-1PAPISID', $thisApp.Config.Youtube_1PAPISID, ".youtube.com", "/")
          $Youtube_1PAPISID.IsSecure=$true
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_1PAPISID)                   
        } 
        if($thisApp.Config.Youtube_3PAPISID){
          write-ezlogs "Adding Youtube Cookie $($thisApp.Config.Youtube_3PAPISID)" -showtime
          $Youtube_3PAPISID = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('__Secure-3PAPISID', $thisApp.Config.Youtube_3PAPISID, ".youtube.com", "/")
          $Youtube_3PAPISID.IsSecure=$true
          $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_3PAPISID)                   
        } 
                                    
      }catch{
        write-ezlogs "An exception occurred in CoreWebView2InitializationCompleted Event" -showtime -catcherror $_
      } 
      $synchash.WebBrowser.CoreWebView2.add_WebResourceRequested({
          [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e = $args[1]
          try{
            $Cookies = ($e.Request.Headers | where {$_.key -eq 'cookie'}).value
            if($Cookies){
              if($Cookies -notmatch 'OptanonAlertBoxClosed'){
                $OptanonAlertBoxClosed = $syncHash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), ".spotify.com", "/")
                $syncHash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed) 
              }
              $Cookies = $cookies -split ';'
              $sp_dc = $cookies | where {$_ -match 'sp_dc=(?<value>.*)'}         
              if($sp_dc){
                $existin_sp_dc = ([regex]::matches($sp_dc,  'sp_dc=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Spotify_SP_DC = $existin_sp_dc
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found SP_DC $($existin_sp_dc | out-string)" -showtime}                              
              } 
              $Youtube_1PSID = $cookies | where {$_ -match '__Secure-1PSID=(?<value>.*)'}         
              if($Youtube_1PSID){
                $existin_Youtube_1PSID = ([regex]::matches($Youtube_1PSID,  '__Secure-1PSID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PSID = $existin_Youtube_1PSID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 1PSID: $($existin_Youtube_1PSID | out-string)" -showtime}                              
              }
              $Youtube_1PAPISID = $cookies | where {$_ -match '__Secure-1PAPISID=(?<value>.*)'}         
              if($Youtube_1PAPISID){
                $existin_Youtube_1PAPISID = ([regex]::matches($Youtube_1PAPISID,  '__Secure-1PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PAPISID = $existin_Youtube_1PAPISID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 1PAPISID: $($existin_Youtube_1PAPISID | out-string)" -showtime}                              
              }
              $Youtube_3PAPISID = $cookies | where {$_ -match '__Secure-3PAPISID=(?<value>.*)'}         
              if($Youtube_3PAPISID){
                $existin_Youtube_3PAPISID = ([regex]::matches($Youtube_3PAPISID,  '__Secure-3PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_3PAPISID = $existin_Youtube_3PAPISID
                if($thisApp.Config.Verbose_Logging){write-ezlogs "Found Youtube 3PAPISID: $($existin_Youtube_3PAPISID | out-string)" -showtime}                              
              }                                          
            }
          }catch{
            write-ezlogs "An exception occurred in CoreWebView2 WebResourceRequested Event" -showtime -catcherror $_
          }
      })
      if($synchash.WebBrowser_url){
        $synchash.WebBrowser.CoreWebView2.Navigate($synchash.WebBrowser_url) 
      }else{
        $synchash.WebBrowser.CoreWebView2.Navigate('https://www.youtube.com') 
      }
     
      $synchash.WebBrowser.CoreWebView2.add_IsDocumentPlayingAudioChanged({

          if($synchash.WebBrowser.CoreWebView2.IsDocumentPlayingAudio){
            write-ezlogs ">>>> Webview2 Audio has begun playing: Audio: $($synchash.WebBrowser.CoreWebView2.IsDocumentPlayingAudio) Mute: $($synchash.WebBrowser.CoreWebView2.IsMuted)" -showtime
          }elseif(!$synchash.WebBrowser.CoreWebView2.IsMuted){        

          }
      })  
      $synchash.WebBrowser.CoreWebView2.add_IsMutedChanged({
          if($synchash.WebBrowser.CoreWebView2.IsMuted){
            write-ezlogs "#### WebBrowser Audio has been muted" -showtime       
          }else{
            write-ezlogs "#### WebBrowser Audio has been un-muted" -showtime
          }
      })


      $synchash.WebBrowser.CoreWebView2.add_ContextMenuRequested({
          [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuRequestedEventArgs]$e = $args[1]
          $sender = $args[0]
          try{
            #write-ezlogs "sender: $($args[0] | select * | out-string)" -showtime
            #write-ezlogs "e: $($e | select * | out-string)" -showtime
            #write-ezlogs "eResourceContext: $($e.ResourceContext | select * | out-string)" -showtime
            #write-ezlogs "eRequest: $($e.Request | select * | out-string)" -showtime
            #write-ezlogs "ContextMenuTarget $($e.ContextMenuTarget | select * | out-string)"
            function New-ContextMenu{
              [CmdletBinding()]
              Param(
                $e,
                $menulist,
                $cm
              )       
              for($i = 0; $i -lt $menulist.count; $i++){
                $current = $menuList[$i]
                if ($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Separator)
                {
                  $Separator = New-object System.Windows.Controls.Separator
                  $null = $cm.Items.Add($Separator);
                  continue;
                }
                $menuItem = new-object System.Windows.Controls.MenuItem
                $menuitem.Header = $current.label -replace '&','_'

                $menuitem.InputGestureText = $current.ShortcutKeyDescription
                $menuitem.IsEnabled = $current.IsEnabled
                if ($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Submenu)
                {
                  #$PopulateContextMenu(args, current.Children, newItem);
                  New-ContextMenu -e $e -menulist $current.children -cm $menuItem
                }
                else
                {
                  if ($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::CheckBox -or $current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Radio)
                  {
                    $menuitem.IsCheckable = $true
                    $menuitem.IsChecked = $current.IsChecked;
                  }

                  $menuitem.add_Click({
                      $e.SelectedCommandId = $current.CommandId;
                  }.GetNewClosure())
                }
                $null = $cm.Items.add($menuItem)
              }
            }
            #write-ezlogs "Webbrowser message received: $($e | Out-String)" -showtime
            $menuList = $e.MenuItems
            #$deferral = $e.GetDeferral()
            #$e.Handled = $true
            #$contextMenu = New-Object System.Windows.Controls.ContextMenu
            #$contextMenu.Add_closed({
            #$deferral.Complete()
            #}.GetNewClosure())
            #New-ContextMenu -e $e -menulist $menulist -cm $contextMenu
            #$contextmenu.IsOpen = $true
            if($e.ContextMenuTarget.LinkUri -match 'youtube' -and ($e.ContextMenuTarget.LinkUri -match 'v=' -or $e.ContextMenuTarget.LinkUri -match 'list=')){
              if($e.ContextMenuTarget.LinkUri -match 'v='){
                #Download    
                $image_bytes = [System.IO.File]::ReadAllBytes("$($thisApp.Config.Current_folder)\\Resources\\Material-Download.png")
                $stream_image = [System.IO.MemoryStream]::new($image_bytes) 
                [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$DownloadMedia = $synchash.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Download and add to Media Library",$stream_image,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                $DownloadMedia.add_CustomItemSelected({
                    $LinkUri = $e.ContextMenuTarget.LinkUri
                    $linktext = $e.contextMenuTarget.LinkText    
                    try{  
                      $result = Open-FolderDialog -Title 'Select the directory path where media will be downloaded to'
                      if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-url $LinkUri) -and [System.IO.Directory]::Exists($result)){
                        write-ezlogs ">>>> Downloading $($linktext) to $result" -showtime
                        Invoke-DownloadMedia -Download_URL $LinkUri -Title_name $linktext -Download_Path $result -synchash $synchash -thisapp $thisapp -Show_notification
                      }else{
                        write-ezlogs "The provided URL or path is not valid or was not provided! -- Link: $LinkUri - Directory: $result" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
                      }                
                    }catch{
                      write-ezlogs 'An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
                    }                                   
                }.GetNewClosure())
                $menuList.Insert(0, $DownloadMedia);
              }       
              #$icon = [System.Drawing.Image]::FromStream($stream_image) 
              $image_bytes = [System.IO.File]::ReadAllBytes("$($thisApp.Config.Current_folder)\\Resources\\Material-Youtube.png")
              $stream_image = [System.IO.MemoryStream]::new($image_bytes) 
              [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$AddMedia = $synchash.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Add to Youtube Media Library",$stream_image,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
              $AddMedia.add_CustomItemSelected({
                  $LinkUri = $e.ContextMenuTarget.LinkUri
                  $linktext = $e.contextMenuTarget.LinkText    
                  try{  
                    if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-url $LinkUri)){
                      if($thisApp.Config.PlayLink_OnDrop){
                        Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -thisScript $thisScript -LinkUri $LinkUri -linktext $linktext
                      }
                      write-ezlogs ">>>> Adding Youtube video $LinkUri - $($linktext)" -showtime -color cyan -logfile:$thisApp.Config.YoutubeMedia_logfile
                      Import-Youtube -Youtube_URL $LinkUri -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $Synchash.PlayMedia_Command -thisApp $thisapp   
                    }else{
                      write-ezlogs "The provided URL is not valid or was not provided! -- $LinkUri" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
                    }                
                  }catch{
                    write-ezlogs 'An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
                  }                                   
              }.GetNewClosure())
              $image_bytes = [System.IO.File]::ReadAllBytes("$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.ico")
              $stream_image = [System.IO.MemoryStream]::new($image_bytes) 
              [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$PlayMedia = $synchash.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Play with $($thisApp.Config.App_name)",$stream_image,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
              $PlayMedia.add_CustomItemSelected({
                  $LinkUri = $e.ContextMenuTarget.LinkUri
                  $linktext = $e.contextMenuTarget.LinkText    
                  try{  
                    if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-url $LinkUri)){
                      if($LinkUri -match '&t='){
                        $LinkUri = ($($LinkUri) -split('&t='))[0].trim()
                      }          
                      write-ezlogs ">>>> Playing Youtube link $LinkUri" -showtime -color cyan
                      if($LinkUri -match "v="){
                        $youtube_id = ($($LinkUri) -split('v='))[1].trim()    
                      }elseif($LinkUri -match 'list='){
                        $youtube_id = ($($LinkUri) -split('list='))[1].trim()                  
                      }  
                      Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -thisScript $thisScript -youtube_id $youtube_id -LinkUri $LinkUri -linktext $linktext
                      #write-ezlogs ">>>> Adding Youtube video $LinkUri - $($linktext)" -showtime -color cyan -logfile:$thisApp.Config.YoutubeMedia_logfile
                      #Import-Youtube -Youtube_URL $LinkUri -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $Synchash.PlayMedia_Command -thisApp $thisapp   
                    }else{
                      write-ezlogs "The provided URL is not valid or was not provided! -- $LinkUri" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
                    }                
                  }catch{
                    write-ezlogs 'An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
                  }                                   
              }.GetNewClosure())
              $menuList.Insert(0, $AddMedia);   
              $menuList.Insert(0, $PlayMedia);        
            }
          }catch{
            write-ezlogs 'An exception occurred in WebBrowser ContextMenuRequested event' -showtime -catcherror $_
          } 
      })           
    }.GetNewClosure()
  )

  $synchash.GoToPage.Add_click({
      try{
        Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp
      }catch{
        write-ezlogs 'An exception occurred in GoToPage Click event' -showtime -catcherror $_
      }
  })

  $synchash.txturl.Add_KeyDown({
      [System.Windows.Input.KeyEventArgs]$e = $args[1] 
      try{
        if($e.key -eq 'Return'){
          Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp
        }  
      }catch{
        write-ezlogs 'An exception occurred in texturl keydown event' -showtime -catcherror $_
      }    
  })

  $synchash.WebBrowser.Add_SourceChanged({        
      try{
        $synchash.txtUrl.text = $synchash.WebBrowser.Source
        $synchash.WebBrowser.Reload()
      }catch{
        write-ezlogs 'An exception occurred in WebBrowser Source changed event' -showtime -catcherror $_
      } 
  }) 


  $synchash.BrowseBack.Add_click({
      try{
        $synchash.WebBrowser.GoBack(
      )}catch{
        write-ezlogs 'An exception occurred in BrowseBack Click event' -showtime -catcherror $_
      }
  })
  $synchash.BrowseForward.Add_click({
      try{
        $synchash.WebBrowser.GoForward()
      }catch{
        write-ezlogs 'An exception occurred in BrowseForward click event' -showtime -catcherror $_
      }  
  })
  $synchash.BrowseRefresh.Add_click({
      try{
        $synchash.WebBrowser.Reload()
      }catch{
        write-ezlogs 'An exception occurred in BrowseRefresh click event' -showtime -catcherror $_
      } 
  })  
  
  $synchash.WebBrowser.add_WebMessageReceived({
      try{
        $results = $args.WebMessageAsJson | ConvertFrom-Json
        #$synchash.WebMessageReceived = $result.value
       
        #$synchash.MediaPlayer_CurrentDuration = $result
        foreach($result in $results){
          write-ezlogs "Webbrowser message received: $($results.value | Out-String)" -showtime                           
        }   
      }catch{
        write-ezlogs 'An exception occurred in WebBrowser WebMessageReceived event' -showtime -catcherror $_
      } 
  })
}
#---------------------------------------------- 
#endregion Initialize-WebBrowser Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-ChatView Function
#----------------------------------------------
Function Initialize-ChatView
{
  param (
    $synchash,
    $thisApp,
    [string]$chat_url
  ) 
  try{
    #chat_webview2

    $synchash.chat_WebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
    $synchash.chat_WebView2.Name = 'chat_WebView2'
    $synchash.chat_WebView2.MaxWidth="500"
    $synchash.chat_WebView2.Visibility="hidden" 
    $synchash.chat_WebView2.VerticalAlignment="Stretch"
    $null = $synchash.ChatWebview2_Grid.addchild($synchash.chat_WebView2)
    $synchash.chatWebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
    $synchash.chatWebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
    $synchash.chatWebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
      [String]::Empty, [IO.Path]::Combine( [String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.chatWebView2Options
    )
    if(!$synchash.chat_WebView2.CoreWebView2){
      $synchash.chatWebView2Env.GetAwaiter().OnCompleted(
        [Action]{
          try{
            $synchash.chat_WebView2.EnsureCoreWebView2Async($synchash.chatWebView2Env.Result)
          }catch{
            write-ezlogs "An exception occurred inintializing corewebview2 enviroment" -showtime -catcherror $_
          }
        }
      )
    }
    $synchash.chat_WebView2.Add_NavigationCompleted(
      [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
        $synchash.chat_WebView2.ExecuteScriptAsync(
          @"
document.addEventListener('click', function (event)
{
    let elem = event.target;
    let jsonObject =
    {
        Key: 'click',
        Value: elem.outerHTML || "Unkown" 
    };
    window.chrome.webview.postMessage(jsonObject);
});
"@)  
        #$synchash.WebView2.CoreWebView2.PostWebMessageAsString("copy");  
      }
    )   
    $synchash.chat_WebView2.Add_CoreWebView2InitializationCompleted(
      [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
  
        try{
          [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.chat_WebView2.CoreWebView2.Settings
          $Settings.AreDefaultContextMenusEnabled  = $true
          $Settings.AreDefaultScriptDialogsEnabled = $false
          $Settings.AreDevToolsEnabled             = $false
          $Settings.AreHostObjectsAllowed          = $true
          $Settings.IsBuiltInErrorPageEnabled      = $false
          $Settings.IsScriptEnabled                = $true
          $Settings.IsStatusBarEnabled             = $false
          $Settings.IsWebMessageEnabled            = $true
          $Settings.IsZoomControlEnabled           = $false  
          $synchash.chat_WebView2.CoreWebView2.AddWebResourceRequestedFilter("*", [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All);     
          if($thisApp.Config.Chat_WebView2_Cookie){           
            $twilight_user_cookie = $synchash.chat_WebView2.CoreWebView2.CookieManager.CreateCookie('twilight-user', $thisApp.Config.Chat_WebView2_Cookie, ".twitch.tv", "/")
            $twilight_user_cookie.IsSecure=$true
            $synchash.chat_WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($twilight_user_cookie)    
          } 
        }catch{
          write-ezlogs "An exception occurred in CoreWebView2InitializationCompleted Event" -showtime -catcherror $_
        } 
        $synchash.chat_WebView2.CoreWebView2.add_WebResourceRequested({
            [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e = $args[1]
            try{
              $Cookies = ($e.Request.Headers | where {$_.key -eq 'cookie'}).value
              if($Cookies){
                $Cookies = $cookies -split ';'
                $twilight_user = $cookies | where {$_ -match 'twilight-user=(?<value>.*)'}         
                if($twilight_user){
                  $existin_twilight_user = ([regex]::matches($twilight_user,  'twilight-user=(?<value>.*)')| %{$_.groups[1].value} )
                  $thisApp.Config.Chat_WebView2_Cookie = $existin_twilight_user
                  if($thisApp.Config.Verbose_logging){write-ezlogs "Found existing twilight_user $($existin_twilight_user | out-string)" -showtime}                  
                }
              }
            }catch{
              write-ezlogs "An exception occurred in CoreWebView2 WebResourceRequested Event" -showtime -catcherror $_
            }
        })
        if(Test-URL $synchash.ChatView_URL){
          write-ezlogs "Navigating ChatView with CoreWebView2.NavigateToString: $($chat_url)" -enablelogs -Color cyan -showtime
          $synchash.chat_WebView2.CoreWebView2.Navigate($synchash.ChatView_URL)     
        }
      }
    )
    $synchash.chat_WebView2.add_WebMessageReceived({
        try{
          $result = $args.WebMessageAsJson | ConvertFrom-Json
          #write-ezlogs "chat_WebView2 message received: $($result.value | out-string)" -showtime
        }catch{
          write-ezlogs 'An exception occurred in chat_Webview2 WebMessageReceived event' -showtime -catcherror $_
        }
    })

  }catch{
    write-ezlogs "An exception occurred creating chatwebview2 Enviroment" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Initialize-ChatView Function
#----------------------------------------------
Export-ModuleMember -Function @('Initialize-WebPlayer','Initialize-WebBrowser','Initialize-ChatView')