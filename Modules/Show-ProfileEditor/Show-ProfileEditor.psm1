<#
    .Name
    Show-ProfileEditor 

    .Version 
    0.1.0

    .SYNOPSIS
    Displays a window for editing game profiles  

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
Add-Type -AssemblyName WindowsFormsIntegration


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
#region Close-ProfileEditor Function
#----------------------------------------------
function Close-ProfileEditor (){
  $hashedit.window.Dispatcher.Invoke("Normal",[action]{ $hashedit.window.close() })
    
}
#---------------------------------------------- 
#endregion Close-ProfileEditor Function
#----------------------------------------------

#---------------------------------------------- 
#region update-EditorHelp Function
#----------------------------------------------
function update-EditorHelp
{    
  param (
    [string]$content,
    [string]$color = 'White',
    [string]$FontWeight = 'Normal',
    $hashedit,
    [string]$FontSize = 14,
    [string]$BackGroundColor = "Transparent",
    [string]$TextDecorations,
    [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
    [switch]$AppendContent,
    [switch]$MultiSelect,
    [System.Windows.Controls.RichTextBox]$RichTextBoxControl = $hashedit.EditorHelpFlyout
  ) 
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
#endregion update-EditorHelp Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-ProfileEditor Function
#----------------------------------------------
function Show-ProfileEditor{
  Param (
    [string]$PageTitle,
    [string]$Splash_More_Info,
    [string]$Logo,
    $thisScript,
    $synchash,
    $thisApp,
    $Media_to_edit,
    [switch]$Verboselog,
    [string]$SplashMessage
  )    
  $hashedit_Scriptblock = {
    $global:hashedit = [hashtable]::Synchronized(@{}) 
    $thisApp = $thisApp
    $hashedit.PageTitle = $PageTitle
    $Logo = $Logo
    $Media_to_edit = $Media_to_edit
    $Current_Folder = $thisApp.Config.Current_Folder
    if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> Loading Profile Editor: $($Current_Folder)\\Views\\ProfileEditor.xaml" -showtime -enablelogs -Color cyan}  
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
    $pattern = "[™$illegal]"
    $pattern2 = "[:$illegal]"
    $pattern3 = "[`?�™$illegal]"
    $Nav_Window_XML = "$($Current_Folder)\\Views\\ProfileEditor.xaml"
  
    #import xml
    [xml]$xaml = [System.IO.File]::ReadAllText($Nav_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
    $Childreader = (New-Object System.Xml.XmlNodeReader $xaml)
    $hashedit.Window  = [Windows.Markup.XamlReader]::Load($Childreader)  
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {   
      if(!$hashedit."$($_.Name)"){$hashedit."$($_.Name)" = $hashedit.Window.FindName($_.Name)}
    }  
      
    #$hashnav.Logo.Source=$Logo
    $hashedit.Window.title = $hashedit.PageTitle
    $hashedit.Window.icon = $Logo 
    $hashedit.Window.icon.Freeze()  
    $hashedit.Window.IsWindowDraggable="True"
    $hashedit.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
    $hashedit.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
    $hashedit.Window.ShowTitleBar=$true
    $hashedit.Window.UseNoneWindowStyle = $false
    $hashedit.Window.WindowStyle = 'none'
    $hashedit.Window.IgnoreTaskbarOnMaximize = $true  
    $hashedit.Title_menu_Image.Source = $Logo
    $hashedit.Title_menu_Image.width = "18"  
    $hashedit.Title_menu_Image.Height = "18"  
    $hashedit.EditorHelpFlyout.Document.Blocks.Clear()

    if([System.IO.File]::Exists($Media_to_edit.profile_path)){
      write-ezlogs ">>>> Importing all media profile: $($Media_to_edit.profile_path)" -enablelogs -showtime
      
      $All_Media_Profile = Import-Clixml $Media_to_edit.profile_path   
      if($Media_to_edit.Source -eq 'Local'){         
        $profile = $All_Media_Profile | where {$_.id -eq $media_to_edit.id}
        write-ezlogs "| Profile: $($profile | out-string)" -enablelogs -showtime
        if($profile.title){
          $title = $profile.title 
        }elseif($profile.SongInfo.title){
          $title = $profile.SongInfo.title 
        }elseif($profile.name){
          $title = $profile.name
        }      
        write-ezlogs "| Loading local Media profile for $($title) - $($profile.id) into editor" -showtime                    
      }      
      if($Media_to_edit.Spotify_path -or $Media_to_edit.Source -eq 'SpotifyPlaylist'){  
        $profile = ($All_Media_Profile.PlayList_tracks | where {$_.id -eq $media_to_edit.id})
        write-ezlogs "| Profile: $($profile | out-string)" -enablelogs -showtime
        if($profile.title){
          $title = $profile.title
        }else{
          $title = $profile.name
        }      
        write-ezlogs "| Loading Spotify profile for $($title) - $($profile.id) into editor" -showtime                        
      }         
      if($Media_to_edit.Source -eq 'YoutubePlaylist_item'){          
        $profile = ($All_Media_Profile.playlist_tracks | where {$_.id -eq $media_to_edit.id})
        write-ezlogs "| Profile: $($profile | out-string)" -enablelogs -showtime
        $title = $profile.title
        write-ezlogs "| Loading Youtube profile for $($title) - $($profile.id) into editor" -showtime                       
      }    
      
      <#      if($backimage){
          #Check Image Cache
          $uri = new-object system.uri($backimage)
          $image_cache_dir = [System.IO.Path]::Combine($thisScript.TempFolder,"Images")
          if(!(Test-Path $image_cache_dir -PathType Container)){
          $null = New-item $image_cache_dir -ItemType directory -Force
          }
          $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,($backimage | split-path -Leaf))
          if(!(Test-Path $image_Cache_path -PathType Leaf)){
          (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path)
          if($verboselog){write-ezlogs " | Caching image $uri to $image_Cache_path" -enablelogs}
          $backimage = $image_Cache_path
          }
          if($VerboseLog){ write-ezlogs " | Using cached file for profile editor: $backimage" -showtime -enablelogs -color Magenta}
          $backimage = $image_Cache_path
          $stream_image = [System.IO.File]::OpenRead($backimage)               
          #$image = new-object System.Windows.Media.Imaging.BitmapImage
          #$image.BeginInit();
          #$image.CacheOption = "OnLoad"
          #$image.DecodePixelHeight = 650;
          #$image.DecodePixelWidth = 364;
          #$image.UriSource = $backimage;
          #$image.StreamSource = $stream_image 
          #$image.EndInit();
          #$imagecontrol.RenderOptions.SetBitmapScalingMode($this,"Fant")        
          #$hashnav.Editor_Background_Image.Source=$image
          #$hashnav.Editor_Background_Image.Stretch = "UniformToFill"      
          $image = new-object System.Windows.Media.Imaging.BitmapImage
          $image.BeginInit();
          $image.CacheOption = "OnLoad"
          #$image.CreateOptions = "DelayCreation"
          $image.DecodePixelHeight = 780;
          $image.DecodePixelWidth = 780;
          $image.StreamSource = $stream_image 
          $image.EndInit();         
          $hashnav.Background_Image.Source=$image
          $hashnav.Background_Image.Stretch = "UniformtoFill"
          $hashnav.Background_Image.Opacity = 0.3 
          $stream_image.Close()
          $stream_image.Dispose()         
      }#>
        
      #Media Title    
      $hashedit.PageHeader.text = $title
      $hashedit.Media_title_textbox.text = $title
      if($hashedit.Media_title_textbox.text){
        $hashedit.Media_title_Label.BorderBrush = "Green"
      }else{
        $hashedit.Media_title_textbox.text = ""
        $hashedit.Media_title_Label.BorderBrush = "Red"
      }   
    
    
      #Media Artist
      if($profile.Artist){
        $Artist = $profile.Artist
      }elseif($profile.SongInfo.Artist){
        $Artist = $profile.SongInfo.Artist
      }
      $hashedit.Media_Artist_textbox.text = $Artist     
      if($hashedit.Media_Artist_textbox.text){     
        $hashedit.Media_Artist_Label.BorderBrush = "Green"
      }else{
        $hashedit.Media_Artist_textbox.text = ""
        $hashedit.Media_Artist_Label.BorderBrush = "Red"
      }  
    
      #Media Album
      if($profile.Album){
        $Album = $profile.Album
      }elseif($profile.SongInfo.Album){
        $Album = $profile.SongInfo.Album
      }
      $hashedit.Media_Album_textbox.text = $Album     
      if($hashedit.Media_Album_textbox.text){     
        $hashedit.Media_Album_Label.BorderBrush = "Green"
      }else{
        $hashedit.Media_Album_textbox.text = ""
        $hashedit.Media_Album_Label.BorderBrush = "Red"
      }    
                                                          
      if($profile.type -eq 'Available'){ 
        $hashedit.Media_Type_ComboBox.selectedindex = 1
        $hashedit.Media_Type_Label.BorderBrush = "Green"
        write-ezlogs "Selected after: $($hashedit.Media_Type_ComboBox.selecteditem.content)" -showtime
      }elseif($profile.type -match 'Installed'){   
        write-ezlogs "Selected before: $($hashedit.Media_Type_ComboBox.selecteditem.content)" -showtime
        $hashedit.Media_Type_ComboBox.selectedindex = 0
        write-ezlogs "Selected after: $($hashedit.Media_Type_ComboBox.selecteditem.content)" -showtime
        $hashedit.Media_Type_Label.BorderBrush = "Green"
      }
      else{
        $hashedit.Media_Type_Label.BorderBrush = "Red"
        $hashedit.Media_Type_ComboBox.selectedindex = -1
      } 
                               
      <#    $synchash.Launch_Command_textbox.Add_TextChanged({
          if($synchash.Launch_Command_textbox.text -eq "")
          {
          $synchash.Launch_Command_Label.BorderBrush = "Red"
          }       
          else
          {
          $synchash.Launch_Command_Label.BorderBrush = "Green"
          }
      })#>      
    }else{ 
      write-ezlogs "A valid profile to edit was not provided or found $($Media_to_edit.profile_path)" -showtime -warning
    
    }      
    <#  $synchash.Save_Path_Browse.add_click({
        [array]$save_browse_Path = Open-FolderDialog -Title "Select the folder where save files are located for this game" -InitialDirectory $synchash.Save_Path_textbox.text -ShowFiles
        $save_browse_Path = $save_browse_Path -join ","
        if(-not [string]::IsNullOrEmpty($save_browse_Path)){
        $synchash.save_Path_textbox.text = $save_browse_Path
        }
    }.GetNewClosure())#>
    <#  $synchash.Backup_Options_ComboBox.add_SelectionChanged({
        if($synchash.Backup_Options_ComboBox.selectedindex -eq -1)
        {
        $synchash.Backup_Options_Label.BorderBrush = "Red"
        }       
        else
        {
        $synchash.Backup_Options_Label.BorderBrush = "Green"
        }      
    }.GetNewClosure()) #>                                
                   
    <#  $synchash.HDR_On_Start_Button.add_click({
        $synchash.EditorHelpFlyout.Document.Blocks.Clear()
        $synchash.Editor_Help_Flyout.isOpen = $true
        $synchash.Editor_Help_Flyout.header = $synchash.HDR_On_Start_Toggle.content
        update-EditorHelp -synchash $synchash -content "Enabling this will force Windows HDR to be enabled for this game when launched from this app. If Windows HDR is already enabled on game start, it wont be changed. Once the game is closed, Windows HDR will be disabled again. Obviously this feature requires your system be HDR compatible"
        update-EditorHelp -synchash $synchash -content "IMPORTANT: This setting can be overrided if the setting `"Always Enable HDR`" is enabled in the main app" -FontWeight bold -color orange
        update-EditorHelp -synchash $synchash -content "TIP: This works best when also enabling game monitoring. If game monitoring is not used, the app can still toggle HDR on game start, but after that it wont know when the game ends so HDR wont be turned off" -FontWeight bold -color cyan
    }.GetNewClosure()) #>   
                        
    #---------------------------------------------- 
    #region Apply Settings Button
    #----------------------------------------------
    $hashedit.Save_Profile_Button.add_Click({
        try{  
          if($Media_to_edit.Source -eq 'Local'){
            $datarow_toupdate = $Datatable.datatable | where {$_.id -eq $Media_to_edit.id}
          }elseif($Media_to_edit.Spotify_path -or $Media_to_edit.Source -eq 'SpotifyPlaylist'){
            $datarow_toupdate = $Spotify_Datatable.datatable | where {$_.id -eq $Media_to_edit.id}
          }elseif($Media_to_edit.Source -eq 'YoutubePlaylist_item'){
            $datarow_toupdate = $Youtube_Datatable.datatable | where {$_.id -eq $Media_to_edit.id}          
          }  
          
          
          #Title        
          if(-not [string]::IsNullOrEmpty($hashedit.Media_title_textbox.text)){
            if($profile.SongInfo.title){
              $profile.SongInfo.title = $hashedit.Media_title_textbox.text
            }
            if($Media_to_edit.SongInfo.title){
              $Media_to_edit.SongInfo.title = $hashedit.Media_title_textbox.text
            }                       
            Add-Member -InputObject $profile -Name "title" -Value $hashedit.Media_title_textbox.text -MemberType NoteProperty -Force 
            Add-Member -InputObject $Media_to_edit -Name "title" -Value $hashedit.Media_title_textbox.text -MemberType NoteProperty -Force
            Add-Member -InputObject $profile -Name "name" -Value $hashedit.Media_title_textbox.text -MemberType NoteProperty -Force           
            if($datarow_toupdate){
              $datarow_toupdate.title = $hashedit.Media_title_textbox.text
            }
          }         
          #Artist        
          if(-not [string]::IsNullOrEmpty($hashedit.Media_Artist_textbox.text)){
            if($profile.SongInfo.Artist){
              $profile.SongInfo.Artist = $hashedit.Media_Artist_textbox.text
            }
            if($Media_to_edit.SongInfo.Artist){
              $Media_to_edit.SongInfo.Artist = $hashedit.Media_Artist_textbox.text
            }                       
            Add-Member -InputObject $profile -Name "Artist" -Value $hashedit.Media_Artist_textbox.text -MemberType NoteProperty -Force 
            Add-Member -InputObject $Media_to_edit -Name "Artist" -Value $hashedit.Media_Artist_textbox.text -MemberType NoteProperty -Force         
            if($datarow_toupdate){
              $datarow_toupdate.Artist = $hashedit.Media_Artist_textbox.text
            }
          }         
          Add-Member -InputObject $profile -Name "Profile_Date_Modified" -Value $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt') -MemberType NoteProperty -Force                                                      
          try{
            $All_Media_Profile | Export-Clixml -Path $Media_to_edit.profile_path -Force -Encoding UTF8
            write-ezlogs ">>>> Saving profile to $($Media_to_edit.profile_path)`n" -showtime -color cyan
          }catch{
            write-ezlogs "Exception Saving profile to $($Media_to_edit.profile_path)" -showtime -catcherror $_
          } 
          $synchash.Import_Playlists_Cache = $false
          Update-Playlist -media $profile -synchash $synchash -thisApp $thisApp -Updateall                  
          $synchash.update_status_timer.start()               
          if($Media_to_edit.Source -eq 'Local'){
            $synchash.LocalMediaFilter_timer.Start()
          }elseif($Media_to_edit.Spotify_path -or $Media_to_edit.Source -eq 'SpotifyPlaylist'){
            $synchash.SpotifyFilter_timer.start()
          }elseif($Media_to_edit.Source -eq 'YoutubePlaylist_item'){
            $synchash.YoutubeFilter_timer.start()        
          }                     
          $hashedit.Save_status_transitioningControl.content = ""
          $hashedit.Save_status_Label.content = "Saved Profile Successfully!"
          $hashedit.Save_status_Label.foreground = "LightGreen"
          $hashedit.Save_status_transitioningControl.content = $hashedit.Save_status_Label       
        }catch{
          $hashedit.Save_status_Label.content = "An exception occurred when saving the profile!`n$_"
          $hashedit.Save_status_Label.foreground = "Red"
          write-ezlogs "An exception occurred when saving the profile $($profile.profile_path)" -CatchError $_ -showtime
        }
    })
    #---------------------------------------------- 
    #endregion Apply Settings Button
    #----------------------------------------------      
    $hashedit.ProfileEditor.add_closed({     
        param($Sender)          
        try{  
          $hashedit.EditorHelpFlyout = $Null 
          $this = $Null          
        }catch{
          write-ezlogs "An exception occurred closing Show-ProfileEditor window" -showtime -catcherror $_
        }
        try{
          $synchash.window.Dispatcher.Invoke("Normal",[action]{ $window_active = $synchash.Window.Activate()  })         
        }catch{
          write-ezlogs "An exception occurred closing Show-ProfileEditor window" -showtime -catcherror $_
        }      
    }.GetNewClosure())   
  
    try{    
      [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashedit.Window)
      [void][System.Windows.Forms.Application]::EnableVisualStyles()   
      $null = $hashedit.Window.ShowDialog()
      $window_active = $hashedit.Window.Activate()          
    }catch{
      write-ezlogs "An exception in Show-ProfileEditor screen show dialog" -showtime -catcherror $_
    }
  }
  try{    
    $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"} 
    $ProfileEdit_RunSpace = Start-Runspace $hashedit_Scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name 'ProfileEditor_Runspace' -logfile $thisApp.Config.Log_File -verboselog:$thisApp.Config.Verbose_logging     
  }catch{
    write-ezlogs "An exception occurred starting ProfileEditor_Runspace" -showtime -catcherror $_
  }
}
Export-ModuleMember -Function @('Show-ProfileEditor','Close-ProfileEditor','update-EditorHelp')
#---------------------------------------------- 
#endregion Show-ProfileEditor Function
#----------------------------------------------


  