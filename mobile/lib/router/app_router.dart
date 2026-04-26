import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/attendance/screens/attendance_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/live_session/screens/live_session_screen.dart';
import '../features/materials/screens/materials_screen.dart';
import '../features/quiz/screens/quiz_attempt_screen.dart';
import '../features/quiz/screens/quiz_list_screen.dart';
import '../features/quiz/screens/quiz_result_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnauth = authState.status == AuthStatus.unauthenticated;
      final location = state.uri.path;

      final publicRoutes = ['/splash', '/login', '/register'];
      final isPublicRoute = publicRoutes.contains(location);

      if (isUnauth && location == '/splash') return '/login';
      if (!isAuth && !isPublicRoute) return '/login';
      if (isAuth && isPublicRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) =>
                const DashboardScreen(),
          ),
          GoRoute(
            path: '/materials',
            name: 'materials',
            builder: (context, state) =>
                const MaterialsScreen(),
            routes: [
              GoRoute(
                path: ':materialId',
                name: 'materialViewer',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Material Viewer'),
              ),
            ],
          ),
          GoRoute(
            path: '/quiz',
            name: 'quizList',
            builder: (context, state) =>
                const QuizListScreen(),
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (context, state) =>
                const AttendanceScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),

      GoRoute(
        path: '/quiz/:quizSetId/attempt',
        name: 'quizAttempt',
        builder: (context, state) => QuizAttemptScreen(
          quizSetId: state.pathParameters['quizSetId']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:quizSetId/result/:attemptId',
        name: 'quizResult',
        builder: (context, state) => QuizResultScreen(
          quizSetId: state.pathParameters['quizSetId']!,
          attemptId: state.pathParameters['attemptId']!,
        ),
      ),

      GoRoute(
        path: '/session/:sessionId',
        name: 'liveSession',
        builder: (context, state) => LiveSessionScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
    ],
  );
});

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Materials',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/materials')) return 1;
    if (location.startsWith('/quiz')) return 2;
    if (location.startsWith('/attendance')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/materials');
      case 2:
        context.go('/quiz');
      case 3:
        context.go('/attendance');
      case 4:
        context.go('/profile');
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}
