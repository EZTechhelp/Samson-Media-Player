<#
    .Name
    Invoke-MediaFilter

    .Version 
    0.1.0

    .SYNOPSIS
    FIlter, sort and grouping functions for Media Table 

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
#region Invoke-MediaFilter Function
#----------------------------------------------
function Invoke-MediaFilter
{
  Param (
    [string]$GameName,
    [switch]$Verboselog,
    $Platform_profile,
    $platform_encodedTitle,
    $all_installed_apps,
    $syncHash,
    [switch]$group,
    [switch]$filter,
    [switch]$Sort,
    [switch]$searchOnly,
    $sort_direction,
    $thisApp,
    [System.Collections.Hashtable]$imagedatatable,
    $Save_GameSessions,
    $encodedTitle,
    [switch]$userunspace
  )
  
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  if($verboselog){write-ezlogs ">>>> Sorting and Filtering Image Grid" -showtime -color cyan}
  #$Global:sorttable =  [hashtable]::Synchronized(@{})
  #$Global:sorttable.array = New-Object -TypeName 'System.Collections.ArrayList'
  <#  if($group){
      foreach($game in $imagedatatable.array){
      if($thisApp.config.Favorites -contains $game.encodedtitle){
      $Group_Name = "Group_name"
      $game.Group_name = "Favorites"            
      }
      else{
      $Group_Name = "Group_name"
      $game.Group_name = "Non_Favorites"
      } 
      }
  }#>
  if($userunspace){
    $synchash.Window.Dispatcher.invoke([action]{        
        $Global:platform_filter = $($syncHash.ImageGrid_FilterBy_Name_list.SelectedItem)
        $Global:Filter_text = $synchash.ImageGrid_Filter_TextBox.text
        $Global:sortby_name = $syncHash.ImageGrid_Sortby_Name_list.SelectedItem
        $Global:GroupBy_name =  $syncHash.ImageGrid_Groupby_Name_list.SelectedItem
        $Global:Show_Uninstalled_games = $syncHash.Show_Uninstalled_Games_Checkbox.IsChecked
        #$imagedatatable.array = [System.Windows.Data.CollectionViewSource]::GetDefaultView( $syncHash.ImageGrid.ItemsSource) 
        #$imagedatatable.array = $syncHash.ImageGrid.ItemsSource
    })
  }else{
    $Global:platform_filter = $($syncHash.ImageGrid_FilterBy_Name_list.SelectedItem)
    $Global:Filter_text = $synchash.ImageGrid_Filter_TextBox.text
    $Global:sortby_name = $syncHash.ImageGrid_Sortby_Name_list.SelectedItem
    $Global:GroupBy_name =  $syncHash.ImageGrid_Groupby_Name_list.SelectedItem
    $Global:Show_Uninstalled_games = $syncHash.Show_Uninstalled_Games_Checkbox.IsChecked
    #$imagedatatable.array = [System.Windows.Data.CollectionViewSource]::GetDefaultView( $syncHash.ImageGrid.ItemsSource) 
  }

  if(!$imagedatatable.array -or $userunspace){
        $imagedatatable = $syncHash.ImageGrid.Tag.imagedatatable         
  }
  if($imagedatatable.array){
    if($syncHash.Expand_Groups_Checkbox.IsChecked){
      $imagedatatable.array | foreach {
        Add-Member -InputObject $_ -Name "isExpanded" -Value $true -MemberType NoteProperty -Force 
      }
    }else{
      $imagedatatable.array | foreach {
        if($thisApp.config.Group_By -eq 'Favorites' -and $_.Group_Name -eq 'Favorites'){
          Add-Member -InputObject $_ -Name "isExpanded" -Value $true -MemberType NoteProperty -Force
        }elseif($thisApp.config.Group_By -eq 'Platform'){
          Add-Member -InputObject $_ -Name "isExpanded" -Value $true -MemberType NoteProperty -Force
        }elseif($thisApp.config.Group_By -eq 'Install State' -and $_.IsInstalled -eq 'Installed'){
          Add-Member -InputObject $_ -Name "isExpanded" -Value $true -MemberType NoteProperty -Force
        }else{
          Add-Member -InputObject $_ -Name "isExpanded" -Value $false -MemberType NoteProperty -Force
        }
      }
    }
  } 

  if($sort -or $group){
    if(-not [string]::IsNullOrEmpty($sortby_name)){
      if($sortby_name -eq 'Title')
      { 
        if($verboselog){write-ezlogs " | Sorting by Title" -showtime}
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = ($imagedatatable.array | sort-object -property{$_.platform},{$_.title})
          }else{
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.group_name},{$_.title})
          }
        }else{
          $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.title})
        }
      }
      elseif($sortby_name -eq 'Install State')
      {
        if($verboselog){write-ezlogs " | Sorting by Install State" -showtime}
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.platform},{($_.IsInstalled -replace '(\d+).*', '$1')})
          }else{
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.group_name},{($_.IsInstalled -replace '(\d+).*', '$1')})
          }        
        }else{
          $imagedatatable.array = ($imagedatatable.array | sort-object -property {($_.IsInstalled -replace '(\d+).*', '$1')},{$_.platform})
        }
      }
      elseif($sortby_name -eq 'Size on Disk')
      {
        if($verboselog){write-ezlogs " | Sorting by Size on Disk" -showtime}
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.platform},@{Expression = {[int](($_.InstallSize -replace 'Installed - ','' -replace ' GB','' -replace 'MB','' -replace 'Not Installed','').trim())}; Ascending = $false})
          }else{
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.group_name},@{Expression = {[int](($_.InstallSize -replace 'Installed - ','' -replace ' GB','' -replace 'MB','' -replace 'Not Installed','').trim())}; Ascending = $false})
          }        
        }else{
          $imagedatatable.array = ($imagedatatable.array | sort-object -property @{Expression = {[int](($_.InstallSize -replace 'Installed - ','' -replace ' GB','' -replace 'MB','' -replace 'Not Installed','').trim())}; Ascending = $false})
        }
      
      }
      elseif($sortby_name -eq 'Last Played' -and $Save_GameSessions)
      {  
        #$ToNatural= { [regex]::Replace($_.Last_Played_time_sort, '\d+',{$args[0].Value.Padleft(20)})}
        #$imagedatatable.array = $imagedatatable.array | Sort-Object -Property @{Expression = {$_.group_name}; Ascending = $true},@{Expression = {Get-date $([datetime]::ParseExact($($_.Last_Played_time_sort | select -Last 1),'MM-dd-yyyy hh:mm:ss:tt',[System.Globalization.CultureInfo]::InvariantCulture)) -Format 'yyyy-MM-ddTHH:mm:ss'}; Ascending = $false} 
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = $imagedatatable.array | Sort-Object -Property {$_.platform},@{Expression = {$_.Last_Played_time_sort -as [Datetime]}; Ascending = $false}
          }else{
            $imagedatatable.array = $imagedatatable.array | Sort-Object -Property {$_.group_name},@{Expression = {$_.Last_Played_time_sort -as [Datetime]}; Ascending = $false}
          }        
        }else{
          $imagedatatable.array = $imagedatatable.array | Sort-Object -Property @{Expression = {$_.Last_Played_time_sort -as [Datetime]}; Ascending = $false}
        }         
      }
      elseif($sortby_name -eq 'Time Played' -and $Save_GameSessions)
      { 
        if($verboselog){write-ezlogs " | Sorting by Time Played" -showtime}
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = $imagedatatable.array | Sort-Object -Property {$_.platform},@{Expression = {[int]$_.Total_Time_Played}; Ascending = $false} 
          }else{
            $imagedatatable.array = $imagedatatable.array | Sort-Object -Property {$_.group_name},@{Expression = {[int]$_.Total_Time_Played}; Ascending = $false} 
          }        
        }else{
          $imagedatatable.array = $imagedatatable.array | Sort-Object -Property @{Expression = {[int]$_.Total_Time_Played}; Ascending = $false} 
        }   
      }                 
      else
      {  
        if(-not [string]::IsNullOrEmpty($GroupBy_name)){
          if($GroupBy_name -eq 'Platform'){
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.platform},{$_.platform}) 
          }else{
            $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.group_name},{$_.platform})
          }        
        }else{
          $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.platform})
        }
      }
    }
    else 
    {
      if($verboselog){write-ezlogs " | Sorting by (Default) Platform" -showtime}
      if(-not [string]::IsNullOrEmpty($GroupBy_name)){
        $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.group_name},{$_.platform})
      }else{
        $imagedatatable.array = ($imagedatatable.array | sort-object -property {$_.platform})
      }
    }
  }

  $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($imagedatatable.array)   
  if($filter -and $view){
    #---------------------------------------------- 
    #region Search
    #----------------------------------------------   
   
    if($Show_Uninstalled_games){
      $Global:state_filter = "*Installed*"
      $favorite_filter = "Favorites"
      $view.Filter = {
        param ($item) 
        #write-ezlogs "[Uninstall-Checked] Title $($item.title)" -color cyan
        #write-ezlogs "[Uninstall-Checked]  | IsInstalled $($item.IsInstalled) - (filter  $state_filter)" -color cyan
        if($($platform_filter) -and $platform_filter -eq 'Favorites'){
          $output = $($item.IsInstalled) -and $($item.title) -match $("$($Filter_text)") -and $($item.Group_Name) -like 'Favorites'
        }elseif($($platform_filter)){
          $output = $($item.IsInstalled) -and $($item.title) -match $("$($Filter_text)") -and $($item.platform) -like $($platform_filter)
        }else{
          $output = $($item.IsInstalled) -and $($item.title) -match $("$($Filter_text)") 
        }
        #write-ezlogs "[Uninstall-Checked]  | Result $output" -color cyan
        $output        
      }
    }
    else
    {
      $Global:state_filter = "Not Installed"       
      $view.Filter = {
        param ($item)       
        #write-ezlogs "[Uninstall-NOTChecked] Title $($item.title)" -color magenta
        #write-ezlogs "[Uninstall-NOTChecked]  | IsInstalled $($item.IsInstalled) - (filter  $state_filter)" -color magenta
        
        if($($platform_filter) -and $platform_filter -eq 'Favorites'){
          $output =  $($item.IsInstalled) -ne $state_filter -and $($item.title) -match $("$($Filter_text)") -and $($item.Group_Name) -like 'Favorites'
        }elseif($($platform_filter)){
          $output =  $($item.IsInstalled) -ne $state_filter -and $($item.title) -match $("$($Filter_text)") -and $($item.platform) -like $($platform_filter)
        }else{
          $output =  $($item.IsInstalled) -ne $state_filter -and $($item.title) -match $("$($Filter_text)") 
        }
        #write-ezlogs "[Uninstall-NOTChecked]  | Result $output" -color magenta
        $output        
        
      }
    } 
    #---------------------------------------------- 
    #endregion Search
    #---------------------------------------------- 
  }  
  #if($group){
  if($thisApp.config.Group_By -eq 'Favorites')
  {
    $IsGroup = $true
    $Group_Name = "Group_Name"
  }
  elseif($thisApp.config.Group_By -eq 'Install State')
  {
    $IsGroup = $true
    $Group_Name = "IsInstalled" 
  }
  elseif($thisApp.config.Group_By -eq 'Platform')
  {
    $IsGroup = $true
    $Group_Name = "Platform"   
  }
  else
  {
    $IsGroup = $false
  } 
  

  
  
  
  if($IsGroup -and $view){
    $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
    $groupdescription.PropertyName = $Group_Name
    $view.GroupDescriptions.Clear()
    $null = $view.GroupDescriptions.Add($groupdescription)
  }elseif($view.GroupDescriptions){
    $view.GroupDescriptions.Clear()
  }     
  # }


  #write-ezlogs "$($view.Total_Time_Played)" 

  #$imagedatatable.array.DefaultView.RowFilter  = $filter_string
  <#  if($Sort){
      $view.SortDescriptions.Clear()
      if(!$sort_direction){
      $sort_direction = 'Ascending'
      }  
      if($syncHash.ImageGrid_Sortby_Name_list.SelectedIndex -ne -1){ 
    
      if($syncHash.ImageGrid_Sortby_Name_list.SelectedItem -eq 'Title')
      {
      $sortby = 'title'
      }
      elseif($syncHash.ImageGrid_Sortby_Name_list.SelectedItem -eq 'Install State')
      {
      $sortby = $('IsInstalled')
      $sort_direction = 'Descending'
      }
      elseif($syncHash.ImageGrid_Sortby_Name_list.SelectedItem -eq 'Size on Disk')
      {
      $sortby =  'Size on Disk'
      $sort_direction = 'Descending' #$('State' -replace 'Installed - ','' -replace ' GB','' -replace 'Not Installed','')             
      } 
      elseif($syncHash.ImageGrid_Sortby_Name_list.SelectedItem -eq 'Last Played' -and $Save_GameSessions)
      {   
      $sortby = $('Last_played_time')               
      }
      elseif($syncHash.ImageGrid_Sortby_Name_list.SelectedItem -eq 'Time Played' -and $Save_GameSessions)
      {  
      $sortby = $('Total_Time_Played')               
      }                                
      else
      {
      $sortby = $('Platform') 
      } 
      if(-not [string]::IsNullOrEmpty($thisApp.config.Group_By)){
      $Group_sort_ascend = New-Object System.ComponentModel.SortDescription('Group_Name','Ascending')
      $Null = $view.SortDescriptions.Add($Group_sort_ascend) 
      $ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
      }     
      $sort_ascend = New-Object System.ComponentModel.SortDescription($sortby,$sort_direction)
      
      $view.SortDescriptions.Add($sort_ascend)     
      }else{
      $view.SortDescriptions.Clear()
      }
  } #> 
  if($userunspace){
    $synchash.Window.Dispatcher.invoke([action]{
        $syncHash.ImageGrid.ItemsSource = $view 
        $synchash.GameGrid.ItemsSource = $view
        if($synchash.imageGrid.ItemsSource.NeedsRefresh){
          $synchash.imageGrid.ItemsSource.Refresh()
        }
        if($synchash.GameGrid.ItemsSource.NeedsRefresh){
          $synchash.GameGrid.ItemsSource.Refresh()
        }  
        $synchash.total_games.content = "Total | $($syncHash.ImageGrid.items.count)"
        $synchash.Game_Table_Total_Games.content = "Total | $($syncHash.GameGrid.items.count)"
        $synchash.total_games.content = "Total | $($syncHash.ImageGrid.items.count)"
        $synchash.Game_Table_Total_Games.content = "Total | $($syncHash.GameGrid.items.count)"        
    })         
  }else{
    $syncHash.ImageGrid.ItemsSource = $view 
    $synchash.GameGrid.ItemsSource = $view
    if($synchash.imageGrid.ItemsSource.NeedsRefresh){
      $synchash.imageGrid.ItemsSource.Refresh()
    }
    if($synchash.GameGrid.ItemsSource.NeedsRefresh){
      $synchash.GameGrid.ItemsSource.Refresh()
    }    
    $synchash.total_games.content = "Total | $($syncHash.ImageGrid.items.count)"
    $synchash.Game_Table_Total_Games.content = "Total | $($syncHash.GameGrid.items.count)"            
    $synchash.total_games.content = "Total | $($syncHash.ImageGrid.items.count)"
    $synchash.Game_Table_Total_Games.content = "Total | $($syncHash.GameGrid.items.count)"    
  }
 
}
#---------------------------------------------- 
#endregion Invoke-MediaFilter Function
#----------------------------------------------
Export-ModuleMember -Function @('Invoke-MediaFilter')