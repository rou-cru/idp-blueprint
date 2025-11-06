# LAN Exposure with Cilium L2 Announcements

This document explains how services are exposed on the local area network (LAN) using Cilium's native LoadBalancer capabilities.

## Overview

The IDP Blueprint uses **Cilium L2 Announcements** to expose Kubernetes LoadBalancer services directly on your LAN. This approach:

- ✅ Uses only Cilium (no additional components like MetalLB)
- ✅ Leverages eBPF for high-performance packet processing
- ✅ Provides automatic failover if a node fails
- ✅ Works transparently with existing LAN infrastructure

## How It Works

### Architecture Flow

```
1. IP Assignment
   └─> Cilium assigns IPs from CiliumLoadBalancerIPPool (192.168.65.240-.250)

2. L2 Announcement
   └─> Cilium sends gratuitous ARP replies on LAN
   └─> Your router/switch learns: "192.168.65.240 is at node MAC XX:XX:XX"

3. Traffic Flow
   └─> Device on LAN resolves: argocd.192-168-65-16.nip.io → 192.168.65.240
   └─> Packet arrives at Kubernetes node
   └─> Cilium eBPF routes to Gateway Pod
   └─> Response returns to device
```

### Components

1. **CiliumLoadBalancerIPPool** (`l2-ippool.yaml`)
   - Defines the IP range available for LoadBalancer services
   - Default: `192.168.65.240` - `192.168.65.250` (11 IPs)

2. **CiliumL2AnnouncementPolicy** (`l2-announcement-policy.yaml`)
   - Configures which IPs to announce and on which interfaces
   - Enables announcement from all nodes for high availability

3. **Cilium Configuration** (`cilium-values.yaml`)
   - `l2announcements.enabled: true` - Enables the L2 announcement feature
   - `loadBalancer.mode: "kubernetes"` - Uses Kubernetes CRDs for IP management

## IP Range Selection

### Default Range: 192.168.65.240 - 192.168.65.250

This range is chosen for the following reasons:

1. **High subnet addresses** - Most home/office routers configure DHCP pools in lower ranges:
   - Typical DHCP: `192.168.65.2` - `192.168.65.100` or `.2` - `.200`
   - Our range: `192.168.65.240` - `192.168.65.250`
   - **Low probability of conflict** in default configurations

2. **Predictable** - Services always get IPs in a known range
3. **Sufficient capacity** - 11 IPs for Gateway + future services

### DHCP Conflict Warning

⚠️ **POTENTIAL CONFLICT SCENARIO**

If your router's DHCP pool extends to the high end of the subnet (e.g., `.2` - `.254`), there is a risk of IP address collision:

```
Conflict Example:
1. Router DHCP assigns 192.168.65.240 to a laptop
2. Cilium assigns 192.168.65.240 to Gateway LoadBalancer
3. Result: Two devices claim the same IP
   → ARP conflicts on the network
   → Unpredictable connectivity
```

### Recommended Solution (Production)

**Reserve the IP range in your router's DHCP configuration:**

Most routers allow you to define DHCP exclusions or reduce the pool range:

```
Example Router Configuration:
┌─────────────────────────────────┐
│ DHCP Settings                   │
├─────────────────────────────────┤
│ Start IP: 192.168.65.10         │
│ End IP:   192.168.65.199        │
│                                 │
│ Reserved Range (manual):        │
│   192.168.65.200 - 192.168.65.250│
│   Purpose: Kubernetes Services  │
└─────────────────────────────────┘
```

**Benefits:**
- Zero chance of DHCP conflicts
- Clean separation of dynamic (DHCP) and static (Kubernetes) IPs
- Easier troubleshooting (you know `.240+` are always k8s services)

### Alternative (If Router Access Not Available)

If you cannot modify router settings, verify the DHCP pool doesn't reach `.240`:

```bash
# Test if IPs are free before deployment
for ip in {240..250}; do
  ping -c 1 -W 1 192.168.65.$ip > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "⚠️  192.168.65.$ip is in use - potential conflict!"
  else
    echo "✅ 192.168.65.$ip available"
  fi
done
```

