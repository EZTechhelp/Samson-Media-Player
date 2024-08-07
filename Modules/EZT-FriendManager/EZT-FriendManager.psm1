<#
    .Name
    EZT-FriendManager

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of functions used to manage lists of unique friend objects and display them in a WPF UI

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
#region Get-Friends Function
#----------------------------------------------
function Get-Friends
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
    [switch]$Import_Friends_Cache = $true
  )
  try{
    if($Import_Friends_Cache){   
      try{
        if(([System.IO.File]::Exists("$($thisApp.config.Friends_Profile_Directory)\All-Friends-Cache.xml"))){
          $synchash.All_Friends = [System.Windows.Data.CollectionViewSource]::GetDefaultView((Import-Clixml "$($thisApp.config.Friends_Profile_Directory)\All-Friends-Cache.xml"))
        }else{
          $synchash.All_Friends = [System.Windows.Data.CollectionViewSource]::GetDefaultView([System.Collections.Generic.List[Object]]::new())
        } 
      }catch{
        write-ezlogs "An exception occurred importing Friends cache" -showtime -catcherror $_
      }
    } 
    $synchash.All_Friend_Groups = $synchash.All_Friends.Group_Name | select -Unique | sort
    $groupdescription = [System.Windows.Data.PropertyGroupDescription]::new()
    $groupdescription.PropertyName = 'Group_Name'
    $Null = $synchash.All_Friends.GroupDescriptions.Add($groupdescription)
    if($synchash.Friends_TreeView){
      $synchash.Friends_TreeView.Itemssource = $synchash.All_Friends
      [System.Windows.RoutedEventHandler]$synchash.Add_Friend_apply_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
          if(-not [string]::IsNullOrEmpty($synchash.Friend_Dialog_Group_Textbox.text) -and $($synchash.Friend_Dialog_Group_Textbox.text) -match $illegalfile){
            write-ezlogs " | Cleaning Friend Group_Name due to illegal characters" -warning
            $synchash.Friend_Dialog_Group_Textbox.text = ([Regex]::Replace($synchash.Friend_Dialog_Group_Textbox.text, $illegalfile, '')).trim()   
          }
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_URL_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Friend URL!","You need to provide a Friend URL",$okandCancel,$Button_Settings)
            return
          }else{
            $Friend_encodedID = $Null  
            $Friend_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($synchash.Friend_Dialog_URL_Textbox.text)-$($synchash.Friend_Dialog_Group_Textbox.text)")
            $Friend_encodedID = [System.Convert]::ToBase64String($Friend_encodedBytes)
          }        
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_Name_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Name!","You must provide a name to identify this Friend",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_Group_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Folder Name!","You must provide a folder name for grouping this Friend",$okandCancel,$Button_Settings)
            return
          }
          if($synchash.All_Friends.Friend_ID -contains $Friend_encodedID){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Friend Already Exists!","A Friend with the same URL already exists!",$okandCancel,$Button_Settings)
            return
          }else{
            $synchash.FriendCustomDialog.RequestCloseAsync()
            Add-Friends -Name $synchash.Friend_Dialog_Name_Textbox.text -Group_Name $synchash.Friend_Dialog_Group_Textbox.text -Friend_URL $synchash.Friend_Dialog_URL_Textbox.text -thisApp $thisApp -synchash $synchash
          }
        }catch{
          write-ezlogs 'An exception occurred in Add_Friend_apply_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Edit_Friend_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
          if(-not [string]::IsNullOrEmpty($synchash.Friend_Dialog_Group_Textbox.text) -and $($synchash.Friend_Dialog_Group_Textbox.text) -match $illegalfile){
            write-ezlogs " | Cleaning Friend Group_Name due to illegal characters" -warning
            $synchash.Friend_Dialog_Group_Textbox.text = ([Regex]::Replace($synchash.Friend_Dialog_Group_Textbox.text, $illegalfile, '')).trim()   
          }
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_URL_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid URL!","The URL for the Friend is missing!",$okandCancel,$Button_Settings)
            return
          }        
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_Name_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Name!","You must provide a name to identify this Friend",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($synchash.Friend_Dialog_Group_Textbox.text)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Folder Name!","You must provide a folder name for grouping this Friend",$okandCancel,$Button_Settings)
            return
          }
          if([string]::IsNullOrEmpty($sender.tag.Friend_ID) -or $synchash.All_Friends.Friend_ID -notcontains $sender.tag.Friend_ID){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unknown Friend!","Unable to find Friend with name ($($synchash.Friend_Dialog_Name_Textbox.text)) and ID: $($sender.tag.Friend_ID)",$okandCancel,$Button_Settings)
            return
          }else{
            $synchash.FriendCustomDialog.RequestCloseAsync()
            Add-Friends -synchash $synchash -thisApp $thisApp -Name $synchash.Friend_Dialog_Name_Textbox.text -Group_Name $synchash.Friend_Dialog_Group_Textbox.text -Friend_URL $synchash.Friend_Dialog_URL_Textbox.text -Friend_ID $sender.tag.Friend_ID -Update
          }
        }catch{
          write-ezlogs 'An exception occurred in Edit_Friend_Command event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Add_Friend_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $synchash.Webbrowser.Visibility = 'Collapsed'
          $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
          $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
          $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
          $synchash.FriendCustomDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window)
          [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\FriendDialog.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
          $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
          $synchash.FriendDialogWindow = [Windows.Markup.XamlReader]::Load($reader)
          $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$synchash."$($_.Name)" = $synchash.FriendDialogWindow.FindName($_.Name)}    
          $synchash.FriendCustomDialog.AddChild($synchash.FriendDialogWindow)
          $synchash.Friend_DialogButtonClose.add_click({
              try{                         
                $synchash.FriendCustomDialog.RequestCloseAsync()
              }catch{
                write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
              }
          })
          if($sender.header -eq 'Edit' -and -not [string]::IsNullOrEmpty($sender.tag.Friend_ID)){
            $synchash.Friend_Dialog_Name_Textbox.text = $sender.tag.Friend_Name
            $synchash.Friend_Dialog_Group_Textbox.text = $sender.tag.Group_Name
            $synchash.Friend_Dialog_URL_Textbox.text = $sender.tag.Friend_URL
            $synchash.Friend_Dialog_Add_Button.tag = $sender.tag
            $synchash.Friend_Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Edit_Friend_Command) 
            $synchash.Friend_Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Edit_Friend_Command)
          }else{
            $synchash.Friend_Dialog_Name_Textbox.text = $null
            $synchash.Friend_Dialog_Group_Textbox.text = $null
            $synchash.Friend_Dialog_URL_Textbox.text = $null
            $synchash.Friend_Dialog_URL_Textbox.tag = $null
            $synchash.Friend_Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Friend_apply_Command) 
            $synchash.Friend_Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Friend_apply_Command)
          }  
          [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($synchash.Window, $synchash.FriendCustomDialog, $CustomDialog_Settings)
        }catch{
          write-ezlogs 'An exception occurred in Add_Friend_Command click event' -showtime -catcherror $_
        }
      }
      $null = $synchash.New_Friend_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Friend_Command)

      $synchash.Navigate_Friend_Scriptblock = {
        param($sender)
        try{
          $e = $args[1]
          $synchash = $synchash
          write-ezlogs "OriginalSource: $($_.OriginalSource.DataContext | out-string)" -Dev_mode
          if($_.OriginalSource.DataContext.Type -eq 'Friend' -and $_.OriginalSource.DataContext.Friend_URL){
            write-ezlogs "[NOT_IMPLEMENTED] NEED TO DO SOMETHING WHEN CLICKING ON A FRIEND" -AlertUI -warning
            #Start-WebNavigation -uri $_.OriginalSource.DataContext.Friend_URL -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp
          }else{
            write-ezlogs "Invalid Friend or URL selected: $($_.OriginalSource.DataContext | out-string)" -warning
          }        
        }catch{
          write-ezlogs 'An exception occurred in Navigate_Friend_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$synchash.Navigate_Friend_Command = $synchash.Navigate_Friend_Scriptblock
      $DataTemplate = [System.Windows.DataTemplate]::new()
      $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('TreeViewButtonStyle') )
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ToolTipProperty, 'Navigate')
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, [System.Windows.Data.Binding]::new('Friend_Name'))
      $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty, [System.Windows.Data.Binding]::new('Friend_ID'))
      $Null = $buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Navigate_Friend_Command)
      $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Navigate_Friend_Command)
      $dataTemplate.VisualTree = $buttonFactory
      if($synchash.Friends_TreeView.ItemTemplate.ItemTemplate){
        $synchash.Friends_TreeView.ItemTemplate.ItemTemplate = $dataTemplate
      }
      [System.Windows.RoutedEventHandler]$Synchash.Remove_Friend_Command = {
        param($sender)
        try{
          $synchash = $synchash
          if(-not [string]::IsNullOrEmpty($sender.tag.Friend_ID) -and $synchash.All_Friends.Friend_ID -contains $sender.tag.Friend_ID){
            Remove-Friends -synchash $synchash -thisApp $thisApp -Friend_ID $sender.tag.Friend_ID -RemoveFromAllGroups
          }else{
            write-ezlogs "No valid Friend was found with id: $($sender.tag.Friend_ID)" -warning
          }        
        }catch{
          write-ezlogs 'An exception occurred in Remove_Friend_Commandt' -showtime -catcherror $_
          $synchash.Webbrowser.Visibility = 'Visible'
        }
      }

      [System.Windows.RoutedEventHandler]$synchash.Friend_ContextMenu = {
        $sender = $args[0]
        [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]  
        $Friend = $e.OriginalSource.TemplatedParent.parent.datacontext
        write-ezlogs "Friend $($Friend | out-string)" -Dev_mode
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and $Friend.Type -eq 'Friend'){
          $items = [System.Collections.Generic.List[Object]]::new()
          $Edit = @{
            'Header' = 'Edit'
            'Color' = 'White'
            'Command' = $synchash.Add_Friend_Command
            'Icon_Color' = 'White'
            'Icon_kind' = 'FileDocumentEditOutline'
            'Tag' = $Friend
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
            'Command' = $Synchash.Remove_Friend_Command
            'Tag' = $Friend
            'IconPack' = 'PackIconForkAwesome'
            'Icon_Color' = 'White'
            'Icon_kind' = 'Trash'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          $null = $items.Add($Remove)
          Add-WPFMenu -control $e.OriginalSource -items $items -AddContextMenu -sourceWindow $synchash         
        }
      }
      $Null = $synchash.Friends_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Friend_ContextMenu)


      #$null = $synchash.Window.CommandBindings.Add($commandBinding)
      #write-ezlogs "Friends_TreeView.ItemTemplate: $($synchash.Friends_TreeView.ItemTemplate | out-string)" -Dev_mode
      #write-ezlogs "Friends_TreeView.ItemTemplate.ItemsSource: $($synchash.Friends_TreeView.ItemTemplate.ItemsSource | out-string)" -Dev_mode
      #write-ezlogs "Friends_TreeView.ItemTemplate.ItemsSource.Path: $($synchash.Friends_TreeView.ItemTemplate.ItemsSource.Path | out-string)" -Dev_mode    
      #write-ezlogs "Friends_TreeView.ItemTemplate.ItemTemplate: $($synchash.Friends_TreeView.ItemTemplate.ItemTemplate | out-string)" -Dev_mode
      #write-ezlogs "Friends_TreeView.ItemTemplate.ItemTemplate.VisualTree: $($synchash.Friends_TreeView.ItemTemplate.ItemTemplate)" -Dev_mode
      #$null = $synchash.Window.resources.add($routedcommand,'TreeItemClickCommand')  
      
      #$null = $synchash.Window.resources.add($routedcommand,'TreeItemClickCommand') 
      #$resources = $synchash.Window.TryFindResource('TreeItemClickCommand')
      #write-ezlogs "resources after: $($resources | out-string)" -Dev_mode
      #write-ezlogs "resources after: $($synchash.Window.resources | out-string)" -Dev_mode
      #
      #$null = $synchash.Friends_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.Navigate_Friend_Command)
    } 
  }catch{
    write-ezlogs "An exception occurred in Get-Friends" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-Friends Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-Friends Function
#----------------------------------------------
function Update-Friends
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
    write-ezlogs "An exception occurred in Update-Friends" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Update-Friends Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-Friends Function
#----------------------------------------------
function Add-Friends
{
  Param (
    $Name,
    $Group_Name,
    $Friend_URL,
    $thisApp,
    $Friends_File_Path,
    $synchash,
    [string]$Friend_ID,
    [Switch]$Update,
    [switch]$Update_UI,
    [switch]$Startup,
    [switch]$GroupOnly,
    [string]$Friends_Profile_Directory = $thisApp.config.Friends_Profile_Directory,
    [switch]$Verboselog
  )
  write-ezlogs "#### Adding/Updating Friends $Name ####" -linesbefore 1 -loglevel 2
  $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
  $illegalpath= "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars()))]"

  if($Group_Name -match $illegalfile){
    write-ezlogs " | Cleaning Friend Group_Name due to illegal characters" -warning
    $Group_Name = ([Regex]::Replace($Group_Name, $illegalfile, '')).trim()   
  }
  $Friends_Cache_profile = "$($thisApp.config.Friends_Profile_Directory)\All-Friends-Cache.xml"
  if(![System.IO.File]::Exists($thisApp.config.Friends_Profile_Directory)){
    $Null = New-Item -Path $thisApp.config.Friends_Profile_Directory -ItemType directory -Force
  }
  if($Update -and $synchash.All_Friends.Friend_ID -contains $Friend_ID){
    write-ezlogs ">>>> Updating existing Friend $($Name) with ID $($Friend_ID)"
    $Friends_Profile = $synchash.All_Friends | where {$_.Friend_ID -eq $Friend_ID}
    $Friend_encodedID = $Null  
    $Friend_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$Friend_URL-$Group_Name")
    $Friend_encodedID = [System.Convert]::ToBase64String($Friend_encodedBytes)  
    $Friends_Profile.Group_Name = $Group_Name
    $Friends_Profile.Friend_Name = $Name
    $Friends_Profile.Friend_ID = $Friend_encodedID
    $Friends_Profile.Friend_URL = $Friend_URL
    $Friends_Profile.Friends_File_Path = $Friends_Cache_profile
    if(-not [string]::IsNullOrEmpty($Friends_Profile.Group_Name)){
      $Friends_Profile.IsGrouped = $true
    }
    $Friends_Profile.Friend_Date_Added = [DateTime]::Now
    write-ezlogs " | New Friend ID: $($Friend_encodedID)"
    $Null = $synchash.All_Friends.CommitEdit()
  }else{
    $Friends_Profile = Import-Clixml "$($thisApp.Config.Current_Folder)\Resources\Templates\Friends_Template.xml"
    $Friend_encodedID = $Null  
    $Friend_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$Friend_URL-$Group_Name")
    $Friend_encodedID = [System.Convert]::ToBase64String($Friend_encodedBytes)  
    $Friends_Profile.Group_Name = $Group_Name
    $Friends_Profile.Friend_Name = $Name
    $Friends_Profile.Friend_ID = $Friend_encodedID
    $Friends_Profile.Friend_URL = $Friend_URL
    $Friends_Profile.Friends_File_Path = $Friends_Cache_profile
    if(-not [string]::IsNullOrEmpty($Friends_Profile.Group_Name)){
      $Friends_Profile.IsGrouped = $true
    }
    $Friends_Profile.Friend_Date_Added = [DateTime]::Now
    if($synchash.All_Friends.CanAddNewItem){
      if($synchash.All_Friends.Friend_ID -notcontains $Friend_encodedID){
        write-ezlogs ">>>> Adding new Friend $($Name) with ID $($Friend_encodedID)" -loglevel 2
        $null = $synchash.All_Friends.AddNewItem($Friends_Profile)
      }else{
        write-ezlogs "A Friend with name ($($Name)) and ID ($($Friend_encodedID)) already exists, updating existing" -warning -loglevel 2
        $existingProfile = $synchash.All_Friends | where {$_.Friend_ID -eq $Friend_encodedID}
        $existingProfile.Group_Name = $Group_Name
        $existingProfile.Friend_Name = $Name
        $existingProfile.Friend_ID = $Friend_encodedID
        $existingProfile.Friend_URL = $Friend_URL
        $existingProfile.Friends_File_Path = $Friends_Cache_profile
        $Null = $synchash.All_Friends.CommitEdit()
      } 
    }else{
      write-ezlogs "Unable to add new item to Friends collection view " -warning -loglevel 2
    }
    $Null = $synchash.All_Friends.CommitNew() 
  }
  $synchash.All_Friends.Refresh()
  Export-Clixml -InputObject @($synchash.All_Friends) -Path $Friends_Cache_profile -Force -Encoding Default
}
#---------------------------------------------- 
#endregion Add-Friends Function
#----------------------------------------------

#---------------------------------------------- 
#region Remove-Friends Function
#----------------------------------------------
function Remove-Friends
{
  Param (
    $Name,
    $Group_Name,
    $Friend_URL,
    $Friend_ID,
    $thisApp,
    $Friends_File_Path,
    $synchash,
    [switch]$Update_UI,
    [switch]$Startup,
    [switch]$RemoveFromAllGroups,
    [string]$Friends_Profile_Directory = $thisApp.config.Friends_Profile_Directory,
    [switch]$Verboselog
  )
  $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
  $illegalpath= "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars()))]"
  if($Group_Name -match $illegalfile){
    write-ezlogs " | Cleaning Friend Group_Name due to illegal characters" -warning
    $Group_Name = ([Regex]::Replace($Group_Name, $illegalfile, '')).trim()   
  }
  $Friends_Cache_profile = "$($thisApp.config.Friends_Profile_Directory)\All-Friends-Cache.xml"
  if(![System.IO.File]::Exists($thisApp.config.Friends_Profile_Directory)){
    $Null = New-Item -Path $thisApp.config.Friends_Profile_Directory -ItemType directory -Force
  }
  if($Group_Name){
    $FriendsToRemove = $synchash.All_Friends | where {$_.Group_name -eq $Group_Name}
  }else{
    $FriendsToRemove = $synchash.All_Friends | where {$_.Friend_ID -eq $Friend_ID}
  } 
  if($synchash.All_Friends.CanRemove){
    if($RemoveFromAllGroups){
      $FriendsToRemove = $synchash.All_Friends | where {$_.Friend_URL -in $FriendsToRemove.Friend_URL}
    }
    foreach($Friend in $FriendsToRemove){
      if($synchash.All_Friends.Friend_ID -contains $Friend.Friend_ID){
        write-ezlogs ">>>> Removing Friend $($Friend.Friend_Name) in group $($Friend.Group_Name) with ID $($Friend.Friend_ID)" -loglevel 2
        $null = $synchash.All_Friends.Remove($Friend)
      }else{
        write-ezlogs "A Friend with name $($Friend.Friend_Name) in group $($Friend.Group_Name) with ID $($Friend.Friend_ID) was not found" -warning -loglevel 2
      }
    }
    $Null = $synchash.All_Friends.CommitEdit()
    if($synchash.All_Friends.NeedsRefresh){
      $synchash.All_Friends.Refresh()
    }
    Export-Clixml -InputObject @($synchash.All_Friends) -Path $Friends_Cache_profile -Force -Encoding Default 
  }else{
    write-ezlogs "Unable to remove items from Friends collection view " -warning -loglevel 2
  }
}
#---------------------------------------------- 
#endregion Remove-Friends Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Friends','Update-Friends','Add-Friends','Remove-Friends')