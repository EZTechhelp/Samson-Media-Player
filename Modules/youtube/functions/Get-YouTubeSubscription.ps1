function Get-YouTubeSubscription {
  [CmdletBinding()]
  param (
    [switch] $Raw
  )

  $Uri = 'https://www.googleapis.com/youtube/v3/subscriptions?part=id,contentDetails,snippet,subscriberSnippet&mine=true&maxResults=50'
  $results_output = New-Object -TypeName 'System.Collections.ArrayList'
  $access_Token = (Get-AccessToken)  
  if($access_Token.Authorization){
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){       
        $Result = Invoke-RestMethod -Uri $Uri -Headers ($access_Token) 
        if($result.nextPageToken){
          $Uri = 'https://www.googleapis.com/youtube/v3/subscriptions?part=id,contentDetails,snippet,subscriberSnippet&mine=true&maxResults=50' + '&pageToken={0}' -f $result.nextPageToken
        }else{
          $Uri = 'https://www.googleapis.com/youtube/v3/subscriptions?part=id,contentDetails,snippet,subscriberSnippet&mine=true&maxResults=50'
        }
        if($result.items){
          foreach($item in $result.items){
            if($results_output -notcontains $item){       
              $null = $results_output.add($item)
            }
          } 
        }        
      }
    }catch{
      write-ezlogs "An exception occurred invoking url $Uri" -showtime -catcherror $_
    }    
    $Result.items | ForEach-Object -Process { $PSItem.PSTypeNames.Add('YouTube.Subscription') } 
    if ($PSBoundParameters.ContainsKey('Raw')) { return $results_output }
    $results_output
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  } 
}