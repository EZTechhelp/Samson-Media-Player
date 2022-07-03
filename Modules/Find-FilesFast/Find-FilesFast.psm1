<#
    .Name
    Find-FilesFast

    .Version 
    0.1.0

    .SYNOPSIS
    Plays provided media files within vlc controls  

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
#region Find-FilesFast Function
#----------------------------------------------
function Find-FilesFast{
  <#
      .SYNOPSIS
      V1.4
      Recursively scans a folder and subfolders looking for explicitly applied permissions.
     
      .DESCRIPTION
      Output is csv and can easily be imported into excel.

      .Notes
      CHANGE LOG:
      1.04 9/27/2013:
      - Fixed bug where scanning was not working recursively in some cases
      1.03 9/9/2013:
      - Fixed bug where app would crash if there were no permissions assigned to an object
      1.02 8/06/2013: 
      - Updated .net class that uses winapi calls to query folders/permissions that allows long folders to be used 
      - Added new switches
      1.01 8/06/2013: 
      - Added .net class that uses winapi calls to query folders/permissions that allows long folders to be used
      .PARAMETER $path
      Path to scan, must be valid

      .PARAMETER $LevelsDeep
      # of sub folders to scan

      .PARAMETER $output
      Determines where the output goes:
    
      Screen
      File
      notepad
    
      .PARAMETER $Progress
      # Displays a progress bar (slower)

      .EXAMPLE
      powershell.exe -file ".\get-folderperms.ps1" -path \\fmc103105\proj
      Launched from cmd prompt or scheduled task
     
      .EXAMPLE
      .\get-folderperms.ps1 -path \\fmc103105\proj -levelsdeep 5 -output notepad
      Scans the proj share of a server 5 levels deep and then opens results in notepad.

      .EXAMPLE
      .\get-folderperms.ps1 -path \\fmc9001209\proj -levelsdeep 3 -progress
      Scans the proj share of a server 3 levels deep and shows a progress bar
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    [string]
    $Path,
    [ValidateRange(2,100)] 
    [Int32]$LevelsDeep=2,
    [ValidateSet("file","screen","notepad")] 
    [string]$output="file",
    [switch]$Progress,
    [switch]$IncludeFileName,
    [switch]$IncludeServer
  )
$code = @"
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections.Generic
Imports System.Runtime.InteropServices
Imports System.ComponentModel

