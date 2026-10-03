import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../hooks/prescription_hook.dart';
import '../pages/analysis_page.dart';
import '../pages/auth_pages.dart';
import '../pages/google_auth_callback_page.dart';
import '../pages/home_page.dart';
import '../pages/password_reset_pages.dart';
import '../pages/result_page.dart';
import '../pages/upload_page.dart';
import '../services/api_service.dart';
import '../services/prescription_service.dart';
import '../utils/constants.dart';
import 'app_routes.dart';
import 'theme/app_theme.dart';

class FarmaGoApp extends StatefulWidget {
  const FarmaGoApp({super.key});

  @override
  State<FarmaGoApp> createState() => _FarmaGoAppState();
}

class _FarmaGoAppState extends State<FarmaGoApp> {
  late final ApiService api;
  late final PrescriptionController controller;
  late final AuthController auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    api = ApiService(AppConfig.apiBaseUrl);
    controller = PrescriptionController(PrescriptionService(api));
    auth = AuthController(AuthRepository(AppConfig.authBaseUrl));
    _router = _createRouter();
    auth.restore();
  }

  @override
  void dispose() {
    _router.dispose();
    controller.dispose();
    auth.dispose();
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Farma Go',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      );

  GoRouter _createRouter() => GoRouter(
        refreshListenable: auth,
        redirect: _redirect,
        routes: [
          GoRoute(
            path: LegacyRoutes.login,
            redirect: (context, state) {
              final error = state.uri.queryParameters['error'];
              return error == null
                  ? AppRoutes.login
                  : Uri(
                      path: AppRoutes.googleCallback,
                      queryParameters: {'error': error},
                    ).toString();
            },
          ),
          GoRoute(
            path: '/auth/callback',
            redirect: (context, state) => Uri(
              path: AppRoutes.googleCallback,
              queryParameters: state.uri.queryParameters,
            ).toString(),
          ),
          GoRoute(
            path: LegacyRoutes.register,
            redirect: (context, state) => AppRoutes.register,
          ),
          GoRoute(
            path: LegacyRoutes.forgotPassword,
            redirect: (context, state) => AppRoutes.forgotPassword,
          ),
          GoRoute(
            path: LegacyRoutes.resetPassword,
            redirect: (context, state) => AppRoutes.resetPassword,
          ),
          GoRoute(
            path: LegacyRoutes.verifyEmail,
            redirect: (context, state) => AppRoutes.verifyEmail,
          ),
          GoRoute(
            path: LegacyRoutes.home,
            redirect: (context, state) => AppRoutes.home,
          ),
          GoRoute(
            path: LegacyRoutes.uploadPrescription,
            redirect: (context, state) => AppRoutes.uploadPrescription,
          ),
          GoRoute(
            path: LegacyRoutes.analyzingPrescription,
            redirect: (context, state) => AppRoutes.analyzingPrescription,
          ),
          GoRoute(
            path: LegacyRoutes.prescriptionResult,
            redirect: (context, state) => AppRoutes.prescriptionResult,
          ),
          GoRoute(
            path: LegacyRoutes.account,
            redirect: (context, state) => AppRoutes.account,
          ),
          GoRoute(
            path: AppRoutes.landing,
            builder: (context, state) => _duringSessionRestore(
              LandingPage(
                onLogin: () => context.push(AppRoutes.login),
                onRegister: () => context.push(AppRoutes.register),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => _duringSessionRestore(
              LoginPage(
                auth: auth,
                onRegister: () => context.push(AppRoutes.register),
                onForgotPassword: () => context.push(AppRoutes.forgotPassword),
                onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.register,
            builder: (context, state) => _duringSessionRestore(
              RegisterPage(
                auth: auth,
                onLogin: () => context.push(AppRoutes.login),
                onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (context, state) => _duringSessionRestore(
              ForgotPasswordPage(
                auth: auth,
                onSent: () => context.push(AppRoutes.resetPassword),
                onBack: () => AppRoutes.backOrGo(context, AppRoutes.login),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.resetPassword,
            builder: (context, state) => _duringSessionRestore(
              ResetPasswordPage(
                auth: auth,
                onLogin: () => context.go(AppRoutes.login),
                onBack: () =>
                    AppRoutes.backOrGo(context, AppRoutes.forgotPassword),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.verifyEmail,
            builder: (context, state) => _duringSessionRestore(
              VerifyPage(
                auth: auth,
                onBack: () {
                  auth.backToPublic();
                  context.go(AppRoutes.login);
                },
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.googleCallback,
            builder: (context, state) => GoogleAuthCallbackPage(
              auth: auth,
              errorCode: state.uri.queryParameters['error'],
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => _duringSessionRestore(
              HomePage(
                auth: auth,
                onAnalyze: () => context.push(AppRoutes.uploadPrescription),
                onAccount: () => context.push(AppRoutes.account),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.uploadPrescription,
            builder: (context, state) => _duringSessionRestore(
              UploadPage(
                onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
                onAnalyze: (image) => context.push(
                  AppRoutes.analyzingPrescription,
                  extra: image,
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.analyzingPrescription,
            builder: (context, state) {
              final image = state.extra;
              if (image is! XFile) {
                return _duringSessionRestore(
                  _MissingAnalysisStep(
                    onBack: () => context.go(AppRoutes.uploadPrescription),
                  ),
                );
              }
              return _duringSessionRestore(
                AnalysisPage(
                  controller: controller,
                  image: image,
                  onBack: () =>
                      AppRoutes.backOrGo(context, AppRoutes.uploadPrescription),
                  onComplete: () => context.go(AppRoutes.prescriptionResult),
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.prescriptionResult,
            builder: (context, state) {
              if (controller.result == null) {
                return _duringSessionRestore(
                  _MissingAnalysisStep(
                    onBack: () => context.go(AppRoutes.uploadPrescription),
                  ),
                );
              }
              return _duringSessionRestore(
                ResultPage(
                  controller: controller,
                  onHome: () => context.go(AppRoutes.home),
                  onAnalyzeAnother: () {
                    controller.reset();
                    context.go(AppRoutes.uploadPrescription);
                  },
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => _duringSessionRestore(
              AccountPage(
                auth: auth,
                onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
              ),
            ),
          ),
        ],
        errorBuilder: (context, state) => _UnknownRoute(
          onHome: () => context.go(
            auth.status == AuthStatus.authenticated
                ? AppRoutes.home
                : AppRoutes.landing,
          ),
        ),
      );

  String? _redirect(BuildContext context, GoRouterState state) {
    if (auth.status == AuthStatus.checking) return null;
    final path = state.uri.path;
    final publicRoutes = {
      AppRoutes.landing,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.resetPassword,
      AppRoutes.googleCallback,
    };
    final protectedRoutes = {
      AppRoutes.home,
      AppRoutes.uploadPrescription,
      AppRoutes.analyzingPrescription,
      AppRoutes.prescriptionResult,
      AppRoutes.account,
    };

    if (auth.status == AuthStatus.verifying) {
      return path == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
    }

    if (auth.status == AuthStatus.authenticated) {
      return publicRoutes.contains(path) || path == AppRoutes.verifyEmail
          ? AppRoutes.home
          : null;
    }

    if (path == AppRoutes.verifyEmail || protectedRoutes.contains(path)) {
      return AppRoutes.login;
    }
    if (path == AppRoutes.login &&
        state.uri.queryParameters.containsKey('error')) {
      return Uri(
        path: AppRoutes.googleCallback,
        queryParameters: {'error': state.uri.queryParameters['error']!},
      ).toString();
    }
    if (path == AppRoutes.resetPassword && auth.resetEmail == null) {
      return AppRoutes.forgotPassword;
    }
    return null;
  }

  Widget _duringSessionRestore(Widget child) => AnimatedBuilder(
        animation: auth,
        builder: (context, _) => auth.status == AuthStatus.checking
            ? const _SessionLoadingPage()
            : child,
      );
}

class _SessionLoadingPage extends StatelessWidget {
  const _SessionLoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: SizedBox(
              width: 38, height: 38, child: CircularProgressIndicator()),
        ),
      );
}

class _MissingAnalysisStep extends StatelessWidget {
  const _MissingAnalysisStep({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Analizar fórmula'),
          leading: IconButton(
            tooltip: 'Volver a seleccionar la fórmula',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_library_outlined,
                    size: 52, color: AppColors.blue),
                const SizedBox(height: 18),
                const Text('Primero selecciona una fórmula',
                    style: AppText.heading, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Este paso necesita una imagen para continuar con el análisis.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Seleccionar una fórmula'),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ruta no disponible')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.explore_off_outlined,
                  size: 52, color: AppColors.blue),
              const SizedBox(height: 18),
              const Text('No encontramos esta pantalla',
                  style: AppText.heading, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Vuelve al inicio para continuar.',
                  style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Ir al inicio'),
              ),
            ]),
          ),
        ),
      );
}
