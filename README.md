
## ABD PetCare — Frontend (Flutter)

Ce dépôt contient l'application mobile Flutter utilisée pour piloter et visualiser
les données du système ABD CatCare (capteurs RuuviTag, alertes, profils chat, etc.).

Ce README décrit l'architecture front/backend, les points d'entrée API principaux,
et comment basculer rapidement entre le mode mock (local) et l'API réelle (dev).

## Architecture (haute-niveau)

- Frontend : Flutter (ce projet)
- Backend : NestJS microservices (Gateway, Auth, User, Cat, Sensor, Communication)
- Communication inter-services : NATS
- Capteurs : RuuviTag via MQTT
- DB / cache : PostgreSQL, Redis

L'API Gateway expose la documentation Swagger sur : http://localhost:3000/api

## Structure importante du frontend

- `lib/core/services/` : services applicatifs (auth, api client, mock, provider)
  - `api_client.dart` : client HTTP minimal (baseUrl, get/post/put/delete)
  - `auth_service.dart` : gestion des tokens (SharedPreferences) et endpoints `/auth/*`
  - `mock_api_service.dart` : faux back-end pour développement hors ligne
  - `api_provider.dart` : switch runtime entre mock et real 
- `lib/screens/` : écrans de l'application (login, register, dashboard, settings...)

## Basculement Mock ↔ API réelle (développement rapide)

Par défaut le projet contient un service de mock (`MockApiService`) utilisé pour le
développement hors-ligne. Pour basculer vers l'API réelle :

1. Ouvrir `lib/core/services/api_provider.dart`.
2. Mettre `ApiProvider.instance.useMock = false;` (ou modifier cette valeur au runtime).
3. Mettre à jour l'URL de base si nécessaire :

	- Modifier `ApiClient.instance.baseUrl` dans `lib/core/services/api_client.dart`.
	- Exemple :

```
ApiClient.instance.baseUrl = 'http://localhost:3000/api';
```

4. (Optionnel) Démarrer votre stack backend (voir section suivante).

Remarque : `ApiProvider` retourne soit une instance du `MockApiService`, soit
`RealApiService.instance`. Les écrans utilisent `ApiProvider.instance.get()` —
pas besoin de modifier plusieurs fichiers.

## Auth & Tokens

- Lors d'une connexion réussie, l'access token est stocké dans `SharedPreferences` (clé `catcare_token`).
- `AuthService` expose `login()`, `logout()` et `fetchCurrentUser()`.
- Les appels authentifiés utilisent l'en-tête `Authorization: Bearer <token>` via `AuthService.authHeader`.

# `TODO` voir avec l'équipe si refresh token 
Utilisez des refresh tokens côté backend, implémentez la logique de refresh dans `AuthService.authGet` (ou équivalent).

## Notifications (raisonnement & implémentation)

Objectif: notifications fiables, non redondantes, cohérentes entre plateformes.

- Responsabilités
  - Backend:
    - Détecte les anomalies et crée des Alertes.
    - Applique les préférences utilisateur (catégories/sévérité) et envoie via la file (push/email).
    - Persiste le flux des notifications (`NotificationEntity`).
  - Flutter :
  - Enregistre le token de l’appareil et gère l’affichage (liste, filtres, deep‑links).
  - Règles UI: badge « non lu », pas d’auto‑lecture à l’ouverture de la page; une notification passe à « lue » au tap. Action « résoudre » disponible selon le type.
    - Fallback: polling périodique si push inactif.

- Flux
1.  Données capteurs → Alerte créée → Notification en file + sauvegarde DB.
2. Mobile reçoit un push  Taper la notif ouvre l’écran ciblé.
3. Dans l’app, une notification devient « lue » lorsqu’elle est ouverte (action=tap).

- Endpoints côté app (tolérance aux variantes du gateway)
  - Feed (in‑app):
    - GET `/communication/notifications?limit=&offset=` → liste des notifications utilisateur.
    - POST `/communication/notifications/{id}/read` → marquer comme lue.
  - Alertes (actives):
    - GET `/cats/{catId}/alerts` (prioritaire), fallback GET `/sensors/alerts/{catId}`.
    - POST `/alerts/{alertId}/resolve`, fallback POST `/sensors/alerts/{alertId}/resolve`.

## TODO
  - Ajouter `firebase_messaging` et `flutter_local_notifications`.
  - À la connexion: enregistrer le `deviceToken` via un endpoint dédié (`POST /devices`).
  - Sur tap de push: deep‑link vers l’écran/alerte concerné(e).

## Quickstart Développement (frontend)

1. Installer les dépendances Flutter :

```bash
flutter pub get
```

2. Démarrer l'application (ex. debug sur un émulateur) :

```bash
flutter run
```

## Ressources

- Backend (NestJS) : Documentation & Swagger sur la Gateway (http://localhost:3000/api)
et ici https://github.com/eltraore/ABD-CatCare/edit/dev/README.md
- MQTT : broker et mapping des RuuviTag dans le service `MqttService` du backend

