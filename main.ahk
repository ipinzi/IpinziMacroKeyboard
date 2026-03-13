#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

#Include lib\Globals.ahk
#Include lib\Utils.ahk
#Include lib\Config.ahk
#Include lib\RunHelpers.ahk
#Include lib\OBS.ahk
#Include lib\Capture.ahk
#Include lib\Actions.ahk
#Include lib\Bindings.ahk
#Include lib\MultiKB.ahk

EnsureDefaultConfig()
LoadBindings()
StartMultiKB()

SetTimer WatchConfigFile, 1000
OnMessage(1325, MsgFunc)

TrayTip "Macros are now active.", "Ipinzi's Macro Keyboard", 1
