function Get-AccessToken {
  [CmdletBinding()]
  param (
    [switch] $DeviceToken,
    $thisApp = $thisApp,
    $thisScript = $thisScript,
    $synchash = $synchash,
    [string] $Name = 'EZT-MediaPlayer'
  )
  $ErrorActionPreference = 'stop'
  try {
    if (!$PSBoundParameters['DeviceToken']) {
      # Return OAuth token obtained via web flow (preferred)
      Write-Verbose -Message 'Returning oAuth token from web-based authentication flow'      
      try{
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "An exception occurred getting SecretStore $name" -showtime -catcherror $_
      }
      if($secretstore){
        $secretstore = $secretstore.name     
        try{
          $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
        }        
        if($access_token){
          try{
            return @{
              Authorization = 'Bearer {0}' -f $access_token
            }                     
          }catch{
            write-ezlogs "An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
          }        
        }else{
          write-ezlogs "Unable to get access token, starting Youtube authorization capture process" -showtime -warning
          try{
            Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript    
            try{
              $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
            }catch{
              write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
            } 
            if($access_token){
              try{
                return @{
                  Authorization = 'Bearer {0}' -f $access_token
                }                     
              }catch{
                write-ezlogs "An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
              }        
            }else{
              write-ezlogs "Unable to get Youtube access token!" -showtime -warning
              return $false
            }                          
          }catch{
            write-ezlogs "An exception occurred executing Grant-YoutubeOauth" -showtime -catcherror $_
          }  
        }               
      }     
    }
    else {
      # Return access token from device authentication flow
      try{
        $Name = $($thisApp.Config.App_Name)
        $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
        $vaultconfig = Get-SecretStoreConfiguration
        if(!$vaultconfig){
          if([System.IO.File]::Exists($ConfigPath)){
            write-ezlogs ">>>> Importing API Config file $ConfigPath" -showtime
            $Client = Import-Clixml $ConfigPath
          }
          Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($client.client_id | ConvertTo-SecureString -AsPlainText -Force)
        }
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
        if(!$secretstore){
          Register-SecretVault -Name $Name -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
          $secretstore = $Name
        }else{
          $secretstore = $secretstore.name
        } 
        $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
        $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue                        
      }catch{
        write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs
      }
      if($access_token -and $refresh_access_token){
        return @{
          Authorization = 'Bearer {0}' -f $access_token
        }   
      }else{
        write-ezlogs "Unable to get access token, starting Youtube authorization capture process" -showtime -warning
        try{
          Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript    
          try{
            $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $secretstore -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          } 
          if($access_token){
            try{
              return @{
                Authorization = 'Bearer {0}' -f $access_token
              }                     
            }catch{
              write-ezlogs "An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
            }        
          }else{
            write-ezlogs "Unable to get Youtube access token!" -showtime -warning
            return $false
          }                          
        }catch{
          write-ezlogs "An exception occurred executing Grant-YoutubeOauth" -showtime -catcherror $_
        }     
      }      
    }
  }
  catch {
    throw 'Please use Set-YouTubeConfiguration to authorize the YouTube module for PowerShell.'
  }
}