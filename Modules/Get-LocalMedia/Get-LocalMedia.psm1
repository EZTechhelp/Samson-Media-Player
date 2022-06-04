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
      try{ 
        if(!$(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -ErrorAction SilentlyContinue)){
          write-ezlogs " | Adding EnableLinkedConnections to registry" -showtime
          New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -Value 1 -PropertyType 'DWord'
          write-ezlogs " | Restarting LanmanWorkstation service" -showtime
          get-service LanmanWorkstation* | Restart-Service -Force
        }
      }catch{
        write-ezlogs "An exception occurred setting EnableLinkedConnections registry" -showtime -catcherror $_
      }
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
      if($Verboselog){write-ezlogs " | Importing Local Media Profile: $AllMedia_Profile_File_Path" -showtime -enablelogs}
      [System.Collections.ArrayList]$Local_Available_Media = Import-CliXml -Path $AllMedia_Profile_File_Path 
    }
  }else{
    $directories = $Media_directories
    if(!$Refresh_All_Media){
      if($Verboselog){write-ezlogs " | Importing Local Media Profile to process differences: $AllMedia_Profile_File_Path" -showtime -enablelogs}
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
            $media_files = cmd /c dir $directory /s /b /a-d | Where{$_ -match $media_pattern}  
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
        try{
          foreach ($m in $media_files) {  
            $media = $Null
            if([System.IO.File]::Exists($m)){  
              $Media = [System.IO.FileInfo]::new($m) | Where{$_.Extension -match $media_pattern}             
            }           
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
                if([System.IO.Directory]::Exists($media.Directory)){
                  $directory_filecount = @([System.IO.Directory]::GetFiles("$($media.Directory)",'*','AllDirectories') | Where{$_ -match $media_pattern}).count
                  $images = [System.IO.Directory]::EnumerateFiles($media.Directory,'*','TopDirectoryOnly') | where {$_ -match $image_pattern}
                  #$images = (robocopy $media.Directory 'Doesntexist' $image_formats /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim() | where {$_}
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
                $songinfo = $Null
                $songinfo = Get-SongInfo -path $url
                if(!$songinfo.Artist -and $directory){
                  $songinfo.Artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($directory))).trim()  
                }else{
                  $songinfo.Artist = $(Get-Culture).TextInfo.ToTitleCase($songinfo.Artist).trim() 
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
                  'Profile_Path' = $AllMedia_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'Local'
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
          write-ezlogs "An exception occurrred processesing media files - Type: $($Media_files.gettype() | out-string) -  $($media_files | out-string)" -showtime -catcherror $_
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