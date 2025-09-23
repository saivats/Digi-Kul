import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/cohort/cohort_details_screen.dart';
import '../screens/lecture/lecture_details_screen.dart';
import '../screens/live_session/live_session_screen.dart';
import '../screens/splash/splash_screen.dart';

// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isGoingToLogin = state.matchedLocation == AppConstants.loginRoute;
      final isGoingToSignup = state.matchedLocation == AppConstants.signupRoute;
      final isGoingToSplash = state.matchedLocation == AppConstants.splashRoute;

      // Show splash screen while initializing
      if (!isInitialized) {
        return AppConstants.splashRoute;
      }

      // If not authenticated and not going to login/signup, redirect to login
      if (!isAuthenticated && !isGoingToLogin && !isGoingToSignup && !isGoingToSplash) {
        return AppConstants.loginRoute;
      }

      // If authenticated and going to login/signup/splash, redirect to dashboard
      if (isAuthenticated && (isGoingToLogin || isGoingToSignup || isGoingToSplash)) {
        return AppConstants.dashboardRoute;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.signupRoute,
        builder: (context, state) => const SignupScreen(),
      ),

      // Main app routes
      GoRoute(
        path: AppConstants.dashboardRoute,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.exploreRoute,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: AppConstants.downloadsRoute,
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: AppConstants.settingsRoute,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.profileRoute,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Detail routes
      GoRoute(
        path: AppConstants.cohortDetailsRoute,
        builder: (context, state) {
          final cohortId = state.pathParameters['id']!;
          return CohortDetailsScreen(cohortId: cohortId);
        },
      ),
      GoRoute(
        path: AppConstants.lectureDetailsRoute,
        builder: (context, state) {
          final lectureId = state.pathParameters['id']!;
          return LectureDetailsScreen(lectureId: lectureId);
        },
      ),
      GoRoute(
        path: AppConstants.liveSessionRoute,
        builder: (context, state) {
          final sessionId = state.pathParameters['id']!;
          return LiveSessionScreen(sessionId: sessionId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.dashboardRoute),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation helper methods
extension AppRouterExtension on GoRouter {
  void goToDashboard() => go(AppConstants.dashboardRoute);
  void goToLogin() => go(AppConstants.loginRoute);
  void goToExplore() => go(AppConstants.exploreRoute);
  void goToDownloads() => go(AppConstants.downloadsRoute);
  void goToSettings() => go(AppConstants.settingsRoute);
  void goToProfile() => go(AppConstants.profileRoute);
  
  void goToCohortDetails(String cohortId) {
    go(AppConstants.cohortDetailsRoute.replaceAll(':id', cohortId));
  }
  
  void goToLectureDetails(String lectureId) {
    go(AppConstants.lectureDetailsRoute.replaceAll(':id', lectureId));
  }
  
  void goToLiveSession(String sessionId) {
    go(AppConstants.liveSessionRoute.replaceAll(':id', sessionId));
  }
}

// Context extension for easier navigation
extension BuildContextExtension on BuildContext {
  void goToDashboard() => GoRouter.of(this).goToDashboard();
  void goToLogin() => GoRouter.of(this).goToLogin();
  void goToExplore() => GoRouter.of(this).goToExplore();
  void goToDownloads() => GoRouter.of(this).goToDownloads();
  void goToSettings() => GoRouter.of(this).goToSettings();
  void goToProfile() => GoRouter.of(this).goToProfile();
  
  void goToCohortDetails(String cohortId) => GoRouter.of(this).goToCohortDetails(cohortId);
  void goToLectureDetails(String lectureId) => GoRouter.of(this).goToLectureDetails(lectureId);
  void goToLiveSession(String sessionId) => GoRouter.of(this).goToLiveSession(sessionId);
}
