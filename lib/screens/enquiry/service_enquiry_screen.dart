import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/api_service.dart';

class ServiceEnquiryScreen extends StatefulWidget {
  final String initialType; // 'solar', 'photography', 'transport'
  const ServiceEnquiryScreen({super.key, this.initialType = 'solar'});

  @override
  State<ServiceEnquiryScreen> createState() => _ServiceEnquiryScreenState();
}

class _ServiceEnquiryScreenState extends State<ServiceEnquiryScreen> {
  late String _selectedType;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Common User Details Controllers
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  // 1. Solar Fields
  String? _solarState = 'Tamil Nadu';
  String? _solarDistrict = 'Coimbatore';
  String? _solarCity = 'Coimbatore';
  final _solarFullAddressController = TextEditingController();
  final _solarPincodeController = TextEditingController();
  String? _solarPropertyType = 'Residential';
  String? _solarRooftopOrGround = 'Rooftop';
  final _solarEbBillController = TextEditingController();
  String? _solarRequiredCapacity = '3-5 kW';
  String? _solarSystemType = 'On-grid';
  String? _solarInstallationTime = 'Within 1 month';
  String? _ebBillFileName;
  String? _roofPhotoFileName;

  // 2. Photography Fields
  String? _photoEventType = 'Wedding';
  DateTime? _photoEventDate;
  TimeOfDay? _photoStartTime;
  TimeOfDay? _photoEndTime;
  final _photoVenueNameController = TextEditingController();
  String? _photoCity = 'Coimbatore';
  final _photoMapLocationController = TextEditingController();
  final List<String> _photoServicesRequired = ['Photography', 'Cinematography'];
  String? _photoBudgetRange = '₹50,000 - ₹1,00,000';
  String? _invitationFileName;

