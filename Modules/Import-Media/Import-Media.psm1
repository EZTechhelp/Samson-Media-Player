<#
    .Name
    Import-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Media Profiles

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-GameManager

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>
#---------------------------------------------- 
#region Import-Media Function
#----------------------------------------------
function Import-Media
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    [string]$Media_Path,
    $all_available_Media,
    $Media_directories,
    [string]$Media_Profile_Directory,
    $Refresh_All_Games,
    $thisApp,
    $Group,
    $Import_Cache_Profile = $startup,
    $thisScript,
    $LocalMedia_Btnnext_Scriptblock = $LocalMedia_Btnnext_Scriptblock,
    $LocalMedia_cbNumberOfRecords_Scriptblock = $LocalMedia_cbNumberOfRecords_Scriptblock,
    $LocalMedia_btnPrev_Scriptblock = $LocalMedia_btnPrev_Scriptblock,
    $PlayMedia_Command,
    [switch]$use_runspace,
    [switch]$VerboseLog = $thisApp.config.Verbose_logging 
  )

  $all_local_media =  [hashtable]::Synchronized(@{})
  $pattern = [regex]::new('$(?<=\.(MP3|mp3|Mp3|mP3|mp4|MP4|Mp4|flac|FLAC|Flac|WAV|wav|Wav|AVI|Avi|avi|wmv|h264|mkv|webm|h265|mov|h264|mpeg|mpg4|movie|mpgx|vob|3gp|m2ts|aac))')
  if($Media_Path){
    write-ezlogs ">>> Getting local media from path $Media_Path" -showtime -color cyan -enablelogs
    if([System.IO.File]::Exists($Media_Path)){ 
      if(([System.IO.FileInfo]::new($Media_Path) | Where{$_.Extension -match $pattern})){
        $Path = $Media_Path
      }else{
        $message = "Provided File $Media_Path is not a valid media type"
      }
    }elseif([System.IO.Directory]::Exists($Media_Path)){      
      if(@([System.IO.Directory]::GetFiles("$($Media_Path)",'*','AllDirectories') | Where{$_ -match $pattern}).count -lt 1){
        $message = "Unable to find any supported media in Directory $Media_Path"
      }else{
        $Path = $Media_Path
      }
    }else{
      write-ezlogs "Provided File $Media_Path is not a valid media type" -showtime -warning
    }
    if($Path){
      $synchash.All_local_Media = Get-LocalMedia -Media_Path $Path -Media_Profile_Directory $Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp
      #TODO: Cleanup old hashtable
      $all_local_media.media = $synchash.All_local_Media
    }else{
      Update-Notifications -Level 'WARNING' -Message $message -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -Open_Flyout
      return
    }
  }else{
    $synchash.All_local_Media = Get-LocalMedia -Media_directories $Media_directories -Media_Profile_Directory $Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -startup 
    #TODO: Cleanup old hashtable
    $all_local_media.media = $synchash.All_local_Media
  }
 
  if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -color cyan -enablelogs} 
  $Fields = @(
    'Track'
    'Title'
    'Artist'
    'Album'
    'Duration'
    'Cover_art'
    'URL'
    'Size'
    'Type'
    'Source'
    'ID'
    'Group_Name'
    'Directory'
    'SongInfo'
    'ItemCount'
  )

  # Add Games to a datatable
 
  $Global:Datatable.datatable = New-Object System.Data.DataTable
  $Null = $Datatable.datatable.Columns.AddRange($Fields)
  #$image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
  if($synchash.All_local_Media -and !$Refresh_All_Media)
  {   
    foreach ($Media in $synchash.All_local_Media | where {$_.encodedtitle})
    {
      $Media_title = $null
      $Artist = $Null
      $encodedtitle = $Null
      #$pattern = [regex]::new('$(?<=\.(MP3|mp3|Mp3|mP3|mp4|MP4|Mp4|flac|FLAC|Flac|WAV|wav|Wav))')     
      $file_count = $null
      $encodedtitle = $Media.encodedtitle
      if($Media.songinfo.title){
        $Media_title = $Media.songinfo.title
      }
      elseif($Media.name){
        $Media_title = $Media.name
      }
      else{
        $Media_title = $null
      }
      if($verboselog){write-ezlogs ">>> Found Local Media title: $Media_title" -showtime} 
      try{
        if($media.songinfo.Artist){
          $artist = $media.songinfo.Artist
          $artist = (Get-Culture).TextInfo.ToTitleCase($artist).trim()          
          if($verboselog){write-ezlogs " | Found count based on matching artist name $artist $($file_count)" -showtime -color cyan -enablelogs}
        }elseif([System.IO.Directory]::Exists($media.directory)){          
          $artist = $media.directory | split-path -Leaf
          $artist = (Get-Culture).TextInfo.ToTitleCase($artist).trim()         
        }else{ 
          write-ezlogs "No Artist name could be generated for $($media | out-string)" -warning
          $artist = $Null
        }
        if($media.directory_filecount){
          $file_count = $media.directory_filecount
          if($verboselog){write-ezlogs " | File count found from profile $($file_count)" -showtime -color cyan -enablelogs} 
        }elseif($artist){
          $file_count = @($all_local_media.media | where {$_.songinfo.Artist -eq $artist}).count 
        }elseif([System.IO.Directory]::Exists($media.directory)){
          if($verboselog){write-ezlogs " | Getting file count for directory $($media.directory)" -showtime -color cyan -enablelogs} 
          $file_count = @([System.IO.Directory]::GetFiles("$($media.directory)",'*','AllDirectories') | Where{$_ -match $pattern}).count
        }else{
          $file_count = "NA"
        }     
        if($media.songinfo.duration){
          $duration = $media.songinfo.duration
        }elseif($media.songinfo.length){
          $duration = $media.songinfo.length
        }else{
          $duration = $Null
        }
        if($media.songinfo.filesize){
          $filesize = $media.songinfo.filesize
        }elseif($media.length){
          $filesize = $media.length
        }else{
          $filesize = $null
        }
      }catch{
        write-ezlogs "[Import-Media] An exception occurred parsing local media properties for $($Media_title)" -showtime -catcherror $_
      }      
      $synchash.LocalMedia_GroupName = 'Group_Name'
      #$Group_Name = 'Group_Name'
          
      #$Sub_GroupName ='Album'
      #$Platform_icon = "$($image_resources_dir)\\Platforms\\$($game.platform_profile.platform).ico"                 
      if($Media_title){
        #---------------------------------------------- 
        #region Add Properties to datatable
        #----------------------------------------------
        try{
          $newTableRow =$Datatable.datatable.NewRow()
          $newTableRow.Track = $media.Songinfo.tracknumber
          $newTableRow.Title = $Media_title
          $newTableRow.Artist = $artist    
          $newTableRow.Album = $media.songinfo.album
          $newTableRow.Duration = $duration
          $newTableRow.URL = $media.url
          $newTableRow.Size = $filesize
          $newTableRow.Type = $media.type
          $newTableRow.Source = $media.Source
          $newTableRow.ID = $encodedtitle
          $newTableRow.Cover_art = $media.Cover_art        
          $newTableRow.Group_Name = "$artist"
          $newTableRow.Directory = [regex]::Escape($media.directory)
          $newTableRow.SongInfo = $media.songinfo                
          $newTableRow.ItemCount = ($media.directory_filecount)
          $Null = $Datatable.datatable.Rows.Add($newTableRow)
        }catch{
          write-ezlogs "[Import-Media] An exception occurred Adding new row to datatable" -showtime -catcherror $_
        }        
        #---------------------------------------------- 
        #endregion Add Properties to datatable
        #----------------------------------------------                 
      }
    }
    
  }
  
  $PerPage = $thisApp.Config.MediaBrowser_Paging
  if($thisApp.Config.MediaBrowser_Paging -ne $Null){
    $approxGroupSize = (@($Datatable.datatable).count | Measure-Object -Sum).Sum / $PerPage  
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
    foreach ($item in $Datatable.datatable) {
      $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name" | where {$_.value -lt $PerPage}) | Select-Object -First 1).name
      #$mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name") | Select-Object -First 1).name
      if($groupMembers.$mostEmpty -notcontains $item){
        $null = $groupMembers.$mostEmpty.Add($item)
        $groupSizes.$mostEmpty += @($item).count
      }
    }
    $synchash.LocalMedia_filterView_Groups = $groupmembers.GetEnumerator() | select *     
    $synchash.LocalMedia_View_Groups = $groupmembers.GetEnumerator() | select *
    $synchash.LocalMedia_TotalView_Groups = ($groupmembers.GetEnumerator() | select *).count
    $synchash.LocalMedia_CurrentView_Group = ($groupmembers.GetEnumerator() | select * | select -last 1).Name    
    $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Artist},{[int]$_.Track}
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
  }else{  
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Datatable.datatable) 
  }   
  $synchash.LocalMedia_View = $view
  if($synchash.LocalMedia_GroupName){
    $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
    $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
    if($synchash.LocalMedia_View.GroupDescriptions){
      $synchash.LocalMedia_View.GroupDescriptions.Clear()    
    }else{
      write-ezlogs "[Import-Media] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning
    }
    $null = $synchash.LocalMedia_View.GroupDescriptions.Add($groupdescription)
    if($Sub_GroupName){
      $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $sub_groupdescription.PropertyName = $Sub_GroupName
      $null = $synchash.LocalMedia_View.GroupDescriptions.Add($sub_groupdescription)
    }
  }elseif($synchash.LocalMedia_View.GroupDescriptions){
    $synchash.LocalMedia_View.GroupDescriptions.Clear()
  } 
  if($use_runspace){
    $syncHash.Window.Dispatcher.invoke([action]{
        $syncHash.MediaTable.ItemsSource = $synchash.LocalMedia_View
        $synchash.Media_Table_Total_Media.content = "$(@($syncHash.MediaTable.ItemsSource).count) of Total | $(@($Datatable.datatable).count)"
        $synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)"           
    },"Normal")     
  }else{
    $syncHash.MediaTable.ItemsSource = $synchash.LocalMedia_View
    $synchash.Media_Table_Total_Media.content = "$(@($syncHash.MediaTable.ItemsSource).count) of Total | $(@($Datatable.datatable).count)"
    $synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)"       
  }    
  if($Startup)
  {
    if($PerPage -ne $Null){
    
      1..($synchash.LocalMedia_TotalView_Groups) | foreach{
        if($synchash.LocalMedia_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
          if($use_runspace){
            $syncHash.Window.Dispatcher.invoke([action]{
                $null = $synchash.LocalMedia_cbNumberOfRecords.items.add("Page $_")
            },"Normal")     
          }else{
            $null = $synchash.LocalMedia_cbNumberOfRecords.items.add("Page $_")
          }         
        }
      }
    } 
    if($use_runspace){
      $syncHash.Window.Dispatcher.invoke([action]{
          $Null = $synchash.LocalMedia_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_Btnnext_Scriptblock)      
          $Null = $synchash.LocalMedia_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_btnPrev_Scriptblock)
          $Null = $synchash.LocalMedia_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$LocalMedia_cbNumberOfRecords_Scriptblock)     
          #$synchash.MediaTable.AutoGenerateColumns = $true
          #$syncHash.MediaTable.Background = "gray"
          #$syncHash.MediaTable.AlternatingRowBackground = "gray"
          $syncHash.MediaTable.CanUserReorderColumns = $true
          #$synchash.MediaTable.Foreground = "black"
          #$syncHash.MediaTable.RowBackground = "lightgray"
          $syncHash.MediaTable.FontWeight = "bold"
          $synchash.MediaTable.CanUserSortColumns = $true
          $synchash.MediaTable.HorizontalAlignment = "Stretch"
          $synchash.MediaTable.CanUserAddRows = $False
          $synchash.MediaTable.HorizontalContentAlignment = "left"
          #$synchash.mediatable.EnableColumnVirtualization = $true
          $synchash.MediaTable.IsReadOnly = $True  
          if($verboselog){write-ezlogs " | Adding Media table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
          $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
          $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
          $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
          if($verboselog){write-ezlogs " | Setting MediaTable Play button click event" -showtime -color cyan -enablelogs} 
          $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
          $dataTemplate = New-Object System.Windows.DataTemplate
          $dataTemplate.VisualTree = $buttonFactory
          $buttonColumn.CellTemplate = $dataTemplate
          $buttonColumn.Header = 'Play'
          $buttonColumn.DisplayIndex = 0
          $null = $synchash.MediaTable.Columns.add($buttonColumn)             
      },"Normal") 
    }else{
      $Null = $synchash.LocalMedia_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_Btnnext_Scriptblock)      
      $Null = $synchash.LocalMedia_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_btnPrev_Scriptblock)
      $Null = $synchash.LocalMedia_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$LocalMedia_cbNumberOfRecords_Scriptblock)     
      #$synchash.MediaTable.AutoGenerateColumns = $true
      #$syncHash.MediaTable.Background = "gray"
      #$syncHash.MediaTable.AlternatingRowBackground = "gray"
      $syncHash.MediaTable.CanUserReorderColumns = $true
      #$synchash.MediaTable.Foreground = "black"
      #$syncHash.MediaTable.RowBackground = "lightgray"
      $syncHash.MediaTable.FontWeight = "bold"
      $synchash.MediaTable.HorizontalAlignment = "Stretch"
      $synchash.MediaTable.CanUserAddRows = $False
      $synchash.MediaTable.HorizontalContentAlignment = "left"
      #$synchash.mediatable.EnableColumnVirtualization = $true
      $synchash.MediaTable.IsReadOnly = $True  
      if($verboselog){write-ezlogs " | Adding Media table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
      if($verboselog){write-ezlogs " | Setting MediaTable Play button click event" -showtime -color cyan -enablelogs} 
      $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.Header = 'Play'
      $buttonColumn.DisplayIndex = 0
      $null = $synchash.MediaTable.Columns.add($buttonColumn) 
    }
    if($startup_perf_timer){write-ezlogs " | Seconds to Import-Media: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}    
  }
}

#---------------------------------------------- 
#endregion Import-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Media')

