<#
    .Name
    Get-YouTubePlaylists

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves list of Youtube playlists. Adapted from Module Youtube  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Get-YouTubePlaylists Function
#----------------------------------------------
function Get-YouTubePlaylists {
  <#
      .SYNOPSIS
      Retrieves list of Youtube playlists.

      .EXAMPLE
      Get-YouTubePlaylists

      .EXAMPLE
      Get-YouTubePlaylists
  #>
  [CmdletBinding()]
  param (
    [switch] $mine,
    [switch] $Liked,
    [string] $id
  )
  $results_output = [System.Collections.Generic.List[Object]]::new()
  if($mine){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
  }elseif($id){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id={1}' -f $Parts,(("$ID").trim())
  }
  $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  if($refresh_access_token){
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  }
  if($access_token_expires -le (Get-date) -or !$access_token){
    write-ezlogs "[Get-YouTubePlaylists] Token has expired, attempting to refresh - access_token_expires: $($access_token_expires)" -showtime -warning -logtype Youtube
    try{
      Grant-YoutubeOauth -thisApp $thisApp
      $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "[Get-YouTubePlaylists] An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
    }
  }
  if($access_Token){    
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){       
        $req=[System.Net.HTTPWebRequest]::Create($uri)
        $req.Method='GET'
        $headers = [System.Net.WebHeaderCollection]::new()
        $headers.add('Authorization',"Bearer $access_token")
        $req.Headers = $headers              
        $response = $req.GetResponse()
        $strm=$response.GetResponseStream()
        $sr=[System.IO.Streamreader]::new($strm)
        $output=$sr.ReadToEnd()
        $result = $output | convertfrom-json  
        $headers.Clear()
        $response.Dispose()
        $strm.Dispose()
        $sr.Dispose()
        if($result.nextPageToken){
          if($mine){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true&pageToken={1}' -f $Parts,$result.nextPageToken
          }elseif($id){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id={1}&pageToken={2}' -f $Parts,(("$ID").trim()),$result.nextPageToken
          }          
        }else{
          if($mine){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
          }elseif($id){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id={1}' -f $Parts,(("$ID").trim())
          }
        }
        if($result.items){
          foreach($item in $result.items){
            if($results_output -notcontains $item){           
              $null = $results_output.add($item)
            }
          } 
          #$result # this return items that will be aggregated with items of other loops
        }
      }
    }catch{
      write-ezlogs "[Get-YouTubePlaylists] An exception occurred invoking url $Uri" -showtime -catcherror $_
    }
    if($Liked){
      Get-YouTubePlaylists -id "LL" | & { process {
          if($results_output -notcontains $_){           
            $null = $results_output.add($_)
          }
      }}
    }
    if(!$Result){
      write-ezlogs "[Get-YouTubePlaylists] No Youtube playlists were found!" -showtime -warning -logtype Youtube
    }             
    return $results_output 
  }else{
    write-ezlogs "[Get-YouTubePlaylists] Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Get-YouTubePlaylists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-YouTubePlaylists')