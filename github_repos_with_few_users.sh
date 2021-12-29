#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-29 18:08:23 +0000 (Wed, 29 Dec 2021)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/git.sh
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds GitHub repo with few users, which in Enterprises is a sign that a user has created a repo without assigning team privileges

The default user threshold if not given is 1

Output format (timestamped progress is sent to stderr, results are sent to stdout):

2021-12-29 18:09:57  checking repo: <org>/<repo1>
2021-12-29 18:09:57  checking repo: <org>/<repo2>
2021-12-29 18:09:58  checking repo: <org>/<repo3>
<org>/<repo3>    <user>     <permission>
<org>/<repo3>    <user2>    <permission>
2021-12-29 18:10:00  checking repo: <org>/<repo4>
...
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<minimum_number_of_users>]"

help_usage "$@"

minimum_number_of_users="${1:-1}"

if ! is_int "$minimum_number_of_users"; then
    usage "invalid number of users argument '$minimum_number_of_users', must be an integer"
fi

user="${GITHUB_USER:-$(get_github_user)}"
user_or_org="${GITHUB_ORGANIZATION:-$user}"

get_github_repos "$user_or_org" "${GITHUB_ORGANIZATION:-}" |
while read -r repo; do
    timestamp "checking repo: $user_or_org/$repo"
    "$srcdir/github_api.sh" "/repos/$user_or_org/$repo/collaborators" |
     jq -r "
        select(length <= $minimum_number_of_users) |
        .[] |
        [\"$repo\", .login, .role_name] |
        @tsv" |
     column -t
done