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
    [switch]$Refresh_All_Media,
    $thisApp,
    $Group,
    $Import_Cache_Profile = $startup,
    $thisScript,
    $PlayMedia_Command,
    [switch]$use_runspace,
    [switch]$VerboseLog = $thisApp.config.Verbose_logging 
  )
  try{
    $synchash.LocalMedia_Progress_Ring.isActive = $true
  }catch{
    write-ezlogs "An exception occurred updating LocalMedia_Progress_Ring" -showtime -catcherror $_
  }  
  $all_local_media =  [hashtable]::Synchronized(@{})
  $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
  if($Startup){
    $Refresh_All_Media = $true
    [System.Windows.RoutedEventHandler]$LocalMedia_Btnnext_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
          write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
        }   
        if($synchash.LocalMedia_CurrentView_Group -eq $synchash.LocalMedia_TotalView_Groups){
          if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.LocalMedia_TotalView_Groups) reached" -showtime -warning}
        }else{
          $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.LocalMedia_CurrentView_Group -and $_.Name -le $synchash.LocalMedia_TotalView_Groups} | select -Last 1).value  | Sort-Object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
          if($synchash.LocalMedia_GroupName -and $view){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
            if($view.GroupDescriptions){
              $view.GroupDescriptions.Clear()
            }
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}   
          $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.LocalMedia_CurrentView_Group -and $_.Name -le $synchash.LocalMedia_TotalView_Groups} | select -last 1).Name       
          $synchash.LocalMedia_View = $view   
          #$synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)" 
          $synchash.LocalMedia_TableUpdate_timer.start()     
          #$synchash.MediaTable.ItemsSource = $view
          #$synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"      
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
      }catch{
        write-ezlogs 'An exception occurred in LocalMedia-BtnPrev click event' -showtime -catcherror $_
      }      
    }.GetNewClosure()
    [System.Windows.RoutedEventHandler]$LocalMedia_cbNumberOfRecords_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
          write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
        }          
        if($synchash.LocalMedia_cbNumberOfRecords.SelectedIndex -ne -1){
          $selecteditem = ($synchash.LocalMedia_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
          if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)"}
          if($synchash.LocalMedia_cbNumberOfRecords.Selecteditem -ne $synchash.LocalMedia_CurrentView_Group){
            $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)              
            if($synchash.LocalMedia_GroupName -and $view){
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
              if($view.GroupDescriptions){
                $view.GroupDescriptions.Clear()
              }
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}     
            $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name
            $synchash.LocalMedia_View = $view   
            $synchash.LocalMedia_TableUpdate_timer.start()                             
            #$synchash.MediaTable.ItemsSource = $view
            #$synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)"
            #$synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"
            if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
          }
        }          
      }catch{write-ezlogs 'An exception occurred in LocalMedia_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_}   
    }.GetNewClosure()
    [System.Windows.RoutedEventHandler]$LocalMedia_btnPrev_Scriptblock = {
      try{
        if($thisapp.Config.Verbose_logging){
          write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
          write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
        }   
        if($synchash.LocalMedia_CurrentView_Group -le 1){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.LocalMedia_TotalView_Groups) reached" -showtime -warning}}else{
          $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.LocalMedia_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)          
          if($synchash.LocalMedia_GroupName -and $view){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
            if($view.GroupDescriptions){
              $view.GroupDescriptions.Clear()
            }
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()} 
          $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.LocalMedia_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name
          $synchash.LocalMedia_View = $view   
          $synchash.LocalMedia_TableUpdate_timer.start()                             
          #$synchash.MediaTable.ItemsSource = $view
          #$synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.LocalMedia_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name
          #$synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)"  
          #$synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"       
        }   
        if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
      }catch{
        write-ezlogs 'An exception occurred in LocalMedia-BtnNext click event' -showtime -catcherror $_
      }    
    }.GetNewClosure()
    $Null = $synchash.LocalMedia_btnNext.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_Btnnext_Scriptblock)      
    $Null = $synchash.LocalMedia_btnPrev.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LocalMedia_btnPrev_Scriptblock)
    $Null = $synchash.LocalMedia_cbNumberOfRecords.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent,$LocalMedia_cbNumberOfRecords_Scriptblock)     
  }
  
  $synchash.import_LocalMedia_scriptblock = ({
      try{
        if($Media_Path){
          write-ezlogs ">>> Getting local media from path $Media_Path" -showtime -color cyan -enablelogs
          if([System.IO.File]::Exists($Media_Path)){ 
            if(([System.IO.FileInfo]::new($Media_Path) | Where{$_.Extension -match $media_pattern})){
              $Path = $Media_Path
            }else{
              $message = "Provided File $Media_Path is not a valid media type"
            }
          }elseif([System.IO.Directory]::Exists($Media_Path)){      
            if(@([System.IO.Directory]::EnumerateFiles($Media_Path,'*','AllDirectories') | where {$_ -match $media_pattern}  ).count -lt 1){
              $message = "Unable to find any supported media in Directory $Media_Path"
            }else{
              $Path = $Media_Path
            }
          }else{
            write-ezlogs "Provided File $Media_Path is not a valid media type" -showtime -warning
          }
          if($Path){
            $synchash.All_local_Media = Get-LocalMedia -Media_Path $Path -Media_Profile_Directory $Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -Refresh_All_Media:$Refresh_All_Media
            #TODO: Cleanup old hashtable
            $all_local_media.media = $synchash.All_local_Media
          }else{
            Update-Notifications -Level 'WARNING' -Message $message -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -Open_Flyout
            return
          }
        }else{
          $Global:get_LocalMedia_Measure = measure-command {
            $synchash.All_local_Media = Get-LocalMedia -Media_directories $Media_directories -Media_Profile_Directory $Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -startup -Refresh_All_Media:$Refresh_All_Media
          }
          if($thisApp.Config.startup_perf_timer){write-ezlogs " | Get-LocalMedia Measure: $($get_LocalMedia_Measure | out-string)" -showtime} 
          #TODO: Cleanup old hashtable
          $all_local_media.media = $synchash.All_local_Media
        }
 
        if($verboselog){write-ezlogs " | Compiling datatable and adding items" -showtime -color cyan -enablelogs} 
        $Fields = @(
          'Number'
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
          'Profile_Path'
          'SongInfo'
          'ItemCount'
        )

        # Add Games to a datatable
        $PerPage = $thisApp.Config.MediaBrowser_Paging
        $Global:Datatable.datatable = New-Object System.Data.DataTable
        $Null = $Datatable.datatable.Columns.AddRange($Fields)
        #$image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
        $count = 0
        if($synchash.All_local_Media)
        {   
          $Global:media_to_Datatable_Measure = measure-command {   
            foreach ($Media in $synchash.All_local_Media | where {$_.encodedtitle})
            {
              $Media_title = $null
              $Artist = $Null
              $encodedtitle = $Null    
              $file_count = $null
              $encodedtitle = $Media.encodedtitle
              if($Media.title){
                $Media_title = $Media.title
              }elseif($Media.songinfo.title){
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
                  write-ezlogs "| Generating Artist name based on media directory $($media.directory)" -showtime
                  if(([System.IO.DirectoryInfo]::new($media.directory).parent)){
                    $artist = ([System.IO.Path]::GetFileNameWithoutExtension($media.directory))
                    $artist = (Get-Culture).TextInfo.ToTitleCase($artist).trim()   
                  }else{
                    $artist = $media.directory
                  }                         
                }else{ 
                  write-ezlogs "No Artist name could be generated for $($media | out-string)" -warning
                  $artist = $Null
                }
                <#          if($media.directory_filecount){
                    $file_count = $media.directory_filecount
                    if($verboselog){write-ezlogs " | File count found from profile $($file_count)" -showtime -color cyan -enablelogs} 
                    }elseif($artist){
                    $file_count = @($all_local_media.media | where {$_.songinfo.Artist -eq $artist}).count 
                    }elseif([System.IO.Directory]::Exists($media.directory)){
                    if($verboselog){write-ezlogs " | Getting file count for directory $($media.directory)" -showtime -color cyan -enablelogs} 
                    $file_count = @([System.IO.Directory]::EnumerateFiles($media.directory,'*','AllDirectories') | where {$_ -match $media_pattern} ).count
                    }else{
                    $file_count = "NA"
                }#>     
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
                $count++
                try{
                  $newTableRow =$Datatable.datatable.NewRow()
                  $newTableRow.Number = $count
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
                  $newTableRow.Directory = $media.directory
                  $newTableRow.SongInfo = $media.songinfo   
                  $newTableRow.Profile_Path = $media.Profile_Path                       
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
          if($thisApp.Config.startup_perf_timer){write-ezlogs " | Media_to_Datatable_Measure: $($media_to_Datatable_Measure | out-string)" -showtime}
        }
        $Global:media_paging_Measure = measure-command {
          if($thisApp.Config.MediaBrowser_Paging -ne $Null){
            $approxGroupSize = (@($synchash.All_local_Media).count | Measure-Object -Sum).Sum / $PerPage  
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
            $itemsource = ($groupmembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
          }else{  
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Datatable.datatable) 
          }
        }  
        if($thisApp.Config.startup_perf_timer){write-ezlogs " | Media_Paging_Measure: $($Media_Paging_Measure | out-string)" -showtime} 
        $synchash.LocalMedia_View = $view
        if($synchash.LocalMedia_GroupName -and $synchash.LocalMedia_View){
          try{
            $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
            if($synchash.LocalMedia_View.GroupDescriptions){
              $synchash.LocalMedia_View.GroupDescriptions.Clear()    
            }
            $null = $synchash.LocalMedia_View.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $synchash.LocalMedia_View.GroupDescriptions.Add($sub_groupdescription)
            }
          }catch{
            write-ezlogs "An exception occurred attempting to set group descriptions" -showtime -catcherror $_
          }
        }elseif($synchash.LocalMedia_View.GroupDescriptions){
          $synchash.LocalMedia_View.GroupDescriptions.Clear()
        }else{
          write-ezlogs "[Import-Media] View group descriptions not available or null! Likely CollectionViewSource was empty!" -showtime -warning
        }  
        if($Startup)
        {         

          $syncHash.Window.Dispatcher.invoke([action]{                     
              $syncHash.MediaTable.CanUserReorderColumns = $true
              $syncHash.MediaTable.FontWeight = "bold"
              $synchash.MediaTable.CanUserSortColumns = $true
              $synchash.MediaTable.HorizontalAlignment = "Stretch"
              $synchash.MediaTable.CanUserAddRows = $False
              $synchash.MediaTable.HorizontalContentAlignment = "left"
              $synchash.MediaTable.IsReadOnly = $True  
              if($verboselog){write-ezlogs " | Adding Media table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
              $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
              $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
              $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
              if($verboselog){write-ezlogs " | Setting MediaTable Play button click event" -showtime -color cyan -enablelogs} 
              $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
              $dataTemplate = New-Object System.Windows.DataTemplate
              $dataTemplate.VisualTree = $buttonFactory
              $buttonColumn.CellTemplate = $dataTemplate
              $buttonColumn.Header = 'Play'
              $buttonColumn.DisplayIndex = 0
              $null = $synchash.MediaTable.Columns.add($buttonColumn)             
          },"Normal")  
        }  
        $synchash.LocalMedia_TableUpdate_timer.start()       
        if($thisApp.Config.startup_perf_timer){write-ezlogs " | Seconds to Import-Media: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
        if($error){
          write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
        }
      }catch{
        write-ezlogs 'An exception occurred in import_LocalMedia_scriptblock' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
      }  
  }.GetNewClosure())
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $synchash.import_LocalMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'import_LocalMedia_scriptblock'
}

#---------------------------------------------- 
#endregion Import-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Media')

