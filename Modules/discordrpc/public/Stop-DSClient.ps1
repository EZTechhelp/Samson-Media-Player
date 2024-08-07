function Stop-DSClient {
  <#
      .SYNOPSIS
      Stops the client and removes the rich presence

      .DESCRIPTION
      Stops the client and removes the rich presence

      .EXAMPLE
      Stop-DSClient

      Stops the client
  #>
  [CmdletBinding()]
  param ()
  process {
    if(-not $script:rpcclient) {
      write-ezlogs "[Stop-DSClient] No discord rpcclient running" -showtime -warning -logtype Discord
    }else{
      try{
        write-ezlogs "[Stop-DSClient] Disposing Discord RPC Client" -showtime -warning -logtype Discord
        [void]$script:rpcclient.ClearPresence()
        [void]$script:rpcclient.Deinitialize()
        [void]$script:rpcclient.Dispose()
        Remove-Variable -Scope Global -Name discordrpcclient -ErrorAction Ignore
        Remove-Variable -Scope Script -Name rpcclient -ErrorAction Ignore
        $global:discordrpcclient = $script:rpcclient = $null
      }catch{
        write-ezlogs "An exception occurred disposing Discord RPC Client" -catcherror $_
      }
    }
    if(Get-EventSubscriber -SourceIdentifier Discord -ErrorAction Ignore){
      write-ezlogs "[Stop-DSClient] Removing Discord Event Subscriber" -showtime -warning -logtype Discord
      $null = Get-EventSubscriber -SourceIdentifier Discord -ErrorAction Ignore | Unregister-Event
    }
  }
}