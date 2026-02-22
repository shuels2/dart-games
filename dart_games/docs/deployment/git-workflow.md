# Git Workflow

## Push Permission Required

**NEVER push to the master branch without explicit permission from the user.**

This is a critical rule to ensure controlled deployments and prevent accidental releases.

## Before Pushing to Remote

Before pushing any commits to the remote repository:

1. **Ask the user for permission to push**
2. **Wait for explicit approval**
3. **Only push after receiving confirmation**

## Commands That Require Permission

The following git operations require explicit user permission:

```bash
git push origin master
git push origin main
git push
git push --force
git push --force-with-lease
# Any other push command
```

## Example Communication

**Bad approach:**
```
Code is ready. Pushing to master now.
```

**Good approach:**
```
I've completed the changes and all tests are passing.
May I push these commits to the remote master branch?

Commits to push:
- [commit hash] [commit message]
- [commit hash] [commit message]
```

## Typical Workflow

### 1. Make Changes Locally
```bash
# Make code changes
# ...

# Stage changes
git add [files]

# Commit changes
git commit -m "Description of changes"
```

### 2. Run Tests
```bash
# MANDATORY: Run all non-UI tests
flutter test

# Optional: Ask user if they want UI automation tests
# If yes:
./run_ui_tests.bat
```

### 3. Verify All Tests Pass
- All 352 non-UI tests must pass (100% pass rate required)
- If running UI tests, all 128 must pass

### 4. Ask Permission to Push
```
All tests are passing. May I push to remote?

Changes:
- [Summary of what changed]

Commits:
- [commit 1]
- [commit 2]
```

### 5. Wait for User Approval

Do NOT proceed until user explicitly says:
- "yes"
- "go ahead"
- "push it"
- "approve"
- or similar explicit approval

### 6. Push to Remote
```bash
git push origin [branch-name]
```

## Branch Protection

### Master/Main Branch
- **Always** requires permission to push
- This is the production branch
- All tests must pass before pushing

### Feature Branches
- May push without permission if user has previously approved
- Use for work-in-progress
- Still run tests before pushing

### Test Branches
- May push without permission if user has previously approved
- Use for experimental changes
- Tests should still pass

## Exception: Continuous Work Session

If the user says something like:

> "You have permission to push all commits during this session"

Then you may push without asking each time, but:
- Still run tests before each push
- Still confirm tests pass
- Stop pushing if any tests fail

## Multi-Commit Pushes

When pushing multiple commits:

```
May I push the following 3 commits to remote?

1. [hash] Add new feature X
2. [hash] Update tests for feature X
3. [hash] Update documentation

All 352 tests passing.
```

## Force Push

**Force pushes require EXTRA permission and justification.**

```
I need to force push to fix [issue].

This will overwrite remote history. Are you sure you want to proceed?

Command: git push --force origin [branch]
```

Only force push if:
- User explicitly approves
- There's a clear reason (e.g., fixing accidentally pushed secrets)
- You understand the consequences

## Pull Before Push

Always pull before pushing to avoid conflicts:

```bash
git pull origin [branch-name]
# Resolve any conflicts
git push origin [branch-name]
```

## Commit Message Guidelines

Use clear, descriptive commit messages:

```bash
git commit -m "$(cat <<'EOF'
Brief description of change (imperative mood)

- Detail 1
- Detail 2
- Detail 3

Fixes #[issue-number] (if applicable)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### Good Commit Messages
✅ "Add hero bonus feature to Target Tag"
✅ "Fix dartboard segment calculation bug"
✅ "Update test descriptions for accuracy"

### Bad Commit Messages
❌ "Changes"
❌ "Fix stuff"
❌ "WIP"

## Standard Co-Author Tag

All commits should include:

```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

This acknowledges AI assistance in the commit.

## Branching Strategy

### Current Branches
- `master` / `main` - Production code
- `test_modernization` - Test refactoring work
- [Other feature branches as needed]

### Creating Feature Branches
```bash
git checkout -b feature/[feature-name]
```

### Merging Branches
Always ask permission before merging to master:

```bash
# Switch to master
git checkout master

# Merge feature branch
git merge feature/[feature-name]

# Push (with permission)
git push origin master
```

## If Push Fails

If a push fails:

1. **Don't force push without permission**
2. **Pull the latest changes:**
   ```bash
   git pull origin [branch-name]
   ```
3. **Resolve conflicts if any**
4. **Re-run tests**
5. **Ask permission to push again**

## Common Push Scenarios

### Scenario 1: Normal Feature Complete
```
User: "commit and push to remote"

Claude:
1. Stages files
2. Creates commit
3. Pushes to remote (permission given by "push to remote")
```

### Scenario 2: Tests Failed
```
User: "commit and push to remote"

Claude:
1. Stages files
2. Creates commit
3. Runs tests
4. Tests fail
5. DOES NOT PUSH
6. Reports test failure to user
```

### Scenario 3: Multi-Step Work
```
User: "make these changes but don't push yet"

Claude:
1. Makes changes
2. Commits locally
3. DOES NOT PUSH
4. Waits for user to say "push" later
```

## Summary

**Key Points:**
- ✅ Always ask permission before pushing to remote
- ✅ Always run tests before pushing
- ✅ Always verify tests pass (100% pass rate)
- ✅ Use clear commit messages
- ✅ Include Co-Author tag
- ❌ Never push without permission
- ❌ Never force push without extra permission
- ❌ Never push when tests are failing
