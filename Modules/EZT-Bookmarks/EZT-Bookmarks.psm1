<#
    .Name
    EZT-Bookmarks

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of functions used to manage web browser like systems for webview2 in a WPF UI

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>
#---------------------------------------------- 
#region Get-Bookmarks Function
#----------------------------------------------
function Get-Bookmarks
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    $thisApp,
    $Group,
    $thisScript,
    [switch]$VerboseLog,
    [switch]$dev_mode,
    [switch]$Import_Bookmarks_Cache = $true
  )
  $Get_Bookmarks_Measure = [system.diagnostics.stopwatch]::StartNew() 
  try{
    if($Import_Bookmarks_Cache){   
      try{
        if(([System.IO.File]::Exists("$($thisApp.config.Bookmarks_Profile_Directory)\All-Bookmarks-Cache.xml"))){
          $synchash.All_Bookmarks = [System.Windows.Data.CollectionViewSource]::GetDefaultView((Import-Clixml "$($thisApp.config.Bookmarks_Profile_Directory)\All-Bookmarks-Cache.xml"))
        }else{
          $synchash.All_Bookmarks = [System.Windows.Data.CollectionViewSource]::GetDefaultView([System.Collections.Generic.List[Object]]::new())
        } 
      }catch{
        write-ezlogs "An exception occurred importing Bookmarks cache" -showtime -catcherror $_
      }
    }
    $synchash.All_Bookmark_Groups = $synchash.All_Bookmarks.Group_Name | select -Unique | sort
    $groupdescription = [System.Windows.Data.PropertyGroupDescription]::new()
    $groupdescription.PropertyName = 'Group_Name'
    $Null = $synchash.All_Bookmarks.GroupDescriptions.Add($groupdescription)
    if($synchash.Bookmarks_TreeView){
      $synchash.Bookmarks_TreeView.Itemssource = $synchash.All_Bookmarks.groups
      [System.Windows.RoutedEventHandler]$synchash.Add_Bookmark_apply_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
          if(-not [string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Group_Textbox.text) -and $($synchash.Bookmark_Dialog_Group_Textbox.text) -match $illegalfile){
            write-ezlogs " | Cleaning Bookmark Group_Name due to illegal characters" -warning
            $synchash.Bookmark_Dialog_Group_Textbox.text = ([Regex]::Replace($synchash.Bookmark_Dialog_Group_Textbox.text, $illegalfile, '')).trim()   
          }
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_URL_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid URL!","I mean, shouldn't you realize you need to provide a URL when adding a bookmark?",$okandCancel,$Button_Settings)
            return
          }else{
            $Bookmark_encodedID = $Null  
            $Bookmark_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($synchash.Bookmark_Dialog_URL_Textbox.text)-$($synchash.Bookmark_Dialog_Group_Textbox.text)")
            $Bookmark_encodedID = [System.Convert]::ToBase64String($Bookmark_encodedBytes)
          }        
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Name_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Name!","You must provide a name to identify this bookmark",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Group_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Folder Name!","You must provide a folder name for grouping this bookmark",$okandCancel,$Button_Settings)
            return
          }
          if($synchash.All_Bookmarks.Bookmark_ID -contains $Bookmark_encodedID){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Bookmark Already Exists!","A bookmark with the same URL already exists!",$okandCancel,$Button_Settings)
            return
          }else{
            $synchash.BookmarkCustomDialog.RequestCloseAsync()
            $synchash.Webbrowser.Visibility = 'Visible'
            Add-Bookmarks -Name $synchash.Bookmark_Dialog_Name_Textbox.text -Group_Name $synchash.Bookmark_Dialog_Group_Textbox.text -Bookmark_URL $synchash.Bookmark_Dialog_URL_Textbox.text -thisApp $thisApp -synchash $synchash
          }
        }catch{
          write-ezlogs 'An exception occurred in Add_Bookmark_apply_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Edit_Bookmark_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
          if(-not [string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Group_Textbox.text) -and $($synchash.Bookmark_Dialog_Group_Textbox.text) -match $illegalfile){
            write-ezlogs " | Cleaning Bookmark Group_Name due to illegal characters" -warning
            $synchash.Bookmark_Dialog_Group_Textbox.text = ([Regex]::Replace($synchash.Bookmark_Dialog_Group_Textbox.text, $illegalfile, '')).trim()   
          }
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_URL_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid URL!","The URL for the bookmark is missing!",$okandCancel,$Button_Settings)
            return
          }        
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Name_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Name!","You must provide a name to identify this bookmark",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($synchash.Bookmark_Dialog_Group_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Folder Name!","You must provide a folder name for grouping this bookmark",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($sender.tag.Bookmark_ID) -or $synchash.All_Bookmarks.Bookmark_ID -notcontains $sender.tag.Bookmark_ID){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unknown Bookmark!","Unable to find bookmark with name ($($synchash.Bookmark_Dialog_Name_Textbox.text)) and ID: $($sender.tag.Bookmark_ID)",$okandCancel,$Button_Settings)
            return
          }else{
            $synchash.BookmarkCustomDialog.RequestCloseAsync()
            $synchash.Webbrowser.Visibility = 'Visible'
            Add-Bookmarks -synchash $synchash -thisApp $thisApp -Name $synchash.Bookmark_Dialog_Name_Textbox.text -Group_Name $synchash.Bookmark_Dialog_Group_Textbox.text -Bookmark_URL $synchash.Bookmark_Dialog_URL_Textbox.text -Bookmark_ID $sender.tag.Bookmark_ID -Update
          }
        }catch{
          write-ezlogs 'An exception occurred in Edit_Bookmark_Command event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Add_Bookmark_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $synchash.Webbrowser.Visibility = 'Collapsed'
          $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
          $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
          $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
          $synchash.BookmarkCustomDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window)
          [string]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\BookmarkDialog.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")          
          $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
          $synchash.BookmarkDialogWindow = [Windows.Markup.XAMLReader]::Parse($XAML)
          while ($reader.Read())
          {
            $name=$reader.GetAttribute('Name')
            if(!$name){ 
              $name=$reader.GetAttribute('x:Name')
            }
            if($name -and $synchash.BookmarkDialogWindow){
              $synchash."$($name)" = $synchash.BookmarkDialogWindow.FindName($name)
            }
          }
          $reader.Dispose()  
          $synchash.BookmarkCustomDialog.AddChild($synchash.BookmarkDialogWindow)
          $synchash.Bookmark_DialogButtonClose.add_click({
              try{                         
                $synchash.BookmarkCustomDialog.RequestCloseAsync()
                $synchash.Webbrowser.Visibility = 'Visible'
              }catch{
                write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
              }
          })
          if($sender.header -eq 'Edit' -and -not [string]::IsNullOrEmpty($sender.tag.Bookmark_ID)){
            $synchash.Bookmark_Dialog_Name_Textbox.text = $sender.tag.Bookmark_Name
            $synchash.Bookmark_Dialog_Group_Textbox.text = $sender.tag.Group_Name
            $synchash.Bookmark_Dialog_URL_Textbox.text = $sender.tag.Bookmark_URL
            $synchash.Bookmark_Dialog_Add_Button.tag = $sender.tag
            $synchash.Bookmark_Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Edit_Bookmark_Command) 
            $synchash.Bookmark_Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Edit_Bookmark_Command)
          }else{
            $synchash.Bookmark_Dialog_Name_Textbox.text = $null
            $synchash.Bookmark_Dialog_Group_Textbox.text = $null
            $synchash.Bookmark_Dialog_URL_Textbox.text = $null
            $synchash.Bookmark_Dialog_URL_Textbox.tag = $null
            $synchash.Bookmark_Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Bookmark_apply_Command) 
            $synchash.Bookmark_Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Bookmark_apply_Command)
          }  
          [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($synchash.Window, $synchash.BookmarkCustomDialog, $CustomDialog_Settings)
        }catch{
          write-ezlogs 'An exception occurred in Add_Bookmark_Command click event' -showtime -catcherror $_
          $synchash.Webbrowser.Visibility = 'Visible'
        }
      }
      $null = $synchash.New_Bookmark_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Bookmark_Command)

      $synchash.Navigate_Bookmark_Scriptblock = {
        param($sender)
        try{
          $e = $args[1]
          $synchash = $synchash
          write-ezlogs "OriginalSource: $($_.OriginalSource.DataContext | out-string)" -Dev_mode
          if($_.OriginalSource.DataContext.Type -eq 'Bookmark' -and (Test-ValidPath -path $_.OriginalSource.DataContext.Bookmark_URL -Type URL)){
            Start-WebNavigation -uri $_.OriginalSource.DataContext.Bookmark_URL -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp
          }else{
            write-ezlogs "Invalid bookmark or URL selected: $($_.OriginalSource.DataContext | out-string)" -warning
          }        
        }catch{
          write-ezlogs 'An exception occurred in Navigate_Bookmark_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Navigate_Bookmark_Command = $synchash.Navigate_Bookmark_Scriptblock
      $DataTemplate = [System.Windows.DataTemplate]::new()
      $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('TreeViewButtonStyle') )
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ToolTipProperty, 'Navigate')
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, [System.Windows.Data.Binding]::new('Bookmark_Name'))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty, [System.Windows.Data.Binding]::new('Bookmark_ID'))
      $Null = $buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Navigate_Bookmark_Command)
      $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Navigate_Bookmark_Command)
      $dataTemplate.VisualTree = $buttonFactory
      $synchash.Bookmarks_TreeView.ItemTemplate.ItemTemplate = $dataTemplate
      [System.Windows.RoutedEventHandler]$synchash.Add_CurrentPageBookmark_Command = {
        param($sender)
        try{
          $synchash = $synchash
          if(-not [string]::IsNullOrEmpty($synchash.WebBrowser.CoreWebView2.Source) -and $synchash.WebBrowser.CoreWebView2.Source -match 'https\:'){
            Add-Bookmarks -Name $synchash.WebBrowser.CoreWebView2.DocumentTitle -Group_Name 'Favorites' -Bookmark_URL $synchash.WebBrowser.CoreWebView2.Source -thisApp $thisApp -synchash $synchash
          }else{
            write-ezlogs "No valid web browser url found $($synchash.WebBrowser.CoreWebView2)" -warning
          }        
        }catch{
          write-ezlogs 'An exception occurred in Add_CurrentPageBookmark_Command click event' -showtime -catcherror $_
          $synchash.Webbrowser.Visibility = 'Visible'
        }
      }
      $null = $synchash.BookmarkCurrentPage.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_CurrentPageBookmark_Command)

      [System.Windows.RoutedEventHandler]$Synchash.Remove_BookMark_Command = {
        param($sender)
        try{
          $synchash = $synchash
          if(-not [string]::IsNullOrEmpty($sender.tag.Bookmark_ID) -and $synchash.All_Bookmarks.Bookmark_ID -contains $sender.tag.Bookmark_ID){
            Remove-Bookmarks -synchash $synchash -thisApp $thisApp -Bookmark_ID $sender.tag.Bookmark_ID -RemoveFromAllGroups
          }else{
            write-ezlogs "No valid Bookmark was found with id: $($sender.tag.Bookmark_ID)" -warning
          }        
        }catch{
          write-ezlogs 'An exception occurred in Remove_BookMark_Commandt' -showtime -catcherror $_
          $synchash.Webbrowser.Visibility = 'Visible'
        }
      }

      [System.Windows.RoutedEventHandler]$synchash.Bookmark_ContextMenu = {
        $sender = $args[0]
        [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]  
        $Bookmark = $e.OriginalSource.TemplatedParent.parent.datacontext
        write-ezlogs "Bookmark $($Bookmark | out-string)" -Dev_mode
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and $Bookmark.Type -eq 'Bookmark'){
          $items = [System.Collections.Generic.List[Object]]::new()
          $Edit = @{
            'Header' = 'Edit'
            'Color' = 'White'
            'Command' = $synchash.Add_Bookmark_Command
            'Icon_Color' = 'White'
            'Icon_kind' = 'FileDocumentEditOutline'
            'Tag' = $Bookmark
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Edit)
          $separator = @{
            'Separator' = $true
            'Style' = 'SeparatorGradient'
          }            
          $null = $items.Add($separator) 
          $Remove = @{
            'Header' = 'Delete'
            'Color' = 'White'
            'Command' = $Synchash.Remove_BookMark_Command
            'Tag' = $Bookmark
            'Icon_Color' = 'White'
            'Icon_kind' = 'TrashCanOutline'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Remove)
          Add-WPFMenu -control $e.OriginalSource -items $items -AddContextMenu -sourceWindow $synchash         
        }
      }
      $Null = $synchash.Bookmarks_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Bookmark_ContextMenu)
    }
    $Get_Bookmarks_Measure.stop()
    write-ezlogs "Get-Bookmarks measure" -Perf -PerfTimer $Get_Bookmarks_Measure
    $Get_Bookmarks_Measure = $Null  
  }catch{
    write-ezlogs "An exception occurred in Get-Bookmarks" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-Bookmarks Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-Bookmarks Function
#----------------------------------------------
function Update-Bookmarks
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$Remove,
    [switch]$UpdateHistory,
    [switch]$Use_RunSpace,
    $ID,
    $synchash,
    $thisApp,
    [switch]$VerboseLog
  )
 
  try{
    $Update_PlayQueue_ScriptBlock ={
      param
      (
        $thisApp = $thisApp,
        $synchash = $synchas,
        $id = $id,
        $UpdateHistory = $UpdateHistory,
        $Remove = $Remove,
        $Clear = $Clear
      )
      try{
        if($Remove -and $thisApp.config.Current_Playlist.values -contains $id){
          try{
            $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $id} | select * -ExpandProperty key 
            if(($index_toremove).count -gt 1){
              write-ezlogs " | Found multiple items in Play Queue matching id $($id) - $($index_toremove | out-string)" -showtime -warning -LogLevel 2
              foreach($index in $index_toremove){
                $null = $thisApp.config.Current_Playlist.Remove($index) 
              }  
            }else{
              write-ezlogs " | Removing $($id) from Play Queue" -showtime -LogLevel 2
              $null = $thisApp.config.Current_Playlist.Remove($index_toremove)
            }                              
          }catch{
            write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
          }                          
        }
        if($UpdateHistory){ 
          #Update History Playlist
          if($thisApp.config.History_Playlist){
            if(($thisApp.config.History_Playlist.GetType()).name -notmatch 'OrderedDictionary'){
              if($thisApp.Config.Verbose_logging){write-ezlogs "History_Playlist not orderedictionary $(($thisApp.config.History_Playlist.GetType()).name) - converting"  -showtime -warning}
              $thisApp.config.History_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.History_Playlist)
            } 
          }else{
            Add-Member -InputObject $thisApp.config -Name 'History_Playlist' -Value ([System.Collections.Specialized.OrderedDictionary]::new()) -MemberType NoteProperty -Force 
          }           
          if($thisApp.config.History_Playlist.values -notcontains $id){
            $historycount = ($thisApp.config.History_Playlist.keys | measure -Maximum).Count
            if($historycount -ge 10){
              write-ezlogs " | History playlist at over maximum clearing all history" -LogLevel 2 -warning
              $null = $thisApp.config.History_Playlist.clear()
            }elseif($historycount -ge 5){
              $historyindex_toremove = $thisapp.config.History_Playlist.GetEnumerator() | select -last 1
              write-ezlogs " | History playlist at maximum, dropping oldest index $($historyindex_toremove.value)" -LogLevel 2
              $null = $thisapp.config.History_Playlist.Remove($historyindex_toremove.key) 
            }
            $historyindex = ($thisApp.config.History_Playlist.keys | measure -Maximum).Maximum
            $historyindex++
            write-ezlogs " | Adding $($id) to Play history" -showtime
            $null = $thisApp.config.History_Playlist.add($historyindex,$id)              
          } 
        }
        Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
        #Export-Clixml -InputObject $thisapp.config -path $thisapp.Config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred in Update_PlayQueue_ScriptBlock" -catcherror $_
      }
    }
    if($use_Runspace){
      $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"} 
      Start-Runspace -scriptblock $Update_PlayQueue_ScriptBlock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Update_PlayQueue_RUNSPACE' -thisApp $thisApp -synchash $synchash
      Remove-Variable Variable_list
    }else{
      Invoke-Command -ScriptBlock $Update_PlayQueue_ScriptBlock
      Remove-Variable Update_PlayQueue_ScriptBlock
    }  
  }catch{
    write-ezlogs "An exception occurred in Update-Bookmarks" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Update-Bookmarks Function
#----------------------------------------------

#---------------------------------------------- 
#region Bookmarks Function
#----------------------------------------------
function Add-Bookmarks
{
  Param (
    $Name,
    $Group_Name,
    $Bookmark_URL,
    $thisApp,
    $Bookmarks_File_Path,
    $synchash,
    [string]$Bookmark_ID,
    [Switch]$Update,
    [switch]$Update_UI,
    [switch]$Startup,
    [switch]$GroupOnly,
    [string]$Bookmarks_Profile_Directory = $thisApp.config.Bookmarks_Profile_Directory,
    [switch]$Verboselog
  )
  write-ezlogs "#### Adding/Updating Bookmarks $Name ####" -linesbefore 1 -loglevel 2
  $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
  $illegalpath= "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars()))]"

  if($Group_Name -match $illegalfile){
    write-ezlogs " | Cleaning Bookmark Group_Name due to illegal characters" -warning
    $Group_Name = ([Regex]::Replace($Group_Name, $illegalfile, '')).trim()   
  }
  $Bookmarks_Cache_profile = "$($thisApp.config.Bookmarks_Profile_Directory)\All-Bookmarks-Cache.xml"
  if(![System.IO.File]::Exists($thisApp.config.Bookmarks_Profile_Directory)){
    $Null = New-Item -Path $thisApp.config.Bookmarks_Profile_Directory -ItemType directory -Force
  }
  if($Update -and $synchash.All_Bookmarks.Bookmark_ID -contains $Bookmark_ID){
    write-ezlogs ">>>> Updating existing bookmark $($Name) with ID $($Bookmark_ID)"
    $Bookmarks_Profile = $synchash.All_Bookmarks | where {$_.Bookmark_ID -eq $Bookmark_ID}
    $Bookmark_encodedID = $Null  
    $Bookmark_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$Bookmark_URL-$Group_Name")
    $Bookmark_encodedID = [System.Convert]::ToBase64String($Bookmark_encodedBytes)  
    $Bookmarks_Profile.Group_Name = $Group_Name
    $Bookmarks_Profile.Bookmark_Name = $Name
    $Bookmarks_Profile.Bookmark_ID = $Bookmark_encodedID
    $Bookmarks_Profile.Bookmark_URL = $Bookmark_URL
    $Bookmarks_Profile.Bookmarks_File_Path = $Bookmarks_Cache_profile
    if(-not [string]::IsNullOrEmpty($Bookmarks_Profile.Group_Name)){
      $Bookmarks_Profile.IsGrouped = $true
    }
    $Bookmarks_Profile.Bookmark_Date_Added = [DateTime]::Now
    write-ezlogs " | New Bookmark ID: $($Bookmark_encodedID)"
    $Null = $synchash.All_Bookmarks.CommitEdit()
  }else{
    $Bookmarks_Profile = Import-Clixml "$($thisApp.Config.Current_Folder)\Resources\Templates\Bookmarks_Template.xml"
    $Bookmark_encodedID = $Null  
    $Bookmark_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$Bookmark_URL-$Group_Name")
    $Bookmark_encodedID = [System.Convert]::ToBase64String($Bookmark_encodedBytes)  
    $Bookmarks_Profile.Group_Name = $Group_Name
    $Bookmarks_Profile.Bookmark_Name = $Name
    $Bookmarks_Profile.Bookmark_ID = $Bookmark_encodedID
    $Bookmarks_Profile.Bookmark_URL = $Bookmark_URL
    $Bookmarks_Profile.Bookmarks_File_Path = $Bookmarks_Cache_profile
    if(-not [string]::IsNullOrEmpty($Bookmarks_Profile.Group_Name)){
      $Bookmarks_Profile.IsGrouped = $true
    }
    $Bookmarks_Profile.Bookmark_Date_Added = [DateTime]::Now
    if($synchash.All_Bookmarks.CanAddNewItem){
      if($synchash.All_Bookmarks.Bookmark_ID -notcontains $Bookmark_encodedID){
        write-ezlogs ">>>> Adding new bookmark $($Name) with ID $($Bookmark_encodedID)" -loglevel 2
        $null = $synchash.All_Bookmarks.AddNewItem($Bookmarks_Profile)
      }else{
        write-ezlogs "A bookmark with name ($($Name)) and ID ($($Bookmark_encodedID)) already exists, updating existing" -warning -loglevel 2
        $existingProfile = $synchash.All_Bookmarks | where {$_.Bookmark_ID -eq $Bookmark_encodedID}
        $existingProfile.Group_Name = $Group_Name
        $existingProfile.Bookmark_Name = $Name
        $existingProfile.Bookmark_ID = $Bookmark_encodedID
        $existingProfile.Bookmark_URL = $Bookmark_URL
        $existingProfile.Bookmarks_File_Path = $Bookmarks_Cache_profile
        $Null = $synchash.All_Bookmarks.CommitEdit()
      } 
    }else{
      write-ezlogs "Unable to add new item to Bookmarks collection view " -warning -loglevel 2
    }
    $Null = $synchash.All_Bookmarks.CommitNew() 
  }
  $synchash.All_Bookmarks.Refresh()
  Export-Clixml -InputObject @($synchash.All_Bookmarks) -Path $Bookmarks_Cache_profile -Force -Encoding Default
}
#---------------------------------------------- 
#endregion Add-Bookmarks Function
#----------------------------------------------

#---------------------------------------------- 
#region Remove-Bookmarks Function
#----------------------------------------------
function Remove-Bookmarks
{
  Param (
    $Name,
    $Group_Name,
    $Bookmark_URL,
    $Bookmark_ID,
    $thisApp,
    $Bookmarks_File_Path,
    $synchash,
    [switch]$Update_UI,
    [switch]$Startup,
    [switch]$RemoveFromAllGroups,
    [string]$Bookmarks_Profile_Directory = $thisApp.config.Bookmarks_Profile_Directory,
    [switch]$Verboselog
  )
  $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
  $illegalpath= "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars()))]"
  if($Group_Name -match $illegalfile){
    write-ezlogs " | Cleaning Bookmark Group_Name due to illegal characters" -warning
    $Group_Name = ([Regex]::Replace($Group_Name, $illegalfile, '')).trim()   
  }
  $Bookmarks_Cache_profile = "$($thisApp.config.Bookmarks_Profile_Directory)\All-Bookmarks-Cache.xml"
  if(![System.IO.File]::Exists($thisApp.config.Bookmarks_Profile_Directory)){
    $Null = New-Item -Path $thisApp.config.Bookmarks_Profile_Directory -ItemType directory -Force
  }
  if($Group_Name){
    $BookmarksToRemove = $synchash.All_Bookmarks | where {$_.Group_name -eq $Group_Name}
  }else{
    $BookmarksToRemove = $synchash.All_Bookmarks | where {$_.Bookmark_ID -eq $Bookmark_ID}
  } 
  if($synchash.All_Bookmarks.CanRemove){
    if($RemoveFromAllGroups){
      $BookmarksToRemove = $synchash.All_Bookmarks | where {$_.Bookmark_URL -in $BookmarksToRemove.Bookmark_URL}
    }
    foreach($Bookmark in $BookmarksToRemove){
      if($synchash.All_Bookmarks.Bookmark_ID -contains $Bookmark.Bookmark_ID){
        write-ezlogs ">>>> Removing bookmark $($Bookmark.Bookmark_Name) in group $($Bookmark.Group_Name) with ID $($Bookmark.Bookmark_ID)" -loglevel 2
        $null = $synchash.All_Bookmarks.Remove($Bookmark)
      }else{
        write-ezlogs "A bookmark with name $($Bookmark.Bookmark_Name) in group $($Bookmark.Group_Name) with ID $($Bookmark.Bookmark_ID) was not found" -warning -loglevel 2
      }
    }
    $Null = $synchash.All_Bookmarks.CommitEdit()
    if($synchash.All_Bookmarks.NeedsRefresh){
      $synchash.All_Bookmarks.Refresh()
    }
    Export-Clixml -InputObject @($synchash.All_Bookmarks) -Path $Bookmarks_Cache_profile -Force -Encoding Default 
  }else{
    write-ezlogs "Unable to remove items from Bookmarks collection view " -warning -loglevel 2
  }
}
#---------------------------------------------- 
#endregion Remove-Bookmarks Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Bookmarks','Update-Bookmarks','Add-Bookmarks','Remove-Bookmarks')