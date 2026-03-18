StartCaptureMode() {
    global CaptureMode, CaptureLayer, CurrentLayer

    CaptureMode := true
    CaptureLayer := CurrentLayer
    ShowDebugTip("Capture mode enabled`nPress the key you want to bind...", 2000)
}

HandleCaptureKey(layer, keyboardNumber, vk, wasDown, isExtended, leftCtrl, rightCtrl, leftAlt, rightAlt, shift) {
    global CaptureMode, CaptureLayer, UnmappedLogFile

    keyName := GetKeyName(Format("vk{:02X}", vk))
    if (keyName = "")
        keyName := "Unknown"

    bindingKey := CaptureLayer "|" keyboardNumber "_" vk
    result := RunBindingWizard(bindingKey, keyName)

    CaptureMode := false

    if !result.Success {
        ShowDebugTip("Binding wizard cancelled", 1500)
        return
    }

    AddBindingToIni(bindingKey, result.BindingValue)
    LoadBindings()

    fullLine := bindingKey "=" result.BindingValue

    A_Clipboard := ""
    Sleep 30
    A_Clipboard := fullLine
    ClipWait 0.5

    ShowDebugTip("Binding added`nKey: " keyName "`n" fullLine "`nCopied to clipboard", 3500)

    logLine := FormatTime(, "yyyy-MM-dd HH:mm:ss")
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

    try FileAppend(logLine, UnmappedLogFile, "UTF-8")
}

