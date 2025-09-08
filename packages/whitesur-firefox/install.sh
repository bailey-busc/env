set -euo pipefail

# Theme source directory (will be substituted by Nix)
THEME_SOURCE="@out@/share/firefox-themes"

# Colors
readonly c_default="\033[0m"
readonly c_blue="\033[1;34m"
readonly c_magenta="\033[1;35m"
readonly c_cyan="\033[1;36m"
readonly c_green="\033[1;32m"
readonly c_red="\033[1;31m"
readonly c_yellow="\033[1;33m"

# Default values
THEME_NAME="WhiteSur"
ADAPTIVE=""
ALT=""
REMOVE=false

prompt() {
    case "${1}" in
    "-s") echo -e "  ${c_green}${2}${c_default}" ;;
    "-e") echo -e "  ${c_red}${2}${c_default}" ;;
    "-w") echo -e "  ${c_yellow}${2}${c_default}" ;;
    "-i") echo -e "  ${c_cyan}${2}${c_default}" ;;
    esac
}

usage() {
    echo -e "${c_cyan}Usage: ${c_blue}$0 ${c_green}[OPTIONS...]"
    echo -e "\n${c_cyan}OPTIONS:"
    echo -e "  ${c_magenta}-m, --monterey${c_default}     Install 'Monterey' theme variant"
    echo -e "  ${c_magenta}-a, --alt${c_default}          Install alt version (only with Monterey)"
    echo -e "  ${c_magenta}-A, --adaptive${c_default}     Install adaptive color version"
    echo -e "  ${c_magenta}-r, --remove${c_default}       Remove installed theme"
    echo -e "  ${c_magenta}-p, --profile${c_default}      Specify Firefox profile name"
    echo -e "  ${c_magenta}-h, --help${c_default}         Show this help"
}

get_firefox_dir() {
    local firefox_dir=""

    # Check for regular Firefox
    if [[ -d "$HOME/.mozilla/firefox" ]]; then
        firefox_dir="$HOME/.mozilla/firefox"
    # Check for Flatpak Firefox
    elif [[ -d "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" ]]; then
        firefox_dir="$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    # Check for Snap Firefox
    elif [[ -d "$HOME/snap/firefox/common/.mozilla/firefox" ]]; then
        firefox_dir="$HOME/snap/firefox/common/.mozilla/firefox"
    fi

    echo "$firefox_dir"
}

