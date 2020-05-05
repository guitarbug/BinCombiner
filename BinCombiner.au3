#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>

Global $config_file=@WorkingDir & "\BinCombiner.ini"
Global $mainGUIWidthDefault=370,$mainGUIheightDefault=610,$FlashSizeDefault=8,$FlashPartitionNumDefault=6
Global $mainGUIWidth,$mainGUIheight
Global $comboFlashSize
Global $FlashSize
Global $inputFlashPartitionNum,$FlashPartitionNum
Global $BaseX=10,$BaseY=10,$GUICtrlHeight=20
Global $inputPartitionSize[$FlashPartitionNumDefault],$inputOffsetSize[$FlashPartitionNumDefault]
Global $buttonSelectFile[$FlashPartitionNumDefault],$inputSelectFile[$FlashPartitionNumDefault]
Global $PartitionSize[$FlashPartitionNumDefault],$OffsetSize[$FlashPartitionNumDefault],$FileName[$FlashPartitionNumDefault]
Global $DEBUG=1

Func print($var)
	If $DEBUG=1 Then
		ConsoleWrite("***val="&$var&@CRLF)
	EndIf
EndFunc

Func check_settings_file()
	;check if we have the configuration file.
	Local $iFileExists = FileExists ($config_file)
	If $iFileExists = 0 Then ;ini file does not exist
		;create the ini file
		If Not _FileCreate($config_file) Then
			MsgBox($MB_ICONWARNING, "Warning", "Error Creating the config file.The settings will not saved")
		EndIf
    EndIf
EndFunc

;read the config from the ini File
Func load_settings()
	Local $i
	;main GUI
	$mainGUIWidth=IniRead($config_file,"mainGUI","width",$mainGUIWidthDefault)
	$mainGUIheight=IniRead($config_file,"mainGUI","height",$mainGUIheightDefault)
	;flash size
	$FlashSize=IniRead($config_file,"flash","size",$FlashSizeDefault)
	;flash partition number
	$FlashPartitionNum=IniRead($config_file,"flash","partitionNum",$FlashPartitionNumDefault)
	For $i = 0 To $FlashPartitionNum-1 Step +1
		;partition size
		$PartitionSize[$i]=IniRead($config_file,"partition"&$i,"size",0)
		;partition offset
		$OffsetSize[$i]=IniRead($config_file,"partition"&$i,"offset",0)
		;partition file
		$FileName[$i]=IniRead($config_file,"partition"&$i,"file",Null)
	Next

EndFunc

;read value from GUI ctrl,then write to ini file.
Func save_settings()
	Local $i
	;main GUI
	IniWrite($config_file,"mainGUI","width",$mainGUIWidth)
	IniWrite($config_file,"mainGUI","height",$mainGUIheight)
	;flash size
	IniWrite($config_file,"flash","size",GUICtrlRead($comboFlashSize))
	;flash partition number
	IniWrite($config_file,"flash","partitionNum",GUICtrlRead($inputFlashPartitionNum))
	For $i = 0 To $FlashPartitionNum-1 Step +1
		;partition size
		IniWrite($config_file,"partition"&$i,"size",GUICtrlRead($inputPartitionSize[$i]))
		;partition offset
		IniWrite($config_file,"partition"&$i,"offset",GUICtrlRead($inputOffsetSize[$i]))
		;partition file
		IniWrite($config_file,"partition"&$i,"file",GUICtrlRead($inputSelectFile[$i]))
	Next
EndFunc

