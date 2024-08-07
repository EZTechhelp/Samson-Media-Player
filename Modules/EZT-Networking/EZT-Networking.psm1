<#
    .Name
    EZT-Networking

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of functions used to perform network related tasks such as troubleshooting, repair, management, configuration and others 

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
#region IP Subnet Functions
#---------------------------------------------- 
function checkSubnet ([string]$addr1, [string]$addr2)
{
  # Separate the network address and lenght
  $network1, [int]$subnetlen1 = $addr1.Split('/')
  $network2, [int]$subnetlen2 = $addr2.Split('/')
 
 
  #Convert network address to binary
  [uint32] $unetwork1 = NetworkToBinary $network1
 
  [uint32] $unetwork2 = NetworkToBinary $network2
 
 
  #Check if subnet length exists and is less then 32(/32 is host, single ip so no calculation needed) if so convert to binary
  if($subnetlen1 -lt 32){
    [uint32] $mask1 = SubToBinary $subnetlen1
  }
 
  if($subnetlen2 -lt 32){
    [uint32] $mask2 = SubToBinary $subnetlen2
  }
 
  #Compare the results
  if($mask1 -and $mask2){
    # If both inputs are subnets check which is smaller and check if it belongs in the larger one
    if($mask1 -lt $mask2){
      return CheckSubnetToNetwork $unetwork1 $mask1 $unetwork2
    }else{
      return CheckNetworkToSubnet $unetwork2 $mask2 $unetwork1
    }
  }ElseIf($mask1){
    # If second input is address and first input is subnet check if it belongs
    return CheckSubnetToNetwork $unetwork1 $mask1 $unetwork2
  }ElseIf($mask2){
    # If first input is address and second input is subnet check if it belongs
    return CheckNetworkToSubnet $unetwork2 $mask2 $unetwork1
  }Else{
    # If both inputs are ip check if they match
    CheckNetworkToNetwork $unetwork1 $unetwork2
  }
}
function CheckNetworkToSubnet ([uint32]$un2, [uint32]$ma2, [uint32]$un1)
{
  $ReturnArray = "" | Select-Object -Property Condition,Direction
 
  if($un2 -eq ($ma2 -band $un1)){
    $ReturnArray.Condition = $True
    $ReturnArray.Direction = "Addr1ToAddr2"
    return $ReturnArray
  }else{
    $ReturnArray.Condition = $False
    $ReturnArray.Direction = "Addr1ToAddr2"
    return $ReturnArray
  }
}
function CheckSubnetToNetwork ([uint32]$un1, [uint32]$ma1, [uint32]$un2)
{
  $ReturnArray = "" | Select-Object -Property Condition,Direction
 
  if($un1 -eq ($ma1 -band $un2)){
    $ReturnArray.Condition = $True
    $ReturnArray.Direction = "Addr2ToAddr1"
    return $ReturnArray
  }else{
    $ReturnArray.Condition = $False
    $ReturnArray.Direction = "Addr2ToAddr1"
    return $ReturnArray
  }
}
function CheckNetworkToNetwork ([uint32]$un1, [uint32]$un2)
{
  $ReturnArray = "" | Select-Object -Property Condition,Direction
 
  if($un1 -eq $un2){
    $ReturnArray.Condition = $True
    $ReturnArray.Direction = "Addr1ToAddr2"
    return $ReturnArray
  }else{
    $ReturnArray.Condition = $False
    $ReturnArray.Direction = "Addr1ToAddr2"
    return $ReturnArray
  }
}
 
function SubToBinary ([int]$sub)
{
  return ((-bnot [uint32]0) -shl (32 - $sub))
}
 
function NetworkToBinary ($network)
{
  $a = [uint32[]]$network.split('.')
  return ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]
}
#---------------------------------------------- 
#endregion IP Subnet Functions
#---------------------------------------------- 

