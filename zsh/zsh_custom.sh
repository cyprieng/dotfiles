DISABLE_AUTO_TITLE="true"

preexec() {
    local action="$1"
    echo -ne "\033]0;$action - ${PWD##*/}\a"
}
