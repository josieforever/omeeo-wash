import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AddressType { other, home, work }

class SavedAddress {
  final AddressType type;
  final String name;
  final String location;
  final String instructions;
  final double? latitude;
  final double? longitude;
  final String? subtitle;

  const SavedAddress({
    required this.type,
    required this.name,
    required this.location,
    required this.instructions,
    this.latitude,
    this.longitude,
    this.subtitle,
  });

  SavedAddress copyWith({
    AddressType? type,
    String? name,
    String? location,
    String? instructions,
    double? latitude,
    double? longitude,
    String? subtitle,
  }) {
    return SavedAddress(
      type: type ?? this.type,
      name: name ?? this.name,
      location: location ?? this.location,
      instructions: instructions ?? this.instructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });
}

class PickedLocationResult {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String subtitle;

  const PickedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.subtitle,
  });
}

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  SavedAddress? _homeAddress;
  SavedAddress? _workAddress;
  final List<SavedAddress> _otherAddresses = [];

  Future<void> _openLocationSearch(
    AddressType type, {
    String? defaultName,
    SavedAddress? existingAddress,
  }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchAddressLocationScreen(
          addressType: type,
          defaultName: existingAddress?.name ?? (defaultName ?? ''),
          existingAddress: existingAddress,
        ),
      ),
    );

    if (result == null) return;

    final saved = SavedAddress(
      type: type,
      name: (result['name'] as String?)?.trim() ?? '',
      location: (result['location'] as String?)?.trim() ?? '',
      instructions: (result['instructions'] as String?)?.trim() ?? '',
      latitude: result['latitude'] as double?,
      longitude: result['longitude'] as double?,
      subtitle: result['subtitle'] as String?,
    );

    final normalizedName = saved.name.trim().toLowerCase();

    setState(() {
      if (normalizedName == 'home') {
        _homeAddress = saved.copyWith(type: AddressType.home);
        return;
      }

      if (normalizedName == 'work') {
        _workAddress = saved.copyWith(type: AddressType.work);
        return;
      }

      if (existingAddress != null &&
          existingAddress.type == AddressType.other) {
        final index = _otherAddresses.indexWhere(
          (e) =>
              e.name == existingAddress.name &&
              e.location == existingAddress.location &&
              e.instructions == existingAddress.instructions,
        );

        if (index != -1) {
          _otherAddresses[index] = saved.copyWith(type: AddressType.other);
        } else {
          _otherAddresses.add(saved.copyWith(type: AddressType.other));
        }
        return;
      }

      _otherAddresses.add(saved.copyWith(type: AddressType.other));
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF3F3F3);
    const primaryText = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 24,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 26),
                child: Text(
                  'My addresses',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 26),

              _SavedOrAddAddressTile(
                savedAddress: null,
                emptyTitle: 'Add address',
                emptyIcon: Icons.bookmark,
                onTap: () => _openLocationSearch(AddressType.other),
              ),

              _SavedOrAddAddressTile(
                savedAddress: _homeAddress,
                emptyTitle: 'Add home address',
                emptyIcon: Icons.home,
                onTap: () => _openLocationSearch(
                  AddressType.home,
                  defaultName: 'Home',
                  existingAddress: _homeAddress,
                ),
              ),

              _SavedOrAddAddressTile(
                savedAddress: _workAddress,
                emptyTitle: 'Add work address',
                emptyIcon: Icons.work,
                onTap: () => _openLocationSearch(
                  AddressType.work,
                  defaultName: 'Work',
                  existingAddress: _workAddress,
                ),
              ),

              ..._otherAddresses.map(
                (address) => _SavedAddressListTile(
                  savedAddress: address,
                  onTap: () => _openLocationSearch(
                    AddressType.other,
                    existingAddress: address,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedOrAddAddressTile extends StatelessWidget {
  final SavedAddress? savedAddress;
  final String emptyTitle;
  final IconData emptyIcon;
  final VoidCallback onTap;

  const _SavedOrAddAddressTile({
    required this.savedAddress,
    required this.emptyTitle,
    required this.emptyIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xFF111111);
    const secondaryText = Color(0xFFC9C9C9);
    const dividerColor = Color(0xFFE0E0E0);
    const plusColor = Color(0xFFD0D0D0);

    final hasAddress = savedAddress != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    emptyIcon,
                    size: 31,
                    color: hasAddress ? primaryText : secondaryText,
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: hasAddress
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                savedAddress!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: primaryText,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                savedAddress!.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            emptyTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: primaryText,
                            ),
                          ),
                  ),
                  Icon(
                    hasAddress ? Icons.more_vert : Icons.add,
                    size: hasAddress ? 24 : 38,
                    color: hasAddress ? const Color(0xFFC0C0C0) : plusColor,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 66),
              child: Divider(height: 1, thickness: 1, color: dividerColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressListTile extends StatelessWidget {
  final SavedAddress savedAddress;
  final VoidCallback onTap;

  const _SavedAddressListTile({
    required this.savedAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xFF111111);
    const secondaryText = Color(0xFF8A8A8A);
    const dividerColor = Color(0xFFE0E0E0);

    IconData leadingIcon;
    switch (savedAddress.type) {
      case AddressType.home:
        leadingIcon = Icons.home;
        break;
      case AddressType.work:
        leadingIcon = Icons.work;
        break;
      case AddressType.other:
        leadingIcon = Icons.bookmark;
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(leadingIcon, size: 31, color: const Color(0xFFC9C9C9)),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          savedAddress.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          savedAddress.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryText,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.more_vert,
                      color: Color(0xFFC0C0C0),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 66),
              child: Divider(height: 1, thickness: 1, color: dividerColor),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchAddressLocationScreen extends StatefulWidget {
  final AddressType addressType;
  final String defaultName;
  final SavedAddress? existingAddress;

  const SearchAddressLocationScreen({
    super.key,
    required this.addressType,
    required this.defaultName,
    this.existingAddress,
  });

  @override
  State<SearchAddressLocationScreen> createState() =>
      _SearchAddressLocationScreenState();
}

class _SearchAddressLocationScreenState
    extends State<SearchAddressLocationScreen> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  bool _isSearchingLocations = false;
  bool _isSheetHigh = false;

  List<PlacePrediction> _predictions = [];
  String? _selectedPickupAddress;

  Timer? _debounce;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final double _lowSnap = 0.22;

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.existingAddress?.location ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_locationFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.addressType) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Address';
    }
  }

  Future<void> _searchPlaces(String query) async {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
        _selectedPickupAddress = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() {
        _isSearchingLocations = true;
      });

      try {
        await Future.delayed(const Duration(milliseconds: 300));
        final q = query.trim();

        final results = <PlacePrediction>[
          PlacePrediction(
            placeId: '1',
            mainText: q,
            secondaryText: 'Accra, Ghana',
            fullAddress: '$q, Accra, Ghana',
            latitude: 5.6037,
            longitude: -0.1870,
          ),
          PlacePrediction(
            placeId: '2',
            mainText: '$q Junction',
            secondaryText: 'East Legon, Accra',
            fullAddress: '$q Junction, East Legon, Accra',
            latitude: 5.6511,
            longitude: -0.1735,
          ),
          PlacePrediction(
            placeId: '3',
            mainText: '$q Road',
            secondaryText: 'Spintex, Accra',
            fullAddress: '$q Road, Spintex, Accra',
            latitude: 5.6390,
            longitude: -0.1185,
          ),
        ];

        if (!mounted) return;
        setState(() {
          _predictions = results;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSearchingLocations = false;
          });
        }
      }
    });
  }

  Future<void> _selectPrediction(PlacePrediction place) async {
    _locationController.text = place.fullAddress;

    setState(() {
      _selectedPickupAddress = place.fullAddress;
      _predictions = [];
    });

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressDetailsScreen(
          addressType: widget.addressType,
          initialName: widget.existingAddress?.name.isNotEmpty == true
              ? widget.existingAddress!.name
              : widget.defaultName,
          initialLocation: place.fullAddress,
          initialInstructions: widget.existingAddress?.instructions ?? '',
          initialLatitude: place.latitude,
          initialLongitude: place.longitude,
          initialSubtitle: place.secondaryText,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    }
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

      final detailsResult = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => AddressDetailsScreen(
            addressType: widget.addressType,
            initialName: widget.existingAddress?.name.isNotEmpty == true
                ? widget.existingAddress!.name
                : widget.defaultName,
            initialLocation: result.addressLine,
            initialInstructions: widget.existingAddress?.instructions ?? '',
            initialLatitude: result.latitude,
            initialLongitude: result.longitude,
            initialSubtitle: result.subtitle,
          ),
        ),
      );

      if (!mounted) return;
      if (detailsResult != null) {
        Navigator.pop(context, detailsResult);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF3F3F3);
    const primaryText = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 24,
                      color: primaryText,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Center(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Select location',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchSection(),
            ],
          ),
        ),
      ),
    );
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
                    color: const Color(0xFFFFF7F9),
                    borderRadius: BorderRadius.circular(10),
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
                    child: Center(
                      child: Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class AddressDetailsScreen extends StatefulWidget {
  final AddressType addressType;
  final String initialName;
  final String initialLocation;
  final String initialInstructions;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialSubtitle;

  const AddressDetailsScreen({
    super.key,
    required this.addressType,
    required this.initialName,
    required this.initialLocation,
    this.initialInstructions = '',
    this.initialLatitude,
    this.initialLongitude,
    this.initialSubtitle,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _instructionsController;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _instructionsFocusNode = FocusNode();

  double? _latitude;
  double? _longitude;
  String? _subtitle;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _locationController = TextEditingController(text: widget.initialLocation);
    _instructionsController = TextEditingController(
      text: widget.initialInstructions,
    );

    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _subtitle = widget.initialSubtitle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_nameFocusNode);
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });

    _nameController.addListener(_refresh);
    _locationController.addListener(_refresh);
    _instructionsController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _locationController.removeListener(_refresh);
    _instructionsController.removeListener(_refresh);

    _nameController.dispose();
    _locationController.dispose();
    _instructionsController.dispose();

    _nameFocusNode.dispose();
    _locationFocusNode.dispose();
    _instructionsFocusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  String get _screenTitle {
    switch (widget.addressType) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Address';
    }
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF3F3F3);
    const primaryText = Color(0xFF111111);
    const hintText = Color(0xFF9A9A9A);
    const dividerColor = Color(0xFFD9D9D9);
    const saveColor = Color(0xFFFF4E38);
    const disabledSaveColor = Color(0xFFF2A49A);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 24,
                      color: primaryText,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Center(
                        child: Text(
                          _screenTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 36, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      autofocus: true,
                      cursorColor: const Color(0xFF4F8EF7),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(top: 2, bottom: 8),
                        border: InputBorder.none,
                      ),
                    ),
                    Container(height: 2, color: const Color(0xFF3B3940)),
                    const SizedBox(height: 20),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    TextField(
                      controller: _locationController,
                      focusNode: _locationFocusNode,
                      cursorColor: const Color(0xFF4F8EF7),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(top: 2, bottom: 8),
                        border: InputBorder.none,
                      ),
                    ),
                    Container(height: 1, color: dividerColor),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _instructionsController,
                      focusNode: _instructionsFocusNode,
                      cursorColor: const Color(0xFF4F8EF7),
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: primaryText,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Pickup instructions for driver',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: hintText,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _canSave
                      ? () {
                          Navigator.pop(context, {
                            'name': _nameController.text.trim(),
                            'location': _locationController.text.trim(),
                            'instructions': _instructionsController.text.trim(),
                            'latitude': _latitude,
                            'longitude': _longitude,
                            'subtitle': _subtitle,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: saveColor,
                    disabledBackgroundColor: disabledSaveColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleMapLocationPickerScreen extends StatefulWidget {
  const GoogleMapLocationPickerScreen({super.key});

  @override
  State<GoogleMapLocationPickerScreen> createState() =>
      _GoogleMapLocationPickerScreenState();
}

class _GoogleMapLocationPickerScreenState
    extends State<GoogleMapLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870);

  GoogleMapController? _mapController;
  LatLng _mapCenter = _defaultCenter;

  bool _isMapReady = false;
  bool _isResolvingAddress = true;
  bool _isFetchingCurrentLocation = false;

  String _title = 'Fetching address...';
  String _subtitle = '';
  Placemark? _placemark;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_mapCenter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() {
      _isResolvingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );

      if (!mounted) return;

      if (placemarks.isEmpty) {
        setState(() {
          _placemark = null;
          _title = 'Selected location';
          _subtitle =
              '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
          _isResolvingAddress = false;
        });
        return;
      }

      final p = placemarks.first;

      final titleParts = <String>[
        if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      ];

      final subtitleParts = <String>[
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? '').trim().isNotEmpty)
          p.administrativeArea!.trim(),
        if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
      ];

      setState(() {
        _placemark = p;
        _title = titleParts.isNotEmpty
            ? titleParts.join(', ')
            : 'Selected location';
        _subtitle = subtitleParts.isNotEmpty
            ? subtitleParts.join(', ')
            : '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placemark = null;
        _title = 'Selected location';
        _subtitle =
            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _isResolvingAddress = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final target = LatLng(position.latitude, position.longitude);

      _mapCenter = target;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );

      await _reverseGeocode(target);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _onDone() {
    final result = PickedLocationResult(
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      addressLine: _title,
      subtitle: _subtitle,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 17,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                setState(() {
                  _isMapReady = true;
                });
              },
              onCameraMove: (position) {
                _mapCenter = position.target;
              },
              onCameraIdle: () {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  _reverseGeocode(_mapCenter);
                });
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Center(
                child: Text(
                  'Swipe to move map',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.80),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -70),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.moped,
                        size: 26,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    Container(width: 3, height: 36, color: Colors.black87),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 0, 0, 0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isResolvingAddress ? 'Locating...' : _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 230,
            child: _RoundMapButton2(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 230,
            child: _RoundMapButton(
              icon: _isFetchingCurrentLocation
                  ? Icons.more_horiz_rounded
                  : Icons.navigation_outlined,
              onTap: _isFetchingCurrentLocation ? null : _goToCurrentLocation,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomAddressCard(
              title: 'Destination address',
              areaText: _subtitle,
              streetText: _title,
              isLoading: _isResolvingAddress || !_isMapReady,
              onDoneTap: (_isResolvingAddress || !_isMapReady) ? null : _onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAddressCard extends StatelessWidget {
  final String title;
  final String areaText;
  final String streetText;
  final bool isLoading;
  final VoidCallback? onDoneTap;

  const _BottomAddressCard({
    required this.title,
    required this.areaText,
    required this.streetText,
    required this.isLoading,
    this.onDoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.local_laundry_service_outlined,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: LinearProgressIndicator(minHeight: 3),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            areaText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            streetText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: onDoneTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE36C9A),
                disabledBackgroundColor: const Color(0xFFFFB4AA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundMapButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF9FB),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFFFF4B36), size: 22),
        ),
      ),
    );
  }
}

class _RoundMapButton2 extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundMapButton2({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF9FB),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 0, 0, 0),
            size: 22,
          ),
        ),
      ),
    );
  }
}
