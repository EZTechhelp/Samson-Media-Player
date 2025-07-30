#$script:RedirectUri = 'http://localhost:8000/auth/complete'
#$script:Scopes = 'https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/youtubepartner-channel-audit'

#$script:thisApp = $thisApp
foreach ($File in [System.IO.Directory]::EnumerateFiles("$PSScriptRoot\functions\",'*.ps1','AllDirectories')) {
  . $file
}