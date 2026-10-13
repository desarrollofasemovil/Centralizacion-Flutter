import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';

/// Registra qué disparos de reseña hizo la UI, sin tocar preferencias ni
/// el plugin.
class SpyReviewPromptService implements ReviewPromptService {
  int loginCalls = 0;
  final List<ReviewTrigger> moments = [];

  @override
  Future<bool> onSuccessfulLogin() async {
    loginCalls++;
    return false;
  }

  @override
  Future<bool> onPositiveMoment(ReviewTrigger trigger) async {
    moments.add(trigger);
    return false;
  }
}
