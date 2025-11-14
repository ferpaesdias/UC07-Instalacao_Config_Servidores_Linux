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

<br/>

Apague o conteúdo do arquivo e insira os dados abaixo:

```bash
options {
  // Diretório de trabalho do BIND
  directory "/var/cache/bind";

  // Permite resolver nomes externos
  recursion yes;

  // Define quem pode usar a recursão
  allow-recursion {
    10.0.2.0/24;
    10.0.3.0/24;
    127.0.0.1;
  };

  // Permite consultas de qualquer host
  allow-query {
    any;
  };

  // Impede a transferência de zona
  allow-transfer {
    none;
  };

  // Encaminhadores - Consulta DNS público
  forwarders {
    8.8.8.8;  // Google
    1.1.1.1;  // Cloudflare
  };

  // Segurança de validação de assinatura
  dnssec-validation auto;

  // Configura qual(is) IP(s) deve(m) ficar escutando 
  listen-on {
    10.0.3.201;
    127.0.0.1;
  };

  // Desabilita IPv6
  listen-on-v6 {
    none;
  };
};
```


---

<br/>

### 3️⃣ Definir as zonas

Edite o arquivo de zonas:

<br/>


```bash
sudo vim /etc/bind/named.conf.local
```

<br/>

Apague o conteúdo do arquivo e insira os dados abaixo:

```bash
zone "empresatech.example" {
  type master;
  file "/etc/bind/db.empresatech.example";
};

zone "2.0.10.in-addr.arpa" {
  type master;
  file "/etc/bind/db.10.0.2";
};

zone "3.0.10.in-addr.arpa" {
  type master;
  file "/etc/bind/db.10.0.3";
};
```
---

<br/>

### 4️⃣ Criar a zona direta

Crie/edite a base de zona direta do domínio:

```bash
sudo vim /etc/bind/db.empresatech.example
```

<br/>

Apague o conteúdo do arquivo e insira os dados abaixo:

```bash
$TTL    604800

; Define as caracteristicas chaves da zona (dominio)
@    IN    SOA    dns01.empresatech.example. admin.empresatech.example. (
                  2025100501 ; Serial
                  3h         ; Refresh
                  15m        ; Retry
                  3w         ; Expire
                  3h )       ; Negative Cache TTL

; Nome do servidor RR para o dominio
@    IN    NS     dns01.empresatech.example.

; Servidores da DMZ
web  IN    A      10.0.2.200

; Servidores da rede interna
dhcp01       IN      A       10.0.3.200
dns01        IN      A       10.0.3.201
filesrv01    IN      A       10.0.3.202
ldap01       IN      A       10.0.3.203

; Alias
www       IN      CNAME   web.empresatech.example.
```

- **$TTL (Time-To-Live)**: O TTL descreve por quanto tempo (em segundos) um **RR** pode ser armazenado em cache antes de ser descartado.
- **Serial**: Este valor DEVE aumentar quando qualquer registro de recurso no arquivo de zona for atualizado. Um servidor DNS escravo (secundário) lerá o registro mestre DNS SOA periodicamente e comparará, aritmeticamente, seu valor atual **SERIAL** com aquele recebido do mestre. Se o valor **SERIAL** do mestre for aritmeticamente SUPERIOR ao atualmente armazenado pelo escravo, então uma transferência de zona é iniciada pelo escravo. Deve ter 10 dígitos.
- **Refresh**: Indica o período em que o escravo tentará atualizar a zona do mestre.
- **Retry**: Define o tempo entre novas tentativas se o escravo (secundário) falhar em contatar o mestre quando a atualização expirar.
- **Expire**: Indica quando os dados da zona não são mais autoritativos. Usado apenas por servidores Escravos (Secundários). Os escravos BIND9 param de responder com autoridade às consultas da zona quando esse tempo expira e nenhum contato é feito com o mestre. 
- **Negative Cache TTL**: Controla por quanto tempo outros servidores armazenam em cache as respostas `no-such-domain (NXDOMAIN)` deste servidor. O tempo máximo para cache negativo é de 3 horas.

---

<br/>

### 5️⃣ Criar as zonas reversas

DMZ (`10.0.2.0/24`):

```bash
sudo vim /etc/bind/db.10.0.2
```

<br/>

Apague o conteúdo do arquivo e insira os dados abaixo:

```bash
$TTL	604800
@    IN    SOA    dns01.empresatech.example. admin.empresatech.example. (
                  2025100501 ; Serial
                  3h         ; Refresh
                  15m        ; Retry
                  3w         ; Expire
                  3h )       ; Negative Cache TTL
;
@    IN    NS    dns01.empresatech.example.
200  IN	   PTR	 web.empresatech.example.
```

<br/>

Clientes (`10.0.3.0/24`):

```bash
sudo vim /etc/bind/db.10.0.3
```

<br/>

Apague o conteúdo do arquivo e insira os dados abaixo:

```bash
$TTL	604800
@    IN    SOA    dns01.empresatech.example. admin.empresatech.example. (
                  2025100501 ; Serial
                  3h         ; Refresh
                  15m        ; Retry
                  3w         ; Expire
                  3h )       ; Negative Cache TTL
;
@    IN	   NS    dns01.empresatech.example.
200  IN    PTR	 dhcp01.empresatech.example.
202  IN    PTR	 filesrv01.empresatech.example.
203  IN    PTR	 ldap01.empresatech.example.
```

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
