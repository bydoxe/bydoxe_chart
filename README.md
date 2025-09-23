# BYDOXE 차트 패키지

## 기능 개요

- **차트 유형**: 캔들(봉), 라인 차트, 거래량(Vol), 보조지표 다중 표기, 호가 뎁스(Depth) 차트
  - **메인 지표**: MA, EMA, BOLL, SAR, AVL(평균가)
  - **보조 지표**: MACD, KDJ, RSI, WR (여러 개 동시 표시 지원)
- **상호작용**: 드래그 스크롤, 핀치 줌, 플링(가속 스크롤), 롱프레스 십자선/데이터 조회, 탭 기반 정보 팝업, 추세선(TrendLine) 모드로 차트 상 라인 그리기, 우측 가격축 드래그로 수직 스케일 조정(기본 표시 범위보다 더 넓게만 확장; 축소는 제한)
- **렌더링/성능**: 가시 구간만 계산/렌더, 이진 탐색 기반 인덱싱, 최대 스크롤 범위 관리, `onLoadMore(bool isLeft)` 콜백으로 양 끝 도달 시 추가 로딩 트리거
- **표시 요소**: 현재가 점선/라벨, 구간 내 고가/저가 표기, 격자 표시 토글, 좌/우 수직축 정렬, 시간 표시 자동 포맷(주기 추론) 및 커스텀 포맷 지원
- **스타일/테마**: `ChartColors`로 배경/텍스트/테두리/지표/깊이 등 세부 색상 제어, `ChartStyle`로 폭/패딩/두께/격자/현재가 라인 등 구성. 다크 모드 등 멀티 테마 적용 가능
- **현지화**: `ChartTranslations`, `DepthChartTranslations`로 정보 창/깊이 차트 라벨 다국어 지원
- **구성 옵션(주요)**: `isLine`, `volHidden`, `mainStateLi`, `secondaryStateLi`, `isTrendLine`, `xFrontPadding`, `isTapShowInfoDialog`, `showNowPrice`, `showInfoDialog`, `materialInfoDialog`, `timeFormat`, `fixedLength`, `maDayList`, `flingTime/flingRatio/flingCurve`, `verticalTextAlignment`, `nowPriceLabelAlignment`, `positionLabelAlignment(예약)`, `positionLines`, `markers`, `onPositionAction`, `onEdgeLoadTs`
- **구성 요소**: `KChartWidget`(메인 차트), `DepthChart`(호가뎁스), `PopupInfoView`(정보 팝업)

## 데이터/유틸

- **엔티티**: `KLineEntity`(open/high/low/close/vol/amount/time 등), `CandleEntity`, `VolumeEntity`, `MACDEntity`, `KDJEntity`, `RSIEntity`, `RWEntity`, `DepthEntity`, `InfoWindowEntity`
- **지표 계산**: `DataUtil.calculate`가 MA/BOLL/SAR/KDJ/MACD/RSI/WR/거래량 MA 일괄 계산
- **포맷/보조**: `NumberUtil`(숫자 단위 축약/소수 자릿수), `date_format_util.dart`(시간 포맷), `extension/num_ext.dart`(널/제로 체크)

## 공개 API

- 라이브러리 진입점 `k_chart_plus.dart`에서 다음을 export:
  - `k_chart_widget.dart`, `chart_style.dart`, `depth_chart.dart`
  - `utils/index.dart`, `entity/index.dart`, `renderer/index.dart`, `extension/num_ext.dart`

## 사용 가능한 위젯

- KChartWidget: 캔들/라인 메인 차트 + 거래량(Vol) + 보조지표(MACD/KDJ/RSI/WR) 다중 표시, 십자선/정보창, 줌/드래그/플링, 트렌드라인 모드, onLoadMore 지원
- DepthChart: 호가 뎁스(매수/매도) 영역 차트, 롱프레스 시 가격/수량 팝업 표시

참고: `PopupInfoView`는 내부 구성요소로 `KChartWidget`에서 사용됩니다. 직접 사용도 가능하지만 권장 공용 API는 `KChartWidget`, `DepthChart`입니다.

## 설치

```yaml
dependencies:
  bydoxe_chart: ^1.0.3
```

## 환경 요구사항

- Dart SDK: ">=3.0.5 <4.0.0" (프로젝트 `pubspec.yaml` 기준)
- Flutter: 최신 안정 채널 권장

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
          // 현재가 라벨을 수직축 정렬과 동일하게(TradingView 스타일)
          nowPriceLabelAlignment: NowPriceLabelAlignment.followVertical,
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
  // 현재가 라벨 텍스트/테두리/점선 컬러는 nowPriceUpColor가 사용됩니다
  nowPriceUpColor: const Color(0xFF32D9F8),
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

