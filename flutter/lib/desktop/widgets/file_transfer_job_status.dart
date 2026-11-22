import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../common.dart';
import '../../consts.dart';
import '../../models/file_model.dart';

class FileTransferJobStatus extends StatelessWidget {
  const FileTransferJobStatus({super.key, required this.item});

  final JobProgress item;

  @override
  Widget build(BuildContext context) {
    final status = item.getStatus();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          waitDuration: Duration(milliseconds: 500),
          message: status,
          child: Text(status,
              style: TextStyle(
                fontSize: 12,
                color: MyTheme.darkGray,
              )).marginOnly(top: 6),
        ),
        if (item.type == JobType.transfer &&
            item.state == JobState.inProgress &&
            item.totalSize > 0)
          LinearPercentIndicator(
            animateFromLastPercent: true,
            center: SizedBox.expand(
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [item.percent, item.percent],
                ).createShader(bounds),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      text: item.percentText,
                      children: [
                        if (item.recvJobRes)
                          TextSpan(
                            text: ' ${readableFileSize(item.speed)}/s',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: MyTheme.darkGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            barRadius: Radius.circular(15),
            percent: item.percent,
            progressColor: MyTheme.accent,
            backgroundColor: Theme.of(context).hoverColor,
            lineHeight: kDesktopFileTransferRowHeight,
          ).paddingSymmetric(vertical: 8),
      ],
    );
  }
}
