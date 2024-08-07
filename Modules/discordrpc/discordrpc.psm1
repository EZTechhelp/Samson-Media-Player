$script:ModuleRoot = $PSScriptRoot

[void][System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\bin\Newtonsoft.Json.dll")
[void][System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\bin\DiscordRPC.dll")

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
    . Import-ModuleFile -Path $function
}

Register-ArgumentCompleter -ParameterName Template -CommandName Start-DSClient -ScriptBlock {
    param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
    "discordrpc", "'Amazon Music'", "Apple", "'Apple Music'", "Discord", "'Disney+'", "DockerHub", "Duolingo", "GitHub", "'GitHub Codespaces'", "GitLab", "Google", "'Google Play Music'", "Hacktoberfest", "'HBO Max'", "Hulu", "Imgur", "'Jira Software'", "Kodi", "'Microsoft Teams'", "Netflix", "Pandora", "'Paramount+'", "Peacock", "Peloton", "Plex", "'Pocket Casts'", "'Prime Video'", "Reddit", "Shazam", "Showtime", "SoundCloud", "Speedtest", "'Stack Overflow'", "TikTok", "Tumblr", "Twitch", "Vimeo", "VLC", "Wikipedia", "YouTube", "'YouTube Music'", "Zoom","Bing", "Amazon", "Bandcamp", "Giphy", "Instagram", "LeetCode", "SiriusXM", "W3Schools", "Codecademy", "freeCodeCamp", "Glitch", "Pastebin", "'Bots For Discord'", "'Bots on Discord'", "Codenames", "CodePen", "Codewars", "'Discord Bot List'", "'Discord BotList'", "'Discord Bots'", "'Discord Extreme List'", "'Discord Templates'", "Discord.bio", "Discord.js", "'DiscordJS Guide'", "DiscordLabs.org", "discordtrlist.xyz", "DuckDuckGo", "Electron", "Emojipedia", "'Font Awesome'", "GGRadio", "Gitbook", "Gitea", "'Google Calendar'", "'Google Classroom'", "'Google Docs'", "'Google Domains'", "'Google Drive'", "'Google Fonts'", "'Google Meet'", "'Google Messages'", "'Google Translate'", "'HBO GO'", "Lawcodev", "Medium", "Messenger", "ReadTheDocs", "'South Park'", "'Virgin Media'", "VirusTotal", "Wikiquote", "Wikisource", "WIRED", "XKCD", "Trello", "TryHackMe", "Streamlabs", "Tidal", "Stadia", "Starz", "Steam", "'Spotify Podcasts'", "Skype", "Mixcloud", "'Minecraft Central'", "MinecraftForge", "'Google Podcast'", "Gfycat" | Where-Object { $PSItem -like "$WordToComplete*" } | Select-Object -Unique | & { process {
        [System.Management.Automation.CompletionResult]::new($PSItem, $PSItem, "ParameterName", $PSItem)
    }}
}

# global variables needed for timer scriptblocks
if ($global:discordrpcclient) {
    $script:rpcclient = $global:discordrpcclient
}