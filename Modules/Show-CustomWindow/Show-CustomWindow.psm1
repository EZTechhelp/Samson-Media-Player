<#
    .Name
    Show-CustomWindow

    .Version 
    0.2.1

    .SYNOPSIS
    Displays simple XAML window for use as a pop-up, dialog, capture and other purposes

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
    #TODO: This module needs full rebuild/refactor
#>

#---------------------------------------------- 
#region Show-CustomWindow Function
#----------------------------------------------
function Show-CustomWindow{
  [CmdletBinding()]
  Param (
    [string]$WindowTitle,
    [string]$WindowLogo,
    [string]$HeaderLogo,
    [string]$WindowMaxHeight,
    [string]$HeaderText,
    [string]$Message,
    [ValidateSet('Top','Bottom','Center','Stretch')]
    [string]$MessageTextVAlign,
    [ValidateSet('Left','Right','Center','Justify')]
    [string]$MessageTextHAlign,
    [string]$MarkDownFile,
    $OkActionScriptBlock,
    $CustomWindow_hash = $CustomWindow_hash,
    [string]$Message_2,
    [ValidateSet('Info','YesNo','OkCancel','Options')]
    [string]$Type,
    [switch]$UseRunspace,
    [switch]$WaitforOutput,
    [switch]$TopMost,
    $Options,
    [string]$OptionsHeader,
    [switch]$Verboselog = $thisApp.Config.Dev_mode,
    $thisApp = $thisApp,
    $synchash = $synchash
  )  

  if($CustomWindow_hash.Window.isVisible){
    write-ezlogs "Custom window is already open - activating" -Warning
    $CustomWindow_hash.Window.Dispatcher.Invoke([Action]{$CustomWindow_hash.Window.Activate()},'Normal')
    return
  }
  if($PSBoundParameters["CustomWindow_hash"] -isnot [hashtable]){
    $PSBoundParameters["CustomWindow_hash"] = [hashtable]::Synchronized(@{})
  }
  if($CustomWindow_hash -isnot [hashtable]){
    $CustomWindow_hash = [hashtable]::Synchronized(@{})
  }

  $CustomWindow_Pwshell = {
    [CmdletBinding()]
    Param (
      [string]$WindowTitle,
      [string]$WindowLogo,
      [string]$HeaderLogo,
      [string]$WindowMaxHeight,
      [string]$HeaderText,
      [string]$Message,
      [string]$MessageTextVAlign,
      [String]$MessageTextHAlign,
      [string]$MarkDownFile,
      $OKActionScriptBlock,
      $CustomWindow_hash,
      [string]$Message_2,
      [string]$Type,
      [switch]$UseRunspace,
      [switch]$WaitforOutput,
      [switch]$TopMost,
      $Options,
      [string]$OptionsHeader,
      [switch]$Verboselog,
      $thisApp,
      $synchash
    )
    try{
      $CustomWindowLoad_Measure = [system.diagnostics.stopwatch]::StartNew()
      $Current_Folder = "$($thisApp.Config.Current_Folder)"
      $CustomWindow_XML = "$($Current_Folder)\Views\CustomWindow.xaml"
      $xaml = [System.IO.File]::ReadAllText($CustomWindow_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      $CustomWindow_hash.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $CustomWindow_hash.Window){
          $CustomWindow_hash."$($name)" = [System.WeakReference]::new(($CustomWindow_hash.Window.FindName($name))).Target
        }
      }
      $reader.Dispose()
      if($CustomWindow_hash.window){
        $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
        if($WindowMaxHeight){
          $CustomWindow_hash.window.MaxHeight = $WindowMaxHeight
        }else{
          $CustomWindow_hash.window.MaxHeight=$PrimaryMonitor.WorkingArea.Height
        }
        $CustomWindow_hash.Window.IsWindowDraggable="True" 
        $CustomWindow_hash.Window.ShowTitleBar=$true
        $CustomWindow_hash.Window.UseNoneWindowStyle = $false
        $CustomWindow_hash.Window.WindowStyle = 'none'
        $CustomWindow_hash.Window.Style = $CustomWindow_hash.Window.TryFindResource('WindowChromeStyle')
        $CustomWindow_hash.Window.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"
        $CustomWindow_hash.Window.TopMost = [bool]$TopMost       
        $CustomWindow_hash.Window.icon.freeze()
        if($WindowTitle){
          $CustomWindow_hash.window.title = $WindowTitle
        }
        if($CustomWindow_hash.Logo){
          if($WindowLogo){
            $CustomWindow_hash.Logo.Source = $WindowLogo
          }else{
            $CustomWindow_hash.Logo.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png"
          }  
        }
        if($HeaderLogo -and $CustomWindow_hash.HeaderLogo){
          $CustomWindow_hash.HeaderLogo.Source = $HeaderLogo
        }
        if($HeaderText -and $CustomWindow_hash.HeaderText){
          $CustomWindow_hash.HeaderText.Content = $HeaderText
        }elseif($CustomWindow_hash.Header -and !$HeaderLogo){
          write-ezlogs ">>>> No Header logo or text provided - hiding header..." -LogLevel 0 -Verboselog:$VerboseLog
          $CustomWindow_hash.Header.Visibility = 'Collapsed'
          if($CustomWindow_hash.ContentGrid){
            $CustomWindow_hash.ContentGrid.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
            $CustomWindow_hash.ContentGrid.SetValue([System.Windows.Controls.Grid]::RowSpanProperty,3)
          }
        }
        if($CustomWindow_hash.window.TaskbarItemInfo){
          $CustomWindow_hash.window.TaskbarItemInfo.Description = "$WindowTitle - $($thisApp.Config.App_Name) Media Player - Version: $($thisApp.Config.App_Version)"
        }   
        if($CustomWindow_hash.Window.LeftWindowCommandsOverlayBehavior){
          $CustomWindow_hash.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
          $CustomWindow_hash.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
        }
        #region BackgroundTile
        if($CustomWindow_hash.Background_TileGrid){
          $SettingsBackground = [System.Windows.Media.ImageBrush]::new()
          $settingsBackground.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTop.png"
          $settingsBackground.ViewportUnits = "Absolute"
          $settingsBackground.Viewport = "0,0,600,263"
          $settingsBackground.TileMode = 'Tile'
          $SettingsBackground.Freeze()
          $CustomWindow_hash.Window.Background = $SettingsBackground
          $CustomWindow_hash.Background_Image_Bottom.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowBottom.png"
          $CustomWindow_hash.Background_Image_Bottom.Source.Freeze()                  
          $imagebrush = [System.Windows.Media.ImageBrush]::new()
          $ImageBrush.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png"
          $imagebrush.TileMode = 'Tile'
          $imagebrush.ViewportUnits = "Absolute"
          $imagebrush.Viewport = "0,0,600,283"
          $imagebrush.ImageSource.freeze()
          $CustomWindow_hash.Background_TileGrid.Background = $imagebrush  
        }
        #endregion BackgroundTile

        if($CustomWindow_hash.MarkdownScrollViewer){
          if($Message_2){
            $message = "$message`n`n$Message_2"
          }    
          if([system.io.file]::Exists($MarkDownFile)){
            write-ezlogs ">>>> Opening Markdown Help File: $MarkDownFile"
            $Message += "`n`n" + ([system.io.file]::ReadAllText($MarkDownFile) -replace '\[USERNAME\]',$env:USERNAME -replace '\[appname\]',$thisApp.Config.App_Name -replace '\[appversion\]',$thisApp.Config.App_Version -replace '\[CURRENTFOLDER\]',$thisApp.Config.Current_Folder)
          }
          if($Message){
            try{
              $CustomWindow_hash.MarkdownScrollViewer.Markdown = $Message
              if($MessageTextVAlign){
                $CustomWindow_hash.MarkdownScrollViewer.VerticalContentAlignment = $MessageTextVAlign
                $CustomWindow_hash.MarkdownScrollViewer.VerticalAlignment = $MessageTextVAlign
              }
              if($MessageTextHAlign){
                $CustomWindow_hash.MarkdownScrollViewer.Document.TextAlignment = $MessageTextHAlign
              }
            }catch{
              write-ezlogs "An exception occurred updating MarkdownScrollViewer" -showtime -catcherror $_
            }
          }
        }

        if($Type -eq 'Info' -or !$Type){
          $OkButton_Text = ''
          $Cancel_Button_Text = 'OK'
        }elseif($Type -eq 'YesNo'){
          $OkButton_Text = 'YES'
          $Cancel_Button_Text = 'NO'
        }elseif($Type -in 'OkCancel','Options'){
          $OkButton_Text = 'OK'
          $Cancel_Button_Text = 'CANCEL'
          $Cancel_Text_Margin = "30 0 0 0"
        }
        #region Ok_Button  
        if($CustomWindow_hash.Ok_Button){
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png") 
          $SaveButton = [System.Windows.Media.Imaging.BitmapImage]::new()
          $SaveButton.BeginInit()
          $SaveButton.CacheOption = "OnLoad"
          $SaveButton.DecodePixelWidth = "86"
          $SaveButton.StreamSource = $stream_image
          $SaveButton.EndInit() 
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $null
          $SaveButton.Freeze()
          $CustomWindow_hash.Ok_Button_Image.Source = $SaveButton
          if($OkButton_Text -and $CustomWindow_hash.Ok_Button_Text){
            $CustomWindow_hash.Ok_Button_Text.text = $OkButton_Text
            if($OKActionScriptBlock){
              $CustomWindow_hash.Ok_Button.add_click($OKActionScriptBlock)
            }else{
              $CustomWindow_hash.Ok_Button.add_click({
                  Param($Sender,$e)
                  try{
                    $CustomWindow_hash.window.close()
                    $CustomWindow_hash.output = $CustomWindow_hash.Ok_Button_Text.text
                  }catch{
                    write-ezlogs "An exception occurred in Ok_Button click event" -showtime -catcherror $_
                  } 
              })  
            }     
          }elseif($CustomWindow_hash.OK_Button_Grid){
            $CustomWindow_hash.OK_Button_Grid.Visibility = 'Collapsed'
          }
        }
        #endregion Ok_Button 

        #region Cancel_Button  
        if($CustomWindow_hash.Cancel_Button){
          if($Cancel_Button_Text -and $CustomWindow_hash.Cancel_Button_Text){
            $CustomWindow_hash.Cancel_Button_Text.text = $Cancel_Button_Text
            if($Cancel_Text_Margin){
              $CustomWindow_hash.Cancel_Button_Text.Margin = $Cancel_Text_Margin
            }
            $CustomWindow_hash.Cancel_Button.add_click({
                Param($Sender,$e)
                try{
                  $CustomWindow_hash.IsCanceled = $true
                  $CustomWindow_hash.window.close()
                }catch{
                  write-ezlogs "An exception occurred in Cancel_Button click event" -showtime -catcherror $_
                } 
            }) 
          }elseif($CustomWindow_hash.Cancel_Button_Grid){
            $CustomWindow_hash.Cancel_Button_Grid.Visibility = 'Collapsed'
          }
        }
        #endregion Cancel_Button 
      }else{
        write-ezlogs "Unable to load valid custom XAML window -- cannot continue!" -Warning -AlertUI
      }

      #region Custom Options
      if($Options.count -gt 0 -and $CustomWindow_hash.Options_StackPanel){
        $CustomWindow_hash.Options_StackPanel.Margin="10,10,0,5"
        if($OptionsHeader -and $CustomWindow_hash.OptionsHeader){
          $CustomWindow_hash.OptionsHeader.Content = $OptionsHeader
        }
        $grid = [System.Windows.Controls.Grid]::new()
        $column1 = [System.Windows.Controls.ColumnDefinition]::new()
        $column2 = [System.Windows.Controls.ColumnDefinition]::new()
        $column3 = [System.Windows.Controls.ColumnDefinition]::new()
        $column1.Width = "Auto"
        $column2.Width = "Auto"
        $column3.Width = "Auto"
        $grid.ColumnDefinitions.add($column1)
        $grid.ColumnDefinitions.add($column2)
        $grid.ColumnDefinitions.add($column3)
        0..@($Options).count | & { process {
            $Row = [System.Windows.Controls.RowDefinition]::new()
            $grid.RowDefinitions.add($Row)
        }}
        $Count = 0
        foreach($Option in $Options){
          if(!$CustomWindow_hash."$($Option.Name)_$($Option.Type)"){
            $CustomWindow_hash."$($Option.Name)_Label" = [System.Windows.Controls.Textblock]::new()
            $CustomWindow_hash."$($Option.Name)_Label".Name = "$($Option.Name)_Label"
            $CustomWindow_hash."$($Option.Name)_Label".Margin="5,5,5,5"
            $CustomWindow_hash."$($Option.Name)_Label".HorizontalAlignment="Left"
            $CustomWindow_hash."$($Option.Name)_Label".VerticalAlignment="Center"
            $CustomWindow_hash."$($Option.Name)_Label".text = $Option.Label
            $CustomWindow_hash."$($Option.Name)_Label".SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
            $CustomWindow_hash."$($Option.Name)_Label".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)      
            $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_Label")
            if($Option.Type -eq 'CheckBox'){
              write-ezlogs ">>>> Creating CheckBox property ($($Option.name)) with value $($Option.value)" -LogLevel 0 -Verboselog:$VerboseLog
              $CustomWindow_hash."$($Option.Name)_Label".Margin="5,3,5,5"
              $CustomWindow_hash."$($Option.Name)_CheckBox" = [System.Windows.Controls.CheckBox]::new()
              $CustomWindow_hash."$($Option.Name)_CheckBox".Name = "$($Option.Name)_CheckBox"
              $CustomWindow_hash."$($Option.Name)_CheckBox".Margin = "5,5,0,5"
              $CustomWindow_hash."$($Option.Name)_CheckBox".ToolTip = $Option.ToolTip            
              $CustomWindow_hash."$($Option.Name)_CheckBox".IsEnabled = $true
              $CustomWindow_hash."$($Option.Name)_CheckBox".isChecked = $($Option.value)
              $CustomWindow_hash."$($Option.Name)_CheckBox".HorizontalAlignment="Left"
              $CustomWindow_hash."$($Option.Name)_CheckBox".Background="Transparent"
              $CustomWindow_hash."$($Option.Name)_CheckBox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
              $CustomWindow_hash."$($Option.Name)_CheckBox".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)
              $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_CheckBox")
            }elseif($Option.Type -eq 'Textbox'){
              write-ezlogs ">>>> Creating Textbox property ($($Option.name)) with value $($Option.value)" -LogLevel 0 -Verboselog:$VerboseLog
              $CustomWindow_hash."$($Option.Name)_textbox" = [System.Windows.Controls.Textbox]::new()
              $CustomWindow_hash."$($Option.Name)_textbox".Margin="5,5,0,5"
              $CustomWindow_hash."$($Option.Name)_textbox".ToolTip = $Option.ToolTip
              $CustomWindow_hash."$($Option.Name)_textbox".isReadOnly = $false
              $CustomWindow_hash."$($Option.Name)_textbox".text = $($Option.value)
              $CustomWindow_hash."$($Option.Name)_textbox".TextWrapping = "Wrap"
              $CustomWindow_hash."$($Option.Name)_textbox".Foreground="#FFC6CFD0"
              $CustomWindow_hash."$($Option.Name)_textbox".Background="Transparent"
              $CustomWindow_hash."$($Option.Name)_textbox".HorizontalAlignment="Left" 
              $CustomWindow_hash."$($Option.Name)_textbox".MinWidth="200"
              $CustomWindow_hash."$($Option.Name)_textbox".MaxWidth="350"
              $CustomWindow_hash."$($Option.Name)_textbox".Name = "$($Option.Name)_textbox"
              $CustomWindow_hash."$($Option.Name)_textbox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
              $CustomWindow_hash."$($Option.Name)_textbox".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)
              if($Option.SingleInputAllowed){
                $CustomWindow_hash."$($Option.Name)_textbox".Add_TextChanged({
                    Param($Sender)
                    try{
                      foreach($Option in $Options){
                        if($Option.SingleInputAllowed -and $CustomWindow_hash."$($Option.Name)_$($Option.Type)" -and $Option.Type -eq 'Textbox'){
                          if(-not [string]::IsNullOrEmpty($Sender.Text) -and $Sender -ne $CustomWindow_hash."$($Option.Name)_textbox"){
                            write-ezlogs ">>>> Disabling input for control: $($Option.Name)_$($Option.Type)" -Dev_mode
                            $CustomWindow_hash."$($Option.Name)_$($Option.Type)".isEnabled = $false
                          }elseif(!$CustomWindow_hash."$($Option.Name)_$($Option.Type)".isEnabled){
                            write-ezlogs ">>>> Enabling input for control: $($Option.Name)_$($Option.Type)" -Dev_mode
                            $CustomWindow_hash."$($Option.Name)_$($Option.Type)".isEnabled = $true
                          }
                        }
                      }
                    }catch{
                      write-ezlogs "An exception occurred in $($Sender.Name).add_TextChanged" -CatchError $_ -enablelogs
                    }
                })
              }
              $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_textbox")
              if($Option.BrowseType -in 'OpenFile','OpenFolder','SaveFolder','SaveFile' -and !$CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)"){
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)" = [System.Windows.Controls.Button]::new()
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".Margin="5,5,0,5"
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".Content = "Browse"
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".Uid = $Option.BrowseType
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".Tag = "$($Option.Name)_textbox"
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".HorizontalAlignment="Left" 
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".Name = "$($Option.Name)_textbox_Browse"
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".SetValue([System.Windows.Controls.Grid]::ColumnProperty,2)
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)
                $CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)".add_Click({
                    Param($Sender)
                    try{
                      if($CustomWindow_hash."$($Sender.Tag)" -is [System.Windows.Controls.Textbox]){
                        $FileDialog = [Bool]($Sender.Uid -match 'SaveFile|OpenFile')
                        $SaveDialog = [Bool]($Sender.Uid -match 'Save')
                        if($FileDialog){
                          write-ezlogs ">>>> Executing Open-FileDialog for textbox control: $($Sender.Tag)" -LogLevel 0 -Verboselog:$VerboseLog
                          $result = (Open-FileDialog -Title 'Select the file name' -SaveDialog:$SaveDialog -CheckPathExists:$SaveDialog -MultiSelect:$FileDialog) -join ','
                        }else{
                          write-ezlogs ">>>> Executing Open-FolderDialog for textbox control: $($Sender.Tag)" -LogLevel 0 -Verboselog:$VerboseLog
                          $result = Open-FolderDialog -Title 'Select the directory'
                        }
                        if(-not [string]::IsNullOrEmpty($result)){
                          $CustomWindow_hash."$($Sender.Tag)".text = $result
                        }
                      }else{
                        write-ezlogs "Cannot find a valid textbox to update with name $($Sender.Tag)" -Warning
                      }                       
                    }catch{
                      write-ezlogs "An exception occurred in Youtube_Download_Browse.add_Click" -CatchError $_ -enablelogs
                    }
                })
                $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_textbox_Browse_$($Option.BrowseType)")
              }  
            }elseif($Option.Type -eq 'ComboBox'){
              write-ezlogs ">>>> Creating ComboBox property ($($Option.name)) with value $($Option.value)" -LogLevel 0 -Verboselog:$VerboseLog
              $CustomWindow_hash."$($Option.Name)_ComboBox" = [System.Windows.Controls.ComboBox]::new()
              $CustomWindow_hash."$($Option.Name)_ComboBox".Margin="5,5,0,5"
              $CustomWindow_hash."$($Option.Name)_ComboBox".ToolTip = $Option.ToolTip
              $CustomWindow_hash."$($Option.Name)_ComboBox".isReadOnly = $true
              $CustomWindow_hash."$($Option.Name)_ComboBox".items.clear()
              $Option.Value | & { process {
                  [void]$CustomWindow_hash."$($Option.Name)_ComboBox".items.add($_)
              }}
              if('Default' -in $Option.Value){
                $CustomWindow_hash."$($Option.Name)_ComboBox".Selecteditem = 'Default'
              }else{
                $CustomWindow_hash."$($Option.Name)_ComboBox".SelectedIndex = -1
              }
              $CustomWindow_hash."$($Option.Name)_ComboBox".Foreground="#FFC6CFD0"
              $CustomWindow_hash."$($Option.Name)_ComboBox".Background="Transparent"
              $CustomWindow_hash."$($Option.Name)_ComboBox".HorizontalAlignment="Left" 
              $CustomWindow_hash."$($Option.Name)_ComboBox".Name = "$($Option.Name)_ComboBox"
              $CustomWindow_hash."$($Option.Name)_ComboBox".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
              $CustomWindow_hash."$($Option.Name)_ComboBox".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)
              $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_ComboBox") 
            }elseif($Option.Type -eq 'ToggleSwitch'){
              write-ezlogs ">>>> Creating ToggleSwitch property ($($Option.name)) with value $($Option.value)" -LogLevel 0 -Verboselog:$VerboseLog
              $CustomWindow_hash."$($Option.Name)_Label".Margin="5,7,5,5"
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch" = [MahApps.Metro.Controls.ToggleSwitch]::new()
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".Margin="5,5,0,5"
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".ToolTip = $Option.ToolTip
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".OffContent = ''
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".OnContent = ''
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".isOn = [Bool]$Option.Value
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".Foreground="#FFC6CFD0"
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".Background="Transparent"
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".HorizontalAlignment="Left" 
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".Name = "$($Option.Name)_ToggleSwitch"
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".SetValue([System.Windows.Controls.Grid]::ColumnProperty,1)
              $CustomWindow_hash."$($Option.Name)_ToggleSwitch".SetValue([System.Windows.Controls.Grid]::RowProperty,$Count)
              $null = $grid.AddChild($CustomWindow_hash."$($Option.Name)_ToggleSwitch") 
            }else{
              write-ezlogs ">>>> Cannot create unknown property type ($($Option.type)) with name ($($Option.name)) and with value $($Option.value)" -showtime
            }
            $Count++
          }
        }
        if($CustomWindow_hash.Options_StackPanel.Children -notcontains $grid){
          $null = $CustomWindow_hash.Options_StackPanel.addChild($grid)
        }
      }
      #endregion Custom Options
    }catch{
      write-ezlogs "An exception occurred Show-CustomWindow Xaml" -showtime -catcherror $_ -AlertUI
      return
    }
    try{ 
      #region MouseDown Event
      [System.Windows.RoutedEventHandler]$CustomWindow_hash.MouseDown_Command = {
        param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed){
          try{
            $CustomWindow_hash.Window.DragMove()
          }catch{
            write-ezlogs "An exception occurred in Custom Window MouseDown event" -showtime -catcherror $_
          }
        }
      }
      $CustomWindow_hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::MouseDownEvent,$CustomWindow_hash.MouseDown_Command)
      if($CustomWindow_hash.PageHeader){
        $CustomWindow_hash.PageHeader.AddHandler([System.Windows.Controls.Label]::MouseDownEvent,$CustomWindow_hash.MouseDown_Command)
      }
      #endregion MouseDown Event

      #region Closed Event
      $CustomWindow_hash.Closed_Event = {
        param($sender)
        try{                                  
          write-ezlogs ">>>> Show-CustomWindow Closed"        
        }catch{
          write-ezlogs "An exception occurred closing Show-Weblogin window" -showtime -catcherror $_
        }
      }
      $Null = $CustomWindow_hash.Window.Add_Closed($CustomWindow_hash.Closed_Event)
      #endregion Closed Event

      #region Loaded Event 
      [System.Windows.RoutedEventHandler]$CustomWindow_hash.Loaded_Event = {
        param($sender,[System.Windows.RoutedEventArgs]$e)
        try{
          #Register window to installed application ID 
          $Sender.MinHeight = $Sender.ActualHeight
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($sender)
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering WebLogin window handle: $($Window_Helper.Handle) -- to appid: $appid" -LogLevel 0 -Verboselog:$VerboseLog
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)  
            $thisapp.config.Installed_AppID = $appid
          }
          $null = $Sender.Show()
          $null = $Sender.Activate()                
        }catch{
          write-ezlogs "An exception occurred in MahDialog_hash.Window.Add_Loaded" -showtime -catcherror $_
        } 
      } 
      $Null = $CustomWindow_hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::LoadedEvent,$CustomWindow_hash.Loaded_Event)
      #endregion Loaded Event 
        
      #region Unloaded Event
      [System.Windows.RoutedEventHandler]$CustomWindow_hash.Unloaded_Event = {
        param($sender,[System.Windows.RoutedEventArgs]$e)
        try{
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseDownEvent) -RemoveHandlers -VerboseLog:$Verboselog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers -VerboseLog:$Verboselog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers -VerboseLog:$Verboselog
          $Cancel_Button = $sender.FindName('Cancel_Button')
          $null = Get-EventHandlers -Element $Cancel_Button -RoutedEvent ([System.Windows.Controls.Button]::ClickEvent) -RemoveHandlers -VerboseLog:$Verboselog
          $Ok_Button = $sender.FindName('Ok_Button')
          if($Ok_Button){
            $null = Get-EventHandlers -Element $Ok_Button -RoutedEvent ([System.Windows.Controls.Button]::ClickEvent) -RemoveHandlers -VerboseLog:$Verboselog
          }
          $Null = $sender.Remove_Closed($CustomWindow_hash.Closed_Event)
          $CustomWindow_hash.Closed_Event = $Null
          $CustomWindow_hash.Loaded_Event = $Null
          $CustomWindow_hash.Unloaded_Event = $Null
          if(!$CustomWindow_hash.IsCanceled -and $Options){
            foreach($Option in $Options){
              if($CustomWindow_hash."$($Option.Name)_$($Option.Type)"){
                if($Option.Type -eq 'CheckBox'){
                  $Option.Output = $CustomWindow_hash."$($Option.Name)_$($Option.Type)".isChecked   
                }elseif($Option.Type -eq 'Textbox'){
                  $Option.Output = $CustomWindow_hash."$($Option.Name)_$($Option.Type)".text
                }elseif($Option.Type -eq 'Combobox'){
                  $Option.Output = $CustomWindow_hash."$($Option.Name)_$($Option.Type)".selecteditem
                }elseif($Option.Type -eq 'ToggleSwitch'){
                  $Option.Output = $CustomWindow_hash."$($Option.Name)_$($Option.Type)".isOn
                }
              }
              $CustomWindow_hash.Output = $Options
            }
          }
          $hashkeys = [System.Collections.ArrayList]::new($CustomWindow_hash.keys)
          $hashkeys | & { process {
              if($CustomWindow_hash.$_ -is [System.Windows.DependencyObject]){
                if($Verboselog){write-ezlogs ">>>> Removing all data bindings from: $($_)" -Dev_mode:$Verboselog}
                [void][System.Windows.Data.BindingOperations]::ClearAllBindings($CustomWindow_hash.$_)
              }
              if($CustomWindow_hash.$_ -is [System.Windows.Controls.Button]){
                [void](Get-EventHandlers -Element $CustomWindow_hash.$_ -RoutedEvent ([System.Windows.Controls.Button]::ClickEvent) -RemoveHandlers -VerboseLog:$Verboselog)
              }elseif($CustomWindow_hash.$_ -is [MahApps.Metro.Controls.ToggleSwitch]){
                if($CustomWindow_hash."$($_)_Command"){
                  if($Verboselog){write-ezlogs ">>>> Removing command: $($_)_Command - from element: $($CustomWindow_hash.$_) with name: $($CustomWindow_hash.$_.name)" -Dev_mode:$Verboselog}
                  $CustomWindow_hash.$_.Remove_Toggled($CustomWindow_hash."$($_)_Command")
                  $CustomWindow_hash."$($_)_Command" = $Null
                }
              }elseif($CustomWindow_hash.$_ -is [System.Windows.Controls.ComboBox]){
                [void](Get-EventHandlers -Element $CustomWindow_hash.$_ -RoutedEvent ([System.Windows.Controls.ComboBox]::SelectionChangedEvent) -RemoveHandlers -VerboseLog:$Verboselog)
              }elseif($CustomWindow_hash.$_ -is [System.Windows.Threading.DispatcherTimer]){
                if($CustomWindow_hash.$_.IsEnabled){
                  write-ezlogs ">>>> Stopping running timer ScriptBlock: $($_)" -warning
                  $CustomWindow_hash.$_.stop()
                }
                if($CustomWindow_hash."$($_)_ScriptBlock"){
                  if($Verboselog){write-ezlogs ">>>> Removing ScriptBlock: $($_)_ScriptBlock - from DispatcherTimer: $($_)" -Dev_mode:$Verboselog}
                  $CustomWindow_hash.$_.Remove_Tick($CustomWindow_hash."$($_)_ScriptBlock")
                  $CustomWindow_hash."$($_)_ScriptBlock" = $Null
                  $CustomWindow_hash.$_ = $Null
                }
              }elseif($CustomWindow_hash.$_ -is [System.Windows.Controls.TextBox]){
                [void](Get-EventHandlers -Element $CustomWindow_hash.$_ -RoutedEvent ([System.Windows.Controls.TextBox]::TextChangedEvent) -RemoveHandlers -VerboseLog:$Verboselog)
              }
              if($sender.FindName($_)){
                if($Verboselog){write-ezlogs ">>>> Unregistering CustomWindow_hash UI name: $_" -Dev_mode:$Verboselog}
                $null = $sender.UnRegisterName($_)                
              }
              if($_ -ne 'Output'){
                $CustomWindow_hash.$_ = $Null
                [void]$CustomWindow_hash.Remove($_)  
              }       
          }}
          $hashkeys = $Null
          [System.Windows.Threading.Dispatcher]::ExitAllFrames()
          [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
          write-ezlogs ">>>> Custom Window Unloaded - disposed CurrentDispatcher thread"
        }catch{
          write-ezlogs "An exception occurred in CustomWindow_hash Window unloaded event" -catcherror $_
        }
      }
      $Null = $CustomWindow_hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$CustomWindow_hash.Unloaded_Event)
      #endregion Unloaded Event
    }catch{
      write-ezlogs "An exception occurred adding CustomWindow_hash.Window routed events" -showtime -CatchError $_
    }finally{
      if($CustomWindowLoad_Measure){
        $CustomWindowLoad_Measure.stop()
        write-ezlogs ">>>> CustomWindow Load Measure" -PerfTimer $CustomWindowLoad_Measure -Perf
      }
    } 

    #endregion Show Window
    try{
      $null = [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($CustomWindow_hash.Window)
      $null = $CustomWindow_hash.window.Show()
      $null = $CustomWindow_hash.Window.Activate()
      [System.Windows.Threading.Dispatcher]::Run()
      if($WaitforOutput){
        return $CustomWindow_hash.output
      }elseif($synchash.CustomWindowResultTimer){
        write-ezlogs ">>>> Starting CustomWindowResultTimer" -LogLevel 0 -Verboselog:$VerboseLog
        $synchash.CustomWindowResultTimer.tag = $CustomWindow_hash.output
        $synchash.CustomWindowResultTimer.start()
      }     
    }catch{
      write-ezlogs "An exception occurred when opening main Show-WebLogin window" -showtime -CatchError $_
    } 
    #endregion Show Window  
  }
  $Output = Start-Runspace $CustomWindow_Pwshell -arguments $PSBoundParameters -StartRunspaceJobHandler -runspace_name 'Show_CustomWindow' -logfile $thisApp.Config.Log_File -thisApp $thisApp -synchash $synchash -verboselog -ApartmentState STA -CheckforExisting -AlertUIWarnings -ReturnOutput:$WaitforOutput -Wait:$WaitforOutput
  if($WaitforOutput){
    return $Output
  }
}
#---------------------------------------------- 
#endregion Show-CustomWindow Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-CustomWindow')