# vim: set ts=4:
# Copyright 2022-present Jakub Jirutka <jakub@jirutka.cz>.
# Copyright 2024-present Michael Matta.
# SPDX-License-Identifier: MIT
#
# Emacs shift-select mode for Zsh - select text in the command line using Shift
# as in many text editors, browsers and other GUI programs.
#
# Version: 0.2.0
# Homepage: <https://github.com/Michael-Matta1/zsh-shift-select>
# Original: <https://github.com/jirutka/zsh-shift-select>

# Detect clipboard tool based on display server
typeset -g _SHIFT_SELECT_CLIPBOARD_CMD
typeset -g _SHIFT_SELECT_PRIMARY_CMD
typeset -g _SHIFT_SELECT_LAST_PRIMARY=""
typeset -g _SHIFT_SELECT_ACTIVE_SELECTION=""
typeset -g _SHIFT_SELECT_LAST_BUFFER=""

# Default keybindings (for reset functionality)
typeset -g _SHIFT_SELECT_DEFAULT_KEYBINDINGS=(
	SELECT_ALL '^A'
	PASTE '^V'
	CUT '^X'
)

# Current keybindings (can be customized by user)
typeset -g SHIFT_SELECT_KEY_SELECT_ALL="${SHIFT_SELECT_KEY_SELECT_ALL:-^A}"
typeset -g SHIFT_SELECT_KEY_PASTE="${SHIFT_SELECT_KEY_PASTE:-^V}"
typeset -g SHIFT_SELECT_KEY_CUT="${SHIFT_SELECT_KEY_CUT:-^X}"

function shift-select::detect-clipboard() {
	if command -v wl-copy &>/dev/null && [[ -n "$WAYLAND_DISPLAY" ]]; then
		# Wayland
		_SHIFT_SELECT_CLIPBOARD_CMD="wl-copy"
		_SHIFT_SELECT_PRIMARY_CMD="wl-paste --primary"
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
		return 1
	fi
	local result
	if [[ "$_SHIFT_SELECT_PRIMARY_CMD" == wl-paste* ]]; then
		result=$(wl-paste --primary 2>/dev/null)
	else
		result=$(xclip -selection primary -o 2>/dev/null)
	fi
	if [[ -n "$result" ]]; then
		echo "$result"
		return 0
	fi
	return 1
}

# Get text from clipboard
function shift-select::get-clipboard() {
	if [[ -z "$_SHIFT_SELECT_CLIPBOARD_CMD" ]]; then
		return 1
	fi
	local result
	if [[ "$_SHIFT_SELECT_CLIPBOARD_CMD" == wl-copy* ]]; then
		result=$(wl-paste 2>/dev/null)
	else
		result=$(xclip -selection clipboard -o 2>/dev/null)
	fi
	if [[ -n "$result" ]]; then
		echo "$result"
		return 0
	fi
	return 1
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
		print -rn "$text" | xclip -selection clipboard -in
	fi
}

# Initialize clipboard detection
shift-select::detect-clipboard

# ==============================================================================
# Configuration Wizard
# ==============================================================================

# Configuration file path
typeset -g _SHIFT_SELECT_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/zsh-shift-select/config"

# Store the path to this plugin file for reset functionality
typeset -g _SHIFT_SELECT_PLUGIN_FILE="${(%):-%x}"

# Load user configuration if it exists
function shift-select::load-config() {
	if [[ -f "$_SHIFT_SELECT_CONFIG_FILE" ]]; then
		source "$_SHIFT_SELECT_CONFIG_FILE"
	fi
}

# Save configuration setting
function shift-select::save-config() {
	local key="$1"
	local value="$2"
	
	# Create config directory if it doesn't exist
	mkdir -p "${_SHIFT_SELECT_CONFIG_FILE:h}"
	
	# Create or update config file
	if [[ -f "$_SHIFT_SELECT_CONFIG_FILE" ]]; then
		# Update existing key or append if not found
		if grep -q "^${key}=" "$_SHIFT_SELECT_CONFIG_FILE" 2>/dev/null; then
			# Use a temporary file for sed compatibility across platforms
			local tmp_file="${_SHIFT_SELECT_CONFIG_FILE}.tmp"
			sed "s|^${key}=.*|${key}=\"${value}\"|" "$_SHIFT_SELECT_CONFIG_FILE" > "$tmp_file"
			mv "$tmp_file" "$_SHIFT_SELECT_CONFIG_FILE"
		else
			echo "${key}=\"${value}\"" >> "$_SHIFT_SELECT_CONFIG_FILE"
		fi
	else
		echo "${key}=\"${value}\"" > "$_SHIFT_SELECT_CONFIG_FILE"
	fi
}

