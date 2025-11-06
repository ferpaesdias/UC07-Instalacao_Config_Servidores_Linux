# 🧰 Configuração Detalhada – Servidor ADM01
**Função:** Administração e Monitoramento  
**IP:** `192.168.100.200`  
**Hostname:** `adm01.empresatech.example`  
**Serviços:** SSH, Ansible, Chrony (NTP), Cockpit (opcional)

---

## 1️⃣ Configuração Inicial do Sistema

```bash
sudo apt update && sudo apt full-upgrade -y
sudo timedatectl set-timezone America/Sao_Paulo
sudo hostnamectl set-hostname adm01
```

<br/>

### `/etc/hosts`
```bash
127.0.0.1   localhost
192.168.100.200  adm01.empresatech.example adm01
192.168.100.201  dc01.empresatech.example dc01
192.168.100.202  dhcp01.empresatech.example dhcp01
192.168.100.203  fs01.empresatech.example fs01
172.20.0.200     web01.empresatech.example web01
172.20.0.201     sys01.empresatech.example sys01
```

---

## 2️⃣ Configuração de Rede Estática (interface LAN)

Arquivo `/etc/network/interfaces.d/enp0s3` ou equivalente em `/etc/systemd/network/`.

```bash
auto enp0s3
iface enp0s3 inet static
    address 192.168.100.200/24
    gateway 192.168.100.1
    dns-nameservers 192.168.100.201 1.1.1.1
```

<br/>

Reinicie a rede:
```bash
sudo systemctl restart networking
```

---

## 3️⃣ Acesso Remoto Seguro (SSH)

```bash
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
```
<br/>


Verifique:
```bash
sudo systemctl status ssh
ss -tlnp | grep ssh
```

---

## 4️⃣ Servidor NTP – **Chrony**

O ADM01 servirá como **servidor de tempo interno**.

```bash
sudo apt install chrony -y
```

<br/>

Crie uma cópia de arquivo de configuração

```bash
sudo mv /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bkp
```

<br/>

Editar o arquivo `/etc/chrony/chrony.conf`:

```bash
# /etc/chrony/chrony.conf
# ============================================================
# Configuração do servidor ADM01 - EmpresaTech
# Função: Servidor de tempo (NTP) da rede LAN 192.168.100.0/24
# ============================================================

# ------------------------------------------------------------
# 1. Servidores públicos de referência (fontes primárias)
# ------------------------------------------------------------
# Utilize servidores confiáveis da rede NTP brasileira (pool.ntp.br)
# O parâmetro 'iburst' acelera a sincronização inicial
server a.st1.ntp.br iburst
server b.st1.ntp.br iburst
server c.st1.ntp.br iburst

# ------------------------------------------------------------
# 2. Permitir clientes da LAN sincronizarem com este servidor
# ------------------------------------------------------------
# Somente os hosts da rede interna terão permissão para acessar o NTP
allow 192.168.100.0/24

# ------------------------------------------------------------
# 3. Servidor local (stratum 10)
# ------------------------------------------------------------
# Caso o ADM01 perca conexão com os servidores públicos,
# ele continuará oferecendo sincronismo local
local stratum 10

# ------------------------------------------------------------
# 4. Freqüência e driftfile
# ------------------------------------------------------------
# Armazena o valor de correção de frequência do relógio
driftfile /var/lib/chrony/chrony.drift

# ------------------------------------------------------------
# 5. Diretório de logs
# ------------------------------------------------------------
# Guarda estatísticas, tracking e medições
log tracking measurements statistics
logdir /var/log/chrony

# ------------------------------------------------------------
# 6. Correção manual (opcional)
# ------------------------------------------------------------
# Se desejar ajustar manualmente o tempo com 'chronyc makestep'
# durante a inicialização, habilite:
makestep 1.0 3

# ------------------------------------------------------------
# 7. Segurança e rede
# ------------------------------------------------------------
# Porta padrão NTP é 123/UDP
port 123

# Permitir respostas a consultas de tracking
cmdallow 127.0.0.1
cmdallow 192.168.100.0/24
```

<br/>

Reinicie o serviço:
```bash
sudo systemctl restart chrony
sudo chronyc sources -v
```

---

## 5️⃣ Instalação do **Ansible** (controle remoto de servidores)

```bash
sudo apt install ansible -y
```

<br/>

Criar inventário `/etc/ansible/hosts`:
```ini
[dc]
192.168.100.201

[dhcp]
192.168.100.202

[fs]
192.168.100.203

[dmz]
172.20.0.200
172.20.0.201

[all:vars]
ansible_user=admin
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

<br/>

Teste de conexão:
```bash
ansible all -m ping
```

---

## 6️⃣ Gerenciamento Web (opcional) – **Cockpit**

```bash
sudo apt install cockpit -y
sudo systemctl enable --now cockpit.socket
```

<br/>

Acesse pelo navegador:  
👉 `https://192.168.100.200:9090`

---

## 7️⃣ Sincronismo Automático com os Demais Servidores

Para forçar os demais servidores (DC01, DHCP01, FS01) a sincronizarem com o ADM01, adicione neles no `/etc/chrony/chrony.conf`:
```bash
server 192.168.100.200 iburst
```

---

## 8️⃣ Scripts de Administração (Sugestão)

Crie `/opt/scripts/update_all.sh`:
```bash
#!/bin/bash
ansible all -m apt -a "update_cache=yes upgrade=yes" -b
```

<br/>

Dê permissão:
```bash
chmod +x /opt/scripts/update_all.sh
```

---

## 🔐 Segurança Recomendada

- Desabilitar login root via SSH:
  ```bash
  sudo nano /etc/ssh/sshd_config
  # PermitRootLogin no
  sudo systemctl restart ssh
  ```

<br/>

- Gerar e usar **chave pública/privada** para acesso do ADM01 aos demais servidores:
  ```bash
  ssh-keygen -t rsa -b 4096
  ssh-copy-id admin@dc01
  ssh-copy-id admin@dhcp01
  ssh-copy-id admin@fs01
  ```

---

## 🔎 Verificação Final

```bash
sudo hostnamectl
ip a
chronyc tracking
ansible all -m ping
```

---

## 📘 Resumo

| Serviço | Pacote | Porta | Função |
|----------|---------|--------|--------|
| SSH | `openssh-server` | 22 | Administração remota |
| NTP | `chrony` | 123/UDP | Sincronismo de tempo |
| Ansible | `ansible` | SSH | Gerência de configuração |
| Cockpit | `cockpit` | 9090 | Gerência via web |
