<#
    .Name
    Get-TwitchAPI

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves data from Twitch API for stream/broadcast status..etc 

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
#region Get-TwitchAPI Function
#----------------------------------------------
function Get-TwitchAPI
{
  Param (
    [string]$StreamName,
    [switch]$Import_Profile,
    $thisApp,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $all_installed_apps,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog = $thisApp.Config.Verbose_Logging
  )
  Add-Type -AssemblyName System.Web
  if($Verboselog){write-ezlogs "#### Checking Twitch Stream $StreamName ####" -enablelogs -color yellow -linesbefore 1 -logfile:$log}
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $Twitch_API_Info_File = "$($thisApp.config.Current_Folder)\Resources\API\Twitch-API-Config.xml"
  if(([System.IO.File]::Exists($Twitch_API_Info_File))){
    if($VerboseLog){write-ezlogs ">>>> Importing Twitch API Config file $Twitch_API_Info_File" -showtime -color cyan -logfile:$log}
    $twitch_Api_Config = Import-Clixml $Twitch_API_Info_File   
    if($twitch_Api_Config.ClientSecret -and $twitch_Api_Config.ClientID){
      #$Twitch_ClientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($twitch_Api_Config.ClientSecret | ConvertTo-SecureString))))
      #$Twitch_clientId = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($twitch_Api_Config.ClientID | ConvertTo-SecureString))))
      $token_expires = $twitch_Api_Config.expires_in 
      if($token_expires -le (Get-date) -or !$twitch_Api_Config.ClientToken){
        if($thisApp.Config.Verbose_logging){write-ezlogs "Refreshing twitch token as it expires $($token_expires)" -showtime -logfile:$log}
        $authurl = "https://id.twitch.tv/oauth2/token?client_id=$($twitch_Api_Config.ClientID)&client_secret=$($twitch_Api_Config.ClientSecret)&grant_type=client_credentials"
        try{
          $tokenInfo = Invoke-RestMethod -Uri $authurl -Method Post -UseBasicParsing
        }
        catch{
          write-ezlogs "[ERROR] An exception occurred getting authorization token for Twitch API" -showtime -catcherror $_ -logfile:$log  
        }          
        $token = $tokenInfo.access_token   
        $token_date = Get-date
        $token_expires = $token_date.AddSeconds($tokenInfo.expires_in)   
        $twitch_Api_Config.ClientToken = $token      
        $twitch_Api_Config.token_date = $token_date  
        $twitch_Api_Config.expires_in = $token_expires
        if($tokenInfo.access_token){
          if($thisApp.Config.Verbose_logging){write-ezlogs " | Twitch Token sucessfully refreshed - Expires: $($token_expires)" -showtime -logfile:$log}
          $twitch_Api_Config | Export-Clixml $Twitch_API_Info_File -Force 
        }else{
          write-ezlogs "[Get-TwitchAPI] Unable to refresh Twitch Token! ($tokenInfo)" -showtime -warning -logfile:$log
          $get_twitch = $false
        }             
      }else{
        if($thisApp.Config.Verbose_logging){write-ezlogs " | Twitch Token is valid - Expires: $($token_expires)" -showtime -logfile:$log}
        $token = $twitch_Api_Config.ClientToken
      }
      $get_twitch = $true 
    }else{
      write-ezlogs "[Get-TwitchAPI] Unable to get API credentials! Cannot use Twitch API" -showtime -warning -logfile:$log
      $get_twitch = $false
    }
  
  }else{
    $get_twitch = $false
  }
  
  if($get_twitch -and $StreamName){
    #Get twitch streamers
    #"https://api.twitch.tv/helix/users?login=Pepp"
    #'https://api.twitch.tv/helix/users/follows?to_id=<user ID>'
    $headers = @{
      "client-id"     = $twitch_Api_Config.ClientID
      "Authorization" = "Bearer $Token"
    }    
    $streamer_data  = Invoke-RestMethod "https://api.twitch.tv/helix/streams?user_login=$StreamName" -Method 'Get' -Headers $headers
    if($streamer_data){
      $encodedTitle = $Null  
      $user_data = Invoke-RestMethod "https://api.twitch.tv/helix/users?login=$StreamName" -Method 'Get' -Headers $headers
      #$encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($name)-SpotifyPlaylist")
      #$encodedTitle = [System.Convert]::ToBase64String($encodedBytes)       
      if($streamer_data.data.type){
        $type = $((Get-Culture).textinfo.totitlecase(($streamer_data.data.type).tolower()))
      }else{
        $type = $streamer_data.data.type
      }
      if($user_data.data){
        $profile_image_url = $user_data.data.profile_image_url
        $offline_image_url = $user_data.data.offline_image_url
        $description = $user_data.data.description
      }else{
        $profile_image_url = $Null
        $offline_image_url = $Null  
        $description = $Null   
      }
      if($VerboseLog){write-ezlogs ">>>> Found Stream $($streamer_data.data.user_name)" -showtime -color Cyan -logfile:$log}
      if($VerboseLog){write-ezlogs " | Type $($streamer_data.data.type)" -showtime -logfile:$log}
      if($VerboseLog){write-ezlogs " | Title $($streamer_data.data.title)" -showtime -logfile:$log}
      if($VerboseLog){write-ezlogs " | Description $description" -showtime -logfile:$log}                  
      $TwitchData = New-Object PsObject -Property @{
        'Title' = $streamer_data.data.title
        'User_id' = $streamer_data.data.user_id
        'user_login' = $streamer_data.data.user_login
        'user_name' = $streamer_data.data.user_name
        'game_name' = $streamer_data.data.game_name
        'type' = $type
        'description' = $description
        'profile_image_url' = $profile_image_url
        'offline_image_url' = $offline_image_url
        'started_at' = $streamer_data.data.started_at
        'viewer_count' = $streamer_data.data.viewer_count
        'thumbnail_url' = $streamer_data.data.thumbnail_url
      }
      #$null = $Available_Spotify_Media.Add($newRow)           
    }else{
      write-ezlogs "Unable to get data for stream ($StreamName)" -showtime -enablelogs -warning -logfile:$log
    }  
    return $TwitchData    
  }else{
    write-ezlogs "Unable to Authenticate with Twitch, cannot continue" -showtime -warning -logfile:$log
    return
  }
}
#---------------------------------------------- 
#endregion Get-TwitchAPI Function
#----------------------------------------------


