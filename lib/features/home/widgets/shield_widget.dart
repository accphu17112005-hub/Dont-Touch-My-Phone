import 'package:flutter/material.dart';
import '../../../models/app_models.dart';
import '../../../core/theme/app_theme.dart';

class ShieldWidget extends StatefulWidget {
  final ProtectionState state;

  const ShieldWidget({super.key, required this.state});

  @override
  State<ShieldWidget> createState() => _ShieldWidgetState();
}

class _ShieldWidgetState extends State<ShieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == ProtectionState.protected;
    final isAlarming = widget.state == ProtectionState.alarmActive ||
        widget.state == ProtectionState.motionDetected ||
        widget.state == ProtectionState.pinRequired;
    final isArming = widget.state == ProtectionState.arming;

    Color shieldColor = Colors.white.withOpacity(0.3);
    Color iconColor = Colors.white;
    IconData iconData = Icons.security_rounded;

    if (isActive) {
      shieldColor = Colors.greenAccent.withOpacity(0.2);
      iconColor = Colors.greenAccent;
      iconData = Icons.shield_rounded;
    } else if (isAlarming) {
      shieldColor = Colors.red.withOpacity(0.2);
      iconColor = Colors.red;
      iconData = Icons.warning_rounded;
    } else if (isArming) {
      shieldColor = Colors.orangeAccent.withOpacity(0.2);
      iconColor = Colors.orangeAccent;
      iconData = Icons.hourglass_top_rounded;
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.scale(
          scale: isActive || isAlarming ? _pulseAnim.value : 1.0,
          child: Transform.rotate(
            angle: isAlarming ? _rotateAnim.value : 0,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  if (isActive || isAlarming)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isAlarming ? Colors.red : Colors.greenAccent)
                                .withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  // Shield background
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: shieldColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(iconData, size: 60, color: iconColor),
                  ),
                  // Status badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.greenAccent
                            : isAlarming
                                ? Colors.red
                                : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive
                            ? Icons.check
                            : isAlarming
                                ? Icons.priority_high
                                : Icons.power_settings_new,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