  // 3. Transport Fields
  final _transPickupAddressController = TextEditingController();
  final _transPickupPincodeController = TextEditingController();
  final _transDeliveryAddressController = TextEditingController();
  final _transDeliveryPincodeController = TextEditingController();
  String? _transMaterialType = 'Boxes / Parcels';
  String? _transWeight = '100 - 500 kg';
  String? _transVehicleRequired = 'Mini Truck (Tata Ace)';
  String _transLoadingRequired = 'Yes';
  String _transUnloadingRequired = 'Yes';
  String _transInsuranceRequired = 'No';
  DateTime? _transPickupDate;
  DateTime? _transDeliveryDate;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      if (auth.user != null) {
        setState(() {
          _fullNameController.text = auth.user!.name;
          _mobileController.text = auth.user!.phone;
          _whatsappController.text = auth.user!.phone;
          _emailController.text = auth.user!.email;
        });

        if (auth.user!.token != null) {
          await addressProvider.fetchAddresses(auth.user!.token!);
          final addr = addressProvider.selectedAddress;
          if (addr != null) {
            setState(() {
              _solarFullAddressController.text = addr.addressLine;
              _solarPincodeController.text = addr.zipCode;
              _transPickupAddressController.text = "${addr.addressLine}, ${addr.city}";
              _transPickupPincodeController.text = addr.zipCode;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _solarFullAddressController.dispose();
    _solarPincodeController.dispose();
    _solarEbBillController.dispose();
    _photoVenueNameController.dispose();
    _photoMapLocationController.dispose();
    _transPickupAddressController.dispose();
    _transPickupPincodeController.dispose();
    _transDeliveryAddressController.dispose();
    _transDeliveryPincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (type == 'ebBill') _ebBillFileName = image.name;
          if (type == 'roofPhoto') _roofPhotoFileName = image.name;
          if (type == 'invitation') _invitationFileName = image.name;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.user?.token;

    final Map<String, dynamic> payload = {
      'enquiryType': _selectedType,
      'fullName': _fullNameController.text.trim(),
      'mobileNumber': _mobileController.text.trim(),
      'whatsappNumber': _whatsappController.text.trim(),
      'email': _emailController.text.trim(),
      'additionalNotes': _notesController.text.trim(),
    };

    if (_selectedType == 'solar') {
      payload.addAll({
        'state': _solarState,
        'district': _solarDistrict,
        'city': _solarCity,
        'fullAddress': _solarFullAddressController.text.trim(),
        'pincode': _solarPincodeController.text.trim(),
        'propertyType': _solarPropertyType,
        'rooftopOrGround': _solarRooftopOrGround,
        'monthlyEbBill': _solarEbBillController.text.trim(),
        'requiredCapacity': _solarRequiredCapacity,
        'systemType': _solarSystemType,
        'installationTime': _solarInstallationTime,
        'ebBillFile': _ebBillFileName,
        'roofPhotoFile': _roofPhotoFileName,
      });
    } else if (_selectedType == 'photography') {
      payload.addAll({
        'eventType': _photoEventType,
        'eventDate': _photoEventDate != null ? DateFormat('dd/MM/yyyy').format(_photoEventDate!) : null,
        'startTime': _photoStartTime != null ? _photoStartTime!.format(context) : null,
        'endTime': _photoEndTime != null ? _photoEndTime!.format(context) : null,
        'venueName': _photoVenueNameController.text.trim(),
        'city': _photoCity,
        'googleMapLocation': _photoMapLocationController.text.trim(),
        'servicesRequired': _photoServicesRequired,
        'budgetRange': _photoBudgetRange,
        'invitationFile': _invitationFileName,
      });
    } else if (_selectedType == 'transport') {
      payload.addAll({
        'pickupAddress': _transPickupAddressController.text.trim(),
        'pickupPincode': _transPickupPincodeController.text.trim(),
        'deliveryAddress': _transDeliveryAddressController.text.trim(),
        'deliveryPincode': _transDeliveryPincodeController.text.trim(),
        'materialType': _transMaterialType,
        'weight': _transWeight,
        'vehicleRequired': _transVehicleRequired,
        'loadingRequired': _transLoadingRequired,
        'unloadingRequired': _transUnloadingRequired,
        'insuranceRequired': _transInsuranceRequired,
        'pickupDate': _transPickupDate != null ? DateFormat('dd/MM/yyyy').format(_transPickupDate!) : null,
        'deliveryDate': _transDeliveryDate != null ? DateFormat('dd/MM/yyyy').format(_transDeliveryDate!) : null,
      });
    }

    try {
      final response = await ApiService.post('service-enquiries', payload, token: token);
      if (response.statusCode == 201) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                  const SizedBox(width: 10),
                  Text("Enquiry Submitted!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                "Thank you for reaching out! Our team will contact you shortly regarding your ${_selectedType.toUpperCase()} requirement.",
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close screen
                  },
                  child: Text("OK", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color get _themeColor {
    switch (_selectedType) {
      case 'solar': return const Color(0xFFFF8C00); // Orange
      case 'photography': return const Color(0xFF8B5CF6); // Purple
      case 'transport': return const Color(0xFF10B981); // Green
      default: return const Color(0xFFFF8C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: _themeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Send Your Enquiry",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
                      maxWidth: isWeb ? 1000 : double.infinity,
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Subtitle
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "✨ Send Your Enquiry – We'll Contact You Soon! ✨",
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Service Tabs Selector
                        Row(
                          children: [
                            Expanded(child: _buildServiceTab('solar', 'Solar', Icons.wb_sunny_rounded, const Color(0xFFFF8C00))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildServiceTab('photography', 'Photography', Icons.camera_alt_rounded, const Color(0xFF8B5CF6))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildServiceTab('transport', 'Transport', Icons.local_shipping_rounded, const Color(0xFF10B981))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main Card Form
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _themeColor.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Card Banner Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: _themeColor.withOpacity(0.08),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _selectedType == 'solar' ? Icons.wb_sunny_rounded :
                                            _selectedType == 'photography' ? Icons.camera_alt_rounded : Icons.local_shipping_rounded,
                                            color: _themeColor, size: 28,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _selectedType == 'solar' ? "Solar Enquiry" :
                                            _selectedType == 'photography' ? "Photography Enquiry" : "Transport Enquiry",
                                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: _themeColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedType == 'solar' ? "Home & Commercial Solar Installation" :
                                        _selectedType == 'photography' ? "Wedding • Events • Birthday • Corporate & More" :
                                        "Parcel • Full Load • Mini Truck • Container & More",
                                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ── SECTION: Your Details ──
                                      _buildSectionHeader("Your Details"),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(child: _buildTextField("Full Name *", _fullNameController, required: true)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildTextField("Mobile Number *", _mobileController, isPhone: true, required: true)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(child: _buildTextField("WhatsApp Number", _whatsappController, isPhone: true)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildTextField("Email", _emailController, isEmail: true)),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // ── TYPE SPECIFIC FIELDS ──
                                      if (_selectedType == 'solar') _buildSolarForm(),
                                      if (_selectedType == 'photography') _buildPhotographyForm(),
                                      if (_selectedType == 'transport') _buildTransportForm(),

                                      const SizedBox(height: 20),
                                      // ── SECTION: Additional Notes ──
                                      _buildSectionHeader("Additional Notes"),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _notesController,
                                        maxLines: 3,
                                        style: GoogleFonts.outfit(fontSize: 13),
                                        decoration: _inputDecoration("Enter any additional notes..."),
                                      ),
                                      const SizedBox(height: 24),

                                      // Submit Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _themeColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            elevation: 2,
                                          ),
                                          onPressed: _isSubmitting ? null : _submitEnquiry,
                                          child: _isSubmitting
                                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                              : Text(
                                                  "Submit Enquiry",
                                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Text(
                                          _selectedType == 'solar' ? "Our Solar Expert will contact you within 24 hours." :
                                          _selectedType == 'photography' ? "Our Team will contact you soon." :
                                          "Our Transport Team will contact you soon.",
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildServiceTab(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _themeColor),
        ),
        const SizedBox(height: 4),
        Container(width: 36, height: 2.5, decoration: BoxDecoration(color: _themeColor, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPhone = false, bool isEmail = false, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: GoogleFonts.outfit(fontSize: 13),
          decoration: _inputDecoration("Enter ${label.replaceAll('*', '').trim().toLowerCase()}"),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Required" : null : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _themeColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  // 1. SOLAR FORM WIDGETS
  Widget _buildSolarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Location"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("State", _solarState, ['Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh'], (v) => setState(() => _solarState = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("District", _solarDistrict, ['Coimbatore', 'Chennai', 'Madurai', 'Sivakasi', 'Salem', 'Trichy'], (v) => setState(() => _solarDistrict = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown("City", _solarCity, ['Coimbatore', 'Chennai', 'Madurai', 'Sivakasi', 'Salem', 'Trichy'], (v) => setState(() => _solarCity = v)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildTextField("Full Address", _solarFullAddressController)),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: _buildTextField("Pincode", _solarPincodeController, isPhone: true)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Requirement Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Property Type", _solarPropertyType, ['Residential', 'Commercial', 'Industrial', 'Agricultural'], (v) => setState(() => _solarPropertyType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Rooftop / Ground", _solarRooftopOrGround, ['Rooftop', 'Ground Mount', 'Both'], (v) => setState(() => _solarRooftopOrGround = v))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Monthly EB Bill (₹)", _solarEbBillController, isPhone: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Required Capacity", _solarRequiredCapacity, ['1-3 kW', '3-5 kW', '5-10 kW', '10-25 kW', '25+ kW'], (v) => setState(() => _solarRequiredCapacity = v))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("System Type", _solarSystemType, ['On-grid', 'Off-grid', 'Hybrid'], (v) => setState(() => _solarSystemType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Installation Time", _solarInstallationTime, ['Immediate (within 1 week)', 'Within 1 month', '1-3 months', 'Just Exploring'], (v) => setState(() => _solarInstallationTime = v))),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Upload Documents"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildFileUploadBox("Upload EB Bill", _ebBillFileName, () => _pickImage('ebBill'))),
            const SizedBox(width: 12),
            Expanded(child: _buildFileUploadBox("Upload Roof Photo", _roofPhotoFileName, () => _pickImage('roofPhoto'))),
          ],
        ),
      ],
    );
  }

  // 2. PHOTOGRAPHY FORM WIDGETS
  Widget _buildPhotographyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Event Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Event Type", _photoEventType, ['Wedding', 'Reception', 'Birthday', 'Corporate', 'Baby Shower', 'Pre/Post Wedding', 'Others'], (v) => setState(() => _photoEventType = v))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Event Date", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setState(() => _photoEventDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_photoEventDate != null ? DateFormat('dd/MM/yyyy').format(_photoEventDate!) : "dd/mm/yyyy", style: GoogleFonts.outfit(fontSize: 12, color: _photoEventDate != null ? Colors.black87 : Colors.grey[400])),
                          Icon(Icons.calendar_today_rounded, size: 16, color: _themeColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTimePicker("Start Time", _photoStartTime, (t) => setState(() => _photoStartTime = t))),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker("End Time", _photoEndTime, (t) => setState(() => _photoEndTime = t))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Venue Name", _photoVenueNameController)),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("City", _photoCity, ['Coimbatore', 'Chennai', 'Madurai', 'Sivakasi', 'Salem', 'Trichy'], (v) => setState(() => _photoCity = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Google Map Location (Link / Name)", _photoMapLocationController),
        const SizedBox(height: 20),

        _buildSectionHeader("Services Required"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Photography', 'Cinematography', 'Drone', 'LED Wall', 'Live Streaming', 'Album', 'Photo Frame', 'Reels', 'Pre Wedding', 'Post Wedding', 'Others'].map((srv) {
            final isChecked = _photoServicesRequired.contains(srv);
            return FilterChip(
              label: Text(srv, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal, color: isChecked ? Colors.white : Colors.black87)),
              selected: isChecked,
              selectedColor: _themeColor,
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _photoServicesRequired.add(srv);
                  } else {
                    _photoServicesRequired.remove(srv);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: _buildDropdown("Budget Range", _photoBudgetRange, ['Below ₹25,000', '₹25,000 - ₹50,000', '₹50,000 - ₹1,00,000', '₹1,00,000 - ₹2,00,000', '₹2,00,000+'], (v) => setState(() => _photoBudgetRange = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildFileUploadBox("Upload Invitation (Optional)", _invitationFileName, () => _pickImage('invitation'))),
          ],
        ),
      ],
    );
  }

  // 3. TRANSPORT FORM WIDGETS
  Widget _buildTransportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Pickup Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildTextField("Pickup Address *", _transPickupAddressController, required: true)),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: _buildTextField("Pickup Pincode *", _transPickupPincodeController, isPhone: true, required: true)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Delivery Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildTextField("Delivery Address *", _transDeliveryAddressController, required: true)),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: _buildTextField("Delivery Pincode *", _transDeliveryPincodeController, isPhone: true, required: true)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Material & Vehicle Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Material Type", _transMaterialType, ['Boxes / Parcels', 'Industrial Goods', 'Household Goods', 'Agricultural Products', 'Crackers / Fireworks', 'Others'], (v) => setState(() => _transMaterialType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Weight", _transWeight, ['Below 100 kg', '100 - 500 kg', '500 kg - 1 Ton', '1 - 3 Tons', '3 - 10 Tons', '10+ Tons'], (v) => setState(() => _transWeight = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown("Vehicle Required", _transVehicleRequired, ['Mini Truck (Tata Ace)', 'Pickup (Bolero)', 'Medium Truck (Eicher)', 'Large Truck (Container)', 'Any Available'], (v) => setState(() => _transVehicleRequired = v)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildRadioOption("Loading Required?", _transLoadingRequired, (v) => setState(() => _transLoadingRequired = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildRadioOption("Unloading Required?", _transUnloadingRequired, (v) => setState(() => _transUnloadingRequired = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildRadioOption("Insurance Required?", _transInsuranceRequired, (v) => setState(() => _transInsuranceRequired = v))),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pickup Date", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setState(() => _transPickupDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_transPickupDate != null ? DateFormat('dd/MM/yyyy').format(_transPickupDate!) : "dd/mm/yyyy", style: GoogleFonts.outfit(fontSize: 12, color: _transPickupDate != null ? Colors.black87 : Colors.grey[400])),
                          Icon(Icons.calendar_today_rounded, size: 16, color: _themeColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Delivery Date", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setState(() => _transDeliveryDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_transDeliveryDate != null ? DateFormat('dd/MM/yyyy').format(_transDeliveryDate!) : "dd/mm/yyyy", style: GoogleFonts.outfit(fontSize: 12, color: _transDeliveryDate != null ? Colors.black87 : Colors.grey[400])),
                          Icon(Icons.calendar_today_rounded, size: 16, color: _themeColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // HELPER WIDGETS
  Widget _buildDropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87),
          isExpanded: true,
          decoration: _inputDecoration("Select"),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? value, ValueChanged<TimeOfDay> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value != null ? value.format(context) : "Select Time", style: GoogleFonts.outfit(fontSize: 12, color: value != null ? Colors.black87 : Colors.grey[400])),
                Icon(Icons.access_time_rounded, size: 16, color: _themeColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadBox(String label, String? fileName, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid)),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, color: _themeColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  fileName ?? "Upload Image / PDF",
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: fileName != null ? Colors.black87 : Colors.grey[500]),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String selectedVal, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Row(
          children: ['Yes', 'No'].map((opt) {
            final isSel = selectedVal == opt;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? _themeColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(opt, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
