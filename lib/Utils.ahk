ClearToolTip() {
    ToolTip
}

ShowDebugTip(text, ms := 1200) {
    global DebugTooltips
    if !DebugTooltips
        return

    ToolTip text
    SetTimer ClearToolTip, -ms
}

RegExEscape(text) {
    static chars := "\.*?+[]{}()^$|"
    escaped := ""

    Loop Parse, text {
        ch := A_LoopField
        escaped .= InStr(chars, ch) ? "\" ch : ch
    }

    return escaped
}

JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}

MapToJson(mapObj) {
    json := "{"
    first := true

    for k, v in mapObj {
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

EscapeCmdArg(str) {
    return StrReplace(str, '"', '\"')
}

SplitEscaped(text, delimiter := "|") {
    parts := []
    current := ""
    i := 1
    dLen := StrLen(delimiter)

    while (i <= StrLen(text)) {
        ch := SubStr(text, i, 1)

        if (ch = "\\") {
            if (i < StrLen(text)) {
                nextCh := SubStr(text, i + 1, 1)
                if (nextCh = delimiter || nextCh = "\\") {
                    current .= nextCh
                    i += 2
                    continue
                }
            }
        }

        if (SubStr(text, i, dLen) = delimiter) {
            parts.Push(current)
            current := ""
            i += dLen
            continue
        }

        current .= ch
        i++
    }

    parts.Push(current)
    return parts
}

JoinParams(params, startIndex := 1, delimiter := "|") {
    output := ""

    Loop params.Length - startIndex + 1 {
        idx := startIndex + A_Index - 1
        if (idx > params.Length)
            break

        if (output != "")
            output .= delimiter
        output .= params[idx]
    }

    return output
}

EscapeBindingValue(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, "|", "\|")
    return str
}
