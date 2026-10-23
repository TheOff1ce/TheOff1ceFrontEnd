import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Scripted auth service: each path answers with the next queued response.
class FakeAuthServer {
  final Map<String, List<http.Response Function()>> _queue = {};
  final List<String> calls = [];

  void on(String path, http.Response Function() response, {int times = 1}) {
    _queue.putIfAbsent(path, () => []).addAll(List.filled(times, response));
  }

  MockClient get client => MockClient((request) async {
        final path = request.url.path.replaceFirst('/auth/', '');
        calls.add(path);
        final queue = _queue[path];
        if (queue == null || queue.isEmpty) return http.Response('{}', 500);
        return queue.removeAt(0)();
      });
}

http.Response ok(Object body) => http.Response(jsonEncode(body), 200);
http.Response session() => ok({'accessToken': 'token', 'expiresIn': 600});
http.Response me() => ok({'id': 'p-1', 'email': 'ana@example.com', 'name': 'Ana', 'role': 'PATIENT'});
http.Response failure(int status, String code) => http.Response(
      jsonEncode({
        'success': false,
        'error': {'code': code, 'message': 'x'},
      }),
      status,
    );
http.Response offline() => throw http.ClientException('offline');

AuthController controllerFor(FakeAuthServer server) => AuthController(
      AuthRepository('https://auth.example', client: server.client, usesBrowserCookies: true),
      retryDelays: const [Duration(seconds: 5), Duration(seconds: 15)],
    );

void main() {
  test('restores a session and schedules the refresh 30 s before the 600 s expiry', () {
    fakeAsync((async) {
      final server = FakeAuthServer()
        ..on('refresh', session)
        ..on('me', me)
        ..on('refresh', session)
        ..on('me', me);
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.accessToken, 'token');

      async.elapse(const Duration(seconds: 569));
      expect(server.calls.where((c) => c == 'refresh'), hasLength(1));
      async.elapse(const Duration(seconds: 2));
      expect(server.calls.where((c) => c == 'refresh'), hasLength(2));
      auth.dispose();
    });
  });

  test('FE-003: a network failure keeps the session and retries with backoff', () {
    fakeAsync((async) {
      final server = FakeAuthServer()
        ..on('refresh', session)
        ..on('me', me)
        ..on('refresh', offline)
        ..on('refresh', () => failure(429, 'RATE_LIMITED'))
        ..on('refresh', session)
        ..on('me', me);
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 571));
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.connectionIssue, isTrue);

      async.elapse(const Duration(seconds: 5)); // first retry → 429, still signed in
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.connectionIssue, isTrue);

      async.elapse(const Duration(seconds: 15)); // second retry succeeds
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.connectionIssue, isFalse);
      auth.dispose();
    });
  });

  test('FE-003: only a rejected session (401) signs the user out, with an explanation', () {
    fakeAsync((async) {
      final server = FakeAuthServer()
        ..on('refresh', session)
        ..on('me', me)
        ..on('refresh', () => failure(401, 'SESSION_INVALID'));
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      auth.rememberReturnTo('/analyze-prescription/result');

      async.elapse(const Duration(seconds: 571));
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.sessionNotice?.kind, AppErrorKind.unauthorized);
      expect(auth.accessToken, isNull);
      expect(auth.takeReturnTo(), '/analyze-prescription/result');
      auth.dispose();
    });
  });

  test('start-up without a reachable service shows "unreachable", not signed-out', () {
    fakeAsync((async) {
      final server = FakeAuthServer()..on('refresh', offline);
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      expect(auth.status, AuthStatus.unreachable);
      expect(auth.startupError?.kind, AppErrorKind.network);
      auth.dispose();
    });
  });

  test('start-up without a session is simply signed out', () {
    fakeAsync((async) {
      final server = FakeAuthServer()..on('refresh', () => failure(401, 'SESSION_INVALID'));
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.sessionNotice, isNull);
      auth.dispose();
    });
  });

  test('logout always closes the local session, even offline', () {
    fakeAsync((async) {
      final server = FakeAuthServer()
        ..on('refresh', session)
        ..on('me', me)
        ..on('logout', offline);
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      auth.logout();
      async.flushMicrotasks();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.user, isNull);
      async.elapse(const Duration(minutes: 20));
      expect(server.calls.where((c) => c == 'refresh'), hasLength(1));
      auth.dispose();
    });
  });

  test('login errors are returned to the page instead of a shared global field', () {
    fakeAsync((async) {
      final server = FakeAuthServer()..on('login', () => failure(401, 'INVALID_CREDENTIALS'));
      final auth = controllerFor(server);
      AppError? error;
      auth.login(email: 'ana@example.com', password: 'wrong-pass').then((value) => error = value);
      async.flushMicrotasks();
      expect(error?.kind, AppErrorKind.invalidCredentials);
      expect(auth.status, isNot(AuthStatus.verifying));
      auth.dispose();
    });
  });

  test('AI-001: the controller hands out its in-memory token and rotates it on demand', () {
    fakeAsync((async) {
      var issued = 0;
      final server = FakeAuthServer()
        ..on('refresh', () => ok({'accessToken': 'token-${++issued}', 'expiresIn': 600}), times: 2)
        ..on('me', me, times: 2);
      final auth = controllerFor(server);
      auth.restore();
      async.flushMicrotasks();
      String? token;
      auth.currentAccessToken().then((value) => token = value);
      async.flushMicrotasks();
      expect(token, 'token-1');
      auth.currentAccessToken(forceRefresh: true).then((value) => token = value);
      async.flushMicrotasks();
      expect(token, 'token-2');
      auth.dispose();
    });
  });
}
