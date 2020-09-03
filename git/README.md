# git in k8s

A cgit & git ssh server that runs in Kubernetes. New repositories can be created
by sshing into the git-ssh instance and running `create pub/my-git-repo.git`.

Any repositories stored within `pub` are shown in cgit. A `private` volume is
also provided which isn't mounted into cgit.

A list of commands that can be run on git-ssh can be found in [git-shell-commands.nix](git-shell-commands.nix).

cgit is running behind caddy using [caddy-cgi](https://github.com/aksdb/caddy-cgi), and
syntax highlights using [syntect](https://github.com/w4/syntect-cgit).
