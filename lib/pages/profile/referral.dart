import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ReferAndEarnPage extends StatelessWidget {
  const ReferAndEarnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: const [
            SliverToBoxAdapter(child: _HeaderSection()),
            SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _StatsRow()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _HowItWorksSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _RecentReferralsSection()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          "Referral code copied",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.scrim,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refer & Earn',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Share the love, earn rewards',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Spacer(),
              GoBack(onPressed: () => Navigator.pop(context)),

              const SizedBox(width: 12),
            ],
          ),

          // Referral code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Referral Code',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SARAH2024',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _CircleIconButton(
                      icon: Icons.copy_rounded,
                      background: Colors.white,
                      iconColor: Colors.black87,
                      onTap: () {
                        copyToClipboard(context, "SARAH2024");
                      },
                    ),
                    SizedBox(height: 16),
                    _CircleIconButton(
                      icon: Icons.share_outlined,
                      background: Colors.white,
                      iconColor: Colors.black87,
                      onTap: () {
                        //Func
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Expanded(
            child: _StatCard(
              icon: Icons.group_outlined,
              iconColor: Color(0xFF4F46E5),
              label: 'Friends Invited',
              value: '12',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.attach_money_rounded,
              iconColor: Color(0xFF9333EA),
              label: 'Rewards Earned',
              value: '600 Pts',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.card_giftcard_outlined,
              iconColor: Color(0xFFFBBF24),
              label: 'Pending',
              value: '3',
            ),
          ),
        ],
      ),
    );
  }
}

// class _ShareCodeSection extends StatelessWidget {
//   const _ShareCodeSection();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Share Your Code',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: const [
//               Expanded(
//                 child: _ShareCard(
//                   icon: Icons.message_outlined,
//                   label: 'Message',
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _ShareCard(icon: Icons.email_outlined, label: 'Email'),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _ShareCard(icon: Icons.share_outlined, label: 'More'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.scrim,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 6),
                _HowItWorksStep(
                  number: '1',
                  title: 'Share your code',
                  subtitle:
                      'Send your unique referral code to friends and family.',
                ),
                SizedBox(height: 12),
                _HowItWorksStep(
                  number: '2',
                  title: 'They get \$10 off',
                  subtitle: 'Your friend saves \$10 on their first wash.',
                ),
                SizedBox(height: 12),
                _HowItWorksStep(
                  number: '3',
                  title: 'You earn rewards',
                  subtitle:
                      'Get up to \$10 credit for each successful referral.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReferralsSection extends StatelessWidget {
  const _RecentReferralsSection();

  @override
  Widget build(BuildContext context) {
    final referrals = [
      const _Referral(
        initials: 'MC',
        name: 'Mike Chen',
        dateLabel: '2 days ago',
        amount: '\$5',
        status: 'Completed',
        statusColor: Colors.greenAccent,
      ),
      const _Referral(
        initials: 'EW',
        name: 'Emma Wilson',
        dateLabel: '5 days ago',
        amount: '\$5',
        status: 'Pending',
        statusColor: Color(0xFFFACC15),
      ),
      const _Referral(
        initials: 'AK',
        name: 'Alex Kim',
        dateLabel: '1 week ago',
        amount: '\$5',
        status: 'Completed',
        statusColor: Colors.greenAccent,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Referrals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.scrim,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: referrals
                  .map(
                    (r) => Column(
                      children: [
                        _ReferralTile(referral: r),
                        if (r != referrals.last)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----- Small widgets & models ----- */

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    this.onTap,
    this.background = const Color(0x331F2937),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 24, color: iconColor),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.scrim,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// class _ShareCard extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _ShareCard({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(18),
//       onTap: () {},
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.scrim,
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 22,
//               color: Theme.of(context).colorScheme.inversePrimary,
//             ),
//             const SizedBox(height: 6),
//             Text(label, style: const TextStyle(fontSize: 13)),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4F46E5).withOpacity(0.25),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Referral {
  final String initials;
  final String name;
  final String dateLabel;
  final String amount;
  final String status;
  final Color statusColor;

  const _Referral({
    required this.initials,
    required this.name,
    required this.dateLabel,
    required this.amount,
    required this.status,
    required this.statusColor,
  });
}

class _ReferralTile extends StatelessWidget {
  final _Referral referral;

  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Text(
          referral.initials,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      title: Text(
        referral.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        referral.dateLabel,
        style: const TextStyle(fontSize: 12, color: Colors.white60),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            referral.amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            referral.status,
            style: TextStyle(fontSize: 11, color: referral.statusColor),
          ),
        ],
      ),
    );
  }
}
