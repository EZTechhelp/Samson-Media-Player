<#
    .Name
    Show-FirstRun 

    .Version 
    0.0.1

    .SYNOPSIS
    Displays a window on first time app run to provide setup options 

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
# Mahapps Library
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
Add-Type -AssemblyName WindowsFormsIntegration
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
function Close-FirstRun (){
  #$hashsetup.window.Dispatcher.Invoke("Normal",[action]{ $hashsetup.window.close() })
  $hashsetup.window.close()
}



#---------------------------------------------- 
#region Open-FileDialog Function
#----------------------------------------------
function Open-FileDialog
{
  param (
    [string]$Title = "Select file",
    [switch]$MultiSelect
  )  
  $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
  $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.AddExtension = $true
  #$OpenFileDialog.InitialDirectory = [environment]::getfolderpath('mydocuments')
  $OpenFileDialog.CheckFileExists = $true
  $OpenFileDialog.Multiselect = $MultiSelect
  $OpenFileDialog.Filter = "All Files (*.*)|*.*"
  $OpenFileDialog.CheckPathExists = $false
  $OpenFileDialog.Title = $Title
  $results = $OpenFileDialog.ShowDialog()
  if ($results -eq [System.Windows.Forms.DialogResult]::OK) 
  {
    Write-Output $OpenFileDialog.FileNames
  }
}
#---------------------------------------------- 
#endregion Open-FileDialog Function
#----------------------------------------------


#---------------------------------------------- 
#region Update-MediaLocations Function
#----------------------------------------------
function Update-MediaLocations
{
  param (
    [switch]$Clear,
    $thisApp,
    [switch]$Startup,
    [switch]$Open_Flyout,
    $Locations_array,
    [string]$Path,
    [string]$Level,
    [string]$Viewlink,
    [string]$Message_color,
    $hashsetup,
    [switch]$VerboseLog
  )
  $Fields = @(
    'Number'
    'Path'
    'MediaCount'
  )
  if(!$hashsetup.MediaLocations_Grid.items){
    $Global:Locationstable =  [hashtable]::Synchronized(@{})
    $Global:Locationstable.datatable = New-Object System.Data.DataTable 
    [void]$Locationstable.datatable.Columns.AddRange($Fields)
    $Number = 1
  }else{
    $Number = $hashsetup.MediaLocations_Grid.items.Number | select -last 1
    $Number++
  }
  if($VerboseLog){write-ezlogs ">>>> Updating Media Locations table" -showtime -enablelogs}
  if($Locations_array)
  {
    foreach ($n in $Locations_array)
    {
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($n.Number)
      $Null = $array.add($n.Path)
      [void]$Locationstable.datatable.Rows.Add($array)
    } 
  }
  <#  if($Path){
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($Number)
      $Null = $array.add($Path)
      #[void]$Notfiytable.datatable.Rows.Add($array)
  }#>
  if($VerboseLog){write-ezlogs " | Adding Number: $Number -- Path: $path" -showtime -enablelogs}
  $media_pattern = [regex]::new('$(?<=\.(MP3|mp3|Mp3|mP3|mp4|MP4|Mp4|flac|FLAC|Flac|WAV|wav|Wav|AVI|Avi|avi|wmv|h264|mkv|webm|h265|mov|h264|mpeg|mpg4|movie|mpgx|vob|3gp|m2ts|aac))')
  if([System.IO.Directory]::Exists($Path)){
    try{
      $directory_filecount = @([System.IO.Directory]::GetFiles("$($Path)",'*','AllDirectories') | Where{$_ -match $media_pattern}).count
    }catch{
      write-ezlogs "An exception occurred attempting to get directory file count for path $Path" -showtime -catcherror $_
    }
  }
  $itemssource = [pscustomobject]@{
    Number=$Number;
    Path=$Path
    MediaCount=$directory_filecount
  }
  
  $hashsetup.MediaLocations_Grid.Background = "Transparent"
  $hashsetup.MediaLocations_Grid.AlternatingRowBackground = "Transparent"
  $hashsetup.MediaLocations_Grid.CanUserReorderColumns = $false
  $hashsetup.MediaLocations_Grid.CanUserDeleteRows = $true
  $hashsetup.MediaLocations_Grid.Foreground = "White"
  $hashsetup.MediaLocations_Grid.RowBackground = "Transparent"
  $hashsetup.MediaLocations_Grid.HorizontalAlignment ="Left"
  $hashsetup.MediaLocations_Grid.CanUserAddRows = $False
  $hashsetup.MediaLocations_Grid.HorizontalContentAlignment = "left"
  $hashsetup.MediaLocations_Grid.IsReadOnly = $True

  #$hashsetup.MediaLocations_Grid.HorizontalGridLinesBrush = "DarkGray"
  $hashsetup.MediaLocations_Grid.GridLinesVisibility = "Horizontal"
  try{
    if([int]$hashsetup.MediaLocations_Grid.items.count -lt 1){
      [int]$Locations = 1
    }else{
      [int]$Locations = [int]$hashsetup.MediaLocations_Grid.items.count + 1
    }      
    $null = $hashsetup.MediaLocations_Grid.Items.add($itemssource)
  }catch{
    write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
  }      

}
#---------------------------------------------- 
#endregion Update-MediaLocations Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-YoutubePlaylists Function
#----------------------------------------------
function Update-YoutubePlaylists
{
  param (
    [switch]$Clear,
    $thisApp,
    [switch]$Startup,
    [switch]$Open_Flyout,
    $Locations_array,
    [string]$Path,
    [string]$Level,
    [string]$Viewlink,
    [string]$Message_color,
    $hashsetup,
    [switch]$VerboseLog
  )
  $Fields = @(
    'Number'
    'Path'
  )
  if(!$hashsetup.YoutubePlaylists_Grid.items){
    $Global:YoutubePlayliststable =  [hashtable]::Synchronized(@{})
    $Global:YoutubePlayliststable.datatable = New-Object System.Data.DataTable 
    [void]$YoutubePlayliststable.datatable.Columns.AddRange($Fields)
    $Number = 1
  }else{
    $Number = $hashsetup.YoutubePlaylists_Grid.items.Number | select -last 1
    $Number++
  }
  if($VerboseLog){write-ezlogs ">>>> Updating Youtube Playlists table" -showtime -enablelogs}
  if($Locations_array)
  {
    foreach ($n in $Locations_array)
    {
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($n.Number)
      $Null = $array.add($n.Path)
      [void]$YoutubePlayliststable.datatable.Rows.Add($array)
    } 
  }
  <#  if($Path){
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($Number)
      $Null = $array.add($Path)
      #[void]$Notfiytable.datatable.Rows.Add($array)
  }#>
  if($VerboseLog){write-ezlogs " | Adding Numnber: $Number -- Path: $path" -showtime -enablelogs}
  $itemssource = [pscustomobject]@{
    Number=$Number;
    Path=$Path
  }
  
  $hashsetup.YoutubePlaylists_Grid.Background = "Transparent"
  $hashsetup.YoutubePlaylists_Grid.AlternatingRowBackground = "Transparent"
  $hashsetup.YoutubePlaylists_Grid.CanUserReorderColumns = $false
  $hashsetup.YoutubePlaylists_Grid.CanUserDeleteRows = $true
  $hashsetup.YoutubePlaylists_Grid.Foreground = "White"
  $hashsetup.YoutubePlaylists_Grid.RowBackground = "Transparent"
  $hashsetup.YoutubePlaylists_Grid.HorizontalAlignment ="Left"
  $hashsetup.YoutubePlaylists_Grid.CanUserAddRows = $False
  $hashsetup.YoutubePlaylists_Grid.HorizontalContentAlignment = "left"
  $hashsetup.YoutubePlaylists_Grid.IsReadOnly = $True

  #$hashsetup.MediaLocations_Grid.HorizontalGridLinesBrush = "DarkGray"
  $hashsetup.YoutubePlaylists_Grid.GridLinesVisibility = "Horizontal"
  try{
    if([int]$hashsetup.YoutubePlaylists_Grid.items.count -lt 1){
      [int]$Locations = 1
    }else{
      [int]$Locations = [int]$hashsetup.YoutubePlaylists_Grid.items.count + 1
    }      
    $null = $hashsetup.YoutubePlaylists_Grid.Items.add($itemssource)
  }catch{
    write-ezlogs "An exception occurred adding items to Locations grid" -showtime -catcherror $_
  }      

}
#---------------------------------------------- 
#endregion Update-MediaLocations Function
#----------------------------------------------


