<#
    .Name
    Merge-Images

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Merging 2 images into 1

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
#region Merge-Images Function
#----------------------------------------------
function Merge-Images
{
  [CmdletBinding()]
  param (
    [switch]$Startup,
    $synchash,
    $thisApp,
    [string]$LargeImage,
    [string]$decode_Width,
    [string]$Save_path,
    [string]$SmallImage,
    [string]$StampIcon_Color = "#FF1ED760",
    [string]$StampIcon_Pack = "PackIconMaterial",
    [int]$StampIcon_Scale = 4,
    [string]$StampIcon

  )
  
  try{
    if([system.io.file]::Exists($LargeImage)){
      write-ezlogs ">>>> Getting stamped icon $StampIcon for source image: $LargeImage" -loglevel 2
      $bigger_Filename = [System.IO.Path]::GetFileNameWithoutExtension($LargeImage)
      $bigger_Fileext = [System.IO.Path]::GetExtension($LargeImage)
      $bigger_Directory = [System.IO.Path]::GetDirectoryName($LargeImage)
      if([System.IO.Directory]::Exists($Save_path)){
        $image_Cache_path = [System.IO.Path]::Combine(($Save_path),"$($bigger_Filename)_$StampIcon$bigger_Fileext")
      }elseif([System.IO.Directory]::Exists($bigger_Directory)){
        $image_Cache_path = [System.IO.Path]::Combine(($bigger_Directory),"$($bigger_Filename)_$StampIcon$bigger_Fileext")
      }else{
        $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($bigger_Filename)_$StampIcon$bigger_Fileext")
      } 
      if([system.io.file]::Exists($image_Cache_path)){
        write-ezlogs "| Provided image has already been merged and cached to: $image_Cache_path)" -loglevel 2
        return $image_Cache_path
      }       
      $stream_image = [System.IO.File]::OpenRead($LargeImage) 
      $image = [System.Windows.Media.Imaging.BitmapImage]::new()
      $image.BeginInit()
      $image.CacheOption = "OnLoad"
      if(-not [string]::IsNullOrEmpty($decode_Width)){
        $image.DecodePixelWidth = $decode_Width
      }
      $image.StreamSource = $stream_image
      $image.EndInit()     
      $stream_image.Close()
      $stream_image.Dispose()
      $stream_image = $null
      $image.Freeze()
      $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
      $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
      $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
      $save_stream = [System.IO.MemoryStream]::new()
      $encoder.Save($save_stream)
      $bigger = [System.Drawing.Bitmap]::FromStream($save_stream)
      $save_stream.Dispose() 
      if([system.io.file]::Exists($SmallImage)){
        $smaller = [System.Drawing.Bitmap]::FromFile($SmallImage)
      }elseif(-not [string]::IsNullOrEmpty($StampIcon)){
        $StampIcon_PackType = "MahApps.Metro.IconPacks.$StampIcon_Pack"
        $Playlist_icon = ($StampIcon_PackType -as [Type])::new()
        $Playlist_icon.Foreground = $StampIcon_Color
        $Playlist_icon.Kind = $StampIcon
        $Playlist_geo = [System.Windows.Media.Geometry]::Parse($Playlist_icon.Data)
        $Playlist_gd = [System.Windows.Media.GeometryDrawing]::new()
        $Playlist_gd.Geometry = $Playlist_geo
        $Playlist_gd.Brush = $Playlist_icon.Foreground
        $Playlist_gd.pen = [System.Windows.Media.Pen]::new("#E7000000",0.5)
        $Playlist_icon_path = [System.Windows.Media.DrawingImage]::new($Playlist_gd)
        $image = [System.Windows.Controls.Image]::new()
        $image.source = $Playlist_icon_path
        $width = $Playlist_icon_path.Drawing.Bounds.Width * $StampIcon_Scale
        $height = $Playlist_icon_path.Drawing.Bounds.Height * $StampIcon_Scale
        $image.Arrange([System.Windows.Rect]::new(0,0,$width,$height))
        $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width,$height,64,64,[System.Windows.Media.PixelFormats]::Pbgra32)
        $bitmap.Render($image)
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $save_stream = [System.IO.MemoryStream]::new()
        $encoder.Save($save_stream)
        $smaller = [System.Drawing.Bitmap]::FromStream($save_stream)
        $smaller.SetResolution($bigger.HorizontalResolution,$bigger.VerticalResolution)
        $save_stream.Dispose()
      }

      #Load the original, and work out where to put it in the bigger one.
      $g = [System.drawing.graphics]::FromImage($bigger)   

      #Put it there
      $g.DrawImage($smaller, ($bigger.Width - 70), ($bigger.Height - 70))

      #Save it
      if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
        write-ezlogs "| Creating image cache directory: $($thisApp.config.image_Cache_path)" -loglevel 3
        $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
      }      
      write-ezlogs ">>>> Saving new merged Image to: $($image_Cache_path)" -loglevel 2
      $bigger.Save($image_Cache_path, [System.Drawing.Imaging.ImageFormat]::Png)
      $g.Dispose()      
      $bigger.Dispose()  
      $smaller.Dispose() 
      $encoder = $Null
      $bitmap = $Null
      $image = $Null
      return $image_Cache_path
    }else{
      write-ezlogs "Unable to find large image to merge with at $LargeImage, cannot continue!" -warning
    }
  }catch{
    write-ezlogs "An exception occurred processing Merge-Images" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Merge-Images Function
#----------------------------------------------
Export-ModuleMember -Function @('Merge-Images')