#---------------------------------------------- 
#region Test-Internet function
#----------------------------------------------
Function Test-Internet
{
  param (
    [Parameter(Mandatory=$true)]
    [string]$address,
    [string]$Secondaryaddress,
    [switch]$autofix,
    [switch]$returnbool,
    [switch]$forcerepair,
    $thisApp = $thisApp,
    [int]$PrimaryCount = 1,
    [int]$SecondaryCount = 2,
    [int]$loglevel = $thisApp.Config.Log_Level,
    [switch]$External_IP_Check

  )
  write-ezlogs "##### Testing Internet Connection #####" -showtime:$false -linesbefore 1 -LogLevel:$loglevel
  if(!$address){
    write-ezlogs "No internet address was provided to test, cannot continue!" -Warning
    return
  }
  $testinternet = Test-Connection -computer $address -count $PrimaryCount -quiet -ErrorAction SilentlyContinue
  if($Secondaryaddress -and !$testinternet){
    start-sleep 1
    $testinternet = Test-Connection -computer $Secondaryaddress -count $SecondaryCount -quiet
    if($testinternet){
      write-ezlogs "Connection test to secondary address $Secondaryaddress was successful" -LogLevel:$loglevel
    }else{
      write-ezlogs "Connection test to secondary address $Secondaryaddress was not successful" -warning
    }
  }
  if(!($testinternet)){   
    write-ezlogs ">>>>Internet Connection Status: Connection Down..." -warning
    #$computerinfo = Get-computerinfo
    #write-ezlogs "`n#### Computer Summary Info ####" -color yellow -LogOnly -LogLevel:$loglevel
    #write-ezlogs $($computerinfo | out-string) -LogOnly
    $testinternet = Test-Connection -computer $address -count $PrimaryCount -quiet -ErrorAction SilentlyContinue
    if($autofix){
      write-ezlogs "#### Attempting to Diagnose and fix internet connection ####" -Color yellow
      $netadapters = Get-NetAdapter | Select-Object Name,Status, LinkSpeed
      write-ezlogs "$netadapters" -LogOnly
      foreach ($adapter in $netadapters)
      {
        write-ezlogs "Net Adapter: $($adapter.name)" -showtime
        write-ezlogs " | LinkSpeed: $($adapter.LinkSpeed)" -showtime
        if ($adapter.status -ne "Up")
        {
          write-ezlogs " | Status: $($adapter.status)" -Color red -showtime
        }
        else
        {
          write-ezlogs " | Status: $($adapter.status)" -showtime
        }
        if($adapter.name -match "Wi-fi" -and $adapter.status -eq "Disabled")
        {
          write-ezlogs ">>>>The Wifi adapter appears to be disabled, attempting to enable..." -Color yellow -showtime
          Get-NetAdapter -Name *Wi-Fi* | Where-Object status -eq disabled | Enable-NetAdapter -Confirm:$false
          start-sleep -seconds 5
          write-ezlogs " | Wifi Enabled" -showtime
          write-ezlogs " | Waiting 5 seconds...then testing connection again" -showtime
          start-sleep -Seconds 5
          $testinternet = Test-Connection -computer $address -count 1 -quiet
          if ($testinternet)
          {
            write-ezlogs ">>> Connection up!" -showtime -color Green
            $internetstatus = $true
          }
          else
          {
            write-ezlogs ">>>> Connection still down...attempting reconnect to all known WLAN Profiles" -Warning -showtime
            $wlanprofiles = netsh wlan show profiles
            if ($wlanprofiles)
            {
              Start-sleep -Seconds 2
              copy-item "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html" "c:\users\public\desktop"
              write-ezlogs "Copying WLAN Report File to Desktop...." -showtime
            }
            $wlanreport = netsh wlan show wlanreport
            $wlaninterfaces = netsh wlan show interfaces
            $ssidSearchResult = $wlanprofiles | select-string -Pattern 'All User Profile'
            $profilenames = ($ssidSearchResult -split ":").Trim()
            foreach ($ssid in $profilenames | Where-Object {$_ -ne "All User Profile"})
            {
              write-ezlogs "Connecting to SSID: $ssid" -showtime -color Cyan
              $netshconnect = Netsh WLAN connect name="$ssid" interface="$($adapter.name)"
              if ($netshconnect -match "Connection request was completed successfully")
              {
                write-ezlogs " | Successfully connected to SSID: $ssid" -showtime -color green
                $ssidprofile = netsh wlan show profiles name="$ssid" key=clear 
                $ssidpwsearch = $ssidprofile | select-string -pattern 'Key Content'
                $ssidpw = ($ssidpwsearch -split ":")[-1].Trim() -replace '"' 
                write-ezlogs "NETSHCONNECT Details:`n" -showtime -logOnly
                write-ezlogs $($netshconnect | out-string) -logOnly
                write-ezlogs "`n#### SSID Details for $ssid ####" -logOnly
                write-ezlogs " | SSID: $ssid" -showtime -logOnly
                write-ezlogs " | PASS: $ssidpw" -showtime -logOnly
                write-ezlogs "`n#### WLAN Profiles ####" -logOnly
                write-ezlogs  $($wlanprofiles | out-string) -logOnly
                write-ezlogs "`n#### WLAN Report ####" -logOnly
                write-ezlogs  $($wlanreport | out-string) -logOnly
                write-ezlogs "`n#### WLAN Interfaces ####" -logOnly
                write-ezlogs  $($wlaninterfaces | out-string) -logOnly
                Start-sleep -Seconds 5
                write-ezlogs ">>>> Testing internet on SSID: $ssid" -showtime -color cyan
                $testinternet = Test-Connection -computer $address -count 1 -quiet
                if ($testinternet)
                {
                  write-ezlogs " | Connection up on SSID: $ssid" -showtime -color green
                  $internetstatus = $true
                  $testinternet = Test-Connection -computer $address -count 1
                  break
                }
                else
                {
                  write-ezlogs "[ERROR] Testing internet on SSID: $ssid failed!" -Color red -showtime
                }
              }
              else
              {
                write-ezlogs "#### Netshconnect Results for SSID $ssid ####" -LogOnly
                write-ezlogs $($netshconnect | out-string) -LogOnly
              }
            }
            write-ezlogs ">>>> Testing connection again" -showtime -color cyan
            Start-sleep -Seconds 5
            $testinternet = Test-Connection -computer $address -count 1 -quiet
            if ($testinternet)
            {
              write-ezlogs " | Connection up!" -showtime -color green
              $internetstatus = $true
              $testinternet = Test-Connection -computer $address -count 1
              break
            }
            else
            {
              write-ezlogs ">>>>Connection still down...." -Color red -showtime
              write-ezlogs "Attempting Final Repairs...." -showtime
              write-ezlogs "`n#### Collecting All Wi-Fi Profile Names ####" -LogOnly
              $wlanprofiles = netsh wlan show profiles
              $ssidSearchResult = $wlanprofiles | select-string -Pattern 'All User Profile'
              $profilenames = ($ssidSearchResult -split ":").Trim() | Where-Object {$_ -ne "All User Profile"}
              write-ezlogs $($profilenames | out-string) -LogOnly
              foreach ($ssid in $profilenames | Where-Object {$_ -ne "All User Profile"})
              {
                $netshconnect = Netsh WLAN connect name="$ssid" interface="$($adapter.name)"
              }
              write-ezlogs "`n#### Dumping Current DNS Cache ####" -LogOnly
              write-ezlogs " | Dumping Current DNS Cache ...." -showtime -LogOnly
              write-ezlogs (Get-DnsClientCache | out-string) -LogOnly
              write-ezlogs "`n#### Running IPConfig Release and Renew ####" -LogOnly
              write-ezlogs " | Running IPConfig Release and Renew...." -LogOnly -showtime
              write-ezlogs  (ipconfig /release | Out-string) -LogOnly
              write-ezlogs  (ipconfig /renew | Out-string) -LogOnly
              write-ezlogs "`n#### Running ARP -d ####" -LogOnly
              write-ezlogs " | Running ARP -d...." -LogOnly -showtime
              write-ezlogs  (arp -d * | Out-string) -LogOnly
              write-ezlogs "`n#### Running nbtstat -r and -rr ####" -LogOnly
              write-ezlogs " | Running nbtstat -r and -rr...." -LogOnly -showtime
              write-ezlogs  (nbtstat -R | Out-string) -LogOnly
              write-ezlogs  (nbtstat -RR | Out-string) -LogOnly
              write-ezlogs "`n#### Running IPconfig /flushdns and /registerdns ####" -LogOnly
              write-ezlogs " | Running IPconfig /flushdns and /registerdns...." -LogOnly -showtime
              write-ezlogs  (ipconfig /flushdns | Out-string) -LogOnly
              write-ezlogs  (ipconfig /registerdns | Out-string) -LogOnly
              write-ezlogs ">>>> Testing connection for final time" -showtime -color cyan
              $testinternet = Test-Connection -computer $address -count 1 -quiet
              if ($testinternet)
              {
                write-ezlogs " | Connection up!" -showtime -color green
                start-sleep -seconds 5
                $internetstatus = $true
                $testinternet = Test-Connection -computer $address -count 1
              }
              else
              {
                write-ezlogs "Connection still down...unable to repair" -Color red -showtime
                write-ezlogs "`n#### Collecting Troubleshooting Data to Log File ####" -Color yellow
                $internetstatus = $false
                $wlanreport = netsh wlan show wlanreport
                $wlaninterfaces = netsh wlan show interfaces
                $wlanprofiles = netsh wlan show profiles
                $networkadapters = Get-NetAdapter
                $adapterstats = Get-NetAdapterStatistics | Format-List
                $ipstats = netsh interface ipv4 show ipstats
                $netstats = netsh interface ipv4 show tcpconnections
                $rdp_eventlogs = Get-WinEvent -logname "Microsoft-Windows-TerminalServices-RDPClient/Operational" -ea silentlycontinue | where {$_.LevelDisplayName -eq "Warning" -and $_.timecreated -gt [datetime]::today}
                $eventlogs = Get-WinEvent -ListLog * -EA silentlycontinue | where-object { $_.recordcount -AND $_.lastwritetime -gt [datetime]::today} | foreach { get-winevent -LogName $_.logname -MaxEvents 1 } | Format-Table TimeCreated, ID, ProviderName, Message -AutoSize -Wrap
                write-ezlogs "`n#### Collecting WLAN Reports ####" -LogOnly
                write-ezlogs  $($wlanreport | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting WLAN Interfaces ####" -LogOnly
                write-ezlogs  $($wlaninterfaces | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting WLAN Profiles ####" -LogOnly
                write-ezlogs  $($wlanprofiles | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting Network Adapters ####" -LogOnly
                write-ezlogs  $($networkadapters | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting IP Stats ####" -LogOnly
                write-ezlogs  $($ipstats | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting Net Stats ####" -LogOnly
                write-ezlogs  $($netstats | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting Adapter Stats ####" -LogOnly
                write-ezlogs  $($adapterstats | Out-string) -LogOnly
                write-ezlogs "`n#### Collecting Recent Event Logs ####" -LogOnly
                write-ezlogs  $($eventlogs | Out-string) -LogOnly
                write-ezlogs "`n#### RDP Event Logs ####" -LogOnly
                write-ezlogs  $($rdp_eventlogs | Out-string) -LogOnly
                write-ezlogs " | Diagnostic data collected to log file: $($thisApp.Config.Log_file)" -showtime
                $msgboxtext = "There appears to be an issue with this computers internet connection. Unfortunately this application was unable to repair the problem. Please ensure your computer is connected to the internet and try again. 

                  Relevent diagnostic data has been gathered into a log file at: $($thisApp.Config.Log_file)

                  As internet is not working, this information cannot automatically be sent to EZTechhelp Support. 

                  Please contact EZTechhelp Support by emailing support@eztechhelp.com or via your normal means of contacting support. 

                  Thank you
                - EZTechhelp Automated Support"
                $msgBoxInput =  [System.Windows.MessageBox]::Show("$msgboxtext",'ERROR: LRAH Remote Access','Ok','Error')
                switch  ($msgBoxInput) {

                  'Ok' {

                    write-ezlogs "`n#### Displaying Error Message to User ####" -LogOnly
                    write-ezlogs "$msgboxtext" -LogOnly
                    write-ezlogs "User ($env:USERNAME) acknowledged dialog window and exited" -showtime -LogOnly
                    exit
                  }

                  'No' {

                    ## Do something

                  }
                  'Cancel' {

                    ## Do something

                  }

                }
              }  
            }
            
          }
        }
        elseif ($adapter.name -match "Wi-fi" -and $adapter.status -eq "Disconnected")
        {
          write-ezlogs ">>>> The Wifi adapter is enabled but is not currently connected to any Wifi network" -Color yellow -showtime
          write-ezlogs " | Attempting to disable and renable Wifi adapter" -showtime
          Get-NetAdapter -Name *Wi-Fi* | Where-Object status -eq Disconnected | Disable-NetAdapter -Confirm:$false
          write-ezlogs " | Wifi disabled...enabling..." -showtime
          Start-Sleep -seconds 5
          Get-NetAdapter -Name *Wi-Fi* | Where-Object status -eq Disabled | Enable-NetAdapter -Confirm:$false
          write-ezlogs " | Wifi Enabled" -showtime
          Start-Sleep -seconds 5
          write-ezlogs ">>>> Testing connection again" -showtime -color cyan
          $testinternet = Test-Connection -computer $address -count 1 -quiet
          if ($testinternet)
          {
            write-ezlogs " | Connection up!" -showtime -color green
            start-sleep -seconds 5
            $internetstatus = $true
            $testinternet = Test-Connection -computer $address -count 1
          }
          else
          {
            write-ezlogs ">>>> Connection still down...attempting reconnect to all known WLAN Profiles" -showtime -warning
            $wlanprofiles = netsh wlan show profiles
            $wlanreport = netsh wlan show wlanreport
            $wlaninterfaces = netsh wlan show interfaces
            $ssidSearchResult = $wlanprofiles | select-string -Pattern 'All User Profile'
            $profilenames = ($ssidSearchResult -split ":").Trim()
            foreach ($ssid in $profilenames | Where-Object {$_ -ne "All User Profile"})
            {
              write-ezlogs ">>>> Connecting to SSID: $ssid" -showtime -color cyan
              $netshconnect = Netsh WLAN connect name="$ssid"
              if ($netshconnect -match "Connection request was completed successfully")
              {
                write-ezlogs " | Successfully connected to SSID: $ssid" -showtime -color Green
                $ssidprofile = netsh wlan show profiles name="$ssid" key=clear 
                $ssidpwsearch = $ssidprofile | select-string -pattern 'Key Content'
                $ssidpw = ($ssidpwsearch -split ":")[-1].Trim() -replace '"' 
                write-ezlogs " | SSID: $ssid" -LogOnly
                write-ezlogs " | PASS: $ssidpw" -LogOnly
                write-ezlogs  $($wlanreport | Out-string) -LogOnly
                write-ezlogs  $($wlaninterfaces | Out-string) -LogOnly
                Start-sleep -Seconds 5
                write-ezlogs ">>>> Testing internet on SSID: $ssid" -showtime
                $testinternet = Test-Connection -computer $address -count 1 -quiet
                if ($testinternet)
                {
                  write-ezlogs " | Connection up on SSID: $ssid" -showtime -color green
                  $internetstatus = $true
                  $testinternet = Test-Connection -computer $address -count 1
                  break
                }
              }
            }

            write-ezlogs ">>>> Testing connection again...." -showtime -color Cyan
            $testinternet = Test-Connection -computer $address -count 1 -quiet
            if ($testinternet)
            {
              write-ezlogs " | Connection up!" -showtime -color Green
              start-sleep -seconds 5
              $internetstatus = $true
              $testinternet = Test-Connection -computer $address -count 1
            }
            else
            {
              write-ezlogs "Connection still down...creating diagnostic report" -warning -showtime
              $internetstatus = $false
              $wlanreport = netsh wlan show wlanreport
              $wlaninterfaces = netsh wlan show interfaces
              $wlanprofiles = netsh wlan show profiles
              write-ezlogs ($wlanreport | Out-string) -LogOnly
              write-ezlogs ($wlaninterfaces | Out-string) -LogOnly
              write-ezlogs ($wlanprofiles | Out-string) -LogOnly
            } 
          }
        }
        elseif ($adapter.name -match "Ethernet" -and $adapter.status -eq "Disabled")
        {
          write-ezlogs ">>>> The Ethernet adapter $($adapter.name) appears to be disabled, attempting to enable..." -showtime -Warning
          Get-NetAdapter -Name *Ethernet* | Where-Object status -eq disabled | Enable-NetAdapter -Confirm:$false
          start-sleep -seconds 5
          write-ezlogs " | Ethernet Adapter Enabled" -showtime
          write-ezlogs " | Waiting 5 seconds...then testing connection again" -showtime
          start-sleep -Seconds 5
          $testinternet = Test-Connection -computer $address -count 1 -quiet
          if ($testinternet)
          {
            write-ezlogs " | Connection up!" -showtime -color green
            $internetstatus = $true
          }
          else
          {
            write-ezlogs ">>>> Connection still down..." -Color red -showtime
            write-ezlogs "Attempting Final Repairs...." -showtime
            write-ezlogs "`n#### Dumping Current DNS Cache ####" -LogOnly
            write-ezlogs " | Dumping Current DNS Cache ...." -showtime -LogOnly
            write-ezlogs (Get-DnsClientCache | out-string) -LogOnly
            write-ezlogs "`n#### Running IPConfig Release and Renew ####" -LogOnly
            write-ezlogs " | Running IPConfig Release and Renew...." -LogOnly -showtime
            write-ezlogs  (ipconfig /release | Out-string) -LogOnly
            write-ezlogs  (ipconfig /renew | Out-string) -LogOnly
            write-ezlogs "`n#### Running ARP -d ####" -LogOnly
            write-ezlogs " | Running ARP -d...." -LogOnly -showtime
            write-ezlogs  (arp -d * | Out-string) -LogOnly
            write-ezlogs "`n#### Running nbtstat -r and -rr ####" -LogOnly
            write-ezlogs " | Running nbtstat -r and -rr...." -LogOnly -showtime
            write-ezlogs  (nbtstat -R | Out-string) -LogOnly
            write-ezlogs  (nbtstat -RR | Out-string) -LogOnly
            write-ezlogs "`n#### Running IPconfig /flushdns and /registerdns ####" -LogOnly
            write-ezlogs " | Running IPconfig /flushdns and /registerdns...." -LogOnly -showtime
            write-ezlogs  (ipconfig /flushdns | Out-string) -LogOnly
            write-ezlogs  (ipconfig /registerdns | Out-string) -LogOnly
            write-ezlogs ">>>> Testing connection for final time" -showtime -color cyan
            $testinternet = Test-Connection -computer $address -count 1 -quiet
            if ($testinternet)
            {
              write-ezlogs " | Connection up!" -showtime -color green
              start-sleep -seconds 5
              $internetstatus = $true
              $testinternet = Test-Connection -computer $address -count 1
            }
            else
            {
              write-ezlogs "Connection still down...unable to repair" -Color red -showtime
              write-ezlogs "`n#### Collecting Troubleshooting Data to Log File ####" -Color yellow
              $internetstatus = $false
              $wlanreport = netsh wlan show wlanreport
              $wlaninterfaces = netsh wlan show interfaces
              $wlanprofiles = netsh wlan show profiles
              $networkadapters = Get-NetAdapter
              $adapterstats = Get-NetAdapterStatistics | Format-List
              $ipstats = netsh interface ipv4 show ipstats
              $netstats = netsh interface ipv4 show tcpconnections
              $rdp_eventlogs = Get-WinEvent -logname "Microsoft-Windows-TerminalServices-RDPClient/Operational" -ea silentlycontinue | where {$_.LevelDisplayName -eq "Warning" -and $_.timecreated -gt [datetime]::today}
              $eventlogs = Get-WinEvent -ListLog * -EA silentlycontinue | where-object { $_.recordcount -AND $_.lastwritetime -gt [datetime]::today} | foreach { get-winevent -LogName $_.logname -MaxEvents 1 } | Format-Table TimeCreated, ID, ProviderName, Message -AutoSize -Wrap
              write-ezlogs "`n#### Collecting WLAN Reports ####" -LogOnly
              write-ezlogs  $($wlanreport | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting WLAN Interfaces ####" -LogOnly
              write-ezlogs  $($wlaninterfaces | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting WLAN Profiles ####" -LogOnly
              write-ezlogs  $($wlanprofiles | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting Network Adapters ####" -LogOnly
              write-ezlogs  $($networkadapters | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting IP Stats ####" -LogOnly
              write-ezlogs  $($ipstats | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting Net Stats ####" -LogOnly
              write-ezlogs  $($netstats | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting Adapter Stats ####" -LogOnly
              write-ezlogs  $($adapterstats | Out-string) -LogOnly
              write-ezlogs "`n#### Collecting Recent Event Logs ####" -LogOnly
              write-ezlogs  $($eventlogs | Out-string) -LogOnly
              write-ezlogs "`n#### RDP Event Logs ####" -LogOnly
              write-ezlogs  $($rdp_eventlogs | Out-string) -LogOnly
              write-ezlogs " | Diagnostic data collected to log file" -showtime
              $msgboxtext = "There appears to be an issue with this computers internet connection. Unfortunately this application was unable to repair the problem. Please ensure your computer is connected to the internet and try again. 

                Relevent diagnostic data has been gathered into a log file at: $($thisApp.Config.Log_file)

                As internet is not working, this information cannot automatically be sent to EZTechhelp Support. 

                Please contact EZTechhelp Support by emailing support@eztechhelp.com or via your normal means of contacting support. 

                Thank you
              - EZTechhelp Automated Support"
              $msgBoxInput =  [System.Windows.MessageBox]::Show("$msgboxtext",'ERROR: LRAH Remote Access','Ok','Error')
              switch  ($msgBoxInput) {

                'Ok' {

                  write-ezlogs "`n#### Displaying Error Message to User ####" -LogOnly
                  write-ezlogs "$msgboxtext" -LogOnly
                  write-ezlogs "User ($env:USERNAME) acknowledged dialog window and exited" -showtime -LogOnly
                  exit
                }

                'No' {

                  ## Do something

                }
                'Cancel' {

                  ## Do something

                }

              }
            }
          }
        
        }
      }
    }else{
      write-ezlogs "Autofix is not enabled, will not attempt to repair or diagnose internet issues" -Warning -showtime -LogLevel:$loglevel
    }
  }elseif($forcerepair){
    write-ezlogs ">>>> Force Repair Option Enabled" -Color cyan -showtime
    write-ezlogs "Attempting Internet Connection Repairs..." -showtime
    $netadapters = Get-NetAdapter | Select-Object Name,Status, LinkSpeed
    foreach ($adapter in $netadapters)
    {
      if ($adapter.name -match "Wi-fi" -and $adapter.status -eq "Up")
      {
        write-ezlogs "Attempting to disable and renable Wifi adapter" -showtime -LogOnly
        Get-NetAdapter -Name *Wi-Fi* | Where-Object status -eq Up | Disable-NetAdapter -Confirm:$false | write-ezlogs -logOnly
        write-ezlogs " | Wifi disabled...enabling..." -showtime -LogOnly
        Start-Sleep -seconds 5
        Get-NetAdapter -Name *Wi-Fi* | Where-Object status -eq Disabled | Enable-NetAdapter -Confirm:$false | write-ezlogs -logOnly
        write-ezlogs " | Wifi Enabled" -showtime -LogOnly
        Start-Sleep -seconds 5
      }
    }
    write-ezlogs "`n#### Dumping Current DNS Cache ####" -LogOnly
    write-ezlogs " | Dumping Current DNS Cache ...." -showtime -LogOnly
    write-ezlogs (Get-DnsClientCache | out-string) -LogOnly
    write-ezlogs "`n#### Running IPConfig Release and Renew ####" -LogOnly
    write-ezlogs " | Running IPConfig Release and Renew...." -LogOnly -showtime
    write-ezlogs  (ipconfig /release | Out-string) -LogOnly
    write-ezlogs  (ipconfig /renew | Out-string) -LogOnly
    write-ezlogs "`n#### Running ARP -d ####" -LogOnly
    write-ezlogs " | Running ARP -d...." -LogOnly -showtime
    write-ezlogs  (arp -d * | Out-string) -LogOnly
    write-ezlogs "`n#### Running nbtstat -r and -rr ####" -LogOnly
    write-ezlogs " | Running nbtstat -r and -rr...." -LogOnly -showtime
    write-ezlogs  (nbtstat -R | Out-string) -LogOnly
    write-ezlogs  (nbtstat -RR | Out-string) -LogOnly
    write-ezlogs "`n#### Running IPconfig /flushdns and /registerdns ####" -LogOnly
    write-ezlogs " | Running IPconfig /flushdns and /registerdns...." -LogOnly -showtime
    write-ezlogs  (ipconfig /flushdns | Out-string) -LogOnly
    write-ezlogs  (ipconfig /registerdns | Out-string) -LogOnly    
    write-ezlogs ">>>> Testing connection for final time" -showtime -color Cyan
    $testinternet = Test-Connection -computer $address -count 1 -quiet
    if ($testinternet)
    {
      write-ezlogs " | Connection up!" -showtime -color green
      start-sleep -seconds 5
      $internetstatus = $true
      $testinternet = Test-Connection -computer $address -count 1
    }
    else
    {
      write-ezlogs "Connection still down...unable to repair" -Color red -showtime
      write-ezlogs "`n#### Collecting Troubleshooting Data to Log File ####" -Color yellow
      $internetstatus = $false
      $wlanreport = netsh wlan show wlanreport
      $wlaninterfaces = netsh wlan show interfaces
      $wlanprofiles = netsh wlan show profiles
      $networkadapters = Get-NetAdapter
      $adapterstats = Get-NetAdapterStatistics | Format-List
      $ipstats = netsh interface ipv4 show ipstats
      $netstats = netsh interface ipv4 show tcpconnections
      $rdp_eventlogs = Get-WinEvent -logname "Microsoft-Windows-TerminalServices-RDPClient/Operational" -ea silentlycontinue | where {$_.LevelDisplayName -eq "Warning" -and $_.timecreated -gt [datetime]::today}
      $eventlogs = Get-WinEvent -ListLog * -EA silentlycontinue | where-object { $_.recordcount -AND $_.lastwritetime -gt [datetime]::today} | foreach { get-winevent -LogName $_.logname -MaxEvents 1 } | Sort-Object TimeCreated -Descending | Format-Table TimeCreated, ID, ProviderName, Message -AutoSize -Wrap
      write-ezlogs "`n#### Collecting WLAN Reports ####" -LogOnly
      write-ezlogs  $($wlanreport | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting WLAN Interfaces ####" -LogOnly
      write-ezlogs  $($wlaninterfaces | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting WLAN Profiles ####" -LogOnly
      write-ezlogs  $($wlanprofiles | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting Network Adapters ####" -LogOnly
      write-ezlogs  $($networkadapters | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting IP Stats ####" -LogOnly
      write-ezlogs  $($ipstats | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting Net Stats ####" -LogOnly
      write-ezlogs  $($netstats | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting Adapter Stats ####" -LogOnly
      write-ezlogs  $($adapterstats | Out-string) -LogOnly
      write-ezlogs "`n#### Collecting Recent Event Logs ####" -LogOnly
      write-ezlogs  $($eventlogs | Out-string) -LogOnly
      write-ezlogs "`n#### RDP Event Logs ####" -LogOnly
      write-ezlogs  $($rdp_eventlogs | Out-string) -LogOnly
      write-ezlogs " | Diagnostic data collected to log file" -showtime
      $msgboxtext = "There appears to be an issue with this computers internet connection. Unfortunately this application was unable to repair the problem. Please ensure your computer is connected to the internet and try again. 

        Relevent diagnostic data has been gathered into a log file at: $($thisApp.Config.Log_file)

        As internet is not working, this information cannot automatically be sent to EZTechhelp Support. 

        Please contact EZTechhelp Support by emailing support@eztechhelp.com or via your normal means of contacting support. 

        Thank you
      - EZTechhelp Automated Support"
      $msgBoxInput =  [System.Windows.MessageBox]::Show("$msgboxtext",'ERROR: LRAH Remote Access','Ok','Error')
      switch  ($msgBoxInput) {
        'Ok' {
          write-ezlogs "`n#### Displaying Error Message to User ####" -LogOnly
          write-ezlogs "$msgboxtext" -LogOnly
          write-ezlogs "User ($env:USERNAME) acknowledged dialog window and exited" -showtime -LogOnly
          exit
        }
        'No' {
          write-ezlogs "`n#### Displaying Error Message to User ####" -LogOnly
          write-ezlogs "$msgboxtext" -LogOnly
          write-ezlogs "User ($env:USERNAME) clicked NO in dialog window and exited" -showtime -LogOnly
          exit
        }
        'Cancel' {
          write-ezlogs "`n#### Displaying Error Message to User ####" -LogOnly
          write-ezlogs "$msgboxtext" -LogOnly
          write-ezlogs "User ($env:USERNAME) clicked Cancel in dialog window and exited" -showtime -LogOnly
          exit
        }
      }
    }
  }else{
    write-ezlogs ">>>> Internet Connection Status: Connected" -showtime -LogLevel:$loglevel
    try{
      $testinternet = Test-Connection -computer $address -count 1
    }catch{
      write-ezlogs "An exception occurred executing Test-Connection for address $address" -catcherror $_
    }   
    $internetstatus = $true
    $AbstractAPI_Config_file = "$($thisApp.Config.Current_Folder)\Resources\API\Abstract-API-Config.xml"
    $known_VPN_IP_List = "https://github.com/X4BNet/lists_vpn/raw/main/ipv4.txt"
    if($External_IP_Check){     
      if([system.io.file]::Exists($AbstractAPI_Config_file)){
        try{
          $AbstractAPI_Config = Import-Clixml $AbstractAPI_Config_file
          $webclient = [System.Net.WebClient]::new()
          $publicIP_info = ($webclient).DownloadString("$($AbstractAPI_Config.url)?api_key=$($AbstractAPI_Config.Client_Secret)") | convertfrom-json
          $public_IP = $publicIP_info.IP_address
          $ISP_Name = $publicIP_info.connection.isp_name
          $ISP_Org_Name = $publicIP_info.connection.organization_name
        }catch{
          write-ezlogs "An exception occurred in web request to: $($AbstractAPI_Config.url)" -CatchError $_
        }finally{
          if($webclient -is [System.IDisposable]){
            $webclient.dispose()
          }
        }
      }
      if($publicIP_info.security.is_vpn){
        $Is_PublicVPN = $publicIP_info.security.is_vpn
      }else{
        if([system.io.file]::Exists("$($thisApp.Config.Temp_Folder)\KnownVPN_IPs.txt")){
          write-ezlogs ">>>> Reading Known_VPN_IP_List from $($thisApp.Config.Temp_Folder)\KnownVPN_IPs.txt" -LogLevel:$loglevel
          $VPN_IPs = [system.io.file]::ReadAllText("$($thisApp.Config.Temp_Folder)\KnownVPN_IPs.txt") -split "`n"
        }else{
          write-ezlogs ">>>> Downloading Known_VPN_IP_List from: $($known_VPN_IP_List)"
          try{
            $webclient = [System.Net.WebClient]::new()
            $download = ($webclient).DownloadString($known_VPN_IP_List).Trim() -split "`n" | out-file "$($thisApp.Config.Temp_Folder)\KnownVPN_IPs.txt" -Force
            $VPN_IPs = [system.io.file]::ReadAllText("$($thisApp.Config.Temp_Folder)\KnownVPN_IPs.txt") -split "`n"
          }catch{
            write-ezlogs "An exception occurred downloading: $known_VPN_IP_List" -CatchError $_
          }finally{
            if($webclient -is [System.IDisposable]){
              $webclient.dispose()
            }
          }
        }
        $octets = $public_IP.Split(".")
        $ipoctets = $octets[0],$octets[1] -join '.'
        $VPN_IPs = $VPN_IPs | where {$_ -like "$ipoctets*"}
        foreach ($ip in $VPN_IPs)
        {
          $subnetCheck = (CheckSubnet $public_IP $ip).condition
          if($subnetCheck)
          {
            write-ezlogs "This systems public IP matches a known VPN subnet $ip" -showtime -Warning -LogLevel:$loglevel
            $IP_isVPN = $true
            break
          }
        }
        $Is_PublicVPN = $IP_isVPN    
      }
      $Public_IP_Region = $publicIP_info.region
      $Public_IP_City = $publicIP_info.city
    }
  }
  write-ezlogs " | External IP: $($public_IP)" -showtime -LogLevel:$loglevel
  write-ezlogs " | Is External IP VPN?: $($Is_PublicVPN)" -showtime -LogLevel:$loglevel
  write-ezlogs " | ISP Name: $($ISP_Name)" -showtime -LogLevel:$loglevel
  write-ezlogs " | ISP Organization Name: $($ISP_Org_Name)" -showtime -LogLevel:$loglevel
  write-ezlogs " | ISP Region: $($Public_IP_Region)" -showtime -LogLevel:$loglevel
  write-ezlogs " | ISP City: $($Public_IP_City)" -showtime -LogLevel:$loglevel
  $internetstatusoutput = [PSCustomObject]@{
    'InternetStatus' = $internetstatus
    'InternetTestResults' = $testinternet
    'Public_IP' = $public_IP
    'ISP_Name' = $ISP_Name
    'ISP_Org_Name' = $ISP_Org_Name
    'Is_PublicVPN' = $Is_PublicVPN
    'Public_IP_Region' = $Public_IP_Region
    'Public_IP_City' = $Public_IP_City
  }
  if($returnbool){
    return $internetstatus
  }else{
    return $internetstatusoutput
  } 
  
}
#---------------------------------------------- 
#endregion Test-Internet function
#----------------------------------------------

#--------------------------------------------- 
#region Get-InstalledVPN Function
#---------------------------------------------
function Get-InstalledVPN
{
  <#
      .Notes
      Attempts to check for and return installed VPN software and config
  #>
  param(
    [switch]
    $All,
    $thisApp,
    [string]$VPNName = 'ProtonVPN',
    [string]$Country = 'US',
    [string]$City,
    [int]$loglevel = $thisApp.Config.Log_Level
  )
  try{   
    write-ezlogs ">>>> Executing Get-InstalledVPN: $VPNName" -LogLevel:$loglevel
    if($VPNName -eq 'ProtonVPN'){
      $Installedexe = find-filesfast -path "$env:ProgramW6432\Proton" -Filter "ProtonVPN.exe" | Select-Object -last 1
      if(!$Installedexe){
        $Installedexe = find-filesfast -path "${env:ProgramFiles(x86)}\Proton" -Filter "ProtonVPN.exe" | Select-Object -last 1
      }
      if(!$Installedexe){
        $Installedexe = find-filesfast -path "${env:ProgramFiles(x86)}\Proton Technologies" -Filter "ProtonVPN.exe" | Select-Object -last 1
      }
      if(!$Installedexe){
        $Installedexe = find-filesfast -path "$env:ProgramW6432\Proton Technologies" -Filter "ProtonVPN.exe" | Select-Object -last 1
      }
    }
    if(Test-ValidPath $Installedexe.FullName -Type File){
      $installpath = $Installedexe.FullName
    }else{
      $installpath = $null
    }
    if(!$installpath){
      write-ezlogs ">>>> ProtonVPN does not appear to be installed at: $installpath" -LogLevel:$loglevel
      return $false
    }else{
      write-ezlogs ">>>> ProtonVPN appears to be installed at: $installpath" -LogLevel:$loglevel
      return $installpath
    }
    #Get ProtonVPN servers
    <#    write-ezlogs " | Getting ProtonVPN Logical servers for Country: $Country - City: $City" -LogLevel:$loglevel
        $serversjson = "$env:localappdata\ProtonVPN\Servers.json"
        if([system.io.file]::Exists($serversjson)){
        $json = [system.io.file]::ReadAllText($serversjson) | Convertfrom-json
        }else{
        $json = Invoke-RestMethod 'https://api.protonmail.ch/vpn/logicals' -UseBasicParsing
        }
        if($City){
        $ip = $json | Where-Object {$_.entrycountry -eq $Country -and $_.City -match $City -and $_.Status -eq 1} 
        }else{
        $ip = $json | Where-Object {$_.entrycountry -eq $Country -and $_.Status -eq 1} 
    }#>
  }catch{
    write-ezlogs "An exception occurred in Get-InstalledVPN" -catcherror $_
  }
}
#--------------------------------------------- 
#endregion Get-InstalledVPN Function
#---------------------------------------------

#--------------------------------------------- 
#region Install-ProtonVPN Function
#---------------------------------------------
function Install-ProtonVPN
{
  <#
      .Notes
      Installs Windows ProtonVPN client and (possibly) retrieves and configures VPN server based on closest proximity 
  #>
  param(
    [switch]
    $All,
    $thisApp,
    [string]$Country = 'US',
    [string]$City = 'New York',
    [int]$loglevel = $thisApp.Config.Log_Level
  )
  try{   
    write-ezlogs ">>>> Executing Install-ProtonVPN" -LogLevel:$loglevel
    $installpath = Get-InstalledVPN -All $thisApp -VPNName 'ProtonVPN'
    if($installpath){
      write-ezlogs ">>>> ProtonVPN appears to already be installed at $installpath" -LogLevel:$loglevel
      return $installpath
    }else{
      #$protonvpn_Link = "https://protonvpn.com/download/ProtonVPN_win_v2.0.1.exe"
      $url = 'https://github.com/ProtonVPN/win-app/releases/latest'
      $request = [System.Net.WebRequest]::Create($url)
      $response = $request.GetResponse()
      $realTagUrl = $response.ResponseUri.OriginalString
      $version = $realTagUrl.split('/')[-1].Trim('v')
      $fileName = "ProtonVPN_v$version.exe"
      $realDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/' + $fileName
      #$protonvpn_exe = [system.io.path]::GetFileName($protonvpn_Link)
      $protonvpn_download_location = "$($thisApp.Config.Temp_Folder)\$fileName"
      write-ezlogs ">>>> Downloading $realDownloadUrl to $protonvpn_download_location" -showtime -LogLevel:$loglevel
      $null =  (New-Object System.Net.WebClient).DownloadFile($realDownloadUrl,$protonvpn_download_location)   
      write-ezlogs " | Installing $fileName from $protonvpn_download_location with arguments '/quiet /norestart /L*v $($thisApp.Config.Temp_Folder)\ProtonVPN-Install.log'" -showtime -LogLevel:$loglevel
      $protonvpn_setup = Start-process $protonvpn_download_location -ArgumentList "/quiet /norestart /L*v $($thisApp.Config.Temp_Folder)\ProtonVPN-Install.log" -Wait
      if(!(Test-Validpath $installpath -Type File)){
        write-ezlogs ">>>> Verifying ProtonVPN is installed" -LogLevel:$loglevel
        $Installers = find-filesfast -path "$env:ProgramW6432\Proton" -Filter "ProtonVPN.exe" | select -last 1
        if(!$Installers){
          $Installers = find-filesfast -path "${env:ProgramFiles(x86)}\Proton" -Filter "ProtonVPN.exe" | select -last 1
        }
        if(!$Installers){
          $Installers = find-filesfast -path "${env:ProgramFiles(x86)}\Proton Technologies" -Filter "ProtonVPN.exe" | select -last 1
        }
        if(!$Installers){
          $Installers = find-filesfast -path "$env:ProgramW6432\Proton Technologies" -Filter "ProtonVPN.exe" | select -last 1
        }
        if(Test-ValidPath $Installers.FullName -Type File){
          $installpath = $Installers.FullName
          write-ezlogs ">>>> ProtonVPN appears to be installed at $installpath" -Success -LogLevel:$loglevel
        }else{
          write-ezlogs "Unable to find ProtonVPN.exe, install may have failed or some other issue occurred. Cannot continue" -Warning -LogLevel:$loglevel
          return
        }
      }
    }
    #Get ProtonVPN servers
    write-ezlogs " | Getting ProtonVPN Logical servers for Country: $Country - City: $City" -LogLevel:$loglevel
    $serversjson = "$env:localappdata\ProtonVPN\Servers.json"
    if([system.io.file]::Exists($serversjson)){
      $json = [system.io.file]::ReadAllText($serversjson) | Convertfrom-json
      $ip = $json | where {$_.entrycountry -eq $Country -and $_.City -match $City} 
    }else{
      $json = Invoke-RestMethod 'https://api.protonmail.ch/vpn/logicals'
      $ip = $json.LogicalServers | where {$_.entrycountry -eq $Country -and $_.City -match $City -and $_.Status -eq 1} 
    }
    write-ezlogs " | LogicalServers found: $($ip.servers.entryip | out-string)" -LogLevel:$loglevel
    $protonvpn_launch = Start-process $installpath -ArgumentList "/quiet /L*v $($thisApp.Config.Temp_Folder)\ProtonVPN-Install.log"
    $protonlaunch_timeout = 0
    while(!(Get-process protonvpn -ErrorAction SilentlyContinue) -and $protonlaunch_timeout -ge 60){
      $protonlaunch_timeout++
      start-sleep -Milliseconds 500
    }
    if($protonlaunch_timeout -ge 60){
      write-ezlogs "Timed out waiting for ProtonVPN to start" -Warning -LogLevel:$loglevel
      return
    }
  }catch{
    write-ezlogs "An exception occurred in Install-ProtonVPN" -catcherror $_
  }
}
#--------------------------------------------- 
#endregion Install-ProtonVPN Function
#---------------------------------------------

#---------------------------------------------- 
#region Get-VPNStatus function
#----------------------------------------------
Function Get-VPNStatus
{
  param (
    [string]$Testaddress = 'www.google.com',
    [switch]$autofix,
    [switch]$PublicVPNCheck,
    [int]$Count = 1,
    $thisApp,
    [int]$loglevel = $thisApp.Config.Log_Level
    
  )
  write-ezlogs "##### Checking VPN Connection Status #####" -linesbefore 1 -LogLevel:$loglevel
  $vpnCheck = Get-CimInstance -Query "Select * from Win32_NetworkAdapter where (Name like '%AnyConnect%' or Name like '%Juniper%' or Name like '%VPN%' or Name like '%TAP%' or Name like '%TUNNEL%' or Name like '%Proton%') and NetEnabled='True'"
  write-ezlogs "Checking VPN Netadapters:`n$($vpnCheck | out-string)" -showtime -LogLevel:$loglevel
  #Check if $vpnCheck is true or false.
  if ($vpnCheck) 
  {
    if($Testaddress){
      $serverovervpntest = Test-Connection -computer $Testaddress -count $Count -Quiet
      if ($serverovervpntest)
      {
        write-ezlogs ">>>> VPN Connection status: Connected and Working Properly" -Color green -showtime -LogLevel:$loglevel
        $vpntestresults = Test-Connection -computer $Testaddress -count $Count -ErrorAction SilentlyContinue
        $vpnstatus = $true
      }
      else
      {
        write-ezlogs ">>>> VPN Connection status: A VPN connection is active but unable to connect to Server '$Testaddress' over VPN" -showtime -warning -LogLevel:$loglevel
        $vpntestresults = Test-Connection -computer $Testaddress -count $Count -ErrorAction SilentlyContinue
        $vpnstatus = $false
      }
    }else{
      $VpnStatus = $true
    }
  }
  if($PublicVPNCheck){
    write-ezlogs ">>>> Checking if behind network level VPN" -LogLevel:$loglevel
    $internet = Test-internet -thisApp $thisApp -address www.google.com -External_IP_Check -LogLevel:$loglevel -Secondaryaddress '1.1.1.1'
    $Vpnstatus = $internet.Is_PublicVPN
  }
  elseif(!$vpnCheck) 
  {
    write-ezlogs ">>>> VPN Connection status: Disconnected" -showtime -warning -LogLevel:$loglevel
    $vpnstatus = $false
  }
  $isPublicVPN = $internet.Is_PublicVPN
  $vpnstatusoutput = [PSCustomObject]@{
    "VPNStatus" = $vpnstatus
    "PublicVPN" = $isPublicVPN
    "VPNTestResults" = $vpntestresults
    'VPNAdapters' = $vpnCheck
  }
  return $vpnstatusoutput
}
#---------------------------------------------- 
#endregion Get-VPNStatus function
#----------------------------------------------

#--------------------------------------------- 
#region Start-ProtonVPN Function
#---------------------------------------------
function Start-ProtonVPN
{
  <#
      .Notes
      Launches Windows ProtonVPN client. Potentially silently if an account is already logged on
  #>
  param(
    [switch]
    $All,
    $thisApp,
    [string]$Country = 'US',
    [string]$City = 'New York',
    [switch]$Install,
    [switch]$WaitforConnect,
    [string]$SetStartMinimized = '1',
    [string]$SetConnectOnStart = 'True',
    [switch]$save_settings,
    [int]$loglevel = $thisApp.Config.Log_Level
  )
  try{   
    write-ezlogs ">>>> Executing Start-ProtonVPN" -LogLevel:$loglevel
    if(Test-ValidPath "${env:ProgramFiles(x86)}\Proton Technologies\ProtonVPN" -Type Directory){
      $ProtonVPNInstalled_Dir = "${env:ProgramFiles(x86)}\Proton Technologies\ProtonVPN"
    }elseif(Test-ValidPath "$env:programfiles\Proton Technologies\ProtonVPN" -Type Directory){
      $ProtonVPNInstalled_Dir = "${env:ProgramFiles(x86)}\Proton Technologies\ProtonVPN"
    }elseif(Test-ValidPath "$env:programfiles\Proton\VPN" -Type Directory){
      $ProtonVPNInstalled_Dir = "$env:programfiles\Proton\VPN"
    }else{
      $ProtonVPNInstalled_Dir = $null
    }
    if($ProtonVPNInstalled_Dir){
      $installpath = [system.io.directory]::EnumerateFiles($ProtonVPNInstalled_Dir,'ProtonVPN.exe','AllDirectories') | select -last 1
    }else{
      $installpath = $null
    }
    if($installpath){
      write-ezlogs " | ProtonVPN appears to be installed at $installpath" -LogLevel:$loglevel
    }else{
      #$protonvpn_Link = "https://protonvpn.com/download/ProtonVPN_win_v2.0.1.exe"
      write-ezlogs "ProtonVPN cannot be launched as it is not installed" -warning -LogLevel:$loglevel
      if($Install){
        Install-ProtonVPN -thisApp $thisApp
      }else{
        return $false
      }
    }

    #CheckConfig?
    $path = [system.io.directory]::EnumerateFiles("$env:localappdata\ProtonVPN","*user.config*","AllDirectories") | select -last 1
    if([System.io.file]::Exists($path)){
      write-ezlogs ">>>> Getting content of user.config file at $path" -LogLevel:$loglevel
      [xml]$Content = [system.io.file]::ReadAllText($Path)
      if($content.ChildNodes[1].userSettings){
        $connectonstart = $content.ChildNodes[1].userSettings.'ProtonVPN.Properties.Settings'.setting | where {$_.name -eq 'ConnectOnAppStart'}
        if(!$connectonstart){
          $connectonstart = $content.ChildNodes[1].userSettings.'ProtonVPN.Properties.Settings'.setting | where {$_.name -eq 'StartOnBoot'}
        }
        if($connectonstart){
          write-ezlogs " | ConnectOnAppStart Name: $($connectonstart.name) -- value: $($connectonstart.value)" -LogLevel:$loglevel
          if(-not [string]::IsNullOrEmpty($SetConnectOnStart) -and $connectonstart.value -ne $SetConnectOnStart){
            write-ezlogs " | Enabling setting StartMinimized" -LogLevel:$loglevel
            $connectonstart.value = $SetConnectOnStart
            $save_settings = $true
          }
        }
        $startminimized = $content.ChildNodes[1].userSettings.'ProtonVPN.Properties.Settings'.setting | where {$_.name -eq 'StartMinimized'}
        if($startminimized){
          write-ezlogs " | StartMinimized value: $($startminimized.value)" -LogLevel:$loglevel
          if(-not [string]::IsNullOrEmpty($SetStartMinimized) -and $startminimized.value -ne $SetStartMinimized){
            write-ezlogs " | Enabling setting StartMinimized" -LogLevel:$loglevel
            $startminimized.value = $SetStartMinimized
            $save_settings = $true
          }
        }
        $userprofiles = $content.ChildNodes[1].userSettings.'ProtonVPN.Properties.Settings'.setting | where {$_.name -match 'UserProfiles'}
        if($userprofiles){
          $userprofiles_json = $($userprofiles.value) | convertfrom-json
          if($userprofiles_json.count -gt 1){
            write-ezlogs " | Multiple UserProfiles found: $($userprofiles_json | out-string)" -LogLevel:$loglevel
          }else{
            write-ezlogs " | UserProfiles User: $($userprofiles_json.user)" -LogLevel:$loglevel
            if($($userprofiles_json).value.External){
              write-ezlogs " | Connection profiles for user $($userprofiles_json.user) -- $($($userprofiles_json).value.External.name -join ',')" -LogLevel:$loglevel
            }
          }  
        }
        $UserQuickConnect = $content.ChildNodes[1].userSettings.'ProtonVPN.Properties.Settings'.setting | where {$_.name -match 'UserQuickConnect'}
        if($UserQuickConnect){
          $UserQuickConnect_json = $UserQuickConnect.value | convertfrom-json
          write-ezlogs " | UserQuickConnect -- User: $($UserQuickConnect_json.user) -- value: $($UserQuickConnect_json.value)" -LogLevel:$loglevel
        }
        if($save_settings){
          write-ezlogs ">>>> Saving ProtonVPN settings to config file: $($path)" -LogLevel:$loglevel
          $null = $content.Save($path)
        }
      }
    }

    $ProtonProcess = Get-CimInstance -Class Win32_Process -Filter "Name = 'ProtonVPN.exe'"
    if($ProtonProcess){
      write-ezlogs " | A ProtonVPN process was detected as already running - skipping process launch" -warning -LogLevel:$loglevel
    }else{
      #Get ProtonVPN servers
      write-ezlogs " | Getting ProtonVPN Logical servers for Country: $Country - City: $City" -LogLevel:$loglevel
      $serversjson = "$env:localappdata\ProtonVPN\Servers.json"
      if([system.io.file]::Exists($serversjson)){
        $json = [system.io.file]::ReadAllText($serversjson) | Convertfrom-json
        $ip = $json | where {$_.entrycountry -eq $Country -and $_.City -match $City} 
      }else{
        $json = Invoke-RestMethod 'https://api.protonmail.ch/vpn/logicals'
        $ip = $json.LogicalServers | where {$_.entrycountry -eq $Country -and $_.City -match $City -and $_.Status -eq 1} 
      }
      #write-ezlogs " | LogicalServers found: $($ip.servers.entryip | out-string)" -LogLevel:$loglevel
      $protonvpn_launch = Start-process $installpath -ArgumentList "/quiet /L*v $($thisApp.Config.Temp_Folder)\ProtonVPN-Launch.log"
      $protonlaunch_timeout = 0
      start-sleep 1
      while(!(Get-process protonvpn -ErrorAction SilentlyContinue) -and $protonlaunch_timeout -ge 60){
        $protonlaunch_timeout++
        write-ezlogs "....Waiting for protonvn to launch" -LogLevel:$loglevel
        start-sleep -Milliseconds 500
      }
      if($protonlaunch_timeout -ge 60){
        write-ezlogs "Timed out waiting for ProtonVPN to start" -Warning -LogLevel:$loglevel
        return $false
      }elseif(Get-process protonvpn*){
        write-ezlogs "ProtonVPN started successfully" -Success -LogLevel:$loglevel
      }
    }

    #Wait for connect
    if($WaitforConnect){
      $protonVPN_Wait = 0
      $VPNConnect_status=(Get-VPNStatus -thisApp $thisApp -loglevel 0).VPNStatus
      while( $(Get-process protonvpn*) -and !($VPNConnect_status) -and $protonVPN_Wait -lt 60){
        $VPNConnect_status=(Get-VPNStatus -thisApp $thisApp -loglevel 0).VPNStatus
        write-ezlogs "...Waiting for VPN connection: VPN_Status: $($VPNConnect_status)" -LogLevel:$loglevel
        start-sleep 1
      }
      if($protonVPN_Wait -ge 60){
        write-ezlogs "Timed out waiting for the VPN client to connect!" -AlertUI -Warning -LogLevel:$loglevel
        return $false
      }elseif($VPNConnect_status){
        write-ezlogs "ProtonVPN has successfully launched and connected" -Success -LogLevel:$loglevel
        return $true
      }
    }else{
      return $true
    }
  }catch{
    write-ezlogs "An exception occurred in Install-ProtonVPN" -catcherror $_
  }
}
#--------------------------------------------- 
#endregion Start-ProtonVPN Function
#---------------------------------------------
Export-ModuleMember -Function @('Test-Internet','Install-ProtonVPN','Get-VPNStatus','Start-ProtonVPN','Get-InstalledVPN')