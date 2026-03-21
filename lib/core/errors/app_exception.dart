import 'package:equatable/equatable.dart';

class AppException extends Equatable {
  const AppException({
    this.message = 'Error desconocido',
    this.code,
  });

  final String message;
  final String? code;

  bool get isNoInternet => code == '502';

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
