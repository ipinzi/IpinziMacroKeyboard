#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

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

EnsureDefaultConfig()
LoadBindings()
StartMultiKB()

SetTimer WatchConfigFile, 1000
OnMessage(1325, MsgFunc)

TrayTip "Macros are now active.", "Ipinzi's Macro Keyboard", 1

MsgFunc(wParam, lParam, msg, hwnd)
{
    global MacroMap, CurrentLayer, CaptureMode

    keyboardNumber := wParam
    vk := lParam & 0xFF
    isDown := (lParam & 0x100) > 0
    wasDown := (lParam & 0x200) > 0
    isExtended := (lParam & 0x400) > 0
    leftCtrl := (lParam & 0x800) > 0
    rightCtrl := (lParam & 0x1000) > 0
    leftAlt := (lParam & 0x2000) > 0
    rightAlt := (lParam & 0x4000) > 0
    shift := (lParam & 0x8000) > 0

    if !isDown
        return

    if CaptureMode
    {
        HandleCaptureKey(CurrentLayer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift)
        return
    }

    keyId := CurrentLayer "|" keyboardNumber "_" vk

    if MacroMap.Has(keyId)
    {
        ExecuteBinding(MacroMap[keyId], keyboardNumber, vk)
        return
    }

    ShowUnmappedKeyInfo(
        CurrentLayer,
        keyboardNumber,
        vk,
        wasDown,
        isExtended,
        leftCtrl,
        rightCtrl,
        leftAlt,
        rightAlt,
        shift
    )
}

