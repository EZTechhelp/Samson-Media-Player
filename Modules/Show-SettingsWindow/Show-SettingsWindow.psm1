<#
    .Name
    Show-SettingsWindow

    .SYNOPSIS
    Displays a WPF window to view and update setting options

    .DESCRIPTION
    Creates, initializes, renders, updates, resets and displays a Mahapps Metro WPF window with controls for all available app settings. Used for both guided First Run setup and updating app settings at any time
       
    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    MahApps.Metro.Controls.MetroWindow

    .NOTES
    Version : 3.0
    Author  : EZTechhelp - https://www.eztechhelp.com
#>

#---------------------------------------------- 
#region Update-MediaLocations Function
#----------------------------------------------
function Update-MediaLocations
{
  param (
    [switch]$Clear,
    $thisApp,
    $synchash,
    [switch]$UpdateLibrary,
    [switch]$Startup,
    [switch]$Open_Flyout,
    [switch]$Refresh,
    [switch]$RefreshLibrary,
    $Directories,
    [string]$Path,
    [string]$Level,
    [string]$Viewlink,
    [string]$Message_color,
    $hashsetup,
    [switch]$SetItemsSource,
    [switch]$VerboseLog
  )
  try{ 
    $hashsetup.Media_Progress_Ring.isActive = $true
    $hashsetup.Media_Path_Browse.isEnabled = $false
    $hashsetup.MediaLocations_Grid.isEnabled = $false
    $hashSetup.setupbutton_status = $hashSetup.Save_Setup_Button.isEnabled
    $hashSetup.Save_Setup_Button.isEnabled = $false
    write-ezlogs "[Update-MediaLocations] >>>> Updating Media Locations table" -showtime -LogLevel 2 -logtype Setup      
    if($Refresh){
      if($hashsetup.LocalMedia_items){
        [void]$hashsetup.LocalMedia_items.clear()
      }
      if($hashsetup.MediaLocations_Grid.items){
        [void]$hashsetup.MediaLocations_Grid.items.clear()
      }                   
    }
    $enumerate_files_Scriptblock = {
      param (
        [switch]$Clear,
        $thisApp,
        $synchash,
        [switch]$UpdateLibrary,
        [switch]$Startup,
        [switch]$Open_Flyout,
        [switch]$Refresh,
        [switch]$RefreshLibrary,
        $Directories,
        [string]$Path,
        [string]$Level,
        [string]$Viewlink,
        [string]$Message_color,
        $hashsetup,
        [switch]$SetItemsSource,
        [switch]$VerboseLog
      )
      $BadPaths = [System.Collections.Generic.List[Object]]::new()
      $warningPaths = [System.Collections.Generic.List[Object]]::new()
      foreach($path in $Directories){
        try{   
          if([string]::IsNullOrEmpty($path)){
            write-ezlogs "[Update-MediaLocations] LocalMedia directory path blank entry" -showtime -warning -logtype Setup
          }elseif($hashsetup.LocalMedia_items.path -notcontains $path){                             
            if(!$hashsetup.LocalMedia_items){
              $Number = 1
            }else{
              $Number = $hashsetup.LocalMedia_items.Number | select -last 1
              $Number++
            }
            if([System.IO.Directory]::Exists($Path)){               
              try{
                if(($Path).StartsWith("\\")){
                  $isNetworkPath = $true
                  write-ezlogs "[Update-MediaLocations] The path $($path) is detected as a network UNC Path" -warning 
                }elseif([system.io.driveinfo]::new($Path).DriveType -eq 'Network' -and (Use-RunAs -Check)){
                  $isNetworkMappedDrive = $true
                  write-ezlogs "[Update-MediaLocations] The path $($path) is detected as a network drive and the app is currently running as admin. It may not be accessible under different user contexts" -warning
                }                       
              }catch{
                write-ezlogs "[Update-MediaLocations] An exception occurred getting drive info for $path" -CatchError $_
                [void]$BadPaths.add($Path)
                $exceptionmessage += "`n$_"
              }
              write-ezlogs "[Update-MediaLocations] >>>> Adding Number: $Number -- Path: $path" -showtime -LogLevel 2 -logtype Setup
              $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($path)-Local")
              $encodedpath = [System.Convert]::ToBase64String($encodedBytes) 
              $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
              $exclude_Pattern = '\.temp\.|\.tmp\.'
              try{ 
                write-ezlogs "[Update-MediaLocations] | Verifying valid media exists in path: $($path)" -showtime -LogLevel 2 -logtype Setup
                $enumerate_measure = [system.diagnostics.stopwatch]::StartNew()  
                $directory_files = Find-FilesFast -Path $Path | select -first 10 | & { process {if ($_.FileName -match $media_pattern -and $_.FullName -notmatch $exclude_Pattern -and !$_.isDirectory){$_}}} 
                $enumerate_measure.stop()
                write-ezlogs "[Update-MediaLocations] Find-FilesFast measure for $path" -LogLevel 2 -logtype Perf -PerfTimer $enumerate_measure
                $enumerate_measure = $Null
                $directory_filecount = $directory_files.count
                write-ezlogs "[Update-MediaLocations] | Directory_filecount: $($directory_filecount)" -logtype Setup
                if($directory_filecount -ge 50){
                  $directory_filecount = "TBD"
                }elseif($directory_filecount -eq 0){
                  [void]$warningPaths.add($path)
                  write-ezlogs "[Update-MediaLocations] Unable to verify if any valid media exists under path: $path" -logtype Setup -warning
                }
              }catch{
                write-ezlogs "[Update-MediaLocations] An exception occurred attempting to get directory file count with GetFiles for path $Path" -showtime -catcherror $_               
                $hashsetup.window.Dispatcher.Invoke("Normal",[action]{     
                    $hashsetup.Media_Progress_Ring.isActive = $false
                    $hashsetup.Media_Path_Browse.isEnabled = $true
                    $hashSetup.Save_Setup_Button.isEnabled = $hashSetup.setupbutton_status
                    $hashsetup.MediaLocations_Grid.isEnabled = $true              
                    $hashsetup.Editor_Help_Flyout.isOpen = $true
                    $hashsetup.Editor_Help_Flyout.header = 'Local Media'                                                      
                }) 
                update-EditorHelp -content "[WARNING] An exception occurred attempting to get media file count for path $Path`n$_" -color red -FontWeight Bold  -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -use_runspace
                update-EditorHelp -content "Media in this directory may not be imported. This is usually due to permission issues. Try re-running setup as admin or verifying you have access to the path specified" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace                       
                continue
              }              
            }else{
              [void]$BadPaths.add($Path)               
              continue
            }                               
            [void]$hashSetup.LocalMedia_items.add([PSCustomObject]@{
                Number=$Number
                Path=$Path
                MediaCount=$directory_filecount
            })  
          }else{
            write-ezlogs "[Update-MediaLocations] LocalMedia path ($($Path)) has already been added to LocalMedia_items" -showtime -warning -logtype Setup
          }
        }catch{
          write-ezlogs "[Update-MediaLocations] An exception occurred processing local media $path" -catcherror $_
        }
      }
      if(@($BadPaths).count -ge 1 -and (Use-RunAs -Check)){
        foreach($path in $BadPaths){
          $BadPathsMessage += "`n + $path"
        }
        $message = @"
**Could not find some of your configured local media directories** 
`n
$BadPathsMessage
%{color:#FFFFD265}*This app is currently running as administrator*%`n 
If these path(s) are network mapped drive(s), you can try the following:`n + Restart the app without running as administrator`n + Click [HERE](RestartAsUser) to restart the app as a normal user now.`n + Configure **Enablelinkedconnections** registry option to allow accessing mapped drives when running as admin.`n`t + Visit [Microsoft KB 3035277](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command) to learn how to configure
"@

        $message2 = "Could not find some of your configured local media directories. If these path(s) are network mapped drive(s), try restarting the app without running as admin or click Restart as User to restart now`n`nInvalid Paths:`n$($BadPaths | out-string)"                   
      }elseif(@($BadPaths).count -ge 1){   
        if($exceptionmessage){
          write-ezlogs "[Update-MediaLocations] **An error occurred when adding the following directories`n`nErrors: $exceptionmessage`n" -warning -logtype Setup
          $message = "**An error occurred when adding the following directories. These errors may or may not prevent issues importing or scanning media from these paths**`n`n%{color:#FFFFD265}Errors: $exceptionmessage%`n`n" 
        }else{
          write-ezlogs "[Update-MediaLocations] Could not find directory to add $($BadPaths)...skipping" -warning -logtype Setup
          $message = "**Could not find some of your configured local media directories**`n" 
        }               
        foreach($path in $BadPaths){
          $message += "`n + $path"
        }
        $message2 = "Could not find some of your configured local media directories`n`nInvalid Paths:`n$($BadPaths | out-string)"
      }elseif(@($warningPaths).count -ge 1){                  
        #write-ezlogs "Unable to verify if any valid media exists under path: $warningPaths" -warning -logtype Setup
        $message = "**Unable to verify if any valid media exists under these paths**`n"
        foreach($path in $warningPaths){
          $message += "`n + $path"
        }
      }
      if($hashsetup.Window.IsInitialized -and $hashsetup.Window.Visibility -ne 'Collapsed' -and $message){
        update-EditorHelp -MarkDownFile $message -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header "Local Path Warning" -clear -use_runspace
        #update-EditorHelp -content "[WARNING] Could not find one of your previously configured local media directories. If this path is a network drive and you are running this setup after just installing or updating the app, you can close and restart the app to launch it under user permissions. `n`nAlternatively, you can enable the `"Use Enablelinkedconnections`" option. Read that settings help topic for details`n`nNetwork Path: $Path" -color orange -FontWeight Bold  -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -use_runspace -Header "Network Drive Warning"
      }elseif($synchash.Window.isVisible -and $message2){
        if((Use-RunAs -Check)){
          $restartasuserScriptBlock = {
            use-runas -RestartAsUser
          }
        }
        New-DialogNotification -thisApp $thisapp -synchash $synchash -Message $message2 -DialogType Normal -DialogLevel WARNING -ActionName 'Restart As User' -ActionScriptBlock $restartasuserScriptBlock
        write-ezlogs $message2 -warning
      }
      #final processing
      if($SetItemsSource){
        try{         
          write-ezlogs "[Update-MediaLocations] >>>> Executing Update_LocalMedia_Timer" -logtype Setup                             
          $hashsetup.Update_LocalMedia_Timer.tag = $hashSetup.LocalMedia_items   
          $hashsetup.Update_LocalMedia_Timer.start()
        }catch{
          write-ezlogs "[Update-MediaLocations] An exception occurred starting Update_LocalMedia_Timer" -catcherror $_
        }
        return
      }
    }
    #$Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $enumerate_files_Scriptblock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name "Enumerate_Files_ScriptBlock" -thisApp $thisApp    
    #$Variable_list = $Null
    $enumerate_files_Scriptblock = $Null
  }catch{
    write-ezlogs "An exception occurred processing local media $path" -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Update-MediaLocations Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-SpotifyPlaylists Function
#----------------------------------------------
function Update-SpotifyPlaylists
{
  param (
    [switch]$Clear,
    $thisApp,
    [switch]$Startup,
    [switch]$Open_Flyout,
    $Locations_array,
    [string]$Path,
    [string]$Level,
    [string]$Viewlink,
    [string]$Message_color,
    [string]$Name,
    [string]$Type,
    $hashsetup,
    $playlist_info,
    [string]$id,
    [switch]$VerboseLog
  )
  <#  $Visible_Fields = @(
      'Number'
      'ID'
      'Name'
      'Path'
      )
      $Fields = @(
      'Number'
      'ID'
      'Name'
      'Path'
      'Type'
      'Tracks'
      'Playlist_info'
  ) #>     
  if(!$hashsetup.SpotifyPlaylists_Grid.items){ 
    #$Global:SpotifyPlayliststable =  [hashtable]::Synchronized(@{})
    #$Global:SpotifyPlayliststable.datatable = [System.Data.DataTable]::new() 
    #[void]$SpotifyPlayliststable.datatable.Columns.AddRange($Fields)
    $Number = 1
  }else{
    $Number = $hashsetup.SpotifyPlaylists_Grid.items.Number | select -last 1
    $Number++
  }
  write-ezlogs ">>>> Updating Spotify Playlists table" -showtime -logtype Setup -loglevel 3
  if($Locations_array)
  {
    foreach ($n in $Locations_array)
    {
      $Array = [System.Collections.Generic.List[Object]]::new()
      [void]$array.add($n.Number)
      [void]$array.add($n.Path)
      #[void]$SpotifyPlayliststable.datatable.Rows.Add($array)
    } 
  }
  write-ezlogs " | Adding Spotify - Number: $Number -- URL: $path -- Name: $Name -- Type: $Type -- ID: $ID" -showtime -logtype Setup -loglevel 3
  try{    
    [void]$hashsetup.SpotifyPlaylists_Grid.Items.add([PSCustomObject]@{
        Number=$Number    
        ID = $id
        Name=$Name
        Path=$Path
        Type=$Type
        Tracks=$Playlist_Info.tracks.total
        Playlist_Info = $Playlist_Info
    })
  }catch{
    write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Update-SpotifyPlaylists Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-YoutubePlaylists Function
#----------------------------------------------
function Update-YoutubePlaylists
{
  param (
    $thisApp = $thisApp,
    [switch]$Startup,
    [string]$Path,
    [string]$Name,
    [string]$Type,
    $hashsetup,
    $playlist_info,
    [string]$id,
    [switch]$VerboseLog
  )
  try{      
    if(!$hashsetup.YoutubePlaylists_Grid.items){ 
      $Number = 1
    }else{
      $Number = $hashsetup.YoutubePlaylists_Grid.items.Number | select -last 1
      $Number++
    }
    write-ezlogs ">>>> Updating Youtube Playlists table | Adding Youtube - Number: $Number -- URL: $path -- Name: $Name -- Type: $Type -- ID: $ID" -showtime -logtype Setup -Dev_mode
    try{
      $hashsetup.Update_YoutubePlaylists_Timer.tag = [PSCustomObject]@{
        Number=$Number;       
        ID = $id
        Name=$Name
        Path=$Path
        Type=$Type
        Playlist_Info = $Playlist_Info
      }
      $hashsetup.Update_YoutubePlaylists_Timer.start()
    }catch{
      write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
    }                
  }catch{
    write-ezlogs "An exception occurred in Update_YoutubePlaylists_Timer.add_tick $($hashsetup | out-string)" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Update-YoutubePlaylists Function
#----------------------------------------------

#---------------------------------------------- 
#region Invoke-YoutubeImport Function
#----------------------------------------------
function Invoke-YoutubeImport
{
  param (
    $thisApp = $thisApp,
    $hashsetup = $hashsetup,
    [switch]$VerboseLog
  )
  try{
    try{
      $youtube_playlists = Get-YouTubePlaylists -mine
    }catch{
      write-ezlogs "An exception occurred retrieving youtube playlists with Get-YoutubePlaylists" -showtime -catcherror $_
    } 
    $newplaylists = 0
    $newchannels = 0
          
    if($youtube_playlists){        
      foreach($playlist in $youtube_playlists){              
        $playlisturl = "https://www.youtube.com/playlist?list=$($playlist.id)"
        $playlistName = $playlist.snippet.title
        if($hashSetup.YoutubePlaylists_itemsArray.path -notcontains $playlisturl){
          write-ezlogs "Adding Youtube Playlist URL $playlisturl" -showtime -logtype Setup -loglevel 3
          if(!$hashSetup.YoutubePlaylists_itemsArray.Number){ 
            $Number = 1
          }else{
            $Number = $hashSetup.YoutubePlaylists_itemsArray.Number | Select-Object -last 1
            $Number++
          }
          [void]$hashSetup.YoutubePlaylists_itemsArray.add([PSCustomObject]@{
              Number=$Number;       
              ID = $playlist.id
              Name=$playlistName
              Path=$playlisturl
              Type='YoutubePlaylist'
              Playlist_Info = $playlist
          })
          #$hashSetup.YoutubePlaylists_items.add($itemssource)
          $newplaylists++
        }else{
          write-ezlogs "The Youtube Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
        }
      }
    }
    try{
      if($thisApp.Config.Import_My_Youtube_Media -or $thisApp.ConfigTemp.Import_My_Youtube_Media){
        $channel = Get-YouTubeChannel -mine -Raw
        if($channel.items.contentdetails.relatedPlaylists.uploads){
          $playlistid = $($channel.items.contentdetails.relatedPlaylists.uploads)
          #$channelurl = "https://www.youtube.com/channel/$($channel.items.id)/videos"
          $playlisturl = "https://www.youtube.com/playlist?list=$($playlistid)"
          $channelName = $channel.items.snippet.title
          if($hashSetup.YoutubePlaylists_itemsArray.path -notcontains $playlisturl){
            write-ezlogs "Adding Youtube Channel URL $playlisturl" -showtime -logtype Setup -loglevel 3
            if(!$hashSetup.YoutubePlaylists_itemsArray.Number){ 
              $Number = 1
            }else{
              $Number = $hashSetup.YoutubePlaylists_itemsArray.Number | Select-Object -last 1
              $Number++
            }
            [void]$hashSetup.YoutubePlaylists_itemsArray.add([PSCustomObject]@{
                Number=$Number;       
                ID = $playlistid
                Name=$channelName
                Path=$playlisturl
                Type='YoutubePlaylist'
                Playlist_Info = $channel.items
            })
            $newplaylists++
          }else{
            write-ezlogs "The Youtube Channel URL $playlisturl has already been added!" -showtime -warning -logtype Setup
          }           
        }
      }
      if($thisApp.Config.Import_My_Youtube_Subscriptions -or $thisApp.ConfigTemp.Import_My_Youtube_Subscriptions){
        try{
          $ytsubs = Get-YouTubeSubscription -Raw
          if($ytsubs.snippet.resourceId.channelId){
            foreach($sub in $ytsubs){
              $channelid = $($sub.snippet.resourceId.channelId)
              $channelName = $sub.snippet.title
              $channelurl = "https://www.youtube.com/channel/$($channelid)"
              $channel = Get-YouTubeChannel -Id $channelid -Raw
              if($hashSetup.YoutubePlaylists_itemsArray.path -notcontains $channelurl){
                write-ezlogs "Adding Youtube Subscription Channel URL $channelurl" -showtime -logtype Setup -loglevel 3
                if(!$hashSetup.YoutubePlaylists_itemsArray.Number){ 
                  $Number = 1
                }else{
                  $Number = $hashSetup.YoutubePlaylists_itemsArray.Number | Select-Object -last 1
                  $Number++
                }
                [void]$hashSetup.YoutubePlaylists_itemsArray.add([PSCustomObject]@{
                    Number=$Number;       
                    ID = $channelid
                    Name=$channelName
                    Path=$channelurl
                    Type='YoutubeChannel'
                    Playlist_Info = $channel.items
                })
                $newchannels++
              }else{
                write-ezlogs "The Youtube Subscription Channel URL $channelurl has already been added!" -showtime -warning -logtype Setup
              }
            }                          
          }
        }catch{
          write-ezlogs "An exception occurred getting personal Youtube subscriptions" -showtime -catcherror $_
        }
      }
      #$hashsetup.Update_YoutubePlaylists_Timer.tag = $hashSetup.YoutubePlaylists_items
      $hashsetup.Update_YoutubePlaylists_Timer.tag = $hashSetup.YoutubePlaylists_itemsArray
      $hashsetup.Update_YoutubePlaylists_Timer.start()
    }catch{
      write-ezlogs "An exception occurred retrieving owner youtube channel id" -showtime -catcherror $_
    }       
    if($newplaylists -le 0 -and $newchannels -le 0){
      write-ezlogs "No new Youtuube Playlists were found!" -showtime -warning -logtype Setup
      $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
          $hashsetup.Editor_Help_Flyout.isOpen = $true           
          $hashsetup.Youtube_Playlists_Import_Progress_Ring.isActive=$false
          $hashsetup.Youtube_Playlists_Import.isEnabled = $true                       
      })
      update-EditorHelp -content "No new Youtuube Playlists were found!" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -use_runspace -Header 'Youtube'
    }else{
      write-ezlogs "Found $newplaylists playlists and $newchannels new channels" -showtime -logtype Setup
 
      if($newplaylists -gt 0){
        $message = "Found $newplaylists new Youtube Playlists!"
        write-ezlogs ">>>> Found $newplaylists new Youtube Playlists!" -showtime -logtype Setup -loglevel 2
      }
      if($newchannels -gt 0){
        $message += "`nFound $newchannels new Youtube Subscribed Channels!"
        write-ezlogs ">>>> Found $newchannels new Youtube Subscribed Channels!" -showtime -logtype Setup -loglevel 2
      }
      $hashsetup.window.Dispatcher.Invoke("Normal",[action]{             
          try{               
            $hashsetup.Editor_Help_Flyout.header = 'Youtube'
            $hashsetup.Youtube_Playlists_Import_Progress_Ring.isActive=$false
            $hashsetup.Youtube_Playlists_Import.isEnabled = $true                                
          }catch{
            write-ezlogs "An exception occurred updating/opening Editor_Help_Flyout" -catcherror $_
          } 
      })
      update-EditorHelp -content $message -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -use_runspace -clear
    }               
  }catch{
    write-ezlogs "An exception occurred in Youtube_ImportHandler routed event" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Invoke-YoutubeImport Function
#----------------------------------------------

#---------------------------------------------- 
#region Invoke-TwitchImport Function
#----------------------------------------------
function Invoke-TwitchImport
{
  param (
    $thisApp = $thisApp,
    $hashsetup = $hashsetup,
    [switch]$VerboseLog
  )
  try{
    try{
      $newtwitchchannels = 0
      $Twitch_playlists = Get-TwitchFollows -GetMyFollows -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred retrieving Twitch Follows with Get-TwitchFollows" -showtime -catcherror $_
    } 
    if($Twitch_playlists){
      foreach($playlist in $Twitch_playlists){                         
        $playlisturl = "https://www.twitch.tv/$($playlist.broadcaster_login)"
        $playlistName = $playlist.broadcaster_name
        if($playlist.followed_at){
          try{
            $followed = [DateTime]::Parse($playlist.followed_at)
            if($followed){
              $followed = $followed.ToShortDateString()
            }
          }catch{
            write-ezlogs "An exception occurred parsing followed_at ($($playlist.followed_at)) for Twitch channel $($playlistName)" -showtime -catcherror $_
          }
        }
        if($hashsetup.TwitchPlaylists_items.path -notcontains $playlisturl){
          $newtwitchchannels++
          write-ezlogs "Adding Twitch Playlist URL $playlisturl" -showtime -logtype Setup -LogLevel 2
          Update-TwitchPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.broadcaster_id -Followed $Followed -type 'TwitchChannel' -VerboseLog:$thisApp.Config.Verbose_logging
        }else{
          write-ezlogs "The Twitch Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
        }
      }
      Update-TwitchPlaylists -hashsetup $hashsetup -VerboseLog:$thisApp.Config.Verbose_logging -SetItemsSource
      write-ezlogs " | Found $newtwitchchannels new Twitch Channels" -showtime -logtype Setup -LogLevel 2
      if($hashsetup.EditorHelpFlyout.Document.Blocks){
        $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
      }        
      if($newtwitchchannels -le 0){
        write-ezlogs "No new Twitch Channels were found!" -showtime -warning -logtype Setup
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = 'Twitch Import'
        update-EditorHelp -content "No new Twitch Channels found to import" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
      }else{
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = 'Twitch Import'
        write-ezlogs ">>>> Found $newtwitchchannels new Twitch Channels!" -showtime -logtype Setup -LogLevel 2
        update-EditorHelp -content "Found $newtwitchchannels new Twitch Channels!" -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
      } 
    }else{
      write-ezlogs "Unable to import Followed channels from Twitch" -showtime -warning -logtype Setup
      if($hashsetup.EditorHelpFlyout.Document.Blocks){
        $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
      } 
      $hashsetup.Editor_Help_Flyout.isOpen = $true
      $hashsetup.Editor_Help_Flyout.header = 'Twitch Import'
      update-EditorHelp -content "Unable to import Followed channels from Twitch. Check the log for more detail or try again in case of a transient issue" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout          
    }         
  }catch{
    write-ezlogs "An exception occurred in Invoke-TwitchImport" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Invoke-TwitchImport Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-TwitchPlaylists Function
#----------------------------------------------
function Update-TwitchPlaylists
{
  param (
    [switch]$Clear,
    [switch]$SetItemsSource,
    $thisApp,
    [switch]$Startup,
    [switch]$Open_Flyout,
    $Locations_array,
    [string]$Path,
    [string]$ID,
    [int]$Number,
    [string]$Name,
    [string]$Followed,
    [string]$Type,
    [string]$Level,
    [string]$Message_color,
    $hashsetup,
    [switch]$VerboseLog,
    [switch]$add_to_Twitch_Playlists,
    [switch]$remove_from_Twitch_Playlists
  ) 
  try{     
    if($Name){
      if(!$Number){
        if(!$hashsetup.TwitchPlaylists_items){
          $Number = 1
        }else{
          $Number = $hashsetup.TwitchPlaylists_items.Number | select -last 1
          $Number++
        }
      }
      write-ezlogs ">>>> Updating Twitch table | Adding Numnber: $Number -- URL: $path" -showtime  -logtype Setup -Dev_mode
      $itemssource = [Twitch_Playlist]@{
        Number=$Number
        Name=$Name
        Path=$Path
        Type=$Type
        Followed=$Followed
        ID = $id
      } 
      if($hashSetup.TwitchPlaylists_items -notcontains $itemssource -and !$remove_from_Twitch_Playlists){
        [void]$hashSetup.TwitchPlaylists_items.add($itemssource)
      }elseif($remove_from_Twitch_Playlists -and $hashSetup.TwitchPlaylists_items -contains $itemssource){
        write-ezlogs "| Removing Twitch channel $($Name) from TwitchPlaylists_items" -warning -logtype Setup -Dev_mode
        [void]$hashSetup.TwitchPlaylists_items.Remove($itemssource)
      }else{
        write-ezlogs "Twitch Channel itemssource for ($($Name)) has alreadyt been added to TwitchPlaylists_items" -showtime -warning -logtype Setup -Dev_mode
      }
      if($add_to_Twitch_Playlists){
        if($thisApp.Config.Twitch_Playlists.path -notcontains $itemssource.Path){
          write-ezlogs " | Adding new Twitch URL to Twitch_Playlists: $($itemssource.Path)" -showtime -logtype Setup
          [void]$thisApp.Config.Twitch_Playlists.add($itemssource)
        }
      }elseif($remove_from_Twitch_Playlists){
        if($thisApp.Config.Twitch_Playlists.path -contains $itemssource.Path){
          write-ezlogs "| Removing Twitch URL from Twitch_Playlists: $($itemssource.Path)" -showtime -logtype Setup -Dev_mode
          [void]$thisApp.Config.Twitch_Playlists.Remove($itemssource)
        }      
      }         
    }
    if($SetItemsSource){
      $hashsetup.Update_TwitchPlaylists_Timer.tag = $hashSetup.TwitchPlaylists_items   
      $hashsetup.Update_TwitchPlaylists_Timer.start()
      return
    }
  }catch{
    write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
  }      
}
#---------------------------------------------- 
#endregion Update-TwitchPlaylists Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-SettingsWindow Function
#----------------------------------------------
function Update-SettingsWindow {
  <#
          
      .SYNOPSIS
      Updates existing properties for the settings UI window.

      .DESCRIPTION
      Uses dispatcher timer to update various wpf controls and properties asyncronously within the settings window thread

      .PARAMETER hashsetup
      The Synchronized hashtable holding the settings UI window and controls

      .EXAMPLE
      PS> Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -close

      .EXAMPLE
      PS> Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -control 'EditorHelpFlyout' -Property 'isOpen' -value $true

  #>
  Param (
    $hashsetup,
    $thisApp,
    [switch]$Show,
    [switch]$Activate,
    [switch]$BringToFront,
    [string]$Control,
    $controls,
    $value,
    $queue_object,
    [switch]$Dequeue,
    $ScriptBlock,
    [string]$Priority,
    [string]$Method,
    $Method_Value,
    [string]$Property,
    [switch]$ClearValue,
    [switch]$NullValue,
    [switch]$Hide,
    [string]$TopMost,
    [switch]$close,
    [switch]$screenshot,
    [switch]$UpdateMediaDirectories,
    [switch]$startHidden,
    [string]$Current_folder,
    [string]$Set_ThemeName,
    [ValidateSet('Local','Spotify','Youtube','Twitch')]
    [string]$RefreshLibrary = 'Local',
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup -and !$hashsetup.SettingsWindow_Update_Timer){
      $hashsetup.SettingsWindow_Update_Queue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $hashsetup.SettingsWindow_Update_Timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
      $hashsetup.SettingsWindow_Update_Timer_ScriptBlock = {
        try{
          #$hashsetup = $hashsetup
          $thisApp = $thisApp
          $object = @{}
          if($hashsetup.SettingsWindow_Update_Queue){
            $Process = $hashsetup.SettingsWindow_Update_Queue.TryDequeue([ref]$object)
          }
          if($Process){   
            if($object.Show){
              $hashsetup.window.Opacity = 1
              $hashsetup.Window.show() 
              $hashsetup.Window.Activate() 
            }
            if($object.Hide){
              $hashsetup.Window.Hide() 
            }  
            if($object.Close){
              $hashsetup.ClosedbyApp = $true
              $hashsetup.Window.Close() 
            }
            if(-not [string]::IsNullOrEmpty($object.Set_ThemeName)){
              try{
                $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
                $themes = $theme.GetLibraryThemes()
                $themeManager = [ControlzEx.Theming.ThemeManager]::new()
                $themeindex = $themes.name.IndexOf($object.Set_ThemeName)
                if($themeindex -ne -1){
                  $newtheme = $themes.Where({$_.Name -eq $object.Set_ThemeName})
                }
                if($themes){
                  [void]$themes.Dispose() 
                  $themes = $Null
                }
                $theme = $null           
                [void]$thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
                [void]$thememanager.ChangeTheme($hashsetup.Window,$newtheme.Name,$false)
                $thememanager = $Null    
              }catch{
                write-ezlogs "An exception occurred setting theme to $($newtheme | out-string)" -CatchError $_
              }
            }             
            if($object.BringToFront -and $hashsetup.Window.isVisible -and !$hashsetup.Window.Topmost){
              $hashsetup.Window.TopMost = $true
              $hashsetup.Window.TopMost = $false
            }
            if($object.UpdateMediaDirectories -and $thisApp.Config.Import_Local_Media){
              if(@($thisApp.Config.Media_Directories).count -gt 0 -and $hashsetup.Window.isInitialized){
                Update-MediaLocations -hashsetup $hashsetup -thisapp $thisApp -Directories $thisApp.Config.Media_Directories -synchash $synchash -SetItemssource        
              }
              if($object.RefreshLibrary -eq 'Local' -and $synchash.MediaTable){
                Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $true
                Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false
                if($synchash.Refresh_LocalMedia_timer){
                  $synchash.Refresh_LocalMedia_timer.tag = 'AddNewOnly'
                  $synchash.Refresh_LocalMedia_timer.Start()
                }
              }
            }
            if($object.screenshot){
              #$hashsetup.Window.TopMost = $true
              $hashsetup.Window.TopMost = $object.TopMost
              $hashsetup.Window.Activate() 
              start-sleep -Milliseconds 500
              write-ezlogs ">>>> Taking Snapshot of Show-SettingsWindow window" -showtime
              $translatepoint = $hashsetup.Window.TranslatePoint([system.windows.point]::new(0,0),$hashsetup.Window)
              $locationfromscreen = $hashsetup.Window.PointToScreen($translatepoint)
              $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)     
            }                     
            if($object.Controls){ 
              foreach($control in $object.Controls){
                write-ezlogs ">>>> Looking for control: $($control.Control)" -loglevel 3  
                write-ezlogs "| Property: $($control.Property)" -loglevel 3 
                write-ezlogs "| value: $($control.value)" -loglevel 3 
                if(-not [string]::IsNullOrEmpty($hashsetup."$($control.Control)")){ 
                  write-ezlogs ">>>> Updating Settings Window Control $($hashsetup."$($control.Control)")" -loglevel 3     
                  if(-not [string]::IsNullOrEmpty($control.Method)){
                    if(-not [string]::IsNullOrEmpty($control.Property)){
                      if(-not [string]::IsNullOrEmpty($control.Method_Value)){
                        [void]$hashsetup."$($control.Control)"."$($control.Property)".$($control.Method)($control.Method_Value)
                      }else{
                        [void]$hashsetup."$($control.Control)"."$($control.Property)".$($control.Method)()
                      }                        
                    }else{
                      if(-not [string]::IsNullOrEmpty($control.Method_Value)){
                        [void]$hashsetup."$($control.Control)".$($control.Method)($control.Method_Value)
                      }else{
                        [void]$hashsetup."$($control.Control)".$($control.Method)()
                      } 
                    }
                  }elseif(-not [string]::IsNullOrEmpty($control.Value) -or $control.ClearValue -or $control.NullValue){
                    if(-not [string]::IsNullOrEmpty($control.Property)){
                      if($hashsetup."$($control.Control)"."$($control.Property)" -ne $control.Value -and $control.NullValue){
                        write-ezlogs "| Setting property $($control.Property) from $($hashsetup."$($control.Control)"."$($control.Property)") to Null" -loglevel 3 
                        $hashsetup."$($control.Control)"."$($control.Property)" = $null
                      }elseif($hashsetup."$($control.Control)"."$($control.Property)" -ne $control.Value){
                        write-ezlogs "| Setting property $($control.Property) from $($hashsetup."$($control.Control)"."$($control.Property)") to $($control.Value)" -loglevel 3 
                        $hashsetup."$($control.Control)"."$($control.Property)" = $control.Value
                      }
                    }else{
                      if($hashsetup."$($control.Control)" -ne $control.Value){
                        write-ezlogs "| Setting $($hashsetup."$($control.Control)") to $($control.Value)" -loglevel 3 
                        $hashsetup."$($control.Control)" = $control.Value
                      }                        
                    }
                  }                      
                }
              }
            }elseif(-not [string]::IsNullOrEmpty($hashsetup."$($object.Control)")){ 
              write-ezlogs ">>>> Updating Settings Window Control: $("$($object.Control)") -- Property: $($object.Property) -- Value: $($object.Value)" -loglevel 3 -Dev_mode                                  
              if(-not [string]::IsNullOrEmpty($object.Method)){
                if(-not [string]::IsNullOrEmpty($object.Property)){
                  if(-not [string]::IsNullOrEmpty($object.Method_Value)){
                    [void]$hashsetup."$($object.Control)"."$($object.Property)".$($object.Method)($object.Method_Value)
                  }else{
                    [void]$hashsetup."$($object.Control)"."$($object.Property)".$($object.Method)()
                  }                     
                }else{
                  if(-not [string]::IsNullOrEmpty($object.Method_Value)){
                    [void]$hashsetup."$($object.Control)".$($object.Method)($object.Method_Value)
                  }else{
                    [void]$hashsetup."$($object.Control)".$($object.Method)()
                  }    
                }
              }
              if(-not [string]::IsNullOrEmpty($object.Value) -or $object.ClearValue -or $object.NullValue){
                if(-not [string]::IsNullOrEmpty($object.Property)){
                  if($hashsetup."$($object.Control)"."$($object.Property)" -ne $object.Value -and $object.NullValue){
                    write-ezlogs "| Setting property $($object.Property) from $($hashsetup."$($object.Control)"."$($object.Property)") to Null" -loglevel 3 
                    $hashsetup."$($object.Control)"."$($object.Property)" = $null
                  }elseif($hashsetup."$($object.Control)"."$($object.Property)" -ne $object.Value){
                    write-ezlogs "| Setting property $($object.Property) from $($hashsetup."$($object.Control)"."$($object.Property)") to $($object.Value)" -loglevel 3
                    $hashsetup."$($object.Control)"."$($object.Property)" = $object.Value
                  }
                }else{
                  write-ezlogs "| Setting Control $($object.Control) from $($hashsetup."$($object.Control)") to $($object.Value)" -loglevel 3 
                  $hashsetup."$($object.Control)" = $object.Value
                }
              }                                     
            }
            if(-not [string]::IsNullOrEmpty($object.ScriptBlock)){ 
              if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Executing Scriptblock: $($object.ScriptBlock | out-string)" -Dev_mode -loglevel 3}
              Invoke-command -ScriptBlock $object.ScriptBlock
            }
          }else{
            write-ezlogs ">>>> Stopping SettingsWindow_Update_Timer as SettingsWindow_Update_Queue is empty" -warning -logtype Setup
            $this.Stop()
          }                  
        }catch{
          $this.stop()
          write-ezlogs "An exception occurred in SettingsWindow_Update_Timer.add_tick" -showtime -catcherror $_
        }
      }
      $hashsetup.SettingsWindow_Update_Timer.add_tick($hashsetup.SettingsWindow_Update_Timer_ScriptBlock)
    }elseif(!$Startup){
      if($queue_object){
        [void]$hashsetup.SettingsWindow_Update_Queue.Enqueue($queue_object)
      }else{
        $Null = $hashsetup.SettingsWindow_Update_Queue.Enqueue([PSCustomObject]::new(@{
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
              'RefreshLibrary' = $RefreshLibrary
              'BringToFront' = $BringToFront
              'UpdateMediaDirectories' = $UpdateMediaDirectories
              'screenshot' = $screenshot
              'controls' = $controls
              'Set_ThemeName' = $Set_ThemeName
              'Show' = $Show
              'Hide' = $hide
              'ScriptBlock' = $ScriptBlock
              'Close' = $close
        }))
      } 
      if(!$hashsetup.SettingsWindow_Update_Timer.IsEnabled){
        write-ezlogs ">>>> Starting SettingsWindow_Update_Timer" -warning -logtype Setup
        $hashsetup.SettingsWindow_Update_Timer.start() 
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Update-SettingsWindow" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-SettingsWindow Function
#----------------------------------------------

#---------------------------------------------- 
#region update-EditorHelp Function
#----------------------------------------------
function update-EditorHelp{    
  param (
    $content,
    [string]$color = "White",
    [string]$MarkDownFile,
    [string]$Header,
    $markdowncontrol,
    [string]$FontWeight = "Normal",
    [string]$FontSize = '14',
    [string]$BackGroundColor = "Transparent",
    [string]$TextDecorations,
    [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
    [switch]$AppendContent,
    [switch]$MultiSelect,
    [switch]$clear,
    [switch]$List,
    [switch]$use_runspace,
    [switch]$Open,
    [System.Windows.Controls.RichTextBox]$RichTextBoxControl,
    $thisApp = $thisApp,
    $hashsetup = $hashsetup
  ) 
  $update_editor_scriptblock = {
    param (
      $content = $content,
      [string]$color = $color,
      [string]$MarkDownFile = $MarkDownFile,
      [string]$Header = $Header,
      $markdowncontrol = $markdowncontrol,
      [string]$FontWeight = $FontWeight,
      [string]$FontSize = $FontSize,
      [string]$BackGroundColor = $BackGroundColor,
      [string]$TextDecorations = $TextDecorations,
      [switch]$AppendContent = $AppendContent,
      [switch]$MultiSelect = $MultiSelect,
      [switch]$clear = $clear,
      [switch]$List = $List,
      [switch]$use_runspace = $use_runspace,
      [switch]$Open = $Open,
      [System.Windows.Controls.RichTextBox]$RichTextBoxControl = $RichTextBoxControl,
      $thisApp = $thisApp,
      $hashsetup = $hashsetup
    ) 
    if($clear -and $RichTextBoxControl.Document.Blocks){
      $RichTextBoxControl.Document.Blocks.Clear() 
      if($markdowncontrol.Markdown){
        $markdowncontrol.Markdown = $Null
      }elseif($hashsetup.MarkdownScrollViewer.Markdown){
        $hashsetup.MarkdownScrollViewer.Markdown = $Null
      }
    }
    if(-not [string]::IsNullOrEmpty($Header)){
      $hashsetup.Editor_Help_Flyout.header = $Header
    }
    $url_pattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"  
    if($MarkDownFile -and $markdowncontrol){
      #write-ezlogs ">>>> Opening Markdown Help File: $MarkDownFile" -loglevel 2 -logtype Setup
      if([system.io.file]::Exists($MarkDownFile)){
        $Markdown = [system.io.file]::ReadAllText($MarkDownFile) -replace '\[USERNAME\]',$env:USERNAME -replace '\[appname\]',$thisApp.Config.App_Name -replace '\[appversion\]',$thisApp.Config.App_Version -replace '\[appbuild\]',$thisApp.Config.App_Build -replace '\[CURRENTFOLDER\]',$thisApp.Config.Current_Folder -replace '\[localappdata\]',$env:LOCALAPPDATA -replace '\[appdata\]',$env:APPDATA
      }else{
        $Markdown = ($MarkDownFile) -replace '\[USERNAME\]',$env:USERNAME -replace '\[appname\]',$thisApp.Config.App_Name -replace '\[appversion\]',$thisApp.Config.App_Version -replace '\[appbuild\]',$thisApp.Config.App_Build -replace '\[CURRENTFOLDER\]',$thisApp.Config.Current_Folder -replace '\[localappdata\]',$env:LOCALAPPDATA -replace '\[appdata\]',$env:APPDATA
      }
      $hashsetup.EditorHelpFlyout.MaxHeight = '0'
      $hashsetup.EditorHelpFlyout.Visibility = 'Hidden'
      $markdowncontrol.MaxHeight='400'
      $hashsetup.EditorHelpFlyout.isEnabled=$false
      $markdowncontrol.Markdown = $Markdown
    }elseif($RichTextBoxControl){
      $hashsetup.MarkdownScrollViewer.Markdown = $Null
      $hashsetup.MarkdownScrollViewer.MaxHeight='0'
      $hashsetup.EditorHelpFlyout.MaxHeight='400'
      $hashsetup.EditorHelpFlyout.isEnabled=$true
      $hashsetup.EditorHelpFlyout.Visibility = 'Visible'
      $Paragraph = [System.Windows.Documents.Paragraph]::new()
      $RichTextRange = [System.Windows.Documents.Run]::new() 
      $RichTextRange.Foreground = $color
      $RichTextRange.FontWeight = $FontWeight
      $RichTextRange.FontSize = $FontSize
      $RichTextRange.Background = $BackGroundColor
      $RichTextRange.TextDecorations = $TextDecorations
      if($List){ 
        $listrange = [System.Windows.Documents.List]::new()
        $listrange.MarkerStyle="Disc" 
        $listrange.MarkerOffset="2"
        #$listrange.padding = "10,0,0,0" 
        $listrange.Background = $BackGroundColor
        $listrange.Foreground = $color
        $listrange.Margin = 0
        $listrange.FontWeight = $FontWeight
        $listrange.FontSize = $FontSize
        $content | & { process {   
            $RichTextRange = [System.Windows.Documents.Run]::new()   
            $RichTextRange.Foreground = $color
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations     
            $listitem = [System.Windows.Documents.ListItem]::new() 
            $RichTextRange.AddText(($_).toupper())
            $Paragraph = [System.Windows.Documents.Paragraph]::new()
            $paragraph.Margin = 0
            $Paragraph.Inlines.add($RichTextRange)
            [void]$listitem.AddChild($Paragraph)
            [void]$listrange.AddChild($listitem)         
        }}    
        [void]$RichTextBoxControl.Document.Blocks.Add($listrange)
      }elseif($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{
        if($content -match $url_pattern){
          $hyperlink = $([regex]::matches($content, $url_pattern) | %{$_.groups[0].value})
          $uri = [system.uri]::new($hyperlink)
          $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
          $link_hyperlink.NavigateUri = $uri
          $link_hyperlink.ToolTip = "$hyperlink"
          $link_hyperlink.Foreground = "LightGreen"
          #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
          [void]$link_hyperlink.Inlines.add("$($uri.Scheme)://$($uri.DnsSafeHost)")
          [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Hyperlink_RequestNavigate)
          [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Hyperlink_RequestNavigate)
          $RichTextRange1 = [System.Windows.Documents.Run]::new()          
          $RichTextRange1.Foreground = $color
          $RichTextRange1.FontWeight = $FontWeight
          $RichTextRange1.FontSize = $FontSize
          $RichTextRange1.Background = $BackGroundColor
          $RichTextRange1.TextDecorations = $TextDecorations      
          $content1 = ($content -split $hyperlink)[0]
          $content2 = ($content -split $hyperlink)[1]
          $RichTextRange1.AddText($content1)
          $paragraph.Margin = 10
          $Paragraph.Inlines.add($RichTextRange1)
          $Paragraph.Inlines.add($link_hyperlink)
          $RichTextRange.AddText($content2)
          $Paragraph.Inlines.add($RichTextRange)
        }else{
          $RichTextRange.AddText($content)
          $paragraph.Margin = 10
          $Paragraph.Inlines.add($RichTextRange)
        }   
        [void]$RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }
    }
    if($Open){
      $hashsetup.Editor_Help_Flyout.isOpen = $true
    }
  }
  if($use_runspace){
    $hashsetup.window.Dispatcher.Invoke("Normal",[action]$update_editor_scriptblock)
  }else{
    Invoke-Command -ScriptBlock $update_editor_scriptblock
  }
}
#---------------------------------------------- 
#endregion update-EditorHelp Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-SettingsWindow Function
#----------------------------------------------
function Show-SettingsWindow{
  <#         
      .SYNOPSIS
      Creates and displays a WPF settings Window.

      .DESCRIPTION
      Initializes a Mahapps Metro WPF window to display all available setting controls for the app that can be changed. Displays help documentation within a flyout for each setting

      .PARAMETER synchash
      Synchronized hashtable holding the apps main UI window and controls

      .PARAMETER thisApp
      Synchronized hashtable holding the settings properties for the app

      .PARAMETER Startup
      Bool: Indicates a new WPF window, controls and routed events should be created and initialized

      .PARAMETER startHidden
      Bool: Indicates that the settings window should be prerendered but not displayed

      .PARAMETER First_Run
      Bool: Indicates if settings window is executing for the first time during First Run setup

      .PARAMETER Update
      Bool: Indicates that the setting window is in update mode, and sets various button states appropriately

      .PARAMETER use_runspace
      Bool: Indicates if window should be created within a separate thread using runspaces. If this is false, the settings UI will block the primary UI thread

      .PARAMETER Reload
      Bool: Indicates if existing settings UI and controls should be reloaded and displayed vs creating a new one. If no settings UI is initialized a new one is created

      .PARAMETER PageTitle
      String: Text to use for the windows title that displays within the taskbar and window manager

      .PARAMETER PageHeader
      String: Text to display within the windows title bar next to the main logo

      .PARAMETER Logo
      String: Path to valid image file to be displayed in the windows title bar

      .EXAMPLE
      Initialize and reload/prerender settings window but do not display
      PS> Show-SettingsWindow -synchash $synchash -thisApp $thisapp -PageTitle "Settings - $($thisApp.Config.App_Name) Media Player" -PageHeader 'Settings' -use_runspace -startHidden

      .EXAMPLE
      Reload/reset existing/preloaded settings window
      PS> Show-SettingsWindow -synchash $synchash -thisApp $thisapp -Update -use_runspace -Reload
  #>
  Param (
    [string]$PageTitle,
    [string]$PageHeader,
    [string]$Logo,
    [switch]$First_Run,
    [switch]$Reload,
    [switch]$No_SettingsPreload,
    [switch]$PlaylistRebuild_Required,
    [switch]$Update,
    [switch]$startHidden,
    [switch]$Use_Runspace,
    [switch]$Startup,
    $synchash = $synchash,
    $thisApp = $thisApp,
    $hash = $hash,
    $hashsetup = $hashsetup,
    [switch]$Verboselog,
    [switch]$ApplyColorTheme,
    [system.diagnostics.stopwatch]$globalstopwatch = $globalstopwatch
  )

  #TODO: Reset various temp properties to indicate if actions are needed on save. Planned to be removed - low priority
  $hashsetup.Update_LocalMedia_Sources = $false
  $hashsetup.Update_YoutubeMedia_Sources = $false
  $hashsetup.Update_SpotifyMedia_Sources = $false
  $hashsetup.Remove_SpotifyMedia_Sources = $false
  $hashsetup.Remove_YoutubeMedia_Sources = $false
  $hashsetup.Remove_TwitcheMedia_Sources = $false
  $hashsetup.Update_TwitchMedia_Sources = $false
  $hashsetup.Remove_LocalMedia_Sources = $false
  $hashsetup.Update = $update
  $hashSetup.First_Run = $First_Run
  $hashsetup.Use_runspace = $Use_runspace

  $FirstRun_Scriptblock = {
    Param (
      [string]$PageTitle = $PageTitle,
      [string]$PageHeader = $PageHeader,
      [string]$Logo = $Logo,
      [switch]$First_Run = $First_Run,
      [switch]$Reload = $Reload,
      [switch]$No_SettingsPreload = $No_SettingsPreload,
      [switch]$PlaylistRebuild_Required = $PlaylistRebuild_Required,
      [switch]$Update = $Update,
      [switch]$startHidden = $startHidden,
      [switch]$Use_Runspace = $Use_Runspace,
      [switch]$Startup = $Startup,
      $synchash = $synchash,
      $thisApp = $thisApp,
      $hash = $hash,
      $hashsetup = $hashsetup,
      [switch]$Verboselog = $Verboselog,
      [switch]$ApplyColorTheme = $ApplyColorTheme,
      [system.diagnostics.stopwatch]$globalstopwatch = $globalstopwatch
    )

    Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -NoClobber -DisableNameChecking -Scope Local

    #Valid fields that can be used for Secret Vault lookups
    $hashsetup.valid_secrets = @( 
      'TwitchClientId'
      'TwitchClientSecret'
      'TwitchRedirectUri'
      'Twitchexpires'
      'Twitchaccess_token'
      'Twitchscope'
      'Twitchrefresh_token'
      'Twitchtoken_type'
      'TwitchUserId'
      'TwitchUsername' 
      'Twitchprofile_image_url'
      'SpotyClientId'
      'SpotyClientSecret'
      'SpotyRedirectUri'
      'Spotyexpires'
      'Spotyaccess_token'
      'Spotyscope'
      'Spotyrefresh_token' 
      'Spotytoken_type'
      'YoutubeAccessToken'
      'Youtubeexpires_in'
      'Youtubecode'
      'Youtuberefresh_token'
    )
    #Load settings into temp hash to be committed on save or discarded on cancel
    try{
      $thisapp.configTemp = Import-SerializedXML -Path $thisApp.Config.Config_Path -isConfig
    }catch{
      write-ezlogs "An exception occurred importing config file for tempconfig at: $($thisApp.Config.Config_Path)" -CatchError $_
      if($thisApp.Config){
        $thisapp.configTemp = $thisapp.config.psobject.Copy()
      }
    }   
    if($Reload -and $hashsetup.Window.Visibility -in 'Hidden','Collapsed'){
      write-ezlogs "######## Reloading and resetting existing Show-SettingsWindow window" -showtime -logtype Setup -linesbefore 1
    }else{
      #############################################################################
      #region Initialize UI Controls and Events
      #############################################################################
      #---------------------------------------------- 
      #region Initialize Xaml
      #----------------------------------------------
      try{
        #$hashsetup = [hashtable]::Synchronized(@{})
        write-ezlogs "######## Executing Show-SettingsWindow" -showtime -logtype Setup -linesbefore 1
        
        #Measure total startup time of UI and Settings
        $setup_TotalStart_Measure = [system.diagnostics.stopwatch]::StartNew()

        #Measure startup time of Initializing UI
        $setup_Initialize_UI_Measure = [system.diagnostics.stopwatch]::StartNew()
        if($First_Run){
          [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
          Add-Type -AssemblyName System.Drawing, System.Windows.Forms, WindowsFormsIntegration
        }
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Startup
        $add_Window_XML = "$($thisapp.Config.Current_Folder)\Views\Settings.xaml"
        try{
          if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.PrimaryAccentColor){
            $PrimaryAccentColor = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
          }else{
            $PrimaryAccentColor = "{StaticResource MahApps.Brushes.Accent}"
          } 
        }catch{
          write-ezlogs "An exception occurred changing theme for Show-SettingsWindow" -showtime -catcherror $_
        }
        if($PrimaryAccentColor){        
          $xaml = [System.IO.File]::ReadAllText($add_Window_XML).replace('Views/Styles.xaml',"$($thisapp.Config.Current_Folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$PrimaryAccentColor")
        }else{
          $xaml = [System.IO.File]::ReadAllText($add_Window_XML).replace('Views/Styles.xaml',"$($thisapp.Config.Current_Folder)`\Views`\Styles.xaml")
        }                
        if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Script path: $($thisapp.Config.Current_Folder)\Views\Settings.xaml" -showtime -logtype Setup -loglevel 3}    
        $hashsetup.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        while ($reader.Read())
        {
          $name=$reader.GetAttribute('Name')
          if(!$name){ 
            $name=$reader.GetAttribute('x:Name')
          }
          if($name -and $hashsetup.Window){
            $hashsetup."$($name)" = [System.WeakReference]::new(($hashsetup.Window.FindName($name))).Target
          }
        }
        $reader.Dispose()           
        $reader = $null
        $XAML = $Null
        $setup_Initialize_UI_Measure.stop()
        write-ezlogs ">>>> Setup_Initialize_UI_Measure (Load/Process Xaml)" -showtime -logtype Setup -PerfTimer $setup_Initialize_UI_Measure -Perf 
        $setup_Initialize_UI_Measure = $Null
      }catch{
        write-ezlogs "An exception occurred when loading xaml" -showtime -CatchError $_
      }
      #---------------------------------------------- 
      #endregion Initialize Xaml
      #----------------------------------------------

      #---------------------------------------------- 
      #region Set Window Properties
      #----------------------------------------------
      try{
        #Measure startup time of setting Window properties
        $Setup_Set_Window_Properties_Measure = [system.diagnostics.stopwatch]::StartNew()

        $hashsetup.Logo.Source=$Logo
        $hashsetup.Window.title =$PageTitle
        $hashsetup.Window.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"      
        $hashsetup.Window.icon.Freeze()  
        $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
        if($PrimaryMonitor.Bounds.Height -lt '1080'){
          $hashsetup.window.MaxHeight=$PrimaryMonitor.WorkingArea.Height
        }
        $hashsetup.window.TaskbarItemInfo.Description = "SETUP - $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)"
        $hashsetup.PageHeader.content = $PageHeader    
        $hashsetup.Window.IsWindowDraggable="True" 
        $hashsetup.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
        $hashsetup.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
        $hashsetup.Window.ShowTitleBar=$true
        $hashsetup.Window.UseNoneWindowStyle = $false
 
        $stream_image = [System.IO.File]::OpenRead("$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTop.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth='735'
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $SettingsBackground = [System.Windows.Media.ImageBrush]::new()
        $SettingsBackground.ImageSource = $image
        $settingsBackground.ViewportUnits = "Absolute"
        $settingsBackground.Viewport = "0,0,600,263"
        $settingsBackground.TileMode = 'Tile'
        $SettingsBackground.Freeze()
        $hashsetup.Window.Background = $SettingsBackground 
        
        $stream_image = [System.IO.File]::OpenRead("$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowBottom.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth='735'
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $hashsetup.Background_Image_Bottom.Source = $image
                        
        $stream_image = [System.IO.File]::OpenRead("$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth='735'
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Dispose()
        $stream_image = $Null
        $image.Freeze()
        $imagebrush = [System.Windows.Media.ImageBrush]::new()
        $ImageBrush.ImageSource = $image
        $imagebrush.TileMode = 'Tile'
        $imagebrush.ViewportUnits = "Absolute"
        $imagebrush.Viewport = "0,0,600,283"
        $hashsetup.Background_TileGrid.Background = $imagebrush
        $hashsetup.Editor_Help_Flyout.Background = $imagebrush
        $image = $Null

        #$hashsetup.Window.WindowStyle = 'none' 
        if($Update){
          $hashsetup.Cancel_Button_Text.text = "CANCEL"
          $hashsetup.Cancel_Setup_Button.ToolTip = "Cancel and Close Settings"
          $hashsetup.Save_Setup_Button.ToolTip = "Apply and Close Settings" 
          $hashsetup.Setup_Button_Textblock.text = "APPLY" 
        }
        if($Use_RoundedCorners){
          $hashsetup.Window.Style = $hashsetup.Window.TryFindResource('WindowChromeStyle')
          $hashsetup.Window.add_SizeChanged({    
              try{ 
                #write-ezlogs ">>>> Setup window sized changed, updating windowchromestyle" -showtime
                $hashsetup.Window.Style = $hashsetup.Window.TryFindResource('WindowChromeStyle')
                #$hashsetup.Window.UpdateDefaultStyle()           
              }catch{
                write-ezlogs 'An exception occurred in hashsetup.Window.add_SizeChanged' -showtime -catcherror $_
              }
          })
        }

        [System.Windows.RoutedEventHandler]$hashsetup.Window_Close_Command = {
          param($sender)
          try{
            Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -close -Dequeue
          }catch{
            write-ezlogs 'An exception occurred in Window_Close_Command event' -showtime -catcherror $_
          }
        }
        [System.Windows.RoutedEventHandler]$hashsetup.TopMost_Command = {
          param($sender)
          try{
            if($hashsetup.Window.TopMost){
              $hashsetup.Window.TopMost = $false
            }else{
              $hashsetup.Window.TopMost = $true
            }                             
          }catch{
            write-ezlogs 'An exception occurred in TopMost_Command' -showtime -catcherror $_
          }
        }
        [System.Windows.RoutedEventHandler]$hashsetup.ShowinTaskbar_Command = {
          param($sender)
          try{
            if($hashsetup.Window.ShowInTaskbar){
              $hashsetup.Window.ShowInTaskbar = $false
            }else{
              $hashsetup.Window.ShowInTaskbar = $true
            }                             
          }catch{
            write-ezlogs 'An exception occurred in ShowinTaskbar_Command' -showtime -catcherror $_
          }
        }
        $hashsetup.Window.ContextMenu = $Null
        $items = [System.Collections.Generic.List[Object]]::new()
        $StayOnTop = @{
          'Header' = "Stay On Top"
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Command' = $hashsetup.TopMost_Command
          'Binding' = $hashsetup.Window
          'binding_property_path' = 'TopMost'
          'binding_mode' = [System.Windows.Data.BindingMode]::OneWay
          'Icon_kind' = 'PinOutline'
          'Enabled' = $true
          'IsCheckable' = $true
        }
        [void]$items.Add($StayOnTop)
        $ShowinTaskbar = @{
          'Header' = "Show in Taskbar"
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Command' = $hashsetup.ShowinTaskbar_Command
          'Binding' = $hashsetup.Window
          'binding_property_path' = 'ShowInTaskbar'
          'binding_mode' = [System.Windows.Data.BindingMode]::OneWay
          'Icon_kind' = 'PinOutline'
          'Enabled' = $true
          'IsCheckable' = $true
        }
        [void]$items.Add($ShowinTaskbar)
        $Exit_App = @{
          'Header' = "Close Settings"
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Command' = $hashsetup.Window_Close_Command
          'Icon_kind' = 'Close'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [void]$items.Add($Exit_App)
        Add-WPFMenu -control $hashsetup.Window -items $items -AddContextMenu -sourceWindow $hashsetup

        $hashsetup.Flyout_Scriptblock = {
          Param($sender)        
          try{
            if($sender.isOpen){
              $sender.isOpen = $false
            }
          }catch{
            write-ezlogs "An exception occurred in Flyout_Scriptblock" -catcherror $_
          }        
        }
        $relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $hashsetup.Flyout_Scriptblock -target $hashsetup.Editor_Help_Flyout
        $hashsetup.Editor_Help_Flyout.tag = $relaycommand
        if($ApplyColorTheme -and $thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.PrimaryAccentColor){    
          try{
            $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
            $themes = $theme.GetLibraryThemes()
            $themeManager = [ControlzEx.Theming.ThemeManager]::new()
            $themeindex = $themes.name.IndexOf($thisApp.Config.Current_Theme.Name)
            if($themeindex -ne -1){
              $newtheme = $themes.Where({$_.Name -eq $thisApp.Config.Current_Theme.Name})
            }
            if($themes){
              [void]$themes.Dispose() 
              $themes = $Null
            }
            $theme = $null           
            [void]$thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
            [void]$thememanager.ChangeTheme($hashsetup.Window,$newtheme.Name,$false)      
          }catch{
            write-ezlogs "An exception occurred setting theme to $($newtheme | out-string)" -CatchError $_
          } 
        }          
      }catch{
        write-ezlogs "An exception occurred setting Window properties" -showtime -catcherror $_
      }finally{
        if($Setup_Set_Window_Properties_Measure){
          $Setup_Set_Window_Properties_Measure.stop()
          write-ezlogs ">>>> Setup_Set_Window_Properties_Measure" -showtime -logtype Setup -PerfTimer $Setup_Set_Window_Properties_Measure -Perf 
          $Setup_Set_Window_Properties_Measure = $Null
        }
      }    
      #---------------------------------------------- 
      #endregion Set Window Properties
      #----------------------------------------------

      #---------------------------------------------- 
      #region MouseDown Event
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.MouseDown_Command = {
        param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed){
          try{
            $hashsetup.Window.DragMove()
          }catch{
            write-ezlogs "An exception occurred in hashsetup Window MouseDown event" -showtime -catcherror $_
          }
        }
      }
      $hashsetup.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::MouseDownEvent,$hashsetup.MouseDown_Command)
      $hashsetup.PageHeader.AddHandler([System.Windows.Controls.Label]::MouseDownEvent,$hashsetup.MouseDown_Command)
      #---------------------------------------------- 
      #endregion MouseDown Event
      #----------------------------------------------

      #---------------------------------------------- 
      #region Hyperlink_RequestNavigate
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Hyperlink_RequestNavigate = {
        param ($sender,$e)
        try{
          $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
          if($sender.NavigateUri -match $url_fullpattern){
            $path = $sender.NavigateUri
          }else{
            $path = (resolve-path $($sender.NavigateUri -replace 'file:///','')).Path
          }     
          write-ezlogs ">>>> Navigating to path: $($path)" -showtime -logtype Setup
          if($path){
            start $($path)
          }else{
            write-ezlogs "Couldnt resolve valid path to navigate from sender: $($sender | out-string)" -warning -logtype Setup
          }
        }catch{
          write-ezlogs "An exception occurred in hashsetup.Hyperlink_RequestNavigate" -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion Hyperlink_RequestNavigate
      #----------------------------------------------
            
      #---------------------------------------------- 
      #region Next Button
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Next_Button_Command = {
        param ($sender)
        try{
          if($hashsetup.Setup_TabControl.SelectedIndex -eq 0){
            $hashsetup.Setup_TabControl.SelectedIndex = 1
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 1){
            $hashsetup.Setup_TabControl.SelectedIndex = 2
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 2){
            $hashsetup.Setup_TabControl.SelectedIndex = 3
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 3){
            $hashsetup.Setup_TabControl.SelectedIndex = 4
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Save_Setup_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 4){
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Prev_Button.isEnabled = $true
          }         
        }catch{
          write-ezlogs "An exception occurred in Next_Button click event" -CatchError $_ -showtime
        }
      }
      $hashsetup.Next_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Next_Button_Command)
      #---------------------------------------------- 
      #endregion Next Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Prev Button
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Prev_Button_Command = {
        param ($sender)
        try{
          if($hashsetup.Setup_TabControl.SelectedIndex -eq 0){
            $hashsetup.Prev_Button.isEnabled = $false
            $hashsetup.Next_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 1){
            $hashsetup.Setup_TabControl.SelectedIndex = 0
            $hashsetup.Prev_Button.isEnabled = $false
            $hashsetup.Next_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 2){
            $hashsetup.Setup_TabControl.SelectedIndex = 1
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 3){
            $hashsetup.Setup_TabControl.SelectedIndex = 2
            $hashsetup.Next_Button.isEnabled = $true
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 4){
            $hashsetup.Setup_TabControl.SelectedIndex = 3
            $hashsetup.Next_Button.isEnabled = $true
            $hashsetup.Prev_Button.isEnabled = $true
          }         
        }catch{
          write-ezlogs "An exception occurred in Prev_Button click event" -CatchError $_ -showtime
        }
      }
      $hashsetup.Prev_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Prev_Button_Command)
      #---------------------------------------------- 
      #endregion Prev Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Tab Selection Change
      #----------------------------------------------
      $hashsetup.Current_NavigationIndex = 0
      [System.Windows.RoutedEventHandler]$hashsetup.TabControlSelectionChanged_Command = {
        param ($sender,$e)
        try{
          if($hashsetup.Setup_TabControl.SelectedIndex -eq 0){
            $hashsetup.Prev_Button.isEnabled = $false
            $hashsetup.Next_Button.isEnabled = $true
            if(!$hashsetup.Update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
              $hashsetup.Current_NavigationIndex = 0
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 1){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
            if(!$hashsetup.Update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
              $hashsetup.Current_NavigationIndex = 1
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 2){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
            if(!$hashsetup.Update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
              $hashsetup.Current_NavigationIndex = 2
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 3){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
            if(!$hashsetup.Update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
              $hashsetup.Current_NavigationIndex = 3
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 4){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Save_Setup_Button.isEnabled = $true
            if(!$hashsetup.Update){
              $hashsetup.Current_NavigationIndex = 4
            }
          }         
        }catch{
          write-ezlogs "An exception occurred in Setup_TabControl add_SelectionChanged  event" -CatchError $_ -showtime
        } 
      }
      [void]$hashsetup.Prev_Button.AddHandler([MahApps.Metro.Controls.MetroTabControl]::SelectionChangedEvent,$hashsetup.TabControlSelectionChanged_Command)
      #----------------------------------------------
      #endregion Tab Selection Change
      #----------------------------------------------      
                 
      #---------------------------------------------- 
      #region Remove Media Location Button
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$RemoveclickEvent = {
        param ($sender,$e)
        try{
          $itemtoremove = $hashsetup.MediaLocations_Grid.SelectedItem
          if($hashsetup.MediaLocations_Grid.items -contains $itemtoremove){
            Write-ezlogs ">>> Removing MediaLocations_Grid Path $($itemtoremove.path)" -showtime -logtype Setup
            [void]$hashsetup.MediaLocations_Grid.Items.Remove($itemtoremove)
            $hashsetup.MediaLocations_Grid.items.refresh()
          }else{
            Write-ezlogs "Cannot find MediaLocations_Grid.Item to remove ($($itemtoremove))" -showtime -warning -logtype Setup
          }
          if($hashsetup.LocalMedia_items -contains $itemtoremove){
            Write-ezlogs ">>> Removing Local Media Path $($itemtoremove.path)" -showtime -logtype Setup
            [void]$hashsetup.LocalMedia_items.Remove($itemtoremove) 
          }else{
            Write-ezlogs "Cannot find Local Media item to remove ($($itemtoremove))" -showtime -warning -logtype Setup
          }
          $hashsetup.total_localMedia = $Null
          if($syncHash.MediaTable.ItemsSource){         
            $synchash.window.Dispatcher.Invoke("Background",[action]{ 
                $hashsetup.total_localMedia = $syncHash.MediaTable.ItemsSource.ItemCount     
            }) 
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: $($hashsetup.total_localMedia)"
          }else{
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: TBD" 
          }         
        }catch{
          write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
        }
      }  
      [System.Windows.RoutedEventHandler]$RemoveAllclickEvent = {
        param ($sender,$e)
        try{
          if($hashSetup.LocalMedia_items){
            [void]$hashSetup.LocalMedia_items.clear()
          }
          [void]$hashsetup.MediaLocations_Grid.items.clear()
          $hashsetup.total_localMedia = $Null
          if($syncHash.MediaTable.ItemsSource){         
            $synchash.window.Dispatcher.Invoke("Background",[action]{ 
                $hashsetup.total_localMedia = $syncHash.MediaTable.ItemsSource.ItemCount
            }) 
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: $($hashsetup.total_localMedia)"
          }else{
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: TBD" 
          }
        }catch{
          write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
        }
      } 
      [System.Windows.RoutedEventHandler]$RemoveSpotifyPlaylistclickEvent = {
        param ($sender,$e)
        try{
          [void]$hashsetup.SpotifyPlaylists_Grid.Items.Remove($hashsetup.SpotifyPlaylists_Grid.SelectedItem)
        }catch{
          write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
        }
      }  
      [System.Windows.RoutedEventHandler]$RemoveSpotifyAllPlaylistclickEvent = {
        param ($sender,$e)
        try{
          [void]$hashsetup.SpotifyPlaylists_Grid.items.clear()
        }catch{
          write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$RemovePlaylistclickEvent = {
        param ($sender,$e)
        try{
          if($hashsetup.YoutubePlaylists_Grid.items -contains $hashsetup.YoutubePlaylists_Grid.SelectedItem){
            Write-ezlogs ">>> Removing Youtube Playlist $($hashsetup.YoutubePlaylists_Grid.SelectedItem)" -showtime -logtype Setup
            [void]$hashSetup.YoutubePlaylists_itemsArray.Remove($hashsetup.YoutubePlaylists_Grid.SelectedItem)   
            [void]$hashSetup.YoutubePlaylists_Grid.items.Remove($hashsetup.YoutubePlaylists_Grid.SelectedItem)    
          }else{
            Write-ezlogs "Cannot find Youtube Playlist to remove ($($hashsetup.YoutubePlaylists_Grid.SelectedItem))" -showtime -warning -logtype Setup
          }
        }catch{
          write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
        }
      }  
      [System.Windows.RoutedEventHandler]$RemoveAllPlaylistclickEvent = {
        param ($sender,$e)
        try{
          if($hashSetup.YoutubePlaylists_itemsArray){
            [void]$hashSetup.YoutubePlaylists_itemsArray.clear()
          }        
          [void]$hashsetup.YoutubePlaylists_Grid.items.clear()
        }catch{
          write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
        }
      } 
      [System.Windows.RoutedEventHandler]$RemoveTwitchPlaylistclickEvent = {
        param ($sender,$e)
        try{
          if($sender.Name -eq 'TwitchProxy_dismiss_button'){
            if($hashsetup.Twitch_Custom_Proxy_Grid.items -contains $hashsetup.Twitch_Custom_Proxy_Grid.SelectedItem){
              Write-ezlogs ">>> Removing Twitch Playlist $($hashsetup.Twitch_Custom_Proxy_Grid.SelectedItem)" -showtime -logtype Setup
              [void]$hashsetup.Twitch_Custom_Proxy_Grid.items.Remove($hashsetup.Twitch_Custom_Proxy_Grid.SelectedItem)
            }else{
              Write-ezlogs "Cannot find Twitch Proxy item to remove ($($hashsetup.Twitch_Custom_Proxy_Grid.SelectedItem))" -showtime -warning -logtype Setup 
            }
          }else{
            if($hashsetup.TwitchPlaylists_Grid.items -contains $hashsetup.TwitchPlaylists_Grid.SelectedItem){
              Write-ezlogs ">>> Removing Twitch Playlist $($hashsetup.TwitchPlaylists_Grid.SelectedItem)" -showtime -logtype Setup
              [void]$hashSetup.TwitchPlaylists_items.Remove($hashsetup.TwitchPlaylists_Grid.SelectedItem)       
            }else{
              Write-ezlogs "Cannot find Twitch Playlist to remove ($($hashsetup.TwitchPlaylists_Grid.SelectedItem))" -showtime -warning -logtype Setup 
            }
          }
        }catch{
          write-ezlogs "An exception occurred for Twitch removeclickevent" -showtime -catcherror $_
        }
      } 

      [System.Windows.RoutedEventHandler]$AddTwitchAllProxyclickEvent = {
        param ($sender,$e)
        try{
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Twitch Proxy","Enter the url of the Twitch Playlist Proxy",$button_settings)
          if(-not [string]::IsNullOrEmpty($result)){
            if($hashsetup.Twitch_Custom_Proxy_Grid.items.url -notcontains $result){
              write-ezlogs ">>>> Adding new Twitch Playlist Proxy URL: $result" -logtype Setup
              $Number = $hashsetup.Twitch_Custom_Proxy_Grid.items.Number | Select-Object -Last 1
              if(-not [string]::IsNullOrEmpty($Number)){
                $Number++
              }else{
                $Number = 0
              }
              [void]$hashsetup.Twitch_Custom_Proxy_Grid.items.add([PSCustomObject]@{
                  Number=[int]$Number
                  URL=$result
              })
            }else{
              write-ezlogs "Twitch Playlist Proxy URL has already been to Twitch_Custom_Proxy_Grid" -warning -logtype Setup
            }
          }  
        }catch{
          write-ezlogs "An exception occurred for Twitch AddTwitchAllProxyclickEvent" -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$RemoveTwitchAllPlaylistclickEvent = {
        param ($sender,$e)
        try{
          if($sender.Name -eq 'TwitchProxy_dismissAll_button'){
            [void]$hashsetup.Twitch_Custom_Proxy_Grid.items.clear()
            #[void]$thisApp.config.TwitchProxies.clear()
          }else{
            [void]$hashsetup.TwitchPlaylists_items.clear()
            [void]$hashsetup.TwitchPlaylists_Grid.items.clear()
          }         
        }catch{
          write-ezlogs "An exception occurred for Twitch removeallclickevent" -showtime -catcherror $_
        }
      }   
      #MarkdownScrollViewer HyperlinkComman 
      $MarkDownLinkScriptBlock = {
        $link = $args[1]
        try{
          write-ezlogs ">>>> Clicked markdown link to open: $($link)" -logtype Setup
          if((Test-ValidPath $link -PathType Any)){
            write-ezlogs " | Opening: $($link)" -logtype Setup
            start-process $link
          }elseif($link -match 'RestartAsUser'){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Restart App?","This will attempt to restart the app under the current logged on user permission context ($($env:username)).`n`nAre you sure?",$okandCancel,$Button_Settings)    
            if($result -eq 'Affirmative'){
              write-ezlogs "User wished to proceed, restarting app as user: $($env:username)" -showtime -warning -logtype Setup
              use-runas -RestartAsUser
            }else{
              write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Markdown HyperlinkCommand" -catcherror $_
        }
      }
      if($hashsetup.MarkdownScrollViewer){
        $markdowncommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $MarkDownLinkScriptBlock -target $hashsetup.MarkdownScrollViewer
        $hashsetup.MarkdownScrollViewer.engine.HyperlinkCommand = $markdowncommand
      }

      #Add MediaLocations Grid Buttons      
      if($hashsetup.MediaLocations_Grid.Columns.count -lt 5){
        <#        $buttontag = @{        
            hashsetup=$hashsetup
            thisApp=$thisApp
        }#>  
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismiss_button")
        [void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveclickEvent)
        [void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveclickEvent)
        #[void]$buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $dataTemplate = [System.Windows.DataTemplate]::new()
        $dataTemplate.VisualTree = $buttonFactory
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismissAll_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllclickEvent)
        #[void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory        
        $buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate 
        $buttonColumn.DisplayIndex = 0  
        [void]$hashsetup.MediaLocations_Grid.Columns.add($buttonColumn)
      }
      #Add SpotifyPlaylists Grid Buttons 
      if($hashsetup.SpotifyPlaylists_Grid.Columns.count -lt 5){
        <#        $buttontag = @{        
            hashsetup=$hashsetup
            thisApp=$thisApp
        }#>  
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "SpotifyPlaylists_dismiss_button")
        [void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveSpotifyPlaylistclickEvent)
        [void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveSpotifyPlaylistclickEvent)
        #[void]$buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $dataTemplate = [System.Windows.DataTemplate]::new()
        $dataTemplate.VisualTree = $buttonFactory
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "SpotifyPlaylists_dismissAll_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveSpotifyAllPlaylistclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveSpotifyAllPlaylistclickEvent)
        #[void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory        
        $buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate 
        $buttonColumn.DisplayIndex = 0  
        [void]$hashsetup.SpotifyPlaylists_Grid.Columns.add($buttonColumn)
      }
      #Add YoutubePlaylists Grid Buttons 
      if($hashsetup.YoutubePlaylists_Grid.Columns.count -lt 5){
        <#        $buttontag = @{        
            hashsetup=$hashsetup
            thisApp=$thisApp
        } #> 
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismiss_button")
        [void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemovePlaylistclickEvent)
        [void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemovePlaylistclickEvent)
        #[void]$buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $dataTemplate = [System.Windows.DataTemplate]::new()
        $dataTemplate.VisualTree = $buttonFactory
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismissAll_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllPlaylistclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllPlaylistclickEvent)
        #[void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
        $buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate 
        $buttonColumn.DisplayIndex = 0  
        [void]$hashsetup.YoutubePlaylists_Grid.Columns.add($buttonColumn)
      } 

      #Add TwitchPlaylists Grid Buttons
      if($hashsetup.TwitchPlaylists_Grid.Columns.count -lt 5){
        <#        $buttontag = @{        
            hashsetup=$hashsetup
            thisApp=$thisApp
        }#>  
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismiss_button")
        [void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchPlaylistclickEvent)
        [void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchPlaylistclickEvent)
        #[void]$buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $dataTemplate = [System.Windows.DataTemplate]::new()
        $dataTemplate.VisualTree = $buttonFactory
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismissAll_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchAllPlaylistclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchAllPlaylistclickEvent)
        #[void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
        $buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate 
        $buttonColumn.DisplayIndex = 0  
        [void]$hashsetup.TwitchPlaylists_Grid.Columns.add($buttonColumn)
      }
      #Add TwitchProxy Grid Buttons
      if($hashsetup.Twitch_Custom_Proxy_Grid.Columns.count -lt 5){
        <#        $buttontag = @{        
            hashsetup=$hashsetup
            thisApp=$thisApp
        }#>  
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
        [void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "TwitchProxy_dismiss_button")
        [void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchPlaylistclickEvent)
        [void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchPlaylistclickEvent)
        #[void]$buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $dataTemplate = [System.Windows.DataTemplate]::new()
        $dataTemplate.VisualTree = $buttonFactory
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "TwitchProxy_dismissAll_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchAllPlaylistclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchAllPlaylistclickEvent)
        #[void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
        $buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate 
        $buttonColumn.DisplayIndex = 1
        [void]$hashsetup.Twitch_Custom_Proxy_Grid.Columns.add($buttonColumn)

        #Add Button
        $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
        $buttonColumn.MinWidth = '80'
        $buttonHeaderFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Add URL")
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
        [void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "TwitchProxy_Add_button")
        [void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$AddTwitchAllProxyclickEvent)
        [void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$AddTwitchAllProxyclickEvent)   
        $headerdataTemplate = [System.Windows.DataTemplate]::new()
        $headerdataTemplate.VisualTree = $buttonheaderFactory
        #$buttonColumn.CellTemplate = $dataTemplate
        $buttonColumn.HeaderTemplate = $headerdataTemplate
        $buttonColumn.DisplayIndex = 0
        [void]$hashsetup.Twitch_Custom_Proxy_Grid.Columns.add($buttonColumn)
      }           
      #---------------------------------------------- 
      #endregion Remove Media Location Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Help_Flyout_OpenChanged_Command = {
        param ($sender)
        try{
          if($sender.isOpen){
            $sender.Height=[Double]::NaN
          }else{
            $sender.Height = '0'
          }
        }catch{
          write-ezlogs "An exception occurred in Editor_Help_Flyout.add_IsOpenChanged" -showtime -catcherror $_
        }
      }
      $hashsetup.Editor_Help_Flyout.AddHandler([MahApps.Metro.Controls.Flyout]::IsOpenChangedEvent,$hashsetup.Help_Flyout_OpenChanged_Command)
      #---------------------------------------------- 
      #endregion Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start Tray Only Toggle
      #----------------------------------------------   
      $hashsetup.Start_Tray_only_Toggle_Command = {
        param ($sender)
        try{
          $thisapp.configTemp.Start_Tray_only = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Editor_Help_Flyout.add_IsOpenChanged" -showtime -catcherror $_
        }
      }
      $hashsetup.Start_Tray_only_Toggle.add_Toggled($hashsetup.Start_Tray_only_Toggle_Command)
      #---------------------------------------------- 
      #endregion Start Tray Only Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start Tray Only Help
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Start_Tray_only_Click_Command = {
        param ($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Start_Minimized.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Start_Tray_only_Toggle.content -open -clear
        }catch{
          write-ezlogs "An exception occurred in Start_Tray_only_Button.add_Click" -CatchError $_
        }
      }
      $hashsetup.Start_Tray_only_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Start_Tray_only_Click_Command)
      #---------------------------------------------- 
      #endregion Start Tray Only Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start Mini Only Toggle
      #----------------------------------------------   
      $hashsetup.Start_Mini_only_Toggle_Command = {
        param ($sender)
        try{
          $thisapp.configTemp.Start_Mini_only = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Editor_Help_Flyout.add_IsOpenChanged" -showtime -catcherror $_
        }
      }
      $hashsetup.Start_Mini_only_Toggle.add_Toggled($hashsetup.Start_Mini_only_Toggle_Command)
      #---------------------------------------------- 
      #endregion Start Mini Only Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start Mini Only Help
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Start_Mini_only_Button_Click_Command = {
        param ($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Start_Mini_Only.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Start_Mini_only_Toggle.content -open -clear
        }catch{
          write-ezlogs "An exception occurred in Start_Mini_only_Button.add_Click" -CatchError $_ 
        }
      }
      $hashsetup.Start_Mini_only_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Start_Mini_only_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Start Mini Only Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Disable_Tray Toggle
      #----------------------------------------------    
      $hashsetup.Disable_Tray_Toggle_Command = {
        param ($sender)
        try{
          if($sender.isOn){
            $thisapp.configTemp.Disable_Tray = $true
            $thisapp.configTemp.Minimize_To_Tray = $false
            $thisapp.configTemp.Start_Tray_only = $false
            $hashsetup.Minimize_To_Tray_Toggle.IsOn = $false
            $hashsetup.Start_Tray_only_Toggle.IsOn = $false
            $hashsetup.Minimize_To_Tray_Toggle.IsEnabled = $false
            $hashsetup.Start_Tray_only_Toggle.IsEnabled = $false
          }else{
            $thisapp.configTemp.Disable_Tray = $false
            $hashsetup.Minimize_To_Tray_Toggle.IsEnabled = $true
            $hashsetup.Start_Tray_only_Toggle.IsEnabled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Disable_Tray_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Disable_Tray_Toggle.add_Toggled($hashsetup.Disable_Tray_Toggle_Command)
      #---------------------------------------------- 
      #endregion Disable_Tray Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Disable_Tray Help
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Disable_Tray_Button_Click_Command = {
        param ($sender)
        try{ 
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Disable_Tray.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Disable_Tray_Toggle.content -clear
        }catch{
          write-ezlogs "An exception occurred in Disable_Tray_Button.add_Click" -CatchError $_
        }
      }
      $hashsetup.Disable_Tray_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Disable_Tray_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Disable_Tray Help
      #----------------------------------------------


      #---------------------------------------------- 
      #region Minimize To Tray Toggle
      #----------------------------------------------    
      $hashsetup.Minimize_To_Tray_Toggle_Command = {
        param ($sender)
        try{
          $thisapp.configTemp.Minimize_To_Tray = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Minimize_To_Tray_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Minimize_To_Tray_Toggle.add_Toggled($hashsetup.Minimize_To_Tray_Toggle_Command)
      #---------------------------------------------- 
      #endregion Minimize To Tray Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Minimize To Tray Help
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Minimize_To_Tray_Button_Click_Command = {
        param ($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Minimize_to_Tray.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Minimize_To_Tray_Toggle.content -open -clear
        }catch{
          write-ezlogs "An exception occurred in Minimize_To_Tray_Button.add_Click" -CatchError $_
        }
      }
      $hashsetup.Minimize_To_Tray_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Minimize_To_Tray_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Minimize To Tray Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start on Windows Login Toggle
      #----------------------------------------------
      $hashsetup.Start_On_Windows_Login_Toggle_Command = {
        param ($sender)
        try{
          $thisapp.configTemp.Start_On_Windows_Login = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Start_On_Windows_Login_Toggle.add_Toggled" -catcherror $_
        }
      }
      $hashsetup.Start_On_Windows_Login_Toggle.add_Toggled($hashsetup.Start_On_Windows_Login_Toggle_Command)
      #---------------------------------------------- 
      #endregion Start on Windows Login Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start on Windows Login Help
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Start_On_Windows_Login_Button_Click_Command = {
        param ($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\StartOnWindows.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Start_On_Windows_Login_Toggle.content -open -clear
        }catch{
          write-ezlogs "An exception occurred in Start_On_Windows_Login_Button.add_Click" -CatchError $_
        }
      }
      $hashsetup.Start_On_Windows_Login_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Start_On_Windows_Login_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Start on Windows Login Help
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Verbose Logging Control
      #----------------------------------------------
      $hashsetup.Log_Path_textbox.Add_TextChanged({
          try{
            if([system.io.file]::Exists($hashsetup.Log_Path_textbox.text) -or [System.IO.Directory]::Exists($hashsetup.Log_Path_textbox.text)){
              $hashsetup.Log_Path_Label.BorderBrush="LightGreen"         
            }else{
              $hashsetup.Log_Path_Label.BorderBrush="Red"
            }
          }catch{
            write-ezlogs "An exception occurred in Log_Path_textbox.Add_TextChanged" -showtime -catcherror $_
          }
      })
      $hashsetup.Log_label_transitioningControlContent = $hashsetup.Log_label_transitioningControl.content

      $hashsetup.Verbose_logging_Toggle_Command = {
        param($sender)
        try{
          if($sender.isOn -eq $true){
            $hashsetup.Log_label_transitioningControl.content = $hashsetup.Log_label_transitioningControlContent      
            $hashsetup.Log_Path_Label.IsEnabled = $true 
            $hashsetup.Log_StackPanel.Height = [Double]::NaN           
            $hashsetup.Log_Path_textbox.text = $thisapp.configTemp.Log_file
            $hashsetup.Log_Path_textbox.IsEnabled = $true    
            $hashsetup.Log_Path_Browse.IsEnabled = $true
            $thisapp.configTemp.Dev_mode = $true
          }else{
            $hashsetup.Log_label_transitioningControl.content = '' 
            $hashsetup.Log_StackPanel.Height = '0'          
            $hashsetup.Log_Path_Label.IsEnabled = $false      
            $hashsetup.Log_Path_textbox.IsEnabled = $false      
            $hashsetup.Log_Path_Browse.IsEnabled = $false 
            $thisapp.configTemp.Dev_mode = $false
          }
        }catch{
          write-ezlogs "An exception occurred in Verbose_logging_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Verbose_logging_Toggle.add_Toggled($hashsetup.Verbose_logging_Toggle_Command)

      $hashsetup.Log_Path_Browse.add_Click({
          try{
            $result = Open-FolderDialog -Title 'Select the directory where logs will be stored'
            if(-not [string]::IsNullOrEmpty($result)){$hashsetup.Log_Path_textbox.text = $result}  
          }catch{
            write-ezlogs "An exception occurred in Log_Path_Browse.add_Click" -CatchError $_
          }
      }) 
      $hashsetup.Log_Path_Hyperlink.Inlines.add("$([system.io.path]::GetFileName($thisApp.Config.Log_file))")
      [void]$hashsetup.Log_Path_Hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Hyperlink_RequestNavigate)
      $hashsetup.Log_Path_Hyperlink.NavigateUri = $thisApp.Config.Log_file
      #---------------------------------------------- 
      #endregion Verbose Logging Control
      #----------------------------------------------

      #---------------------------------------------- 
      #region Verbose Logging Help
      #----------------------------------------------
      $hashsetup.Verbose_logging_Button.add_Click({
          try{ 
            Update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Dev_mode.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Verbose_logging_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Verbose_logging_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Verbose Logging Help
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Notification_Audio Toggle
      #----------------------------------------------
      $hashsetup.Notification_Audio_Toggle_Command = {
        param($sender)
        try{
          $thisapp.configTemp.Notification_Audio = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Notification_Audio_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Notification_Audio_Toggle.add_Toggled($hashsetup.Notification_Audio_Toggle_Command)
      #---------------------------------------------- 
      #endregion Notification_Audio Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Notification_Audio Help
      #----------------------------------------------
      $hashsetup.Notification_Audio_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Notification_Audio.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Notification_Audio_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Splash_Screen_Audio_Button.add_Click" -CatchError $_ 
          }
      })
      #---------------------------------------------- 
      #endregion Notification_Audio Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Snapshots Toggle
      #----------------------------------------------
      $hashsetup.SnapShots_textbox.Add_TextChanged({
          try{
            if([system.io.directory]::Exists($hashsetup.SnapShots_textbox.text)){
              $hashsetup.SnapShots_Label.BorderBrush="LightGreen"         
            }else{
              $hashsetup.SnapShots_Label.BorderBrush = 'Red'
            }
          }catch{
            write-ezlogs "An exception occurred inSnapShots_textbox.Add_TextChanged" -showtime -catcherror $_
          }
      })
      $hashsetup.SnapShots_Toggle_Command = {
        param($sender)
        try{
          $thisapp.configTemp.Video_Snapshots = $sender.isOn
          if($synchash.window.IsInitialized){
            Update-MainWindow -synchash $synchash -thisapp $thisApp -Control 'ScreenShot_Button' -Property 'isEnabled' -value $sender.isOn
          }
        }catch{
          write-ezlogs "An exception occurred in SnapShots_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.SnapShots_Toggle.add_Toggled($hashsetup.SnapShots_Toggle_Command)

      $hashsetup.App_SnapShots_Toggle_Command = {
        param($sender)
        try{
          $thisapp.configTemp.App_Snapshots = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in App_SnapShots_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.App_SnapShots_Toggle.add_Toggled($hashsetup.App_SnapShots_Toggle_Command)

      $hashsetup.SnapShots_Browse.add_Click({
          try{
            $SnapShot_Path = Open-FolderDialog -Title 'Select the directory path where Snapshots will be saved to' -InitialDirectory $hashsetup.SnapShots_textbox.text
            if([system.io.directory]::Exists($SnapShot_Path)){
              $hashsetup.SnapShots_textbox.text = $SnapShot_Path   
              $thisapp.configTemp.Snapshots_Path = $SnapShot_Path
              $hashsetup.SnapShots_Hyperlink.Inlines.add("Open Snapshots Folders")
              $hashsetup.SnapShots_Hyperlink.NavigateUri = [uri]$thisapp.configTemp.Snapshots_Path
              if($hashsetup.SnapShots_Hyperlink.Visibility){
                $hashsetup.SnapShots_Hyperlink.Visibility = 'Visible'
              }           
            }else{
              $hashsetup.SnapShots_textbox.text = ''
              $thisapp.configTemp.Snapshots_Path = ''
              $hashsetup.SnapShots_Hyperlink.NavigateUri = $Null
              $hashsetup.SnapShots_Hyperlink.inlines.clear()
            }
          }catch{
            write-ezlogs "An exception occurred in SnapShots_Browse click event" -showtime -catcherror $_
          }
      })  
      [void]$hashsetup.SnapShots_Hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Hyperlink_RequestNavigate)
      #---------------------------------------------- 
      #endregion Snapshots Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Snapshots Help
      #----------------------------------------------
      $hashsetup.SnapShots_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Snapshots.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.SnapShots_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in SnapShots_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Snapshots Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region App Snapshots Help
      #----------------------------------------------
      $hashsetup.App_SnapShots_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\App_Snapshots.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.App_SnapShots_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in App_SnapShots_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion App Snapshots Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Performance Mode Toggle
      #----------------------------------------------
      $hashsetup.Performance_Mode_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Enable_Performance_Mode = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Performance_Mode_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Performance_Mode_Toggle.add_Toggled($hashsetup.Performance_Mode_Toggle_Command)
      #---------------------------------------------- 
      #endregion Performance Mode Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Performance Mode Help
      #----------------------------------------------
      $hashsetup.Performance_Mode_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Performance_Mode.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Performance_Mode_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Performance_Mode_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Performance Mode Help
      #----------------------------------------------

      if($hashsetup.High_DPI_Toggle){
        #---------------------------------------------- 
        #region High DPI Toggle
        #----------------------------------------------
        $hashsetup.High_DPI_Toggle_Command = {
          Param($Sender)
          try{
            $thisapp.configTemp.Enable_HighDPI = $Sender.isOn
          }catch{
            write-ezlogs "An exception occurred in High_DPI_Toggle.add_Toggled" -CatchError $_
          }
        }
        $hashsetup.High_DPI_Toggle.add_Toggled($hashsetup.High_DPI_Toggle_Command)
        #---------------------------------------------- 
        #endregion High DPI Toggle
        #----------------------------------------------

        #---------------------------------------------- 
        #region High DPI Help
        #----------------------------------------------
        $hashsetup.High_DPI_Button_Command = {
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\High_DPI.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.High_DPI_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in High_DPI_Button.add_Click" -CatchError $_
          }
        }
        $hashsetup.High_DPI_Button.add_Click($hashsetup.High_DPI_Button_Command)
        #---------------------------------------------- 
        #endregion High DPI Help
        #----------------------------------------------
      }
      #---------------------------------------------- 
      #region Use Hardware Acceleration Toggle
      #----------------------------------------------
      $hashsetup.Use_HardwareAcceleration_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Use_HardwareAcceleration = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Use_HardwareAcceleration_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Use_HardwareAcceleration_Toggle.add_Toggled($hashsetup.Use_HardwareAcceleration_Toggle_Command)
      #---------------------------------------------- 
      #endregion Use Hardware Acceleration Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Use Hardware Acceleration Help
      #----------------------------------------------
      $hashsetup.Use_HardwareAcceleration_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Hardware_Acceleration.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Use_HardwareAcceleration_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Use_HardwareAcceleration_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Use Hardware Acceleration Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_WebEQSupport Toggle
      #----------------------------------------------
      $hashsetup.Enable_WebEQSupport_Toggle_Command = {
        Param($Sender)
        try{
          if($hashsetup.Enable_WebEQSupport_Toggle.isOn -eq $true){
            if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("$("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe")").versioninfo.fileversion -replace ', ','.'
            }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
            }else{
              write-ezlogs "VB-Cable virtual audio device does not appear to be installed, requesting permissions to install" -warning -logtype setup
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Yes'
              $Button_Settings.NegativeButtonText = 'No'  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Install Virtual Audio","Enabling EQ Support for WebPlayers requires installation of a virtual audio device (VB-Cable).`n`nDo you want to continue?",$okandCancel,$Button_Settings)    
              if($result -eq 'Affirmative'){
                write-ezlogs "User wished to proceed, installing vb-cable" -showtime -warning -logtype Setup
                try{
                  if($hashsetup.Window){
                    $hashsetup.window.hide()
                  }
                  if($First_Run){
                    write-ezlogs ">>>> UnHiding Splash Screen" -logtype Setup
                    Update-SplashScreen -hash $hash -SplashMessage 'Installing VB-Cable...' -Splash_More_Info 'Please Wait' -show
                  }else{
                    write-ezlogs ">>>> Launching new Splash Screen" -logtype Setup
                    Start-SplashScreen -SplashTitle "$($thisApp.Config.App_Name) Media Player" -SplashMessage 'Installing VB-Cable...' -Splash_More_Info 'Please Wait' -current_folder $thisapp.Config.Current_Folder -log_file $thisapp.Config.Log_file
                  }                  
                  if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe")){
                    write-ezlogs " | Attempting to install from $($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe" -showtime -logtype setup
                    try{
                      $default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)   
                    }catch{
                      write-ezlogs "An exception occurred installing VB-Cable" -catcherror $_
                    }
                    if(!$default_output_Device.DeviceID){
                      try{
                        write-ezlogs "Unable to get default audio device via MMDeviceEnumerator:...attempting Get-AudioDevice" -logtype setup            
                        $Audio_output_Device = Get-AudioDevice -List | Where-Object {$_.type -eq 'Playback' -and $_.default}
                      }catch{
                        write-ezlogs "An exception occurred executing Get-AudioDevice" -catcherror $_
                      }
                      if($Audio_output_Device){
                        $DeviceID = $Audio_output_Device.id
                        $DeviceName = $Audio_output_Device.Name
                      }else{
                        $NoDefaultDevice = $true
                      }
                    }else{
                      $DeviceID = $default_output_Device.DeviceID
                      $DeviceName = $default_output_Device.FriendlyName
                    }
                    if($DeviceID){
                      try{
                        write-ezlogs " | Current Default Audio Device: $($DeviceName) -- ID: $DeviceID" -logtype setup            
                        Start-Process "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe" -ArgumentList '-i -h' -Wait -Verb RunAs
                        write-ezlogs " | Resetting Default Audio Device to: $($DeviceName)" -logtype setup
                        $set_AudioDevice = Get-AudioDevice -ID $DeviceID | Set-AudioDevice -DefaultOnly
                      }catch{
                        if($_.Exception -match 'No AudioDevice with that ID'){
                          write-ezlogs "No AudioDevice was found or able to be set with id $($DeviceID) - enumerating all devices" -logtype setup -warning
                          $audio_devices = Get-AudioDevice -List | Where-Object {$_.Type -eq 'Playback'} | Select-Object -first 1
                          $set_AudioDevice = Get-AudioDevice -ID $audio_devices.ID | Set-AudioDevice -DefaultOnly
                          $DefaultDeviceWarning = $true                     
                        }else{
                          write-ezlogs "An exception occurred installing VB-Cable" -catcherror $_
                        }
                      }                                     
                      if($set_AudioDevice){
                        write-ezlogs " | New Default Audio Device (should be same as previous): $($set_AudioDevice | out-string)" -logtype setup
                      }
                    }else{
                      $NoDefaultDevice = $true
                    }                   
                  }else{
                    if(!$(get-command choco*)){
                      [void](confirm-requirements -thisApp $thisApp -noRestart)
                    }
                    write-ezlogs "Attempting to install VB-Cable from chocolatey" -showtime -warning -logtype Setup 
                    $choco_install = choco upgrade vb-cable --confirm --force --acceptlicense
                    write-ezlogs ">>>> Verifying if vb-cable was installed successfully...." -showtime -loglevel 2 -logtype Setup
                    $chocoappmatch = choco list vb-cable
                    if($chocoappmatch){
                      $appinstalled = $($chocoappmatch | Select-String vb-cable | out-string).trim()
                    } 
                  }
                  if(!$NoDefaultDevice){
                    if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
                      $appinstalled = [System.IO.FileInfo]::new("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe").versioninfo.fileversion -replace ', ','.'
                      write-ezlogs "VB-Cable successfully installed to ${env:ProgramFiles(x86)}\VB\CABLE\ -- Version: $appinstalled" -logtype Setup -Success
                      $thisapp.configTemp.Enable_WebEQSupport = $true
                      $hashsetup.Enable_WebEQSupport_Toggle.isOn = $true
                      $Message = "VB-Cable was installed succesfully!"
                      $Header = 'Install Virtual Audio'
                      $color = 'lightgreen'
                    }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
                      $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
                      write-ezlogs "VB-Cable successfully installed to $env:ProgramW6432\VB\CABLE\ -- Version: $appinstalled" -logtype Setup -Success
                      $thisapp.configTemp.Enable_WebEQSupport = $true
                      $hashsetup.Enable_WebEQSupport_Toggle.isOn = $true
                      $Message = "VB-Cable was installed succesfully!"
                      $Header = 'Install Virtual Audio'
                      $color = 'lightgreen'
                    }else{
                      write-ezlogs "Vb-Audio did not installed correctly -- disabling Web EQ Suport" -warning -logtype Setup
                      $appinstalled = ''
                      $thisapp.configTemp.Enable_WebEQSupport = $false
                      $hashsetup.Enable_WebEQSupport_Toggle.isOn = $false
                      update-EditorHelp -content "VB-Cable was not installed succesfully! Check the logs for more information or try again. Disabling Web EQ Support" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Install Virtual Audio' -color Orange
                      return
                    }
                    if($DefaultDeviceWarning){
                      $Message += "`nUnable to determine which audio device should be default. The following active device was found and set as default but may not be correct:`n`nDevice Name: $($audio_devices.Name)"
                      $Header = 'WARNING: Install Virtual Audio'
                      $Color = 'Orange'
                    }
                  }else{
                    $Message += "`nNo default audio device was found or there is an issue with audio device on this system. Cannot continue"
                    $Header = 'WARNING: Failed to Install Virtual Audio'
                    $Color = 'Orange'
                    $thisapp.configTemp.Enable_WebEQSupport = $false
                    $hashsetup.Enable_WebEQSupport_Toggle.isOn = $false
                  }
                  update-EditorHelp -content $Message -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header $Header -color $Color
                }catch{
                  write-ezlogs "An exception occurred installing VB-Cable" -catcherror $_
                  update-EditorHelp -content "An exception occurred installing the Virtual Audio Device:`n$_" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Install Virtual Audio' -color Tomato  
                  $thisapp.configTemp.Enable_WebEQSupport = $false
                  $hashsetup.Enable_WebEQSupport_Toggle.isOn = $false
                }finally{
                  if($hashsetup.Window){
                    write-ezlogs ">>>> Unhiding setup window" -logtype Setup
                    $hashsetup.window.show()
                  }
                  if($hash.Window){
                    if($First_Run){
                      write-ezlogs ">>>> Hide Splash Screen for first run" -logtype Setup
                      Update-SplashScreen -hash $hash -Hide
                    }else{
                      write-ezlogs ">>>> Closing Splash Screen" -logtype Setup
                      Update-SplashScreen -hash $hash -Close
                    }
                  }
                  if($default_output_Device){
                    $default_output_Device.dispose()
                    $default_output_Device = $null
                  }    
                }                
              }else{
                write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
                $thisapp.configTemp.Enable_WebEQSupport = $false
                $hashsetup.Enable_WebEQSupport_Toggle.isOn = $false
                return
              }
            }
            if($appinstalled){
              write-ezlogs ">>>> VB-Cable is installed -- Version: $appinstalled -- Enabling Enable_EQWeb_Toggle" -logtype Setup
              $thisapp.configTemp.Enable_WebEQSupport = $true
            }else{
              write-ezlogs "Unable to verify if VB-Cable is installed" -warning -logtype Setup
            }           
            if($synchash.Enable_EQWeb_Toggle){
              write-ezlogs "[Show-SettingsWindow] >>>> Enabling Enable_EQWeb_Toggle" -logtype Setup
              Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Enable_EQWeb_Toggle' -Property 'IsEnabled' -value $true
            }
          }
          else{
            $thisapp.configTemp.Enable_WebEQSupport = $false
            if($synchash.Enable_EQWeb_Toggle){
              write-ezlogs "[Show-SettingsWindow] >>>> Disabling Enable_EQWeb_Toggle" -logtype Setup
              Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Enable_EQWeb_Toggle' -Property 'IsEnabled' -value $false
            }
            #vb-cable Removal
            try{
              $appinstalled = $Null
              if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
                $appinstalled = [System.IO.FileInfo]::new("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe").versioninfo.fileversion -replace ', ','.'
                $vbcablesetup = "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe"
              }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
                $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
                $vbcablesetup = "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe"
              }
              if($appinstalled){
                write-ezlogs "VB-Cable virtual audio device is installed, requesting permissions to uninstall" -warning -logtype setup
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                $Button_Settings.AffirmativeButtonText = 'Yes'
                $Button_Settings.NegativeButtonText = 'No'  
                $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative                
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Uninstall Virtual Audio","Do you wish to uninstall the virtual audio device (VB-Cable)?",$okandCancel,$Button_Settings)  
                if($result -eq 'Affirmative'){
                  write-ezlogs "User wished to proceed, uninstalling vb-cable" -showtime -warning -logtype Setup
                  try{
                    if($hashsetup.Window){
                      $hashsetup.window.hide()
                    }
                    if($first_run -or $hash.window.Visibilty -eq 'Hidden'){
                      Update-SplashScreen -hash $hash -SplashMessage 'Uninstalling VB-Cable...' -Splash_More_Info 'Please Wait' -Show
                    }else{
                      Start-SplashScreen -SplashTitle "$($thisApp.Config.App_Name) Media Player" -SplashMessage 'Uninstalling VB-Cable...' -Splash_More_Info 'Please Wait' -current_folder $thisapp.Config.Current_Folder -log_file $thisapp.Config.Log_file
                    }                
                    if([system.io.file]::Exists($vbcablesetup)){
                      write-ezlogs " | Executing $vbcablesetup with arguments -u -h with verb Runas" -logtype Setup
                      Start-Process "$vbcablesetup" -ArgumentList '-u -h' -Wait -Verb Runas
                    }else{
                      if(!$(get-command choco*)){
                        [void](confirm-requirements -thisApp $thisApp -noRestart)
                      }
                      write-ezlogs "Attempting to uninstall VB-Cable from chocolatey" -showtime -warning -logtype Setup 
                      $choco_install = choco uninstall vb-cable --confirm --force --acceptlicense
                      write-ezlogs ">>>> Verifying if vb-cable was removed successfully...." -showtime -loglevel 2 -logtype Setup
                      $chocoappmatch = choco list vb-cable
                      if($chocoappmatch){
                        $appinstalled = $($chocoappmatch | Select-String vb-cable | out-string).trim()
                      } 
                    }
                    if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
                      write-ezlogs "VB-Cable was not removed succesfully - install still found at ${env:ProgramFiles(x86)}\VB\CABLE\" -logtype Setup -warning
                      update-EditorHelp -content "VB-Cable was not removed succesfully! You may need to manually uninstall from the Control Panel" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Uninstall Virtual Audio' -color Orange
                    }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
                      write-ezlogs "VB-Cable was not removed succesfully - install still found at $env:ProgramW6432\VB\CABLE\" -logtype Setup -warning
                      update-EditorHelp -content "VB-Cable was not removed succesfully! You may need to manually uninstall from the Control Panel" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Uninstall Virtual Audio' -color Orange
                    }else{
                      write-ezlogs "Vb-Audio was removed successfully" -logtype Setup -Success
                      update-EditorHelp -content "VB-Cable was removed succesfully!" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Uninstall Virtual Audio' -color lightgreen
                    }
                  }catch{
                    write-ezlogs "An exception occurred uninstalling VB-Cable" -catcherror $_
                  }finally{
                    if($hashsetup.Window){
                      write-ezlogs "Unhiding Setup Window" -logtype Setup
                      $hashsetup.window.show()
                    }
                    if($hash.Window){
                      if($First_Run){
                        write-ezlogs ">>>> Hide Splash Screen for first run" -logtype Setup
                        Update-SplashScreen -hash $hash -Hide
                      }else{
                        write-ezlogs ">>>> Closing Splash Screen" -logtype Setup
                        Update-SplashScreen -hash $hash -Close
                      }
                    }
                  }                
                }else{
                  write-ezlogs "User did not wish to uninstall VB-Cable" -showtime -warning -logtype Setup
                  return
                }  
              }else{
                write-ezlogs "VB-Audio does not appear to be installed -- skipping uninstall process" -warning -logtype Setup
              } 
            }catch{
              write-ezlogs "An exception occurred removing vb-cable" -catcherror $_
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Enable_WebEQSupport_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Enable_WebEQSupport_Toggle.add_Toggled($hashsetup.Enable_WebEQSupport_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable_WebEQSupport Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_WebEQSupport Help
      #----------------------------------------------
      $hashsetup.Enable_WebEQSupport_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_WebEQSupport.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Enable_WebEQSupport_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Enable_WebEQSupport_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Enable_WebEQSupport Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Show Notifications Toggle
      #----------------------------------------------
      $hashsetup.Show_Notifications_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Show_Notifications = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Show_Notifications_Toggle.add_Toggled" -showtime -catcherror $_
        }
      }
      $hashsetup.Show_Notifications_Toggle.add_Toggled($hashsetup.Show_Notifications_Toggle_Command) 
      #---------------------------------------------- 
      #endregion Show Notifications Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Show Notifications Help
      #----------------------------------------------
      $hashsetup.Show_Notifications_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Show_Notifications.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Show_Notifications_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Show_Notifications_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Show Notifications Help
      #----------------------------------------------  

      #---------------------------------------------- 
      #region Enable_Marquee Toggle
      #----------------------------------------------
      $hashsetup.Enable_Marquee_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Enable_Marquee = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_Marquee_Toggle.add_Toggled" -CatchError $_ 
        }
      }
      $hashsetup.Enable_Marquee_Toggle.add_Toggled($hashsetup.Enable_Marquee_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable_Marquee Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_Marquee Help
      #----------------------------------------------
      $hashsetup.Enable_Marquee_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Marquee_Overlay.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Enable_Marquee_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Enable_Marquee_Button.add_Click" -CatchError $_ 
          }
      })
      #---------------------------------------------- 
      #endregion Enable_Marquee Help
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Open_VideoPlayer Toggle
      #----------------------------------------------
      $hashsetup.Open_VideoPlayer_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Open_VideoPlayer = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Open_VideoPlayer_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Open_VideoPlayer_Toggle.add_Toggled($hashsetup.Open_VideoPlayer_Toggle_Command) 
      #---------------------------------------------- 
      #endregion Open_VideoPlayer Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Open_VideoPlayer Help
      #----------------------------------------------
      $hashsetup.Open_VideoPlayer_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\OpenClose_VideoPlayer.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Open_VideoPlayer_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Open_VideoPlayer_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Open_VideoPlayer Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Remember_Playback_Progress Toggle
      #----------------------------------------------
      $hashsetup.Remember_Playback_Progress_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Remember_Playback_Progress = $Sender.isOn
          if(!$Sender.isOn){
            $thisapp.configTemp.Current_Playing_Media = $Null
          }           
        }catch{
          write-ezlogs "An exception occurred in Remember_Playback_Progress_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Remember_Playback_Progress_Toggle.add_Toggled($hashsetup.Remember_Playback_Progress_Toggle_Command)
      #---------------------------------------------- 
      #endregion Remember_Playback Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Remember_Playback Help
      #----------------------------------------------
      $hashsetup.Remember_Playback_Progress_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Remember_Progress.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Remember_Playback_Progress_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Remember_Playback_Progress_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Remember_Playback Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start_Paused_Toggle
      #----------------------------------------------
      $hashsetup.Start_Paused_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Start_Paused = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Start_Paused_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Start_Paused_Toggle.add_Toggled($hashsetup.Start_Paused_Toggle_Command)
      #---------------------------------------------- 
      #endregion Start_Paused_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Start_Paused Help
      #----------------------------------------------
      $hashsetup.Start_Paused_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Start_Paused.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Start_Paused_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Start_Paused_Button.add_Click" -CatchError $_
          }
      })
      #---------------------------------------------- 
      #endregion Start_Paused Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Current_Visualization Combobox
      #----------------------------------------------
      [void]$hashsetup.Current_Visualization_ComboBox.items.add('Goom')
      [void]$hashsetup.Current_Visualization_ComboBox.items.add('Spectrum')
      $hashsetup.Current_Visualization_ComboBox.add_SelectionChanged({
          Param($Sender)
          try{
            if($Sender.Selectedindex -ne -1){ 
              if($Sender.selecteditem -eq 'Spectrum'){
                $Visualization = 'Visual'
              }else{
                $Visualization = $Sender.selecteditem
              }
              $hashsetup.Current_Visualization_Label.BorderBrush = 'LightGreen'      
              write-ezlogs ">>>> Enabling Use_Visualizations -- Current_Visualization: $($Visualization)" -logtype Setup
              $thisapp.configTemp.Current_Visualization = $Visualization
              #$thisapp.configTemp.Use_Visualizations = $true
            }
            else{       
              $hashsetup.Current_Visualization_Label.BorderBrush = 'Red'   
              write-ezlogs ">>>> Disabling Use_Visualizations -- no Current_Visualization selected" -logtype Setup
              $thisapp.configTemp.Use_Visualizations = $false
              $thisapp.configTemp.Current_Visualization = ''    
            }
          }catch{
            write-ezlogs "An exception occurred in Current_Visualization_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Current_Visualization Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Use_Visualizations Toggle
      #----------------------------------------------
      $hashsetup.Use_Visualizations_Toggle_Command = {
        Param($Sender)
        try{
          if($Sender.isOn -eq $true){      
            $hashsetup.Current_Visualization_ComboBox.isEnabled = $true            
            if($hashsetup.Current_Visualization_ComboBox.Selectedindex -ne -1){
              write-ezlogs ">>>> Enabling Use_Visualizations -- Current_Visualization_ComboBox.Selecteditem: $($hashsetup.Current_Visualization_ComboBox.Selecteditem)" -logtype Setup
              $thisapp.configTemp.Use_Visualizations = $true
            }else{
              write-ezlogs ">>>> Cannot enable Use_Visualizations -- Current_Visualization_ComboBox.Selectedindex -eq -1" -logtype Setup
              $thisapp.configTemp.Use_Visualizations = $false
              $hashsetup.Use_Visualizations_Toggle.isOn = $false
            }            
          }else{         
            $hashsetup.Current_Visualization_ComboBox.isEnabled = $false 
            write-ezlogs ">>>> Disabling Use_Visualizations" -logtype Setup
            $thisapp.configTemp.Use_Visualizations = $false    
          }
        }catch{
          write-ezlogs "An exception occurred in Use_Visualizations_Toggle.add_Toggled" -CatchError $_ 
        }
      }
      $hashsetup.Use_Visualizations_Toggle.add_Toggled($hashsetup.Use_Visualizations_Toggle_Command)
      #---------------------------------------------- 
      #endregion Use_Visualizations Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Use_Visualizations Help
      #----------------------------------------------
      $hashsetup.Use_Visualizations_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Visualizations.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Use_Visualizations_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Use_Visualizations_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Use_Visualizations Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Audio_Output Combobox
      #----------------------------------------------    
      [void]$hashsetup.Audio_Output_ComboBox.items.clear()
      [void]$hashsetup.Audio_Output_ComboBox.items.add('Default')
      #TODO: Refactor this to not use selection change event but only on save event  
      <#      $hashsetup.Audio_Output_ComboBox.add_SelectionChanged({
          Param($Sender)

      }) #>
      #---------------------------------------------- 
      #endregion Audio_Output Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Audio_Output Help
      #----------------------------------------------
      $hashsetup.Audio_Output_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Audio_OutputDevice.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Audio_Output_Label.content -clear
          }catch{
            write-ezlogs "An exception occurred in Audio_Output_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Audio_Output Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Discord Integration Toggle
      #----------------------------------------------
      $hashsetup.Discord_Integration_Toggle_Command = {
        Param($Sender)
        try{
          write-ezlogs ">>>> Setting Discord Integration to: $($Sender.isOn)" -logtype Discord -LogLevel 2
          $thisapp.configTemp.Discord_Integration = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Discord_Integration_Toggle.add_Toggled" -CatchError $_ -enablelogs
        }
      }
      $hashsetup.Discord_Integration_Toggle.add_Toggled($hashsetup.Discord_Integration_Toggle_Command)
      #---------------------------------------------- 
      #endregion Discord Integration Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Discord Integration Help
      #----------------------------------------------
      $hashsetup.Discord_Integration_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Discord_Integration.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Discord_Integration_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Audio_Output_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Discord Integration Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_Subtitles Toggle
      #----------------------------------------------
      $hashsetup.Enable_Subtitles_Toggle_Command = {
        Param($Sender)
        try{
          $thisapp.configTemp.Enable_Subtitles = $Sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_Subtitles_Toggle.add_Toggled" -CatchError $_ -enablelogs
        }
      }
      $hashsetup.Enable_Subtitles_Toggle.add_Toggled($hashsetup.Enable_Subtitles_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable_Subtitles Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_Subtitles Help
      #----------------------------------------------
      $hashsetup.Enable_Subtitles_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_Subtitles.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Enable_Subtitles_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Enable_Subtitles_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Enable_Subtitles Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Hotkeys_Button Help
      #----------------------------------------------
      $hashsetup.Hotkeys_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Hotkeys.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Hotkeys_Label.content -clear
          }catch{
            write-ezlogs "An exception occurred in Hotkeys_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Hotkeys_Button Help
      #----------------------------------------------
      
      #$relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $ScriptBlock -target $hashsetup.VolUpHotkey
      #[MahApps.Metro.Controls.TextBoxHelper]::SetButtonCommand($hashsetup.VolUpHotkey,$relaycommand)
      #TODO: HOTKEYS
      <#      $HashSetup.Hotkeys = [Hotkeys]::new()

          $HashSetup.Hotkeys.Add_PropertyChanged({
          Param($Sender,$e)
          try{
          write-ezlogs "The property $($e.PropertyName) was changed to: $($Sender.($e.PropertyName))"
          }catch{
          write-ezlogs "An exception occurred in Auto_UpdateCheck_Toggle.add_Toggled" -CatchError $_ -enablelogs
          }
          })
          $Binding = [System.Windows.Data.Binding]::new()
          $Binding.Source = $HashSetup.Hotkeys
          $Binding.Mode = 'Twoway'
          $Binding.Path = "Mute"
          $Binding.ValidatesOnDataErrors = $true
          $null = [System.Windows.Data.BindingOperations]::SetBinding($hashsetup.VolMutehotkey,[MahApps.Metro.Controls.HotKeyBox]::HotKeyProperty, $Binding)

          $Binding = [System.Windows.Data.Binding]::new()
          $Binding.Source = $HashSetup.Hotkeys
          $Binding.Mode = 'Twoway'
          $Binding.Path = "VolUp"
          $Binding.ValidatesOnDataErrors = $true
          $null = [System.Windows.Data.BindingOperations]::SetBinding($hashsetup.VolUpHotkey,[MahApps.Metro.Controls.HotKeyBox]::HotKeyProperty, $Binding)

          $Binding = [System.Windows.Data.Binding]::new()
          $Binding.Source = $HashSetup.Hotkeys
          $Binding.Mode = 'Twoway'
          $Binding.Path = "VolDown"
          $Binding.ValidatesOnDataErrors = $true
      $null = [System.Windows.Data.BindingOperations]::SetBinding($hashsetup.VolDownhotkey,[MahApps.Metro.Controls.HotKeyBox]::HotKeyProperty, $Binding)#>
      #---------------------------------------------- 
      #region Auto_UpdateCheck Toggle
      #----------------------------------------------
      if($thisApp.Enable_Update_Features){
        $hashsetup.Auto_UpdateCheck_Toggle_Command = {
          Param($sender)
          try{
            $thisapp.configTemp.Auto_UpdateCheck = $Sender.isOn
          }catch{
            write-ezlogs "An exception occurred in Auto_UpdateCheck_Toggle.add_Toggled" -CatchError $_ -enablelogs
          }
        }
        $hashsetup.Auto_UpdateCheck_Toggle.add_Toggled($hashsetup.Auto_UpdateCheck_Toggle_Command)
        #---------------------------------------------- 
        #endregion Auto_UpdateCheck Toggle
        #----------------------------------------------

        #---------------------------------------------- 
        #region Auto_UpdateCheck Help
        #----------------------------------------------
        $hashsetup.Auto_UpdateCheck_Button.add_Click({
            try{ 
              update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Auto_UpdateCheck.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Auto_UpdateCheck_Toggle.content -clear
            }catch{
              write-ezlogs "An exception occurred in Auto_UpdateCheck_Button.add_Click" -CatchError $_ -enablelogs
            }
        })
        #---------------------------------------------- 
        #endregion Auto_UpdateCheck Help
        #----------------------------------------------

        #---------------------------------------------- 
        #region Auto_UpdateInstall Toggle
        #----------------------------------------------
        $hashsetup.Auto_UpdateInstall_Toggle_Command = {
          Param($sender)
          try{
            $thisapp.configTemp.Auto_UpdateInstall = $Sender.isOn
          }catch{
            write-ezlogs "An exception occurred in Auto_UpdateInstall_Toggle.add_Toggled" -CatchError $_ -enablelogs
          }
        }
        $hashsetup.Auto_UpdateInstall_Toggle.add_Toggled($hashsetup.Auto_UpdateInstall_Toggle_Command)
        #---------------------------------------------- 
        #endregion Auto_UpdateCheck Toggle
        #----------------------------------------------

        #---------------------------------------------- 
        #region Auto_UpdateInstall Help
        #----------------------------------------------
        $hashsetup.Auto_UpdateInstall_Button.add_Click({
            try{ 
              update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Auto_UpdateInstall.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Auto_UpdateInstall_Toggle.content -clear
            }catch{
              write-ezlogs "An exception occurred in Auto_UpdateInstall_Button.add_Click" -CatchError $_ -enablelogs
            }
        })
        #---------------------------------------------- 
        #endregion Auto_UpdateInstall Help
        #----------------------------------------------
      }elseif($hashsetup.Updates_Settings_Expander){
        $hashsetup.Updates_Settings_Expander.isEnabled = $false
        $hashsetup.Updates_Settings_Expander.visibility = 'Collapsed'
      }
      #---------------------------------------------- 
      #region Enable_MediaCasting_Toggle
      #----------------------------------------------
      $hashsetup.Enable_MediaCasting_Toggle_Command = {
        Param($sender)
        try{        
          $thisapp.configTemp.Use_MediaCasting = $Sender.isOn
          if($sender.isOn){
            if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Enabling Use_MediaCasting" -logtype Setup -LogLevel 2 -Dev_mode}
            #TODO: Move to apply event
            if($synchash.VideoView_Cast_Button){
              Update-MainWindow -synchash $synchash -thisapp $thisapp -Control 'VideoView_Cast_Button' -Property 'isEnabled' -value $true
              Update-MainWindow -synchash $synchash -thisapp $thisapp -Control 'VideoView_Cast_Button' -Property 'Tooltip' -value 'Cast Media to other Device'  
            }
          }
          else{
            if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Disabling Use_MediaCasting" -logtype Setup -LogLevel 2 -Dev_mode}
            if($synchash.VideoView_Cast_Button){
              Update-MainWindow -synchash $synchash -thisapp $thisapp -Control 'VideoView_Cast_Button' -Property 'isEnabled' -value $false
              Update-MainWindow -synchash $synchash -thisapp $thisapp -Control 'VideoView_Cast_Button' -Property 'Tooltip' -value 'Media Casting Support is currently disabled'   
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Enable_MediaCasting_Toggle.add_Toggled" -CatchError $_ -enablelogs
        }
      }
      $hashsetup.Enable_MediaCasting_Toggle.add_Toggled($hashsetup.Enable_MediaCasting_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable_MediaCasting_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_MediaCasting Help
      #----------------------------------------------
      $hashsetup.Enable_MediaCasting_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_MediaCasting.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Enable_MediaCasting_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Enable_MediaCasting_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Enable_MediaCasting Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Cast_HTTPPort_textbox
      #----------------------------------------------
      $hashsetup.Cast_HTTPPort_textbox.add_textChanged({
          try{
            if(-not [string]::IsNullOrEmpty($hashsetup.Cast_HTTPPort_textbox.text)){   
              $hashsetup.Cast_HTTPPort_Label.BorderBrush = 'LightGreen' 
              Add-Member -InputObject $thisapp.configTemp -Name 'Cast_HTTPPort' -Value $($hashsetup.Cast_HTTPPort_textbox.text) -MemberType NoteProperty -Force
            }
            else{       
              $hashsetup.Cast_HTTPPort_Label.BorderBrush = 'Red'   
              Add-Member -InputObject $thisapp.configTemp -Name 'Cast_HTTPPort' -Value $null -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in Cast_HTTPPort_textbox.add_textChanged" -CatchError $_ -enablelogs
          }
      }) 

      #---------------------------------------------- 
      #endregion Cast_HTTPPort_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Cast_HTTPPort_HelpButton Help
      #----------------------------------------------
      $hashsetup.Cast_HTTPPort_HelpButton.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Cast_HTTPPort.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Enable_MediaCasting_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Cast_HTTPPort_HelpButton.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Cast_HTTPPort_HelpButton Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Audio_OutputModule Combobox
      #----------------------------------------------
      [void]$hashsetup.Audio_OutputModule_ComboBox.items.add('Auto')
      [void]$hashsetup.Audio_OutputModule_ComboBox.items.add('mmdevice')
      [void]$hashsetup.Audio_OutputModule_ComboBox.items.add('directsound')
      [void]$hashsetup.Audio_OutputModule_ComboBox.items.add('waveout')
      $hashsetup.Audio_OutputModule_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Audio_OutputModule_ComboBox.Selectedindex -ne -1){   
              $hashsetup.Audio_OutputModule_Textbox.BorderBrush = 'LightGreen' 
              Add-Member -InputObject $thisapp.configTemp -Name 'Audio_OutputModule' -Value $($hashsetup.Audio_OutputModule_ComboBox.selecteditem) -MemberType NoteProperty -Force
            }
            else{       
              $hashsetup.Audio_OutputModule_Textbox.BorderBrush = 'Red'   
              Add-Member -InputObject $thisapp.configTemp -Name 'Audio_OutputModule' -Value 'Auto' -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in Audio_OutputModule_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Audio_OutputModule Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Audio_OutputModule Help
      #----------------------------------------------
      $hashsetup.Audio_OutputModule_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Audio_OutputModule.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -Header $hashsetup.Audio_OutputModule_Textbox.text -open -clear
          }catch{
            write-ezlogs "An exception occurred in Audio_Output_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Audio_OutputModule Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region vlc_GlobalGain_textbox
      #----------------------------------------------
      $hashsetup.vlc_GlobalGain_textbox.add_textChanged({
          Param($sender)
          [double]$doubleref = [double]::NaN
          try{
            if(-not [string]::IsNullOrEmpty($sender.text) -and [double]::TryParse($sender.text,[ref]$doubleref) -and ($doubleref -ge 0 -and $doubleref -le 8)){
              $hashsetup.vlc_GlobalGain_Label.BorderBrush = 'LightGreen'
              $sender.ToolTip = ''
              $thisapp.configTemp.Libvlc_Global_Gain = $sender.text
            }else{
              $hashsetup.vlc_GlobalGain_Label.BorderBrush = 'Red'
              $sender.ToolTip = 'Current value is not valid. Must be a number with range of 0 - 8. Can include decimals'
              $thisapp.configTemp.Libvlc_Global_Gain = $Null
            }
          }catch{
            write-ezlogs "An exception occurred in vlc_GlobalGain_textbox.add_textChanged" -CatchError $_
          }
      }) 
      #----------------------------------------------
      #endregion vlc_GlobalGain_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region vlc_GlobalGain Help
      #----------------------------------------------
      $hashsetup.vlc_GlobalGain_HelpButton.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\vlc_GlobalGain.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.vlc_GlobalGain_Label.text -open -clear
          }catch{
            write-ezlogs "An exception occurred in vlc_GlobalGain_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion vlc_GlobalGain Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region vlc_Arguments_textbox
      #----------------------------------------------
      $hashsetup.vlc_Arguments_textbox.add_textChanged({
          try{
            if(-not [string]::IsNullOrEmpty($hashsetup.vlc_Arguments_textbox.text)){   
              $hashsetup.vlc_Arguments_Label.BorderBrush = 'LightGreen' 
              Add-Member -InputObject $thisapp.configTemp -Name 'vlc_Arguments' -Value $($hashsetup.vlc_Arguments_textbox.text) -MemberType NoteProperty -Force
            }
            else{       
              $hashsetup.vlc_Arguments_Label.BorderBrush = 'Red'   
              Add-Member -InputObject $thisapp.configTemp -Name 'vlc_Arguments' -Value $null -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in vlc_Arguments_textbox.add_textChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion vlc_Arguments_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region vlc_Arguments Help
      #----------------------------------------------
      $hashsetup.vlc_Arguments_HelpButton.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\vlc_Arguments.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.vlc_Arguments_Label.text -open -clear
          }catch{
            write-ezlogs "An exception occurred in vlc_Arguments_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion vlc_Arguments Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Optimize_Assembly_Button
      #----------------------------------------------
      $hashsetup.Update_Optimize_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $hashsetup.Update_Optimize_Timer_ScriptBlock = {
        try{
          if($this.tag -eq 'Requires Reboot'){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Optimization Requires Admin Permissions","$($thisApp.Config.App_name) Media Player must be run as an administrator in order to optimize Powershell Assemblies.`n`nDo you want to restart the app as admin now? You can then try executing Optimize Assemblies again.",$okandCancel,$Button_Settings)    
            if($result -eq 'Affirmative'){
              write-ezlogs "User wished to proceed, restarting app as admin" -showtime -warning -logtype Setup
              if($First_Run){
                Use-RunAs -ForceReboot -uninstall_Module -FreshStart
              }else{
                Use-RunAs -ForceReboot -uninstall_Module
              }
            }else{
              write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
            }    
          }elseif(-not [string]::IsNullOrEmpty($this.tag)){
            update-EditorHelp -content $this.tag -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Optimization Tools'
          }
          if($hashsetup.Optimize_Assembly_Button){
            $hashsetup.Optimize_Assembly_Button.isEnabled = $true        
            $hashsetup.Optimize_Assembly_Progress_Ring.isActive = $false
          }
          if($hashsetup.Optimize_Services_Button){
            $hashsetup.Optimize_Services_Button.isEnabled = $true
          }
          if($hashsetup.Optimize_Assembly_Progress_Ring){
            $hashsetup.Optimize_Services_Button.isEnabled = $true
          } 
          if($hashsetup.Optimization_Toggle){
            $hashsetup.Optimization_Toggle.isEnabled = $true
          }      
        }catch{
          write-ezlogs "An exception occurred in Update_Optimize_Timer" -catcherror $_
        }finally{
          $this.stop()
          $this.tag = $null
        }   
      }
      $hashsetup.Update_Optimize_Timer.add_Tick($hashsetup.Update_Optimize_Timer_ScriptBlock)

      $hashsetup.Optimize_Assembly_Button.add_Click({
          try{               
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Optimize .NET Assemblies","Optimizing Assemblies attempts to improve general Powershell performance by caching .NET assemblies. This process can take a while even on a fast machine. You can continue to use the app normally while optimization continues, but it will effect performance until the operation is complete.`n`nIt is HIGHLY RECOMMENDED to first read and review the help topics for these Optimizations before continuing`n`nDo you wish to continue?",$okandCancel,$Button_Settings)    
            if($result -eq 'Affirmative'){
              $hashsetup.Optimize_Assembly_Button.isEnabled = $false
              $hashsetup.Optimize_Services_Button.isEnabled = $false
              $hashsetup.Optimization_Toggle.isEnabled = $false
              $hashsetup.Optimize_Assembly_Progress_Ring.isActive = $true
              write-ezlogs "User wished to proceed, executing Optimize-Assemblines" -showtime -warning -logtype Setup
              Optimize-Assemblies -thisApp $thisApp -hashsetup $hashsetup #-UpdateGAC
            }else{
              write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
              $hashsetup.Optimize_Assembly_Button.isEnabled = $true
              $hashsetup.Optimization_Toggle.isEnabled = $true
              $hashsetup.Optimize_Services_Button.isEnabled = $true
              $hashsetup.Optimize_Assembly_Progress_Ring.isActive = $false
              return
            }       
          }catch{
            write-ezlogs "An exception occurred in Optimize_Assembly_Button.add_Click" -CatchError $_ -enablelogs
            $failure = $true
          }finally{
            if($failure){
              $hashsetup.Optimize_Assembly_Button.isEnabled = $true
              $hashsetup.Optimize_Services_Button.isEnabled = $true
              $hashsetup.Optimize_Assembly_Progress_Ring.isActive = $false
              $hashsetup.Optimization_Toggle.isEnabled = $true
            }
          }
      })
      #---------------------------------------------- 
      #endregion Optimize_Assembly_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Optimizations Help
      #----------------------------------------------
      $hashsetup.Optimization_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Optimization_tools.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Optimization_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Optimization_Button_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Optimizations Help
      #----------------------------------------------
      if($thisApp.Enable_Tor_Features){
        if($hashsetup.VPN_Grid.Visibility -eq 'Collapsed'){
          $hashsetup.VPN_Grid.Visibility = 'Visible'
        }
        if($hashsetup.VPN_StackPanel.Visibility -eq 'Collapsed'){
          $hashsetup.VPN_StackPanel.Visibility = 'Visible'
        }
        #---------------------------------------------- 
        #region Install_VPN_Button
        #----------------------------------------------
        $hashsetup.Update_VPN_Timer = [System.Windows.Threading.DispatcherTimer]::new()
        $hashsetup.Update_VPN_Timer_ScriptBlock = {
          try{
            if($this.tag -eq 'Requires Reboot'){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Yes'
              $Button_Settings.NegativeButtonText = 'No'  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"VPN Install Requires Admin Permissions","$($thisApp.Config.App_name) Media Player must be run as an administrator in order to install ProtonVPN.`n`nDo you want to restart the app as admin now? You can then try executing Install ProtonVPN again.",$okandCancel,$Button_Settings)    
              if($result -eq 'Affirmative'){
                write-ezlogs "User wished to proceed, restarting app as admin" -showtime -warning -logtype Setup
                if($First_Run){
                  Use-RunAs -ForceReboot -uninstall_Module -FreshStart
                }else{
                  Use-RunAs -ForceReboot -uninstall_Module
                }
              }else{
                write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
              }    
            }elseif(-not [string]::IsNullOrEmpty($this.tag)){
              update-EditorHelp -content $this.tag -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'VPN Tools'
            }
            if($hashsetup.Install_VPN_Button){
              $hashsetup.Install_VPN_Button.isEnabled = $true        
              $hashsetup.Install_VPN_Progress_Ring.isActive = $false
            }
            if($hashsetup.VPN_Toggle){
              $hashsetup.VPN_Toggle.isEnabled = $true
            }      
          }catch{
            write-ezlogs "An exception occurred in Update_VPN_Timer" -catcherror $_
          }finally{
            $this.stop()
            $this.tag = $null
          }   
        }
        $hashsetup.Update_VPN_Timer.add_Tick($hashsetup.Update_VPN_Timer_ScriptBlock)
        #---------------------------------------------- 
        #region VPN_Toggle
        #----------------------------------------------
        if($hashsetup.VPN_Toggle){
          $hashsetup.VPN_Toggle_Command = {
            Param($sender)
            try{
              if($sender.isOn){
                write-ezlogs ">>>> Enabling Use_Preferred_VPN" -logtype Setup -LogLevel 2   
                $thisapp.configTemp.Use_Preferred_VPN = $true
                #Add-Member -InputObject $thisapp.configTemp -Name 'Preferred_VPN' -Value 'ProtonVPN' -MemberType NoteProperty -Force
              }
              else{
                write-ezlogs ">>>> Disabling Use_Preferred_VPN" -logtype Setup -LogLevel 2 
                $thisapp.configTemp.Use_Preferred_VPN = $false
                #Add-Member -InputObject $thisapp.configTemp -Name 'Preferred_VPN' -Value '' -MemberType NoteProperty -Force  
              }
            }catch{
              write-ezlogs "An exception occurred in VPN_Toggle.add_Toggled" -CatchError $_
            }
          }
          $hashsetup.VPN_Toggle.add_Toggled($hashsetup.VPN_Toggle_Command)
        }
        #---------------------------------------------- 
        #endregion VPN_Toggle
        #----------------------------------------------
        $hashsetup.Install_VPN_Button.add_Click({
            try{               
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Yes'
              $Button_Settings.NegativeButtonText = 'No'  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Install ProtonVPN","This will download the latest public windows build of ProtonVPN, install it and then launch it.`n`nDo you wish to continue?",$okandCancel,$Button_Settings)    
              if($result -eq 'Affirmative'){
                $hashsetup.Install_VPN_Button.isEnabled = $false
                $hashsetup.VPN_Toggle.isEnabled = $false
                $hashsetup.Install_VPN_Progress_Ring.isActive = $true           
                write-ezlogs "User wished to proceed, executing Install_VPN" -showtime -warning -logtype Setup
                $ProtonVPN = Install-ProtonVPN -thisApp $thisApp
                if($ProtonVPN){
                  update-EditorHelp -content "ProtonVPN is already installed at: $($ProtonVPN)" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -clear -Open -Header 'Install ProtonVPN'
                }
                #Optimize-Assemblies -thisApp $thisApp
              }else{
                write-ezlogs "User did not wish to proceed" -showtime -warning -logtype Setup
                $hashsetup.Install_VPN_Button.isEnabled = $true
                $hashsetup.VPN_Toggle.isEnabled = $true
                $hashsetup.Install_VPN_Progress_Ring.isActive = $false
                return
              }       
            }catch{
              write-ezlogs "An exception occurred in Install_VPN_Button.add_Click" -CatchError $_ -enablelogs
              $failure = $true
            }finally{
              if($failure -or $ProtonVPN){
                $hashsetup.Install_VPN_Button.isEnabled = $true
                $hashsetup.Install_VPN_Progress_Ring.isActive = $false
                $hashsetup.VPN_Toggle.isEnabled = $true
              }
            }
        })
        #---------------------------------------------- 
        #endregion Install_VPN_Button
        #----------------------------------------------

        #---------------------------------------------- 
        #region VPN Help
        #----------------------------------------------
        $hashsetup.VPN_Button.add_Click({
            try{
              update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\VPN_tools.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.VPN_Toggle.Content -open -clear
            }catch{
              write-ezlogs "An exception occurred in VPN_Button_Button.add_Click" -CatchError $_ -enablelogs
            }
        })
        #---------------------------------------------- 
        #endregion VPN Help
        #----------------------------------------------
      }else{
        if($hashsetup.VPN_Grid){
          $hashsetup.VPN_Grid.Visibility = 'Collapsed'
        }
        if($hashsetup.VPN_StackPanel){
          $hashsetup.VPN_StackPanel.Visibility = 'Collapsed'
        }
        if($hashsetup.VPN_StackPanel){
          $hashsetup.VPN_StackPanel.Visibility = 'Collapsed'
        }
      }
      #---------------------------------------------- 
      #region Update_LocalMedia_Timer
      #----------------------------------------------
      $hashSetup.LocalMedia_items = [System.Collections.Generic.List[Object]]::new()
      $hashsetup.Update_LocalMedia_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $hashsetup.Update_LocalMedia_Timer_ScriptBlock = {
        try{
          write-ezlogs ">>>> Updating MediaLocations_Grid" -logtype Setup -LogLevel 2
          foreach($item in $this.tag | where {$hashsetup.MediaLocations_Grid.Items -notcontains $_}){
            write-ezlogs "| Adding $($item.path)" -logtype Setup -LogLevel 3
            [void]$hashsetup.MediaLocations_Grid.Items.add($item)
          }
          $hashsetup.total_localMedia = $Null
          if($synchash.All_local_Media){         
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: $($synchash.All_local_Media.count)"
          }else{
            $hashsetup.Local_Media_Total_Textbox.text = "Total Imported Media: TBD" 
          }
          #$hashsetup.Local_Media_Total_Textbox.text = "Total Media: $($total_media)"
          $hashsetup.Media_Path_Browse.isEnabled = $true
          if($hashsetup.Update){
            $hashsetup.Save_Setup_Button.isEnabled = $true
          }else{
            $hashsetup.Save_Setup_Button.isEnabled = $hashSetup.setupbutton_status
          }
          $hashsetup.MediaLocations_Grid.isEnabled = $true
          $hashsetup.Media_Path_Browse.IsEnabled = $true
          $hashsetup.Media_Progress_Ring.isActive = $false     
          if($hashsetup.Refresh_LocalMedia_Library -and $synchash.MediaTable -and $thisApp.Config.Import_Local_Media){
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $true
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false
            if($synchash.Refresh_LocalMedia_timer){
              $synchash.Refresh_LocalMedia_timer.tag = 'AddNewOnly'   
              $synchash.Refresh_LocalMedia_timer.start()
            }
          }    
          $this.stop()
        }catch{
          write-ezlogs "An exception occurred in Update_LocalMedia_Timer" -showtime -catcherror $_
          $this.stop()
        }finally{
          $hashsetup.Refresh_LocalMedia_Library = $Null
          $this.stop()
        }
      }
      $hashsetup.Update_LocalMedia_Timer.add_tick($hashsetup.Update_LocalMedia_Timer_ScriptBlock)
      #---------------------------------------------- 
      #endregion Update_LocalMedia_Timer
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Local_Media_Toggle
      #----------------------------------------------
      $hashsetup.Import_Local_Media_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.MediaLocations_Grid.IsEnabled = $sender.isOn
          $hashsetup.Media_Path_Browse.IsEnabled = $sender.isOn
          $thisapp.configTemp.Import_Local_Media = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Import_Local_Media_Toggle.add_Toggled" -CatchError $_
        }
      }
      $hashsetup.Import_Local_Media_Toggle.add_Toggled($hashsetup.Import_Local_Media_Toggle_Command)
      #---------------------------------------------- 
      #endregion Import_Local_Media_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Local_Media_Button
      #----------------------------------------------
      $hashsetup.Import_Local_Media_Button.add_click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\LocalMedia_Importing.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Import_Local_Media_Toggle.content  -clear 
          }catch{
            write-ezlogs "An exception occurred in Import_Local_Media_Button.add_click" -catcherror $_
          }      
      }) 
      #---------------------------------------------- 
      #endregion Import_Local_Media_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region LocalMedia_SkipDuplicates
      #---------------------------------------------- 
      $hashsetup.LocalMedia_SkipDuplicates_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.LocalMedia_SkipDuplicates = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in LocalMedia_SkipDuplicates_Toggle.add_Toggled" -catcherror $_
        }
      }
      $hashsetup.LocalMedia_SkipDuplicates_Toggle.add_Toggled($hashsetup.LocalMedia_SkipDuplicates_Toggle_Command)
      #---------------------------------------------- 
      #endregion LocalMedia_SkipDuplicates
      #----------------------------------------------
       
      #---------------------------------------------- 
      #region LocalMedia_SkipDuplicates Help
      #----------------------------------------------
      $hashsetup.LocalMedia_SkipDuplicates_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\LocalMedia_SkipDuplicates.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.LocalMedia_SkipDuplicates_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in LocalMedia_SkipDuplicates_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion LocalMedia_SkipDuplicates Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region LocalMedia_ImportMode
      #----------------------------------------------
      if($hashsetup.LocalMedia_ImportMode_ComboBox){
        try{
          [void]$hashsetup.LocalMedia_ImportMode_ComboBox.items.add('Fast')
          [void]$hashsetup.LocalMedia_ImportMode_ComboBox.items.add('Normal')
          [void]$hashsetup.LocalMedia_ImportMode_ComboBox.items.add('Slow')
          $hashsetup.LocalMedia_ImportMode_ComboBox.add_SelectionChanged({
              try{
                if($hashsetup.LocalMedia_ImportMode_ComboBox.SelectedIndex -ne -1){    
                  $hashsetup.LocalMedia_ImportMode_Textbox.BorderBrush = 'Green'
                  Add-Member -InputObject $thisapp.configTemp -Name 'LocalMedia_ImportMode' -Value $hashsetup.LocalMedia_ImportMode_ComboBox.SelectedItem -MemberType NoteProperty -Force
                }
                else{          
                  $hashsetup.LocalMedia_ImportMode_Textbox.BorderBrush = 'Green'
                  Add-Member -InputObject $thisapp.configTemp -Name 'LocalMedia_ImportMode' -Value $LocalMedia_ImportMode_Default -MemberType NoteProperty -Force      
                }
              }catch{
                write-ezlogs "An exception occurred in LocalMedia_ImportMode event" -CatchError $_ -showtime
              }
          }) 
        }catch{
          write-ezlogs 'An exception occurred processing LocalMedia_ImportMode_ComboBox' -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion LocalMedia_ImportMode
      #----------------------------------------------

      #---------------------------------------------- 
      #region LocalMedia_ImportMode Help
      #----------------------------------------------
      $hashsetup.LocalMedia_ImportMode_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\LocalMedia_ImportMode.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.LocalMedia_ImportMode_Textbox.Text -open -clear
          }catch{
            write-ezlogs "An exception occurred inLocalMedia_ImportMode_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion LocalMedia_ImportMode Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_LocalMedia_Monitor
      #---------------------------------------------- 
      $hashsetup.Enable_LocalMedia_Monitor_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Enable_LocalMedia_Monitor = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_LocalMedia_Monitor_Toggle.add_Toggled" -catcherror $_
        }
      }
      $hashsetup.Enable_LocalMedia_Monitor_Toggle.add_Toggled($hashsetup.Enable_LocalMedia_Monitor_Toggle_Command)
      if($hashsetup.LocalMedia_MonitorMode_ComboBox){
        try{
          [void]$hashsetup.LocalMedia_MonitorMode_ComboBox.items.add('All')
          [void]$hashsetup.LocalMedia_MonitorMode_ComboBox.items.add('New Media')
          [void]$hashsetup.LocalMedia_MonitorMode_ComboBox.items.add('Changed Media')
          [void]$hashsetup.LocalMedia_MonitorMode_ComboBox.items.add('Removed Media')
          $hashsetup.LocalMedia_MonitorMode_ComboBox.add_SelectionChanged({
              try{
                if($hashsetup.LocalMedia_MonitorMode_ComboBox.SelectedIndex -ne -1){    
                  $hashsetup.LocalMedia_MonitorMode_Textbox.BorderBrush = 'Green'
                  Add-Member -InputObject $thisapp.configTemp -Name 'LocalMedia_MonitorMode' -Value $hashsetup.LocalMedia_MonitorMode_ComboBox.SelectedItem -MemberType NoteProperty -Force
                }
                else{          
                  $hashsetup.LocalMedia_MonitorMode_Textbox.BorderBrush = 'Green'
                  Add-Member -InputObject $thisapp.configTemp -Name 'LocalMedia_MonitorMode' -Value $LocalMedia_MonitorMode_Default -MemberType NoteProperty -Force      
                }
              }catch{
                write-ezlogs "An exception occurred in LocalMedia_MonitorMode event" -CatchError $_ -showtime
              }
          }) 
        }catch{
          write-ezlogs 'An exception occurred processing LocalMedia_MonitorMode options' -showtime -catcherror $_
        }
      }     
      #---------------------------------------------- 
      #endregion Enable_LocalMedia_Monitor
      #----------------------------------------------
       
      #---------------------------------------------- 
      #region Enable_LocalMedia_Monitor Help
      #----------------------------------------------
      $hashsetup.Enable_LocalMedia_Monitor_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_LocalMedia_Monitor.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Enable_LocalMedia_Monitor_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Enable_LocalMedia_Monitor_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Enable_LocalMedia_Monitor Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region LocalMedia_Display_Syntax_textbox
      #----------------------------------------------
      $hashsetup.LocalMedia_Display_Syntax_textbox.add_textChanged({
          try{
            if(-not [string]::IsNullOrEmpty($hashsetup.LocalMedia_Display_Syntax_textbox.text)){   
              $hashsetup.LocalMedia_Display_Syntax_Label.BorderBrush = 'LightGreen' 
            }
            else{       
              $hashsetup.LocalMedia_Display_Syntax_Label.BorderBrush = 'Red'   
            }
          }catch{
            write-ezlogs "An exception occurred in LocalMedia_Display_Syntax_textbox.add_textChanged" -CatchError $_ -enablelogs
          }
      }) 

      #---------------------------------------------- 
      #endregion LocalMedia_Display_Syntax_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region LocalMedia_Display_Syntax_HelpButton Help
      #----------------------------------------------
      $hashsetup.LocalMedia_Display_Syntax_HelpButton.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\LocalMedia_Display_Syntax.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.LocalMedia_Display_Syntax_Label.text -clear
          }catch{
            write-ezlogs "An exception occurred in LocalMedia_Display_Syntax_HelpButton.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion LocalMedia_Display_Syntax_HelpButton Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Media_Path_Browse
      #---------------------------------------------- 
      $hashsetup.Media_Path_Browse.add_click({
          try{
            if(($hashsetup.MediaLocations_Grid.items.path | select -last 1)){
              $initialdirectory = ($hashsetup.MediaLocations_Grid.items.path | select -last 1)
            }else{
              $initialdirectory = "file:"
            }     
            $hashsetup.Media_Path_Browse.IsEnabled = $false
            $hashsetup.Media_Progress_Ring.isActive = $true
            $hashsetup.MediaLocations_Grid.IsEnabled = $false
            [array]$file_browse_Path = Open-FolderDialog -Title "Select the folder from which media will be imported" -InitialDirectory $initialdirectory -MultiSelect
            if(-not [string]::IsNullOrEmpty($file_browse_Path)){
              Update-MediaLocations -hashsetup $hashsetup -VerboseLog -thisapp $thisApp -synchash $synchash -Directories $file_browse_Path -SetItemssource -UpdateLibrary
            }elseif($hashsetup.Import_Local_Media_Toggle.isEnabled){
              $hashsetup.Media_Path_Browse.IsEnabled = $true
              $hashsetup.MediaLocations_Grid.IsEnabled = $true
            } 
            $hashsetup.Media_Progress_Ring.isActive = $false      
          }catch{
            write-ezlogs "An exception occurred in Media_Path_Browse.add_click" -CatchError $_ -enablelogs
          }
      })     
      #---------------------------------------------- 
      #endregion Media_Path_Browse
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spicetify_Toggle
      #----------------------------------------------
      $hashsetup.Spicetify_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Spicetify_textblock.text = ''
          $hashsetup.Spicetify_transitioningControl.content = ''     
          if($hashsetup.Spicetify_Toggle.isOn){
            $hashsetup.Spicetify_textblock.text = "IMPORTANT! You must click 'Apply to Spotify' to complete Spicetify setup and customizations"
            $hashsetup.Spicetify_Remove_Button.IsEnabled = $false
            $hashsetup.Spicetify_Status = $false
            $hashsetup.Spotify_WebPlayer_Toggle.isOn = $false             
          }else{
            $hashsetup.Spicetify_textblock.text = "IMPORTANT! You must click 'Remove from Spotify' to complete the removal of Spicetify customizations if previously enabled"
            $hashsetup.Spicetify_Remove_Button.IsEnabled = $true
            $hashsetup.Spotify_WebPlayer_Toggle.isOn = $true
          }        
          $hashsetup.Spicetify_textblock.foreground = 'Orange'
          $hashsetup.Spicetify_textblock.FontSize = 14
          $hashsetup.Spicetify_transitioningControl.content = $hashsetup.Spicetify_textblock      
        }catch{
          write-ezlogs "An exception occurred in Spicetify_Toggle.Add_Toggled" -CatchError $_ -enablelogs
        } 
      }
      $hashsetup.Spicetify_Toggle.add_Toggled($hashsetup.Spicetify_Toggle_Command)
      #---------------------------------------------- 
      #endregion Spicetify_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spicetify_Button
      #----------------------------------------------
      $hashsetup.Spicetify_Button.Add_Click({ 
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Spotify_Use_Spicetify.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Spicetify_Toggle.content -clear
            #update-EditorHelp -content "Enabling this will use Spicetify to customize the Spotify client to allow direct control of playback and status" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold 
            #update-EditorHelp -content "Why Spicetify?" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -TextDecorations Underline
            #update-EditorHelp -content "Using Spicetify allows more consistent, responsive and reliable control integration of the Spotify client. Without Spicetify, control of the Spotify client is handled using Spotify Web API calls, since Spotify no longer supports direct control of the Windows app (programmically). While this works, it can be less reliable, as a web API call is needed anytime a command needs to be sent or when getting status. This can result in a delay between issuing a command and Spotify responding or sometimes it can fail alltogether." -RichTextBoxControl $hashsetup.EditorHelpFlyout 
            #update-EditorHelp -content "IMPORTANT" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -TextDecorations Underline
            #update-EditorHelp -content "Spicetify makes direct modifications to the Spotify client, injecting custom code. Highly recommend visiting https://spicetify.app/ to read more about what Spicetify does. If you are not comfortable with these modifications, leave this option disabled. `nIf you wish to revert these changes, click the 'Remove From Spotify' button" -RichTextBoxControl $hashsetup.EditorHelpFlyout -color orange
            #update-EditorHelp -content "Updates to the Spotify client may break the customizations made by Spicetify. If this happens, $($thisApp.Config.App_Name) will attempt to warn you and revert to using the Spotify API (with Web Player). If that happens, you can re-enable this option to reapply the customizations using the 'Apply to Spotify' button" -RichTextBoxControl $hashsetup.EditorHelpFlyout -color orange
            #update-EditorHelp -content "MORE INFO" -RichTextBoxControl $hashsetup.EditorHelpFlyout -color cyan -FontWeight bold -TextDecorations Underline
            #update-EditorHelp -content "Spicetify is used to inject a customized version of the Webnowplaying extension which originally was designed to allow Spotify to work with Rainmeter. $($thisApp.Config.App_Name) uses the PowerShell module PODE to create a local Websocket server (127.0.0.1) on port 8974. The customized Webnowplaying connects to this Websocket to relay Spotify playback data and accept commands from $($thisApp.Config.App_Name), such as Play/Pause, next, previous, repeat, loop...etc. This allows controlling Spotify without sending commands over the web, which is more reliable and faster." -RichTextBoxControl $hashsetup.EditorHelpFlyout -color cyan
          }catch{
            write-ezlogs "An exception occurred in Spicetify_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Spicetify_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spicetify_Apply_Button
      #----------------------------------------------
      $hashsetup.Spicetify_Apply_Button.Add_Click({ 
          try{
            $hashsetup.Spicetify_Status = $false
            if($synchash){
              $synchash.Spicetify_apply_status = $Null
              $synchash.Spotify_install_status = $Null
            }
            if([System.IO.File]::Exists("$($env:USERPROFILE)\spicetify-cli\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\.spicetify\config-xpui.ini")){
              $Spicetify_Install_Dir = "$($env:USERPROFILE)\spicetify-cli\"
              $Spicetify_Config_Dir = "$($env:USERPROFILE)\.spicetify"
              $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
              if(!$appinstalled){
                $appinstalled = "$($env:USERPROFILE)\spicetify-cli\spicetify.exe"
              }
            }elseif([System.IO.File]::Exists("$($env:LOCALAPPDATA)\spicetify\spicetify.exe") -and [System.IO.File]::Exists("$($env:APPDATA)\spicetify\config-xpui.ini")){    
              $Spicetify_Install_Dir = "$($env:LOCALAPPDATA)\spicetify"
              $Spicetify_Config_Dir = "$($env:APPDATA)\spicetify"  
              $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
              if(!$appinstalled){
                $appinstalled = "$($env:LOCALAPPDATA)\spicetify\spicetify.exe"
              }    
            }else{
              write-ezlogs "Spicetify does not appear to be installed!" -showtime -warning -logtype Setup
            }
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Apply Spicetify?","Are you sure you wish to apply Spicetify customizations to Spotify?`nA backup of Spotify's state is made so you can always restore/remove customizations later",$okandCancel,$Button_Settings)
            if($result -eq 'Affirmative'){
              if($synchash.Window.isVisible){
                $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.hide() })
                $hashsetup.MainWindow_Status = $true
              }
              $hashsetup.window.hide()
              if($first_run){
                Update-SplashScreen -hash $hash -SplashMessage 'Applying Spicetify customizations...' -Splash_More_Info 'Please Wait' -Show
              }else{
                Start-SplashScreen -SplashTitle "$($thisapp.Config.App_Name) Media Player" -SplashMessage 'Applying Spicetify customizations...' -Splash_More_Info 'Please Wait' -current_folder $thisapp.Config.Current_Folder -log_file $thisApp.Config.Log_file
              }                 
              $Spicetify = Enable-Spicetify -thisApp $thisApp -synchash $synchash
              write-ezlogs ">>>> Enable Spicetify Results: $($Spicetify)" -logtype Setup
              if($Spicetify.Spicetify_apply_status){
                $hashsetup.Spicetify_Toggle.ison = $false
                Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
                update-EditorHelp -content "An error was encountered when applying Spicetfiy! Spicetify will be disabled. Please refer to the logs! You can attempt to download and install an older version of Spotify as a potential workaround`n`n$($Spicetify.Spicetify_apply_status | out-string)" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -Header 'Spicetify ERROR' -Open -clear
                $hashsetup.Spicetify_Status = $true
              }elseif($Spicetify.Spotify_install_status -eq 'NotInstalled'){
                $hashsetup.Spicetify_Toggle.ison = $false
                Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
                update-EditorHelp -content "Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!`n`nNOTE: You can have this app auto install Spotify using the 'Install Spotify' options above" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -Header 'Spicetify ERROR' -Open -clear       
                $hashsetup.Spicetify_Status = $true      
              }elseif($Spicetify.Spotify_install_status -eq 'StoreVersion'){
                $hashsetup.Spicetify_Toggle.ison = $false
                Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
                update-EditorHelp -content "You are using the Windows Store version of Spotify, which is not supported with Spicetify.`nYou must first remove the Windows Store version and install the normal version!" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -Header 'Spicetify ERROR' -Open -clear    
                $hashsetup.Spicetify_Status = $true        
              }elseif(!$Spicetify){
                $hashsetup.Spicetify_Toggle.ison = $false
                Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
                update-EditorHelp -content "Unable to verify Spicetify is installed successfully, cannot continue! Check logs for more detail" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange -Header 'Spicetify ERROR' -Open -clear    
                $hashsetup.Spicetify_Status = $true            
              }else{
                Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $true -MemberType NoteProperty -Force  
                write-ezlogs 'Successfully applied Spicetify customizations to Spotify! The Spotify app may have opened' -Success -logtype Setup
                $hashsetup.Spicetify_Toggle.ison = $true       
                if((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){
                  write-ezlogs ">>>> Closing existing PODE Server Runspace for Spicetify" -showtime -logtype Setup -loglevel 2
                  Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue
                }
                $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
                write-ezlogs ">>>> Starting new PODE Server Runspace for Spicetify" -showtime -logtype Setup -loglevel 2
                Start-Runspace -scriptblock $synchash.pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'PODE_SERVER_RUNSPACE' -thisApp $thisApp -synchash $synchash
                $Variable_list = $Null  
                $hashsetup.Spicetify_Status = $true
                $hashsetup.Spicetify_textblock.text = '[SUCCESS] Successfully applied Spicetify customizations to Spotify! The Spotify app may have opened. Make sure you are logged in with your Spotify account'
                $hashsetup.Spicetify_textblock.foreground = 'LightGreen'
                $hashsetup.Spicetify_textblock.FontSize = 14
                $hashsetup.Spicetify_transitioningControl.content = $hashsetup.Spicetify_textblock 
              }
            }else{
              write-ezlogs "User choose not to Apply Spicetify" -showtime -warning -logtype Setup
            }
          }catch{
            write-ezlogs "An exception occurred in Spicetify_Apply_Button click event" -showtime -catcherror $_
          }finally{    
            if($first_Run){
              Update-SplashScreen -hash $hash -hide
            }else{
              Update-SplashScreen -hash $hash -Close
            }          
            $hashsetup.Window.show()
            if($hashsetup.MainWindow_Status){
              write-ezlogs "Unhiding Main App Window" -logtype Setup -loglevel 2
              $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.show() })
              $hashsetup.MainWindow_Status = $false
            }
          }
      })
      #---------------------------------------------- 
      #endregion Spicetify_Apply_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spicetify_Remove_Button
      #----------------------------------------------
      $hashsetup.Spicetify_Remove_Button.Add_Click({ 
          try{
            if($synchash){
              $synchash.Spicetify_apply_status = $Null
            }
            if([System.IO.File]::Exists("$($env:USERPROFILE)\spicetify-cli\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\.spicetify\config-xpui.ini")){
              $Spicetify_Install_Dir = "$($env:USERPROFILE)\spicetify-cli\"
              $Spicetify_Config_Dir = "$($env:USERPROFILE)\.spicetify"
              $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
              if(!$appinstalled){
                $appinstalled = "$($env:USERPROFILE)\spicetify-cli\spicetify.exe"
              }
              write-ezlogs ">>>> Spicetify is installed:`n$appinstalled" -showtime -logtype Setup -loglevel 2
            }elseif([System.IO.File]::Exists("$($env:LOCALAPPDATA)\spicetify\spicetify.exe") -and [System.IO.File]::Exists("$($env:APPDATA)\spicetify\config-xpui.ini")){    
              $Spicetify_Install_Dir = "$($env:LOCALAPPDATA)\spicetify"
              $Spicetify_Config_Dir = "$($env:APPDATA)\spicetify"  
              $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
              if(!$appinstalled){
                $appinstalled = "$($env:LOCALAPPDATA)\spicetify\spicetify.exe"
              } 
              write-ezlogs ">>>> Spicetify is installed:`n$appinstalled" -showtime -logtype Setup -loglevel 2   
            }else{
              write-ezlogs "Spicetify does not appear to be installed!" -showtime -warning -logtype Setup
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              }
              $hashsetup.Editor_Help_Flyout.Header = 'Spicetify'
              update-EditorHelp -content "Spicetify does not appear to be installed! Unable to continue" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange
              return
            }
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Remove Spicetify?","Are you sure you wish to remove Spicetify customizations from Spotify?`nThis will restore the Spotify app to the state it was in before Spicetify was added",$okandCancel,$Button_Settings)
            if($result -eq 'Affirmative'){
              if($synchash.Window.isVisible){
                $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.hide() })
                $hashsetup.MainWindow_Status = $true
              }
              $hashsetup.window.hide()
              $hashsetup.Spicetify_Toggle.ison = $false
              Add-Member -InputObject $thisapp.configTemp -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
              Start-SplashScreen -SplashTitle "$($thisapp.Config.App_Name) Media Player" -SplashMessage 'Removing Spicetify customizations...' -Splash_More_Info 'Please Wait' -current_folder $thisapp.Config.Current_Folder -log_file $thisApp.Config.Log_file
              Disable-Spicetify -thisApp $thisApp -synchash $synchash
              if((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}       
              $hashsetup.Spicetify_textblock.text = '[SUCCESS] Successfully removed Spicetify customizations to Spotify! If the Spotify launched, you can safely close it' 
              $hashsetup.Spicetify_textblock.foreground = 'LightGreen'
              $hashsetup.Spicetify_textblock.FontSize = 14
              $hashsetup.Spicetify_transitioningControl.content = $hashsetup.Spicetify_textblock
            }else{
              write-ezlogs "User choose not to Remove Spicetify" -showtime -warning -logtype Setup
            } 
            #}
          }catch{
            write-ezlogs "An exception occurred in Spicetify_Remove_Button click event" -showtime -catcherror $_
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }
            $hashsetup.Editor_Help_Flyout.Header = 'Spicetify'
            update-EditorHelp -content "An exception occurred when attempting to remove Spicetify customizations from Spotify!`n`n$($_ | out-string)" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold -color orange
          }finally{            
            if($hash.Window.isVisible){
              Update-SplashScreen -hash $hash -Close
            }
            if(!$hashsetup.Window.isVisible){
              $hashsetup.Window.show()
            }      
            if($hashsetup.MainWindow_Status){
              $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.show() })
              $hashsetup.MainWindow_Status = $false
            }
          }
      })
      #---------------------------------------------- 
      #endregion Spicetify_Remove_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify WebPlayer Toggle
      #----------------------------------------------
      $hashsetup.Spotify_WebPlayer_Toggle_Command = {
        Param($sender)
        try{
          if($sender.isOn -eq $true){    
            write-ezlogs ">>>> Enabling Spotify Webplayer" -logtype Setup -LogLevel 3
            $thisapp.configTemp.Spotify_WebPlayer = $true
            if($hashsetup.Spicetify_Toggle){
              $hashsetup.Spicetify_Toggle.isOn = $false
            }
          }
          else{            
            write-ezlogs ">>>> Disabling Spotify Webplayer" -logtype Setup -LogLevel 3   
            $thisapp.configTemp.Spotify_WebPlayer = $false
            if($hashsetup.Spicetify_Toggle){
              $hashsetup.Spicetify_Toggle.isOn = $true
            }             
          }     
        }catch{
          write-ezlogs "An exception occurred in Spotify_WebPlayer_Toggle event" -showtime -catcherror $_
        } 
      }
      $hashsetup.Spotify_WebPlayer_Toggle.add_Toggled($hashsetup.Spotify_WebPlayer_Toggle_Command)
      #---------------------------------------------- 
      #endregion Spotify WebPlayer Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify WebPlayer Help
      #----------------------------------------------
      $hashsetup.Spotify_WebPlayer_Help_Button.add_Click({
          try{ 
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Spotify_WebPlayer.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Spotify_WebPlayer_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred in Spotify_WebPlayer_Help_Button.add_Click" -CatchError $_ -enablelogs
          }  
      })
      #---------------------------------------------- 
      #endregion Spotify WebPlayer Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify AuthHandler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Spotify_AuthHandler = {
        param ($sender,$e)
        if($sender.NavigateUri -match 'Spotify_Auth'){
          try{
            $Spotify_AuthHandler_Measure = [system.diagnostics.stopwatch]::StartNew()
            $hashsetup.Spotify_Progress_Ring.isActive = $true
            $hashsetup.SpotifyMedia_Importing_Settings_Expander.isEnabled = $false
            if($hashsetup.Update_SpotifyStatus_Timer.IsEnabled){
              write-ezlogs "Stopping Update_SpotifyStatus_Timer" -logtype Setup -LogLevel 2
              $hashsetup.Update_SpotifyStatus_Timer.stop()
            }
            $Spotify_AuthHandler_Scriptblock = {              
              try{             
                <#                if([System.IO.Directory]::Exists("$($thisApp.Config.Temp_Folder)\Setup_Webview2")){   
                    try{
                    write-ezlogs ">>>> Removing existing Webview2 cache $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -color cyan -logtype Setup -LogLevel 2
                    [void][System.IO.Directory]::Delete("\\?\$($thisApp.Config.Temp_Folder)\Setup_Webview2",$true)
                    }catch{
                    write-ezlogs "An exception occurred attempting to remove $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -catcherror $_
                    }
                }#>
                try{
                  $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
                }catch{
                  write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
                }
                if($secretstore){
                  write-ezlogs ">>>> Removing stored Spotify authentication secrets from vault: $($secretstore.name)" -showtime -warning -logtype Setup
                  foreach($secret in $hashsetup.valid_secrets | where {$_ -match 'Spoty'}){  
                    $secret_info = Get-SecretInfo -Filter $secret -VaultName $thisApp.config.App_Name -ErrorAction SilentlyContinue       
                    if($secret_info.Name -eq $secret){
                      try{                  
                        write-ezlogs " | Removing Secret $($secret_info.Name)" -showtime -warning -logtype Setup
                        Remove-secret -Name $($secret_info.Name) -Vault $thisApp.config.App_Name
                      }catch{
                        write-ezlogs "An exception occurred removing Secret $($secret) from vault $($thisApp.config.App_Name)" -catcherror $_
                      }
                    }
                  }
                }
                $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name   
                if(!$hashsetup.Spotify_Auth_app.token.access_token){
                  write-ezlogs ">>>> Starting spotify authentication setup process" -showtime -logtype Setup -LogLevel 2
                  $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\Spotify-API-Config.xml"
                  write-ezlogs " | Importing API XML $APIXML" -showtime -logtype Setup -LogLevel 2
                  if([System.IO.File]::Exists($APIXML)){
                    $Spotify_API = Import-Clixml $APIXML
                    $client_ID = $Spotify_API.ClientID
                    $client_secret = $Spotify_API.ClientSecret
                  }
                  if($Spotify_API -and $client_ID -and $client_secret){
                    write-ezlogs ">>>> Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime -logtype Setup -LogLevel 2            
                    New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
                    write-ezlogs ">>>> Getting Spotify Application" -showtime -logtype Setup -LogLevel 2
                    $hashsetup.Spotify_Auth_app = $null
                    $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
                    #write-ezlogs ">>>> Starting Update_SpotifyStatus_Timer" -showtime -logtype Setup -LogLevel 2
                    $hashsetup.Update_SpotifyStatus_Timer.tag = 'NewAuth'
                    $hashsetup.Update_SpotifyStatus_Timer.start() 
                    return
                  }else{
                    write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning -logtype Setup
                    #$hashsetup.Spotify_Playlists_Import.isEnabled = $false
                    $hashsetup.Spotify_Auth_Status = $false         
                    update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API, no API credentials were found. Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -clear -Open -Header 'Spotify - Warning' 
                    $hashsetup.Update_SpotifyStatus_Timer.tag = $Null
                    $hashsetup.Update_SpotifyStatus_Timer.start()  
                    Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Control 'Import_Spotify_Playlists_Toggle' -Property 'IsOn' -value $false
                    return
                  }
                }
                $hashsetup.Update_SpotifyStatus_Timer.tag = 'NewAuth'
                $hashsetup.Update_SpotifyStatus_Timer.start()
                return                    
              }catch{
                write-ezlogs "An exception occurred executing Get-SpotifyApplication in Import_Spotify_Playlists_Toggle.add_Toggled" -catcherror $_
              }                          
            }
            $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
            Start-Runspace -scriptblock $Spotify_AuthHandler_Scriptblock -Variable_list $Variable_list -runspace_name 'Spotify_AuthHandler_RUNSPACE' -thisApp $thisApp -synchash $synchash  
            $Variable_list = $Null
            $Spotify_AuthHandler_Scriptblock = $Null
            $Spotify_AuthHandler_Measure.stop()
            write-ezlogs ">>>> Spotify_AuthHandler_Measure: $($Spotify_AuthHandler_Measure.elapsed | out-string)" -logtype Setup
            $Spotify_AuthHandler_Measure = $Null
          }catch{
            write-ezlogs "An exception occurred in Spotify_AuthHandler routed event" -showtime -catcherror $_
          }         
        }     
      }
      #---------------------------------------------- 
      #endregion Spotify AuthHandler
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify ImportHandler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$Spotify_ImportHandler = {
        param ($sender,$e)
        try{
          $Spotify_ImportHandler_Measure = [system.diagnostics.stopwatch]::StartNew()
          try{
            $Spotify_playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -First_Run:$First_Run 
          }catch{
            write-ezlogs "An exception occurred retrievingSpotify playlists with Get-CurrentUserPlaylists" -showtime -catcherror $_
          } 
          $newplaylists = 0
          if($Spotify_playlists){        
            foreach($playlist in $Spotify_playlists){              
              $playlisturl = $playlist.uri
              $playlistName = $playlist.name
              if($hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $playlisturl){
                write-ezlogs "Adding Spotify Playlist URL $playlisturl" -showtime -logtype Setup -LogLevel 3
                Update-SpotifyPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'SpotifyPlaylist' -Playlist_Info $playlist -VerboseLog:$thisApp.Config.Verbose_logging
                $newplaylists++
              }else{
                write-ezlogs "The Spotify Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
              }
            }
          }
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          if($newplaylists -le 0){
            write-ezlogs "No new Spotify Playlists were found!" -showtime -warning -logtype Setup
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Spotify'
            update-EditorHelp -content "No new Spotify Playlists were found!" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
          }else{
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Spotify'
            write-ezlogs ">>>> Found $newplaylists new Spotify Playlists!" -showtime -logtype Setup -LogLevel 2
            update-EditorHelp -content "Found $newplaylists new Spotify Playlists!" -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
          } 
          $Spotify_ImportHandler_Measure.stop()
          write-ezlogs ">>>> Spotify_ImportHandler_Measure: $($Spotify_ImportHandler_Measure.elapsed | out-string)" -logtype Setup  
          $Spotify_ImportHandler_Measure = $Null           
        }catch{
          write-ezlogs "An exception occurred in Spotify_ImportHandler routed event" -showtime -catcherror $_
        }             
      }
      [void]$hashsetup.Spotify_Playlists_Import.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_ImportHandler) 
      #---------------------------------------------- 
      #endregion Spotify ImportHandler
      #----------------------------------------------

      #---------------------------------------------- 
      #region Update_SpotifyStatus_Timer
      #----------------------------------------------
      $hashsetup.Update_SpotifyStatus_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $hashsetup.Update_SpotifyStatus_Timer_ScriptBlock = {
        try{
          $hashsetup.Spotify_Progress_Ring.isActive = $false
          $hashsetup.SpotifyMedia_Importing_Settings_Expander.isEnabled = $true
          write-ezlogs ">>>> Updating Spotify Authentication Status: $($hashsetup.Spotify_Auth_app | out-string)" -logtype Setup -LogLevel 2 -Dev_mode
          if($this.tag -eq 'NewAuth'){           
            if($hashsetup.Spotify_Auth_app){
              try{
                write-ezlogs ">>>> Getting current Spotify User Playlists" -logtype Setup -LogLevel 2
                $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -First_Run:$First_Run        
              }catch{
                write-ezlogs "[Show-SettingsWindow] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_
              }                             
              if($playlists){
                foreach($playlist in $playlists){              
                  $playlisturl = $playlist.uri
                  $playlistName = $playlist.name
                  if($hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $playlisturl){
                    if($thisApp.Config.Verbose_logging){write-ezlogs "Adding Spotify Playlist URL $playlisturl" -showtime}
                    Update-SpotifyPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'SpotifyPlaylist' -Playlist_Info $playlist -VerboseLog:$thisApp.Config.Verbose_logging
                  }else{
                    write-ezlogs "The Spotify Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
                  }
                }
                Add-Member -InputObject $thisapp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                write-ezlogs "Authenticated to Spotify and retrieved Playlists" -showtime -color green -logtype Setup -LogLevel 2 -Success
                $hashsetup.Import_Spotify_textbox.isEnabled = $true
                $hashsetup.Spotify_Playlists_Import.isEnabled = $true
                $hashsetup.Spotify_Auth_Status = $true
                $hashsetup.Import_Spotify_textbox.text = ''
                $hashsetup.Import_Spotify_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Spotify_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Spotify_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Spotify_textbox.isEnabled = $true
                $hyperlink = 'https://Spotify_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $link_hyperlink.FontWeight = "Bold"
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add("If you wish to update or change your Spotify credentials, click ")  
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
                $hashsetup.Import_Spotify_textbox.FontSize = '14'
                $hashsetup.Import_Spotify_transitioningControl.Height = '60'
                $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
                $hashsetup.Install_Spotify_Toggle.isEnabled = $true
                if($MahDialog_hash.window.Dispatcher){
                  write-ezlogs ">>>> Closing Weblogin Window: isVisible: $($MahDialog_hash.window.isVisible) - Visibility: $($MahDialog_hash.window.Visibility)" -logtype Setup -LogLevel 2
                  $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                }  
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[SUCCESS] Authenticated to Spotify and retrieved Playlists!.`n`nSpotify Playlists have been imported automatically. If you do not see them or wish to refresh the list, click 'Import from Spotify'" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout     
                update-EditorHelp -content "INFO" -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
                update-EditorHelp -content "If you disable the 'Use Web Player' option for Spotify, please ensure that you have the Windows Spotify client installed and are logged in with your account" -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout  \                
                $this.tag = $null 
                $this.stop()                    
              }else{
                write-ezlogs "[Show-SettingsWindow] Unable to successfully authenticate to spotify!" -showtime -warning -logtype Setup
                Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                $hyperlink = 'https://Spotify_Auth'
                #$uri = new-object system.uri($hyperlink)
                $hashsetup.Import_Spotify_textbox.isEnabled = $true
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                $link_hyperlink.FontWeight = "Bold"
                $hashsetup.Import_Spotify_Status_textbox.Text="[NONE]"
                $hashsetup.Import_Spotify_Status_textbox.Foreground = "Orange"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $hashsetup.Import_Spotify_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add(" to provide your Spotify account credentials.")  
                $hashsetup.Import_Spotify_textbox.Foreground = "Orange"
                $hashsetup.Import_Spotify_textbox.FontSize = '14'
                $hashsetup.Import_Spotify_transitioningControl.Height = '60'
                $hashsetup.Spotify_Auth_Status = $false
                $hashsetup.Spotify_Playlists_Import.isEnabled = $false
                $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! (No playlists returned!) Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout     
                Remove-SpotifyApplication -Name $thisApp.config.App_Name               
              }
              $this.tag = $null 
              $this.stop() 
              if(!$hashsetup.Window.isVisible){
                write-ezlogs "Show/unhiding First Run Setup window" -logtype Setup
                $hashsetup.Window.Show()
              }                            
            }else{
              write-ezlogs "No Spotify app returned from Get-SpotifyApplication! Cannot continue" -showtime -warning -logtype Setup
            }
          }else{
            if([string]::IsNullOrEmpty($hashsetup.Spotify_Auth_app.token.access_token)){
              write-ezlogs "No valid Spotify Authentication found" -showtime -logtype Setup -warning
              $hyperlink = 'https://Spotify_Auth'
              #$uri = new-object system.uri($hyperlink)
              $hashsetup.Import_Spotify_textbox.isEnabled = $true
              $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              $link_hyperlink.FontWeight = "Bold"
              $hashsetup.Import_Spotify_Status_textbox.Text="[NONE]"
              $hashsetup.Import_Spotify_Status_textbox.Foreground = "Orange"
              [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
              $hashsetup.Import_Spotify_textbox.Inlines.add("Click ")
              [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
              [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
              [void]$hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
              [void]$hashsetup.Import_Spotify_textbox.Inlines.add(" to provide your Spotify account credentials.")  
              $hashsetup.Import_Spotify_textbox.Foreground = "Orange"
              $hashsetup.Import_Spotify_textbox.FontSize = 14
              $hashsetup.Spotify_Playlists_Import.isEnabled = $false
              $hashsetup.Import_Spotify_transitioningControl.Height = '60'
            }else{
              write-ezlogs "[Show-SettingsWindow:Update_Timer] Returned Spotify application" -showtime -logtype Setup -Success -Dev_mode  #$($hashsetup.Spotify_Auth_app)
              $hashsetup.Import_Spotify_textbox.text = ''
              $hashsetup.Import_Spotify_Status_textbox.Text="[VALID]"
              $hashsetup.Import_Spotify_Status_textbox.Foreground = "LightGreen"
              $hashsetup.Import_Spotify_textbox.isEnabled = $true
              $hashsetup.Spotify_Playlists_Import.isEnabled = $true
              $hashsetup.Spotify_Auth_Status = $true
              $hyperlink = 'https://Spotify_Auth'
              $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
              $link_hyperlink.FontWeight = "Bold"
              [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
              [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
              [void]$hashsetup.Import_Spotify_textbox.Inlines.add("If you wish to update/change your Spotify credentials, click ")  
              [void]$hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
              $hashsetup.Import_Spotify_textbox.Foreground = "LightGreen"
              $hashsetup.Import_Spotify_textbox.FontSize = '14'
              $hashsetup.Import_Spotify_transitioningControl.Height = '60'
            }
          } 
          $hashsetup.Update_SpotifyStatus_Timer.tag = $Null
          $hashsetup.Update_SpotifyStatus_Timer.stop()         
        }catch{
          write-ezlogs "An exception occurred in Update_SpotifyStatus_Timer" -catcherror $_
        }finally{
          $this.tag = $null
          $hashsetup.Update_SpotifyStatus_Timer.stop() 
        }
      }
      $hashsetup.Update_SpotifyStatus_Timer.add_Tick($hashsetup.Update_SpotifyStatus_Timer_ScriptBlock)
      #---------------------------------------------- 
      #endregion Update_SpotifyStatus_Timer
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Spotify_Playlists_Toggle
      #----------------------------------------------
      $hashsetup.Import_Spotify_Playlists_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Import_Spotify_textbox.text = ''
          if($thisApp.Config.Startup_perf_timer){
            $Import_Spotify_Playlists_Toggle_Measure = [system.diagnostics.stopwatch]::StartNew()
          }         
          if($sender.isOn){     
            $hashsetup.Spotify_Progress_Ring.isActive = $true
            $hashsetup.SpotifyMedia_Importing_Settings_Expander.isEnabled = $false
            $hashsetup.Install_Spotify_Toggle.isEnabled = $true
            $Spotify_AUth_Check_Scriptblock = {              
              try{             
                $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name                  
              }catch{
                write-ezlogs "An exception occurred executing Get-SpotifyApplication in Import_Spotify_Playlists_Toggle.add_Toggled" -catcherror $_
              }finally{
                $hashsetup.Update_SpotifyStatus_Timer.start()
              }                          
            }
            $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
            Start-Runspace -scriptblock $Spotify_AUth_Check_Scriptblock -Variable_list $Variable_list -runspace_name 'Spotify_AUth_Check__RUNSPACE' -thisApp $thisApp -synchash $synchash       
            $Variable_list = $Null        
          }else{
            $hashsetup.Install_Spotify_Toggle.isEnabled = $false
            $hashsetup.Spotify_Playlists_Import.isEnabled = $false
            write-ezlogs ">>>> Disabling Import Spotify Media" -showtime -logtype Setup -LogLevel 2
            $thisapp.configTemp.Install_Spotify = $false
            $thisapp.configTemp.Import_Spotify_Media = $false
            $hashsetup.Import_Spotify_textbox.text = ""
            $hashsetup.Import_Spotify_transitioningControl.Height = '0'
            #$hashsetup.Import_Spotify_transitioningControl.content = ''
          }           
          if($Import_Spotify_Playlists_Toggle_Measure){
            $Import_Spotify_Playlists_Toggle_Measure.stop()
            write-ezlogs "[Import_Spotify_Playlists_Toggle] >>>> Import_Spotify_Playlists_Toggle_Measure" -showtime -logtype Setup -LogLevel 2 -PerfTimer $Import_Spotify_Playlists_Toggle_Measure
            $Import_Spotify_Playlists_Toggle_Measure = $Null
          }    
        }catch{
          write-ezlogs "An exception occurred in Import_Spotify_Playlists_Toggle toggle event" -showtime -catcherror $_
        }
      }
      $hashsetup.Import_Spotify_Playlists_Toggle.add_Toggled($hashsetup.Import_Spotify_Playlists_Toggle_Command)
      #---------------------------------------------- 
      #endregion Import_Spotify_Playlists_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Spotify_Status_Button
      #----------------------------------------------
      $hashsetup.Import_Spotify_Status_Button_Command = {
        Param($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Setup\API_Authentication_Setup.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header 'API Credential Setup Instructions' -clear
        }catch{
          write-ezlogs "An exception occurred in Import_Spotify_Status_Button click event" -showtime -catcherror $_
        }
      }
      $hashsetup.Import_Spotify_Status_Button.add_click($hashsetup.Import_Spotify_Status_Button_Command)
      #---------------------------------------------- 
      #endregion Import_Spotify_Status_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Spotify_Playlists_Button
      #----------------------------------------------
      $hashsetup.Import_Spotify_Playlists_Button_Command = {
        Param($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Spotify_Integration.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Import_Spotify_Playlists_Toggle.content -clear 
        }catch{
          write-ezlogs "An exception occurred in Import_Spotify_Playlists_Button click event" -showtime -catcherror $_
        }
      }
      $hashsetup.Import_Spotify_Playlists_Button.add_click($hashsetup.Import_Spotify_Playlists_Button_Command)
      #---------------------------------------------- 
      #endregion Import_Spotify_Playlists_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify_Playlists_Browse
      #----------------------------------------------
      $hashsetup.Spotify_Playlists_Browse_Command = {
        Param($sender)
        try{
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Playlist","Enter the url of the Spotify Playlist or Track",$button_settings)
          if(-not [string]::IsNullOrEmpty($result)){
            if(($result -match 'spotify\:' -or $result -match 'open.spotify.com')){
              if($hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $result){
                $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
                write-ezlogs "Adding URL $result" -showtime -logtype Setup -loglevel 2
                if($result -match "playlist\:" -or $result -match '\/playlist\/'){
                  if($result -match "playlist\:"){
                    $id = ($($result) -split('playlist:'))[1].trim() 
                  }elseif($result -match '\/playlist\/'){
                    $id = ($($result) -split('\/playlist\/'))[1].trim() 
                  } 
                  if($id -match '\?si\='){
                    $id = ($($id) -split('\?si\='))[0].trim()
                  }             
                  if($id -and $hashsetup.Spotify_Auth_app.token.access_token){
                    $Spotifyplaylist = Get-Playlist -Id $id -ApplicationName $thisApp.Config.App_Name
                  }  
                  if($Spotifyplaylist){
                    $name = $Spotifyplaylist.name
                    $url = $Spotifyplaylist.uri
                  }else{                
                    $Name = "Custom_$id"    
                    $url = $result            
                  }
                  $type = 'Playlist'  
                  $Playlist_info = $Spotifyplaylist                                
                }elseif($result -match "track\:" -or $result -match '\/track\/'){
                  if($result -match "track\:"){
                    $id = ($($result) -split('track:'))[1].trim() 
                  }elseif($result -match '\/track\/'){
                    $id = ($($result) -split('\/track\/'))[1].trim() 
                  }
                  if($id -match '\?si\='){
                    $id = ($($id) -split('\?si\='))[0].trim()
                  }              
                  if($id -and $hashsetup.Spotify_Auth_app.token.access_token){
                    $Spotifytrack = Get-Track -Id $id -ApplicationName $thisApp.Config.App_Name
                  }
                  if($Spotifytrack){
                    $name = "$($Spotifytrack.artists.name) - $($Spotifytrack.name)"
                    $url = $Spotifytrack.uri
                  }else{                
                    $Name = "Custom_$id"
                    $url = $result                
                  }  
                  $type = 'Track'
                  $Playlist_info = $Spotifytrack                      
                }elseif($result -match "episode\:" -or $result -match '\/episode\/'){
                  if($result -match "episode\:"){
                    $id = ($($result) -split('episode:'))[1].trim() 
                  }elseif($result -match '\/episode\/'){
                    $id = ($($result) -split('\/episode\/'))[1].trim() 
                  } 
                  if($id -match '\?si\='){
                    $id = ($($id) -split('\?si\='))[0].trim()
                  }              
                  if($id -and $hashsetup.Spotify_Auth_app.token.access_token){
                    $Spotifytrack = Get-Episode -Id $id -ApplicationName $thisApp.Config.App_Name
                  }
                  if($Spotifytrack){
                    $name = $($Spotifytrack.show.name)
                    $url = $Spotifytrack.uri
                  }else{                
                    $Name = "Custom_$id"
                    $url = $result                
                  }  
                  $type = 'Episode'
                  $Playlist_info = $Spotifytrack                      
                }
                Update-SpotifyPlaylists -hashsetup $hashsetup -Path $url -Name $Name -id $id -type $type -Playlist_Info $Playlist_info -VerboseLog:$thisApp.Config.Verbose_logging
              }else{
                write-ezlogs "The location $result has already been added!" -showtime -warning -logtype Setup
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[WARNING] The URL $result has already been added!" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear
              } 
            }else{
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
              update-EditorHelp -content "[WARNING] Invalid URL Provided" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear
              update-EditorHelp -content "The location $result is not a valid URL! Please ensure the URL is a valid Spotify Playlist or Track URL" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout     
              write-ezlogs "The location $result is not a valid URL!" -showtime -warning -logtype Setup
            }
          }else{
            write-ezlogs "No URL was provided!" -showtime -warning -logtype Setup
          }
        }catch{
          write-ezlogs "An exception occurred in Spotify_Playlists_Browse_Command click event" -showtime -catcherror $_
        }
      }
      $hashsetup.Spotify_Playlists_Browse.add_click($hashsetup.Spotify_Playlists_Browse_Command)
      #---------------------------------------------- 
      #endregion Spotify_Playlists_Browse
      #----------------------------------------------

      #---------------------------------------------- 
      #region Install_Spotify_Toggle
      #----------------------------------------------
      $hashsetup.Install_Spotify_Toggle_Command = {
        Param($sender)
        try{
          if($sender.isOn)
          {  
            Add-Member -InputObject $thisapp.configTemp -Name "Install_Spotify" -Value $true -MemberType NoteProperty -Force
            if($psversiontable.PSVersion.Major -gt 5 -and ![System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
              try{
                write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning -logtype Setup
                if(!(get-command Get-appxpackage -ErrorAction SilentlyContinue)){
                  Import-module Appx -usewindowspowershell -DisableNameChecking -ErrorAction SilentlyContinue
                }            
              }catch{
                write-ezlogs "[SETUP] An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
              }
            }
            if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
              $appinstalled = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
            }elseif((Get-appxpackage 'Spotify*')){
              write-ezlogs ">>>> Spotify installed as appx" -showtime -logtype Setup -loglevel 2
              $spotifyApx = $true
              $appinstalled = (Get-ItemProperty "$((Get-appxpackage 'Spotify*').InstallLocation)\Spotify.exe").VersionInfo.ProductVersion
            }else{
              $appinstalled = $false
            }
            if($appinstalled){
              $hashsetup.Install_Spotify_Status_textblock.text = "INSTALLED:`n$appinstalled"
              $hashsetup.Install_Spotify_Status_textblock.Foreground = 'LightGreen'
            }else{
              $hashsetup.Install_Spotify_Status_textblock.text = "NOT INSTALLED"
              $hashsetup.Install_Spotify_Status_textblock.Foreground = 'Orange'
            }
          }else{
            Add-Member -InputObject $thisapp.configTemp -Name "Install_Spotify" -Value $false -MemberType NoteProperty -Force
            $hashsetup.Install_Spotify_Status_textblock.text = ""
          }
        }catch{
          write-ezlogs "An exception occurred in $($sender.Name)" -catcherror $_
        } 
      }
      $hashsetup.Install_Spotify_Toggle.add_Toggled($hashsetup.Install_Spotify_Toggle_Command)
      #---------------------------------------------- 
      #endregion Install_Spotify_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Install_Spotify_Button
      #----------------------------------------------
      $hashsetup.Install_Spotify_Button.add_click({
          try{  
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Install_Spotify.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Install_Spotify_Toggle.content -clear     
          }catch{
            write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
          }

      })
      #---------------------------------------------- 
      #endregion Install_Spotify_Button
      #----------------------------------------------   
  
      #---------------------------------------------- 
      #region Install_Spotify_Now_Button
      #----------------------------------------------     
      $hashsetup.Install_Spotify_Now_Button.add_click({
          try{  
            write-ezlogs ">>>> Checking for existing installation of Spotify..." -showtime -logtype Setup -loglevel 2
            if($psversiontable.PSVersion.Major -gt 5 -and ![System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
              try{
                write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning -logtype Setup
                if(!(get-command Get-appxpackage -ErrorAction SilentlyContinue)){
                  Import-module Appx -usewindowspowershell -DisableNameChecking -ErrorAction SilentlyContinue
                }            
              }catch{
                write-ezlogs "[SETUP] An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
              }
            }
            if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
              $appinstalled = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
            }elseif((Get-appxpackage 'Spotify*')){
              write-ezlogs ">>>> Spotify installed as appx" -showtime -logtype Setup -loglevel 2
              $spotifyApx = $true
              $appinstalled = (Get-ItemProperty "$((Get-appxpackage 'Spotify*').InstallLocation)\Spotify.exe").VersionInfo.ProductVersion
            }else{
              $appinstalled = $false
            }
            if(!$appinstalled -or $spotifyApx){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Yes'
              $Button_Settings.NegativeButtonText = 'No'  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              write-ezlogs " | Checking admin permissions" -showtime -logtype Setup -loglevel 2
              if(!(Use-RunAs -Check)){
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Restart as Admin Required","In order to install Spotify, the app must be run with administrator permissions.`nWould you like to restart the app as admin now?",$okandCancel,$Button_Settings)
                if($result -eq 'Affirmative'){                  
                  if($First_Run){
                    write-ezlogs ">>>> Restarting app as admin...and restarting First Run" -showtime -logtype Setup -loglevel 2
                    Use-RunAs -ForceReboot -freshstart
                  }else{
                    write-ezlogs ">>>> Restarting app as admin..." -showtime -logtype Setup -loglevel 2
                    Use-RunAs -ForceReboot
                  }                 
                }else{
                  write-ezlogs "User did not wish to restart as admin, unable to continue" -showtime -warning -logtype Setup
                  return
                }
              }else{
                if($spotifyApx){
                  $title = "Spotify Appx Detected"
                  $message = "The Windows Store version of Spotify was detected as installed. Version: $appinstalled`n`nThe Windows Store version of Spotify is NOT recommended to use with this app, and is guaranteed to have issues. If you continue, this app will attempt to uninstall the Windows Store version, then install the normal Windows Spotify Client `n`nWould you like to continue?"
                }else{
                  $title = "Install Spotify?"
                  $message = "This will install the latest version of the Windows Spotify client from chocolatey.`n`nWould you like to continue?"
                }
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,$title,$message,$okandCancel,$Button_Settings)
              }
              if($result -eq 'Affirmative'){
                write-ezlogs "User wished to continue." -showtime -logtype Setup -loglevel 2
              }else{
                write-ezlogs "User did not wish to continue" -showtime -warning -logtype Setup
                return
              }
              if($synchash.Window.isVisible){
                $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.hide() })
                $hashsetup.MainWindow_Status = $true
              }
              #$hashsetup.window.hide()
              if($First_Run){
                write-ezlogs " | Unhiding Splash Screen" -showtime -logtype Setup -loglevel 2
                Update-SplashScreen -hash $hash -show 
              }else{
                Start-SplashScreen -SplashTitle "$($thisApp.Config.App_Name) Media Player" -SplashMessage 'Installing Spotify' -Splash_More_Info 'Please Wait' -current_folder $thisapp.Config.Current_Folder -log_file $thisapp.Config.Log_file
              }             
              $app_install_scriptblock = {
                #Install Chocolatey
                [void](confirm-requirements -thisApp $thisApp -noRestart)         
                if($spotifyApx){
                  if($hash.Window){
                    Update-SplashScreen -hash $hash -More_Info_Visibility 'Visible' -SplashMessage 'Uninstalling Spotify Appx version...'
                  }
                  write-ezlogs ">>>> Uninstalling Spotify Appx version..." -showtime -logtype Setup -loglevel 2
                  try{
                    if($psversiontable.PSVersion.Major -gt 5){
                      try{
                        write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning -logtype Setup
                        if(!(get-command Get-appxpackage -ErrorAction SilentlyContinue)){
                          Import-module Appx -usewindowspowershell -DisableNameChecking -ErrorAction SilentlyContinue
                        }            
                      }catch{
                        write-ezlogs "[SETUP] An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
                      }
                    }
                    (Get-appxpackage 'Spotify*') | Remove-AppxPackage 
                  }catch{
                    write-ezlogs "An exception occurred removing the Spotify appx package" -showtime -catcherror $_
                    $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
                        if(!$hashsetup.Window.isVisible){
                          $hashsetup.Window.Show()
                        }
                        $hashsetup.Window.Activate()       
                        $hashsetup.Editor_Help_Flyout.isOpen = $true
                        $hashsetup.Editor_Help_Flyout.header = 'Spotify Install'
                        $hashsetup.Install_Spotify_Status_textblock.text = "NOT INSTALLED"
                        $hashsetup.Install_Spotify_Status_textblock.Foreground = 'Orange'
                    })
                    update-EditorHelp -content "ERROR" -FontWeight bold -color Tomato -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -clear
                    update-EditorHelp -content "An exception occurred removing the Spotify appx package! See logs for details`n`n$($_ | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -Open
                    return
                  }               
                } 
                if($hash.Window){
                  Update-SplashScreen -hash $hash -More_Info_Visibility 'Visible' -SplashMessage 'Installing Spotify..'
                }
                write-ezlogs "----------------- [START] Install Spotify via chocolatey [START] -----------------" -showtime -logtype Setup -loglevel 2   
                $chocoappmatch = choco list Spotify
                write-ezlogs "$($chocoappmatch)" -showtime -logtype Setup -loglevel 2
                $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                if(-not [string]::IsNullOrEmpty($appinstalled) -and $appinstalled -notmatch 'Removing incomplete install for'){               
                  if([System.IO.Directory]::Exists("$($env:APPDATA)\Spotify")){
                    $appinstalled_Version = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
                    if($appinstalled_Version){
                      write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)). Also detected installed exe: $($appinstalled_Version). Will continue to attemp to update Spotify..." -showtime -warning -logtype Setup
                    }
                  }else{
                    write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)), yet it does not exist. Choco database likely corrupted or out-dated, performing remove of Spotify via Chocolately.." -showtime -warning -logtype Setup 
                    $chocoremove = choco uninstall Spotify --confirm --force
                    write-ezlogs "Verifying if Choco still thinks Spotify is installed..." -showtime -logtype Setup -loglevel 2
                    $chocoappmatch = choco list Spotify
                    $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                    if(-not [string]::IsNullOrEmpty($appinstalled)){
                      write-ezlogs "Choco still thinks Spotify is installed, unable to continue! Check choco logs at: $env:ProgramData\chocolatey\logs\chocolatey.log" -showtime -warning -logtype Setup
                      $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
                          if(!$hashsetup.Window.isVisible){
                            $hashsetup.Window.Show()
                          }
                          $hashsetup.window.Activate()       
                          $hashsetup.Editor_Help_Flyout.isOpen = $true
                          $hashsetup.Editor_Help_Flyout.header = 'Spotify Install'
                          $hashsetup.Install_Spotify_Status_textblock.text = "NOT INSTALLED"
                          $hashsetup.Install_Spotify_Status_textblock.Foreground = 'Orange'
                      })
                      update-EditorHelp -content "WARNING" -FontWeight bold -color Orange -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear -use_runspace
                      update-EditorHelp -content "There was an issue with Chocolatey, unable to install Spotify. Check app logs for more details! Sorry!" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -Open
                      return
                    }
                  }
                }
                $choco_install = choco upgrade Spotify --confirm --force --acceptlicense 4>&1 | Out-File -FilePath $logfile -Encoding unicode -Append
                write-ezlogs "----------------- [END] Install Spotify via chocolatey [END] -----------------" -showtime -logtype Setup -loglevel 2
                if($hash.Window){
                  Update-SplashScreen -hash $hash -More_Info_Visibility 'Visible' -SplashMessage 'Verifying if Spotify was installed successfully....'
                }
                write-ezlogs "Verifying if Spotify was installed successfully...." -showtime -logtype Setup -loglevel 2
                $chocoappmatch = choco list Spotify
                if($chocoappmatch){
                  $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                }      
                if($hashSetup.First_Run){
                  write-ezlogs ">>>> Hiding Splash screen to continue setup" -showtime -logtype Setup -loglevel 2
                  Update-SplashScreen -hash $hash -hide -SplashMessage 'Continuing Setup...'
                }elseif($hash.Window.isVisible){
                  #close-splashscreen
                  write-ezlogs ">>>> Closing Splash screen" -showtime -logtype Setup -loglevel 2
                  Update-SplashScreen -hash $hash -Close
                  if($hashsetup.MainWindow_Status){
                    write-ezlogs " | Showing Main Window" -showtime -logtype Setup -loglevel 2
                    $synchash.window.Dispatcher.Invoke("Normal",[action]{ $synchash.window.show() })
                    $hashsetup.MainWindow_Status = $false
                  }
                } 
                if(-not [string]::IsNullOrEmpty($appinstalled)){
                  if($appinstalled -match 'spotify'){
                    $appinstalled = $appinstalled.replace('spotify','').trim()
                  }
                  write-ezlogs "Spotify was successfully installed. Version $appinstalled" -showtime -logtype Setup -loglevel 2 -Success
                  $hashsetup.window.Dispatcher.Invoke("Normal",[action]{        
                      $hashsetup.Editor_Help_Flyout.isOpen = $true
                      $hashsetup.Editor_Help_Flyout.header = 'Spotify Install'
                      $hashsetup.Install_Spotify_Status_textblock.text = "INSTALLED:`n$appinstalled"
                      $hashsetup.Install_Spotify_Status_textblock.Foreground = 'LightGreen'
                  })
                  update-EditorHelp -content "SUCCESS" -FontWeight bold -color LightGreen -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear -use_runspace
                  update-EditorHelp -content "Spotify was successfully installed. Version`n $appinstalled" -color LightGreen -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -Open
                }else{
                  write-ezlogs "Unable to verify if Spotify installed successfully! Choco output: $($choco_install | out-string)" -showtime -warning -logtype Setup
                  $hashsetup.window.Dispatcher.Invoke("Normal",[action]{      
                      $hashsetup.Editor_Help_Flyout.isOpen = $true
                      $hashsetup.Editor_Help_Flyout.header = 'Spotify Install'
                      $hashsetup.Install_Spotify_Status_textblock.text = "UNKNOWN"
                      $hashsetup.Install_Spotify_Status_textblock.Foreground = 'Orange'
                  })
                  update-EditorHelp -content "WARNING" -FontWeight bold -color Orange -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -clear
                  update-EditorHelp -content "Unable to verify if Spotify installed successfully! See logs for details" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout -use_runspace -Open
                }
                if(!$hashsetup.Window.isVisible){
                  write-ezlogs " | Unhiding Setup Window" -showtime -logtype Setup -loglevel 2
                  $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
                      $hashsetup.Window.Show()
                      $hashsetup.Window.Activate()
                  })
                }                                   
              }
              try{
                if($First_Run){
                  if($hashSetup.Window.isVisible){
                    write-ezlogs " | Hiding setup window" -showtime -logtype Setup -loglevel 2
                    $hashSetup.Window.Hide()               
                  }
                  Invoke-Command -ScriptBlock $app_install_scriptblock
                }else{               
                  $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
                  Start-Runspace -scriptblock $app_install_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'App_install__RUNSPACE' -thisApp $thisApp -synchash $synchash
                  $Variable_list = $Null
                }
              }catch{
                write-ezlogs "An exception occurred Installing Spotify!" -showtime -catcherror $_
                $hashsetup.Window.Show()
                $hashsetup.Window.Activate()
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify Install'
                update-EditorHelp -content "ERROR" -FontWeight bold -color Tomato -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
                update-EditorHelp -content "An exception occurred Installing Spotify! See logs for details`n`n$($_ | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout
                return
              }
            }else{
              write-ezlogs "Spotify was detected as already installed. Version: $appinstalled" -showtime -warning -logtype Setup
              $message = "Spotify was detected as already installed. Version: $appinstalled"
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              }        
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Spotify'
              update-EditorHelp -content "INFO" -FontWeight bold -color cyan -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
              update-EditorHelp -content $message -RichTextBoxControl $hashsetup.EditorHelpFlyout -color cyan
            }                  
          }catch{
            write-ezlogs "An exception occurred in Install_Spotify_Now_Button.add_click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Install_Spotify_Now_Button
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Spotify Updates Toggle
      #----------------------------------------------
      $hashsetup.Spotify_Update_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Spotify_Update_Interval_ComboBox.IsEnabled = $sender.isOn
          $thisapp.configTemp.Spotify_Update = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Spotify_Update_Toggle event" -CatchError $_ -showtime
        } 
      }
      $hashsetup.Spotify_Update_Toggle.add_Toggled($hashsetup.Spotify_Update_Toggle_Command)
      #---------------------------------------------- 
      #endregion Spotify Updates Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify_Update_Interval_ComboBox
      #----------------------------------------------
      $hashsetup.Spotify_Update_Interval_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Spotify_Update_Interval_ComboBox.SelectedIndex -ne -1){    
              $hashsetup.Spotify_Update_Interval_Label.BorderBrush = 'Green'
              if($hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content -match 'Startup'){
                $interval = $hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content
              }elseif($hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content -match 'Minutes'){
                $interval = [TimeSpan]::FromMinutes("$(($hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content -replace 'Minutes', '').trim())")
              }elseif($hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content -match 'Hour'){
                $interval = [TimeSpan]::FromHours("$(($hashsetup.Spotify_Update_Interval_ComboBox.Selecteditem.Content -replace 'Hour', '').trim())")
              }
              Add-Member -InputObject $thisapp.configTemp -Name 'Spotify_Update_Interval' -Value $interval -MemberType NoteProperty -Force
            }
            else{          
              $hashsetup.Spotify_Update_Interval_Label.BorderBrush = 'Red'
              Add-Member -InputObject $thisapp.configTemp -Name 'Spotify_Update_Interval' -Value '' -MemberType NoteProperty -Force      
            }
          }catch{
            write-ezlogs "An exception occurred in Spotify_Update_Interval_ComboBox event" -CatchError $_ -showtime
          }
      })
      #---------------------------------------------- 
      #endregion Spotify_Update_Interval_ComboBox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Spotify Updates Help
      #----------------------------------------------
      $hashsetup.Spotify_Update_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Spotify_AutoUpdate.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Spotify_Update_Toggle.content            
          }catch{
            write-ezlogs "An exception occurred in Spotify_Update_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Spotify Updates Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube WebPlayer Toggle
      #----------------------------------------------
      $hashsetup.Youtube_WebPlayer_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Use_invidious_Toggle.IsEnabled = $sender.isOn
          $thisapp.configTemp.Youtube_WebPlayer = $sender.isOn     
        }catch{
          write-ezlogs "An exception occurred in Youtube_WebPlayer_Toggle event" -showtime -catcherror $_
        } 
      }
      $hashsetup.Youtube_WebPlayer_Toggle.add_Toggled($hashsetup.Youtube_WebPlayer_Toggle_Command)
      #---------------------------------------------- 
      #endregion Youtube WebPlayer Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube WebPlayer Help
      #----------------------------------------------
      $hashsetup.Youtube_WebPlayer_Help_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_Webplayer.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header $hashsetup.Youtube_WebPlayer_Toggle.Content -clear
          }catch{
            write-ezlogs "An exception occurred in Youtube_WebPlayer_Help_Button.add_Click" -CatchError $_ -enablelogs
          }   
      })
      #---------------------------------------------- 
      #endregion Youtube WebPlayer Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Use_invidious Toggle
      #----------------------------------------------
      $hashsetup.Use_invidious_Toggle_Command = {
        Param($sender)
        try{
          if($sender.isOn -eq $true){
            $hashsetup.Use_invidious_grid.BorderBrush = 'LightGreen'    
            $thisapp.configTemp.Use_invidious = $true
          }else{
            $thisapp.configTemp.Use_invidious = $false
            $hashsetup.Use_invidious_grid.BorderBrush = 'Red'   
          }      
        }catch{
          write-ezlogs "An exception occurred in Use_invidious_Toggle event" -showtime -catcherror $_
        } 
      }
      $hashsetup.Use_invidious_Toggle.add_Toggled($hashsetup.Use_invidious_Toggle_Command)
      #---------------------------------------------- 
      #endregion Use_invidious Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Use_invidious Help
      #----------------------------------------------
      $hashsetup.Use_invidious_Help_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Invidious_Webplayer.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header $hashsetup.Use_invidious_Toggle.Content -clear
          }catch{
            write-ezlogs "An exception occurred in Use_invidious_Help_Button.add_Click" -CatchError $_ -enablelogs
          }    
      })
      #---------------------------------------------- 
      #endregion Use_invidious Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube Updates Toggle
      #----------------------------------------------
      $hashsetup.Youtube_Update_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Youtube_Update = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Youtube_Update_Toggle event" -showtime -catcherror $_
        } 
      }
      $hashsetup.Youtube_Update_Toggle.add_Toggled($hashsetup.Youtube_Update_Toggle_Command)
      #---------------------------------------------- 
      #endregion Youtube Updates Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Update_Interval_ComboBox
      #----------------------------------------------
      $hashsetup.Youtube_Update_Interval_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Youtube_Update_Interval_ComboBox.SelectedIndex -ne -1){    
              $hashsetup.Youtube_Update_Interval_Label.BorderBrush = 'Green'
              if($hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content -match 'Startup'){
                $interval = $hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content
              }elseif($hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content -match 'Minutes'){
                $interval = [TimeSpan]::FromMinutes("$(($hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content -replace 'Minutes', '').trim())")
              }elseif($hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content -match 'Hour'){
                $interval = [TimeSpan]::FromHours("$(($hashsetup.Youtube_Update_Interval_ComboBox.Selecteditem.Content -replace 'Hour', '').trim())")
              }
              Add-Member -InputObject $thisapp.configTemp -Name 'Youtube_Update_Interval' -Value $interval -MemberType NoteProperty -Force
            }
            else{          
              $hashsetup.Youtube_Update_Interval_Label.BorderBrush = 'Red'
              Add-Member -InputObject $thisapp.configTemp -Name 'Youtube_Update_Interval' -Value '' -MemberType NoteProperty -Force      
            }
          }catch{
            write-ezlogs "An exception occurred in Youtube_Update_Interval_ComboBox event" -CatchError $_ -showtime
          }
      }) 
      #---------------------------------------------- 
      #endregion Youtube_Update_Interval_ComboBox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube Updates Help
      #----------------------------------------------
      $hashsetup.Youtube_Update_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_AutoUpdate.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Youtube_Update_Toggle.content            
          }catch{
            write-ezlogs "An exception occurred in Youtube_Update_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube Updates Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable Sponsorblock Toggle
      #----------------------------------------------
      $hashsetup.Enable_Sponsorblock_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Sponsorblock_ActionType_ComboBox.IsEnabled = $sender.isOn
          $thisapp.configTemp.Enable_Sponsorblock = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_Sponsorblock_Toggle event" -showtime -catcherror $_
        } 
      }
      $hashsetup.Enable_Sponsorblock_Toggle.add_Toggled($hashsetup.Enable_Sponsorblock_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable Sponsorblock Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Sponsorblock_ActionType_ComboBox
      #----------------------------------------------
      $hashsetup.Sponsorblock_ActionType_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Sponsorblock_ActionType_ComboBox.SelectedIndex -ne -1){    
              Add-Member -InputObject $thisapp.configTemp -Name 'Sponsorblock_ActionType' -Value $hashsetup.Sponsorblock_ActionType_ComboBox.Selecteditem.Content -MemberType NoteProperty -Force
            }
            else{          
              $hashsetup.Youtube_Update_Interval_Label.BorderBrush = 'Red'
              Add-Member -InputObject $thisapp.configTemp -Name 'Sponsorblock_ActionType' -Value '' -MemberType NoteProperty -Force      
            }
          }catch{
            write-ezlogs "An exception occurred in Sponsorblock_ActionType_ComboBox event" -CatchError $_ -showtime
          }
      }) 
      #---------------------------------------------- 
      #endregion Sponsorblock_ActionType_ComboBox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Sponsorblock Help
      #----------------------------------------------
      $hashsetup.Enable_Sponsorblock_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_Sponsorblock.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Enable_Sponsorblock_Toggle.content            
          }catch{
            write-ezlogs "An exception occurred in Enable_Sponsorblock_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Sponsorblock Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region YoutubeComments Toggle
      #----------------------------------------------
      $hashsetup.Enable_YoutubeComments_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Enable_YoutubeComments = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_YoutubeComments_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Enable_YoutubeComments_Toggle.add_Toggled($hashsetup.Enable_YoutubeComments_Toggle_Command)
      #---------------------------------------------- 
      #endregion YoutubeComments Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region YoutubeComments Help
      #----------------------------------------------
      $hashsetup.YoutubeComments_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_YoutubeComments.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header $hashsetup.Enable_YoutubeComments_Toggle.Content -clear   
          }catch{
            write-ezlogs "An exception occurred in YoutubeComments_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion YoutubeComments Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region PlayLink_OnDrop Toggle
      #----------------------------------------------
      $hashsetup.PlayLink_OnDrop_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.PlayLink_OnDrop = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in PlayLink_OnDrop_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.PlayLink_OnDrop_Toggle.add_Toggled($hashsetup.PlayLink_OnDrop_Toggle_Command)
      #---------------------------------------------- 
      #endregion PlayLink_OnDrop Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region PlayLink_OnDrop Help
      #----------------------------------------------
      $hashsetup.PlayLink_OnDrop_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_StartOnDrop.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header $hashsetup.PlayLink_OnDrop_Toggle.Content -clear   
          }catch{
            write-ezlogs "An exception occurred in PlayLink_OnDrop_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion PlayLink_OnDrop Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Quality Combobox
      #----------------------------------------------
      [void]$hashsetup.Youtube_Quality_ComboBox.items.add('Auto')
      [void]$hashsetup.Youtube_Quality_ComboBox.items.add('Best')
      [void]$hashsetup.Youtube_Quality_ComboBox.items.add('Medium')
      [void]$hashsetup.Youtube_Quality_ComboBox.items.add('Low')
      $hashsetup.Youtube_Quality_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Youtube_Quality_ComboBox.Selectedindex -ne -1){   
              if($hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Best' -or $hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Auto'){
                $hashsetup.Youtube_Quality_Label.BorderBrush = 'LightGreen'
              }elseif($hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Medium'){
                $hashsetup.Youtube_Quality_Label.BorderBrush = 'Gray'
              }else{
                $hashsetup.Youtube_Quality_Label.BorderBrush = 'Red'
              }   
              Add-Member -InputObject $thisapp.configTemp -Name 'Youtube_Quality' -Value $($hashsetup.Youtube_Quality_ComboBox.selecteditem) -MemberType NoteProperty -Force
            }
            else{      
              Add-Member -InputObject $thisapp.configTemp -Name 'Youtube_Quality' -Value 'Auto' -MemberType NoteProperty -Force  
              $hashsetup.Youtube_Quality_Label.BorderBrush = 'Gray'               
            }
          }catch{
            write-ezlogs "An exception occurred in Youtube_Quality_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Youtube_Quality Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Download_textbox
      #----------------------------------------------      
      $hashsetup.Youtube_Download_textbox.Add_TextChanged({
          try{
            if([system.io.directory]::Exists($hashsetup.Youtube_Download_textbox.text)){
              $hashsetup.Youtube_Download_Label.BorderBrush="LightGreen"         
            }else{
              $hashsetup.Youtube_Download_Label.BorderBrush="Red"
            }
          }catch{
            write-ezlogs "An exception occurred in Youtube_Download_textbox.Add_TextChanged" -showtime -catcherror $_
          }
      })
      if(-not [string]::IsNullOrEmpty($thisApp.Config.Youtube_Download_Path)){
        $hashsetup.Youtube_Download_textbox.text = $thisApp.Config.Youtube_Download_Path
      }
      #---------------------------------------------- 
      #endregion Youtube_Download_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Download_Browse
      #---------------------------------------------- 
      $hashsetup.Youtube_Download_Browse.add_Click({
          try{
            $result = Open-FolderDialog -Title 'Select the directory where Youtube videos will be downloaded'
            if(-not [string]::IsNullOrEmpty($result)){$hashsetup.Youtube_Download_textbox.text = $result}  
          }catch{
            write-ezlogs "An exception occurred in Youtube_Download_Browse.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_Download_Browse
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Download Help
      #----------------------------------------------
      $hashsetup.Youtube_Download_Help_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Default_Download_Path.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header 'Default Youtube Download Location' -clear         
          }catch{
            write-ezlogs "An exception occurred in Youtube_Download_Help_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_Download Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Quality Help
      #----------------------------------------------
      $hashsetup.Youtube_Quality_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_Quality.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open  -Header  $hashsetup.Youtube_Quality_Label.content -clear                 
          }catch{
            write-ezlogs "An exception occurred in Youtube_Quality_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_Quality Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Update_YoutubePlaylists_Timer
      #----------------------------------------------
      try{
        $hashSetup.YoutubePlaylists_itemsArray = [System.Collections.Generic.List[Object]]::new()
        #$hashSetup.YoutubePlaylists_items = New-Object System.Collections.ObjectModel.ObservableCollection[object]
        $hashsetup.Update_YoutubePlaylists_Timer = [System.Windows.Threading.DispatcherTimer]::new()
        $hashsetup.Update_YoutubePlaylists_Timer_ScriptBlock = {
          try{             
            if($hashsetup.YoutubePlaylists_Grid.Items){
              [void]$hashsetup.YoutubePlaylists_Grid.Items.clear()
            }          
            foreach($item in $this.tag | where {$hashsetup.YoutubePlaylists_Grid.Items -notcontains $_}){
              [void]$hashsetup.YoutubePlaylists_Grid.Items.add($item)
            }
            $this.stop()
          }catch{
            write-ezlogs "An exception occurred in Update_YoutubePlaylists_Timer" -showtime -catcherror $_
            $this.stop()
          }finally{
            $this.stop()
          }  
        }
        $hashsetup.Update_YoutubePlaylists_Timer.add_tick($hashsetup.Update_YoutubePlaylists_Timer_ScriptBlock) 
      }catch{
        write-ezlogs "An exception occurred in Update-YoutubePlaylists startup" -showtime -catcherror $_
      } 
      #---------------------------------------------- 
      #endregion Update_YoutubePlaylists_Timer
      #----------------------------------------------

      #---------------------------------------------- 
      #region Update_YoutubeStatus_Timer
      #----------------------------------------------
      $hashsetup.Update_YoutubeStatus_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $hashsetup.Update_YoutubeStatus_Timer_ScriptBlock = {
        try{
          write-ezlogs ">>>> Update_YoutubeStatus_Timer has started" -LogLevel 2 -logtype Setup
          if($hashsetup.Youtube_Progress_Ring.IsActive){
            $hashsetup.Youtube_Progress_Ring.IsActive = $false
          }
          if($hashsetup.YoutubeMedia_Importing_Settings_Expander){
            $hashsetup.YoutubeMedia_Importing_Settings_Expander.isEnabled = $true
          }                 
          if($this.tag -eq 'AuthSuccess'){
            write-ezlogs "Authenticated to Youtube and retrieved access tokens" -showtime -LogLevel 2 -logtype Setup -Success
            $hashsetup.Youtube_Playlists_Import.isEnabled = $true
            $hashsetup.Import_Youtube_textbox.text = ''
            $hashsetup.Import_Youtube_Status_textbox.Text="[VALID]"
            $hashsetup.Import_Youtube_Status_textbox.Foreground = "LightGreen"
            $hashsetup.Import_Youtube_textbox.isEnabled = $true
            $hyperlink = 'https://Youtube_Auth'
            $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
            $link_hyperlink.NavigateUri = $hyperlink
            $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
            $link_hyperlink.Foreground = "LightBlue"
            [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
            [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
            [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
            [void]$hashsetup.Import_Youtube_textbox.Inlines.add("If you wish to update or change your Youtube credentials, click ")  
            [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
            $hashsetup.Import_Youtube_textbox.Foreground = "LightGreen"
            $hashsetup.Import_Youtube_textbox.FontSize = '14'
            $hashsetup.Import_Youtube_transitioningControl.Height = '60'
            if($MahDialog_hash.window.Dispatcher -and $MahDialog_hash.window.isVisible){
              write-ezlogs ">>>> Closing Web Login Window" -LogLevel 2 -logtype Setup
              $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
            }          
            Invoke-YoutubeImport -thisapp $thisApp -hashsetup $hashsetup
            update-EditorHelp -content "[SUCCESS] Authenticated to Youtube and saved access tokens into the Secret Vault! You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear -Open -Header 'Youtube Authentication' 
          }elseif($this.tag -eq 'AuthFail'){           
            write-ezlogs "[Show-SettingsWindow] Unable to successfully authenticate to Youtube!" -showtime -warning -logtype Youtube
            $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $false
            $hashsetup.Youtube_Playlists_Import.isEnabled = $false  
            update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Youtube! Some Youtube features may be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear -Open -Header 'Youtube Authentication'
          }
          if(!$hashsetup.Window.isVisible){
            $hashsetup.Window.Show() 
          }         
        }catch{
          write-ezlogs "An exception occurred in Youtube_UpdateStatus_Timer" -catcherror $_
        }finally{
          $this.tag = $null
          $this.stop()
        } 
      }
      $hashsetup.Update_YoutubeStatus_Timer.add_Tick($hashsetup.Update_YoutubeStatus_Timer_ScriptBlock)
      #---------------------------------------------- 
      #endregion Update_YoutubePlaylists_Timer
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_AuthHandler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashSetup.Youtube_AuthHandler = {
        param ($sender,$e)
        if($sender.NavigateUri -match 'Youtube_Auth'){
          try{
            $hashsetup.Youtube_Progress_Ring.isActive=$true
            $hashsetup.YoutubeMedia_Importing_Settings_Expander.isEnabled = $false
            if($hashsetup.Update_YoutubeStatus_Timer.isEnabled){
              write-ezlogs ">>>> Stopping Update_YoutubeStatus_Timer" -warning -logtype Setup
              $hashsetup.Update_YoutubeStatus_Timer.tag = $null
              $hashsetup.Update_YoutubeStatus_Timer.stop()
            }
            <#            if([System.IO.Directory]::Exists("$($thisApp.Config.Temp_Folder)\Setup_Webview2")){   
                try{
                write-ezlogs ">>>> Removing existing Webview2 cache $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -logtype Setup -LogLevel 2
                del "\\?\$($thisApp.Config.Temp_Folder)\Setup_Webview2" -Force -Confirm:$false -Recurse
                }catch{
                write-ezlogs "An exception occurred attempting to remove $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -catcherror $_
                }
            }#>
            try{
              $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
            }
            if($secretstore){
              write-ezlogs ">>>> Removing stored Youtube authentication secrets from vault" -showtime -warning -logtype Setup
              foreach($secret in $hashsetup.valid_secrets | where-Object {$_ -match 'Youtube'}){  
                $secret_info = Get-SecretInfo -Filter $secret -VaultName $thisApp.config.App_Name -ErrorAction SilentlyContinue       
                if($secret_info.Name -eq $secret){
                  try{                  
                    write-ezlogs " | Removing Secret $($secret_info.Name)" -showtime -warning -logtype Setup
                    Remove-secret -Name $($secret_info.Name) -Vault $thisApp.config.App_Name
                  }catch{
                    write-ezlogs "An exception occurred removing Secret $($secret) from vault $($thisApp.config.App_Name)" -catcherror $_
                  }
                }
              }
            }
            try{
              Grant-YoutubeOauth -thisApp $thisApp
              write-ezlogs ">>>> Youtube Authentication has finished" -logtype Setup -loglevel 2
              if($hashsetup.Update_YoutubeStatus_Timer){
                #write-ezlogs ">>>> Starting Update_YoutubeStatus_Timer" -logtype Setup -loglevel 2
                $hashsetup.Update_YoutubeStatus_Timer.start()
              }
            }catch{
              write-ezlogs "[Show-SettingsWindow] An exception occurred in Grant-YoutubeOauth" -showtime -catcherror $_
            }         
          }catch{
            write-ezlogs "An exception occurred in Youtube_AuthHandler routed event" -showtime -catcherror $_
          }         
        }     
      }   
      #---------------------------------------------- 
      #endregion Youtube_AuthHandler
      #----------------------------------------------  

      #---------------------------------------------- 
      #region Youtube_ImportHandler
      #----------------------------------------------         
      [System.Windows.RoutedEventHandler]$Youtube_ImportHandler = {
        param ($sender,$e)
        $hashsetup.Youtube_Playlists_Import_Progress_Ring.isActive=$true
        $hashsetup.Youtube_Playlists_Import.isEnabled = $false
        $Youtube_Import_Scriptblock = {
          try{
            Invoke-YoutubeImport -thisapp $thisApp -hashsetup $hashsetup               
          }catch{
            write-ezlogs "An exception occurred in Youtube_ImportHandler routed event" -showtime -catcherror $_
          }     
        }
        try{
          $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and !$_.description){$_}}} 
          Start-Runspace -scriptblock $Youtube_Import_Scriptblock -Variable_list $Variable_list -runspace_name 'Youtube_ImportHandler_RUNSPACE' -thisApp $thisApp -synchash $synchash
          $Variable_list = $Null
          $Youtube_Import_Scriptblock = $Null
        }catch{
          write-ezlogs "An exception occurred executing Youtube_ImportHandler_RUNSPACE" -showtime -catcherror $_
        }             
      } 
      [void]$hashsetup.Youtube_Playlists_Import.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_ImportHandler) 
      #---------------------------------------------- 
      #endregion Youtube_ImportHandler
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Youtube_Auth_ComboBox
      #----------------------------------------------     
      $hashsetup.Import_Youtube_Auth_ComboBox.add_SelectionChanged({
          Param($Sender)
          try{
            if($Sender.selectedindex -eq -1){
              $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Red"
            }else{
              $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Green"
            } 
          }catch{
            write-ezlogs "An exception occured in Import_Youtube_Auth_ComboBox.add_SelectionChanged" -catcherror $_
          }
      }) 
      #---------------------------------------------- 
      #endregion Import_Youtube_Auth_ComboBox
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Youtube_Auth_Toggle
      #---------------------------------------------- 
      $hashsetup.Import_Youtube_Auth_Toggle_Command = {
        Param($sender)
        try{
          $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $sender.isOn
          $thisapp.configTemp.Import_Youtube_Browser_Auth = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Import_Youtube_Auth_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Import_Youtube_Auth_Toggle.add_Toggled($hashsetup.Import_Youtube_Auth_Toggle_Command)
      #---------------------------------------------- 
      #endregion Import_Youtube_Auth_Toggle
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Youtube_Playlists_Toggle
      #----------------------------------------------
      $hashsetup.Import_Youtube_Playlists_Toggle_Command = {
        Param($sender)
        try{
          if($sender.tag -ne 'Startup'){
            if($sender.isOn) {     
              write-ezlogs ">>>> Enabling Import Youtube Playlists" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
              $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true   
              $hashsetup.YoutubePlaylists_Grid.MaxHeight = 250  
              $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true 
              if($hashsetup.Import_Youtube_Auth_Toggle.isOn){
                $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $true
              }else{
                $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
              }           
              Add-Member -InputObject $thisapp.configTemp -Name "Import_Youtube_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue   
              try{
                $Name = $($thisApp.Config.App_Name)
                $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
                $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
                if(!$secretstore){
                  write-ezlogs ">>>> Couldnt find secret vault, Attempting to create new application: $Name" -showtime -LogLevel 2 -logtype Setup
                  try{
                    $secretstore = New-YoutubeApplication -thisApp $thisApp -Name $Name -ConfigPath $ConfigPath                  
                  }catch{
                    write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs 
                  }   
                }else{
                  write-ezlogs "Retrieved SecretVault: $($Name)" -showtime -LogLevel 2 -logtype Setup -Success  
                }                 
              }catch{
                write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime
              }
              try{
                $access_token = Get-secret -name YoutubeAccessToken  -Vault $Name -ErrorAction SilentlyContinue
                $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $Name -ErrorAction SilentlyContinue
                if($refresh_access_token){
                  $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $Name -ErrorAction SilentlyContinue
                }   
              }catch{
                write-ezlogs "An exception occurred getting Youtube secrets from vault $Name" -catcherror $_
                if($_.Exception -match 'A valid password is required to access the Microsoft.PowerShell.SecretStore vault'){
                  try{
                    write-ezlogs "Attempting to unlock SecretStore Vault: $($Name)" -warning -logtype Setup
                    Unlock-SecretVault -VaultName $Name -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
                    $access_token = Get-secret -name YoutubeAccessToken  -Vault $Name -ErrorAction SilentlyContinue
                    $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $Name -ErrorAction SilentlyContinue
                    if($refresh_access_token){
                      $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $Name -ErrorAction SilentlyContinue
                    } 
                  }catch{
                    write-ezlogs "An exception occurred getting Youtube secrets after unlocking SecretVault $Name" -catcherror $_
                  }
                }
              }                    
              if($hashsetup.Import_Youtube_textbox.Inlines){
                $hashsetup.Import_Youtube_textbox.Inlines.clear()
              }
              if([string]::IsNullOrEmpty($access_token_expires) -or [string]::IsNullOrEmpty($access_token) -or [string]::IsNullOrEmpty($refresh_access_token)){
                $hyperlink = 'https://Youtube_Auth'
                write-ezlogs "No valid Youtube authentication was found (Access_Token: $($access_token)) - (Access_token_expires: $($access_token_expires)) - (Refresh_access_token: $($refresh_access_token))" -showtime -logtype Setup -Warning
                $hashsetup.Import_Youtube_Status_textbox.Text="[NONE]"
                $hashsetup.Import_Youtube_Status_textbox.Foreground = "Orange"
                $hashsetup.Import_Youtube_textbox.isEnabled = $true
                $hashsetup.Youtube_Playlists_Import.isEnabled = $false
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                $link_hyperlink.FontWeight = 'Bold'
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $hashsetup.Import_Youtube_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add(" to provide your Youtube account credentials.")   
                $hashsetup.Import_Youtube_textbox.Foreground = "Orange"
                $hashsetup.Import_Youtube_textbox.FontSize = '14'
                $hashsetup.Import_Youtube_transitioningControl.Height = '60'
              }else{
                write-ezlogs "Returned Youtube authentication - (Expires: $($access_token_expires))" -showtime -logtype Setup -LogLevel 2 -Success
                $hashsetup.Import_Youtube_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Youtube_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Youtube_textbox.isEnabled = $true
                $hashsetup.Youtube_Playlists_Import.isEnabled = $true
                $hyperlink = 'https://Youtube_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add("If you wish to update or change your Youtube credentials, click ")  
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
                $hashsetup.Import_Youtube_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Youtube_textbox.FontSize = '14'
                $hashsetup.Import_Youtube_transitioningControl.Height = '60'        
              }                   
            }else{
              $hashsetup.Youtube_Playlists_Browse.IsEnabled = $false
              $hashsetup.YoutubePlaylists_Grid.IsEnabled = $false    
              $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
              $hashsetup.Youtube_Playlists_Import.isEnabled = $false
              $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $false    
              $hashsetup.YoutubePlaylists_Grid.MaxHeight = '0'
              Add-Member -InputObject $thisapp.configTemp -Name "Import_Youtube_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
              $hashsetup.Import_Youtube_textbox.text = ""
              $hashsetup.Import_Youtube_transitioningControl.Height = '0'
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Import_Youtube_Playlists_Toggle.add_Toggled event" -showtime -catcherror $_
        }finally{
          $sender.tag = $Null
        }
      }
      $hashsetup.Import_Youtube_Playlists_Toggle.add_Toggled($hashsetup.Import_Youtube_Playlists_Toggle_Command)
      #---------------------------------------------- 
      #endregion Import_Youtube_Playlists_Toggle
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Youtube_Playlists_Button
      #----------------------------------------------
      $hashsetup.Import_Youtube_Playlists_Button.add_click({
          try{  
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_Integration.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Import_Youtube_Playlists_Toggle.content  
          }catch{
            write-ezlogs "An exception occurred when opening main UI window" -CatchError $_
          }

      }) 
      #---------------------------------------------- 
      #endregion Import_Youtube_Playlists_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Youtube_Status_Button
      #----------------------------------------------
      $hashsetup.Import_Youtube_Status_Button_Command = {
        Param($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Setup\API_Authentication_Setup.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header 'API Credential Setup Instructions' -clear
        }catch{
          write-ezlogs "An exception occurred in Import_Youtube_Status_Button click event" -showtime -catcherror $_
        }
      }
      $hashsetup.Import_Youtube_Status_Button.add_click($hashsetup.Import_Youtube_Status_Button_Command)
      #---------------------------------------------- 
      #endregion Import_Youtube_Status_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Import_Youtube_Auth_Button
      #----------------------------------------------
      $hashsetup.Import_Youtube_Auth_Button.add_click({
          try{  
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_BrowserCookies.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Import_Youtube_Auth_Toggle.Content  
          }catch{
            write-ezlogs "An exception occurred in Import_Youtube_Auth_Button.add_click" -CatchError $_ 
          }

      })  
      #---------------------------------------------- 
      #endregion Import_Youtube_Auth_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_Playlists_Browse
      #----------------------------------------------      
      $hashsetup.Youtube_Playlists_Browse.add_click({  
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Youtube URL","Enter the url of the Youtube Playlist, Channel or Video",$button_settings)
          if(-not [string]::IsNullOrEmpty($result)){
            if((Test-URL $result) -and ($result -match 'youtube\.com' -or $result -match 'yewtu\.be|invidious' -or $result -match 'soundcloud\.com')){
              if($hashsetup.YoutubePlaylists_Grid.items.path -notcontains $result){
                write-ezlogs "Adding URL $result" -showtime -logtype Setup -LogLevel 2
                if($result -match 'tv\.youtube'){
                  if($result -match "v="){
                    $id = ($($result) -split('v='))[1].trim() 
                  }elseif($result -match "\/watch\/"){
                    $id = ($($result) -split('/watch/'))[1].trim() 
                  }
                  $Name = "Custom_$id"
                  $type = "YoutubeTV"
                }elseif($result -match "v="){
                  $id = ($($result) -split('v='))[1].trim()  
                  $type = 'YoutubeVideo'
                  $Name = "Custom_$id"          
                }elseif($result -match 'list='){
                  $id = ($($result) -split('list='))[1].trim()    
                  $type = 'YoutubePlaylist'     
                  $Name = "Custom_$id"                 
                }elseif($result -match 'youtube\.com\/channel\/'){
                  $id = $((Get-Culture).textinfo.totitlecase(($result | split-path -leaf).tolower())) 
                  $Name = "Custom_$id"
                  $type = 'YoutubeChannel'
                }elseif($result -match "\/watch\/"){
                  $id = [regex]::matches($result, "\/watch\/(?<value>.*)")| %{$_.groups[1].value}
                  $Name = "Custom_$id"
                  $type = 'YoutubeVideo'
                }elseif($result -notmatch "v=" -and $result -notmatch '\?' -and $result -notmatch '\&'){
                  $id = ([uri]$result).segments | select -last 1
                  $Name = "Custom_$id"
                  $type = 'YoutubeVideo'
                }elseif($result -match "soundcloud\.com"){
                  $id = ([uri]$result).segments | select -last 1
                  $Name = "Custom_$id"
                  $type = 'SoundCloud'
                }
                if(!$hashSetup.YoutubePlaylists_itemsArray.Number){ 
                  $Number = 1
                }else{
                  $Number = $hashSetup.YoutubePlaylists_itemsArray.Number | select -last 1
                  $Number++
                }
                [void]$hashSetup.YoutubePlaylists_itemsArray.add([PSCustomObject]@{
                    Number=$Number;       
                    ID = $id
                    Name=$Name
                    Path=$result
                    Type=$type
                    Playlist_Info = ''
                })
                $hashsetup.Update_YoutubePlaylists_Timer.tag = $hashSetup.YoutubePlaylists_itemsArray
                $hashsetup.Update_YoutubePlaylists_Timer.start()
              }else{
                write-ezlogs "The location $result has already been added!" -showtime -warning -logtype Setup
              } 
            }else{
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Youtube Playlists'            
              update-EditorHelp -content "[WARNING] Invalid URL Provided" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear
              update-EditorHelp -content "The location $result is not a valid URL! Please ensure the URL is a valid Youtube or Twitch URL" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout     
              write-ezlogs "The location $result is not a valid URL!" -showtime -warning -logtype Setup -LogLevel 2
            }
          }else{
            write-ezlogs "No URL was provided!" -showtime -warning -logtype Setup
          } 
      })
      #---------------------------------------------- 
      #endregion Youtube_Playlists_Browse
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Playlists_Import_Checked
      #----------------------------------------------
      $hashsetup.Youtube_My_Playlists_Import.add_Checked({
          try{
            Add-Member -InputObject $thisapp.configTemp -Name "Import_My_Youtube_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occured in Youtube_My_Playlists_Import.add_Checked event" -showtime -catcherror $_
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_My_Playlists_Import_Checked
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Playlists_Import_UnChecked
      #----------------------------------------------
      $hashsetup.Youtube_My_Playlists_Import.add_UnChecked({
          try{
            Add-Member -InputObject $thisapp.configTemp -Name "Import_My_Youtube_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occured in Youtube_My_Playlists_Import.add_UnChecked event" -showtime -catcherror $_
          }
      }) 
      #---------------------------------------------- 
      #endregion Youtube_My_Playlists_Import_UnChecked
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Playlists_Import_Button
      #----------------------------------------------
      $hashsetup.Youtube_My_Playlists_Import_Button.add_click({
          try{  
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_MyUploads.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Youtube_My_Playlists_Import.content
          }catch{
            write-ezlogs "An exception occurred in Youtube_My_Playlists_Import_Button.add_click event" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_My_Playlists_Import_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Subscriptions_Import_Checked
      #----------------------------------------------
      $hashsetup.Youtube_My_Subscriptions_Import.add_Checked({
          try{
            Add-Member -InputObject $thisapp.configTemp -Name "Import_My_Youtube_Subscriptions" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occured in Youtube_My_Subscriptions_Import.add_Checked event" -showtime -catcherror $_
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_My_Subscriptions_Import_Checked
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Subscriptions_Import_UnChecked
      #----------------------------------------------
      $hashsetup.Youtube_My_Subscriptions_Import.add_UnChecked({
          try{
            Add-Member -InputObject $thisapp.configTemp -Name "Import_My_Youtube_Subscriptions" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occured in Youtube_My_Subscriptions_Import.add_UnChecked event" -showtime -catcherror $_
          }
      }) 
      #---------------------------------------------- 
      #endregion Youtube_My_Subscriptions_Import_UnChecked
      #----------------------------------------------

      #---------------------------------------------- 
      #region Youtube_My_Subscriptions_Import_Button
      #----------------------------------------------
      $hashsetup.Youtube_My_Subscriptions_Import_Button.add_click({
          try{  
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = $hashsetup.Youtube_My_Subscriptions_Import.content

            update-EditorHelp -content "Check this if you also wish to import Youtube Channels you have Subscribed to on Youtube" -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "This needs to be documented with the help system...DID HE FORGET?!"  -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout  
          }catch{
            write-ezlogs "An exception occurred in Youtube_My_Subscriptions_Import_Button.add_click event" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Youtube_My_Subscriptions_Import_Button
      #----------------------------------------------  

      #---------------------------------------------- 
      #region Update_TwitchPlaylists_Timer
      #----------------------------------------------
      #$hashSetup.TwitchPlaylists_items = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
      $hashSetup.TwitchPlaylists_items = [System.Collections.Generic.List[Object]]::new()
      try{
        $hashsetup.Update_TwitchPlaylists_Timer = [System.Windows.Threading.DispatcherTimer]::new()
        $hashsetup.Update_TwitchPlaylists_Timer_ScriptBlock = {
          try{
            $hashsetup.TwitchPlaylists_Grid.Itemssource = $this.tag
            $this.stop()
          }catch{
            write-ezlogs "An exception occurred in Update_TwitchPlaylists_Timer" -showtime -catcherror $_
            $this.stop()
          }finally{
            $this.stop()
          }     
        }
        $hashsetup.Update_TwitchPlaylists_Timer.add_tick($hashsetup.Update_TwitchPlaylists_Timer_ScriptBlock)
      }catch{
        write-ezlogs "An exception occurred creating Update-TwitchPlaylists startup" -showtime -catcherror $_
      }
      #---------------------------------------------- 
      #endregion Update_TwitchPlaylists_Timer
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch Updates Toggle
      #----------------------------------------------
      $hashsetup.Twitch_Update_transitioningControl.content = ''
      $hashsetup.Twitch_Update_textblock.text = ''
      $hashsetup.Twitch_Update_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Twitch_Update = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Twitch_Update_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Twitch_Update_Toggle.add_Toggled($hashsetup.Twitch_Update_Toggle_Command)
      #---------------------------------------------- 
      #endregion Twitch Updates Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_Update_Interval_ComboBox
      #----------------------------------------------
      $hashsetup.Twitch_Update_Interval_ComboBox.add_SelectionChanged({
          Param($Sender)
          try{
            if($Sender.SelectedIndex -ne -1){    
              $hashsetup.Twitch_Update_Interval_Label.BorderBrush = 'Green'
              if($Sender.Selecteditem.Content -match 'Minutes'){
                $interval = [TimeSpan]::FromMinutes("$(($Sender.Selecteditem.Content -replace 'Minutes', '').trim())")
              }elseif($Sender.Selecteditem.Content -match 'Hour'){
                $interval = [TimeSpan]::FromHours("$(($Sender.Selecteditem.Content -replace 'Hour', '').trim())")
              }
              $thisapp.configTemp.Twitch_Update_Interval = $interval
              $hashsetup.Twitch_Update_textblock.text = ''
              $hashsetup.Twitch_Update_transitioningControl.content = ''
            }else{          
              $hashsetup.Twitch_Update_Interval_Label.BorderBrush = 'Red'
              $thisapp.configTemp.Twitch_Update_Interval = ''    
            }
          }catch{
            write-ezlogs "An exception occurred in Twitch_Update_Interval_ComboBox event" -CatchError $_ -showtime
          }
      }) 
      #---------------------------------------------- 
      #endregion Twitch_Update_Interval_ComboBox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch Updates Help
      #----------------------------------------------
      $hashsetup.Twitch_Update_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_AutoUpdate.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -clear -Header $hashsetup.Twitch_Update_Toggle.content            
          }catch{
            write-ezlogs "An exception occurred in Twitch_Update_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Twitch Updates Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_Twitch_Notifications Toggle
      #----------------------------------------------
      $hashsetup.Enable_Twitch_Notifications_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Enable_Twitch_Notifications = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_Twitch_Notifications_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Enable_Twitch_Notifications_Toggle.add_Toggled($hashsetup.Enable_Twitch_Notifications_Toggle_Command)
      #---------------------------------------------- 
      #endregion Enable_Twitch_Notifications Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Enable_Twitch_Notifications Help
      #----------------------------------------------
      $hashsetup.Enable_Twitch_Notifications_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Enable_Twitch_Notifications.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Enable_Twitch_Notifications_Toggle.Content -open -clear                  
          }catch{
            write-ezlogs "An exception occurred in Enable_Twitch_Notifications_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Enable_Twitch_Notifications Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region ForceUse_YTDLP Toggle
      #----------------------------------------------
      $hashsetup.ForceUse_YTDLP_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.ForceUse_YTDLP = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Enable_Twitch_Notifications_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.ForceUse_YTDLP_Toggle.add_Toggled($hashsetup.ForceUse_YTDLP_Toggle_Command)
      #---------------------------------------------- 
      #endregion ForceUse_YTDLP Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region ForceUse_YTDLP Help
      #----------------------------------------------
      $hashsetup.ForceUse_YTDLP_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\ForceUse_YTDLP.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.ForceUse_YTDLP_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in ForceUse_YTDLP_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion ForceUse_YTDLP Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Skip_Twitch_Ads_Toggle Toggle
      #----------------------------------------------
      $hashsetup.Skip_Twitch_Ads_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Skip_Twitch_Ads = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Skip_Twitch_Ads_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Skip_Twitch_Ads_Toggle.add_Toggled($hashsetup.Skip_Twitch_Ads_Toggle_Command)
      #---------------------------------------------- 
      #endregion Skip_Twitch_Ads_Toggle Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Skip_Twitch_Ads Help
      #----------------------------------------------
      $hashsetup.Skip_Twitch_Ads_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Skip_Twitch_Ads.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Skip_Twitch_Ads_Toggle.Content -open -clear                
          }catch{
            write-ezlogs "An exception occurred in Skip_Twitch_Ads_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Skip_Twitch_Ads Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Mute_Twitch_Ads_Toggle Toggle
      #----------------------------------------------
      $hashsetup.Mute_Twitch_Ads_Toggle_Command = {
        Param($sender)
        try{
          $thisapp.configTemp.Mute_Twitch_Ads = $sender.isOn
        }catch{
          write-ezlogs "An exception occurred in Skip_Twitch_Ads_Toggle.add_Toggled" -showtime -catcherror $_
        } 
      }
      $hashsetup.Mute_Twitch_Ads_Toggle.add_Toggled($hashsetup.Mute_Twitch_Ads_Toggle_Command)
      #---------------------------------------------- 
      #endregion Mute_Twitch_Ads_Toggle Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Mute_Twitch_Ads Help
      #----------------------------------------------
      $hashsetup.Mute_Twitch_Ads_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Mute_Twitch_Ads.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Mute_Twitch_Ads_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Mute_Twitch_Ads_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Mute_Twitch_Ads Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_TTVLOL_Toggle Toggle
      #----------------------------------------------
      $hashsetup.Twitch_TTVLOL_Toggle_Command = {
        Param($sender)
        try{
          $customTwitchPlugindst = "$env:appdata\streamlink\plugins\twitch.py"
          $customTwitchPluginsrc = "$($thisApp.Config.Current_Folder)\Resources\Streamlink\twitch.py"
          if($sender.isOn -eq $true){       
            write-ezlogs ">>>> Enabled Use_Twitch_TTVLOL" -LogLevel 2 -logtype Setup
            if($hashsetup.Twitch_luminous_Toggle.isOn){
              write-ezlogs " | Disabling Twitch_luminous_Toggle" -LogLevel 2 -logtype Setup
              $hashsetup.Twitch_luminous_Toggle.isOn = $false
            }
            if($hashsetup.Twitch_Custom_Proxy_Toggle.isOn){
              $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $false
            }
            if($thisapp.configTemp.UseTwitchCustom){
              $thisapp.configTemp.UseTwitchCustom = $false
            }
            if($thisapp.configTemp.Use_Twitch_luminous){
              $thisapp.configTemp.Use_Twitch_luminous = $false
            }
            try{
              if([system.io.file]::Exists($customTwitchPlugindst)){
                write-ezlogs " | Custom Twitch streamlink plugin already exits at $customTwitchPlugindst - overwriting" -LogLevel 2 -logtype Setup
                [void][system.io.file]::Copy($customTwitchPluginsrc,$customTwitchPlugindst,$true)
              }elseif([system.io.file]::Exists($customTwitchPluginsrc)){
                if(![system.io.directory]::Exists([system.io.directory]::GetParent($customTwitchPlugindst).fullname)){
                  write-ezlogs " | Creating Streamlink plugins directory: $env:appdata\streamlink\plugins" -LogLevel 2 -logtype Setup
                  [void][system.io.directory]::CreateDirectory("$env:appdata\streamlink\plugins")
                }
                write-ezlogs " | Copying custom Twitch streamlink plugin to $env:appdata\streamlink\plugins" -LogLevel 2 -logtype Setup
                [void][system.io.file]::Copy($customTwitchPluginsrc,$customTwitchPlugindst,$true)
              }
              $thisapp.configTemp.Use_Twitch_TTVLOL = $true
            }catch{
              write-ezlogs "An exception occurred attempting to enable Twitch_TTVLOL" -catcherror $_
              update-EditorHelp -content "An exception occurred attempting to enable Twitch_TTVLOL`n$($_.Exception | out-string)`n$($_.ScriptStackTrace | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Config ERROR' -clear -Open
              $error.clear()
              return
            }
          }
          else{     
            write-ezlogs "Disabled Use_Twitch_TTVLOL" -LogLevel 2 -logtype Setup   
            if(!$hashsetup.Twitch_luminous_Toggle.isOn){
              if([system.io.file]::Exists($customTwitchPlugindst)){ 
                try{        
                  if((Get-Process streamlink -ErrorAction SilentlyContinue)){
                    write-ezlogs " | Streamlink is currently running, it must be shutdown before disabling the TTVLOL Plugin" -warning -logtype Setup
                    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                    $Button_Settings.AffirmativeButtonText = 'Yes'
                    $Button_Settings.NegativeButtonText = 'No'  
                    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
                    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Streamlink WARNING","Streamlink (which is used to play Twitch streams) is currently running. It must be shutdown before disabling the TTVLOL Plugin. This will end any currently playing Twitch Streams.`nDo you want to close it now and continue?",$okandCancel,$Button_Settings)
                    if($result -eq 'Affirmative'){
                      write-ezlogs "User wished to continue, killing streamlink" -showtime -warning -logtype Setup
                      [void](Get-Process streamlink -ErrorAction SilentlyContinue) | Stop-Process -Force
                    }else{
                      write-ezlogs "User did not wish to continue" -showtime -warning -logtype Setup
                      return
                    }
                  }else{
                    write-ezlogs " | Removing custom Twitch streamlink plugin at $customTwitchPlugindst" -LogLevel 2 -logtype Setup
                    [void][system.io.file]::Delete($customTwitchPlugindst)
                  }                
                }catch{
                  write-ezlogs "An exception occurred attempting to disable Twitch_TTVLOL" -catcherror $_
                  update-EditorHelp -content "An exception occurred attempting to disable Twitch_TTVLOL. The setting will still be diabled, but the associated Streamlink Plugin files may still exist`n$($_.Exception | out-string)`n$($_.ScriptStackTrace | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Config ERROR' -clear -Open
                  $error.clear()
                }            
              }          
            }                
            Add-Member -InputObject $thisapp.configTemp -Name 'Use_Twitch_TTVLOL' -Value $false -MemberType NoteProperty -Force
          }
        }catch{
          write-ezlogs "An exception occurred in Twitch_TTVLOL_Toggle event" -CatchError $_ -showtime
        } 
      }
      $hashsetup.Twitch_TTVLOL_Toggle.add_Toggled($hashsetup.Twitch_TTVLOL_Toggle_Command)
      #---------------------------------------------- 
      #endregion Twitch_TTVLOL_Toggle Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_TTVLOL Help
      #----------------------------------------------
      $hashsetup.Twitch_TTVLOL_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_TTVLOL.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Twitch_TTVLOL_Toggle.Content -open -clear         
          }catch{
            write-ezlogs "An exception occurred in Twitch_TTVLOL_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Twitch_TTVLOL Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_luminous_Toggle
      #----------------------------------------------
      if($thisapp.config.Use_Twitch_luminous){
        $hashsetup.Twitch_luminous_Toggle.isOn = $true
        $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
        if($hashsetup.Twitch_Custom_Proxy_Toggle.isOn){
          $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $false 
        }
        if($thisapp.configTemp.UseTwitchCustom){
          $thisapp.configTemp.UseTwitchCustom = $false
        }
        if($thisapp.configTemp.Use_Twitch_TTVLOL){
          $thisapp.configTemp.Use_Twitch_TTVLOL = $false
        }
      }else{
        $hashsetup.Twitch_luminous_Toggle.isOn = $false
      }
      #---------------------------------------------- 
      #endregion Twitch_luminous_Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_luminous_Toggle Toggle
      #----------------------------------------------
      $hashsetup.Twitch_luminous_Toggle_Command = {
        Param($sender)
        try{
          $customTwitchPlugindst = "$env:appdata\streamlink\plugins\twitch.py"
          $customTwitchPluginsrc = "$($thisApp.Config.Current_Folder)\Resources\Streamlink\twitch.py"
          if($sender.isOn -eq $true){       
            write-ezlogs ">>>> Enabled Use_Twitch_luminous" -LogLevel 2 -logtype Setup
            if($hashsetup.Twitch_TTVLOL_Toggle.isOn){
              write-ezlogs " | Disabling Twitch_TTVLOL_Toggle" -LogLevel 2 -logtype Setup
              $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
              if($thisapp.configTemp.Use_Twitch_TTVLOL){
                $thisapp.configTemp.Use_Twitch_TTVLOL  =$false
              }
            }
            if($hashsetup.Twitch_Custom_Proxy_Toggle.isOn){
              $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $false
            }
            if($thisapp.configTemp.UseTwitchCustom){
              $thisapp.configTemp.UseTwitchCustom = $false
            }
            try{
              if([system.io.file]::Exists($customTwitchPlugindst)){
                write-ezlogs " | Custom Twitch streamlink plugin already exits at $customTwitchPlugindst - overwriting" -LogLevel 2 -logtype Setup
                [void][system.io.file]::Copy($customTwitchPluginsrc,$customTwitchPlugindst,$true)
              }elseif([system.io.file]::Exists($customTwitchPluginsrc)){
                if(![system.io.directory]::Exists([system.io.directory]::GetParent($customTwitchPlugindst).fullname)){
                  write-ezlogs " | Creating Streamlink plugins directory: $env:appdata\streamlink\plugins" -LogLevel 2 -logtype Setup
                  [void][system.io.directory]::CreateDirectory("$env:appdata\streamlink\plugins")
                }
                write-ezlogs " | Copying custom Twitch streamlink plugin to $env:appdata\streamlink\plugins" -LogLevel 2 -logtype Setup
                [void][system.io.file]::Copy($customTwitchPluginsrc,$customTwitchPlugindst,$true)
              }
              $thisapp.configTemp.Use_Twitch_luminous = $true
            }catch{
              write-ezlogs "An exception occurred attempting to enable Twitch_luminous" -catcherror $_
              update-EditorHelp -content "An exception occurred attempting to enable Twitch_luminous`n$($_.Exception | out-string)`n$($_.ScriptStackTrace | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Config ERROR' -clear -Open
              $error.clear()
              return
            }
          }
          else{     
            write-ezlogs "Disabled Use_Twitch_luminous" -LogLevel 2 -logtype Setup   
            if(!$hashsetup.Twitch_TTVLOL_Toggle.isOn){               
              if([system.io.file]::Exists($customTwitchPlugindst)){ 
                try{        
                  if((Get-Process streamlink -ErrorAction SilentlyContinue)){
                    write-ezlogs " | Streamlink is currently running, it must be shutdown before disabling the luminous Plugin" -warning -logtype Setup
                    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                    $Button_Settings.AffirmativeButtonText = 'Yes'
                    $Button_Settings.NegativeButtonText = 'No'  
                    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
                    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Streamlink WARNING","Streamlink (which is used to play Twitch streams) is currently running. It must be shutdown before disabling the luminous Plugin. This will end any currently playing Twitch Streams.`nDo you want to close it now and continue?",$okandCancel,$Button_Settings)
                    if($result -eq 'Affirmative'){
                      write-ezlogs "User wished to continue, killing streamlink" -showtime -warning -logtype Setup
                      [void](Get-Process streamlink -ErrorAction SilentlyContinue) | Stop-Process -Force
                    }else{
                      write-ezlogs "User did not wish to continue" -showtime -warning -logtype Setup
                      return
                    }
                  }else{
                    write-ezlogs " | Removing custom Twitch streamlink plugin at $customTwitchPlugindst" -LogLevel 2 -logtype Setup
                    [void][system.io.file]::Delete($customTwitchPlugindst)
                  }                
                }catch{
                  write-ezlogs "An exception occurred attempting to disable Twitch_luminous" -catcherror $_
                  update-EditorHelp -content "An exception occurred attempting to disable Twitch_luminous. The setting will still be diabled, but the associated Streamlink Plugin files may still exist`n$($_.Exception | out-string)`n$($_.ScriptStackTrace | out-string)" -color Tomato -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Config ERROR' -clear -Open
                  $error.clear()
                }            
              }
            }
            Add-Member -InputObject $thisapp.configTemp -Name 'Use_Twitch_luminous' -Value $false -MemberType NoteProperty -Force
          }
        }catch{
          write-ezlogs "An exception occurred in Twitch_luminous_Toggle event" -CatchError $_ -showtime
        }
      }
      $hashsetup.Twitch_luminous_Toggle.add_Toggled($hashsetup.Twitch_luminous_Toggle_Command)
      #---------------------------------------------- 
      #endregion Twitch_luminous_Toggle Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_luminous Help
      #----------------------------------------------
      $hashsetup.Twitch_luminous_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_luminous.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Twitch_luminous_Toggle.Content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Twitch_luminous_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Twitch_luminous Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch Custom Playlists Proxy 
      #---------------------------------------------- 
      if($thisApp.Config.TwitchProxies.count -eq 0){
        $thisApp.Config.TwitchProxies = [System.Collections.ArrayList]::new()
      }
      if($hashsetup.Twitch_Custom_Proxy_Grid.items){
        [void]$hashsetup.Twitch_Custom_Proxy_Grid.items.clear()
      }
      if($thisApp.config.UseTwitchCustom){
        $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $true
        if($hashsetup.Twitch_luminous_Toggle.isOn){
          $hashsetup.Twitch_luminous_Toggle.isOn = $false
        }
        if($thisapp.configTemp.Use_Twitch_luminous){
          $thisapp.configTemp.Use_Twitch_luminous = $false
        }
        if($hashsetup.Twitch_TTVLOL_Toggle.isOn){
          $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
        }
        if($thisapp.configTemp.Use_Twitch_TTVLOL){
          $thisapp.configTemp.Use_Twitch_TTVLOL = $false
        }
        $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
        $thisApp.Config.TwitchProxies | & { process {
            [void]$hashsetup.Twitch_Custom_Proxy_Grid.items.add([PSCustomObject]@{
                Number=[int]$($thisApp.Config.TwitchProxies.IndexOf($_))
                URL=$_
            })
        }}
      }else{
        $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $false
      }
      #---------------------------------------------- 
      #endregion Twitch Custom Playlists Proxy
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Twitch_Custom_Proxy_Toggle Toggle
      #----------------------------------------------
      $hashsetup.Twitch_Custom_Proxy_Toggle_Command = {
        Param($sender)
        try{
          if($sender.isOn -eq $true){
            write-ezlogs ">>>> Enabled Twitch_Custom_Proxy" -LogLevel 2 -logtype Setup
            $thisApp.configTemp.UseTwitchCustom = $true
            if($hashsetup.Twitch_luminous_Toggle.isOn){
              $hashsetup.Twitch_luminous_Toggle.isOn = $false
            }
            if($thisapp.configTemp.Use_Twitch_luminous){
              $thisapp.configTemp.Use_Twitch_luminous = $false
            }
            if($hashsetup.Twitch_TTVLOL_Toggle.isOn){
              $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
            }
            if($thisapp.configTemp.Use_Twitch_TTVLOL){
              $thisapp.configTemp.Use_Twitch_TTVLOL = $false
            }
          }else{     
            write-ezlogs "Disabled Twitch_Custom_Proxy" -LogLevel 2 -logtype Setup                   
            $thisApp.configTemp.UseTwitchCustom = $false
          }
        }catch{
          write-ezlogs "An exception occurred in Twitch_Custom_Proxy_Toggle event" -CatchError $_ -showtime
        } 
      }
      $hashsetup.Twitch_Custom_Proxy_Toggle.add_Toggled($hashsetup.Twitch_Custom_Proxy_Toggle_Command)
      #---------------------------------------------- 
      #endregion Twitch_Custom_Proxy_Toggle Toggle
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_Custom_Proxy Help
      #----------------------------------------------
      $hashsetup.Twitch_Custom_Proxy_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_Custom_Proxy.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Twitch_Custom_Proxy_Toggle.Content -open -clear        
          }catch{
            write-ezlogs "An exception occurred in Twitch_Custom_Proxy_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Twitch_Custom_Proxy Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_Quality Help
      #----------------------------------------------
      $hashsetup.Twitch_Quality_Button.add_Click({
          try{       
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_Stream_Quality.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Twitch_Quality_Label.content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Skip_Twitch_Ads_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Twitch_Quality Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_Quality Combobox
      #----------------------------------------------
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('Best')
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('1080p')
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('720p')
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('480p')
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('Worst')
      [void]$hashsetup.Twitch_Quality_ComboBox.items.add('audio_only')     
      $hashsetup.Twitch_Quality_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Twitch_Quality_ComboBox.Selectedindex -ne -1){   
              if($hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'Best' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '1080p' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '720p'){
                $hashsetup.Twitch_Quality_Label.BorderBrush = 'LightGreen'
              }elseif($hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '480p' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'Worst' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'audio_only'){
                $hashsetup.Twitch_Quality_Label.BorderBrush = 'Gray'
              }else{
                $hashsetup.Twitch_Quality_Label.BorderBrush = 'Red'
              }   
              Add-Member -InputObject $thisapp.configTemp -Name 'Twitch_Quality' -Value $($hashsetup.Twitch_Quality_ComboBox.selecteditem) -MemberType NoteProperty -Force
            }
            else{       
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'LightGreen'   
              Add-Member -InputObject $thisapp.configTemp -Name 'Twitch_Quality' -Value 'Best' -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in Twitch_Quality_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Twitch_Quality Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Interface Help
      #----------------------------------------------
      $hashsetup.Streamlink_Interface_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Streamlink_Interface.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Streamlink_Interface_Label.content -open -clear
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Interface_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Streamlink_Interface Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Interface Combobox
      #----------------------------------------------
      $hashsetup.Streamlink_Interface_ComboBox.add_SelectionChanged({
          try{
            if($hashsetup.Streamlink_Interface_ComboBox.Selectedindex -ne -1){     
              Add-Member -InputObject $thisapp.configTemp -Name 'Streamlink_Interface' -Value $($hashsetup.Streamlink_Interface_ComboBox.selecteditem) -MemberType NoteProperty -Force
            }
            else{         
              Add-Member -InputObject $thisapp.configTemp -Name 'Streamlink_Interface' -Value 'Any' -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Interface_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Streamlink_Interface Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Arguments_textbox
      #----------------------------------------------
      $hashsetup.Streamlink_Arguments_textbox.add_textChanged({
          try{
            if(-not [string]::IsNullOrEmpty($this.text)){   
              $hashsetup.Streamlink_Arguments_Label.BorderBrush = 'LightGreen' 
              Add-Member -InputObject $thisapp.configTemp -Name 'Streamlink_Arguments' -Value $($this.text) -MemberType NoteProperty -Force
            }
            else{       
              $hashsetup.Streamlink_Arguments_Label.BorderBrush = 'Red'   
              Add-Member -InputObject $thisapp.configTemp -Name 'Streamlink_Arguments' -Value $null -MemberType NoteProperty -Force     
            }
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Arguments_textbox.add_textChanged" -CatchError $_ -enablelogs
          }
      }) 
 
      #---------------------------------------------- 
      #endregion Streamlink_Arguments_textbox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Arguments Help
      #TODO: Refactor to use new MD format
      #----------------------------------------------
      $hashsetup.Streamlink_Arguments_HelpButton.add_Click({
          try{
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = $hashsetup.Streamlink_Arguments_Label.content
            update-EditorHelp -content "Allows providing additional command-line arguments to pass to streamlink when fetching Twitch streams. Use a comma-separated list when providing multiple arguments" -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "This should only be used by those who understand exactly how these options will work and effect streamlink behaviour" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout   
            update-EditorHelp -content "Not all options are guaranteed to work, and some may be overridden by this app to ensure functionality is not compromised." -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "INFO" -FontWeight bold -color cyan -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
            update-EditorHelp -content "To review available arguments and how they are used, refer to streamlink documentation: https://streamlink.github.io/cli.html#command-line-interface" -color cyan -RichTextBoxControl $hashsetup.EditorHelpFlyout                           
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Arguments_HelpButton.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Streamlink_Arguments Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Logging Help
      #----------------------------------------------
      $hashsetup.Streamlink_Logging_Button.add_Click({
          try{
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Streamlink_Logging.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -header $hashsetup.Streamlink_Logging_Label.content -open -clear             
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Logging_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Streamlink_Logging Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Streamlink_Logging Combobox
      #----------------------------------------------
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('info')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('warning')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('error')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('debug')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('trace')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('all')
      [void]$hashsetup.Streamlink_Logging_ComboBox.items.add('none')
      $hashsetup.Streamlink_Logging_ComboBox.add_SelectionChanged({
          Param($Sender)
          try{
            if($Sender.Selectedindex -ne -1){   
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'LightGreen'  
              $thisapp.configTemp.Streamlink_Verbose_logging = $Sender.selecteditem
            }else{       
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'LightGreen'   
              $thisapp.configTemp.Streamlink_Verbose_logging = 'info'
            }
          }catch{
            write-ezlogs "An exception occurred in Streamlink_Logging_ComboBox.add_SelectionChanged" -CatchError $_ -enablelogs
          }
      }) 
      #---------------------------------------------- 
      #endregion Streamlink_Logging Combobox
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_AuthHandler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Twitch_AuthHandler = {
        param ($sender,$e)
        if($sender.NavigateUri -match 'Twitch_Auth'){
          try{
            <#            if([System.IO.Directory]::Exists("$($thisApp.Config.Temp_Folder)\Setup_Webview2")){   
                try{
                write-ezlogs ">>>> Removing existing Webview2 cache $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -color cyan -logtype Setup -LogLevel 2
                [void][System.IO.Directory]::Delete("$($thisApp.Config.Temp_Folder)\Setup_Webview2",$true)
                }catch{
                write-ezlogs "An exception occurred attempting to remove $($thisApp.Config.Temp_Folder)\Setup_Webview2" -showtime -catcherror $_
                }
            }#>
            try{
              $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
            }
            write-ezlogs "Removing stored Twitch authentication secrets from vault" -showtime -warning -logtype Setup
            if($secretstore){  
              try{
                [void](Remove-secret -name Twitchaccess_token -Vault $thisApp.config.App_Name -ErrorAction SilentlyContinue)
              }catch{
                write-ezlogs "An exception occurred removing Secret TwitchAccessToken" -showtime -catcherror $_
              }
              try{
                [void](Remove-secret -name Twitchexpires -Vault $thisApp.config.App_Name -ErrorAction SilentlyContinue)
              }catch{
                write-ezlogs "An exception occurred removing Secret Twitchexpires_in" -showtime -catcherror $_
              }   
              try{
                [void](Remove-secret -name Twitchrefresh_token -Vault $thisApp.config.App_Name -ErrorAction SilentlyContinue)
              }catch{
                write-ezlogs "An exception occurred removing Secret Twitchrefresh_token" -showtime -catcherror $_
              }                    
            }
            try{
              write-ezlogs ">>> Verifying Twitch authentication" -showtime -logtype Setup -LogLevel 2
              $Twitchaccess_token = Get-TwitchAccessToken -thisApp $thisApp -ApplicationName $thisApp.Config.App_Name -Verboselog 
              #$Twitchaccess_token = Get-secret -name TwitchAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
              $Twitchrefresh_access_token = Get-secret -name Twitchrefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred getting Secret TwitchAccessToken" -showtime -catcherror $_
            } 
            if($Twitchaccess_token -and $Twitchrefresh_access_token){
              Invoke-TwitchImport -thisApp $thisApp -hashsetup $hashsetup
              write-ezlogs "Authenticated to Twitch and retrieved access tokens" -showtime -color green -logtype Setup -LogLevel 2 -Success
              $hashsetup.Twitch_Playlists_Import.isEnabled = $true
              $hashsetup.Import_Twitch_transitioningControl.Height = '0'
              #$hashsetup.Import_Twitch_transitioningControl.content = ''
              $hashsetup.Import_Twitch_textbox.text = ''
              if($MahDialog_hash.window.Dispatcher -and $MahDialog_hash.window.isVisible){
                $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
              }
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              } 
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Twitch'            
              update-EditorHelp -content "[SUCCESS] Authenticated to Twitch and saved access tokens into the Secret Vault! Any followed channels have been imported automatically. You can always refresh or manually add more channels" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout     
              if(!$hashsetup.Window.isVisible){
                $hashsetup.Window.Show()
              } 
              return                                   
            }else{
              write-ezlogs "[Show-SettingsWindow] Unable to successfully authenticate to Twitch!" -showtime -warning -logtype Setup
              $hashsetup.Twitch_Playlists_Import.isEnabled = $false
              $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $false
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              }        
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Twitch'            
              update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Twitch! Some Twitch features may be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
              if(!$hashsetup.Window.isVisible){
                $hashsetup.Window.Show()
              }
              return              
            }          
          }catch{
            write-ezlogs "An exception occurred in Twitch_AuthHandler routed event" -showtime -catcherror $_
          }         
        }     
      } 
      #---------------------------------------------- 
      #endregion Twitch_AuthHandler
      #----------------------------------------------    

      #---------------------------------------------- 
      #region Twitch_ImportHandler
      #----------------------------------------------     
      [System.Windows.RoutedEventHandler]$Twitch_ImportHandler = {
        param ($sender,$e)
        try{
          Invoke-TwitchImport -thisApp $thisApp -hashsetup $hashsetup         
        }catch{
          write-ezlogs "An exception occurred in Twitch_ImportHandler routed event" -showtime -catcherror $_
        }             
      } 
      [void]$hashsetup.Twitch_Playlists_Import.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Twitch_ImportHandler) 
      #---------------------------------------------- 
      #endregion Twitch_ImportHandler
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Twitch_Playlists_Toggle
      #----------------------------------------------
      $hashsetup.Import_Twitch_Playlists_Toggle_Command = {
        Param($sender)
        try{
          if($this.tag -ne 'Startup'){
            if($hashsetup.Import_Twitch_Playlists_Toggle.isOn){     
              $hashsetup.Twitch_Playlists_Browse.IsEnabled = $true
              $hashsetup.TwitchPlaylists_Grid.IsEnabled = $true   
              $hashsetup.TwitchPlaylists_Grid.MaxHeight = '250'     
              $thisapp.configTemp.Import_Twitch_Media = $true
              $TwitchApp = Get-TwitchApplication -Name $($thisApp.Config.App_name)
              if(([string]::IsNullOrEmpty($TwitchApp.token.access_token) -or [string]::IsNullOrEmpty($TwitchApp.token.expires))){
                $hyperlink = 'https://Twitch_Auth'
                write-ezlogs "No Twitch authentication returned (Expires: $($TwitchApp.token.access_token)) (Expires: $($TwitchApp.token.expires))" -warning -logtype Setup
                $hashsetup.Import_Twitch_textbox.isEnabled = $true
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"    
                $hashsetup.Import_Twitch_Status_textbox.Text="[NONE]"
                $hashsetup.Import_Twitch_Status_textbox.Foreground = "Orange"
                $hashsetup.Import_Twitch_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add(" to provide your Twitch account credentials")   
                $hashsetup.Import_Twitch_textbox.Foreground = "Orange"
                $hashsetup.Import_Twitch_textbox.FontSize = '14'
                $hashsetup.Import_Twitch_transitioningControl.Height = '80'
              }else{
                write-ezlogs "[SUCCESS] Returned Twitch authentication (Expires: $($TwitchApp.token.expires))" -showtime -logtype Setup -LogLevel 2
                $hashsetup.Import_Twitch_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Twitch_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Twitch_textbox.isEnabled = $true
                $hyperlink = 'https://Twitch_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add("If you wish to update/change your Twitch credentials, click ")  
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
                $hashsetup.Import_Twitch_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Twitch_textbox.FontSize = '14'
                $hashsetup.Import_Twitch_transitioningControl.Height = '60'
                $hashsetup.Twitch_Playlists_Import.isEnabled = $true
                $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $true
              }                                       
            }else{
              $hashsetup.Twitch_Playlists_Browse.IsEnabled = $false
              $hashsetup.TwitchPlaylists_Grid.IsEnabled = $false       
              $hashsetup.TwitchPlaylists_Grid.MaxHeight = '0'
              Add-Member -InputObject $thisapp.configTemp -Name "Import_Twitch_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
              $hashsetup.Import_Twitch_textbox.text = ""
              $hashsetup.Import_Twitch_transitioningControl.Height = '0'
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Import_Twitch_Playlists_Toggle.add_Toggled" -showtime -catcherror $_
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }                  
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Import Twitch'            
          update-EditorHelp -content "[ERROR] An exception occurred in Import_Twitch_Playlists Toggle Event`n$($_ | out-string)" -color red -FontWeight Bold  -RichTextBoxControl $hashsetup.EditorHelpFlyout  
        }finally{
          $this.tag = $Null
        }
      }
      $hashsetup.Import_Twitch_Playlists_Toggle.add_Toggled($hashsetup.Import_Twitch_Playlists_Toggle_Command)
      #---------------------------------------------- 
      #endregion Import_Twitch_Playlists_Toggle
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Twitch_Playlists_Button
      #---------------------------------------------- 
      $hashsetup.Import_Twitch_Playlists_Button.add_click({
          try{  
            update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Twitch_Integration.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header $hashsetup.Import_Twitch_Playlists_Toggle.content -clear
          }catch{
            write-ezlogs "An exception occurred when opening main UI window" -CatchError $_
          }

      })  
      #---------------------------------------------- 
      #endregion Import_Twitch_Playlists_Button
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Import_Twitch_Status_Button
      #----------------------------------------------
      $hashsetup.Import_Twitch_Status_Button_Command = {
        Param($sender)
        try{
          update-EditorHelp -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Setup\API_Authentication_Setup.md" -MarkDownControl $hashsetup.MarkdownScrollViewer -open -Header 'API Credential Setup Instructions' -clear
        }catch{
          write-ezlogs "An exception occurred in Import_Twitch_Status_Button click event" -showtime -catcherror $_
        }
      }
      $hashsetup.Import_Twitch_Status_Button.add_click($hashsetup.Import_Twitch_Status_Button_Command)
      #---------------------------------------------- 
      #endregion Import_Twitch_Status_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Twitch_Playlists_Browse
      #----------------------------------------------
      $hashsetup.Twitch_Playlists_Browse.add_click({  
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Twitch URL","Enter the url of the Twitch Channel or Stream",$button_settings)
          if(-not [string]::IsNullOrEmpty($result)){
            if((Test-URL $result) -and ($result -match 'twitch.tv' -or $result -match 'twitch')){
              $id = $((Get-Culture).textinfo.totitlecase(($result | split-path -leaf).tolower())) 
              if($hashsetup.TwitchPlaylists_Grid.items.path -notcontains $result){           
                $Name = $id
                $type = 'TwitchChannel'
                write-ezlogs "Adding Twitch URL $result" -showtime -logtype Setup -LogLevel 2 
                Update-TwitchPlaylists -hashsetup $hashsetup -Path $result -id $id -Name $Name -type $type -VerboseLog:$thisApp.Config.Verbose_logging -SetItemsSource
              }else{
                write-ezlogs "The location $result ($id) has already been added!" -showtime -warning -logtype Setup
                update-EditorHelp -content "Twitch Channel ($id) has already been added!" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Channel' -clear -Open 
              } 
            }else{
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Twitch Channels'            
              update-EditorHelp -content "[WARNING] Invalid URL Provided" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear
              update-EditorHelp -content "The location $result is not a valid URL! Please ensure the URL is a valid Twitch URL" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout     
              write-ezlogs "The location $result is not a valid URL!" -showtime -warning -logtype Setup
            }
          }else{
            write-ezlogs "No URL was provided!" -showtime -warning -logtype Setup
          } 
      })
      #---------------------------------------------- 
      #endregion Twitch_Playlists_Browse
      #----------------------------------------------

      #---------------------------------------------- 
      #region Apply Settings Button
      #----------------------------------------------
      try{
        #Next Button
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\OptionButton.png") 
        $OptionButton = [System.Windows.Media.Imaging.BitmapImage]::new()
        $OptionButton.BeginInit()
        $OptionButton.CacheOption = "OnLoad"
        $OptionButton.DecodePixelWidth = "64"
        $OptionButton.StreamSource = $stream_image
        $OptionButton.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $OptionButton.Freeze()
        $hashsetup.Next_Button_Image.Source = $OptionButton
        #Save Button
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png") 
        $SaveButton = [System.Windows.Media.Imaging.BitmapImage]::new()
        $SaveButton.BeginInit()
        $SaveButton.CacheOption = "OnLoad"
        $SaveButton.DecodePixelWidth = "86"
        $SaveButton.StreamSource = $stream_image
        $SaveButton.EndInit() 
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        $SaveButton.Freeze()
        $hashsetup.Save_Setup_Button_Image.Source = $SaveButton
      }catch{
        write-ezlogs "An exception occurred setting images for Next and Save buttons" -catcherror $_
      }
      [System.Windows.RoutedEventHandler]$hashsetup.Save_Setup_Button_Click_Command = {
        param ($sender)
        try{   
          #TODO: Put into function
          $hashsetup = $hashsetup
          $thisApp = $thisApp
          $First_Run = $First_Run
          $PlaylistRebuild_Required = $PlaylistRebuild_Required
          $hashsetup.Save_Setup_Button_clicked = $true
          $hashsetup.Save_setup_textblock.text = ""
          $hashsetup.Update_LocalMedia_Sources = $false
          $thisApp.config = $thisapp.configTemp.psobject.copy()
          $thisapp.configTemp = $Null
          #Check for existing custom playlists
          $playlist_pattern = [regex]::new('$(?<=((?i)Playlist.xml))')
          if($First_Run -and ([System.IO.Directory]::Exists($thisApp.config.Playlist_Profile_Directory)) -and $PlaylistRebuild_Required){
            $existing_playlists = Find-FilesFast -Path $thisApp.config.Playlist_Profile_Directory -Recurse -Filter $playlist_pattern 
            if($existing_playlists){
              write-ezlogs " | Prompting user to decide whether to delete existing playlists for first run as this version requires rebuilding them" -showtime -enablelogs -color cyan -logtype Setup -LogLevel 2
              if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Playlists_Confirmation.txt")){
                $PlaylistsConfirmation = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Playlists_Confirmation.txt")
              }   
              $PlaylistsConfirmation += "`n`nPlaylists effected`n: $($existing_playlists.FileName | out-string)"
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_settings.AffirmativeButtonText = "Yes"
              $Button_settings.NegativeButtonText = "No"  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Keep Playlists?",$PlaylistsConfirmation,$okAndCancel,$button_settings)
              if($result -eq 'Affirmative'){
                write-ezlogs "User wished to keep existing playlist profiles" -showtime -warning -logtype Setup
              }else{
                write-ezlogs " | Clearing playlist profile directory $($thisApp.config.Playlist_Profile_Directory)" -showtime -logtype Setup
                [void][System.IO.Directory]::Delete($thisApp.config.Playlist_Profile_Directory,$true)
              }
            }else{
              write-ezlogs "No existing playlists found, continuing" -showtime -logtype Setup
            }
          }elseif($First_Run){
            write-ezlogs " | Prompting to confirm if user is sure they are finished" -logtype Setup
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_settings.AffirmativeButtonText = "Yes"
            $Button_settings.NegativeButtonText = "No"  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Setup_Confirmation.txt")){
              $SetupConfirmation = [system.io.file]::ReadAllText("$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Setup_Confirmation.txt")
            }
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Complete Setup?",$SetupConfirmation,$okAndCancel,$button_settings)
            if($result -eq 'Affirmative'){
              write-ezlogs ">>>> User indicated they are finished and ready to continue setup" -showtime -logtype Setup
            }else{
              write-ezlogs "User indicated they are not finished" -showtime -logtype Setup -warning  
              return
            }
          }
          #region Start on Windows Login
          if($hashsetup.Start_On_Windows_Login_Toggle.isOn){
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
            $Main_exe = [System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).exe")         
            if([System.IO.Directory]::Exists($install_folder)){
              if([System.IO.File]::Exists($Main_exe)){
                $thisapp.config.Start_On_Windows_Login = $true
                $thisapp.config.App_Exe_Path = $Main_exe    
                if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                  write-ezlogs "The app $($thisApp.Config.App_Name) is already configured to start on Windows logon." -logtype Setup -loglevel 2          
                }else{
                  try{
                    New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Value $Main_exe -Force -ErrorAction SilentlyContinue
                    if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                      write-ezlogs "The app $($thisApp.Config.App_Name) has been successfully configured to start automatically upon logon to Windows (current user)" -logtype Setup -LogLevel 2 -Success              
                    }else{
                      write-ezlogs "Unable to verify if $($thisApp.Config.App_Name) was successfully configured to start automatically upon logon to Windows (current user) - List of current user Run reg entries $((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') | out-string)" -Warning -showtime -logtype Setup               
                    }            
                  }catch{
                    write-ezlogs "An exception occurred attempting to create startup entry for exe path $($Main_exe)" -CatchError $_ -showtime
                    $thisapp.config.Start_On_Windows_Login = $false
                    $hashsetup.Start_On_Windows_Login_Toggle.isOn = $false
                    update-EditorHelp -content "An exception occurred attempting to create startup entry for exe path $($Main_exe)" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -Header 'SAVE CONFIG WARNING'
                    return              
                  }
                }
              }else{         
                $thisapp.config.Start_On_Windows_Login = $false
                $hashsetup.Start_On_Windows_Login_Toggle.isOn = $false
                write-ezlogs "Could not find main exe file for $($thisApp.Config.App_Name) in folder ($install_folder). Installation may be corrupt! Please re-install the latest version of $($thisApp.Config.App_Name)" -Warning  -showtime -logtype Setup 
                update-EditorHelp -content "Could not find main exe file for $($thisApp.Config.App_Name) in folder ($install_folder).`n`nInstallation may be corrupt! Please re-install the latest version of $($thisApp.Config.App_Name)" -color tomato -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -Header 'SAVE CONFIG ERROR'
                if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                  try{ 
                    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force
                    write-ezlogs "Removed app $($thisApp.Config.App_Name) from starting on Windows logon." -color cyan  -showtime -logtype Setup -LogLevel 2          
                  }catch{
                    write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_ -showtime
                  }
                }
                return                    
              }
              write-ezlogs ">>>> Saving App Exe Path setting $($thisapp.config.App_Exe_Path)" -color cyan -showtime -logtype Setup
              write-ezlogs ">>>> Saving setting '$($hashsetup.Start_On_Windows_Login_Toggle.content) - $($thisapp.config.Start_On_Windows_Login)' " -color cyan -showtime -logtype Setup
            }else{
              write-ezlogs "Could not find app install folder ($install_folder). Installation may be corrupt! Please re-install the latest version of $($thisApp.Config.App_Name)" -Warning  -showtime -logtype Setup 
              $thisapp.config.Start_On_Windows_Login = $false     
              update-EditorHelp -content "Could not find app install folder ($install_folder).`n`nInstallation may be corrupt! Please re-install the latest version of $($thisApp.Config.App_Name) using the setup installer. Otherwise, disable the start on windows login option" -color tomato -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open -clear -Header 'CONFIG ERROR - Start On Windows Login'
              if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
                try{ 
                  Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force
                  $thisapp.config.Start_On_Windows_Login = $false
                  write-ezlogs "Removed app $($thisApp.Config.App_Name) from starting on Windows logon." -color cyan  -showtime -logtype Setup -LogLevel 2          
                }catch{
                  write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_ -showtime
                  $hashsetup.Start_On_Windows_Login_Toggle.isOn = $false       
                }
              }
              return        
            }
          }else{
            if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisApp.Config.App_Name)")){
              try{
                Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisApp.Config.App_Name) -Force -ErrorAction SilentlyContinue
                $thisapp.config.Start_On_Windows_Login = $false
                write-ezlogs "Removed app $($thisApp.Config.App_Name) from starting on Windows logon." -showtime -logtype Setup -LogLevel 2 -Success          
              }catch{
                write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name)" -CatchError $_ -showtime
                update-EditorHelp -content "[WARNING] An exception occurred attempting to remove startup entry for: $($thisApp.Config.App_Name) -- Start on windows login is disabled. See logs for details" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout  -Header 'Setup ERROR!' -clear -Open  
                $hashsetup.Start_On_Windows_Login_Toggle.isOn = $false
                return      
              }
            }else{
              write-ezlogs "The app $($thisApp.Config.App_Name) is not configured to start on Windows logon." -enablelogs -showtime -logtype Setup -LogLevel 2 
              $hashsetup.Start_On_Windows_Login_Toggle.isOn = $false
            }
            $thisapp.config.Start_On_Windows_Login = $false
            write-ezlogs ">>>> Saving setting '$($hashsetup.Start_On_Windows_Login_Toggle.content) - $($thisapp.config.Start_On_Windows_Login)' "  -color cyan -showtime -logtype Setup -LogLevel 2 
          }
          #endregion Start on Windows Login

          #region High DPI Mode
          if(!$hashsetup.High_DPI_Toggle.isOn -and [System.IO.Directory]::Exists($thisapp.config.App_Exe_Path)){
            try{ 
              $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
              $keys = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\")
              $Keyname = $keys.GetValueNames() | & { process {
                  if($_ -eq $thisapp.config.App_Exe_Path -or $_ -match "$($thisApp.Config.App_Name).exe"){
                    $_
                  }
              }}
              if($Keyname){
                write-ezlogs ">>>> Removing High DPI registry key: $Keyname" -logtype Setup
                $null = Remove-ItemProperty -Path 'Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\' -Name $Keyname -Force -ErrorAction SilentlyContinue
              }
            }catch{
              write-ezlogs "An exception occurred checking for or removing high DPI registry key for process: $($thisApp.Config.App_Name)" -CatchError $_
            }finally{
              if($Registry -is [System.IDisposable]){
                $Registry.dispose()
              }
              if($keys -is [System.IDisposable]){
                $keys.dispose()
              }
            } 
          }
          #endregion High DPI Mode

          #region Require 1 media type
          if(!$hashsetup.Import_Local_Media_Toggle.isOn -and !$hashsetup.Import_Youtube_Playlists_Toggle.isOn -and !$hashsetup.Import_Spotify_Playlists_Toggle){
            write-ezlogs "At least 1 Media type to import was not selected! (Local Media, Spotify, or Youtube)" -showtime -warning -logtype Setup  
            update-EditorHelp -content "[WARNING] You must enable at least 1 Media type to import in order to continue! (Local Media, Spotify, Youtube, or Twitch)" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout  -Header 'Requirements Missing!' -clear -Open                                               
            return
          }
          #endregion Require 1 media type

          #region Dev Mode
          $thisapp.config.Dev_mode = $($hashsetup.Verbose_logging_Toggle.isOn -eq $true)
          #endregion Dev Mode

          #region Audio Output
          try{
            if($hashsetup.Audio_Output_ComboBox.Selectedindex -ne -1){  
              if($synchash.vlc){
                $devices = ($synchash.vlc.AudioOutputDeviceEnum | Where-Object {$_.Description}).clone()
                $selecteddevice = $devices | Where-Object {$_.Description -eq $hashsetup.Audio_Output_ComboBox.selecteditem}
              }                       
              if($synchash.vlc.AudioOutputDeviceEnum -and $selecteddevice){
                write-ezlogs ">>>> Selected Audio Device for change $($selecteddevice)" -showtime -logtype Setup
                $synchash.window.Dispatcher.Invoke("Normal",[action]{ 
                    $synchash.vlc.SetOutputDevice($selecteddevice.deviceidentifier)
                })
              }
              $thisapp.config.Current_Audio_Output = $hashsetup.Audio_Output_ComboBox.selecteditem
            }else{     
              if($synchash.vlc.AudioOutputDeviceEnum){
                $device = $synchash.vlc.AudioOutputDeviceEnum | Where-Object {$_.Description -eq 'Default'}   
              }
              if($synchash.vlc.AudioOutputDeviceEnum -and $device){
                write-ezlogs ">>>> Selected Default Audio Device for change $($device)" -showtime -logtype Setup
                $synchash.window.Dispatcher.Invoke("Normal",[action]{ 
                    $synchash.vlc.SetOutputDevice($device.deviceidentifier)      
                })
              }
              $thisapp.config.Current_Audio_Output = 'Default'
            }
          }catch{
            write-ezlogs "An exception occurred in setting/saving audio output" -CatchError $_ -enablelogs
          }
          #endregion Audio Output


          #---------------------------------------------- 
          #region TODO:Media Control Hotkeys
          #----------------------------------------------
          try{
            if($HashSetup.VolUpHotkey.Hotkey -is [MahApps.Metro.Controls.HotKey] -and $HashSetup.VolUpHotkey.text){
              if($thisApp.Config.GlobalHotKeys.Name -notcontains 'VolUphotkey'){
                $Hotkey = [GlobalHotKey]::New()
                [void]$thisApp.Config.GlobalHotKeys.add($Hotkey)
              }else{
                $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolUphotkey'}
              }
              if($Hotkey.Name -ne 'VolUphotkey'){
                $Hotkey.Name = 'VolUphotkey'
              }
              if($Hotkey.Modifier -ne $HashSetup.VolUpHotkey.Hotkey.ModifierKeys){
                $Hotkey.Modifier = $HashSetup.VolUpHotkey.Hotkey.ModifierKeys
              }
              if($Hotkey.Key -ne $HashSetup.VolUpHotkey.Hotkey.Key){
                $Hotkey.Key = $HashSetup.VolUpHotkey.Hotkey.Key
              }
            }elseif($thisApp.Config.GlobalHotKeys.Name -contains 'VolUphotkey'){
              write-ezlogs "| Removing VolUphotkey from GlobalHotkeys"
              $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolUphotkey'}
              [void]$thisApp.Config.GlobalHotKeys.Remove($Hotkey)
            }
          }catch{
            write-ezlogs "An exception occurred saving VolUphotkey global hotkey" -CatchError $_       
          }
          try{
            if($HashSetup.VolDownhotkey.Hotkey -is [MahApps.Metro.Controls.HotKey] -and $HashSetup.VolDownhotkey.text){
              if($thisApp.Config.GlobalHotKeys.Name -notcontains 'VolDownhotkey'){
                $Hotkey = [GlobalHotKey]::New()
                [void]$thisApp.Config.GlobalHotKeys.add($Hotkey)
              }else{
                $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolDownhotkey'}
              }
              if($Hotkey.Name -ne 'VolDownhotkey'){
                $Hotkey.Name = 'VolDownhotkey'
              }
              if($Hotkey.Modifier -ne $HashSetup.VolDownhotkey.Hotkey.ModifierKeys){
                $Hotkey.Modifier = $HashSetup.VolDownhotkey.Hotkey.ModifierKeys
              }
              if($Hotkey.Key -ne $HashSetup.VolDownhotkey.Hotkey.Key){
                $Hotkey.Key = $HashSetup.VolDownhotkey.Hotkey.Key
              }
            }elseif($thisApp.Config.GlobalHotKeys.Name -contains 'VolDownhotkey'){
              write-ezlogs "| Removing VolDownhotkey from GlobalHotkeys"
              $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolDownhotkey'}
              [void]$thisApp.Config.GlobalHotKeys.Remove($Hotkey)
            }
          }catch{
            write-ezlogs "An exception occurred saving VolDownhotkey global hotkey" -CatchError $_       
          }
          try{
            if($HashSetup.VolMutehotkey.Hotkey -is [MahApps.Metro.Controls.HotKey] -and $HashSetup.VolMutehotkey.text){
              if($thisApp.Config.GlobalHotKeys.Name -notcontains 'VolMutehotkey'){
                $Hotkey = [GlobalHotKey]::New()
                [void]$thisApp.Config.GlobalHotKeys.add($Hotkey)
              }else{
                $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolMutehotkey'}
              }
              if($Hotkey.Name -ne 'VolMutehotkey'){
                $Hotkey.Name = 'VolMutehotkey'
              }
              if($Hotkey.Modifier -ne $HashSetup.VolMutehotkey.Hotkey.ModifierKeys){
                $Hotkey.Modifier = $HashSetup.VolMutehotkey.Hotkey.ModifierKeys
              }
              if($Hotkey.Key -ne $HashSetup.VolMutehotkey.Hotkey.Key){
                $Hotkey.Key = $HashSetup.VolMutehotkey.Hotkey.Key
              }
            }elseif($thisApp.Config.GlobalHotKeys.Name -contains 'VolMutehotkey'){
              write-ezlogs "| Removing VolMutehotkey from GlobalHotkeys"
              $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'VolMutehotkey'}
              [void]$thisApp.Config.GlobalHotKeys.Remove($Hotkey)
            }
          }catch{
            write-ezlogs "An exception occurred saving VolMutehotkey global hotkey" -CatchError $_       
          }  
          
          try{
            if($HashSetup.Restarthotkey.Hotkey -is [MahApps.Metro.Controls.HotKey] -and $HashSetup.Restarthotkey.text){
              if($thisApp.Config.GlobalHotKeys.Name -notcontains 'Restarthotkey'){
                $Hotkey = [GlobalHotKey]::New()
                [void]$thisApp.Config.GlobalHotKeys.add($Hotkey)
              }else{
                $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'Restarthotkey'}
              }
              if($Hotkey.Name -ne 'Restarthotkey'){
                $Hotkey.Name = 'Restarthotkey'
              }
              if($Hotkey.Modifier -ne $HashSetup.Restarthotkey.Hotkey.ModifierKeys){
                $Hotkey.Modifier = $HashSetup.Restarthotkey.Hotkey.ModifierKeys
              }
              if($Hotkey.Key -ne $HashSetup.Restarthotkey.Hotkey.Key){
                $Hotkey.Key = $HashSetup.Restarthotkey.Hotkey.Key
              }
            }elseif($thisApp.Config.GlobalHotKeys.Name -contains 'Restarthotkey'){
              write-ezlogs "| Removing Restarthotkey from GlobalHotkeys"
              $Hotkey = $thisApp.Config.GlobalHotKeys | Where-Object {$_.Name -eq 'Restarthotkey'}
              [void]$thisApp.Config.GlobalHotKeys.Remove($Hotkey)
            }
          }catch{
            write-ezlogs "An exception occurred saving Restarthotkey global hotkey" -CatchError $_       
          }
          try{
            Update-MainWindow -thisApp $thisApp -synchash $synchash -PSGlobalHotkeys
          }catch{
            write-ezlogs "An exception occurred executing Get-GlobalHotkeys" -catcherror $_
          }
          #---------------------------------------------- 
          #endregion TODO:Media Control Hotkeys
          #----------------------------------------------

          #region Import Local Media                                 
          if($hashsetup.Import_Local_Media_Toggle.isOn){
            $thisapp.config.Import_Local_Media = $true
            $newLocalMediaCount = 0
            #$RemovedLocalMediaCount = 0
            foreach($path in $hashsetup.MediaLocations_Grid.items){
              if([System.IO.Directory]::Exists($path.path)){
                if($thisApp.Config.Media_Directories -notcontains $path.path){
                  write-ezlogs " | Adding new Local Media Directory $($path.path)" -showtime -logtype Setup -LogLevel 2
                  [void]$thisApp.Config.Media_Directories.add($path.path)
                  $newLocalMediaCount++
                }            
              }else{       
                write-ezlogs "The provide local media path $($path.path) is invalid!" -showtime -warning -logtype Setup
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Local Media' 
                update-EditorHelp -content "[WARNING] The provide local media path $($path.path) is invalid!" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout           
                return
              } 
            }
            $hashSetup.paths_toRemove = $thisApp.Config.Media_Directories | Where-Object {$hashsetup.MediaLocations_Grid.items.path -notcontains $_}    
            if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.LocalMedia_Browser_Tab){
              $syncHash.Window.Dispatcher.invoke([action]{
                  [void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.LocalMedia_Browser_Tab) 
                  $syncHash.MediaTable.isEnabled = $true
                  $syncHash.LocalMedia_Browser_Tab.isEnabled = $true
                  $syncHash.LocalMedia_Browser_Tab.Visibility = 'Visible'
              })            
            }   
            if($thisApp.Config.Enable_LocalMedia_Monitor -and $thisApp.Config.Media_Directories -and (!$thisApp.ProfileManagerEnabled -or !$thisApp.LocalMedia_Monitor_Enabled)){
              $thisApp.Config.Media_Directories | foreach {
                Start-FileWatcher -FolderPath $_ -MonitorSubFolders -use_Runspace -Start_ProfileManager:$(!$thisApp.ProfileManagerEnabled) -synchash $synchash -thisApp $thisApp -Runspace_Guid (New-GUID).Guid
              }
            }elseif(!$thisApp.Config.Enable_LocalMedia_Monitor -and ($thisApp.ProfileManagerEnabled -or $thisApp.LocalMedia_Monitor_Enabled)){
              Stop-FileWatcher -thisApp $thisApp -synchash $synchash -use_Runspace -Stop_ProfileManager -force  
            }                   
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $false -MemberType NoteProperty -Force
            if($thisApp.ProfileManagerEnabled -or $thisApp.LocalMedia_Monitor_Enabled){
              Stop-FileWatcher -thisApp $thisApp -synchash $synchash -use_Runspace -Stop_ProfileManager -force   
            }
          }
          #TODO: Display Name Syntax Update
          if($thisApp.Config.LocalMedia_Display_Syntax -ne $hashsetup.LocalMedia_Display_Syntax_textbox.text){
            write-ezlogs ">>>> Local Media Default Display Name Syntax changed from: '$($thisApp.Config.LocalMedia_Display_Syntax)' to '$($hashsetup.LocalMedia_Display_Syntax_textbox.text)'" -logtype Setup
            Add-Member -InputObject $thisapp.config -Name 'LocalMedia_Display_Syntax' -Value $($hashsetup.LocalMedia_Display_Syntax_textbox.text) -MemberType NoteProperty -Force 
          }
          #endregion Import Local Media

          #region Save Youtube
          #Import Youtube
          if($hashsetup.Import_Youtube_Playlists_Toggle.isOn){
            try{
              $Name = $($thisApp.Config.App_Name)
              $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
              $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
              if(!$secretstore){
                write-ezlogs ">>>> Couldnt find secret vault, Attempting to create new application: $Name" -showtime -LogLevel 2 -logtype Setup
                try{
                  $secretstore = New-YoutubeApplication -thisApp $thisApp -Name $Name -ConfigPath $ConfigPath                  
                }catch{
                  write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs 
                }   
              }else{
                write-ezlogs "Retrieved SecretVault: $Name" -showtime -LogLevel 2 -logtype Setup -Success  
              }                 
            }catch{
              write-ezlogs "[Show-SettingsWindow-Apply] An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime
            }            
            $access_token = Get-secret -name YoutubeAccessToken  -Vault $Name -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $Name -ErrorAction SilentlyContinue
            if($refresh_access_token){
              $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $Name -ErrorAction SilentlyContinue
            }
            if([string]::IsNullOrEmpty($access_token_expires) -or [string]::IsNullOrEmpty($access_token) -or [string]::IsNullOrEmpty($refresh_access_token)){
              try{
                write-ezlogs "[Show-SettingsWindow-Apply] Did not receive access_token_expires $($access_token_expires) - access_token $($access_token) - or refresh_access_token $($refresh_access_token) from secret vault $($Name) - Starting Grant-YoutubeOauth" -showtime -warning -logtype Setup
                Grant-YoutubeOauth -thisApp $thisApp
                $access_token = Get-secret -name YoutubeAccessToken  -Vault $Name -ErrorAction SilentlyContinue
                $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $Name -ErrorAction SilentlyContinue
              }catch{
                write-ezlogs "[Show-SettingsWindow-Apply] An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
              } 
              if($access_token -and $refresh_access_token){
                write-ezlogs "[Show-SettingsWindow-Apply] [SUCCESS] Authenticated to Youtube and retrieved access tokens" -showtime -logtype Setup -LogLevel 2 -Success                      
              }else{
                write-ezlogs "[Show-SettingsWindow-Apply] Unable to successfully authenticate to Youtube!" -showtime -warning -logtype Setup
                $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
                update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Youtube! You may try to re-authenticate again or disable Import Youtube" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout      
                return         
              }             
            }else{
              write-ezlogs "Returned Youtube authentication - access_token_expires: $($access_token_expires)" -showtime -Success -logtype Setup -LogLevel 2
            }            
            $newYoutubeMediaCount = 0
            $RemovedYoutubeMediaCount = 0
            $thisApp.config.Import_Youtube_Media = $true
            if($hashsetup.Import_Youtube_Auth_ComboBox.Selectedindex -ne -1){
              $thisApp.config.Youtube_Browser = $hashsetup.Import_Youtube_Auth_ComboBox.Selecteditem.Content
            }else{
              $thisApp.config.Youtube_Browser = $null
            }                    
            if(![System.IO.Directory]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists")){
              try{
                [void][System.IO.Directory]::CreateDirectory("$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists")
              }catch{
                write-ezlogs "An exception occurred creating new directory $($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists" -showtime -catcherror $_
              }             
            }
            if([System.IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
              try{
                $Playlist_Profile = Import-Clixml "$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"
              }catch{
                write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
              }             
            }        
            foreach($playlist in $hashsetup.YoutubePlaylists_Grid.items){
              if(Test-URL $playlist.path){
                if($thisApp.Config.Youtube_Playlists -notcontains $playlist.path){
                  try{
                    write-ezlogs " | Adding new Youtube Playlist URL: $($playlist.path) - Name: $($playlist.Name)" -showtime -logtype Setup -LogLevel 3
                    [void]$thisApp.Config.Youtube_Playlists.add($playlist.path)
                    if($Playlist_Profile -and $playlist.path -notmatch 'Twitch.tv'){  
                      if($playlist.Name){
                        $playlist_Name = $playlist.name
                      }else{
                        $playlist_Name = "Custom_$($playlist.id)"
                      }    
                      #$playlistName_Cleaned = ([Regex]::Replace($playlist_Name, $pattern3, '')).trim()            
                      $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($playlist.id).xml"
                      write-ezlogs " | Saving new Youtube Playlist profile to $Playlist_Profile_path" -showtime -logtype Setup -LogLevel 2
                      $Playlist_Profile.name = $playlist_Name
                      #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                      $Playlist_Profile.Playlist_ID = $playlist.id
                      $Playlist_Profile.Playlist_URL = $playlist.path
                      $Playlist_Profile.type = $playlist.type
                      $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                      $Playlist_Profile.Playlist_Date_Added = [DateTime]::Now.ToString()
                      if($playlist.playlist_info.id){
                        $Playlist_Profile.Source = 'YoutubeAPI'
                        Add-Member -InputObject $Playlist_Profile -Name 'Playlist_Info' -Value $playlist.playlist_info -MemberType NoteProperty -Force
                      }else{
                        $Playlist_Profile.Source = 'Custom'
                      }  
                      Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default                
                    }
                    $newYoutubeMediaCount++
                  }catch{
                    write-ezlogs "An exception occurred adding path $($playlist.path) to Youtube_Playlists" -showtime -catcherror $_
                  }
                }            
              }else{        
                write-ezlogs "The provided Youtube playlist URL $($playlist.path) is invalid!" -showtime -warning -logtype Setup
                update-EditorHelp -content "The provided Youtube playlist URL $($playlist.path) is invalid! Please remove it from the Youtube list before continuing" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Youtube Import Warning' -clear -Open
                return
              } 
            }
            if($hashsetup.Update){
              $hashSetup.playlists_toRemove = [System.Collections.Generic.List[Object]]::new()
              $playlists_toRemove = $thisApp.Config.Youtube_Playlists | where {$hashsetup.YoutubePlaylists_Grid.items.path -notcontains $_}
              if($playlists_toRemove){
                foreach($playlist in $playlists_toRemove){
                  $RemovedYoutubeMediaCount++
                  [void]$hashSetup.playlists_toRemove.add($playlist)
                  write-ezlogs " | Removing Youtube Playlist $($playlist)" -showtime -logtype Setup -LogLevel 2
                  [void]$thisApp.Config.Youtube_Playlists.Remove($playlist)
                }
              }
            }
            if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Youtube_Tabitem){
              $hashSetup.Update_YoutubeMedia_Sources = $true
              $syncHash.Window.Dispatcher.invoke([action]{
                  [void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Youtube_Tabitem) 
                  if($syncHash.YoutubeTable){
                    $syncHash.YoutubeTable.isEnabled = $true
                  }                  
                  $syncHash.Youtube_Tabitem.isEnabled = $true
              })            
            }
            #Youtube Monitor
            if($hashsetup.Youtube_Update_Toggle.isOn -and $hashsetup.Youtube_Update_Interval_ComboBox.SelectedIndex -eq -1){
              $thisApp.Config.Youtube_Update = $false
              write-ezlogs "You must specify an interval when enabling option '$($hashsetup.Youtube_Update_Toggle.content)'" -showtime -warning -logtype Setup        
              update-EditorHelp -content "[Warning] You must specify an interval when enabling option '$($hashsetup.Youtube_Update_Toggle.content)'" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Youtube' -clear -Open
              return     
            }
            if($syncHash.YoutubeTable -and $synchash.YoutubeMedia_View){
              if($thisapp.config.Youtube_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Youtube_Update_Interval) -and $thisapp.config.Youtube_Update_Interval -ne 'On Startup'){
                try{
                  Start-YoutubeMonitor -Interval $thisapp.config.Youtube_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
                }catch{
                  write-ezlogs 'An exception occurred in Start-YoutubeMonitor' -showtime -catcherror $_
                }
              }elseif((!$thisapp.config.Youtube_Update -or [string]::IsNullOrEmpty($thisapp.config.Youtube_Update_Interval)) -and $thisapp.config.Youtube_Update_Interval -ne 'On Startup'){
                try{
                  $thisapp.config.Youtube_Update = $false
                  $thisApp.YoutubeMonitorEnabled = $false
                  $Stop_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Youtube_Monitor_Runspace' -force
                }catch{
                  write-ezlogs 'An exception occurred in Start-YoutubeMonitor' -showtime -catcherror $_
                }
              }      
            }                                        
          }else{
            $thisapp.config.Import_Youtube_Media = $false
          }

          #Youtube Browser Auth
          $thisApp.config.Import_Youtube_Browser_Auth = ($hashsetup.Import_Youtube_Auth_Toggle.isOn -eq $true)

          #Youtube Download Path
          if([system.io.directory]::Exists($hashsetup.Youtube_Download_textbox.text)){
            $thisApp.config.Youtube_Download_Path = $($hashsetup.Youtube_Download_textbox.text) 
          }else{
            $thisApp.config.Youtube_Download_Path = ''      
          }
          #Sponsorblock
          $thisapp.config.Sponsorblock_ActionType = $hashsetup.Sponsorblock_ActionType_ComboBox.Selecteditem.Content
          #endregion Save Youtube

          #region Apply Twitch
          $hashsetup.Twitch_Update_textblock.text = ''
          $hashsetup.Twitch_Update_transitioningControl.content = ''   
          #Twitch Monitor
          if($hashsetup.Twitch_Update_Toggle.isOn -and $hashsetup.Twitch_Update_Interval_ComboBox.SelectedIndex -eq -1){
            $thisapp.config.Twitch_Update = $false
            write-ezlogs "You must specify an interval when enabling option '$($hashsetup.Twitch_Update_Toggle.content)'" -showtime -warning -logtype Setup
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Twitch'            
            update-EditorHelp -content "[Warning]`n`nYou must specify an interval when enabling option '$($hashsetup.Twitch_Update_Toggle.content)'" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
            $hashsetup.Twitch_Update_textblock.text = "[Warning] You must specify an interval when enabling option '$($hashsetup.Twitch_Update_Toggle.content)'"
            $hashsetup.Twitch_Update_textblock.foreground = 'Orange'
            $hashsetup.Twitch_Update_textblock.FontSize = 14
            $hashsetup.Twitch_Update_transitioningControl.content = $hashsetup.Twitch_Update_textblock
            return     
          }    
          if($thisapp.config.Twitch_Update -and $thisapp.config.Twitch_Update_Interval){
            try{
              Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
            }catch{
              write-ezlogs 'An exception occurred starting Start-TwitchMonitor' -showtime -catcherror $_
            }
          }else{
            $thisApp.Config.Twitch_Update = $false
            try{
              if($synchash.TwitchMonitor_timer.isEnabled){
                write-ezlogs ">>>> Stopping existing TwitchMonitor timer" -logtype Setup
                $synchash.TwitchMonitor_timer.stop()
              }
            }catch{
              write-ezlogs 'An exception occurred stopping Twitch_Monitor_Runspace' -showtime -catcherror $_
            }
          }

          if($hashsetup.Import_Twitch_Playlists_Toggle.isOn){           
            $newTwitchMediaCount = 0
            $RemovedTwitchMediaCount = 0
            $thisApp.config.Import_Twitch_Media = $true
            #$urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
            if($thisApp.Config.Twitch_Playlists.count -eq 0){
              $thisApp.config.Twitch_Playlists = [System.Collections.Generic.List[Twitch_Playlist]]::new()
            }
            foreach($playlist in $hashsetup.TwitchPlaylists_Grid.items){
              if(Test-URL $playlist.path){
                if($thisApp.Config.Twitch_Playlists.path -notcontains $playlist.path){
                  write-ezlogs " | Adding new Twitch URL $($playlist.path)" -showtime -logtype Setup
                  [void]$thisApp.Config.Twitch_Playlists.add($playlist)
                  $newTwitchMediaCount++
                }elseif(!$synchash.All_Twitch_Media -or $synchash.All_Twitch_Media.url -notcontains $playlist.path){
                  $newTwitchMediaCount++
                }            
              }else{           
                write-ezlogs "The provided Twitch URL $($playlist.path) is invalid!" -showtime -warning -logtype Setup
                update-EditorHelp -content "The provided Twitch URL $($playlist.path) is invalid! Please remove it from the Twitch list before continuing" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Twitch Import Warning' -clear -Open
                return
              } 
            }
            $hashSetup.Twitchplaylists_toRemove = [System.Collections.Generic.List[Object]]::new()
            $Twitchplaylists_toRemove = $thisApp.Config.Twitch_Playlists | where {$hashsetup.TwitchPlaylists_Grid.items.path -notcontains $_.path}
            if($Twitchplaylists_toRemove){
              foreach($playlist in $Twitchplaylists_toRemove){
                $RemovedTwitchMediaCount++
                [void]$hashSetup.Twitchplaylists_toRemove.add($playlist)
                write-ezlogs "| Removing Twitch channel $($playlist.name) from thisApp.Config.Twitch_Playlists" -showtime -logtype Setup -LogLevel 2
                [void]$thisApp.Config.Twitch_Playlists.Remove($playlist)
              }
            }                    
          }else{
            $thisApp.config.Import_Twitch_Media = $false
          } 
          
          #Proxies
          if($hashsetup.Twitch_Custom_Proxy_Toggle.isOn){
            $thisApp.config.UseTwitchCustom = $true
            $thisApp.config.TwitchProxies.clear()
            foreach($proxy in $hashsetup.Twitch_Custom_Proxy_Grid.items){
              if(Test-URL $proxy.url){
                if($thisApp.config.TwitchProxies -notcontains $proxy.url){
                  write-ezlogs " | Adding new Twitch Playlist Proxy URL: $($proxy.url)" -showtime -logtype Setup
                  [void]$thisApp.config.TwitchProxies.add($proxy.url)
                }else{
                  write-ezlogs "Twitch Playlist Proxy URL has already been added: $($proxy.url)" -warning -logtype Setup
                }            
              }else{           
                write-ezlogs "The provided Twitch Playlist Proxy URL '$($proxy.url)' is invalid!" -showtime -warning -logtype Setup
              } 
            }
            $Twitch_Proxy_toRemove = $thisApp.config.TwitchProxies | Where-Object {$hashsetup.Twitch_Custom_Proxy_Grid.items.url -notcontains $_}
            foreach($proxy in $Twitch_Proxy_toRemove){
              write-ezlogs " | Removing Twitch Playlist Proxy URL: $($proxy)" -showtime -logtype Setup
              [void]$thisApp.config.TwitchProxies.Remove($proxy)
            }
          }else{
            $thisApp.config.UseTwitchCustom = $false
          }                      
          #endregion Apply Twitch
                         
          #region Spicetify
          if($hashsetup.Spicetify_Toggle.isOn){
            try{    
              $thisapp.config.Use_Spicetify = $true
            }catch{
              write-ezlogs "An exception occurred enabling Spicetify customization" -showtime -catcherror $_  
            }                       
          }else{
            try{                     
              if($thisApp.config.Use_Spicetify){
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                $Button_Settings.AffirmativeButtonText = 'Yes'
                $Button_Settings.NegativeButtonText = 'No'  
                $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Spicetify - IMPORTANT!","Spicetify is now disabled. However, if Spicetify was previously enabled and applied, you must click the 'Remove from Spotify' button under Spotify Options to complete the process. Its recommended to do this now, but you can also do so later.`nDo you still want to continue?",$okandCancel,$Button_Settings)
                if($result -eq 'Affirmative'){
                  write-ezlogs "User wished to continue setup without removing Spicetify customizations..." -showtime -warning -logtype Setup
                }else{
                  write-ezlogs "User did not wish to continue without removing Spicetify customizations" -showtime -warning -logtype Setup
                  return
                }
                $hashsetup.Spicetify_textblock.text = "IMPORTANT! Spicetify is disabled. To remove customizations made to Spotify, you must click 'Remove from Spotify' to complete the process" 
                $hashsetup.Spicetify_textblock.foreground = 'Orange'
                $hashsetup.Spicetify_textblock.FontSize = 14
                $hashsetup.Spicetify_transitioningControl.content = $hashsetup.Spicetify_textblock                  
              }        
              Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force                             
            }catch{
              write-ezlogs 'An error occurred while disabling Spicetify customizations' -showtime -catcherror $_
              Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force                
            }
          } 
          #endregion Spicetify  
                   
          #region Import Spotify
          if($first_run -and (Get-Process *Spotify* -ErrorAction SilentlyContinue)){
            write-ezlogs "Forcing Spotify client to close.." -showtime -warning -logtype Setup
            Get-Process *Spotify* | Stop-Process -Force -ErrorAction SilentlyContinue
          } 
          $newSpotifyMediaCount = 0
          $RemovedSpotifyMediaCount = 0                          
          if($hashsetup.Import_Spotify_Playlists_Toggle.isOn){
            $thisApp.config.Import_Spotify_Media = $true
            $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
            if(!$hashsetup.Spotify_Auth_app.token.access_token){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_settings.AffirmativeButtonText = "Yes"
              $Button_settings.NegativeButtonText = "No"  
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Invalid/Missing Spotify Credentials","No Spotify credentials were provided or the existing ones are invalid. Do you wish to supply your Spotify credentials now?`n`nNOTE: If you proceed without providing valid credentials, you may not be able play or manage Spotify media",$okAndCancel,$button_settings)
              if($result -eq 'Affirmative'){
                write-ezlogs ">>>> User wished to provide their Spotify credentials - Starting spotify authentication setup process" -showtime -logtype Setup
                $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
                if(!$hashsetup.Spotify_Auth_app){
                  $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\Spotify-API-Config.xml"
                  write-ezlogs "Importing API XML $APIXML" -showtime -logtype Setup
                  if([System.IO.File]::Exists($APIXML)){
                    $Spotify_API = Import-Clixml $APIXML
                    $client_ID = $Spotify_API.ClientID
                    $client_secret = $Spotify_API.ClientSecret            
                  }
                  if($Spotify_API -and $client_ID -and $client_secret){
                    write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime -logtype Setup
                    #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientSecret | ConvertTo-SecureString))))
                    #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientID | ConvertTo-SecureString))))            
                    New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs 
                    $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name               
                  }
                }
                if($hashsetup.Spotify_Auth_app){
                  try{
                    $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp               
                  }catch{
                    write-ezlogs "[Show-SettingsWindow] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_ -enablelogs
                  }                             
                  if($playlists){
                    foreach($playlist in $playlists){              
                      $playlisturl = $playlist.uri
                      $playlistName = $playlist.name
                      if($hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $playlisturl){
                        if($thisApp.Config.Verbose_logging){write-ezlogs "Adding Spotify Playlist URL $playlisturl" -showtime}
                        Update-SpotifyPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'SpotifyPlaylist' -Playlist_Info $playlist -VerboseLog:$thisApp.Config.Verbose_logging
                      }else{
                        write-ezlogs "The Spotify Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
                      }
                    }
                    $thisApp.config.Import_Spotify_Media = $true
                    write-ezlogs "Authenticated to Spotify and retrieved Playlists" -showtime -color green -logtype Setup -Success
                    $hashsetup.Spotify_Auth_Status = $true
                    $hashsetup.Import_Spotify_textbox.text = '' 
                    if($MahDialog_hash.window.Dispatcher){
                      write-ezlogs "[Show-SettingsWindow-Apply] | Closing Weblogin Window" -logtype Setup
                      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                    }  
                    if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Spotify_Tabitem){
                      $syncHash.Window.Dispatcher.invoke([action]{
                          [void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Spotify_Tabitem) 
                          if($syncHash.SpotifyTable){
                            $syncHash.SpotifyTable.isEnabled = $true
                          }                          
                          $syncHash.Spotify_Tabitem.isEnabled = $true
                      })            
                    }                                              
                  }else{
                    write-ezlogs "[Show-SettingsWindow] Unable to successfully authenticate to spotify! (No playlists returned!)" -showtime -warning -logtype Setup
                    $thisApp.config.Import_Spotify_Media = $false
                    $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                    $hashsetup.Spotify_Auth_Status = $false
                    if($hashsetup.EditorHelpFlyout.Document.Blocks){
                      $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                    }        
                    $hashsetup.Editor_Help_Flyout.isOpen = $true
                    $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                    update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! (No playlists returned!) Spotify integration will be unavailable. Please try again or disable Spotify Importing to continue setup" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
                    Remove-SpotifyApplication -Name $thisApp.config.App_Name 
                    return              
                  }               
                }else{
                  write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning -logtype Setup      
                  if($hashsetup.EditorHelpFlyout.Document.Blocks){
                    $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                  }        
                  $hashsetup.Editor_Help_Flyout.isOpen = $true
                  $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                  update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API (Couldn't find API creds!). Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout   
                  Remove-SpotifyApplication -Name $thisApp.config.App_Name   
                  return
                }                
              }else{
                write-ezlogs " | User wish to continue without providing Spotify credentials!" -showtime -logtype Setup -Warning
                $hashsetup.Spotify_Auth_Status = $false
              }
            }else{
              $hashsetup.Spotify_Auth_Status = $true
            } 
            if(![System.IO.Directory]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists")){
              try{
                [void][System.IO.Directory]::CreateDirectory("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists")
              }catch{
                write-ezlogs "An exception occurred creating new directory $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists" -showtime -catcherror $_
              }             
            }
            if([System.IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
              try{
                $Playlist_Profile = Import-Clixml "$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"
              }catch{
                write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
              }             
            }        
            foreach($playlist in $hashsetup.SpotifyPlaylists_Grid.items){
              if($playlist.path -match 'Spotify'){
                if($thisApp.Config.Spotify_Playlists -notcontains $playlist.path){
                  try{
                    write-ezlogs " | Adding new Spotify Playlist URL: $($playlist.path) - Name: $($playlist.Name)" -showtime -logtype Setup -LogLevel 3
                    [void]$thisApp.Config.Spotify_Playlists.add($playlist.path)
                    if($Playlist_Profile -and $playlist.path){  
                      if($playlist.Name){
                        $playlist_Name = $playlist.name
                      }else{
                        $playlist_Name = "Custom_$($playlist.id)"
                      }    
                      #$playlistName_Cleaned = ([Regex]::Replace($playlist_Name, $pattern3, '')).trim()            
                      $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml"
                      write-ezlogs " | Saving new Spotify Playlist profile to $Playlist_Profile_path" -showtime -logtype Setup -LogLevel 3
                      $Playlist_Profile.name = $playlist_Name
                      #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                      $Playlist_Profile.Playlist_ID = $playlist.id
                      $Playlist_Profile.Playlist_URL = $playlist.path
                      $Playlist_Profile.type = $playlist.type
                      $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                      $Playlist_Profile.Playlist_Date_Added = [DateTime]::Now.ToString()
                      if($playlist.playlist_info.id){
                        $Playlist_Profile.Source = 'SpotifyAPI'
                        Add-Member -InputObject $Playlist_Profile -Name 'Playlist_Info' -Value $playlist.playlist_info -MemberType NoteProperty -Force
                      }else{
                        $Playlist_Profile.Source = 'Custom'
                      }
                      Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default                   
                    }
                    $newSpotifyMediaCount++
                  }catch{
                    write-ezlogs "An exception occurred adding path $($playlist.path) to Spotify_Playlists" -showtime -catcherror $_
                  }
                }            
              }else{
                write-ezlogs "The provided Spotify playlist URL $($playlist.path) is invalid!" -showtime -warning -logtype Setup                 
                $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[WARNING] A provided Spotify playlist URL ($($playlist.path)) is invalid! Please remove the offending playlist and try again" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
                return
              } 
            }
            if($hashsetup.Update){
              $hashSetup.Spotifyplaylists_toRemove = [System.Collections.Generic.List[Object]]::new()
              $Spotify_playlists_toRemove = $thisApp.Config.Spotify_Playlists | where {$hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $_}
              if($Spotify_playlists_toRemove){
                foreach($playlist in $Spotify_playlists_toRemove){
                  $RemovedSpotifyMediaCount++
                  [void]$hashSetup.Spotifyplaylists_toRemove.add($playlist)
                  write-ezlogs " | Removing Spotify Playlist $($playlist)" -showtime -logtype Setup -LogLevel 2
                  [void]$thisApp.Config.Spotify_Playlists.Remove($playlist)
                }
              }
            }
            if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Spotify_Tabitem){
              $hashsetup.Update_SpotifyMedia_Sources = $true
              $syncHash.Window.Dispatcher.invoke([action]{
                  [void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Spotify_Tabitem) 
                  if($syncHash.SpotifyTable){
                    $syncHash.SpotifyTable.isEnabled = $true
                  }                    
                  $syncHash.Spotify_Tabitem.isEnabled = $true
              })            
            }
            #Spotify Monitor
            if($hashsetup.Spotify_Update_Toggle.isOn -and $hashsetup.Spotify_Update_Interval_ComboBox.SelectedIndex -eq -1){
              $thisapp.config.Spotify_Update = $false
              write-ezlogs "You must specify an interval when enabling option '$($hashsetup.Spotify_Update_Toggle.content)'" -showtime -warning -logtype Setup        
              update-EditorHelp -content "[Warning] You must specify an interval when enabling option '$($hashsetup.Spotify_Update_Toggle.content)'" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout -Header 'Spotify' -clear -Open
              return     
            }
            if($syncHash.SpotifyTable.Itemssource){
              if($thisapp.config.Spotify_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Spotify_Update_Interval) -and $thisapp.config.Spotify_Update_Interval -ne 'On Startup'){
                try{
                  Start-SpotifyMonitor -Interval $thisapp.config.Spotify_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
                }catch{
                  write-ezlogs 'An exception occurred in Start-SpotifyMonitor' -showtime -catcherror $_
                }
              }elseif((!$thisapp.config.Spotify_Update -or [string]::IsNullOrEmpty($thisapp.config.Spotify_Update_Interval)) -and $thisapp.config.Spotify_Update_Interval -ne 'On Startup'){
                try{
                  $thisApp.SpotifyMonitorEnabled = $false
                  $thisapp.config.Spotify_Update = $false
                }catch{
                  write-ezlogs 'An exception occurred in Start-SpotifyMonitor' -showtime -catcherror $_
                }
              }      
            }
          }else{
            try{
              $thisApp.Config.Import_Spotify_Media = $false
              $thisApp.Config.Install_Spotify = $false
              $thisApp.Config.Spotify_Update = $false
              $thisApp.SpotifyMonitorEnabled = $false
            }catch{
              write-ezlogs 'An exception occurred setting Spotify config settings' -showtime -catcherror $_
            }
          } 
          $thisApp.Config.Install_Spotify = ($hashsetup.Install_Spotify_Toggle.isOn -eq $true)
          #endregion Import Spotify

          #region Discord Integration         
          if($hashsetup.Discord_Integration_Toggle.isOn){
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
              $thisApp.config.Discord_Integration = $false
              Set-DiscordPresense -synchash $synchash -thisapp $thisApp -stop -runspace
            }catch{
              write-ezlogs "An exception occurred executing Set-DiscordPresence" -showtime -catcherror $_
            }           
          }
          #endregion Discord Integration
                                    
          #region Apply configuration changes 
          if(!$First_run -and $hashsetup.Update){
            $hashsetup.Update_Media_Sources = $true
            if($newLocalMediaCount -ge 1){
              write-ezlogs "Found $newLocalMediaCount additions to local media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_LocalMedia_Sources = $true
            }else{
              $hashsetup.Update_LocalMedia_Sources = $false
              write-ezlogs "No additions found to local media sources" -showtime -logtype Setup -LogLevel 2
            }
            if(@($hashSetup.paths_toRemove | Where-Object {$_}).count -ge 1){
              $synchash.LocalMedia_ToRemove = [System.Collections.Generic.List[Object]]::new()
              write-ezlogs "Found $(@($hashSetup.paths_toRemove).count) removals from local media sources" -showtime -logtype Setup -LogLevel 2
              foreach($path in $hashSetup.paths_toRemove){
                write-ezlogs " | Removing Local Media Directory $($path)" -showtime -logtype Setup -LogLevel 2
                [void]$thisApp.Config.Media_Directories.Remove($path)
              } 
              if($synchash.All_local_Media.SyncRoot){
                write-ezlogs "Parsing All_Local_media for media in directory $($path)" -showtime -logtype Setup -LogLevel 2               
                $synchash.LocalMedia_ToRemove = foreach($path in $hashSetup.paths_toRemove){
                  Get-IndexesOf $synchash.All_local_Media.Sourcedirectory -Value $path | & { process {
                      $synchash.All_local_Media[$_]
                  }}
                }
              }elseif($synchash.MediaTable.Itemssource.SourceCollection){
                write-ezlogs "Parsing MediaTable itemssource for media in directory $($path)" -showtime -logtype Setup -LogLevel 2
                $synchash.LocalMedia_ToRemove = $synchash.MediaTable.Itemssource.SourceCollection | Where-Object {$_.Sourcedirectory -in $hashSetup.paths_toRemove}
              }
              #Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
              $hashsetup.Remove_LocalMedia_Sources = $true                
            }else{
              write-ezlogs "No removals found from local media sources" -showtime -logtype Setup -LogLevel 2
              $synchash.LocalMedia_ToRemove = $Null
              $hashsetup.Remove_LocalMedia_Sources = $false
            }

            #Spotify Playlist/Source Updates
            if($newSpotifyMediaCount -ge 1){
              write-ezlogs "Found $newSpotifyMediaCount additions to Spotify media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_SpotifyMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to Spotify media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_SpotifyMedia_Sources = $false
            }           
            if($RemovedSpotifyMediaCount -ge 1){
              write-ezlogs "Found $RemovedSpotifyMediaCount removals from Spotify media sources" -showtime -logtype Setup -LogLevel 2        
              $hashsetup.Remove_SpotifyMedia_Sources = $true
            }else{
              write-ezlogs "No removals found from Spotify media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Remove_SpotifyMedia_Sources = $false
            }            
                           
            if($newYoutubeMediaCount -ge 1){
              write-ezlogs "Found $newYoutubeMediaCount additions to Youtube media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_YoutubeMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to Youtube media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_YoutubeMedia_Sources = $false
            }
            if($RemovedYoutubeMediaCount -ge 1){
              write-ezlogs "Found $RemovedYoutubeMediaCount removals from Youtube media sources" -showtime -logtype Setup -LogLevel 2        
              foreach($path in $hashSetup.playlists_toRemove){
                if($thisApp.Config.Youtube_Playlists -contains $path){
                  write-ezlogs " | Removing Youtube playlist $($path)" -showtime -logtype Setup -LogLevel 2
                  [void]$thisApp.Config.Youtube_Playlists.remove($path)
                }
              }
              #Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
              if($synchash.All_Youtube_Media){
                write-ezlogs "Parsing All_Youtube_media for for playlists to remove" -showtime -logtype Setup -LogLevel 2
                $playlists_to_remove = $synchash.All_Youtube_Media | where {$hashSetup.playlists_toRemove -contains $_.Playlist_URL}
              }
              if($playlists_to_remove){
                write-ezlogs " | Found $($playlists_to_remove.count) playlists to remove from All_Youtube_media" -showtime -logtype Setup -LogLevel 2
                $hashsetup.Remove_YoutubeMedia_Sources = $true 
                $hashSetup.playlists_toRemove = $playlists_to_remove
              }else{
                $hashsetup.Remove_YoutubeMedia_Sources = $false
              }
            }else{
              write-ezlogs "No removals found from Youtube media sources" -showtime -logtype Setup -LogLevel 2
            }
            if($newTwitchMediaCount -ge 1){
              write-ezlogs "Found $newTwitchMediaCount additions to Twitch media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Update_TwitchMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to Twitch media sources" -showtime -logtype Setup -LogLevel 2
            }
            if($RemovedTwitchMediaCount -ge 1){
              write-ezlogs "Found $RemovedTwitchMediaCount removals from Twitch media sources" -showtime -logtype Setup -LogLevel 2
              $hashsetup.Remove_TwitchMedia_Sources = $true
            }else{
              write-ezlogs "No removals found from Twitch media sources" -showtime -logtype Setup -LogLevel 2
            }                    
          }
          #endregion Apply configuration changes

          #region Save configuration changes
          try{
            write-ezlogs ">>>> Saving configuration to: $($thisApp.Config.Config_Path)" -logtype Setup
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
          }catch{
            write-ezlogs "An exception occurred saving config file to $($thisApp.config.Config_Path)" -showtime -catcherror $_           
            update-EditorHelp -content "Unable to continue due to critical error, settings may not have saved or may be lost!" -color Tomato  -RichTextBoxControl $hashsetup.EditorHelpFlyout -clear -Header 'SAVE ERROR'
            update-EditorHelp -content "[ERROR] An exception occurred saving config file to $($thisApp.config.Config_Path)`n$($_ | out-string)" -color Tomato  -RichTextBoxControl $hashsetup.EditorHelpFlyout -Open
            return
          }
          #endregion Save configuration changes

          $hashsetup.Accepted = $true
          Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -close -Dequeue                                  
        }catch{
          write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime
          $hashsetup.Accepted = $false
          $hashsetup.Canceled = $false
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'SAVE ERROR' 
          update-EditorHelp -content "[ERROR] An exception occurred when when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
        }
      }.GetNewClosure()
      $hashsetup.Save_Setup_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Save_Setup_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Apply Settings Button
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Cancel Button
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashsetup.Cancel_Setup_Button_Click_Command = {
        try{          
          $hashsetup = $hashsetup
          $thisApp = $thisApp
          $First_Run = $First_Run
          write-ezlogs ">>>> User choose to cancel first run setup...exiting" -showtime -logtype Setup
          try{
            $existing_Runspace = Get-runspace -name 'enumerate_files_Scriptblock'
            if($existing_Runspace){
              $existingjob_check = $existing_Runspace | where {$_.name -eq 'enumerate_files_Scriptblock' -and $_.RunspaceAvailability -eq 'Busy' -and $_.RunspaceStateInfo.state -eq 'Opened'}
              if($existingjob_check){ 
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                $Button_settings.AffirmativeButtonText = "Yes"
                $Button_settings.NegativeButtonText = "No"  
                $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Scan in Progress","App is currently scanning for valid media files, are you sure you wish to cancel?",$okAndCancel,$button_settings)
                if($result -eq 'Affirmative'){
                  write-ezlogs "User wished to cancel" -showtime -warning -logtype Setup
                  $Stop_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'enumerate_files_Scriptblock' -force
                }else{
                  write-ezlogs " | User did not wish to cancel" -showtime -logtype Setup 
                  break
                }
              }                    
            }
          }catch{
            write-ezlogs " An exception occurred checking for existing runspace 'enumerate_files_Scriptblock'" -showtime -catcherror $_
          }
          $hashsetup.Canceled = $true 
          Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -close -Dequeue
          if($First_Run){
            Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs -thisApp $thisApp -globalstopwatch $globalstopwatch
            Stop-Process $pid 
            exit 
          }else{
            $hashsetup.Update_Media_Sources = $false
          }                                          
        }catch{
          write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
          update-EditorHelp -content "[ERROR] An exception occurred when when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                       
          if($First_Run){
            return
          }else{
            $hashsetup.Update_Media_Sources = $false
          }                
        }
      }.GetNewClosure()
      $hashsetup.Cancel_Setup_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashsetup.Cancel_Setup_Button_Click_Command)
      #---------------------------------------------- 
      #endregion Cancel Button
      #----------------------------------------------   

      #---------------------------------------------- 
      #region Window Loaded Event
      #---------------------------------------------- 
      $hashsetup.Window_Loaded_Command = {
        param($Sender)    
        try{
          if($hash.Window.IsVisible){
            write-ezlogs ">>>> Hiding Splash Screen" -showtime -logtype Setup
            Update-SplashScreen -hash $hash -hide
            [void]$hashsetup.Window.Activate() 
          }
          #Register window to installed application ID 
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($hashsetup.Window)   
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering Miniplayer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)    
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }
        }catch{
          write-ezlogs "An exception occurred in hashsetup.Window.Add_Loaded" -showtime -catcherror $_
        }
      }
      $hashsetup.Window.Add_Loaded($hashsetup.Window_Loaded_Command)
      #---------------------------------------------- 
      #endregion Window Loaded Event
      #----------------------------------------------

      #---------------------------------------------- 
      #region Window Closing Event
      #---------------------------------------------- 
      $hashsetup.Window_Closing_Command = {
        [CmdletBinding()]
        Param([Parameter()] $Sender,[Parameter()] $CancelEventArgs)
        $hashSetup = $hashSetup
        $First_run = $First_Run
        $No_SettingsPreload = $No_SettingsPreload
        $thisApp = $thisApp
        $synchash = $synchash
        if($sender -eq $hashsetup.Window){  
          try{
            if(($hashsetup.Update -or $hashsetup.Canceled -or $hashsetup.Accepted)){
              if($hashsetup.Update){
                if(!$First_Run -and !$No_SettingsPreload){
                  write-ezlogs ">>>> Hiding First Run Window" -showtime -logtype Setup
                  $hashsetup.Window.Hide()
                  $_.Cancel = $true
                }
                if($thisApp.Config.Dev_Mode){write-ezlogs ">>>> Unchecking SettingsButton_ToggleButton" -showtime -logtype Setup -Dev_mode}
                Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SettingsButton_ToggleButton' -Property 'isChecked' -value $false
              }
              [void][System.Windows.Input.FocusManager]::SetFocusedElement([System.Windows.Input.FocusManager]::GetFocusScope($hashsetup.Window),$Null)
              [void][System.Windows.Input.Keyboard]::ClearFocus()
              if(!$First_Run -and $hashsetup.Update_Media_Sources){
                if($thisapp.config.Import_Local_Media){ 
                  if($hashsetup.Remove_LocalMedia_Sources){
                    if(@($synchash.LocalMedia_ToRemove).count -gt 0){
                      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $true
                      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false 
                      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Label' -Property 'text' -value "Removing $(@($synchash.LocalMedia_ToRemove).count) media from library..."
                      $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
                      if([System.IO.File]::Exists($AllMedia_Profile_File_Path)){
                        write-ezlogs ">>>> Importing All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime -logtype Setup
                        $synchash.All_local_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path
                      }
                      write-ezlogs "| Before Media Profile count: $(@($synchash.All_local_Media).count) - Media to remove count: $(@($synchash.LocalMedia_ToRemove).count)" -showtime -logtype Setup
                      $synchash.All_local_Media = $synchash.All_local_Media.where({$synchash.LocalMedia_ToRemove.id -notcontains $_.id})      
                      write-ezlogs "| After Media Profile count: $(@($synchash.All_local_Media).count)" -showtime -logtype Setup
                      Export-SerializedXML -InputObject $synchash.All_local_Media -Path $AllMedia_Profile_File_Path
                      $tag = 'Import'
                    }else{
                      write-ezlogs "There was no local media to remove!" -showtime -warning -logtype Setup
                    }
                  }                  
                  if($hashsetup.Update_LocalMedia_Sources){
                    write-ezlogs ">>>> Adding/Updating Local media table" -showtime -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $true
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false
                    $tag = 'AddNewOnly'
                  }
                  if($tag -and $synchash.Refresh_LocalMedia_timer){
                    $synchash.Refresh_LocalMedia_timer.tag = $tag            
                    $synchash.Refresh_LocalMedia_timer.start()                 
                  }         
                }elseif($synchash.MediaTable){
                  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.LocalMedia_Browser_Tab){
                    write-ezlogs "Setting mediatable itemssource to null and removing local media library tab" -showtime -warning -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'ItemsSource' -value $Null -ClearValue
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MainGrid_Bottom_TabControl' -Property 'items' -Method 'Remove' -Method_Value $syncHash.LocalMedia_Browser_Tab
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false
                    $synchash.All_local_Media = $Null           
                  }
                }        
                if($thisapp.Config.Import_Spotify_Media){
                  if(($hashsetup.Update_SpotifyMedia_Sources -or $hashsetup.Remove_SpotifyMedia_Sources)){
                    write-ezlogs ">>>> Executing Import-Spotify to update sources" -showtime -logtype Setup
                    Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisApp $thisapp
                  }    
                }else{
                  $AllSpotify_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisapp.config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')        
                  if([System.IO.File]::exists($AllSpotify_Media_Profile_Directory_Path)){
                    [void][System.IO.File]::Delete($AllSpotify_Media_Profile_Directory_Path)
                  }
                  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Spotify_Tabitem){
                    write-ezlogs "Setting SpotifyTable itemssource to null and removing Spotify media library tab" -showtime -warning -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SpotifyTable' -Property 'ItemsSource' -value $Null -ClearValue
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MainGrid_Bottom_TabControl' -Property 'items' -Method 'Remove' -Method_Value $syncHash.Spotify_Tabitem
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SpotifyTable' -Property 'isEnabled' -value $false
                    $synchash.All_Spotify_Media = $Null         
                  }         
                }
                if($thisapp.Config.Import_Youtube_Media){
                  if($hashSetup.playlists_toRemove -and $hashsetup.Remove_YoutubeMedia_Sources){
                    $All_YoutubeMedia_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')
                    if([System.IO.File]::Exists($All_YoutubeMedia_File_Path)){
                      write-ezlogs "Importing All Youtube Media profile cache at $All_YoutubeMedia_File_Path" -showtime -logtype Setup
                      $all_youtubemedia_profile = Import-SerializedXML -Path $All_YoutubeMedia_File_Path
                      #[System.Collections.Generic.List[Object]]$all_youtubemedia_profile = Import-Clixml $All_YoutubeMedia_File_Path
                    }
                    [System.Collections.Generic.List[Object]]$all_youtubemedia_profile = $all_youtubemedia_profile | where {$hashSetup.playlists_toRemove.id -notcontains $_.id}
                    write-ezlogs "Updating All Youtube Media profile cache at $All_YoutubeMedia_File_Path" -showtime -logtype Setup
                    Export-SerializedXML -InputObject $all_youtubemedia_profile -path $All_YoutubeMedia_File_Path
                    #Export-Clixml -InputObject ([System.Collections.Generic.List[Object]]$all_youtubemedia_profile) -path $All_YoutubeMedia_File_Path -Force -Encoding Default 
                  }
                  if($hashsetup.Update_YoutubeMedia_Sources -or $hashsetup.Remove_YoutubeMedia_Sources){
                    write-ezlogs ">>>> Executing Import-Youtube to update sources" -logtype Setup
                    Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh
                  }elseif($thisApp.Config.Youtube_Playlists.count -eq 0){
                    write-ezlogs ">>>> Youtube Playlists count is 0 - clearing Youtube library table itemssource" -showtime -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'itemssource' -value $Null -ClearValue
                  }      
                }else{
                  $AllYoutube_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisapp.config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')        
                  if([System.IO.File]::exists($AllYoutube_Media_Profile_Directory_Path)){
                    $null = Remove-Item $AllYoutube_Media_Profile_Directory_Path -Force -ErrorAction SilentlyContinue
                    [void][System.IO.File]::Delete($AllYoutube_Media_Profile_Directory_Path)
                  }
                  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Youtube_Tabitem){
                    write-ezlogs "Setting YoutubeTable itemssource to null and removing Youtube media library tab" -showtime -warning -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'ItemsSource' -value $Null -ClearValue
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MainGrid_Bottom_TabControl' -Property 'items' -Method 'Remove' -Method_Value $syncHash.Youtube_Tabitem
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'isEnabled' -value $false  
                    $synchash.All_Youtube_Media = $Null        
                  }                
                } 
                if($thisapp.Config.Import_Twitch_Media){
                  if($hashsetup.Remove_TwitchMedia_Sources){
                    $All_TwitchMedia_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml')
                    if([System.IO.File]::Exists($All_TwitchMedia_File_Path)){
                      write-ezlogs ">>>> Importing All Twitch Media profile cache to remove twitch media sources at $All_TwitchMedia_File_Path" -showtime -logtype Setup
                      $all_Twitchmedia_profile = Import-SerializedXML -Path $All_TwitchMedia_File_Path
                      #[System.Collections.Generic.List[Object]]$all_Twitchmedia_profile = Import-Clixml $All_TwitchMedia_File_Path
                    }
                    [System.Collections.Generic.List[Object]]$all_Twitchmedia_profile = $all_Twitchmedia_profile | where {$hashSetup.Twitchplaylists_toRemove.id -notcontains $_.id}
                    write-ezlogs ">>>> Saving updated All Twitch Media profile cache at $All_TwitchMedia_File_Path" -showtime -logtype Setup
                    Export-SerializedXML -InputObject $all_Twitchmedia_profile -Path $All_TwitchMedia_File_Path
                    #Export-Clixml -InputObject ([System.Collections.Generic.List[Object]]$all_Twitchmedia_profile) -path $All_TwitchMedia_File_Path -Force -Encoding Default
                  }
                  if($hashsetup.Update_TwitchMedia_Sources -or $hashsetup.Remove_TwitchMedia_Sources){
                    write-ezlogs ">>>> Executing Import-Twitch to update media library - Number of Playlists: $(($thisapp.Config.Twitch_Playlists).count)" -logtype Setup
                    Import-Twitch -Twitch_playlists $thisapp.Config.Twitch_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh
                  }     
                }else{
                  $AllTwitch_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisapp.config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml')        
                  if([System.IO.File]::exists($AllTwitch_Media_Profile_Directory_Path)){
                    [void][System.IO.File]::Delete($AllTwitch_Media_Profile_Directory_Path)
                  }
                  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Twitch_Tabitem){
                    write-ezlogs "Setting TwitchTable itemssource to null and removing Twitch media library tab" -showtime -warning -logtype Setup
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'TwitchTable' -Property 'ItemsSource' -value $Null -ClearValue
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MainGrid_Bottom_TabControl' -Property 'items' -Method 'Remove' -Method_Value $syncHash.Twitch_Tabitem
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'TwitchTable' -Property 'isEnabled' -value $false
                    $synchash.All_Twitch_Media = $Null             
                  }                
                }                           
              }
            }
            $hashsetup.Update_LocalMedia_Sources = $false
            $hashsetup.Update_YoutubeMedia_Sources = $false
            $hashsetup.Update_SpotifyMedia_Sources = $false
            $hashsetup.Remove_SpotifyMedia_Sources = $false
            $hashsetup.Remove_YoutubeMedia_Sources = $false
            $hashsetup.Remove_TwitcheMedia_Sources = $false
            $hashsetup.Update_TwitchMedia_Sources = $false
            $hashsetup.Remove_LocalMedia_Sources = $false
          }catch{
            write-ezlogs "An exception occurred closing Show-SettingsWindow window" -showtime -catcherror $_
          } 
        }
      }.GetNewClosure()
      $hashsetup.Window.Add_Closing($hashsetup.Window_Closing_Command)
      #---------------------------------------------- 
      #endregion Window Closing Event
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Window Closed Event
      #---------------------------------------------- 
      $hashsetup.Window_Closed_Command = {
        param($Sender)    
        if($sender -eq $hashsetup.Window){    
          #$hashsetup.Canceled = $true
          try{
            $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'enumerate_files_Scriptblock' -force
          }catch{
            write-ezlogs " An exception occurred stopping existing runspace 'enumerate_files_Scriptblock'" -showtime -catcherror $_
          }          
          try{
            if(($hashsetup.Update -or $hashsetup.Canceled -or $hashsetup.Accepted)){
              write-ezlogs "Show-SettingsWindow Closed" -showtime
            }else{
              write-ezlogs "Show-SettingsWindow was not closed with either the cancel button or Save button, exiting" -showtime -warning -logtype Setup
              Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs -thisApp $thisApp -globalstopwatch $globalstopwatch         
              Stop-Process $pid 
              exit 
            }             
          }catch{
            write-ezlogs "An exception occurred closing Show-SettingsWindow window" -showtime -catcherror $_
            return
          }          
        }
      }
      $hashsetup.Window.Add_Closed($hashsetup.Window_Closed_Command)  
      #---------------------------------------------- 
      #endregion Window Closed Event
      #----------------------------------------------   

      #---------------------------------------------- 
      #region Window Unloaded Event
      #----------------------------------------------
      $hashsetup.Window_Unloaded_Command = {
        param($Sender) 
        try{
          write-ezlogs ">>>>> Settings window has unloaded" -logtype Setup -loglevel 2
          if($hashsetup.SnapShots_Hyperlink){
            [void](Get-EventHandlers -Element $hashsetup.SnapShots_Hyperlink -RoutedEvent ([System.Windows.Documents.Hyperlink]::ClickEvent) -RemoveHandlers)
          }
          if($hashsetup.Log_Path_Hyperlink){
            [void](Get-EventHandlers -Element $hashsetup.Log_Path_Hyperlink -RoutedEvent ([System.Windows.Documents.Hyperlink]::ClickEvent) -RemoveHandlers)
          }  
          $hashsetup.MouseDown_Command = $null
          $hashsetup.Next_Button_Command = $null
          $hashsetup.Prev_Button_Command = $Null
          $hashsetup.TabControlSelectionChanged_Command = $Null
          $hashsetup.Help_Flyout_OpenChanged_Command = $Null
          $hashsetup.Start_Tray_only_Click_Command = $Null
          $hashsetup.Start_Mini_only_Button_Click_Command = $null
          $hashsetup.Minimize_To_Tray_Button_Click_Command = $Null
          $hashsetup.Start_On_Windows_Login_Button_Click_Command = $Null
          $hashsetup.Save_Setup_Button_Click_Command = $Null
          $hashsetup.Cancel_Setup_Button_Click_Command = $null
          $hashsetup.Window.Remove_Closed($hashsetup.Window_Closed_Command)
          $hashsetup.Window_Closed_Command = $Null
          $hashsetup.Window.Remove_Closing($hashsetup.Window_Closing_Command)
          $hashsetup.Window_Closing_Command = $Null
          [void](Get-EventHandlers -Element $hashsetup.Window -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers)
          $hashsetup.Window_Loaded_Command = $Null
          [void](Get-EventHandlers -Element $hashsetup.Window -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers)
          $hashsetup.Window_Unloaded_Command = $Null
          $hashkeys = [System.Collections.ArrayList]::new($hashsetup.keys)
          $hashkeys | & { process {
              if($hashsetup.$_ -is [System.Windows.DependencyObject]){
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Removing all data bindings from: $($_)" -Dev_mode}
                [void][System.Windows.Data.BindingOperations]::ClearAllBindings($hashsetup.$_)
              }
              if($hashsetup.$_ -is [System.Windows.Controls.Button]){
                [void](Get-EventHandlers -Element $hashsetup.$_ -RoutedEvent ([System.Windows.Controls.Button]::ClickEvent) -RemoveHandlers)
              }elseif($hashsetup.$_ -is [MahApps.Metro.Controls.ToggleSwitch]){
                if($hashsetup."$($_)_Command"){
                  if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Removing command: $($_)_Command - from element: $($hashsetup.$_) with name: $($hashsetup.$_.name)" -Dev_mode}
                  $hashsetup.$_.Remove_Toggled($hashsetup."$($_)_Command")
                  $hashsetup."$($_)_Command" = $Null
                }else{
                  write-ezlogs ">>>> Couldn't find toggle command for element: $($hashsetup.$_) with name: $($hashsetup.$_.name)" -warning
                }
              }elseif($hashsetup.$_ -is [System.Windows.Controls.ComboBox]){
                [void](Get-EventHandlers -Element $hashsetup.$_ -RoutedEvent ([System.Windows.Controls.ComboBox]::SelectionChangedEvent) -RemoveHandlers)
              }elseif($hashsetup.$_ -is [System.Windows.Threading.DispatcherTimer]){
                if($hashsetup.$_.IsEnabled){
                  write-ezlogs ">>>> Stopping running timer ScriptBlock: $($_)" -warning
                  $hashsetup.$_.stop()
                }
                if($hashsetup."$($_)_ScriptBlock"){
                  if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Removing ScriptBlock: $($_)_ScriptBlock - from DispatcherTimer: $($_)" -Dev_mode}
                  $hashsetup.$_.Remove_Tick($hashsetup."$($_)_ScriptBlock")
                  $hashsetup."$($_)_ScriptBlock" = $Null
                  $hashsetup.$_ = $Null
                }
              }elseif($hashsetup.$_ -is [System.Windows.Controls.TextBox]){
                [void](Get-EventHandlers -Element $hashsetup.$_ -RoutedEvent ([System.Windows.Controls.TextBox]::TextChangedEvent) -RemoveHandlers)
              }
              if($hashsetup.Window.FindName($_)){
                if($thisApp.Config.Dev_mode){write-ezlogs -text ">>>> Unregistering Setup UI name: $_" -Dev_mode}
                [void]$Sender.UnRegisterName($_)
                [void]$hashsetup.Remove($_)

              }
              if($hashsetup.$_ -is [System.Collections.Concurrent.ConcurrentQueue`1[object]]){
                write-ezlogs ">>>> Removing ConcurrentQueue: $($_)"
                $hashsetup.$_ = $Null
              }
          }}
          $hashsetup.Window = $Null
          $hashkeys = $null
          if($hashsetup.appContext){
            write-ezlogs ">>>> Exiting AppContext threading" -logtype Setup -loglevel 2 -GetMemoryUsage -forceCollection
            $hashsetup.appContext.ExitThread()
            $hashsetup.appContext.dispose()
            $hashsetup.appContext = $Null
          }elseif($hashsetup.Use_runspace){
            write-ezlogs ">>>> Exiting current dispatcher threading" -logtype Setup -loglevel 2 -GetMemoryUsage -forceCollection
            [System.Windows.Threading.Dispatcher]::ExitAllFrames()
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
          }
          $hashsetup = $Null
        }catch{
          write-ezlogs "An exception occurred in Settings Window unloaded event" -catcherror $_
        }    
      }       
      $hashsetup.window.Add_Unloaded($hashsetup.Window_Unloaded_Command)  
      #---------------------------------------------- 
      #endregion Window Unloaded Event
      #----------------------------------------------
   
      #############################################################################
      #endregion Initialize UI Controls and Events
      ############################################################################# 
      
      #Initializate setting groups that will update UI controls and states
      Update-Settings -hashsetup $hashsetup -thisApp $thisApp -Startup
    }  
   
    #############################################################################
    #region Display Window
    #############################################################################
    try{
      if($Reload -and $hashsetup.Window.Visibility -in 'Hidden','Collapsed'){
        #Window is already initialized, load/reload all valid settings then display
        Update-Settings -hashsetup $hashsetup -thisApp $thisApp -Update:$Update -First_Run:$First_Run
        [void]$hashsetup.Window.Dispatcher.InvokeAsync{  
          $hashsetup.window.Opacity = 1
          $hashsetup.window.Show()
          [void]$hashsetup.window.Activate()
        }.Wait()
      }else{
        #Load/apply all settings to UI controls
        Update-Settings -hashsetup $hashsetup -thisApp $thisApp -Update:$Update -First_Run:$First_Run
        $setup_ShowUI_Measure = [system.diagnostics.stopwatch]::StartNew()
        if(!$startHidden){         
          $hashsetup.window.Opacity = 1
          [void]$hashsetup.window.Show()
          [void]$hashsetup.window.Activate()
        }else{
          write-ezlogs ">>>> Starting First Run/Settings as hidden" -showtime -logtype Setup
          #Trick to prerender window without showing it - Set opacity to 0, show to render, then hide
          $hashsetup.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
          $hashsetup.window.Opacity = 0
          [void]$hashsetup.Window.Dispatcher.InvokeAsync{$hashsetup.window.Show()}.Wait()          
          $hashsetup.window.Hide()
          $hashsetup.window.ShowActivated = $true

          #TODO: Alternate prerender trick - doesnt really provide any benefit in testing - Remove if above trick working fine
          #$hashsetup.window.Measure([System.Windows.Size]::new([Double]::PositiveInfinity,[Double]::PositiveInfinity));
          #$hashsetup.window.Arrange([System.Windows.Rect]::new([System.Windows.Size]::new($hashsetup.window.ActualWidth,$hashsetup.window.ActualHeight)));
        }
        if($setup_ShowUI_Measure){
          $setup_ShowUI_Measure.stop()   
          write-ezlogs ">>>> Setup_ShowUI_Measure" -PerfTimer $setup_ShowUI_Measure
          $setup_ShowUI_Measure = $Null
        }
        if($setup_TotalStart_Measure){
          $setup_TotalStart_Measure.stop()
          write-ezlogs ">>>> Setup_TotalStart_Measure" -PerfTimer $setup_TotalStart_Measure
          $setup_TotalStart_Measure = $Null
        }    
        #Allow keyboard input to window for TextBoxes, etc              
        [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashsetup.Window) 

        #Use ApplicationContext for threading instead of a new [Dispatcher]::Run() so we dont override apps main UI thread if not using runspace
        if($Use_runspace){
          [System.Windows.Threading.Dispatcher]::Run()
        }elseif($First_Run){
          $hashsetup.appContext = [Windows.Forms.ApplicationContext]::new()
          [void][System.Windows.Forms.Application]::Run($hashsetup.appContext)
        }   
      }
    }catch{
      write-ezlogs "An exception occurred when opening main Show-SettingsWindow window" -showtime -CatchError $_
      [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      if($First_Run){
        #If critical error occurs during first run, inform user and die to prevent potential settings corruption
        Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs -thisApp $thisApp -globalstopwatch $globalstopwatch
        [void][System.Windows.Forms.MessageBox]::Show("An exception occurred when opening main Show-SettingsWindow window for ($($thisApp.Config.App_name) Media Player - Version: $($thisApp.Config.App_Version) - PID: $($pid))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.`n`nThis app will now close","CRITICAL ERROR - $($thisApp.Config.App_name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)                
        Stop-Process $pid
      }else{
        #If not first run, app may still function on error but inform user things are very bad
        [void][System.Windows.Forms.MessageBox]::Show("An exception occurred when opening main Show-SettingsWindow window for ($($thisApp.Config.App_name) Media Player - Version: $($thisApp.Config.App_Version) - PID: $($pid))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.","CRITICAL ERROR - $($thisApp.Config.App_name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)    
      }       
    } 
    #############################################################################
    #endregion Display Window
    #############################################################################     
  }
  if($Use_runspace){
    #Execute UI in a new thread
    #[void]$PSBoundParameters.Add('hashsetup',$hashsetup)
    Start-Runspace $FirstRun_Scriptblock -Variable_list $PSBoundParameters -StartRunspaceJobHandler -runspace_name 'Show-SettingsWindow_Runspace' -logfile $thisApp.Config.Log_File -thisApp $thisApp -synchash $synchash -verboselog
  }else{
    #Execute UI in main thread - will block all other execution - good during First Run setup
    write-ezlogs ">>>> Starting setup without runspace" -showtime -logtype Setup
    Invoke-Command -ScriptBlock $FirstRun_Scriptblock
  } 
}
#---------------------------------------------- 
#endregion Show-SettingsWindow Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-Settings Function
#----------------------------------------------
function Update-Settings {
  <#
          
      .SYNOPSIS
      Updates app setting properties and related UI window controls.

      .DESCRIPTION
      Executes scriptblocks to update or reload various settings and related wpf controls asyncronously within the settings window dispatcher thread. There is a scriptblock for setting group corresponding to each page/tab. General, Local Media, Spotify, Youtube and Twitch. Each scriptblock is then queued and executed via Update-SettingsWindow

      .PARAMETER hashsetup
      Synchronized hashtable holding the settings UI window and controls

      .PARAMETER thisApp
      Synchronized hashtable holding the settings properties for the app

      .PARAMETER startup
      Bool: Creates the required scriptblocks to be executed later within the UI dispatcher via Update-SettingsWindow. Must be created in same thread as UI

      .PARAMETER First_Run
      Bool: Indicates if settings instance is executing for the first time during First Run setup

      .EXAMPLE
      PS> Update-Settings -hashsetup $hashsetup -thisApp $thisApp -Startup

      .EXAMPLE
      PS> Update-Settings -hashsetup $hashsetup -thisApp $thisApp -Update -First_Run

  #>
  Param (
    $hashsetup,
    $thisApp,
    [switch]$Update,
    [switch]$First_Run,
    [switch]$verboselog,
    [switch]$use_Runspace,
    [switch]$Startup
  )
  try{
    $Update_Settings_Timer = [system.diagnostics.stopwatch]::StartNew()    
    if($Startup){
      #############################################################################
      #region General Settings 
      #############################################################################
      if(!$hashSetup.General_Settings_Scriptblock){
        $hashSetup.General_Settings_Scriptblock = {
          Param (
            $hashsetup = $hashSetup,
            $thisApp = $thisApp,
            [switch]$Update = $Update,
            [switch]$First_Run = $First_Run,
            [switch]$verboselog = $verboselog,
            [switch]$use_Runspace = $use_Runspace,
            [switch]$Startup = $Startup
          )  
          try{  
            $setup_GeneralSettings_Measure = [system.diagnostics.stopwatch]::StartNew()
            #---------------------------------------------- 
            #region Start Tray Only
            #----------------------------------------------
            $hashsetup.Start_Tray_only_Toggle.IsOn = $thisApp.config.Start_Tray_only -eq $true   
            #---------------------------------------------- 
            #endregion Start Tray Only
            #----------------------------------------------

            #---------------------------------------------- 
            #region Start Mini Only
            #----------------------------------------------
            $hashsetup.Start_Mini_only_Toggle.IsOn = $thisApp.config.Start_Mini_only -eq $true
            #---------------------------------------------- 
            #endregion Start Mini Only
            #----------------------------------------------

            #---------------------------------------------- 
            #region Minimize To Tray
            #----------------------------------------------
            $hashsetup.Minimize_To_Tray_Toggle.IsOn = $thisApp.config.Minimize_To_Tray -eq $true
            #---------------------------------------------- 
            #endregion Minimize To Tray
            #----------------------------------------------

            #---------------------------------------------- 
            #region Disable Tray
            #----------------------------------------------
            if($thisApp.config.Disable_Tray){
              $hashsetup.Disable_Tray_Toggle.IsOn = $true
              $thisapp.config.Minimize_To_Tray = $false
              $thisApp.config.Start_Tray_only = $false
              $hashsetup.Minimize_To_Tray_Toggle.IsEnabled = $false
              $hashsetup.Minimize_To_Tray_Toggle.IsOn = $false
              $hashsetup.Start_Tray_only_Toggle.IsEnabled = $false
              $hashsetup.Start_Tray_only_Toggle.IsOn = $false  
            }else{
              $hashsetup.Disable_Tray_Toggle.IsOn = $false
              $hashsetup.Minimize_To_Tray_Toggle.IsEnabled = $true
              $hashsetup.Start_Tray_only_Toggle.IsEnabled = $true
            }
            #----------------------------------------------
            #endregion Disable Tray
            #----------------------------------------------

            #---------------------------------------------- 
            #region Start on Windows Login
            #----------------------------------------------
            $hashsetup.Start_On_Windows_Login_Toggle.isOn = $thisapp.config.Start_On_Windows_Login -eq $true
            #---------------------------------------------- 
            #endregion Start on Windows Login
            #----------------------------------------------

            #---------------------------------------------- 
            #region Verbose Logging
            #----------------------------------------------
            $hashsetup.Verbose_logging_Toggle.IsOn = $thisapp.config.Dev_mode -eq $true
            if($thisapp.config.Dev_mode){
              $hashsetup.Log_label_transitioningControl.content = $hashsetup.Log_label_transitioningControlContent
              $hashsetup.Verbose_logging_Toggle.isOn = $true
              $hashsetup.Log_StackPanel.Height = [Double]::NaN
              $hashsetup.Log_Path_textbox.text = $thisapp.Config.Log_file  
              $hashsetup.Log_Path_Label.IsEnabled = $true      
              $hashsetup.Log_Path_textbox.IsEnabled = $true     
              $hashsetup.Log_Path_Browse.IsEnabled = $true  
            }
            else{
              $hashsetup.Verbose_logging_Toggle.isOn = $false
              $hashsetup.Log_label_transitioningControl.content = ''
              $hashsetup.Log_StackPanel.Height = '5'      
              $hashsetup.Log_Path_Label.IsEnabled = $false       
              $hashsetup.Log_Path_textbox.IsEnabled = $false     
              $hashsetup.Log_Path_Browse.IsEnabled = $false  
            }
            #---------------------------------------------- 
            #endregion Verbose Logging
            #----------------------------------------------

            #---------------------------------------------- 
            #region Notification_Audio
            #----------------------------------------------
            $hashsetup.Notification_Audio_Toggle.isOn = $thisapp.config.Notification_Audio -eq $true
            #---------------------------------------------- 
            #endregion Notification_Audio
            #----------------------------------------------
 
            #---------------------------------------------- 
            #region Snapshots
            #----------------------------------------------
            $hashsetup.SnapShots_Hyperlink.inlines.clear()
            $hashsetup.SnapShots_Toggle.isOn = $thisApp.Config.Video_Snapshots -eq $true
            $hashsetup.App_SnapShots_Toggle.isOn = $thisApp.Config.App_Snapshots -eq $true
            if([system.io.directory]::Exists($thisapp.config.Snapshots_Path)){
              $hashsetup.SnapShots_textbox.text = $thisapp.config.Snapshots_Path   
              $hashsetup.SnapShots_Label.BorderBrush = 'LightGreen'   
              $hashsetup.SnapShots_Hyperlink.Inlines.add("Open Snapshots Folder")
              $hashsetup.SnapShots_Hyperlink.NavigateUri = [uri]$thisapp.config.Snapshots_Path
            }else{
              $hashsetup.SnapShots_Label.BorderBrush = 'Red'
              $hashsetup.SnapShots_textbox.text = ''
              $hashsetup.SnapShots_Hyperlink.inlines.clear()
              $hashsetup.SnapShots_Hyperlink.NavigateUri = $Null
            }
            #---------------------------------------------- 
            #endregion Snapshots
            #----------------------------------------------

            #---------------------------------------------- 
            #region Performance Mode
            #----------------------------------------------
            $hashsetup.Performance_Mode_Toggle.isOn = $thisApp.Config.Enable_Performance_Mode -eq $true
            #---------------------------------------------- 
            #endregion Performance Mode
            #----------------------------------------------
        
            #---------------------------------------------- 
            #region High DPI
            #----------------------------------------------
            if($hashsetup.High_DPI_Toggle){
              $hashsetup.High_DPI_Toggle.isOn = $thisApp.Config.Enable_HighDPI -eq $true
            }
            #---------------------------------------------- 
            #endregion High DPI
            #----------------------------------------------

            #---------------------------------------------- 
            #region Use Hardware Acceleration
            #----------------------------------------------
            $hashsetup.Use_HardwareAcceleration_Toggle.isOn = $thisapp.config.Use_HardwareAcceleration -eq $true
            #---------------------------------------------- 
            #endregion Use Hardware Acceleration
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_WebEQSupport
            #Toggling displays message to user to install/uninstall vb-cable if not already - See related toggle routed event
            #----------------------------------------------
            $hashsetup.Enable_WebEQSupport_Toggle.isOn = $thisapp.config.Enable_WebEQSupport -eq $true
            #---------------------------------------------- 
            #endregion Enable_WebEQSupport
            #----------------------------------------------

            #---------------------------------------------- 
            #region Show Notifications
            #----------------------------------------------
            $hashsetup.Show_Notifications_Toggle.isOn = $thisapp.config.Show_Notifications -eq $true
            #---------------------------------------------- 
            #endregion Show Notifications
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_Marquee
            #----------------------------------------------
            $hashsetup.Enable_Marquee_Toggle.isOn = $thisapp.config.Enable_Marquee -eq $true
            #---------------------------------------------- 
            #endregion Enable_Marquee
            #----------------------------------------------  
    
            #---------------------------------------------- 
            #region Open_VideoPlayer
            #----------------------------------------------
            $hashsetup.Open_VideoPlayer_Toggle.isOn = $thisapp.config.Open_VideoPlayer -eq $true
            #---------------------------------------------- 
            #endregion Open_VideoPlayer
            #----------------------------------------------    

            #---------------------------------------------- 
            #region Remember_Playback_Progress
            #----------------------------------------------
            $hashsetup.Remember_Playback_Progress_Toggle.isOn = $thisapp.config.Remember_Playback_Progress -eq $true
            #---------------------------------------------- 
            #endregion Remember_Playback_Progress
            #----------------------------------------------

            #---------------------------------------------- 
            #region Start_Paused
            #----------------------------------------------
            $hashsetup.Start_Paused_Toggle.isOn = $thisapp.config.Start_Paused -eq $true
            #---------------------------------------------- 
            #endregion Start_Paused
            #----------------------------------------------

            #---------------------------------------------- 
            #region Use_Visualizations
            #----------------------------------------------
            $hashsetup.Use_Visualizations_Toggle.isOn = $thisapp.config.Use_Visualizations -eq $true
            $hashsetup.Current_Visualization_ComboBox.isEnabled = $thisapp.config.Use_Visualizations -eq $true
            #---------------------------------------------- 
            #endregion Use_Visualizations
            #----------------------------------------------

            #---------------------------------------------- 
            #region Current_Visualization
            #----------------------------------------------
            if($thisapp.config.Current_Visualization){
              if($thisapp.config.Current_Visualization -eq 'Visual'){
                $selected_Visualization = 'Spectrum'
              }else{
                $selected_Visualization = $thisapp.config.Current_Visualization
              }
              $hashsetup.Current_Visualization_Label.BorderBrush = 'LightGreen'
              $hashsetup.Current_Visualization_ComboBox.selecteditem = $selected_Visualization
            }else{
              $hashsetup.Current_Visualization_Label.BorderBrush = 'Red'
              $hashsetup.Current_Visualization_ComboBox.Selectedindex = -1
            }
            #---------------------------------------------- 
            #endregion Current_Visualization
            #----------------------------------------------

            #---------------------------------------------- 
            #region Audio_Output
            #----------------------------------------------
            $hashsetup.Audio_Output_transitioningControl.content = ''
            try{
              $AudioDevices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.DeviceState]::Active)
              if($AudioDevices){
                foreach($device in $AudioDevices){
                  if($hashsetup.Audio_Output_ComboBox.items -notcontains $device.FriendlyName){
                    write-ezlogs "| Adding detected audio output device: $($device.FriendlyName)" -showtime -logtype Setup
                    [void]$hashsetup.Audio_Output_ComboBox.items.add($device.FriendlyName)
                  }
                }
              }else{
                write-ezlogs "Unable to enumerate any valid Audio Output Devices on this system!" -showtime -warning -logtype Setup
                $hashsetup.Audio_Output_transitioningControl.Height='30'
                $hashsetup.Audio_Output_textblock.text = 'Unable to find any valid Audio Output Devices on this system! This app will be pretty useless without some kind of sound output'
                $hashsetup.Audio_Output_textblock.foreground = 'Orange'
                $hashsetup.Audio_Output_transitioningControl.content = $hashsetup.Audio_Output_textblock
              }
              if($thisapp.config.Current_Audio_Output -and $hashsetup.Audio_Output_ComboBox.selecteditem -ne $thisapp.config.Current_Audio_Output){
                $hashsetup.Audio_Output_ComboBox.selecteditem = $thisapp.config.Current_Audio_Output
              }elseif($hashsetup.Audio_Output_ComboBox.selecteditem -ne 'Default'){
                $hashsetup.Audio_Output_ComboBox.selecteditem = 'Default'
              }
            }catch{
              write-ezlogs "An exception occurred initializing CSCore to enumerate Audio Output Devices" -showtime -catcherror $_
            }finally{
              if($AudioDevices){
                $AudioDevices.Dispose()
                $AudioDevices = $null
              }
            }
            #---------------------------------------------- 
            #endregion Audio_Output
            #----------------------------------------------

            #---------------------------------------------- 
            #region Discord Integration
            #----------------------------------------------
            $hashsetup.Discord_Integration_Toggle.isOn = $thisapp.config.Discord_Integration -eq $true
            #---------------------------------------------- 
            #endregion Discord Integration
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_Subtitles
            #----------------------------------------------
            $hashsetup.Enable_Subtitles_Toggle.isOn = $thisapp.config.Enable_Subtitles -eq $true
            #---------------------------------------------- 
            #endregion Enable_Subtitles
            #----------------------------------------------

            #---------------------------------------------- 
            #region Auto_UpdateCheck
            #----------------------------------------------
            if($thisApp.Enable_Update_Features -and $hashsetup.Auto_UpdateCheck_Toggle){
              $hashsetup.Auto_UpdateCheck_Toggle.isOn = $thisapp.config.Auto_UpdateCheck -eq $true
            }
            #---------------------------------------------- 
            #endregion Auto_UpdateCheck
            #----------------------------------------------

            #---------------------------------------------- 
            #region TODO:Media Control Hotkeys
            #----------------------------------------------
            foreach($Hotkey in $thisApp.Config.GlobalHotKeys){
              if($hotkey.Modifier -eq 'Shift'){
                $Modifier = [System.Windows.Input.ModifierKeys]::Shift
              }elseif($hotkey.Modifier -eq 'Alt'){
                $Modifier = [System.Windows.Input.ModifierKeys]::Alt
              }elseif($hotkey.Modifier -eq 'Control'){
                $Modifier = [System.Windows.Input.ModifierKeys]::Control
              }elseif($hotkey.Modifier -eq 'Windows'){
                $Modifier = [System.Windows.Input.ModifierKeys]::Windows
              }else{
                $Modifier = [System.Windows.Input.ModifierKeys]::None
              }
              if($hashsetup.$($hotkey.Name) -and [System.Windows.Input.Key]::($hotkey.key)){
                $hashsetup.$($hotkey.Name).Hotkey = [MahApps.Metro.Controls.HotKey]::new($hotkey.key,$Modifier)
              }elseif($hashsetup.$($hotkey.Name)){
                $hashsetup.$($hotkey.Name).Hotkey = $Null
              }
            }
            #---------------------------------------------- 
            #endregion TODO:Media Control Hotkeys
            #----------------------------------------------

            #---------------------------------------------- 
            #region Auto_UpdateInstall
            #----------------------------------------------
            $hashsetup.Auto_UpdateInstall_Toggle.isOn = $thisapp.config.Auto_UpdateInstall -eq $true
            #---------------------------------------------- 
            #endregion Auto_UpdateInstall
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_MediaCasting
            #----------------------------------------------
            $hashsetup.Enable_MediaCasting_Toggle.isOn = $thisapp.config.Use_MediaCasting -eq $true
            #---------------------------------------------- 
            #endregion Enable_MediaCasting
            #----------------------------------------------

            #---------------------------------------------- 
            #region Cast_HTTPPort
            #----------------------------------------------
            if(-not [string]::IsNullOrEmpty($thisapp.config.Cast_HTTPPort)){
              $hashsetup.Cast_HTTPPort_textbox.text = $thisapp.config.Cast_HTTPPort
            }else{
              $hashsetup.Cast_HTTPPort_textbox.text = ''
            }
            #---------------------------------------------- 
            #endregion Cast_HTTPPort
            #----------------------------------------------

            #---------------------------------------------- 
            #region Audio_OutputModule
            #----------------------------------------------
            if($hashsetup.Audio_OutputModule_ComboBox.selectedindex -ne -1){
              $hashsetup.Audio_OutputModule_Textbox.BorderBrush = 'LightGreen'
            }else{
              $hashsetup.Audio_OutputModule_Textbox.BorderBrush = 'Red'
            } 
            #---------------------------------------------- 
            #endregion Audio_OutputModule
            #----------------------------------------------

            #---------------------------------------------- 
            #region vlc_Arguments
            #----------------------------------------------
            if(-not [string]::IsNullOrEmpty($thisapp.config.Libvlc_Global_Gain)){
              $hashsetup.vlc_GlobalGain_textbox.text = $thisapp.config.Libvlc_Global_Gain
            }else{
              $hashsetup.vlc_GlobalGain_textbox.text = 4
            }
            #---------------------------------------------- 
            #endregion vlc_Arguments
            #----------------------------------------------

            #---------------------------------------------- 
            #region vlc_Arguments
            #----------------------------------------------
            if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
              $hashsetup.vlc_Arguments_textbox.text = $thisapp.config.vlc_Arguments
            }else{
              $hashsetup.vlc_Arguments_textbox.text = ''
            } 
            #---------------------------------------------- 
            #endregion vlc_Arguments
            #----------------------------------------------

            #---------------------------------------------- 
            #region Install_VPN
            #----------------------------------------------
            $hashsetup.VPN_Toggle.isOn = $thisapp.config.Use_Preferred_VPN -eq $true
            #---------------------------------------------- 
            #endregion Install_VPN
            #----------------------------------------------

            $setup_GeneralSettings_Measure.stop()
            write-ezlogs "| Setup_GeneralSettings_Measure" -showtime -logtype Setup -PerfTimer $setup_GeneralSettings_Measure -Perf
            $setup_GeneralSettings_Measure = $null        
          }catch{
            write-ezlogs "An exception occurred in General_Settings_Scriptblock" -catcherror $_
          }      
        }.GetNewClosure()
      }
      #############################################################################
      #endregion General Settings 
      ############################################################################# 

      #############################################################################
      #region Local Media 
      ############################################################################# 
      if(!$hashSetup.LocalMedia_Settings_Scriptblock){
        $hashSetup.LocalMedia_Settings_Scriptblock = {
          Param (
            $hashsetup = $hashSetup,
            $thisApp = $thisApp,
            [switch]$Update = $Update,
            [switch]$First_Run = $First_Run,
            [switch]$verboselog = $verboselog,
            [switch]$use_Runspace = $use_Runspace,
            [switch]$Startup = $Startup
          )  
          try{
            $setup_LocalMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
            if($hashSetup.LocalMedia_items){
              $hashSetup.LocalMedia_items.clear()
            }
            #---------------------------------------------- 
            #region Import_Local_Media
            #----------------------------------------------
            if($thisApp.Config.Import_Local_Media){
              $hashsetup.Import_Local_Media_Toggle.isOn = $true
              $hashsetup.Media_Path_Browse.IsEnabled = $true
              $hashsetup.MediaLocations_Grid.IsEnabled = $true
              if($hashsetup.MediaLocations_Grid.items){
                [void]$hashsetup.MediaLocations_Grid.items.clear()
              }
              $hashsetup.MediaLocations_Grid.Itemssource = $Null
              if(@($thisApp.Config.Media_Directories).count -gt 0){
                Update-MediaLocations -hashsetup $hashsetup -thisapp $thisApp -synchash $synchash -Directories $thisApp.Config.Media_Directories -SetItemssource -Startup:$Update
              }
            }  
            #---------------------------------------------- 
            #endregion Import_Local_Media
            #----------------------------------------------

            #---------------------------------------------- 
            #region SkipDuplicates
            #----------------------------------------------
            $hashsetup.LocalMedia_SkipDuplicates_Toggle.isOn = $thisApp.Config.LocalMedia_SkipDuplicates -eq $true
            #---------------------------------------------- 
            #endregion SkipDuplicates
            #----------------------------------------------

            #---------------------------------------------- 
            #region LocalMedia_ImportMode
            #----------------------------------------------
            try{
              $LocalMedia_ImportMode_Default = 'Fast' 
              if(-not [string]::IsNullOrEmpty($thisapp.config.LocalMedia_ImportMode)){   
                $hashsetup.LocalMedia_ImportMode_ComboBox.SelectedItem = $thisapp.config.LocalMedia_ImportMode
                $hashsetup.LocalMedia_ImportMode_Textbox.BorderBrush = 'Green'      
              }else{
                $thisapp.config.LocalMedia_ImportMode = $LocalMedia_ImportMode_Default
                $hashsetup.LocalMedia_ImportMode_ComboBox.SelectedItem = $LocalMedia_ImportMode_Default
                $hashsetup.LocalMedia_ImportMode_Textbox.BorderBrush = 'Green'
              }
            }catch{
              write-ezlogs 'An exception occurred processing LocalMedia_ImportMode options' -showtime -catcherror $_
            }
            #---------------------------------------------- 
            #endregion LocalMedia_ImportMode
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_LocalMedia_Monitor
            #----------------------------------------------
            $hashsetup.Enable_LocalMedia_Monitor_Toggle.isOn = $thisApp.Config.Enable_LocalMedia_Monitor -eq $true
            try{
              $LocalMedia_MonitorMode_Default = 'All'
              if(-not [string]::IsNullOrEmpty($thisapp.config.LocalMedia_MonitorMode)){   
                $hashsetup.LocalMedia_MonitorMode_ComboBox.SelectedItem = $thisapp.config.LocalMedia_MonitorMode
                $hashsetup.LocalMedia_MonitorMode_Textbox.BorderBrush = 'Green'      
              }else{
                Add-Member -InputObject $thisapp.config -Name 'LocalMedia_MonitorMode' -Value $LocalMedia_MonitorMode_Default -MemberType NoteProperty -Force
                $hashsetup.LocalMedia_MonitorMode_ComboBox.SelectedItem = $LocalMedia_MonitorMode_Default
                $hashsetup.LocalMedia_MonitorMode_Textbox.BorderBrush = 'Green'
              }
            }catch{
              write-ezlogs 'An exception occurred processing LocalMedia_MonitorMode options' -showtime -catcherror $_
            }
            #---------------------------------------------- 
            #endregion Enable_LocalMedia_Monitor
            #----------------------------------------------    
          
            #---------------------------------------------- 
            #region LocalMedia_Display_Syntax
            #----------------------------------------------
            try{
              $hashsetup.LocalMedia_Display_Syntax_textbox.text = $thisApp.Config.LocalMedia_Display_Syntax
            }catch{
              write-ezlogs 'An exception occurred setting LocalMedia_Display_Syntax_Textbox' -showtime -catcherror $_
            }
            #---------------------------------------------- 
            #endregion LocalMedia_Display_Syntax
            #----------------------------------------------                             
          }catch{
            write-ezlogs "An exception occurred in General_Settings_Scriptblock" -catcherror $_
          }finally{
            if($setup_LocalMedia_Measure){
              $setup_LocalMedia_Measure.stop()
              write-ezlogs "| Setup_LocalMedia_Measure" -showtime -logtype Setup -PerfTimer $setup_LocalMedia_Measure -perf
              $setup_LocalMedia_Measure = $Null          
            } 
          }      
        }.GetNewClosure()
      }
      #############################################################################
      #endregion Local Media 
      ############################################################################# 

      #############################################################################
      #region Spotify Media 
      ############################################################################# 
      if(!$hashSetup.SpotifyMedia_Settings_Scriptblock){
        $hashSetup.SpotifyMedia_Settings_Scriptblock = {
          Param (
            $hashsetup = $hashSetup,
            $thisApp = $thisApp,
            [switch]$Update = $Update,
            [switch]$First_Run = $First_Run,
            [switch]$verboselog = $verboselog,
            [switch]$use_Runspace = $use_Runspace,
            [switch]$Startup = $Startup
          )  
          try{
            $Setup_Spotify_Measure = [system.diagnostics.stopwatch]::StartNew()
            #---------------------------------------------- 
            #region Spicetify Options
            #----------------------------------------------
            $hashsetup.Spicetify_textblock.text = ''
            $hashsetup.Spicetify_transitioningControl.content = ''
            if($thisapp.config.Use_Spicetify){
              $hashsetup.Spicetify_Status = $true
              $hashsetup.Spicetify_Toggle.ison = $true
              $hashsetup.Spicetify_Remove_Button.IsEnabled = $false
            }else{
              $hashsetup.Spicetify_Status = $true
              $hashsetup.Spicetify_Toggle.ison = $false
              $hashsetup.Spicetify_Remove_Button.IsEnabled = $true
            }
            #---------------------------------------------- 
            #endregion Spicetify Options
            #----------------------------------------------

            #---------------------------------------------- 
            #region Spotify WebPlayer
            #----------------------------------------------
            $hashsetup.Spotify_WebPlayer_transitioningControl.Height = '0'
            if($thisapp.config.Spotify_WebPlayer){
              $hashsetup.Spotify_WebPlayer_Toggle.isOn = $true
              if($thisApp.Config.Use_Spicetify){
                $thisApp.Config.Use_Spicetify = $false
              }
              if($hashsetup.Spicetify_Toggle){
                $hashsetup.Spicetify_Toggle.isOn = $false
              }
            }else{
              $hashsetup.Spotify_WebPlayer_Toggle.isOn = $false
              if($hashsetup.Spicetify_Toggle -and $thisApp.Config.Use_Spicetify){
                $hashsetup.Spicetify_Toggle.isOn = $true   
              }
            }
            #---------------------------------------------- 
            #endregion Spotify WebPlayer
            #----------------------------------------------

            #---------------------------------------------- 
            #region Import_Spotify_Media
            #----------------------------------------------
            if($thisApp.Config.Import_Spotify_Media){
              if($hashsetup.SpotifyPlaylists_Grid.items){
                $hashsetup.SpotifyPlaylists_Grid.items.clear()
              }
              $hashsetup.Import_Spotify_textbox.inlines.clear()
              $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
              $hashsetup.Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
              if(!$hashsetup.Spotify_Auth_app.token.access_token -and !$First_Run){
                write-ezlogs "Unable to get Spotify authentication, starting spotify authentication setup process" -showtime -warning -logtype Setup                
                if($hashsetup.Spotify_Auth_app.token.access_token){
                  try{
                    $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp
                  }catch{
                    write-ezlogs "[Show-SettingsWindow] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_ -enablelogs
                  }                
                  if($playlists){
                    $foundplaylists = 0
                    foreach($playlist in $playlists){              
                      $playlisturl = $playlist.uri
                      $playlistName = $playlist.name
                      if($hashsetup.SpotifyPlaylists_Grid.items.path -notcontains $playlisturl){
                        write-ezlogs "Adding Spotify Playlist URL $playlisturl" -showtime -logtype Setup -LogLevel 3
                        Update-SpotifyPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'SpotifyPlaylist' -Playlist_Info $playlist -VerboseLog:$thisApp.Config.Verbose_logging
                        $foundplaylists++
                      }else{
                        write-ezlogs "The Spotify Playlist URL $playlisturl has already been added!" -showtime -warning -logtype Setup
                      }
                    }
                    Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                    $hashsetup.Spotify_Playlists_Import.isEnabled = $true
                    $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
                    $hashsetup.Install_Spotify_Toggle.isEnabled = $true
                    $hashsetup.Spotify_Auth_Status = $true
                    write-ezlogs "Authenticated to Spotify and retrieved Playlists" -showtime -color green -logtype Setup -Success                           
                  }else{
                    write-ezlogs "Unable to successfully authenticate to spotify!" -showtime -warning -logtype Setup
                    Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                    $hashsetup.Spotify_Playlists_Import.isEnabled = $false
                    $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                    $hashsetup.Install_Spotify_Toggle.isEnabled = $false
                    $hashsetup.Spotify_Auth_Status = $false            
                  }
                }else{
                  $hashsetup.Update_SpotifyStatus_Timer.start()
                  write-ezlogs "Unable to authenticate with Spotify API -- Spotify_Auth_app.token.access_token was null -- cannot enable Spotify integration" -showtime -warning -logtype Setup        
                }
              }else{
                write-ezlogs "[Show-SettingsWindow:Startup] Returned Spotify application" -showtime -Success -logtype Setup -LogLevel 2
                $hashsetup.Import_Spotify_textbox.isEnabled = $true
                $hashsetup.Spotify_Playlists_Import.isEnabled = $true
                $hashsetup.Spotify_Auth_Status = $true
                $hashsetup.Import_Spotify_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Spotify_textbox.text = ''
                $hashsetup.Import_Spotify_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Spotify_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Spotify_textbox.isEnabled = $true
                $hyperlink = 'https://Spotify_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $link_hyperlink.FontWeight = "Bold"
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Spotify_AuthHandler)
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add("If you wish to update or change your Spotify credentials, click ")  
                [void]$hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
                $hashsetup.Import_Spotify_textbox.FontSize = '14'
                $hashsetup.Import_Spotify_transitioningControl.Height = '60'
                $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
                $hashsetup.Install_Spotify_Toggle.isEnabled = $true
              } 
              try{
                if($synchash.all_playlists){
                  foreach($playlist in $synchash.all_playlists){
                    if(($playlist.gettype()).name -eq 'ArrayList'){
                      $playlist = $playlist | select *
                    }
                    if($playlist.playlist_tracks.Values.Playlist_URL){
                      $playlist_urls = $playlist.PlayList_tracks.values.Playlist_URL.where({$_ -match 'spotify\:playlist'})
                    }
                    foreach($url in $playlist_urls){
                      if($thisApp.Config.Spotify_Playlists -notcontains $url){
                        write-ezlogs "| Found custom playlist to add to Spotify media library: $url" -showtime -logtype Setup -loglevel 2
                        [void]$thisApp.Config.Spotify_Playlists.add($url)
                      }
                    }
                  }
                }       
              }catch{
                write-ezlogs "[Show-SettingsWindow] An exception occurred parsing custom playlists for Spotify at $($playlist)" -showtime -catcherror $_
              }
              if(@($thisApp.Config.Spotify_Playlists).count -gt 0){
                foreach($playlist in $thisApp.Config.Spotify_Playlists){
                  if($playlist -match "playlist\:" -or $playlist -match '\/playlist\/'){
                    if($playlist -match "playlist\:"){
                      $id = ($($playlist) -split('playlist:'))[1].trim() 
                    }elseif($playlist -match '\/playlist\/'){
                      $id = ($($playlist) -split('\/playlist\/'))[1].trim() 
                    }
                    $type = 'Playlist' 
                    $Name = "Custom_$id"        
                  }elseif($playlist -match "track\:" -or $playlist -match '\/track\/'){
                    if($playlist -match "track\:"){
                      $id = ($($playlist) -split('track:'))[1].trim()
                    }elseif($playlist -match '\/track\/'){
                      $id = ($($playlist) -split('\/track\/'))[1].trim() 
                    }
                    $Name = "Custom_$id"   
                    $type = 'Track'  
                    $playlist_info = $Null                    
                  }elseif($playlist -match "episode"){
                    if($playlist -match 'episode\:'){
                      $id = ($($playlist) -split('episode:'))[1].trim()  
                    }elseif($playlist -match '\/episode\/'){
                      $id = ($($playlist) -split('\/episode\/'))[1].trim()  
                    } 
                    $Name = "Custom_$id"        
                    $type = 'Episode'   
                    $playlist_info = $Null                
                  }elseif($playlist -match "show"){  
                    if($playlist -match 'episode\:'){
                      $id = ($($playlist) -split('show:'))[1].trim() 
                    }elseif($playlist -match '\/show\/'){
                      $id = ($($playlist) -split('\/show\/'))[1].trim()  
                    } 
                    $Name = "Custom_$id"
                    $type = 'Show' 
                    $playlist_info = $Null                  
                  } 
                  if($id -match '\?si\='){
                    $id = ($($id) -split('\?si\='))[0].trim()
                  }
                  if([System.IO.File]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($id).xml")){
                    try{
                      $playlist_profile = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($id).xml"
                      write-ezlogs ">>>> Importing Spotify Playlist profile: $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($id).xml"  -logtype Setup -LogLevel 3
                      write-ezlogs " | Spotify Playlist Name: $($playlist_Profile.Name)"  -logtype Setup -LogLevel 3
                      $Name = $playlist_Profile.Name
                      $type = $playlist_Profile.type
                      $playlist_Info = $playlist_Profile.Playlist_Info
                    }catch{
                      write-ezlogs "An exception occurred importing profile $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($id).xml" -showtime -catcherror $_
                    }         
                  }      
                  Update-SpotifyPlaylists -hashsetup $hashsetup -Path $playlist -id $id -type $type -Name $Name -playlist_info $playlist_info -VerboseLog:$thisApp.Config.Verbose_logging
                }
              }
            }
            #---------------------------------------------- 
            #endregion Import_Spotify_Media
            #----------------------------------------------

            #---------------------------------------------- 
            #region Install Spotify
            #----------------------------------------------
            try{
              if($thisApp.Config.Install_Spotify){
                if($psversiontable.PSVersion.Major -gt 5 -and ![System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
                  try{
                    write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning -logtype Setup
                    if(!(get-command Get-appxpackage -ErrorAction SilentlyContinue)){
                      Import-module Appx -usewindowspowershell -DisableNameChecking -ErrorAction SilentlyContinue
                    }            
                  }catch{
                    write-ezlogs "[SETUP] An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
                  }
                }
                $hashsetup.Install_Spotify_Toggle.isOn = $true
                if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
                  $appinstalled = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
                }elseif((Get-appxpackage 'Spotify*' -ErrorAction SilentlyContinue)){
                  write-ezlogs ">>>> Spotify installed as appx" -showtime -logtype Setup -loglevel 2
                  $spotifyApx = $true
                  $appinstalled = (Get-ItemProperty "$((Get-appxpackage 'Spotify*').InstallLocation)\Spotify.exe").VersionInfo.ProductVersion
                }else{
                  $appinstalled = $false
                }
                if($appinstalled){
                  $hashsetup.Install_Spotify_Status_textblock.text = "INSTALLED:`n$appinstalled"
                  $hashsetup.Install_Spotify_Status_textblock.Foreground = 'LightGreen'
                }else{
                  $hashsetup.Install_Spotify_Status_textblock.text = "NOT INSTALLED"
                  $hashsetup.Install_Spotify_Status_textblock.Foreground = 'Orange'
                }
              }else{
                $hashsetup.Install_Spotify_Toggle.isOn = $false
                $hashsetup.Install_Spotify_Status_textblock.text = ""
              }
            }catch{
              write-ezlogs "An exception occurred processing Install_Spotify options" -showtime -catcherror $_
            }
            #---------------------------------------------- 
            #endregion Install Spotify
            #----------------------------------------------

            #---------------------------------------------- 
            #region Spotify Updates
            #----------------------------------------------
            if($thisapp.config.Spotify_Update){
              $hashsetup.Spotify_Update_Toggle.isOn = $true
              $hashsetup.Spotify_Update_Interval_ComboBox.IsEnabled = $true
            }else{
              $hashsetup.Spotify_Update_Toggle.isOn = $false
              $hashsetup.Spotify_Update_Interval_ComboBox.IsEnabled = $false
            }
            #---------------------------------------------- 
            #endregion Spotify Updates
            #----------------------------------------------

            #---------------------------------------------- 
            #region Spotify Update Interval
            #----------------------------------------------
            if($thisapp.config.Spotify_Update_Interval){
              try{
                if($thisapp.config.Spotify_Update_Interval -eq 'On Startup'){
                  $content = $thisapp.config.Spotify_Update_Interval
                }else{
                  $interval = [TimeSpan]::Parse($thisapp.config.Spotify_Update_Interval)
                  if($interval.TotalMinutes -ge 60){$content = "$($interval.TotalHours) Hour"}else{$content = "$($interval.TotalMinutes) Minutes"}
                }
                if($content -ne $null){
                  $hashsetup.Spotify_Update_Interval_ComboBox.SelectedItem = $hashsetup.Spotify_Update_Interval_ComboBox.items | where {$_.content -eq $content}
                  $hashsetup.Spotify_Update_Interval_Label.BorderBrush = 'Green'
                }
              }catch{
                write-ezlogs 'An exception occurred parsing Spotify Update Interval' -showtime -catcherror $_
              }
            }else{
              $hashsetup.Spotify_Update_Interval_ComboBox.SelectedIndex = -1
              $hashsetup.Spotify_Update_Interval_Label.BorderBrush = 'Red'
            } 
            #---------------------------------------------- 
            #endregion Spotify Update Interval
            #----------------------------------------------   
          }catch{
            write-ezlogs "An exception occurred in SpotifyMedia_Settings_Scriptblock" -catcherror $_
          }finally{
            if($Setup_Spotify_Measure){
              $Setup_Spotify_Measure.stop()
              write-ezlogs "| Setup_Spotify_Measure" -showtime -logtype Setup -PerfTimer $Setup_Spotify_Measure -Perf
              $Setup_Spotify_Measure = $Null
            }        
          }      
        }.GetNewClosure()
      }
      #############################################################################
      #endregion Spotify Media 
      ############################################################################# 

      #############################################################################
      #region Youtube Media 
      ############################################################################# 
      if(!$hashSetup.YoutubeMedia_Settings_Scriptblock){
        $hashSetup.YoutubeMedia_Settings_Scriptblock = {
          Param (
            $hashsetup = $hashSetup,
            $thisApp = $thisApp,
            [switch]$Update = $Update,
            [switch]$First_Run = $First_Run,
            [switch]$verboselog = $verboselog,
            [switch]$use_Runspace = $use_Runspace,
            [switch]$Startup = $Startup
          )  
          try{
            $Setup_Youtube_Measure = [system.diagnostics.stopwatch]::StartNew()
            #---------------------------------------------- 
            #region Youtube WebPlayer
            #----------------------------------------------
            $hashsetup.Youtube_WebPlayer_transitioningControl.content = ''
            $hashsetup.Youtube_WebPlayer_transitioningControl.Height = 0
            if($thisapp.config.Youtube_WebPlayer){
              $hashsetup.Youtube_WebPlayer_Toggle.isOn = $true
              $hashsetup.Use_invidious_Toggle.IsEnabled = $true
              if($thisApp.Config.Use_invidious){
                $hashsetup.Use_invidious_Toggle.isOn = $true
              }else{
                $hashsetup.Use_invidious_Toggle.isOn = $false
              }
            }else{
              $hashsetup.Youtube_WebPlayer_Toggle.isOn = $false
              $hashsetup.Use_invidious_Toggle.IsEnabled = $false
            }
            #---------------------------------------------- 
            #endregion Youtube WebPlayer
            #----------------------------------------------

            #---------------------------------------------- 
            #region Use_invidious
            #----------------------------------------------
            if($thisApp.Config.Use_invidious){
              $hashsetup.Use_invidious_Toggle.isOn = $true
              $hashsetup.Use_invidious_grid.BorderBrush = 'LightGreen' 
            }else{
              $hashsetup.Use_invidious_Toggle.isOn = $false
              $hashsetup.Use_invidious_grid.BorderBrush = 'Red'
            }
            #---------------------------------------------- 
            #endregion Use_invidious
            #----------------------------------------------

            #---------------------------------------------- 
            #region Youtube Updates
            #----------------------------------------------
            $hashsetup.Youtube_Update_Toggle.isOn = ($thisapp.config.Youtube_Update -eq $true)
            #---------------------------------------------- 
            #endregion Youtube Updates
            #----------------------------------------------

            #---------------------------------------------- 
            #region Youtube Update Interval
            #----------------------------------------------
            if($thisapp.config.Youtube_Update_Interval){
              try{
                if($thisapp.config.Youtube_Update_Interval -eq 'On Startup'){
                  $content = $thisapp.config.Youtube_Update_Interval
                }else{
                  $interval = [TimeSpan]::Parse($thisapp.config.Youtube_Update_Interval)
                  if($interval.TotalMinutes -ge 60){$content = "$($interval.TotalHours) Hour"}else{$content = "$($interval.TotalMinutes) Minutes"}
                }
                if($content -ne $null){
                  $hashsetup.Youtube_Update_Interval_ComboBox.SelectedItem = $hashsetup.Youtube_Update_Interval_ComboBox.items | where {$_.content -eq $content}
                  $hashsetup.Youtube_Update_Interval_Label.BorderBrush = 'Green'
                }
              }catch{
                write-ezlogs 'An exception occurred parsing Youtube Update Interval' -showtime -catcherror $_
              }
            }else{
              $hashsetup.Youtube_Update_Interval_ComboBox.SelectedIndex = -1
              $hashsetup.Youtube_Update_Interval_Label.BorderBrush = 'Red'
            }
            #---------------------------------------------- 
            #endregion Youtube Update Interval
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable Sponsorblock
            #----------------------------------------------
            if($thisapp.config.Enable_Sponsorblock){
              $hashsetup.Enable_Sponsorblock_Toggle.isOn = $true
              $hashsetup.Sponsorblock_ActionType_ComboBox.IsEnabled = $true
            }else{
              $hashsetup.Enable_Sponsorblock_Toggle.isOn = $false
              $hashsetup.Sponsorblock_ActionType_ComboBox.IsEnabled = $false
            }
            #---------------------------------------------- 
            #endregion Enable Sponsorblock
            #----------------------------------------------

            #---------------------------------------------- 
            #region Sponsorblock ActionType
            #----------------------------------------------
            try{
              if($thisApp.Config.Sponsorblock_ActionType -ne $null){
                $hashsetup.Sponsorblock_ActionType_ComboBox.SelectedItem = $hashsetup.Sponsorblock_ActionType_ComboBox.items | where {$_.content -eq $thisApp.Config.Sponsorblock_ActionType}
              }else{
                $hashsetup.Sponsorblock_ActionType_ComboBox.SelectedIndex = 0
              }      
            }catch{
              write-ezlogs 'An exception occurred parsing Sponsorblock ActionType' -showtime -catcherror $_
            }
            #---------------------------------------------- 
            #endregion Sponsorblock ActionType
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable YoutubeComments
            #----------------------------------------------
            if($hashsetup.Enable_YoutubeComments_Toggle){
              $hashsetup.Enable_YoutubeComments_Toggle.isOn = $thisapp.config.Enable_YoutubeComments -eq $true
            }
            #---------------------------------------------- 
            #endregion Enable YoutubeComments
            #----------------------------------------------

            #---------------------------------------------- 
            #region PlayLink_OnDrop
            #----------------------------------------------
            $hashsetup.PlayLink_OnDrop_Toggle.isOn = $thisapp.config.PlayLink_OnDrop -eq $true
            #---------------------------------------------- 
            #endregion PlayLink_OnDrop
            #----------------------------------------------

            #---------------------------------------------- 
            #region Youtube_Quality
            #----------------------------------------------
            if($thisapp.config.Youtube_Quality){
              $hashsetup.Youtube_Quality_ComboBox.selecteditem = $thisapp.config.Youtube_Quality
            }else{
              $hashsetup.Youtube_Quality_ComboBox.selecteditem = 'Auto'
            }
            if($hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Best' -or $hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Auto'){
              $hashsetup.Youtube_Quality_Label.BorderBrush = 'LightGreen'
            }elseif($hashsetup.Youtube_Quality_ComboBox.selecteditem -eq 'Medium'){
              $hashsetup.Youtube_Quality_Label.BorderBrush = 'Gray'
            }else{
              $hashsetup.Youtube_Quality_Label.BorderBrush = 'Red'
            }
            #---------------------------------------------- 
            #endregion Youtube_Quality
            #----------------------------------------------

            #---------------------------------------------- 
            #region Webview2 Extensions
            #----------------------------------------------
            try{
              Get-Webview2Extensions -thisApp $thisApp
            }catch{
              write-ezlogs "An exception occurred adding webview2 extensions to config" -catcherror $_
            }
            #---------------------------------------------- 
            #endregion Webview2 Extensions
            #----------------------------------------------

            #---------------------------------------------- 
            #region Import_Youtube_Media
            #----------------------------------------------
            if($hashSetup.YoutubePlaylists_itemsArray){
              $hashSetup.YoutubePlaylists_itemsArray.clear()
            }       
            if($hashsetup.Import_Youtube_textbox.Inlines){
              $hashsetup.Import_Youtube_textbox.Inlines.clear()
            }
            if($thisApp.Config.Import_Youtube_Media){
              if(@($thisApp.Config.Youtube_Playlists).count -gt 0){        
                foreach($playlist in $thisApp.Config.Youtube_Playlists){
                  if($hashSetup.YoutubePlaylists_itemsArray.Path -notcontains $playlist){
                    if($playlist -match 'youtube\.com' -or $playlist -match 'youtu\.be'){
                      if($playlist -match 'tv\.youtube'){
                        if($playlist -match "v="){
                          $id = ($($playlist) -split('v='))[1].trim() 
                        }elseif($playlist -match "\/watch\/"){
                          $id = ($($playlist) -split('/watch/'))[1].trim() 
                        }
                        $Name = "Custom_$id"
                        $type = "YoutubeTV"
                      }elseif($playlist -match "v="){
                        $id = ($($playlist) -split('v='))[1].trim()  
                        $type = 'YoutubeVideo' 
                        $Name = "Custom_$id"        
                      }elseif($playlist -match 'list='){
                        $id = ($($playlist) -split('list='))[1].trim() 
                        $Name = "Custom_$id"   
                        $type = 'YoutubePlaylist'                      
                      }elseif($playlist -match 'youtube\.com\/channel\/'){
                        $id = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower())) 
                        $Name = "Custom_$id"
                        $type = 'YoutubeChannel'
                      }elseif($playlist -match "\/watch\/"){
                        $id = [regex]::matches($playlist, "\/watch\/(?<value>.*)")| %{$_.groups[1].value}
                        $Name = "Custom_$id"
                        $type = 'YoutubeVideo'
                      }elseif($playlist -match 'twitch\.tv'){
                        $id = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower())) 
                        $Name = $id
                        $type = 'TwitchChannel'
                      }elseif($playlist -notmatch "v=" -and $playlist -notmatch '\?' -and $playlist -notmatch '\&'){
                        $id = ([uri]$playlist).segments | select -last 1
                        $Name = "Custom_$id"
                        $type = 'YoutubeVideo'
                      }
                    }elseif($playlist -match "soundcloud\.com"){
                      $id = ([uri]$playlist).segments | select -last 1
                      $Name = "Custom_$id"
                      $type = 'Soundcloud'
                    }
                    if([System.IO.File]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($id).xml")){
                      try{
                        $playlist_profile = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($id).xml"
                        $Name = $playlist_Profile.Name
                        $type = $playlist_Profile.type
                        $playlist_Info = $playlist_Profile.Playlist_Info
                      }catch{
                        write-ezlogs "An exception occurred importing profile $($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($id).xml" -showtime -catcherror $_
                      }         
                    } 
                    if(!$hashSetup.YoutubePlaylists_itemsArray.Number){ 
                      $Number = 1
                    }else{
                      $Number = $hashSetup.YoutubePlaylists_itemsArray.Number | select -last 1
                      $Number++
                    }
                    [void]$hashSetup.YoutubePlaylists_itemsArray.add([PSCustomObject]@{
                        Number=$Number;       
                        ID = $id
                        Name=$Name
                        Path=$playlist
                        Type=$type
                        Playlist_Info = $playlist_info
                    }) 
                  }
                }
                try{
                  if($synchash.all_playlists){
                    foreach($playlist in $synchash.all_playlists){
                      if(($playlist.gettype()).name -eq 'ArrayList'){
                        $playlist = $playlist | select *
                      }
                      if($playlist.PlayList_tracks.values){
                        $PlayList_tracks = $playlist.PlayList_tracks.values.where({$_.Playlist_URL -match 'youtu\.be' -or $_ -match 'youtube\.com'})
                      }
                      foreach($list in $PlayList_tracks){      
                        $customplaylist_Name = $Null       
                        if($list.Playlist_URL){
                          $customplaylist_Name = $hashSetup.YoutubePlaylists_itemsArray | where {$_.path -eq $list.Playlist_URL}
                          if($customplaylist_Name.name -and $customplaylist_Name.name -ne $list.Playlist){
                            write-ezlogs "| Updating youtube playlist table name from: $($customplaylist_Name.name) - to: $($list.Playlist) - ID: $($list.playlist_id)" -showtime -logtype Setup -loglevel 2
                            $customplaylist_Name.Name = $list.Playlist
                          }
                        }
                      }
                    }
                  }
                }catch{
                  write-ezlogs "An exception occurred parsing custom playlists in $($thisApp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
                }
                $hashsetup.Update_YoutubePlaylists_Timer.tag = $hashSetup.YoutubePlaylists_itemsArray
                $hashsetup.Update_YoutubePlaylists_Timer.start()
              }
              try{
                $access_token = Get-secret -name YoutubeAccessToken -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
                $refresh_access_token = Get-secret -name Youtuberefresh_token -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
              }catch{
                write-ezlogs "An exception occurred getting refresh_access_token: $($refresh_access_token) or access_token: $($access_token) from Secret vault $($thisApp.Config.App_name)" -showtime -catcherror $_
                $retry = $true
              }
              if(-not [string]::IsNullOrEmpty($refresh_access_token)){
                $access_token_expires = Get-secret -name Youtubeexpires_in -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
              }else{
                write-ezlogs "Unable to find Youtube refresh_access_token - refresh_access_token: $($refresh_access_token) - access_token: $($access_token)" -showtime -warning -logtype Setup
              }
              if([string]::IsNullOrEmpty($access_token_expires) -or [string]::IsNullOrEmpty($access_token)){
                $hyperlink = 'https://Youtube_Auth'
                write-ezlogs "No valid Youtube authentication was found (Access_Token: $($access_token)) - (Access_token_expires: $($access_token_expires)) - (Refresh_access_token: $($refresh_access_token))" -showtime -logtype Setup -Warning
                $hashsetup.Import_Youtube_textbox.isEnabled = $true
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                $link_hyperlink.FontWeight = 'Bold'
                $hashsetup.Import_Youtube_Status_textbox.Text="[NONE]"
                $hashsetup.Import_Youtube_Status_textbox.Foreground = "Orange"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $hashsetup.Import_Youtube_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add(" to provide your Youtube account credentials.")   
                $hashsetup.Import_Youtube_textbox.Foreground = "Orange"
                $hashsetup.Import_Youtube_transitioningControl.Height = '60'
                $hashsetup.Youtube_Playlists_Import.isEnabled = $false
              }elseif([string]::IsNullOrEmpty($access_token_expires)){
                $hyperlink = 'https://Youtube_Auth'
                write-ezlogs "Found existing Youtube authentication, but they are expired and need to be refreshed: $($access_token_expires)" -showtime -warning -logtype Setup
                $hashsetup.Import_Youtube_Status_textbox.Text="[EXPIRED]"
                $hashsetup.Import_Youtube_Status_textbox.Foreground = "Orange"
                $hashsetup.Import_Youtube_textbox.isEnabled = $true
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                $hashsetup.Import_Youtube_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add(" to update your Youtube account credentials")   
                $hashsetup.Import_Youtube_textbox.Foreground = "Orange"
                $hashsetup.Import_Youtube_transitioningControl.Height = '60'
                $hashsetup.Youtube_Playlists_Import.isEnabled = $false    
              }else{
                write-ezlogs "Returned Youtube authentication - (Expires: $($access_token_expires))" -showtime -logtype Setup -LogLevel 2 -Success
                $hashsetup.Import_Youtube_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Youtube_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Youtube_textbox.isEnabled = $true
                $hyperlink = 'https://Youtube_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashSetup.Youtube_AuthHandler)
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add("If you wish to update or change your Youtube credentials, click ") 
                [void]$hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))
                $hashsetup.Import_Youtube_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Youtube_textbox.FontSize = '14'
                $hashsetup.Import_Youtube_transitioningControl.Height = '60'
                $hashsetup.Youtube_Playlists_Import.isEnabled = $true
              }
              $hashsetup.Import_Youtube_Playlists_Toggle.Tag = 'Startup'
              $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $true
              $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true
              $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
              $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true
              $hashsetup.YoutubePlaylists_Grid.MaxHeight = '250'                 
            }else{
              $hashsetup.YoutubePlaylists_Grid.MaxHeight = '0'
              $hashsetup.Import_Youtube_textbox.text = ""
              $hashsetup.Import_Youtube_transitioningControl.Height = '0'
              $hashsetup.Youtube_Playlists_Import.isEnabled = $false
            } 
            #---------------------------------------------- 
            #endregion Import_Youtube_Media
            #----------------------------------------------

            #---------------------------------------------- 
            #region Youtube_Browser
            #----------------------------------------------
            if($thisApp.config.Youtube_Browser){     
              $hashsetup.Import_Youtube_Auth_ComboBox.selecteditem = $hashsetup.Import_Youtube_Auth_ComboBox.items | where {$_.content -eq $thisApp.config.Youtube_Browser}
            }else{
              $hashsetup.Import_Youtube_Auth_ComboBox.selectedindex = -1
            } 
            if($hashsetup.Import_Youtube_Auth_ComboBox.selectedindex -ne -1){     
              $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Green"
            }else{
              $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Red"
            } 
            if($thisApp.config.Import_Youtube_Browser_Auth){     
              $hashsetup.Import_Youtube_Auth_Toggle.isOn = $true
              $hashsetup.Import_Youtube_Auth_ComboBox.IsEnabled = $true
            }else{
              $hashsetup.Import_Youtube_Auth_Toggle.isOn = $false
              $hashsetup.Import_Youtube_Auth_ComboBox.IsEnabled = $false
            } 
            #---------------------------------------------- 
            #endregion Youtube_Browser
            #----------------------------------------------  
    
            #---------------------------------------------- 
            #region Import_My_Youtube
            #----------------------------------------------
            $hashsetup.Youtube_My_Playlists_Import.isChecked = $thisApp.Config.Import_My_Youtube_Media -eq $true
            #---------------------------------------------- 
            #endregion Import_My_Youtube
            #----------------------------------------------
          
            #---------------------------------------------- 
            #region Youtube_My_Subscriptions
            #----------------------------------------------
            $hashsetup.Youtube_My_Subscriptions_Import.isChecked = $thisApp.Config.Import_My_Youtube_Subscriptions -eq $true
            #---------------------------------------------- 
            #endregion Youtube_My_Subscriptions
            #----------------------------------------------  
          }catch{
            write-ezlogs "An exception occurred in YoutubeMedia_Settings_Scriptblock" -catcherror $_
          }finally{
            if($Setup_Youtube_Measure){
              $Setup_Youtube_Measure.stop()
              write-ezlogs "| Setup_Youtube_Measure" -showtime -logtype Setup -PerfTimer $Setup_Youtube_Measure -Perf
              $Setup_Youtube_Measure = $Null
            }        
          }      
        }.GetNewClosure()
      }      
      #############################################################################
      #endregion Youtube Media 
      #############################################################################

      #############################################################################
      #region Twitch Media 
      ############################################################################# 
      if(!$hashSetup.TwitchMedia_Settings_Scriptblock){
        $hashSetup.TwitchMedia_Settings_Scriptblock = {
          Param (
            $hashsetup = $hashSetup,
            $thisApp = $thisApp,
            [switch]$Update = $Update,
            [switch]$First_Run = $First_Run,
            [switch]$verboselog = $verboselog,
            [switch]$use_Runspace = $use_Runspace,
            [switch]$Startup = $Startup
          )  
          try{
            $Setup_Twitch_Measure = [system.diagnostics.stopwatch]::StartNew()
            #---------------------------------------------- 
            #region Twitch Updates
            #----------------------------------------------
            $hashsetup.Twitch_Update_Toggle.isOn = $thisapp.config.Twitch_Update -eq $true
            #---------------------------------------------- 
            #endregion Twitch Updates
            #----------------------------------------------

            #---------------------------------------------- 
            #region Twitch Update Interval
            #----------------------------------------------
            $hashsetup.Twitch_Update_transitioningControl.content = ''
            $hashsetup.Twitch_Update_textblock.text = ''
            if($thisapp.config.Twitch_Update_Interval){
              try{
                $interval = [TimeSpan]::Parse($thisapp.config.Twitch_Update_Interval).TotalMinutes
                if($interval -ge 60){$content = "$interval Hour"}else{$content = "$interval Minutes"}
                if($content -ne $null){
                  $hashsetup.Twitch_Update_Interval_ComboBox.SelectedItem = $hashsetup.Twitch_Update_Interval_ComboBox.items | where {$_.content -eq $content}
                  $hashsetup.Twitch_Update_Interval_Label.BorderBrush = 'Green'
                }
              }catch{
                write-ezlogs 'An exception occurred parsing Twitch Update Interval' -showtime -catcherror $_
              }
            }else{
              $hashsetup.Twitch_Update_Interval_ComboBox.SelectedIndex = -1
              $hashsetup.Twitch_Update_Interval_Label.BorderBrush = 'Red'
              $hashsetup.Twitch_Update_Toggle.isOn = $false
              $thisapp.config.Twitch_Update = $false
            }
            #---------------------------------------------- 
            #endregion Twitch Update Interval
            #----------------------------------------------

            #---------------------------------------------- 
            #region Enable_Twitch_Notifications
            #----------------------------------------------
            $hashsetup.Enable_Twitch_Notifications_Toggle.isOn = $thisapp.config.Enable_Twitch_Notifications -eq $true
            #---------------------------------------------- 
            #endregion Enable_Twitch_Notifications
            #----------------------------------------------

            #---------------------------------------------- 
            #region ForceUse_YTDLP
            #----------------------------------------------
            $hashsetup.ForceUse_YTDLP_Toggle.isOn = $thisapp.config.ForceUse_YTDLP -eq $true
            #---------------------------------------------- 
            #endregion ForceUse_YTDLP
            #----------------------------------------------

            #---------------------------------------------- 
            #region Skip_Twitch_Ads_Toggle
            #----------------------------------------------
            $hashsetup.Skip_Twitch_Ads_Toggle.isOn = $thisapp.config.Skip_Twitch_Ads -eq $true
            #---------------------------------------------- 
            #endregion Skip_Twitch_Ads_Toggle
            #----------------------------------------------

            #---------------------------------------------- 
            #region Mute_Twitch_Ads_Toggle
            #----------------------------------------------
            $hashsetup.Mute_Twitch_Ads_Toggle.isOn = $thisapp.config.Mute_Twitch_Ads -eq $true
            #---------------------------------------------- 
            #endregion Mute_Twitch_Ads_Toggle
            #----------------------------------------------

            #---------------------------------------------- 
            #region Twitch_TTVLOL
            #----------------------------------------------
            if($thisapp.config.Use_Twitch_TTVLOL){
              $hashsetup.Twitch_TTVLOL_Toggle.isOn = $true
              if($hashsetup.Twitch_luminous_Toggle.isOn){
                $hashsetup.Twitch_luminous_Toggle.isOn = $false
              }     
              if($thisapp.config.Use_Twitch_luminous){
                $thisapp.config.Use_Twitch_luminous = $false
              } 
              if($hashsetup.Twitch_Custom_Proxy_Toggle.isOn){
                $hashsetup.Twitch_Custom_Proxy_Toggle.isOn = $false               
              }
              $thisapp.config.UseTwitchCustom = $false                
            }else{
              $hashsetup.Twitch_TTVLOL_Toggle.isOn = $false
            }
            #---------------------------------------------- 
            #endregion Twitch_TTVLOL
            #----------------------------------------------

            #---------------------------------------------- 
            #region Twitch_Quality
            #----------------------------------------------
            if($thisapp.config.Twitch_Quality){
              $hashsetup.Twitch_Quality_ComboBox.selecteditem = $thisapp.config.Twitch_Quality
            }else{
              $hashsetup.Twitch_Quality_ComboBox.selecteditem = 'Best'
            }
            if($hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'Best' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '1080p' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '720p'){
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'LightGreen'
            }elseif($hashsetup.Twitch_Quality_ComboBox.selecteditem -eq '480p' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'Worst' -or $hashsetup.Twitch_Quality_ComboBox.selecteditem -eq 'audio_only'){
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'Gray'
            }else{
              $hashsetup.Twitch_Quality_Label.BorderBrush = 'Red'
            }
            #---------------------------------------------- 
            #endregion Twitch_Quality
            #----------------------------------------------

            #---------------------------------------------- 
            #region Streamlink_Interface
            #----------------------------------------------
            try{
              $Network_Adapter = (Get-CimInstance  -Class Win32_NetworkAdapterConfiguration).Where{$_.IPEnabled -and $_.IPaddress -and $_.DefaultIPGateway -notcontains '0.0.0.0'}
              [void]$hashsetup.Streamlink_Interface_ComboBox.items.clear()
              [void]$hashsetup.Streamlink_Interface_ComboBox.items.add('Default')
              [void]$hashsetup.Streamlink_Interface_ComboBox.items.add('Any')
              if($Network_Adapter.IPAddress){
                $Network_Adapter.IPAddress| & { process {
                    if($hashsetup.Streamlink_Interface_ComboBox.items -notcontains $_){
                      [void]$hashsetup.Streamlink_Interface_ComboBox.items.add("$_")
                    }
                }}
              }
              if($thisapp.config.Streamlink_Interface -and $hashsetup.Streamlink_Interface_ComboBox.items -contains $thisapp.config.Streamlink_Interface){
                $hashsetup.Streamlink_Interface_ComboBox.selecteditem = $thisapp.config.Streamlink_Interface
              }else{
                $hashsetup.Streamlink_Interface_ComboBox.selecteditem = 'Default'
              }
              $hashsetup.Streamlink_Interface_Label.BorderBrush = 'LightGreen'
            }catch{
              write-ezlogs "[Show-SettingsWindow] An exception occurred getting network adapters" -catcherror $_
            }finally{
              if($Network_Adapter -and $Network_Adapter[0] -is [System.IDisposable]){
                [void]$Network_Adapter.dispose()
              }
            }
            #---------------------------------------------- 
            #endregion Streamlink_Interface
            #----------------------------------------------

            #---------------------------------------------- 
            #region Streamlink_Arguments
            #----------------------------------------------
            if(-not [string]::IsNullOrEmpty($thisapp.config.Streamlink_Arguments)){
              $hashsetup.Streamlink_Arguments_textbox.text = $thisapp.config.Streamlink_Arguments
            }else{
              $hashsetup.Streamlink_Arguments_textbox.text = ''
            }
            #---------------------------------------------- 
            #endregion Streamlink_Arguments
            #----------------------------------------------

            #---------------------------------------------- 
            #region Streamlink_Logging
            #----------------------------------------------
            if(-not [string]::IsNullOrEmpty($thisapp.config.Streamlink_Verbose_logging)){
              $hashsetup.Streamlink_Logging_ComboBox.selecteditem = $thisapp.config.Streamlink_Verbose_logging
            }else{
              $hashsetup.Streamlink_Logging_ComboBox.selecteditem = 'info'
            }
            if($hashsetup.Streamlink_Logging_ComboBox.selectedindex -ne -1){
              $hashsetup.Streamlink_Logging_Label.BorderBrush = 'LightGreen'
            }else{
              $hashsetup.Streamlink_Logging_Label.BorderBrush = 'Red'
            } 
            #---------------------------------------------- 
            #endregion Streamlink_Logging
            #----------------------------------------------

            #---------------------------------------------- 
            #region Import_Twitch_Media
            #----------------------------------------------
            if($hashSetup.TwitchPlaylists_items){
              $hashSetup.TwitchPlaylists_items.clear()
            }
            if($hashsetup.Import_Twitch_textbox.Inlines){
              $hashsetup.Import_Twitch_textbox.Inlines.clear()
            }
            if($thisApp.Config.Import_Twitch_Media){
              if(@($thisApp.Config.Twitch_Playlists).count -gt 0){
                foreach($playlist in $thisApp.Config.Twitch_Playlists | where {$hashsetup.TwitchPlaylists_Grid.items.path -notcontains $_.path}){
                  if($playlist.Path -match 'twitch.tv'){
                    if($playlist.Name){
                      $Name = $playlist.Name
                    }else{
                      $Name = $((Get-Culture).textinfo.totitlecase(($playlist.path | split-path -leaf).tolower())) 
                    }             
                    $type = 'TwitchChannel'
                    Update-TwitchPlaylists -hashsetup $hashsetup -Path $playlist.path -id $playlist.Id -Number $playlist.Number -Followed $playlist.Followed -type $type -Name $Name -VerboseLog:$thisApp.Config.Verbose_logging
                  }       
                }
                Update-TwitchPlaylists -hashsetup $hashsetup -SetItemsSource -VerboseLog:$thisApp.Config.Verbose_logging
              }
              $TwitchApp = Get-TwitchApplication -Name $($thisApp.Config.App_name)
              if(([string]::IsNullOrEmpty($TwitchApp.token.access_token) -or [string]::IsNullOrEmpty($TwitchApp.token.expires))){
                $hyperlink = 'https://Twitch_Auth'
                write-ezlogs "No Twitch authentication returned (Expires: $($TwitchApp.token.access_token)) (Expires: $($TwitchApp.token.expires))" -warning -logtype Setup
                $hashsetup.Import_Twitch_textbox.isEnabled = $true
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"    
                $hashsetup.Import_Twitch_Status_textbox.Text="[NONE]"
                $hashsetup.Import_Twitch_Status_textbox.Foreground = "Orange"
                $hashsetup.Import_Twitch_textbox.Inlines.add("Click ")
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add(" to provide your Twitch account credentials.")   
                $hashsetup.Import_Twitch_textbox.Foreground = "Orange"
                $hashsetup.Import_Twitch_textbox.FontSize = '14'
                $hashsetup.Import_Twitch_transitioningControl.Height = '80'
                $hashsetup.Twitch_Playlists_Import.isEnabled = $false
                $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $false
              }else{
                write-ezlogs "Returned Twitch authentication (Expires: $($TwitchApp.token.expires))" -showtime -logtype Setup -Success -LogLevel 2
                $hashsetup.Import_Twitch_Status_textbox.Text="[VALID]"
                $hashsetup.Import_Twitch_Status_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Twitch_textbox.isEnabled = $true
                $hyperlink = 'https://Twitch_Auth'
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $hyperlink
                $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
                $link_hyperlink.Foreground = "LightBlue"
                [void]$link_hyperlink.Inlines.add("AUTHENTICATE")
                [void]$link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashsetup.Twitch_AuthHandler)
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add("If you wish to update or change your Twitch credentials, click ")  
                [void]$hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
                $hashsetup.Import_Twitch_textbox.Foreground = "LightGreen"
                $hashsetup.Import_Twitch_textbox.FontSize = '14'
                $hashsetup.Import_Twitch_transitioningControl.Height = '60'
                $hashsetup.Twitch_Playlists_Import.isEnabled = $true
                $hashsetup.Import_Twitch_Playlists_Toggle.tag = 'Startup'
                $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $true
              }                 
              $hashsetup.Twitch_Playlists_Browse.IsEnabled = $true
              $hashsetup.TwitchPlaylists_Grid.IsEnabled = $true
              $hashsetup.TwitchPlaylists_Grid.MaxHeight = '250'
            }else{
              $hashsetup.TwitchPlaylists_Grid.MaxHeight = '0'
              $hashsetup.Import_Twitch_textbox.text = ""
              $hashsetup.Import_Twitch_transitioningControl.Height = '0'
              $hashsetup.Twitch_Playlists_Import.isEnabled = $false
            }  
            #---------------------------------------------- 
            #endregion Import_Twitch_Media
            #---------------------------------------------- 
          }catch{
            write-ezlogs "An exception occurred in TwitchMedia_Settings_Scriptblock" -catcherror $_
          }finally{
            if($Setup_Twitch_Measure){
              $Setup_Twitch_Measure.stop()
              write-ezlogs "| Setup_Twitch_Measure" -showtime -logtype Setup -PerfTimer $Setup_Twitch_Measure -Perf
              $Setup_Twitch_Measure = $Null
            }                  
          }      
        }.GetNewClosure()
      }    
      #############################################################################
      #endregion Twitch Media 
      #############################################################################
    }else{
      try{
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisapp -ScriptBlock $hashSetup.General_Settings_Scriptblock -Dequeue
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisapp -ScriptBlock $hashSetup.LocalMedia_Settings_Scriptblock -Dequeue
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisapp -ScriptBlock $hashSetup.SpotifyMedia_Settings_Scriptblock -Dequeue
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisapp -ScriptBlock $hashSetup.YoutubeMedia_Settings_Scriptblock -Dequeue
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisapp -ScriptBlock $hashSetup.TwitchMedia_Settings_Scriptblock -Dequeue
      }catch{
        write-ezlogs "An exception occurred in Update-Settings" -catcherror $_
      }    
    }  
  }catch{
    write-ezlogs "An exception occurred in Update-Settings" -showtime -catcherror $_
  }finally{
    if($Update_Settings_Timer){
      $Update_Settings_Timer.stop()
      write-ezlogs ">>>> Update_Settings_Timer" -PerfTimer $Update_Settings_Timer -GetMemoryUsage -forceCollection
      $Update_Settings_Timer = $Null
    }  
  }   
}
#---------------------------------------------- 
#endregion Update-Settings Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-SettingsWindow','Update-EditorHelp','Update-SettingsWindow','Update-Settings','Update-MediaLocations','Update-SpotifyPlaylists','Update-TwitchPlaylists','Invoke-YoutubeImport')