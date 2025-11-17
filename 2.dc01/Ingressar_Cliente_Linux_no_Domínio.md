# 🐧 Ingressar um PC Linux (Debian) no Domínio Active Directory  

---

## 🕒 1. Sincronização de Horário (Obrigatória para Kerberos)

Antes de qualquer passo, o PC Linux **deve estar com o relógio sincronizado** com o DC01.  
O Kerberos recusa conexões se houver diferença maior que 5 minutos.
Usaremos o serviço padrão: **systemd-timesyncd**.  

<br/>

Abra o arquivo `/etc/systemd/timesyncd.conf` e descomente a linha `#NTP=` e insira o IP do DC01, que também tem a função de servidor de horário (NTP). Veja o exemplo abaixo:

```bash
[Time]
NTP=192.168.100.200
```

<br/>

Habilite (caso não esteja habilitado) e reinicie o serviço `systemd-timesyncd`:

```bash
sudo systemctl enable systemd-timesyncd
sudo systemctl restart systemd-timesyncd
```

<br/>


Verifique o status da sincronização:

```bash
timedatectl timesync-status
```

<br/>

Output:

```bash
       Server: 192.168.100.200 (192.168.100.200)
Poll interval: 32s (min: 32s; max 34min 8s)
 Packet count: 0
```

---

## 🌐 2. Ingressando o Debian no Domínio


### 2.1 Instalar pacotes necessários

Estes pacotes fazem o Linux:

- descobrir o domínio  
- autenticar usuários  
- integrar Kerberos e LDAP  

Instale tudo com:

```bash
sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin
```

<br/>

### 2.2 Descobrir o domínio

Use o comando:

```bash
sudo realm discover empresatech.example -v
```

<br/>


Output:

```bash
 * Resolving: _ldap._tcp.empresatech.example
 * Performing LDAP DSE lookup on: 192.168.100.200
 * Successfully discovered: empresatech.example
empresatech.example
  type: kerberos
  realm-name: EMPRESATECH.EXAMPLE
  domain-name: empresatech.example
  configured: no
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: sssd
  required-package: libnss-sss
  required-package: libpam-sss
  required-package: adcli
  required-package: samba-common-bin
```

<br/>

### 2.3 Ingressar no domínio


```bash
sudo realm join empresatech.example --user=administrator --client-software=sssd --os-name="Debian Gnome Desktop" --os-version="Trixie (13)" -v
```

- Digite a senha do administrador quando solicitado.  
- Se não aparecer nenhum erro → o computador já entrou no domínio.

---

## 🗂️ 3. Configurando o SSSD

O SSSD é o serviço que permitirá login de usuários do AD dentro do Linux.

<br/>

Acesse o arquivo `/etc/sssd/sssd.conf` e adicione as duas últimas linhas que estão no exemplo abaixo:

```bash
[sssd]
domains = empresatech.example
config_file_version = 2
services = nss, pam

[domain/empresatech.example]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = EMPRESATECH.EXAMPLE
realmd_tags = manages-system joined-with-adcli 
id_provider = ad
fallback_homedir = /home/%u@%d
ad_domain = empresatech.example
use_fully_qualified_names = True
ldap_id_mapping = True
access_provider = ad
override_homedir = /home/%d/%u
default_domain_suffix = empresatech.example
```

<br/>

Habilite (caso não esteja habilitado) e reinicie o serviço `sssd`:

```bash
sudo systemctl enable sssd
sudo systemctl restart sssd
```

---

## 👤 4. Ajustando o PAM (Criação automática do diretório HOME)

Sempre que um usuário do AD fizer login, o Debian deve criar seu diretório `home`.

<br/>

### 4.1 Editar a configuração do `mkhomedir`

```bash
Name: Create home directory on login
Default: no
Priority: 0
Session-Type: Additional
Session-Interactive-Only: yes
Session:
	optional			pam_mkhomedir.so	umask=077
```

<br/>

### 4.2 Habilitar via pam-auth-update
Execute:
```
sudo pam-auth-update
```

<br/>

Marque:
- [*] SSS authentication  
- [*] Create home directory on login  

Isso ativa a criação automática do `/home` dos usuários de domínio.

---
