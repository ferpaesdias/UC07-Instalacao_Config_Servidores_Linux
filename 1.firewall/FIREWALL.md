# FIREWALL – Servidor de Borda (NAT + Filtro de Pacotes)

## 1. Visão Geral

Este servidor funciona como **gateway** entre:

- **Internet (WAN)** – recebe IP via DHCP  
- **DMZ (172.20.0.0/24)** – onde ficam os servidores WEB01 e SYS01  
- **LAN (192.168.100.0/24)** – rede interna da empresa  

<br/>

Funções principais:

- Fazer **NAT (masquerade)** para que a LAN e a DMZ acessem a Internet.
- Controlar o tráfego entre **LAN ↔ DMZ** e **LAN/DMZ ↔ Internet** usando **nftables**.
- Ser o **gateway padrão** para as redes LAN e DMZ.

<br/>

Interfaces sugeridas:

- enp0s3 → WAN  
- enp0s8 → DMZ  
- enp0s9 → LAN  

---

## 2. Pré-requisitos

- Debian 13 “Trixie”
- 3 interfaces configuradas no VirtualBox
- Acesso root/sudo

---

## 3. Configuração de Rede

### 3.1 Arquivo `/etc/network/interfaces`

```ini
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet dhcp

auto enp0s8
iface enp0s8 inet static
    address 172.20.0.1
    netmask 255.255.255.0

auto enp0s9
iface enp0s9 inet static
    address 192.168.100.1
    netmask 255.255.255.0
```

<br/>

Aplicar:

```
sudo systemctl restart networking
```

---

## 4. Habilitar Roteamento

```conf
# /etc/sysctl.d/99-sysctl.conf
net.ipv4.ip_forward = 1
```

<br/>

Aplicar:

```
sudo sysctl --system
```

---

## 5. Instalação do nftables

```
sudo apt update
sudo apt install -y nftables
sudo systemctl enable --now nftables
```

---

## 6. Configuração `/etc/nftables.conf`

```nft
#!/usr/sbin/nft -f

# Apaga completamente o conjunto de regras anteriores
flush ruleset

# --- Variaveis --- #
# Altere os valores conforme sua infraestrutura
define WAN_IF = "enp0s3"
define DMZ_IF = "enp0s8"
define LAN_IF = "enp0s9"
define DMZ_NET = 172.20.0.0/24
define LAN_NET = 192.168.100.0/24

# Tabela INET FILTER
table inet filter {

  # --- CHAIN INPUT --- #
  # Pacotes destinados ao proprio Firewall
  chain input {
    type filter hook input priority 0;
    policy drop;
   
    # Aceitar loopback
    iifname "lo" accept

    # Aceitar as conexoes ja pre estabelecidas ou relacionadas
    ct state {established, related} accept

    # Descarta pacotes invalidos
    ct state invalid drop

    # Permitir ICMP da LAN  para o Firewall
    iifname $LAN_IF icmp type echo-request accept

    # Permitir ICMP da DMZ para o Firewall
    iifname $DMZ_IF icmp type echo-request accept

    # Permitir que o DHCP Client funciona na interface WAN
    iifname $WAN_IF udp dport 68 accept

    # Permitir acesso SSH ao Firewall apenas pela rede LAN 
    iifname $LAN_IF tcp dport 22 accept

    # Log de pacotes bloqueados
    log prefix "FIREWALL INPUT DROP: " flags all
  }

  # --- CHAIN FORWARD --- #
  # Pacotes que passam pelo Firewall
  chain forward {
    type filter hook forward priority 0;
    policy drop;

    # Permite o trafego de conexoes ja estabelecidas
    ct state {established, related} accept

    # Descarta pacotes invalidos
    ct state invalid drop

    # Permite que a rede LAN acesse a rede WAN
    iifname $LAN_IF oifname $WAN_IF accept
 
    # Permite que a rede LAN acesse a rede DMZ
    iifname $LAN_IF oifname $DMZ_IF accept
 
    # Permite que a rede DMZ acesse a rede WAN
    iifname $DMZ_IF oifname $WAN_IF accept

    # Log de pacotes bloqueados
    log prefix "FIREWALL FORWARD DROP: " flags all
  }

# --- CHAIN OUTPUT --- #
  # Pacotes originados pelo Firewall
  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}

# TABELA IP NAT
table ip nat {
  
  # --- CHAIN PREROUTING (DNAT)
  # Aplica regras a pacotes assim que eles chegam, antes do roteamento
  chain prerouting {
    type nat hook prerouting priority -100; 
  }   

  # --- CHAIN POSTROUTING (MASQUERADE) --- #
  chain postrouting {
    type nat hook postrouting priority 100;
    oifname $WAN_IF masquerade
  }
}
```

<br/>

Aplicar:

```
sudo nft -f /etc/nftables.conf
sudo nft list ruleset
```

---

## 7. Testes

### Firewall:
```
ping -c 4 8.8.8.8
ping -c 4 google.com
```

<br/>

---

## 8. Notas

- Ajuste o nome das interfaces com `ip a`
- Para limpar regras: `sudo nft flush ruleset`
