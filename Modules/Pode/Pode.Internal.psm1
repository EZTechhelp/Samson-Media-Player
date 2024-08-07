# root path
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path

# import everything
$sysfuncs = Get-ChildItem Function:

# load private functions
foreach ($function in ([System.IO.Directory]::EnumerateFiles("$($root)/Private/","*.ps1","AllDirectories"))) {
    . $function
}
#Get-ChildItem "$($root)/Private/*.ps1" | ForEach-Object { . ([System.IO.Path]::GetFullPath($_)) }

# load public functions
foreach ($function in ([System.IO.Directory]::EnumerateFiles("$($root)/Public/","*.ps1","AllDirectories"))) {
    . $function
}
#Get-ChildItem "$($root)/Public/*.ps1" | ForEach-Object { . ([System.IO.Path]::GetFullPath($_)) }

# get functions from memory and compare to existing to find new functions added
$funcs = Get-ChildItem Function: | Where-Object { $sysfuncs -notcontains $_ }

# export the module's public functions
Export-ModuleMember -Function ($funcs.Name)