# Save keybinding configuration
function shift-select::save-keybinding() {
	local action="$1"
	local keybinding="$2"
	
	shift-select::save-config "SHIFT_SELECT_KEY_${action}" "$keybinding"
}

# Load keybinding configurations
function shift-select::load-keybindings() {
	shift-select::load-config
	
	# Set current keybindings from config or use defaults
	SHIFT_SELECT_KEY_SELECT_ALL="${SHIFT_SELECT_KEY_SELECT_ALL:-^A}"
	SHIFT_SELECT_KEY_PASTE="${SHIFT_SELECT_KEY_PASTE:-^V}"
	SHIFT_SELECT_KEY_CUT="${SHIFT_SELECT_KEY_CUT:-^X}"
}

# Apply keybindings to the plugin
function shift-select::apply-keybindings() {
	# Unbind old keybindings first (if they exist)
	bindkey -M emacs -r '^A' 2>/dev/null
	bindkey -M emacs -r '^V' 2>/dev/null
	bindkey -M emacs -r '^X' 2>/dev/null
	bindkey -r '^X' 2>/dev/null
	
	# Apply new keybindings
	if [[ -n "$SHIFT_SELECT_KEY_SELECT_ALL" ]]; then
		bindkey -M emacs "$SHIFT_SELECT_KEY_SELECT_ALL" shift-select::select-all
	fi
	
	if [[ -n "$SHIFT_SELECT_KEY_PASTE" ]]; then
		bindkey -M emacs "$SHIFT_SELECT_KEY_PASTE" shift-select::paste-clipboard
		bindkey -M shift-select "$SHIFT_SELECT_KEY_PASTE" shift-select::paste-clipboard
	fi
	
	if [[ -n "$SHIFT_SELECT_KEY_CUT" ]]; then
		bindkey -M emacs "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
		bindkey -M shift-select "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
		bindkey "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
	fi
}

# Display the configuration menu
function shift-select::show-menu() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║         ZSH Shift-Select Configuration Wizard                  ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "Current Configuration:"
	echo "  Clipboard Integration: ${SHIFT_SELECT_CLIPBOARD_TYPE:-auto-detect}"
	echo "  Mouse Replacement:     ${SHIFT_SELECT_MOUSE_REPLACEMENT:-enabled}"
	echo ""
	echo "Available Options:"
	echo "  1) Configure Clipboard Integration"
	echo "  2) Configure Mouse Replacement"
	echo "  3) Configure Key Bindings"
	echo "  4) Reset to Default Configuration"
	echo "  5) View Current Configuration"
	echo "  6) Exit"
	echo ""
	echo -n "Select an option (1-6): "
}

# Configure clipboard integration
function shift-select::configure-clipboard() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║            Clipboard Integration Configuration                 ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "Select your preferred clipboard backend:"
	echo ""
	echo "  1) Wayland (wl-copy/wl-paste)"
	echo "  2) X11 (xclip)"
	echo "  3) Auto-detect (recommended)"
	echo "  4) Back to main menu"
	echo ""
	echo -n "Select an option (1-4): "
	
	read -r choice
	
	case "$choice" in
		1)
			shift-select::set-clipboard-backend "wayland"
			;;
		2)
			shift-select::set-clipboard-backend "x11"
			;;
		3)
			shift-select::set-clipboard-backend "auto"
			;;
		4)
			return
			;;
		*)
			echo ""
			echo "Invalid option. Press Enter to continue..."
			read -r
			shift-select::configure-clipboard
			;;
	esac
}