Func create_patition_list_GUI()
	Local $groupPartitionListWidth=350,$groupPartitionListHeight=80,$inputPartitionSizeWidth=40,$inputOffsetSizeWidth=100,$inputSelectFileWidth=215
	Local $i
	$BaseY=70
	For $i = 0 To $FlashPartitionNum-1 Step +1
		;Partition group
		GUICtrlCreateGroup("Partition "&$i, $BaseX, $BaseY,$groupPartitionListWidth,$groupPartitionListHeight)
		;partitin size Label
		GUICtrlCreateLabel("Partition Size(KB) :", $BaseX+10, $BaseY+20,-1,$GUICtrlHeight)
		;offset Label
		GUICtrlCreateLabel("Offset(Hex) :", $BaseX+150, $BaseY+20)

		;partitin size
		$inputPartitionSize[$i]=GUICtrlCreateInput("", $BaseX+100, $BaseY+20, $inputPartitionSizeWidth, $GUICtrlHeight)
		;offset
		$inputOffsetSize[$i]=GUICtrlCreateInput("", $BaseX+215, $BaseY+20, $inputOffsetSizeWidth, $GUICtrlHeight)
		;file name
		$buttonSelectFile[$i]=GUICtrlCreateButton("Select a File", $BaseX+10, $BaseY+45,-1,$GUICtrlHeight)
		$inputSelectFile[$i]=GUICtrlCreateInput("", $BaseX+100, $BaseY+45, $inputSelectFileWidth, $GUICtrlHeight)
		GUICtrlSetData($inputOffsetSize[$i],$OffsetSize[$i],0)
		GUICtrlSetData($inputPartitionSize[$i],$PartitionSize[$i],0)
		GUICtrlSetData($inputSelectFile[$i],$FileName[$i],NULL)
		$BaseY+=90
	Next
EndFunc

Func validate_FlashPartitionNum_settings()
	Local $tmp_val= GUICtrlRead($inputFlashPartitionNum)
	If $tmp_val >= 1 And $tmp_val <= 6 Then
		If $tmp_val <> $FlashPartitionNum Then
			$FlashPartitionNum = $tmp_val
			MsgBox($MB_ICONWARNING,"Warning","Please restart the program to make settings to take effect")
		EndIf
		Else
		MsgBox($MB_ICONERROR,"Error","Flash Partition Number only support 1 - 6")
		GUICtrlSetData($inputFlashPartitionNum,$FlashPartitionNum)
	EndIf
EndFunc

Func validate_FlashSize_settings()
	Local $tmp_val = GUICtrlRead($comboFlashSize)
	;only support "1MB|2MB|4MB|8MB|16MB|32MB"
	If $tmp_val <> 1 And $tmp_val <> 2 And $tmp_val <> 4 And $tmp_val <> 8 And $tmp_val <> 16 And $tmp_val <> 32 Then
		MsgBox($MB_ICONERROR,"Error","Flash Size only support 1MB|2MB|4MB|8MB|16MB|32MB")
		GUICtrlSetData($comboFlashSize,$FlashSize)
	Else
		$FlashSize = $tmp_val
	EndIf
EndFunc

Func validate_Partition_settings()
	Local $i,$partition_size_val=0,$offset_val_size=0,$TotalPartitionSize=0
	For $i = 0 To $FlashPartitionNum-1 Step +1
		;check Partition size
		$partition_size_val=GUICtrlRead($inputPartitionSize[$i])
		If $partition_size_val <=0 Or $partition_size_val > ($FlashSize*1024) Then
			MsgBox($MB_ICONERROR,"Error","Partition "&$i&" Size "&$partition_size_val&" is invalid")
			Return
		EndIf
		$PartitionSize[$i]=$partition_size_val
		$TotalPartitionSize+=$partition_size_val
		If $TotalPartitionSize > ($FlashSize*1024) Then
			MsgBox($MB_ICONERROR,"Error","Total Partition Size exceed "&$FlashSize&"MB")
			Return
		EndIf

		;check offset size
		$offset_val_size=GUICtrlRead($inputOffsetSize[$i])
		If $offset_val_size >= ($FlashSize*1024) Or ($offset_val_size = 0 And $i <> 0) Or ($offset_val_size<0) Then
			MsgBox($MB_ICONERROR,"Error","Partition "&$i&" Offset is invalid")
			Return
		EndIf

		If $i = 0 And $offset_val_size<>0 Then ;the 1st partition offset should be 0x00
			MsgBox($MB_ICONWARNING,"Warning","Partition 1 Offset is NOT 0,the Offset 0-"&$offset_val_size&" will be padded with 0xFF")
			;partition 0 gap handle TODO
		EndIf
		$OffsetSize[$i]=$offset_val_size
		If $i<>0 Then
			If $OffsetSize[$i] < ($PartitionSize[$i-1]+$OffsetSize[$i-1]) Then
				MsgBox($MB_ICONERROR,"Error","Partition "&$i&" Offset should be greater or equal "&($PartitionSize[$i-1]+$OffsetSize[$i-1]))
				Return
			EndIf

			If $OffsetSize[$i] > ($PartitionSize[$i-1]+$OffsetSize[$i-1]) Then
				MsgBox($MB_ICONWARNING,"Warning","Gap found between Partition "&$i&" with Partition "&$i&",and the Gap will be padded with 0xFF")
				;gap handle TODO
			EndIf

		EndIf

	Next
