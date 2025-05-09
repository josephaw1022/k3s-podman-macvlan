# 🧪 K3s + Podman + macvlan + Headlamp Setup

This project runs a local K3s cluster in Podman containers using a macvlan network, allowing you to expose your Kubernetes API and services directly on your LAN. It's great for local development, testing, or homelab setups.

---


## 📦 Prerequisites

You must first create a **macvlan network** that connects your containers to your LAN.

> 🔧 I'm using my laptop setup, that is done automatically via Ansible:
> [▶️ macvlan setup task](https://github.com/josephaw1022/LaptopConfiguration/blob/main/fedora-41/automated-setup/roles/podman/tasks/macvlan.yml)

For convenience and to focus on this repo, here's the shell equivalent of what the Ansible playbook does:

```bash
# Create the Podman macvlan network (only needed once)
sudo podman network create \
  --driver macvlan \
  --subnet 192.168.0.0/21 \
  --gateway 192.168.2.1 \
  --macvlan eth0 \
  homelabnetwork

# Delete existing macvlan interface if it exists
sudo ip link delete macvlan0 2>/dev/null || true

# Create macvlan interface on host bound to the parent interface
sudo ip link add macvlan0 link eth0 type macvlan mode bridge

# Assign an IP to the new interface
sudo ip addr add 192.168.0.3/21 dev macvlan0

# Bring the interface up
sudo ip link set macvlan0 up
```

> Replace `eth0` with your actual interface if different (check with `ip link`).

This gives your **host access to the `homelabnetwork`**, allowing it to communicate with Podman containers using real LAN-routable IPs.

---

## 🚀 Quick Start

### 🔍 View available Makefile targets

```bash
make
```

### 🛠 Start the K3s + Pi-hole cluster

```bash
make up
```

### 📄 Replace your kubeconfig with the one from K3s

```bash
make replace-kubeconfig
```

### 🔌 Enable host access to the macvlan subnet

```bash
make setup-host-macvlan
```

---

## 🌐 Accessing the Cluster

Once setup is complete, open **Headlamp** in your browser. You should see your K3s cluster running on the macvlan network.

### 📸 Cluster view:

![Headlamp Cluster](images/headlamp-cluster.png)

### 📦 Pods view:

![Cluster Pods](images/cluster-pods.png)

---

## 🌐 DNS with Pi-hole

This setup includes a Pi-hole container that also acts as a DNS server for your K3s cluster.

* The file `kubesoar.conf` inside the `dnsmasq-config/` directory is **automatically mounted into Pi-hole**.
* Pi-hole is just a wrapper around `dnsmasq`, so this file is picked up and used on container start — **no manual reload or reconfiguration required**.
* This enables DNS resolution for domains like `kubesoar.home` and `*.kubesoar.home` inside your LAN.

### 📌 DNS Setup

To make use of this:

* Set the **IP of the Pi-hole container** as your primary DNS server.
* You can do this:

  * On your **laptop's network settings** (for quick testing)
  * Or on your **router/DHCP settings** (recommended for persistent, network-wide use)

> ⚠️ Even though containers run on macvlan, it's likely that DNS resolution still flows through the host stack unless explicitly overridden — so setting your laptop’s DNS may still work. However, setting it at the router is the safest, most consistent approach.

---

## 🧹 Cleanup

To tear everything down:

```bash
make down
make cleanup-host-macvlan
make clean
```
