<#
    .Name
    Get-Spotify

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves spotify tracks, albums, playlists..etc 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-Spotify Function
#----------------------------------------------
function Get-Spotify
{
  Param (
    [string]$MediaName,
    [switch]$Import_Profile,
    $thisApp,
    $log,
    $synchash,
    $all_installed_apps,
    [switch]$Refresh_Global_Profile,
    [switch]$Startup,
    [switch]$update_global,
    [switch]$Export_Profile,
    [switch]$Get_Playlists,
    [switch]$Export_AllMedia_Profile,
    [string]$Media_Profile_Directory,
    $Media_directories,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog
  )
  $GetSpotify_stopwatch = [system.diagnostics.stopwatch]::StartNew() 
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
  $pattern = "[™$illegal]"
  #$pattern2 = "[:$illegal]"
  Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
  $AllSpotify_Media_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-Spotify_MediaProfile")
  if (!([System.IO.Directory]::Exists($AllSpotify_Media_Profile_Directory_Path))){
    [Void][System.IO.Directory]::CreateDirectory($AllSpotify_Media_Profile_Directory_Path)
  } 
  $AllSpotify_Media_Profile_File_Path = [System.IO.Path]::Combine($AllSpotify_Media_Profile_Directory_Path,"All-Spotify_Media-Profile.xml")
  if($Import_Profile -and ([System.IO.File]::Exists($AllSpotify_Media_Profile_File_Path))){
    write-ezlogs ">>>> Importing Cached Spotify Media Profile: $AllSpotify_Media_Profile_File_Path" -showtime -enablelogs -logtype Spotify -loglevel 3
    $synchash.All_Spotify_Media = Import-SerializedXML -Path $AllSpotify_Media_Profile_File_Path
    if($GetSpotify_stopwatch){
      $GetSpotify_stopwatch.stop()
    }
    write-ezlogs "####################### Get-Spotify Finished" -PerfTimer $GetSpotify_stopwatch -Perf -logtype Spotify -GetMemoryUsage #-forceCollection
    return
  }else{
    write-ezlogs ">>>> Spotify Media Profile to import not found at $AllSpotify_Media_Profile_File_Path or import_profile was false....Attempting to build new profile" -showtime -logtype Spotify -loglevel 2
    Import-module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
  }  
  try{  
    Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -NoClobber -DisableNameChecking -Scope Local
    $access_Token = Get-SpotifyAccessToken -ApplicationName $thisApp.config.App_Name -NoAuthPrompt
  }catch{
    write-ezlogs "An exception occurred in Get-SpotifyApplication" -showtime -catcherror $_
  }
  if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
    write-ezlogs ">>>> Checking for spotify at  $($env:APPDATA)\Spotify\Spotify.exe" -showtime -logtype Spotify
    $Spotify_Install_Path = [system.io.path]::GetDirectoryName("$($env:APPDATA)\Spotify\Spotify.exe")
    $Spotify_Launch_Path = "$($env:APPDATA)\Spotify\Spotify.exe"
  }
  if(!$Spotify_Install_Path -and !$thisApp.Config.Spotify_WebPlayer){
    write-ezlogs ">>>> Could not find Spotify, checking appx packages" -showtime -logtype Spotify
    if($psversiontable.PSVersion.Major -gt 5){
      try{
        write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning
        Import-module Appx -usewindowspowershell
      }catch{
        write-ezlogs "An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
      }
    }    
    $Spotify_app = (Get-appxpackage 'Spotify*')
    if($Spotify_app){
      $Spotify_Install_Path = $($Spotify_app.InstallLocation)
      $Spotify_Launch_Path = "$($Spotify_app.InstallLocation)\Spotify.exe"
    }    
  }
  if([System.IO.File]::Exists($Spotify_Launch_Path)){
    write-ezlogs " | Spotify is installed at $Spotify_Launch_Path" -showtime -logtype Spotify 
  }elseif(!$thisApp.Config.Spotify_WebPlayer){
    write-ezlogs "Unable to find Spotify installed at path $Spotify_Launch_Path" -showtime -Warning -logtype Spotify
    if($thisApp.Config.Install_Spotify){
      $null = confirm-requirements -thisApp $thisApp -noRestart
      write-ezlogs ">>>> Installing Spotify via chocolatey" -showtime -logtype Spotify
      write-ezlogs "----------------- [START] Install Spotify via chocolatey [START] -----------------" -showtime -logtype Spotify  
      #$chocoappmatch = choco list Spotify
      try{
        $Chocopath = "$($env:ChocolateyInstall)\choco.exe"
        $newProc = [System.Diagnostics.ProcessStartInfo]::new($Chocopath)
        $newProc.WindowStyle = 'Hidden'
        $newProc.Arguments = "list Spotify"
        $newProc.UseShellExecute = $false
        $newProc.CreateNoWindow = $true
        $newProc.RedirectStandardOutput = $true
        $Process = [System.Diagnostics.Process]::Start($newProc)
        $chocoappmatch = $Process.StandardOutput.ReadToEnd()
      }catch{
        write-ezlogs "An exception occurred executing: $Chocopath" -catcherror $_
      }finally{
        if($Process -is [System.IDisposable]){
          $Process.dispose()
        }
      }
      write-ezlogs "$($chocoappmatch)" -showtime -logtype Spotify
      $appinstalled = $("$($chocoappmatch | Select-String Spotify)").trim()
      if(-not [string]::IsNullOrEmpty($appinstalled) -and $appinstalled -notmatch 'Removing incomplete install for'){
        if([System.IO.Directory]::Exists("$($env:APPDATA)\Spotify")){
          $appinstalled_Version = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
          if($appinstalled_Version){
            write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)). Also detected installed exe: $($appinstalled_Version). Will continue to attemp to update Spotify..." -showtime -warning -logtype Spotify
          }
        }else{
          write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)), yet it does not exist. Choco database likely corrupted or out-dated, performing remove of Spotify via Chocolately.." -showtime -warning -logtype Spotify
          try{
            $Chocopath = "$($env:ChocolateyInstall)\choco.exe"
            $newProc = [System.Diagnostics.ProcessStartInfo]::new($Chocopath)
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "uninstall Spotify --confirm --force"
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $newProc.RedirectStandardOutput = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
            $chocoremove = $Process.StandardOutput.ReadToEnd()
            write-ezlogs "Choco Uninstall: $($chocoremove)" -logtype Spotify
          }catch{
            write-ezlogs "An exception occurred executing: $Chocopath" -catcherror $_
          }finally{
            if($Process -is [System.IDisposable]){
              $Process.dispose()
            }
          }          
          #$chocoremove = choco uninstall Spotify --confirm --force
          write-ezlogs "Verifying if Choco still thinks Spotify is installed..." -showtime -logtype Spotify
          try{
            $Chocopath = "$($env:ChocolateyInstall)\choco.exe"
            $newProc = [System.Diagnostics.ProcessStartInfo]::new($Chocopath)
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "list Spotify"
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $newProc.RedirectStandardOutput = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
            $chocoappmatch = $Process.StandardOutput.ReadToEnd()
          }catch{
            write-ezlogs "An exception occurred executing: $Chocopath" -catcherror $_
          }finally{
            if($Process -is [System.IDisposable]){
              $Process.dispose()
            }
          }
          #$chocoappmatch = choco list Spotify
          $appinstalled = $("$($chocoappmatch | Select-String Spotify)").trim()
          if(-not [string]::IsNullOrEmpty($appinstalled)){
            write-ezlogs "Choco still thinks Spotify is installed, unable to continue! Check choco logs at: $env:ProgramData\chocolatey\logs\chocolatey.log" -showtime -warning -logtype Spotify
            return
          }
        }
      }
      try{
        $Chocopath = "$($env:ChocolateyInstall)\choco.exe"
        $newProc = [System.Diagnostics.ProcessStartInfo]::new($Chocopath)
        $newProc.WindowStyle = 'Hidden'
        $newProc.Arguments = "upgrade Spotify --confirm --force --acceptlicense"
        $newProc.UseShellExecute = $false
        $newProc.CreateNoWindow = $true
        $newProc.RedirectStandardOutput = $true
        $Process = [System.Diagnostics.Process]::Start($newProc)
      }catch{
        write-ezlogs "An exception occurred executing: $Chocopath" -catcherror $_
      }finally{
        while($Process.StandardOutput.EndOfStream -eq $false){
          $Process.StandardOutput.ReadLine() | & { process {
              write-ezlogs $_ -logtype Spotify
          }}
        }
        if($Process -is [System.IDisposable]){
          $Process.dispose()
        }
      }
      #$choco_install = choco upgrade Spotify --confirm --force --acceptlicense *>&1 | write-ezlogs -logtype Spotify
      write-ezlogs "----------------- [END] Install Spotify via chocolatey [END] -----------------" -showtime -logtype Spotify
      write-ezlogs "Verifying if Spotify was installed successfully...." -showtime -logtype Spotify
      try{
        $Chocopath = "$($env:ChocolateyInstall)\choco.exe"
        $newProc = [System.Diagnostics.ProcessStartInfo]::new($Chocopath)
        $newProc.WindowStyle = 'Hidden'
        $newProc.Arguments = "list Spotify"
        $newProc.UseShellExecute = $false
        $newProc.CreateNoWindow = $true
        $newProc.RedirectStandardOutput = $true
        $Process = [System.Diagnostics.Process]::Start($newProc)
        $chocoappmatch = $Process.StandardOutput.ReadToEnd()
      }catch{
        write-ezlogs "An exception occurred executing: $Chocopath" -catcherror $_
      }finally{
        if($Process -is [System.IDisposable]){
          $Process.dispose()
        }
      }
      #$chocoappmatch = choco list Spotify
      if($chocoappmatch){
        $appinstalled = $("$($chocoappmatch | Select-String Spotify)").trim()
        write-ezlogs " | Choco found: $appinstalled" -showtime -logtype Spotify
      }  
      if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
        #$appinstalled = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe" -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
        $Spotify_Launch_Path = "$($env:APPDATA)\Spotify\Spotify.exe"
        $Spotify_Install_Path = "$($env:APPDATA)\Spotify\"
        write-ezlogs "Successfully installed Spotify at path: $Spotify_Launch_Path" -showtime -logtype Spotify -Success
      }else{
        Import-module "$($thisApp.Config.Current_Folder)\Modules\Get-InstalledApplications\Get-InstalledApplications.psm1" -NoClobber -DisableNameChecking -Scope Local
        $installed_apps = Get-InstalledApplications -verboselog -Force
        $Spotify_app = $installed_apps | Where-Object {$_.'Display Name' -eq 'Spotify'} | Select-Object -Unique
        $Spotify_Install_Path = $Spotify_app.'Install Location'
        $Spotify_Launch_Path = "$($Spotify_app.'Install Location')\Spotify.exe"       
        if([System.IO.File]::Exists($Spotify_Launch_Path)){
          write-ezlogs "Spotify installed successfully" -showtime -logtype Spotify -Success    
        }else{
          write-ezlogs "Spotify did not appear to install correctly or was unable to be found! See logs for errors or details" -showtime -warning -logtype Spotify -AlertUI
        }
      }    
    }else{
      write-ezlogs "Auto installation of Spotify is not enabled, skipping install. Spotify must be manually installed for Spotify features to function" -showtime -warning -logtype Spotify
    }
  }
  
  if($access_Token){
    $synchash.All_Spotify_Media = [System.Collections.Generic.List[Media]]::new()
    $total_playlists = $thisApp.Config.Spotify_Playlists.count
    $synchash.processed_Spotify_tracks = [System.Collections.Generic.List[string]]::new()
    $synchash.processed_Spotify_playlists = 0
    #Get Playlists
    $thisApp.Config.Spotify_Playlists | Invoke-Parallel -NoProgress -ThrottleLimit 64 {
      try{
        if($_ -match 'playlist'){
          if($_ -match "playlist\:"){
            $playlist_id = ($($_) -split('playlist:'))[1].trim()
          }elseif($playlist_id -match '\/playlist\/'){
            $playlist_id = ($($_) -split('\/playlist\/'))[1].trim() 
          }
          $source_type = 'Playlist'     
        }elseif($_ -match 'track'){
          if($_ -match "track\:"){
            $playlist_id = ($($_) -split('track:'))[1].trim()
          }elseif($_ -match '\/track\/'){
            $playlist_id = ($($_) -split('\/track\/'))[1].trim() 
          } 
          $source_type = 'Track'                   
        }elseif($_ -match "episode"){
          if($_ -match 'episode\:'){
            $playlist_id = ($($_) -split('episode:'))[1].trim()  
          }elseif($_ -match '\/episode\/'){
            $playlist_id = ($($_) -split('\/episode\/'))[1].trim()  
          }         
          $source_type = 'Episode'                   
        }elseif($_ -match "show"){  
          if($_ -match 'show\:'){
            $playlist_id = ($($_) -split('show:'))[1].trim()
          }elseif($_ -match '\/show\/'){
            $playlist_id = ($($_) -split('\/show\/'))[1].trim()  
          } 
          $source_type = 'Show'                   
        }
        if($playlist_id -match '\?si\='){
          $playlist_id = ($($playlist_id) -split('\?si\='))[0].trim()
        }
        if([System.IO.File]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist_id).xml")){
          try{
            $playlist_profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist_id).xml"))
            $playlist_profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist_id).xml"
            $Playlist_name = $playlist_Profile.Name
            $playlist_Info = $playlist_Profile.Playlist_Info
            $source_type = $playlist_Info.type
            if($playlist_Info.uri){
              $url = $playlist_Info.uri
            }elseif($playlist_Info.url){
              $url = $playlist_Info.url
            }        
            $playlist_images = $playlist_Info.images
          }catch{
            write-ezlogs "An exception occurred importing profile $playlist_profile_path" -showtime -catcherror $_
          }         
        }elseif($playlist_id -and $access_Token){
          if($source_type -eq 'Playlist'){
            $playlist_Info = Get-Playlist -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
            $Playlist_name = $playlist_Info.Name
            $source_type = $playlist_Info.type
            $url = $playlist_Info.uri
            $images = $playlist_Info.images
            write-ezlogs ">>>> Found Spotify Playlist $Playlist_name" -showtime -logtype Spotify 
          }elseif($source_type -eq 'Track'){
            $Spotifytrack = Get-Track -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
            $source_type = $Spotifytrack.type
            $Playlist_name = "$($Spotifytrack.artists.name)"
            $url = $Spotifytrack.uri
            $images = $Spotifytrack.album.images
            write-ezlogs ">>>> Found Spotify Track $Playlist_name" -showtime -logtype Spotify 
          }elseif($source_type -eq 'Show'){
            $playlist_Info = Get-Show -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
            $Playlist_name = $playlist_Info.Name
            $source_type = $playlist_Info.type
            $url = $playlist_Info.uri
            $images = $playlist_Info.images
            write-ezlogs ">>>> Found Spotify Show $Playlist_name" -showtime -logtype Spotify 
          }elseif($source_type -eq 'Episode'){
            $Spotifytrack = Get-Episode -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
            $source_type = $Spotifytrack.type
            $Playlist_name = "$($Spotifytrack.show.name)"
            $url = $Spotifytrack.uri
            $images = $Spotifytrack.album.images
            write-ezlogs ">>>> Found Spotify Track $Playlist_name" -showtime -logtype Spotify 
          } 
        }
        $href = $_
        if($url -and $playlist_id){   
          if($source_type -match 'Playlist'){
            $playlist_items = [System.Collections.Generic.List[object]]($(Get-PlaylistItems -id $playlist_id -ApplicationName $thisApp.config.App_Name).track)
          }elseif($source_type -match 'Track'){
            if(!$Spotifytrack){
              $playlist_items = [System.Collections.Generic.List[object]](Get-Track -Id $playlist_id -ApplicationName $thisApp.Config.App_Name)
            }else{
              $playlist_items = [System.Collections.Generic.List[object]]($Spotifytrack)
            }       
          }elseif($source_type -eq 'Show'){
            $playlist_items = [System.Collections.Generic.List[object]](Get-ShowEpisodes -id $playlist_id -ApplicationName $thisApp.config.App_Name)     
          }elseif($source_type -eq 'Episode'){
            if(!$Spotifytrack){
              $playlist_items = [System.Collections.Generic.List[object]]$(Get-Episode -id $playlist_id -ApplicationName $thisApp.config.App_Name)  
            }else{
              $playlist_items = [System.Collections.Generic.List[object]]($Spotifytrack)
            }   
          } 
          $encodedBytes = $null      
          if($playlist_items){
            foreach($track in $playlist_items.where({$_.id})){
              try{
                $type = $Null
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.id)-$($Playlist_ID)")
                $encodedid = [System.Convert]::ToBase64String($encodedBytes)   
                if($track.type){
                  $type = $track.type  
                }else{
                  $type = $source_type 
                }
                if($Track.Duration_ms -and $Track.Duration_ms -notmatch ":"){
                  try{
                    $Timespan = [timespan]::FromMilliseconds($Track.Duration_ms)
                    if($Timespan){
                      $duration = "$(([string]$timespan.Hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
                    }                
                  }catch{
                    write-ezlogs "An exception occurred parsing timespan for duration $($Track.Duration_ms)" -showtime -catcherror $_
                  }                
                }
                if(($Track.Album.images).url){
                  $imagetocache = ($Track.Album.images | Where-Object {$_.Width -le 300} | Select-Object -First 1).url
                  if(!$imagetocache){
                    $imagetocache = ($Track.Album.images | Where-Object {$_.Width -ge 300} | Select-Object -last 1).url
                  }
                  if(!$imagetocache){
                    $imagetocache = (($Track.Album.images).psobject.Properties.Value).url | Select-Object -First 1
                  }
                }elseif(($Track.Show.images).url){
                  $imagetocache = ($Track.Show.images | Where-Object {$_.Width -le 300} | Select-Object -First 1).url
                  if(!$imagetocache){
                    $imagetocache = ($Track.Show.images | Where-Object {$_.Width -ge 300} | Select-Object -last 1).url
                  }
                  if(!$imagetocache){
                    $imagetocache = (($Track.Show.images).psobject.Properties.Value).url | Select-Object -First 1
                  }
                }
                if(-not [string]::IsNullOrEmpty(($track.Album.Name))){
                  $Album = ($track.Album.Name)
                  $Album_id = $($Track.Album.id)
                  $artist = ($track.Artists.Name -join ',')
                  $artist_id = $($Track.Artists.id -join ',')
                  $release_date = $($Track.album.release_date)
                }elseif(-not [string]::IsNullOrEmpty(($track.Show.Name))){
                  $Album = ($track.Show.Name)
                  $Album_id = ($track.Show.id)
                  $artist = ($track.show.Name -join ',')
                  $artist_id = $($Track.show.id -join ',')
                  $release_date = $($Track.release_date)
                }
                if(-not [string]::IsNullOrEmpty($thisApp.Config.YoutubeMedia_Display_Syntax)){
                  $DisplayName = $thisApp.Config.YoutubeMedia_Display_Syntax -replace '%artist%',$artist -replace '%title%',$track.name -replace '%album%',$Album -replace '%track%',$($track.track_number) -replace '%playlist%',$playlist_name
                }else{
                  $DisplayName = $Null
                }
                $newRow = [Media]@{
                  'title' = $track.name
                  'artist' = $artist
                  'Display_Name' = $DisplayName
                  'id' = $encodedid
                  'album' = $Album
                  'Playlist' = $($Playlist_name)
                  'description' =''
                  'track' = $($track.track_number)
                  'Album_id' = $Album_id
                  'Spotify_id' = $($Track.id)
                  'duration' = $duration
                  'url' = $($Track.uri)
                  #'release_date' = $release_date
                  'Artist_ID' = $artist_id
                  'cached_image_path' = $imagetocache
                  'type' = $type
                  'Playlist_url' = $url
                  'playlist_id' = $playlist_id
                  #'playlist_profile_path' = $playlist_profile_path
                  #'Profile_Path' = ''
                  'Profile_Date_Added' = [Datetime]::Now.ToString()
                  'Source' = 'Spotify'
                }

                lock-object -InputObject $synchash.All_Spotify_Media.SyncRoot -ScriptBlock {
                  if($synchash.processed_Spotify_tracks -notcontains $encodedid){
                    [void]$synchash.processed_Spotify_tracks.add($encodedid)
                    #$synchash.All_Spotify_Media[$encodedid] = $newRow
                    [void]$synchash.All_Spotify_Media.add($newRow)
                  }else{
                    write-ezlogs "Duplicate Spotify Track found $($Track.Name) - ID $($Track.id) - Encodedid $($encodedid) - Playlist $($Playlist_name)" -showtime -warning -logtype Spotify
                  }
                }
              }catch{
                write-ezlogs "An exception occurred processing track $($track | out-string)" -catcherror $_
                [void]$error.clear()
              }finally{
                $Timespan = $null   
                $duration = $null
                $encodedid = $Null  
                $imagetocache = $Null
                $encodedBytes = $null
                $encodedid = $Null
                $track = $null
              }
            }        
          }
          $synchash.processed_Spotify_playlists++ 
          try{
            $Controls_to_Update = [System.Collections.Generic.List[object]]::new(3) 
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'SpotifyMedia_Progress_Label'
                'Property' = 'Text'
                'Value' = "Imported ($($synchash.processed_Spotify_playlists) of $($total_playlists)) Spotify Playlists"
            })              
            [void]$Controls_to_Update.Add($newRow) 
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'SpotifyMedia_Progress2_Label'
                'Property' = 'Text'
                'Value' = "Current Playlist: $Playlist_name"
            })              
            [void]$Controls_to_Update.Add($newRow)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'SpotifyMedia_Progress2_Label'
                'Property' = 'Visibility'
                'Value' = "Visible"
            })
            [void]$Controls_to_Update.Add($newRow)
            Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
          }catch{
            write-ezlogs "An exception occurred updating SpotifyMedia_Progress_Ring" -showtime -catcherror $_
          }
          write-ezlogs ">>>> Processed ($($synchash.processed_Spotify_playlists) of $($total_playlists)) Spotify Playlists - Playlist Name: $Playlist_name" -showtime -logtype Spotify -LogLevel 2                                                 
        }else{
          write-ezlogs "Couldnt get details of Spotify playlist: Name: ($Playlist_name) - id: $($playlist_id) - url: $($url)" -showtime -enablelogs -warning -logtype Spotify
        }
        $url = $null
        $Playlist_name = $null
        $type = $null
        $source_type = $Null
        #$Tracks_Total = $null
        $images = $null
        $href = $Null
        $playlist_id = $Null
        $Album = $null
        $Album_id = $Null
        $artist = $null
        $artist_id = $null
        $Spotifytrack = $Null
        $release_date = $null
        $playlist_profile_path = $null   
      }catch{
        write-ezlogs "An exception occurred processing Spotify playlist $($href)" -showtime -catcherror $_
      }
      #}
    }
    if($synchash.processed_Spotify_tracks){
      [void]$synchash.processed_Spotify_tracks.clear()
      $synchash.processed_Spotify_tracks = $null
      [void]$synchash.Remove('processed_Spotify_tracks')
    }
    if($export_profile -and $AllSpotify_Media_Profile_File_Path -and $synchash.All_Spotify_Media){
      Export-SerializedXML -InputObject $synchash.All_Spotify_Media -Path $AllSpotify_Media_Profile_File_Path  
    }
    if($Verboselog){write-ezlogs " | Number of Spotify Playlists found: $($synchash.All_Spotify_Media.Count)" -showtime -enablelogs -logtype Spotify}
    if($GetSpotify_stopwatch){
      $GetSpotify_stopwatch.stop()
      write-ezlogs "###### Get-Spotify Finished" -PerfTimer $GetSpotify_stopwatch -Perf -logtype Spotify -GetMemoryUsage
    }      
    #Remove-Variable Available_Spotify_Media  
  }else{
    write-ezlogs "Unable to get Spotify media, Spotify credentials are either missing or invalid! Go to Settings - Spotify to provide credentials or disable Spotify integration" -showtime -warning -logtype Spotify -AlertUI
    return
  }
}
#---------------------------------------------- 
#endregion Get-Spotify Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-SpotifyPlaylist Function
#----------------------------------------------
function Add-SpotifyPlaylist
{
  Param (
    $thisApp,
    $synchash,
    $media,
    $Sender,
    [switch]$Verboselog
  )
  try{
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
    $pattern = "[™`�$illegal]"   
    if($sender.header -eq 'Add to New Playlist..'){
      if($synchash.MediaLibrary_Viewer.isVisible){
        $Playlist = [Microsoft.VisualBasic.Interaction]::InputBox('Add New Spotify Playlist', 'Enter the name of the new Spotify playlist')
      }else{
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
        $Playlist = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add New Spotify Playlist','Enter the name of the new Spotify playlist',$Button_Settings)
      }
      if(-not [string]::IsNullOrEmpty($Playlist)){  
        write-ezlogs ">>>> Verifying new Spotify playlist name: $Playlist" -logtype Spotify 
        $Playlist = ([Regex]::Replace($Playlist, $pattern, '')).trim() 
        [int]$character_Count = ($Playlist | measure-object -Character -ErrorAction SilentlyContinue).Characters
        if([int]$character_Count -ge 100){
          write-ezlogs "Playlist name too long! ($character_Count characters). Please choose a name 100 characters or less " -showtime -warning -logtype Spotify
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[System.Windows.Forms.MessageBox]::Show("Please choose a name for the playlist that is 100 characters or less","Playlist name too long! ($character_Count)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist name too long! ($character_Count)","Please choose a name for the playlist that is 100 characters or less",$okandCancel,$Button_Settings)
          }
          #Update-Notifications  -Level 'WARNING' -Message "Playlist name too long! ($character_Count). Please choose a name 100 characters or less" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
          return
        }
        $playlist_check = $synchash.All_Spotify_Media.where({$_.playlist -eq $Playlist})
        if(-not [string]::IsNullOrEmpty($playlist_check)){ 
          write-ezlogs "An existing Playlist with the name $Playlist already exists!" -warning -logtype Spotify
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[System.Windows.Forms.MessageBox]::Show("Please choose a unique name for the new playlist","An existing Playlist with the name $Playlist already exists!",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"An existing Playlist with the name $Playlist already exists!","Please choose a unique name for the new playlist",$okandCancel,$Button_Settings)
          }
          return
        }
        write-ezlogs "| Creating new Spotify playlist with name $Playlist" -loglevel 2 -logtype Spotify
        $target_playlist = New-Playlist -Name $Playlist -Description "Created from $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -ApplicationName $thisApp.Config.App_Name
        if($target_playlist){
          write-ezlogs "Created new Spotify Playlist $($target_playlist.name) with ID $($target_playlist.id)" -LogLevel 2 -Success -logtype Spotify
          $target_Url = $target_playlist.uri
        }else{
          write-ezlogs "Spotify did not return results creating new playlist $($Playlist). Check the logs for errors/details or try again later" -warning -logtype Spotify
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[System.Windows.Forms.MessageBox]::Show("Spotify did not return results when creating new playlist $($Playlist). Check the logs for errors/details or try again later","Spotify Playlist not successfully created!",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Spotify did not return results when creating new playlist $($Playlist). Check the logs for errors/details or try again later","Spotify Playlist not successfully created!",$okandCancel,$Button_Settings)
          }
          return
        }    
      }
    }else{
      $Playlist = $sender.header
      $target_playlist = $synchash.All_Spotify_Media.where({$_.playlist -eq $Playlist})
      if(@($target_playlist).count -gt 1){
        write-ezlogs "Found multiple ($(@($target_playlist).count)) playlists with the name $Playlist" -warning -logtype Spotify
        #TODO: Need to add handling for multiple Spotify lists with same name since they allow it. Need to pass playlist ID
        $target_playlist = $target_playlist | select -last 1
      }
      if([system.io.file]::Exists($($target_playlist.playlist_profile_path))){
        $target_playlist = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($target_playlist.playlist_profile_path))
      }
      $target_Url = $target_playlist.playlist_url
    }
    if($Media.type -match 'Spotify' -or $Media.uri -match 'spotify\:' -or $Media.Source -eq 'Spotify'){   
      $source_playlist = $synchash.All_Spotify_Media.where({$_.id -eq $Media.id -and $_.playlist_id -eq $Media.playlist_id})
      if($target_playlist.playlist_id -and $Media.Url){      
        $add = Add-PlaylistItem -Id $target_playlist.playlist_id -ItemId $Media.Url -ApplicationName $thisApp.Config.App_Name
        if($add){
          write-ezlogs "Added track $($Media.title) to Spotify Playlist $($target_playlist.name)" -logtype Spotify -Success
          if($thisApp.Config.Spotify_Playlists -notcontains $target_Url){
            try{
              write-ezlogs " | Adding new Spotify Playlist URL to config: $($target_Url) - Playlist Name: $($target_playlist.Name)" -showtime -logtype Spotify -loglevel 3
              $null = $thisApp.Config.Spotify_Playlists.add($target_Url)
              if(![System.IO.Directory]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists")){
                try{
                  $Null = New-item -Path "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists" -ItemType Directory -Force
                }catch{
                  write-ezlogs "An exception occurred creating new directory $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists" -showtime -catcherror $_
                }             
              }
              if([System.IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
                try{
                  $Playlist_Profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"))
                }catch{
                  write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
                }             
              }
              if($Playlist_Profile -and $target_Url){ 
                if($hashsetup.Spotify_Playlists_Import){
                  $hashsetup.window.Dispatcher.Invoke("Normal",[action]{ 
                      if($hashsetup.Spotify_Playlists_Import.isEnabled){
                        $hashsetup.Spotify_Playlists_Import.RaiseEvent([System.Windows.RoutedEventArgs]::New([System.Windows.Controls.Button]::ClickEvent)) 
                      }                                                         
                  })
                }                
                #$playlistName_Cleaned = ([Regex]::Replace($target_playlist.name, $pattern, '')).trim()             
                $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($target_playlist.Playlist_ID).xml"
                write-ezlogs " | Saving new Spotify Playlist profile to $Playlist_Profile_path" -showtime -logtype Spotify -loglevel 3
                $Playlist_Profile.name = $target_playlist.name
                #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                $Playlist_Profile.Playlist_ID = $target_playlist.id
                $Playlist_Profile.Playlist_URL = $target_Url
                $Playlist_Profile.type = $target_playlist.type
                $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                $Playlist_Profile.PlayList_Info = $target_playlist.PlayList_Info
                $Playlist_Profile.Playlist_Date_Added = $([DateTime]::Now.ToString())
                $Playlist_Profile.Source = 'SpotifyAPI'
                Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default
                Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisApp $thisapp                   
              }
            }catch{
              write-ezlogs "An exception occurred adding path $($target_Url) to Spotify_Playlists" -showtime -catcherror $_
            }
          }else{
            $track_to_update = $synchash.All_Spotify_Media.where({$_.id -eq $media.id})
            if($track_to_update.id -and $track_to_update.playlist_id -ne $target_playlist.playlist_id){    
              $track_to_update.playlist_id = $target_playlist.playlist_id 
              $track_to_update.playlist = $target_playlist.name
              $track_to_update.playlist_profile_path = $target_playlist.Playlist_Path  
              $track_to_update.Playlist_url = $target_playlist.Playlist_URL                
              $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')    
              if([System.IO.File]::Exists($AllSpotify_Profile_File_Path)){               
                if($synchash.All_Spotify_Media){
                  write-ezlogs "Updating All Spotify profile cache at $AllSpotify_Profile_File_Path" -showtime       
                  try{  
                    Export-SerializedXML -InputObject $synchash.All_Spotify_Media -Path $AllSpotify_Profile_File_Path
                  }catch{
                    write-ezlogs "An exception occurred saving All Spotify Profile Cache to $AllSpotify_Profile_File_Path" -showtime -catcherror $_
                  }                     
                } 
              }
            }else{
              write-ezlogs "Either couldnt find the track to add or the target playlist already contains media with id $($media.id): $($media | out-string)" -showtime -warning  -logtype Spotify
            }
          }
        }else{
          write-ezlogs "Unable to add track $($Media.title) - ID: $($Media.id) - uri: $($Media.Url) to playlist $($target_playlist.name)- id: $($target_playlist.id)" -showtime -warning  -logtype Spotify
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[System.Windows.Forms.MessageBox]::Show("Unable to add track $($Media.title) to $($target_playlist.name). Check the logs for errors/details or try again later","Spotify Track not added to Playlist!",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unable to add track $($Media.title) to $($target_playlist.name). Check the logs for errors/details or try again later","Spotify Track not added to Playlist!",$okandCancel,$Button_Settings)
          }
          return
        }
      }                 
    }
  }catch{
    write-ezlogs "An exception occurred in Add-Spotify - Media: $($media | out-string)" -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Add-SpotifyPlaylist Function
#----------------------------------------------

#---------------------------------------------- 
#region Remove-SpotifyPlaylist Function
#----------------------------------------------
function Remove-SpotifyPlaylist
{
  Param (
    $thisApp,
    $synchash,
    $media,
    $Sender,
    [switch]$Verboselog
  )
  try{
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
    $pattern = "[™`�$illegal]"   
    $Playlist = $sender.header
    $target_playlist = $synchash.All_Spotify_Media.where({$_.playlist -eq $Playlist})
    if(@($target_playlist).count -gt 1){
      write-ezlogs "Found multiple ($(@($target_playlist).count)) playlists with the name $Playlist" -warning -logtype Spotify
      #TODO: Need to add handling for multipole Spotify lists with same name since they allow it. Need to pass playlist ID
      $target_playlist = $target_playlist | select -last 1
    }
    if([system.io.file]::Exists($($target_playlist.playlist_profile_path))){
      $target_playlist = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($target_playlist.playlist_profile_path))
    }     
    $target_Url = $target_playlist.playlist_url
    $Removeerrors = 0
    foreach($media in $media){
      if($Media.type -match 'Spotify' -or $Media.uri -match 'spotify\:' -or $Media.Source -eq 'Spotify'){     
        write-ezlogs ">>>> Removing track $($Media.title) from Spotify Playlist $($target_playlist.name)" -logtype Spotify
        if($target_playlist.Playlist_ID -and $Media.Url){      
          $remove = Remove-PlaylistItems -Id $target_playlist.Playlist_ID -Track @(@{uri = $Media.Url}) -ApplicationName $thisApp.Config.App_Name
          if($remove){
            write-ezlogs "Removed track $($Media.title) from Spotify Playlist $($target_playlist.name)" -logtype Spotify -Success
            $track_to_update = $synchash.All_Spotify_Media.where({$_.id -eq $media.id -and $_.playlist_id -eq $target_playlist.Playlist_ID})
            if($track_to_update.id -and $target_playlist.Playlist_ID -eq $media.Playlist_ID){
              #$null = $target_playlist.playlist_tracks.Remove($track_to_remove)
              $track_to_update.playlist = $track_to_update.artist  
              $track_to_update.playlist_id = $track_to_update.id
              $track_to_update.playlist_url = ''
              $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')    
              if([System.IO.File]::Exists($AllSpotify_Profile_File_Path)){               
                if($synchash.All_Spotify_Media){
                  write-ezlogs "Updating All Spotify profile cache at $AllSpotify_Profile_File_Path" -showtime -logtype Spotify      
                  try{
                    Export-SerializedXML -InputObject $synchash.All_Spotify_Media -Path $AllSpotify_Profile_File_Path
                  }catch{
                    write-ezlogs "An exception occurred saving All Spotify Profile Cache to $AllSpotify_Profile_File_Path" -showtime -catcherror $_
                  }                     
                } 
              }
              Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -startup -thisApp $thisapp
            }else{
              write-ezlogs "Either couldnt find the track to remove or the target playlist doesnt contain media with id $($media.id): $($media | out-string)" -showtime -warning  -logtype Spotify
            }
          }else{
            $Removeerrors++
          }
        }else{
          write-ezlogs "Unable to remove track $($Media.title) - ID: $($Media.id) - uri: $($Media.Url) from playlist $($target_playlist.name)- id: $($target_playlist.id)" -showtime -warning  -logtype Spotify
          $Removeerrors++
        }
      }                 
    }
    if($Removeerrors -gt 0){
      if($synchash.MediaLibrary_Viewer.isVisible){
        $result=[System.Windows.Forms.MessageBox]::Show("Unable to remove some tracks from $($target_playlist.name). Check the logs for errors/details or try again later","Spotify Tracks not Removed from Playlist!",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
      }else{
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Ok'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
        $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unable to remove some tracks from $($target_playlist.name). Check the logs for errors/details or try again later","Spotify Tracks not Removed from Playlist!",$okandCancel,$Button_Settings)
      }
      return
    }
  }catch{
    write-ezlogs "An exception occurred in Remove-SpotifyPlaylist - Media: $($media | out-string)" -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Remove-SpotifyPlaylist Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-SpotifyStatus Function
#----------------------------------------------
function Get-SpotifyStatus
{
  Param (
    [switch]$Use_runspace,
    $thisApp,
    $synchash,
    $log = $thisapp.config.SpotifyMedia_logfile,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog
  )  
  write-ezlogs "#### Checking for new Spotify playlists" -showtime -logtype Spotify -LogLevel 2 -linesbefore 1    
  try{
    $internet_Connectivity = Test-ValidPath -path 'www.spotify.com' -PingConnection -timeout_milsec 1000
  }catch{
    write-ezlogs "Ping test failed for: www.spotify.com - trying 1.1.1.1" -Warning -logtype Spotify
  }finally{
    try{
      if(!$internet_Connectivity){
        $internet_Connectivity = Test-ValidPath -path '1.1.1.1' -PingConnection -timeout_milsec 2000
      }
    }catch{
      write-ezlogs "Secondary ping test failed for: 1.1.1.1" -Warning -logtype Spotify
      $internet_Connectivity = $null
    }
  }
  if($internet_Connectivity){
    try{      
      if($thisApp.Config.Import_Spotify_Media){       
        $checkSpotify_scriptblock = {   
          Param(
            $thisApp = $thisApp,
            $synchash = $synchash,
            [string]$log = $log
          ) 
          try{
            $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
            $pattern = "[™$illegal]"
            $pattern2 = "[:$illegal]"
            $pattern3 = "[`?�™:$illegal]"    
            try{
              $Spotify_playlists = Get-CurrentUserPlaylists -ApplicationName $thisApp.config.App_Name -thisApp $thisApp
            }catch{
              write-ezlogs "An exception occurred retrieving Spotify playlists with Get-CurrentUserPlaylists" -showtime -catcherror $_
            } 
            $newplaylists = 0
            $newtracks = 0
            $removedtracks = 0
            $SpotifyPlaylists_itemsArray = [System.Collections.Generic.List[Object]]::new()
            $Spotify_Playlist_Update = [System.Collections.Generic.List[Object]]::new()
            if($Spotify_playlists){        
              $Spotify_playlists | foreach { 
                $playlist = $_
                $existingplaylistcount = $Null     
                $playlistcount = $null             
                $playlisturl = $playlist.uri
                $playlistName = $playlist.name
                $playlistcount = $playlist.tracks.total
                try{
                  #$encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.id)-$($Playlist_ID)")
                  #$encodedid = [System.Convert]::ToBase64String($encodedBytes)  
                  $existingplaylist_tracks = Get-IndexesOf $synchash.All_Spotify_Media.playlist_id -Value $playlist.id | & { process { 
                      $synchash.All_Spotify_Media[$_]
                  }}
                  #$existingplaylist_tracks = ($synchash.All_Spotify_Media.where({$_.Playlist_id -eq $playlist.id}))                     
                  if([System.IO.File]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml")){
                    try{
                      $playlist_profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml"))
                    }catch{
                      write-ezlogs "An exception occurred importing profile $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml" -showtime -catcherror $_
                    }         
                  }
                  if($playlist_profile.Playlist_Info.tracks){
                    $existingplaylistcount = $playlist_profile.Playlist_Info.tracks.total
                    if($playlist_profile.Playlist_Info.tracks.total -ne $playlist.tracks.total){
                      write-ezlogs ">>>> Updating saved Playlist Profile with latest info from API" -logtype Spotify
                      try{
                        $playlist_profile.Playlist_Info = $playlist
                        Export-Clixml -InputObject $playlist_profile -Path "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml" -Force -Encoding Default
                      }catch{
                        write-ezlogs "An exception occurred exporting profile $($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml" -showtime -catcherror $_
                      }  
                    }
                  }else{
                    $existingplaylistcount = $existingplaylist_tracks.count
                  }
                }catch{
                  $existingplaylistcount = $Null
                  $playlistcount = $Null
                  write-ezlogs "An exception occurred enumerating All_Spotify_Media for playlist_id $($playlist.id)" -catcherror $_
                }                          
                if($SpotifyPlaylists_itemsArray.path -notcontains $playlisturl){
                  if(!$SpotifyPlaylists_itemsArray.Number){ 
                    $Number = 1
                  }else{
                    $Number = $SpotifyPlaylists_itemsArray.Number | select -last 1
                    $Number++
                  }
                  $itemssource = [PSCustomObject]::new(@{
                      Number=$Number;       
                      ID = $playlist.id
                      Name=$playlistName
                      Path=$playlisturl
                      Type='SpotifyPlaylist'
                      Playlist_Info = $playlist
                  })
                  $null = $SpotifyPlaylists_itemsArray.add($itemssource)  
                }
                if($thisApp.Config.Spotify_Playlists -notcontains $playlisturl){
                  $newplaylists++
                }elseif($playlistcount -gt $existingplaylistcount){
                  $newtracks += ($playlistcount - $existingplaylistcount)
                  if($Spotify_Playlist_Update -notcontains $playlisturl){
                    $Null = $Spotify_Playlist_Update.add($playlisturl)
                    write-ezlogs ">>>> Playlist $($playlistName) has new tracks - New Count: $playlistcount - Existing: $existingplaylistcount - Playlist URL: $($playlisturl)" -logtype Spotify
                  }                
                }elseif($existingplaylistcount -gt $playlistcount){
                  $removedtracks += ($existingplaylistcount - $playlistcount)
                  if($Spotify_Playlist_Update -notcontains $playlisturl){
                    $Null = $Spotify_Playlist_Update.add($playlisturl)
                    write-ezlogs ">>>> Playlist $($playlistName) has removed tracks - New Count: $playlistcount - Existing: $existingplaylistcount - Playlist URL: $($playlisturl)" -logtype Spotify
                  }
                }
              }
            }
            #Custom/Imported Playlists
            if($synchash.all_playlists){
              foreach($custom_playlist_Profile in $synchash.all_playlists){
                try{
                  if(($custom_playlist_Profile.gettype()).name -eq 'ArrayList'){
                    $custom_playlist_Profile = $custom_playlist_Profile | select *
                  }
                  $Changes = 0
                  foreach($list in $custom_playlist_Profile.PlayList_tracks.values | Where-Object {$_.Playlist_URL -match 'spotify\:'}){
                    $customplaylist_Name = $Null                
                    if($list.Playlist_URL){
                      #$customplaylist_Name = $SpotifyPlaylists_itemsArray | where {$_.path -eq $list.Playlist_URL}
                      $customplaylist_Name = $SpotifyPlaylists_itemsArray | & { process {if ($_.path -eq $list.Playlist_URL -or $_.id -eq $list.Playlist_ID){$_}}}
                      if($customplaylist_Name.name -and $customplaylist_Name.name -ne $list.Playlist){
                        write-ezlogs "| Updating Spotify playlist table name from: $($list.Playlist) - to: $($customplaylist_Name.name) - ID: $($list.playlist_id)" -showtime -logtype Spotify
                        $list.Playlist = $customplaylist_Name.Name
                        $Changes++
                      }
                      if($customplaylist_Name.id -and $customplaylist_Name.id -ne $list.Playlist_ID){
                        if(($synchash.all_playlists.Playlist_ID.IndexOf($list.Playlist_ID)) -eq -1){
                          write-ezlogs "| Updating Spotify playlist table playlist_id from: $($list.Playlist_ID) - to: $($customplaylist_Name.id)" -showtime -logtype Spotify
                          $list.Playlist_ID = $customplaylist_Name.id
                          $Changes++    
                        }
                      }
                      if($customplaylist_Name.Path -and $customplaylist_Name.Path -ne $list.Playlist_url){
                        write-ezlogs "| Updating Spotify playlist table url from: $($list.Playlist_url) - to: $($customplaylist_Name.Path)" -showtime -logtype Spotify
                        $list.Playlist_url = $customplaylist_Name.Path 
                        $Changes++  
                      }
                      if($SpotifyPlaylists_itemsArray.path -notcontains $list.Playlist_URL){
                        if(!$SpotifyPlaylists_itemsArray.Number){ 
                          $Number = 1
                        }else{
                          $Number = $SpotifyPlaylists_itemsArray.Number | select-Object -last 1
                          $Number++
                        }
                        if([system.io.file]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($list.Playlist_ID).xml")){
                          $Custom_playlist = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($list.Playlist_ID).xml"))
                        }
                        $itemssource = [PSCustomObject]::new(@{
                            Number=$Number    
                            ID = $list.Playlist_ID
                            Name=$list.Playlist
                            Path=$list.Playlist_URL
                            Type='SpotifyPlaylist'
                            Playlist_Info = $Custom_playlist.Playlist_Info
                        })
                        $null = $SpotifyPlaylists_itemsArray.add($itemssource)
                      }
                    }   
                  }
                }catch{
                  write-ezlogs "An exception occurred parsing custom playlists: $($custom_playlist_Profile)" -showtime -catcherror $_
                }
              }
              if($Changes -gt 0){            
                write-ezlogs ">>>> Saving all_playlists library to: $($thisApp.Config.Playlists_Profile_Path)" -logtype Spotify
                Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
              }
            }
            #Check for playlists that no longer exist   
            $playlists_toRemove = $thisApp.Config.Spotify_Playlists | Where-Object {$SpotifyPlaylists_itemsArray.path -notcontains $_}
            if($newplaylists -le 0 -and $playlists_toRemove.count -le 0 -and $newtracks -le 0 -and $removedtracks -le 0){
              write-ezlogs "No changes to Spotify playlists were found" -showtime -warning -logtype Spotify
              return
            }else{
              write-ezlogs "Found $newplaylists playlists, $($newtracks) new playlist tracks, $removedtracks removed playlist tracks -- found $($playlists_toRemove.count) playlists to remove" -showtime -logtype Spotify
            }           
            $newSpotifyMediaCount = 0
            if([System.IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
              try{
                $Playlist_Profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"))
              }catch{
                write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
              }             
            } 
            foreach($playlist in $SpotifyPlaylists_itemsArray){
              if($playlist.path){
                if($thisApp.Config.Spotify_Playlists -notcontains $playlist.path){
                  try{
                    write-ezlogs " | Adding new Spotify Playlist URL: $($playlist.path) - Name: $($playlist.Name)" -showtime -logtype Spotify -LogLevel 2
                    $null = $thisApp.Config.Spotify_Playlists.add($playlist.path)
                    if($Playlist_Profile -and $playlist.path){  
                      if($playlist.Name){
                        $playlist_Name = $playlist.name
                      }else{
                        $playlist_Name = "Custom_$($playlist.id)"
                      }    
                      #$playlistName_Cleaned = ([Regex]::Replace($playlist_Name, $pattern3, '')).trim()            
                      $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Spotify_Playlists\$($playlist.id).xml"
                      write-ezlogs " | Saving new Spotify Playlist profile to $Playlist_Profile_path" -showtime -logtype Spotify -LogLevel 2
                      $Playlist_Profile.name = $playlist_Name
                      #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                      $Playlist_Profile.Playlist_ID = $playlist.id
                      $Playlist_Profile.Playlist_URL = $playlist.path
                      $Playlist_Profile.type = $playlist.type
                      $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                      $Playlist_Profile.Playlist_Date_Added = [DateTime]::Now.ToString()
                      if($playlist.playlist_info.id){
                        $Playlist_Profile.Source = 'SpotifyAPI'
                        Add-Member -InputObject $Playlist_Profile -Name 'Playlist_Info' -Value $playlist.playlist_info -MemberType NoteProperty -Force
                      }else{
                        $Playlist_Profile.Source = 'Custom'
                      }  
                      Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default               
                    }
                    $newSpotifyMediaCount++  
                  }catch{
                    write-ezlogs "An exception occurred adding path $($playlist.path) to Spotify_Playlists" -showtime -catcherror $_
                  }
                }            
              }else{        
                write-ezlogs "The provided Spotify playlist URL $($playlist.path) is invalid!" -showtime -warning -logtype Spotify
              } 
            }
            #Remove playlists that no longer exist
            $AllSpotify_Media_Profile_File_Path = [System.IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Spotify_MediaProfile","All-Spotify_Media-Profile.xml")  
            if($playlists_toRemove){
              if([System.IO.File]::Exists($AllSpotify_Media_Profile_File_Path)){
                write-ezlogs " | Importing All Spotify Media profile cache at $AllSpotify_Media_Profile_File_Path" -showtime -logtype Spotify
                $all_Spotifymedia_profile = Import-SerializedXML -Path $AllSpotify_Media_Profile_File_Path
                #[System.Collections.Generic.List[Object]]$all_Spotifymedia_profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($AllSpotify_Media_Profile_File_Path))
              }              
              foreach($playlist_path in $playlists_toRemove){
                write-ezlogs " | Removing Spotify Playlist $($playlist_path)" -showtime -logtype Spotify -LogLevel 2
                $null = $thisApp.Config.Spotify_Playlists.Remove($playlist_path)
              }
              try{
                Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
              }catch{
                write-ezlogs "[Get-SpotifyStatus] An exception occurred saving config file to path $($thisApp.Config.Config_Path)" -showtime -catcherror $_
              }            
              $all_Spotifymedia_profile = $all_Spotifymedia_profile | where-Object {$SpotifyPlaylists_itemsArray.id -contains $_.playlist_id}
              write-ezlogs "Updating All Spotify Media profile cache at $AllSpotify_Media_Profile_File_Path" -showtime -logtype Spotify
              Export-SerializedXML -InputObject $all_Spotifymedia_profile -Path $AllSpotify_Media_Profile_File_Path
            }
            if($newSpotifyMediaCount -gt 0 -or $playlists_toRemove -or $newtracks -gt 0 -or $removedtracks -gt 0){
              if($hashsetup.Spotify_Playlists_Import -and $hashsetup.window){
                write-ezlogs ">>>> Invoking click event for Spotify_Playlists_Import" -showtime -logtype Spotify 
                $hashsetup.window.Dispatcher.Invoke("Normal",[action]{ 
                    if($hashsetup.Spotify_Playlists_Import.isEnabled){
                      $hashsetup.Spotify_Playlists_Import.RaiseEvent([System.Windows.RoutedEventArgs]::New([System.Windows.Controls.Button]::ClickEvent)) 
                    }                                                         
                })
              }                 
              if($synchash.Refresh_SpotifyMedia_timer){
                write-ezlogs ">>>> Executing Refresh_SpotifyMedia_timer to refresh Spotify library" -showtime -logtype Spotify       
                $synchash.Refresh_SpotifyMedia_timer.tag = 'Get-SpotifyStatus'
                $synchash.Refresh_SpotifyMedia_timer.start()
              }
            }elseif($thisApp.Config.Spotify_Playlists.count -eq 0){
              write-ezlogs ">>>> Spotify Playlists count is 0 - clearing Spotify library table itemssource" -showtime -logtype Spotify
              Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'SpotifyTable' -Property 'itemssource' -value $Null -ClearValue
            }                                                           
          }catch{
            write-ezlogs "An exception occurred in checkSpotify_scriptblock" -showtime -catcherror $_
          }                                                              
        } 
        if($Use_runspace){
          $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
          Start-Runspace $checkSpotify_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "checkSpotify_runspace" -thisApp $thisApp
          $Variable_list = $Null
        }else{
          Invoke-Command -ScriptBlock $checkSpotify_scriptblock
        }
        $checkSpotify_scriptblock = $Null                         
      }else{
        write-ezlogs "Unable to refresh Spotify playlists, Spotify importing is not enabled!" -showtime -warning -logtype Spotify -LogLevel 2
      }
    }catch{
      write-ezlogs "An exception occurred getting Spotify playlists and tracks!" -showtime -catcherror $_
    }  
  }else{
    write-ezlogs "Canot check status of Spotify Playlists, unable to connect to 'www.Spotify.com'" -warning -AlertUI
  }
}
#---------------------------------------------- 
#endregion Get-SpotifyStatus Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-SpotifyMonitor Function
#----------------------------------------------
function Start-SpotifyMonitor
{
  Param (
    $Interval,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Stop,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging
  ) 
  write-ezlogs "#### Starting Spotify Monitor ####" -enablelogs -color yellow -linesbefore 1 -logtype Spotify -LogLevel 2
  if($thisApp.config.Spotify_Update_Interval -eq 'On Startup'){
    $thisApp.SpotifyMonitorEnabled = $false
    write-ezlogs "Cannot start Spotify monitor, Spotify_Update_Interval is set to 'On Startup'" -logtype Spotify -warning   
    return
  }  
  $Sleep_Value = [TimeSpan]::Parse($Interval).TotalSeconds
  $Spotify_Status_Monitor_Scriptblock = {
    Param (
      $Interval,
      $thisApp,
      $synchash,
      [switch]$Startup,
      [switch]$Stop,
      [switch]$Verboselog
    )
    $ProgressPreference = 'SilentlyContinue'
    $Spotify_Monitor_Timer = 0
    try{      
      $Sleep_Value = [TimeSpan]::Parse($Interval).TotalSeconds
      write-ezlogs " | Interval Seconds: $sleep_value" -showtime -logtype Spotify -LogLevel 2
      $LastUpdate_Spotify_Monitor_Timer = [datetime]::Now
      if($thisApp.SpotifyMonitorEnabled){
        $thisApp.SpotifyMonitorEnabled = $false
        start-sleep 1
      }
      $thisApp.SpotifyMonitorEnabled = $true
      $HasRunYet = $false
      while($thisApp.config.Spotify_Update -and $thisApp.config.Spotify_Update_Interval -ne $null -and $thisApp.SpotifyMonitorEnabled){            
        $Sleep_Value = [TimeSpan]::Parse($thisApp.config.Spotify_Update_Interval).TotalSeconds
        if([datetime]::Now -ge $LastUpdate_Spotify_Monitor_Timer.AddSeconds($Sleep_Value) -or !$HasRunYet){
          try{
            $HasRunYet = $true
            $checkupdate_timer = [system.diagnostics.stopwatch]::StartNew()
            Get-SpotifyStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -Use_runspace:$false
            Write-ezlogs "[Start-SpotifyMonitor] Ran for: $($checkupdate_timer.Elapsed.TotalSeconds) seconds" -showtime -logtype Spotify -LogLevel 2
          }catch{
            write-ezlogs "An exception occurred executing Get-SpotifyStatus" -showtime -catcherror $_
          }finally{
            $LastUpdate_Spotify_Monitor_Timer = [datetime]::Now
            $checkupdate_timer.Restart()
          }
        }
        $Spotify_Monitor_Timer++
        start-sleep -Seconds 1
        #start-sleep -Seconds $Sleep_Value
      }
      if(!$thisApp.config.Spotify_Update){
        write-ezlogs "Spotify Monitor ended due to Spotify_Update option being disabled - It ran for $($Spotify_Monitor_Timer) seconds" -showtime -warning -logtype Spotify -LogLevel 2
      }else{
        write-ezlogs "Spotify Monitor has ended - It ran for $($Spotify_Monitor_Timer) seconds" -showtime -warning -logtype Spotify -LogLevel 2
      }
    }catch{
      write-ezlogs "An exception occurred in Spotify_status_Monitor_Scriptblock" -showtime -catcherror $_
    }
  }
  if($thisApp.config.Spotify_Update -and $Sleep_Value -ne $null){
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}} 
    Start-Runspace $Spotify_Status_Monitor_Scriptblock -arguments $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Spotify_Monitor_Runspace" -thisApp $thisApp
    Remove-Variable Variable_list
    Remove-Variable Spotify_Status_Monitor_Scriptblock
  }else{
    write-ezlogs "No sleep value was provided or found, cannot continue" -showtime -warning -logtype Spotify -LogLevel 2
  }
}
#---------------------------------------------- 
#endregion Start-SpotifyMonitor Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-SpotifyMedia Function
#----------------------------------------------
function Update-SpotifyMedia
{
  param (
    $InputObject,
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    [string]$TotalCount,
    [switch]$Refresh_All_Media,
    [switch]$update_Library,
    [switch]$UpdatePlaylists,
    $thisApp,
    $all_Playlists,
    $UpdateMedia,
    [switch]$SkipGetMedia
  )
  $update_SpotifyMedia_scriptblock = {
    $update_SpotifyMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    $synchash = $synchash
    $thisApp = $thisApp
    $update_Library = $update_Library
    $UpdateMedia = $UpdateMedia
    $UpdatePlaylists = $UpdatePlaylists
    try{
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
      #Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Spotify\Get-Spotify.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
      if($synchash.All_Spotify_Media.count -gt 0){
        $AllSpotify_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-Spotify_Profile")
        $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($AllSpotify_Profile_Directory_Path,"All-Spotify_Media-Profile.xml")
        if($UpdateMedia.id){
          write-ezlogs ">>>> Updating Spotify media with id: $($UpdateMedia.id)"  
          $media_to_Update = foreach($Media in $UpdateMedia){
            Get-IndexesOf $synchash.All_Spotify_Media.id -Value $Media.id | & { process {
                $synchash.All_Spotify_Media[$_]
            }}   
          }
        }else{
          write-ezlogs ">>>> Updating all Spotify media"
          $media_to_Update = $synchash.All_Spotify_Media
        }
        $TotalCount = @($media_to_Update).count
        write-ezlogs "####################### Executing Update-SpotifyMedia for $($TotalCount) media" -linesbefore 1 -logtype Spotify
        if(!([System.IO.Directory]::Exists($AllSpotify_Profile_Directory_Path))){
          [void][System.IO.Directory]::CreateDirectory($AllSpotify_Profile_Directory_Path)
        } 
        if($media_to_Update){
          if($UpdatePlaylists -and $synchash.all_playlists){
            if($synchash.all_playlists -isnot [System.Collections.Generic.List[Playlist]]){
              $all_Playlists = $synchash.all_playlists | ConvertTo-Playlists -List
            }else{
              $all_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchash.all_playlists)
            }
            $media_to_Update | & { process {
                if($_.url){
                  try{
                    $Media = $_
                    $all_Playlists | & { process {
                        $playlist = $_
                        $Changes = $false
                        $track_index = $Null
                        $track = $null
                        try{
                          $urls = [System.Collections.Generic.list[object]]$playlist.PlayList_tracks.values.url
                          if($urls){
                            $track_index = $urls.indexof($Media.url)
                          }
                          if($track_index -ne -1 -and $track_index -ne $null){
                            #$track = $playlist.PlayList_tracks[$track_index]
                            $track = $playlist.PlayList_tracks.Values | Where-Object {$_.url -eq $Media.url}
                            if($track){
                              foreach ($property in $Media.psobject.properties.name){
                                if([bool]$track.PSObject.Properties[$property] -and $track.$property -ne $Media.$property){
                                  if($thisApp.Config.Dev_mode){write-ezlogs " | Updating track property: '$($property)' from value: '$($track.$property)' - to: '$($Media.$property)'"  -Dev_mode -logtype Spotify}
                                  $track.$property = $Media.$property
                                  $Changes = $true
                                }elseif(-not [bool]$track.PSObject.Properties[$property]){
                                  write-ezlogs " | Adding track property: '$($property)' with value: $($Media.$property)" -logtype Spotify
                                  $Changes = $true
                                  $track.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new($property,$Media.$property))
                                }
                              }
                              if($Changes){
                                $UpdatePlaylists = $true
                              }
                            }
                          }
                        }catch{
                          write-ezlogs "[Update-SpotifyMedia] An exception occurred processing playlist: $($playlist | out-string)" -CatchError $_
                        }finally{
                          $track = $Null
                        }
                    }}                 
                  }catch{
                    write-ezlogs "[Update-SpotifyMedia] An exception occurred attempting to lookup and update playlist tracks with url: $($Media.url)" -CatchError $_
                  } 
                }
            }} 
          }
          if($AllSpotify_Profile_File_Path){
            write-ezlogs ">>>> Exporting All Spotify Profile cache to file $($AllSpotify_Profile_File_Path)" -showtime -color cyan -logtype Spotify -LogLevel 3
            Export-SerializedXML -Path $AllSpotify_Profile_File_Path -InputObject $synchash.All_Spotify_Media
          }
          if($UpdatePlaylists -and $all_Playlists){
            Export-SerializedXML -InputObject $all_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Playlists\Get-Playlists.psm1" -NoClobber -DisableNameChecking -Scope Local
            Get-Playlists -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Import_Playlists_Cache -Quick_Refresh
            [void]$all_Playlists.clear()
            $all_Playlists = $Null
          }
          if($update_SpotifyMedia_Measure){
            $update_SpotifyMedia_Measure.stop()
            write-ezlogs "####################### Update-SpotifyMedia Processing Finished #######################" -PerfTimer $update_SpotifyMedia_Measure -Perf -GetMemoryUsage -forceCollection -PriorityLevel 3
            $update_SpotifyMedia_Measure = $null
          }
        }else{
          write-ezlogs "No Spotify Media was found to process!" -logtype Spotify -LogLevel 2 -warning
        }
      }else{
        write-ezlogs "No Spotify Media was found to process!" -logtype Spotify -LogLevel 2 -warning
      }
    }catch{
      write-ezlogs "An exception occurred in update-Spotifymedia scriptblock" -catcherror $_
    }finally{
      if($synchash.Refresh_SpotifyMedia_timer -and $update_Library){
        write-ezlogs ">>>> Executing Refresh_SpotifyMedia_timer for Update-SpotifyMedia"
        $synchash.Refresh_SpotifyMedia_timer.tag = 'QuickRefresh_SpotifyMedia_Button'
        $synchash.Refresh_SpotifyMedia_timer.start()
      }
      Remove-Module -Name "Write-EZLogs" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "Set-WPFControls" -Force -ErrorAction SilentlyContinue
      #Remove-Module -Name "Get-Spotify" -Force -ErrorAction SilentlyContinue
      Remove-module -Name "Get-HelperFunctions" -Force -ErrorAction SilentlyContinue
      #Remove-module -Name "PSParallel" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "PSSerializedXML" -Force -ErrorAction SilentlyContinue
    }
  }
  try{
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $update_SpotifyMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'update_SpotifyMedia_Runspace' -thisApp $thisApp -synchash $synchash -CheckforExisting -RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
    $update_LocalMedia_scriptblock = $Null
    $Variable_list = $Null
  }catch{
    write-ezlogs "An exception occurred in Update-SpotifyMedia" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Update-SpotifyMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Spotify','Add-SpotifyPlaylist','Remove-SpotifyPlaylist','Get-SpotifyStatus','Start-SpotifyMonitor','Update-SpotifyMedia')