## 속성 레퍼런스

### KChartWidget

| 이름 | 타입 | 설명 |
|---|---|---|
| datas | `List<KLineEntity>?` | 차트 데이터(OHLCV). `DataUtil.calculate`로 지표 필드 사전 계산 권장 |
| chartStyle | `ChartStyle` | 패딩, 포인트/캔들 폭, 그리드, 현재가 라인 등 스타일 설정 |
| chartColors | `ChartColors` | 배경/텍스트/상승·하락/지표/깊이/선택 영역 등 색상 팔레트 |
| isTrendLine | `bool` | 트렌드라인 모드 활성화 여부(롱프레스 후 라인 기록/표시) |
| xFrontPadding | `double` | 왼쪽 여백(스크롤 경계 계산에 반영) |
| mainStateLi | `Set<MainState>` | 메인 지표 목록. `MA`, `BOLL`, `SAR` 중 다중 선택 가능 |
| secondaryStateLi | `Set<SecondaryState>` | 보조 지표 목록. `MACD`, `KDJ`, `RSI`, `WR` 다중 선택 |
| volHidden | `bool` | 거래량(Vol) 차트 숨김 여부 |
| isLine | `bool` | 메인 차트를 라인 모드로 표시(기본은 캔들) |
| isTapShowInfoDialog | `bool` | 탭으로 정보창 표시 활성화(롱프레스 십자선과 병행) |
| hideGrid | `bool` | 그리드 라인 숨김 여부 |
| showNowPrice | `bool` | 현재가 점선/라벨 표시 여부 |
| showInfoDialog | `bool` | 정보창 위젯(`PopupInfoView`) 표시 여부 |
| materialInfoDialog | `bool` | 정보창에 Material 래핑 적용 여부 |
| chartTranslations | `ChartTranslations` | 정보창 라벨 텍스트 번역 값 |
| timeFormat | `List<String>` | 정보창 시간 포맷. `TimeFormat.YEAR_MONTH_DAY` 등 (x축 포맷은 `ChartStyle.dateTimeFormat` 사용 또는 자동 추론) |
| nowPriceLabelAlignment | `NowPriceLabelAlignment` | 현재가 라벨 정렬: `followVertical`(수직축 정렬과 동일), `left`, `right` |
| positionLabelAlignment | `PositionLabelAlignment` | 포지션 좌/우 라벨 정렬 기준(우측 가격칩은 우측 정렬, 좌측 포지션칩은 좌측 정렬을 기본으로 하되 이 옵션으로 동기화할 수 있음) |
| positionLines | `List<PositionLineEntity>` | 포지션 라인/칩 구성 리스트 |
| onPositionAction | `void Function(int id, PositionAction action)?` | 포지션 액션 콜백(닫기/TP/SL). 인자는 `PositionLineEntity.id`, `PositionAction` |
| onLoadMore | `Function(bool)?` | 좌/우 끝 도달 시 콜백. `true`=좌측, `false`=우측 끝 |
| onEdgeLoadTs | `void Function(bool isLeft, int ts)?` | 끝 도달 시 페이징 기준 타임스탬프 제공. `true`(좌측)=현재 마지막 봉 시간+1ms, `false`(우측)=현재 첫 봉 시간-1ms |
| fixedLength | `int` | 가격/수치 소수 자릿수(기본 자동 유추, 수동 지정 가능) |
| maDayList | `List<int>` | MA 계산 기간 목록(예: `[5,10,20]`) |
| indicatorMA | `List<IndicatorMA>?` | MA 라벨/색상 커스터마이즈(최대 10개) |
| indicatorEMA | `List<IndicatorEMA>?` | EMA 주기/색상 커스터마이즈(최대 10개) 및 EMA 라벨 표시 |
| indicatorBOLL | `IndicatorBOLL?` | BOLL 주기/밴드폭/표시여부/색상 설정 |
| indicatorSAR | `IndicatorSAR?` | SAR 색상 및 시작/최대 가속도(%) 파라미터 설정 |
| indicatorAVL | `IndicatorAVL?` | AVL(캔들 평균가) 색상 설정 및 라벨 표시 |
| indicatorVolMA | `List<IndicatorVolMA>?` | 거래량 MA 다중 주기/색상 설정(최대 10개) |
| flingTime | `int` | 플링 애니메이션 지속(ms) |
| flingRatio | `double` | 플링 속도 비율(관성 세기) |
| flingCurve | `Curve` | 플링 커브(e.g. `Curves.decelerate`) |
| isOnDrag | `Function(bool)?` | 드래그 상태 콜백. `true`=드래그 중, `false`=종료 |
| verticalTextAlignment | `VerticalTextAlignment` | 수직축 값 라벨 정렬: `left` 또는 `right` |
| mBaseHeight | `double` | 기준 높이. 내부적으로 볼륨/보조 섹션 높이 산출에 사용 |

