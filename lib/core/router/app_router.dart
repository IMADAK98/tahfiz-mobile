import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/recover_account_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/halaqa/presentation/halaqa_detail_page.dart';
import '../../features/halaqa/presentation/halaqa_plans_assign_page.dart';
import '../../features/halaqa/presentation/halaqa_plans_create_page.dart';
import '../../features/halaqa/presentation/halaqa_plans_page.dart';
import '../../features/home/presentation/bottom_nav_page.dart';
import '../../features/student/presentation/student_attendance_page.dart';
import '../../features/student/presentation/student_page.dart';
import '../../features/student/presentation/student_progress_page.dart';
import '../storage/secure_storage_service.dart';

/// Public auth routes that do not require an access token.
const _authLocations = {'/login', '/register', '/recover-account'};

({String? date, String? halaqaId}) _dateHalaqaFrom(GoRouterState state) {
  final q = state.uri.queryParameters;
  String? date = q['date'];
  String? halaqaId = q['halaqaId'] ?? q['halqaId'];
  final extra = state.extra;
  if (extra is Map) {
    date ??= extra['date']?.toString();
    halaqaId ??=
        extra['halaqaId']?.toString() ?? extra['halqaId']?.toString();
  }
  return (date: date, halaqaId: halaqaId);
}

({String? halaqaName, int studentCount, String? planName, Set<String> assigned})
    _plansExtra(GoRouterState state) {
  final extra = state.extra;
  if (extra is! Map) {
    return (
      halaqaName: null,
      studentCount: 0,
      planName: null,
      assigned: const <String>{},
    );
  }
  final assignedRaw = extra['assignedIds'];
  final assigned = <String>{};
  if (assignedRaw is Iterable) {
    for (final v in assignedRaw) {
      final s = v.toString().trim();
      if (s.isNotEmpty) assigned.add(s);
    }
  }
  final count = extra['studentCount'];
  return (
    halaqaName: extra['halaqaName']?.toString(),
    studentCount: count is int ? count : int.tryParse('$count') ?? 0,
    planName: extra['planName']?.toString(),
    assigned: assigned,
  );
}

/// go_router with a light access-token gate.
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token = await storage.readAccessToken();
      final hasToken = token != null && token.isNotEmpty;
      final loc = state.matchedLocation;
      final onAuth = _authLocations.contains(loc);

      if (!hasToken && !onAuth) {
        return '/login';
      }
      if (hasToken && loc == '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/recover-account',
        name: 'recoverAccount',
        builder: (context, state) => const RecoverAccountPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const BottomNavPage(),
      ),
      GoRoute(
        path: '/halaqa/:id',
        name: 'halaqaDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final edit = state.uri.queryParameters['edit'];
          return HalaqaDetailPage(
            halaqaId: id,
            startInEdit: edit == '1' || edit == 'true',
          );
        },
        routes: [
          GoRoute(
            path: 'plans',
            name: 'halaqaPlans',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final x = _plansExtra(state);
              return HalaqaPlansPage(
                halaqaId: id,
                halaqaName: x.halaqaName,
                studentCount: x.studentCount,
              );
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'halaqaPlansCreate',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final x = _plansExtra(state);
                  return HalaqaPlansCreatePage(
                    halaqaId: id,
                    halaqaName: x.halaqaName,
                    studentCount: x.studentCount,
                  );
                },
              ),
              GoRoute(
                path: ':planId/assign',
                name: 'halaqaPlansAssign',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final planId =
                      int.tryParse(state.pathParameters['planId'] ?? '') ?? 0;
                  final x = _plansExtra(state);
                  return HalaqaPlansAssignPage(
                    halaqaId: id,
                    planId: planId,
                    halaqaName: x.halaqaName,
                    planName: x.planName,
                    alreadyAssignedIds: x.assigned,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/student/:id',
        name: 'student',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final ctx = _dateHalaqaFrom(state);
          return StudentPage(
            studentId: id,
            date: ctx.date,
            halaqaId: ctx.halaqaId,
          );
        },
        routes: [
          GoRoute(
            path: 'attendance',
            name: 'studentAttendance',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final ctx = _dateHalaqaFrom(state);
              return StudentAttendancePage(
                studentId: id,
                date: ctx.date,
                halaqaId: ctx.halaqaId,
              );
            },
          ),
          GoRoute(
            path: 'progress',
            name: 'studentProgress',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final ctx = _dateHalaqaFrom(state);
              return StudentProgressPage(
                studentId: id,
                date: ctx.date,
                halaqaId: ctx.halaqaId,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('المسار غير موجود: ${state.uri}')),
    ),
  );
});
