import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../bloc/inspection_bloc.dart';
import '../bloc/inspection_event.dart';
import '../bloc/inspection_state.dart';
import '../../data/models/daily_check_model.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class DailyCheckHistoryPage extends StatelessWidget {
  const DailyCheckHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InspectionBloc>()..add(InspectionHistoryRequested()),
      child: AppShell(
        title: 'Daily Checks',
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.go('/driver/checks/add'),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('New Check', style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
        child: BlocBuilder<InspectionBloc, InspectionState>(
          builder: (context, state) {
            if (state is InspectionLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2));
            }
            if (state is InspectionHistoryLoaded) {
              if (state.checks.isEmpty) {
                return EmptyState(
                  icon: Icons.checklist_outlined,
                  title: 'No inspections yet',
                  subtitle: 'Complete your pre-trip vehicle inspection.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/driver/checks/add'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                    child: const Text('Start Inspection'),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  context.read<InspectionBloc>().add(InspectionHistoryRequested());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.checks.length,
                  itemBuilder: (_, i) => _CheckCard(check: state.checks[i]),
                ),
              );
            }
            if (state is InspectionError) {
              return Center(child: Text(state.message,
                style: const TextStyle(color: AppTheme.rose)));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final DailyCheckModel check;
  const _CheckCard({required this.check});

  @override
  Widget build(BuildContext context) {
    final passed = [
      check.oilLevel, check.coolantLevel, check.noEngineLeaks,
      check.tyrePressure, check.tyreCondition, check.wheelNuts,
      check.brakeResponse, check.airPressure,
      check.headlights, check.indicators, check.brakeLights,
      check.fireExtinguisher, check.reflectiveTriangles, check.seatbelt,
    ].where((b) => b).length;
    const total = 14;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: check.statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            check.overallStatus == 'pass' ? Icons.check_circle_outline
              : check.overallStatus == 'critical' ? Icons.error_outline
              : Icons.warning_amber_rounded,
            color: check.statusColor, size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(check.checkDate,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text('Horse #${check.horseId}  ·  $passed/$total items passed',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          if (check.notes != null && check.notes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(check.notes!,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: check.statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(check.statusLabel,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: check.statusColor)),
        ),
      ]),
    );
  }
}
