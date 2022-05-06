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
    $log_file,
    $Script_Modules,
    [string]$SplashMessage
  )  
    
  $global:hash = [hashtable]::Synchronized(@{})
  $Global:splash_logo = "$($current_folder)\\Resources\\MusicPlayerFilltest.ico"
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
        $Assemblies = (Get-childitem "$Current_Folder\\Assembly" -Filter "*.dll" -Force -Recurse)
      }     
      
      #$script:Assembly_Names = ($Assemblies).BaseName    
      #$thisScript.Version | out-file "$Current_Folder\\Resources\Version_check.txt"
      foreach ($a in $Assemblies)
      {       
        $Assembly = $a.fullName
        $Assembly_Name = $a.BaseName
        if($Assembly_Name -ne 'WebView2Loader'){
          if($verboselog){write-ezlogs ">>>> Loading assembly $assembly" -showtime -color cyan}
          $null = [System.Reflection.Assembly]::LoadFrom($Assembly)
        }          
      }
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [ERROR] An exception occurred loading assemblines -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding utf8 
    } 
  }
  
  if(!$Runspace_name){
    $GUID = (New-GUID).Guid
    $Runspace_name = "Start_SplashScreen_$GUID"
  }  
  $Splash_Pwshell = {
    try{
     
      if($setup){
        $Splash_Window_XML = "$($Current_Folder)\\Splash.xaml"
      }else{
        $Splash_Window_XML = "$($Current_Folder)\\Views\\Splash.xaml"   
      }       
      [xml]$xml = [System.IO.File]::ReadAllText($Splash_Window_XML).replace('Views/Styles.xaml',"$($Current_Folder)`\Views`\Styles.xaml") 
      $reader = New-Object System.Xml.XmlNodeReader $xml
      $hash.window = [Windows.Markup.XamlReader]::Load($reader)
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [ERROR] An exception occurred loading Splash.XAML -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding utf8 
    }
    $hash.LoadingLabel = $hash.window.FindName("LoadingLabel")
    $hash.Logo = $hash.window.FindName("Logo")
    $hash.Logo.Source=$splash_logo
    $hash.SplashTitle = $hash.window.FindName("SplashTitle")
    $hash.WindowSplash = $hash.window.FindName("WindowSplash")
    $hash.More_Info_Msg = $hash.window.FindName("More_info_Msg")
    $hash.window.title =$SplashTitle
    $hash.SplashTitle.Content=$SplashTitle
    $hash.LoadingLabel.Content= $SplashMessage
    $hash.More_Info_Msg.text= "$Splash_More_Info"
    #Add Exit
    
    $hash.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $hash.Window){        
          try{
            write-ezlogs " Splash Screen Closed" -showtime
            return
           # if($Startup){
           # }         
          }catch{
            write-ezlogs "An exception occurred closing Splash window" -showtime -catcherror $_
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
        $null = $hash.window.ShowDialog()
        $window_active = $hash.Window.Activate() 
      }
      $hashContext = New-Object Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($hashContext)             
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [ERROR] An exception occurred when opening main Get-LoadScreen window -- '$($_ | out-string)'" | out-file $log_file -Force -Append -Encoding utf8 
    }     
  } 
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $Splash_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -runspace_name $Runspace_name -logfile $Log_file -Script_Modules $thisApp.Config.Script_Modules
  
}
#---------------------------------------------- 
#endregion Start-SplashScreen Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-SplashScreen','close-SplashScreen')



  