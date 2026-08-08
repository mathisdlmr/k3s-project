# molecule/default/tests/test_default.py
# Testinfra checks that the role under test has been applied correctly.

# Note : without Cilium the node stays NotReady - only checked here 
# is that k3s itself is up and the node is registered, not that it's Ready.

def test_k3s_binary_is_installed(host):
    assert host.file("/usr/local/bin/k3s").exists

def test_k3s_config_is_deployed(host):
    config = host.file("/etc/rancher/k3s/config.yaml")
    assert config.exists
    assert config.contains("cluster-init: true")
    assert config.contains("flannel-backend: none")

def test_k3s_service_is_running(host):
    k3s = host.service("k3s")
    assert k3s.is_running
    assert k3s.is_enabled

def test_k3s_api_is_listening(host):
    assert host.socket("tcp://0.0.0.0:6443").is_listening

def test_node_is_registered(host):
    cmd = host.run("k3s kubectl get node")
    assert cmd.rc == 0

def test_kubeconfig_is_copied_for_ansible_user(host):
    kubeconfig = host.file("/home/root/.kube/config")
    assert kubeconfig.exists
    assert kubeconfig.user == "root"
