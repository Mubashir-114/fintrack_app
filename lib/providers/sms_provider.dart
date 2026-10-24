import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/cache_service.dart';
import '../core/services/sms_service.dart';
import '../core/utils/sms_parser.dart';
import '../models/detected_transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/smart_transaction_repository.dart';

class SmsBatchResult {
  const SmsBatchResult({
    this.added = 0,
    this.needsAttention = 0,
    this.skipped = 0,
  });
  final int added;
  final int needsAttention;
  final int skipped;
  String get message =>
      '$added added; $needsAttention need correction or retry'
      '${skipped > 0 ? "; $skipped duplicates or unavailable skipped" : ""}.';
}

class SmsProvider extends ChangeNotifier {
  SmsProvider({
    SmsService? smsService,
    TransactionRepository? repository,
    SmartTransactionRepository? smartRepo,
  }) : _smsService = smsService ?? SmsService(),
       _repository = repository ?? TransactionRepository(),
       _smartRepo = smartRepo ?? SmartTransactionRepository();

  final SmsService _smsService;
  final TransactionRepository _repository;
  final SmartTransactionRepository _smartRepo;

  bool _isScanning = false;
  bool _isImporting = false;
  bool _isLoadingDetected = false;
  bool _isOperating = false;
  String? _errorMessage;
  String? _detectedErrorMessage;

  List<ParsedSmsTransaction> _transactions = [];
  List<ParsedSmsTransaction> _archivedTransactions = [];
  final Set<String> _selectedHashes = {};

  // Phase 3B Smart Transactions state
  List<DetectedTransactionModel> _detectedTransactions = [];
  List<DetectedTransactionModel> _archivedDetectedTransactions = [];
  final Set<int> _selectedDetectedIds = {};

  SmsBatchResult? _batchResult;
  final Map<int, String> _confirmationErrors = {};
  SmsBatchResult? get batchResult => _batchResult;
  Map<int, String> get confirmationErrors =>
      Map.unmodifiable(_confirmationErrors);

