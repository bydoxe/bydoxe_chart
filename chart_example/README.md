# chart_example

BYDOXE 차트 라이브러리 예제 앱입니다. 바이낸스 선물 REST/WebSocket을 사용해 1분봉 데이터를 로드하고 실시간 체결(aggTrade)로 마지막 봉 업데이트/신규 봉 추가를 수행합니다.

## 환경

- Flutter SDK: ^3.9.0
- 패키지 의존성:
  - `bydoxe_chart`: 상위 경로(../)의 로컬 패키지
  - `http`: ^1.5.0
  - `web_socket_channel`: ^2.4.0
  - `flutter_lints`: ^5.0.0
- 에셋: `assets/depth.json`, `assets/chartData.json`

## 동작 개요

1. 앱 시작 시 REST로 최근 1분봉 1000개 로드 후 `DataUtil.calculate`로 주요 지표 계산(MA/BOLL/SAR/Vol MA/MACD/KDJ/RSI/WR/CCI).
2. `KChartWidget`에 데이터 바인딩, 토글 버튼으로 메인/보조 지표와 거래량 표시 전환.
3. WebSocket(aggTrade) 수신 시 마지막 캔들 갱신 또는 새 캔들 추가(1분 단위 롤링), 지표 재계산 후 `setState`.
4. `DepthChart`는 `assets/depth.json`을 읽어 누적량으로 변환하여 표시(매수는 역누적, 매도는 순누적).

## 실행 방법

```bash
flutter pub get
flutter run
```

## 주요 코드 포인트

- 초기 로딩: `chart_example/lib/services/rest_api_service.dart`의 `getKLineData`
- 실시간: `chart_example/lib/services/websocket_service.dart`의 `listenAggTrade`
- 차트 사용: `chart_example/lib/main.dart`의 `KChartWidget`/`DepthChart` 데모 위젯

## 참고

- 예제는 바이낸스 선물 공용 API를 사용합니다. 네트워크 환경에 따라 지연/실패가 발생할 수 있습니다.
