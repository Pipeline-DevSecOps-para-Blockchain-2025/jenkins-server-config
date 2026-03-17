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
ansible-playbook playbooks/devsecops-server.yaml
```

Atualizar serviços como `root`:

```sh
ansible-playbook playbooks/devsecops-server.yaml --tags all -Kb
```

## Testes

Veja [`cloud-init/README.md`](./cloud-init/README.md). Atualizações de infra com:

```sh
ansible-playbook playbooks/devsecops-server.yaml -l devsecops-libvirt-server
```
