# Configuração do Servidor: DHCP01 (Kea DHCP)

Esta documentação cobre a instalação e configuração do servidor DHCP utilizando Kea no Debian 13, incluindo a preparação para atualizações dinâmicas de DNS (DDNS) no DC01.

---

## 1. Visão Geral

- **Hostname**: dhcp01
- **Sistema Operacional**: Debian 13 "Trixie"
- **Função**: Distribuir IPs e configurações de rede para clientes LAN
- **IP**: 192.168.100.202/24
- **Software**: Kea DHCP Server (Pacotes kea-dhcp4-server e kea-dhcp-ddns-server)

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
    address 192.168.100.202
    netmask 255.255.255.0
    gateway 192.168.100.1
    dns-nameservers 192.168.100.200 192.168.100.201
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
hostnamectl set-hostname dhcp01
``` 

<br/>

Edite o arquivo `/etc/hosts` para garantir que o servidor saiba quem ele é:

```bash
127.0.0.1       localhost
192.168.100.202 dhcp01.empresatech.example dhcp01
``` 
---

## 3. Instalação do Kea DHCP

O Kea é modular. Vamos instalar o servidor IPv4 e o módulo de DDNS (para atualizar o DNS automaticamente).

```bash
apt update
apt install kea-dhcp4-server kea-dhcp-ddns-server bind9 -y
```
> A instalação do **Bind9** é somente para usar a ferramenta **TSIG Key**.

<br/>

⚠️ **Atenção durante a instalação**: Uma tela pode aparecer pedindo o "Realm" do Kerberos.
- **Realm Kerberos versão 5 padrão**: `EMPRESATECH.EXAMPLE`
- **Servidores Kerberos para seu realm**: `dc01.empresatech.example`
- **Servidor administrativo para seu realm Kerberos**: `dc01.empresatech.example`


<br/>

Desative o serviço do Bind9:

```bash
systemctl stop bind9
systemctl disable bind9
systemctl mask bind9
``` 
---

## 4. Gerar Chave de Segurança (TSIG Key)

Para que o DHCP possa escrever no servidor DNS (DC01), eles precisam compartilhar uma "senha" secreta, chamada chave TSIG.

<br/>

Execute este comando no terminal para gerar uma chave limpa:

```bash
tsig-keygen -a HMAC-SHA256 ddns-key
```

<br/>

Copie o resultado. Ele será parecido com isto (mas não use este exemplo, use o que você gerou):


```bash
key "ddns-key" {
    algorithm hmac-sha256;
    secret "UmaStringAleatoriaDeLetrasENumeros";
};
```
⚠️ IMPORTANTE: Salve esta chave num bloco de notas. Você precisará colocá-la na configuração abaixo e TAMBÉM no servidor **DC01** depois.

---

## 5. Configuração do DHCPv4 `kea-dhcp4.conf`

O arquivo de configuração do Kea é em JSON. Cuidado com as vírgulas e chaves `{ }`!

<br/>

Edite o arquivo `/etc/kea/kea-dhcp4.conf`.

Apague tudo e cole o conteúdo abaixo (Ajuste a seção `tsig-keys` com a sua chave gerada acima):

```bash
{
"Dhcp4": {
    "interfaces-config": {
        "interfaces": [ "eth0" ]
    },
    
    // Conexão com o módulo DDNS (que fala com o DNS)
    "dhcp-ddns": {
        "enable-updates": true,
        "server-ip": "127.0.0.1",
        "server-port": 53001
    },

    // Definição da Chave TSIG (COLE A SUA CHAVE AQUI IGUAL AO PASSO 4)
    "tsig-keys": [
        {
            "name": "ddns-key",
            "algorithm": "hmac-sha256",
            "secret": "COLE_SUA_CHAVE_GERADA_AQUI=="
        }
    ],

    // Configurações de tempo (Lease de 24 horas)
    "valid-lifetime": 86400,
    "renew-timer": 43200,
    "rebind-timer": 75600,

    // Definição da Subrede
    "subnet4": [
        {
            "subnet": "192.168.100.0/24",
            "pools": [ { "pool": "192.168.100.11 - 192.168.100.199" } ],
            
            "option-data": [
                {
                    "name": "routers",
                    "data": "192.168.100.1"
                },
                {
                    "name": "domain-name-servers",
                    "data": "192.168.100.200"
                },
                {
                    "name": "domain-name",
                    "data": "empresatech.example"
                }
            ],
            
            // Habilita atualização de DNS para esta subnet
            "ddns-send-updates": true,
            "ddns-qualifying-suffix": "empresatech.example"
        }
    ],

    // Onde armazenar os leases (arquivo simples)
    "lease-database": {
        "type": "memfile",
        "persist": true,
        "name": "/var/lib/kea/kea-leases4.csv"
    },

    "loggers": [
        {
            "name": "kea-dhcp4",
            "output_options": [ { "output": "stdout" } ],
            "severity": "INFO"
        }
    ]
}
}
```
---

## 6. Configuração do Módulo DDNS `kea-dhcp-ddns.conf`

Este é o serviço que pega a informação do DHCP e envia para o Bind9 no DC01.

<br/>

Edite o arquivo `/etc/kea/kea-dhcp-ddns.conf`.

Apague tudo e cole (Inserindo novamente a SUA chave secreta):

```bash
{
"DhcpDdns": {
    "ip-address": "127.0.0.1",
    "port": 53001,
    "tsig-keys": [
        {
            "name": "ddns-key",
            "algorithm": "hmac-sha256",
            "secret": "COLE_SUA_CHAVE_GERADA_AQUI=="
        }
    ],
    "forward-ddns": {
        "ddns-domains": [
            {
                "name": "empresatech.example.",
                "key-name": "ddns-key",
                "dns-servers": [ { "ip-address": "192.168.100.200", "port": 53 } ]
            }
        ]
    },
    "reverse-ddns": {
        "ddns-domains": [
            {
                "name": "100.168.192.in-addr.arpa.",
                "key-name": "ddns-key",
                "dns-servers": [ { "ip-address": "192.168.100.200", "port": 53 } ]
            }
        ]
    },
    "loggers": [
        {
            "name": "kea-dhcp-ddns",
            "output_options": [ { "output": "stdout" } ],
            "severity": "INFO"
        }
    ]
}
}
``` 

---

## 7. Ajuste no DC01 (Bind9)

O DHCP está configurado para enviar atualizações, mas o **DC01** ainda não sabe receber essa chave. Precisamos voltar rapidinho no **DC01**.

<br/>

No SERVIDOR DC01:

1. Edite o arquivo `/etc/bind/named.conf.options` e adicione a chave e a permissão de atualização:
   
```bash
# Adicione isso ANTES do bloco 'options'
key "ddns-key" {
    algorithm hmac-sha256;
    secret "COLE_SUA_CHAVE_GERADA_AQUI==";
};

