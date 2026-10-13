# Project State (read this first)
Last updated: 2026-10-13 by build Loans list and return action vertical slice

## Stack and run commands
- Backend: Node.js (Express, pg, bcrypt, jsonwebtoken). Run: `cd backend && npm start` (port 3000). Dev: `npm run dev`.
- Database: PostgreSQL. Init: `npm run db:init`, Demo data: `npm run db:demo`, Reset: `npm run db:reset`.
- Mobile: Flutter 3.x / Dart. Run: `cd mobile && flutter run` (emulator default: `http://10.0.2.2:3000/api`).
- Physical Phone: Run via tunnel or LAN: `flutter run --dart-define=API_BASE_URL=https://<tunnel-host>/api` or `http://<LAN_IP>:3000/api`.

## Architecture map
- `backend/src/domain/`: Pure domain entities and repository interfaces.
- `backend/src/infrastructure/`: Database pool and PostgreSQL repository implementations.
- `backend/src/usecases/`: Application business logic.
- `backend/src/interfaces/http/`: Express controllers, middleware (auth, validation, errors), and routes.
- `mobile/lib/core/`: ApiClient, constants, exceptions, theme (M3), reusable widgets, AppRouter.
- `mobile/lib/features/<name>/domain/`: Feature entities, repository contracts, and use cases.
- `mobile/lib/features/<name>/data/`: Models, remote data sources, repository implementations.
- `mobile/lib/features/<name>/presentation/`: ChangeNotifier controllers, screens, and widgets.

## Feature status
| Feature | Backend | Mobile | Notes |
|---------|---------|--------|-------|
| auth | Complete | Complete | Login, logout, session restore, auto-logout on 401. No registration. |
| books | Complete | Complete | Restyled with M3 widgets (AppCard, SearchField, EmptyState, ErrorState, LoadingIndicator, RefreshIndicator); librarian controls protected. |
| members | Complete | Complete | MemberListScreen, MemberFormScreen (createUser switch & one-time temp password dialog), delete confirmation, 409 error handling. |
| loans | Complete | Complete | LoanListScreen (Active/Overdue/Returned ChoiceChips, Return book action with confirmation, overdue highlight, friendly 409). Issue loan form pending. |
| dashboard | Derived | Complete | Uses books, loans, members endpoints client-side for 4 StatCards & overdue list. |
| settings | Complete | Complete | SettingsScreen shows user profile, role, debug API base URL, and logout with confirmation. |

## Key files per feature
- Auth: `backend/src/interfaces/http/routes/auth.routes.js`, `mobile/lib/features/auth/presentation/controllers/auth_controller.dart`, `mobile/lib/features/auth/presentation/screens/login_screen.dart`
- Books: `backend/src/interfaces/http/routes/book.routes.js`, `mobile/lib/features/books/presentation/controllers/books_controller.dart`, `mobile/lib/features/books/presentation/screens/book_list_screen.dart`
- Members: `backend/src/interfaces/http/routes/member.routes.js`, `mobile/lib/features/members/presentation/controllers/members_controller.dart`, `mobile/lib/features/members/presentation/screens/member_list_screen.dart`, `mobile/lib/features/members/presentation/screens/member_form_screen.dart`
- Loans: `backend/src/interfaces/http/routes/loan.routes.js`, `mobile/lib/features/loans/presentation/controllers/loans_controller.dart`, `mobile/lib/features/loans/presentation/screens/loan_list_screen.dart`
- Settings: `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- Dashboard: `mobile/lib/features/dashboard/presentation/controllers/dashboard_controller.dart`, `mobile/lib/features/auth/presentation/screens/home_screen.dart`
- Shell & Navigation: `mobile/lib/core/widgets/main_shell.dart`, `mobile/lib/core/router/app_router.dart`

## API contract
- Full contract documented at: `/docs/api-contract.md`.

## Conventions
- State manager: `Provider` with `ChangeNotifier` controllers.
- Error types: `AppException` subclasses (`ValidationException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ConflictException`, `ServerException`, `NetworkException`).
- Naming: camelCase for variables/JSON keys, PascalCase for classes, snake_case for filenames.
- Theme & Widgets location: `mobile/lib/core/theme/` (`app_theme.dart`, `app_spacing.dart`), `mobile/lib/core/widgets/` (`widgets.dart`, `app_card.dart`, `stat_card.dart`, `status_chip.dart`, `search_field.dart`, `empty_state.dart`, `error_state.dart`, `loading_indicator.dart`, `main_shell.dart`).

## Known issues and UNVERIFIED items
- UNVERIFIED: Physical phone network latency/firewall on specific local Wi-Fi router configurations without cloudflared tunnel.
- Known: Cloudflared quick tunnel URLs change when restarted without a named tunnel configuration.

## Next task
- Build Issue Loan form (FAB in Loans tab, searchable active member picker, searchable available book picker, 14-day default due date).
