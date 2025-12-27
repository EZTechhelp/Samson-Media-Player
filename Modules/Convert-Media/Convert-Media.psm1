<#
    .Name
    Convert-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Allows converting local media file formats and codecs to another

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
#region Convert-Media Function
#----------------------------------------------
function Convert-Media
{
  [CmdletBinding()]
  param (
    [switch]$Startup,
    [switch]$use_Runspace,
    $synchash,
    $thisApp,
    [string]$InputFile,
    [string]$OutputDirectory,
    [string]$OutputFileName,
    [string]$Codec,
    [switch]$VerboseLog,
    [switch]$Test,
    [switch]$Force
  )
  try{
    if($use_Runspace){
      try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Convert_Media_RUNSPACE' -check
        if($existing_Runspace -and !$Force){
          write-ezlogs "Convert-Media runspace already exists: $($existing_Runspace), halting another execution to avoid a race condition" -warning -Verboselog:$VerboseLog -LogLevel 0
          return
        }
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace 'Convert_Media_RUNSPACE'" -showtime -catcherror $_
      }
    }
    if($synchash.Convert_Media_Progress_Ring){
      Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Convert_Media_Progress_Ring' -Property 'IsActive' -value $true
    }

    $Convert_Media_ScriptBlock = {
      param (
        [switch]$Startup,
        [switch]$use_Runspace,
        $synchash,
        $thisApp,
        [string]$InputFile,
        [string]$OutputDirectory,
        [string]$OutputFileName,
        [string]$Codec,
        [switch]$VerboseLog,
        [switch]$Test,
        [switch]$Force
      )
      try{
        if($VerboseLog -or $thisApp.Config.Dev_mode){
          $Convert_Media_Measure = [system.diagnostics.stopwatch]::StartNew()
        }
        $logtempfile = "$env:appdata\$($thisApp.Config.App_Name)\ConvertMedia.log"
        if(![system.io.file]::Exists($inputfile)){
          write-ezlogs "Providing file for media conversion cannout be found at: $inputfile. Aborting!" -Warning -AlertUI
          return
        }
        $OutputFile = [system.io.Path]::Combine($OutputDirectory,$OutputFileName)
        if([system.io.file]::Exists($OutputFile) -and !$Force){
          write-ezlogs "Output file for media converstion already exists at: $OutputFile. Aborting!" -Warning -AlertUI
          return
        }
        if([system.io.file]::Exists($logtempfile)){
          Remove-Item -Path $logtempfile -Force
        }
        if($Codec){
          $CodecArgs = " -c $Codec"
        }else{
          $CodecArgs = ""
        }
        $SongInfo = Get-SongInfo -Path $inputfile
        if($SongInfo.Duration){
          $Duration = $SongInfo.Duration
        }
        $FFArguments = "-i `"$InputFile`" `"$OutputFile`""
        try{
          $command = "& `"$($thisApp.Config.Current_Folder)\Resources\flac\ffmpeg.exe`" -i `"$InputFile`" `"$OutputFile`"$CodecArgs*>$logtempfile"
          $block = {
            Param($command)
            $console_output_array = invoke-expression $command -ErrorAction Ignore -Verbose:$VerboseLog
          }   
          #Remove all jobs and set max threads
          Get-Job | Remove-Job -Force
          $MaxThreads = 3
  
          #Start the jobs. Max 4 jobs running simultaneously.
          While ($(Get-Job -state running).count -ge $MaxThreads)
          {Start-Sleep -Milliseconds 3}
          Write-EZLogs -text ">>>> Executing ffmpeg with command: $command" -showtime -color cyan
          $Null = Start-Job -Scriptblock $Block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
          Write-EZLogs '-----------ffmpeg Log Entries-----------'
          #Wait for all jobs to finish.
          $ffmpeg_start_timer = 0
          While(!(get-process ffmpeg -ErrorAction SilentlyContinue) -and $ffmpeg_start_timer -lt 120){
            $ffmpeg_start_timer++
            start-sleep -Milliseconds 500
            write-ezlogs "Waiting for ffmpeg to begin: $ffmpeg_start_timer" -showtime
          }  
          $count = 0
          $synchash.MediaConvert_status = $true
          $outputLines = [Collections.ArrayList]::new()
          if($ffmpeg_start_timer -ge 120 -and !(get-process ffmpeg -ErrorAction SilentlyContinue)){
            write-ezlogs "Timed out waiting for ffmpeg to begin: $ffmpeg_start_timer" -showtime -warning -AlertUI
          }else{
            While ($(Get-Job -State Running).count -gt 0 -and (get-process 'ffmpeg' -ErrorAction SilentlyContinue))
            {
              #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
              if($synchash.MediaConvert_Cancel){
                $synchash.MediaConvert_Cancel = $false
                write-ezlogs "Breaking out of ffmpeg log monitoring due to cancel status" -warning
                break
              }elseif(!([System.IO.File]::Exists($logtempfile))){
                Start-Sleep -Milliseconds 500
              }else{        
                #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait         
                Get-Content -Path $logtempfile -force -Tail 1 | ForEach-Object {
                  $count++
                  $Output = $Null
                  if($synchash.MediaConvert_Cancel){
                    $synchash.MediaConvert_Cancel = $false
                    write-ezlogs "Breaking out of ffmpeg log monitoring due to cancel status" -warning
                    break
                  }
                  if(($outputLines | Select-Object -Last 1) -ne "$_"){
                    $null = $outputLines.Add($_)
                    $timepattern = 'time=(?<value>.*) bitrate'
                    $Durationpattern = 'Duration: (?<value>.*)\, start'
                    $sizepattern ='size=   (?<value>.*) time='
                    $speedpattern ='speed=(?<value>.*)'
                    $replaceBrackets = '^\[[^\]]+\]\s{0,}'
                    $progress = $Null
                    $time = $Null
                    if(!$Duration -and $_ -match $Durationpattern){
                      $Duration = ([regex]::matches($_, $Durationpattern)| %{$_.groups[1].value} )
                      $Output = "Duration: $Duration "
                      if($Duration -as [timespan]){
                        $Duration = $Duration -as [timespan]
                      }
                    }
                    if($_ -match $timepattern){
                      $time = ([regex]::matches($_, $timepattern)| %{$_.groups[1].value} )
                      $Output = "$($Output)| Time: $Time"
                      if($time -as [timespan]){
                        $time = $time -as [timespan]
                      }
                    }
                    if($_ -match $speedpattern){
                      $speed = ([regex]::matches($_, $speedpattern)| %{$_.groups[1].value} )
                      $Output = "$Output | Speed: $Speed"
                    }
                    if($_ -match $sizepattern){
                      $size = ([regex]::matches($_, $sizepattern)| %{$_.groups[1].value} )
                      $Output = "$Output | Size: $Size"
                    }                                                                 
                    if($time -as [timespan] -and $Duration -as [timespan]){
                      try{
                        $progress = [math]::Round(($time.TotalMilliseconds * 100 / $Duration.TotalMilliseconds),2)
                        $Output = "$Output | Progres: $progress"
                      }catch{
                        write-ezlogs "An exception occurred Processing progress math" -showtime -catcherror $_
                      }
                    }
                    if($Output){
                      Write-EZLogs "$Output" -showtime -NoTypeHeader -CallBack:$false 
                    }
                    <#                    if($_ -match $errorpattern){    
                        $errormsg = $([regex]::matches($_, $errorpattern) | %{$_.groups[1].value})                   
                        write-ezlogs "ffmpeg reports error: $errormsg" -showtime -warning
                        $message = "$_"
                        $level = 'ERROR'
                    }#>
                  } 
                  if($(Get-Job -State Running).count -eq 0 -or !(Get-Process 'ffmpeg*' -ErrorAction SilentlyContinue)){
                    write-ezlogs "Ended due to job or process ending"          
                    break
                  }
                }
              }
              Start-Sleep -Milliseconds 500    
            }
          }
          #Get information from each job.
          foreach($job in Get-Job)
          {$info=Receive-Job -Id ($job.Id)}
  
          #Remove all jobs created.
          Get-Job | Remove-Job -Force
          $synchash.MediaConvert_status = $false  
          Write-EZLogs '---------------END Log Entries---------------' -enablelogs
          return
        }catch{
          write-ezlogs "An exception occurred executing ffmepg with arguments: $($FFArguments)" -catcherror $_
        }finally{
          if([system.io.file]::Exists($OutputFile)){
            write-ezlogs "Convert-Media completed for: $OutputFile" -AlertUI
          }else{
            write-ezlogs "Convert-Media completed but unable to verify conversion to: $OutputFile" -warning
          }        
        }
      }catch{
        write-ezlogs "An exception occurred in Convert_Media_ScriptBlock" -CatchError $_
      }finally{
        if($synchash.Convert_Media_Progress_Ring){
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Convert_Media_Progress_Ring' -Property 'IsActive' -value $false
        }
        if($Convert_Media_Measure){
          $Convert_Media_Measure.stop()
          write-ezlogs "Convert-Media Measure" -Perf -PerfTimer $Convert_Media_Measure
        }
      }
    }
    
    if($use_Runspace){
      if($test){
        $RunspaceName = "Convert_Media_test_runspace"
      }else{
        $RunspaceName = "Convert_Media_RUNSPACE"
      }
      #$Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}} 
      Start-Runspace -scriptblock $Convert_Media_ScriptBlock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name $RunspaceName -thisApp $thisApp -synchash $synchash -ApartmentState STA #-RestrictedRunspace -function_list write-ezlogs,Update-MainWindow,Import-SerializedXML,Export-SerializedXML,Lock-Object,Register-ObjectEvent,Remove-Item,Receive-Job,Get-Job,Get-Process,Get-Content,invoke-expression,Remove-Job,Start-Job,Start-Sleep
    }else{
      Invoke-Command -ScriptBlock $Convert_Media_ScriptBlock -ArgumentList $Startup,$use_Runspace,$synchash,$thisApp,$InputFile,$OutputDirectory,$OutputFileName,$Codec,$VerboseLog,$Test,$Force
    } 
  }catch{
    write-ezlogs "An exception occurred in Convert-Media" -catcherror $_
  }
}
#----------------------------------------------
#endregion Convert-Media Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-Lyrics Function
#TODO: TESTING ONLY
#----------------------------------------------
Function Get-Lyrics {
  [CmdletBinding()]
  param (
    [switch]$use_Runspace,
    $synchash,
    $thisApp,
    [string]$Artist,
    [string]$title,
    [switch]$VerboseLog
  )
  try{
    $url = "https://www.azlyrics.com/lyrics/$($Artist)/$($title).html"
    $htmlContent =  Invoke-RestMethod -Uri $url
    $lyricsPattern = '<div>.*?<!-- Usage of azlyrics.com content.*?-->(.*?)</div>'
    $lyricsMatches = [regex]::Matches($htmlContent, $lyricsPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $lyricsMatches[0].Groups[1].Value -replace '<.*?>', '' -replace '\n', "`n"
  }catch{
    write-ezlogs "An exception occurred in Get-Lyrics" -catcherror $_
  }
}
#----------------------------------------------
#endregion Get-Lyrics Function
#----------------------------------------------
Export-ModuleMember -Function @('Convert-Media')
