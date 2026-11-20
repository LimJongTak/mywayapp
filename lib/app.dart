import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'models/post.dart';
import 'screens/admin/admin_inquiries_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/community/post_detail_screen.dart';
import 'screens/community/post_form_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/mypage/favorites_screen.dart';
import 'screens/mypage/inquiry_screens.dart';
import 'screens/mypage/my_trails_screen.dart';
import 'screens/mypage/mypage_screen.dart';
import 'screens/mypage/points_screen.dart';
import 'screens/mypage/profile_screen.dart';
import 'screens/mypage/rewards_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/shell.dart';
import 'screens/trail/trail_detail_screen.dart';
import 'screens/trail/trail_form_screen.dart';
import 'screens/trail/trail_list_screen.dart';
import 'screens/trail/trail_record_screen.dart';
import 'screens/trail/walk_screen.dart';
import 'services/auth_service.dart';

class MyWayApp extends StatefulWidget {
  const MyWayApp({super.key});

  @override
  State<MyWayApp> createState() => _MyWayAppState();
}

class _MyWayAppState extends State<MyWayApp> {
  late final GoRouter _router = _buildRouter(AuthService.instance);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyWay - 산책이 일상으로',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}

const _publicPaths = {'/login', '/signup'};

GoRouter _buildRouter(AuthService auth) {
  return GoRouter(
    initialLocation: '/map',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.initialized) return loc == '/splash' ? null : '/splash';
      if (!auth.signedIn) return _publicPaths.contains(loc) ? null : '/login';
      if (auth.needsEmailVerification) return loc == '/verify-email' ? null : '/verify-email';
      if (!auth.profileLoaded) return loc == '/splash' ? null : '/splash';
      if (auth.profile == null) return loc == '/onboarding' ? null : '/onboarding';
      const gates = {'/login', '/signup', '/splash', '/verify-email', '/onboarding'};
      if (gates.contains(loc)) return '/map';
      if (loc.startsWith('/admin') && !auth.isAdmin) return '/map';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/verify-email', builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/community', builder: (_, _) => const CommunityScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mypage', builder: (_, _) => const MyPageScreen()),
          ]),
        ],
      ),
      // 산책로
      GoRoute(path: '/trails', builder: (_, _) => const TrailListScreen()),
      GoRoute(path: '/trail/record', builder: (_, _) => const TrailRecordScreen()),
      GoRoute(
        path: '/trail/new',
        builder: (_, state) => TrailFormScreen(path: state.extra as List<LatLng>?),
      ),
      GoRoute(
        path: '/trail/:id',
        builder: (_, state) => TrailDetailScreen(trailId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => TrailFormScreen(editTrailId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'walk',
            builder: (_, state) => WalkScreen(trailId: state.pathParameters['id']!),
          ),
        ],
      ),
      // 커뮤니티
      GoRoute(
        path: '/post/new',
        builder: (_, state) =>
            PostFormScreen(board: Board.parse(state.uri.queryParameters['board'])),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => PostFormScreen(editPostId: state.pathParameters['id']),
          ),
        ],
      ),
      // 마이페이지
      GoRoute(path: '/me/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/me/trails', builder: (_, _) => const MyTrailsScreen()),
      GoRoute(path: '/me/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/me/points', builder: (_, _) => const PointsScreen()),
      GoRoute(path: '/me/rewards', builder: (_, _) => const RewardsScreen()),
      GoRoute(path: '/me/inquiries', builder: (_, _) => const InquiryListScreen()),
      GoRoute(path: '/me/inquiries/new', builder: (_, _) => const InquiryFormScreen()),
      // 관리자
      GoRoute(path: '/admin/inquiries', builder: (_, _) => const AdminInquiriesScreen()),
    ],
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MyWay',
                style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.primary)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
