# Practical Git Guide (Beginner to Advanced)

This guide is written in **simple language**, works with **default Git behavior**, and covers **real-world setups** you will actually use. It is suitable for beginners and still useful for advanced users.

______________________________________________________________________

## 1. What Is Git?

**Git** is a distributed version control system. It tracks changes in files so that:

- You can go back in time
- Multiple people can work together
- You can safely experiment without breaking things

Git works **locally first**. The internet is optional.

______________________________________________________________________

## 2. Installing Git

### Linux (most distros)

```bash
sudo apt install git        # Debian/Ubuntu
sudo pacman -S git          # Arch
sudo dnf install git        # Fedora
```

### Verify installation

```bash
git --version
```

______________________________________________________________________

## 3. One-Time Setup (Mandatory)

These values are attached to every commit.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Optional but recommended:

```bash
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global color.ui auto
```

______________________________________________________________________

## 4. Creating a Repository

### Option A: Start a new project

```bash
git init
```

### Option B: Clone an existing repo

```bash
git clone git@github:USER/REPO.git
```

______________________________________________________________________

## 5. Basic Daily Workflow

### Check status (use this a lot)

```bash
git status
```

### Stage changes

```bash
git add file.txt        # specific file
git add .               # everything
```

### Commit changes

```bash
git commit -m "Clear message explaining why"
```

### View history

```bash
git log --oneline --graph --decorate
```

______________________________________________________________________

## 6. Undoing Mistakes (Safe Methods)

### Undo unstaged changes

```bash
git restore file.txt
```

### Unstage a file

```bash
git restore --staged file.txt
```

### Fix last commit message

```bash
git commit --amend
```

⚠️ Do not amend commits that are already pushed.

______________________________________________________________________

## 7. Branches (Core Concept)

### Create a branch

```bash
git branch new-feature
```

### Switch branch

```bash
git switch new-feature
```

### Create + switch

```bash
git switch -c new-feature
```

### Merge branch

```bash
git switch main
git merge new-feature
```

______________________________________________________________________

## 8. Remote Repositories (GitHub / GitLab)

### Add a remote

```bash
git remote add origin git@github:USER/REPO.git
```

### Push for the first time

```bash
git push -u origin main
```

After this, just use:

```bash
git push
git pull
```

______________________________________________________________________

## 9. Pushing to GitHub **and** GitLab (Mirroring)

### Best Practice: One fetch, multiple push

```bash
git remote add all git@github:USER/REPO.git
git remote set-url --add --push all git@github:USER/REPO.git
git remote set-url --add --push all git@gitlab.com:USER/REPO.git
```

### Push to both

```bash
git push all main
```

### Push everything

```bash
git push all --all
git push all --tags
```

______________________________________________________________________

## 10. SSH Setup (Required for Smooth Work)

### Generate key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

### Add key to agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Test

```bash
ssh -T git@github
ssh -T git@gitlab.com
```

______________________________________________________________________

## 11. Handling Conflicts

When Git cannot merge automatically:

1. Open the file
1. Fix the marked sections
1. Stage the file
1. Commit

```bash
git add conflicted_file.txt
git commit
```

______________________________________________________________________

## 12. Stashing (Temporary Save)

```bash
git stash            # save changes
git stash pop        # restore
```

Useful when switching branches quickly.

______________________________________________________________________

## 13. Tags (Releases)

```bash
git tag v1.0.0
git push origin v1.0.0
```

Annotated tag (recommended):

```bash
git tag -a v1.0.0 -m "First release"
```

______________________________________________________________________

## 14. Cleaning and Maintenance

### Remove untracked files

```bash
git clean -fd
```

⚠️ This deletes files permanently.

### Garbage collection

```bash
git gc
```

______________________________________________________________________

## 15. Useful Aliases (Optional)

```bash
git config --global alias.s status
git config --global alias.l "log --oneline --graph --decorate"
```

______________________________________________________________________

## 16. Golden Rules

- Commit **small and often**
- Write commit messages like explanations, not titles
- Never force-push shared branches
- Always `git status` before pushing
- If confused: **stop and inspect**

______________________________________________________________________

## 17. If Something Breaks

```bash
git status
git reflog
git log --oneline
```

Git almost never loses data.

______________________________________________________________________

## 18. Mental Model: How Git Thinks

Git does **not** track files — it tracks **snapshots**.

Key ideas:

- A commit is a **snapshot** of the entire project
- Branches are **labels** pointing to commits
- HEAD tells Git where you currently are

