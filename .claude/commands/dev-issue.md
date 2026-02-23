# Dev Issue

Create a correctly-named branch for a GitHub issue, then implement all the work described in that issue.

## Usage

```
/dev-issue <issue-number>
```

## What it does

1. Fetches the issue from GitHub
2. Derives the correct branch name from the issue type and title (`feat/issue-{n}-{slug}` or `fix/issue-{n}-{slug}`)
3. Creates and switches to that branch
4. Reads the issue's Work and Acceptance Criteria
5. Implements everything, following HoosierCiv conventions
6. Runs `flutter analyze` and `dart format .`
7. Reports what was done and what's next

$ARGUMENTS
