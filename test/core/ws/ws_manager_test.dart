import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/core/ws/ws_manager.dart';

void main() {
  group('WsEvent.fromJson', () {
    test('parses feature.updated event', () {
      final e = WsEvent.fromJson({
        'type': 'feature.updated',
        'feature_id': 'f-1',
        'payload': {'status': 'done'},
      });
      expect(e, isA<FeatureUpdatedEvent>());
      final fe = e as FeatureUpdatedEvent;
      expect(fe.featureId, 'f-1');
      expect(fe.payload['status'], 'done');
    });

    test('parses note.created event', () {
      final e = WsEvent.fromJson({
        'type': 'note.created',
        'note_id': 'n-2',
        'payload': {'title': 'Hello'},
      });
      expect(e, isA<NoteCreatedEvent>());
    });

    test('parses sync.ack event', () {
      final e = WsEvent.fromJson({'type': 'sync.ack', 'queue_id': 42});
      expect(e, isA<SyncAckEvent>());
      expect((e as SyncAckEvent).queueId, 42);
    });

    test('parses ping event', () {
      final e = WsEvent.fromJson({'type': 'ping'});
      expect(e, isA<PingEvent>());
    });

    test('unknown type returns UnknownWsEvent', () {
      final e = WsEvent.fromJson({'type': 'some.new.event', 'x': 1});
      expect(e, isA<UnknownWsEvent>());
      expect((e as UnknownWsEvent).type, 'some.new.event');
    });

    test('missing type returns UnknownWsEvent', () {
      final e = WsEvent.fromJson({'data': 'hello'});
      expect(e, isA<UnknownWsEvent>());
    });
  });

  group('WsManager state', () {
    test('initial state is disconnected', () {
      final mgr = WsManager();
      expect(mgr.state, WsState.disconnected);
      mgr.dispose();
    });

    test('disconnect from disconnected is safe', () async {
      final mgr = WsManager();
      await mgr.disconnect();
      expect(mgr.state, WsState.disconnected);
      mgr.dispose();
    });
  });
}
