# 🏢 Infraestrutura de Servidores - EmpresaTech

<br/>

## 📘 Visão Geral
Este repositório documenta a infraestrutura da **rede corporativa da EmpresaTech**, composta por servidores **Linux** e clientes **múltiplas plataformas (Linux e Windows)**.  
O ambiente está dividido em **duas zonas principais** — **LAN** e **DMZ** — e protegido por um **Firewall** que realiza NAT e controle de tráfego entre as redes internas e a Internet.

---

<br/>

## 🧩 Topologia de Rede

![Topologia da rede](diag_rede_linux.jpg)

---

<br/>

## 🌐 Redes

| Segmento | Faixa | Gateway | Descrição |
|-----------|--------|----------|-----------|
| **LAN** | `192.168.100.0/24` | `192.168.100.1` | Rede interna (servidores e clientes) |
| **DMZ** | `172.20.0.0/24` | `172.20.0.1` | Rede exposta à Internet |
| **WAN** | DHCP (IP público) | — | Interface externa do firewall |

---

<br/>

## 🖥️ Servidores da LAN

| Hostname | IP | Função | Serviços |
|-----------|----|--------|-----------|
| **DC01** | 192.168.100.200 | Controlador de Domínio Primário | Samba AD DC + BIND9 (DNS interno `empresatech.example`)|
| **DC02** | 192.168.100.201 | Controlador de Domínio Secundário | Samba AD DC + BIND9 (DNS interno `empresatech.example`)|
| **DHCP01** | 192.168.100.202 | Servidor DHCP | Kea DHCP4 Server|
| **FS01** | 192.168.100.203 | Servidor de Arquivos | Samba (membro do domínio) |

---

<br/>

## 🌍 Servidores da DMZ

| Hostname | IP | Função | Serviços |
|-----------|----|--------|-----------|
| **WEB01** | 172.20.0.200 | Servidor Web Público | Nginx (porta 80/443) |
| **SYS01** | 172.20.0.201 | Sistema CRUD | Backend (porta 8080) |

---

<br/>

## 🔥 Firewall

| Interface | IP | Rede | Função |
|------------|----|------|---------|
| **WAN** | DHCP (dinâmico) | Internet | Interface externa |
| **DMZ** | 172.20.0.1 | DMZ | Controle de entrada/saída |
| **LAN** | 192.168.100.1 | LAN | Gateway interno e NAT |

---

<br/>

## 🧭 Ordem de Implantação

1. **Firewall**: configurar NAT e rotas básicas.   
2. **DC01**: Samba AD + DNS interno  
3. **DC02**: Samba AD + DNS interno
4. **DHCP01**: Kea DHCP4 Server
5. **FS01**: Ingressar no domínio e configurar compartilhamentos.  
6. **WEB01/SYS01**: Configurar webserver e expor via DNAT.  

---

<br/>

## 🧰 Ferramentas Utilizadas

| Categoria | Software |
|------------|-----------|
| Sistema Operacional | Debian 13 (Trixie) |
| Servidor DHCP | Kea DHCP4 |
| Servidor DNS, Domínio e DHCP | Samba AD DC + BIND9 + Kea DHCP4 |
| Servidor de Arquivos | Samba |
| Firewall | nftables |
| Sincronismo de Tempo | Chrony |

---

<br/>

## 🧾 Autor

**Fernando Dias**  
Docente de Redes e Infraestrutura de Computadores  
💻 *Ambiente didático e técnico para aulas de manutenção e servidores Linux.*

---

<br/>

> 📦 **Repositório criado para estudos de infraestrutura de redes locais e serviços Linux integrados.**
>  
> 🔄 Pode ser utilizado como base para as UCs de **Redes**, **Serviços de Infraestrutura**, e **Administração de Servidores** no curso Técnico em Informática ou Redes.
