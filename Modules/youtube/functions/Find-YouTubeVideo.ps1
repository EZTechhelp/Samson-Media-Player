function Find-YouTubeVideo {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string] $Query,
    [string] $PageToken,
    [switch] $Raw
  )
  $Uri = 'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=50&q={0}' -f $Query
  if ($PageToken) {
    $Uri += '&pageToken={0}' -f $PageToken
  }
  $access_Token = (Get-AccessToken)  
  if($access_Token.Authorization){
    $Result = Invoke-RestMethod -Uri $Uri -Headers ($access_Token) 
    if ($PSBoundParameters.ContainsKey('Raw')) { return $Result }
    $Result.Items
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}