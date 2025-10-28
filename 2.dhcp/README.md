# 🧭 Servidor DHCP (Kea DHCP)


Este documento descreve a instalação e configuração do **servidor DHCP (Kea DHCP)** utilizado nos laboratórios da UC07.

---

<br/>

## 🎯 Objetivo

O **DHCP (Dynamic Host Configuration Protocol)** é responsável por **atribuir automaticamente endereços IP, gateway, DNS e máscara de rede** aos clientes de uma rede local, simplificando o gerenciamento de endereçamento IP e reduzindo erros de configuração manual.

---

## 🧩 Descrição do Serviço

| Item | Detalhe |
|------|----------|
| **Software** | Kea DHCP (ISC) |
| **Sistema operacional** | Debian 13 (Trixie) |
| **Faixa de IPs** | `10.0.3.11 – 10.0.3.99` |
| **Gateway padrão** | `10.0.3.1` |
| **Servidor DHCP** | `10.0.3.200` |
| **Domínio** | `empresatech.example` |
| **Arquivo principal** | `/etc/kea/kea-dhcp4.conf` |

---

<br/>

## ⚙️ Instalação e Configuração do Kea DHCP Server


### 1️⃣ Instalar o pacote

```bash
sudo apt update
sudo apt install kea-dhcp4-server -y
```

---

<br/>

### 2️⃣ Fazer backup da configuração original

```bash
sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
```
---

<br/>

### 3️⃣ Criar o novo arquivo de configuração

Abra o arquivo principal:

```bash
sudo vim /etc/kea/kea-dhcp4.conf
```

Copie o conteúdo do arquivo [`kea-dhcp4.conf`](./configs/kea-dhcp4.conf) deste repositório e personalize de acordo com o seu cenário de rede (interface, gateway, faixa de IPs, domínio e DNS).

---

<br/>

### 4️⃣ Criar diretórios para logs e leases

```bash
sudo mkdir -p /var/log/kea /var/lib/kea
```

Esses diretórios armazenam os **logs de execução** e as **concessões de IPs (leases)** realizadas pelo servidor DHCP.

---

<br/>

### 5️⃣ Validar a configuração

Antes de iniciar o serviço, verifique se há erros no arquivo de configuração:

```bash
sudo kea-dhcp4 -c /etc/kea/kea-dhcp4.conf -W
```

Se não houver erros, prossiga com a execução.

---

<br/>

### 6️⃣ Habilitar e iniciar o serviço

```bash
sudo systemctl enable --now kea-dhcp4-server
sudo systemctl status kea-dhcp4-server
```

---

<br/>

### 7️⃣ Testar o funcionamento

Conecte um cliente à rede e verifique se o endereço IP foi atribuído automaticamente.

Para visualizar os registros de leases (endereços concedidos):

```bash
sudo cat /var/lib/kea/kea-leases4.csv
```
---
