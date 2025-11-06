# 🔥 Servidor FIREWALL - EmpresaTech

**Sistema Operacional:** Debian 13 (Trixie)  
**Função:** Gateway e proteção entre LAN, DMZ e Internet  
**Ferramenta de Firewall:** nftables  

---

## 📘 Visão Geral

O servidor **FIREWALL** é o primeiro a ser configurado na infraestrutura da EmpresaTech.  
Sua função é **interligar e proteger** as redes LAN e DMZ, além de **fornecer acesso à Internet** através de **NAT (masquerade)**.  
Também realiza o **DNAT** para permitir que servidores da DMZ (WEB01 e SYS01) sejam acessados externamente.

---

## 🌐 Configuração das Interfaces de Rede

<br/>


Edite o arquivo `/etc/network/interfaces` com o conteúdo abaixo:

```bash
sudo vim /etc/network/interfaces
```

```bash
# Interface externa (WAN - Internet)
allow-hotplug enp0s3
iface enp0s3 inet dhcp
    description "WAN - Internet"

# Interface DMZ
allow-hotplug enp0s8
iface enp0s8 inet static
    address 172.20.0.1/24
    description "DMZ"

# Interface LAN
allow-hotplug enp0s9
iface enp0s9 inet static
    address 192.168.100.1/24
    description "LAN interna"
```

<br/>

Após salvar, reinicie as interfaces:
```bash
sudo systemctl restart networking
```

<br/>

Verifique:
```bash
ip -br a
```

---

## ⚙️ Habilitar Roteamento IPv4

Edite o arquivo de configuração do kernel:

<br/>

```bash
sudo vim /etc/sysctl.d/99-custom-forwarding.conf
```

<br/>

Adicione a linha:
```bash
net.ipv4.ip_forward=1
```

<br/>

Aplicar a alteração:
```bash
sudo sysctl --system
```

---

## 🧱 Instalação do nftables

```bash
sudo apt install nftables -y
```

---

## 🧩 Configuração Principal `/etc/nftables.conf`

```bash
sudo vim /etc/nftables.conf
```

<br/>

Conteúdo completo e comentado:

```bash
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

---

## 🚀 Aplicar e Validar

Carregar a configuração:

```bash
sudo nft -f /etc/nftables.conf
```

<br/>

Listar as regras:

```bash
sudo nft list ruleset
```

<br/>

Inicializar o serviço do `nftables`

```bash
sudo systemctl enable nftables
sudo systemctl start nftables
```

---

## 🧪 Testes de Conectividade

| Origem | Destino | Comando de Teste | Esperado |
|---------|----------|------------------|-----------|
| LAN | Internet | `ping 8.8.8.8` | ✅ Resposta |
| LAN | WEB01 | `ping 172.20.0.200` | ✅ Resposta |
| LAN | SYS01 | `curl 172.20.0.201:8080` | ✅ Conexão |
| Internet | WEB01 | Acesso via navegador à porta 80/443 | ✅ Página exibida |
| Internet | SYS01 | Acesso via navegador à porta 8080 | ✅ Aplicação responde |

---

## 🪵 Logs de Segurança

Visualizar registros de pacotes bloqueados:
```bash
sudo journalctl -k -f | grep FIREWALL
```
---

## 🧭 Funções Resumidas

| Função | Descrição |
|--------|------------|
| NAT (Masquerade) | Permite LAN e DMZ acessarem a Internet |
| DNAT | Publica servidores WEB01 e SYS01 externamente |
| Filtragem | Controla acesso SSH, ICMP e conexões internas |
| Log | Gera registros de pacotes bloqueados |
| Roteamento | Interliga LAN ↔ DMZ ↔ WAN |

---

## 📄 Informações Complementares

- Interface **WAN**: `enp0s3` (DHCP público)  
- Interface **DMZ**: `enp0s8` → `172.20.0.1/24`  
- Interface **LAN**: `enp0s9` → `192.168.100.1/24`  

---

## 👨‍💻 Autor

**Fernando Dias**  
Docente de Redes e Infraestrutura de Computadores  
📘 *Ambiente didático para as UCs de Redes e Servidores Linux*  

---
