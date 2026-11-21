import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy, 
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The standalone logo, sized up
                    Image.asset(
                      'assets/logo.png',
                      height: 64, // You can now use a smaller height because there is no invisible padding
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft, // Aligns it perfectly with the text below it
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: ts(24, FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// White outlined pill on a navy background ("Log in" / "Log out").
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: ts(14, FontWeight.w600, color: Colors.white)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: const BorderSide(color: Colors.white, width: 2),
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Big filled button (Send report, Log in, I'll respond).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 18,
    this.radius = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Small colored pill that shows a ticket status.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.fontSize = 13});

  final TicketStatus status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case TicketStatus.reported:
        bg = AppColors.amberBg;
        fg = AppColors.amberFg;
        break;
      case TicketStatus.acknowledged:
      case TicketStatus.enRoute:
        bg = AppColors.purpleBg;
        fg = AppColors.purpleFg;
        break;
      case TicketStatus.resolved:
        bg = AppColors.greenBg;
        fg = AppColors.greenFg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status.label, style: ts(fontSize, FontWeight.w700, color: fg)),
    );
  }
}

/// Label on the left (90px), value on the right.
class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.rows, this.fontSize = 15});

  final Map<String, String> rows;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(e.key,
                      style: ts(fontSize, FontWeight.w400, color: AppColors.muted)),
                ),
                Expanded(
                  child: Text(e.value, style: ts(fontSize, FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
