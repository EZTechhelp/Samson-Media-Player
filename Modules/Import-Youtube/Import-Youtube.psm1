<#
    .Name
    Import-Youtube

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Youtube Profiles

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
#region Import-Youtube Function
#----------------------------------------------
function Import-Youtube
{
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$NoUpdate,
    [switch]$use_Runspace,
    [switch]$refresh,
    [switch]$CacheImages,
    [switch]$StartPlayback,
    $synchash,
    [string]$Youtube_URL,
    $all_available_Media,
    $Youtube_playlists,
    [string]$Media_Profile_Directory,
    $Refresh_All_Youtube_Media,
    $thisApp,
    $log = $thisApp.Config.YoutubeMedia_logfile,
    $Group,
    $thisScript,
    $Import_Cache_Profile = $startup,
    $PlayMedia_Command,    
    [switch]$VerboseLog
  )
  try{
    $Controls_to_Update = [System.Collections.Generic.List[Object]]::new(4)          
    $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
          'Control' = 'Youtube_Progress_Ring'
          'Property' = 'isActive'
          'Value' = $true
    })) 
    $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
          'Control' =  'YoutubeMedia_Progress_Label'
          'Property' = 'Visibility'
          'Value' =  'Visible'
    })) 
    $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
          'Control' =  'YoutubeMedia_Progress_Label'
          'Property' = 'Text'
          'Value' =  'Importing Youtube Media...'
    }))
    $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
          'Control' =  'YoutubeTable'
          'Property' = 'isEnabled'
          'Value' =  $false
    }))
    Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update 
    if($Clear){
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'itemssource' -value $Null -ClearValue
    }
  }catch{
    write-ezlogs "An exception occurred updating Youtube_Progress_Ring" -showtime -catcherror $_
  } 
  $import_YoutubeMedia_scriptblock = ({
      $synchash = $synchash
      $thisApp = $thisApp
      $Startup = $Startup
      $Youtube_URL = $Youtube_URL
      $StartPlayback = $StartPlayback
      $Youtube_playlists = $Youtube_playlists
      $CacheImages = $CacheImages
      $refresh = $refresh
      $NoUpdate = $NoUpdate
      $Get_Youtube_Measure = [system.diagnostics.stopwatch]::StartNew()
      if($thisApp.Config.Verbose_Logging){write-ezlogs "#### Getting Youtube Media ####" -linesbefore 1 -logtype Youtube}
      try{
        if($Youtube_URL){        
          if($StartPlayback){
            Add-YoutubePlayback -synchash $synchash -thisApp $thisApp -LinkUri $Youtube_URL
          }
          Get-Youtube -Youtube_URL $Youtube_URL -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser -refresh:$refresh -synchash $synchash
        }else{  
          Get-Youtube -Youtube_playlists $Youtube_playlists -Media_Profile_Directory $thisApp.config.Media_Profile_Directory -Import_Profile -Export_Profile -Verboselog:$thisApp.config.Verbose_logging -thisApp $thisApp -import_browser_auth $thisApp.config.Youtube_Browser -startup:$Startup -refresh:$refresh -synchash $synchash
        }
      }catch{
        write-ezlogs "An exception occurred executing Get-Youtube - Params: $($PSBoundParameters | out-string)" -catcherror $_
      }
      if($CacheImages -and $synchash.All_Youtube_Media){ 
        $Youtube_image_Measure = [system.diagnostics.stopwatch]::StartNew()
        $synchash.All_Youtube_Media | where {-not [string]::IsNullOrEmpty($_.id)} | & { process {
            #---------------------------------------------- 
            #region Process Track Images
            #----------------------------------------------
            try{
              $cached_image = $Null
              $isDefault = $false
              if($_.thumbnail){    
                $imagetocache = $_.thumbnail
              }elseif((($_.images).psobject.Properties.Value).url){
                $imagetocache = (($_.images).psobject.Properties.Value).url | where {$_ -match 'maxresdefault.jpg'} | select -First 1
                if(!$imagetocache){
                  $imagetocache = (($_.images).psobject.Properties.Value).url | where {$_ -match 'hqdefault.jpg'} | select -First 1
                }
                if(!$imagetocache){
                  $imagetocache = (($_.images).psobject.Properties.Value).url | where {$_ -match 'original.jpg'} | select -First 1
                }
                if(!$imagetocache){
                  $imagetocache = (($_.images).psobject.Properties.Value).url | select -First 1
                }
              }else{
                $imagetocache = "$($thisApp.Config.Current_Folder)\Resources\Youtube\default.png"
                $isDefault = $true
              } 
              write-ezlogs "[Import-Youtube] >>>> Image to cache for $($_.title): $imagetocache" -showtime -logtype Youtube -loglevel 3                
              $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),'Youtube',"$($_.id).png")
              if(!([System.IO.Directory]::Exists("$($thisApp.config.image_Cache_path)\Youtube"))){
                write-ezlogs "[Import-Youtube] >>>> Creating image cache directory: $($thisApp.config.image_Cache_path)\Youtube" -showtime -logtype Youtube -loglevel 3
                $null = New-item "$($thisApp.config.image_Cache_path)\Youtube" -ItemType directory -Force
              }
              if($imagetocache){         
                write-ezlogs "[Import-Youtube] | Destination path for cached image: $image_Cache_path" -showtime -logtype Youtube -LogLevel 3
                if(!([System.IO.File]::Exists($image_Cache_path)) -and !$isDefault){
                  try{
                    if([System.IO.File]::Exists($imagetocache)){
                      write-ezlogs "[Import-Youtube] | Cached Image found but does not exist in cache, copying image $($imagetocache) to cache path $image_Cache_path" -showtime -logtype Youtube -loglevel 3
                      $null = Copy-item -LiteralPath $imagetocache -Destination $image_Cache_path -Force
                    }elseif($_.title -eq 'Deleted video' -or $_.description -eq 'This video is unavailable.'){
                      write-ezlogs "Cannot process image for Youtube video $($_.id) as its labled as Deleted or unavailable - Title: $($_.title) - Description: $($_.description)" -warning -logtype Youtube
                    }elseif((Test-URL $imagetocache -TestConnection)){
                      $uri = [system.uri]::new($imagetocache)
                      write-ezlogs "[Import-Youtube] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -showtime -logtype Youtube -loglevel 3
                      try{
                        $webclient = [System.Net.WebClient]::new()
                        $null = $webclient.DownloadFile($uri,$image_Cache_path)
                      }catch{
                        write-ezlogs "An exception occurred downloading file: $uri" -CatchError $_
                      }finally{
                        if($webclient){
                          $webclient.Dispose()
                          $webclient = $Null
                        }
                      }
                    }else{
                      write-ezlogs "[Import-Youtube] | Image URL not valid: $imagetocache, using default" -showtime -logtype Youtube -loglevel 3
                      $image_Cache_path = "$($thisApp.Config.Current_Folder)\Resources\Youtube\default.png"
                    }                       
                  }catch{
                    $cached_image = $Null
                    $image_Cache_path = $Null
                    write-ezlogs "[Import-Youtube] An exception occurred attempting to download image for track $($_.title) from $uri to path $image_Cache_path" -showtime -catcherror $_
                  }
                }elseif($isDefault){
                  $image_Cache_path = "$($thisApp.Config.Current_Folder)\Resources\Youtube\default.png"
                }
                if([System.IO.File]::Exists($image_Cache_path)){
                  $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  $image.BeginInit()
                  $image.CacheOption = "OnLoad"
                  #$image.CreateOptions = "DelayCreation"
                  $image.DecodePixelHeight = '180'
                  #$image.DecodePixelWidth = "180"
                  $image.StreamSource = $stream_image
                  $image.EndInit()     
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze()
                  #write-ezlogs "[Import-Youtube] Saving decoded media image to path $image_Cache_path" -showtime -enablelogs -logtype Youtube -LogLevel 3
                  $cached_image = [System.Windows.Media.Imaging.BitmapImage]$image
                  #$encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                  #$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                  #$save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                  #$encoder.Save($save_stream)
                  #$save_stream.Dispose()       
                }                         
              }else{
                write-ezlogs "[Import-Youtube] Cannot cache image $($imagetocache) for $($_.title) to cache path $image_Cache_path - URL is invalid - Using Default Image" -enablelogs -showtime -warning -logtype Youtube
                $cached_image = "$($thisApp.Config.Current_Folder)\Resources\Youtube\default.png"      
                $image_Cache_path = $cached_image   
              }    
              $_.cached_image = $cached_image
              Add-Member -InputObject $_ -Name 'cached_image_path' -Value $image_Cache_path -MemberType NoteProperty -Force
            }catch{
              write-ezlogs "An exception occurred processing image for track $($_)" -catcherror $_
            }
            #---------------------------------------------- 
            #endregion Process Track Images
            #----------------------------------------------      
        }}
        if($Youtube_image_Measure){
          $Youtube_image_Measure.stop()
          write-ezlogs ">>>> Youtube Image Caching Measure" -PerfTimer $Youtube_image_Measure -GetMemoryUsage
          $Youtube_image_Measure = $Null
        }
      }
      #$PerPage = $thisApp.Config.YoutubeBrowser_Paging
      #[System.Collections.Generic.List[string]]$synchash.All_Youtube_Playlists = ($synchash.All_Youtube_Media.playlist) | sort | Get-Unique
      if($synchash.All_Youtube_Media.count -gt 0){ 
        #$synchash.All_Youtube_Media = $synchash.All_Youtube_Media | Sort-Object -Property 'Playlist','Track'
        $synchash.YoutubeMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Youtube_Media)
        $synchash.YoutubeMedia_View.UsePLINQ = $true
      }else{  
        write-ezlogs "[Import-Youtube] All_Youtube_Media was empty!" -showtime -warning -logtype Youtube 
        $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml') 
        if([System.IO.File]::Exists($AllYoutube_Profile_File_Path)){
          write-ezlogs "[Import-Youtube] Removing empyt All_Youtube_Media profile at $AllYoutube_Profile_File_Path" -showtime -warning -logtype Youtube 
          $null = Remove-item $AllYoutube_Profile_File_Path -Force
        }
      }
      if($synchash.YoutubeMedia_TableStartup_timer){
        if($Startup){
          $synchash.YoutubeMedia_TableStartup_timer.tag = 'Startup'
        }else{
          $synchash.YoutubeMedia_TableStartup_timer.tag = $Null
        }        
        $synchash.YoutubeMedia_TableStartup_timer.start()
      }else{
        write-ezlogs "YoutubeMedia_TableStartup_timer is not initialized!" -warning
      }   
      $synchash.Youtube_Update = $false
      if($Get_Youtube_Measure){
        $Get_Youtube_Measure.stop()
        write-ezlogs "Get-Youtube startup" -PerfTimer $Get_Youtube_Measure -GetMemoryUsage
        $Get_Youtube_Measure = $Null
      }      
  }) 
  $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace -scriptblock $import_YoutubeMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Import_YoutubeMedia_Runspace' -thisApp $thisApp -synchash $synchash
  $Variable_list = $Null
  $import_YoutubeMedia_scriptblock = $Null
}
#---------------------------------------------- 
#endregion Import-Youtube Function
#----------------------------------------------
Export-ModuleMember -Function @('Import-Youtube')
