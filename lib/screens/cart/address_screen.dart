import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!.token != null) {
        Provider.of<AddressProvider>(context, listen: false)
            .fetchAddresses(auth.user!.token!);
      }
    });
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<List<String>> _getPlacesSuggestions(String query) async {
    print("[Autocomplete Log] Calling _getPlacesSuggestions with query: '$query'");
    if (query.trim().isEmpty) return [];
    try {
      final url = 'addresses/autocomplete?query=${Uri.encodeComponent(query.trim())}';
      print("[Autocomplete Log] Request URL: $url");
      final response = await ApiService.get(url);
      print("[Autocomplete Log] Response status: ${response.statusCode}");
      print("[Autocomplete Log] Response body: ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final suggestions = data.map((item) => item.toString()).toList();
        print("[Autocomplete Log] Parsed suggestions: $suggestions");
        return suggestions;
      }
    } catch (e) {
      print("[Autocomplete Log] Error fetching places from backend: $e");
    }
    return [];
  }

  void _showAddAddressSheet(AddressProvider addressProvider, {Address? existingAddress}) {
    List<String> suggestions = [];
    bool isSearching = false;
    Timer? debounceTimer;
    String activeField = ''; // 'addressLine' or 'city'

    if (existingAddress != null) {
      _addressLineController.text = existingAddress.addressLine;
      _cityController.text = existingAddress.city;
      _stateController.text = existingAddress.state;
      _zipCodeController.text = existingAddress.zipCode;
      _phoneController.text = existingAddress.phoneNumber;
      _addressType = existingAddress.type;
    } else {
      _addressLineController.clear();
      _cityController.clear();
      _stateController.clear();
      _zipCodeController.clear();
      _phoneController.clear();
      _addressType = 'Home';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSuggestionsDropdown() {
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                        title: Text(
                          suggestion,
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          final parts = suggestion.split(',').map((p) => p.trim()).toList();
                          if (parts.isNotEmpty && parts.last.toLowerCase() == 'india') {
                            parts.removeLast();
                          }
                          
                          String state = '';
                          String zip = '';
                          if (parts.isNotEmpty) {
                            final statePart = parts.removeLast();
                            final zipRegExp = RegExp(r'\d{6}');
                            final match = zipRegExp.firstMatch(statePart);
                            if (match != null) {
                              zip = match.group(0)!;
                              state = statePart.replaceAll(zip, '').trim();
                            } else {
                              state = statePart;
                            }
                          }
                          
                          String city = '';
                          if (parts.isNotEmpty) {
                            city = parts.removeLast();
                          }
                          
                          String addressLine = parts.join(', ');
                          
                          setModalState(() {
                            _addressLineController.text = addressLine.isEmpty ? city : addressLine;
                            _cityController.text = city;
                            _stateController.text = state;
                            _zipCodeController.text = zip;
                            suggestions.clear();
                            activeField = '';
                          });
                        },
                      );
                    },
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existingAddress != null ? "Edit Address" : "Add New Address",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Type selector
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Home"),
                            selected: _addressType == 'Home',
                            selectedColor: const Color(0xFFFF8C00).withOpacity(0.15),
                            labelStyle: GoogleFonts.outfit(
                              color: _addressType == 'Home' ? const Color(0xFFFF8C00) : Colors.black87,
                              fontWeight: _addressType == 'Home' ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => _addressType = 'Home');
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text("Office"),
                            selected: _addressType == 'Office',
                            selectedColor: const Color(0xFFFF8C00).withOpacity(0.15),
                            labelStyle: GoogleFonts.outfit(
                              color: _addressType == 'Office' ? const Color(0xFFFF8C00) : Colors.black87,
                              fontWeight: _addressType == 'Office' ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => _addressType = 'Office');
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text("Other"),
                            selected: _addressType == 'Other',
                            selectedColor: const Color(0xFFFF8C00).withOpacity(0.15),
                            labelStyle: GoogleFonts.outfit(
                              color: _addressType == 'Other' ? const Color(0xFFFF8C00) : Colors.black87,
                              fontWeight: _addressType == 'Other' ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => _addressType = 'Other');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressLineController,
                        onChanged: (val) {
                          print("[Autocomplete Log] Address Line onChanged fired with text: '$val'");
                          if (debounceTimer?.isActive ?? false) {
                            print("[Autocomplete Log] Cancelling active debounce timer");
                            debounceTimer!.cancel();
                          }
                          debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                            print("[Autocomplete Log] Debounce timer triggered for Address Line query: '${val.trim()}'");
                            if (val.trim().isEmpty) {
                              setModalState(() {
                                suggestions = [];
                                activeField = '';
                              });
                              return;
                            }
                            setModalState(() {
                              isSearching = true;
                              activeField = 'addressLine';
                            });
                            final fetched = await _getPlacesSuggestions(val.trim());
                            print("[Autocomplete Log] Fetched for Address Line: $fetched");
                            setModalState(() {
                              suggestions = fetched;
                              isSearching = false;
                            });
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Address Line",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                          ),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address line' : null,
                      ),
                      if (activeField == 'addressLine') ...[
                        if (isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00)),
                              ),
                            ),
                          ),
                        buildSuggestionsDropdown(),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              onChanged: (val) {
                                print("[Autocomplete Log] City onChanged fired with text: '$val'");
                                if (debounceTimer?.isActive ?? false) {
                                  print("[Autocomplete Log] Cancelling active debounce timer");
                                  debounceTimer!.cancel();
                                }
                                debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                                  print("[Autocomplete Log] Debounce timer triggered for City query: '${val.trim()}'");
                                  if (val.trim().isEmpty) {
                                    setModalState(() {
                                      suggestions = [];
                                      activeField = '';
                                    });
                                    return;
                                  }
                                  setModalState(() {
                                    isSearching = true;
                                    activeField = 'city';
                                  });
                                  final fetched = await _getPlacesSuggestions(val.trim());
                                  print("[Autocomplete Log] Fetched for City: $fetched");
                                  setModalState(() {
                                    suggestions = fetched;
                                    isSearching = false;
                                  });
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "City",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: "State",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter state' : null,
                            ),
                          ),
                        ],
                      ),
                      if (activeField == 'city') ...[
                        if (isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00)),
                              ),
                            ),
                          ),
                        buildSuggestionsDropdown(),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _zipCodeController,
                              decoration: InputDecoration(
                                labelText: "Zip Code",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter zip' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final token = auth.user?.token ?? '';
                              if (existingAddress != null) {
                                final updatedAddr = Address(
                                  id: existingAddress.id,
                                  type: _addressType,
                                  addressLine: _addressLineController.text,
                                  city: _cityController.text,
                                  state: _stateController.text,
                                  zipCode: _zipCodeController.text,
                                  phoneNumber: _phoneController.text,
                                );
                                addressProvider.updateAddress(existingAddress.id, updatedAddr, token);
                              } else {
                                final newAddr = Address(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  type: _addressType,
                                  addressLine: _addressLineController.text,
                                  city: _cityController.text,
                                  state: _stateController.text,
                                  zipCode: _zipCodeController.text,
                                  phoneNumber: _phoneController.text,
                                );
                                addressProvider.addAddress(newAddr, token);
                              }
                              // Clear fields
                              _addressLineController.clear();
                              _cityController.clear();
                              _stateController.clear();
                              _zipCodeController.clear();
                              _phoneController.clear();
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            existingAddress != null ? "Save Changes" : "Save Address",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                      if (existingAddress != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Delete Address", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  content: Text("Are you sure you want to delete this address?", style: GoogleFonts.outfit()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text("Delete", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                final token = auth.user?.token ?? '';
                                await addressProvider.removeAddress(existingAddress.id, token);
                                _addressLineController.clear();
                                _cityController.clear();
                                _stateController.clear();
                                _zipCodeController.clear();
                                _phoneController.clear();
                                Navigator.pop(context); // Close sheet
                              }
                            },
                            child: Text(
                              "Delete Address",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    final addresses = addressProvider.addresses;
    final selected = addressProvider.selectedAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Theme background color
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
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
                        // Deliver To / Header Title
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                          child: Text(
                            "Deliver To",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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
                              final avatarColor = isHome ? const Color(0xFFFF8C00) : Colors.grey[600]!;

                              return GestureDetector(
                                onTap: () {
                                  addressProvider.selectAddress(addr);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[100]!,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.01),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Icon Avatar
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
                                      // Address lines
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
                                            const SizedBox(height: 6),
                                            Text(
                                              addr.formattedAddress,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
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
                                      // Right Edit Button
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.grey[500],
                                          size: 20,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
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

                        // Outlined Add New Address Button (matches mockup)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showAddAddressSheet(addressProvider),
                              child: Text(
                                "Add New Address",
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5722),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // If checkout mode, persistent select & checkout action block
                        if (widget.isCheckoutMode && selected != null) ...[
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
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
                                      backgroundColor: const Color(0xFFFF8C00),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