Public Class utlWin32_Perm
    Public Class ACE_Entry
        Private _Object_Name As String
        Public Property Object_Name() As String
            Get
                Return _Object_Name
            End Get
            Set(ByVal value As String)
                _Object_Name = value
            End Set
        End Property

        Private _Ace_Type As String
        Public Property Ace_Type() As String
            Get
                Return _Ace_Type
            End Get
            Set(ByVal value As String)
                _Ace_Type = value
            End Set
        End Property

        Private _Ace_Name As String
        Public Property Ace_Name() As String
            Get
                Return _Ace_Name
            End Get
            Set(ByVal value As String)
                _Ace_Name = value
            End Set
        End Property

        Private _Ace_Permission As String
        Public Property Ace_Permission() As String
            Get
                Return _Ace_Permission
            End Get
            Set(ByVal value As String)
                _Ace_Permission = value
            End Set
        End Property

        Private _Ace_Inherited As String
        Public Property Ace_Inherited() As String
            Get
                Return _Ace_Inherited
            End Get
            Set(ByVal value As String)
                _Ace_Inherited = value
            End Set
        End Property

        Private _Ace_Scope As String
        Public Property Ace_Scope() As String
            Get
                Return _Ace_Scope
            End Get
            Set(ByVal value As String)
                _Ace_Scope = value
            End Set
        End Property


        Private _Ace_PermissionMask_ As Integer
        Public Property Ace_PermissionMask() As Integer
            Get
                Return _Ace_PermissionMask_
            End Get
            Set(ByVal value As Integer)
                _Ace_PermissionMask_ = value
            End Set
        End Property

        Private _Ace_ObjectType As String
        Public Property Ace_ObjectType() As String
            Get
                Return _Ace_ObjectType
            End Get
            Set(ByVal value As String)
                _Ace_ObjectType = value
            End Set
        End Property


        Private _Err As String
        Public Property Err() As String
            Get
                Return _Err
            End Get
            Set(ByVal value As String)
                _Err = value
            End Set
        End Property
    End Class
    <Flags()>
    Public Enum FindType
        Files = &H1
        Directories = &H2
    End Enum
    Public Enum SECURITY_INFORMATION As Integer
        OWNER_SECURITY_INFORMATION = 1
        GROUP_SECURITY_INFORMATION = 2
        DACL_SECURITY_INFORMATION = 4
        SACL_SECURITY_INFORMATION = 8
        'PROTECTED_SACL_SECURITY_INFORMATION
        'PROTECTED_DACL_SECURITY_INFORMATION
        'UNPROTECTED_SACL_SECURITY_INFORMATION
        'UNPROTECTED_DACL_SECURITY_INFORMATION
    End Enum
    Public Enum FileAccessType As Integer
        DELETE = &H10000
        READ_CONTROL = &H20000
        WRITE_DAC = &H40000
        WRITE_OWNER = &H80000
        SYNCHRONIZE = &H100000
        STANDARD_RIGHTS_REQUIRED = &HF0000
        STANDARD_RIGHTS_READ = READ_CONTROL
        STANDARD_RIGHTS_WRITE = READ_CONTROL
        STANDARD_RIGHTS_EXECUTE = READ_CONTROL
        STANDARD_RIGHTS_ALL = &H1F0000
        SPECIFIC_RIGHTS_ALL = &HFFFF
        ACCESS_SYSTEM_SECURITY = &H1000000
        MAXIMUM_ALLOWED = &H2000000
        GENERIC_READ = &H80000000
        GENERIC_WRITE = &H40000000
        GENERIC_EXECUTE = &H20000000
        GENERIC_ALL = &H10000000
        FILE_READ_DATA = &H1
        FILE_WRITE_DATA = &H2
        FILE_APPEND_DATA = &H4
        FILE_READ_EA = &H8
        FILE_WRITE_EA = &H10
        FILE_EXECUTE = &H20
        FILE_READ_ATTRIBUTES = &H80
        FILE_WRITE_ATTRIBUTES = &H100
        FILE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED Or SYNCHRONIZE Or &H1FF
        FILE_GENERIC_READ = STANDARD_RIGHTS_READ Or FILE_READ_DATA Or FILE_READ_ATTRIBUTES Or FILE_READ_EA Or SYNCHRONIZE
        FILE_GENERIC_WRITE = STANDARD_RIGHTS_WRITE Or FILE_WRITE_DATA Or FILE_WRITE_ATTRIBUTES Or FILE_WRITE_EA Or FILE_APPEND_DATA Or SYNCHRONIZE
        FILE_GENERIC_EXECUTE = STANDARD_RIGHTS_EXECUTE Or FILE_READ_ATTRIBUTES Or FILE_EXECUTE Or SYNCHRONIZE
    End Enum
    Public Enum DirectoryAccessType As Integer
        DELETE = &H10000
        READ_CONTROL = &H20000
        WRITE_DAC = &H40000
        WRITE_OWNER = &H80000
        SYNCHRONIZE = &H100000
        STANDARD_RIGHTS_REQUIRED = &HF0000
        STANDARD_RIGHTS_READ = READ_CONTROL
        STANDARD_RIGHTS_WRITE = READ_CONTROL
        STANDARD_RIGHTS_EXECUTE = READ_CONTROL
        STANDARD_RIGHTS_ALL = &H1F0000
        SPECIFIC_RIGHTS_ALL = &HFFFF
        ACCESS_SYSTEM_SECURITY = &H1000000
        MAXIMUM_ALLOWED = &H2000000
        GENERIC_READ = &H80000000
        GENERIC_WRITE = &H40000000
        GENERIC_EXECUTE = &H20000000
        GENERIC_ALL = &H10000000
        FILE_LIST_DIRECTORY = &H1
        FILE_ADD_FILE = &H2
        FILE_ADD_SUBDIRECTORY = &H4
        FILE_READ_EA = &H8
        FILE_WRITE_EA = &H10
        FILE_TRAVERSE = &H20
        FILE_DELETE_CHILD = &H40
        FILE_READ_ATTRIBUTES = &H80
        FILE_WRITE_ATTRIBUTES = &H100
        FILE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED Or SYNCHRONIZE Or &H1FF
        FILE_GENERIC_READ = STANDARD_RIGHTS_READ Or FILE_LIST_DIRECTORY Or FILE_READ_ATTRIBUTES Or FILE_READ_EA Or SYNCHRONIZE
        FILE_GENERIC_WRITE = STANDARD_RIGHTS_WRITE Or FILE_ADD_FILE Or FILE_WRITE_ATTRIBUTES Or FILE_WRITE_EA Or FILE_ADD_SUBDIRECTORY Or SYNCHRONIZE
        FILE_GENERIC_EXECUTE = STANDARD_RIGHTS_EXECUTE Or FILE_READ_ATTRIBUTES Or FILE_TRAVERSE Or SYNCHRONIZE
    End Enum

    Public Enum AceFlags As Byte
        OBJECT_INHERIT_ACE = &H1
        CONTAINER_INHERIT_ACE = &H2
        NO_PROPAGATE_INHERIT_ACE = &H4
        INHERIT_ONLY_ACE = &H8
        INHERITED_ACE = &H10
        VALID_INHERIT_FLAGS = &H1F
        SUCCESSFUL_ACCESS_ACE_FLAG = &H40
        FAILED_ACCESS_ACE_FLAG = &H80
    End Enum

    <StructLayout(LayoutKind.Sequential)> Structure ACEHeader
        Dim AceType As Byte
        Dim AceFlags As Byte
        Dim AceSize As Int16
    End Structure

    <StructLayout(LayoutKind.Sequential)> Structure ACCESS_ACE
        Dim AceHeader As ACEHeader
        Dim AccessMask As Integer
        Dim SID As Int32
    End Structure

    ' This function obtains specified information about the security of a file or directory.
    <DllImport("AdvAPI32.DLL", CharSet:=CharSet.Auto, SetLastError:=True)>
    Private Shared Function GetFileSecurity(
    ByVal lpFileName As String,
    ByVal RequestedInformation As SECURITY_INFORMATION,
    ByVal pSecurityDescriptor As IntPtr,
    ByVal nLength As Int32,
    ByRef lpnLengthNeeded As Int32) As Boolean
    End Function

    ' This function retrieves a pointer to the DACL in a specified security descriptor.
    <DllImport("AdvAPI32.DLL", CharSet:=CharSet.Auto, SetLastError:=True)>
    Private Shared Function GetSecurityDescriptorDacl(
    ByVal SecurityDescriptor As IntPtr,
    ByRef DaclPresent As Boolean,
    ByRef Dacl As IntPtr,
    ByRef DaclDefaulted As Boolean) As Boolean
    End Function
    ' This function obtains a pointer to an ACE in an ACL.
    <DllImport("AdvAPI32.DLL", CharSet:=CharSet.Auto, SetLastError:=True)>
    Private Shared Function GetAce(
    ByVal Dacl As IntPtr,
    ByVal AceIndex As Integer,
    ByRef Ace As IntPtr) As Boolean
    End Function
    <DllImport("advapi32.dll", CharSet:=CharSet.Auto, SetLastError:=True)>
    Private Shared Function LookupAccountSid(
    ByVal systemName As String,
    ByVal psid As IntPtr,
    ByVal accountName As String,
    ByRef cbAccount As Integer,
    ByVal domainName As String,
    ByRef cbDomainName As Integer,
    ByRef use As Integer) As Boolean
    End Function
    <DllImport("advapi32.dll", CharSet:=CharSet.Auto, SetLastError:=True)>
    Private Shared Function ConvertSidToStringSid(
    ByVal psid As IntPtr,
    ByRef ssp As IntPtr) As Boolean
    End Function
    Public Shared Function GetObjectACL(ByVal strObjectName As String, Optional ByVal bExplicitOnly As Boolean = False, Optional ByVal ObjectType As FindType = FindType.Directories, Optional ByVal iChop As Integer = 0) As List(Of ACE_Entry)
        Dim SD As System.IntPtr
        Dim SDSizeNeeded, SDSize As Integer
        Dim LastError As Integer
        Dim Dacl_Present, Dacl_Defaulted As Boolean
        Dim DACL, ACE, SID_ptr, SID_String_ptr As System.IntPtr
        Dim ACE_Header As ACEHeader
        Dim Access_ACE As ACCESS_ACE
        Dim entry As Integer
        'Dim isFile As Boolean
        Dim name_len, domain_len, dUse As Integer
        Dim name, domain_name, UserName, StringSID As String
        Dim Ans As New ACE_Entry

        Dim lstReturn As New List(Of ACE_Entry)
        'ReDim Ans(0)
        ' Do a quick sanity check?
        'isFile = True
        'If System.IO.File.Exists(file) = False Then
        '    If System.IO.Directory.Exists(file) = False Then
        '        Ans(0).Ace_Name = Left("Error: " & file & " doesn't exist!", 255)
        '        Return Ans
        '    End If
        '    isFile = False
        'End If

        ' Do a test run to get the size needed
        SD = New IntPtr(0)
        SDSizeNeeded = 0
        GetFileSecurity(strObjectName, SECURITY_INFORMATION.DACL_SECURITY_INFORMATION, SD, 0, SDSizeNeeded)

        ' Allocate the memory required for the security descriptor.
        SD = Marshal.AllocHGlobal(SDSizeNeeded)
        SDSize = SDSizeNeeded

        ' Get the security descriptor.
        If GetFileSecurity(strObjectName, SECURITY_INFORMATION.DACL_SECURITY_INFORMATION, SD, SDSize, SDSizeNeeded) = False Then
            'LastError = Marshal.GetLastWin32Error()
            Dim errorMessage As String = New Win32Exception(Marshal.GetLastWin32Error()).Message
            Select Case iChop
                Case 4, 7
                    Ans.Object_Name = strObjectName.Substring(iChop)
                Case Else
                    Ans.Object_Name = strObjectName
            End Select

            Ans.Err = Left(errorMessage, 255)
            lstReturn.Add(Ans)
            Return lstReturn
        End If

        ' Get the DACL from the SD
        If GetSecurityDescriptorDacl(SD, Dacl_Present, DACL, Dacl_Defaulted) = False Then
            'LastError = Marshal.GetLastWin32Error()
            Dim errorMessage As String = New Win32Exception(Marshal.GetLastWin32Error()).Message
            Select Case iChop
                Case 4, 7
                    Ans.Object_Name = strObjectName.Substring(iChop)
                Case Else
                    Ans.Object_Name = strObjectName
            End Select

            Ans.Err = Left(errorMessage, 255)
            lstReturn.Add(Ans)
            Return lstReturn
        End If

        ' loop thru all of the ACE's in the DACL
        entry = 0

        If Dacl_Present Then


            Do While GetAce(DACL, entry, ACE) = True
                ' start by copying just the header
                ACE_Header = Marshal.PtrToStructure(ACE, GetType(ACEHeader))

                ' we're really only interested in type=0 (allow) and type=1 (deny)
                If ACE_Header.AceType = 0 Or ACE_Header.AceType = 1 Then
                    If (ACE_Header.AceFlags And 16) = 0 Or bExplicitOnly = False Then
                        Ans = New ACE_Entry
                        ' now that we know it's type… we do the copy over again
                        Access_ACE = Marshal.PtrToStructure(ACE, GetType(ACCESS_ACE))

                        ' translate SID to Account Name
                        name_len = 64
                        domain_len = 64
                        name = Space(name_len)
                        domain_name = Space(domain_len)

                        ' are we doing this remotely? (detected source of mapped drive letters?)
                        'If file.StartsWith("\\") Then
                        '    MachineName = file.Split("\")(2)
                        'Else
                        '    MachineName = ""
                        'End If

                        ' lookup the account for that SID
                        SID_ptr = New IntPtr(ACE.ToInt32 + 8)
                        'If LookupAccountSid(MachineName, SID_ptr, name, name_len, domain_name, domain_len, dUse) = False Then
                        If LookupAccountSid(Nothing, SID_ptr, name, name_len, domain_name, domain_len, dUse) = False Then
                            LastError = Marshal.GetLastWin32Error()
                            ' if we fail on error 1332, then use the SID in the name
                            If LastError <> 1332 Then
                                domain_len = 0
                                name = "Error: LookupAccountSid: " & LastError.ToString
                                name_len = Len(name)
                            Else
                                If ConvertSidToStringSid(SID_ptr, SID_String_ptr) = False Then
                                    LastError = Marshal.GetLastWin32Error()
                                    domain_len = 0
                                    name = "Error: ConvertSidToStringSid: " & LastError.ToString
                                    name_len = Len(name)
                                Else
                                    StringSID = Marshal.PtrToStringAuto(SID_String_ptr)
                                    Marshal.FreeHGlobal(SID_String_ptr)
                                    domain_len = 0
                                    name = StringSID
                                    name_len = Len(name)
                                End If
                            End If
                        End If
                        If domain_len > 0 Then
                            UserName = Left(domain_name, domain_len) & "\" & Left(name, name_len)
                        Else
                            UserName = Left(name, name_len)
                        End If

                        'ReDim Preserve Ans(num)

                        ' Type of ACE
                        If ACE_Header.AceType = 0 Then
                            Ans.Ace_Type = "Allow"
                        Else
                            Ans.Ace_Type = "Deny"
                        End If

                        ' The security principle
                        Ans.Ace_Name = UserName

                        ' the permissions
                        Ans.Ace_PermissionMask = Access_ACE.AccessMask
                        If ObjectType = FindType.Files Then
                            Ans.Ace_Permission = FileMaskToString(Access_ACE.AccessMask)
                            Ans.Ace_ObjectType = "F"
                        Else
                            Ans.Ace_Permission = DirectoryMaskToString(Access_ACE.AccessMask)
                            Ans.Ace_ObjectType = "D"
                        End If

                        ' Inheritance
                        If Access_ACE.AceHeader.AceFlags And AceFlags.INHERITED_ACE Then
                            Ans.Ace_Inherited = True
                        Else
                            Ans.Ace_Inherited = False
                        End If

                        ' Scope (directories only)
                        If ObjectType = FindType.Directories Then
                            Ans.Ace_Scope = ACEFlagToString(Access_ACE.AceHeader.AceFlags)
                        End If

                        Select Case iChop
                            Case 4, 7
                                Ans.Object_Name = strObjectName.Substring(iChop)
                            Case Else
                                Ans.Object_Name = strObjectName
                        End Select


                        lstReturn.Add(Ans)
                    End If
                    entry = entry + 1
                End If

            Loop

        Else

            Ans = New ACE_Entry
            Ans.Ace_Inherited = False
            ' Scope (directories only)
            If ObjectType = FindType.Directories Then
                Ans.Ace_Scope = ACEFlagToString(Access_ACE.AceHeader.AceFlags)
            End If
            If ObjectType = FindType.Files Then
                Ans.Ace_ObjectType = "F"
            Else
                Ans.Ace_ObjectType = "D"
            End If
            Select Case iChop
                Case 4, 7
                    Ans.Object_Name = strObjectName.Substring(iChop)
                Case Else
                    Ans.Object_Name = strObjectName
            End Select
            Ans.Ace_Inherited = False
            Ans.Err = "No permissions have been assigned for this object. "
            lstReturn.Add(Ans)
        End If


        ' Free the memory we allocated.
        Marshal.FreeHGlobal(SD)

        ' Exit the routine.
        Return lstReturn
    End Function
    Public Shared Function GetFolderPermR(ByVal strFolder As String, Optional ByVal iMax As Integer = 0) As List(Of ACE_Entry)

        Dim strUnicodeUNC As String = "\\?\UNC\{0}"
        Dim strUnicodeLoc As String = "\\?\{0}"
        Dim strPre As String = ""
        Dim iRemove As Integer = 0

        If strFolder.Length > 2 Then

            If strFolder.Substring(2, 1) <> "?" Then 'Lets convert to unicode
                If strFolder.Substring(1, 1) = ":" Then 'local folder
                    strFolder = String.Format(strUnicodeLoc, strFolder)
                    iRemove = 4
                Else 'UNC
                    strFolder = String.Format(strUnicodeUNC, strFolder.Substring(2))
                    iRemove = 7
                    strPre = "\"
                End If
            End If
        End If
        If Right(strFolder, 1) = "\" Then strFolder = strFolder.Substring(0, strFolder.Length - 1)

        Dim lstResults As New List(Of ACE_Entry)
        If iMax <= 0 Then
            'lstResults = GetFolderPerm(strFolder)
        Else
            Dim lst As New List(Of String)
            lst = utlWin32_Dir.FindFilesAndDirs(strFolder, FindType.Directories, True, iMax)
            For Each strlstFolder As String In lst

                lstResults.InsertRange(0, GetObjectACL(strlstFolder, True, FindType.Directories, iRemove))


            Next
        End If
        lstResults.InsertRange(0, GetObjectACL(strFolder, True, FindType.Directories, iRemove))
        Return lstResults
    End Function

    ' User friendly version of the access masks
    Public Shared Function FileMaskToString(ByVal mask As Integer) As String
        Dim buf As String

        Select Case mask
            Case FileAccessType.FILE_ALL_ACCESS
                Return ("Full Control")
            Case FileAccessType.FILE_ALL_ACCESS And Not (FileAccessType.WRITE_DAC Or FileAccessType.WRITE_OWNER Or &H40)
                Return ("Modify")
            Case FileAccessType.FILE_GENERIC_READ Or FileAccessType.FILE_GENERIC_EXECUTE
                Return ("Read & Execute")
            Case FileAccessType.FILE_GENERIC_READ
                Return ("Read")
            Case FileAccessType.FILE_GENERIC_WRITE
                Return ("Write")
            Case FileAccessType.FILE_GENERIC_EXECUTE
                Return ("Execute")
            Case Else
                ' ok… do it the hard way
                buf = "Special (0x" & Hex(mask) & "): "
                If mask And FileAccessType.FILE_EXECUTE Then
                    buf = buf & "Execute File,"
                End If
                If mask And FileAccessType.FILE_READ_DATA Then
                    buf = buf & "Read Data,"
                End If
                If mask And FileAccessType.FILE_READ_ATTRIBUTES Then
                    buf = buf & "Read Attributes,"
                End If
                If mask And FileAccessType.FILE_READ_EA Then
                    buf = buf & "Read Extended Attributes,"
                End If
                If mask And FileAccessType.FILE_WRITE_DATA Then
                    buf = buf & "Write Data,"
                End If
                If mask And FileAccessType.FILE_APPEND_DATA Then
                    buf = buf & "Append Data,"
                End If
                If mask And FileAccessType.FILE_WRITE_ATTRIBUTES Then
                    buf = buf & "Write Attributes,"
                End If
                If mask And FileAccessType.FILE_WRITE_EA Then
                    buf = buf & "Write Extended Attributes,"
                End If
                If mask And FileAccessType.DELETE Then
                    buf = buf & "Delete,"
                End If
                If mask And FileAccessType.READ_CONTROL Then
                    buf = buf & "Read Permissions,"
                End If
                If mask And FileAccessType.WRITE_DAC Then
                    buf = buf & "Change Permissions,"
                End If
                If mask And FileAccessType.WRITE_OWNER Then
                    buf = buf & "Take Ownership,"
                End If
                If buf.EndsWith(",") Then
                    buf = buf.TrimEnd(",")
                End If
                Return (buf)
        End Select

    End Function
    Public Shared Function DirectoryMaskToString(ByVal mask As Integer) As String
        Dim buf As String

        Select Case mask
            Case DirectoryAccessType.FILE_ALL_ACCESS
                Return ("Full Control")
            Case DirectoryAccessType.FILE_ALL_ACCESS And Not (DirectoryAccessType.WRITE_DAC Or DirectoryAccessType.WRITE_OWNER Or DirectoryAccessType.FILE_DELETE_CHILD)
                Return ("Modify")
            Case DirectoryAccessType.FILE_GENERIC_READ Or DirectoryAccessType.FILE_GENERIC_EXECUTE
                Return ("Read & Execute")
            Case DirectoryAccessType.FILE_GENERIC_EXECUTE
                Return ("List Folder Contents")
            Case DirectoryAccessType.FILE_GENERIC_READ
                Return ("Read")
            Case DirectoryAccessType.FILE_GENERIC_WRITE
                Return ("Write")
                ' generic permissions
            Case DirectoryAccessType.GENERIC_ALL
                Return ("Generic Full Control")
            Case DirectoryAccessType.GENERIC_READ Or DirectoryAccessType.GENERIC_WRITE Or DirectoryAccessType.GENERIC_EXECUTE Or DirectoryAccessType.DELETE
                Return ("Generic Modify")
            Case DirectoryAccessType.GENERIC_READ Or DirectoryAccessType.GENERIC_EXECUTE
                Return ("Generic Read & Execute")
            Case DirectoryAccessType.GENERIC_EXECUTE
                Return ("Generic List Folder Contents")
            Case DirectoryAccessType.GENERIC_READ
                Return ("Generic Read")
            Case DirectoryAccessType.GENERIC_WRITE
                Return ("Generic Write")
            Case Else
                ' ok… do it the hard way
                buf = "Special (0x" & Hex(mask) & "): "
                If mask And DirectoryAccessType.FILE_TRAVERSE Then
                    buf = buf & "Traverse Folder,"
                End If
                If mask And DirectoryAccessType.FILE_LIST_DIRECTORY Then
                    buf = buf & "List Folder,"
                End If
                If mask And DirectoryAccessType.FILE_READ_ATTRIBUTES Then
                    buf = buf & "Read Attributes,"
                End If
                If mask And DirectoryAccessType.FILE_READ_EA Then
                    buf = buf & "Read Extended Attributes,"
                End If
                If mask And DirectoryAccessType.FILE_ADD_FILE Then
                    buf = buf & "Create Files,"
                End If
                If mask And DirectoryAccessType.FILE_ADD_SUBDIRECTORY Then
                    buf = buf & "Create Folders,"
                End If
                If mask And DirectoryAccessType.FILE_WRITE_ATTRIBUTES Then
                    buf = buf & "Write Attributes,"
                End If
                If mask And DirectoryAccessType.FILE_WRITE_EA Then
                    buf = buf & "Write Extended Attributes,"
                End If
                If mask And DirectoryAccessType.DELETE Then
                    buf = buf & "Delete,"
                End If
                If mask And DirectoryAccessType.FILE_DELETE_CHILD Then
                    buf = buf & "Delete Subfolders & Files,"
                End If
                If mask And DirectoryAccessType.READ_CONTROL Then
                    buf = buf & "Read Permissions,"
                End If
                If mask And DirectoryAccessType.WRITE_DAC Then
                    buf = buf & "Change Permissions,"
                End If
                If mask And DirectoryAccessType.WRITE_OWNER Then
                    buf = buf & "Take Ownership,"
                End If
                If buf.EndsWith(",") Then
                    buf = buf.TrimEnd(",")
                End If
                Return (buf)
        End Select

    End Function
    Public Shared Function ACEFlagToString(ByVal flag As Byte) As String
        Dim buf As String

        Select Case flag
            Case 0, AceFlags.INHERITED_ACE
                Return "This folder only"
            Case AceFlags.OBJECT_INHERIT_ACE Or AceFlags.CONTAINER_INHERIT_ACE, AceFlags.OBJECT_INHERIT_ACE Or AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERITED_ACE
                Return "This folder, subfolders and files"
            Case AceFlags.CONTAINER_INHERIT_ACE, AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERITED_ACE
                Return "This folder and subfolders"
            Case AceFlags.OBJECT_INHERIT_ACE, AceFlags.OBJECT_INHERIT_ACE Or AceFlags.INHERITED_ACE
                Return "This folder and files"
            Case AceFlags.OBJECT_INHERIT_ACE Or AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE, AceFlags.OBJECT_INHERIT_ACE Or AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE Or AceFlags.INHERITED_ACE
                Return "Subfolders and files only"
            Case AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE, AceFlags.CONTAINER_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE Or AceFlags.INHERITED_ACE
                Return "Subfolders only"
            Case AceFlags.OBJECT_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE, AceFlags.OBJECT_INHERIT_ACE Or AceFlags.INHERIT_ONLY_ACE Or AceFlags.INHERITED_ACE
                Return "Files only"
            Case Else
                ' ok… do it the hard way
                buf = "Special (0x" & Hex(flag) & "): "
                If flag And AceFlags.OBJECT_INHERIT_ACE Then
                    buf = buf & "Object,"
                End If
                If flag And AceFlags.CONTAINER_INHERIT_ACE Then
                    buf = buf & "Container,"
                End If
                If flag And AceFlags.NO_PROPAGATE_INHERIT_ACE Then
                    buf = buf & "No Propagate,"
                End If
                If flag And AceFlags.INHERIT_ONLY_ACE Then
                    buf = buf & "Inherit Only,"
                End If
                If flag And AceFlags.INHERITED_ACE Then
                    buf = buf & "Inherited,"
                End If
                If flag And AceFlags.SUCCESSFUL_ACCESS_ACE_FLAG Then
                    buf = buf & "Successful,"
                End If
                If flag And AceFlags.FAILED_ACCESS_ACE_FLAG Then
                    buf = buf & "Failed,"
                End If
                Return buf
        End Select
    End Function
