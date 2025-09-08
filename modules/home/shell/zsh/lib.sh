include() {
  [[ -f "$1" ]] && source "$1"
}

has() {
  type "$1" &>/dev/null
}

cbc() {
  cat $1 | xclip -selection clipboard
}
