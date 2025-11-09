# Configuração: DC01 (Samba AD + BIND9)

Este guia detalha a instalação e configuração do `DC01` como um Controlador de Domínio Active Directory (AD DC) usando Samba 4.

Esta configuração utiliza o BIND9 como *backend* de DNS, permitindo que o Samba gira dinamicamente os registos DNS (como é padrão no Active Directory) através do BIND9.

## 📋 Parâmetros

* **Hostname:** `DC01`
* **IP:** `192.168.100.201/24`
* **Gateway:** `192.168.100.1` (Firewall)
* **Domínio:** `empresatech.example`
* **Realm:** `EMPRESATECH.EXAMPLE`
* **NTP (ADM01):** `192.168.100.200`
* **OS:** Debian 13 (Trixie)

---

## Passo 1: Pré-configuração do Sistema

Antes de instalar o Samba, o servidor precisa de ter um IP estático, *hostname* correto e, o mais importante, **sincronismo de tempo**. O protocolo de autenticação Kerberos (usado pelo AD) não tolera diferenças de tempo.

<br/>

### 1.1. Configurar IP Estático

Define o IP estático do servidor. (Este exemplo usa `ifupdown`, certifica-te que o pacote `ifupdown` está instalado).

```bash
sudo vim /etc/network/interfaces
```

<br/>

Adiciona a configuração conforme sua interface (ex: enp0s3 ou eth0):

```bash
# /etc/network/interfaces

auto lo
iface lo inet loopback

# Interface da LAN (DC01)
auto enp0s3
iface enp0s3 inet static
    address 192.168.100.201/24
    gateway 192.168.100.1
```

<br/>

Por agora, vamos configurar o DNS `8.8.8.8` para conseguirmos instalar os pacotes.

```bash
sudo vim /etc/resolv.conf
```

<br/>

Substitua todo o conteúdo por isto:

```bash
nameserver 8.8.8.8
```

<br/>

Depois, reinicie o serviço de rede:

```bash
sudo systemctl restart networking
```

<br/>

### 1.2. Configurar Hostname e /etc/hosts

O servidor deve conhecer o seu próprio nome (FQDN - Nome de Domínio Totalmente Qualificado).

```bash
# Define o hostname
sudo hostnamectl set-hostname dc01.empresatech.example

# Edita o arquivo de hosts
sudo vim /etc/hosts
```

<br/>

O arquivo /etc/hosts deve ter esta aparência:

```bash
127.0.0.1       localhost
192.168.100.201 dc01.empresatech.example dc01

# Opcional, mas recomendado
192.168.100.200 adm01.empresatech.example adm01
```

<br/>

### 1.3. Sincronizar o Tempo (Chrony)

Vamos apontar o chrony para o nosso servidor NTP (ADM01) para manter o relógio sincronizado.

```bash
# Atualiza os pacotes e instala o chrony
sudo apt update
sudo apt install chrony -y

# Edita o arquivo de configuração
sudo vim /etc/chrony/chrony.conf
```

<br/>

Dentro do chrony.conf, comenta as linhas padrão pool ... e adiciona o teu servidor ADM01:

```bash
# Comenta estas linhas
# pool 2.debian.pool.ntp.org iburst
# ...

# Adiciona o servidor NTP da LAN
server 192.168.100.200 iburst
```

<br/>

Reinicia o serviço e verifica a sincronia:

```bash
sudo systemctl restart chrony
chronyc sources
```

<br/>

A saída do comando será semelhante a abaixo:

```bash
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* adm01.empresatech.example    10   6    17     6  -3595ns[  +67ms] +/-  145u
```

---

## Passo 2: Instalação dos Pacotes

Agora, instalamos o Samba, BIND9 e todos os utilitários necessários.

```bash
sudo apt install samba krb5-user krb5-config winbind smbclient bind9 bind9-utils bind9-dnsutils -y
```

<br/>

Durante a instalação do krb5-user, serás questionado:

