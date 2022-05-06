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
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,
    $Spotify_cbNumberOfRecords_Scriptblock,
    $Spotify_btnPrev_Scriptblock,
    $Spotify_Btnnext_Scriptblock,
    [switch]$use_runspace,
    [switch]$VerboseLog
  )
  
  $all_spotify_media =  [hashtable]::Synchronized(@{})
  try{
    if($Verboselog){write-ezlogs "#### Getting Spotify Media ####" -enablelogs -color yellow -linesbefore 1}
    $all_spotify_media.media = Get-Spotify -Media_directories $Media_directories -Media_Profile_Directory $Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp
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
    'Album_ID'
    'Album_url'
    'thumbnail'
    'Album_web_url'
    'Playlist'
    'Playlist_ID'
    'Playlist_URL'
    'Playlist_Track_Total'
    'Track_Url'    
    'Album_images'
    'Group_Name'
    'encodedtitle'
    'ID'
    'Url'
    'playlist_encodedtitle'
    'Type'
    'Source'
    'Spotify_Path'
  )

  # Add Media to a datatable
  #$Global:Spotify_Datatable =  [hashtable]::Synchronized(@{})
  $Global:Spotify_Datatable.datatable = New-Object System.Data.DataTable
  $Null = $Spotify_Datatable.datatable.Columns.AddRange($Fields)

  $image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
  if($all_spotify_media.media -and !$Refresh_All_Spotify_Media)
  { 
    $counter = 0
    foreach ($Media in $all_spotify_media.media)
    {
      $Array = @()
      $Playlist_name = $null     
      $Playlist_ID = $null
      $Media_Description = $null
      $Track_Total = $null
      $Playlist_URL = $null
      $Web_URL = $null
      $Playlist_encodedtitle = $Null
      $Playlist_encodedtitle = $Media.encodedtitle
      $Playlist_name = $Media.name
      $Playlist_ID = $media.id
      $Media_Description = $Media.Description
      $Track_Total = $Media.Track_Total
      $Playlist_URL = $Media.URL
      $Web_URL = $Media.Web_URL
      $Type = $media.type      
      $Spotify_Path = $media.Spotify_Launch_Path
      $images = $media.images
      $Playlist_tracks = $media.Playlist_tracks
      $synchash.Spotify_GroupName = 'Playlist'
      #$Group_Name = 'Playlist'
      #$Sub_GroupName = 'Artist'
      if($verboselog){write-ezlogs ">>> Found Spotify Playlist: $Playlist_name" -showtime} 
      #$Sub_GroupName = 'Artist_Name'
      foreach($Track in $Playlist_tracks){
        if($Track.id){
          $counter++
          $track_encodedtitle = $Null  
          $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Track.Name)-$($Track.Artists.Name)-$($Track.Album.Name)-$($Playlist_ID)-SpotifyTrack")
          $track_encodedTitle = [System.Convert]::ToBase64String($track_encodedBytes) 
          [int]$hrs = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Hours)
          [int]$mins = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Minutes)
          [int]$secs = $($([timespan]::FromMilliseconds($Track.Duration_ms)).Seconds) 
          $total_time = "$mins`:$secs"
          $thumbimage = $Track.Album.images | where {$_.Width -le 64}
          $albumimage = $Track.Album.images | where {$_.Width -ge 300} | select -last 1
          if($verboselog){write-ezlogs " | Adding Spotify Track: $($Track.Name) - ID $($Track.id)" -showtime} 
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
          $newTableRow.Title = $Track.Name
          $newTableRow.Duration = $total_time
          $newTableRow.Duration_ms = $Track.Duration_ms
          $newTableRow.Track_number = $Track.Track_number
          $newTableRow.Artist_Name = $Track.Artists.Name -join ','
          $newTableRow.Artist = $Track.Artists.Name -join ','
          $newTableRow.Artist_ID = $Track.Artists.id -join ','
          $newTableRow.Artist_url = $Track.Artists.uri -join ','
          $newTableRow.Artist_web_url = $Track.Artists.href -join ','
          $newTableRow.Album_name = $Track.Album.Name
          $newTableRow.Album_ID = $Track.Album.id
          $newTableRow.thumbnail = $thumbimage.url
          $newTableRow.Album_url = $Track.Album.uri
          $newTableRow.Album_web_url = $Track.Album.href
          $newTableRow.Album_images = $albumimage.url
          $newTableRow.Group_Name = $synchash.Spotify_GroupName
          $newTableRow.encodedtitle = $track_encodedTitle
          $newTableRow.ID = $track_encodedTitle
          $newTableRow.playlist_encodedtitle = $Playlist_encodedtitle
          $newTableRow.type = $Track.type
          $newTableRow.Source = $Media.source
          $newTableRow.Spotify_Path = $Spotify_Path 
          if($Spotify_Datatable.datatable.id -notcontains $track_encodedTitle){
            $Null = $Spotify_Datatable.datatable.Rows.Add($newTableRow) 
          }else{
            write-ezlogs "Duplicate Spotify Track found $($Track.Name) - ID $($Track.id) - Playlist $($Playlist_name)" -showtime -warning
          }                       
          #---------------------------------------------- 
          #endregion Add Properties to datatable
          #----------------------------------------------      
        }
      }              
    }
  }
  if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -color cyan -enablelogs} 
  $PerPage = $thisApp.Config.SpotifyBrowser_Paging
  #$syncHash.SpotifyTable.Items.clear()
  if($thisApp.Config.SpotifyBrowser_Paging -ne $Null){
    $approxGroupSize = (@($Spotify_Datatable.datatable).count | Measure-Object -Sum).Sum / $PerPage  
    #$page_size = [math]::ceiling($PerPage / $approxGroupSize) 
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
      #$mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name") | Select-Object -First 1).name
      if($groupMembers.$mostEmpty -notcontains $item){
        $null = $groupMembers.$mostEmpty.Add($item)
        $groupSizes.$mostEmpty += @($item).count
      }
    }     
    $synchash.Spotify_filterView_Groups = $groupmembers.GetEnumerator() | select *
    $synchash.Spotify_View_Groups = $groupmembers.GetEnumerator() | select *
    $synchash.Spotify_TotalView_Groups = ($groupmembers.GetEnumerator() | select *).count
    $synchash.Spotify_CurrentView_Group = ($groupmembers.GetEnumerator() | select * | select -last 1).Name    
    $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Playlist},{[int]$_.Track_Number}
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
    if($synchash.Spotify_GroupName){
      $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $groupdescription.PropertyName = $synchash.Spotify_GroupName
      $view.GroupDescriptions.Clear()
      $null = $view.GroupDescriptions.Add($groupdescription)
      if($Sub_GroupName){
        $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
        $sub_groupdescription.PropertyName = $Sub_GroupName
        $null = $view.GroupDescriptions.Add($sub_groupdescription)
      }
    }elseif($view.GroupDescriptions){
      $view.GroupDescriptions.Clear()
    } 
    if($use_runspace){
      $syncHash.Window.Dispatcher.invoke([action]{
          $syncHash.SpotifyTable.ItemsSource = $view
          $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
          $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"           
      },"Background")     
    }else{
      $syncHash.SpotifyTable.ItemsSource = $view
      $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
      $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"       
    }   
   
  }else{  
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Spotify_Datatable.datatable) 
    if($synchash.Spotify_GroupName){
      $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $groupdescription.PropertyName = $synchash.Spotify_GroupName
      if($view.GroupDescriptions){
        $view.GroupDescriptions.Clear()
        $null = $view.GroupDescriptions.Add($groupdescription)
      }else{
        write-ezlogs "[Import-Spotify] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning
      }
      if($Sub_GroupName){
        $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
        $sub_groupdescription.PropertyName = $Sub_GroupName
        $null = $view.GroupDescriptions.Add($sub_groupdescription)
      }
    }elseif($view.GroupDescriptions){
      $view.GroupDescriptions.Clear()
    } 
    
    if($use_runspace){
      $syncHash.Window.Dispatcher.invoke([action]{
          $syncHash.SpotifyTable.ItemsSource = $view
          $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
          $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"           
      },"Normal")     
    }else{
      $syncHash.SpotifyTable.ItemsSource = $view
      $synchash.Spotify_Table_Total_Media.content = "$(@($syncHash.SpotifyTable.ItemsSource).count) of Total | $(@($Spotify_Datatable.datatable).count)"
      $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"       
    }     
  }
   
  if($Startup)
  {    
  
    if($PerPage -ne $Null){    
      1..($synchash.Spotify_TotalView_Groups) | foreach{
        if($synchash.Spotify_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
          if($use_runspace){
            $syncHash.Window.Dispatcher.invoke([action]{
                $null = $synchash.Spotify_cbNumberOfRecords.items.add("Page $_")
            },"Normal")     
          }else{
            $null = $synchash.Spotify_cbNumberOfRecords.items.add("Page $_")
          }         
        }
      }
    }
    # $synchash.GameGrid.Dispatcher.invoke([action]{ 
    #$syncHash.BrowserGrid.ItemsSource = $Datatable.datatable.DefaultView 
    if($use_runspace){
      $syncHash.Window.Dispatcher.invoke([action]{
          $Null = $synchash.Spotify_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_Btnnext_Scriptblock)      
          $Null = $synchash.Spotify_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_btnPrev_Scriptblock)
          $Null = $synchash.Spotify_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Spotify_cbNumberOfRecords_Scriptblock) 
          #$synchash.SpotifyTable.AutoGenerateColumns = $true
          #$syncHash.SpotifyTable.Background = "gray"
          #$syncHash.SpotifyTable.AlternatingRowBackground = "gray"
          $syncHash.SpotifyTable.CanUserReorderColumns = $true
          $synchash.SpotifyTable.CanUserSortColumns = $true
          #$synchash.SpotifyTable.Foreground = "black"
          #$syncHash.SpotifyTable.RowBackground = "lightgray"
          $syncHash.SpotifyTable.FontWeight = "bold"
          $synchash.SpotifyTable.HorizontalAlignment = "Stretch"
          $synchash.SpotifyTable.CanUserAddRows = $False
          $synchash.SpotifyTable.HorizontalContentAlignment = "left"
          $synchash.SpotifyTable.IsReadOnly = $True
          if($verboselog){write-ezlogs " | Adding Spotify Media table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
          $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
          $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
          $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
          if($verboselog){write-ezlogs " | Setting SpotifyTable Play button click event" -showtime -color cyan -enablelogs} 
          #$buttonstyle = $synchash.Window.TryFindResource('ImageGridButtonStyle')
          #$Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $buttonstyle)
          $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
          $dataTemplate = New-Object System.Windows.DataTemplate
          $dataTemplate.VisualTree = $buttonFactory
          $buttonColumn.CellTemplate = $dataTemplate
          $buttonColumn.Header = 'Play'
          $buttonColumn.DisplayIndex = 0
          $null = $synchash.SpotifyTable.Columns.add($buttonColumn) 
      },"Normal")     
    }else{
      $Null = $synchash.Spotify_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_Btnnext_Scriptblock)      
      $Null = $synchash.Spotify_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Spotify_btnPrev_Scriptblock)
      $Null = $synchash.Spotify_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$Spotify_cbNumberOfRecords_Scriptblock)     
      #$synchash.SpotifyTable.AutoGenerateColumns = $true
      #$syncHash.SpotifyTable.Background = "gray"
      #$syncHash.SpotifyTable.AlternatingRowBackground = "gray"
      $syncHash.SpotifyTable.CanUserReorderColumns = $true
      #$synchash.SpotifyTable.Foreground = "black"
      #$syncHash.SpotifyTable.RowBackground = "lightgray"
      $syncHash.SpotifyTable.FontWeight = "bold"
      $synchash.SpotifyTable.HorizontalAlignment = "Stretch"
      $synchash.SpotifyTable.CanUserAddRows = $False
      $synchash.SpotifyTable.HorizontalContentAlignment = "left"
      $synchash.SpotifyTable.IsReadOnly = $True
      if($verboselog){write-ezlogs " | Adding Spotify Media table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
      if($verboselog){write-ezlogs " | Setting SpotifyTable Play button click event" -showtime -color cyan -enablelogs} 
      $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.Header = 'Play'
      $buttonColumn.DisplayIndex = 0
      $null = $synchash.SpotifyTable.Columns.add($buttonColumn) 
    } 
    if($startup_perf_timer){write-ezlogs " | Seconds to Import-Spotify: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}           
  }
}

#---------------------------------------------- 
#endregion Import-Spotify Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Spotify')

