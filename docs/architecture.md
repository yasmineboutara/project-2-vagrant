# Architecture et plan d'automatisation

## Infrastructure cible

Le laboratoire comporte un seul hôte Ubuntu 22.04 joignable en SSH. Le profil Docker expose le port HTTP 8080 du poste vers le port 80 du serveur et le port SSH 2222 à Ansible. Le profil Vagrant/VMware expose le port HTTP 8080 et utilise le port SSH 2222 par défaut. Nginx sert le contenu statique depuis `/var/www/site`.

### Inventaire

| Groupe | Hôte | Connexion | Rôle |
| --- | --- | --- | --- |
| `web` | `web1` (`127.0.0.1:2222`) | utilisateur `deploy`, clé SSH | Nginx et site statique |

L'inventaire Docker est `inventory/lab.yml`; celui de la VM est `inventory/vagrant.yml`. Une installation réelle doit remplacer l'adresse et la clé par celles de l'environnement cible, sans stocker de clé privée dans Git.

## Plan des playbooks

1. `playbooks/site.yml` applique le rôle `webserver` au groupe `web` avec privilèges sudo.
2. `roles/webserver/tasks/main.yml` installe Nginx, crée le répertoire web et publie la configuration et le contenu.
3. `roles/webserver/handlers/main.yml` valide la configuration et recharge Nginx après modification.
4. `roles/webserver/templates/site.conf.j2` et `roles/webserver/defaults/main.yml` séparent configuration et paramètres.
5. `group_vars/all/vault.yml` est créé localement avec `ansible-vault`; il est ignoré par Git.

Les tâches sont idempotentes : paquets, répertoires, templates, fichiers et service sont gérés par leurs modules dédiés.
