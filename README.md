# BYDOXE 차트 패키지

## 기능 개요

- **차트 유형**: 캔들(봉), 라인 차트, 거래량(Vol), 보조지표 다중 표기, 호가 뎁스(Depth) 차트
  - **메인 지표**: MA, BOLL, SAR
  - **보조 지표**: MACD, KDJ, RSI, WR, CCI (여러 개 동시 표시 지원)
- **상호작용**: 드래그 스크롤, 핀치 줌, 플링(가속 스크롤), 롱프레스 십자선/데이터 조회, 탭 기반 정보 팝업, 추세선(TrendLine) 모드로 차트 상 라인 그리기
- **렌더링/성능**: 가시 구간만 계산/렌더, 이진 탐색 기반 인덱싱, 최대 스크롤 범위 관리, `onLoadMore(bool isLeft)` 콜백으로 양 끝 도달 시 추가 로딩 트리거
- **표시 요소**: 현재가 점선/라벨, 구간 내 고가/저가 표기, 격자 표시 토글, 좌/우 수직축 정렬, 시간 표시 자동 포맷(주기 추론) 및 커스텀 포맷 지원
- **스타일/테마**: `ChartColors`로 배경/텍스트/테두리/지표/깊이 등 세부 색상 제어, `ChartStyle`로 폭/패딩/두께/격자/현재가 라인 등 구성. 다크 모드 등 멀티 테마 적용 가능
- **현지화**: `ChartTranslations`, `DepthChartTranslations`로 정보 창/깊이 차트 라벨 다국어 지원
- **구성 옵션(주요)**: `isLine`, `volHidden`, `mainStateLi`, `secondaryStateLi`, `isTrendLine`, `xFrontPadding`, `isTapShowInfoDialog`, `showNowPrice`, `showInfoDialog`, `materialInfoDialog`, `timeFormat`, `fixedLength`, `maDayList`, `flingTime/flingRatio/flingCurve`, `verticalTextAlignment`
- **구성 요소**: `KChartWidget`(메인 차트), `DepthChart`(호가뎁스), `PopupInfoView`(정보 팝업)

## 데이터/유틸

- **엔티티**: `KLineEntity`(open/high/low/close/vol/amount/time 등), `CandleEntity`, `VolumeEntity`, `MACDEntity`, `KDJEntity`, `RSIEntity`, `RWEntity`, `CCIEntity`, `DepthEntity`, `InfoWindowEntity`
- **지표 계산**: `DataUtil.calculate`가 MA/BOLL/SAR/KDJ/MACD/RSI/WR/CCI/거래량 MA 일괄 계산
- **포맷/보조**: `NumberUtil`(숫자 단위 축약/소수 자릿수), `date_format_util.dart`(시간 포맷), `extension/num_ext.dart`(널/제로 체크)

## 공개 API

- 라이브러리 진입점 `k_chart_plus.dart`에서 다음을 export:
  - `k_chart_widget.dart`, `chart_style.dart`, `depth_chart.dart`
  - `utils/index.dart`, `entity/index.dart`, `renderer/index.dart`, `extension/num_ext.dart`

## 사용 가능한 위젯

- KChartWidget: 캔들/라인 메인 차트 + 거래량(Vol) + 보조지표(MACD/KDJ/RSI/WR/CCI) 다중 표시, 십자선/정보창, 줌/드래그/플링, 트렌드라인 모드, onLoadMore 지원
- DepthChart: 호가 뎁스(매수/매도) 영역 차트, 롱프레스 시 가격/수량 팝업 표시

참고: `PopupInfoView`는 내부 구성요소로 `KChartWidget`에서 사용됩니다. 직접 사용도 가능하지만 권장 공용 API는 `KChartWidget`, `DepthChart`입니다.

## 설치

```yaml
dependencies:
  bydoxe_chart: ^1.0.3
```

## 사용 예시

### 1) KChartWidget (캔들/라인 + 지표)

첫 번째 인자는 `List<KLineEntity>` 타입의 `datas` 입니다.

