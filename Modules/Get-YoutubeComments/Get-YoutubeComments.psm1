<#
    .Name
    Get-YoutubeComments

    .Version 
    0.1.0

    .SYNOPSIS
    Processes comments from Youtube API and adds to treeview UI

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
#region Get-YoutubeComments Function
#----------------------------------------------
function Get-YoutubeComments
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$use_Runspace,
    [switch]$Quick_Refresh,
    [switch]$Full_Refresh,
    [string]$Youtube_VID,
    $synchash,
    $thisApp
  )
  
  try{
    if($Quick_Refresh){     
      if($syncHash.Comments_TreeView.Itemssource){
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_TreeView' -Property 'Itemssource' -Method 'refresh'
      }    
      return
    }
    if($use_Runspace){
      try{
        $null = Stop-Runspace -thisApp $thisApp -runspace_name 'Get_YoutubeComments_RUNSPACE' -force
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace 'Get_YoutubeComments_RUNSPACE'" -showtime -catcherror $_
      }
    }
    $synchash.Comments_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
    if($syncHash.Comments_TreeView.Nodes -is [System.IDisposable]){
      Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_TreeView' -Property 'Nodes' -Method 'dispose'
    }
    $Get_Comments_ScriptBlock = {
      param (
        [switch]$Clear = $clear,
        [switch]$Startup = $Startup,
        [switch]$use_Runspace = $use_Runspace,
        [switch]$Quick_Refresh = $Quick_Refresh,
        [switch]$Full_Refresh = $Full_Refresh,
        [string]$Youtube_VID = $Youtube_VID,
        $synchash = $synchash,
        $thisApp = $thisApp
      )
      try{  
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Total' -Property 'Text' -value '' -NullValue
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Total' -Property 'Visibility' -value 'Collapsed'
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Progress_Ring' -Property 'IsActive' -value $true
        if($Youtube_VID){   
          try{
            $Get_comments_Measure = [system.diagnostics.stopwatch]::StartNew() 
            write-ezlogs ">>>> Checking for Youtube comments for video id: $Youtube_VID" 
            $comments = Get-YouTubeCommentThread -Id $Youtube_VID
            if($Get_comments_Measure){
              $Get_comments_Measure.stop()
            }
            if($comments){
              write-ezlogs "| Found $($comments.count) Youtube comments"
              $Comments | sort-object -property @{e={$_.snippet.topLevelComment.snippet.likeCount}} -Descending | & { process { 
                  $parentNOde = [Syncfusion.UI.Xaml.TreeView.Engine.TreeViewNode]::new() 
                  if($_.snippet.topLevelComment.snippet.updatedAt){
                    $RelativeTime = Convertto-RelativeTime -Time ([datetime]$_.snippet.topLevelComment.snippet.updatedAt)
                  }elseif($_.snippet.topLevelComment.snippet.publishedAt){
                    $RelativeTime = Convertto-RelativeTime -Time ([datetime]$_.snippet.topLevelComment.snippet.publishedAt)
                  }else{
                    $RelativeTime = $Null
                  }
                  $cached_image = $_.snippet.topLevelComment.snippet.authorProfileImageUrl
                  if($cached_image){
                    $profileImage = $cached_image
                  }elseif($synchash.YoutubeMedia_PackIcon){
                    $profileImage = $synchash.YoutubeMedia_PackIcon
                  }else{
                    $profileImage = $Null
                  }
                  $parentnode.Content = [PSCustomObject]@{
                    'textDisplay' = [string]$_.snippet.topLevelComment.snippet.textOriginal
                    'authorProfileImage' = $cached_image
                    'authorDisplayName' = $_.snippet.topLevelComment.snippet.authorDisplayName
                    'likeCount' = "$($_.snippet.topLevelComment.snippet.likeCount)"
                    'videoId' = $_.snippet.topLevelComment.snippet.videoId
                    'Id' = $_.id
                    'MaxWidth' = '400'
                    'repliesCount' = $_.snippet.totalReplyCount
                    'updatedAt' = $RelativeTime
                  }
                  <#                  $parentnode.Content = [PSCustomObject]::new(@{
                      'textDisplay' = [string]$_.snippet.topLevelComment.snippet.textOriginal
                      'authorProfileImage' = ''
                      'authorDisplayName' = $_.snippet.topLevelComment.snippet.authorDisplayName
                      'likeCount' = "$($_.snippet.topLevelComment.snippet.likeCount)"
                      'videoId' = $_.snippet.topLevelComment.snippet.videoId
                      'Id' = $_.id
                      'MaxWidth' = '400'
                      'repliesCount' = $_.snippet.totalReplyCount
                      'updatedAt' = $RelativeTime
                  })#>
                  if($_.replies.comments.snippet){
                    $_.replies.comments.snippet | & { process { 
                        if($_.updatedAt){
                          $RelativeTime = Convertto-RelativeTime -Time ([datetime]$_.updatedAt)
                        }elseif($_.publishedAt){
                          $RelativeTime = Convertto-RelativeTime -Time ([datetime]$_.publishedAt)
                        }else{
                          $RelativeTime = $Null
                        }
                        <#                        $cached_image = $_.authorProfileImageUrl
                            if($cached_image){
                            $profileImage = $cached_image
                            }elseif($synchash.YoutubeMedia_PackIcon){
                            $profileImage = $synchash.YoutubeMedia_PackIcon
                            }else{
                            $profileImage = $Null
                        }#>
                        $childNOde = [Syncfusion.UI.Xaml.TreeView.Engine.TreeViewNode]::new()
                        $childNOde.Content = [PSCustomObject]@{
                          'textDisplay' = [string]$_.textOriginal
                          'authorProfileImage' = ''
                          'authorDisplayName' = $_.authorDisplayName
                          'likeCount' = "$($_.likeCount)"
                          'videoId' = $_.videoId
                          'Id' = $_.id
                          'updatedAt' = $RelativeTime
                        }
                        [void]$parentNOde.ChildNodes.add($childNOde)
                    }}
                  }
                  Update-YoutubeComments -synchash $synchash -thisApp $thisApp -itemssource $parentNOde -UpdateItemssource
              }}
              Update-YoutubeComments -synchash $synchash -thisApp $thisApp -RefreshView
            }else{
              write-ezlogs "No comments found for Youtube video id: $Youtube_VID"
            }            
            if($Process_Comments_Measure){
              $Process_Comments_Measure.stop()                
            }
            if($synchash.Comments_Progress_Ring){
              Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Progress_Ring' -Property 'IsActive' -value $false
            }              
          }catch{
            write-ezlogs "An exception occurred processing Youtube Comments" -showtime -catcherror $_
            if($synchash.Comments_Progress_Ring){
              Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Progress_Ring' -Property 'IsActive' -value $false
            }
          }
        }elseif($synchash.Comments_Progress_Ring){
          write-ezlogs "Cannot process Youtube comments, no Youtube video id provided!" -warning
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Comments_Progress_Ring' -Property 'IsActive' -value $false
        }
        if($Get_Comments_Measure){
          write-ezlogs ">>>> YoutubeComments Measure" -Perf -PerfTimer $Get_comments_Measure
          $Get_Comments_Measure = $Null   
        }
        if($Process_comments_Measure){
          write-ezlogs " | Process YoutubeComments Measure" -Perf -PerfTimer $Process_comments_Measure
          $Process_Comments_Measure = $Null
        } 
      }catch{
        write-ezlogs "An exception occurred in Get_comments_ScriptBlock" -CatchError $_
        if($synchash.Comments_Progress_Ring){
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $false
        }
      }
    }
    if($use_Runspace){
      $keys = $PSBoundParameters.keys
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
      Start-Runspace -scriptblock $Get_Comments_ScriptBlock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Get_YoutubeComments_RUNSPACE' -thisApp $thisApp -synchash $synchash -ApartmentState STA
      Remove-Variable Variable_list
    }else{
      Invoke-Command -ScriptBlock $Get_Comments_ScriptBlock
      if($Get_Comments_Measure){
        $Get_Comments_Measure.stop()
        write-ezlogs "Get-YoutubeComments Measure" -Perf -PerfTimer $Get_Comments_Measure
        $Get_Comments_Measure = $Null 
      } 
    } 
  }catch{
    write-ezlogs "An exception occurred in Get-YoutubeComments" -catcherror $_
  }
}

