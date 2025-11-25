# Infraestrutura de Servidores Linux – Projeto Educacional

Este repositório faz parte de um projeto educacional desenvolvido para alunos iniciantes na área de Redes de Computadores e Administração de Sistemas Linux.  
O objetivo é fornecer **documentação detalhada, passo-a-passo**, para que qualquer aluno consiga reproduzir em laboratório toda a infraestrutura de servidores apresentada nas aulas.

A infraestrutura utiliza **Debian 13 "Trixie"**, virtualizada em **VirtualBox**, e inclui servidores essenciais como DHCP, DNS, Active Directory (Samba 4), File Server e Firewall com Nftables.  
Os clientes da rede são máquinas Windows 10/11 e Linux com interface gráfica Gnome.

## Topologia da Rede
![Topologia da Rede](diag_rede_linux.jpg)

## Objetivos do Projeto
- Ensinar os fundamentos e a prática de administração de servidores Linux.
- Demonstrar como construir uma infraestrutura corporativa completa em laboratório.
- Fornecer documentação clara e acessível para iniciantes.
- Servir como material de apoio educacional.

## Componentes da Infraestrutura

### Firewall
- WAN: DHCP Client  
- DMZ: 172.20.0.1/24  
- LAN: 192.168.100.1/24  
- Serviço: Nftables

### DMZ
- WEB01 – 172.20.0.200  
- SYS01 – 172.20.0.201 (porta 8080)

### LAN
- DC01 – 192.168.100.200 (Samba4 + Bind9)  
- DC02 – 192.168.100.201  
- DHCP01 – 192.168.100.202 (Kea DHCP4)  
- FS01 – 192.168.100.203 (Samba4 File Server)

## Estrutura do Repositório
docs/
├── FIREWALL/  
├── DC01/  
├── DC02/  
├── DHCP01/  
├── FS01/  
└── CLIENTES/

## Tecnologias Utilizadas
- Debian 13  
- Samba 4  
- Bind9  
- Kea DHCP  
- Nftables  
- Chrony  
- Windows 10/11  
- GNOME

## Como Usar
1. Acesse o diretório do servidor desejado.
2. Siga o README.md específico.
3. Valide os testes propostos.
4. Continue até montar toda a infraestrutura.

---

