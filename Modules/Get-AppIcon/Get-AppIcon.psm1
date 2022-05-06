<#
    .Name
    Get-AppIcon

    .Version 
    0.1.0

    .SYNOPSIS
    Generates application icons and saves to disk.  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher

    .EXAMPLE

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Export-Resources Function
#---------------------------------------------- 
function Export-Resources 
{
  
  Param ( 
    [Parameter(Mandatory=$false)]
    [string]$file_path,
    [string]$app_name,
    [string]$Output_folder,
    [string]$execute_file,
    [switch]$Verboselog
  )  
  
  #$App_name = 'resourcesextract' #The name of the application
  if(!$app_name)
  {
    $app_name = (Get-childitem $file_path -Force).BaseName
  }
  $Output_folder = [System.IO.Path]::Combine($Output_folder, $app_name) 
  
  #Create config file and run process
  if($execute_file)
  {
    #$null = $cfg_file | Out-File -FilePath $download_cfg_file -Encoding unicode -Force
    $argumentlist = "/Source `"$file_path`" /DestFolder `"$Output_folder`"" 
    if($verboselog){write-ezlogs ">>>> Extracting icon from $file_path to $Output_folder" -showtime -color cyan -enablelogs}
    $proc = Start-Process -FilePath $execute_file -ArgumentList $argumentlist -PassThru -NoNewWindow
    start-sleep -Milliseconds 50  
  } 

}
#---------------------------------------------- 
#endregion Export-Resources Function
#---------------------------------------------- 

#---------------------------------------------- 
#region Convert-image Function
#---------------------------------------------- 
function Convert-image 
{
  
  Param ( 
    [Parameter(Mandatory=$false)]
    [string]$file_path,
    [string]$app_name,
    [string]$IconSize,
    [string]$Output_folder,
    [string]$execute_file,
    [switch]$Verboselog
  )  
  if(!$app_name)
  {
    $app_name = (Get-childitem $file_path -Force).BaseName
  }
  $Output_file = [System.IO.Path]::Combine($Output_folder, "$app_name.ico") 
  
  
  if($file_path -and $app_name)
  {
    if($verboselog){write-ezlogs " | Converting image $file_path to icon $Output_file" -enablelogs -showtime}

    $Null = Start-process $execute_file -ArgumentList "`"$file_path`" -define icon:auto-resize=$IconSize `"$Output_file`"" -NoNewWindow -PassThru
    if((Get-ChildItem $file_path -Force -File).Length -gt 100000){
      #[GC]::Collect() 
      start-sleep 1
    }
    else
    {
      start-sleep -Milliseconds 50
    } 
    return $Output_file   
  } 
}
#---------------------------------------------- 
#endregion Convert-image Function
#---------------------------------------------- 

