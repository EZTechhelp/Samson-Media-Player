<#
    .Name
    Write-IDTags

    .Version 
    0.1.0

    .SYNOPSIS
    Writes various ID tags to media files using Taglibsharp

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
#region Write-IDTags Function
#----------------------------------------------
function Write-IDTags
{
  Param (
    $synchash,
    $thisApp,
    $media,
    $hashedit,
    $FilePath,
    [switch]$Startup,
    [switch]$Verboselog = $thisApp.Config.Verbose_Logging
  )
  if([System.IO.file]::Exists($FilePath) -and $media){      
    $Write_IDTags_scriptblock = {
      Param (
        $synchash = $synchash,
        $thisApp = $thisApp,
        $media = $media,
        $hashedit = $hashedit,
        $FilePath = $FilePath,
        [switch]$Startup = $Startup,
        [switch]$Verboselog = $Verboselog
      )
      try{
        $Errors = 0
        if(($media.group -eq 'Youtube' -or $media.url -match 'youtube\.com') -and $thisApp.Config.Import_Spotify){
          write-ezlogs ">>>> Attempting to find track info for youtube video from Spotify" -showtime

        }
        write-ezlogs ">>>> Writing media tags info to file for media $($media | out-string)" -showtime
        $taginfo = [taglib.file]::create($FilePath) 
        if($taginfo.Tag){  
          #Title         
          if(-not [string]::IsNullOrEmpty($media.title)){
            $taginfo.tag.title = $media.title
          }elseif(-not [string]::IsNullOrEmpty($media.name)){
            $taginfo.tag.name = $media.name
          }
          #Artist
          if(-not [string]::IsNullOrEmpty($media.Artist)){
            $taginfo.tag.Artists = $media.Artist
          }elseif(-not [string]::IsNullOrEmpty($media.uploader)){
            $taginfo.tag.Artists = $media.uploader
          }

          #Album 
          if(-not [string]::IsNullOrEmpty($media.Album)){
            $taginfo.tag.Album = $media.Album
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.Album)){
            $taginfo.tag.Album = $media.SongInfo.Album
          }
          #Track
          if(-not [string]::IsNullOrEmpty($media.track)){
            $taginfo.tag.Track = $media.track
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.TrackNumber)){
            $taginfo.tag.Track = $media.SongInfo.TrackNumber
          }
          #Disc
          if(-not [string]::IsNullOrEmpty($media.disc)){
            $taginfo.tag.disc = $media.disc
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.discNumber)){
            $taginfo.tag.disc = $media.SongInfo.discNumber
          }
          #Images
          if(-not [string]::IsNullOrEmpty($media.cover_art)){
            $image = $media.cover_art
          }elseif(-not [string]::IsNullOrEmpty($media.Album_Info.images.url)){
            $image = $($media.Album_Info.images.url | select -First 1)
          }elseif(-not [string]::IsNullOrEmpty($media.thumbnail)){
            $image = $($media.thumbnail | select -First 1)
          }else{
            $image = $null
          } 
          $image_Cache_path = $Null
          if($image)
          {
            write-ezlogs "Media Image found: $($image)" -showtime      
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime
              $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
            }
            $encodeduri = $Null  
            $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
            $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
            $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
            if([System.IO.File]::Exists($image_Cache_path)){
              $cached_image = $image_Cache_path
              write-ezlogs "| Found cached image: $cached_image" -showtime
            }elseif($image){         
              if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
              if(!([System.IO.File]::Exists($image_Cache_path))){
                try{
                  if([System.IO.File]::Exists($image)){
                    if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime}
                    [void][system.io.file]::Copy($image, $image_Cache_path,$true)
                  }else{
                    $uri = new-object system.uri($image)
                    write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime
                    (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                  }             
                  if([System.IO.File]::Exists($image_Cache_path)){
                    $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                    $image = new-object System.Windows.Media.Imaging.BitmapImage
                    $image.BeginInit();
                    $image.CacheOption = "OnLoad"
                    #$image.CreateOptions = "DelayCreation"
                    #$image.DecodePixelHeight = 229;
                    $image.DecodePixelWidth = 500;
                    $image.StreamSource = $stream_image
                    $image.EndInit();        
                    $stream_image.Close()
                    $stream_image.Dispose()
                    $stream_image = $null
                    $image.Freeze();
                    if($thisApp.Config.Verbose_logging){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs}
                    $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                    $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                    $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                    $encoder.Save($save_stream)
                    $save_stream.Dispose()       
                  }  
                  $cached_image = $image_Cache_path            
                }catch{
                  $cached_image = $Null
                  write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
                  $Errors++
                }
              }           
            }else{
              write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
              $cached_image = $Null        
            }                                      
          }
          if([System.IO.File]::Exists($cached_image)){
            write-ezlogs " | Adding image to tag pictures: $cached_image" -enablelogs -showtime
            $picture = [TagLib.Picture]::CreateFromPath($cached_image)
            $taginfo.Tag.Pictures = $picture
          }
          #Description
          if(-not [string]::IsNullOrEmpty($media.Description)){
            $taginfo.tag.Description = "$($media.Description)"              
          }elseif(-not [string]::IsNullOrEmpty($media.Songinfo.Description)){
            $taginfo.tag.Description = "$($media.Songinfo.Description)"              
          }

          #TotalTracks
          if(-not [string]::IsNullOrEmpty($media.album_info.total_tracks)){
            $taginfo.tag.TrackCount = $media.album_info.total_tracks             
          }
          #Year
          if(-not [string]::IsNullOrEmpty($media.year)){
            $taginfo.tag.Year = $media.year            
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.year)){
            $taginfo.tag.Year = $media.SongInfo.year
          }elseif(-not [string]::IsNullOrEmpty($media.release_date)){
            try{
              $taginfo.tag.Year = [datetime]::Parse($media.Album_Info.release_date).year
            }catch{
              write-ezlogs "An exception occured parsing year from album release date: $($media.Album_Info.release_date)" -showtime -catcherror $_
              $Errors++
            }
          }
          #Genres
          if(-not [string]::IsNullOrEmpty($media.genres)){
            $taginfo.tag.Genres = $media.genres             
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.genres)){
            $taginfo.tag.genres = $media.SongInfo.genres
          }elseif(-not [string]::IsNullOrEmpty($media.artists.id)){
            try{ 
              write-ezlogs ">>>> Attempting Spotify lookup of artist id $($media.artists.id)" -showtime
              $artist_info = Get-Artist -id $media.artists.id -ApplicationName $($thisApp.Config.App_Name)
              write-ezlogs "| Lookup results: $($artist_info | out-string)" -showtime
              if($artist_info.genres){
                $taginfo.tag.Genres = $artist_info.genres
              }
            }catch{
              write-ezlogs "An exception occurred getting artist info artist id: $($media.artists.id)" -showtime -catcherror $_
              $Errors++
            }
          }
          #Comments
          if(-not [string]::IsNullOrEmpty($media.Comments)){
            $taginfo.tag.Comment = $media.Comments             
          }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.Comments)){
            $taginfo.tag.Comment = $media.SongInfo.Comments
          }else{
            $taginfo.tag.Comment = "Modified with $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)"
          }        
          try{
            write-ezlogs ">>>> Saving new tag info" -showtime -loglevel 2 -logtype LocalMedia
            write-ezlogs "| Tag: $($taginfo.tag | out-string)" -showtime -loglevel 3 -logtype LocalMedia
            $taginfo.Save()
            $taginfo.dispose()
          }catch{
            write-ezlogs "An exception occurred saving tag info to $FilePath" -showtime -catcherror $_
            $Errors++
          }

        }
      }catch{
        write-ezlogs "An exception occurred getting taginfo for $FilePath" -showtime -catcherror $_
        $Errors++
      }finally{
        if($Errors -gt 0){
          write-ezlogs "ERRORS occurred when writing Taginfo for $($media.url)" -showtime -warning
          if($hashedit.Window.isVisible){
            [void]$hashedit.Window.Dispatcher.InvokeAsync{            
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hashedit.Window,"ERROR Writing IDTags!","ERRORS occurred when writing Taginfo for $($media.url)`nReview logs for more detail",$okandCancel,$Button_Settings)            
            }.Wait()
          }elseif($synchash.Window.isVisible){
            [void]$synchash.Window.Dispatcher.InvokeAsync{            
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"ERROR Writing IDTags!","ERRORS occurred when writing Taginfo for $($media.url)`nReview logs for more detail",$okandCancel,$Button_Settings)            
            }.Wait()
          }
        }
      }
    }
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}} 
    Start-Runspace $Write_IDTags_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Write-IDTags" -thisApp $thisApp  
    $Variable_list = $Null
  }else{
    write-ezlogs "The provided media file path is invalid or or no media profile provided! - $($media | out-string)" -showtime -warning
  }  
}
#---------------------------------------------- 
#endregion Write-IDTags Function
#----------------------------------------------
Export-ModuleMember -Function @('Write-IDTags')