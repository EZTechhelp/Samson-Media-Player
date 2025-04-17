<#
    .Name
    Get-Plex

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves API authentication for connection and integration to Plex Media Server and Services

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
#region Get-PlexToken Function
#----------------------------------------------
function Get-PlexToken {
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [String]$Name = $thisApp.Config.App_Name,
    [switch]$VerboseLog
  )
  try{
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Web')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Net.Http')
    $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "An exception occurred getting SecretStore $name" -showtime -catcherror $_
    return
  }
  if(!$SecretStore){
    try{
      Write-ezlogs "No SecretStore found called $Name" -warning -showtime
      write-ezlogs ">>>> Setting new SecretStoreConfiguration with password set to $Name (Scope: CurrentUser)" -showtime
      Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
      write-ezlogs ">>>> Registering new SecretVault: $name" -showtime
      $secretstore = Register-SecretVault -Name $Name -ModuleName "$($thisApp.Config.Current_Folder)\Modules\Microsoft.PowerShell.SecretStore" -DefaultVault -Description "Created by $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -PassThru
    }catch{
      write-ezlogs "An exception occurred registering new secretvault with name $Name" -catcherror $_
    }
  }
  if($secretstore){ 
    try{
      $access_token = Get-secret -name PlexAccessToken -Vault $Name -ErrorAction SilentlyContinue
      $expires = Get-secret -name PlexExpires -Vault $Name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting Secret Amazonaccess_token" -showtime -catcherror $_
    }

    #VerifyToken
    try{
      $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
      $MachineGuid = $Registry.OpenSubKey("SOFTWARE\Microsoft\Cryptography").GetValue("MachineGuid")
      $UniqueID = [System.Guid]::Parse($MachineGuid).ToString("N")
      if($access_token -and $expires -and (Get-date) -le (Get-date $expires)){
        $req=[System.Net.HTTPWebRequest]::Create("https://plex.tv/api/v2/user")
        $req.Method='GET'
        $req.ContentType = 'application/json'
        $req.Accept = 'application/json'
        $headers = [System.Net.WebHeaderCollection]::new()
        $headers.add("X-Plex-Client-Identifier",$UniqueID)
        $headers.add("X-Plex-Product", 'EZT-MediaPlayer')
        $headers.add("X-Plex-Token",$access_token)
        $req.Headers = $headers
        $response = $req.GetResponse()
        $strm=$response.GetResponseStream()
        $sr=[System.IO.Streamreader]::new($strm)
        $output=$sr.ReadToEnd()
        $AuthResponse = [xml]$output
      }
    }catch{
      write-ezlogs "An exception occured verifying Plex user token" -CatchError $_
    }finally{
      if($response){
        $response.Dispose()
      }
      if($strm){
        $strm.Dispose()
      }  
      if($sr){
        $sr.Dispose()
      }
      if($Registry -is [System.IDisposable]){
        $Registry.dispose()
      }
      $req = $Null
    }
    if($AuthResponse.user.authToken){
      if($VerboseLog){write-ezlogs ">>>> Plex access token is still valid" -showtime -Dev_mode:$VerboseLog}
      return $AuthResponse.user.authToken
    }else{
      write-ezlogs "Plex access token not valid - starting pin code authorization" -warning
      #Get PIN CODE
      $client = [System.Net.Http.HttpClient]::new()
      $client.DefaultRequestHeaders.Add("Accept", "application/json")
      $client.DefaultRequestHeaders.Add("X-Plex-Client-Identifier", $UniqueID)
      $client.DefaultRequestHeaders.Add("X-Plex-Product", "$($thisApp.Config.App_Name) Media Player")
      $authPostContent = @{
        "strong" = "true"
      } | Convertto-Json
      $authResponse = $client.PostAsync("https://plex.tv/api/v2/pins",[System.Net.Http.StringContent]::new($authPostContent,[System.Text.Encoding]::UTF8,"application/json")) | Wait-Task
      $authResponseContent = $authResponse.content.ReadAsStringAsync() | Wait-Task
      $authData = $authResponseContent | Convertfrom-Json
      if($AuthData.id -and $AuthData.Code){
        write-ezlogs "| Starting Plex Pin approval in end user browser"
        $MahDialog_hash = Show-WebLogin -SplashTitle "Plex Account Login" -SplashLogo "$($thisApp.Config.Current_Folder)\Resources\Youtube\Material-Youtube_Auth.png" -Message 'Login to your Plex account to approve access for this application' -WebView2_URL "https://app.plex.tv/auth#?clientID=$UniqueID&code=$($authData.code)&context%5Bdevice%5D%5Bproduct%5D=Plex Web" -thisApp $thisApp -MahDialog_hash $MahDialog_hash
        $wait = 0
        while(!$MahDialog_hash.Window.isVisible){
          write-ezlogs ">>>> Waiting for Plex WebLogin window to open..." -showtime -LogLevel 2
          start-sleep -Milliseconds 500
        }
        while($MahDialog_hash.Window.isVisible -and $wait -lt 600){
          write-ezlogs ">>>> Waiting for Plex WebLogin window to close..." -showtime -LogLevel 2
          $wait++
          start-sleep 1
        }
        #CheckPinResponse
        try{
          $req=[System.Net.HTTPWebRequest]::Create("https://plex.tv/api/v2/pins/$($authData.id)")
          $req.Method='GET'
          $req.ContentType = 'application/json'
          $req.Accept = 'application/json'
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add("X-Plex-Client-Identifier",$UniqueID)
          $headers.add("code",$authData.code)
          $req.Headers = $headers
          $response = $req.GetResponse()
          $strm=$response.GetResponseStream()
          $sr=[System.IO.Streamreader]::new($strm)
          $output=$sr.ReadToEnd()
          $PinResponse = [xml]$output
        }catch{
          write-ezlogs "An exception occured verifying Plex pin approval" -CatchError $_
        }finally{
          if($response){
            $response.Dispose()
          }
          if($strm){
            $strm.Dispose()
          }  
          if($sr){
            $sr.Dispose()
          }
          $req = $Null       
        } 
      }
      if($PinResponse.pin.authToken -and $PinResponse.pin.expiresAt){
        try{        
          $Expires = (Get-Date $($PinResponse.pin.expiresAt -replace 'UTC','Z') -Format U).ToString()
          write-ezlogs "Received valid Plex Authorization code - Expires: $($Expires)" -Success
          Set-Secret -Name PlexAccessToken  -Secret "$($PinResponse.pin.authToken)" -Vault $Name
          Set-Secret -Name PlexExpires  -Secret "$($Expires)" -Vault $Name
          return $PinResponse.pin.authToken
        }catch{
          write-ezlogs "An exception occurred getting Secrets for AmazonAccess_Token" -showtime -catcherror $_
        }        
      }else{
        write-ezlogs "Unable to get valid Plex Access Token!" -showtime -warning
      } 
    }
  }else{
    Write-ezlogs "No SecretStore found called $Name" -warning -showtime
  }
}
#---------------------------------------------- 
#endregion Get-PlexToken Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-PlexLibraries Function
#----------------------------------------------
function Get-PlexLibraries {
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [string]$PlexMediaServer = '192.168.50.2',
    [string]$PlexMediaServerPort = '32400',
    [switch]$VerboseLog
  )
  if(!$PlexMediaServer){
    write-ezlogs "No Plex Media Server was provided, will default to local" -warning
    $PlexMediaServer = '127.0.0.1'
  }
  if(!$PlexMediaServerPort){
    write-ezlogs "No Plex Media Server port was provided, will default to: 32400" -warning
    $PlexMediaServerPort = '32400'
  }
  try{
    write-ezlogs ">>>> Getting all available Plex libraries from Plex Media Server: $($PlexMediaServer):$($PlexMediaServerPort)"
    $Token = Get-PlexToken -thisApp $thisApp
  }catch{
    write-ezlogs "An exception occured executing Get-PlexToken" -CatchError $_
  }
  try{
    if($Token){
      $req=[System.Net.HTTPWebRequest]::Create("http://$($PlexMediaServer):$($PlexMediaServerPort)/library/sections?X-Plex-Token=$Token")
      $req.Method='GET'
      $req.ContentType = 'application/json'
      $req.Accept = 'application/json'
      $response = $req.GetResponse()
      $strm=$response.GetResponseStream()
      $sr=[System.IO.Streamreader]::new($strm)
      $output=$sr.ReadToEnd() | Convertfrom-json -ErrorAction SilentlyContinue
      #$AuthResponse = [xml]$output
      if($output.MediaContainer){
        if($VerboseLog){write-ezlogs "| Found $($output.MediaContainer.size) Plex libraries" -showtime -Dev_mode:$VerboseLog}
        return $output.MediaContainer
      }
    }else{
      write-ezlogs "Cannot lookup Plex libraries - no valid token was provided!" -Warning
    }
  }catch{
    write-ezlogs "An exception occured getting list of Plex libraries" -CatchError $_
  }finally{
    if($response){
      $response.Dispose()
    }
    if($strm){
      $strm.Dispose()
    }  
    if($sr){
      $sr.Dispose()
    }
    $req = $Null
  }
}
#---------------------------------------------- 
#endregion Get-PlexLibraries Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-PlexLibraryContent Function
#----------------------------------------------
function Get-PlexLibraryContent {
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [string]$PlexMediaServer = '192.168.50.2',
    [string]$PlexMediaServerPort = '32400',
    $Libraries,
    [switch]$VerboseLog
  )
  if(!$PlexMediaServer){
    write-ezlogs "No Plex Media Server was provided, will default to local" -warning
    $PlexMediaServer = '127.0.0.1'
  }
  if(!$PlexMediaServerPort){
    write-ezlogs "No Plex Media Server port was provided, will default to: 32400" -warning
    $PlexMediaServerPort = '32400'
  }
  try{
    write-ezlogs ">>>> Getting Plex Library Content from Plex Media Server: $($PlexMediaServer):$($PlexMediaServerPort)"
    $Token = Get-PlexToken -thisApp $thisApp
  }catch{
    write-ezlogs "An exception occured executing Get-PlexToken" -CatchError $_
  }
  try{
    if($Token){
      if(!$Libraries){
        $Libraries = Get-PlexLibraries -thisApp $thisApp
      }
      if($Libraries){
        write-ezlogs "| Getting content for $($Libraries.size) Plex Libraries"
        $LibrariesOutput = $Libraries.Directory | & { process {
            try{
              $SectionKey = $_.key
              $req=[System.Net.HTTPWebRequest]::Create("http://$($PlexMediaServer):$($PlexMediaServerPort)/library/sections/$SectionKey/all?X-Plex-Token=$Token")
              $req.Method='GET'
              $req.ContentType = 'application/json'
              $req.Accept = 'application/json'
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd() | Convertfrom-json -ErrorAction SilentlyContinue
              if($output.MediaContainer){
                $output.MediaContainer
              }else{
                write-ezlogs "No content or metadata found for Plex Library $($SectionKey)" -warning
              }
            }catch{
              write-ezlogs "An exception occured getting list of Plex libraries" -CatchError $_
            }finally{
              if($response){
                $response.Dispose()
              }
              if($strm){
                $strm.Dispose()
              }  
              if($sr){
                $sr.Dispose()
              }
              $req = $Null
            }
        }}
        $LibrariesOutput
      }else{
        write-ezlogs "Cannot get Plex Library content - no valid Plex libraries provided or found!" -warning
      }
    }else{
      write-ezlogs "Cannot get Plex Library content - no valid token was provided!" -Warning
    }
  }catch{
    write-ezlogs "An exception occured executing Get-PlexLibraryContent" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Get-PlexLibraryContent Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-PlexItemDetails Function
#----------------------------------------------
function Get-PlexItemDetails {
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [string]$PlexMediaServer = '192.168.50.2',
    [string]$PlexMediaServerPort = '32400',
    [string]$ItemKey,
    [string]$Item,
    [switch]$VerboseLog
  )
  if(!$PlexMediaServer){
    write-ezlogs "No Plex Media Server was provided, will default to local" -warning
    $PlexMediaServer = '127.0.0.1'
  }
  if(!$PlexMediaServerPort){
    write-ezlogs "No Plex Media Server port was provided, will default to: 32400" -warning
    $PlexMediaServerPort = '32400'
  }
  if(!$ItemKey -and $item.key){
    $ItemKey = $item.key
  }  
  if(!$ItemKey){
    write-ezlogs "Cannot get Plex item details, no item key was provided!" -warning
    return
  }
  try{
    write-ezlogs ">>>> Getting Item Details from Plex Media Server: $($PlexMediaServer):$($PlexMediaServerPort)"
    $Token = Get-PlexToken -thisApp $thisApp
  }catch{
    write-ezlogs "An exception occured executing Get-PlexToken" -CatchError $_
  }
  try{
    if($Token){
      $req=[System.Net.HTTPWebRequest]::Create("http://$($PlexMediaServer):$($PlexMediaServerPort)$($ItemKey)?X-Plex-Token=$Token")
      $req.Method='GET'
      $req.ContentType = 'application/json'
      $req.Accept = 'application/json'
      $response = $req.GetResponse()
      $strm=$response.GetResponseStream()
      $sr=[System.IO.Streamreader]::new($strm)
      $output=$sr.ReadToEnd() | Convertfrom-json -ErrorAction SilentlyContinue
      if($output.MediaContainer){
        if($output.MediaContainer.metadata.key -match '\/children'){
          $ReturnOutput = $output.MediaContainer.metadata.key | & { process {
              if($VerboseLog){write-ezlogs "| Getting sub item details for children key: $($_)" -Dev_mode:$VerboseLog}
              Get-PlexItemDetails -thisApp $thisApp -ItemKey $_
          }}
        }else{
          $ReturnOutput = $output.MediaContainer
        }
        if($VerboseLog){write-ezlogs "| Found $($output.MediaContainer.size) Plex items" -showtime -Dev_mode:$VerboseLog}
        return $ReturnOutput
      }
    }else{
      write-ezlogs "Cannot lookup Plex item details - no valid token was provided!" -Warning
    }
  }catch{
    write-ezlogs "An exception occured getting Plex item details" -CatchError $_
  }finally{
    if($response){
      $response.Dispose()
    }
    if($strm){
      $strm.Dispose()
    }  
    if($sr){
      $sr.Dispose()
    }
    $req = $Null
  }
}
#---------------------------------------------- 
#endregion Get-PlexItemDetails Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-PlexMedia Function
#----------------------------------------------
function Add-PlexMedia
{
  [CmdletBinding(DefaultParameterSetName = 'Media')]
  param (
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    $Media,
    [switch]$Startup,
    $synchash,
    [string]$Library,
    [switch]$Refresh_All_Media,
    [switch]$NoMediaLibrary,
    $thisApp,
    [switch]$use_runspace,
    [switch]$use_Queue,
    [switch]$update_Library,
    [switch]$VerboseLog 
  )
  
  $Add_PlexMedia_scriptblock = {
    $synchash = $synchash
    $thisApp = $thisApp
    $media = $Media
    $Library = $Library
    $update_Library = $update_Library
    $use_Queue = $use_Queue
    try{
      $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-Plex_MediaProfile")
      if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
        try{
          [void][System.IO.Directory]::CreateDirectory($AllMedia_Profile_Directory_Path)
        }catch{
          write-ezlogs "[Add-PlexMedia] An exception occurred creating new directory at: $AllMedia_Profile_Directory_Path" -catcherror $_
        }   
      }
      $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Plex_Media-Profile.xml")
      if(!$synchash.All_Plex_Media -or $synchash.All_Plex_Media.count -lt 1){
        write-ezlogs "[Add-PlexMedia] | Creating new Generic list for Plex_Available_Media" -showtime -logtype Plex
        $synchash.All_Plex_Media = [System.Collections.Generic.List[Media]]::new()
      }
      if(-not [string]::IsNullOrEmpty($media.FileSize)){
        $length = $media.FileSize
      }elseif(-not [string]::IsNullOrEmpty($media.Size)){
        $length = $media.Size
      }elseif(-not [string]::IsNullOrEmpty($media.media.part.size)){
        $length = $media.media.part.size
      }
      if(-not [string]::IsNullOrEmpty($media.media.part.key)){
        $Title = $media.Title
        $url = $media.media.part.key
        $filename = $media.media.part.file
      }elseif(-not [string]::IsNullOrEmpty($media.url)){
        $Title = $media.Title
        $url = $media.url
        $filename = $media.Name
      }
      if(-not [string]::IsNullOrEmpty($media.summary)){
        $Description = $media.summary
      }elseif(-not [string]::IsNullOrEmpty($media.Description)){
        $Description = $media.Description
      }
      if(($Title) -and $url){
        if($media.media.id){
          $id = $media.media.id
        }elseif($media.id){
          $id = $media.id
        }           
        if($thisApp.Config.PlexMedia_SkipDuplicates -and $synchash.All_Plex_Media.SyncRoot){
          $MediaNotAddedCheck = lock-object -InputObject $synchash.All_Plex_Media.SyncRoot -ScriptBlock {
            if(!$synchash.All_Plex_Media.id){
              return $id
            }else{
              return ($synchash.All_Plex_Media.id.IndexOf($id) -eq -1)
            }
          }  
        }else{
          $MediaNotAddedCheck = $id
        }
        if($MediaNotAddedCheck){                      
          $type = $media.type
          #[string]$sourcedirectory = $directory                                   
          if($images){
            $covert_art = $images.where({$_ -match [regex]::Escape($name)})                  
            if(!$covert_art){
              $covert_art = $images.where({$_ -match 'cover'})
            }                  
            if(!$covert_art){
              $covert_art = $images.where({$_ -match 'album'})
            }                  
          }                                         
          if(-not [string]::IsNullOrEmpty($media.Artist)){
            $artist = $media.Artist         
          }else{ 
            $artist = 'Unknown'
          }  
          if(-not [string]::IsNullOrEmpty($media.duration)){
            $duration = $media.duration
          }elseif(-not [string]::IsNullOrEmpty($media.media.duration)){
            $duration = $media.media.duration
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
            lock-object -InputObject $synchash.All_Plex_Media.SyncRoot -ScriptBlock {
              if($synchash.All_Plex_Media.IsFixedSize){
                $synchash.All_Plex_Media = ConvertTo-Media -InputObject $synchash.All_Plex_Media -List
              }
              [void]$synchash.All_Plex_Media.add($newRow) 
            }      
          }catch{
            write-ezlogs "An exception occurred adding new media to All_Plex_Media -- Media url: $($newRow.url)" -showtime -catcherror $_
          }                                                                                
        }else{ 
          $synchash.PlexMediaDuplicates++
          if($thisApp.Config.Dev_mode){write-ezlogs "Skipping duplicate media: ($name) -- path: $($url)" -showtime -warning -logtype Plex -Dev_mode}
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
        $synchash.processed_PlexMedia++
        try{
          if($synchash.Window){
            $Controls_to_Update = [System.Collections.Generic.List[PSCustomObject]]::new(3)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'Plex_RefreshProgress_Ring'
                'Property' = 'isActive'
                'Value' = $true
            })              
            [void]$Controls_to_Update.Add($newRow) 
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'PlexTable_RefreshLabel'
                'Property' = 'Visibility'
                'Value' = "Visible"
            })
            [void]$Controls_to_Update.Add($newRow)
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'Refresh_PlexMedia_Button'
                'Property' = 'isEnabled'
                'Value' = $false
            })
            $newRow = [PSCustomObject]::new(@{
                'Control' = 'PlexMedia_Progress2_Label'
                'Property' = 'Text'
                'Value' = "Current Directory: $($directory) - Processed Files: $($synchash.processed_localMedia)"
            })                         
            [void]$Controls_to_Update.Add($newRow)
            Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
          }      
        }catch{
          write-ezlogs "An exception occurred updating PlexMedia_Progress_Ring" -showtime -catcherror $_
        }
        if($update_Library){
          write-ezlogs " | ProfileManager_Queue.IsEmpty: $($synchash.ProfileManager_Queue.IsEmpty)"
          if($synchash.All_Plex_Media -and ($synchash.ProfileManager_Queue.IsEmpty)){
            write-ezlogs ">>>> Exporting All Plex Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype Plex
            Export-SerializedXML -Path $AllMedia_Profile_File_Path -InputObject $synchash.All_Plex_Media
            if($synchash.Refresh_LocalMedia_timer -and !$synchash.Refresh_LocalMedia_timer.isEnabled){
              $synchash.Refresh_LocalMedia_timer.tag = 'WatcherLocalRefresh'  
              $synchash.Refresh_LocalMedia_timer.start()   
            }
          }
        }                             
      }else{
        write-ezlogs "[Add-PlexMedia] Provided media: $($url) is not a valid media file type - length: $($length)" -showtime -warning -logtype Plex
      }
    }catch{
      write-ezlogs "An exception occurrred processesing Plex media file: $($media)" -showtime -catcherror $_
    }
  }
  if($Use_Runspace){
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    $Runspace_GUID = (New-Guid).Guid
    Start-Runspace -scriptblock $Add_PlexMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name "Add_PlexMedia_Runspace_$Runspace_GUID" -thisApp $thisApp -synchash $synchash
    $Variable_list = $Null
  }else{
    Invoke-Command -ScriptBlock $Add_PlexMedia_scriptblock
  }
}
#---------------------------------------------- 
#endregion Add-PlexMedia Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-PlexMedia Function
#----------------------------------------------
function Get-PlexMedia
{
  Param (
    [string]$Media_Path,
    $Media_Libraries,
    [switch]$Import_Profile,
    $thisApp,
    $synchash,
    [switch]$Refresh_All_Media = $true,
    [switch]$FastImporting,
    [string]$ImportMode,
    [switch]$AddNewOnly,
    [switch]$Startup,
    [switch]$update_global,
    [switch]$Export_Profile,
    [switch]$Export_AllMedia_Profile,
    [switch]$Verboselog
  )
  write-ezlogs "#### Executing Get-PlexMedia ####" -linesbefore 1 -logtype Plex
  $GetPlexMedia_stopwatch = [system.diagnostics.stopwatch]::StartNew() 
  Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
  $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-Plex_MediaProfile")
  if (!([System.IO.Directory]::Exists($AllMedia_Profile_Directory_Path))){
    try{
      [void][System.IO.Directory]::CreateDirectory($AllMedia_Profile_Directory_Path)
    }catch{
      write-ezlogs "[Get-PlexMedia] An exception occurred creating new directory at: $AllMedia_Profile_Directory_Path" -catcherror $_
    }   
  }
  $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Plex_Media-Profile.xml")
  if($startup -and $Import_Profile -and ([System.IO.FIle]::Exists($AllMedia_Profile_File_Path))){ 
    if($thisApp.Config.Dev_mode){write-ezlogs "[Get-PlexMedia] | Importing Plex Media Profile: $AllMedia_Profile_File_Path" -showtime -logtype Plex -Dev_mode}
    try{
      $synchash.All_Plex_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path 
    }catch{
      write-ezlogs "[Get-PlexMedia] An exception occurred importing local media profile at: $AllMedia_Profile_File_Path" -catcherror $_
    } 
    if($GetPlexMedia_stopwatch){
      $GetPlexMedia_stopwatch.stop()
      write-ezlogs "####################### Get-PlexMedia Finished" -PerfTimer $GetPlexMedia_stopwatch -Perf
      $GetPlexMedia_stopwatch = $null
    }
    return
  }elseif($startup -and $Import_Profile){
    write-ezlogs "[Get-PlexMedia] | Plex Media Profile to import not found at $AllMedia_Profile_File_Path....Attempting to build new profile" -showtime -logtype Plex
    Import-module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
  }  

  #Get libraries to process
  if(!$Refresh_All_Media -and $Import_Profile -and ([System.IO.File]::Exists($AllMedia_Profile_File_Path))){ 
    write-ezlogs "[Get-PlexMedia] | Importing Plex Media Profile: $AllMedia_Profile_File_Path" -showtime -logtype Plex
    try{
      $synchash.All_Plex_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path
    }catch{
      write-ezlogs "[Get-PlexMedia] An exception occurred importing Plex media profile at: $AllMedia_Profile_File_Path" -catcherror $_
    } 
  }
  if($Refresh_All_Media -or !$Media_Libraries){
    $Media_Libraries = Get-PlexLibraryContent -thisApp $thisApp
  }
  if(!$synchash.All_Plex_Media -or @($synchash.All_Plex_Media).count -lt 1){
    write-ezlogs "[Get-PlexMedia] | Creating new Generic list for Plex_Available_Media" -showtime -logtype Plex
    $synchash.All_Plex_Media = [System.Collections.Generic.List[Media]]::new()
  }
  try{
    if($Media_Libraries){

      #TODO: Check for duplicates
      if($AddNewOnly -and !$Media_Path -and $synchash.All_Plex_Media){
        try{
          $Media_Libraries = lock-object -InputObject $synchash.All_Plex_Media.SyncRoot -ScriptBlock {
            $Media_Libraries | & { process { 
                if(($synchash.All_Plex_Media.SourceDirectory.indexof("$_".ToUpper()) -eq -1 -and $synchash.All_Plex_Media.SourceDirectory.indexof("$_".ToLower()) -eq -1)){
                  $_
                }
            }} | Select-Object -Unique
          }         
          write-ezlogs "[Get-PlexMedia] | New directories not already included in media library: Count $($Media_Libraries.count)" -showtime -logtype Plex
        }catch{
          write-ezlogs "An exception occurred getting unique directories not already included in media library" -catcherror $_
        }
      }

      $total_Libraries = @($Media_Libraries).count
      $synchash.processed_Libraries = 0 
      $synchash.processed_PlexMedia = 0    
      if($total_Libraries -ge 128){
        $throttle = 128
      }elseif($total_Libraries -gt 1){
        $throttle = $total_Libraries
      }else{
        $throttle = 32
      }
      write-ezlogs "[Get-PlexMedia] >>>> Scanning $total_Libraries libraries - throttlelimit - $throttle" -showtime -logtype Plex
      try{
        $Controls_to_Update = [System.Collections.Generic.List[object]]::new(2)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'PlexMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' = "Visible"
        })            
        [void]$Controls_to_Update.Add($newRow) 
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'PlexMedia_Progress2_Label'
            'Property' = 'Visibility'
            'Value' = "Visible"
        })              
        [void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'PlexMedia_Progress_Label'
            'Property' = 'Text'
            'Value' = "Processed ($($synchash.processed_directories) of $($total_Libraries)) libraries"
        })             
        [void]$Controls_to_Update.Add($newRow)
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      }catch{
        write-ezlogs "[Get-PlexMedia] An exception occurred updating PlexMedia_Progress_Ring" -showtime -catcherror $_
      }
      $synchash.PlexMediaDuplicates = 0
      try{
        if($synchash.All_Plex_Media.IsFixedSize -and [system.io.file]::Exists($AllMedia_Profile_File_Path)){
          write-ezlogs "[Get-PlexMedia] All_Plex_Media is fixed size - Current Type: $($synchash.All_Plex_Media.gettype()), reimporting/recreating from media profiles" -warning -logtype Plex
          try{
            $synchash.All_Plex_Media = Import-SerializedXML -Path $AllMedia_Profile_File_Path
          }catch{
            write-ezlogs "[Get-PlexMedia] An exception occurred importing Plex media profile at: $AllMedia_Profile_File_Path" -catcherror $_
          }
        }
        $Media_Libraries | Where-Object {-not [string]::IsNullOrEmpty($_)} | Invoke-Parallel -NoProgress -ThrottleLimit $throttle {
          $Library = $_
          try{            
            write-ezlogs "[Get-PlexMedia] | Scanning for Plex media files in Library: $($Library.title1)" -showtime -logtype Plex -LogLevel 2    
            try{
              $Add_PlexMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
              if($Library.Metadata.key -match '\/children'){
                $LibraryMedia = $Library.Metadata.key | & { process {
                    Get-PlexItemDetails -thisApp $thisApp -ItemKey $_
                }}
              }else{
                $LibraryMedia = $Library.Metadata
              }
              $Library.Metadata | & { process {
                  Add-PlexMedia -synchash $synchash -thisApp $thisApp -Media $_ -Library $Library
              }}
              $Add_PlexMedia_Measure.stop()
              write-ezlogs "Add-PlexMedia Measure for $($Library.title1)" -showtime -logtype Plex -LogLevel 2 -Perf -PerfTimer $Add_PlexMedia_Measure
              $Add_PlexMedia_Measure = $Null
              $synchash.processed_Libraries++
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
          }catch{
            write-ezlogs "[Get_PlexMedia] An exception occurred in an Invoke-Parallel thread/loop" -catcherror $_
          }
        }
      }catch{
        write-ezlogs "[Get_PlexMedia] An exception executing Invoke-Parallel" -catcherror $_
      }
    }else{
      write-ezlogs "No valid directory/path was provided to scan for media files!" -showtime -warning -logtype Plex
      return
    }  
    write-ezlogs "Number of local media duplicates skipped: $($synchash.PlexMediaDuplicates)" -showtime -warning -logtype Plex -LogLevel 2
    if($export_profile -and $AllMedia_Profile_File_Path){
      write-ezlogs ">>>> Exporting All Plex Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype Plex -LogLevel 3
      Export-SerializedXML -InputObject $synchash.All_Plex_Media -Path $AllMedia_Profile_File_Path
    }
    if($ImportMode -eq 'Fast' -and $synchash.PlexMediaUpdate_timer){
      if($AddNewOnly){
        $synchash.PlexMediaUpdate_timer.tag = $directories
      }else{
        $synchash.PlexMediaUpdate_timer.tag = $Null
      }
      $synchash.PlexMediaUpdate_timer.start()
    }
    write-ezlogs " | Number of Plex Media files found: $(@($synchash.All_Plex_Media).Count)" -showtime -logtype Plex
  }catch{
    write-ezlogs "An exception occurred scanning Plex media files" -catcherror $_
  }finally{
    if($GetPlexMedia_stopwatch){
      $GetPlexMedia_stopwatch.stop()
      write-ezlogs "####################### Get-PlexMedia Processing Finished #######################" -PerfTimer $GetPlexMedia_stopwatch -Perf -GetMemoryUsage
      $GetPlexMedia_stopwatch = $null
    }
  }
}
#---------------------------------------------- 
#endregion Get-PlexMedia Function
#----------------------------------------------
#General Media Server info
#"http://192.168.50.2:32400/?X-Plex-Token=$Token"
Export-ModuleMember -Function @('Get-PlexToken','Get-PlexLibraries','Get-PlexLibraryContent','Get-PlexItemDetails')