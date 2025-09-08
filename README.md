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
