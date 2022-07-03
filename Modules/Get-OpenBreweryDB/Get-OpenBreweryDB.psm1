<#
    .Name
    Get-OpenBreweryDb

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves data from OpenBreweryDB API

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
#region Get-OpenBreweryDB Function
#----------------------------------------------
function Get-OpenBreweryDB
{
  Param (
    $thisApp,
    $synchash,
    [string]$search_query,
    [string]$City,
    [string]$Zip,
    [string]$State,
    [string]$Brewery_Name,
    [ValidateSet('micro','nano','regional','brewpub','large','planning','bar','contract','proprietor','closed')]
    [string]$Brewery_Type,
    [ValidateSet('asc','desc')]
    [string]$Sort = 'desc',
    [switch]$Get_Random,
    [string]$distance,
    [switch]$Verboselog
  )
  Add-Type -AssemblyName System.Web
  if($Verboselog){write-ezlogs "#### Checking Open Brewery DB ####" -enablelogs -color yellow -linesbefore 1}
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $OpenBreweryDB_API_Info_File = "$($thisApp.config.Current_Folder)\Resources\API\OpenBreweryDB-API-Config.xml"
  if(([System.IO.File]::Exists($OpenBreweryDB_API_Info_File))){
    write-ezlogs ">>>> Importing Twitch API Config file $OpenBreweryDB_API_Info_File" -showtime -color cyan
    $OpenBreweryDB_Api_Config = Import-Clixml $OpenBreweryDB_API_Info_File
 
  }else{

  }
  
  if($OpenBreweryDB_Api_Config){
    #Get twitch streamers
    try{
      $ipinfo = Invoke-RestMethod -Uri ('https://ipinfo.io/')
    }catch{
      write-ezlogs "An exception occurred getting current public ip info" -showtime -catcherror $_
    }
    if($ipinfo.ip){
      $city = $ipinfo.city
      $state = $ipinfo.region
      $zip = $ipinfo.postal
      $distance = $ipinfo.loc
    }
    $brew_url = $OpenBreweryDB_Api_Config.Auth_URLs
    if($search_query){
      $brew_url += '/search?query={0}&per_page=50' -f $([System.Web.HttpUtility]::UrlEncode($search_query))
    }else{
      $brew_url = $brew_url + '?per_page=50'
    }
    if($distance){
      $brew_url += '&by_dist={0}' -f $([System.Web.HttpUtility]::UrlEncode($distance))
    }
    switch ($MyInvocation.BoundParameters.Keys) {
      'City' {
        $brew_url += '&by_city={0}' -f $([System.Web.HttpUtility]::UrlEncode($city))
      }
      'Zip' {
        $brew_url += '&by_postal={0}' -f $([System.Web.HttpUtility]::UrlEncode($zip))
      }
      'State' {
        $brew_url += '&by_State={0}' -f $([System.Web.HttpUtility]::UrlEncode($State))
      }
      'Brewery_Name' {
        $brew_url += '&by_name={0}' -f $([System.Web.HttpUtility]::UrlEncode($Brewery_Name))
      }
      'Brewery_Type' {
        $brew_url += '&by_type={0}' -f $([System.Web.HttpUtility]::UrlEncode($Brewery_Type))
      }
      'Sort' {
        $brew_url += '&sort=type,name:{0}' -f $([System.Web.HttpUtility]::UrlEncode($sort))
      }

    }   

    $brewery = Invoke-RestMethod $brew_url -Method 'Get'
   
    if($brewery){
      $encodedTitle = $Null  
      [xml]$XamlBrewWindow_window = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\\Views\\BrewWindow.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
      $Childreader = (New-Object System.Xml.XmlNodeReader $XamlBrewWindow_window)
      $synchash.BrewWindow   = [Windows.Markup.XamlReader]::Load($Childreader) 
      $XamlBrewWindow_window.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $synchash.BrewWindow.FindName($_.Name)}
      $synchash.BrewWindow.AllowMove = $true      
      if($synchash.RootGrid.children -notcontains $synchash.BrewWindow){
        $null = $synchash.RootGrid.addchild($synchash.BrewWindow)
      }

      #$synchash.MainGrid_Background_Image_Source_transition.content = $synchash.BrewWindow
      #$synchash.BrewWindow.SetValue([System.Windows.Controls.Grid]::RowSpanProperty,4)
      #$synchash.BrewWindow.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty,5)
      $synchash.BrewWindow.Background = $synchash.Audio_Flyout.Background
      $synchash.BrewWindow.ChildWindowImage = 'Information'
      #$synchash.BrewBackground_Image.Source = $syncHash.MainGrid_Background_Image_Source.Source
      $synchash.BrewBackground_Image.Stretch = "UniformToFill"
      $titlebar =  $synchash.Window.TryFindResource('MahApps.Brushes.Accent') 
      if($titlebar){
        $synchash.BrewWindow.TitleBarBackground = $titlebar
      }   
      #$synchash.BrewWindow.HorizontalAlignment = 'Center'
      $synchash.BrewWindow.title = "You look like you need a beer. Here are some Breweries within 50 miles from you!"
      $synchash.BrewWindow.ShowCloseButton = $true
      if($synchash.Window.GlowBrush){
        $synchash.BrewWindow.GlowBrush = $synchash.Window.GlowBrush
      }
      #write-ezlogs "$($synchash.BrewWindow | out-string)"
      #$synchash.BrewWindow.VerticalAlignment = 'Center'
      if($null = $synchash.Brew_Grid.Items){
        $null = $synchash.Brew_Grid.Items.clear()
      }  

      $linkColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $textFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.TextBlock])
      $Binding = New-Object System.Windows.Data.Binding
      #$Relativesource = New-Object System.Windows.Data.RelativeSource
      #$Relativesource.AncestorType = [System.Windows.Controls.DataGridRow]
      #$Binding.Source = $synchash.MediaTable.SelectedItem
      #$Binding.RelativeSource = $Relativesource
      $Binding.Path = "Website"
      $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
      #$link_hyperlink.SetBinding([System.Windows.Documents.Hyperlink]::NavigateUriProperty,$binding)
      $textFactory.SetValue([System.Windows.Controls.TextBlock]::TextProperty,$binding)
      #$textFactory.SetValue([System.Windows.Controls.TextBlock]::ForegroundProperty,$synchash.Window.TryFindResource("MahApps.Brushes.IdealForeground"))
      $linkCommand = [Windows.Input.MouseButtonEventHandler]{
        param($Sender)
        try{
          [uri]$uri = $sender.text
          write-ezlogs "Navigation to $($uri)" -showtime
          if(test-url $uri){
            write-ezlogs "Navigation to $($uri)" -showtime
            start $uri
          }else{
            write-ezlogs "No valid path/URL provided! Sender: $($sender | out-string)" -showtime -warning
          }
        }catch{
          write-ezlogs "An exception occurred in Hyperlink_RequestNavigate" -showtime -catcherror $_
        }
      }  
      $textFactory.AddHandler([System.Windows.Controls.TextBlock]::PreviewMouseLeftButtonDownEvent,$linkCommand)
      $TextDecorations = [System.Windows.Controls.TextBlock]::new()
      $TextDecorations.TextDecorations = 'Underline'
      $TextDecorations.Cursor = [System.Windows.Input.Cursors]::Hand
      $textFactory.SetValue([System.Windows.Controls.TextBlock]::TextDecorationsProperty,$TextDecorations.TextDecorations)
      $textFactory.SetValue([System.Windows.Controls.TextBlock]::ForceCursorProperty,$true)
      $textFactory.SetValue([System.Windows.Controls.TextBlock]::CursorProperty,$TextDecorations.Cursor)
      $textFactory.SetValue([System.Windows.Controls.TextBlock]::StyleProperty,$synchash.Window.TryFindResource("HyperlinkStyle"))  
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $textFactory
      $linkColumn.CellTemplate = $dataTemplate
      $linkColumn.Header = "Website"
      #$null = [System.Windows.Data.BindingOperations]::SetBinding($buttonFactory,[Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty, $Binding)

      $null = $synchash.Brew_Grid.Columns.add($linkColumn)


      foreach($brew in $brewery){
        #$Null = $synchash.Hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$synchash.Hyperlink_RequestNavigate)
        #write-ezlogs ">>>> Found Brewery $($brew.name)" -showtime -color Cyan
        #write-ezlogs " | Type $($brew.brewery_type)" -showtime
        #$hyperlink = $synchash.Brew_Grid.TryFindResource('Hyperlink')
        #write-ezlogs " | hyperlink $($hyperlink)" -showtime  
        $itemssource = New-Object PsObject -Property @{
          'ID' = $brew.id
          'Name' = $brew.name
          'Name_color' = 'White'
          'NameFontWeight' = 'Bold'
          'street_color' = 'White'
          'city_color' = 'White'
          'state_color' = 'White'
          'Phone_color' = 'White'
          'Type' = $brew.brewery_type
          'Street' = $brew.street
          'City' = $brew.city
          'State' = $($brew.state)
          'postal_code' = $($brew.postal_code)
          'Phone' = $brew.phone
          'Website' = $brew.website_url
        }  
        $null = $synchash.Brew_Grid.Items.add($itemssource)   
      }
      $synchash.BrewWindow.isOpen = $true   
      $synchash.RootGrid.updatelayout() 
      $synchash.BrewWindow.UpdateLayout()         
      #$null = $Available_Spotify_Media.Add($newRow)           
    }else{
      write-ezlogs "Unable to get brewery" -showtime -enablelogs -warning
    }    
  }else{
    write-ezlogs "Unable to get API configuration, cannot continue" -showtime -warning
    return
  }
}
#---------------------------------------------- 
#endregion Get-OpenBreweryDB Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-OpenBreweryDB')