<#
    .Name
    Find-FilesFast

    .Version 
    0.3.0

    .SYNOPSIS
    Uses FindFilesFast.dll to access Win32 API for fast file and folder enumeration 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - FindFilesFast.dll
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Find-FilesFast Function
#----------------------------------------------
function Find-FilesFast{
  param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({-not [string]::IsNullOrEmpty($_)})]
    [string]$Path,
    [string]$Filter,
    [switch]$Recurse = $true,
    [switch]$FollowReparsePoints
  )
  Begin{
    if(-not [bool]('FindFilesFast.Finder' -as [Type]) -and [system.IO.File]::Exists("$($thisApp.Config.Current_Folder)\Assembly\FindFilesFast\FindFilesFast.dll")){ 
      [void][System.Reflection.Assembly]::LoadFrom("$($thisApp.Config.Current_Folder)\Assembly\FindFilesFast\FindFilesFast.dll")
    }
  }
  Process { 
    try{
      if([system.io.directory]::Exists($Path)){
        $files = [FindFilesFast.Finder]::FindFiles($Path,$Recurse,$FollowReparsePoints,$filter)
      }elseif([system.io.file]::Exists($Path)){
        $fso = New-Object -ComObject Scripting.FileSystemObject
        $files = $fso.getfile($Path)          
        #$a = New-Object -ComObject Scripting.FileSystemObject
        #$files = $a.GetFile($Path)
        #$files = [system.io.fileinfo]::new($Path)
      }   
    }catch{
      write-ezlogs "An exception occurred in Find-FilesFast" -showtime -catcherror $_
    }
    return $files
  }
  End { 
    if($fso){
      $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($fso)
    }
  }
}
#---------------------------------------------- 
#endregion Find-FilesFast Function
#----------------------------------------------
Export-ModuleMember -Function @('Find-FilesFast')