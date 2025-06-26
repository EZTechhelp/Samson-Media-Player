<#
    .Name
    New-ScreenShot

    .Version 
    0.1.0

    .SYNOPSIS
    Takes a screenshow of the current active window

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

function get-screenScaling
{

  <#
      .SYNOPSIS
      get the screen scale
            
      .DESCRIPTION
      get the screen scale
            
            
      .NOTES
      Author: Adrian Andersson
      Last-Edit-Date: 2019-03-15
            
            
      Changelog:

      2019-03-15 - AA
      - Initial Script
      - TypeDefinitiion from here:
      - https://hinchley.net/articles/get-the-scaling-rate-of-a-display-using-powershell/

      2019-03-17 - AA
      - Fixing bugs
      - Thanks to lazytao for raising this
                    
      .COMPONENT
      What cmdlet does this script live in
  #>

  [CmdletBinding()]
  PARAM(
        
  )
  begin{
    #Return the script name when running verbose, makes it tidier
    #write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
    #Return the sent variables when running debug
    #Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    if($psversiontable.psversion.Major -gt 5){
      Add-Type -AssemblyName System.Drawing.Common
      $namespace = 'System.Drawing.Common'
    }else{
      $namespace = 'System.Drawing'
    }

    $typeDefinition = @(
      'using System;',
      'using System.Runtime.InteropServices;',
      'using System.Drawing;',
      '',
      'public class DPI {',
      '   [DllImport("gdi32.dll")]',
      '   static extern int GetDeviceCaps(IntPtr hdc, int nIndex);',
      '',
      '   public enum DeviceCap {',
      '       VERTRES = 10,',
      '       DESKTOPVERTRES = 117',
      '   } ',
      '',
      '   public static float scaling() {',
      '       Graphics g = Graphics.FromHwnd(IntPtr.Zero);',
      '       IntPtr desktop = g.GetHdc();',
      '       int LogicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.VERTRES);',
      '       int PhysicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.DESKTOPVERTRES);',
      '       return (float)PhysicalScreenHeight / (float)LogicalScreenHeight;',
      '   }',
      '}'
    )

    Add-Type $($typeDefinition -join "`n") -ReferencedAssemblies $namespace

             
  }
    
  process{

        
    try{
      #write-verbose 'Getting DPI 1st Attempt'
      $dpi = [dpi]::scaling()

    }catch{
      #write-verbose 'Typedef missing, adding'
      #Add-Type $($typeDefinition -join "`n") -ReferencedAssemblies 'System.Drawing.dll'
      #write-verbose 'Getting DPI 2nd Attempt'
      #$dpi = [dpi]::scaling()
    }

    if(!$dpi -or ($dpi -le 0))
    {
      write-ezlogs 'unable to get screen DPI' -showtime -warning
    }else{
      #write-verbose 'Got screen dpi'

      $dpi
    }
        
        
  }
    
}
function Out-screenshot
{
  param(
    [int]$verStart,
    [int]$horStart,
    [int]$verEnd,
    [int]$horEnd,
    [string]$path,
    [switch]$getvideoimage,
    [int]$Width,
    [int]$height,
    [switch]$captureCursor,
    $thisApp = $thisApp,
    $synchash = $synchash,
    $hashSetup = $hashSetup,
    $MahDialog_hash = $MahDialog_hash
  )
  try{
    if($getvideoimage){
      if($synchash.videoview){
        $Width =  $synchash.videoview.ActualWidth
        $Height = $synchash.videoview.ActualHeight
        $Size = New-Object System.Drawing.Size($Width, $Height)
        $translatepoint = $synchash.videoview.TranslatePoint([system.windows.point]::new(0,0),$this)
        $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
      }else{
        write-ezlogs "Cannot get screenshot of video image, videoview not found!" -warning 
        return
      }
    }else{
      if($synchash.MiniPlayer_Viewer.isVisible){
        $Width =  $synchash.MiniPlayer_Viewer.ActualWidth
        $Height = $synchash.MiniPlayer_Viewer.ActualHeight
        $Size = New-Object System.Drawing.Size($Width, $Height)
        $translatepoint = $synchash.MiniPlayer_Viewer.TranslatePoint([system.windows.point]::new(0,0),$this)
        $locationfromscreen = $synchash.MiniPlayer_Viewer.PointToScreen($translatepoint)
      }elseif($synchash.Window.isVisible){
        $Width =  $synchash.Window.ActualWidth
        $Height = $synchash.Window.ActualHeight
        $Size = New-Object System.Drawing.Size($Width, $Height)
        $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
        $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
      }else{
        write-ezlogs "Cannot get screenshot, miniplayer or main window not found!" -warning 
        return
      }
    }
    $Point = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)
    $ScreenshotObject = [Drawing.Bitmap]::new($Width,$Height)
    $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
    $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)  
    if($captureCursor)
    {
      #write-ezlogs "CaptureCursor is true" -showtime
      $scale = get-screenScaling
      $mousePos = [System.Windows.Forms.Cursor]::Position
      $mouseX = $mousePos.x * $scale
      $mouseY = $mousePos.y * $scale
      if(($mouseX -gt $horStart)-and($mouseX -lt $horEnd)-and($mouseY -gt $verStart) -and ($mouseY -lt $verEnd))
      {
        #Get the position in the box
        $x = $mouseX - $horStart
        $y = $mouseY - $verStart
        $pen = [drawing.pen]::new([drawing.color]::Red)
        $pen.width = 5
        $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Bevel
        $DrawingGraphics.DrawRectangle($pen,$x,$y, 5,5)
      }
    }
    $ScreenshotObject.Save($path,"PNG")
    if($synchash.MediaLibraryFloat.isVisible){
      try{
        $newpathname = "MediaLibrary_$([System.io.path]::GetFileName($path))"
        $pathdir = [System.io.directory]::GetParent($path)
        $path = [system.io.path]::Combine($pathdir,$newpathname)
        $before = $synchash.MediaLibraryFloat.TopMost
        $synchash.MediaLibraryFloat.TopMost = $true
        $synchash.MediaLibraryFloat.Activate() 
        start-sleep -Milliseconds 200
        write-ezlogs ">>>> Taking Snapshot of MediaLibrary_viewer" -showtime
        $Width =  $synchash.MediaLibraryFloat.ActualWidth
        $Height = $synchash.MediaLibraryFloat.ActualHeight
        $Size = [System.Drawing.Size]::new($Width, $Height)
        $translatepoint = $synchash.MediaLibraryFloat.TranslatePoint([system.windows.point]::new(0,0),$this)
        $locationfromscreen = $synchash.MediaLibraryFloat.PointToScreen($translatepoint)
        $Point = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)
        $ScreenshotObject = [Drawing.Bitmap]::new($Width, $Height)
        $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
        $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)
        $ScreenshotObject.Save($path,"PNG")
        $synchash.MediaLibraryFloat.TopMost = $before
      }catch{
        write-ezlogs "An exception occurred getting screenshot of MediaLibraryFloat" -showtime -catcherror $_
      }
    }
    if($hashsetup.Window.isVisible){
      try{
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -Screenshot -ScreenshotPath $path
      }catch{
        write-ezlogs "An exception occurred getting screenshot of settings window" -showtime -catcherror $_
      }
    }
    if($synchash.MahDialog_hash.window.isVisible){
      try{
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
        $pattern = "[$illegal]"
        if($MahDialog_hash.window.title){
          $title = ([Regex]::Replace($($synchash.MahDialog_hash.window.title), $pattern, '')).trim()    
        }else{
          $title = "WebLogin_"
        }
        $Width =  $synchash.MahDialog_hash.window.ActualWidth
        $Height = $synchash.MahDialog_hash.window.ActualHeight
        $newpathname = "$($title)_$([System.io.path]::GetFileName($path))"
        $pathdir = [System.io.directory]::GetParent($path)
        $path = [system.io.path]::Combine($pathdir,$newpathname)
        $before = $MahDialog_hash.window.TopMost
        $Size = [System.Drawing.Size]::new($Width, $Height)
        $ScreenshotObject = [Drawing.Bitmap]::new($Width, $Height)
        $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
        $synchash.MahDialog_hash.Window.Dispatcher.Invoke("Normal",[action]{     
            try{
              $synchash.MahDialog_hash.window.TopMost = $true
              $synchash.MahDialog_hash.window.Activate() 
              start-sleep -Milliseconds 500
              write-ezlogs ">>>> Taking Snapshot of Show-weblogon window - $before" -showtime
              $translatepoint = $synchash.MahDialog_hash.window.TranslatePoint([system.windows.point]::new(0,0),$this)
              $locationfromscreen = $synchash.MahDialog_hash.window.PointToScreen($translatepoint)
              $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
           
            }catch{
              write-ezlogs "An exception occurred getting snapshot of Show-Weblogin window" -showtime -catcherror $_
            }   
        })
        $DrawingGraphics.CopyFromScreen($synchash.SnapshotPoint, [Drawing.Point]::Empty, $Size)
        $ScreenshotObject.Save($path,"PNG")
        $synchash.MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{  
            $synchash.MahDialog_hash.window.TopMost = $before 
        })
      }catch{
        write-ezlogs "An exception occurred getting screenshot of Show-Weblogin window" -showtime -catcherror $_
      }
    }
    if($hashedit.window.isVisible){
      try{
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
        $pattern = "[$illegal]"
        if($hashedit.window.title){
          $title = ([Regex]::Replace($($hashedit.window.title), $pattern, '')).trim()    
        }else{
          $title = "Editor_"
        }
        $Width =  $hashedit.window.ActualWidth
        $Height = $hashedit.window.ActualHeight
        $newpathname = "$($title)_$([System.io.path]::GetFileName($path))"
        $pathdir = [System.io.directory]::GetParent($path)
        $path = [system.io.path]::Combine($pathdir,$newpathname)
        $before = $hashedit.window.TopMost
        $Size = [System.Drawing.Size]::new($Width, $Height)
        $ScreenshotObject = [Drawing.Bitmap]::new($Width, $Height)
        $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
        $hashedit.Window.Dispatcher.Invoke("Normal",[action]{     
            try{
              $hashedit.Window.TopMost = $true
              $hashedit.Window.Activate() 
              start-sleep -Milliseconds 500
              write-ezlogs ">>>> Taking Snapshot of Show-ProfileEditor window - $before" -showtime
              $translatepoint = $hashedit.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
              $locationfromscreen = $hashedit.Window.PointToScreen($translatepoint)
              $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
           
            }catch{
              write-ezlogs "An exception occurred getting snapshot of Show-PorfileEditor window" -showtime -catcherror $_
            }   
        })
        $DrawingGraphics.CopyFromScreen($synchash.SnapshotPoint, [Drawing.Point]::Empty, $Size)
        $ScreenshotObject.Save($path,"PNG")
        $hashedit.Window.Dispatcher.Invoke("Normal",[action]{  
            $hashedit.Window.TopMost = $before 
        })
      }catch{
        write-ezlogs "An exception occurred getting screenshot of editor window" -showtime -catcherror $_
      }
    }
    if($synchash.AudioOptions_Viewer.isVisible){
      try{
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
        $pattern = "[$illegal]"
        if($synchash.AudioOptions_Viewer.title){
          $title = ([Regex]::Replace($($synchash.AudioOptions_Viewer.title), $pattern, '')).trim()    
        }else{
          $title = "AudioOptions_"
        }
        $Width =  $synchash.AudioOptions_Viewer.ActualWidth
        $Height = $synchash.AudioOptions_Viewer.ActualHeight
        $newpathname = "$($title)_$([System.io.path]::GetFileName($path))"
        $pathdir = [System.io.directory]::GetParent($path)
        $path = [system.io.path]::Combine($pathdir,$newpathname)
        $before = $synchash.AudioOptions_Viewer.TopMost
        $Size = [System.Drawing.Size]::new($Width, $Height)
        $ScreenshotObject = [Drawing.Bitmap]::new($Width, $Height)
        $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)    
        try{
          $synchash.AudioOptions_Viewer.TopMost = $true
          $synchash.AudioOptions_Viewer.Activate() 
          start-sleep -Milliseconds 500
          write-ezlogs ">>>> Taking Snapshot of Audio Options window - $before" -showtime
          $translatepoint = $synchash.AudioOptions_Viewer.TranslatePoint([system.windows.point]::new(0,0),$this)
          $locationfromscreen = $synchash.AudioOptions_Viewer.PointToScreen($translatepoint)
          $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)          
        }catch{
          write-ezlogs "An exception occurred getting snapshot of AudioOpions window" -showtime -catcherror $_
        }   
        $DrawingGraphics.CopyFromScreen($synchash.SnapshotPoint, [Drawing.Point]::Empty, $Size)
        $ScreenshotObject.Save($path,"PNG")
        $synchash.AudioOptions_Viewer.TopMost = $before 
      }catch{
        write-ezlogs "An exception occurred getting screenshot of Audio Options window" -showtime -catcherror $_
      }
    }
  }catch{
    write-ezlogs "An exception occurred getting in Out-screenshot" -showtime -catcherror $_
  }finally{
    if($DrawingGraphics -is [System.IDisposable]){
      $DrawingGraphics.Dispose()
    }
  }
}
function get-EvenNumber
{
  Param(
    [int]$number
  )
  if($($number/2) -like '*.5')
  {
    $number = $number-1
  }
  return $number
}
#---------------------------------------------- 
#region New-ScreenShot Function
#----------------------------------------------
function New-ScreenShot
{
  <#
      .SYNOPSIS
      Simple Screen-Capture done in PowerShell

      Needs ffmpeg: https://www.ffmpeg.org/

      .DESCRIPTION
      Simple Screen-Capture done in PowerShell.
      Useful for making tutorial  and demonstration videos

      Also draws a big red dot where your cursor is, if it is in the defined window bounds

      Uses FFMPeg to make a video file
      Video file can then be edited in your fav video editor
      Like Blender :)


      You will need to download and setup FFMPEG first

      https://www.ffmpeg.org/

      The default path to the ffmpeg exe is c:\program files\ffmpeg\bin


      .PARAMETER videoName
      Name + Extension to output the video file as
      By default will use out.mp4

      .PARAMETER fps
      Framerate used to calculate both how often to take a screenshot
      And what to use to process the ffmpeg call

      .PARAMETER captureCursor
      Should we put a replacement cursor (Red-dot for visibility) in the video?

      .PARAMETER force
      Skip fileExists and remove check


      .PARAMETER outFolder
      The folder to save the output video to


      .PARAMETER ffMPegPath
      Path to ffMpeg
      Suggest you modify this to be where yours is by default


      .PARAMETER tempPath
      Where to store the images before compiling them into a video


      .EXAMPLE
      new-psScreenRecord -outFolder 'C:\temp\testVid' -Verbose

      DESCRIPTION
      ------------
      Will create a new video file with 'out.mp4' filename in c:\temp\testVid folder


      .NOTES
      Author: Adrian Andersson



      Changelog

      2017-09-13  - AA
      - New script, cleaned-up from an old one I had saved

      2019-03-14 - AA
      - Moved to bartender module

      2019-03-14 - AA
      - Changed the ffmpegPath to use the allUsersProfile path
      - Throw better errors
      - Added a couple write-hosts so users were not left wondering what was going on with the capture process
      - Normally I don't condone write-host but it seemed to make sense in this case
      -Changed var name to ffmpegArg
      - Moved images to temp folder rather than output folder
      - Fixed confirm switch so it actually works
      - Fixed the help

      2019-03-17 - AA
      - Second attempt at fixing screen scaling bug

      2019-03-20 - AA
      - Added a switch and the necessary call changes to not capture the cursor if it is undesired
      - Removed the requirement to confirm
      - Changed the output folder to be in the users documents + psScreenRecorder subfolder
      - Old path was a bit untidy
      - Made confirm a 'force' switch as this is clearer language
      - Also it should only ask to confirm on removing the existing video file
      - Changed the way we check for files to be a bit tidier
      - Return the output video path as a string
      - Removed the write-hosts and made them write warning instead
      - Added a hidden param for startCapture
      - Can be used to skip the actual capture
      - Left it in for debug purposes
      - Re-ordered the params
      - Since videoName is the most important one now we have good defaults
      - If videoname does not end in .mp4, add it in
      - Added a check to see if mp4 is part of the video name, add it in if it isn't there

      .COMPONENT
      psScreenCapture
  #>

  [CmdletBinding()]
  PARAM(
    [Alias("name")]
    [string]$videoName,
    [Alias("framerate")]
    [string]$fps = 24,
    [int]$screen_Capture_Duration = 30,
    [bool]$captureCursor = $false,
    [switch]$force,
    [switch]$getvideoimage,
    [Alias("path")]
    [string]$outFolder= "$($thisApp.Config.Temp_Folder)",
    [string]$tempPath = "$($thisApp.Config.Temp_Folder)",
    [Parameter(DontShow)]
    [bool]$startCapture = $true,
    [Parameter(DontShow)]
    [switch]$leaveImages,
    $thisApp = $thisApp,
    $synchash = $synchash,
    $hashSetup = $hashSetup,
    $MahDialog_hash = $MahDialog_hash
  )
  begin{
    #Write-ezlogs 'Adding a new C# Assembly to get the Foreground Window' -showtime
    #This assembly is needed to get the current process
    #So we know when we have gone BACK to PowerShell
    #Use an array since its tidier than a here string
    $typeDefinition = @(
      'using System;',
      'using System.Runtime.InteropServices;',
      'public class UserWindows {',
      '   [DllImport("user32.dll")]',
      '   public static extern IntPtr GetForegroundWindow();',
      '}'
    )

    Add-Type $($typeDefinition -join "`n")
  }process{
    if(![system.io.directory]::Exists($outfolder)){
      write-ezlogs 'Creating new output folder' -showtime
      new-item -Path $outFolder -ItemType Directory -Force
    }
    $VideoController = Get-CimInstance -Query 'SELECT VideoModeDescription FROM Win32_VideoController' | where {$_.VideoModeDescription} | select-object -Last 1

    if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
      $Width = [Int] $Matches['ScreenWidth']
      $Height = [Int] $Matches['ScreenHeight']
    } else {
      $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
      $Width = $ScreenBounds.Width
      $Height = $ScreenBounds.Height
    }
    if($startCapture -eq $true -or $startCapture -eq 1)
    {
      write-ezlogs 'Starting screen capture' -showtime -Warning
      #Start up the capture process
      $num = 1 #Iteration number for screenshot naming
      $x = "{0:D5}" -f $num
      $path = "$tempPath\$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt').png"
      $screenshotSplat = @{
        Width = $Width
        Height = $Height
        path = $path
        getvideoimage = $getvideoimage
        captureCursor = $captureCursor
      }
      out-screenShot @screenshotSplat
      
    }else{
      return -1
    }
  }End{
    return $outFolder
  }
}
#---------------------------------------------- 
#endregion Update-MediaTimer Function
#----------------------------------------------
#New-ScreenShot -outFolder $Capture_Output_Path -tempPath $thisScript.TempFolder -ffMPegPath "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffmpeg.exe" -fps 60 -screen_Capture_Duration $Capture_Duration_Seconds -captureCursor 1 -Verbose
Export-ModuleMember -Function @('New-ScreenShot')