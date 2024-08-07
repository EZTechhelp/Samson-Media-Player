function New-DSRichPresence {
  <#
      .SYNOPSIS
      Creates a Rich Presence object that will be sent and received by Discord

      .DESCRIPTION
      Creates a Rich Presence object that will be sent and received by Discord. Use this class to build your presence and update it appropriately.

      .PARAMETER Buttons
      The buttons to display in the presence

      .PARAMETER State
      The user's current Party status. For example, "Playing Solo" or "With Friends"

      .PARAMETER Details
      What the user is currently doing. For example, "Competitive - Total Mayhem"

      .PARAMETER Timestamps
      The time elapsed / remaining time data

      .PARAMETER Assets
      The names of the images to use and the tooltips to give those images

      .PARAMETER Party
      The party the player is currently in. The ID  must be set for this to be included in the RichPresence update.

      .PARAMETER Secrets
      The secrets used for Join / Spectate. Secrets are obfuscated data of your choosing. They could be match ids, player ids, lobby ids, etc. Make this object null if you do not wish too / unable too implement the Join / Request feature.

      .EXAMPLE
      $assets = New-DSAsset -LargeImageKey avatar -LargeImageText "Summoners Rift" -SmallImageKey icon -SmallImageText "Lvl 7"
      $timestamp = [DiscordRPC.Timestamps]::Now
      $button = New-DSButton -Label "Potato ðŸ¥"" -Url https://github.com/potatoqualitee/discordrpc
      $party = New-DSParty -Size 10 -Privacy Public -Max 100
      $params = @{
      Asset = $assets
      State = "Something good"
      Details = "Aww yeah"
      Timestamp = $timestamp
      Buttons = $button
      }
      New-DSRichPresence @params

  #>
  [CmdletBinding()]
  param (
    [DiscordRPC.Button[]]$Buttons,
    [String]$State,
    [String]$Details,
    [DiscordRPC.Timestamps]$Timestamps,
    [DiscordRPC.Assets]$Assets,
    [DiscordRPC.Party]$Party,
    [DiscordRPC.Secrets]$Secrets
  )
  process {
    $object = New-Object -TypeName DiscordRPC.RichPresence   
    if($Buttons){
      try{
        $object.Buttons = $Buttons
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Buttons - $($($Buttons | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      } 
    }
    if($State){ 
      try{
        $Chars = ($State | measure-object -Character).Characters
        if($Chars -ge 124){
          $State = "$([string]$State.subString(0, [System.Math]::Min(120, $State.Length)).trim())..." 
          write-ezlogs "[New-DSRichPresence] Provided state string is $($Chars) characters long (123 max allowed) - trimming to: $State" -warning -logtype Discord
        }
        $object.State = "$State"
      }catch{
        write-ezlogs "[New-DSRichPresence] An exception occurred setting Discord RichPresense State - characters: $Chars -- State: $($($State | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
        $isError = $true
      }finally{
        if($isError){
          $object.State = ''
        }
      }
    }
    if($Details){
      try{
        $DetailsChars = ($Details | measure-object -Character).Characters
        if($DetailsChars -ge 126){
          $Details = "$([string]$Details.subString(0, [System.Math]::Min(123, $Details.Length)).trim())..." 
          write-ezlogs "[New-DSRichPresence] Provided Details string is $($DetailsChars) characters long (128 max allowed) - trimming to: $Details" -warning -logtype Discord
        }
        $object.Details = $Details
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Details - $($($Details | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      }
    }
    if($Timestamps){
      try{
        $object.Timestamps = $Timestamps
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Timestamps - $($($Timestamps | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      }      
    }
    if($Assets){
      try{
        $object.Assets = $Assets
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Assets - $($($Assets | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      } 
    }
    if($Party){
      try{
        $object.Party = $Party
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Party - $($($Party | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      }    
    }
    if($Secrets){
      try{
        $object.Secrets = $Secrets
      }catch{
        write-ezlogs "An exception occurred setting Discord RichPresense Secrets - $($($Secrets | out-string)) - Params: $($PSBoundParameters | out-string)" -showtime -catcherror $_
      } 
    }
    <#      foreach ($key in ($PSBoundParameters.Keys | Where-Object { $PSItem -notin [System.Management.Automation.PSCmdlet]::CommonParameters })) {
        $object.$key = $PSBoundParameters[$key]         
    }#>

    $object
  }
}