function Get-AccessToken {
  [CmdletBinding()]
  param (
    [switch]$DeviceToken,
    [switch]$NoHeader,
    [switch]$ForceTokenRefresh,
    $thisApp = $thisApp,
    $synchash = $synchash,
    [string] $Name = $thisApp.Config.App_Name
  )
  $ErrorActionPreference = 'stop'
  try {
    if ($Name) {
      try{
        $Name = $($thisApp.Config.App_Name)
        $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml"
        $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue 
        if(!$secretstore){
          write-ezlogs "[Get-AccessToken] >>>> Attempting to create new application: $Name" -showtime -LogLevel 2 -logtype Youtube
          $secretstore = New-YoutubeApplication -thisApp $thisApp -Name $Name -ConfigPath $ConfigPath
        }else{
          $secretstore = $Name
          write-ezlogs "[Get-AccessToken] >>>> Retrieved SecretVault: $secretstore" -showtime -LogLevel 3 -logtype Youtube
          $access_token = Get-secret -name YoutubeAccessToken  -Vault $secretstore -ErrorAction SilentlyContinue
          $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $secretstore -ErrorAction SilentlyContinue 
          $access_token_expires = Get-secret -name Youtubeexpires_in -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          if(!$access_token -or !$refresh_access_token){
            write-ezlogs "[Get-AccessToken] Missing access_token $($access_token) or refresh_access_token $($refresh_access_token), trying again in case of transient issue" -showtime -warning -LogLevel 2 -logtype Youtube
            start-sleep -Milliseconds 500
            $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
            $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }
        }                                                     
      }catch{
        write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime
      }
      if($access_token -and $refresh_access_token){
        if($access_token_expires -le (Get-date) -or !$access_token -or $ForceTokenRefresh){
          write-ezlogs "[Get-AccessToken] Attempting to refresh access token - ForceTokenRefresh: $ForceTokenRefresh - access_token_expires: $($access_token_expires) - access_token: $($access_token)" -showtime -warning -LogLevel 2 -logtype Youtube
          try{
            Grant-YoutubeOauth -thisApp $thisApp
            $access_token = Get-secret -name YoutubeAccessToken -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          }
        }
        if($access_token){
          if($NoHeader){
            return $access_token
          }else{
            write-ezlogs " | Found YoutubeAccessToken and Youtuberefresh_token - building and returning Authorization header" -showtime -LogLevel 3 -logtype Youtube
            return @{
              Authorization = 'Bearer {0}' -f $access_token
            }
          }        
        }else{
          write-ezlogs "Unable to get Youtube access token!" -showtime -warning -LogLevel 2 -logtype Youtube
          return $false
        }  
      }else{
        write-ezlogs "[Get-AccessToken] Unable to get access token, starting Youtube authorization capture process" -showtime -warning -LogLevel 2 -logtype Youtube
        try{
          Grant-YoutubeOauth -thisApp $thisApp   
          try{
            $access_token = Get-secret -name YoutubeAccessToken -Vault $secretstore -ErrorAction SilentlyContinue
          }catch{
            write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
          } 
          if($access_token){
            try{
              if($NoHeader){
                return $access_token
              }else{
                write-ezlogs " | Found YoutubeAccessToken and Youtuberefresh_token - building and returning Authorization header" -showtime -LogLevel 3 -logtype Youtube
                return @{
                  Authorization = 'Bearer {0}' -f $access_token
                }
              }
                     
            }catch{
              write-ezlogs "An exception occurred getting Secrets for Access_Token" -showtime -catcherror $_
            }        
          }else{
            write-ezlogs "Unable to get Youtube access token!" -showtime -warning -LogLevel 2 -logtype Youtube
            return $false
          }                          
        }catch{
          write-ezlogs "An exception occurred executing Grant-YoutubeOauth" -showtime -catcherror $_
        }     
      }      
    }
  }
  catch {
    write-ezlogs 'An exception occurred in Get-AccessToken' -showtime -catcherror $_
  }
}