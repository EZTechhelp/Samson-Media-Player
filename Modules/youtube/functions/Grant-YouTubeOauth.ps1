
<#
    .Name
    Grant-YoutubeOauth

    .Version 
    0.1.0

    .SYNOPSIS
    Implementation of oAuth authentication for YouTube APIs 

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
#region Grant-YoutubeOauth Function
#----------------------------------------------
function Grant-YoutubeOauth {
  <#
      .SYNOPSIS
      Implementation of oAuth authentication for YouTube APIs.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    $thisApp,
    [string]$Name = $($thisApp.Config.App_Name),
    [string]$ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml",
    [switch]$First_Run,
    $MahDialog_hash = $MahDialog_hash   
  )
  if([System.IO.File]::Exists($ConfigPath)){
    write-ezlogs "[Grant-YoutubeOauth] >>>> Importing API Config file $ConfigPath" -showtime -LogLevel 2 -logtype Youtube -Dev_mode
    $Client = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($ConfigPath))
    $RedirectUri = $Client.RedirectUri
  } 
  $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
  if(!$secretstore){
    write-ezlogs "[Grant-YoutubeOauth] >>>> Couldnt find secret vault, Attempting to create new application: $Name" -showtime -LogLevel 2 -logtype Youtube
    try{
      $secretstore = New-YoutubeApplication -thisApp $thisApp -Name $Name -ConfigPath $ConfigPath
    }catch{
      write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs 
    }   
  }else{
    $secretstore = $secretstore.name 
    write-ezlogs "[Grant-YoutubeOauth] >>>> Retrieved SecretVault: $secretstore" -showtime -LogLevel 3 -logtype Youtube    
  }

  #try refreshing token
  try{
    $refresh_access_token = Get-secret -name Youtuberefresh_token -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  }catch{
    write-ezlogs "[Grant-YoutubeOauth] An exception occurred getting Youtube secret Youtuberefresh_token for vault $($thisApp.Config.App_name)" -CatchError $_ -showtime
  }  
  if(!$refresh_access_token){
    write-ezlogs "[Grant-YoutubeOauth] Missing refresh_access_token, trying again in case of transient issue" -showtime -warning -LogLevel 2 -logtype Youtube
    start-sleep -Milliseconds 500
    try{
      $refresh_access_token = Get-secret -name Youtuberefresh_token -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "[Grant-YoutubeOauth] An exception occurred when retrying to get Youtube secret Youtuberefresh_token for vault $($thisApp.Config.App_name)" -CatchError $_ -showtime
    }
  }
  if($refresh_access_token){
    $refresh_Uri = 'https://oauth2.googleapis.com/token?&grant_type=refresh_token&client_id={0}&client_secret={1}&refresh_token={2}' -f $Client.client_id,$Client.client_secret,$refresh_access_token
    try{
      write-ezlogs "[Grant-YoutubeOauth] >>>> Attempting to refresh access token" -showtime -LogLevel 2 -logtype Youtube
      write-ezlogs "[Grant-YoutubeOauth] | URL: $refresh_Uri" -showtime -LogLevel 2 -logtype Youtube -Dev_mode      
      $refresh_response = Invoke-RestMethod -Method Post -Uri $refresh_Uri -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "[Grant-YoutubeOauth] An exception occurred attempting to refresh the youtube access token" -CatchError $_ -showtime
    }
    if($refresh_response.access_token){
      Set-Secret -Name YoutubeAccessToken -Secret $refresh_response.access_token -Vault $secretstore
      write-ezlogs "[Grant-YoutubeOauth] Refreshed access_token" -showtime -LogLevel 2 -logtype Youtube -Success
      if($refresh_response.expires_in){
        $token_expires = (Get-date).AddSeconds($refresh_response.expires_in)  
        Set-Secret -Name Youtubeexpires_in -Secret "$($token_expires)" -Vault $secretstore
        write-ezlogs "[Grant-YoutubeOauth] | Refresh token expires_in: $($token_expires)" -showtime -LogLevel 2 -logtype Youtube
      }
      return      
    }else{
      write-ezlogs "[Grant-YoutubeOauth] Did not receive refresh token! - Response: $refresh_response" -showtime -warning -LogLevel 2 -logtype Youtube
    } 
  }else{
    write-ezlogs "[Grant-YoutubeOauth] Did not receive refresh token from Youtuberefresh_token secret of vault $($thisApp.Config.App_name) - Web Dialog Window Visible: $($MahDialog_hash.Window.isVisible)" -showtime -warning -logtype Youtube
  }
  if($MahDialog_hash.Window.isVisible){
    write-ezlogs "[Grant-YoutubeOauth] WebCapture window is alreay open! Not launching another" -showtime -warning -logtype Youtube
    return
  }else{
    write-ezlogs "[Grant-YoutubeOauth] Starting Youtube Web Auth capture" -showtime -warning -logtype Youtube
  }
  $pode_Youtube_scriptblock = { 
    try{
      if(!(Get-command -Module Pode)){         
        try{  
          write-ezlogs "[Grant-YoutubeOauth] >>>> Importing Module PODE" -showtime -LogLevel 2 -logtype Youtube
          Import-Module "$($thisApp.Config.Current_folder)\Modules\Pode\Pode.psm1" -Force -NoClobber -DisableNameChecking -Scope Local
        }catch{
          write-ezlogs "[Grant-YoutubeOauth] An exception occurred Importing required module Pode" -showtime -catcherror $_
        }     
      } 
      try{  
        $podestate = Get-PodeServerPath -ErrorAction SilentlyContinue 
        if($podestate){
          write-ezlogs "[Grant-YoutubeOauth] >>>> Current PODE Server state: $($podestate | out-string)" -logtype Youtube
        }       
      }catch{
        write-ezlogs "[Grant-YoutubeOauth] An exception occurred closing existing pode server" -showtime -catcherror $_
      }            
      Start-PodeServer -Name "$($thisApp.Config.App_Name)_Youtube_PODE" -Threads 1 {
        try{    
          write-ezlogs '[Start-PodeServer] >>>> Starting PodeServer for Youtube Auth Redirect capture for http://127.0.0.1:8080/auth/complete' -showtime -color cyan -LogLevel 2 -logtype Youtube       
          write-ezlogs '[Start-PodeServer] | Adding PodeEndpoint -Address 127.0.0.1 -Port 8080 -Protocol Http' -showtime -color cyan -LogLevel 2 -logtype Youtube
          Add-PodeEndpoint -Address 127.0.0.1 -Port 8000 -Protocol Http -PassThru -Force
          write-ezlogs '[Start-PodeServer] | Adding PodeRoute -Method Get -Path /CLOSE_YT_PODE' -showtime -color cyan -LogLevel 2 -logtype Youtube 
          Add-PodeRoute -Method Get -Path '/CLOSE_YT_PODE' -PassThru -ScriptBlock {
            #$logfile = $using:logfile
            $thisapp = $using:thisapp
            $Name = $using:Name
            $secretstore = $using:secretstore
            $synchash = $using:synchash
            $client = $using:client
            write-ezlogs ">>>> Youtube Auth webevent sent [CLOSE_YT_PODE]: Close-PodeServer" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
            $PodeServerNetStat = ((NETSTAT.EXE -an).where({$_ -match '127.0.0.1:8000' -or $_ -match '0.0.0.0:8000'}))
            if($PodeServerNetStat){
              write-ezlogs " | Executing Close-PodeServer - Netstat: $($PodeServerNetStat)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
              Close-PodeServer
            }else{
              write-ezlogs "Received request to close Youtube Auth PODE server, but no pode server matching 127.0.0.1:8000 was found" -showtime -warning -LogLevel 2 -logtype Youtube -thisApp $thisApp
            }
          }
          write-ezlogs '[Start-PodeServer] | Adding PodeRoute -Method Get -Path /auth/complete' -showtime -color cyan -LogLevel 2 -logtype Youtube 
          Add-PodeRoute -Method Get -Path '/auth/complete' -PassThru -ScriptBlock  {
            #$logfile = $using:logfile
            $thisapp = $using:thisapp
            $Name = $using:Name
            $secretstore = $using:secretstore
            $synchash = $using:synchash
            $client = $using:client
            $code = $WebEvent.Query['code'] 
            $expires_in = $WebEvent.Query['expires_in']
            write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Received response from Pode path localhost:8000/auth/complete - Expires_in: $($expires_in)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp        
            # Try to save application to file.
            if($code){
              try{ 
                write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Attempting to save secret Youtubecode to SecretStore: $Name" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp                           
                Set-Secret -Name Youtubecode -Secret $code -Vault $secretstore
                $Response_Uri = 'https://oauth2.googleapis.com/token?&grant_type=authorization_code&client_id={0}&client_secret={1}&redirect_uri={2}&code={3}' -f $Client.client_id,$Client.client_secret, $Client.RedirectUri,$code
                try {
                  write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Attempting to request youtube access token from: https://oauth2.googleapis.com/token?&grant_type=authorization_code" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
                  $auth_response = Invoke-RestMethod -Method Post -Uri $Response_Uri
                }catch {
                  write-ezlogs "[Add-PodeRoute-AuthComplete] An exception occurred in invoke-restmethod for $Response_Uri" -CatchError $_ -showtime -thisApp $thisApp
                }
                try{
                  if($auth_response.access_token){
                    $access_token_json = @{access_token = $auth_response.access_token} | ConvertTo-Json
                    write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Received authorization access_token" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp -Success 
                    Set-Secret -Name YoutubeAccessToken -Secret $auth_response.access_token -Vault $secretstore
                    write-ezlogs "[Add-PodeRoute-AuthComplete] | Saved secret YoutubeAccessToken to vault: $($secretstore)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp  
                  }
                  if($auth_response.refresh_token){
                    write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Received authorization refresh_token" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
                    Set-Secret -Name Youtuberefresh_token -Secret $auth_response.refresh_token -Vault $secretstore
                    write-ezlogs "[Add-PodeRoute-AuthComplete] | Saved secret Youtuberefresh_token to vault: $($secretstore)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
                  }
                  if($auth_response.expires_in){
                    $token_expires = (Get-date).AddSeconds($auth_response.expires_in)  
                    write-ezlogs "[Add-PodeRoute-AuthComplete]>>>> Received authorization expires_in $($token_expires)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp 
                    Set-Secret -Name Youtubeexpires_in -Secret "$($token_expires)" -Vault $secretstore
                    write-ezlogs "[Add-PodeRoute-AuthComplete] | Saved secret Youtubeexpires_in to vault: $($secretstore)" -showtime -LogLevel 2 -logtype Youtube -thisApp $thisApp
                  }
                }catch{
                  write-ezlogs "[Add-PodeRoute-AuthComplete] An exception occurred saving Youtube Auth response $($auth_response | out-string)" -CatchError $_ -thisApp $thisApp
                }               
              }catch{
                write-ezlogs "[Add-PodeRoute-AuthComplete] An exception occurred when setting or configuring the secret store $Name" -CatchError $_ -thisApp $thisApp
              }
            }else{
              write-ezlogs "[Add-PodeRoute-AuthComplete] >>>> Did not receive Youtubecode from Pode path localhost:8000/auth/complete - WebEvent.Query: $($WebEvent.query | out-string )" -showtime -LogLevel 2 -thisApp $thisApp -Warning
            }         
            $Response = @'
        <h1 style="font-family: sans-serif;">Authentication Complete</h1>
        <h3 style="font-family: sans-serif;">This window should automatically close or you may manually close this window.</h3>
        <script>
          console.log(window.location.hash);
          let access_token_regex = /access_token=(?<access_token>.*?)&token_type/;
          let result = access_token_regex.exec(window.location.hash);
          fetch(`/auth/complete?access_token=${result.groups.access_token}`);
        </script>
'@
            Write-PodeHtmlResponse -Value $Response         
          }
        }catch{
          write-ezlogs "[Grant-YoutubeOauth] An exception occurred in Start-PodeServer scriptblock" -catcherror $_
        }                            
      } 
    }catch{
      write-ezlogs '[Grant-YoutubeOauth] An exception occurred in pode_youtube_scriptblock' -showtime -catcherror $_
    }
    if($error){
      write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error -LogLevel 2
      $error.clear()
    }  
  }
  $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace -scriptblock $pode_Youtube_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'PODE_YOUTUBE_RUNSPACE' -thisApp $thisApp -synchash $synchash -cancel_runspace
  Remove-Variable Variable_list
  $ScopeList = @( # requesting all existing scopes
    'https://www.googleapis.com/auth/youtube',
    'https://www.googleapis.com/auth/youtube.force-ssl',
    'https://www.googleapis.com/auth/youtube.readonly'
  ) -join '%20'
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
      if($synchash.Window.isVisible -and !$synchash.MiniPlayer_Viewer){
        $WaitingMainWindow = $true
      }else{
        $WaitingMainWindow = $false
      }
      $MahDialog_hash = Show-WebLogin -SplashTitle "Youtube Account Login" -MarkDownFile "$($thisApp.Config.Current_Folder)\Resources\Docs\Settings\Youtube_WebAuth.md"  -SplashLogo "$($thisApp.Config.Current_Folder)\Resources\Youtube\Material-Youtube_Auth.png" -WebView2_URL $URI -thisApp $thisApp -First_Run $First_Run -MahDialog_hash $MahDialog_hash    
      $wait = 0
      while(!$MahDialog_hash.Window.isVisible){
        write-ezlogs ">>>> Waiting for WebLogin window to open..." -showtime -LogLevel 2 -logtype Youtube
        start-sleep -Milliseconds 500
      }
      while($MahDialog_hash.Window.isVisible -and $wait -lt 600){
        write-ezlogs ">>>> Waiting for WebLogin window to close..." -showtime -LogLevel 2 -logtype Youtube
        $wait++
        start-sleep 1
      }
      if($WaitingSetupWindow -and $hashsetup.Window.IsInitialized -and !$hashsetup.Window.isVisible -and !$hashsetup.Save_Setup_Button_clicked){
        try{
          write-ezlogs ">>>> Unhiding Setup Window" -showtime -LogLevel 2 -logtype Youtube
          try{          
            write-ezlogs ">>> Verifying Youtube authentication" -showtime -LogLevel 2 -logtype Youtube
            $access_token = Get-secret -name YoutubeAccessToken -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          }            
          try{
            if($access_token -and $refresh_access_token){
              write-ezlogs "Successfully retrieved Youtube access and refresh tokens" -LogLevel 2 -logtype Youtube -Success
              if($hashsetup.Update_YoutubeStatus_Timer){
                write-ezlogs " | Starting Update_YoutubeStatus_Timer" -LogLevel 2 -logtype Youtube
                $hashsetup.Update_YoutubeStatus_Timer.tag = 'AuthSuccess'
              }                 
            }else{
              write-ezlogs "Failed to retrieve Youtube access and refresh tokens" -LogLevel 2 -logtype Youtube -Warning
              if($hashsetup.Update_YoutubeStatus_Timer){
                write-ezlogs " | Starting Update_YoutubeStatus_Timer" -LogLevel 2 -logtype Youtube
                $hashsetup.Update_YoutubeStatus_Timer.tag = 'AuthFail'
              }              
            }
            $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{  
                $null = $hashsetup.Window.Show()
            })             
          }catch{
            write-ezlogs "An exception occurred attempting to show hashsetup.Window" -showtime -catcherror $_
          }      
        }catch{
          write-ezlogs "An exception occurred attempting to show hashsetup.Window" -showtime -catcherror $_
        } 
      } 
      if($WaitingMainWindow -and $synchash.Window.IsInitialized -and !$synchash.Window.isVisible){
        try{
          write-ezlogs ">>>> Unhiding Main Window" -showtime -logtype Youtube -LogLevel 2
          $synchash.Window.Dispatcher.Invoke("Normal",[action]{  
              $synchash.Window.Show()
          })  
        }catch{
          write-ezlogs "An exception occurred attempting to show synchash.window" -showtime -catcherror $_
        }
      }                         
      if($wait -ge 600){
        write-ezlogs "Timed out waiting for Weblogin window to close!" -showtime -warning -logtype Youtube
      }
      return
    }catch{
      write-ezlogs "[Grant-YoutubeOauth] An exception occurred in Show-Weblogin" -showtime -catcherror $_
    }finally{
      $PodeServerNetStat = ((NETSTAT.EXE -an).where({($_ -match '127.0.0.1:8000' -or $_ -match '0.0.0.0:8000') -and $_ -match 'LISTENING|ESTABLISHED'}))
      if($PodeServerNetStat){
        try{ 
          write-ezlogs ">>>> Closing PodeServer for Youtube Auth Redirect capture with url: http://127.0.0.1:8000/CLOSE_YT_PODE - Netstat: $($PodeServerNetStat) - Get-PodeServerPath: $(Get-PodeServerPath)" -showtime -logtype Youtube -LogLevel 2        
          Invoke-RestMethod -Uri 'http://127.0.0.1:8000/CLOSE_YT_PODE' -UseBasicParsing -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occurred Closing PodeServer for Youtube Auth Redirect capture with url: http://127.0.0.1:8000/CLOSE_YT_PODE" -showtime -catcherror $_
        }
      }  
    }     
  }
}
#---------------------------------------------- 
#endregion Grant-YoutubeOauth Function
#----------------------------------------------