import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:master/master_auth_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Master app boots into the workspace selector', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MasterApp());
    await tester.pumpAndSettle();

    expect(find.text('اختر مساحة العمل'), findsOneWidget);
  });

  testWidgets('Master auth layout fits a wide browser viewport', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1440, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MasterApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Master activity dashboard renders the live activity workspace', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = MasterSession(
      token: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      master: const MasterUser(
        adminId: 1,
        adminName: 'أحمد محمد',
        adminEmail: 'admin@example.com',
        adminPhone: '+963900000000',
        adminApprove: 1,
        adminRoleId: 1,
        role: MasterRoleProfile(
          roleId: 1,
          roleName: 'صاحب المنصة',
          roleScope: 'platform',
          permissions: [],
          tintHex: '#177A48',
          sortOrder: 1,
        ),
        adminLastLoginAt: null,
        adminCreate: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MasterOperationsPage(
            session: session,
            onLogout: () async {},
            serverNow: DateTime(2026, 7, 1, 11, 58, 22),
            initialSubSection: 'activity',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('سجل النشاط'), findsWidgets);
    expect(find.text('سجل النشاطات'), findsOneWidget);
    expect(find.text('متابعة جميع عمليات المنصة لحظة بلحظة'), findsOneWidget);
    expect(find.text('إدارة الطلبات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'Master API accepts successful writes and rejects logical API errors',
    () async {
      final successApi = MasterAuthApiService(
        client: _FakeMasterClient(
          statusCode: 200,
          body: '{"status":"success"}',
        ),
      );
      addTearDown(successApi.dispose);

      await successApi.updateMasterPrintSettings(
        'test-token',
        invoiceCopies: 2,
        printLogo: true,
      );
      final health = await successApi.fetchMasterDeploymentHealth('test-token');
      expect(health, isA<Map<String, dynamic>>());

      final failingApi = MasterAuthApiService(
        client: _FakeMasterClient(
          statusCode: 200,
          body: '{"status":"error","message":"denied"}',
        ),
      );
      addTearDown(failingApi.dispose);

      await expectLater(
        failingApi.updateMasterScheduledReportStatus(
          'test-token',
          reportId: 1,
          isActive: false,
        ),
        throwsA(isA<MasterApiException>()),
      );
    },
  );
}

class _FakeMasterClient extends http.BaseClient {
  _FakeMasterClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(body.codeUnits),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}
