#!/usr/bin/env bash

set -euo pipefail

BRANCH="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-${CI_COMMIT_BRANCH:-}}"

echo "============================================"
echo "Branch validation"
echo "============================================"
echo
echo "Branch: $BRANCH"
echo

if [[ "$BRANCH" == "main" ]]; then
    echo "✓ main"
    exit 0
fi

if [[ "$BRANCH" =~ ^(feat|fix|refactor|chore|docs|test|ci|build|perf)/[a-z0-9][a-z0-9._-]*$ ]]; then
    echo "✓ Valid branch name: $BRANCH"
    exit 0
fi

echo "❌ Invalid branch name: $BRANCH"
echo
echo "Allowed prefixes:"
echo "  feat/*"
echo "  fix/*"
echo "  refactor/*"
echo "  chore/*"
echo "  docs/*"
echo "  test/*"
echo "  ci/*"
echo "  build/*"
echo "  perf/*"
echo
echo "Examples:"
echo "  feat/niri-config"
echo "  fix/dms-launcher"
echo "  refactor/home-manager"
echo "  chore/hooks"
echo "  docs/readme"
echo "  ci/gitlab"

exit 1
