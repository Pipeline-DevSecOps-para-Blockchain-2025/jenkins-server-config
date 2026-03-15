# Pipeline DevSecOps para Smart Contracts - Infraestrutura

## Configuração

### Criação de senhas

Senhas para Linux:

```sh
mkpasswd -m yescrypt -R 11
```

Senhas para o serviço Jenkins:

```sh
mkpasswd -m bcrypt -R 12 | sed 's/$2b/$2a/'
```

## Deploy

## Testes

Veja [`cloud-init/README.md`](./cloud-init/README.md).
