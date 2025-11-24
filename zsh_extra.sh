# compinit
# 色の設定
export LSCOLORS=Exfxcxdxbxegedabagacad

# 補完時の色設定
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# キャッシュの利用による補完の高速化
zstyle ':completion::complete:*' use-cache true

# 補完候補に色つける
autoload -U colors ; colors ; zstyle ':completion:*' list-colors "${LS_COLORS}"
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# 大文字・小文字を区別しない(大文字を入力した場合は区別する)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完の選択を楽にする
zstyle ':completion:*' menu select=1

# 補完候補をできるだけ詰めて表示する
setopt list_packed
# current directory内でcdなしで移動する
setopt auto_cd
# 他のターミナルとヒストリーを共有
setopt share_history
setopt nomatch
# ヒストリーに重複を表示しない
setopt histignorealldups

HISTFILE=~/.zsh_history
HISTSIZE=10000000000000000
SAVEHIST=10000000000000000

# コマンドミスを修正
setopt correct
setopt correct_all

PROMPT='%F{green}%n%f %F{blue}%2~%f %% '
autoload -Uz colors && colors

function mkdirYYYYMMDD() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: mkdirYYYYMMDD <directory_name>"
    return 1
  fi
  local date=$(date +%Y%m%d)
  mkdir "${date}_$1"
}

if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi
# fh - repeat history
fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}
# fshow - git commit browser
fgitshow() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
        fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
            --bind "ctrl-m:execute:
                (grep -o '[a-f0--9]\{7\}' | head -1 | 
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}
function cdi() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@"
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p -A | grep '/$' | sed 's;/;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p -A -FG "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &>/dev/null
    done
}

function git-switch() {
    target_br=(
        git branch -a | grep -v "HEAD" |
            fzf --exit-0 --layout=reverse --info=hidden --no-multi --preview-window="right,65%" --prompt="CHECKOUT BRANCH > " --preview="echo {} | tr -d ' *' | xargs git log --graph --decorate --abbrev-commit --name-status --color=always"
    )
    if [ -n "$target_br" ]; then
        git switch "$target_br" &>/dev/null
    fi
}
_diff_file_list() {
    git diff --name-status --relative |
        while read -r f p; do
            case "$f" in
            A) c=$'\e[32m' ;; 
            D) c=$'\e[31m' ;; 
            *) c='' ;; 
            esac
            printf '%s\t%b\n' "$p" "${c}${p}\e[0m"
        done
}

_PREVIEW='{ 
  git diff --color=always --relative -- {1}; 
  git diff --cached --color=always --relative -- {1}; 
} | delta --paging=never --side-by-side --line-numbers || true'

_opts=(
    --ansi
    --delimiter=$'\t'
    --with-nth=2..
    --prompt='diff> '
    --layout=reverse
    --cycle --no-sort
    --preview="$_PREVIEW"
    --preview-window='right:80%'
    --bind='enter:toggle-preview'
    --bind='s:execute:git add -p -- {1} >/dev/tty; reload(_diff_file_list)'
    --bind='r:execute:git restore -p -- {1} >/dev/tty; reload(_diff_file_list)'
    --bind='ctrl-c:abort'
)

git_diff() { _diff_file_list | fzf "${_opts[@]}"; }
  
