# ABD – PetCare (Frontend Flutter)

Projet Flutter mobile-first (Android/iOS), web optionnel. Données mockées via `abd_petcare/lib/core/services/mock_api_service.dart`.

## Prérequis
- Flutter SDK installé (ou FVM)

## Installation & Lancement
```bash
cd abd_petcare
flutter create --org com.skyaksa.abdpetcare --project-name abd_petcare --platforms=android,ios,web .
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