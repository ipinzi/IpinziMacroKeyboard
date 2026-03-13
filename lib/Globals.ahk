global ConfigFile := A_ScriptDir "\bindings.ini"
global MultiKBPath := A_ScriptDir "\data\MultiKB_For_AutoHotkey.exe"
global UnmappedLogFile := A_ScriptDir "\unmapped_keys.log"
global OBSHelperPath := A_ScriptDir "\data\obs_helper.ps1"

global MacroMap := Map()
global CurrentLayer := "default"
global DebugTooltips := true
global ConfigLastModified := ""

global LastUnmappedKeyId := ""
global LastUnmappedTick := 0

global CaptureMode := false
global CaptureLayer := ""