노트:

- x축 시간 포맷 커스텀은 `chartStyle.dateTimeFormat`을 설정하세요. 설정하지 않으면 데이터 주기를 자동 추론하여 포맷을 선택합니다. 정보창의 시간은 `timeFormat`을 따릅니다.
- 우측 가격축 드래그에 의한 수직 스케일은 현재 구현상 기본 표시 범위보다 더 넓게(줌 아웃) 확장만 허용됩니다. 기본 범위보다 더 좁게(줌 인) 축소하는 동작은 제한됩니다.

### 스크롤/페이징 동작

- `onLoadMore(bool isLeft)`: 플링으로 양 끝에 도달했을 때 호출됩니다. 좌측 끝 도달 시 `true`, 우측 끝 도달 시 `false`.
- `onEdgeLoadTs(bool isLeft, int ts)`: 끝 도달 시 함께 제공되는 타임스탬프입니다.
  - `isLeft=true`(좌측): 현재 로딩된 데이터의 마지막 봉 시간 + 1ms(이후 구간 로드에 사용)
  - `isLeft=false`(우측): 현재 로딩된 데이터의 첫 봉 시간 - 1ms(이전 구간 로드에 사용)

예)

```dart
KChartWidget(
  datas,
  chartStyle,
  chartColors,
  isTrendLine: false,
  onEdgeLoadTs: (isLeft, ts) {
    if (!isLeft) {
      // 우측 끝: ts 이전 구간 추가 로드
      loadMoreKlineData(ts);
    }
  },
)
```

참고:

- `datas`가 비어있을 경우 내부 스크롤/줌 상태가 초기화됩니다.
- 보조 지표가 많을수록 전체 높이(`mBaseHeight`) 대비 보조 영역이 늘어납니다.

### DepthChart

| 이름 | 타입 | 설명 |
|---|---|---|
| bids | `List<DepthEntity>` | 매수 뎁스 데이터(가격, 누적/구간 수량) |
| asks | `List<DepthEntity>` | 매도 뎁스 데이터(가격, 누적/구간 수량) |
| chartColors | `ChartColors` | 뎁스 라인/영역/텍스트/선택 박스 등 색상 |
| baseUnit | `int` | 수량 소수 자릿수 |
| quoteUnit | `int` | 가격 소수 자릿수 |
| offset | `Offset` | 롱프레스 팝업 위치 보정(오프셋) |
| chartTranslations | `DepthChartTranslations` | 팝업 라벨 번역(Price/Amount) |

- 기본값: `baseUnit = 2`, `quoteUnit = 6`, `offset = Offset(10, 10)`

### 포지션 라인(Position Lines)

KChartWidget에서 보유 포지션의 평단가를 수평 라인으로 표시할 수 있습니다.

- 속성: `positionLines: List<PositionLineEntity>`
- 항목: `id:int`(필수), `price`(필수), `isLong`(선택), `label`(선택), `color`(선택), `lineWidth`(선택)
- 라벨 정렬: 가격 라벨은 `nowPriceLabelAlignment`로 제어됩니다. `positionLabelAlignment`는 현재 버전에서 예약 필드이며 렌더 정렬에는 아직 적용되지 않습니다.

스타일(기본 구현)

- 현재가 라벨: 둥근 사각형 칩(라운드 4), 텍스트/테두리 단일 색, 배경 `selectFillColor`, 점선은 기본적으로 마지막 봉의 x부터 라벨 가장자리까지만 표시
  - 색상 설정: 텍스트/테두리/점선 컬러는 `ChartColors.nowPriceUpColor`(상승/하락 무관 동일 적용), 배경은 `ChartColors.selectFillColor`
- 포지션 라인: 화면 가로 점선(`position.color`),
  - 우측 가격 칩: 배경 `bgColor`, 테두리/텍스트 `position.color`, 현재가 라벨과 동일한 칩 크기 규칙(padH=5, padV=2, radius=4)
  - 좌측 포지션 칩(2파트): 외곽선 `position.color`, 왼쪽 파트 배경 `position.color`(텍스트 흰색, "Long xx.xx%" 또는 "Short xx.xx%"), 오른쪽 파트 배경 `bgColor`(텍스트 `position.color`, 내용은 `label`)

인터랙션(확장/액션 버튼)

- 좌측 포지션 칩을 탭하면 해당 라인이 활성화되어 점선→실선으로 변경되고, 칩 오른쪽에 액션 버튼 3개가 나타납니다.
  - 닫기(×), TP, SL 버튼
  - 버튼 높이=칩 높이, 배경=`bgColor`, 테두리/텍스트=`position.color`
