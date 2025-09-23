import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';

import 'services/rest_api_service.dart';
import 'services/websocket_service.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      ),
      home: const ChartExamplePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class ChartExamplePage extends StatefulWidget {
  const ChartExamplePage({super.key, this.title});

  final String? title;

  @override
  State<ChartExamplePage> createState() => _ChartExamplePageState();
}

class _ChartExamplePageState extends State<ChartExamplePage> {
  final ws = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  List<KLineEntity>? datas;
  KLineEntity? _lastCandle;
  bool showLoading = true;
  bool _volHidden = false;
  final List<MainState> _mainStateLi = [];
  final List<SecondaryState> _secondaryStateLi = [];
  List<DepthEntity>? _bids, _asks;

  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors(nowPriceUpColor: Colors.black);

  final List<IndicatorMA> _indicatorMA = [
    IndicatorMA(5, Colors.red),
    IndicatorMA(10, Colors.blue),
    IndicatorMA(20, Colors.green),
    IndicatorMA(1, Colors.amber),
    IndicatorMA(1, Colors.purple),
    IndicatorMA(1, Colors.orange),
    IndicatorMA(1, Colors.brown),
    IndicatorMA(1, Colors.cyan),
    IndicatorMA(1, Colors.deepPurple),
    IndicatorMA(1, Colors.blueAccent),
  ];

  final List<IndicatorEMA> _indicatorEMA = [
    IndicatorEMA(5, Colors.red),
    IndicatorEMA(10, Colors.blue),
    IndicatorEMA(20, Colors.green),
    IndicatorEMA(1, Colors.amber),
    IndicatorEMA(1, Colors.purple),
    IndicatorEMA(1, Colors.orange),
    IndicatorEMA(1, Colors.brown),
    IndicatorEMA(1, Colors.cyan),
    IndicatorEMA(1, Colors.deepPurple),
    IndicatorEMA(1, Colors.blueAccent),
  ];

  final IndicatorBOLL _indicatorBOLL = IndicatorBOLL(
    20,
    2,
    true,
    true,
    true,
    Colors.red,
    Colors.blue,
    Colors.green,
  );

  final IndicatorSAR _indicatorSAR = IndicatorSAR(0.02, 0.2, Colors.red);
  final IndicatorAVL _indicatorAVL = IndicatorAVL(Colors.red);

  final List<IndicatorVolMA> _indicatorVolMA = [
    IndicatorVolMA(5, Colors.red),
    IndicatorVolMA(10, Colors.blue),
  ];

  final List<RSIInputEntity> _indicatorRSI = [
    RSIInputEntity(value: 6, color: Colors.red),
    RSIInputEntity(value: 12, color: Colors.blue),
    RSIInputEntity(value: 24, color: Colors.green),
  ];

  final MACDInputEntity _indicatorMACD = MACDInputEntity(
    shortPeriod: 12,
    longPeriod: 26,
    MAPeriod: 9,
    difShow: true,
    difColor: Colors.orange,
    deaShow: true,
    deaColor: Colors.purple,
    macdShow: true,
    macdLongGrowType: GrowFallType.hollow,
    macdLongGrowColor: Colors.green,
    macdLongFallType: GrowFallType.solid,
    macdLongFallColor: Colors.green,
    macdShortGrowType: GrowFallType.hollow,
    macdShortGrowColor: Colors.red,
    macdShortFallType: GrowFallType.solid,
    macdShortFallColor: Colors.red,
  );

  final WRInputEntity _indicatorWR = WRInputEntity(
    value: 14,
    color: Colors.red,
  );

  final OBVInputEntity _indicatorOBV = OBVInputEntity(
    obvColor: Colors.red,
    obvMAShow: true,
    obvMAValue: 7,
    obvMAColor: Colors.blue,
    obvEMAShow: true,
    obvEMAValue: 7,
    obvEMAColor: Colors.green,
  );

  final StochRSIInputEntity _indicatorStochRSI = StochRSIInputEntity(
    lengthRSI: 14,
    lengthStoch: 14,
    smoothK: 3,
    smoothD: 3,
    stochRSIShow: true,
    stochRSIKColor: Colors.orange,
    stochRSIDShow: true,
    stochRSIDColor: Colors.purple,
  );

