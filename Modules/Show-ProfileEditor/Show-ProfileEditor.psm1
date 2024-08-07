<#
    .Name
    Show-ProfileEditor 

    .Version 
    0.1.0

    .SYNOPSIS
    Displays a window for editing game profiles  

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
    #TODO: Requires either complete rewrite or heavy refactor
#>
Add-Type -AssemblyName WindowsFormsIntegration


#---------------------------------------------- 
#region Close-ProfileEditor Function
#----------------------------------------------
function Close-ProfileEditor (){
  $hashedit.window.Dispatcher.Invoke("Normal",[action]{ $hashedit.window.close() })
    
}
#---------------------------------------------- 
#endregion Close-ProfileEditor Function
#----------------------------------------------


#---------------------------------------------- 
#region Show-ProfileEditor Function
#----------------------------------------------
function Show-ProfileEditor{
  Param (
    [string]$PageTitle,
    [string]$Logo,
    $synchash,
    $thisApp,
    $Media_to_edit,
    [switch]$Verboselog
  ) 
  $hashedit = [hashtable]::Synchronized(@{})
  $hashedit_Scriptblock = {
    Param (
      [string]$PageTitle = $PageTitle,
      [string]$Logo = $Logo,
      $synchash = $synchash,
      $thisApp = $thisApp,
      $Media_to_edit = $Media_to_edit,
      [switch]$Verboselog = $Verboselog
    )
    $hashedit = $hashedit
    $Current_Folder = $thisApp.Config.Current_Folder
    if($VerboseLog){write-ezlogs ">>>> Loading Profile Editor: $($Current_Folder)\Views\ProfileEditor.xaml" -showtime -VerboseDebug:$VerboseLog}  
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
    $pattern = "[™$illegal]"
    #$pattern2 = "[:$illegal]"
    #$pattern3 = "[`?�™$illegal]"
    $Nav_Window_XML = "$($Current_Folder)\Views\ProfileEditor.xaml"   
    #Initialize UI
    try{
      #theme
      $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
      $themes = $theme.GetLibraryThemes()
      $themeManager = [ControlzEx.Theming.ThemeManager]::new()
      if($synchash.Window){
        $detectTheme = $thememanager.DetectTheme($synchash.Window)
        $newtheme = $themes | Where-Object {$_.Name -eq $detectTheme.Name}
      }elseif($_.Name -eq $thisApp.Config.Current_Theme.Name){
        $newtheme = $themes | Where-Object {$_.Name -eq $thisApp.Config.Current_Theme.Name}
      }
      if($themes){
        $null = $themes.Dispose() 
      }
      #import xml 
      if($newTheme.PrimaryAccentColor){        
        $xaml = [System.IO.File]::ReadAllText($Nav_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$($newTheme.PrimaryAccentColor)")
      }else{
        $xaml = [System.IO.File]::ReadAllText($Nav_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
      }
      $hashedit.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $hashedit.Window){
          $hashedit."$($name)" = $hashedit.Window.FindName($name)
        }
      }
      $reader.Dispose()       
      $reader = $null
      $XAML = $Null
      #$hashnav.Logo.Source=$Logo
      $hashedit.Window.title = $PageTitle
      $hashedit.Window.icon = $Logo 
      $hashedit.Window.icon.Freeze()  
      $hashedit.Window.IsWindowDraggable="True"
      $hashedit.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
      $hashedit.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
      $hashedit.Window.ShowTitleBar=$true
      $hashedit.Window.UseNoneWindowStyle = $false
      $hashedit.Window.WindowStyle = 'none'
      $hashedit.Window.IgnoreTaskbarOnMaximize = $true  
      $hashedit.Window.TaskbarItemInfo.Description = $PageTitle
      $SettingsBackground = [System.Windows.Media.ImageBrush]::new()
      $settingsBackground.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTop.png"
      $settingsBackground.ViewportUnits = "Absolute"
      $settingsBackground.Viewport = "0,0,600,263"
      $settingsBackground.TileMode = 'Tile'
      $SettingsBackground.Freeze()
      $hashedit.Window.Background = $SettingsBackground
      $hashedit.Background_Image_Bottom.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowBottom.png"
      $hashedit.Background_Image_Bottom.Source.Freeze()
                   
      $imagebrush = [System.Windows.Media.ImageBrush]::new()
      $ImageBrush.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png"
      $imagebrush.TileMode = 'Tile'
      $imagebrush.ViewportUnits = "Absolute"
      $imagebrush.Viewport = "0,0,600,283"
      $imagebrush.ImageSource.freeze()
      $hashedit.Background_TileGrid.Background = $imagebrush
      #$hashedit.Background_Image_Tile.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png"
      #$hashedit.Background_Image_Tile.ImageSource.Freeze()
      
      $hashedit.Window.Style = $hashedit.Window.TryFindResource('WindowChromeStyle')
      $hashedit.Window.UpdateDefaultStyle()
      $hashedit.PageHeader = $PageTitle
      $hashedit.Logo.Source = $Logo
      #$hashedit.Title_menu_Image.width = "18"  
      #$hashedit.Title_menu_Image.Height = "18"  
      if($hashedit.EditorHelpFlyout){
        $hashedit.EditorHelpFlyout.Document.Blocks.Clear()
      }
      #---------------------------------------------- 
      #region update-EditorHelp Function
      #----------------------------------------------
      function update-EditorHelp{    
        param (
          $content,
          [string]$color = "White",
          [string]$FontWeight = "Normal",
          [string]$FontSize = '14',
          [string]$BackGroundColor = "Transparent",
          [string]$TextDecorations,
          [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
          [switch]$AppendContent,
          [switch]$Open,
          [string]$Header,
          [switch]$Clear,
          [switch]$MultiSelect,
          [switch]$List,
          [System.Windows.Controls.RichTextBox]$RichTextBoxControl
        ) 
        try{
          Add-Type -AssemblyName PresentationFramework
          if($Clear -and $hashedit.EditorHelpFlyout.Document){
            $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
          }
          $hashedit.EditorHelpFlyout.MaxHeight= $hashedit.Window.ActualHeight - 50 
          if(-not [string]::IsNullOrEmpty($Header)){
            $hashedit.Editor_Help_Flyout.Header = $Header
          }
          if(-not [string]::IsNullOrEmpty($content)){
            $url_pattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"  
            $Paragraph = [System.Windows.Documents.Paragraph]::new()
            $RichTextRange = [System.Windows.Documents.Run]::new()
            $RichTextRange.Foreground = $color
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations
            if($List){ 
              $listrange = [System.Windows.Documents.List]::new()
              $listrange.MarkerStyle="Disc" 
              $listrange.MarkerOffset="2"
              #$listrange.padding = "10,0,0,0" 
              $listrange.Background = $BackGroundColor
              $listrange.Foreground = $color
              $listrange.Margin = 0
              $listrange.FontWeight = $FontWeight
              $listrange.FontSize = $FontSize
              $content | foreach{     
                $RichTextRange = [System.Windows.Documents.Run]::new()
                $RichTextRange.Foreground = $color
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = $BackGroundColor
                $RichTextRange.TextDecorations = $TextDecorations     
                $listitem = [System.Windows.Documents.ListItem]::new()
                $RichTextRange.AddText(($_).toupper())
                $Paragraph = [System.Windows.Documents.Paragraph]::new()
                $paragraph.Margin = 0
                $Paragraph.Inlines.add($RichTextRange)
                $null = $listitem.AddChild($Paragraph)
                $null = $listrange.AddChild($listitem)         
              }    
              $null = $RichTextBoxControl.Document.Blocks.Add($listrange)
            }elseif($AppendContent){
              $existing_content = $RichTextBoxControl.Document.blocks | Select-Object -last 1
              #post the content and set the default foreground color
              foreach($inline in $Paragraph.Inlines){
                $existing_content.inlines.add($inline)
              }
            }else{
              if($content -match $url_pattern){
                $hyperlink = $([regex]::matches($content, $url_pattern) | %{$_.groups[0].value})
                $uri = [system.uri]::new($hyperlink)
                $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                $link_hyperlink.NavigateUri = $uri
                $link_hyperlink.ToolTip = "$hyperlink"
                $link_hyperlink.Foreground = "LightGreen"
                $Null = $link_hyperlink.Inlines.add("$($uri.Scheme)://$($uri.DnsSafeHost)")
                $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                $RichTextRange1 = [System.Windows.Documents.Run]::new()
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
          if($Open){
            $hashedit.Editor_Help_Flyout.isOpen = $true
          }
        }
        catch{
          write-ezlogs "An exception occurred in update-EditorHelp" -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion update-EditorHelp Function
      #----------------------------------------------

      #---------------------------------------------- 
      #region Hyperlink Handler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashedit.Hyperlink_RequestNavigate = {
        param ($sender,$e)
        try{
          $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
          if($sender.gettype().name -eq 'TextBox'){
            $url = $sender.text
          }elseif($sender.NavigateUri){
            $url = $sender.NavigateUri
          }
          if($url -match $url_fullpattern){
            $path = $url
          }else{
            $url = $url -replace 'file:///',''
            $path = (resolve-path -LiteralPath $url).Path
          }  
          if(Test-ValidPath $path -Type File){
            $path = [system.io.path]::GetDirectoryName($path)
          }
          write-ezlogs ">>>> Navigating to: $($path)" -showtime
          if($path){
            Start-Process $($path)
          }
        }catch{
          write-ezlogs "An exception occurred in hashedit.Hyperlink_RequestNavigate" -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion Hyperlink Handler
      #----------------------------------------------

      #---------------------------------------------- 
      #region Open_Location_Command Handler
      #----------------------------------------------

      [System.Windows.RoutedEventHandler]$hashedit.BrowseImages_Command  = {
        param($sender)
        try{
          $result = Open-FileDialog -Title "Select the Image file you wish to import"  -filter "Image Files (*.bmp, *.jpg,*.jpeg,*.png)|*.bmp;*.jpg:*.jpeg;*.png" -CheckPathExists
          if([system.io.file]::Exists($result)){
            $hashedit.Dialog_Local_File_Textbox.text = $result
          }else{
            write-ezlogs "The provided image file is not valid!" -warning
          }
        }catch{
          write-ezlogs 'An exception occurred in BrowseMedia_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$hashedit.ApplyImages_Command = {
        param($sender)
        try{
          $hashedit = $hashedit
          if(-not [string]::IsNullOrEmpty($hashedit.Dialog_Local_File_Textbox.text) -and $hashedit.Dialog_Local_File_Textbox.isEnabled){
            $image_pattern = [regex]::new('$(?<=\.((?i)bmp|(?i)jpg|(?i)jpeg|(?i)png))')
            $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
            $pattern = "[$illegal]"
            $result = $hashedit.Dialog_Local_File_Textbox.text
            if([system.io.file]::Exists($result)){
              if([system.io.file]::Exists($result) -and ([System.IO.FileInfo]::new($result) | Where{$_.Extension -notmatch $image_pattern})){
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
                $Button_Settings.AffirmativeButtonText = 'Ok'
                $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
                $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid Image!","The image file you provided is invalid or unsupported - $result",$okandCancel,$Button_Settings)
                write-ezlogs "The mimage file provided is invalid or unsupported - $result" -showtime -warning -LogLevel 2
                return
              }
              $result_cleaned = ([Regex]::Replace($result, $pattern, '')).trim()      
              if(-not [string]::IsNullOrEmpty($result_cleaned)){             
                write-ezlogs ">>>> Adding Image $result_cleaned" -showtime -color cyan -LogLevel 2
                $hashedit.ImagePath.text = $result
                $hashedit.MediaImage.Source = $result  
              }else{
                write-ezlogs "The provided Path is not valid! -- $result" -showtime -warning -LogLevel 2
              }  
            }else{
              write-ezlogs "No Path was provided! - $($result)" -showtime -warning -LogLevel 2
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid Image!","The image file you provided is invalid or unsupported - $result",$okandCancel,$Button_Settings)
            }
          }elseif(-not [string]::IsNullOrEmpty($hashedit.Dialog_Remote_URL_Textbox.text) -and $hashedit.Dialog_Remote_URL_Textbox.isEnabled){
            $result = ($hashedit.Dialog_Remote_URL_Textbox.text).trim()
            if((Test-url $result -TestConnection) -and $result -match $image_pattern){       
              write-ezlogs ">>>> Adding image from URL $result" -showtime -color cyan -logtype Youtube
              $hashedit.ImagePath.text = $result
              $hashedit.MediaImage.Source = $result 
            }else{
              write-ezlogs "The provided URL is invalid or unsupported - $result" -showtime -warning
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid URL!","The URL you provided is not a valid image URL or is not accessible - $result",$okandCancel,$Button_Settings)
              return
            } 
          }else{
            write-ezlogs "No URL or file path was provided!" -showtime -warning
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Did you forget something?","No URL or file path was provided!",$okandCancel,$Button_Settings)
            return
          }
          $hashedit.CustomDialog.RequestCloseAsync()
        }catch{
          write-ezlogs 'An exception occurred in BrowseMedia_Command click event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$hashedit.Open_Location_Command = {
        param($sender)
        try{
          $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
          $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
          $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
          $hashedit.CustomDialog    = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($hashedit.Window)
          [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\Dialog.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
          $reader = [System.Xml.XmlNodeReader]::new($xaml) 
          $hashedit.DialogWindow = [Windows.Markup.XamlReader]::Load($reader)
          $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$hashedit."$($_.Name)" = $hashedit.DialogWindow.FindName($_.Name)}   
          $reader.dispose() 
          $hashedit.CustomDialog.AddChild($hashedit.DialogWindow)
          $hashedit.DialogButtonClose.add_click({
              try{               
                $hashedit.CustomDialog.RequestCloseAsync()
              }catch{
                write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
              }
          })
          $hashedit.Dialog_Remote_URL_Textbox.add_TextChanged({
              try{
                if(-not [string]::IsNullOrEmpty($hashedit.Dialog_Remote_URL_Textbox.text)){
                  $hashedit.Dialog_Local_File_Textbox.IsEnabled = $false
                }else{
                  $hashedit.Dialog_Local_File_Textbox.IsEnabled = $true
                }
              }catch{
                write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
              }
          })
          $hashedit.Dialog_Local_File_Textbox.add_TextChanged({
              try{
                if(-not [string]::IsNullOrEmpty($hashedit.Dialog_Local_File_Textbox.text)){
                  $hashedit.Dialog_Remote_URL_Textbox.IsEnabled = $false
                }else{
                  $hashedit.Dialog_Remote_URL_Textbox.IsEnabled = $true
                }
              }catch{
                write-ezlogs "An exception occurred in Dialog_Local_File_Textbox.add_TextChanged" -catcherror $_
              }
          })
          $hashedit.Dialog_WebURL_Label.content = "Image URL"
          $hashedit.Dialog_Browse_Label.content = "From File:"
          $hashedit.Dialog_Remote_URL_Textbox.MaxWidth="125"
          $hashedit.Dialog_Local_File_Textbox.MaxWidth="125"
          $hashedit.Dialog_Remote_URL_Textbox.Margin="82,0,0,0"
          $hashedit.Dialog_Browse_Label.Width="80"
          $hashedit.Dialog_RootStackPanel.Width = "400"
          $hashedit.Dialog_Local_File_Textbox.Margin="10,0,0,0"
          $hashedit.Dialog_Title_Label.content = 'Open Image'
          $hashedit.Dialog_Add_Button.Content="Ok"
          $hashedit.Dialog_Browse_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$hashedit.BrowseImages_Command)
          $hashedit.Dialog_Browse_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashedit.BrowseImages_Command)
          $hashedit.Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$hashedit.ApplyImages_Command) 
          $hashedit.Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$hashedit.ApplyImages_Command)   
          [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($hashedit.Window, $hashedit.CustomDialog, $CustomDialog_Settings)
        }catch{
          write-ezlogs 'An exception occurred in Open_Location_Command click event' -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #region Open_Location_Command Handler
      #----------------------------------------------

      #---------------------------------------------- 
      #region TextChanged Handler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashedit.TextChanged_Command = {
        param ($sender,$e)
        try{
          $textboxname = $sender.Name
          if($textboxname -match 'Media_(?<value>.*)_textbox'){
            $labelname = ([regex]::matches($textboxname, 'Media_(?<value>.*)_textbox' ) | %{$_.groups[1].value} )
            $label = $hashedit."Media_$($labelname)_Label"
          }
          if($label.Name -eq "Media_$($labelname)_Label"){        
            if(-not [string]::IsNullOrWhiteSpace($sender.text) -or -not [string]::IsNullOrWhiteSpace($sender.document.blocks.inlines.text)){     
              $label.BorderBrush = "Green"
            }else{
              $label.BorderBrush = "Red"
            }
          }
        }catch{
          write-ezlogs "An exception occurred in TextChanged_Command" -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion TextChanged Handler
      #----------------------------------------------
      $hashedit.Media_title_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_title_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Artist_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Artist_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Album_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Album_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Description_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Description_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Track_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Track_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Disc_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Disc_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Year_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_Year_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_FileName_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_FileName_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_EditURL_textbox.RemoveHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      $hashedit.Media_EditURL_textbox.AddHandler([System.Windows.Controls.textbox]::TextChangedEvent,$hashedit.TextChanged_Command)
      #---------------------------------------------- 
      #region Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------
      $hashedit.Editor_Help_Flyout.add_IsOpenChanged({
          try{
            if($hashedit.Editor_Help_Flyout.isOpen){
              $hashedit.Editor_Help_Flyout.Height=[Double]::NaN
            }else{
              $hashedit.Editor_Help_Flyout.Height = '0'
            }
          }catch{
            write-ezlogs "An exception occurred in Editor_Help_Flyout.add_IsOpenChanged" -showtime -catcherror $_
          }
      })
      #---------------------------------------------- 
      #endregion Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------

      #---------------------------------------------- 
      #region Write_TAG_Toggle
      #----------------------------------------------
      $hashedit.Write_TAG_Toggle.add_Toggled({
          try{ 
            if($hashedit.Write_TAG_Toggle.isOn){
              Add-Member -InputObject $thisApp.Config -Name "Profile_Write_IDTags" -Value $true -MemberType NoteProperty -Force
            }else{
              Add-Member -InputObject $thisApp.Config -Name "Profile_Write_IDTags" -Value $false -MemberType NoteProperty -Force
            }
          }catch{
            write-ezlogs "An exception occurred in Write_TAG_Toggle.add_Toggled" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Write_TAG_Toggle
      #----------------------------------------------


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
      $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')

      #---------------------------------------------- 
      #region FileName_Help_Button
      #----------------------------------------------

      $file_restrictions = @(
        'Max Characters: 150'
        'Invalid Characters: "<>|:*?\/`� Carriage Returns'
      )
      $hashedit.FileName_Help_Button.add_Click({
          try{ 
            if($hashedit.EditorHelpFlyout.Document){
              $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
            }
            $hashedit.Editor_Help_Flyout.isOpen = $true
            $hashedit.Editor_Help_Flyout.Header = 'File Name'
            update-EditorHelp -content "Displays and allows renaming of the media's local file name. When changing, you can either click 'Rename File' to rename the file immediately, or the file will be renamed when you click 'Save'" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold 
            update-EditorHelp -content "IMPORTANT" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold -color orange -TextDecorations Underline
            update-EditorHelp -content "Be careful when renaming files, review the following file name restrictions" -FontWeight bold -color orange  -RichTextBoxControl $hashedit.EditorHelpFlyout
            update-EditorHelp -content $file_restrictions -List -RichTextBoxControl $hashedit.EditorHelpFlyout -color cyan
            update-EditorHelp -content "The following file extension formats are currently supported" -RichTextBoxControl $hashedit.EditorHelpFlyout -color orange -FontWeight bold
            update-EditorHelp -content "Audio Formats" -FontWeight bold -TextDecorations Underline -RichTextBoxControl $hashedit.EditorHelpFlyout 
            update-EditorHelp -content $audio_formats -List -RichTextBoxControl $hashedit.EditorHelpFlyout -color cyan
            update-EditorHelp -content "Video Formats" -FontWeight bold -TextDecorations Underline -RichTextBoxControl $hashedit.EditorHelpFlyout
            update-EditorHelp -content $video_formats -List -RichTextBoxControl $hashedit.EditorHelpFlyout -color cyan 
          }catch{
            write-ezlogs "An exception occurred in FileName_Help_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion FileName_Help_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Read_Tag_Help_Button
      #----------------------------------------------
      $hashedit.Read_Tag_Help_Button.add_Click({
          try{ 
            if($hashedit.EditorHelpFlyout.Document.Blocks){
              $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
            }
            $hashedit.Editor_Help_Flyout.isOpen = $true
            $hashedit.Editor_Help_Flyout.Header = $hashedit.Read_IDTags_Texblock.text
            update-EditorHelp -content "Click to immediately rescan the IDTags of the current local media file for metatdata. After scanning, metadata found will be refreshed/updated within the appropriate fields of the editing form" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold 
            update-EditorHelp -content "IMPORTANT" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold -color orange -TextDecorations Underline
            update-EditorHelp -content "This operation does not perform any write operations. If the scan updates or populates any fields in the editing form, you must click 'Save' to commit those changes to the media profile" -RichTextBoxControl $hashedit.EditorHelpFlyout -color orange
          }catch{
            write-ezlogs "An exception occurred in Read_Tag_Help_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Read_Tag_Help_Button
      #----------------------------------------------

      #---------------------------------------------- 
      #region Write_TAG_Button Help
      #----------------------------------------------
      $hashedit.Write_TAG_Button.add_Click({
          try{ 
            if($hashedit.EditorHelpFlyout.Document.Blocks){
              $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
            }
            $hashedit.Editor_Help_Flyout.isOpen = $true
            $hashedit.Editor_Help_Flyout.Header = $hashedit.Write_TAG_Toggle.content
            update-EditorHelp -content "When enabled, metadata will be written to the ID3Tag of the Media file when saving" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold 
            update-EditorHelp -content "IMPORTANT" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold -color orange -TextDecorations Underline
            update-EditorHelp -content "Only supported when editing profiles of Local Media" -RichTextBoxControl $hashedit.EditorHelpFlyout -color orange
            update-EditorHelp -content "INFO" -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold -color cyan -TextDecorations Underline
            update-EditorHelp -content "If enabled, the only data written to the file upon saqving are from the editable fields within this form. Other data such as on the 'Details' tab is readonly. If you wish to update data in the details tab, you can use the 'Read IDTags' button" -RichTextBoxControl $hashedit.EditorHelpFlyout -color cyan
          }catch{
            write-ezlogs "An exception occurred in Write_TAG_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Write_TAG_Button Help
      #----------------------------------------------

      #---------------------------------------------- 
      #region Change_Album_Image Help
      #----------------------------------------------
      $hashedit.Change_Album_Image_Help_Button.add_Click({
          try{ 
            if($hashedit.EditorHelpFlyout.Document.Blocks){
              $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
            }
            $hashedit.Editor_Help_Flyout.isOpen = $true
            $hashedit.Editor_Help_Flyout.Header = $hashedit.Change_Album_Image_Label.content
            update-EditorHelp -content "Some media, such as Youtube videos, may have the album set as the playlist name. If so this setting will apply to all media within that playlist" -RichTextBoxControl $hashedit.EditorHelpFlyout -color orange
            update-EditorHelp -content "Additionally, some Local media may have the album set as the name of the Directory where the file exists. If so this setting will apply to all media within that directory" -RichTextBoxControl $hashedit.EditorHelpFlyout -color orange
          }catch{
            write-ezlogs "An exception occurred in Write_TAG_Button.add_Click" -CatchError $_ -enablelogs
          }
      })
      #---------------------------------------------- 
      #endregion Change_Album_Image Help
      #----------------------------------------------

    }
    catch
    {
      write-ezlogs "An exception occurred when loading xaml" -showtime -CatchError $_
      [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occurred when loading the Profile Editor xaml. Recommened reviewing logs for details.`n`n$($_ | out-string)","[ERROR]- $($thisApp.Config.App_name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
      switch ($oReturn){
        "OK" {
        } 
      }
      return      
    }

    #---------------------------------------------- 
    #region Update-Details Function
    #----------------------------------------------      
    function Update-Details{    
      param (
        $profile,
        $hashedit = $hashedit,
        $textFields,
        $ValidFields,
        $type,
        $VerboseLog = $VerboseLog
      ) 
      try{
        $properties = ($profile | Select-Object *).psobject.properties     
        foreach($property in $properties){
          if((!$hashedit."Media_$($property.name)_Label")){
            $grid = [System.Windows.Controls.Grid]::new()
            $column1 = [System.Windows.Controls.ColumnDefinition]::new()
            $column2 = [System.Windows.Controls.ColumnDefinition]::new()
            $column1.Width = "145"
            $grid.ColumnDefinitions.add($column1)
            $grid.ColumnDefinitions.add($column2)                  
            if($textFields -contains $property.TypeNameOfValue){
              if($VerboseLog){write-ezlogs ">>>> Creating text property ($($property.name)) with value $($property.value)" -showtime -VerboseDebug:$VerboseLog}
              $hashedit."Media_$($property.name)_Label" = [System.Windows.Controls.Label]::new()
              $hashedit."Media_$($property.name)_Label".Name = "Media_$($property.name)_Label"
              $hashedit."Media_$($property.name)_Label".Margin="5,0,0,5"
              #$hashedit."Media_$($property.name)_Label".BorderBrush="Red"
              $hashedit."Media_$($property.name)_Label".Foreground="#FFC6CFD0"
              $hashedit."Media_$($property.name)_Label".BorderThickness="0,0,0,0"
              $hashedit."Media_$($property.name)_Label".HorizontalAlignment="Left"
              $hashedit."Media_$($property.name)_Label".Content = $((Get-Culture).textinfo.totitlecase($($Property.Name).tolower()))
              $hashedit."Media_$($property.name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
              $null = $grid.AddChild($hashedit."Media_$($property.name)_Label") 
              if($Property.Name -match 'bitrate'){
                $value = "$($property.value) Kbps"
              }elseif($Property.Name -match 'SampleRate'){
                $value = "$($property.value) Hz"
              }elseif($Property.Name -match 'FileSize' -or $Property.Name -match 'Size'){
                $value = "$($property.value) MB"
              }else{
                $value = $($property.value)
              }
              if($type -eq 'Local' -and $Property.Name -eq 'Url' -and [system.io.file]::Exists($($property.value))){
                $hashedit.Media_FileName_textbox.isEnabled = $true
                $hashedit.FileName_Button.isEnabled = $true
                $hashedit.Media_FileName_textbox.text = $([System.IO.Path]::GetFileName($property.value))              
                $hashedit.Media_FileName_textbox.tag = $property.value
              }
              if($(Test-ValidPath $property.value)){
                #Clickable link
                try{
                  if($VerboseLog){write-ezlogs ">>>> Creating clickable link property ($($property.name)) with value $($property.value) - Value Type: $($($property.value).gettype()) - Test-URL $(Test-URL $property.value)" -showtime -VerboseDebug:$VerboseLog}
                  $hashedit."Media_$($property.name)_textbox" = [System.Windows.Controls.TextBlock]::new()
                  $hashedit."Media_$($property.name)_textbox".Margin="8,0,0,5"
                  $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                  $link_hyperlink.Foreground = "LightGreen"
                  $link_hyperlink.ToolTip = $property.value
                  $Null = $link_hyperlink.Inlines.add("$($property.value)")
                  $null = $hashedit."Media_$($property.name)_textbox".addChild($link_hyperlink)
                  $uri = [system.uri]::new($property.value)                 
                  $link_hyperlink.NavigateUri = $uri
                  $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                  $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)                                                     
                }catch{
                  write-ezlogs "An exception occurred creating clickable link for property ($($property.name)) with value $($property.value)" -showtime -catcherror $_
                }
              }else{
                $hashedit."Media_$($property.name)_textbox" = [System.Windows.Controls.Textbox]::new()                            
                $hashedit."Media_$($property.name)_textbox".BorderThickness="0,0,0,0"    
                $hashedit."Media_$($property.name)_textbox".Margin="3,0,0,5"
                $hashedit."Media_$($property.name)_textbox".isReadOnly = $true                     
                $hashedit."Media_$($property.name)_textbox".text = $value 
              }
              if($hashedit."Media_$($property.name)_textbox"){
                $hashedit."Media_$($property.name)_textbox".TextWrapping = "Wrap" 
                $hashedit."Media_$($property.name)_textbox".Foreground="#FFC6CFD0"
                $hashedit."Media_$($property.name)_textbox".Background="Transparent"
                $hashedit."Media_$($property.name)_textbox".HorizontalAlignment="Left" 
                $hashedit."Media_$($property.name)_textbox".MinWidth="50"            
                $hashedit."Media_$($property.name)_textbox".Name = "Media_$($property.name)_textbox"           
                $hashedit."Media_$($property.name)_textbox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
                $null = $grid.AddChild($hashedit."Media_$($property.name)_textbox") 
              }
            }   
            if($property.TypeNameOfValue -eq 'System.Boolean'){
              if($VerboseLog){write-ezlogs ">>>> Creating Boolean property ($($property.name)) with value $($property.value)" -showtime -VerboseDebug:$VerboseLog}
              $hashedit."Media_$($property.name)_Label" = [System.Windows.Controls.Label]::new()
              $hashedit."Media_$($property.name)_Label".Name = "Media_$($property.name)_Label"
              $hashedit."Media_$($property.name)_Label".Margin="5,0,0,5"
              #$hashedit."Media_$($property.name)_Label".BorderBrush="Red"
              $hashedit."Media_$($property.name)_Label".BorderThickness="0,0,0,0"
              $hashedit."Media_$($property.name)_Label".HorizontalAlignment="Left"
              $hashedit."Media_$($property.name)_Label".Content = $((Get-Culture).textinfo.totitlecase($($Property.Name).tolower()))
              $hashedit."Media_$($property.name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
              $null = $grid.AddChild($hashedit."Media_$($property.name)_Label") 
              $hashedit."Media_$($property.name)_CheckBox" = [System.Windows.Controls.CheckBox]::new()
              $hashedit."Media_$($property.name)_CheckBox".Name = "Media_$($property.name)_CheckBox"
              $hashedit."Media_$($property.name)_CheckBox".Margin="7,0,0,5"
              $hashedit."Media_$($property.name)_CheckBox".IsEnabled = $false
              $hashedit."Media_$($property.name)_CheckBox".isChecked = $($property.value)
              $hashedit."Media_$($property.name)_CheckBox".HorizontalAlignment="Left"
              $hashedit."Media_$($property.name)_CheckBox".Background="Transparent"
              $hashedit."Media_$($property.name)_CheckBox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
              $null = $grid.AddChild($hashedit."Media_$($property.name)_CheckBox") 
            }                            
            if($hashedit.Details_StackPanel.Children -notcontains $grid){
              $null = $hashedit.Details_StackPanel.addChild($grid)
            }
          }elseif($hashedit."Media_$($property.name)_Label" -and $hashedit."Media_$($property.name)_textbox"){
            if($VerboseLog){write-ezlogs ">>>> Setting existing property ($($property.name)) to value $($property.value)" -showtime -VerboseDebug:$VerboseLog}
            if($property.Name -match 'bitrate'){
              $value = "$($property.value) Kbps"
            }elseif($property.Name -match 'SampleRate'){
              $value = "$($property.value) Hz"
            }elseif($property.Name -match 'FileSize' -or $property.Name -match 'Size'){
              $value = "$($property.value) MB"
            }else{
              $value = $($property.value)
            }
            if($(Test-ValidPath $property.value)){
              #Clickable link
              $uri = [system.uri]::new($property.value)
              $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
              $link_hyperlink.NavigateUri = $uri
              $link_hyperlink.ToolTip = $property.value
              $link_hyperlink.Foreground = "LightGreen"
              $Null = $link_hyperlink.Inlines.add($property.value)
              $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
              $null = $hashedit."Media_$($property.name)_textbox".Text = ''
              $null = $hashedit."Media_$($property.name)_textbox".addChild($link_hyperlink)
            }elseif($hashedit."Media_$($property.name)_textbox".gettype().name -eq 'RichTextBox'){              
              $hashedit."Media_$($property.name)_textbox".document.blocks.clear()
              $Paragraph = [System.Windows.Documents.Paragraph]::new()
              $RichTextRange = [System.Windows.Documents.Run]::new()       
              $RichTextRange.AddText($property.value)
              $Paragraph.Inlines.add($RichTextRange)
              $null = $hashedit."Media_$($property.name)_textbox".Document.Blocks.Add($Paragraph)            
            }else{
              $hashedit."Media_$($property.name)_textbox".text = $($property.value)
            }
          }
        }
        $obj_properties = (($properties | Where-Object {$_.TypeNameofValue -eq 'System.Object' -or $_.TypeNameofValue -eq 'Deserialized.System.Object[]' -or $_.TypeNameofValue -eq 'Deserialized.System.Management.Automation.PSCustomObject' -or $_.TypeNameOfValue -eq 'Deserialized.System.Object'}))

        #$sub_properties = (($properties | where {$_.TypeNameofValue -eq 'System.Object' -or $_.TypeNameofValue -eq 'Deserialized.System.Object[]' -or $_.TypeNameofValue -eq 'Deserialized.System.Management.Automation.PSCustomObject'}).value | select *).psobject.properties | where {$_.isSettable}
        if($obj_properties){    
          foreach($property in $obj_properties){
            $sub_properties = ($property.value | Select-Object *).psobject.properties
            if($VerboseLog){write-ezlogs ">>>> Creating new object sub-properties for ($($property.name)) -- sub-properties for ($($sub_properties.Name))" -showtime -VerboseDebug:$VerboseLog}
            foreach($sub_property in $sub_properties){             
              $sub_property_name = "$($property.name)_$($sub_property.name)"
              if($VerboseLog){write-ezlogs " | Sub_Property Name: $sub_property_name" -showtime -VerboseDebug:$VerboseLog}
              if(!$hashedit."Media_$($sub_property_name)_Label"){
                if($VerboseLog){write-ezlogs "| Creating new field: $sub_property_name" -showtime -VerboseDebug:$VerboseLog}
                $grid = [System.Windows.Controls.Grid]::new()
                $column1 = [System.Windows.Controls.ColumnDefinition]::new()
                $column2 = [System.Windows.Controls.ColumnDefinition]::new()
                $column1.Width = "145"
                $grid.ColumnDefinitions.add($column1)
                $grid.ColumnDefinitions.add($column2) 
                if($textFields -contains $sub_property.TypeNameOfValue){
                  if($VerboseLog){write-ezlogs "| Creating new sub-property ($($sub_property_name)) with value $($sub_property.value)" -showtime -VerboseDebug:$VerboseLog}
                  $row = [System.Windows.Controls.RowDefinition]::new()
                  $grid.rowDefinitions.add($row)
                  $rownumber = ($grid.rowDefinitions.Count - 1)
                  $hashedit."Media_$($sub_property_name)_Label" = [System.Windows.Controls.Label]::new()
                  $hashedit."Media_$($sub_property_name)_Label".Name = "Media_$($sub_property_name)_Label"
                  $hashedit."Media_$($sub_property_name)_Label".Margin="5,0,0,5"
                  #$hashedit."Media_$($property.name)_Label".BorderBrush="Red"
                  $hashedit."Media_$($sub_property_name)_Label".BorderThickness="0,0,0,0"
                  $hashedit."Media_$($sub_property_name)_Label".Foreground="#FFC6CFD0"                 
                  $hashedit."Media_$($sub_property_name)_Label".HorizontalAlignment="Left"
                  $hashedit."Media_$($sub_property_name)_Label".Content = "$($((Get-Culture).textinfo.totitlecase($($Property.Name).tolower()))).$($((Get-Culture).textinfo.totitlecase($($sub_property.Name).tolower())))"
                  $hashedit."Media_$($sub_property_name)_Label".SetValue([System.Windows.Controls.Grid]::RowProperty,$rownumber)
                  $hashedit."Media_$($sub_property_name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
                  $null = $grid.AddChild($hashedit."Media_$($sub_property_name)_Label")
                  if($sub_property.Name -match 'bitrate'){
                    $value = "$($sub_property.value) Kbps"
                  }elseif($sub_property.Name -match 'SampleRate'){
                    $value = "$($sub_property.value) Hz"
                  }elseif($sub_property.Name -match 'FileSize' -or $sub_property.Name -match 'Size'){
                    $value = "$($sub_property.value) MB"
                  }else{
                    $value = $($sub_property.value)
                  }
                  if($(Test-ValidPath $sub_property.value)){
                    #Clickable link
                    try{
                      $hashedit."Media_$($sub_property_name)_textbox" = [System.Windows.Controls.TextBlock]::new()
                      $hashedit."Media_$($sub_property_name)_textbox".Margin="8,0,0,5"
                      $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                      $link_hyperlink.ToolTip = $sub_property.value
                      $link_hyperlink.Foreground = "LightGreen"
                      $Null = $link_hyperlink.Inlines.add("$($sub_property.value)")
                      $null = $hashedit."Media_$($sub_property_name)_textbox".addChild($link_hyperlink)
                      $uri = [system.uri]::new($sub_property.value)                    
                      $link_hyperlink.NavigateUri = $uri
                      $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                      $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)                                           
                    }catch{
                      write-ezlogs "An exception occurred creating clickable link for property ($($sub_property_name)) with value $($sub_property.value)" -showtime -catcherror $_
                    }
                  }else{
                    $hashedit."Media_$($sub_property_name)_textbox" = [System.Windows.Controls.Textbox]::new()
                    $hashedit."Media_$($sub_property_name)_textbox".BorderThickness="0,0,0,0"    
                    $hashedit."Media_$($sub_property_name)_textbox".Margin="3,0,0,5" 
                    $hashedit."Media_$($sub_property_name)_textbox".isReadOnly = $true       
                    $hashedit."Media_$($sub_property_name)_textbox".text = $value 
                  }
                  if($hashedit."Media_$($sub_property_name)_textbox"){
                    $hashedit."Media_$($sub_property_name)_textbox".MinWidth="50"
                    $hashedit."Media_$($sub_property_name)_textbox".Foreground="#FFC6CFD0"
                    $hashedit."Media_$($sub_property_name)_textbox".TextWrapping = "Wrap"           
                    $hashedit."Media_$($sub_property_name)_textbox".HorizontalAlignment="Left"
                    $hashedit."Media_$($sub_property_name)_textbox".Background="Transparent"          
                    $hashedit."Media_$($sub_property_name)_textbox".Name = "Media_$($sub_property_name)_textbox"
                    $hashedit."Media_$($sub_property_name)_textbox".SetValue([System.Windows.Controls.Grid]::RowProperty,$rownumber)
                    $hashedit."Media_$($sub_property_name)_textbox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
                    $null = $grid.AddChild($hashedit."Media_$($sub_property_name)_textbox") 
                  }
                }
                if($sub_property.TypeNameOfValue -eq 'System.Boolean'){
                  if($VerboseLog){write-ezlogs ">>>> Creating Boolean property ($($sub_property.name)) with value $($sub_property.value)" -showtime -VerboseDebug:$VerboseLog}
                  $hashedit."Media_$($sub_property_name)_Label" = [System.Windows.Controls.Label]::new()
                  $hashedit."Media_$($sub_property_name)_Label".Name = "Media_$($sub_property_name)_Label"
                  $hashedit."Media_$($sub_property_name)_Label".Margin="5,0,0,5"
                  #$hashedit."Media_$($property.name)_Label".BorderBrush="Red"
                  $hashedit."Media_$($sub_property_name)_Label".BorderThickness="0,0,0,0"
                  $hashedit."Media_$($sub_property_name)_Label".HorizontalAlignment="Left"
                  $hashedit."Media_$($sub_property_name)_Label".Content = $((Get-Culture).textinfo.totitlecase($($sub_property.Name).tolower()))
                  $hashedit."Media_$($sub_property_name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
                  $null = $grid.AddChild($hashedit."Media_$($sub_property_name)_Label") 
                  $hashedit."Media_$($sub_property_name)_CheckBox" = [System.Windows.Controls.CheckBox]::new()
                  $hashedit."Media_$($sub_property_name)_CheckBox".Name = "Media_$($sub_property_name)_CheckBox"
                  $hashedit."Media_$($sub_property_name)_CheckBox".Margin="7,0,0,5"
                  $hashedit."Media_$($sub_property_name)_CheckBox".IsEnabled = $false
                  $hashedit."Media_$($sub_property_name)_CheckBox".isChecked = $($sub_property.value)
                  $hashedit."Media_$($sub_property_name)_CheckBox".HorizontalAlignment="Left"
                  $hashedit."Media_$($sub_property_name)_CheckBox".Background="Transparent"
                  $hashedit."Media_$($sub_property_name)_CheckBox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
                  $null = $grid.AddChild($hashedit."Media_$($sub_property_name)_CheckBox") 
                }
                if($sub_property.TypeNameOfValue -eq 'System.Object' -or $sub_property.TypeNameOfValue -eq 'Deserialized.System.Object[]' -or $sub_property.TypeNameOfValue -eq 'Deserialized.System.Management.Automation.PSCustomObject' -or $sub_property.TypeNameOfValue -eq 'Deserialized.System.Object'){
                  if($VerboseLog){write-ezlogs ">>>> Creating object sublvl2-property ($($sub_property.name)) with value $($sub_property.value)" -showtime -VerboseDebug:$VerboseLog}
                  $sublvl2_properties = (($sub_property).value | Select-Object *).psobject.properties
                  foreach($sublvl2_property in $sublvl2_properties){                            
                    $sublvl2_property_name = "$($sub_property.name)_$($sublvl2_property.name)"
                    if(!$hashedit."Media_$($sublvl2_property_name)_Label"){
                      $grid = [System.Windows.Controls.Grid]::new()
                      $column1 = [System.Windows.Controls.ColumnDefinition]::new()
                      $column2 = [System.Windows.Controls.ColumnDefinition]::new()
                      $column1.Width = "145"
                      $grid.ColumnDefinitions.add($column1)
                      $grid.ColumnDefinitions.add($column2) 
                      if($textFields -contains $sublvl2_property.TypeNameOfValue){
                        if($VerboseLog){write-ezlogs "| Creating new sublvl2-property ($($sublvl2_property_name)) with value $($sublvl2_property.value)" -showtime -VerboseDebug:$VerboseLog}
                        $row = [System.Windows.Controls.RowDefinition]::new()
                        $grid.rowDefinitions.add($row)
                        $rownumber = ($grid.rowDefinitions.Count - 1)
                        $hashedit."Media_$($sublvl2_property_name)_Label" = [System.Windows.Controls.Label]::new()
                        $hashedit."Media_$($sublvl2_property_name)_Label".Name = "Media_$($sublvl2_property_name)_Label"
                        $hashedit."Media_$($sublvl2_property_name)_Label".Margin="5,0,0,5"
                        $hashedit."Media_$($sublvl2_property_name)_Label".BorderThickness="0,0,0,0"
                        $hashedit."Media_$($sublvl2_property_name)_Label".Foreground="#FFC6CFD0"                 
                        $hashedit."Media_$($sublvl2_property_name)_Label".HorizontalAlignment="Left"
                        $hashedit."Media_$($sublvl2_property_name)_Label".Content = "$($((Get-Culture).textinfo.totitlecase($($sub_Property.Name).tolower()))).$($((Get-Culture).textinfo.totitlecase($($sublvl2_property.Name).tolower())))"
                        $hashedit."Media_$($sublvl2_property_name)_Label".SetValue([System.Windows.Controls.Grid]::RowProperty,$rownumber)
                        $hashedit."Media_$($sublvl2_property_name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
                        $null = $grid.AddChild($hashedit."Media_$($sublvl2_property_name)_Label")
                        if($sublvl2_property.Name -match 'bitrate'){
                          $value = "$($sublvl2_property.value) Kbps"
                        }elseif($sublvl2_property.Name -match 'SampleRate'){
                          $value = "$($sublvl2_property.value) Hz"
                        }elseif($sublvl2_property.Name -match 'FileSize' -or $sublvl2_property.Name -match 'Size'){
                          $value = "$($sublvl2_property.value) MB"
                        }else{
                          $value = $($sublvl2_property.value)
                        }
                        if($(Test-ValidPath $sublvl2_property.value)){
                          #Clickable link
                          $uri = [system.uri]::new($sublvl2_property.value)
                          $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                          $link_hyperlink.NavigateUri = $uri
                          $link_hyperlink.ToolTip = $sublvl2_property.value
                          $link_hyperlink.Foreground = "LightGreen"
                          $Null = $link_hyperlink.Inlines.add($sublvl2_property.value)
                          $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                          $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                          $hashedit."Media_$($sublvl2_property_name)_textbox" = [System.Windows.Controls.TextBlock]::new()
                          $hashedit."Media_$($sublvl2_property_name)_textbox".Margin="8,0,0,5"
                          $null = $hashedit."Media_$($sublvl2_property_name)_textbox".addChild($link_hyperlink)
                        }else{
                          $hashedit."Media_$($sublvl2_property_name)_textbox" = [System.Windows.Controls.Textbox]::new()
                          $hashedit."Media_$($sublvl2_property_name)_textbox".BorderThickness="0,0,0,0"    
                          $hashedit."Media_$($sublvl2_property_name)_textbox".Margin="3,0,0,5" 
                          $hashedit."Media_$($sublvl2_property_name)_textbox".isReadOnly = $true       
                          $hashedit."Media_$($sublvl2_property_name)_textbox".text = $value 
                        }
                        $hashedit."Media_$($sublvl2_property_name)_textbox".MinWidth="50"
                        $hashedit."Media_$($sublvl2_property_name)_textbox".Foreground="#FFC6CFD0"
                        $hashedit."Media_$($sublvl2_property_name)_textbox".TextWrapping = "Wrap"           
                        $hashedit."Media_$($sublvl2_property_name)_textbox".HorizontalAlignment="Left"
                        $hashedit."Media_$($sublvl2_property_name)_textbox".Background="Transparent"          
                        $hashedit."Media_$($sublvl2_property_name)_textbox".Name = "Media_$($sublvl2_property_name)_textbox"
                        $hashedit."Media_$($sublvl2_property_name)_textbox".SetValue([System.Windows.Controls.Grid]::RowProperty,$rownumber)
                        $hashedit."Media_$($sublvl2_property_name)_textbox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
                        $null = $grid.AddChild($hashedit."Media_$($sublvl2_property_name)_textbox") 
                      }

                    }
                  }
                }                
                if($hashedit.Details_StackPanel.Children -notcontains $grid){
                  $null = $hashedit.Details_StackPanel.addChild($grid)
                }
              }elseif($hashedit."Media_$($sub_property_name)_Label" -and $hashedit."Media_$($sub_property_name)_textbox"){
                if($VerboseLog){write-ezlogs ">>>> Updating existing sub-property ($($sub_property_name)) from value $($hashedit."Media_$($sub_property_name)_textbox".text) to value $($sub_property.value)" -showtime -VerboseDebug:$VerboseLog}
                if($sub_property.Name -match 'bitrate'){
                  $value = "$($sub_property.value) Kbps"
                }elseif($sub_property.Name -match 'SampleRate'){
                  $value = "$($sub_property.value) Hz"
                }elseif($sub_property.Name -match 'FileSize' -or $sub_property.Name -match 'Size'){
                  $value = "$($sub_property.value) MB"
                }else{
                  $value = $($sub_property.value)
                }
                if([system.io.file]::Exists($($sub_property.value)) -or [System.IO.Directory]::Exists($($sub_property.value)) -or (Test-URL $($sub_property.value))){
                  #Clickable link
                  $uri = [system.uri]::new($sub_property.value)
                  $link_hyperlink = [System.Windows.Documents.Hyperlink]::new()
                  $link_hyperlink.NavigateUri = $uri
                  $link_hyperlink.ToolTip = $sub_property.value
                  $link_hyperlink.Foreground = "LightGreen"
                  $Null = $link_hyperlink.Inlines.add($sub_property.value)
                  $Null = $link_hyperlink.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                  $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Hyperlink_RequestNavigate)
                  $null = $hashedit."Media_$($sub_property_name)_textbox".Text = ''
                  $null = $hashedit."Media_$($sub_property_name)_textbox".addChild($link_hyperlink)
                }else{              
                  $hashedit."Media_$($sub_property_name)_textbox".text = $value
                }
              }                      
            } 
          }
        }
        #Year
        if(-not [string]::IsNullOrEmpty($profile.release_date)){
          $hashedit.Media_Year_textbox.text = $profile.release_date        
        }elseif(-not [string]::IsNullOrEmpty($profile.SongInfo.Year)){
          $hashedit.Media_Year_textbox.text = $profile.SongInfo.Year 
        }     
        #TrackNumber
        if(-not [string]::IsNullOrEmpty($profile.SongInfo.TrackNumber) -and $profile.SongInfo.TrackNumber -ne 'true' -and $profile.SongInfo.TrackNumber -ne 'false'){
          $hashedit.Media_Track_textbox.text = $profile.SongInfo.TrackNumber         
        }elseif([string]::IsNullOrEmpty($hashedit.Media_Track_textbox.text) -and -not [string]::IsNullOrEmpty($profile.Track_Number)){
          $hashedit.Media_Track_textbox.text = $profile.Track_Number 
        }elseif([string]::IsNullOrEmpty($hashedit.Media_Track_textbox.text) -and -not [string]::IsNullOrEmpty($profile.TrackNumber)){
          $hashedit.Media_Track_textbox.text = $profile.TrackNumber 
        }
        #disc_number
        if([string]::IsNullOrEmpty($hashedit.Media_Disc_textbox.text) -and -not [string]::IsNullOrEmpty($profile.disc_number) -and $profile.disc_number -ne 'true' -and $profile.disc_number -ne 'false'){
          $hashedit.Media_Disc_textbox.text = $profile.disc_number          
        } 
      }
      catch{
        write-ezlogs "An exception occurred in update-Details" -showtime -catcherror $_
      }
    }     
    #---------------------------------------------- 
    #endregion Update-Details Function
    #----------------------------------------------

    $ValidFields = @(
      'Number'
      'Title'
      'Artist'
      'Artists'
      'spotify'
      'href'
      'name'
      'total_tracks'
      'Album'
      'Duration'
      'hasVideo'
      'Duration_ms'
      'Cover_art'
      'URL'
      'URi'
      'Size'
      'ID'
      'Directory'
      'Profile_Path'
      'SongInfo'
      'Bitrate'
      'PictureData'
      'Genre'
      'definition'
      'channel_id'
      'Comments'
      'Copyright'
      'MediaTypes'
      'like_count'
      'availability'
      'popularity'
      'Album_Info'
      'artists'
      'Spotify_Launch_Path'
      'licensedContent'
      'external_urls'
      'categories'
      'Profile_Date_Added'
      'Profile_Date_Modified'
      'chat_url'
      'uploader'
      'Followed'
      'Stream_title'
      'User_id'
      'Live_Status'
      'Status_msg'
      'Playlist'
      'Playlist_ID'
      'AudioChannels'
      'VideoWidth'
      'VideoHeight'
      'SampleRate'
      'ItemCount'
      'Year'
      'TrackNumber'
      'FileSize'
      'DiscNumber'
      'BitsPerSample'
      'images'
      'thumbnail'
      'status'
      'Source'
      'Type'
      'Albums'
      'Album_Name'
      'profile_image_url'
      'video_url'
      'formats'
      'regionRestriction'
      'audio_url'
      'format_note'
      'default'
      'medium'
      'high'
      'standard'
      'maxres'
      'format_id'
      'offline_image_url'
      'tags'
      'height'
      'width'
      'video_ext'
      'resolution'
      'ext'
      'manifest_url'
      'upload_date'
      'playlist_index'
      'privacyStatus'
      'Playlist_encodedtitle'
      'encodedid'
      'view_count'
      'Group'
      'Tracks_Total'
      'album_type'
      'available_markets'
      'release_date'
      'release_date_precision'
      'year'
      'explicit'
      'episode'
      'is_local'
      'Artist_url'
      'Artist_web_url'
      'Album_ID'
      'Album_url'
      'Album_web_url'
      'Artist_ID'
      'External_url'
      'Group_Name'
    )
    $textFields = @(
      'System.String'
      'System.Double'
      'System.Int64'
      'System.UInt32'
      'System.Int32'
      'Deserialized.System.String[]'
      'Deserialized.TagLib.MediaTypes'
      'System.TimeSpan'
      'System.Uri'
    )
    if($Media_to_edit.Source -eq 'Local'){
      $profile_Path = [system.io.path]::Combine($thisApp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
      $All_Media_Profile = $synchash.All_local_Media
    }elseif($Media_to_edit.Source -eq 'Spotify'){
      $profile_Path = [system.io.path]::Combine($thisApp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')
      $All_Media_Profile = $synchash.All_Spotify_Media
    }elseif($Media_to_edit.Source -eq 'Youtube'){
      $profile_Path = [system.io.path]::Combine($thisApp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')
      $All_Media_Profile = $synchash.All_Youtube_Media
    }elseif($Media_to_edit.Source -eq 'Twitch'){
      $profile_Path = [system.io.path]::Combine($thisApp.Config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml')
      $All_Media_Profile = $synchash.All_Twitch_Media
    }

    if($Media_to_edit.url){          
      <#      if([System.IO.File]::Exists($profile_Path)){
          write-ezlogs ">>>> Importing media profile: $($profile_Path)" -enablelogs -showtime 
          if($Media_to_edit.Source -in 'Local','Spotify','Twitch','Youtube'){
          $All_Media_Profile = Import-SerializedXML -Path $profile_Path
          }else{
          [System.Collections.Generic.List[Object]]$All_Media_Profile = Import-Clixml $profile_Path
          }     
      }#>      
      #[System.Collections.ArrayList]$All_Media_Profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($profile_Path))
      if($Media_to_edit.Source -eq 'Local'){    
        $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $media_to_edit.Id            
        if(@($profile).count -gt 1){
          write-ezlogs "| Multiple profiles returned, matching against urls" -enablelogs -showtime
          $profile = ($profile | Where-Object {$_.url -eq $media_to_edit.url}) | Select-Object -unique
        }
        write-ezlogs "| Local Profile to Edit: $($profile | out-string)" -enablelogs -showtime
        if($profile.title){
          $title = $profile.title 
        }elseif($profile.SongInfo.title){
          $title = $profile.SongInfo.title 
        }elseif($profile.name){
          $title = $profile.name
        }else{
          $title = $Null
        }
        #Media Artist
        if($profile.Artist){
          $Artist = $profile.Artist
        }elseif($profile.SongInfo.Artist){
          $Artist = $profile.SongInfo.Artist
        }else{
          $Artist = $Null
        } 
        #Media Album
        if($profile.Album){
          $Album = $profile.Album
        }elseif($profile.SongInfo.Album){
          $Album = $profile.SongInfo.Album
        }else{
          $Album = $Null
        }
        #Media Description
        if($profile.Description){
          $Description = $profile.Description
        }elseif($profile.SongInfo.Description){
          $Description = $profile.SongInfo.Description
        }else{
          $Description = $null
        } 
        #Media url
        if($profile.url){
          $url = $profile.url
        }elseif($profile.uri){
          $url = $profile.uri
        }else{
          $url = $null
        } 
        #Media image
        if([system.io.file]::Exists($profile.cached_image.StreamSource.Name)){
          $image = $profile.cached_image.StreamSource.Name
          $imageSource = $profile.cached_image.StreamSource.Name
        }elseif([system.io.file]::Exists($Media_to_edit.cached_image.StreamSource.Name)){
          $image = $Media_to_edit.cached_image.StreamSource.Name
          $imageSource = $Media_to_edit.cached_image.StreamSource.Name
        }elseif($profile.Cover_art){
          $image = $profile.Cover_art
          $imageSource = $image
        }elseif($profile.PictureData){
          try{
            $taginfo = [taglib.file]::create($url) 
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Tag Picture: $($taginfo.tag.pictures | out-string)" -showtime}
          }catch{
            write-ezlogs "An exception occurred getting taginfo for $($url)" -showtime -catcherror $_
          }
          if($taginfo.tag.pictures){
            $tagimage = ($taginfo.tag.pictures | Select-Object -first 1).data.data
            if($tagimage){
              write-ezlogs "Getting Cached image from taginfo type $($tagimage.gettype())" -showtime
              $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($profile.id).png")
              if(!([System.IO.File]::Exists($image_Cache_path))){
                $BinaryWriter = [System.IO.BinaryWriter]::new([System.IO.File]::create($image_Cache_path))
                $BinaryWriter.Write($tagimage)
                $BinaryWriter.Close()
                $binarywriter.Dispose()
                if(([System.IO.File]::Exists($image_Cache_path))){
                  $image = $image_Cache_path
                }else{
                  $image = $null
                }                            
              }else{
                $image = $image_Cache_path
              }              
            }
          }else{
            $image = $null
          }
          $imageSource = $image
        }elseif($profile.thumbnail){
          $image = $profile.thumbnail
          $imageSource = $profile.thumbnail
        }else{
          $image = $null
          $imageSource = $null
        }                                          
        $type = 'Local'                    
        write-ezlogs "| Loading local Media profile for $($title) - $($profile.id) into editor" -showtime                    
      }elseif($Media_to_edit.Source -eq 'Spotify' -or $media_to_edit.url -match 'spotify\:' -or $media_to_edit.uri -match 'spotify\:'){  
        $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $media_to_edit.Id         
        if(@($profile).count -gt 1){
          $profile = ($profile.where({$_.playlist_id -eq $media_to_edit.playlist_id})) | Select-Object *
        }
        if($VerboseLog){write-ezlogs "| Spotify Profile to Edit: $($profile | out-string)" -enablelogs -showtime -VerboseDebug:$VerboseLog}
        if($profile.title){
          $title = $profile.title
        }elseif($profile.name){
          $title = $profile.name
        }else{
          $title = $Null
        }
        if($profile.artist){
          $artist = $profile.artist
        }else{
          $artist = $Null
        }
        #Media Album
        if($profile.Album){
          $Album = $profile.Album
        }elseif($profile.Album_Info.name){
          $Album = $profile.Album_Info.name
        }else{
          $Album = $Null
        } 
        #Media Description
        if($profile.Description){
          $Description = $profile.Description
        }else{
          $Description = $null
        }
        #Media url
        if($profile.url){
          $url = $profile.url
        }elseif($profile.uri){
          $url = $profile.uri
        }else{
          $url = $null
        }

        #Media image
        if([system.io.file]::Exists($profile.cached_image_path)){
          $image = $profile.cached_image_path
          $imageSource = $profile.cached_image_path
        }elseif([system.io.file]::Exists($Media_to_edit.cached_image.StreamSource.Name)){
          $image = $Media_to_edit.cached_image.StreamSource.Name
          $imageSource = $Media_to_edit.cached_image.StreamSource.Name
        }elseif(-not [string]::IsNullOrEmpty($profile.thumbnail)){    
          $image = $profile.thumbnail
          $imageSource = $profile.thumbnail
        }elseif(($profile.images).url){
          $image = ($profile.images | Where-Object {$_.Width -le 300} | Select-Object -First 1).url
          if(!$image){
            $image = ($profile.images | Where-Object {$_.Width -ge 300} | Select-Object -last 1).url
          }
          if(!$image){
            $image = (($profile.images).psobject.Properties.Value).url | Select-Object -First 1
          }
          $imageSource = $image          
        }else{
          $image = $null
          $imageSource = $null
        }
        #Media Type
        $type = 'Spotify'                     
        write-ezlogs "| Loading Spotify profile for $($title) - $($profile.id) into editor" -showtime                        
      }elseif($Media_to_edit.Source -eq 'Youtube' -or $Media_to_edit.type -eq 'YoutubeChannel' -or $Media_to_edit.type -eq 'YoutubeTV' -or $Media_to_edit.url -match 'youtube\.com' -or $Media_to_edit.url -match 'youtu\.be'){          
        $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $media_to_edit.Id 
        if(!$profile -and $media_to_edit.url){
          $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_URL $media_to_edit.url
        }        
        if(@($profile).count -gt 1){
          $profile = ($profile | Where-Object {$_.Playlist_ID -eq $media_to_edit.Playlist_ID}) | Select-Object *
        }
        if(@($profile).count -gt 1){
          $profile = ($profile | Where-Object {$_.url -eq $media_to_edit.url}) | Select-Object -Unique
        }
        if(!$profile){
          write-ezlogs "Unable to find media to edit in library profiles, media may be orphaned!" -showtime -Warning
          $profile = $media_to_edit | Select-Object *
        }
        write-ezlogs "| Youtube Profile to Edit: $($profile | out-string)" -enablelogs -showtime
        if($profile.title){
          $title = $profile.title
        }else{
          $title = $Null
        }       
        if($profile.artist){
          $artist = $profile.artist
        }elseif($profile.uploader){
          $artist = $profile.uploader
        }else{
          $artist = $Null
        }
        #Media Album
        if($profile.Album){
          $Album = $profile.Album
        }else{
          $Album = $null
        }
        #Media Description
        if($profile.Description){
          $Description = $profile.Description
        }else{
          $Description = $null
        }
        #Media url
        if($profile.url){
          $url = $profile.url
        }elseif($profile.uri){
          $url = $profile.uri
        }else{
          $url = $null
        }
        #Media Image
        if([system.io.file]::Exists($profile.cached_image.StreamSource.Name)){
          $image = $profile.cached_image.StreamSource.Name
          $imageSource = $profile.cached_image.StreamSource.Name
        }elseif([system.io.file]::Exists($Media_to_edit.cached_image.StreamSource.Name)){
          $image = $Media_to_edit.cached_image.StreamSource.Name
          $imageSource = $Media_to_edit.cached_image.StreamSource.Name
        }elseif(-not [string]::IsNullOrEmpty($profile.cover_art) -or (Test-url $profile.cover_art)){
          $image = $($profile.Cover_art | Select-Object -First 1)
          $imageSource = $image
        }elseif([System.IO.File]::Exists($profile.thumbnail)){
          $image = $($profile.thumbnail | Select-Object -First 1)
          $imageSource = $image
        }elseif(-not [string]::IsNullOrEmpty((($profile.images).psobject.Properties.Value).url)){          
          $image = (($profile.images).psobject.Properties.Value).url | Where-Object {$_ -match 'maxresdefault.jpg'} | Select-Object -First 1
          if(!$image){
            $image = (($profile.images).psobject.Properties.Value).url | Where-Object {$_ -match 'hqdefault.jpg'} | Select-Object -First 1
          }
          if(!$image){
            $image = (($profile.images).psobject.Properties.Value).url | Select-Object -First 1
          }
          $imageSource = $image
        }else{
          $image = $null
          $imageSource = $null
        }
        #Media Type
        $type = 'Youtube'
        write-ezlogs "| Loading Youtube profile for $($title) - $($profile.id) into editor" -showtime                       
      }elseif($Media_to_edit.Source -eq 'Twitch' -or $Media_to_edit.type -eq 'TwitchChannel' -or $Media_to_edit.url -match 'twitch.tv'){ 
        $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $media_to_edit.Id
        if(!$profile -and $media_to_edit.url){
          $profile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_URL $media_to_edit.url
        }         
        if(@($profile).count -gt 1){
          $profile = ($profile | Where-Object {$_.url -eq $media_to_edit.url}) | Select-Object *
        }        
        if($VerboseLog){write-ezlogs "| Twitch Profile to Edit: $($profile | out-string)" -enablelogs -showtime -VerboseDebug:$VerboseLog}
        if($profile.title){
          $title = $profile.title
        }else{
          $title = $Null
        }       
        if($profile.artist){
          $artist = $profile.artist
        }elseif($profile.Name){
          $artist = $profile.Name
        }elseif($profile.Channel_Name){
          $artist = $profile.Channel_Name
        }else{
          $Album = $null
        }
        #Media Album
        if($profile.Album){
          $Album = $profile.Album
        }else{
          $Album = $null
        }
        #Media Description
        if($profile.Description){
          $Description = $profile.Description
        }else{
          $Description = $null
        }
        #Media url
        if($profile.url){
          $url = $profile.url
        }elseif($profile.uri){
          $url = $profile.uri
        }else{
          $url = $null
        }
        #Media Image
        if([system.io.file]::Exists($profile.cached_image.StreamSource.Name)){
          $image = $profile.cached_image.StreamSource.Name
          $imageSource = $profile.cached_image.StreamSource.Name
        }elseif([system.io.file]::Exists($Media_to_edit.cached_image.StreamSource.Name)){
          $image = $Media_to_edit.cached_image.StreamSource.Name
          $imageSource = $Media_to_edit.cached_image.StreamSource.Name
        }elseif(-not [string]::IsNullOrEmpty($profile.offline_image_url)){
          $image = $($profile.offline_image_url | Select-Object -First 1)
          $imageSource = $image
        }elseif(-not [string]::IsNullOrEmpty($profile.profile_image_url)){
          $image = $($profile.profile_image_url | Select-Object -First 1)
          $imageSource = $image
        }elseif(-not [string]::IsNullOrEmpty($profile.cover_art)){
          $image = $($profile.Cover_art | Select-Object -First 1)
          $imageSource = $image
        }elseif(-not [string]::IsNullOrEmpty($profile.images.url)){
          $image = $($profile.images.url | Where-Object {$_ -match 'maxresdefault.jpg'} | Select-Object -First 1)
          $imageSource = $image
        }elseif(-not [string]::IsNullOrEmpty($profile.thumbnail)){
          $image = $($profile.thumbnail | Select-Object -First 1)
          $imageSource = $image
        }else{
          $image = $null
          $imageSource = $null
        }
        #Media Type
        $type = 'Twitch'
        write-ezlogs "| Loading Youtube profile for $($title) - $($profile.id) into editor" -showtime                       
      }    
  
      #---------------------------------------------- 
      #region Duration
      #----------------------------------------------
      if(-not [string]::IsNullOrEmpty($profile.duration)){
        $duration = $profile.duration
      }elseif($profile.duration_ms -or $profile.SongInfo.Duration_ms){ 
        if($profile.duration_ms){
          $duration_ms = $profile.duration_ms
        }elseif($profile.SongInfo.Duration_ms){
          $duration_ms = $profile.SongInfo.Duration_ms
        }
        if($duration_ms){
          [int]$hrs = $($([timespan]::FromMilliseconds($profile.duration_ms)).Hours)
          [int]$mins = $($([timespan]::FromMilliseconds($profile.duration_ms)).Minutes)
          [int]$secs = $($([timespan]::FromMilliseconds($profile.duration_ms)).Seconds)
          if($hrs -lt 1){
            $hrs = '0'
          }
          $duration = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"        
        }         
      }else{
        $duration = $Null
      }
      #---------------------------------------------- 
      #endregion Duration
      #----------------------------------------------        

      #---------------------------------------------- 
      #region Images
      #----------------------------------------------
      if(-not [string]::IsNullOrEmpty($image)){
        $hashedit.MediaImage.Source=$image     
        if(Test-ValidPath $imageSource -Type Any){
          $hashedit.ImagePath.text = $imageSource              
        }
      }
      $Null = $hashedit.ImagePath.RemoveHandler([System.Windows.Documents.Hyperlink]::PreviewMouseLeftButtonDownEvent,$hashedit.Hyperlink_RequestNavigate)
      $Null = $hashedit.ImagePath.AddHandler([System.Windows.Documents.Hyperlink]::PreviewMouseLeftButtonDownEvent,$hashedit.Hyperlink_RequestNavigate)      
      #---------------------------------------------- 
      #endregion Images
      #---------------------------------------------- 

      #---------------------------------------------- 
      #region Populate Fields
      #----------------------------------------------
         
      #Create fields dynamically from profile properties
      Update-Details -profile $profile -hashedit $hashedit -textFields $textFields -ValidFields $ValidFields -type $type 

      #Media Title    
      if([string]::IsNullOrEmpty($hashedit.Media_title_textbox.text) -and -not [string]::IsNullOrEmpty($title)){
        $hashedit.Media_title_textbox.text = $title          
      }
      #Media Artist
      if([string]::IsNullOrEmpty($hashedit.Media_Artist_textbox.text) -and -not [string]::IsNullOrEmpty($Artist)){
        $hashedit.Media_Artist_textbox.text = $Artist          
      } 
      #Media Album
      if([string]::IsNullOrEmpty($hashedit.Media_Album_textbox.text) -and -not [string]::IsNullOrEmpty($Album)){
        $hashedit.Media_Album_textbox.text = $Album         
      }      
      #---------------------------------------------- 
      #endregion Populate Fields
      #----------------------------------------------

      if($type -eq 'Local'){
        $hashedit.Write_TAG_Toggle.isEnabled = $true
        if($thisApp.Config.Profile_Write_IDTags){
          $hashedit.Write_TAG_Toggle.isOn = $true
        }
      }else{
        if(-not [string]::IsNullOrEmpty($url)){
          $hashedit.Media_EditURL_textbox.text = $url
        }
        $hashedit.Write_TAG_Toggle.isEnabled = $false
        $hashedit.Write_TAG_Toggle.isOn = $false
      }                                                      
    }else{ 
      write-ezlogs "A valid url was not provided or found for media: $($media_to_edit | out-string)" -showtime -warning
      Update-Notifications  -Level 'WARNING' -Message "A valid url was not provided or found for selected media" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold
      return    
    }                                        
     
    #---------------------------------------------- 
    #region FileName_Button
    #----------------------------------------------

    function Rename-LocalMediaFile {
      Param (     
        $FileTextBoxControl,     
        $synchash = $synchash,
        $hashedit = $hashedit,
        $thisApp = $thisApp,
        $media_to_edit = $media_to_edit,
        $All_Media_Profile = $All_Media_Profile,
        $type = $type,
        $profile = $profile,
        $media_pattern = $media_pattern,
        [string]$profile_Path,
        [switch]$Verboselog,
        [switch]$UpdateProfile
      )       
      try{ 
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Ok'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
        if(-not [string]::IsNullOrEmpty($FileTextBoxControl.text)){
          $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
          $pattern = "[`�$illegal]"
          $path_directory = [system.io.path]::GetDirectoryName($FileTextBoxControl.tag)
          $existingfilename = [system.io.path]::GetFileName($FileTextBoxControl.tag)
          $existingpath = [system.io.path]::Combine($path_directory,$existingfilename)
          write-ezlogs ">>>> Existing file name and path: $($existingpath)" -showtime
          if($FileTextBoxControl.text -match $pattern){
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid File Name!","The file name you provided contains invalid characters - $($FileTextBoxControl.text)`nPlease choose a different file name",$okandCancel,$Button_Settings)
            return
          }
          $result = ([Regex]::Replace($FileTextBoxControl.text, $pattern, '')).trim()
          $FileTextBoxControl.text = $result
          [int]$character_Count = ($result | measure-object -Character -ErrorAction SilentlyContinue).Characters
          if($character_Count -gt 150){
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid File Name!","The file name you provided contains too many characters - $($character_Count)`nPlease choose a file name with 150 characters or less",$okandCancel,$Button_Settings)
            return
          }
          $extension = [System.io.path]::GetExtension($FileTextBoxControl.text)
          if($extension -notmatch $media_pattern){
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid File Extension!","The file name you provided does not match a supported media extension - $($extension)`nPlease choose a file name that matches a supported media extension`n`nAudio Formats:`n$($audio_formats | out-string)`n`nVideo Formats:`n$($video_formats | out-string)",$okandCancel,$Button_Settings)
            return
          }           
          $new_Path_and_Name = [system.io.path]::Combine($path_directory,$result)
          if($new_Path_and_Name -eq $existingpath){
            write-ezlogs "New file name ($new_Path_and_Name) and existing ($existingpath) are the same, no changes to be made" -showtime -warning
            if($UpdateProfile){
              if($hashedit.EditorHelpFlyout.Document.Blocks){
                $hashedit.EditorHelpFlyout.Document.Blocks.Clear() 
              }
              $hashedit.Editor_Help_Flyout.isOpen = $true
              $hashedit.Editor_Help_Flyout.Header = 'File Rename'
              update-EditorHelp -content "New file name and existing file name are the same, no changes to be made." -RichTextBoxControl $hashedit.EditorHelpFlyout -FontWeight bold -color cyan 
            }
            return $true
          }elseif([System.IO.File]::Exists($new_Path_and_Name)){
            write-ezlogs "New file name and path ($new_Path_and_Name) already exists" -showtime -warning
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"File Name Already Exists!","An existing file was found with with the same name at path ($new_Path_and_Name)`nPlease choose a different file name",$okandCancel,$Button_Settings)
            return
          }elseif([System.IO.File]::Exists($existingpath) -and $new_Path_and_Name){
            write-ezlogs ">>>> Renaming file ($existingpath) to ($new_Path_and_Name)" -showtime
            $null = [system.io.file]::Move($existingpath,$new_Path_and_Name)
            #$Null = Rename-item $existingpath -NewName $new_Path_and_Name -Force -Verbose *>&1 | Out-File $thisApp.Config.Log_File -Encoding unicode -Append -Force
          }
          if([System.IO.File]::Exists($new_Path_and_Name)){
            write-ezlogs "[SUCCESS] File successfully renamed" -showtime
            $FileTextBoxControl.tag = $new_Path_and_Name
            if($hashedit.Media_url_Textbox){
              $hashedit.Media_url_Textbox.text = $new_Path_and_Name
            }
            if($UpdateProfile){
              $LibraryMediaProfile = ($synchash.All_local_Media.where({$_.id -eq $profile.id})) 
              if(@($LibraryMediaProfile).count -gt 1){
                $LibraryMediaProfile = ($LibraryMediaProfile.where({$_.Playlist_ID -eq $media_to_edit.Playlist_ID})) | Select-Object *
              }
              if(!$LibraryMediaProfile){
                write-ezlogs "Unable to find media to edit in library profiles, media may be orphaned!" -showtime -Warning
                $LibraryMediaProfile = $media_to_edit
              } 
              if($profile){
                Add-Member -InputObject $profile -Name "url" -Value $new_Path_and_Name -MemberType NoteProperty -Force
              }
              if($Media_to_edit){
                Add-Member -InputObject $Media_to_edit -Name "url" -Value $new_Path_and_Name -MemberType NoteProperty -Force
              }
              if($LibraryMediaProfile.id){
                foreach($media in $LibraryMediaProfile){
                  $media.url = $new_Path_and_Name    
                }
              }
              Add-Member -InputObject $profile -Name "Profile_Date_Modified" -Value $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt') -MemberType NoteProperty -Force    
              try{
                $profile_to_update = ($All_Media_Profile.where({$_.id -eq $media_to_edit.id}))
                if($profile_to_update){
                  if($All_Media_Profile -contains $profile_to_update){
                    foreach($p in $profile_to_update){
                      write-ezlogs "Updating all media profile for track $($p.title)" -showtime
                      $p = $profile
                    }
                    #$null = $All_Media_Profile.remove($profile_to_update)
                  }else{
                    write-ezlogs "Was unable to remove old profile from all_media_profile - old profile $($profile_to_update | out-string)" -showtime -warning
                  }
                  Export-SerializedXML -InputObject $All_Media_Profile -path $profile_Path                        
                  #Export-Clixml -InputObject ([System.Collections.Generic.List[Object]]$All_Media_Profile) -path $profile_Path -Force -Encoding Default
                }           
                write-ezlogs ">>>> Saving profile to $($profile_Path)" -showtime -color cyan
              }catch{
                write-ezlogs "Exception Saving profile to $($profile_Path)" -showtime -catcherror $_
              }          
              if($LibraryMediaProfile){
                write-ezlogs " | Updated Library Media Profile: $($LibraryMediaProfile | out-string)" -showtime
              }else{
                write-ezlogs "Could not find Library Media Profile to update!" -showtime -warning
              }                                                           
              try{
                Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
                #Export-Clixml -InputObject $thisapp.config -path $thisapp.config.Config_Path -Force -Encoding UTF8
              }catch{
                write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
              }
              #$synchash.Import_Playlists_Cache = $false
              Update-Playlist -media $profile -synchash $synchash -thisApp $thisApp -Updateall     
              $synchash.update_status_timer.tag = $type             
              $synchash.update_status_timer.start()  
              $synchash.update_Queue_timer.tag = 'FullRefresh'
              $synchash.update_Queue_timer.start()                                        
              $hashedit.Save_status_transitioningControl.content = ""
              $hashedit.Save_status_textblock.text = "Saved Profile Successfully!"
              $hashedit.Save_status_textblock.foreground = "LightGreen"
              $hashedit.Save_status_transitioningControl.content = $hashedit.Save_status_textblock
            }
            return $new_Path_and_Name
          }else{
            write-ezlogs "Unable to verify existance of renamed file, something went wrong" -showtime -warning
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"File Rename Warning!","Unable to verify existance of renamed file, something went wrong! Check logs for details",$okandCancel,$Button_Settings)
            return
          }
        }else{
          write-ezlogs "File name cannot be blank!" -showtime -warning
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Missing Required Field!","File name cannot be blank, please update and try again!",$okandCancel,$Button_Settings)
          return
        }
      }catch{
        write-ezlogs "An exception occurred in FileName_Button.add_Click" -CatchError $_ -enablelogs
        if($okandCancel){
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"ERROR Renaming File!","An exception occurred when renaming file to $($FileTextBoxControl.text) - $($_ | out-string)",$okandCancel,$Button_Settings)
          write-ezlogs "| Dialogresult: $($dialogresult | out-string)" -showtime -warning
        }
      }     
    }

    $hashedit.FileName_Button.add_Click({
        try{ 
          Rename-LocalMediaFile -FileTextBoxControl $hashedit.Media_FileName_textbox -UpdateProfile -profile_Path $profile_Path        
        }catch{
          write-ezlogs "An exception occurred in FileName_Button.add_Click" -CatchError $_ -enablelogs
        }
    })
    #---------------------------------------------- 
    #endregion FileName_Button
    #----------------------------------------------     
 
 
    #---------------------------------------------- 
    #region Read_Tag_Button
    #----------------------------------------------
    $hashedit.Read_Tag_Button.add_Click({
        try{ 
          if($type -eq 'Local' -and [system.io.file]::Exists($hashedit.Media_FileName_textbox.tag)){
            $songinfo = Get-SongInfo -path $hashedit.Media_FileName_textbox.tag
            if($songinfo){
              write-ezlogs ">>>> Metadata from Get-SongInfo: $($songinfo | out-string)" -showtime -loglevel 2
              #Add-Member -InputObject $profile.Songinfo -Name "name" -Value $songInfo -MemberType NoteProperty -Force
              if($Songinfo.title){
                $profile.title = $Songinfo.title
              } 
              if(-not [string]::IsNullOrEmpty($songinfo.duration)){
                try{
                  $Timespan = [timespan]::Parse($songinfo.duration)
                  if($Timespan){
                    $updated_duration = "$(([string]$timespan.Hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
                  }                
                }catch{
                  write-ezlogs "An exception occurred parsing timespan for duration $duration" -showtime -catcherror $_
                  $error.clear()
                } 
                if($updated_duration){
                  $Profile.duration = $updated_duration
                }                                             
              }
              if($Songinfo.Artist){
                $Profile.artist = (Get-Culture).TextInfo.ToTitleCase($Songinfo.Artist).trim()          
              } 
              if($Songinfo.Album){
                $Profile.Album = (Get-Culture).TextInfo.ToTitleCase($Songinfo.Album).trim()          
              }
              if(-not [string]::IsNullOrEmpty($Songinfo.hasVideo)){
                $Profile.hasVideo = $Songinfo.hasVideo        
              }  
              if(-not [string]::IsNullOrEmpty($Songinfo.PictureData)){
                $Profile.PictureData = $Songinfo.PictureData       
              }                                                                  
              Update-Details -profile $profile -hashedit $hashedit -textFields $textFields -ValidFields $ValidFields -type $type
              if($songinfo.PictureData){
                $hashedit.MediaImage.Source=$null
                $hashedit.ImagePath.text = $null
                try{
                  $taginfo = [taglib.file]::create($hashedit.Media_FileName_textbox.tag) 
                }catch{
                  write-ezlogs "An exception occurred getting taginfo for $($hashedit.Media_FileName_textbox.tag)" -showtime -catcherror $_
                }
                if($taginfo.tag.pictures){
                  $tagimage = ($taginfo.tag.pictures | Select-Object -first 1).data.data
                  if($tagimage){
                    write-ezlogs " | Getting Cached image from taginfo type $($tagimage.gettype())" -showtime -loglevel 2
                    $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($profile.id).png")
                    if(([System.IO.File]::Exists($image_Cache_path))){
                      write-ezlogs " | Removing existing cached image $image_Cache_path" -loglevel 2
                      try{
                        $null = Remove-item -Path $image_Cache_path -Force
                      }catch{
                        write-ezlogs "An exception occurred removing cached image $image_Cache_path" -catcherror $_
                      }
                    }
                    try{
                      write-ezlogs " | Saving new cached image $($image_Cache_path)" -showtime -loglevel 2
                      $BinaryWriter = [System.IO.BinaryWriter]::new([System.IO.File]::create($image_Cache_path))
                      $BinaryWriter.Write($tagimage)
                      $BinaryWriter.Close()
                      $binarywriter.Dispose()
                      if(([System.IO.File]::Exists($image_Cache_path))){
                        $image = $image_Cache_path
                      }else{
                        $image = $null
                      }
                    }catch{
                      write-ezlogs "An exception occurred saving cached image $image_Cache_path" -catcherror $_
                    }                            
                  }
                }else{
                  $image = $null
                }
                $imageSource = $image  
                if(-not [string]::IsNullOrEmpty($image)){
                  $hashedit.MediaImage.Source=$image     
                  if(Test-ValidPath $imageSource -Type Any){
                    $hashedit.ImagePath.text = $imageSource       
                    Add-Member -InputObject $profile -Name "cached_image_path" -Value $imageSource -MemberType NoteProperty -Force       
                  }
                }                              
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Read_Tag_Button.add_Click" -CatchError $_ -enablelogs
        }
    })
    #---------------------------------------------- 
    #endregion Read_Tag_Button
    #----------------------------------------------
 
    #---------------------------------------------- 
    #region Change_Image_Button
    #----------------------------------------------
    $Null = $hashedit.Change_Image_Button.RemoveHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Open_Location_Command)
    $Null = $hashedit.Change_Image_Button.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$hashedit.Open_Location_Command)
    #---------------------------------------------- 
    #endregion Change_Image_Button
    #----------------------------------------------
                        
    #---------------------------------------------- 
    #region Apply Settings Button
    #----------------------------------------------
    $hashedit.Save_Profile_Button_Image.Source = "$($Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png"
    $hashedit.Save_Profile_Button_Image.Source.freeze()
    $hashedit.Save_Profile_Button.add_Click({
        try{          
          if($VerboseLog){write-ezlogs ">>>> Before Profile: $($Profile | out-string)" -showtime -VerboseDebug:$VerboseLog}
          $profile = $Profile | Select-Object *
          $hashedit.Profile_Editor_Progress_Ring.isActive = $true
          $hashedit.Editor_TabControl.isEnabled = $false
          if($type -eq 'Local'){
            #$All_LocalMedia_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-MediaProfile","All-Media-Profile.xml")
            if($synchash.MediaTable.ItemsSource.SourceCollection -and $syncHash.MediaTable.ItemsSource.SourceCollection.count -gt 0){
              $LibraryMediaProfile = ($syncHash.MediaTable.ItemsSource.SourceCollection.where({$_.id -eq $profile.id})) 
            }
          }elseif($type -eq 'Spotify'){
            if($synchash.All_Spotify_Media.count -gt 0){
              #$LibraryMediaProfile = $synchash.All_Spotify_Media[$profile.id]
              $LibraryMediaProfile = $synchash.All_Spotify_Media.where({$_.id -eq $profile.id})
            }elseif($synchash.SpotifyTable.ItemsSource.SourceCollection -and $syncHash.SpotifyTable.ItemsSource.SourceCollection.count -gt 0){
              $LibraryMediaProfile = ($syncHash.SpotifyTable.ItemsSource.SourceCollection.where({$_.id -eq $profile.id})) 
            }                      
          }elseif($type -eq 'Youtube'){
            #$AllYoutube_Media_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Youtube_MediaProfile","All-Youtube_Media-Profile.xml") 
            if($synchash.YoutubeTable.ItemsSource.SourceCollection -and $syncHash.YoutubeTable.ItemsSource.SourceCollection.count -gt 0){
              $LibraryMediaProfile = ($syncHash.YoutubeTable.ItemsSource.SourceCollection.where({$_.id -eq $profile.id}))  
            }       
          }elseif($type -eq 'Twitch'){
            $AllTwitch_Media_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Twitch_MediaProfile","All-Twitch_Media-Profile.xml") 
            if($syncHash.TwitchTable.ItemsSource.SourceCollection.count -gt 0){
              $LibraryMediaProfile = ($syncHash.TwitchTable.ItemsSource.SourceCollection.where({$_.id -eq $profile.id})) 
            }                 
          } 
          if(@($LibraryMediaProfile).count -gt 1){
            $LibraryMediaProfile = ($LibraryMediaProfile | Where-Object {$_.Playlist_ID -eq $media_to_edit.Playlist_ID}) | Select-Object *
          }
          if(!$LibraryMediaProfile){
            write-ezlogs "Unable to find media to edit in library profiles, media may be orphaned!" -showtime -Warning
            $LibraryMediaProfile = $media_to_edit
          }   
                                
          #Title        
          if(-not [string]::IsNullOrEmpty($hashedit.Media_title_textbox.text)){
            $TitleValue = ($hashedit.Media_title_textbox.text).trim()
          }else{
            $TitleValue = $Null
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Missing Required Field!","The title field cannot be blank, please update and try again",$okandCancel,$Button_Settings)
            return
          }
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "title" -Value $TitleValue -MemberType NoteProperty -Force
            }#>
            <#            if($Media_to_edit.SongInfo.title){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "title" -Value $TitleValue -MemberType NoteProperty -Force
            }#>
          }         
          if($profile.id){
            $profile.title = $TitleValue
            #Add-Member -InputObject $profile -Name "name" -Value $TitleValue -MemberType NoteProperty -Force
          }                                      
          if($Media_to_edit.id){
            $Media_to_edit.title = $TitleValue
            #Add-Member -InputObject $Media_to_edit -Name "name" -Value $TitleValue -MemberType NoteProperty -Force
          } 
          if($LibraryMediaProfile.id){
            foreach($media in $LibraryMediaProfile){
              $media.title = $TitleValue
              #$media.name = $TitleValue        
            }
          }                       
          #Artist        
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Artist_textbox.text)){
            $ArtistValue = ($hashedit.Media_Artist_textbox.text).trim()
          }else{
            $ArtistValue = $Null
          }
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "Artist" -Value $ArtistValue -MemberType NoteProperty -Force
                }
                if($Media_to_edit.SongInfo){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "Artist" -Value $ArtistValue -MemberType NoteProperty -Force
            }#>  
          }   
          if($profile.Artist){
            $profile.Artist = $ArtistValue
          }               
          if($Media_to_edit.id){
            $Media_to_edit.Artist = $ArtistValue
          }
          if($LibraryMediaProfile.id){
            foreach($media in $LibraryMediaProfile){
              $media.Artist = $ArtistValue    
            }
            write-ezlogs "Updating librarymediaprofile artist $($ArtistValue)" -showtime
          }
          if($type -eq 'Spotify'){
            if($profile.artists){
              Add-Member -InputObject $profile.artists -Name "Name" -Value $ArtistValue -MemberType NoteProperty -Force
            }
            if($Media_to_edit.artists){
              Add-Member -InputObject $Media_to_edit.artists -Name "Name" -Value $ArtistValue -MemberType NoteProperty -Force
            }
          } 
          if($type -eq 'Twitch'){
            if($profile){
              Add-Member -InputObject $profile -Name "Channel_Name" -Value $ArtistValue -MemberType NoteProperty -Force 
            }               
            if($Media_to_edit){
              Add-Member -InputObject $Media_to_edit -Name "Channel_Name" -Value $ArtistValue -MemberType NoteProperty -Force 
            }
          }                                           
         
          #Album        
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Album_textbox.text)){
            $AlbumValue = ($hashedit.Media_Album_textbox.text).trim()
          }else{
            $AlbumValue = $null
          } 
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "Album" -Value $AlbumValue -MemberType NoteProperty -Force
                }
                if($Media_to_edit.SongInfo){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "Album" -Value $AlbumValue -MemberType NoteProperty -Force
            } #>                      
          }
          if($type -eq 'Spotify'){
            if($profile.Album_Info){
              Add-Member -InputObject $profile.Album_Info -Name "Name" -Value $AlbumValue -MemberType NoteProperty -Force
            }
            if($Media_to_edit.Album_Info){
              Add-Member -InputObject $Media_to_edit.Album_Info -Name "Name" -Value $AlbumValue -MemberType NoteProperty -Force
            }
          }
          if($profile.id){
            $profile.Album = $AlbumValue
          }         
          if($Media_to_edit.id){
            $Media_to_edit.Album = $AlbumValue
          } 
          if($LibraryMediaProfile.id){
            foreach($media in $LibraryMediaProfile){
              $media.Album = $AlbumValue    
            }
          }                                         
          #Track
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Track_textbox.text)){
            $TrackValue = ($hashedit.Media_Track_textbox.text).trim()
          }else{
            $TrackValue = $Null
          }
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "TrackNumber" -Value $TrackValue -MemberType NoteProperty -Force
                }
                if($Media_to_edit.SongInfo){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "TrackNumber" -Value $TrackValue -MemberType NoteProperty -Force
            }#>
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                $media.Track = $TrackValue    
              }
            }
            <#            if($LibraryMediaProfile.SongInfo.TrackNumber){
                foreach($media in $LibraryMediaProfile){
                $media.SongInfo.TrackNumber = $TrackValue    
                }
                #$LibraryMediaProfile.SongInfo.TrackNumber = $hashedit.Media_Track_textbox.text
                #Add-Member -InputObject $LibraryMediaProfile.SongInfo -Name "TrackNumber" -Value $hashedit.Media_Track_textbox.text -MemberType NoteProperty -Force
            }#>
            Add-Member -InputObject $profile -Name "Track" -Value $TrackValue -MemberType NoteProperty -Force
            Add-Member -InputObject $Media_to_edit -Name "Track" -Value $TrackValue -MemberType NoteProperty -Force
          }
          if($type -eq 'Spotify' -or $type -eq 'Youtube'){    
            if($profile.id){
              Add-Member -InputObject $profile -Name "track" -Value $hashedit.Media_Track_textbox.text -MemberType NoteProperty -Force
            }         
            if($Media_to_edit.id){
              Add-Member -InputObject $Media_to_edit -Name "track" -Value $hashedit.Media_Track_textbox.text -MemberType NoteProperty -Force
            } 
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                $media.track = $hashedit.Media_Track_textbox.text  
              }
            }                           
          }                                                     
          #Disc
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Disc_textbox.text)){
            $discValue = ($hashedit.Media_Disc_textbox.text).trim()
          }else{
            $discValue = $Null
          }  
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "DiscNumber" -Value $discValue -MemberType NoteProperty -Force
                }
                if($Media_to_edit.SongInfo){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "DiscNumber" -Value $discValue -MemberType NoteProperty -Force
            }#>
            <#            if($LibraryMediaProfile.id){
                foreach($media in $LibraryMediaProfile){
                Add-Member -InputObject $media -Name "Disc" -Value $discValue -MemberType NoteProperty -Force
                }
            }#>
            <#            if(-not [string]::IsNullOrEmpty($LibraryMediaProfile.SongInfo.DiscNumber)){
                foreach($media in $LibraryMediaProfile){
                Add-Member -InputObject $media.SongInfo -Name "DiscNumber" -Value $discValue -MemberType NoteProperty -Force  
                }
            }#>
            #Add-Member -InputObject $profile -Name "Disc" -Value $discValue -MemberType NoteProperty -Force
            #Add-Member -InputObject $Media_to_edit -Name "Disc" -Value $discValue -MemberType NoteProperty -Force
          }
          <#          if($type -eq 'Spotify' -or $type -eq 'Youtube'){    
              if($profile.id){
              Add-Member -InputObject $profile -Name "Disc_number" -Value $discValue -MemberType NoteProperty -Force
              }         
              if($Media_to_edit.id){
              Add-Member -InputObject $Media_to_edit -Name "Disc_number" -Value $discValue -MemberType NoteProperty -Force
              } 
              if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
              Add-Member -InputObject $media -Name "Disc_number" -Value $discValue -MemberType NoteProperty -Force
              }
              }                           
          }#>                                                     
                 
          #Year
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Year_textbox.text)){
            $YearValue = ($hashedit.Media_Year_textbox.text).trim()
          }else{
            $YearValue = $Null
          }
          if($type -eq 'Local'){
            <#            if($profile.SongInfo){
                Add-Member -InputObject $profile.SongInfo -Name "Year" -Value $YearValue -MemberType NoteProperty -Force
                }
                if($Media_to_edit.SongInfo){
                Add-Member -InputObject $Media_to_edit.SongInfo -Name "Year" -Value $YearValue -MemberType NoteProperty -Force
            }#>
            <#            if($LibraryMediaProfile.SongInfo){
                foreach($media in $LibraryMediaProfile){
                write-ezlogs "media.SongInfo.Year $($media.SongInfo.Year)" -showtime                 
                $media.SongInfo.Year = $YearValue
                #Add-Member -InputObject $media.SongInfo -Name "Year" -Value $hashedit.Media_Year_textbox.text -MemberType NoteProperty -Force
                }
            }#>                                                            
          }
          <#          if($type -eq 'Spotify'){
              if($profile.release_date){
              Add-Member -InputObject $profile -Name "release_date" -Value $YearValue -MemberType NoteProperty -Force
              }
              if($Media_to_edit.release_date){
              Add-Member -InputObject $Media_to_edit -Name "release_date" -Value $YearValue -MemberType NoteProperty -Force
              }                          
          }#>
          #youtube doesnt have year, so create new property
          <#          if($type -eq 'Youtube'){
              if($profile.id){
              Add-Member -InputObject $profile -Name "Year" -Value $YearValue -MemberType NoteProperty -Force
              }         
              if($Media_to_edit.id){
              Add-Member -InputObject $Media_to_edit -Name "Year" -Value $YearValue -MemberType NoteProperty -Force
              }
              if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
              Add-Member -InputObject $media -Name "Year" -Value $YearValue -MemberType NoteProperty -Force
              }
              #Add-Member -InputObject $LibraryMediaProfile -Name "Year" -Value $hashedit.Media_Year_textbox.text -MemberType NoteProperty -Force
              }                           
          }#>         
       
          #Description
          $RichTextRange2 = [System.Windows.Documents.textrange]::new($hashedit.Media_Description_textbox.Document.ContentStart, $hashedit.Media_Description_textbox.Document.ContentEnd)
          if(-not [string]::IsNullOrEmpty($RichTextRange2.text)){
            $DescriptionValue = ($RichTextRange2.text).trim()
          }else{
            $DescriptionValue = $Null
          } 
          if($type -eq 'Local'){
            if($profile){
              $profile.Description = $DescriptionValue
            }         
            if($Media_to_edit){
              $Media_to_edit.Description = $DescriptionValue
            }
            if($LibraryMediaProfile){
              foreach($media in $LibraryMediaProfile){              
                $media.Description = $DescriptionValue
              }
            }                                                            
          }
          if($type -eq 'Spotify'){
            if($profile){
              Add-Member -InputObject $profile -Name "Description" -Value $DescriptionValue -MemberType NoteProperty -Force
            }
            if($Media_to_edit){
              Add-Member -InputObject $Media_to_edit -Name "Description" -Value $DescriptionValue -MemberType NoteProperty -Force
            }                          
          }
          if($type -eq 'Youtube'){
            if($profile.id){
              Add-Member -InputObject $profile -Name "Description" -Value $DescriptionValue -MemberType NoteProperty -Force
            }         
            if($Media_to_edit.id){
              Add-Member -InputObject $Media_to_edit -Name "Description" -Value $DescriptionValue -MemberType NoteProperty -Force
            }
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                Add-Member -InputObject $media -Name "Description" -Value $DescriptionValue -MemberType NoteProperty -Force
              }
            }                           
          }         
                   
          #FileName
          if(-not [string]::IsNullOrEmpty($hashedit.Media_FileName_textbox.text) -and $type -eq 'Local'){
            $filename = Rename-LocalMediaFile -FileTextBoxControl $hashedit.Media_FileName_textbox -profile_Path $profile_Path
            if([system.io.file]::Exists($filename)){
              if($profile){
                Add-Member -InputObject $profile -Name "url" -Value $filename -MemberType NoteProperty -Force
              }
              if($Media_to_edit){
                Add-Member -InputObject $Media_to_edit -Name "url" -Value $filename -MemberType NoteProperty -Force
              }
              if($LibraryMediaProfile.id){
                foreach($media in $LibraryMediaProfile){
                  $media.url = $filename    
                }
              } 
            }elseif($filename){
              write-ezlogs " | FileName/URL is the same" -showtime
              if(-not [string]::IsNullOrEmpty($hashedit.Media_url_textbox.text)){
                if($profile.url -ne $hashedit.Media_url_textbox.text){
                  write-ezlogs " | Changing profile.url from $($profile.url) to $($hashedit.Media_url_textbox.text)" -showtime
                  Add-Member -InputObject $profile -Name "url" -Value $hashedit.Media_url_textbox.text -MemberType NoteProperty -Force
                }
                if($Media_to_edit.url -ne $hashedit.Media_url_textbox.text){
                  write-ezlogs " | Changing Media_to_edit.url from $($Media_to_edit.url) to $($hashedit.Media_url_textbox.text)" -showtime
                  Add-Member -InputObject $Media_to_edit -Name "url" -Value $hashedit.Media_url_textbox.text -MemberType NoteProperty -Force
                }
                if($LibraryMediaProfile.id){
                  foreach($media in $LibraryMediaProfile){
                    if($media.url -ne $hashedit.Media_url_textbox.text){
                      write-ezlogs " | Changing LibraryMediaProfile from $($media.url) to $($hashedit.Media_url_textbox.text)" -showtime
                      Add-Member -InputObject $media -Name "url" -Value $hashedit.Media_url_textbox.text -MemberType NoteProperty -Force
                    }
                  }
                }
              }
            }else{
              write-ezlogs "Invalid file name (or doesnt exist) returned from Rename-LocalMediaFile: $($filename)" -showtime -warning
              return
            }
          } 
          #URL 
          if($type -ne 'Local'){
            if(-not [string]::IsNullOrEmpty($hashedit.Media_EditURL_textbox.text) -and ((Test-URL $hashedit.Media_EditURL_textbox.text) -or $hashedit.Media_EditURL_textbox.text -match 'spotify\:')){
              $urlValue = ($hashedit.Media_EditURL_textbox.text).trim()
            }else{
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid URL!","The URL property is required and must be a valid web URL for $type!",$okandCancel,$Button_Settings)
              return           
            }          
          }       
          if($type -eq 'Spotify'){
            if($urlValue -match "playlist\:"){
              $spotify_id = $null        
            }elseif($urlValue -match "track\:"){
              $spotify_id = ($($urlValue) -split('track:'))[1].trim()                    
            }elseif($urlValue -match "open.spotify.com\/track\/"){
              $spotify_id = ($($urlValue) -split('open.spotify.com/track/'))[1].trim()                                   
            }else{
              $spotify_id = $null
            }
            if([string]::IsNullOrEmpty($spotify_id)){
              write-ezlogs "Unable to find Spotify ID within provided url $($urlValue)" -showtime -warning -loglevel 2
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid Spotify URL!","Unable to find Spotify ID within the provided url $($urlValue)`n`nSpotify URls must match one of the following formats:`n - spotify:track:5QLHGv0DfpeXLNFo7SFEy1`n - https://open.spotify.com/track/5QLHGv0DfpeXLNFo7SFEy1",$okandCancel,$Button_Settings)
              return
            }else{
              $uri_property = "spotify:track:$spotify_id"
              $weburl_property = "https://open.spotify.com/track/$spotify_id"
              $old_Spotify_id = $Media_to_edit.id
            }
            if($profile){
              Add-Member -InputObject $profile -Name "url" -Value $uri_property -MemberType NoteProperty -Force
              #Add-Member -InputObject $profile -Name "uri" -Value $uri_property -MemberType NoteProperty -Force             
              #Add-Member -InputObject $profile -Name "External_url" -Value $weburl_property -MemberType NoteProperty -Force             
              if($profile.external_urls){
                #Add-Member -InputObject $profile.external_urls -Name "spotify" -Value $weburl_property -MemberType NoteProperty -Force
              }
              #Add-Member -InputObject $profile -Name "id" -Value $spotify_id -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "Spotify_id" -Value $spotify_id -MemberType NoteProperty -Force
            }
            if($Media_to_edit){
              Add-Member -InputObject $Media_to_edit -Name "url" -Value $uri_property -MemberType NoteProperty -Force
              #Add-Member -InputObject $Media_to_edit -Name "uri" -Value $uri_property -MemberType NoteProperty -Force          
              #Add-Member -InputObject $Media_to_edit -Name "External_url" -Value $weburl_property -MemberType NoteProperty -Force             
              if($Media_to_edit.external_urls){
                #Add-Member -InputObject $Media_to_edit.external_urls -Name "spotify" -Value $weburl_property -MemberType NoteProperty -Force
              }
              #Add-Member -InputObject $Media_to_edit -Name "id" -Value $spotify_id -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "Spotify_id" -Value $spotify_id -MemberType NoteProperty -Force
            }
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                $media.url = $uri_property 
                $media.Spotify_id = $spotify_id  
                #$media.uri = $uri_property
              }
            }
          }
          if($type -eq 'Youtube'){
            if($urlValue -match 'youtube\.com' -or $urlValue -match 'youtu\.be'){
              <#              if($urlValue -match '\/tv\.youtube\.com\/'){
                  if($urlValue -match '\%3D\%3D'){
                  $urlValue = $urlValue -replace '\%3D\%3D'
                  }
                  if($urlValue -match '\?vp='){
                  $youtube_vp = ($($urlValue) -split('\?vp='))[1].trim()
                  $youtube_id = [regex]::matches($urlValue, "tv.youtube.com\/watch\/(?<value>.*)\?vp\=")| %{$_.groups[1].value}
                  }elseif($urlValue -match '\?v='){
                  $youtube_id = [regex]::matches($urlValue, "tv.youtube.com\/watch\?v=(?<value>.*)")| %{$_.groups[1].value}
                  }elseif($urlValue){
                  $youtube_id = [regex]::matches($urlValue, "tv.youtube.com\/watch\/(?<value>.*)")| %{$_.groups[1].value}
                  }
                  $youtube_type = 'YoutubeTV'   
                  }elseif($urlValue -match "v="){
                  $youtube_id = ($($urlValue) -split('v='))[1].trim()  
                  $youtube_type = 'Video' 
                  write-ezlogs " | Youtube type: Video" -showtime -logtype Youtube -loglevel 3        
                  }elseif($urlValue -match 'list='){
                  $youtube_id = ($($urlValue) -split('list='))[1].trim()    
                  $youtube_type = 'Playlist'                      
                  }elseif($urlValue -match '\/channel\/'){
                  if($urlValue -match '\/videos'){
                  $playlist = $playlist -replace '\/videos'
                  }
                  $youtube_id = ($($playlist) -split('\/channel\/'))[1].trim() 
                  $youtube_type = 'Channel'   
                  }elseif($urlValue -match "\/watch\/"){
                  $youtube_id = [regex]::matches($urlValue, "\/watch\/(?<value>.*)")| %{$_.groups[1].value}
                  $youtube_type = 'Video'
                  }elseif($urlValue -notmatch "v=" -and $urlValue -notmatch '\?' -and $urlValue -notmatch '\&'){
                  $youtube_id = (([uri]$urlValue).segments | select -last 1) -replace '/',''
                  $youtube_type = 'Video'
              }#>
              $youtube = Get-YoutubeURL -thisApp $thisApp -URL $urlValue
            }
            if(!$youtube.url -or (!$youtube.id -and !$youtube.playlist_id)){
              write-ezlogs "Unable to find Youtube ID within provided url $($urlValue)" -showtime -warning -loglevel 2
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $message = "Unable to find Youtube ID within the provided url $($urlValue)"
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid Youtube URL!","$message`n`nYoutube track URls must match one of the following formats:`n - https://www.youtube.com/watch?v=ormQQG2UhtQ`n - https://www.youtube.com/watch/ormQQG2UhtQ`n - https://tv.youtube.com/watch/ormQQG2UhtQ`n - https://tv.youtube.com/watch?v=ormQQG2UhtQ`n - All above but domain as youtu.be vs youtube.com",$okandCancel,$Button_Settings)
              return
            }else{
              #[uri]$url_property = $urlValue
              $urlValue = $youtube.url
              $old_youtube_id = $Media_to_edit.id    
              if($youtube.id){
                $youtube_id = $youtube.id   
              }elseif($youtube.playlist_id){
                $youtube_id = $youtube.playlist_id
              }            
            }
            if($profile){
              $profile.url = $urlValue
              $profile.id = $youtube_id
            }
            if($Media_to_edit){
              $Media_to_edit.url = $urlValue
              $Media_to_edit.id = $youtube_id
            }
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                $media.url = $urlValue
                $media.id = $youtube_id
              }
            }
          }
          if($type -eq 'Twitch'){
            if($urlvalue -match 'twitch.tv'){
              $twitch_channel = $((Get-Culture).textinfo.totitlecase(($urlValue | split-path -leaf).tolower()))
            }
            if($urlvalue -notmatch 'twitch.tv' -or $twitch_channel -match 'Twitch.Tv' -or [string]::IsNullOrEmpty($twitch_channel)){
              write-ezlogs "Invalid Twitch URL provided $($urlValue)" -showtime -warning -loglevel 2
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              if($twitch_channel -match 'twitch.tv' -or $urlvalue -notmatch 'twitch.tv'){
                $message = "The provided URL is not a twitch channel: $($urlValue)"
              }else{
                $message = "Unable to determine the twitch channel from provided url: $($urlValue)"
              }
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"Invalid Twitch URL!","$message`n`nTwitch channel URls must match the following format:`n - https://www.twitch.tv/pepp",$okandCancel,$Button_Settings)
              return
            }else{
              $chat_url = "https://twitch.tv/$($twitch_channel)/chat"
            }   
            if($profile){
              Add-Member -InputObject $profile -Name "url" -Value $urlValue -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "chat_url" -Value $chat_url -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "Playlist_URL" -Value $urlValue -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "Channel_Name" -Value $twitch_channel -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "Playlist" -Value $twitch_channel -MemberType NoteProperty -Force
              Add-Member -InputObject $profile -Name "Name" -Value $twitch_channel -MemberType NoteProperty -Force            
            }
            if($Media_to_edit){
              Add-Member -InputObject $Media_to_edit -Name "url" -Value $urlValue -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "chat_url" -Value $chat_url -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "Playlist_URL" -Value $urlValue -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "Channel_Name" -Value $twitch_channel -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "Playlist" -Value $twitch_channel -MemberType NoteProperty -Force
              Add-Member -InputObject $Media_to_edit -Name "Name" -Value $twitch_channel -MemberType NoteProperty -Force
            }
            if($LibraryMediaProfile.id){
              foreach($media in $LibraryMediaProfile){
                $media.url = $urlValue    
                $media.chat_url = $chat_url
                $media.Playlist_URL = $urlValue
                $media.Channel_Name = $twitch_channel
                $media.Playlist = $twitch_channel
                $media.Name = $twitch_channel
              }
            }
          } 
          Add-Member -InputObject $profile -Name "Profile_Date_Modified" -Value $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt') -MemberType NoteProperty -Force   
          try{
            if(-not [string]::IsNullOrEmpty($old_Spotify_id)){
              $Lookup_id = $old_Spotify_id
            }elseif(-not [string]::IsNullOrEmpty($old_youtube_id)){
              $Lookup_id = $old_youtube_id
            }else{
              $Lookup_id = $media_to_edit.id
            }
            if($profile_Path){
              write-ezlogs ">>>> Saving All Media Profile to $($profile_Path)" -loglevel 2    
              Export-SerializedXML -InputObject $All_Media_Profile -path $profile_Path            
            }      
          }catch{
            write-ezlogs "Exception Saving profile to $($profile_Path)" -showtime -catcherror $_
          }          
          if($LibraryMediaProfile){
            write-ezlogs " | Updated Library Media Profile: $($LibraryMediaProfile | out-string)" -showtime -loglevel 3
          }else{
            write-ezlogs "Could not find Library Media Profile to update!" -showtime -warning
          }                                                           
          try{
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
            #Export-Clixml -InputObject $thisapp.config -path $thisapp.config.Config_Path -Force -Encoding UTF8
          }catch{
            write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
          }

          #$synchash.Import_Playlists_Cache = $false
          Update-Playlist -media $profile -media_lookupid $Lookup_id -synchash $synchash -thisApp $thisApp -Updateall     
          $synchash.update_status_timer.tag = $type             
          $synchash.update_status_timer.start()               
 
          if($type -eq 'Local' -and $thisApp.Config.Profile_Write_IDTags){
            try{
              Write-IDTags -synchash $synchash -thisApp $thisApp -media $profile -FilePath $profile.url -hashedit $hashedit
            }catch{
              write-ezlogs "An exception occurred executing Write-IDTags" -showtime -catcherror $_
            }
          }  
          $hashedit.Editor_TabControl.isEnabled = $true 
          $hashedit.Profile_Editor_Progress_Ring.isActive = $false                                  
          $hashedit.Save_status_transitioningControl.content = ""
          $hashedit.Save_status_textblock.text = "Saved Profile Successfully!"
          $hashedit.Save_status_textblock.foreground = "LightGreen"
          $hashedit.Save_status_transitioningControl.content = $hashedit.Save_status_textblock     
        }catch{
          #$hashedit.Profile_Editor_Progress_Ring.isActive = $false
          #$hashedit.Editor_TabControl.isEnabled = $true
          #$hashedit.Save_status_textblock.text = "An exception occurred when saving the profile!`n$_"
          #$hashedit.Save_status_textblock.foreground = "Red"
          write-ezlogs "An exception occurred when saving the profile: $($profile_Path)" -CatchError $_ -showtime
          update-EditorHelp -Header 'SAVE ERROR' -RichTextBoxControl $hashedit.EditorHelpFlyout -color Tomato -Clear
          update-EditorHelp -content "An exception occurred when saving the profile: $($profile_Path)" -RichTextBoxControl $hashedit.EditorHelpFlyout -color Tomato -Open
        }
    })
    #---------------------------------------------- 
    #endregion Apply Settings Button
    #----------------------------------------------    
    
    $hashedit.Window.Add_loaded({
        try{
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($hashedit.Window)         
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID 
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }     
          $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
          $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)
        }catch{
          write-ezlogs "An exception occurred in hashedit.window.add_loaded" -catcherror $_ 
        }
    })

    $hashedit.Cancel_Setup_Button.add_click({
        param($Sender)  
        try{
          write-ezlogs ">>>> Canceling ProfileEditor" -showtime
          Close-ProfileEditor                 
        }catch{
          write-ezlogs "An exception occurred in Cancel_Setup_Button.add_click" -showtime -catcherror $_
        } 
    })
    $hashedit.ProfileEditor.add_Unloaded({  
        param($Sender)  
        try{
          write-ezlogs ">>>> Exiting application context thread for profile editor" -showtime
          if($hashedit.appContext){
            $hashedit.appContext.ExitThread()
            $hashedit.appContext.dispose()       
            $hashedit.appContext = $Null     
          }
          $hashedit.Window = $Null
          write-ezlogs "Profile editor unloaded" -loglevel 2 -GetMemoryUsage -forceCollection                      
        }catch{
          write-ezlogs "An exception occurred in ProfileEditor.add_Unloaded" -showtime -catcherror $_
        } 
    })     
    $hashedit.ProfileEditor.add_closed({     
        param($Sender)          
        try{  
          $hashedit.EditorHelpFlyout = $Null 
          $this = $Null          
        }catch{
          write-ezlogs "An exception occurred closing Show-ProfileEditor window" -showtime -catcherror $_
        }
        try{
          #$synchash.window.Dispatcher.Invoke("Normal",[action]{ $window_active = $synchash.Window.Activate()  })         
        }catch{
          write-ezlogs "An exception occurred closing Show-ProfileEditor window" -showtime -catcherror $_
        }      
    })   
  
    try{    
      [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashedit.Window)
      [void][System.Windows.Forms.Application]::EnableVisualStyles()   
      $null = $hashedit.Window.Show()
      $Null = $hashedit.Window.Activate()     
      $hashedit.appContext = [System.Windows.Forms.ApplicationContext]::new()
      [void][System.Windows.Forms.Application]::Run($hashedit.appContext)     
    }catch{
      write-ezlogs "An exception in Show-ProfileEditor screen show dialog" -showtime -catcherror $_
      [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occurred showing the Profile Editor Window. Recommened reviewing logs for details.`n`n$($_ | out-string)","[ERROR]- $($thisApp.Config.App_name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
      switch ($oReturn){
        "OK" {
        } 
      }
      return 
    }
  }
  try{    
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    $Null = Start-Runspace $hashedit_Scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name 'Show_ProfileEditor_Runspace' -logfile $thisApp.Config.Log_File -verboselog:$thisApp.Config.Verbose_logging -thisApp $thisApp  
    $Variable_list = $Null
  }catch{
    write-ezlogs "An exception occurred starting ProfileEditor_Runspace" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Show-ProfileEditor Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-ProfileEditor','Close-ProfileEditor')