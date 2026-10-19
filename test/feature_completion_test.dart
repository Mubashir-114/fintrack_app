import 'package:image_picker/image_picker.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/transactions/sms_import_screen.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/services/sms_service.dart';
import 'package:frontend/core/utils/sms_parser.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/auth_response.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/detected_transaction_model.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:frontend/repositories/smart_transaction_repository.dart';
import 'package:frontend/screens/profile/avatar_editor.dart';
import 'package:frontend/core/widgets/profile_avatar.dart';

class _Picker extends ImagePicker {
  bool usedGallery = false;
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    usedGallery = source == ImageSource.gallery && !requestFullMetadata;
    return XFile.fromData(
      Uint8List.fromList(img.encodePng(img.Image(width: 600, height: 400))),
      mimeType: 'image/png',
    );
  }
}

class _Avatars extends AuthRepository {
  @override
  Future<ApiResponse<ProfileResponse>> updateProfile({
    required String name,
    required String email,
  }) => getProfile();
  Uint8List? stored;
  bool fail = false;
  @override
  Future<Uint8List?> getAvatar() async => stored;
  @override
  Future<Uint8List?> saveAvatar(Uint8List? bytes) async {
    if (fail) throw StateError('offline');
    return stored = bytes;
  }

  @override
  Future<ApiResponse<ProfileResponse>> getProfile() async => const ApiResponse(
    success: true,
    message: '',
    data: ProfileResponse(
      user: UserModel(id: 3, name: 'Test', email: 'test@example.test'),
    ),
  );
}

class _Prefs extends AnalyticsRepository {
  CompanionPreferences saved = const CompanionPreferences();
  @override
  Future<ApiResponse<CompanionPreferences>> getCompanionPreferences() async =>
      ApiResponse(success: true, message: '', data: saved);
  @override
  Future<ApiResponse<CompanionPreferences>> updateCompanionPreferences(
    CompanionPreferences prefs,
  ) async => ApiResponse(success: true, message: '', data: saved = prefs);
  @override
  Future<ApiResponse<CompanionPreferences>> resetCompanionPreferences() async =>
      ApiResponse(
        success: true,
        message: '',
        data: saved = const CompanionPreferences(),
      );
}

class _Sms extends SmsService {
  PermissionStatus permission = PermissionStatus.granted;
  int reads = 0;
  final date = DateTime(2026, 10, 10);
  @override
  Future<PermissionStatus> getPermissionStatus() async => permission;
  @override
  Future<PermissionStatus> requestPermission() async => permission;
  @override
  Future<List<ParsedSmsTransaction>> readAndParseSms() async {
    reads++;
    final tx = SmsParser.parseSms(
      sender: 'TESTBANK',
      body: 'INR 450 debited from a/c XX1234 at Market on 10 Oct. Ref 123456',
      date: date,
    )!;
    return [tx, tx];
  }
}

DetectedTransactionModel candidate({String amount = '450.00'}) =>
    DetectedTransactionModel(
      id: 8,
      userId: 3,
      accountId: 1,
      categoryId: 2,
      classification: 'expense',
      amount: amount,
      transactionDate: '2026-10-10',
      merchantRaw: 'Market',
      merchantClean: 'Market',
      smsHash: 'hash',
      confidence: .8,
      isAccountAmbiguous: false,
      status: 'suggested',
    );

class _Smart extends SmartTransactionRepository {
  List<Map<String, dynamic>>? sent;
  bool fail = false;
  Map<String, dynamic>? edits;
  @override
  Future<ApiResponse<Map<String, dynamic>>> detectTransactions(
    List<Map<String, dynamic>> messages,
  ) async {
    sent = messages;
    return const ApiResponse(success: true, message: '', data: {});
  }

