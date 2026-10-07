import 'package:flutter/material.dart';

class LundriUserDataScreen extends StatelessWidget {
  const LundriUserDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = lundriUserDataPages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(title: 'User data'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: pages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _DocumentPageCard(
                    pageNumber: index + 1,
                    totalPages: pages.length,
                    page: pages[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 28,
                  color: Colors.black,
                ),
              ),
            ),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPageCard extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final LundriUserDataPage page;

  const _DocumentPageCard({
    required this.pageNumber,
    required this.totalPages,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 92,
            color: Colors.white,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 22, top: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$pageNumber of $totalPages',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.showBrand)
                  Container(
                    padding: EdgeInsets.all(5),
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/lundri_logo_transparent_small.png',
                    ),
                  ),
                if (page.heroTitle != null) ...[
                  Text(
                    page.heroTitle!,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (page.platformChips.isNotEmpty) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: page.platformChips
                        .map(
                          (chip) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            color: const Color(0xFFF4C8D8),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF313131),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (page.introText != null) ...[
                  Text(
                    page.introText!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Color(0xFF3F3F3F),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ...page.blocks.map((block) => _PageBlock(block: block)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBlock extends StatelessWidget {
  final LundriPageBlock block;
  const _PageBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final stacked = screenWidth < 700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: const Color(0xFFF6F6F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.title != null) ...[
              Text(
                block.title!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (block.imageAsset != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  block.imageAsset!,
                  width: double.infinity,
                  height: stacked ? 180 : 240,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (block.highlightNote != null) ...[
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E7B8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  block.highlightNote!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoColumn(
                        title: block.leftTitle,
                        text: block.leftText,
                        accent: block.leftAccent,
                      ),
                      const SizedBox(height: 22),
                      _InfoColumn(
                        title: block.middleTitle,
                        text: block.middleText,
                      ),
                      const SizedBox(height: 22),
                      _InfoColumn(
                        title: block.rightTitle,
                        text: block.rightText,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoColumn(
                          title: block.leftTitle,
                          text: block.leftText,
                          accent: block.leftAccent,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _InfoColumn(
                          title: block.middleTitle,
                          text: block.middleText,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _InfoColumn(
                          title: block.rightTitle,
                          text: block.rightText,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String text;
  final bool accent;

  const _InfoColumn({
    required this.title,
    required this.text,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: accent ? 18 : 16,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: accent ? const Color(0xFF2E92D0) : const Color(0xFF2F2F2F),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.7,
            color: Color(0xFF3C3C3C),
          ),
        ),
      ],
    );
  }
}

class LundriUserDataPage {
  final bool showBrand;
  final String? heroTitle;
  final List<String> platformChips;
  final String? introText;
  final List<LundriPageBlock> blocks;

  const LundriUserDataPage({
    this.showBrand = false,
    this.heroTitle,
    this.platformChips = const [],
    this.introText,
    this.blocks = const [],
  });
}

class LundriPageBlock {
  final String? title;
  final String leftTitle;
  final String leftText;
  final bool leftAccent;
  final String middleTitle;
  final String middleText;
  final String rightTitle;
  final String rightText;
  final String? imageAsset;
  final String? highlightNote;

  const LundriPageBlock({
    this.title,
    required this.leftTitle,
    required this.leftText,
    this.leftAccent = false,
    required this.middleTitle,
    required this.middleText,
    required this.rightTitle,
    required this.rightText,
    this.imageAsset,
    this.highlightNote,
  });
}

const List<LundriUserDataPage> lundriUserDataPages = [
  LundriUserDataPage(
    showBrand: true,
    heroTitle: 'Why does our app need access to some features of your device?',
    platformChips: ['Android', 'iOS'],
    blocks: [],
  ),

  LundriUserDataPage(
    introText:
        'Lundri may ask for access to some features on your device so we can provide laundry pickup, delivery tracking, rider communication, secure payments, and smoother order updates.\n\n'
        'We only ask for permissions that improve the service experience. You can refuse most permissions and still use the app, though some features may work in a limited way.',
    blocks: [
      LundriPageBlock(
        title: 'Camera',
        leftTitle: 'Camera',
        leftAccent: true,
        leftText:
            'Take photos of your clothes, stains, receipts, or special handling instructions before pickup.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'The camera helps you attach clear images to your order so riders and laundry partners know exactly what to expect. This reduces mistakes, missing items, and disputes.',
        rightTitle: 'How to turn it off',
        rightText:
            'Settings → Apps → Lundri → Permissions → Camera\n\n'
            'or\n\n'
            'Settings → Privacy → Camera → Lundri',
        imageAsset: 'assets/images/camera.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Pickup Scheduling',
        leftTitle: 'Pickup scheduling',
        leftAccent: true,
        leftText: 'Choose a pickup day and time for your laundry order.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri uses your selected schedule to assign a rider, notify the laundry partner, and prepare your order for pickup at the right time.',
        rightTitle: 'How to manage it',
        rightText:
            'You can change your selected date and time before pickup begins from your order details screen.',
        imageAsset: 'assets/images/pickup_sheduling.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Location',
        leftTitle: 'Location',
        leftAccent: true,
        leftText:
            'Access GPS and network-based location to detect pickup and delivery addresses.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri uses your location to suggest addresses, estimate arrival times, help the rider find you, and match you with nearby laundry partners. If you deny location access, you can still enter your address manually.',
        rightTitle: 'How to turn it off',
        rightText:
            'Settings → Apps → Lundri → Permissions → Location\n\n'
            'or\n\n'
            'Settings → Privacy → Location Services → Lundri',
        imageAsset: 'assets/images/location.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Microphone',
        leftTitle: 'Microphone',
        leftAccent: true,
        leftText:
            'Use voice notes or speech input for pickup notes, washing instructions, or rider communication.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'In some cases it is easier to describe stains, delivery directions, or special handling instructions by voice. If you do not allow microphone access, you can still type these instructions.',
        rightTitle: 'How to turn it off',
        rightText:
            'Settings → Apps → Lundri → Permissions → Microphone\n\n'
            'or\n\n'
            'Settings → Privacy → Microphone → Lundri',
        imageAsset: 'assets/images/microphone.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Live Tracking',
        leftTitle: 'Live tracking',
        leftAccent: true,
        leftText: 'Track pickup and delivery progress in real time.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri uses live tracking to show rider movement, estimated arrival times, and order progress between your location and the assigned laundry partner.',
        rightTitle: 'How to manage it',
        rightText:
            'Live tracking depends on location access and internet connection. You can stop sharing location by turning off location permission for Lundri.',
        imageAsset: 'assets/images/live_tracking.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Notifications',
        leftTitle: 'Notifications',
        leftAccent: true,
        leftText:
            'Receive alerts for order confirmation, rider arrival, washing progress, payment requests, and delivery updates.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Notifications keep you informed when your order has been accepted, when pickup is near, when your clothes are ready, and when payment is needed before delivery.',
        rightTitle: 'How to turn it off',
        rightText: 'Settings → Notifications → Lundri',
        imageAsset: 'assets/images/notifications_updates_illustration.png',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Payment',
        leftTitle: 'Payment',
        leftAccent: true,
        leftText:
            'Pay securely for laundry services and delivery inside the app.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Payment details are used only to process transactions, confirm successful payment, and keep your order moving into the delivery stage.',
        rightTitle: 'How to manage it',
        rightText:
            'You can remove or update saved payment methods from the payment methods section in the app.',
        imageAsset: 'assets/images/payment.png',
        highlightNote:
            'If you connect a card or payment method to Lundri, payment information should be processed securely through the payment provider. Store only what is necessary for faster checkout and receipts.',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Phone',
        leftTitle: 'Phone',
        leftAccent: true,
        leftText:
            'Call riders or laundry partners directly from the app when needed.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'This helps you contact the assigned rider or laundry partner quickly if pickup is delayed, the address is hard to find, or there is a delivery issue.',
        rightTitle: 'How to turn it off',
        rightText: 'Settings → Apps → Lundri → Permissions → Phone',
      ),
      LundriPageBlock(
        title: 'Photos & Storage',
        leftTitle: 'Photos & Storage',
        leftAccent: true,
        leftText:
            'Upload clothing photos, issue evidence, receipts, and profile images.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri may save selected images temporarily so they load faster during claims, order review, or support conversations.',
        rightTitle: 'How to turn it off',
        rightText:
            'Settings → Apps → Lundri → Permissions → Photos and videos\n\n'
            'or\n\n'
            'Settings → Privacy → Photos → Lundri',
      ),
      LundriPageBlock(
        title: 'Contacts',
        leftTitle: 'Contacts',
        leftAccent: true,
        leftText:
            'Choose another recipient for pickup or delivery, or send a referral more easily.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'If you want someone else to receive the order or want to refer a friend, contact access can make that process faster. You can still type the person’s details manually.',
        rightTitle: 'How to turn it off',
        rightText:
            'Settings → Apps → Lundri → Permissions → Contacts\n\n'
            'or\n\n'
            'Settings → Privacy → Contacts → Lundri',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Messages & Verification',
        leftTitle: 'SMS verification',
        leftAccent: true,
        leftText: 'Used during sign-up or login verification.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri may use one-time verification codes to confirm your phone number and protect your account.',
        rightTitle: 'How to turn it off',
        rightText:
            'This depends on your device and OS version. You can still use manual code entry if auto-read is not available.',
      ),
      LundriPageBlock(
        title: 'Mobile Data',
        leftTitle: 'Mobile Data',
        leftAccent: true,
        leftText:
            'Use internet access for live order updates, chat, payment, and tracking.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri needs internet access to update order status, send notifications, load map routes, process payments, and sync support messages.',
        rightTitle: 'How to turn it off',
        rightText: 'Settings → Mobile Data → Lundri',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Background App Refresh',
        leftTitle: 'Background App Refresh',
        leftAccent: true,
        leftText:
            'Keep order progress and rider tracking updated while the app is not open.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'If Lundri stays active in the background, it can continue refreshing order status, rider location, estimated delivery times, and important alerts while you do other things on your phone.',
        rightTitle: 'How to turn it off',
        rightText: 'Settings → General → Background App Refresh → Lundri',
      ),
      LundriPageBlock(
        title: 'Data We Use',
        leftTitle: 'Basic account data',
        leftAccent: true,
        leftText: 'Name, phone number, email, addresses, and order history.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'This information is needed to create your account, assign riders, coordinate with laundry partners, send receipts, and help support resolve issues.',
        rightTitle: 'How to manage it',
        rightText:
            'You can edit most profile details inside the app settings and personal information screen.',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'Order Complete',
        leftTitle: 'Order complete',
        leftAccent: true,
        leftText:
            'Final confirmation that your laundry was cleaned and delivered successfully.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Lundri stores order completion details so you can review finished orders, check receipts, report problems, and build trust in the service.',
        rightTitle: 'How to manage it',
        rightText:
            'Completed orders remain visible in your order history. You can contact support if you need help with any completed order.',
        imageAsset: 'assets/images/order_complete.png',
      ),
      LundriPageBlock(
        title: 'Support Evidence',
        leftTitle: 'Issue photos and notes',
        leftAccent: true,
        leftText: 'Photos or notes you send when reporting a problem.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'This helps Lundri investigate damaged items, missing items, wrong pricing, or incomplete delivery claims.',
        rightTitle: 'How to manage it',
        rightText:
            'You can delete or request removal of support evidence through customer support where applicable.',
      ),
    ],
  ),

  LundriUserDataPage(
    blocks: [
      LundriPageBlock(
        title: 'How to Contact Us',
        leftTitle: 'Need help?',
        leftAccent: true,
        leftText:
            'If you have questions about how Lundri uses your data, contact support from the app.',
        middleTitle: 'Why it’s necessary',
        middleText:
            'Support can explain how permissions affect features like pickup tracking, notifications, address detection, payments, and photo uploads.',
        rightTitle: 'Where to find it',
        rightText:
            'Profile → Help\n'
            'Profile → Support\n'
            'Settings → User data',
      ),
    ],
  ),

  LundriUserDataPage(
    showBrand: true,
    blocks: [
      LundriPageBlock(
        title: 'Summary',
        leftTitle: 'What Lundri needs',
        leftAccent: true,
        leftText:
            'Only the permissions that improve pickup, tracking, payments, communication, and issue handling.',
        middleTitle: 'What remains optional',
        middleText:
            'Most permissions are optional. If you turn them off, you can usually still use the service, but some features may become slower or manual.',
        rightTitle: 'Your control',
        rightText:
            'You can manage permissions at any time from your phone settings and your Lundri app settings.',
      ),
    ],
  ),
];
