import 'dart:math';
import 'dart:math' as math;

import '../entity/index.dart';

class DataUtil {
  static calculate(List<KLineEntity> dataList,
      [List<int> maDayList = const [5, 10, 20], int n = 20, k = 2]) {
    /// calculate main state
    calcMA(dataList, maDayList);
    calcBOLL(dataList, n, k);
    calcSAR(dataList);

    /// calculate secondary state
    calcVolumeMA(dataList);
    calcKDJ(dataList);
    calcMACD(dataList);
    calcRSI(dataList);
    calcWR(dataList);
  }

  /// Calculate multiple EMA series and store in emaValueList (max 10 periods)
  static void calcEMAList(List<KLineEntity> dataList, List<int> periods) {
    if (dataList.isEmpty || periods.isEmpty) return;
    final List<int> ps = periods.take(10).toList();
    final List<double> lastEma = List<double>.filled(ps.length, 0.0);
    for (int i = 0; i < dataList.length; i++) {
      final KLineEntity e = dataList[i];
      e.emaValueList = List<double>.filled(ps.length, 0.0);
      for (int j = 0; j < ps.length; j++) {
        final int p = ps[j] <= 1 ? 1 : ps[j];
        final double alpha = 2.0 / (p + 1);
        if (i == 0) {
          lastEma[j] = e.close;
        } else {
          lastEma[j] = alpha * e.close + (1 - alpha) * lastEma[j];
        }
        e.emaValueList![j] = lastEma[j];
      }
    }
  }

