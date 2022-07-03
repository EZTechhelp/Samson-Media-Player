<#
    .SYNOPSIS
    Sends a call off to Spotify API
    .DESCRIPTION
    Send a pre-packaged spotify call off to the API.
    .EXAMPLE
    PS C:\> Send-SpotifyCall -Method 'Get' -Uri 'https://api.spotify.com/v1/me'
    Uses the default Authorization header and passes Get and the Uri to invoke-webrequest and returns it
    .PARAMETER Method
    Specifies the HTTP request method (usually Get, Put, Post, Delete)        
    .PARAMETER Uri
    Specifies the URI of the internet ressource. Example: https://api.spotify.com/v1/albums/
    .PARAMETER Body
    Specifies the Body of the request to send
    .PARAMETER ApplicationName
    Specifies the Spotify Application Name (otherwise default is used)
#>
function Send-SpotifyCall {

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]
    $Method,

    [Parameter(Mandatory)]
    [string]
    $Uri,

    $Body,

    [string]
    $ApplicationName,
    $thisScript,

    [switch]$First_Run,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging        
  )

  # Prepare header
  try{
    if($thisApp){
      $Header = @{
        Authorization = 'Bearer ' + (Get-SpotifyAccessToken -ApplicationName $ApplicationName -thisScript $thisScript)
      }
    }else{
      $Header = @{
        Authorization = 'Bearer ' + (Get-SpotifyAccessToken -ApplicationName $ApplicationName)
      }
    }
  }catch{
    write-ezlogs "[Send-SpotifyCall] An exception occurred executing Get-SpotifyAccessToken to retreive bearer token for API header" -showtime -catcherror $_
  }
  if($Verboselog){Write-ezlogs ">>>> Attempting to send request to API $Uri" -showtime -color cyan}

  $ProgressPreference = 'SilentlyContinue'
  if($header){
    try {
      if($Body -and $Body.GetType() -notmatch 'Switch'){
        $Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing
      }else{
        $Response = Invoke-WebRequest -Method $Method -Headers $Header -Uri $Uri -UseBasicParsing
      }  
    }
    catch {
      # if we hit the rate limit of Spotify API, code is 429
      if ($_.Exception.Response.StatusCode -eq 429) {
        $WaitTime = ([int]$_.Exception.Response.Headers['retry-after']) + 1
        Write-ezlogs "API Rate Limit reached, Spotify asked to wait $WaitTime seconds" -showtime -warning

        # wait number of seconds indicated by Spotify
        Start-Sleep -Seconds $WaitTime 

        # then make request again (no try catch this time)
        $Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing  
      }
      else {
        # Exception is not Rate Limit so throw it
        #Throw $PSItem
        write-ezlogs "An exception occurred in Send-Spotifycall for Invoke-webrequest to $Uri - header $($header.values | out-string)" -showtime -catcherror $_
      }
    }
  }
  <#  if($hashsetup.Window){
      $hashsetup.Window.Showdialog()
  } #> 
  $ProgressPreference = 'Continue'
  if($Response.Content){
    if($verboselog){Write-ezlogs 'We got an API JSON response' -showtime}
    return $Response.Content | ConvertFrom-Json
  }elseif($Response){
    if($verboselog){Write-ezlogs "We got an API JSON response - URI $($Uri) - body $($body | out-string) - header $($Header | out-string)" -showtime}
    return $Response | ConvertFrom-Json
  }else{
    Write-ezlogs "We did not get a valid API response - URI $($Uri) - body $($body | out-string) - header $($Header | out-string)" -showtime -warning
    return $false
  }
}