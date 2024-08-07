<#
    .Name
    Get-YouTubeCommentThread

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves top-level comments from a video, or comments related to a channel. 
     
    .EXAMPLE
    Get-YouTubeCommentThread -Id '8dZbdl3wzW8'

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player
    - Modules Write-EZLogs, youtube

    .OUTPUTS
    System.Collections.Generic.List[object]

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
#>

#---------------------------------------------- 
#region Get-YouTubeCommentThread Function
#----------------------------------------------
function Get-YouTubeCommentThread {
  <#
      .SYNOPSIS
      Retrieves top-level comments from a video, or comments related to a channel.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, ParameterSetName = 'VideoId')]
    [string[]] $Id,
    [Parameter(Mandatory = $true, ParameterSetName = 'ChannelRelated')]
    [string] $RelatedToChannelId,
    [switch] $Raw
  )
  $Parts = 'id,replies,snippet'
  $type = 'videoId'
  $Uri = 'https://www.googleapis.com/youtube/v3/commentThreads?part={0}&maxResults=100' -f $Parts
  $Uri += '&{0}={1}' -f $type, ($Id -join ',').trim()
  try{
    $access_token = Get-AccessToken -thisApp $thisapp -NoHeader -ForceTokenRefresh
  }catch{
    Write-EZLogs -text 'An exception occurred executing Get-AccessToken' -showtime -CatchError $_
  }
  try{
    if($access_token){
      $results_output = [System.Collections.Generic.List[object]]::new()
      $Authorization = 'Bearer {0}' -f $access_token
      if(@($Id).count -gt 1){
        $group = 100
        $i = 0
        do {
          $name = $null
          $ids = $null
          foreach($name in $Id[$i..(($i += $group) - 1)] | Where-Object -FilterScript {$_}){
            try{
              $name = $name.replace(' ',[string]::Empty)
              if([string]::IsNullOrEmpty($ids) -and $ids -notlike "*$name*"){
                $ids += "$name"
              }elseif($ids -notlike "*$name*"){
                $ids += ",$name"
              }                
            }catch{
              Write-EZLogs -text "An exception building url while processing entry $name" -showtime -CatchError $_
            }     
          }
          $Uri += $ids
          try{
            $req = [System.Net.HTTPWebRequest]::Create($Uri)
            $req.Method = 'GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('Authorization',$Authorization)
            $req.Headers = $headers
            $response = $req.GetResponse()
            $strm = $response.GetResponseStream()
            $sr = [System.IO.Streamreader]::new($strm)
            $result = $sr.ReadToEnd() | ConvertFrom-Json
          }catch{
            Write-EZLogs -text "An exception occurred in Get-YoutubeCommentThread with HTTPWebRequest to $($Uri) - access_token: $($access_token | Out-String)" -showtime -CatchError $_
            #break
          }finally{
            if($headers){
              $null = $headers.Clear()
            }
            if($response){
              $null = $response.Dispose()
            }
            if($strm){
              $null = $strm.Dispose()
            }
            if($sr){
              $null = $sr.Dispose()
            }
          }
          if($result.items){
            foreach($item in $result.items){
              $null = $results_output.add($item)
            }
          }
        }
        until ($i -ge $Id.count -1)
      }else{
        $result = @{
          nextPageToken = 1
        }
        While ($result.nextPageToken){ 
          try{
            $req = [System.Net.HTTPWebRequest]::Create($Uri)
            $req.Method = 'GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('Authorization',$Authorization)
            $req.Headers = $headers
            $response = $req.GetResponse()
            $strm = $response.GetResponseStream()
            $sr = [System.IO.Streamreader]::new($strm)
            $result = $sr.ReadToEnd() | ConvertFrom-Json
            #$result = Invoke-RestMethod -Method Get -Uri $Uri -Headers $access_token
          }catch{  
            if($_.Exception -match 'The remote server returned an error: \(404\) Not Found'){
              Write-EZLogs -text "Youtube API server returned '(404) Not Found' - for playlist id: $Id" -Warning -logtype Youtube
              return 'Not Found'
            }else{
              Write-EZLogs -text "An exception occurred in Get-YoutubeCommentThread with HTTPWebRequest to $($Uri)" -showtime -CatchError $_
            } 
            $error.clear()        
            break
          }finally{
            if($response -is [System.IDisposable]){
              $null = $response.Dispose()
            }
            if($strm -is [System.IDisposable]){
              $null = $strm.Dispose()
            }
            if($sr -is [System.IDisposable]){
              $null = $sr.Dispose()
            }        
          }             
          if($result.nextPageToken){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/commentThreads?part={0}&maxResults=100&{1}={2}&pageToken={3}' -f $Parts, $type, (($Id).trim()), $result.nextPageToken
          }else{
            $Uri = 'https://youtube.googleapis.com/youtube/v3/commentThreads?part={0}&maxResults=100&{1}={2}' -f $Parts, $type, (($Id).trim())
          }
          $result.items | & { process { 
              if($_.id -notin $results_output.id){
                $null = $results_output.add($_)
              }
          }}
          <#          if($result.items){
              foreach($item in $result.items){
              $null = $results_output.add($item)
              }
          }#>
        }
      }
      $PSCmdlet.WriteObject($results_output)
      #return $results_output
    }
  }catch{
    Write-EZLogs -text 'An exception occurred in Get-YouTubeCommentThread' -CatchError $_
  }finally{
    if($response -is [System.IDisposable]){
      $null = $response.Dispose()
    }
    if($strm -is [System.IDisposable]){
      $null = $strm.Dispose()
    }
    if($sr -is [System.IDisposable]){
      $null = $sr.Dispose()
    }
  }
}
#----------------------------------------------
#endregion Get-YouTubeCommentThread Function
#----------------------------------------------