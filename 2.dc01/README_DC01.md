# DC01 – Controlador de Domínio Primário (Samba 4 + Bind9)

Este documento descreve todo o processo de instalação, configuração e validação do servidor **DC01**, responsável por atuar como **Controlador de Domínio Primário (PDC)** do domínio: `empresatech.example`

<br/>

O DC01 utiliza:
- **Samba 4 (AD/DC)**
- **Bind9 com backend DLZ**
- **Chrony (NTP)**
- **Debian 13 "Trixie"**

---

## 1. 🎯 Visão Geral

O servidor **DC01** centraliza:
- Autenticação de usuários
- Gerenciamento de grupos e Unidades Organizacionais
- DNS integrado ao AD
- Sincronização de horário
- Replicação futura com DC02

---

## 2. 📌 Pré-requisitos

- Debian 13 instalado
- Acesso root (Use o comando `sudo -i`, caso necessário)
- Rede configurada
- Servidor com hostname definido como: `dc01.empresatech.example`

---

## 3. 🖥️ Configuração do Hostname

<br/>

### 3.1 Definir o hostname

```bash
hostnamectl set-hostname dc01.empresatech.example
```

<br/>

### 3.2 Configuração do arquivo `/etc/hosts`

```bash
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       dc01.empresatech.example dc01
192.168.100.200 dc01.empresatech.example dc01
```

<br/>

### 3.4 Verificar

```bash
hostname
hostname -f
```

---

## 4. 🌐 Configuração de Rede

### Arquivo `/etc/network/interfaces`

```bash
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
    address 192.168.100.200/24
    gateway 192.168.100.1
```

<br/>

### Configurar um DNS temporário `/etc/resolv.conf`

```bash
nameserver 8.8.8.8
nameserver 1.1.1.1
```

<br/>

### Aplicar a configuração de rede

```bash
systemctl restart networking
```

<br/>


### Verificar se a configuração foi aplicada

```bash
ip -br addr
ip route
ping -c 4 8.8.8.8
ping -c 4 deb.debian.org
```

---

## 5. 🕒 Configuração de Horário (NTP)

### Instalar o Chrony

```bash
apt install chrony -y
```
<br/>

### Configurar `/etc/chrony/chrony.conf`

Comente a linha `pool 2.debian.pool.ntp.org iburst` e adicione os **servers** do [NTP.br](https://ntp.br/). Siga o exemplo abaixo:

```bash
# Use Debian vendor zone.
# pool 2.debian.pool.ntp.org iburst   # Comente esta linha

# Adicione estas linhas 
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst
```

<br/>

### Reiniciar e ativar 

```bash
sudo systemctl restart chrony
sudo systemctl enable chrony
sudo systemctl status chrony
```

---

## 6. 🧱 Instalação do Samba + Bind9 DLZ

```bash
apt update && apt install samba krb5-user winbind libnss-winbind libpam-winbind bind9 bind9utils bind9-dnsutils dnsutils -y
```

Durante a instalação pode ser solicitados alguns dados, responda conforme está abaixo:

- **Realm Kerberos versão 5 padrão**: `EMPRESATECH.EXAMPLE`
- **Servidores Kerberos para seu realm**: `dc01.empresatech.example`
- **Servidor administrativo para seu realm Kerberos**: `dc01.empresatech.example`

<br/>

### Reconfigurar `/etc/resolv.conf`

```bash
nameserver  192.168.100.200
nameserver  192.168.100.201
search      empresatech.example  
```

---

## 7. 🏗️ Provisionamento do Domínio


Desative serviços “legados” que não se usam em AD DC:

```bash
systemctl stop samba-ad-dc smbd nmbd winbind
systemctl disable smbd nmbd winbind
systemctl mask smbd nmbd winbind
```

<br/>

Antes de criar o domínio, faça um backup do arquivo de configuração do Samba:

```bash
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```

<br/>

Provisionando o domínio:

```bash
samba-tool domain provision --use-rfc2307 --realm=EMPRESATECH.EXAMPLE --domain=EMPRESATECH --server-role=dc --dns-backend=BIND9_DLZ --adminpass='Admin@123'
```

---

## 8. ⚙️ Configuração Bind9 + DLZ

### Configuração completa do arquivo `/etc/bind/named.conf.options`

```bash
options {
    directory "/var/cache/bind";

    // Escutar em IPv4
    listen-on port 53 { 192.168.100.200; 127.0.0.1; };

    // Escutar em IPv6 (loopback apenas)
    listen-on-v6 port 53 { ::1; };

    // Permitir consultas de toda a LAN (DNS interno corporativo)
    allow-query { 
        192.168.100.0/24; 
        172.20.0.0/24;
        localhost;
    };

    // Permitir recursão (necessário para resolução externa)
    recursion yes;
    allow-recursion {
        192.168.100.0/24;
        172.20.0.0/24;
        localhost;
    };

    // Forwarders para resolução externa
    forwarders {
        8.8.8.8;
        1.1.1.1;
    };

    // Desabilitar DNSSEC para compatibilidade com Samba DLZ
    dnssec-enable no;
    dnssec-validation no;

    // Evita recorrência infinita em casos raros
    auth-nxdomain no;

    // Ajuste de conformidade
    minimal-responses no;

    // Permitir atualizações dinâmicas do Samba
    tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";

    // Evitar problemas com IPv6 caso a rede não use
    listen-on-v6 { any; };
};
```

<br/>

### Configuração completa do arquivo `/etc/bind/named.conf.local`
```bash
include "/var/lib/samba/bind-dns/named.conf";
```

<br/>


### Configurar permissões

```bash
chown -R bind:bind /var/lib/samba/bind-dns/
chmod 750 /var/lib/samba/bind-dns
```

---

## 9. ▶️ Ativação dos Serviços

### Reiniciar e ativar
```bash
systemctl enable --now samba-ad-dc
systemctl enable --now named
```

---

## 10. 🔍 Validação

```bash
kinit administrator
klist
host dc01.empresatech.example
host -t SRV _ldap._tcp.empresatech.example
```

---

## 11. 🗂️ Criação das Unidades Organizacionais

```bash
samba-tool ou create "OU=Vendas"
samba-tool ou create "OU=Financeiro"
samba-tool ou create "OU=TI"
samba-tool ou create "OU=Suporte"
samba-tool ou create "OU=RH"
samba-tool ou create "OU=Publico"
```

---

## 12. ✔️ Conclusão

O **DC01** está totalmente configurado como Controlador de Domínio Primário.

