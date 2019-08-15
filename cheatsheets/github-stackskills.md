Github
---

```
git config --global user.name "<name>"
git config --global user.email "<mail>"
vi ~/.gitconfig

git init ["<folder>"]
git clone <url>
git commit [-m "<message>"]
git pull [<local branch> <remotebranch>]
git push [<local branch> <remotebranch>]

git status
git add <file[s]>
git add -A
git mv <old_file> <new_file>
git ls-files

git log
git log --abbrev-commit
git log --oneline --graph --decorate
git log --since="3 days ago"

git show <commit_hash>

git reset HEAD <file>			# HEAD = Last commit

git diff				# Working space vs Staging space
git diff HEAD				# Working space vs Remote space
git diff --staged HEAD 			# Staging space vs Remote space
git diff -- <file path>			# Diff a specific file
git difftool				# Work as diff. Must be configured?

git branch -a				# Show all branches
git branch <name>			# Create a new branch
git checkout <branch>			# Switch to selected branch
git branch -m <old branch> <new branch>	# Change branch name
git branch -d <branch>			# Delete a branch

git merge <branch to merge in current branch> 
```
### Updating forked repository
```
git remote add upstream <git url from original repo>
git fetch upstream

git pull upstream master
```

### Generating and login using SSH key
```
ssh-keygen -t rsa -b 4096 -C <your.mail@domain.com>
ssh-add ~/.ssh/<id rsa file>
```
Now you can add your SSH key to Github [following the next steps](<https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/>).

### Free courses
GitHub 101: [Introduction](<https://services.github.com/on-demand/intro-to-github/>)
GitHub 102: [GitHub Desktop](<https://services.github.com/on-demand/github-desktop/>)
GitHub 103: [Command Line](<https://services.github.com/on-demand/github-cli/>)