# Set clipboard backend and update plugin configuration
function shift-select::set-clipboard-backend() {
	local backend="$1"
	
	echo ""
	echo "Setting clipboard backend to: $backend"
	
	# Save to config file
	shift-select::save-config "SHIFT_SELECT_CLIPBOARD_TYPE" "$backend"
	
	# Apply the configuration immediately
	case "$backend" in
		wayland)
			if command -v wl-copy &>/dev/null; then
				_SHIFT_SELECT_CLIPBOARD_CMD="wl-copy"
				_SHIFT_SELECT_PRIMARY_CMD="wl-paste --primary"
				echo "✓ Wayland clipboard configured successfully"
			else
				echo "⚠ Warning: wl-copy not found. Please install wl-clipboard package."
			fi
			;;
		x11)
			if command -v xclip &>/dev/null; then
				_SHIFT_SELECT_CLIPBOARD_CMD="xclip -selection clipboard"
				_SHIFT_SELECT_PRIMARY_CMD="xclip -selection primary -o"
				echo "✓ X11 clipboard configured successfully"
			else
				echo "⚠ Warning: xclip not found. Please install xclip package."
			fi
			;;
		auto)
			shift-select::detect-clipboard
			echo "✓ Auto-detect mode enabled"
			;;
	esac
	
	# Update the global variable for display
	typeset -g SHIFT_SELECT_CLIPBOARD_TYPE="$backend"
	
	echo ""
	echo "Configuration saved. Press Enter to continue..."
	read -r
}

# Configure mouse replacement feature
function shift-select::configure-mouse-replacement() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║            Mouse Replacement Configuration                     ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "The Mouse Replacement feature allows you to:"
	echo "  • Select text with your mouse in the terminal"
	echo "  • Type to replace the selected text"
	echo "  • Delete selections with Backspace"
	echo "  • Paste over selections"
	echo ""
	echo "Current status: ${SHIFT_SELECT_MOUSE_REPLACEMENT:-enabled}"
	echo ""
	echo "Select an option:"
	echo ""
	echo "  1) Enable Mouse Replacement"
	echo "  2) Disable Mouse Replacement"
	echo "  3) Back to main menu"
	echo ""
	echo -n "Select an option (1-3): "
	
	read -r choice
	
	case "$choice" in
		1)
			shift-select::set-mouse-replacement "enabled"
			;;
		2)
			shift-select::set-mouse-replacement "disabled"
			;;
		3)
			return
			;;
		*)
			echo ""
			echo "Invalid option. Press Enter to continue..."
			read -r
			shift-select::configure-mouse-replacement
			;;
	esac
}

# Set mouse replacement mode and update plugin configuration
function shift-select::set-mouse-replacement() {
	local mode="$1"
	
	echo ""
	echo "Setting mouse replacement to: $mode"
	
	# Save to config file
	shift-select::save-config "SHIFT_SELECT_MOUSE_REPLACEMENT" "$mode"
	
	# Update the global variable for display
	typeset -g SHIFT_SELECT_MOUSE_REPLACEMENT="$mode"
	
	# Apply the configuration immediately by rebinding keys
	shift-select::apply-mouse-replacement-config
	
	if [[ "$mode" == "enabled" ]]; then
		echo "✓ Mouse replacement enabled"
		echo "  You can now select text with your mouse and type to replace it"
	else
		echo "✓ Mouse replacement disabled"
		echo "  Mouse selections will no longer be replaced when typing"
	fi
	
	echo ""
	echo "Configuration saved. Press Enter to continue..."
	read -r
}

# Configure Select All keybinding
function shift-select::configure-select-all() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║              Configure Select All Keybinding                   ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "Current keybinding: $SHIFT_SELECT_KEY_SELECT_ALL"
	echo ""
	echo "Select a keybinding for Select All:"
	echo ""
	echo "  1) Ctrl + A (^A)"
	echo "  2) Ctrl + Shift + A (^[[65;6u)"
	echo "  3) Advanced Option (Enter custom keybinding)"
	echo "  4) Back to Key Bindings menu"
	echo ""
	echo -n "Select an option (1-4): "
	
	read -r choice
	
	case "$choice" in
		1)
			shift-select::set-keybinding "SELECT_ALL" "^A"
			;;
		2)
			shift-select::set-keybinding "SELECT_ALL" "^[[65;6u"
			;;
		3)
			echo ""
			echo "Enter your custom keybinding (e.g., ^A, ^[[200~):"
			echo -n "> "
			read -r custom_key
			if [[ -n "$custom_key" ]]; then
				shift-select::set-keybinding "SELECT_ALL" "$custom_key"
			else
				echo "Invalid keybinding. Press Enter to continue..."
				read -r
				shift-select::configure-select-all
			fi
			;;
		4)
			return
			;;
		*)
			echo ""
			echo "Invalid option. Press Enter to continue..."
			read -r
			shift-select::configure-select-all
			;;
	esac
}

