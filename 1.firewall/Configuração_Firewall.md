# 🔥 Servidor FIREWALL - EmpresaTech

## 🖥️ Função Geral
Controlar o tráfego entre as redes **LAN (192.168.100.0/24)**, **DMZ (172.20.0.0/24)** e **WAN (Internet)**.  
Realiza **NAT (masquerade)**, **roteamento interno**, e **regras de filtragem com `nftables`**.

---

## 🌐 Interfaces de Rede

| Interface | IP | Rede | Função |
|------------|----|------|--------|
| `ens33` | DHCP | WAN (Internet) | Interface externa |
| `ens34` | 172.20.0.1/24 | DMZ | Comunicação com WEB01 e SYS01 |
| `ens35` | 192.168.100.1/24 | LAN | Gateway interno dos servidores e clientes |

---

## ⚙️ Configuração de Rede

```bash
# Interface WAN - obtém IP público via DHCP
auto ens33
iface ens33 inet dhcp

# Interface DMZ
auto ens34
iface ens34 inet static
  address 172.20.0.1/24

# Interface LAN
auto ens35
iface ens35 inet static
  address 192.168.100.1/24
```

---

## 🔄 Ativação do Roteamento IPv4

```bash
sudo nano /etc/sysctl.conf
```
Descomente (ou adicione):
```bash
net.ipv4.ip_forward=1
```

Aplicar:
```bash
sudo sysctl -p
```

---

## 🧱 Regras do nftables

```bash
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        # Permitir loopback
        iif lo accept

        # Permitir conexões já estabelecidas
        ct state established,related accept

        # SSH administrativo
        tcp dport 22 accept

        # ICMP (ping)
        ip protocol icmp accept

        # Acesso HTTP/HTTPS da DMZ
        iifname "ens34" tcp dport {80,443,8080} accept

        # Log e descarte do restante
        log prefix "DROP_INPUT: " counter
        drop
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;

        # Permitir LAN → Internet
        iifname "ens35" oifname "ens33" accept

        # Permitir LAN → DMZ
        iifname "ens35" oifname "ens34" accept

        # Permitir retorno das conexões
        ct state established,related accept

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
        iifname "ens33" tcp dport 80 dnat to 172.20.0.200:80
        iifname "ens33" tcp dport 8080 dnat to 172.20.0.201:8080
    }

    chain postrouting {
        type nat hook postrouting priority 100;
        # NAT (masquerade) para LAN e DMZ
        oifname "ens33" masquerade
    }
}
```

---

## 🧰 Serviços Instalados

```bash
sudo apt install nftables iproute2
sudo systemctl enable --now nftables
```

---

## 🧪 Testes de Conectividade

1. **Ping LAN → Internet**  
   `ping 8.8.8.8`

2. **Ping LAN → DMZ**  
   `ping 172.20.0.200`

3. **Acesso Externo (DNAT)**  
   Acessar o IP público do firewall nas portas 80 e 8080  
   → deve abrir respectivamente o **Web01 (Nginx)** e o **Sys01 (CRUD)**

---

## ✍️ Autor
**Fernando Dias**  
Docente de Redes e Infraestrutura de Computadores - SENAC São Paulo  
📘 Projeto: Infraestrutura de Servidores Linux (UC07)
