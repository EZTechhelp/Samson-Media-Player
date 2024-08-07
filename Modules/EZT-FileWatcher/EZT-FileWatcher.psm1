<#
    .Name
    EZT-FileWatcher

    .Version 
    0.1.0

    .SYNOPSIS
    Creates events to monitor changes using FileSystemWatcher and trigger actions for provided file/folder paths 

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
    Adapted from: https://stackoverflow.com/questions/47273578/a-robust-solution-for-filesystemwatcher-firing-events-multiple-times

    .RequiredModules
    /Modules/Write-EZLogs/Write-EZLogs.psm1
    /Modules/Start-RunSpace/Start-Runspace.psm1
#>

#---------------------------------------------- 
#region Start-FileWatcher Function
#----------------------------------------------

function Start-FileWatcher{
  [CmdletBinding()]
  param (
    [string]$FolderPath,
    [switch]$MonitorSubFolders,
    [string]$SyncDestination,
    [string]$Filter = '*.*',
    [switch]$use_Runspace,
    [switch]$Start_ProfileManager,
    $thisApp,
    $synchash,
    $Runspace_Guid
  )
  
  $filewatcher_ScriptBlock = {  
    param (
      [string]$FolderPath = $FolderPath,
      [switch]$MonitorSubFolders = $MonitorSubFolders,
      [string]$SyncDestination = $SyncDestination,
      [string]$Filter = $Filter,
      [switch]$use_Runspace = $use_Runspace,
      $thisApp = $thisApp,
      $synchash = $synchash,
      $Runspace_Guid = $Runspace_Guid
    )
    if([system.io.directory]::Exists($FolderPath)){
      try{  
        #$waithandle = [System.WeakReference]::new($thisApp.Jobs[$($thisApp.Jobs.Name.IndexOf("filewatcher_Runspace_$Runspace_Guid"))],$false)
        $jobs = [System.WeakReference]::new($thisApp.Jobs.clone(),$false).Target
        $index = $($jobs.Name.IndexOf("filewatcher_Runspace_$Runspace_Guid"))
        if($index -ne -1){
          $waithandle = [System.WeakReference]::new($jobs[$index])
        }else{
          write-ezlogs "Unable to find runspace job for runspace: filewatcher_Runspace_$Runspace_Guid - cannot continue!" -warning
          return
        }
        $jobs = $Null
        write-ezlogs ">>>> Started new filewatcher for path $FolderPath"
        if(!$synchash){
          $synchash = [hashtable]::Synchronized(@{})
        }
        [void][System.Reflection.Assembly]::LoadWithPartialName('System.Runtime.Caching')
        #Caching Policies
        [int]$CacheTimeMilliseconds = 1000
        $ChangedCachingPolicy = [System.Runtime.Caching.CacheItemPolicy]::new()

        #MemoryCache
        $ChangedMemoryCache = [system.runtime.caching.MemoryCache]::Default

        #FileWatcher Changed Events
        $Changedfilewatcher = [System.IO.FileSystemWatcher]::new($FolderPath)
        $Changedfilewatcher.IncludeSubdirectories = $MonitorSubFolders
        $Changedfilewatcher.Filter = $Filter
        $Changedfilewatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
        $Changedfilewatcher.EnableRaisingEvents = $true

        #FileWatcher other Events
        $filewatcher = [System.IO.FileSystemWatcher]::new($FolderPath)
        $filewatcher.IncludeSubdirectories = $MonitorSubFolders
        $filewatcher.Filter = $Filter
        $filewatcher.NotifyFilter = [System.IO.NotifyFilters]::FileName,[System.IO.NotifyFilters]::DirectoryName
        $filewatcher.EnableRaisingEvents = $true

        #Caching Policy Callbacks
        $CachingPolicy_Scriptblock = { 
          try{
            $path = $args.CacheItem.Value.FullPath              
            if($args.RemovedReason -ne [system.runtime.caching.CacheEntryRemovedReason]::Expired){
              return
            } 
            $changetype = $args.CacheItem.Value.ChangeType
            $isFile = [system.io.path]::HasExtension($path) -or [System.IO.File]::Exists($path)
            if($isFile){
              write-ezlogs "File $($changetype): $($path)"          
            }else{
              #write-ezlogs "Directory $($changetype): $($path)"
            }
          }catch{          
            write-ezlogs "An exception occurred in CachingPolicy_Scriptblock" -showtime -catcherror $_ 
          }   
        }

        $ChangedEvent_Scriptblock = { 
          try{        
            $synchash = $Event.MessageData
            $ChangedCachingPolicy.AbsoluteExpiration = [datetime]::Now.AddMilliseconds($CacheTimeMilliseconds)
            $ChangedMemoryCache.AddOrGetExisting($event.SourceEventArgs.Name,$event.SourceEventArgs,$ChangedCachingPolicy)
          }catch{
            write-ezlogs "An exception occurred in ChangedEvent_Scriptblock" -showtime -catcherror $_ 
          }   
        }.GetNewClosure()

        $ChangedCachingPolicy.RemovedCallback = $CachingPolicy_Scriptblock
      
        #FileWatcher Events
        $FileWatcherAction_Scripblock = { 
          $synchash = $Event.MessageData
          $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
          $exclude_Pattern = '\.temp\.|\.tmp\.'
          try{                      
            $path = $event.SourceEventArgs.fullpath
            $changetype = $event.SourceEventArgs.ChangeType
            $isFile = [system.io.path]::HasExtension($path) -or [System.IO.File]::Exists($path)
            if($isFile -and $path -match $media_pattern){
              #delay first!
              #[void][System.Threading.WaitHandle]::WaitAny($waithandle.Runspace.AsyncWaitHandle,50)
              Start-sleep -Milliseconds 50
              write-ezlogs "#### File $($changetype): $($path)" -linesbefore 1
              $Media = Get-MediaProfile -synchash $synchash -thisApp $thisApp -Media_URL $path
              if($Media){ 
                write-ezlogs ">>>> Found media profile for $($media.title) -- $($media.url)"
                if($changetype -eq 'Changed' -and [System.IO.File]::Exists($path)){
                  $mediainfo = [System.IO.FileInfo]::new($path)
                  if(-not [string]::IsNullOrEmpty($mediainfo.Length) -and $mediainfo.Length -gt 0 -and $Media.Size -ne $mediainfo.Length){
                    write-ezlogs " | Media has changed size from '$($Media.Size)' to '$($mediainfo.Length)'"
                    $MediaChanged = $true
                  }
                }
                if($changetype -in 'Deleted','Renamed' -or $MediaChanged){
                  write-ezlogs " | Updating $($media.url) in local media profile"
                  [void]$synchash.ProfileManager_Queue.Enqueue([PSCustomObject]@{
                      'Media' = $media
                      'ActionType' = $changetype
                      'ProcessObject' = $true
                      'Type' = 'Local'
                  })
                }
              }elseif($changetype -eq 'Created' -and $path -match $media_pattern -and $path -notmatch $exclude_Pattern){                
                $mediainfo = [System.IO.FileInfo]::new($path)
                $directory = [system.io.path]::GetDirectoryName($Path)
                $PathSegments = [uri]::new($($path)).segments
                $PathRoot = [system.io.path]::GetPathRoot($path)
                if($synchash.ProfileManager_Queue.fullname -notcontains $mediainfo.FullName -and $mediainfo.Length -gt 0){
                  $SourceDirectory = $thisApp.Config.Media_Directories.where({$PathSegments -contains [uri]::new($($_)).AbsolutePath})
                  if(!$SourceDirectory -and $thisApp.Config.Media_Directories -contains $PathRoot){
                    $sourceDirectory = $PathRoot
                  }elseif(!$SourceDirectory){
                    $sourceDirectory = $directory
                  }
                  #Sleep first - file may be still copying
                  Start-sleep 1
                  write-ezlogs " | Add new media path $path to local media profile - length: $($mediainfo.Length)"
                  [void]$synchash.ProfileManager_Queue.Enqueue([PSCustomObject]@{
                      'FullName' = $mediainfo.FullName
                      'BaseName' = $mediainfo.BaseName
                      'FileName' = $mediainfo.Name
                      'Extension' = $mediainfo.Extension
                      'Length' = $mediainfo.Length
                      'directory' = $directory
                      'SourceDirectory' = $SourceDirectory
                      'PathRoot' = $PathRoot
                      'ActionType' = $changetype
                      'ProcessObject' = $true
                      'Type' = 'Local'
                  })
                }
              }
            }elseif(!$isFile){
              write-ezlogs "Directory $($changetype): $($path)"
              #Sync-Files 
            }
          }catch{
            write-ezlogs "An exception occurred in FileWatcherAction_Scripblock" -showtime -catcherror $_
          }   
        }
        if($thisApp.Config.LocalMedia_MonitorMode -in 'All','New Media'){
          $Null = Register-ObjectEvent -InputObject $filewatcher -EventName Created -MessageData $synchash -Action $FileWatcherAction_Scripblock 
        }
        if($thisApp.Config.LocalMedia_MonitorMode -in 'All','Removed Media'){
          $Null = Register-ObjectEvent -InputObject $filewatcher -EventName Deleted -MessageData $synchash -Action $FileWatcherAction_Scripblock
        }
        if($thisApp.Config.LocalMedia_MonitorMode -in 'All','Changed Media'){
          $Null = Register-ObjectEvent -InputObject $filewatcher -EventName Renamed -MessageData $synchash -Action $FileWatcherAction_Scripblock
          $Null = Register-ObjectEvent -InputObject $Changedfilewatcher -EventName Changed -MessageData $synchash -Action $ChangedEvent_Scriptblock
        }  
        if(!$thisApp.LocalMedia_Monitor_Enabled){
          $thisApp.LocalMedia_Monitor_Enabled = $true
        }      
      }catch{
        write-ezlogs "An exception occurred in MediaTransportControls_scriptblock" -showtime -catcherror $_
      } 
      try{
        while(($Changedfilewatcher.EnableRaisingEvents -or $filewatcher.EnableRaisingEvents) -and $thisApp.LocalMedia_Monitor_Enabled -and $waithandle.IsAlive){
          if($waithandle.target.runspace.AsyncWaitHandle){
            [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(50)
          }else{
            start-sleep -Milliseconds 50
          }
          #[void][System.Threading.WaitHandle]::WaitAny($waithandle.Runspace.AsyncWaitHandle,10)
        }
        write-ezlogs "FileWatcher has ended for path: $FolderPath -- LocalMedia_Monitor_Enabled: $($thisApp.LocalMedia_Monitor_Enabled) - Waithandle.IsAlive: $($waithandle.IsAlive) -- Changedfilewatcher.EnableRaisingEvents: $($Changedfilewatcher.EnableRaisingEvents) -- filewatcher.EnableRaisingEvents: $($filewatcher.EnableRaisingEvents)" -warning
        #Check for and remove existing registered events
        Get-EventSubscriber -force | & { process {
            if($_.EventName -in 'Changed','Created','Deleted','Renamed'){
              if($thisApp.Config.Dev_mode){write-ezlogs "[Stop-FileWatcher] Unregistering existing event: $($_.EventName)" -LogLevel 2 -Dev_mode}
              Unregister-Event -SourceIdentifier $_.SourceIdentifier -Force
            }
        }} 
      }catch{
        write-ezlogs "An exception occurred in FileWatcher" -catcherror $_
      }finally{
        if($Changedfilewatcher){
          $Changedfilewatcher.Dispose()
        }
        if($filewatcher){
          $filewatcher.Dispose()
        }
        if($ChangedCachingPolicy){
          $ChangedCachingPolicy.RemovedCallback = $Null
        }
        if($ChangedMemoryCache){
          $ChangedMemoryCache.Dispose()
        }
        if($error){
          write-ezlogs "Errors in runspace: filewatcher_Runspace_$Runspace_Guid" -showtime -PrintErrors -ErrorsToPrint $error
          $error.clear()
        }
      }
    }else{
      write-ezlogs "No valid folder path was provided for FileWatcher: $($FolderPath)" -warning
    }     
  }
  if($Start_ProfileManager -and !$thisApp.ProfileManagerEnabled){
    Get-ProfileManager -thisApp $thisApp -synchash $synchash -Startup
  }
  if($use_Runspace){ 
    Start-Runspace $filewatcher_ScriptBlock -StartRunspaceJobHandler -thisApp $thisApp -synchash $synchash -runspace_name "filewatcher_Runspace_$Runspace_Guid" -Variable_list $PSBoundParameters -RestrictedRunspace -function_list 'write-ezlogs','Get-MediaProfile'
  }else{
    Invoke-Command -ScriptBlock $filewatcher_ScriptBlock
  }
}
#---------------------------------------------- 
#endregion Start-FileWatcher Function
#----------------------------------------------

#---------------------------------------------- 
#region Stop-FileWatcher Function
#----------------------------------------------
function Stop-FileWatcher{
  param (
    [string]$FolderPath,
    [switch]$MonitorSubFolders,
    [string]$SyncDestination,
    [string]$Filter = '*.*',
    [switch]$use_Runspace,
    [switch]$force,
    [switch]$Stop_ProfileManager,
    $thisApp = $thisApp,
    $synchash = $synchash
  )

  $Stop_filewatcher_ScriptBlock = {  
    param (
      [string]$FolderPath = $FolderPath,
      [switch]$MonitorSubFolders = $MonitorSubFolders,
      [string]$SyncDestination = $SyncDestination,
      [string]$Filter = $Filter,
      [switch]$use_Runspace = $use_Runspace,
      [switch]$Stop_ProfileManager = $Stop_ProfileManager,
      [switch]$force = $force,
      $thisApp = $thisApp,      
      $synchash = $synchash
    )
    try{  
      if(!$thisApp.Config.Enable_LocalMedia_Monitor -or $force){
        $thisApp.LocalMedia_Monitor_Enabled = $false
      }
      if($thisApp.ProfileManagerEnabled -and $Stop_ProfileManager){
        write-ezlogs ">>>> Stopping ProfileManager" -callpath "Stop-FileWatcher"
        Get-ProfileManager -thisApp $thisApp -synchash $synchash -shutdown -shutdownWait
      } 
    }catch{
      write-ezlogs "An exception occurred in Stop_filewatcher_ScriptBlock" -showtime -catcherror $_  -callpath "Stop-FileWatcher"
    }  
  }
  if($use_Runspace){ 
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    #$Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant" -and ($_.Name -in $PSBoundParameters.keys -or $_.Name -in 'thisApp','synchash')}
    Start-Runspace $Stop_filewatcher_ScriptBlock -StartRunspaceJobHandler -thisApp $thisApp -synchash $synchash -runspace_name "Stop_filewatcher_Runspace" -Variable_list $Variable_list
  }else{
    Invoke-Command -ScriptBlock $Stop_filewatcher_ScriptBlock
  }
}
#---------------------------------------------- 
#endregion Stop-FileWatcher Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-FileWatcher','Stop-FileWatcher')