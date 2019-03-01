# hookbook

Hookbook provides a way to register multiple "DEBUG" hooks in bash, and their equivalents in zsh.

The main benefit of hookbook is to be able to treat bash as if it were zsh as far as registering
these hooks goes. The hook you register will be called with either `precmd` or `preexec`, and will
be run only once for each process started as well as once for each command prompt generated. A lot
of complexity is involved in making the bash `DEBUG` trap behave in this way.

## Usage

Call `hookbook_add_hook` with a function name. This function will be called with one parameter:

* `precmd`: [`precmd_functions`](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions) in `zsh`;
  [`PROMPT_COMMAND`](http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x264.html) in `bash`.

* `preexec`: [`preexec_functions`](http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions) in `zsh`;
  simulated using the bash ["DEBUG" trap](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html).

`precmd` runs immediately before generating your command prompt, and `preexec` runs immediately
before forking a process based on the entered command. For example, take this script:

```bash
source hookbook.sh
myhook() { echo $1; }
hookbook_add_hook myhook
```

In bash, this will immediately print:

```
precmd
bash-5.0$
```

If you run a command:

```
bash-5.0$ echo 'two commands' | wc -c
preexec
preexec
      13
precmd
```

The output is *almost* identical in zsh, except that `preexec` is only fired once for a whole
process pipeline, rather than for each process in the pipeline:

```
zsh% echo 'two commands' | wc -c
preexec
      13
precmd
```

Hookbook used to support `fish` as well, but we found that this was not useful: it's very easy to
[bind a fish function to an event](https://fishshell.com/docs/current/#event), and nearly impossible
to write a script that doesn't require completely different implementations in fish and bash/zsh
anyway.

Depending on your use-case, it likely makes sense to copy `hookbook.sh` into your application and
source it into the user's session. If you want to source `hookbook.sh` from the same directory as
a script that may be loaded by either bash or zsh:

```bash
case "$(basename "$(\ps -p $$ | \awk 'NR > 1 { sub(/^-/, "", $4); print $4 }')")" in
  zsh)
    source "$(\dirname "$0:A")/hookbook.sh"
    ;;
  bash)
    source "$(builtin cd "$(\dirname "${BASH_SOURCE[0]}")" && \pwd)/hookbook.sh"
    ;;
  *)
    >&2 echo "shadowenv is not compatible with your shell (only bash and zsh are supported)"
    return 1
    ;;
esac
```

Alternatively, you may prefer to simply inline `hookbook.sh` into another script.

For an actual example of usage, see
[Shadowenv](https://github.com/Shopify/shadowenv).
