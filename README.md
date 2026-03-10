# 🎛 Multi-Keyboard Macro System

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

------------------------------------------------------------------------

# ✨ Features

## Dedicated Macro Keyboard

Use a second keyboard purely for macros while your main keyboard behaves
normally.

  Keyboard             Purpose
  -------------------- ---------------
  Primary keyboard     Normal typing
  Secondary keyboard   Macro deck

------------------------------------------------------------------------

## Dynamic Macros

All macros are defined in:

`bindings.ini`

The script automatically reloads the file when it changes.

No restart required.

------------------------------------------------------------------------

## Binding Wizard

Create new macros without editing configuration files.

Workflow:

    Press capture key
          ↓
    Press key you want to bind
          ↓
    Choose macro type
          ↓
    Enter macro details
          ↓
    Macro saved automatically

------------------------------------------------------------------------

## OBS Integration

Control **OBS Studio** directly from your macro keyboard.

Supported actions:

-   Scene switching
-   Start/stop recording
-   Start/stop streaming
-   Mute audio sources
-   Trigger OBS hotkeys

------------------------------------------------------------------------

# 📁 Project Structure

    MacroKeyboard/
    │
    ├── MacroKeyboard.ahk
    ├── bindings.ini
    ├── unmapped_keys.log
    │
    └── data/
        └── obs_helper.ps1

  File                  Description
  --------------------- ----------------------
  MacroKeyboard.ahk     Main macro system
  bindings.ini          Macro configuration
  unmapped_keys.log     Log of unknown keys
  data/obs_helper.ps1   OBS websocket helper

------------------------------------------------------------------------

# ⚙ Requirements

## 1️⃣ Install AutoHotkey

Download:

https://www.autohotkey.com/

Required version:

    AutoHotkey v2

------------------------------------------------------------------------

## 2️⃣ Install Multi-Keyboard for AutoHotkey

Download:

https://github.com/sebeksd/Multi-Keyboard-For-AutoHotkey

Run:

    MultiKB_For_AutoHotkey.exe

------------------------------------------------------------------------

# 🔴 IMPORTANT --- Add Your Keyboard to MultiKB

Your macro keyboard **must be registered inside Multi-Keyboard for
AutoHotkey**.

Otherwise the script cannot detect it.

### Steps

1.  Run `MultiKB_For_AutoHotkey.exe`
2.  Open the MultiKB interface
3.  Press **Add Keyboard**
4.  Press a key on the keyboard you want to use as your macro keyboard
5.  Assign a keyboard number

Example:

    Keyboard 1 → Main keyboard
    Keyboard 2 → Macro keyboard

6.  Save the configuration.

------------------------------------------------------------------------

# 🎬 OBS Setup (Optional)

Install OBS:

https://obsproject.com/

Enable WebSocket:

    OBS → Tools → WebSocket Server Settings

Enable:

    Enable WebSocket Server

Default port:

    4455

------------------------------------------------------------------------

# 📄 Configuration File

Location:

    bindings.ini

Example:

``` ini
[Settings]
DefaultLayer=default
DebugTooltips=1

[OBS]
Host=127.0.0.1
Port=4455
Password=

[Bindings]

default|2_120=editbindings|
default|2_121=capture|

default|2_112=obs_scene|Starting Soon
default|2_113=obs_scene|Live
default|2_114=obs_scene|BRB
```

------------------------------------------------------------------------

# 🧩 Binding Format

    layer|keyboard_key=action|value

Example:

    default|2_112=run|notepad.exe

Meaning:

  Part          Meaning
  ------------- -----------------
  default       layer
  2             keyboard number
  112           key code
  run           action
  notepad.exe   value

------------------------------------------------------------------------

# 🎮 Supported Actions

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

## Message Box

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

# 🧙 Binding Wizard

Start wizard using a capture key.

Example:

    default|2_121=capture|

Workflow:

    Press capture key
    ↓
    Press key to bind
    ↓
    Choose action type
    ↓
    Enter action data
    ↓
    Binding written automatically

------------------------------------------------------------------------

# 🔁 Auto Reload

Whenever `bindings.ini` changes the script reloads automatically.

Notification:

    Bindings reloaded

------------------------------------------------------------------------

# 🪵 Logs

Unknown keys are logged in:

    unmapped_keys.log

Example:

    2026-03-09 | Layer=default | Keyboard=2 | VK=118 | Key=F7

------------------------------------------------------------------------

# 🖥 Converting to EXE

Compile the script:

    Right-click → Compile Script

Result:

    MacroKeyboard.exe

AutoHotkey installation will not be required.

------------------------------------------------------------------------

# ⭐ Recommended Use Cases

-   Streaming macro deck
-   Game macro keyboard
-   Video editing shortcuts
-   Developer automation
-   Home automation hotkeys

------------------------------------------------------------------------

# License

Free for personal and commercial use.
