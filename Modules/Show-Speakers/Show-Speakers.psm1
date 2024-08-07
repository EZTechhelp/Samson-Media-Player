<#
    .Name
    Show-Speakers 

    .Version 
    0.1.1

    .SYNOPSIS
    Displays simple Speaker graphic windows for Samson UI 

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
#region Update-Speakers Function
#----------------------------------------------
function Update-Speakers {
  Param (
    [string]$SplashTitle,
    $hash,
    $synchash,
    [string]$Speaker,
    [switch]$EnableBeats,
    [switch]$DisableBeats,
    [switch]$Show,
    [switch]$Hide,
    [switch]$close,
    [switch]$screenshot,
    [string]$Visibility = 'Visible',
    [switch]$verboselog = $true,
    [switch]$Startup
  )
  try{
    if($Startup){
      $timer = [System.Windows.Threading.DispatcherTimer]::new()
      $timer.add_tick({
          try{
            if(-not [string]::IsNullOrEmpty($this.tag.SplashTitle)){
              if($this.tag.Speaker -eq 'Left' -and $hashSpeakerLeft.SplashTitle){
                $hashSpeakerLeft.SplashTitle.Content=$this.tag.SplashTitle
              }elseif($this.tag.Speaker -eq 'Right' -and $hashSpeakerRight.SplashTitle){
                $hashSpeakerRight.SplashTitle.Content=$this.tag.SplashTitle
              }     
            }
            if($this.tag.Show){
              if($this.tag.Speaker -eq 'Left' -and $hashSpeakerLeft.Window){
                $hashSpeakerLeft.Window.show()
              }elseif($this.tag.Speaker -eq 'Right' -and $hashSpeakerRight.Window){
                $hashSpeakerRight.Window.show()
              } 
            }
            if($this.tag.Hide){
              if($this.tag.Speaker -eq 'Left' -and $hashSpeakerLeft.Window){
                $hashSpeakerLeft.Window.Hide()
              }elseif($this.tag.Speaker -eq 'Right' -and $hashSpeakerRight.Window){
                $hashSpeakerRight.Window.Hide()
              }
            }  
            if($this.tag.Close){
              if($this.tag.Speaker -eq 'Left' -and $hashSpeakerLeft.Window){
                $hashSpeakerLeft.Window.Close() 
                if($synchash.SpeakerLeft_ToggleButton){
                  [void]$synchash.SpeakerLeft_ToggleButton.Dispatcher.InvokeAsync{
                    $synchash.SpeakerLeft_ToggleButton.isChecked = $false
                  }
                }
              }elseif($this.tag.Speaker -eq 'Right' -and $hashSpeakerRight.Window){
                $hashSpeakerRight.Window.Close() 
                if($synchash.SpeakerRight_ToggleButton){
                  [void]$synchash.SpeakerRight_ToggleButton.Dispatcher.InvokeAsync{
                    $synchash.SpeakerRight_ToggleButton.isChecked = $false
                  }
                }

              }
            } 
            if($this.tag.EnableBeats){
              if($this.tag.Speaker -eq 'Left'){
                $hashSpeakerLeft.Beats.ItemsSource = $hashSpeakerLeft.FrequencyObservers
              }elseif($this.tag.Speaker -eq 'Right'){
                $hashSpeakerRight.Beats.ItemsSource = $hashSpeakerRight.FrequencyObservers           
              }
            }
            if($this.tag.DisableBeats){
              if($this.tag.Speaker -eq 'Left'){
                $hashSpeakerLeft.Beats.ItemsSource = $null
              }elseif($this.tag.Speaker -eq 'Right'){
                $hashSpeakerRight.Beats.ItemsSource = $null           
              }
            }
            if($this.tag.screenshot){
              if($this.tag.Speaker -eq 'Left'){
                $hashSpeakerLeft.Window.TopMost = $true
                $hashSpeakerLeft.Window.Activate() 
                start-sleep -Milliseconds 500
                write-ezlogs ">>>> Taking Snapshot of Show-LeftSpeaker window" -showtime
                $translatepoint = $hashSpeakerLeft.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
                $locationfromscreen = $hashSpeakerLeft.Window.PointToScreen($translatepoint)
                $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
              }elseif($this.tag.Speaker -eq 'Right'){
                $hashSpeakerRight.Window.TopMost = $true
                $hashSpeakerRight.Window.Activate() 
                start-sleep -Milliseconds 500
                write-ezlogs ">>>> Taking Snapshot of Show_RightSpeaker window" -showtime
                $translatepoint = $hashSpeakerRight.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
                $locationfromscreen = $hashSpeakerRight.Window.PointToScreen($translatepoint)
                $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
              }
           
            }                              
            $this.Stop()
          }catch{
            write-ezlogs "An exception occurred in Update_Timer.add_tick" -showtime -catcherror $_
          }finally{
            $this.Stop()
          }
      }) 
      if($Speaker -eq 'Left'){
        $hashSpeakerLeft.SpeakerLeft_Update_timer = $timer
      }elseif($Speaker -eq 'Right'){
        $hashSpeakerRight.SpeakerRight_Update_timer = $timer
      }else{
        return
      }
    }else{
      if($Speaker -eq 'Left'){
        $hashSpeakerLeft.SpeakerLeft_Update_timer.tag = [PSCustomObject]::new(@{
            'Speaker' = $Speaker
            'SplashTitle' = $SplashTitle
            'EnableBeats' = $EnableBeats
            'DisableBeats' = $DisableBeats
            'Visibility' = $Visibility
            'screenshot' = $screenshot
            'Show' = $Show
            'Hide' = $hide
            'Close' = $close
        })  
        $hashSpeakerLeft.SpeakerLeft_Update_timer.start() 
      }elseif($Speaker -eq 'Right'){
        $hashSpeakerRight.SpeakerRight_Update_timer.tag = [PSCustomObject]::new(@{
            'Speaker' = $Speaker
            'SplashTitle' = $SplashTitle
            'EnableBeats' = $EnableBeats
            'DisableBeats' = $DisableBeats
            'Visibility' = $Visibility
            'screenshot' = $screenshot
            'Show' = $Show
            'Hide' = $hide
            'Close' = $close
        })  
        $hashSpeakerRight.SpeakerRight_Update_timer.start() 
      }else{
        return
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Update-Speakers" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-Speakers Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-LeftSpeaker Function
#----------------------------------------------
function Show-LeftSpeaker{
  Param (
    [string]$SplashTitle,
    [switch]$ShowDialog,
    [string]$Runspace_name,
    $thisApp,
    $synchash,
    $hashSpeakerLeft,
    [string]$Splash_More_Info,
    [string]$SplashLogo,
    [switch]$verboselog,
    [switch]$start_hidden,
    [switch]$Debug_verboselog,
    [string]$SplashMessage
  )      
  $SpeakerLeft_Pwshell = {
    Param (
      [string]$SplashTitle,
      [switch]$ShowDialog,
      [string]$Runspace_name,
      $thisApp,
      $synchash,
      $hashSpeakerLeft,
      [string]$Splash_More_Info,
      [string]$SplashLogo,
      [switch]$verboselog,
      [switch]$start_hidden,
      [switch]$Debug_verboselog,
      [string]$SplashMessage
    )
    try{        
      Update-Speakers -hash $hashSpeakerLeft -Startup -Speaker 'Left'
      $SpeakerLeft_Window_XML = "$($thisApp.Config.Current_Folder)\Views\Speakers.xaml"
      [xml]$xaml = [System.IO.File]::ReadAllText($SpeakerLeft_Window_XML) 
      $reader = [System.Xml.XmlNodeReader]::new($xaml)
      $hashSpeakerLeft.window = [Windows.Markup.XamlReader]::Load($reader)                       
    }catch{
      write-ezlogs "An exception occurred loading Show-LeftSpeaker XAML" -showtime -catcherror $_ 
    }
    try{
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | & { process {$hashSpeakerLeft."$($_.Name)" = $hashSpeakerLeft.window.FindName($_.Name)}}
      $reader.dispose() 
      $hashSpeakerLeft.Window.icon = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"  
      $hashSpeakerLeft.Window.icon.freeze()
      $hashSpeakerLeft.window.title =$SplashTitle    
      $hashSpeakerLeft.Beats.tag = [PSCustomObject]@{
          'Source' = "$($thisApp.Config.Current_Folder)\Resources\Images\Samson_Speaker_Left_Small_Woofer.png" 
          'Width' = "165"
          'Height' = "164"
      }
      $hashSpeakerLeft.Beats.Margin = "4.5,10,0,30.5"

      $synchash.Window.Dispatcher.invokeAsync({         
          if($synchash.AudioSpectrum.DataContext.IsCapturing){
            $hashSpeakerLeft.FrequencyObservers = $synchash.AudioSpectrum.DataContext.FrequencyObservers
          }             
      }).Wait()
      $samsonspeakers = [System.IO.Directory]::EnumerateFiles("$($thisApp.Config.Current_Folder)\Resources\Images\",'*_Speaker_Left_Small.png','TopDirectoryOnly')
      if(-not [string]::IsNullOrEmpty($thisApp.Config.Last_SpeakerLeft_Image)){
        $samsonspeakerimage = $samsonspeakers | where {$_ -notmatch [regex]::Escape($thisApp.Config.Last_SpeakerLeft_Image)} | Get-Random -count 1
      }else{
        $samsonspeakerimage = $samsonspeakers | Get-Random -count 1
      } 
      if(!$samsonspeakerimage){
        $samsonspeakerimage = $samsonspeakers | Get-Random -count 1 
      }        
      if($thisApp.Config){
        $thisApp.Config.Last_SpeakerLeft_Image = $samsonspeakerimage
      }
      $hashSpeakerLeft.Background_Image.source = $samsonspeakerimage
      if($samsonspeakers -match 'Small.png'){
        $hashSpeakerLeft.Window.Height="381"
        $hashSpeakerLeft.Window.Width="313"
        $hashSpeakerLeft.Background_Image.Height="381"
        $hashSpeakerLeft.Background_Image.Width="313"
      }else{
        $hashSpeakerLeft.Window.Height="547"
        $hashSpeakerLeft.Window.Width="450"
        $hashSpeakerLeft.Background_Image.Height="547"
        $hashSpeakerLeft.Background_Image.Width="450"
      }
      #$PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen  
      $hashSpeakerLeft.IsVideoOpen = $Null
      $synchash.Window.Dispatcher.invoke([action]{
          $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
          $hashSpeakerLeft.locationfromscreen = $synchash.Window.PointToScreen($translatepoint) 
          $current_Monitor = [System.Windows.Interop.WindowInteropHelper]::new($synchash.Window)
          $hashSpeakerLeft.current_monitor_info = [System.Windows.Forms.Screen]::FromHandle($current_Monitor.Handle)           
          $hashSpeakerLeft.IsVideoOpen = $synchash.VideoButton_ToggleButton.isChecked  
      },'Normal')        
      if($hashSpeakerLeft.current_monitor_info.bounds.Width -lt 2560){
        $hashSpeakerLeft.Window.Left = ($hashSpeakerLeft.locationfromscreen.X)
        if($hashSpeakerLeft.IsVideoOpen){
          $hashSpeakerLeft.Window.Top = ($hashSpeakerLeft.locationfromscreen.Y + 81)
        }else{
          $hashSpeakerLeft.Window.Top = ($hashSpeakerLeft.locationfromscreen.Y + 100 - ($synchash.Window.ActualHeight)) 
        }          
      }else{
        $hashSpeakerLeft.Window.Left = ($hashSpeakerLeft.locationfromscreen.X - $hashSpeakerLeft.Window.Width)
        $hashSpeakerLeft.Window.Top = ($hashSpeakerLeft.locationfromscreen.Y + 100)      
      }
    }catch{
      write-ezlogs "An exception occurred loading image for Show-LeftSpeaker" -showtime -catcherror $_
    }        
    $hashSpeakerLeft.Window.add_MouseLeftButtonDown({
        $sender = $args[0]
        [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
        try{
          #write-ezlogs "$($e | out-string)"
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
          {
            $hashSpeakerLeft.Window.DragMove()
            $e.handled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Show-LeftSpeaker MouseLeftButtonDown event" -showtime -catcherror $_
        }
    }) 
    $hashSpeakerLeft.Window.Add_loaded({     
        param($Sender)                
        $hashSpeakerLeft.Beats.ItemsSource = $hashSpeakerLeft.FrequencyObservers  
        $Audio_Path = "$($thisApp.Config.Current_Folder)\Resources\Audio\Samson_Notification.mp3"
        if($thisapp.config.Notification_Audio -and [system.io.file]::Exists($Audio_Path)){          
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
            $Media_Element.Play()   
            $Media_Element.Add_MediaEnded({   
                param($Sender) 
                try{
                  if($hashSpeakerLeft.Notification_Media.Document.Blocks){
                    write-ezlogs ">>>> Removing Audio Notification paragraph"
                    $hashSpeakerLeft.Notification_Media.Document.Blocks.clear()                     
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
            $BlockUIContainer.AddChild($Media_Element)
          }   
          $floater.AddChild($BlockUIContainer)   
          $Paragraph.addChild($floater)
          $null = $hashSpeakerLeft.Notification_Media.Document.Blocks.Add($Paragraph)
        }else{
          write-ezlogs "Unable to play media: '$($Audio_Path)' - Notification_Audio: $($thisapp.config.Notification_Audio)" -warning
        } 
        #Register window to installed application ID 
        $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($hashSpeakerLeft.Window)      
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
    })
    #Add Exit   
    $hashSpeakerLeft.Closed_Event = {
      param($sender)
      try{
        Write-ezlogs ">>>> SpeakerLeft window has closed"
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SpeakerLeft_ToggleButton' -Property 'isChecked' -value $false
      }catch{
        write-ezlogs "An exception occurred in hashSpeakerLeft.Closed_Event" -showtime -catcherror $_
      }
    }
    $hashSpeakerLeft.Window.Add_Closed($hashSpeakerLeft.Closed_Event)
    #region Unloaded Event
    [System.Windows.RoutedEventHandler]$hashSpeakerLeft.Unloaded_Event = {
      param($sender,[System.Windows.RoutedEventArgs]$e)
      try{
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent) -RemoveHandlers -VerboseLog
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers -VerboseLog
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers -VerboseLog
        $Null = $sender.Remove_Closed($hashSpeakerLeft.Closed_Event)
        $hashkeys = [System.Collections.ArrayList]::new($hashSpeakerLeft.keys)
        $hashkeys | & { process {
            if($hashSpeakerLeft.Window.FindName($_)){
              if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Unregistering hashSpeakerLeft UI name: $_" -Dev_mode}
              $null = $hashSpeakerLeft.Window.UnRegisterName($_)
              $hashSpeakerLeft.$_ = $Null
            }        
        }}
        $hashSpeakerLeft.Window = $Null
        $hashSpeakerLeft = $null
        $hashkeys = $Null
        write-ezlogs ">>>> Exiting application context thread for SpeakerRight.Window" -showtime
        [System.Windows.Threading.Dispatcher]::ExitAllFrames()
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
        #Remove-Variable hashedit
        write-ezlogs ">>>> SpeakerLeft.Window has unloaded" -loglevel 2 -GetMemoryUsage -forceCollection                      
      }catch{
        write-ezlogs "An exception occurred in SpeakerLeft.Window.add_Unloaded" -showtime -catcherror $_
      }
    }
    $Null = $hashSpeakerLeft.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$hashSpeakerLeft.Unloaded_Event)
    #endregion Unloaded Event       
    try{          
      if(!$start_hidden){
        $null = $hashSpeakerLeft.window.Show()
        $null = $hashSpeakerLeft.Window.Activate() 
      }          
    }catch{
      write-ezlogs "An exception occurred when opening Show-LeftSpeaker window" -showtime -catcherror $_ 
    }  
    try{
      [System.Windows.Threading.Dispatcher]::Run()    
    }catch{
      write-ezlogs "An exception occurred when opening main Show-LeftSpeaker window" -showtime -catcherror $_ 
    } 
  }
  try{ 
    #$Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}  
    $Null = Start-Runspace $SpeakerLeft_Pwshell -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -runspace_name "Show_LeftSpeaker_Runspace"  -verboselog:$verboselog    
    #$Variable_list = $Null
  }catch{
    write-ezlogs "An exception occurred when creating runspace for Show-LeftSpeaker window" -showtime -catcherror $_        
  }   
}
#---------------------------------------------- 
#endregion Show-LeftSpeaker Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-RightSpeaker Function
#----------------------------------------------
function Show-RightSpeaker{
  Param (
    [string]$SplashTitle,
    [switch]$ShowDialog,
    [string]$Runspace_name,
    $thisApp,
    $synchash,
    $hashSpeakerRight,
    [string]$Splash_More_Info,
    [string]$SplashLogo,
    [switch]$verboselog,
    [switch]$start_hidden,
    [switch]$Debug_verboselog,
    [string]$SplashMessage
  )     
 
  $SpeakerRight_Pwshell = {
    Param (
      [string]$SplashTitle,
      [switch]$ShowDialog,
      [string]$Runspace_name,
      $thisApp,
      $synchash,
      $hashSpeakerRight,
      [string]$Splash_More_Info,
      [string]$SplashLogo,
      [switch]$verboselog,
      [switch]$start_hidden,
      [switch]$Debug_verboselog,
      [string]$SplashMessage
    )
    try{ 
      Update-Speakers -hash $hashSpeakerRight -Startup -Speaker 'Right'
      $SpeakerRight_Window_XML = "$($thisApp.Config.Current_Folder)\Views\Speakers.xaml"                   
      [xml]$xaml = [System.IO.File]::ReadAllText($SpeakerRight_Window_XML) 
      $reader = [System.Xml.XmlNodeReader]::new($xaml)
      $hashSpeakerRight.window = [Windows.Markup.XamlReader]::Load($reader)                       
    }catch{
      write-ezlogs "An exception occurred loading Show-LeftSpeaker XAML" -showtime -catcherror $_ 
    }
    try{
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | & { process { $hashSpeakerRight."$($_.Name)" = $hashSpeakerRight.window.FindName($_.Name)}}
      $reader.dispose() 
      $hashSpeakerRight.Window.icon = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"  
      $hashSpeakerRight.Window.icon.freeze()
      $hashSpeakerRight.window.title =$SplashTitle      
      $speakerimage = "$($thisApp.Config.Current_Folder)\Resources\Images\Bitty_Speaker_Right_Small.png"   
      $hashSpeakerRight.Background_Image.source = $speakerimage
      $hashSpeakerRight.Beats.tag = [PSCustomObject]@{
          'Source' = "$($thisApp.Config.Current_Folder)\Resources\Images\Bitty_Speaker_Right_Small_Woofer.png" 
          'Width' = "156"
          'Height' = "155"
      }   
      $hashSpeakerRight.Beats.Margin = "1.5,0,0,35"
      $synchash.Window.Dispatcher.invokeAsync({        
          if($synchash.AudioSpectrum.DataContext.IsCapturing){
            $hashSpeakerRight.FrequencyObservers = $synchash.AudioSpectrum.DataContext.FrequencyObservers
          }             
      })
      if($speakerimage -match 'Small.png'){
        $hashSpeakerRight.Window.Height="510"
        $hashSpeakerRight.Window.Width="313"
        $hashSpeakerRight.Background_Image.Height="510"
        $hashSpeakerRight.Background_Image.Width="313"
      }else{
        $hashSpeakerRight.Window.Height="733"
        $hashSpeakerRight.Window.Width="450"
        $hashSpeakerRight.Background_Image.Height="733"
        $hashSpeakerRight.Background_Image.Width="450"
      }
      $hashSpeakerRight.IsVideoOpen = $Null
      $synchash.Window.Dispatcher.invoke([action]{
          $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
          $hashSpeakerRight.locationfromscreen = $synchash.Window.PointToScreen($translatepoint) 
          $current_Monitor = [System.Windows.Interop.WindowInteropHelper]::new($synchash.Window)
          $hashSpeakerRight.current_monitor_info = [System.Windows.Forms.Screen]::FromHandle($current_Monitor.Handle)     
          $hashSpeakerRight.IsVideoOpen = $synchash.VideoButton_ToggleButton.isChecked        
      },'Normal') 
             
      if($hashSpeakerRight.current_monitor_info.bounds.Width -lt 2560){
        $hashSpeakerRight.Window.Left = ($hashSpeakerRight.locationfromscreen.X + $synchash.Window.ActualWidth) - $hashspeakerRight.Window.Width
        if($hashSpeakerRight.IsVideoOpen){
          $hashSpeakerRight.Window.Top = $hashSpeakerRight.locationfromscreen.Y - 47
        }else{
          $hashSpeakerRight.Window.Top = $hashSpeakerRight.locationfromscreen.Y - 28 - ($synchash.Window.ActualHeight)
        }        
      }else{
        $hashSpeakerRight.Window.Left = ($hashSpeakerRight.locationfromscreen.X + $synchash.Window.ActualWidth)
        $hashSpeakerRight.Window.Top = $hashSpeakerRight.locationfromscreen.Y - 28
      }
    }catch{
      write-ezlogs "An exception occurred loading image for Show-RightSpeaker" -showtime -catcherror $_
    }
        
    $hashSpeakerRight.Window.add_MouseLeftButtonDown({
        $sender = $args[0]
        [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
        try{
          if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown'){
            $hashSpeakerRight.Window.DragMove()
            $e.handled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Show-RightSpeaker MouseLeftButtonDown event" -showtime -catcherror $_
        }
    }) 
    #add opened

    $hashSpeakerRight.Window.Add_loaded({     
        param($Sender)                
        $hashSpeakerRight.Beats.ItemsSource = $hashSpeakerRight.FrequencyObservers
        $Audio_Path = "$($thisApp.Config.Current_Folder)\Resources\Audio\Bitty_Notification.mp3"
        if($thisapp.config.Notification_Audio -and [system.io.file]::Exists($Audio_Path)){          
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
            $Media_Element.Play()   
            $Media_Element.Add_MediaEnded({   
                param($Sender) 
                try{
                  if($hashSpeakerRight.Notification_Media.Document.Blocks){
                    write-ezlogs ">>>> Removing Audio Notification paragraph"
                    $hashSpeakerRight.Notification_Media.Document.Blocks.clear()                     
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
            $BlockUIContainer.AddChild($Media_Element) 
          }   
          $floater.AddChild($BlockUIContainer)   
          $Paragraph.addChild($floater)
          $null = $hashSpeakerRight.Notification_Media.Document.Blocks.Add($Paragraph)
        }else{
          write-ezlogs "Unable to play media: '$($Audio_Path)' - Notification_Audio: $($thisapp.config.Notification_Audio)" -warning
        } 
        #Register window to installed application ID 
        $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($hashSpeakerRight.Window)      
        if($thisApp.Config.Installed_AppID){
          $appid = $thisApp.Config.Installed_AppID
        }else{
          $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        }
        if($Window_Helper.Handle -and $appid){
          $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
          write-ezlogs ">>>> Registering Miniplayer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
          $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)
          $thisApp.Config.Installed_AppID = $appid
        }                          
    })
    #Add Exit   
    $hashSpeakerRight.Closed_Event = {
      param($sender)
      try{
        Write-ezlogs ">>>> SpeakerRight window has closed"
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SpeakerRight_ToggleButton' -Property 'isChecked' -value $false
      }catch{
        write-ezlogs "An exception occurred in hashSpeakerRight.Closed_Event" -showtime -catcherror $_
      }
    }
    $hashSpeakerRight.Window.Add_Closed($hashSpeakerRight.Closed_Event)
    #region Unloaded Event
    [System.Windows.RoutedEventHandler]$hashSpeakerRight.Unloaded_Event = {
      param($sender,[System.Windows.RoutedEventArgs]$e)
      try{
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent) -RemoveHandlers -VerboseLog
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers -VerboseLog
        $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers -VerboseLog
        $Null = $sender.Remove_Closed($hashSpeakerRight.Closed_Event)
        $hashkeys = [System.Collections.ArrayList]::new($hashSpeakerRight.keys)
        $hashkeys | & { process {
            if($hashSpeakerRight.Window.FindName($_)){
              if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Unregistering hashSpeakerRight UI name: $_" -Dev_mode}
              $null = $hashSpeakerRight.Window.UnRegisterName($_)
              $hashSpeakerRight.$_ = $Null
            }        
        }}
        $hashSpeakerRight.Window = $Null
        $hashSpeakerRight = $null
        $hashkeys = $Null
        write-ezlogs ">>>> Exiting application context thread for SpeakerRight.Window" -showtime
        [System.Windows.Threading.Dispatcher]::ExitAllFrames()
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
        write-ezlogs ">>>> SpeakerRight.Window has unloaded" -loglevel 2 -GetMemoryUsage -forceCollection                      
      }catch{
        write-ezlogs "An exception occurred in SpeakerRight.Window.add_Unloaded" -showtime -catcherror $_
      }
    }
    $Null = $hashSpeakerRight.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$hashSpeakerRight.Unloaded_Event)
    #endregion Unloaded Event

    try{       
      if(!$start_hidden){
        $null = $hashSpeakerRight.window.Show()
        $null = $hashSpeakerRight.Window.Activate() 
      }          
    }catch{
      write-ezlogs "An exception occurred when opening Show-RightSpeaker window" -showtime -catcherror $_ 
    }  
    try{
      [System.Windows.Threading.Dispatcher]::Run() 
    }catch{
      write-ezlogs "An exception occurred when opening main Show-RightSpeaker window" -showtime -catcherror $_ 
    } 
  }
  try{ 
    $null = Start-Runspace $SpeakerRight_Pwshell -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -runspace_name "Show_RightSpeaker_Runspace"  -verboselog:$verboselog        
  }catch{
    write-ezlogs "An exception occurred when creating runspace for Show-RightSpeaker window" -showtime -catcherror $_        
  }   
}
#---------------------------------------------- 
#endregion Show-RightSpeaker Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-LeftSpeaker','Show-RightSpeaker','Update-Speakers')