# Phase 0 : Initialisation et Préparation

*Read the [English Version](README.md) here.*

## Objectif
Initialiser l'architecture du dépôt SRE (Projet 3), en s'appuyant sur l'infrastructure et l'application issues du Projet 2 (DevSecOps). Mettre en place les fondations nécessaires pour l'ajout ultérieur des briques d'observabilité, de fiabilité et de chaos engineering.

## Statut
**Terminé**

## Actions Réalisées

1. **Migration du Code Source**
   - Transfert des ressources du Projet 2 : le code de l'application (`/app`), l'Infrastructure as Code (`/terraform`), le workflow CI/CD (`.github/`), et la configuration SonarQube (`sonar-project.properties`).
   - Nettoyage des fichiers temporaires ou inutiles de l'ancien projet.

2. **Initialisation du Contrôle de Version**
   - Initialisation d'un dépôt Git propre dédié au projet SRE.
   - Création et adaptation du `.gitignore` pour exclure les futurs artefacts liés aux outils SRE locaux (données de Prometheus/Grafana) en plus des exclusions habituelles (nœuds, terraform.tfstate, secrets).
   - Validation et push du commit initial (« baseline ») vers GitHub.

3. **Validation de l'Existant (CI/CD et OIDC)**
   - Vérification de l'authentification sécurisée avec Azure via OIDC (OpenID Connect), empêchant la fuite de credentials.
   - Vérification que la pipeline CI/CD pré-existante (héritée du Projet 2) est prête et s'exécute correctement pour déployer l'application et l'infrastructure de départ sans les surcouches SRE.

## Dossiers Associés
- `app/`
- `terraform/`
- `.github/`
- `PLAN.md`
