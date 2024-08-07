<#
    .Name
    Get-SponsorBlock

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves sponsor segments for submitted videos via Sponsorblock API

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
#region Get-SponsorBlock Function
#----------------------------------------------
function Get-SponsorBlock {
  [CmdletBinding()]
  param (
    [string]$videoId,
    [string[]]$categories,
    [string[]]$requiredSegments,
    [ValidateSet('skip','full','poi','mute')]
    [string]$actionType = 'skip',
    [string]$service = 'Youtube'
  )
  if($videoId){    
    $Uri = "https://sponsor.ajay.app/api/skipSegments?videoID=$videoId&actionType=$actionType&service=$service"
    if($categories){
      $cats = $([System.Web.HTTPUtility]::UrlEncode("[`"$($categories -join '","')`"]"))
      $Uri += "&categories=$($cats)"
    }
    if($requiredSegments){     
      $reqs = $([System.Web.HTTPUtility]::UrlEncode("[`"$($categories -join '","')`"]"))
      $Uri += "&requiredSegments=$($reqs)"
    } 
    write-ezlogs "[Get-SponsorBlock] >>>> Getting Sponsorblock data for Youtube videoid: $($videoId)" 
    try{       
      $req=[System.Net.HTTPWebRequest]::Create($uri)
      $req.Timeout = 5000
      $req.Method='GET'            
      $response = $req.GetResponse()
      $strm=$response.GetResponseStream()
      $sr=[System.IO.Streamreader]::new($strm)
      $output=$sr.ReadToEnd()
      $result = $output | convertfrom-json     
    }catch{
      if($_.Exception -match '\(404\) Not Found'){
        write-ezlogs "[Get-SponsorBlock] No results returned for video id: $videoid" -showtime -warning
        $Null = $error.clear()
      }else{
        write-ezlogs "[Get-SponsorBlock] An exception occurred invoking sponserblock url: $Uri" -showtime -catcherror $_
      }   
    }finally{
      if($response){
        $response.Dispose()
      }
      if($strm){
        $strm.Dispose()
      }
      if($sr){
        $sr.Dispose() 
      }
    }
    if($Result){
      $result  | & { process {
          Add-Member -InputObject $_ -Name 'videoId' -Value $videoId -MemberType NoteProperty -Force
      }}
    }             
    return $Result 
  }else{
    write-ezlogs "[Get-SponsorBlock] A Youtube video ID must be provided! Cannot continue" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Get-SponsorBlock Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-SponsorBlock')