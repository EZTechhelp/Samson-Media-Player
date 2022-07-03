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
    - Module designed for EZT-MediaPlayer

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
    [switch]$captureCursor
  )
  #$bounds = [drawing.rectangle]::FromLTRB($horStart,$verStart,$horEnd,$verEnd)
    
  #$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    
  #$Width = $Screen.Width
  #$Height = $Screen.Height
  #$Left = $Screen.Left
  #$Top = $Screen.Top
  #$bitmap = New-Object System.Drawing.Bitmap $Width, $Height

  #$horStart = get-EvenNumber $($($start.x * $scale))
  #$verStart = get-EvenNumber $($($start.y * $scale))
  #$horEnd = get-EvenNumber $($($end.x * $scale))
  #$verEnd = get-EvenNumber $($($end.y * $scale))
  #$boxSize = "box size: Xa: $horStart, Ya: $verStart, Xb: $horEnd, Yb: $verEnd, $($horEnd - $horStart) pixels wide, $($verEnd - $verStart) pixles tall"
  $synchash = $synchash
  $hashedit = $hashedit
  $hashsetup = $hashSetup
  $MahDialog_hash = $MahDialog_hash
  write-ezlogs "Weblogon $($synchash.MahDialog_hash | out-string)"
  if($getvideoimage){
    $Width =  $synchash.videoview.ActualWidth
    $Height = $synchash.videoview.ActualHeight
    $Size = New-Object System.Drawing.Size($Width, $Height)
    $translatepoint = $synchash.videoview.TranslatePoint([system.windows.point]::new(0,0),$this)
    $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
  }else{
    $Width =  $synchash.Window.ActualWidth
    $Height = $synchash.Window.ActualHeight
    $Size = New-Object System.Drawing.Size($Width, $Height)
    $translatepoint = $synchash.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
    $locationfromscreen = $synchash.Window.PointToScreen($translatepoint)
  }

  $Point = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
  $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
  $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
  #write-ezlogs "Position of video view $($translatepoint | out-string)" -showtime
  #write-ezlogs "Position of video view $($locationfromscreen | out-string)" -showtime
  #write-ezlogs "Position of video view $($Point | out-string)" -showtime
  #write-ezlogs "size $($size | out-string)" -showtime
  #write-ezlogs "Width $($Width | out-string)" -showtime
  #write-ezlogs "Height $($Height | out-string)" -showtime
  $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)
  #$jpg = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.height
  #$graphics = [drawing.graphics]::FromImage($jpg)
  #$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  # $graphics.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
  #$graphics.CopyFromScreen($bounds.Location,[Drawing.Point]::Empty,$bounds.Size)
  if($captureCursor)
  {
    #write-ezlogs "CaptureCursor is true" -showtime
    $scale = get-screenScaling
    $mousePos = [System.Windows.Forms.Cursor]::Position
    $mouseX = $mousePos.x * $scale
    $mouseY = $mousePos.y * $scale
    if(($mouseX -gt $horStart)-and($mouseX -lt $horEnd)-and($mouseY -gt $verStart) -and ($mouseY -lt $verEnd))
    {
      #write-verbose "Mouse is in the box"
      #Get the position in the box
      $x = $mouseX - $horStart
      $y = $mouseY - $verStart
      #write-verbose "X: $x, Y: $y"
      #Add a 4 pixel red-dot
      $pen = [drawing.pen]::new([drawing.color]::Red)
      $pen.width = 5
      $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Bevel
      #$hand = [System.Drawing.SystemIcons]::Hand
      #$arrow = [System.Windows.Forms.Cursors]::Arrow
      #$graphics.DrawIcon($arrow, $x, $y)
      $DrawingGraphics.DrawRectangle($pen,$x,$y, 5,5)
      #$mousePos
    }
  }
  $ScreenshotObject.Save($path,"JPEG")
  if($synchash.MediaLibrary_viewer.isVisible){
    $newpathname = "MediaLibrary_$([System.io.path]::GetFileName($path))"
    $pathdir = [System.io.directory]::GetParent($path)
    $path = [system.io.path]::Combine($pathdir,$newpathname)
    $before = $synchash.MediaLibrary_viewer.TopMost
    $synchash.MediaLibrary_viewer.TopMost = $true
    $synchash.MediaLibrary_viewer.Activate() 
    start-sleep -Milliseconds 200
    write-ezlogs ">>>> Taking Snapshot of MediaLibrary_viewer" -showtime
    $Width =  $synchash.MediaLibrary_viewer.ActualWidth
    $Height = $synchash.MediaLibrary_viewer.ActualHeight
    $Size = New-Object System.Drawing.Size($Width, $Height)
    $translatepoint = $synchash.MediaLibrary_viewer.TranslatePoint([system.windows.point]::new(0,0),$this)
    $locationfromscreen = $synchash.MediaLibrary_viewer.PointToScreen($translatepoint)
    $Point = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
    $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
    $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
    $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)
    $ScreenshotObject.Save($path,"JPEG")
    $synchash.MediaLibrary_viewer.TopMost = $before
  }
  if($hashsetup.Window.isVisible){
    $newpathname = "Setup_$([System.io.path]::GetFileName($path))"
    $pathdir = [System.io.directory]::GetParent($path)
    $path = [system.io.path]::Combine($pathdir,$newpathname)
    $before = $hashsetup.Window.TopMost
    $Width =  $hashsetup.Window.ActualWidth
    $Height = $hashsetup.Window.ActualHeight
    $Size = New-Object System.Drawing.Size($Width, $Height)
    $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
    $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
    $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{     
        try{
          $hashsetup.Window.TopMost = $true
          $hashsetup.Window.Activate() 
          start-sleep -Milliseconds 500
          write-ezlogs ">>>> Taking Snapshot of Show-FirstRun window" -showtime
          $translatepoint = $hashsetup.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
          $locationfromscreen = $hashsetup.Window.PointToScreen($translatepoint)
          $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
           
        }catch{
          write-ezlogs "An exception occurred getting snapshot of first run setup window" -showtime -catcherror $_
        }   
    })
    $DrawingGraphics.CopyFromScreen($synchash.SnapshotPoint, [Drawing.Point]::Empty, $Size)
    $ScreenshotObject.Save($path,"JPEG")
    $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{  
        $hashsetup.Window.TopMost = $before 
    })
  }
  if($synchash.MahDialog_hash.window.isVisible){
    try{
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
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
      $Size = New-Object System.Drawing.Size($Width, $Height)
      $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
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
      $ScreenshotObject.Save($path,"JPEG")
      $synchash.MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{  
          $synchash.MahDialog_hash.window.TopMost = $before 
      })
    }catch{
      write-ezlogs "An exception occurred getting screenshot of Show-Weblogin window" -showtime -catcherror $_
    }
  }
  if($hashedit.window.isVisible){
    try{
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
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
      $Size = New-Object System.Drawing.Size($Width, $Height)
      $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
      $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
      $hashedit.Window.Dispatcher.Invoke("Normal",[action]{     
          try{
            $hashedit.Window.TopMost = $true
            $hashedit.Window.Activate() 
            start-sleep -Milliseconds 500
            write-ezlogs ">>>> Taking Snapshot of Show-PorfileEditor window - $before" -showtime
            $translatepoint = $hashedit.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
            $locationfromscreen = $hashedit.Window.PointToScreen($translatepoint)
            $synchash.SnapshotPoint = New-Object System.Drawing.Point($locationfromscreen.x,$locationfromscreen.y)
           
          }catch{
            write-ezlogs "An exception occurred getting snapshot of Show-PorfileEditor window" -showtime -catcherror $_
          }   
      })
      $DrawingGraphics.CopyFromScreen($synchash.SnapshotPoint, [Drawing.Point]::Empty, $Size)
      $ScreenshotObject.Save($path,"JPEG")
      $hashedit.Window.Dispatcher.Invoke("Normal",[action]{  
          $hashedit.Window.TopMost = $before 
      })
    }catch{
      write-ezlogs "An exception occurred getting screenshot of editor window" -showtime -catcherror $_
    }
  }
  if($DrawingGraphics){
    $DrawingGraphics.Dispose()
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
    [string]$videoName = 'out.mp4',
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
    [switch]$leaveImages
  )
  begin{

    #[string]$ffMPegPath = $(get-childitem -path "$($env:ALLUSERSPROFILE)\ffmpeg" -filter 'ffmpeg.exe' -Recurse|sort-object -Property LastWriteTime -Descending|select-object -First 1).fullname,
    #Return the script name when running verbose, makes it tidier
    #write-ezlogs "===========Executing $($MyInvocation.InvocationName)===========" -color yellow
    #Return the sent variables when running debug
    #Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"


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

    #write-ezlogs 'Loading other required assemblies' -showtime
    #Add-Type -AssemblyName system.drawing
    #add-type -AssemblyName system.windows.forms




    #We need to calculate the sleep-time based on the FPS
    #We want to know how many miliseconds to take a snap - as a whole number
    #Based on the frame-rate
    #This should be accurate enough
    #write-ezlogs 'Calculating capture time' -showtime
    #$msWait =[math]::Floor(1/$($fps/1000))

    #write-ezlogs 'Checking videoName has extension' -showtime
    if($videoName.EndsWith('.mp4') -ne $true)
    {
      write-ezlogs ' | Appending mp4 extension to video name since it was not supplied' -showtime
      $videoName = "$videoName.mp4"
    }


    #write-ezlogs 'Generating output path' -showtime

    $outputFilePath = "$outFolder\$videoName"
    write-ezlogs " | outputFilePath: $outputFilePath" -showtime


  }process{

    <#        write-ezlogs 'Checking for ffmpeg' -showtime
        if(!$(test-path -Path $ffMPegPath -ErrorAction SilentlyContinue))
        {
        throw 'FFMPEG not found - either provide the path variable or run the install-ffmmpeg command'
    }#>

    <#        if(!$(test-path $tempPath))
        {
        write-ezlogs 'Creating ffmpeg temp directory' -showtime
        try{
        $outputDir = new-item -ItemType Directory -Path $tempPath -Force -ErrorAction Stop
        write-ezlogs ' | Directory Created' -showtime
        }catch{
        throw "Unable to create ffmpeg temp directory $tempPath"
        }
        }else{
        write-ezlogs 'Removing existing jpegs in folder and video file if it exists' -showtime
        remove-item "$tempPath\*.jpg" -Force
    }#>


    #write-ezlogs 'Getting THIS POWERSHELL Session handle number so we know what to ignore' -showtime
    #This is used in conjunction with the above service, to identify when we get back to the ps window
    #$thisWindowHandle = $(Get-Process -Name *powershell* | Where-Object{$_.MainWindowHandle -eq $([userwindows]::GetForegroundWindow())}).MainWindowHandle

    #write-ezlogs 'Ensuring output folder is ok' -showtime
    if([system.io.directory]::Exists($outfolder))
    {
      #write-ezlogs ' | Output folder already exists.' -showtime
      if([system.io.file]::Exists($outputFilePath))
      {

        if(!$force)
        {
          <#                    if($($Host.UI.PromptForChoice('Continue',"$outputFilePath already exists! Continue?", @('No','Yes'), 1)) -eq 1)
              {
              write-warning 'Removing file and continuing with screen capture'
              }else{
              return -1
          }#>

          remove-item $outputFilePath -Force -ErrorAction SilentlyContinue #SilentlyCont in case the file doesn't exist

        }


      }

    }else{
      write-ezlogs 'Creating new output folder' -showtime
      new-item -Path $outFolder -ItemType Directory -Force

    }


    #Get the window size
    #write-ezlogs 'Getting the Window Size' -showtime
    #Read-Host 'VIDEO RECORD, put mouse cursor in top left corner of capture area and press any key'
    #$start = [System.Windows.Forms.Cursor]::Position
    #Read-Host 'VIDEO RECORD, put mouse cursor in bottom right corner of capture area and press any key'
    #$end = [System.Windows.Forms.Cursor]::Position

    #$scale = get-screenScaling
    $VideoController = Get-CimInstance -Query 'SELECT VideoModeDescription FROM Win32_VideoController' | where {$_.VideoModeDescription} | select-object -Last 1

    if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
      $Width = [Int] $Matches['ScreenWidth']
      $Height = [Int] $Matches['ScreenHeight']
    } else {
      $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen

      $Width = $ScreenBounds.Width
      $Height = $ScreenBounds.Height
    }
    #$horStart = get-EvenNumber $($($start.x * $scale))
    #$verStart = get-EvenNumber $($($start.y * $scale))
    #$horEnd = get-EvenNumber $($($end.x * $scale))
    #$verEnd = get-EvenNumber $($($end.y * $scale))
    #$boxSize = "box size: Xa: $horStart, Ya: $verStart, Xb: $horEnd, Yb: $verEnd, $($horEnd - $horStart) pixels wide, $($verEnd - $verStart) pixles tall"
    #Write-Verbose $boxSize
    #$startCapture = $true - Used to be used by confirm block
    #But will leave it in here to quickly switch off capturing for debug purposes
    #Wil move $startCapture = $true to be a hiidden boolean at the top though

    if($startCapture -eq $true -or $startCapture -eq 1)
    {
      write-ezlogs 'Starting screen capture' -showtime -Warning
      #Start up the capture process
      $num = 1 #Iteration number for screenshot naming
      #$capture = $false #Switch to say when to stop capture
      #Wait for PowerShell to loose focus
      <#            while($capture -eq $false)
          {
          if([userwindows]::GetForegroundWindow() -eq $thisWindowHandle)
          {
          write-verbose 'Powershell still in focus'
          Start-Sleep -Milliseconds 60
          }else{
          write-verbose 'Powershell lost focus'
          Write-warning 'Focus Lost - Starting screen capture in 2 seconds'
          Start-Sleep -Seconds 2
          Write-Warning 'Capturing Screen'
          $capture=$true
          $stopwatch = [System.Diagnostics.stopwatch]::StartNew()
          }
      }#>
      #Start-Sleep -Seconds 2
      #write-ezlogs 'Capturing Screen' -showtime -color cyan
            
      #$capture=$true
      #$stopwatch = [System.Diagnostics.stopwatch]::StartNew()
            
      #Do another loop until PowerShell regains focus
      #while($capture -eq $true)
      # {
      <#                if([userwindows]::GetForegroundWindow() -eq $thisWindowHandle)
          {
          write-verbose 'Powershell has regained focus, so exit the loop'
          $capture = $false
      }#>
      if($StopWatch.Elapsed.Seconds -eq $screen_Capture_Duration)
      {
        #write-ezlogs "Timer has reached $screen_Capture_Duration seconds. Ending screen capture" -showtime -Warning
        $capture = $false
      }
      else{
        #write-verbose "Capturing - Seconds Elapsed: $($StopWatch.Elapsed.Seconds) -- Total Seconds to Capture: $screen_Capture_Duration"
        $x = "{0:D5}" -f $num
        $path = "$tempPath\$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt').png"
        $screenshotSplat = @{
          #horStart = $horStart
          #vertStart = $verStart
          #horEnd = $horEnd
          #verEnd = $verEnd
          Width = $Width
          Height = $Height
          path = $path
          getvideoimage = $getvideoimage
          captureCursor = $captureCursor
        }
        #Out-screenshot -horStart $horStart -verStart $verStart -horEnd $horEnd -verEnd $verEnd -path $path -captureCursor
        out-screenShot @screenshotSplat
        #$num++
        #Start-Sleep -milliseconds 1
      }
      #}

    }else{
      return -1
    }


  }End{
    #$stopwatch.stop()
    #$numberOfImages = $(get-childitem $tempPath -Filter '*.jpg').count
    #Gasp ... a write host appeared
    #Since we aren't returning any objects this seems like a good option
    #We are now returning objects, so this needs to be changed to a warning
    #write-ezlogs 'Capture complete, compiling video' -showtime -color Cyan
    #$actualFrameRate = $numberOfImages / $stopwatch.Elapsed.TotalSeconds
    #$actualFrameRate = [math]::Ceiling($actualFrameRate)
    #write-ezlogs " | Time Elapsed: $($stopwatch.Elapsed.ToString())" -showtime
    #write-ezlogs " | Total Number of Images: $numberOfImages" -showtime
    #write-ezlogs " | ActualFrameRate: $actualFrameRate" -showtime
    #write-ezlogs 'Creating video using ffmpeg' -showtime
    #write-ezlogs "Temp path - $tempPath" -showtime
    #write-ezlogs "images - $(get-childitem $tempPath -Filter '*.jpg')" -showtime
    return $path
    #$ffmpegArg = "-framerate $actualFrameRate -i $tempPath\%05d.jpg -c:v libx264 -vf fps=$actualFrameRate -pix_fmt yuv420p $outputFilePath -y"
    #Start-Process -FilePath $ffMPegPath -ArgumentList $ffmpegArg -Wait -NoNewWindow
    <#        if(!$leaveImages)
        {
        write-ezlogs 'Cleaning up jpegs' -showtime
        remove-item "$tempPath\*.jpg" -Force
        }else{
        write-ezlogs "Leaving images in: $tempPath" -showtime -Warning
    }#>

    if(test-path $tempPath)
    {
      return $tempPath
    }else{
      throw 'Error - Unable to find newly created file'
    }


  }

}
#---------------------------------------------- 
#endregion Update-MediaTimer Function
#----------------------------------------------
#New-ScreenShot -outFolder $Capture_Output_Path -tempPath $thisScript.TempFolder -ffMPegPath "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffmpeg.exe" -fps 60 -screen_Capture_Duration $Capture_Duration_Seconds -captureCursor 1 -Verbose
Export-ModuleMember -Function @('New-ScreenShot')

