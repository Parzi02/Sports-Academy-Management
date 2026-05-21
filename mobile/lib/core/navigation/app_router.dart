import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/phone_entry_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/admin/admin_shell_screen.dart';
import '../../features/admin/home/admin_home_screen.dart';
import '../../features/admin/members/members_screen.dart';
import '../../features/admin/attendance/attendance_screen.dart';
import '../../features/admin/events/admin_events_screen.dart';
import '../../features/admin/member_details/member_details_screen.dart';
import '../../features/admin/attendance/mark_attendance_screen.dart';
import '../../features/admin/events/create_event_screen.dart';
import '../../features/admin/profile/admin_profile_screen.dart';
import '../../features/admin/payments/payment_verification_screen.dart';
import '../../features/admin/orders/screens/coach_orders_screen.dart';
import '../../features/member/member_shell_screen.dart';
import '../../features/member/home/member_home_screen.dart';
import '../../features/member/attendance/member_attendance_screen.dart';
import '../../features/member/events/member_events_screen.dart';
import '../../features/member/fees/fees_screen.dart';
import '../../features/member/profile/member_profile_screen.dart';
import '../../features/member/events/event_detail_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/cart_screen.dart';

final appRouterProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isSplashing = state.matchedLocation == '/splash';
      final isAuthPath = state.matchedLocation.startsWith('/auth');

      if (authState.isLoading) return '/splash';

      if (!isLoggedIn) {
        return null;
      }

      if (isLoggedIn && (isAuthPath || isSplashing)) {
        return authState.value!.role == 'admin' ? '/admin' : '/member';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      
      // Auth Routes
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => OtpScreen(data: state.extra as Map<String, dynamic>),
      ),

      // Admin Shell
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
          GoRoute(
            path: '/admin/members', 
            builder: (context, state) => const MembersScreen(),
            routes: [
              GoRoute(
                path: ':id', 
                builder: (context, state) => MemberDetailsScreen(id: state.pathParameters['id']!)
              ),
            ]
          ),
          GoRoute(
            path: '/admin/attendance', 
            builder: (context, state) => const AttendanceScreen(),
            routes: [
              GoRoute(path: 'mark', builder: (context, state) => const MarkAttendanceScreen()),
            ]
          ),
          GoRoute(
            path: '/admin/events', 
            builder: (context, state) => const AdminEventsScreen(),
            routes: [
              GoRoute(path: 'create', builder: (context, state) => const CreateEventScreen()),
            ]
          ),
          GoRoute(path: '/admin/payments/pending', builder: (context, state) => const PaymentVerificationScreen()),
          GoRoute(path: '/admin/profile', builder: (context, state) => const AdminProfileScreen()),
          GoRoute(path: '/admin/orders', builder: (context, state) => const CoachOrdersScreen()),
        ],
      ),

      // Member Shell
      ShellRoute(
        builder: (context, state, child) => MemberShellScreen(child: child),
        routes: [
          GoRoute(path: '/member', builder: (context, state) => const MemberHomeScreen()),
          GoRoute(path: '/member/attendance', builder: (context, state) => const MemberAttendanceScreen()),
          GoRoute(
            path: '/member/events', 
            builder: (context, state) => const MemberEventsScreen(),
            routes: [
              GoRoute(
                path: ':id', 
                builder: (context, state) => EventDetailScreen(id: state.pathParameters['id']!)
              ),
            ]
          ),
          GoRoute(path: '/member/fees', builder: (context, state) => const FeesScreen()),
          GoRoute(path: '/member/profile', builder: (context, state) => const MemberProfileScreen()),
          GoRoute(path: '/member/products', builder: (context, state) => const ProductsScreen(), routes: [
            GoRoute(path: ':id', builder: (context, state) => ProductDetailScreen(id: state.pathParameters['id']!)),
          ]),
          GoRoute(path: '/member/cart', builder: (context, state) => const CartScreen()),
        ],
      ),
    ],
  );
});
