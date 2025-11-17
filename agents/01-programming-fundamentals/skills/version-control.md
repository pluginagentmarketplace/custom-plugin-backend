# Skill: Version Control & Git Mastery

## Objective
Master Git and GitHub for professional version control, collaboration, and code management in team environments.

## What is Version Control?

**Version Control System (VCS)** manages changes to source code over time by:
- **Tracking** all modifications with history
- **Enabling** reversion to previous versions
- **Allowing** parallel development (branching)
- **Facilitating** team collaboration
- **Maintaining** code integrity and accountability
- **Providing** backup and disaster recovery

## Types of Version Control

### Centralized VCS (Outdated)
- Single central repository
- Examples: SVN, Perforce
- All team members depend on central server
- Limited offline capability
- Less flexible workflow

### Distributed VCS (Modern)
- Each developer has full repository copy
- Examples: Git, Mercurial
- Works offline
- Flexible workflows
- Better for distributed teams
- Current industry standard

## Git Fundamentals

### What is Git?
- **Distributed** version control system
- Created by **Linus Torvalds** in 2005
- **Free and open-source**
- Industry standard for professional development
- Tracks snapshots, not differences
- **Fast** and **efficient**

### Core Concepts

#### Repository
A storage location containing:
- Project files
- Complete history
- Metadata
- Branches
- Tags

**Local Repository**: On your machine
**Remote Repository**: Hosted on server (GitHub, GitLab, etc.)

#### Commits
- Snapshot of code at specific time
- Contains: changes, author, timestamp, message, hash
- Immutable once created
- Complete project history

**Commit Message Best Practices**:
```
Imperative mood (use "add", not "added")
First line: concise summary (50 chars)
Blank line
Detailed explanation (wrapped at 72 chars)
References to issues: Fixes #123
```

#### Branches
- Independent line of development
- Allows parallel work
- Can be merged back together
- Default branch: `main` (or `master` historically)

**Branching Strategy**:
```
main (production-ready)
├── develop (integration branch)
│   ├── feature/user-auth
│   ├── feature/api-redesign
│   ├── bugfix/login-issue
│   └── hotfix/critical-bug
```

#### Tags
- Label specific commits
- Used for releases
- Example: `v1.0.0`, `v2.1.3`
- Create with: `git tag v1.0.0`

#### Staging Area (Index)
- Preparation zone before commit
- Allows selective committing
- Review changes before committing
- Provides flexibility

### Git Workflow

```
Working Directory → Staging Area → Local Repository → Remote Repository
   (modified)      (git add)       (git commit)      (git push)
```

## Essential Git Commands

### Repository Setup
```bash
# Initialize new repository
git init

# Clone existing repository
git clone https://github.com/user/repo.git
git clone https://github.com/user/repo.git custom-folder

# View repository configuration
git config --list
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Checking Status
```bash
# See working directory status
git status

# Show changes in working directory
git diff

# Show staged changes
git diff --staged

# Show commit history
git log
git log --oneline                    # Concise format
git log --graph --oneline --all      # Visual branch graph
git log -n 5                         # Last 5 commits
git log --author="John"              # Commits by author
git log --grep="feature"             # Search commit messages
git log --since="2 weeks ago"        # Commits since time

# Show specific commit
git show commit-hash
```

### Staging & Committing
```bash
# Stage all changes
git add .

# Stage specific file
git add path/to/file.js

# Stage interactive (choose hunks)
git add -p

# Commit changes
git commit -m "Clear commit message"

# Amend last commit (dangerous if pushed)
git commit --amend

# Unstage files
git reset HEAD filename
git restore --staged filename

# Discard changes (dangerous!)
git checkout -- filename
git restore filename
```

### Branching
```bash
# List branches (local)
git branch

# List all branches (including remote)
git branch -a

# Create new branch
git branch feature-name
git checkout -b feature-name         # Create and switch in one

# Switch branches
git checkout feature-name
git switch feature-name              # Newer syntax

# Delete branch
git branch -d feature-name           # Safe (requires merge)
git branch -D feature-name           # Force delete

# Rename branch
git branch -m old-name new-name
git branch -m new-name               # Rename current

# Push branch to remote
git push origin feature-name

