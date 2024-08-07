<#
    .Name
    Add-EQPreset

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and adds EQ Presets

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

#>

#---------------------------------------------- 
#region Add-EQPreset Function
#----------------------------------------------
function Add-EQPreset
{
  Param (
    [string]$PresetName,
    $EQ_Bands,
    $EQ_Preamp,
    $thisApp,
    $synchash,
    [string]$ImportPreset,
    [switch]$Apply_EQ,
    [string]$Preset_ID,
    [switch]$Startup,
    [string]$EQPreset_Profile_Directory = $thisApp.config.EQPreset_Profile_Directory,
    [switch]$Verboselog
  )
  try{
    Add-Type -AssemblyName System.Web
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
    $pattern = "[™$illegal]"
    $pattern2 = "[$illegal]" 
    $Preset_Directory_Path = [System.IO.Path]::Combine($EQPreset_Profile_Directory,'Custom-EQPresets')
    if(![System.IO.File]::Exists($Preset_Directory_Path)){
      $Null = New-Item -Path $Preset_Directory_Path -ItemType directory -Force
    } 
    if([System.IO.File]::Exists($ImportPreset)){
      write-ezlogs "#### Importing Custom EQ Preset $ImportPreset" -loglevel 2 -logtype Libvlc
      $Preset_to_Update = Import-CliXml -Path $ImportPreset
      $Preset_Path_Name = [system.io.path]::GetFileName($ImportPreset)
      $Preset_File_Path = [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)     
      $PresetName = $Preset_to_Update.Preset_Name
      $EQ_Bands = $Preset_to_Update.EQ_Bands
      $EQ_Preamp = $Preset_to_Update.EQ_Preamp
    }else{
      write-ezlogs "#### Adding/Updating EQ Preset $PresetName" -loglevel 2 -logtype Libvlc
      $Preset_Path_Name = "$($PresetName)-Custom-EQPreset.xml" 
      $Preset_File_Path = [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)     
      if([System.IO.File]::Exists($Preset_File_Path)){ 
        if($Verboselog){write-ezlogs " | Importing EQ Preset Profile: $Preset_File_Path" -showtime -enablelogs}
        $Preset_to_Update = Import-CliXml -Path $Preset_File_Path
      }elseif($PresetName -and $EQ_Bands){
        if($Verboselog){write-ezlogs " | Preset Profile to import not found at $Preset_File_Path....Attempting to build new profile" -showtime -enablelogs -color cyan}
        $Preset_to_Update =[Custom_EQ_Preset]::new()
        $Preset_encodedTitle = $Null  
        $Preset_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($PresetName)-CustomEQPreset")
        $Preset_encodedTitle = [System.Convert]::ToBase64String($Preset_encodedBytes)
        $Preset_to_Update.Preset_ID = $Preset_encodedTitle
        $Preset_to_Update.Preset_Name = $PresetName
        #$Preset_to_Update.Preset_Date_Added = [Datetime]::Now
        #$Preset_to_Update.type = 'CustomEQPreset'
        $Preset_to_Update.Preset_Path = $Preset_File_Path
      }                  
    }    
    if(-not [string]::IsNullOrEmpty($Preset_to_Update.Preset_ID) -and $PresetName -and $EQ_Bands){
      $Preset_to_Update.EQ_Bands = $EQ_Bands
      if(-not [string]::IsNullOrEmpty($EQ_Preamp)){       
        $Preset_to_Update.EQ_Preamp = $EQ_Preamp
        #Add-Member -InputObject $Preset_to_Update -Name 'EQ_Preamp' -Value $EQ_Preamp -MemberType NoteProperty -Force
      }elseif(-not [string]::IsNullOrEmpty($thisapp.Config.EQ_Preamp)){
        $Preset_to_Update.EQ_Preamp = $thisapp.Config.EQ_Preamp
        #Add-Member -InputObject $Preset_to_Update -Name 'EQ_Preamp' -Value $thisapp.Config.EQ_Preamp -MemberType NoteProperty -Force
      } 
      write-ezlogs ">>>> Exporting updated Preset profile to $Preset_File_Path" -showtime -color cyan
      Export-Clixml -InputObject $Preset_to_Update -Path $Preset_File_Path -Force -Encoding Default
      write-ezlogs ">>> Updating app config custom eq playlists" -showtime -color cyan
      if($thisApp.Config.Custom_EQ_Presets.Preset_Name -notcontains $PresetName){
        $newRow = [Custom_EQ_Preset]@{
          'Preset_Name' = $PresetName
          'Preset_ID'   = $Preset_to_Update.Preset_ID
          'Preset_Path' = $Preset_File_Path
        }
        $null = $thisApp.Config.Custom_EQ_Presets.add($newRow)
      }elseif($thisApp.Config.Custom_EQ_Presets){
        $pindex = $thisApp.Config.Custom_EQ_Presets.preset_name.IndexOf($PresetName)
        if($pindex -ne -1){
          $update_preset = $thisApp.Config.Custom_EQ_Presets[$pindex]
        }
        if($update_preset){
          $update_preset.Preset_ID = $Preset_to_Update.Preset_ID
          $update_preset.Preset_Path = $Preset_File_Path
        }
      }
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
      #Export-Clixml -InputObject $thisApp.config -Path $thisApp.Config.Config_Path -Force -Encoding Default    
      if($Apply_EQ){
        if($Preset_to_Update.Preset_Name){
          if($synchash.LoadPreset_Button.items.header -notcontains $Preset_to_Update.Preset_Name -and $Preset_to_Update.Preset_Name -notin 'Memory 1','Memory 2' -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $Preset_to_Update.Preset_Name){
            $Menuitem = [System.Windows.Controls.MenuItem]::new()
            $Menuitem.IsCheckable = $true
            $Menuitem.Header = $Preset_to_Update.Preset_Name
            $null = $Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
            $null = $Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
            $null = $synchash.LoadPreset_Button.items.add($Menuitem)
          }else{
            write-ezlogs "An existing preset with name $($Preset_to_Update.Preset_Name) already exists -- updated to current values" -showtime -warning -logtype Libvlc
          }
          if($Preset_to_Update.Preset_Name -eq 'Memory 1'){
            $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $true
            $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $false
          }elseif($Preset_to_Update.Preset_Name -eq 'Memory 2'){
            $synchash.EQ_CustomPreset2_ToggleButton.isChecked = $true
            $synchash.EQ_CustomPreset1_ToggleButton.isChecked = $false
          }  
          if($synchash.SetEQasActive){
            $thisApp.Config.EQ_Selected_Preset = $Preset_to_Update.Preset_Name
            #Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value $Preset_to_Update.Preset_Name -MemberType NoteProperty -Force
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
            #Export-Clixml -InputObject $thisapp.config -Path $thisapp.config.Config_Path -Force -Encoding UTF8
            foreach($item in $synchash.LoadPreset_Button.items){
              if($item.Header -eq $Preset_to_Update.Preset_Name){
                $item.isChecked = $true
              }elseif($item.isChecked){
                $item.isChecked = $false
              }
            }
            foreach($presets in $thisapp.config.EQ_Presets){
              if($synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton" -and $synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton".isChecked -and $presets.Preset_ID -ne $Preset_to_Update.Preset_ID){      
                $synchash."EQ_Preset_$($presets.Preset_ID)_ToggleButton".IsChecked = $false                           
              }              
            }
            if($synchash."EQ_Preset_$($Preset_to_Update.Preset_ID)_ToggleButton" -and !$synchash."EQ_Preset_$($Preset_to_Update.Preset_ID)_ToggleButton".isChecked){
              $synchash."EQ_Preset_$($Preset_to_Update.Preset_ID)_ToggleButton".isChecked = $true
            }
            if($synchash.CurrentSaveMenuItem){
              if(-not [string]::IsNullOrEmpty($thisapp.config.EQ_Selected_Preset)){
                $synchash.CurrentSaveMenuItem.Header = "Save as '$($thisapp.config.EQ_Selected_Preset)'"
                $synchash.CurrentSaveMenuItem.Height = [double]::NaN
                $synchash.CurrentSaveMenuItem.Uid = ($thisapp.config.Custom_EQ_Presets | where {$_.Preset_Name -eq $thisapp.config.EQ_Selected_Preset}).Preset_ID
              }else{
                $synchash.CurrentSaveMenuItem.Header = ""
                $synchash.CurrentSaveMenuItem.Height = '0'
                $synchash.CurrentSaveMenuItem.Uid = $Null
              }
            }
            write-ezlogs ">>>> Applying new imported Preset to EQ" -logtype Libvlc
            $synchash.EQ_Timer.start()
          }
        }else{
          write-ezlogs 'Unable to add Preset as no preset profile was returned when importing!' -showtime -warning -logtype Libvlc
        } 
        if($synchash.keys -contains 'SetEQasActive'){
          [void]$synchash.Remove('SetEQasActive')
        }
      }else{
        return $Preset_to_Update
      }
       
    }else{
      write-ezlogs "Could not find Preset to update or no Preset to update was provided" -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in Add-EQPreset" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Add-EQPreset Function
#----------------------------------------------

#---------------------------------------------- 
#region Remove-EQPreset Function
#----------------------------------------------
function Remove-EQPreset
{
  Param (
    [string]$PresetName,
    $EQ_Bands,
    $EQ_Preamp,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [string]$EQPreset_Profile_Directory = $thisApp.config.EQPreset_Profile_Directory,
    [switch]$Verboselog
  )
  try{
    Add-Type -AssemblyName System.Web
    if($Verboselog){write-ezlogs "#### Removing EQ Preset $PresetName ####" -enablelogs -color yellow -linesbefore 1}
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
    $pattern = "[™$illegal]"
    $pattern2 = "[$illegal]" 
    $Preset_Path_Name = "$($PresetName)-Custom-EQPreset.xml"    
    $Preset_Directory_Path = [System.IO.Path]::Combine($EQPreset_Profile_Directory,'Custom-EQPresets')
    $Preset_File_Path = [System.IO.Path]::Combine($Preset_Directory_Path,$Preset_Path_Name)  
    if([System.IO.File]::Exists($Preset_File_Path)){ 
      if($Verboselog){write-ezlogs " | Deleting EQ Preset Profile: $Preset_File_Path" -showtime -enablelogs}
      Remove-item $Preset_File_Path -Force  
    }else{
      write-ezlogs "Unable to find preset profile to remove at $Preset_File_Path" -showtime -warning
    }
    $PresetToRemove = $thisApp.Config.Custom_EQ_Presets | where {$_.Preset_Name -eq $PresetName}
    if($PresetToRemove){      
      $null = $thisApp.Config.Custom_EQ_Presets.Remove($PresetToRemove) 
      write-ezlogs " | Removed Custom Preset: $($PresetToRemove.Preset_Name)" -showtime
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
      #Export-Clixml -InputObject $thisApp.config -Path $thisApp.Config.Config_Path -Force -Encoding UTF8   
    }else{
      write-ezlogs "Unable to find custom preset to remove: $($PresetToRemove.Preset_Name)" -showtime -warning
    }      
  }catch{
    write-ezlogs "An exception occurred in Remove-EQPreset" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Remove-EQPreset Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-EQPreset','Remove-EQPreset')