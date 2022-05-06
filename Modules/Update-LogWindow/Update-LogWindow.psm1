<#
    .Name
    Update-LogWindow

    .Version 
    0.1.0

    .SYNOPSIS
    Updates richtextbox for log window control  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-GameManager

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Update-LogWindow Function
#----------------------------------------------
function Update-LogWindow 
{  
  #https://msdn.microsoft.com/en-us/library/system.windows.documents.textelement(v=vs.110).aspx#Propertiesshut
  [CmdletBinding(DefaultParameterSetName = 'content')]  
  param (   
    $synchash,
    $thisapp,
    [System.Windows.Controls.RichTextBox]$RichTextBoxControl = $synchash.LogWindow,  
    $commonParams,
    [String]$Content,
    $Control,
    $Property,
    [switch]$enablelogs = $enablelogs,  
    [String]$Color = 'White',
    [switch]$Warning,  
    [String]$BackGroundColor = 'black',  
    [String]$FontSize = '12',  
    [String]$FontStyle = 'Normal',  
    [String]$FontWeight = 'Normal',
    [Switch]$linebefore,
    [Switch]$lineafter,
    [Switch]$AppendContent,
    [switch]$showtime,
    [string]$logfile = $thisApp.Config.Log_file,
    [switch]$norunspace 
  )

  #This is kind of a hack, there may be a better way to do this
  If ($Property -eq "Close") 
  {
    $synchash.Window.Dispatcher.invoke([action]{$synchash.Window.Close()},"Normal")
    Return
  }
  if($Warning)
  {
    $color = "orange"
    $content = "[WARNING] $Content"
  }

  if($norunspace)
  {      
    $ParamOption = @{ForeGroundColor=$Color;BackGroundColor=$BackGroundColor;FontSize=$FontSize; FontStyle=$FontStyle; FontWeight=$FontWeight}     
    #if using linebefore, add an extra line break before the content      
    if ($linebefore)      
    {        
      $Content = "`n$Content"  
    }
        
    #if using lineafter, add an extra line break after the content        
    if ($lineafter)        
    {         
      $Content = "$Content`n"        
    }  
        
    #if we want to show time, add date time in front of content. Then count the number of characters of content after showtime to get position info for later calculation
        
    if ($showtime)       
    {         
      $content1 = "[$(Get-Date -Format $logdateformat):] "         
      $content2 = $content          
      $Contentfinal = "$content1$content2"          
      $content2count = $content2.ToCharArray().count + 2        
    }        
    else        
    {          
      $Contentfinal = $content          
      $content2count = $Contentfinal.ToCharArray().count + 2        
    }
    #post the content and set the default foreground color
    $RichTextRange = New-Object System.Windows.Documents.Run($Contentfinal)
    $RichTextRange.Foreground = "white"
    $RichTextRange.FontWeight = "Normal"
    $Paragraph = New-Object System.Windows.Documents.Paragraph($RichTextRange)
    $null = $synchash.LogWindow.Document.Blocks.Add($Paragraph)
    #Output content to logfile if enabled
    if ($enablelogs)
    {
      $RichTextRange.Text | Out-File -FilePath $logfile -Encoding unicode -Append
    }
    #select only the content we want to manipulate using the positional info calculated previously
    $RichTextRange2 = New-Object System.Windows.Documents.textrange($synchash.LogWindow.Document.Contentend.GetPositionAtOffset(-$content2count), $synchash.LogWindow.Document.ContentEnd.GetPositionAtOffset(-1))
    #if a foreground color is specified, set the paramter foregroundcolor to the specified value
    if($color)
    {
      #$ParamOption = @{ForeGroundColor=$foregroundcolor}
      $Defaults = @{ForeGroundColor=$color}
      foreach ($Key in $Defaults.Keys) {  
        if ($ParamOption.Keys -notcontains $Key) {  
          $null = $ParamOption.Add($Key, $Defaults[$Key]) 
        } 
      }
    }
    if($FontWeight)
    {  
      #$ParamOption = @{ForeGroundColor="White"; FontSize="18"}
      $Defaults = @{FontWeight=$FontWeight}
      $default_keys = $Defaults.Keys
      foreach ($Key in $default_keys) {  
        if ($ParamOption.Keys -notcontains $Key) {  
          $null = $ParamOption.Add($Key, $Defaults[$Key]) 
        } 
      }
      #$ParamOption = @{FontWeight=$FontWeight}
    }
    $paramOption_keys = $ParamOption.keys
    #Select all the parameters, create the textelement property it applies to and then apply the property value to our previously selected text
    foreach ($param in $paramOption_keys)
    {
      $SelectedParam = $param  
      if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}  
      elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}  
      elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}  
      elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}  
      elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
      $script:logmessage = $RichTextRange2.ApplyPropertyValue($TextElement, $ParamOption[$SelectedParam]) 
    }
    $synchash.logwindow.ScrollToEnd()
  }
  else
  {
    $synchash.LogWindow.Dispatcher.Invoke([action]{
        $ParamOption = @{ForeGroundColor=$Color;BackGroundColor=$BackGroundColor;FontSize=$FontSize; FontStyle=$FontStyle; FontWeight=$FontWeight}
        #if using linebefore, add an extra line break before the content
        if ($linebefore) 
        {
          $Content = "`n$Content"  
        }
        #if using lineafter, add an extra line break after the content
        if ($lineafter)
        {
          $Content = "$Content`n"
        }  
        #if we want to show time, add date time in front of content. Then count the number of characters of content after showtime to get position info for later calculation
        if ($showtime)
        {
          $content1 = "[$(Get-Date -Format $logdateformat):] "
          $content2 = $content
          $Contentfinal = "$content1$content2"
          $content2count = $content2.ToCharArray().count + 2
        }
        else
        {
          $Contentfinal = $content
          $content2count = $Contentfinal.ToCharArray().count + 2
        }
        #post the content and set the default foreground color
        $RichTextRange = New-Object System.Windows.Documents.Run($Contentfinal)
        $RichTextRange.Foreground = "white"
        $RichTextRange.FontWeight = "Normal"
        $Paragraph = New-Object System.Windows.Documents.Paragraph($RichTextRange)
        $null = $synchash.LogWindow.Document.Blocks.Add($Paragraph)
        #Output content to logfile if enabled
        if ($enablelogs)
        {
          $RichTextRange.Text | Out-File -FilePath $thisApp.Config.Log_file -Encoding unicode -Append
        }
        #select only the content we want to manipulate using the positional info calculated previously
        $RichTextRange2 = New-Object System.Windows.Documents.textrange($synchash.LogWindow.Document.Contentend.GetPositionAtOffset(-$content2count), $synchash.LogWindow.Document.ContentEnd.GetPositionAtOffset(-1))

        #if a foreground color is specified, set the paramter foregroundcolor to the specified value
        if($color)
        {
          #$ParamOption = @{ForeGroundColor=$foregroundcolor}
          $Defaults = @{ForeGroundColor=$color}
          foreach ($Key in $Defaults.Keys) {  
            if ($ParamOption.Keys -notcontains $Key) {  
              $null = $ParamOption.Add($Key, $Defaults[$Key]) 
            } 
          }
        }
        if($FontWeight)
        {  
          #$ParamOption = @{ForeGroundColor="White"; FontSize="18"}
          $Defaults = @{FontWeight=$FontWeight}
          $default_keys = $Defaults.Keys
          foreach ($Key in $default_keys) {  
            if ($ParamOption.Keys -notcontains $Key) {  
              $null = $ParamOption.Add($Key, $Defaults[$Key]) 
            } 
          }
          #$ParamOption = @{FontWeight=$FontWeight}
        }
        $paramOption_keys = $ParamOption.keys
      
        #Select all the parameters, create the textelement property it applies to and then apply the property value to our previously selected text
        foreach ($param in $paramOption_keys)
        {
          $SelectedParam = $param  
          if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}  
          elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}  
          elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}  
          elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}  
          elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
          $RichTextRange2.ApplyPropertyValue($TextElement, $ParamOption[$SelectedParam]) 
        }
        $synchash.logwindow.ScrollToEnd()
      },
    "Normal")  
  }
}
#---------------------------------------------- 
#endregion Update-LogWindow Function
#----------------------------------------------
#---------------------------------------------- 
#region Update-HelpFlyout Function
#----------------------------------------------
function Update-HelpFlyout
{  
  #https://msdn.microsoft.com/en-us/library/system.windows.documents.textelement(v=vs.110).aspx#Propertiesshut
  [CmdletBinding(DefaultParameterSetName = 'content')]  
  param (   
    [System.Windows.Controls.RichTextBox]$RichTextBoxControl,  
    $commonParams,
    $synchash,
    $thisApp,
    [String]$Content,
    $Control,
    $Property,
    $GameName,
    $Platform,
    $Platform_Profile_Path,
    $Game_install_path,
    $Valid_Configpaths,
    $Global_Profile_Path,
    [switch]$enablelogs = $false,  
    [String]$Color = 'White',
    [switch]$Warning,
    [switch]$Separator, 
    [string]$TextDecorations,
    [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]  
    [String]$BackGroundColor = 'transparent',  
    [String]$FontSize = '14',  
    [String]$FontStyle = 'Normal',  
    [String]$FontWeight = 'Normal',
    [Switch]$linebefore,
    [Switch]$lineafter,
    [Switch]$AppendContent,
    [switch]$showtime,
    [string]$customdateformat,
    [string]$custom_showtime,
    [string]$logfile = $thisApp.config.Log_File,
    [switch]$norunspace, 
    [switch]$Verboselog
  )
 
  #This is kind of a hack, there may be a better way to do this
  If ($Property -eq "Close") 
  {
    $synchash.Window.Dispatcher.invoke([action]{$synchash.Window.Close()},"Normal")
    Return
  }
  if($Warning)
  {
    $color = "orange"
    $content = "[WARNING] $Content"
  }
  $pattern_strong = '<strong>(?<value>.*)</strong>'
  $pattern_code = '<code>(?<value>.*)</code>'
  if($thisApp.config){
    $image_cache_dir = [System.IO.Path]::Combine(($thisApp.config.Media_Profile_Directory | split-path -parent),"Images")
  }
  if($norunspace)
  {      
    $ParamOption = @{ForeGroundColor=$Color;BackGroundColor=$BackGroundColor;FontSize=$FontSize; FontStyle=$FontStyle; FontWeight=$FontWeight}

    #if using linebefore, add an extra line break before the content
    if ($linebefore) 
    {
      $Content = "`n$Content"  
    }
    if ($Separator)        
    {         
      $horz_line = "`n────────────────────────────`n"
      $Content = "$Content$horz_line"        
    }        
    #if using lineafter, add an extra line break after the content
    if ($lineafter)
    {
      $Content = "$Content`n"
    }  
    #if we want to show time, add date time in front of content. Then count the number of characters of content after showtime to get position info for later calculation
    if ($showtime)       
    {         
      if($custom_showtime){
        if($customdateformat){
          $content1 = "[$(Get-Date $custom_showtime -Format $customdateformat):] "
        }else{
          $content1 = "[$(Get-Date $custom_showtime)] : "
        }  
      }else{
        $content1 = "[$(Get-Date -Format $logdateformat)] : "
      }        
      $content2 = $content          
      $Contentfinal = "$content1$content2"          
      $content2count = $content2.ToCharArray().count + 2        
    }
    else
    {
      $Contentfinal = $content
      $content2count = $Contentfinal.ToCharArray().count + 2
    }
    $RichTextRange = New-Object System.Windows.Documents.Run               
    $RichTextRange.Foreground = $color
    $RichTextRange.FontWeight = $FontWeight
    $RichTextRange.FontSize = $FontSize
    $RichTextRange.Background = $BackGroundColor
    $RichTextRange.TextDecorations = $TextDecorations
    [System.Windows.RoutedEventHandler]$Hyperlink_RequestNavigate = {
      param ($sender,$e)
      $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
      if($sender.NavigateUri.ToString() -match $url_fullpattern){
        $path = $sender.NavigateUri.ToString()
      }else{
        $path = (resolve-path $($sender.NavigateUri.ToString() -replace 'file:///','')).Path
      }     
      write-ezlogs "Navigation to $($path)" -showtime
      if($path){
        start $($path)
      }
    }
    #write-ezlogs "Before####$Contentfinal"
    if($contentfinal -match '</br>' -or $Contentfinal -match '<br />' -or $Contentfinal -match '<br>' -or $Contentfinal -match '<p>' -or $Contentfinal -match '</p>' -or $ContentFinal -match 'br>' -or $Contentfinal -match '<li>' -or $Contentfinal -match '</li>' -or $Contentfinal -match '<ul>' -or $Contentfinal -match '</ul>' -or $Contentfinal -match '</ol>' -or $Contentfinal -match '<u>' -or $Contentfinal -match '</u>'){
      $contentfinal = $($($contentfinal) -replace '<br />',"" -replace '<br>',"`n" -replace '<p>',"`n" -replace 'br>',"`n" -replace '<li>',"`n  • " -replace '<ul>','' -replace '<ol>','' -replace '</ul>','' -replace '</li>','' -replace '</ol>','' -replace '<ul class="bb_ul">','' -replace '<u>','' -replace '</u>','').trim()
    }  
      
    if($contentfinal -match "`n`n"){
      $contentfinal = ($contentfinal -replace "`n`n","`n").trim()
    }
    if($contentfinal -match '&quot;'){
      $contentfinal = ($contentfinal -replace '&quot;','"').trim()
    }
    if($contentfinal -match '&amp;'){
      $contentfinal = ($contentfinal -replace '&amp;','&').trim()
    }
    if($contentfinal -match '\[\[Glossary\:Command line'){
      $contentfinal = ($contentfinal -replace '\[\[Glossary:Command line','https://www.pcgamingwiki.com/wiki/Glossary:Command_line_arguments').trim()
    }  
    if($Valid_Configpaths -and $contentfinal -match '\#Game dataconfiguration file\(s\) location'){
      
      $contentfinal = ($contentfinal -replace '\#Game dataconfiguration file\(s\) location',"https://localconfigpath/$($Valid_Configpaths | select -first 1)" -replace '\[\[','' -replace '\]\]','').trim()
    }     
    if($Game_install_path -and $contentfinal -match [regex]::Escape($Game_install_path)){
      
      $contentfinal = ($contentfinal -replace [regex]::Escape($Game_install_path),"https://localgamepath/$($Game_install_path)" -replace '\[\[','' -replace '\]\]','').trim()
    } 
    if($contentfinal -match [regex]::Escape($env:userprofile)){
      
      $contentfinal = ($contentfinal -replace [regex]::Escape($env:userprofile),"https://localgamepath/$($env:userprofile)" -replace '\[\[','' -replace '\]\]','').trim()
    } 
    if($contentfinal -match [regex]::Escape($env:appdata)){
      
      $contentfinal = ($contentfinal -replace [regex]::Escape($env:appdata),"https://localgamepath/$($env:appdata)" -replace '\[\[','' -replace '\]\]','').trim()
    } 
    if($contentfinal -match [regex]::Escape($env:localappdata)){
      
      $contentfinal = ($contentfinal -replace [regex]::Escape($env:localappdata),"https://localgamepath/$($env:localappdata)" -replace '\[\[','' -replace '\]\]','').trim()
    }         
    $env:appdata
    if($contentfinal -match 'cndate='){
      $contentfinal = $($contentfinal -replace 'cndate=',' Date: ')
    }       
    $localpath_pattern = '(([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()'       
    $contentfinal = $contentfinal.trim()
    $url_fullpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
 
    #write-ezlogs ">>>> To Post: $Contentfinal" 
    if($Contentfinal -match 'href='){
      $titlepattern = " title=`"(?<value>.*)`""  
      $titlecode = ([regex]::matches($Contentfinal, $titlepattern) | %{$_.groups[0].value} )
      #write-ezlogs "Titlecode $titlecode"
      foreach($code in $titlecode){
        $contentfinal = $Contentfinal -replace $code,''
      }
      #write-ezlogs "Contentfinal $contentfinal"
      $urlpattern = "<a href=`"(?<value>.*)`">"
      #write-ezlogs "#####$Contentfinal"
      #$links2 = $([regex]::matches($Contentfinal, $urlpattern) | %{$_.groups[0].value})
      $links2 = $([regex]::matches($Contentfinal, $url_fullpattern) | %{$_.groups[0].value})
      #write-ezlogs ">>>>$links2"
      $fullurls = New-Object System.Collections.ArrayList
      if(!$links2){   
        $fullurls =  $([regex]::matches($Contentfinal, '<a href="(?<value>.*)</a>') | %{$_.groups[0].value})
        $links = $([regex]::matches($fullurls, "`"(?<value>.*)`/`"") | %{$_.groups[1].value}) 
        $fullurls = $fullurls -replace "`n", ''
      }else{       
        foreach($link in $links2){
          $url1pattern = "$([regex]::Escape($link))(?<value>.*)</a>"
          $fullurl = ([regex]::matches($Contentfinal, $url1pattern) | %{$_.groups[0].value} )
          if(($fullurl).count -gt 1){
            $fullurl = ([regex]::matches($fullurl, $([regex]::Escape($link))) | %{$_.groups[0].value} )
          }
          if(!$fullurl){
            $fullurl = ([regex]::matches($contentfinal, "(?<value>.*)$([regex]::Escape($link))(?<value>.*)/>") | %{$_.groups[0].value} ) 
          }
          if(-not [string]::IsNullOrEmpty($fullurl)){
            $fullurls.add($fullurl)
          }
        }  
      }      
      $Paragraph = New-Object System.Windows.Documents.Paragraph
      foreach($l in $fullurls | where {-not [string]::IsNullOrEmpty($_)}){
        if($links){
          $hyperlink = $([regex]::matches($l, "`"(?<value>.*)`/`"") | %{$_.groups[1].value})
          $fullurlname = ([regex]::matches($l, "$($hyperlink)(?<value>.*)>(?<value>.*)</a>") | %{$_.groups[1].value})        
        }else{
          $hyperlink = ([regex]::matches($l, "<a href=`"(?<value>.*)`">") | %{$_.groups[1].value} ) | select -first 1
          if(!$hyperlink){
            $hyperlink = $([regex]::matches($l, $url_fullpattern) | %{$_.groups[0].value}) | select -first 1 
          }         
          $url1pattern = "$([regex]::Escape($hyperlink))`">(?<value>.*)</a>"
          $fullurlname = ([regex]::matches($l, $url1pattern) | %{$_.groups[1].value} )     
          if(!$fullurlname){
            $fullurlname = ([regex]::matches($l, "(?<value>.*)>(?<value>.*)</a>") | %{$_.groups[1].value} )  
          }     
        }
        if(!$fullurlname){
          $fullurlname = $hyperlink
        }
        write-ezlogs ">>>Hyperlink $hyperlink"
        $link_hyperlink = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink.NavigateUri = $hyperlink
        $link_hyperlink.ToolTip = "$hyperlink"
        $link_hyperlink.Foreground = "LightGreen"
        #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
        $Null = $link_hyperlink.Inlines.add("$fullurlname")
        $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)
        #write-ezlogs "####Bef $Contentfinal"
        $Contentfinal = ($Contentfinal -replace [regex]::Escape($l),"$l------SPLITME------")
        $Contentfinal = ($Contentfinal -split '------SPLITME------')
        #$Contentfinal = $Contentfinal.trim()   
        foreach($content in $Contentfinal){
          if($content -match [regex]::Escape($l) -and -not [string]::IsNullOrEmpty($content)){           
            $content = $($content -replace [regex]::Escape($l),' ')
            #write-ezlogs "Content: $($content | out-string)"
            $RichTextRange = New-Object System.Windows.Documents.Run               
            $RichTextRange.Foreground = $color
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations
            $RichTextRange.AddText($content)
            $Paragraph.Inlines.add($RichTextRange)
            if($hyperlink -match '.jpg' -or $hyperlink -match '.jpeg' -or $hyperlink -match '.png' -or $hyperlink -match '.gif'){
              #$uri = new-object system.uri($link)
              $uri_imagelink_pattern = "(?<value>.*)\?t"
              if($hyperlink -match '\?t='){
                $uri = $([regex]::matches($hyperlink, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
              }else{
                $uri = new-object system.uri($hyperlink)
              }              
              #$uri = $([regex]::matches($hyperlink, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
              if(!([System.IO.Directory]::Exists($image_cache_dir))){
                $null = New-item $image_cache_dir -ItemType directory -Force
              }
              if($uri -match "https://store-images.s-microsoft.com/image/apps"){
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf).png")
              }else{
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf)")
              }      
              if(!([System.IO.File]::Exists($image_Cache_path))){
                #$null =  (New-Object System.Net.WebClient).DownloadFileAsync($uri,$image_Cache_path)
                (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path)
                if($verboselog){write-ezlogs "Caching image $uri to $image_Cache_path" -enablelogs -showtime}
                $ImageURL = $image_Cache_path
                $image_Decoded_Image_file = $Null        
              }else{
                if($verboselog){write-ezlogs "Found Cached image at $image_Cache_path" -enablelogs -showtime}
                $ImageURL = $image_Cache_path
                $image_Decoded_Image_file = "$ImageURL"
              }          
              $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer  
              $Floater = New-Object System.Windows.Documents.Floater
              $Floater.HorizontalAlignment = "Center" 
              $Floater.Name = "Media_Floater"
              if($ImageURL -match '.gif'){ 
                $Media_Element = New-object System.Windows.Controls.MediaElement 
                $media_element.UnloadedBehavior = 'Close'  
                $media_element.Name = 'Gif_Player'
                $Media_Element.Source = $ImageURL
                $Media_Element.Width = '600'
                $Media_Element.Stretch = "UniformToFill"
                $Media_Element.LoadedBehavior="Manual" 
                $Media_Element.Play()
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($gamename)-$($ImageURL)")
                $encodeduid = [System.Convert]::ToBase64String($encodedBytes)
                $media_element.Uid =  "Media_$encodeduid"
                $Media_Element.tag = @{
                  synchash=$synchash;
                  thisApp=$thisApp
                  gamename=$gamename
                }
                $Media_element.Add_MediaEnded({   
                    param($Sender) 
                    $synchash = $Sender.tag.synchash
                    $gamename = $Sender.tag.gamename  
                    if($synchash.Window.IsVisible -and $syncHash.Window.Title -notmatch 'Now Playing' -and $syncHash.Window.WindowState -ne 'Minimized'){
                      $this.Position = [Timespan]::FromMilliseconds(1)  
                    }else{
                      $this.Stop()
                      $this.tag = $Null
                      $this.close()
                    }
                    #$this.LoadedBehavior = 'Manual'
                    #$this.Play()
                })    
                $media_element.add_MediaFailed({
                    param($Sender) 
                    $synchash = $Sender.tag.synchash
                    $gamename = $Sender.tag.gamename
                    write-ezlogs "An exception occurred in medial element $($sender | out-string)" -showtime -warning
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()                   
                })                    
                #$synchash.Gif_player = $Media_Element
                $BlockUIContainer.AddChild($Media_Element) 
              }else{
                $imagecontrol = New-Object System.Windows.Controls.Image
                $image = new-object System.Windows.Media.Imaging.BitmapImage 
                $stream_image = [System.IO.File]::OpenRead($ImageURL)
                $image.BeginInit();
                $image.CacheOption = "OnLoad"
                $image.StreamSource = $stream_image;
                #$image.UriSource = $ImageURL
                $image.DecodePixelWidth = '600' 
                $image.EndInit();    
                $image.Freeze();             
                #$imagecontrol.Source = $ImageURL
                $imagecontrol.Source = $image
                $imagecontrol.Width = "600"
                $imagecontrol.Stretch = "UniformToFill"
                $BlockUIContainer.AddChild($imagecontrol)                 
              }   
              $floater.AddChild($BlockUIContainer)
              $Paragraph.Inlines.Add($floater)
            }else{
              $Paragraph.Inlines.add($link_hyperlink)
            }           
          }elseif($content -match [regex]::Escape('<img src="')){
            $content = $($content -replace [regex]::Escape('<img src="'),'' -replace '"/>',"`n" -replace '"','')
            #write-ezlogs "#### img Code match: $Content" 
            $RichTextRange = New-Object System.Windows.Documents.Run 
            $RichTextRange.Foreground = $color
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations
            $RichTextRange.AddText($content)
            #$Paragraph.Inlines.add($RichTextRange)
          }elseif($Content -match $pattern_code){                 
            #write-ezlogs "#####Sections $sections"
            $pattern1 = '<code>(?<value>.*)'
            $code_split = ($($Content) -split '<\/code>')
            foreach ($split in $code_split){
              $codetext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
              if($codetext_match){
                [array]$codetext += $codetext_match
              }
            }                
            $sections = ($($code_split) -split $pattern1)     
            #write-ezlogs ">>>>Bolded $boldedtext"           
            foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){
              $section = ($section).replace('					 ',"`n").replace('  ',' ')
              #write-ezlogs "---Section $section"      
              if($codetext -contains $section){
                $RichTextRange = New-Object System.Windows.Documents.Run              
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.Foreground = 'White' 
                $RichTextRange.FontFamily = 'Courier New'
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = 'Black'
                $RichTextRange.TextDecorations = $TextDecorations           
                $RichTextRange.AddText("$section")
              }else{
                $RichTextRange = New-Object System.Windows.Documents.Run
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.Foreground = $color 
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = $BackGroundColor
                $RichTextRange.TextDecorations = $TextDecorations            
                $RichTextRange.AddText($section)
              }
              $Paragraph.Inlines.add($RichTextRange)
            }                   
          }else{
            $content = $($content -replace [regex]::Escape($l),' ' -replace '"/>','' -replace '"','')
            #write-ezlogs "no match $Content"
            $RichTextRange.Foreground = $color
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations            
            $RichTextRange.AddText($content)
            $Paragraph.Inlines.add($RichTextRange)
          }
        }
      }
      if($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{

        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }         
    }elseif($Contentfinal -match $urlpattern){
      $contentfinal = $contentfinal | out-string
      #$urlpattern = "<ref>(?<value>.*)</ref>"         
      $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
      if($Contentfinal -match 'https://localconfigpath/' -or $Contentfinal -match 'https://localgamepath/'){
        $Contentfinal = $Contentfinal -replace 'https://localconfigpath/','' -replace 'https://localgamepath/',''
        $urlpattern = '(([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()'
      }else{
        $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
      }
      $links2 = $([regex]::matches($Contentfinal, $urlpattern) | %{$_.groups[0].value})  
      $hyperlinks = New-Object System.Collections.ArrayList
      foreach($li in $links2){
        if($li -match "title="){
          $hyperlinks.add(($li -split 'title=')[0])
        }else{
          $hyperlinks.add($li)
        } 
      }
      #write-ezlogs "Link: $links2"
      $fullurls = @()
      $Paragraph = New-Object System.Windows.Documents.Paragraph
      $Linkcount = 0
      $titles = $null
      $titles = @()
      $titlestring = $Null
      $titlestring = ($contentfinal | out-string)    
      foreach($l in $hyperlinks){          
        $hyperlink = $l
        #write-ezlogs "Title: $titles"
        $titlepattern = "$([regex]::Escape($hyperlink))title=(?<value>.*)date="        
        $title = $([regex]::matches($titlestring, $titlepattern) | %{$_.groups[1].value}) 
        if($title -match 'date=' ){
          $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
          if($title -match 'date='){
            $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
          }
        }
        if($title){
          $datepattern = "$([regex]::Escape($title))date=(?<value>.*)"
          $date = $([regex]::matches($titlestring, $datepattern) | %{$_.groups[1].value}) 
          if($date){
            $date = ($date -split '</ref>')[0].trim()
            $date_replacement = "[Date: $date]"
          }else{
            $date_replacement = "Date: "
          }
          $Contentfinal = $Contentfinal -replace "title=$([regex]::Escape($title))",' ' -replace '</ref>',"" -replace '<ref>',"" -replace '</ref>',"" -replace 'Refurlurl=','' -replace '{{','' -replace '}}','' -replace "date=$date",$date_replacement
        }
        $Contentfinal = ($Contentfinal -replace [regex]::Escape($l),"------SPLITME------$l------SPLITME------")
        $Contentfinal = ($Contentfinal -split '------SPLITME------').trim()                      
      }
      foreach($content in $Contentfinal){ 
        $title = $Null
        $content = $content.trim() -replace '<ref>',"" -replace '</ref>',"" 
        #write-ezlogs "Content: $content" -color Cyan
        $link = $hyperlinks | where {$_ -eq $content} | select -Unique
        #$titlestring2 = (($content -split "date=")[0])
        if($content.StartsWith('#')){
          $content = "`n$content"
        }        
        if($content -eq $link){ 
          if($link -match "title="){
            $link = ($link -split 'title=')[0]
          } 
          $titlepattern = "$($link)title=(?<value>.*)date="
          #$titlestring = ($contentfinal -replace "date=","`ndate=" | out-string)
          $RichTextRange = New-Object System.Windows.Documents.Run    
          $link_hyperlink = New-object System.Windows.Documents.Hyperlink          
          if($link -match $localpath_pattern -and $([System.IO.Directory]::Exists($link) -or [System.IO.File]::Exists($link))){
            $title = $link
            if([System.IO.File]::Exists($link)){
              $link = $link | Split-path -Parent
            }
            $link_hyperlink.Background = 'Black'
          }elseif($link -match 'https://www.pcgamingwiki.com/wiki/Glossary'){
            $title = 'Glossary: Command Line Arguments'
          }elseif($link -match $localpath_pattern){
            $link_hyperlink.Background = 'Black'
          }else{
            $title = $([regex]::matches($titlestring, $titlepattern) | %{$_.groups[1].value})           
          }          
          if(!$title){
            $title = $([regex]::matches($link, $urlpattern) | %{$_.groups[2].value})
            if($title -match 'date=' ){
              $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
              if($title -match 'date='){
                $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
              }
            }           
          }          
          $linkcount++
          $RichTextRange.Background = $BackGroundColor         
          $link_hyperlink.NavigateUri = $link
          $link_hyperlink.ToolTip = "$link"
          $link_hyperlink.Foreground = "LightGreen"
          $Null = $link_hyperlink.Inlines.add("$title")
          $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)            
          $content = $($content -replace [regex]::Escape($link),' ')                      
          $RichTextRange.Foreground = $color
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.AddText("$content")          
          $RichTextRange.TextDecorations = $TextDecorations
          $Paragraph.Inlines.add($RichTextRange)  
          $ImageURL = $Null
          if($link -match '.jpg' -or $link -match '.jpeg' -or $link -match '.png' -or $link -match '.gif'){
            #$uri = new-object system.uri($link)
            $uri_imagelink_pattern = "(?<value>.*)\?t"
            if($link -match '\?t='){
              $uri = $([regex]::matches($link, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
            }else{
              $uri = new-object system.uri($link)
            }
            if(!([System.IO.Directory]::Exists($image_cache_dir))){
              $null = New-item $image_cache_dir -ItemType directory -Force
            }
            try{
              if($uri -match "https://store-images.s-microsoft.com/image/apps"){
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf).png")
              }elseif($uri -match '.png\?'){
                $filename = $([regex]::matches($uri, "(?<value>.*).png") | %{$_.groups[0].value}) | split-path -Leaf
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($filename)")
              }elseif($uri -match '.jpg\?'){
                $filename = $([regex]::matches($uri, "(?<value>.*).jpg") | %{$_.groups[0].value}) | split-path -Leaf
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($filename)")
              }elseif($uri -match '.jpeg\?'){
                $filename = $([regex]::matches($uri, "(?<value>.*).jpeg") | %{$_.groups[0].value}) | split-path -Leaf
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($filename)")
              }else{
                $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf)")
              }
            }catch{
              write-ezlogs "An exception occurred generating image cache path: $image_Cache_path" -showtime -catcherror $_
            }                  
            if(!([System.IO.File]::Exists($image_Cache_path))){
              try{
                if($verboselog){write-ezlogs "Caching image $uri to $image_Cache_path" -enablelogs -showtime}
                (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path)
              }catch{
                write-ezlogs "An exception occurred downloading file $uri to $image_Cache_path" -showtime -catcherror $_
              }              
              $ImageURL = $image_Cache_path
              $image_Decoded_Image_file = $Null        
            }else{
              if($verboselog){write-ezlogs "Found Cached image at $image_Cache_path" -enablelogs -showtime}
              $ImageURL = $image_Cache_path
              $image_Decoded_Image_file = "$ImageURL"
            }          
            $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer  
            $Floater = New-Object System.Windows.Documents.Floater
            $Floater.HorizontalAlignment = "Center" 
            $Floater.Name = "Media_Floater"
            if($ImageURL -match '.gif'){ 
              $Media_Element = New-object System.Windows.Controls.MediaElement   
              $Media_Element.Source = $ImageURL
              $media_element.UnloadedBehavior = 'Close'
              $Media_Element.Width = '600'
              $Media_Element.Stretch = "UniformToFill"
              $Media_Element.LoadedBehavior="Manual" 
              $Media_Element.Play()
              $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($gamename)-$($ImageURL)")
              $encodeduid = [System.Convert]::ToBase64String($encodedBytes)
              $media_element.Uid =  "Media_$encodeduid"              
              $Media_Element.tag = @{
                synchash=$synchash;
                thisApp=$thisApp
                gamename=$gamename
              }
              $Media_element.Add_MediaEnded({   
                  param($Sender) 
                  $synchash = $Sender.tag.synchash
                  $gamename = $Sender.tag.gamename  
                  if($synchash.Window.IsVisible -and $syncHash.Window.Title -notmatch 'Now Playing' -and $syncHash.Window.WindowState -ne 'Minimized'){
                    $this.Position = [Timespan]::FromMilliseconds(1)  
                  }else{
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()
                  }
                  #$this.LoadedBehavior = 'Manual'
                  #$this.Play()
              })  
              $media_element.add_MediaFailed({
                  param($Sender) 
                  $synchash = $Sender.tag.synchash
                  write-ezlogs "An exception occurred in medial element $($sender | out-string)" -showtime -warning
                  $this.Stop()
                  $this.tag = $Null
                  $this.close()                   
              })             
              #$synchash.Gif_player = $Media_Element 
              $BlockUIContainer.AddChild($Media_Element) 
            }else{
              $imagecontrol = New-Object System.Windows.Controls.Image
              $image = new-object System.Windows.Media.Imaging.BitmapImage 
              $stream_image = [System.IO.File]::OpenRead($ImageURL)
              $image.BeginInit();
              $image.CacheOption = "OnLoad"
              $image.StreamSource = $stream_image;
              #$image.UriSource = $ImageURL
              $image.DecodePixelWidth = '600' 
              $image.EndInit();    
              $image.Freeze();             
              #$imagecontrol.Source = $ImageURL
              $imagecontrol.Source = $image
              $imagecontrol.Width = "600"
              $imagecontrol.Stretch = "UniformToFill"
              $BlockUIContainer.AddChild($imagecontrol)                 
            }   
            $floater.AddChild($BlockUIContainer)
            $Paragraph.Inlines.Add($floater)
          }else{
            $Paragraph.Inlines.add(' ')
            $Paragraph.Inlines.add($link_hyperlink)
          }          
        }elseif($content -match [regex]::Escape('<img src="')){
          $content = $($content -replace [regex]::Escape('<img src="'),'' -replace '/>',"`n" -replace '"','')
          #write-ezlogs "no match $Content"
          $RichTextRange = New-Object System.Windows.Documents.Run 
          $RichTextRange.Foreground = $color
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.AddText($content)
          $RichTextRange.Background = $BackGroundColor
          $RichTextRange.TextDecorations = $TextDecorations
          $Paragraph.Inlines.add($RichTextRange)
        }elseif($Content -match $pattern_code){                         
          #write-ezlogs "#####Sections $sections"
          $pattern1 = '<code>(?<value>.*)'
          $code_split = ($($Content) -split '<\/code>')
          foreach ($split in $code_split){
            $codetext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
            if($codetext_match){
              [array]$codetext += $codetext_match
            }
          }                
          $sections = ($($code_split) -split $pattern1)     
          #write-ezlogs ">>>>Bolded $boldedtext"           
          foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){       
            $section = ($section).replace('					 ',"`n").replace('  ',' ')
            #write-ezlogs "---Section $section"      
            if($codetext -contains $section){
              $link_section = $section.trim()
              #write-ezlogs "---Section $link_section" -showtime
              if([System.IO.Directory]::Exists($link_section) -or [System.IO.File]::Exists($link_section) -or $link_section -match 'https:'){
                if([System.IO.File]::Exists($link_section)){
                  $title = $link_section
                  $link = $link_section | split-path -Parent
                }else{
                  $title = $link_section
                  $link = $link_section
                }
                $link_hyperlink = New-object System.Windows.Documents.Hyperlink                             
                $link_hyperlink.NavigateUri = $link
                $link_hyperlink.ToolTip = "$link"
                $link_hyperlink.Foreground = "LightGreen"
                $link_hyperlink.FontWeight = $FontWeight
                $link_hyperlink.BackGround = 'Black'
                $link_hyperlink.FontSize = $FontSize
                $link_hyperlink.FontFamily = 'Courier New'
                $Null = $link_hyperlink.Inlines.add("$title")
                $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)  
                $Paragraph.Inlines.add($link_hyperlink)
              }elseif($link_section -match $localpath_pattern){
                $Link_path = ($link_section | split-path -parent)
                if(![System.IO.Directory]::Exists($Link_path)){
                  $Link_path = ($link_section | split-path -parent | split-path -parent)
                }
                if(![System.IO.Directory]::Exists($Link_path)){
                  $Link_path = ($link_section | split-path -parent | split-path -parent | split-path -parent)
                }
                if(![System.IO.Directory]::Exists($Link_path)){
                  $Link_path = ($link_section | split-path -parent | split-path -parent | split-path -parent | split-path -parent)
                }
                if(![System.IO.Directory]::Exists($Link_path)){
                  $Link_path = ($link_section | split-path -parent | split-path -parent | split-path -parent | split-path -parent | split-path -parent)
                }  
                if([System.IO.Directory]::Exists($Link_path)){
                  $title = $link_section
                  $link = $Link_path
                  $link_hyperlink = New-object System.Windows.Documents.Hyperlink                             
                  $link_hyperlink.NavigateUri = $link
                  $link_hyperlink.ToolTip = "$link"
                  $link_hyperlink.Foreground = "LightGreen"
                  $link_hyperlink.FontWeight = $FontWeight
                  $link_hyperlink.BackGround = 'Black'
                  $link_hyperlink.FontSize = $FontSize
                  $link_hyperlink.FontFamily = 'Courier New'
                  $Null = $link_hyperlink.Inlines.add("$title")
                  $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)  
                  $Paragraph.Inlines.add($link_hyperlink)                     
                }else{
                  $RichTextRange = New-Object System.Windows.Documents.Run              
                  $RichTextRange.FontWeight = $FontWeight
                  $RichTextRange.Foreground = 'White' 
                  $RichTextRange.FontFamily = 'Courier New'
                  $RichTextRange.FontSize = $FontSize
                  $RichTextRange.Background = 'Black'
                  $RichTextRange.TextDecorations = $TextDecorations           
                  $RichTextRange.AddText("$section")
                  $Paragraph.Inlines.add($RichTextRange)               
                }                                                           
              }else{
                $RichTextRange = New-Object System.Windows.Documents.Run              
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.Foreground = 'White' 
                $RichTextRange.FontFamily = 'Courier New'
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = 'Black'
                $RichTextRange.TextDecorations = $TextDecorations           
                $RichTextRange.AddText("$section")
                $Paragraph.Inlines.add($RichTextRange)
              }
            }else{
              $RichTextRange = New-Object System.Windows.Documents.Run
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.Foreground = $color 
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations            
              $RichTextRange.AddText($section)
              $Paragraph.Inlines.add($RichTextRange)
            }
          }                   
        } 
        else{
          $link = $null
          $content = $($content -replace '/>',"`n" -replace '"','')
          $RichTextRange = New-Object System.Windows.Documents.Run               
          $RichTextRange.Foreground = $color
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.AddText($content)
          $RichTextRange.Background = $BackGroundColor
          $RichTextRange.TextDecorations = $TextDecorations
          $Paragraph.Inlines.add($RichTextRange)
        }
      }      
      if($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{
        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }                     
    }elseif($Contentfinal -match $pattern_strong){    
      $Paragraph = New-Object System.Windows.Documents.Paragraph       
      write-ezlogs "#####Sections $sections"
      $pattern1 = '<strong>(?<value>.*)'
      $Game_Description_split = ($($Contentfinal) -split '<\/strong>')
      foreach ($split in $Game_Description_split){
        $boldedtext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
        if($boldedtext_match){
          [array]$boldedtext += $boldedtext_match
        }
      }                
      $sections = ($($Game_Description_split) -split $pattern1)      
      write-ezlogs ">>>>Bolded $boldedtext"           
      foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){     
        $section = ($section).replace('					 ',"`n").replace('  ',' ')
        $link_section = $section.trim()
        #write-ezlogs "---Section $section"      
        if($boldedtext -contains $section){
          if([System.IO.Directory]::Exists($link_section) -or [System.IO.File]::Exists($link_section) -or $link_section -match 'https:'){
            if([System.IO.File]::Exists($link_section)){
              $title = $link_section
              $link = $link_section | split-path -Parent
            }elseif([System.IO.Directory]::Exists($link_section)){
              $title = $link_section
              $link = $link_section
            }else{
              $title = $link_section
              $link = $link_section
            }
            $link_hyperlink = New-object System.Windows.Documents.Hyperlink                             
            $link_hyperlink.NavigateUri = $link
            $link_hyperlink.ToolTip = "$link"
            $link_hyperlink.Foreground = "LightGreen"
            $link_hyperlink.FontWeight = $FontWeight
            $link_hyperlink.BackGround = 'Black'
            $link_hyperlink.FontSize = $FontSize
            $link_hyperlink.FontFamily = 'Courier New'
            $Null = $link_hyperlink.Inlines.add("$title")
            $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)  
            $RichTextRange = New-Object System.Windows.Documents.Run
            $RichTextRange.FontWeight = 'Bold'
            $RichTextRange.Foreground = $color 
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations           
            $RichTextRange.AddText($link_hyperlink)             
          }else{
            $RichTextRange = New-Object System.Windows.Documents.Run
            $RichTextRange.FontWeight = 'Bold'
            $RichTextRange.Foreground = $color 
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = $BackGroundColor
            $RichTextRange.TextDecorations = $TextDecorations           
            $RichTextRange.AddText($section)                   
          }        
        }else{
          $RichTextRange = New-Object System.Windows.Documents.Run
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.Foreground = $color 
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.Background = $BackGroundColor
          $RichTextRange.TextDecorations = $TextDecorations            
          $RichTextRange.AddText($section)
        }
        $Paragraph.Inlines.add($RichTextRange)
      }
      if($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{
        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }                   
    }elseif($Contentfinal -match $pattern_code){  
      $Paragraph = New-Object System.Windows.Documents.Paragraph       
      write-ezlogs "#####Sections $sections"
      $pattern1 = '<code>(?<value>.*)'
      $Game_Description_split = ($($Contentfinal) -split '<\/code>')
      foreach ($split in $Game_Description_split){
        $boldedtext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
        if($boldedtext_match){
          [array]$boldedtext += $boldedtext_match
        }
      }                
      $sections = ($($Game_Description_split) -split $pattern1)              
      foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){      
        $section = ($section).replace('					 ',"`n").replace('  ',' ')     
        if($boldedtext -contains $section){
          $link_section = $section.trim()
          #write-ezlogs "---Section $link_section" -showtime
          if([System.IO.Directory]::Exists($link_section) -or [System.IO.File]::Exists($link_section) -or $link_section -match 'https:'){
            if([System.IO.File]::Exists($link_section)){
              $title = $link_section
              $link = $link_section | split-path -Parent
            }elseif([System.IO.Directory]::Exists($link_section)){
              $title = $link_section
              $link = $link_section
            }else{
              $title = $link_section
              $link = $link_section
            }
            $link_hyperlink = New-object System.Windows.Documents.Hyperlink                             
            $link_hyperlink.NavigateUri = $link
            $link_hyperlink.ToolTip = "$link"
            $link_hyperlink.Foreground = "LightGreen"
            $link_hyperlink.FontWeight = $FontWeight
            $link_hyperlink.BackGround = 'Black'
            $link_hyperlink.FontSize = $FontSize
            $link_hyperlink.FontFamily = 'Courier New'
            $Null = $link_hyperlink.Inlines.add("$title")
            $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)  
            $Paragraph.Inlines.add($link_hyperlink)
          }else{
            $RichTextRange = New-Object System.Windows.Documents.Run              
            $RichTextRange.FontWeight = $FontWeight
            $RichTextRange.Foreground = 'White' 
            $RichTextRange.FontFamily = 'Courier New'
            $RichTextRange.FontSize = $FontSize
            $RichTextRange.Background = 'Black'
            $RichTextRange.TextDecorations = $TextDecorations           
            $RichTextRange.AddText("$section")
            $Paragraph.Inlines.add($RichTextRange)
          }        
        }else{
          $RichTextRange = New-Object System.Windows.Documents.Run
          $RichTextRange.FontWeight = $FontWeight
          $RichTextRange.Foreground = $color 
          $RichTextRange.FontSize = $FontSize
          $RichTextRange.Background = $BackGroundColor
          $RichTextRange.TextDecorations = $TextDecorations            
          $RichTextRange.AddText($section)
          $Paragraph.Inlines.add($RichTextRange)
        }
      }
      if($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        foreach($inline in $Paragraph.Inlines){
          $existing_content.inlines.add($inline)
        }
      }else{
        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
      }                   
    }          
    else{      
      if(Test-url -address $Contentfinal){
        #write-ezlogs "Content: $Contentfinal" -color Cyan
        $link_hyperlink1 = New-object System.Windows.Documents.Hyperlink
        $link_hyperlink1.NavigateUri = $Contentfinal
        $link_hyperlink1.ToolTip = "$Contentfinal"
        $link_hyperlink1.Foreground = "LightGreen"
        #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
        $Null = $link_hyperlink1.Inlines.add("Link")
        $Null = $link_hyperlink1.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)          
      }          
      if($AppendContent){
        $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
        #post the content and set the default foreground color
        if($link_hyperlink1){
          $existing_content.inlines.add($link_hyperlink1)
        }else{
          $RichTextRange.AddText($Contentfinal)
          $existing_content.inlines.add($RichTextRange)
        }
        #$Paragraph.Inlines.Add($RichTextRange)
      }else{
        $Paragraph = New-Object System.Windows.Documents.Paragraph
        $RichTextRange.AddText($Contentfinal)
        #$RichTextRange = New-Object System.Windows.Documents.Run($Contentfinal)
        $Paragraph = New-Object System.Windows.Documents.Paragraph($RichTextRange)
        $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)      
      }
    }
    #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.ContentStart, $RichTextBoxControl.Document.ContentEnd) 
    #write-ezlogs $Richtextrange2.text
    #[int]$codestart = $RichTextRange2.Text.IndexOf('<code>')
    #Write-ezlogs  $codestart
    #[int]$codeend = $RichTextRange2.Text.IndexOf('</code>')
    #$wordStartOffset = $RichTextRange2.Start.GetPositionAtOffset([int]$codestart + 6);
    #$wordEndOffset = $RichTextRange2.Start.GetPositionAtOffset([int]$codeend);
    #$wordRange = New-Object System.Windows.Documents.textrange($wordStartOffset, $wordEndOffset);
    #$wordRange.ApplyPropertyValue([System.Windows.Documents.TextElement]::BackgroundProperty, 'Gray')


    if(-not [string]::IsNullOrEmpty($RichTextRange.Text)){
      $content2count = ($RichTextRange.Text).ToCharArray().count + 2
    }
    else{
      $content2count = ($Contentfinal).ToCharArray().count + 2
    }
        
    #Output content to logfile if enabled
    if ($enablelogs)
    {
      $RichTextRange.Text | Out-File -FilePath $logfile -Encoding unicode -Append
    }
    #select only the content we want to manipulate using the positional info calculated previously
    #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.Contentend.GetPositionAtOffset(-$content2count), $RichTextBoxControl.Document.ContentEnd.GetPositionAtOffset(-1))
    #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.Contentend.GetPositionAtOffset(-$content2count), $RichTextBoxControl.Document.ContentEnd.GetPositionAtOffset(-1))
    #if a foreground color is specified, set the paramter foregroundcolor to the specified value
    if($color)
    {
      #$ParamOption = @{ForeGroundColor=$foregroundcolor}
      $Defaults = @{ForeGroundColor=$color}
      foreach ($Key in $Defaults.Keys) {  
        if ($ParamOption.Keys -notcontains $Key) {  
          $null = $ParamOption.Add($Key, $Defaults[$Key]) 
        } 
      }
    }
    if($FontWeight)
    {  
      #$ParamOption = @{ForeGroundColor="White"; FontSize="18"}
      $Defaults = @{FontWeight=$FontWeight}
      $default_keys = $Defaults.Keys
      foreach ($Key in $default_keys) {  
        if ($ParamOption.Keys -notcontains $Key) {  
          $null = $ParamOption.Add($Key, $Defaults[$Key]) 
        } 
      }
      #$ParamOption = @{FontWeight=$FontWeight}
    }
    $paramOption_keys = $ParamOption.keys
      
    #Select all the parameters, create the textelement property it applies to and then apply the property value to our previously selected text
    foreach ($param in $paramOption_keys)
    {
      $SelectedParam = $param  
      if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}  
      elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}  
      elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}  
      elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}  
      elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
      #$RichTextRange2.ApplyPropertyValue($TextElement, $ParamOption[$SelectedParam]) 
    }
  }
  else
  {
    $RichTextBoxControl.Dispatcher.Invoke([action]{
        $ParamOption = @{ForeGroundColor=$Color;BackGroundColor=$BackGroundColor;FontSize=$FontSize; FontStyle=$FontStyle; FontWeight=$FontWeight}

        #if using linebefore, add an extra line break before the content
        if ($linebefore) 
        {
          $Content = "`n$Content"  
        }
        if ($Separator)        
        {         
          $horz_line = "`n────────────────────────────`n"
          $Content = "$Content$horz_line"        
        }        
        #if using lineafter, add an extra line break after the content
        if ($lineafter)
        {
          $Content = "$Content`n"
        }  
        #if we want to show time, add date time in front of content. Then count the number of characters of content after showtime to get position info for later calculation
        if ($showtime)       
        {         
          if($custom_showtime){
            if($customdateformat){
              $content1 = "[$(Get-Date $custom_showtime -Format $customdateformat):] "
            }else{
              $content1 = "[$(Get-Date $custom_showtime)] : "
            }  
          }else{
            $content1 = "[$(Get-Date -Format $logdateformat)] : "
          }        
          $content2 = $content          
          $Contentfinal = "$content1$content2"          
          $content2count = $content2.ToCharArray().count + 2        
        }
        else
        {
          $Contentfinal = $content
          $content2count = $Contentfinal.ToCharArray().count + 2
        }
        $RichTextRange = New-Object System.Windows.Documents.Run               
        $RichTextRange.Foreground = $color
        $RichTextRange.FontWeight = $FontWeight
        $RichTextRange.FontSize = $FontSize
        $RichTextRange.Background = $BackGroundColor
        $RichTextRange.TextDecorations = $TextDecorations
        [System.Windows.RoutedEventHandler]$Hyperlink_RequestNavigate = {
          param ($sender,$e)
          start $sender.NavigateUri.ToString()
        }
        #write-ezlogs "Before####$Contentfinal"
        if($contentfinal -match '</br>' -or $Contentfinal -match '<br />' -or $Contentfinal -match '<br>' -or $ContentFinal -match 'br>' -or $Contentfinal -match '<li>' -or $Contentfinal -match '</li>' -or $Contentfinal -match '<ul>' -or $Contentfinal -match '</ul>' -or $Contentfinal -match '</ol>' -or $Contentfinal -match '<u>' -or $Contentfinal -match '</u>'){
          $contentfinal = $($($contentfinal) -replace '<br />',"" -replace '<br>',"`n" -replace 'br>',"`n" -replace '<li>',"`n  • " -replace '<ul>','' -replace '<ol>','' -replace '</ul>','' -replace '</li>','' -replace '</ol>','' -replace '<ul class="bb_ul">','' -replace '<u>','' -replace '</u>','').trim()
        }  
      
        if($contentfinal -match "`n`n"){
          $contentfinal = ($contentfinal -replace "`n`n","`n").trim()
        }
        if($contentfinal -match '&quot;'){
          $contentfinal = ($contentfinal -replace '&quot;','"').trim()
        }
        if($contentfinal -match '&amp;'){
          $contentfinal = ($contentfinal -replace '&amp;','&').trim()
        }
        if($contentfinal -match '\[\[Glossary\:Command line'){
          $contentfinal = ($contentfinal -replace '\[\[Glossary:Command line','https://www.pcgamingwiki.com/wiki/Glossary:Command_line_arguments').trim()
        }  
        if($Valid_Configpaths -and $contentfinal -match '\#Game dataconfiguration file\(s\) location'){
      
          $contentfinal = ($contentfinal -replace '\#Game dataconfiguration file\(s\) location',"https://localconfigpath/$($Valid_Configpaths | select -first 1)" -replace '\[\[','' -replace '\]\]','').trim()
        }     
        if($Game_install_path -and $contentfinal -match [regex]::Escape($Game_install_path)){
      
          $contentfinal = ($contentfinal -replace [regex]::Escape($Game_install_path),"https://localgamepath/$($Game_install_path)" -replace '\[\[','' -replace '\]\]','').trim()
        }    
        $localpath_pattern = '(([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()'       
        $contentfinal = $contentfinal.trim()
        #write-ezlogs "After>>>>$Contentfinal" 
        if($Contentfinal -match 'href='){
          $titlepattern = " title=`"(?<value>.*)`""  
          $titlecode = ([regex]::matches($Contentfinal, $titlepattern) | %{$_.groups[0].value} )
          #write-ezlogs "Titlecode $titlecode"
          foreach($code in $titlecode){
            $contentfinal = $Contentfinal -replace $code,''
          }
          #write-ezlogs "Contentfinal $contentfinal"
          $urlpattern = "<a href=`"(?<value>.*)`">"
          #write-ezlogs "#####$Contentfinal"
          $links2 = $([regex]::matches($Contentfinal, $urlpattern) | %{$_.groups[0].value})
          #write-ezlogs ">>>>$links2"
          if(!$links2){   
            $fullurls =  $([regex]::matches($Contentfinal, '<a href="(?<value>.*)</a>') | %{$_.groups[0].value})
            $links = $([regex]::matches($fullurls, "`"(?<value>.*)`/`"") | %{$_.groups[1].value}) 
            $fullurls = $fullurls -replace "`n", ''
            #write-ezlogs "--$fullurls"
          }else{
            $fullurls = New-Object System.Collections.ArrayList
            foreach($link in $links2){
              $url1pattern = "$($link)(?<value>.*)</a>"
              $fullurl = ([regex]::matches($Contentfinal, $url1pattern) | %{$_.groups[0].value} )
              $fullurls.add($fullurl)
            }      
          }      
          $Paragraph = New-Object System.Windows.Documents.Paragraph
          foreach($l in $fullurls){
            if($links){
              $hyperlink =  $([regex]::matches($l, "`"(?<value>.*)`/`"") | %{$_.groups[1].value})
              $fullurlname = ([regex]::matches($l, "$($hyperlink)(?<value>.*)>(?<value>.*)</a>") | %{$_.groups[1].value} )        
            }else{
              $hyperlink = ([regex]::matches($l, $urlpattern) | %{$_.groups[1].value} )
              $url1pattern = "$($hyperlink)`">(?<value>.*)</a>"
              $fullurlname = ([regex]::matches($l, $url1pattern) | %{$_.groups[1].value} )          
            }
            #write-ezlogs ">>>Hyperlink $hyperlink"
            $link_hyperlink = New-object System.Windows.Documents.Hyperlink
            $link_hyperlink.NavigateUri = $hyperlink
            $link_hyperlink.ToolTip = "$hyperlink"
            $link_hyperlink.Foreground = "LightGreen"
            #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
            $Null = $link_hyperlink.Inlines.add("$fullurlname")
            $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)
            #write-ezlogs "####Bef $Contentfinal"
            $Contentfinal = ($Contentfinal -replace [regex]::Escape($l),"$l------SPLITME------")
            $Contentfinal = ($Contentfinal -split '------SPLITME------')
            #$Contentfinal = $Contentfinal.trim()   
            foreach($content in $Contentfinal){
              if($content -match [regex]::Escape($l) -and -not [string]::IsNullOrEmpty($content)){
                #write-ezlogs "---match $l"
                $content = $($content -replace [regex]::Escape($l),' ')
                $RichTextRange = New-Object System.Windows.Documents.Run               
                $RichTextRange.Foreground = $color
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = $BackGroundColor
                $RichTextRange.TextDecorations = $TextDecorations
                $RichTextRange.AddText($content)
                $Paragraph.Inlines.add($RichTextRange)
                if($hyperlink -match '.jpg' -or $hyperlink -match '.jpeg' -or $hyperlink -match '.png' -or $hyperlink -match '.gif'){
                  #$uri = new-object system.uri($link)
                  $uri_imagelink_pattern = "(?<value>.*)\?t"
                  if($hyperlink -match '\?t='){
                    $uri = $([regex]::matches($hyperlink, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
                  }else{
                    $uri = new-object system.uri($hyperlink)
                  }              
                  $uri = $([regex]::matches($hyperlink, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
                  if(!([System.IO.Directory]::Exists($image_cache_dir))){
                    $null = New-item $image_cache_dir -ItemType directory -Force
                  }
                  if($uri -match "https://store-images.s-microsoft.com/image/apps"){
                    $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf).png")
                  }else{
                    $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf)")
                  }      
                  if(!([System.IO.File]::Exists($image_Cache_path))){
                    #$null =  (New-Object System.Net.WebClient).DownloadFileAsync($uri,$image_Cache_path)
                    (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path)
                    if($verboselog){write-ezlogs "Caching image $uri to $image_Cache_path" -enablelogs -showtime}
                    $ImageURL = $image_Cache_path
                    $image_Decoded_Image_file = $Null        
                  }else{
                    if($verboselog){write-ezlogs "Found Cached image at $image_Cache_path" -enablelogs -showtime}
                    $ImageURL = $image_Cache_path
                    $image_Decoded_Image_file = "$ImageURL"
                  }          
                  $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer  
                  $Floater = New-Object System.Windows.Documents.Floater
                  $Floater.HorizontalAlignment = "Center" 
                  $Floater.Name = "Media_Floater"
                  if($ImageURL -match '.gif'){ 
                    $Media_Element = New-object System.Windows.Controls.MediaElement 
                    $media_element.UnloadedBehavior = 'Close'  
                    $media_element.Name = 'Gif_Player'
                    $Media_Element.Source = $ImageURL
                    $Media_Element.Width = '600'
                    $Media_Element.Stretch = "UniformToFill"
                    $Media_Element.LoadedBehavior="Manual" 
                    $Media_Element.Play()
                    $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($gamename)-$($ImageURL)")
                    $encodeduid = [System.Convert]::ToBase64String($encodedBytes)
                    $media_element.Uid =  "Media_$encodeduid"                    
                    $Media_Element.tag = @{
                      synchash=$synchash;
                      thisApp=$thisApp
                      gamename=$gamename
                    }
                    $Media_element.Add_MediaEnded({   
                        param($Sender) 
                        $synchash = $Sender.tag.synchash
                        $gamename = $Sender.tag.gamename  
                        if($synchash.Window.IsVisible -and $syncHash.Window.Title -notmatch 'Now Playing' -and $syncHash.Window.WindowState -ne 'Minimized'){
                          $this.Position = [Timespan]::FromMilliseconds(1)  
                        }else{
                          $this.Stop()
                          $this.tag = $Null
                          $this.close()
                        }
                        #$this.LoadedBehavior = 'Manual'
                        #$this.Play()
                    })  
                    $media_element.add_MediaFailed({
                        param($Sender) 
                        $synchash = $Sender.tag.synchash
                        write-ezlogs "An exception occurred in medial element $($sender | out-string)" -showtime -warning
                        $this.Stop()
                        $this.tag = $Null
                        $this.close()                   
                    })                   
                    #$synchash.Gif_player = $Media_Element
                    $BlockUIContainer.AddChild($Media_Element) 
                  }else{
                    $imagecontrol = New-Object System.Windows.Controls.Image
                    $image = new-object System.Windows.Media.Imaging.BitmapImage 
                    $stream_image = [System.IO.File]::OpenRead($ImageURL)
                    $image.BeginInit();
                    $image.CacheOption = "OnLoad"
                    $image.StreamSource = $stream_image;
                    #$image.UriSource = $ImageURL
                    $image.DecodePixelWidth = '600' 
                    $image.EndInit();    
                    $image.Freeze();             
                    #$imagecontrol.Source = $ImageURL
                    $imagecontrol.Source = $image
                    $imagecontrol.Width = "600"
                    $imagecontrol.Stretch = "UniformToFill"
                    $BlockUIContainer.AddChild($imagecontrol)                 
                  }   
                  $floater.AddChild($BlockUIContainer)
              
                  $Paragraph.Inlines.Add($floater)
                }else{
                  $Paragraph.Inlines.add($link_hyperlink)
                }           
              }elseif($content -match [regex]::Escape('<img src="')){
                $content = $($content -replace [regex]::Escape('<img src="'),'' -replace '"/>',"`n" -replace '"','')
                #write-ezlogs "no match $Content"
                $RichTextRange.Foreground = $color
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = $BackGroundColor
                $RichTextRange.TextDecorations = $TextDecorations
                $RichTextRange.AddText($content)
                $Paragraph.Inlines.add($RichTextRange)
              }elseif($Content -match $pattern_code){                 
                #write-ezlogs "#####Sections $sections"
                $pattern1 = '<code>(?<value>.*)'
                $code_split = ($($Content) -split '<\/code>')
                foreach ($split in $code_split){
                  $codetext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
                  if($codetext_match){
                    [array]$codetext += $codetext_match
                  }
                }                
                $sections = ($($code_split) -split $pattern1)     
                #write-ezlogs ">>>>Bolded $boldedtext"           
                foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){
                  $section = ($section).replace('					 ',"`n").replace('  ',' ')
                  #write-ezlogs "---Section $section"      
                  if($codetext -contains $section){
                    $RichTextRange = New-Object System.Windows.Documents.Run              
                    $RichTextRange.FontWeight = $FontWeight
                    $RichTextRange.Foreground = 'White' 
                    $RichTextRange.FontFamily = 'Courier New'
                    $RichTextRange.FontSize = $FontSize
                    $RichTextRange.Background = 'Black'
                    $RichTextRange.TextDecorations = $TextDecorations           
                    $RichTextRange.AddText("$section")
                  }else{
                    $RichTextRange = New-Object System.Windows.Documents.Run
                    $RichTextRange.FontWeight = $FontWeight
                    $RichTextRange.Foreground = $color 
                    $RichTextRange.FontSize = $FontSize
                    $RichTextRange.Background = $BackGroundColor
                    $RichTextRange.TextDecorations = $TextDecorations            
                    $RichTextRange.AddText($section)
                  }
                  $Paragraph.Inlines.add($RichTextRange)
                }                   
              }else{
                $content = $($content -replace [regex]::Escape($l),' ' -replace '"/>','' -replace '"','')
                #write-ezlogs "no match $Content"
                $RichTextRange.Foreground = $color
                $RichTextRange.FontWeight = $FontWeight
                $RichTextRange.FontSize = $FontSize
                $RichTextRange.Background = $BackGroundColor
                $RichTextRange.TextDecorations = $TextDecorations            
                $RichTextRange.AddText($content)
                $Paragraph.Inlines.add($RichTextRange)
              }
            }
          }
          if($AppendContent){
            $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
            #post the content and set the default foreground color
            foreach($inline in $Paragraph.Inlines){
              $existing_content.inlines.add($inline)
            }
          }else{
            $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
          }         
        }elseif($Contentfinal -match 'https:' -and !(Test-url -address $Contentfinal)){
          $contentfinal = $contentfinal | out-string
          #$urlpattern = "<ref>(?<value>.*)</ref>"         
          $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
          if($Contentfinal -match 'https://localconfigpath/' -or $Contentfinal -match 'https://localgamepath/'){
            $Contentfinal = $Contentfinal -replace 'https://localconfigpath/','' -replace 'https://localgamepath/',''
            $urlpattern = '(([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"/\\|?*])|\/(?![\0-\37<>:"/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"/\\|?*]+))((\\|\/)[^\0-\37<>:"/\\|?*]+|(\\|\/)$)*()'
          }else{
            $urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
          }
          $links2 = $([regex]::matches($Contentfinal, $urlpattern) | %{$_.groups[0].value})  
          $hyperlinks = New-Object System.Collections.ArrayList
          foreach($li in $links2){
            if($li -match "title="){
              $hyperlinks.add(($li -split 'title=')[0])
            }else{
              $hyperlinks.add($li)
            } 
          }
          #write-ezlogs "Link: $links2"
          $fullurls = @()
          $Paragraph = New-Object System.Windows.Documents.Paragraph
          $Linkcount = 0
          $titles = $null
          $titles = @()
          $titlestring = $Null
          $titlestring = ($contentfinal | out-string)     
          foreach($l in $hyperlinks){          
            $hyperlink = $l
            #write-ezlogs "Title: $titles"
            $titlepattern = "$([regex]::Escape($hyperlink))title=(?<value>.*)date="        
            $title = $([regex]::matches($titlestring, $titlepattern) | %{$_.groups[1].value}) 
            if($title -match 'date=' ){
              $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
              if($title -match 'date='){
                $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
              }
            }
            if($title){
              $datepattern = "$([regex]::Escape($title))date=(?<value>.*)"
              $date = $([regex]::matches($titlestring, $datepattern) | %{$_.groups[1].value}) 
              if($date){
                $date = ($date -split '</ref>')[0].trim()
                $date_replacement = "[Date: $date]"
              }else{
                $date_replacement = "Date: "
              }
              $Contentfinal = $Contentfinal -replace "title=$([regex]::Escape($title))",' ' -replace '</ref>',"" -replace '<ref>',"" -replace '</ref>',"" -replace 'Refurlurl=','' -replace '{{','' -replace '}}','' -replace "date=$date",$date_replacement
            }
            $Contentfinal = ($Contentfinal -replace [regex]::Escape($l),"------SPLITME------$l------SPLITME------")
            $Contentfinal = ($Contentfinal -split '------SPLITME------').trim()                      
          }
          #write-ezlogs "Contentfinal after split: $Contentfinal"
          foreach($content in $Contentfinal){ 
            $title = $Null
            $content = $content.trim() -replace '<ref>',"" -replace '</ref>',"" 
            #write-ezlogs "Content: $content" -color Cyan
            $link = $hyperlinks | where {$_ -eq $content} | select -Unique
            #write-ezlogs "Content: $content"
            #$titlestring2 = (($content -split "date=")[0])
            if($content.StartsWith('#')){
              $content = "`n$content"
            }        
            if($content -eq $link){ 
              if($link -match "title="){
                $link = ($link -split 'title=')[0]
              } 
              $titlepattern = "$($link)title=(?<value>.*)date="
              #$titlestring = ($contentfinal -replace "date=","`ndate=" | out-string)
              $RichTextRange = New-Object System.Windows.Documents.Run    
              $link_hyperlink = New-object System.Windows.Documents.Hyperlink          
              if($link -match $localpath_pattern -or [System.IO.Directory]::Exists($link)){
                $title = 'Config Files(s)'
                $link_hyperlink.Background = 'Black'
              }elseif($link -match 'https://www.pcgamingwiki.com/wiki/Glossary'){
                $title = 'Glossary: Command Line Arguments'
              }else{
                $title = $([regex]::matches($titlestring, $titlepattern) | %{$_.groups[1].value})           
              }          
              if(!$title){
                $title = $([regex]::matches($link, $urlpattern) | %{$_.groups[2].value})
                if($title -match 'date=' ){
                  $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
                  if($title -match 'date='){
                    $title = $([regex]::matches($title, "(?<value>.*)date=") | %{$_.groups[1].value}) 
                  }
                }           
              }          
              $linkcount++
              $RichTextRange.Background = $BackGroundColor         
              $link_hyperlink.NavigateUri = $link
              $link_hyperlink.ToolTip = "$link"
              $link_hyperlink.Foreground = "LightGreen"
              $Null = $link_hyperlink.Inlines.add("$title")
              $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)            
              $content = $($content -replace [regex]::Escape($link),' ')                      
              $RichTextRange.Foreground = $color
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.AddText("$content")          
              $RichTextRange.TextDecorations = $TextDecorations
              $Paragraph.Inlines.add($RichTextRange)  
              $ImageURL = $Null
              if($link -match '.jpg' -or $link -match '.jpeg' -or $link -match '.png' -or $link -match '.gif'){
                #$uri = new-object system.uri($link)
                $uri_imagelink_pattern = "(?<value>.*)\?t"
                if($link -match '\?t='){
                  $uri = $([regex]::matches($link, $uri_imagelink_pattern) | %{$_.groups[1].value}) 
                }else{
                  $uri = new-object system.uri($link)
                }
                if(!([System.IO.Directory]::Exists($image_cache_dir))){
                  $null = New-item $image_cache_dir -ItemType directory -Force
                }
                if($uri -match "https://store-images.s-microsoft.com/image/apps"){
                  $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf).png")
                }else{
                  $image_Cache_path = [System.IO.Path]::Combine($image_cache_dir,"$($uri | split-path -Leaf)")
                }      
                if(!([System.IO.File]::Exists($image_Cache_path))){
                  (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path)
                  if($verboselog){write-ezlogs "Caching image $uri to $image_Cache_path" -enablelogs -showtime}
                  $ImageURL = $image_Cache_path
                  $image_Decoded_Image_file = $Null        
                }else{
                  if($verboselog){write-ezlogs "Found Cached image at $image_Cache_path" -enablelogs -showtime}
                  $ImageURL = $image_Cache_path
                  $image_Decoded_Image_file = "$ImageURL"
                }          
                $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer
                $Floater = New-Object System.Windows.Documents.Floater
                $Floater.HorizontalAlignment = "Center" 
                $Floater.Name = "Media_Floater"
                if($ImageURL -match '.gif'){ 
                  $Media_Element = New-object System.Windows.Controls.MediaElement   
                  $Media_Element.Source = $ImageURL
                  $media_element.UnloadedBehavior = 'Close'
                  $Media_Element.Width = '600'
                  $Media_Element.Stretch = "UniformToFill"
                  $Media_Element.LoadedBehavior="Manual" 
                  $Media_Element.Play()
                  $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($gamename)-$($ImageURL)")
                  $encodeduid = [System.Convert]::ToBase64String($encodedBytes)
                  $media_element.Uid =  "Media_$encodeduid"                  
                  $Media_Element.tag = @{
                    synchash=$synchash;
                    thisApp=$thisApp
                    gamename=$gamename
                  }
                  $Media_element.Add_MediaEnded({   
                      param($Sender) 
                      $synchash = $Sender.tag.synchash
                      $gamename = $Sender.tag.gamename  
                      if($synchash.Window.IsVisible -and $syncHash.Window.Title -notmatch 'Now Playing' -and $syncHash.Window.WindowState -ne 'Minimized'){
                        $this.Position = [Timespan]::FromMilliseconds(1)  
                      }else{
                        $this.Stop()
                        $this.tag = $Null
                        $this.close()
                      }
                      #$this.LoadedBehavior = 'Manual'
                      #$this.Play()
                  })  
                  $media_element.add_MediaFailed({
                      param($Sender) 
                      $synchash = $Sender.tag.synchash
                      write-ezlogs "An exception occurred in medial element $($sender | out-string)" -showtime -warning
                      $this.Stop()
                      $this.tag = $Null
                      $this.close()                   
                  })                  
                  #$synchash.Gif_player = $Media_Element 
                  $BlockUIContainer.AddChild($Media_Element) 
                }else{
                  $imagecontrol = New-Object System.Windows.Controls.Image
                  $image = new-object System.Windows.Media.Imaging.BitmapImage 
                  $stream_image = [System.IO.File]::OpenRead($ImageURL)
                  $image.BeginInit();
                  $image.CacheOption = "OnLoad"
                  $image.StreamSource = $stream_image;
                  #$image.UriSource = $ImageURL
                  $image.DecodePixelWidth = '600' 
                  $image.EndInit();    
                  $image.Freeze();             
                  #$imagecontrol.Source = $ImageURL
                  $imagecontrol.Source = $image
                  $imagecontrol.Width = "600"
                  $imagecontrol.Stretch = "UniformToFill"
                  $BlockUIContainer.AddChild($imagecontrol)                 
                }   
                $floater.AddChild($BlockUIContainer)
                $Paragraph.Inlines.Add($floater)
              }else{
                $Paragraph.Inlines.add(' ')
                $Paragraph.Inlines.add($link_hyperlink)
              }          
            }elseif($content -match [regex]::Escape('<img src="')){
              $content = $($content -replace [regex]::Escape('<img src="'),'' -replace '/>',"`n" -replace '"','')
              #write-ezlogs "no match $Content"
              $RichTextRange = New-Object System.Windows.Documents.Run 
              $RichTextRange.Foreground = $color
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.AddText($content)
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations
              $Paragraph.Inlines.add($RichTextRange)
            }elseif($Content -match $pattern_code){                         
              #write-ezlogs "#####Sections $sections"
              $pattern1 = '<code>(?<value>.*)'
              $code_split = ($($Content) -split '<\/code>')
              foreach ($split in $code_split){
                $codetext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
                if($codetext_match){
                  [array]$codetext += $codetext_match
                }
              }                
              $sections = ($($code_split) -split $pattern1)     
              #write-ezlogs ">>>>Bolded $boldedtext"           
              foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){       
                $section = ($section).replace('					 ',"`n").replace('  ',' ')
                #write-ezlogs "---Section $section"      
                if($codetext -contains $section){
                  $link_section = $section.trim()
                  if([System.IO.Directory]::Exists($link_section) -or $link_section -match 'https:'){
                    $link_hyperlink = New-object System.Windows.Documents.Hyperlink                             
                    $link_hyperlink.NavigateUri = $link
                    $link_hyperlink.ToolTip = "$link"
                    $link_hyperlink.Foreground = "LightGreen"
                    $link_hyperlink.FontWeight = $FontWeight
                    $link_hyperlink.BackGround = 'Black'
                    $link_hyperlink.FontSize = $FontSize
                    $link_hyperlink.FontFamily = 'Courier New'
                    $Null = $link_hyperlink.Inlines.add("$link")
                    $Null = $link_hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)  
                    $Paragraph.Inlines.add($link_hyperlink)
                  }else{
                    $RichTextRange = New-Object System.Windows.Documents.Run              
                    $RichTextRange.FontWeight = $FontWeight
                    $RichTextRange.Foreground = 'White' 
                    $RichTextRange.FontFamily = 'Courier New'
                    $RichTextRange.FontSize = $FontSize
                    $RichTextRange.Background = 'Black'
                    $RichTextRange.TextDecorations = $TextDecorations           
                    $RichTextRange.AddText("$section")
                    $Paragraph.Inlines.add($RichTextRange)
                  }
                }else{
                  $RichTextRange = New-Object System.Windows.Documents.Run
                  $RichTextRange.FontWeight = $FontWeight
                  $RichTextRange.Foreground = $color 
                  $RichTextRange.FontSize = $FontSize
                  $RichTextRange.Background = $BackGroundColor
                  $RichTextRange.TextDecorations = $TextDecorations            
                  $RichTextRange.AddText($section)
                  $Paragraph.Inlines.add($RichTextRange)
                }
              }                   
            } 
            else{
              $link = $null
              $content = $($content -replace '/>',"`n" -replace '"','')
              $RichTextRange = New-Object System.Windows.Documents.Run               
              $RichTextRange.Foreground = $color
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.AddText($content)
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations
              $Paragraph.Inlines.add($RichTextRange)
            }
          }      
          if($AppendContent){
            $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
            #post the content and set the default foreground color
            foreach($inline in $Paragraph.Inlines){
              $existing_content.inlines.add($inline)
            }
          }else{
            $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
          }                     
        }elseif($Contentfinal -match $pattern_strong){    
          $Paragraph = New-Object System.Windows.Documents.Paragraph       
          #write-ezlogs "#####Sections $sections"
          $pattern1 = '<strong>(?<value>.*)'
          $Game_Description_split = ($($Contentfinal) -split '<\/strong>')
          foreach ($split in $Game_Description_split){
            $boldedtext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
            if($boldedtext_match){
              [array]$boldedtext += $boldedtext_match
            }
          }                
          $sections = ($($Game_Description_split) -split $pattern1)      
          #write-ezlogs ">>>>Bolded $boldedtext"           
          foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){     
            $section = ($section).replace('					 ',"`n").replace('  ',' ')
            #write-ezlogs "---Section $section"      
            if($boldedtext -contains $section){
              $RichTextRange = New-Object System.Windows.Documents.Run
              $RichTextRange.FontWeight = 'Bold'
              $RichTextRange.Foreground = $color 
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations           
              $RichTextRange.AddText($section)
            }else{
              $RichTextRange = New-Object System.Windows.Documents.Run
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.Foreground = $color 
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations            
              $RichTextRange.AddText($section)
            }
            $Paragraph.Inlines.add($RichTextRange)
          }
          if($AppendContent){
            $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
            #post the content and set the default foreground color
            foreach($inline in $Paragraph.Inlines){
              $existing_content.inlines.add($inline)
            }
          }else{
            $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
          }                   
        }elseif($Contentfinal -match $pattern_code){  
          $Paragraph = New-Object System.Windows.Documents.Paragraph       
          #write-ezlogs "#####Sections $sections"
          $pattern1 = '<code>(?<value>.*)'
          $Game_Description_split = ($($Contentfinal) -split '<\/code>')
          foreach ($split in $Game_Description_split){
            $boldedtext_match = ([regex]::matches($($split), $pattern1) | %{$_.groups[1].value})
            if($boldedtext_match){
              [array]$boldedtext += $boldedtext_match
            }
          }                
          $sections = ($($Game_Description_split) -split $pattern1)      
          #write-ezlogs ">>>>Bolded $boldedtext"           
          foreach($section in $sections | where { -not [string]::IsNullOrEmpty($_)}){      
            $section = ($section).replace('					 ',"`n").replace('  ',' ')
            #write-ezlogs "---Section $section"      
            if($boldedtext -contains $section){
              $RichTextRange = New-Object System.Windows.Documents.Run
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.Foreground = 'White' 
              $RichTextRange.FontFamily = 'Courier New'
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.Background = 'Black'
              $RichTextRange.TextDecorations = $TextDecorations           
              $RichTextRange.AddText("$section")
            }else{
              $RichTextRange = New-Object System.Windows.Documents.Run
              $RichTextRange.FontWeight = $FontWeight
              $RichTextRange.Foreground = $color 
              $RichTextRange.FontSize = $FontSize
              $RichTextRange.Background = $BackGroundColor
              $RichTextRange.TextDecorations = $TextDecorations            
              $RichTextRange.AddText($section)
            }
            $Paragraph.Inlines.add($RichTextRange)
          }
          if($AppendContent){
            $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
            #post the content and set the default foreground color
            foreach($inline in $Paragraph.Inlines){
              $existing_content.inlines.add($inline)
            }
          }else{
            $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)
          }                   
        }          
        else{      
          if(Test-url -address $Contentfinal){
            $link_hyperlink1 = New-object System.Windows.Documents.Hyperlink
            $link_hyperlink1.NavigateUri = $Contentfinal
            $link_hyperlink1.ToolTip = "$Contentfinal"
            $link_hyperlink1.Foreground = "LightGreen"
            #$LinkParagraph = New-Object System.Windows.Documents.Paragraph($link_hyperlink)
            $Null = $link_hyperlink1.Inlines.add("Link")
            $Null = $link_hyperlink1.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$Hyperlink_RequestNavigate)          
          }          
          if($AppendContent){
            $existing_content = $RichTextBoxControl.Document.blocks | select -last 1
            #post the content and set the default foreground color
            if($link_hyperlink1){
              $existing_content.inlines.add($link_hyperlink1)
            }else{
              $RichTextRange.AddText($Contentfinal)
              $existing_content.inlines.add($RichTextRange)
            }
            #$Paragraph.Inlines.Add($RichTextRange)
          }else{
            $Paragraph = New-Object System.Windows.Documents.Paragraph
            $RichTextRange.AddText($Contentfinal)
            #$RichTextRange = New-Object System.Windows.Documents.Run($Contentfinal)
            $Paragraph = New-Object System.Windows.Documents.Paragraph($RichTextRange)
            $null = $RichTextBoxControl.Document.Blocks.Add($Paragraph)      
          }
        }
        #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.ContentStart, $RichTextBoxControl.Document.ContentEnd) 
        #write-ezlogs $Richtextrange2.text
        #[int]$codestart = $RichTextRange2.Text.IndexOf('<code>')
        #Write-ezlogs  $codestart
        #[int]$codeend = $RichTextRange2.Text.IndexOf('</code>')
        #$wordStartOffset = $RichTextRange2.Start.GetPositionAtOffset([int]$codestart + 6);
        #$wordEndOffset = $RichTextRange2.Start.GetPositionAtOffset([int]$codeend);
        #$wordRange = New-Object System.Windows.Documents.textrange($wordStartOffset, $wordEndOffset);
        #$wordRange.ApplyPropertyValue([System.Windows.Documents.TextElement]::BackgroundProperty, 'Gray')


        if(-not [string]::IsNullOrEmpty($RichTextRange.Text)){
          $content2count = ($RichTextRange.Text).ToCharArray().count + 2
        }
        else{
          $content2count = ($Contentfinal).ToCharArray().count + 2
        }
        
        #Output content to logfile if enabled
        if ($enablelogs)
        {
          $RichTextRange.Text | Out-File -FilePath $logfile -Encoding unicode -Append
        }
        #select only the content we want to manipulate using the positional info calculated previously
        #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.Contentend.GetPositionAtOffset(-$content2count), $RichTextBoxControl.Document.ContentEnd.GetPositionAtOffset(-1))
        #$RichTextRange2 = New-Object System.Windows.Documents.textrange($RichTextBoxControl.Document.Contentend.GetPositionAtOffset(-$content2count), $RichTextBoxControl.Document.ContentEnd.GetPositionAtOffset(-1))
        #if a foreground color is specified, set the paramter foregroundcolor to the specified value
        if($color)
        {
          #$ParamOption = @{ForeGroundColor=$foregroundcolor}
          $Defaults = @{ForeGroundColor=$color}
          foreach ($Key in $Defaults.Keys) {  
            if ($ParamOption.Keys -notcontains $Key) {  
              $null = $ParamOption.Add($Key, $Defaults[$Key]) 
            } 
          }
        }
        if($FontWeight)
        {  
          #$ParamOption = @{ForeGroundColor="White"; FontSize="18"}
          $Defaults = @{FontWeight=$FontWeight}
          $default_keys = $Defaults.Keys
          foreach ($Key in $default_keys) {  
            if ($ParamOption.Keys -notcontains $Key) {  
              $null = $ParamOption.Add($Key, $Defaults[$Key]) 
            } 
          }
          #$ParamOption = @{FontWeight=$FontWeight}
        }
        $paramOption_keys = $ParamOption.keys
      
        #Select all the parameters, create the textelement property it applies to and then apply the property value to our previously selected text
        foreach ($param in $paramOption_keys)
        {
          $SelectedParam = $param  
          if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}  
          elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}  
          elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}  
          elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}  
          elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
          #$RichTextRange2.ApplyPropertyValue($TextElement, $ParamOption[$SelectedParam]) 
        }
      },
    "Normal")  
  }
}
#---------------------------------------------- 
#endregion Update-HelpFlyout Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-LogWindow','Update-HelpFlyout')