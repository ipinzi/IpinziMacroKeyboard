# 🎛 Ipinzi's Macro Keyboard - Multi-Keyboard Macro System

Turn a **second keyboard into a programmable macro deck** (similar to a
Stream Deck).

This project allows you to assign **custom actions to every key on a
secondary keyboard** without affecting your primary keyboard.

It supports:

-   🎹 Multiple keyboards
-   ⚡ Instant macro execution
-   🧩 Unlimited layers
-   🎬 OBS scene switching
-   🔁 Auto-reloading configuration
-   🧙 Interactive macro wizard
-   📋 Clipboard binding generator

You can download the latest release here https://github.com/ipinzi/IpinziMacroKeyboard/releases

------------------------------------------------------------------------

## Dynamic Macros

All macros are defined in:

`bindings.ini`

The app automatically reloads the file when it changes.

No restart required.

## OBS Integration

Control **OBS Studio** directly from your macro keyboard.

Current Supported actions (more can be added in future):

-   Scene switching
-   Start/stop recording
-   Start/stop streaming
-   Mute audio sources
-   Trigger OBS hotkeys

------------------------------------------------------------------------

# Setup

## 🔴 IMPORTANT --- Add Your Keyboard to MultiKB

When you run the app it will open two programs in your taskbar. One of those programs (MultiKB) routes the key presses and the other runs the macro app.

Your macro keyboard **must be registered inside MultiKB**.

Otherwise the app cannot detect it.

### Steps

1.  Run app
2.  Open the MultiKB interface by clicking the D icon in the taskbar.
3.  Add the keyboards you intend to use for macros (not your main keyboard)
4.  If your keyboard does not show in the list unplug it and plug it back in
5.  Assign a keyboard number

Your keyboard should now be active and show a tooltip when any unboud keys are pressed. You can use one of these key numbers to create a capture key in the bindings.ini so you can use
the binding wizard to create your bindings. Alternatively you can just manually edit the bindings.ini and add each key binding manually.

## 🎬 OBS Setup (Optional)

Enable WebSocket:

    OBS → Tools → WebSocket Server Settings

Enable:

    Enable WebSocket Server

Default port:

    4455

------------------------------------------------------------------------

# Usage

## 🧩 Binding Format

    layer|keyboard_key=action|value

Example:

    default|2_112=run|notepad.exe

but most of the time you should use the full file path

    default|2_112=run|C:\Program Files (x86)\Adobe\Photoshop\Photoshop.exe

------------------------------------------------------------------------

## 🎮 Supported Actions

## Run Program

    run|program

Example:

    default|2_112=run|notepad.exe

------------------------------------------------------------------------

## Send Keystrokes

    send|keys

Example:

    default|2_113=send|^c

Result:

    CTRL + C

------------------------------------------------------------------------

## Message Box (Show a message)

    msg|text

Example:

    default|2_114=msg|Hello World

------------------------------------------------------------------------

## Media Controls

    media|action

Supported:

    playpause
    next
    prev
    stop
    mute
    volup
    voldown

Example:

    default|2_115=media|playpause

------------------------------------------------------------------------

# 🎬 OBS Actions

## Switch Scene

    obs_scene|Scene Name

Example:

    default|2_112=obs_scene|Live

------------------------------------------------------------------------

## Recording

    obs_record|start
    obs_record|stop
    obs_record|toggle

Example:

    default|2_113=obs_record|start

------------------------------------------------------------------------

## Streaming

    obs_stream|start
    obs_stream|stop
    obs_stream|toggle

------------------------------------------------------------------------

## Mute Input

    obs_mute|InputName|toggle

Example:

    default|2_115=obs_mute|Mic/Aux|toggle

------------------------------------------------------------------------

# ⭐ Recommended Use Cases

-   Streaming macro deck
-   Game macro keyboard
-   Video editing shortcuts
-   Developer automation
-   Home automation hotkeys

------------------------------------------------------------------------

# Key Modifier Symbols (Send Actions)

A concise reference for modifier symbols used for send actions (sending keystrokes).

---

## Core Modifiers

| Symbol | Modifier    | Example | Result    |
| ------ | ----------- | ------- | --------- |
| `^`    | Ctrl        | `^c`    | Ctrl + C  |
| `!`    | Alt         | `!f4`   | Alt + F4  |
| `+`    | Shift       | `+a`    | Shift + A |
| `#`    | Windows key | `#e`    | Win + E   |

Modifiers can be combined.

Example:

```
^!c      Ctrl + Alt + C
^+s      Ctrl + Shift + S
#!r      Win + Alt + R
^+#s     Ctrl + Shift + Win + S
```

---

## Left / Right Specific Modifiers

These specify the left or right version of modifier keys.

| Symbol | Meaning        | Example | Result        |
| ------ | -------------- | ------- | ------------- |
| `<`    | Left modifier  | `<^c`   | Left Ctrl + C |
| `>`    | Right modifier | `>!a`   | Right Alt + A |

Supported combinations:

```
<^  Left Ctrl
>^  Right Ctrl
<!  Left Alt
>!  Right Alt
<+  Left Shift
>+  Right Shift
<#  Left Win
>#  Right Win
```

---

## Modifier Behaviour Flags

| Symbol | Meaning                                  | Example | Result                              |
| ------ | ---------------------------------------- | ------- | ----------------------------------- |
| `*`    | Wildcard (ignore extra modifiers)        | `*F1`   | F1 triggers regardless of modifiers |
| `~`    | Pass-through (do not block original key) | `~a`    | A still types normally              |
| `$`    | Prevent trigger recursion                | `$^c`   | Safe remapping                      |
| `&`    | Custom key combination                   | `a & b` | A held + B pressed                  |

Example:

```
CapsLock & j
```

Result:

```
Press CapsLock + J
```

---

## Special Key Syntax

Special keys must be wrapped in braces.

```
{Enter}
{Tab}
{Esc}
{Delete}
{Space}
{F1}
```

Example:

```
^+{Esc}
```

Result:

```
Ctrl + Shift + Esc
```

---

## Complete Modifier Symbol Reference

```
^  Ctrl
!  Alt
+  Shift
#  Win
<  Left modifier
>  Right modifier
*  Wildcard
~  Pass-through
$  Prevent recursion
&  Combo key
```


# License

Free for personal use.
