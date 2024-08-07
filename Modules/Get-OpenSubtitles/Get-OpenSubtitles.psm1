<#
    .Name
    Get-OpenSubtitles

    .Version 
    0.1.0

    .SYNOPSIS
    Fetches subtitles for provided media files via Open Subtitles API.

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
#region Get-OpenSubtitles Function
#----------------------------------------------
function Get-OpenSubtitles {
  [CmdletBinding()]
  param (
    [string]$mediafile,
    [string]$Query,
    [switch]$Use_Runspace,
    $thisApp = $thisApp,
    $synchash = $synchash
  )
  #-replace "(\d{4}|\(|\)|^\s+|\s+$)",""
  $OpenSubtitles_ScriptBlock = {
    param (
      [string]$mediafile = $mediafile,
      [string]$Query = $Query,
      [switch]$Use_Runspace = $Use_Runspace,
      $thisApp = $thisApp,
      $synchash = $synchash
    )   
    #--------------------------------------------- 
    #region Await Function
    #---------------------------------------------  
    function Wait-Task { 
      process { 
        $task = $_ 
        while (-not $task.AsyncWaitHandle.WaitOne(200)) { } 
        return $task.GetAwaiter().GetResult() 
      } 
    }
    #--------------------------------------------- 
    #endregion Await Function
    #---------------------------------------------  
    Add-type -AssemblyName System.Net.Http 
    if([system.io.file]::exists($mediafile) -or -not [string]::IsNullOrEmpty($Query)){
      try{   
        $file = $null
        $httpclient = [System.Net.Http.HttpClient]::new() 
        $subtitleOptions = [MovieCollection.OpenSubtitles.OpenSubtitlesOptions]::new()
        #TODO: API CONFIG
        $subtitleOptions.ApiKey = 'waA0Krb752ySGGMuGaNSbhn0PGVEE3bO'
        $subtitleOptions.ProductInformation = [System.Net.Http.headers.productheadervalue]::new('EZT-MediaPlayer')
        $service = [MovieCollection.OpenSubtitles.OpenSubtitlesService]::new($httpclient,$subtitleOptions)
        $Subtitle_Search = [MovieCollection.OpenSubtitles.Models.NewSubtitleSearch]::new()
        if([system.io.file]::exists($mediafile)){
          $directory = [System.IO.Path]::GetDirectoryName($mediafile)
          $filename = "$([System.IO.Path]::GetFileNameWithoutExtension($mediafile)).srt"
          $downloadfile = [System.IO.Path]::Combine($directory,$filename)
          if([system.io.file]::exists($downloadfile)){
            write-ezlogs "A subtitle for already exists for this media at: $downloadfile" -warning
            Update-Subtitles -synchash $synchash -thisApp $thisApp -Add_Subtitles -Subtitles_Path $downloadfile
            return
          }
          write-ezlogs ">>>> Getting file hash for $mediafile"
          $Query = [System.IO.Path]::GetFileNameWithoutExtension($mediafile)
          $MovieHash = [MovieCollection.OpenSubtitles.OpenSubtitlesHasher]::GetFileHash($mediafile)
          $Subtitle_Search.MovieHash = $MovieHash
        }
        write-ezlogs ">>>> Executing SearchSubtitles with query: $Query"
        $Subtitle_Search.Query = $Query      
        try{
          $search = $service.SearchSubtitlesAsync($Subtitle_Search) | Wait-Task
        }catch{
          write-ezlogs "An exception occurred executing SearchSubtitlesAsync" -catcherror $_
        }        
        $results = $search.data | where {$_.Attributes.Language -eq 'en'}
        if(-not $search.TotalCount -gt 0 -or !$results){
          $query = $($Query -split "(\d{4}|\(|\)|^\s+|\s+$)")[0]
          $Subtitle_Search.Query = $Query
          $search = $service.SearchSubtitlesAsync($Subtitle_Search) | Wait-Task
        }
        $subtitle = $search.data | where {$_.attributes.files.filename -match $Query -and $_.Attributes.Language -eq 'en'}
        if($subtitle){
          $file = $subtitle.attributes.files | select -first 1
        }elseif($search.TotalCount -gt 0){
          $file = ($search.data.attributes | where {$_.Language -eq 'en'}).files | select -first 1
        }else{
          write-ezlogs "No results returned from Open Subtitles: $($search | out-string)" -warning
          Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
          return
        }
        if($file){
          write-ezlogs " | Found subtitle file: $($file.FileName)"
          if(!$thisApp.OS_LoginToken.token){
            $Login = [MovieCollection.OpenSubtitles.Models.NewLogin]::new()
            #TODO: API CRED CONFIG
            $Login.Username = 'ezt-mediaplayer'
            $Login.password = 'aKw:7l0j>4a3iBj1ePK37Xtcg6a'
            try{
              $thisApp.OS_LoginToken = $service.LoginAsync($Login) | Wait-Task
              $Userinfo = $service.GetUserInformationAsync($thisApp.OS_LoginToken.token) | Wait-Task
            }catch{
              write-ezlogs "An exception occurred executing LoginAsync" -catcherror $_
            } 
          }
          if($Userinfo.Data.RemainingDownloads -le 1){
            write-ezlogs "The account used for OpenSubtitles ($($Login.Username)) has only $($Userinfo.Data.RemainingDownloads) subtitle downloads remaining!" -warning -AlertUI
          }elseif($Userinfo.Data.RemainingDownloads -lt 1){
            write-ezlogs "The account used for OpenSubtitles ($($Login.Username)) has $($Userinfo.Data.RemainingDownloads) subtitle downloads remaining! This will be reset to $($Userinfo.Data.AllowedDownloads) in $($Userinfo.Data.ResetTime)" -warning -AlertUI
            if($httpclient -is [System.IDisposable]){
              write-ezlogs "[Get-OpenSubtitles] >>>> Diposing HTTPClient"
              $httpclient.Dispose()
            } 
            return
          }                 
          if($thisApp.OS_LoginToken.token){          
            $NewDownload = [MovieCollection.OpenSubtitles.Models.NewDownload]::new()
            $newdownload.FileId = $file.FileId
            $NewDownload.FileName = $file.FileName
            write-ezlogs "[Get-OpenSubtitles] | Getting new download with user $($Login.Username)"
            try{
              $download = $service.GetSubtitleForDownloadAsync($NewDownload,$thisApp.OS_LoginToken.token) | Wait-Task
            }catch{
              write-ezlogs "An exception occurred executing GetSubtitleForDownloadAsync" -catcherror $_
            }           
            if($MovieHash){
              $filename = "$([System.IO.Path]::GetFileNameWithoutExtension($mediafile)).srt"
            }else{
              $filename = [System.IO.Path]::GetFileName($download.Link)
              $directory = "$($thisApp.Config.Temp_Folder)"
            }        
            $downloadfile = [System.IO.Path]::Combine($directory,$filename)
            if($download.Link){
              write-ezlogs "[Get-OpenSubtitles] | Downloading subtitle file: $($download.Link)"
              (New-Object System.Net.WebClient).DownloadFile($download.Link,$downloadfile)
              if([system.io.file]::Exists($downloadfile)){
                write-ezlogs "[Get-OpenSubtitles] Successfully downloaded subtitle file: $downloadfile" -Success
                Update-Subtitles -synchash $synchash -thisApp $thisApp -Add_Subtitles -Subtitles_Path $downloadfile
                return
              }else{
                write-ezlogs "[Get-OpenSubtitles] Unable to verify successfully download of file: $downloadfile" -warning
              }
            }else{
              write-ezlogs "[Get-OpenSubtitles] Unable to find download link -- result: $($download | out-string)" -warning
            }
          }else{
            write-ezlogs "[Get-OpenSubtitles] Unable to retrieve login token for user $($Login.Username) - Result: $($thisApp.OS_LoginToken | out-string)" -warning
          }
        }else{
          write-ezlogs "[Get-OpenSubtitles] No subtitles were found for $Query" -warning
        }
        Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
      }catch{
        write-ezlogs "[Get-OpenSubtitles] An exception occurred in Get-OpenSubtitles with query: $Query" -showtime -catcherror $_
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'VideoView_Subtitles_Fetch' -Property 'IsEnabled' -value $true
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'PackIconFontAwesome_Subtitle_Spinner' -Property 'Spin' -value $false
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaSubtitles_TextBox' -Property 'Header' -value 'Error!'
      }finally{
        if($httpclient){
          write-ezlogs "[Get-OpenSubtitles] >>>> Diposing HTTPClient"
          $httpclient.Dispose()
        }
      }
    }else{
      write-ezlogs "No media path was provided for Get-OpenSubtitles - cannot continue!" -warning
    }
  }
  if($use_Runspace){
    #$keys = $PSBoundParameters.keys
    #$Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $OpenSubtitles_ScriptBlock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name 'Get_OpenSubtitles_RUNSPACE' -thisApp $thisApp -synchash $synchash -CheckforExisting
    #Remove-Variable Variable_list
  }else{
    Invoke-Command -ScriptBlock $OpenSubtitles_ScriptBlock
  } 
}
#---------------------------------------------- 
#endregion Get-OpenSubtitles Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-OpenSubtitles')