import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../services/traffic_fine_service.dart';
import '../../../models/officer_model.dart';
import '../../../core/storage/token_storage.dart';

class ShiftStatusCard extends StatefulWidget {
  const ShiftStatusCard({super.key});

  @override
  State<ShiftStatusCard> createState() => _ShiftStatusCardState();
}

class _ShiftStatusCardState extends State<ShiftStatusCard> {
  final _tokenStorage = const TokenStorage();
  final _fineService = TrafficFineService();

  bool _isLoading = true;
  OfficerModel? _officer;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  Future<void> _loadShiftData() async {
    setState(() => _isLoading = true);

    try {
      final session = await _tokenStorage.getSession();
      if (session == null) {
        setState(() {
          _error = 'No session found';
          _isLoading = false;
        });
        return;
      }

      // TODO: Implement getOfficerProfile with shifts
      // For now, create a placeholder
      setState(() {
        _officer = OfficerModel(
          id: session.officerId,
          name: session.officerName,
          email: '',
          badgeNumber: session.officerBadgeNumber,
          status: 'OFF_DUTY',
          role: session.role,
          divisionId: session.districtId,
          currentShift: null,
          shifts: const [],
        );
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load shift data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerCard();
    }

    if (_error.isNotEmpty) {
      return _buildErrorCard();
    }

    final shift = _officer?.activeShift;
    final hasShift = shift != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryBlack.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasShift
                  ? AppTheme.successGreen.withValues(alpha: 0.12)
                  : AppTheme.textGray.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasShift ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
              color: hasShift ? AppTheme.successGreen : AppTheme.textGray,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasShift ? 'Active Shift' : 'No Active Shift',
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasShift
                      ? '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}'
                      : 'You are not assigned to any active shift',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasShift && shift.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${shift.location}',
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryBlack.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorRed,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Unable to load shift information',
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    final local = time.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}