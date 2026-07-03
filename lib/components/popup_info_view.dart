import 'package:flutter/material.dart';
import 'package:bydoxe_chart/chart_style.dart';
import 'package:bydoxe_chart/chart_translations.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import '../utils/number_util.dart';
import '../utils/price_label_util.dart';

class PopupInfoView extends StatelessWidget {
  final KLineEntity entity;
  final double width;
  final ChartColors chartColors;
  final ChartTranslations chartTranslations;
  final bool materialInfoDialog;
  final List<String> timeFormat;
  final int fixedLength;
  final double? priceLabelTickSize;

  const PopupInfoView({
    Key? key,
    required this.entity,
    required this.width,
    required this.chartColors,
    required this.chartTranslations,
    required this.materialInfoDialog,
    required this.timeFormat,
    required this.fixedLength,
    this.priceLabelTickSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chartColors.selectFillColor,
        border: Border.all(color: chartColors.selectBorderColor, width: 0.5),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    double upDown = entity.change ?? entity.close - entity.open;
    double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
    final double? entityAmount = entity.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem(chartTranslations.date, getDate(entity.time)),
        _buildItem(
            chartTranslations.open,
            formatPriceLabel(entity.open,
                fixedLength: fixedLength, tickSize: priceLabelTickSize)),
        _buildItem(
            chartTranslations.high,
            formatPriceLabel(entity.high,
                fixedLength: fixedLength, tickSize: priceLabelTickSize)),
        _buildItem(
            chartTranslations.low,
            formatPriceLabel(entity.low,
                fixedLength: fixedLength, tickSize: priceLabelTickSize)),
        _buildItem(
            chartTranslations.close,
            formatPriceLabel(entity.close,
                fixedLength: fixedLength, tickSize: priceLabelTickSize)),
        _buildColorItem(chartTranslations.changeAmount,
            formatPriceLabel(upDown,
                fixedLength: fixedLength, tickSize: priceLabelTickSize),
            upDown > 0),
        _buildColorItem(chartTranslations.change,
            '${upDownPercent.toStringAsFixed(2)}%', upDownPercent > 0),
        _buildItem(chartTranslations.vol, NumberUtil.format(entity.vol)),
        if (entityAmount != null)
          _buildItem(chartTranslations.amount, entityAmount.toInt().toString()),
      ],
    );
  }

  Widget _buildColorItem(String label, String info, bool isUp) {
    if (isUp) {
      return _buildItem(label, '+$info',
          textColor: chartColors.infoWindowUpColor);
    }
    return _buildItem(label, info, textColor: chartColors.infoWindowDnColor);
  }

  Widget _buildItem(String label, String info, {Color? textColor}) {
    final infoWidget = Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: chartColors.infoWindowTitleColor,
              fontSize: 10.0,
            ),
          ),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                  color: textColor ?? chartColors.infoWindowNormalColor,
                  fontSize: 10.0),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
    return materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        timeFormat,
      );
}
