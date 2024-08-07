<#
    .Name
    Get-LocalMedia

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves all media files from local provided sources  

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
#region Get-Taglib Function
#----------------------------------------------
function Get-Taglib {
  [CmdletBinding()]
  Param (
    [string]$Path,
    [switch]$dev_mode
  )
  if($Path){
    try{ 
      $taginfo = [taglib.file]::create($Path)
      return $taginfo
    }catch{
      if($_ -match 'because it is being used by another process'){
        return 'Locked'
      }
    }finally{
      if($taginfo -is [System.IDisposable]){
        [void]$taginfo.Dispose()
        $taginfo = $null
      }
    }
  }else{
    write-ezlogs "Cannot get taglib metadata for invalid file path: $($path)" -warning -logtype LocalMedia
  }
}
#---------------------------------------------- 
#endregion Get-Taglib Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-SongInfo Function
#----------------------------------------------
function Get-SongInfo {
  [CmdletBinding()]
  Param (
    [string]$Path,
    [switch]$use_FFPROBE,
    [switch]$use_FFPROBE_Fallback,
    [switch]$dev_mode
  )
  if($Path){
    try{ 
      try{       
        $duration = $Null
        $taginfo = $Null
        $artist = $Null
        $title = $Null
        $ffprobe = $Null
        $Description = $null
        #$taginfo = [taglib.file]::create($Path,[TagLib.ReadStyle]::PictureLazy)
        if($thisApp.Config.Dev_mode -and $thisApp.config.Debug_mode){
          write-ezlogs ">>>> Getting Taginfo for file: $($Path)" -Dev_mode -logOnly -LogLevel 3
        }
        $taginfo = [taglib.file]::create($Path)
      }catch{
        if($_ -match 'because it is being used by another process'){
          write-ezlogs "Taglib error indicates file is currently open in another process" -showtime -warning -logtype LocalMedia
          $Retry = $true
        }else{
          write-ezlogs "An exception occurred getting taginfo for $Path - type $($path.gettype())" -showtime -catcherror $_
          $Retry = $false
        }
      }
      if($Retry){
        try{       
          $taginfo = $Null
          $waittimer = 0
          if($synchash.All_Tor_Results.State -match 'Started|Downloading'){
            write-ezlogs "Tor download is running, skipping Taglib retry as file likely locked for a long period" -warning -logtype LocalMedia
          }else{
            while((Get-Taglib -Path $Path -ErrorAction SilentlyContinue) -eq 'Locked' -and $waittimer -lt 30){
              $waittimer++
              write-ezlogs "| File locked....Waiting up to 30 seconds: $($waittimer)" -showtime -warning -logtype LocalMedia
              start-Sleep 1
            }
            if($waittimer -ge 30){
              write-ezlogs "Timed out waiting for file to unlock - moving on" -showtime -warning -logtype LocalMedia
            }else{
              $taginfo = Get-Taglib -Path $Path
            }
          }
        }catch{
          write-ezlogs "Retry of taglib failed for path: $Path -- moving on" -showtime -logtype LocalMedia
        }   
      }                   
      if(($taginfo.tag.IsEmpty -or !$taginfo)){
        if($use_FFPROBE_Fallback){
          if($thisApp.Config.Dev_mode){
            write-ezlogs "Attempting to fallback to ffprobe to get info about $($Path)" -warning -Dev_mode -LogLevel 3
          }
          try{
            $newProc = [System.Diagnostics.ProcessStartInfo]::new("$($thisApp.Config.Current_Folder)\Resources\flac\ffprobe.exe")
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "-hide_banner -loglevel quiet -show_error -select_streams v:0 -show_optional_fields always -show_entries format -print_format json `"$($Path)`""
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $newProc.RedirectStandardOutput = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
          }catch{
            write-ezlogs "An exception occurred executing ffprobe fallback method to get info about $($Path)" -catcherror $_
          }finally{
            if($Process.StandardOutput){
              $ffprobe = $Process.StandardOutput.ReadToEnd() | convertfrom-json
            }
            if($Process -is [System.IDisposable]){
              $Process.dispose()
            }
          }
          <#          try{
              $ffprobe = ffprobe -hide_banner -loglevel quiet -show_error -select_streams v:0 -show_optional_fields always -show_entries format -print_format json $Path | convertfrom-json
              }catch{
              write-ezlogs "An exception occurred executing ffprobe fallback method to get info about $($Path)" -catcherror $_ -ClearErrors
          } #>        
          try{
            if($ffprobe.format){
              if(-not [string]::IsNullOrEmpty($ffprobe.format.tags.ARTIST)){
                $artist = $ffprobe.format.tags.ARTIST
              }elseif(-not [string]::IsNullOrEmpty($ffprobe.format.tags.ACTOR)){
                $artist = $ffprobe.format.tags.ACTOR
              }else{
                $rootdir = [System.IO.directory]::GetParent($Path)
                $artist = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($rootdir))).trim()
                #$artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($rootdir))).trim() 
              }
              if(-not [string]::IsNullOrEmpty($ffprobe.format.tags.TITLE)){
                $title = $ffprobe.format.tags.TITLE
              }else{
                $title = ([System.IO.Path]::GetFileNameWithoutExtension($Path))
              }
              if(-not [string]::IsNullOrEmpty($ffprobe.format.duration)){
                $duration = [timespan]::FromSeconds($ffprobe.format.duration)
                if($thisApp.Config.Dev_mode -and $thisApp.config.Debug_mode){
                  write-ezlogs " | Found duration -- FFProbe: $($ffprobe.format.duration) -- Timespan: $($duration)" -Dev_mode -LogLevel 3
                }                
              }elseif($taginfo.properties.duration){
                if($thisApp.Config.Dev_mode -and $thisApp.config.Debug_mode){
                  write-ezlogs " | Found duration -- taginfo.properties: $($taginfo.properties.duration)" -Dev_mode -LogLevel 3
                }                
                $duration = $taginfo.properties.duration
              }
              if(-not [string]::IsNullOrEmpty($ffprobe.format.bit_rate)){         
                $bitrate = (Convert-Size -From Bytes -To KB -Value $ffprobe.format.bit_rate -Precision 2)
              }
              if(-not [string]::IsNullOrEmpty($ffprobe.format.tags.DESCRIPTION)){         
                $description = $ffprobe.format.tags.DESCRIPTION
              }
            }elseif($ffprobe.error){
              write-ezlogs "Unable to get info with ffprobe for media: $($path) -- FFPROBE ERROR: $($ffprobe.error.string)" -logtype LocalMedia -Warning
            }else{
              write-ezlogs "Unable to get info with ffprobe for media: $($path)" -logtype LocalMedia -Warning
            }
          }catch{
            write-ezlogs "An exception occurred processing ffprobe properties of media path: $($Path)" -catcherror $_ -ClearErrors
          }   
        }else{
          $title = ([System.IO.Path]::GetFileNameWithoutExtension($Path))
        }
      }else{ 
        if(-not [string]::IsNullOrEmpty($taginfo.tag.Artists)){
          $artist = $taginfo.tag.Artists -join '/'
        }elseif(-not [string]::IsNullOrEmpty($taginfo.tag.AlbumArtists)){
          $artist = $taginfo.tag.AlbumArtists -join '/'
        }elseif(-not [string]::IsNullOrEmpty($taginfo.tag.JoinedArtists)){
          $artist = $taginfo.tag.JoinedArtists
        }elseif(-not [string]::IsNullOrEmpty($taginfo.tag.FirstArtist)){
          $artist = $taginfo.tag.FirstArtist
        }elseif(-not [string]::IsNullOrEmpty($taginfo.tag.FirstAlbumArtist)){
          $artist = $taginfo.tag.FirstAlbumArtist
        }elseif(-not [string]::IsNullOrEmpty($taginfo.tag.FirstPerformer)){
          $artist = $taginfo.tag.FirstPerformer
        }     
        $title = $taginfo.tag.title
        $Description = $taginfo.tag.Description  
        $Length = $taginfo.FileAbstraction.ReadStream.Length
      }
      if(-not [string]::IsNullOrEmpty($artist)){
        $artist = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($artist.ToLower()).trim()
        #$artist = (Get-Culture).TextInfo.ToTitleCase($artist.ToLower()).trim() 
      }else{
        $artist = 'Unknown'
      }
      #TODO: Dont use parent folder as artist name by default - maybe as option
      <#      if(-not[string]::IsNullOrEmpty($artist)) {
          $rootdir = [System.IO.directory]::GetParent($Path)
          $artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($rootdir))).trim() 
      }#>
      if([string]::IsNullOrEmpty($title)) {
        $rootdir = [System.IO.directory]::GetParent($Path)
        $title = ([System.IO.Path]::GetFileNameWithoutExtension($Path))
      }
      if(-not [string]::IsNullOrEmpty($taginfo.properties.duration) -and [string]::IsNullOrEmpty($duration)){
        if($thisApp.Config.Dev_mode -and $thisApp.config.Debug_mode){
          write-ezlogs " | Found duration -- taginfo.properties: $($taginfo.properties.duration)" -Dev_mode -LogLevel 3 -logOnly
        }        
        $duration = $taginfo.properties.duration
      }  
      $hasVideo = if ($taginfo.properties.MediaTypes -match 'Video') { $true } else { $false }   
      if($use_FFPROBE -and !$ffprobe){
        try{
          $ffprobe = ffprobe -hide_banner -loglevel quiet -show_error -select_streams v:0 -show_optional_fields always -show_entries format -print_format json $Path | convertfrom-json 
        }catch{
          write-ezlogs "An exception occurred executing ffprobe for $path" -catcherror $_
        }
      }
      if((($taginfo.properties.audiobitrate -eq 0 -or [string]::IsNullOrEmpty($taginfo.properties.audiobitrate)) -and -not [string]::IsNullOrEmpty($ffprobe.format.bit_rate))){
        try{
          $bitrate = (Convert-Size -From Bytes -To KB -Value $ffprobe.format.bit_rate -Precision 2)
        }catch{
          write-ezlogs "An exception occurred executing convert-size for bitrate $($ffprobe.format.bit_rate)" -catcherror $_
        }
      }else{
        $bitrate = $taginfo.properties.audiobitrate
      } 
      if([string]::IsNullOrEmpty($Length)){
        $Length = [System.IO.FileInfo]::new($path).Length
      }
      $newObject = [PSCustomObject]::new(@{
          'Artist' = $artist
          'Title' = $title
          'Album' = $taginfo.tag.Album 
          'Year' = $taginfo.tag.Year
          'hasVideo' = $hasVideo
          'Comments' = $taginfo.tag.comment
          #'Chapters' = $ffprobe.chapters
          'Length' = $Length
          'Description' = $description
          'Duration' = $duration
          'PictureData' = (-not [string]::IsNullOrEmpty($taginfo.tag.pictures.Filename))
          'TrackNumber' = $taginfo.tag.track
          'Bitrate' = $bitrate
          'SampleRate' = $taginfo.properties.AudioSampleRate
          'BitsPerSample' = $taginfo.properties.BitsPerSample
      })
      $PSCmdlet.WriteObject($newobject)
      #return $newobject
    }catch{
      write-ezlogs "An exception occurred parsing info about file $Path" -showtime -catcherror $_
      [void]$error.clear()
    }finally{
      if($taginfo -is [System.IDisposable]){
        [void]$taginfo.Dispose()
        $taginfo = $null
      } 
    }
  }else{
    write-ezlogs "Cannot get taglib metadata for invalid file path: $($path)" -warning -logtype LocalMedia
  }
}
#---------------------------------------------- 
#endregion Get-SongInfo Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-SongInfo Function
#----------------------------------------------
function Set-SongInfo
{  Param (
    [string]$Path,
    [string]$Title,
    [string]$Artist,
    [string]$Album,
    [string]$Year,
    [string]$Description,
    [string]$Comment,
    [Int]$TrackNumber,
    [Int]$TrackCount,
    [Int]$Disc,
    [Int]$DiscCount,
    [string]$Image,
    [string]$Genres,
    [string]$Lyrics,
    [string]$Copyright,
    [string]$Subtitle,
    [string]$logtype = 'LocalMedia',
    [switch]$dev_mode
  )

  if($Path){
    try{ 
      try{       
        if($dev_mode -and $thisApp.config.Debug_mode){
          write-ezlogs ">>>> Getting Taginfo for file: $($Path)" -Dev_mode -logOnly -LogLevel 3 -logtype $logtype
        }        
        $taginfo = [taglib.file]::create($Path) 
      }catch{
        write-ezlogs "An exception occurred getting taginfo for $Path - type $($path.gettype())" -showtime -catcherror $_
        [void]$error.clear()
      }             
      if((!$taginfo)){
        write-ezlogs "Unable to get taginfo for file: $path -- Skipping" -warning -logtype $logtype
        return
      }else{  
        if(-not [string]::IsNullOrEmpty($artist)) {
          $taginfo.tag.Artists = $artist
        }    
        if(-not [string]::IsNullOrEmpty($title)) {
          $taginfo.tag.title = $title
        } 
        if(-not [string]::IsNullOrEmpty($Description)) {
          $taginfo.tag.Description = $Description
        }
        if(-not [string]::IsNullOrEmpty($Comment)) {
          $taginfo.tag.Comment = $Comment
        }
        if(-not [string]::IsNullOrEmpty($Album)) {
          $taginfo.tag.Album = $album
        } 
        if(-not [string]::IsNullOrEmpty($Year)){
          [System.Globalization.CultureInfo]$provider = [System.Globalization.CultureInfo]::InvariantCulture
          [System.DateTime]$parsedDate = [Datetime]::Now
          if([datetime]::TryParseExact($year,'yyyy',$provider,[System.Globalization.DateTimeStyles]::None,[ref]$parseddate)){
            $taginfo.tag.Year = $year
          }else{
            write-ezlogs "Unable to set year tag to: $year -- for file: $($path) -- Value is not valid year" -warning -logtype $logtype
          }
        }
        if(-not [string]::IsNullOrEmpty($TrackNumber)){
          $taginfo.tag.Track = $TrackNumber
        }
        if(-not [string]::IsNullOrEmpty($TrackCount)){
          $taginfo.tag.TrackCount = $TrackCount
        }          
        if([System.IO.File]::Exists($Image)){
          write-ezlogs " | Adding image to tag pictures: $Image" -logtype $logtype
          try{
            $picture = [TagLib.Picture]::CreateFromPath($Image)
            $taginfo.Tag.Pictures = $picture
          }catch{
            write-ezlogs "An exception occurred setting taglib image from image path $Image" -showtime -catcherror $_
          }
        } 
        if(-not [string]::IsNullOrEmpty($Genres)){
          $taginfo.tag.Genres = $Genres
        }   
        if(-not [string]::IsNullOrEmpty($Lyrics)){
          $taginfo.tag.Lyrics = $Lyrics
        } 
        if(-not [string]::IsNullOrEmpty($Copyright)){
          $taginfo.tag.Lyrics = $Copyright
        } 
        if(-not [string]::IsNullOrEmpty($Disc)){
          $taginfo.tag.Disc = $Disc
        } 
        if(-not [string]::IsNullOrEmpty($DiscCount)){
          $taginfo.tag.DiscCount = $DiscCount
        }
        if(-not [string]::IsNullOrEmpty($Subtitle)){
          $taginfo.tag.Subtitle = $Subtitle
        }  
        try{
          write-ezlogs ">>>> Saving new tag info: $($path)"
          [void]$taginfo.Save()
        }catch{
          write-ezlogs "An exception occurred saving tag info to file: $path" -showtime -catcherror $_
        }                                                                             
      }
      <#      $taginfo.tag.psobject.properties.name | foreach {
          if($_ -in $PSBoundParameters.keys){
          $value = $PSBoundParameters[$_]
          }
      }#>                     
    }catch{
      write-ezlogs "An exception occurred parsing info about file $Path" -showtime -catcherror $_
      [void]$error.clear()
    }finally{
      if($taginfo){
        [void]$taginfo.Dispose()
        $taginfo = $null
      } 
    }
  }else{
    write-ezlogs "Cannot get taglib metadata for invalid file path: $($path)" -warning -logtype $logtype
  }
}
#---------------------------------------------- 
#endregion Set-SongInfo Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-LocalMedia Function
#----------------------------------------------
function Get-LocalMedia
{
  Param (
    [string]$Media_Path,
    $Media_directories,
    [switch]$Import_Profile,
    $thisApp,
    $synchash,
    $all_installed_apps,
    [switch]$Refresh_All_Media = $true,
    [switch]$FastImporting,
    [string]$ImportMode,
    [switch]$AddNewOnly,
    [switch]$Startup,
    [switch]$Enablelinkedconnections,
    [switch]$update_global,
    [switch]$Export_Profile,
    [switch]$Export_AllMedia_Profile,
    [string]$Media_Profile_Directory,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog
  )
  write-ezlogs "#### Executing Get-LocalMedia ####" -linesbefore 1 -logtype LocalMedia
  $GetLocalMedia_stopwatch = [system.diagnostics.stopwatch]::StartNew() 
  Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
  $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
  if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
    try{
      [void][System.IO.Directory]::CreateDirectory($AllMedia_Profile_Directory_Path)
    }catch{
      write-ezlogs "[Get-LocalMedia] An exception occurred creating new directory at: $AllMedia_Profile_Directory_Path" -catcherror $_
    }   
  }
  $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
  #$ffmpeg_Path = "$($thisApp.config.Current_folder)\Resources\flac"
  #$envpaths2 = $env:path -split ';'
  <#  if($ffmpeg_Path -notin $envpaths2){
      if($thisApp.Config.Dev_mode){write-ezlogs "[Get-LocalMedia] >>>> Adding ffmpeg to user enviroment path $ffmpeg_Path" -Dev_mode}
      $env:path += ";$ffmpeg_Path"
      $envpaths = [Environment]::GetEnvironmentVariable('Path') -split ';'
      if($ffmpeg_Path -notin $envpaths){
      [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$ffmpeg_Path",[EnvironmentVariableTarget]::User)
      }
  }#>
  if($startup -and $Import_Profile -and ([System.IO.FIle]::Exists($AllMedia_Profile_File_Path))){ 
    if($thisApp.Config.Dev_mode){write-ezlogs "[Get-LocalMedia] | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -logtype LocalMedia -Dev_mode}
    try{
      $synchash.All_local_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path 
    }catch{
      write-ezlogs "[Get-LocalMedia] An exception occurred importing local media profile at: $AllMedia_Profile_File_Path" -catcherror $_
    } 
    if($GetLocalMedia_stopwatch){
      $GetLocalMedia_stopwatch.stop()
      write-ezlogs "####################### Get-LocalMedia Finished" -PerfTimer $GetLocalMedia_stopwatch -Perf
      $GetLocalMedia_stopwatch = $null
    }
    return
  }elseif($startup -and $Import_Profile){
    write-ezlogs "[Get-LocalMedia] | Media Profile to import not found at $AllMedia_Profile_File_Path....Attempting to build new profile" -showtime -logtype LocalMedia
    Import-module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
    Import-module "$($thisApp.Config.Current_Folder)\Modules\Find-FilesFast\Find-FilesFast.psm1" -NoClobber -DisableNameChecking -Scope Local
  }  
  if($Media_Path){
    $directories = $Media_Path
    if($Import_Profile -and ([System.IO.File]::Exists($AllMedia_Profile_File_Path))){ 
      write-ezlogs "[Get-LocalMedia] | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -logtype LocalMedia
      try{
        $synchash.All_local_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path
      }catch{
        write-ezlogs "[Get-LocalMedia] An exception occurred importing local media profile at: $AllMedia_Profile_File_Path" -catcherror $_
      } 
    }
  }else{
    $directories = $Media_directories
    if(!$Refresh_All_Media -and [System.IO.File]::Exists($AllMedia_Profile_File_Path)){
      write-ezlogs "[Get-LocalMedia] | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -logtype LocalMedia
      try{
        $synchash.All_local_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path 
      }catch{
        write-ezlogs "[Get-LocalMedia] An exception occurred importing local media profile at: $AllMedia_Profile_File_Path" -catcherror $_
      }    
    }
  } 
  if(!$synchash.All_local_Media -or @($synchash.All_local_Media).count -lt 1){
    write-ezlogs "[Get-LocalMedia] | Creating new Generic list for Local_Available_Media" -showtime -logtype LocalMedia
    $synchash.All_local_Media = [System.Collections.Generic.List[Media]]::new()
  } 
  try{
    if($directories){
      $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))',[System.Text.RegularExpressions.RegexOptions]::Compiled)
      $exclude_Pattern = '\.temp\.|\.tmp\.'
      $image_pattern = [regex]::new('$(?<=\.((?i)jpg|(?i)png|(?i)jpeg|(?i)bmp|(?i)webp|(?i)gif))',[System.Text.RegularExpressions.RegexOptions]::Compiled)
      if($AddNewOnly -and !$Media_Path -and $synchash.All_local_Media){
        try{
          $directories = lock-object -InputObject $synchash.All_local_Media.SyncRoot -ScriptBlock {
            $directories | & { process { 
                if(($synchash.All_local_Media.SourceDirectory.indexof("$_".ToUpper()) -eq -1 -and $synchash.All_local_Media.SourceDirectory.indexof("$_".ToLower()) -eq -1)){
                  $_
                }
            }} | Select-Object -Unique
            #$directories = $directories.where({($synchash.All_local_Media.SourceDirectory.indexof($_)) -eq -1}) | Select-Object -Unique
          }         
          write-ezlogs "[Get-LocalMedia] | New directories not already included in media library: Count $($directories.count)" -showtime -logtype LocalMedia
        }catch{
          write-ezlogs "An exception occurred getting unique directories not already included in media library" -catcherror $_
        }
      }
      $total_directories = @($directories).count
      $synchash.processed_directories = 0 
      $synchash.processed_localMedia = 0    
      if($ImportMode -eq 'Slow'){
        $throttle = 1
      }elseif($total_directories -ge 128){
        $throttle = 128
      }elseif($total_directories -gt 1){
        $throttle = $total_directories
      }else{
        $throttle = 32
      }
      write-ezlogs "[Get-LocalMedia] >>>> Scanning $total_directories directories - throttlelimit - $throttle" -showtime -logtype LocalMedia
      try{
        $Controls_to_Update = [System.Collections.Generic.List[object]]::new(2)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'LocalMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' = "Visible"
        })            
        [void]$Controls_to_Update.Add($newRow) 
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'LocalMedia_Progress2_Label'
            'Property' = 'Visibility'
            'Value' = "Visible"
        })              
        [void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'LocalMedia_Progress_Label'
            'Property' = 'Text'
            'Value' = "Processed ($($synchash.processed_directories) of $($total_directories)) Directories"
        })             
        [void]$Controls_to_Update.Add($newRow)
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      }catch{
        write-ezlogs "[Get-LocalMedia] An exception occurred updating LocalMedia_Progress_Ring" -showtime -catcherror $_
      }
      $synchash.LocalMediaDuplicates = 0
      try{
        if($synchash.All_local_Media.IsFixedSize -and [system.io.file]::Exists($AllMedia_Profile_File_Path)){
          write-ezlogs "[Get-LocalMedia] All_Local_Media is fixed size - Current Type: $($synchash.All_local_Media.gettype()), reimporting/recreating from media profiles" -warning -logtype LocalMedia
          try{
            $synchash.All_local_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path
          }catch{
            write-ezlogs "[Get-LocalMedia] An exception occurred importing local media profile at: $AllMedia_Profile_File_Path" -catcherror $_
          }
        }
        $directories | Where-Object {-not [string]::IsNullOrEmpty($_)} | Invoke-Parallel -NoProgress -ThrottleLimit $throttle {
          $directory = $_
          try{            
            if(($directory).StartsWith("\\")){
              $isNetworkPath = $true
            }elseif([system.io.driveinfo]::new($directory).DriveType -eq 'Network' -and (Use-RunAs -Check)){
              $isNetworkMappedDrive = $true
            }
            if($isNetworkMappedDrive){
              $isEnableLinkedConnections = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -ErrorAction SilentlyContinue).EnableLinkedConnections
              if(!$isEnableLinkedConnections){
                write-ezlogs "[Get-LocalMedia] A local media import path looks to be a network or mapped drive and this app is currently running as administrator. Importing and scanning for media from this path may fail. Read the help topic for 'Use Enablelinkedconnections' under settings for details`n`nNetwork Path: $directory" -warning
                if($synchash.Window.isLoaded){
                  Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Update-Notifications\Update-Notifications.psm1" -NoClobber -DisableNameChecking -Scope Local
                  $restartasuserScriptBlock = {
                    use-runas -RestartAsUser
                  }
                  New-DialogNotification -thisApp $thisapp -synchash $synchash -Message "A local media import path looks to be a network or mapped drive and this app is currently running as administrator. Importing and scanning for media from this path may fail. Read the help topic for 'Use Enablelinkedconnections' under settings for details`n`nNetwork Path: $directory" -DialogType Normal -ActionName 'Restart As User' -ActionScriptBlock $restartasuserScriptBlock
                } 
              }                 
            }
            if([System.IO.Directory]::Exists($directory) -or [System.IO.File]::Exists($directory)){
              write-ezlogs "[Get-LocalMedia] | Scanning for media files in directory: $directory" -showtime -logtype LocalMedia -LogLevel 2          
              try{
                $find_Files_Measure = [system.diagnostics.stopwatch]::StartNew()      
                (Find-FilesFast -Path $directory -Recurse -Filter $media_pattern) | & { process {
                    if(!$_.isDirectory){
                      Add-LocalMedia -synchash $synchash -thisApp $thisApp -Media $_ -ImportMode $ImportMode -Directory $directory -image_pattern $image_pattern -media_pattern $media_pattern
                    }
                }}
                $find_Files_Measure.stop()
                write-ezlogs "Find-FilesFast Measure for $($_)" -showtime -logtype LocalMedia -LogLevel 2 -Perf -PerfTimer $find_Files_Measure
                $find_Files_Measure = $Null
                $synchash.processed_directories++
                try{
                  $Controls_to_Update = [System.Collections.Generic.List[object]]::new(2) 
                  $newRow = [PSCustomObject]::new(@{
                      'Control' = 'LocalMedia_Progress_Label'
                      'Property' = 'Text'
                      'Value' = "Processed ($($synchash.processed_directories) of $($total_directories)) Directories"
                  })             
                  [void]$Controls_to_Update.Add($newRow) 
                  $newRow = [PSCustomObject]::new(@{
                      'Control' = 'LocalMedia_Progress2_Label'
                      'Property' = 'Text'
                      'Value' = "Current Directory: $($directory)"
                  })             
                  [void]$Controls_to_Update.Add($newRow)
                  Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
                }catch{
                  write-ezlogs "An exception occurred updating LocalMedia_Progress_Ring" -showtime -catcherror $_
                }
              }catch{
                write-ezlogs "An exception occurred attempting to enumerate files for directory $($_)" -showtime -catcherror $_
                [void]$error.clear()
              }                
            }else{
              write-ezlogs "The provided path is not valid: $($_)" -warning -logtype LocalMedia
            }
          }catch{
            write-ezlogs "[Get_LocalMedia] An exception occurred in an Invoke-Parallel thread/loop" -catcherror $_
          }
        }
      }catch{
        write-ezlogs "[Get_LocalMedia] An exception executing Invoke-Parallel" -catcherror $_
      }
    }else{
      write-ezlogs "No valid directory/path was provided to scan for media files!" -showtime -warning -logtype LocalMedia
      return
    }  
    write-ezlogs "Number of local media duplicates skipped: $($synchash.LocalMediaDuplicates)" -showtime -warning -logtype LocalMedia -LogLevel 2
    if($export_profile -and $AllMedia_Profile_File_Path){
      write-ezlogs ">>>> Exporting All Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype LocalMedia -LogLevel 3
      Export-SerializedXML -InputObject $synchash.All_local_Media -Path $AllMedia_Profile_File_Path
    }
    if($ImportMode -eq 'Fast' -and $synchash.LocalMediaUpdate_timer){
      if($AddNewOnly){
        $synchash.LocalMediaUpdate_timer.tag = $directories
      }else{
        $synchash.LocalMediaUpdate_timer.tag = $Null
      }
      $synchash.LocalMediaUpdate_timer.start()
    }
    write-ezlogs " | Number of Local Media files found: $(@($synchash.All_local_Media).Count)" -showtime -logtype LocalMedia
  }catch{
    write-ezlogs "An exception occurred scanning media files for directories: $($directories)" -catcherror $_
  }finally{
    if($GetLocalMedia_stopwatch){
      $GetLocalMedia_stopwatch.stop()
      write-ezlogs "####################### Get-LocalMedia Processing Finished #######################" -PerfTimer $GetLocalMedia_stopwatch -Perf -GetMemoryUsage
      $GetLocalMedia_stopwatch = $null
    }
  }
}
#---------------------------------------------- 
#endregion Get-LocalMedia Function
#----------------------------------------------

#---------------------------------------------- 
#region Receive-LocalMedia Function
#----------------------------------------------
function Receive-LocalMedia{
  param (
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    $thisApp = $thisApp,
    $synchash = $synchash,
    $thisScript = $thisScript,
    $ImportMode,
    [System.Collections.Concurrent.ConcurrentQueue`1[object]]$Queue,
    [string]$Directory,
    [switch]$Startup,
    [switch]$shutdown,
    [switch]$Use_Runspace
  )
  <#  if(!$synchash.LocalMedia_Queue){
      $synchash.LocalMedia_Queue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      } 
      if($thisApp.LocalMedia_Queue_Enabled -and $shutdown){
      $thisApp.LocalMedia_Queue_Enabled = $false
      return
  }#>
  $LocalMedia_Queue_ScriptBlock = {
    param (
      $thisApp = $thisApp,
      $synchash = $synchash,
      $ImportMode = $ImportMode,
      [System.Collections.Concurrent.ConcurrentQueue`1[object]]$Queue = $Queue,
      $thisScript = $thisScript,
      [string]$Directory = $Directory,
      [switch]$Startup = $Startup,
      [switch]$shutdownWait = $shutdownWait,
      [switch]$StartupWait = $StartupWait,
      [switch]$shutdown = $shutdown
    )
    try{   
      #$thisApp.LocalMedia_Queue_Enabled = $true   
      $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
      $exclude_Pattern = '\.temp\.|\.tmp\.'
      $image_pattern = [regex]::new('$(?<=\.((?i)jpg|(?i)png|(?i)jpeg|(?i)bmp|(?i)webp|(?i)gif))')
      do
      {
        try{
          $object = @{}
          $ProcessMessage = $Queue.TryDequeue([ref]$object)
          if($ProcessMessage -and $object){
            if($object.FullName -match $media_pattern -and $object.FullName -notmatch $exclude_Pattern -and !$object.isDirectory){
              Add-LocalMedia -synchash $synchash -thisApp $thisApp -Media $object -ImportMode $ImportMode -Directory $directory
            }          
          }
          Remove-Variable object
          Remove-Variable ProcessMessage
        }catch{
          Start-Sleep -Milliseconds 500
          write-ezlogs "[Receive-LocalMedia] An exception occurred in ProfileManager_ScriptBlock while loop" -catcherror $_
        } 
      } while(!$Queue.IsEmpty)
      write-ezlogs "[Receive-LocalMedia] LocalMedia_Queue for directory '$Directory' has ended!" -warning
    }catch{
      write-ezlogs "[Receive-LocalMedia] An exception occurred in LocalMedia_Queue_ScriptBlock for directory: $Directory" -catcherror $_
    }  
  }
  if($Use_Runspace){
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    Start-Runspace $LocalMedia_Queue_ScriptBlock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name "LocalMedia_Queue_Runspace_$((New-Guid).Guid)" -thisApp $thisapp -CheckforExisting  
    Remove-Variable Variable_list 
  }else{
    Invoke-Command -ScriptBlock $LocalMedia_Queue_ScriptBlock
  }
}
#---------------------------------------------- 
#endregion Receive-LocalMedia Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-LocalMedia Function
#----------------------------------------------
function Add-LocalMedia
{
  [CmdletBinding(DefaultParameterSetName = 'Media')]
  param (
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    $Media,
    [switch]$Startup,
    $synchash,
    $ImportMode,
    [string]$Directory,
    [switch]$Refresh_All_Media,
    [switch]$NoMediaLibrary,
    $thisApp,
    [regex]$image_pattern,
    [regex]$media_pattern,
    [switch]$use_runspace,
    [switch]$use_Queue,
    [switch]$update_Library,
    [switch]$VerboseLog 
  )
  
  $Add_LocalMedia_scriptblock = {
    #$Add_LocalMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    $synchash = $synchash
    $thisApp = $thisApp
    $media = $Media
    $directory = $directory
    $update_Library = $update_Library
    $ImportMode = $ImportMode
    $use_Queue = $use_Queue
    $exclude_Pattern = '\.temp\.|\.tmp\.'
    $image_pattern = $image_pattern
    try{    
      $sourcedirectory = $Null    
      $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
      if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
        try{
          [void][System.IO.Directory]::CreateDirectory($AllMedia_Profile_Directory_Path)
        }catch{
          write-ezlogs "[Add-LocalMedia] An exception occurred creating new directory at: $AllMedia_Profile_Directory_Path" -catcherror $_
        }   
      }
      $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
      if(!$synchash.All_local_Media -or $synchash.All_local_Media.count -lt 1){
        write-ezlogs "[Add-LocalMedia] | Creating new Generic list for Local_Available_Media" -showtime -logtype LocalMedia
        $synchash.All_local_Media = [System.Collections.Generic.List[Media]]::new()
      }
      $mediadirectory = $null
      $MediaNotAddedCheck = $Null
      $Subtitles_file = $Null
      $filename = $Null
      $length = $Null
      $ParentFolderName = $Null
      if(-not [string]::IsNullOrEmpty($media.FileSize)){
        $length = $media.FileSize
      }elseif(-not [string]::IsNullOrEmpty($media.Size)){
        $length = $media.Size
      }elseif(-not [string]::IsNullOrEmpty($media.length)){
        $length = $media.length
      }
      if(-not [string]::IsNullOrEmpty($Media.FullName)){
        $name = [system.io.path]::GetFileNameWithoutExtension($Media.FullName)
        $url = $media.FullName
        $filename = $media.FileName
        $mediadirectory = [system.io.path]::GetDirectoryName($media.FullName)
        $ParentFolderName = [system.io.directory]::GetParent($media.Fullname).name
      }elseif(-not [string]::IsNullOrEmpty($media.path)){
        $name = [system.io.path]::GetFileNameWithoutExtension($media.path)
        $url = $media.path 
        $filename = $media.Name
        $mediadirectory = [system.io.path]::GetDirectoryName($media.path)
        $ParentFolderName = [system.io.directory]::GetParent($media.path).name
      }
      if(($name) -and $length){      
        if($Media.AlternateFileName){
          $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Media.AlternateFileName)-$($Media.FileSize)")
        }elseif($Media.ShortName){
          $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Media.ShortName)-$($Media.Size)")
        }else{
          $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($filename)-$($length)")
        }        
        $encodedid = [System.Convert]::ToBase64String($encodedBytes)          
        if($thisApp.Config.LocalMedia_SkipDuplicates -and $synchash.All_local_Media.SyncRoot){
          $MediaNotAddedCheck = lock-object -InputObject $synchash.All_local_Media.SyncRoot -ScriptBlock {
            if(!$synchash.All_local_Media.id){
              return $encodedid
            }else{
              return ($synchash.All_local_Media.id.IndexOf($encodedid) -eq -1)
            }
          }  
        }else{
          $MediaNotAddedCheck = $encodedid
        }   
        if($MediaNotAddedCheck){                      
          $type = [system.io.path]::GetExtension($filename).replace('.','')
          [string]$sourcedirectory = $directory
          if($ImportMode -ne 'Fast'){
            $songinfo = Get-SongInfo -path $("$url") #-use_FFPROBE_Fallback  
          }                                              
          if($ImportMode -notin 'Fast','Slow'){
            if(!$songinfo.PictureData -and [System.IO.Directory]::Exists($mediadirectory)){
              $images = [System.IO.Directory]::EnumerateFiles($mediadirectory,'*.*','TopDirectoryOnly') | where-object {$_ -match $image_pattern}
            }
            $Subtitles_file = ([system.io.path]::Combine($mediadirectory,"$([system.io.path]::GetFileNameWithoutExtension($filename)).srt"))
            if([system.io.file]::Exists($Subtitles_file)){
              $Subtitles_Path = $Subtitles_file
            }else{
              $Subtitles_Path = $null
            }           
          }                                   
          <#          if($songinfo -and !$songinfo.Artist -and $mediadirectory){
              $songinfo.Artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($mediadirectory)).ToLower()).trim() 
              $songinfo.Artist = (Get-Culture).TextInfo.ToTitleCase().trim()  
              }elseif($songinfo.Artist){
              $songinfo.Artist = $(Get-Culture).TextInfo.ToTitleCase($songinfo.Artist).trim() 
          }#>
          if($images){
            $covert_art = $images.where({$_ -match [regex]::Escape($name)})                  
            if(!$covert_art){
              $covert_art = $images.where({$_ -match 'cover'})
            }                  
            if(!$covert_art){
              $covert_art = $images.where({$_ -match 'album'})
            }                  
          }                                         
          if(-not [string]::IsNullOrEmpty($Songinfo.Artist)){
            $artist = $songinfo.Artist          
          }else{ 
            $artist = 'Unknown'
          }  
          if($Songinfo.title){
            $Media_title = $Songinfo.title
          }elseif($name){
            $Media_title = $name
          }
          if(-not [string]::IsNullOrEmpty($songinfo.duration)){
            $duration = $songinfo.duration
          }elseif(-not [string]::IsNullOrEmpty($songinfo.duration_ms)){
            $duration = $songinfo.duration_ms
            $duration_ms = $Null
          }else{
            $duration = $Null
          }
          if($duration){
            try{
              $Timespan = [timespan]::Parse($duration)
              if($Timespan){
                $duration = "$(([string]$timespan.Hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
              }                
            }catch{
              write-ezlogs "An exception occurred parsing timespan for duration $duration" -showtime -catcherror $_
            }                
          }
          if(-not [string]::IsNullOrEmpty($thisApp.Config.LocalMedia_Display_Syntax) -and $ImportMode -ne 'Fast'){
            $DisplayName = $thisApp.Config.LocalMedia_Display_Syntax -replace '%artist%',$artist -replace '%title%',$Media_title -replace '%track%',$Songinfo.tracknumber -replace '%album%',$songinfo.album
          }else{
            $DisplayName = $Null
          }                                        
          $newRow = [Media]@{
            'title' = [string]$Media_title
            'Display_Name' = $DisplayName
            'Artist' = [string]$artist
            'Track' = [int]$Songinfo.tracknumber
            'Album' = [string]$songinfo.album
            'Bitrate' = $songinfo.bitrate
            'id' = [string]$encodedid
            'url' = ($url -replace '\\\\','\')
            'type' = [string]$type
            'Duration' = $duration
            'Size' = $length
            'directory' = [string]$mediadirectory
            'SourceDirectory' = [string]$sourcedirectory
            'Current_Progress_Secs' = ''
            'Subtitles_Path' = [string]$Subtitles_Path
            'hasVideo' = $songinfo.hasVideo
            'PictureData' = ($songinfo.PictureData -eq $true)
            'Profile_Date_Added' = [DateTime]::Now.ToString()
            'Source' = 'Local'
          } 
          try{
            lock-object -InputObject $synchash.All_local_Media.SyncRoot -ScriptBlock {
              if($synchash.All_local_Media.IsFixedSize){
                #write-ezlogs "All_local_media is currently a fixed size - Current Type: $($synchash.All_local_Media.GetType())..creating new generic list" -warning -logtype LocalMedia
                $synchash.All_local_Media = ConvertTo-Media -InputObject $synchash.All_local_Media -List
                #$synchash.All_local_Media = [System.Collections.Generic.List[Media]]::new($synchash.All_local_Media)
              }
              [void]$synchash.All_local_Media.add($newRow) 
            }      
          }catch{
            write-ezlogs "An exception occurred adding new media to All_Local_Media -- Media url: $($newRow.url)" -showtime -catcherror $_
          }                                                                                
        }else{ 
          $synchash.LocalMediaDuplicates++
          if($thisApp.Config.Dev_mode){write-ezlogs "Skipping duplicate media: ($name) -- path: $($url)" -showtime -warning -logtype LocalMedia -Dev_mode}
        } 
        $name = $null 
        $type = $null 
        $images = $null          
        $url = $null
        $encodedid = $Null  
        $artist = $Null
        $filesize = $null
        $duration = $Null
        $directory_filecount = $null
        $covert_art = $Null
        $Media_title = $null
        $songinfo = $Null
        $length = $null
        $synchash.processed_localMedia++
        try{
          if($synchash.Window){
            $Controls_to_Update = [System.Collections.Generic.List[PSCustomObject]]::new(3)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'LocalMedia_RefreshProgress_Ring'
                'Property' = 'isActive'
                'Value' = $true
            })              
            [void]$Controls_to_Update.Add($newRow) 
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'MediaTable_RefreshLabel'
                'Property' = 'Visibility'
                'Value' = "Visible"
            })             
            [void]$Controls_to_Update.Add($newRow)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'Refresh_LocalMedia_Button'
                'Property' = 'isEnabled'
                'Value' = $false
            })
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'LocalMedia_Progress2_Label'
                'Property' = 'Text'
                'Value' = "Current Directory: $($directory) - Processed Files: $($synchash.processed_localMedia)"
            })                         
            [void]$Controls_to_Update.Add($newRow)
            Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
            #Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'LocalMedia_RefreshProgress_Ring' -Property 'isActive' -value $true
            #Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'MediaTable_RefreshLabel' -Property 'Visibility' -value 'Visible'
            #Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Refresh_LocalMedia_Button' -Property 'isEnabled' -value $false
            #Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'LocalMedia_Progress2_Label' -Property 'Text' -value "Current Directory: $($directory) - Processed Files: $($synchash.processed_localMedia)"
          }      
        }catch{
          write-ezlogs "An exception occurred updating LocalMedia_Progress_Ring" -showtime -catcherror $_
        }
        if($update_Library){
          write-ezlogs " | ProfileManager_Queue.IsEmpty: $($synchash.ProfileManager_Queue.IsEmpty)"
          if($synchash.All_local_Media -and ($synchash.ProfileManager_Queue.IsEmpty)){
            write-ezlogs ">>>> Exporting All Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype LocalMedia 
            Export-SerializedXML -Path $AllMedia_Profile_File_Path -InputObject $synchash.All_local_Media
            if($synchash.Refresh_LocalMedia_timer -and !$synchash.Refresh_LocalMedia_timer.isEnabled){
              $synchash.Refresh_LocalMedia_timer.tag = 'WatcherLocalRefresh'  
              $synchash.Refresh_LocalMedia_timer.start()   
            }
          }
        }                             
      }else{
        write-ezlogs "[Add-LocalMedia] Provided media: $($url) is not a valid media file type - length: $($length)" -showtime -warning -logtype LocalMedia
      }
    }catch{
      write-ezlogs "An exception occurrred processesing media file: $($media)" -showtime -catcherror $_
    }
  }
  if($Use_Runspace){
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    $Runspace_GUID = (New-Guid).Guid
    Start-Runspace -scriptblock $Add_LocalMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name "Add_LocalMedia_Runspace_$Runspace_GUID" -thisApp $thisApp -synchash $synchash
    $Variable_list = $Null
  }else{
    #[void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Normal,[Action]$Add_LocalMedia_scriptblock)
    Invoke-Command -ScriptBlock $Add_LocalMedia_scriptblock
  }
}
#---------------------------------------------- 
#endregion Add-LocalMedia Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-Media Function
#----------------------------------------------
function Update-Media
{
  param (
    $InputObject,
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    [string]$TotalCount,
    [switch]$Refresh_All_Media,
    [switch]$update_Library,
    [switch]$NoTagScan,
    [switch]$UpdatePlaylists,
    $thisApp,
    $all_Playlists,
    $UpdateDirectory,
    $UpdateMedia,
    [switch]$SkipGetMedia
  )
  try{
    if(!$NoTagScan){
      $songinfo = Get-SongInfo -path $($InputObject.url) #-use_FFPROBE_Fallback
    }
    if($songinfo){                
      if($songinfo.Artist -ne $Null -and $songinfo.Artist -ne '' -and $InputObject.artist -ne $songinfo.Artist){
        $InputObject.artist = [Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($songinfo.Artist)
      }
      if($Songinfo.title -ne $Null -and $Songinfo.title -ne '' -and $InputObject.title -ne $Songinfo.title){
        $InputObject.title = $Songinfo.title
      }
      if($songinfo.duration -ne $null -and $songinfo.duration -ne ''){
        $duration = $songinfo.duration
      }elseif($songinfo.duration_ms -ne $null -and $songinfo.duration_ms -ne ''){
        $duration = $songinfo.duration_ms
        $duration_ms = $Null
      }else{
        $duration = $Null
      }
      if($duration){
        try{
          $Timespan = [timespan]::Parse($duration).ToString()
          if($Timespan -and $InputObject.duration -ne $TimeSpan){
            $InputObject.duration = $TimeSpan
          }
        }catch{
          write-ezlogs "An exception occurred parsing timespan for duration $duration" -showtime -catcherror $_
        }finally{
          $Timespan = $Null
        }           
      }
      $mediadirectory = [system.io.path]::GetDirectoryName($InputObject.url)
      if(!(Test-ValidPath $InputObject.Subtitles_Path -Type File)){
        $Subtitles_file = "$mediadirectory\$([system.io.path]::GetFileNameWithoutExtension($InputObject.url)).srt"
        #$Subtitles_file = ([system.io.path]::Combine($mediadirectory,"$([system.io.path]::GetFileNameWithoutExtension($_.url)).srt"))
        if($InputObject.Subtitles_Path -ne $Subtitles_file -and (Test-ValidPath $Subtitles_file -Type File)){
          $InputObject.Subtitles_Path = $Subtitles_file
        }
      }
      if($InputObject.Track -ne $Songinfo.tracknumber){
        $InputObject.Track = $Songinfo.tracknumber
      }
      if($InputObject.Album -ne $songinfo.album){
        $InputObject.Album = $songinfo.album
      }
      if($InputObject.hasVideo -ne $songinfo.hasVideo){
        $InputObject.hasVideo = $songinfo.hasVideo
      }
      if($InputObject.PictureData -ne $songinfo.PictureData){
        $InputObject.PictureData = $songinfo.PictureData
      }
      if($Songinfo.Length -ne $Null -and $InputObject.Size -ne $Songinfo.Length){
        $InputObject.Size = $Songinfo.Length
      }
      if($thisApp.Config.LocalMedia_Display_Syntax -ne $null -and $InputObject.Display_Name -eq $null){
        $InputObject.Display_Name = $($thisApp.Config.LocalMedia_Display_Syntax -replace '%artist%',$InputObject.artist -replace '%title%',$InputObject.title -replace '%track%',$InputObject.Track -replace '%album%',$InputObject.Album)
      }
      $songinfo = $Null
    }
    if($InputObject -and $UpdatePlaylists -and $all_Playlists){
      try{
        $Media = $InputObject
        $all_Playlists | & { process {
            $playlist = $_
            $Changes = $false
            $track_index = $Null
            $track = $null
            try{           
              $urls = [System.Collections.Generic.list[object]]$playlist.PlayList_tracks.values.url
              if($urls){
                $track_index = $urls.indexof($InputObject.url)
              }
              if($track_index -ne -1 -and $track_index -ne $null){
                #$track = $playlist.PlayList_tracks[$track_index]
                $track = $playlist.PlayList_tracks.Values | Where-Object {$_.url -eq $InputObject.url}
                if($track){
                  foreach ($property in $InputObject.psobject.properties.name){
                    if([bool]$track.PSObject.Properties[$property] -and $track.$property -ne $InputObject.$property){
                      if($thisApp.Config.Dev_mode){write-ezlogs " | Updating track property: '$($property)' from value: '$($track.$property)' - to: '$($InputObject.$property)'" -Dev_mode -logtype LocalMedia}
                      $track.$property = $InputObject.$property
                      $Changes = $true
                    }elseif(-not [bool]$track.PSObject.Properties[$property]){
                      write-ezlogs " | Adding track property: '$($property)' with value: $($InputObject.$property)" -logtype LocalMedia
                      $Changes = $true
                      $track.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new($property,$InputObject.$property))
                    }
                  }
                  if([bool]$track.psobject.properties['SongInfo']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('SongInfo')
                  }
                  if([bool]$track.psobject.properties['Profile_path']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('Profile_path')
                  }
                  if([bool]$track.psobject.properties['encodedTitle']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('encodedTitle')
                  }
                  if([bool]$track.psobject.properties['Cover_art']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('Cover_art')
                  } 
                  if([bool]$track.psobject.properties['directory_filecount']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('directory_filecount')
                  }
                  if([bool]$track.psobject.properties['cached_image_path']){
                    $Changes = $true
                    [void]$track.PSObject.Properties.Remove('cached_image_path')
                  }
                  if($Changes){
                    $UpdatePlaylists = $true
                  }
                }
              }
            }catch{
              write-ezlogs "[Update-LocalMedia] An exception occurred processing playlist: $($playlist | out-string)" -CatchError $_
            }finally{
              $track = $Null
            }
        }}                 
      }catch{
        write-ezlogs "[Update-LocalMedia] An exception occurred attempting to lookup and update playlist tracks with url: $($InputObject.url)" -CatchError $_
      }      
    }
    $synchash.UpdateMediaCount++
    Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'MediaTable_RefreshProgress_Label' -Property 'Text' -value "[$($synchash.UpdateMediaCount)/$($TotalCount)]"
  }catch{
    write-ezlogs "An exception occurred processing media item $($InputObject | out-string)" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Update-Media Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-LocalMedia Function
#----------------------------------------------
function Update-LocalMedia
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
    [switch]$update_Library,
    [switch]$UpdatePlaylists,
    [switch]$NoTagScan,
    $thisApp,
    $UpdateDirectory,
    $UpdateMedia,
    [switch]$SkipGetMedia,
    [switch]$use_runspace,
    [switch]$VerboseLog = $thisApp.config.Verbose_logging
  )
  $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
  $update_LocalMedia_scriptblock = {
    $get_LocalMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    $synchash = $synchash
    $thisApp = $thisApp
    $NoTagScan = $NoTagScan
    $update_Library = $update_Library
    $UpdateDirectory = $UpdateDirectory
    $UpdateMedia = $UpdateMedia
    $UpdatePlaylists = $UpdatePlaylists
    try{
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-LocalMedia\Get-LocalMedia.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-module -Name "$($thisApp.Config.Current_Folder)\Modules\PSParallel\PSParallel.psd1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
      if($synchash.All_local_Media.count -gt 0){
        $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
        $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
        if($UpdateDirectory){
          write-ezlogs ">>>> Updating local media for directories: $($UpdateDirectory)"    
          $media_to_Update = foreach($Directory in $UpdateDirectory){
            Get-IndexesOf $synchash.All_local_Media.SourceDirectory -Value $Directory | & { process {
                $synchash.All_local_Media[$_]
            }}    
          }
        }elseif($UpdateMedia.id){
          write-ezlogs ">>>> Updating local media with id: $($UpdateMedia.id)"  
          $media_to_Update = foreach($Media in $UpdateMedia){
            Get-IndexesOf $synchash.All_local_Media.id -Value $Media.id | & { process {
                $synchash.All_local_Media[$_]
            }}   
          }
        }else{
          write-ezlogs ">>>> Updating all local media"
          $media_to_Update = $synchash.All_local_Media
        }
        $TotalCount = @($media_to_Update).count
        write-ezlogs "####################### Executing Update-LocalMedia for $($TotalCount) files" -linesbefore 1 -logtype LocalMedia
        if(!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
          [void][System.IO.Directory]::CreateDirectory($AllMedia_Profile_Directory_Path)
        } 
        $synchash.UpdateMediaCount = 0
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'MediaTable_RefreshProgress_Label' -Property 'Text' -value "[$($synchash.UpdateMediaCount)/$($TotalCount)]"
        if($media_to_Update){
          if($UpdatePlaylists -and $synchash.all_playlists){
            if($synchash.all_playlists -isnot [System.Collections.Generic.List[Playlist]]){
              $all_Playlists = $synchash.all_playlists | ConvertTo-Playlists -List
            }else{
              $all_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchash.all_playlists)
            }
          }
          if([int]$env:NUMBER_OF_PROCESSORS -le 4){
            $Thottle = 2
          }else{
            $Thottle = [int]$env:NUMBER_OF_PROCESSORS
          }
          $media_to_Update | & { process {if($_.url -and ([System.IO.Path]::HasExtension($_.url))){$_}}} | Invoke-Parallel -NoProgress -ThrottleLimit ($Thottle) {
            Update-Media -InputObject $_ -synchash $synchash -thisapp $thisApp -all_Playlists $all_Playlists -TotalCount $TotalCount -UpdatePlaylists:$UpdatePlaylists -update_Library:$update_Library -UpdateMedia:$UpdateMedia -UpdateDirectory:$UpdateDirectory -NoTagScan:$NoTagScan
          }
          if($AllMedia_Profile_File_Path){
            write-ezlogs ">>>> Exporting All Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype LocalMedia -LogLevel 3
            Export-SerializedXML -Path $AllMedia_Profile_File_Path -InputObject $synchash.All_local_Media
          }
          if($UpdatePlaylists -and $all_Playlists){
            Export-SerializedXML -InputObject $all_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Playlists\Get-Playlists.psm1" -NoClobber -DisableNameChecking -Scope Local
            Get-Playlists -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Import_Playlists_Cache -Quick_Refresh
            [void]$all_Playlists.clear()
            $all_Playlists = $Null
          }
          if($get_LocalMedia_Measure){
            $get_LocalMedia_Measure.stop()
            write-ezlogs "####################### Update-LocalMedia Processing Finished #######################" -PerfTimer $get_LocalMedia_Measure -Perf -GetMemoryUsage -forceCollection -PriorityLevel 3
            $GetLocalMedia_stopwatch = $null
          }
          write-ezlogs " | Number of Local Media files updated: $($media_to_Update.Count)" -showtime -logtype LocalMedia -LogLevel 2
          #}
        }else{
          write-ezlogs "No Local Media was found to process!" -logtype LocalMedia -LogLevel 2 -warning
        }
      }else{
        write-ezlogs "No Local Media was found to process!" -logtype LocalMedia -LogLevel 2 -warning
      }
    }catch{
      write-ezlogs "An exception occurred in update-localmedia scriptblock" -catcherror $_
    }finally{
      if($synchash.MainWindow_Update_Timer.isEnabled){
        $synchash.MainWindow_Update_Timer.stop()
      }
      if($synchash.MainWindow_UpdateQueue){
        $synchash.MainWindow_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      }
      $synchash.UpdateMediaCount = 0
      Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'MediaTable_RefreshProgress_Label' -Property 'Text' -value "[0/0]"
      if($synchash.Refresh_LocalMedia_timer -and $update_Library){
        write-ezlogs ">>>> Executing Refresh_LocalMedia_timer for Update-LocalMedia"
        $synchash.Refresh_LocalMedia_timer.tag = 'Update-LocalMedia'
        $synchash.Refresh_LocalMedia_timer.start()
      }
      Remove-Module -Name "Write-EZLogs" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "Set-WPFControls" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "Get-LocalMedia" -Force -ErrorAction SilentlyContinue
      Remove-module -Name "Get-HelperFunctions" -Force -ErrorAction SilentlyContinue
      Remove-module -Name "PSParallel" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "PSSerializedXML" -Force -ErrorAction SilentlyContinue
    }
  }
  $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace -scriptblock $update_LocalMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'update_LocalMedia_Runspace' -thisApp $thisApp -synchash $synchash -CheckforExisting -RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
  $update_LocalMedia_scriptblock = $Null
  $Variable_list = $Null
}
#----------------------------------------------
#endregion Update-LocalMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-LocalMedia','Get-SongInfo','Update-LocalMedia','Add-LocalMedia','Receive-LocalMedia','Get-Taglib','Get-TitleCase','Update-Media')