# molecule/default/tests/test_default.py
# Testinfra checks that the role under test has been applied correctly.

def test_cstates_are_disabled(host):
    grub_file = host.file("/etc/default/grub")
    assert grub_file.contains('GRUB_CMDLINE_LINUX_DEFAULT="quiet splash processor.max_cstate=1"')