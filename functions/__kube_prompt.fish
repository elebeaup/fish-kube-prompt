# Inspired from:
# https://github.com/jonmosco/kube-ps1
# https://github.com/Ladicle/fish-kubectl-prompt

function __kube_ps_update_cache
  function __kube_ps_cache_context
    set -l ctx (kubectl config current-context 2>/dev/null)
    if test $status -eq 0
      set -g __kube_ps_context "$ctx"
    else
      set -g __kube_ps_context "n/a"
    end
  end

  function __kube_ps_cache_namespace
    set -l ns (kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)
    if test -n "$ns"
      set -g __kube_ps_namespace "$ns"
    else
      set -g __kube_ps_namespace "default"
    end
  end

  set -l kubeconfig "$KUBECONFIG"
  if test -z "$kubeconfig"
    set kubeconfig "$HOME/.kube/config"
  end

  if test "$kubeconfig" != "$__kube_ps_kubeconfig"
    __kube_ps_cache_context
    __kube_ps_cache_namespace
    set -g __kube_ps_kubeconfig "$kubeconfig"
    set -g __kube_ps_timestamp (date +%s)
    return
  end

  for conf in (string split ':' "$kubeconfig")
    if test -r "$conf"
      set -l mtime
      if test (stat -c "%s" /dev/null 2>/dev/null) -eq 0
        # GNU stat
        set mtime (stat -L -c "%Y" "$conf")
      else
        # BSD stat
        set mtime (stat -L -f "%m" "$conf")
      end

      if test -z "$__kube_ps_timestamp"; or test "$mtime" -gt "$__kube_ps_timestamp"
        __kube_ps_cache_context
        __kube_ps_cache_namespace
        set -g __kube_ps_kubeconfig "$kubeconfig"
        set -g __kube_ps_timestamp (date +%s)
        return
      end
    end
  end
end

function __kube_prompt
  if test -z "$__kube_ps_enabled"; or test $__kube_ps_enabled -ne 1
    return
  end

  __kube_ps_update_cache
  echo -n -s " (⎈ $__kube_ps_context|$__kube_ps_namespace)"
end