EndFunc


;main entry
Func main()
	check_settings_file()
	load_settings()

	;local Var
	Local $mainGUI
	Local $grouopSelectFlashSizeWidth=100,$groupSelectFlashSizeHeight=50
	Local $comboFlashSizeWidth=40
	Local $buttonCreateImage

	; Create a main GUI
	$mainGUI = GUICreate("Binary Combiner",$mainGUIWidth,$mainGUIheight)
	; Display the GUI.
	GUISetState(@SW_SHOW, $mainGUI)

	;create GUI for Flash Size Selection
	GUICtrlCreateGroup("Select Flash Size", $BaseX, $BaseY, $grouopSelectFlashSizeWidth, $groupSelectFlashSizeHeight)
	$comboFlashSize = GUICtrlCreateCombo("", $BaseX+10, $BaseY+20,$comboFlashSizeWidth,$GUICtrlHeight)
	GUICtrlCreateLabel("MB", $BaseX+60, $BaseY+20,-1,$GUICtrlHeight)
	GUICtrlSetData($comboFlashSize, "1|2|4|8|16|32",$FlashSize)

	;create GUI for Flash Partition Number
	GUICtrlCreateGroup("Flash Partition Number", $BaseX+110, $BaseY, 130, $groupSelectFlashSizeHeight)
	$inputFlashPartitionNum = GUICtrlCreateInput("", $BaseX+120, $BaseY+20,100,$GUICtrlHeight)
	GUICtrlSetData($inputFlashPartitionNum, $FlashPartitionNum)
	;create GUI for Create Image button
	$buttonCreateImage  = GUICtrlCreateButton("Create Image", $BaseX+250, $BaseY+20, 85, 25)

	create_patition_list_GUI()

	; Loop until the user exits.
	Local $Msg
	While 1
		$Msg=GUIGetMsg()

		For $i = 0 To $FlashPartitionNum-1 Step +1
			If $Msg = $buttonSelectFile[$i] And $buttonSelectFile[$i] <> 0 Then
				GUISetState(@SW_HIDE)
				$FileName[$i]=FileOpenDialog("Select a file:",GUICtrlRead($inputSelectFile[$i]),"All (*.*)")
				If @error = 0 Then
					GUICtrlSetData($inputSelectFile[$i], $FileName[$i])
				EndIf
				GUISetState(@SW_SHOW)
			EndIf
		Next

		Switch $Msg
			Case $inputFlashPartitionNum
				validate_FlashPartitionNum_settings()
			Case $buttonCreateImage
				validate_FlashSize_settings()
				validate_Partition_settings()
			Case $GUI_EVENT_CLOSE
				MsgBox($MB_ICONINFORMATION,"Bye","",0.3)
				ExitLoop
		EndSwitch
	WEnd
	;write current config to ini config file
	save_settings()
	; Delete the previous GUI and all controls.
	GUIDelete($mainGUI)
EndFunc

main()