End Class
Public Class utlWin32_Dir
    <DllImport("kernel32.dll", CharSet:=CharSet.Unicode, SetLastError:=True)>
    Friend Shared Function FindFirstFile(ByVal lpFileName As String, ByRef lpFindFileData As WIN32_FIND_DATA) As IntPtr
    End Function
    <DllImport("kernel32.dll", CharSet:=CharSet.Unicode, SetLastError:=True)>
    Friend Shared Function FindNextFile(ByVal hFindFile As IntPtr, ByRef lpFindFileData As WIN32_FIND_DATA) As Boolean
    End Function

    <DllImport("kernel32.dll", SetLastError:=True, CharSet:=CharSet.Unicode)>
    Friend Shared Function FindClose(ByVal hFindFile As IntPtr) As <MarshalAs(UnmanagedType.Bool)> Boolean
    End Function

    Friend Shared FILE_ATTRIBUTE_DIRECTORY As Integer = &H10
    Friend Shared INVALID_HANDLE_VALUE As New IntPtr(-1)
    Friend Shared FILE_ATTRIBUTE_HIDDEN As Integer = &H2
    Friend Shared FILE_ATTRIBUTE_REPARSE_POINT As Integer = &H400
    Friend Shared FILE_ATTRIBUTE_SYSTEM As Integer = &H4
    Friend Shared FILE_ATTRIBUTE_READONLY As Integer = &H1
    <StructLayout(LayoutKind.Sequential, CharSet:=CharSet.Unicode)>
    Structure WIN32_FIND_DATA
        Public dwFileAttributes As UInteger
        Public ftCreationTime As System.Runtime.InteropServices.ComTypes.FILETIME
        Public ftLastAccessTime As System.Runtime.InteropServices.ComTypes.FILETIME
        Public ftLastWriteTime As System.Runtime.InteropServices.ComTypes.FILETIME
        Public nFileSizeHigh As UInteger
        Public nFileSizeLow As UInteger
        Public dwReserved0 As UInteger
        Public dwReserved1 As UInteger
        <MarshalAs(UnmanagedType.ByValTStr, SizeConst:=260)> Public cFileName As String
        <MarshalAs(UnmanagedType.ByValTStr, SizeConst:=14)> Public cAlternateFileName As String
    End Structure
    <Flags()>
    Public Enum FindType
        Files = &H1
        Directories = &H2
    End Enum
    Public Shared Function FindFilesAndDirs(ByVal dirName As String, Optional ByVal types As FindType = FindType.Directories, Optional ByVal recursive As Boolean = False, Optional ByVal iMax As Integer = 100000, Optional ByVal iLevel As Integer = 0) As List(Of String)
        Dim results As New List(Of String)()
        Dim subResults As New List(Of String)()
        Dim findData As New WIN32_FIND_DATA
        Dim findHandle As IntPtr = FindFirstFile(dirName & "\*", findData)


        If findHandle <> INVALID_HANDLE_VALUE Then 'valid handle
            Dim found As Boolean
            iLevel += 1

            Do 'Loop through files/folders
                Dim currentFileName As String = findData.cFileName

              If ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_DIRECTORY) <> 0) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_HIDDEN) = 0) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_SYSTEM) = 0) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_REPARSE_POINT) = 0) Then 'if current object is a directory
                    If currentFileName <> "." AndAlso currentFileName <> ".." Then
                        If (recursive = True) And (iLevel < iMax) Then 'lets go deeper if we need
                            Dim childResults As List(Of String) = FindFilesAndDirs(System.IO.Path.Combine(dirName, currentFileName), types, recursive, iMax, iLevel)
                            subResults.AddRange(childResults)
                        End If
                        If (types And FindType.Directories) = FindType.Directories Then 'Directories, add their list
                            results.Add(System.IO.Path.Combine(dirName, currentFileName))
                        End If
                    End If
                Else
                    If ((types And FindType.Files) = FindType.Files) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_HIDDEN) = 0) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_SYSTEM) = 0) And ((CInt(findData.dwFileAttributes) And FILE_ATTRIBUTE_REPARSE_POINT) = 0) Then 'If we specified files, get their info
                        results.Add(System.IO.Path.Combine(dirName, currentFileName))
                    End If
                End If

                found = FindNextFile(findHandle, findData)
            Loop While found
        Else
            results.Add(dirName & "\.*")
            'HttpContext.Current.Response.Write(dirName & "<br />")
        End If

        FindClose(findHandle)
        results.InsertRange(0, subResults)
        Return results
    End Function
End Class

"@
  Add-Type -ReferencedAssemblies ("System.Windows.Forms") -Language VisualBasic -IgnoreWarnings -TypeDefinition $code
  $files = [utlwin32_dir]::FindFilesAndDirs($path,1,$true,100)
  return $files
}
#---------------------------------------------- 
#endregion Sind-FilesFast Function
#----------------------------------------------
Export-ModuleMember -Function @('Find-FilesFast')

