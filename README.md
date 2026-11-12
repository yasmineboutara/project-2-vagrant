# Déployer un site statique avec Ansible

Projet pédagogique : provisionner une VM Linux jetable, installer Nginx et publier un site statique. L'environnement cible repose sur Docker pour démarrer rapidement; le même playbook peut être utilisé avec une VM Vagrant.

## Architecture cible

- Un serveur Ubuntu 22.04 (conteneur de laboratoire par défaut, ou VM Vagrant) : Ansible se connecte en SSH; Nginx sert le site sur le port 80.
- Le poste de contrôle exécute Ansible. GitHub Actions reproduit le laboratoire Docker et lance le déploiement deux fois.
- Pour une évolution à deux serveurs : séparer le serveur web du reverse proxy, puis ajouter un groupe `proxy` et un rôle dédié. Ce projet garde un seul nœud pour limiter les prérequis.

Voir [docs/architecture.md](docs/architecture.md) pour l'inventaire et le plan de playbooks.

## Prérequis

Docker Desktop (profil Docker) ou VMware Workstation avec Vagrant et son plugin (profil VM), plus Ansible Core dans WSL. Sous Windows, exécuter les commandes Ansible depuis WSL ou un environnement Linux.

```sh
python3 -m pip install ansible-core
ssh-keygen -t ed25519 -N '' -f .lab/id_ed25519
export SSH_PUBLIC_KEY="$(cat .lab/id_ed25519.pub)"
export ANSIBLE_PRIVATE_KEY_FILE="$PWD/.lab/id_ed25519"
docker compose up -d --build
ansible-playbook playbooks/site.yml
curl http://localhost:8080
```

L'inventaire `inventory/lab.yml` cible le conteneur via SSH. `docker compose down` supprime le laboratoire.

## Idempotence

Le playbook utilise des modules Ansible déclaratifs, un template Nginx et un handler qui ne redémarre Nginx que si la configuration change. Relancer `ansible-playbook playbooks/site.yml` doit afficher `changed=0` au second passage. Le workflow GitHub Actions fait ces deux exécutions et échoue si la seconde modifie l'hôte.

## Secrets (Ansible Vault)

Le fichier Vault chiffré peut être versionné; ne commitez jamais son mot de passe. Créez un coffre chiffré localement :

```sh
ansible-vault create group_vars/all/vault.yml
```

Exemple de contenu à saisir dans l'éditeur : `vault_deploy_notice: "Environnement de démonstration"`.

Pour lancer le playbook, utilisez `ansible-playbook --ask-vault-pass playbooks/site.yml`. En CI, stockez le mot de passe dans le secret GitHub `ANSIBLE_VAULT_PASSWORD` et fournissez-le via un fichier temporaire hors du dépôt. Le rôle est prêt à consommer `vault_deploy_notice`; les secrets ne sont pas requis pour servir le site de démonstration.

## Variante VM avec Vagrant et VMware Workstation

Installer Vagrant, VMware Workstation et le Vagrant VMware Utility sur Windows, puis dans PowerShell installer le plugin :

```powershell
vagrant plugin install vagrant-vmware-desktop
```

Depuis le dossier du projet dans PowerShell, lancer `vagrant up --provider=vmware_desktop`. La première exécution télécharge l'image Ubuntu et peut prendre quelques minutes. Sous Windows 10, WSL ne peut pas toujours joindre le port SSH transféré par Vagrant sur Windows. La méthode de laboratoire ci-dessous exécute donc Ansible dans la VM sur le dossier partagé du projet :

```powershell
vagrant ssh
```

Dans la VM :

```bash
sudo apt update && sudo apt install -y ansible
cd /vagrant
ANSIBLE_ROLES_PATH=/vagrant/roles ansible-playbook -i 'web,' -c local playbooks/site.yml
```

Le site est ensuite accessible sur `http://localhost:8081`. Relancer la dernière commande Ansible doit produire `changed=0`. Pour arrêter la VM, quitter le shell invité puis exécuter `vagrant halt` dans PowerShell; pour la supprimer, `vagrant destroy`.

## Déploiement CI

Le workflow `.github/workflows/deploy.yml` construit un conteneur cible éphémère, crée une clé SSH temporaire, puis exécute le playbook deux fois. Dans ce projet d'exercice, le pipeline valide le déploiement sur une cible jetable. Pour un déploiement réel, remplacez cette cible par l'hôte d'environnement et stockez clé SSH et mot de passe Vault dans les secrets GitHub.

## Structure

```text
ansible.cfg                 Configuration Ansible
inventory/lab.yml           Inventaire SSH du conteneur
playbooks/site.yml          Point d'entrée
roles/webserver/            Installation, configuration et contenu Nginx
site/                       Site statique
Dockerfile, compose.yaml    VM de laboratoire SSH
```