#---------------------------------------------- 
#region Show-FirstRun Function
#----------------------------------------------
function Show-FirstRun{
  Param (
    [string]$PageTitle,
    [string]$PageHeader,
    [string]$Logo,
    [switch]$First_Run,
    [switch]$Update,
    $thisScript,
    $synchash,
    $thisApp,
    $hash,
    $PlaySpotify_Media_Command,
    $PlayMedia_Command,
    $Script_Modules,
    [string]$all_games_profile_path,
    $Platform_launchers,
    $Save_GameSessions,
    $all_installed_games,
    [string]$Game_Profile_Directory,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog,
    [switch]$Export_Profile,
    [switch]$update_global
  )  
  $global:hashsetup = [hashtable]::Synchronized(@{}) 
  $Global:Current_Folder = $($thisScript.path | Split-path -Parent)
  if(!([System.IO.Directory]::Exists("$Current_Folder\\Views"))){
    $Global:Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
  }   
  #$Splash_setup = {
  if($thisapp){
    $thisApp.Config = Import-Clixml $thisApp.Config.Config_path
  }
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $pattern3 = "[`?�™$illegal]"     
  try{
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
    
    $add_Window_XML = "$($Current_Folder)\\Views\\FirstRun.xaml"
    if(!([System.IO.file]::Exists($add_Window_XML))){
      $Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
      $add_Window_XML = "$($Current_Folder)\\Views\\FirstRun.xaml"
    }
    $xaml=(New-Object System.Xml.XmlDocument)
    $xaml.Load($add_Window_XML)  
    $styles = (($xaml.MetroWindow.'Window.Resources'.ResourceDictionary.'ResourceDictionary.MergedDictionaries'.ResourceDictionary) | where {$_.source -match 'styles.xaml'})
    $styles.source = "$($Current_Folder)`\Views`\Styles.xaml"    
    #[xml]$xaml = Get-content "$($Current_Folder)\\Views\\FirstRun.xaml" -Force
    if($Verboselog){write-ezlogs ">>>> Script path: $($Current_Folder)\\Views\\FirstRun.xaml" -showtime -enablelogs -Color cyan}
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    
    $hashsetup.Window=[Windows.Markup.XamlReader]::Load($reader)

    [xml]$XAML = $xaml
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {   
      $hashsetup."$($_.Name)" =  $hashsetup.Window.FindName($_.Name)  
    }  
  }
  catch
  {
    write-ezlogs "An exception occurred when loading xaml" -CatchError $_
      
  }      
  $hashsetup.Logo.Source=$Logo
  $hashsetup.Window.title =$PageTitle
  $hashsetup.PageHeader.content = $PageHeader
  #Update-EditorHelp  
  function Show-Console
  {
    $consolePtr = [Console.Window]::GetConsoleWindow()

    # Hide = 0,
    # ShowNormal = 1,
    # ShowMinimized = 2,
    # ShowMaximized = 3,
    # Maximize = 3,
    # ShowNormalNoActivate = 4,
    # Show = 5,
    # Minimize = 6,
    # ShowMinNoActivate = 7,
    # ShowNoActivate = 8,
    # Restore = 9,
    # ShowDefault = 10,
    # ForceMinimized = 11

    [Console.Window]::ShowWindow($consolePtr, 4)
  }
  function Hide-Console
  {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
  }  
  function update-EditorHelp{    
    param (
      [string]$content,
      [string]$color = "White",
      [string]$FontWeight = "Normal",
      [string]$FontSize = 14,
      [string]$BackGroundColor = "Transparent",
      [string]$TextDecorations,
      [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
      [switch]$AppendContent,
      [switch]$MultiSelect,
      [System.Windows.Controls.RichTextBox]$RichTextBoxControl = $hashsetup.EditorHelpFlyout
    ) 
    #$hashsetup.Editor_Help_Flyout.Document.Blocks.Clear()  
    $hashsetup.EditorHelpFlyout.MaxHeight= $hashsetup.Window.Height - 50
    $Paragraph = New-Object System.Windows.Documents.Paragraph
    $RichTextRange = New-Object System.Windows.Documents.Run               
    $RichTextRange.Foreground = $color
    $RichTextRange.FontWeight = $FontWeight
    $RichTextRange.FontSize = $FontSize
    $RichTextRange.Background = $BackGroundColor
    $RichTextRange.TextDecorations = $TextDecorations
    $RichTextRange.AddText($content)
    $Paragraph.Inlines.add($RichTextRange)
    if($AppendContent){
      $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
      #post the content and set the default foreground color
      foreach($inline in $Paragraph.Inlines){
        $existing_content.inlines.add($inline)
      }
    }else{
      $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
    }      
  }
  #---------------------------------------------- 
  #region Remove Media Location Button
  #----------------------------------------------
  [System.Windows.RoutedEventHandler]$RemoveclickEvent = {
    param ($sender,$e)
    try{
      $null = $hashsetup.MediaLocations_Grid.Items.Remove($hashsetup.MediaLocations_Grid.SelectedItem)
    }catch{
      write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
    }
  }  
  [System.Windows.RoutedEventHandler]$RemoveAllclickEvent = {
    param ($sender,$e)
    try{
      $null = $hashsetup.MediaLocations_Grid.items.clear()
    }catch{
      write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
    }
  } 
  [System.Windows.RoutedEventHandler]$RemovePlaylistclickEvent = {
    param ($sender,$e)
    try{
      $null = $hashsetup.YoutubePlaylists_Grid.Items.Remove($hashsetup.YoutubePlaylists_Grid.SelectedItem)
    }catch{
      write-ezlogs "An exception occurred for removeclickevent" -showtime -catcherror $_
    }
  }  
  [System.Windows.RoutedEventHandler]$RemoveAllPlaylistclickEvent = {
    param ($sender,$e)
    try{
      $null = $hashsetup.YoutubePlaylists_Grid.items.clear()
    }catch{
      write-ezlogs "An exception occurred for removeallclickevent" -showtime -catcherror $_
    }
  }   
  if($hashsetup.MediaLocations_Grid.Columns.count -lt 5){
    $buttontag = @{        
      hashsetup=$hashsetup;
      thisScript=$thisScript;
      thisApp=$thisApp
    }  
    $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("ToolsButtonStyle"))
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismiss_button")
    $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveclickEvent)
    $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
    $dataTemplate = New-Object System.Windows.DataTemplate
    $dataTemplate.VisualTree = $buttonFactory
    $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("ToolsButtonStyle"))
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Locations_dismissAll_button")
    $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllclickEvent)
    $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
    $headerdataTemplate = New-Object System.Windows.DataTemplate
    $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
    $buttonColumn.CellTemplate = $dataTemplate
    $buttonColumn.HeaderTemplate = $headerdataTemplate 
    $buttonColumn.DisplayIndex = 0  
    $null = $hashsetup.MediaLocations_Grid.Columns.add($buttonColumn)
  }
  if($hashsetup.YoutubePlaylists_Grid.Columns.count -lt 5){
    $buttontag = @{        
      hashsetup=$hashsetup;
      thisScript=$thisScript;
      thisApp=$thisApp
    }  
    $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove")
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("ToolsButtonStyle"))
    $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismiss_button")
    $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemovePlaylistclickEvent)
    $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
    $dataTemplate = New-Object System.Windows.DataTemplate
    $dataTemplate.VisualTree = $buttonFactory
    $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Remove All")
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $hashsetup.Window.TryFindResource("ToolsButtonStyle"))
    $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Playlists_dismissAll_button")
    $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RemoveAllPlaylistclickEvent)
    $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
    $headerdataTemplate = New-Object System.Windows.DataTemplate
    $headerdataTemplate.VisualTree = $buttonheaderFactory    
    
    $buttonColumn.CellTemplate = $dataTemplate
    $buttonColumn.HeaderTemplate = $headerdataTemplate 
    $buttonColumn.DisplayIndex = 0  
    $null = $hashsetup.YoutubePlaylists_Grid.Columns.add($buttonColumn)
  }  
  #---------------------------------------------- 
  #region Remove Media Location Button
  #----------------------------------------------
  if($Update){
    $hashsetup.Setup_Button_Textblock.text = "Apply Changes"
  }
  if(@($thisApp.Config.Media_Directories).count -gt 0){
    foreach($directory in $thisApp.Config.Media_Directories){
      Update-MediaLocations -hashsetup $hashsetup -Path $directory -VerboseLog
    }
  }
  if($thisApp.Config.Import_Local_Media){
    $hashsetup.Import_Local_Media_Toggle.isOn = $true
    $hashsetup.Media_Path_Browse.IsEnabled = $true
    $hashsetup.MediaLocations_Grid.IsEnabled = $true
  }
  if($thisApp.Config.Import_Spotify_Media){
    $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
    if(!$Spotify_Auth_app -and !$First_Run){
      write-ezlogs "Unable to get Spotify authentication, starting spotify authentication setup process" -showtime -warning  
      $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
      write-ezlogs "Importing API XML $APIXML" -showtime
      if([System.IO.File]::Exists($APIXML)){
        $Spotify_API = Import-Clixml $APIXML
        $client_ID = $Spotify_API.ClientID
        $client_secret = $Spotify_API.ClientSecret
      }
      if($Spotify_API -and $client_ID -and $client_secret){
        write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime
        #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($client_secret_raw))
        #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientID_raw))
        New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
        $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name                
        if($Spotify_Auth_app){
          try{
            $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
          }catch{
            write-ezlogs "An exception occurred" -CatchError $_ -enablelogs
          }                
          if($playlists){
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
            $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
            write-ezlogs "[SUCCESS] Authenticated to Spotify and retrieved Playlists" -showtime -color green                           
          }else{
            write-ezlogs "Unable to successfully authenticate to spotify!" -showtime -warning
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
            $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
            update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! Spotify integration will be unavailable" -color orange -FontWeight Bold                
          }
          #$devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
          #Show-WebLogin -SplashTitle "Spotify Account Login" -SplashMessage "Splash Message" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL 'https://accounts.spotify.com/authorize' -thisScript $thisScript
        }else{
          write-ezlogs "Unable to authenticate with Spotify API -- Spotify_Auth_app was null -- cannot continue" -showtime -warning      
          if($hashsetup.EditorHelpFlyout.Document.Blocks){
            $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
          }        
          $hashsetup.Editor_Help_Flyout.isOpen = $true
          $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
          update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API. Spotify integration will be unavailable" -color orange -FontWeight Bold      
        }
      }else{
        write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning      
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }        
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
        update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API. Spotify integration will be unavailable" -color orange -FontWeight Bold      
      }
    }elseif($First_Run){
      $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
    }else{
      $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $true
    }  
  }
  if(@($thisApp.Config.Youtube_Playlists).count -gt 0){
    foreach($playlist in $thisApp.Config.Youtube_Playlists){
      Update-YoutubePlaylists -hashsetup $hashsetup -Path $playlist -VerboseLog
    }
  }  
  if($thisApp.Config.Import_Youtube_Media){
    $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $true
    $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true
    $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
    $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true
    $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 250    
  }else{
    $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 0
  }  
  #---------------------------------------------- 
  #region Get Local Media
  #---------------------------------------------- 
  $hashsetup.Import_Local_Media_Toggle.add_Toggled({
      if($hashsetup.Import_Local_Media_Toggle.isOn)
      {
        $hashsetup.Media_Path_Browse.IsEnabled = $true
        $hashsetup.MediaLocations_Grid.IsEnabled = $true
        Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $true -MemberType NoteProperty -Force
      }
      else
      {
        $hashsetup.MediaLocations_Grid.IsEnabled = $false
        $hashsetup.Media_Path_Browse.IsEnabled = $false
        Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $false -MemberType NoteProperty -Force
      }
  })

  $hashsetup.Import_Local_Media_Button.add_click({
      if($hashsetup.EditorHelpFlyout.Document.Blocks){
        $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
      }  
      $hashsetup.Editor_Help_Flyout.isOpen = $true
      $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Local_Media_Toggle.content
      update-EditorHelp -content "Enabling this will attempt to import all media from each local directory you specify"
      update-EditorHelp -content "The following formats are currently supported
        'Mp3'
        'mp4'
        'wav'
        'flac'
        'h264'
        'avi'
        'mkv'
        'webm'
        'h265'
        'mov'
        'wmv'
        'h264'
        'mpeg'
        'mpg4'
        'movie'
        'mpgx'
        'vob'
        '3gp'
        'm2ts'
      'aac'" -color Cyan

      #update-EditorHelp -content "IMPORTANT: This setting will likely increase the import/scanning time of the first run setup significantly, depending on how many steam games you own" -FontWeight bold -color orange
      #update-EditorHelp -content "IMPORTANT: In order for this option to work, your Steam account profile must be set to public" -FontWeight bold -color orange
  })      
  #---------------------------------------------- 
  #endregion Get Local Media
  #----------------------------------------------
      
  #---------------------------------------------- 
  #region Get Spotify Media
  #----------------------------------------------
  $hashsetup.Import_Spotify_Playlists_Toggle.add_Toggled({
  
      if($hashsetup.Import_Spotify_Playlists_Toggle.isOn)
      {     

        $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
        if(!$Spotify_Auth_app){
          write-ezlogs "Unable to get Spotify authentication, starting spotify authentication setup process" -showtime -warning  
          $APIXML = "$($thisApp.Config.Current_folder)\\Resources\API\Spotify-API-Config.xml"
          write-ezlogs "Importing API XML $APIXML" -showtime
          if([System.IO.File]::Exists($APIXML)){
            $Spotify_API = Import-Clixml $APIXML
            $client_ID = $Spotify_API.ClientID
            $client_secret = $Spotify_API.ClientSecret            
          }
          if($Spotify_API -and $client_ID -and $client_secret){
            write-ezlogs "Creating new Spotify Application '$($thisApp.config.App_Name)'" -showtime
            #$client_secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientSecret | ConvertTo-SecureString))))
            #$client_ID = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($Spotify_API.ClientID | ConvertTo-SecureString))))            
            New-SpotifyApplication -ClientId $client_ID -ClientSecret $client_secret -Name $thisApp.config.App_Name -RedirectUri $Spotify_API.Redirect_URLs
            $Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
            if($Spotify_Auth_app){
              try{
                $playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript                
              }catch{
                write-ezlogs "[Show-FirstRun] An exception occurred executing Get-CurrentUserPlaylists" -CatchError $_ -enablelogs
              }                             
              if($playlists){
                Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
                write-ezlogs "[SUCCESS] Authenticated to Spotify and retrieved Playlists" -showtime -color green 
                if($MahDialog_hash.window.Dispatcher){
                  $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                }  
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[SUCCESS] Authenticated to Spotify and retrieved Playlists! In order for Spotify playback to work properly, please ensure that you are logged in to the Spotify app with your account. You may close this message" -color lightgreen -FontWeight Bold                           
              }else{
                write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to spotify!" -showtime -warning
                Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
                $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
                update-EditorHelp -content "[WARNING] Unable to successfully authenticate to spotify! (No playlists returned!) Spotify integration will be unavailable" -color orange -FontWeight Bold
                Remove-SpotifyApplication -Name $thisApp.config.App_Name               
              }
              if($hashsetup.Window){
                $hashsetup.Window.Showdialog()
              }              
              #$devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name -thisApp $thisApp -thisScript $thisScript
              #Show-WebLogin -SplashTitle "Spotify Account Login" -SplashMessage "Splash Message" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png" -WebView2_URL 'https://accounts.spotify.com/authorize' -thisScript $thisScript
            }
          }else{
            write-ezlogs "Unable to authenticate with Spotify API -- cannot continue" -showtime -warning      
            if($hashsetup.EditorHelpFlyout.Document.Blocks){
              $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
            }        
            $hashsetup.Editor_Help_Flyout.isOpen = $true
            $hashsetup.Editor_Help_Flyout.header = 'Spotify'            
            update-EditorHelp -content "[WARNING] Unable to authenticate with Spotify API (Couldn't find API creds!). Spotify integration will be unavailable" -color orange -FontWeight Bold    
            Remove-SpotifyApplication -Name $thisApp.config.App_Name   
            return
          }
        }else{
          if($thisApp.Config.Verbose_logging){write-ezlogs "[SUCCESS] Returned Spotify application $($Spotify_Auth_app | out-string)" -showtime}
        }         
      
     
        <#        try{
            $Button_Style = [MahApps.Metro.Controls.Dialogs.LoginDialogSettings]::new()  
            $spoti_creds = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($hashsetup.Window,'Spotify Account','Enter your Spotify account username and password. This will be stored in the Windows Credential Manager',$Button_Style )
            }catch{
            write-ezlogs "An exception occurred when getting Spotify credentials" -CatchError $_ -enablelogs
            }  
            if($spoti_creds){
            $SecureString = $spoti_creds.SecurePassword
            $username = $spoti_creds.Username
            try{
            Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$SecureString
            $secretstore = Get-SecretVault -Name EZT-SecretStore -ErrorAction SilentlyContinue
            if(!$secretstore){
            Register-SecretVault -Name EZT-SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
            $secretstore = 'EZT-SecretStore'
            }else{
            $secretstore = $secretstore.name
            }        
            Set-Secret -Name SpotiHost -Secret "accounts.spotify.com" -Vault $secretstore
            Set-Secret -Name SpotiUser -Secret $username -Vault $secretstore
            Set-Secret -Name SpotiPassword -Secret $spoti_creds.password -Vault $secretstore
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force   
            }catch{
            write-ezlogs "An exception occurred when setting or configuring the secret store" -CatchError $_ -enablelogs
            $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force            
            }            
            }else{
            $hashsetup.Import_Spotify_Playlists_Toggle.isOn = $false
            Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
        }  #>   
      }
      else
      {
        Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
      }
  })
  $hashsetup.Import_Spotify_Playlists_Button.add_click({
      try{  
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }        
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Spotify_Playlists_Toggle.content
        update-EditorHelp -content "Enabling this will attempt to import all Spotify playlists and media from your Spotify account. A Spotify account and credentials will be required"
        #update-EditorHelp -content "IMPORTANT: This setting will likely increase the import/scanning time of the first run setup significantly, depending on how many Ubisoft games you own" -FontWeight bold -color orange
        #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
      }catch{
        write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
      }

  })      
  #---------------------------------------------- 
  #endregion Get Spotify Media
  #----------------------------------------------
  
  #---------------------------------------------- 
  #region Get Youtube Media
  #----------------------------------------------
  if($thisApp.config.Youtube_Browser){     
    $hashsetup.Import_Youtube_Auth_ComboBox.selecteditem = $hashsetup.Import_Youtube_Auth_ComboBox.items | where {$_.content -eq $thisApp.config.Youtube_Browser}
  }else{
    $hashsetup.Import_Youtube_Auth_ComboBox.selectedindex = -1
  } 
  if($hashsetup.Import_Youtube_Auth_ComboBox.selectedindex -ne -1){     
    $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Green"
  }else{
    $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Red"
  } 
  if($thisApp.config.Import_Youtube_Browser_Auth){     
    $hashsetup.Import_Youtube_Auth_Toggle.isOn = $true
    $hashsetup.Import_Youtube_Auth_ComboBox.IsEnabled = $true
  }else{
    $hashsetup.Import_Youtube_Auth_Toggle.isOn = $false
    $hashsetup.Import_Youtube_Auth_ComboBox.IsEnabled = $false
  } 
   
  $hashsetup.Import_Youtube_Auth_ComboBox.add_SelectionChanged({
      if($hashsetup.Import_Youtube_Auth_ComboBox.selectedindex -eq -1)
      {
        $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Red"
      }       
      else
      {
        $hashsetup.Import_Youtube_Auth_Label.BorderBrush = "Green"
      }      
  }) 
  $hashsetup.Import_Youtube_Auth_Toggle.add_Toggled({
      if($hashsetup.Import_Youtube_Auth_Toggle.isOn)
      {
        $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $true
        Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $true -MemberType NoteProperty -Force
      }
      else
      {
        $hashsetup.Import_Youtube_Auth_ComboBox.isEnabled = $false
        Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $false -MemberType NoteProperty -Force
      }
  })       
  $hashsetup.Import_Youtube_Playlists_Toggle.add_Toggled({
  
      if($hashsetup.Import_Youtube_Playlists_Toggle.isOn)
      {     
        $hashsetup.Youtube_Playlists_Browse.IsEnabled = $true
        $hashsetup.YoutubePlaylists_Grid.IsEnabled = $true   
        $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 250  
        $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $true   
        Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $true -MemberType NoteProperty -Force -ErrorAction SilentlyContinue          
      }
      else
      {
        $hashsetup.Youtube_Playlists_Browse.IsEnabled = $false
        $hashsetup.YoutubePlaylists_Grid.IsEnabled = $false    
        $hashsetup.Import_Youtube_Auth_Toggle.isEnabled = $false    
        $hashsetup.Youtube_Playlists_ScrollViewer.MaxHeight = 0
        Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $false -MemberType NoteProperty -Force -ErrorAction SilentlyContinue
      }
  })
  $hashsetup.Import_Youtube_Playlists_Button.add_click({
      try{  
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }        
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Youtube_Playlists_Toggle.content
        update-EditorHelp -content "Enabling this will attempt to import all Youtube playlists and media from your Youtube/Google account. A Google account and credentials will be required"
        #update-EditorHelp -content "IMPORTANT: This setting will likely increase the import/scanning time of the first run setup significantly, depending on how many Ubisoft games you own" -FontWeight bold -color orange
        #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
      }catch{
        write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
      }

  }) 
  $hashsetup.Import_Youtube_Auth_Button.add_click({
      try{  
        if($hashsetup.EditorHelpFlyout.Document.Blocks){
          $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
        }        
        $hashsetup.Editor_Help_Flyout.isOpen = $true
        $hashsetup.Editor_Help_Flyout.header = $hashsetup.Import_Youtube_Auth_Toggle.content
        update-EditorHelp -content "Enabling this will attempt to import cookies from the default profile of the browser you specify"
        update-EditorHelp -content "IMPORTANT: For this to work, you must first login to youtube with your Google account with the browser you specify, then enable this and select the name of the browser" -FontWeight bold -color orange
        #update-EditorHelp -content "TIP: When enabling, you will be prompted to provide your Ubisoft account username and password. These will be stored securely within the Windows Credential Manager. You can remove or change them there at any time" -FontWeight bold -color cyan   
      }catch{
        write-ezlogs "An exception occurred when opening main UI window" -CatchError $_ -enablelogs
      }

  })  
     
  $hashsetup.Youtube_Playlists_Browse.add_click({  
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($hashsetup.Window,"Add New Playlist","Enter the url of the Youtube Playlist",$button_settings)
      if(-not [string]::IsNullOrEmpty($result)){
        if(Test-URL $result){
          if($hashsetup.YoutubePlaylists_Grid.items.path -notcontains $result){
            write-ezlogs "Adding selected folder/path $result" -showtime
            Update-YoutubePlaylists -hashsetup $hashsetup -Path $result -VerboseLog
          }else{
            write-ezlogs "The location $result has already been added!" -showtime -warning
          } 
        }else{
          write-ezlogs "The location $result is not a valid URL!" -showtime -warning
        }
      }else{
        write-ezlogs "No URL was provided!" -showtime -warning
      } 
  })      
  #---------------------------------------------- 
  #endregion Get Youtube Media
  #----------------------------------------------  
       
  $hashsetup.Media_Path_Browse.add_click({
      if(($hashsetup.MediaLocations_Grid.items.path | select -last 1)){
        $initialdirectory = ($hashsetup.MediaLocations_Grid.items.path | select -last 1)
      }else{
        $initialdirectory = "file:"
      }      
      [array]$file_browse_Path = Open-FolderDialog -Title "Select the folder from which media will be imported" -InitialDirectory $initialdirectory -MultiSelect
      #$file_browse_Path = $file_browse_Path -join ","
      if(-not [string]::IsNullOrEmpty($file_browse_Path)){
        foreach($path in $file_browse_Path){
          if($hashsetup.MediaLocations_Grid.items.path -notcontains $file_browse_Path){
            #write-ezlogs "Adding selected folder/path $path" -showtime
            Update-MediaLocations -hashsetup $hashsetup -Path $path -VerboseLog
          }else{
            write-ezlogs "The location $file_browse_Path has already been added!" -showtime -warning
          }                  
        }
      }
  }) 
          
  #---------------------------------------------- 
  #region Apply Settings Button
  #----------------------------------------------
  $hashsetup.Save_Setup_Button.add_Click({
      try{   
        $hashsetup.Save_setup_textblock.text = ""        
        if($hashsetup.Import_Local_Media_Toggle.isOn)
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $true -MemberType NoteProperty -Force
          $thisApp.Config.Media_Directories.clear()
          foreach($path in $hashsetup.MediaLocations_Grid.items){
            if([System.IO.Directory]::Exists($path.path)){
              if($thisApp.Config.Media_Directories -notcontains $path.path){
                write-ezlogs " | Adding new Local Media Directory $($path.path)" -showtime
                $null = $thisApp.Config.Media_Directories.add($path.path)
              }            
            }else{
              $hashsetup.Save_setup_textblock.text = "The provide local media path $($path.path) is invalid!"
              $hashsetup.Save_setup_textblock.foreground = "Orange"
              $hashsetup.Save_setup_textblock.FontSize = 14            
              write-ezlogs "The provide local media path $($path.path) is invalid!" -showtime -warning              
              return
            } 
          }
        }
        else
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Local_Media" -Value $false -MemberType NoteProperty -Force
        }
        if($hashsetup.Import_Youtube_Playlists_Toggle.isOn)
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $true -MemberType NoteProperty -Force
          if($hashsetup.Import_Youtube_Auth_ComboBox.Selectedindex -ne -1){
            Add-Member -InputObject $thisApp.config -Name "Youtube_Browser" -Value $hashsetup.Import_Youtube_Auth_ComboBox.Selecteditem.Content -MemberType NoteProperty -Force
          }else{
            Add-Member -InputObject $thisApp.config -Name "Youtube_Browser" -Value $null -MemberType NoteProperty -Force
          }                    
          $thisApp.Config.Youtube_Playlists.clear()
          foreach($playlist in $hashsetup.YoutubePlaylists_Grid.items){
            if(Test-URL $playlist.path){
              if($thisApp.Config.Youtube_Playlists -notcontains $playlist.path){
                write-ezlogs " | Adding new Youtube Playlist $($playlist.path)" -showtime
                $null = $thisApp.Config.Youtube_Playlists.add($playlist.path)
              }            
            }else{
              $hashsetup.Save_setup_textblock.text = "The provided Youtube playlist URL $($playlist.path) is invalid!"
              $hashsetup.Save_setup_textblock.foreground = "Orange"
              $hashsetup.Save_setup_textblock.FontSize = 14            
              write-ezlogs "The provided Youtube playlist URL $($playlist.path) is invalid!" -showtime -warning
              return
            } 
          }
        }
        else
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Media" -Value $false -MemberType NoteProperty -Force
        }               
        if($hashsetup.Import_Spotify_Playlists_Toggle.isOn)
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $true -MemberType NoteProperty -Force
        }
        else
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Spotify_Media" -Value $false -MemberType NoteProperty -Force
        } 
        if($hashsetup.Import_Youtube_Auth_Toggle.isOn)
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $true -MemberType NoteProperty -Force
        }
        else
        {
          Add-Member -InputObject $thisApp.config -Name "Import_Youtube_Browser_Auth" -Value $false -MemberType NoteProperty -Force
        }              
        $thisApp.config | Export-Clixml -Path $thisApp.config.Config_Path -Force -Encoding UTF8
        if($First_Run -and ([System.IO.Directory]::Exists($thisApp.config.Playlist_Profile_Directory))){
          write-ezlogs " | Prompting user to decide whether to delete existing playlists for first run" -showtime -enablelogs -color cyan
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_settings.AffirmativeButtonText = "Yes"
          $Button_settings.NegativeButtonText = "No"  
          $hashsetup.Window.Dispatcher.invoke([action]{
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
              $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashsetup.Window,"Keep Playlists?","Existing Playlists profiles were found while running setup. Do you wish to keep these profiles?`nNOTE: If updating to a new version, there is a chance old profiles will no longer work properly, which is why its recommended to remove them. Additional options/abilities are planned to preserve playlists between versions",$okAndCancel,$button_settings)
              if($result -eq 'Affirmative'){
                write-ezlogs "User wished to keep existing playlist profiles" -showtime -warning
              }else{
                write-ezlogs " | Clearing playlist profile directory $($thisApp.config.Playlist_Profile_Directory)" -showtime 
                $null = Remove-item $thisApp.config.Playlist_Profile_Directory -Force -Recurse 
              }
          })
          
        }    
        if($Update){
          $hashsetup.Update_Media_Sources = $true
        }             
        Close-FirstRun 
                         
      }catch{
        $hashsetup.Save_setup_textblock.text = "An exception occurred when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
        $hashsetup.Save_setup_textblock.foreground = "Tomato"
        $hashsetup.Save_setup_textblock.FontSize = 14
        write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime -enablelogs
      }
  })
  #---------------------------------------------- 
  #endregion Apply Settings Button
  #---------------------------------------------- 
  
  #---------------------------------------------- 
  #region Cancel Button
  #----------------------------------------------
  $hashsetup.Cancel_Setup_Button.add_Click({
      try{          
        write-ezlogs ">>>> User choose to cancel first run setup...exiting" -showtime -enablelogs  
        Close-FirstRun
        [GC]::Collect() 
        if($First_Run){
          Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs          
          Stop-Process $pid 
          exit 
        }else{
          $hashsetup.Update_Media_Sources = $false
        }                                   
      }catch{
        $hashsetup.Save_setup_textblock.text = "An exception occurred when saving setup settings -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
        $hashsetup.Save_setup_textblock.foreground = "Tomato"
        $hashsetup.Save_setup_textblock.FontSize = 14
        write-ezlogs "An exception occurred when when saving setup settings" -CatchError $_ -showtime -enablelogs
        if($First_Run){
          exit
        }else{
          $hashsetup.Update_Media_Sources = $false
        }                
      }
  })
  #---------------------------------------------- 
  #endregion Cancel Button
  #----------------------------------------------   
  $hashsetup.Window.Add_Closed({     
      param($Sender)    
      if($sender -eq $hashsetup.Window){        
        try{
          write-ezlogs "Show-Firstrun Closed" -showtime
          $hashsetup = $Null      
        }catch{
          write-ezlogs "An exception occurred closing Show-Firstrun window" -showtime -catcherror $_
          return
        }
      }
  }.GetNewClosure())    

  [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashsetup.Window)
  [void][System.Windows.Forms.Application]::EnableVisualStyles()   
  try{

    $null = $hashsetup.window.Showdialog()
    $window_active = $hashsetup.Window.Activate() 
    #$hashsetupContext = New-Object System.Windows.Forms.ApplicationContext 
    #[void][System.Windows.Forms.Application]::Run($hashsetupContext)          
  }catch{
    write-ezlogs "An exception occurred when opening main Show-Firstrun window" -showtime -CatchError $_
  }   
}
#---------------------------------------------- 
#endregion Show-FirstRun Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-FirstRun','Close-FirstRun')




  