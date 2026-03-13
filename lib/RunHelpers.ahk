DetectHiddenWindows false
SetTitleMatchMode 2

RunBindingTargets(targets) {
    for _, target in targets {
        target := Trim(target)
        if (target = "")
            continue

        RunOrFocusTarget(target)
    }
}
RunMultipleTargets(params, targetKind := "target") {
    for _, target in params {
        target := Trim(target)
        if (target = "")
            continue

        try Run target
        catch Error as err
            MsgBox "Failed to open " targetKind ":`n" target "`n`n" err.Message
    }
}
RunOrFocusTarget(target) {
    exePath := ExtractExecutablePath(target)
    exeName := ""

    if exePath
        SplitPath exePath, &exeName

    windows := GetAppWindows(exeName)

    ; --- no windows → launch ---
    if windows.Length = 0 {
        runDir := exePath ? GetParentDir(exePath) : ""
        if runDir
            Run target, runDir
        else
            Run target
        return
    }

    ; --- one window → focus ---
    if windows.Length = 1 {
        FocusWindow(windows[1])
        return
    }

    ; --- multiple windows → cycle ---
    active := WinActive("A")

    for i, hwnd in windows {
        if hwnd = active {
            next := (i = windows.Length) ? windows[1] : windows[i+1]
            FocusWindow(next)
            return
        }
    }

    ; if none active, focus first
    FocusWindow(windows[1])
}
GetAppWindows(exeName) {
    windows := []

    for hwnd in WinGetList("ahk_exe " exeName) {

        ; ignore invisible or tool windows
        if !WinExist("ahk_id " hwnd)
            continue

        if !WinGetTitle("ahk_id " hwnd)
            continue

        windows.Push(hwnd)
    }

    return windows
}
FocusWindow(hwnd) {
    if WinActive("ahk_id " hwnd)
        return

    state := WinGetMinMax("ahk_id " hwnd)
    if (state = -1)
        WinRestore("ahk_id " hwnd)

    WinActivate("ahk_id " hwnd)
}

ExtractExecutablePath(commandLine) {
    commandLine := Trim(commandLine)
    if (commandLine = "")
        return ""

    if RegExMatch(commandLine, '^\s*"([^"]+)"', &m)
        return m[1]

    if RegExMatch(commandLine, '^\s*([^\s]+)', &m)
        return m[1]

    return ""
}

GetParentDir(filePath) {
    if (filePath = "")
        return ""

    SplitPath filePath, , &dir
    return dir
}
