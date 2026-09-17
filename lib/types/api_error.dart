enum ApiErrorType {
  noConnection,
  invalidFile,
  unsupportedFormat,
  server,
  unavailable,
  unexpected,
}

class ApiError implements Exception {
  const ApiError(this.type, this.message);
  final ApiErrorType type;
  final String message;
  factory ApiError.fromStatusCode(int s, {String? message}) => ApiError(
        s == 400 || s == 422
            ? ApiErrorType.invalidFile
            : s == 415
                ? ApiErrorType.unsupportedFormat
                : s == 500
                    ? ApiErrorType.server
                    : s == 503
                        ? ApiErrorType.unavailable
                        : ApiErrorType.unexpected,
        message ?? 'No pudimos procesar la fórmula. Inténtalo nuevamente.',
      );
}