```dart
import 'package:flutter/material.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';

class KChartDemo extends StatefulWidget {
  const KChartDemo({super.key});
  @override
  State<KChartDemo> createState() => _KChartDemoState();
}

class _KChartDemoState extends State<KChartDemo> {
  late final List<KLineEntity> datas;

  @override
  void initState() {
    super.initState();
    datas = [
      KLineEntity.fromCustom(
        time: DateTime.now().millisecondsSinceEpoch,
        open: 100,
        high: 105,
        low: 98,
        close: 102,
        vol: 15000,
        amount: 300000,
      ),
      KLineEntity.fromCustom(
        time: DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        open: 102,
        high: 108,
        low: 101,
        close: 107,
        vol: 22000,
        amount: 450000,
      ),
      // ... 더 많은 봉 데이터
    ];
    // 지표 데이터 계산(MA/BOLL/SAR/볼륨 MA/MACD/KDJ/RSI/WR/CCI)
    DataUtil.calculate(datas, [5, 10, 20]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KChart Demo')),
      body: Container(
        color: Colors.white,
        height: 360,
        width: double.infinity,
        child: KChartWidget(
          datas,
          ChartStyle()
            ..gridRows = 4
            ..gridColumns = 4,
          ChartColors(),
          isTrendLine: false,
          mainStateLi: {MainState.MA, MainState.BOLL},
          secondaryStateLi: {SecondaryState.MACD, SecondaryState.RSI},
          volHidden: false,
          isLine: false,
          showNowPrice: true,
          // 오른쪽/왼쪽 끝 도달 시 호출
          onLoadMore: (isLeft) {
            // 예: 추가 데이터 로딩 트리거
          },
          // 십자선 정보창(롱프레스/탭) 표기 설정
          isTapShowInfoDialog: true,
          materialInfoDialog: true,
          // 표기 정렬(좌/우)
          verticalTextAlignment: VerticalTextAlignment.left,
          // 앞쪽 여백(차트 좌측 패딩)
          xFrontPadding: 100,
        ),
      ),
    );
  }
}
```

라인 차트로 보고 싶다면 `isLine: true`로 설정하면 됩니다. MA/BOLL/SAR, 보조지표는 필요에 따라 `mainStateLi`, `secondaryStateLi`에 원하는 지표를 추가/삭제하세요.

다크 테마 색상 예시:

```dart
final darkColors = ChartColors(
  bgColor: const Color(0xFF0F1115),
  gridColor: const Color(0xFF2A2D34),
  defaultTextColor: const Color(0xFF9BA1A6),
  nowPriceTextColor: const Color(0xFF0F1115),
  selectFillColor: const Color(0xFF1A1D23),
  selectBorderColor: const Color(0xFF3A3F47),
);
```

### 2) DepthChart (호가 뎁스)

```dart
import 'package:flutter/material.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';

class DepthChartDemo extends StatelessWidget {
  const DepthChartDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final bids = <DepthEntity>[
      DepthEntity(99.5, 2.0),
      DepthEntity(99.0, 5.0),
      DepthEntity(98.5, 7.5),
    ];
    final asks = <DepthEntity>[
      DepthEntity(100.5, 2.5),
      DepthEntity(101.0, 6.0),
      DepthEntity(101.5, 8.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('DepthChart Demo')),
      body: Container(
        color: Colors.white,
        height: 220,
        width: double.infinity,
        child: DepthChart(
          bids,
          asks,
          ChartColors(),
          baseUnit: 2,   // 수량 소수 자릿수
          quoteUnit: 2,  // 가격 소수 자릿수
          chartTranslations: const DepthChartTranslations(
            price: 'Price',
            amount: 'Amount',
          ),
        ),
      ),
    );
  }
}
```

롱프레스 상태에서 해당 지점의 가격/수량 팝업이 표시됩니다. 색상 테마는 `ChartColors`의 depth 관련 색상(`depthBuyColor`, `depthSellColor`, `depthBuyPathColor`, `depthSellPathColor`)을 조정하세요.
