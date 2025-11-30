# 🐧 Projeto: Infraestrutura de Redes Linux (Debian 13)

Bem-vindo ao laboratório prático de Infraestrutura de Redes **Empresa Tech**.

Este projeto é um guia educacional passo-a-passo destinado a estudantes de redes e administração de sistemas. O objetivo é simular um ambiente corporativo real, construindo uma infraestrutura completa baseada em **Linux Debian 13 "Trixie"**, desde o firewall de borda até ao controlador de domínio e servidor de arquivos.

<br/>

## 🎯 Objetivo Educacional
Ao concluir este projeto, o aluno será capaz de:
* Configurar interfaces de rede e roteamento estático em Linux.
* Implementar um **Firewall** de borda seguro com *Nftables*.
* Configurar um **Controlador de Domínio (Active Directory)** usando *Samba 4*.
* Gerenciar serviços essenciais como **DNS** (Bind9) e **DHCP** (Kea).
* Configurar um **Servidor de Arquivos** integrado ao domínio com permissões avançadas.
* Realizar troubleshooting e validação de serviços de rede.

---

## 🏗️ Topologia e Cenário

A "Empresa Tech" possui uma infraestrutura dividida em três zonas de rede:
1.  **WAN (Internet):** Conexão externa.
2.  **DMZ (172.20.0.0/24):** Zona Desmilitarizada para servidores expostos (Web).
3.  **LAN (192.168.100.0/24):** Rede interna segura onde residem os dados e usuários.

![Diagrama de Rede](diag_rede_linux.jpg)

<br/>

### 🖥️ Inventário de Servidores

| Hostname | IP (LAN) | IP (DMZ) | Função | Tecnologia |
| :--- | :--- | :--- | :--- | :--- |
| **Firewall** | `192.168.100.1` | `172.20.0.1` | Gateway, NAT, Filtro de Pacotes | Nftables |
| **DC01** | `192.168.100.200` | - | Controlador de Domínio Primário (AD/DNS) | Samba 4, Bind9 |
| **DC02** | `192.168.100.201` | - | Controlador de Domínio Secundário | Samba 4 |
| **DHCP01** | `192.168.100.202` | - | Servidor de DHCP | Kea-DHCP4 |
| **FS01** | `192.168.100.203` | - | Servidor de Arquivos | Samba 4 |

---

## 👥 Estrutura Organizacional

O ambiente simula departamentos reais com usuários fictícios para testar permissões e políticas.

* **Domínio:** `empresatech.example`
* **Departamentos:**
    * 📂 **Vendas:** (Ex: Valter Gateway Perdido, Débora Buffer Overflow)
    * 📂 **Financeiro:** (Ex: Zé do DHCP Maluco, Tânia Packet Loss)
    * 📂 **TI:** (Ex: Adalberto Kernel Panela, Neide Loop Infinito)
    * 📂 **Suporte:** (Ex: Belarmino VLAN Fantasma, Juvêncio Firewall Furado)
    * 📂 **RH:** (Ex: Clésio DNS Travado, Fabiana Latência Braba)

---

## 🛠️ Tecnologias e Requisitos

Para reproduzir este laboratório, você precisará de um ambiente de virtualização.

### Software
* **Virtualizador:** VirtualBox, VMware Workstation ou Proxmox.
* **SO Servidores:** Imagem ISO do [Debian 13 (Testing/Trixie)](https://www.debian.org/devel/debian-installer/).
* **Clientes:** Windows 10/11 ou Linux com Interface Gráfica (Gnome/KDE).

<br/>

### Hardware Recomendado (Mínimo por VM)
* **Firewall:** 1 vCPU, 1 GB RAM, 15GB HD (3 Placas de Rede).
* **Servidores (Sem GUI):** 1 vCPU, 1 GB RAM, 15GB HD.
* **Clientes:** 2 vCPU, 4GB RAM.

---

## 🚀 Como usar este guia

Este repositório está organizado por servidor. Recomenda-se seguir a implementação na seguinte ordem lógica para garantir que as dependências (como DNS e Gateway) estejam funcionais:

1.  [Configuração do Firewall](1.firewall/Configuração_Firewall.md) 🛡️ *(Gateway e Internet)*
2.  [Configuração do DC01](2.dc01/Configuração_DC01.md) 👑 *(Identidade e DNS)*
3.  [Configuração do DHCP01](3.dhcp01/Configuração_DHCP01.md) 📡 *(Distribuição de IPs)*
4.  [Configuração do DC02](4.dc02/Configuração_DC02.md) 🔄 *(Redundância)*
5.  [Configuração do FS01](5.fs01/Configuração_FS01.md) 📂 *(Arquivos e Permissões)*

---

## 📝 Licença

Este projeto é de código aberto e destinado fins educacionais. Sinta-se à vontade para fazer fork, contribuir e usar em suas aulas ou estudos.

---
*Desenvolvido como material de apoio para aulas de Infraestrutura de Redes.*