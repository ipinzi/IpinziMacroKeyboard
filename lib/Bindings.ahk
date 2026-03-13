LoadBindings() {
    global ConfigFile, MacroMap, CurrentLayer, DebugTooltips, ConfigLastModified

    MacroMap := Map()

    try CurrentLayer := IniRead(ConfigFile, "Settings", "DefaultLayer", "default")
    catch
        CurrentLayer := "default"

    try DebugTooltips := IniRead(ConfigFile, "Settings", "DebugTooltips", 1) = 1
    catch
        DebugTooltips := true

    bindingsSection := IniReadSection(ConfigFile, "Bindings")
    for key, value in bindingsSection {
        cleanKey := Trim(key)
        cleanValue := Trim(value)

        if (cleanKey != "" && cleanValue != "")
            MacroMap[cleanKey] := cleanValue
    }

    if FileExist(ConfigFile)
        ConfigLastModified := FileGetTime(ConfigFile, "M")
}

WatchConfigFile() {
    global ConfigFile, ConfigLastModified

    if !FileExist(ConfigFile)
        return

    currentModified := FileGetTime(ConfigFile, "M")

    if (ConfigLastModified = "") {
        ConfigLastModified := currentModified
        return
    }

    if (currentModified != ConfigLastModified) {
        Sleep 150
        LoadBindings()
        ShowDebugTip("Bindings reloaded", 800)
    }
}

MsgFunc(wParam, lParam, msg, hwnd) {
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

    if CaptureMode {
        HandleCaptureKey(CurrentLayer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift)
        return
    }

    keyId := CurrentLayer "|" keyboardNumber "_" vk

    if MacroMap.Has(keyId) {
        ExecuteBinding(MacroMap[keyId], keyboardNumber, vk)
        return
    }

    ShowUnmappedKeyInfo(CurrentLayer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift)
}

ShowUnmappedKeyInfo(layer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift) {
    global UnmappedLogFile, LastUnmappedKeyId, LastUnmappedTick

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

    ShowDebugTip(
        "Unmapped key`nLayer: " layer
        . "`nKeyboard: " keyboardNumber
        . "`nVK: " vk
        . "`nKey: " keyName
        . "`nCopied:`n" starterLine,
        2500
    )

    logLine := FormatTime(, "yyyy-MM-dd HH:mm:ss")
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

    try FileAppend(logLine, UnmappedLogFile, "UTF-8")
}
