# 🌐 DHCP Server – UC07

<br/>

## ⚙️ 1. Instalar o Kea DHCP Server

Atualize os repositórios e instale o serviço:

```bash
sudo apt update
sudo apt install kea-dhcp4-server -y
```

---

<br/>

## 🧾 2. Fazer backup do arquivo de configuração padrão

Antes de realizar qualquer modificação, crie um backup do arquivo original:

```bash
sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
```

---

<br/>

## 🧩 3. Criar o novo arquivo de configuração

Abra o arquivo principal do Kea DHCP para edição:

```bash
sudo vim /etc/kea/kea-dhcp4.conf
```

Em seguida, copie o conteúdo do arquivo [`kea-dhcp4.conf`](./kea-dhcp4.conf) deste repositório e ajuste conforme a infraestrutura da sua rede  
(ex.: nome da interface, gateway, faixa de IPs, domínio, etc.).

---

<br/>

## 📂 4. Criar diretórios para logs e leases

Crie os diretórios utilizados pelo Kea para armazenar logs e registros de concessões (leases):

```bash
sudo mkdir -p /var/log/kea /var/lib/kea
```

---

<br/>

## 🧪 5. Validar a configuração

Verifique se há erros no arquivo de configuração antes de iniciar o serviço:

```bash
sudo kea-dhcp4 -c /etc/kea/kea-dhcp4.conf -W
```

Se não houver erros, prossiga com a execução.

---

<br/>

## 🚀 6. Habilitar e iniciar o serviço do DHCP Server

Ative e inicie o serviço do Kea DHCP4:

```bash
sudo systemctl enable --now kea-dhcp4-server
```

<br/>

Verifique o status:

```bash
sudo systemctl status kea-dhcp4-server
```

---

<br/>

## 🔍 7. Testar o funcionamento

Conecte um cliente na rede e verifique se o IP foi atribuído automaticamente.

Você pode consultar o log de concessões em:

```bash
sudo cat /var/lib/kea/kea-leases4.csv
```
---