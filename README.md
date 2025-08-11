# ABD – PetCare (Frontend Flutter)

Projet Flutter mobile-first (Android/iOS), web optionnel. Données mockées via `abd_petcare/lib/core/services/mock_api_service.dart`.

## Prérequis
- Flutter SDK installé (ou FVM)

## Installation & Lancement
```bash
cd abd_petcare
flutter create --org com.abdpetcare.app --project-name abd_petcare --platforms=android,ios,web .
flutter pub get
flutter run -d <device_id>
```

## Navigation principale
- /login → /register → /settings/notifications → /dashboard

## Notes
- Thème Material 3 pastel (`lib/core/theme/app_theme.dart`)
- go_router (`lib/router/app_router.dart`)
- Garde d’auth via SharedPreferences (`lib/core/services/auth_state.dart`)
- Mocks: `MockApiService`
- Seuils centralisés: `lib/core/constants/app_constants.dart`
- Statuts KPI: `lib/core/utils/status_utils.dart`

Note: Les seuils d’alerte sont modifiables dans `lib/core/constants/app_constants.dart`.

## À propos
- Page: `/about` (titre "À propos", version, crédits, note de démo)

## Identifiant de package (org neutre)
- Utilisé: `com.abdpetcare.app`
- NOTE: Si le projet a été créé avec une autre org, régénérez via:
  - `flutter create --org com.abdpetcare.app --project-name abd_petcare --platforms=android,ios,web .`
  - ou renommez manuellement l'applicationId (Android) et le Bundle Identifier (iOS).

## Parcours de test
- login/register → settings → dashboard → refresh → logout → about