#---------------------------------------------- 
#endregion Get-YoutubeComments Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-YoutubeComments Function
#----------------------------------------------
function Update-YoutubeComments {
  Param (
    $synchash,
    $thisApp,
    $itemssource,
    [switch]$UpdateItemssource,
    [switch]$Add,
    [switch]$Sort,
    [switch]$RefreshView,
    [switch]$use_Runspace,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    if($Startup){
      try{
        $synchash.Comments_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
        if($synchash.Comments_TreeView){
          $synchash.Comments_TreeView.add_QueryNodeSize({
              Param($Sender,[Syncfusion.UI.Xaml.TreeView.QueryNodeSizeEventArgs]$e)
              try{
                $e.Height = $e.GetAutoFitNodeHeight()
                $e.Handled = $true
              }catch{
                write-ezlogs "An exception occurred in Comments_TreeView.add_QueryNodeSize" -catcherror $_
              }
          }) 
          $synchash.Comments_TreeView.add_SizeChanged({
              Param($Sender,[System.Windows.SizeChangedEventArgs]$e)
              try{
                if($e.NewSize.Width -gt 0){
                  $synchash.Comments_TreeView.tag = $synchash.chat_column.ActualWidth - 50
                }
                $e.Handled = $true
              }catch{
                write-ezlogs "An exception occurred in Comments_TreeView.add_SizeChanged" -catcherror $_
              }
          })           
          if($synchash.Refresh_Comments_Button){
            $synchash.Refresh_Comments_Button.add_Click({
                try{                   
                  if($synchash.Current_Playing_media.id -and ($synchash.Current_Playing_media.url -match 'youtube\.com|youtu\.be' -and $synchash.Current_Playing_media.url -notmatch 'tv\.youtube\.com')){    
                    if($synchash.Youtube_webplayer_current_Media.Video_id){
                      $YoutubeID = $synchash.Youtube_webplayer_current_Media.Video_id
                    }else{
                      $YoutubeID = $synchash.Current_Playing_media.id
                    }
                    write-ezlogs ">>>> Refreshing comments for youtube video with id: $($YoutubeID) -- url: $($synchash.Current_Playing_media.url)"
                    Update-ChatView -synchash $synchash -thisApp $thisApp -Navigate -Youtube_ID $YoutubeID -show
                  }else{
                    write-ezlogs "Can't refresh comments, current playing media is not youtube - id: $($synchash.Current_Playing_media.id) -- url: $($synchash.Current_Playing_media.url)" -warning
                  }                                    
                }catch{
                  write-ezlogs "An exception occurred in Refresh_Comments_Button.add_Click" -catcherror $_
                }
            })
          }
        }
        if($thisApp.Config.Dev_mode){
          $synchash.ImageDownload_Failed_Event = {
            Param($Sender,[System.windows.Media.ExceptionEventArgs]$e)
            try{
              write-ezlogs "Image download Failed - Source: $($e.ErrorException.Source) - Exception: $($e.ErrorException | out-string)" -Warning
            }catch{
              write-ezlogs "An exception occurred in ImageDownload_Failed_Event" -catcherror $_
            }
          }
        }

        if($synchash.Close_Comments_Button){
          [System.Windows.RoutedEventHandler]$synchash.Close_Comments_Command = {
            param($sender,[System.Windows.RoutedEventArgs]$e)
            try {
              if($synchash.Comments_TreeView.Nodes -is [System.IDisposable]){
                $count = 0
                foreach($node in $synchash.Comments_TreeView.Nodes){
                  if($node.Content.authorProfileImage -is [System.Windows.Media.Imaging.BitmapImage]){
                    $count++
                    if($synchash.ImageDownload_Failed_Event){$node.Content.authorProfileImage.Remove_DownloadFailed($synchash.ImageDownload_Failed_Event)}
                    $node.Content.authorProfileImage = $Null
                  }
                  [void]$node.dispose()
                }
                [void]$synchash.Comments_TreeView.Nodes.dispose()
              }
              write-ezlogs "| Disposed $($count) Comments_TreeView.Nodes"
              Update-ChatView -synchash $synchash -thisApp $thisApp -sender $sender -hide
            } catch {
              write-ezlogs "An exception occurred in Close_Comments_Button.add_Click" -catcherror $_
            }
          }
          $synchash.Close_Comments_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Close_Comments_Command)
        }
        <#      $synchash.Comments_ImageFreeze_Timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
            $synchash.Comments_ImageFreeze_Timer.add_tick({
            try{
            if($this.tag.CanFreeze){
            $this.tag.freeze()
            }               
            }catch{
            write-ezlogs "An exception occurred in ImageDownload_Completed_Event" -catcherror $_
            }finally{
            $this.stop()
            $this.tag = $Null
            }
            })
            $synchash.ImageDownload_Completed_Event = {
            Param($Sender,[System.EventArgs]$e)
            try{
            if($sender.CanFreeze){
            $synchash.Comments_ImageFreeze_Timer.tag = $sender
            $synchash.Comments_ImageFreeze_Timer.start()
            }               
            }catch{
            write-ezlogs "An exception occurred in ImageDownload_Completed_Event" -catcherror $_
            }finally{
            $sender.Remove_DownloadCompleted($synchash.ImageDownload_Completed_Event)
            $sender.Remove_DownloadCompleted($synchash.ImageDownload_Failed_Event)
            }
        }#>
        $synchash.Comments_Update_Timer_Tick = {
          try{  
            $synchash = $synchash
            $thisApp = $thisApp  
            $object = @{}
            if($synchash.Comments_UpdateQueue){
              $Process = $synchash.Comments_UpdateQueue.TryDequeue([ref]$object)
            }
            if($Process -and $object.ProcessObject -and (-not [string]::IsNullOrEmpty($object.Itemssource) -and $object.UpdateItemssource)){
              if($syncHash.Comments_TreeView){
                if($object.Itemssource.Content.authorProfileImage){
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  #$image.Add_DownloadCompleted($synchash.ImageDownload_Completed_Event)
                  if($thisApp.Config.Dev_mode){$image.Add_DownloadFailed($synchash.ImageDownload_Failed_Event)}
                  $image.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                  $image.DecodePixelWidth = 25
                  $image.BeginInit()
                  $image.UriSource = $object.Itemssource.Content.authorProfileImage
                  $cached_image = [System.Windows.Media.Imaging.BitmapImage]$image
                  $object.Itemssource.Content.authorProfileImage = $cached_image
                  $image.EndInit()
                }
                $syncHash.Comments_TreeView.nodes.add($object.Itemssource)
                $image = $Null
                try{
                  $Total = "$($synchash.Comments_TreeView.Nodes.count) Comments"         
                  if($synchash.Comments_Total -and $synchash.Comments_Total.Text -ne $Total){
                    $synchash.Comments_Total.Visibility = 'Visible'
                    $synchash.Comments_Total.Text = $Total
                  }                                   
                }catch{
                  write-ezlogs "An exception occurred updating Comments_Total" -catcherror $_
                }
              }else{
                write-ezlogs "No Comments_Treeview UI is available" -warning
              }              
            }elseif($Process -and $object.ProcessObject -and $object.sort){
              $array = [System.Collections.Generic.List[Object]]::new()
              $syncHash.Comments_TreeView.nodes | sort-object -property @{e={$_.content.snippet.topLevelComment.snippet.likeCount}} -Descending | & { process {
                  [void]$array.add($_)
              }}
              if($syncHash.Comments_TreeView.Nodes -is [System.IDisposable]){
                $syncHash.Comments_TreeView.Nodes.dispose()
              }
              foreach($node in $array){
                [void]$syncHash.Comments_TreeView.nodes.add($node)
              }
            }elseif($Process -and $object.ProcessObject -and $object.RefreshView){
              $refreshView = $synchash.Comments_TreeView.GetType().GetMethod("RefreshView", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
              if($refreshView){
                write-ezlogs "| Invoking RefreshView for Comments_TreeView" -Dev_mode
                $refreshView.Invoke($syncHash.Comments_TreeView,$Null)
              }
            }else{
              $this.Stop()
            }            
          }catch{
            $this.Stop()
            write-ezlogs "An exception occurred in Comments_Update_Timer_Tick" -showtime -catcherror $_
          }
        }
      }catch{
        write-ezlogs "An exception occurred updating Comments_treeview" -showtime -catcherror $_
      }
      $synchash.Comments_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
      $synchash.Comments_Update_Timer.add_tick($synchash.Comments_Update_Timer_Tick)
    }elseif($itemssource -or $UpdateItemssource -or $RefreshView){
      if($synchash.Comments_UpdateQueue){
        [void]$synchash.Comments_UpdateQueue.Enqueue([PSCustomObject]::new(@{
              'Itemssource' = $itemssource
              'ProcessObject' = $true
              'Sort' = $Sort
              'RefreshView' = $RefreshView
              'UpdateItemssource' = $UpdateItemssource
        })) 
      }
      if(!$synchash.Comments_Update_Timer.isEnabled){
        $synchash.Comments_Update_Timer.start()
      }
      return
    }
  }catch{
    write-ezlogs "An exception occurred in Update-YoutubeComments" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-YoutubeComments Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-YoutubeComments','Update-YoutubeComments')