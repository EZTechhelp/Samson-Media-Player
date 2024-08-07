<#
    .Name
    Set-WPFSkin

    .Version 
    0.1.0

    .SYNOPSIS
    Sets images, themes and other properties related to WPF UI

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
#region Set-WPFSkin Function
#----------------------------------------------
function Set-WPFSkin
{
  <#
      .Name
      Set-WPFSkin

      .Version 
      0.1.0

      .SYNOPSIS
      Sets events and properties for WPF Buttons  

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
  Param (
    $thisApp,
    $synchash,
    [switch]$DPlayer,
    [switch]$Verboselog
  )
  try{
    #Load special/custom Samson Theme
    if($DPlayer){  
      try{
        #TODO: Testing - Special Events Themes
        $Today = [DateTime]::Now
        $Month = $Today.Month
        $Day = $Today.day
        $isSpecialHDay = $($Month -eq '10' -and $Day -eq '31')
        $Skin = "$($thisApp.Config.Current_Folder)\Resources\Skins\Samson.png"
        if($isSpecialHDay){
          $Web1Image = "$($thisApp.Config.Current_Folder)\Resources\Skins\Web1.png"
        }
        if($isSpecialHDay -and [system.io.file]::Exists($Web1Image)){
          $stream_image = [System.IO.File]::OpenRead($Web1Image) 
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.DecodePixelWidth = "252"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $null
          $image.Freeze()
          $imagecontrol = [System.Windows.Controls.Image]::new()
          $imagecontrol.Source = $image
          $image = $Null
          $imagecontrol.Width = "252"
          $imagecontrol.Height = "222"
          $imagecontrol.Margin="0,0,0,0"
          $imagecontrol.HorizontalAlignment="Left"
          $imagecontrol.SetValue([System.Windows.Controls.Grid]::RowProperty,0)
          $imagecontrol.SetValue([System.Windows.Controls.Grid]::ColumnProperty,0)
          $imagecontrol.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty,2)
          $imagecontrol.SetValue([System.Windows.Controls.Grid]::ZIndexProperty,2)
          $imagecontrol.IsHitTestVisible = $false
          $imagecontrol.CacheMode = "BitmapCache"
          $imagecontrol.RenderTransformOrigin="0.5, 0.5"
          $Null = $synchash.MainGrid.addChild($imagecontrol) 
        }
        if([system.io.file]::Exists($Skin)){
          $stream_image = [System.IO.File]::OpenRead($Skin)
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.DecodePixelWidth = "1630"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $null
          $image.Freeze()
          $syncHash.MainGrid_Background_Image_Source.Source = $image
          $image = $Null
        }
        if($syncHash.MainGrid_Background_Image_Source2 -and [system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Feet.png")){
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Feet.png") 
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.DecodePixelWidth = "1546"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $null
          $image.Freeze()
          $syncHash.MainGrid_Background_Image_Source2.Source = $image
          $syncHash.MainGrid_Background_Image_Source2.Width="1630"
          $syncHash.MainGrid_Background_Image_Source2.Height="58"
          $image = $Null
        }
        if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Skins\Screen.png")){
          $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Screen.png") 
          $image = [System.Windows.Media.Imaging.BitmapImage]::new()
          $image.BeginInit()
          $image.CacheOption = "OnLoad"
          $image.DecodePixelWidth = "634"
          $image.StreamSource = $stream_image
          $image.EndInit()
          $stream_image.Close()
          $stream_image.Dispose()
          $stream_image = $null
          $image.Freeze()
          $synchash.DisplayScreen.Source = $image
          $image = $Null
        }
        #Load CassetteWheel and set PlayIcon  
        $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\CassetteWheelRight.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        $image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "44"
        $image.StreamSource = $stream_image
        $image.EndInit()
        $stream_image.Close()
        $stream_image.Dispose()
        $stream_image = $null
        #$image.Freeze() #Dont freeze due to animation?
        $synchash.PlayIcon.Source = $image
        $image = $Null
      }catch{
        write-ezlogs "An exception occurred setting main background" -showtime -catcherror $_
      }
    }else{
      try{
        if($syncHash.MainGrid_Background_Image_Source){
          $syncHash.MainGrid_Background_Image_Source.Stretch = "UniformToFill"
          $syncHash.MainGrid_Background_Image_Source.Opacity = '0.10'
          if($syncHash.MainGrid_Background_Image_Source.Effect){
            $syncHash.MainGrid_Background_Image_Source.Effect.Radius = "10"
          }          
        }
        $synchash.Window.Height = "600"
        $synchash.Window.Width = "1100"
        $synchash.Window.MinHeight = "320"
        $synchash.Window.MinWidth = "900"
        $PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen 
        $synchash.Window.MaxHeight = $PrimaryScreen.WorkingArea.Height
        $synchash.Window.MaxWidth = $PrimaryScreen.WorkingArea.Width
        #$syncHash.MainGrid_Background_Image_Source_transition.content = $syncHash.MainGrid_Background_Image_Source 
      }catch{
        write-ezlogs "An exception occurred setting main background" -showtime -catcherror $_
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Set-WPFButtons" -CatchError $_ -showtime
  }
}
#---------------------------------------------- 
#endregion Set-WPFSkin Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-WPFTheme Function
#----------------------------------------------
function Set-WPFTheme
{
  <#
      .Name
      Set-WPFTheme

      .Version 
      0.1.0

      .SYNOPSIS
      Sets color theme for WPF UI and controls  

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
  Param (
    $thisApp,
    $synchash,
    [switch]$DPlayer,
    [switch]$Verboselog
  )
  try{        
    $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
    $themes = $theme.GetLibraryThemes()
    [System.Windows.RoutedEventHandler]$MenuItem_ClickEvent = {
      try{
        $menutheme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
        $menuthemes = $menutheme.GetLibraryThemes()
        $themeManager = [ControlzEx.Theming.ThemeManager]::new()
        $detectTheme = $thememanager.DetectTheme($synchash.Window)
        $menuColorTable = $($this.uid -split ',')
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Current Theme: $($detectTheme.name)" -showtime -Dev_mode}
        $newtheme = $menuthemes.where({$_.Name -eq "$($menuColorTable[0]).$($menuColorTable[1])"})
        if($newtheme){
          write-ezlogs ">>>> Setting new theme: $($newtheme)" -showtime -LogLevel 2
          $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
          $thememanager.ChangeTheme($synchash.Window,$newtheme.Name,$false)              
          if($synchash.PlayQueue_Flyout_Grid){
            write-ezlogs " | Changing theme for PlayQueue_Flyout_Grid" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.PlayQueue_Flyout_Grid,$newtheme.Name,$false)
          }
          if($synchash.AudioOptions_Viewer){
            write-ezlogs " | Setting theme for AudioOptions_Viewer" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.AudioOptions_Viewer,$newtheme.Name,$false)
          }
          if($synchash.Audio_Flyout_Control){
            write-ezlogs " | Setting theme for Audio_Flyout_Control" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.Audio_Flyout_Control,$newtheme.Name,$false)
            if($synchash.Enable_EQ_Toggle.isChecked){
              if($newTheme.PrimaryAccentColor){
                $synchash.Audio_Flyout.Tag = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
              }else{
                $synchash.Audio_Flyout.Tag = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
              } 
            }else{
              $synchash.Audio_Flyout.Tag = "#FF535455"
            }                                     
          }    
          if($synchash.MainGrid_Top_TabControl){
            write-ezlogs " | Setting theme for MainGrid_Top_TabControl" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.MainGrid_Top_TabControl,$newtheme.Name,$false)
          } 
          if($synchash.DockingManager){
            write-ezlogs " | Setting theme for DockingManager" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.DockingManager,$newtheme.Name,$false)
          }
          if($synchash.MediaTable){
            $synchash.MediaTable.RowSelectionBrush = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
          } 
          if($synchash.Spotifytable){
            $synchash.Spotifytable.RowSelectionBrush = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
          }
          if($synchash.Youtubetable){
            $synchash.Youtubetable.RowSelectionBrush = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
          }
          if($synchash.Twitchtable){
            $synchash.Twitchtable.RowSelectionBrush = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
          }                                                                                   
          if($synchash.MainGrid_Bottom_TabControl){
            write-ezlogs " | Setting theme for MainGrid_Bottom_TabControl" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.MainGrid_Bottom_TabControl,$newtheme.Name,$false)
          } 
          if($synchash.Playlist_TabControl){
            write-ezlogs " | Setting theme for Playlist_TabControl" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.Playlist_TabControl,$newtheme.Name,$false) 
          } 
          if($synchash.TrayPlayer_TreeView){
            $synchash.TrayPlayer_TreeView.SelectionBackgroundColor = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
            $synchash.TrayPlayer_TreeView.LineStroke = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')   
          } 
          if($synchash.LocalMedia_TreeView){
            $synchash.LocalMedia_TreeView.SelectionBackgroundColor = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
            $synchash.LocalMedia_TreeView.LineStroke = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')   
          } 
          if($synchash.Playlists_TreeView){
            $synchash.Playlists_TreeView.SelectionBackgroundColor = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
            $synchash.Playlists_TreeView.LineStroke = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase') 
          }                                            
          if($synchash.PlayQueue_TreeView){
            write-ezlogs " | Setting theme for PlayQueue_TreeView" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.PlayQueue_TreeView,$newtheme.Name,$false) 
          }       
          if($synchash.EQ_Slider_StackPanel){
            write-ezlogs " | Setting theme for EQ_Slider_StackPanel" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.EQ_Slider_StackPanel,$newtheme.Name,$false)                   
          }
          if($synchash.EQ_Preset_Grid){
            write-ezlogs " | Setting theme for EQ_Preset_Grid" -showtime -Dev_mode
            $thememanager.ChangeTheme($synchash.EQ_Preset_Grid,$newtheme.Name,$false)                   
          }                                                                                                                                                            
          if($synchash.BrewWindow.isVisible){
            $titlebar =  $synchash.Window.TryFindResource('MahApps.Brushes.Accent') 
            if($titlebar){
              $synchash.BrewWindow.TitleBarBackground = $titlebar
            } 
            $thememanager.ChangeTheme($synchash.BrewWindow,$newtheme.Name,$false) 
          }
          if($hashsetup.Window.IsInitialized){
            Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Set_ThemeName $newtheme.Name
          }
          $newRow = [ColorTheme]@{
            'Name' = "$($menuColorTable[0]).$($menuColorTable[1])"
            'Menu_item' = "Theme_$($menuColorTable[1])"
            #'GridGradientColor1' = '#FF000000'
            #'GridGradientColor2' = $($menuColorTable[2])
            'PrimaryAccentColor' = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString()).Color
          }
          $thisApp.Config.Current_Theme = $newRow
          if($synchash.AudioSpectrum.DataContext.IsCapturing){
            try{          
              Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchash -Action Begin
            }catch{
              write-ezlogs "An exception occurred in Get-SpectrumAnalyzer" -CatchError $_ -showtime
            } 
          }
          if($synchash.DisplayPanel_Title_TextBlock){
            $synchash.DisplayPanel_Title_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
          }
          if($synchash.DisplayPanel_Status_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_Title_TextBlock.Text)){
            $synchash.DisplayPanel_Status_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
            $synchash.DisplayPanel_Status_Border.BorderBrush = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
          }elseif($synchash.DisplayPanel_STOP_TextBlock){
            $synchash.DisplayPanel_STOP_Border.BorderBrush = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
            $synchash.DisplayPanel_STOP_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newTheme.PrimaryAccentColor.ToString())
          }        
          $synchash.Change_Theme.items | & { process { 
              if($_.Uid -eq $this.uid){
                $_.isChecked = $true
              }else{
                $_.isChecked = $false
              }                
          }}  
          try{
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
            #Export-Clixml -InputObject $thisapp.config -Path $thisapp.config.Config_Path -Force -Encoding UTF8
          }catch{
            write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
          } 
        }else{
          write-ezlogs "Couldnt find new theme - $($_  | out-string) - $($this | out-string)" -showtime -warning
        }
      }catch{
        write-ezlogs "An exception occurred in $($menuitem.Name) click event" -CatchError $_ -showtime
      }finally{
        if($menuthemes -is [System.IDisposable]){
          $null = $menuthemes.Dispose()
        }
      }  
    }
    foreach($theme in $themes){
      if($theme.BaseColorScheme -eq 'Dark' -and $synchash.Change_Theme.items.Name -notcontains "Theme_$($theme.ColorScheme)"){
        $menuitem = [System.Windows.Controls.MenuItem]::new()
        $menuitem.Name = "Theme_$($theme.ColorScheme)"
        $menuitem.Foreground = "$($theme.PrimaryAccentColor)"
        $menuitem.IsCheckable = $true
        $menuitem.Header = "$($theme.DisplayName)"
        $menuitem.Uid = "$($theme.BaseColorScheme),$($theme.ColorScheme)"
        $menuitem.Add_Click($MenuItem_ClickEvent)
        if($menuitem.Name -eq $thisApp.Config.Current_Theme.Menu_item){
          $menuitem.IsChecked = $true
        }else{
          $menuitem.IsChecked = $false
        }
        $null = $synchash.Change_Theme.items.add($menuitem)
      }
    }
    if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
      try{       
        $themeManager = [ControlzEx.Theming.ThemeManager]::new()
        $newtheme = $themes.where({$_.Name -eq $thisApp.Config.Current_Theme.Name})
        if($newtheme){
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Current Theme: $($newtheme.Name)" -showtime -Dev_mode}          
          $Null = $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
          $Null = $thememanager.ChangeTheme($synchash.Window,$newtheme.Name,$false)              
          if($synchash.DisplayPanel_Title_TextBlock){
            $synchash.DisplayPanel_Title_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newtheme.PrimaryAccentColor.ToString())
          }
          if($synchash.DisplayPanel_Status_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_Title_TextBlock.Text)){
            $synchash.DisplayPanel_Status_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newtheme.PrimaryAccentColor.ToString())
            $synchash.DisplayPanel_Status_Border.BorderBrush = [System.Windows.Media.SolidColorBrush]::new($newtheme.PrimaryAccentColor.ToString())
          }elseif($synchash.DisplayPanel_STOP_TextBlock){
            $synchash.DisplayPanel_STOP_Border.BorderBrush = [System.Windows.Media.SolidColorBrush]::new($newtheme.PrimaryAccentColor.ToString())
            $synchash.DisplayPanel_STOP_TextBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new($newtheme.PrimaryAccentColor.ToString())
          }                                      
        }
        $themeManager.ClearThemes()
        $thememanager = $Null
      }catch{
        write-ezlogs "An exception occurred applying theme $($thisApp.Config.Current_Theme | out-string)" -catcherror $_
      }    
    }
    if($themes -is [System.IDisposable]){
      $null = $themes.Dispose()
      $themes = $Null
    }  
  }catch{
    write-ezlogs "An exception occurred in Set-WPFTheme" -CatchError $_ -showtime
  }
}
#---------------------------------------------- 
#endregion Set-WPFTheme Function
#----------------------------------------------
Export-ModuleMember -Function @('Set-WPFSkin','Set-WPFTheme')