# Configure Paste keybinding
function shift-select::configure-paste() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║                Configure Paste Keybinding                      ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "Current keybinding: $SHIFT_SELECT_KEY_PASTE"
	echo ""
	echo "Select a keybinding for Paste:"
	echo ""
	echo "  1) Ctrl + V (^V)"
	echo "  2) Ctrl + Shift + V (^[[86;6u)"
	echo "  3) Advanced Option (Enter custom keybinding)"
	echo "  4) Back to Key Bindings menu"
	echo ""
	echo -n "Select an option (1-4): "
	
	read -r choice
	
	case "$choice" in
		1)
			shift-select::set-keybinding "PASTE" "^V"
			;;
		2)
			shift-select::set-keybinding "PASTE" "^[[86;6u"
			;;
		3)
			echo ""
			echo "Enter your custom keybinding (e.g., ^V, ^[[200~):"
			echo -n "> "
			read -r custom_key
			if [[ -n "$custom_key" ]]; then
				shift-select::set-keybinding "PASTE" "$custom_key"
			else
				echo "Invalid keybinding. Press Enter to continue..."
				read -r
				shift-select::configure-paste
			fi
			;;
		4)
			return
			;;
		*)
			echo ""
			echo "Invalid option. Press Enter to continue..."
			read -r
			shift-select::configure-paste
			;;
	esac
}

# Configure Cut keybinding
function shift-select::configure-cut() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║                 Configure Cut Keybinding                       ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "Current keybinding: $SHIFT_SELECT_KEY_CUT"
	echo ""
	echo "Select a keybinding for Cut:"
	echo ""
	echo "  1) Ctrl + X (^X)"
	echo "  2) Ctrl + Shift + X (^[[88;6u)"
	echo "  3) Advanced Option (Enter custom keybinding)"
	echo "  4) Back to Key Bindings menu"
	echo ""
	echo -n "Select an option (1-4): "
	
	read -r choice
	
	case "$choice" in
		1)
			shift-select::set-keybinding "CUT" "^X"
			;;
		2)
			shift-select::set-keybinding "CUT" "^[[88;6u"
			;;
		3)
			echo ""
			echo "Enter your custom keybinding (e.g., ^X, ^[[200~):"
			echo -n "> "
			read -r custom_key
			if [[ -n "$custom_key" ]]; then
				shift-select::set-keybinding "CUT" "$custom_key"
			else
				echo "Invalid keybinding. Press Enter to continue..."
				read -r
				shift-select::configure-cut
			fi
			;;
		4)
			return
			;;
		*)
			echo ""
			echo "Invalid option. Press Enter to continue..."
			read -r
			shift-select::configure-cut
			;;
	esac
}

# Set keybinding and apply it
function shift-select::set-keybinding() {
	local action="$1"
	local keybinding="$2"
	
	echo ""
	echo "Setting $action keybinding to: $keybinding"
	
	# Save to config file
	shift-select::save-keybinding "$action" "$keybinding"
	
	# Update the global variable
	case "$action" in
		SELECT_ALL)
			typeset -g SHIFT_SELECT_KEY_SELECT_ALL="$keybinding"
			;;
		PASTE)
			typeset -g SHIFT_SELECT_KEY_PASTE="$keybinding"
			;;
		CUT)
			typeset -g SHIFT_SELECT_KEY_CUT="$keybinding"
			;;
	esac
	
	# Apply the keybindings immediately
	shift-select::apply-keybindings
	
	echo "✓ Keybinding configured successfully"
	echo ""
	echo "Configuration saved. Press Enter to continue..."
	read -r
}

# Reset keybindings to defaults
function shift-select::reset-keybindings() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║             Reset Keybindings to Defaults                      ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "This will restore all keybindings to their default values:"
	echo ""
	echo "  • Select All: Ctrl + A (^A)"
	echo "  • Paste:      Ctrl + V (^V)"
	echo "  • Cut:        Ctrl + X (^X)"
	echo ""
	echo -n "Are you sure? (y/N): "
	
	read -r confirm
	
	if [[ "$confirm" =~ ^[Yy]$ ]]; then
		echo ""
		
		# Reset to defaults
		typeset -g SHIFT_SELECT_KEY_SELECT_ALL="^A"
		typeset -g SHIFT_SELECT_KEY_PASTE="^V"
		typeset -g SHIFT_SELECT_KEY_CUT="^X"
		
		# Save to config
		shift-select::save-keybinding "SELECT_ALL" "^A"
		shift-select::save-keybinding "PASTE" "^V"
		shift-select::save-keybinding "CUT" "^X"
		
		# Apply keybindings
		shift-select::apply-keybindings
		
		echo "✓ All keybindings have been reset to defaults"
		echo ""
		echo "Press Enter to continue..."
		read -r
	else
		echo ""
		echo "Reset cancelled."
		echo "Press Enter to continue..."
		read -r
	fi
}

