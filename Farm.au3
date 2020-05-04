#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         Cosmix

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

#include <String.au3>
#include <IE.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include "HTTP.au3"

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("TribalWars FarmBot", 400, 330, 192, 124)
$Button1 = GUICtrlCreateButton("Start", 120, 200, 150, 39)
$Label1 = GUICtrlCreateLabel("", 152, 56, 212, 73)
$Label2 = GUICtrlCreateLabel("https://onlinebots.wixsite.com/tribalwars", 122, 300, 212, 73)
$Input1 = GUICtrlCreateInput("Code", 160, 160, 80, 25)
$Checkbox1 = GUICtrlCreateCheckbox("Run automatically every:", 40, 108, 153, 49)
$Combo1 = GUICtrlCreateCombo("15 minutes", 200, 124, 137, 25)
GUICtrlSetData($Combo1, "30 minutes|45 minutes|1 hour", "15 minutes")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

; MIN PASS TIME IN MS
Global $STANDARD = 250

; FILENAME --> Village IDS
Global $FILENAME = "ids.txt"

; MAIN WINDOW
Global $window = _IECreate("https://www.die-staemme.de")


; GUI LOOP
While 1
   $nMsg = GUIGetMsg()
   Switch $nMsg
   Case $GUI_EVENT_CLOSE
	  quit_($window)
	  Exit

	  Case $Button1
		 $timer = 0

		 IF _IsChecked($Checkbox1) Then
			; MsgBox(0, "", "" & GUICtrlRead($Combo1), 0, $Form1)

			if GUICtrlRead($Combo1) == "30 minutes" Then
			   $timer = 30
			ElseIf GUICtrlRead($Combo1) == "15 minutes" Then
			   $timer = 15
			ElseIf GUICtrlRead($Combo1) == "45 minutes" Then
			   $timer = 45
			ElseIf GUICtrlRead($Combo1) == "1 hour" Then
			   $timer = 60
			EndIf
		 EndIf

		 $village_ids = read_file()

		 $url_prop = StringSplit(_IEPropertyGet($window, "locationurl"), '?')
		 ; ConsoleWrite($url_prop[1])

		 If check_if_code_ok() < 0 Then
			MsgBox(0, "Error", "Code or Username not valid! ")

			ContinueCase
		 EndIf

		 if $village_ids == -1 Then
			ContinueCase
		 EndIf

		 ; START
		 main($village_ids, $timer, $url_prop[1])
   EndSwitch
WEnd


; GUI FUNCTIONS
Func _IsChecked($idControlID)
   Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc


; UTILITY FUNCTIONS
Func read_file()
   Local $arr[0]

   if FileOpen($FILENAME, 0) < 0 Then
	  GUICtrlSetData($Label1, "Could not read File! Check your VillageFile it must be named: ids.txt")

	  Return -1
   EndIf

   For $i = 1 to _FileCountLines($FILENAME)
	  ReDim $arr[UBound($arr) + 1]
	  $line = FileReadLine($FILENAME, $i)

	  $arr[$i - 1] = $line
   Next
   FileClose($FILENAME)


   Return $arr
EndFunc


Func wait_time($time)
   Local $60Count = 0, $begin = TimerInit()
   While $time > $60Count

	   $dif = TimerDiff($begin)
	   $Count = int($dif/1000)
	   $60Count = Int($Count / 60)

	   Sleep(20)
   WEnd
EndFunc


; Check if Player registered Code
Func check_if_code_ok()
   $get = _HTTP_Get("https://github.com/Serophiny/memoization/blob/master/logs")	; 1st Check
   $code = GUICtrlRead($Input1)

   If $get == 0 Then
	  MsgBox(0, "Error", "Error connecting to Server. Please check your Internet connection")

	  Return -1
   EndIf

   ; Get UserName
   Local $check_window = _IECreate(_IEPropertyGet($window, "locationurl") & "&screen=info_player", 0, 0)
   Sleep(3000)
   $get_link_coll = _IELinkGetCollection($check_window)
   $player = -1
   $count = 0

   For $link in $get_link_coll
	  If StringInStr($link.href, "&screen=info_player") Then
		 if $count == 1 Then
			$player = $link.innerText
		 EndIf

		 $count = $count + 1
	  EndIf

   Next

   If $player == -1 Then
	  MsgBox(0, "Error", "Please login first")

	  _IEQuit($check_window)
	  Return -1
   EndIf

   If StringInStr($get, $player) > 0 And StringInStr($get, $code) > 0 Then
	  _IEQuit($check_window)

	  Return 1
   Else
	  $get_2 = _HTTP_Get("https://onlinebots.wixsite.com/tribalwars/about")
	  If $get == 0 Then
		 MsgBox(0, "Error", "Error connecting to Server. Please check your Internet connection")

		 Return -1
	  EndIf

	  If StringInStr($get_2, $player) > 0 And StringInStr($get_2, $code) > 0 Then
		 _IEQuit($check_window)

		 Return 1
	  EndIf

	  _IEQuit($check_window)

	  Return -1
   EndIf

   _IEQuit($check_window)
