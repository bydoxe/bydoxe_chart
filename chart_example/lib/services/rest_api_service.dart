import 'package:http/http.dart' as http;

class RestApiService {
  static const String baseUrl = 'https://fapi.binance.com/fapi/v1';

  static Future getKLineData(int? endTime) async {
    final params = <String, String>{
      'pair': 'BTCUSDT',
      'contractType': 'PERPETUAL',
      'interval': '1m',
      'limit': '1000',
    };

    if (endTime != null) {
      params['endTime'] = endTime.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/continuousKlines',
    ).replace(queryParameters: params);
    final response = await http.get(uri);
    return response.body;
  }
}
