# 🖥️ Configuração do Servidor **DC01** 

## Samba Active Directory Domain Controller

---

## 🌐 1. Dados do Ambiente
| Componente | Valor |
|-----------|-------|
| Hostname | **dc01** |
| Endereço IP | **192.168.100.200/24** |
| Gateway | **192.168.100.1** |
| Domínio AD (NetBIOS) | **EMPRESATECH** |
| Realm (Kerberos) | **EMPRESATECH.EXAMPLE** |
| Zona DNS | **empresatech.example** |
| Zona reversa | **100.168.192.in-addr.arpa** |

---

## 🧩 2. Preparação Inicial do Sistema

### 2.1 Definir o hostname
```bash
sudo hostnamectl set-hostname dc01
```

<br/>

### 2.2 Configurar o arquivo `/etc/hosts`

Substitua o conteúdo por:

```
127.0.0.1        localhost
192.168.100.200  dc01.empresatech.example  dc01
```

<br/>

### 2.3 Configurar IP estático

Configure o endereço IP da interface de rede no arquivo `/etc/network/interfaces`. No nosso exemplo, a interface de rede é a `enp0s3`:

```
auto enp0s3
iface enp0s3 inet static
  address 192.168.100.200/24
  gateway 192.168.100.1
```

<br/>

### 2.4 Definir DNS temporário para conexão externa

Edite o arquivo `/etc/resolv.conf` para usarmos o DNS do Google. Essa configuração é momentânea só para o servidor ter Internet para a instalação dos pacotes do Chrony e do Samba:  

```
nameserver 8.8.8.8
```

---

## 🕒 3. Sincronização de Horário (NTP)

Instalação do Chrony:

```bash
sudo apt update
sudo apt install -y chrony
```

<br/>

No arquivo `/etc/chrony/chrony.conf`, comente a linha `pool 2.debian.pool.ntp.org iburst` e adicione os **servers** do [NTP.br](https://ntp.br/). Siga o exemplo abaixo:

```
# Use Debian vendor zone.
# pool 2.debian.pool.ntp.org iburst   # Comente esta linha

# Adicione estas linhas 
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst
```

<br/>

Reinicie e ative o serviço:

```bash
sudo systemctl restart chrony
sudo systemctl enable chrony
sudo systemctl status chrony
```

<br/>

Verifique quais servidores o **chronyd** está consultando

```bash
chronyc sources
```

<br/>

Output:

```bash
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* a.ntp.br                      2   6   377    48   +975us[+1820us] +/- 9649us
^- b.ntp.br                      2   6   377    47   -312us[ -312us] +/-   52ms
^+ c.ntp.br                      2   6   377    48  +2046us[+2890us] +/-   28ms

```

---

## 📦 4. Instalação do Samba

Instalando o Samba e suas dependências:

```bash
sudo apt-get install -y acl attr samba winbind libpam-winbind libnss-winbind krb5-config krb5-user bind9-dnsutils python3-setproctitle
```

<br/>

Durante a instalação pode ser solicitados alguns dados, responda conforme está abaixo:

- **Realm Kerberos versão 5 padrão**: Deixe em branco
- **Servidores Kerberos para seu realm**: Deixe em branco
- **Servidor administrativo para seu realm Kerberos**: Deixe em branco

<br/>

Altere novamente o arquivo `/etc/resolv.conf` com a configuração abaixo:

```bash
nameserver  192.168.100.200
nameserver  192.168.100.201
search      empresatech.example
```

--- 

##  🏗️ 5. Criação do Domínio (Provisionamento AD)

Antes de criar o domínio, faça um backup do arquivo de configuração do Samba:

```bash
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```

<br/>


Desative serviços “legados” que não se usam em AD DC:

```bash
sudo systemctl stop smbd nmbd winbind
sudo systemctl disable smbd nmbd winbind
sudo systemctl mask smbd nmbd winbind
```

<br/>

Criando o domínio:

```bash
sudo samba-tool domain provision --use-rfc2307 --domain=EMPRESATECH --realm=EMPRESATECH.EXAMPLE --adminpass='Admin@123'
```

<br/>

Caso queira alterar a senha de administrador:

```bash
sudo samba-tool user userpassword administrator
```

<br/>

Substitua o arquivo `/etc/krb5.conf` pelo `/var/lib/samba/private/krb5.conf` criado pelo Samba:

```bash
sudo cp -v /var/lib/samba/private/krb5.conf /etc/krb5.conf
```

---

## 🌍 6. Configuração do DNS Interno do Samba

Acesse o arquivo de configuração do Samba `/etc/samba/smb.conf` e altere a opção `dns forwarder = 192.168.1000.200` para `dns forwarder = 8.8.8.8`, conforme o exemplo abaixo:

```bash
# Global parameters
[global]
  # Altere a linha abaixo
	dns forwarder = 8.8.8.8
	netbios name = DC01
	realm = EMPRESATECH.EXAMPLE
	server role = active directory domain controller
	workgroup = EMPRESATECH
	idmap_ldb:use rfc2307 = yes

[sysvol]
	path = /var/lib/samba/sysvol
	read only = No

[netlogon]
	path = /var/lib/samba/sysvol/empresatech.example/scripts
	read only = No
```

<br/>

Teste os parâmetros do arquivo `smb.conf`:

```bash
sudo testparm
```

<br/>

Reinicie o serviço do Samba:

```bash
sudo systemctl restart samba-ad-dc
```

<br/>

Teste se o DNS está fazendo consultas externas:

```bash
nslookup google.com
```

<br/>

Output:

```bash
Server:		192.168.100.200
Address:	192.168.100.200#53

Non-authoritative answer:
Name:	google.com
Address: 142.251.133.78
Name:	google.com
Address: 2800:3f0:4001:80b::200e
```

<br/>

---
