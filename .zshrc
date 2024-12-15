# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/bin/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias icat="echo; kitty +kitten icat --align center"
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias cat='/bin/bat'
alias cant='/bin/cat'
alias catnl='/bin/bat --paging=never'
alias ccc="sed 's/ *$//' | xclip -sel clip"
alias top="/usr/bin/htop"
alias egrep='/usr/bin/egrep --color=always'
alias grep='/usr/bin/grep --color=always'
alias g502='ratbagctl bellowing-paca'
alias g915='ratbagctl hollering-marmot'
alias vi='/usr/bin/nvim'
alias k='kubectl'
alias d='docker'
alias boxcc='boxes -d shell'

# Actualizar function
function actualizar(){
  clear

  # Imprimir la linea
    imprimir_linea() {
      local longitud=$(tput cols)
      local linea=$(printf "%*s" "$longitud" | tr ' ' '-')
      local rojo=$(tput setaf 1)
      local reset=$(tput sgr0)
      printf "%s\n" "${rojo}${linea}${reset}"
    }

  # Función para imprimir texto centrado
    centrar_texto() {
      local texto="$1"
      local ancho_terminal=$(tput cols)
      local padding=$(( (ancho_terminal - ${#texto}) / 2 ))
      printf "\e[31m%*s%s%*s\e[0m\n" "$padding" "" "$texto" "$padding" ""
    }

  imprimir_linea
  centrar_texto "Updating the repositories"
  imprimir_linea
  sudo apt update

  imprimir_linea
  centrar_texto "Doing a full upgrade"
  imprimir_linea
  sudo apt -y full-upgrade
  sudo apt list --upgradable 2>/dev/null | awk -F/ '/upgradable/ {print $1}' | xargs -r sudo apt -y --allow-change-held-packages install

  if command -v snap &> /dev/null; then
    imprimir_linea
    centrar_texto "Updating SNAP Installs"
    imprimir_linea
    sudo snap refresh
  else
    imprimir_linea
    centrar_texto "Snap is not installed"
    imprimir_linea
  fi

  imprimir_linea
  centrar_texto "Removing old packages and/or fixing broken packages"
  imprimir_linea
  sudo apt -y autoremove || sudo apt --fix-broken install && sudo apt -y autoremove

  imprimir_linea
  imprimir_linea

  if [ -f /var/run/reboot-required ]; then
    echo
    centrar_texto "*******************"
    centrar_texto "* Reboot Required *"
    centrar_texto "*******************"
    echo
    read -t 60 -r -p "Do you want to reboot now? (y/n): " choice
    if [[ $choice =~ ^[Yy]$ ]]; then
      sudo reboot now
    elif [[ $choice =~ ^[Nn]$ || -z $choice ]]; then
      echo "Reboot skipped. You can reboot later."
    else
      echo "Invalid choice. Skipping reboot."
    fi
  else
    echo
    centrar_texto "***********************"
    centrar_texto "* Reboot NOT Required *"
    centrar_texto "***********************"
    echo
  fi
}

# Fix the Java Problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh
source /usr/share/zsh/plugins/zsh-chuck/chucknorris.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# NTFY Function
function ntfy() {
  msg=$1
  tit=${2:-"Casa"}
  curl -H "Title:$tit" -d "$msg" https://ntfy.perezandrade.com/Home
}

# MKT Function
function mkt(){
  mkdir {content,exploits,nmap,scripts}
}

function checkip() {
  # Verificar si los primeros 5 caracteres de $1 son alfabéticos
  if [[ ${1:0:5} =~ ^[[:alpha:]]+$ ]]; then
    imprimir_linea
    ssh carlos@10.9.71.4 "ping $1 -c 1" | awk '/from/ {ip = substr($5, 1, length($5)-1); printf "The IP of %s is %s\n", $4, ip}'
    imprimir_linea
  else
    # Verificar si $1 tiene el formato de una dirección IPv4 válida
    if [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      imprimir_linea
      ssh carlos@10.9.71.4 "nslookup $1" | awk '/name/{printf "The FQDN of %s is %s\n", $2, $4}'
      imprimir_linea
    else
      echo "'$1'has to be a valid IPv4 or a valid name."
      return 1
    fi
   return 1
  fi
}

# Extract nmap information
function extractPorts(){
  ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
  ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
  echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
  echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
  echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
  echo $ports | tr -d '\n' | xclip -sel clip
  echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
  cat extractPorts.tmp; rm extractPorts.tmp
}

# ssh Trinseo
function ssht(){
if [ $(hostname) = "Vader" ]; then
kitty @ launch --type=tab --tab-title "$1" kitty +kitten ssh -i ~/.ssh/teeupinfra -At -J carlos@10.9.71.4 d2t684526@"$1"
kitty @ send-text --match-tab=title:$1 'if egrep "export TERM=xterm-256color" .bashrc ; then clear ; else echo "export TERM=xterm-256color" >> .bashrc ; fi' \\x0d
kitty @ send-text --match-tab=title:$1 export TERM=xterm-256color \\x0d clear \\x0d
elif [ $(hostname) = "teeupinfubuas01" ]; then
ssh d2t684526@"$1"
fi
}

# ssh Trinseo aztrinseoadmin
function sshta(){
if [ $(hostname) = "Vader" ]; then
kitty @ launch --type=tab --tab-title "$1" kitty +kitten ssh -i ~/.ssh/aztrinseoadmin -At -J carlos@10.9.71.4 aztrinseoadmin@"$1"
kitty @ send-text --match-tab=title:$1 'if egrep "export TERM=xterm-256color" .bashrc ; else echo "export TERM=xterm-256color" >> .bashrc ; fi' \\x0d
kitty @ send-text --match-tab=title:$1 export TERM=xterm-256color \\x0d clear \\x0d
elif [ $(hostname) = "teeupinfubuas01" ]; then
ssh -i ~/.ssh/aztrinseoadmin aztrinseoadmin@"$1"
fi
}

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
source /usr/bin/powerlevel10k/powerlevel10k.zsh-theme

# BindKeys

case "${TERM}" in
  cons25*|linux) # plain BSD/Linux console
    bindkey "^[[H"    beginning-of-line   # home 
    bindkey "^[[F"    end-of-line         # end  
    bindkey '\e[5~'   delete-char         # delete
    bindkey '[D'      emacs-backward-word # esc left
    bindkey '[C'      emacs-forward-word  # esc right
    ;;
  *rxvt*) # rxvt derivatives
    bindkey "^[[3~"   delete-char         # delete
    bindkey "^[[1;3C" forward-word        # alt right
    bindkey "^[[1;3D" backward-word       # alt left
    bindkey '\eOc'    forward-word        # ctrl right
    bindkey '\eOd'    backward-word       # ctrl left
    # workaround for screen + urxvt
    bindkey '\e[7~'   beginning-of-line   # home
    bindkey '\e[8~'   end-of-line         # end
    bindkey '^[[1~'   beginning-of-line   # home
    bindkey '^[[4~'   end-of-line         # end
    ;;
  *xterm*) # xterm derivatives
    bindkey "^[[H"    beginning-of-line   # home 
    bindkey "^[[F"    end-of-line         # end  
    bindkey "^[[3~"   delete-char         # delete
    bindkey '\e[1;5C' forward-word        # ctrl right
    bindkey '\e[1;5D' backward-word       # ctrl left
    # workaround for screen + xterm
    bindkey '\e[1~'   beginning-of-line   # home
    bindkey '\e[4~'   end-of-line         # end
    ;;
  screen)
    bindkey '^[[1~'   beginning-of-line   # home
    bindkey '^[[4~'   end-of-line         # end
    bindkey '\e[3~'   delete-char         # delete
    bindkey '\eOc'    forward-word        # ctrl right
    bindkey '\eOd'    backward-word       # ctrl left
    bindkey '^[[1;5C' forward-word        # ctrl right
    bindkey '^[[1;5D' backward-word       # ctrl left
    ;;
esac

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#source <(kubectl completion zsh)
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
export TERM=xterm-256color