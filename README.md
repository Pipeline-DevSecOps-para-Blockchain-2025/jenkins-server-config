# Pipeline DevSecOps para Smart Contracts - Infraestrutura

## Configuração

## Serviços esperados

O playbook `playbooks/devsecops-server.yaml` configura um único host Fedora com dois grupos de serviços:

- `system`: pacotes base, firewall, usuário `runner`, nginx, sshd, certbot, ferramentas interativas e Podman.
- `user`: serviços rootless do `runner`, hoje `jenkins` e `grafana`.

Fluxo esperado por papel:

- `nginx` publica os endpoints de Jenkins e Grafana.
- `jenkins` cria segredos do Podman para GitHub App, PAT e SendGrid, aplica a configuração CasC e sobe os quadlets do controller e do Docker-in-Docker.
- `grafana` cria o segredo de admin, aplica dashboards, datasources e regras de alerting, e sobe os quadlets do Grafana, renderer e VictoriaMetrics.

Os segredos de serviço são carregados em `pre_tasks` a partir de `secret_vars/{{ inventory_hostname }}.yaml`.

### Criação de senhas

Senhas para Linux:

```sh
mkpasswd -m yescrypt -R 11
```

Senhas para o serviço Jenkins:

```sh
mkpasswd -m bcrypt -R 12 | sed 's/$2b/$2a/'
```

## Vault e segredos

Inspecionar um arquivo de segredos:

```sh
ansible-vault view secret_vars/jenkins-server-docker.yaml
```

Editar os segredos de um host:

```sh
ansible-vault edit secret_vars/jenkins-server-docker.yaml
```

Criar um novo arquivo criptografado:

```sh
ansible-vault create secret_vars/novo-host.yaml
```

Criptografar um arquivo em claro:

```sh
ansible-vault encrypt secret_vars/devsecops-libvirt-server.yaml
```

Fluxo comum:

```sh
ansible-vault edit secret_vars/jenkins-server-docker.yaml
ansible-playbook playbooks/devsecops-server.yaml -l jenkins-server-docker --ask-vault-pass
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
