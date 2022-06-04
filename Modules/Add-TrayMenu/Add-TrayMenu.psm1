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
    [switch]$Startup,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog
  )

  #Tray Icon
  #$image =  [System.Drawing.Image]::FromStream($stream_image)
  #$icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap][System.Drawing.Image]::FromStream([System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"))).GetHicon())
  $Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
  $Main_Tool_Icon.Text = "$($thisApp.Config.App_Name) - Version $($thisApp.Config.App_Version)"
  $Main_Tool_Icon.Icon =  "$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico"
  $Main_Tool_Icon.Visible = $true

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
  $ForeColor = [System.Drawing.Color]::White
  $BorderColor = '#CC0078D7' #[System.Drawing.Color]::DimGray'
  $SelectionBackColor = [System.Drawing.SystemColors]::Highlight
  $MenuSelectionColor = '#CC0078D7'#[System.Drawing.Color]::AliceBlue'
  $SelectionForeColor = [System.Drawing.Color]::White
  $colorTable = New-Object SAPIENTypes.SAPIENColorTable -ArgumentList $ContainerColor, $BackColor, $BorderColor, $MenuSelectionColor
  $render = New-Object System.Windows.Forms.ToolStripProfessionalRenderer -ArgumentList $colorTable
  $contextmenu.Renderer = $render
  #[System.Windows.Forms.ToolStripManager]::Renderer = $render
  
  # Add Open App
  $Open_App = $contextmenu.Items.Add("Open App");
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\MainIcon.ico") 
  $image = [System.Drawing.Image]::FromStream($stream_image)
             
  #$Open_App_Picture = $image#[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$($current_folder)\\Resources\\App_Icon5.ico")))
  $Open_App.image = $image
  $Open_App.add_Click({
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
  
  # Add menu exit
  $Menu_Exit = $contextmenu.Items.Add("Exit");
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-Close.png")
  $image =  [System.Drawing.Image]::FromStream($stream_image)
  $Menu_Exit.image = $image #[System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes("$image_resources_dir\Material-Close.png")))
  $Main_Tool_Icon.ContextMenuStrip = $contextmenu
  $Menu_Exit.add_Click({
      try{
        $Main_Tool_Icon.Visible = $false
        $syncHash.Window.close()
      }catch{
        write-ezlogs "An exception ocurred in Menu_exit click event" -showtime -catcherror $_
      }
  }.GetNewClosure())  
  
  return $Main_Tool_Icon
}
#---------------------------------------------- 
#endregion Add-TrayMenu Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-TrayMenu')

