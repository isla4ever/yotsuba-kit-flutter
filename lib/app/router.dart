import 'package:go_router/go_router.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/schedule_screen.dart';
import 'package:yotsuba_schedule/features/settings/presentation/settings_screen.dart';
import 'package:yotsuba_schedule/features/shell/app_shell.dart';
import 'package:yotsuba_schedule/features/today/presentation/today_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/schedule',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ScheduleScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TodayScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