* **Reino Kerberos Padrão**: EMPRESATECH.EXAMPLE
* **Servidores Kerberos para seu realm**: dc01.empresatech.example
* **Servidor administrativo para o seu realm Kerberos**: dc01.empresatech.example

---

## Passo 3: Parar Serviços e Provisionar o Domínio

Esta é a etapa principal, onde o `samba-tool` cria o Active Directory.

<br/>

### 3.1. Parar e Desabilitar Serviços

Antes de provisionar, todos os serviços relacionados devem estar parados para que o Samba possa configurá-los do zero.

```bash
sudo systemctl stop samba-ad-dc smbd nmbd winbind named
sudo systemctl disable samba-ad-dc smbd nmbd winbind named
```

<br/>

### 3.2. Limpar Configurações Antigas (Se necessário)

Se esta for uma segunda tentativa, limpe os arquivos antigos. Se for a primeira instalação, pode ignorar isto.

```bash
# Apenas se o provisionamento falhou antes
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.backup
sudo mv /var/lib/samba/private /var/lib/samba/private.backup
```

<br/>

### 3.3. Provisionar o Domínio

Este comando cria o domínio, define o backend de DNS e a senha do Administrador.

```bash
sudo samba-tool domain provision \
  --use-rfc2307 \
  --realm=EMPRESATECH.EXAMPLE \
  --domain=EMPRESATECH \
  --server-role=dc \
  --dns-backend=BIND9_DLZ \
  --adminpass=SuaSenhaForteAqui!
```

Explicação dos parâmetros:
* `--use-rfc2307`: Adiciona atributos POSIX ao AD (essencial para clientes Linux).
* `--realm`: O nome Kerberos (Maiúsculas).
* `--domain`: O nome NetBIOS (Curto).
* `--server-role=dc`: Define este servidor como um Controlador de Domínio.
* `--dns-backend=BIND9_DLZ`: Instrui o Samba a gerar os arquivos de configuração para o BIND9.
* `--adminpass=`: Define a senha de administrador.

---

## Passo 4: Configuração do BIND9 (DNS)

O Samba provisionou o domínio, mas agora o BIND9 precisa de ser configurado para "ler" as zonas de DNS diretamente do Samba.

<br/>

### 4.1. Corrigir o `named.conf.local`

Dizemos ao BIND9 para incluir o arquivo de configuração que o Samba acabou de criar.


```bash
sudo vim /etc/bind/named.conf.local
```

<br/>

Apague qualquer conteúdo e adicione apenas estas linhas:

```bash
// Configuração do Samba AD DLZ
include "/var/lib/samba/bind-dns/named.conf";
```

<br/>

### 4.2. Configurar o `named.conf.options`

Configuramos *forwarders* (para onde o BIND9 pergunta sobre domínios externos, como `google.com`) e permissões.


```bash
sudo vim /etc/bind/named.conf.options
```

<br/>

Apague qualquer conteúdo e adicione estas linhas:

```bash
options {
    directory "/var/cache/bind";

    // Define os forwarders (para onde o BIND9 pergunta sobre domínios externos)
    forwarders {
        192.168.100.1; // Gateway/Firewall
        8.8.8.8;       // DNS Público (Google)
    };

    // Permite que o Samba (via Kerberos) atualize o DNS
    tkey-gssapi-keytab "/var/lib/samba/private/dns.keytab";

    // Define quem pode consultar o DNS (LAN, DMZ e o próprio servidor)
    allow-query {
        127.0.0.1;
        192.168.100.0/24;
        172.20.0.0/24;
    };
    
    // Interfaces que o BIND irá escutar
    listen-on { 
        127.0.0.1;
        192.168.100.201;
    };
    
    // Desativa IPv6 
    listen-on-v6 { 
        none; 
    };

    // Restrições de recursão (quem pode pedir ao BIND9 para consultar
    // domínios externos). Deve ser igual ou mais restrito que 'allow-query'.
    allow-recursion {
        127.0.0.1;
        192.168.100.0/24;
        172.20.0.0/24;
    };

    // O BIND deve seguir a autoridade de zona
    dnssec-validation auto;

};
```
---