# Delete remote branch
git push origin --delete feature-name
```

### Merging
```bash
# Merge branch into current branch
git merge feature-name

# Merge with merge commit (default)
git merge --no-ff feature-name

# Merge with fast-forward (if possible)
git merge --ff-only feature-name

# Abort merge if conflicts
git merge --abort
```

### Rebasing (Advanced)
```bash
# Rebase current branch on another
git rebase main                      # Linear history

# Interactive rebase (edit, squash, reorder)
git rebase -i HEAD~3                 # Last 3 commits

# Continue rebase after conflict resolution
git rebase --continue

# Abort rebase
git rebase --abort
```

### Remote Management
```bash
# List remotes
git remote -v

# Add remote
git remote add origin https://github.com/user/repo.git

# Change remote URL
git remote set-url origin new-url

# Remove remote
git remote remove origin

# Fetch from remote (download, no merge)
git fetch origin
git fetch origin main:local-branch

# Pull from remote (fetch + merge)
git pull origin main

# Push to remote
git push origin main

# Push all branches
git push origin --all

# Push tags
git push origin --tags

# Set upstream branch
git push -u origin feature-name
git branch --set-upstream-to=origin/feature-name
```

### Stashing (Temporary Storage)
```bash
# Save changes temporarily
git stash

# List stashes
git stash list

# Apply latest stash
git stash apply

# Apply specific stash
git stash apply stash@{0}

# Pop stash (apply and remove)
git stash pop

# Delete stash
git stash drop
```

### Undoing Changes
```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Undo last commit (keep changes unstaged)
git reset --mixed HEAD~1

# Completely undo last commit (dangerous)
git reset --hard HEAD~1

# Revert commit (create new commit)
git revert commit-hash              # Safe, preserves history

