<#
    .Name
    Set-WebPlayerTimers

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and manages DispatcherTimer's used for Web Players  

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
#region Set-WebPlayerTimer Function
#----------------------------------------------
function Set-WebPlayerTimer
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Verboselog
  )
  try{
    if($Startup){
      $synchash.WebPlayer_Playing_timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.WebPlayer_Playing_timer.Interval = [timespan]::new(0,0,0,0,500)
      $synchash.WebPlayer_Playing_timer.Add_Tick({
          try{
            $thisApp = $thisApp
            $synchash = $synchash
            $Current_Playing_Id = $null
            if(($synchash.Youtube_WebPlayer_title -or $synchash.Spotify_WebPlayer_title) -and ($synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -or $synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -or $synchash.Webview2.CoreWebView2.IsMuted -or $synchash.YoutubeWebView2.CoreWebView2.IsMuted) -or ($synchash.WebPlayer_State -ne 0 -or $synchash.Spotify_WebPlayer_State.playbackstate -ne 0)){        
              if($synchash.Youtube_WebPlayer_title){
                if($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|invidious'){
                  $synchash.YoutubeWebView2_Script = @"
`n
var player_data = JSON.parse(document.getElementById('player_data').textContent);
var video_data = JSON.parse(document.getElementById('video_data').textContent);
var time = player.currentTime();

var volume = player.volume();
var paused = player.paused();
var ended = player.ended();
var last = lastUpdated;

if(ended){
  console.log('Media Ended');
  var state = 0;
}else if (paused) {
  console.log('paused');
  var state = 2;
}else{
   var state = 1; 
}
if(lastUpdated !== time && time <= video_data.length_seconds - 15) {
   const all_video_times = get_all_video_times();
   console.log('Saving time', time);
   //save_video_time(time);
   all_video_times[video_data.id] = time;
   helpers.storage.set(save_player_pos_key, all_video_times);
   lastUpdated = time;
}
//console.log(time);
  var jsonObject =
  {
    Key: 'state',
    Value: state 
  };

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
  var volumeObject =
  {
    Key: 'volume',
    Value: volume 
  };
  var endedObject =
  {
    Key: 'ended',
    Value: ended 
  };
    window.chrome.webview.postMessage(jsonObject);
    window.chrome.webview.postMessage(volumeObject);
    window.chrome.webview.postMessage(playerdataJson);  
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(playerObject);
    window.chrome.webview.postMessage(timeJson);
    window.chrome.webview.postMessage(pausedObject);
    window.chrome.webview.postMessage(endedObject);

"@
                }else{
                  $synchash.YoutubeWebView2_Script =  @" 
 try{
    //console.log('Checking for player state');
    var player = document.getElementById('movie_player');
    var state = player.getPlayerState();
    var videourl = player.getVideoUrl();
   } catch (e) {
     console.log('Exception occurred getting youtube player and state',e);
    } 
    try {
      //var isFullScreen = player.isFullscreen();    
         if(state == 1 && !document.fullscreen && !videourl.match('tv.youtube.com')){
           console.log('Requesting FullScreen',state);
           player.requestFullscreen();
           FullScreenSet = true;
         }else if (state == 2 && !document.fullscreen && !videourl.match('tv.youtube.com')){
           console.log('Requesting FullScreen',state);
           player.requestFullscreen();
           FullScreenSet = true;
         }
      } catch (e) {
         console.log('Exception occurred executing player.isFullscreen()',e);
     } 

        if (!FullScreenButtonSet) {
          try {
           var fullscreen_button = document.getElementsByClassName("ytp-fullscreen-button");
          } catch (e) {
           console.log('Exception occurred getting fullscreen button elements', e);
          }
	        try {
		        if (fullscreen_button.length > 0 && !FullScreenButtonSet) {
              console.log('Registering fullscreen button events');
			        fullscreen_button[0].addEventListener("click", function (event) {
				        try {
					        var isFullScreen = player.isFullscreen();
				        } catch (e) {
					        console.log('Exception occurred getting fullscreen state', e);
				        }
				        //var isFullScreen = player.isFullscreen();
				        console.log('FullScreen Button Clicked');
				        if (isFullScreen) {
					        console.log('isFullScreen', isFullScreen);
				        } else {
					        console.log('Requesting FullScreen');
					        player.requestFullscreen();
				        }
				        var fullscreenbuttonObject = {
					        Key: 'fullscreenbutton',
					        Value: event
				        };
				        window.chrome.webview.postMessage(fullscreenbuttonObject);
				        try {
					        var fullScreenMsg = document.getElementsByClassName("ytp-popup ytp-generic-popup");
					        if (fullScreenMsg.length > 0) {
					          if(fullScreenMsg[0].innerText == 'Full screen is unavailable. Find out more') {
						          fullScreenMsg[0].replaceWith('')
						          console.log('Removed fullscreen warning message');
					          }
					        }
				        } catch (e) {
					        console.log('Exception occurred removing fullscreen unavailable message', e);
				        }
			        });
			        FullScreenButtonSet = true;
			        console.log('Adding Fullscreen_Button event listener', fullscreen_button[0]);
		        }
	        } catch (e) {
		        console.log('Exception occurred registering fullscreen button event listener', e);
	        }
        }
      try {
        if (!QualitySet) {
          QualitySet = true;
          var oldquality = player.getPlaybackQuality();
          console.log('Current Quality:', oldquality);
          const levels = player.getAvailableQualityLevels();
          let quality = JSON.parse(localStorage.getItem('yt-player-quality'));
	        if ('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'Auto'.toLowerCase()) {
		        quality = levels.find(function (levels) {
			        return levels === "auto"
		        });
	        } else if ('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'medium'.toLowerCase()) {
		        quality = levels.find(function (levels) {
			        return levels === "medium"
		        });
	        } else if ('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'low'.toLowerCase()) {
		        quality = levels.find(function (levels) {
			        return levels === "small"
		        });
	        } else if ('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'Best'.toLowerCase()) {
		        quality = levels[0];
	        }
	        if (!levels.includes(quality)) {
		        quality = levels[0];
	        }
          if(quality !== null && oldquality !== quality){
	          console.log('Setting Quality to', quality);
	          player.setPlaybackQualityRange(quality, quality);
	          var newquality = player.getPlaybackQuality();
	          if (newquality) {
		          QualitySet = true;
	          }
	          console.log('New Quality:', newquality);
          }
          var newqualitylabel = player.getPlaybackQualityLabel();
		      var currentquality = {
			      Key: 'currentquality',
			      Value: newqualitylabel
		      };
		      window.chrome.webview.postMessage(currentquality);
        }
      } catch (e) {
	      console.log('Exception occurred getting getting or setting playback quality', e);
      }
  try {
   if (!PlayerStateEvent) {
    console.log('Registering Youtube Player state event');
    player.addEventListener("onStateChange", onYouTubePlayerStateChange);
    PlayerStateEvent = true;
   }
  } catch (e) {
   console.log('Exception occurred adding EventListener to youtube player', e);
  }
  try {
   if (!PlayerErrorEvent) {
    console.log('Registering Youtube Player error event');
    	player.addEventListener("onError", onYouTubeError);
    PlayerErrorEvent = true;
   }
  } catch (e) {
   console.log('Exception occurred adding error EventListener to youtube player', e);
  }
  //var fullscreen_button = document.getElementsByClassName("ytp-fullscreen-button");
  try {
    var videodata = player.getVideoData();
    var time = player.getCurrentTime();
    var duration = player.getDuration();
    var isMuted = player.isMuted();
    var volume = player.getVolume();
    var MuteStatus =
    {
      Key: 'MuteStatus',
      Value: isMuted
    };
    var timeJson =
    {
      Key: 'time',
      Value: time 
    };
    var statejsonObject =
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
    window.chrome.webview.postMessage(MuteStatus);
    window.chrome.webview.postMessage(statejsonObject);
    window.chrome.webview.postMessage(durationObject);
    window.chrome.webview.postMessage(volumeObject);
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(videoUrlObject);
    var Playerlabel = document.getElementById('id-player-main');
    if(Playerlabel){
      var PlayerlabelObject =
      {
        Key: 'Playerlabel',
        Value: Playerlabel.ariaLabel
      };
      window.chrome.webview.postMessage(PlayerlabelObject);
    }
  } catch (e) {
   console.log('Exception occurred posting webview messages', e);
  }
    try {
	    var fullScreenMsg = document.getElementsByClassName("ytp-popup ytp-generic-popup");
	    if (fullScreenMsg.length > 0) {
	      if(fullScreenMsg[0].innerText == 'Full screen is unavailable. Find out more') {
		      fullScreenMsg[0].replaceWith('')
		      console.log('Removed fullscreen warning message');
	      }
	    }
    } catch (e) {
	    console.log('Exception occurred removing fullscreen unavailable message', e);
    }
"@         
          
                }      
                $synchash.YoutubeWebView2.ExecuteScriptAsync(
                  $synchash.YoutubeWebView2_Script       
                ) 
                $Current_Playing_Id = $synchash.Current_playing_media.id
                if($synchash.FullScreen_Player_Button){
                  $synchash.FullScreen_Player_Button.isEnabled = $true
                }                        
              }elseif($synchash.Spotify_WebPlayer_title){
                $synchash.Webview2_Script = @"

var state = getStatePosition();
//console.log(state);
	  var Spotify_state =
	  {
		Key: 'Spotify_state',
		Value: state
	  };
		window.chrome.webview.postMessage(Spotify_state);	
 SpotifyWeb.player.getVolume().then(volume => {
  let volume_percentage = volume * 100;
	  var Spotify_volume =
	  {
		Key: 'Spotify_volume',
		Value: volume
	  };
		window.chrome.webview.postMessage(Spotify_volume);	
   //console.log('The volume of the player is', volume_percentage);
});
"@
                if($synchash.WebView2){
                  $synchash.WebView2.ExecuteScriptAsync(
                    $synchash.Webview2_Script       
                  )
                }
                $Current_Playing_Id = $synchash.Last_Played
                if($synchash.FullScreen_Player_Button){
                  $synchash.FullScreen_Player_Button.isEnabled = $false
                }                
              }
              $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
              if($Current_playlist_items){
                $queue_index = $Current_playlist_items.id.indexof($Current_Playing_Id)
                if($queue_index -ne -1){
                  $Current_playing = $Current_playlist_items[$queue_index]
                }else{
                  $Current_playing = $Current_playlist_items.where({$_.id -eq $Current_Playing_Id}) | select -Unique
                }
              } 
              if(!$Current_playing){
                write-ezlogs '| Item does not seem to be in the queue' -showtime -warning
                if($thisapp.config.Current_Playlist.values -notcontains $Current_Playing_Id){
                  write-ezlogs "| Adding $($Current_Playing_Id) to Play Queue" -showtime
                  $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                  $index++
                  $null = $thisapp.config.Current_Playlist.add($index,$Current_Playing_Id)         
                }else{
                  write-ezlogs "| Play queue already contains $($Current_Playing_Id), refreshing" -showtime -warning
                }
                Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Export_Config  
                $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
                if($Current_playlist_items){
                  $queue_index = $Current_playlist_items.id.indexof($Current_Playing_Id)
                  if($queue_index -ne -1){
                    $Current_playing = $Current_playlist_items[$queue_index]
                  }else{
                    $Current_playing = $Current_playlist_items.where({$_.id -eq $Current_Playing_Id}) | select -Unique
                  }
                }        
                if(!$Current_playing){
                  write-ezlogs "| Still couldnt find $($Current_Playing_Id) in the play queue, looping!" -showtime -warning
                }else{
                  write-ezlogs '| Found current playing item after adding it to the play queue and refreshing the play queue' -showtime -warning
                }                      
              }
              if(($synchash.Youtube_WebPlayer_title -and $synchash.WebPlayer_State -eq 2) -or ($synchash.Spotify_WebPlayer_title -and $synchash.Spotify_WebPlayer_State.Paused)){
                #write-ezlogs "[WebPlayer] Received Paused status from web player (Youtube state: $($synchash.WebPlayer_State)) - (Spotify state: $($synchash.Spotify_WebPlayer_State)) - (Current media: $($synchash.Current_playing_media.title))" -showtime
                $synchash.Now_Playing_Label.DataContext = "PAUSED" 
                $synchash.Now_Playing_Label.Visibility = 'Visible'
                $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'    
                return           
              }else{
                $synchash.Now_Playing_Label.Visibility = 'Visible'
                $synchash.Now_Playing_Label.DataContext = "PLAYING" 
                $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
              }               
              if($synchash.Invidious_webplayer_current_Media -and ($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|')){
                if($synchash.Invidious_webplayer_current_Media.length_seconds -match ":"){
                  $total_time = $synchash.Invidious_webplayer_current_Media.length_seconds
                }else{
                  $a = $synchash.Invidious_webplayer_current_Media.length_seconds
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  if($hrs -lt 1){
                    $hrs = '0'
                  }  
                  $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))" 
                }         
              }elseif($synchash.MediaPlayer_TotalDuration){
                if($synchash.MediaPlayer_TotalDuration -match ":"){
                  $total_time =$synchash.MediaPlayer_TotalDuration       
                }else{
                  $a = $($synchash.MediaPlayer_TotalDuration)
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  if($hrs -lt 1){
                    $hrs = '0'
                  }  
                  $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
                }
              }
              try{
                if($synchash.MediaPlayer_CurrentDuration -match ":"){
                  $total_time = $synchash.MediaPlayer_CurrentDuration
                }else{
                  if($synchash.Spotify_WebPlayer_State.current_track.id){
                    $a = $($([timespan]::FromMilliseconds($synchash.MediaPlayer_CurrentDuration)).TotalSeconds)                      
                  }else{
                    $a = $synchash.MediaPlayer_CurrentDuration
                  }
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  if($hrs -lt 1){
                    $hrs = '0'
                  }  
                  $current_Progress = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"       
                }
                if(!$synchash.MediaPlayer_Slider.isEnabled){
                  write-ezlogs ">>>> Enabling MediaPlayer_Slider slider" -Dev_mode
                  $synchash.MediaPlayer_Slider.isEnabled = $true
                }
                if($synchash.MediaPlayer_TotalDuration -and $synchash.MediaPlayer_Slider.Maximum -ne $synchash.MediaPlayer_TotalDuration){
                  $synchash.MediaPlayer_Slider.Maximum = $synchash.MediaPlayer_TotalDuration
                }
                if($a -and !$synchash.MediaPlayer_Slider.IsMouseOver -and !$synchash.VideoView_Progress_Slider.IsMouseOver -and !$synchash.Mini_Progress_Slider.IsMouseOver){
                  $synchash.MediaPlayer_Slider.Value = $a
                  if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
                    $synchash.Main_TaskbarItemInfo.ProgressState = 'Normal'
                  }
                }else{
                  #$synchash.MediaPlayer_Slider.ToolTip = $synchash.Media_Length_Label.content
                  $synchash.MediaPlayer_Slider.ToolTip = "$current_Progress" + " / " + "$total_time"
                  $synchash.VideoView_Progress_Slider.ToolTip = $synchash.MediaPlayer_Slider.ToolTip
                  $synchash.Mini_Progress_Slider.ToolTip = $synchash.MediaPlayer_Slider.ToolTip
                } 
                #$synchash.Media_Length_Label.text = "$current_Progress" + " / " + "$total_time"
                if($synchash.VideoView_Current_Length_TextBox){
                  $synchash.VideoView_Current_Length_TextBox.text = $current_Progress
                }
                if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
                  $synchash.VideoView_Total_Length_TextBox.text = $total_time
                }
                if($synchash.Media_Current_Length_TextBox -and $synchash.Media_Current_Length_TextBox.DataContext -ne $current_Progress){
                  $synchash.Media_Current_Length_TextBox.DataContext = $current_Progress
                }
                if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.DataContext -ne $total_time){
                  $synchash.Media_Total_Length_TextBox.DataContext = $total_time
                }
                if($synchash.MiniPlayer_Media_Length_Label -and $synchash.MiniPlayer_Media_Length_Label.Content -ne "$current_Progress"){
                  $synchash.MiniPlayer_Media_Length_Label.Content = "$current_Progress"
                }                      
              }catch{
                write-ezlogs "An exception occurred parsing current play duration for web player" -showtime -catcherror $_
              }                                       

              if(!$Current_playing){    
                try{
                  write-ezlogs "| Couldnt get current playing item with id $($Current_Playing_Id) from queue! Executing Get-PlayQueue" -showtime -warning    
                  $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
                  if($Current_playlist_items){
                    $queue_index = $Current_playlist_items.id.indexof($Current_Playing_Id)
                    if($queue_index -ne -1){
                      $Current_playing = $Current_playlist_items[$queue_index]
                    }else{
                      $Current_playing = $Current_playlist_items.where({$_.id -eq $Current_Playing_Id}) | select -Unique
                    }
                  }     
                  if(!$Current_playing){
                    if($thisapp.config.Current_Playlist.values -notcontains $Current_Playing_Id){
                      write-ezlogs '| Item does not seem to be in the queue' -showtime -warning
                      write-ezlogs "| Adding $($Current_Playing_Id) to Play Queue" -showtime
                      $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                      $index++
                      $null = $thisapp.config.Current_Playlist.add($index,$Current_Playing_Id)      
                      Get-PlayQueue -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Export_Config                         
                    }else{
                      write-ezlogs "| Play queue already contains $($Current_Playing_Id), refreshing" -showtime -warning
                      Get-PlayQueue -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
                    }
                    $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
                    if($Current_playlist_items){
                      $queue_index = $Current_playlist_items.id.indexof($Current_Playing_Id)
                      if($queue_index -ne -1){
                        $Current_playing = $Current_playlist_items[$queue_index]
                      }else{
                        $Current_playing = $Current_playlist_items.where({$_.id -eq $Current_Playing_Id}) | select -Unique
                      }
                    }      
                    if(!$Current_playing){
                      write-ezlogs "[ERROR] | Still couldnt find $($Current_Playing_Id) in the play queue, looping!" -showtime -color red
                      return
                    }else{
                      write-ezlogs '| Found current playing item after adding it to the play queue and refreshing Get-PlayQueue' -showtime -warning
                    }                      
                  }else{
                    write-ezlogs '| Found current playing item after refreshing Get-PlayQueue' -showtime
                  }   
                }catch{
                  write-ezlogs "An exception occurred in WebPlayer_Playing_timer while trying to update/get current playing items" -showtime -catcherror $_
                }  
              }elseif($Current_playing.title){   
                if($Current_playing.FontWeight -ne 'Bold'){ 
                  if($synchash.PlayQueue_TreeView.itemssource){
                    $synchash.PlayQueue_TreeView.itemssource.refresh()
                  }elseif($synchash.PlayQueue_TreeView.items){
                    $synchash.PlayQueue_TreeView.items.refresh()
                  } 
                  $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
                  if($Current_playlist_items){
                    $queue_index = $Current_playlist_items.id.indexof($Current_Playing_Id)
                    if($queue_index -ne -1){
                      $Current_playing = $Current_playlist_items[$queue_index]
                    }else{
                      $Current_playing = $Current_playlist_items.where({$_.id -eq $Current_Playing_Id}) | select -Unique
                    }
                  }
                  if($synchash.Now_Playing_Title_Label.DataContext -notmatch [regex]::Escape("$($Current_playing.title)")){
                    $synchash.Now_Playing_Label.DataContext = "PLAYING" 
                    $synchash.Now_Playing_Label.Visibility = 'Visible'
                    $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
                  }
                  try{           
                    $Current_playing.FontWeight = 'Bold'
                    $Current_playing.FontSize = [Double]'13' 
                    if($synchash.AudioRecorder.isRecording){
                      $current_playing.PlayIconRecord = "RecordRec"
                      $current_playing.PlayIconRecordVisibility = "Visible"
                      $current_playing.PlayIconRecordRepeat = "Forever"
                      $current_playing.PlayIconVisibility = "Hidden"
                      $current_playing.PlayIconRepeat = "1x"
                    }else{
                      $current_playing.PlayIconRecordVisibility = "Hidden"
                      $current_playing.PlayIconRecordRepeat = "1x"
                      if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                        $current_playing.PlayIconRepeat = "Forever"
                        $current_playing.PlayIconEnabled = $true  
                      }else{
                        write-ezlogs "| Performance_Mode enabled - Disabling playicon animation" -Warning -Dev_mode
                        $current_playing.PlayIconRepeat = "1x"
                        $current_playing.PlayIconEnabled = $false
                      }                     
                      $current_playing.PlayIconVisibility = "Visible"
                      $current_playing.PlayIcon = "CompactDiscSolid"
                    }
                    $current_playing.NumberVisibility = "Hidden"
                    $current_playing.NumberFontSize = [Double]'0.1'                    
                    if($synchash.PlayQueue_TreeView.itemssource){
                      $synchash.PlayQueue_TreeView.itemssource.refresh()
                    }elseif($synchash.PlayQueue_TreeView.items){
                      $synchash.PlayQueue_TreeView.items.refresh()
                    }                          
                  }catch{
                    write-ezlogs "An exception occurred updating properties for current_playing $($current_playing | out-string)" -showtime -catcherror $_
                  }  
                  try{
                    $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                    $synchash.Update_Playing_Playlist_Timer.start()             
                  }catch{
                    write-ezlogs "An exception occurred updating properties for current_playing $($current_playing | out-string)" -showtime -catcherror $_
                  }                                       
                }                                  
              }elseif($Current_playing.Header){
                #$Current_playing.Header = "---> $($Current_playing.Header)"
                if($synchash.Now_Playing_Title_Label.DataContext -notmatch [regex]::Escape("$($Current_playing.Header)")){
                  $synchash.Now_Playing_Label.DataContext = "PLAYING"
                  $synchash.Now_Playing_Label.Visibility = 'Visible'
                  $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
                }
              }       
            }elseif(($synchash.Youtube_WebPlayer_title -or $synchash.Spotify_WebPlayer_title) -and (($synchash.WebPlayer_State -eq 0 -or $synchash.Spotify_WebPlayer_State.playbackstate -eq 0)) -and !$synchash.Invidious_webplayer_current_Media -and !$synchash.Spotify_WebPlayer -and !$synchash.Spotify_WebPlayer.is_started){
              write-ezlogs "[WebPlayer] >>>> WebPlayer finished playing, removing $($synchash.Current_playing_media.id) from queue " -showtime        
              $synchash.WebMessageReceived = $Null
              Update-Playlist -Playlist 'Play Queue' -media $synchash.Current_playing_media -synchash $synchash -thisApp $thisApp -Remove -clear_lastplayed
              $synchash.Last_played = $Null
              $synchash.Youtube_WebPlayer_title = $Null
              $synchash.Spotify_WebPlayer_title = $Null
              $synchash.Temporary_Playback_Media = $null
              if($thisapp.config.Auto_Repeat){
                write-ezlogs "[WebPlayer] >>>> Repeat is enabled, restarting current track" -showtime
                if($synchash.Current_playing_media.source -eq 'Spotify' -or $synchash.Current_playing_media.url -match 'spotify\:'){
                  Start-SpotifyMedia -Media $synchash.Current_playing_media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
                }else{
                  Start-Media -Media $synchash.Current_playing_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification -restart
                }                
              }elseif($thisapp.config.Auto_Playback){
                write-ezlogs "[WebPlayer] >>>> Checking for and starting next track" -showtime
                $synchash.Timer.start()
              }
              $this.Stop()
            }else{
              write-ezlogs ">>>> Stopping WebPlayer_Playing_timer" -showtime
              $synchash.WebPlayer_State = 0
              $synchash.WebMessageReceived = $Null
              $this.Stop()
            }                                              
          }catch{
            write-ezlogs 'An exception occurred executing WebPlayer_Playing_timer' -showtime -catcherror $_
            $this.Stop()
          }  
      })     
    }elseif($start){
      if($synchash.WebPlayer_Playing_timer.isEnabled){
        if($thisApp.Config.Dev_mode){write-ezlogs "WebPlayer_Playing_timer is already started" -showtime -warning -Dev_mode}
      }else{
        write-ezlogs ">>>> Starting WebPlayer_Playing_timer" -showtime
        $synchash.WebPlayer_Playing_timer.start()
      }    
    }elseif($stop){
      if($synchash.WebPlayer_Playing_timer.isEnabled){
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Stopping WebPlayer_Playing_timer" -showtime -Dev_mode}
        $synchash.WebPlayer_Playing_timer.stop()
      }else{
        if($thisApp.Config.Dev_mode){write-ezlogs "WebPlayer_Playing_timer cant be stopped as it is not enabled/running" -showtime -warning -Dev_mode}
      }
    }      
  }catch{
    write-ezlogs 'An exception occurred in Set-WebPlayerTimer' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Set-WebPlayerTimer Function
#----------------------------------------------

#----------------------------------------------
#TODO: REFACTOR TO MODULE 
#region Spotify WebPlayer Timer
#----------------------------------------------
function Set-SpotifyWebPlayerTimer
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Start,
    [switch]$Stop,
    [switch]$LogLevel
  )
  try{
    if($Startup){
      $synchash.Spotify_WebPlayer_timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.Spotify_WebPlayer_timer.Add_Tick({
          try{
            $synchash = $synchash
            $thisApp = $thisApp
            if($synchash.FullScreen_Player_Button){
              $synchash.FullScreen_Player_Button.isEnabled = $false
            }           
            if($thisapp.config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title){
              if($syncHash.YoutubeWebView2 -ne $null -and $syncHash.YoutubeWebView2.CoreWebView2 -ne $null){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] >>>> Disposing youtube webplayer Webview2 instance" -showtime
                $synchash.YoutubeWebView2.dispose()
              }              
              if($synchash.Webview2_Grid.children -contains $synchash.Webview2){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] >>>> Removing Spotify Webview2 from Webview2_Grid" -showtime
                $Null = $synchash.Webview2_Grid.children.Remove($synchash.Webview2)
              }
              <#              if($synchash.VLC_Grid.children -contains $synchash.VideoView){
                  $synchash.VLC_Grid.children.Remove($synchash.VideoView)
              }#>
              if($synchash.MainGrid.children -notcontains $synchash.Webview2){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] >>>> Adding Spotify Webview2 to TitleMenuGrid" -showtime
                $Null = $synchash.MainGrid.AddChild($synchash.Webview2) 
              }         
              $Beforeindex = $synchash.MediaViewAnchorable.isSelected
              $synchash.MediaViewAnchorable.isSelected = $true                                    
              if($synchash.VideoView.Visibility -in 'Hidden','Collapsed'){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] | UnHiding VideoView" -showtime
                $synchash.VideoView.Visibility = 'Visible'
              }   
              $synchash.VLC_Grid.Visibility="Visible"
              #$synchash.Webview2.updatelayout()      
              $synchash.MediaViewAnchorable.isSelected = $Beforeindex  
              $synchash.MediaPlayer_Slider.isEnabled = $true
              $synchash.Webview2.Visibility = 'Visible'
              if($thisApp.Config.dev_mode){
                $synchash.Webview2.Height = '5'
                $synchash.Webview2.VerticalAlignment = 'Top'
                $synchash.Webview2.HorizontalAlignment = 'Left'
                $synchash.Webview2.Width ='5'
              }else{
                $synchash.Webview2.Height = '1'
                $synchash.Webview2.VerticalAlignment = 'Top'
                $synchash.Webview2.HorizontalAlignment = 'Left'
                $synchash.Webview2.Width ='1'
              }
              #[System.Windows.Controls.Panel]::SetZIndex($synchash.Webview2,-1)
              $synchash.Now_Playing_Label.Visibility = 'Visible'
              $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
              if($synchash.PlayIcon1_Storyboard.Storyboard){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Begin
              }
              if(!$synchash.PlayButton_ToggleButton.isChecked){
                $synchash.PlayButton_ToggleButton.isChecked = $true
              }
              if(($synchash.Current_playing_media.title) -and ($synchash.Current_playing_media.artist -or $synchash.Current_playing_media.Artist_Name)){
                if($synchash.Current_playing_media.artist){
                  $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.Current_playing_media.artist)"
                }elseif($synchash.Current_playing_media.Artist_Name){
                  $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.Current_playing_media.Artist_Name)"
                }else{
                  $synchash.Now_Playing_Artist_Label.DataContext = ""
                }        
              }else{
                $synchash.Now_Playing_Artist_Label.DataContext = ""
              }
              if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.Current_playing_media.Bitrate -ne '0'){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
              }elseif(-not [string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.DisplayPanel_VideoQuality_TextBlock.text -ne $synchash.Current_Video_Quality){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = $synchash.Current_Video_Quality
              }elseif([string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_VideoQuality_TextBlock.text)){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = $Null
              }
              <#              if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.Current_playing_media.Bitrate -ne '0'){
                  $synchash.DisplayPanel_Bitrate_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
                  $synchash.DisplayPanel_Sep3_Label.Visibility = 'Visible'
                  }else{
                  $synchash.DisplayPanel_Bitrate_TextBlock.text = ""
                  $synchash.DisplayPanel_Sep3_Label.Visibility = 'Hidden'
              }#>
              if(-not [string]::IsNullOrEmpty($synchash.VideoView_ViewCount_Label.text)){
                $synchash.VideoView_ViewCount_Label.text = $Null
                $synchash.VideoView_Sep3_Label.Text = $Null
                $synchash.VideoView_ViewCount_Label.Visibility = 'Hidden'
              }
              <#              if($synchash.Main_tool_icon.text){
                  [int]$character_Count = ($synchash.Now_Playing_Label.text | measure-object -Character -ErrorAction SilentlyContinue).Characters
                  if([int]$character_Count -ge 64){
                  $Synchash.Main_Tool_Icon.Text = ($synchash.Now_Playing_Label.text).substring(0, [System.Math]::Min(62, ($synchash.Now_Playing_Label.text).Length))
                  }else{
                  $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.text     
                  }
              }#>
              if($synchash.MediaPlayer_CurrentDuration){
                if($synchash.MediaPlayer_CurrentDuration -match ":"){
                  $total_time = $synchash.MediaPlayer_CurrentDuration        
                }else{
                  [int]$a = $($synchash.MediaPlayer_CurrentDuration / 1000);
                  [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds) 
                  if($hrs -lt 1){
                    $hrs = '0'
                  }  
                  $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
                }
              } 
              #$synchash.Media_Length_Label.content = "$total_time"
              #$synchash.Media_Length_Label.text = "$total_time"
              if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
                $synchash.VideoView_Total_Length_TextBox.text = $total_time
              }     
              if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.DataContext -ne $total_time){
                $synchash.Media_Total_Length_TextBox.DataContext = $total_time
              }                                       
              if($synchash.MiniPlayer_Media_Length_Label){
                $synchash.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
              }                                
              Start-WebNavigation -uri $synchash.Spotify_WebPlayer_URL -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp                     
            }elseif($synchash.VLC_Grid.Children.Name -contains 'Webview2'){
              Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
              Start-WebNavigation -uri "$($thisApp.Config.Current_Folder)\Resources\Spotify\SpotifyWebPlayerTemplate.html" -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp     
              if($synchash.TitleMenuGrid.Children.Name -contains 'Webview2'){
                $synchash.TitleMenuGrid.children.Remove($synchash.Webview2)  
              }                       
              if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] >>>> Replacing Spotify WebPlayer with Vlc VideoView" -showtime
                $synchash.VLC_Grid.AddChild($synchash.VideoView)       
              }
              if($synchash.Webview2_Grid.children -notcontains $synchash.Webview2){
                $synchash.Webview2_Grid.AddChild($synchash.Webview2)       
              }              
              #$synchash.Webview2_Grid.updatelayout()
              if($synchash.VideoView.Visibility -in 'Hidden','Collapsed'){
                write-ezlogs "[Set-SpotifyWebPlayerTimer] | Unhiding VideoView" -showtime
                $synchash.VideoView.Visibility = 'Visible'
              }      
              $synchash.VLC_Grid.Visibility="Visible"
              $synchash.Spotify_WebPlayer_title = '' 
              $synchash.MediaPlayer_Slider.Value = 0
              $synchash.MediaPlayer_Slider.isEnabled = $false
              if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'None'){
                $synchash.Main_TaskbarItemInfo.ProgressState = 'None'
              }
              #$synchash.VLC_Grid.UpdateLayout() 
              #$synchash.Webview2.updatelayout()          
            }         
            $this.Stop()                                    
          }catch{
            write-ezlogs '[Set-SpotifyWebPlayerTimer] An exception occurred executing Spotify_WebPlayer_timer' -showtime -catcherror $_
            $this.Stop()
            Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
          }
          $this.Stop()     
      })   
    }else{
      if(!$synchash.Spotify_WebPlayer_timer.isEnabled){
        $synchash.Spotify_WebPlayer_timer.tag = [PSCustomObject]::new(@{
            'Startup' = $Startup
            'Start' = $Start
            'Stop' = $Stop
            'LogLevel' = $LogLevel
        }) 
        $synchash.Spotify_WebPlayer_timer.start()     
      }else{
        write-ezlogs "[Set-SpotifyWebPlayerTimer] Spotify_WebPlayer_timer is already enabled, not executing start() again" -warning
      }   
    }   
  }catch{
    write-ezlogs 'An exception occurred in Set-SpotifyWebPlayerTimer' -showtime -catcherror $_
  }
}
#----------------------------------------------
#endregion Spotify WebPlayer Timer
#----------------------------------------------

#----------------------------------------------
#region Youtube WebPlayer Timer
#----------------------------------------------
function Set-YoutubeWebPlayerTimer
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Start,
    [switch]$Stop,
    [switch]$No_YT_Embed,
    [switch]$LogLevel
  )
  try{
    if($Startup){
      $synchash.TrayPlayerQueueFlyoutScriptBlock = {
        Param($Sender)
        try{
          if($Sender.isOpen){
            write-ezlogs ">>>> $($Sender.name) is open, setting VideoViewTransparentBackground Maxheight and MaxWidth to infinity"
            $synchash.VideoViewTransparentBackground.MaxHeight = [Double]::PositiveInfinity
          }else{
            write-ezlogs ">>>> $($Sender.name) is closed, setting VideoViewTransparentBackground Maxheight and MaxWidth to 60"
            $synchash.VideoViewTransparentBackground.MaxHeight = 60
          }
          $VideoViewAirControl = Get-VisualParentUp -source $synchash.VideoViewAirControl.front -type ([System.Windows.Window])
          if($VideoViewAirControl){
            if($synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.isVisible){
              $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.VideoViewFloat)
            }elseif($synchash.Window.isLoaded){
              $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
            }
            if($VideoViewAirControl -and $FloatingWindowOwner){
              write-ezlogs "| Setting VideoViewAirControl window owner to $($FloatingWindowOwner.Name)" -showtime
              $VideoViewAirControl.Owner = $FloatingWindowOwner
            }
          }
        }catch{
          write-ezlogs "An exception occurred in TrayPlayerQueueFlyoutScriptBlock.add_IsOpenChanged" -catcherror $_
        }
      }
      $synchash.Youtube_WebPlayer_timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.Youtube_WebPlayer_timer.Add_Tick({
          try{    
            $synchash = $synchash
            $thisApp = $thisApp
            $synchash.MediaView_Image.Source = $Null  
            if($synchash.FullScreen_Player_Button){
              $synchash.FullScreen_Player_Button.isEnabled = $false
            }             
            if($thisapp.config.Youtube_WebPlayer -and $synchash.Youtube_WebPlayer_URL -and $synchash.Youtube_WebPlayer_title -and !$this.tag.Stop){
              if($syncHash.WebView2 -ne $null -and $syncHash.WebView2.CoreWebView2 -ne $null){
                write-ezlogs "[Set-YoutubeWebPlayerTimer] >>>> Disposing Spotify webplayer Webview2 instance" -showtime
                $synchash.webview2.dispose()
                $syncHash.WebView2 = $null
              }
              if($synchash.Webview2_Grid.children -contains $synchash.YoutubeWebView2){
                $null = $synchash.Webview2_Grid.children.Remove($synchash.YoutubeWebView2)
              }
              if($synchash.VLC_Grid.Children -contains $synchash.VideoViewAirControl){
                Write-EZLogs '| Removing VideoViewAirControl from VLC_Grid'
                [void]$synchash.VLC_Grid.children.Remove($synchash.VideoViewAirControl)
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
              if($synchash.VideoViewTransparentBackground -and !$synchash.VideoViewAirControl){
                Write-EZLogs '>>>> Creating new Airhack control for VideoViewTransparentBackground (front) and YoutubeWebView2 (Back)' -showtime
                $synchash.VideoViewAirControl = [airhack.aircontrol]::new()
                $synchash.VideoViewAirControl.MinHeight = 1
                $synchash.VideoViewAirControl.MinWidth = 1
                #$synchash.VideoViewAirControl.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
                $synchash.VideoViewAirControl.SetValue([System.Windows.Controls.Grid]::RowSpanProperty,3)
                if($synchash.VideoView_Overlay_Grid.Children -contains $synchash.VideoViewTransparentBackground){
                  write-ezlogs "| Removing TrayPlayerQueue_FlyoutControl from VideoViewTransparentBackground"
                  $synchash.VideoView_Overlay_Grid.Children.Remove($synchash.VideoViewTransparentBackground)
                }
                $synchash.VideoViewAirControl.Front = $synchash.VideoViewTransparentBackground
                $synchash.VideoViewAirControl.Back = $synchash.YoutubeWebView2
                $synchash.VideoViewTransparentBackground.Visibility="Visible" 
                $synchash.YoutubeWebView2.Visibility="Visible"
              }
              if($synchash.VideoViewAirControl -and $synchash.VLC_Grid.children -notcontains $synchash.VideoViewAirControl){
                write-ezlogs "| Adding Youtube VideoViewAirControl to VLC_Grid" -showtime
                #$synchash.VideoViewAirStackPanel = [System.Windows.Controls.VirtualizingStackPanel]::new()
                #[void]$synchash.VideoViewAirStackPanel.AddChild($synchash.VideoViewAirControl)
                [void]$synchash.VLC_Grid.AddChild($synchash.VideoViewAirControl)
                $synchash.VideoViewTransparentBackground.Margin = '100,0,0,60'
                $synchash.TrayPlayerQueue_FlyoutControl.Margin = "0,0,0,0"
                $synchash.OverlayFlyoutBackground.Margin = "0,0,0,0"
                #$synchash.VideoViewTransparentBackground.MaxWidth = '600'
                $synchash.VideoViewTransparentBackground.HorizontalAlignment="Right"
                #$synchash.VideoViewTransparentBackground.Background="Transparent"
                $synchash.VideoViewOverlayTopGrid.Visibility = [System.Windows.Visibility]::Visible
                $synchash.OverlayFlyoutBackground.Style = $synchash.Window.TryFindResource('OverlayGridFade')
                $synchash.TrayPlayerQueueFlyout.Remove_IsOpenChanged($synchash.TrayPlayerQueueFlyoutScriptBlock)
                $synchash.TrayPlayerQueueFlyout.add_IsOpenChanged($synchash.TrayPlayerQueueFlyoutScriptBlock)
                if($synchash.TrayPlayerQueueFlyout.isOpen){
                  write-ezlogs "| TrayPlayerQueueFlyout is open, setting VideoViewTransparentBackground Maxheight and MaxWidth"
                  $synchash.VideoViewTransparentBackground.MaxHeight = [Double]::PositiveInfinity
                }else{
                  write-ezlogs "| TrayPlayerQueueFlyout is closed, setting VideoViewTransparentBackground Maxheight and MaxWidth to 100"
                  $synchash.VideoViewTransparentBackground.MaxHeight = 60
                  #$synchash.VideoViewTransparentBackground.MaxWidth = 400
                }
                if($synchash.VideoViewAirControl.front.parent.parent -is [System.Windows.Window]){
                  $synchash.VideoViewAirControl.front.parent.parent.MinHeight = 1
                  $synchash.VideoViewAirControl.front.parent.parent.MinWidth = 1
                  if($synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.isVisible){
                    write-ezlogs "| Setting VideoViewAirControl window owner to VideoViewFloat" -showtime
                    $synchash.VideoViewAirControl.front.parent.parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.VideoViewFloat)
                  }elseif($synchash.VideoViewAirControl.front.parent.parent -is [System.Windows.Window] -and $synchash.Window.isLoaded){
                    write-ezlogs "| Setting VideoViewAirControl window owner to main window" -showtime
                    $synchash.VideoViewAirControl.front.parent.parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
                  }
                }
                if($synchash.MiniPlayer_Viewer.isVisible){
                  #Force show/render main window to update visual tree
                  write-ezlogs "| Miniplayer is open, quickly showing/hiding main window to force visual tree update" -showtime
                  [void]$synchash.window.Hide()
                  $synchash.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
                  $synchash.window.Opacity = 0
                  $synchash.window.ShowInTaskbar = $false
                  [void]$synchash.window.Show()
                  #$synchash.window.Hide()
                  #$synchash.window.Opacity = 1
                  #$synchash.window.ShowActivated = $true
                }
              }
              <#              if($synchash.VLC_Grid.children -contains $synchash.VideoView){
                  write-ezlogs "[Set-YoutubeWebPlayerTimer] | Removing VideoView from VLC_Grid" -showtime
                  $null = $synchash.VLC_Grid.children.Remove($synchash.VideoView)
              }#>
              <#              if($synchash.YoutubeWebView2 -and $synchash.VLC_Grid.children -notcontains $synchash.YoutubeWebView2){
                  write-ezlogs "[Set-YoutubeWebPlayerTimer] >>>> Adding Youtube WebPlayer to VLC_Grid" -showtime
                  $null = $synchash.VLC_Grid.AddChild($synchash.YoutubeWebView2) 
                  $synchash.YoutubeWebView2.SetValue([System.Windows.Controls.Grid]::RowSpanProperty,3)
              }#>                     
              <#              if($synchash.VideoView_Grid.Visibility -eq 'Visible'){
                  $synchash.VideoView_Grid.Visibility = 'Hidden'
                  }
                  if($synchash.VideoView_Overlay_Grid.Visibility -eq 'Visible'){
                  $synchash.VideoView_Overlay_Grid.Visibility = 'Hidden'
              }#>
              if($synchash.VideoView.Visibility -eq 'Visible'){
                write-ezlogs "[Set-YoutubeWebPlayerTimer] >>>> Collapsing Vlc VideoView to display Youtube WebPlayer for youtube playback of url: $($synchash.Youtube_WebPlayer_URL)" -showtime 
                $synchash.VideoView.Visibility = 'Collapsed'
              }
              if($synchash.VideoView.Visibility -in 'Hidden','Collapsed' -and $synchash.VideoView_Grid -and $synchash.VideoView_Grid.Visibility -eq 'Visible'){
                write-ezlogs "[Set-YoutubeWebPlayerTimer] | Collapsing VideoView_Grid" -showtime -warning
                $synchash.VideoView_Grid.Visibility = 'Collapsed'           
              }
              $Beforeindex = $synchash.MediaLibraryAnchorable.isSelected
              $synchash.MediaViewAnchorable.isSelected = $true
              $synchash.MediaLibraryAnchorable.isSelected = $Beforeindex
              $synchash.VLC_Grid.Visibility="Visible"   
              $synchash.MediaPlayer_Slider.isEnabled = $false
              $synchash.Now_Playing_Label.Visibility = 'Visible'
              $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
              if($synchash.PlayIcon1_Storyboard.Storyboard){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Begin
              }
              if(!$synchash.PlayButton_ToggleButton.isChecked){
                $synchash.PlayButton_ToggleButton.isChecked = $true
              }
              if(($synchash.Current_playing_media.title) -and ($synchash.Current_playing_media.artist -or $synchash.Current_playing_media.Playlist)){
                if($synchash.Current_playing_media.artist){
                  $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.Current_playing_media.artist)"
                }elseif($synchash.Current_playing_media.Playlist){
                  $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.Current_playing_media.Playlist)"
                }else{
                  $synchash.Now_Playing_Artist_Label.DataContext = ""
                }
                if($synchash.Current_playing_media.title){
                  $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.Current_playing_media.title)"
                }        
              }elseif($synchash.Youtube_WebPlayer_title -and $synchash.Now_Playing_Title_Label.DataContext -ne "$($synchash.Youtube_WebPlayer_title)"){
                $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.Youtube_WebPlayer_title)"
                $synchash.Now_Playing_Artist_Label.DataContext = ""
              }else{
                $synchash.Now_Playing_Title_Label.DataContext = "Unknown Youtube Video"
                $synchash.Now_Playing_Artist_Label.DataContext = ""
              }
              if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.Current_playing_media.Bitrate -ne '0'){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
              }elseif(-not [string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.DisplayPanel_VideoQuality_TextBlock.text -ne $synchash.Current_Video_Quality){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = $synchash.Current_Video_Quality
              }elseif([string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_VideoQuality_TextBlock.text)){
                $synchash.DisplayPanel_VideoQuality_TextBlock.text = $Null
              }
              <#              if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.Current_playing_media.Bitrate -ne '0'){
                  $synchash.DisplayPanel_Bitrate_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
                  $synchash.DisplayPanel_Sep3_Label.Visibility = 'Visible'
                  }else{
                  $synchash.DisplayPanel_Bitrate_TextBlock.text = ""
                  $synchash.DisplayPanel_Sep3_Label.Visibility = 'Hidden'
              }#>
              if(-not [string]::IsNullOrEmpty($synchash.VideoView_ViewCount_Label.text)){
                $synchash.VideoView_ViewCount_Label.text = $Null
                $synchash.VideoView_Sep3_Label.Text = $Null
                $synchash.VideoView_ViewCount_Label.Visibility = 'Hidden'
              }       
              <#              if($synchash.Main_tool_icon.text){
                  [int]$character_Count = ($synchash.Now_Playing_Label.text | measure-object -Character -ErrorAction SilentlyContinue).Characters
                  if([int]$character_Count -ge 64){
                  $Synchash.Main_Tool_Icon.Text = ($synchash.Now_Playing_Label.text).substring(0, [System.Math]::Min(62, ($synchash.Now_Playing_Label.text).Length))
                  }else{
                  $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.text
                  }
              }#>
              if($synchash.MediaPlayer_CurrentDuration){
                if($synchash.MediaPlayer_CurrentDuration -match ":"){
                  $total_time = $synchash.MediaPlayer_CurrentDuration
                }else{
                  [int]$a = $($synchash.MediaPlayer_CurrentDuration / 1000)
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  if($hrs -lt 1){
                    $hrs = '0'
                  }
                  $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
                }
              }
              #$synchash.Media_Length_Label.text = "$total_time" + " / " + "$($synchash.MediaPlayer_TotalDuration)" 
              if($synchash.VideoView_Current_Length_TextBox){
                $synchash.VideoView_Current_Length_TextBox.text = $total_time
              }
              if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $($synchash.MediaPlayer_TotalDuration)){
                $synchash.VideoView_Total_Length_TextBox.text = $($synchash.MediaPlayer_TotalDuration)
              }
              if($synchash.Media_Current_Length_TextBox){
                $synchash.Media_Current_Length_TextBox.DataContext = $total_time
              }
              if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.DataContext -ne $($synchash.MediaPlayer_TotalDuration)){
                $synchash.Media_Total_Length_TextBox.DataContext = $($synchash.MediaPlayer_TotalDuration)
              }   
              if($synchash.MiniPlayer_Media_Length_Label){
                $synchash.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
              }      
              if($synchash.FullScreen_Player_Button){
                $synchash.FullScreen_Player_Button.isEnabled = $true
              }
              if($synchash.Youtube_WebPlayer_retry -eq 'NoEmbed'){
                $no_YT_Embed = $true
              }else{
                $no_YT_Embed = $false
              }               
              Start-WebNavigation -uri $synchash.Youtube_WebPlayer_URL -synchash $synchash -WebView2 $synchash.YoutubeWebView2 -thisApp $thisApp -No_YT_Embed:$this.tag.No_YT_Embed
              if($synchash.MiniPlayer_Viewer.isVisible -and !$synchash.MediaViewAnchorable.isFloating){
                write-ezlogs ">>>> Video view is not visible and MiniPlayer is visible, Youtube webplayer not playing, undocking video player" -Warning
                if($synchash.VideoViewFloat.Height){
                  $synchash.MediaViewAnchorable.FloatingHeight = $synchash.VideoViewFloat.Height
                }else{
                  $synchash.MediaViewAnchorable.FloatingHeight = '400'
                }                 
                $synchash.MediaViewAnchorable.float()
                if($synchash.VLC_Grid.Visibility -eq 'Hidden'){
                  write-ezlogs "| unhiding VLC_Grid" -Warning
                  $synchash.VLC_Grid.Visibility = 'Visible'
                }
              }elseif(!$synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer -and !$synchash.MediaViewAnchorable.isFloating){
                write-ezlogs "[Set-YoutubeWebPlayerTimer] >>>> Showing Video Player for Youtube media" -showtime
                Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Open
              }                             
            }else{
              Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
              $synchash.WebPlayer_State = 0
              write-ezlogs ">>>> Resetting and cleaning up UI and Webplayer resources" -showtime
              #TODO: Setting as nan is bad!
              if($synchash.VideoView -and $synchash.VideoView.Height -ne [Double]::NaN){
                #$synchash.VideoView.Height=[Double]::NaN
              }
              <#              if($synchash.VLC_Grid.children -contains $synchash.YoutubeWebView2){
                  $synchash.VLC_Grid.children.Remove($synchash.YoutubeWebView2)
              }#>
              if($syncHash.YoutubeWebView2 -ne $null -and $syncHash.YoutubeWebView2.CoreWebView2 -ne $null){
                write-ezlogs "| Disposing youtube webplayer Webview2 instance" -showtime
                $synchash.YoutubeWebView2.dispose()
                $synchash.YoutubeWebView2 = $Null
              }
              if($synchash.VLC_Grid.children -contains $synchash.Webview2){
                $synchash.VLC_Grid.children.Remove($synchash.Webview2)
              }
              if($syncHash.WebView2 -ne $null -and $syncHash.WebView2.CoreWebView2 -ne $null){
                write-ezlogs "| Disposing spotify webplayer Webview2 instance" -showtime 
                $synchash.webview2.dispose()
                $syncHash.WebView2 = $null
              }
              if($synchash.VLC_Grid.Children -contains $synchash.VideoViewAirControl){
                Write-EZLogs '| Removing VideoViewAirControl from VLC_Grid'
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
              if($synchash.VideoView_Overlay_Grid.children -notcontains $synchash.VideoViewTransparentBackground){
                Write-EZLogs '| Setting VideoViewTransparentBackground and adding back to VideoView_Overlay_Grid'
                $null = $synchash.VideoView_Overlay_Grid.AddChild($synchash.VideoViewTransparentBackground)
                $synchash.VideoViewTransparentBackground.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
                $synchash.VideoViewTransparentBackground.Margin = '0,0,0,35'
                $synchash.TrayPlayerQueue_FlyoutControl.Margin = "0,0,0,35"
                $synchash.OverlayFlyoutBackground.Margin = "0,0,0,35"
                $synchash.VideoViewTransparentBackground.MaxWidth = [Double]::PositiveInfinity
                $synchash.VideoViewTransparentBackground.HorizontalAlignment="Stretch"
                $synchash.OverlayFlyoutBackground.Style = $synchash.Window.TryFindResource('ResetOverlayGridFade')
                $synchash.VideoViewOverlayTopGrid.Visibility = [System.Windows.Visibility]::Collapsed
                $synchash.TrayPlayerQueueFlyout.Remove_IsOpenChanged($synchash.TrayPlayerQueueFlyoutScriptBlock)
                $synchash.VideoViewTransparentBackground.MaxHeight = [Double]::PositiveInfinity
                #$synchash.VideoViewTransparentBackground.MaxWidth = [Double]::PositiveInfinity
                #[void][System.Windows.Data.BindingOperations]::ClearAllBindings($synchash.OverlayFlyoutBackground)
                #$synchash.OverlayFlyoutBackground.Style = $Null
                #$synchash.OverlayFlyoutBackground.Opacity=1
                #$synchash.OverlayFlyoutBackground.SetValue([System.Windows.Controls.Grid]::StyleProperty,$Null)
                #$synchash.VideoView_Overlay_Grid.Style = $synchash.Window.TryFindResource('OverlayGridFade')
              }               
              if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
                Write-EZLogs '| Adding VideoView to VLC_Grid'
                $null = $synchash.VLC_Grid.AddChild($synchash.VideoView)
              } 
              if($synchash.VideoView.Visibility -in 'Hidden','Collapsed'){
                write-ezlogs "| Unhiding VideoView" -showtime
                $synchash.VideoView.Visibility = 'Visible'
              }
              if($synchash.VLC_Grid.Visibility -eq 'Hidden'){
                write-ezlogs "| Unhiding VLC_Grid" -showtime
                $synchash.VLC_Grid.Visibility="Visible"
              } 
              $synchash.Youtube_WebPlayer_title = $Null
            }         
            $this.Stop()                                    
          }catch{
            write-ezlogs '[Set-YoutubeWebPlayerTimer] An exception occurred executing Youtube_WebPlayer_timer' -showtime -catcherror $_
            $this.Stop()
            Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
          }
          $this.Stop()     
      })
    }else{
      if(!$synchash.Youtube_WebPlayer_timer.isEnabled){
        $synchash.Youtube_WebPlayer_timer.tag = [PSCustomObject]::new(@{
            'Startup' = $Startup
            'Start' = $Start
            'Stop' = $Stop
            'No_YT_Embed' = $No_YT_Embed
            'LogLevel' = $LogLevel
        }) 
        $synchash.Youtube_WebPlayer_timer.start()
      }else{
        write-ezlogs "[Set-YoutubeWebPlayerTimer] Youtube_WebPlayer_timer is already enabled, not executing start() again" -warning
      }   
    }
  }catch{
    write-ezlogs '[Set-YoutubeWebPlayerTimer] An exception occurred in Set-YoutubeWebPlayerTimer' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Youtube WebPlayer Timer
#----------------------------------------------
Export-ModuleMember -Function @('Set-WebPlayerTimer','Set-SpotifyWebPlayerTimer','Set-YoutubeWebPlayerTimer')