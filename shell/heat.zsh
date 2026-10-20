# Heat is sent as the cursor's red channel using OSC 12. No key logging.
zmodload zsh/datetime
zmodload zsh/mathfunc
autoload -Uz add-zle-hook-widget add-zsh-hook
typeset -gF _matrix_heat=0 _matrix_last=$EPOCHREALTIME
typeset -g _matrix_buffer=''
typeset -gi _matrix_cursor=-1
typeset -gi _matrix_enabled=1
typeset -gi _matrix_effect_flags=15
# Effect state is shared by terminal so helper commands can update the shader.
typeset -g _matrix_bin=${${(%):-%x}:A:h:h}/bin
typeset -g _matrix_state=${XDG_STATE_HOME:-$HOME/.local/state}/matrix-power/${TTY:t}.power-off
[[ -n $TTY ]] && rm -f -- $_matrix_state
function _matrix_update_effect_flags() {
  local state_prefix=${XDG_STATE_HOME:-$HOME/.local/state}/matrix-power/${TTY:t}
  local -i flags=0
  [[ ! -e $state_prefix.background-off ]] && (( flags |= 1 ))
  [[ ! -e $state_prefix.idle-off ]] && (( flags |= 2 ))
  [[ ! -e $state_prefix.shake-off ]] && (( flags |= 4 ))
  [[ ! -e $state_prefix.sparks-off ]] && (( flags |= 8 ))
  _matrix_effect_flags=$flags
  return 0
}
function _matrix_redraw() {
  (( _matrix_enabled )) || return
  [[ $BUFFER == $_matrix_buffer && $CURSOR == $_matrix_cursor ]] && return
  local -F now=$EPOCHREALTIME dt
  dt=$(( now - _matrix_last ))
  (( _matrix_heat = _matrix_heat * exp(-dt / 3.5) + 0.14 ))
  (( _matrix_heat > 1 )) && _matrix_heat=1
  _matrix_last=$now
  _matrix_buffer=$BUFFER
  _matrix_cursor=$CURSOR
  local -i red=$(( int(_matrix_heat * 255) ))
  _matrix_update_effect_flags
  printf '\e]12;#%02xff%02x\a' $red $_matrix_effect_flags >&2
}
function _matrix_reset() {
  _matrix_heat=0
  _matrix_buffer=''
  _matrix_cursor=-1
  [[ -e $_matrix_state ]] && _matrix_enabled=0 || _matrix_enabled=1
  _matrix_update_effect_flags
  if (( _matrix_enabled )); then
    printf '\e]12;#00ff%02x\a' $_matrix_effect_flags >&2
  else
    printf '\e]12;#00ff00\a' >&2
  fi
}
function _matrix_toggle() {
  "$_matrix_bin/matrix-toggle" $TTY >/dev/null
  _matrix_reset
  zle -R
}
zle -N _matrix_toggle
bindkey '\e[99~' _matrix_toggle
function _matrix_background_toggle() {
  "$_matrix_bin/matrix-background-toggle" $TTY >/dev/null
  _matrix_reset
  zle -R
}
function _matrix_idle_toggle() {
  "$_matrix_bin/matrix-idle-toggle" $TTY >/dev/null
  _matrix_reset
  zle -R
}
function _matrix_shake_toggle() {
  "$_matrix_bin/matrix-shake-toggle" $TTY >/dev/null
  _matrix_reset
  zle -R
}
function _matrix_sparks_toggle() {
  "$_matrix_bin/matrix-sparks-toggle" $TTY >/dev/null
  _matrix_reset
  zle -R
}
zle -N _matrix_background_toggle
zle -N _matrix_idle_toggle
zle -N _matrix_shake_toggle
zle -N _matrix_sparks_toggle
bindkey '\e[98~' _matrix_background_toggle
bindkey '\e[100~' _matrix_idle_toggle
bindkey '\e[101~' _matrix_shake_toggle
bindkey '\e[102~' _matrix_sparks_toggle
add-zle-hook-widget line-pre-redraw _matrix_redraw
add-zsh-hook preexec _matrix_reset
add-zsh-hook precmd _matrix_reset
