; Sample plugin script for external execution
; This script is run as a separate process when the "plugin" action is used
; Parameters are passed via command line args in A_Args

#Requires AutoHotkey v2.0

; Example usage in bindings.ini:
; default|2_120=plugin|sample.ahk|msg|Hello World
; default|2_121=plugin|sample.ahk|send|^c

if (A_Args.Length == 0) {
    MsgBox "Sample plugin: No parameters provided."
    ExitApp
}

action := A_Args[1]

switch action {
    case "msg":
        if (A_Args.Length >= 2) {
            MsgBox "msg: " A_Args[2]
        } else {
            MsgBox "Sample plugin: msg action requires a message parameter."
        }
    case "send":
        if (A_Args.Length >= 2) {
            Send A_Args[2]
        } else {
            MsgBox "Sample plugin: send action requires keystrokes parameter."
        }
    default:
        MsgBox "Sample plugin: Unknown action '" action "'. Supported: msg, send"
}