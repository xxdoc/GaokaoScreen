VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "GSaving"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'Emerald 相关代码

Private Type SaveData
    Name As String
    value As String
    datacheck As String
End Type
Private Type SaveFile
    Data() As SaveData
End Type
Dim MySave As SaveFile
Public AutoSave As Boolean
Public sToken As Boolean, path As String
Public Key As String
'========================================================
'   Init
    Public Function FetchUserName() As String
        On Error Resume Next
        FetchUserName = "default"
        FetchUserName = PoolCreateObject("Wscript.Network").Username
    End Function
    Public Sub CheckFullPath(path As String)
        Dim S() As String
        S = Split(path, "\")
        Dim p As String
        p = S(0) & "\"
        For I = 1 To UBound(S)
            p = p & S(I) & "\"
            If Dir(p, vbDirectory) = "" Then MkDir p
        Next
    End Sub
    Public Function Create(Name As String, Optional BMKey) As Boolean
        If ESave Is Nothing Then Set ESave = Me
    
        If XPMode Then
            If Dir("C:\Emerad\", vbDirectory) = "" Then MkDir "C:\Emerad\"
            path = "C:\Emerad\" & Name
        Else
            path = "C:\Users\" & FetchUserName & "\AppData\Local\" & Name
        End If
        
        Call CheckFullPath(path)
        
        AutoSave = True
        
        If Not IsMissing(BMKey) Then Key = BMKey
        
        ReDim MySave.Data(0)
        If Dir(path & "\", vbDirectory) = "" Then
            If Name <> "Emerald.Core" Then
                SysPage.index = 0: SysPage.Key = 0
                Dim Win As New EmeraldWindow
                sToken = (Win.NewPermissionDialog("存档读写", "该应用请求在您的计算机的下列位置储存数据：" & vbCrLf & ESave.path & vbCrLf & vbCrLf & "拒绝可能导致“无法存档”之类的问题" & vbCrLf & "请求授权的应用：" & App.Title & "(" & Name & ")") = 1)
                If sToken Then
                    Create = True
                    MkDir path & "\"
                End If
            Else
                MkDir path & "\"
            End If
        Else
            If Dir(path & "\save") <> "" Then
                On Error GoTo ErrHandle
                Open path & "\save" For Binary As #1
                Get #1, , MySave
                Close #1
                Call CheckSave
ErrHandle:
                If Err.Number <> 0 Then
                    MsgBox "存档已经损坏！", 16, DisplayName: ReDim MySave.Data(0)
                    Suggest "游戏存档损坏。", NeverClear, 2
                End If
            End If
            Create = True
        End If
        
        If Create = False Then Suggest "游戏存档授权失败。", NeverClear, 1
        sToken = Create
        
    End Function
'========================================================
'   RunTime
    Public Sub CheckSave()
        Dim msg As String
        For I = 1 To UBound(MySave.Data)
            If MySave.Data(I).value <> "" Then
                If MySave.Data(I).datacheck <> IIf(Key = "", BMEA(I & MySave.Data(I).value), Key) Then
                    msg = msg & MySave.Data(I).Name & vbCrLf
                    MySave.Data(I).value = ""
                End If
            End If
        Next
        
        If msg <> "" Then
            Call Save
            MsgBox "已经发现并删除存档中以下非法数据：" & vbCrLf & msg, 64
            Suggest "游戏存档中含有非法数据。", NeverClear, 1
        End If
    End Sub
'========================================================
'   Manager
    Public Function Count() As Long
        Count = UBound(MySave.Data)
    End Function
    Public Function GetName(index As Integer) As String
        GetName = MySave.Data(index).Name
    End Function
    Public Sub Save()
        If sToken = False Then Exit Sub
        Open path & "\save" For Binary As #1
        Put #1, , MySave
        Close #1
    End Sub
    Public Function GetData(Name As String) As String
        For I = 1 To UBound(MySave.Data)
            If MySave.Data(I).Name = Name Then GetData = MySave.Data(I).value: Exit For
        Next
    End Function
    Public Sub PutData(Name As String, ByVal value As String)
        Dim fd As Boolean
        For I = 1 To UBound(MySave.Data)
            If MySave.Data(I).Name = Name Then
                MySave.Data(I).value = value
                MySave.Data(I).datacheck = IIf(Key = "", BMEA(I & value), Key)
                fd = True
                Exit For
            End If
        Next
        If fd = False Then
            '新增
            ReDim Preserve MySave.Data(UBound(MySave.Data) + 1)
            MySave.Data(UBound(MySave.Data)).Name = Name
            MySave.Data(UBound(MySave.Data)).value = value
            MySave.Data(UBound(MySave.Data)).datacheck = IIf(Key = "", BMEA(UBound(MySave.Data) & value), Key)
        End If
        If AutoSave Then Call Save
    End Sub
'========================================================


