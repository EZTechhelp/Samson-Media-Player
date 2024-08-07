# this is a Pester test file

#region Further Reading
# http://www.powershellmagazine.com/2014/03/27/testing-your-powershell-scripts-with-pester-assertions-and-more/
#endregion
#region LoadScript
# load the script file into memory
# attention: make sure the script only contains function definitions
# and no active code. The entire script will be executed to load
# all functions into memory
Import-Module ($PSCommandPath -replace '\.tests\.ps1$', '.psm1')

#endregion

# describes the function Initialize-XAML
Describe 'Initialize-XAML' {

  # scenario 1: call the function with arguments
  Context 'Running with arguments'   {
    # test 1: it does not throw an exception:
    It 'runs without errors' {
      # Gotcha: to use the "Should Not Throw" assertion,
      # make sure you place the command in a 
      # scriptblock (braces):
      { Initialize-XAML -Current_folder 'C:\Users\DopaDodge\OneDrive - EZTechhelp Company\Development\Repositories\EZT-MediaPlayer-Samson' -thisApp $thisApp -synchash $synchash } | Should -Not -Throw
    }
    # Test 2: It should return an expected object type
    It 'does something' {
      #call function Initialize-XAML and pipe the result to an assertion
      Initialize-XAML -Current_folder 'C:\Users\DopaDodge\OneDrive - EZTechhelp Company\Development\Repositories\EZT-MediaPlayer-Samson' -thisApp $thisApp -synchash $synchash | Should -ExpectedType System.Collections.Hashtable
    }

  }
  #scenario 2: call the function without arguments
  Context 'Running without agruments' {
     # Test 3: It should return null
     It 'does not return anything'     {
      Initialize-XAML | Should -BeNullOrEmpty
    } 
  }
}
