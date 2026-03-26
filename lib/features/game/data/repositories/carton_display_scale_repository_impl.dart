import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/constants/carton_display_scale.dart';
import '../../domain/repositories/carton_display_scale_repository.dart';

class CartonDisplayScaleRepositoryImpl implements ICartonDisplayScaleRepository {
  static const _key = 'lota_carton_display_step_v1';

  @override
  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key);
    if (raw == null) return 0;
    return raw.clamp(0, CartonDisplayScale.stepCount - 1);
  }

  @override
  Future<void> save(int step) async {
    final prefs = await SharedPreferences.getInstance();
    final s = step.clamp(0, CartonDisplayScale.stepCount - 1);
    await prefs.setInt(_key, s);
  }
}
