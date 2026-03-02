import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/patient_model.dart';
import '../../data/patient_repository.dart';

/// State for the patient list (paginated + searchable).
class PatientListState {
  final List<PatientModel> patients;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String searchQuery;
  final int currentPage;

  const PatientListState({
    this.patients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
    this.currentPage = 0,
  });

  PatientListState copyWith({
    List<PatientModel>? patients,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? searchQuery,
    int? currentPage,
  }) {
    return PatientListState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier managing patient list with pagination and debounced search.
class PatientListNotifier extends StateNotifier<PatientListState> {
  final PatientRepository _repo;
  Timer? _debounce;

  PatientListNotifier(this._repo) : super(const PatientListState()) {
    loadPatients();
  }

  Future<void> loadPatients({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 0,
    );

    try {
      final patients = await _repo.fetchPatients(
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(
        patients: patients,
        isLoading: false,
        hasMore: patients.length >= 20,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final more = await _repo.fetchPatients(
        page: nextPage,
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      state = state.copyWith(
        patients: [...state.patients, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Debounced search — fires 400ms after last keystroke.
  void search(String query) {
    _debounce?.cancel();
    state = state.copyWith(searchQuery: query);
    _debounce = Timer(const Duration(milliseconds: 400), loadPatients);
  }

  void clearSearch() {
    _debounce?.cancel();
    state = state.copyWith(searchQuery: '');
    loadPatients();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final patientListProvider =
    StateNotifierProvider<PatientListNotifier, PatientListState>((ref) {
  return PatientListNotifier(ref.read(patientRepositoryProvider));
});

/// Provider for a single patient.
final patientDetailProvider =
    FutureProvider.family<PatientModel, String>((ref, patientId) async {
  return ref.read(patientRepositoryProvider).fetchPatientById(patientId);
});

