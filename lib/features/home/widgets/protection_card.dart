import 'package:flutter/material.dart';
import '../../../models/app_models.dart';
import '../../../core/theme/app_theme.dart';

class ProtectionCard extends StatefulWidget {
  final ProtectionState state;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback? onCancel;

  const ProtectionCard({
    super.key,
    required this.state,
    required this.onActivate,
    required this.onDeactivate,
    this.onCancel,
  });

  @override
  State<ProtectionCard> createState() => _ProtectionCardState();
}

class _ProtectionCardState extends State<ProtectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == ProtectionState.protected;
    final isArming = widget.state == ProtectionState.arming;
    final isAlarming = widget.state == ProtectionState.alarmActive ||
        widget.state == ProtectionState.pinRequired ||
        widget.state == ProtectionState.motionDetected;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: FadeTransition(
        opacity: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Phone Protection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(state: widget.state),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status indicator
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.greenAccent[700]
                              : isAlarming
                                  ? Colors.red
                                  : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isArming
                              ? '⏳ Arming in progress...'
                              : isActive
                                  ? '🛡 Protection is ACTIVE'
                                  : isAlarming
                                      ? '🚨 ALARM TRIGGERED!'
                                      : '⚠ Protection is OFF',
                          key: ValueKey(widget.state),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? Colors.green[700]
                                : isAlarming
                                    ? Colors.red
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isArming
                          ? _ArmingButton(
                              key: const ValueKey('arming'),
                              onCancel: widget.onCancel ?? widget.onDeactivate,
                            )
                          : isActive || isAlarming
                              ? _DeactivateButton(
                                  key: const ValueKey('deactivate'),
                                  onTap: widget.onDeactivate,
                                  isAlarming: isAlarming,
                                )
                              : _ActivateButton(
                                  key: const ValueKey('activate'),
                                  onTap: widget.onActivate,
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProtectionState state;

  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final isActive = state == ProtectionState.protected;
    final isAlarming = state == ProtectionState.alarmActive ||
        state == ProtectionState.pinRequired ||
        state == ProtectionState.motionDetected;

    Color bg;
    Color text;
    String label;

    if (isActive) {
      bg = Colors.green[50]!;
      text = Colors.green[700]!;
      label = 'Active';
    } else if (isAlarming) {
      bg = Colors.red[50]!;
      text = Colors.red;
      label = 'ALARM';
    } else {
      bg = Colors.grey[100]!;
      text = Colors.grey[600]!;
      label = 'Inactive';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ActivateButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.security_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'ACTIVATE PROTECTION',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _DeactivateButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isAlarming;

  const _DeactivateButton({
    super.key,
    required this.onTap,
    required this.isAlarming,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isAlarming ? Colors.red : Colors.grey[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stop_circle_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            isAlarming ? 'STOP ALARM' : 'DEACTIVATE',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ArmingButton extends StatelessWidget {
  final VoidCallback onCancel;

  const _ArmingButton({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onCancel,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'ARMING... TAP TO CANCEL',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
