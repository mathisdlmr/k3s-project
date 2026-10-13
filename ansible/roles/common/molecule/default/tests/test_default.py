# molecule/default/tests/test_default.py
# Testinfra checks that the role under test has been applied correctly.

# Note: Tailscale isn't exercised here : it needs a real account/authkey) 
# so it isn't checked either (tagged molecule-notest in the role).



def test_base_packages_are_installed(host):
    BASE_PACKAGES = ["openssh-server", "ufw", "unattended-upgrades", "curl", "lynis"]
    for package in BASE_PACKAGES:
        assert host.package(package).is_installed

def test_unattended_upgrades_is_configured(host):
    conf = host.file("/etc/apt/apt.conf.d/20auto-upgrades")
    assert conf.exists
    assert conf.contains('APT::Periodic::Unattended-Upgrade "1"')

def test_ssh_key_is_authorized(host):
    authorized_keys = host.file("/root/.ssh/authorized_keys")
    assert authorized_keys.exists
    assert authorized_keys.contains("molecule-test")

def test_ssh_hardening_dropin_is_present(host):
    hardening = host.file("/etc/ssh/sshd_config.d/99-hardening.conf")
    assert hardening.exists
    assert hardening.contains("PermitRootLogin no")
    assert hardening.contains("PasswordAuthentication no")

def test_cloud_init_ssh_override_is_removed(host):
    assert not host.file("/etc/ssh/sshd_config.d/50-cloud-init.conf").exists

def test_k3s_kernel_sysctls_are_set(host):
    assert host.sysctl("net.bridge.bridge-nf-call-iptables") == 1
    assert host.sysctl("net.ipv4.ip_forward") == 1

def test_inotify_limits_are_raised(host):
    assert host.sysctl("fs.inotify.max_user_watches") == 524288
    assert host.sysctl("fs.inotify.max_user_instances") == 512

def test_kernel_modules_persist_on_boot(host):
    modules_conf = host.file("/etc/modules-load.d/k3s.conf")
    assert modules_conf.exists
    assert modules_conf.contains("br_netfilter")
    assert modules_conf.contains("overlay")

def test_ufw_is_enabled(host):
    cmd = host.run("ufw status")
    assert cmd.rc == 0
    assert "Status: active" in cmd.stdout