install_theme() {
    local profile_dir="$1"
    local theme_dir="$2"

    prompt -i "Installing theme for profile: $(basename "$profile_dir")"

    # Create chrome directory
    mkdir -p "$profile_dir/chrome"

    # Copy theme files
    cp -r "$THEME_SOURCE/$THEME_NAME"/* "$profile_dir/chrome/"

    # Copy appropriate userChrome.css
    local chrome_variant="${THEME_NAME}"
    [[ -n "$ADAPTIVE" ]] && chrome_variant="${chrome_variant}-adaptive"
    [[ "$ALT" == "true" && "$THEME_NAME" == "Monterey" ]] && chrome_variant="Monterey-alt${ADAPTIVE}"

    if [[ -f "$THEME_SOURCE/userChrome-${chrome_variant}.css" ]]; then
        cp "$THEME_SOURCE/userChrome-${chrome_variant}.css" "$profile_dir/chrome/userChrome.css"
    else
        prompt -w "userChrome variant not found: userChrome-${chrome_variant}.css"
        cp "$THEME_SOURCE/userChrome-${THEME_NAME}.css" "$profile_dir/chrome/userChrome.css"
    fi

    # Copy userContent.css
    cp "$THEME_SOURCE/userContent-${THEME_NAME}${ADAPTIVE}.css" "$profile_dir/chrome/userContent.css" 2>/dev/null ||
        cp "$THEME_SOURCE/userContent-${THEME_NAME}.css" "$profile_dir/chrome/userContent.css"

    # Copy customChrome.css
    cp "$THEME_SOURCE/customChrome.css" "$profile_dir/chrome/" 2>/dev/null || true

    # Update user.js
    touch "$profile_dir/user.js"

    # Remove old preferences if they exist
    sed -i '/toolkit.legacyUserProfileCustomizations.stylesheets/d' "$profile_dir/user.js"
    sed -i '/browser.tabs.drawInTitlebar/d' "$profile_dir/user.js"
    sed -i '/browser.uidensity/d' "$profile_dir/user.js"
    sed -i '/layers.acceleration.force-enabled/d' "$profile_dir/user.js"
    sed -i '/mozilla.widget.use-argb-visuals/d' "$profile_dir/user.js"
    sed -i '/widget.gtk.rounded-bottom-corners.enabled/d' "$profile_dir/user.js"
    sed -i '/svg.context-properties.content.enabled/d' "$profile_dir/user.js"

    # Add preferences
    cat >>"$profile_dir/user.js" <<EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("browser.uidensity", 0);
user_pref("layers.acceleration.force-enabled", true);
user_pref("mozilla.widget.use-argb-visuals", true);
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
user_pref("svg.context-properties.content.enabled", true);
EOF

    prompt -s "Theme installed successfully!"
}

remove_theme() {
    local profile_dir="$1"

    prompt -i "Removing theme from profile: $(basename "$profile_dir")"

    # Remove chrome directory
    rm -rf "$profile_dir/chrome"

    # Clean up user.js
    if [[ -f "$profile_dir/user.js" ]]; then
        sed -i '/toolkit.legacyUserProfileCustomizations.stylesheets/d' "$profile_dir/user.js"
        sed -i '/browser.tabs.drawInTitlebar/d' "$profile_dir/user.js"
        sed -i '/browser.uidensity/d' "$profile_dir/user.js"
        sed -i '/layers.acceleration.force-enabled/d' "$profile_dir/user.js"
        sed -i '/mozilla.widget.use-argb-visuals/d' "$profile_dir/user.js"
        sed -i '/widget.gtk.rounded-bottom-corners.enabled/d' "$profile_dir/user.js"
        sed -i '/svg.context-properties.content.enabled/d' "$profile_dir/user.js"
    fi

    prompt -s "Theme removed successfully!"
}

# Parse arguments
PROFILE_NAME=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    -m | --monterey)
        THEME_NAME="Monterey"
        shift
        ;;
    -a | --alt)
        ALT="true"
        THEME_NAME="Monterey"
        shift
        ;;
    -A | --adaptive)
        ADAPTIVE="-adaptive"
        prompt -i "Installing adaptive color version..."
        prompt -w "You need the adaptive-tab-bar-colour addon: https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour/"
        shift
        ;;
    -r | --remove)
        REMOVE=true
        shift
        ;;
    -p | --profile)
        PROFILE_NAME="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        prompt -e "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

# Find Firefox directory
FIREFOX_DIR=$(get_firefox_dir)
if [[ -z "$FIREFOX_DIR" ]]; then
    prompt -e "Firefox directory not found!"
    prompt -i "Please make sure Firefox is installed and has been run at least once."
    exit 1
fi

prompt -i "Firefox directory: $FIREFOX_DIR"

# Check if Firefox is running
if pgrep -x "firefox" >/dev/null; then
    prompt -w "Firefox is running. Please close it before continuing."
    read -p "Press Enter when Firefox is closed..."
fi

# Process profiles
if [[ -n "$PROFILE_NAME" ]]; then
    # Specific profile requested
    PROFILE_DIR="$FIREFOX_DIR/$PROFILE_NAME"
    if [[ ! -d "$PROFILE_DIR" ]]; then
        prompt -e "Profile '$PROFILE_NAME' not found!"
        exit 1
    fi

    if [[ "$REMOVE" == true ]]; then
        remove_theme "$PROFILE_DIR"
    else
        install_theme "$PROFILE_DIR" "$THEME_NAME"
    fi
else
    # Process all profiles
    found_profile=false
    for profile_dir in "$FIREFOX_DIR"/*default*; do
        if [[ -d "$profile_dir" && -f "$profile_dir/prefs.js" ]]; then
            found_profile=true
            if [[ "$REMOVE" == true ]]; then
                remove_theme "$profile_dir"
            else
                install_theme "$profile_dir" "$THEME_NAME"
            fi
        fi
    done

    if [[ "$found_profile" == false ]]; then
        prompt -e "No Firefox profiles found!"
        prompt -i "Please run Firefox at least once to create a profile."
        exit 1
    fi
fi

echo
if [[ "$REMOVE" != true ]]; then
    prompt -w "IMPORTANT: Please go to Firefox menu > Customize..."
    prompt -w "Move the 'new tab' button to the title bar for the best experience."
    prompt -i "You can edit userChrome.css in your profile's chrome directory for further customization."
fi
