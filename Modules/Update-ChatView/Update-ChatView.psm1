<#
    .Name
    Update-ChatView

    .Version 
    0.1.0

    .SYNOPSIS
    Provides controls for opening, closing, intializing and other functions for Twitch Chat View

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
#region Update-ChatView Function
#----------------------------------------------
function Update-ChatView
{
  [CmdletBinding()]
  Param (
    $synchash,
    $sender,
    $thisApp = $thisApp,
    [string]$ChatView_URL = $synchash.ChatView_URL,
    [string]$Youtube_ID,
    [switch]$Show,
    [switch]$Hide,
    [switch]$Reload,
    [switch]$Disable,
    [switch]$Navigate,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      if($synchash.chat_column){
        $synchash.chat_column.Width = '0'
      }
      if($synchash.Chat_Icon){
        $synchash.Chat_Icon.Kind = 'Chat'
      }
      $synchash.ChatView_ShowStoryboard = [System.Windows.Media.Animation.Storyboard]::new()
      $synchash.ChatView_ShowAnimation = [WpfExtensions.GridLengthAnimation]::new()
      $null = $synchash.ChatView_ShowStoryboard.addChild($synchash.ChatView_ShowAnimation)
      [EventHandler]$synchash.ChatView_ShowStoryboard_Completed = {
        Param($Sender,[EventArgs]$e)
        try{
          if($synchash.Chat_Splitter_Value -gt 0){
            $Width = $synchash.Chat_Splitter_Value
          }else{
            $Width = "75*"
          }
          write-ezlogs "Chat_Column animation completed to width: $($Width)" -Dev_mode
          $synchash.chat_column.BeginAnimation([Windows.Controls.ColumnDefinition]::WidthProperty,$null)
          $synchash.chat_column.Width = $Width
          $synchash.chat_column.MinWidth="380"
          if($synchash.chat_column.ActualWidth -gt 0){
            $synchash.Comments_TreeView.Tag = $synchash.chat_column.ActualWidth - 50
          }                  
        }catch{
          write-ezlogs "An exception occurred in VideoViewstoryboard" -catcherror $_
        }finally{
          $Sender.Remove_Completed([EventHandler]$synchash.ChatView_ShowStoryboard_Completed)
        }
      }
      [EventHandler]$synchash.ChatView_HideStoryboard_Completed = {
        Param($Sender,[EventArgs]$e)
        try{
          $synchash.chat_column.BeginAnimation([Windows.Controls.ColumnDefinition]::WidthProperty,$null)
          $synchash.chat_column.MinWidth="0"
          $synchash.chat_column.Width = '0'
        }catch{
          write-ezlogs "An exception occurred in VideoViewstoryboard" -catcherror $_
        }finally{
          $Sender.Remove_Completed([EventHandler]$synchash.ChatView_HideStoryboard_Completed)
        }
      }
      $null = [Windows.Media.Animation.Storyboard]::SetTargetProperty($synchash.ChatView_ShowStoryboard,"(Width)")
      $null = [Windows.Media.Animation.Storyboard]::SetTarget($synchash.ChatView_ShowStoryboard,$synchash.chat_column)
      $synchash.ChatView_UpdateQueue = [Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $synchash.ChatView_timer = [Windows.Threading.DispatcherTimer]::new([Windows.Threading.DispatcherPriority]::Normal)
      $synchash.ChatView_timer.add_tick({
          try{ 
            $synchash = $synchash
            $thisApp = $thisApp 
            $object = @{}
            $Process = $synchash.ChatView_UpdateQueue.TryDequeue([ref]$object)
            if($Process -and $object){
              if($object.Navigate -and $object.Youtube_ID -and $thisApp.Config.Enable_YoutubeComments){
                $synchash.Chat_View_Button.ToolTip="Comments View" 
                $synchash.Chat_Icon.Kind="Chat"
                $synchash.Chat_View_Button.Opacity='1'           
                $synchash.Chat_View_Button.IsEnabled = $true
                Get-YoutubeComments -synchash $synchash -thisApp $thisApp -Youtube_VID $object.Youtube_ID -use_Runspace
              }elseif($object.Navigate -and (Test-URL $object.ChatView_URL)){
                $synchash.Chat_View_Button.ToolTip="Chat View" 
                $synchash.Chat_Icon.Kind="Chat"
                $synchash.Chat_View_Button.Opacity='1'
                $synchash.Chat_View_Button.IsEnabled = $true   
                if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
                  write-ezlogs "[ChatView_Timer] Navigating with CoreWebView2.Navigate: $($synchash.ChatView_URL)" -enablelogs -Color cyan -showtime
                  $syncHash.chat_WebView2.CoreWebView2.Navigate($synchash.ChatView_URL)
                }
                else{
                  Initialize-ChatView -synchash $synchash -thisApp $thisApp
                }              
              }
              if($object.Show){
                write-ezlogs "[ChatView_Timer] >>>> Showing Chat View" -loglevel 2
                $synchash.Chat_Icon.Kind = 'ChatRemove'
                #$synchash.chat_column.Width="70*"
                if($synchash.Chat_Splitter_Value -gt 0){
                  $synchash.ChatView_ShowAnimation.to = $synchash.Chat_Splitter_Value
                }else{
                  $synchash.ChatView_ShowAnimation.to = "75*"
                }              
                $synchash.ChatView_ShowAnimation.Duration = '0:0:0.2'
                $synchash.ChatView_ShowStoryboard.Remove_Completed([EventHandler]$synchash.ChatView_ShowStoryboard_Completed)
                $synchash.ChatView_ShowStoryboard.Add_Completed([EventHandler]$synchash.ChatView_ShowStoryboard_Completed)
                $synchash.ChatView_ShowStoryboard.Begin($synchash.chat_column,[Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace,$true)
                $synchash.Chat_View_Button.isChecked = $true
                if($object.sender.Header){
                  $object.sender.Header = 'Close Chat View'
                  if($object.sender.icon.kind){
                    $object.sender.icon.kind = 'ChatRemove'
                  }        
                }
                $thisApp.Config.Chat_View = $true
                if($object.ChatView_URL -and $synchash.chat_WebView2.Visibility -eq 'Hidden'){
                  $synchash.chat_WebView2.Visibility = 'Visible'
                  if($synchash.Comments_Grid.Visibility -eq 'Visible'){
                    $synchash.Comments_Grid.Visibility = 'Hidden'
                  }
                }elseif($synchash.Comments_Grid.Visibility -eq 'Collapsed'){
                  $synchash.Comments_Grid.Visibility = 'Visible'
                  if($synchash.chat_WebView2.Visibility -eq 'Visible'){
                    $synchash.chat_WebView2.Visibility = 'Hidden'
                  }               
                }
              }
              if($object.Reload -and -not [string]::IsNullOrEmpty($synchash.chat_WebView2.CoreWebView2)){
                if(-not [string]::IsNullOrEmpty($synchash.chat_WebView2.CoreWebView2)){
                  write-ezlogs "[ChatView_Timer] >>>> Reloading chat_WebView2.CoreWebView2" -logtype Webview2
                  $synchash.chat_WebView2.Reload()                                                     
                }else{
                  write-ezlogs "[ChatView_Timer] Unable to Reload chat view, chat_webview2 is not initialized!" -loglevel 2 -warning
                }
              }elseif($object.Reload -and -not [string]::IsNullOrEmpty($syncHash.Comments_TreeView.Nodes)){
                write-ezlogs "[ChatView_Timer] [NOT_IMPLEMENTED]>>>> Reloading Comments_TreeView.Nodes" -logtype Webview2
            
              }            
              if($object.Hide){
                write-ezlogs "[ChatView_Timer] >>>> Hiding Chat View" -loglevel 2
                $synchash.Chat_View_Button.isChecked = $false
                $synchash.Chat_Icon.Kind = 'Chat'
                #$synchash.chat_column.Width="0"
                $synchash.ChatView_ShowAnimation.to = "0"
                $synchash.ChatView_ShowAnimation.Duration = '0:0:0.2'
                $synchash.ChatView_ShowStoryboard.Remove_Completed([EventHandler]$synchash.ChatView_HideStoryboard_Completed)
                $synchash.ChatView_ShowStoryboard.Add_Completed([EventHandler]$synchash.ChatView_HideStoryboard_Completed)
                $synchash.ChatView_ShowStoryboard.Begin($synchash.chat_column,[Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace,$true)
                if($object.sender.Header){
                  $object.sender.Header = 'Open Chat View'
                  if($object.sender.icon.kind){
                    $object.sender.icon.kind = 'Chat'
                  }        
                }
                if($synchash.Comments_Grid.Visibility -eq 'Visible'){
                  $synchash.Comments_Grid.Visibility = 'Collapsed'
                }else{
                  write-ezlogs "[ChatView_Timer] Comments_Grid is already Hidden" -loglevel 2 -warning -Dev_mode
                }
                if($synchash.chat_WebView2.Visibility -eq 'Visible'){
                  $synchash.chat_WebView2.Visibility = 'Hidden'
                }else{
                  write-ezlogs "[ChatView_Timer] Chat_WebView2 is already Hidden" -loglevel 2 -warning -Dev_mode
                }
              }             
              if($object.Disable){
                try{
                  write-ezlogs "[ChatView_Timer] >>>> Disabling Chat View" -loglevel 2
                  $synchash.Chat_View_Button.IsEnabled = $false
                  $synchash.Chat_View_Button.isChecked = $false
                  $synchash.Chat_Icon.Kind="Chat"
                  $synchash.Chat_View_Button.Opacity='0.7'
                  $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
                  if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
                    write-ezlogs "[ChatView_Timer] >>>> Disposing Chat_Webview2 instance"
                    $synchash.chat_WebView2.Visibility = 'Hidden'
                    $synchash.chat_WebView2.dispose()
                    $synchash.chat_WebView2 = $Null
                  }
                  if($syncHash.Comments_TreeView){
                    try{
                      $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Get_YoutubeComments_RUNSPACE' -force
                    }catch{
                      write-ezlogs " An exception occurred checking for existing runspace 'Get_YoutubeComments_RUNSPACE'" -showtime -catcherror $_
                    }
                    $syncHash.Comments_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemsProperty)
                    $syncHash.Comments_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemProperty)
                    $Null = [Windows.Data.BindingOperations]::ClearAllBindings($syncHash.Comments_TreeView)
                    $syncHash.Comments_TreeView.Itemssource = $Null
                    if($synchash.Comments_TreeView.Nodes.count -gt 0 -and $synchash.Comments_TreeView.Nodes -is [System.IDisposable]){
                      $count = 0
                      foreach($node in $synchash.Comments_TreeView.Nodes){
                        if($node.Content.authorProfileImage -is [Windows.Media.Imaging.BitmapImage] -and $synchash.ImageDownload_Failed_Event){
                          if($synchash.ImageDownload_Failed_Event){
                            $node.Content.authorProfileImage.Remove_DownloadFailed($synchash.ImageDownload_Failed_Event)
                          }
                        }
                        $count++
                        $Null = $node.dispose()
                      }
                      $null = $synchash.Comments_TreeView.Nodes.dispose()
                      write-ezlogs "[ChatView_Timer] >>>> Disposed $($count) nodes in Comments_TreeView"
                    }            
                    $synchash.Comments_Grid.Visibility = 'Collapsed'
                  }
                }catch{
                  write-ezlogs "An exception occurred disabling chat view" -showtime -catcherror $_
                }
              }
            }else{
              $this.Stop()
            }
          }catch{
            $this.Stop()
            write-ezlogs "An exception occurred in ChatView_timer.add_tick" -showtime -catcherror $_
          }
      }) 
    }else{
      [void]$synchash.ChatView_UpdateQueue.Enqueue([PSCustomObject]::new(@{
            'ChatView_URL' = $ChatView_URL
            'Navigate' = $Navigate
            'Reload' = $Reload
            'Youtube_ID' = $Youtube_ID
            'Show' = $Show
            'Hide' = $Hide
            'Sender' = $Sender
            'Disable' = $Disable
      }))
      if(!$synchash.ChatView_timer.isEnabled){
        $synchash.ChatView_timer.start()
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Update-ChatView" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Update-ChatView Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-ChatView')