  /// Validation incorporates explicit manual account, confident suggested account,
  /// or designated default account fallback before failing.
  String? confirmationIssue(
    DetectedTransactionModel tx, {
    bool checkDuplicates = true,
    int? fallbackDefaultAccountId,
  }) {
    if (!['suggested', 'detected'].contains(tx.status) ||
        tx.confirmedTransactionId != null) {
      return 'This transaction is no longer pending.';
    }
    final resolvedAccId = tx.accountId ??
        (tx.isAccountAmbiguous ? null : tx.suggestedAccountId) ??
        fallbackDefaultAccountId;
    if ((resolvedAccId ?? 0) <= 0) {
      return 'Choose an unambiguous account using Edit.';
    }
    final amount = double.tryParse(tx.amount);
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 9999999999.99) {
      return 'Enter a valid positive amount using Edit.';
    }
    final date = DateTime.tryParse(tx.transactionDate);
    if (date == null ||
        date.toIso8601String().substring(0, 10) != tx.transactionDate) {
      return 'Enter a valid transaction date using Edit.';
    }
    if (tx.merchantClean.trim().isEmpty || tx.merchantClean.length > 150) {
      return 'Enter a valid merchant using Edit.';
    }
    if (![
      'expense',
      'income',
      'transfer',
      'refund',
      'credit_card_purchase',
      'credit_card_repayment',
    ].contains(tx.classification)) {
      return 'Choose a valid transaction type using Edit.';
    }
    if ((tx.categoryId ?? tx.suggestedCategoryId ?? 0) <= 0) {
      return 'Choose a category using Edit.';
    }
    if (checkDuplicates &&
        (_archivedDetectedTransactions.any(
              (other) =>
                  other.status == 'confirmed' &&
                  other.smsHash == tx.smsHash &&
                  tx.smsHash.isNotEmpty,
            ) ||
            _detectedTransactions.any(
              (other) =>
                  other.id != tx.id &&
                  other.id < tx.id &&
                  other.smsHash == tx.smsHash &&
                  tx.smsHash.isNotEmpty &&
                  confirmationIssue(
                        other,
                        checkDuplicates: false,
                        fallbackDefaultAccountId: fallbackDefaultAccountId,
                      ) ==
                      null,
            ))) {
      return 'Duplicate SMS candidate; review or reject it.';
    }
    return null;
  }

  int get eligibleDetectedCount =>
      _detectedTransactions.where((tx) => confirmationIssue(tx) == null).length;

  int eligibleCount({int? fallbackDefaultAccountId}) => _detectedTransactions
      .where((tx) =>
          confirmationIssue(
            tx,
            fallbackDefaultAccountId: fallbackDefaultAccountId,
          ) ==
          null)
      .length;

  PermissionStatus? _permissionStatus;
  SmsImportResponse? _importResponse;
  DateTime? _lastImportTime;
  int _sessionGeneration = 0;

  void clearSession() {
    _sessionGeneration++;
    _batchResult = null;
    _confirmationErrors.clear();
    _isScanning = false;
    _isImporting = false;
    _isLoadingDetected = false;
    _isOperating = false;
    _errorMessage = null;
    _detectedErrorMessage = null;
    _transactions = [];
    _archivedTransactions = [];
    _selectedHashes.clear();
    _detectedTransactions = [];
    _archivedDetectedTransactions = [];
    _selectedDetectedIds.clear();
    _permissionStatus = null;
    _importResponse = null;
    _lastImportTime = null;
    notifyListeners();
  }

  Future<void> loadLastImportTime() async {
    final sessionGeneration = _sessionGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(
        CacheService.userScopedKey('last_sms_import_time'),
      );
      if (timeStr != null) {
        final lastImportTime = DateTime.parse(timeStr);
        if (sessionGeneration == _sessionGeneration) {
          _lastImportTime = lastImportTime;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Getters - Legacy & Generic
  bool get isScanning => _isScanning;
  bool get isImporting => _isImporting;
  bool get isLoadingDetected => _isLoadingDetected;
  bool get isOperating => _isOperating;
  String? get errorMessage => _errorMessage;
  String? get detectedErrorMessage => _detectedErrorMessage;
  List<ParsedSmsTransaction> get transactions => _transactions;
  List<ParsedSmsTransaction> get archivedTransactions => _archivedTransactions;
  Set<String> get selectedHashes => _selectedHashes;
  PermissionStatus? get permissionStatus => _permissionStatus;
  SmsImportResponse? get importResponse => _importResponse;
  DateTime? get lastImportTime => _lastImportTime;

  int get foundCount => _transactions.length;
  int get selectedCount => _selectedHashes.length;
  bool get isAllSelected =>
      _transactions.isNotEmpty &&
      _selectedHashes.length == _transactions.length;

  // Getters - Phase 3B Smart Transactions
  List<DetectedTransactionModel> get detectedTransactions =>
      _detectedTransactions;
  List<DetectedTransactionModel> get archivedDetectedTransactions =>
      _archivedDetectedTransactions;
  Set<int> get selectedDetectedIds => _selectedDetectedIds;
  int get detectedCount => _detectedTransactions.length;
  int get selectedDetectedCount => _selectedDetectedIds.length;
  bool get isAllDetectedSelected =>
      _detectedTransactions.isNotEmpty &&
      _selectedDetectedIds.length == _detectedTransactions.length;

  // ── Phase 3B Smart Transactions Methods ─────────────────────────────────────

  void toggleDetectedSelection(int id) {
    if (_selectedDetectedIds.contains(id)) {
      _selectedDetectedIds.remove(id);
    } else {
      _selectedDetectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAllDetected(bool select) {
    _selectedDetectedIds.clear();
    if (select) {
      for (final tx in _detectedTransactions) {
        _selectedDetectedIds.add(tx.id);
      }
    }
    notifyListeners();
  }

  /// Loads detected transactions from backend for review.
  Future<void> loadDetectedTransactions({String status = "suggested"}) async {
    final sessionGeneration = _sessionGeneration;
    _isLoadingDetected = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      var page = 1;
      final records = <DetectedTransactionModel>[];
      while (true) {
        final response = await _smartRepo.getDetectedTransactions(
          status: status,
          page: page,
          limit: 100,
        );
        if (sessionGeneration != _sessionGeneration) return;
        if (!response.success) throw Exception(response.message);
        records.addAll(response.data);
        if (response.data.length < 100) break;
        page++;
      }
      final res = records;
      {
        if (status == "suggested" || status == "detected") {
          _detectedTransactions = res;
          _selectedDetectedIds.clear();
          for (final item in _detectedTransactions) {
            _selectedDetectedIds.add(item.id);
          }
        } else {
          _archivedDetectedTransactions = res;
        }
      }
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      final responseData = e is DioException ? e.response?.data : null;
      _detectedErrorMessage = e is DioException
          ? ((responseData is Map ? responseData['message']?.toString() : null) ??
                e.message ??
                "Failed to load detected transactions")
          : e.toString().replaceAll("Exception: ", "");
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isLoadingDetected = false;
        notifyListeners();
      }
    }
  }

  /// Reads only after consent and permission; sends structured financial candidates
  /// without SMS body text. Candidates remain separate from the ledger.
  Future<void> scanAndDetectSmartTransactions({
    bool userConsented = false,
  }) async {
    if (!userConsented) {
      _errorMessage =
          'Review and accept the SMS import notice before scanning.';
      notifyListeners();
      return;
    }
    if (_isScanning || _isImporting) return;
    final sessionGeneration = _sessionGeneration;
    _isScanning = true;
    _errorMessage = null;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      await loadLastImportTime();
      if (sessionGeneration != _sessionGeneration) return;

      // 1. Check and request SMS permission
      final status = await _smsService.getPermissionStatus();
      if (sessionGeneration != _sessionGeneration) return;
      _permissionStatus = status;

      if (!status.isGranted && !status.isLimited) {
        final requestStatus = await _smsService.requestPermission();
        if (sessionGeneration != _sessionGeneration) return;
        _permissionStatus = requestStatus;

        if (!requestStatus.isGranted && !requestStatus.isLimited) {
          if (requestStatus.isPermanentlyDenied || requestStatus.isRestricted) {
            _errorMessage =
                'SMS permission permanently denied. Please enable it in system settings.';
          } else {
            _errorMessage = 'SMS permission denied.';
          }
          notifyListeners();
          return;
        }
      }

      // 2. Read messages from inbox
      final parsedList = await _smsService.readAndParseSms();
      if (sessionGeneration != _sessionGeneration) return;

      if (parsedList.isEmpty) {
        _errorMessage =
            'No eligible financial transaction SMS found on this device.';
        notifyListeners();
        return;
      }

      final unique = {for (final item in parsedList) item.smsHash: item};
      final candidates = unique.values.toList();
      for (var start = 0; start < candidates.length; start += 50) {
        if (sessionGeneration != _sessionGeneration) return;
        final batch = candidates
            .skip(start)
            .take(50)
            .map(
              (p) => {
                'amount': p.amount,
                'type': p.type,
                'merchant': p.merchant,
                'bank': p.bank,
                'date': p.date.toIso8601String(),
                'reference': p.referenceNumber,
                'maskedAccountHint': p.maskedAccountHint,
                'sms_hash': p.smsHash,
                'sender': p.sender,
              },
            )
            .toList();
        final result = await _smartRepo.detectTransactions(batch);
        if (!result.success) throw Exception(result.message);
      }
      if (sessionGeneration != _sessionGeneration) return;
      await loadDetectedTransactions(status: 'suggested');
      if (sessionGeneration != _sessionGeneration) return;
      await loadDetectedTransactions(status: 'confirmed');
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      _errorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to scan SMS")
          : e.toString().replaceAll("Exception: ", "");
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  /// Confirms a single detected transaction into the ledger.
  Future<bool> confirmDetected(
    int id, {
    Map<String, dynamic>? overrides,
    int? fallbackDefaultAccountId,
  }) async {
    if (_isOperating) return false;
    final candidate = _detectedTransactions
        .where((tx) => tx.id == id)
        .firstOrNull;
    final issue = candidate == null
        ? 'Transaction is no longer pending.'
        : confirmationIssue(
            candidate,
            fallbackDefaultAccountId: fallbackDefaultAccountId,
          );
    if (issue != null) {
      _detectedErrorMessage = issue;
      notifyListeners();
      return false;
    }
    final operationSession = _sessionGeneration;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final effectiveOverrides = Map<String, dynamic>.from(overrides ?? {});
      if (!effectiveOverrides.containsKey('account_id') &&
          candidate!.accountId == null &&
          (candidate.suggestedAccountId == null || candidate.isAccountAmbiguous) &&
          fallbackDefaultAccountId != null) {
        effectiveOverrides['account_id'] = fallbackDefaultAccountId;
      }
      final res = await _smartRepo.confirmTransaction(
        id,
        overrides: effectiveOverrides.isNotEmpty ? effectiveOverrides : null,
      );
      if (operationSession != _sessionGeneration) return false;
      if (res.success) {
        _archivedDetectedTransactions.add(
          candidate!.copyWith(status: 'confirmed'),
        );
        _confirmationErrors.remove(id);
        _detectedTransactions.removeWhere((t) => t.id == id);
        _selectedDetectedIds.remove(id);
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      if (operationSession != _sessionGeneration) return false;
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ??
                e.message ??
                "Failed to confirm transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      if (operationSession == _sessionGeneration) {
        _isOperating = false;
        notifyListeners();
      }
    }
  }

  /// Rejects a detected transaction so it never enters the ledger.
  Future<bool> rejectDetected(int id, {String? reason}) async {
    if (_isOperating) return false;
    final operationSession = _sessionGeneration;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.rejectTransaction(id, reason: reason);
      if (operationSession != _sessionGeneration) return false;
      if (res.success) {
        _detectedTransactions.removeWhere((t) => t.id == id);
        _selectedDetectedIds.remove(id);
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      if (operationSession != _sessionGeneration) return false;
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ??
                e.message ??
                "Failed to reject transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      if (operationSession == _sessionGeneration) {
        _isOperating = false;
        notifyListeners();
      }
    }
  }

  /// Updates a detected transaction with manual user corrections.
  Future<bool> updateDetected(int id, Map<String, dynamic> changes) async {
    if (_isOperating) return false;
    final operationSession = _sessionGeneration;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final res = await _smartRepo.updateDetectedTransaction(id, changes);
      if (operationSession != _sessionGeneration) return false;
      if (res.success) {
        final index = _detectedTransactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _detectedTransactions[index] = res.data;
          _confirmationErrors.remove(id);
        }
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      if (operationSession != _sessionGeneration) return false;
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ??
                e.message ??
                "Failed to update transaction")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      if (operationSession == _sessionGeneration) {
        _isOperating = false;
        notifyListeners();
      }
    }
  }

  /// Add All snapshots all pending items independently of checkbox selection.
  Future<bool> batchConfirmSelected({
    bool all = false,
    int? fallbackDefaultAccountId,
  }) async {
    if (_isOperating) return false;
    final candidates = _detectedTransactions
        .where((tx) => all || _selectedDetectedIds.contains(tx.id))
        .toList();
    if (candidates.isEmpty) return false;
    final operationSession = _sessionGeneration;
    _isOperating = true;
    _detectedErrorMessage = null;
    _batchResult = null;
    _confirmationErrors.clear();
    final eligible = <DetectedTransactionModel>[];
    var skipped = 0;
    for (final tx in candidates) {
      final issue = confirmationIssue(
        tx,
        fallbackDefaultAccountId: fallbackDefaultAccountId,
      );
      if (issue == null) {
        eligible.add(tx);
      } else if (issue.startsWith('Duplicate') ||
          issue.contains('no longer pending')) {
        skipped++;
      } else {
        _confirmationErrors[tx.id] = issue;
      }
    }
    notifyListeners();
    var added = 0;
    try {
      // The existing endpoint accepts at most 100 candidates per request.
      for (var start = 0; start < eligible.length; start += 100) {
        final chunk = eligible.skip(start).take(100).toList();
        try {
          final res = await _smartRepo.batchConfirm([
            for (final tx in chunk) {
              'id': tx.id,
              if (tx.accountId == null &&
                  (tx.suggestedAccountId == null || tx.isAccountAmbiguous) &&
                  fallbackDefaultAccountId != null)
                'account_id': fallbackDefaultAccountId,
            },
          ]);
          if (operationSession != _sessionGeneration) return false;
          final confirmed = res.data['confirmed'] as List? ?? [];
          final completed = confirmed
              .map((item) => (item['id'] as num).toInt())
              .where((id) => chunk.any((tx) => tx.id == id))
              .toSet();
          final errors = res.data['errors'] as List? ?? [];
          for (final tx in chunk) {
            if (completed.contains(tx.id)) {
              _archivedDetectedTransactions.add(
                tx.copyWith(status: 'confirmed'),
              );
            } else {
              final error = errors.where((e) => e['id'] == tx.id).firstOrNull;
              _confirmationErrors[tx.id] =
                  error?['error']?.toString() ??
                  (res.success
                      ? 'Not confirmed. Please retry or Edit.'
                      : res.message);
            }
          }
          added += completed.length;
          _detectedTransactions.removeWhere((tx) => completed.contains(tx.id));
          _selectedDetectedIds.removeAll(completed);
          notifyListeners();
        } catch (e) {
          if (operationSession != _sessionGeneration) return false;
          for (final tx in chunk) {
            _confirmationErrors[tx.id] =
                'Could not confirm. Please retry or Edit.';
          }
        }
      }
      _batchResult = SmsBatchResult(
        added: added,
        needsAttention: _confirmationErrors.length,
        skipped: skipped,
      );
      if (_confirmationErrors.isNotEmpty) {
        _detectedErrorMessage = _batchResult!.message;
      }
      if (added > 0) {
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();
      }
      return added > 0 && _confirmationErrors.isEmpty;
    } finally {
      if (operationSession == _sessionGeneration) {
        _isOperating = false;
        notifyListeners();
      }
    }
  }

  /// Batch rejects all selected detected transactions.
  Future<bool> batchRejectSelected({String? reason}) async {
    if (_selectedDetectedIds.isEmpty) return false;
    if (_isOperating) return false;
    final operationSession = _sessionGeneration;
    _isOperating = true;
    _detectedErrorMessage = null;
    notifyListeners();

    try {
      final ids = _selectedDetectedIds.toList();
      final res = await _smartRepo.batchReject(ids, reason: reason);
      if (operationSession != _sessionGeneration) return false;
      if (res.success) {
        final results =
            (res.data['confirmed'] ?? res.data['rejected'] ?? []) as List;
        final completed = results
            .map((item) => (item['id'] as num).toInt())
            .toSet();
        _detectedTransactions.removeWhere((t) => completed.contains(t.id));
        _selectedDetectedIds.removeAll(completed);
        final errors = res.data['errors'] as List? ?? [];
        if (errors.isNotEmpty) {
          _detectedErrorMessage =
              '${errors.length} items need correction or retry. Successfully processed items were removed.';
        }
        notifyListeners();
        return true;
      } else {
        _detectedErrorMessage = res.message;
        return false;
      }
    } catch (e) {
      if (operationSession != _sessionGeneration) return false;
      _detectedErrorMessage = e is DioException
          ? (e.response?.data["message"] ??
                e.message ??
                "Failed to batch reject transactions")
          : e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      if (operationSession == _sessionGeneration) {
        _isOperating = false;
        notifyListeners();
      }
    }
  }

  // ── Existing SMS Scanning and Import Methods (Preserved) ────────────────────

  /// Check permissions and scan for financial transactions in the device SMS inbox.
  Future<void> scanSms({bool userConsented = false}) async {
    if (!userConsented) {
      _errorMessage =
          'Review and accept the SMS import notice before scanning.';
      notifyListeners();
      return;
    }
    if (_isScanning || _isImporting) return;
    final sessionGeneration = _sessionGeneration;
    _isScanning = true;
    _errorMessage = null;
    _importResponse = null;
    notifyListeners();

    try {
      await loadLastImportTime();
      if (sessionGeneration != _sessionGeneration) return;

      // 1. Check and request SMS permission
      final status = await _smsService.getPermissionStatus();
      if (sessionGeneration != _sessionGeneration) return;
      _permissionStatus = status;

      if (!status.isGranted) {
        final requestStatus = await _smsService.requestPermission();
        if (sessionGeneration != _sessionGeneration) return;
        _permissionStatus = requestStatus;

        if (!requestStatus.isGranted) {
          if (requestStatus.isPermanentlyDenied) {
            _errorMessage =
                'SMS permission permanently denied. Please enable it in system settings.';
          } else {
            _errorMessage = 'SMS permission denied.';
          }
          notifyListeners();
          return;
        }
      }

      // 2. Fetch already imported SMS hashes from the backend
      final hashResponse = await _repository.getImportedSmsHashes();
      if (sessionGeneration != _sessionGeneration) return;
      if (!hashResponse.success) {
        throw Exception(
          hashResponse.message.isEmpty
              ? 'Could not check previously imported SMS transactions.'
              : hashResponse.message,
        );
      }
      final importedSet = Set<String>.from(hashResponse.data);

      // 3. Query and parse SMS inbox
      final parsedList = await _smsService.readAndParseSms();
      if (sessionGeneration != _sessionGeneration) return;

      // 4. Split into new and archived transactions
      _transactions = [];
      _archivedTransactions = [];
      for (final tx in parsedList) {
        if (importedSet.contains(tx.smsHash)) {
          _archivedTransactions.add(tx);
        } else {
          _transactions.add(tx);
        }
      }

      // 5. Select all discovered new transactions by default
      _selectedHashes.clear();
      for (final tx in _transactions) {
        _selectedHashes.add(tx.smsHash);
      }

      // 6. Also load server-side detected transactions
      try {
        await loadDetectedTransactions(status: "suggested");
      } catch (_) {}
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _transactions = [];
      _archivedTransactions = [];
      _selectedHashes.clear();
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  /// Toggle selection checkbox for a specific transaction
  void toggleSelection(String hash) {
    if (_selectedHashes.contains(hash)) {
      _selectedHashes.remove(hash);
    } else {
      _selectedHashes.add(hash);
    }
    notifyListeners();
  }

  /// Select or deselect all transactions in the checklist
  void toggleSelectAll(bool select) {
    _selectedHashes.clear();
    if (select) {
      for (final tx in _transactions) {
        _selectedHashes.add(tx.smsHash);
      }
    }
    notifyListeners();
  }

  /// Clear any active error message
  void clearError() {
    _errorMessage = null;
    _detectedErrorMessage = null;
    notifyListeners();
  }

  /// Upload the selected transactions to the backend
  Future<bool> importSelectedTransactions() async {
    if (_isScanning || _isImporting) return false;
    if (_selectedHashes.isEmpty) {
      _errorMessage = 'No transactions selected for import.';
      notifyListeners();
      return false;
    }

    _isImporting = true;
    final sessionGeneration = _sessionGeneration;
    _errorMessage = null;
    notifyListeners();

    // Filter selected transactions
    final selectedTxs = _transactions
        .where((tx) => _selectedHashes.contains(tx.smsHash))
        .toList();

    try {
      final response = await _repository.importSmsTransactions(selectedTxs);
      if (sessionGeneration != _sessionGeneration) return false;

      if (response.success) {
        _importResponse = response.data;
        await CacheService.remove('dashboard_cache');
        await CacheService.clearBudgetCaches();

        // Save last import time
        _lastImportTime = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            CacheService.userScopedKey('last_sms_import_time'),
            _lastImportTime!.toIso8601String(),
          );
        } catch (_) {}

        if (response.data.failed == 0) {
          final importedTxs = _transactions
              .where((tx) => _selectedHashes.contains(tx.smsHash))
              .toList();
          _archivedTransactions.addAll(importedTxs);
          _transactions.removeWhere(
            (tx) => _selectedHashes.contains(tx.smsHash),
          );
          _selectedHashes.clear();
        }
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      if (e is DioException) {
        _errorMessage =
            e.response?.data["message"] ??
            e.message ??
            'Failed to connect to the server.';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isImporting = false;
        notifyListeners();
      }
    }
  }
}