- 각 버튼을 탭하면 `(id, action)` 형태로 콜백이 전달됩니다.
- 활성 상태에서 칩/버튼 외 영역을 탭하면 비활성(닫힘)

현재가 라벨의 고정 모드(좌측 스크롤 시)

- 마지막 분봉이 화면 밖으로 나가면 현재가 라벨은 화면 우측에서 30% 지점(= 좌측 기준 70%)에 고정 표기됩니다
- 이때 라벨 오른쪽에 화살표가 표시되며, 라벨/화살표를 탭하면 차트를 최신 분봉이 보이도록 우측 끝으로 이동합니다
- 점선은 라벨 기준으로 좌/우 양방향으로 화면 끝까지 이어져 표시됩니다(촘촘한 패턴)

```dart
KChartWidget(
  datas,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  positionLines: [
    PositionLineEntity(
      id: 1,
      price: 103.25,
      isLong: true,
      label: 'BTCUSDT',
      color: const Color(0xFF32D9F8),
    ),
  ],
  onPositionAction: (id, action) {
    // action: PositionAction.close | PositionAction.tp | PositionAction.sl
    // id: PositionLineEntity.id
  },
)
```

### 마커(Markers)

포지션 체결 이벤트를 B/S 마커로 표시합니다.

- 속성: `markers: List<PositionMarkerEntity>`
- 항목: `id:int`, `time:int(ms)`, `type: MarkerType.buy|sell`, `color`(선택)
- 표기: `buy`는 해당 봉 아래에 B, `sell`은 해당 봉 위에 S가 배치됩니다.
- 스타일: 마커는 말풍선 버블로 표기됩니다(꼬리 방향은 캔들을 가리킴)
  - 버블 배경색: 마커 색(`color` 없으면 `upColor/dnColor` 자동 적용)
  - 텍스트 색: 흰색
  - 꼬리(tail): 삼각형으로 봉의 고가/저가 방향을 가리켜 체결 지점을 명확히 표시
- 겹침 처리: 동일 봉 시간 구간[t(i), t(i+1))에 여러 마커가 있으면 “최신(마지막)” 1개만 렌더링됩니다.

```dart
final markers = <PositionMarkerEntity>[
  PositionMarkerEntity(id: 101, time: datas[20].time!, type: MarkerType.buy),
  PositionMarkerEntity(id: 102, time: datas[45].time!, type: MarkerType.sell),
];

KChartWidget(
  datas,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  markers: markers,
)
```

예시:

```dart
final positions = <PositionLineEntity>[
  PositionLineEntity(id: 1, price: 103.25, isLong: true, label: 'Entry 103.25'),
  PositionLineEntity(id: 2, price: 99.80, isLong: false, label: 'Hedge 99.80', lineWidth: 1.5),
];

KChartWidget(
  datas,
  ChartStyle(),
  ChartColors(),
  isTrendLine: false,
  positionLines: positions,
  nowPriceLabelAlignment: NowPriceLabelAlignment.right, // 현재가 라벨 우측 정렬(예시)
  positionLabelAlignment: PositionLabelAlignment.left, // 포지션 좌측 칩 좌측 정렬(예시)
  verticalTextAlignment: VerticalTextAlignment.left,
)
```

현재가 라벨 색상 설정 예시

```dart
final colors = ChartColors(
  // 현재가 칩 텍스트/테두리/점선 컬러
  nowPriceUpColor: const Color(0xFF32D9F8),
  // 현재가 칩 배경 컬러
  selectFillColor: const Color(0xFF0F1115),
  // 차트 배경(우측 가격칩/포지션 칩 오른쪽 파트 배경으로도 사용)
  bgColor: const Color(0xFF0F1115),
);

KChartWidget(
  datas,
  ChartStyle()
    ..nowPriceLineLength = 4.5
    ..nowPriceLineSpan = 3.5
    ..nowPriceLineWidth = 1,
  colors,
  isTrendLine: false,
  nowPriceLabelAlignment: NowPriceLabelAlignment.right,
);
```

참고:

- 현재가 라벨 텍스트/테두리는 `nowPriceUpColor`로 그려지며, `nowPriceTextColor`는 현재 구현상 사용되지 않습니다.
- EMA/AVL을 사용하려면 `mainStateLi`에 `MainState.EMA`, `MainState.AVL`을 추가하고, 필요 시 `indicatorEMA`, `indicatorAVL`로 색상/라벨을 지정하세요. `DataUtil.calcEMAList`를 사용하면 데이터에 EMA 값이 채워져 EMA 라인이 렌더링됩니다.
