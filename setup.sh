#!/usr/bin/env bash
# setup.sh — RH294-Labs (PUBLIC FORK: lab exercises for the RH294 Ansible course)
# The root of this repo is Markdown lab instruction sheets, not runnable
# playbooks. This script sets up Ansible, discovers any real playbooks that
# do exist, and lists every lab with one-line usage.
# Bootstrap: on a fresh Ubuntu/Debian VM this script INSTALLS its own prerequisites
# (git/curl base tools + python3/venv; Ansible itself via a pip venv — never apt).
# Docs-only verify behavior is unchanged: nothing here runs the labs for you.
set -e

REPO="RH294-Labs"
OWNER="UncleD0886475978"
CLONE_URL="https://github.com/${OWNER}/${REPO}.git"
TARGET_DIR="$HOME/repos/${REPO}"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO}/main/setup.sh | bash"

echo "==> Step 1/5: Platform check + base bootstrap (git, curl)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}
if [ "${APT}" -eq 1 ]; then
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    echo "    Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    echo "    Base tools already present (git, curl, ca-certificates, gnupg)."
  fi
else
  echo "    Non-apt platform detected — bootstrap will only CHECK tools and print install guidance."
fi

install_python() {
  if command -v python3 >/dev/null 2>&1 && python3 -c "import venv" >/dev/null 2>&1; then echo "    python3 + venv: already present ($(python3 --version))"; return 0; fi
  [ "${APT}" -eq 1 ] || return 1
  echo "    Installing python3, venv and pip..."
  apt_install python3 python3-venv python3-pip
  note_installed "python3"
}

echo "==> Step 2/5: Locate or clone ${REPO}"
if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi
if [ -d ".git" ] && command -v git >/dev/null 2>&1 && git remote get-url origin 2>/dev/null | grep -qi "${REPO}"; then
  REPO_DIR="$PWD"
elif [ -d "${SCRIPT_DIR}/.git" ] && command -v git >/dev/null 2>&1 && git -C "${SCRIPT_DIR}" remote get-url origin 2>/dev/null | grep -qi "${REPO}"; then
  REPO_DIR="${SCRIPT_DIR}"
elif [ -d "${TARGET_DIR}/.git" ]; then
  REPO_DIR="${TARGET_DIR}"
  git -C "${REPO_DIR}" pull --ff-only || echo "    (git pull skipped/failed — continuing with existing checkout)"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is not installed. Install it: https://git-scm.com/downloads"
    exit 1
  fi
  mkdir -p "$HOME/repos"
  git clone "${CLONE_URL}" "${TARGET_DIR}"
  REPO_DIR="${TARGET_DIR}"
fi
cd "${REPO_DIR}"
echo "    Working in: ${REPO_DIR}"

echo "==> Step 3/5: Bootstrap prerequisites (python3 for Ansible)"
MISSING_LIST=""
install_python || MISSING_LIST="${MISSING_LIST} python3(https://www.python.org/downloads/ — Ansible install docs: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)"
if [ -n "${MISSING_LIST}" ]; then
  echo "ERROR: could not auto-install on this platform. Missing:${MISSING_LIST}"
  echo "Install the tool(s) manually, then re-run this script."
  exit 1
fi
echo "    python3: $(python3 --version)"

echo "==> Step 4/5: Ansible — use system ansible, or a local venv"
ANSIBLE_PLAYBOOK=""
if command -v ansible-playbook >/dev/null 2>&1; then
  ANSIBLE_PLAYBOOK="ansible-playbook"
elif [ -x ".venv/bin/ansible-playbook" ]; then
  ANSIBLE_PLAYBOOK=".venv/bin/ansible-playbook"
else
  echo "    ansible not found — creating .venv and installing ansible with pip..."
  echo "    (Manual alternative: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)"
  python3 -m venv .venv
  .venv/bin/pip install --upgrade pip >/dev/null
  .venv/bin/pip install ansible
  ANSIBLE_PLAYBOOK=".venv/bin/ansible-playbook"
fi
${ANSIBLE_PLAYBOOK} --version | head -n 1

echo "==> Step 5/5: List the labs (and any real playbooks hiding in the repo)"
echo "    Lab instruction sheets found:"
find . -path './.venv' -prune -o -type f \( -iname 'Lab*' -o -iname 'Labs*' \) -print | sort | while IFS= read -r lab; do
  echo "      ${lab}"
  echo "        usage: open it (cat \"${lab}\") and follow its steps on your lab hosts"
done
echo ""
echo "    Playbooks (.yml/.yaml) found anywhere in the repo:"
PB_LIST="$(find . -path './.venv' -prune -o -type f \( -name '*.yml' -o -name '*.yaml' \) -print | sort)"
if [ -n "${PB_LIST}" ]; then
  echo "${PB_LIST}" | while IFS= read -r pb; do
    echo "      ${pb}"
    echo "        usage: ${ANSIBLE_PLAYBOOK} --syntax-check \"${pb}\"  then  ${ANSIBLE_PLAYBOOK} \"${pb}\""
  done
  SAMPLE="$(echo "${PB_LIST}" | head -n 1)"
  echo ""
  echo "    Syntax-checking a sample playbook to prove the toolchain works:"
  if ${ANSIBLE_PLAYBOOK} --syntax-check "${SAMPLE}" 2>/dev/null; then
    echo "    Sample OK: ${SAMPLE}"
  else
    echo "    NOTE: ${SAMPLE} did not syntax-check standalone — RH294 labs usually expect"
    echo "    the course lab environment (control node + managed hosts + lab inventory)."
  fi
else
  echo "      none — this checkout is instruction sheets only, exactly as inspected."
  echo "      The commands/playbooks live INSIDE each lab sheet; you create/run them"
  echo "      on your RH294 lab machines as the sheet directs."
fi

cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF

cat <<'EOF'

✅ RH294-Labs ready (toolchain verified, lab catalogue printed above).

NEXT COMMANDS
  Run/use:
    • Pick a lab and read it first, e.g.:
          cat "Lab - Wordpress.md"
          cat "Labs - Ansible Vault"
    • RH294 labs assume the course environment: a control node with Ansible plus the
      lab's managed hosts/inventory. Run each lab's commands on that control node,
      in the order the sheet gives, and use --check before a real playbook run.
  Stop:
    • Nothing runs persistently from this repo — lab services (httpd, Tomcat, WordPress…)
      are stopped on the lab hosts themselves, e.g. ansible all -m service -a "name=httpd state=stopped"
  Logs:
    • Terminal output of each lab command/playbook run; service logs live on the managed lab hosts (/var/log/).
EOF
