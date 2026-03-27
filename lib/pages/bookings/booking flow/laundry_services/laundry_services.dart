import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services_date_time.dart'
    show LaundryServicestDateScreen;
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/location_picker.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

import 'service_review.dart' show PickedLocationResult;

class LaundryServicesScreen extends StatefulWidget {
  final String? serviceType;

  const LaundryServicesScreen({super.key, this.serviceType});

  @override
  State<LaundryServicesScreen> createState() => _LaundryServicesScreenState();
}

class _LaundryServicesScreenState extends State<LaundryServicesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String serviceType = 'none';
  int? duration;
  String? expandedService;
  Set<String> selectedAddOns = {};

  static const String washFold = ' Wash & Fold';
  static const String ironingPressing = ' Wash & Iron';

  static const double _lowSnap = 0.43;
  static const double _highSnap = 0.93;

  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  bool _isSheetHigh = false;
  bool _isSearchingLocations = false;
  String? _selectedPickupAddress;

  List<PlaceSuggestion> _predictions = [];

  @override
  void initState() {
    super.initState();

    final initialType = widget.serviceType;
    if (initialType != null && initialType.trim().isNotEmpty) {
      serviceType = initialType;
      duration = _durationForService(initialType);
      expandedService = initialType;
    }

    _sheetController.addListener(_sheetListener);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_sheetListener);
    _sheetController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _sheetListener() {
    if (!_sheetController.isAttached) return;

    final size = _sheetController.size;
    final isHighNow = size > ((_lowSnap + _highSnap) / 2);

    if (isHighNow != _isSheetHigh) {
      setState(() {
        _isSheetHigh = isHighNow;
      });
    }
  }

  Future<void> _toggleSheetSnap() async {
    if (!_sheetController.isAttached) return;

    final target = _isSheetHigh ? _lowSnap : _highSnap;

    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    if (target == _highSnap && mounted) {
      _locationFocusNode.requestFocus();
    } else {
      _locationFocusNode.unfocus();
    }
  }

  Future<void> _expandSheetHigh() async {
    if (!_sheetController.isAttached) return;

    await _sheetController.animateTo(
      _highSnap,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    if (mounted) {
      _locationFocusNode.requestFocus();
    }
  }

  bool get _canContinue =>
      serviceType != 'none' &&
      duration != null &&
      (_selectedPickupAddress?.trim().isNotEmpty ?? false);

  int? _durationForService(String type) {
    switch (type) {
      case washFold:
        return 30;
      case ironingPressing:
        return 120;
      default:
        return null;
    }
  }

  Future<void> _onSelect(String type) async {
    setState(() {
      serviceType = type;
      duration = _durationForService(type);
      expandedService = type;
    });

    await _expandSheetHigh();
  }

  void _goNext() {
    final selectedDuration = duration;

    if (!_canContinue || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and choose a pickup location.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LaundryServicestDateScreen(
          serviceType: serviceType,
          duration: selectedDuration,
          addOns: selectedAddOns,
        ),
      ),
    );
  }

  Future<void> _searchPlaces(String input) async {
    final query = input.trim();

    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocations = true;
    });

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&key=$_googleApiKey'
        '&components=country:gh',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Places request failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = (data['predictions'] as List<dynamic>? ?? [])
          .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _predictions = predictions;
        _isSearchingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch locations. Check your API key.'),
        ),
      );
    }
  }

  void _selectPrediction(PlaceSuggestion place) {
    setState(() {
      _selectedPickupAddress = place.description;
      _locationController.text = place.description;
      _predictions = [];
    });

    _locationFocusNode.unfocus();
  }

  Future<void> _openMapPicker() async {
    if (_sheetController.isAttached) {
      await _sheetController.animateTo(
        _lowSnap,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }

    if (mounted) {
      setState(() {
        _isSheetHigh = false;
      });
    }

    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(builder: (_) => const GoogleMapLocationPickerScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _selectedPickupAddress = result.addressLine;
        _locationController.text = result.addressLine;
        _predictions = [];
      });
    }
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        53,
                        27,
                        36,
                      ).withOpacity(0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _locationController,
                  focusNode: _locationFocusNode,
                  onChanged: _searchPlaces,
                  decoration: InputDecoration(
                    hintText: 'Pickup location',
                    prefixIcon: Transform.scale(
                      scale: 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36C9A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.moped,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                    suffixIcon: _isSearchingLocations
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_locationController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _locationController.clear();
                                    setState(() {
                                      _selectedPickupAddress = null;
                                      _predictions = [];
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFF4F8),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _openMapPicker,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 233, 233, 233),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          53,
                          27,
                          36,
                        ).withOpacity(0.18),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Center(child: CustomText(text: 'Map', textSize: 14)),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1C9D8)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _predictions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFE36C9A),
                  ),
                  title: Text(
                    place.mainText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    place.secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPrediction(place),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 260),
      ],
    );
  }

  Widget _buildLowStateContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ServiceMiniChip(
              icon: Icons.local_laundry_service,
              title: 'Washing',
              subtitle: '35 min',
              titleColor: const Color(0xFFE36C9A),
              subtitleColor: Colors.black,
              iconColor: Colors.white,
              iconCircleColor: const Color(0xFFE36C9A),
              backgroundColor: const Color.fromARGB(189, 246, 220, 229),
            ),
            ServiceMiniChip(
              icon: Icons.dry_cleaning,
              title: 'Drying',
              subtitle: '35 min',
              titleColor: const Color(0xFFE36C9A),
              subtitleColor: Colors.black,
              iconColor: Colors.white,
              iconCircleColor: const Color(0xFFE36C9A),
              backgroundColor: const Color.fromARGB(189, 246, 220, 229),
            ),
            ServiceMiniChip(
              icon: Icons.iron,
              title: 'Ironing',
              subtitle: '35 min',
              titleColor: const Color(0xFFE36C9A),
              subtitleColor: Colors.black,
              iconColor: Colors.white,
              iconCircleColor: const Color(0xFFE36C9A),
              backgroundColor: const Color.fromARGB(189, 246, 220, 229),
            ),
          ],
        ),
        const SizedBox(height: 15),
        PromoImageCarousel(
          imagePaths: const [
            'assets/images/promo_banner.png',
            'assets/images/promo_banner_inverse.png',
          ],
          height: 120,
          onTap: (index) {
            debugPrint('Tapped banner $index');
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: ServiceButtonExpanded2(
                textWidget1: washFold,
                textWidget2: 'Washed, dried & neatly folded',
                textWidget3: '⏱️ 30 min',
                serviceItems: const [
                  'Sorted by color',
                  'Premium detergent',
                  'Folded & packaged',
                ],
                addOns: const [
                  'Express/Delivery',
                  'Scent Booster',
                  'Separate Wash',
                ],
                isSelected: serviceType == washFold,
                isExpanded: expandedService == washFold,
                onTap: () => _onSelect(washFold),
                selectedAddOns: selectedAddOns,
                onAddOnToggle: (_) {},
                deepColor: const Color(0xFFE36C9A),
                backgroundColor: const Color.fromARGB(189, 246, 220, 229),
                boxShadowColor: const Color.fromARGB(255, 207, 181, 202),
                image: Image.asset(
                  'assets/images/wash_fold.png',
                  height: 120,
                  width: 140,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ServiceButtonExpanded2(
                textWidget1: ironingPressing,
                textWidget2: 'Crisp, wrinkle-free',
                textWidget3: '⏱️ 120 min',
                serviceItems: const [
                  'Steam pressed',
                  'Hung on hangers',
                  'Express available',
                ],
                addOns: const ['Express/Delivery', 'Starch Treatment'],
                isSelected: serviceType == ironingPressing,
                isExpanded: expandedService == ironingPressing,
                onTap: () => _onSelect(ironingPressing),
                selectedAddOns: selectedAddOns,
                onAddOnToggle: (_) {},
                deepColor: const Color(0xFFE36C9A),
                backgroundColor: const Color.fromARGB(189, 246, 220, 229),
                boxShadowColor: const Color.fromARGB(255, 207, 181, 202),
                image: Image.asset(
                  'assets/images/wash_iron.png',
                  height: 120,
                  width: 140,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  bool _shouldExit = false;

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exit App',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to close the app?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "No",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Yes",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              // fontSize: FontSizes.ml,
              // color: lightPurple,
            ),
          ),
        ],
      ),
    );

    setState(() {
      _shouldExit = result ?? false;
    });

    if (_shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) {
        if (!didPop) {
          _showExitDialog();
        }
      },

      child: Scaffold(
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: false,
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: const Drawer(
            //margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: ProfileScreen(),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/laundry_backdrop.png',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.18)),
                ],
              ),
            ),
            Positioned(
              top: topInset + 40,
              right: 0,
              left: 0,
              child: Center(
                child: Column(
                  children: [CustomText(text: 'Divin Tassel Academy')],
                ),
              ),
            ),
            Positioned(
              top: topInset + 40,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF9FB),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.sort,
                    color: Color.fromARGB(255, 0, 0, 0),
                    size: 25,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 150,
              left: 16,
              right: 16,
              child: SearchEventsBar(onTap: _toggleSheetSnap),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 220,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(15),
                color: Color(0xFFFFF9FB),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationResultTile(
                        title: 'Accra Mall, Accra Mall, Middle Gate',
                        subtitle: 'City of Accra, Greater Accra Region',
                        trailingText: '40 min',
                        serviceType: 'wash_fold',
                        onTap: () {},
                      ),
                      LocationResultTile(
                        title: 'Achimota Mall',
                        subtitle:
                            'Greater Accra Region...East Municipal, Taifa',
                        trailingText: '17 min',
                        showDivider: false,
                        serviceType: 'wash_iron',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _lowSnap,
              minChildSize: _lowSnap,
              maxChildSize: _highSnap,
              snap: true,
              snapSizes: const [_lowSnap, _highSnap],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 247, 249, 1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      _isSheetHigh
                          ? Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.4,
                                    child: Lottie.asset(
                                      'assets/animations/washing_machine_icon.json',
                                      width: 420,
                                      height: 420,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                      CustomScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _toggleSheetSnap,
                                  child: Lottie.asset(
                                    'assets/animations/breathing_pill.json',
                                    width: 50,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            sliver: SliverToBoxAdapter(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _isSheetHigh
                                    ? Container(
                                        key: const ValueKey('searchOnly'),
                                        child: _buildSearchSection(),
                                      )
                                    : Container(
                                        key: const ValueKey('serviceSelection'),
                                        child: _buildLowStateContent(),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlaceSuggestion(
      description: (json['description'] ?? '') as String,
      mainText: (formatting['main_text'] ?? '') as String,
      secondaryText: (formatting['secondary_text'] ?? '') as String,
    );
  }
}

class ServiceMiniChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconCircleColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const ServiceMiniChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.backgroundColor = const Color(0xFF1F1F1F),
    this.iconCircleColor = const Color(0xFFD7EA6A),
    this.iconColor = const Color(0xFF4A4A2A),
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xFFB9B9B9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 18, bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 207, 181, 202),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconCircleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchEventsBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const SearchEventsBar({
    super.key,
    this.hintText = 'Pickup location...',
    this.controller,
    this.onFilterTap,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Color(0xFFFFF9FB),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(255, 95, 77, 92),
              blurRadius: 25,
              spreadRadius: 1,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/moped_full.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),

            Expanded(child: Row(children: [Text('Pickup location...')])),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: onFilterTap,
              child: const Icon(
                Icons.tune,
                color: Color.fromARGB(255, 227, 75, 133),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoImageCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration autoPlayDuration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onTap;

  const PromoImageCarousel({
    super.key,
    required this.imagePaths,
    this.height = 180,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.onTap,
  });

  @override
  State<PromoImageCarousel> createState() => _PromoImageCarouselState();
}

class _PromoImageCarouselState extends State<PromoImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.imagePaths.length <= 1) return;

    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!_pageController.hasClients) return;

      int nextPage = _currentIndex + 1;
      if (nextPage >= widget.imagePaths.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(22);

    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      /* boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ], */
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Image.asset(
                        widget.imagePaths[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imagePaths.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFFE36C9A)
                    : const Color(0xFFD8C5CD),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LocationResultTile extends StatelessWidget {
  final String title;
  final String serviceType;
  final String subtitle;
  final String trailingText;
  final VoidCallback? onTap;
  final bool showDivider;
  final IconData icon;

  const LocationResultTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    this.onTap,
    this.showDivider = true,
    this.icon = Icons.location_on_outlined,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          splashColor: const Color.fromARGB(15, 227, 108, 154),
          highlightColor: const Color.fromARGB(15, 227, 108, 154),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 197, 220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Transform.scale(
                    scale: serviceType == 'wash_fold' ? 0.7 : 0.85,
                    child: Image.asset(
                      serviceType == 'wash_fold'
                          ? 'assets/images/machine.png'
                          : 'assets/images/machine_iron.png',
                      height: 70,
                      width: 70,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 86, right: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
          ),
      ],
    );
  }
}
