# 🔥 Servidor FIREWALL - EmpresaTech

## 🖥️ Função Geral
Controlar o tráfego entre as redes **LAN (192.168.100.0/24)**, **DMZ (172.20.0.0/24)** e **WAN (Internet)**.  
Realiza **NAT (masquerade)**, **roteamento interno**, e **regras de filtragem com `nftables`**.

---

## 🌐 Interfaces de Rede

| Interface | IP | Rede | Função |
|------------|----|------|--------|
| `ens33` | DHCP Client | WAN (Internet) | Interface externa |
| `ens34` | 172.20.0.1/24 | DMZ | Comunicação com WEB01 e SYS01 |
| `ens35` | 192.168.100.1/24 | LAN | Gateway interno dos servidores e clientes |

---

## ⚙️ Configuração de Rede

Arquivo de configuração de redes: `/etc/network/interfaces`

```bash
# Configure as interfaces conforme a sua infraestrutura 

# Interface WAN - obtém IP público via DHCP
auto enp0s3
iface enp0s3 inet dhcp

# Interface DMZ
auto enp0s8
iface enp0s8 inet static
  address 172.20.0.1/24

# Interface LAN
auto enp0s9
iface enp0s9 inet static
  address 192.168.100.1/24
```

---

## 🔄 Ativação do Roteamento IPv4

```bash
sudo vim /etc/sysctl.d/99-forwarding-custom.conf
```

<br/>

Adicione ao arquivo:
```bash
net.ipv4.ip_forward=1
```

<br/>

Aplicar a configuração:

```bash
sudo sysctl --system
```

---

## 🧱 Regras do nftables

Arquivo de configuração do `nftables`: `/etc/nftables.conf`

```bash
#!/usr/sbin/nft -f

flush ruleset

# --- Variáveis --- #
define WAN_IF  = "enp0s3"
define DMZ_IF  = "enp0s8"
define LAN_IF  = "enp0s9"
define DMZ_NET  = 172.20.0.0/24
define LAN_NET  = 192.168.100.0/24
# ------------------ # 

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        # Permitir loopback
        iif lo accept

        # Permitir conexões já estabelecidas
        ct state {established,related} accept

        # Bloquear pacotes inválidos
        ct state invalid drop

        # SSH administrativo
        ip saddr 192.168.100.200 protocol tcp dport 22 accept

        # ICMP (ping)
        ip saddr $LAN_NET protocol icmp type echo-request accept

        # Log e descarte do restante
        log prefix "DROP_INPUT: " counter
        drop
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;

        # Permitir LAN → Internet
        iifname $LAN_IF oifname $WAN_IF accept

        # Permitir LAN → DMZ
        iifname $LAN_IF oifname $DMZ_IF accept

        # Permitir conexões já estabelecidas
        ct state {established,related} accept

        # Bloquear pacotes inválidos
        ct state invalid drop

        # Log e descarte do restante
        log prefix "DROP_FORWARD: " counter
        drop
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}

table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100;
        
        # DNAT: acesso externo redirecionado para Web01 e Sys01
        iifname $WAN_IF tcp dport 80 dnat to 172.20.0.200:80
        iifname $WAN_IF tcp dport 8080 dnat to 172.20.0.201:8080
    }

    chain postrouting {
        type nat hook postrouting priority 100;
        # NAT (masquerade) para LAN e DMZ
        oifname $WAN_IF masquerade
    }
}
```

<br/>

Aplicar e validar a configuração do `nftables`:

```bash
sudo nft -f /etc/nftables.conf
```

<br/>

Listar as regras

```bash
sudo nft list ruleset
```

---

## 🧰 Habilitar e iniciar o nftables

```bash
sudo systemctl enable --now nftables
```

---

## 🧪 Testes de Conectividade

1. **Ping Firewall → Internet**  

```bash
ping 8.8.8.8
ping google.com
```

---

## ✍️ Autor
**Fernando Dias**  
Docente de Redes e Infraestrutura de Computadores 

---
