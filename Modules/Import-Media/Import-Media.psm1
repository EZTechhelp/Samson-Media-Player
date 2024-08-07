<#
    .Name
    Import-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Media Profiles

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
#region Import-Media Function
#----------------------------------------------
function Import-Media
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    [string]$Media_Path,
    $Media_directories,
    [string]$Media_Profile_Directory,
    [switch]$Refresh_All_Media,
    [switch]$NoMediaLibrary,
    [switch]$StartPlayback,
    $thisApp,
    $ImportMode = $thisapp.config.LocalMedia_ImportMode,
    [switch]$AddNewOnly,
    [switch]$SkipGetMedia,
    $Import_Cache_Profile = $startup,
    [switch]$use_runspace,
    [switch]$RestrictedRunspace,
    [switch]$VerboseLog = $thisApp.config.Verbose_logging
  )
  
  #$all_local_media = [hashtable]::Synchronized(@{})
  
  if($Startup){
    $Refresh_All_Media = $true
  }  
  $import_LocalMedia_scriptblock = {
    param (
      [switch]$Clear,
      [switch]$Startup,
      $synchash,
      [string]$Media_Path,
      $Media_directories,
      [string]$Media_Profile_Directory,
      [switch]$Refresh_All_Media,
      [switch]$NoMediaLibrary,
      [switch]$StartPlayback,
      $thisApp,
      $ImportMode = $thisapp.config.LocalMedia_ImportMode,
      [switch]$AddNewOnly,
      [switch]$SkipGetMedia,
      $Import_Cache_Profile = $startup,
      [switch]$use_runspace,
      [switch]$RestrictedRunspace,
      [switch]$VerboseLog = $thisApp.config.Verbose_logging
    )
    try{
      $get_LocalMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
      if($RestrictedRunspace){
        Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
        Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
      }
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-LocalMedia\Get-LocalMedia.psm1" -NoClobber -DisableNameChecking -Scope Local
      $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $true
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $false         
    }catch{
      write-ezlogs "An exception occurred updating LocalMedia_Progress_Ring" -showtime -catcherror $_
    }
    try{
      if($Media_Path){       
        if($Media_Path -match ','){
          write-ezlogs ">>> Getting local media from paths $Media_Path" -showtime -color cyan -logtype LocalMedia -LogLevel 2
          [array]$Media_Paths = $Media_Path -split ','
        }elseif(@($Media_Path).count -gt 1){
          [array]$Media_Paths = $Media_Path
          write-ezlogs ">>> Getting local media from paths $($Media_Paths)" -showtime -color cyan -logtype LocalMedia -LogLevel 2
        }else{
          if([System.IO.File]::Exists($Media_Path)){ 
            try{
              if(([System.IO.FileInfo]::new($Media_Path) | Where-Object{$_.Extension -match $media_pattern})){
                $media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_URL $Media_Path
                $directory = [system.io.path]::GetDirectoryName($Media_Path)
                $PathRoot = [system.io.path]::GetPathRoot($Media_Path)
                $PathSegments = [uri]::new($($Media_Path)).segments
                $SourceDirectory = $thisApp.Config.Media_Directories.where({$PathSegments -contains [uri]::new($($_)).AbsolutePath})
                if(!$SourceDirectory -and $thisApp.Config.Media_Directories -contains $PathRoot){
                  $sourceDirectory = $PathRoot
                }elseif(!$SourceDirectory){
                  $sourceDirectory = $directory
                }
                if($media.id){
                  write-ezlogs ">>>> Media profile already exists -- Title: $($media.title) -- ID: $($media.id) -- URL: $($media.url)" -showtime -logtype LocalMedia -warning
                  $PathToAdd = $Null
                }else{
                  write-ezlogs ">>>> Adding new local media file $Media_Path" -showtime -color cyan -logtype LocalMedia -LogLevel 2
                  $file = Find-FilesFast -Path $Media_Path   
                  Add-LocalMedia -synchash $synchash -thisApp $thisApp -Media $file -ImportMode 'Normal' -Directory $sourceDirectory -update_Library                
                }                               
                if($StartPlayback){
                  try{
                    if(!$media){                                                                  
                      $songinfo = Get-SongInfo -path $Media_Path
                      $type = [system.io.path]::GetExtension($Media_Path).replace('.','')
                      $name = [system.io.path]::GetFileNameWithoutExtension($Media_Path)
                      #$ParentFolderName = [system.io.directory]::GetParent($Media_Path).name
                      if($file.ShortName){
                        $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($file.ShortName)-$($file.Size)")
                      }else{
                        $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Media_Path)")
                      } 
                      $encodedTitle = [System.Convert]::ToBase64String($encodedBytes) 
                      if($songinfo -and !$songinfo.Artist -and $directory){
                        $songinfo.Artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($directory))).trim()  
                      }elseif($songinfo.Artist){
                        $songinfo.Artist = $(Get-Culture).TextInfo.ToTitleCase($songinfo.Artist).trim() 
                      }
                      if($Songinfo.Artist){
                        $artist = $Songinfo.Artist
                        $artist = (Get-Culture).TextInfo.ToTitleCase($artist).trim()          
                      }elseif([System.IO.Directory]::Exists($directory)){                   
                        write-ezlogs "| Generating Artist name based on media directory $($directory) for $name" -showtime
                        if(([System.IO.DirectoryInfo]::new($directory).parent)){
                          $artist = ([System.IO.Path]::GetFileNameWithoutExtension($directory))
                          $artist = (Get-Culture).TextInfo.ToTitleCase($artist).trim()   
                        }else{
                          $artist = $directory
                        }                         
                      }
                      if($Songinfo.title){
                        $Media_title = $Songinfo.title
                      }elseif($name){
                        $Media_title = $name
                      }
                      if($songinfo.duration_ms){
                        $duration = $songinfo.duration_ms
                        #$duration_ms = $songinfo.duration_ms
                      }elseif($songinfo.duration){
                        $duration = $songinfo.duration
                        #$duration_ms = $Null
                      }else{
                        $duration = $Null
                      }
                      if($duration){
                        try{
                          $Timespan = [timespan]::Parse($duration)
                          if($Timespan){
                            $duration = "$(([string]$timespan.hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
                          }                
                        }catch{
                          write-ezlogs "[Import-Media] An exception occurred parsing timespan for duration $duration" -showtime -catcherror $_
                        }                
                      }
                      if(-not [string]::IsNullOrEmpty($Songinfo.Length) -and $Songinfo.Length -gt 0){
                        $Size = $Songinfo.Length
                      }
                      $Subtitles_file = ([system.io.path]::Combine($directory,"$([system.io.path]::GetFileNameWithoutExtension($name)).srt"))
                      if([system.io.file]::Exists($Subtitles_file)){
                        $Subtitles_Path = $Subtitles_file
                      }else{
                        $Subtitles_Path = $null
                      }
                      $media = [Media]@{
                        'title' = [string]$Media_title
                        'Artist' = [string]$artist
                        'Track' = [int]$Songinfo.tracknumber
                        'Album' = [string]$songinfo.album
                        'Bitrate' = $songinfo.bitrate
                        'id' = [string]$encodedTitle
                        'url' = ($Media_Path -replace '\\\\','\')
                        'type' = [string]$type
                        'Duration' = $duration
                        'Size' = $Size
                        'directory' = [string]$directory
                        'SourceDirectory' = [string]$sourceDirectory
                        'Current_Progress_Secs' = ''
                        'Subtitles_Path' = [string]$Subtitles_Path
                        'hasVideo' = $songinfo.hasVideo
                        'PictureData' = ($songinfo.PictureData -eq $true)
                        'Profile_Date_Added' = [DateTime]::Now.ToString()
                        'Source' = 'Local'
                      } 
                    }    
                    $synchash.Temporary_Playback_Media = $media
                    Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Startup
                  }catch{
                    write-ezlogs "An exception occurred attempting to start playback for media $Media_Path"
                  }
                }
                #if(!$PathToAdd){
                #  return
                #}
              }else{
                $PathToAdd = $Null
                write-ezlogs "Provided File ($Media_Path) is not a valid media type" -showtime -warning -logtype LocalMedia -LogLevel 2
              }
            }catch{
              write-ezlogs "An exception occurred importing new media path: $Media_Path" -catcherror $_
            }finally{
              if($synchash.Refresh_LocalMedia_timer){
                $synchash.Refresh_LocalMedia_timer.tag = 'Update-LocalMedia'
                $synchash.Refresh_LocalMedia_timer.start()  
              }
            }
            return
          }elseif([System.IO.Directory]::Exists($Media_Path)){   
            $Unique_Paths = $Media_Path | Where-Object {($synchash.All_local_Media.SourceDirectory.indexof($_)) -eq -1} | Select-Object -Unique
            if(!$Unique_Paths){
              write-ezlogs "The path: '$Media_Path' has already been added to the media library!" -warning -AlertUI
              if($synchash.Refresh_LocalMedia_timer){
                $synchash.Refresh_LocalMedia_timer.tag = 'Update-LocalMedia'  
                $synchash.Refresh_LocalMedia_timer.start()  
              }
              return
            }elseif(([System.IO.Directory]::EnumerateFiles($Media_Path, '*', 'AllDirectories') | Where-Object { $_ -match $media_pattern } | Select-Object -First 1)){
              write-ezlogs ">>> Adding new local media directory $Media_Path" -showtime -color cyan -logtype LocalMedia -LogLevel 2
              $PathToAdd = $Media_Path
            }else{
              $PathToAdd = $Null
              write-ezlogs "Unable to find any supported media in Directory $Media_Path" -showtime -warning -logtype LocalMedia -LogLevel 2
            }
          }else{
            write-ezlogs "Provided Directory path ($Media_Path) is not a valid media type" -showtime -warning -logtype LocalMedia -LogLevel 2
          }
        }
        if($PathToAdd){          
          Get-LocalMedia -Media_Path $PathToAdd -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -Refresh_All_Media -synchash $synchash -AddNewOnly:$AddNewOnly -ImportMode $ImportMode
        }elseif($Media_Paths){
          Get-LocalMedia -Media_directories $Media_Paths -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -Refresh_All_Media -synchash $synchash -AddNewOnly:$AddNewOnly -ImportMode $ImportMode    
        }else{
          Update-Notifications -Level 'WARNING' -Message "No valid media was found at path $Media_Path" -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -Open_Flyout
          if($synchash.Window.isVisible){
            $Null = $synchash.Window.Dispatcher.InvokeAsync{
              $synchash.Window.Activate()
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"No Media Found!","No valid media was found at the provided local path: $Media_Path",$okandCancel,$Button_Settings)            
            }.Wait()            
          }
          return
        }
      }elseif(!$SkipGetMedia -or !$synchash.All_local_media){
        Get-LocalMedia -Media_directories $Media_directories -Media_Profile_Directory $Media_Profile_Directory -Import_Profile:$Import_Cache_Profile -Export_Profile -Verboselog:$VerboseLog -thisApp $thisApp -startup -Refresh_All_Media:$Refresh_All_Media -synchash $synchash -AddNewOnly:$AddNewOnly -ImportMode $ImportMode               
      }
      if($synchash.All_local_Media.count -eq 0 -or $NoMediaLibrary){
        try{
          write-ezlogs "[Import-Media] All_local_Media was empty!" -showtime -warning -logtype LocalMedia
          $All_LocalMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml') 
          if([System.IO.File]::Exists($All_LocalMedia_Profile_File_Path)){
            write-ezlogs "[Import-Media] Removing empty All-Media-Profile profile at $All_LocalMedia_Profile_File_Path" -showtime -warning -logtype LocalMedia
            [void][System.IO.File]::Delete($All_LocalMedia_Profile_File_Path)
          } 
        }catch{
          write-ezlogs "An exception occurred sorting all_local_Media" -catcherror $_
        }
      }  
      if($thisApp.Config.Dev_mode){write-ezlogs " | Starting LocalMedia_TableStartup_timer" -showtime -color cyan -logtype LocalMedia -Dev_mode}
      if($get_LocalMedia_Measure){
        $get_LocalMedia_Measure.stop()
        write-ezlogs "Get-LocalMedia Total Startup" -PerfTimer $Get_LocalMedia_Measure -GetMemoryUsage #-forceCollection
        $get_LocalMedia_Measure = $Null
      }
      if($synchash.LocalMedia_TableStartup_timer){
        $synchash.LocalMedia_TableStartup_timer.tag = $Startup
        $synchash.LocalMedia_TableStartup_timer.start() 
      }                                
      if($error){
        write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
        $error.clear()
      }
    }catch{
      write-ezlogs 'An exception occurred in import_LocalMedia_scriptblock' -showtime -catcherror $_ -AlertUI
      $Controls_to_Update = [System.Collections.Generic.List[Object]]::new(4)             
      $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
            'Control' = 'LocalMedia_Progress_Ring'
            'Property' = 'isActive'
            'Value' = $false
      }))            
      $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
            'Control' = 'Mediatable'
            'Property' = 'isEnabled'
            'Value' = $true
      }))         
      $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
            'Control' = 'LocalMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' = 'Hidden'
      }))        
      $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
            'Control' =  'MediaTable'
            'Property' = 'isEnabled'
            'Value' =  $true
      }))
      Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      $Controls_to_Update = $Null
    }
  }
  Start-Runspace -scriptblock $import_LocalMedia_scriptblock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name 'import_LocalMedia_scriptblock' -thisApp $thisApp -synchash $synchash -RestrictedRunspace:$RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
  $import_LocalMedia_scriptblock = $Null
}
#---------------------------------------------- 
#endregion Import-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Media')