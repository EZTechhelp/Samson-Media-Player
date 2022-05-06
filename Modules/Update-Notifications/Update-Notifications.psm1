<#
    .Name
    Update-Notifications

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of functions for managing the notifications UI

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
#region Update Notifications List Function
#----------------------------------------------
function Update-Notifications
{
  param (
    [switch]$Clear,
    $thisApp,
    [switch]$Startup,
    [switch]$Open_Flyout,
    $Notification_array,
    [string]$Message,
    [switch]$No_runspace,
    [string]$Level,
    [string]$Viewlink,
    [string]$Message_color = 'White',
    [string]$MessageFontWeight = 'Normal',
    [string]$Level_color = 'White',
    [string]$LevelFontWeight = 'Normal',
    [int]$id,
    $synchash,
    [switch]$VerboseLog = $thisApp.Config.Verbose_Logging
  )
  $Fields = @(
    'ID'
    'Time'
    'Level'
    'Level_color'
    'LevelFontWeight'
    'Message'
    'Message_color'
    'MessageFontWeight'
  )
  if(!$synchash.Notifications_Grid.items){
    $Global:Notfiytable = [hashtable]::Synchronized(@{})
    $Global:Notfiytable.datatable = New-Object System.Data.DataTable 
    [void]$Notfiytable.datatable.Columns.AddRange($Fields)
    if(!$id){
      $id = 1
    }
  }else{
    if(!$id){
      $id = $synchash.Notifications_Grid.items.id | select -last 1
      $id++
    }
  }
  if($thisApp.Config.Verbose_Logging){write-ezlogs ">>>> Updating Notifications table" -showtime -enablelogs}
  if($Notification_array)
  {
    foreach ($n in $Notification_array)
    {
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($n.id)
      $Null = $array.add($n.time)
      $Null = $array.add($n.level)
      $Null = $array.add($n.Message)
      [void]$Notfiytable.datatable.Rows.Add($array)
    } 
  }
  <#  if($Message){
      $Array = New-Object System.Collections.ArrayList
      $Null = $array.add($id)
      $Null = $array.add("[$(Get-Date -Format 'MM/dd/yyyy h:mm:ss tt'):]")
      $Null = $array.add($Level)
      $Null = $array.add($Message)
      $Null = $array.add($Message_color)
      $Null = $array.add($MessageFontWeight)
  }#>
  if($Level = 'ERROR'){
    $Level_color = 'Red'
  }elseif($Level = 'Warning'){
    $Level_color = 'Orange'
  }elseif($Level = 'INFO'){
    $Level_color = 'Cyan'
  }
  $itemssource = [pscustomobject]@{
    ID=$ID;
    Time="$(Get-Date -Format 'MM/dd/yyyy h:mm:ss tt')";
    Level=$Level;
    Level_color=$Level_color
    LevelFontWeight=$LevelFontWeight    
    Message=$Message
    Message_color=$Message_color
    MessageFontWeight=$MessageFontWeight
    
  }
  
  if($No_runspace){
    $syncHash.Notifications_Grid.Background = "Transparent"
    $syncHash.Notifications_Grid.AlternatingRowBackground = "Transparent"
    $syncHash.Notifications_Grid.CanUserReorderColumns = $false
    $syncHash.Notifications_Grid.CanUserDeleteRows = $true
    $synchash.Notifications_Grid.Foreground = "White"
    $syncHash.Notifications_Grid.RowBackground = "Transparent"
    $synchash.Notifications_Grid.HorizontalAlignment ="Left"
    $synchash.Notifications_Grid.CanUserAddRows = $False
    $synchash.Notifications_Grid.HorizontalContentAlignment = "left"
    $synchash.Notifications_Grid.IsReadOnly = $True
    $synchash.Notifications_Grid.HorizontalGridLinesBrush = "DarkGray"
    $synchash.Notifications_Grid.GridLinesVisibility = "Horizontal"
    try{  
      if($Clear){
        $null = $synchash.Notifications_Grid.Items.clear()
      }           
      if([int]$synchash.Notifications_Grid.items.count -lt 1){
        [int]$notifications = 1
      }else{
        [int]$notifications = [int]$synchash.Notifications_Grid.items.count + 1
      }
      [int]$synchash.Notifications_Badge.badge = [int]$notifications
             
      $null = $synchash.Notifications_Grid.Items.add($itemssource)
      if($Open_Flyout){
        $synchash.NotificationFlyout.isOpen=$true 
      }
    }catch{
      write-ezlogs "An exception occurred adding items to notifications grid" -showtime -catcherror $_
    } 
  }else{
    $synchash.Window.Dispatcher.invoke([action]{
        $syncHash.Notifications_Grid.Background = "Transparent"
        $syncHash.Notifications_Grid.AlternatingRowBackground = "Transparent"
        $syncHash.Notifications_Grid.CanUserReorderColumns = $false
        $syncHash.Notifications_Grid.CanUserDeleteRows = $true
        $synchash.Notifications_Grid.Foreground = "White"
        $syncHash.Notifications_Grid.RowBackground = "Transparent"
        $synchash.Notifications_Grid.HorizontalAlignment ="Left"
        $synchash.Notifications_Grid.CanUserAddRows = $False
        $synchash.Notifications_Grid.HorizontalContentAlignment = "left"
        $synchash.Notifications_Grid.IsReadOnly = $True
        $synchash.Notifications_Grid.HorizontalGridLinesBrush = "DarkGray"
        $synchash.Notifications_Grid.GridLinesVisibility = "Horizontal"
        try{  
          if($Clear){
            $null = $synchash.Notifications_Grid.Items.clear()
          }           
          if([int]$synchash.Notifications_Grid.items.count -lt 1){
            [int]$notifications = 1
          }else{
            [int]$notifications = [int]$synchash.Notifications_Grid.items.count + 1
          }
          [int]$synchash.Notifications_Badge.badge = [int]$notifications
             
          $null = $synchash.Notifications_Grid.Items.add($itemssource)
          if($Open_Flyout){
            $synchash.NotificationFlyout.isOpen=$true 
          }
        }catch{
          write-ezlogs "An exception occurred adding items to notifications grid" -showtime -catcherror $_
        }      

    },"Normal")
  }  
  
}
#---------------------------------------------- 
#endregion Update-Notifications Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-Notifications')