# Configure keybindings
function shift-select::configure-keybindings() {
	while true; do
		clear
		echo "╔════════════════════════════════════════════════════════════════╗"
		echo "║              Key Bindings Configuration                        ║"
		echo "╚════════════════════════════════════════════════════════════════╝"
		echo ""
		echo "Current Key Bindings:"
		echo "  Select All: $SHIFT_SELECT_KEY_SELECT_ALL"
		echo "  Paste:      $SHIFT_SELECT_KEY_PASTE"
		echo "  Cut:        $SHIFT_SELECT_KEY_CUT"
		echo ""
		echo "Select an action to configure:"
		echo ""
		echo "  1) Select All"
		echo "  2) Paste"
		echo "  3) Cut"
		echo "  4) Reset to Default Keybindings"
		echo "  5) Back to main menu"
		echo ""
		echo -n "Select an option (1-5): "
		
		read -r choice
		
		case "$choice" in
			1)
				shift-select::configure-select-all
				;;
			2)
				shift-select::configure-paste
				;;
			3)
				shift-select::configure-cut
				;;
			4)
				shift-select::reset-keybindings
				;;
			5)
				return
				;;
			*)
				echo ""
				echo "Invalid option. Press Enter to continue..."
				read -r
				;;
		esac
	done
}

# Reset configuration to defaults
function shift-select::reset-config() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║              Reset Configuration to Defaults                   ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	echo "This will:"
	echo "  • Delete your custom configuration file"
	echo "  • Reset clipboard integration to auto-detect mode"
	echo "  • Reset mouse replacement to enabled"
	echo "  • Restore all default plugin behavior"
	echo ""
	echo -n "Are you sure? (y/N): "
	
	read -r confirm
	
	if [[ "$confirm" =~ ^[Yy]$ ]]; then
		# Remove config file
		if [[ -f "$_SHIFT_SELECT_CONFIG_FILE" ]]; then
			rm -f "$_SHIFT_SELECT_CONFIG_FILE"
			echo ""
			echo "✓ Configuration file deleted"
		fi
		
		# Reset to auto-detect
		shift-select::detect-clipboard
		unset SHIFT_SELECT_CLIPBOARD_TYPE
		
		# Reset mouse replacement to enabled (default)
		typeset -g SHIFT_SELECT_MOUSE_REPLACEMENT="enabled"
		shift-select::apply-mouse-replacement-config
		
		echo "✓ Configuration reset to defaults"
		echo ""
		echo "Press Enter to continue..."
		read -r
	else
		echo ""
		echo "Reset cancelled."
		echo "Press Enter to continue..."
		read -r
	fi
}

# View current configuration
function shift-select::view-config() {
	clear
	echo "╔════════════════════════════════════════════════════════════════╗"
	echo "║                Current Configuration                           ║"
	echo "╚════════════════════════════════════════════════════════════════╝"
	echo ""
	
	if [[ -f "$_SHIFT_SELECT_CONFIG_FILE" ]]; then
		echo "Configuration file: $_SHIFT_SELECT_CONFIG_FILE"
		echo ""
		echo "Settings:"
		echo "─────────────────────────────────────────────────────────────"
		cat "$_SHIFT_SELECT_CONFIG_FILE"
		echo "─────────────────────────────────────────────────────────────"
	else
		echo "No custom configuration file found."
		echo "Using default settings (auto-detect mode)."
	fi
	
	echo ""
	echo "Active Settings:"
	echo "  Clipboard Type:     ${SHIFT_SELECT_CLIPBOARD_TYPE:-auto-detect}"
	echo "  Clipboard Cmd:      ${_SHIFT_SELECT_CLIPBOARD_CMD:-none}"
	echo "  Primary Cmd:        ${_SHIFT_SELECT_PRIMARY_CMD:-none}"
	echo "  Mouse Replacement:  ${SHIFT_SELECT_MOUSE_REPLACEMENT:-enabled}"
	echo ""
	echo "Key Bindings:"
	echo "  Select All:         ${SHIFT_SELECT_KEY_SELECT_ALL:-^A}"
	echo "  Paste:              ${SHIFT_SELECT_KEY_PASTE:-^V}"
	echo "  Cut:                ${SHIFT_SELECT_KEY_CUT:-^X}"
	echo ""
	echo "Plugin file: $_SHIFT_SELECT_PLUGIN_FILE"
	echo ""
	echo "Press Enter to continue..."
	read -r
}

