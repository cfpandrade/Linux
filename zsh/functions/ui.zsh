# Shared output helpers used by the other function files.

# Current terminal width, re-read on every call so that resizing the window
# mid-run is picked up straight away. $COLUMNS is only refreshed by zsh between
# commands, and a long-running function never gets that chance, so ask the tty
# directly and fall back to 80 when there is no tty (pipe, cron, CI).
_ancho_terminal() {
  local cols
  # The braces keep the "cannot open /dev/tty" message inside the redirection
  # that silences it.
  cols=$( { tput cols </dev/tty; } 2>/dev/null )
  [[ -z "$cols" ]] && cols=${COLUMNS:-0}
  (( cols > 0 )) || cols=80
  print -- "$cols"
}

imprimir_linea() {
  # One column short of the full width: a line that fills the terminal exactly
  # triggers the auto-wrap edge case and shows up as two rows.
  local longitud=$(( $(_ancho_terminal) - 1 ))
  (( longitud < 1 )) && longitud=1
  local linea=$(printf "%*s" "$longitud" | tr ' ' '-')
  printf "\e[31m%s\e[0m\n" "$linea"
}

centrar_texto() {
  local texto="$1"
  local ancho_terminal=$(_ancho_terminal)
  local padding=$(( (ancho_terminal - ${#texto}) / 2 ))
  (( padding < 0 )) && padding=0
  printf "\e[31m%*s%s\e[0m\n" "$padding" "" "$texto"
}

# Section banner: line / centred title / line
seccion() {
  imprimir_linea
  centrar_texto "$1"
  imprimir_linea
}
