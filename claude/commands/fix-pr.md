Run ESLint auto-fix on all TypeScript files changed relative to the base branch (full PR scope), then commit and push any fixes.

## Step 1: Find all changed TS files in the PR

```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' '*.mts'
```

If the base branch is not `main`, detect it:
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

## Step 2: Run ESLint --fix

Run on every changed TypeScript file:
```bash
bunx eslint --fix <file1> <file2> ...
```

If no changed TypeScript files are found, report that and stop.

## Step 3: Run type-check

```bash
bunx turbo run type-check
```

Report any type errors with file:line links. Do not proceed if type-check fails — ask the user to resolve them.

## Step 4: Commit and push fixes (if any files were changed by ESLint)

Check whether ESLint actually modified files:
```bash
git diff --name-only
```

If files were changed:
```bash
git add <changed-files>
git commit -m "fix: eslint auto-fix on PR changes"
git push
```

## Step 5: Report

1. Which files were fixed and what rules were applied
2. Any remaining lint errors that could not be auto-fixed (file:line format)
3. Type-check result
4. Whether a fix commit was pushed or everything was already clean
