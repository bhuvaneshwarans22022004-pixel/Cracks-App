import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/guest_auth_prompt.dart';
import 'payment_screen.dart';

class AddressScreen extends StatefulWidget {
  final bool isCheckoutMode;
  final double totalMrp;
  final double discount;
  final double deliveryCharge;
  final double toPay;

  const AddressScreen({
    super.key,
    required this.isCheckoutMode,
    this.totalMrp = 0.0,
    this.discount = 0.0,
    this.deliveryCharge = 0.0,
    this.toPay = 0.0,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  String _addressType = 'Home';
  String _selectedState = 'Tamil Nadu';
  String _selectedCity = 'Select City';

  final _nameController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final List<String> _tnCities = [
    "Select City",
    "Others",
    "Ambasamudram",
    "Anamali",
    "Arakandanallur",
    "Arantangi",
    "Ariyalur",
    "Chennai",
    "Coimbatore",
    "Cuddalore",
    "Dharmapuri",
    "Dindigul",
    "Erode",
    "Kanchipuram",
    "Kanyakumari",
    "Karur",
    "Krishnagiri",
    "Madurai",
    "Nagapattinam",
    "Namakkal",
    "Nilgiris",
    "Perambalur",
    "Pudukkottai",
    "Ramanathapuram",
    "Ranipet",
    "Salem",
    "Sivaganga",
    "Sivakasi",
    "Tenkasi",
    "Thanjavur",
    "Theni",
    "Thoothukudi",
    "Tiruchirappalli",
    "Tirunelveli",
    "Tirupathur",
    "Tirupati",
    "Tirupathi",
    "Tiruppur",
    "Tirupur",
    "Tiruvallur",
    "Tiruvannamalai",
    "Tiruvarur",
    "Vellore",
    "Viluppuram",
    "Virudhunagar",
  ];

  final List<String> _states = [
    "Tamil Nadu",
    "Karnataka",
    "Puducherry",
  ];

  @override
  void initState() {
    super.initState();
    _stateController.text = _selectedState;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!.token != null) {
        Provider.of<AddressProvider>(context, listen: false)
            .fetchAddresses(auth.user!.token!);
        if (auth.user!.name != null) {
          _nameController.text = auth.user!.name!;
        }
        if (auth.user!.email != null) {
          _emailController.text = auth.user!.email!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<List<String>> _getPlacesSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = 'addresses/autocomplete?query=${Uri.encodeComponent(query.trim())}';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item.toString()).toList();
      }
    } catch (e) {
      print("[Autocomplete Log] Error fetching places from backend: $e");
    }
    return [];
  }

  bool _isFetchingPincode = false;
  List<String> _postalPlaceSuggestions = [];
  String? _selectedPostalPlace;

  void _selectPostalPlace(String place, Function setModalState) {
    setModalState(() {
      final oldPlace = _selectedPostalPlace;
      _selectedPostalPlace = place;

      String currentAddress = _addressLineController.text.trim();
      if (oldPlace != null && oldPlace.isNotEmpty && currentAddress.contains(oldPlace)) {
        currentAddress = currentAddress.replaceAll(oldPlace, place).trim();
      } else if (currentAddress.isEmpty) {
        currentAddress = place;
      } else if (!currentAddress.contains(place)) {
        currentAddress = "$place, $currentAddress";
      }
      _addressLineController.text = currentAddress;
    });
  }

