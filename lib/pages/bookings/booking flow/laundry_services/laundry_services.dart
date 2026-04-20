import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, FieldValue, SetOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services_date_time.dart'
    show LaundryServicestDateScreen;
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/location_picker.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';
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

  static const String washFold = ' Wash & Fold  ';
  static const String ironingPressing = ' Wash & Iron  ';

  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

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
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
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

    await _showLocationSheet();
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

  Future<void> _showLocationSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _locationFocusNode.requestFocus();
          }
        });

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.91,
            minChildSize: 0.91,
            maxChildSize: 0.91,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(sheetContext).pop(),
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
                      padding: const EdgeInsets.fromLTRB(12, 50, 12, 24),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            key: const ValueKey('searchOnly'),
                            child: _buildSearchSection(sheetContext),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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

  void _selectPrediction(PlaceSuggestion place, {BuildContext? modalContext}) {
    setState(() {
      _selectedPickupAddress = place.description;
      _locationController.text = place.description;
      _predictions = [];
    });

    _locationFocusNode.unfocus();

    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }
  }

  Future<void> _openMapPicker({BuildContext? modalContext}) async {
    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }

    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(
        builder: (_) => GoogleMapLocationPickerScreen(serviceType: serviceType),
      ),
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

  Widget _buildSearchSection(BuildContext modalContext) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            child: Lottie.asset(
              'assets/animations/washing_machine_icon.json',
              width: 400,
              height: MediaQuery.of(context).size.height * 0.7,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(40, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        focusNode: _locationFocusNode,
                        onChanged: _searchPlaces,
                        decoration: InputDecoration(
                          hintText: 'Pickup location',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: Transform.scale(
                            scale: 0.60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(1),
                              child: const Icon(
                                Icons.moped,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          suffixIcon: _isSearchingLocations
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _openMapPicker(modalContext: modalContext),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(40, 0, 0, 0),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: Icon(Icons.map, color: Color(0xFFE67E22)),
                          ),
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
                        onTap: () => _selectPrediction(
                          place,
                          modalContext: modalContext,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
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
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Colors.white,
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: const Drawer(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: ProfileScreen(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Hello, ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Chris',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 188, 113, 0),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECDB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.sort,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                SearchEventsBar(
                  controller: _locationController,
                  onTap: _showLocationSheet,
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ServiceTile(
                      title: 'Wash & Fold',
                      imageAsset: 'assets/images/wash_foldd.png',
                      onTap: () => _onSelect(washFold),
                    ),
                    ServiceTile(
                      title: 'Wash & Iron',
                      imageAsset: 'assets/images/wash_ironn.png',
                      onTap: () => _onSelect(ironingPressing),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                PromoImageCarousel(
                  imagePaths: const [
                    'assets/images/promo_banner.png',
                    'assets/images/promo_banner_inverse.png',
                  ],
                  height: 140,
                  onTap: (index) {
                    debugPrint('Tapped banner $index');
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 10),

                LaundryCard(
                  name: 'Sparkle Wash',
                  imageUrl: 'https://example.com/laundry.jpg',
                  distanceKm: 2.4,
                  rating: 4.7,
                  availabilityStatus: 'available',
                  isOpenNow: true,
                  supportedServices: const ['wash_fold', 'wash_iron'],
                  basePricePerKg: 18,
                  washIronExtraPerKg: 2,
                  turnaroundText: 'Same day',
                  onTap: () {},
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await seedBookingsDummy();
                  },
                  child: const Text('press me'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
            color: const Color.fromARGB(255, 255, 255, 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 35,
            height: 35,
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
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
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
    final text = controller?.text.trim() ?? '';
    final hasValue = text.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(50, 230, 125, 34),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.moped, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? text : hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? Colors.black : Colors.black54,
                ),
              ),
            ),
            const Icon(Icons.search, size: 25, color: Color(0xFFE67E22)),
          ],
        ),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback? onTap;

  const ServiceTile({
    super.key,
    required this.title,
    required this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F1F1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                  height: 1.2,
                ),
              ),
            ],
          ),
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
                    decoration: BoxDecoration(borderRadius: radius),
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
                    ? const Color.fromARGB(255, 227, 166, 108)
                    : const Color.fromARGB(255, 216, 207, 197),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LaundryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double distanceKm;
  final double? rating;
  final String availabilityStatus;
  final bool isOpenNow;
  final List<String> supportedServices;
  final int basePricePerKg;
  final int washIronExtraPerKg;
  final String turnaroundText;
  final VoidCallback? onTap;

  const LaundryCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    required this.rating,
    required this.availabilityStatus,
    required this.isOpenNow,
    required this.supportedServices,
    required this.basePricePerKg,
    required this.washIronExtraPerKg,
    required this.turnaroundText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData(availabilityStatus, isOpenNow);

    final darkOrange = const Color(0xFFE67E22);
    final softOrange = const Color(0xFFFFECDB);
    final white = Colors.white;
    final black = Colors.black;
    final borderColor = const Color(0xFFEAEAEA);
    final subtitleColor = Colors.black54;
    final closedColor = Colors.black45;
    final shadowColor = Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.trim().isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: softOrange,
                              child: Icon(
                                Icons.local_laundry_service_outlined,
                                size: 40,
                                color: darkOrange,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: softOrange,
                          child: Icon(
                            Icons.local_laundry_service_outlined,
                            size: 40,
                            color: darkOrange,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _StatusBadge(
                      label: status.label,
                      textColor: status.textColor,
                      bgColor: status.bgColor,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: supportedServices
                            .map(
                              (service) => _ServiceChip(
                                label: _serviceLabel(service),
                                bgColor: softOrange,
                                textColor: darkOrange,
                              ),
                            )
                            .toList(),
                      ),
                      _MetaItem(
                        title: 'From',
                        value: 'GH₵$basePricePerKg/kg',
                        titleColor: subtitleColor,
                        valueColor: black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isOpenNow ? 'Open now' : 'Currently closed',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isOpenNow ? darkOrange : closedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: darkOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating == null || rating == 0
                                      ? 'New'
                                      : rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusData _statusData(String availabilityStatus, bool isOpenNow) {
    if (!isOpenNow) {
      return const _StatusData(
        label: 'Closed',
        textColor: Color(0xFF6D6D6D),
        bgColor: Color(0xFFEEEEEE),
      );
    }

    switch (availabilityStatus.toLowerCase()) {
      case 'available':
        return const _StatusData(
          label: 'Available',
          textColor: Color(0xFFE67E22),
          bgColor: Color(0xFFFFE8D6),
        );
      case 'busy':
        return const _StatusData(
          label: 'Busy',
          textColor: Colors.black,
          bgColor: Color(0xFFFFD6A5),
        );
      default:
        return const _StatusData(
          label: 'Offline',
          textColor: Color(0xFF6D6D6D),
          bgColor: Color(0xFFEEEEEE),
        );
    }
  }

  String _serviceLabel(String key) {
    switch (key) {
      case 'wash_fold':
        return 'Wash & Fold';
      case 'wash_iron':
        return 'Wash & Iron';
      default:
        return key;
    }
  }
}

class _StatusData {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusData({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _ServiceChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _MetaItem({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> seedNearbyLaundriesDummy() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final now = FieldValue.serverTimestamp();

  final laundries = <Map<String, dynamic>>[
    {
      'id': 'quick_wash_east_legon',
      'ownerUid': '',
      'name': 'Quick Wash Laundry East Legon',
      'description': 'Laundry and dry cleaning service in East Legon.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '+233502774789',
      'email': '',
      'addressLine':
          'Nii Osae Ntiful Avenue, Otinshie, East Legon, Accra, Ghana',
      'latitude': 5.6408,
      'longitude': -0.1492,
      'serviceRadiusKm': 8,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'rating': 4.6,
      'totalReviews': 32,
      'estimatedTurnaroundText': 'Same day',
      'availabilityStatus': 'available',
      'isOpenNow': true,
      'acceptingOrders': true,
      'isApproved': true,
      'isFeatured': false,
      'currentOrderCount': 2,
      'maxConcurrentOrders': 10,
      'openingHours': {
        'monday': {'open': '08:00', 'close': '20:00'},
        'tuesday': {'open': '08:00', 'close': '20:00'},
        'wednesday': {'open': '08:00', 'close': '20:00'},
        'thursday': {'open': '08:00', 'close': '20:00'},
        'friday': {'open': '08:00', 'close': '20:00'},
        'saturday': {'open': '09:00', 'close': '18:00'},
        'sunday': {'open': '09:00', 'close': '16:00'},
      },
      'stats': {
        'totalOrders': 140,
        'completedOrders': 132,
        'cancelledOrders': 8,
      },
    },
    {
      'id': 'laundry_chief_east_legon_shop',
      'ownerUid': '',
      'name': 'Laundry Chief - East Legon Shop',
      'description': 'Pickup and delivery laundry and dry cleaning.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '',
      'email': '',
      'addressLine': '19 Boundary Road, East Legon, Accra, Ghana',
      'latitude': 5.6396,
      'longitude': -0.1468,
      'serviceRadiusKm': 8,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'rating': 4.4,
      'totalReviews': 21,
      'estimatedTurnaroundText': 'Same day',
      'availabilityStatus': 'available',
      'isOpenNow': true,
      'acceptingOrders': true,
      'isApproved': true,
      'isFeatured': true,
      'currentOrderCount': 3,
      'maxConcurrentOrders': 12,
      'openingHours': {
        'monday': {'open': '09:00', 'close': '20:00'},
        'tuesday': {'open': '09:00', 'close': '20:00'},
        'wednesday': {'open': '09:00', 'close': '20:00'},
        'thursday': {'open': '09:00', 'close': '20:00'},
        'friday': {'open': '09:00', 'close': '20:00'},
        'saturday': {'open': '09:00', 'close': '20:00'},
        'sunday': {'open': '12:00', 'close': '18:30'},
      },
      'stats': {
        'totalOrders': 116,
        'completedOrders': 111,
        'cancelledOrders': 5,
      },
    },
    {
      'id': 'smile_laundry_east_legon',
      'ownerUid': '',
      'name': 'Smile Laundry East Legon',
      'description': 'Specialist laundry and dry cleaning with pickup.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '+233208232788',
      'email': '',
      'addressLine': 'East Legon, Accra, Ghana',
      'latitude': 5.6421,
      'longitude': -0.1510,
      'serviceRadiusKm': 8,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 17,
      'washIronExtraPerKg': 2,
      'rating': 4.2,
      'totalReviews': 14,
      'estimatedTurnaroundText': '3–5 hrs',
      'availabilityStatus': 'busy',
      'isOpenNow': true,
      'acceptingOrders': true,
      'isApproved': true,
      'isFeatured': false,
      'currentOrderCount': 7,
      'maxConcurrentOrders': 10,
      'openingHours': {
        'monday': {'open': '08:00', 'close': '18:00'},
        'tuesday': {'open': '08:00', 'close': '18:00'},
        'wednesday': {'open': '08:00', 'close': '18:00'},
        'thursday': {'open': '08:00', 'close': '18:00'},
        'friday': {'open': '08:00', 'close': '18:00'},
        'saturday': {'open': '09:00', 'close': '17:00'},
        'sunday': {'open': 'closed', 'close': 'closed'},
      },
      'stats': {'totalOrders': 74, 'completedOrders': 69, 'cancelledOrders': 5},
    },
    {
      'id': 'kabell_east_legon',
      'ownerUid': '',
      'name': 'Ka-Bell Laundry & Dry Cleaning',
      'description': 'Laundry and dry cleaning with pickup and delivery.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '+233501394548',
      'email': '',
      'addressLine':
          'East Legon-American House, Agbogba Junction, Shia-shi, Agbogba, Accra, Ghana',
      'latitude': 5.6440,
      'longitude': -0.1449,
      'serviceRadiusKm': 9,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 20,
      'washIronExtraPerKg': 3,
      'rating': 4.5,
      'totalReviews': 27,
      'estimatedTurnaroundText': 'Next day',
      'availabilityStatus': 'available',
      'isOpenNow': true,
      'acceptingOrders': true,
      'isApproved': true,
      'isFeatured': false,
      'currentOrderCount': 4,
      'maxConcurrentOrders': 10,
      'openingHours': {
        'monday': {'open': '07:00', 'close': '19:30'},
        'tuesday': {'open': '07:00', 'close': '19:30'},
        'wednesday': {'open': '07:00', 'close': '19:30'},
        'thursday': {'open': '07:00', 'close': '19:30'},
        'friday': {'open': '07:00', 'close': '19:30'},
        'saturday': {'open': '07:00', 'close': '18:30'},
        'sunday': {'open': 'closed', 'close': 'closed'},
      },
      'stats': {
        'totalOrders': 102,
        'completedOrders': 97,
        'cancelledOrders': 5,
      },
    },
    {
      'id': 'dirttobright_east_legon',
      'ownerUid': '',
      'name': 'DirtToBright East Legon',
      'description': 'Laundry and dry cleaning branch in East Legon.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '+233559324211',
      'email': 'info@dirttobright.com',
      'addressLine': 'Nii Sai Rd, East Legon, Accra, Ghana',
      'latitude': 5.6387,
      'longitude': -0.1523,
      'serviceRadiusKm': 8,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'rating': 4.8,
      'totalReviews': 41,
      'estimatedTurnaroundText': 'Same day',
      'availabilityStatus': 'available',
      'isOpenNow': true,
      'acceptingOrders': true,
      'isApproved': true,
      'isFeatured': true,
      'currentOrderCount': 1,
      'maxConcurrentOrders': 12,
      'openingHours': {
        'monday': {'open': '08:00', 'close': '18:00'},
        'tuesday': {'open': '08:00', 'close': '18:00'},
        'wednesday': {'open': '08:00', 'close': '18:00'},
        'thursday': {'open': '08:00', 'close': '18:00'},
        'friday': {'open': '08:00', 'close': '18:00'},
        'saturday': {'open': '08:00', 'close': '18:00'},
        'sunday': {'open': 'closed', 'close': 'closed'},
      },
      'stats': {
        'totalOrders': 160,
        'completedOrders': 153,
        'cancelledOrders': 7,
      },
    },
    {
      'id': 'e_laundry_east_legon',
      'ownerUid': '',
      'name': 'E-Laundry & General Cleaning Services',
      'description': 'Laundry and general cleaning service in East Legon.',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '+233241995917',
      'email': '',
      'addressLine': 'East Legon American, Accra, Ghana',
      'latitude': 5.6415,
      'longitude': -0.1477,
      'serviceRadiusKm': 8,
      'supportedServices': ['wash_fold', 'wash_iron'],
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'rating': 4.1,
      'totalReviews': 11,
      'estimatedTurnaroundText': 'Same day',
      'availabilityStatus': 'offline',
      'isOpenNow': false,
      'acceptingOrders': false,
      'isApproved': true,
      'isFeatured': false,
      'currentOrderCount': 0,
      'maxConcurrentOrders': 10,
      'openingHours': {
        'monday': {'open': '08:00', 'close': '18:00'},
        'tuesday': {'open': '08:00', 'close': '18:00'},
        'wednesday': {'open': '08:00', 'close': '18:00'},
        'thursday': {'open': '08:00', 'close': '18:00'},
        'friday': {'open': '08:00', 'close': '18:00'},
        'saturday': {'open': '09:00', 'close': '16:00'},
        'sunday': {'open': 'closed', 'close': 'closed'},
      },
      'stats': {'totalOrders': 58, 'completedOrders': 54, 'cancelledOrders': 4},
    },
  ];

  for (final laundry in laundries) {
    final docRef = firestore
        .collection('laundries')
        .doc(laundry['id'] as String);
    batch.set(docRef, {
      ...laundry,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  await batch.commit();
}

Future<void> seedBookingsDummy() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final now = FieldValue.serverTimestamp();

  final bookings = <Map<String, dynamic>>[
    {
      'id': 'booking_001',
      'customerId': 'user_001',
      'laundryId': 'quick_wash_east_legon',
      'pickupRiderId': 'rider_001',
      'deliveryRiderId': null,

      'serviceType': 'wash_fold',
      'supportedAddOns': ['express_delivery', 'scent_booster'],

      'weightRange': '3-5kg',
      'estimatedWeightKg': 4,
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'addOnTotal': 6,
      'subtotal': 78,
      'deliveryFee': 10,
      'totalAmount': 88,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'East Legon, Accra',
        'latitude': 5.6402,
        'longitude': -0.1480,
        'contactName': 'Josiah Commey',
        'contactPhone': '+233240000001',
        'pickupDate': '2026-04-20',
        'pickupTimeSlot': '10:00 AM - 11:00 AM',
        'pickupNotes': 'Call when you arrive.',
      },

      'dropoff': {
        'addressLine': 'East Legon, Accra',
        'latitude': 5.6402,
        'longitude': -0.1480,
        'contactName': 'Josiah Commey',
        'contactPhone': '+233240000001',
        'dropoffNotes': '',
      },

      'laundrySnapshot': {
        'name': 'Quick Wash Laundry East Legon',
        'phoneNumber': '+233502774789',
        'photoUrl': '',
        'addressLine':
            'Nii Osae Ntiful Avenue, Otinshie, East Legon, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Josiah Commey',
        'phoneNumber': '+233240000001',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': {
        'name': 'Kwame Mensah',
        'phoneNumber': '+233240000101',
        'photoUrl': '',
        'vehicleType': 'motorbike',
        'plateNumber': 'GR-1234-24',
      },

      'deliveryRiderSnapshot': null,

      'status': 'pickup_rider_assigned',
      'paymentStatus': 'unpaid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': null,
        'pickupRiderAssignedAt': now,
        'pickupStartedAt': null,
        'pickedUpAt': null,
        'arrivedAtLaundryAt': null,
        'processingStartedAt': null,
        'readyForDropoffAt': null,
        'deliveryRiderAssignedAt': null,
        'deliveryStartedAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
      },

      'cancellation': {'cancelledBy': null, 'reason': null},

      'notes': {
        'customer': 'Please handle white shirts carefully.',
        'laundry': '',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
    {
      'id': 'booking_002',
      'customerId': 'user_002',
      'laundryId': 'laundry_chief_east_legon_shop',
      'pickupRiderId': 'rider_002',
      'deliveryRiderId': 'rider_003',

      'serviceType': 'wash_iron',
      'supportedAddOns': ['starch_treatment'],

      'weightRange': '1-3kg',
      'estimatedWeightKg': 2,
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'addOnTotal': 4,
      'subtotal': 40,
      'deliveryFee': 10,
      'totalAmount': 50,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'Adjiringanor, Accra',
        'latitude': 5.6418,
        'longitude': -0.1459,
        'contactName': 'Ama Boateng',
        'contactPhone': '+233240000002',
        'pickupDate': '2026-04-20',
        'pickupTimeSlot': '1:00 PM - 2:00 PM',
        'pickupNotes': '',
      },

      'dropoff': {
        'addressLine': 'Adjiringanor, Accra',
        'latitude': 5.6418,
        'longitude': -0.1459,
        'contactName': 'Ama Boateng',
        'contactPhone': '+233240000002',
        'dropoffNotes': 'Leave at reception if unavailable.',
      },

      'laundrySnapshot': {
        'name': 'Laundry Chief - East Legon Shop',
        'phoneNumber': '',
        'photoUrl': '',
        'addressLine': '19 Boundary Road, East Legon, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Ama Boateng',
        'phoneNumber': '+233240000002',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': {
        'name': 'Yaw Tetteh',
        'phoneNumber': '+233240000102',
        'photoUrl': '',
        'vehicleType': 'motorbike',
        'plateNumber': 'GT-2231-24',
      },

      'deliveryRiderSnapshot': {
        'name': 'Kojo Asare',
        'phoneNumber': '+233240000103',
        'photoUrl': '',
        'vehicleType': 'motorbike',
        'plateNumber': 'GX-8831-24',
      },

      'status': 'processing',
      'paymentStatus': 'paid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': now,
        'pickupRiderAssignedAt': now,
        'pickupStartedAt': now,
        'pickedUpAt': now,
        'arrivedAtLaundryAt': now,
        'processingStartedAt': now,
        'readyForDropoffAt': null,
        'deliveryRiderAssignedAt': now,
        'deliveryStartedAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
      },

      'cancellation': {'cancelledBy': null, 'reason': null},

      'notes': {
        'customer': '',
        'laundry': 'Prioritize office wear.',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
    {
      'id': 'booking_003',
      'customerId': 'user_003',
      'laundryId': 'dirttobright_east_legon',
      'pickupRiderId': 'rider_004',
      'deliveryRiderId': 'rider_004',

      'serviceType': 'wash_fold',
      'supportedAddOns': [],

      'weightRange': '5-8kg',
      'estimatedWeightKg': 6,
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'addOnTotal': 0,
      'subtotal': 108,
      'deliveryFee': 12,
      'totalAmount': 120,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'Shiashie, Accra',
        'latitude': 5.6389,
        'longitude': -0.1511,
        'contactName': 'Nana Adjei',
        'contactPhone': '+233240000003',
        'pickupDate': '2026-04-21',
        'pickupTimeSlot': '9:00 AM - 10:00 AM',
        'pickupNotes': '',
      },

      'dropoff': {
        'addressLine': 'Shiashie, Accra',
        'latitude': 5.6389,
        'longitude': -0.1511,
        'contactName': 'Nana Adjei',
        'contactPhone': '+233240000003',
        'dropoffNotes': '',
      },

      'laundrySnapshot': {
        'name': 'DirtToBright East Legon',
        'phoneNumber': '+233559324211',
        'photoUrl': '',
        'addressLine': 'Nii Sai Rd, East Legon, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Nana Adjei',
        'phoneNumber': '+233240000003',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': {
        'name': 'Eric Osei',
        'phoneNumber': '+233240000104',
        'photoUrl': '',
        'vehicleType': 'motorbike',
        'plateNumber': 'GW-4401-24',
      },

      'deliveryRiderSnapshot': {
        'name': 'Eric Osei',
        'phoneNumber': '+233240000104',
        'photoUrl': '',
        'vehicleType': 'motorbike',
        'plateNumber': 'GW-4401-24',
      },

      'status': 'delivered',
      'paymentStatus': 'paid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': now,
        'pickupRiderAssignedAt': now,
        'pickupStartedAt': now,
        'pickedUpAt': now,
        'arrivedAtLaundryAt': now,
        'processingStartedAt': now,
        'readyForDropoffAt': now,
        'deliveryRiderAssignedAt': now,
        'deliveryStartedAt': now,
        'deliveredAt': now,
        'cancelledAt': null,
      },

      'cancellation': {'cancelledBy': null, 'reason': null},

      'notes': {
        'customer': '',
        'laundry': '',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
    {
      'id': 'booking_004',
      'customerId': 'user_004',
      'laundryId': 'kabell_east_legon',
      'pickupRiderId': null,
      'deliveryRiderId': null,

      'serviceType': 'wash_iron',
      'supportedAddOns': ['express_delivery', 'starch_treatment'],

      'weightRange': '3-5kg',
      'estimatedWeightKg': 5,
      'basePricePerKg': 20,
      'washIronExtraPerKg': 3,
      'addOnTotal': 8,
      'subtotal': 123,
      'deliveryFee': 12,
      'totalAmount': 135,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'American House, Accra',
        'latitude': 5.6441,
        'longitude': -0.1453,
        'contactName': 'Efua Mensima',
        'contactPhone': '+233240000004',
        'pickupDate': '2026-04-21',
        'pickupTimeSlot': '4:00 PM - 5:00 PM',
        'pickupNotes': 'Ring bell twice.',
      },

      'dropoff': {
        'addressLine': 'American House, Accra',
        'latitude': 5.6441,
        'longitude': -0.1453,
        'contactName': 'Efua Mensima',
        'contactPhone': '+233240000004',
        'dropoffNotes': '',
      },

      'laundrySnapshot': {
        'name': 'Ka-Bell Laundry & Dry Cleaning',
        'phoneNumber': '+233501394548',
        'photoUrl': '',
        'addressLine':
            'East Legon-American House, Agbogba Junction, Shia-shi, Agbogba, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Efua Mensima',
        'phoneNumber': '+233240000004',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': null,
      'deliveryRiderSnapshot': null,

      'status': 'awaiting_pickup_rider_assignment',
      'paymentStatus': 'unpaid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': now,
        'pickupRiderAssignedAt': null,
        'pickupStartedAt': null,
        'pickedUpAt': null,
        'arrivedAtLaundryAt': null,
        'processingStartedAt': null,
        'readyForDropoffAt': null,
        'deliveryRiderAssignedAt': null,
        'deliveryStartedAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
      },

      'cancellation': {'cancelledBy': null, 'reason': null},

      'notes': {
        'customer': 'Mostly formal wear.',
        'laundry': '',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
    {
      'id': 'booking_005',
      'customerId': 'user_005',
      'laundryId': 'smile_laundry_east_legon',
      'pickupRiderId': null,
      'deliveryRiderId': null,

      'serviceType': 'wash_fold',
      'supportedAddOns': ['scent_booster'],

      'weightRange': '1-3kg',
      'estimatedWeightKg': 3,
      'basePricePerKg': 17,
      'washIronExtraPerKg': 2,
      'addOnTotal': 3,
      'subtotal': 54,
      'deliveryFee': 10,
      'totalAmount': 64,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'East Legon Hills, Accra',
        'latitude': 5.6450,
        'longitude': -0.1530,
        'contactName': 'Linda Owusu',
        'contactPhone': '+233240000005',
        'pickupDate': '2026-04-22',
        'pickupTimeSlot': '11:00 AM - 12:00 PM',
        'pickupNotes': '',
      },

      'dropoff': {
        'addressLine': 'East Legon Hills, Accra',
        'latitude': 5.6450,
        'longitude': -0.1530,
        'contactName': 'Linda Owusu',
        'contactPhone': '+233240000005',
        'dropoffNotes': '',
      },

      'laundrySnapshot': {
        'name': 'Smile Laundry East Legon',
        'phoneNumber': '+233208232788',
        'photoUrl': '',
        'addressLine': 'East Legon, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Linda Owusu',
        'phoneNumber': '+233240000005',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': null,
      'deliveryRiderSnapshot': null,

      'status': 'pending_laundry_acceptance',
      'paymentStatus': 'unpaid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': null,
        'pickupRiderAssignedAt': null,
        'pickupStartedAt': null,
        'pickedUpAt': null,
        'arrivedAtLaundryAt': null,
        'processingStartedAt': null,
        'readyForDropoffAt': null,
        'deliveryRiderAssignedAt': null,
        'deliveryStartedAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
      },

      'cancellation': {'cancelledBy': null, 'reason': null},

      'notes': {
        'customer': '',
        'laundry': '',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
    {
      'id': 'booking_006',
      'customerId': 'user_006',
      'laundryId': 'e_laundry_east_legon',
      'pickupRiderId': null,
      'deliveryRiderId': null,

      'serviceType': 'wash_fold',
      'supportedAddOns': [],

      'weightRange': '3-5kg',
      'estimatedWeightKg': 4,
      'basePricePerKg': 18,
      'washIronExtraPerKg': 2,
      'addOnTotal': 0,
      'subtotal': 72,
      'deliveryFee': 10,
      'totalAmount': 82,
      'currency': 'GHS',

      'pickup': {
        'addressLine': 'East Legon American House, Accra',
        'latitude': 5.6416,
        'longitude': -0.1478,
        'contactName': 'Bernice Aidoo',
        'contactPhone': '+233240000006',
        'pickupDate': '2026-04-23',
        'pickupTimeSlot': '2:00 PM - 3:00 PM',
        'pickupNotes': '',
      },

      'dropoff': {
        'addressLine': 'East Legon American House, Accra',
        'latitude': 5.6416,
        'longitude': -0.1478,
        'contactName': 'Bernice Aidoo',
        'contactPhone': '+233240000006',
        'dropoffNotes': '',
      },

      'laundrySnapshot': {
        'name': 'E-Laundry & General Cleaning Services',
        'phoneNumber': '+233241995917',
        'photoUrl': '',
        'addressLine': 'East Legon American, Accra, Ghana',
      },

      'customerSnapshot': {
        'name': 'Bernice Aidoo',
        'phoneNumber': '+233240000006',
        'photoUrl': '',
      },

      'pickupRiderSnapshot': null,
      'deliveryRiderSnapshot': null,

      'status': 'laundry_rejected',
      'paymentStatus': 'unpaid',

      'timeline': {
        'requestedAt': now,
        'laundryAcceptedAt': null,
        'pickupRiderAssignedAt': null,
        'pickupStartedAt': null,
        'pickedUpAt': null,
        'arrivedAtLaundryAt': null,
        'processingStartedAt': null,
        'readyForDropoffAt': null,
        'deliveryRiderAssignedAt': null,
        'deliveryStartedAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
      },

      'cancellation': {
        'cancelledBy': 'laundry',
        'reason': 'Laundry currently unavailable.',
      },

      'notes': {
        'customer': '',
        'laundry': 'Store closed for maintenance.',
        'pickupRider': '',
        'deliveryRider': '',
      },
    },
  ];

  for (final booking in bookings) {
    final docRef = firestore
        .collection('bookings')
        .doc(booking['id'] as String);

    batch.set(docRef, {
      ...booking,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  await batch.commit();
}
