
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
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
#alias actualizar='sudo apt update && sudo apt -y full-upgrade && sudo snap refresh && sudo apt -y autoremove || sudo apt --fix-broken install'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias cat='/bin/bat'
alias cant='/bin/cat'
alias catnl='/bin/bat --paging=never'
alias ccc="sed 's/ *$//' | xclip -sel clip"
alias top="/usr/bin/htop"
alias egrep='/usr/bin/egrep --color=always'
alias grep='/usr/bin/grep --color=always'
alias g915='ratbagctl bellowing-paca'
alias vi='/usr/bin/nvim'
alias k='kubectl'


# Actualizar function
function actualizar(){
	clear
        echo "$(tput setaf 5)---------------------------------------------------"
	echo "Updating repositories"
        echo "---------------------------------------------------$(tput sgr 0)"
	sudo apt update
        echo "$(tput setaf 5)---------------------------------------------------"
	echo "Doing a full package upgrade"
        echo "---------------------------------------------------$(tput sgr 0)"
	sudo apt -y full-upgrade
        echo "$(tput setaf 5)---------------------------------------------------"
	echo "Updating SNAP installs"
        echo "---------------------------------------------------$(tput sgr 0)"
	sudo snap refresh
        echo "$(tput setaf 5)---------------------------------------------------"
	echo "Removing old packages and/or fixing broken packages"
        echo "---------------------------------------------------$(tput sgr 0)"
	sudo apt -y autoremove || sudo apt --fix-broken install
}

# Fix the Java Problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Plugins
#source /usr/share/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/zsh-plugins/sudo.plugin.zsh
#source /usr/share/zsh-plugins/tmux.plugin.zsh

# MKT Function
function mkt(){
	mkdir {content,exploits,nmap,scripts}
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
#kitty +kitten ssh -i ~/.ssh/teeupinfra -At -J carlos@10.9.71.4 d2t684526@"$1"
tmux rename-window -t${TMUX_PANE} "$1"
ssh -i ~/.ssh/teeupinfra -At -J carlos@10.9.71.4 d2t684526@"$1"
elif [ $(hostname) = "teeupinfubuas01" ]; then
ssh d2t684526@"$1"
fi
}

# ssh Trinseo aztrinseoadmin
function sshta(){
if [ $(hostname) = "Vader" ]; then
#kitty +kitten ssh -i ~/.ssh/aztrinseoadmin -At -J carlos@10.9.71.4 aztrinseoadmin@"$1"
ssh -i ~/.ssh/aztrinseoadmin -At -J carlos@10.9.71.4 aztrinseoadmin@"$1"
elif [ $(hostname) = "teeupinfubuas01" ]; then
ssh -i ~/.ssh/aztrinseoadmin aztrinseoadmin@"$1"
fi
}

# Set title windows
#settitle() {
#    printf "\033k$1\033\\"
#}


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