  @override
  Future<ApiResponse<List<DetectedTransactionModel>>> getDetectedTransactions({
    String status = 'suggested',
    String? classification,
    String? search,
    int page = 1,
    int limit = 50,
  }) async => ApiResponse(
    success: true,
    message: '',
    data: status == 'suggested' ? [candidate()] : [],
  );
  @override
  Future<ApiResponse<DetectedTransactionModel>> updateDetectedTransaction(
    int id,
    Map<String, dynamic> changes,
  ) async {
    edits = changes;
    return ApiResponse(
      success: true,
      message: '',
      data: candidate(amount: changes['amount'].toString()),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmTransaction(
    int id, {
    Map<String, dynamic>? overrides,
  }) async =>
      ApiResponse(success: !fail, message: 'Retry this candidate', data: {});
  @override
  Future<ApiResponse<Map<String, dynamic>>> rejectTransaction(
    int id, {
    String? reason,
  }) async => const ApiResponse(success: true, message: '', data: {});
}

class _Accounts extends AccountProvider {
  int loads = 0;
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {
    loads++;
  }
}

class _Dashboard extends DashboardProvider {
  int loads = 0;
  @override
  Future<void> loadDashboardData() async {
    loads++;
  }
}

class _Reports extends ReportProvider {
  int loads = 0;
  @override
  Future<void> loadAllReports() async {
    loads++;
  }
}

class _Budgets extends BudgetProvider {
  int loads = 0;
  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    loads++;
  }
}

class _Ledger extends TransactionProvider {
  int loads = 0;
  @override
  Future<void> loadTransactions({bool loadMore = false}) async {
    loads++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize(memoryOnly: true);
    CacheService.setUserId(3);
  });
  test(
    'avatar saves immediately, restores in a new session, replaces, removes, and preserves photo on failure',
    () async {
      final repo = _Avatars();
      AuthProvider make() => AuthProvider(
        repository: repo,
        tokenReader: () async => 'mock',
        tokenRemover: () async {},
      );
      final first = make();
      await first.loadCurrentUser();
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(await first.saveAvatar(bytes), true);
      expect(first.avatarBytes, bytes);
      await first.logout();
      expect(first.avatarBytes, null);
      final second = make();
      await second.loadCurrentUser();
      await second.loadAvatar();
      expect(second.avatarBytes, bytes);
      final replacement = Uint8List.fromList([4, 5]);
      await second.saveAvatar(replacement);
      repo.fail = true;
      expect(await second.saveAvatar(null), false);
      expect(second.avatarBytes, replacement);
      repo.fail = false;
      expect(await second.saveAvatar(null), true);
      expect(second.avatarBytes, null);
    },
  );
  test(
    'FIN dismiss-hide-restore repeated is immediate and persists per user',
    () async {
      final repo = _Prefs();
      final fin = AnalyticsProvider(repository: repo);
      for (var i = 0; i < 2; i++) {
        fin.visualController.dismissFloating();
        final hiding = fin.updateCompanionPreferences(
          fin.companionPreferences.copyWith(showAcrossApp: false),
        );
        expect(fin.companionPreferences.showAcrossApp, false);
        expect(fin.visualController.isFloatingDismissed, false);
        await hiding;
        fin.visualController.dismissFloating();
        final restoring = fin.restoreFinNow();
        expect(fin.companionPreferences.showAcrossApp, true);
        expect(fin.visualController.isFloatingDismissed, false);
        await restoring;
      }
      await fin.updateCompanionPreferences(
        fin.companionPreferences.copyWith(
          edgePosition: 'left',
          animationsEnabled: false,
        ),
      );
      await CacheService.clearAll();
      final restored = AnalyticsProvider(repository: repo);
      await restored.loadCompanionPreferences();
      expect(restored.companionPreferences.edgePosition, 'left');
      expect(restored.visualController.animationsEnabled, false);
      await restored.resetCompanionPreferences();
      expect(restored.companionPreferences.edgePosition, 'right');
      expect(restored.companionPreferences.showAcrossApp, true);
    },
  );
  test(
    'denied SMS permission never reads, retries send deduplicated structured candidates, edits and confirmation preserve failures',
    () async {
      final service = _Sms()..permission = PermissionStatus.permanentlyDenied;
      final repo = _Smart();
      final provider = SmsProvider(smsService: service, smartRepo: repo);
      await provider.scanAndDetectSmartTransactions(userConsented: true);
      expect(service.reads, 0);
      expect(provider.errorMessage, contains('settings'));
      service.permission = PermissionStatus.granted;
      await provider.scanAndDetectSmartTransactions(userConsented: true);
      expect(repo.sent, hasLength(1));
      expect(repo.sent!.single.containsKey('message'), false);
      expect(repo.sent!.single.containsKey('body'), false);
      expect(repo.sent!.single['sms_hash'], hasLength(64));
      expect(repo.sent!.single['maskedAccountHint'], '1234');
      expect(provider.detectedCount, 1);
      await provider.updateDetected(8, {
        'amount': '999.00',
        'accountId': 1,
        'categoryId': 2,
        'transactionDate': '2026-10-11',
      });
      expect(provider.detectedTransactions.single.amount, '999.00');
      repo.fail = true;
      expect(await provider.confirmDetected(8), false);
      expect(provider.detectedCount, 1);
      repo.fail = false;
      expect(await provider.confirmDetected(8), true);
      expect(provider.detectedCount, 0);
      await provider.loadDetectedTransactions();
      expect(await provider.rejectDetected(8), true);
      expect(provider.detectedCount, 0);
    },
  );
  test(
    'parser accepts rupee debit and credit and excludes OTP, failure, marketing and reminders',
    () {
      ParsedSmsTransaction? parse(String body) => SmsParser.parseSms(
        sender: 'TESTBANK',
        body: body,
        date: DateTime(2026, 10, 10),
      );
      expect(parse('Rs 450 credited to a/c XX1234')?.type, 'income');
      expect(parse('\u20b9 450 debited from a/c XX1234')?.type, 'expense');
      for (final message in [
        'OTP 1234 for Rs 500 paid with card',
        'Rs 50 bank payment failed',
        'Rs 500 bank offer credited today',
        'Rs 500 card payment due date today',
      ]) {
        expect(parse(message), null);
      }
    },
  );
  testWidgets(
    'confirmed SMS refreshes dashboard, ledger, accounts, reports and budgets once',
    (tester) async {
      final sms = SmsProvider(smsService: _Sms(), smartRepo: _Smart());
      final accounts = _Accounts();
      final dashboard = _Dashboard();
      final ledger = _Ledger();
      final reports = _Reports();
      final budgets = _Budgets();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SmsProvider>.value(value: sms),
            ChangeNotifierProvider<AccountProvider>.value(value: accounts),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<TransactionProvider>.value(value: ledger),
            ChangeNotifierProvider<ReportProvider>.value(value: reports),
            ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: const MaterialApp(home: SmsImportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(dashboard.loads, 0);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(dashboard.loads, 1);
      expect(ledger.loads, 1);
      expect(reports.loads, 1);
      expect(budgets.loads, 1);
      expect(
        accounts.loads,
        2,
      ); // initial account picker data plus committed balance refresh
      expect(find.text('Transaction saved to your history.'), findsOneWidget);
    },
  );
  testWidgets(
    'gallery selection previews crop and saves photo to shared profile state',
    (tester) async {
      final repo = _Avatars();
      final picker = _Picker();
      final auth = AuthProvider(
        repository: repo,
        tokenReader: () async => 'mock',
      );
      await auth.loadCurrentUser();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(picker: picker),
                  ),
                ),
                child: const Text('Edit identity'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit identity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      expect(picker.usedGallery, true);
      expect(find.text('Crop profile photo'), findsOneWidget);
      await tester.tap(find.text('Use photo'));
      await tester.pumpAndSettle();
      expect(repo.stored, null); // choosing never uploads without saving
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      expect(repo.stored, isNotNull);
      expect(auth.avatarBytes, repo.stored);
    },
  );
  testWidgets(
    'crop preview returns a bounded square JPEG; initials survive missing image',
    (tester) async {
      Uint8List? result;
      final source = Uint8List.fromList(
        img.encodePng(img.Image(width: 800, height: 400)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.push<Uint8List>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvatarEditor(bytes: source),
                  ),
                );
              },
              child: const Text('Choose photo'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider).first, const Offset(60, 0));
      await tester.tap(find.text('Use photo'));
      await tester.pumpAndSettle();
      final decoded = img.decodeJpg(result!)!;
      expect(decoded.width, 384);
      expect(decoded.height, 384);
      expect(result!.length, lessThan(262144));
      await tester.pumpWidget(
        const MaterialApp(home: ProfileAvatar(name: 'Alice')),
      );
      expect(find.text('A'), findsOneWidget);
    },
  );
}
