Global ThisWindowTitle := "순록이 - V0.3"

#SingleInstance, off
#NoEnv
#Persistent
#KeyHistory 0
#NoTrayIcon
#Warn All, Off

ListLines, OFF
DetectHiddenText, On
DetectHiddenWindows, On
CoordMode, Mouse, Client
CoordMode, pixel, Client
SetWinDelay, 0
SetControlDelay, 0
SetKeyDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetTitleMatchMode,3
SetBatchLines, -1
Setworkingdir,%a_scriptdir%
Multiplyer := 1 ; 게임 캐릭터 플레이어 조회 갯수
TargetPID := 0 ; 초기값으로 0을 설정
SelectedElancia := "" ; 초기값으로 빈 문자열 설정

class _ClassMemory
{
static baseAddress, hProcess, PID, currentProgram
, insertNullTerminator := True
, readStringLastError := False
, isTarget64bit := False
, ptrType := "UInt"
, aTypeSize := {    "UChar":    1,  "Char":     1
,   "UShort":   2,  "Short":    2
,   "UInt":     4,  "Int":      4
,   "UFloat":   4,  "Float":    4
,   "Int64":    8,  "Double":   8}
, aRights := {  "PROCESS_ALL_ACCESS": 0x001F0FFF
,   "PROCESS_CREATE_PROCESS": 0x0080
,   "PROCESS_CREATE_THREAD": 0x0002
,   "PROCESS_DUP_HANDLE": 0x0040
,   "PROCESS_QUERY_INFORMATION": 0x0400
,   "PROCESS_QUERY_LIMITED_INFORMATION": 0x1000
,   "PROCESS_SET_INFORMATION": 0x0200
,   "PROCESS_SET_QUOTA": 0x0100
,   "PROCESS_SUSPEND_RESUME": 0x0800
,   "PROCESS_TERMINATE": 0x0001
,   "PROCESS_VM_OPERATION": 0x0008
,   "PROCESS_VM_READ": 0x0010
,   "PROCESS_VM_WRITE": 0x0020
,   "SYNCHRONIZE": 0x00100000}
__new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
{
if this.PID := handle := this.findPID(program, windowMatchMode)
{
if dwDesiredAccess is not integer
dwDesiredAccess := this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_VM_OPERATION | this.aRights.PROCESS_VM_READ | this.aRights.PROCESS_VM_WRITE

dwDesiredAccess |= this.aRights.SYNCHRONIZE

if this.hProcess := handle := this.OpenProcess(this.PID, dwDesiredAccess)
{
this.pNumberOfBytesRead := DllCall("GlobalAlloc", "UInt", 0x0040, "Ptr", A_PtrSize, "Ptr")

this.pNumberOfBytesWritten := DllCall("GlobalAlloc", "UInt", 0x0040, "Ptr", A_PtrSize, "Ptr")

this.readStringLastError := False

this.currentProgram := program

if this.isTarget64bit := this.isTargetProcess64Bit(this.PID, this.hProcess, dwDesiredAccess)
this.ptrType := "Int64"

else this.ptrType := "UInt"
if (A_PtrSize != 4 || !this.isTarget64bit)
this.BaseAddress := this.getModuleBaseAddress()

if this.BaseAddress < 0 || !this.BaseAddress
this.BaseAddress := this.getProcessBaseAddress(program, windowMatchMode)

RETURN this

}
}
return
}
__delete()
{
this.closeHandle(this.hProcess)

if this.pNumberOfBytesRead
DllCall("GlobalFree", "Ptr", this.pNumberOfBytesRead)

if this.pNumberOfBytesWritten
DllCall("GlobalFree", "Ptr", this.pNumberOfBytesWritten)

return
}
version()
{
RETURN 2.92

}
findPID(program, windowMatchMode := "3")
{
if RegExMatch(program, "i)\s*AHK_PID\s+(0x[[:xdigit:]]+|\d+)", pid)
RETURN pid1

if windowMatchMode
{
mode := A_TitleMatchMode

STRINGREPLACE,windowMatchMode,windowMatchMode,0x

SETTITLEMATCHMODE,%windowMatchMode%

}
WINGET,pid,pid,%program%

if windowMatchMode
SETTITLEMATCHMODE,%mode%

if (!pid && RegExMatch(program, "i)\bAHK_EXE\b\s*(.*)", fileName))
{
filename := RegExReplace(filename1, "i)\bahk_(class|id|pid|group)\b.*", "")

filename := trim(filename)

SPLITPATH,fileName,fileName

if (fileName)
{
PROCESS,Exist,%fileName%

pid := ErrorLevel

}
}
RETURN pid ? pid : 0

}
isHandleValid()
{
RETURN 0x102 = DllCall("WaitForSingleObject", "Ptr", this.hProcess, "UInt", 0)

}
openProcess(PID, dwDesiredAccess)
{
r := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr")

if (!r && A_LastError = 5)
{
this.setSeDebugPrivilege(true)

if (r2 := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr"))
RETURN r2

DllCall("SetLastError", "UInt", 5)

}
RETURN r ? r : ""

}
closeHandle(hProcess)
{
RETURN DllCall("CloseHandle", "Ptr", hProcess)

}
numberOfBytesRead()
{
RETURN !this.pNumberOfBytesRead ? -1 : NumGet(this.pNumberOfBytesRead+0, "Ptr")

}
numberOfBytesWritten()
{
RETURN !this.pNumberOfBytesWritten ? -1 : NumGet(this.pNumberOfBytesWritten+0, "Ptr")

}
read(address, type := "UInt", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
RETURN "", ErrorLevel := -2

if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", result, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesRead)
RETURN result

return
}
readRaw(address, byRef buffer, bytes := 4, aOffsets*)
{
VarSetCapacity(buffer, bytes)

RETURN DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", bytes, "Ptr", this.pNumberOfBytesRead)

}
readString(address, sizeBytes := 0, encoding := "UTF-8", aOffsets*)
{
bufferSize := VarSetCapacity(buffer, sizeBytes ? sizeBytes : 100, 0)

this.ReadStringLastError := False

if aOffsets.maxIndex()
address := this.getAddressFromOffsets(address, aOffsets*)

if !sizeBytes
{
if (encoding = "utf-16" || encoding = "cp1200")
encodingSize := 2, charType := "UShort", loopCount := 2

else encodingSize := 1, charType := "Char", loopCount := 4
Loop
{
if !DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address + ((outterIndex := A_index) - 1) * 4, "Ptr", &buffer, "Ptr", 4, "Ptr", this.pNumberOfBytesRead) || ErrorLevel
RETURN "", this.ReadStringLastError := True

else loop, %loopCount%
{
if NumGet(buffer, (A_Index - 1) * encodingSize, charType) = 0
{
if (bufferSize < sizeBytes := outterIndex * 4 - (4 - A_Index * encodingSize))
VarSetCapacity(buffer, sizeBytes)

BREAK,2

}
}
}
}
if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesRead)
RETURN StrGet(&buffer,, encoding)

RETURN "", this.ReadStringLastError := True

}
writeString(address, string, encoding := "utf-8", aOffsets*)
{
encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1

requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)

