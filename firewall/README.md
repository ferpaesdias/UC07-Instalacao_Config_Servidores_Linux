# 🔥 Servidor Firewall (nftables)

<br/>

Este documento apresenta as etapas para **configuração do firewall** em servidores **Debian 13 (Trixie)** utilizando o **nftables**, responsável pelo controle e filtragem do tráfego entre as redes LAN, DMZ e WAN.

---

<br/>

## 🎯 Objetivo

O **Firewall** tem como função **controlar o tráfego de entrada e saída de pacotes** entre redes, protegendo os servidores e usuários de acessos indevidos.  
Com o **nftables**, é possível definir políticas de segurança, NAT (Network Address Translation) e regras de encaminhamento de pacotes de forma moderna e eficiente.

---

<br/>

## 🧩 Descrição do Serviço

| Item | Detalhe |
|------|----------|
| **Software** | nftables |
| **Sistema operacional** | Debian 13 (Trixie) |
| **Função** | Controle de tráfego e NAT entre redes (LAN ↔ DMZ ↔ WAN) |
| **Arquivos principais** | `/etc/nftables.conf` e `/etc/sysctl.d/99-custom-forwarding.conf` |
| **Serviço** | `nftables.service` |

---

<br/>

## ⚙️ Instalação e Configuração do Firewall

<br/>

### 1️⃣ Habilitar o encaminhamento de pacotes (IP Forwarding)

Crie o arquivo `/etc/sysctl.d/99-custom-forwarding.conf`:

```bash
sudo vim /etc/sysctl.d/99-custom-forwarding.conf
```

<br/>

Adicione o conteúdo abaixo:

```bash
net.ipv4.ip_forward=1
```

<br/>

Aplique a configuração:

```bash
sudo sysctl --system
```

> Essa etapa garante que o servidor possa encaminhar pacotes entre interfaces de rede distintas (função essencial de um firewall).

---

<br/>

### 2️⃣ Configurar o nftables

Substitua o conteúdo do arquivo principal do firewall:

```bash
sudo vim /etc/nftables.conf
```

Copie o conteúdo do arquivo [`nftables.conf`](./configs/nftables.conf) deste repositório e personalize conforme o ambiente (interfaces, sub-redes e regras de filtragem).

---

<br/>

### 3️⃣ Aplicar e testar a configuração

Teste o arquivo de regras antes de ativar o serviço:

```bash
sudo nft -f /etc/nftables.conf
```

<br/>

Visualize as regras aplicadas:

```bash
sudo nft list ruleset
```

---

<br/>

### 4️⃣ Habilitar o serviço nftables

```bash
sudo systemctl enable nftables
sudo systemctl start nftables
sudo systemctl status nftables
```

> Após reiniciar o servidor, o firewall será carregado automaticamente.

---

<br/>

## 🧪 Testes de funcionamento

Após aplicar as regras, execute testes de conectividade entre as zonas:

```bash
# Teste de ping entre clientes e DMZ
ping 10.0.2.2

# Verificar NAT de saída para a WAN
curl ifconfig.me
```

<br/>

Para logs e diagnósticos:

```bash
sudo journalctl -u nftables
```

---
