# molecule/default/tests/test_default.py
# Testinfra checks that the role under test has been applied correctly.

def test_cilium_cli_is_installed(host):
    cilium = host.file("/usr/local/bin/cilium")
    assert cilium.exists
    assert cilium.mode & 0o111

def test_cilium_daemonset_is_ready(host):
    cmd = host.run(
        "k3s kubectl -n kube-system get daemonset cilium "
        "-o jsonpath={.status.numberReady}/{.status.desiredNumberScheduled}"
    )
    assert cmd.rc == 0
    ready, desired = cmd.stdout.strip().split("/")
    assert ready == desired
    assert int(desired) > 0

def test_cilium_status_is_healthy(host):
    cmd = host.run("KUBECONFIG=/etc/rancher/k3s/k3s.yaml cilium status")
    assert cmd.rc == 0

def test_node_is_ready(host):
    cmd = host.run(
        "k3s kubectl get node -o "
        "jsonpath='{.items[0].status.conditions[?(@.type==\"Ready\")].status}'"
    )
    assert cmd.rc == 0
    assert cmd.stdout.strip() == "True"
