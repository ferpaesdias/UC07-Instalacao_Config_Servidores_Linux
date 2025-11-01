# Servidor ADM01 — Servidor de Administração e Sincronização

## 📘 Descrição

O **ADM01** é o servidor de **administração** da rede LAN da empresa fictícia **Empresatech**.  
Ele é responsável por permitir o **acesso remoto seguro via SSH**, realizar a **sincronização de tempo (NTP)** na rede por meio do **Chrony**, e atuar como ponto central de administração local.  
Conta ainda com **nftables** para controle de tráfego local e **fail2ban** para proteção contra tentativas de login indevidas.

---

## 🖥️ Informações do Servidor

| Item | Valor |
|------|-------|
| Hostname | **adm01.empresatech.example** |
| IP | **192.168.100.200** |
| Rede | **LAN — 192.168.100.0/24** |
| Gateway | **192.168.100.1** (Firewall) |
| DNS | **192.168.100.201** (DNS01) |
| Sistema Operacional | **Debian 13 (Trixie)** |
| Funções principais | SSH, Chrony (NTP), Firewall local (nftables), Fail2Ban |
| Acesso remoto | `ssh admin@192.168.100.200` |

---

## ⚙️ Instalação das Ferramentas

Atualize os repositórios e instale os pacotes necessários:

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y vim curl git htop unzip tmux bash-completion ca-certificates \
                    openssh-server chrony nftables fail2ban
```

Verifique as versões instaladas:

```bash
chronyd --version
ssh -V
nft --version
```

Ative os serviços principais:

```bash
sudo systemctl enable --now ssh
sudo systemctl enable --now chrony
sudo systemctl enable --now nftables
sudo systemctl enable --now fail2ban
```

---

## 🧱 Estrutura dos Serviços

```plaintext
ADM01
├── SSH (22/TCP)
├── Chrony (NTP server)
├── nftables (Firewall local)
└── Fail2Ban (proteção SSH)
```

---

## ⚙️ Configuração da Rede

Arquivo `/etc/network/interfaces.d/ens18`:

```bash
auto ens18
iface ens18 inet static
  address 192.168.100.200/24
  gateway 192.168.100.1
  dns-nameservers 192.168.100.201 1.1.1.1
  dns-search empresatech.example
```

Reinicie o serviço:

```bash
sudo systemctl restart networking
```

---

## 🔐 SSH

Arquivo `/etc/ssh/sshd_config` (principais diretivas):

```bash
PermitRootLogin prohibit-password
PasswordAuthentication yes
AllowUsers admin
```

Ativar o serviço:

```bash
sudo systemctl enable --now ssh
```

---

## 🧍 Usuário Administrador

```bash
sudo adduser admin
sudo usermod -aG sudo admin
```

Para acesso via chave pública:

```bash
sudo mkdir -p /home/admin/.ssh
sudo chmod 700 /home/admin/.ssh
sudo nano /home/admin/.ssh/authorized_keys
# cole sua chave SSH
sudo chmod 600 /home/admin/.ssh/authorized_keys
sudo chown -R admin:admin /home/admin/.ssh
```
---

## 🕒 Servidor NTP (Chrony)

Arquivo `/etc/chrony/chrony.conf`:

```bash
pool br.pool.ntp.org iburst
allow 192.168.100.0/24
local stratum 10
driftfile /var/lib/chrony/chrony.drift
rtcsync
makestep 1.0 3
logdir /var/log/chrony
noclientlog
```

Verificação:

```bash
chronyc tracking
chronyc sources -v
```

Os clientes da LAN podem ser configurados para usar o ADM01 como servidor NTP (`server 192.168.100.200 iburst`).

---

## 🔥 nftables (firewall local)

Arquivo `/etc/nftables.conf`:

```bash
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
  set lan {
    type ipv4_addr;
    flags interval;
    elements = { 192.168.100.0/24  }
  }

  chain input {
    type filter hook input priority 0;
    policy drop;

    iifname "lo" accept
    ct state {established,related} accept
    ct state invalid drop
    ip protocol icmp accept

    ip saddr @lan tcp dport 22 accept
    ip saddr @lan udp dport 123 accept
    udp dport 68 accept
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;
  }
  
  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}
```

Ativar:

```bash
sudo systemctl enable --now nftables
sudo nft list ruleset
```

---

## 🛡️ Fail2Ban

Arquivo `/etc/fail2ban/jail.d/ssh.local`:

```bash
[sshd]
enabled = true
maxretry = 5
bantime = 30m
findtime = 10m
```

Reinicie o serviço:

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

---

## 🧩 Verificações

```bash
hostname -f
ping -c2 192.168.100.1
chronyc tracking
sudo nft list ruleset
sudo fail2ban-client status
```

---

## 🧾 Estrutura do Repositório

```plaintext
├── README_ADM01.md
├── Imagens/
│   └── diag_rede_linux.jpg
└── Scripts/
    └── bootstrap_adm01.sh
```

---

## 📜 Script de Instalação Automática

> Arquivo: `Scripts/bootstrap_adm01.sh`

```bash
sudo bash ./Scripts/bootstrap_adm01.sh
```

---

## 🧠 Observações

- O ADM01 atua como **ponto de acesso administrativo** para a rede LAN.  
- Sincroniza o tempo dos dispositivos da rede usando **Chrony**.  
- Possui **firewall local (nftables)** e **proteção de login (fail2ban)**.  
- É o servidor base para manutenção e monitoramento de conectividade.

---

## 🧑‍🏫 Autor

**Professor:** Fernando Dias  
**Curso:** Técnico em Informática – UC07  
**Ano:** 2025 