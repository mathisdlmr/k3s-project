# molecule/default/tests/test_default.py
# Testinfra checks that the role under test has been applied correctly.

def test_helm_is_installed(host):
    helm = host.file("/usr/local/bin/helm")
    assert helm.exists
    assert helm.mode & 0o111


def test_argocd_values_file_deployed(host):
    values_file = host.file("/tmp/argocd-values.yaml")
    assert values_file.exists
    assert values_file.contains("ghcr.io/mathisdlmr/argocd")


def test_bootstrap_app_file_deployed(host):
    bootstrap_file = host.file("/tmp/bootstrap-app.yaml")
    assert bootstrap_file.exists
    assert bootstrap_file.contains("name: argocd-bootstrap")


def test_argocd_namespace_exists(host):
    cmd = host.run("k3s kubectl get namespace argocd")
    assert cmd.rc == 0


def test_argocd_server_deployment_is_ready(host):
    cmd = host.run(
        "k3s kubectl -n argocd get deployment argocd-server "
        "-o jsonpath={.status.readyReplicas}"
    )
    assert cmd.rc == 0
    assert cmd.stdout.strip() == "1"


def test_bootstrap_application_is_deployed(host):
    cmd = host.run("k3s kubectl -n argocd get application argocd-bootstrap")
    assert cmd.rc == 0
