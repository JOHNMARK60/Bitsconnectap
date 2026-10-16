import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/models/event_model.dart';

class EventService {
  EventService(this._api);

  final ApiService _api;

  Future<List<EventModel>> scannerEvents() async {
    final response = await _api.get('/scanner/events');
    final data = response['data'];
    final events = data is Map ? data['events'] : data;
    if (events is! List) return [];

    return events
        .map(
          (event) =>
              EventModel.fromJson(Map<String, dynamic>.from(event as Map)),
        )
        .toList();
  }
}
