# 🗂️ Servidor de Arquivos – FILESRV01

Servidor responsável por **armazenar e compartilhar arquivos** entre os usuários da rede local utilizando o **Samba 4**.

---

## 🌐 Informações da Máquina

| Configuração | Valor |
|---------------|--------|
| **Hostname** | FILESRV01 |
| **Função** | Servidor de Arquivos |
| **Sistema Operacional** | Debian 13 (Trixie) |
| **Endereço IP** | `10.0.3.202/24` |
| **Gateway** | `10.0.3.1` |
| **DNS** | `10.0.3.201` |
| **Rede** | LAN Empresa (`10.0.3.0/24`) |

---

## 🧱 1️⃣ Instalação

```bash
sudo apt update
sudo apt install samba -y
```
Verifique se o serviço está ativo:
```bash
systemctl status smbd nmbd
```
Habilite no boot:
```bash
sudo systemctl enable smbd nmbd
```

---

## 🧩 2️⃣ Estrutura de diretórios

```bash
sudo mkdir -p /srv/compartilhamentos/{secretaria,financeiro,rh,suporte}
sudo groupadd secretaria
sudo groupadd financeiro
sudo groupadd rh
sudo groupadd suporte

sudo chown -R root:secretaria /srv/compartilhamentos/secretaria
sudo chown -R root:financeiro /srv/compartilhamentos/financeiro
sudo chown -R root:rh /srv/compartilhamentos/rh
sudo chown -R root:suporte /srv/compartilhamentos/suporte

sudo chmod -R 770 /srv/compartilhamentos/*
sudo chmod 755 /srv/compartilhamentos/
```

---

## 👥 3️⃣ Criação de usuários

```bash
sudo useradd -m -G secretaria maria
sudo useradd -m -G financeiro joao
sudo useradd -m -G rh carla
sudo useradd -m -G suporte paulo

sudo passwd maria
sudo passwd joao
sudo passwd carla
sudo passwd paulo

sudo smbpasswd -a maria
sudo smbpasswd -a joao
sudo smbpasswd -a carla
sudo smbpasswd -a paulo
```

---

## ⚙️ 4️⃣ Arquivo de configuração `/etc/samba/smb.conf`

```ini
[global]
   # Nome do grupo de trabalho (Padrão do Windows)
   workgroup = EMPRESATECH

   # Nome NetBIOS do servidor (como será visto na rede) 
   netbios name = FILESRV01

   # Descrição do servidor exibido no ambiente de rede
   server string = Servidor de Arquivos - FILESRV01

   # Tipo de segurança: autenticação por usuário
   security = user

   # Mapeia tentativas de login anônimas para o usuário "guest"
   map to guest = Bad User

   # Desativa uso de servidor DNS externo para resolução NetBIOS
   dns proxy = no

   # Arquivo de log individual por cliente conectado
   log file = /var/log/samba/log.%m

   # Tamanho máximo de cada log
   max log size = 1000

   # Interfaces de rede que o Samba deve escutar
   interfaces = lo enp0s3

   # Restringe o Samba a apenas as interfaces definidas acima
   bind interfaces only = yes

   # Define o charset usado no servidor Linux e nos clientes Windows
   unix charset = UTF-8
   dos charset = CP850

   # Segurança e compatibilidade 
   # Define protocolos mínimos permitidos (SMB2 e superior)
   server min protocol = SMB2
   client min protocol = SMB2

   # Habilita autenticação NTLM (necessário para clientes Windows 10/11)
   ntlm auth = yes

# -------------------
# Compartilhamentos
# -------------------

# =============================================
# Diretório: /srv/compartilhamentos/secretaria
# Grupo de acesso: secretaria
# =============================================
[Secretaria]
   # Caminho físico da pasta
   path = /srv/compartilhamentos/secretaria  

   # Visivel no ambiente de rede   
   browseable = yes
   
   # Permite gravação de arquivos                             
   writable = yes            

   # Somente membros do grupo "secretaria"                   
   valid users = @secretaria              

   # Permissões padrão para novos arquivos
   create mask = 0660

   # Permissões padrão para novos diretórios      
   directory mask = 0770

   # Descrição exibida na rede                        
   comment = Pasta do setor de Secretaria       

# =============================================
# Diretório: /srv/compartilhamentos/financeiro
# Grupo de acesso: financeiro
# =============================================
[Financeiro]
   path = /srv/compartilhamentos/financeiro
   browseable = yes
   writable = yes
   valid users = @financeiro
   create mask = 0660
   directory mask = 0770
   comment = Pasta do setor Financeiro

# =============================================
# Diretório: /srv/compartilhamentos/rh
# Grupo de acesso: rh
# =============================================
[RH]
   path = /srv/compartilhamentos/rh
   browseable = yes
   writable = yes
   valid users = @rh
   create mask = 0660
   directory mask = 0770
   comment = Pasta do setor de Recursos Humanos

# =============================================
# Diretório: /srv/compartilhamentos/suporte
# Grupo de acesso: suporte
# =============================================
[Suporte]
   path = /srv/compartilhamentos/suporte
   browseable = yes
   writable = yes
   valid users = @suporte
   create mask = 0660
   directory mask = 0770
   comment = Pasta do setor de Suporte Técnico

```

---

## 🔍 5️⃣ Testar configuração

```bash
testparm
sudo systemctl restart smbd
```

---

## 💻 6️⃣ Acesso pelos clientes

**Linux:**
```bash
smbclient -L //10.0.3.202 -U maria
sudo mount -t cifs //10.0.3.202/Secretaria /mnt/secretaria -o username=maria
```

**Windows:**
```
\\10.0.3.202
```

---

## 🧠 Dicas Extras

```bash
tail -f /var/log/samba/log.smbd
```
Para restringir o acesso apenas à LAN:
```ini
hosts allow = 10.0.3.0/24
hosts deny = 0.0.0.0/0
```
