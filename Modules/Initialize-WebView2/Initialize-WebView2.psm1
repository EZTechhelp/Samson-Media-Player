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
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-Webview2Extensions
#----------------------------------------------
Function Get-Webview2Extensions{
  [CmdletBinding()]
  Param(
    $thisApp
  ) 
  try{
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
    $pattern = "[™₀$illegal]"
    $ExtensionsPath = "$($thisApp.Config.Current_Folder)\Resources\Webview2\Extensions"
    if(![system.io.directory]::Exists($ExtensionsPath)){
      [void][system.io.directory]::CreateDirectory($ExtensionsPath)
    }
    #Cleanup non-existing
    $paths = $thisApp.Config.Webview2_Extensions.path
    $paths | & { process {
        try{
          if($_){
            $Path = $_
            $Folder = [system.io.path]::GetFileName($_)
            $CurrentPath = [system.io.path]::Combine($ExtensionsPath,$Folder)
            if(-not [system.io.directory]::Exists($CurrentPath) -or $_ -ne $CurrentPath){
              $index = $thisApp.Config.Webview2_Extensions.path.IndexOf($_)
              if($index -ne -1){
                write-ezlogs "| Removing extension that cannot be found at path: $Path" -warning
                [void]$thisApp.Config.Webview2_Extensions.RemoveAt($index)
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred processing webview2 extension with path: $Path" -CatchError $_
        }
    }}
    $Null = [System.IO.Directory]::EnumerateFiles($ExtensionsPath,'manifest.json','AllDirectories') | & { process {
        $json = [system.io.file]::ReadAllText($_) | Convertfrom-json
        $Path = [system.io.path]::GetDirectoryName($_)
        $Icon = $Null
        if($json.Name -and $json.Name -notlike '__MSG*__'){
          $name = $json.Name
        }else{
          $name = $json.short_name
        }
        $name = ([Regex]::Replace($name, $pattern, '')).trim()
        if('Webview2_Extensions' -in $thisApp.Config.psobject.properties.name -and $Path -notin $thisApp.Config.Webview2_Extensions.path){
          $Size = '16'      
          if($json.icons.$Size){
            $Icon = "$($Path)\$($json.icons.$Size)"
          }else{
            $Size = $json.icons.psobject.properties.name | select -last 1
            if($Size){
              $Icon = "$($Path)\$($json.icons.$Size)"
            }
          }       
          $newRow = [WebExtension]@{
            'Name' = $name
            'ID' = ''
            'IsEnabled' = $true
            'Icon' = $Icon
            'path' = $Path
          }
          write-ezlogs ">>>> Adding new extension: $($name)" -logtype Webview2
          $null = $thisApp.Config.Webview2_Extensions.add($newRow)
        }elseif($Path -in $thisApp.Config.Webview2_Extensions.path){
          $index = $thisApp.Config.Webview2_Extensions.name.IndexOf($name)
          if($index -ne -1){
            $Extension = $thisApp.Config.Webview2_Extensions[$index]
            if($Extension.path -ne $Path){
              write-ezlogs ">>>> Updating extension ($($Extension.Name)) with new path: $Path" -logtype Webview2
              $Extension.path = $Path
            }
            $Size = '16'                            
            if($json.icons.$Size){
              $Icon = "$($Path)\$($json.icons.$Size)"
            }else{
              $Size = $json.icons.psobject.properties.name | Select-Object -last 1
              if($Size){
                $Icon = "$($Path)\$($json.icons.$Size)"
              }
            }
            if($Extension.icon -ne $icon -and [system.io.file]::Exists($icon)){
              $Extension.icon = $icon
            }
          }
        }
    }}
    $newRow = $null
  }catch{
    write-ezlogs "An exception occurred adding webview2 extensions to config in Get-Webview2Extensions" -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Get-Webview2Extensions
#----------------------------------------------

#---------------------------------------------- 
#region Add-Webview2Extension
#----------------------------------------------
Function Add-Webview2Extension{
  [CmdletBinding()]
  Param(
    $synchash,
    $thisApp,
    $Extensions,
    $WebView2
  ) 
  try{
    if($synchash.WebExtensions_Button){
      try{
        #$synchash.WebExtensions_Button.items.clear()
        $Extensions | & { process {
            $Extension = $_      
            if($Extension.Name -notin 'Microsoft Clipboard Extension','Microsoft Edge PDF Viewer'){
              $EnabledExtension = $thisApp.Config.Webview2_Extensions | Where-Object {$_.name -eq $Extension.Name}
              if(!$EnabledExtension -and $Extension.ID){
                $EnabledExtension = $thisApp.Config.Webview2_Extensions | Where-Object {$_.id -eq $Extension.ID}
              }
              if(!$EnabledExtension){
                $EnabledExtension = $thisApp.Config.Webview2_Extensions | Where-Object {$_.name -match $Extension.Name}
              }
              if(!$EnabledExtension){
                $EnabledExtension = $thisApp.Config.Webview2_Extensions | Where-Object {$Extension.Name -match $_.name}
              }
              if($EnabledExtension.isEnabled -and $synchash.WebExtensions_Button.items.Header -notcontains $EnabledExtension.Name){
                $MenuItem = [System.Windows.Controls.MenuItem]::new()
                $MenuItem.Header = $EnabledExtension.Name
                $ExtensionManifest = "$($EnabledExtension.Path)\manifest.json"
                $json = [system.io.file]::ReadAllText($ExtensionManifest) | ConvertFrom-Json -ErrorAction SilentlyContinue
                $Size = '16'
                if([system.io.file]::exists($EnabledExtension.icon)){
                  $icon = $EnabledExtension.icon
                }else{
                  if($json.icons.$Size){
                    $icon = "$($EnabledExtension.Path)\$($json.icons.$Size)"
                  }else{
                    $Size = $json.icons.psobject.properties.name | Select-Object -last 1
                    if($Size){
                      $icon = "$($EnabledExtension.Path)\$($json.icons.$Size)"
                    }
                  }     
                }                            
                if([system.io.file]::exists($icon)){
                  $stream_image = [System.IO.File]::OpenRead($icon) 
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  $image.BeginInit()
                  $image.CacheOption = 'OnLoad'    
                  $image.StreamSource = $stream_image
                  $image.DecodePixelWidth = $Size
                  $image.EndInit()        
                  $menuItem_imagecontrol = [System.Windows.Controls.Image]::new()
                  $menuItem_imagecontrol.Source = $image
                  $MenuItem.icon = $menuItem_imagecontrol
                  $image.Freeze() 
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null                                                                             
                }                           
                $MenuItem.IsCheckable = $false  
                $MenuItem.tag = $Extension.id
                if($json.browser_action.default_popup){
                  $MenuItem.Uid = $json.browser_action.default_popup
                }elseif($json.options_ui.page){
                  $MenuItem.Uid = $json.options_ui.page
                }elseif($json.options_page){
                  $MenuItem.Uid = $json.options_page
                }                             
                $MenuItem.Add_Click({
                    try{
                      if(-not [string]::IsNullOrEmpty($this.tag)){
                        if(-not [string]::IsNullOrEmpty($this.Uid)){
                          $Extensionurl = "chrome-extension://$($this.tag)/$($this.Uid)"
                        }else{
                          $Extensionurl = "chrome-extension://$($this.tag)"
                        }                                      
                        Write-EZLogs ">>>> Opening Webbrowser extension url: $Extensionurl" -logtype Webview2
                        $NewWindowScript = @"
                                      console.log('Opening new extension window: $Extensionurl');
                                      window.open("$Extensionurl")
"@
                        $synchash.Webbrowser.ExecuteScriptAsync($NewWindowScript)
                      }
                    }catch{
                      Write-EZLogs "An exception occurred in add_checked for menuitem: $($this.Header)" -catcherror $_
                    }
                })
                Write-EZLogs " | Adding extension to WebExtensions_Button: $($EnabledExtension.Name)" -logtype Webview2
                $synchash.WebExtensions_Button.items.add($MenuItem)
              }elseif($synchash.WebExtensions_Button.items.Header -contains $EnabledExtension.Name){
                write-ezlogs "Extension: $($Extension.Name) -- already added to WebExtensions_Button" -Warning -logtype Webview2 -Dev_mode
              }else{
                write-ezlogs "Unable to find extension: $($Extension.Name) -- to add to WebExtensions_Button" -Warning -logtype Webview2
              }  
            }     
        }}
      }catch{
        Write-EZLogs 'An exception occurred in WebExtensions_Button.add_Loaded' -catcherror $_
      }    
    }
  }catch{
    Write-EZLogs 'An exception occurred in Add-Webview2Extension' -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Add-Webview2Extension
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-YoutubeWebPlayer Function
#----------------------------------------------
Function Initialize-YoutubeWebPlayer
{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    $thisScript
  ) 
  try{
    if(!$synchash.YoutubeWebView2 -or !$synchash.YoutubeWebView2.CoreWebView2){
      Write-EZLogs '#### Creating new YoutubeWebView2 instance' -showtime -logtype Webview2 -linesbefore 1
      $synchash.YoutubeWebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
    }
    $synchash.YoutubeWebView2.Visibility = 'Visible'
    $synchash.YoutubeWebView2.Name = 'YoutubeWebView2'
    $synchash.YoutubeWebView2.DefaultBackgroundColor = [System.Drawing.Color]::Black
    <#    if([Environment]::GetEnvironmentVariable('WEBVIEW2_DEFAULT_BACKGROUND_COLOR') -ne '#FF000000'){
        [void][Environment]::SetEnvironmentVariable("WEBVIEW2_DEFAULT_BACKGROUND_COLOR",'#FF000000')
    }#>
 
    $synchash.YoutubeWebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
    $synchash.YoutubeWebView2Options.IsCustomCrashReportingEnabled = $true
    # --disable-web-security
    $synchash.YoutubeWebView2Options.AdditionalBrowserArguments = '--autoplay-policy=no-user-gesture-required --Disable-features=HardwareMediaKeyHandling,OverscrollHistoryNavigation,msExperimentalScrolling'
    #TODO: Extensions 
    if(-not [string]::IsNullOrEmpty($synchash.YoutubeWebView2Options.AreBrowserExtensionsEnabled)){
      Write-EZLogs '>>>> Enabling browser extension support for YoutubeWebView2' -logtype Webview2
      Get-Webview2Extensions -thisApp $thisApp
      $synchash.YoutubeWebView2Options.AreBrowserExtensionsEnabled = $true
      $synchash.YoutubeWebView2.CreationProperties = [Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties]::new()
      $synchash.YoutubeWebView2.CreationProperties.AreBrowserExtensionsEnabled = $true
      Write-EZLogs " | YoutubeWebView2 CreationProperties -- AdditionalBrowserArgument: $($synchash.YoutubeWebView2.CreationProperties.AdditionalBrowserArguments) -- AreBrowserExtensionsEnabled: $($synchash.YoutubeWebView2.CreationProperties.AreBrowserExtensionsEnabled)" -logtype Webview2 -Dev_mode    
    }
    $synchash.YoutubeWebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
      [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.YoutubeWebView2Options
    )

  }catch{
    Write-EZLogs 'An exception occurred creating YoutubeWebView2 Enviroment' -showtime -catcherror $_
  }

  $synchash.YoutubeWebView2_NavigationStarting_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationStartingEventArgs]]{
    param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationStartingEventArgs]$e)
    $synchash = $synchash
    $thisApp = $thisApp
    try{
      Write-EZLogs ">>>> Navigation started for: $($sender.Name) -- URI: $($e.Uri) -- Source: $($sender.source) -- NavigationKind: $($e.NavigationKind)" -showtime -logtype Webview2
    }catch{
      Write-EZLogs 'An exception occurred in YoutubeWebView2_NavigationStarting_Scriptblock' -catcherror $_
    }
  }
  $synchash.YoutubeWebView2.Remove_NavigationStarting($synchash.YoutubeWebView2_NavigationStarting_Scriptblock)
  $synchash.YoutubeWebView2.Add_NavigationStarting($synchash.YoutubeWebView2_NavigationStarting_Scriptblock)

  $synchash.YoutubeWebView2_NavigationCompleted_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
    param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]$e)
    $synchash = $synchash
    $thisApp = $thisApp
    try{     
      if($e.IsSuccess){
        $logtype = 'Webview2'
        Write-EZLogs ">>>> YoutubeWebview2 NavigationCompleted for $($sender.source)" -showtime -logtype $logtype
        #$synchash.YoutubeWebView2.CoreWebView2.Settings.UserAgent = "Chrome"
        #$synchash.YoutubeWebView2.CoreWebView2.Settings.UserAgent =  "Android"
        if(($thisApp.Config.Use_invidious -or $sender.source -match 'yewtu.be|invidious') -and $sender.source -notmatch 'tv\.youtube\.com'){
          Write-EZLogs ">>>> Adding YoutubeWebview2 Script for Invidious session" -showtime -logtype $logtype
          $synchash.YoutubeWebView2_Script = @"
var options = {
    preload: 'auto',
    liveui: true,
    save_player_pos: true,
    player_style: 'youtube',
    dark_mode:  true,
    quality: 'dash',
    quality_set: 'best',
    playbackRates: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
    playerOptions: {
      autoplay: true,
      player_style: 'youtube'
    },
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


player.options(options);
var player_data = JSON.parse(document.getElementById('player_data').textContent);
var video_data = JSON.parse(document.getElementById('video_data').textContent);
var time = player.currentTime();
var volume = player.volume();
player.volume($($synchash.Volume_Slider.Value / 100));
player.on('playing', function () {
const all_video_times = helpers.storage.get(save_player_pos_key) || {};
var rememberedTime = all_video_times[video_data.id];
console.log('Save Player Pos',rememberedTime);
if (options.save_player_pos) {
    //const url = new URL(location);
    //const hasTimeParam = url.searchParams.has('t');
    //const rememberedTime = get_video_time();
    //let lastUpdated = 0;
    //console.log('Remembered time',rememberedTime);
    //if(!hasTimeParam) set_seconds_after_start(rememberedTime);
}

if (options.quality === 'dash') {
    player.httpSourceSelector();

     const qualityLevels = Array.from(player.qualityLevels()).sort(function (a, b) {return a.height - b.height;});
     console.log('Video Quality Dash',video_data.params.quality_dash);
     let targetQualityLevel;
                switch (options.quality_set) {
                    case 'best':
                        targetQualityLevel = qualityLevels.length - 1;
                        break;
                    case 'worst':
                        targetQualityLevel = 0;
                        break;
                    default:
                        const targetHeight = parseInt(video_data.params.quality_dash);
                        for (let i = 0; i < qualityLevels.length; i++) {
                            if (qualityLevels[i].height <= targetHeight)
                                targetQualityLevel = i;
                            else
                                break;
                        }
                }
                qualityLevels.forEach(function (level, index) {
                    level.enabled = (index === targetQualityLevel);
                    });
               
}

else remove_all_video_times();
});

//player.addEventListener("onPlayerReady", onPlayerReady);
//player.addEventListener("onvolumechange", onYoutubevolumechange);


console.log(player_data);
console.log(video_data);
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
    window.chrome.webview.postMessage(playerdataJson);  
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(playerObject);
    window.chrome.webview.postMessage(timeJson);
    window.chrome.webview.postMessage(volumeObject);   
    let lastUpdated = 0;

    console.log('Navigation Complete Script Finished:');
"@
        }else{
          Write-EZLogs ">>>> Adding YoutubeWebview2 Script for Youtube session" -showtime -logtype $logtype
          $synchash.YoutubeWebView2_Script = @"
console.log('Setting up Youtube element move_player:');
var player = document.getElementById('movie_player');
var YTTV = false;
var FullScreenSet = false;
var FullScreenButtonSet = false;
var QualitySet = false;
var CinemaSet = false;
var ContinuePlaylist = false;
var PlayerStateEvent = false;
var PlayerErrorEvent = false;

try {
	function onYouTubePlayerStateChange(event) {
		try {
        console.log('Player State Changed event', event);
				if (event == 0) {
					console.log(' | Player State reports ended', event);
          var playlist = player.getPlaylist();
          if (playlist !== null && playlist !== -1 && playlist.length > 0) {
            console.log(' | Currently playing a playlist of length', playlist.length);
            var playlistindex = player.getPlaylistIndex();
			      if (playlistindex !== null && playlistindex !== -1 && playlistindex <= playlist.length) {
              console.log(' | Current playlist index is less than total, continue playlist', playlistindex);
				      var ContinuePlaylist = true;
			      } else {
              console.log(' | Should not continue current playlist', playlistindex);
				      var ContinuePlaylist = false;
			      }
          } else {
             console.log(' | Not Currently playing a playlist');
             var ContinuePlaylist = false;
          }
				} else {
					var ContinuePlaylist = false;
				}
		} catch (e) {
			console.log('Exception occurred posting youtube event state', e);
		}

		try {
		 if (!ContinuePlaylist) {
			  var statejsonObject = {
				  Key: 'state',
				  Value: event
			  };
			  window.chrome.webview.postMessage(statejsonObject);
      } else {
			  var statejsonObject = {
				  Key: 'state',
				  Value: 99
			  };
			  window.chrome.webview.postMessage(statejsonObject);
      }
		} catch (e) {
			console.log('Exception occurred posting youtube event state', e);
		}

		try {
			var isFullScreen = player.isFullscreen();
		} catch (e) {
			console.log('Exception occurred getting fullscreen state', e);
		}

		try {
			var videourl = player.getVideoUrl();
		} catch (e) {
			console.log('Exception occurred getting video url', e);
		}
		try {
			if (isFullScreen) {
				console.log('isFullScreen', isFullScreen);
			} else if (!videourl.match('tv.youtube.com') && state != 0) {
				console.log('Requesting FullScreen');
				player.requestFullscreen();
			}
		} catch (e) {
			console.log('Exception occurred Requesting FullScreen', e);
		}
    if (event == 1) {
      try {
        var oldquality = player.getPlaybackQuality();
        console.log('Current Quality:', oldquality);
        const levels = player.getAvailableQualityLevels();
        //console.log('oldquality:', oldquality);
        let quality = JSON.parse(localStorage.getItem('yt-player-quality'));
        if (!QualitySet) {
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
        }
        var videodata = player.getVideoData();
        if (videodata) {
            var videodataObject = {
                Key: 'videodata',
                Value: videodata
            };
            window.chrome.webview.postMessage(videodataObject);
        }
          var newqualitylabel = player.getPlaybackQualityLabel();
		      var currentquality = {
			      Key: 'currentquality',
			      Value: newqualitylabel
		      };
		      window.chrome.webview.postMessage(currentquality);
      } catch (e) {
	      console.log('Exception occurred getting getting or setting playback quality', e);
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
	  }
	}
} catch (e) {
	console.log('Exception occurred creating function onYouTubePlayerStateChange', e);
}

try {
 var fullscreen_button = document.getElementsByClassName("ytp-fullscreen-button");
 var cinema_button = document.getElementsByClassName("ytp-size-button");
 var YTTV_fullscreen_button = document.getElementsByClassName("yib-button style-scope ytu-icon-button");
} catch (e) {
 console.log('Exception occurred getting fullscreen button elements', e);
}

console.log('is FullScreenButton Set:', FullScreenButtonSet);
if (fullscreen_button.length > 0 && !FullScreenButtonSet) {
	try {
		if (!FullScreenButtonSet) {
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
  if (cinema_button.length > 0) {
	  collection = document.getElementsByTagName('ytd-watch-flexy');
	  if (!CinemaSet) {
		  CinemaSet = true;
		  console.log('Setting cinema button click event', cinema_button[0]);
		  cinema_button[0].addEventListener("click", function (event) {
			  console.log('cinema Button Clicked');
			  var cinemabuttonObject = {
				  Key: 'cinemabutton',
				  Value: event
			  };
			  window.chrome.webview.postMessage(cinemabuttonObject);
		  });
	  }
  }
} catch (e) {
 console.log('Exception occurred getting or setting the cinema_button button', e);
}
try {
  if (YTTV_fullscreen_button[23].ariaLabel == 'Full screen (f)' && !YTTV) {
	  YTTV = true;
	  console.log('Setting YTTV Fullscreen button click event', YTTV_fullscreen_button[23]);
	  YTTV_fullscreen_button[23].addEventListener("click", function (event) {
		  console.log('YT FullScreen Button Clicked');
		  var fullscreenbuttonObject = {
			  Key: 'fullscreenbutton',
			  Value: event
		  };
		  window.chrome.webview.postMessage(fullscreenbuttonObject);
	  });
  }
} catch (e) {
 console.log('Exception occurred getting or setting YoutubeTV fullscreen button', e);
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
try {
	var isFullScreen = player.isFullscreen();
} catch (e) {
	console.log('Exception occurred getting fullscreen state', e);
}

try {
	var videourl = player.getVideoUrl();
} catch (e) {
	console.log('Exception occurred getting video url', e);
}
try {
	if (isFullScreen) {
		console.log('isFullScreen', isFullScreen);
	} else if (!videourl.match('tv.youtube.com') && state != 0) {
		console.log('Requesting FullScreen');
		player.requestFullscreen();
	}
} catch (e) {
	console.log('Exception occurred Requesting FullScreen', e);
}
try {
  function onYoutubePlayerReady(event) {
      console.log('Player is Ready');
      player.playVideo();
      var quality = player.getAvailableQualityLevels();
      player.setPlaybackQuality(quality[0]);
  }
} catch (e) {
	console.log('Exception occurred creating function onYoutubePlayerReady', e);
}

try {
  function onYoutubePlayerfullscreenchange(event) {
      console.log('Player fullscreen change event',event);
      console.log(event);
      var fullscreenObject = {
          Key: 'fullscreenchange',
          Value: event
      };
      window.chrome.webview.postMessage(fullscreenObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYoutubePlayerfullscreenchange', e);
}

try {
  function onYoutubevolumechange(event) {
      var volume = player.getVolume();
      console.log('Volume changed to', volume);
      var volumeObject = {
          Key: 'volume',
          Value: volume
      };
      window.chrome.webview.postMessage(volumeObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYoutubevolumechange', e);
}

try {
  function onYouTubeError(event) {
      console.log('Youtube ERROR:', event);
      var ErrorObject = {
          Key: 'error',
          Value: event
      };
      window.chrome.webview.postMessage(ErrorObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYouTubeError', e);
}
try {
  function onYouTubePlaying(event) {
      console.log('Youtube playing event: event');
      var PlayingObject = {
          Key: 'playing',
          Value: event
      };
      window.chrome.webview.postMessage(PlayingObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYouTubePlaying', e);
}
try {
  function onYoutubePlayerPause(event) {
      console.log('Youtube Pause event: event');
      var PauseObject = {
          Key: 'pause',
          Value: event
      };
      window.chrome.webview.postMessage(PauseObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYouTubePause', e);
}
try {
  function onYoutubeContextMenu(event) {
      console.log('Youtube ContextMenu event: event');
      var ContextMenuObject = {
          Key: 'ContextMenu',
          Value: event
      };
      window.chrome.webview.postMessage(ContextMenuObject);
  }
} catch (e) {
	console.log('Exception occurred creating function onYouTubeContextMenu', e);
}

try {
	player.addEventListener("OnReady", onYoutubePlayerReady);
  //player.onpause= onYoutubePlayerPause;
  //player.oncontextmenu = onYoutubeContextMenu;
	player.addEventListener("onStateChange", onYouTubePlayerStateChange);
  PlayerStateEvent = true;
	//player.addEventListener("onfullscreenchange", onYoutubePlayerfullscreenchange);
  player.onfullscreenchange = onYoutubePlayerfullscreenchange;
	player.addEventListener("onError", onYouTubeError);
  PlayerErrorEvent = true;
	player.addEventListener("onvolumechange", onYoutubevolumechange);
  console.log('Added addEventListeners to youtube player');
} catch (e) {
 console.log('Exception occurred adding EventListener to youtube player', e);
}

try {
  console.log('Setting youtube player volume:',$($synchash.Volume_Slider.Value));
  player.setVolume($($synchash.Volume_Slider.Value));
} catch (e) {
 console.log('Exception occurred adding setting youtube player volume to: $($synchash.Volume_Slider.Value)', e);
}

try {
  var state = player.getPlayerState();
  var videodata = player.getVideoData();
  if (videodata) {
      var videodataObject = {
          Key: 'videodata',
          Value: videodata
      };
      window.chrome.webview.postMessage(videodataObject);
  }
  var videoUrl = player.getVideoUrl();
  var time = player.getCurrentTime();
  var duration = player.getDuration();
  var volume = player.getVolume();
  var isMuted = player.isMuted();
  var Playerlabel = document.getElementById('id-player-main');
  if (Playerlabel) {
      var PlayerlabelObject = {
          Key: 'Playerlabel',
          Value: Playerlabel.ariaLabel
      };
      window.chrome.webview.postMessage(PlayerlabelObject);
  }
  var timeJson = {
      Key: 'time',
      Value: time
  };
  var statejsonObject = {
      Key: 'state',
      Value: state
  };
  window.chrome.webview.postMessage(statejsonObject);
  var durationObject = {
      Key: 'duration',
      Value: duration
  };
  var volumeObject = {
      Key: 'volume',
      Value: volume
  };
  var videoUrlObject = {
      Key: 'videoUrl',
      Value: videoUrl
  };
  var MuteStatus = {
      Key: 'MuteStatus',
      Value: isMuted
  };

  //window.chrome.webview.postMessage(MuteStatus);
  window.chrome.webview.postMessage(timeJson);
  window.chrome.webview.postMessage(durationObject);
  //window.chrome.webview.postMessage(volumeObject);
  window.chrome.webview.postMessage(videoUrlObject);
} catch (e) {
 console.log('Exception occurred posting player objects and properties ', e);
}
"@        
        } 
        $YT_ADblockScript = "$($thisApp.Config.Current_Folder)\Resources\Ad Blocking\Youtube_ADBlock2.js"  
        if([system.io.file]::Exists($YT_ADblockScript)){
          if(!$synchash.YoutubeWebView2_Adblock_Script -or $thisApp.Config.Dev_mode){
            $synchash.YoutubeWebView2_Adblock_Script = [system.io.file]::ReadAllText($YT_ADblockScript)
          }
          Write-EZLogs '>>>> Injecting custom Youtube Adblock script' -logtype $logtype
          $synchash.YoutubeWebView2.ExecuteScriptAsync(
            $synchash.YoutubeWebView2_Adblock_Script       
          )
        }  
        Write-EZLogs ' | Executing YoutubeWebView2_Script' -showtime -logtype $logtype -Dev_mode
        $synchash.YoutubeWebView2.ExecuteScriptAsync(        
          $synchash.YoutubeWebView2_Script
        )
        if($synchash.Current_playing_media.id -and $synchash.Current_playing_media.url -notmatch 'tv\.youtube\.com'){
          if($synchash.Youtube_webplayer_current_Media.Video_id){
            $YoutubeID = $synchash.Youtube_webplayer_current_Media.Video_id
          }else{
            $youtube = Get-Youtubeurl -URL $synchash.Current_playing_media.url -thisApp $thisApp
            $YoutubeID = $youtube.id
          }        
          if($YoutubeID){
            if($thisApp.Config.Enable_Sponsorblock -and $thisApp.Config.Sponsorblock_ActionType){
              $thisApp.SponsorBlock = Get-SponsorBlock -videoId $YoutubeID -actionType $thisApp.Config.Sponsorblock_ActionType
            }else{
              $thisApp.SponsorBlock = $null
            }
            try{
              Write-EZLogs " | Executing Youtube dislike lookup: https://returnyoutubedislikeapi.com/votes?videoId=$($YoutubeID)" -showtime -logtype $logtype -Dev_mode
              $req = [System.Net.HTTPWebRequest]::Create("https://returnyoutubedislikeapi.com/votes?videoId=$($YoutubeID)")
              $req.Method = 'GET'         
              $req.Timeout = 5000
              $response = $req.GetResponse()
              $strm = $response.GetResponseStream()
              $sr = [System.IO.Streamreader]::new($strm)
              $output = $sr.ReadToEnd()
              $youtube_ds = $output | ConvertFrom-Json
            }catch{
              Write-EZLogs "An exception occurred in HTTPWebRequest for: https://returnyoutubedislikeapi.com/votes?videoId=$($YoutubeID)" -showtime -catcherror $_
            }finally{
              if($response){
                $response.Dispose()
              }
              if($strm){
                $strm.Dispose()
              }
              if($sr){
                $sr.Dispose()
              }   
              $req = $null
            }
          }
          if($youtube_ds.dislikes){
            $DisLikes = $($youtube_ds.dislikes -as [decimal]).ToString('N0')
          }
          if($youtube_ds.likes){
            $Likes = $($youtube_ds.likes -as [decimal]).ToString('N0')
          }
          if($synchash.Likes_Total -and $synchash.DisLikes_Total){
            if($youtube_ds){            
              $synchash.Likes_Total.Visibility = 'Visible'
              $synchash.Likes_Total.text = $Likes
              $synchash.DisLikes_Total.text = $DisLikes
            }else{
              $synchash.Likes_Total.Visibility = 'Collapsed'
              $synchash.Likes_Total.text = ''
              $synchash.DisLikes_Total.text = ''
            }
          }
          $synchash.YoutubeDislikes_Script = @"
  var IsDisLikeSet = false;
  var dsbutton = document.getElementById("segmented-dislike-button")
  if(dsbutton && !dsbutton.children[0].children[0].children[0].innerText){
   dsbutton.children[0].children[0].children[0].append('  ',$($DisLikes))
   console.log('Youtube Dislikes: $($DisLikes)');
  }else{
   var dsbutton = document.getElementById("menu-container")?.querySelector("#top-level-buttons-computed");
   dsbutton.children[1].querySelector("#text").innerText = $($DisLikes);
   console.log('Youtube Dislikes: $($DisLikes)');
  }

"@  
          if($DisLikes){
            Write-EZLogs " | Youtube dislikes: $($DisLikes), Executing YoutubeDislikes_Script" -logtype $logtype
            $synchash.YoutubeWebView2.ExecuteScriptAsync(
              $synchash.YoutubeDislikes_Script
            )
          } 
          $synchash.YoutubeWebView2_Youtube_returnDislike_Script = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Youtube\Return Youtube Dislike.user.js")
          Write-EZLogs ' | Executing Youtube_returnDislike_Script' -logtype $logtype
          $synchash.YoutubeWebView2.ExecuteScriptAsync(
            $synchash.YoutubeWebView2_Youtube_returnDislike_Script       
          )
        } 
        Write-EZLogs " | Post navigation execution complete: BrowserProcessID: $($synchash.YoutubeWebView2.CoreWebview2.BrowserProcessId) - DocumentTitle: $($synchash.YoutubeWebView2.CoreWebview2.DocumentTitle) - ContainsFullScreenElement: $($synchash.YoutubeWebView2.CoreWebview2.ContainsFullScreenElement)" -logtype $logtype -loglevel 3
      }else{
        Write-EZLogs "YoutubeWebView2 Navigation to source: '$($sender.source)' was not successful -- HttpStatusCode: $($e.HttpStatusCode) -- WebErrorStatus: $($e.WebErrorStatus)" -logtype Webview2 -warning
      }
    }catch{
      Write-EZLogs 'An exception occurred in YoutubeWebView2_NavigationCompleted_Scriptblock' -catcherror $_
    }
  }

  $synchash.YoutubeWebView2.Remove_NavigationCompleted($synchash.YoutubeWebView2_NavigationCompleted_Scriptblock)
  $synchash.YoutubeWebView2.Add_NavigationCompleted($synchash.YoutubeWebView2_NavigationCompleted_Scriptblock)   
  $synchash.YoutubeWebView2.Add_CoreWebView2InitializationCompleted(
    [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
      Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]$event)
      $logtype = 'Webview2'
      $synchash = $synchash
      $thisApp = $thisApp
      Write-EZLogs '[YoutubeWebView2] >>>> YoutubeWebView2 CoreWebView2InitializationCompleted' -showtime -logtype $logtype -linesbefore 1
      try{
        if($event.IsSuccess){
          [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.YoutubeWebView2.CoreWebView2.Settings
          $Settings.AreDefaultContextMenusEnabled  = $true
          $Settings.AreDefaultScriptDialogsEnabled = $true
          $Settings.AreDevToolsEnabled             = $true
          $Settings.AreHostObjectsAllowed          = $true
          $Settings.IsBuiltInErrorPageEnabled      = $false
          $Settings.IsScriptEnabled                = $true
          $Settings.IsStatusBarEnabled             = $thisApp.Config.Dev_mode
          $Settings.IsWebMessageEnabled            = $true
          $Settings.IsZoomControlEnabled           = $false
          $Settings.IsGeneralAutofillEnabled       = $false
          $Settings.IsPasswordAutosaveEnabled      = $false
          $Settings.AreBrowserAcceleratorKeysEnabled = $thisApp.Config.Dev_mode
          $Settings.IsSwipeNavigationEnabled = $false
          #$Settings.UserAgent = ""
          #$Settings.UserAgent = "Mozilla/5.0 (PS4; Leanback Shell) Gecko/20100101 Firefox/65.0 LeanbackShell/01.00.01.75 Sony PS4/ (PS4, , no, CH)"
          $synchash.YoutubeWebView2.CoreWebView2.AddWebResourceRequestedFilter('*', [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All)    
          $synchash.YoutubeWebview2.CoreWebview2.MemoryUsageTargetLevel = 'Low'
          if($synchash.YoutubeWebView2.CoreWebView2.Profile.PreferredTrackingPreventionLevel -ne 'Strict'){
            Write-EZLogs '[YoutubeWebView2] | Setting CoreWebView2.Profile.PreferredTrackingPreventionLevel to Strict' -showtime -logtype $logtype
            $synchash.YoutubeWebView2.CoreWebView2.Profile.PreferredTrackingPreventionLevel = 'Strict'
          }
          if($thisApp.Config.Youtube_WebPlayer_PrivateMode){
            Write-EZLogs '[YoutubeWebView2] | Enabling private mode for YoutubeWebView2' -showtime -logtype $logtype
            $synchash.YoutubeWebView2.CoreWebView2.Profile.IsInPrivateModeEnabled = $true
          }
          if($synchash.YoutubeWebView2.CoreWebView2.Profile.IsInPrivateModeEnabled){
            Write-EZLogs '[YoutubeWebView2] | YoutubeWebView2 is currently in private mode' -showtime -logtype $logtype -warning
          }
          $synchash.YoutubeWebview2.CoreWebView2.add_ProcessFailed({
              Param($sender)
              [Microsoft.Web.WebView2.Core.CoreWebView2ProcessFailedEventArgs]$e = $args[1]
              try{
                Write-EZLogs "[YoutubeWebView2] Youtube WebPlayer ProcessFailed - Uri: $($e.Uri) - ProcessFailedKind: $($args.ProcessFailedKind) - Reason: $($args.reason) - ExitCode: $($args.exitcode)" -isError -AlertUI
                if($thisApp.Config.Dev_mode){
                  Write-EZLogs "[YoutubeWebView2] Uri: $($e.Uri) - RequestHeaders: $($e.RequestHeaders) - NavigationKind: $($e.NavigationKind)" -Dev_mode
                  Write-EZLogs "[YoutubeWebView2] YoutubeWebview2.CoreWebView2: $($synchash.YoutubeWebview2.CoreWebView2 | Out-String)" -Dev_mode
                }
              }catch{
                Write-EZLogs '[YoutubeWebView2] An exception occurred in YoutubeWebview2.CoreWebView2.add_ProcessFailed' -catcherror $_
              }
          })
          #TODO: Extension support - coming soon(?) per Webview2 github
          #[Microsoft.Web.WebView2.Core.CoreWebView2BrowserExtension]$extensionsList = $syncHash.YoutubeWebView2.CoreWebView2.Profile.GetBrowserExtensionsAsync()
          #await $syncHash.YoutubeWebView2.CoreWebView2.Profile.AddBrowserExtensionAsync($m_defaultExtensionFolderPath);
          <#          if($thisApp.Config.Spotify_SP_DC){
              write-ezlogs "Adding Spotify Cookie $($thisApp.Config.Spotify_SP_DC)" -showtime -logtype Webview2
              $OptanonAlertBoxClosed = $syncHash.YoutubeWebView2.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), ".spotify.com", "/")
              $syncHash.YoutubeWebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed)           
              $sp_dc = $syncHash.YoutubeWebView2.CoreWebView2.CookieManager.CreateCookie('sp_dc', $thisApp.Config.Spotify_SP_DC, ".spotify.com", "/")
              $sp_dc.IsSecure=$true
              $syncHash.YoutubeWebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($sp_dc)   
          }#>
          foreach($cookie in $thisApp.Config.Youtube_Cookies){
            if(($cookie.cookiedurldomain -eq '.youtube.com' -or $cookie.cookiedurldomain -eq '.google.com') -and $cookie.name -in 'PREF', '__Secure-1PSID', '__Secure-3PAPISID', 'LOGIN_INFO', '__Secure-1PAPISID', 'OptanonAlertBoxClosed' -and -not [string]::IsNullOrEmpty($cookie.value)){
              Write-EZLogs "[YoutubeWebView2] >>>> Adding domain $($cookie.cookiedurldomain) cookie $($cookie.name)" -showtime -logtype $logtype -Dev_mode
              try{
                $Youtube_cookie = $synchash.YoutubeWebView2.CoreWebView2.CookieManager.CreateCookie($cookie.name, $($cookie.value), '.youtube.com', '/')
                $Youtube_cookie.IsSecure = $cookie.isSecure
                $synchash.YoutubeWebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_cookie) 
              }catch{
                Write-EZLogs "[YoutubeWebView2] An exception occurred adding youtube cookie $($cookie | Out-String)" -catcherror $_
              }finally{
                $Youtube_cookie = $null
              }  
            }                
          }
          $synchash.YoutubeWebView2.CoreWebView2.add_WebResourceRequested({
              Param($Sender,[Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e)
              $logtype = 'Webview2'
              try{
                $Cookies = ($e.Request.Headers.Where({$_.key -eq 'cookie'})).value
                if($Cookies){
                  if($Cookies -notmatch 'OptanonAlertBoxClosed'){
                    $OptanonAlertBoxClosed = $synchash.YoutubeWebView2.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-Date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), '.spotify.com', '/')
                    $synchash.YoutubeWebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed) 
                  }
                  if($synchash.YoutubeWebView2.Source -match 'spotify\.com'){
                    $cookiedurldomain = '.spotify.com'                
                  }elseif($synchash.YoutubeWebView2.Source -match 'google\.com'){
                    $cookiedurldomain = '.google.com'
                  }elseif($synchash.YoutubeWebView2.Source -match 'youtube\.com|youtu\.be'){
                    $cookiedurldomain = '.youtube.com'
                  }
                  $Cookies = $Cookies -split ';'
                  foreach($cookie in $Cookies){
                    try{
                      if($cookiedurldomain -eq '.youtube.com' -or $cookiedurldomain -eq '.google.com'){
                        if($cookie -match '(?<value>.*)=(?<value>.*)'){
                          $cookiename = $($cookie -split '=')[0]
                          if($cookiename){
                            $cookiename = $cookiename.trim()
                          }
                          $cookievalue = ([regex]::matches($cookie, "$cookiename=(?<value>.*)").foreach({$_.groups[1].value})) 
                        } 
                        switch ($cookiename){
                          'SIDCC' {
                            $isSecure = $false
                          } 
                          'SID' {
                            $isSecure = $false
                          }
                          'OptanonAlertBoxClosed' {
                            $isSecure = $false
                          }
                          'HSID' {
                            $isSecure = $false
                          }
                          'APISID' {
                            $isSecure = $false
                          }
                          'GPS' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'DEVICE_INFO' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'VISITOR_INFO1_LIVE' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '1PAPISID' {
                            $skip = $false
                            $isSecure = $true
                          }
                          'test_cookie' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'CONSISTENCY' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'ACCOUNT_CHOOSER' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-1PLSID' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-3PLSID' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-GAPS' {
                            $skip = $true
                            $isSecure = $false
                          }                        
                          Default {
                            $skip = $false
                            $isSecure = $true
                          }
                        }
                        if(!$skip){   
                          if($thisApp.Config.Youtube_Cookies.name){
                            $index = $thisApp.Config.Youtube_Cookies.name.IndexOf($cookiename) 
                            if($index -ne -1){
                              $ExistingCookie = $thisApp.Config.Youtube_Cookies[$index] 
                            }                             
                          }   
                          if($cookiename -and $cookievalue -and !$ExistingCookie){
                            $null = $thisApp.Config.Youtube_Cookies.add([cookie]@{
                                'Name'           = $cookiename
                                'isSecure'       = $isSecure
                                'Value'          = $cookievalue.trim()
                                'cookiedurldomain' = $cookiedurldomain
                            })          
                            Write-EZLogs "[YoutubeWebView2] >>>> Found and new Youtube cookie  -- Name: $cookiename -- Value: $($cookievalue)" -showtime -logtype $logtype -Dev_mode                              
                          }elseif($cookiename -and $cookievalue -and $ExistingCookie.name -eq $cookiename -and $ExistingCookie.value -and $ExistingCookie.value -ne $cookievalue){
                            Write-EZLogs "[YoutubeWebView2] >>>> Found and updated Youtube cookie  -- Name: $cookiename -- Value: $($cookievalue)" -showtime -logtype $logtype -Dev_mode 
                            $ExistingCookie.value = $cookievalue.trim()
                          }
                        }
                      }
                    }catch{
                      Write-EZLogs "[YoutubeWebView2] An exception occurred saving youtube cookie $($cookie | Out-String)" -showtime -catcherror $_
                    }
                  }                                        
                }
              }catch{
                Write-EZLogs 'An exception occurred in YoutubeWebView2 CoreWebView2 WebResourceRequested Event' -showtime -catcherror $_
              }
          })
          #TODO: Extensions - Put in Function
          if($synchash.YoutubeWebView2Options.AreBrowserExtensionsEnabled -and $thisApp.Config.Webview2_Extensions.Count -gt 0){           
            try{
              Write-EZLogs '[YoutubeWebView2] >>>> Loading YoutubeWebView2 extensions' -logtype Webview2
              $Task = $synchash.YoutubeWebView2.CoreWebView2.Profile.GetBrowserExtensionsAsync()
              $Task.GetAwaiter().OnCompleted(
                [Action]{
                  Write-EZLogs "[YoutubeWebView2] | Installed YoutubeWebView2 extensions: $($Task.Result.name -join ' | ')" -logtype Webview2
                  $thisApp.Config.Webview2_Extensions | & { process {
                      $InstallTask = $null
                      $Extension = $_
                      try{
                        if($Extension.isEnabled){
                          if([system.io.directory]::Exists($Extension.path) -and $Extension.Name){
                            if($Extension.Name -notin $Task.Result.name){
                              Write-EZLogs "[YoutubeWebView2] >>>> Installing YoutubeWebView2 extension: $($Extension.Name)" -logtype Webview2
                              $InstallTask = $synchash.YoutubeWebView2.CoreWebView2.Profile.AddBrowserExtensionAsync($Extension.path)
                              $InstallTask.GetAwaiter().OnCompleted(
                                [Action]{
                                  if($InstallTask){
                                    Write-EZLogs "[YoutubeWebView2] Installed extension: $($InstallTask.Result.Name) - this: $($this | out-string)" -logtype Webview2 -Success
                                  }
                                }
                              )
                            }
                          }else{
                            Write-EZLogs "[YoutubeWebView2] Cannot find path or name for extension: $($Extension.name) -- path: $($Extension.path) -- disabling extension" -logtype Webview2 -warning
                            $Extension.isEnabled = $false
                          }
                        }
                      }catch{
                        Write-EZLogs "An exception occurred loading YoutubeWebView2 extension: $($Extension | Out-String)" -catcherror $_
                      }
                  }}
                  if($Task){
                    $null = $Task.Dispose()
                    $Task = $Null
                  }                                                              
                }.GetNewClosure() 
              )
            }catch{
              Write-EZLogs 'An exception occurred loading YoutubeWebView2 extensions' -catcherror $_
            }finally{
              if($synchash.Youtube_WebPlayer_URL -and $synchash.Youtube_WebPlayer_URL -match 'youtube' -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|invidious'){
                Write-EZLogs "[YoutubeWebView2] >>>> Navigating with YoutubeWebView2 CoreWebView2.Navigate: $($synchash.Youtube_WebPlayer_URL)" -enablelogs -showtime -logtype $logtype 
                $synchash.YoutubeWebView2.CoreWebView2.Navigate($synchash.Youtube_WebPlayer_URL)      
                if($synchash.YoutubeWebView2.Source -notmatch ($synchash.Youtube_WebPlayer_URL)){
                  Write-EZLogs "[YoutubeWebView2] >>>> YoutubeWebview2 Source: $($synchash.YoutubeWebView2.Source) -- Youtube_WebPlayer_URL: $($synchash.Youtube_WebPlayer_URL)" -enablelogs -Dev_mode -warning -logtype $logtype 
                }
              }
            }
          }else{
            if($synchash.Youtube_WebPlayer_URL -and $synchash.Youtube_WebPlayer_URL -match 'youtube' -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|invidious'){
              Write-EZLogs "[YoutubeWebView2] >>>> Navigating with YoutubeWebView2 CoreWebView2.Navigate: $($synchash.Youtube_WebPlayer_URL)" -enablelogs -showtime -logtype $logtype 
              $synchash.YoutubeWebView2.CoreWebView2.Navigate($synchash.Youtube_WebPlayer_URL)      
              if($synchash.YoutubeWebView2.Source -notmatch ($synchash.Youtube_WebPlayer_URL)){
                Write-EZLogs "[YoutubeWebView2] >>>> YoutubeWebview2 Source: $($synchash.YoutubeWebView2.Source) -- Youtube_WebPlayer_URL: $($synchash.Youtube_WebPlayer_URL)" -enablelogs -Dev_mode -warning -logtype $logtype 
              }
            }
          }             
          $synchash.YoutubeWebView2.CoreWebView2.add_IsDocumentPlayingAudioChanged({
              Param($Sender)
              $logtype = 'Webview2'
              try{
                if($synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio){
                  Write-EZLogs "[YoutubeWebView2] >>>> YoutubeWebview2 Audio has begun playing audio - WebPlayer_State: $($synchash.WebPlayer_State)" -showtime -logtype $logtype -Dev_mode
                  if(-not [string]::IsNullOrEmpty($synchash.Current_Audio_Session.GroupingParam) -and $synchash.Managed_AudioSession_Processes -notcontains $synchash.YoutubeWebView2.CoreWebView2.BrowserProcessId){
                    Set-AudioSessions -thisApp $thisApp -synchash $synchash
                    if($synchash.Managed_AudioSession_Processes){
                      Write-EZLogs "[YoutubeWebView2] | Registering Youtube Webplayer audio session with process id: $($synchash.YoutubeWebView2.CoreWebView2.BrowserProcessId)" -logtype $logtype
                      $Null = $synchash.Managed_AudioSession_Processes.add($synchash.YoutubeWebView2.CoreWebView2.BrowserProcessId)
                    }
                  }
                  if($synchash.YoutubeWebview2.CoreWebview2.IsSuspended){
                    $tryresume = $synchash.YoutubeWebView2.CoreWebView2.Resume()
                    Write-EZLogs "[YoutubeWebView2] | YoutubeWebview2 IsSuspended - attempting to resume with Resume() - Result: $($tryresume)" -logtype $logtype
                  } 
                  if($synchash.Timer.isEnabled){
                    $synchash.Timer.Stop() 
                  } 
                  if(!$synchash.WebPlayer_Playing_timer.isEnabled){
                    Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -start
                  }          
                  if($thisApp.Config.Dev_mode){
                    Write-EZLogs "[YoutubeWebView2] YoutubeWebview2.CoreWebView2: $($synchash.YoutubeWebView2.CoreWebView2 | Out-String)" -loglevel 3 -logtype $logtype
                    Write-EZLogs "[YoutubeWebView2] YoutubeWebview2.CoreWebView2.Settings: $($synchash.YoutubeWebView2.CoreWebView2.Settings | Select-Object * | Out-String)" -loglevel 3 -logtype $logtype
                  }           
                }elseif($synchash.WebPlayer_State -eq 0){
                  Write-EZLogs '[YoutubeWebView2] >>>> YoutubeWebView2 stopped playing audio' -loglevel 2 -logtype $logtype -linesbefore 1
                  Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -Stop
                }
                if($synchash.YoutubeWebView2.CoreWebView2.IsMuted){
                  Write-EZLogs '[YoutubeWebView2] | YoutubeWebView2 is Muted, checking Mute button' -loglevel 2 -logtype $logtype
                  $synchash.MuteButton_ToggleButton.isChecked = $true
                }elseif($synchash.MuteButton_ToggleButton.isChecked){
                  Write-EZLogs '[YoutubeWebView2] | YoutubeWebView2 is NOT muted and mute button is checked, unchecking Mute button' -loglevel 2 -logtype $logtype            
                  $synchash.MuteButton_ToggleButton.isChecked = $false
                } 
              }catch{
                Write-EZLogs '[YoutubeWebView2] An exception occurred in YoutubeWebView2.CoreWebView2.add_IsDocumentPlayingAudioChanged' -catcherror $_
              }
          }) 
          $synchash.YoutubeWebView2.CoreWebView2.add_IsMutedChanged({
              Param($Sender)
              $logtype = 'Webview2'
              if($synchash.YoutubeWebView2.CoreWebView2.IsMuted){
                Write-EZLogs '#### YoutubeWebView2 Audio has been muted' -showtime -loglevel 2 -logtype $logtype   
              }else{
                Write-EZLogs '#### YoutubeWebView2 Audio has been un-muted' -showtime -loglevel 2 -logtype $logtype
              }
          })
          if($thisApp.Config.Dev_mode){
            $synchash.YoutubeWebview2.CoreWebView2.add_ContainsFullScreenElementChanged({
                Param($sender)
                try{
                  Write-EZLogs "[YoutubeWebView2] >>>> YoutubeWebview2.CoreWebView2 ContainsFullScreenElementChanged:  $($sender.ContainsFullScreenElement)" -logtype Webview2 -Dev_mode
                }catch{
                  Write-EZLogs '[YoutubeWebView2] An exception occurred in ContainsFullScreenElementChanged' -catcherror $_
                }
            })
            Write-EZLogs '[YoutubeWebView2] >>>> Enabling DevToolsProtocolEventReceived event for YoutubeWebview2' -Dev_mode
            $CallDevtools = $synchash.YoutubeWebview2.CoreWebView2.CallDevToolsProtocolMethodAsync('Log.enable', '{}')
            $CallDevtools = $synchash.YoutubeWebview2.CoreWebView2.CallDevToolsProtocolMethodAsync('Runtime.enable', '{}')
            $YoutubeWebview2_DevToolsProtocolEventReceivedLog = $synchash.YoutubeWebview2.CoreWebView2.GetDevToolsProtocolEventReceiver('Log.entryAdded')   
            $YoutubeWebview2_DevToolsProtocolEventReceivedRuntime = $synchash.YoutubeWebview2.CoreWebView2.GetDevToolsProtocolEventReceiver('Runtime.consoleAPICalled')
            if($YoutubeWebview2_DevToolsProtocolEventReceivedLog){         
              Write-EZLogs ' | Registering DevTools Event Log' -Dev_mode
              $YoutubeWebview2_DevToolsProtocolEventReceivedLog.add_DevToolsProtocolEventReceived({
                  Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2DevToolsProtocolEventReceivedEventArgs]$e)
                  $logtype = 'Webview2'
                  try{
                    if($e.ParameterObjectAsJson){
                      $eventmessage = $e.ParameterObjectAsJson | ConvertFrom-Json
                      Write-EZLogs '[YoutubeWebView2] >>>> YoutubeWebview2 Event Logs Received' -Dev_mode -logtype $logtype -linesbefore 1
                      if($eventmessage.entry){
                        Write-EZLogs "[YoutubeWebView2] | [$(($eventmessage.entry.level).ToUpper()) - $(($eventmessage.entry.source).ToUpper())] $($eventmessage.entry.text | Out-String)" -Dev_mode -logtype $logtype
                        Write-EZLogs "[YoutubeWebView2] | [URL] $($eventmessage.entry.url)" -Dev_mode -logtype $logtype
                      }elseif($eventmessage.args){
                        if(-not [string]::IsNullOrEmpty($eventmessage.args.className)){
                          Write-EZLogs "[YoutubeWebView2] | [$(($eventmessage.args.className))]: $($eventmessage.args.description)" -Dev_mode -logtype $logtype
                        }else{
                          if(-not [string]::IsNullOrEmpty($eventmessage.args.description)){                           
                            Write-EZLogs "[YoutubeWebView2] | $(($eventmessage.args.type)): $($eventmessage.args.value) -- Description: $($eventmessage.args.description)" -Dev_mode -logtype $logtype
                          }else{
                            Write-EZLogs "[YoutubeWebView2] | [$(($eventmessage.args.type))]: $($eventmessage.args.value)" -Dev_mode -logtype $logtype
                          }                         
                        }                  
                      }elseif($eventmessage){
                        Write-EZLogs "[YoutubeWebView2] | JSON message: $($eventmessage | Out-String)" -Dev_mode -logtype $logtype
                      }                    
                    }elseif($e){
                      Write-EZLogs "[YoutubeWebView2] | CoreWebView2DevToolsProtocolEventReceivedEventArgs: $($e | Out-String)" -Dev_mode -logtype $logtype
                    }                  
                  }catch{
                    Write-EZLogs '[YoutubeWebView2] An exception occurred in Logs.DevToolsProtocolEventReceived' -catcherror $_
                  }
              })
            }
            if($YoutubeWebview2_DevToolsProtocolEventReceivedRuntime){         
              Write-EZLogs '[YoutubeWebView2] | Registering DevTools Event Runtime' -Dev_mode
              $YoutubeWebview2_DevToolsProtocolEventReceivedRuntime.add_DevToolsProtocolEventReceived({
                  Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2DevToolsProtocolEventReceivedEventArgs]$e)
                  $logtype = 'Webview2'
                  try{
                    if($e.ParameterObjectAsJson){
                      $eventmessage = $e.ParameterObjectAsJson | ConvertFrom-Json
                      Write-EZLogs '[YoutubeWebView2] >>>> YoutubeWebview2 Runtime Event Logs Received' -Dev_mode -logtype $logtype -linesbefore 1
                      if($eventmessage.entry){
                        Write-EZLogs "[YoutubeWebView2] | JSON eventmessage.entry: $($eventmessage.entry | Out-String)" -Dev_mode -logtype $logtype
                      }elseif($eventmessage.args){
                        if(-not [string]::IsNullOrEmpty(($eventmessage.args.className | Out-String))){
                          Write-EZLogs "[YoutubeWebView2] | [$(($eventmessage.args.className))]: $($eventmessage.args.description)" -Dev_mode -logtype $logtype
                        }else{
                          if(-not [string]::IsNullOrEmpty(($eventmessage.args.description | Out-String))){                           
                            Write-EZLogs "[YoutubeWebView2] | $(($eventmessage.args.type)): $($eventmessage.args.value) -- Description: $($eventmessage.args.description)" -Dev_mode -logtype $logtype
                          }else{
                            Write-EZLogs "[YoutubeWebView2] | [$(($eventmessage.args.type))]: $($eventmessage.args.value)" -Dev_mode -logtype $logtype
                          }                         
                        }                  
                      }elseif($eventmessage){
                        Write-EZLogs "[YoutubeWebView2] | JSON message: $($eventmessage | Out-String)" -Dev_mode -logtype $logtype
                      }                    
                    }elseif($e){
                      Write-EZLogs "[YoutubeWebView2] | CoreWebView2DevToolsProtocolEventReceivedEventArgs: $($e | Out-String)" -Dev_mode -logtype $logtype
                    }                  
                  }catch{
                    Write-EZLogs '[YoutubeWebView2] An exception occurred in Runtime.add_DevToolsProtocolEventReceived' -catcherror $_
                  }
              })
            }
          }         
        }else{
          Write-EZLogs "[YoutubeWebView2] An issue occurred initializing YoutubeWebView2: $($event.InitializationException | Out-String)" -warning -AlertUI -logtype Webview2
        }                                   
      }catch{
        Write-EZLogs "[YoutubeWebView2] An exception occurred in YoutubeWebView2 CoreWebView2InitializationCompleted Event: $($synchash.YoutubeWebView2.CoreWebView2 | Out-String)" -showtime -catcherror $_
      }     
    }
  )
  if(!$synchash.YoutubeWebView2.CoreWebView2){
    $synchash.YoutubeWebView2Env.GetAwaiter().OnCompleted(
      [Action]{
        Write-EZLogs ">>>> Executing YoutubeWebview2 EnsureCoreWebView2Async for YoutubeWebview2env result -- BrowserVersionString: $($synchash.YoutubeWebView2Env.Result.BrowserVersionString) -- UserDataFolder: $($synchash.YoutubeWebView2Env.Result.UserDataFolder)" -showtime -logtype Webview2
        $synchash.YoutubeWebView2.EnsureCoreWebView2Async($synchash.YoutubeWebView2Env.Result)     
      }
    )
  }
  $synchash.YoutubeWebView2_WebMessageReceived = {
    Param(
      $sender,
      [Microsoft.Web.WebView2.Core.CoreWebView2WebMessageReceivedEventArgs]$e,
      $synchash = $synchash,
      $thisApp = $thisApp
    )
    try{
      $result = $e.WebMessageAsJson | ConvertFrom-Json -ErrorAction SilentlyContinue
      if($result.key -eq 'videodata'){
        if($result.value.video_id -and !$result.value.isPlayable){
          Write-EZLogs '[YoutubeWebView2_WebMessageReceived] Youtube webplayer returned media as not playable' -showtime -warning -logtype Webview2 -LogLevel 2
          if($e.Source -match '\/embed\/'){
            try{
              if(!$synchash.start_media_timer.IsEnabled){
                $synchash.Youtube_WebPlayer_retry = 'NoEmbed'
                $synchash.Start_media = $synchash.Current_playing_media
                Write-EZLogs '[YoutubeWebView2_WebMessageReceived] | Will retry without using embed' -showtime -warning -logtype Webview2 -LogLevel 2
                $synchash.start_media_timer.start()
              }
            }catch{
              Write-EZLogs '[YoutubeWebView2_WebMessageReceived] An exception occurred retrying playback without embed for Youtube' -showtime -catcherror $_
            }             
            return
          }
          Write-EZLogs " | Source $($e.Source)" -logtype Webview2 -Warning                
          Write-EZLogs " | errorCode $($result.value.errorCode) - cpn: $($result.value.cpn)" -logtype Webview2 -Warning 
        } 
        if($result.value.author){
          if($synchash.Youtube_webplayer_current_Media.author -ne $result.value.author){
            Write-EZLogs ">>>> Updating Youtube_webplayer_current_Media video id from webplayer videodata: $($result.value)" -showtime -logtype Webview2 -Dev_mode
            $synchash.Youtube_webplayer_current_Media = $result.value
          }
          if($synchash.Now_Playing_Artist_Label.DataContext -ne "$($result.value.author)"){
            Write-EZLogs "| Updating Youtube Author/Artist from webplayer videodata from value: $($synchash.Now_Playing_Artist_Label.DataContext) - to new value: $($result.value.author)" -showtime -logtype Webview2 -LogLevel 2
            $synchash.Now_Playing_Artist_Label.DataContext = "$($result.value.author)"
          }
          if($synchash.Current_playing_media.Artist -and $synchash.Current_playing_media.Artist -ne "$($result.value.author)"){
            $synchash.Current_playing_media.Artist = "$($result.value.author)"
          }elseif($synchash.Current_playing_media.Playlist -and $synchash.Current_playing_media.Playlist -ne "$($result.value.author)"){
            $synchash.Current_playing_media.Playlist = "$($result.value.author)"
          }
        }
        if($result.value.video_id -and $result.value.list -and $synchash.Current_Playing_media.url -match $result.value.list -and $synchash.Current_Playing_media.url -notmatch $result.value.video_id){
          $updatedUrl = "https://www.youtube.com/watch?v=$($result.value.video_id)&list=$($result.value.list)"
          if($synchash.Current_Playing_media.url -ne $updatedUrl){
            write-ezlogs "| Updating current media url from: $($synchash.Current_Playing_media.url) -- to: $updatedUrl" -logtype Webview2
            $synchash.Current_Playing_media.url = $updatedUrl
          } 
        }
        $chatURL = "https://www.youtube.com/live_chat?v=$($result.value.video_id)"
        if($thisApp.Config.Enable_YoutubeComments -and $result.value.video_id -and $result.value.isLive -and $synchash.ChatView_URL -ne $chatURL){
          $synchash.ChatView_URL = $chatURL       
          write-ezlogs "| Youtube video is live, updating chatview with YT live chat url: $chatURL"
          Update-ChatView -synchash $synchash -thisApp $thisApp -Navigate -ChatView_URL $chatURL -show:$thisApp.Config.Chat_View
        }
        #TODO: Gah this logic is horrible! Need to setup ONE reference to check and validate against if its videodata or playerlabel (YoutubeTV)
        if($result.value.title -and $synchash.Current_Playing_media.url -notmatch 'tv\.youtube\.com|accounts\.google\.com' -and ($synchash.Youtube_WebPlayer_title -ne "$($result.value.title)" -or $synchash.Now_Playing_title_Label.DataContext -ne "$($result.value.title)")){
          if($synchash.Youtube_WebPlayer_title -ne "$($result.value.title)"){
            $synchash.Youtube_WebPlayer_title = "$($result.value.title)"
          }
          if($synchash.Now_Playing_title_Label.DataContext -ne "$($result.value.title)"){
            Write-EZLogs "| Updating Youtube title from webplayer videodata from value: $($synchash.Now_Playing_title_Label.DataContext) - to new value: $($result.value.title)" -showtime -logtype Webview2 -LogLevel 2
            $synchash.Now_Playing_title_Label.DataContext = "$($result.value.title)"
          }
          if($synchash.Current_playing_media.Title -and $synchash.Current_playing_media.Title -ne "$($result.value.title)"){
            $synchash.Current_playing_media.Title = "$($result.value.title)"
          }
          if($thisApp.Config.Discord_Integration){
            try{
              Set-DiscordPresense -synchash $synchash -media $synchash.Current_playing_media -thisapp $thisApp -start -update
            }catch{
              Write-EZLogs "[YoutubeWebView2_WebMessageReceived] An exception occurred setting Set-DiscordPresense for Current_playing_media: $($synchash.Current_playing_media | Out-String)"
            }
          }
          if($result.value.video_id){
            if($thisApp.Config.Enable_Sponsorblock -and $thisApp.Config.Sponsorblock_ActionType -and !$result.value.isLive){
              Write-EZLogs "| Updating SponsorBlock with Youtube id: $($result.value.video_id)" -loglevel 2 -logtype Webview2 
              $thisApp.SponsorBlock = Get-SponsorBlock -videoId $result.value.video_id -actionType $thisApp.Config.Sponsorblock_ActionType
            }else{
              $thisApp.SponsorBlock = $null
            }
            Write-EZLogs "| Getting Youtube dislikes for video id: $($result.value.video_id)" -showtime -logtype Webview2 -LogLevel 2
            try{
              $req = [System.Net.HTTPWebRequest]::Create("https://returnyoutubedislikeapi.com/votes?videoId=$($result.value.video_id)")
              $req.Method = 'GET'         
              $req.Timeout = 5000
              $response = $req.GetResponse()
              $strm = $response.GetResponseStream()
              $sr = [System.IO.Streamreader]::new($strm)
              $output = $sr.ReadToEnd()
              $youtube_ds = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()
            }catch{
              Write-EZLogs "An exception occurred getting youtube dislikes with url: https://returnyoutubedislikeapi.com/votes?videoId=$($result.value.video_id)" -catcherror $_
              $error.clear()
            }finally{
              if($response){
                $response.Dispose()
              }
              if($strm){
                $strm.Dispose()
              }
              if($sr){
                $sr.Dispose()
              }   
              $req = $null
            }
            if($youtube_ds.dislikes){
              $DisLikes = $($youtube_ds.dislikes -as [decimal]).ToString('N0')
            }
            if($youtube_ds.likes){
              $Likes = $($youtube_ds.likes -as [decimal]).ToString('N0')
            }
            if($synchash.Likes_Total -and $synchash.DisLikes_Total){
              if($youtube_ds){
                $synchash.Likes_Total.Visibility = 'Visible'
                $synchash.Likes_Total.text = $Likes
                $synchash.DisLikes_Total.text = $DisLikes
              }else{
                $synchash.Likes_Total.Visibility = 'Collapsed'
                $synchash.Likes_Total.text = ''
                $synchash.DisLikes_Total.text = ''
              }
            }
            if($thisApp.Config.Enable_YoutubeComments -and !$result.value.isLive -and $youtube_ds){
              #TODO: Update comments on video change
              Update-ChatView -synchash $synchash -thisApp $thisApp -Navigate -Youtube_ID $($result.value.video_id) -show
            }
          }
        }      
      }
      if($result.key -eq 'time'){
        $synchash.WebPlayer_finished_state = $false
        $synchash.MediaPlayer_CurrentDuration = $result.value
        #write-ezlogs ">>>> Youtube playback current time: $($result.value) -- Sponsorblock.segments: $($thisApp.SponsorBlock.segment)" -dev_mode 
        if($thisApp.Config.Enable_Sponsorblock -and -not [string]::IsNullOrEmpty($thisApp.Config.Sponsorblock_ActionType) -and -not [string]::IsNullOrEmpty($thisApp.SponsorBlock.videoId) -and -not [string]::IsNullOrEmpty($synchash.Current_playing_media.id) -and $synchash.Current_playing_media.id -in $thisApp.SponsorBlock.videoId){
          try{        
            $currentime = [timespan]::FromSeconds($result.value)   
            $Segment = $thisApp.SponsorBlock | Where-Object {[timespan]::FromSeconds($_.segment[0]) -eq $currentime -or ($currentime -gt [timespan]::FromSeconds($_.segment[0]) -and $currentime -lt [timespan]::FromSeconds($_.segment[1]))}
            if($Segment){
              if($thisApp.Config.Sponsorblock_ActionType -eq 'Skip'){
                Write-EZLogs ">>>> Sponsorblock skipping segment for youtubeid $($Segment.videoId) - Start: $($Segment.segment[0]) -- End: $($Segment.segment[1])" -warning
                $YoutubeWebView2_SeekScript = @"
try {
  var player = document.getElementById('movie_player');
  //var state = player.getPlayerState();
  console.log('Seeking Youtube player for Sponsorblock to $($Segment.segment[1])');
  player.seekTo($($Segment.segment[1]));
} catch (error) {
  console.error('An exception occurred seeking player to $($Segment.segment[1])', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}
"@
                $synchash.YoutubeWebView2.ExecuteScriptAsync(
                  $YoutubeWebView2_SeekScript      
                )
              }elseif($thisApp.Config.Sponsorblock_ActionType -eq 'Mute'){
                if(!$synchash.YoutubeWebView2.CoreWebView2.IsMuted){
                  Write-EZLogs ">>>> Sponsorblock muting segment for youtubeid $($Segment.videoId) - Start: $($Segment.segment[0]) -- End: $($Segment.segment[1])" -warning
                  $synchash.YoutubeWebView2.CoreWebView2.IsMuted = $true
                }
              }
            }elseif($thisApp.Config.Sponsorblock_ActionType -eq 'Mute' -and $synchash.YoutubeWebView2.CoreWebView2.IsMuted){
              Write-EZLogs ">>>> Sponsorblock unmuting segment for youtubeid $($Segment.videoId)" -warning
              $synchash.YoutubeWebView2.CoreWebView2.IsMuted = $false
            }
          }catch{
            Write-EZLogs "An exception occurred skipping video segments from sponsorblock: $($thisApp.SponsorBlock | Out-String)" -catcherror $_
          }
        }
      }
      if($result.key -eq 'state'){
        if($synchash.WebPlayer_State -ne $result.value){
          if($thisApp.Config.Dev_mode){Write-EZLogs "Youtube Web message received State: $($result.value)" -showtime -logtype Webview2 -Dev_mode}    
          $synchash.WebPlayer_State = $result.value
        }
        if($synchash.WebPlayer_State -eq 1){
          $synchash.WebPlayer_finished_state = $false
          if(!$synchash.WebPlayer_Playing_timer.isEnabled){
            Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -Start
          }        
          $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
          if($Current_playlist_items){
            $queue_index = $Current_playlist_items.id.indexof($synchash.Current_playing_media.id)
            if($queue_index -ne -1){
              $Current_playing = $Current_playlist_items[$queue_index]
            }else{
              $Current_playing = $Current_playlist_items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
            }
          }
          if($synchash.AudioRecorder.isRecording -and $Current_playing.PlayIconRecordVisibility -eq 'Hidden'){
            $Current_playing.PlayIconRecord = 'RecordRec'
            $Current_playing.PlayIconRecordVisibility = 'Visible'
            $Current_playing.PlayIconRecordRepeat = 'Forever'
            $Current_playing.PlayIconVisibility = 'Hidden'
            $Current_playing.PlayIconRepeat = '1x'
          }elseif($Current_playing.FontWeight -ne 'Bold' -or ($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Playing')){
            if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and  $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Playing'){
              $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
              $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
            }
            Write-EZLogs ">>>> Youtube webplayer state is now playing" -showtime -logtype Webview2
            if($Current_playing){
              try{
                if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                  $Current_playing.PlayIconRepeat = 'Forever'
                }else{
                  write-ezlogs "| Performance_Mode enabled - Disabling playicon animation" -Warning -Dev_mode
                  $Current_playing.PlayIconRepeat = '1x'
                }
                if($Current_playing.FontWeight -ne 'Bold'){
                  $Current_playing.FontWeight = 'Bold'
                  $Current_playing.FontSize = '14' 
                  $Current_playing.PlayIconRecordVisibility = 'Hidden'
                  $Current_playing.PlayIconRecordRepeat = '1x'
                  $Current_playing.PlayIcon = 'CompactDiscSolid'
                  #$current_playing.PlayIconRecord = "RecordRec"
                  $Current_playing.NumberVisibility = 'Hidden'
                  $Current_playing.NumberFontSize = '0'
                  $Current_playing.PlayIconRecordVisibility = 'Hidden'
                  $Current_playing.PlayIconVisibility = 'Visible' 
                  $Current_playing.PlayIconEnabled = $true
                  if($synchash.PlayQueue_TreeView.itemssource){
                    $synchash.PlayQueue_TreeView.itemssource.refresh()
                  }elseif($synchash.PlayQueue_TreeView.items){
                    $synchash.PlayQueue_TreeView.items.refresh()
                  }
                  try{
                    $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                    $synchash.Update_Playing_Playlist_Timer.start()             
                  }catch{
                    Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                  }
                }         
              }catch{
                Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
              }
            }
            if($synchash.VideoView_Play_Icon.kind -ne 'PauseCircleOutline'){
              $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
            }           
            if($synchash.PauseButton_ToggleButton.isChecked){
              $synchash.PauseButton_ToggleButton.isChecked = $false
            }
            if($synchash.MiniPlayButton_ToggleButton.uid -eq 'IsPaused'){
              $synchash.MiniPlayButton_ToggleButton.uid = $null
            }
            if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
              $synchash.PlayButton_ToggleButton.Uid = $null
            }
            if($synchash.PlayButton_ToggleButton -and !$synchash.PlayButton_ToggleButton.isChecked){
              $synchash.PlayButton_ToggleButton.isChecked = $true
            }
            if($synchash.PauseIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
              $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PauseIcon_PackIcon
            }
            if($synchash.PlayIcon1_Storyboard.Storyboard){
              Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Resume
            }
          }
        }elseif($synchash.WebPlayer_State -eq 2){
          $synchash.WebPlayer_finished_state = $false
          if($thisApp.Config.Dev_mode){Write-EZLogs ">>>> Youtube webplayer state is Paused $($result.key): $($result.value)" -showtime -Dev_mode -logtype Webview2}
          $Current_playlist_items = $synchash.PlayQueue_TreeView.Items
          if($Current_playlist_items){
            $queue_index = $Current_playlist_items.id.indexof($synchash.Current_playing_media.id)
            if($queue_index -ne -1){
              $Current_playing = $Current_playlist_items[$queue_index]
            }else{
              $Current_playing = $Current_playlist_items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
            }
          }
          if($synchash.AudioRecorder.isRecording -and $Current_playing.PlayIconRecordVisibility -eq 'Visible'){
            $Current_playing.PlayIconRecord = 'RecordRec'
            $Current_playing.PlayIconRecordVisibility = 'Visible'
            $Current_playing.PlayIconRecordRepeat = '1x'
            $Current_playing.PlayIconVisibility = 'Hidden'
            $Current_playing.PlayIconRepeat = '1x'
          }elseif($Current_playing.PlayIconRepeat -eq 'Forever' -or ($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Paused')){
            if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Paused'){
              $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Paused'
              $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
            }
            Write-EZLogs ">>>> Youtube webplayer state is Paused" -showtime -logtype Webview2
            if($Current_playing){
              try{
                $Current_playing.FontWeight = 'Bold'
                $Current_playing.FontSize = '14' 
                $Current_playing.NumberVisibility = 'Hidden'
                $Current_playing.NumberFontSize = '0'
                $Current_playing.PlayIconRepeat = '1x'
                #$current_playing.PlayIconVisibility = "Hidden"
                $Current_playing.PlayIconEnabled = $true
                if($synchash.PlayQueue_TreeView.itemssource){
                  $synchash.PlayQueue_TreeView.itemssource.refresh()
                }elseif($synchash.PlayQueue_TreeView.items){
                  $synchash.PlayQueue_TreeView.items.refresh()
                }
                try{
                  $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                  $synchash.Update_Playing_Playlist_Timer.start()             
                }catch{
                  Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                }         
              }catch{
                Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
              }
            }
            if($synchash.VideoView_Play_Icon.kind -and $synchash.VideoView_Play_Icon.kind -ne 'PlayCircleOutline'){
              $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'  
            }
            if($synchash.PauseButton_ToggleButton -and !$synchash.PauseButton_ToggleButton.isChecked){
              $synchash.PauseButton_ToggleButton.isChecked = $true
            } 
            if($synchash.MiniPlayButton_ToggleButton -and $synchash.MiniPlayButton_ToggleButton.uid -ne 'IsPaused'){
              $synchash.MiniPlayButton_ToggleButton.uid = 'IsPaused'
            }                
            if($synchash.PlayButton_ToggleButton -and $synchash.PlayButton_ToggleButton.Uid -ne 'IsPaused'){
              $synchash.PlayButton_ToggleButton.Uid = 'IsPaused'
            }
            if($synchash.PlayButton_ToggleButton.isChecked){
              $synchash.PlayButton_ToggleButton.isChecked = $false
            }
            if($synchash.PlayIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
              $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PlayIcon_PackIcon
            }
            if($synchash.PlayIcon1_Storyboard.Storyboard){
              Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Pause
            }                                           
          } 
        }elseif(($synchash.WebPlayer_State -eq 0 -or $synchash.WebPlayer_State -eq 99) -and ($synchash.Current_playing_media.Url -notmatch 'tv\.youtube\.com' -and $synchash.Current_playing_media.Type -notmatch 'YoutubeTV' -and !$synchash.WebPlayer_finished_state)){
          Write-EZLogs ">>>> Youtube webplayer state $($result.key): $($result.value)" -showtime -logtype Webview2     
          if($thisApp.config.Auto_Playback -and $synchash.Youtube_WebPlayer_URL -match '\&list=' -and $synchash.WebPlayer_State -eq 99){
            write-ezlogs "| Youtube webplayer is playing a playlist, Auto_Playback is enabled so letting playback continue to next video" -warning -logtype Webview2
            return
          }else{
            $synchash.Youtube_WebPlayer_title = $null
            Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
            if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
              $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Stopped'
              $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.ClearAll()
              $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
            }
            if($thisApp.config.Auto_Repeat){
              Write-EZLogs '| Auto_Repeat enabled, restarting current media' -showtime
              Start-Media -Media $synchash.Current_playing_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification -restart
            }elseif($thisApp.config.Auto_Playback){
              if($synchash.SkipMedia_isExecuting){
                Write-EZLogs 'Skip-Media is already executing, this could be a race condition or other conflict!' -showtime
                break
              }else{
                Write-EZLogs '| Youtube Webplayer reports finished, Auto_Playback enabled, executing Skip-Media' -showtime
                Skip-Media -synchash $synchash -thisApp $thisApp
              }               
            }else{
              Stop-Media -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp -UpdateQueue -StopMonitor
            }
            $synchash.WebPlayer_finished_state = $true
            return
          }
        }
      }
      if($result.key -eq 'Playerlabel'){
        if(-not [string]::IsNullOrEmpty($result.value)){
          if($synchash.Now_Playing_Title_Label.DataContext -ne "$($result.value)"){
            Write-EZLogs ">>>> Updating Youtube Title from webplayer Playerlabel from value: $($synchash.Now_Playing_Title_Label.DataContext) - to new value: $($result.value)" -showtime -logtype Webview2 -LogLevel 2
            $synchash.Youtube_WebPlayer_title = $result.value
            $synchash.Now_Playing_Title_Label.DataContext = "$($result.value)"
            if($synchash.Current_playing_media.title -ne "$($result.value)"){
              $synchash.Current_playing_media.title = "$($result.value)"
            }
            if($thisApp.Config.Discord_Integration){
              if($synchash.DSClient.IsInitialized){
                $details = "Watching: $($result.value)"                     
                if($synchash.Current_playing_media.url){
                  $url = $synchash.Current_playing_media.url
                }elseif($synchash.Current_playing_media.Uri){
                  $url = $synchash.Current_playing_media.Uri
                }
                if($synchash.Current_playing_media.source -match 'YoutubeTV' -or $url -match 'tv\.youtube\.com'){
                  $SmallImageKey = 'youtubetv'
                  $SmallImageText = 'Youtube TV'
                  $Label = 'Watch on Youtube TV'
                }else{
                  $SmallImageKey = 'youtube'
                  $SmallImageText = 'Youtube'
                  $Label = 'Watch on Youtube'
                }
                if($synchash.Youtube_webplayer_current_Media.author){
                  $Artist = "$($synchash.Youtube_webplayer_current_Media.author)"
                }elseif($synchash.Current_playing_media.artist){
                  $Artist = "$($synchash.Current_playing_media.artist)"
                }elseif($synchash.Current_playing_media.Playlist){
                  $Artist = "$($synchash.Current_playing_media.Playlist)"
                }else{
                  $Artist = $null
                } 
                if($Artist){
                  $State = "on Channel: $Artist"
                }else{
                  $State = "on $SmallImageText"
                }
                $LargeImageText = "$($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)"
                $buttons = New-DSButton -Label $Label -Url $url    
                $Assets = New-DSAsset -SmallImageKey $SmallImageKey -SmallImageText $SmallImageText -LargeImageText $LargeImageText -LargeImageKey 'samson_icon_notext1'
                Write-EZLogs ">>>> Updating Youtube Title from webplayer for Discord_Integration - title: $($synchash.Youtube_WebPlayer_title) - Artist: $($Artist)" -showtime -logtype Discord -LogLevel 2
                $null = Update-DSRichPresence -Details $details -State $State -Buttons $buttons -Assets $Assets
              }else{
                Write-EZLogs ">>>> Starting Discord_Integration For youtube webplayer - title: $($synchash.Current_playing_media.title) - Artist: $($synchash.Current_playing_media.Artist)" -showtime -logtype Discord -LogLevel 2
                Set-DiscordPresense -synchash $synchash -media $synchash.Current_playing_media -thisapp $thisApp -start
              }
            }elseif($synchash.DSClient.IsInitialized){
              Write-EZLogs ">>>> Discord client is initialized but Discord integration is not enabled, stopping discord" -showtime -logtype Discord -LogLevel 2 -warning
              Set-DiscordPresense -thisApp $thisapp -synchash $synchash -Stop
            }          
          } 
        }
      }elseif($result.key -eq 'player_data'){
        if(!($synchash.Youtube_WebPlayer_title) -and $result.value.title -and $synchash.Now_Playing_Title_Label.DataContext -ne "$($result.value.title)"){
          Write-EZLogs "Updating Youtube Title from webplayer player_data from value: $($synchash.Now_Playing_Title_Label.DataContext) - to new value: $($result.value.title)" -showtime -logtype Webview2 -LogLevel 2
          $synchash.Now_Playing_Title_Label.DataContext = "$($result.value.title)"
        }             
      } 
      if($result.key -eq 'video_data'){
        if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received video_data: $($result.value.params | Out-String)" -showtime -logtype Webview2 -LogLevel 4}
        $synchash.Invidious_webplayer_current_Media = $result.value
      }       
      if($result.key -eq 'duration' -and $synchash.MediaPlayer_TotalDuration -ne $result.value){
        if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received duration: $($result.value)" -showtime -logtype Webview2 -LogLevel 2 -Dev_mode}
        $synchash.MediaPlayer_TotalDuration = $result.value
      }
      if($result.key -eq 'volume'){
        if($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|invidious'){
          $volume = $result.value * 100
        }else{
          $volume = $result.value
        }
        #TODO: Sync webplayer volume with libvlc?
        if(-not [string]::IsNullOrEmpty($volume) -and $thisApp.Config.Media_Volume -ne $volume){
          $thisApp.Config.Media_Volume = $volume
        }
        #elseif(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value) -and $thisApp.Config.Media_Volume -ne $synchash.Volume_Slider.value){
        #$thisApp.Config.Media_Volume = $synchash.Volume_Slider.value
        #}
        if($synchash.Vlc.isPlaying -or $synchash.Vlc.state -match 'Paused'){
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $synchash.vlc.setVolume($thisApp.Config.Media_Volume)
          }else{
            $synchash.vlc.Volume = $thisApp.Config.Media_Volume
          }
        }
        if($synchash.Volume_Slider.value -ne $thisApp.Config.Media_Volume){
          if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received volume: $($result.value) - changing volume_slider value from: $($synchash.Volume_Slider.value) -- to: $($thisApp.Config.Media_Volume)" -showtime -logtype Youtube -Dev_mode}
          $synchash.Volume_Slider.value = $thisApp.Config.Media_Volume
        }          
        if($synchash.VideoView_Mute_Icon){
          if($synchash.Volume_Slider.value -ge 75){
            $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
          }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
            $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
          }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
            $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
          }elseif($synchash.Volume_Slider.value -le 0){
            $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
          }
        }
      }
      if($result.key -eq 'MuteStatus'){
        if(-not [string]::IsNullOrEmpty($result.value)){
          if($synchash.MuteButton_ToggleButton){
            if($result.value -and !$synchash.MuteButton_ToggleButton.isChecked){    
              if($thisApp.Config.Dev_mode){Write-EZLogs "Youtube Web message received MuteStatus: $($result.value) -- checking mute togglebutton" -showtime -logtype Webview2 -Dev_mode}             
              $synchash.MuteButton_ToggleButton.isChecked = $true
            }elseif(!$result.value -and $synchash.MuteButton_ToggleButton.isChecked){
              if($thisApp.Config.Dev_mode){Write-EZLogs "Youtube Web message received MuteStatus: $($result.value) -- umchecking mute togglebutton" -showtime -logtype Webview2 -Dev_mode}   
              $synchash.MuteButton_ToggleButton.isChecked = $false
            }
          }
          if($synchash.VideoView_Mute_Icon){
            if($result.value){
              $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
            }elseif($synchash.Volume_Slider.Value -ge 75){
              $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
            }elseif($synchash.Volume_Slider.Value -gt 25 -and $synchash.Volume_Slider.Value -lt 75){
              $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
            }elseif($synchash.Volume_Slider.Value -le 25 -and $synchash.Volume_Slider.Value -gt 0){
              $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
            }elseif($synchash.Volume_Slider.Value -le 0){
              $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
            }
          }
        }
      } 
      <#      if($thisApp.Config.Dev_mode -and $result.key -eq 'videoUrl' -and $result.value){
          write-ezlogs "Web message received videoUrl : $($result.value | out-string)" -showtime -Dev_mode -logtype Webview2
      }#>
      if($result.key -eq 'error'){
        if($result.value -eq '150' -or $result.value -eq '101'){
          Write-EZLogs '[YoutubeWebview2] Youtube ERROR 150, usually means this video is not allowed to be played outside of youtube.com, may not support embed' -showtime -Warning -logtype Webview2 -LogLevel 2
        }elseif($result.value -eq '100'){
          Write-EZLogs '[YoutubeWebview2] Youtube ERROR 100: The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private' -showtime -warning -logtype Webview2 -LogLevel 2 -AlertUI
        }elseif($result.value -eq '5'){
          Write-EZLogs '[YoutubeWebview2] Youtube ERROR 5: The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred' -showtime -warning -logtype Webview2 -LogLevel 2
          if($e.Source -match '\/embed\/'){
            try{
              if(!$synchash.start_media_timer.IsEnabled){
                $synchash.Youtube_WebPlayer_retry = 'NoEmbed'
                $synchash.Start_media = $synchash.Current_playing_media
                Write-EZLogs ' | Will retry without using embed' -showtime -warning -logtype Webview2 -LogLevel 2
                $synchash.start_media_timer.start()
              }
            }catch{
              Write-EZLogs 'An exception occurred retrying playback without embed for Youtube' -showtime -catcherror $_
            }             
            return
          }else{
            Update-Notifications  -Level 'WARNING' -Message 'Youtube ERROR 5: The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
          }
        }elseif($result.value -eq '2'){
          Write-EZLogs "[YoutubeWebview2] Youtube ERROR 2: The request contains an invalid parameter value. For example, this error occurs if you specify a video ID that does not have 11 characters, or if the video ID contains invalid characters, such as exclamation points or asterisks`nURL: $($e.Source)" -showtime -warning -logtype Webview2 -LogLevel 2
        }else{
          Write-EZLogs "[YoutubeWebview2] Youtube ERROR: $($result.value)" -showtime -warning -logtype Webview2 -LogLevel 2
        }
      }  
      if($result.key -eq 'fullscreenchange'){
        if($thisApp.Config.Dev_mode){Write-EZLogs '[YoutubeWebview2] >>>> Received Youtube fullscreenchange event' -showtime -logtype Webview2 -LogLevel 2 -Dev_mode}
      }  
      if($result.key -eq 'fullscreenbutton'){
        Write-EZLogs '[YoutubeWebview2] >>>> Received Youtube fullscreenbutton click event' -showtime -logtype Webview2 -LogLevel 2
        if($result.value.isTrusted -and !$synchash.MediaViewAnchorable.isFloating -and !$synchash.VideoViewFloat.isVisible){
          try{
            Write-EZLogs '[YoutubeWebview2] | Invoking Set-VideoPlayer' -showtime -logtype Webview2 -LogLevel 2
            $synchash.YT_fullscreenbutton_Event = [DateTime]::Now
            Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action FullScreen                 
          }catch{
            Write-EZLogs 'An exception occurred in MiniOpenButton_Button.add_Click' -CatchError $_ -showtime
          }              
        }elseif($result.value.isTrusted -and $synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.WindowState -eq 'Maximized' -and [DateTime]::Now.Subtract([TimeSpan]::FromSeconds(1)) -gt $synchash.YT_fullscreenbutton_Event){
          $synchash.YT_fullscreenbutton_Event = [DateTime]::Now
          Write-EZLogs '[YoutubeWebview2] | Video player is floating, maximized, setting to normal' -logtype Webview2 -LogLevel 2
          Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Normal
        }elseif($result.value.isTrusted -and $synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.WindowState -ne 'Maximized' -and [DateTime]::Now.Subtract([TimeSpan]::FromSeconds(1)) -gt $synchash.YT_fullscreenbutton_Event){
          $synchash.YT_fullscreenbutton_Event = [DateTime]::Now
          Write-EZLogs '[YoutubeWebview2] | Video player is floating, maximized, setting to Maximized' -logtype Webview2 -LogLevel 2
          Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Maximized 
        } 
      } 
      if($result.key -eq 'currentquality'){
        Write-EZLogs "[YoutubeWebview2] >>>> Received current Youtube quality: $($result.value)" -showtime -logtype Webview2 -LogLevel 2
        if($result.value -and $synchash.DisplayPanel_VideoQuality_TextBlock){
          $synchash.DisplayPanel_VideoQuality_TextBlock.text = "$($result.value)"
        }
      }
    }catch{
      Write-EZLogs 'An exception occurred in YoutubeWebView2 WebMessageReceived event' -showtime -catcherror $_
    }   
  }
  $synchash.YoutubeWebView2.Remove_WebMessageReceived($synchash.YoutubeWebView2_WebMessageReceived)
  $synchash.YoutubeWebView2.add_WebMessageReceived($synchash.YoutubeWebView2_WebMessageReceived)
}
#---------------------------------------------- 
#endregion Initialize-YoutubeWebPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region New-WebContextMenu Function
#----------------------------------------------
function New-WebContextMenu{
  [CmdletBinding()]
  Param(
    $e,
    $menulist,
    $cm
  )       
  try{
    for($i = 0; $i -lt $menulist.count; $i++){
      $current = $menulist[$i]
      if ($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Separator){
        $Separator = [System.Windows.Controls.Separator]::new()
        [void]$cm.Items.Add($Separator)
        continue
      }
      $MenuItem = [System.Windows.Controls.MenuItem]::new()
      $MenuItem.Header = $current.label -replace '&', '_'
      $MenuItem.InputGestureText = $current.ShortcutKeyDescription
      $MenuItem.IsEnabled = $current.IsEnabled
      if ($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Submenu){
        New-WebContextMenu -e $e -menulist $current.children -cm $MenuItem
      }else{
        if($current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::CheckBox -or $current.Kind -eq [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Radio){
          $MenuItem.IsCheckable = $true
          $MenuItem.IsChecked = $current.IsChecked
        }
        $MenuItem.add_Click({
            $e.SelectedCommandId = $current.CommandId
        }.GetNewClosure())
      }
      [void]$cm.Items.add($MenuItem)
    }
  }catch{
    Write-EZLogs 'An exception occurred in New-WebContextMenu' -catcherror $_
  }
}
#---------------------------------------------- 
#endregion New-WebContextMenu Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebPlayer Function
#----------------------------------------------
Function Initialize-WebPlayer
{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    $thisScript
  ) 
  try{
    if(!$synchash.WebView2 -or !$synchash.Webview2.CoreWebView2){
      Write-EZLogs '>>>> Creating new Webview2 instance' -showtime -logtype Webview2
      $synchash.WebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
    }
    $synchash.Webview2.DefaultBackgroundColor = [System.Drawing.Color]::Transparent
    if($synchash.WebView2Env.IsCompleted){
      Write-EZLogs ">>>> WebView2Env already initialized - UserDataFolder: $($synchash.WebView2Env.Result.UserDataFolder)" -showtime -logtype Webview2
      $synchash.Webview2.EnsureCoreWebView2Async( $synchash.WebView2Env.Result )
    }else{      
      $synchash.WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
      $synchash.WebView2Options.IsCustomCrashReportingEnabled = $true
      $synchash.WebView2Options.AdditionalBrowserArguments = '--autoplay-policy=no-user-gesture-required --Disable-features=HardwareMediaKeyHandling,OverscrollHistoryNavigation,msExperimentalScrolling'
      $synchash.WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
        [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.WebView2Options
      )
      if(!$synchash.WebView2.CoreWebView2){
        $synchash.WebView2Env.GetAwaiter().OnCompleted(
          [Action]{
            Write-EZLogs "Initialzing new WebView2Env: $($synchash.WebView2Env)" -showtime -logtype Webview2
            $synchash.WebView2.EnsureCoreWebView2Async( $synchash.WebView2Env.Result )
      
          }
        )
      }
    }
  }catch{
    Write-EZLogs 'An exception occurred creating webview2 Enviroment' -showtime -catcherror $_
  }
  if(!$synchash.SpotifyWebview2_NavigationCompleted){
    $synchash.SpotifyWebview2_NavigationCompleted = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
      param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]$e)
      $synchash = $synchash
      $thisApp = $thisApp
      try{
        if($thisApp.Config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title -and $synchash.Spotify_WebPlayer.SpotifyToken){
          if($synchash.Volume_Slider.Value -ne $null){
            $volume = $synchash.Volume_Slider.Value / 100
          }elseif($thisApp.Config.Media_Volume -ne $null){
            $volume = $thisApp.Config.Media_Volume / 100
          }else{
            $volume = 1
          }
          $synchash.Spotify_StartScript_Webview2 = @"

// Set token
 var _token = '$($synchash.Spotify_WebPlayer.SpotifyToken)';
  SpotifyWeb.player = new Spotify.Player({
    name: '$($thisApp.Config.App_Name) Media Player',
    volume: $($synchash.Volume_Slider.Value / 100),
    getOAuthToken: cb => { cb(_token); }
  });

function play(device_id) {
try {
  $.ajax({
   url: "https://api.spotify.com/v1/me/player/play?device_id=" + device_id,
   type: "PUT",
   data: '{"uris": ["spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)"]}',
   beforeSend: function(xhr){xhr.setRequestHeader('Authorization', 'Bearer ' + _token );},
   success: function(data) { 
     console.log('Started Playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId) - deviceid', device_id);
     console.log(data)
   }
  });
} catch (error) {
  console.error('An exception occurred attempting to start playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)', error);

}

}
  // Error handling
  SpotifyWeb.player.on('initialization_error', e => console.error(e));
  SpotifyWeb.player.on('authentication_error', e => console.error(e));
  SpotifyWeb.player.on('account_error', e => console.error(e));
  SpotifyWeb.player.on('playback_error', e => console.error(e));
  SpotifyWeb.player.on('account_error', e => {
    console.log('Spotify Account Error',e);
     var account_errorObject =
      {
        Key: 'account_error',
        Value: e
      };
      window.chrome.webview.postMessage(account_errorObject); 
  });
  // Playback status updates
  SpotifyWeb.currState = {}
  SpotifyWeb.player.on('player_state_changed', state => {
    //console.log(state);
    //`$('#current-track').attr('src', state.track_window.current_track.album.images[0].url);
    `$('#current-track-name').text(```${state.track_window.current_track.name} - `${state.track_window.current_track.album.name}``);
     SpotifyWeb.currState.current_track = state.track_window.current_track  
     SpotifyWeb.currState.position = state.position;   
     SpotifyWeb.currState.duration = state.duration;
     SpotifyWeb.currState.updateTime = performance.now()
     SpotifyWeb.currState.current_track = state.track_window.current_track;
     let previous = state.track_window.previous_tracks[0];
     console.log(state.track_window.current_track);
     console.log(previous);
    if (
        SpotifyWeb.currState 
        && previous
        && previous.uid == state.track_window.current_track.uid
        && state.paused
        ) {
        console.log('Track ended');
        SpotifyWeb.currState.playbackstate = 0
      var playbackended =
      {
        Key: 'playbackended',
        Value: true
      };
        window.chrome.webview.postMessage(playbackended); 
      } else{
        SpotifyWeb.currState.playbackstate = 1
        SpotifyWeb.currState.paused = state.paused;
      }   
    //console.log(state.track_window.previous_tracks);
  });
// Play a specified track on the Web Playback SDK's device ID
  // Ready
  SpotifyWeb.player.on('ready', data => {
    console.log('Ready with Device ID', data.device_id);
  console.log('Setting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
  SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100));
  var SpotifyDeviceID =
  {
    Key: 'SpotifyDeviceID',
    Value: data.device_id
  };
    window.chrome.webview.postMessage(SpotifyDeviceID);     
    // Play a track using our new device ID
    //play(data.device_id);
  });
    // Connect to the player!
  SpotifyWeb.player.connect();

"@
          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Spotify_StartScript_Webview2      
          )
        }else{
          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Webview2_Script       
          )   
        }     
      }catch{
        Write-EZLogs 'An exception occurred in SpotifyWebview2_NavigationCompleted_Scriptblock' -catcherror $_
      }
    }
  }
  $synchash.WebView2.Remove_NavigationCompleted($synchash.SpotifyWebview2_NavigationCompleted)
  $synchash.WebView2.Add_NavigationCompleted($synchash.SpotifyWebview2_NavigationCompleted)   

  if(!$synchash.SpotifyWebview2_InitializationCompleted){
    $synchash.SpotifyWebview2_InitializationCompleted = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
      param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]$e)
      try{
        $synchash = $synchash
        $thisApp = $thisApp
        Write-EZLogs '>>>> WebView2 CoreWebView2InitializationCompleted' -showtime -logtype Webview2
        if($e.IsSuccess){   
          [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.WebView2.CoreWebView2.Settings
          if($synchash.WebView2.CoreWebView2){           
            $Settings.AreDefaultContextMenusEnabled  = $true
            $Settings.AreDefaultScriptDialogsEnabled = $true
            $Settings.AreDevToolsEnabled             = $true
            $Settings.AreHostObjectsAllowed          = $true
            $Settings.IsBuiltInErrorPageEnabled      = $false
            $Settings.IsScriptEnabled                = $true
            $Settings.IsStatusBarEnabled             = $false
            $Settings.IsWebMessageEnabled            = $true
            $Settings.IsZoomControlEnabled           = $false
            $Settings.IsGeneralAutofillEnabled       = $false
            $Settings.IsPasswordAutosaveEnabled      = $false
            $Settings.AreBrowserAcceleratorKeysEnabled = $thisApp.Config.Dev_mode
            $Settings.IsSwipeNavigationEnabled = $false
          }
          if($thisApp.Config.Dev_mode){Write-EZLogs "| Webview2 CoreWebview2: $($synchash.WebView2.CoreWebView2 | Out-String)" -showtime -logtype Webview2 -Dev_mode}
          $synchash.WebView2.CoreWebView2.AddWebResourceRequestedFilter('*', [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All)               
          if($thisApp.Config.Spotify_SP_DC){
            Write-EZLogs "Adding Spotify Cookie $($thisApp.Config.Spotify_SP_DC)" -showtime -logtype Webview2 -Dev_mode
            $OptanonAlertBoxClosed = $synchash.WebView2.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-Date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), '.spotify.com', '/')
            $synchash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed)           
            $sp_dc = $synchash.WebView2.CoreWebView2.CookieManager.CreateCookie('sp_dc', $thisApp.Config.Spotify_SP_DC, '.spotify.com', '/')
            $sp_dc.IsSecure = $true
            $synchash.WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($sp_dc)   
          }        
          $synchash.Webview2.CoreWebView2.add_WebResourceRequested({
              [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e = $args[1]
              try{
                $Cookies = ($e.Request.Headers | Where-Object {$_.key -eq 'cookie'}).value
                if($Cookies){
                  $Cookies = $Cookies -split ';'
                  $sp_dc = $Cookies | Where-Object {$_ -match 'sp_dc=(?<value>.*)'}       
                  if($sp_dc){
                    $existin_sp_dc = ([regex]::matches($sp_dc,  'sp_dc=(?<value>.*)') | & { process {$_.groups[1].value}})
                    $thisApp.Config.Spotify_SP_DC = $existin_sp_dc
                    if($thisApp.Config.Dev_mode){Write-EZLogs "Found SP_DC $($existin_sp_dc | Out-String)" -showtime -logtype Webview2 -Dev_mode}                           
                  }                                          
                }
              }catch{
                Write-EZLogs 'An exception occurred in CoreWebView2 WebResourceRequested Event' -showtime -catcherror $_
              }
          })
          if($synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer){
            if($synchash.Spotify_WebPlayer_URL -match 'Spotify Embed'){
              Write-EZLogs "Navigating with CoreWebView2.NavigateToString: $($synchash.Spotify_WebPlayer_URL)" -logtype Webview2
              $synchash.WebView2.CoreWebView2.NavigateToString($synchash.Spotify_WebPlayer_URL)
            }else{
              Write-EZLogs ">>>> Navigating with CoreWebView2.Navigate: $($synchash.Spotify_WebPlayer_URL)" -logtype Webview2
              $synchash.WebView2.CoreWebView2.Navigate($synchash.Spotify_WebPlayer_URL)
            }        
          }      
          $synchash.Webview2.CoreWebView2.add_IsDocumentPlayingAudioChanged({
              if($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio){
                Write-EZLogs '>>>> Spotify Webview2 Audio has begun playing, starting webplayer_playing_timer' -showtime -logtype Webview2
                if($thisApp.Config.Enable_EQ -and !$synchash.vlc.IsPlaying -and $([string]$synchash.vlc.media.Mrl).StartsWith('dshow://')){
                  Write-EZLogs 'EQ for Spotify is enabled but Vlc is not playing, executing play()' -Warning
                  $synchash.vlc.play()
                }
                if($synchash.Spotify_WebPlayer.Deviceid -and !$synchash.Spotify_WebPlayer.is_started){
                  $synchash.Spotify_WebPlayer.is_started = $true
                }
                if($synchash.Timer.isEnabled){
                  $synchash.Timer.Stop()  
                }
                Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -start           
                Write-EZLogs "| Webview2.CoreWebView2 PID: $($synchash.Webview2.CoreWebView2.BrowserProcessId) -- DocumentTitle: $($synchash.Webview2.CoreWebView2.DocumentTitle)" -loglevel 2 -logtype Webview2   
                if(-not [string]::IsNullOrEmpty($synchash.Current_Audio_Session.GroupingParam) -and $synchash.Managed_AudioSession_Processes -notcontains $synchash.Webview2.CoreWebView2.BrowserProcessId){
                  Set-AudioSessions -thisApp $thisApp -synchash $synchash
                }   
              }else{
                Write-EZLogs '>>>> Spotify Web Player has stopped playing audio' -logtype Webview2                  
              }
          })
      
          $synchash.Webview2.CoreWebView2.add_IsMutedChanged({
              if($synchash.Webview2.CoreWebView2.IsMuted){
                Write-EZLogs '#### Webview2 Audio has been muted' -showtime -logtype Webview2      
              }else{
                Write-EZLogs '#### Webview2 Audio has been un-muted' -showtime -logtype Webview2
              }
          })
          if($thisApp.Config.Dev_mode){
            Write-EZLogs '>>> Enabling DevToolsProtocolEventReceived event for SpotifyWebview2' -Dev_mode -logtype Webview2
            $CallDevtools = $synchash.Webview2.CoreWebView2.CallDevToolsProtocolMethodAsync('Log.enable', '{}')
            $CallDevtools = $synchash.Webview2.CoreWebView2.CallDevToolsProtocolMethodAsync('Runtime.enable', '{}')
            $SpotifyWebview2_DevToolsProtocolEventReceivedLog = $synchash.Webview2.CoreWebView2.GetDevToolsProtocolEventReceiver('Log.entryAdded')   
            $SpotifyWebview2_DevToolsProtocolEventReceivedRuntime = $synchash.Webview2.CoreWebView2.GetDevToolsProtocolEventReceiver('Runtime.consoleAPICalled')      
            if($SpotifyWebview2_DevToolsProtocolEventReceivedLog){         
              Write-EZLogs ' | Registering Spotify DevTools Event Log' -Dev_mode -logtype Webview2
              $SpotifyWebview2_DevToolsProtocolEventReceivedLog.add_DevToolsProtocolEventReceived({
                  Param($sender)
                  [Microsoft.Web.WebView2.Core.CoreWebView2DevToolsProtocolEventReceivedEventArgs]$e = $args[1]
                  try{
                    if($args.ParameterObjectAsJson){
                      $eventmessage = $args.ParameterObjectAsJson | ConvertFrom-Json
                      Write-EZLogs '>>>> SpotifyWebview2 Event Logs Received' -Dev_mode -logtype Webview2 -linesbefore 1
                      if($eventmessage.entry){
                        Write-EZLogs " | [$(($eventmessage.entry.level).ToUpper()) - $(($eventmessage.entry.source).ToUpper())] $($eventmessage.entry.text | Out-String)" -Dev_mode -logtype Webview2
                        Write-EZLogs " | [URL] $($eventmessage.entry.url)" -Dev_mode -logtype Webview2
                      }elseif($eventmessage.args){
                        if(-not [string]::IsNullOrEmpty($eventmessage.args.className)){
                          Write-EZLogs " | [$(($eventmessage.args.className))]: $($eventmessage.args.description)" -Dev_mode -logtype Webview2
                        }else{
                          if(-not [string]::IsNullOrEmpty($eventmessage.args.description)){                           
                            Write-EZLogs " | $(($eventmessage.args.type)): $($eventmessage.args.value) -- Description: $($eventmessage.args.description)" -Dev_mode -logtype Webview2
                          }else{
                            Write-EZLogs " | [$(($eventmessage.args.type))]: $($eventmessage.args.value)" -Dev_mode -logtype Webview2
                          }                         
                        }                  
                      }else{
                        Write-EZLogs " | JSON message: $($eventmessage | Out-String)" -Dev_mode -logtype Webview2
                      }                    
                    }else{
                      Write-EZLogs " | Args: $($args | Out-String)" -Dev_mode -logtype Webview2
                    }                  
                  }catch{
                    Write-EZLogs 'An exception occurred in Logs.DevToolsProtocolEventReceived' -catcherror $_
                  }
              })
            }
            if($SpotifyWebview2_DevToolsProtocolEventReceivedRuntime){         
              Write-EZLogs ' | Registering Spotify DevTools Event Runtime' -Dev_mode -logtype Webview2
              $SpotifyWebview2_DevToolsProtocolEventReceivedRuntime.add_DevToolsProtocolEventReceived({
                  Param($sender)
                  [Microsoft.Web.WebView2.Core.CoreWebView2DevToolsProtocolEventReceivedEventArgs]$e = $args[1]
                  try{
                    if($args.ParameterObjectAsJson){
                      $eventmessage = $args.ParameterObjectAsJson | ConvertFrom-Json
                      Write-EZLogs '>>>> SpotifyWebview2 Runtime Event Logs Received' -Dev_mode -logtype Webview2 -linesbefore 1
                      if($eventmessage.entry){
                        Write-EZLogs " | JSON eventmessage.entry: $($eventmessage.entry | Out-String)" -Dev_mode -logtype Webview2
                      }elseif($eventmessage.args){
                        if(-not [string]::IsNullOrEmpty(($eventmessage.args.className | Out-String))){
                          Write-EZLogs " | [$(($eventmessage.args.className))]: $($eventmessage.args.description)" -Dev_mode -logtype Webview2
                        }else{
                          if(-not [string]::IsNullOrEmpty(($eventmessage.args.description | Out-String))){                           
                            Write-EZLogs " | $(($eventmessage.args.type)): $($eventmessage.args.value) -- Description: $($eventmessage.args.description)" -Dev_mode -logtype Webview2
                          }else{
                            Write-EZLogs " | [$(($eventmessage.args.type))]: $($eventmessage.args.value)" -Dev_mode -logtype Webview2
                          }                         
                        }                  
                      }else{
                        Write-EZLogs " | JSON message: $($eventmessage | Out-String)" -Dev_mode -logtype Webview2
                      }                    
                    }else{
                      Write-EZLogs " | Args: $($args | Out-String)" -Dev_mode -logtype Webview2
                    }                  
                  }catch{
                    Write-EZLogs 'An exception occurred in Runtime.add_DevToolsProtocolEventReceived' -catcherror $_
                  }
              })
            }
          }
          $synchash.Webview2.CoreWebView2.add_ProcessFailed({
              Param($sender)
              [Microsoft.Web.WebView2.Core.CoreWebView2ProcessFailedEventArgs]$e = $args[1]
              try{
                Write-EZLogs "Spotify WebPlayer ProcessFailed - Uri: $($e.Uri) - ProcessFailedKind: $($args.ProcessFailedKind) - Reason: $($args.reason) - ExitCode: $($args.exitcode)" -isError -AlertUI -logtype Webview2
                if($thisApp.Config.Dev_mode){Write-EZLogs "Webview2.CoreWebView2: $($synchash.Webview2.CoreWebView2 | Out-String)" -Dev_mode -logtype Webview2}
              }catch{
                Write-EZLogs 'An exception occurred in Webview2.CoreWebView2.add_ProcessFailed' -catcherror $_
              }
          }) 
          $synchash.Webview2.CoreWebView2.MemoryUsageTargetLevel = 'Low'
        }else{
          Write-EZLogs "An issue occurred initializing WebView2: $($e.InitializationException | Out-String) - CoreWebView2: $($synchash.WebView2.CoreWebView2 | Out-String)" -warning -logtype Webview2
          Update-Notifications  -Level 'WARNING' -Message 'An issue occurred initializing WebView2 - See logs for details' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
        }                                  
      }catch{
        Write-EZLogs 'An exception occurred in CoreWebView2InitializationCompleted Event' -showtime -catcherror $_
      }
    }
  }
  $synchash.WebView2.Remove_CoreWebView2InitializationCompleted($synchash.SpotifyWebview2_InitializationCompleted)
  $synchash.WebView2.Add_CoreWebView2InitializationCompleted($synchash.SpotifyWebview2_InitializationCompleted)
 
  if(!$synchash.SpotifyWebview2_WebMessageReceived){
    $synchash.SpotifyWebview2_WebMessageReceived = {
      Param(
        $sender,
        [Microsoft.Web.WebView2.Core.CoreWebView2WebMessageReceivedEventArgs]$e,
        $synchash = $synchash,
        $thisApp = $thisApp
      )
      try{
        $results = $e.WebMessageAsJson | ConvertFrom-Json -ErrorAction SilentlyContinue
        foreach($result in $results){
          if($result.key -eq 'time'){
            Write-EZLogs "Web message received Time: $($result.value)" -showtime -logtype Webview2
            $synchash.MediaPlayer_CurrentDuration = $result.value
          }
          if($result.key -eq 'state'){           
            if($synchash.WebPlayer_State -ne $result.value){
              if($thisApp.Config.Dev_mode){Write-EZLogs "Spotify Web message received State: $($result.value)" -showtime -logtype Webview2 -Dev_mode}   
              $synchash.WebPlayer_State = $result.value
            }
            if($synchash.WebPlayer_State -eq 1){ 
              $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
              if($Current_playlist_items.id){
                $queue_index = $Current_playlist_items.id.indexof($synchash.Current_playing_media.id)
                if($queue_index -ne -1){
                  $Current_playing = $Current_playlist_items[$queue_index]
                }else{
                  $Current_playing = $Current_playlist_items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
                }
              }
              if($Current_playing.FontWeight -ne 'Bold'){
                $Current_playing.FontWeight = 'Bold'
                $Current_playing.FontSize = '14' 
                $Current_playing.PlayIcon = 'CompactDiscSolid'
                #$current_playing.PlayIconRecord = "RecordRec"
                $Current_playing.NumberVisibility = 'Hidden'
                $Current_playing.NumberFontSize = 0
                $Current_playing.PlayIconRecordVisibility = 'Hidden'
                if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                  $Current_playing.PlayIconRepeat = 'Forever'
                  $Current_playing.PlayIconEnabled = $true
                }else{
                  write-ezlogs "| Performance_Mode enabled - Disabling playicon animation" -Warning -Dev_mode
                  $Current_playing.PlayIconRepeat = '1x'
                  $Current_playing.PlayIconEnabled = $false
                }                   
                $Current_playing.PlayIconVisibility = 'Visible'                
                if($synchash.PlayQueue_TreeView.itemssource){
                  $synchash.PlayQueue_TreeView.itemssource.refresh()
                }elseif($synchash.PlayQueue_TreeView.items){
                  $synchash.PlayQueue_TreeView.items.refresh()
                }
                try{
                  $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                  $synchash.Update_Playing_Playlist_Timer.start()             
                }catch{
                  Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                }
                if($synchash.PlayIcon1_Storyboard.Storyboard){
                  Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Resume
                }
                write-ezlogs ">>>> Spotify is playing - Current_playing: $($Current_playing | out-string)" -showtime
              }
            }elseif($synchash.WebPlayer_State -eq 2){
              $Current_playlist_items = $synchash.PlayQueue_TreeView.Items 
              if($Current_playlist_items.id){
                $queue_index = $Current_playlist_items.id.indexof($synchash.Current_playing_media.id)
                if($queue_index -ne -1){
                  $Current_playing = $Current_playlist_items[$queue_index]
                }else{
                  $Current_playing = $Current_playlist_items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
                }
              }
              if($Current_playing.PlayIconVisibility -eq 'Visible'){          
                $Current_playing.FontWeight = 'Bold'
                $Current_playing.FontSize = '14'
                #$current_playing.PlayIconRecord = "CompactDiscSolid"
                $Current_playing.NumberVisibility = 'Hidden'
                $Current_playing.NumberFontSize = 0
                $Current_playing.PlayIconRepeat = '1x' 
                #$current_playing.PlayIconRecordVisibility = "Visible"   
                $Current_playing.PlayIconVisibility = 'Hidden' 
                $Current_playing.PlayIconEnabled = $true  
                if($synchash.PlayQueue_TreeView.itemssource){
                  $synchash.PlayQueue_TreeView.itemssource.refresh()
                }elseif($synchash.PlayQueue_TreeView.items){
                  $synchash.PlayQueue_TreeView.items.refresh()
                }
                try{
                  $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                  $synchash.Update_Playing_Playlist_Timer.start()             
                }catch{
                  Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                }
                if($synchash.PlayIcon1_Storyboard.Storyboard){
                  Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Pause
                } 
                write-ezlogs ">>>> Spotify is paused - Current_playing: $($Current_playing | out-string)" -showtime
              }
            }
          }
          if($result.key -eq 'player_data'){
            Write-EZLogs "Web message received Player_data: $($result.value)" -showtime -logtype Webview2
            if($result.value.title -and $synchash.Now_Playing_Title_Label.DataContext -ne "$($result.value.title)"){
              Write-EZLogs "Updating Now Playing Spotify title with player_data title: $($result.value.title)" -showtime -logtype Webview2
              $synchash.Now_Playing_Title_Label.DataContext = "$($result.value.title)"
            }           
          } 
          if($result.key -eq 'video_data'){
            if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received video_data: $($result.value | Out-String)" -showtime -logtype Webview2 -Dev_mode}
            $synchash.Invidious_webplayer_current_Media = $result.value
          } 
          if($result.key -eq 'duration'){
            if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received duration: $($result.value | Out-String)" -showtime -logtype Webview2 -Dev_mode}
            $synchash.MediaPlayer_TotalDuration = $result.value
          }
          if($result.key -eq 'volume'){
            if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received volume: $($result.value | Out-String)" -showtime -logtype Webview2 -Dev_mode}
            $synchash.MediaPlayer_CurrentVolume = $result.value
          } 
          if($result.key -eq 'videodata'){
            $synchash.Youtube_webplayer_current_Media = $result.value
            #if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received videodata : $($result.value | out-string)" -showtime}
          }
          #if($result.key -eq 'videoUrl'){
          #if($thisApp.Config.Verbose_Logging){write-ezlogs "Web message received videoUrl : $($result.value | out-string)" -showtime -logtype Webview2}
          #} 
          if($result.key -eq 'error'){
            Write-EZLogs "Web message received error : $($result.value)" -showtime -warning -logtype Webview2
            if($result.value -eq '150'){
              Write-EZLogs 'Youtube ERROR 150, usually means this video is not allowed to be played outside of youtube.com, try using invidious instead' -showtime -warning -logtype Webview2
              Update-Notifications  -Level 'WARNING' -Message 'Youtube ERROR 150, usually means this video is not allowed to be played outside of youtube.com, try using invidious instead' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
            }elseif($result.value -eq '100'){
              Write-EZLogs 'Youtube ERROR 100: The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private' -showtime -warning -logtype Webview2
              Update-Notifications  -Level 'WARNING' -Message 'Youtube ERROR 100: The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
            }elseif($result.value -eq '5'){
              Write-EZLogs 'Youtube ERROR 5: The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred' -showtime -warning -logtype Webview2
              Update-Notifications  -Level 'WARNING' -Message 'Youtube ERROR 5: The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
            }elseif($result.value -eq '2'){
              Write-EZLogs 'Youtube ERROR 2: The request contains an invalid parameter value. For example, this error occurs if you specify a video ID that does not have 11 characters, or if the video ID contains invalid characters, such as exclamation points or asterisks' -showtime -warning -logtype Webview2
              Update-Notifications  -Level 'WARNING' -Message 'Youtube ERROR 2: The request contains an invalid parameter value. For example, this error occurs if you specify a video ID that does not have 11 characters, or if the video ID contains invalid characters, such as exclamation points or asterisks' -VerboseLog -Message_color 'Orange' -thisApp $thisApp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
            }
          } 
          if($result.key -eq 'account_error'){
            Write-EZLogs "Spotify Web Player Account Error Received : $($result.value.message)" -showtime -warning -AlertUI -logtype Webview2
            $synchash.Stop_media_timer.start()
          }
          if($result.key -eq 'playbackended'){              
            if($synchash.Spotify_WebPlayer_State -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0 -and $synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer){
              if($thisApp.Config.Dev_mode){Write-EZLogs "Web message received playbackended: $($synchash.Spotify_WebPlayer_State.playbackstate | Out-String)" -showtime -Dev_mode -logtype Webview2}
              $synchash.Spotify_WebPlayer_State.playbackstate = 0
              Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
              $synchash.Spotify_WebPlayer = $null
              if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
                $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Stopped'
                $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
              }
              if($thisApp.config.Auto_Repeat){
                Write-EZLogs '| Auto_Repeat enabled, restarting current media' -showtime
                Start-SpotifyMedia -Media $synchash.Current_playing_media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
              }elseif($thisApp.config.Auto_Playback){
                Write-EZLogs '>>>> Skipping to next media' -showtime
                $peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($synchash.NextButton_Button)
                $invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
                $invokeProv.Invoke()
              }else{
                Write-EZLogs '>>>> Stopping all playback' -showtime
                Stop-Media -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp -UpdateQueue -StopMonitor
              }
              return
            }
          } 
          if($result.key -eq 'Spotify_state'){
            if($thisApp.Config.Verbose_Logging){Write-EZLogs "Web message received Spotify_state: $($result.value)" -showtime -logtype Webview2}
            $synchash.Spotify_WebPlayer_State = $result.value            
            if($synchash.Spotify_WebPlayer_State.current_track.name -and $synchash.Now_Playing_Title_Label.DataContext -ne "$($synchash.Spotify_WebPlayer_State.current_track.name)"){
              Write-EZLogs ">>>> Updating Now Playing title (from: $($synchash.Now_Playing_Title_Label.DataContext)) with Spotify track name: $($synchash.Spotify_WebPlayer_State.current_track.name)" -showtime -logtype Webview2
              $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.Spotify_WebPlayer_State.current_track.name)"
              Write-EZLogs " | Spotify current track artists: $($synchash.Spotify_WebPlayer_State.current_track.artists)" -Dev_mode -logtype Webview2
            }
            if($synchash.Spotify_WebPlayer_State.current_track.Artists.name -and $synchash.Now_Playing_Artist_Label.DataContext -ne "$($synchash.Spotify_WebPlayer_State.current_track.Artists.name)"){          
              Write-EZLogs ">>>> Updating Now Playing artist (from: $($synchash.Now_Playing_Artist_Label.DataContext)) with Spotify artist name: $($synchash.Spotify_WebPlayer_State.current_track.Artists.name)" -showtime -logtype Webview2
              $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.Spotify_WebPlayer_State.current_track.Artists.name)"
              #Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -value "$($synchash.Spotify_WebPlayer_State.current_track.Artists.name)"
            }
            if($synchash.Spotify_WebPlayer_State.duration){
              $synchash.MediaPlayer_TotalDuration = [timespan]::FromMilliseconds($synchash.Spotify_WebPlayer_State.duration).TotalSeconds
            }  
            if($synchash.Spotify_WebPlayer_State.newposition){
              $synchash.MediaPlayer_CurrentDuration = $synchash.Spotify_WebPlayer_State.newposition
            }
            $Current_playlist_items = $synchash.PlayQueue_TreeView.Items
            if($Current_playlist_items.id){
              $queue_index = $Current_playlist_items.id.indexof($synchash.Current_playing_media.id)
              if($queue_index -ne -1){
                $Current_playing = $Current_playlist_items[$queue_index]
              }else{
                $Current_playing = $Current_playlist_items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
              }
            }
            if($synchash.Spotify_WebPlayer_State.Paused){  
              if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
                $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Paused'
                $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
              } 
              if($synchash.PauseButton_ToggleButton){
                $synchash.PauseButton_ToggleButton.isChecked = $true
              } 
              if($synchash.MiniPlayButton_ToggleButton -and $synchash.MiniPlayButton_ToggleButton.Uid -ne 'IsPaused'){
                $synchash.MiniPlayButton_ToggleButton.uid = 'IsPaused'
              }                
              if($synchash.PlayButton_ToggleButton.Uid -ne 'IsPaused'){
                $synchash.PlayButton_ToggleButton.Uid = 'IsPaused'
              }
              if($synchash.PlayButton_ToggleButton.isChecked){
                $synchash.PlayButton_ToggleButton.isChecked = $false
              }
              if($synchash.PlayIcon1_Storyboard.Storyboard){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Pause
              }               
              if($synchash.PlayIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
                $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PlayIcon_PackIcon
              }
              if($Current_playing.PlayIconRepeat -eq 'Forever'){     
                $Current_playing.PlayIconVisibility = 'Visible'
                $Current_playing.PlayIconRepeat = '1x' 
                $Current_playing.PlayIconEnabled = $false  
                if($synchash.PlayQueue_TreeView.itemssource){
                  $synchash.PlayQueue_TreeView.itemssource.refresh()
                }elseif($synchash.PlayQueue_TreeView.items){
                  $synchash.PlayQueue_TreeView.items.refresh()
                }
                try{
                  $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                  $synchash.Update_Playing_Playlist_Timer.start()             
                }catch{
                  Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                }               
              }
              if($synchash.VideoView_Play_Icon){
                $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'
              }                          
            }else{
              if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
                $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
                $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
              }
              if($synchash.PauseButton_ToggleButton){
                $synchash.PauseButton_ToggleButton.isChecked = $false
              } 
              if($synchash.MiniPlayButton_ToggleButton.Uid -eq 'IsPaused'){
                $synchash.MiniPlayButton_ToggleButton.uid = $null
              }                
              if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
                $synchash.PlayButton_ToggleButton.Uid = $null
              }
              if($synchash.PlayButton_ToggleButton){
                $synchash.PlayButton_ToggleButton.isChecked = $true
              }
              if($synchash.PlayIcon1_Storyboard.Storyboard){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Resume
              }
              if($synchash.VideoView_Play_Icon -and $synchash.VideoView_Play_Icon.kind -ne 'PauseCircleOutline'){
                $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
              } 
              if($synchash.PauseIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
                $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PauseIcon_PackIcon
              }
              if($Current_playing){
                try{
                  if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode -and $Current_playing.PlayIconRepeat -eq '1x'){
                    $Current_playing.PlayIconRepeat = 'Forever' 
                    $Update = $true
                    if(!$Current_playing.PlayIconEnabled){
                      $Update = $true
                      $Current_playing.PlayIconEnabled = $true
                    }
                  }elseif($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){                     
                    if($Current_playing.PlayIconRepeat -eq 'Forever'){
                      write-ezlogs "| Performance_Mode enabled - Disabling playicon animation" -Warning -Dev_mode
                      $Update = $true
                      $Current_playing.PlayIconRepeat = '1x'
                    } 
                    if($Current_playing.PlayIconEnabled){
                      $Update = $true
                      $Current_playing.PlayIconEnabled = $false
                    }
                  }
                  if($Current_playing.PlayIconVisibility -and $Current_playing.PlayIconVisibility -ne 'Visible'){
                    $Update = $true
                    $Current_playing.PlayIconVisibility = 'Visible'
                  }
                  if($Update){                   
                    if($synchash.PlayQueue_TreeView.itemssource){
                      $synchash.PlayQueue_TreeView.itemssource.refresh()
                    }elseif($synchash.PlayQueue_TreeView.items){
                      $synchash.PlayQueue_TreeView.items.refresh()
                    }
                    $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
                    $synchash.Update_Playing_Playlist_Timer.start()    
                  }         
                }catch{
                  Write-EZLogs "An exception occurred updating properties for current_playing $($Current_playing | Out-String)" -showtime -catcherror $_
                }
              }
            }
          }
          if($result.key -eq 'Spotify_volume'){
            #write-ezlogs "Web message received Spotify_volume: $($result.value | out-string)" -showtime -logtype Webview2
            if($result.value -eq 0 -and !$synchash.MuteButton_ToggleButton.isChecked){
              Write-EZLogs ">>>> Spotify webplayer reports volume $($result.value) - checking mute button"
              $synchash.MuteButton_ToggleButton.isChecked = $true
              $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
            }elseif($result.value -ne 0 -and $synchash.MuteButton_ToggleButton.isChecked){
              Write-EZLogs ">>>> Spotify webplayer reports volume $($result.value) - unchecking mute button"
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
          if($result.key -eq 'SpotifyDeviceID'){
            #$synchash.Current_Spotify_Deviceid = $result.value
            if($synchash.Spotify_WebPlayer){
              Write-EZLogs "Web message received SpotifyDeviceID $($result.value)" -showtime -logtype Webview2
              $synchash.Spotify_WebPlayer.Deviceid = $result.value
              if($synchash.Spotify_WebPlayer.Deviceid -and $($synchash.Spotify_WebPlayer.Spotifytype) -and $($synchash.Spotify_WebPlayer.SpotifyId)){
                try{
                  Write-EZLogs ">>>> Starting spotify playback and web timer - Deviceid: $($synchash.Spotify_WebPlayer.Deviceid) - spotifyid: $($synchash.Spotify_WebPlayer.SpotifyId)" -showtime -logtype Webview2   
                  if(($synchash.vlc.IsPlaying -or $synchash.Vlc.state -match 'Paused') -and !$([string]$synchash.vlc.media.Mrl).StartsWith('dshow://')){
                    write-ezlogs "| Stopping current VLC playback of: $($synchash.vlc.media.Mrl)" -logtype Webview2
                    $synchash.VLC_IsPlaying_State = $false
                    $synchash.vlc.Stop()
                  }  
                  if($synchash.WebView2.CoreWebView2 -ne $null){
                    $Spotify_StartPlayback = @"
try{
  console.log('Executing Playback for Spotify device: $($synchash.Spotify_WebPlayer.Deviceid) - URL: spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)');
try {
  $.ajax({
   url: "https://api.spotify.com/v1/me/player/play?device_id=$($synchash.Spotify_WebPlayer.Deviceid)",
   type: "PUT",
   data: '{"uris": ["spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)"]}',
   beforeSend: function(xhr){xhr.setRequestHeader('Authorization', 'Bearer ' + '$($synchash.Spotify_WebPlayer.SpotifyToken)' );},
   success: function(data) { 
     console.log('Started Playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId) - deviceid: $($synchash.Spotify_WebPlayer.Deviceid)');
     console.log(data)
   }
  });
} catch (error) {
  console.error('An exception occurred attempting to start playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)', error);
}
  console.log('Setting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
  SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100));
} catch (error) {
  console.error('An exception occurred attempting to start playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)', error);
}

"@
                    Write-EZLogs "| Executing Spotify_StartScript_Webview2" -logtype Webview2 -loglevel 2
                    $synchash.WebView2.ExecuteScriptAsync(
                      $Spotify_StartPlayback
                    )
                  }else{
                    Write-EZLogs "| Executing Start-Playback" -logtype Webview2 -loglevel 2
                    $start_playback = Start-Playback -TrackUris "spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)" -ApplicationName $thisApp.config.App_Name -DeviceId:$synchash.Spotify_WebPlayer.Deviceid
                  }
                  Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -start
                  $synchash.Spotify_WebPlayer.is_started = $true
                }catch{
                  Write-EZLogs "An exception occurred executing start-playback for spotify uri: spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId) - Deviceid: $($synchash.Spotify_WebPlayer.Deviceid)" -showtime -catcherror $_
                }finally{
                  if(!$synchash.Spotify_WebPlayer.is_started){
                    Write-EZLogs 'It didnt start...maybe attempt again?' -showtime -warning -logtype Webview2
                    $start_playback = Start-Playback -TrackUris "spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)" -ApplicationName $thisApp.config.App_Name -DeviceId:$synchash.Spotify_WebPlayer.Deviceid 
                    <#                    $startSpotifyPlayback_Scriptblock = {
                        $start_playback = Start-Playback -TrackUris "spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)" -ApplicationName $thisApp.config.App_Name -DeviceId:$synchash.Spotify_WebPlayer.Deviceid
                        }
                        $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}} 
                    Start-Runspace -scriptblock $startSpotifyPlayback_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Start_SpotifyPlayback_RUNSPACE' -thisApp $thisApp -synchash $synchash -ApartmentState STA -CheckforExisting #>     
                  }
                }
              }else{
                Write-EZLogs "Not doing anything with received SpotifyDeviceID - Spotify_WebPlayer: $($synchash.Spotify_WebPlayer | out-string)" -showtime -logtype Webview2 -warning
              }
            }else{
              Write-EZLogs 'Unable to find synchash.Spotify_WebPlayer hashtable!' -warning -logtype Webview2 
            }
          }                                                                               
        }   
      }catch{
        Write-EZLogs 'An exception occurred in Webview2 WebMessageReceived event' -showtime -catcherror $_
      }
    }
  }
  $synchash.WebView2.Remove_WebMessageReceived($synchash.SpotifyWebview2_WebMessageReceived)
  $synchash.WebView2.add_WebMessageReceived($synchash.SpotifyWebview2_WebMessageReceived)
}
#---------------------------------------------- 
#endregion Initialize-WebPlayer Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebBrowser Function
#----------------------------------------------
Function Initialize-WebBrowser
{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    $thisScript,
    [switch]$dev_mode
  ) 
  try{
    $Initialize_WebBrowser_Measure = [system.diagnostics.stopwatch]::StartNew()
    if($synchash.WebBrowserGrid.Children -contains $synchash.WebBrowser){
      $null = $synchash.WebBrowserGrid.Children.Remove($synchash.WebBrowser)
    }
    if($synchash.WebBrowserGrid.Children -contains $synchash.Bookmarks_FlyoutControl){
      $null = $synchash.WebBrowserGrid.Children.Remove($synchash.Bookmarks_FlyoutControl)
    }
    if(!$synchash.WebView2_VisibleChange_Command){
      $synchash.WebView2_VisibleChange_Command = {
        param($sender,[System.Windows.DependencyPropertyChangedEventArgs]$e)
        try{
          Write-EZLogs ">>>> Visibility changed for: $($sender.name) -- Visibility: $($sender.visibility) -- NewValue: $($e.NewValue) -- CoreWebview2.IsSuspended: $($synchash."$($sender.name)".CoreWebview2.IsSuspended)" -logtype Webview2
          if($sender.name -eq 'WebBrowser' -and ($sender.visibility -eq 'Visible' -or $e.NewValue -eq $true) -and $synchash."$($sender.name)".CoreWebview2.IsSuspended){
            Write-EZLogs "| $($sender.name) is now visible and is currently suspended, executing Resume()" -logtype Webview2
            $synchash."$($sender.name)".CoreWebview2.Resume()
          }
        }catch{
          Write-EZLogs 'An exception has occurred in WebView2_VisibleChange_Command' -catcherror $_
        }
      }
    }
   
    if(!$synchash.WebBrowser -or !$synchash.WebBrowser.CoreWebView2){
      Write-EZLogs '#### Creating new WebBrowser instance' -showtime -logtype Webview2 -linesbefore 1
      $synchash.WebBrowser = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
      $synchash.WebBrowser.Visibility = 'Visible'
      $synchash.WebBrowser.Name = 'WebBrowser'
      $synchash.WebBrowser.DefaultBackgroundColor = [System.Drawing.Color]::Transparent
      $synchash.WebBrowser.Remove_IsVisibleChanged($synchash.WebView2_VisibleChange_Command)
      $synchash.WebBrowser.Add_IsVisibleChanged($synchash.WebView2_VisibleChange_Command)
    }
    if($synchash.WebBrowserGrid.Children -contains $synchash.AirControl){
      Write-EZLogs ' | Removing Aircontrol from WebBrowserGrid' -loglevel 2 -logtype Webview2
      [void]$synchash.WebBrowserGrid.children.Remove($synchash.AirControl)
      $synchash.AirControl.Front = $null
      $synchash.AirControl.Back = $null
      $synchash.AirControl = $null
    }
    if($synchash.Bookmarks_FlyoutControl -and !$synchash.AirControl){
      if($thisApp.Config.Dev_mode){Write-EZLogs '>>>> Creating new Airhack control for Bookmarks_FlyoutControl (front) and WebBrowser (Back)' -showtime -dev_mode -logtype Webview2}
      $synchash.AirControl = [airhack.aircontrol]::new()
      $synchash.AirControl.MinHeight = 1
      $synchash.AirControl.MinWidth = 1
      [void]$synchash.AirControl.SetValue([System.Windows.Controls.Grid]::RowProperty,1)
      $synchash.AirControl.Front = $synchash.Bookmarks_FlyoutControl
      $synchash.AirControl.Back = $synchash.WebBrowser
      if($synchash.WebBrowserGrid.Children -notcontains $synchash.AirControl){
        [void]$synchash.WebBrowserGrid.addChild($synchash.AirControl)
      }
    }
    if($synchash.WebView2Env.IsCompleted -and $synchash.WebBrowser.CoreWebView2){
      Write-EZLogs ">>>> WebView2Env already initialized: $($synchash.WebView2Env.Result)" -showtime -logtype Webview2
      $synchash.WebBrowser.EnsureCoreWebView2Async($synchash.WebView2Env.Result)
    }else{
      Write-EZLogs '>>>> Initializing new WebView2Env' -showtime -logtype Webview2
      $synchash.WebBrowserOptions = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
      $synchash.WebBrowserOptions.IsCustomCrashReportingEnabled = $true

      #Extensions
      if(-not [string]::IsNullOrEmpty($synchash.WebBrowserOptions.AreBrowserExtensionsEnabled)){
        Write-EZLogs '>>>> Enabling browser extension support for WebBrowser' -logtype Webview2
        Get-Webview2Extensions -thisApp $thisApp
        $synchash.WebBrowserOptions.AreBrowserExtensionsEnabled = $true
        $synchash.WebBrowser.CreationProperties = [Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties]::new()
        $synchash.WebBrowser.CreationProperties.AreBrowserExtensionsEnabled = $true
        if($thisApp.Config.Dev_mode){Write-EZLogs " | WebBrowser CreationProperties: $($synchash.WebBrowser.CreationProperties | Out-String)" -logtype Webview2 -Dev_mode}
      }
      #--edge-webview-enable-builtin-background-extensions 
      $synchash.WebBrowserOptions.AdditionalBrowserArguments = '--autoplay-policy=no-user-gesture-required --Disable-features=HardwareMediaKeyHandling,OverscrollHistoryNavigation,msExperimentalScrolling'
      $synchash.WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
        [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.WebBrowserOptions
      )
      $synchash.WebView2Env.GetAwaiter().OnCompleted(
        [Action]{
          $synchash.WebBrowser.EnsureCoreWebView2Async($synchash.WebView2Env.Result)
        }
      )
    }
  }catch{
    Write-EZLogs 'An exception occurred creating WebBrowser Enviroment' -showtime -catcherror $_
  }
  try{
    $synchash.WebBrowser_NavigationCompleted_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
      param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]$e)
      $synchash = $synchash
      $thisApp = $thisApp
      try{
        Write-EZLogs ">>>> WebBrowser Navigation completed -- Sender: $($sender.Name) -- Source: $($sender.source)" -showtime -logtype Webview2
        if($e.IsSuccess){
          $url = $sender.source        
          if($url -match 'youtube\.com|youtu\.be' -and $url -notmatch 'accounts\.google\.com'){
            $synchash.WebBrowser_Youtube_URL = $sender.source
            $Youtube = Get-YoutubeUrl -thisApp $thisApp -URL $url
            Write-EZLogs " | Youtube page $($synchash.WebBrowser_Youtube_URL)" -loglevel 2 -logtype Webview2
          }
          if($Youtube.id -and $url -notmatch 'tv\.youtube\.com' -and $url -notmatch 'accounts\.google\.com'){
            Write-EZLogs " | Youtube id: $($Youtube.id)" -loglevel 2 -logtype Webview2 
            if($thisApp.Config.Enable_Sponsorblock -and $thisApp.Config.Sponsorblock_ActionType){
              $thisApp.SponsorBlock = Get-SponsorBlock -videoId $Youtube.id -actionType $thisApp.Config.Sponsorblock_ActionType
            }else{
              $thisApp.SponsorBlock = $null
            }
            try{
              $req = [System.Net.HTTPWebRequest]::Create("https://returnyoutubedislikeapi.com/votes?videoId=$($Youtube.id)")
              $req.Method = 'GET'         
              $req.Timeout = 5000    
              $response = $req.GetResponse()
              $strm = $response.GetResponseStream()
              $sr = [System.IO.Streamreader]::new($strm)
              $output = $sr.ReadToEnd()
              $youtube_ds = $output | ConvertFrom-Json   
              $response.Dispose()
              $strm.Dispose()
              $sr.Dispose()
            }catch{
              Write-EZLogs "An exception occurred getting youtube dislikes with url: https://returnyoutubedislikeapi.com/votes?videoId=$($Youtube.id)" -catcherror $_
              $error.clear()
            }finally{
              if($response){
                $response.Dispose()
              }
              if($strm){
                $strm.Dispose()
              }
              if($sr){
                $sr.Dispose()
              }   
              $req = $null          
            }
            if($youtube_ds.dislikes){
              $DisLikes = $($youtube_ds.dislikes -as [decimal]).ToString('N0')
            }
            if($youtube_ds.likes){
              $Likes = $($youtube_ds.likes -as [decimal]).ToString('N0')
            }
            if($synchash.Likes_Total -and $synchash.DisLikes_Total){
              if($youtube_ds){
                $synchash.Likes_Total.Visibility = 'Visible'
                $synchash.Likes_Total.text = $Likes
                $synchash.DisLikes_Total.text = $DisLikes
              }else{
                $synchash.Likes_Total.Visibility = 'Collapsed'
                $synchash.Likes_Total.text = ''
                $synchash.DisLikes_Total.text = ''
              }
            }
            $WebBrowser_Script = @"
  console.log('Youtube Dislikes: $($DisLikes)');
  var IsDisLikeSet = false;
  var dsbutton = document.getElementById("segmented-dislike-button")
  if(dsbutton && !dsbutton.children[0].children[0].children[0].innerText){
   dsbutton.children[0].children[0].children[0].append('  ',$($DisLikes))
  }else{
   var dsbutton = document.getElementById("menu-container")?.querySelector("#top-level-buttons-computed");
   dsbutton.children[1].querySelector("#text").innerText = $($DisLikes);
  }
"@  
          } 
          $synchash.WebBrowser_Script = @"

 var player = document.getElementById('movie_player');
 console.log('Loading the YT IFrame Player', player);

var YTTV = false;
          try {
            //var AdblockApplied = false;   
            //var adblockresult = runBlockYoutube();
            //if(adblockresult.success){
              //AdblockApplied = adblockresult.success;
            //}
            //console.log('Adblock Execution Result:',adblockresult.message);
          } catch (e) {
            console.log('Exception occurred executing adblocking',e);
          }
if(player){
function onYouTubePlayerStateChange(event) {
    console.log('Player State Changed ', event); 
    if(event == 1){
     var oldquality = player.getPlaybackQuality();
     console.log('Old Quality:', oldquality);
     const levels = player.getAvailableQualityLevels();
     let quality = JSON.parse(
            localStorage.getItem('yt-player-quality')
    );
    if('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'Auto'.toLowerCase()){
      quality = levels.find(function(levels) {
        return levels === "auto"
      });
    }else if('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'medium'.toLowerCase()){
      quality = levels.find(function(levels) {
        return levels === "medium"
      });
    }else if('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'low'.toLowerCase()){
       quality = levels.find(function(levels) {
          return levels === "small"
        });
    }else if('$($thisApp.config.Youtube_Quality)'.toLowerCase() === 'Best'.toLowerCase()){
       quality = levels[0];
    }

     if (!levels.includes(quality)) {
           quality = levels[0];
      }
      //console.log('Setting Quality to', quality);
      player.setPlaybackQualityRange(quality, quality);
      var newquality = player.getPlaybackQualityLabel();
      if(newquality){
        var currentquality =
        {
          Key: 'currentquality',
          Value: newquality
        };
        window.chrome.webview.postMessage(currentquality);
      }     
      console.log('New Quality:', newquality);
    } 
      var fullscreen_button = document.getElementsByClassName("ytp-fullscreen-button");
      var YTTV_fullscreen_button = document.getElementsByClassName("yib-button style-scope ytu-icon-button");
        if(fullscreen_button.length > 0){
         console.log('Setting Fullscreen button click event',fullscreen_button[0]);
         fullscreen_button[0].addEventListener("click", function(event) {
          console.log('FullScreen Button Clicked');
          var fullscreenbuttonObject =
          {
            Key: 'fullscreenbutton',
            Value: event 
          };
          window.chrome.webview.postMessage(fullscreenbuttonObject);
     });
        }
      
      if(YTTV_fullscreen_button[23].ariaLabel == 'Full screen (f)' && !YTTV){
       YTTV = true;
       console.log('Setting YTTV Fullscreen button click event',YTTV_fullscreen_button[23]);
       YTTV_fullscreen_button[23].addEventListener("click", function(event) {
        console.log('YT FullScreen Button Clicked');
        var fullscreenbuttonObject =
        {
          Key: 'fullscreenbutton',
          Value: event 
        };
        window.chrome.webview.postMessage(fullscreenbuttonObject);
   });
      }else{      

      }
          try {
            //var adblockresult = runBlockYoutube();
            //if(adblockresult.success){
            //  AdblockApplied = adblockresult.success;
            //}
            //console.log('Adblock Execution Result:',adblockresult.message);
          } catch (e) {
            console.log('Exception occurred executing adblocking',e);
          }
}

function onYoutubePlayerReady(event) {
  console.log('Player is Ready');
  player.playVideo();
  var quality = player.getAvailableQualityLevels();
  player.setPlaybackQuality(quality[0]);

}

function onYoutubePlayerfullscreenchange(event) {
  console.log('Player fullscreen change');
  console.log(event);
  var fullscreenObject =
  {
    Key: 'fullscreenchange',
    Value: event 
  };
  window.chrome.webview.postMessage(fullscreenObject);
}

function onYoutubevolumechange(event) {
  var volume = player.getVolume();
  console.log('Volume changed to',volume);
  var volumeObject =
  {
    Key: 'volume',
    Value: volume 
  };
  window.chrome.webview.postMessage(volumeObject);
}


function onYouTubeError(event) {
  console.log('Youtube ERROR:', event);
  console.log(event);
  var ErrorObject =
  {
    Key: 'error',
    Value: event 
  };
  window.chrome.webview.postMessage(ErrorObject);
}

  player.addEventListener("OnReady", onYoutubePlayerReady);
  player.addEventListener("onStateChange", onYouTubePlayerStateChange);
  player.addEventListener("onfullscreenchange", onYoutubePlayerfullscreenchange);
  player.addEventListener("onError", onYouTubeError);
  player.addEventListener("onvolumechange", onYoutubevolumechange);
  player.setVolume($($synchash.Volume_Slider.Value));

function getChangedVolume () {
  //let currentYoutubeVolume = this.player.getVolume();
  //console.log(currentYoutubeVolume);

  // YouTube returns Promise, but we need actual data, so:
  //Promise.resolve(currentYoutubeVolume).then(data => { this.volumeLv = data });
  var volume = player.getVolume();
  //console.log('Volume is',volume);
  var volumeObject =
  {
    Key: 'volume',
    Value: volume 
  };
  window.chrome.webview.postMessage(volumeObject);

  };
  setInterval(this.getChangedVolume, 500);

  var state = player.getPlayerState();
  var videodata = player.getVideoData();
  if(videodata){
    var videodataObject =
    {
      Key: 'videodata',
      Value: videodata 
    };
    window.chrome.webview.postMessage(videodataObject);
  }
  var videoUrl = player.getVideoUrl();
  var time = player.getCurrentTime();
  var duration = player.getDuration();
  var volume = player.getVolume();
  var isMuted = player.isMuted();
    var Playerlabel = document.getElementById('id-player-main');
    if(Playerlabel){
      var PlayerlabelObject =
      {
        Key: 'Playerlabel',
        Value: Playerlabel.ariaLabel
      };
      window.chrome.webview.postMessage(PlayerlabelObject);
    }
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
  var videoUrlObject =
  {
    Key: 'videoUrl',
    Value: videoUrl
  };
  var MuteStatus =
  {
    Key: 'MuteStatus',
    Value: isMuted
  };


    window.chrome.webview.postMessage(MuteStatus);
    window.chrome.webview.postMessage(timeJson);  
    window.chrome.webview.postMessage(jsonObject);
    window.chrome.webview.postMessage(durationObject);
    //window.chrome.webview.postMessage(volumeObject);   
    window.chrome.webview.postMessage(videoUrlObject);
}else{      
var player = videojs.getAllPlayers()[0];
if(player){
  var source = player.currentSource();
  console.log('>>>> Found videojs player',source.src);
  var videojsplayer =
  {
    Key: 'videojsplayer',
    Value: source
  };
   window.chrome.webview.postMessage(videojsplayer);
}

}

"@ 
          if($sender.source -notmatch 'accounts\.google\.com' -and ($sender.source -match 'youtube\.com' -or $sender.source -match 'youtu\.be')){
            $WebBrowser_Youtube_returnDislike_Script = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Youtube\Return Youtube Dislike.user.js")
            Write-EZLogs '>>>> Executing Return Youtube Dislike scripts' -loglevel 2 -logtype Webview2
            $sender.ExecuteScriptAsync(
              $WebBrowser_Youtube_returnDislike_Script
            )
            $YT_ADblockScript = "$($thisApp.Config.Current_Folder)\Resources\Ad Blocking\Youtube_ADBlock2.js"
            if([system.io.file]::Exists($YT_ADblockScript)){
              if(!$synchash.YoutubeWebView2_Adblock_Script -or $thisApp.Config.Dev_mode){
                $synchash.YoutubeWebView2_Adblock_Script = [system.io.file]::ReadAllText($YT_ADblockScript)
              }
              Write-EZLogs '>>>> Injecting custom Youtube Adblock script' -logtype Webview2
              $sender.ExecuteScriptAsync(
                $synchash.YoutubeWebView2_Adblock_Script
              )
            }
          }
          if($youtube_ds.dislikes){
            Write-EZLogs " | Youtube dislikes: $($youtube_ds.dislikes)" -logtype Webview2
            $sender.ExecuteScriptAsync(
              $WebBrowser_Script
            )
          }

          #Handle new window requests
          if($sender.Name -match "WebBrowser_Webview2_$($synchash.WebBrowser_tabs)" -and $synchash.WebBrowser2_NewWindowEvent){
            Write-EZLogs ">>>> This is a new tab, setting NewWindow - Name: $($sender.Name)" -loglevel 2 -logtype Webview2
            if($synchash.WebBrowser2_NewWindowEvent.uri -match 'chrome-extension\:'){
              Write-EZLogs "| Requested window is extension: $($synchash.WebBrowser2_NewWindowEvent.uri)" -loglevel 2 -logtype Webview2
            }else{
              $synchash.WebBrowser2_NewWindowEvent.NewWindow = $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".CoreWebView2 
            }          
            $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".title = $sender.CoreWebview2.DocumentTitle
            $synchash.WebBrowser2_Deferral.Complete()
            $synchash.WebBrowser2_NewWindowEvent = $null
            $synchash.WebBrowser2_Deferral = $null
          }elseif($sender.Name -match 'WebBrowser_Webview2_' -and $synchash.WebBrowser2_NewWindowEvent){
            Write-EZLogs ">>>> This is a new tab, setting NewWindow - Name: $($sender.Name)" -loglevel 2 -logtype Webview2
            if($synchash.WebBrowser2_NewWindowEvent.uri -match 'chrome-extension\:'){
              Write-EZLogs "| Requested window is extension: $($synchash.WebBrowser2_NewWindowEvent.uri)" -loglevel 2 -logtype Webview2
            }else{
              $synchash.WebBrowser2_NewWindowEvent.NewWindow = $synchash."$($sender.Name)".CoreWebView2 
            }  
            if('title' -in $synchash."$($sender.Name)".psobject.properties.name){
              $synchash."$($sender.Name)".title = $sender.CoreWebview2.DocumentTitle
            }            
            $synchash.WebBrowser2_Deferral.Complete()
            $synchash.WebBrowser2_NewWindowEvent = $null
            $synchash.WebBrowser2_Deferral = $null
          }elseif($sender.Name -eq 'Webbrowser' -and $synchash.WebBrowserAnchorable -and $synchash.WebBrowserAnchorable.Title -ne "Web Browser - $($synchash.Webbrowser.CoreWebview2.DocumentTitle)"){
            $synchash.WebBrowserAnchorable.Title = "Web Browser - $($synchash.Webbrowser.CoreWebview2.DocumentTitle)"
          }
          $sender.ExecuteScriptAsync(
            $synchash.WebBrowser_Script
          )   
          if($sender.source -match 'twitch\.tv'){
            if(!$synchash.Chat_Twitch_Emotes_Script){
              $synchash.Chat_Twitch_Emotes_Script = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Twitch\twitch-bttv.js")  
            }              
            Write-EZLogs '>>>> Executing Chat_Twitch_BTTV_Script' -showtime -logtype Webview2
            $sender.ExecuteScriptAsync(
              $synchash.Chat_Twitch_Emotes_Script
            )  
          }
        }else{
          Write-EZLogs "Navigation to source $($sender.source) was not successful -- HttpStatusCode: $($e.HttpStatusCode) -- WebErrorStatus: $($e.WebErrorStatus)" -logtype Webview2 -warning
        }    
      }catch{
        Write-EZLogs 'An exception occurred in WebBrowser_NavigationCompleted_Scriptblock' -catcherror $_
      }
    }
    $synchash.WebBrowser.Remove_NavigationCompleted(
      $synchash.WebBrowser_NavigationCompleted_Scriptblock
    )
    $synchash.WebBrowser.Add_NavigationCompleted(
      $synchash.WebBrowser_NavigationCompleted_Scriptblock
    ) 
  
    $synchash.WebBrowser_NavigationStarting_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationStartingEventArgs]]{
      param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationStartingEventArgs]$e)
      try{
        Write-EZLogs ">>>> WebBrowser Navigation started -- Sender: $($sender.Name) -- Requested URI: $($e.Uri) -- Current Source: $($sender.source) -- NavigationKind: $($e.NavigationKind)" -showtime -linesbefore 1 -logtype Webview2
      }catch{
        Write-EZLogs 'An exception occurred in WebBrowser_NavigationStarting_Scriptblock' -catcherror $_
      }
    }
    $synchash.WebBrowser.Remove_NavigationStarting($synchash.WebBrowser_NavigationStarting_Scriptblock)
    $synchash.WebBrowser.Add_NavigationStarting($synchash.WebBrowser_NavigationStarting_Scriptblock)
    $synchash.WebBrowser_tabs = 0
    $synchash.WebBrowser.Add_CoreWebView2InitializationCompleted(
      [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
        Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]$event)
        $synchash = $synchash
        if($event.IsSuccess){ 
          try{
            Write-EZLogs '>>>> WebBrowserWebView2 CoreWebView2InitializationCompleted' -showtime -LogLevel 2 -logtype Webview2
            $synchash.WebBrowser.CoreWebView2.add_ProcessFailed({
                Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2ProcessFailedEventArgs]$e)
                try{
                  Write-EZLogs "Webbrowser ProcessFailed - URI: $($e.Uri) - ProcessFailedKind: $($args.ProcessFailedKind) - Reason: $($args.reason) - ExitCode: $($args.exitcode)" -isError -AlertUI
                  Write-EZLogs "Webview2.CoreWebView2: $($synchash.WebBrowser.CoreWebView2 | Out-String)" -Dev_mode
                }catch{
                  Write-EZLogs 'An exception occurred in Webview2.CoreWebView2.add_ProcessFailed' -catcherror $_
                }
            }) 
            $synchash.WebBrowser.CoreWebView2.add_NewWindowRequested(
              [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NewWindowRequestedEventArgs]]{
                Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NewWindowRequestedEventArgs]$event)           
                $synchash = $synchash
                try{
                  Write-EZLogs "[WebBrowser] New Window Requested - event.IsSuccess: $($event.IsSuccess)" -loglevel 2 -logtype Webview2   
                  if($synchash.DockingDocumentPane.children -notcontains $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)" -and $event.IsUserInitiated){
                    #if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)"){                  
                    try{
                      $synchash.WebBrowser_tabs++   
                      $event.handled = $true
                      [Microsoft.Web.WebView2.Core.CoreWebView2Deferral]$Deferral = $event.GetDeferral()
                      $synchash.WebBrowser2_NewWindowEvent = $event  
                      $synchash.WebBrowser2_Deferral = $Deferral   
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)" = [AvalonDock.Layout.LayoutAnchorable]::new()
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".IconSource = $synchash.WebBrowserAnchorable.IconSource
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".ContentId = "WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)"
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".title = "WebBrowser($($synchash.WebBrowser_tabs))"
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanClose = $true
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanFloat = $true
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanMove = $true
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanHide = $false
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanAutoHide = $false
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".CanShowOnHover = $true
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".add_closed({
                          param($sender)
                          try{
                            Write-EZLogs ">>>> $($sender.ContentId) has closed" -loglevel 2 -logtype Webview2
                            if($thisApp.Config.Dev_mode){Write-EZLogs ">>>> $($sender.ContentId) args: $($args[1] | Out-String)" -loglevel 2 -logtype Webview2 -Dev_mode}
                            $WebView2 = $($sender.ContentId) -replace 'TabWindow', 'Webview2'
                            if($synchash."$WebView2".isVisible -eq $false){
                              Write-EZLogs " | Disposing Webview2 instance $($WebView2)" -loglevel 2 -logtype Webview2
                              $synchash."$WebView2".dispose()
                              $synchash."$WebView2" = $null
                              Write-EZLogs ' | Webview2 instance disposed' -loglevel 2 -logtype Webview2 -GetMemoryUsage
                            }
                          }catch{
                            Write-EZLogs "An exception occurred in WebBrowser_TabWindow_$($synchash.WebBrowser_tabs) closed event" -catcherror $_
                          }
                      })
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".add_FloatingPropertiesUpdated($synchash.FloatingPropertiesUpdated_Command)
                      #$synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)" = [MahApps.Metro.Controls.MetroTabItem]::new()
                      #$synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".Header = "WebBrowser_$($synchash.WebBrowser_tabs)"
                      #$synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".Name = "WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)"
                      if(!$synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)" -or !$synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)"){
                        Write-EZLogs '>>>> Creating new WebBrowser2_Webview instance' -showtime -logtype Webview2
                        $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)" = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
                      }
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".Visibility = 'Visible'
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".Name = "WebBrowser_Webview2_$($synchash.WebBrowser_tabs)"
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".DefaultBackgroundColor = [System.Drawing.Color]::Transparent
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)_env" = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
                        [String]::Empty, [IO.Path]::Combine([String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.WebBrowserOptions
                      )
                      if(!$synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".CoreWebView2){
                        $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)_env".GetAwaiter().OnCompleted(
                          [Action]{
                            Write-EZLogs ">>>> Executing WebBrowser_Webview2_$($synchash.WebBrowser_tabs)_env EnsureCoreWebView2Async" -showtime -logtype Webview2
                            $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".EnsureCoreWebView2Async( $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)_env".Result )     
                          }
                        )
                      }
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".Add_NavigationCompleted(
                        $synchash.WebBrowser_NavigationCompleted_Scriptblock
                      )
                      $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".Add_CoreWebView2InitializationCompleted(
                        [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
                          $event2 = $args[1]
                          Write-EZLogs "[WebBrowser_Webview2_$($synchash.WebBrowser_tabs)] Navigation to $(($synchash.WebBrowser2_NewWindowEvent.Uri))" -loglevel 2 -logtype Webview2
                          $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)".CoreWebView2.Navigate($synchash.WebBrowser2_NewWindowEvent.Uri)
                      })
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".content = $synchash."WebBrowser_Webview2_$($synchash.WebBrowser_tabs)"
                      #DockingDocumentPane
                      $null = $synchash.DockingDocumentPane.children.Add($synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)")
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".float()
                      #$synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".DockAsDocument()
                      #$Null = $syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)")  
                      #$synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".isSelected = $true
                      $synchash."WebBrowser_TabWindow_$($synchash.WebBrowser_tabs)".show()
                    }catch{
                      Write-EZLogs 'An exception occurred creating WebBrowser2_Webview Enviroment' -showtime -catcherror $_
                    }            
                  }
                }catch{
                  Write-EZLogs 'An exception occurred in webbrowser webview2 newwindowrequested event' -CatchError $_
                }
            })
            [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.WebBrowser.CoreWebView2.Settings
            $Settings.AreDefaultContextMenusEnabled  = $true
            $Settings.AreDefaultScriptDialogsEnabled = $true
            $Settings.AreDevToolsEnabled             = $true
            $Settings.AreHostObjectsAllowed          = $true
            $Settings.IsBuiltInErrorPageEnabled      = $false
            $Settings.IsScriptEnabled                = $true
            $Settings.IsStatusBarEnabled             = $true
            $Settings.IsWebMessageEnabled            = $true
            $Settings.IsZoomControlEnabled           = $true
            $Settings.IsGeneralAutofillEnabled       = $false
            $Settings.IsPasswordAutosaveEnabled      = $false
            $Settings.AreBrowserAcceleratorKeysEnabled = $true
            $Settings.IsSwipeNavigationEnabled = $false
            $isYoutube = $true
            if($synchash.txtUrl.text -match 'youtube\.com' -or $synchash.txtUrl.text -match 'youtu\.be' -or $synchash.txtUrl.text -match 'google\.com'){
              $isYoutube = $true
            }                  
            $synchash.WebBrowser.CoreWebView2.AddWebResourceRequestedFilter('*', [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All)    
            if($thisApp.Config.WebBrowser_PrivateMode){
              Write-EZLogs '[WebBrowser] | Enabling private mode for WebBrowser' -showtime -logtype Webview2
              $synchash.WebBrowser.CoreWebView2.Profile.IsInPrivateModeEnabled = $true
            }
            if($synchash.WebBrowser.CoreWebView2.Profile.IsInPrivateModeEnabled){
              Write-EZLogs '[WebBrowser] | WebBrowser is currently in private mode' -showtime -logtype Webview2 -warning
            }                      
            if($thisApp.Config.Chat_WebView2_Cookie -and $synchash.txtUrl.text -match 'twitch\.tv'){           
              Write-EZLogs "[WebBrowser] | Adding Twitch chat Cookie" -showtime -logtype Webview2 -Dev_mode
              $twilight_user_cookie = $synchash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('twilight-user', $thisApp.Config.Chat_WebView2_Cookie, '.twitch.tv', '/')
              $twilight_user_cookie.IsSecure = $true
              $synchash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($twilight_user_cookie)    
            } 
            #If saved cookies exist, add them to Webview2  
            if($isYoutube){
              foreach($cookie in $thisApp.Config.Youtube_Cookies){
                if(($cookie.cookiedurldomain -eq '.youtube.com' -or $cookie.cookiedurldomain -eq '.google.com') -and $cookie.name -in 'PREF', '__Secure-1PSID', '__Secure-3PAPISID', 'LOGIN_INFO', '__Secure-1PAPISID', 'OptanonAlertBoxClosed' -and -not [string]::IsNullOrEmpty($cookie.value)){
                  Write-EZLogs "[WebBrowser] | Adding domain $($cookie.cookiedurldomain) cookie $($cookie.name)" -showtime -logtype Webview2 -Dev_mode
                  try{
                    $Youtube_cookie = $synchash.WebBrowser.CoreWebView2.CookieManager.CreateCookie($cookie.name, $($cookie.value), '.youtube.com', '/')
                    $Youtube_cookie.IsSecure = $cookie.isSecure
                    $synchash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($Youtube_cookie) 
                  }catch{
                    Write-EZLogs "[WebBrowser] An exception occurred adding youtube cookie $($cookie | Out-String)" -catcherror $_
                  }finally{
                    $Youtube_cookie = $null
                  }  
                }                
              }
            }                                           
          }catch{
            Write-EZLogs '[WebBrowser] An exception occurred in CoreWebView2InitializationCompleted Event' -showtime -catcherror $_
          } 
          $synchash.WebBrowser.CoreWebView2.add_WebResourceRequested({
              Param($Sender,[Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e)
              try{
                $Cookies = ($e.Request.Headers | Where-Object {$_.key -eq 'cookie'}).value
                if($synchash.WebBrowser.Source -match 'spotify\.com'){
                  $cookiedurldomain = '.spotify.com'                
                }elseif($synchash.WebBrowser.Source -match 'google\.com'){
                  $cookiedurldomain = '.google.com'
                }elseif($synchash.WebBrowser.Source -match 'youtube\.com' -or $synchash.WebBrowser.Source -match 'youtu\.be'){
                  $cookiedurldomain = '.youtube.com'
                }
                if($Cookies){
                  if($thisApp.Config.Dev_mode -and $Cookies -notmatch 'OptanonAlertBoxClosed'){    
                    Write-EZLogs ">>>> Adding WebBrowser OptanonAlertBoxClosed cookie for URL domain: $($cookiedurldomain)" -logtype Webview2
                    $OptanonAlertBoxClosed = $synchash.WebBrowser.CoreWebView2.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-Date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), $cookiedurldomain, '/')
                    $Null = $synchash.WebBrowser.CoreWebView2.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed) 
                  }               
                  $Cookies = $Cookies -split ';' 
                  foreach($cookie in $Cookies){
                    try{
                      if($cookiedurldomain -eq '.youtube.com' -or $cookiedurldomain -eq '.google.com'){
                        if($cookie -match '(?<value>.*)=(?<value>.*)'){
                          $cookiename = $($cookie -split '=')[0]
                          if($cookiename){
                            $cookiename = $cookiename.trim()
                          }
                          $cookievalue = ([regex]::matches($cookie, "$cookiename=(?<value>.*)") | & { process {$_.groups[1].value}}) 
                        } 
                        switch ($cookiename){
                          'SIDCC' {
                            $isSecure = $false
                          } 
                          'SID' {
                            $isSecure = $false
                          }
                          'OptanonAlertBoxClosed' {
                            $isSecure = $false
                          }
                          'HSID' {
                            $isSecure = $false
                          }
                          'APISID' {
                            $isSecure = $false
                          }
                          'GPS' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '1PAPISID' {
                            $skip = $false
                            $isSecure = $true
                          }
                          'test_cookie' {
                            $skip = $true
                            $isSecure = $false
                          } 
                          'DEVICE_INFO' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'VISITOR_INFO1_LIVE' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'CONSISTENCY' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'ACCOUNT_CHOOSER' {
                            $skip = $true
                            $isSecure = $false
                          }
                          'SUPPORT_CONTENT' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-1PLSID' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-3PLSID' {
                            $skip = $true
                            $isSecure = $false
                          }
                          '__Host-GAPS' {
                            $skip = $true
                            $isSecure = $false
                          }
                          Default {
                            $skip = $false
                            $isSecure = $true
                          }
                        }
                        if(!$skip){
                          if($thisApp.Config.Youtube_Cookies.name){
                            $index = $thisApp.Config.Youtube_Cookies.name.IndexOf($cookiename) 
                            if($index -ne -1){
                              $ExistingCookie = $thisApp.Config.Youtube_Cookies[$index] 
                            } 
                          }
                          #$null = $thisApp.Config.Youtube_Cookies.Clear()               
                          if($cookiename -and $cookievalue -and !$ExistingCookie){ 
                            $null = $thisApp.Config.Youtube_Cookies.add([cookie]@{
                                'Name'           = $cookiename
                                'isSecure'       = $isSecure
                                'Value'          = $cookievalue.trim()
                                'cookiedurldomain' = $cookiedurldomain
                            })
                            Write-EZLogs "[WebBrowser] Found and adding new Youtube cookie  -- Name: $cookiename -- Value: $($cookievalue)" -showtime -logtype Webview2 -Dev_mode                              
                          }elseif($cookiename -and $cookievalue -and $ExistingCookie.name -eq $cookiename -and $ExistingCookie.value -and $ExistingCookie.value -ne $cookievalue){
                            Write-EZLogs "[WebBrowser] Found and updated Youtube cookie  -- Name: $cookiename -- Value: $($cookievalue.trim())" -showtime -logtype Webview2 -Dev_mode 
                            $ExistingCookie.value = $cookievalue.trim() 
                          }
                        }
                      }
                      $twilight_user = $Cookies | Where-Object {$_ -match 'twilight-user=(?<value>.*)'}       
                      if($twilight_user -and $thisApp.Config.Chat_WebView2_Cookie -ne $twilight_user){
                        $existin_twilight_user = ([regex]::matches($twilight_user,  'twilight-user=(?<value>.*)') | & { process {$_.groups[1].value}})
                        $thisApp.Config.Chat_WebView2_Cookie = $existin_twilight_user
                        if($thisApp.Config.Dev_mode){Write-EZLogs "[WebBrowser] Found and updating existing twilight_user $($existin_twilight_user | Out-String)" -showtime -LogLevel 3 -logtype Twitch -Dev_mode}
                      }
                    }catch{
                      Write-EZLogs "[WebBrowser] An exception occurred saving youtube cookie $($cookie | Out-String)" -showtime -catcherror $_
                    }
                  }                                                         
                }
              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in CoreWebView2 WebResourceRequested Event' -showtime -catcherror $_
              }finally{
                $newRow = $null
                $cookiename = $null
                $cookievalue = $null
              }
          })
          if($synchash.WebBrowser_url){
            $NavigateUrl = $synchash.WebBrowser_url
          }else{
            $NavigateUrl = 'https://www.youtube.com'
            $synchash.WebBrowser_url = 'https://www.youtube.com'
          }
          #TODO: Extensions - Put into function
          if($synchash.WebBrowserOptions.AreBrowserExtensionsEnabled -and $thisApp.Config.Webview2_Extensions.Count -gt 0){           
            try{
              Write-EZLogs '>>>> Loading Webbrowser extensions' -logtype Webview2
              $Extensions = $thisApp.Config.Webview2_Extensions
              $Task = $synchash.WebBrowser.CoreWebView2.Profile.GetBrowserExtensionsAsync()
              $Task.GetAwaiter().OnCompleted(
                [Action]{
                  try{
                    Write-EZLogs " | Installed WebBrowser extensions: $($Task.Result.name -join ', ')" -logtype Webview2
                    $Extensions | & { process {
                        $InstallTask = $null
                        $Extension = $_
                        try{
                          if($Extension.isEnabled){
                            if([system.io.directory]::Exists($Extension.path) -and $Extension.Name){
                              $ExtensionName = $Task.Result.name | Where-Object {$_ -eq $Extension.Name -or $_ -match $Extension.Name}
                              if(!$ExtensionName){
                                Write-EZLogs "| Installing WebBrowser extension: $($Extension.Name)" -logtype Webview2
                                $InstallTask = $synchash.WebBrowser.CoreWebView2.Profile.AddBrowserExtensionAsync($Extension.path)
                                $Synchash.WebBrowserExt_IsInstalling = $true
                                $InstallTask.GetAwaiter().OnCompleted(
                                  [Action]{
                                    if($InstallTask){
                                      try{
                                        Write-EZLogs "Installed extension: $($InstallTask.Result | out-string)" -logtype Webview2 -Success
                                        if($Extension.id -ne $InstallTask.Result.ID){
                                          $ExtensionUpdateIndex = $thisApp.Config.Webview2_Extensions.name.IndexOf($InstallTask.Result.Name)
                                          if($ExtensionUpdateIndex -eq -1){
                                            $ExtensionUpdate = $thisApp.Config.Webview2_Extensions | Where-Object {$InstallTask.Result.Name -match $_.Name}
                                          }else{
                                            $ExtensionUpdate = $thisApp.Config.Webview2_Extensions[$ExtensionUpdateIndex]
                                          }
                                          if($ExtensionUpdate){
                                            Write-EZLogs " | Updating installed extension from id '$($ExtensionUpdate.ID)' to new id '$($InstallTask.Result.ID)' for extension: $($InstallTask.Result.Name)" -logtype Webview2
                                            $ExtensionUpdate.id = $InstallTask.Result.ID
                                          }else{
                                            Write-EZLogs "Unable to find extension with name '$($InstallTask.Result.Name)' in Config.Webview2_Extensions" -logtype Webview2 -warning
                                          }                                                                         
                                        }else{
                                          Write-EZLogs " | Installed extension id: $($InstallTask.Result.ID)" -logtype Webview2
                                        }
                                      }catch{
                                        Write-EZLogs "An exception occurred loading Webbrowser extension: $($Extension | Out-String)" -catcherror $_
                                      }finally{
                                        Add-Webview2Extension -synchash $synchash -thisapp $thisApp -Extensions $Extension -WebView2 $synchash.WebBrowser
                                      }
                                    }
                                  }.GetNewClosure()
                                )
                              }
                            }else{
                              Write-EZLogs "Cannot find path or name for extension: $($Extension)" -logtype Webview2 -warning
                            }
                          }
                        }catch{
                          Write-EZLogs "An exception occurred loading Webbrowser extension: $($Extension | Out-String)" -catcherror $_
                        }
                    }}
                  }catch{
                    Write-EZLogs "An exception occurred loading Webbrowser extensions: $($Task.Result | Out-String)" -catcherror $_
                  }finally{
                    Add-Webview2Extension -synchash $synchash -thisapp $thisApp -Extensions $Task.Result -WebView2 $synchash.WebBrowser 
                    if($Task){
                      $null = $Task.Dispose()
                      $task = $Null
                    }
                    if($synchash.WebBrowser_url -and $synchash.txtUrl.text -ne $synchash.WebBrowser_url){
                      Write-EZLogs "[WebBrowser] >>>> Navigating WebBrowser to $($synchash.WebBrowser_url)" -logtype Webview2
                      $synchash.WebBrowser.CoreWebView2.Navigate($synchash.WebBrowser_url)
                      $synchash.txtUrl.text = $synchash.WebBrowser_url
                    }elseif($NavigateUrl -and $synchash.WebBrowser.Source -ne $synchash.txtUrl.text){
                      Write-EZLogs "[WebBrowser] >>>> Navigating WebBrowser to $NavigateUrl" -logtype Webview2
                      $synchash.WebBrowser.CoreWebView2.Navigate($NavigateUrl) 
                      $synchash.txtUrl.text = $NavigateUrl
                    }
                  }                                       
                }.GetNewClosure() 
              )
            }catch{
              Write-EZLogs 'An exception occurred loading Webbrowser extensions' -catcherror $_
            }
          }else{
            if($synchash.WebBrowser_url){
              Write-EZLogs "[WebBrowser] >>>> Navigating WebBrowser to $($synchash.WebBrowser_url)" -logtype Webview2
              $synchash.WebBrowser.CoreWebView2.Navigate($synchash.WebBrowser_url) 
            }else{
              Write-EZLogs "[WebBrowser] >>>> Navigating WebBrowser to $NavigateUrl" -logtype Webview2
              $synchash.WebBrowser.CoreWebView2.Navigate($NavigateUrl) 
            }
          }     
          $synchash.WebBrowser.CoreWebView2.add_IsDocumentPlayingAudioChanged({
              try{
                $synchashWeak = [System.WeakReference]::new($synchash)
                if($synchashWeak.Target.WebBrowser.CoreWebView2.IsDocumentPlayingAudio){       
                  #$synchash.WebBrowser.CoreWebView2.TrySuspendAsync()                                             
                  if(-not [string]::IsNullOrEmpty($synchashWeak.Target.Current_Audio_Session.GroupingParam) -and $synchashWeak.Target.Managed_AudioSession_Processes -notcontains $synchashWeak.Target.WebBrowser.CoreWebView2.BrowserProcessId){
                    Write-EZLogs "[WebBrowser] WebBrowser.CoreWebView2: $($synchashWeak.Target.WebBrowser.CoreWebView2.DocumentTitle) - Source: $($synchashWeak.Target.WebBrowser.CoreWebView2.Source) - ContainsFullScreenElement: $($synchashWeak.Target.WebBrowser.CoreWebView2.ContainsFullScreenElement)" -loglevel 2 -logtype Webview2
                    Write-EZLogs "[WebBrowser] >>>> Webview2 Audio has begun playing: Audio: $($synchashWeak.Target.WebBrowser.CoreWebView2.IsDocumentPlayingAudio) Mute: $($synchashWeak.Target.WebBrowser.CoreWebView2.IsMuted)" -showtime -loglevel 2 -logtype Webview2
                    $synchashWeak.Target.WebBrowser.ExecuteScriptAsync(
                      $synchashWeak.Target.WebBrowser_Script
                    )
                    Set-AudioSessions -thisApp $thisApp -synchash $synchashWeak.Target
                    if($synchashWeak.Target.Managed_AudioSession_Processes){
                      $null = $synchashWeak.Target.Managed_AudioSession_Processes.add($synchashWeak.Target.WebBrowser.CoreWebView2.BrowserProcessId)
                    }                
                  }
                }elseif($synchashWeak.Target.WebBrowser.CoreWebView2.IsMuted){        
                  Write-EZLogs '#### WebBrowser Audio has been muted' -showtime -LogLevel 2 
                }
              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in WebBrowser.CoreWebView2.IsDocumentPlayingAudioChanged' -catcherror $_
              }
          })  
          <#          $synchash.WebBrowser.CoreWebView2.add_IsMutedChanged({
              if($sender.IsMuted){
              Write-EZLogs '#### WebBrowser Audio has been muted' -showtime -LogLevel 2     
              }else{
              Write-EZLogs '#### WebBrowser Audio has been un-muted' -showtime -LogLevel 2
              }
          })#>  
          if(!$Synchash.WebView2_Playlist_SelectedCommand){
            $Synchash.WebView2_Playlist_SelectedCommand = {
              try{  
                $LinkUri = $synchash.WebView2_ContextMenuLink
                $linktext = $synchash.WebView2_ContextMenuText
                $Channel = $synchash.WebView2_ContextMenuChannel
                Write-EZLogs "[WebBrowser] Playlist Name: $($this.Label)"
                $Playlist = Get-IndexesOf $synchash.all_playlists.Playlist_name -Value $this.Label | & { process {
                    $synchash.all_playlists[$_]
                }}
                $Playlist_name = $Playlist.name
                if($Channel -and $LinkUri -match 'twitch\.tv'){
                  Write-EZLogs "[WebBrowser] >>>> Adding Twitch Channel: $Channel -- Link: $LinkUri - LinkText: $($linktext) - to Playlist: $($Playlist_name)"
                  Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -AddtoPlaylist $Playlist_name -Channel $Channel
                }elseif(-not [string]::IsNullOrEmpty($LinkUri) -and -not [string]::IsNullOrEmpty($Playlist_name) -and (Test-URL $LinkUri)){
                  Write-EZLogs "[WebBrowser] >>>> Adding Youtube video $LinkUri - $($linktext) - to Playlist: $($Playlist_name)"
                  Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -AddtoPlaylist $Playlist_name
                }else{
                  Write-EZLogs "[WebBrowser] The provided URL is not valid or unable to find playlist! -- $LinkUri" -showtime -warning -logtype Youtube
                }                
              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
              }            
            }
          }
          if(!$Synchash.WebView2_Add_New_Playlist_SelectedCommand){
            $Synchash.WebView2_Add_New_Playlist_SelectedCommand = {
              try{  
                $LinkUri = $synchash.WebView2_ContextMenuLink
                $linktext = $synchash.WebView2_ContextMenuText
                $Channel = $synchash.WebView2_ContextMenuChannel
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
                $Playlist_name = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add New Playlist','Enter the name of the new playlist',$Button_Settings)
                if(-not [string]::IsNullOrEmpty($Playlist_name)){
                  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
                  $pattern = "[™`�$illegal]"
                  $Playlist_name = ([Regex]::Replace($Playlist_name, $pattern, '')).trim() 
                  [int]$character_Count = ($Playlist_name | measure-object -Character -ErrorAction SilentlyContinue).Characters
                  if([int]$character_Count -ge 100){
                    write-ezlogs "Playlist name too long! ($character_Count characters). Please choose a name 100 characters or less " -showtime -warning
                    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
                    $Button_Settings.AffirmativeButtonText = 'Ok'
                    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
                    $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist name too long! ($character_Count)","Please choose a name for the playlist that is 100 characters or less",$okandCancel,$Button_Settings)
                    return
                  }
                }else{
                  write-ezlogs "[WebBrowser] No playlist name was provided - cannot continue! " -showtime -warning
                  return
                }
                if($Channel -and $LinkUri -match 'twitch\.tv'){
                  Write-EZLogs "[WebBrowser] >>>> Adding Twitch Channel: $Channel -- Link: $LinkUri - LinkText: $($linktext) - to Playlist: $($Playlist_name)"
                  Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -AddtoPlaylist $Playlist_name -Channel $Channel
                }elseif(-not [string]::IsNullOrEmpty($LinkUri) -and -not [string]::IsNullOrEmpty($Playlist_name) -and (Test-URL $LinkUri)){
                  Write-EZLogs "[WebBrowser] >>>> Adding Youtube video $LinkUri - $($linktext) - to Playlist: $($Playlist_name)"
                  Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -AddtoPlaylist $Playlist_name
                }else{
                  Write-EZLogs "[WebBrowser] The provided URL is not valid or no valud playlist name was provided! -- $LinkUri" -showtime -warning -logtype Youtube
                }                
              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
              }             
            }
          }         
                      
          $synchash.WebBrowser.CoreWebView2.add_ContextMenuRequested({
              Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuRequestedEventArgs]$e)
              try{
                $synchashWeak = [System.WeakReference]::new($synchash)
                $TwitchRegex = '(^http(s)?:\/\/)?((www|en-es|en-gb|secure|beta|ro|www-origin|en-ca|fr-ca|lt|zh-tw|he|id|ca|mk|lv|ma|tl|hi|ar|bg|vi|th)\.)?twitch.tv\/(?!directory|user\/legal|admin|login|signup|jobs)(?<channel>\w+)'
                if($thisApp.Config.Dev_mode){Write-EZLogs "[WebBrowser] >>>> WebBrowser ContexeMenuRequested $($e.ContextMenuTarget | Out-String)" -Dev_mode}
                $synchashWeak.Target.WebView2_ContextMenuLink = $null
                $synchashWeak.Target.WebView2_ContextMenuText = $null
                $synchashWeak.Target.WebView2_ContextMenuChannel = $Null
                $menulist = $e.MenuItems
                if($e.ContextMenuTarget.LinkUri -match 'youtube|youtu\.be|youtube\-nocookie\.com' -and ($e.ContextMenuTarget.LinkUri -match 'v=|\/watch\/|\/v\/|list\=')){ 
                  $synchashWeak.Target.WebView2_ContextMenuLink = $e.ContextMenuTarget.LinkUri
                  $synchashWeak.Target.WebView2_ContextMenuText = $e.contextMenuTarget.LinkText
                  #Download and Add to Youtube library
                  if(!$synchashWeak.Target.WebView2_DownloadMediaCommand){
                    $DownloadIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Material-Download.png"
                    if([System.IO.File]::Exists($DownloadIcon) -and !$synchash.DownloadIcon_StreamImage){
                      $image_bytes = [System.IO.File]::ReadAllBytes($DownloadIcon)
                      $synchashWeak.Target.DownloadIcon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                    }
                    [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_DownloadMediaCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Download and add to Media Library',$synchashWeak.Target.DownloadIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                    $synchashWeak.Target.WebView2_DownloadMediaCommand.add_CustomItemSelected({
                        $LinkUri = $synchash.WebView2_ContextMenuLink
                        $linktext = $synchash.WebView2_ContextMenuText
                        try{  
                          $result = Open-FolderDialog -Title 'Select the directory path where media will be downloaded to'
                          if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and [System.IO.Directory]::Exists($result)){
                            Write-EZLogs "[WebBrowser] >>>> Downloading $($linktext) to $result" -showtime
                            Invoke-DownloadMedia -Download_URL $LinkUri -Title_name $linktext -Download_Path $result -synchash $synchash -thisapp $thisApp -Show_notification
                          }else{
                            Write-EZLogs "[WebBrowser] The provided URL or path is not valid or was not provided! -- Link: $LinkUri - Directory: $result" -showtime -warning -logtype Youtube
                          }                
                        }catch{
                          Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                        }                                   
                    })
                  }
                  $menulist.Insert(2, $synchashWeak.Target.WebView2_DownloadMediaCommand)                   
                  #Add to Youtube library 
                  if($thisApp.Config.Import_Youtube_Media){                  
                    $YoutubeIcon = "$($thisApp.Config.Current_folder)\Resources\Youtube\Material-Youtube_Auth.png"
                    if([System.IO.File]::Exists($YoutubeIcon) -and !$synchashWeak.Target.YoutubeIcon_StreamImage){
                      $image_bytes = [System.IO.File]::ReadAllBytes($YoutubeIcon)
                      $synchashWeak.Target.YoutubeIcon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                    }elseif($false){
                      $icon = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
                      $icon.Foreground = '#FFFF3737'
                      $icon.Kind = 'Youtube'
                      $icon.Width = '16'
                      $icon.Height = '16'
                      $geo = [System.Windows.Media.Geometry]::Parse($icon.Data)
                      $gd = [System.Windows.Media.GeometryDrawing]::new()
                      $gd.Geometry = $geo
                      $gd.Brush = $icon.Foreground
                      $PackIcon = [System.Windows.Media.DrawingImage]::new($gd)
                      $image = [System.Windows.Controls.Image]::new()
                      $image.source = $PackIcon
                      $image.Arrange([System.Windows.Rect]::new(0,0,$icon.Width,$icon.Height))
                      $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($icon.Width,$icon.Height,64,64,[System.Windows.Media.PixelFormats]::Pbgra32)
                      $bitmap.Render($image)
                      $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                      $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
                      $stream_image = [System.IO.MemoryStream]::new()
                      $encoder.Save($stream_image)
                    }
                    if(!$synchashWeak.Target.WebView2_AddMediaCommand){
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_AddMediaCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Youtube Media Library',$synchashWeak.Target.YoutubeIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                      $synchashWeak.Target.WebView2_AddMediaCommand.add_CustomItemSelected({
                          $LinkUri = $synchash.WebView2_ContextMenuLink
                          $linktext = $synchash.WebView2_ContextMenuText   
                          try{  
                            if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri)){
                              if($thisApp.Config.PlayLink_OnDrop){
                                Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext
                              }
                              Write-EZLogs "[WebBrowser] >>>> Adding Youtube video $LinkUri - $($linktext)" -showtime -color cyan -logtype Youtube
                              Import-Youtube -Youtube_URL $LinkUri -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisApp.config.Media_Profile_Directory  -thisApp $thisApp   
                            }else{
                              Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- $LinkUri" -showtime -warning -logtype Youtube
                            }                
                          }catch{
                            Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                          }                                   
                      })
                    }
                    $menulist.Insert(2, $synchashWeak.Target.WebView2_AddMediaCommand) 

                    #Play Media               
                    if(!$synchashWeak.Target.WebView2_PlayMediaCommand){
                      $Samson_Icon = "$($thisApp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"               
                      if([System.IO.File]::Exists($Samson_Icon) -and !$synchashWeak.Target.Samson_Icon_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($Samson_Icon)
                        $synchashWeak.Target.Samson_Icon_StreamImage = [System.IO.MemoryStream]::new($image_bytes) 
                      } 
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_PlayMediaCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Play with $($thisApp.Config.App_name)",$synchashWeak.Target.Samson_Icon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                      $synchashWeak.Target.WebView2_PlayMediaCommand.add_CustomItemSelected({
                          $LinkUri = $synchash.WebView2_ContextMenuLink
                          $linktext = $synchash.WebView2_ContextMenuText    
                          try{  
                            if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri)){
                              if($LinkUri -match '&t='){
                                $LinkUri = ($($LinkUri) -split('&t='))[0].trim()
                              }          
                              Write-EZLogs "[WebBrowser] >>>> Playing Youtube link $LinkUri" -showtime -color cyan 
                              Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -PlayOnly
                            }else{
                              Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- $LinkUri" -showtime -warning -logtype Youtube
                            }                
                          }catch{
                            Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                          }                                   
                      })
                    }
                    $menulist.Insert(0, $synchashWeak.Target.WebView2_PlayMediaCommand)

                    #Add to play queue
                    if(!$synchashWeak.Target.WebView2_AddMediaQueueCommand){
                      $QueueIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Coolicons-AddToQueue.png"
                      if([System.IO.File]::Exists($QueueIcon) -and !$synchashWeak.Target.AddToQueue_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($QueueIcon)
                        $synchashWeak.Target.AddToQueue_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                      }
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_AddMediaQueueCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Play Queue',$synchashWeak.Target.AddToQueue_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                      $synchashWeak.Target.WebView2_AddMediaQueueCommand.add_CustomItemSelected({
                          $LinkUri = $synchash.WebView2_ContextMenuLink
                          $linktext = $synchash.WebView2_ContextMenuText    
                          try{  
                            if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri)){
                              Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -AddtoQueue                           
                            }else{
                              Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- $LinkUri" -showtime -warning -logtype Youtube
                            }                
                          }catch{
                            Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                          }                                   
                      })
                    }
                    $menulist.Insert(1, $synchashWeak.Target.WebView2_AddMediaQueueCommand) 

                    #Add to playlists                 
                    if(!$synchashWeak.Target.WebView2_AddPlaylistSubCommand){
                      $QueueIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Material-PlaylistPlus.png"
                      if([System.IO.File]::Exists($QueueIcon) -and !$synchashWeak.Target.QueueIcon_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($QueueIcon)
                        $synchashWeak.Target.QueueIcon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                      } 
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_AddPlaylistSubCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Playlist',$synchashWeak.Target.QueueIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Submenu)   
                    }else{
                      $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Clear()
                    }                  
                    if($synchashWeak.Target.all_playlists.count -gt 0){
                      foreach ($Playlist in $synchashWeak.Target.all_playlists.where({-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.values.url -notcontains $e.ContextMenuTarget.LinkUri}))
                      {
                        $Playlist_name = $Playlist.name
                        $Playlist_ID = $Playlist.Playlist_ID
                        $ID_Cleaned = ($Playlist_ID -replace '\s', '').GetHashCode()
                        #$Playlist_tracks = $Playlist.Playlist_tracks.values
                        if(!$synchashWeak.Target."WebView2_Playlist_$ID_Cleaned"){
                          [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target."WebView2_Playlist_$ID_Cleaned" = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem($Playlist_name,$null,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)
                          $synchashWeak.Target."WebView2_Playlist_$ID_Cleaned".add_CustomItemSelected($Synchash.WebView2_Playlist_SelectedCommand)  
                        }
                        $Null = $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Add($synchashWeak.Target."WebView2_Playlist_$ID_Cleaned")
                      }
                      if(!$synchashWeak.Target.WebView2_Add_New_Playlist){
                        [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_Add_New_Playlist = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to new playlist...',$synchashWeak.Target.QueueIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)
                        $synchashWeak.Target.WebView2_Add_New_Playlist.add_CustomItemSelected($Synchash.WebView2_Add_New_Playlist_SelectedCommand)  
                      }
                      $Null = $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Add($synchashWeak.Target.WebView2_Add_New_Playlist) 
                    }                                    
                    $menulist.Insert(2, $synchashWeak.Target.WebView2_AddPlaylistSubCommand)
                  }
                }elseif($e.ContextMenuTarget.LinkUri -match $TwitchRegex){
                  $linkmatch = [regex]::matches($e.ContextMenuTarget.LinkUri, $TwitchRegex)
                  $Channel = ($linkmatch.groups | where-Object {$_.name -eq 'channel'}).value
                  if($Channel){
                    $synchashWeak.Target.WebView2_ContextMenuLink = $e.ContextMenuTarget.LinkUri
                    $synchashWeak.Target.WebView2_ContextMenuText = $e.contextMenuTarget.LinkText
                    $synchashWeak.Target.WebView2_ContextMenuChannel = $Channel

                    #Add to Twitch library 
                    if($thisApp.Config.Import_Twitch_Media){                  
                      $LibraryIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Library.png"
                      if(!$synchashWeak.Target.Libraryicon_StreamImage -and [system.io.file]::Exists($LibraryIcon)){
                        $image_bytes = [System.IO.File]::ReadAllBytes($LibraryIcon)
                        $synchashWeak.Target.Libraryicon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                      }
                      if(!$synchashWeak.Target.WebView2_AddTwitchMediaCommand){
                        [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_AddTwitchMediaCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Twitch Media Library',$synchashWeak.Target.Libraryicon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                        $synchashWeak.Target.WebView2_AddTwitchMediaCommand.add_CustomItemSelected({
                            $LinkUri = $synchash.WebView2_ContextMenuLink
                            $linktext = $synchash.WebView2_ContextMenuText
                            $Channel = $synchash.WebView2_ContextMenuChannel 
                            try{  
                              if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $Channel){
                                Write-EZLogs "[WebBrowser] >>>> Adding Twitch Channel: $Channel - Link: $LinkUri - Linktext: $($linktext) -- to Twitch Media Library" -showtime
                                Import-Twitch -Twitch_URL $LinkUri -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace
                              }else{
                                Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- Link: $LinkUri -- Channel: $Channel" -showtime -warning
                              }                
                            }catch{
                              Write-EZLogs '[WebBrowser] An exception occurred in AddTwitchMediaCommand' -showtime -catcherror $_
                            }                                   
                        })
                      }
                      $menulist.Insert(0, $synchashWeak.Target.WebView2_AddTwitchMediaCommand) 

                      #Twitch Actions
                      $Followed = $false                
                      if(!$synchashWeak.Target.WebView2_TwitchActionSubCommand){
                        $TwitchIcon = "$($thisApp.Config.Current_folder)\Resources\Twitch\Material-Twitch.png"
                        if(!$synchashWeak.Target.TwitchIcon_StreamImage -and [System.IO.File]::Exists($TwitchIcon)){
                          $image_bytes = [System.IO.File]::ReadAllBytes($TwitchIcon)
                          $synchashWeak.Target.TwitchIcon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                        }elseif(!$synchashWeak.Target.TwitchIcon_StreamImage){
                          $icon = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
                          $icon.Foreground = '#FF9A75F9'
                          $icon.Kind = 'Twitch'
                          $icon.Width = '16'
                          $icon.Height = '16'
                          $geo = [System.Windows.Media.Geometry]::Parse($icon.Data)
                          $gd = [System.Windows.Media.GeometryDrawing]::new()
                          $gd.Geometry = $geo
                          $gd.Brush = $icon.Foreground
                          $PackIcon = [System.Windows.Media.DrawingImage]::new($gd)
                          $image = [System.Windows.Controls.Image]::new()
                          $image.source = $PackIcon
                          $image.Arrange([System.Windows.Rect]::new(0,0,$icon.Width,$icon.Height))
                          $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($icon.Width,$icon.Height,64,64,[System.Windows.Media.PixelFormats]::Pbgra32)
                          $bitmap.Render($image)
                          $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                          $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
                          $synchashWeak.Target.TwitchIcon_StreamImage = [System.IO.MemoryStream]::new()
                          $encoder.Save($synchashWeak.Target.TwitchIcon_StreamImage)
                        }
                        [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_TwitchActionSubCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Twitch Actions',$synchashWeak.Target.TwitchIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Submenu)   
                      }else{
                        $synchashWeak.Target.WebView2_TwitchActionSubCommand.Children.Clear()
                      }
                      #Twitch Follow/Unfollow
                      if($synchashWeak.Target.All_Twitch_Media.url){
                        $FollowedIndex = $synchashWeak.Target.All_Twitch_Media.url.indexof("$($e.ContextMenuTarget.LinkUri)")
                        if($FollowedIndex -eq $Null -or $FollowedIndex -eq -1){
                          $FollowedIndex = $synchashWeak.Target.All_Twitch_Media.Channel_Name.indexof("$channel")
                        }
                        if($FollowedIndex -ne -1){
                          $TwitchMedia = $synchashWeak.Target.All_Twitch_Media[$FollowedIndex]
                          if($TwitchMedia -and -not [string]::IsNullOrEmpty($TwitchMedia.followed)){
                            $Followed = $true
                          }
                        }else{
                          $Followed = $false
                        }
                      }
                      if($Followed){
                        $Unfollow_Icon = "$($thisApp.Config.Current_folder)\Resources\Images\UserUnfollowLine.png"               
                        if([System.IO.File]::Exists($Unfollow_Icon) -and !$synchashWeak.Target.Unfollow_StreamImage){
                          $image_bytes = [System.IO.File]::ReadAllBytes($Unfollow_Icon)
                          $synchashWeak.Target.Unfollow_StreamImage = [System.IO.MemoryStream]::new($image_bytes) 
                        }
                        if(!$synchashWeak.Target.TwitchRemoveFollowCommand){
                          [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchRemoveFollowCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Unfollow Channel",$synchashWeak.Target.Unfollow_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                          $synchashWeak.Target.TwitchRemoveFollowCommand.add_CustomItemSelected({
                              $LinkUri = $synchash.WebView2_ContextMenuLink
                              $linktext = $synchash.WebView2_ContextMenuText    
                              $Channel = $synchash.WebView2_ContextMenuChannel
                              try{  
                                if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $channel){        
                                  Write-EZLogs "[WebBrowser_NOTFINISHED] >>>> Unfollowing Twitch channel: $channel - link $LinkUri" -showtime
                                  #Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -PlayOnly -Channel $Channel
                                }else{
                                  Write-EZLogs "[WebBrowser_NOTFINISHED] The provided URL is not valid or was not provided! -- $LinkUri -- channel: $Channel" -showtime -warning -logtype Webview2
                                }                
                              }catch{
                                Write-EZLogs '[WebBrowser] An exception occurred in TwitchRemoveFollowCommand' -showtime -catcherror $_
                              }   
                          })
                        } 
                        [void]$synchashWeak.Target.WebView2_TwitchActionSubCommand.Children.Add($synchashWeak.Target.TwitchRemoveFollowCommand)
                      }else{
                        $follow_Icon = "$($thisApp.Config.Current_folder)\Resources\Images\UserfollowLine.png"               
                        if([System.IO.File]::Exists($follow_Icon) -and !$synchashWeak.Target.follow_StreamImage){
                          $image_bytes = [System.IO.File]::ReadAllBytes($follow_Icon)
                          $synchashWeak.Target.follow_StreamImage = [System.IO.MemoryStream]::new($image_bytes) 
                        }
                        if(!$synchashWeak.Target.TwitchAddFollowCommand){
                          [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchAddFollowCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Follow Channel",$synchashWeak.Target.follow_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                          $synchashWeak.Target.TwitchAddFollowCommand.add_CustomItemSelected({
                              $LinkUri = $synchash.WebView2_ContextMenuLink
                              $linktext = $synchash.WebView2_ContextMenuText    
                              $Channel = $synchash.WebView2_ContextMenuChannel
                              try{  
                                if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $channel){        
                                  Write-EZLogs "[WebBrowser_NOTFINISHED] >>>> Adding new follow for Twitch channel: $channel - link $LinkUri" -showtime
                                  #Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -PlayOnly -Channel $Channel
                                }else{
                                  Write-EZLogs "[WebBrowser_NOTFINISHED] The provided URL is not valid or was not provided! -- $LinkUri -- channel: $Channel" -showtime -warning
                                }                
                              }catch{
                                Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                              }   
                          })
                        } 
                        [void]$synchashWeak.Target.WebView2_TwitchActionSubCommand.Children.Add($synchashWeak.Target.TwitchAddFollowCommand)
                      }
                      if($TwitchMedia){
                        if($synchashWeak.Target.Bell_StreamImage -is [System.IDisposable]){
                          $synchashWeak.Target.Bell_StreamImage.dispose()
                        }
                        if($twitchmedia.Enable_LiveAlert){
                          $Header = "Disable Live Notifications"
                          $isChecked = $true
                          $Bell_Icon = "$($thisApp.Config.Current_folder)\Resources\Images\BellCancel.png"
                        }else{
                          $Header = "Enable Live Notifications"
                          $isChecked = $false
                          $Bell_Icon = "$($thisApp.Config.Current_folder)\Resources\Images\BellCheck.png"
                        }                                        
                        if([System.IO.File]::Exists($Bell_Icon)){
                          $image_bytes = [System.IO.File]::ReadAllBytes($Bell_Icon)
                          $synchashWeak.Target.Bell_StreamImage = [System.IO.MemoryStream]::new($image_bytes) 
                        }
                        if(!$synchashWeak.Target.TwitchLiveAlertCommand){
                          $synchashWeak.Target.TwitchLiveAlertCommand = {
                            $LinkUri = $synchash.WebView2_ContextMenuLink
                            $linktext = $synchash.WebView2_ContextMenuText
                            $Channel = $synchash.WebView2_ContextMenuChannel
                            $isChecked = [bool]($this.Label -eq "Disable Live Notifications")
                            try{  
                              if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $channel -and $isChecked){        
                                Write-EZLogs "[WebBrowser_NOTFINISHED] >>>> Disabling Live Alert for Twitch channel: $channel - link $LinkUri" -showtime
                                #Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -PlayOnly -Channel $Channel
                              }elseif(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $channel){
                                Write-EZLogs "[WebBrowser_NOTFINISHED] >>>> Enabling Live Alert for Twitch channel: $channel - link $LinkUri" -showtime
                              }else{
                                Write-EZLogs "[WebBrowser_NOTFINISHED] The provided URL is not valid or was not provided! -- $LinkUri -- channel: $Channel" -showtime -warning
                              }                
                            }catch{
                              Write-EZLogs '[WebBrowser] An exception occurred in TwitchLiveAlertCommand' -showtime -catcherror $_
                            }  
                          }
                        }

                        if($isChecked){
                          if(!$synchashWeak.Target.TwitchAlertDisableCommand){
                            [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchAlertDisableCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem($Header,$synchashWeak.Target.Bell_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)                        
                            $synchashWeak.Target.TwitchAlertDisableCommand.add_CustomItemSelected($synchashWeak.Target.TwitchLiveAlertCommand)
                          } 
                          [void]$synchashWeak.Target.WebView2_TwitchActionSubCommand.Children.Add($synchashWeak.Target.TwitchAlertDisableCommand)
                        }else{
                          if(!$synchashWeak.Target.TwitchAlertEnableCommand){
                            [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchAlertEnableCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem($Header,$synchashWeak.Target.Bell_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)                        
                            $synchashWeak.Target.TwitchAlertEnableCommand.add_CustomItemSelected($synchashWeak.Target.TwitchLiveAlertCommand)
                          }
                          [void]$synchashWeak.Target.WebView2_TwitchActionSubCommand.Children.Add($synchashWeak.Target.TwitchAlertEnableCommand)
                        }
                      }
                      $menulist.Insert(1, $synchashWeak.Target.WebView2_TwitchActionSubCommand)
                    }
                    #Play Media               
                    if(!$synchashWeak.Target.TwitchWebView2_PlayMediaCommand){
                      $Samson_Icon = "$($thisApp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"               
                      if([System.IO.File]::Exists($Samson_Icon) -and !$synchashWeak.Target.Samson_Icon_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($Samson_Icon)
                        $synchashWeak.Target.Samson_Icon_StreamImage = [System.IO.MemoryStream]::new($image_bytes) 
                      } 
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchWebView2_PlayMediaCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem("Play with $($thisApp.Config.App_name)",$synchashWeak.Target.Samson_Icon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                      $synchashWeak.Target.TwitchWebView2_PlayMediaCommand.add_CustomItemSelected({
                          $LinkUri = $synchash.WebView2_ContextMenuLink
                          $linktext = $synchash.WebView2_ContextMenuText    
                          $Channel = $synchash.WebView2_ContextMenuChannel
                          try{  
                            if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $channel){        
                              Write-EZLogs "[WebBrowser] >>>> Playing Twitch link $LinkUri -- channel: $channel" -showtime -logtype Webview2
                              Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -PlayOnly -Channel $Channel
                            }else{
                              Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- $LinkUri -- channel: $Channel" -showtime -warning -logtype Webview2
                            }                
                          }catch{
                            Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                          }   
                      })
                    }
                    $menulist.Insert(0, $synchashWeak.Target.TwitchWebView2_PlayMediaCommand)
                    #Add to play queue
                    if(!$synchashWeak.Target.TwitchWebView2_AddMediaQueueCommand){
                      $QueueIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Coolicons-AddToQueue.png"
                      if([System.IO.File]::Exists($QueueIcon) -and !$synchashWeak.Target.AddToQueue_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($QueueIcon)
                        $synchashWeak.Target.AddToQueue_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                      }
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.TwitchWebView2_AddMediaQueueCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Play Queue',$synchashWeak.Target.AddToQueue_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)          
                      $synchashWeak.Target.TwitchWebView2_AddMediaQueueCommand.add_CustomItemSelected({
                          $LinkUri = $synchash.WebView2_ContextMenuLink
                          $linktext = $synchash.WebView2_ContextMenuText
                          $Channel = $synchash.WebView2_ContextMenuChannel
                          try{  
                            if(-not [string]::IsNullOrEmpty($LinkUri) -and (Test-URL $LinkUri) -and $Channel){
                              Write-EZLogs "[WebBrowser] Found valid Twitch URL: $LinkUri -- channel: $Channel" -showtime -logtype Webview2
                              Add-TwitchPlayback -synchash $synchash -thisApp $thisApp -LinkUri $LinkUri -linktext $linktext -Channel $Channel -AddtoQueue   
                            }else{
                              Write-EZLogs "[WebBrowser] The provided URL is not valid or was not provided! -- $LinkUri -- channel: $Channel" -showtime -warning -logtype Webview2
                            }                
                          }catch{
                            Write-EZLogs '[WebBrowser] An exception occurred in CustomItemSelected.Add_Click' -showtime -catcherror $_
                          }                                   
                      })
                    }
                    $menulist.Insert(1, $synchashWeak.Target.TwitchWebView2_AddMediaQueueCommand) 

                    #Add to playlists                 
                    if(!$synchashWeak.Target.WebView2_AddPlaylistSubCommand){
                      $QueueIcon = "$($thisApp.Config.Current_folder)\Resources\Images\Material-PlaylistPlus.png"
                      if([System.IO.File]::Exists($QueueIcon) -and !$synchashWeak.Target.QueueIcon_StreamImage){
                        $image_bytes = [System.IO.File]::ReadAllBytes($QueueIcon)
                        $synchashWeak.Target.QueueIcon_StreamImage = [System.IO.MemoryStream]::new($image_bytes)
                      } 
                      [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_AddPlaylistSubCommand = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to Playlist',$synchashWeak.Target.QueueIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Submenu)   
                    }else{
                      $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Clear()
                    }                  
                    if($synchashWeak.Target.all_playlists.count -gt 0){
                      foreach ($Playlist in $synchashWeak.Target.all_playlists.where({-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.values.url -notcontains $e.ContextMenuTarget.LinkUri}))
                      {
                        $Playlist_name = $Playlist.name
                        $Playlist_ID = $Playlist.Playlist_ID
                        $ID_Cleaned = ($Playlist_ID -replace '\s', '').GetHashCode()
                        if(!$synchashWeak.Target."WebView2_Playlist_$ID_Cleaned"){
                          [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target."WebView2_Playlist_$ID_Cleaned" = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem($Playlist_name,$null,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)
                          $synchashWeak.Target."WebView2_Playlist_$ID_Cleaned".add_CustomItemSelected($Synchash.WebView2_Playlist_SelectedCommand)  
                        }
                        $Null = $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Add($synchashWeak.Target."WebView2_Playlist_$ID_Cleaned")
                      }
                      if(!$synchashWeak.Target.WebView2_Add_New_Playlist){
                        [Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItem]$synchashWeak.Target.WebView2_Add_New_Playlist = $synchashWeak.Target.WebBrowser.CoreWebView2.Environment.CreateContextMenuItem('Add to new playlist...',$synchashWeak.Target.QueueIcon_StreamImage,[Microsoft.Web.WebView2.Core.CoreWebView2ContextMenuItemKind]::Command)
                        $synchashWeak.Target.WebView2_Add_New_Playlist.add_CustomItemSelected($Synchash.WebView2_Add_New_Playlist_SelectedCommand)  
                      }
                      $Null = $synchashWeak.Target.WebView2_AddPlaylistSubCommand.Children.Add($synchashWeak.Target.WebView2_Add_New_Playlist) 
                    }                                    
                    $menulist.Insert(2, $synchashWeak.Target.WebView2_AddPlaylistSubCommand)
                  }
                }
              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in WebBrowser ContextMenuRequested event' -showtime -catcherror $_
              }
          })
          $synchash.WebBrowser.CoreWebView2.add_ContainsFullScreenElementChanged({
              Param($sender)
              try{
                Write-EZLogs "[WebBrowser] >>>> WebBrowser.CoreWebView2 ContainsFullScreenElementChanged $($args)" -logtype Webview2 -Dev_mode
                if($sender.ContainsFullScreenElement){
                  if(!$synchash.WebBrowserAnchorable.isFloating){
                    $synchash.WebBrowserAnchorable.IsMaximized = $true
                    $synchash.WebBrowserAnchorable.Float()
                    $synchash.WebBrowserGrid.Tag = $false
                  }
                  if($synchash.WebBrowserAnchorable.isFloating -and $synchash.WebBrowserFloat.WindowState -ne 'Maximized'){
                    $synchash.WebBrowserAnchorable.IsMaximized = $true
                    if($synchash.WebBrowserFloat.isLoaded){
                      $synchash.WebBrowserFloat.WindowState = 'Maximized'
                    }               
                    $synchash.WebBrowserGrid.Tag = $false  
                  }
                }elseif($synchash.WebBrowserAnchorable.isFloating -and  $synchash.WebBrowserFloat.WindowState -eq 'Maximized'){
                  $synchash.WebBrowserAnchorable.IsMaximized = $false
                  $synchash.WebBrowserFloat.WindowState = 'Normal'
                  $synchash.WebBrowserFloat.Top = '0'
                  $synchash.WebBrowserGrid.Tag = $true
                }

              }catch{
                Write-EZLogs '[WebBrowser] An exception occurred in ContainsFullScreenElementChanged' -catcherror $_
              }
          })

        }else{
          Write-EZLogs "[WebBrowser] WebBrowser CoreWebView2 Initialization Completed but without success - Message: $($event.InitializationException.Message) - InnerException: $($event.InitializationException.InnerException) - StackTrace: $($event.InitializationException.StackTrace)" -showtime -warning -logtype Webview2
        }          
      }
    )
    if($synchash.GoToPage){
      $synchash.GoToPage.Add_click({
          try{
            if($synchash.WebBrowser.CoreWebview2){
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }else{
              Write-EZLogs "Unable to start navigation to $($synchash.txtUrl.text) for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }           
          }catch{
            Write-EZLogs 'An exception occurred in GoToPage Click event' -showtime -catcherror $_
          }
      })
    }
    if($synchash.GoToYoutube){
      $synchash.GoToYoutube.Add_click({
          try{
            $synchash.txtUrl.text = "https://www.youtube.com"
            if($synchash.WebBrowser.CoreWebview2){
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }else{
              Write-EZLogs "Unable to start navigation to $($synchash.txtUrl.text) for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }           
          }catch{
            Write-EZLogs 'An exception occurred in GoToYoutube Click event' -showtime -catcherror $_
          }
      })
    }
    if($synchash.GoToSpotify){
      $synchash.GoToSpotify.Add_click({
          try{
            $synchash.txtUrl.text = "https://open.spotify.com"
            if($synchash.WebBrowser.CoreWebview2){
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }else{
              Write-EZLogs "Unable to start navigation to $($synchash.txtUrl.text) for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }           
          }catch{
            Write-EZLogs 'An exception occurred in GoToSpotify Click event' -showtime -catcherror $_
          }
      })
    }
    if($synchash.GoToTwitch){
      $synchash.GoToTwitch.Add_click({
          try{
            $synchash.txtUrl.text = "https://www.twitch.tv"
            if($synchash.WebBrowser.CoreWebview2){
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }else{
              Write-EZLogs "Unable to start navigation to $($synchash.txtUrl.text) for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }           
          }catch{
            Write-EZLogs 'An exception occurred in GoToTwitch Click event' -showtime -catcherror $_
          }
      })
    }
    if($synchash.txturl){
      $synchash.txturl.Add_KeyDown({
          Param($Sender,[System.Windows.Input.KeyEventArgs]$e)
          try{
            if($e.key -eq 'Return'){
              Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.WebBrowser -thisApp $thisApp
            }  
          }catch{
            Write-EZLogs 'An exception occurred in texturl keydown event' -showtime -catcherror $_
          }    
      })
    }
    if($synchash.BrowseBack){
      $synchash.BrowseBack.Add_click({
          try{
            if($synchash.WebBrowser.CoreWebview2){
              $synchash.WebBrowser.GoBack()
            }else{
              Write-EZLogs "Unable to execute GoBack() for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
            }          
          }catch{
            Write-EZLogs 'An exception occurred in BrowseBack Click event' -showtime -catcherror $_
          }
      })
    }
    $synchash.WebBrowser.Add_SourceChanged({        
        try{
          $synchash.txtUrl.text = $synchash.WebBrowser.Source
        }catch{
          Write-EZLogs 'An exception occurred in WebBrowser Source changed event' -showtime -catcherror $_
        } 
    }) 
    if($synchash.BrowseForward){
      $synchash.BrowseForward.Add_click({
          try{
            if($synchash.WebBrowser.CoreWebview2){
              $synchash.WebBrowser.GoForward()
            }else{
              Write-EZLogs "Unable to execute GoForward for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
            }           
          }catch{
            Write-EZLogs 'An exception occurred in BrowseForward click event' -showtime -catcherror $_
          }  
      })
    }
    if($synchash.BrowseRefresh){
      $synchash.BrowseRefresh.Add_click({
          try{
            if($synchash.WebBrowser.CoreWebview2){
              $synchash.WebBrowser.Reload()
            }else{
              Write-EZLogs "Unable to execute reload for WebBrowser, CoreWebView2 not yet initialized: $($synchash.WebBrowser)" -warning -logtype Webview2
              Initialize-WebBrowser -synchash $synchash -thisApp $thisApp
            }       
          }catch{
            Write-EZLogs 'An exception occurred in BrowseRefresh click event' -showtime -catcherror $_
          } 
      })  
    }
    $synchash.WebBrowser.add_WebMessageReceived({
        try{
          $results = $args.WebMessageAsJson | ConvertFrom-Json
          foreach($result in $results){
            if($thisApp.Config.Dev_mode){Write-EZLogs "Webbrowser message received: $($results.value)" -showtime -loglevel 3 -logtype Webview2 -Dev_mode}
            if(!$synchash.vlc.isPlaying){
              if($result.key -eq 'videodata'){
                if($thisApp.Config.Dev_mode){Write-EZLogs "Videodata Webbrowser message received: $($results.value)" -showtime -logtype Webview2 -Dev_mode}
                $synchash.Youtube_webplayer_current_Media = $result.value
                if($($result.value.author) -and $synchash.Now_Playing_Artist_Label.DataContext -ne "$($result.value.author)"){
                  Write-EZLogs ">>>> Updating Youtube Author/Artist from webplayer videodata: $($result.value.author)" -showtime -logtype Youtube -LogLevel 2
                  $synchash.Now_Playing_Artist_Label.DataContext = "$($result.value.author)"
                  if($($result.value.title) -and $synchash.Now_Playing_title_Label.DataContext -ne "$($result.value.title)"){
                    Write-EZLogs "Updating Youtube title from webplayer videodata: $($result.value.title)" -showtime -logtype Youtube -LogLevel 2
                    $synchash.Now_Playing_title_Label.DataContext = "$($result.value.title)"
                  }
                }                  
                if($result.value.video_id -and !$result.value.isPlayable){
                  Write-EZLogs 'Youtube webplayer returned media as not playable!' -showtime -warning -logtype Youtube -LogLevel 2             
                  return
                }
              } 
              if($result.key -eq 'time'){
                Write-EZLogs ">>>> Youtube video current time: $($result.value)" -dev_mode
                if($thisApp.Config.Enable_Sponsorblock -and $thisApp.Config.Sponsorblock_ActionType -eq 'skip' -and -not [string]::IsNullOrEmpty($thisApp.SponsorBlock.videoId) -and -not [string]::IsNullOrEmpty($synchash.Youtube_webplayer_current_Media.video_id) -and $synchash.Youtube_webplayer_current_Media.video_id -in $thisApp.SponsorBlock.videoId){
                  try{  
                    Write-EZLogs ">>>> Checking Sponsorblock segments that match current time $($result.value)" -dev_mode
                    #$Start = $Segment.segment[0]      
                    #$Starttime = [timespan]::FromSeconds($Segment.segment[0]) 
                    $currentime = [timespan]::FromSeconds($result.value)   
                    $Segment = $thisApp.SponsorBlock | Where-Object {[timespan]::FromSeconds($_.segment[0]) -eq $currentime -or ($currentime -gt [timespan]::FromSeconds($_.segment[0]) -and $currentime -lt [timespan]::FromSeconds($_.segment[0]).add('0:0:0:0.4'))}
                    if($Segment){
                      Write-EZLogs ">>>> Sponsorblock skipping segment for youtubeid $($thisApp.SponsorBlock.videoId) - Start: $($Segment.segment[0]) -- End: $($Segment.segment[1])" -warning
                      $YoutubeWebView2_SeekScript = @"
try {
  var player = document.getElementById('movie_player');
  //var state = player.getPlayerState();
  console.log('Seeking Youtube player for Sponsorblock to $($Segment.segment[1])');
  player.seekTo($($Segment.segment[1]));
} catch (error) {
  console.error('An exception occurred seeking player to $($Segment.segment[1])', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}
"@         
                      $synchash.YoutubeWebView2.ExecuteScriptAsync(
                        $YoutubeWebView2_SeekScript      
                      )
                    }
                  }catch{
                    Write-EZLogs "An exception occurred skipping video segments from sponsorblock: $($thisApp.SponsorBlock | Out-String)" -catcherror $_
                  }
                }
              }                    
            }
            if($result.key -eq 'volume' -and !$synchash.Spotify_WebPlayer_State.playbackstate -and !$synchash.Spotify_WebPlayer_State.current_track.id){
              if($result.value -ne $synchash.Volume_Slider.value -and ($synchash.WebBrowser_Youtube_URL -match 'youtube\.com' -or $synchash.WebBrowser_Youtube_URL -match 'youtu\.be') -and !$synchash.Volume_Slider.isMouseOver -and (!$synchash.vlc.IsPlaying -or $([string]$synchash.vlc.media.Mrl).StartsWith('dshow://'))){
                $volume = $result.value
                Write-EZLogs '>>>> Received volume change from Webbrowser Youtube content' -loglevel 2 -logtype Webview2
                if(-not [string]::IsNullOrEmpty($volume)){
                  $thisApp.Config.Media_Volume = $volume
                }elseif(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
                  $thisApp.Config.Media_Volume = $synchash.Volume_Slider.value        
                }else{
                  $thisApp.Config.Media_Volume = 100
                }
                if($synchash.vlc){
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $synchash.vlc.setVolume($thisApp.Config.Media_Volume)
                  }else{
                    $synchash.vlc.Volume = $thisApp.Config.Media_Volume
                  }
                }
                if($synchash.Volume_Slider.value -ne $thisApp.Config.Media_Volume){
                  $synchash.Volume_Slider.value = $thisApp.Config.Media_Volume
                }
                if($synchash.VideoView_Mute_Icon){
                  if($synchash.Volume_Slider.value -ge 75){
                    $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
                  }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
                    $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
                  }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
                    $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
                  }elseif($synchash.Volume_Slider.value -le 0){
                    $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
                  }
                }
              }
            }
            if($result.key -eq 'videojsplayer'){
              Write-EZLogs ">>>> Received webbrowser event for videojsplayer - source $($result.value | Out-String)" -warning
            }          
            if($result.key -eq 'fullscreenbutton'){
              #TODO: Do something with fullscreen button event?
              #write-ezlogs "Webbrowser message received fullscreenbutton  : $($result.value)" -showtime -warning -LogLevel 2
              <#            if($synchash.WebBrowserAnchorable -and !$synchash.WebBrowserAnchorable.isFloating){
                  write-ezlogs "WebBrowser Not floating, floating then fullscreen"
                  $synchash.WebBrowserAnchorable.IsMaximized = $true
                  $synchash.WebBrowserAnchorable.float()
                  }elseif($synchash.WebBrowserAnchorable.isFloating -and $synchash.WebBrowserFloat.WindowState -eq 'Maximized'){
                  write-ezlogs "WebBrowser Floating, maximized, setting to normal"
                  $synchash.WebBrowserFloat.WindowState -eq 'Normal'
                  }elseif($synchash.WebBrowserAnchorable.isFloating -and $synchash.WebBrowserFloat.WindowState -ne 'Maximized'){
                  write-ezlogs "WebBrowser Floating, maximized, setting to normal"
                  $synchash.WebBrowserFloat.WindowState -eq 'Maximized'
              }#> 
            }                                              
          }   
        }catch{
          Write-EZLogs 'An exception occurred in WebBrowser WebMessageReceived event' -showtime -catcherror $_
        } 
    })
  }catch{
    Write-EZLogs 'An exception occurred in Initialize-WebBrowser' -showtime -catcherror $_
  }finally{
    if($Initialize_WebBrowser_Measure){
      $Initialize_WebBrowser_Measure.stop()
      write-ezlogs "Initialize_WebBrowser_Measure" -PerfTimer $Initialize_WebBrowser_Measure -GetMemoryUsage:$thisApp.Config.Memory_perf_measure
      $Initialize_WebBrowser_Measure = $Null
    }
  }
}
#---------------------------------------------- 
#endregion Initialize-WebBrowser Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-ChatView Function
#----------------------------------------------
Function Initialize-ChatView
{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    [string]$chat_url
  ) 
  try{
    #chat_webview2
    Write-EZLogs '>>>> Adding initializing new Chat Webview2 instance' -showtime -logtype Webview2
    $synchash.chat_WebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
    $synchash.chat_WebView2.Name = 'chat_WebView2'
    $synchash.chat_WebView2.MaxWidth = $synchash.chat_WebView2.MaxWidth
    $synchash.chat_WebView2.Visibility = 'hidden' 
    $synchash.chat_WebView2.VerticalAlignment = 'Stretch'
    if($synchash.ChatWebview2_Grid.children -notcontains $synchash.chat_WebView2){
      Write-EZLogs '>>>> Adding Chat_Webview2 to chatwebview2_grid' -showtime -Dev_mode -logtype Webview2
      $null = $synchash.ChatWebview2_Grid.addchild($synchash.chat_WebView2)
    }
    if($synchash.WebView2Env.IsCompleted){
      Write-EZLogs ">>>> WebView2Env already initialized - UserDataFolder: $($synchash.WebView2Env.Result.UserDataFolder)" -showtime -logtype Webview2
      $synchash.chat_WebView2.EnsureCoreWebView2Async($synchash.WebView2Env.Result)
    }else{
      $synchash.chatWebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
      $synchash.chatWebView2Options.IsCustomCrashReportingEnabled = $true
      $synchash.chatWebView2Options.AdditionalBrowserArguments = '--edge-webview-enable-builtin-background-extensions --Disable-features=HardwareMediaKeyHandling,OverscrollHistoryNavigation,msExperimentalScrolling'
      $synchash.WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
        [String]::Empty, [IO.Path]::Combine( [String[]]($($thisApp.config.Temp_Folder), 'Webview2') ), $synchash.chatWebView2Options
      )
      if(!$synchash.chat_WebView2.CoreWebView2){
        $synchash.WebView2Env.GetAwaiter().OnCompleted(
          [Action]{
            try{
              if($thisApp.Config.Dev_mode){Write-EZLogs "Initialzing new WebView2Env: $($synchash.WebView2Env | Out-String)" -showtime -logtype Webview2 -Dev_mode}
              $synchash.chat_WebView2.EnsureCoreWebView2Async($synchash.WebView2Env.Result)
            }catch{
              Write-EZLogs 'An exception occurred inintializing corewebview2 enviroment' -showtime -catcherror $_
            }
          }
        )
      }
    }

    $synchash.chat_WebView2.Add_NavigationCompleted(
      [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
        $event = $args[1]
        try{
          Write-EZLogs '>>>> chat_WebView2 CoreWebView2InitializationCompleted' -showtime -logtype Webview2
          if($event.isSuccess){
            if(!$synchash.Chat_Twitch_Emotes_Script){
              $synchash.Chat_Twitch_Emotes_Script = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Twitch\twitch-bttv.js")
            }
            Write-EZLogs ' | Executing Chat_Twitch_BTTV_Script' -showtime -logtype Webview2
            $synchash.chat_WebView2.ExecuteScriptAsync(
              $synchash.Chat_Twitch_Emotes_Script
            )
            Write-EZLogs " | Chat_WebView2.CoreWebView2.DocumentTitle: $($synchash.chat_WebView2.CoreWebView2.DocumentTitle)" -loglevel 2 -logtype Webview2 
            if($thisApp.Config.Dev_mode){
              Write-EZLogs "chat_WebView2.CoreWebView2: $($synchash.chat_WebView2.CoreWebView2 | Select-Object * | Out-String)" -loglevel 2 -logtype Webview2 -Dev_mode  
              Write-EZLogs "chat_WebView2.CoreWebView2.Environment: $($synchash.chat_WebView2.CoreWebView2.Environment | Out-String)" -loglevel 2 -logtype Webview2 -Dev_mode
              Write-EZLogs "chat_WebView2.CoreWebView2.Settings: $($synchash.chat_WebView2.CoreWebView2.Settings | Select-Object * | Out-String)" -loglevel 2 -logtype Webview2 -Dev_mode   
            }  
          }else{
            Write-EZLogs "Chat_WebView2 Navigation Completed but without success --  WebErrorStatus: $($event.WebErrorStatus) -- HttpStatusCode: $($event.HttpStatusCode)" -showtime -warning -logtype Webview2
          }        
        }catch{
          Write-EZLogs 'An exception occurred in chat_WebView2.Add_NavigationCompleted' -showtime -catcherror $_
        }
      }
    ) 
     
    $synchash.chat_WebView2.Add_CoreWebView2InitializationCompleted(
      [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{  
        $event = $args[1]
        if($event.isSuccess){
          try{
            [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.chat_WebView2.CoreWebView2.Settings
            $Settings.AreDefaultContextMenusEnabled  = $true
            $Settings.AreDefaultScriptDialogsEnabled = $false
            $Settings.AreDevToolsEnabled             = $true
            $Settings.AreHostObjectsAllowed          = $true
            $Settings.IsBuiltInErrorPageEnabled      = $true
            $Settings.IsScriptEnabled                = $true
            $Settings.IsStatusBarEnabled             = $false
            $Settings.IsWebMessageEnabled            = $true
            $Settings.IsZoomControlEnabled           = $false  
            $Settings.IsGeneralAutofillEnabled       = $false
            $Settings.IsPasswordAutosaveEnabled      = $false
            $Settings.AreBrowserAcceleratorKeysEnabled = $thisApp.Config.Dev_mode
            $Settings.IsSwipeNavigationEnabled = $false
            $synchash.chat_WebView2.CoreWebView2.AddWebResourceRequestedFilter('*', [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All)     
            if($thisApp.Config.Chat_WebView2_Cookie){           
              $twilight_user_cookie = $synchash.chat_WebView2.CoreWebView2.CookieManager.CreateCookie('twilight-user', $thisApp.Config.Chat_WebView2_Cookie, '.twitch.tv', '/')
              $twilight_user_cookie.IsSecure = $true
              $synchash.chat_WebView2.CoreWebView2.CookieManager.AddOrUpdateCookie($twilight_user_cookie)    
            } 
          }catch{
            Write-EZLogs 'An exception occurred in CoreWebView2InitializationCompleted Event' -showtime -catcherror $_
          } 
          $synchash.chat_WebView2.CoreWebView2.add_WebResourceRequested({
              [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e = $args[1]
              try{
                $Cookies = ($e.Request.Headers | Where-Object {$_.key -eq 'cookie'}).value
                if($Cookies){
                  $Cookies = $Cookies -split ';'
                  $twilight_user = $Cookies.Where({$_ -match 'twilight-user=(?<value>.*)'})   
                  if($twilight_user){
                    $existin_twilight_user = ([regex]::matches($twilight_user,  'twilight-user=(?<value>.*)') | & { process {$_.groups[1].value}})
                    $thisApp.Config.Chat_WebView2_Cookie = $existin_twilight_user
                    if($thisApp.Config.Dev_mode){Write-EZLogs "Found and saving existing twilight_user $($existin_twilight_user | Out-String)" -showtime -logtype Webview2 -Dev_mode}   
                  }
                }
              }catch{
                Write-EZLogs 'An exception occurred in CoreWebView2 WebResourceRequested Event' -showtime -catcherror $_
              }
          })
          try{
            if(Test-URL $synchash.ChatView_URL){
              Write-EZLogs ">>>> Navigating ChatView with CoreWebView2.NavigateToString: $($chat_url)" -logtype Webview2
              $synchash.chat_WebView2.CoreWebView2.Navigate($synchash.ChatView_URL)     
            }
            $synchash.chat_WebView2.CoreWebView2.MemoryUsageTargetLevel = 'Low'
          }catch{
            Write-EZLogs "An exception occurred navigating to $($synchash.ChatView_UR)" -catcherror $_
          }
        }else{
          Write-EZLogs "WebBrowser chat_WebView2 Initialization Completed but without success - InitializationException: $($event.InitializationException.Message) - InnerException: $($event.InitializationException.InnerException)- StackTrace: $($event.InitializationException.StackTrace)" -warning -logtype Webview2
        }
       
      }
    )
    $synchash.chat_WebView2.add_WebMessageReceived({
        try{
          $result = $args.WebMessageAsJson | ConvertFrom-Json
          #write-ezlogs "chat_WebView2 message received: $($result.value | out-string)" -showtime
        }catch{
          Write-EZLogs 'An exception occurred in chat_Webview2 WebMessageReceived event' -showtime -catcherror $_
        }
    })
  }catch{
    Write-EZLogs 'An exception occurred creating chatwebview2 Enviroment' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Initialize-ChatView Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-WebNavigation
#----------------------------------------------
Function Start-WebNavigation{
  [CmdletBinding()]
  Param(
    $uri,
    $synchash,
    $thisScript,
    [string]$urihtml,
    [switch]$No_YT_Embed,
    [switch]$RawUrl,
    $thisApp,
    $WebView2
  ) 
  try{

    if($uri){
      Write-EZLogs ">>>> Navigating to URL $uri - Webview2: $($WebView2.name)" -showtime -color cyan -linesbefore 1 -logtype Webview2
      if(!(Test-URL -address $uri) -and !$RawUrl){
        if($uri -notmatch 'https://'){
          $uri = "https://$($uri)"
        }
      }
      if($thisApp.Config.Spotify_WebPlayer){
        [uri]$synchash.Spotify_WebPlayer_HTML = "$($thisApp.Config.Current_Folder)\Resources\Spotify\SpotifyWebPlayerTemplate.html"
      }
      if($uri -match 'youtube\.com' -or $uri -match 'youtu\.be' -and $WebView2.Name -ne 'WebBrowser'){
        Write-EZLogs ' | URL is of type Youtube' -logtype Webview2
        $Youtube = Get-YoutubeURL -thisApp $thisApp -URL $uri -APILookup
        if($Youtube.playlist_id){
          if($thisApp.Config.Use_invidious){            
            #$uri = "https://yewtu.be/embed/videoseries?list=$($Youtube.playlist_id)`&autoplay=1"
            #$uri = "https://invidious.nerdvpn.de/embed/videoseries?list=$($Youtube.playlist_id)`&autoplay=1"
            $uri = "https://invidious.jing.rocks/embed/videoseries?list=$($Youtube.playlist_id)`&autoplay=1"          
            $synchash.Use_invidious_url = $uri            
          }else{
            if($No_YT_Embed -or $Youtube.id){
              if($Youtube.id){
                $uri = "https://www.youtube.com/watch?v=$($Youtube.id)&list=$($Youtube.playlist_id)`&autoplay=1&enablejsapi=1"
              }else{
                $uri = "https://www.youtube.com/watch/videoseries?list=$($Youtube.playlist_id)`&autoplay=1&enablejsapi=1"
              }              
              $synchash.Youtube_WebPlayer_retry = $null
            }else{
              $uri = "https://www.youtube.com/embed/videoseries?list=$($Youtube.playlist_id)`&autoplay=1&enablejsapi=1"
            } 
            if($Youtube.PlaylistIndex){
              $uri = $uri + "&index=$($Youtube.PlaylistIndex)"
            }
            if($Youtube.PlayerParams -and $uri -notmatch '\&pp='){
              $uri = $uri + "&pp=$($Youtube.PlayerParams)"
            }
          }
        }elseif($Youtube.id){
          if($thisApp.Config.Use_invidious -and $uri -notmatch 'tv\.youtube\.com'){
            #$uri = "https://yewtu.be/embed/$($Youtube.id)`&autoplay=1"
            #$uri = "https://invidious.nerdvpn.de/embed/$($Youtube.id)`&autoplay=1"
            $uri = "https://invidious.jing.rocks/embed/$($Youtube.id)`&autoplay=1"           
            $synchash.Use_invidious_url = $uri
          }elseif($uri -notmatch 'tv\.youtube\.com'){
            if($No_YT_Embed){
              $uri = "https://www.youtube.com/watch/$($Youtube.id)`?&autoplay=1&enablejsapi=1"
              $synchash.Youtube_WebPlayer_retry = $null    
            }else{
              $uri = "https://www.youtube.com/embed/$($Youtube.id)`?&autoplay=1&enablejsapi=1"
            }
          }elseif($uri -match 'tv\.youtube\.com' -and $uri -notmatch '\&autoplay=1'){
            $uri = "https://tv.youtube.com/watch/$($Youtube.id)`?&autoplay=1&enablejsapi=1"
          }
        }
      }elseif($uri -match 'spotify.com' -and $WebView2.Name -ne 'WebBrowser'){
        Write-EZLogs '>>>> URL is of type Spotify'
        if($uri -match 'open.spotify.com/track/' -or $uri -match 'open.spotify.com/episode/'){
          if($uri -match 'open.spotify.com/track/'){
            $spotify_id = ($($uri) -split('open.spotify.com/track/'))[1].trim()
            $type = 'track'
          }elseif($uri -match 'open.spotify.com/episode/'){
            $spotify_id = ($($uri) -split('open.spotify.com/episode/'))[1].trim()
            $type = 'episode'
          }          
          if($thisApp.Config.Spotify_WebPlayer){          
            try{
              $Spotify_accesstoken = (Get-SpotifyAccessToken -ApplicationName $thisApp.Config.App_name)         
            }catch{
              Write-EZLogs 'An exception occurred getting spotifyaccesstoken' -showtime -catcherror $_
            }
            if($synchash.Spotify_WebPlayer_HTML -and $Spotify_accesstoken){
              $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
              $device = $devices | Where-Object {$_.Name -match $thisApp.config.App_Name -and $_.is_active -eq $true}
              if(!$device){
                $device = $devices | Where-Object {$_.Name -match $thisApp.config.App_Name}
              }
              if($device.count -gt 1 -and $synchash.Spotify_WebPlayer.Deviceid){
                Write-EZLogs " | Multiple Spotify Devices returned, checking for existing Spotify_WebPlayer deviceid ($($synchash.Spotify_WebPlayer.Deviceid))" -logtype Webview2 -loglevel 2 -warning
                $device = $devices.Where({$_.id -eq $synchash.Spotify_WebPlayer.Deviceid})
              }
              Write-EZLogs " | Spotify Devices ($($device))" -logtype Webview2 -loglevel 2
              if($device.id -and $synchash.Spotify_WebPlayer){               
                $synchash.Spotify_WebPlayer.Deviceid = $device.id
              }else{
                $synchash.Spotify_WebPlayer = @{}
              }
              $synchash.Spotify_WebPlayer.SpotifyToken = $Spotify_accesstoken
              $synchash.Spotify_WebPlayer.SpotifyId = $spotify_id
              $synchash.Spotify_WebPlayer.Spotifytype = $type
              $synchash.Spotify_WebPlayer.URL = $uri
              $synchash.Session_SpotifyToken = $Spotify_accesstoken
              $synchash.Session_SpotifyId = $spotify_id
              $synchash.Session_Spotifytype = $type
              $synchash.Spotify_WebPlayer.is_started = $false
              [uri]$uri = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer.Player_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
            }else{
              $uri = "https://open.spotify.com/embed/$type/$spotify_id"
              $synchash.Spotify_WebPlayer = $null
              $synchash.Spotify_WebPlayer_URL = $uri
              $synchash.Session_SpotifyId = $null
              $synchash.Session_Spotifytype = $null
              $synchash.Spotify_WebPlayer_HTML = $null
              $synchash.Session_SpotifyToken = $null
            }          
          }           
        }elseif($uri -match 'open.spotify.com/playlist/'){
          $spotify_id = ($($uri) -split('open.spotify.com/playlist/'))[1].trim()
          if($thisApp.Config.Spotify_WebPlayer){
            try{
              $Spotify_accesstoken = (Get-SpotifyAccessToken -ApplicationName $thisApp.Config.App_name)            
            }catch{
              Write-EZLogs 'An exception occurred getting spotifyaccesstoken' -showtime -catcherror $_
            }
            if($synchash.Spotify_WebPlayer_HTML -and $Spotify_accesstoken){
              $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
              $device = $devices | Where-Object {$_.is_active -eq $true}
              if(!$device){
                $device = $devices | Where-Object {$_.Name -match $thisApp.config.App_Name}
              }
              if($device.count -gt 1 -and $synchash.Spotify_WebPlayer.Deviceid){
                Write-EZLogs " | Multiple Spotify Devices returned, checking for existing Spotify_WebPlayer deviceid ($($synchash.Spotify_WebPlayer.Deviceid))" -logtype Webview2 -loglevel 2 -warning
                $device = $devices | Where-Object {$_.id -eq $synchash.Spotify_WebPlayer.Deviceid}
              }
              if($device.id){
                $synchash.Spotify_WebPlayer.Deviceid = $device.id
              }else{
                $synchash.Spotify_WebPlayer = @{}
              }
              $synchash.Spotify_WebPlayer.SpotifyToken = $Spotify_accesstoken
              $synchash.Spotify_WebPlayer.SpotifyId = $spotify_id
              $synchash.Spotify_WebPlayer.Spotifytype = 'playlist'
              $synchash.Spotify_WebPlayer.URL = $uri
              $synchash.Session_SpotifyToken = $Spotify_accesstoken
              $synchash.Session_SpotifyId = $spotify_id
              $synchash.Session_Spotifytype = 'playlist'
              $synchash.Spotify_WebPlayer.is_started = $false
              [uri]$uri = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer.Player_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
            }else{
              $uri = "https://open.spotify.com/embed/track/$spotify_id"
              $synchash.Spotify_WebPlayer = $null
              $synchash.Spotify_WebPlayer_URL = $uri
              $synchash.Session_SpotifyId = $null
              $synchash.Session_Spotifytype = $null
              $synchash.Spotify_WebPlayer_HTML = $null
              $synchash.Session_SpotifyToken = $null
            }          
          }          
        }
        if($synchash.Spotify_WebPlayer.Deviceid){
          Write-EZLogs ">>>> Starting Spotify Playback for track (spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)) -and deviceid ($($synchash.Spotify_WebPlayer.Deviceid)) - synchash.WebView2.CoreWebView2: $($synchash.WebView2.CoreWebView2)" -logtype Webview2 -loglevel 2
          if($synchash.WebView2.CoreWebView2 -ne $null){
            $Spotify_StartPlayback = @"
try{
  console.log('Executing Playback for Spotify device: $($synchash.Spotify_WebPlayer.Deviceid) - URL: spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)');
try {
  $.ajax({
   url: "https://api.spotify.com/v1/me/player/play?device_id=$($synchash.Spotify_WebPlayer.Deviceid)",
   type: "PUT",
   data: '{"uris": ["spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)"]}',
   beforeSend: function(xhr){xhr.setRequestHeader('Authorization', 'Bearer ' + '$($synchash.Spotify_WebPlayer.SpotifyToken)' );},
   success: function(data) { 
     console.log('Started Playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId) - deviceid: $($synchash.Spotify_WebPlayer.Deviceid)');
     console.log(data)
   }
  });
} catch (error) {
  console.error('An exception occurred attempting to start playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Session_SpotifyId)', error);
}
  console.log('Setting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
  SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100));
} catch (error) {
  console.error('An exception occurred attempting to start playback for spotify:$($synchash.Spotify_WebPlayer.Spotifytype):$($synchash.Spotify_WebPlayer.SpotifyId)', error);
}

"@
            Write-EZLogs "| Executing Spotify_StartScript_Webview2" -logtype Webview2 -loglevel 2
            $synchash.WebView2.ExecuteScriptAsync(
              $Spotify_StartPlayback
            )
            $synchash.Spotify_WebPlayer.is_started = $true
          }
          #$synchash.Spotify_WebPlayer.is_started = $true
          return
        }
      }
      if($WebView2 -ne $null -and $WebView2.CoreWebView2 -ne $null){ 
        if($urihtml){ 
          Write-EZLogs ">>>> Navigating with CoreWebView2.NavigateToString: $($urihtml)"  -logtype Webview2
          $WebView2.CoreWebView2.NavigateToString($urihtml)
        }else{
          Write-EZLogs ">>>> Navigating with CoreWebView2.Navigate: $($uri)" -logtype Webview2
          if($WebView2.name -eq 'WebView2'){
            Write-EZLogs "| Setting Spotify_WebPlayer_URL" -logtype Webview2
            $synchash.Spotify_WebPlayer_URL = $uri
          }
          $WebView2.CoreWebView2.Navigate($uri)
        }       
      }else{
        if($WebView2.name -eq 'WebBrowser'){
          $synchash.WebBrowser_url = $uri
        }     
        if($urihtml){
          Write-EZLogs " | Adding CoreWebView2InitializationCompleted with navigate to url: $($urihtml)" -logtype Webview2
          $synchash.Youtube_WebPlayer_URL = $urihtml
          $synchash.Spotify_WebPlayer_URL = $urihtml
        }elseif($WebView2.name -eq 'YoutubeWebview2'){
          Write-EZLogs " | Setting URL variable for Youtubewebview2 to navigate to url: $($uri)" -logtype Webview2 
          $synchash.Youtube_WebPlayer_URL = $uri
        }else{
          Write-EZLogs " | Setting URL variable for webview2 to navigate to url: $($uri)" -logtype Webview2
          $synchash.Youtube_WebPlayer_URL = $uri
          $synchash.Spotify_WebPlayer_URL = $uri
        }                      
      } 
    }else{
      Write-EZLogs "The provided $uri was null or invalid!" -showtime -warning -logtype Webview2
    }
  }catch{
    Write-EZLogs 'An exception occurred in Start-WebNavigation' -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Start-WebNavigation
#----------------------------------------------
Export-ModuleMember -Function @('Initialize-WebPlayer', 'Initialize-WebBrowser', 'Initialize-ChatView', 'Initialize-YoutubeWebPlayer', 'Start-WebNavigation', 'Add-Webview2Extension','Get-Webview2Extensions')