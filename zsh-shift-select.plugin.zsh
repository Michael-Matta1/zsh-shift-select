# vim: set ts=4:
# Copyright 2022-present Jakub Jirutka <jakub@jirutka.cz>.
# SPDX-License-Identifier: MIT
#
# Emacs shift-select mode for Zsh - select text in the command line using Shift
# as in many text editors, browsers and other GUI programs.
#
# Version: 0.1.1
# Homepage: <https://github.com/jirutka/zsh-shift-select>

# Detect clipboard tool based on display server
typeset -g _SHIFT_SELECT_CLIPBOARD_CMD
typeset -g _SHIFT_SELECT_PRIMARY_CMD
typeset -g _SHIFT_SELECT_LAST_PRIMARY=""
typeset -g _SHIFT_SELECT_PRIMARY_ACTIVE=0
typeset -g _SHIFT_SELECT_LAST_BUFFER=""

function shift-select::detect-clipboard() {
	if command -v wl-copy &>/dev/null && [[ -n "$WAYLAND_DISPLAY" ]]; then
		# Wayland
		_SHIFT_SELECT_CLIPBOARD_CMD="wl-copy"
		_SHIFT_SELECT_PRIMARY_CMD="wl-copy --primary"
	elif command -v xclip &>/dev/null && [[ -n "$DISPLAY" ]]; then
		# X11
		_SHIFT_SELECT_CLIPBOARD_CMD="xclip -selection clipboard"
		_SHIFT_SELECT_PRIMARY_CMD="xclip -selection primary -o"
	else
		# Fallback: no clipboard support
		_SHIFT_SELECT_CLIPBOARD_CMD=""
		_SHIFT_SELECT_PRIMARY_CMD=""
	fi
}

# Get text from primary selection (mouse selection)
function shift-select::get-primary() {
	if [[ -z "$_SHIFT_SELECT_PRIMARY_CMD" ]]; then
		echo ""
		return 1
	fi
	
	if [[ "$_SHIFT_SELECT_PRIMARY_CMD" == wl-copy* ]]; then
		wl-paste --primary 2>/dev/null
	else
		xclip -selection primary -o 2>/dev/null
	fi
}

# Copy text to clipboard
function shift-select::copy-to-clipboard() {
	local text="$1"
	if [[ -z "$_SHIFT_SELECT_CLIPBOARD_CMD" ]]; then
		return 1
	fi
	
	if [[ "$_SHIFT_SELECT_CLIPBOARD_CMD" == wl-copy* ]]; then
		print -rn "$text" | wl-copy
	else
		print -rn "$text" | xclip -selection clipboard
	fi
}

# Initialize clipboard detection
shift-select::detect-clipboard