Think of Git as:

> A graph of snapshots, not a list of changes

______________________________________________________________________

## 19. One-Page Quick Reference

```bash
# Create / clone
git init
git clone <repo>

# Daily work
git status
git add .
git commit -m "message"
git push
git pull

# Branching
git switch -c branch
git merge branch

# Undo
git restore file
git restore --staged file

git log --oneline --graph
```

______________________________________________________________________

## 20. What NOT To Do (Hard Rules)

❌ Do NOT force-push shared branches

```bash
git push --force    # dangerous
```

❌ Do NOT commit secrets

- API keys
- Tokens
- Passwords

❌ Do NOT rewrite history after pushing

```bash
git commit --amend
```

______________________________________________________________________

## 21. Solo Developer vs Team Workflow

### Solo

- main branch only
- frequent commits
- rebase allowed

### Team

- main protected
- feature branches
- merge commits preferred

Golden rule:

> Rewriting history is fine **only if no one else has it**.

______________________________________________________________________

## 22. CI/CD-Aware Workflow

Typical pipeline:

1. Push code
1. CI runs tests
1. Merge only if green

Good practices:

- Never push broken main
- Use tags for releases
- Keep commits small

______________________________________________________________________

## 23. Safe Hard Reset Recovery

If you mess up badly:

```bash
git reflog
```

Find the commit hash, then:

```bash
git reset --hard <hash>
```

Git rarely loses data.

______________________________________________________________________

## 24. NixOS + SSH Notes

- SSH keys live in `~/.ssh`
- Prefer `ed25519`
- Ensure agent is running

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

______________________________________________________________________

## 25. Git for Backup (Mirroring)

Use multiple remotes:

```bash
git remote add all git@github:USER/REPO.git
git remote set-url --add --push all git@github:USER/REPO.git
git remote set-url --add --push all git@gitlab.com:USER/REPO.git
```

Then:

```bash
git push all main
```

This gives redundancy with zero extra effort.

______________________________________________________________________

## 26. Git for Open-Source Contribution

This is the standard workflow used in most open-source projects.

### 1. Fork the Repository

On GitHub or GitLab, click **Fork**. This creates a copy under your account.

You now have:

- Original repo (upstream)
- Your fork (origin)

______________________________________________________________________

### 2. Clone Your Fork

```bash
git clone git@github:YOUR_USERNAME/REPO.git
cd REPO
```

______________________________________________________________________

### 3. Add Upstream Remote

```bash
git remote add upstream git@github:ORIGINAL_OWNER/REPO.git
```

Verify:

```bash
git remote -v
```

______________________________________________________________________

### 4. Create a Feature Branch

Never work directly on `main`.

```bash
git switch -c fix-bug-description
```

Branch names should be short and meaningful.

______________________________________________________________________

### 5. Make Changes and Commit

```bash
git add .
git commit -m "Fix: clear explanation of what was broken"
```

Good open-source commits:

- Small
- Focused
- Explain **why**, not just what

______________________________________________________________________

### 6. Keep Your Fork Updated

Before pushing or opening a PR:

```bash
git fetch upstream
git switch main
git merge upstream/main
git push origin main
```

Then rebase your branch if needed:

```bash
git switch fix-bug-description
git rebase main
```

______________________________________________________________________

### 7. Push Your Branch

```bash
git push origin fix-bug-description
```

______________________________________________________________________

### 8. Open a Pull Request (PR)

- Base branch: `upstream/main`
- Compare branch: your feature branch

Write a good PR description:

- What problem does this solve?
- How was it tested?
- Screenshots if UI-related

______________________________________________________________________

### 9. Handle Review Feedback

If maintainers request changes:

```bash
# make changes
git add .
git commit -m "Address review feedback"
git push origin fix-bug-description
```

Do **not** open a new PR.

______________________________________________________________________

### 10. After Merge (Cleanup)

```bash
git switch main
git pull upstream main
git branch -d fix-bug-description
git push origin --delete fix-bug-description
```

______________________________________________________________________

### Open-Source Etiquette (Important)

- Read `CONTRIBUTING.md`
- Follow project style
- Be respectful in discussions
- Do not demand merges

Good contributors are remembered.

______________________________________________________________________

## 27. Final Note

If you understand:

- commits
- branches
- remotes
- status

You already know Git better than most people.

This document intentionally avoids unsafe tricks and rare edge cases.
Master this, and Git will never be a problem again.
