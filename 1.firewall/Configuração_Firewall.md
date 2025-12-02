# Configuração do Servidor: Firewall e Gateway

Esta documentação detalha o processo de configuração do servidor Firewall utilizando Debian 13.

Este servidor atua como roteador entre a Internet, a rede interna (LAN) e a zona desmilitarizada (DMZ), utilizando Nftables para filtrar pacotes e realizar NAT (Network Address Translation).

---

## 1. Visão Geral

- **Hostname**: firewall
- **Sistema Operacional**: Debian 13 "Trixie"
- **Função**: Gateway, Firewall, NAT
- **Interfaces de Rede**:
  - **WAN** (Internet): DHCP (Interface enp0s3)
  - **DMZ** (Servidores Web): 172.20.0.1/24 (Interface enp0s8)
  - **LAN** (Empresa): 192.168.100.1/24 (Interface enp0s9)

> **Nota para o Aluno**: Os nomes das interfaces de rede (enp0s3, enp0s8, enp0s9) podem variar dependendo do seu hardware ou virtualizador (ex: eth0, eth1). Use o comando ip link para identificar as suas interfaces antes de configurar.

---

## 2. Configuração de Rede (IPs Estáticos)

Primeiro, vamos definir os endereços IP das placas de rede. O Firewall precisa de IPs fixos nas redes internas para que os outros computadores o encontrem como "Gateway".

Edite o arquivo `/etc/network/interfaces` com o conteúdo abaixo:

```bash
# Esta linha habilita a interface de loopback (local)
auto lo
iface lo inet loopback

# --- Interface WAN (Internet) ---
# Recebe IP automaticamente do provedor ou laboratório
auto enp0s3
iface enp0s3 inet dhcp

# --- Interface DMZ (Servidores Públicos) ---
# IP fixo para ser o gateway da rede 172.20.0.0/24
auto enp0s8
iface enp0s8 inet static
    address 172.20.0.1
    netmask 255.255.255.0

# --- Interface LAN (Rede Interna) ---
# IP fixo para ser o gateway da rede 192.168.100.0/24
auto enp0s9
iface enp0s9 inet static
    address 192.168.100.1
    netmask 255.255.255.0
```

🧠 Entendendo a configuração:

- **auto enp0sX**: Diz ao Linux para ligar essa placa de rede assim que o computador iniciar.
- **inet dhcp**: A placa WAN pede um IP emprestado a quem fornece a internet (como o modem da operadora).
- **inet static**: Nas redes internas (LAN e DMZ), nós decidimos o IP.

Reinicie o serviço `networking` para aplicar as configurações de rede:

```bash
systemctl restart networking
```

---

## 3. Habilitar o Roteamento (IP Forwarding)

Por padrão, o Linux bloqueia a passagem de dados de uma placa de rede para outra por segurança. Como este servidor é um Roteador, precisamos liberar esse tráfego.

Edite o arquivo `/etc/sysctl.d/99-custom-forwarding.conf` com o conteúdo abaixo:

```bash
net.ipv4.ip_forward=1
```

**Aplicar a mudança**:

Execute o comando abaixo para ativar a configuração sem precisar reiniciar:

```bash
sysctl --system
```

---

## 4. Configuração do Firewall (Nftables)

O Nftables vai controlar quem pode falar com quem e permitir que os computadores internos naveguem na internet (usando NAT/Masquerade).

### Instalação

```bash
apt update
apt install nftables -y
systemctl enable nftables
```

### Configuração

Apague todo o conteúdo existente no arquivo `/etc/nftables.conf` e cole o seguinte:

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

🧠 Entendendo as regras:

- **Policy Drop**: "Se não for explicitamente permitido, é proibido". Isso bloqueia tudo por padrão.
- **Input**: Controla quem acessa o servidor Firewall diretamente. Permitimos apenas Ping e SSH (apenas vindo da rede segura, a LAN).
- **Forward**: Controla o tráfego que atravessa o firewall.
- **LAN -> Internet**: Permitido.
- **DMZ -> Internet**: Permitido.
- **LAN -> DMZ**: Permitido (para administrarmos os servidores).
- **DMZ -> LAN**: Bloqueado (Implicitamente pelo policy drop). Isso isola a rede da empresa caso um dos servidores da rede DMZ seja hackeado.
- **NAT Masquerade**: O firewall "mascara" os IPs internos, coloca o dele na saída, e quando a resposta da internet volta, ele entrega ao computador certo.

### Testar e aplicar as regras

```bash
nft -f /etc/nftables.conf
```

---

## 5. Configuração de Nome e Hosts

Altere o *Hostname* do servidor

```bash
hostnamectl set-hostname firewall
```

Edite o arquivo `/etc/hosts/` e o deixe igual o conteúdo abaixo:

```bash
127.0.0.1       localhost
127.0.1.1       firewall.empresatech.example  firewall
```

---

## 6. Validação e Testes

Agora, vamos garantir que tudo funciona. Execute os comandos abaixo no terminal do Firewall.

1. Verificar endereços IP:

   ```bash
   ip -brief addr
   ```

   Resultado esperado:

   ```bash
   lo               UNKNOWN        127.0.0.1/8 ::1/128 
   enp0s3           UP             192.168.3.44/24 fe80::7d16:45ba:d71f:3c0f/64 
   enp0s8           UP             172.20.0.1/24 fe80::a00:27ff:fee5:dfb8/64 
   enp0s9           UP             192.168.100.1/24 fe80::a00:27ff:fe28:c085/64 
   ```

2. Verificar se tem Internet:

   ```bash
   ping -c 4 google.com
   ```

3. Verificar se as regras do firewall foram carregadas:

   ```bash
   nft list ruleset
   ```

---
