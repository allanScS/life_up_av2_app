import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.sincronizado});

  final bool sincronizado;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: sincronizado ? 'Sincronizado' : 'Pendente de envio',
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: sincronizado
              ? AppColors.primarySoft
              : const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          sincronizado ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
          color: sincronizado ? AppColors.primary : AppColors.warning,
          size: 18,
        ),
      ),
    );
  }
}
