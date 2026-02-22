#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Allow main and CI/bot contexts
if echo "$BRANCH" | grep -qE '^(main|HEAD)$'; then
  exit 0
fi

# feat/issue-{number}-{description} or fix/issue-{number}-{description}
if echo "$BRANCH" | grep -qE '^(feat|fix)/issue-[0-9]+-[a-z0-9-]+$'; then
  exit 0
fi

# chore/{description} or docs/{description}
if echo "$BRANCH" | grep -qE '^(chore|docs)/[a-z0-9-]+$'; then
  exit 0
fi

echo ""
echo "✗ Branch name '$BRANCH' does not follow the required convention."
echo ""
echo "  Valid patterns:"
echo "    feat/issue-{number}-{short-description}   e.g. feat/issue-2-profiles-table"
echo "    fix/issue-{number}-{short-description}    e.g. fix/issue-9-router-redirect"
echo "    chore/{short-description}                 e.g. chore/upgrade-flutter-deps"
echo "    docs/{short-description}                  e.g. docs/update-setup-guide"
echo ""
echo "  Rename your branch and retry:"
echo "    git branch -m $BRANCH feat/issue-{number}-{description}"
echo ""
echo "  See CONTRIBUTING.md for the full branching convention."
exit 1
