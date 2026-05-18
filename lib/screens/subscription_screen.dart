import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to PRO')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose your plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock high quality downloads and support the project.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            
            ...SubscriptionPlan.plans.map((plan) => _PlanCard(
              plan: plan,
              isDark: isDark,
              primary: primary,
              onTap: () async {
                final auth = context.read<AuthProvider>();
                await auth.upgradeToPro();
                if (context.mounted) Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(plan.price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primary)),
            ],
          ),
          Text(plan.duration, style: TextStyle(color: isDark ? const Color(0xFF8A8AAA) : Colors.grey)),
          const Divider(height: 32),
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: primary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