VarSetCapacity(buffer, requiredSize)

StrPut(string, &buffer, StrLen(string) + (this.insertNullTerminator ?  1 : 0), encoding)

RETURN DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", requiredSize, "Ptr", this.pNumberOfBytesWritten)

}
write(address, value, type := "Uint", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
RETURN "", ErrorLevel := -2

RETURN DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", value, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesWritten)

}
writeRaw(address, pBuffer, sizeBytes, aOffsets*)
{
RETURN DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", pBuffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesWritten)

}
writeBytes(address, hexStringOrByteArray, aOffsets*)
{
if !IsObject(hexStringOrByteArray)
{
if !IsObject(hexStringOrByteArray := this.hexStringToPattern(hexStringOrByteArray))
RETURN hexStringOrByteArray

}
sizeBytes := this.getNeedleFromAOBPattern("", buffer, hexStringOrByteArray*)

RETURN this.writeRaw(address, &buffer, sizeBytes, aOffsets*)

}
pointer(address, finalType := "UInt", offsets*)
{
For index, offset in offsets
address := this.Read(address, this.ptrType) + offset

RETURN this.Read(address, finalType)

}
getAddressFromOffsets(address, aOffsets*)
{
RETURN aOffsets.Remove() + this.pointer(address, this.ptrType, aOffsets*)

}
getProcessBaseAddress(windowTitle, windowMatchMode := "3")
{
if (windowMatchMode && A_TitleMatchMode != windowMatchMode)
{
mode := A_TitleMatchMode

STRINGREPLACE,windowMatchMode,windowMatchMode,0x

SETTITLEMATCHMODE,%windowMatchMode%

}
WINGET,hWnd,ID,%WindowTitle%

if mode
SETTITLEMATCHMODE,%mode%

if !hWnd
return
RETURN DllCall(A_PtrSize = 4 ? "GetWindowLong" : "GetWindowLongPtr", "Ptr", hWnd, "Int", -6, A_Is64bitOS ? "Int64" : "UInt")

}
getModuleBaseAddress(moduleName := "", byRef aModuleInfo := "")
{
aModuleInfo := ""

if (moduleName = "")
moduleName := this.GetModuleFileNameEx(0, True)

if r := this.getModules(aModules, True) < 0
RETURN r

RETURN aModules.HasKey(moduleName) ? (aModules[moduleName].lpBaseOfDll, aModuleInfo := aModules[moduleName]) : -1

}
getModuleFromAddress(address, byRef aModuleInfo, byRef offsetFromModuleBase := "")
{
aModuleInfo := offsetFromModule := ""

if result := this.getmodules(aModules) < 0
RETURN result

for k, module in aModules
{
if (address >= module.lpBaseOfDll && address < module.lpBaseOfDll + module.SizeOfImage)
RETURN 1, aModuleInfo := module, offsetFromModuleBase := address - module.lpBaseOfDll

}
RETURN -1

}
setSeDebugPrivilege(enable := True)
{
h := DllCall("OpenProcess", "UInt", 0x0400, "Int", false, "UInt", DllCall("GetCurrentProcessId"), "Ptr")

DllCall("Advapi32.dll\OpenProcessToken", "Ptr", h, "UInt", 32, "PtrP", t)

VarSetCapacity(ti, 16, 0)

NumPut(1, ti, 0, "UInt")

DllCall("Advapi32.dll\LookupPrivilegeValue", "Ptr", 0, "Str", "SeDebugPrivilege", "Int64P", luid)

NumPut(luid, ti, 4, "Int64")

if enable
NumPut(2, ti, 12, "UInt")

r := DllCall("Advapi32.dll\AdjustTokenPrivileges", "Ptr", t, "Int", false, "Ptr", &ti, "UInt", 0, "Ptr", 0, "Ptr", 0)

DllCall("CloseHandle", "Ptr", t)

DllCall("CloseHandle", "Ptr", h)

RETURN r

}
isTargetProcess64Bit(PID, hProcess := "", currentHandleAccess := "")
{
if !A_Is64bitOS
RETURN False

else if !hProcess || !(currentHandleAccess & (this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_QUERY_LIMITED_INFORMATION))
closeHandle := hProcess := this.openProcess(PID, this.aRights.PROCESS_QUERY_INFORMATION)

if (hProcess && DllCall("IsWow64Process", "Ptr", hProcess, "Int*", Wow64Process))
result := !Wow64Process

RETURN result, closeHandle ? this.CloseHandle(hProcess) : ""

}
suspend()
{
RETURN DllCall("ntdll\NtSuspendProcess", "Ptr", this.hProcess)

}
resume()
{
RETURN DllCall("ntdll\NtResumeProcess", "Ptr", this.hProcess)

}
getModules(byRef aModules, useFileNameAsKey := False)
{
if (A_PtrSize = 4 && this.IsTarget64bit)
RETURN -4

aModules := []

if !moduleCount := this.EnumProcessModulesEx(lphModule)
RETURN -3

loop % moduleCount
{
this.GetModuleInformation(hModule := numget(lphModule, (A_index - 1) * A_PtrSize), aModuleInfo)

aModuleInfo.Name := this.GetModuleFileNameEx(hModule)

filePath := aModuleInfo.name

SPLITPATH,filePath,fileName

aModuleInfo.fileName := fileName

if useFileNameAsKey
aModules[fileName] := aModuleInfo

else aModules.insert(aModuleInfo)
}
RETURN moduleCount

}
getEndAddressOfLastModule(byRef aModuleInfo := "")
{
if !moduleCount := this.EnumProcessModulesEx(lphModule)
RETURN -3

hModule := numget(lphModule, (moduleCount - 1) * A_PtrSize)

if this.GetModuleInformation(hModule, aModuleInfo)
RETURN aModuleInfo.lpBaseOfDll + aModuleInfo.SizeOfImage

RETURN -5

}
GetModuleFileNameEx(hModule := 0, fileNameNoPath := False)
{
VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))

