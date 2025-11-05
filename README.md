# DevOps Project

This repository contains the main DevOps project and uses [coffee-project](https://github.ncsu.edu/CSC-519/coffee-project.git) as a Git submodule.

## Quick Start (No Extra Work!)

**For collaborators — just clone and run setup once:**

```bash
git clone https://github.ncsu.edu/vpatel29/devops-project.git
cd devops-project
./setup.sh
```

Done! Everything is ready to use. No additional commands needed.

---

## Full Setup & Installation

### Recommended: Clone with submodules
To clone and initialize submodules in one step:

```bash
git clone --recurse-submodules https://github.ncsu.edu/vpatel29/devops-project.git
cd devops-project
```

### Manual setup (if already cloned)
If you cloned without `--recurse-submodules`, run:

```bash
./setup.sh
```

Or manually initialize submodules:

```bash
git submodule update --init --recursive
```

This will populate the `coffee-project/` folder with the latest version from its remote repository.

## Project Structure

```
devops-project/
├── README.md
├── .gitmodules          # Submodule configuration
├── coffee-project/      # Git submodule (separate repo)
│   ├── app.js
│   ├── data.js
│   ├── package.json
│   ├── README.md
│   ├── public/
│   │   ├── index.html
│   │   └── script.js
│   └── test/
│       └── app.test.js
└── ...
```

## Updating submodules

To pull the latest changes from the coffee-project remote:

```bash
cd coffee-project
git pull origin main
cd ..
git add coffee-project
git commit -m "Update coffee-project to latest"
git push
```

## Notes

- `coffee-project` is a separate Git repository embedded as a submodule
- Changes inside `coffee-project` must be committed to the coffee-project repo, not the devops-project repo
- Always use `git submodule update --init --recursive` after cloning or pulling if you see empty submodule folders