## Passo 5: Configuração Final do Sistema

Os últimos ajustes para garantir que o próprio DC01 consegue autenticar-se e resolver nomes.

<br/>

### 5.1. Copiar Configuração Kerberos

O Samba gerou um arquivo krb5.conf. Vamos usá-lo como o padrão do sistema.

```bash
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
```

<br/>

### 5.2. Configurar o `resolv.conf`

O servidor **DC01** deve, obrigatoriamente, usar a si mesmo para DNS. 

```bash
sudo vim /etc/resolv.conf
```

<br/>

Substitui todo o conteúdo por isto:

```bash
domain empresatech.example
search empresatech.example
nameserver 192.168.100.201
```

<br/>

**Importante**: Para evitar que o `systemd-resolved` ou o `networking` sobrescrevam este arquivo, vamos torná-lo "imutável":

```bash
sudo chattr +i /etc/resolv.conf
```

<br/>

Depois, reinicie o serviço de rede:

```bash
sudo systemctl restart networking
```

---

## Passo 6: Iniciar e Validar os Serviços

Estamos prontos para iniciar e testar.

<br/>

### 6.1. Iniciar e Habilitar

```bash
sudo systemctl unmask samba-ad-dc

sudo systemctl enable samba-ad-dc
sudo systemctl enable named

sudo systemctl restart named
sudo systemctl restart samba-ad-dc
```

<br/>


### 6.2. Validar o BIND9

Verifica se o BIND9 está a funcionar sem erros:

```bash
sudo systemctl status named
```

<br/>

### 6.3. Validar o DNS (Registros do AD)

Testa se o BIND9 está a responder com os registros do Active Directory.

<br/>

* Testa se o Kerberos está registrado (autenticação)

```bash
host -t SRV _kerberos._tcp.empresatech.example
```

Deve retornar:

```bash
_kerberos._tcp.empresatech.example has SRV record 0 100 88 dc01.empresatech.example.
```

<br/>

* Testa se o LDAP está registado (serviço de diretório)

```bash
host -t SRV _ldap._tcp.empresatech.example
```

Deve retornar:
```bash
_ldap._tcp.empresatech.example has SRV record 0 100 389 dc01.empresatech.example.
```

<br/>

* Testa o registro A do próprio DC

```bash
host -t A dc01.empresatech.example
```

Deve retornar: 

```bash
dc01.empresatech.example has address 192.168.100.201
```

<br/>

### 6.4. Validar o Kerberos (Autenticação)

Tenta obter um "bilhete" de autenticação como o Administrador do domínio. Use a senha de *administrador* definida no **Passo 3.3**.

```bash
kinit administrator@EMPRESATECH.EXAMPLE
```

<br/>

Deve retornar uma mensagem semelhante a abaixo: 

```bash
Warning: Your password will expire in 41 days on dom 21 dez 2025 10:57:58
```

<br/>

Verifique o "bilhete".

```bash
klist
```

<br/>

Deve mostrar um bilhete válido para 'administrator':

```bash
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: administrator@EMPRESATECH.EXAMPLE

Valid starting       Expires              Service principal
09/11/2025 11:43:07  09/11/2025 21:43:07  krbtgt/EMPRESATECH.EXAMPLE@EMPRESATECH.EXAMPLE
	renew until 10/11/2025 11:42:48
```

<br/>

### 6.5. Validar o Samba

Verifica a saúde geral da base de dados do AD.

```bash
sudo samba-tool dbcheck
```

<br/>

Deve retornar uma mensagem semelhante a abaixo: 

```bash
Checking 283 objects
Checked 283 objects (0 errors)
```

<br/>

Se todos estes testes passarem, o teu `DC01` está totalmente operacional.

---