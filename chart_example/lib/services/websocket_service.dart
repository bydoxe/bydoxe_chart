import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String _wsUrl = 'wss://fstream.binance.com';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? subscription;

  /// 현재 열린 채널이 있는지 여부
  bool get isConnected => _channel != null;

  /// 연결을 시작합니다.
  void connect(String uri) {
    // 항상 새 URI로 재연결
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }
    _channel = WebSocketChannel.connect(Uri.parse(uri));
  }

  /// 단일 심볼의 aggTrade 이벤트를 1회 수신(Future 완료)하되,
  /// 구독은 유지하여 이후 이벤트도 계속 수신/로그합니다.
  Future<Map<String, dynamic>> requestSymbolPriceTicker({
    required String symbol,
  }) async {
    final uri = '$_wsUrl/stream?streams=${symbol.toLowerCase()}@aggTrade';

    debugPrint('### uri $uri');

    connect(uri);

    final completer = Completer<Map<String, dynamic>>();
    subscription = _channel!.stream.listen(
      (event) {
        try {
          final String text = event is String
              ? event
              : utf8.decode(event as List<int>);
          final data = jsonDecode(text) as Map<String, dynamic>;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
          // 구독 취소를 제거하여 이후에도 계속 이벤트를 수신
        } catch (_) {
          // ignore parse errors for unrelated messages
        }
      },
      onError: (e, st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('WebSocket closed before response'),
          );
        }
      },
    );

    return completer.future;
  }

  /// 연속 수신 스트림: aggTrade 이벤트를 지속적으로 전달합니다.
  Stream<Map<String, dynamic>> listenAggTrade({required String symbol}) {
    final uri = '$_wsUrl/stream?streams=${symbol.toLowerCase()}@aggTrade';
    debugPrint('### uri $uri');
    connect(uri);
    return _channel!.stream.map((event) {
      final String text = event is String
          ? event
          : utf8.decode(event as List<int>);
      final data = jsonDecode(text) as Map<String, dynamic>;
      return data;
    });
  }

  /// 연결을 종료합니다.
  Future<void> disconnect({int code = 1000, String reason = 'normal'}) async {
    subscription?.cancel();
    if (_channel == null) return;
    await _channel!.sink.close(code, reason);
    _channel = null;
  }
}