# Move cursor to the end of the buffer.
# This is an alternative to builtin end-of-buffer-or-history.
function end-of-buffer() {
	CURSOR=${#BUFFER}
	zle end-of-line -w  # trigger syntax highlighting redraw
}
zle -N end-of-buffer

# Move cursor to the beginning of the buffer.
# This is an alternative to builtin beginning-of-buffer-or-history.
function beginning-of-buffer() {
	CURSOR=0
	zle beginning-of-line -w  # trigger syntax highlighting redraw
}
zle -N beginning-of-buffer

# Select all text in the buffer (Ctrl+A)
function shift-select::select-all() {
	MARK=0
	CURSOR=${#BUFFER}
	REGION_ACTIVE=1
	zle -K shift-select
}
zle -N shift-select::select-all

# Kill the selected region and switch back to the main keymap.
function shift-select::kill-region() {
	zle kill-region -w
	zle -K main
}
zle -N shift-select::kill-region

# Deactivate the selection region, switch back to the main keymap and process
# the typed keys again.
function shift-select::deselect-and-input() {
	zle deactivate-region -w
	# Switch back to the main keymap (emacs).
	zle -K main
	# Push the typed keys back to the input stack, i.e. process them again,
	# but now with the main keymap.
	zle -U "$KEYS"
}
zle -N shift-select::deselect-and-input

# Replace selection with typed character (like text editors)
function shift-select::replace-selection() {
	if (( REGION_ACTIVE )); then
		# Delete the keyboard-selected text
		zle kill-region -w
		# Switch back to main keymap and insert character
		zle -K main
		zle -U "$KEYS"
		return
	fi
	
	# Check for mouse selection in PRIMARY (only if it's new)
	local mouse_sel=$(shift-select::get-primary)
	if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" && "$BUFFER" == *"$mouse_sel"* ]]; then
		# Mark that we've processed this selection
		_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
		
		# Find and delete the mouse-selected text from buffer
		local before="${BUFFER%%$mouse_sel*}"
		local after="${BUFFER#*$mouse_sel}"
		BUFFER="${before}${after}"
		CURSOR=${#before}
		# Insert the typed character at cursor position
		zle -U "$KEYS"
		return
	fi
	
	# No selection found - just insert the character normally
	zle self-insert -w
}
zle -N shift-select::replace-selection

# Check for mouse selection and handle character input
function shift-select::handle-char() {
	# If the buffer has changed since last check, update our tracking
	# This prevents replacing pasted content
	if [[ "$BUFFER" != "$_SHIFT_SELECT_LAST_BUFFER" ]]; then
		_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
		# Reset the primary tracking when buffer changes externally (paste, etc)
		local current_primary=$(shift-select::get-primary)
		if [[ -n "$current_primary" ]]; then
			_SHIFT_SELECT_LAST_PRIMARY="$current_primary"
		fi
	fi
	
	# Check for mouse selection in PRIMARY
	local mouse_sel=$(shift-select::get-primary)
	
	# Only replace if we have a new selection (different from last one we processed)
	# AND the buffer hasn't changed since the last character was typed
	if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" && "$BUFFER" == *"$mouse_sel"* ]]; then
		# Mark that we've seen and processed this selection
		_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
		
		# Find and delete the mouse-selected text from buffer
		local before="${BUFFER%%$mouse_sel*}"
		local after="${BUFFER#*$mouse_sel}"
		BUFFER="${before}${after}"
		CURSOR=${#before}
	fi
	
	# Insert the typed character
	zle self-insert -w
	
	# Update buffer tracking after character insertion
	_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
}
zle -N shift-select::handle-char

# Copy the selected region to clipboard and deactivate selection.
function shift-select::copy-region() {
	if (( REGION_ACTIVE )); then
		# If zsh has a selection, copy it
		local start=$(( MARK < CURSOR ? MARK : CURSOR ))
		local length=$(( MARK > CURSOR ? MARK - CURSOR : CURSOR - MARK ))
		local selected="${BUFFER:$start:$length}"
		shift-select::copy-to-clipboard "$selected"
		zle deactivate-region -w
		zle -K main
	else
		# No zsh selection - copy from PRIMARY to clipboard
		local primary_sel=$(shift-select::get-primary)
		if [[ -n "$primary_sel" ]]; then
			shift-select::copy-to-clipboard "$primary_sel"
			# Clear the tracking variable so this selection won't be auto-replaced
			_SHIFT_SELECT_LAST_PRIMARY="$primary_sel"
		fi
	fi
}
zle -N shift-select::copy-region

# Cut the selected region to clipboard and delete it.
function shift-select::cut-region() {
	if (( REGION_ACTIVE )); then
		# If zsh has a selection, cut it (copy and delete)
		local start=$(( MARK < CURSOR ? MARK : CURSOR ))
		local length=$(( MARK > CURSOR ? MARK - CURSOR : CURSOR - MARK ))
		local selected="${BUFFER:$start:$length}"
		shift-select::copy-to-clipboard "$selected"
		# Delete the selected text
		zle kill-region -w
		zle -K main
	else
		# No zsh selection - try to cut mouse selection from buffer
		local mouse_sel=$(shift-select::get-primary)
		if [[ -n "$mouse_sel" ]]; then
			# Copy to clipboard
			shift-select::copy-to-clipboard "$mouse_sel"
			
			# Try to find and delete it from the buffer
			if [[ "$BUFFER" == *"$mouse_sel"* ]]; then
				# Find the position of the selected text in buffer
				local before="${BUFFER%%$mouse_sel*}"
				local after="${BUFFER#*$mouse_sel}"
				
				# Reconstruct buffer without the selected text
				BUFFER="${before}${after}"
				
				# Position cursor where the deletion happened
				CURSOR=${#before}
			fi
		fi
	fi
}
zle -N shift-select::cut-region


# If the selection region is not active, set the mark at the cursor position,
# switch to the shift-select keymap, and call $WIDGET without 'shift-select::'
# prefix. This function must be used only for shift-select::<widget> widgets.
function shift-select::select-and-invoke() {
	if (( !REGION_ACTIVE )); then
		zle set-mark-command -w
		zle -K shift-select
	fi
	zle ${WIDGET#shift-select::} -w
}

function {
	emulate -L zsh

	# Create a new keymap for the shift-selection mode.
	bindkey -N shift-select

	# Bind all possible key sequences to deselect-and-input, i.e. it will be used
	# as a fallback for "unbound" key sequences.
	bindkey -M shift-select -R '^@'-'^?' shift-select::deselect-and-input
	
	# Override printable characters (space to ~) to replace selection instead
	bindkey -M shift-select -R ' '-'~' shift-select::replace-selection
	
	# Bind printable characters in emacs keymap to handle mouse selections
	bindkey -M emacs -R ' '-'~' shift-select::handle-char

	local kcap seq seq_mac widget

	# Bind Shift keys in the emacs and shift-select keymaps.
	for	kcap   seq          seq_mac    widget (             # key name
		kLFT   '^[[1;2D'    x          backward-char        # Shift + LeftArrow
		kRIT   '^[[1;2C'    x          forward-char         # Shift + RightArrow
		kri    '^[[1;2A'    x          up-line              # Shift + UpArrow
		kind   '^[[1;2B'    x          down-line            # Shift + DownArrow
		kHOM   '^[[1;2H'    x          beginning-of-line    # Shift + Home
		x      '^[[97;6u'   x          beginning-of-line    # Shift + Ctrl + A
		kEND   '^[[1;2F'    x          end-of-line          # Shift + End
		x      '^[[101;6u'  x          end-of-line          # Shift + Ctrl + E
		x      '^[[1;6D'    '^[[1;4D'  backward-word        # Shift + Ctrl/Option + LeftArrow
		x      '^[[1;6C'    '^[[1;4C'  forward-word         # Shift + Ctrl/Option + RightArrow
		x      '^[[1;6H'    '^[[1;4H'  beginning-of-buffer  # Shift + Ctrl/Option + Home
		x      '^[[1;6F'    '^[[1;4F'  end-of-buffer        # Shift + Ctrl/Option + End
	); do
		# Use alternative sequence (Option instead of Ctrl) on macOS, if defined.
		[[ "$OSTYPE" = darwin* && "$seq_mac" != x ]] && seq=$seq_mac

		zle -N shift-select::$widget shift-select::select-and-invoke
		bindkey -M emacs ${terminfo[$kcap]:-$seq} shift-select::$widget
		bindkey -M shift-select ${terminfo[$kcap]:-$seq} shift-select::$widget
	done

	# Bind keys in the shift-select keymap.
	for	kcap   seq        widget (                          # key name
		kdch1  '^[[3~'    shift-select::kill-region         # Delete
		bs     '^?'       shift-select::kill-region         # Backspace
		x      '^[[67;6u' shift-select::copy-region         # Ctrl+Shift+C
		x      '^X'       shift-select::cut-region          # Ctrl+X
	); do
		bindkey -M shift-select ${terminfo[$kcap]:-$seq} $widget
	done
	
	# Bind Ctrl+A to select all in emacs keymap
	bindkey -M emacs '^A' shift-select::select-all
	
	# Also bind Ctrl+Shift+C and Ctrl+X in emacs keymap for mouse selections
	bindkey -M emacs '^[[67;6u' shift-select::copy-region
	bindkey -M emacs '^X' shift-select::cut-region
	
	# Ensure Ctrl+X is bound in main keymap as well
	bindkey '^X' shift-select::cut-region
}