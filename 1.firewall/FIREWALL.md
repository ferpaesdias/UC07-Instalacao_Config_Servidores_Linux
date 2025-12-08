# 01 - Configuração do Gateway e Firewall (GW-FIREWALL)

Bem-vindo ao primeiro passo prático! Neste guia, vamos transformar uma instalação padrão do Debian 13 em um roteador e firewall corporativo robusto.

**Objetivo:** Configurar as interfaces de rede para segmentar o tráfego e aplicar regras de firewall (Nftables) que protejam a nossa rede interna (LAN) e a zona desmilitarizada (DMZ).

---

## 🏗️ Preparação da Máquina Virtual (VirtualBox)

Antes de ligar a máquina, precisamos garantir que o hardware virtual tenha as "placas de rede" corretas para conectar os cabos virtuais.

1. Selecione a VM **GW-FIREWALL** e vá em **Configurações > Rede**.
2. Configure os 3 adaptadores:
    * **Adaptador 1:** Conectado a: `NAT` (Simula a conexão WAN/Internet).
    * **Adaptador 2:** Conectado a: `Rede Interna`. Nome: `intnet_dmz` (Será a nossa DMZ).
    * **Adaptador 3:** Conectado a: `Rede Interna`. Nome: `intnet_lan` (Será a nossa LAN Corporativa).

> **Por que isso é importante?** Fisicamente, isso seria equivalente a instalar 3 placas de rede no servidor e conectar cabos de cores diferentes em switches separados. O VirtualBox simula isso via software.

---

## Passo 1: Configuração das Interfaces de Rede

O Linux precisa saber qual IP usar em cada placa de rede. Vamos editar o arquivo de configuração de interfaces.

1. Abra o terminal e logue como `root` (ou use `sudo -i`).
2. Edite o arquivo de interfaces:

   ```bash
   vim /etc/network/interfaces
   ```

   ```bash
   # Interface de Loopback (Interna do sistema)
   auto lo
   iface lo inet loopback

   # 1. Interface WAN (Internet - Adaptador 1)
   # Recebe IP automático do VirtualBox/Provedor
   allow-hotplug enp0s3
   iface enp0s3 inet dhcp

   # 2. Interface DMZ (Servidores Públicos - Adaptador 2)
   # IP Estático para ser o Gateway da DMZ
   allow-hotplug enp0s8
   iface enp0s8 inet static
      address 172.20.0.1/24

   # 3. Interface LAN (Rede Corporativa - Adaptador 3)
   # IP Estático para ser o Gateway da LAN
   allow-hotplug enp0s9
   iface enp0s9 inet static
      address 192.168.100.1/24
   ```

   >**Nota**: Os nomes das interfaces (`enp0s3`, `enp0s8`, `enp0s9`) podem variar dependendo do hardware. Use o comando `ip link` antes para conferir os nomes. Se forem diferentes, ajuste no arquivo acima.

3. Reinicie o serviço de rede para aplicar:

   ```bash
   systemctl restart networking
   ```

4. Verifique se os IPs estão corretos:

   ```bash
   ip addr
   ```

   >Você deve ver 3 IPs diferentes agora.

---

