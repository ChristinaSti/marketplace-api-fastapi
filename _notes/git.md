# git

## Branching strategy
- trunk-based development
    - One long-lived branch: main
    - Optional short-lived feature branches (≤ 1 day)

## Getting started
1. create github repository (for codebase storage and version control) and an associated project (for task management)
- don't chose an generic `.gitignore` template, make a minimal, project-specific one (+readability, -accidental over-ignoring)
2. clone the repository (including files and history) from remote server to local machine
- sets 'origin' as the shorthand name for the remote repository to use instead of URL
3. set up **branch protection rules** for main (set as pattern):
- in github repo UI: Settings → Branches → Add branch ruleset
- enable:
    - Require pull request before merging (e.g. require review form code owner)
    - Block force pushes (prevents changing existing commit history)
    - Restrict deletions
    - TODO: automated tests, linters, or CI/CD pipelines must pass before integration

## Git workflow
1. change to main branch: `git checkout main` (or `switch` instead of `checkout`)
2. `git pull`
- fetches changes from all remote branches in the github repo to corresponding remote tracking branches (origin/main, origin/feature-x, ...) that are read-only copies of the remote branches
- merges only the remote counterpart of the branch, I am currently on
=> in this case: merge origin/main into my local main
3. create and change to a new feature branch
- e.g. `git checkout -b feature/42-add-login` (or `git switch -c ...`)
    - linking branch to github issue with issue number as prefix
4. implement and test small feature
5. `git add <file_name>`: stage changes I want to commit
6. e.g. `git commit -m "Add login endpoint #42"`
- link github issue in commit message
- keywords like `Closes #42` or `Fixes #42` in commit message or PR description will automatically close the issue when the PR is merged into main
7. It can be useful to combine multiple small commits into an single more meaningful one for these reasons:
    - **cleaner history** e.g. if there are 'fix typo' or 'WIP' commits
    - **easier reverts** of the whole feature that breaks the build
    - **simplified reviews**
- HowTo:
    - e.g. `git rebase -i HEAD~3` for squashing the last 3 commits
    - in the editor that opens, keep the first commit as pick and change the others to squash (or s)
    - write commit message for combined changes
7. if the main branch has changed since checking out the feature branch:
- avoid creating merge commit (which would happen when using e.g. `git fetch origin main && git merge origin/main` from feature branch) by rebasing instead:
    - `git fetch `(`origin main`): updates the remote tracking branches (or just origin/main) with the remote versions
    - `git rebase origin/main`: makes it as if the feature branch was started from the latest main branch, without a merge commit => keeps history linear
    - eventually solve merge conflicts
8. `git push -u origin <branch_name>`
- -u (or --set-upstream): establishes a tracking relationship, it links the local branch to the remote branch on origin => `git push` alone without branch name specification will be enough for future pushes and analogously for other commands
9. Create pull request in github, merge when approved and CI/CD pipeline completed successfully

