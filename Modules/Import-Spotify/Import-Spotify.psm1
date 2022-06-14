<#
    .Name
    Import-Spotify

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Spotify Profiles

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
#region Import-Spotify Function
#----------------------------------------------
function Import-Spotify
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    $all_available_Media,
    $Media_directories,
    [string]$Media_Profile_Directory,
    $Refresh_All_Spotify_Media,
    $thisApp,
    $log = $thisApp.Config.SpotifyMedia_logfile,
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,
    [switch]$use_runspace,
    [switch]$VerboseLog
  )
  try{
    $synchash.Window.Dispatcher.invoke([action]{
        $Synchash.spotifyMedia_Progress_Ring.isActive = $true 
         $syncHash.SpotifyTable.isEnabled = $false         
    },'Normal')  
  }catch{
    write-ezlogs "An exception occurred updating SpotifyMedia_Progress_Ring" -showtime -catcherror $_
  }   
  $all_spotify_media =  [hashtable]::Synchronized(@{})
  
  if($Startup){
    [System.Windows.RoutedEventHandler]$Spotify_Btnnext_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile  
          write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile
        }   
        if($synchash.Spotify_CurrentView_Group -eq $synchash.Spotify_TotalView_Groups){
          if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Spotify_TotalView_Groups) reached" -showtime -warning -logfile:$thisApp.Config.SpotifyMedia_logfile}
        }else{
          $itemsource = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Spotify_CurrentView_Group -and $_.Name -le $synchash.Spotify_TotalView_Groups} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
          if($synchash.Spotify_GroupName -and $view){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Spotify_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                  
          $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Spotify_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name   
          $synchash.SpotifyMedia_View = $view      
          $synchash.SpotifyMedia_TableUpdate_timer.start()   
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile}
      }catch{
        write-ezlogs 'An exception occurred in Spotify-BtnPrev click event' -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile
      }      
    }.GetNewClosure()
    [System.Windows.RoutedEventHandler]$Spotify_cbNumberOfRecords_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile 
          write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile
        }          
        if($synchash.Spotify_cbNumberOfRecords.SelectedIndex -ne -1 -and $synchash.SpotifyFilter_Handler.name -ne 'Show_SpotifyMediaArtist_ComboBox' -and $synchash.SpotifyFilter_Handler.name -ne 'SpotifyFilterTextBox'){
          $selecteditem = ($synchash.Spotify_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
          if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile}
          if($synchash.Spotify_cbNumberOfRecords.Selecteditem){
            $itemsource = ($synchash.Spotify_View_Groups | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)              
            if($synchash.Spotify_GroupName -and $view){
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Spotify_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}   
            $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name                 
            $synchash.SpotifyMedia_View = $view      
            $synchash.SpotifyMedia_TableUpdate_timer.start() 
            if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile}
          }
        }          
      }catch{write-ezlogs 'An exception occurred in Spotify_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile}   
    }.GetNewClosure()     
    [System.Windows.RoutedEventHandler]$Spotify_btnPrev_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile 
          write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile
        }   
        if($synchash.Spotify_CurrentView_Group -le 1){
          if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Spotify_TotalView_Groups) reached" -showtime -warning -logfile:$thisApp.Config.SpotifyMedia_logfile}
        }else{
          $itemsource = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Spotify_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)          
          if($synchash.Spotify_GroupName){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Spotify_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}  
          $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Spotify_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name   
          $synchash.SpotifyMedia_View = $view      
          $synchash.SpotifyMedia_TableUpdate_timer.start()            
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)" -showtime -logfile:$thisApp.Config.SpotifyMedia_logfile}
      }catch{
        write-ezlogs 'An exception occurred in Spotify-BtnNext click event' -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile
      }    
    }.GetNewClosure()
    $Null = $synchash.Spotify_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_Btnnext_Scriptblock)      
    $Null = $synchash.Spotify_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_btnPrev_Scriptblock)
    $Null = $synchash.Spotify_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Spotify_cbNumberOfRecords_Scriptblock) 
  }
  $synchash.import_SpotifyMedia_scriptblock = ({
      try{
        if($thisApp.Config.Verbose_logging){write-ezlogs "#### Getting Spotify Media ####" -linesbefore 1 -logfile:$log}
        $synchash.All_Spotify_Media = Get-Spotify -Media_directories $Media_directories -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -log:$log
        #TODO: Cleanup old hashtable
        $all_spotify_media.media = $synchash.All_Spotify_Media 
      }catch{
        write-ezlogs "An exception occurred in Get-Spotify" -showtime -catcherror $_
      }
  
      #$syncHash.SpotifyTable.ItemsSource = $null
      $Fields = @(
        'Number'
        'Track_Name'
        'Title'
        'Track_number'
        'Duration'
        'Duration_ms'
        'Artist_Name'
        'Artist'
        'Artist_ID'
        'Track_ID'
        'Artist_url'
        'Artist_web_url'
        'Album_name'
        'Album'
        'Album_ID'
        'Album_url'
        'thumbnail'
        'Album_web_url'
        'Playlist'
        'External_url'
        'Playlist_ID'
        'Playlist_URL'
        'Playlist_Track_Total'
        'Track_Url'    
        'Album_images'
        'Group_Name'
        'encodedtitle'
        'ID'
        'Profile_Path'
        'Url'
        'playlist_encodedtitle'
        'Type'
        'Source'
        'Spotify_Path'
      )

      # Add Media to a datatable
      <#  if(!$Spotify_Datatable.datatable){
          $Global:Spotify_Datatable =  [hashtable]::Synchronized(@{})
      }#>
      $Global:Spotify_Datatable.datatable = New-Object System.Data.DataTable
      $Null = $Spotify_Datatable.datatable.Columns.AddRange($Fields)

      #$image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
      $synchash.Spotify_GroupName = 'Group_Name'
      if($synchash.All_Spotify_Media -and !$Refresh_All_Spotify_Media)
      { 
        $counter = 0
        foreach ($Media in $synchash.All_Spotify_Media | where {$_.id})
        {
          #$Array = @()
          $Playlist_name = $null     
          $Playlist_ID = $null
          $Profile_path = $Null
          $Media_Description = $null
          $Track_Total = $null
          $Playlist_URL = $null
          $Web_URL = $null
          $Playlist_encodedtitle = $Null
          $Playlist_encodedtitle = $Media.encodedtitle
          $Playlist_name = $Media.name
          $Playlist_ID = $media.id
          $Profile_path = $media.Profile_Path
          $Media_Description = $Media.Description
          $Track_Total = $Media.Track_Total
          $Playlist_URL = $Media.URL
          $Web_URL = $Media.Web_URL
          $Type = $media.type      
          $Spotify_Path = $media.Spotify_Launch_Path
          $images = $media.images
          $Playlist_tracks = $media.Playlist_tracks      
          #$Group_Name = 'Playlist'
          #$Sub_GroupName = 'Artist'
          if($verboselog){write-ezlogs ">>> Found Spotify Playlist: $Playlist_name" -showtime -logfile:$log} 
          #$Sub_GroupName = 'Artist_Name'
          foreach($Track in $Playlist_tracks){
            if($Track.id){
              $counter++
              #$track_encodedtitle = $Null  
              #$track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Track.Name)-$($Track.Artists.Name)-$($Track.Album.Name)-$($Playlist_ID)-SpotifyTrack")
              #$track_encodedTitle = [System.Convert]::ToBase64String($track_encodedBytes) 
              [int]$hrs = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Hours)
              [int]$mins = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Minutes)
              [int]$secs = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Seconds) 
              $total_time = "$mins`:$secs"
              $thumbimage = $Track.Album_info.images | where {$_.Width -le 64}
              $albumimage = $Track.Album_info.images | where {$_.Width -ge 300} | select -last 1
              if($verboselog){write-ezlogs " | Adding Spotify Track: $($Track.Name) - ID $($Track.id)" -showtime -logfile:$log}              
              #---------------------------------------------- 
              #region Add Properties to datatable
              #----------------------------------------------
              $newTableRow =$Spotify_Datatable.datatable.NewRow()
              $newTableRow.Number = $counter
              $newTableRow.Playlist = $Playlist_name
              $newTableRow.Playlist_ID = $Playlist_ID
              $newTableRow.Playlist_URL = $Playlist_URL    
              $newTableRow.Playlist_Track_Total = $Track_Total
              $newTableRow.Url = $Track.uri
              $newTableRow.Track_ID = $Track.id
              $newTableRow.Track_Url = $Track.uri
              $newTableRow.Track_Name = $Track.Name
              $newTableRow.Title = $Track.title
              $newTableRow.Duration = $total_time
              $newTableRow.Duration_ms = $Track.Duration_ms
              $newTableRow.Track_number = $Track.Track_number
              $newTableRow.Artist_Name = $Track.Artists.Name -join ','
              $newTableRow.Artist = $Track.Artist
              $newTableRow.Artist_ID = $Track.Artists.id -join ','
              $newTableRow.Artist_url = $Track.Artists.uri -join ','
              $newTableRow.Artist_web_url = $Track.Artists.href -join ','
              $newTableRow.Album_name = $Track.Album.Name
              $newTableRow.Album = $Track.Album
              $newTableRow.Album_ID = $Track.Album.id
              $newTableRow.thumbnail = $thumbimage.url
              $newTableRow.Album_url = $Track.Album_info.uri
              $newTableRow.Album_web_url = $Track.Album_info.href
              $newTableRow.External_url = $track.external_urls.spotify
              $newTableRow.Album_images = $albumimage.url
              $newTableRow.Group_Name = "$Playlist_name"
              $newTableRow.encodedtitle = $Track.id
              $newTableRow.ID = $Track.id
              $newTableRow.playlist_encodedtitle = $Playlist_encodedtitle
              $newTableRow.type = $Track.type
              $newTableRow.Profile_Path = $Profile_path         
              $newTableRow.Source = $Media.source
              $newTableRow.Spotify_Path = $Spotify_Path 
              if($Spotify_Datatable.datatable.id -notcontains $Track.id){
                $Null = $Spotify_Datatable.datatable.Rows.Add($newTableRow) 
              }else{
                write-ezlogs "Duplicate Spotify Track found $($Track.Name) - ID $($Track.id) - Playlist $($Playlist_name)" -showtime -warning -logfile:$log
              }                       
              #---------------------------------------------- 
              #endregion Add Properties to datatable
              #----------------------------------------------      
            }
          }              
        }
      }
      if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -logfile:$log} 
      $PerPage = $thisApp.Config.SpotifyBrowser_Paging
      if($thisApp.Config.SpotifyBrowser_Paging -ne $Null){
        $approxGroupSize = (@($Spotify_Datatable.datatable).count | Measure-Object -Sum).Sum / $PerPage  
        $approxGroupSize = [math]::ceiling($approxGroupSize)
        #write-host ('This will create {0} groups which will be approximately {1} in size' -f $approxGroupSize, $page_size)
        # create number of groups requested
        $groupMembers = @{}
        $groupSizes = @{}
        for ($i = 1; $i -le ($approxGroupSize); $i++) {
          $groupMembers.$i = [Collections.Generic.List[Object]]@()
          $groupSizes.$i = 0
        }
        foreach ($item in $Spotify_Datatable.datatable) {
          $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name" | where {$_.value -lt $PerPage}) | Select-Object -First 1).name
          if($groupMembers.$mostEmpty -notcontains $item){
            $null = $groupMembers.$mostEmpty.Add($item)
            $groupSizes.$mostEmpty += @($item).count
          }
        }     
        $synchash.Spotify_filterView_Groups = $groupmembers.GetEnumerator() | select *
        $synchash.Spotify_View_Groups = $groupmembers.GetEnumerator() | select *
        $synchash.Spotify_TotalView_Groups = ($groupmembers.GetEnumerator() | select *).count
        $synchash.Spotify_CurrentView_Group = ($groupmembers.GetEnumerator() | select * | select -last 1).Name    
        $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}
        $synchash.SpotifyMedia_View = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)   
      }else{  
        $synchash.SpotifyMedia_View = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Spotify_Datatable.datatable)     
      }
      if(($synchash.SpotifyMedia_View.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Spotify_GroupName){
        $syncHash.Window.Dispatcher.invoke([action]{
            $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Spotify_GroupName
            $synchash.SpotifyMedia_View.GroupDescriptions.Clear()
            $null = $synchash.SpotifyMedia_View.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $synchash.SpotifyMedia_View.GroupDescriptions.Add($sub_groupdescription)
            }
        })
      }elseif($synchash.SpotifyMedia_View.GroupDescriptions){
        $syncHash.Window.Dispatcher.invoke([action]{
            $synchash.SpotifyMedia_View.GroupDescriptions.Clear()
        })
      }else{
        write-ezlogs "[Import-Spotify] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning -logfile:$log
      }     

      <#      $syncHash.Window.Dispatcher.invoke([action]{
          try{
          $syncHash.SpotifyTable.ItemsSource = $synchash.SpotifyMedia_View
          $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
          $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"    
          }catch{
          write-ezlogs "[RUNSPACE INVOKE] An exception occurred attempting to set itemsource for SpotifyTable" -showtime -catcherror $_
          }           
      },"Normal")  #>   
  
      if($Startup)
      {     
<#        $syncHash.Window.Dispatcher.invoke([action]{
            $syncHash.SpotifyTable.CanUserReorderColumns = $true
            $synchash.SpotifyTable.CanUserSortColumns = $true
            $syncHash.SpotifyTable.FontWeight = "bold"
            $synchash.SpotifyTable.HorizontalAlignment = "Stretch"
            $synchash.SpotifyTable.CanUserAddRows = $False
            $synchash.SpotifyTable.HorizontalContentAlignment = "left"
            $synchash.SpotifyTable.IsReadOnly = $True
            if($verboselog){write-ezlogs " | Adding Spotify Media table play button and select checkbox to table" -showtime -logfile:$log} 
            $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
            $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
            $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
            if($verboselog){write-ezlogs " | Setting SpotifyTable Play button click event" -showtime -logfile:$log} 
            $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            $dataTemplate = New-Object System.Windows.DataTemplate
            $dataTemplate.VisualTree = $buttonFactory
            $buttonColumn.CellTemplate = $dataTemplate
            $buttonColumn.Header = 'Play'
            $buttonColumn.DisplayIndex = 0
            $null = $synchash.SpotifyTable.Columns.add($buttonColumn) 
        },"Normal") #>    
        if($thisApp.Config.startup_perf_timer){write-ezlogs " | Seconds to Import-Spotify: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}           
      }
      $synchash.SpotifyMedia_TableUpdate_timer.start() 
  })
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $synchash.import_SpotifyMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'Import_SpotifyMedia_Runspace' -thisApp $thisApp -synchash $synchash
}

#---------------------------------------------- 
#endregion Import-Spotify Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Spotify')

