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
