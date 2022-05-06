<#
    .Name
    Get-Playlists

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Customized EZT-MediaPlayer Playlists

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
#region Get-Playlists Function
#----------------------------------------------
function Get-Playlists
{
 [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    $thisApp,
    $media_contextMenu,
    [switch]$Update_Current_Playlist,
    $all_available_Media,
    [string]$mediadirectory,
    [string]$Media_Profile_Directory,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    $Group,
    [System.Collections.Hashtable]$all_playlists,
    $thisScript,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    [switch]$Refresh_Spotify_Playlists,
    [switch]$Refresh_All_Playlists,
    [switch]$VerboseLog,
    [switch]$Import_Playlists_Cache
  )
  
  <#  if($Update_Current_Playlist){
      if($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}){
      $syncHash.PlayQueue_TreeView.Items.remove(($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}))
      }
      }else{
      $syncHash.PlayQueue_TreeView.Items.clear()
  }#>
  if($Verboselog){write-ezlogs "#### Executing Get-Playlists ####" -enablelogs -color yellow -linesbefore 1}
  $syncHash.PlayQueue_TreeView.items.Clear()
  $syncHash.Playlists_TreeView.items.Clear()
  $Media_ContextMenu = $synchash.Media_ContextMenu
  if($Import_Playlists_Cache){
    $all_playlists = [hashtable]::Synchronized(@{})
    $all_playlists.playlists = Import-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
  }elseif($startup -or (@($all_playlists).count -lt 2)){
    $all_playlists = [hashtable]::Synchronized(@{})
    $all_playlists.playlists = New-Object -TypeName 'System.Collections.ArrayList'
    (robocopy $Playlist_Profile_Directory 'Doesntexist' '*Playlist.xml' /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim() | foreach { 
      $profile_path = $null
      if([System.IO.File]::Exists($_)){
        $profile_path = $_
        if($Verboselog){write-ezlogs ">>>> Importing Playlist profile $profile_path" -showtime -enablelogs -color cyan}
        try{
          if([System.IO.File]::Exists($profile_path)){
            $Playlist_profile = Import-CliXml -Path $profile_path
          }          
        }catch{
          write-ezlogs "An exception occurred importing Playlist profile path ($profile_path)" -showtime -catcherror $_
        }             
        $Playlist_encodedTitle = $Playlist_profile.Playlist_ID
        if($Playlist_encodedTitle -and $all_playlists.Playlist_ID -notcontains $Playlist_encodedTitle){
          try{
            $Null = $all_playlists.playlists.Add($Playlist_profile)
          }catch{
            write-ezlogs "An exception occurred adding playlist ($Playlist_encodedTitle) from path $profile_path" -showtime -catcherror $_
          }
              
        }               
      }
    }
    $all_playlists.playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8
  }  
  if($thisApp.config.Current_Playlist.values){
    if($VerboseLog){
      write-ezlogs ">>>> Updating current play queue" -showtime -color cyan
      write-ezlogs " | Importing config file $($thisApp.Config.Config_Path)" -showtime
    }     
    $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
    $Current_Playlist = New-Object System.Windows.Controls.TreeViewItem
    $header = New-Object PsObject -Property @{
      'title' = 'Play Queue'
      'Status' = ''
      'FontStyle' = 'Normal'
      'FontColor' = 'White'
      'FontWeight' = 'Bold'
      'FontSize' = 12          
      'Status_Msg' = ''
      'Status_FontStyle' = ''
      'Status_FontColor' = ''
      'Status_FontWeight' = ''
      'Status_FontSize' = ''          
    }    
    $Current_Playlist.Name = 'Play_Queue'
    $Current_Playlist.isExpanded = $true     
    $Current_Playlist.Header = $header
    $Current_Playlist.Uid = "$($thisApp.Config.Current_Folder)\\Resources\\Material-AnimationPlayOutline.png"    
    $Current_Playlist.Tag = @{        
      synchash=$synchash;
      thisScript=$thisScript;
      thisApp=$thisApp
      PlayMedia_Command = $PlayMedia_Command
      PlaySpotify_Media_Command = $PlaySpotify_Media_Command
      Playlist = 'Play Queue'
      All_Playlists = $all_playlists
    }    
    $null = $Current_Playlist.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Media_ContextMenu)
    #write-ezlogs $($all_playlists.playlists | out-string)
    if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){$thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)}
    foreach($item in $thisApp.config.Current_Playlist.values){
      #$Track = $synchash.MediaTable.Items | where {$_.id -eq $item}
      #write-ezlogs "[Get-Playlists] | Looking for track with ID $($item)" -showtime 
      $Track = $all_playlists.playlists.Playlist_tracks | where {$_.id -eq $item} | select -Unique     
      if(!$Track){
        $Track = $synchash.MediaTable.items | where {$_.id -eq $item}
      }            
      if(!$Track){
        $Track = $synchash.SpotifyTable.items | where {$_.id -eq $item}
      }
      if(!$Track){
        $Track = $synchash.YoutubeTable.items | where {$_.id -eq $item}
      } 
      $playlist = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $item} | select -Unique   
      #write-ezlogs "[Get-Playlists] | Adding track $($track | out-string) to Play Queue" -showtime           
      if($Track.id){
        $Current_Playlist_ChildItem = New-Object System.Windows.Controls.TreeViewItem
        if($Track.Spotify_path){
          $Title = "$($Track.Artist_Name) - $($Track.Track_Name)"
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png"
        }elseif($Track.webpage_url -match 'twitch'){
          $Title = "$($Track.Title)"
          #$title = "Twitch Stream: $($track.Playlist)"
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Twitch.png"
        }elseif($Track.type -eq 'YoutubePlaylist_item'){
          $Title = "$($Track.Title)"
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube.png"
        }else{
          $Title = "$($Track.Artist) - $($Track.Title)"
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
        }
        if($Track.live_status -eq 'Offline'){
          $fontstyle = 'Italic'
          $fontcolor = 'Gray'
          $FontWeight = 'Normal'
          $FontSize = 12          
        }elseif($Track.live_status -eq 'Online' -or $Track.live_status -eq 'Live'){
          $fontstyle = 'Normal'
          $fontcolor = 'LightGreen'
          $FontWeight = 'Normal'
          $FontSize = 12         
        }else{
          $fontstyle = 'Normal'
          $fontcolor = 'White' 
          $FontWeight = 'Normal'
          $FontSize = 12                     
        }
        if($track.status_msg){
          $status_msg = $track.status_msg
          if($track.live_status -eq 'Offline'){
            $Status_fontcolor = 'Gray'
            $Status_fontstyle = 'Italic'
          }else{
            $Status_fontcolor = 'White'
            $Status_fontstyle = 'Normal'
          }          
          $Status_FontWeight = 'Normal'
          $Status_FontSize = 12
        }else{
          $status_msg = $null
          $Status_fontstyle = 'Normal'
          $Status_fontcolor = 'White' 
          $Status_FontWeight = 'Normal'
          $Status_FontSize = 12          
        }                    
        $header = New-Object PsObject -Property @{
          'title' = $title
          'ID' = $track.id
          'Status' = $Track.live_status
          'FontStyle' = $fontstyle
          'FontColor' = $fontcolor
          'FontWeight' = $FontWeight
          'FontSize' = $FontSize          
          'Status_Msg' = $status_msg
          'Status_FontStyle' = $Status_fontstyle
          'Status_FontColor' = $Status_fontcolor
          'Status_FontWeight' = $Status_FontWeight
          'Status_FontSize' = $Status_FontSize          
        }  
        #write-ezlogs "[Get-Playlists] | Adding $($title) with ID $($track.id) to Play Queue" -showtime      
        $Current_Playlist_ChildItem.Header = $header        
        $Current_Playlist_ChildItem.Name = 'Track'
        $Current_Playlist_ChildItem.Uid = $icon_path
        if($thisApp.config.Last_Played -eq $Track.id){
          #$Current_Playlist_ChildItem.IsSelected = $true
        }
        #$Current_Playlist_ChildItem.Tag = $Track
        $Current_Playlist_ChildItem.Tag = @{        
          synchash=$synchash;
          thisScript=$thisScript;
          thisApp=$thisApp
          PlayMedia_Command = $PlayMedia_Command
          All_Playlists = $all_playlists
          PlaySpotify_Media_Command = $PlaySpotify_Media_Command
          Media_ContextMenu = $Media_ContextMenu
          Media = $Track
        } 
        $Current_Playlist_ChildItem.add_KeyDown{
          param
          (
            [Parameter(Mandatory)][Object]$sender,
            [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
          )
          $synchash = $Sender.tag.synchash
          $thisApp = $Sender.tag.thisapp
          $thisScript = $Sender.tag.thisScript 
          $PlayMedia_Command = $sender.tag.PlayMedia_Command
          $all_playlists = $sender.tag.all_playlists
          $Playlist = $Sender.header          
          $Media = $sender.tag.Media 
          $PlaySpotify_Media_Command = $sender.tag.PlaySpotify_Media_Command
          $Media_ContextMenu = $sender.tag.Media_ContextMenu
          $Playlist = $e.Source.Parent.Header
          if($e.Key -eq 'Enter' -and $Media.url)
          {
            #write-ezlogs "Playlist $($e.Source.Parent.Header | out-string)" -showtime
            try{
              if($media.Spotify_Path){
                $media = $syncHash.SpotifyTable.items | where {$_.id -eq $Media.id} | select -Unique
                Play-SpotifyMedia -Media $Media -thisApp $thisApp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command 
              }else{
                Start-Media -Media $Media -thisApp $thisApp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command 
              }  
              #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
            }catch{
              write-ezlogs "An exception occurred attempting to play media using keyboard event $($e.Key | out-string) for media $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_
            }    
          }
          if($e.Key -eq 'Delete'-and $Media.url)
          {
            try{
              if($media.Spotify_Path){
                if($thisApp.config.Current_Playlist.values -contains $Media.encodedtitle){
                  write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
                  $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
                  $null = $thisApp.config.Current_Playlist.Remove($index_toremove) 
                }      
              }elseif($thisApp.config.Current_Playlist.values -contains $Media.id){
                write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
                $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
                $null = $thisApp.config.Current_Playlist.Remove($index_toremove)                 
              }
              $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
              Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -startup -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command  -all_playlists $all_playlists 
            }catch{
              write-ezlogs "An exception occurred removing media $($Media.id) from Playlist $($Playlist) using keyboard event $($e.Key | out-string)" -showtime -catcherror $_
            } 
          }    
        }               
        $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$PlayMedia_Command)
        $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Media_ContextMenu)        
        $null = $Current_Playlist.items.add($Current_Playlist_ChildItem)        
      }
    }   
    $null = $syncHash.PlayQueue_TreeView.Items.Add($Current_Playlist) 
    $syncHash.PlayQueue_TreeView.AllowDrop = $true   
  }  
  <#   $syncHash.PlayQueue_TreeView.add_SelectedItemChanged({

      write-ezlogs "This changed $($this | out-string)"
  }) #>
  $PreviewDrop = {
    [System.Object]$script:sender = $args[0]
    [System.Windows.DragEventArgs]$d = $args[1]  
    #write-ezlogs ">>>> $($d.OriginalSource | out-string)" -showtime -color cyan
    #write-ezlogs ">>>> $($d.Source | out-string)" -showtime -color cyan
    if($d.Data.GetDataPresent([Windows.Forms.DataFormats]::Text)){
      try{  
        $LinkDrop = $d.data.GetData([Windows.Forms.DataFormats]::Text) 
        if(-not [string]::IsNullOrEmpty($LinkDrop) -and (Test-url $LinkDrop)){
          if($LinkDrop -match 'twitch.tv'){
            $d.Handled = $true
            $twitch_channel = $((Get-Culture).textinfo.totitlecase(($LinkDrop | split-path -leaf).tolower()))
            write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $LinkDrop" -showtime -color cyan                       
          }elseif($LinkDrop -match 'youtube.com' -or $LinkDrop -match 'youtu.be'){
            write-ezlogs ">>>> Adding Youtube link $LinkDrop" -showtime -color cyan
            $d.Handled = $true
          }
          if($d.Handled){
            Import-Youtube -Youtube_URL $LinkDrop -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisApp
          }
          #close-splashscreen
          #$synchash.Window.Show()        
        }else{
          write-ezlogs "The provided URL is not valid or was not provided! -- $LinkDrop" -showtime -warning
        }                        
      }catch{
        write-ezlogs "An exception occurred in PreviewDrop" -showtime -catcherror $_
        #close-splashscreen
        #$synchash.Window.Show()
      }    
    }elseif($d.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){
      try{  
        $FileDrop = $d.Data.GetData([Windows.Forms.DataFormats]::FileDrop)  
        #foreach ($path in $FileDrop) {
        if(([System.IO.FIle]::Exists($FileDrop) -or [System.IO.Directory]::Exists($FileDrop))){
          #$synchash.Window.hide()
          #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage "Updating Media library..." -thisScript $thisScript -current_folder $Current_Folder -log_file $thisApp.Config.Log_file -Script_modules $Script_Modules
          #start-sleep 1      
          $d.Handled = $true  
          write-ezlogs ">>>> Adding Local Media $FileDrop" -showtime -color cyan
          Import-Media -Media_Path $FileDrop -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisApp
          #close-splashscreen
          #$synchash.Window.Show()        
        }else{
          write-ezlogs "The provided Path is not valid or was not provided! -- $FileDrop" -showtime -warning
        }          
        #}      
        #$path = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)                
      }catch{
        write-ezlogs "An exception occurred in PreviewDrop" -showtime -catcherror $_
        #close-splashscreen
        #$synchash.Window.Show()
      }    
    }elseif($d.data.GetDataPresent([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name)){       
      $item = $d.data.GetData([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name)
      $Media = $item.tag.Media
      $from_Playlist = $item.parent.Header  
      $to_Playlist_Name = $sender.items.Name
      $to_Playlist_Name = $d.source.parent.Header.title
      $From_Playlist_Name = $item.parent.Header.title
      $to_PlayList = $d.originalsource.datacontext
      write-ezlogs "From $($From_Playlist_Name | out-string)" -showtime
      #write-ezlogs "Media $($Media | out-string)" -showtime
      write-ezlogs "To Playlist Name $($to_Playlist_Name | out-string)" -showtime
      #write-ezlogs "Destination $($d.originalsource.datacontext | out-string)" -showtime
      if($to_Playlist_Name -eq 'Play Queue'){      
        <#        if($Media.Spotify_Path){
            if($thisApp.config.Current_Spotify_Playlist -notcontains $Media.id)
            {
            write-ezlogs " | Adding $($Media.id) to Spotify Play Queue" -showtime
            $null = $thisApp.config.Current_Spotify_Playlist.Add($Media.id)
            }      
        } #>  
        if($thisApp.config.Current_Playlist.values -notcontains $Media.id)
        {
          if($VerboseLog){write-ezlogs " | Adding $($Media.id) to Play Queue from Drag and Drop" -showtime}                  
          $Current_Playlist_ChildItem = New-Object System.Windows.Controls.TreeViewItem
          if($Media.Spotify_Path){         
            $Title = "$($media.Artist_Name) - $($media.Track_Name)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png"
            $click_command = $PlaySpotify_Media_Command
          }elseif($Media.webpage_url -match 'twitch'){
            $Title = "$($media.Title)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Twitch.png"
          }elseif($Media.type -eq 'YoutubePlaylist_item'){
            $Title = "$($media.Title)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube.png"
            $click_command = $PlayMedia_Command         
          }else{
            $Title = "$($media.Artist) - $($media.Title)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
            $click_command = $PlayMedia_Command
          }
          if($media.live_status -eq 'Offline'){
            $fontstyle = 'Italic'
            $fontcolor = 'Gray'
            $FontWeight = 'Normal'
            $FontSize = 12          
          }elseif($media.live_status -eq 'Online' -or $media.live_status -eq 'Live'){
            $fontstyle = 'Normal'
            $fontcolor = 'LightGreen'
            $FontWeight = 'Normal'
            $FontSize = 12         
          }else{
            $fontstyle = 'Normal'
            $fontcolor = 'White' 
            $FontWeight = 'Normal'
            $FontSize = 12                     
          }
          if($media.status_msg){
            $status_msg = $media.status_msg
            if($media.live_status -eq 'Offline'){
              $Status_fontcolor = 'Gray'
              $Status_fontstyle = 'Italic'
            }else{
              $Status_fontcolor = 'White'
              $Status_fontstyle = 'Normal'
            }           
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12
          }else{
            $status_msg = $null
            $Status_fontstyle = 'Normal'
            $Status_fontcolor = 'White' 
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12          
          }                    
          $header = New-Object PsObject -Property @{
            'title' = $title
            'ID' = $media.id
            'Status' = $media.live_status
            'FontStyle' = $fontstyle
            'FontColor' = $fontcolor
            'FontWeight' = $FontWeight
            'FontSize' = $FontSize          
            'Status_Msg' = $status_msg
            'Status_FontStyle' = $Status_fontstyle
            'Status_FontColor' = $Status_fontcolor
            'Status_FontWeight' = $Status_FontWeight
            'Status_FontSize' = $Status_FontSize          
          }         
          $Current_Playlist_ChildItem.Header = $header        
          $Current_Playlist_ChildItem.Name = 'Track'
          $Current_Playlist_ChildItem.Uid = $icon_path
          $Current_Playlist_ChildItem.IsSelected = $true
          $Current_Playlist_ChildItem.Tag = @{        
            synchash=$synchash;
            thisScript=$thisScript;
            thisApp=$thisApp
            PlayMedia_Command = $PlayMedia_Command
            PlaySpotify_Media_Command = $PlaySpotify_Media_Command
            All_Playlists = $all_playlists
            Media = $Media
          }                  
          $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$click_command)
          $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Media_ContextMenu)
          #$null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseLeftButtonDownEvent,$Drag_MouseDown)        
          $Play_Queue = $syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
          $null = $Play_Queue.items.add($Current_Playlist_ChildItem)                     
          if($from_Playlist -eq 'Play Queue')
          {
            $d.Effects = [System.Windows.DragDropEffects]::Move
            $d.Handled = $false
            
          }else{
            $d.Effects = [System.Windows.DragDropEffects]::Copy
            $d.Handled = $true
          }
          try{
            $null = $thisApp.config.Current_Playlist.clear()
            $index = 0
            foreach($item in $Play_Queue.items.tag.Media.id | where {$_ -ne $Media.id}){
              $null = $thisApp.config.Current_Playlist.add($index,$item)              
              #$null = $thisApp.config.Current_Playlist.add($item)
            }  
            $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisApp.config.Current_Playlist.add($index,$Media.id)               
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8           
          }catch{
            write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
          }               
        }
        else
        {
          write-ezlogs " | Play Queue already contains $($Media.id)" -showtime
          try{
            #$e.Effects = [System.Windows.DragDropEffects]::Move             
            if($from_Playlist -eq 'Play Queue')
            {
              $d.Effects = [System.Windows.DragDropEffects]::Move 
              $d.Handled = $false  
              write-ezlogs " | Reordering Play Queue from Drag and Drop" -showtime
            }else{
              $d.Effects = [System.Windows.DragDropEffects]::Copy
              $d.Handled = $true
            }                                                       
          }catch{
            write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
          }                   
        } 
        $synchash.Playqueue_update_timer = New-Object System.Windows.Threading.DispatcherTimer          
        $synchash.Playqueue_update_timer.add_tick({
            try{               
              $Play_Queue = $syncHash.PlayQueue_TreeView.Items                
              #$thisApp.config.Current_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
              $null = $thisApp.config.Current_Playlist.clear()
              $index = 0
              foreach($item in $Play_Queue.items.tag.Media.id | Select -Unique){   
                write-ezlogs " | Adding $($item) with index $($index) to play queue" -showtime            
                $null = $thisApp.config.Current_Playlist.add($index,$item)  
                $index++            
              }  
              if($VerboseLog){write-ezlogs ">>>> Exporting updated play queue to $($thisApp.Config.Config_Path)" -showtime -color cyan}
              $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8                                         
              $this.Stop()
            }catch{
              $this.Stop()
              write-ezlogs "An exception occurred in Playqueue_update_timer" -showtime -catcherror $_
            }
        })                   
        $synchash.Playqueue_update_timer.start()  
        $d.Handled = $false 
        $syncHash.PlayQueue_TreeView.UpdateLayout()                        
      }   
      elseif($all_playlists.playlists -and $to_PlayList)
      {
        try{
          $d.Effects = [System.Windows.DragDropEffects]::Copy
          $Playlist_To_Remove = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $Media.id -and $_.Name -eq $from_Playlist}
          $Playlist_To_Add = $all_playlists.playlists | where {$_.Name -eq $to_Playlist}
          if($Playlist_To_Remove){
            $Playlist_Track_To_Remove = $Playlist_To_Remove.Playlist_tracks | where {$_.id -eq $Media.id}
            $null = $Playlist_To_Remove.Playlist_tracks.Remove($Playlist_Track_To_Remove)
          }
          if($Playlist_To_Add){
            $Playlist_Track_To_Add = $all_playlists.playlists.Playlist_tracks | where {$_.id -eq $Media.id}
            $null = $Playlist_To_Add.Playlist_tracks.Add($Playlist_Track_To_Add)
          }             
          $d.Handled = $false      
          $all_playlists.playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8
        }catch{
          $d.Handled = $true
          write-ezlogs "An exception occurred moving $($Media.id) from Playlist $($from_Playlist) to Playlist $to_Playlist" -showtime -catcherror $_
        }    
      }elseif($From_Playlist_Name -eq $to_Playlist_Name){
        try{
          $d.Effects = [System.Windows.DragDropEffects]::Move 
          $d.Handled = $false                  
          $Playlist_items = ($syncHash.Playlists_TreeView.Items | where {$_.Header.Title -eq $From_Playlist_Name}).items
          $Playlist_To_Update = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $Media.id -and $_.Name -eq $From_Playlist_Name} 
          $synchash.Playlist_update_timer = New-Object System.Windows.Threading.DispatcherTimer          
          $synchash.Playlist_update_timer.add_tick({
              try{               
                #write-ezlogs "Playlist to update before: $($Playlist_To_Update.Playlist_tracks.Title | out-string)"                        
                $Updated_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
                foreach($item in $Playlist_items.tag.Media){
                  $null = $Updated_Playlist.add($item)
                } 
                $Playlist_To_Update.Playlist_tracks = $Updated_Playlist
                #write-ezlogs "Playlist to update after: $($Playlist_To_Update.Playlist_tracks.Title | out-string)"  
                $Playlist_To_Update | Export-Clixml $Playlist_To_Update.Playlist_Path -Force 
                $d.Handled = $false                             
                $this.Stop()
              }catch{
                $this.Stop()
                write-ezlogs "An exception occurred in playlist_update_timer" -showtime -catcherror $_
              }
          }.GetNewClosure())                   
          $synchash.Playlist_update_timer.start()  
          $syncHash.Playlists_TreeView.UpdateLayout()          
                                     
        }catch{
          $d.Handled = $true
          write-ezlogs "An exception occurred moving $($Media.id) from Playlist $($from_Playlist) to Playlist $to_Playlist" -showtime -catcherror $_
        }      
      
      }else{
        $d.Handled = $true
        write-ezlogs "Not sure what to do" -showtime -warning
      }              
    }else{
      $d.Handled = $true
    }        
  }.GetNewClosure()  
  $syncHash.PlayQueue_TreeView.add_PreviewDrop($PreviewDrop)
  $syncHash.Playlists_TreeView.add_PreviewDrop($PreviewDrop)
  $syncHash.MediaTable.add_PreviewDrop($PreviewDrop)
  $syncHash.YoutubeTable.add_PreviewDrop($PreviewDrop)
 
  <#  [System.Windows.DragEventHandler]$Drag_Over = {
      [System.Object]$script:sender = $args[0]
      [System.Windows.DragEventArgs]$e = $args[1]   
      write-ezlogs "You dropped $($e.data | out-string)"
  } #> 
  #$syncHash.MediaTable.add_PreviewDragOver($Drag_Over)
  if(!$Update_Current_Playlist){    
    $image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
    if($all_playlists.playlists -and !$Refresh_All_Playlists)
    { 
      foreach ($Playlist in $all_playlists.playlists)
      {
        $Playlist_Item = New-Object System.Windows.Controls.TreeViewItem
        $Playlist_Item.AllowDrop = $true
        $Playlist_item.IsExpanded = $true
        $Playlist_name = $null
        $Playlist_ID = $null
        $Media_Description = $null
        $Track_Total = $null
        $Playlist_name = $Playlist.name
        if($verboselog){write-ezlogs ">>>> Adding Playlist $Playlist_name" -showtime -color cyan}
        $Playlist_ID = $Playlist.Playlist_ID
        $Media_Description = $Playlist.Description
        $Track_Total = $Playlist.Playlist_Track_Total
        $Type = $Playlist.type
        $Playlist_tracks = $Playlist.Playlist_tracks
        $Playlist_Item.Uid = "$($thisApp.Config.Current_Folder)\\Resources\\Fontisto-PlayList.png" 
        $Group_Name = 'Name'
        $Sub_GroupName = 'Artist_Name'
        $Playlist_Item.Tag = @{        
          synchash=$synchash;
          thisScript=$thisScript;
          thisApp=$thisApp
          PlayMedia_Command = $PlayMedia_Command
          PlaySpotify_Media_Command = $PlaySpotify_Media_Command
          Playlist = $Playlist
          All_Playlists = $all_playlists
        }        
        #$Playlist_Item.Tag = $Playlist
        $header = New-Object PsObject -Property @{
          'title' = $Playlist_name
          'Status' = ''
          'FontStyle' = 'Normal'
          'FontColor' = 'White'
          'FontWeight' = 'Bold'
          'FontSize' = 12          
          'Status_Msg' = ''
          'Status_FontStyle' = ''
          'Status_FontColor' = ''
          'Status_FontWeight' = ''
          'Status_FontSize' = ''          
        }        
        $Playlist_Item.Header = $header
        $Playlist_Item.Name = 'Playlist'
        $null = $Playlist_Item.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Media_ContextMenu)        
        $Playlist_Item.add_PreviewDrop($PreviewDrop)
        foreach($Track in $Playlist_tracks){
          if($Track.id){
            $ChildItem = New-Object System.Windows.Controls.TreeViewItem
            $Childitem.AllowDrop = $true
            [int]$hrs = $($([timespan]::FromMilliseconds($track.Duration_ms)).Hours)
            [int]$mins = $($([timespan]::FromMilliseconds($track.Duration_ms)).Minutes)
            [int]$secs = $($([timespan]::FromMilliseconds($track.Duration_ms)).Seconds) 
            $total_time = "$mins`:$secs"
            $Title = $null
            if($Track.Spotify_path){
              $Title = "$($Track.Artist_Name) - $($Track.Track_Name)"
              $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png"
            }elseif($Track.webpage_url -match 'twitch'){
              $Title = "$($Track.Title)"
              #$title = "Twitch Stream: $($track.Playlist)"
              $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Twitch.png"
            }elseif($Track.type -eq 'YoutubePlaylist_item'){
              $Title = "$($Track.Title)"
              $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube.png"
            }else{
              $Title = "$($Track.Artist) - $($Track.Title)"
              $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
            } 
            if($Track.live_status -eq 'Offline'){
              $fontstyle = 'Italic'
              $fontcolor = 'Gray'
              $FontWeight = 'Normal'
              $FontSize = 12          
            }elseif($Track.live_status -eq 'Online' -or $track.live_status -eq 'Live'){
              $fontstyle = 'Normal'
              $fontcolor = 'LightGreen'
              $FontWeight = 'Normal'
              $FontSize = 12         
            }else{
              $fontstyle = 'Normal'
              $fontcolor = 'White' 
              $FontWeight = 'Normal'
              $FontSize = 12                     
            }
            if($Track.status_msg){
              $status_msg = $Track.status_msg
              if($Track.live_status -eq 'Offline'){
                $Status_fontcolor = 'Gray'
                $Status_fontstyle = 'Italic'
              }else{
                $Status_fontcolor = 'White'
                $Status_fontstyle = 'Normal'
              }                            
              $Status_FontWeight = 'Normal'
              $Status_FontSize = 12
            }else{
              $status_msg = $null
              $Status_fontstyle = 'Normal'
              $Status_fontcolor = 'White' 
              $Status_FontWeight = 'Normal'
              $Status_FontSize = 12          
            }                    
            $header = New-Object PsObject -Property @{
              'title' = $title
              'Status' = $Track.live_status
              'ID' = $Track.id
              'FontStyle' = $fontstyle
              'FontColor' = $fontcolor
              'FontWeight' = $FontWeight
              'FontSize' = $FontSize          
              'Status_Msg' = $status_msg
              'Status_FontStyle' = $Status_fontstyle
              'Status_FontColor' = $Status_fontcolor
              'Status_FontWeight' = $Status_FontWeight
              'Status_FontSize' = $Status_FontSize          
            }     
            if($Verboselog){write-ezlogs " | Adding Playlist Track: $Title" -showtime}
            $ChildItem.Header = $header       
            $ChildItem.Name = 'Track'
            $ChildItem.Uid = $icon_path
            #$ChildItem.Tag = $Track
            $ChildItem.Tag = @{        
              synchash=$synchash;
              thisScript=$thisScript;
              thisApp=$thisApp
              PlayMedia_Command = $PlayMedia_Command
              All_Playlists = $all_playlists
              PlaySpotify_Media_Command = $PlaySpotify_Media_Command
              Media = $Track
            }  
            $Childitem.add_PreviewDrop($PreviewDrop)          
            $null = $Childitem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$PlayMedia_Command)
            #$null = $Childitem.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$Media_ContextMenu)
            $null = $Childitem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Media_ContextMenu)
            #$null = $Childitem.AddHandler([System.Windows.Controls.Button]::PreviewMouseLeftButtonDownEvent,$Drag_MouseDown)            
            $null = $Playlist_Item.items.add($ChildItem)     
          }
        }
        $null = $syncHash.Playlists_TreeView.Items.Add($Playlist_Item)               
      }
    }
  }
}

#---------------------------------------------- 
#endregion Get-Playlists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Playlists')

