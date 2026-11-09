# RH294-Labs — BUILD

- **Repo:** `UncleD0886475978/RH294-Labs` — **public fork** (per task brief). Lab exercises for the RH294 (Red Hat Ansible Automation) course.
- **Stack actually found** (via GitHub connector directory listing of the root):
  - **Docs/labs only at root — no runnable code:** Markdown/plain lab instruction sheets: `Lab - Caching Server.md`, `Lab - Tomcat Automation.md`, `Lab - Virtual Hosting.md`, `Lab - Wordpress.md`, `Labs - Ad Hoc Commands`, `Labs - Ansible Conditions`, `Labs - Ansible Loops`, `Labs - Ansible Vault`, `Labs - Multiple Plays Playbooks`, `Labs - Simple Playbooks`, `Labs - Task Failure Handling`, `Labs - Variables`, `Labs- Extra`.
  - Root also: `README.md` (48 B), `Untitled Diagram.drawio.png`, `.gitattributes`, and a `brarchitects/` directory.
  - **No `.yml` playbooks, no ansible.cfg, no inventory at root** — the Ansible commands live inside the instruction sheets and are meant to run on the RH294 course lab environment.
- **Inspection note:** the connector returned directory listings, not file bodies, and a GitHub HTTP 429 (rate limit) stopped inspection before `brarchitects/` and any deeper paths were listed. `setup.sh` discovers any real playbooks at runtime with `find`, so if playbooks exist deeper in the tree it will list and sample-check them.

## One-line install (fresh Ubuntu/Debian VM)

```bash
curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/RH294-Labs/main/setup.sh | bash
```

The script installs its own prerequisites — git/curl base tools and python3 + venv via apt (Ansible itself is installed with pip into a local `.venv`, never via apt) — then locates/clones the repo and verifies the lab catalogue; it remains docs-only verify-and-open and never runs the labs for you. Alternative: clone the repo yourself and run `./setup.sh` from its root, as described below.

## What setup.sh does

0. Platform check + base bootstrap: installs git/curl/ca-certificates/gnupg via apt when missing (on non-apt systems it only checks tools and prints install guidance).
1. Uses the current checkout if its git remote mentions `RH294-Labs` (or the script sits in the repo root); otherwise clones into `~/repos/RH294-Labs` (`git pull` if already there).
2. Bootstraps python3 + venv via apt; on a non-apt system without python3 it prints the Python and Ansible install-doc URLs and exits cleanly.
3. Resolves Ansible: system `ansible-playbook` if present, else creates `.venv` and `pip install ansible`.
4. Lists every lab instruction sheet with a one-line usage (open it, follow its steps on the lab hosts), discovers any `.yml`/`.yaml` playbooks anywhere in the repo, and syntax-checks a sample if one exists — with an honest note when the checkout is instruction-sheets only.
5. Prints next commands: how to start a lab, the RH294 control-node/managed-host assumption, how to stop lab services, and where logs live.

**Issue it prevents:** expecting a runnable project and "running the repo" when it is actually a set of guided lab sheets that only make sense, step by step, on the RH294 lab machines.
