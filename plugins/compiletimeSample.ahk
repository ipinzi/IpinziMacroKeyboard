; Compile-time sample plugin
; Demonstrates custom action functions integrated directly into the macro keyboard
; To use these actions, add this file to main.ahk with: #Include plugins\compiletimeSample.ahk
; Then use the actions in bindings.ini with the format: actionname|param1|param2

; Example usage in bindings.ini:
; default|2_130=sampleversion
; default|2_131=sampleinfo
; default|2_132=samplesystem
; default|2_133=samplehelp
; default|2_134=sampleecho|Hello from compile-time

Action_sampleversion(params, keyboardNumber, vk) {
    version := A_AhkVersion
    info := "AutoHotkey Version`n`n"
    info .= "Version: " version "`n"
    info .= "Platform: " (A_PtrSize = 8 ? "64-bit" : "32-bit") "`n"
    info .= "Is Compiled: " (A_IsCompiled ? "Yes" : "No")
    MsgBox info, "Script Version Info"
}

Action_sampleinfo(params, keyboardNumber, vk) {
    info := "Script Information`n`n"
    info .= "Script Name: " A_ScriptName "`n"
    info .= "Script Dir: " A_ScriptDir "`n"
    info .= "Script Path: " A_ScriptFullPath "`n"
    info .= "Is Compiled: " (A_IsCompiled ? "Yes" : "No")
    MsgBox info, "Script Information"
}

Action_samplesystem(params, keyboardNumber, vk) {
    info := "System Information`n`n"
    info .= "OS Version: " A_OSVersion "`n"
    info .= "Screen Width: " A_ScreenWidth " px`n"
    info .= "Screen Height: " A_ScreenHeight " px"
    MsgBox info, "System Information"
}

Action_sampleecho(params, keyboardNumber, vk) {
    msg := params.Length ? params[1] : "No message provided"
    MsgBox msg, "Sample Echo"
}

Action_samplehelp(params, keyboardNumber, vk) {
    help := "Compile-time Sample Plugin - Available Actions`n`n"
    help .= "• sampleversion  - Show AutoHotkey version and platform info`n"
    help .= "• sampleinfo     - Show script information`n"
    help .= "• samplesystem   - Show system and hardware info`n"
    help .= "• sampleecho     - Echo a message parameter`n"
    help .= "• samplehelp     - Show this help message`n`n"
    help .= "These are compile-time actions (integrated into the EXE).`n"
    help .= "Usage: actionname|param1|param2"
    MsgBox help, "Help - Compile-time Sample"
}