DllCall("psapi\GetModuleFileNameEx", "Ptr", this.hProcess, "Ptr", hModule, "Str", lpFilename, "Uint", 2048 / (A_IsUnicode ? 2 : 1))

if fileNameNoPath
SPLITPATH,lpFilename,lpFilename

RETURN lpFilename

}
EnumProcessModulesEx(byRef lphModule, dwFilterFlag := 0x03)
{
lastError := A_LastError

size := VarSetCapacity(lphModule, 4)

loop
{
DllCall("psapi\EnumProcessModulesEx", "Ptr", this.hProcess, "Ptr", &lphModule, "Uint", size, "Uint*", reqSize, "Uint", dwFilterFlag)

if ErrorLevel
RETURN 0

else if (size >= reqSize)
break
else size := VarSetCapacity(lphModule, reqSize)
}
DllCall("SetLastError", "UInt", lastError)

RETURN reqSize // A_PtrSize

}
GetModuleInformation(hModule, byRef aModuleInfo)
{
VarSetCapacity(MODULEINFO, A_PtrSize * 3), aModuleInfo := []

RETURN DllCall("psapi\GetModuleInformation", "Ptr", this.hProcess, "Ptr", hModule, "Ptr", &MODULEINFO, "UInt", A_PtrSize * 3), aModuleInfo := {  lpBaseOfDll: numget(MODULEINFO, 0, "Ptr"),   SizeOfImage: numget(MODULEINFO, A_PtrSize, "UInt"),   EntryPoint: numget(MODULEINFO, A_PtrSize * 2, "Ptr") }

}
hexStringToPattern(hexString)
{
AOBPattern := []

hexString := RegExReplace(hexString, "(\s|0x)")

STRINGREPLACE,hexString,hexString,?,?,UseErrorLevel

wildCardCount := ErrorLevel

if !length := StrLen(hexString)
RETURN -1

else if RegExMatch(hexString, "[^0-9a-fA-F?]")
RETURN -2

else if Mod(wildCardCount, 2)
RETURN -3

else if Mod(length, 2)
RETURN -4

loop, % length/2
{
value := "0x" SubStr(hexString, 1 + 2 * (A_index-1), 2)

AOBPattern.Insert(value + 0 = "" ? "?" : value)

}
RETURN AOBPattern

}
stringToPattern(string, encoding := "UTF-8", insertNullTerminator := False)
{
if !length := StrLen(string)
RETURN -1

AOBPattern := []

encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1

requiredSize := StrPut(string, encoding) * encodingSize - (insertNullTerminator ? 0 : encodingSize)

VarSetCapacity(buffer, requiredSize)

StrPut(string, &buffer, length + (insertNullTerminator ?  1 : 0), encoding)

loop, % requiredSize
AOBPattern.Insert(NumGet(buffer, A_Index-1, "UChar"))

RETURN AOBPattern

}
modulePatternScan(module := "", aAOBPattern*)
{
MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000, PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100

if (result := this.getModuleBaseAddress(module, aModuleInfo)) <= 0
RETURN "", ErrorLevel := result

if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
RETURN -10

if (result := this.PatternScan(aModuleInfo.lpBaseOfDll, aModuleInfo.SizeOfImage, patternMask, AOBBuffer)) >= 0
RETURN result

address := aModuleInfo.lpBaseOfDll

endAddress := address + aModuleInfo.SizeOfImage

loop
{
if !this.VirtualQueryEx(address, aRegion)
RETURN -9

if (aRegion.State = MEM_COMMIT
&& !(aRegion.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aRegion.RegionSize >= patternSize
&& (result := this.PatternScan(address, aRegion.RegionSize, patternMask, AOBBuffer)) > 0)
RETURN result

} until (address += aRegion.RegionSize) >= endAddress
RETURN 0

}
addressPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
RETURN -10

RETURN this.PatternScan(startAddress, sizeOfRegionBytes, patternMask, AOBBuffer)

}
processPatternScan(startAddress := 0, endAddress := "", aAOBPattern*)
{
address := startAddress

if endAddress is not integer
endAddress := this.isTarget64bit ? (A_PtrSize = 8 ? 0x7FFFFFFFFFF : 0xFFFFFFFF) : 0x7FFFFFFF

MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000

PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100

if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
RETURN -10

while address <= endAddress
{
if !this.VirtualQueryEx(address, aInfo)
RETURN -1

if A_Index = 1
aInfo.RegionSize -= address - aInfo.BaseAddress

if (aInfo.State = MEM_COMMIT)
&& !(aInfo.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aInfo.RegionSize >= patternSize
&& (result := this.PatternScan(address, aInfo.RegionSize, patternMask, AOBBuffer))
{
if result < 0
RETURN -2

else if (result + patternSize - 1 <= endAddress)
RETURN result

else return 0
}
address += aInfo.RegionSize

}
RETURN 0

}
rawPatternScan(byRef buffer, sizeOfBufferBytes := "", startOffset := 0, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
RETURN -10

if (sizeOfBufferBytes + 0 = "" || sizeOfBufferBytes <= 0)
sizeOfBufferBytes := VarSetCapacity(buffer)

if (startOffset + 0 = "" || startOffset < 0)
startOffset := 0

RETURN this.bufferScanForMaskedPattern(&buffer, sizeOfBufferBytes, patternMask, &AOBBuffer, startOffset)

}
getNeedleFromAOBPattern(byRef patternMask, byRef needleBuffer, aAOBPattern*)
{
patternMask := "", VarSetCapacity(needleBuffer, aAOBPattern.MaxIndex())

for i, v in aAOBPattern
patternMask .= (v + 0 = "" ? "?" : "x"), NumPut(round(v), needleBuffer, A_Index - 1, "UChar")

RETURN round(aAOBPattern.MaxIndex())

}
VirtualQueryEx(address, byRef aInfo)
{
if (aInfo.__Class != "_ClassMemory._MEMORY_BASIC_INFORMATION")
aInfo := new this._MEMORY_BASIC_INFORMATION()

RETURN aInfo.SizeOfStructure = DLLCall("VirtualQueryEx", "Ptr", this.hProcess, "Ptr", address, "Ptr", aInfo.pStructure, "Ptr", aInfo.SizeOfStructure, "Ptr")

}
patternScan(startAddress, sizeOfRegionBytes, byRef patternMask, byRef needleBuffer)
{
if !this.readRaw(startAddress, buffer, sizeOfRegionBytes)
RETURN -1

if (offset := this.bufferScanForMaskedPattern(&buffer, sizeOfRegionBytes, patternMask, &needleBuffer)) >= 0
RETURN startAddress + offset

else return 0
}
bufferScanForMaskedPattern(hayStackAddress, sizeOfHayStackBytes, byRef patternMask, needleAddress, startOffset := 0)
{
static p
if !p
{
if A_PtrSize = 4
p := this.MCode("1,x86:8B44240853558B6C24182BC5568B74242489442414573BF0773E8B7C241CBB010000008B4424242BF82BD8EB038D49008B54241403D68A0C073A0A740580383F750B8D0C033BCD74174240EBE98B442424463B74241876D85F5E5D83C8FF5BC35F8BC65E5D5BC3")

else
p := this.MCode("1,x64:48895C2408488974241048897C2418448B5424308BF2498BD8412BF1488BF9443BD6774A4C8B5C24280F1F800000000033C90F1F400066660F1F840000000000448BC18D4101418D4AFF03C80FB60C3941380C18740743803C183F7509413BC1741F8BC8EBDA41FFC2443BD676C283C8FF488B5C2408488B742410488B7C2418C3488B5C2408488B742410488B7C2418418BC2C3")

}
if (needleSize := StrLen(patternMask)) + startOffset > sizeOfHayStackBytes
RETURN -1

if (sizeOfHayStackBytes > 0)
RETURN DllCall(p, "Ptr", hayStackAddress, "UInt", sizeOfHayStackBytes, "Ptr", needleAddress, "UInt", needleSize, "AStr", patternMask, "UInt", startOffset, "cdecl int")

RETURN -2

}
MCode(mcode)
{
static e := {1:4, 2:1}, c := (A_PtrSize=8) ? "x64" : "x86"
if !regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m)
return
if !DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0)
return
p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")

DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)

if DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0)
RETURN p

DllCall("GlobalFree", "ptr", p)

return
}
class _MEMORY_BASIC_INFORMATION
{
__new()
{
if !this.pStructure := DllCall("GlobalAlloc", "UInt", 0, "Ptr", this.SizeOfStructure := A_PtrSize = 8 ? 48 : 28, "Ptr")
RETURN ""

RETURN this

}
__Delete()
{
DllCall("GlobalFree", "Ptr", this.pStructure)

}
__get(key)
{
static aLookUp := A_PtrSize = 8
?   {   "BaseAddress": {"Offset": 0, "Type": "Int64"}
,    "AllocationBase": {"Offset": 8, "Type": "Int64"}
,    "AllocationProtect": {"Offset": 16, "Type": "UInt"}
,    "RegionSize": {"Offset": 24, "Type": "Int64"}
,    "State": {"Offset": 32, "Type": "UInt"}
,    "Protect": {"Offset": 36, "Type": "UInt"}
,    "Type": {"Offset": 40, "Type": "UInt"} }
:   {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
,   "RegionSize": {"Offset": 12, "Type": "UInt"}
,   "State": {"Offset": 16, "Type": "UInt"}
,   "Protect": {"Offset": 20, "Type": "UInt"}
,   "Type": {"Offset": 24, "Type": "UInt"} }
if aLookUp.HasKey(key)
RETURN numget(this.pStructure+0, aLookUp[key].Offset, aLookUp[key].Type)

}
__set(key, value)
{
static aLookUp := A_PtrSize = 8
?   {   "BaseAddress": {"Offset": 0, "Type": "Int64"}
,    "AllocationBase": {"Offset": 8, "Type": "Int64"}
,    "AllocationProtect": {"Offset": 16, "Type": "UInt"}
,    "RegionSize": {"Offset": 24, "Type": "Int64"}
,    "State": {"Offset": 32, "Type": "UInt"}
,    "Protect": {"Offset": 36, "Type": "UInt"}
,    "Type": {"Offset": 40, "Type": "UInt"} }
:   {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
,   "RegionSize": {"Offset": 12, "Type": "UInt"}
,   "State": {"Offset": 16, "Type": "UInt"}
,   "Protect": {"Offset": 20, "Type": "UInt"}
,   "Type": {"Offset": 24, "Type": "UInt"} }
if aLookUp.HasKey(key)
{
NumPut(value, this.pStructure+0, aLookUp[key].Offset, aLookUp[key].Type)

RETURN value

}
}
Ptr()
{
RETURN this.pStructure

}
sizeOf()
{
RETURN this.SizeOfStructure

}
}
}

