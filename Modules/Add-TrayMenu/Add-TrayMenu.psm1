<#
    .Name
    Add-TrayMenu

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and updates system tray context menus

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Add-TrayMenu Function
#----------------------------------------------
function Add-TrayMenu
{
  Param (
    $thisApp,
    $synchash,
    $all_playlists,
    [switch]$Update_Playlists,
    [switch]$Startup,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog
  )

  #Tray Icon
  #$image =  [System.Drawing.Image]::FromStream($stream_image)
  #$icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap][System.Drawing.Image]::FromStream([System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"))).GetHicon())
  if($Synchash.Main_Tool_Icon){
    $Synchash.Main_Tool_Icon.dispose()
  }
  $Synchash.Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
  #$Binding = New-Object System.Windows.Data.Binding
  #$Binding.Source = $synchash.Now_Playing_Label
  #$Binding.Path = [System.Windows.Controls.Label]::ContentProperty
  #$Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  #[void][System.Windows.Data.BindingOperations]::SetBinding($Synchash.Main_Tool_Icon,'Text', $Binding)  

 
  $Synchash.Main_Tool_Icon.Text = "$($thisApp.Config.App_Name) - Version $($thisApp.Config.App_Version)"
  #$Synchash.Main_Tool_Icon.Text = $Binding
  [uri]$icon = "$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"
  $Synchash.Main_Tool_Icon.Icon =  "$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"
  #$synchash.myNotifyIcon.IconSource = $Synchash.Title_menu_title.Source
  $Synchash.Main_Tool_Icon.Visible = $true


<#  [System.Windows.RoutedEventHandler]$OpenApp_Command  = {
    param($sender)
    try{    
      $synchash.Window.Show()
      if($SyncHash.Window.WindowState -eq 'Minimized'){
        $SyncHash.Window.WindowState = 'Normal'
      }
      write-ezlogs "Main window size is currently $($synchash.window.height) x $($synchash.window.width)" -showtime     
      $window_active = $synchash.Window.Activate()    
      $null = [System.GC]::GetTotalMemory($true) 
    }catch{
      write-ezlogs "An exception occurred in EditProfile_Command routed event" -showtime -catcherror $_
    }
  }
  $items = New-Object System.Collections.ArrayList
  $Open_App = @{
    'Header' = "Open App"
    'Color' = 'White'
    'Icon_Color' = 'Blue'
    'IconPack' = 'PackIconBootstrapIcons'
    'Command' = $OpenApp_Command
    'Icon_kind' = 'MusicPlayerFill'
    'Enabled' = $true
    'IsCheckable' = $false
  }
  $null = $items.Add($Open_App)
  $separator = @{
    'Separator' = $true
    'Style' = 'SeparatorGradient'
  }            
  $null = $items.Add($separator) 


  $Synchash.Main_Tool_Icon = [Hardcodet.Wpf.TaskbarNotification.TaskbarIcon]::new()
  $Synchash.Main_Tool_Icon.Name = "Main_Tool_Icon"
  $Synchash.Main_Tool_Icon.Visibility="Visible"#>
  #$Synchash.Main_Tool_Icon.Icon =  "$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"


  #Add-WPFMenu -control $synchash.myNotifyIcon -items $items -AddContextMenu -synchash $synchash
  #$newcontextMenu = New-Object System.Windows.Controls.ContextMenu
  #$menuItem = new-object System.Windows.Controls.MenuItem -property @{Header = 'Test'}
  #$null = $newcontextMenu.items.add($menuItem)
  #$menuItem2 = new-object System.Windows.Controls.MenuItem -property @{Header = 'Test2'}
  #$null = $newcontextMenu.items.add($menuItem2)
  #$synchash.myNotifyIcon.Contextmenu = $newcontextMenu
  #$newcontextMenu.Style = $synchash.Window.TryFindResource("DropDownMenuStyle")


  #ContextMenu
  $contextmenu = New-Object System.Windows.Forms.ContextMenuStrip
  $contextmenu.DropShadowEnabled = $true
  $contextmenu.ShowItemToolTips = $true
  $contextmenu.BackColor = '#333333'
  $contextmenu.ForeColor = 'WhiteSmoke'
  $contextmenu.ShowCheckMargin = $false
  $contextmenu.ShowImageMargin = $true
  $contextmenu.AllowTransparency = $true
  #$contextmenu.Opacity = 0.8

  #Need to use Drawing Primitives for PS 7/core support to get to ProfessionalColorTable
  if($psversiontable.psversion.Major -gt 5){
    Add-Type -AssemblyName System.Drawing.Primitives
    $namespace = 'System.Drawing.Primitives'
    $PSDefaultParameterValues['*:Encoding'] = 'unicode'
  }else{
    $namespace = 'System.Drawing'
  }

  Add-Type -ReferencedAssemblies 'System.Windows.Forms', $namespace -TypeDefinition "
    using System;
    using System.Windows.Forms;
    using System.Drawing;
    namespace SAPIENTypes
    {
    public class SAPIENColorTable : ProfessionalColorTable
    {
    Color ContainerBackColor;
    Color BackColor;
    Color BorderColor;
    Color SelectBackColor;
    public SAPIENColorTable(Color containerColor, Color backColor, Color borderColor, Color selectBackColor)
    {
    ContainerBackColor = containerColor;
    BackColor = backColor;
    BorderColor = borderColor;
    SelectBackColor = selectBackColor;
    } 
    public override Color MenuStripGradientBegin { get { return ContainerBackColor; } }
    public override Color MenuStripGradientEnd { get { return ContainerBackColor; } }
    public override Color ToolStripBorder { get { return BorderColor; } }
    public override Color MenuItemBorder { get { return SelectBackColor; } }
    public override Color MenuItemSelected { get { return SelectBackColor; } }
    public override Color SeparatorDark { get { return BorderColor; } }
    public override Color ToolStripDropDownBackground { get { return BackColor; } }
    public override Color MenuBorder { get { return BorderColor; } }
    public override Color MenuItemSelectedGradientBegin { get { return SelectBackColor; } }
    public override Color MenuItemSelectedGradientEnd { get { return SelectBackColor; } }      
    public override Color MenuItemPressedGradientBegin { get { return ContainerBackColor; } }
    public override Color MenuItemPressedGradientEnd { get { return ContainerBackColor; } }
    public override Color MenuItemPressedGradientMiddle { get { return ContainerBackColor; } }
    public override Color ImageMarginGradientBegin { get { return BackColor; } }
    public override Color ImageMarginGradientEnd { get { return BackColor; } }
    public override Color ImageMarginGradientMiddle { get { return BackColor; } }
    }
  }"

  $ContainerColor = [System.Drawing.Color]'45, 45, 45'
  $BackColor = [System.Drawing.Color]'32, 32, 32'
  #$ForeColor = [System.Drawing.Color]::White
  $BorderColor = '#CC0078D7' #[System.Drawing.Color]::DimGray'
  #$SelectionBackColor = [System.Drawing.SystemColors]::Highlight
  $MenuSelectionColor = '#FF0067B9' # '#CC0078D7'#[System.Drawing.Color]::AliceBlue'
  #$SelectionForeColor = [System.Drawing.Color]::White
  $colorTable = New-Object SAPIENTypes.SAPIENColorTable -ArgumentList $ContainerColor, $BackColor, $BorderColor, $MenuSelectionColor
  $render = New-Object System.Windows.Forms.ToolStripProfessionalRenderer -ArgumentList $colorTable
  $contextmenu.Renderer = $render
  #[System.Windows.Forms.ToolStripManager]::Renderer = $render
  
  # Add Open App
  $Synchash.Open_App = $contextmenu.Items.Add("Open App");
  $Synchash.Open_App.ToolTipText = 'Open App/Restore Focus'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico") 
  $image = [System.Drawing.Image]::FromStream($stream_image)
             
  #$Open_App_Picture = $image#[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$($current_folder)\\Resources\\App_Icon5.ico")))
  $Synchash.Open_App.image = $image
  $Synchash.Open_App.add_Click({
      try{
        $synchash.Window.Show()
        if($SyncHash.Window.WindowState -eq 'Minimized'){
          $SyncHash.Window.WindowState = 'Normal'
        }
        write-ezlogs "Main window size is currently $($synchash.window.height) x $($synchash.window.width)" -showtime     
        $window_active = $synchash.Window.Activate()    
        $null = [System.GC]::GetTotalMemory($true) 
      }catch{
        write-ezlogs "An exception occurred in Open_App click event" -showtime -catcherror $_
      }
  }.GetNewClosure())

  #Add menu Playlists
  $Synchash.Tray_Playlists = $contextmenu.Items.Add("Playlists");
  #$Launchers_imagecontrol.Kind = 'Launch'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\PlaylistMusic.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Synchash.Tray_Playlists.image = $image 
  foreach ($playlist in $synchash.all_playlists | where {$_.playlist_tracks.id} | select -first 25){
    $playlist_item = New-Object System.Windows.Forms.ToolStripMenuItem
    $playlist_item.dropdown.Renderer = $render
    $playlist_item.DropDown.ForeColor = 'WhiteSmoke'
    $playlist_item.ForeColor = 'WhiteSmoke'
    $playlist_item.text = "$($playlist.name)"    
    $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Fontisto-PlayList.png")
    $image =  [System.Drawing.Image]::FromStream($stream_image)
    $playlist_item_Picture = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Platforms\$($Platform.name)_16.ico")))
    $playlist_item.Image = $playlist_item_Picture 
    $playlist_item.add_Click({
        param($Sender)
        if($($sender.text) -match 'Play:'){
          $playlistName = $($sender.text) -replace 'Play: '
        }else{
          $playlistName = $($sender.text)
        }       
        $playlist_items = ($synchash.all_playlists | where {$_.name -eq $playlistName}).playlist_tracks
        write-ezlogs "Adding all items in Playlist $($playlistName) to Play Queue" -showtime
        #write-ezlogs "Playlist tracks $(($synchash.all_playlists | where {$_.name -eq $playlistName}) | out-string)" -showtime
        foreach($Media in $playlist_items){
          if($Media.Spotify_Path){
            if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
              write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
              $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
            }   
          }elseif($thisapp.config.Current_Playlist -notcontains $Media.id){
            write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
            $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisapp.config.Current_Playlist.add($index,$Media.id)            
          }  
        }
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8   
        $start_media = $playlist_items | select -first 1
        write-ezlogs "[Tray-Menu] >>>> Starting playback of $($start_media | Out-String)" -showtime -color cyan
        if($start_media.Spotify_path){
          Start-SpotifyMedia -Media $start_media -thisApp $thisapp -synchash $synchash
        }else{
          Start-Media -media $start_media -thisApp $thisapp -synchash $synchash
        }
        return 
    })
    foreach ($track in $playlist.playlist_tracks | where {$_.id} | select -first 25){
      $track_item = New-Object System.Windows.Forms.ToolStripMenuItem
      $track_item.dropdown.Renderer = $render
      $track_item.DropDown.ForeColor = 'WhiteSmoke'
      $track_item.ForeColor = 'WhiteSmoke'
      $track_item.text = "$($track.title)"
      $track_item.tag = $track.id
      $playlist_item_Icon = (($syncHash.Playlists_TreeView.Items | where {$_.Header.Title -eq $($playlist.name)}).items | where {$_.header.id -eq $track.id}).uid
      #write-ezlogs "Icon: $($playlist_item_Icon)" -showtime
      #write-ezlogs "items: $(($syncHash.Playlists_TreeView.Items | where {$_.Header.Title -eq $($playlist.name)}).items)" -showtime
      if($playlist_item_Icon){
        $stream_image = [System.IO.File]::OpenRead($playlist_item_Icon)
        $image =  [System.Drawing.Image]::FromStream($stream_image)
        $track_item.Image = $image
      }
      $track_item.add_MouseDown({
          param($Sender)
          if($args.Button -eq 'Left'){
            if($($sender.OwnerItem.text) -match 'Play:'){
              $playlistName = $($sender.OwnerItem.text) -replace 'Play: '
            }else{
              $playlistName = $($sender.OwnerItem.text)
            }  
            $mediaid = $sender.tag               
            $Media = ($synchash.all_playlists | where {$_.name -eq $playlistName}).playlist_tracks | where {$_.id -eq $mediaid}
            #write-ezlogs "Adding track $($media.title) from Playlist $($playlistName) to Play Queue" -showtime
            #write-ezlogs "Playlist tracks $(($synchash.all_playlists | where {$_.name -eq $playlistName}) | out-string)" -showtime
            if($Media.Spotify_Path){
              if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
                write-ezlogs " | Adding track $($media.title) from Playlist $($playlistName) to Play Queue" -showtime
                $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                $index++
                $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
              }   
            }elseif($thisapp.config.Current_Playlist -notcontains $Media.id){
              write-ezlogs " | Adding track $($media.title) from Playlist $($playlistName) to Play Queue" -showtime
              $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisapp.config.Current_Playlist.add($index,$Media.id)            
            }  
            $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8   
            write-ezlogs "[Tray-Menu] >>>> Starting playback of $($Media | Out-String)" -showtime -color cyan
            if($Media.Spotify_path){
              Start-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash
            }else{
              Start-Media -media $Media -thisApp $thisapp -synchash $synchash
            }
            return              
          }
      })
      $null = $playlist_item.DropDownItems.add($track_item)
    }
    $null = $Synchash.Tray_Playlists.DropDownItems.add($playlist_item)
  }

  #Add menu Playback Options
  $PlaybackOptions = $contextmenu.Items.Add("Playback Options");
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Audio-Options.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $PlaybackOptions.image = $image 
  $synchash.Shuffle_trayOption = New-Object System.Windows.Forms.ToolStripMenuItem
  $synchash.Shuffle_trayOption.dropdown.Renderer = $render
  $synchash.Shuffle_trayOption.DropDown.ForeColor = 'WhiteSmoke'
  $synchash.Shuffle_trayOption.ForeColor = 'WhiteSmoke'
  $synchash.Shuffle_trayOption.text = 'Shuffle'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\$($synchash.Shuffle_Icon.Kind).png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $synchash.Shuffle_trayOption.Image = $image
  $synchash.Shuffle_trayOption.Checked = $thisapp.config.Shuffle_Playback
  $Null = $synchash.Shuffle_trayOption.add_Click($synchash.Shuffle_Playback_tray_command)
  $null = $PlaybackOptions.DropDownItems.add($synchash.Shuffle_trayOption)

  
  # Add menu Stop
  $Synchash.Menu_Stop = $contextmenu.Items.Add("Stop Media");
  $Synchash.Menu_Stop.ToolTipText = 'Stop Playback of Media'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-Stop.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Synchash.Menu_Stop.image = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Material-Close.png")))
  #$Synchash.Main_Tool_Icon.ContextMenuStrip = $contextmenu
  #$null = $Menu_Stop.AddHandler([System.Windows.Controls.Button]::ClickEvent,$StopMedia_Command)
  $Synchash.Menu_Stop.add_Click($Synchash.Menu_StopMedia_Command)
  
  # Add menu Pause
  $Synchash.Menu_Pause = $contextmenu.Items.Add("Pause Media");
  $Synchash.Menu_Pause.ToolTipText = 'Pause or Resume Media'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-PauseCircle.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Synchash.Menu_Pause.image = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Material-Close.png")))
  #$Synchash.Main_Tool_Icon.ContextMenuStrip = $contextmenu
  #$null = $Menu_Stop.AddHandler([System.Windows.Controls.Button]::ClickEvent,$StopMedia_Command)
  $Synchash.Menu_Pause.add_Click($Synchash.Menu_PauseMedia_Command)  
  
  # Add menu Next
  $Synchash.Menu_Next = $contextmenu.Items.Add("Next Media");
  $Synchash.Menu_Next.ToolTipText = 'Play Next Media in Queue'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-SkipNext.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Synchash.Menu_Next.image = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Material-Close.png")))
  $Synchash.Menu_Next.add_Click($Synchash.Menu_NextMedia_Command)  
  
  # Add menu exit
  $Synchash.Menu_Exit = $contextmenu.Items.Add("Exit");
  $Synchash.Menu_Exit.ToolTipText = 'Exit App'
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-Close.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Synchash.Menu_Exit.image = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Material-Close.png")))
  $Synchash.Menu_Exit.add_Click({
      try{
        $Synchash.Main_Tool_Icon.Visible = $false
        $syncHash.Window.close()
      }catch{
        write-ezlogs "An exception ocurred in Menu_exit click event" -showtime -catcherror $_
      }
  }.GetNewClosure())  
  $Synchash.Main_Tool_Icon.ContextMenuStrip = $contextmenu
  #$synchash.myNotifyIcon.ContextMenu = $Synchash.Media_ContextMenu

  return $Synchash.Main_Tool_Icon
}
#---------------------------------------------- 
#endregion Add-TrayMenu Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-TrayMenu')

