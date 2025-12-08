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

## Passo 2: Habilitar o Roteamento (IP Forwarding)

Por padrão, o Linux é "egoísta": se ele recebe um pacote que não é para ele, ele o descarta. Para agir como um roteador, precisamos dizer a ele: "Se receber um pacote para outro lugar, passe adiante".

1. Crie o arquivo abaixo:

   ```bash
   vim /etc/sysctl.conf.d/99-forwarding.conf
   ```

2. Adicione o conteúdo abaixo:

   ```bash
   net.ipv4.ip_forward=1
   ```

3. Salve e saia. Aplique a mudança imediatamente com o comando:

   ```bash
   sysctl --system
   ```

---

## Passo 3: Configuração do Firewall (Nftables)

Agora vamos configurar o segurança da rede. O **Nftables** é o sucessor do `iptables`. Ele decide quem entra e quem sai.

Vamos criar regras que:

* Permitam que a LAN e DMZ acessem a internet (NAT).
* Permitam que a LAN acesse a DMZ.
* Bloqueiem que a DMZ inicie conexões para a LAN (Segurança crítica).

1. Edite o arquivo de configuração do nftables:

   ```bash
   vim /etc/nftables.conf
   ```

2. Apague todo o conteúdo e cole a seguinte configuração:

   ```bash
   #!/usr/sbin/nft -f

   # Apaga completamente o conjunto de regras anteriores
   flush ruleset

   # --- Variáveis --- #
   # Altere os valores conforme sua infraestrutura
   define WAN_IF = "enp0s3"
   define DMZ_IF = "enp0s8"
   define LAN_IF = "enp0s9"
   define DMZ_NET = 172.20.0.0/24
   define LAN_NET = 192.168.100.0/24

   # Tabela INET FILTER
   table inet filter {

      # --- CHAIN INPUT --- #
      # Pacotes destinados ao próprio Firewall
      chain input {
         type filter hook input priority 0;
         policy drop;
   
         # Aceitar loopback
         iifname "lo" accept

         # Aceitar as conexões ja pre estabelecidas ou relacionadas
         ct state {established, related} accept

         # Descarta pacotes inválidos
         ct state invalid drop

         # Permitir ICMP da LAN  para o Firewall
         iifname $LAN_IF icmp type echo-request accept

         # Permitir ICMP da DMZ para o Firewall
         iifname $DMZ_IF icmp type echo-request accept

         # Permitir que o DHCP Client funciona na interface WAN
         iifname $WAN_IF udp dport 68 accept

         # Permitir acesso SSH ao Firewall apenas pela rede LAN 
         iifname $LAN_IF tcp dport 22 accept

         # Log de pacotes bloqueados
         log prefix "FIREWALL INPUT DROP: " flags all
      }

      # --- CHAIN FORWARD --- #
      # Pacotes que passam pelo Firewall
      chain forward {
         type filter hook forward priority 0;
         policy drop;

         # Permite o trafego de conexões ja estabelecidas
         ct state {established, related} accept

         # Descarta pacotes inválidos
         ct state invalid drop

         # Permite que a rede LAN acesse a rede WAN
         iifname $LAN_IF oifname $WAN_IF accept
 
         # Permite que a rede LAN acesse a rede DMZ
         iifname $LAN_IF oifname $DMZ_IF accept
 
         # Permite que a rede DMZ acesse a rede WAN
         iifname $DMZ_IF oifname $WAN_IF accept

         # Log de pacotes bloqueados
         log prefix "FIREWALL FORWARD DROP: " flags all
      }

      # --- CHAIN OUTPUT --- #
      # Pacotes originados pelo Firewall
      chain output {
         type filter hook output priority 0;
         policy accept;
      }
   }

   # TABELA IP NAT
   table ip nat {

      # --- CHAIN PREROUTING (DNAT)
      # Aplica regras a pacotes assim que eles chegam, antes do roteamento
      chain prerouting {
         type nat hook prerouting priority -100; 
      }   

      # --- CHAIN POSTROUTING (MASQUERADE) --- #
      chain postrouting {
         type nat hook postrouting priority 100;
         oifname $WAN_IF masquerade
      }
   }
   ```

3. Aplicar e listar a configuração do Nftables:

   ```bash
   sudo nft -f /etc/nftables.conf
   sudo nft list ruleset
   ```

4. Habilitar o serviço do Nftables:

   ```bash
   systemctl enable nftables.service
   ```

---

## Testes

Verifique se tem internet

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

---
