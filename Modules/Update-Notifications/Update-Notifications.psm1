<#
    .Name
    Update-Notifications

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of functions for managing the notifications UI

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
#region Update Notifications List Function
#----------------------------------------------
function Update-Notifications
{
  param (
    [switch]$Clear,
    $thisApp,
    [switch]$Startup,    
    [switch]$Open_Flyout,
    [string]$Message,
    [switch]$EnableAudio = $thisapp.config.Notification_Audio,
    [switch]$No_runspace,
    [string]$Level,
    [string]$Viewlink,
    [string]$ActionName,
    $ActionScriptBlock,
    [string]$Message_color = 'White',
    [string]$MessageFontWeight = 'Normal',
    [string]$Level_color = 'White',
    [string]$LevelFontWeight = 'Bold',
    [int]$id,
    $synchash,
    [switch]$VerboseLog = $thisApp.Config.Verbose_Logging
  )
  $Fields = @(
    'ID'
    'Time'
    'Level'
    'Level_color'
    'LevelFontWeight'
    'Message'
    'Message_color'
    'MessageFontWeight'
  )
  if(!$synchash.Notifications_Grid.items){
    if(!$id){
      $id = 1
    }
  }else{
    if(!$id){
      $id = $synchash.Notifications_Grid.items.id | Select-Object -last 1
      if(!$id){
        $id = 1
      }else{
        $id++
      }        
    }
  }
  write-ezlogs ">>>> Updating Notifications table" -showtime -loglevel 3
  if($Level -eq 'ERROR'){
    $Level_color = 'Red'
  }elseif($Level -eq 'Warning'){
    $Level_color = 'Orange'
  }elseif($Level -eq 'INFO'){
    $Level_color = 'Cyan'
  }elseif($Level -eq 'SUCCESS'){
    $Level_color = 'LightGreen'
  }
  
  if($synchash.Notifications_Grid.items.id -contains $id){
    $itemssource = $synchash.Notifications_Grid.items.where({$_.id -eq $id}) | Select-Object -Unique
    $existing = $true
    write-ezlogs "Found existing notification with ID: $($itemssource.id) - updating" -showtime -Dev_mode
    $itemssource.Time = [DateTime]::Now.ToString()
    $itemssource.Level = $Level
    $itemssource.Level_color = $Level_color
    $itemssource.LevelFontWeight  = $LevelFontWeight 
    $itemssource.Message = $Message
    $itemssource.Message_color = $Message_color
    $itemssource.MessageFontWeight = $MessageFontWeight   
    if($ActionName -and $ActionScriptBlock){
      $itemssource.Action = $ActionName
      $itemssource.ActionCommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $ActionScriptBlock -target $itemssource
    } 
  }else{
    $existing = $false
    if($ActionName -and $ActionScriptBlock){
      $Action = $ActionName
      $ActionCommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $ActionScriptBlock -target $synchash.Notifications_Grid
    }
    $itemssource = [PSCustomObject]@{
      ID=$ID;
      Time=[DateTime]::Now.ToString()
      Level=$Level
      Level_color=$Level_color
      LevelFontWeight=$LevelFontWeight    
      Message=$Message
      Message_color=$Message_color
      MessageFontWeight=$MessageFontWeight
      Action=$Action
      ActionCommand=$ActionCommand         
    }
  } 
  if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Audio\Notification_Alert.wav")){
    $Notifications_Audio_Path = "$($thisApp.Config.Current_Folder)\Resources\Audio\Notification_Alert.wav"
  }elseif([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Audio\Bitty_Notification.mp3")){
    $Notifications_Audio_Path = "$($thisApp.Config.Current_Folder)\Resources\Audio\Bitty_Notification.mp3"
  }
  $ActionBlock = {
    try{  
      if($Clear){
        $null = $synchash.Notifications_Grid.Items.clear()
      }           
      if([int]$synchash.Notifications_Grid.items.count -lt 1){
        [int]$notifications = 1
      }else{
        [int]$notifications = [int]$synchash.Notifications_Grid.items.count + 1
      }
      [int]$synchash.Notifications_Badge.badge = [int]$notifications
      if($EnableAudio -and [system.io.file]::Exists($Notifications_Audio_Path)){          
        $Paragraph = [System.Windows.Documents.Paragraph]::new()    
        $BlockUIContainer = [System.Windows.Documents.BlockUIContainer]::new()
        $Floater = [System.Windows.Documents.Floater]::new()  
        $Floater.HorizontalAlignment = "Center" 
        $Floater.Name = "Media_Floater"
        if($Notifications_Audio_Path -match '.gif' -or $Notifications_Audio_Path -match '.mp3' -or $Notifications_Audio_Path -match '.mp4' -or $Notifications_Audio_Path -match '.wav'){ 
          $Media_Element = [System.Windows.Controls.MediaElement]::new()  
          $Media_Element.UnloadedBehavior = 'Close'  
          $Media_Element.LoadedBehavior="Manual"  
          $Media_Element.Name = 'Media_Element'     
          $Media_Element.Source = $synchash.Notifications_Audio_Path   
          $Media_Element.Play()                     
          $BlockUIContainer.AddChild($Media_Element) 
        }   
        $floater.AddChild($BlockUIContainer)   
        $Paragraph.addChild($floater)
        $null = $synchash.Notification_Media.Document.Blocks.Add($Paragraph)
      }elseif($EnableAudio){
        write-ezlogs "Unable to find media file for Playback: '$($Notifications_Audio_Path)'" -warning
      }
      if($existing){
        $null = $synchash.Notifications_Grid.Items.refresh()
      }else{
        $null = $synchash.Notifications_Grid.Items.add($itemssource)
      }              
      if($Open_Flyout){
        $synchash.NotificationFlyout.isOpen=$true 
      }
    }catch{
      write-ezlogs "An exception occurred adding items to notifications grid" -showtime -catcherror $_
    }     
  }
  if($No_runspace){
    try{
      Invoke-command -ScriptBlock $ActionBlock 
    }catch{
      write-ezlogs "An exeception occurred in Invoke-command" -catcherror $_
    }   
  }else{
    try{     
      $synchash.Window.Dispatcher.Invoke([Action]$ActionBlock,[System.Windows.Threading.DispatcherPriority]::Background)
    }catch{
      write-ezlogs "An exeception occurred in Window.Dispatcher.BeginInvoke" -catcherror $_
    }
  }  
  
}
#---------------------------------------------- 
#endregion Update-Notifications Function
#----------------------------------------------

