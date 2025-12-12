# Ingressando Cliente Debian (Gnome) no domínio empresatech.example

<br/>

Este guia documenta como configurar uma estação de trabalho Debian para autenticar usuários através do servidor DC01.

<br>

## Panorama Geral da Solução

Vamos configurar o Debian para utilizar o **Realmd** e o **SSSD**. O objetivo é fazer com que o Debian consulte o **DC01** para validar senhas e permitir que usuários da **Empresa Tech** façam login na interface gráfica do Gnome.

* Servidor Alvo: DC01 (Controlador de Domínio)
* Domínio: empresatech.example
* Cliente: Debian com interface Gnome

<br>

## Pré-requisitos 

Antes de começar, a configuração de rede é o passo mais importante:

* **DNS**: O arquivo `/etc/resolv.conf` do cliente Debian deve ter o IP do **DC01** como servidor de nomes principal. Sem isso, o Debian não encontrará o domínio `empresatech.example`.
* **Conectividade**: Tente executar `ping dc01.empresatech.example` no terminal do cliente. Se responder, você está pronto.

---

## Implementação
  
Abra o terminal no seu cliente Debian e siga os comandos abaixo.

<br>

### Passo 1: Configurar o Nome da Máquina (Hostname)

Vamos definir o nome deste computador. Usaremos `estacao01` como exemplo para manter a organização da empresa.

```bash
# Define o nome completo (FQDN) da estação
sudo hostnamectl set-hostname estacao01.empresatech.example

# Verifica se a alteração foi aplicada
hostname -f
``` 

<br>

Saída esperada: 

```
estacao01.empresatech.example
```

<br>

### Passo 2: Instalar Pacotes de Integração

Instale o `realmd` e as dependências necessárias para a comunicação com o AD.

```bash
sudo apt update
sudo apt install realmd sssd sssd-tools libnss-sss libpam-sss adcli packagekit -y
``` 

<br>

Saída esperada: 

```
estacao01.empresatech.example
```

<br>

### Passo 3: Descobrir o Domínio

Vamos verificar se o cliente consegue encontrar o domínio gerenciado pelo DC01.

```bash
# Faz a varredura na rede pelo domínio
sudo realm discover empresatech.example
``` 
>Se a configuração de DNS estiver correta, o sistema retornará informações sobre o domínio `empresatech.example` e o software necessário (sssd).

<br>

### Passo 4: Ingressar no Domínio

Agora faremos a união oficial.

```bash
# Ingressa no domínio usando o usuário Administrator
sudo realm join empresatech.example -U administrator
``` 
>O terminal pedirá a senha do usuário **Administrator** do domínio (aquela definida na criação do DC01). Digite-a e aguarde (não aparecerão asteriscos).

<br>

### Passo 5: Configurar Criação Automática de Pasta Pessoal

Para que o usuário do domínio tenha onde salvar seus arquivos ao logar pela primeira vez no Gnome.

```bash
sudo pam-auth-update
``` 

1. Uma tela azul aparecerá.
2. Certifique-se de que a opção "**Create home directory on login**" está marcada (tem um asterisco `[*]`). Se não estiver, use a tecla `Espaço` para marcar.
3. Pressione `Tab` para selecionar **<Ok>** e pressione **Enter**.

---

## Explicação do Código
  
* `hostnamectl ... estacao01...`: O Active Directory precisa saber exatamente quem é a máquina. Usar o sufixo `.empresatech.example` ajuda o DNS a rotear corretamente.
* `realm join empresatech.example`: Este comando automatiza a configuração do Kerberos e do SSSD. Ele cria a conta de computador "ESTACAO01" dentro do banco de dados do AD no DC01.
* `-U administrator`: Especifica que estamos usando a conta suprema do domínio para autorizar essa adição.

---

## Verificação e Login
  
Antes de reiniciar ou fazer logoff, teste a comunicação com o DC01:

```bash
# Tente obter informações de um usuário (ex: administrator)
id administrator@empresatech.example
```
>Se aparecer `uid=... gid=... groups=...,` a conexão está perfeita.


<br>

Para entrar com a interface gráfica:

* Faça **Logoff** do usuário local.
* Clique em "**Não está listado?**".
* **Usuário**: `carla.dias@empresatech.example` (ou outro usuário que você criou no AD).
* **Senha**: A senha do usuário.

---