; Gui

Gui, Add, Text, x15 y20 w120 h20 +border +0x201, 순록이 Beta ; 타이틀 표시
Gui, Add, Text, x15 y45 w120 h20 vA, 제작자: L - 오곡밀크 ; 현재 매크로 동작 상태 표시
Gui, Add, Text, x15 y65 w120 h30, 자동사냥O 보조사냥X
Gui, Add, Button, x15 y90 w120 h40 gBtn1, 순록이 시작 ; 순록이 시작
Gui, Add, Button, x15 y140 w120 h40 gBtn2, 순록이 종료 ; 순록이 자동사냥 종료
Gui, Add, ListBox, x145 y20 w143 h165 gClick vElanciaTitle, %ElanTitles%
Gui, Add, Text, x15 y190 w180 h20 vSelectedElancia, 선택된 Elancia: %SelectedElancia%
Gui, show, x1600 y600 w300 h220, %ThisWindowTitle%
Read_Elancia_Titles() ; Elancia PID창을 초기 한번 불러오기

; ListBox Section 리스트박스에서 gClick 시 호출될 함수
Click:
Gui, Submit, NoHide
TargetTitle := ElanciaTitle
WinGet, TargetPID, PID, %TargetTitle% ; 선택한 Elancia 창의 PID를 가져옴
SelectedElancia := TargetTitle ; 선택한 Elancia 창의 제목을 SelectedElancia에 저장
GuiControl,, SelectedElancia, 선택된 Elancia: %SelectedElancia%
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
		ATT1()
	}
}
return