  static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
    List<double> ma = List<double>.filled(maDayList.length, 0);
    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice;
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          }
        }
      }
    }
  }

  static void calcSAR(List<KLineEntity> dataList) {
    const List<double> params = [2, 2, 20]; //calcParams default
    final startAf = params[0] / 100;
    final step = params[1] / 100;
    final maxAf = params[2] / 100;

    // Acceleration factor
    double af = startAf;
    // Extreme point
    double ep = -100;
    // Determine trend direction — false: downtrend
    bool isIncreasing = false;
    double sar = 0;

    for (int i = 0; i < dataList.length; ++i) {
      // the previous period SAR
      final preSar = sar;
      final high = dataList[i].high;
      final low = dataList[i].low;

      if (isIncreasing) {
        // Uptrend
        if (ep == -100 || ep < high) {
          // Reinitialize parameters
          ep = high;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final lowMin = min(dataList[max(1, i) - 1].low, low);
        if (sar > dataList[i].low) {
          sar = ep;
          // Reinitialize parameters
          af = startAf;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar > lowMin) {
          sar = lowMin;
        }
      } else {
        if (ep == -100 || ep > low) {
          // Reinitialize parameters
          ep = low;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final highMax = max(dataList[max(1, i) - 1].high, high);
        if (sar < dataList[i].high) {
          sar = ep;
          // Reinitialize parameters
          af = 0;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar < highMax) {
          sar = highMax;
        }
      }

      dataList[i].sar = sar;
    }
  }

  /// SAR calculation with configurable start/step/max (percent inputs)
  /// startPercent, stepPercent, maxPercent are provided in percent units
  /// (e.g., 2 => 0.02, 20 => 0.20)
  static void calcSARWithParams(
    List<KLineEntity> dataList, {
    double startPercent = 2,
    double stepPercent = 2,
    double maxPercent = 20,
  }) {
    final double startAf = startPercent / 100.0;
    final double step = stepPercent / 100.0;
    final double maxAf = maxPercent / 100.0;
    if (dataList.isEmpty) return;

    // 1) 초기 추세 판단: 첫 2개의 종가/고저 비교
    bool upTrend;
    if (dataList.length >= 2) {
      upTrend = dataList[1].close >= dataList[0].close;
    } else {
      upTrend = true;
    }

    // 2) 초기 SAR/EP 설정
    double sar;
    double ep; // extreme point
    double af = startAf;
    if (upTrend) {
      sar = dataList[0].low; // 이전 최저가에서 시작
      ep = max(
          dataList[0].high, dataList[1 <= dataList.length - 1 ? 1 : 0].high);
    } else {
      sar = dataList[0].high; // 이전 최고가에서 시작
      ep = min(dataList[0].low, dataList[1 <= dataList.length - 1 ? 1 : 0].low);
    }
    dataList[0].sar = sar;

    for (int i = 1; i < dataList.length; i++) {
      final cur = dataList[i];

      // 3) 기본 업데이트
      sar = sar + af * (ep - sar);

      if (upTrend) {
        // SAR는 이전 두 봉의 최저가보다 작거나 같아야 함
        if (i >= 2) {
          sar = min(sar, min(dataList[i - 1].low, dataList[i - 2].low));
        } else {
          sar = min(sar, dataList[i - 1].low);
        }
        // EP 갱신 및 AF 증가
        if (cur.high > ep) {
          ep = cur.high;
          af = min(af + step, maxAf);
        }
        // 추세 전환 체크
        if (cur.low < sar) {
          // downtrend로 전환
          upTrend = false;
          sar = ep; // 전환 시 SAR = 직전 EP
          ep = cur.low;
          af = startAf;
        }
      } else {
        // downtrend: SAR는 이전 두 봉의 최고가보다 크거나 같아야 함
        if (i >= 2) {
          sar = max(sar, max(dataList[i - 1].high, dataList[i - 2].high));
        } else {
          sar = max(sar, dataList[i - 1].high);
        }
        if (cur.low < ep) {
          ep = cur.low;
          af = min(af + step, maxAf);
        }
        if (cur.high > sar) {
          // uptrend로 전환
          upTrend = true;
          sar = ep;
          ep = cur.high;
          af = startAf;
        }
      }

      cur.sar = sar;
    }
  }

  static void calcBOLL(List<KLineEntity> dataList, int n, int k) {
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.mb = entity.BOLLMA!;
        entity.up = entity.mb! + k * md;
        entity.dn = entity.mb! - k * md;
      }
    }
  }

  static void _calcBOLLMA(int day, List<KLineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      ma += entity.close;
      if (i == day - 1) {
        entity.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.BOLLMA = ma / day;
      } else {
        entity.BOLLMA = null;
      }
    }
  }

  static void calcMACD(List<KLineEntity> dataList) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  /// MACD with configurable periods using EMA smoothing
  /// shortPeriod, longPeriod, maPeriod must be >= 1
  static void calcMACDWithParams(
    List<KLineEntity> dataList, {
    int shortPeriod = 12,
    int longPeriod = 26,
    int maPeriod = 9,
  }) {
    if (dataList.isEmpty) return;
    final int s = shortPeriod <= 1 ? 1 : shortPeriod;
    final int l = longPeriod <= 1 ? 1 : longPeriod;
    final int m = maPeriod <= 1 ? 1 : maPeriod;

    double emaShort = 0.0;
    double emaLong = 0.0;
    double dea = 0.0;
    final double alphaS = 2.0 / (s + 1);
    final double alphaL = 2.0 / (l + 1);
    final double alphaM = 2.0 / (m + 1);

    for (int i = 0; i < dataList.length; i++) {
      final KLineEntity e = dataList[i];
      if (i == 0) {
        emaShort = e.close;
        emaLong = e.close;
        dea = 0.0;
      } else {
        emaShort = alphaS * e.close + (1 - alphaS) * emaShort;
        emaLong = alphaL * e.close + (1 - alphaL) * emaLong;
      }
      final double dif = emaShort - emaLong;
      dea = alphaM * dif + (1 - alphaM) * dea;
      final double macd = (dif - dea) * 2;
      e.dif = dif;
      e.dea = dea;
      e.macd = macd;
    }
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  /// Calculate multiple Volume MA series and store in volMaValueList (max 10 periods)
  static void calcVolumeMAList(List<KLineEntity> dataList, List<int> periods) {
    if (dataList.isEmpty || periods.isEmpty) return;
    final List<int> ps = periods.take(10).toList();
    final List<double> windows = List<double>.filled(ps.length, 0.0);
    for (int i = 0; i < dataList.length; i++) {
      final KLineEntity e = dataList[i];
      e.volMaValueList = List<double>.filled(ps.length, 0.0);
      for (int j = 0; j < ps.length; j++) {
        final int p = ps[j] <= 1 ? 1 : ps[j];
        windows[j] += e.vol;
        if (i == p - 1) {
          e.volMaValueList![j] = windows[j] / p;
        } else if (i >= p) {
          windows[j] -= dataList[i - p].vol;
          e.volMaValueList![j] = windows[j] / p;
        } else {
          e.volMaValueList![j] = 0.0;
        }
      }
    }
  }

  /// Calculate OBV, OBV-MA, OBV-EMA
  static void calcOBV(
    List<KLineEntity> dataList, {
    int maPeriod = 10,
    int emaPeriod = 10,
  }) {
    if (dataList.isEmpty) return;
    double obv = 0.0;
    double obvEma = 0.0;
    final int m = maPeriod <= 1 ? 1 : maPeriod;
    final int e = emaPeriod <= 1 ? 1 : emaPeriod;
    final double alpha = 2.0 / (e + 1);
    final List<double> window = [];
    for (int i = 0; i < dataList.length; i++) {
      final cur = dataList[i];
      final prev = dataList[math.max(0, i - 1)];
      if (i == 0) {
        obv = 0.0;
      } else {
        // use volume normalized by close price
        final double unit = (cur.close == 0) ? 0.0 : (cur.vol / cur.close);
        if (cur.close > prev.close) {
          obv += unit;
        } else if (cur.close < prev.close) {
          obv -= unit;
        }
      }
      cur.obv = obv;
      // MA
      window.add(obv);
      if (window.length > m) window.removeAt(0);
      cur.obvMA = window.isEmpty
          ? 0.0
          : (window.reduce((a, b) => a + b) / window.length);
      // EMA
      if (i == 0) {
        obvEma = obv;
      } else {
        obvEma = alpha * obv + (1 - alpha) * obvEma;
      }
      cur.obvEMA = obvEma;
    }
  }

  static void calcRSI(List<KLineEntity> dataList) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  /// Calculate StochRSI (K, D lines)
  static void calcStochRSI(
    List<KLineEntity> dataList, {
    int lengthRSI = 14,
    int lengthStoch = 14,
    int smoothK = 3,
    int smoothD = 3,
  }) {
    if (dataList.isEmpty) return;
    // 1) Precompute RSI(lengthRSI)
    final List<double?> rsiArr = List<double?>.filled(dataList.length, null);
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      final e = dataList[i];
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        final double diff = e.close - dataList[i - 1].close;
        final double rMax = max(0, diff);
        final double rAbs = diff.abs();
        rsiMaxEma = (rMax + (lengthRSI - 1) * rsiMaxEma) / lengthRSI;
        rsiABSEma = (rAbs + (lengthRSI - 1) * rsiABSEma) / lengthRSI;
        rsi = (rsiABSEma == 0) ? 0 : (rsiMaxEma / rsiABSEma) * 100.0;
      }
      if (i < lengthRSI - 1) rsi = 0;
      rsiArr[i] = rsi;
    }

    // 2) StochRSI over window lengthStoch
    final List<double> rawK = List<double>.filled(dataList.length, 0.0);
    for (int i = 0; i < dataList.length; i++) {
      final int start = max(0, i - lengthStoch + 1);
      double rMin = double.maxFinite, rMax = -double.maxFinite;
      for (int j = start; j <= i; j++) {
        final v = rsiArr[j] ?? 0.0;
        if (v < rMin) rMin = v;
        if (v > rMax) rMax = v;
      }
      final double denom = (rMax - rMin).abs();
      rawK[i] = (denom == 0) ? 0.0 : ((rsiArr[i]! - rMin) / denom) * 100.0;
    }

    // 3) Smooth K and D with simple moving average
    double sma(List<double> arr, int end, int win) {
      final int start = max(0, end - win + 1);
      double sum = 0.0;
      int cnt = 0;
      for (int i = start; i <= end; i++) {
        sum += arr[i];
        cnt++;
      }
      return cnt == 0 ? 0.0 : sum / cnt;
    }

    for (int i = 0; i < dataList.length; i++) {
      final double k = sma(rawK, i, smoothK);
      // D = SMA(K, smoothD)
      final List<double> kSeries =
          List<double>.generate(i + 1, (t) => sma(rawK, t, smoothK));
      final double dFixed = sma(kSeries, i, smoothD);
      dataList[i].stochK = k;
      dataList[i].stochD = dFixed;
    }

    // Debug logging removed
  }

  /// Calculate multiple RSI series and store in rsiValueList (max 3 periods)
  static void calcRSIList(List<KLineEntity> dataList, List<int> periods) {
    if (dataList.isEmpty || periods.isEmpty) return;
    final List<int> ps = periods.take(3).toList();
    final int n = ps.length;
    final List<double> absEma = List<double>.filled(n, 0.0);
    final List<double> maxEma = List<double>.filled(n, 0.0);
    for (int i = 0; i < dataList.length; i++) {
      final KLineEntity e = dataList[i];
      e.rsiValueList = List<double>.filled(n, 0.0);
      if (i == 0) {
        // seed
        for (int j = 0; j < n; j++) {
          absEma[j] = 0.0;
          maxEma[j] = 0.0;
          e.rsiValueList![j] = 0.0;
        }
        continue;
      }
      final double change = e.close - dataList[i - 1].close;
      final double rMax = math.max(0, change);
      final double rAbs = change.abs();
      for (int j = 0; j < n; j++) {
        final int p = ps[j] <= 1 ? 1 : ps[j];
        maxEma[j] = (rMax + (p - 1) * maxEma[j]) / p;
        absEma[j] = (rAbs + (p - 1) * absEma[j]) / p;
        final double denom = absEma[j] == 0 ? 0.0 : absEma[j];
        double value = denom == 0.0 ? 0.0 : (maxEma[j] / denom) * 100.0;
        if (i < (p - 1)) value = 0.0;
        e.rsiValueList![j] = value;
      }
    }
  }

  static void calcKDJ(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  /// KDJ calculation with configurable window and smoothing periods
  /// period: lookback window for RSV (typically 9)
  /// m1: smoothing for K (typically 3)
  /// m2: smoothing for D (typically 3)
  static void calcKDJWithParams(
    List<KLineEntity> dataList, {
    int period = 9,
    int m1 = 3,
    int m2 = 3,
  }) {
    if (dataList.isEmpty) return;
    final int n = period <= 1 ? 1 : period;
    final int s1 = m1 <= 1 ? 1 : m1;
    final int s2 = m2 <= 1 ? 1 : m2;

    double prevK = 50.0;
    double prevD = 50.0;
    // seed first
    dataList[0].k = prevK;
    dataList[0].d = prevD;
    dataList[0].j = 50.0;

    for (int i = 1; i < dataList.length; i++) {
      final int start = math.max(0, i - n + 1);
      double low = double.maxFinite;
      double high = -double.maxFinite;
      for (int j = start; j <= i; j++) {
        final e = dataList[j];
        if (e.low < low) low = e.low;
        if (e.high > high) high = e.high;
      }
      final double denom = (high - low).abs();
      double rsv =
          denom == 0 ? 0.0 : ((dataList[i].close - low) / denom) * 100.0;
      // K = SMA(RSV, m1) => (m1-1)/m1 * prevK + 1/m1 * RSV
      final double k = ((s1 - 1) * prevK + rsv) / s1;
      // D = SMA(K, m2)
      final double d = ((s2 - 1) * prevD + k) / s2;
      final double j = 3 * k - 2 * d;
      prevK = k;
      prevD = d;
      dataList[i].k = k;
      dataList[i].d = d;
      dataList[i].j = j;
    }
  }

  static void calcWR(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }
}
