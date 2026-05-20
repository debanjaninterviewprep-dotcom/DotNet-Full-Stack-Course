Local setup and push instructions

Repository location (workspace-relative): DotNet-Full-Stack-Course/

1) Verify clone and remotes

  git remote -v
  git branch -a

2) Configure Git user (if not already):

  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"

3) Authentication options

- HTTPS (Personal Access Token):
  1. Create a Personal Access Token (PAT) on GitHub with `repo` scope.
  2. On Windows, Git Credential Manager usually handles storing credentials. When prompted for a password, use the PAT as the password.
  3. Example push (first push may need `-u` to set upstream):

     git add .
     git commit -m "Your message"
     git push -u origin main

- SSH:
  1. Generate a key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
  2. Start agent and add key (Windows may differ):
     eval "$(ssh-agent -s)"
     ssh-add ~/.ssh/id_ed25519
  3. Copy `~/.ssh/id_ed25519.pub` and add it to GitHub (Settings → SSH and GPG keys).
  4. Change remote to SSH if desired:

     git remote set-url origin git@github.com:debanjaninterviewprep-dotcom/DotNet-Full-Stack-Course.git

4) If you don't have push permission

- If the repo belongs to another GitHub account and you don't own it, either:
  - Add your account as a collaborator (ask the repo owner), or
  - Fork the repo on GitHub, then set your fork as `origin`:

     git remote set-url origin https://github.com/your-username/DotNet-Full-Stack-Course.git

5) Quick workflow to push changes

  git checkout -b my-changes
  git add .
  git commit -m "Describe changes"
  git push -u origin my-changes

6) Open in VS Code

  cd DotNet-Full-Stack-Course
  code .

Troubleshooting:
- If `git push` fails with authentication/permission errors, confirm the account you're authenticating with matches the repo owner or that you have collaborator access.
- Use a PAT with appropriate scopes for HTTPS pushes, or use SSH keys for passwordless pushes.