  @override
  void initState() {
    super.initState();
    loadKlineData();
    rootBundle.loadString('assets/depth.json').then((result) {
      final parseJson = json.decode(result);
      final tick = parseJson['tick'] as Map<String, dynamic>;
      final List<DepthEntity> bids = (tick['bids'] as List<dynamic>)
          .map<DepthEntity>(
            (item) => DepthEntity(item[0] as double, item[1] as double),
          )
          .toList();
      final List<DepthEntity> asks = (tick['asks'] as List<dynamic>)
          .map<DepthEntity>(
            (item) => DepthEntity(item[0] as double, item[1] as double),
          )
          .toList();
      initDepth(bids, asks);
    });
  }

  Future<void> loadKlineData() async {
    final response = await RestApiService.getKLineData(null);
    convertKlineData(response);

    // 연속 수신: aggTrade 이벤트를 지속적으로 로그
    _wsSub = ws.listenAggTrade(symbol: 'BTCUSDT').listen((value) {
      final c = _lastCandle;
      if (c == null || datas == null || datas!.isEmpty) return;

      final double last =
          double.tryParse(value['data']['p'] as String) ?? c.close;
      final double quantity =
          double.tryParse(value['data']['q'] as String) ?? 0.0;
      final double tradeVol = quantity * last;
      final int time = value['data']['T'] as int; // ms
      final int nextTime = (c.time ?? 0) + 60000; // c.time + 1분

      if (time < nextTime) {
        // 현재 분 내: 마지막 캔들 갱신
        c.high = math.max(c.high, last);
        c.low = math.min(c.low, last);
        c.close = last;
        c.vol = c.vol + tradeVol;
        datas![datas!.length - 1] = c;
        _lastCandle = c;
      } else {
        // 다음 분 이상: 새 캔들 추가 (nextTime 기준)
        final KLineEntity nc = KLineEntity.fromCustom(
          open: last,
          close: last,
          high: last,
          low: last,
          time: nextTime,
          vol: tradeVol,
        );
        datas!.add(nc);
        _lastCandle = nc;
      }

      // 지표 재계산 및 리빌드
      DataUtil.calculate(
        datas!,
        _indicatorMA.map((e) => e.value).take(10).toList(),
        _indicatorBOLL.period,
        _indicatorBOLL.bandwidth,
      );
      DataUtil.calcEMAList(datas!, _indicatorEMA.map((e) => e.value).toList());
      // MACD 재계산(사용자 지정 파라미터)
      DataUtil.calcMACDWithParams(
        datas!,
        shortPeriod: _indicatorMACD.shortPeriod,
        longPeriod: _indicatorMACD.longPeriod,
        maPeriod: _indicatorMACD.MAPeriod,
      );
      DataUtil.calcSARWithParams(
        datas!,
        startPercent: _indicatorSAR.start,
        stepPercent: _indicatorSAR.start,
        maxPercent: _indicatorSAR.maximum,
      );
      DataUtil.calcVolumeMAList(
        datas!,
        _indicatorVolMA.map((e) => e.value).toList(),
      );
      DataUtil.calcRSIList(datas!, _indicatorRSI.map((e) => e.value).toList());
      DataUtil.calcStochRSI(
        datas!,
        lengthRSI: _indicatorStochRSI.lengthRSI,
        lengthStoch: _indicatorStochRSI.lengthStoch,
        smoothK: _indicatorStochRSI.smoothK,
        smoothD: _indicatorStochRSI.smoothD,
      );
      DataUtil.calcOBV(
        datas!,
        maPeriod: _indicatorOBV.obvMAValue,
        emaPeriod: _indicatorOBV.obvEMAValue,
      );
      setState(() {});
    });
  }

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;
    _bids = [];
    _asks = [];
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    for (var item in bids.reversed) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    for (var item in asks) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    }
    setState(() {});
  }

  Future<void> loadMoreKlineData(int ts) async {
    final response = await RestApiService.getKLineData(ts);
    final List<dynamic> parsed = json.decode(response) as List<dynamic>;
    final List<KLineEntity> more = parsed
        .map<KLineEntity>(
          (item) => KLineEntity.fromCustom(
            open: double.tryParse(item[1].toString()) ?? 0.0,
            close: double.tryParse(item[4].toString()) ?? 0.0,
            time: item[0] as int,
            high: double.tryParse(item[2].toString()) ?? 0.0,
            low: double.tryParse(item[3].toString()) ?? 0.0,
            vol: double.tryParse(item[7].toString()) ?? 0.0,
          ),
        )
        .toList();

    if (datas == null || datas!.isEmpty) {
      datas = more;
    } else {
      final int firstTime = datas!.first.time ?? 0;
      final List<KLineEntity> prepend = more
          .where((e) => (e.time ?? 0) < firstTime)
          .toList();
      datas = [...prepend, ...datas!];
    }

    DataUtil.calculate(
      datas!,
      _indicatorMA.map((e) => e.value).take(10).toList(),
      _indicatorBOLL.period,
      _indicatorBOLL.bandwidth,
    );
    DataUtil.calcEMAList(datas!, _indicatorEMA.map((e) => e.value).toList());
    // MACD 초기 계산(사용자 지정 파라미터)
    DataUtil.calcMACDWithParams(
      datas!,
      shortPeriod: _indicatorMACD.shortPeriod,
      longPeriod: _indicatorMACD.longPeriod,
      maPeriod: _indicatorMACD.MAPeriod,
    );
    DataUtil.calcSARWithParams(
      datas!,
      startPercent: _indicatorSAR.start,
      stepPercent: _indicatorSAR.start,
      maxPercent: _indicatorSAR.maximum,
    );
    // RSI 다중 계산(최대 3개)
    DataUtil.calcRSIList(datas!, _indicatorRSI.map((e) => e.value).toList());
    DataUtil.calcVolumeMAList(
      datas!,
      _indicatorVolMA.map((e) => e.value).toList(),
    );
    // OBV 계산 (OBV, MA, EMA)
    DataUtil.calcOBV(
      datas!,
      maPeriod: _indicatorOBV.obvMAValue,
      emaPeriod: _indicatorOBV.obvEMAValue,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final positions = <PositionLineEntity>[
      PositionLineEntity(
        id: 1, // 포지션 고유 ID
        price: 112321.3, // 포지션 진입가격
        label: "0.001", // 포지션 수량
        color: Colors.red,
        isLong: false,
      ),
      PositionLineEntity(
        id: 2,
        price: 1112614,
        label: "0.02",
        color: Colors.green,
        isLong: true,
      ),
    ];

    final markers = <PositionMarkerEntity>[
      if (datas != null && datas!.length > 5)
        PositionMarkerEntity(
          id: 101,
          time:
              datas![datas!.length - 5].time ??
              DateTime.now().millisecondsSinceEpoch,
          type: MarkerType.buy,
        ),
      if (datas != null && datas!.length > 10)
        PositionMarkerEntity(
          id: 102,
          time:
              datas![datas!.length - 10].time ??
              DateTime.now().millisecondsSinceEpoch,
          type: MarkerType.sell,
        ),
    ];

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const SafeArea(bottom: false, child: SizedBox(height: 10)),
          Stack(
            children: <Widget>[
              KChartWidget(
                datas,
                chartStyle,
                chartColors,
                mBaseHeight: 360,
                isTrendLine: false,
                mainStateLi: _mainStateLi.toSet(),
                volHidden: _volHidden,
                secondaryStateLi: _secondaryStateLi.toSet(),
                fixedLength: 1,
                timeFormat: TimeFormat.YEAR_MONTH_DAY,
                verticalTextAlignment: VerticalTextAlignment.right, // 가격 라벨 정렬
                showNowPrice: true,
                nowPriceLabelAlignment:
                    NowPriceLabelAlignment.right, // 현재가 라벨 정렬
                materialInfoDialog: true,
                isLine: false,
                positionLines: positions,
                onPositionAction: (id, action) {
                  debugPrint('### onPositionAction $id $action');
                },
                markers: markers,
                onEdgeLoadTs: (isLeft, ts) {
                  // 차트가 좌측 도달시, 새로운 캔들 데이터 로드
                  debugPrint('### onEdgeLoadTs $isLeft $ts');
                  if (!isLeft) {
                    loadMoreKlineData(ts);
                  }
                },
                indicatorMA: _indicatorMA,
                indicatorEMA: _indicatorEMA,
                indicatorRSI: _indicatorRSI,
                indicatorWR: _indicatorWR,
                indicatorBOLL: _indicatorBOLL,
                indicatorSAR: _indicatorSAR,
                indicatorAVL: _indicatorAVL,
                indicatorVolMA: _indicatorVolMA,
                indicatorMACD: _indicatorMACD,
                indicatorOBV: _indicatorOBV,
                indicatorStochRSI: _indicatorStochRSI,
              ),
              if (showLoading)
                Container(
                  width: double.infinity,
                  height: 450,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          ),
          _buildTitle(context, 'VOL'),
          buildVolButton(),
          _buildTitle(context, 'Main State'),
          buildMainButtons(),
          _buildTitle(context, 'Secondary State'),
          buildSecondButtons(),
          const SizedBox(height: 30),
          if (_bids != null && _asks != null)
            Container(
              color: Colors.white,
              height: 320,
              width: double.infinity,
              child: DepthChart(_bids!, _asks!, chartColors),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 15),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          // color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildVolButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildButton(
          context: context,
          title: 'VOL',
          isActive: !_volHidden,
          onPress: () {
            _volHidden = !_volHidden;
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget buildMainButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        children: MainState.values.map((e) {
          bool isActive = _mainStateLi.contains(e);
          return _buildButton(
            context: context,
            title: e.name,
            isActive: isActive,
            onPress: () {
              if (isActive) {
                _mainStateLi.remove(e);
              } else {
                _mainStateLi.add(e);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildSecondButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 5,
        children: SecondaryState.values.map((e) {
          bool isActive = _secondaryStateLi.contains(e);
          return _buildButton(
            context: context,
            title: e.name,
            isActive: _secondaryStateLi.contains(e),
            onPress: () {
              if (isActive) {
                _secondaryStateLi.remove(e);
              } else {
                _secondaryStateLi.add(e);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String title,
    required isActive,
    required Function onPress,
  }) {
    late Color? bgColor, txtColor;
    if (isActive) {
      bgColor = Theme.of(context).primaryColor.withAlpha(30);
      txtColor = Theme.of(context).primaryColor;
    } else {
      bgColor = Colors.transparent;
      txtColor = Theme.of(context).textTheme.bodyMedium?.color;
    }
    return InkWell(
      onTap: () {
        onPress();
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: txtColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void convertKlineData(String result) {
    final List<dynamic> parsed = json.decode(result) as List<dynamic>;
    datas = parsed
        .map<KLineEntity>(
          (item) => KLineEntity.fromCustom(
            open: double.tryParse(item[1].toString()) ?? 0.0,
            close: double.tryParse(item[4].toString()) ?? 0.0,
            time: item[0] as int,
            high: double.tryParse(item[2].toString()) ?? 0.0,
            low: double.tryParse(item[3].toString()) ?? 0.0,
            vol: double.tryParse(item[7].toString()) ?? 0.0,
          ),
        )
        .toList();

    // 마지막 봉 저장
    _lastCandle = (datas != null && datas!.isNotEmpty) ? datas!.last : null;

    DataUtil.calculate(
      datas!,
      _indicatorMA.map((e) => e.value).take(10).toList(),
      _indicatorBOLL.period,
      _indicatorBOLL.bandwidth,
    );
    DataUtil.calcEMAList(datas!, _indicatorEMA.map((e) => e.value).toList());
    DataUtil.calcSARWithParams(
      datas!,
      startPercent: _indicatorSAR.start,
      stepPercent: _indicatorSAR.start,
      maxPercent: _indicatorSAR.maximum,
    );
    DataUtil.calcVolumeMAList(
      datas!,
      _indicatorVolMA.map((e) => e.value).toList(),
    );
    DataUtil.calcStochRSI(
      datas!,
      lengthRSI: _indicatorStochRSI.lengthRSI,
      lengthStoch: _indicatorStochRSI.lengthStoch,
      smoothK: _indicatorStochRSI.smoothK,
      smoothD: _indicatorStochRSI.smoothD,
    );
    showLoading = false;
    setState(() {});
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    ws.disconnect();
    super.dispose();
  }
}
