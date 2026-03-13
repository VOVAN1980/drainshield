import 'dart:async';
import '../../models/security_event.dart';

class SecurityEventService {
  static final SecurityEventService instance = SecurityEventService._internal();
  SecurityEventService._internal();

  final _eventController = StreamController<SecurityEvent>.broadcast();

  Stream<SecurityEvent> get eventStream => _eventController.stream;

  Future<void> init() async {
    // Initialization logic if needed
  }

  void emit(SecurityEvent event) {
    _eventController.add(event);
  }

  StreamSubscription<SecurityEvent> subscribe(
    void Function(SecurityEvent) onData,
  ) {
    return _eventController.stream.listen(onData);
  }

  void dispose() {
    _eventController.close();
  }
}
