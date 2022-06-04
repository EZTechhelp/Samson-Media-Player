<#
    .Name
    Get-LoadScreen 

    .Version 
    0.1.1

    .SYNOPSIS
    Displays simple graphic splash screen while app is loading or waiting for tasks to complete  

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
using namespace System.Windows.Data
using namespace System.Windows.Markup
#---------------------------------------------- 
#region close-SplashScreen Function
#----------------------------------------------
function close-SplashScreen (){
  $hash.window.Dispatcher.Invoke("Normal",[action]{ 
 
      $hash.window.close() 
  
  })
    
}
#---------------------------------------------- 
#endregion close-SplashScreen Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-SplashScreen Function
#----------------------------------------------
function Start-SplashScreen{
  Param (
    [string]$SplashTitle,
    [switch]$ShowDialog,
    [switch]$PlayAudio,
    [string]$Runspace_name,
    $thisScript,
    [string]$Current_folder,
    [string]$Splash_More_Info,
    [string]$SplashLogo,
    [switch]$verboselog,
    [switch]$firstRun,
    [switch]$start_hidden,
    [switch]$Startup,
    [switch]$Setup,
    [switch]$Debug_verboselog,
    $log_file,
    [switch]$startup_perf_timer,
    $startup_stopwatch,
    $Script_Modules,
    [string]$SplashMessage
  )  
    
  if(!$log_file){
    $log_file = $thisApp.Config.Log_File
  }
  $splash_logo = "$($current_folder)\\Resources\\MusicPlayerFilltest.ico"
  if($Startup){
    try{       
      if($setup){
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Globalization") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
        $Assemblies = (Get-childitem "$Current_Folder" -Filter "*.dll" -Force -Recurse)
      }else{    
        $Assemblies = [System.IO.Directory]::EnumerateFiles("$Current_Folder\\Assembly",'*.dll','AllDirectories')    
        #$Assemblies = (Get-childitem "$Current_Folder\\Assembly" -Filter "*.dll" -Force -Recurse)
      }           
      #$script:Assembly_Names = ($Assemblies).BaseName    
      #$thisScript.Version | out-file "$Current_Folder\\Resources\Version_check.txt"
      foreach ($a in $Assemblies)
      {       
        #$Assembly = $a.fullName
        #$Assembly_Name = $a.BaseName
        #$Assembly_Name = [System.IO.Path]::GetFileNameWithoutExtension($a)
        if($a -notmatch 'WebView2Loader'){
          if($Debug_verboselog){write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] >>>> Loading assembly $a" | out-file $log_file -Force -Append -Encoding unicode}
          $null = [System.Reflection.Assembly]::LoadFrom($a)
        }          
      }
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred loading assemblines -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding unicode
    } 
  }
  
  if(!$Runspace_name){
    $Runspace_name = "Start_SplashScreen_$((Get-PSCallStack)[1].FunctionName)"
  } 
  $global:hash = [hashtable]::Synchronized(@{}) 
  $Splash_Pwshell = {
    try{     
      if($setup){
        $Splash_Window_XML = "$($Current_Folder)\\Splash.xaml"
      }else{
        $Splash_Window_XML = "$($Current_Folder)\\Views\\Splash.xaml"   
      }       
      [xml]$xaml = [System.IO.File]::ReadAllText($Splash_Window_XML).replace('Views/Styles.xaml',"$($Current_Folder)`\Views`\Styles.xaml")   
      $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
      $hash.window = [Windows.Markup.XamlReader]::Load($reader)
      [xml]$xaml = $xaml
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$hash."$($_.Name)" = $hash.window.FindName($_.Name)}  
      
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred loading Splash.XAML -- '$($_ | Select *)'" | out-file $log_file -Force -Append -Encoding unicode
    }
    #$hash.LoadingLabel = $hash.window.FindName("LoadingLabel")
    #$hash.Logo = $hash.window.FindName("Logo")
    $hash.Window.icon = $splash_logo
    $hash.Logo.Source=$splash_logo
    $hash.SplashTitle = $hash.window.FindName("SplashTitle")
    $hash.WindowSplash = $hash.window.FindName("WindowSplash")
    $hash.More_Info_Msg = $hash.window.FindName("More_info_Msg")
    $hash.window.title =$SplashTitle
    $hash.SplashTitle.Content=$SplashTitle
    $hash.LoadingLabel.Content= $SplashMessage
    $hash.More_Info_Msg.text= "$Splash_More_Info"
    #$hash.Background_Image.source = "$($Current_Folder)\\ByrnePlayer\DavidByrneTour.png"
    #$hash.Background_Image.Stretch = "UniformToFill"
    
    $hash.Window.Add_Loaded({
        if($PlayAudio){
          try{     
            $Paragraph = New-Object System.Windows.Documents.Paragraph
            $media_url = "$($Current_Folder)\Resources\Audio\Do_it_live.mp4"
            $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer  
            $Floater = New-Object System.Windows.Documents.Floater
            $Floater.HorizontalAlignment = "Center" 
            $Floater.Name = "Media_Floater"
            if($media_url -match '.gif' -or $media_url -match '.mp3' -or $media_url -match '.mp4'){ 
              $Media_Element = New-object System.Windows.Controls.MediaElement 
              $Media_Element.UnloadedBehavior = 'Close'  
              $Media_Element.LoadedBehavior="Manual"  
              $Media_Element.Name = 'Media_Element'     
              $Media_Element.Source = $media_url   
              $Media_Element.Play()   
              $Media_Element.Add_MediaEnded({   
                  param($Sender) 
                  $hash.SplashRichText.Visibility = 'Hidden'  
                  $this.Stop()
                  $this.tag = $Null
                  $this.close()
              })    
              $Media_Element.add_MediaFailed({
                  param($Sender) 
                  write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] An exception occurred in medial element $($sender | out-string)" | out-file $log_file -Force -Append -Encoding unicode
                  $this.Stop()
                  $this.tag = $Null
                  $this.close()                   
              }.GetNewClosure())                    
              $BlockUIContainer.AddChild($Media_Element) 
            }   
            $floater.AddChild($BlockUIContainer)   
            $Paragraph.addChild($floater)
            $hash.SplashRichText.Visibility = 'Visible'
            $null = $hash.SplashRichText.Document.Blocks.Add($Paragraph)
      
          }catch{
            write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred loading Splash.XAML -- '$($_ | Select *)'" | out-file $log_file -Force -Append -Encoding unicode
          }
        }else{
          $hash.SplashRichText.Visibility = 'Hidden'
        }
    })
    
    #---------------------------------------------- 
    #region Cancel Button
    #----------------------------------------------
    $hash.Cancel_Button.add_Click({
        try{   
          Write-Output ">>>> User selected cancel...exiting" | Out-File -FilePath $log_file -Encoding unicode -Append  
          $hash.window.close() 
          if((Get-Process -Name "*yt-dlp*"))
          {
            write-ezlogs ">>>> Closing yt-dlp processes" -showtime -color cyan
            Get-Process -Name "*yt-dlp*" | Stop-Process -Force -ErrorAction SilentlyContinue 2> $null
          }          
          [GC]::Collect() 
          if($pid)
          {
            Stop-Process $pid -Force
          }                    
        }catch{
          Write-Output "[ERROR] An exception occurred in cancel_button click event`n$($_.exception.message)`n$($_.InvocationInfo.positionmessage)`n$($_.ScriptStackTrace)`n`n" | Out-File -FilePath $log_file -Encoding unicode -Append
          if($pid)
          {
            Stop-Process $pid -Force
          }
        }
    }.GetNewClosure())
    #---------------------------------------------- 
    #endregion Cancel Button
    #----------------------------------------------    
    
    
    #Add Exit
    
    $hash.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $hash.Window){        
          try{
            if($verboselog){write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] >>>> Splash Screen Closed" | out-file $log_file -Force -Append -Encoding unicode} 
            $hash = $Null
            return        
          }catch{
            write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred closing Splash window-- '$($_ | Select *)'" | out-file $log_file -Force -Append -Encoding unicode
            return
          }
        }         
    }.GetNewClosure())    

    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hash.Window)
    [void][System.Windows.Forms.Application]::EnableVisualStyles()   
    try{
      if($firstRun){
        $hash.window.TopMost = $false
      }      
      if(!$start_hidden){
        if($verboselog){write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] Seconds to Start-SplashScreen: $($startup_stopwatch.Elapsed.TotalSeconds)" | out-file $log_file -Force -Append -Encoding unicode} 
        $null = $hash.window.ShowDialog()
        $window_active = $hash.Window.Activate() 
      }
      $hashContext = New-Object Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($hashContext)             
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred when opening main Get-LoadScreen window -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding unicode
    }     
  }
  try{ 
    $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
    $Start_RunSpace_Measure = measure-command{
      $Start_RunSpace = Start-Runspace $Splash_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name $Runspace_name -logfile $Log_file -startup_stopwatch $startup_stopwatch -verboselog:$verboselog -startup_perf_timer $startup_perf_timer
    }
    $Start_SplashScreen_Perf = "[$(Get-date -format 'MM/dd/yyyy h:mm:ss tt')] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Start-SplashScreen:  $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"
    if($startup_perf_timer){
      return "$Start_RunSpace`n[$(Get-date -format 'MM/dd/yyyy h:mm:ss tt')]     | Start_RunSpace Total: $($Start_RunSpace_Measure.Seconds) seconds - $($Start_RunSpace_Measure.Milliseconds) Milliseconds`n$Start_SplashScreen_Perf"
    }            
  }catch{
    write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] [ERROR] An exception occurred when opening main Get-LoadScreen window -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding unicode
    if((get-command -module write-ezlogs)){
      Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs 
    }          
    Stop-Process $pid 
  }   
}
#---------------------------------------------- 
#endregion Start-SplashScreen Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-SplashScreen','close-SplashScreen')