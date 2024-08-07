<#
    .Name
    Initialize-XAML

    .Version 
    0.1.0

    .SYNOPSIS
    Loads and parses XAML files to create WPF window

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Collections.Hashtable

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>


#---------------------------------------------- 
#region Initialize-XAML
#----------------------------------------------
function Initialize-XAML {
  [CmdletBinding()]
  param (
    [string]$Current_folder,
    $thisApp,
    $synchash
  )
  try{
    #---------------------------------------------- 
    #region Required Assemblies
    #----------------------------------------------
    [void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
    [void][System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')
    [void][System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Collections')
    #---------------------------------------------- 
    #endregion Required Assemblies
    #----------------------------------------------
    $ViewsPath = "$($Current_folder)\views"
    if([System.io.directory]::Exists($ViewsPath)){
      $Main_Window_XML = "$ViewsPath\MainWindow.xaml"
      $LocalMediaBrowser_XML = "$ViewsPath\LocalMediaBrowser.xaml"
      $SpotifyBrowser_XML = "$ViewsPath\SpotifyBrowser.xaml"
      $TwitchBrowser_XML = "$ViewsPath\TwitchBrowser.xaml"
      $YoutubeBrowser_XML = "$ViewsPath\YoutubeBrowser.xaml"    
      $MainWindow = [System.IO.File]::ReadAllText($Main_Window_XML)
      $XamlLocalMediaBrowser = [System.IO.File]::ReadAllText($LocalMediaBrowser_XML)
      $XamlSpotifyBrowser = [System.IO.File]::ReadAllText($SpotifyBrowser_XML)
      $XamlyoutubeBrowser = [System.IO.File]::ReadAllText($TwitchBrowser_XML)
      $XamlTwitchBrowser = [System.IO.File]::ReadAllText($YoutubeBrowser_XML)

      if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.PrimaryAccentColor){
        $PrimaryAccentColor = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
      }else{
        $PrimaryAccentColor = "{StaticResource MahApps.Brushes.Accent}"
      }
      $xaml = ($MainWindow).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml").Replace("<Tabitem Name=`"LOCALMEDIABROWSER_REPLACE_ME`"/>","$XamlLocalMediaBrowser").Replace("<Tabitem Name=`"SPOTIFYBROWSER_REPLACE_ME`"/>","$XamlSpotifyBrowser").Replace("<Tabitem Name=`"YOUTUBEBROWSER_REPLACE_ME`"/>","$XamlYoutubeBrowser").Replace(`
      "{StaticResource MahApps.Brushes.Accent}","$($PrimaryAccentColor)").Replace("<Tabitem Name=`"TWITCHBROWSER_REPLACE_ME`"/>","$XamlTwitchBrowser").Replace("{CURRENT_FOLDER}","$($Current_folder)")
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      $synchash.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $synchash.Window){
          $synchash."$($name)" = $synchash.Window.FindName($name)
        }
      }
      $reader.Dispose()

      #Enable support for OS theme styling and High DPI
      [void][System.Windows.Forms.Application]::EnableVisualStyles()
    }else{
      write-ezlogs "Failed to load main window - xaml files not found! -- Cannot continue!" -warning
    }
  }catch{
    write-ezlogs "An exception occurred in Intialize-Xaml" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Initialize-XAML
#----------------------------------------------
Export-ModuleMember -Function @('Initialize-XAML')