# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew prefix, resolved without shelling out to `brew` (which is slow and
# is not on PATH yet at this point).
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX=/opt/homebrew          # Apple Silicon
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX=/usr/local             # Intel Macs
else
  BREW_PREFIX=""
fi
[[ -n "$BREW_PREFIX" ]] && eval "$("$BREW_PREFIX/bin/brew" shellenv)"

for _p10k in "${BREW_PREFIX:+$BREW_PREFIX/share/powerlevel10k}" \
             /usr/share/powerlevel10k /usr/bin/powerlevel10k "$HOME/powerlevel10k"; do
  [[ -n "$_p10k" && -r "$_p10k/powerlevel10k.zsh-theme" ]] &&
    source "$_p10k/powerlevel10k.zsh-theme" && break
done
unset _p10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#------------------------------------------------------------------------------
# PATH, history and shell options
#------------------------------------------------------------------------------

export TERM=xterm-256color
export _JAVA_AWT_WM_NONREPARENTING=1   # fix Java AWT under tiling WMs

typeset -U path PATH                   # keep PATH free of duplicates
path=("$HOME/.local/bin" /usr/local/bin $path)
export PATH

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------

alias icat="echo; kitty +kitten icat --align center"
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias lt='lsd --tree --depth=2 --group-dirs=first'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# bat is called batcat on Debian/Ubuntu when installed from the repos
if (( $+commands[bat] )); then
  alias cat='bat'
  alias catnl='bat --paging=never'
elif (( $+commands[batcat] )); then
  alias cat='batcat'
  alias catnl='batcat --paging=never'
fi
alias cant='/bin/cat'

# Copy stdin to the clipboard, whichever clipboard this machine has
if (( $+commands[pbcopy] )); then
  alias ccc="sed 's/ *$//' | pbcopy"
elif (( $+commands[xclip] )); then
  alias ccc="sed 's/ *$//' | xclip -sel clip"
elif (( $+commands[wl-copy] )); then
  alias ccc="sed 's/ *$//' | wl-copy"
fi

(( $+commands[htop] )) && alias top='htop'
alias egrep='command grep -E --color=always'
alias vi='nvim'
alias k='kubectl'
alias d='docker'
alias dc='docker compose'
alias df='duf'
alias ..='cd ..'
alias ...='cd ../..'

(( $+commands[rg] ))    && alias grep='rg'
(( $+commands[dog] ))   && alias dig='dog'
(( $+commands[boxes] )) && alias boxcc='boxes -d shell'
if (( $+commands[ratbagctl] )); then
  alias g502='ratbagctl bellowing-paca'
  alias g915='ratbagctl hollering-marmot'
fi

# cpbar - cp/mv/rm with progress bars.
# Originals always available as cpo/mvo/rmo; the wrappers are only aliased
# when cpbar is actually installed, so a fresh machine keeps working cp/rm.
alias cpo="/bin/cp"
alias mvo="/bin/mv"
alias rmo="/bin/rm"
if (( $+commands[cpbar] )); then
  alias cp="cpbar cp"
  alias mv="cpbar mv"
  alias rm="cpbar rm"
fi

#------------------------------------------------------------------------------
# Plugins (syntax-highlighting must stay last)
#------------------------------------------------------------------------------

# zsh-sudo and zsh-chuck ship with this repo; autosuggestions and
# syntax-highlighting come from the distribution or from Homebrew.
ZSH_PLUGIN_DIRS=(/usr/share/zsh/plugins "$HOME/.local/share/zsh/plugins")
for _name in zsh-autosuggestions/zsh-autosuggestions.zsh \
             zsh-sudo/sudo.plugin.zsh \
             zsh-chuck/chucknorris.plugin.zsh \
             zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  for _dir in "${ZSH_PLUGIN_DIRS[@]}"; do
    [[ -r "$_dir/$_name" ]] && { source "$_dir/$_name"; break }
  done
done
# Homebrew keeps them one level up, without the plugin-name directory
if [[ -n "$BREW_PREFIX" ]]; then
  for _plugin in "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
                 "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [[ -r "$_plugin" ]] && source "$_plugin"
  done
fi
unset _name _dir _plugin

#------------------------------------------------------------------------------
# Own functions (installed from the repo into ~/.config/zsh/functions)
#   ui.zsh         imprimir_linea / centrar_texto / seccion
#   actualizar.zsh actualizar
#   tools.zsh      ntfy, mkt, checkip, extractPorts, ssht, sshta
#------------------------------------------------------------------------------

ZSH_FUNCTIONS_DIR="${ZSH_FUNCTIONS_DIR:-$HOME/.config/zsh/functions}"
if [[ -d "$ZSH_FUNCTIONS_DIR" ]]; then
  for _fn in "$ZSH_FUNCTIONS_DIR"/*.zsh(N); do
    source "$_fn"
  done
  unset _fn
fi

#------------------------------------------------------------------------------
# Completion
#------------------------------------------------------------------------------

autoload -Uz compinit
# Rebuild the completion dump once a day instead of on every shell start
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
# dircolors is GNU-only; macOS gets it from coreutils as gdircolors
if (( $+commands[dircolors] )); then
  eval "$(dircolors -b)"
elif (( $+commands[gdircolors] )); then
  eval "$(gdircolors -b)"
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS:-}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

#------------------------------------------------------------------------------
# BindKeys
#------------------------------------------------------------------------------

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

#------------------------------------------------------------------------------
# Tool integrations
#------------------------------------------------------------------------------

# fzf: modern releases ship the shell integration themselves
if (( $+commands[fzf] )); then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
  else
    # fzf < 0.48 (Ubuntu 22.04/24.04): the distro ships the scripts separately
    for _f in /usr/share/doc/fzf/examples/key-bindings.zsh \
              /usr/share/doc/fzf/examples/completion.zsh \
              /usr/share/fzf/key-bindings.zsh /usr/share/fzf/completion.zsh; do
      [[ -r "$_f" ]] && source "$_f"
    done
    unset _f
  fi
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
  (( $+commands[fd] )) && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# zoxide: smarter cd (z <dir>, zi for the interactive picker)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# atuin: searchable, syncable shell history (ctrl-r)
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# kubectl completion
(( $+commands[kubectl] )) && source <(kubectl completion zsh)

# gh completion
(( $+commands[gh] )) && eval "$(gh completion -s zsh)"
