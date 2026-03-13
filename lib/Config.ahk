EnsureDefaultConfig() {
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
    ; Format: layer|keyboard_vk=action|param1|param2|param3
    ; Escape a literal pipe as \|
    ; Escape a literal backslash before a pipe as \\
    ;
    ; Example helpers:
    ; default|1_120=editbindings
    ; default|1_121=capture
    ;
    ; Run one or more targets:
    ; default|1_122=run|notepad.exe|calc.exe
    ;
    ; OBS mute:
    ; default|1_124=obs_mute|Mic/Aux|toggle
    "
    )

    FileAppend defaultConfig, ConfigFile, "UTF-8"
}

IniReadSection(filePath, sectionName) {
    result := Map()

    if !FileExist(filePath)
        return result

    inSection := false

    Loop Read, filePath {
        rawLine := A_LoopReadLine
        line := Trim(rawLine)

        if (line = "" || SubStr(line, 1, 1) = ";")
            continue

        if RegExMatch(line, "^\[(.*)\]$", &match) {
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

AddBindingToIni(bindingKey, bindingValue) {
    global ConfigFile

    if !FileExist(ConfigFile)
        EnsureDefaultConfig()

    content := FileRead(ConfigFile, "UTF-8")
    pattern := "(?m)^" RegExEscape(bindingKey) "=.*$"
    replacement := bindingKey "=" bindingValue

    if RegExMatch(content, pattern)
        content := RegExReplace(content, pattern, replacement)
    else {
        if !InStr(content, "[Bindings]") {
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
