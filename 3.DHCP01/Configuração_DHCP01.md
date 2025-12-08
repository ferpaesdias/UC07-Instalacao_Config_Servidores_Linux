# 03 - Serviço de DHCP (ISC Kea)

Este guia cobre a instalação e configuração do **ISC Kea DHCP Server**, o responsável por distribuir endereços IP automaticamente para todos os computadores da rede.

**Objetivo:** Automatizar a configuração de rede dos clientes. Quando um PC for ligado na rede, ele deve receber:
1.  Um IP livre (ex: `192.168.100.50`).
2.  O endereço do Gateway (Firewall) para ter Internet.
3.  O endereço do DNS (DC01) para encontrar o domínio.

**Informações do Servidor:**
* **Hostname:** `dhcp01`
* **IP:** `192.168.100.202`
* **Software:** ISC Kea DHCP4

---

## 🛑 Pré-requisitos de Rede

O Controlador de Domínio é o servidor mais importante da rede. Ele precisa de um IP fixo e um nome definido.

1. **Definir o Hostname:**

    ```bash
    hostnamectl set-hostname dhcp01
    ```
<br/>

2. **Configurar IP Estático:**

    Edite o arquivo `/etc/network/interfaces`:

    ```bash
    vim /etc/network/interfaces
    ```
    <br/>

    O arquivo deve conter a configuração da interface LAN (ajuste o nome `enp0s3` conforme seu comando `ip link`):

    ```conf
    auto lo
    iface lo inet loopback

    allow-hotplug enp0s3
    iface enp0s3 inet static
        address 192.168.100.202/24
        gateway 192.168.100.1
    ```

    *Salve e saia.*

<br/>

3. **Configurar DNS Temporário (Para Instalação):**

    Para baixar os pacotes, precisamos de internet. Edite o `/etc/resolv.conf`:

    ```bash
    vim /etc/resolv.conf
    ```

    <br/>

    Adicione um DNS público temporariamente:

    ```conf
    search empresatech.example
    nameserver 192.168.100.200
    ```
    <br/>

4. **Aplicar Rede e Atualizar Hosts:**

    ```bash
    systemctl restart networking
    ```
    <br/>

    Edite o `/etc/hosts` para associar o nome ao IP. 
      
    ```bash
    vim /etc/hosts
    ```
    <br/>
    
    Apague tudo e adicione o conteúdo abaixo:  
    ```conf
    127.0.0.1       localhost
    192.168.100.202 dhcp01.empresatech.example dhcp01
    ```
    <br/>

---

## 📦 Passo 1: Instalação do Kea DHCP

O Kea é dividido em módulos. Para este laboratório, precisamos apenas do suporte a IPv4.

```bash
apt update
apt install kea-dhcp4-server -y
```

---

## ⚙️ Passo 2: Configuração JSON

O arquivo de configuração padrão do Kea é muito extenso e cheio de exemplos. Para facilitar o aprendizado, vamos renomeá-lo e criar um arquivo limpo, contendo apenas o essencial.

1. Backup do original:

    ```bash
    mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.backup
    ```
    <br/>

2. Criar nova configuração:
      
    ```bash
    vim /etc/kea/kea-dhcp4.conf
    ```
    <br/>
    
3. Cole o código abaixo: 
   *Atenção à sintaxe: O JSON é muito rigoroso com vírgulas e chaves.*
   
    ```conf
    {
    "Dhcp4": {
    "interfaces-config": {
        "interfaces": ["enp0s3"]
    },
    
    "lease-database": {
        "type": "memfile",
        "persist": true,
        "name": "/var/lib/kea/kea-leases4.csv"
    },

    "valid-lifetime": 4000,
    "renew-timer": 1000,
    "rebind-timer": 2000,

    "subnet4": [
        {
            "id": 1,
            "subnet": "192.168.100.0/24",
            "pools": [ { "pool": "192.168.100.100 - 192.168.100.199" } ],
            
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
            ]
        }
      ]
    }
    }
    ```

    <br/>

### 🔍 Entendendo a Configuração

* `interfaces`: Diz ao Kea em qual placa de rede ele deve escutar pedidos. Verifique se o seu é `enp0s3`.
* `pools`: Define o intervalo de IPs que serão entregues (do .100 ao .199). Reservamos do .200 ao .254 para servidores estáticos.
* `routers`: Informa aos clientes quem é o Gateway (Firewall) para saírem para a internet.
* `domain-name-servers`: Informa aos clientes quem é o DNS (DC01). Isso é crucial para o AD funcionar.

---

## 🚀 Passo 3: Validação e Início do Serviço

O JSON não perdoa erros de digitação. Vamos verificar se o arquivo está válido antes de iniciar.

1. **Testar a configuração**: O Kea possui uma ferramenta integrada para verificar erros de sintaxe.
   
    ```bash
    kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
    ```
    >Resultado esperado: Nenhuma mensagem de erro ou uma mensagem de log limpa.

    <br/>

2. Iniciar o serviço:
      
    ```bash
    systemctl enable kea-dhcp4-server
    systemctl restart kea-dhcp4-server
    ```
    <br/>
    
2. Verificar status:
      
    ```bash
    systemctl status kea-dhcp4-server
    ```
    >Deve estar "Active (running)".
    
    <br/>

---

