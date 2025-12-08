# 🧩 Configuração Detalhada — Servidor DHCP01
**Sistema:** Debian 13 (Trixie)  
**Função:** Servidor DHCP (Kea DHCP4 Server)  
**Endereço IP:** `192.168.100.202/24`  
**Gateway:** `192.168.100.1`  
**DNS:** `192.168.100.201`  
**Domínio:** `empresatech.example`

---

## 1️⃣ Instalação dos Pacotes

```bash
sudo apt update
sudo apt install -y kea-dhcp4-server kea-admin kea-common
```

* O pacote `kea-dhcp4-server` fornece o daemon principal do Kea para IPv4.  
* `kea-admin` gerencia o banco de dados de leases.  
* `kea-shell` arquivos de suporte e utilitários CLI básicos.

---

## 2️⃣ Configuração de Rede Estática

Arquivo: `/etc/network/interfaces.d/eth0`

```bash
auto eth0
iface eth0 inet static
    address 192.168.100.202/24
    gateway 192.168.100.1
    dns-nameservers 192.168.100.201
    dns-search empresatech.example
```

Reinicie a interface:
```bash
sudo systemctl restart networking
```

---

## 3️⃣ Configuração do Kea DHCP4

Crie um backup do arquivo de configuração

```bash
sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bkp
```

<br/>

Crie o arquivo `/etc/kea/kea-dhcp4.conf` com o conteúdo abaixo. Altere a interface de rede de acordo com o seu ambiente:

```jsonc
{
"Dhcp4": {
  // Interface o Kea deve "ouvir" pedidos DHCP
  "interfaces-config": {
    "interfaces": [ "enp0s3" ]
  },

  // 2. Base de dados de leases (quem alugou qual IP)
  "lease-database": {
      "type": "memfile",
      "lfc-interval": 3600
  },

  // 3. Configuração da nossa Sub-rede LAN
  "subnet4": [
    {
      // ID da subnet
     "id": 1,

      // A rede que vamos servir
      "subnet": "192.168.100.0/24",

      // A faixa de IPs que será distribuída (ex: 50 a 150)
      "pools": [
        { "pool": "192.168.100.50 - 192.168.100.150" }
      ],

      // 4. Opções que serão entregues aos clientes (PC01, PC02, etc.)
      "option-data": [
        {
          // Opção 3: O Gateway (Router)
          "name": "routers",
          "data": "192.168.100.1"
        },
        {
          // Opção 6: O Servidor de DNS
          "name": "domain-name-servers",
          "data": "192.168.100.201"
        },
        {
          // Opção 15: O nome do domínio
          "name": "domain-search",
          "data": "empresatech.example"
        }
      ]
    }
  ],

  // Configuração de Logging (opcional)
  "loggers": [
    {
      "name": "kea-dhcp4",
      "output_options": [
        {
          "output": "/var/log/kea/kea-dhcp4.log",
          "maxsize": 1048576,
          "maxver": 4
        }
      ],
      
      "severity": "INFO",
      "debuglevel": 0
      }
    ]
  }
}
```

<br />

Verifique a sintaxe:
```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
```

---

## 4️⃣ Habilitar e Iniciar o Serviço

```bash
sudo systemctl enable kea-dhcp4-server
sudo systemctl start kea-dhcp4-server
sudo systemctl status kea-dhcp4-server
```

Logs:
```bash
sudo journalctl -u kea-dhcp4-server -f
```

---

## 5️⃣ Teste de Funcionamento

Em um **cliente Linux ou Windows** configurado como DHCP:

```bash
ip addr show
# ou
ipconfig /all
```

O cliente deve receber:
- IP entre `192.168.100.50–150`
- Gateway: `192.168.100.1`
- DNS: `192.168.100.201`
- Domínio: `empresatech.example`

---

## 6️⃣ (Opcional) Reserva de IPs

```jsonc
"reservations": [
  {
    "hw-address": "00:11:22:33:44:55",
    "ip-address": "192.168.100.60",
    "hostname": "cliente01"
  }
]
```

---

## 7️⃣ Verificação dos Leases

```bash
sudo cat /var/lib/kea/kea-leases4.csv
```

---

## 8️⃣ Integração com o DC01 (DNS)

O Kea apontará para o **DC01 (192.168.100.201)** como servidor DNS.  
Se desejar integração dinâmica de DNS (DDNS), será necessário configurar o Kea Control Agent e o Bind9 (no DC01) com TSIG — configuração opcional para o ambiente atual.

---

## 9️⃣ Backup e Restauração

Backup:
```bash
sudo cp /etc/kea/kea-dhcp4.conf /root/backup/
sudo cp /var/lib/kea/kea-leases4.csv /root/backup/
```

Restauração:
```bash
sudo cp /root/backup/kea-dhcp4.conf /etc/kea/
sudo cp /root/backup/kea-leases4.csv /var/lib/kea/
sudo systemctl restart kea-dhcp4-server
```

---

## 10️⃣ Troubleshooting

| Comando | Função |
|----------|--------|
| `sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf` | Testa o arquivo de configuração |
| `sudo journalctl -u kea-dhcp4-server` | Visualiza logs |
| `sudo systemctl restart kea-dhcp4-server` | Reinicia o serviço |
| `sudo ss -ulpn | grep 67` | Verifica se o Kea está escutando na porta UDP 67 |
| `sudo tail -f /var/log/kea-dhcp4.log` | Acompanha o log em tempo real |
