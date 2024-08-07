<#try {
  if(!$(Get-Command Start-PodeServer*)){
     Import-Module -Name Pode -ErrorAction Stop
  }
}
catch {
  throw 'The YouTube module for PowerShell requires the Pode web server for completing the oAuth process.'
}
#>
#$script:RedirectUri = 'http://localhost:8000/auth/complete'
#$script:Scopes = 'https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/youtubepartner-channel-audit'

#$script:thisApp = $thisApp
foreach ($File in [System.IO.Directory]::EnumerateFiles("$PSScriptRoot\functions\",'*.ps1','AllDirectories')) {
  . $File
}
<#foreach ($Format in [System.IO.Directory]::EnumerateFiles("$PSScriptRoot\formats\",'*.ps1xml','AllDirectories')) {
  Update-FormatData -PrependPath $Format
}#>