If conflicts are detected, you have two options:

1. **Adjust the IP pool** in `IT/cilium/l2-ippool.yaml` to use a different range
2. **Wait for DHCP leases to expire** and ensure devices don't use those IPs

## Customizing the IP Range

If you need to change the IP range (e.g., your network is `10.0.0.0/24`):

1. **Edit the IP pool** (`IT/cilium/l2-ippool.yaml`):
   ```yaml
   spec:
     blocks:
       - start: "10.0.0.240"
         stop: "10.0.0.250"
   ```

2. **Update Gateway hostname** (`IT/gateway/gateway.yaml`):
   ```yaml
   spec:
     listeners:
       - hostname: '*.10-0-0-16.nip.io'  # Match your LAN IP format
   ```

3. **Re-deploy Cilium** to apply changes:
   ```bash
   task cilium:deploy
   kubectl apply -f IT/cilium/
   ```

## Verification

After deployment, verify L2 announcements are working:

### 1. Check LoadBalancer IP Assignment

```bash
kubectl get svc cilium-gateway-idp-gateway -n kube-system
```

Expected output:
```
NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)
cilium-gateway-idp-gateway    LoadBalancer   10.43.120.235   192.168.65.240    443:31055/TCP
```

### 2. Check Cilium L2 Status

```bash
kubectl get ciliumloadbalancerippool
kubectl get ciliuml2announcementpolicy
```

### 3. Test Connectivity from LAN

From another device on your LAN:

```bash
# Test DNS resolution
nslookup argocd.192-168-65-16.nip.io
# Should resolve to 192.168.65.240

# Test HTTPS connectivity
curl -k https://argocd.192-168-65-16.nip.io
# Should return ArgoCD UI HTML
```

### 4. Check ARP Table (Advanced)

On the Kubernetes host:

```bash
# Check if the LoadBalancer IP is announced
ip neigh show | grep 192.168.65.240
```

## Troubleshooting

### Service Stuck in "Pending"

**Symptom:** LoadBalancer service shows `EXTERNAL-IP: <pending>`

**Causes:**
1. L2 announcements not enabled in Cilium
2. CiliumLoadBalancerIPPool not created
3. IP pool exhausted

**Solution:**
```bash
# Check Cilium config
kubectl get cm -n kube-system cilium-config -o yaml | grep -A5 l2

# Check IP pools
kubectl get ciliumloadbalancerippool -o yaml

# Re-apply L2 resources
kubectl apply -f IT/cilium/
```

### Cannot Access Service from LAN

**Symptom:** Service has IP assigned but not reachable from other devices

**Causes:**
1. IP conflict with another device
2. Firewall on Kubernetes host blocking traffic
3. Wrong interface selected for announcements

**Solution:**
```bash
# Check for IP conflicts
arping -I eth0 192.168.65.240

# Check Cilium logs
kubectl logs -n kube-system -l k8s-app=cilium | grep -i l2

# Verify announcement policy
kubectl get ciliuml2announcementpolicy lan-announcement -o yaml
```

### DNS Not Resolving

**Symptom:** `nslookup argocd.192-168-65-16.nip.io` fails

**Causes:**
1. Using wrong IP format (should match your actual LAN IP)
2. nip.io service is down (rare)

**Solution:**
```bash
# Check your actual LAN IP
ip route get 1.1.1.1 | awk '{print $7; exit}'

# Use the correct format
# If IP is 192.168.65.16, use: service.192-168-65-16.nip.io
```

## References

- [Cilium L2 Announcements Documentation](https://docs.cilium.io/en/stable/network/l2-announcements/)
- [Cilium LoadBalancer IPAM](https://docs.cilium.io/en/stable/network/lb-ipam/)
- [Gateway API Service Exposure](../../ARCHITECTURE_VISUAL.md#8-gateway-api-service-exposure)
