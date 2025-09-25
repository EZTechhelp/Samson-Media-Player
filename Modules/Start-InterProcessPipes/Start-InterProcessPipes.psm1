<#
    .Name
    Start-InterProcessPipes

    .Version 
    0.1.0

    .SYNOPSIS
    Creates, monitors and manages inter process named pipes

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
#region Start-InterProcessPipes Function
#----------------------------------------------
function Start-InterProcessPipes{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    [string]$PipeName,
    [switch]$use_Runspace,
    [switch]$Verboselog
  )
  $InterProcessPipes_ScriptBlock = {
    [CmdletBinding()]
    param (
      $synchash,
      $thisApp,
      [string]$PipeName,
      [switch]$use_Runspace,
      [switch]$Verboselog
    )
    try{
      if(!$PipeName -and $thisApp.Config.Installed_AppID){
        $PipeName = $thisApp.Config.Installed_AppID
      }elseif(!$PipeName){
        Import-Module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking
        $PipeName = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        $thisApp.Config.Installed_AppID = $PipeName
      }
      if($PipeName){
        $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
        $thisApp.InterProcessPipes = $true
        while ($thisApp.InterProcessPipes)
        {        
          try{
            write-ezlogs ">>>> Starting new InterProcessPipes instance with name: $($PipeName)"
            $PipeSecurity = [System.IO.Pipes.PipeSecurity]::new()
            $PipSID = [System.Security.Principal.SecurityIdentifier]::new([System.Security.Principal.WellKnownSidType]::WorldSid,$null)
            $PipAccessRule = [System.IO.Pipes.PipeAccessRule]::new($PipSID, [System.IO.Pipes.PipeAccessRights]::ReadWrite, [System.Security.AccessControl.AccessControlType]::Allow)
            $PipeSecurity.SetAccessRule($PipAccessRule)
            #Different constructor depending on PS version
            if($psversiontable.PSVersion.Major -gt 5){
              $InterProcessPipe = [System.IO.Pipes.NamedPipeServerStreamAcl]::Create($PipeName,[System.IO.Pipes.PipeDirection]::In,1,[System.IO.Pipes.PipeTransmissionMode]::Byte,[System.IO.Pipes.PipeOptions]::Asynchronous,512,512,$PipeSecurity)
            }else{
              $InterProcessPipe = [System.IO.Pipes.NamedPipeServerStream]::new($PipeName,[System.IO.Pipes.PipeDirection]::In,1,[System.IO.Pipes.PipeTransmissionMode]::Byte,[System.IO.Pipes.PipeOptions]::Asynchronous,512,512,$PipeSecurity)       
            }
            $Token = [System.Threading.CancellationTokenSource]::new()
            $wait = $InterProcessPipe.WaitForConnectionAsync($Token.Token)
            do{
              if($thisApp.Config.Dev_mode -or $Verboselog){write-ezlogs "....Waiting for Named Pipe Connection" -Dev_mode:($thisApp.Config.Dev_mode -or $Verboselog)}
              [System.Threading.Thread]::Sleep(500)
            }while(!$Wait.IsCanceled -and !$wait.IsCompleted -and $thisApp.InterProcessPipes)
            if($thisApp.InterProcessPipes){
              $sr = [System.IO.StreamReader]::new($InterProcessPipe)
              while (($cmd= $sr.ReadLine()) -ne 'exit' -and $thisApp.InterProcessPipes -and $InterProcessPipe.IsConnected) 
              {
                #Process each command or line written from client side of pipe
                if($cmd){
                  write-ezlogs ">>>> Received InterProcessPipes message: $($cmd) - IsConnected: $($InterProcessPipe.IsConnected)"
                  try{  
                    if(([system.io.file]::Exists($cmd) -and $cmd -match $media_pattern) -or [system.io.directory]::Exists($cmd)){      
                      $media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_URL $cmd
                      if($media){
                        $synchash.Temporary_Playback_Media = $media
                        Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Startup
                      }elseif($cmd -or [system.io.directory]::Exists($cmd)){
                        write-ezlogs -text "| Importing media file: $cmd" -showtime
                        Import-Media -Media_Path $cmd -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisApp.config.Media_Profile_Directory  -thisApp $thisApp -StartPlayback
                      }
                    }elseif((Test-ValidPath -path $cmd -Type URL) -and $cmd -match 'yewtu\.be|youtu\.be|youtube\.com|twitch\.tv|spotify\.com'){
                      if($cmd -match 'yewtu\.be|youtu\.be|youtube\.com'){
                        $type = 'Youtube'
                      }elseif($cmd -match 'twitch\.tv'){
                        $type = 'Twitch'
                      }elseif($cmd -match 'spotify\.com'){
                        $type = 'Spotify'
                      }
                      write-ezlogs -text "| Executing Start-NewMedia for type: $type" -showtime
                      Start-NewMedia -synchash $synchash -thisApp $thisApp -Mediaurl $cmd -Use_Runspace -MediaType $type
                    }else{
                      write-ezlogs -text 'Command line is not valid or supported!' -showtime -Warning
                    }
                  }catch{
                    write-ezlogs -text "An exception occurred importing or play provided media from command line: $cmd" -showtime -CatchError $_
                  }
                }
              }
              if($cmd -eq 'Exit' -or !$thisApp.InterProcessPipes){
                write-ezlogs "| Received exit command, shutting down InterProcessPipes" -warning
                $thisApp.InterProcessPipes = $false
                return
              }elseif(!$InterProcessPipe.IsConnected){
                write-ezlogs "| InterProcessPipe is no longer connected, terminating session" -warning
                continue
              }
            }else{
              return
            }
          }catch{
            write-ezlogs "An exception occurred in namedpipeserverstream: $PipeName" -CatchError $_
            $thisApp.InterProcessPipes = $false
          }finally{
            if($sr -is [System.IDisposable]){
              $sr.Dispose()
            }
            if($InterProcessPipe -is [System.IDisposable]){
              $InterProcessPipe.Dispose()
            }
            if($Wait -is [System.IDisposable] -and ($Wait.IsCanceled -or $wait.IsCompleted -or $Wait.IsFaulted)){
              $Wait.Dispose()
            }
            if($Token -is [System.IDisposable]){
              $Token.dispose()
            }
          }
        }
      }else{
        write-ezlogs "Cannot start NamedPipeServerStream - no Pipe Name provided!" -warning
      }
    }catch{
      write-ezlogs "An exception occurred in InterProcessPipes_scriptblock" -showtime -catcherror $_
    }finally{
      write-ezlogs "InterProcessPipes_Runspace has ended!" -warning
    }
  }
  if($use_Runspace){
    Start-Runspace $InterProcessPipes_ScriptBlock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "InterProcessPipes_Runspace" -thisApp $thisapp -RestrictedRunspace -function_list 'write-ezlogs' -cancel_runspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
  }else{
    Invoke-Command -ScriptBlock $InterProcessPipes_ScriptBlock -ArgumentList $synchash,$thisApp,$PipeName,$use_Runspace,$Verboselog
  }
}
#----------------------------------------------
#endregion Start-InterProcessPipes Function
#----------------------------------------------

