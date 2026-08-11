import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/api_service.dart';
import '../../utils/whatsapp_helper.dart';


class WholesaleEnquiryScreen extends StatefulWidget {
  const WholesaleEnquiryScreen({super.key});

  @override
  State<WholesaleEnquiryScreen> createState() => _WholesaleEnquiryScreenState();
}

class _WholesaleEnquiryScreenState extends State<WholesaleEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _messageController = TextEditingController();
  
  // List of selected product items with their corresponding quantity controllers
  final List<Map<String, dynamic>> _selectedItems = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start with 1 empty item row
    _addItemRow();
    
    // Fetch products and address info on load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      productProvider.fetchProducts();

      if (authProvider.user != null && authProvider.user!.token != null) {
        await addressProvider.fetchAddresses(authProvider.user!.token!);
        final defaultAddress = addressProvider.selectedAddress;
        if (defaultAddress != null) {
          setState(() {
            _addressController.text = defaultAddress.addressLine;
            if (defaultAddress.city.isNotEmpty) {
              _addressController.text += ", ${defaultAddress.city}";
            }
            if (defaultAddress.state.isNotEmpty) {
              _addressController.text += ", ${defaultAddress.state}";
            }
            _pincodeController.text = defaultAddress.zipCode;
            if (_phoneController.text.isEmpty && defaultAddress.phoneNumber.isNotEmpty) {
              _phoneController.text = defaultAddress.phoneNumber;
            }
          });
        }

        setState(() {
          if (_businessNameController.text.isEmpty && authProvider.user!.name.isNotEmpty) {
            _businessNameController.text = authProvider.user!.name;
          }
          if (_phoneController.text.isEmpty && authProvider.user!.phone.isNotEmpty) {
            _phoneController.text = authProvider.user!.phone;
          }
        });
      }
    });
  }

  void _addItemRow() {
    setState(() {
      _selectedItems.add({
        'productName': null,
        'qtyController': TextEditingController(text: '100'), // Default wholesale qty
      });
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _selectedItems[index]['qtyController'].dispose();
      _selectedItems.removeAt(index);
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _messageController.dispose();
    for (var item in _selectedItems) {
      item['qtyController'].dispose();
    }
    super.dispose();
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate that all item rows have a product selected and valid quantity
    for (int i = 0; i < _selectedItems.length; i++) {
      final item = _selectedItems[i];
      if (item['productName'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please select a product for Item #${i + 1}"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      final qtyText = item['qtyController'].text.trim();
      final qty = int.tryParse(qtyText);
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter a valid quantity for Item #${i + 1}"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.user?.token;

    final List<Map<String, dynamic>> itemsPayload = _selectedItems.map((item) {
      return {
        'productName': item['productName'],
        'qty': int.parse(item['qtyController'].text.trim()),
      };
    }).toList();

    final enquiryData = {
      'businessName': _businessNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'items': itemsPayload,
      'address': _addressController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'requirements': _messageController.text.trim(),
    };

    try {
      final response = await ApiService.post('wholesale', enquiryData, token: token);
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Enquiry sent successfully!",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to submit enquiry. Please try again.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

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
          "Wholesale Enquiry",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bulk Order Inquiries",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF8C00), // Theme Orange
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you a retailer? Contact us for special wholesale pricing on bulk orders.",
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                
                // Business Name Field
                TextFormField(
                  controller: _businessNameController,
                  style: GoogleFonts.outfit(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Business Name",
                    labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Business Name is required" : null,
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.outfit(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Phone number is required";
                    if (value.length < 10) return "Enter a valid 10-digit number";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Section Title & Add Button for Products
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Inquired Products / Items",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addItemRow,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFFFF8C00)),
                      label: Text(
                        "Add Item",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF8C00),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Selected Items list
                if (productProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
                    ),
                  )
                else
                  Column(
                    children: List.generate(_selectedItems.length, (index) {
                      final item = _selectedItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: item['productName'],
                                hint: Text("Select Product", style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13)),
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                                items: products.map((product) {
                                  final displayName = product.tamilName.isNotEmpty
                                      ? "${product.name} (${product.tamilName})"
                                      : product.name;
                                  return DropdownMenuItem<String>(
                                    value: product.name,
                                    child: Text(
                                      displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    item['productName'] = value;
                                  });
                                },
                                validator: (value) => value == null ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Quantity Field
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: item['qtyController'],
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: "Qty",
                                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) return "Required";
                                  final val = int.tryParse(value);
                                  if (val == null || val <= 0) return "Min 1";
                                  return null;
                                },
                              ),
                            ),

                            // Delete Button
                            if (_selectedItems.length > 1) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                onPressed: () => _removeItemRow(index),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  style: GoogleFonts.outfit(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Shipping Address",
                    labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Address is required" : null,
                ),
                const SizedBox(height: 16),

                // Pincode Field
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Pincode",
                    labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Pincode is required";
                    if (value.length < 6) return "Enter a valid 6-digit pincode";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Requirements (Detailed message) Field
                TextFormField(
                  maxLines: 4,
                  controller: _messageController,
                  style: GoogleFonts.outfit(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Your Requirements (Items, Quantity)",
                    labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter your requirements" : null,
                ),
                // Send via WhatsApp Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    label: Text(
                      "Send Bulk Order via WhatsApp 💬",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final itemsPayload = _selectedItems.map((item) {
                        return {
                          'name': item['productName'] ?? 'Product',
                          'quantity': item['qtyController'].text.trim(),
                        };
                      }).toList();

                      WhatsAppHelper.launchBulkOrderEnquiry(
                        name: _businessNameController.text.trim().isNotEmpty
                            ? _businessNameController.text.trim()
                            : "Wholesale Buyer",
                        phone: _phoneController.text.trim(),
                        city: _addressController.text.trim().isNotEmpty
                            ? _addressController.text.trim()
                            : "Tamil Nadu",
                        notes: _messageController.text.trim(),
                        items: itemsPayload,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitEnquiry,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            "Submit Enquiry",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
