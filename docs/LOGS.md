# Implementation log

[2026-09-13 05:42 UTC] - Configured documentation pull-request authentication

Commit `c400e45` changed the documentation workflow to use the
`DOCUMENTATION_PR_TOKEN` repository secret when it runs `gh pr create`. It now
stops with a clear error if the secret is missing. This allows the workflow to
create documentation pull requests when the repository setting prevents the
built-in GitHub token from doing so.
