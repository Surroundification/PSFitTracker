import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.width,
    this.radius = 18,
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double radius;
  final bool raised;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        width: width,
        decoration: BoxDecoration(
          color: raised ? appSurfaceRaised : appSurface,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: appAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt, color: appBackground, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'PSFitTracker',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.offline_bolt_outlined, color: appMuted, size: 19),
          const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'PRIVATE & OFFLINE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: appAccent, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800)),
                Text(
                  label,
                  style: const TextStyle(
                    color: appMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: appMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, color: appAccent, size: 34),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: appMuted, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (action.isNotEmpty)
              TextButton(
                onPressed: onPressed,
                child: Text(action),
              ),
          ],
        ),
      );
}

void noOp() {}