EndFunc


; GAME FUNCTIONS
Func navigate($i)
   $url = _IEPropertyGet($window, "locationurl")
   _IENavigate($window, $url & "&Farm_page=" & $i)
EndFunc


Func get_pointer_light()
   $tag_coll = _IETagNameGetCollection($window, "td")
   For $tag in $tag_coll
	  if StringInStr($tag.classname, "unit-item unit-item-light") Then
		 $pointer = $tag
		 ExitLoop
	  EndIf
   Next

   Return $pointer
EndFunc


Func get_a_b_count()
   $tag_coll_input = _IETagNameGetCollection($window, "input")

   Local $arr[2]
   $i = 0

   For $input in $tag_coll_input
	  if StringInStr($input.name, "light") Then
		 if $i == 0 Then
			$arr[0] = Number($input.value)
		 Else
			$arr[1] = Number($input.value)
		 EndIf

		 $i = $i + 1
	  EndIf

	  if $i > 1 Then
		 ExitLoop
	  EndIf
   Next

   Return $arr
EndFunc


Func get_a_b_send()
   $img_coll = _IEImgGetCollection($window)
   Local $arr[100]
   $i = 0

   For $img in $img_coll
	  if StringInStr($img.src, "0.png") Then
		 $arr[$i] = 0
		 $i = $i + 1
	  ElseIf StringInStr($img.src, "1.png") Then
		 $arr[$i] = 1
		 $i = $i + 1
	  ElseIf StringInStr($img.src, "blue.png") Then
		 $arr[$i] = 2
		 $i = $i + 1
	  EndIf
   Next

   Return $arr
EndFunc


Func get_page_count()
   $link_coll = _IELinkGetCollection($window)
   $i = 1
   $temp = $i

   While True
	  For $link in $link_coll
		 if StringInStr($link.href, "Farm_page=" & $i) Then
			$i = $i + 1

			ExitLoop
		 EndIf
	  Next
	  if $temp == $i Then
		 ExitLoop
	  EndIf
	  $temp = $temp + 1
   WEnd

   Return $i
EndFunc


Func send_a_b($pointer, $a, $b, $arr)
   $link_coll = _IELinkGetCollection($window)

   $i = 0
   For $link in $link_coll
	  if StringInStr($link.href, '#') and StringInStr($link.classname, "farm_icon_a") and StringInStr($link.classname, "farm_village") Then
		 if $arr[$i] == 1 Then
			_IEAction($link, "click")
		 EndIf
	  ElseIf StringInStr($link.href, '#') and StringInStr($link.classname, "farm_icon_b") and StringInStr($link.classname, "farm_village") Then
		 if $arr[$i] == 0 Then
			_IEAction($link, "click")
		 EndIf

		 $i = $i + 1

		 Local $pass_time = 1000 * Random() + $STANDARD

		 if Number($pointer.innerText) < $a Or Number($pointer.innerText) < $b Then
			Return -1	; Not enough units
		 EndIf

		 Sleep($pass_time)

	  EndIf
   Next

   Return 0		; All sent
EndFunc


Func quit_($window)
   _IEQuit($window)
EndFunc


; main driver function
Func main($ids, $timer, $prop)
   if $timer == 0 Then
	  For $village in $ids	; Run through the villages
		 $i = 1

		 _IENavigate($window, $prop & "?village=" & $village & "&screen=am_farm")
		 Sleep(5000)
		 $a_b = get_a_b_count()
		 $page_count = get_page_count()

		 While True
			if $i == $page_count Then		; Max pages reached
			   ExitLoop
			EndIf

			$pointer = get_pointer_light()
			$a_b_send = get_a_b_send()
			if send_a_b($pointer, $a_b[0], $a_b[1], $a_b_send) < 0 Then
			   ConsoleWrite("NO MORE TROUPS IN THIS VILLAGE LEFT")

			   ExitLoop
			EndIf

			navigate($i)
			Sleep(5000)

			$i = $i + 1
		 WEnd
	  Next

   Else
	  While True
		 For $village in $ids	; Run through the villages
			$i = 1
			_IENavigate($window, $prop & "?village=" & $village & "&screen=am_farm")
			Sleep(5000)
			$a_b = get_a_b_count()
			$page_count = get_page_count()

			While True
			   if $i == $page_count Then		; Max pages reached
				  ExitLoop
			   EndIf

			   $pointer = get_pointer_light()
			   $a_b_send = get_a_b_send()
			   if send_a_b($pointer, $a_b[0], $a_b[1], $a_b_send) < 0 Then
				  ; ConsoleWrite("NO MORE TROUPS IN THIS VILLAGE LEFT")

				  ExitLoop
			   EndIf

			   navigate($i)
			   Sleep(5000)

			   $i = $i + 1
			WEnd
		 Next

		 wait_time($timer)
	  WEnd
   EndIf

EndFunc