# Restore file from previous commit
git checkout commit-hash -- filename
```

## GitHub & Collaboration

### Creating Repository on GitHub
1. Create new repository on GitHub
2. Clone locally: `git clone <url>`
3. Add files and commit
4. Push: `git push origin main`

### Pull Requests (Code Review)
**Purpose**: Propose changes before merging

**Workflow**:
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and commit
3. Push branch: `git push origin feature/new-feature`
4. Create Pull Request on GitHub
5. Team reviews and requests changes
6. Update branch with feedback
7. Merge when approved
8. Delete branch

**PR Best Practices**:
- Small, focused changes
- Clear description of what and why
- Link related issues
- Request specific reviewers
- Respond to feedback promptly

### Branching Strategies

#### Git Flow
```
main (stable releases)
├── develop (integration)
│   ├── feature/* (new features)
│   ├── bugfix/* (bug fixes)
│   └── release/* (release prep)
├── hotfix/* (urgent fixes for main)
```

**Use When**: Complex projects, scheduled releases

#### GitHub Flow
```
main (always deployable)
├── feature-name (any changes)
├── improvement-x (enhancements)
└── fix-critical-bug (fixes)
```

**Use When**: Continuous deployment, simple workflows

#### Trunk-Based Development
```
main (development on main)
├── short-lived feature branches (2-3 days max)
└── feature flags for incomplete work
```

**Use When**: High-frequency deployments

### Commit Message Conventions

#### Conventional Commits (Popular Standard)
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, missing semicolons)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `ci`: CI/CD configuration
- `chore`: Dependency updates, maintenance

**Examples**:
```
feat(auth): add JWT token refresh mechanism
fix(api): handle null responses in user endpoint
docs: update installation instructions
test(users): add tests for user creation
```

## Collaborative Workflows

### Example Team Workflow

**Developer starts feature**:
```bash
git checkout -b feature/user-authentication
# Make changes
git add .
git commit -m "feat(auth): implement JWT authentication"
```

**Developer pushes and creates PR**:
```bash
git push origin feature/user-authentication
# Create PR on GitHub
```

**Reviewer reviews**:
- Checks code quality
- Tests functionality
- Requests changes if needed

**Developer responds to feedback**:
```bash
# Make requested changes
git add .
git commit -m "feat(auth): add password validation"
git push origin feature/user-authentication
```

**Merge when approved**:
```bash
# On GitHub: Click "Merge Pull Request"
# Or from command line:
git checkout main
git pull origin main
git merge feature/user-authentication
git push origin main
```

## Handling Merge Conflicts

### When Conflicts Occur
Conflict markers in file:
```
<<<<<<< HEAD
Your changes
=======
Their changes
>>>>>>> branch-name
```

### Resolution Steps
1. Open conflicting files
2. Decide which version to keep (or combine)
3. Remove conflict markers
4. Stage resolved files: `git add .`
5. Complete merge: `git commit`

### Conflict Prevention
- Pull before pushing
- Communicate with team
- Keep branches short-lived
- Rebase frequently

## Advanced Topics

### Rebasing vs Merging

**Merge** (recommended for public branches):
- Preserves complete history
- Creates merge commit
- Clear integration point
- Easier for team understanding

**Rebase** (recommended for local branches):
- Linear, cleaner history
- Rewriting commits (don't use on public branches)
- Dangerous if shared
- Good for cleaning local commits before PR

### Bisect (Finding Breaking Changes)
```bash
git bisect start
git bisect bad HEAD              # Current is broken
git bisect good v1.0.0          # Last known good version
# Binary search through commits
git bisect reset                # End bisect
```

### Cherry-pick (Apply Specific Commits)
```bash
# Apply specific commit to current branch
git cherry-pick commit-hash

# Apply multiple commits
git cherry-pick commit1..commit5
```

### Reflog (Safety Net)
```bash
# See all reference changes
git reflog

# Recover deleted branch
git reflog
git checkout -b recovered-branch commit-hash
```

## GitHub Features

### Issues
- Track bugs, features, discussions
- Assign to team members
- Label and milestone organization
- Close with commits/PRs

### Discussions
- Community discussions
- Q&A format
- Announcements
- Not tied to code changes

### Projects
- Kanban boards
- Sprint planning
- Progress tracking
- Integration with issues/PRs

### Actions (CI/CD)
- Automated testing
- Build pipelines
- Deployment workflows
- Code quality checks

## Best Practices

1. **Commit Frequently**
   - Small, logical changes
   - Easy to review
   - Easy to revert if needed

2. **Write Descriptive Messages**
   - Explain the "why"
   - Reference issues
   - Use standard format

3. **Keep Branches Short-Lived**
   - Feature complete in 2-3 days
   - Reduces merge conflicts
   - Easier reviews

4. **Review Before Merging**
   - Code review process
   - Automated tests
   - Manual testing

5. **Protect Main Branch**
   - Require PR reviews
   - Require passing tests
   - Prevent force pushes

6. **Clean Up**
   - Delete merged branches
   - Archive old branches
   - Maintain repository health

## Common Scenarios & Solutions

### "Oh no, I committed to main!"
```bash
git reset --soft HEAD~1           # Undo, keep changes
git branch feature/new-feature    # Create proper branch
git commit -m "proper message"
git push origin feature/new-feature
```

### "I committed with wrong message"
```bash
git commit --amend -m "Correct message"
# Only if not pushed. If pushed, use revert instead
```

### "I want to undo last 3 commits"
```bash
git reset --soft HEAD~3           # Undo but keep changes
# Or completely:
git reset --hard HEAD~3           # Dangerous!
```

### "Wrong branch tracking origin"
```bash
git branch -u origin/correct-branch
# Or:
git push -u origin feature-name
```

## Tools & Extensions

### Visual Tools
- **GitHub Desktop** - GUI for Git
- **GitKraken** - Feature-rich desktop client
- **VS Code** - Built-in Git integration
- **JetBrains IDEs** - Excellent Git integration
- **Magit** - Emacs Git interface

### Useful Aliases
```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.log 'log --graph --oneline --all'
git config --global alias.amend 'commit --amend --no-edit'
```

## Success Criteria

- [ ] Git installed and configured
- [ ] Created local repository or cloned existing
- [ ] Comfortable with basic commands (add, commit, push, pull)
- [ ] Understand and can navigate branches
- [ ] Comfortable with merging and resolving conflicts
- [ ] Created GitHub/GitLab account
- [ ] Have made commits and pushed to remote
- [ ] Have created and merged pull requests
- [ ] Understand branching strategy for team
- [ ] Can troubleshoot common Git issues
- [ ] Follow commit message conventions
- [ ] Can help team members with Git problems
