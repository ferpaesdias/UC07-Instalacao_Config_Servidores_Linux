# Configuração do Servidor DC01 — Samba AD DC com BIND9_DLZ (Debian 13)

## Dados do ambiente
- Hostname: **dc01**
- IP: **192.168.100.201/24**
- Gateway: **192.168.100.1**
- Domínio NetBIOS: **EMPRESATECH**
- Realm: **EMPRESATECH.EXAMPLE**
- DNS (zona direta): **empresatech.example**
- DNS (zona reversa): **100.168.192.in-addr.arpa**
- NTP: **adm01.empresatech.example** ou **pool.ntp.org**

---

## 1. Preparação do sistema
```bash
sudo -i
hostnamectl set-hostname dc01
vim /etc/hosts
```
Adicione:
```
192.168.100.201 dc01.empresatech.example dc01
```

### IP estático
Se usar `/etc/network/interfaces`:
```
auto enp0s3
iface enp0s3 inet static
  address 192.168.100.201/24
  gateway 192.168.100.1
  dns-nameservers 192.168.100.201
  dns-search empresatech.example
```

---

## 2. Sincronização de horário (NTP)
```bash
apt update
apt install -y chrony
vim /etc/chrony/chrony.conf
```
Conteúdo:
```
server adm01.empresatech.example iburst
allow 192.168.100.0/24
rtcsync
makestep 1 3
```
Ative o serviço:
```bash
systemctl enable --now chrony
chronyc sources -v
```

---

## 3. Instalação de pacotes do AD DC com BIND9_DLZ
```bash
apt install -y samba-ad-dc krb5-user winbind bind9 bind9utils bind9-dnsutils dnsutils acl attr python3-dnspython
```

Durante a instalação do **krb5-user**, informe:
- Realm: **EMPRESATECH.EXAMPLE**
- Servidor KDC: **dc01.empresatech.example**
- Servidor de administração: **dc01.empresatech.example**

---

## 4. Desative serviços Samba não usados
```bash
systemctl stop smbd nmbd winbind || true
systemctl disable smbd nmbd winbind || true
systemctl mask smbd nmbd winbind || true
```

---

## 5. Provisionamento do domínio com backend BIND9_DLZ
```bash
mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp

samba-tool domain provision   --use-rfc2307   --realm=EMPRESATECH.EXAMPLE   --domain=EMPRESATECH   --server-role=dc   --dns-backend=BIND9_DLZ   --adminpass='SenhaForte#2025'
```

---

## 6. Configuração do Kerberos
```bash
mv /etc/krb5.conf /etc/krb5.conf.bkp
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
```

---

## 7. Configuração do BIND9_DLZ
Edite o arquivo principal:
```bash
vim /etc/bind/named.conf
```
Adicione no final:
```
include "/var/lib/samba/bind-dns/named.conf";
```

Verifique o conteúdo do arquivo incluído (ele é gerado pelo Samba e contém a configuração DLZ).

### Ajuste de permissões
```bash
chown -R bind:bind /var/lib/samba/bind-dns
chmod 770 /var/lib/samba/bind-dns
```

### Adapte o AppArmor (se ativo)
Edite `/etc/apparmor.d/usr.sbin.named` e adicione:
```
/var/lib/samba/bind-dns/** rwk,
```
Depois:
```bash
apparmor_parser -r /etc/apparmor.d/usr.sbin.named
```

Reinicie o BIND:
```bash
systemctl enable --now bind9
systemctl status bind9
```

---

## 8. Configuração do Samba AD DC
Verifique `/etc/samba/smb.conf`:
```
[global]
    workgroup = EMPRESATECH
    realm = EMPRESATECH.EXAMPLE
    netbios name = DC01
    server role = active directory domain controller
    dns forwarder = 8.8.8.8

[sysvol]
    path = /var/lib/samba/sysvol
    read only = No

[netlogon]
    path = /var/lib/samba/sysvol/empresatech.example/scripts
    read only = No
```

Ative o serviço AD DC:
```bash
systemctl enable --now samba-ad-dc
```

---

## 9. Testes
```bash
systemctl status samba-ad-dc
host -t A dc01.empresatech.example 127.0.0.1
host -t SRV _ldap._tcp.empresatech.example 127.0.0.1
kinit administrator@EMPRESATECH.EXAMPLE
klist
samba-tool drs showrepl
```

---

## 10. Firewall básico (nftables)
```bash
nft add rule inet filter input iifname "enp0s3" ip saddr 192.168.100.0/24 tcp dport (53, 88, 135, 139, 389, 445, 464, 3268, 3269) accept
nft add rule inet filter input iifname "enp0s3" ip saddr 192.168.100.0/24 udp dport (53, 88, 123, 137, 138, 389, 464) accept
```

---

## 11. Criar zonas DNS reversas (caso não criadas)
```bash
samba-tool dns zonecreate dc01.empresatech.example 100.168.192.in-addr.arpa -U "administrator"
samba-tool dns add dc01.empresatech.example 100.168.192.in-addr.arpa 201 PTR dc01.empresatech.example -U "administrator"
```

---

## 12. Criar usuários de teste
```bash
samba-tool user create fernando 'Senha.Forte#2025' --use-username-as-cn --given-name="Fernando" --surname="Dias"
samba-tool group addmembers "Domain Admins" fernando
```

---

## 13. Backup básico
Diretórios importantes:
```
/etc/samba/
/var/lib/samba/
/var/lib/samba/sysvol/
/var/lib/samba/bind-dns/
```
Recomenda-se snapshot da VM após provisionamento.

---

**Servidor DC01 configurado com sucesso com BIND9_DLZ no Debian 13!**

Gerado em 10/11/2025 18:51