RunBindingWizard(bindingKey, keyName) {
    segments := []

    loop {
        actionChoice := ShowBindingTypePicker(bindingKey, keyName, segments.Length + 1)
        if (actionChoice = "")
            return { Success: false }

        actionType := ""
        params := []

        switch actionChoice {
            case "1": 
                actionType := "run"
                d := InputBox(
                    "Enter one or more programs, files, or commands to run.`n`n"
                  . "Separate multiple targets with |`n"
                  . "Escape a literal pipe as \\|`n`n"
                  . "Examples:`n"
                  . "notepad.exe|calc.exe`n"
                  . '"C:\Program Files\obs-studio\bin\64bit\obs64.exe" --profile "Streaming"',
                    "Run Action",
                    "w620 h260"
                )
                if (d.Result != "OK")
                    return { Success: false }
                params := SplitEscaped(d.Value, "|")
            

            case "2": 
                actionType := "send"
                d := InputBox(
                    "Enter the keys to send.`n`nExamples:`n^c`n!{Tab}`nHello world`n`nTo include a literal pipe, escape it as \\|",
                    "Send Action",
                    "w560 h220"
                )
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(d.Value)
            

            case "3": 
                actionType := "msg"
                d := InputBox("Enter the message text to show. Escape a literal pipe as \\| if needed.", "Message Action", "w560 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(d.Value)
            

            case "4": 
                actionType := "media"
                d := InputBox("Enter media action:`n`nplaypause`nnext`nprev`nstop`nmute`nvolup`nvoldown", "Media Action", "w500 h220")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(StrLower(Trim(d.Value)))
            
            case "5": 
                actionType := "layer"
                d := InputBox("Enter layer name to switch to.`n`nExample:`ndefault`nmedia`nunity", "Layer Action", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(Trim(d.Value))

            case "6":
                actionType := "folder"
                d := InputBox(
                    "Enter one or more folder paths.`n`n"
                . "Separate multiple targets with |`n"
                . "Escape a literal pipe as \|`n`n"
                . "Example:`n"
                . "C:\Projects|D:\Art|C:\Users\Ben\Documents",
                    "Folder Action",
                    "w620 h240"
                )
                if (d.Result != "OK")
                    return { Success: false }
                params := SplitEscaped(d.Value, "|")

            case "7":
                actionType := "website"
                d := InputBox(
                    "Enter one or more website URLs.`n`n"
                . "Separate multiple targets with |`n"
                . "Escape a literal pipe as \|`n`n"
                . "Example:`n"
                . "https://google.com|https://youtube.com",
                    "Website Action",
                    "w620 h240"
                )
                if (d.Result != "OK")
                    return { Success: false }
                params := SplitEscaped(d.Value, "|")

            case "8": 
                actionType := "editbindings"

            case "9": 
                actionType := "obs_scene"
                d := InputBox("Enter the exact OBS scene name.", "OBS Scene", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(d.Value)

            case "10": 
                actionType := "obs_record"
                d := InputBox("Enter OBS recording action:`n`nstart`nstop`ntoggle", "OBS Recording", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(StrLower(Trim(d.Value)))

            case "11": 
                actionType := "obs_stream"
                d := InputBox("Enter OBS streaming action:`n`nstart`nstop`ntoggle", "OBS Streaming", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(StrLower(Trim(d.Value)))

            case "12": 
                actionType := "obs_mute"
                d1 := InputBox("Enter the exact OBS input name.", "OBS Mute Input", "w500 h180")
                if (d1.Result != "OK")
                    return { Success: false }

                d2 := InputBox("Enter mute action:`n`non`noff`ntoggle", "OBS Mute Mode", "w500 h180")
                if (d2.Result != "OK")
                    return { Success: false }

                params.Push(d1.Value)
                params.Push(StrLower(Trim(d2.Value)))

            case "13": 
                actionType := "obs_hotkey"
                d := InputBox("Enter OBS hotkey name.", "OBS Hotkey", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(d.Value)

            case "14":
                actionType := "delay"
                d := InputBox("Enter delay duration in milliseconds (e.g. 250).", "Delay Action", "w500 h160")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(Trim(d.Value))

            case "15":
                actionType := "typemsg"
                d1 := InputBox("Enter the message to type.", "Type Message", "w500 h180")
                if (d1.Result != "OK")
                    return { Success: false }
                d2 := InputBox("Submit with Enter? (true/false)", "Submit Option", "w500 h160")
                if (d2.Result != "OK")
                    return { Success: false }
                params.Push(d1.Value)
                params.Push(StrLower(Trim(d2.Value)))

            case "16":
                actionType := "focus"
                d := InputBox("Enter window title to focus (partial match).", "Focus Window", "w500 h180")
                if (d.Result != "OK")
                    return { Success: false }
                params.Push(d.Value)

            case "17":
                actionType := "plugin"
                d1 := InputBox("Enter plugin filename (e.g., myplugin.ahk).", "Plugin File", "w500 h160")
                if (d1.Result != "OK")
                    return { Success: false }
                params.Push(d1.Value)

                d2 := InputBox("Enter plugin action (e.g., msg, send).", "Plugin Action", "w500 h160")
                if (d2.Result != "OK")
                    return { Success: false }
                params.Push(d2.Value)

                ; Optional: additional parameters
                moreParams := MsgBox("Add additional parameters to the plugin call?", "Plugin Parameters", "YesNo")
                if (moreParams = "Yes") {
                    loop {
                        dparam := InputBox("Enter additional parameter (leave empty to skip):", "Plugin Parameter", "w500 h160")
                        if (dparam.Result != "OK" || dparam.Value = "")
                            break
                        params.Push(dparam.Value)
                    }
                }

            case "18":
                actionType := "customaction"
                d := InputBox(
                    "Enter custom action name (will call Action_<name> function).`n`n"
                  . "Example: sampleversion`n"
                  . "Must be defined in a compile-time plugin.",
                    "Custom Action Name",
                    "w560 h220"
                )
                if (d.Result != "OK")
                    return { Success: false }
                actionName := StrLower(Trim(d.Value))
                if (actionName = "")
                    return { Success: false }
                actionType := actionName

                ; Optional: additional parameters
                moreParams := MsgBox("Add parameters to this custom action?", "Action Parameters", "YesNo")
                if (moreParams = "Yes") {
                    loop {
                        dparam := InputBox("Enter parameter (leave empty to finish):", "Action Parameter", "w500 h160")
                        if (dparam.Result != "OK" || dparam.Value = "")
                            break
                        params.Push(dparam.Value)
                    }
                }

            default:
                return { Success: false }
        }

        segment := actionType
        for _, param in params
            segment .= "|" EscapeBindingValue(param)

        segments.Push(segment)

        ; Ask if add another action
        if (segments.Length >= 10) {  ; Prevent too many
            MsgBox "Maximum 10 actions per binding reached."
            break
        }

        addMore := MsgBox("Action added. Add another action to this binding?", "Add More Actions", "YesNo")
        if (addMore = "No")
            break
    }

    bindingValue := ""
    for i, seg in segments {
        if (i > 1)
            bindingValue .= ";;"
        bindingValue .= seg
    }

    return { Success: true, BindingValue: bindingValue }
}

ShowBindingTypePicker(bindingKey, keyName, step := 1) {
    selected := ""

    title := step = 1 ? "Binding Wizard" : "Binding Wizard - Step " step
    picker := Gui("+AlwaysOnTop", title)
    picker.SetFont("s10", "Segoe UI")

    picker.AddText("xm ym w520", "Creating binding for:")
    picker.AddEdit("xm w520 ReadOnly", bindingKey)
    picker.AddText("xm w520", "Key: " keyName)
    picker.AddText("xm y+10 w520", "Choose action type:")

    items := [
        "1 = Run program / app / file"
      , "2 = Send keys"
      , "3 = Message box"
      , "4 = Media control"
      , "5 = Layer switch"
      , "6 = Open folder"
      , "7 = Open website"
      , "8 = Edit bindings file"
      , "9 = OBS scene"
      , "10 = OBS recording"
      , "11 = OBS streaming"
      , "12 = OBS mute / unmute input"
      , "13 = OBS hotkey"
      , "14 = Delay (milliseconds)"
      , "15 = Type message (with optional Enter)"
      , "16 = Focus window"
      , "17 = Plugin (runtime external script)"
      , "18 = Custom action (compile-time)"
    ]

    list := picker.AddListBox("xm w520 r18", items)
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

    OnOK(*) {
        rowText := list.Text
        if (rowText = "")
            return
        selected := Trim(StrSplit(rowText, "=")[1])
        picker.Destroy()
    }

    OnCancel(*) {
        selected := ""
        picker.Destroy()
    }
}
