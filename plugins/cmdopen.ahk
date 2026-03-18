; Compile-time plugin: open Terminal at a resolved location.
; Action name: cmdopen
;
; Usage examples in bindings.ini:
; default|2_140=cmdopen
; default|2_141=cmdopen|C:\Projects\MyGame
; default|2_142=cmdopen|file:///C:/Projects/MyGame
;
; Behavior:
; 1) If a path/URI parameter is provided, use that location.
; 2) Otherwise, use the currently focused Explorer folder.
; 3) If neither resolves, open terminal normally.
; 4) If a terminal window is open and Ctrl is NOT held, focus it instead of opening new.
; 5) If Ctrl IS held, always open a new terminal window.
;
; Priority: Windows Terminal > PowerShell 7 > PowerShell 5 > Command Prompt

Action_cmdopen(params, keyboardNumber, vk) {
    ctrlHeld := GetKeyState("LCtrl") || GetKeyState("RCtrl")
    
    ; If Ctrl is not held, try to focus existing terminal first
    if (!ctrlHeld) {
        if (TryFocusExistingTerminal())
            return
    }

    ; Open a new terminal (or if no existing terminal found)
    targetDir := ResolveCmdOpenTarget(params)

    if (targetDir != "" && DirExist(targetDir)) {
        ; Try Windows Terminal first with -d (startingDirectory) flag
        try {
            Run 'wt.exe -d "' targetDir '"'
            return
        } catch {
            ; Fall through to next option
        }

        ; Fall back to PowerShell 7
        try {
            Run "pwsh.exe", targetDir
            return
        } catch {
            ; Fall through to next option
        }

        ; Fall back to PowerShell 5
        try {
            Run "powershell.exe", targetDir
            return
        } catch {
            ; Fall through to next option
        }

        ; Fall back to Command Prompt
        try {
            Run "cmd.exe", targetDir
            return
        } catch {
            ; Fall through to default
        }
    }

    ; Fallback: try each terminal in order.
    try {
        Run "wt.exe"
        return
    } catch {
    }

    try {
        Run "pwsh.exe"
        return
    } catch {
    }

    try {
        Run "powershell.exe"
        return
    } catch {
    }

    Run "cmd.exe"
}

TryFocusExistingTerminal() {
    terminalPatterns := [
        "ahk_exe WindowsTerminal.exe",
        "ahk_exe wt.exe",
        "ahk_exe pwsh.exe",
        "ahk_exe powershell.exe",
        "ahk_exe conhost.exe",
        "ahk_exe cmd.exe"
    ]

    ; Collect all open terminal windows
    terminalWindows := []
    for pattern in terminalPatterns {
        for hwnd in WinGetList(pattern) {
            if (hwnd && WinExist("ahk_id " hwnd)) {
                terminalWindows.Push(hwnd)
            }
        }
    }

    if (terminalWindows.Length = 0)
        return false

    ; If only one terminal, focus it
    if (terminalWindows.Length = 1) {
        WinActivate "ahk_id " terminalWindows[1]
        return true
    }

    ; Multiple terminals: find the active one and cycle to the next
    activeHwnd := WinActive("A")
    nextIndex := 1

    for i, hwnd in terminalWindows {
        if (hwnd = activeHwnd) {
            nextIndex := (i = terminalWindows.Length) ? 1 : i + 1
            break
        }
    }

    WinActivate "ahk_id " terminalWindows[nextIndex]
    return true
}

ResolveCmdOpenTarget(params) {
    if (params.Length >= 1) {
        candidate := NormalizeLocationInput(params[1])
        if (candidate != "")
            return candidate
    }

    return GetFocusedExplorerPath()
}

NormalizeLocationInput(rawValue) {
    value := Trim(rawValue)
    if (value = "")
        return ""

    if (SubStr(value, 1, 1) = '"' && SubStr(value, -1) = '"' && StrLen(value) >= 2)
        value := SubStr(value, 2, -1)

    lower := StrLower(value)
    if (SubStr(lower, 1, 8) = "file:///")
        value := FileUriToPath(value)
    else if (SubStr(lower, 1, 7) = "file://")
        value := FileUriToPath(value)

    value := PercentDecode(value)
    value := StrReplace(value, "/", "\")

    if (DirExist(value))
        return value

    ; If this points to a file, use its parent directory.
    if (FileExist(value)) {
        SplitPath value, , &parent
        if (parent != "" && DirExist(parent))
            return parent
    }

    return ""
}

GetFocusedExplorerPath() {
    hwnd := WinActive("A")
    if !hwnd
        return ""

    try {
        shell := ComObject("Shell.Application")
        for window in shell.Windows {
            try {
                if (window.HWND != hwnd)
                    continue

                folderPath := window.Document.Folder.Self.Path
                if (folderPath != "" && DirExist(folderPath))
                    return folderPath
            } catch {
                continue
            }
        }
    } catch {
        return ""
    }

    return ""
}

FileUriToPath(uri) {
    value := uri

    ; Strip file:// prefix.
    if (SubStr(StrLower(value), 1, 8) = "file:///")
        value := SubStr(value, 9)
    else if (SubStr(StrLower(value), 1, 7) = "file://")
        value := SubStr(value, 8)

    ; Handle localhost form.
    if (SubStr(StrLower(value), 1, 10) = "localhost/")
        value := SubStr(value, 11)

    ; Convert URI separators to Windows separators.
    value := StrReplace(value, "/", "\")

    return value
}

PercentDecode(text) {
    out := ""
    i := 1

    while (i <= StrLen(text)) {
        ch := SubStr(text, i, 1)
        if (ch = "%" && i + 2 <= StrLen(text)) {
            hex := SubStr(text, i + 1, 2)
            if RegExMatch(hex, "i)^[0-9a-f]{2}$") {
                out .= Chr("0x" hex)
                i += 3
                continue
            }
        }

        out .= ch
        i += 1
    }

    return out
}