options {
    ...
    # Dentro de Options, procure allow-query e adicione a linha abaixo:
    allow-update { key "ddns-key"; };
    ...
};
``` 

<br/>

2. Reinicie o Bind9 no DC01:

```bash
systemctl restart bind9
``` 

---

## 8. Validação e Testes

De volta ao servidor **DHCP01**.

<br/>

1. Habilitar e Iniciar Serviços:

```bash
systemctl enable kea-dhcp4-server kea-dhcp-ddns-server
systemctl restart kea-dhcp4-server kea-dhcp-ddns-server
``` 

Deve retornar:

```bash
dc01.empresatech.example has address 192.168.100.200
``` 

<br/>


2. Verificar Status:

```bash
systemctl status kea-dhcp4-server
``` 

<br/>


3. Teste em Tempo Real: Acompanhe os logs enquanto conecta um cliente (Windows ou Linux) na rede:

```bash
journalctl -u kea-dhcp4-server -f
``` 
Resultado esperado: Mensagens de `DHCPDISCOVER`, `DHCPOFFER`, `DHCPREQUEST`, `DHCPACK`. 

<br/>

4. Validar DDNS: Após um cliente pegar IP, verifique no log ou consulte no DC01

```bash
host nome-do-cliente.empresatech.example 192.168.100.200
``` 
Se retornar o IP, a integração funcionou!

---
