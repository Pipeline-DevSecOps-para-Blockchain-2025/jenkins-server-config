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

```sh
ansible-playbook playbooks/devsecops-server.yaml -l jenkins-server-docker --ask-vault-pass
```

Atualizar serviços como `root`:

```sh
ansible-playbook playbooks/devsecops-server.yaml -l jenkins-server-docker --tags all --ask-vault-pass -Kb
```

## Testes

Veja [`cloud-init/README.md`](./cloud-init/README.md). Atualizações de infra com:

```sh
ansible-playbook playbooks/devsecops-server.yaml -l devsecops-libvirt-server
```
