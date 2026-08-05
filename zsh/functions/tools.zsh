# Personal helper functions.

# Push a notification to the home ntfy server
function ntfy() {
  local msg=$1
  local tit=${2:-"Casa"}
  curl -H "Title:$tit" -d "$msg" https://ntfy.perezandrade.com/Home
}

# Scaffold a pentest working directory
function mkt() {
  mkdir -p {content,exploits,nmap}
}

# Resolve a name to an IP (or an IP to its FQDN) through the jump host
function checkip() {
  if [[ ${1:0:5} =~ ^[[:alpha:]]+$ ]]; then
    imprimir_linea
    ssh carlos@10.9.71.4 "ping $1 -c 1" | awk '/from/ {ip = substr($5, 1, length($5)-1); printf "The IP of %s is %s\n", $4, ip}'
    imprimir_linea
  elif [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    imprimir_linea
    ssh carlos@10.9.71.4 "nslookup $1" | awk '/name/{printf "The FQDN of %s is %s\n", $2, $4}'
    imprimir_linea
  else
    echo "'$1' has to be a valid IPv4 or a valid name."
    return 1
  fi
}

# Extract open ports and the target IP out of an nmap report
function extractPorts() {
  local ports ip_address
  ports="$(grep -oP '\d{1,5}/open' "$1" | awk -F/ '{print $1}' | xargs | tr ' ' ',')"
  ip_address="$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$1" | sort -u | head -n 1)"
  echo -e "\n[*] Extracting information...\n"
  echo -e "\t[*] IP Address: $ip_address"
  echo -e "\t[*] Open ports: $ports\n"
  if (( $+commands[xclip] )); then
    echo -n "$ports" | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n"
  fi
}

# ssh Trinseo
function ssht() {
  if [ "$(hostname)" = "Vader" ]; then
    kitty @ launch --type=tab --tab-title "$1" kitty +kitten ssh -i ~/.ssh/teeupinfra -At -J carlos@10.9.71.4 d2t684526@"$1"
    kitty @ send-text --match-tab=title:$1 'if egrep "export TERM=xterm-256color" .bashrc ; then clear ; else echo "export TERM=xterm-256color" >> .bashrc ; fi' \\x0d
    kitty @ send-text --match-tab=title:$1 export TERM=xterm-256color \\x0d clear \\x0d
  elif [ "$(hostname)" = "teeupinfubuas01" ]; then
    ssh d2t684526@"$1"
  fi
}

# ssh Trinseo aztrinseoadmin
function sshta() {
  if [ "$(hostname)" = "Vader" ]; then
    kitty @ launch --type=tab --tab-title "$1" kitty +kitten ssh -i ~/.ssh/aztrinseoadmin -At -J carlos@10.9.71.4 aztrinseoadmin@"$1"
    kitty @ send-text --match-tab=title:$1 'if egrep "export TERM=xterm-256color" .bashrc ; then clear ; else echo "export TERM=xterm-256color" >> .bashrc ; fi' \\x0d
    kitty @ send-text --match-tab=title:$1 export TERM=xterm-256color \\x0d clear \\x0d
  elif [ "$(hostname)" = "teeupinfubuas01" ]; then
    ssh -i ~/.ssh/aztrinseoadmin aztrinseoadmin@"$1"
  fi
}
