# Configuração do Servidor DC01 — Samba AD DC (Debian 13)

## Dados do ambiente
- Hostname: **dc01**
- IP: **192.168.100.200/24**
- Gateway: **192.168.100.1**
- Domínio NetBIOS: **EMPRESATECH**
- Realm: **EMPRESATECH.EXAMPLE**
- DNS (zona direta): **empresatech.example**
- DNS (zona reversa): **100.168.192.in-addr.arpa**
---

## 1. Preparação do sistema

### Hostname 

Altere o `hostname` do servidor para `dc01`:
```bash
sudo hostnamectl set-hostname dc01
```

<br/>

Apague o conteúdo do arquivo `/etc/hosts/` e adicione as linhas abaixo:

```
127.0.0.1        localhost
192.168.100.200  dc01.empresatech.example  dc01
```

<br/>

### IP estático

Configure sua rede em `/etc/network/interfaces`:

```
auto enp0s3
iface enp0s3 inet static
  address 192.168.100.201/24
  gateway 192.168.100.1
```

<br>

### DNS

Altere DNS do servidor no arquivo `/etc/resolv.conf` para consultar o DNS do Google (ou outro que desejar). Essa alteração é temporária para termos acesso à Internet, depois iremos reconfigurar este arquivo com o endereço correto:  

```
nameserver  8.8.8.8
```
---

## 2. Sincronização de horário (NTP)
```bash
sudo apt update
sudo apt install -y chrony
sudo vim /etc/chrony/chrony.conf
```

<br/>

Comente a linha `pool 2.debian.pool.ntp.org iburst` e adicione os **servers** do [NTP.br](https://ntp.br/). Siga o exemplo abaixo:

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

## 3. Instalação do Samba

Instalando o Samba e suas dependências:

```bash
sudo apt-get install -y acl attr samba winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils python3-setproctitle
```

<br/>

Durante a instalação serão solicitados alguns dados, responda conforme está abaixo:

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

## 4. Criação do domínio

Antes de criar o domínio, faça um backup do arquivo de configuração do Samba:

```bash
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```

<br/>

Criando o domínio:

```bash
sudo samba-tool domain provision --use-rfc2307 --domain=EMPRESATECH --realm=EMPRESATECH.EXAMPLE
```
