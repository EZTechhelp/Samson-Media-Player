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
    - Module designed for EZT-GameManager

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-SongInfo Function
#----------------------------------------------
function Get-SongInfo($Path)
{
  if($Path){
    try{
      <#      $Shell = New-Object -COMObject Shell.Application
          $DirName = $([System.IO.Path]::GetDirectoryName($Path))
          if($DirName){
          $Folder = $shell.Namespace($($DirName))
          $Filename = [System.IO.Path]::GetFileName($Path)
          }
          if($Folder -and $Filename){
          $File = $Folder.ParseName($($Filename))
          if(!$file -and $filename -match '\?'){
          $Filename = ($Folder.Items() | where {$_.name -match $(($Filename -split '\?')[0]) -or $_.name -match $(($Filename -split '\?')[0])}).Name
          }
          if($Filename){
          $File = $Folder.ParseName($($Filename))
          }
          $title = ($Folder.GetDetailsOf($File, 21))
          $artistpattern = "(?<value>.*) by (?<value>.*)"
          #[int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
          $Artist = ($Folder.GetDetailsOf($File, 13))
          if([string]::IsNullOrEmpty($artist) -and $title -match $artistpattern){   
          $artist = ([regex]::matches($title,  $artistpattern)| %{$_.groups[1].value} )
          }
          if($Artist -match ';'){
          $artist = ($artist -split ';')[0]
          }
          $filesize = ($Folder.GetDetailsOf($File, 1))
          $comments =  ($Folder.GetDetailsOf($File,24))
          $album = ($Folder.GetDetailsOf($File, 14))
          #$year = ($Folder.GetDetailsOf($File, 15))
          #$Genre = ($Folder.GetDetailsOf($File, 16))
          #  if($Genre -match ';'){
          #    $Genre = ($Genre -split ';')[0]
          #}  
          #$copyright = ($Folder.GetDetailsOf($File, 25))
          #$length = $h*60*60 + $m*60 +$s
          $tracknumber = ($Folder.GetDetailsOf($File, 26))
          $duration = ($Folder.GetDetailsOf($File, 27))
          $bitrate = ($Folder.GetDetailsOf($File, 28))
          }
          $meta_properties_output = New-Object -TypeName 'System.Collections.ArrayList'     
          $newRow = New-Object PsObject -Property @{
          'Artist' = $Artist
          'Title' = $title
          'Album' = $album 
          'Year' = $year
          'Comments' = $comments
          'Genre' = $Genre
          'Length' = $length
          'Duration' = $duration
          'FileSize' = $filesize
          'Copyright' = $copyright
          'TrackNumber' = $tracknumber
          'Bitrate' = $bitrate
          }
          $null = $meta_properties_output.Add($newRow)
      Write-Output $meta_properties_output #>  
      try{
        $taginfo = [taglib.file]::create($Path) 
      }catch{
        write-ezlogs "An exception occurred getting taginfo for $Path" -showtime -catcherror $_
      }              
      if($taginfo.tag.IsEmpty -or !$taginfo){
        $rootdir = [System.IO.directory]::GetParent($Path)
        $artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($rootdir))).trim() 
        $title = ([System.IO.Path]::GetFileNameWithoutExtension($Path))
      }else{
        if($taginfo.tag.Albumartists){
          $artist = $taginfo.tag.Albumartists
        }elseif($taginfo.tag.FirstArtist){
          $artist = $taginfo.tag.FirstArtist
        }elseif($taginfo.tag.FirstPerformer){
          $artist = $taginfo.tag.FirstPerformer
        }elseif($taginfo.tag.Artists){
          $artist = $taginfo.tag.Artists | select -first 1
        }        
        $title = $taginfo.tag.title
        if($taginfo.properties.duration){
          $duration = [timespan]::Parse($taginfo.properties.duration)
          $duration_ms = [timespan]::Parse($taginfo.properties.duration).TotalMilliseconds
        }
      }
      if($taginfo.tag.pictures.IsLoaded){
        $PictureData = $true
      }else{
        $PictureData = $false
      }
      $meta_properties_output = New-Object -TypeName 'System.Collections.ArrayList'       
      $newRow = New-Object PsObject -Property @{
        'Artist' = $Artist
        'Title' = $title
        'Album' = $taginfo.tag.Album 
        'Year' = $taginfo.tag.Year
        'Comments' = $taginfo.tag.comment
        'Genre' = $taginfo.tag.Genres
        'Length' = ''
        'Duration' = $duration
        'Duration_ms' = $duration_ms
        'FileSize' = ''
        'MediaTypes' = $taginfo.properties.MediaTypes
        'PictureData' = $PictureData
        'Copyright' = $taginfo.tag.copyright
        'TrackNumber' = $taginfo.tag.track
        'Bitrate' = $taginfo.properties.audiobitrate
      }
      $null = $meta_properties_output.Add($newRow)
      Write-Output $meta_properties_output

    }catch{
      write-ezlogs "An exception occurred parsing info about file $Path" -showtime -catcherror $_
    }
  }
}
#---------------------------------------------- 
#endregion Get-SongInfo Function
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
    $all_installed_apps,
    [switch]$Refresh_All_Media = $true,
    [switch]$Startup,
    [switch]$update_global,
    [switch]$Export_Profile,
    [switch]$Export_AllMedia_Profile,
    [string]$Media_Profile_Directory,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog
  )
  if($Verboselog){write-ezlogs "#### Getting Local Media ####" -enablelogs -color yellow -linesbefore 1}
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
  if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
    $Null = New-Item -Path $AllMedia_Profile_Directory_Path -ItemType directory -Force
  } 
  $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
  $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
  $image_pattern = [regex]::new('$(?<=\.((?i)jpg|(?i)png|(?i)jpeg))')
  if($startup -and $Import_Profile -and ([System.IO.FIle]::Exists($AllMedia_Profile_File_Path))){ 
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') 
    #Enable linked connections in order to access mapped drives when running under admin context
    if(!$IsAdmin){
      <#      try{ 
          if(!$(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -ErrorAction SilentlyContinue)){
          write-ezlogs " | Adding EnableLinkedConnections to registry" -showtime
          New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -Value 1 -PropertyType 'DWord'
          write-ezlogs " | Restarting LanmanWorkstation service" -showtime
          get-service LanmanWorkstation* | Restart-Service -Force
          }
          }catch{
          write-ezlogs "An exception occurred setting EnableLinkedConnections registry" -showtime -catcherror $_
      }#>
    }  
    if($Verboselog){write-ezlogs "[STARTUP] | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -enablelogs}
    [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path
    return $Local_Available_Media    
  }elseif($startup -and $Import_Profile){
    if($Verboselog){write-ezlogs " | Media Profile to import not found at $AllMedia_Profile_File_Path....Attempting to build new profile" -showtime -enablelogs -color cyan}
  }  
  if($Media_Path){
    $directories = $Media_Path
    if($Import_Profile -and ([System.IO.File]::Exists($AllMedia_Profile_File_Path))){ 
      if($Verboselog){write-ezlogs "[Media_Path] | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -enablelogs}
      [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path 
    }
  }else{
    $directories = $Media_directories
    if(!$Refresh_All_Media){
      if($Verboselog){write-ezlogs "[Media_directories] | Importing Local Media Profile to process differences: $AllMedia_Profile_File_Path" -showtime -enablelogs}
      [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path
    }
  } 
  if(!$Local_Available_Media -or @($Local_Available_Media).count -lt 1){
    if($Verboselog){write-ezlogs " | Creating new Array list for Local_Available_Media" -showtime -enablelogs}
    $Local_Available_Media = New-Object -TypeName 'System.Collections.ArrayList'  
  }  
  if($directories){
    if(!$Refresh_All_Media){
      $directories = $directories | where {$Local_Available_Media.directory.fullname -notcontains $_}
    } 

    foreach($directory in $directories){
      if($hash.Window.isVisible){
        $hash.Window.Dispatcher.invoke([action]{
            $hash.More_Info_Msg.Visibility= "Visible"
            $hash.More_info_Msg.text="Scanning Directory $($directory)"
        },"Normal")
      }      
      if([System.IO.Directory]::Exists($directory)){
        if($Verboselog){write-ezlogs " | Scanning for media files in directory: $directory" -showtime -enablelogs}     
        if($PSVersionTable.PSVersion.Major -gt 5){ 
          try{ 
            $searchOptions = [System.IO.EnumerationOptions]::New()
            $searchOptions.RecurseSubdirectories = $true
            $searchOptions.IgnoreInaccessible = $true   
            $searchoptions.AttributesToSkip = "Hidden,System,ReparsePoint,Temporary"
            $media_files = [System.IO.Directory]::EnumerateFiles($directory,'*',$searchOptions) | where {$_ -match $media_pattern}
          }catch{
            write-ezlogs "An exception occurred attempting to enumerate files for directory $($directory)" -showtime -catcherror $_        
          }    
        }else{
          try{
            #$media_files = [System.IO.Directory]::EnumerateFiles($directory,'*','AllDirectories') | where {$_ -match $media_pattern}  
            $find_Files_Measure = Measure-Command {
              $media_files = Find-FilesFast -Path $directory | where {$_ -match $media_pattern}
            }
            write-ezlogs "Find-FilesFast Meaasure: $($find_Files_Measure | out-string)" -showtime
            #$media_files = cmd /c dir $directory /s /b /a-d | Where{$_ -match $media_pattern}  
          }catch{
            write-ezlogs "An exception occurred attempting to enumerate files for directory $($directory)" -showtime -catcherror $_
          } 
        }                    
        #$media_files = (robocopy $directory 'Doesntexist' $media_formats /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim()       
      }elseif([System.IO.File]::Exists($directory)){
        if($Verboselog){write-ezlogs " | Found Media file: $directory" -showtime -enablelogs}
        $media_files = $directory
      } 
      if(-not [string]::IsNullOrEmpty($media_files)){ 
        #$found_media = $media_formats | %{ Get-ChildItem -File $mediaDirectory -Filter $_ -Recurse }    
        foreach ($m in $media_files | where {$_}) {  
          try{
            $media = $Null
            try{
              $Media = [System.IO.FileInfo]::new($m) #| Where{$_.Extension -match $media_pattern}  
            }catch{
              write-ezlogs "An exception occurrred getting fileinfo for: $($m)" -showtime -catcherror $_
            }
            if(!$media){
              try{
                $media = Get-Item $m -Force
              }catch{
                write-ezlogs "An exception occurred in get-item for: $($m)" -showtime -catcherror $_
              }
            }
            if(!$media){
              try{
                $media = Get-Item -literalpath $m -Force
              }catch{
                write-ezlogs "An exception occurred in get-item -literalpath for: $($m)" -showtime -catcherror $_
              }
            }
            if(!$media){
              try{
                $Shell = New-Object -COMObject Shell.Application
                $DirName = $([System.IO.Path]::GetDirectoryName($m))
                if($DirName){
                  $Folder = $shell.Namespace($($DirName))
                  $Filename = [System.IO.Path]::GetFileName($m)
                }
                if($Folder -and $Filename){
                  $File = $Folder.ParseName($($Filename))
                  if(!$file -and $filename -match '\?'){
                    $Filename = ($Folder.Items() | where {$_.name -match $(($Filename -split '\?')[0]) -or $_.name -match $(($Filename -split '\?')[0])}).Name
                  }
                  if($Filename){
                    $File = $Folder.ParseName($($Filename))
                  }
                  if($file.path){
                    $Media = [System.IO.FileInfo]::new($file.path)
                  }
                }
              }catch{
                write-ezlogs "An exception occurred in getting file info from Shell.Application for: $($m)" -showtime -catcherror $_
              }
            }                       
            #}           
            if($Media){              
              $name = $null           
              $name = $media.BaseName
              $url = $null
              $url = $media.FullName
              $encodedTitle = $Null  
              $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($name)-Local")
              $encodedTitle = [System.Convert]::ToBase64String($encodedBytes)            
              if($url -and $Local_Available_Media.encodedtitle -notcontains $encodedTitle){
                $Local_Media_output = New-Object -TypeName 'System.Collections.ArrayList'            
                $type = $null           
                $type = $($media.Extension).replace('.','')
                $length = $null
                $length = $media.Length
                $directory = $null
                $directory = $($media.Directory)
                $directory_filecount = $null
                $covert_art = $Null
                $images = $null 
                $songinfo = $Null
                $songinfo = Get-SongInfo -path $url                               
                if([System.IO.Directory]::Exists($media.Directory)){
                  #$directory_filecount = @([System.IO.Directory]::GetFiles("$($media.Directory)",'*','AllDirectories') | Where{$_ -match $media_pattern}).count
                  if(!$songinfo.PictureData){
                    $images = [System.IO.Directory]::EnumerateFiles($media.Directory,'*','TopDirectoryOnly') | where {$_ -match $image_pattern}
                  }
                  #$images = (robocopy $media.Directory 'Doesntexist' $image_formats /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim() | where {$_}
                }                
                if($songinfo -and !$songinfo.Artist -and $directory){
                  $songinfo.Artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($directory))).trim()  
                }elseif($songinfo.Artist){
                  $songinfo.Artist = $(Get-Culture).TextInfo.ToTitleCase($songinfo.Artist).trim() 
                }
                if($songinfo -and !$songinfo.filesize -and $media.Length){
                  $songinfo.filesize = [math]::round($media.Length /1mb, 2)
                }
                if($songinfo.MediaTypes -match 'Video'){
                  $hasVideo = $true
                }else{
                  $hasVideo = $false
                }
                if($images){
                  $covert_art = $images | where {$_ -match $name}                  
                  if(!$covert_art){
                    $covert_art = $images | where {$_ -match 'cover'}
                  }                  
                  if(!$covert_art){
                    $covert_art = $images | where {$_ -match 'album'}
                  }                  
                }                               
                if($Verboselog){write-ezlogs ">>>> Found local media file $name" -showtime -color Cyan}
                if($Verboselog){write-ezlogs " | Type $($type)" -showtime}
                if($Verboselog){write-ezlogs " | Title $($Songinfo.title)" -showtime}
                if($Verboselog){write-ezlogs " | Artist $($Songinfo.Artist)" -showtime}
                if($Verboselog){write-ezlogs " | URL $($url)" -showtime}            
             
                $newRow = New-Object PsObject -Property @{
                  'name' = $name
                  'title' = $Songinfo.title
                  'encodedTitle' = $encodedTitle
                  'id' = $encodedTitle
                  'url' = $url
                  'type' = $type
                  'length' = $length
                  'directory' = $directory
                  'directory_filecount' = $directory_filecount
                  'Cover_art' = $covert_art
                  'SongInfo' = $songinfo
                  'hasVideo' = $hasVideo
                  'Profile_Path' = $AllMedia_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'Local'
                }              
                $null = $Local_Media_output.Add($newRow) 
                $null = $Local_Available_Media.add($Local_Media_output)                                         
              }else{
                if($thisApp.Config.Verbose_logging){write-ezlogs "Media ($name) already exists -- skipping duplicate" -showtime -enablelogs -warning}
              }     
            }else{
              write-ezlogs "Provided File $_ is not a valid media type" -showtime -warning
            }
          }catch{
            write-ezlogs "An exception occurrred processesing media file: $($m)" -showtime -catcherror $_
          }
        }
        #$found_media = (Get-childitem -path "$($mediaDirectory)\*" -Filter $media_formats -Recurse -force)

      }else{
        write-ezlogs "Provided Media Directory $Directory is not valid!" -showtime -warning
      }
    }

  }else{
    write-ezlogs "No valid directory/path was provided to scan for media files!" -showtime -warning
  }
  <#  [array]$Local_Available_Media = foreach($media in  $found_media)
      {

  }#>
  if($export_profile -and $AllMedia_Profile_File_Path){
    if($Verboselog){write-ezlogs ">>>> Exporting All Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -enablelogs}
    [System.Collections.ArrayList]$Local_Available_Media | Export-Clixml $AllMedia_Profile_File_Path -Force
  }
  if($Verboselog){write-ezlogs " | Number of Local Media files found: $(@($Local_Available_Media).Count)" -showtime -enablelogs}
  if($hash.Window.isVisible){
    $hash.Window.Dispatcher.invoke([action]{
        $hash.More_Info_Msg.Visibility= "Visible"
        $hash.More_info_Msg.text=""
    },"Normal")
  }  
  return [System.Collections.ArrayList]$Local_Available_Media

}
#---------------------------------------------- 
#endregion Get-LocalMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-LocalMedia','Get-SongInfo')