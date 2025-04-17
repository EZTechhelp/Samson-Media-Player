<#
    .Name
    Start-WPFOverlay

    .Version 
    0.1.0

    .SYNOPSIS
    Creates a new WPF window and sets it to topmost (even above fullscreen apps)

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
#region Start-WPFOverlay
#----------------------------------------------
function Start-WPFOverlay{
  [CmdletBinding()]
  param (
    [string]$GameID,
    [string]$GameTitle,
    [string]$Platform,
    $GameProfile,
    $thisApp,
    $synchash,
    [switch]$use_Runspace,
    [switch]$VerboseLog
  )
  try{
    write-ezlogs ">>>> Starting OverlayWindow"
    $ViewsPath = "$($thisApp.Config.Current_Folder)\Views\OverlayWindow.xaml"
    if([System.io.File]::Exists($ViewsPath)){
      $WindowXAML = [System.IO.File]::ReadAllText($ViewsPath)
      if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.PrimaryAccentColor){
        $PrimaryAccentColor = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
      }else{
        $PrimaryAccentColor = "{StaticResource MahApps.Brushes.Accent}"
      }
      $xaml = ($WindowXAML).replace('Views/Styles.xaml',"$($thisApp.Config.Current_Folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$($PrimaryAccentColor)").Replace("{CURRENT_FOLDER}","$($thisApp.Config.Current_Folder)")
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      $synchash.OverlayWindow = [Windows.Markup.XAMLReader]::Parse($XAML)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $synchash.OverlayWindow){
          $synchash."$($name)" = $synchash.OverlayWindow.FindName($name)
        }
      }
      $reader.Dispose()
      $synchash.OverlayWindow.Title = "$($thisApp.Config.App_Name) - Version: $($thisApp.Config.App_Version) - Overlay"
      $synchash.OverlayWindow.AllowsTransparency = $true
      $synchash.OverlayWindow.IsWindowDraggable="True"
      $synchash.OverlayWindow.LeftWindowCommandsOverlayBehavior="HiddenTitleBar"
      $synchash.OverlayWindow.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
      $Synchash.OverlayWindow.ShowTitleBar=$false
      $Synchash.OverlayWindow.UseNoneWindowStyle = $true
      $Synchash.OverlayWindow.WindowStyle = 'none'
      $synchash.OverlayWindow.IgnoreTaskbarOnMaximize = $true
      $synchash.OverlayWindow.ShowInTaskbar = $false
      $synchash.OverlayWindow.Topmost = $true
      $synchash.OverlayWindow.WindowState = "Normal"
      if($synchash.Overlay_Title_TextBlock){
        $Binding = [System.Windows.Data.Binding]::new()
        $Binding.Source = $synchash.Now_Playing_Title_Label
        $Binding.Path = "Text"
        $Binding.NotifyOnTargetUpdated = $true
        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Overlay_Title_TextBlock,[System.Windows.Controls.TextBlock]::TextProperty, $Binding)
      }
      if($synchash.Overlay_Artist_TextBlock){
        $Binding = [System.Windows.Data.Binding]::new()
        $Binding.Source = $synchash.Now_Playing_Artist_Label
        $Binding.Path = "Text"
        $Binding.NotifyOnTargetUpdated = $true
        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Overlay_Artist_TextBlock,[System.Windows.Controls.TextBlock]::TextProperty, $Binding)
      }
      $synchash.OverlayWindow.add_Loaded({
          Param($Sender)
          try{
            $current_Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($Sender)
            if($thisApp.Config.Installed_AppID){
              $appid = $thisApp.Config.Installed_AppID
            }else{
              $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
            }
            if($current_Window_Helper.Handle -and $appid){        
              $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
              write-ezlogs ">>>> Registering main window handle: $($current_Window_Helper.Handle) -- to appid: $appid" -Dev_mode
              $taskbarinstance.SetApplicationIdForSpecificWindow($current_Window_Helper.Handle,$appid)
              if($thisApp.Config.Installed_AppID -ne $appid){
                $thisApp.Config.Installed_AppID = $appid
              }
            } 
            $Sender.Top = 5
            $Sender.Left = 5
          }catch{
            write-ezlogs "An exception occurred in OverlayWindow Loaded event" -catcherror $_
          }
      })
      $synchash.OverlayWindow_KeyboardFocusScriptblock = {
        param([Parameter(Mandatory)][Object]$sender,$e)
        try{
          if($e.NewValue){
            $Newvalue = $e.NewValue
          }else{
            $newValue = $e.NewFocus
          }
          if($e.OldValue -ne $null){
            $Oldvalue = $e.OldValue
          }else{
            $OldValue = $e.OldFocus
          }
          write-ezlogs ">>>> Window with name: $($sender.Name) -- and title: $($sender.Title) -- focus changed -- Old: $($Oldvalue) -- New: $($Newvalue) -- E.Type: $($e) - Sender.isFocused: $($sender.isFocused)" -Dev_mode
          Set-WindowTopMost -thisApp $thisApp -Window $sender -Force
          $Sender.Activate()
        }catch{
          write-ezlogs "An exception occurred in IsKeyboardFocusedChanged event" -CatchError $_
        }
      }
      
      $synchash.OverlayWindow.add_MouseLeave($synchash.OverlayWindow_KeyboardFocusScriptblock)
      $synchash.OverlayWindow.add_PreviewGotKeyboardFocus($synchash.OverlayWindow_KeyboardFocusScriptblock)
      $synchash.OverlayWindow.add_PreviewLostKeyboardFocus($synchash.OverlayWindow_KeyboardFocusScriptblock)
      $synchash.OverlayWindow.add_IsKeyboardFocusedChanged($synchash.OverlayWindow_KeyboardFocusScriptblock)
      $synchash.OverlayWindow.add_IsKeyboardFocusWithinChanged($synchash.OverlayWindow_KeyboardFocusScriptblock)
      $synchash.OverlayWindow.add_ContentRendered({
          Param($Sender)
          try{
            $Sender.ShowActivated = $true
            Set-WindowTopMost -thisApp $thisApp -Window $sender
            $Sender.Activate()
          }catch{
            write-ezlogs "An exception occurred in OverlayWindow ContentRendered event" -catcherror $_
          }
      })

      $synchash.OverlayWindow.add_Unloaded({
          try{
            write-ezlogs ">>>> OverlayWindow has unloaded"
            $synchash.OverlayWindow.Remove_MouseLeave($synchash.OverlayWindow_KeyboardFocusScriptblock)
            $synchash.OverlayWindow.Remove_PreviewGotKeyboardFocus($synchash.OverlayWindow_KeyboardFocusScriptblock)
            $synchash.OverlayWindow.Remove_PreviewLostKeyboardFocus($synchash.OverlayWindow_KeyboardFocusScriptblock)
            $synchash.OverlayWindow.Remove_IsKeyboardFocusedChanged($synchash.OverlayWindow_KeyboardFocusScriptblock)
            $synchash.OverlayWindow.Remove_IsKeyboardFocusWithinChanged($synchash.OverlayWindow_KeyboardFocusScriptblock)
            $null = $synchash.Remove('OverlayWindow')
            $this = $Null
            if($synchash.Overlay_Button.isOn){
              $synchash.Overlay_Button.isOn = $false
            }
          }catch{
            write-ezlogs "An exception occurred in OverlayWindow.add_closed event" -CatchError $_
          }
      })
      if($synchash.OverlayClose_Button){
        $synchash.OverlayClose_Button.add_Click({
            param($sender)
            try{
              if($synchash.OverlayWindow.isVisible){
                write-ezlogs ">>>> Closing OverlayWindow"
                $synchash.OverlayWindow.close()
              }              
            }catch{
              write-ezlogs 'An exception occurred in OverlayClose_Button click event' -showtime -catcherror $_
            }
        })
      }
      [void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.OverlayWindow)
      $synchash.OverlayWindow.Show()
    }else{
      write-ezlogs "Failed to load OverlayWindow - xaml files not found! -- Cannot continue!" -warning
    }
  }catch{
    write-ezlogs "An exception occurred in WPFOverlay" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Start-WPFOverlay
#----------------------------------------------
Export-ModuleMember -Function @('Start-WPFOverlay')
