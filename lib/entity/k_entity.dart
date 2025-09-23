import 'candle_entity.dart';
import 'kdj_entity.dart';
import 'macd_entity.dart';
import 'rsi_entity.dart';
import 'wr_entity.dart';
import 'obv_entity.dart';
import 'stoch_rsi_entity.dart';
import 'volume_entity.dart';

class KEntity
    with
        CandleEntity,
        VolumeEntity,
        KDJEntity,
        RSIEntity,
        WREntity,
        OBVEntity,
        StochRSIEntity,
        MACDEntity {}
