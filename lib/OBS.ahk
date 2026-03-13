OBS_Call(requestType, requestData := unset) {
    global ConfigFile, OBSHelperPath

    host := IniRead(ConfigFile, "OBS", "Host", "127.0.0.1")
    port := IniRead(ConfigFile, "OBS", "Port", "4455")
    password := IniRead(ConfigFile, "OBS", "Password", "")

    if !FileExist(OBSHelperPath) {
        MsgBox "OBS helper not found:`n" OBSHelperPath
        return
    }

    psExe := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    tempJsonFile := ""
    cmd := ""

    if IsSet(requestData) {
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
    } else {
        cmd := '"' psExe '" -NoProfile -ExecutionPolicy Bypass -File "' OBSHelperPath '"'
            . ' -ObsHost "' host '"'
            . ' -Port "' port '"'
            . ' -Password "' EscapeCmdArg(password) '"'
            . ' -RequestType "' EscapeCmdArg(requestType) '"'
    }

    try RunWait cmd, , "Hide"
    catch Error as err
        MsgBox "Failed to call OBS helper.`n`n" err.Message
    finally {
        if (tempJsonFile != "" && FileExist(tempJsonFile))
            FileDelete tempJsonFile
    }
}

HandleOBSMute(params) {
    if (params.Length < 2) {
        MsgBox "obs_mute requires format:`nobs_mute|InputName|toggle"
        return
    }

    inputName := params[1]
    mode := StrLower(params[2])

    switch mode {
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
