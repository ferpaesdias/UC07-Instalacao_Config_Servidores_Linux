# 🧭 Servidor DNS (BIND9)

<br/>

Este documento descreve a instalação e configuração do **servidor DNS (BIND9)** adotado nos laboratórios da UC07.

---

<br/>

## 🎯 Objetivo

O **DNS (Domain Name System)** resolve **nomes de host em endereços IP** (e vice‑versa), permitindo o acesso a serviços por nomes amigáveis e padronizados dentro da rede.

---

<br/>

## 🧩 Descrição do Serviço

| Item | Detalhe |
|------|--------|
| **Software** | BIND 9 (ISC) |
| **Sistema operacional** | Debian 13 (Trixie) |
| **Endereço IP** | `10.0.3.201` |
| **Gateway padrão** | `10.0.3.1` |
| **Endereço DNS** | `127.0.0.1` |
| **Domínio** | `empresatech.example` |
| **Zonas** | Direta: <br/>`empresatech.example`<br/> <br/>Reversas: <br/>`2.0.10.in-addr.arpa` (DMZ – 10.0.2.0/24) <br/>`3.0.10.in-addr.arpa` (LANEmpresa – 10.0.3.0/24) |
| **Arquivos principais** | `/etc/bind/named.conf.options`, `/etc/bind/named.conf.local`, `/etc/bind/db.empresatech.example`, `/etc/bind/db.10.0.2`, `/etc/bind/db.10.0.3` |

---

<br/>

## ⚙️ Instalação e Configuração do BIND9

<br/>

### 1️⃣ Instalar os pacotes

```bash
sudo apt update
sudo apt install bind9 bind9-utils bind9-dnsutils -y
```

---

<br/>

### 2️⃣ Configurar opções globais

Edite o arquivo de opções do BIND:

```bash
sudo vim /etc/bind/named.conf.options
```

Copie o conteúdo do arquivo [`named.conf.options`](./configs/named.conf.options) disponível neste repositório e ajuste conforme a infraestrutura.

---

<br/>

### 3️⃣ Definir as zonas

Edite o arquivo de zonas:

```bash
sudo vim /etc/bind/named.conf.local
```

Inclua as definições conforme o arquivo [`named.conf.local`](./configs/named.conf.local) deste repositório (zona direta + zonas reversas).

---

<br/>

### 4️⃣ Criar a zona direta

Crie/edite a base de zona direta do domínio:

```bash
sudo vim /etc/bind/db.empresatech.example
```

Utilize o conteúdo de [`db.empresatech.example`](./configs/db.empresatech.example) e personalize registros (A, CNAME, NS, etc.) conforme seu ambiente.

---

<br/>

### 5️⃣ Criar as zonas reversas

DMZ (`10.0.2.0/24`):

```bash
sudo vim /etc/bind/db.10.0.2
```
Preencha a partir do arquivo [`db.10.0.2`](./configs/db.10.0.2)

<br/>

Clientes (`10.0.3.0/24`):

```bash
sudo vim /etc/bind/db.10.0.3
```

Preencha a partir do arquivo [`db.10.0.3`](./configs/db.10.0.3).

---

<br/>

### 6️⃣ Validar a configuração

Execute as checagens:

```bash
sudo named-checkconf
sudo named-checkzone empresatech.example /etc/bind/db.empresatech.example
sudo named-checkzone 2.0.10.in-addr.arpa /etc/bind/db.10.0.2
sudo named-checkzone 3.0.10.in-addr.arpa /etc/bind/db.10.0.3
```

---

<br/>

### 7️⃣ Reiniciar e habilitar o serviço

```bash
sudo systemctl restart bind9
sudo systemctl enable bind9
sudo systemctl status bind9
```

---

<br/>

## 🔍 Testes rápidos

```bash
# Resolução direta
dig @localhost www.empresatech.example +short

# Resolução reversa (exemplo para 10.0.3.201)
dig @localhost -x 10.0.3.201 +short
```

> Se receber respostas coerentes, a configuração está funcional.

---
