<#
    .Name
    Get-EventHandlers

    .Version 
    0.1.0

    .SYNOPSIS
    Functions to retrieve and manage the life cycle of WPF event handlers

    .DESCRIPTION

    .Requirements
    - Powershell v3.0 or higher

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
#>

#---------------------------------------------- 
#region Get-EventHandlers
#----------------------------------------------
function Get-EventHandlers {
  <#
      .Name
      Get-EventHandlers

      .DESCRIPTION
      Uses reflection to retrieve hidden EventHandlersStore and GetRoutedEventHandlers to see if any event handlers of the provided routedevent type are registered to the provided UIElement. Includes option to remove found event handlers 

      .NOTES
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [PSObject] $Element,
    [Parameter(Mandatory = $true)]
    [System.Windows.RoutedEvent] $RoutedEvent,
    [switch]$RemoveHandlers,
    [switch]$VerboseLog
  )
  try{
    if($Element -is [System.Windows.UIElement] -or $Element -is [System.Windows.ContentElement]){
      $eventHandlersStoreProperty = $Element.GetType().GetProperty("EventHandlersStore", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
      if($eventHandlersStoreProperty){
        $eventHandlersStore = $eventHandlersStoreProperty.GetValue($Element, $null)
      }
      if ($eventHandlersStore) {
        $getRoutedEventHandlers = $eventHandlersStore.GetType().GetMethod("GetRoutedEventHandlers", [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
        $RoutedEventHandlers = [System.Windows.RoutedEventHandlerInfo[]]$getRoutedEventHandlers.Invoke($eventHandlersStore, $RoutedEvent)
        if($RemoveHandlers){
          foreach ($RoutedEventHandlerInfo in $RoutedEventHandlers) {
            if($VerboseLog){write-ezlogs ">>>> Removing routed event: $($RoutedEvent.name) - for element: $($Element) with name: $($Element.name)"}
            $Element.RemoveHandler($RoutedEvent,$RoutedEventHandlerInfo.Handler)
          }
          $RoutedEventHandlers = $Null
        }else{
          return [bool]($RoutedEventHandlers.Count -gt 0)
        }   
      } else {
        return $false
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Get-EventHandlers for element $($Element) with name $($Element.name) and routed event: $($RoutedEvent.name)"
  }
}
#----------------------------------------------
#endregion Get-EventHandlers
#----------------------------------------------
Export-ModuleMember -Function @('Get-EventHandlers')