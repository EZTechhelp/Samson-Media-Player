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
      write-ezlogs "[Grant-YoutubeOauth] >>>> Attempting to save application to SecretStore Youtube" -showtime
      try{
        $vaultconfig = Get-SecretStoreConfiguration
        if(!$vaultconfig){
          write-ezlogs "[Grant-YoutubeOauth] | Setting secretstoreconfiguration" -showtime
          Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($client.client_id | ConvertTo-SecureString -AsPlainText -Force)
        }
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
        if(!$secretstore){
          write-ezlogs "[Grant-YoutubeOauth] | Registering new secret vault $name" -showtime
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
  
  
  #try refreshing token
  $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  if($refresh_access_token){
    $refresh_Uri = 'https://oauth2.googleapis.com/token?&grant_type=refresh_token&client_id={0}&client_secret={1}&refresh_token={2}' -f $Client.client_id,$Client.client_secret,$refresh_access_token
    try{
      write-ezlogs ">>>> Attempting to refresh access token - URL: $refresh_Uri" -showtime
      $refresh_response = Invoke-RestMethod -Method Post -Uri $refresh_Uri 
    }catch{
      write-ezlogs "An exception occurred in invoke-restmethod for $refresh_Uri" -CatchError $_ -showtime
    }
    if($refresh_response.access_token){
      $access_token_json = @{
        access_token = $refresh_response.access_token
      } | ConvertTo-Json
      Set-Secret -Name YoutubeAccessToken -Secret $refresh_response.access_token -Vault $secretstore
      write-ezlogs "Refreshed access_token $($refresh_response.access_token)" -showtime 
      if($refresh_response.expires_in){
        $token_expires = (Get-date).AddSeconds($refresh_response.expires_in)  
        Set-Secret -Name Youtubeexpires_in -Secret "$($token_expires)" -Vault $secretstore
        write-ezlogs "Refreshed expires_in $($token_expires)" -showtime
      }
      return      
    }
  }
  $global:MahDialog_hash = [hashtable]::Synchronized(@{})
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
          $client = $using:client
          $MahDialog_hash = $using:MahDialog_hash
          $code = $WebEvent.Query['code'] 
          $expires_in = $WebEvent.Query['expires_in'] 
          write-ezlogs ">>>> Received response from Pode path localhost:8080/auth/complete - $code" -showtime -logfile $logfile  
          write-ezlogs ">>>> Received response from Pode path localhost:8080/auth/complete - $expires_in" -showtime -logfile $logfile                          
          # Try to save application to file.
          if($code){
            try{ 
              write-ezlogs ">>>> Attempting to save secret Youtubecode to SecretStore $Name" -showtime -logfile $logfile -enablelogs                             
              Set-Secret -Name Youtubecode -Secret $code -Vault $secretstore
              $Response_Uri = 'https://oauth2.googleapis.com/token?&grant_type=authorization_code&client_id={0}&client_secret={1}&redirect_uri={2}&code={3}' -f $Client.client_id,$Client.client_secret, $Client.RedirectUri,$code
              try {
                $auth_response = Invoke-RestMethod -Method Post -Uri $Response_Uri 
                if($auth_response.access_token){
                  $access_token_json = @{
                    access_token = $auth_response.access_token
                  } | ConvertTo-Json
                  Set-Secret -Name YoutubeAccessToken -Secret $auth_response.access_token -Vault $secretstore
                  write-ezlogs "Received authorization access_token $($auth_response.access_token)" -showtime -logfile $logfile -enablelogs  
                }
                if($auth_response.refresh_token){
                  Set-Secret -Name Youtuberefresh_token -Secret $auth_response.refresh_token -Vault $secretstore
                  write-ezlogs "Received authorization refresh_token $($auth_response.refresh_token)" -showtime -logfile $logfile -enablelogs
                }
                if($auth_response.expires_in){
                  $token_expires = (Get-date).AddSeconds($auth_response.expires_in)  
                  Set-Secret -Name Youtubeexpires_in -Secret "$($token_expires)" -Vault $secretstore
                  write-ezlogs "Received authorization expires_in $($token_expires)" -showtime -logfile $logfile -enablelogs
                }                
              }
              catch {
                write-ezlogs "An exception occurred in invoke-restmethod for $Response_Uri" -CatchError $_ -showtime -logfile $logfile -enablelogs
              }
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
  $Uri = 'https://accounts.google.com/o/oauth2/v2/auth?include_granted_scopes=true&access_type=offline&response_type=code&prompt=consent&client_id={0}&redirect_uri={1}&scope={3}&state={2}' -f $Client.client_id, $RedirectUri, (New-Guid).Guid, ($ScopeList -join ' ')
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
        #$synchash.Window.Dispatcher.Invoke("Normal",[action]{  
        #    $synchash.Window.hide()  
        #})      
      }else{
        $WaitingMainWindow = $false
      }            
      Show-WebLogin -SplashTitle "Youtube Account Login" -Message "Please login with your Youtube/Google account. When finished click Close to continue" -SplashLogo "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube_Auth.png" -WebView2_URL $URI -thisScript $thisScript -thisApp $thisApp -verboselog -First_Run $First_Run -MahDialog_hash $MahDialog_hash    
      start-sleep 2
      $wait = 0
      while($MahDialog_hash.Window.isVisible -and $wait -lt 600){
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
          try{ 
            write-ezlogs ">>> Verifying Youtube authentication" -showtime
            $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          }           
          $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{  
              if($access_token -and $refresh_access_token){
                write-ezlogs "[SUCCESS] Authenticated to Youtube and retrieved access tokens" -showtime -color green 
                $hashsetup.Import_Youtube_transitioningControl.Height = 0
                $hashsetup.Youtube_Playlists_Import.isEnabled = $true
                $hashsetup.Import_Youtube_transitioningControl.content = ''
                $hashsetup.Import_Youtube_textbox.text = ''
                if($MahDialog_hash.window.Dispatcher -and $MahDialog_hash.window.isVisible){
                  $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
                }  
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
                update-EditorHelp -content "[SUCCESS] Authenticated to Youtube and saved access tokens into the Secret Vault! You may close this message" -color lightgreen -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout                           
              }else{
                write-ezlogs "[Show-FirstRun] Unable to successfully authenticate to Youtube!" -showtime -warning
                $hashsetup.Import_Youtube_Playlists_Toggle.isOn = $false
                $hashsetup.Youtube_Playlists_Import.isEnabled = $false
                if($hashsetup.EditorHelpFlyout.Document.Blocks){
                  $hashsetup.EditorHelpFlyout.Document.Blocks.Clear()
                }        
                $hashsetup.Editor_Help_Flyout.isOpen = $true
                $hashsetup.Editor_Help_Flyout.header = 'Youtube'            
                update-EditorHelp -content "[WARNING] Unable to successfully authenticate to Youtube! Some Youtube features may be unavailable" -color orange -FontWeight Bold -RichTextBoxControl $hashsetup.EditorHelpFlyout               
              }          
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