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
    [switch]$Refresh_Global_Profile,
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
  $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,"All-MediaProfile")
  if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
    $Null = New-Item -Path $AllMedia_Profile_Directory_Path -ItemType directory -Force
  } 
  $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
  $media_pattern = [regex]::new('$(?<=\.(MP3|mp3|Mp3|mP3|mp4|MP4|Mp4|flac|FLAC|Flac|WAV|wav|Wav|AVI|Avi|avi|wmv|h264|mkv|webm|h265|mov|h264|mpeg|mpg4|movie|mpgx|vob|3gp|m2ts|aac))')
  $media_formats = @(
    '*.Mp3'
    '*.mp4'
    '*.wav'
    '*.flac'
    '*.h264'
    '*.avi'
    '*.mkv'
    '*.webm'
    '*.h265'
    '*.mov'
    '*.wmv'
    '*.h264'
    '*.mpeg'
    '*.mpg4'
    '*.movie'
    '*.mpgx'
    '*.vob'
    '*.3gp'
    '*.m2ts'
    '*.aac'
  )
  $image_formats = @(
    '*.jpg'
    '*.png'
    '*.Jpeg'
  )
  $media_pattern = [regex]::new('$(?<=\.(MP3|mp3|Mp3|mP3|mp4|MP4|Mp4|flac|FLAC|Flac|WAV|wav|Wav|AVI|Avi|avi|wmv|h264|mkv|webm|h265|mov|h264|mpeg|mpg4|movie|mpgx|vob|3gp|m2ts|aac))')
  $image_pattern = [regex]::new('$(?<=\.(jpg|png|jpeg|PNG|JPG|JPEG))')
  #Enable linked connections in order to access mapped drives when running under admin context
  if(!$(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -ErrorAction SilentlyContinue)){
    write-ezlogs " | Adding EnableLinkedConnections to registry" -showtime
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -Value 1 -PropertyType 'DWord'
    write-ezlogs " | Restarting LanmanWorkstation service" -showtime
    get-service LanmanWorkstation | Restart-Service -Force
  }
  if($startup -and $Import_Profile -and ([System.IO.FIle]::Exists($AllMedia_Profile_File_Path))){ 
    if($Verboselog){write-ezlogs " | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -enablelogs}
    [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path
    return $Local_Available_Media    
  }elseif($startup -and $Import_Profile){
    if($Verboselog){write-ezlogs " | Media Profile to import not found at $AllMedia_Profile_File_Path....Attempting to build new profile" -showtime -enablelogs -color cyan}
  }  
  if($Media_Path){
    $directories = $Media_Path
    if($Import_Profile -and ([System.IO.File]::Exists($AllMedia_Profile_File_Path))){ 
      if($Verboselog){write-ezlogs " | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -enablelogs}
      [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path 
    }
  }else{
    $directories = $Media_directories
    $Local_Available_Media = New-Object -TypeName 'System.Collections.ArrayList'
  }   
  if($directories){  
    foreach($directory in $directories){
      if($hash.Window.isVisible){
        $hash.Window.Dispatcher.invoke([action]{
            $hash.More_Info_Msg.Visibility= "Visible"
            $hash.More_info_Msg.text="Scanning Directory $($directory)"
        },"Normal")
      }      
      if([System.IO.Directory]::Exists($directory)){
        if($Verboselog){write-ezlogs " | Scanning for media files in directory: $directory" -showtime -enablelogs}
        $media_files = (robocopy $directory 'Doesntexist' $media_formats /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim()       
      }elseif([System.IO.File]::Exists($directory)){
        if($Verboselog){write-ezlogs " | Found Media file: $directory" -showtime -enablelogs}
        $media_files = $directory
      } 
      if(-not [string]::IsNullOrEmpty($media_files)){ 
        #$found_media = $media_formats | %{ Get-ChildItem -File $mediaDirectory -Filter $_ -Recurse }
        try{
          ($media_files).trim() | foreach {  
            $media = $Null
            if([System.IO.File]::Exists($_)){  
              $Media = [System.IO.FileInfo]::new($_) | Where{$_.Extension -match $media_pattern}             
            }           
            if($Media){              
              #$Media = [System.IO.FileInfo]::new($_)
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
                if([System.IO.Directory]::Exists($media.Directory)){
                  $directory_filecount = @([System.IO.Directory]::GetFiles("$($media.Directory)",'*','AllDirectories') | Where{$_ -match $media_pattern}).count
                  $images = (robocopy $media.Directory 'Doesntexist' $image_formats /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim() | where {$_}
                }                
                if($images){
                  $covert_art = $images | where {$_ -match $name}                  
                  if(!$covert_art){
                    $covert_art = $images | where {$_ -match 'cover'}
                  }                  
                  if(!$covert_art){
                    $covert_art = $images | where {$_ -match 'album'}
                  }
                  if(!$covert_art){
                    $covert_art = $images | select -first 1
                  }                  
                }
                $songinfo = $Null
                $songinfo = Get-SongInfo -path $url
                $songinfo.Artist = $(Get-Culture).TextInfo.ToTitleCase($songinfo.Artist).trim() 
                if($Verboselog){write-ezlogs ">>>> Found local media file $name" -showtime -color Cyan}
                if($Verboselog){write-ezlogs " | Type $($type)" -showtime}
                if($Verboselog){write-ezlogs " | Title $($Songinfo.title)" -showtime}
                if($Verboselog){write-ezlogs " | Artist $($Songinfo.Artist)" -showtime}
                if($Verboselog){write-ezlogs " | URL $($url)" -showtime}            
             
                $newRow = New-Object PsObject -Property @{
                  'name' = $name
                  'encodedTitle' = $encodedTitle
                  'id' = $encodedTitle
                  'url' = $url
                  'type' = $type
                  'length' = $length
                  'directory' = $directory
                  'directory_filecount' = $directory_filecount
                  'Cover_art' = $covert_art
                  'SongInfo' = $songinfo
                  'Profile_Path' = $AllMedia_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'Local'
                  'LaunchCommand' = ""
                }              
                $null = $Local_Media_output.Add($newRow) 
                $null = $Local_Available_Media.add($Local_Media_output)                                         
              }else{
                write-ezlogs "Media ($name) already exists -- skipping duplicate" -showtime -enablelogs -warning
              }     
            }else{
              write-ezlogs "Provided File $_ is not a valid media type" -showtime -warning
            }
          }
          #$found_media = (Get-childitem -path "$($mediaDirectory)\*" -Filter $media_formats -Recurse -force)
        }catch{
          write-ezlogs "An exception occurrred processesing media files $($media_files | out-string)" -showtime -catcherror $_
        }
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
    $Local_Available_Media | Export-Clixml $AllMedia_Profile_File_Path -Force
  }
  if($Verboselog){write-ezlogs " | Number of Local Media files found: $(@($Local_Available_Media).Count)" -showtime -enablelogs}
  if($hash.Window.isVisible){
    $hash.Window.Dispatcher.invoke([action]{
        $hash.More_Info_Msg.Visibility= "Visible"
        $hash.More_info_Msg.text=""
    },"Normal")
  }  
  return $Local_Available_Media

}
#---------------------------------------------- 
#endregion Get-LocalMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-LocalMedia')