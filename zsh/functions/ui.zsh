# Shared output helpers used by the other function files.

imprimir_linea() {
  local longitud=$(tput cols)
  local linea=$(printf "%*s" "$longitud" | tr ' ' '-')
  local rojo=$(tput setaf 1)
  local reset=$(tput sgr0)
  printf "%s\n" "${rojo}${linea}${reset}"
}

centrar_texto() {
  local texto="$1"
  local ancho_terminal=$(tput cols)
  local padding=$(( (ancho_terminal - ${#texto}) / 2 ))
  printf "\e[31m%*s%s%*s\e[0m\n" "$padding" "" "$texto" "$padding" ""
}

# Section banner: line / centred title / line
seccion() {
  imprimir_linea
  centrar_texto "$1"
  imprimir_linea
}