#---------------------------------------------- 
#region Get-TwitchStatus Function
#----------------------------------------------
function Get-TwitchStatus
{
  Param (
    [string]$StreamName,
    $media,
    [switch]$CheckAll,
    [switch]$Use_runspace,
    $thisApp,
    $synchash,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $all_playlists,
    $all_installed_apps,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog
  ) 
  if($CheckAll){    
    if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Getting Status of all known Twitch Streams" -showtime -logfile:$log}      
    #$TwitchStreams = ($synchash.All_Youtube_Media | where {$_.Source -eq 'TwitchChannel'}).playlist_tracks
    #write-ezlogs ">>>> itemsource: $($syncHash.YoutubeTable.ItemsSource | out-string)"
    #write-ezlogs ">>>> youtubedatable: $($Youtube_Datatable.datatable | out-string)"
    try{
      [Collections.Generic.List[System.Data.DataTable]]$lookuplist = $Youtube_Datatable.datatable
      $TwitchStreams = ($lookuplist | where {$_.webpage_url -match 'twitch.tv'})
      $AllYoutube_Media_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Youtube_MediaProfile","All-Youtube_Media-Profile.xml")        
      if(-not [string]::IsNullOrEmpty($TwitchStreams) -and @($TwitchStreams).count -gt 0){       
        $checktwitch_scriptblock = {       
          if([System.IO.File]::Exists($AllYoutube_Media_Profile_File_Path)){
            if($thisApp.Config.Verbose_logging){write-ezlogs "| Importing Youtube Media Profile: $AllYoutube_Media_Profile_File_Path" -logfile:$log -showtime}
            [System.Collections.ArrayList]$Available_Youtube_Media = Import-CliXml -Path $AllYoutube_Media_Profile_File_Path 
            $playlists = Import-clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" 
            #$TwitchStreams = ($Available_Youtube_Media | where {$_.Source -eq 'TwitchChannel'}).playlist_tracks   
            $changes = 0             
            foreach($media in ($Available_Youtube_Media | where {$_.Source -eq 'TwitchChannel'}).playlist_tracks){
              try{
                $twitch_channel = $((Get-Culture).textinfo.totitlecase(([System.IO.Path]::GetFileNameWithoutExtension($media.webpage_url)).tolower()))
                if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Checking status of Twitch stream $twitch_channel -- $($Media.webpage_url) - Currently playing $($thisApp.Config.streamlink.User_Name)" -showtime -color cyan -logfile:$log}
                $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
                if($TwitchAPI.user_name -eq $thisApp.Config.streamlink.User_Name){
                  if($thisApp.Config.Verbose_logging){write-ezlogs "#### | Updating currently playing Twitch stream $twitch_channel -- View Count: $($TwitchAPI.viewer_count)" -showtime -color cyan -logfile:$log}
                   $thisApp.Config.streamlink = $TwitchAPI
                }
                if(!$TwitchAPI.type){
                  if($thisApp.Config.Verbose_Logging){write-ezlogs "| Twitch Channel $twitch_channel`: OFFLINE" -showtime -logfile:$log}
                  if($Media.Live_Status -ne 'Offline' -or $media.Status_Msg -ne ''){
                    write-ezlogs ">>>> Updating $($Media.title) with status Offline from $($Media.Live_Status)" -showtime -logfile:$log
                    #Update-Notifications -Level 'INFO' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -Message_color "Red" -thisApp $thisApp -synchash $synchash -Open_Flyout -No_runspace
                    Add-Member -InputObject $media -Name 'Live_Status' -Value 'Offline' -MemberType NoteProperty -Force
                    Add-Member -InputObject $media -Name 'Status_msg' -Value '' -MemberType NoteProperty -Force
                    Add-Member -InputObject $media -Name 'Stream_title' -Value "" -MemberType NoteProperty -Force
                    Add-Member -InputObject $media -Name 'thumbnail' -Value "" -MemberType NoteProperty -Force
                    $changes++
                  }  
                }elseif($TwitchAPI.type){
                  if($thisapp.Config.streamlink.type){
                    $thisapp.Config.streamlink = $TwitchAPI
                  }               
                  #$twitch_status = $streamlink_fetchjson | convertfrom-json
                  $twitch_status = $TwitchAPI.type
                  $twitch_channel = $TwitchAPI.User_Name           
                  if($twitch_status -ne $Media.Live_Status -or ("- $($TwitchAPI.game_name)" -ne $media.Status_msg)){
                    if($thisApp.Config.Verbose_Logging){write-ezlogs "| Twitch Channel $twitch_channel`: $((Get-Culture).textinfo.totitlecase(($twitch_status).toUpper()))" -showtime -logfile:$log}
                    write-ezlogs ">>>> Updating $($Media.title) with status $($twitch_status) from $($Media.Live_Status)" -showtime -logfile:$log
                    if($TwitchAPI.thumbnail_url){
                      $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
                    }else{
                      $thumbnail = ''
                    }
                    #Update-Notifications -Level 'INFO' -Message "Twitch Channel $twitch_channel`: $((Get-Culture).textinfo.totitlecase(($twitch_status).toUpper()))" -VerboseLog -Message_color "Red" -thisApp $thisApp -synchash $synchash -Open_Flyout -No_runspace
                    Add-Member -InputObject $Media -Name 'Live_Status' -Value $twitch_status -MemberType NoteProperty -Force
                    Add-Member -InputObject $media -Name 'Status_msg' -Value "- $($TwitchAPI.game_name)" -MemberType NoteProperty -Force  
                    Add-Member -InputObject $media -Name 'Stream_title' -Value "$($TwitchAPI.title)" -MemberType NoteProperty -Force     
                    Add-Member -InputObject $media -Name 'thumbnail' -Value $thumbnail -MemberType NoteProperty -Force 
                    $changes++                                 
                  }
                }
                if($changes -gt 0){               
                  $Playlist_profile = $playlists | where {$_.Playlist_tracks.webpage_url -eq $media.webpage_url} 
                  if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> playlist profile: $($Playlist_profile | out-string)" -showtime -color cyan -logfile:$log}
                  foreach($track in $Playlist_profile.Playlist_tracks){
                    if($track.webpage_url -eq $media.webpage_url){                 
                      $track.title = $Media.Title
                      if($thisApp.Config.Verbose_logging){
                        write-ezlogs " | Track Title: $($track.title)
                          | Media TItle: $($Media.title)
                          | Track Status: $($track.Status_msg)
                          | Media Status: $($Media.Status_msg)
                          | thumbnail: $($Media.thumbnail)   
                          | track.Playlist_File_Path: $($track.Playlist_File_Path)  
                        | Playlist_profile.Playlist_Path: $($Playlist_profile.Playlist_Path)" -logfile:$log 
                      }            
                      $track.Status_msg = $Media.Status_msg
                      $track.Live_Status = $Media.Live_Status
                      Add-Member -InputObject $track -Name 'thumbnail' -Value "$($Media.thumbnail)" -MemberType NoteProperty -Force
                      Add-Member -InputObject $track -Name 'Stream_title' -Value "$($Media.Stream_title)" -MemberType NoteProperty -Force 
                      if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -color cyan -logfile:$log}
                      if([System.IO.FIle]::Exists($track.Playlist_File_Path)){
                        if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> Saving updated playlist profile from track profile: $($track.Playlist_File_Path)" -showtime -color cyan -logfile:$log}
                        $Playlist_profile | Export-Clixml $track.Playlist_File_Path -Force
                      }elseif([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
                        if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan -logfile:$log}
                        $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
                      }         
                    }
                  }
                  $playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force 
                }
              }catch{
                write-ezlogs "An exception occurred in checktwitch_scriptblock" -showtime -catcherror $_ -logfile:$log
              }
            }
            if($changes -gt 0){
              try{
                write-ezlogs ">>>> Updating $($changes) changes for Twitch streams" -showtime -logfile:$log
                [System.Collections.ArrayList]$Available_Youtube_Media | Export-Clixml $AllYoutube_Media_Profile_File_Path -Force
                $synchash.update_status_timer.start() 
                #Import-Youtube -Youtube_playlists $thisApp.Config.Youtube_playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -thisApp $thisApp -use_Runspace
              }catch{
                write-ezlogs "An exception occurred executing Import-youtube" -showtime -catcherror $_ -logfile:$log
              } 
            }else{
              write-ezlogs "No changes were found for any Twitch Streams" -showtime -logfile:$log
            }                                                       
          }                                                      
        }.GetNewClosure()
        $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
        if($Use_runspace){
          Start-Runspace $checktwitch_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "checktwitch_runspace" -thisApp $thisApp -Script_Modules $Script_Modules
        }else{
          Invoke-Command -ScriptBlock $checktwitch_scriptblock
        }                            
      }else{
        write-ezlogs "Unable to find any valid twitch media!" -showtime -warning -logfile:$log
      }
      #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -startup -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
    }catch{
      write-ezlogs "An exception occurred getting status of Twitch streams!" -showtime -catcherror $_ -logfile:$log
      Update-Notifications -Level 'ERROR' -Message "An exception occurred getting status of Twitch streams!" -VerboseLog -Message_color "Red" -thisApp $thisApp -synchash $synchash -Open_Flyout
    }      
    #$twitchStreams = $synchash.
  }else{
    if($StreamName){
      $twitch_channel = $((Get-Culture).textinfo.totitlecase(($StreamName).tolower()))
    }elseif($media.webpage_url){
      $twitch_channel = $((Get-Culture).textinfo.totitlecase(($media.webpage_url | split-path -leaf).tolower()))
    }
    try{
      $synchash.update_twitchstatus_timer = new-object System.Windows.Threading.DispatcherTimer
      $synchash.update_twitchstatus_timer.Add_Tick({
          try{  
            if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Checking status of Twitch stream $twitch_channel -- $($Media.webpage_url)" -showtime -color cyan -logfile:$log}          
            $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
            if($TwitchAPI.type){
              #$twitch_status = $streamlink_fetchjson | convertfrom-json
              $twitch_status = $TwitchAPI.type
              $twitch_channel = $TwitchAPI.User_Name           
              if($twitch_status){
                if($TwitchAPI.thumbnail_url){
                  $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
                }else{
                  $thumbnail = ''
                }              
                Update-Notifications -Level 'INFO' -Message "Twitch Channel $twitch_channel`: $((Get-Culture).textinfo.totitlecase(($twitch_status).toUpper()))" -VerboseLog -Message_color "Cyan" -thisApp $thisApp -synchash $synchash -Open_Flyout -No_runspace
                Add-Member -InputObject $Media -Name 'Live_Status' -Value $twitch_status -MemberType NoteProperty -Force
                Add-Member -InputObject $media -Name 'Status_msg' -Value "- $($TwitchAPI.game_name)" -MemberType NoteProperty -Force  
                Add-Member -InputObject $media -Name 'Stream_title' -Value "$($TwitchAPI.title)" -MemberType NoteProperty -Force
                Add-Member -InputObject $media -Name 'thumbnail' -Value $thumbnail -MemberType NoteProperty -Force                                      
              }
            }else{
              Update-Notifications -Level 'INFO' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -No_runspace
              Add-Member -InputObject $media -Name 'Live_Status' -Value 'Offline' -MemberType NoteProperty -Force
              Add-Member -InputObject $media -Name 'Status_msg' -Value '' -MemberType NoteProperty -Force
              Add-Member -InputObject $media -Name 'Stream_title' -Value "" -MemberType NoteProperty -Force 
              Add-Member -InputObject $media -Name 'thumbnail' -Value "" -MemberType NoteProperty -Force                
            }  
            $Playlist_profile = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $media.id}         
            foreach($track in $Playlist_profile.Playlist_tracks){
              if($track.id -eq $media.id){
                $track.title = $Media.Title
                $track.Status_msg = $Media.Status_msg
                $track.Live_Status = $Media.Live_Status
                Add-Member -InputObject $track -Name 'thumbnail' -Value "$($Media.thumbnail)" -MemberType NoteProperty -Force
                Add-Member -InputObject $track -Name 'Stream_title' -Value "$($Media.Stream_title)" -MemberType NoteProperty -Force 
                if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -color cyan -logfile:$log}
                if([System.IO.FIle]::Exists($track.Playlist_File_Path)){
                  write-ezlogs ">>>> Saving updated playlist profile from track profile: $($track.Playlist_File_Path)" -showtime -color cyan
                  $Playlist_profile | Export-Clixml $track.Playlist_File_Path -Force
                }elseif([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
                  if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan -logfile:$log}
                  $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
                }         
              }
            } 
            Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -PlayMedia_Command $synchash.PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $synchash.PlaySpotify_Media_Command -all_playlists $all_playlists      
            #$synchash.Refresh_Playlist_Hidden_Checkbox.IsChecked = $true                   
          }catch{
            write-ezlogs "An exception occurred executing update_status_timer" -showtime -catcherror $_ -logfile:$log
            $this.Stop()
          }
          $this.Stop()     
      }.GetNewClosure()) 
      $synchash.update_twitchstatus_timer.start()  
      #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -startup -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
    }catch{
      write-ezlogs "An exception occurred getting status of Twitch stream $($_.OriginalSource.datacontext)" -showtime -catcherror $_ -logfile:$log
      Update-Notifications -Level 'ERROR' -Message "An exception occurred getting status of Twitch stream $($Media.webpage_url)" -VerboseLog -Message_color "Red" -thisApp $thisApp -synchash $synchash -Open_Flyout
    }    

  }

}
#---------------------------------------------- 
#endregion Get-TwitchStatus Function
#----------------------------------------------


