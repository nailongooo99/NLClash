import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/liquid/liquid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusHero extends ConsumerWidget {
  const StatusHero({super.key});

  String get _appVersion {
    try {
      return globalState.packageInfo.version;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final coreStatus = ref.watch(coreStatusProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = coreStatus == CoreStatus.connected;
    final isConnecting = coreStatus == CoreStatus.connecting;
    final containerColor = isRunning
        ? colorScheme.secondaryContainer
        : isConnecting
        ? colorScheme.tertiaryContainer
        : colorScheme.errorContainer;
    final contentColor = isRunning
        ? colorScheme.onSecondaryContainer
        : isConnecting
        ? colorScheme.onTertiaryContainer
        : colorScheme.onErrorContainer;
    final title = isRunning
        ? appLocalizations.connected
        : isConnecting
        ? appLocalizations.connecting
        : appLocalizations.disconnected;
    final icon = isRunning
        ? Icons.bolt_rounded
        : isConnecting
        ? Icons.sync_rounded
        : Icons.block_rounded;
    final modeLabel = switch (mode) {
      Mode.rule => appLocalizations.rule,
      Mode.global => appLocalizations.global,
      Mode.direct => appLocalizations.direct,
    };
    return LiquidGlass(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      blurSigma: 10,
      lensHeight: 14,
      lensAmount: 18,
      tint: containerColor,
      tintOpacity: 0.82,
      highlight: const LiquidHighlightSpec(alpha: 0.6),
      innerShadowRadius: 5,
      innerShadowIntensity: 0.12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: contentColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: contentColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NLClash v$_appVersion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: contentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                modeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
