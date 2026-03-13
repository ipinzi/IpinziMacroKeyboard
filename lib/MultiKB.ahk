StartMultiKB() {
    global MultiKBPath

    if FileExist(MultiKBPath) && !ProcessExist("MultiKB_For_AutoHotkey.exe") {
        Run MultiKBPath
        Sleep 1500
    }
}
