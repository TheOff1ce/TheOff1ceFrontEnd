import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/admin_service.dart';
import '../types/admin.dart';

/// User directory for administrators: search, filter by role, paginate and change roles.
class AdminUsersController extends ChangeNotifier {
  AdminUsersController(this._admin, {this.searchDelay = const Duration(milliseconds: 350)});

  final AdminService _admin;
  final Duration searchDelay;

  List<AdminUser> users = const [];
  int total = 0;
  int _page = 1;
  bool _hasMore = false;
  String search = '';
  UserRole? roleFilter;
  bool loading = false;
  bool loadingMore = false;
  AppError? error;

  /// Ids whose role change is in flight (their selector is disabled).
  Set<String> saving = const {};

  Timer? _debounce;
  int _generation = 0;
  bool _disposed = false;

  bool get hasMore => _hasMore;

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final page = await _admin.users(search: search, role: roleFilter);
      if (generation != _generation) return; // a newer search already answered
      users = page.users;
      total = page.total;
      _page = page.page;
      _hasMore = page.hasMore;
    } catch (e) {
      if (generation == _generation) error = ErrorMapper.fromException(e);
    } finally {
      if (generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || loadingMore || loading) return;
    final generation = _generation;
    loadingMore = true;
    _notify();
    try {
      final page = await _admin.users(search: search, role: roleFilter, page: _page + 1);
      if (generation != _generation) return;
      final known = {for (final u in users) u.id};
      users = [...users, ...page.users.where((u) => !known.contains(u.id))];
      total = page.total;
      _page = page.page;
      _hasMore = page.hasMore;
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loadingMore = false;
      _notify();
    }
  }

  /// Debounced so typing does not fire one request per key.
  void setSearch(String value) {
    if (value == search) return;
    search = value;
    _debounce?.cancel();
    _debounce = Timer(searchDelay, load);
  }

  void setRoleFilter(UserRole? role) {
    if (role == roleFilter) return;
    roleFilter = role;
    _debounce?.cancel();
    load();
  }

  /// Returns `null` on success or the error to show.
  Future<AppError?> changeRole(AdminUser user, UserRole role) async {
    if (user.role == role) return null;
    saving = {...saving, user.id};
    _notify();
    try {
      final updated = await _admin.changeRole(user.id, role);
      final keep = roleFilter == null || updated.role == roleFilter;
      users = [
        for (final u in users)
          if (u.id != user.id)
            u
          else if (keep)
            updated,
      ];
      if (!keep) total = total > 0 ? total - 1 : 0;
      return null;
    } catch (e) {
      return ErrorMapper.fromException(e);
    } finally {
      saving = {...saving}..remove(user.id);
      _notify();
    }
  }

  void clear() {
    _debounce?.cancel();
    _generation++;
    users = const [];
    total = 0;
    _page = 1;
    _hasMore = false;
    search = '';
    roleFilter = null;
    error = null;
    loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