  Future<void> _fetchPincodeDetails(String pincode, Function setModalState) async {
    if (pincode.length != 6) return;
    setModalState(() => _isFetchingPincode = true);
    try {
      final res = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List? ?? [];
          if (postOffices.isNotEmpty) {
            final firstPo = postOffices[0];
            final district = firstPo['District'] ?? '';
            final state = firstPo['State'] ?? '';
            final poNames = postOffices.map((po) => po['Name'].toString()).toList();

            setModalState(() {
              if (district.isNotEmpty) {
                _cityController.text = district;
                _selectedCity = district;
              }
              if (state.isNotEmpty) {
                _selectedState = state;
                _stateController.text = state;
              }
              _postalPlaceSuggestions = poNames;
              if (poNames.isNotEmpty) {
                _selectedPostalPlace = poNames.first;
                if (_addressLineController.text.isEmpty) {
                  _addressLineController.text = poNames.first;
                }
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching pincode: $e");
    } finally {
      setModalState(() => _isFetchingPincode = false);
    }
  }

  void _showAddAddressSheet(AddressProvider addressProvider, {Address? existingAddress}) {
    List<String> suggestions = [];
    bool isSearching = false;
    Timer? debounceTimer;
    String activeField = '';

    if (existingAddress != null) {
      _addressLineController.text = existingAddress.addressLine;
      _cityController.text = existingAddress.city;
      _stateController.text = existingAddress.state;
      _zipCodeController.text = existingAddress.zipCode;
      _phoneController.text = existingAddress.phoneNumber;
      _addressType = existingAddress.type;
      if (_tnCities.contains(existingAddress.city)) {
        _selectedCity = existingAddress.city;
      } else {
        _selectedCity = 'Others';
      }
      if (_states.contains(existingAddress.state)) {
        _selectedState = existingAddress.state;
      }
    } else {
      _addressLineController.clear();
      _cityController.clear();
      _zipCodeController.clear();
      _phoneController.clear();
      _addressType = 'Home';
      _selectedState = 'Tamil Nadu';
      _selectedCity = 'Select City';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cart = Provider.of<CartProvider>(context, listen: false);
            final double calcSubTotal = widget.totalMrp > 0 ? widget.totalMrp : cart.totalAmount;
            final double calcPacking = widget.deliveryCharge > 0 ? widget.deliveryCharge : 50.0;
            final double calcOverall = widget.toPay > 0 ? widget.toPay : (calcSubTotal + calcPacking);

            Widget buildFormLabel(String label, {bool isRequired = false}) {
              return SizedBox(
                width: 95,
                child: RichText(
                  text: TextSpan(
                    text: label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    children: isRequired ? [
                      const TextSpan(
                        text: ' (*)',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ] : [],
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Column(
                children: [
                  // 1. Header Bar (Orange Background with Store Title & Close Button)
                  Container(
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top + 8 : 14, 12, 12),
                    color: const Color(0xFFFF5722),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "FestiveKart ",
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // 2. Form Fields Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // State Row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  buildFormLabel("State", isRequired: true),
                                  Expanded(
                                    child: Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[400]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _states.contains(_selectedState) ? _selectedState : _states.first,
                                          isExpanded: true,
                                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                                          items: _states.map((s) {
                                            return DropdownMenuItem(value: s, child: Text(s));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                _selectedState = val;
                                                _stateController.text = val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // City Row (Searchable & Editable Input)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: buildFormLabel("City"),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            controller: _cityController,
                                            style: GoogleFonts.outfit(fontSize: 14),
                                            onChanged: (val) {
                                              setModalState(() {});
                                            },
                                            decoration: InputDecoration(
                                              hintText: "Enter or select city (e.g. Tirupur, Coimbatore)",
                                              hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                            ),
                                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                                          ),
                                        ),
                                        if (_cityController.text.trim().isNotEmpty) ...[
                                          Builder(
                                            builder: (context) {
                                              final query = _cityController.text.trim().toLowerCase();
                                              final matches = _tnCities
                                                  .where((c) => c != 'Select City' && c.toLowerCase().contains(query) && c.toLowerCase() != query)
                                                  .toList();
                                              if (matches.isEmpty) return const SizedBox.shrink();
                                              return Container(
                                                constraints: const BoxConstraints(maxHeight: 140),
                                                margin: const EdgeInsets.only(top: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.06),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 3),
                                                    )
                                                  ],
                                                ),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.zero,
                                                  itemCount: matches.length,
                                                  itemBuilder: (c, idx) => ListTile(
                                                    dense: true,
                                                    title: Text(matches[idx], style: GoogleFonts.outfit(fontSize: 13)),
                                                    onTap: () {
                                                      setModalState(() {
                                                        _cityController.text = matches[idx];
                                                      });
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Pincode Row (Auto Fetches City, State & Postal Places)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      buildFormLabel("Pincode", isRequired: true),
                                      Expanded(
                                        child: SizedBox(
                                          height: 42,
                                          child: TextFormField(
                                            controller: _zipCodeController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            style: GoogleFonts.outfit(fontSize: 14),
                                            onChanged: (val) {
                                              if (val.trim().length == 6) {
                                                _fetchPincodeDetails(val.trim(), setModalState);
                                              }
                                            },
                                            decoration: InputDecoration(
                                              counterText: "",
                                              hintText: "Enter 6-digit Pincode (e.g. 641402)",
                                              hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                              suffixIcon: _isFetchingPincode
                                                  ? const Padding(
                                                      padding: EdgeInsets.all(10),
                                                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5722))),
                                                    )
                                                  : const Icon(Icons.pin_drop_outlined, color: Colors.grey, size: 18),
                                            ),
                                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter pincode' : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_postalPlaceSuggestions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        buildFormLabel("Postal Place"),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                             children: _postalPlaceSuggestions.map((place) {
                                               final isSelected = _selectedPostalPlace == place;
                                               return ChoiceChip(
                                                 avatar: isSelected ? const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white) : null,
                                                 label: Text(
                                                   place,
                                                   style: GoogleFonts.outfit(
                                                     fontSize: 11,
                                                     fontWeight: FontWeight.bold,
                                                     color: isSelected ? Colors.white : const Color(0xFFE65100),
                                                   ),
                                                 ),
                                                 selected: isSelected,
                                                 selectedColor: const Color(0xFFFF5722),
                                                 backgroundColor: const Color(0xFFFFF3E0),
                                                 side: BorderSide(
                                                   color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFFF8C00),
                                                   width: 1.2,
                                                 ),
                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                 onSelected: (val) {
                                                   if (val) {
                                                     _selectPostalPlace(place, setModalState);
                                                   }
                                                 },
                                               );
                                             }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Name Row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  buildFormLabel("Name", isRequired: true),
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: TextFormField(
                                        controller: _nameController,
                                        style: GoogleFonts.outfit(fontSize: 14),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                        ),
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Mobile No Row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  buildFormLabel("Mobile.No", isRequired: true),
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.outfit(fontSize: 14),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                        ),
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Email Row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  buildFormLabel("Email"),
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: GoogleFonts.outfit(fontSize: 14),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Address Row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: buildFormLabel("Address", isRequired: true),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _addressLineController,
                                          maxLines: 3,
                                          style: GoogleFonts.outfit(fontSize: 14),
                                          onChanged: (val) {
                                            if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
                                            debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                                              if (val.trim().isEmpty) {
                                                setModalState(() { suggestions = []; activeField = ''; });
                                                return;
                                              }
                                              setModalState(() { isSearching = true; activeField = 'addressLine'; });
                                              final fetched = await _getPlacesSuggestions(val.trim());
                                              setModalState(() { suggestions = fetched; isSearching = false; });
                                            });
                                          },
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.all(12),
                                            hintText: "Address Line (Door No, Street)",
                                            hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
                                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF5722)), borderRadius: BorderRadius.circular(4)),
                                          ),
                                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter address line' : null,
                                        ),
                                        if (activeField == 'addressLine' && suggestions.isNotEmpty)
                                          Container(
                                            constraints: const BoxConstraints(maxHeight: 140),
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: suggestions.length,
                                              itemBuilder: (c, idx) => ListTile(
                                                dense: true,
                                                title: Text(suggestions[idx], style: GoogleFonts.outfit(fontSize: 12)),
                                                onTap: () {
                                                  setModalState(() {
                                                    _addressLineController.text = suggestions[idx];
                                                    suggestions.clear();
                                                    activeField = '';
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 24, thickness: 1),

                            // 3. Billing Summary Block (Matches Screenshot 2)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Sub Total", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                      Text("₹ ${calcSubTotal.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Min.Order Amount", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      Text("₹ 4500.00", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Packing Charges (50)", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                      Text("₹ ${calcPacking.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Round OFF", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                      Text("₹ 0.00", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Overall Amount", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      Text("₹ ${calcOverall.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. Submit & Back Dual Action Buttons (Green & Red)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00C853), // Bright vibrant Green
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          final auth = Provider.of<AuthProvider>(context, listen: false);
                                          final token = auth.user?.token ?? '';
                                          final cityVal = _selectedCity != 'Select City' && _selectedCity != 'Others'
                                              ? _selectedCity
                                              : (_cityController.text.isNotEmpty ? _cityController.text : "Coimbatore");

                                          if (existingAddress != null) {
                                            final updatedAddr = Address(
                                              id: existingAddress.id,
                                              type: _addressType,
                                              addressLine: _addressLineController.text,
                                              city: cityVal,
                                              state: _selectedState,
                                              zipCode: _zipCodeController.text.isNotEmpty ? _zipCodeController.text : "641001",
                                              phoneNumber: _phoneController.text,
                                            );
                                            addressProvider.updateAddress(existingAddress.id, updatedAddr, token);
                                          } else {
                                            final newAddr = Address(
                                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                                              type: _addressType,
                                              addressLine: _addressLineController.text,
                                              city: cityVal,
                                              state: _selectedState,
                                              zipCode: _zipCodeController.text.isNotEmpty ? _zipCodeController.text : "641001",
                                              phoneNumber: _phoneController.text,
                                            );
                                            addressProvider.addAddress(newAddr, token);
                                          }

                                          Navigator.pop(context);

                                          if (widget.isCheckoutMode) {
                                            final selAddr = addressProvider.selectedAddress ?? (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.last : null);
                                            if (selAddr != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PaymentScreen(
                                                    selectedAddress: selAddr,
                                                    totalMrp: widget.totalMrp,
                                                    discount: widget.discount,
                                                    deliveryCharge: widget.deliveryCharge,
                                                    toPay: widget.toPay,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      child: Text(
                                        "Submit",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935), // Bright vibrant Red
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Back",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    final addresses = addressProvider.addresses;
    final selected = addressProvider.selectedAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5722),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Address",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWeb ? 800 : double.infinity,
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: isWeb ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deliver To Header
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Deliver To",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF5722)),
                                onPressed: () {
                                  if (auth.isGuest) {
                                    showGuestAuthPrompt(context, "Please log in or register to add a new address.");
                                    return;
                                  }
                                  _showAddAddressSheet(addressProvider);
                                },
                              ),
                            ],
                          ),
                        ),

                        // List of Address cards
                        if (addresses.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                "No saved addresses yet.",
                                style: GoogleFonts.outfit(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final addr = addresses[index];
                              final isSelected = selected?.id == addr.id;

                              final isHome = addr.type.toLowerCase() == 'home';
                              final avatarColor = isHome ? const Color(0xFFFF5722) : Colors.grey[600]!;

                              return GestureDetector(
                                onTap: () {
                                  addressProvider.selectAddress(addr);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFFF5722) : Colors.grey[300]!,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: avatarColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isHome ? Icons.location_on_rounded : Icons.work_rounded,
                                          color: avatarColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              addr.type,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              addr.formattedAddress,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              addr.phoneNumber,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          if (auth.isGuest) {
                                            showGuestAuthPrompt(context, "Please log in or register to edit addresses.");
                                            return;
                                          }
                                          _showAddAddressSheet(addressProvider, existingAddress: addr);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 10),

                        // Outlined Add New Address Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (auth.isGuest) {
                                  showGuestAuthPrompt(context, "Please log in or register to add a new address.");
                                  return;
                                }
                                _showAddAddressSheet(addressProvider);
                              },
                              child: Text(
                                "+ Add New Address",
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5722),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Checkout action bottom bar if checkout mode
                        if (widget.isCheckoutMode && selected != null) ...[
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Delivering to ${selected.type}",
                                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Total: ₹${widget.toPay.toStringAsFixed(0)}",
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5722),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentScreen(
                                            selectedAddress: selected,
                                            totalMrp: widget.totalMrp,
                                            discount: widget.discount,
                                            deliveryCharge: widget.deliveryCharge,
                                            toPay: widget.toPay,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Proceed to Payment",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
