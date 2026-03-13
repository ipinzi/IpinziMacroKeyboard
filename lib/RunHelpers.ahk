RunBindingTargets(targets) {
    for _, target in targets {
        target := Trim(target)
        if (target = "")
            continue

        RunOrFocusTarget(target)
    }
}

RunOrFocusTarget(target) {
    exePath := ExtractExecutablePath(target)
    exeName := ""

    if (exePath != "")
        SplitPath exePath, &exeName

    if (exeName != "") {
        hwnd := WinExist("ahk_exe " exeName)
        if hwnd {
            try WinRestore("ahk_id " hwnd)
            WinActivate("ahk_id " hwnd)
            return
        }
    }

    runDir := (exePath != "") ? GetParentDir(exePath) : ""

    if (runDir != "")
        Run target, runDir
    else
        Run target
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
