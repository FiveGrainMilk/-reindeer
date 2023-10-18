#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
Multiplyer := 1
TargetPID := 0 ; 초기값으로 0을 설정
SelectedElancia := "" ; 초기값으로 빈 문자열 설정


Gui, Add, Text, x15 y20 w120 h20 +border +0x201, 순록이 Beta ; 타이틀 표시
Gui, Add, Text, x15 y45 w120 h20 vA, 제작자: L - 오곡밀크 ; 현재 매크로 동작 상태 표시
Gui, Add, Text, x15 y65 w120 h30, 자동사냥O 보조사냥X
Gui, Add, Button, x15 y90 w120 h40 gBtn1, 순록이 시작 ; 순록이 시작
Gui, Add, Button, x15 y140 w120 h40 gBtn2, 순록이 종료 ; 순록이 자동사냥 종료
Gui, Add, ListBox, x145 y20 w143 h165 gClick vElanciaTitle, %ElanTitles%
Gui, Add, Text, x15 y190 w180 h20 vSelectedElancia, 선택된 Elancia: %SelectedElancia%
Gui, show, x1600 y600 w300 h220, 뉴비전용 순록이 0.3Ver
Read_Elancia_Titles() ; Elancia PID창을 초기 한번 불러오기


; Elancia PID List
Read_Elancia_Titles() {
    jElanciaArray := [] ; Elancia 창 ID를 저장할 빈 배열 생성
    Winget, jElanciaArray, List, ahk_class Nexon.Elancia ; Elancia 창 목록을 가져와 ID를 저장
    jElancia_Count := 0 ; Elancia 창의 개수를 초기화
    ElanTitles := "" ; Elancia 제목을 저장할 문자열 초기화


    ; 배열의 각 Elancia 창에 대해 반복
    loop, %jElanciaArray% {
        jElancia := jElanciaArray%A_Index%
        WinGetTitle, Title, ahk_id %jElancia% ; 현재 Elancia 창의 제목 가져오기
        ElanTitles .= Title "|" ; 제목을 ElanTitles 문자열에 "|"로 구분하여 추가
    }
    
    
    ; Listbox 업데이트
    GuiControl,, ElanciaTitle, %ElanTitles%
}


; ListBox Section g일랜시아선택 시 호출될 함수
Click:
Gui, Submit, NoHide
TargetTitle := ElanciaTitle
WinGet, TargetPID, PID, %TargetTitle% ; 선택한 Elancia 창의 PID를 가져옴
SelectedElancia := TargetTitle ; 선택한 Elancia 창의 제목을 SelectedElancia에 저장
GuiControl,, SelectedElancia, 선택된 Elancia: %SelectedElancia%
; 선택한 항목에 대한 추가 동작 수행 가능
return


; Button Functions
Btn1: ; 순록이 시작 버튼 동작
{
	if (SelectedElancia = "") {
		MsgBox,,Process Check, Elancia 창을 선택하세요.
		return
	}
	
	if (TargetPID = 0) {
	}
	
	Gui, Submit, NoHide
	GuiControl,, A, 순록이 동작중...
	Sleep, 500
	Macrostate := true
	While (Macrostate)
	{
		순록이사냥()
	}
}
return


Btn2: ; 순록이 종료 버튼 동작
{
    GuiControl,, A, 매크로 동작종료
    ;MsgBox, 종료 버튼을 눌렀어, 안전한 곳으로 가
    Gui, Submit, NoHide
    Macrostate := false
    ExitApp ; 스크립트 종료
}
return

마우스클릭(X,Y) { ; 마우스 값 
	pid := TargetPid
	MouseX := X * Multiplyer
	MouseY := Y * Multiplyer
	MousePos := MouseX|MouseY<< 16
	PostMessage, 0x200, 0, %MousePos% ,,ahk_pid %pid%
	PostMessage, 0x201, 1, %MousePos% ,,ahk_pid %pid%
	PostMessage, 0x202, 0, %MousePos% ,,ahk_pid %pid%
}


순록이사냥(){ ; Type1. 순록이 자사 CT에서 값이랑 좌표 가져온 몹 OID 방식으로 해보자!
	
;Hint Hint | 멤리 서치 학습용 쏘스들
	
	; 대상 창이 활성화되지 않은 경우, 해당 창을 활성화합니다.
	;IfWinNotActive, %TargetTitle%
	;{
	;	WinActivate, %TargetTitle%
;		Sleep, 30
	;}
	
	; 몬스터 스캔 오픈쏘스 [ 제일 맨 위의 몬스터값을 가져 옵니다. ]
	; https://github.com/Kalamity/classMemory
	;this.processPatternScan(startAddress, endAddress, 0xAC, 0x20, 0x54, 0x00) 
	
	;startaddress := 0 endAddress := 0x7FFFFFFF
	
	;0xAC, 0x20, 0x54, 0x00  ;이걸로 몬스터 구하셨으면, 해당주소를 result라고 가정하면 
	;find_x := mem.read(result + 0x0C, "UInt", aOffsets*)
	;find_y := mem.read(result + 0x10, "UInt", aOffsets*)
	;find_z := mem.read(result + 0x14, "UInt", aOffsets*)  ;이렇게하면 몬스터 좌표가져오는거고
	
	; 몬스터 OID와 몬스터 번호를 찾아서 읽어옵니다.
	;find_oid := mem.read(result + 0x5E, "UInt", aOffsets*) ; 몬스터 OID
	;find_M_Number := mem.read(result + 0x82, "UInt", aOffsets*) ; 몬스터 번호
	
	;자사CT를 이용한 후킹방식으로 할 경우, 0048E1EB 을 후킹해서, ESI 값을 아무 빈곳에 100bytes정도 부여해서
	;4바이트씩 25개 정도 쓰게하고 그걸 오핫으로 읽어오는 방식
	
	
	; ReadMemory 함수는 특정 메모리 주소에서 데이터를 읽어오는 함수입니다.
	
; MADDRESS: 읽어올 메모리 주소를 나타내는 변수입니다.
; PROGRAM: 대상 프로그램의 이름 또는 타이틀입니다.
	
	ReadMemory(MADDRESS, PROGRAM) {
    ; 대상 프로그램의 PID를 가져오기 위해 WinGet을 사용합니다.
		WinGet, pid, PID, %PROGRAM%
		
    ; MVALUE 변수는 메모리에서 읽어온 데이터를 저장하기 위한 변수입니다.
		VarSetCapacity(MVALUE, 4, 0)
		
    ; 대상 프로세스의 핸들을 열어야 합니다. OpenProcess 함수를 사용하여 엽니다.
		ProcessHandle := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", pid, "UInt")
		
    ; ReadProcessMemory 함수를 사용하여 메모리에서 데이터를 읽어옵니다.
		DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Str", MVALUE, "UInt", 4, "UInt *", 0)
		
    ; 결과 값을 저장할 변수인 result를 초기화합니다.
		result := 0
		
    ; 읽어온 4바이트 데이터를 10진수로 변환하여 result에 저장합니다.
		Loop, 4
		{
			result += *(&MVALUE + A_Index - 1) << 8 * (A_Index - 1)
		}
		
    ; 결과 값을 반환합니다.
		return result
	}
	
}

;순록이사냥(){ ; Type2. 구 홍이 자사에서 이용하는 몹 서칭 방식으로 해보자!
	;But 무거움

;}
F3::pause
F4::exitapp
