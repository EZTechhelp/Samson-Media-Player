function Get-YouTubeChannel {
  <#
      .SYNOPSIS
      Retrieves details for a YouTube channel.

      .PARAMETER ChannelId
      The array of channels that you want to get detailed information for.
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'ChannelId')]
    [string[]] $Id,
    [Parameter(ParameterSetName = 'Mine')]
    [switch] $mine,
    [switch] $Raw
  )
  $Uri = 'https://www.googleapis.com/youtube/v3/channels?part=brandingSettings,contentDetails,contentOwnerDetails,id,snippet,localizations,statistics,status,topicDetails'

  switch ($PSCmdlet.ParameterSetName) {
    'ChannelId' {
      $Uri += '&id={0}' -f ($Id -join ',')
    }    
    'Mine' {
      $Uri += "&mine=true"
    }
  }
  #Write-Verbose -Message $Uri
  $access_Token = (Get-AccessToken)  
  if($access_Token.Authorization){
    try{
      $req=[System.Net.HTTPWebRequest]::Create($uri)
      $req.Method='GET'
      $headers = [System.Net.WebHeaderCollection]::new()
      $headers.add('Authorization',$access_Token.Authorization)
      $req.Headers = $headers              
      $response = $req.GetResponse()
      $strm=$response.GetResponseStream();
      $sr=New-Object System.IO.Streamreader($strm);
      $output=$sr.ReadToEnd()
      $result = $output | convertfrom-json  
      $headers.Clear()
      $response.Dispose()
      $strm.Dispose()
      $sr.Dispose()
    }catch{
       write-ezlogs "[Get-YouTubeChannel] An exception occurred in HTTPWebRequest of uri: $uri" -catcherror $_
    }
    if ($Raw) { return $Result }
    $Result.items
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}