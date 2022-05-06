<#
    .Name
    Show-FeedbackForm 

    .Version 
    0.0.1

    .SYNOPSIS
    Displays a window to capture feedback/issues for submission to developer

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
# Mahapps Library
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
Add-Type -AssemblyName WindowsFormsIntegration

function Close-FeedbackForm (){
  $hashfeedback.window.Dispatcher.Invoke("Normal",[action]{ $hashfeedback.window.close()})
  
}



#---------------------------------------------- 
#region Open-FileDialog Function
#----------------------------------------------
function Open-FileDialog
{
  param (
    [string]$Title = "Select file",
    [switch]$MultiSelect
  )  
  $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
  $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.AddExtension = $true
  #$OpenFileDialog.InitialDirectory = [environment]::getfolderpath('mydocuments')
  $OpenFileDialog.CheckFileExists = $true
  $OpenFileDialog.Multiselect = $MultiSelect
  $OpenFileDialog.Filter = "All Files (*.*)|*.*"
  $OpenFileDialog.CheckPathExists = $false
  $OpenFileDialog.Title = $Title
  $results = $OpenFileDialog.ShowDialog()
  if ($results -eq [System.Windows.Forms.DialogResult]::OK) 
  {
    Write-Output $OpenFileDialog.FileNames
  }
}
#---------------------------------------------- 
#endregion Open-FileDialog Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-FeedbackForm Function
#----------------------------------------------
function Show-FeedbackForm{
  Param (
    [string]$PageTitle,
    [string]$Splash_More_Info,
    [string]$Logo,
    $thisScript,
    $thisApp,
    $synchash,
    [string]$all_games_profile_path,
    $Platform_launchers,
    $Save_GameSessions,
    $all_installed_games,
    [string]$Game_Profile_Directory,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog,
    [switch]$Export_Profile,
    [switch]$update_global
  )  

  $global:hashfeedback = [hashtable]::Synchronized(@{})  
  $Global:Current_Folder = $($thisScript.path | Split-path -Parent)
  if(!(Test-Path "$Current_Folder\\Views")){
    $Global:Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
  }
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $pattern3 = "[`?�™$illegal]"     
  $feedback_Pwshell = {
    try{
      [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
      Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
      $add_Window_XML = "$($Current_Folder)\\Views\\FeedbackForm.xaml"
      if(!(Test-Path $add_Window_XML)){
        $Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
        $add_Window_XML = "$($Current_Folder)\\Views\\FeedbackForm.xaml"
      }
      [xml]$xaml = Get-content "$($Current_Folder)\\Views\\FeedbackForm.xaml" -Force
      if($Verboselog){write-ezlogs ">>>> Script path: $($Current_Folder)\\Views\\FeedbackForm.xaml" -showtime -enablelogs -Color cyan}
      $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    
      $hashfeedback.Window=[Windows.Markup.XamlReader]::Load($reader)

      [xml]$XAML = $xaml
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {   
        $hashfeedback."$($_.Name)" =  $hashfeedback.Window.FindName($_.Name)  
      }  
    }
    catch
    {
      write-ezlogs "An exception occurred when loading xaml -- $_" -CatchError
      
    }      
    $hashfeedback.Logo.Source=$Logo
    $hashfeedback.Window.title =$PageTitle
    $hashfeedback.PageNotes.text = "NOTE: A copy of the log file ($($thisApp.Config.Log_file)) will automatically be included with your submission"
    $hashfeedback.PageNotes.FontStyle="Italic"
    $hashfeedback.Feedback_Subject_textbox.Add_TextChanged({
        if($hashfeedback.Feedback_Subject_textbox.text -eq "")
        {
          $hashfeedback.Feedback_Subject_Label.BorderBrush = "Red"
        }       
        else
        {          
          $hashfeedback.Feedback_Subject_Label.BorderBrush = "Green"
        }
    })  
    $hashfeedback.Feedback_Details.Add_TextChanged({
        if($hashfeedback.Feedback_Details.document.blocks.inlines.text -eq "")
        {
          $hashfeedback.Feedback_Details_Label.BorderBrush = "Red"
        }       
        else
        {          
          $hashfeedback.Feedback_Details_Label.BorderBrush = "Green"
        }
    })      
    $hashfeedback.Feedback_ComboBox.add_SelectionChanged({
        if($hashfeedback.Feedback_ComboBox.selectedindex -eq -1)
        {
          $hashfeedback.FeedBack_Category.BorderBrush = "Red"
        }       
        else
        {
          $hashfeedback.FeedBack_Category.BorderBrush = "Green"
        }      
    })  
    $hashfeedback.File_Path_Browse.add_click({
        $File_Path_Browse = Open-FileDialog -Title "Select a file to include with your submission (Ex: Screenshot..etc)" -Multiselect
        write-ezlogs "Selected Path: $($File_Path_Browse)" -showtime -color cyan
        #$File_Path_Browse = $File_Path_Browse -join ","
        if(-not [string]::IsNullOrEmpty($File_Path_Browse)){
          $hashfeedback.File_Path_textbox.text = $File_Path_Browse
        }
    }) 
    $hashfeedback.File_Path_textbox.Add_TextChanged({
        if($hashfeedback.File_Path_textbox.text -eq "")
        {
          $hashfeedback.File_Path_Label.BorderBrush = "Orange"
        }       
        elseif([System.IO.File]::Exists($hashfeedback.File_Path_textbox.text))
        {          
          $hashfeedback.File_Path_Label.BorderBrush = "Green"
        }
        elseif(![System.IO.File]::Exists($hashfeedback.File_Path_textbox.text))
        {
          $hashfeedback.File_Path_Label.BorderBrush = "Red"
        }
    })          
    #Update-EditorHelp  
    function update-EditorHelp{    
      param (
        [string]$content,
        [string]$color = "White",
        [string]$FontWeight = "Normal",
        [string]$FontSize = 14,
        [string]$BackGroundColor = "Transparent",
        [string]$TextDecorations,
        [ValidateSet('Underline','Strikethrough','Underline, Overline','Overline','baseline','Strikethrough,Underline')]
        [switch]$AppendContent,
        [switch]$MultiSelect,
        [System.Windows.Controls.RichTextBox]$RichTextBoxControl = $hashfeedback.EditorHelpFlyout
      ) 
      #$hashfeedback.Editor_Help_Flyout.Document.Blocks.Clear()  
      $Paragraph = New-Object System.Windows.Documents.Paragraph
      $RichTextRange = New-Object System.Windows.Documents.Run               
      $RichTextRange.Foreground = $color
      $RichTextRange.FontWeight = $FontWeight
      $RichTextRange.FontSize = $FontSize
      $RichTextRange.Background = $BackGroundColor
      $RichTextRange.TextDecorations = $TextDecorations
      $RichTextRange.AddText($content)
      $Paragraph.Inlines.add($RichTextRange)
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
             
    #---------------------------------------------- 
    #region Apply Settings Button
    #----------------------------------------------
    $hashfeedback.Submit_Button.add_Click({
        try{           
          $RichTextRange2 = New-Object System.Windows.Documents.textrange($hashfeedback.Feedback_Details.Document.ContentStart, $hashfeedback.Feedback_Details.Document.ContentEnd)
          if(-not [string]::IsNullOrEmpty($RichTextRange2.text) -and -not [string]::IsNullOrEmpty($hashfeedback.Feedback_Subject_textbox.text) -and $hashfeedback.Feedback_ComboBox.selectedindex -ne -1 )
          {
            #submit feedback
            try{
              try
              {
                $email_settings = Import-Clixml "$($thisApp.Config.Current_folder)\\Resources\\Email\\365Mail.xml"
                $emailusername = $email_settings.EmailUser
                $encrypted = (Get-Content "$($thisApp.Config.Current_folder)\\Resources\\Email\\365Auth.txt" -ReadCount 0 -Force) | ConvertTo-SecureString
                $credential = New-Object System.Management.Automation.PsCredential($emailusername, $encrypted)
                $EmailFrom = $email_settings.EmailFrom
                $EmailTo = $email_settings.EmailTo
                $Smtpport = $email_settings.Smtpport
                $SMTPServer = $email_settings.SmtpServer 
              }
              catch
              {
                write-ezlogs "An exception occurred sending email to $EmailTo" -showtime -catcherror $_
                $emailstatus = "[ERROR] Sending email failed!"
                $notificationstatus = "[ERROR] An issue occurred while attempting to submit your feedback/issue! Please try again or contact support@eztechhelp.com"
                $emailcolor = "red"
              }
              if($credential){
                $Subject = "$($thisScript.Name) - $($thisScript.Version) - Feedback/Issue"  
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                # Create the email.
                Write-EZLogs "Creating email with SUBJECT ($subject) FROM ($EmailFrom) TO ($EmailTo)" -ShowTime
                $email = New-Object System.Net.Mail.MailMessage($EmailFrom , $EmailTo)
                $email.Subject = $Subject
                $email.IsBodyHtml = $true
                $email.Body = @"
<h2>This was submitted from the feedback/issue form of $($thisScript.Name)</h2><br>Version: $($thisScript.Version)<br>Date: $(Get-Date -Format $logdateformat)<br>User: $($env:username)<br>Computer: $($env:computername)<br><br><b>Category: </b> $($hashfeedback.Feedback_ComboBox.selecteditem.content)<br><b>Subject: </b> $($hashfeedback.Feedback_Subject_textbox.text)<br><b>Details: </b>$($RichTextRange2.text)
"@
                write-ezlogs "Sending email via $SmtpServer\:$Smtpport" -showtime 
                #endregion Attach HTML report
                if($thisApp.Config.Log_file)
                {
                  $emaillog =  [System.IO.Path]::Combine($env:temp, "$($thisScript.Name)-$($thisScript.Version)-EM.zip")
                  write-ezlogs -text "Attaching Log File ($emaillog)" -ShowTime
                  $null = copy-item $thisApp.Config.Log_file -Destination $emaillog -Force
                  Compress-Archive -LiteralPath $thisApp.Config.Log_file -DestinationPath $emaillog -Force 
                  Write-Output "[$(Get-Date -Format $logdateformat)] Sending Email...."  | Out-File -FilePath $emaillog -Encoding unicode -Append
                  Write-Output "###################### Logging Finished - [$(Get-Date -Format $logdateformat)] ######################`n" | Out-File -FilePath $emaillog -Encoding unicode -Append
                  start-sleep 1
                }                
                if([System.IO.File]::Exists($hashfeedback.File_Path_textbox.text)){
                  write-ezlogs -text "Attaching File $($hashfeedback.File_Path_textbox.text)" -ShowTime
                  Compress-Archive -LiteralPath $hashfeedback.File_Path_textbox.text -DestinationPath $emaillog -update                  
                }
                if($emaillog){
                  $email.attachments.add($emaillog)
                } 
                # Send the email.
                $SMTPClient=New-Object System.Net.Mail.SmtpClient( $SmtpServer , $SmtpPort )
                $SMTPClient.EnableSsl=$true
                $SMTPClient.Credentials = $credential
                try
                {
                  $SMTPClient.Send( $email )
                  $emailstatus = "[SUCCESS] Email successfuly sent!" 
                  $notificationstatus = "[SUCCESS] Your feedback/issue was successsfully submitted!"
                  $emailcolor = "green"
                }
                catch
                {
                  write-ezlogs "An exception occurred sending email to $EmailTo" -showtime -catcherror $_
                  $emailstatus = "[ERROR] Sending email failed!"
                  $notificationstatus = "[ERROR] An issue occurred while attempting to submit your feedback/issue! Please try again or contact support@eztechhelp.com"
                  $emailcolor = "red"
                }
                $email.Dispose();
                write-ezlogs $emailstatus -showtime -color:$emailcolor
                if($emaillog)
                {
                  $Null = Remove-item $emaillog -Force
                }
                Show-NotifyBalloon -Message $notificationstatus -Title 'FeedBack/Issue Submission' -TipIcon Info -Icon_path "$($current_folder)\\Resources\\MusicPlayerFill.ico"
              }else{
                write-ezlogs "[Show-FeedBackForm] Unable to get email credentials! Unable to send" -showtime -warning
                Show-NotifyBalloon -Message "[WARNING] Unable to send Feedback/Issue, invalid email credentials!" -Title 'FeedBack/Issue Submission' -TipIcon Warning -Icon_path "$($current_folder)\\Resources\\MusicPlayerFill.ico"
              }

              <#              $spotify_startapp = Get-startapps *mail
                  if($spotify_startapp){
                  $spotify_appid = $spotify_startapp.AppID
                  }else{
                  $spotify_appid = $Spotify_Path
              }  #>              
              #New-BurntToastNotification -AppID $spotify_appid -Text $Message -AppLogo $applogo
              
              #Update-Notifications -id 1 -Level 'Info' -Message $notificationstatus -VerboseLog -Message_color $emailcolor -thisApp $thisApp -synchash $synchash -open_flyout
              Remove-Variable -Name credential -Force
              Remove-Variable -Name SMTPClient -Force
              Remove-Variable -Name Subject -Force
              Remove-Variable -Name EmailFrom -Force
              Remove-Variable -Name EmailTo -Force
              Remove-Variable -Name emailusername -Force
              Remove-Variable -Name encrypted -Force
              Remove-Variable -Name email -Force
            }catch{
              write-ezlogs "An exception occurred sending email to $EmailTo" -showtime -catcherror $_
            }
            write-ezlogs "[FEEDBACK-SUBJECT] $($hashfeedback.Feedback_Subject_textbox.text)" -showtime -linesbefore 1           
            write-ezlogs "[FEEDBACK] $($RichTextRange2.text)" -showtime
            $hashfeedback.Save_setup_textblock.text = "Feedback submitted"
            $hashfeedback.Save_setup_textblock.foreground = "LightGreen"
            $hashfeedback.Save_setup_textblock.FontSize = 14     
            $hashfeedback.Feedback_ComboBox.selectedindex = -1    
            $hashfeedback.File_Path_textbox.text = ''  
            $hashfeedback.Feedback_Details.Document.Blocks.Clear()
            $hashfeedback.Feedback_Subject_textbox.clear()
          }
          else
          {
            #dont do anything
            write-ezlogs "[FEEDBACK] Nothing was entered..." -showtime
            $hashfeedback.Save_setup_textblock.text = "A required field is missing!"
            $hashfeedback.Save_setup_textblock.foreground = "Orange"
            $hashfeedback.Save_setup_textblock.FontSize = 14
          }                                      
        }catch{
          $hashfeedback.Save_setup_textblock.text = "An exception occurred when submiting -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
          $hashfeedback.Save_setup_textblock.foreground = "Tomato"
          $hashfeedback.Save_setup_textblock.FontSize = 14
          write-ezlogs "An exception occurred when when submiting" -CatchError $_ -showtime -enablelogs
        }
    })
    #---------------------------------------------- 
    #endregion Apply Settings Button
    #---------------------------------------------- 
  
    #---------------------------------------------- 
    #region Cancel Button
    #----------------------------------------------
    $hashfeedback.Cancel_Button.add_Click({
        try{          
          write-ezlogs ">>>> User choose to cancel feedback form...exiting" -showtime -enablelogs  
          Close-FeedbackForm                          
        }catch{
          $hashfeedback.Save_setup_textblock.text = "An exception occurred when submitting feedback -- `n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n"
          $hashfeedback.Save_setup_textblock.foreground = "Tomato"
          $hashfeedback.Save_setup_textblock.FontSize = 14
          write-ezlogs "An exception occurred when when submitting feedback" -CatchError $_ -showtime -enablelogs
        }
    })
    #---------------------------------------------- 
    #endregion Cancel Button
    #----------------------------------------------   
    $hashfeedback.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $hashfeedback.Window){        
          try{
            #if($Startup){
            write-ezlogs " Feedbackform closed" -showtime
            #$hashContext.ExitThread()
            #$hashContext.Dispose()
            return
            # }         
          }catch{
            write-ezlogs "An exception occurred closing Show-feedbackform" -showtime -catcherror $_
            return
          }
        }
          
    }.GetNewClosure())    

    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($hashfeedback.Window)
    [void][System.Windows.Forms.Application]::EnableVisualStyles()   
    try{
      if($firstRun){
        $hash.window.TopMost = $false
      }         
      $null = $hashfeedback.window.ShowDialog()
      $window_active = $hashfeedback.Window.Activate() 
      $hashfeedbackContext = New-Object System.Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($hashfeedbackContext)            
    }catch{
      write-ezlogs "An exception occurred when opening main Show-FeedbackForm window" -showtime -CatchError $_
    }       
  }
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}
  Start-Runspace $feedback_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisapp.config.log_file 
}
#---------------------------------------------- 
#endregion Show-FeedbackForm Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-FeedbackForm','Close-FeedbackForm')



  