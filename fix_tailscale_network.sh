#!/bin/bash
# Script à exécuter avec "sudo" sur chaque noeud k3s
# Ce script force Tailscale à contourner le blocage UDP de la Freebox en passant par le relais TCP DERP

if [ "$EUID" -ne 0 ]
  then echo "Veuillez exécuter ce script avec sudo"
  exit
fi

echo "=== Configuration Tailscale : Forçage du relais TCP (DERP) ==="
# On enlève le MTU modifié qui n'a rien corrigé
sed -i '/TS_DEBUG_MTU=1200/d' /etc/default/tailscaled

# On ajoute le forçage DERP
if grep -q "TS_DEBUG_ALWAYS_USE_DERP" /etc/default/tailscaled 2>/dev/null; then
    sed -i 's/.*TS_DEBUG_ALWAYS_USE_DERP.*/TS_DEBUG_ALWAYS_USE_DERP=true/' /etc/default/tailscaled
else
    echo 'TS_DEBUG_ALWAYS_USE_DERP=true' >> /etc/default/tailscaled
fi

echo "Redémarrage de Tailscaled..."
systemctl restart tailscaled

echo "Redémarrage de K3s pour relancer etcd proprement..."
systemctl restart k3s

echo "=== Terminé ! Vérifiez la latence avec 'tailscale ping 100.113.113.100' ==="
