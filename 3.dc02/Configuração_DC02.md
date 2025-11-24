# 🖥️ Configuração do Servidor **DC02** 

## Samba Active Directory Domain Controller

---

## 🌐 1. Dados do Ambiente
| Componente | Valor |
|-----------|-------|
| Hostname | **dc02** |
| Endereço IP | **192.168.100.201/24** |
| Gateway | **192.168.100.1** |
| Domínio AD (NetBIOS) | **EMPRESATECH** |
| Realm (Kerberos) | **EMPRESATECH.EXAMPLE** |
| Zona DNS | **empresatech.example** |
| Zona reversa | **100.168.192.in-addr.arpa** |

---

## 🧩 2. Preparação Inicial do Sistema

### 2.1 Definir o hostname
```bash
sudo hostnamectl set-hostname dc02
```

<br/>

### 2.2 Configurar o arquivo `/etc/hosts`

Substitua o conteúdo por:

```
127.0.0.1        localhost
192.168.100.201  dc02.empresatech.example  dc02
```

<br/>

### 2.3 Configurar IP estático

Configure o endereço IP da interface de rede no arquivo `/etc/network/interfaces`. No nosso exemplo, a interface de rede é a `enp0s3`:

```
auto enp0s3
iface enp0s3 inet static
  address 192.168.100.201/24
  gateway 192.168.100.1
```

<br/>

### 2.4 Definir DNS

Edite o arquivo `/etc/resolv.conf`: 

```
nameserver  192.168.100.201
nameserver  192.168.100.200
domain      empresatech.example
search      empresatech.example
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

--- 

##  🏗️ 5. Promovendo servidor Samba a Domain Controller

Faça um backup do arquivo `/etc/krb5.conf`:

```bash
sudo mv /etc/krb5.conf /etc/krb5.conf.bkp
```

<br/>

Edite o arquivo `/etc/krb5.conf` com o conteúdo abaixo:

```bash
[libdefaults]
  default_realm = EMPRESATECH.EXAMPLE
  dns_lookup_realm = false
  dns_lookup_kdc = true
```

<br/>

Teste com o comando:

```bash
kinit administrator
```
Será solicitada a senha do usuário *administrator* (administrador do domínio).

<br/>

A saída do comando será semelhante a abaixo:

```bash
Warning: Your password will expire in 38 days on dom 28 dez 2025 10:31:38
```

<br/>

Em seguida use o comando abaixo para verificar o ticket Kerberos criado com o comando acima:

```bash
klist
```
Kerberos é o sistema de autenticação usado pelo Active Directory.
É um comando usado para ver os tickets Kerberos que estão armazenados no computador.

<br/>

A saída será igual a esta:

```bash
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: administrator@EMPRESATECH.EXAMPLE

Valid starting       Expires              Service principal
19/11/2025 10:43:16  19/11/2025 20:43:16  krbtgt/EMPRESATECH.EXAMPLE@EMPRESATECH.EXAMPLE
	renew until 20/11/2025 10:43:13
```

<br/>

Desative serviços “legados” que não se usam em AD DC:

```bash
sudo systemctl stop smbd nmbd winbind
sudo systemctl disable smbd nmbd winbind
sudo systemctl mask smbd nmbd winbind
```

<br/>

Faça um backup do arquivo de configuração do Samba:

```bash
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```

<br/>

Ingressar o servidor DC02 no domínio:

```bash
sudo samba-tool domain join empresatech.example DC --dns-backend=SAMBA_INTERNAL -U "EMPRESATECH\Administrator"
```

- **samba-tool domain join**: Instrução para ingressar o servidor no domínio.
- **empresatech.example**: É o realm/DNS do domínio AD ao qual o novo servidor vai se juntar.
- **DC**: Define o papel do servidor. *DC* significa que o servidor será um Controlador de Domínio.
- **--dns-backend=SAMBA_INTERNAL**: Define qual DNS o novo DC usará. *SAMBA_INTERNAL* é o DNS interno do Samba
- **-U "EMPRESATECH\Administrator"**: Usuário usado para autenticar a entrada no domínio.
---


## 🌍 6. Configuração do DNS Interno do Samba

Acesse o arquivo de configuração do Samba `/etc/samba/smb.conf` e insira o parâmetro `dns forwarder = 8.8.8.8` abaixo de `workgroup = EMPRESATECH`, conforme o exemplo abaixo:

```bash
# Global parameters
[global]
	netbios name = DC02
	realm = EMPRESATECH.EXAMPLE
	server role = active directory domain controller
	workgroup = EMPRESATECH
	dns forwarder = 8.8.8.8

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
Server:		192.168.100.201
Address:	192.168.100.201#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.78.142
Name:	google.com
Address: 2800:3f0:4001:80e::200e
```

<br/>

---
