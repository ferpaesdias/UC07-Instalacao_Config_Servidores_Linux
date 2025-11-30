# Configuração do Servidor: DC01 (Controlador de Domínio com Bind9)

Esta documentação detalha a configuração do Controlador de Domínio Primário no Debian 13, integrando o Samba 4 com o servidor DNS **Bind9** via módulo DLZ (Dynamically Loadable Zones).

---

## 1. Visão Geral

- **Hostname**: dc01
- **Sistema Operacional**: Debian 13 "Trixie"
- **Função**: Active Directory e DNS Master (Bind9)
- **Domínio**: empresatech.example
- **IP**: 192.168.100.200/24
- **Tecnologia DNS**: BIND9_DLZ (O Samba atualiza as zonas do Bind diretamente)

---

## 2. Configuração de Rede

O Controlador de Domínio DEVE ter um IP estático.

<br/>

**Arquivo**: `/etc/network/interfaces`

Edite este arquivo com o conteúdo abaixo:

```bash
# Interface de Loopback
auto lo
iface lo inet loopback

# Interface LAN
auto enp0s3
iface enp0s3 inet static
    address 192.168.100.200
    netmask 255.255.255.0
    gateway 192.168.100.1
    
    # Durante a instalação, usamos um DNS externo (Google) para baixar pacotes.
    # Após configurar o Samba, mudaremos para 127.0.0.1
    dns-nameservers 8.8.8.8
    dns-search empresatech.example
```

<br/>

Reinicie a rede para aplicar:

```bash
systemctl restart networking
``` 
<br/>

**Configurar Hostname**

O Samba é sensível ao nome da máquina. 

```bash
hostnamectl set-hostname dc01
``` 

<br/>

Edite o arquivo `/etc/hosts` para garantir que o servidor saiba quem ele é:

```bash
127.0.0.1       localhost
192.168.100.200 dc01.empresatech.example dc01
``` 
---

## 3. Instalação de Pré-requisitos e Samba

Precisamos do Samba e de ferramentas para manipular Kerberos (autenticação).

```bash
apt update
apt install samba smbclient krb5-config krb5-user winbind bind9 bind9-utils python3-setproctitle -y
```

<br/>

⚠️ **Atenção durante a instalação**: Uma tela pode aparecer pedindo o "Realm" do Kerberos.
- **Realm Kerberos versão 5 padrão**: `EMPRESATECH.EXAMPLE`
- **Servidores Kerberos para seu realm**: `dc01.empresatech.example`
- **Servidor administrativo para seu realm Kerberos**: `dc01.empresatech.example`


<br/>

Acesse o arquivo `/etc/network/interfaces` e altere a linha `dns-nameservers 8.8.8.8` para `dns-nameservers 127.0.0.1`.

Reinicie o serviço de rede para aplicar a configuração:

```bash
systemctl restart networking
``` 
---

## 4. Provisionamento do Domínio

Agora vamos transformar este servidor comum em um Controlador de Domínio.

<br/>

1. Fazer backup da configuração original (por segurança)

```bash
mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
```

<br/>

2. **Provisionar o Domínio**: Execute o comando abaixo. Ele cria a base de dados de usuários e configura o DNS automaticamente. 
Definiremos a senha de `administrator` como `SenhaForte123!` para fins educativos.


```bash
samba-tool domain provision \
    --server-role=dc \
    --use-rfc2307 \
    --dns-backend=BIND9_DLZ \
    --realm=EMPRESATECH.EXAMPLE \
    --domain=EMPRESATECH \
    --adminpass='SenhaForte123!'
```

---

## 5. Configuração do Bind9

Esta é a parte crítica. O Bind9 precisa "enxergar" os arquivos do Samba.

<br/>

### A. Configuração Global `/etc/bind/named.conf.options`

Substitua o conteúdo por:

```bash
options {
    directory "/var/cache/bind";

    # Encaminhadores (Para navegar na internet)
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;

    # Permitir consultas apenas da nossa rede interna e local
    allow-query { localhost; 192.168.100.0/24; 172.20.0.0/24; };
    
    # Habilitar recursão (necessário para clientes navegarem)
    recursion yes;

    # Configurações exigidas pelo Samba AD
    tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";
    minimal-responses yes;

    listen-on-v6 { any; };
};
```

<br/>

### B. Incluir a Zona do Samba `/etc/bind/named.conf.local`

Precisamos dizer ao Bind onde está o arquivo de zona que o Samba criou.

Substitua o conteúdo por:

```bash
include "/var/lib/samba/bind-dns/named.conf";
``` 
---

## 6. Inicialização dos Serviços

O serviço do Samba para AD é o `samba-ad-dc`. Os serviços `smbd`, `nmbd` e `winbind` antigos devem ser desativados para não conflitar.

```bash
# Reiniciar o Bind9 para pegar as novas configurações
systemctl restart bind9
systemctl enable named

# Parar serviços legados
systemctl stop smbd nmbd winbind
systemctl disable smbd nmbd winbind

# Ativar o Samba AD DC
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
systemctl start samba-ad-dc
``` 

---

## 7. Criação de Usuários e Grupos

Utilize o script abaixo para criar a estrutura organizacional.

Crie o arquivo `criar_usuarios.sh`

```bash
#!/bin/bash
# Script de Criação de Estrutura Empresa Tech

echo "--- Criando Grupos ---"
samba-tool group add Vendas
samba-tool group add Financeiro
samba-tool group add TI
samba-tool group add Suporte
samba-tool group add RH

criar_user() {
    USER=$1
    PASS="Mudar123!"
    GROUP=$2
    # Obriga o usuário a alterar a senha no primeiro acesso
    samba-tool user create $USER $PASS --surname="$3" --given-name="$USER" --must-change-at-next-login
    samba-tool group addmembers $GROUP $USER
    echo "Usuário $USER criado em $GROUP"
}

echo "--- Criando Usuários ---"

# Se desejar, adicione mais usuários usando o padrão "Nome" "Grupo" "Sobrenome"  
criar_user "Pinguelson" "Vendas" "Timeout"
criar_user "Valter" "Vendas" "Gateway Perdido"
criar_user "Adalberto" "TI" "Kernel Panela"
criar_user "Clesio" "RH" "DNS Travado"

echo "--- Concluído! ---"
``` 
---

## 8. Validação e Testes

Agora vamos validar se o Bind9 e o Samba estão conversando corretamente.

<br/>

1. Testar resolução DNS (Bind9):

```bash
host dc01.empresatech.example
``` 

Deve retornar:

```bash
dc01.empresatech.example has address 192.168.100.200
``` 

<br/>


2. Testar registros SRV (Essenciais para o AD):

```bash
host -t SRV _ldap._tcp.empresatech.example
``` 

Deve retornar:

```bash
_ldap._tcp.empresatech.example has SRV record 0 100 389 dc01.empresatech.example.
``` 

<br/>


3. Testar Kerberos: Vamos tentar obter um ticket de autenticação para o `administrador`.

```bash
kinit administrator
``` 

(Digite a senha `SenhaForte123!`). Se não der erro, funcionou. Verifique o ticket com o coomando:


```bash
klist
``` 

Deve retornar uma mensagem semelhante a abaixo:

```bash
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: administrator@EMPRESATECH.EXAMPLE

Valid starting       Expires              Service principal
30/11/2025 19:02:42  01/12/2025 05:02:42  krbtgt/EMPRESATECH.EXAMPLE@EMPRESATECH.EXAMPLE
	renew until 01/12/2025 19:02:36
``` 

<br/>


4. Teste de Navegação (Forwarding):

```bash
ping -c 2 google.com
``` 
Isso confirma que o **Bind9** está encaminhando consultas externas para o `8.8.8.8` corretamente.
---