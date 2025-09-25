<#
    .Name
    Get-TMDB

    .Version 
    0.1.0

    .SYNOPSIS
    Fetches movie/TV show metadata via the TMDbLib wrapper of the TheMovieDB API

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
    Image URL Path: https://image.tmdb.org/t/p/w780/
    TorrentTitleParser: https://github.com/bhmahler/TorrentTitleParser
#>

#---------------------------------------------- 
#region Get-TMDBSecret Function
#----------------------------------------------
function Get-TMDBSecret {
  <#
      .SYNOPSIS
      Retrieves or optionally sets secret token for TMDB API.

      .EXAMPLE
      Get-TMDBSecret
  #>
  [CmdletBinding()]
  param (
    $thisApp = $thisApp,
    [string]$TMDBSecret
  )
  try{
    try{
      $name = $thisApp.Config.App_Name
      $secretstore = Get-SecretVault -Name $name -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting SecretStore: $name" -showtime -catcherror $_
    }
    if(!$Secretstore){
      try{
        Write-ezlogs "No SecretStore found called $Name" -warning -showtime
        write-ezlogs ">>>> Setting new SecretStoreConfiguration with password set to: $Name (Scope: CurrentUser)" -showtime
        Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
        write-ezlogs ">>>> Registering new SecretVault: $name" -showtime
        $secretstore = Register-SecretVault -Name $Name -ModuleName "$($thisApp.Config.Current_Folder)\Modules\Microsoft.PowerShell.SecretStore" -DefaultVault -Description "Created by $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)" -PassThru
      }catch{
        write-ezlogs "An exception occurred registering new secretvault with name: $Name" -catcherror $_
      }
    }
    if($secretstore){
      if(-not [string]::IsNullOrEmpty($TMDBSecret)){
        try{
          write-ezlogs ">>>> Saving TMDBSecret to vault: $Name"
          Set-Secret -Name TMDBSecret -Secret $TMDBSecret -Vault $Name
        }catch{
          write-ezlogs "An exception occurred saving TMDBSecret to vault: $Name" -catcherror $_
        }
      }else{
        try{
          $TMDBSecret = Get-secret -name TMDBSecret -Vault $name -ErrorAction Continue
        }catch{
          if($_ -match 'A valid password is required to access'){
            write-ezlogs "A valid password is required to access secret vault: $name" -warning
            $unlock = $true
          }else{
            write-ezlogs "An exception occurred getting TMDBSecret from Secret vault: $name" -catcherror $_
          }
        }
        if($unlock){
          try{
            write-ezlogs "| Attempting to unlock secret store: $Name" -warning
            Unlock-SecretStore -password:$($Name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
            $TMDBSecret = Get-secret -name TMDBSecret -Vault $name -ErrorAction Continue
          }catch{
            write-ezlogs "An exception occurred unlocking secretstore: $($Name)" -catcherror $_
          }
        }
        if([string]::IsNullOrEmpty($TMDBSecret)){
          try{
            $APIXML = "$($thisApp.Config.Current_folder)\Resources\API\TMDB-API-Config.xml"
            if([System.IO.File]::Exists($APIXML)){
              write-ezlogs ">>>> Importing API Config file: $APIXML" -showtime
              $TMDB_API_CONFIG = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText($APIXML))
              $TMDBSecret = $TMDB_API_CONFIG.Client_Secret
            }
            if(-not [string]::IsNullOrEmpty($TMDBSecret)){
              write-ezlogs "| Saving TMDBSecret to vault: $Name"
              Set-Secret -Name TMDBSecret -Secret $TMDBSecret -Vault $Name
            }else{
              write-ezlogs "No TMDBSecret found or provided!" -Warning
            }
          }catch{
            write-ezlogs "An exception occurred getting clientid or clientsecret from API Config file: $APIXML" -catcherror $_
          }
        }
      }
      return $TMDBSecret
    }else{
      write-ezlogs "Unable to get or create Secret Vault: $Name -- cannot continue!" -Warning
    }
  }catch{
    write-ezlogs "An exception occurred in Get-TMDBSecret" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-TMDBSecret Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-TMDB Function
#----------------------------------------------
function Get-TMDB {
  <#
      .SYNOPSIS
      Retrieves list of Youtube playlists.

      .EXAMPLE
      Get-YouTubePlaylists

      .EXAMPLE
      Get-YouTubePlaylists
  #>
  [CmdletBinding()]
  param (
    [string]$SearchQuery,
    [string]$FilePath,
    $thisApp = $thisApp,
    $MediaProfile,
    [ValidateSet('Movie','TvShow','Collection','Keyword','Multi')]
    [string]$SearchType = 'Multi',
    [string]$LookupID,
    [ValidateSet('Movie','TvShow','Collection','Keyword','TvEpisode','TvSeason')]
    [string]$LookupType,
    [string]$SeasonNumber,
    [string]$EpisodeNumber,
    [string]$Language,
    [string]$Country,
    [switch]$ParseTorName,
    [switch]$UpdateProfile
  )
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[.:`?�™®$illegal]"
  if(-not [string]::IsNullOrEmpty($SearchQuery) -or -not [string]::IsNullOrEmpty($LookupID) -or -not [string]::IsNullOrEmpty($FilePath)){
    try{   
      if(-not [string]::IsNullOrEmpty($FilePath)){
        if([system.io.path]::HasExtension($FilePath)){
          write-ezlogs ">>>> Getting search query from filepath: $FilePath"
          $SearchQuery = [system.io.path]::GetFileNameWithoutExtension($FilePath)
        }else{
          write-ezlogs "Invalid file path was provided: $FilePath" -Warning
        }
      }     
    }catch{
      write-ezlogs "An exception occurred importing TMDB API Config" -showtime -catcherror $_
    }
    try{   
      $TMDBSecret = Get-TMDBSecret -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred importing TMDB API Config" -showtime -catcherror $_
    }
    if(-not [string]::IsNullOrEmpty($TMDBSecret)){
      try{
        if(-not [bool]('TMDbLib.Client.TMDbClient' -as [Type])){
          [void][System.Reflection.Assembly]::LoadFrom("$($thisApp.Config.Current_Folder)\Modules\Get-TMDB\TMDbLib.dll")
        }
        $TMDB_Client = [TMDbLib.Client.TMDbClient]::new($TMDBSecret)
        if($ParseTorName){
          try{
            $ParseTor = [TorrentTitleParser.Torrent]::new($SearchQuery)
            $ParseTor2 = [TorrentTitleParser.Torrent]::new($FilePath)
            if($ParseTor.Title){
              $SearchQuery = $ParseTor.Title
            }
            if($ParseTor.Season){
              $SearchType = 'TvShow'
              $LookupType = 'TvSeason'
              $SeasonNumber = $ParseTor.Season
            }
            if($ParseTor.Episode){
              $SearchType = 'TvShow'
              $LookupType = 'TvEpisode'
              $EpisodeNumber = $ParseTor.Episode
            }
            if($ParseTor.Year){
              $Year = $ParseTor.Year
            }elseif($ParseTor2.Year){
              $Year = $ParseTor2.Year
            }
          }catch{
            write-ezlogs "An exception occurred attempting to parse info from Tor name" -CatchError $_
          }
        }
        if(-not [string]::IsNullOrEmpty($SearchQuery)){
          try{             
            write-ezlogs ">>>> Executing TMDB client SearchType: ($SearchType) with SearchQuery: ($SearchQuery)"
            $Result = $TMDB_Client."Search$($SearchType)Async"($SearchQuery)
            if($Result.result.TotalResults -gt 0){
              $MatchedResults = $Result.result.Results | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person'}
              if(@($MatchedResults).count -gt 1 -and $Year){
                $MatchedResults = $Result.result.Results | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person' -and ($_.ReleaseDate -match $Year -or $_.FirstAirDate -match $Year)}
              }
              if(@($MatchedResults).count -gt 1 -and !$Country -and $FilePath -and [system.io.path]::GetFileNameWithoutExtension($FilePath) -match '\(US\)' -and $MatchedResults.OriginCountry -contains 'US'){
                $MatchedResults = $MatchedResults | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person' -and ($_.OriginCountry -contains 'US')}
              }
              if(@($MatchedResults).count -gt 1 -and $MatchedResults.OriginCountry -contains $Country){
                $MatchedResults = $Result.result.Results | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person' -and ($_.OriginCountry -contains $Country)}
              }
              if(@($MatchedResults).count -gt 1 -and $MatchedResults.OriginalLanguage -contains $Language){
                $MatchedResults = $Result.result.Results | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person' -and ($_.OriginalLanguage -contains $Language)}
              }
              if(@($MatchedResults).count -eq 1){
                write-ezlogs "Found 1 result from TMDB" -Success
                if($ParseTorName -and $MatchedResults.Id){
                  $LookupID = $MatchedResults.Id
                  if(!$LookupType -and $MatchedResults.MediaType -eq 'Tv'){
                    $LookupType = 'TvShow'
                  }elseif(!$LookupType -and $MatchedResults.MediaType){
                    $LookupType = $MatchedResults.MediaType
                  }elseif(!$LookupType){
                    $LookupType = $SearchType
                  }
                }else{
                  $Output = $MatchedResults
                }
                if($MatchedResults.name){
                  $FoundTitle = $MatchedResults.name
                }elseif($MatchedResults.title){
                  $FoundTitle = $MatchedResults.title
                }elseif($ParseTor.Title){
                  $FoundTitle = $ParseTor.Title
                }
              }elseif(@($MatchedResults).count -gt 0){
                write-ezlogs "Found $(@($MatchedResults).count) results from TMDB Search Query" -Success
                $Output = $MatchedResults                           
              }else{
                write-ezlogs "Found $(@($Result.result.Results).count) results from TMDB Search Query" -Success
                $Output = $Result.result.Results
              }
            }else{
              write-ezlogs "No results found from TMDB Search Query!" -warning
            }
          }catch{
            write-ezlogs "An exception occurred invoking TMDB client SearchType: ($SearchType) with SearchQuery: ($SearchQuery)" -showtime -catcherror $_
          }
        }
        if(-not [string]::IsNullOrEmpty($LookupID)){
          try{             
            write-ezlogs ">>>> Executing TMDB client lookupType: ($LookupType) with LookupID: ($LookupID)"
            if($LookupType -eq 'TvEpisode' -and $SeasonNumber -and $EpisodeNumber){
              $Result = $TMDB_Client."Get$($LookupType)Async"($LookupID,$SeasonNumber,$EpisodeNumber)
            }elseif($LookupType -eq 'TvSeason' -and $SeasonNumber){
              $Result = $TMDB_Client."Get$($LookupType)Async"($LookupID,$SeasonNumber)  
            }else{
              $Result = $TMDB_Client."Get$($LookupType)Async"($LookupID)  
            }            
            if($Result.result){
              if(@($Result.result).count -eq 1){
                write-ezlogs "Found 1 result from TMDB Lookup" -Success
                $Output = $Result.result
              }else{
                write-ezlogs "Found $(@($Result.result).count) from TMDB Lookup" -Success
                $Output = $Result.result
              }
            }else{
              if($SearchType -and $SearchQuery -and $ParseTor.Year){
                $Result = $TMDB_Client."Search$($SearchType)Async"($SearchQuery)
                $MatchedResults = $Result.result.Results | Where-Object {($_.Name -eq $SearchQuery -or [Regex]::Replace($_.Name, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim() -or $_.title -eq $SearchQuery -or [Regex]::Replace($_.title, $pattern, '').trim() -eq [Regex]::Replace($SearchQuery, $pattern, '').trim()) -and $_.MediaType -ne 'Person' -and ($_.ReleaseDate -notmatch $ParseTor.Year -and $_.FirstAirDate -notmatch $ParseTor.Year)} | Select-Object -First 1
                if(@($MatchedResults).count -eq 1 -and $MatchedResults.Id){
                  if($LookupType -eq 'TvEpisode' -and $SeasonNumber -and $EpisodeNumber){
                    $Result = $TMDB_Client."Get$($LookupType)Async"($MatchedResults.Id,$SeasonNumber,$EpisodeNumber)
                  }elseif($LookupType -eq 'TvSeason' -and $SeasonNumber){
                    $Result = $TMDB_Client."Get$($LookupType)Async"($MatchedResults.Id,$SeasonNumber)  
                  }else{
                    $Result = $TMDB_Client."Get$($LookupType)Async"($MatchedResults.Id)  
                  }
                  if($Result.result){
                    if(@($Result.result).count -eq 1){
                      write-ezlogs "Found 1 result from TMDB Lookup" -Success
                      $Output = $Result.result
                    }else{
                      write-ezlogs "Found $(@($Result.result).count) from TMDB Lookup" -Success
                      $Output = $Result.result
                    }
                  }else{
                    write-ezlogs "No results found from TMDB Lookup!" -warning
                  }
                }
              }else{
                write-ezlogs "No results found from TMDB Lookup!" -warning
              }              
            }
          }catch{
            write-ezlogs "An exception occurred invoking TMDB client lookupType: ($LookupType) with LookupID: ($LookupID)" -showtime -catcherror $_
          }
        }
        if($Output.Id -and ($LookupType -in 'TvEpisode','TvSeason') -and $FoundTitle){
          $Output.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('ShowName',$FoundTitle))
        }
      }catch{
        write-ezlogs "An exception occurred creating new TMDBClient" -catcherror $_
      }finally{
        if($TMDB_Client){
          $TMDB_Client.Dispose()
        }
      }
      $Output
    }else{
      write-ezlogs "Unable to find TMDB API Key - cannot continue!" -warning
    }
  }else{
    write-ezlogs "No search or lookup query was provided for TMDB - cannot continue!" -warning
  }
}
#---------------------------------------------- 
#endregion Get-TMDB Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-TMDB','Get-TMDBSecret')