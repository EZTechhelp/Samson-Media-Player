<#
    .Name
    Set-Shuffle

    .Version 
    0.1.0

    .SYNOPSIS
    Sets/toggles shuffle state for media player  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Set-Shuffle Function
#----------------------------------------------
function Set-Shuffle
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Verboselog
  )
  try{
    if($thisapp.config.Shuffle_Playback){
      $synchash.Shuffle_Icon.Kind = 'ShuffleDisabled'
      $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Disabled'
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\$($synchash.Shuffle_Icon.Kind).png")
      $image =  [System.Drawing.Image]::FromStream($stream_image)
      $synchash.Shuffle_trayOption.Image = $image
      Add-Member -InputObject $thisapp.config -Name 'Shuffle_Playback' -Value $false -MemberType NoteProperty -Force
      $synchash.Shuffle_trayOption.Checked = $thisapp.config.Shuffle_Playback
    }else{
      $synchash.Shuffle_Icon.Kind = 'ShuffleVariant'
      $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Enabled'
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\$($synchash.Shuffle_Icon.Kind).png")
      $image =  [System.Drawing.Image]::FromStream($stream_image)
      $synchash.Shuffle_trayOption.Image = $image
      Add-Member -InputObject $thisapp.config -Name 'Shuffle_Playback' -Value $true -MemberType NoteProperty -Force
      $synchash.Shuffle_trayOption.Checked = $thisapp.config.Shuffle_Playback
    }
  }catch{
    write-ezlogs "An exception occurred in Shuffle_Playback_Button click event" -CatchError $_ -showtime
  }finally{
    try{
      $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
    }   
  }
}
#---------------------------------------------- 
#endregion SSet-Shuffle Function
#----------------------------------------------
Export-ModuleMember -Function @('Set-Shuffle')