# hookbook

Hookbook provides a way to register multiple "DEBUG" hooks in bash, and their equivalents in zsh and
fish.

The main benefit of hookbook is that the API is unified across all three shells, while enabling
registration of multiple hooks in bash, which is otherwise challenging since only one function can
be registered to the `DEBUG` trap.

## Usage

Call `hookbook_add_hook` with a function name. This function will be called with one parameter,
indicating the shell and which hook was fired:

* `bash-debug`: The bash ["DEBUG" trap](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html)
* `bash-prompt`: Called from [`PROMPT_COMMAND`](http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x264.html)
* `zsh-preexec`: [`preexec_functions`](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions)
* `zsh-precmd`: [`precmd_functions`](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions)
* `zsh-chpwd`: [`chpwd_functions`](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions)
* `fish-chpwd`: Fired [when `$PWD` changes](https://github.com/fish-shell/fish-shell/blob/master/doc_src/function.txt#L24)
* `fish-prompt`: Fired [when the prompt is generated](https://github.com/fish-shell/fish-shell/blob/master/doc_src/function.txt#L22)

You may want to add some heuristics to filter certain events depending on your use-case, as the bash
`DEBUG` trap is a rather chatty hook.

```bash
source hookbook.sh
myhook() { echo $1; }
hookbook_add_hook myhook
```

In bash, this will immediately print:

```
bash-debug
bash-debug
bash-prompt
bash-debug
bash-debug
bash-5.0$
```

Unfortunately, we haven't found a way to implement a script that can be understood by all three of
bash, zsh, and fish, so for fish, you'll have to `source hookbook.fish` instead of `source hookbook.sh`.

Depending on your use-case, it likely makes sense to copy both of these files into your application
and source them as appropriately into the user's session. If you want to source `hookbook.sh` from
the same directory as a script that may be loaded by either bash or zsh:

```bash
case "$(basename "$(\ps -p $$ | \awk 'NR > 1 { sub(/^-/, "", $4); print $4 }')")" in
  zsh)
    source "$(\dirname "$0:A")/hookbook.sh"
    ;;
  bash)
    source "$(builtin cd "$(\dirname "${BASH_SOURCE[0]}")" && \pwd)/hookbook.sh"
    ;;
  *)
    >&2 echo "shadowenv is not compatible with your shell (bash, zsh, and fish are supported)"
    return 1
    ;;
esac
```

...and an equivalent for fish:

```fish
set __this_source_dir (pushd (dirname (dirname (status -f))) ; pwd ; popd)
source $__this_source_dir/hookbook.fish
set -e __this_source_dir
```

For an actual example of usage, see
[Shadowenv](https://github.com/Shopify/shadowenv).
