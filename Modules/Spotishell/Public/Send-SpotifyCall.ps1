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
    [string]$Method,

    [Parameter(Mandatory)]
    [string]$Uri,

    $Body,

    [string]$ApplicationName,

    [switch]$First_Run,
    [switch]$retry = $true,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging        
  )

  # Prepare header
  try{
    $Header = @{
      Authorization = 'Bearer ' + (Get-SpotifyAccessToken -ApplicationName $ApplicationName)
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
        $req=[System.Net.HTTPWebRequest]::Create($Uri);
        $req.Method=$Method
        $req.ContentLength = '0'
        $headers = [System.Net.WebHeaderCollection]::new()
        $headers.add('Authorization',($header.values))
        $req.Headers = $headers              
        $GetResponse = $req.GetResponse()
        $strm=$GetResponse.GetResponseStream();
        $sr=New-Object System.IO.Streamreader($strm);
        $Response=$sr.ReadToEnd()
        #$Response = $output | convertfrom-json   
        $headers.Clear()
        $GetResponse.dispose()
        $strm.Dispose()
        $sr.Dispose()
        #$Response = Invoke-WebRequest -Method $Method -Headers $Header -Uri $Uri -UseBasicParsing
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
        #$Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing  
        if($Body -and $Body.GetType() -notmatch 'Switch'){
          $Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing
        }else{
          $req=[System.Net.HTTPWebRequest]::Create($Uri);
          $req.Method=$Method
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',($header.values))
          $req.Headers = $headers              
          $GetResponse = $req.GetResponse()
          $strm=$GetResponse.GetResponseStream();
          $sr=New-Object System.IO.Streamreader($strm);
          $Response=$sr.ReadToEnd()
          $headers.Clear()
          $GetResponse.dispose()
          $strm.Dispose()
          $sr.Dispose()
        }
      }elseif($_.Exception.Response.StatusCode -eq 502){
        Write-ezlogs "Bad Gateway 502 received, retrying again in case of transient issue..." -showtime -warning
        start-sleep -Milliseconds 500
        try{
          if($Body -and $Body.GetType() -notmatch 'Switch'){
            $Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing
          }else{
            $req=[System.Net.HTTPWebRequest]::Create($Uri);
            $req.Method=$Method
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('Authorization',($header.values))
            $req.Headers = $headers              
            $GetResponse = $req.GetResponse()
            $strm=$GetResponse.GetResponseStream();
            $sr=New-Object System.IO.Streamreader($strm);
            $Response=$sr.ReadToEnd()
            $headers.Clear()
            $GetResponse.dispose()
            $strm.Dispose()
            $sr.Dispose()
          }
        }catch{
          write-ezlogs "[Send-SpotifyCall] An exception occurred executing Send-SpotifyCall for uri: $Uri" -showtime -catcherror $_
        }
      }elseif($_.Exception.Response.StatusCode -eq 404){
        Write-ezlogs "Not Found 404 received, retrying again in case of transient issue...for uri $($Uri)" -showtime -warning
        start-sleep 1
        # then make request again (no try catch this time)
        if($Body -and $Body.GetType() -notmatch 'Switch'){
          $Response = Invoke-WebRequest -Method $Method -Headers $Header -Body $Body -Uri $Uri -UseBasicParsing
        }else{
          $req=[System.Net.HTTPWebRequest]::Create($Uri);
          $req.Method=$Method
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',($header.values))
          $req.Headers = $headers              
          $GetResponse = $req.GetResponse()
          $strm=$GetResponse.GetResponseStream();
          $sr=New-Object System.IO.Streamreader($strm);
          $Response=$sr.ReadToEnd()
          $headers.Clear()
          $GetResponse.dispose()
          $strm.Dispose()
          $sr.Dispose()
        }
      }elseif($_.Exception.Response.StatusCode -eq 403){
        Write-ezlogs "Error 403 received, Spotify Player command failed: Spotify Premium required" -showtime -warning -AlertUI
        if($synchash.Stop_media_Timer){
          $synchash.Stop_media_Timer.start()
        }       
        return
      }
      else {
        # Exception is not Rate Limit so throw it
        write-ezlogs "An exception occurred in Send-Spotifycall for Invoke-webrequest to $Uri - header $($header.values | out-string) - Body: $($Body | out-string)" -showtime -catcherror $_
      }
    }
  }
  $ProgressPreference = 'Continue'
  if($Response.Content){
    if($verboselog){Write-ezlogs 'We got an API JSON response' -showtime}
    return $Response.Content | ConvertFrom-Json
  }elseif($Response){
    if($verboselog){Write-ezlogs "We got an API JSON response - URI $($Uri) - body $($body | out-string) - header $($Header | out-string)" -showtime}
    return $Response | ConvertFrom-Json
  }else{
    Write-ezlogs "We did not get a valid API response - URI $($Uri) - body $($body | out-string)" -showtime -warning -logtype Spotify
    if($retry){
      write-ezlogs "Attempting to retry Send-SpotifyCall for url $uri" -showtime -warning -logtype Spotify
      Send-SpotifyCall -Method $Method -Uri $Uri -Body $Body -ApplicationName $ApplicationName -First_Run:$First_Run -retry:$false
    }else{
      return $false
    }
  }
}