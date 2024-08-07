<#
    .Name
    Get-WPFAnimation

    .Version 
    0.1.0

    .SYNOPSIS
    Controls various WPF Animations such as storyboards  

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
#region Get-WPFAnimation Function
#----------------------------------------------
function Get-WPFAnimation
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [ValidateSet('Begin','Pause','Stop','Resume')]
    [string]$Action,
    [switch]$SpectrumAnalyzer,
    [switch]$PlayIcons,
    [switch]$Verboselog
  )
  try{ 
    
    #[System.Windows.Media.RenderCapability]::Tier -shr 16
    #[System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty.OverrideMetadata([System.Windows.Media.MediaTimeline],[System.Windows.FrameworkPropertyMetadata]::new(30))
    #[System.Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace
    #$synchash.PlayIcon1_Storyboard.Storyboard.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty,$null)
    switch ($Action) {
      'Begin' {
        if($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){
          write-ezlogs "Performance mode is enabled, skipping animations for playicon" -warning
        }else{
          $synchash.PlayIcon1_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
          $synchash.PlayIcon1_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,30)
          $synchash.PlayIcon1_Storyboard.Storyboard.Begin($synchash.PlayIcon,[System.Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace,$true)
          #$synchash.PlayIcon1_Storyboard.Storyboard.Begin()
          $synchash.PlayIcon2_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
          $synchash.PlayIcon2_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,30)
          $synchash.PlayIcon2_Storyboard.Storyboard.Begin($synchash.PlayIcon2,[System.Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace,$true)
        }
        if($synchash.MiniDisplayPanel_Storyboard -and $synchash.MiniSlideText_StackPanel.ActualWidth -gt 300){
          $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
          if(!$target){
            $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
          }
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.AutoReverse = $false
          if($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){
            $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,5)
          }else{
            $synchash.MiniDisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,$null)
          }
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.Begin()
          #$synchash.MiniDisplayPanel_Slide_Storyboard.To = $($synchash.MiniSlideText_StackPanel.ActualWidth - 20)
        }else{
          #$synchash.MiniSlideText_StackPanel2.Visibility = 'Hidden'
        }
      }
      'Pause' {
        $synchash.PlayIcon1_Storyboard.Storyboard.Pause($synchash.PlayIcon)
        $synchash.PlayIcon2_Storyboard.Storyboard.Pause($synchash.PlayIcon2)
        #$synchash.PlayIcon2_Storyboard.Storyboard.Pause()
        if($synchash.DisplayPanel_Storyboard -and $synchash.SlideText_StackPanel.ActualWidth -gt 500){
          $synchash.DisplayPanel_Storyboard.Storyboard.Pause($synchash.DisplayPanel_Text_StackPanel)
        }
        if($synchash.miniDisplayPanel_Storyboard -and $synchash.miniSlideText_StackPanel.ActualWidth -gt 300){
          $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
          if(!$target){
            $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
          }
          $synchash.miniDisplayPanel_Storyboard.Storyboard.Pause()
        }
      }
      'Stop' {
        $synchash.PlayIcon1_Storyboard.Storyboard.Stop($synchash.PlayIcon)
        $synchash.PlayIcon2_Storyboard.Storyboard.Stop($synchash.PlayIcon2)
        if($synchash.DisplayPanel_Storyboard){
          $synchash.DisplayPanel_Slide_Animation.From = 0
          $synchash.DisplayPanel_Slide_Animation.To = 0
          #$synchash.transferCurreny2.x = '0'
          $synchash.SlideText_StackPanel2.Visibility = 'Hidden'
          $synchash.DisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::new(0)      
          $synchash.DisplayPanel_Storyboard.Storyboard.Stop($synchash.DisplayPanel_Text_StackPanel)
        }
        if($synchash.MiniDisplayPanel_Storyboard){
          $target = [System.Windows.Media.Animation.Storyboard]::GetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard)
          if(!$target){
            $null = [System.Windows.Media.Animation.Storyboard]::SetTarget($synchash.MiniDisplayPanel_Storyboard.Storyboard,$synchash.MiniDisplayPanel_Text_StackPanel)
          }
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.RepeatBehavior = '0.1x'
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.Stop()
        }
        if($synchash.AudioSpectrum.DataContext.IsCapturing){
          $synchash.AudioSpectrum.DataContext.StopCapture()
        }
      }      
      'Resume' {
        if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
          $synchash.PlayIcon1_Storyboard.Storyboard.Resume($synchash.PlayIcon)
          $synchash.PlayIcon2_Storyboard.Storyboard.Resume($synchash.PlayIcon2)
        }
        if($synchash.DisplayPanel_Storyboard -and $synchash.SlideText_StackPanel.ActualWidth -gt 500){
          $synchash.DisplayPanel_Storyboard.Storyboard.Resume($synchash.DisplayPanel_Text_StackPanel)
        }
        if($synchash.MiniDisplayPanel_Storyboard -and $synchash.MiniSlideText_StackPanel.ActualWidth -gt 300){
          $synchash.MiniDisplayPanel_Storyboard.Storyboard.Resume()
        }
      }
    } 
  }catch{
    write-ezlogs 'An exception occurred in Start-WPFAnimation' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-WPFAnimation Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-SpectrumAnalyzer
#----------------------------------------------
function Get-SpectrumAnalyzer
{
  Param (
    $thisApp,
    $synchash,
    [ValidateSet('Begin','Pause','Stop','Resume','Disable')]
    [string]$Action,
    [switch]$Startup,
    [switch]$Reflection,
    [switch]$Verboselog
  )
  try{ 
    if(!$synchash.SpectrumAnalyzer_Timer -and $Startup){
      if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Creating new SpectrumAnalyzer_Timer" -showtime -Dev_mode}
      $synchash.SpectrumAnalyzer_Timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
      $synchash.SpectrumAnalyzer_Timer.add_tick({
          try{  
            $synchash = $synchash
            $thisApp = $thisApp         
            if(-not [string]::IsNullOrEmpty($this.tag.Action)){
              switch ($this.tag.Action) {
                'Begin' {
                  if($synchash.AudioSpectrum.DataContext.IsCapturing){
                    write-ezlogs ">>>> Disabling Existing Spectrum Analyzer" -showtime -color cyan
                    if($synchash.AudioSpectrum.DataContext.soundIn -is [System.IDisposable]){
                      write-ezlogs "| Stopping SoundIn recording" -showtime -color cyan
                      $synchash.AudioSpectrum.DataContext.soundIn.Stop()
                    }
                    $synchash.AudioSpectrum.DataContext.StopCapture()   
                    $synchash.AudioSpectrum.DataContext = $Null                  
                  }else{
                    write-ezlogs " | Spectrum Analyzer is not capturing" -showtime
                  } 
                  if($synchash.AudioSpectrum2.DataContext.IsCapturing){
                    write-ezlogs ">>>> Disabling Spectrum Reflection" -showtime -color cyan
                    $synchash.AudioSpectrum2.DataContext.StopCapture()
                  }else{
                    write-ezlogs " | Spectrum Analyzer Reflection is not capturing" -showtime
                  }
                  if($synchash.DisplaySpectrum.children -contains $synchash.AudioSpectrum){
                    $synchash.DisplaySpectrum.children.Remove($synchash.AudioSpectrum)
                  }    
                  if($synchash.DisplayReflection.children -contains $synchash.AudioSpectrum2){
                    $synchash.DisplayReflection.children.Remove($synchash.AudioSpectrum2)
                  }
                  $synchash.AudioSpectrum = $Null 
                  write-ezlogs ">>>> Enabling Spectrum Analyzer" -showtime -color cyan
                  $synchash.AudioSpectrum = [SpectrumAnalyzer.Controls.AudioSpectrum]::new()
                  if($synchash.AudioSpectrum.DataContext.IsCapturing){
                    $synchash.AudioSpectrum.DataContext.StopCapture()
                  }
                  $synchash.AudioSpectrum.PitchColor = $false
                  $synchash.AudioSpectrum.Name = 'AudioSpectrum'
                  $synchash.AudioSpectrum.Height = '55'
                  $imagebrush = [System.Windows.Media.ImageBrush]::new()
                  $ImageBrush.ImageSource = "$($thisApp.Config.Current_Folder)\Resources\Skins\SpectrumLineBack.png"
                  $imagebrush.TileMode = 'Tile'
                  $imagebrush.ViewportUnits = "Absolute"
                  $imagebrush.Viewport = "0,0,7,100"
                  $synchash.AudioSpectrum.ForegroundImage = $imagebrush
                  if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                    $synchash.AudioSpectrum.Foreground = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
                  }else{
                    $synchash.AudioSpectrum.Foreground = $synchash.Window.TryFindResource('MahApps.Brushes.Accent')
                  }     
                  $synchash.AudioSpectrum.SpeedRaising = '100'
                  $synchash.AudioSpectrum.SpeedDropping = '20'
                  $synchash.AudioSpectrum.RoundedLineCorners = $false
                  $synchash.AudioSpectrum.LineVerticalAlignment = 'Bottom'
                  #$synchash.AudioSpectrum.RenderTransformOrigin="0.5, 0.5"
                  $synchash.AudioSpectrum.datacontext = $Null
                  $synchash.AudioSpectrum.OrientationAngle = '0'
                  if(-not [string]::IsNullOrEmpty($thisApp.Config.AudioMonitor_RefreshRate) -and $thisApp.Config.AudioMonitor_RefreshRate -is [int] -and $thisApp.Config.AudioMonitor_RefreshRate -gt 0){
                    $RefreshRate = $thisApp.Config.AudioMonitor_RefreshRate
                  }else{
                    $RefreshRate = 40
                  }
                  $AnalyzerViewview = [SpectrumAnalyzer.Models.AnalyzerViewModel]::new(30,$RefreshRate,255,0,18000)
                  $AnalyzerViewview.ScalingStrategy = 'Decibel'
                  #$AnalyzerViewview.BeatSensibility = '50'
                  #FrequencyObservers for Speaker UI animations (bass only)
                  $AnalyzerViewview.DetectBeats = $true
                  $AnalyzerViewview.FrequencyObservers.RemoveAt(0)
                  $AnalyzerViewview.FrequencyObservers.RemoveAt(0)
                  $AnalyzerViewview.FrequencyObservers.RemoveAt(0)     
                  $AnalyzerViewview.FrequencyObservers | & { process {$_.MinFrequency = 20;$_.MaxFrequency=80}}
                  $synchash.AudioSpectrum.ForegroundPitched = [System.Windows.Media.SolidColorBrush]::new('DarkBlue')
                  $synchash.AudioSpectrum.datacontext = $AnalyzerViewview
                  if($synchash.DisplaySpectrum.children -notcontains $synchash.AudioSpectrum){
                    $synchash.DisplaySpectrum.children.add($synchash.AudioSpectrum)
                  }
                  if($hashSpeakerLeft.Window.isVisible){  
                    $hashSpeakerLeft.FrequencyObservers = $AnalyzerViewview.FrequencyObservers
                    Update-Speakers -Speaker 'Left' -EnableBeats -synchash $synchash
                  }
                  if($hashSpeakerRight.Window.isVisible){  
                    $hashSpeakerRight.FrequencyObservers = $AnalyzerViewview.FrequencyObservers
                    Update-Speakers -Speaker 'Right' -EnableBeats -synchash $synchash
                  }
                  if($this.tag.Reflection){
                    write-ezlogs ">>>> Enabling Spectrum Reflection" -showtime -color cyan
                    $synchash.AudioSpectrum2 = [SpectrumAnalyzer.Controls.AudioSpectrum]::new()
                    $synchash.AudioSpectrum2.PitchColor = $true
                    $synchash.AudioSpectrum2.Name = 'AudioSpectrum2'
                    $synchash.AudioSpectrum2.Foreground =[System.Windows.Media.SolidColorBrush]::new('#FF7FE3FE')
                    $synchash.AudioSpectrum2.ForegroundPitched = [System.Windows.Media.SolidColorBrush]::new('DarkBlue')
                    $synchash.AudioSpectrum2.SpeedRaising = '100'
                    $synchash.AudioSpectrum2.SpeedDropping = '20'  
                    $synchash.AudioSpectrum2.RoundedLineCorners = $false  
                    $synchash.AudioSpectrum2.datacontext = $AnalyzerViewview
                    $synchash.AudioSpectrum2.LineVerticalAlignment = 'Bottom'
                    $synchash.AudioSpectrum2.OrientationAngle = '0'
                    #$synchash.AudioSpectrum2.Opacity = $synchash.Window.TryFindResource('ShadowOpacity')
                    if($synchash.DisplayReflection.children -notcontains $synchash.AudioSpectrum2){
                      $synchash.DisplayReflection.children.add($synchash.AudioSpectrum2)
                    }   
                  }
                }
                'Pause' {

                }
                'Stop' {
                  if($synchash.AudioSpectrum.DataContext.IsCapturing){
                    write-ezlogs ">>>> Disabling Spectrum Analyzer" -showtime
                    if($synchash.AudioSpectrum.DataContext.soundIn -is [System.IDisposable]){
                      write-ezlogs "| Stopping SoundIn recording" -showtime
                      $synchash.AudioSpectrum.DataContext.soundIn.Stop()
                    }
                    $synchash.AudioSpectrum.DataContext.StopCapture()       
                  }else{
                    write-ezlogs ">>>> Can't Stop Spectrum Analyzer since it is not capturing" -showtime -warning
                  }
                  if($synchash.DisplaySpectrum.children -contains $synchash.AudioSpectrum){
                    write-ezlogs "| Removing AudioSpectrum from DisplaySpectrum" -showtime
                    $synchash.DisplaySpectrum.children.Remove($synchash.AudioSpectrum)
                  }    
                  if($synchash.DisplayReflection.children -contains $synchash.AudioSpectrum2){
                    write-ezlogs "| Removing AudioSpectrum2 from DisplayReflection" -showtime
                    $synchash.DisplayReflection.children.Remove($synchash.AudioSpectrum2)
                  }  
                  if($synchash.AudioSpectrum2.DataContext.IsCapturing){
                    write-ezlogs "| Disabling Spectrum Reflection" -showtime
                    $synchash.AudioSpectrum2.DataContext.StopCapture()
                    $synchash.AudioSpectrum2.DataContext = $Null
                  }else{
                    write-ezlogs "Can't Stop Spectrum Analyzer Reflection since it is not capturing" -showtime -warning
                  }
                  if(!$thisApp.Config.Enable_AudioMonitor){
                    $synchash.MonitorButton_ToggleButton.isChecked = $false
                  }
                  if($hashSpeakerLeft.Window.isVisible){  
                    Update-Speakers -Speaker 'Left' -DisableBeats -synchash $synchash
                  }
                  if($hashSpeakerRight.Window.isVisible){  
                    Update-Speakers -Speaker 'Right' -DisableBeats -synchash $synchash
                  }
                  $synchash.AudioSpectrum.datacontext = $Null
                  $synchash.AudioSpectrum = $Null
                }                         
                'Resume' {

                }
              }          
            }                                           
            $this.Stop()
          }catch{
            write-ezlogs "An exception occurred in SpectrumAnalyzer_Timer.add_tick" -showtime -catcherror $_
          }finally{
            $this.tag = $Null
            $this.Stop()
          }
      })                                                                   
    }elseif($synchash.SpectrumAnalyzer_Timer){
      $synchash.SpectrumAnalyzer_Timer.Tag = [PSCustomObject]::new(@{
          'Action' = $Action
          'Reflection' = $Reflection
      })
      if(!$synchash.SpectrumAnalyzer_Timer.IsEnabled){  
        write-ezlogs ">>>> Starting SpectrumAnalyzer_Timer" -loglevel 2
        $synchash.SpectrumAnalyzer_Timer.start() 
      }else{
        write-ezlogs "SpectrumAnalyzer_Timer is already started and running" -loglevel 2 -warning
      }   
    }                   
  }catch{
    write-ezlogs 'An exception occurred in Start-WPFAnimation' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-SpectrumAnalyzer Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-WPFAnimation','Get-SpectrumAnalyzer')