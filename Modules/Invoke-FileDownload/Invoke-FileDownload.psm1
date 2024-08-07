<#
    .Name
    Invoke-FileDownload

    .Version 
    0.1.1

    .SYNOPSIS
    Downloads files from various cloud services or via direct URL into specified directory

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
    #API: https://displaycatalog.mp.microsoft.com/v7.0/products?bigIds=9NBR2VXT87SJ&languages=en&market=cn
#>

#---------------------------------------------- 
#region Invoke-FileDownload Function
#----------------------------------------------
function Invoke-FileDownload
{
  Param(
    [uri]$DownloadURL,
    [string]$Download_file_name,
    [string]$Destination_File_Path,
    [string]$Download_Directory,
    [switch]$Overwrite
  )
  Try{
    write-ezlogs ">> Initializing Download from: $DownloadURL" -showtime -color Cyan
    if($DownloadURL -match "sharepoint.com"){
      write-ezlogs " | Download URL is a Onedrive share link" -showtime
      if($DownloadURL -notmatch "&download=1"){
        $DownloadURL = "$DownloadURL&download=1"
      }
    }
    elseif($DownloadURL -match "drive.google.com"){
      write-ezlogs " | URL is Google Drive" -ShowTime
      $Pattern = [Regex]::new('[-\w]{25,}')
      $matches = $Pattern.Matches($DownloadURL)
      $GoogleFileId = $matches.Value
      write-ezlogs " | Google File ID: $GoogleFileId" -ShowTime
      $download_file_name = Get-GDriveDownloadName -GoogleFileId $GoogleFileId
      write-ezlogs " | Google File Name: $download_file_name" -ShowTime
      $DownloadURL = "https://drive.google.com/uc?export=download&id=$GoogleFileId"
    }
    else{
      $download_file_name = Split-Path $downloadurl -Leaf #name of the file that is downloaded
    }
    if($Destination_File_Path){
      $Download_Directory = Split-Path $Destination_File_Path -Parent
      $download_file_name = Split-Path $Destination_File_Path -Leaf
    }
    $download_output_file = [System.IO.Path]::Combine($Download_Directory, $download_file_name)
    $Test_Download_Directory = Test-Path $Download_Directory -PathType Container
    $test_download_output_file = Test-Path $download_output_file -PathType Leaf
    if($test_download_output_file){
      if($Overwrite){
        write-ezlogs " | Overwriting existing download file: $download_output_file" -showtime
      }
      else{
        write-ezlogs " | File to download already exists : $download_output_file | Overwite option disabled, Skipping download" -showtime -Warning
        return $download_output_file
      }
    }
    elseif (!$Test_Download_Directory) {
      write-ezlogs " | Creating destination directory: $Download_Directory" -ShowTime
      $null = New-Item $Download_Directory -ItemType Directory -Force
    }
    else{
      write-ezlogs " | Destination directory is valid: $Download_Directory" -ShowTime 
    }
    $start_time = Get-Date
    $null = Invoke-WebRequest -Uri $DownloadURL -OutFile $download_output_file -UseBasicParsing
    write-ezlogs " | Download Time taken for file $DownloadURL : $((Get-Date).Subtract($start_time).Seconds) second(s)" -ShowTime 
    $test_download_output_file = Test-Path $download_output_file
    if($test_download_output_file){
      write-ezlogs " | File successfully downloaded to $download_output_file" -ShowTime -color Green
      return $download_output_file
    }
    else{
      write-ezlogs " | Unable to validate downloaded file: $download_output_file" -ShowTime -Warning
      return $false
    } 
  }
  catch{
    write-ezlogs "[ERROR] An exception occured downloading from $DownloadURL :`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -Color Red -showtime
  }
}
#---------------------------------------------- 
#endregion Invoke-FileDownload Function
#----------------------------------------------
Export-ModuleMember -Function @('Invoke-FileDownload')