ExecuteBinding(binding, keyboardNumber, vk)
{
    global CurrentLayer, DebugTooltips, ConfigFile

    parts := StrSplit(binding, "|", , 2)
    actionType := StrLower(parts[1])
    actionValue := parts.Length >= 2 ? parts[2] : ""

    pos := InStr(actionValue, "\", , -1)
    actionDir := pos ? SubStr(actionValue, 1, pos - 1) : ""

    switch actionType
    {
        case "run":
            try
            {
                exeName := actionValue
                SplitPath actionValue, &exeName

                if ProcessExist(exeName)
                {
                    if WinExist("ahk_exe " exeName)
                    {
                        WinActivate
                        return
                    }
                }

                if (actionDir != "")
                    Run actionValue, actionDir
                else
                    Run actionValue
            }
            catch Error as err
                MsgBox "Failed to run:`n" actionValue "`n`n" err.Message

        case "send":
            Send actionValue

        case "msg":
            MsgBox actionValue

        case "layer":
            CurrentLayer := actionValue
            if DebugTooltips
            {
                ToolTip "Layer: " CurrentLayer
                SetTimer ClearToolTip, -700
            }

        case "media":
            HandleMediaAction(actionValue)

        case "folder":
            try Run actionValue
            catch Error as err
                MsgBox "Failed to open folder:`n" actionValue "`n`n" err.Message

        case "website":
            try Run actionValue
            catch Error as err
                MsgBox "Failed to open website:`n" actionValue "`n`n" err.Message

        case "editbindings":
            try Run 'notepad.exe "' ConfigFile '"'
            catch Error as err
                MsgBox "Failed to open bindings file.`n`n" err.Message

        case "capture":
            StartCaptureMode()

        case "obs_scene":
            OBS_Call("SetCurrentProgramScene", Map("sceneName", actionValue))

        case "obs_record":
            switch StrLower(actionValue)
            {
                case "start":
                    OBS_Call("StartRecord")
                case "stop":
                    OBS_Call("StopRecord")
                case "toggle":
                    OBS_Call("ToggleRecord")
                default:
                    MsgBox "Unknown obs_record action:`n" actionValue
            }

        case "obs_stream":
            switch StrLower(actionValue)
            {
                case "start":
                    OBS_Call("StartStream")
                case "stop":
                    OBS_Call("StopStream")
                case "toggle":
                    OBS_Call("ToggleStream")
                default:
                    MsgBox "Unknown obs_stream action:`n" actionValue
            }

        case "obs_hotkey":
            OBS_Call("TriggerHotkeyByName", Map("hotkeyName", actionValue))

        case "obs_mute":
            HandleOBSMute(actionValue)

        default:
            MsgBox "Unknown action type:`n" actionType "`n`nBinding:`n" binding
    }
}

HandleMediaAction(action)
{
    switch StrLower(action)
    {
        case "playpause":
            Send "{Media_Play_Pause}"
        case "next":
            Send "{Media_Next}"
        case "prev":
            Send "{Media_Prev}"
        case "stop":
            Send "{Media_Stop}"
        case "mute":
            Send "{Volume_Mute}"
        case "volup":
            Send "{Volume_Up}"
        case "voldown":
            Send "{Volume_Down}"
        default:
            MsgBox "Unknown media action:`n" action
    }
}

StartCaptureMode()
{
    global CaptureMode, CaptureLayer, CurrentLayer, DebugTooltips

    CaptureMode := true
    CaptureLayer := CurrentLayer

    if DebugTooltips
    {
        ToolTip "Capture mode enabled`nPress the key you want to bind..."
        SetTimer ClearToolTip, -2000
    }
}

HandleCaptureKey(layer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift)
{
    global CaptureMode, CaptureLayer, DebugTooltips, UnmappedLogFile

    keyName := GetKeyName(Format("vk{:02X}", vk))
    if (keyName = "")
        keyName := "Unknown"

    bindingKey := CaptureLayer "|" keyboardNumber "_" vk

    result := RunBindingWizard(bindingKey, keyName)
    CaptureMode := false

    if !result.Success
    {
        if DebugTooltips
        {
            ToolTip "Binding wizard cancelled"
            SetTimer ClearToolTip, -1500
        }
        return
    }

    AddBindingToIni(bindingKey, result.BindingValue)
    LoadBindings()

    fullLine := bindingKey "=" result.BindingValue

    A_Clipboard := ""
    Sleep 30
    A_Clipboard := fullLine
    ClipWait 0.5

    tooltipText :=
    (
        "Binding added"
        . "`nKey: " keyName
        . "`n" fullLine
        . "`nCopied to clipboard"
    )

    if DebugTooltips
    {
        ToolTip tooltipText
        SetTimer ClearToolTip, -3500
    }

    logLine :=
    (
        FormatTime(, "yyyy-MM-dd HH:mm:ss")
        . " | CaptureMode"
        . " | Layer=" CaptureLayer
        . " | Keyboard=" keyboardNumber
        . " | VK=" vk
        . " | Key=" keyName
        . " | AddedBinding=" fullLine
        . " | WasDown=" (wasDown ? "1" : "0")
        . " | Extended=" (isExtended ? "1" : "0")
        . " | LCtrl=" (leftCtrl ? "1" : "0")
        . " | RCtrl=" (rightCtrl ? "1" : "0")
        . " | LAlt=" (leftAlt ? "1" : "0")
        . " | RAlt=" (rightAlt ? "1" : "0")
        . " | Shift=" (shift ? "1" : "0")
        . "`n"
    )

    try FileAppend(logLine, UnmappedLogFile, "UTF-8")
}
RunBindingWizard(bindingKey, keyName)
{
    actionChoice := ShowBindingTypePicker(bindingKey, keyName)
    if (actionChoice = "")
        return { Success: false }

    actionType := ""
    actionValue := ""

    switch actionChoice
    {
        case "1":
        {
            actionType := "run"
            valueDialog := InputBox(
                "Enter program, file, or command to run.`n`nExamples:`nnotepad.exe`nC:\Tools\app.exe",
                "Run Action",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "2":
        {
            actionType := "send"
            valueDialog := InputBox(
                "Enter the keys to send.`n`nExamples:`n^c`n!{Tab}`nHello world",
                "Send Action",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "3":
        {
            actionType := "msg"
            valueDialog := InputBox(
                "Enter the message text to show.",
                "Message Action",
                "w500 h160"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "4":
        {
            actionType := "media"
            valueDialog := InputBox(
                "Enter media action:`n`nplaypause`nnext`nprev`nstop`nmute`nvolup`nvoldown",
                "Media Action",
                "w500 h220"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := StrLower(Trim(valueDialog.Value))
        }

        case "5":
        {
            actionType := "layer"
            valueDialog := InputBox(
                "Enter layer name to switch to.`n`nExample:`ndefault`nmedia`nunity",
                "Layer Action",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := Trim(valueDialog.Value)
        }

        case "6":
        {
            actionType := "folder"
            valueDialog := InputBox(
                "Enter folder path.`n`nExample:`nC:\Projects",
                "Folder Action",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "7":
        {
            actionType := "website"
            valueDialog := InputBox(
                "Enter website URL.`n`nExample:`nhttps://www.google.com",
                "Website Action",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "8":
        {
            actionType := "editbindings"
            actionValue := ""
        }

        case "9":
        {
            actionType := "obs_scene"
            valueDialog := InputBox(
                "Enter the exact OBS scene name.`n`nExample:`nStarting Soon",
                "OBS Scene",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        case "10":
        {
            actionType := "obs_record"
            valueDialog := InputBox(
                "Enter OBS recording action:`n`nstart`nstop`ntoggle",
                "OBS Recording",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := StrLower(Trim(valueDialog.Value))
        }

        case "11":
        {
            actionType := "obs_stream"
            valueDialog := InputBox(
                "Enter OBS streaming action:`n`nstart`nstop`ntoggle",
                "OBS Streaming",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := StrLower(Trim(valueDialog.Value))
        }

        case "12":
        {
            actionType := "obs_mute"

            obsInputDialog := InputBox(
                "Enter the exact OBS input name.`n`nExamples:`nMic/Aux`nDesktop Audio",
                "OBS Mute Input",
                "w500 h180"
            )
            if (obsInputDialog.Result != "OK")
                return { Success: false }

            obsModeDialog := InputBox(
                "Enter mute action:`n`non`noff`ntoggle",
                "OBS Mute Mode",
                "w500 h180"
            )
            if (obsModeDialog.Result != "OK")
                return { Success: false }

            actionValue := obsInputDialog.Value "|" StrLower(Trim(obsModeDialog.Value))
        }

        case "13":
        {
            actionType := "obs_hotkey"
            valueDialog := InputBox(
                "Enter OBS hotkey name.`n`nExample:`nOBSBasic.StartStreaming",
                "OBS Hotkey",
                "w500 h180"
            )
            if (valueDialog.Result != "OK")
                return { Success: false }
            actionValue := valueDialog.Value
        }

        default:
            return { Success: false }
    }

    return { Success: true, BindingValue: actionType "|" actionValue }
}
ShowBindingTypePicker(bindingKey, keyName)
{
    selected := ""

    picker := Gui("+AlwaysOnTop", "Binding Wizard")
    picker.SetFont("s10", "Segoe UI")

    picker.AddText("xm ym w520", "Creating binding for:")
    picker.AddEdit("xm w520 ReadOnly", bindingKey)
    picker.AddText("xm w520", "Key: " keyName)
    picker.AddText("xm y+10 w520", "Choose action type:")

    items := [
        "1 = Run program / app / file",
        "2 = Send keys",
        "3 = Message box",
        "4 = Media control",
        "5 = Layer switch",
        "6 = Open folder",
        "7 = Open website",
        "8 = Edit bindings file",
        "9 = OBS scene",
        "10 = OBS recording",
        "11 = OBS streaming",
        "12 = OBS mute / unmute input",
        "13 = OBS hotkey"
    ]

    list := picker.AddListBox("xm w520 r13 vActionList", items)
    list.Choose(1)

    okBtn := picker.AddButton("xm y+12 w120 Default", "OK")
    cancelBtn := picker.AddButton("x+10 w120", "Cancel")

    okBtn.OnEvent("Click", OnOK)
    cancelBtn.OnEvent("Click", OnCancel)
    picker.OnEvent("Close", OnCancel)
    list.OnEvent("DoubleClick", OnOK)

    picker.Show("AutoSize Center")
    WinWaitClose("ahk_id " picker.Hwnd)

    return selected

    OnOK(*)
    {
        rowText := list.Text
        if (rowText = "")
            return

        selected := Trim(StrSplit(rowText, "=")[1])
        picker.Destroy()
    }

    OnCancel(*)
    {
        selected := ""
        picker.Destroy()
    }
}

ShowUnmappedKeyInfo(layer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift)
{
    global DebugTooltips, UnmappedLogFile, LastUnmappedKeyId, LastUnmappedTick

    keyName := GetKeyName(Format("vk{:02X}", vk))
    if (keyName = "")
        keyName := "Unknown"

    bindingKey := layer "|" keyboardNumber "_" vk
    starterLine := bindingKey "=msg|"

    tickNow := A_TickCount

    if (LastUnmappedKeyId = bindingKey && (tickNow - LastUnmappedTick) < 500)
        return

    LastUnmappedKeyId := bindingKey
    LastUnmappedTick := tickNow

    A_Clipboard := ""
    Sleep 30
    A_Clipboard := starterLine
    ClipWait 0.5

    tooltipText :=
    (
        "Unmapped key"
        . "`nLayer: " layer
        . "`nKeyboard: " keyboardNumber
        . "`nVK: " vk
        . "`nKey: " keyName
        . "`nCopied:"
        . "`n" starterLine
    )

    if DebugTooltips
    {
        ToolTip tooltipText
        SetTimer ClearToolTip, -2500
    }

    logLine :=
    (
        FormatTime(, "yyyy-MM-dd HH:mm:ss")
        . " | Layer=" layer
        . " | Keyboard=" keyboardNumber
        . " | VK=" vk
        . " | Key=" keyName
        . " | SuggestedBinding=" starterLine
        . " | WasDown=" (wasDown ? "1" : "0")
        . " | Extended=" (isExtended ? "1" : "0")
        . " | LCtrl=" (leftCtrl ? "1" : "0")
        . " | RCtrl=" (rightCtrl ? "1" : "0")
        . " | LAlt=" (leftAlt ? "1" : "0")
        . " | RAlt=" (rightAlt ? "1" : "0")
        . " | Shift=" (shift ? "1" : "0")
        . "`n"
    )

    try FileAppend(logLine, UnmappedLogFile, "UTF-8")
}

OBS_Call(requestType, requestData := unset)
{
    global ConfigFile, OBSHelperPath

    host := IniRead(ConfigFile, "OBS", "Host", "127.0.0.1")
    port := IniRead(ConfigFile, "OBS", "Port", "4455")
    password := IniRead(ConfigFile, "OBS", "Password", "")

    if !FileExist(OBSHelperPath)
    {
        MsgBox "OBS helper not found:`n" OBSHelperPath
        return
    }

    psExe := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    tempJsonFile := ""
    cmd := ""

    if IsSet(requestData)
    {
        jsonData := MapToJson(requestData)
        tempJsonFile := A_Temp "\obs_request_" A_TickCount ".json"

        if FileExist(tempJsonFile)
            FileDelete tempJsonFile

        FileAppend jsonData, tempJsonFile, "UTF-8"

        cmd := '"' psExe '" -NoProfile -ExecutionPolicy Bypass -File "' OBSHelperPath '"'
            . ' -ObsHost "' host '"'
            . ' -Port "' port '"'
            . ' -Password "' EscapeCmdArg(password) '"'
            . ' -RequestType "' EscapeCmdArg(requestType) '"'
            . ' -RequestDataFile "' tempJsonFile '"'
    }
    else
    {
        cmd := '"' psExe '" -NoProfile -ExecutionPolicy Bypass -File "' OBSHelperPath '"'
            . ' -ObsHost "' host '"'
            . ' -Port "' port '"'
            . ' -Password "' EscapeCmdArg(password) '"'
            . ' -RequestType "' EscapeCmdArg(requestType) '"'
    }

    try
        RunWait cmd, , "Hide"
    catch Error as err
        MsgBox "Failed to call OBS helper.`n`n" err.Message
    finally
    {
        if (tempJsonFile != "" && FileExist(tempJsonFile))
            FileDelete tempJsonFile
    }
}

HandleOBSMute(actionValue)
{
    parts := StrSplit(actionValue, "|")
    if (parts.Length < 2)
    {
        MsgBox "obs_mute requires format:`nInputName|toggle"
        return
    }

    inputName := parts[1]
    mode := StrLower(parts[2])

    switch mode
    {
        case "on":
            OBS_Call("SetInputMute", Map("inputName", inputName, "inputMuted", true))
        case "off":
            OBS_Call("SetInputMute", Map("inputName", inputName, "inputMuted", false))
        case "toggle":
            OBS_Call("ToggleInputMute", Map("inputName", inputName))
        default:
            MsgBox "Unknown obs_mute mode:`n" mode
    }
}

MapToJson(mapObj)
{
    json := "{"
    first := true

    for k, v in mapObj
    {
        if !first
            json .= ","
        first := false

        json .= '"' JsonEscape(k) '":'

        if (v is String)
            json .= '"' JsonEscape(v) '"'
        else if (v == true)
            json .= "true"
        else if (v == false)
            json .= "false"
        else
            json .= v
    }

    json .= "}"
    return json
}

JsonEscape(str)
{
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}

EscapeCmdArg(str)
{
    return StrReplace(str, '"', '\"')
}

AddBindingToIni(bindingKey, bindingValue)
{
    global ConfigFile

    if !FileExist(ConfigFile)
        EnsureDefaultConfig()

    content := FileRead(ConfigFile, "UTF-8")
    pattern := "(?m)^" RegExEscape(bindingKey) "=.*$"
    replacement := bindingKey "=" bindingValue

    if RegExMatch(content, pattern)
    {
        content := RegExReplace(content, pattern, replacement)
    }
    else
    {
        if !InStr(content, "[Bindings]")
        {
            if SubStr(content, -1) != "`n"
                content .= "`r`n"
            content .= "`r`n[Bindings]`r`n"
        }

        if SubStr(content, -1) != "`n"
            content .= "`r`n"

        content .= replacement "`r`n"
    }

    FileDelete ConfigFile
    FileAppend content, ConfigFile, "UTF-8"
}

RegExEscape(text)
{
    static chars := "\.*?+[]{}()^$|"
    escaped := ""
    Loop Parse, text
    {
        ch := A_LoopField
        escaped .= InStr(chars, ch) ? "\" ch : ch
    }
    return escaped
}

LoadBindings()
{
    global ConfigFile, MacroMap, CurrentLayer, DebugTooltips, ConfigLastModified

    MacroMap := Map()

    try CurrentLayer := IniRead(ConfigFile, "Settings", "DefaultLayer", "default")
    catch
        CurrentLayer := "default"

    try DebugTooltips := IniRead(ConfigFile, "Settings", "DebugTooltips", 1) = 1
    catch
        DebugTooltips := true

    bindingsSection := IniReadSection(ConfigFile, "Bindings")

    for key, value in bindingsSection
    {
        cleanKey := Trim(key)
        cleanValue := Trim(value)

        if (cleanKey != "" && cleanValue != "")
            MacroMap[cleanKey] := cleanValue
    }

    if FileExist(ConfigFile)
        ConfigLastModified := FileGetTime(ConfigFile, "M")
}

WatchConfigFile()
{
    global ConfigFile, ConfigLastModified, DebugTooltips

    if !FileExist(ConfigFile)
        return

    currentModified := FileGetTime(ConfigFile, "M")

    if (ConfigLastModified = "")
    {
        ConfigLastModified := currentModified
        return
    }

    if (currentModified != ConfigLastModified)
    {
        Sleep 150
        LoadBindings()

        if DebugTooltips
        {
            ToolTip "Bindings reloaded"
            SetTimer ClearToolTip, -800
        }
    }
}

IniReadSection(filePath, sectionName)
{
    result := Map()

    if !FileExist(filePath)
        return result

    inSection := false

    loop read, filePath
    {
        line := Trim(A_LoopReadLine)

        if (line = "" || SubStr(line, 1, 1) = ";")
            continue

        if RegExMatch(line, "^\[(.*)\]$", &match)
        {
            inSection := (match[1] = sectionName)
            continue
        }

        if !inSection
            continue

        eqPos := InStr(line, "=")
        if !eqPos
            continue

        key := Trim(SubStr(line, 1, eqPos - 1))
        value := Trim(SubStr(line, eqPos + 1))

        result[key] := value
    }

    return result
}

EnsureDefaultConfig()
{
    global ConfigFile

    if FileExist(ConfigFile)
        return

    defaultConfig :=
    (
"[Settings]
DefaultLayer=default
DebugTooltips=1

[OBS]
Host=127.0.0.1
Port=4455
Password=

[Bindings]
; Replace the keyboard number with the one your MultiKB setup uses.
; Use an unmapped key or capture mode to generate correct binding lines.

; Example helper bindings:
; default|1_120=editbindings|
; default|1_121=capture|
"
    )

    FileAppend defaultConfig, ConfigFile, "UTF-8"
}

StartMultiKB()
{
    global MultiKBPath

    if FileExist(MultiKBPath) && !ProcessExist("MultiKB_For_AutoHotkey.exe")
    {
        Run MultiKBPath
        Sleep 1500
    }
}

ClearToolTip()
{
    ToolTip
}