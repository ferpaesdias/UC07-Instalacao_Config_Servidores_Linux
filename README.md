# 🏢 Laboratório de Infraestrutura Corporativa com Debian 13

Bem-vindo ao guia passo a passo para a construção de uma infraestrutura de TI corporativa completa utilizando **Debian 13 "Trixie"**.

Este projeto foi desenhado para **iniciantes**. O objetivo não é apenas digitar comandos, mas entender como os servidores conversam entre si, como proteger uma rede e como gerenciar usuários em um ambiente profissional.

<br>

## 🗺️ Topologia de Rede

O nosso laboratório simula uma empresa real com segmentação de rede para segurança.

![Topologia de rede](diag_rede_linux.jpg)

| Zona | Sub-rede | Descrição |
| :--- | :--- | :--- |
| **WAN** | DHCP (ISP) | Conexão com a Internet (via NAT do VirtualBox) |
| **DMZ** | `172.20.0.0/24` | Zona Desmilitarizada (Serviços acessíveis de fora) |
| **LAN** | `192.168.100.0/24` | Rede Local (Servidores internos e Estações) |

<br>

## 🖥️ Inventário de Servidores

| Hostname | IP | Função | Software Principal |
| :--- | :--- | :--- | :--- |
| **FIREWALL** | **WAN**: DHCP Client | Gateway, Firewall, Roteamento | Nftables, Chrony |
| | **DMZ**: 172.20.0.1 | | |
| | **LAN**: 192.168.100.1 | |  |
| **DC01** | 192.168.100.200 | Controlador de Domínio Primário, DNS | Samba4 AD, Bind9 (interno) |
| **DC02** | 192.168.100.201 | Controlador de Domínio Secundário | Samba4 AD |
| **DHCP01** | 192.168.100.202 | Servidor de DHCP | ISC Kea DHCP4 |
| **FS01** | 192.168.100.203 | Servidor de Arquivos | Samba4 File Server |
| **WEB01** | 172.20.0.200 | Servidor Web (Intranet/Extranet) | Nginx |
| **SYS01** | 172.20.0.201 | Sistema Interno | App Customizada (:8080) |

<br>

## 👥 Estrutura de Usuários e Grupos

Neste laboratório, vamos gerenciar a autenticação centralizada. Estes são os funcionários da nossa empresa fictícia:

### 1. Departamento Financeiro (`Financeiro`)

* Ana Souza (`ana.souza`)
* Bruno Alves (`bruno.alves`)
* Carla Dias (`carla.dias`)
* Julia Pereira (`julia.pereira`)

<br>

### 2. Recursos Humanos (`RH`)

* Daniel Rocha (`daniel.rocha`)
* Elisa Martins (`elisa.martins`)
* Fabio Costa (`fabio.costa`)
* Igor Santos (`igor.santos`)

<br>

### 3. Tecnologia / TI (`TI`)

* Gabriel Lima (`gabriel.lima`)
* Helena Silva (`helena.silva`)

<br>

### 4. Diretoria (`Diretoria`)

* Luis Divino (`luis.divino`)
---

## 🛠️ Pré-requisitos

* Computador com suporte a virtualização (VT-x/AMD-V).
* VirtualBox ou KVM/QEMU instalado.
* ISO do **Debian 13 (Trixie)** Netinst.
* Vontade de aprender!

---