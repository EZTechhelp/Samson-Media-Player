<#
    .Name
    Import-Youtube

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Youtube Profiles

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
#region Import-Youtube Function
#----------------------------------------------
function Import-Youtube
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$use_Runspace,
    $synchash,
    [string]$Youtube_URL,
    $all_available_Media,
    $Youtube_playlists,
    [string]$Media_Profile_Directory,
    $Refresh_All_Youtube_Media,
    $thisApp,
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,
    $Youtube_cbNumberOfRecords_Scriptblock,
    $Youtube_btnPrev_Scriptblock,
    $Youtube_Btnnext_Scriptblock,    
    [switch]$VerboseLog
  )
  
  $all_Youtube_media =  [hashtable]::Synchronized(@{})
  if($Youtube_URL){
    $synchash.All_Youtube_Media = Get-Youtube -Youtube_URL $Youtube_URL -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser
  }else{
    Add-Type -AssemblyName System.Web
    if($Verboselog){write-ezlogs "#### Getting Youtube Media ####" -enablelogs -color yellow -linesbefore 1}
    $synchash.All_Youtube_Media = Get-Youtube -Youtube_playlists $Youtube_playlists -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser -startup
  }

  
  #$synchash.All_Youtube_Media = $all_Youtube_media.media
  #$syncHash.YoutubeTable.ItemsSource = $null
  $Fields = @(
    'Track_Name'
    'Title'
    'Track_number'
    'Duration'
    'Duration_ms'
    'Artist_Name'
    'Artist'
    'Artist_ID'
    'Artist_url'
    'Artist_web_url'
    'video_url'
    'audio_url'
    'Album_name'
    'Album_ID'
    'Album_url'
    'Album_web_url'
    'Playlist'
    'Playlist_ID'
    'Playlist_URL'
    'Profile_Path'
    'Live_Status'
    'Stream_title'
    'Status_msg'
    'chat_url'
    'Playlist_Track_Total'
    'Track_Url'
    'webpage_url' 
    'Url'    
    'Album_images'
    'Thumbnail'
    'Group_Name'
    'Group'
    'encodedtitle'
    'ID'
    'playlist_encodedtitle'
    'Type'
    'Source'
  )

  # Add Media to a datatable
  #$Global:Youtube_Datatable =  [hashtable]::Synchronized(@{})
  $Global:Youtube_Datatable.datatable = New-Object System.Data.DataTable
  $Null = $Youtube_Datatable.datatable.Columns.AddRange($Fields)
  
  $image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
  #$Group_Name = 'Playlist'
  $synchash.Youtube_GroupName = 'Playlist'
  if($synchash.All_Youtube_Media -and !$Refresh_All_Youtube_Media)
  { 
    foreach ($Media in $synchash.All_Youtube_Media)
    {
      $Playlist_name = $null
      $Playlist_ID = $null
      $Media_Description = $null      
      $Track_Total = $null
      $Playlist_URL = $null
      $Web_URL = $null
      if($Media.chat_url){
        $chat_url = $Media.chat_url
      }elseif($media.url -match 'twitch.tv'){      
        $chat_url = "$($media.url)/chat"
      }else{
        $chat_url = $null
      }
      $Playlist_encodedtitle = $Null
      $Playlist_encodedtitle = $Media.encodedtitle
      $Playlist_name = $Media.name
      $Playlist_ID = $media.id
      #$Media_Description = $Media.Description
      $Track_Total = $Media.Tracks_Total
      $Playlist_URL = $Media.URL
      $Type = $media.type
      $images = $media.images
      $Playlist_tracks = $media.Playlist_tracks
      #write-ezlogs "chaturl: $chat_url" -showtime      
      #$Sub_GroupName = 'Artist_Name'
      foreach($Track in $Playlist_tracks){
        if($Track.id){
          $track_encodedtitle = $Null 
          $track_encodedtitle = $track.encodedtitle  
          [int]$hrs = $($([timespan]::Fromseconds($Track.Duration)).Hours)
          [int]$mins = $($([timespan]::Fromseconds($Track.Duration)).Minutes)
          [int]$secs = $($([timespan]::Fromseconds($Track.Duration)).Seconds) 
          [int]$milsecs = $($([timespan]::Fromseconds($Track.Duration)).TotalMilliseconds)
          $total_time = "$hrs`:$mins`:$secs"                   
          $thumbimage = $Track.thumbnail 
          if($Media.Group -match 'twitch'){
            $Playlist_name = $Media.Group
          }                   
          #---------------------------------------------- 
          #region Add Properties to datatable
          #----------------------------------------------
          $newTableRow =$Youtube_Datatable.datatable.NewRow()
          $newTableRow.Playlist = $Playlist_name
          $newTableRow.Playlist_ID = $Playlist_ID
          $newTableRow.Playlist_URL = $Playlist_URL    
          $newTableRow.Playlist_Track_Total = $Track_Total
          $newTableRow.Track_Url = $Track.url
          $newTableRow.video_url = $Track.video_url
          $newTableRow.audio_url = $Track.audio_url
          $newTableRow.webpage_url = $Track.webpage_url
          $newTableRow.chat_url = $chat_url
          $newTableRow.Url = $Track.url
          $newTableRow.Track_Name = $Track.title
          $newTableRow.Title = $Track.title
          $newTableRow.Duration = $total_time
          $newTableRow.Live_Status = $Track.live_status
          $newTableRow.Status_msg = $Track.Status_msg
          $newTableRow.Stream_title = $Track.Stream_title
          $newTableRow.Profile_Path = $Media.Profile_Path
          $newTableRow.Duration_ms = $milsecs
          $newTableRow.Track_number = $Track.playlist_index
          $newTableRow.Artist_Name = ''
          $newTableRow.Artist = ''
          $newTableRow.Group = $Media.Group
          $newTableRow.Artist_ID = ''
          $newTableRow.Artist_url = ''
          $newTableRow.Artist_web_url = ''
          $newTableRow.Album_name = ''
          $newTableRow.Album_ID = ''
          $newTableRow.Album_url = ''
          $newTableRow.Album_web_url = ''
          $newTableRow.Album_images = ''
          $newTableRow.thumbnail = $Track.thumbnail
          $newTableRow.Group_Name = $synchash.Youtube_GroupName
          $newTableRow.encodedtitle = $track_encodedTitle
          $newTableRow.ID = $track_encodedTitle
          $newTableRow.playlist_encodedtitle = $Playlist_encodedtitle
          $newTableRow.type = $Track.source
          $newTableRow.Source = $Track.source       
          $Null = $Youtube_Datatable.datatable.Rows.Add($newTableRow)        
          #---------------------------------------------- 
          #endregion Add Properties to datatable
          #----------------------------------------------      
        }
      }              
    }
  }
  if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -color cyan -enablelogs} 
  #$view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable)
  $PerPage = $thisApp.Config.YoutubeBrowser_Paging
  if($thisApp.Config.YoutubeBrowser_Paging -ne $Null){
    $approxGroupSize = (@($Youtube_Datatable.datatable).count | Measure-Object -Sum).Sum / $thisApp.Config.YoutubeBrowser_Paging     
    $approxGroupSize = [math]::ceiling($approxGroupSize)
    #write-host ('This will create {0} groups which will be approximately {1} in size' -f $approxGroupSize, $page_size)
    # create number of groups requested
    $groupMembers = @{}
    $groupSizes = @{}
    for ($i = 1; $i -le ($approxGroupSize); $i++) {
      $groupMembers.$i = [Collections.Generic.List[Object]]@()
      $groupSizes.$i = 0
    }
    foreach ($item in $Youtube_Datatable.datatable) {
      $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name" | where {$_.value -lt $thisApp.Config.YoutubeBrowser_Paging}) | Select-Object -First 1).name
      #$mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name") | Select-Object -First 1).name
      if($groupMembers.$mostEmpty -notcontains $item){
        $null = $groupMembers.$mostEmpty.Add($item)
        $groupSizes.$mostEmpty += @($item).count
      }
    }     
    $synchash.Youtube_filterView_Groups = $groupmembers.GetEnumerator() | select *
    $synchash.Youtube_View_Groups = $groupmembers.GetEnumerator() | select *
    $synchash.Youtube_TotalView_Groups = @($groupmembers.GetEnumerator() | select *).count
    $synchash.Youtube_CurrentView_Group = ($groupmembers.GetEnumerator() | select * | select -last 1).Name    
    $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Playlist},{$_.Track_Name}
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
  }else{  
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
  }
  $synchash.Youtube_View = $view
  if($synchash.Youtube_GroupName){
    $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
    $groupdescription.PropertyName = $synchash.Youtube_GroupName
    if($synchash.Youtube_View.GroupDescriptions){
      $synchash.Youtube_View.GroupDescriptions.Clear()    
    }else{
      write-ezlogs "[Import-Youtube] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning
    }
     $null = $synchash.Youtube_View.GroupDescriptions.Add($groupdescription)
    if($Sub_GroupName){
      $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $sub_groupdescription.PropertyName = $Sub_GroupName
      $null = $synchash.Youtube_View.GroupDescriptions.Add($sub_groupdescription)
    }
  }elseif($synchash.Youtube_View.GroupDescriptions){
    $synchash.Youtube_View.GroupDescriptions.Clear()
  }    
  if($use_runspace){
    #$synchash.import_youtube_timer.start()
    $syncHash.Window.Dispatcher.invoke([action]{
        $syncHash.YoutubeTable.ItemsSource = $synchash.Youtube_View
        $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)" 
        $synchash.Youtube_Table_Total_Media.content = "$(@($syncHash.YoutubeTable.ItemsSource).count) of Total | $(@(($synchash.Youtube_View_Groups | select *).value).count)"       
        $synchash.Youtube_Progress_Ring.isActive=$false   
    },"Normal")     
  }else{
    $syncHash.SpotifyTable.ItemsSource = $view
    $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
    $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"
    $synchash.Youtube_Progress_Ring.isActive=$false        
  }

  if($Startup)
  {
    if($use_runspace){
      if($thisApp.Config.YoutubeBrowser_Paging -ne $Null){
        1..($synchash.Youtube_TotalView_Groups) | foreach{
          if($synchash.Youtube_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
            $syncHash.Window.Dispatcher.invoke([action]{
                $null = $synchash.Youtube_cbNumberOfRecords.items.add("Page $_")
            },"Normal")   
          }
        }   
      }    
      $syncHash.Window.Dispatcher.invoke([action]{
          $Null = $synchash.Youtube_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_Btnnext_Scriptblock)      
          $Null = $synchash.Youtube_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_btnPrev_Scriptblock)
          $Null = $synchash.Youtube_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Youtube_cbNumberOfRecords_Scriptblock) 
          #$synchash.YoutubeTable.AutoGenerateColumns = $true
          $syncHash.YoutubeTable.CanUserReorderColumns = $false
          $syncHash.YoutubeTable.FontWeight = "bold"
          $synchash.YoutubeTable.HorizontalAlignment = "Stretch"
          $synchash.YoutubeTable.CanUserSortColumns = $true
          $synchash.YoutubeTable.CanUserAddRows = $False
          $synchash.YoutubeTable.HorizontalContentAlignment = "left"
          $synchash.YoutubeTable.IsReadOnly = $false  
          $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
          $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
          $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
          if($verboselog){write-ezlogs " | Setting YoutubeTable Play button click event" -showtime -color cyan -enablelogs} 
          $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
          $dataTemplate = New-Object System.Windows.DataTemplate
          $dataTemplate.VisualTree = $buttonFactory
          $buttonColumn.CellTemplate = $dataTemplate
          $buttonColumn.Header = 'Play'
          $buttonColumn.DisplayIndex = 0
          $null = $synchash.YoutubeTable.Columns.add($buttonColumn) 
      },"Normal")     
    }else{
      if($thisApp.Config.YoutubeBrowser_Paging -ne $Null){
        1..($synchash.Youtube_TotalView_Groups) | foreach{
          if($synchash.Youtube_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
            $null = $synchash.Youtube_cbNumberOfRecords.items.add("Page $_") 
          }
        }   
      }    
      $Null = $synchash.Youtube_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_Btnnext_Scriptblock)      
      $Null = $synchash.Youtube_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_btnPrev_Scriptblock)
      $Null = $synchash.Youtube_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Youtube_cbNumberOfRecords_Scriptblock)     
      #$synchash.YoutubeTable.AutoGenerateColumns = $true
      $syncHash.YoutubeTable.CanUserReorderColumns = $true
      $syncHash.YoutubeTable.FontWeight = "bold"
      $synchash.YoutubeTable.HorizontalAlignment = "Stretch"
      $synchash.YoutubeTable.CanUserAddRows = $False
      $synchash.YoutubeTable.HorizontalContentAlignment = "left"
      $synchash.YoutubeTable.IsReadOnly = $True    
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
      if($verboselog){write-ezlogs " | Setting YoutubeTable Play button click event" -showtime -color cyan -enablelogs} 
      $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.Header = 'Play'
      $buttonColumn.DisplayIndex = 0
      $null = $synchash.YoutubeTable.Columns.add($buttonColumn) 
    } 
    if($startup_perf_timer){write-ezlogs " | Seconds to Import-Youtube: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}        
  }
}

#---------------------------------------------- 
#endregion Import-Youtube Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Youtube')