#---------------------------------------------- 
#region Send-PipesMessage Function
#----------------------------------------------
function Send-PipesMessage{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    [string]$PipeName,
    [string]$Message,
    [switch]$use_Runspace,
    [switch]$Verboselog
  )
  $SendPipesMessage_ScriptBlock = {
    [CmdletBinding()]
    param (
      $synchash,
      $thisApp,
      [string]$PipeName,
      [string]$Message,
      [switch]$use_Runspace,
      [switch]$Verboselog
    )
    try{
      if(!$PipeName -and $thisApp.Config.Installed_AppID){
        $PipeName = $thisApp.Config.Installed_AppID
      }elseif(!$PipeName){
        Import-Module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking
        $PipeName = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        $thisApp.Config.Installed_AppID = $PipeName
      }
      if($PipeName -and $Message){
        write-ezlogs ">>>> Sending new message to Pipe: $($PipeName) - Message: $($Message)"
        $pipe = [System.IO.Pipes.NamedPipeClientStream]::new('.',$PipeName,[System.IO.Pipes.PipeDirection]::Out)
        $pipe.Connect()
        $sw = [System.IO.StreamWriter]::new($pipe)
        $sw.WriteLine($Message)
      }else{
        write-ezlogs "Cannot send Pipe message - no Pipe name or message was provided!" -warning
      }
    }catch{
      write-ezlogs "An exception occurred in SendPipesMessage_scriptblock" -showtime -catcherror $_
    }finally{
      if($sw -is [System.IDisposable]){
        $sw.dispose()
      }
      if($pipe -is [System.IDisposable]){
        $pipe.dispose()
      }
    }
  }
  if($use_Runspace){
    Start-Runspace $SendPipesMessage_ScriptBlock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "SendPipesMessage_Runspace" -thisApp $thisapp -RestrictedRunspace -function_list 'write-ezlogs'
  }else{
    Invoke-Command -ScriptBlock $SendPipesMessage_ScriptBlock -ArgumentList $synchash,$thisApp,$PipeName,$Message,$use_Runspace,$Verboselog
  }
}
#----------------------------------------------
#endregion Send-PipesMessage Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-InterProcessPipes','Send-PipesMessage')