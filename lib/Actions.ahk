ParseBinding(binding) {
    parts := SplitEscaped(binding, "|")
    actionType := ""
    params := []

    if (parts.Length >= 1)
        actionType := StrLower(Trim(parts[1]))

    if (parts.Length >= 2) {
        Loop parts.Length - 1
            params.Push(parts[A_Index + 1])
    }

    return { ActionType: actionType, Params: params }
}

ExecuteBinding(binding, keyboardNumber, vk) {
    global CurrentLayer, ConfigFile

    ; Allow chaining multiple actions in one binding (separated by ";;").
    segments := SplitEscaped(binding, ";;")
    if (segments.Length > 1) {
        for _, seg in segments {
            seg := Trim(seg)
            if (seg = "")
                continue
            ExecuteBinding(seg, keyboardNumber, vk)
        }
        return
    }

    parsed := ParseBinding(binding)
    actionType := parsed.ActionType
    params := parsed.Params

    switch actionType {
        case "run":
            try RunBindingTargets(params)
            catch Error as err
                MsgBox "Failed to run target(s):`n" JoinParams(params) "`n`n" err.Message

        case "send":
            Send (params.Length ? params[1] : "")

        case "msg":
            MsgBox (params.Length ? params[1] : "")

        case "layer":
            CurrentLayer := (params.Length ? params[1] : "default")
            ShowDebugTip("Layer: " CurrentLayer, 700)

        case "media":
            HandleMediaAction(params.Length ? params[1] : "")

        case "folder":
            try RunMultipleTargets(params, "folder")
            catch Error as err
                MsgBox "Failed to open folder target.`n`n" err.Message

        case "website":
            try RunMultipleTargets(params, "website")
            catch Error as err
                MsgBox "Failed to open website target.`n`n" err.Message

        case "editbindings":
            try Run 'notepad.exe "' ConfigFile '"'
            catch Error as err
                MsgBox "Failed to open bindings file.`n`n" err.Message

        case "capture":
            StartCaptureMode()

        case "obs_scene":
            OBS_Call("SetCurrentProgramScene", Map("sceneName", params.Length ? params[1] : ""))

        case "obs_record":
            switch StrLower(params.Length ? params[1] : "") {
                case "start":
                    OBS_Call("StartRecord")
                case "stop":
                    OBS_Call("StopRecord")
                case "toggle":
                    OBS_Call("ToggleRecord")
                default:
                    MsgBox "Unknown obs_record action:`n" (params.Length ? params[1] : "")
            }

        case "obs_stream":
            switch StrLower(params.Length ? params[1] : "") {
                case "start":
                    OBS_Call("StartStream")
                case "stop":
                    OBS_Call("StopStream")
                case "toggle":
                    OBS_Call("ToggleStream")
                default:
                    MsgBox "Unknown obs_stream action:`n" (params.Length ? params[1] : "")
            }

        case "obs_hotkey":
            OBS_Call("TriggerHotkeyByName", Map("hotkeyName", params.Length ? params[1] : ""))

        case "obs_mute":
            HandleOBSMute(params)

        case "delay":
            ms := (params.Length ? params[1] : "")
            if (ms = "" || !RegExMatch(ms, "^\d+$")) {
                MsgBox "Invalid delay value (milliseconds):`n" ms
                return
            }
            Sleep ms
        case "typemsg":
            text := params.Length ? params[1] : ""
            submit := params.Length > 1 ? StrLower(params[2]) : "false"
            if (submit == "true" || submit == "1" || submit == "yes")
                Send text "{Enter}"
            else
                Send text
        case "focus":
            windowTitle := params.Length ? params[1] : ""
            if (windowTitle != "") {
                WinActivate windowTitle
                WinWaitActive windowTitle, , 2
            }
        default:
            MsgBox "Unknown action type:`n" actionType "`n`nBinding:`n" binding
    }
}

HandleMediaAction(action) {
    switch StrLower(action) {
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
