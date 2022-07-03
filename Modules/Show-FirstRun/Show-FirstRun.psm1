<#
    .Name
    Show-FirstRun 

    .Version 
    0.0.1

    .SYNOPSIS
    Displays a window on first time app run to provide setup options 

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
# Mahapps Library
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
Add-Type -AssemblyName WindowsFormsIntegration
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
function Close-FirstRun (){
  Param (
    [switch]$First_Run,
    [switch]$Update,
    [switch]$Use_Runspace,
    $thisScript,
    $synchash,
    $thisApp
  )
  if($use_runspace){
    $hashsetup.window.Dispatcher.Invoke("Normal",[action]{ 
        $hashsetup.window.close() 
    })
  }else{
    $hashsetup.window.close() 
  }
  #$hashsetup.window.close()
}


#---------------------------------------------- 
#region Show-FirstRun Function
#----------------------------------------------
function Show-FirstRun{
  Param (
    [string]$PageTitle,
    [string]$PageHeader,
    [string]$Logo,
    [switch]$First_Run,
    [switch]$Update,
    [switch]$Use_Runspace,
    $thisScript,
    $synchash,
    $thisApp,
    $hash,
    $PlaySpotify_Media_Command,
    $PlayMedia_Command,
    $Script_Modules,
    [string]$all_games_profile_path,
    $Platform_launchers,
    $Save_GameSessions,
    $all_installed_games,
    [string]$Game_Profile_Directory,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog,
    [switch]$Export_Profile,
    [switch]$update_global
  )  
  $global:hashsetup = [hashtable]::Synchronized(@{}) 
  $Global:Current_Folder = $($thisScript.path | Split-path -Parent)
  $hashsetup.Update_LocalMedia_Sources = $false
  $hashsetup.Update_YoutubeMedia_Sources = $false
  $hashsetup.Remove_YoutubeMedia_Sources = $false
  $hashsetup.Remove_LocalMedia_Sources = $false
  $hashsetup.Update = $update
  if(!([System.IO.Directory]::Exists("$Current_Folder\\Views"))){
    $Global:Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
  }   
  #$Splash_setup = {
  if($thisapp){
    $thisApp.Config = Import-Clixml $thisApp.Config.Config_path
  }
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $pattern3 = "[`?�™:$illegal]"     
  
  $FirstRun_Scriptblock = {
    #---------------------------------------------- 
    #region Update-MediaLocations Function
    #----------------------------------------------
    function Update-MediaLocations
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
        $hashsetup,
        [switch]$VerboseLog
      )
      $Fields = @(
        'Number'
        'Path'
        'MediaCount'
      )
      if(!$hashsetup.MediaLocations_Grid.items){
        $Global:Locationstable =  [hashtable]::Synchronized(@{})
        $Global:Locationstable.datatable = New-Object System.Data.DataTable 
        [void]$Locationstable.datatable.Columns.AddRange($Fields)
        $Number = 1
      }else{
        $Number = $hashsetup.MediaLocations_Grid.items.Number | select -last 1
        $Number++
      }
      if($VerboseLog){write-ezlogs ">>>> Updating Media Locations table" -showtime -enablelogs}
      if($Locations_array)
      {
        foreach ($n in $Locations_array)
        {
          $Array = New-Object System.Collections.ArrayList
          $Null = $array.add($n.Number)
          $Null = $array.add($n.Path)
          [void]$Locationstable.datatable.Rows.Add($array)
        } 
      }

      if($VerboseLog){write-ezlogs " | Adding Number: $Number -- Path: $path" -showtime -enablelogs}
      $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($path)-Local")
      $encodedpath = [System.Convert]::ToBase64String($encodedBytes) 
      $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
      $hashsetup.Media_Progress_Ring.isActive = $true
      $hashsetup.Media_Path_Browse.isEnabled = $false
      $hashsetup.MediaLocations_Grid.isEnabled = $false



      $setupbutton_status = $hashSetup.Save_Setup_Button.isEnabled
      $hashSetup.Save_Setup_Button.isEnabled = $false
      $enumerate_files_Scriptblock = {
        $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
            $hashsetup.Media_Path_Browse.IsEnabled = $false
            $hashsetup.MediaLocations_Grid.IsEnabled = $false
            $hashsetup.Media_Progress_Ring.isActive = $true         
        })
        if([System.IO.Directory]::Exists($Path)){
          if($PSVersionTable.PSVersion.Major -gt 5){ 
            try{ 
              $searchOptions = [System.IO.EnumerationOptions]::New()
              $searchOptions.RecurseSubdirectories = $true
              $searchOptions.IgnoreInaccessible = $true  
              $searchoptions.AttributesToSkip = "Hidden,System,ReparsePoint,Temporary" 
              if($VerboseLog){write-ezlogs "| Enumerating media file count for path $($path)" -showtime}
              $enumerate_measure = measure-command {
                $hashsetup.directory_files = ([System.IO.Directory]::EnumerateFiles($Path,'*',$searchOptions) | where {$_ -match $media_pattern})
              }
              write-ezlogs " | Enumerate measure for $path`: $($enumerate_measure | out-string)"
              $directory_filecount = @($hashsetup.directory_files).count
            }catch{
              write-ezlogs "An exception occurred attempting to get directory file count with EnumerateFiles for path $Path" -showtime -catcherror $_ 
              $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
                  if($hashsetup.EditorHelpFlyout.Document.Blocks){
                    $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                  } 
                  $hashsetup.Media_Progress_Ring.isActive = $false
                  $hashsetup.Media_Path_Browse.isEnabled = $true
                  $hashSetup.Save_Setup_Button.isEnabled = $setupbutton_status
                  $hashsetup.MediaLocations_Grid.isEnabled = $true
                  $hashsetup.Editor_Help_Flyout.isOpen = $true
                  $hashsetup.Editor_Help_Flyout.header = 'Local Media'            
                  update-EditorHelp -content "[WARNING] An exception occurred attempting to get media file count for path $Path - $_" -color orange -FontWeight Bold  -RichTextBoxControl $hashsetup.EditorHelpFlyout  
                  update-EditorHelp -content "Media in this directory may not be imported. This is usually due to permission issues. Try re-running setup as admin or verifying you have access to the path specified" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout           
              })
            }     
          }else{   
            try{ 
              $searchOptions = 'AllDirectories'
              if($VerboseLog){write-ezlogs "| GetFiles count for path $($path)" -showtime}
              $enumerate_measure = measure-command {
                #$hashsetup.directory_files = (cmd /c dir $($Path) /s /b /a-d | Where{$_ -match $media_pattern})     
                $hashsetup.directory_files = Find-FilesFast -Path $Path | where {$_ -match $media_pattern}
              }
              write-ezlogs " | cmd /c dir measure for $path`: $($enumerate_measure | out-string)"
              $directory_filecount = @($hashsetup.directory_files).count
              #$directory_filecount = @([System.IO.Directory]::GetFiles("$($Path)",'*','AllDirectories') | Where{$_ -match $media_pattern}).count
              #$directory_filecount = @([System.IO.Directory]::EnumerateFiles($Path,'*',$searchOptions) | where {$_ -match $media_pattern}).count
            }catch{
              write-ezlogs "An exception occurred attempting to get directory file count with GetFiles for path $Path" -showtime -catcherror $_ 
              $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
                  if($hashsetup.EditorHelpFlyout.Document.Blocks){
                    $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                  }       
                  $hashsetup.Media_Progress_Ring.isActive = $false
                  $hashsetup.Media_Path_Browse.isEnabled = $true
                  $hashSetup.Save_Setup_Button.isEnabled = $setupbutton_status
                  $hashsetup.MediaLocations_Grid.isEnabled = $true              
                  $hashsetup.Editor_Help_Flyout.isOpen = $true
                  $hashsetup.Editor_Help_Flyout.header = 'Local Media'            
                  update-EditorHelp -content "[WARNING] An exception occurred attempting to get media file count for path $Path`n$_" -color red -FontWeight Bold  -RichTextBoxControl $hashsetup.EditorHelpFlyout  
                  update-EditorHelp -content "Media in this directory may not be imported. This is usually due to permission issues. Try re-running setup as admin or verifying you have access to the path specified" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout                    
              })
            }    
          }                 
        }        
        $itemssource = [pscustomobject]@{
          Number=$Number;
          Path=$Path
          MediaCount=$directory_filecount
        }
        $hashsetup.window.Dispatcher.Invoke("Normal",[action]{
            $hashsetup.MediaLocations_Grid.Background = "Transparent"
            $hashsetup.MediaLocations_Grid.AlternatingRowBackground = "Transparent"
            $hashsetup.MediaLocations_Grid.CanUserReorderColumns = $false
            $hashsetup.MediaLocations_Grid.CanUserDeleteRows = $true
            $hashsetup.MediaLocations_Grid.Foreground = "White"
            $hashsetup.MediaLocations_Grid.RowBackground = "Transparent"
            $hashsetup.MediaLocations_Grid.HorizontalAlignment ="Left"
            $hashsetup.MediaLocations_Grid.CanUserAddRows = $False
            $hashsetup.MediaLocations_Grid.HorizontalContentAlignment = "left"
            $hashsetup.MediaLocations_Grid.IsReadOnly = $True

            #$hashsetup.MediaLocations_Grid.HorizontalGridLinesBrush = "DarkGray"
            $hashsetup.MediaLocations_Grid.GridLinesVisibility = "Horizontal"
            try{
              if([int]$hashsetup.MediaLocations_Grid.items.count -lt 1){
                [int]$Locations = 1
              }else{
                [int]$Locations = [int]$hashsetup.MediaLocations_Grid.items.count + 1
              }      
              $null = $hashsetup.MediaLocations_Grid.Items.add($itemssource)
              #$hashsetup.Media_Progress_Ring.isActive = $false
              $hashsetup.Media_Path_Browse.isEnabled = $true

              if($hashsetup.Update){
                $hashsetup.Save_Setup_Button.isEnabled = $true
              }else{
                $hashsetup.Save_Setup_Button.isEnabled = $setupbutton_status
              }
              $hashsetup.MediaLocations_Grid.isEnabled = $true
              $hashsetup.Media_Path_Browse.IsEnabled = $true
              $hashsetup.Media_Progress_Ring.isActive = $false 
            }catch{
              write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
              #$hashsetup.Media_Progress_Ring.isActive = $false
              $hashsetup.Media_Path_Browse.isEnabled = $true
              $hashSetup.Save_Setup_Button.isEnabled = $setupbutton_status
              $hashsetup.MediaLocations_Grid.isEnabled = $true
            }                      
        })    
      }
      $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
      Start-Runspace -scriptblock $enumerate_files_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -runspace_name "Enumerate_Files_ScriptBlock-$encodedpath" -thisApp $thisApp     
    }
    #---------------------------------------------- 
    #endregion Update-MediaLocations Function
    #----------------------------------------------

    #---------------------------------------------- 
    #region Update-YoutubePlaylists Function
    #----------------------------------------------
    function Update-YoutubePlaylists
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
      $Visible_Fields = @(
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
        'Playlist_info'
      )      
      if(!$hashsetup.YoutubePlaylists_Grid.items){ 
        $Global:YoutubePlayliststable =  [hashtable]::Synchronized(@{})
        $Global:YoutubePlayliststable.datatable = New-Object System.Data.DataTable 
        [void]$YoutubePlayliststable.datatable.Columns.AddRange($Fields)
        $Number = 1
      }else{
        $Number = $hashsetup.YoutubePlaylists_Grid.items.Number | select -last 1
        $Number++
      }
      if($VerboseLog){write-ezlogs ">>>> Updating Youtube Playlists table" -showtime -enablelogs}
      if($Locations_array)
      {
        foreach ($n in $Locations_array)
        {
          $Array = New-Object System.Collections.ArrayList
          $Null = $array.add($n.Number)
          $Null = $array.add($n.Path)
          [void]$YoutubePlayliststable.datatable.Rows.Add($array)
        } 
      }
      <#  if($Path){
          $Array = New-Object System.Collections.ArrayList
          $Null = $array.add($Number)
          $Null = $array.add($Path)
          #[void]$Notfiytable.datatable.Rows.Add($array)
      }#>
      if($thisApp.Config.Verbose_logging){write-ezlogs " | Adding Youtube - Number: $Number -- URL: $path -- Name: $Name -- Type: $Type -- ID: $ID" -showtime -enablelogs}
      $itemssource = [pscustomobject]@{
        Number=$Number;       
        ID = $id
        Name=$Name
        Path=$Path
        Type=$Type
        Playlist_Info = $Playlist_Info
      }  
      $hashsetup.YoutubePlaylists_Grid.Background = "Transparent"
      $hashsetup.YoutubePlaylists_Grid.AlternatingRowBackground = "Transparent"
      $hashsetup.YoutubePlaylists_Grid.CanUserReorderColumns = $false
      $hashsetup.YoutubePlaylists_Grid.CanUserDeleteRows = $true
      $hashsetup.YoutubePlaylists_Grid.Foreground = "White"
      $hashsetup.YoutubePlaylists_Grid.RowBackground = "Transparent"
      $hashsetup.YoutubePlaylists_Grid.HorizontalAlignment ="Left"
      $hashsetup.YoutubePlaylists_Grid.CanUserAddRows = $False
      $hashsetup.YoutubePlaylists_Grid.HorizontalContentAlignment = "left"
      $hashsetup.YoutubePlaylists_Grid.IsReadOnly = $True

      #$hashsetup.MediaLocations_Grid.HorizontalGridLinesBrush = "DarkGray"
      $hashsetup.YoutubePlaylists_Grid.GridLinesVisibility = "Horizontal"
      try{
        if([int]$hashsetup.YoutubePlaylists_Grid.items.count -lt 1){
          [int]$Locations = 1
        }else{
          [int]$Locations = [int]$hashsetup.YoutubePlaylists_Grid.items.count + 1
        }      
        $null = $hashsetup.YoutubePlaylists_Grid.Items.add($itemssource)
      }catch{
        write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
      }      

    }
    #---------------------------------------------- 
    #endregion Update-YoutubePlaylists Function
    #----------------------------------------------

    #---------------------------------------------- 
    #region Update-TwitchPlaylists Function
    #----------------------------------------------
    function Update-TwitchPlaylists
    {
      param (
        [switch]$Clear,
        $thisApp,
        [switch]$Startup,
        [switch]$Open_Flyout,
        $Locations_array,
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [string]$Level,
        [string]$Viewlink,
        [string]$Message_color,
        $hashsetup,
        [switch]$VerboseLog
      )
      $Visible_Fields = @(
        'Number'
        'Name'
        'Path'
      )
      $Fields = @(
        'Number'
        'Name'
        'Path'
        'Type'
      ) 
      if(!$hashsetup.TwitchPlaylists_Grid.items){
        $Global:TwitchPlayliststable =  [hashtable]::Synchronized(@{})
        $Global:TwitchPlayliststable.datatable = New-Object System.Data.DataTable 
        [void]$TwitchPlayliststable.datatable.Columns.AddRange($Fields)
        $Number = 1
      }else{
        $Number = $hashsetup.TwitchPlaylists_Grid.items.Number | select -last 1
        $Number++
      }
      if($VerboseLog){write-ezlogs ">>>> Updating Twitch table" -showtime -enablelogs}
      if($Locations_array)
      {
        foreach ($n in $Locations_array)
        {
          $Array = New-Object System.Collections.ArrayList
          $Null = $array.add($n.Number)
          $Null = $array.add($n.Path)
          [void]$TwitchPlayliststable.datatable.Rows.Add($array)
        } 
      }
      <#  if($Path){
          $Array = New-Object System.Collections.ArrayList
          $Null = $array.add($Number)
          $Null = $array.add($Path)
          #[void]$Notfiytable.datatable.Rows.Add($array)
      }#>
      if($VerboseLog){write-ezlogs " | Adding Numnber: $Number -- URL: $path" -showtime -enablelogs}
      $itemssource = [pscustomobject]@{
        Number=$Number;       
        Name=$Name
        Path=$Path
        Type=$Type
      }
  
      $hashsetup.TwitchPlaylists_Grid.Background = "Transparent"
      $hashsetup.TwitchPlaylists_Grid.AlternatingRowBackground = "Transparent"
      $hashsetup.TwitchPlaylists_Grid.CanUserReorderColumns = $false
      $hashsetup.TwitchPlaylists_Grid.CanUserDeleteRows = $true
      $hashsetup.TwitchPlaylists_Grid.Foreground = "White"
      $hashsetup.TwitchPlaylists_Grid.RowBackground = "Transparent"
      $hashsetup.TwitchPlaylists_Grid.HorizontalAlignment ="Left"
      $hashsetup.TwitchPlaylists_Grid.CanUserAddRows = $False
      $hashsetup.TwitchPlaylists_Grid.HorizontalContentAlignment = "left"
      $hashsetup.TwitchPlaylists_Grid.IsReadOnly = $True
      $hashsetup.TwitchPlaylists_Grid.GridLinesVisibility = "Horizontal"
      
      try{
        if([int]$hashsetup.TwitchPlaylists_Grid.items.count -lt 1){
          [int]$Locations = 1
        }else{
          [int]$Locations = [int]$hashsetup.TwitchPlaylists_Grid.items.count + 1
        }      
        $null = $hashsetup.TwitchPlaylists_Grid.Items.add($itemssource)
      }catch{
        write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
      }      
    }
    #---------------------------------------------- 
    #endregion Update-YoutubePlaylists Function
    #----------------------------------------------
    
    function update-EditorHelp{    
      param (
        $content,
        [string]$color = "White",
        [string]$FontWeight = "Normal",
        [string]$FontSize = 14,
        [string]$BackGroundColor = "Transparent",
        [string]$TextDecorations,
        [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
        [switch]$AppendContent,
        [switch]$MultiSelect,
        [switch]$List,
        [System.Windows.Controls.RichTextBox]$RichTextBoxControl
      ) 
      if($hashsetup.Editor_Help_Flyout.Document.Blocks){
        $hashsetup.Editor_Help_Flyout.Document.Blocks.Clear() 
      }
      $hashsetup.EditorHelpFlyout.MaxHeight= $hashsetup.Window.Height - 50 
      $url_pattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
      [System.Windows.RoutedEventHandler]$Hyperlink_RequestNavigate = {
        param ($sender,$e)
        $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
        if($sender.NavigateUri -match $url_fullpattern){
          $path = $sender.NavigateUri
        }else{
          $path = (resolve-path $($sender.NavigateUri -replace 'file:///','')).Path
        }     
        write-ezlogs "Navigation to $($path)" -showtime
        if($path){
          start $($path)
        }
      }  
      $Paragraph = New-Object System.Windows.Documents.Paragraph
      $RichTextRange = New-Object System.Windows.Documents.Run            
      $RichTextRange.Foreground = $color
      $RichTextRange.FontWeight = $FontWeight
      $RichTextRange.FontSize = $FontSize
      $RichTextRange.Background = $BackGroundColor
      $RichTextRange.TextDecorations = $TextDecorations
      if($List){ 
        $listrange = New-Object System.Windows.Documents.List
        $listrange.MarkerStyle="Disc" 
        $listrange.MarkerOffset="2"
        #$listrange.padding = "10,0,0,0" 
        $listrange.Background = $BackGroundColor
        $listrange.Foreground = $color
        $listrange.Margin = 0
        $listrange.FontWeight = $FontWeight
        $listrange.FontSize = $FontSize
        $content | foreach{     
          $RichTextRange = New-Object System.Windows.Documents.Run            
          $RichTextRange.Foreground = $color
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.Background = $BackGroundColor
          $RichTextRange.TextDecorations = $TextDecorations     
          $listitem = New-Object System.Windows.Documents.ListItem   
          $RichTextRange.AddText(($_).toupper())
          $Paragraph = New-Object System.Windows.Documents.Paragraph
          $paragraph.Margin = 0
          $Paragraph.Inlines.add($RichTextRange)
          $null = $listitem.AddChild($Paragraph)
          $null = $listrange.AddChild($listitem)         
        }    
        $null = $RichTextBoxControl.Document.Blocks.Add($listrange)
      }elseif($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{
        if($content -match $url_pattern){
          $hyperlink = $([regex]::matches($content, $url_pattern) | %{$_.groups[0].value})
          $uri = new-object system.uri($hyperlink)
          $link_hyperlink = New-object System.Windows.Documents.Hyperlink
          $link_hyperlink.NavigateUri = $uri
          $link_hyperlink.ToolTip = "$hyperlink"
          $link_hyperlink.Foreground = "LightGreen"
          #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
          $Null = $link_hyperlink.Inlines.add("$($uri.Scheme)://$($uri.DnsSafeHost)")
          $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)
          $RichTextRange1 = New-Object System.Windows.Documents.Run            
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
        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }
    }
    try{
      [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
      Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
      $add_Window_XML = "$($Current_Folder)\\Views\\FirstRun.xaml"
      if(!([System.IO.file]::Exists($add_Window_XML))){
        $Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
        $add_Window_XML = "$($Current_Folder)\\Views\\FirstRun.xaml"
      }
  
      try{
        if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
          $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
          $themes = $theme.GetLibraryThemes()
          $themeManager = [ControlzEx.Theming.ThemeManager]::new()
          if($synchash.Window.isLoaded){
            $detectTheme = $thememanager.DetectTheme($synchash.Window)
            if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Current Theme: $($detectTheme | out-string)" -showtime}
            $newtheme = $themes | where {$_.Name -eq $detectTheme.Name}
          }else{
            $newtheme = $themes | where {$_.Name -eq $thisApp.Config.Current_Theme.Name}
          } 
        }
      }catch{
        write-ezlogs "An exception occurred changing theme for Get-loadScreen" -showtime -catcherror $_
      }       
      [xml]$xaml = [System.IO.File]::ReadAllText($add_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$($newTheme.PrimaryAccentColor)")
      #[xml]$xaml = Get-content "$($Current_Folder)\\Views\\FirstRun.xaml" -Force
      if($Verboselog){write-ezlogs ">>>> Script path: $($Current_Folder)\\Views\\FirstRun.xaml" -showtime -enablelogs -Color cyan}
      $reader=(New-Object System.Xml.XmlNodeReader $xaml)   
      $hashsetup.Window=[Windows.Markup.XamlReader]::Load($reader)
      [xml]$XAML = $xaml
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {   
        $hashsetup."$($_.Name)" =  $hashsetup.Window.FindName($_.Name)  
      }  
    }
    catch
    {
      write-ezlogs "An exception occurred when loading xaml" -CatchError $_
      
    } 
         
    $hashsetup.Logo.Source=$Logo
    $hashsetup.Window.title =$PageTitle
    <#  $imagecontrol = New-Object MahApps.Metro.IconPacks.PackIconBootstrapIcons
        $imagecontrol.width = "16"
        $imagecontrol.Height = "16"
        $imagecontrol.Kind = "MusicPlayerFill"
    $imagecontrol.Foreground = 'White'#> 
    #$hashsetup.Window.icon = $Logo
    #$hashsetup.Title_menu_Image.Source = $Logo
    $hashsetup.Title_menu_Image.width = "18"  
    $hashsetup.Title_menu_Image.Height = "18" 
    $hashsetup.window.TaskbarItemInfo.Description = "SETUP - $($thisScript.Name) - Version: $($thisScript.Version)"
    $hashsetup.PageHeader.content = $PageHeader 
    #$hashsetup.Window.icon.Freeze()  
    $hashsetup.Window.icon = $hashsetup.Title_menu_Image.Source
    $hashsetup.Window.IsWindowDraggable="True" 
    $hashsetup.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
    $hashsetup.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
    $hashsetup.Window.ShowTitleBar=$true
    $hashsetup.Window.UseNoneWindowStyle = $false
    $hashsetup.Window.WindowStyle = 'none'   
    if($newtheme){    
      try{
        $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
        $thememanager.ChangeTheme($hashsetup.Window,$newtheme.Name,$false)      
        if($synchash.GameDetails_Flyout.Background){ 
          $hashsetup.Window.Background = $synchash.GameDetails_Flyout.Background
        }else{
          $gradientbrush = New-object System.Windows.Media.LinearGradientBrush
          $gradientbrush.StartPoint = "0.5,0"
          $gradientbrush.EndPoint = "0.5,1"
          $gradientstop1 = New-object System.Windows.Media.GradientStop
          $gradientstop1.Color = $thisApp.Config.Current_Theme.GridGradientColor1
          $gradientstop1.Offset= "0.0"
          $gradientstop2 = New-object System.Windows.Media.GradientStop
          $gradientstop2.Color = $thisApp.Config.Current_Theme.GridGradientColor2
          $gradientstop2.Offset= "0.7"  
          $gradientstop_Collection = New-object System.Windows.Media.GradientStopCollection
          $null = $gradientstop_Collection.Add($gradientstop1)
          $null = $gradientstop_Collection.Add($gradientstop2)
          $gradientbrush.GradientStops = $gradientstop_Collection  
          $hashsetup.Window.Background = $gradientbrush    
          #$helpbackground = "$($thisApp.Config.Current_Theme.GridGradientColor2)" -replace $("$($thisApp.Config.Current_Theme.GridGradientColor2)").Substring(0,3),'#c9' 
          $flyoutgradientbrush = $gradientbrush.clone()
          $flyoutgradientbrush.GradientStops[1].color = "$($flyoutgradientbrush.GradientStops[1].color)" -replace $("$($flyoutgradientbrush.GradientStops[1].color)").Substring(0,3),'#E9' 
          $flyoutgradientbrush.GradientStops[1].Offset = "0.7"
          $hashsetup.Editor_Help_Flyout.Background = $flyoutgradientbrush

          #$hashsetup.EditorHelpFlyout.BorderBrush = '#FF444444'
          #$hashsetup.EditorHelpFlyout.BorderThickness="1,1,1,1"
        }
      }
      catch{
        write-ezlogs "An exception occurred setting theme to $($newtheme | out-string)" -CatchError $_
      } 
    }  
    if($Update){
      $hashsetup.Cancel_Button_Text.text = "Cancel"
      $hashsetup.Setup_Button_Textblock.text = "Apply"   
    }
    #Allow dragging window from anywhere
    $hashsetup.Window.add_MouseDown({
        $sender = $args[0]
        [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and [System.Windows.Input.MouseButtonState]::Pressed)
        {
          try{
            $hashsetup.Window.DragMove()
          }catch{
            write-ezlogs "An exception occurred in hashsetup Window MouseDown event" -showtime -catcherror $_
          }
        }
    })  
  
    #Update-EditorHelp  
    function Show-Console
    {
      $consolePtr = [Console.Window]::GetConsoleWindow()

      # Hide = 0,
      # ShowNormal = 1,
      # ShowMinimized = 2,
      # ShowMaximized = 3,
      # Maximize = 3,
      # ShowNormalNoActivate = 4,
      # Show = 5,
      # Minimize = 6,
      # ShowMinNoActivate = 7,
      # ShowNoActivate = 8,
      # Restore = 9,
      # ShowDefault = 10,
      # ForceMinimized = 11

      [Console.Window]::ShowWindow($consolePtr, 4)
    }
    function Hide-Console
    {
      $consolePtr = [Console.Window]::GetConsoleWindow()
      #0 hide
      [Console.Window]::ShowWindow($consolePtr, 0)
    }  

    #---------------------------------------------- 
    #region Remove Media Location Button
    #----------------------------------------------
    [System.Windows.RoutedEventHandler]$RemoveclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.MediaLocations_Grid.Items.Remove($hashsetup.MediaLocations_Grid.SelectedItem)
      }catch{
        write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
      }
    }  
    [System.Windows.RoutedEventHandler]$RemoveAllclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.MediaLocations_Grid.items.clear()
      }catch{
        write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
      }
    } 
    [System.Windows.RoutedEventHandler]$RemovePlaylistclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.YoutubePlaylists_Grid.Items.Remove($hashsetup.YoutubePlaylists_Grid.SelectedItem)
      }catch{
        write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
      }
    }  
    [System.Windows.RoutedEventHandler]$RemoveAllPlaylistclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.YoutubePlaylists_Grid.items.clear()
      }catch{
        write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
      }
    } 
    [System.Windows.RoutedEventHandler]$RemoveTwitchPlaylistclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.YoutubePlaylists_Grid.Items.Remove($hashsetup.YoutubePlaylists_Grid.SelectedItem)
      }catch{
        write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
      }
    }  
    [System.Windows.RoutedEventHandler]$RemoveTwitchAllPlaylistclickEvent = {
      param ($sender,$e)
      try{
        $null = $hashsetup.YoutubePlaylists_Grid.items.clear()
      }catch{
        write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
      }
    }      
    if($hashsetup.MediaLocations_Grid.Columns.count -lt 5){
      $buttontag = @{        
        hashsetup=$hashsetup;
        thisScript=$thisScript;
        thisApp=$thisApp
      }  
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismiss_button")
      $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveclickEvent)
      $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismissAll_button")
      $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllclickEvent)
      $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $headerdataTemplate = New-Object System.Windows.DataTemplate
      $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.HeaderTemplate = $headerdataTemplate 
      $buttonColumn.DisplayIndex = 0  
      $null = $hashsetup.MediaLocations_Grid.Columns.add($buttonColumn)
    }
    if($hashsetup.YoutubePlaylists_Grid.Columns.count -lt 5){
      $buttontag = @{        
        hashsetup=$hashsetup;
        thisScript=$thisScript;
        thisApp=$thisApp
      }  
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismiss_button")
      $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemovePlaylistclickEvent)
      $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismissAll_button")
      $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllPlaylistclickEvent)
      $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $headerdataTemplate = New-Object System.Windows.DataTemplate
      $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.HeaderTemplate = $headerdataTemplate 
      $buttonColumn.DisplayIndex = 0  
      $null = $hashsetup.YoutubePlaylists_Grid.Columns.add($buttonColumn)
    } 
    if($hashsetup.TwitchPlaylists_Grid.Columns.count -lt 5){
      $buttontag = @{        
        hashsetup=$hashsetup;
        thisScript=$thisScript;
        thisApp=$thisApp
      }  
      $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("GridButtonStyle"))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismiss_button")
      $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchPlaylistclickEvent)
      $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $buttonFactory
      $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("DetailButtonStyle"))
      $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismissAll_button")
      $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveTwitchAllPlaylistclickEvent)
      $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
      $headerdataTemplate = New-Object System.Windows.DataTemplate
      $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
      $buttonColumn.CellTemplate = $dataTemplate
      $buttonColumn.HeaderTemplate = $headerdataTemplate 
      $buttonColumn.DisplayIndex = 0  
      $null = $hashsetup.TwitchPlaylists_Grid.Columns.add($buttonColumn)
    }     
    #---------------------------------------------- 
    #region Remove Media Location Button
    #----------------------------------------------
    if(@($thisApp.Config.Media_Directories).count -gt 0){
      $hashsetup.Media_Progress_Ring.isActive = $true
      $hashsetup.Media_Path_Browse.IsEnabled = $false
      $hashsetup.MediaLocations_Grid.IsEnabled = $false
      foreach($directory in $thisApp.Config.Media_Directories){
        Update-MediaLocations -hashsetup $hashsetup -Path $directory -VerboseLog -thisapp $thisApp
      }
      if($Update){
        $hashsetup.Save_Setup_Button.isEnabled = $true
      }
      $hashsetup.Media_Progress_Ring.isActive = $false
      $hashsetup.Media_Path_Browse.IsEnabled = $true
      $hashsetup.MediaLocations_Grid.IsEnabled = $true
    }
    if($Update){
      $hashsetup.Save_Setup_Button.isEnabled = $true
    }else{
      $hashsetup.Save_Setup_Button.isEnabled = $false
    }
    if($thisApp.Config.Import_Local_Media){
      $hashsetup.Import_Local_Media_Toggle.isOn = $true
      $hashsetup.Media_Path_Browse.IsEnabled = $true
      $hashsetup.MediaLocations_Grid.IsEnabled = $true
    }
    if($thisApp.Config.Import_Spotify_Media){
      $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
      if(!$Spotify_Auth_app.token.access_token -and !$First_Run){
        write-ezlogs "Unable to get Spotify authentication, starting spotify authentication setup process" -showtime -warning  
        $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
        write-ezlogs "Importing API XML $APIXML" -showtime
        if([System.IO.File]::Exists($APIXML)){
          $Spotify_API = Import-Clixml $APIXML
          $client_ID = $Spotify_API.ClientID
          $client_secret = $Spotify_API.ClientSecret
        }
        if($Spotify_API -and $client_ID -and $client_secret){
          write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime
          #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($client_secret_raw))
          #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientID_raw))
          New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
          $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name                
          if($Spotify_Auth_app.token.access_token){
            try{
              $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
            }catch{
              write-ezlogs "An exception occurred" -CatchError $_ -enablelogs
            }                
            if($playlists){
              Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
              $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
              $hashsetup.Install_Spotify_Toggle.isEnabled = $true
              write-ezlogs "[SUCCESS] Authenticated to Spotify and retrieved Playlists" -showtime -color green                           
            }else{
              write-ezlogs "Unable to successfully authenticate to spotify!" -showtime -warning
              Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
              $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
              $hashsetup.Install_Spotify_Toggle.isEnabled = $false
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              }        
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
              update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                
            }
            #$devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
            #Show-WebLogin -SplashTitle "Spotify Account Login" -SplashMessage "Splash Message" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL 'https://accounts.spotify.com/authorize' -thisScript $thisScript
          }else{
            write-ezlogs "Unable to authenticate with Spotify API -- Spotify_Auth_app was null -- cannot continue" -showtime -warning      
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
            update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API. Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout      
          }
        }else{
          write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning      
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
          update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API. Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout     
        }
      }elseif($First_Run){
        $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
        $hashsetup.Install_Spotify_Toggle.isOn = $false
        $hashsetup.Install_Spotify_Toggle.isEnabled = $false
      }else{
        $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
        $hashsetup.Install_Spotify_Toggle.isEnabled = $true
      }  
    }
    #Youtube
    [System.Windows.RoutedEventHandler]$Youtube_AuthHandler = {
      param ($sender,$e)
      if($sender.NavigateUri -match 'Youtube_Auth'){
        try{
          if([System.IO.Directory]::Exists("$($thisScript.TempFolder)\Spotify_Webview2")){   
            try{
              write-ezlogs ">>>> Removing existing Webview2 cache $($thisScript.TempFolder)\Spotify_Webview2" -showtime -color cyan
              $null = Remove-Item "$($thisScript.TempFolder)\Spotify_Webview2" -Force -Recurse
            }catch{
              write-ezlogs "An exception occurred attempting to remove $($thisScript.TempFolder)\Spotify_Webview2" -showtime -catcherror $_
            }
          }
          try{
            $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
          }
          write-ezlogs "Removing stored Youtube authentication secrets from vault" -showtime -warning
          if($secretstore){
            $secretstore = $secretstore.name  
            try{
              $null = Remove-secret -name YoutubeAccessToken -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret YoutubeAccessToken" -showtime -catcherror $_
            }
            try{
              $null = Remove-secret -name Youtubeexpires_in -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret Youtubeexpires_in" -showtime -catcherror $_
            }   
            try{
              $null = Remove-secret -name Youtuberefresh_token -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret Youtuberefresh_token" -showtime -catcherror $_
            }                    
          }
          try{
            Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript 
            write-ezlogs ">>> Verifying Youtube authentication" -showtime
            $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          } 
          if($access_token -and $refresh_access_token){
            #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
            write-ezlogs "[SUCCESS] Authenticated to Youtube and retrieved access tokens" -showtime -color green 
            $hashsetup.Youtube_Playlists_Import.isEnabled = $true

            $hashsetup.Import_Youtube_transitioningControl.Height = 0
            $hashsetup.Import_Youtube_transitioningControl.content = ''
            $hashsetup.Import_Youtube_textbox.text = ''
            if($MahDialog_hash.window.Dispatcher -and $MahDialog_hash.window.isVisible){
              $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
            }  
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
            update-EditorHelp -content "[SUCCESS] Authenticated to Youtube and saved access tokens into the Secret Vault! You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                           
          }else{
            write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to Youtube!" -showtime -warning
            $hashsetup.Youtube_Playlists_Import.isEnabled = $false
            #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
            $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $false
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
            update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Youtube! Some Youtube features may be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout               
          }          
        }catch{
          write-ezlogs "An exception occurred in Youtube_AuthHandler routed event" -showtime -catcherror $_
        }         
      }     
    }  
    [System.Windows.RoutedEventHandler]$Youtube_ImportHandler = {
      param ($sender,$e)
      try{
        try{
          $youtube_playlists = Get-YouTubePlaylists -mine
        }catch{
          write-ezlogs "An exception occurred retrieving youtube playlists with Get-YoutubePlaylists" -showtime -catcherror $_
        } 
        $newplaylists = 0
        if($youtube_playlists){        
          foreach($playlist in $youtube_playlists){              
            $playlisturl = "https://www.youtube.com/playlist?list=$($playlist.id)"
            $playlistName = $playlist.snippet.title
            if($hashsetup.YoutubePlaylists_Grid.items.path -notcontains $playlisturl){
              if($thisApp.Config.Verbose_logging){write-ezlogs "Adding Youtube Playlist URL $playlisturl" -showtime}
              Update-YoutubePlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'YoutubePlaylist' -Playlist_Info $playlist -VerboseLog:$thisApp.Config.Verbose_logging
              $newplaylists++
            }else{
              write-ezlogs "The Youtube Playlist URL $playlisturl has already been added!" -showtime -warning
            }
          }
        }
        try{
          if($thisApp.Config.Import_My_Youtube_Media){
            $channel = Get-YouTubeChannel -mine -Raw
            if($channel.items.contentdetails.relatedPlaylists.uploads){
              $playlistid = $($channel.items.contentdetails.relatedPlaylists.uploads)
              #$channelurl = "https://www.youtube.com/channel/$($channel.items.id)/videos"
              $playlisturl = "https://www.youtube.com/playlist?list=$($playlistid)"
              $channelName = $channel.items.snippet.title
              if($hashsetup.YoutubePlaylists_Grid.items.path -notcontains $playlisturl){
                write-ezlogs "Adding Youtube Channel URL $playlisturl" -showtime
                Update-YoutubePlaylists -hashsetup $hashsetup -Path $playlisturl -Name $channelName -id $playlistid -type 'YoutubePlaylist' -Playlist_Info $channel.items -VerboseLog:$thisApp.Config.Verbose_logging
                $newplaylists++
              }else{
                write-ezlogs "The Youtube Channel URL $channelurl has already been added!" -showtime -warning
              }           
            }
          }
        }catch{
          write-ezlogs "An exception occurred retrieving owner youtube channel id" -showtime -catcherror $_
        }
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }        
        if($newplaylists -le 0){
          write-ezlogs "No new Youtuube Playlists were found!" -showtime -warning
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Youtube'
          update-EditorHelp -content "No new Youtuube Playlists were found!" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
        }else{
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Youtube'
          write-ezlogs ">>>> Found $newplaylists new Youtuube Playlists!" -showtime
          update-EditorHelp -content "Found $newplaylists new Youtuube Playlists!" -color cyan -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
        }               
      }catch{
        write-ezlogs "An exception occurred in Youtube_ImportHandler routed event" -showtime -catcherror $_
      }             
    } 
    $Null = $hashsetup.Youtube_Playlists_Import.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Youtube_ImportHandler) 
         
    if($thisApp.Config.Import_Youtube_Media){
      $CustomPlaylist_pattern = [regex]::new('$(?<=((?i)CustomPlaylist.xml))')
      try{
        $existing_CustomPlaylist = [System.IO.Directory]::EnumerateFiles($thisApp.config.Playlist_Profile_Directory,'*','AllDirectories') | where {$_ -match $CustomPlaylist_pattern} 
        if($existing_CustomPlaylist){
          foreach($customplaylist in $existing_CustomPlaylist){
            $playlist = Import-Clixml $customplaylist
            $playlist_urls = $playlist.PlayList_tracks.Playlist_URL | where {$_ -match 'Twitch.tv' -or $_ -match 'youtube.com'}
            foreach($url in $playlist_urls){
              if($thisApp.Config.Youtube_Playlists -notcontains $url){
                write-ezlogs "| Found custom playlist to add to media library: $url" -showtime
                $null = $thisApp.Config.Youtube_Playlists.add($url)
              }
            }
          }
        }
      }catch{
        write-ezlogs "An exception occurred parsing custom playlists in $($thisApp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
      }
      if(@($thisApp.Config.Youtube_Playlists).count -gt 0){
        foreach($playlist in $thisApp.Config.Youtube_Playlists){
          if($playlist -match "v="){
            $id = ($($playlist) -split('v='))[1].trim()  
            $type = 'YoutubeVideo' 
            $Name = "Custom_$id"        
          }elseif($playlist -match 'list='){
            $id = ($($playlist) -split('list='))[1].trim() 
            $Name = "Custom_$id"   
            $type = 'YoutubePlaylist'                      
          }elseif($playlist -match 'twitch.tv'){
            $id = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower())) 
            $Name = $id
            $type = 'TwitchChannel'
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
          Update-YoutubePlaylists -hashsetup $hashsetup -Path $playlist -id $id -type $type -Name $Name -playlist_info $playlist_info -VerboseLog:$thisApp.Config.Verbose_logging
        }

      }
      $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      if($refresh_access_token){
        $access_token_expires = Get-secret -name Youtubeexpires_in -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      }
      if(!$access_token_expires -or !$access_token){
        $hyperlink = 'https://Youtube_Auth'
        write-ezlogs "Unable to find Youtube authentication - $($access_token_expires)" -showtime -warning
        #$uri = new-object system.uri($hyperlink)
        $hashsetup.Import_Youtube_textbox.isEnabled = $true
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
        $link_hyperlink.Foreground = "LightBlue"
        #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
        $Null = $link_hyperlink.Inlines.add("HERE")
        $hashsetup.Import_Youtube_textbox.text = "[INFO] Using some Youtube features requires providing your Youtube account credentials. You will be prompted upon Starting/Saving setup"
        $hashsetup.Import_Youtube_textbox.Inlines.add("`n`nOptionally: Click ")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Youtube_AuthHandler)
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add(" to provide them now")   
        $hashsetup.Import_Youtube_textbox.Foreground = "Cyan"
        $hashsetup.Import_Youtube_textbox.FontSize = 14
        $hashsetup.Import_Youtube_transitioningControl.Height = 80
        $hashsetup.Import_Youtube_transitioningControl.content = $hashsetup.Import_Youtube_textbox
        $hashsetup.Youtube_Playlists_Import.isEnabled = $false
      }elseif($access_token_expires -le (Get-date)){
        $hyperlink = 'https://Youtube_Auth'
        write-ezlogs "Found existing Youtube authentication, but they are expired and need to be refreshed: $($access_token_expires)" -showtime -warning
        $hashsetup.Import_Youtube_textbox.isEnabled = $true
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
        $link_hyperlink.Foreground = "LightBlue"
        #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
        $Null = $link_hyperlink.Inlines.add("HERE")
        $hashsetup.Import_Youtube_textbox.text = "[WARNING] Found existing Youtube authentication, but they are expired and need to be refreshed. You will be prompted after Starting/Saving setup"
        $hashsetup.Import_Youtube_textbox.Inlines.add("`n`nOptionally: Click ")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Youtube_AuthHandler)
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add(" to provide them now")   
        $hashsetup.Import_Youtube_textbox.Foreground = "Orange"
        $hashsetup.Import_Youtube_textbox.FontSize = 14
        $hashsetup.Import_Youtube_transitioningControl.Height = 80
        $hashsetup.Import_Youtube_transitioningControl.content = $hashsetup.Import_Youtube_textbox
        $hashsetup.Youtube_Playlists_Import.isEnabled = $false    
      }else{
        write-ezlogs "[SUCCESS] Returned Youtube authentication $($access_token_expires)" -showtime
        $hashsetup.Import_Youtube_textbox.text = "[SUCCESS] Retrieved previously provided Youtube authentication from Secure Vault"
        $hashsetup.Import_Youtube_textbox.isEnabled = $true
        $hyperlink = 'https://Youtube_Auth'
        #$uri = new-object system.uri($hyperlink)
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
        $link_hyperlink.Foreground = "LightBlue"
        $Null = $link_hyperlink.Inlines.add("HERE")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Youtube_AuthHandler)
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add("`nIf you wish to update/change your Youtube credentials, click ")  
        $null = $hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
        $hashsetup.Import_Youtube_textbox.Foreground = "LightGreen"
        $hashsetup.Import_Youtube_textbox.FontSize = 14
        $hashsetup.Import_Youtube_transitioningControl.Height = 80
        $hashsetup.Import_Youtube_transitioningControl.content = $hashsetup.Import_Youtube_textbox
        $hashsetup.Youtube_Playlists_Import.isEnabled = $true
      }          
      $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $true
      $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true
      $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
      $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true
      $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 250    
    }else{
      $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 0
      $hashsetup.Import_Youtube_textbox.text = ""
      $hashsetup.Import_Youtube_transitioningControl.Height = 0
      $hashsetup.Import_Youtube_transitioningControl.content = ''
      $hashsetup.Youtube_Playlists_Import.isEnabled = $false
    }  
    
    
    
    
    #---------------------------------------------- 
    #region Get Local Media
    #---------------------------------------------- 
    $hashsetup.Import_Local_Media_Toggle.add_Toggled({
        if($hashsetup.Import_Local_Media_Toggle.isOn)
        {
          $hashsetup.Media_Path_Browse.IsEnabled = $true
          $hashsetup.MediaLocations_Grid.IsEnabled = $true
          Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $true -MemberType NoteProperty -Force
        }
        else
        {
          $hashsetup.MediaLocations_Grid.IsEnabled = $false
          $hashsetup.Media_Path_Browse.IsEnabled = $false
          Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $false -MemberType NoteProperty -Force
        }
    })
    $audio_formats = @(
      'Mp3'
      'wav'
      'flac'
      '3gp'
      'aac'
    )
    $video_formats = @(
      'mp4'
      'avi'
      'mkv'    
      'h264'
      'webm'
      'h265'
      'mov'
      'wmv'
      'h264'
      'mpeg'
      'mpg4'
      'movie'
      'mpgx'
      'vob'
      '3gp'
      'm2ts'

    )
    $hashsetup.Import_Local_Media_Button.add_click({
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }  
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Local_Media_Toggle.content
        update-EditorHelp -content "Enabling this will attempt to import all media from each local directory you specify" -RichTextBoxControl $hashsetup.EditorHelpFlyout
        update-EditorHelp -content "The following formats are currently supported" -color Cyan -RichTextBoxControl $hashsetup.EditorHelpFlyout
        update-EditorHelp -content "Audio Formats" -FontWeight bold -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
        update-EditorHelp -content $audio_formats -List -RichTextBoxControl $hashsetup.EditorHelpFlyout
        update-EditorHelp -content "Video Formats" -FontWeight bold -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
        update-EditorHelp -content $video_formats -List -RichTextBoxControl $hashsetup.EditorHelpFlyout      
        #update-EditorHelp -content "IMPORTANT: This setting will likely increase the import/scanning time of the first run setup significantly, depending on how many steam games you own" -FontWeight bold -color orange
        #update-EditorHelp -content "IMPORTANT: In order for this option to work, your Steam account profile must be set to public" -FontWeight bold -color orange
    }) 
       
    $hashsetup.Media_Path_Browse.add_click({
        if(($hashsetup.MediaLocations_Grid.items.path | select -last 1)){
          $initialdirectory = ($hashsetup.MediaLocations_Grid.items.path | select -last 1)
        }else{
          $initialdirectory = "file:"
        } 
        $savebutton_history = $hashsetup.Save_Setup_Button.isEnabled     
        $hashsetup.Media_Path_Browse.IsEnabled = $false
        $hashsetup.Media_Progress_Ring.isActive = $true
        $hashsetup.MediaLocations_Grid.IsEnabled = $false
        [array]$file_browse_Path = Open-FolderDialog -Title "Select the folder from which media will be imported" -InitialDirectory $initialdirectory -MultiSelect
        #$file_browse_Path = $file_browse_Path -join ","
        if(-not [string]::IsNullOrEmpty($file_browse_Path)){
          $hashsetup.Save_Setup_Button.isEnabled = $false
          $hashsetup.Media_Path_Browse.IsEnabled = $false
          foreach($path in $file_browse_Path){
            if($hashsetup.MediaLocations_Grid.items.path -notcontains $file_browse_Path){
              #write-ezlogs "Adding selected folder/path $path" -showtime
              Update-MediaLocations -hashsetup $hashsetup -Path $path -VerboseLog -thisapp $thisApp
            }else{
              write-ezlogs "The location $file_browse_Path has already been added!" -showtime -warning
            }                  
          }
        }

        if($hashsetup.Update){
          $hashsetup.Save_Setup_Button.isEnabled = $true
        }else{
          $hashsetup.Save_Setup_Button.isEnabled = $savebutton_history
        }
    })     
    #---------------------------------------------- 
    #endregion Get Local Media
    #----------------------------------------------
 
    [System.Windows.RoutedEventHandler]$Spotify_AuthHandler = {
      param ($sender,$e)
      if($sender.NavigateUri -match 'Spotify_Auth'){
        try{
          if([System.IO.Directory]::Exists("$($thisScript.TempFolder)\Spotify_Webview2")){   
            try{
              write-ezlogs ">>>> Removing existing Webview2 cache $($thisScript.TempFolder)\Spotify_Webview2" -showtime -color cyan
              $null = Remove-Item "$($thisScript.TempFolder)\Spotify_Webview2" -Force -Recurse
            }catch{
              write-ezlogs "An exception occurred attempting to remove $($thisScript.TempFolder)\Spotify_Webview2" -showtime -catcherror $_
            }
          }
          $Spotify_Auth_app = $null
          try{
            $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
          }
          write-ezlogs "Removing stored Spotify authentication secrets from vault" -showtime -warning
          if($secretstore){
            $secretstore = $secretstore.name  
            try{
              $null = Remove-secret -name SpotyRedirectUri -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret SpotyRedirectUri" -showtime -catcherror $_
            }
            try{
              $null = Remove-secret -name SpotyClientId -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret SpotyClientId" -showtime -catcherror $_
            }   
            try{
              $null = Remove-secret -name SpotyClientSecret -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret SpotyClientSecret" -showtime -catcherror $_
            }    
            try{
              $null = Remove-secret -name Spotyaccess_token -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret Spotyaccess_token" -showtime -catcherror $_
            }                 
          }
          $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name      
          if(!$Spotify_Auth_app.token.access_token){
            write-ezlogs "Starting spotify authentication setup process" -showtime -warning  
            $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
            write-ezlogs "Importing API XML $APIXML" -showtime
            if([System.IO.File]::Exists($APIXML)){
              $Spotify_API = Import-Clixml $APIXML
              $client_ID = $Spotify_API.ClientID
              $client_secret = $Spotify_API.ClientSecret            
            }
            if($Spotify_API -and $client_ID -and $client_secret){
              write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime
              #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientSecret | ConvertTo-SecureString))))
              #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientID | ConvertTo-SecureString))))            
              New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
              $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
              if($Spotify_Auth_app){
                try{
                  $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript -First_Run:$First_Run        
                }catch{
                  write-ezlogs "[Show-FirstRun] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_ -enablelogs
                }                             
                if($playlists){
                  Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                  write-ezlogs "[SUCCESS] Authenticated to Spotify and retrieved Playlists" -showtime -color green 
                  $hashsetup.Import_Spotify_transitioningControl.Height = 0
                  $hashsetup.Import_Spotify_transitioningControl.content = ''
                  $hashsetup.Import_Spotify_textbox.text = ''
                  if($MahDialog_hash.window.Dispatcher){
                    $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                  }  
                  if($hashsetup.EditorHelpFlyout.Document.Blocks){
                    $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                  }        
                  $hashsetup.Editor_Help_Flyout.isOpen = $true
                  $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                  update-EditorHelp -content "[SUCCESS] Authenticated to Spotify and retrieved Playlists! In order for Spotify playback to work properly, please ensure that you are logged in to the Spotify app with your account. You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                           
                }else{
                  write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to spotify!" -showtime -warning
                  Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                  $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                  if($hashsetup.EditorHelpFlyout.Document.Blocks){
                    $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                  }        
                  $hashsetup.Editor_Help_Flyout.isOpen = $true
                  $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                  update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! (No playlists returned!) Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
                  Remove-SpotifyApplication -Name $thisApp.config.App_Name               
                }
                if(!$hashsetup.Window.isVisible){
                  $hashsetup.Window.Showdialog()
                }              
                #$devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
                #Show-WebLogin -SplashTitle "Spotify Account Login" -SplashMessage "Splash Message" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL 'https://accounts.spotify.com/authorize' -thisScript $thisScript
              }else{
                write-ezlogs "No Spotify app returned from Get-SpotifyApplication! Cannot continue" -showtime -warning
              }
            }else{
              write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning      
              if($hashsetup.EditorHelpFlyout.Document.Blocks){
                $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
              }        
              $hashsetup.Editor_Help_Flyout.isOpen = $true
              $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
              update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API (Couldn't find API creds!). Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout   
              Remove-SpotifyApplication -Name $thisApp.config.App_Name   
              return
            }
          } 
        }catch{
          write-ezlogs "An exception occurred in Spotify_AuthHandler routed event" -showtime -catcherror $_
        }         
      }     
    }
      
    #---------------------------------------------- 
    #region Get Spotify Media
    #----------------------------------------------
    $hashsetup.Import_Spotify_Playlists_Toggle.add_Toggled({
        try{
          $hashsetup.Import_Spotify_transitioningControl.content = ''
          $hashsetup.Import_Spotify_textbox.text = ''
          if($hashsetup.Import_Spotify_Playlists_Toggle.isOn)
          {     
            $hashsetup.Install_Spotify_Toggle.isEnabled = $true
            $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
            if(!$Spotify_Auth_app.token.access_token){
              $hyperlink = 'https://Spotify_Auth'
              #$uri = new-object system.uri($hyperlink)
              $hashsetup.Import_Spotify_textbox.isEnabled = $true
              $link_hyperlink = New-object System.Windows.Documents.Hyperlink
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
              $Null = $link_hyperlink.Inlines.add("HERE")
              $hashsetup.Import_Spotify_textbox.text = "[INFO] Using Spotify features requires providing your Spotify account credentials. You will be prompted upon Starting/Saving setup"
              $hashsetup.Import_Spotify_textbox.Inlines.add("`n`nOptionally: Click ")
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Spotify_AuthHandler)
              $null = $hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
              $null = $hashsetup.Import_Spotify_textbox.Inlines.add(" to provide them now")   
              $hashsetup.Import_Spotify_textbox.Foreground = "Cyan"
              $hashsetup.Import_Spotify_textbox.FontSize = 14
              $hashsetup.Import_Spotify_transitioningControl.Height = 80
              $hashsetup.Import_Spotify_transitioningControl.content = $hashsetup.Import_Spotify_textbox
            }else{
              if($thisApp.Config.Verbose_logging){write-ezlogs "[SUCCESS] Returned Spotify application $($Spotify_Auth_app | out-string)" -showtime}
              $hashsetup.Import_Spotify_textbox.text = "[SUCCESS] Retrieved previously provided Spotify authentication from Secure Vault"
              $hashsetup.Import_Spotify_textbox.isEnabled = $true
              $hyperlink = 'https://Spotify_Auth'
              #$uri = new-object system.uri($hyperlink)
              $link_hyperlink = New-object System.Windows.Documents.Hyperlink
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Spotify Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
              $Null = $link_hyperlink.Inlines.add("HERE")
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Spotify_AuthHandler)
              $null = $hashsetup.Import_Spotify_textbox.Inlines.add("`nIf you wish to update/change your Spotify credentials, click ")  
              $null = $hashsetup.Import_Spotify_textbox.Inlines.add($($link_hyperlink))        
              $hashsetup.Import_Spotify_textbox.Foreground = "LightGreen"
              $hashsetup.Import_Spotify_textbox.FontSize = 14
              $hashsetup.Import_Spotify_transitioningControl.Height = 80
              $hashsetup.Import_Spotify_transitioningControl.content = $hashsetup.Import_Spotify_textbox
            }            
          }
          else
          {
            $hashsetup.Install_Spotify_Toggle.isEnabled = $false
            Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $false -MemberType NoteProperty -Force
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
            $hashsetup.Import_Spotify_textbox.text = ""
            $hashsetup.Import_Spotify_transitioningControl.Height = 0
            $hashsetup.Import_Spotify_transitioningControl.content = ''
          }     
        }catch{
          write-ezlogs "An exception occurred in Import_Spotify_Playlists_Toggle toggle event" -showtime -catcherror $_
        }

    })
    $hashsetup.Import_Spotify_Playlists_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Spotify_Playlists_Toggle.content
          update-EditorHelp -content "Enabling this will attempt to import all Spotify playlists and media from your Spotify account.`nA Spotify account and credentials will be required" -RichTextBoxControl $hashsetup.EditorHelpFlyout -FontWeight bold
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -TextDecorations Underline  -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "Once enabled, you will be required to provide your Spotify account login. A login window will appear when Saving/Starting setup, or you may click the link that appears when enabling this option"  -color orange  -RichTextBoxControl $hashsetup.EditorHelpFlyout
          #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
        }catch{
          write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
        }

    }) 
  
    #Install Spotify
    if($thisApp.Config.Install_Spotify){
      $hashsetup.Install_Spotify_Toggle.isOn = $true
    }else{
      $hashsetup.Install_Spotify_Toggle.isOn = $false
    }
    $hashsetup.Install_Spotify_Toggle.add_Toggled({
  
        if($hashsetup.Install_Spotify_Toggle.isOn)
        {  
          Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $true -MemberType NoteProperty -Force
        }else{
          Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $false -MemberType NoteProperty -Force
        }

    })
    $hashsetup.Install_Spotify_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Install_Spotify_Toggle.content
          update-EditorHelp -content "When this option is enabled, the latest version of the Spotify Desktop Client will be automatically installed if it is not already." -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "INFO" -FontWeight bold -color cyan -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "The Spotify desktop client is required to use native Spotify playback features (non-WebPlayer). Spotify will be installed using Chocolatey. For more information on this install method, see https://community.chocolatey.org/packages/spotify." -color cyan -RichTextBoxControl $hashsetup.EditorHelpFlyout  
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -TextDecorations Underline -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "If you do not enable this option, and still wish to use native Spotify playback features (non-WebPlayer), you must ensure you already have installed or will install the Spotify client." -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout        
        }catch{
          write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
        }

    })
       
    #---------------------------------------------- 
    #endregion Get Spotify Media
    #----------------------------------------------
  
    #---------------------------------------------- 
    #region Get Youtube Media
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
   
    $hashsetup.Import_Youtube_Auth_ComboBox.add_SelectionChanged({
        if($hashsetup.Import_Youtube_Auth_ComboBox.selectedindex -eq -1)
        {
          $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Red"
        }       
        else
        {
          $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Green"
        }      
    }) 
    $hashsetup.Import_Youtube_Auth_Toggle.add_Toggled({
        if($hashsetup.Import_Youtube_Auth_Toggle.isOn)
        {
          $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $true
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $true -MemberType NoteProperty -Force
        }
        else
        {
          $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $false -MemberType NoteProperty -Force
        }
    })       
    $hashsetup.Import_Youtube_Playlists_Toggle.add_Toggled({
        try{
          if($hashsetup.Import_Youtube_Playlists_Toggle.isOn)
          {     
            write-ezlogs ">>>> Enabling Import Youtube Playlists" -showtime
            $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
            $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true   
            $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 250  
            $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true 
            if($hashsetup.Import_Youtube_Auth_Toggle.isOn){
              $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $true
            }else{
              $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
            }           
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue   
            try{
              $Name = $($thisApp.Config.App_Name)
              $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
              if(!(Get-command Get-SecretStoreConfiguration -ErrorAction SilentlyContinue)){
                Import-module Microsoft.Powershell.SecretStore
              }
              $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
              #$vaultconfig = Get-SecretStoreConfiguration -ErrorAction SilentlyContinue
              if(!$secretstore){
                if([System.IO.File]::Exists($ConfigPath)){
                  write-ezlogs ">>>> Importing API Config file $ConfigPath" -showtime
                  $Client = Import-Clixml $ConfigPath
                }
                if($client.client_id){
                  try{
                    Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($client.client_id | ConvertTo-SecureString -AsPlainText -Force)
                  }catch{
                    write-ezlogs "An exception occurred executing Set-SecretStoreConfiguration" -showtime -catcherror $_
                  }
                }else{
                  write-ezlogs "Unable to get Youtube API client_id, cannot create/configure secretstore!" -showtime
                }
              }
              $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
              if(!$secretstore){
                Register-SecretVault -Name $Name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
                $secretstore = $Name
              }else{
                $secretstore = $secretstore.name
              }                  
            }catch{
              write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime
            }                    
            $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            if($refresh_access_token){
              $access_token_expires = Get-secret -name Youtubeexpires_in -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            }
            if(!$access_token_expires -or !$access_token -or !$refresh_access_token){
              $hyperlink = 'https://Youtube_Auth'
              #$uri = new-object system.uri($hyperlink)
              $hashsetup.Import_Youtube_textbox.isEnabled = $true
              $hashsetup.Youtube_Playlists_Import.isEnabled = $false
              $link_hyperlink = New-object System.Windows.Documents.Hyperlink
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
              $Null = $link_hyperlink.Inlines.add("HERE")
              $hashsetup.Import_Youtube_textbox.text = "[INFO] Using some Youtube features requires providing your Youtube account credentials. You will be prompted upon Starting/Saving setup"
              $hashsetup.Import_Youtube_textbox.Inlines.add("`n`nOptionally: Click ")
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Youtube_AuthHandler)
              $null = $hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
              $null = $hashsetup.Import_Youtube_textbox.Inlines.add(" to provide them now")   
              $hashsetup.Import_Youtube_textbox.Foreground = "Cyan"
              $hashsetup.Import_Youtube_textbox.FontSize = 14
              $hashsetup.Import_Youtube_transitioningControl.Height = 80
              $hashsetup.Import_Youtube_transitioningControl.content = $hashsetup.Import_Youtube_textbox
            }else{
              if($thisApp.Config.Verbose_logging){write-ezlogs "[SUCCESS] Returned Youtube authentication $($access_token)" -showtime}
              $hashsetup.Import_Youtube_textbox.text = "[SUCCESS] Retrieved previously provided Youtube authentication from Secure Vault"
              $hashsetup.Import_Youtube_textbox.isEnabled = $true
              $hashsetup.Youtube_Playlists_Import.isEnabled = $true
              $hyperlink = 'https://Youtube_Auth'
              #$uri = new-object system.uri($hyperlink)
              $link_hyperlink = New-object System.Windows.Documents.Hyperlink
              $link_hyperlink.NavigateUri = $hyperlink
              $link_hyperlink.ToolTip = "Open Youtube Authentication Capture"
              $link_hyperlink.Foreground = "LightBlue"
              $Null = $link_hyperlink.Inlines.add("HERE")
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Youtube_AuthHandler)
              $null = $hashsetup.Import_Youtube_textbox.Inlines.add("`nIf you wish to update/change your Youtube credentials, click ")  
              $null = $hashsetup.Import_Youtube_textbox.Inlines.add($($link_hyperlink))        
              $hashsetup.Import_Youtube_textbox.Foreground = "LightGreen"
              $hashsetup.Import_Youtube_textbox.FontSize = 14
              $hashsetup.Import_Youtube_transitioningControl.Height = 80
              $hashsetup.Import_Youtube_transitioningControl.content = $hashsetup.Import_Youtube_textbox          
            }                   
          }
          else
          {
            $hashsetup.Youtube_Playlists_Browse.IsEnabled = $false
            $hashsetup.YoutubePlaylists_Grid.IsEnabled = $false    
            $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
            $hashsetup.Youtube_Playlists_Import.isEnabled = $false
            $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $false    
            $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 0
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
            $hashsetup.Import_Youtube_textbox.text = ""
            $hashsetup.Import_Youtube_transitioningControl.Height = 0
            $hashsetup.Import_Youtube_transitioningControl.content = ''
          }
        }catch{
          write-ezlogs "An exception occurred in Import_Youtube_Playlists_Toggle.add_Toggled event" -showtime -catcherror $_
        }
    })
    $hashsetup.Import_Youtube_Playlists_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Youtube_Playlists_Toggle.content
          update-EditorHelp -content "Enabling this will allow you to add Youtube videos and/or playlists that the app will then import. For playlists, all valid videos found will be imported" -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "If you are attempting to manually add any videos or playlists that are private (including private videos within public playlists), you must provide valid Youtube credentials when prompted or alternatively, ensure you are logged in with a valid google account to youtube.com in your web browser.`nThen enable the setting 'Import Browser Cookies for Youtube' and select the browser you logged into under 'Select Browser'" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
        }catch{
          write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
        }

    }) 
    $hashsetup.Import_Youtube_Auth_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Youtube_Auth_Toggle.content
          update-EditorHelp -content "Enabling this will attempt to import cookies from the default profile of the browser you specify for Youtube authentication" -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "If you are attempting to add any videos or playlists that are private (including private videos within public playlists), you must first be logged in with a valid google account to youtube.com in your web browser.`nThen enable this setting and select the browser you logged into under 'Select Browser'.`nIf no means of authentication is found, any private videos/playlists will fail to import"  -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
        }catch{
          write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
        }

    })  
     
    $hashsetup.Youtube_Playlists_Browse.add_click({  
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Playlist","Enter the url of the Youtube Playlist",$button_settings)
        if(-not [string]::IsNullOrEmpty($result)){
          if((Test-URL $result) -and ($result -match 'youtube' -or $result -match 'yewtu.be' -or $result -match 'twitch')){
            if($hashsetup.YoutubePlaylists_Grid.items.path -notcontains $result){
              write-ezlogs "Adding URL $result" -showtime
              if($result -match "v="){
                $id = ($($result) -split('v='))[1].trim()  
                $type = 'YoutubeVideo'
                $Name = "Custom_$id"          
              }elseif($result -match 'list='){
                $id = ($($result) -split('list='))[1].trim()    
                $type = 'YoutubePlaylist'     
                $Name = "Custom_$id"                 
              }elseif($result -match 'twitch.tv'){
                $id = $((Get-Culture).textinfo.totitlecase(($result | split-path -leaf).tolower())) 
                $type = 'TwitchChannel'
                $Name = $id
              }
              Update-YoutubePlaylists -hashsetup $hashsetup -Path $result -id $id -type $type -Name $Name -VerboseLog:$thisApp.Config.Verbose_logging
            }else{
              write-ezlogs "The location $result has already been added!" -showtime -warning
            } 
          }else{
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Youtube Playlists'            
            update-EditorHelp -content "[WARNING] Invalid URL Provided" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
            update-EditorHelp -content "The location $result is not a valid URL! Please ensure the URL is a valid Youtube or Twitch URL" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout     
            write-ezlogs "The location $result is not a valid URL!" -showtime -warning
          }
        }else{
          write-ezlogs "No URL was provided!" -showtime -warning
        } 
    }) 
    
    $hashsetup.Youtube_My_Playlists_Import.add_Checked({
        try{
          Add-Member -InputObject $thisApp.config -Name "Import_My_Youtube_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occured in Youtube_My_Playlists_Import.add_Checked event" -showtime -catcherror $_
        }
    })
    $hashsetup.Youtube_My_Playlists_Import.add_UnChecked({
        try{
          Add-Member -InputObject $thisApp.config -Name "Import_My_Youtube_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occured in Youtube_My_Playlists_Import.add_UnChecked event" -showtime -catcherror $_
        }
    }) 
    $hashsetup.Youtube_My_Playlists_Import_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Youtube_My_Playlists_Import.content
          update-EditorHelp -content "Check this if you also wish to import Youtube videos you have uploaded to your channel when importing playlists from Youtube" -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "This needs to be documented with the help system"  -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
        }catch{
          write-ezlogs "An exception occurred in Youtube_My_Playlists_Import_Button.add_click event" -CatchError $_ -enablelogs
        }

    })           
    #---------------------------------------------- 
    #endregion Get Youtube Media
    #----------------------------------------------  
    
    
    #---------------------------------------------- 
    #region Get Twitch Media
    #---------------------------------------------- 
    #TODO: Finish Twitch Oauth integration
    [System.Windows.RoutedEventHandler]$Twitch_AuthHandler = {
      param ($sender,$e)
      if($sender.NavigateUri -match 'Twitch_Auth'){
        try{
          if([System.IO.Directory]::Exists("$($thisScript.TempFolder)\Spotify_Webview2")){   
            try{
              write-ezlogs ">>>> Removing existing Webview2 cache $($thisScript.TempFolder)\Spotify_Webview2" -showtime -color cyan
              $null = Remove-Item "$($thisScript.TempFolder)\Spotify_Webview2" -Force -Recurse
            }catch{
              write-ezlogs "An exception occurred attempting to remove $($thisScript.TempFolder)\Spotify_Webview2" -showtime -catcherror $_
            }
          }
          try{
            $secretstore = Get-SecretVault -Name $thisApp.config.App_Name -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting SecretStore $($thisApp.config.App_Name)" -showtime -catcherror $_
          }
          write-ezlogs "Removing stored Youtube authentication secrets from vault" -showtime -warning
          if($secretstore){
            $secretstore = $secretstore.name  
            try{
              $null = Remove-secret -name TwitchAccessToken -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret TwitchAccessToken" -showtime -catcherror $_
            }
            try{
              $null = Remove-secret -name Twitcheexpires_in -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret Twitchexpires_in" -showtime -catcherror $_
            }   
            try{
              $null = Remove-secret -name Twitchrefresh_token -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred removing Secret Twitchrefresh_token" -showtime -catcherror $_
            }                    
          }
          try{
            Grant-TwitchOauth -thisApp $thisApp -thisScript $thisScript 
            write-ezlogs ">>> Verifying Twitch authentication" -showtime
            $Twitchaccess_token = Get-secret -name TwitchAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $Twitchrefresh_access_token = Get-secret -name Twitchrefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret TwitchAccessToken" -showtime -catcherror $_
          } 
          if($Twitchaccess_token -and $Twitchrefresh_access_token){
            #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
            write-ezlogs "[SUCCESS] Authenticated to Twitch and retrieved access tokens" -showtime -color green 
            $hashsetup.Twitch_Playlists_Import.isEnabled = $true
            $hashsetup.Import_Twitch_transitioningControl.Height = 0
            $hashsetup.Import_Twitch_transitioningControl.content = ''
            $hashsetup.Import_Twitch_textbox.text = ''
            if($MahDialog_hash.window.Dispatcher -and $MahDialog_hash.window.isVisible){
              $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
            }  
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Twitch'            
            update-EditorHelp -content "[SUCCESS] Authenticated to Twitch and saved access tokens into the Secret Vault! You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                           
          }else{
            write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to Twitch!" -showtime -warning
            $hashsetup.Twitch_Playlists_Import.isEnabled = $false
            #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
            $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $false
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Twitch'            
            update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Twitch! Some Twitch features may be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout               
          }          
        }catch{
          write-ezlogs "An exception occurred in Twitch_AuthHandler routed event" -showtime -catcherror $_
        }         
      }     
    }  
    [System.Windows.RoutedEventHandler]$Twitch_ImportHandler = {
      param ($sender,$e)
      try{
        try{
          $Twitch_playlists = Get-TwitchPlaylists -mine
        }catch{
          write-ezlogs "An exception occurred retrieving youtube playlists with Get-TwitchPlaylists" -showtime -catcherror $_
        } 
        if($Twitch_playlists){
          foreach($playlist in $Twitch_playlists){              
            #$playlisturl = "https://www.youtube.com/playlist?list=$($playlist.id)"
            #$playlistName = $playlist.snippet.title
            if($hashsetup.TwitchPlaylists_Grid.items.path -notcontains $playlisturl){
              write-ezlogs "Adding Twitch Playlist URL $playlisturl" -showtime
              Update-TwitchPlaylists -hashsetup $hashsetup -Path $playlisturl -Name $playlistName -id $playlist.id -type 'TwitchChannel' -VerboseLog:$thisApp.Config.Verbose_logging
            }else{
              write-ezlogs "The Twitch Playlist URL $playlisturl has already been added!" -showtime -warning
            }
          }
        }         
      }catch{
        write-ezlogs "An exception occurred in Twitch_ImportHandler routed event" -showtime -catcherror $_
      }             
    } 
    #$Null = $hashsetup.Twitch_Playlists_Import.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Twitch_ImportHandler) 
    #TODO: Finish Twitch Oauth integration    
    <#    if($thisApp.Config.Import_Twitch_Media){
        if(@($thisApp.Config.Twitch_Playlists).count -gt 0){
        foreach($playlist in $thisApp.Config.Twitch_Playlists){
        if($playlist -match 'twitch.tv'){
        $id = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower())) 
        $Name = $id
        $type = 'TwitchChannel'
        Update-TwitchPlaylists -hashsetup $hashsetup -Path $playlist -id $id -type $type -Name $Name -VerboseLog:$thisApp.Config.Verbose_logging
        }       
        }
        }
        $Twitchaccess_token = Get-secret -name TwitchAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
        $Twitchrefresh_access_token = Get-secret -name Twitchrefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
        if($Twitchrefresh_access_token){
        $Twitchaccess_token_expires = Get-secret -name Twitchexpires_in -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
        }
        if(!$Twitchaccess_token_expires -or !$Twitchaccess_token){
        $hyperlink = 'https://Twitch_Auth'
        #$uri = new-object system.uri($hyperlink)
        $hashsetup.Import_Twitch_textbox.isEnabled = $true
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
        $link_hyperlink.Foreground = "LightBlue"
        #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
        $Null = $link_hyperlink.Inlines.add("HERE")
        $hashsetup.Import_Twitch_textbox.text = "[INFO] Using some Twitch features requires providing your Twitch account credentials. You will be prompted upon Starting/Saving setup"
        $hashsetup.Import_Twitch_textbox.Inlines.add("`n`nOptionally: Click ")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Twitch_AuthHandler)
        $null = $hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
        $null = $hashsetup.Import_YTwitch_textbox.Inlines.add(" to provide them now")   
        $hashsetup.Import_Twitch_textbox.Foreground = "Cyan"
        $hashsetup.Import_Twitch_textbox.FontSize = 14
        $hashsetup.Import_Twitch_transitioningControl.Height = 80
        $hashsetup.Import_Twitch_transitioningControl.content = $hashsetup.Import_Twitch_textbox
        $hashsetup.Twitch_Playlists_Import.isEnabled = $false
        }else{
        if($thisApp.Config.Verbose_logging){write-ezlogs "[SUCCESS] Returned Twitch authentication" -showtime}
        $hashsetup.Import_Twitch_textbox.text = "[SUCCESS] Retrieved previously provided Twitch authentication from Secure Vault"
        $hashsetup.Import_Twitch_textbox.isEnabled = $true
        $hyperlink = 'https://Twitch_Auth'
        #$uri = new-object system.uri($hyperlink)
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "Open Twitch Authentication Capture"
        $link_hyperlink.Foreground = "LightBlue"
        $Null = $link_hyperlink.Inlines.add("HERE")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Twitch_AuthHandler)
        $null = $hashsetup.Import_Twitch_textbox.Inlines.add("`nIf you wish to update/change your Twitch credentials, click ")  
        $null = $hashsetup.Import_Twitch_textbox.Inlines.add($($link_hyperlink))        
        $hashsetup.Import_Twitch_textbox.Foreground = "LightGreen"
        $hashsetup.Import_Twitch_textbox.FontSize = 14
        $hashsetup.Import_Twitch_transitioningControl.Height = 80
        $hashsetup.Import_Twitch_transitioningControl.content = $hashsetup.Import_Twitch_textbox
        $hashsetup.Twitch_Playlists_Import.isEnabled = $true
        }          
        $hashsetup.Import_Twitch_Playlists_Toggle.isOn = $true
        $hashsetup.Import_Twitch_Auth_Toggle.isEnabled = $true
        $hashsetup.Twitch_Playlists_Browse.IsEnabled = $true
        $hashsetup.TwitchPlaylists_Grid.IsEnabled = $true
        $hashsetup.Twitch_Playlists_ScrollViewer.MaxHeight = 250    
        }else{
        $hashsetup.Twitch_Playlists_ScrollViewer.MaxHeight = 0
        $hashsetup.Import_Twitch_textbox.text = ""
        $hashsetup.Import_Twitch_transitioningControl.Height = 0
        $hashsetup.Import_Twitch_transitioningControl.content = ''
        $hashsetup.Twitch_Playlists_Import.isEnabled = $false
    }#>    
               
    $hashsetup.Import_Twitch_Playlists_Toggle.add_Toggled({
  
        if($hashsetup.Import_Twitch_Playlists_Toggle.isOn)
        {     
          $hashsetup.Twitch_Playlists_Browse.IsEnabled = $true
          $hashsetup.TwitchPlaylists_Grid.IsEnabled = $true   
          $hashsetup.Twitch_Playlists_ScrollViewer.MaxHeight = 250     
          Add-Member -InputObject $thisApp.config -Name "Import_Twitch_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue   
                   
        }
        else
        {
          $hashsetup.Twitch_Playlists_Browse.IsEnabled = $false
          $hashsetup.TwitchPlaylists_Grid.IsEnabled = $false       
          $hashsetup.Twitch_Playlists_ScrollViewer.MaxHeight = 0
          Add-Member -InputObject $thisApp.config -Name "Import_Twitch_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
          $hashsetup.Import_Twitch_textbox.text = ""
          $hashsetup.Import_Twitch_transitioningControl.Height = 0
          $hashsetup.Import_Twitch_transitioningControl.content = ''
        }
    })
    $hashsetup.Import_Twitch_Playlists_Button.add_click({
        try{  
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Twitch_Playlists_Toggle.content
          update-EditorHelp -content "Enabling this will allow you to add Twitch channels/stream URLs that the app will then import." -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "IMPORTANT" -FontWeight bold -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout
          update-EditorHelp -content "Something important will go here. For now just add Twitch URLs to the Youtube list, this isnt finished" -color orange -RichTextBoxControl $hashsetup.EditorHelpFlyout  
        }catch{
          write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
        }

    })  
    $hashsetup.Twitch_Playlists_Browse.add_click({  
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Twitch URL","Enter the url of the Twitch Channel or Stream",$button_settings)
        if(-not [string]::IsNullOrEmpty($result)){
          if((Test-URL $result) -and ($result -match 'twitch.tv' -or $result -match 'twitch')){
            if($hashsetup.TwitchPlaylists_Grid.items.path -notcontains $result){
              $id = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower())) 
              $Name = $id
              $type = 'TwitchChannel'
              write-ezlogs "Adding URL $result" -showtime
              Update-TwitchPlaylists -hashsetup $hashsetup -Path $result -id $id -Name $Name -type $type -VerboseLog:$thisApp.Config.Verbose_logging
            }else{
              write-ezlogs "The location $result has already been added!" -showtime -warning
            } 
          }else{
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Twitch Channels'            
            update-EditorHelp -content "[WARNING] Invalid URL Provided" -color Orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
            update-EditorHelp -content "The location $result is not a valid URL! Please ensure the URL is a valid Twitch URL" -color Orange -RichTextBoxControl $hashsetup.EditorHelpFlyout     
            write-ezlogs "The location $result is not a valid URL!" -showtime -warning
          }
        }else{
          write-ezlogs "No URL was provided!" -showtime -warning
        } 
    })      
    #---------------------------------------------- 
    #endregion Get Twitch Media
    #----------------------------------------------    

    #---------------------------------------------- 
    #region Next Button
    #----------------------------------------------
    $hashsetup.Next_Button.add_Click({
        try{
          #write-ezlogs "$($hashsetup.Setup_TabControl.psobject.methods | where {$_ -match 'add_'})"
          if($hashsetup.Setup_TabControl.SelectedIndex -eq 0){
            $hashsetup.Setup_TabControl.SelectedIndex = 1
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 1){
            $hashsetup.Setup_TabControl.SelectedIndex = 2
            $hashsetup.Prev_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 2){
            $hashsetup.Setup_TabControl.SelectedIndex = 3
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Save_Setup_Button.isEnabled = $true
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 3){
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Prev_Button.isEnabled = $true
          }         
        }catch{
          write-ezlogs "An exception occurred in Next_Button click event" -CatchError $_ -showtime
        }  
    })
    #---------------------------------------------- 
    #endregion Next Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region Prev Button
    #----------------------------------------------
    $hashsetup.Prev_Button.add_Click({
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
          }         
        }catch{
          write-ezlogs "An exception occurred in Prev_Button click event" -CatchError $_ -showtime
        }  
    })
    #---------------------------------------------- 
    #endregion Prev Button
    #----------------------------------------------

    #---------------------------------------------- 
    #region Tab Selection Change
    #----------------------------------------------
    $hashsetup.Setup_TabControl.add_SelectionChanged({
        try{
          if($hashsetup.Setup_TabControl.SelectedIndex -eq 0){
            $hashsetup.Prev_Button.isEnabled = $false
            $hashsetup.Next_Button.isEnabled = $true
            if(!$update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 1){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
            if(!$update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 2){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $true
            if(!$update){
              $hashsetup.Save_Setup_Button.isEnabled = $false
            }
          }elseif($hashsetup.Setup_TabControl.SelectedIndex -eq 3){
            $hashsetup.Prev_Button.isEnabled = $true
            $hashsetup.Next_Button.isEnabled = $false
            $hashsetup.Save_Setup_Button.isEnabled = $true
          }         
        }catch{
          write-ezlogs "An exception occurred in Setup_TabControl add_SelectionChanged  event" -CatchError $_ -showtime
        }  
    })
    #---------------------------------------------- 
    #endregion Tab Selection Change
    #----------------------------------------------

    #---------------------------------------------- 
    #region Apply Settings Button
    #----------------------------------------------
    $hashsetup.Save_Setup_Button.add_Click({
        try{   
          $hashsetup.Save_setup_textblock.text = ""
          if(!$hashsetup.Import_Local_Media_Toggle.isOn -and !$hashsetup.Import_Youtube_Playlists_Toggle.isOn -and !$hashsetup.Import_Spotify_Playlists_Toggle){
            $hashsetup.Save_setup_textblock.text = "You must enable at least 1 Media type to import in order to continue! (Local Media, Spotify, or Youtube)"
            $hashsetup.Save_setup_textblock.foreground = "Orange"
            $hashsetup.Save_setup_textblock.FontSize = 14            
            write-ezlogs "At least 1 Media type to import was not selected! (Local Media, Spotify, or Youtube)" -showtime -warning              
            return
          }               
          if($hashsetup.Import_Local_Media_Toggle.isOn)
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $true -MemberType NoteProperty -Force
            $newLocalMediaCount = 0
            $RemovedLocalMediaCount = 0
            #$thisApp.Config.Media_Directories.clear()
            foreach($path in $hashsetup.MediaLocations_Grid.items){
              if([System.IO.Directory]::Exists($path.path)){
                if($thisApp.Config.Media_Directories -notcontains $path.path){
                  write-ezlogs " | Adding new Local Media Directory $($path.path)" -showtime
                  $null = $thisApp.Config.Media_Directories.add($path.path)
                  $newLocalMediaCount++
                }            
              }else{
                $hashsetup.Save_setup_textblock.text = "The provide local media path $($path.path) is invalid!"
                $hashsetup.Save_setup_textblock.foreground = "Orange"
                $hashsetup.Save_setup_textblock.FontSize = 14            
                write-ezlogs "The provide local media path $($path.path) is invalid!" -showtime -warning              
                return
              } 
            }
            #$hashSetup.paths_toRemove = New-Object System.Collections.ArrayList
            $hashSetup.paths_toRemove = $thisApp.Config.Media_Directories | where {$hashsetup.MediaLocations_Grid.items.path -notcontains $_}    
            if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.LocalMedia_Browser_Tab){
              $syncHash.Window.Dispatcher.invoke([action]{
                  $Null = $syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.LocalMedia_Browser_Tab) 
                  $syncHash.MediaTable.isEnabled = $false
                  $syncHash.LocalMedia_Browser_Tab.isEnabled = $true
              })            
            }                     
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $false -MemberType NoteProperty -Force
          }
          if($hashsetup.Import_Youtube_Playlists_Toggle.isOn)
          {
            try{
              $Name = $($thisApp.Config.App_Name)
              $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
              $vaultconfig = Get-SecretStoreConfiguration
              if(!$vaultconfig){
                if([System.IO.File]::Exists($ConfigPath)){
                  write-ezlogs ">>>> Importing API Config file $ConfigPath" -showtime
                  $Client = Import-Clixml $ConfigPath
                }
                Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($client.client_id | ConvertTo-SecureString -AsPlainText -Force)
              }
              $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
              if(!$secretstore){
                Register-SecretVault -Name $Name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
                $secretstore = $Name
              }else{
                $secretstore = $secretstore.name
              }                  
            }catch{
              write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs
            }            
            $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            if($refresh_access_token){
              $access_token_expires = Get-secret -name Youtubeexpires_in -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            }
            if(!$access_token_expires -or !$access_token -or !$refresh_access_token){
              try{
                Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript 
                $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
                $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
              }catch{
                write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
              } 
              if($access_token -and $refresh_access_token){
                #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                write-ezlogs "[SUCCESS] Authenticated to Youtube and retrieved access tokens" -showtime -color green                           
              }else{
                write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to Youtube!" -showtime -warning
                #Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
                update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Youtube! You may try to re-authenticate again or disable Import Youtube" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout      
                break         
              }             
            }else{
              if($thisApp.Config.Verbose_logging){write-ezlogs "[SUCCESS] Returned Youtube authentication $($access_token)" -showtime}
            }            
            $newYoutubeMediaCount = 0
            $RemovedYoutubeMediaCount = 0
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $true -MemberType NoteProperty -Force
            if($hashsetup.Import_Youtube_Auth_ComboBox.Selectedindex -ne -1){
              Add-Member -InputObject $thisApp.config -Name "Youtube_Browser" -Value $hashsetup.Import_Youtube_Auth_ComboBox.Selecteditem.Content -MemberType NoteProperty -Force
            }else{
              Add-Member -InputObject $thisApp.config -Name "Youtube_Browser" -Value $null -MemberType NoteProperty -Force
            }                    
            #$thisApp.Config.Youtube_Playlists.clear()
            $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
            if(![System.IO.Directory]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists")){
              try{
                $Null = New-item -Path "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists" -ItemType Directory -Force
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
                    if($thisApp.Config.Verbose_logging){write-ezlogs " | Adding new Youtube Playlist URL: $($playlist.path) - Name: $($playlist.Name)" -showtime}
                    $null = $thisApp.Config.Youtube_Playlists.add($playlist.path)
                    if($Playlist_Profile -and $playlist.path -notmatch 'Twitch.tv'){  
                      if($playlist.Name){
                        $playlist_Name = $playlist.name
                      }else{
                        $playlist_Name = "Custom_$($playlist.id)"
                      }    
                      $playlistName_Cleaned = ([Regex]::Replace($playlist_Name, $pattern3, '')).trim()            
                      $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($playlist.id).xml"
                      if($thisApp.Config.Verbose_logging){write-ezlogs " | Saving new Youtube Playlist profile to $Playlist_Profile_path" -showtime}
                      $Playlist_Profile.name = $playlist_Name
                      $Playlist_Profile.NameCleaned = $playlistName_Cleaned
                      $Playlist_Profile.Playlist_ID = $playlist.id
                      $Playlist_Profile.Playlist_URL = $playlist.path
                      $Playlist_Profile.type = $playlist.type
                      $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                      $Playlist_Profile.Playlist_Date_Added = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                      if($playlist.playlist_info.id){
                        $Playlist_Profile.Source = 'YoutubeAPI'
                        Add-Member -InputObject $Playlist_Profile -Name 'Playlist_Info' -Value $playlist.playlist_info -MemberType NoteProperty -Force
                      }else{
                        $Playlist_Profile.Source = 'Custom'
                      }
                      $Playlist_Profile | Export-Clixml $Playlist_Profile_path -Force                    
                    }
                    $newYoutubeMediaCount++
                  }catch{
                    write-ezlogs "An exception occurred adding path $($playlist.path) to Youtube_Playlists" -showtime -catcherror $_
                  }
                }            
              }else{
                $hashsetup.Save_setup_textblock.text = "The provided Youtube playlist URL $($playlist.path) is invalid!"
                $hashsetup.Save_setup_textblock.foreground = "Orange"
                $hashsetup.Save_setup_textblock.FontSize = 14            
                write-ezlogs "The provided Youtube playlist URL $($playlist.path) is invalid!" -showtime -warning
                return
              } 
            }
            if($update){
              $hashSetup.playlists_toRemove = New-Object System.Collections.ArrayList
              $playlists_toRemove = $thisApp.Config.Youtube_Playlists | where {$hashsetup.YoutubePlaylists_Grid.items.path -notcontains $_}
              if($playlists_toRemove){
                foreach($playlist in $playlists_toRemove){
                  $RemovedYoutubeMediaCount++
                  $null = $hashSetup.playlists_toRemove.add($playlist)
                  if($thisApp.Config.Verbose_logging){write-ezlogs " | Removing Youtube Playlist $($playlist)" -showtime}
                  $null = $thisApp.Config.Youtube_Playlists.Remove($playlist)
                }
              }
            }
            if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Youtube_Tabitem){
              $syncHash.Window.Dispatcher.invoke([action]{
                  $Null = $syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Youtube_Tabitem) 
                  $syncHash.YoutubeTable.isEnabled = $true
                  $syncHash.Youtube_Tabitem.isEnabled = $true
              })            
            }                             
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $false -MemberType NoteProperty -Force
          }
          if($hashsetup.Import_Twitch_Playlists_Toggle.isOn)
          {
            
            $newTwitchMediaCount = 0
            $RemovedTwitchMediaCount = 0
            Add-Member -InputObject $thisApp.config -Name "Import_Twitch_Media" -Value $true -MemberType NoteProperty -Force                   
            $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
            if(!$thisApp.Config.Twitch_Playlists){
              Add-Member -InputObject $thisApp.config -Name 'Twitch_Playlists' -Value $(New-object System.Collections.ArrayList) -MemberType NoteProperty -Force 
            }
            foreach($playlist in $hashsetup.TwitchPlaylists_Grid.items){
              if(Test-URL $playlist.path){
                if($thisApp.Config.Twitch_Playlists -notcontains $playlist.path){
                  write-ezlogs " | Adding new Twitch URL $($playlist.path)" -showtime
                  $null = $thisApp.Config.Twitch_Playlists.add($playlist.path)
                  $newYoutubeMediaCount++
                }            
              }else{
                $hashsetup.Save_setup_textblock.text = "The provided Twitch URL $($playlist.path) is invalid!"
                $hashsetup.Save_setup_textblock.foreground = "Orange"
                $hashsetup.Save_setup_textblock.FontSize = 14            
                write-ezlogs "The provided Twitch URL $($playlist.path) is invalid!" -showtime -warning
                return
              } 
            }
            $hashSetup.Twitchplaylists_toRemove = New-Object System.Collections.ArrayList
            $Twitchplaylists_toRemove = $thisApp.Config.Twitch_Playlists | where {$hashsetup.TwitchPlaylists_Grid.items.path -notcontains $_}
            if($Twitchplaylists_toRemove){
              foreach($playlist in $Twitchplaylists_toRemove){
                $RemovedTwitchMediaCount++
                $null = $hashSetup.Twitchplaylists_toRemove.add($playlist)
                write-ezlogs " | Removing Twitch $($playlist)" -showtime
                $null = $thisApp.Config.Twitch_Playlists.Remove($playlist)
              }
            }                    
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Twitch_Media" -Value $false -MemberType NoteProperty -Force
          }                         
          if($hashsetup.Import_Spotify_Playlists_Toggle.isOn)
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force
            if(!$Spotify_Auth_app.token.access_token){
              write-ezlogs "Starting spotify authentication setup process" -showtime -warning  
              $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
              write-ezlogs "Importing API XML $APIXML" -showtime
              if([System.IO.File]::Exists($APIXML)){
                $Spotify_API = Import-Clixml $APIXML
                $client_ID = $Spotify_API.ClientID
                $client_secret = $Spotify_API.ClientSecret            
              }
              if($Spotify_API -and $client_ID -and $client_secret){
                write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime
                #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientSecret | ConvertTo-SecureString))))
                #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientID | ConvertTo-SecureString))))            
                New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
                $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
                if($Spotify_Auth_app){
                  try{
                    $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript                
                  }catch{
                    write-ezlogs "[Show-FirstRun] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_ -enablelogs
                  }                             
                  if($playlists){
                    Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                    write-ezlogs "[SUCCESS] Authenticated to Spotify and retrieved Playlists" -showtime -color green
                    $hashsetup.Import_Spotify_transitioningControl.Height = 0
                    $hashsetup.Import_Spotify_transitioningControl.content = ''
                    $hashsetup.Import_Spotify_textbox.text = '' 
                    if($MahDialog_hash.window.Dispatcher){
                      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                    }  
                    if($hashsetup.EditorHelpFlyout.Document.Blocks){
                      $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                    }        
                    $hashsetup.Editor_Help_Flyout.isOpen = $true
                    $hashsetup.Editor_Help_Flyout.header = 'Spotify'                               
                    update-EditorHelp -content "[SUCCESS] Authenticated to Spotify and retrieved Playlists! In order for Spotify playback to work properly, please ensure that you are logged in to the Spotify app with your account. You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout 
                    if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Spotify_Tabitem){
                      $syncHash.Window.Dispatcher.invoke([action]{
                          $Null = $syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Spotify_Tabitem) 
                          $syncHash.SpotifyTable.isEnabled = $true
                          $syncHash.Spotify_Tabitem.isEnabled = $true
                      })            
                    }                                              
                  }else{
                    write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to spotify!" -showtime -warning
                    Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                    $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                    if($hashsetup.EditorHelpFlyout.Document.Blocks){
                      $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                    }        
                    $hashsetup.Editor_Help_Flyout.isOpen = $true
                    $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                    update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! (No playlists returned!) Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout
                    Remove-SpotifyApplication -Name $thisApp.config.App_Name               
                  }
                  if(!$hashsetup.Window.isVisible){
                    $hashsetup.Window.Showdialog()
                  }              
                  #$devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
                  #Show-WebLogin -SplashTitle "Spotify Account Login" -SplashMessage "Splash Message" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL 'https://accounts.spotify.com/authorize' -thisScript $thisScript
                }
              }else{
                write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning      
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API (Couldn't find API creds!). Spotify integration will be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout   
                Remove-SpotifyApplication -Name $thisApp.config.App_Name   
                return
              }
            } 
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
            Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $false -MemberType NoteProperty -Force
          } 
          if($hashsetup.Install_Spotify_Toggle.isOn){
            Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $true -MemberType NoteProperty -Force        
          }else{
            Add-Member -InputObject $thisApp.config -Name "Install_Spotify" -Value $false -MemberType NoteProperty -Force
          }
          if($hashsetup.Import_Youtube_Auth_Toggle.isOn)
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $true -MemberType NoteProperty -Force
          }
          else
          {
            Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $false -MemberType NoteProperty -Force
          }              
          $thisApp.config | Export-Clixml -Path $thisApp.config.Config_Path -Force -Encoding UTF8
          $playlist_pattern = [regex]::new('$(?<=((?i)Playlist.xml))')
          if($First_Run -and ([System.IO.Directory]::Exists($thisApp.config.Playlist_Profile_Directory))){
            $existing_playlists = [System.IO.Directory]::EnumerateFiles($thisApp.config.Playlist_Profile_Directory,'*','AllDirectories') | where {$_ -match $playlist_pattern} 
            if($existing_playlists){
              write-ezlogs " | Prompting user to decide whether to delete existing playlists for first run" -showtime -enablelogs -color cyan
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_settings.AffirmativeButtonText = "Yes"
              $Button_settings.NegativeButtonText = "No"  
              $hashsetup.Window.Dispatcher.invoke([action]{
                  $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
                  $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Keep Playlists?","Existing Playlists profiles were found while running setup. Do you wish to keep these profiles?`nNOTE: If updating to a new version, there is a chance old profiles will no longer work properly, which is why its recommended to remove them. Additional options/abilities are planned to preserve playlists between versions",$okAndCancel,$button_settings)
                  if($result -eq 'Affirmative'){
                    write-ezlogs "User wished to keep existing playlist profiles" -showtime -warning
                  }else{
                    write-ezlogs " | Clearing playlist profile directory $($thisApp.config.Playlist_Profile_Directory)" -showtime 
                    $null = Remove-item $thisApp.config.Playlist_Profile_Directory -Force -Recurse 
                  }
              }) 
            }else{
              write-ezlogs "No existing playlists found, continuing" -showtime
            }
          }    
          if(!$First_run -and $Update){
            $hashsetup.Update_Media_Sources = $true
            if($newLocalMediaCount -ge 1){
              write-ezlogs "Found $newLocalMediaCount additions to local media sources" -showtime
              $hashsetup.Update_LocalMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to local media sources" -showtime
            }
            if(@($hashSetup.paths_toRemove).count -ge 1){
              $synchash.LocalMedia_ToRemove = New-Object -TypeName 'System.Collections.ArrayList'
              write-ezlogs "Found $(@($hashSetup.paths_toRemove).count) removals from local media sources" -showtime           
              foreach($path in $hashSetup.paths_toRemove){
                #$null = $hashSetup.paths_toRemove.add($path)
                write-ezlogs " | Removing Local Media Directory $($path)" -showtime
                $null = $thisApp.Config.Media_Directories.Remove($path)
                #$media_to_remove = ($synchash.LocalMedia_FilterView_Groups.GetEnumerator() | select *).Value | where {$_.Directory -eq $path}
                if($synchash.All_local_Media){
                  write-ezlogs "Parsing All_Local_media for media in directory $($path)" -showtime
                  $media_to_remove = $synchash.All_local_Media | where {([System.IO.Directory]::GetParent($_.url).fullname) -match [regex]::Escape($path)}
                }elseif($Datatable.datatable){
                  write-ezlogs "Parsing Datatable for media in directory $($path)" -showtime
                  $media_to_remove = $Datatable.datatable | where {([System.IO.Directory]::GetParent($_.url).fullname) -match [regex]::Escape($path)}
                }
                if($media_to_remove){ 
                  $synchash.LocalMedia_ToRemove = $media_to_remove
                  <#                  foreach($media in $media_to_remove | where {$_.id}){
                      if($synchash.LocalMedia_ToRemove.id -notcontains $media.id){
                      if($thisApp.Config.Verbose_logging){write-ezlogs "Adding media to remove $($media.name)" -showtime} 
                      #write-ezlogs "Adding media to remove $($media.name)" -showtime
                      $null = $synchash.LocalMedia_ToRemove.add($media)                      
                      }
                  }#>
                }
              }
              $thisApp.config | Export-Clixml -Path $thisApp.config.Config_Path -Force -Encoding UTF8          
              $hashsetup.Remove_LocalMedia_Sources = $true                
            }else{
              write-ezlogs "No removals found from local media sources" -showtime
            }    
            if($newYoutubeMediaCount -ge 1){
              write-ezlogs "Found $newYoutubeMediaCount additions to Youtube media sources" -showtime
              $hashsetup.Update_YoutubeMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to Youtube media sources" -showtime
            }
            if($RemovedYoutubeMediaCount -ge 1){
              write-ezlogs "Found $RemovedYoutubeMediaCount removals from Youtube media sources" -showtime        
              foreach($path in $hashSetup.playlists_toRemove){
                if($thisApp.Config.Youtube_Playlists -contains $path){
                  write-ezlogs " | Removing Youtube playlist $($path)" -showtime
                  $null = $thisApp.Config.Youtube_Playlists.remove($path)
                }
              }
              $thisApp.config | Export-Clixml -Path $thisApp.config.Config_Path -Force -Encoding UTF8 
              if($synchash.All_Youtube_Media){
                write-ezlogs "Parsing All_Youtube_media for for playlists to remove" -showtime
                $playlists_to_remove = $synchash.All_Youtube_Media | where {$hashSetup.playlists_toRemove -contains $_.url}
              }elseif($Youtube_Datatable.datatable){
                write-ezlogs "Parsing Youtube_Datatable.datatable for playlists to remove" -showtime
                $playlists_to_remove = $Youtube_Datatable.datatable | where {$hashSetup.playlists_toRemove -contains $_.Playlist_URL}
              }
              if($playlists_to_remove){
                $hashsetup.Remove_YoutubeMedia_Sources = $true 
                $hashSetup.playlists_toRemove = $playlists_to_remove
              }else{
                $hashsetup.Remove_YoutubeMedia_Sources = $false
              }
            }else{
              write-ezlogs "No removals found from Youtube media sources" -showtime
            }  
            if($newTwitchMediaCount -ge 1){
              write-ezlogs "Found $newTwitchMediaCount additions to Twitch media sources" -showtime
              $hashsetup.Update_TwitchMedia_Sources = $true
            }else{
              write-ezlogs "No additions found to Twitch media sources" -showtime
            }
            if($RemovedTwitchMediaCount -ge 1){
              write-ezlogs "Found $RemovedTwitchMediaCount removals from Twitch media sources" -showtime
              $hashsetup.Remove_TwitchMedia_Sources = $true
            }else{
              write-ezlogs "No removals found from Twitch media sources" -showtime
            }                    
          }  
          $hashsetup.Accepted = $true           
          Close-FirstRun -Use_Runspace:$Use_Runspace                         
        }catch{
          $hashsetup.Accepted = $false
          $hashsetup.Canceled = $false
          $hashsetup.Save_setup_textblock.text = "An exception occurred when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
          $hashsetup.Save_setup_textblock.foreground = "Tomato"
          $hashsetup.Save_setup_textblock.FontSize = 14
          write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime -enablelogs
        }
    })
    #---------------------------------------------- 
    #endregion Apply Settings Button
    #---------------------------------------------- 
  
    #---------------------------------------------- 
    #region Cancel Button
    #----------------------------------------------
    $hashsetup.Cancel_Setup_Button.add_Click({
        try{          
          write-ezlogs ">>>> User choose to cancel first run setup...exiting" -showtime -enablelogs
          $existingjob_check = $Jobs | where {$_.name -match 'enumerate_files_Scriptblock'}
          if($existingjob_check){ 
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_settings.AffirmativeButtonText = "Yes"
            $Button_settings.NegativeButtonText = "No"  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Scan in Progress","App is currently scanning for valid media files, are you sure you wish to cancel?",$okAndCancel,$button_settings)
            if($result -eq 'Affirmative'){
              write-ezlogs "User wished to cancel" -showtime -warning
            }else{
              write-ezlogs " | User did not wish to cancel" -showtime  
              break
            }
          } 
          $hashsetup.Canceled = $true       
          Close-FirstRun -Use_Runspace:$Use_Runspace  
          [GC]::Collect() 
          if($First_Run){
            Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs          
            Stop-Process $pid 
            exit 
          }else{
            $hashsetup.Update_Media_Sources = $false
          } 
                                            
        }catch{
          $hashsetup.Save_setup_textblock.text = "An exception occurred when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
          $hashsetup.Save_setup_textblock.foreground = "Tomato"
          $hashsetup.Save_setup_textblock.FontSize = 14
          write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime -enablelogs
          if($First_Run){
            exit
          }else{
            $hashsetup.Update_Media_Sources = $false
          }                
        }
    })
    #---------------------------------------------- 
    #endregion Cancel Button
    #----------------------------------------------   
    $hashsetup.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $hashsetup.Window){    
          #$hashsetup.Canceled = $true
          $existingjob_check = $Jobs | where {$_.name -match 'enumerate_files_Scriptblock'}
          if($existingjob_check){
            try{
              if(($existingjob_check.runspace) -and $existingjob_check.runspace.isCompleted -eq $false){
                write-ezlogs " Existing Runspace '$($_.name)' found as busy, canceling" -showtime -warning    
                $existingjob_check.powershell.stop()    
                #$existingjob_check.powershell.Runspace.Dispose()
                $existingjob_check.powershell.dispose()        
                $Null = $jobs.remove($existingjob_check)            
              }
            }catch{
              write-ezlogs "An exception occurred stopping runspace $($_.name)" -showtime -catcherror $_
            }
          }          
          try{
            if(($Update -or $hashsetup.Canceled -or $hashsetup.Accepted)){
              write-ezlogs "Show-Firstrun Closed" -showtime
              if($Update){
                $synchash.Window.Dispatcher.invoke([action]{
                    $synchash.Add_Media_Button.isEnabled = $true               
                },'Normal')
              }
              if(!$First_Run -and $hashsetup.Update_Media_Sources){
                #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
                #Start-Sleep 1
                if($thisapp.config.Import_Local_Media){   
                  if($hashsetup.Update_LocalMedia_Sources){
                    write-ezlogs ">>>> Updating Local media table" -showtime
                    $synchash.Window.Dispatcher.invoke([action]{
                        $synchash.LocalMedia_Progress_Ring.isActive = $true
                        $synchash.MediaTable.isEnabled = $false                   
                    },'Normal')
                    Import-Media -Media_directories $thisapp.Config.Media_Directories -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -Refresh_All_Media:$false         
                  }
                  if($hashsetup.Remove_LocalMedia_Sources){
                    if(@($synchash.LocalMedia_ToRemove).count -gt 0){
                      $synchash.Window.Dispatcher.invoke([action]{
                          $synchash.LocalMedia_Progress_Ring.isActive = $true  
                          $synchash.MediaTable.isEnabled = $false                 
                      },'Normal') 
                      if($synchash.LocalMedia_ToRemove){
                        $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
                        if([System.IO.File]::Exists($AllMedia_Profile_File_Path)){
                          write-ezlogs "Importing All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime 
                          [System.Collections.ArrayList]$all_media_profile = Import-Clixml $AllMedia_Profile_File_Path 
                        }
                        [System.Collections.ArrayList]$all_media_profile = $all_media_profile | where {$synchash.LocalMedia_ToRemove.id -notcontains $_.id}
                        <#                        foreach($Media in  ($synchash.LocalMedia_ToRemove) | where {$_.id}){
                            $Media_id = $Media.id
                            #write-ezlogs ">>>> Removing Media $($Media.name) - $($Media.id)" -showtime -color cyan
                            if($thisapp.config.Current_Playlist.values -contains $Media.id){
                            write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
                            $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
                            $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                  
                            }
                            if($all_media_profile){
                            $tracks_to_remove = $all_media_profile | where {$_.id -eq $Media.id}
                            if($tracks_to_remove){
                            if($thisApp.Config.Verbose_logging){write-ezlogs " | Removing track $($tracks_to_remove.Name) from playlists and profiles" -showtime}
                            $all_media_profile = $all_media_profile | where {$_.id -ne $tracks_to_remove.id}         
                            } 
                            }
                            $playlist_to_modify = $all_playlists.playlists | where {$_.playlist_tracks.id -eq $Media.id}
                            if($playlist_to_modify){
                            foreach($Playlist in $playlist_to_modify){
                            $Track_To_Remove = $Playlist.playlist_tracks | where {$_.id -eq $Media_id}
                            if($Track_To_Remove){
                            write-ezlogs " | Removing track $($Media_id) from playlist $($Playlist.name)" -showtime
                            $null = $playlist_to_modify.playlist_tracks.remove($Track_To_Remove)
                            write-ezlogs ">>>> Saving Playlist profile to path $($Playlist.Playlist_Path)"
                            $Playlist | Export-Clixml $Playlist.Playlist_Path -Force
                            }
                            }
                            write-ezlogs ">>>> Saving all_playlists cache profile to path $($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"       
                            $all_playlists.playlists | Export-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8   
                            }                     
                        }#>
                        Import-Media -Media_directories $thisapp.config.Media_Directories -use_runspace -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -startup -thisApp $thisapp -Refresh_All_Media  
                        write-ezlogs "Updating All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime 
                        [System.Collections.ArrayList]$all_media_profile | Export-Clixml $AllMedia_Profile_File_Path -Force                                           
                      }else{
                        write-ezlogs "There was no local media to remove!" -showtime -warning
                      }                      
                      #$hashsetup.LocalMedia_ViewUpdate = $view    
                      #update-Notifications -id 1 -Level 'INFO' -Message "Restart the app for changes to Local Media Browser to take effect!" -VerboseLog -Message_color 'Cyan' -thisApp $thisapp -synchash $synchash -open_flyout               
                      #$synchash.LocalMediaremove_item_timer.start() 
                    }
                  }              
                }else{
                  $synchash.MediaTable.ItemsSource = $null
                }        
                if($thisapp.Config.Import_Spotify_Media){
                  write-ezlogs ">>>> Updating Spotify media table" -showtime
                  #$hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Spotify Media'},'Normal')        
                  Import-Spotify -Media_directories $thisapp.Config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -thisApp $thisapp 
                }else{
                  $AllSpotify_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisapp.config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')        
                  if([System.IO.File]::exists($AllSpotify_Media_Profile_Directory_Path)){$null = Remove-Item $AllSpotify_Media_Profile_Directory_Path -Force}
                  $synchash.Window.Dispatcher.invoke([action]{
                      $synchash.SpotifyTable.ItemsSource = $null                  
                  },'Normal')             
                }
                if($thisapp.Config.Import_Youtube_Media){
                  #$hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Youtube Media'},'Normal')
                  if($hashSetup.playlists_toRemove -and $hashsetup.Remove_YoutubeMedia_Sources){
                    $All_YoutubeMedia_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')
                    if([System.IO.File]::Exists($All_YoutubeMedia_File_Path)){
                      write-ezlogs "Importing All Youtube Media profile cache at $All_YoutubeMedia_File_Path" -showtime 
                      [System.Collections.ArrayList]$all_youtubemedia_profile = Import-Clixml $All_YoutubeMedia_File_Path
                    }
                    [System.Collections.ArrayList]$all_youtubemedia_profile = $all_youtubemedia_profile | where {$hashSetup.playlists_toRemove.id -notcontains $_.id}
                    write-ezlogs "Updating All Youtube Media profile cache at $All_YoutubeMedia_File_Path" -showtime 
                    [System.Collections.ArrayList]$all_youtubemedia_profile | Export-Clixml $All_YoutubeMedia_File_Path -Force 
                  }
                  if($hashsetup.Update_YoutubeMedia_Sources -or $hashsetup.Remove_YoutubeMedia_Sources){
                    Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh 
                  }      
                }else{
                  $AllYoutube_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisapp.config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')        
                  if([System.IO.File]::exists($AllYoutube_Media_Profile_Directory_Path)){$null = Remove-Item $AllYoutube_Media_Profile_Directory_Path -Force}
                  $synchash.Window.Dispatcher.invoke([action]{
                      $synchash.YoutubeTable.ItemsSource = $null                
                  },'Normal')                 
                }                          
              }                
              #write-ezlogs ">>>> Closing First run to continue setup...." -showtime  
              #$hashsetup = $Null      
            }else{
              write-ezlogs "Show-Firstrun was not closed with either the cancel button or Save button, exiting" -showtime -warning
              Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs          
              Stop-Process $pid 
              exit 
            }             
          }catch{
            write-ezlogs "An exception occurred closing Show-Firstrun window" -showtime -catcherror $_
            return
          }          
        }       
    }.GetNewClosure())    
    try{
      $null = $hashsetup.window.ShowDialog()
      $window_active = $hashsetup.Window.Activate()    
      if(!$First_Run){
        [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashsetup.Window)
        [void][System.Windows.Forms.Application]::EnableVisualStyles() 
        $hashsetup.appContext = New-Object System.Windows.Forms.ApplicationContext 
        [void][System.Windows.Forms.Application]::Run($hashsetup.appContext)
      }      
    }catch{
      write-ezlogs "An exception occurred when opening main Show-Firstrun window" -showtime -CatchError $_
      Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs          
      Stop-Process $pid         
    }  
  }
  $Global:MahDialog_hash = [hashtable]::Synchronized(@{})
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}
  if($Use_runspace){
    Start-Runspace $FirstRun_Scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -runspace_name 'Show_FirstRun' -logfile $thisApp.Config.Log_File -Script_Modules $thisApp.Config.Script_Modules -thisApp $thisApp -synchash $synchash -verboselog
  }else{
    write-ezlogs ">>>> Starting setup without runspace" -showtime
    Invoke-Command -ScriptBlock $FirstRun_Scriptblock
  } 
}
#---------------------------------------------- 
#endregion Show-FirstRun Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-FirstRun','Close-FirstRun')




  