import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/constants/carton_display_scale.dart';
import '../../domain/repositories/carton_display_scale_repository.dart';

/// Paso global (0…[CartonDisplayScale.stepCount]-1) para agrandar números en cartones.
///
/// Persiste en disco en cada cambio, igual que [ThemeCubit].
class CartonDisplayScaleCubit extends Cubit<int> {
  CartonDisplayScaleCubit(this._repository, int initialStep)
      : super(initialStep.clamp(0, CartonDisplayScale.stepCount - 1));

  final ICartonDisplayScaleRepository _repository;

  void setStep(int step) {
    final s = step.clamp(0, CartonDisplayScale.stepCount - 1);
    if (s == state) return;
    emit(s);
    _repository.save(s);
  }
}