#---------------------------------------------- 
#region Start-TwitchMonitor Function
#----------------------------------------------
function Start-TwitchMonitor
{
  Param (
    [string]$StreamName,
    $Interval,
    $thisApp,
    $all_playlists,
    $log = $thisApp.Config.TwitchMedia_logfile,
    $synchash,
    [switch]$Startup,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging
  ) 
  if($Verboselog){write-ezlogs "#### Starting Twitch Monitor ####" -enablelogs -color yellow -linesbefore 1 -logfile:$log}
  $Sleep_Value = [TimeSpan]::Parse($Interval).TotalSeconds
  if($Verboselog){write-ezlogs " | Interval Seconds: $sleep_value" -showtime -logfile:$log}
  $Twitch_Status_Monitor_Scriptblock = {
    $Twitch_Monitor_Timer = 0    
    try{      
      while($thisApp.config.Twitch_Update -and $thisApp.config.Twitch_Update_Interval -ne $null){      
        $Sleep_Value = [TimeSpan]::Parse($thisApp.config.Twitch_Update_Interval).TotalSeconds
        $checkupdate_timer = [system.diagnostics.stopwatch]::StartNew()
        Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -all_playlists $all_playlists -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace:$false
        Write-ezlogs "[Get-TwitchStatus] Ran for: $($checkupdate_timer.Elapsed.TotalSeconds) seconds" -showtime -logfile:$log
        $checkupdate_timer.Restart()
        start-sleep -Seconds $Sleep_Value
        $Twitch_Monitor_Timer++
      }
      if(!$thisApp.config.Twitch_Update){
        write-ezlogs "Twitch Status Monitor ended due to Twitch_Update option being disabled - It ran for $($Twitch_Monitor_Timer) cycles" -showtime -warning -logfile:$log
      }else{
        write-ezlogs "Twitch Status Monitor has ended - It ran for $($Twitch_Monitor_Timer) cycles" -showtime -warning -logfile:$log
      }
    }catch{
      write-ezlogs "An exception occurred in Twitch_status_Monitor_Scriptblock" -showtime -catcherror $_ -logfile:$log
    }
  }
  if($thisApp.config.Twitch_Update -and $Sleep_Value -ne $null){
    $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
    Start-Runspace $Twitch_Status_Monitor_Scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Twitch_Monitor_Runspace" -thisApp $thisApp -Script_Modules $Script_Modules
  }else{
    write-ezlogs "No sleep value was provided or found, cannot continue" -showtime -warning -logfile:$log
  }
}
#---------------------------------------------- 
#endregion Start-TwitchMonitor Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-TwitchAPI','Get-TwitchStatus','Start-TwitchMonitor')