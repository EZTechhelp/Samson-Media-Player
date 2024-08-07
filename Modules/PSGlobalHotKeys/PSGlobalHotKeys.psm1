<#
    .Name
    PSGlobalHotKeys

    .Version 
    0.1.0

    .SYNOPSIS
    Monitors and captures keyboard events for media player controls 

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
#region Get-GlobalHotKeys Function
#----------------------------------------------
function Get-GlobalHotKeys{
  param (
    $synchash,
    $thisApp,
    [switch]$Register,
    [switch]$UnRegister,
    [switch]$Shutdown
  )
  try{
    if($thisApp.Config.startup_perf_timer){
      $HotKeys_Measure = [system.diagnostics.stopwatch]::StartNew()
    }
    if(-not [bool]('mrousavy.HotKey' -as [Type])){
      [void][System.Reflection.Assembly]::LoadFrom("$($thisApp.Config.Current_folder)\Assembly\EZT-MediaPlayer\Hotkeys.dll")
    }
    if($UnRegister){
      if($synchash.VolUphotkey -is [System.IDisposable]){
        write-ezlogs "| Disposing and unregistering existing VolUphotkey" -loglevel 2
        [Void]$synchash.VolUphotkey.dispose()
        $synchash.VolUphotkey = $null
      } 
      if($synchash.VolDownhotkey -is [System.IDisposable]){
        write-ezlogs "| Disposing and unregistering existing VolDownhotkey" -loglevel 2
        [Void]$synchash.VolDownhotkey.dispose()
        $synchash.VolDownhotkey = $null
      }  
      if($synchash.VolMutehotkey -is [System.IDisposable]){
        write-ezlogs "| Disposing and unregistering existing VolMutehotkey" -loglevel 2
        [Void]$synchash.VolMutehotkey.dispose()
        $synchash.VolMutehotkey = $null
      }
      if(!$Register -and !$Shutdown){
        if($synchash.Hotkeys_Button.isEnabled -and !$synchash.Hotkeys_Button.isChecked){
          $synchash.Hotkeys_Button.isChecked = $false
        }
        if($thisApp.Config.EnableGlobalHotKeys){
          $thisApp.Config.EnableGlobalHotKeys = $false
        }
        if($synchash.Hotkeys_Button.ToolTip -ne 'Global HotKeys Currently Disabled'){
          $synchash.Hotkeys_Button.ToolTip = 'Global HotKeys Currently Disabled'
        }
        if($synchash.Hotkeys_Icon.Kind -eq 'KeyboardOutline'){
          $synchash.Hotkeys_Icon.Kind = 'KeyboardOffOutline'
        }
      }
    }
    if($Register){
      write-ezlogs "#### Registering Global HotKeys ####" -color yellow -linesbefore 1 -LogLevel 2
      if($synchash.MiniPlayer_Viewer.isInitialized){
        $Window = [System.Windows.Interop.WindowInteropHelper]::new($synchash.MiniPlayer_Viewer) 
      }elseif($synchash.Window.isInitialized){
        $Window = [System.Windows.Interop.WindowInteropHelper]::new($synchash.Window) 
      }
      if($window){
        [Action`1[mrousavy.HotKey]]$Action = {
          try{
            if($args -eq $synchash.VolUphotkey){
              write-ezlogs ">>>> Global VolUphotkey pressed - Modifier: $($args.KeyModifier) + Key: $($args.Key)" -showtime      
              if($thisApp.Config.Media_Volume -lt 100){            
                if($thisApp.Config.Media_Volume -ge 95){
                  $thisApp.Config.Media_Volume = 100
                }else{
                  $thisApp.Config.Media_Volume = ($thisApp.Config.Media_Volume + 1)
                }
                if($synchash.Volume_Slider -and $synchash.Volume_Slider.value -ne $thisApp.Config.Media_Volume){
                  write-ezlogs " | Increasing volume by 1: $($thisApp.Config.Media_Volume)" -showtime
                  $synchash.Volume_Slider.value = $thisApp.Config.Media_Volume  
                }       
              }else{
                write-ezlogs " | Volume is already at max $($thisApp.Config.Media_Volume)" -showtime -warning
              }
            }elseif($args -eq $synchash.VolDownhotkey){
              write-ezlogs ">>>> Global VolDownhotkey pressed - Modifier: $($args.KeyModifier) + Key: $($args.Key)" -showtime    
              if($thisApp.Config.Media_Volume -gt 0){             
                if($thisApp.Config.Media_Volume -le 5){
                  $thisApp.Config.Media_Volume = 0
                }else{
                  $thisApp.Config.Media_Volume = ($thisApp.Config.Media_Volume - 1)
                }
                if($synchash.Volume_Slider -and $synchash.Volume_Slider.value -ne $thisApp.Config.Media_Volume){
                  write-ezlogs " | Decreasing volume by 1: $($thisApp.Config.Media_Volume)" -showtime
                  $synchash.Volume_Slider.value = $thisApp.Config.Media_Volume
                }                            
              }else{
                write-ezlogs " | Volume is already at lowest $($thisApp.Config.Media_Volume)" -showtime -warning
              }
            }elseif($args -eq $synchash.VolMutehotkey){
              write-ezlogs ">>>> Global VolMutehotkey pressed - Modifier: $($args.KeyModifier) + Key: $($args.Key)" -showtime  
              write-ezlogs " | Toggling Mute" -showtime
              Set-Mute -thisApp $thisApp -synchash $synchash
            }else{
              write-ezlogs "Pressed registered Hotkey with action assigned: $($args | out-string)" -showtime -Warning
            }
          }catch{
            write-ezlogs "An exception occurred in global hotkey action" -CatchError $_
          }
        }
        try{
          foreach($Hotkey in $thisApp.Config.GlobalHotKeys){
            if($hotkey.Modifier -eq 'Shift'){
              $Modifier = [System.Windows.Input.ModifierKeys]::Shift
            }elseif($hotkey.Modifier -eq 'Alt'){
              $Modifier = [System.Windows.Input.ModifierKeys]::Alt
            }elseif($hotkey.Modifier -eq 'Control'){
              $Modifier = [System.Windows.Input.ModifierKeys]::Control
            }elseif($hotkey.Modifier -eq 'Windows'){
              $Modifier = [System.Windows.Input.ModifierKeys]::Windows
            }else{
              $Modifier = [System.Windows.Input.ModifierKeys]::None
            }
            if([System.Windows.Input.Key]::($hotkey.key)){
              write-ezlogs "| Registering $($hotkey.Name) - Modifier: $($Modifier) + Key: $($hotkey.key)" -showtime
              try{
                $synchash.$($hotkey.Name) = [mrousavy.HotKey]::New($Modifier,[System.Windows.Input.Key]::($hotkey.key),$Window,$Action)
              }catch{
                if($_ -match 'Hotkey may already be in use'){
                  write-ezlogs "Failed to register global hotkey: $($hotkey.Name) - hotkey may already be in use!" -warning
                }else{
                  write-ezlogs "An exception occurred registering global hotkey: $($hotkey.Name)" -CatchError $_
                }
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred registering global hotkeys" -CatchError $_         
        }
        $thisApp.Config.EnableGlobalHotKeys = $true
        if($thisApp.Config.GlobalHotKeys.name){
          $toolTip = @"
Global HotKeys Currently Enabled:

$($thisApp.Config.GlobalHotKeys.name[0])       : $($thisApp.Config.GlobalHotKeys.key[0])
$($thisApp.Config.GlobalHotKeys.name[1])  : $($thisApp.Config.GlobalHotKeys.key[1])
$($thisApp.Config.GlobalHotKeys.name[2])   : $($thisApp.Config.GlobalHotKeys.key[2])
"@
        }else{
         $ToolTip = 'Global HotKeys Currently Disabled - No Hotkeys have been configured'
        }
        if($synchash.Hotkeys_Button.isEnabled -and !$synchash.Hotkeys_Button.isChecked){
          $synchash.Hotkeys_Button.isChecked = $true
        }
        if($synchash.Hotkeys_Button.ToolTip -ne $toolTip){
          $synchash.Hotkeys_Button.ToolTip = $toolTip
        }
        if($synchash.Hotkeys_Icon.Kind -eq 'KeyboardOffOutline'){
          $synchash.Hotkeys_Icon.Kind = 'KeyboardOutline'
        }
        #$synchash.VolUphotkey = [mrousavy.HotKey]::New([System.Windows.Input.ModifierKeys]::Alt -bor [System.Windows.Input.ModifierKeys]::Control,[System.Windows.Input.Key]::E,$Window,$Action)
      }
    }
    return
  }catch{
    write-ezlogs "An exception occured in Get-GlobalHotKeys" -catcherror $_
  }finally{
    if($HotKeys_Measure){
      $HotKeys_Measure.stop()
      write-ezlogs ">>>> Get-GlobalHotKeys Measure" -PerfTimer $HotKeys_Measure
      $HotKeys_Measure = $Null
    }
  }
}
#---------------------------------------------- 
#endregion Get-GlobalHotKeys Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-GlobalHotKeys')

