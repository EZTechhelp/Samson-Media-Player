function Grant-YoutubeOauth {
  <#
      .SYNOPSIS
      Implementation of oAuth authentication for YouTube APIs.

      .PARAMETER BrowserCommand
      Use this parameter to override the command line to launch your browser (ie. chrome.exe, firefox, firefox.exe, chromium, etc.)
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [string] $BrowserCommand,  #$HOME/.pwsh.youtube.config.json
    $thisApp,
    $thisScript,
    [string] $Name = $($thisApp.Config.App_Name),
    [string] $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml",
    [switch]$First_Run
    
  )
  if([System.IO.File]::Exists($ConfigPath)){
    write-ezlogs ">>>> Importing API Config file $ConfigPath" -showtime
    $Client = Import-Clixml $ConfigPath
    $RedirectUri = $Client.RedirectUri
    #$RedirectUri = 'http://localhost:8000/auth/complete'
    #$Client = Get-Content -Path $ConfigPath | ConvertFrom-Json
  } 
  if($client.client_id){
    try {
      write-ezlogs ">>>> Attempting to save application to SecretStore Youtube" -showtime
      try{
        $vaultconfig = Get-SecretStoreConfiguration
        if(!$vaultconfig){
          Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($client.client_id | ConvertTo-SecureString -AsPlainText -Force)
        }
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
        if(!$secretstore){
          Register-SecretVault -Name $Name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
          $secretstore = $Name
        }else{
          $secretstore = $secretstore.name
        }                  
      }catch{
        write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs
      }   
    }
    catch {
      write-ezlogs "Failed creating SecretStore $Name : $($PSItem[0].ToString())" -showtime -catcherror $_
    }
  }else{
    write-ezlogs "Unable to get API configuration from config path: $ConfigPath!" -showtime -warning
    return    
  }
  $JobName = 'youtubetempwebserver'
  
  $pode_Youtube_scriptblock = { 
    try{
      if(!(Get-command -Module Pode)){         
        try{  
          write-ezlogs ">>> Importing Module PODE" -showtime
          Import-Module "$($thisApp.Config.Current_folder)\Modules\Pode\2.6.2\Pode.psm1" -Force    
        }catch{
          write-ezlogs "An exception occurred Importing required module Pode" -showtime -catcherror $_
        }     
      }       
      Start-PodeServer -Name 'EZT-MediaPlayer_PODE' -Threads 2  {
        write-ezlogs '[Start-PodeServer] >>>> Starting PodeServer for Youtube Auth Redirect capture for http://127.0.0.1:8000/auth/complete' -showtime -color cyan
        foreach($module in $thisApp.Config.Script_Modules){Import-Module $module}    
        Add-PodeEndpoint -Port 8000 -Protocol Http -PassThru -Force   
        Add-PodeRoute -Method Get -Path /auth/complete -PassThru -ScriptBlock {
          $logfile = $using:logfile
          $thisapp = $using:thisapp
          $Name = $using:Name
          $secretstore = $using:secretstore
          $synchash = $using:synchash
          $access_token = $WebEvent.Query['access_token'] 
          write-ezlogs ">>>> Received response from Pode path localhost:8080/auth/complete - $access_token" -showtime -logfile $logfile                 
          $access_token_json = @{
            access_token = $access_token
          } | ConvertTo-Json          
          # Try to save application to file.
          if($access_token){
            try{ 
              write-ezlogs ">>>> Attempting to save secret YoutubeAccessToken to SecretStore $Name" -showtime -logfile $logfile -enablelogs                             
              Set-Secret -Name YoutubeAccessToken -Secret $access_token -Vault $secretstore
            }catch{
              write-ezlogs "An exception occurred when setting or configuring the secret store $Name" -CatchError $_ -showtime -logfile $logfile -enablelogs
            }
            try {  
              write-ezlogs ">>>> Attempting to export access token to: $HOME/.pwsh.youtube.oauth.json" -showtime -logfile $logfile -enablelogs
              $access_token_json | Set-Content -Path $HOME/.pwsh.youtube.oauth.json    
            }
            catch {
              write-ezlogs "Failed to export json : $($PSItem[0].ToString())" -showtime -logfile $logfile -enablelogs -catcherror $_
            }
          }else{
            write-ezlogs ">>>> Received response from Pode path localhost:8080/auth/complete - $($WebEvent.query | out-string )" -showtime -logfile $logfile            
          }
          $Response = @'
        <h1 style="font-family: sans-serif;">Authentication Complete</h1>
        <h3 style="font-family: sans-serif;">You may close this browser window.</h3>
        <script>
          console.log(window.location.hash);
          let access_token_regex = /access_token=(?<access_token>.*?)&token_type/;
          let result = access_token_regex.exec(window.location.hash);
          fetch(`/auth/complete?access_token=${result.groups.access_token}`);
        </script>
'@           
          Write-PodeHtmlResponse -Value $Response                 
        }                    
      } 
    }catch{
      write-ezlogs 'An exception occurred in pode_youtube_scriptblock' -showtime -catcherror $_
    }
    if($error){
      write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
    }  
  } 

  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $pode_Youtube_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'PODE_YOUTUBE_RUNSPACE' -thisApp $thisApp -synchash $synchash
  $ScopeList = @( # requesting all existing scopes
    'https://www.googleapis.com/auth/youtube',
    'https://www.googleapis.com/auth/youtube.force-ssl',
    'https://www.googleapis.com/auth/youtube.readonly'
  ) -join '%20'
  <#  $ScopeList = @(
      'https://www.googleapis.com/auth/youtube'
      'https://www.googleapis.com/auth/youtube.force-ssl'
      'https://www.googleapis.com/auth/youtube.readonly'
  )#>
  $Uri = 'https://accounts.google.com/o/oauth2/v2/auth?include_granted_scopes=true&response_type=token&client_id={0}&redirect_uri={1}&scope={3}&state={2}' -f $Client.client_id, $RedirectUri, (New-Guid).Guid, ($ScopeList -join ' ')
  if($thisApp){
    try{
      if($hashsetup.Window.isVisible){
        $WaitingSetupWindow = $true
        $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{  
            $hashsetup.Window.hide() 
        }) 
      }else{
        $WaitingSetupWindow = $false
      }
      if($synchash.Window.isVisible){
        $WaitingMainWindow = $true
        $synchash.Window.Dispatcher.Invoke("Normal",[action]{  
            $synchash.Window.hide()  
        })      
      }else{
        $WaitingMainWindow = $false
      }            
      Show-WebLogin -SplashTitle "Youtube Account Login" -Message "Please login with your Youtube/Google account. When finished click Close to continue" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube_Auth.png" -WebView2_URL $URI -thisScript $thisScript -thisApp $thisApp -verboselog -First_Run $First_Run       
      start-sleep 1
      $wait = 0
      while($MahDialog_hash.Window.isVisible -and $wait -lt 300){
        write-ezlogs ">>>> Waiting for WebLogin window to close..." -showtime
        $wait++
        start-sleep 1
      }
      if($WaitingMainWindow -and $synchash.Window.IsInitialized -and !$synchash.Window.isVisible){
        try{
          write-ezlogs ">>>> Unhiding Main Window" -showtime
          $synchash.Window.Dispatcher.Invoke("Normal",[action]{  
              $synchash.Window.Show() 
          })  
        }catch{
          write-ezlogs "An exception occurred attempting to show synchash.window" -showtime -catcherror $_
        }
      }
      if($WaitingSetupWindow -and $hashsetup.Window.IsInitialized -and !$hashsetup.Window.isVisible){
        try{
          write-ezlogs ">>>> Unhiding Setup Window" -showtime
          $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{  
              $hashsetup.Window.ShowDialog() 
          })   
        }catch{
          write-ezlogs "An exception occurred attempting to show hashsetup.Window" -showtime -catcherror $_
        } 
      }           
      if($wait -ge 300){
        write-ezlogs "Timed out waiting for Weblogin window to close!" -showtime -warning
      }
    }catch{
      write-ezlogs "[Grant-YoutubeOauth] An exception occurred in Show-Weblogin" -showtime -catcherror $_
    }     
  }
  #$Browser = $BrowserCommand | ? $BrowserCommand : (Find-Browser)
  #Write-Verbose -Message ('Browser command line is: ' -f $Browser)
  #Start-Process -FilePath $Browser -ArgumentList ('"{0}"' -f $Uri) -Wait

}