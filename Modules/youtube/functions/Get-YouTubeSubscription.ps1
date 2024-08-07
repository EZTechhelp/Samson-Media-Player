
#---------------------------------------------- 
#region Get-YouTubeSubscription Function
#----------------------------------------------
function Get-YouTubeSubscription {
  [CmdletBinding()]
  param (
    [switch] $Raw
  )

  $Uri = 'https://www.googleapis.com/youtube/v3/subscriptions?part=id,contentDetails,snippet,subscriberSnippet&mine=true&maxResults=50'
  $results_output = [System.Collections.Generic.List[Object]]::new()
  $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name)  
  if($access_Token.Authorization){
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){             
        #$Result = Invoke-RestMethod -Uri $Uri -Headers ($access_Token) 
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
          $result = $output | convertfrom-json -ErrorAction SilentlyContinue
          $headers.Clear()
        }catch{
          write-ezlogs "[Get-YouTubeSubscription] An exception occurred in HTTPWebRequest of uri: $uri" -catcherror $_
        }finally{
          if($response -is [System.IDisposable]){
            $response.Dispose()
          }
          if($strm -is [System.IDisposable]){
            $strm.Dispose()
          }
          if($sr -is [System.IDisposable]){
            $sr.Dispose()
          }
        }
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
    $PSCmdlet.WriteObject($results_output)   
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  } 
}
#---------------------------------------------- 
#endregion Get-YouTubeSubscription Function
#----------------------------------------------