#---------------------------------------------- 
#region New-DialogNotification Function
#----------------------------------------------
function New-DialogNotification {
  Param (
    $synchash,
    $thisApp,
    [switch]$Show,
    [switch]$updates,
    [string]$Title,
    [string]$Message,
    [ValidateSet('Confirm','Notify','Custom','Normal')]
    [string]$DialogType,
    [string]$AffirmativeButtonText = 'Yes',
    [string]$NegativeButtonText = 'No',
    [switch]$Hide,
    [ValidateSet('INFO','ERROR','WARNING')]
    [string]$DialogLevel,
    $ActionScriptBlock,
    [string]$ActionName,
    [switch]$isAsync,
    [switch]$close,
    [switch]$screenshot,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.DialogNotification_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.DialogNotification_Timer.add_tick({
          try{  
            $synchash = $synchash
            $thisApp = $thisApp   
            if($this.tag.Show){
              #$synchash.Window.show() 
              #$synchash.Window.Activate() 
            }
            if($this.tag.Hide){
              #$synchash.Window.Hide() 
            }  
            if($this.tag.Close){
              #$synchash.Window.Close() 
            }

            if($this.tag.DialogType -eq 'Confirm'){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = $this.tag.AffirmativeButtonText
              $Button_Settings.NegativeButtonText = $this.tag.NegativeButtonText 
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,$($this.tag.title),$($this.tag.Message),$okandCancel,$Button_Settings)
              if($result -eq 'Affirmative'){
                if($this.tag.updates){
                  write-ezlogs "User wishes to proceed to download/install updates" -loglevel 2
                  Install-Updates -synchash $synchash -thisApp $thisApp -Download_Destination "$($thisApp.Config.Temp_Folder)\Updates" -Use_Runspace
                  Update-Notifications  -Level 'INFO' -Message "Downloading the latest build/installer, install/update will continue when finished" -VerboseLog -Message_color 'cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold
                }               
              }else{
                write-ezlogs "User said no or chose to cancel" -warning
              }
            }elseif($this.tag.DialogType -eq 'Notify'){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = $this.tag.AffirmativeButtonText
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,$($this.tag.title),$($this.tag.Message),$okandCancel,$Button_Settings)                    
            }elseif($this.tag.DialogType -eq 'Normal'){
              if($this.tag.DialogLevel){
                $Level = $this.tag.DialogLevel
              }else{
                $Level = 'INFO'
              }
              Update-Notifications -Level $Level -Message $this.tag.Message -VerboseLog -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -ActionName $this.tag.ActionName -ActionScriptBlock $this.tag.ActionScriptblock -No_runspace
            }                                                                                             
            if($this.tag.screenshot){
              $synchash.Window.TopMost = $this.tag.TopMost
              $synchash.Window.Activate() 
              start-sleep -Milliseconds 500
              write-ezlogs ">>>> Taking Snapshot of Main window" -loglevel 2
              $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$synchash.Window)
              $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
              $synchash.SnapshotPoint = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)
            }                              
            $this.Stop()
          }catch{
            write-ezlogs "An exception occurred in Settings_Update_Timer.add_tick" -showtime -catcherror $_
          }finally{
            $this.Stop()
          }
      }) 
    }else{
      $synchash.DialogNotification_Timer.tag = [PSCustomObject]@{
        'Title' = $Title
        'Message' = $Message
        'AffirmativeButtonText' = $AffirmativeButtonText
        'NegativeButtonText' = $NegativeButtonText
        'isAsync' = $isAsync
        'DialogLevel' = $DialogLevel
        'ActionScriptBlock' = $ActionScriptBlock
        'ActionName' = $ActionName
        'updates' = $updates
        'DialogType' = $DialogType
        'screenshot' = $screenshot
        'Show' = $Show
        'Hide' = $hide
        'Close' = $close
      } 
      $synchash.DialogNotification_Timer.start()
    }
  }catch{
    write-ezlogs "An exception occurred in New-DialogNotification" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion New-DialogNotification Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-ChildWindow Function
#----------------------------------------------
function Update-ChildWindow {
  Param (
    $synchash,
    $thisApp,
    [string]$Control,
    $controls,
    $value,
    [switch]$NewDialog,
    [string]$StringValue,
    [string]$sendername,
    [string]$Method,
    [string]$Property,
    [switch]$Show,
    [switch]$Hide,
    [string]$TopMost,
    [switch]$close,
    [switch]$screenshot,
    [string]$Visibility,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      $synchash.ChildWindow_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $synchash.ChildWindow_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      $synchash.ChildWindow_Update_Timer.add_tick({
          try{  
            $synchash = $synchash
            $thisApp = $thisApp  
            $object = @{}
            $Process = $synchash.ChildWindow_UpdateQueue.TryDequeue([ref]$object)              
            if($Process -and $object.ProcessObject){
              if($object.sendername -eq 'About_Menu'){
                $hashname = 'hashAboutWindow'                           
              }elseif($object.sendername -eq 'Dedication_Menu'){
                $hashname = 'hashDedicationWindow'  
              }elseif($object.sendername -eq 'OpenAI'){
                $hashname = 'hashOpenAIWindow'  
              }elseif($object.sendername -eq 'Check_Updates'){
                $hashname = 'hashUpdatesWindow'  
              }else{
                $hashname = 'hashChildWindow'  
              } 
              $WindowHash = Get-Variable -Name $hashname -ValueOnly -ErrorAction SilentlyContinue 
              if($WindowHash){
                if($object.sendername -eq 'OpenAI' -and $object.NewDialog){
                  write-ezlogs ">>>> Prompting for OpenAI"
                  $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
                  $Result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($WindowHash.Window,'Ask Samson a Question?','Ask any question and Samson will have the answer',$Button_Settings)
                  if(-not [string]::IsNullOrEmpty($Result)){ 
                    #TODO: TEST ONLY - MODULE NOT INCLUDED ANYMORE - LEAVING FOR FUTURE
                    Invoke-OpenAI -synchash $synchash -thisApp $thisApp -Prompt $Result
                  }else{
                    write-ezlogs 'No prompt was supplied - aborting' -showtime -warning                   
                  }
                  $this.stop()
                  return
                }
                if(-not [string]::IsNullOrEmpty($object.Visibility)){
                  $WindowHash.Window.Visibility = $object.Visibility 
                }   
                if($object.Show){
                  $WindowHash.Window.show() 
                  $WindowHash.Window.Activate() 
                }
                if($object.Hide){
                  $WindowHash.Window.Hide() 
                }  
                if($object.Close){
                  $WindowHash.Window.Close() 
                }
                if(-not [string]::IsNullOrEmpty($object.TopMost)){
                  $WindowHash.Window.TopMost = $object.TopMost
                }              
                if($object.Controls){ 
                  foreach($control in $object.Controls){                   
                    if(-not [string]::IsNullOrEmpty($control.StringValue)){
                      $value = $control.StringValue 
                    }else{
                      $value = $control.Value
                    }
                    write-ezlogs ">>>> Looking for control: $($control.Control)" -loglevel 3  
                    write-ezlogs "| Property: $($control.Property)" -loglevel 3 
                    write-ezlogs "| value: $($value)" -loglevel 3 
                    if(-not [string]::IsNullOrEmpty($WindowHash."$($control.Control)")){ 
                      write-ezlogs ">>>> Updating Main Window Control $($WindowHash."$($control.Control)")" -loglevel 3                                 
                      if(-not [string]::IsNullOrEmpty($value)){
                        if(-not [string]::IsNullOrEmpty($control.Property)){
                          if($WindowHash."$($control.Control)"."$($control.Property)" -ne $value){
                            write-ezlogs "| Setting property $($control.Property) from $($WindowHash."$($control.Control)"."$($control.Property)") to $($value)" -loglevel 3 
                            $WindowHash."$($control.Control)"."$($control.Property)" = $value
                          }
                        }else{
                          if($WindowHash."$($control.Control)" -ne $value){
                            write-ezlogs "| Setting $($WindowHash."$($control.Control)") to $($value)" -loglevel 3 
                            $WindowHash."$($control.Control)" = $value
                          }                        
                        }
                      }                      
                    }
                  }
                }else{
                  if(-not [string]::IsNullOrEmpty($object.StringValue)){
                    $value = $object.StringValue 
                  }else{
                    $value = $object.Value
                  }
                  if(-not [string]::IsNullOrEmpty($WindowHash."$($object.Control)")){ 
                    write-ezlogs ">>>> Updating Main Window Control $("$($object.Control)")" -loglevel 3                                  
                    if(-not [string]::IsNullOrEmpty($object.Method)){
                      if(-not [string]::IsNullOrEmpty($object.Property)){
                        $null = $WindowHash."$($object.Control)"."$($object.Property)".$($object.Method)()
                      }else{
                        $null = $WindowHash."$($object.Control)".$($object.Method)()
                      }
                    }
                    if(-not [string]::IsNullOrEmpty($value)){
                      if(-not [string]::IsNullOrEmpty($object.Property)){
                        write-ezlogs "| Setting property $($object.Property) from $($WindowHash."$($object.Control)"."$($object.Property)") to $($value)" -loglevel 3 
                        $WindowHash."$($object.Control)"."$($object.Property)" = $value
                      }else{
                        $WindowHash."$($object.Control)" = $value
                      }
                    }                      
                  }
                }                                                                              
                if($object.screenshot){
                  #$hashsetup.Window.TopMost = $true
                  $WindowHash.Window.TopMost = $object.TopMost
                  $WindowHash.Window.Activate() 
                  start-sleep -Milliseconds 500
                  write-ezlogs ">>>> Taking Snapshot of $hashname window" -loglevel 2
                  $translatepoint = $WindowHash.Window.TranslatePoint([system.windows.point]::new(0,0),$WindowHash.Window)
                  $locationfromscreen = $WindowHash.Window.PointToScreen($translatepoint)
                  $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)           
                }
              }else{
                write-ezlogs "Unable to find hashtable variable from sendername $($object.sendername) - cannot continue" -warning
                return
              }
            }else{
              $this.Stop()
            }                                       
          }catch{
            write-ezlogs "An exception occurred in MainWindow_Update_Timer.add_tick" -showtime -catcherror $_
            $this.stop()
          }
      }) 
    }else{
      $Null = $synchash.ChildWindow_UpdateQueue.Enqueue([PSCustomObject]@{
          'Control' = $Control
          'ProcessObject' = $true
          'sendername' = $sendername
          'Value' = $Value
          'StringValue' = $StringValue
          'Method' = $Method
          'NewDialog' = $NewDialog
          'TopMost' = $TopMost
          'Property' = $Property
          'Visibility' = $Visibility
          'screenshot' = $screenshot
          'controls' = $controls
          'Show' = $Show
          'Hide' = $hide
          'Close' = $close
      })
      if(!$synchash.ChildWindow_Update_Timer.IsEnabled){  
        write-ezlogs "Starting ChildWindow_Update_Timer" -loglevel 3
        $synchash.ChildWindow_Update_Timer.start() 
      }    
    }
  }catch{
    write-ezlogs "An exception occurred in Update-ChildWindow" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-ChildWindow Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-ChildWindow Function
#----------------------------------------------
function Show-ChildWindow{
  Param (
    [string]$WindowTitle,
    $Message,
    [string]$MarkDownFile,
    [switch]$Prompt,
    [switch]$isSpecialDay,
    [switch]$List,
    $MessageColor = 'White',
    $icon_Kind,
    $sendername,
    [switch]$use_runspace = $true,
    [switch]$AppendContent,
    [string]$Logo,
    $thisScript,
    $synchash,
    $thisApp,
    [switch]$Verboselog
  ) 
  if($sendername -eq 'About_Menu'){
    $hashname = 'hashAboutWindow'  
    New-Variable -name $hashname -Value ([hashtable]::Synchronized(@{})) -Scope Global -Force       
  }elseif($sendername -eq 'Dedication_Menu'){
    $hashname = 'hashDedicationWindow'
    New-Variable -name $hashname -Value ([hashtable]::Synchronized(@{})) -Scope Global -Force
  }elseif($sendername -eq 'OpenAI'){
    $hashname = 'hashOpenAIWindow'
    write-ezlogs ">>>> Creating new hashtable for $hashname" -Dev_mode
    New-Variable -name $hashname -Value ([hashtable]::Synchronized(@{})) -Scope Global -Force
  }elseif($sendername -eq 'Check_Updates'){
    $hashname = 'hashUpdatesWindow'  
    if(!$hashUpdatesWindow){
      New-Variable -name $hashname -Value ([hashtable]::Synchronized(@{})) -Scope Global -Force
    }     
  }else{
    $hashname = 'hashChildWindow'
    New-Variable -name $hashname -Value ([hashtable]::Synchronized(@{})) -Scope Global -Force  
  }  
  $hashChildWindow = Get-Variable -Name $hashname -ValueOnly
  $hashChildWindow_Scriptblock = {
    $hashChildWindow = $hashChildWindow
    $use_runspace = $use_runspace
    $thisApp = $thisApp
    $Logo = $Logo
    $icon_Kind = $icon_Kind
    $isSpecialDay = $isSpecialDay
    $Message = $Message
    $List = $List
    $AppendContent = $AppendContent
    $MessageColor = $MessageColor
    $WindowTitle = $WindowTitle
    $MarkDownFile = $MarkDownFile
    $sendername = $sendername
    $Current_Folder = $thisApp.Config.Current_Folder
    if($thisApp.Config.Debug_mode){write-ezlogs ">>>> Loading ChildWindow: $($thisApp.Config.Current_Folder)\Views\ChildWindow.xaml" -showtime}  
  
    #---------------------------------------------- 
    #region Update-ChildWindow Startup
    #----------------------------------------------
    try{
      Update-ChildWindow -synchash $synchash -thisApp $thisApp -Startup
    }catch{
      wrtie-ezlogs "An exception occurred in Update-ChildWindow startup" -catcherror $_
    }
    #---------------------------------------------- 
    #endregion Update-ChildWindow Startup
    #----------------------------------------------

    #Initialize UI
    try{
      #theme
      $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
      $themes = $theme.GetLibraryThemes()
      $themeManager = [ControlzEx.Theming.ThemeManager]::new()
      if($synchash.Window){
        $detectTheme = $thememanager.DetectTheme($synchash.Window)
        $newtheme = $themes | where {$_.Name -eq $detectTheme.Name}
      }elseif($_.Name -eq $thisApp.Config.Current_Theme.Name){
        $newtheme = $themes | where {$_.Name -eq $thisApp.Config.Current_Theme.Name}
      }else{
        $newtheme = $themes | where {$_.Name -eq'Dark.Blue'}
      } 
      if($themes){
        $null = $themes.Dispose() 
      }     
      #import xml
      if($newTheme.PrimaryAccentColor){        
        [string]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\ChildWindow.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$($newTheme.PrimaryAccentColor)")
      }else{
        [string]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\ChildWindow.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
      }     
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      $hashChildWindow.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $hashChildWindow.Window){
          $hashChildWindow."$($name)" = $hashChildWindow.Window.FindName($name)
        }
      }
      $reader.Dispose()
      #$hashnav.Logo.Source=$Logo
      $hashChildWindow.Window.title = $WindowTitle
      if([system.io.file]::Exists($Logo)){
        $hashChildWindow.Logo.Source = $Logo
      }else{
        $hashChildWindow.Logo.Source = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico" 
      }
      $hashChildWindow.Window.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"
      $hashChildWindow.Window.icon.Freeze()  
      $hashChildWindow.Window.IsWindowDraggable="True"
      $hashChildWindow.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
      $hashChildWindow.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
      $hashChildWindow.Window.ShowTitleBar=$true
      $hashChildWindow.Window.UseNoneWindowStyle = $false
      $hashChildWindow.Window.WindowStyle = 'none'
      $hashChildWindow.Window.IgnoreTaskbarOnMaximize = $true  
      $hashChildWindow.Window.TaskbarItemInfo.Description = $WindowTitle
      $SettingsBackground = [System.Windows.Media.ImageBrush]::new()
      $settingsBackground.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTop.png"
      $settingsBackground.ViewportUnits = "Absolute"
      $settingsBackground.Viewport = "0,0,600,263"
      $settingsBackground.TileMode = 'Tile'
      $SettingsBackground.Freeze()
      $hashChildWindow.Window.Background = $SettingsBackground
      $hashChildWindow.Background_Image_Bottom.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowBottom.png"
      $hashChildWindow.Background_Image_Bottom.Source.Freeze()                  
      $imagebrush = [System.Windows.Media.ImageBrush]::new()
      $ImageBrush.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png"
      $imagebrush.TileMode = 'Tile'
      $imagebrush.ViewportUnits = "Absolute"
      $imagebrush.Viewport = "0,0,600,283"
      $imagebrush.ImageSource.freeze()
      $hashChildWindow.Background_TileGrid.Background = $imagebrush      
      $hashChildWindow.Window.Style = $hashChildWindow.Window.TryFindResource('WindowChromeStyle')
      $hashChildWindow.Window.UpdateDefaultStyle()
      $hashChildWindow.PageHeader.Content = $WindowTitle     
      if($sendername ){       
        $hashChildWindow.$sendername = $hashChildWindow.Window
        $hashChildWindow.Window.Name = $sendername
      }
      write-ezlogs "Sender: $($sendername) - hashname: $($hashname)" -Dev_mode     
      if($hashChildWindow.EditorHelpFlyout){
        $hashChildWindow.EditorHelpFlyout.Document.Blocks.Clear()
      }
      if([system.io.file]::Exists($MarkDownFile)){
        write-ezlogs ">>>> Opening Markdown Help File: $MarkDownFile" -loglevel 2
        if($isSpecialDay){
          $SpecialMessage = "`n`n##HAPPY BIRTHDAY DAN!!`n`n"
        }
        $Message += "`n`n" + $SpecialMessage + ([system.io.file]::ReadAllText($MarkDownFile) -replace '\[USERNAME\]',$env:USERNAME -replace '\[appname\]',$thisApp.Config.App_Name -replace '\[appversion\]',$thisApp.Config.App_Version -replace '\[appbuild\]',$thisApp.Config.App_Build -replace '\[CURRENTFOLDER\]',$thisApp.Config.Current_Folder) -replace '\[localappdata\]',$env:LOCALAPPDATA -replace '\[appdata\]',$env:APPDATA
      }
      if($Message){
        try{
          if($sendername -ne 'OpenAI'){
            $Message = $Message -replace '  - ','  + '
          }else{
            $hashChildWindow.MarkdownScrollViewerHeader_Row.Height="*"
            $hashChildWindow.MarkdownScrollViewerHeader.Markdown =  "## Chatting with Samson`n`n![applogo]($($thisApp.Config.Current_Folder)/Resources/Samson_Icon1.png)"
          }        
          write-ezlogs "Message: $($Message | out-string)" -Dev_mode
          $hashChildWindow.MarkdownScrollViewer.Markdown = $($Message)
        }
        catch{
          write-ezlogs "An exception occurred updating MarkdownScrollViewer" -showtime -catcherror $_
        }
      }
      #Allow dragging window from anywhere
      $hashChildWindow.Window.add_MouseDown({
          $sender = $args[0]
          [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed)
          {
            try{
              $sender.DragMove()
            }catch{
              write-ezlogs "An exception occurred in hashChildWindow Window MouseDown event" -showtime -catcherror $_
            }
          }
      }) 
      $hashChildWindow.PageHeader.add_MouseDown({
          $sender = $args[0]
          [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed)
          {
            try{
              $hashChildWindow.Window.DragMove()
            }catch{
              write-ezlogs "An exception occurred in hashChildWindow PageHeader MouseDown event" -showtime -catcherror $_
            }
          }
      })
      #---------------------------------------------- 
      #region Hyperlink Handler
      #----------------------------------------------
      [System.Windows.RoutedEventHandler]$hashChildWindow.Hyperlink_RequestNavigate = {
        param ($sender,$e)
        try{
          $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
          if($sender.NavigateUri -match $url_fullpattern){
            $path = $sender.NavigateUri
          }else{
            $path = (resolve-path $($sender.NavigateUri -replace 'file:///','')).Path
          }     
          write-ezlogs ">>>> Navigating to: $($path)" -showtime
          if($path){
            start $($path)
          }
        }catch{
          write-ezlogs "An exception occurred in hashChildWindow.Hyperlink_RequestNavigate" -showtime -catcherror $_
        }
      }
      #---------------------------------------------- 
      #endregion Hyperlink Handler
      #----------------------------------------------

      #---------------------------------------------- 
      #region Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------
      $hashChildWindow.Editor_Help_Flyout.add_IsOpenChanged({
          Param($sender)
          try{
            if($sender.isOpen){
              $sender.Height=[Double]::NaN
            }else{
              $sender.Height = '0'
            }
          }catch{
            write-ezlogs "An exception occurred in Editor_Help_Flyout.add_IsOpenChanged" -showtime -catcherror $_
          }
      })
      #---------------------------------------------- 
      #endregion Editor_Help_Flyout IsOpenChanged
      #----------------------------------------------

    }catch{
      write-ezlogs "An exception occurred when loading xaml" -showtime -CatchError $_
      [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occurred when loading the ChildWindow xaml. Recommened reviewing logs for details.`n`n$($_ | out-string)","[ERROR]- $($thisApp.Config.App_name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
      return          
    }

    if($synchash.App_Update_Status.isUpdate_Available -and $hashname -eq 'hashUpdatesWindow'){
      $hashChildWindow.Ok_Button_Textblock.text = 'INSTALL'
      $hashChildWindow.Ok_Button_Grid.Visibility = 'Visible'
      $hashChildWindow.Ok_Button.isEnabled = $true
      $hashChildWindow.Cancel_Button_Text.text = 'CANCEL'
      $hashChildWindow.Cancel_Button_Text.HorizontalAlignment="Right"
    }elseif($hashname -eq 'hashUpdatesWindow'){  
      $hashChildWindow.Ok_Button_Textblock.text = 'INSTALL'
      $hashChildWindow.Ok_Button_Grid.Visibility = 'Visible'
      $hashChildWindow.Ok_Button.isEnabled = $true
      $hashChildWindow.Cancel_Button_Text.text = 'CANCEL'
      $hashChildWindow.Cancel_Button_Text.HorizontalAlignment="Right"               
    }elseif($hashname -eq 'hashOpenAIWindow'){  
      $hashChildWindow.Ok_Button_Textblock.text = 'ASK'
      $hashChildWindow.Ok_Button_Grid.Visibility = 'Visible'
      $hashChildWindow.Ok_Button.isEnabled = $true
      $hashChildWindow.Cancel_Button_Text.text = 'CANCEL'
      $hashChildWindow.Cancel_Button_Text.HorizontalAlignment="Right"               
    }else{
      $hashChildWindow.Ok_Button.isEnabled = $false
      $hashChildWindow.Ok_Button_Grid.Visibility = 'Hidden'
      $hashChildWindow.Ok_Button_Grid.Width = '0'
      $hashChildWindow.Cancel_Button_Text.text = 'OK'
      $hashChildWindow.Cancel_Button_Text.HorizontalAlignment="Center"
    }
    $hashChildWindow.Ok_Button_Image.source = "$($Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png"
    $hashChildWindow.Ok_Button_Image.source.freeze()
    $hashChildWindow.Ok_Button.add_click({     
        param($Sender)          
        try{  
          if($sendername -eq 'OpenAI' -and $Prompt){
            write-ezlogs ">>>> Prompting for OpenAI"
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
            $Result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashChildWindow.Window,'Ask Samson a Question?','Ask any question and Samson will have the answer',$Button_Settings)
            if(-not [string]::IsNullOrEmpty($Result)){ 
              #TODO: TEST ONLY - MODULE NOT INCLUDED ANYMORE - LEAVING FOR FUTURE
              Invoke-OpenAI -synchash $synchash -thisApp $thisApp -Prompt $Result
            }else{
              write-ezlogs 'No prompt was supplied - aborting' -showtime -warning
              return
            }
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            if($synchash.App_Update_Status.isUpdate_Available){
              $message = 'Would you like to download the latest version?'
            }else{
              $message = 'Would you like to download and re-install the latest version?'
            }
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashChildWindow.Window,'Download and Install Latest Version',"$message`n`nNOTE: The update system is still work-in-progress",$okandCancel,$Button_Settings)
            if($result -eq 'Affirmative'){
              write-ezlogs "User wishes to proceed to download/install updates" -loglevel 2
              Install-Updates -synchash $synchash -thisApp $thisApp -Download_Destination "$($thisApp.Config.Temp_Folder)\Updates" -Use_Runspace -install_update
              Update-Notifications  -Level 'INFO' -Message "Downloading the latest build/installer, install/update will continue when finished" -VerboseLog -Message_color 'cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold
              $hashChildWindow.Window.close()
            }else{
              write-ezlogs "User said no or chose to cancel" -warning
            }
          }
          #New-DialogNotification -synchash $synchash -thisApp $thisApp -Title '[TESTING] Download Latest Version' -Message '[TESTING] Would you like to download the latest version?' -DialogType Confirm -AffirmativeButtonText 'Yes' -NegativeButtonText 'No' -updates           
          $this = $Null          
        }catch{
          write-ezlogs "An exception occurred closing Show-ChildWindow window" -showtime -catcherror $_
        }    
    })

    $hashChildWindow.Window.add_ContentRendered({     
        param($Sender)          
        try{  
          if($sendername -eq 'OpenAI' -and $Prompt){
            write-ezlogs ">>>> Prompting for OpenAI"
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
            $Result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Sender,'Ask Samson a Question?','Ask any question and Samson will have the answer',$Button_Settings)
            if(-not [string]::IsNullOrEmpty($Result)){ 
              #TODO: TEST ONLY - MODULE NOT INCLUDED ANYMORE - LEAVING FOR FUTURE
              Invoke-OpenAI -synchash $synchash -thisApp $thisApp -Prompt $Result
            }else{
              write-ezlogs 'No prompt was supplied - aborting' -showtime -warning
              return
            }                   
          }         
        }catch{
          write-ezlogs "An exception occurred closing Show-ChildWindow add_Rendered" -showtime -catcherror $_
        }    
    })

    $hashChildWindow.Cancel_Button.add_click({     
        param($Sender)          
        try{            
          $hashChildWindow.Window.close()    
        }catch{
          write-ezlogs "An exception occurred closing Show-ChildWindow window" -showtime -catcherror $_
        }    
    })

    $hashChildWindow.Window.Add_Loaded({
        param($Sender)          
        try{
          #Register window to installed application ID 
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($Sender)      
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering Miniplayer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)    
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }
          $Audio_Path = "$($thisApp.Config.Current_Folder)\Resources\Audio\Bitty_Notification.mp3"
          if($markdownfile -match 'About_FirstRun\.md' -and [system.io.file]::Exists($Audio_Path)){          
            $Paragraph = [System.Windows.Documents.Paragraph]::new()      
            $BlockUIContainer = [System.Windows.Documents.BlockUIContainer]::new()
            $Floater = [System.Windows.Documents.Floater]::new()
            $Floater.HorizontalAlignment = "Center" 
            $Floater.Name = "Media_Floater"
            if($Audio_Path -match '.gif' -or $Audio_Path -match '.mp3' -or $Audio_Path -match '.mp4'){ 
              $Media_Element = [System.Windows.Controls.MediaElement]::new() 
              $Media_Element.UnloadedBehavior = 'Close'  
              $Media_Element.LoadedBehavior="Manual"  
              $Media_Element.Name = 'Media_Element'     
              $Media_Element.Source = $Audio_Path    
              $Media_Element.Add_MediaEnded({   
                  param($Sender) 
                  try{
                    if($hashChildWindow.EditorHelpFlyout.Document.Blocks){
                      write-ezlogs ">>>> Removing Audio Notification paragraph"
                      $hashChildWindow.EditorHelpFlyout.Document.Blocks.clear()                     
                    }
                    write-ezlogs ">>>> Disposing notification media"
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()
                  }catch{
                    write-ezlogs "An exception occurred in Media_Element.Add_MediaEnded" -catcherror $_
                  }
              })    
              $Media_Element.add_MediaFailed({
                  param($Sender) 
                  try{
                    write-ezlogs "An exception occurred in media element $($sender | out-string)" -warning
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()   
                  }catch{
                    write-ezlogs "An exception occurred in Media_Element.add_MediaFailed" -catcherror $_
                  }               
              }) 
              $Media_Element.Play()                     
              $BlockUIContainer.AddChild($Media_Element) 
            }   
            $floater.AddChild($BlockUIContainer)   
            $Paragraph.addChild($floater)
            $null = $hashChildWindow.EditorHelpFlyout.Document.Blocks.Add($Paragraph)
          }


          <#          function Get-ScrollViewer
              {

              param(
              [Windows.DependencyObject]$obj = $hashChildWindow.'MarkdownScrollViewer'
              )
    
              process {
              while (!($obj -is [System.Windows.Controls.ScrollViewer])) {
              if([Windows.Media.VisualTreeHelper]::GetChildrenCount($obj) -gt 0){
              $obj = [Windows.Media.VisualTreeHelper]::GetChild($obj -as [Windows.Media.Visual],0)
              }else{
              return $Null
              }               
              }  
              return $obj -as [System.Windows.Controls.ScrollViewer]  
              }
              }
              $ScrollViewer =  Get-ScrollViewer $hashChildWindow.'MarkdownScrollViewer'
         
              if($ScrollViewer){            
              $scrollviewer.SetValue([ScrollAnimateBehavior.AttachedBehaviors.ScrollAnimationBehavior]::IsEnabledProperty,$true)
              $scrollviewer.SetValue([ScrollAnimateBehavior.AttachedBehaviors.ScrollAnimationBehavior]::PointsToScrollProperty,[double]30)
              $scrollviewer.SetValue([ScrollAnimateBehavior.AttachedBehaviors.ScrollAnimationBehavior]::TimeDurationProperty,[timespan]::FromMilliseconds('500'))
              write-ezlogs "Scrollviewer?: $($ScrollViewer | out-string)"
          }#>
        }catch{
          write-ezlogs "An exception occurred in hashChildWindow.Window.Add_Loaded" -showtime -catcherror $_
          return
        }   
    }) 

    $hashChildWindow.Window.Add_UnLoaded({     
        param($Sender)    
        if($sender -eq $hashChildWindow.Window){        
          try{
            write-ezlogs " | Disposing ChildWindow application thread" -showtime
            if($hashChildWindow.appContext){
              $hashChildWindow.appContext.ExitThread()
              $hashChildWindow.appContext.dispose()
              $hashChildWindow.appContext = $Null
            }
            $hashkeys = [System.Collections.ArrayList]::new($hashChildWindow.keys)
            $hashkeys | & { process {
                if($hashChildWindow.Window.FindName($_)){
                  #write-ezlogs ">>>> Unregistering ChildWindow UI name: $_"
                  $null = $hashChildWindow.Window.UnRegisterName($_)
                  $hashChildWindow.$_ = $Null
                }        
            }}
            $hashChildWindow.Window = $Null
            $hashkeys = $null
            write-ezlogs "ChildWindow disposed" -logtype Perf -loglevel 2 -GetMemoryUsage -forceCollection
            return       
          }catch{
            write-ezlogs "An exception occurred in Show-ChildWindow unloaded event" -showtime -catcherror $_
            return
          }
        }      
    })  

    $hashChildWindow.Window.add_closed({     
        param($Sender)          
        try{  
          if($synchash.OpenAI_CurrentConversation){
            write-ezlogs ">>>> Resetting current conversation with OpenAI" -Dev_mode
            $synchash.OpenAI_CurrentConversation = $Null
          }
          if($hashChildWindow.AboutFirstRun_timer){
            $hashChildWindow.AboutFirstRun_timer.stop()
            $hashChildWindow.AboutFirstRun_timer = $Null
          }
          if($markdownfile -match 'About_FirstRun\.md' -and (!$thisapp.config.IsRead_AboutFirstRun -or !$thisapp.config.IsRead_SpecialFirstRun)){
            Add-Member -InputObject $thisapp.config -Name 'IsRead_AboutFirstRun' -Value $true -MemberType NoteProperty -Force
            Add-Member -InputObject $thisapp.config -Name 'IsRead_SpecialFirstRun' -Value $true -MemberType NoteProperty -Force
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
            #Export-Clixml -InputObject $thisapp.config -Path $thisApp.Config.Config_Path -Force -Encoding UTF8 
            if($synchash.Window -and $synchash.Window.Visibility -eq 'Hidden' -and $use_runspace){
              $Null = $synchash.Window.Dispatcher.InvokeAsync{
                $synchash.Window.Show()
                $synchash.Window.Activate()
              }.Wait()             
            }
          }
          $hashChildWindow.EditorHelpFlyout = $Null 
          $this = $Null          
        }catch{
          write-ezlogs "An exception occurred closing Show-ChildWindow window" -showtime -catcherror $_
        }    
    })   
  
    try{    
      [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashChildWindow.Window)
      [void][System.Windows.Forms.Application]::EnableVisualStyles()   
      $null = $hashChildWindow.Window.Show()
      $window_active = $hashChildWindow.Window.Activate()     
      $hashChildWindow.appContext = New-Object System.Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($hashChildWindow.appContext)     
    }catch{
      write-ezlogs "An exception in Show-ChildWindow screen show dialog" -showtime -catcherror $_ -AlertUI
    }
  }
  try{    
    if($use_runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      $NUll = Start-Runspace $hashChildWindow_Scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name 'Show_ChildWindow' -logfile $thisApp.Config.Log_File -verboselog:$thisApp.Config.Verbose_logging -thisApp $thisApp  
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $hashChildWindow_Scriptblock
    }
  }catch{
    write-ezlogs "An exception occurred starting ChildWindow_Runspace" -showtime -catcherror $_
  }
}

#---------------------------------------------- 
#endregion Show-ChildWindow Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-Notifications','New-DialogNotification','Show-ChildWindow','Update-ChildWindow')
