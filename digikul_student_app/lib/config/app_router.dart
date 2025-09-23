import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen_new.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen_new.dart';
import '../screens/explore_screen.dart';
import '../screens/cohort_details_screen_new.dart';
import '../screens/lecture_details_screen_new.dart';
import '../screens/live_session_screen_new.dart';
import '../screens/downloads_screen.dart';
import '../screens/profile_screen_new.dart';
import '../screens/settings_screen_new.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.fullPath == '/login' || state.fullPath == '/signup';
      
      // If not authenticated and not on login/signup page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      // If authenticated and on login/signup page, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Cohort routes
      GoRoute(
        path: '/cohort/:cohortId',
        builder: (context, state) {
          final cohortId = state.pathParameters['cohortId']!;
          return CohortDetailsScreen(cohortId: cohortId);
        },
      ),
      
      // Lecture routes
      GoRoute(
        path: '/lecture/:lectureId',
        builder: (context, state) {
          final lectureId = state.pathParameters['lectureId']!;
          return LectureDetailsScreen(lectureId: lectureId);
        },
      ),
      
      // Live session route
      GoRoute(
        path: '/live-session/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final lectureId = state.uri.queryParameters['lectureId'];
          return LiveSessionScreen(
            sessionId: sessionId,
            lectureId: lectureId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
