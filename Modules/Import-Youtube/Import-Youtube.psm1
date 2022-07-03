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
    [switch]$refresh,
    $synchash,
    [string]$Youtube_URL,
    $all_available_Media,
    $Youtube_playlists,
    [string]$Media_Profile_Directory,
    $Refresh_All_Youtube_Media,
    $thisApp,
    $log = $thisApp.Config.YoutubeMedia_logfile,
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,    
    [switch]$VerboseLog
  )
  try{
    $synchash.Window.Dispatcher.invoke([action]{
        $Synchash.Youtube_Progress_Ring.isActive = $true
        $syncHash.YoutubeTable.isEnabled = $false              
    },'Normal')    
  }catch{
    write-ezlogs "An exception occurred updating Youtube_Progress_Ring" -showtime -catcherror $_
  } 
  $all_Youtube_media =  [hashtable]::Synchronized(@{})
  
  if($Startup){
    [System.Windows.RoutedEventHandler]$Youtube_Btnnext_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile  
          write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
        }   
        if($synchash.Youtube_CurrentView_Group -eq $synchash.Youtube_TotalView_Groups){
          if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Youtube_TotalView_Groups) reached" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile}
        }else{
          if($synchash.Youtube_View_Groups){
            $itemsource = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Youtube_CurrentView_Group -and $_.Name -le $synchash.Youtube_TotalView_Groups} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
          }else{
            $itemsource = $Youtube_Datatable.datatable | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
          }
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
          if($view){
            if($synchash.Youtube_GroupName){
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Youtube_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
          }                  
          $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups | select * | where {$_.Name -gt $synchash.Youtube_CurrentView_Group -and $_.Name -le $synchash.Youtube_TotalView_Groups} | select -last 1).Name        
          #$synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Youtube_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name   
          $synchash.YoutubeMedia_View = $view      
          $synchash.YoutubeMedia_TableUpdate_timer.start()                
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile}
      }catch{
        write-ezlogs 'An exception occurred in Youtube-BtnPrev click event' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
      }      
    }.GetNewClosure()
    [System.Windows.RoutedEventHandler]$Youtube_cbNumberOfRecords_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile 
          write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
        }          
        if($synchash.Youtube_cbNumberOfRecords.SelectedIndex -ne -1 -and $synchash.YoutubeFilter_Handler.name -ne 'Show_YoutubeMediaArtist_ComboBox' -and $synchash.YoutubeFilter_Handler.name -ne 'YoutubeFilterTextBox'){
          $selecteditem = ($synchash.Youtube_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
          if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)"}
          if($synchash.Youtube_cbNumberOfRecords.Selecteditem){
            if($synchash.Youtube_View_Groups){
              $itemsource = ($synchash.Youtube_View_Groups | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
            }else{
              $itemsource = $Youtube_Datatable.datatable | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
            }
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)   
            if($view){
              if($synchash.Youtube_GroupName){
                $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $groupdescription.PropertyName = $synchash.Youtube_GroupName
                $view.GroupDescriptions.Clear()
                $null = $view.GroupDescriptions.Add($groupdescription)
                if($Sub_GroupName){
                  $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                  $sub_groupdescription.PropertyName = $Sub_GroupName
                  $null = $view.GroupDescriptions.Add($sub_groupdescription)
                }
              }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
            }
            $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name                                        
            $synchash.YoutubeMedia_View = $view        
            $synchash.YoutubeMedia_TableUpdate_timer.start()  
            if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile}
          }
        }          
      }catch{
        write-ezlogs 'An exception occurred in Youtube_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
      }   
    }.GetNewClosure()     
    [System.Windows.RoutedEventHandler]$Youtube_btnPrev_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile  
          write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
        }   
        if($synchash.Youtube_CurrentView_Group -le 1){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Youtube_TotalView_Groups) reached" -showtime -warning}}else{
          if($synchash.Youtube_View_Groups){
            $itemsource = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Youtube_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
          }else{
            $itemsource = $Youtube_Datatable.datatable | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
          }       
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
          if($view){
            if($synchash.Youtube_GroupName){
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Youtube_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
          }
          $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups | select * | where {$_.Name -lt $synchash.Youtube_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name   
          $synchash.YoutubeMedia_View = $view      
          $synchash.YoutubeMedia_TableUpdate_timer.start()   
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile}
      }catch{
        write-ezlogs 'An exception occurred in Youtube-BtnNext click event' -showtime -catcherror $_ -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
      }    
    }.GetNewClosure()
    $Null = $synchash.Youtube_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_Btnnext_Scriptblock)      
    $Null = $synchash.Youtube_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_btnPrev_Scriptblock)
    $Null = $synchash.Youtube_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Youtube_cbNumberOfRecords_Scriptblock) 
  }  
  $synchash.import_YoutubeMedia_scriptblock = ({
      if($thisApp.Config.Verbose_Logging){write-ezlogs "#### Getting Youtube Media ####" -linesbefore 1 -logfile:$log}
      $Get_Youtube_Measure = measure-command {
        if($Youtube_URL){
          $synchash.All_Youtube_Media = Get-Youtube -Youtube_URL $Youtube_URL -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser -log:$log -refresh:$refresh
        }else{
          Add-Type -AssemblyName System.Web    
          $synchash.All_Youtube_Media = Get-Youtube -Youtube_playlists $Youtube_playlists -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser -startup:$Startup -log:$log -refresh:$refresh
        }
      }
      if($thisApp.Config.startup_perf_timer){write-ezlogs ">>>> Get-Youtube Measure: $($Get_Youtube_Measure.Minutes)mins - $($Get_Youtube_Measure.Seconds)secs - $($Get_Youtube_Measure.Milliseconds)ms" -showtime} 
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
        'Description'
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
        'profile_image_url'
        'offline_image_url'    
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
      $synchash.Youtube_GroupName = 'Group_Name'
      if($synchash.All_Youtube_Media -and !$Refresh_All_Youtube_Media)
      { 
        $Youtube_to_Datatable_Measure = measure-command {
          foreach ($Media in $synchash.All_Youtube_Media | where {$_.id})
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
            if($verboselog){write-ezlogs ">>>> Adding Youtube Playlist: $($Playlist_name)" -showtime -logfile:$log}      
            #$Sub_GroupName = 'Artist_Name'
            foreach($Track in $Playlist_tracks){
              if($Track.id){
                if($Track.id -match '&t='){
                  $Track.id = ($($Track.id) -split('&t='))[0].trim()
                }               
                $track_encodedtitle = $Null 
                $track_encodedtitle = $track.encodedtitle  
                try{
                  [int]$hrs = $($([timespan]::FromMilliseconds($Track.Duration)).Hours)
                  [int]$mins = $($([timespan]::FromMilliseconds($Track.Duration)).Minutes)
                  [int]$secs = $($([timespan]::FromMilliseconds($Track.Duration)).Seconds) 
                  $total_time = "$hrs`:$mins`:$secs"                   
                }catch{
                  write-ezlogs "An exception occurred parsing track duration time $($Track.Duration)" -showtime -catcherror $_
                }
                if($Media.Group -match 'twitch'){
                  $Playlist_name = $Media.Group
                }   
                if($verboselog){write-ezlogs " | Adding track: $($Track.title) - $($Track.id)" -showtime -logfile:$log}      
                #write-ezlogs "Playlist: $($Playlist_name) - Media.name $($Media.name) - Title: $($Track.title) - Group: $($Media.Group)"       
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
                $newTableRow.Description = $Media.Description
                $newTableRow.Duration_ms = $Track.Duration
                $newTableRow.Track_number = $Track.playlist_index
                $newTableRow.Artist_Name = ''
                $newTableRow.Artist = ''
                $newTableRow.Group = $Media.Group
                $newTableRow.Artist_ID = ''         
                $newTableRow.profile_image_url = $track.profile_image_url
                $newTableRow.offline_image_url = $track.offline_image_url
                $newTableRow.Artist_url = ''
                $newTableRow.Artist_web_url = ''
                $newTableRow.Album_name = ''
                $newTableRow.Album_ID = ''
                $newTableRow.Album_url = ''
                $newTableRow.Album_web_url = ''
                $newTableRow.Album_images = ''
                $newTableRow.thumbnail = $Track.thumbnail
                $newTableRow.Group_Name = "$Playlist_name"
                $newTableRow.encodedtitle = $track.id
                $newTableRow.ID = $track.id       
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
        if($thisApp.Config.startup_perf_timer){write-ezlogs ">>>> Youtube_to_Datatable_Measure Measure: $($Youtube_to_Datatable_Measure.Minutes)mins - $($Youtube_to_Datatable_Measure.Seconds)secs - $($Youtube_to_Datatable_Measure.Milliseconds)ms" -showtime} 
      }
      if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -logfile:$log} 
      $PerPage = $thisApp.Config.YoutubeBrowser_Paging
      $Youtube_Page_Measure = measure-command {
        if($thisApp.Config.YoutubeBrowser_Paging -ne $Null -and @($Youtube_Datatable.datatable).count -gt 1){
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
          $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
          $synchash.YoutubeMedia_View = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
        }else{  
          $synchash.YoutubeMedia_View = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
        }
      }
      if($thisApp.Config.startup_perf_timer){write-ezlogs ">>>> Youtube_Page_Measure: $($Youtube_Page_Measure.Minutes)mins - $($Youtube_Page_Measure.Seconds)secs - $($Youtube_Page_Measure.Milliseconds)ms" -showtime} 
      if(($synchash.YoutubeMedia_View.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Youtube_GroupName){
        $syncHash.Window.Dispatcher.invoke([action]{
            $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Youtube_GroupName
            $synchash.YoutubeMedia_View.GroupDescriptions.Clear()
            $null = $synchash.YoutubeMedia_View.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $synchash.YoutubeMedia_View.GroupDescriptions.Add($sub_groupdescription)
            }
        })
      }elseif($synchash.YoutubeMedia_View.GroupDescriptions){
        $syncHash.Window.Dispatcher.invoke([action]{
            $synchash.YoutubeMedia_View.GroupDescriptions.Clear()
        })
      }else{
        write-ezlogs "[Import-Youtube] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning -logfile:$log
      } 

      <#      $syncHash.Window.Dispatcher.invoke([action]{
          try{
          $syncHash.YoutubeTable.ItemsSource = $synchash.YoutubeMedia_View
          $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)" 
          $synchash.Youtube_Table_Total_Media.content = "$(@($syncHash.YoutubeTable.ItemsSource).count) of Total | $(@(($synchash.Youtube_View_Groups | select *).value).count)"       
          $synchash.Youtube_Progress_Ring.isActive=$false   
          }catch{
          write-ezlogs "[RUNSPACE INVOKE] An exception occurred attempting to set itemsource for MediaTable" -showtime -catcherror $_
          }    
      },"Normal")   #>  

      if($Startup -and !$synchash.Youtube_Update)
      {     
        <#        $syncHash.Window.Dispatcher.invoke([action]{
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
            if($verboselog){write-ezlogs " | Setting YoutubeTable Play button click event" -showtime -enablelogs -logfile:$log} 
            $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            $dataTemplate = New-Object System.Windows.DataTemplate
            $dataTemplate.VisualTree = $buttonFactory
            $buttonColumn.CellTemplate = $dataTemplate
            $buttonColumn.Header = 'Play'
            $buttonColumn.DisplayIndex = 0
            $null = $synchash.YoutubeTable.Columns.add($buttonColumn)  
        },"Normal")#>     
        if($thisApp.Config.startup_perf_timer){write-ezlogs " | Seconds to Import-Youtube: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}            
      }
      $synchash.YoutubeMedia_TableUpdate_timer.start()
      $synchash.Youtube_Update = $false 
  
  }) 
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $synchash.import_YoutubeMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'Import_YoutubeMedia_Runspace' -thisApp $thisApp -synchash $synchash
}

#---------------------------------------------- 
#endregion Import-Youtube Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Youtube')