# Main configuration wizard function
function shift-select::config-wizard() {
	# Load current config
	shift-select::load-config
	
	# Set display variables
	typeset -g SHIFT_SELECT_CLIPBOARD_TYPE="${SHIFT_SELECT_CLIPBOARD_TYPE:-auto-detect}"
	typeset -g SHIFT_SELECT_MOUSE_REPLACEMENT="${SHIFT_SELECT_MOUSE_REPLACEMENT:-enabled}"
	
	# Load keybinding configurations
	shift-select::load-keybindings
	
	while true; do
		shift-select::show-menu
		read -r choice
		
		case "$choice" in
			1)
				shift-select::configure-clipboard
				;;
			2)
				shift-select::configure-mouse-replacement
				;;
			3)
				shift-select::configure-keybindings
				;;
			4)
				shift-select::reset-config
				;;
			5)
				shift-select::view-config
				;;
			6)
				clear
				echo "Configuration wizard closed."
				return 0
				;;
			*)
				echo ""
				echo "Invalid option. Press Enter to continue..."
				read -r
				;;
		esac
	done
}

# Create the zselect command with subcommand support
function zselect() {
	case "$1" in
		conf|config)
			shift-select::config-wizard
			;;
		*)
			echo "ZSH Shift-Select Plugin"
			echo ""
			echo "Usage: zselect <command>"
			echo ""
			echo "Commands:"
			echo "  conf, config    Launch configuration wizard"
			echo ""
			echo "For more information, visit:"
			echo "https://github.com/Michael-Matta1/zsh-shift-select"
			;;
	esac
}

# Load user configuration on plugin initialization
shift-select::load-config

# Load keybinding configurations
shift-select::load-keybindings

# Apply user's clipboard preference if set
if [[ -n "$SHIFT_SELECT_CLIPBOARD_TYPE" ]]; then
	case "$SHIFT_SELECT_CLIPBOARD_TYPE" in
		wayland)
			if command -v wl-copy &>/dev/null; then
				_SHIFT_SELECT_CLIPBOARD_CMD="wl-copy"
				_SHIFT_SELECT_PRIMARY_CMD="wl-paste --primary"
			fi
			;;
		x11)
			if command -v xclip &>/dev/null; then
				_SHIFT_SELECT_CLIPBOARD_CMD="xclip -selection clipboard"
				_SHIFT_SELECT_PRIMARY_CMD="xclip -selection primary -o"
			fi
			;;
		# auto is already handled by the initial detect-clipboard call
	esac
fi

# Apply mouse replacement configuration on initialization
# This function will be defined later, after the widget definitions
function shift-select::apply-mouse-replacement-config() {
	# Get current setting (default to enabled if not set)
	local mode="${SHIFT_SELECT_MOUSE_REPLACEMENT:-enabled}"
	
	if [[ "$mode" == "enabled" ]]; then
		# Bind mouse-related handlers in emacs keymap
		bindkey -M emacs -R ' '-'~' shift-select::handle-char
		bindkey -M emacs '^?' shift-select::delete-mouse-or-backspace
		bindkey -M emacs '^[[200~' shift-select::bracketed-paste-replace
	else
		# Unbind mouse handlers - restore default behavior
		# Use self-insert for printable characters (space to ~)
		bindkey -M emacs -R ' '-'~' self-insert
		# Restore default backspace behavior
		bindkey -M emacs '^?' backward-delete-char
		# Restore default bracketed paste
		bindkey -M emacs '^[[200~' bracketed-paste
	fi
}

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

# Delete mouse selection or perform normal backspace
function shift-select::delete-mouse-or-backspace() {
	local mouse_sel=$(shift-select::get-primary)
	
	# Check if PRIMARY has changed (new selection was made)
	if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" ]]; then
		# This is a NEW selection - mark it as active
		_SHIFT_SELECT_ACTIVE_SELECTION="$mouse_sel"
		_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
	fi
	
	# Only delete if we have an ACTIVE mouse selection that exists in the buffer
	if [[ -n "$_SHIFT_SELECT_ACTIVE_SELECTION" && "$BUFFER" == *"$_SHIFT_SELECT_ACTIVE_SELECTION"* ]]; then
		# Find and delete the mouse-selected text from buffer
		local before="${BUFFER%%$_SHIFT_SELECT_ACTIVE_SELECTION*}"
		local after="${BUFFER#*$_SHIFT_SELECT_ACTIVE_SELECTION}"
		BUFFER="${before}${after}"
		CURSOR=${#before}
		# Clear the active selection after deleting
		_SHIFT_SELECT_ACTIVE_SELECTION=""
		_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
		return
	fi
	
	# No active mouse selection - perform normal backspace
	zle backward-delete-char -w
}
zle -N shift-select::delete-mouse-or-backspace

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
	
	# No selection - just insert character normally
	zle self-insert -w
}
zle -N shift-select::replace-selection

