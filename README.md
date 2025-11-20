# 📌 README — Projet Fullstack (React + Spring Boot + PostgreSQL + Nginx Reverse Proxy)

## 📖 Introduction

Ce projet est une application web complète composée de :

- un frontend React (servi en statique via Nginx)

- un backend Spring Boot exposant des endpoints REST

- une base PostgreSQL

- un reverse proxy Nginx servant de gateway unique pour / et /api

L’objectif : fournir un architecture propre, modulaire et entièrement conteneurisée avec Docker.

## 🏗️ 1. Architecture globale

                   ┌──────────────────────────────┐
                   │     Utilisateur / Client     │
                   └───────────────┬──────────────┘
                                   │
                HTTP - http://localhost/ (port 80)
                                   │
                        ┌──────────▼───────────┐
                        │   reverse-proxy      │
                        │ Reverse Proxy Nginx  │
                        └──────────┬───────────┘
                                   │
              ┌────────────────────┴─────────────────────┐
              │                                          │
           / (frontend React)                      /api (backend)
              │                                          │
      ┌───────▼────────┐                       ┌────────▼──────────┐
      │    webapp      │                       │   spring-api      │
      │ React build    │                       │ Spring Boot REST  │
      └────────────────┘                       └────────┬──────────┘
                                                        │ JDBC
                                                        │
                                               ┌────────▼──────────┐
                                               │       db          │
                                               │ PostgreSQL 16     │
                                               └───────────────────┘

- 👉 Le frontend ne communique qu’avec Nginx
- 👉 Le backend communique avec PostgreSQL uniquement via JDBC
- 👉 Pas de CORS grâce au reverse proxy

## 🚀 2. Commandes pour builder et lancer

1. Cloner le projet

    ```bash
    git clone <url-du-repo>
    cd <projet>
    ```

2. Build complet

    ```bash
    docker compose build
    ```

3. Lancer les services

    ```bash
    docker compose up -d
    ```

4. Arrêter

    ```bash
    docker compose down
    ```

## 🌐 3. URLs & Endpoints exposés

### 💻 Frontend React

<code>http://localhost/</code>

Servi statiquement via Nginx (reverse_proxy_service).

### 🛠️ Backend API Spring Boot

Toutes les routes sont accessibles via le reverse proxy :

<code>http://localhost/api/</code>

Exemples :

Méthode | URL | Description
--- | --- | ---
GET | /api/users | Liste des utilisateurs
POST | /api/users | Création d’un utilisateur
GET | /api/users/{id} | Détails d’un utilisateur

La communication API → DB se fait via JDBC :

<code>jdbc:postgresql://db:5432/\<dbname></code>

## 🛑 4. Problèmes rencontrés & Solutions

### ❌ 1. Erreur Nginx : "server directive is not allowed here"

#### Cause

Le fichier nginx.conf ne contenait pas la structure complète d’un fichier global

#### Solution

Se limiter à un fichier de conf dans conf.d/default.conf

### ❌ 2. Le backend ne se connectait pas à PostgreSQL

#### Problèmes rencontrés

Mauvaise URL JDBC

#### Solutions

Utilisation du bon hostname Docker :
<code>jdbc:postgresql://db:5432/\<dbname></code>

### ❌ 3. Variables d'environnement React non prises en compte

#### Cause

React (Vite) lit les variables au build, pas au runtime Docker.

#### Solution

Ajouter un argument de build pour injecter les variables au moment du build Docker.

### ❌ 4. Impossibilité de communiquer directement avec la webapp en mode dev

#### Cause

le mode host n'est pas activé au lancement du server

#### Solution

modifié dans le package.json du front la commande de démarrage du server en mode dev pour activer le mode host :

```json
"scripts": {
    "dev": "vite --host",
  },
```

### ❌ 5. La webapp est inaccessible en mode dev depuis le reverse proxy

#### Cause

en mode dev, la webapp React tourne sur le port 5173 et non 80

#### Solution

ajout d'une nouvelle configuration Nginx pour le reverse proxy en mode dev (nginx-dev.conf) qui redirige les requêtes vers le port 5173 de la webapp

## ⚙️ 5. Choix techniques & motivation

### 🔹 Configuration Nginx minimal du reverse proxy

- Gain de performance en évitant des configurations complexes

- Plus facile à maintenir

### 🔹 Séparation des réseaux Docker

- web_api_network pour front ⇄ back ⇄ reverse proxy

- api_database_network pour API ⇄ DB
→ Sécurité : seul  spring-api  eut toucher PostgreSQL

### 🔹 Localisation des DockerFile

- Chaque service a son propre Dockerfile dans son dossier
→ Clarté et modularité

### 🔹 Multi-stage builds

- Backend Spring Boot : compilation + runtime séparés

- Frontend React : build + Nginx séparés

→ Images finales légères et optimisées

### 🔹 Utilisation d’arguments de build pour React

- Permet d’injecter des variables d’environnement au moment du build Docker
→ Flexibilité pour différents environnements (dev, prod)

### 🔹 Utilisation d'image docker précit

- Pas de latest utilisé pour éviter les montées de version non contrôlées ou cassantes

- Base de donnée :
  - PostgreSQL:18 : dernière version stable avec correctifs de sécurité récents

- Backend :
  - Build : emaven:3.9-eclipse-temurin-21-alpine : dernière version stable de Maven avec JDK 21 et Alpine pour légèreté et rapidité
  - Runtime : eclipse-temurin:21-jre-alpine : JRE léger pour exécuter l’application Spring Boot
  - On utilise la version JDK 21 puisque le projet compile avec cette version.

- Frontend :
    - Build : node:25-alpine : dernière version stable de Node.js avec Alpine pour légèreté
    - Runtime : nginx:1.29-alpine : dernière version stable de Nginx avec Alpine pour légèreté

- Reverse Proxy :
  - nginx:1.29-alpine : dernière version stable de Nginx avec Alpine pour légèreté

### 🔹 Utilisation de multiple réseaux

- Isolation des services pour une meilleure sécurité
- Limitation de l’exposition des services uniquement à ceux qui en ont besoin

## 🎉 Conclusion

Cette architecture respecte les bonnes pratiques :

- Reverse proxy unique

- Front servie en statique

- Service isolé

- Base de données accessible uniquement par l’API

- Multi-réseaux Docker propres

- Pas de CORS

- Communication API → DB via JDBC exclusivement
