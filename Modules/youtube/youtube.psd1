@{
  RootModule = 'youtube.psm1'
  Author = 'Trevor Sullivan <trevor@trevorsullivan.net>'
  CompanyName = 'Trevor Sullivan'
  ModuleVersion = '0.3.6'
  GUID = '4f1448cd-300f-444c-afdf-8ed678504ffd'
  Copyright = '2022 Trevor Sullivan'
  Description = 'Manage YouTube from the command line with PowerShell.'
  PowerShellVersion = '5.1'
  CompatiblePSEditions = @('Desktop', 'Core')
  FunctionsToExport = @(
    'Grant-YouTube'
    'Grant-YouTubeOauth'
    'Find-YouTubeVideo'
    'Find-YouTubeChannel'
    'Get-YouTubeVideo'
	'Get-AccessToken'
    'Set-YouTubeConfiguration'
    'Get-YouTubeCommentThread'
    'Get-YouTubeComment'
    'New-YouTubeComment'
    'Remove-YouTubeComment'
    'Add-YouTubeSubscription'
    'Get-YouTubeSubscription'
    'Remove-YouTubeSubscription'
    'Get-YouTubePlaylistItems'
    'Get-YouTubeActivity'
    'Get-YouTubeChannel'
    'Set-YouTubeVideoRating'
	  'New-YoutubeApplication',
    'Remove-YoutubePlaylistItem'
  )
  AliasesToExport = @('')
  VariablesToExport = @('')
  PrivateData = @{
    PSData = @{
      Tags = @('google', 'youtube')
      LicenseUri = 'https://github.com/pcgeek86/youtube/blob/main/LICENSE'
      ProjectUri = 'https://github.com/pcgeek86/youtube/'
      IconUri = ''
      ReleaseNotes = @'
0.2 

- Added New-YouTubeComment to create a top-level comment thread


0.1

- Initial realease
'@
    }
  }
  # HelpInfoURI = ''
}