# Check for mouse selection and handle character input
# This detects fresh mouse selections and replaces them when typing
function shift-select::handle-char() {
	local mouse_sel=$(shift-select::get-primary)
	
	# Check if PRIMARY has changed (new selection was made)
	if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" ]]; then
		# This is a NEW selection - mark it as active
		_SHIFT_SELECT_ACTIVE_SELECTION="$mouse_sel"
		_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
	fi
	
	# Check if we have an ACTIVE mouse selection that exists in buffer
	if [[ -n "$_SHIFT_SELECT_ACTIVE_SELECTION" && "$BUFFER" == *"$_SHIFT_SELECT_ACTIVE_SELECTION"* ]]; then
		# Find and delete the mouse-selected text from buffer
		local before="${BUFFER%%$_SHIFT_SELECT_ACTIVE_SELECTION*}"
		local after="${BUFFER#*$_SHIFT_SELECT_ACTIVE_SELECTION}"
		BUFFER="${before}${after}"
		CURSOR=${#before}
		# Clear the active selection after replacing it ONCE
		_SHIFT_SELECT_ACTIVE_SELECTION=""
	fi
	
	# Insert the typed character
	zle self-insert -w
	
	# Update buffer tracking after character insertion
	_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
}
zle -N shift-select::handle-char

# Monitor PRIMARY selection changes to track active selections
function shift-select::update-active-selection() {
	local current_primary=$(shift-select::get-primary)
	
	# Update last known PRIMARY value for reference
	if [[ -n "$current_primary" ]]; then
		_SHIFT_SELECT_LAST_PRIMARY="$current_primary"
	fi
}

# Hook that runs on every ZLE widget call
function shift-select::zle-line-pre-redraw() {
	shift-select::update-active-selection
}

# Register the hook
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw shift-select::zle-line-pre-redraw

# Copy the selected region to clipboard and deactivate selection.
function shift-select::copy-region() {
	if (( REGION_ACTIVE )); then
		# If zsh has a selection, copy it
		local start=$(( MARK < CURSOR ? MARK : CURSOR ))
		local length=$(( MARK > CURSOR ? MARK - CURSOR : CURSOR - MARK ))
		local selected="${BUFFER:$start:$length}"
		shift-select::copy-to-clipboard "$selected"
		_SHIFT_SELECT_LAST_PRIMARY="$selected"
		_SHIFT_SELECT_ACTIVE_SELECTION=""
		zle deactivate-region -w
		zle -K main
	else
		# No zsh selection - copy from PRIMARY to clipboard
		local primary_sel=$(shift-select::get-primary)
		if [[ -n "$primary_sel" ]]; then
			shift-select::copy-to-clipboard "$primary_sel"
			_SHIFT_SELECT_LAST_PRIMARY="$primary_sel"
			# After manual copy, clear active selection so it won't be auto-replaced
			_SHIFT_SELECT_ACTIVE_SELECTION=""
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
		_SHIFT_SELECT_LAST_PRIMARY="$selected"
		_SHIFT_SELECT_ACTIVE_SELECTION=""
		# Delete the selected text
		zle kill-region -w
		zle -K main
	else
		# No zsh selection - try to cut mouse selection from buffer
		local mouse_sel=$(shift-select::get-primary)
		
		# Check if PRIMARY has changed (new selection was made)
		if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" ]]; then
			_SHIFT_SELECT_ACTIVE_SELECTION="$mouse_sel"
			_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
		fi
		
		if [[ -n "$_SHIFT_SELECT_ACTIVE_SELECTION" && "$BUFFER" == *"$_SHIFT_SELECT_ACTIVE_SELECTION"* ]]; then
			# Copy to clipboard
			shift-select::copy-to-clipboard "$_SHIFT_SELECT_ACTIVE_SELECTION"
			
			# Find and delete it from the buffer
			local before="${BUFFER%%$_SHIFT_SELECT_ACTIVE_SELECTION*}"
			local after="${BUFFER#*$_SHIFT_SELECT_ACTIVE_SELECTION}"
			BUFFER="${before}${after}"
			CURSOR=${#before}
			
			# Clear active selection
			_SHIFT_SELECT_ACTIVE_SELECTION=""
		fi
	fi
}
zle -N shift-select::cut-region

# Custom bracketed paste that replaces selected text
function shift-select::bracketed-paste-replace() {
	# Check if there's an active keyboard selection
	if (( REGION_ACTIVE )); then
		# Delete the selected region first
		zle kill-region -w
		REGION_ACTIVE=0
		zle -K main
	else
		# Check for fresh mouse selection
		local mouse_sel=$(shift-select::get-primary)
		
		# Check if PRIMARY has changed (new selection was made)
		if [[ -n "$mouse_sel" && "$mouse_sel" != "$_SHIFT_SELECT_LAST_PRIMARY" ]]; then
			# This is a NEW selection - mark it as active
			_SHIFT_SELECT_ACTIVE_SELECTION="$mouse_sel"
			_SHIFT_SELECT_LAST_PRIMARY="$mouse_sel"
		fi
		
		# Replace active mouse selection if it exists in buffer
		if [[ -n "$_SHIFT_SELECT_ACTIVE_SELECTION" && "$BUFFER" == *"$_SHIFT_SELECT_ACTIVE_SELECTION"* ]]; then
			local before="${BUFFER%%$_SHIFT_SELECT_ACTIVE_SELECTION*}"
			local after="${BUFFER#*$_SHIFT_SELECT_ACTIVE_SELECTION}"
			BUFFER="${before}${after}"
			CURSOR=${#before}
			# Clear the active selection after replacing
			_SHIFT_SELECT_ACTIVE_SELECTION=""
		fi
	fi
	
	# Now perform the default bracketed paste at the current cursor position
	zle .bracketed-paste
	
	# Update buffer tracking after paste
	_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
}
zle -N shift-select::bracketed-paste-replace

# Manual paste function for Ctrl+V
function shift-select::paste-clipboard() {
	# Get clipboard content first
	local clipboard_content=$(shift-select::get-clipboard)
	
	# Check if there's an active keyboard selection
	if (( REGION_ACTIVE )); then
		# Delete the selected region first
		zle kill-region -w
		REGION_ACTIVE=0
		zle -K main
	fi
	
	# NEVER replace mouse selections on paste - they may have been visually deselected
	
	# Insert clipboard content
	if [[ -n "$clipboard_content" ]]; then
		LBUFFER="${LBUFFER}${clipboard_content}"
	fi
	
	# Update buffer tracking after paste
	_SHIFT_SELECT_LAST_BUFFER="$BUFFER"
}
zle -N shift-select::paste-clipboard


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
	); do
		bindkey -M shift-select ${terminfo[$kcap]:-$seq} $widget
	done
	
	# Bind user-configurable keybindings in shift-select keymap
	bindkey -M shift-select "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
	bindkey -M shift-select "$SHIFT_SELECT_KEY_PASTE" shift-select::paste-clipboard
	
	# Bind Backspace in emacs keymap to handle mouse selections
	bindkey -M emacs '^?' shift-select::delete-mouse-or-backspace
	
	# Bind user-configurable keybindings in emacs keymap
	bindkey -M emacs "$SHIFT_SELECT_KEY_SELECT_ALL" shift-select::select-all
	bindkey -M emacs "$SHIFT_SELECT_KEY_PASTE" shift-select::paste-clipboard
	bindkey -M emacs "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
	
	# Also bind Ctrl+Shift+C in emacs keymap for mouse selections
	bindkey -M emacs '^[[67;6u' shift-select::copy-region
	
	# Ensure Cut is bound in main keymap as well
	bindkey "$SHIFT_SELECT_KEY_CUT" shift-select::cut-region
	
	# Override the default bracketed-paste widget to handle paste-replace
	bindkey -M emacs '^[[200~' shift-select::bracketed-paste-replace
	bindkey -M shift-select '^[[200~' shift-select::bracketed-paste-replace
}

# Apply mouse replacement configuration based on user preference
# This must be called after all widgets are defined and initial bindings are set
shift-select::apply-mouse-replacement-config

# Apply custom keybindings if configured by the user
# This ensures user's custom keybindings override the defaults
shift-select::apply-keybindings
