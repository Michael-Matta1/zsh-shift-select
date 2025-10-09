# Zsh Shift Select Mode

Emacs [shift-select mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Shift-Selection.html) for Zsh — select text in the command line using Shift as in many text editors, browsers and other GUI programs. Features **full editor-like experience** with type-to-replace, paste-replace, and seamless **mouse selection integration** that works alongside keyboard

![Demo](media/demo.gif)

---

## Table of Contents

-   [Overview](#overview)
-   [Features](#features)
-   [Installation](#installation)
-   [Key Bindings](#key-bindings)
-   [Clipboard Integration](#clipboard-integration)
-   [Terminal Compatibility](#terminal-compatibility)

---

## Overview

This plugin brings familiar text selection behavior to your Zsh command line. Select text using **Shift + Arrow keys** just like you would in any GUI text editor, then type to replace, or copy/cut to clipboard.

### Key Design Principles

-   **Non-invasive**: Does not override any existing widgets
-   **Only binds shifted keys**: Preserves all your existing keybindings
-   **Automatic keymap switching**: Seamlessly switches between `main` and `shift-select` keymaps
-   **Plugin-friendly**: Works perfectly with [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and other popular plugins
-   **Zero configuration**: Automatically detects your display server (Wayland/X11) and uses appropriate clipboard tools

---

## Features

### Multi-Display Server Support

The plugin **automatically detects** your display server and uses the appropriate clipboard tool:

| Display Server   | Clipboard Tool           | Status                                 |
| ---------------- | ------------------------ | -------------------------------------- |
| **Wayland**      | `wl-copy` and `wl-paste` | ✅ Auto-detected                       |
| **X11**          | `xclip`                  | ✅ Auto-detected                       |
| **No clipboard** | N/A                      | ⚠️ Selection works, clipboard disabled |

**No configuration needed** — it just works!

### Text Selection

-   **Shift + Arrow keys**: Select text just like in GUI text editors
-   **Ctrl + A**: Select all text in the buffer (including multi-line commands)
-   **Mouse selection support**: The plugin recognizes and works with text selected via mouse

### Type-to-Replace

Type while text is selected to replace it automatically:

-   ✅ Works with **keyboard selections** (Shift + arrows)
-   ✅ Works with **mouse selections** (highlight text with your mouse, then type)
-   ✅ Seamlessly handles **multiple windows/splits** within the same terminal

### Delete Selected Text

Delete selected text with a single key press:

-   ✅ Works with **keyboard selections** (Shift + arrows) - press **Delete** or **Backspace**
-   ✅ Works with **mouse selections** - press **Backspace** to delete the selected text

> **⚠️ Important Note on Mouse Selection:** If your command contains multiple occurrences of the same exact selected text, mouse selection will replace/delete the **first occurrence** found in the buffer, not necessarily the one you visually selected. For more reliable text replacement or deletion, especially with duplicate text, it's recommended to use **Shift + Arrow keys** for selection instead of mouse selection.

### Paste-Replace

Replace selected text by pasting:

1. Select text with **Shift + Arrow keys** (or **Ctrl + A** for all) **or** select with your mouse
2. Press **Ctrl + V** to paste
3. The selected text will be replaced with the pasted content

Works with both keyboard and mouse selections!

### Copy and Cut

-   **Ctrl + Shift + C** (or **Ctrl + C** with remapping): Copy selected text to clipboard
-   **Ctrl + X**: Cut selected text to clipboard
-   Works with both keyboard selections and mouse selections

---

## Installation

### Using sheldon

If you use [sheldon](https://github.com/rossmacarthur/sheldon) plugin manager, run:

```sh
sheldon add zsh-shift-select --github Michael-Matta1/zsh-shift-select
```

### Using zgenom

If you use [zgenom](https://github.com/jandamm/zgenom) (successor of [zgen](https://github.com/tarjoilija/zgen)), add this to your `.zshrc`:

```sh
zgenom load "Michael-Matta1/zsh-shift-select"
```

### Using Oh My Zsh

If you use [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) framework:

1. **Clone the repository** into `$ZSH_CUSTOM/plugins`:

    ```sh
    git clone https://github.com/Michael-Matta1/zsh-shift-select.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-shift-select
    ```

2. **Add the plugin** to your `.zshrc`:

    ```sh
    plugins=(
        # other plugins...
        zsh-shift-select
    )
    ```

3. **Restart** your terminal or source your `.zshrc`:
    ```sh
    source ~/.zshrc
    ```

### Manually (Git Clone)

1. **Clone the repository**:

    ```sh
    git clone https://github.com/Michael-Matta1/zsh-shift-select ~/.local/share/zsh/plugins/zsh-shift-select
    ```

2. **Source the plugin** in your `~/.zshrc`:

    ```sh
    source ~/.local/share/zsh/plugins/zsh-shift-select/zsh-shift-select.plugin.zsh
    ```

3. **Restart** your terminal or source your `.zshrc`:
    ```sh
    source ~/.zshrc
    ```

---

## Key Bindings

### Selection Keys

Keys defined in both the `emacs` and `shift-select` keymaps:

| Key Combination         | Action                            | Notes                         |
| ----------------------- | --------------------------------- | ----------------------------- |
| **Shift + ←**           | Select one character to the left  |                               |
| **Shift + →**           | Select one character to the right |                               |
| **Shift + ↑**           | Select one line up                |                               |
| **Shift + ↓**           | Select one line down              |                               |
| **Shift + Home**        | Select to the beginning of a line |                               |
| **Shift + Ctrl + A**    | Select to the beginning of a line | Alternative to Shift + Home   |
| **Shift + End**         | Select to the end of a line       |                               |
| **Shift + Ctrl + E**    | Select to the end of a line       | Alternative to Shift + End    |
| **Shift + Ctrl + ←**    | Select to the beginning of a word | ⌥ Use Shift + Option on macOS |
| **Shift + Ctrl + →**    | Select to the end of a word       | ⌥ Use Shift + Option on macOS |
| **Shift + Ctrl + Home** | Select to the beginning of buffer | ⌥ Use Shift + Option on macOS |
| **Shift + Ctrl + End**  | Select to the end of buffer       | ⌥ Use Shift + Option on macOS |
| **Ctrl + A**            | Select all text in the buffer     | Includes multi-line commands  |

### Editing Behavior

In addition to selection, this plugin supports common text editor behaviors:

| Key Combination       | Action                  | Notes                                    |
| --------------------- | ----------------------- | ---------------------------------------- |
| **Ctrl + X**          | Cut the selected text   | Works with keyboard and mouse selections |
| **Ctrl + V**          | Paste clipboard content | Replaces any selected text               |
| **Any printable key** | Replace selected text   | Works with keyboard and mouse selections |

### Shift-Select Mode Only

Keys defined only in the `shift-select` keymap:

| Key           | Action               |
| ------------- | -------------------- |
| **Delete**    | Delete selected text |
| **Backspace** | Delete selected text |

> **Tip:** You can add custom key bindings to manipulate active selections by defining them in the `shift-select` keymap:
>
> ```sh
> bindkey -M shift-select <key-sequence> <widget>
> ```

> **Alternative:** Use default Alt + W or Ctrl + W to copy (`copy-region-as-kill`) or cut (`backward-kill-word`) selected text to the "kill buffer", and Ctrl + Y to paste (`yank`).

---

## Clipboard Integration

This plugin includes **automatic clipboard integration** that works with both Wayland and X11.

### Prerequisites

Install the appropriate clipboard tool for your display server:

#### For Wayland

```sh
# Debian/Ubuntu
sudo apt install wl-clipboard

# Arch Linux
sudo pacman -S wl-clipboard

# Fedora
sudo dnf install wl-clipboard
```

#### For X11

```sh
# Debian/Ubuntu
sudo apt install xclip

# Arch Linux
sudo pacman -S xclip

# Fedora
sudo dnf install xclip
```

The plugin will automatically detect which display server you're using and use the appropriate tool. If neither is available, the plugin will still work for text selection, but clipboard operations will be disabled.

### Using Ctrl+Shift+C (Default)

To use **Ctrl + Shift + C** for copying, add the following to your `kitty.conf`:

```conf
map ctrl+shift+c send_text all \x1b[67;6u
```

This configuration allows you to:

-   ✅ Copy shift-selected text (selected with Shift + arrows)
-   ✅ Copy mouse-selected text
-   ✅ Use Ctrl + C for interrupt (default behavior)

### Using Ctrl+C for Copying (Reversed)

If you prefer to use **Ctrl + C** for copying (like in GUI applications) and **Ctrl + Shift + C** for interrupt:

```conf
# Ctrl+C sends the escape sequence for copying
map ctrl+c send_text all \x1b[67;6u

# Ctrl+Shift+C sends interrupt (default behavior)
map ctrl+shift+c send_text all \x03
```

### Other Terminals

This approach works with any terminal emulator that supports key remapping:

-   **Kitty** — as shown above
-   **WezTerm** — use similar key remapping in `wezterm.lua`
-   **Alacritty** — use key bindings in `alacritty.yml`

> **Important:** If you have any existing mapping for Ctrl + Shift + C in your terminal config (such as `map ctrl+shift+c copy_to_clipboard`), you must remove or comment it out first, as it will conflict with this configuration.

### Alternative: Without Terminal Remapping

If your terminal doesn't support key remapping, you can add the following to your `~/.zshrc` to use **Ctrl + /** for copying:

```sh
x-copy-selection () {
  if [[ $MARK -ne $CURSOR ]]; then
    local start=$(( MARK < CURSOR ? MARK : CURSOR ))
    local length=$(( MARK > CURSOR ? MARK - CURSOR : CURSOR - MARK ))
    local selected="${BUFFER:$start:$length}"
    print -rn "$selected" | xclip -selection clipboard
  fi
}
zle -N x-copy-selection
bindkey '^_' x-copy-selection
```

You can change the keybinding to any key you prefer. For example, to use **Ctrl + K**:

```sh
bindkey '^K' x-copy-selection
```

> **Note:** The `^_` sequence represents Ctrl + / (Ctrl + Slash), and `^K` represents Ctrl + K. You can find other key sequences by running `cat` in your terminal and pressing the desired key combination.

> **Bonus Feature:** If no text is selected, this manual keybinding will copy the entire current line to the clipboard.

---

## Terminal Compatibility

Some keys may not work in your terminal by default. To check compatibility, run `cat` (without arguments) in your terminal and press the key sequence in question. If nothing is printed, your terminal or operating system has intercepted the key sequence.

### Tested Terminals

| Terminal      | Status                 | Notes                                                             |
| ------------- | ---------------------- | ----------------------------------------------------------------- |
| **Alacritty** | ✅ Works out-of-box    | No configuration needed                                           |
| **Kitty**     | ⚙️ Needs configuration | Shift + Ctrl doesn't work by default — [see fix](#kitty)          |
| **WezTerm**   | ⚙️ Needs configuration | Shift + Ctrl + arrows don't work by default — [see fix](#wezterm) |
| **VS Code**   | ⚙️ Needs configuration | Key bindings intercepted by default — [see fix](#vs-code)         |

### Kitty

[Kitty](https://sw.kovidgoyal.net/kitty/) uses Shift + Ctrl as the modifier for all its shortcuts ([kitty_mod](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.kitty_mod)) by default.

Add the following to your `kitty.conf` to unmap the conflicting key strokes:

```conf
# Don't intercept the following key strokes to make zsh-shift-select work.
map ctrl+shift+left no_op
map ctrl+shift+right no_op
map ctrl+shift+home no_op
map ctrl+shift+end no_op
```

### WezTerm

[WezTerm](https://wezfurlong.org/wezterm/) uses Shift + Ctrl + Left Arrow and Shift + Ctrl + Right Arrow to activate panes by default (see [Default Key Assignments](https://wezfurlong.org/wezterm/config/default-keys.html)).

To use these keys in Zsh instead, disable the default assignments in your `wezterm.lua`:

```lua
return {
  keys = {
    { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = 'DisableDefaultAssignment' },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = 'DisableDefaultAssignment' },
  },
}
```

### VS Code

[VS Code](https://code.visualstudio.com/) intercepts several key combinations in its integrated terminal by default. To make zsh-shift-select work properly, you need to configure VS Code to send the correct escape sequences to the terminal.

Add the following to your **`keybindings.json`** (File → Preferences → Keyboard Shortcuts → Open Keyboard Shortcuts JSON):

```json
[
	{
		// Ctrl+C sends copy sequence to terminal (CSI 67 ; 6 u)
		// This is the sequence that triggers the copy widget in zsh
		"key": "ctrl+c",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u001b[67;6u" },
		"when": "terminalFocus"
	},
	{
		// Ctrl+Shift+C sends interrupt signal (ETX control character)
		// This is equivalent to the traditional Ctrl+C interrupt behavior
		"key": "ctrl+shift+c",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u0003" },
		"when": "terminalFocus"
	},
	{
		// Ctrl+Shift+Left sends CSI 1 ; 6 D (Ctrl+Shift+Left arrow)
		// This allows word-backward selection in zsh
		"key": "ctrl+shift+left",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u001b[1;6D" },
		"when": "terminalFocus"
	},
	{
		// Ctrl+Shift+Right sends CSI 1 ; 6 C (Ctrl+Shift+Right arrow)
		// This allows word-forward selection in zsh
		"key": "ctrl+shift+right",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u001b[1;6C" },
		"when": "terminalFocus"
	},
	{
		// Ctrl+Shift+Home sends CSI 1 ; 6 H (Ctrl+Shift+Home)
		// This allows selection to beginning of buffer in zsh
		"key": "ctrl+shift+home",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u001b[1;6H" },
		"when": "terminalFocus"
	},
	{
		// Ctrl+Shift+End sends CSI 1 ; 6 F (Ctrl+Shift+End)
		// This allows selection to end of buffer in zsh
		"key": "ctrl+shift+end",
		"command": "workbench.action.terminal.sendSequence",
		"args": { "text": "\u001b[1;6F" },
		"when": "terminalFocus"
	}
]
```

#### Understanding the Escape Sequences

The escape sequences used above follow the ANSI/VT terminal protocol:

-   **`\u001b`** — ESC character (starts an escape sequence)
-   **`[67;6u`** — CSI u-format for modified keys (67 = 'C' key code, 6 = Shift+Ctrl modifiers)
-   **`\u0003`** — ETX control character (traditional interrupt signal, equivalent to `^C`)
-   **`[1;6D/C/H/F`** — CSI format for cursor movement with modifiers (1 = cursor command, 6 = Shift+Ctrl, D/C/H/F = direction)

> **Note:** If these sequences don't work for you, you can verify what your terminal expects by running `cat` (without arguments) and pressing the key combinations. The terminal will display the exact escape sequences it receives. Copy those sequences and replace the `"text"` values in the configuration above.

> **Tip:** To test if the configuration is working, open the VS Code integrated terminal, run `cat`, and press the configured key combinations. You should see output instead of VS Code intercepting the keys.

---

## References

-   [Zsh zle shift selection — StackOverflow](https://stackoverflow.com/questions/5407916/zsh-zle-shift-selection) (initial inspiration, but uses a different approach)
-   [Zsh Line Editor Documentation](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)
-   Original project: [jirutka/zsh-shift-select](https://github.com/jirutka/zsh-shift-select)

---

## License

This project is licensed under [MIT License](http://opensource.org/licenses/MIT/).
