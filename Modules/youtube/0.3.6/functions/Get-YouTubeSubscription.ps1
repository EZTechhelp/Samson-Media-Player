function Get-YouTubeSubscription {
  [CmdletBinding()]
  param (
    [string] $NextPageToken,
    [switch] $Raw
  )

  $Uri = 'https://www.googleapis.com/youtube/v3/subscriptions?part=id,contentDetails,snippet,subscriberSnippet&mine=true&maxResults=50'
  if ($PSBoundParameters.ContainsKey('NextPageToken')) {
    $Uri += '&pageToken={0}' -f $NextPageToken
    Write-Verbose -Message 'Added next page token'
  }
  $access_Token = (Get-AccessToken)  
  if($access_Token.Authorization){
    $Result = Invoke-RestMethod -Uri $Uri -Headers ($access_Token) 
    $Result.items | ForEach-Object -Process { $PSItem.PSTypeNames.Add('YouTube.Subscription') } 
    if ($PSBoundParameters.ContainsKey('Raw')) { return $Result }
    $Result.items
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  } 
}