Btn2: ; 순록이 종료 버튼 동작
{
	GuiControl,, A, 매크로 동작종료
	Gui, Submit, NoHide
	Macrostate := false
	wall_remove_disable()
	floor_remove_disable()
	char_remove_disable()
	ExitApp ; 스크립트 종료
}
return


;STEP1.
Read_Elancia_Titles() { ;*[ݸ؏L0.3]
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

;STEP2.
;탈것 제거
ride_enable(){
		WriteMemory(0x0046035B, 0x90, "char")
		WriteMemory(0x0046035C, 0x90, "char")
		WriteMemory(0x0046035D, 0x90, "char")
		WriteMemory(0x0046035E, 0x90, "char")
		WriteMemory(0x0046035F, 0x90, "char")
		WriteMemory(0x00460360, 0x90, "char")
	}
	
	ride_disable(){
		WriteMemory(0x0046035B, 0x89, "char")
		WriteMemory(0x0046035C, 0x83, "char")
		WriteMemory(0x0046035D, 0x6B, "char")
		WriteMemory(0x0046035E, 0x01, "char")
		WriteMemory(0x0046035F, 0x00, "char")
		WriteMemory(0x00460360, 0x00, "char")
	}
	
;벽제거
wall_remove_enable(){
		WriteMemory(0x0047AA5B,  0xEB, "char")
	}
	
	wall_remove_disable(){
		WriteMemory(0x0047AA5B,  0x7d, "char")
	}
	
;땅제거
floor_remove_enable(){
		WriteMemory(0x0047A196,  0xEB, "char")
	}
	floor_remove_disable(){
		WriteMemory(0x0047A196,  0x75, "char")
	}
	
;캐릭터 제거
char_remove_enable(){
		WriteMemory(0x0045D28F,  0xE9, "char")
		WriteMemory(0x0045D290,  0x8A, "char")
		WriteMemory(0x0045D291,  0x0A, "char")
		WriteMemory(0x0045D292,  0x00, "char")
		WriteMemory(0x0045D293,  0x00, "char")
	}
	char_remove_disable(){
		WriteMemory(0x0045D28F,  0x0F, "char")
		WriteMemory(0x0045D290,  0x84, "char")
		WriteMemory(0x0045D291,  0xC2, "char")
		WriteMemory(0x0045D292,  0x00, "char")
		WriteMemory(0x0045D293,  0x00, "char")
	}

;step3.

;Attack

ATT1(){
	Gui, Submit, nohide
	Guicontrol,, Statusline, 순록이 셋팅중..
	WindowTitle := Player1Title
	if(isFirstTimeRunThisCode := 1){
		wall_remove_enable()
		floor_remove_enable()
		char_remove_enable()
		isFirstTimeRunThisCode := 0
		sleep, 100
	}
	return
}

마우스클릭(X,Y) { ; 마우스 값 
	pid := TargetPid
	MouseX := X * Multiplyer
	MouseY := Y * Multiplyer
	MousePos := MouseX|MouseY<< 16
	PostMessage, 0x200, 0, %MousePos% ,,ahk_pid %pid%
	PostMessage, 0x201, 1, %MousePos% ,,ahk_pid %pid%
	PostMessage, 0x202, 0, %MousePos% ,,ahk_pid %pid%
}

;제거 함수 호출
WriteMemory(WriteAddress = "", Data="", TypeOrLength = ""){ ;*[H_Elancia_V1.0.3]
	PROGRAM:=WindowTitle
	Static OLDPROC, hProcess, pid
	If (PROGRAM != OLDPROC){
		if hProcess
			closed := DllCall("CloseHandle", "UInt", hProcess), hProcess := 0, OLDPROC := ""
		if PROGRAM{
			WinGet, pid, pid, % OLDPROC := PROGRAM
			jPID = pid
			if !pid
			return "Process Doesn't Exist", OLDPROC := ""
			hProcess := DllCall("OpenProcess", "Int", 0x8 | 0x20, "Int", 0, "UInt", pid)
			}
		}
	If Data is Number
		{
		If TypeOrLength is Integer
			{
			DataAddress := Data
			DataSize := TypeOrLength
			}
		Else{
			If (TypeOrLength = "Double" or TypeOrLength = "Int64")
				DataSize = 8
			Else If (TypeOrLength = "Int" or TypeOrLength = "UInt" or TypeOrLength = "Float")
				DataSize = 4
			Else If (TypeOrLength = "Short" or TypeOrLength = "UShort")
				DataSize = 2
			Else If (TypeOrLength = "Char" or TypeOrLength = "UChar")
				DataSize = 1
			Else {
				Return False
				}
			VarSetCapacity(Buf, DataSize, 0)
			NumPut(Data, Buf, 0, TypeOrLength)
			DataAddress := &Buf
			}
		}
	Else{
		DataAddress := &Data
		If TypeOrLength is Integer
			{
			If A_IsUnicode
			DataSize := TypeOrLength * 2
			Else
			DataSize := TypeOrLength
			}
		Else{
			If A_IsUnicode
				DataSize := (StrLen(Data) + 1) * 2
			Else
				DataSize := StrLen(Data) + 1
			}
		}
	if (hProcess && DllCall("WriteProcessMemory", "UInt", hProcess
	, "UInt", WriteAddress
	, "UInt", DataAddress
	, "UInt", DataSize
	, "UInt", 0))
	return
	else return !hProcess ? "Handle Closed:" closed : "Fail"
}
