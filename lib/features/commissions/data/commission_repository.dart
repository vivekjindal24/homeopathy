import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/models.dart';

/// Repository for commission records.
class CommissionRepository {
  final SupabaseClient _client;
  CommissionRepository(this._client);

  Future<List<CommissionModel>> fetchAll({String? staffId}) async {
    try {
      var query = _client.from(AppConstants.tableCommissions).select();
      if (staffId != null) {
        query = query.eq('staff_id', staffId);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => CommissionModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<void> markPaid(String id) async {
    try {
      await _client.from(AppConstants.tableCommissions).update({
        'status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<double> totalPending(String staffId) async {
    try {
      final data = await _client
          .from(AppConstants.tableCommissions)
          .select('amount')
          .eq('staff_id', staffId)
          .eq('status', 'pending');
      return (data as List)
          .fold<double>(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }
}

final commissionRepositoryProvider = Provider<CommissionRepository>((ref) {
  return CommissionRepository(ref.watch(supabaseClientProvider));
});

