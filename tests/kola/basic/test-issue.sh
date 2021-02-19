#!/bin/bash     

# Test for issuegen's basic functionality

set -xeuo pipefail

. ${KOLA_EXT_DATA}/test-util.sh

# Pretend to be running from a TTY
faketty () {
    outfile=$1
    shift 1
    script -c "$(printf "%q " "$@")" "${outfile}"
}

if ! systemctl is-enabled ${PKG_NAME}-gensnippet-ssh-keys.service; then
    fatal "unit ${unit} not enabled"
fi
ok "systemd units enabled"

cd $(mktemp -d)

# If SSH keys are present, check that SSH keys snippets were generated by 
# `gensnippet_ssh_keys` and shown by `agetty`.
if test -n "$(find /etc/ssh -name 'ssh_host_*_key' -print -quit)"; then
    sleep 2
    faketty agetty_output.txt agetty --show-issue
    assert_file_has_content agetty_output.txt 'SSH host key:*'
    ok "gensnippet_ssh_keys"
fi

# Check that a new issue snippet is generated when a .issue file is dropped into 
# the issue run directory.
echo 'foo' > ${ISSUE_RUN_SNIPPETS_PATH}/10_foo.issue
sleep 2
faketty agetty_output.txt agetty --show-issue
assert_file_has_content agetty_output.txt 'foo'
ok "display new single issue snippet"

# Check that a large burst of .issue files dropped into the issue run directory
# will all get displayed
for i in {1..150};
do
    echo "Issue snippet: $i" > ${ISSUE_RUN_SNIPPETS_PATH}/${i}_spam.issue
done
sleep 2
faketty agetty_output.txt agetty --show-issue
for i in {1..150};
do
    assert_file_has_content agetty_output.txt "Issue snippet: $i"
done
ok "display burst of new issue snippets"

tap_finish
