<#
    .Name
    New-RelayCommand

    .Version 
    0.1.0

    .SYNOPSIS
    Creates a new Windows.Input.Icommand from provided scriptblock to be used in WPF control command bindings

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
#region New-RelayCommand Function
#----------------------------------------------
function New-RelayCommand
{
  Param (
    $synchash,
    $thisApp,
    $Scriptblock,
    $target,
    [switch]$Startup,
    [switch]$Verboselog = $thisApp.Config.Verbose_Logging
  )
  if($Startup){
    try{
      class RelayCommand : Windows.Input.ICommand {
        # canExecute runs automatically on click. Doesn't run when background task is finished.
        # requery with [System.Windows.Input.CommandManager]::InvalidateRequerySuggested() on ui thread dispatcher
        # on open, these add a requery event to each button and on close, remove the event

        add_CanExecuteChanged([EventHandler] $value) {
          #[System.Windows.Input.CommandManager]::add_RequerySuggested($value)
        }

        remove_CanExecuteChanged([EventHandler] $value) {
          #[System.Windows.Input.CommandManager]::remove_RequerySuggested($value)
        }

        hidden [ScriptBlock] $_execute
        hidden [ScriptBlock] $_canExecute
        hidden [Object] $_self

        #constructor

        RelayCommand(
          [object] $self,
          # [object] $self, [object] $commandParameter -> [void]
          [ScriptBlock] $execute,
          # [object] $this, $commandParameter -> [bool]
        [ScriptBlock] $canExecute) {
          if ($null -eq $self) {
            throw "The reference to the parent was not set, please provide it by passing `$this to the `$self parameter."
          }
          $this._self = $self

          $e = $execute.ToString().Trim()
          if ([string]::IsNullOrWhiteSpace($e)){
            throw "Execute script is `$null or whitespace, please provide a valid ScriptBlock."
          }
          $this._execute = [ScriptBlock]::Create("param(`$this, `$parameter)`n&{`n$e`n} `$this `$parameter")
          # Write-Verbose -Message "param(`$this)&{$e}" -Verbose
          # Backtick(`) prevents $this from evaluating to 'RelayCommand' in the scriptblock creation
          if($this.verboselog){
            write-ezlogs "Execute script $($this._execute)" -showtime
          }
          $ce = $canExecute.ToString().Trim()
          if ([string]::IsNullOrWhiteSpace($ce)){
            if($this.verboselog){write-ezlogs "Can execute script is empty" -showtime}
            $this._canExecute = $null
          }else {
            $this._canExecute = [ScriptBlock]::Create("param(`$this, `$parameter)`n&{`n$ce`n} `$this `$parameter")
          }
        }

        [bool] CanExecute([object] $parameter) {
          if ($null -eq $this._canExecute) {
            if($this.verboselog){write-ezlogs "Can execute script is empty so it can execute" -showtime}
            return $true
          } else {
            [bool] $result = $this._canExecute.Invoke($this._self, $parameter)
            if ($result) {
              if($this.verboselog){write-ezlogs "Can execute script was run and can execute" -showtime}
              #Write-Verbose -Message "Can execute script was run and can execute" -Verbose
            }else {
              if($this.verboselog){write-ezlogs "Can execute script was run and cannot execute" -showtime}
              #Write-Verbose -Message "Can execute script was run and cannot execute" -Verbose
            }
            return $result
          }
        }

        [void] Execute([object] $parameter) {
          if($this.verboselog){write-ezlogs "Executing script on RelayCommand against $($this._self)"}
          try {
            $this._execute.Invoke($this._self, $parameter)
            if($this.verboselog){Write-ezlogs "Script on RelayCommand executed" -showtime }
            #Write-Verbose "$($this._execute)" -Verbose
          }catch{
            write-ezlogs "Error handling execute:" -showtime -catcherror $_
          }
          #if ($parameter){Write-Verbose $parameter -Verbose}
          #$_execute must have '$parameter' inorder for commandparameter binding to be passed and executed
        }
      }
    }catch{
      write-ezlogs "An exception occurred creating class RelayCommand : Windows.Input.ICommand" -showtime -catcherror $_
    }
  }elseif($target -and $scriptblock){
    try{
      $relaycommand = [RelayCommand]::new($target, $Scriptblock,{})  
      return $relaycommand
    }catch{
      write-ezlogs "An exception occurred creating new RelayCommand for target $($target | out-string)" -showtime -catcherror $_
    }
  }  
}
#---------------------------------------------- 
#endregion New-RelayCommand Function
#----------------------------------------------
Export-ModuleMember -Function @('New-RelayCommand')