#---------------------------------------------- 
#region Get-AppIcon Function
#---------------------------------------------- 
Function Get-AppIcon 
{
  Param ( 
    [Parameter(Mandatory=$false)]
    $file_path,
    [string]$app_name,
    [string]$folder,
    [string]$Platform,
    [string]$IconSize,
    [switch]$Verboselog,
    [string]$convert_image_path,
    [string]$SaveFolder,
    [string]$Resource_extract
  )
  $null = [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[:$illegal]"
  $pattern2 = "[`"$illegal]"
  #$app_name = [Regex]::Replace($app_name, $pattern, '-')
  $app_name_cleaned = [Regex]::Replace($app_name, $pattern, ' ').replace('  ',' ')
  $folder = [Regex]::Replace($folder, $pattern2, '')
  $OriginalPref = $ProgressPreference
  $ProgressPreference = 'SilentlyContinue'
  if($Verboselog)
  {
    Write-EZLogs ">>>> Getting Icons for $app_name (cleaned: $app_name_cleaned)" -Color cyan -enablelogs -showtime
  }
  if(!(Test-Path $SaveFolder -PathType Container))
  {
     $null = New-item $SaveFolder -ItemType directory -Force
  }
  if($folder)
  {
    $file_path = (Get-ChildItem $folder -Filter '*.ico' -recurse -Force -ErrorAction Continue).FullName | select -First 1
    if(!$file_path)
    {
      $file_path = (Get-ChildItem $folder -Filter '*logo*.png' -recurse -Force).FullName | select -First 1 #| where {$_ -eq $app_name}
    }
    if(!$file_path)
    {
      $file_path = (Get-ChildItem $folder -Filter '*logo*.jpg' -recurse -Force).FullName | select -First 1 #| where {$_ -eq $app_name}
    }
    if(!$file_path -and $Platform -eq "Ubisoft")
    {
      $file_path = (Get-ChildItem $folder -Filter '*_plus.exe' -recurse -Force).FullName | select -First 1
    }
    if(!$file_path)
    {
      $file_path = (Get-ChildItem $folder -Filter "*$app_name_cleaned*.exe" -recurse -Force).FullName | select -First 1 #| where {$_ -eq $app_name}
    }      
    if(!$file_path)
    {
      $appname_exe = $((Get-Culture).textinfo.totitlecase($app_name.replace(' ','').replace(':',' ').tolower()))
      $file_path = (Get-ChildItem $folder -Filter "*$appname_exe*.exe" -recurse -Force).FullName | select -First 1
    }   
    if(!$file_path)
    {
      $file_path = (Get-ChildItem $folder -Filter "*$app_name*.exe" -Recurse -Force).FullName | select -First 1 #| where {$_ -eq $app_name}
    }
    if(!$file_path)
    {
      $file_path = (Get-ChildItem $folder -Filter '*.exe' -Depth 3 -Force).FullName | select -First 1 #| where {$_ -eq $app_name}
    }         
    if($Verboselog)
    {
      Write-EZLogs " | Using Folder $folder" -showtime -enablelogs
      Write-EZLogs " | Found file to use: $file_path" -showtime -enablelogs
      
    }
  }
  foreach ($img in $file_path)
  {  
    try
    {    
      $img_ext = [System.IO.Path]::GetExtension($img) 2>$null
      $img_dirpath = [System.IO.Path]::GetDirectoryName($img) 2>$null
      $baseName = [System.IO.Path]::GetFileNameWithoutExtension($img)
      if(Test-Path "$SaveFolder\$app_name_cleaned")
      {
        $icon = (Get-childitem "$SaveFolder\$app_name_cleaned" -Filter '*.ico' -Force).FullName | select -first 1
        if($icon)
        {
          if($Verboselog)
          {
            Write-EZLogs " | Cached icon found: $icon" -Color Cyan -showtime -enablelogs
          }
          #$app_name = $null
          return $icon
        }
      }      
      if(Test-Path "$SaveFolder\$app_name_cleaned.ico" 2>$null)
      { 
        if($Verboselog)
        {
          Write-EZLogs " | Cached icon found: $SaveFolder\$([regex]::Escape($app_name_cleaned)).ico" -Color Cyan -showtime -enablelogs
          Write-EZLogs " | Icon path (Non-escaped): $SaveFolder\$app_name_cleaned.ico" -showtime -enablelogs
        }
        $icon = "$SaveFolder\$app_name_cleaned.ico"
        $app_name_cleaned = $null
        return $icon
      }
      elseif($img_ext -eq '.ico')
      {
        $icon = "$SaveFolder\$app_name_cleaned$img_ext"
        if($Verboselog)
        {
          Write-EZLogs " | Using icon file $img" -Color Cyan -showtime -enablelogs
          Write-EZLogs " | Copying to path: $icon" -showtime -enablelogs
        }
        if(!(Test-Path "$icon")){
           Copy-Item $img -Destination "$icon" -Force
        }
        $app_name_cleaned = $null
        return $icon      
      }
      elseif($img_ext -eq '.png' -or $img_ext -eq '.jpg')
      {
        if(!(Test-Path $img 2>$null))
        { 
          $img_path = (Get-ChildItem $img_dirpath -Recurse -Include "*$baseName*$img_ext" -ErrorAction SilentlyContinue).FullName | select -First 1
          if(!$img_path)
          {
            if($Verboselog)
            {
              Write-EZLogs " | Unable to find image at path: $img" -color cyan -showtime -enablelogs
              $app_name_cleaned = $null
              return
            }
          }
          else
          {
            $img = $img_path
          }
        }
        if($Verboselog)
        {
          Write-EZLogs " | Using Image File: $img" -color cyan -showtime -enablelogs
          Write-EZLogs " | Destination: $SaveFolder\$app_name_cleaned$img_ext" -showtime -enablelogs
        }
        $icon = Convert-image -file_path $img -Output_folder $SaveFolder -app_name $app_name_cleaned -IconSize $IconSize -execute_file $convert_image_path -Verboselog:$Verboselog
        #Copy-Item $img -Destination "$SaveFolder\$app_name.$img_ext" -Force
        #$img = "$SaveFolder\$app_name.$img_ext"
        $app_name_cleaned = $null
        return $icon 
      }
      elseif($img_ext -eq '.exe' -or $img_ext -eq '.dll')
      {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($img)
        if($Verboselog)
        {
          Write-EZLogs " | Extracting icon from File: $img" -color cyan -showtime -enablelogs
          Write-EZLogs " | Destination: $SaveFolder\$app_name_cleaned" -showtime -enablelogs
        }
        Export-Resources -file_path $img -Output_folder "$SaveFolder" -app_name $app_name_cleaned -execute_file $Resource_extract -Verboselog:$Verboselog
        if((Test-Path "$SaveFolder\$app_name_cleaned"))
        {
          Start-sleep -Milliseconds 50
          $img = (Get-childitem "$SaveFolder\$app_name_cleaned" -Filter '*.ico' -Force).FullName | select -first 1
          if($img)
          {
            if($Verboselog){Write-EZLogs " | Found generated icon at $img" -color Green -showtime -enablelogs}
            #$icon = "$SaveFolder\$app_name.ico"
            #$icon = Convert-image -file_path $img -Output_folder $SaveFolder -app_name $app_name -IconSize $IconSize -Verboselog:$Verboselog
            #Copy-item $img -Destination $icon -Force
            $app_name_cleaned = $null
            return $img
          }
          else
          {
            if($Verboselog){Write-EZLogs " | Icon not generated. Couldn't find any output icon files at: $SaveFolder\$app_name_cleaned | IMG path: $img" -Warning -showtime -enablelogs}
            $app_name_cleaned = $null
            return
          }         
        }
        else
        {
          if($Verboselog)
          {
            Write-EZLogs " | Extracting icon failed! Source file: $img" -color red -showtime -enablelogs
            Write-EZLogs " | Destination folder: $SaveFolder\$app_name_cleaned" -color red -showtime -enablelogs
          }
          $app_name_cleaned = $null
          return        
        }     
      }
    }
    catch
    {
      Write-EZLogs "[ERROR] Unable to generate icon for $app_name (Cleaned: $app_name_cleaned)`n | Image Path: $img`n | Save Folder: $SaveFolder`n | Img Ext: $img_ext`n -- $($_.Exception.Message)`n$($_.InvocationInfo.PositionMessage)" -Color Red -ShowTime -enablelogs
    }
  }
   
}
#---------------------------------------------- 
#endregion Get-AppIcon Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-AppIcon','Export-Resources','Convert-image')