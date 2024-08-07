function New-YoutubeApplication {
  <#
      .SYNOPSIS
      Creates and registers a new Secret Vault for storing Youtube credentials

  #>
  param (
    $thisApp,
    [string] $Name = $($thisApp.Config.App_Name),
    [string] $ConfigPath = "$($thisApp.Config.Current_Folder)\Resources\API\Youtube-API-Config.xml",
    [switch]$First_Run
  )
  if($ConfigPath -and $Name){
    if([System.IO.File]::Exists($ConfigPath)){
      write-ezlogs "[New-YoutubeApplication] >>>> Importing API Config file $ConfigPath" -showtime -LogLevel 2 -logtype Youtube
      $Client = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($ConfigPath))
      $RedirectUri = $Client.RedirectUri
      #$RedirectUri = 'http://localhost:8000/auth/complete'
    } 
    if($client.client_id){
      try {
        write-ezlogs "[New-YoutubeApplication] >>>> Attempting to create application SecretStore $Name" -showtime -LogLevel 2 -logtype Youtube
        try{
          Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($Name | ConvertTo-SecureString -AsPlainText -Force)
          $secretstore = Get-SecretVault -Name $Name -ErrorAction SilentlyContinue
          if(!$secretstore){
            write-ezlogs "[New-YoutubeApplication] >>>> Registrying new Secret Vault: $Name" -showtime -logtype Youtube -LogLevel 2
            $secretstore = Register-SecretVault -Name $Name -ModuleName "$($thisApp.Config.Current_Folder)\Modules\Microsoft.PowerShell.SecretStore" -DefaultVault -Description "Created by $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -PassThru
          }
          $secretstore = $secretstore.name 
          return $secretstore                          
        }catch{
          write-ezlogs "An exception occurred when setting or configuring the secret vault $Name" -CatchError $_ -showtime -enablelogs 
        }   
      }
      catch {
        write-ezlogs "Failed creating SecretStore $Name" -showtime -catcherror $_
      }
    }else{
      write-ezlogs "Unable to get API configuration from config path: $ConfigPath!" -showtime -warning -LogLevel 2 -logtype Youtube
      return    
    }
  }else{
    write-ezlogs "Cannot create new Youtube Application, must provide values for $ConfigPath and Name parameters" -showtime -warning -logtype Youtube
  }
}