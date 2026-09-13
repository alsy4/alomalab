# Implementation log

[2026-09-13 08:40 UTC] - Repaired Archify setup in the documentation workflow

Commit `222a1f6` changes the Archify installation step to run from the GitHub
Actions runner's temporary directory and install the skill globally. The
verification step now invokes the installed executable at
`$HOME/.agents/skills/archify/bin/archify.mjs`. This prevents the workflow from
looking for a repository-local skill directory after installing the global
copy.

[2026-09-13 07:15 UTC] - Added Syncthing provisioning for Debian LXC hosts

Commit `b34cf31` added `ansible/playbooks/nas/setup-syncthing.yml`. The
playbook installs Syncthing on every host in the `debian_lxc` inventory group,
creates the `syncthing` system account and service home at
`/var/lib/syncthing`, enables `syncthing@syncthing.service`, and checks its local
administration interface on port `8384`. Device pairing and folder selection
remain an operational step after provisioning because the playbook does not
store device IDs or folder paths.

[2026-09-13 05:42 UTC] - Configured documentation pull-request authentication

Commit `c400e45` changed the documentation workflow to use the
`DOCUMENTATION_PR_TOKEN` repository secret when it runs `gh pr create`. It now
stops with a clear error if the secret is missing. This allows the workflow to
create documentation pull requests when the repository setting prevents the
built-in GitHub token from doing so.
