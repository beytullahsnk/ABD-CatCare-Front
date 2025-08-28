
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

## Flux de connexion ( a test )

### Flux de connection

- L’écran appelle AuthState.signIn(identifier, password).
- Cela délègue à AuthService.login() qui fait POST /auth/login via ApiClient.
La réponse JSON est parsée pour récupérer :

```json
accessToken (ou token/access_token)
refreshToken (ou refresh_token)
```

AuthService.saveTokens() stocke ces valeurs dans SharedPreferences:
- catcare_token, catcare_refresh

 AuthState.setLoggedIn(true) enregistre aussi logged_in=true (clé SharedPreferences) et déclenche loggedIn (ValueNotifier) pour le router.

### Au démarrage de l'app

- main.dart appelle AuthState.load() avant runApp.
- AuthState.load():
- lit logged_in et met à jour loggedIn (influence go_router)
- charge les tokens en mémoire via AuthService.loadTokens() (pour préparer le header auth).

### Appels protégés avec le token
 - AuthService.authHeader construit {'Authorization': 'Bearer <accessToken>'}.
 -Les services réels (ex: RealApiService) passent ce header aux méthodes d’ApiClient:
ApiClient.get/post/put/delete(path, headers: AuthService.instance.authHeader).

Refresh token : pas test ni dev

AuthService.authGet() TODO si r.statusCode == 401: appeler un endpoint de refresh, sauvegarder le nouveau token, rejouer la requête.
À prévoir: POST /auth/refresh (ou équivalent backend), mise à jour des tokens, puis retry.


### Déconnexion

AuthState.signOut():
AuthService.logout() supprime les clés catcare_token/catcare_refresh.
setLoggedIn(false) met logged_in=false et notifie le router.
