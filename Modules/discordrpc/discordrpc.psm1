$script:ModuleRoot = $PSScriptRoot
$dll = "$PSScriptRoot\bin\Newtonsoft.Json.dll"
if($PSVersionTable.PSVersion.Major -le 5){
  try {        
    $assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($Dll)
    if($assemblyName.Flags -eq 'PublicKey'){
      [void][System.Reflection.Assembly]::Load($assemblyName)
    }else{
      [void][System.Reflection.Assembly]::LoadFrom($Dll)
    }
  } catch {
    write-warning "Fallback to Loading assembly ($assemblyName) from path: $Dll"
    [void][System.Reflection.Assembly]::LoadFrom($Dll)
  }
}else{
  [void][System.Reflection.Assembly]::LoadFrom($Dll)
}

if(-not [bool]('DiscordRPC.DiscordRpcClient' -as [Type])){
  $dll = "$PSScriptRoot\bin\DiscordRPC.dll"
  if($PSVersionTable.PSVersion.Major -le 5){
    try {        
      $assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($Dll)
      if($assemblyName.Flags -eq 'PublicKey'){
        [void][System.Reflection.Assembly]::Load($assemblyName)
      }else{
        [void][System.Reflection.Assembly]::LoadFrom($Dll)
      }
    } catch {
      write-warning "Fallback to Loading assembly ($assemblyName) from path: $Dll"
      [void][System.Reflection.Assembly]::LoadFrom($Dll)
    }
  }else{
    [void][System.Reflection.Assembly]::LoadFrom($Dll)
  }
}
function Import-ModuleFile {
  [CmdletBinding()]
  Param (
    [string]$Path
  )

  if ($doDotSource) { . $Path }
  else {
    $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null)
  }
}

# Detect whether at some level dotsourcing was enforced
if ($discord_dotsourcemodule) { $script:doDotSource }

# Import all public functions
#TODO: Improve load module speed by 2x by using EnumerateFiles
foreach ($function in ([System.IO.Directory]::EnumerateFiles("$ModuleRoot\public","*.ps1","AllDirectories"))) {
  . $function
}

# global variables needed for timer scriptblocks
if ($global:discordrpcclient) {
  $script:rpcclient = $global:discordrpcclient
}