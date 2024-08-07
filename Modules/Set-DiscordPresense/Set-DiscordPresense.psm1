<#
    .Name
    Set-DiscordPresense

    .Version 
    0.1.0

    .SYNOPSIS
    Utilizes discordrpc powershell module for setting up custom rich client integration with Discord 

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
    Appid: 1012233037855080448
    Public Key: 309ae4705a8f119a3c4192f51c24b3ae9452a23dd95c47a6f7df8ecea39e690a

#>

#---------------------------------------------- 
#region Set-DiscordPresense Function
#----------------------------------------------
function Set-DiscordPresense {
  <#
      .SYNOPSIS
      Sets discord presense info for playing media.

      .EXAMPLE
      Set-DiscordPresense -synchash $synchash -media $synchash.Current_playing_media -thisapp $thisApp
  #>
  [CmdletBinding()]
  Param (
    $thisApp,
    $synchash,
    $media = $synchash.Current_playing_media,
    [switch]$Start,
    [switch]$update,
    [switch]$Startup,
    [switch]$Stop,
    [switch]$runspace,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog
  )

  if($Startup){ 
    $synchash.DSClientTimer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Normal)
    $synchash.DSClientTimer.tag = [PSCustomObject]::new(@{
        'media' = $media
        'Start' = $Start
        'update' = $update
        'Stop' = $Stop
    })
    $synchash.DSClientTimer.add_Tick({
        try{
          $start = $this.tag.Start
          $stop = $this.tag.Stop
          $media = $this.tag.media
          $update = $this.tag.update
          $synchash = $synchash
          $thisapp = $thisapp
          if($Start){   
            #Build variables for dsclient params from provided media
            if($thisApp.Config.Dev_mode){write-ezlogs "| Media for Discord Presense $($media | out-string)" -showtime -Dev_mode -logtype Discord }
            switch ($media) {
              {$_.source -match 'Spotify' -or $_.url -match 'spotify:'} {
                $SmallImageKey = 'spotify'
                $SmallImageText = 'Spotify'
                if($media.title){
                  $details = "Listening to: $($media.title)"
                } 
                if($media.Artist){
                  $dsState = "by $($media.Artist)"
                }elseif($media.Artist_Name){
                  $dsState = "by $($media.Artist_Name)"
                }
                $Label = "Listen on Spotify"
                if($media.Spotify_id){
                  $url = "https://open.spotify.com/track/$($media.Spotify_id)?si="
                }elseif($media.track_id){
                  $url = "https://open.spotify.com/track/$($media.track_id)?si"
                }elseif($media.Url -match 'spotify\:'){
                  $url = ($media.Url) -replace '\\'
                }elseif($media.uri){
                  $url = $media.uri
                }elseif($Media.Playlist_URL){
                  $url = $Media.Playlist_URL
                }
              }
              {$_.url -match 'twitch\.tv'} {
                $SmallImageKey = 'twitch'
                $SmallImageText = 'Twitch'
                $details = "Watching: $($media.artist)"
                if($media.Stream_title){
                  [String]$dsState = "$($($media.Stream_title).trim())"
                }elseif($synchash.streamlink.title){
                  [String]$dsState = "$($($synchash.streamlink.title).trim())"
                }
                if(-not [string]::IsNullOrEmpty($media.Stream_msg)){
                  [String]$dsState = "$($media.Stream_msg): $dsState"
                }elseif(-not [string]::IsNullOrEmpty($synchash.streamlink.game_name)){
                  [String]$dsState = "$($synchash.streamlink.game_name): $dsState"
                }
                
                $Label = "Watch on Twitch"
                if($Media.url){
                  $url = $Media.url
                }elseif($media.uri){
                  $url = $media.uri
                }
                break
              }
              {$_.source -match 'Youtube' -or $_.url -match 'youtube\.com' -or $_.url -match 'youtu\.be'} {
                if($_.source -match 'YoutubeTV' -or $_.url -match 'tv\.youtube\.com'){
                  $SmallImageKey = 'youtubetv'
                  $SmallImageText = 'Youtube TV'
                  $Label = "Watch on Youtube TV"
                }else{
                  $SmallImageKey = 'youtube'
                  $SmallImageText = 'Youtube'
                  $Label = "Watch on Youtube"
                }
                if($synchash.Youtube_WebPlayer_title){
                  $details = "Watching: $($synchash.Youtube_WebPlayer_title)"
                }elseif($media.title){
                  $details = "Watching: $($media.title)"
                }
                if($media.artist){
                  $dsState = "on Channel: $($media.Artist)"
                }elseif($media.Playlist){
                  $dsState = "on Channel: $($media.Playlist)"
                }else{
                  $dsState = "on $SmallImageText"
                }
                if($Media.url -match 'soundcloud\.com'){
                  $SmallImageKey = 'soundcloud'
                  $SmallImageText = 'SoundCloud'
                  $Label = "Listen on SoundCloud"
                  $details = "Listening to: $($media.title)"
                  $dsState = "by $($media.Artist)"
                }
                if($Media.url){
                  $url = $Media.url
                }elseif($media.Uri){
                  $url = $media.Uri
                }
                break
              }
              {$_.source -eq 'Local'} {
                $SmallImageKey = 'local'
                $SmallImageText = 'Local Media'
                if($media.hasVideo -or $synchash.vlc.VideoTrackCount -gt 0){
                  $details = "Watching: $($media.Title)"
                  $dsState = "by $($media.Artist)"
                }else{
                  $details = "Listening to: $($media.Title)"
                  $dsState = "by $($media.Artist)"
                }         
                $label = $null               
                break
              }
              'Default' {
                $SmallImageKey = 'other'
                $SmallImageText = ''
                break
              }
            }

            $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
            $pattern = "[™`�$illegal]"
            #if($dsState -match $pattern){
            #[int]$character_Count = ($dsState | measure-object -Character -ErrorAction SilentlyContinue).Characters
            #write-ezlogs "Cleaning illegal characters from State: $($dsState | out-string)" -showtime -warning -logtype Discord
            #$dsState = $dsState.replace('PACKED DAY!','').replace('(','').replace(')','').replace('#','').replace('&','').replace('ad','').trim()
            #$dsState = ([Regex]::Replace($dsState, $pattern, '')).trim()              
            #write-ezlogs "| Cleaned State: $($dsState | out-string)" -showtime -warning -logtype Discord
            if($dsState){
              $Chars = ($dsState | measure-object -Character).Characters
              if($Chars -ge 128){
                $dsState = "$([string]$dsState.subString(0, [System.Math]::Min(124, $dsState.Length)).trim())..." 
                write-ezlogs "[Set-DiscordPresense] Provided state string is $($Chars) characters long (128 max allowed) - trimming to: $dsState" -warning -logtype Discord
              }
            }
            #build detail string and potentially label/url
            if(-not [string]::IsNullOrEmpty($url) -and -not [string]::IsNullOrEmpty($label)){
              #set params for dsclient
              $params = @{
                ApplicationID  = "1012233037855080448"
                LargeImageKey  = "samson_icon_notext1"                
                LargeImageText = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)"
                SmallImageKey  = $SmallImageKey
                SmallImageText = $SmallImageText
                Label          = $Label
                Url            = $url
                Details        = $details
                State          = "$($dsState)"
                LoggerType     = "ConsoleLogger"
                LoggerLevel    = "Info"
                TimerRefresh   = 1
                Start          = "Now"
                <#                  UpdateScript   = { 
                    try{

                    }catch{
                    write-ezlogs "An exeception occurred in dsclient update script" -showtime -catcherror $_
                    }
                    #Update-DSAsset -LargeImageText "Timer worked!" -SmallImageText "Lvl 10"
                }.GetNewClosure()#>
              }
              #$buttons = New-DSButton -Label $url -Url $url
            }else{
              $buttons = $Null
              $label = $null
              #set params for dsclient
              $params = @{
                ApplicationID  = "1012233037855080448"
                LargeImageKey  = "samson_icon_notext1"
                LargeImageText = "$($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)"
                SmallImageKey  = $SmallImageKey
                SmallImageText = $SmallImageText
                Details        = $details
                State          = "$($dsState)"
                LoggerType     = "ConsoleLogger"
                LoggerLevel    = "Info"
                TimerRefresh   = 1
                Start          = "Now"
                <#                  UpdateScript   = { 
                    try{
                    }catch{
                    write-ezlogs "An exeception occurred in dsclient update script" -showtime -catcherror $_
                    }
                }#>
              }
            }
            if($synchash.DSClient.IsInitialized){
              try{
                write-ezlogs "[Set-DiscordPresense] >>>> Clearing presence for existing DSClient $($synchash.DSClient.CurrentPresence.Details)" -showtime -logtype Discord -LogLevel 2
                #[void]$synchash.DSClient.ClearPresence()
                [void](Stop-DSClient)
              }catch{
                write-ezlogs "An exception occurred disposing dsclient $($synchash.DSClient | out-string)" -showtime -catcherror $_
              }
            }

            #start her up
            write-ezlogs ">>>> Starting new Discord presense: State: $($details) - Details: $($dsState)" -showtime -LogLevel 2 -logtype Discord
            $synchash.DSClient = Start-DSClient @params
            if($Buttons){
              $params = @{
                Buttons   = $Buttons
                Details   = $details
                State     = "$($dsState)"
              }
              Update-DSRichPresence @params
            }
          }elseif($stop){
            #Stop an existing Dsclient
            if($synchash.DSClient.IsInitialized){
              try{
                write-ezlogs ">>>> Stopping existing DSClient $($synchash.DSClient.CurrentPresence.Details)" -showtime -logtype Discord -LogLevel 2
                Stop-DSClient     
                $synchash.DsClient = $null
              }catch{
                write-ezlogs "An exception occurred diposing dsclient $($synchash.DSClient | out-string)" -showtime -catcherror $_
              }
            }else{
              write-ezlogs "No DSClient is currently running" -showtime -warning -logtype Discord -LogLevel 2
            }     
          }
        }catch{
          write-ezlogs "An exception occurred in Set-DiscordPresense - params $($params.state | out-string) - dsclient $($synchash.DSClient | out-string)" -showtime -catcherror $_
        }finally{
          $this.tag = $Null
          $this.Stop()
        }               
    })
    if($Start){
      $synchash.DSClientTimer.start()
    }
  }else{
    if($synchash.DSClientTimer -and !$synchash.DSClientTimer.IsEnabled){
      $synchash.DSClientTimer.tag = [PSCustomObject]::new(@{
          'media' = $media
          'Start' = $Start
          'Stop' = $Stop
          'update' = $update
      })
      $synchash.DSClientTimer.start()
    }else{
      write-ezlogs "No discordclient timer has been created, haulting further actions" -showtime -warning -logtype Discord
    }
  }
}
#---------------------------------------------- 
#endregion Set-DiscordPresense Function
#----------------------------------------------
Export-ModuleMember -Function @('Set-DiscordPresense')