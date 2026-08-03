import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

class ServiceEnquiryScreen extends StatefulWidget {
  final String initialType; // 'solar', 'photography', 'transport', 'real-estate', 'website'
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

  // 4. Real Estate Fields
  String _reLookingFor = 'Buy'; // 'Buy', 'Sell', 'Rent', 'Plot'
  String? _rePropertyCategory = 'Apartment / Flat';
  String? _reBhkType = '2 BHK';
  String? _reBudgetRange = '₹25 - 50 Lakhs';
  String? _reAreaSqFt;
  final _rePreferredLocationController = TextEditingController();
  final _reLandmarkLocalityController = TextEditingController();
  String? _reFurnishing = 'Any';
  String? _reFacing = 'Any';
  String? _reFloorPreference = 'Any';
  String? _rePropertyAge = 'Any';
  final List<String> _reAmenities = [];
  String? _rePreferredContactTime = 'Any Time';
  String? _reDocumentFileName;

  // 5. Website Fields
  final _webBusinessNameController = TextEditingController();
  String? _webBusinessType = 'Retail / Shop';
  String? _webIndustryCategory = 'E-Commerce';
  final _webExistingWebsiteController = TextEditingController();
  String _webWebsiteType = 'Static Website (Informational)';
  final List<String> _webWebsitePurpose = ['Business / Company Profile'];
  final List<String> _webWebsiteFeatures = ['Responsive (Mobile Friendly)', 'Contact / Enquiry Form', 'SEO Optimization'];
  String? _webDesignPreference = 'Modern & Sleek';
  final _webColorPreferenceController = TextEditingController();
  final _webReferenceWebsiteController = TextEditingController();
  String _webContentReady = 'No';
  String? _webEstimatedBudget = '₹10,000 - ₹25,000';
  String? _webRequiredTimeframe = '2-3 Weeks';
  String _webHasDomainHosting = 'No';
  String? _webPreferredContactTime = 'Any Time';
  String? _webReferenceFileName;

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
              _rePreferredLocationController.text = addr.city;
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
    _rePreferredLocationController.dispose();
    _reLandmarkLocalityController.dispose();
    _webBusinessNameController.dispose();
    _webExistingWebsiteController.dispose();
    _webColorPreferenceController.dispose();
    _webReferenceWebsiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final String base64DataUrl = "data:image/jpeg;base64,${base64Encode(bytes)}";
        setState(() {
          if (type == 'ebBill') _ebBillFileName = base64DataUrl;
          if (type == 'roofPhoto') _roofPhotoFileName = base64DataUrl;
          if (type == 'invitation') _invitationFileName = base64DataUrl;
          if (type == 'realEstateDoc') _reDocumentFileName = base64DataUrl;
          if (type == 'webReference') _webReferenceFileName = base64DataUrl;
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

    final String fullName = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : (auth.user?.name.isNotEmpty == true ? auth.user!.name : 'Customer');
    final String mobileNumber = _mobileController.text.trim().isNotEmpty
        ? _mobileController.text.trim()
        : (auth.user?.phone.isNotEmpty == true ? auth.user!.phone : '9442136010');

    final Map<String, dynamic> payload = {
      'enquiryType': _selectedType,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
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
    } else if (_selectedType == 'real-estate') {
      payload.addAll({
        'lookingFor': _reLookingFor,
        'propertyCategory': _rePropertyCategory,
        'bhkType': _reBhkType,
        'budgetRange': _reBudgetRange,
        'areaSqFt': _reAreaSqFt,
        'preferredLocation': _rePreferredLocationController.text.trim(),
        'landmarkLocality': _reLandmarkLocalityController.text.trim(),
        'furnishing': _reFurnishing,
        'facing': _reFacing,
        'floorPreference': _reFloorPreference,
        'propertyAge': _rePropertyAge,
        'amenities': _reAmenities,
        'preferredContactTime': _rePreferredContactTime,
        'propertyDocumentFile': _reDocumentFileName,
      });
    } else if (_selectedType == 'website') {
      payload.addAll({
        'businessName': _webBusinessNameController.text.trim(),
        'businessType': _webBusinessType,
        'industryCategory': _webIndustryCategory,
        'existingWebsite': _webExistingWebsiteController.text.trim(),
        'websiteType': _webWebsiteType,
        'websitePurpose': _webWebsitePurpose,
        'websiteFeatures': _webWebsiteFeatures,
        'designPreference': _webDesignPreference,
        'colorPreference': _webColorPreferenceController.text.trim(),
        'referenceWebsite': _webReferenceWebsiteController.text.trim(),
        'contentReady': _webContentReady,
        'estimatedBudget': _webEstimatedBudget,
        'requiredTimeframe': _webRequiredTimeframe,
        'hasDomainHosting': _webHasDomainHosting,
        'preferredContactTime': _webPreferredContactTime,
        'websiteReferenceFile': _webReferenceFileName,
      });
    }

    try {
      final response = await ApiService.post('service-enquiries', payload, token: token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: _themeColor, size: 28),
                  const SizedBox(width: 10),
                  const Text("Enquiry Submitted!"),
                ],
              ),
              content: const Text("Thank you! Our dedicated service team will review your requirements and reach out to you shortly."),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Done"),
                )
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          String errMsg = "Failed (${response.statusCode}): ${response.body}";
          try {
            final jsonRes = jsonDecode(response.body);
            if (jsonRes['message'] != null) errMsg = "${jsonRes['message']}";
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red[700]),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting enquiry: $e"), backgroundColor: Colors.red[700]),
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

  Color get _themeColor {
    switch (_selectedType) {
      case 'photography':
        return const Color(0xFF8B5CF6);
      case 'transport':
        return const Color(0xFF10B981);
      case 'real-estate':
        return const Color(0xFFD97706);
      case 'website':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFFF8C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: isWeb ? const Color(0xFFFAF8F5) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Send Your Enquiry",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: isWeb,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 650 : double.infinity),
          decoration: isWeb
              ? BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                )
              : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Service Category Selection Tabs
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildServiceTab('solar', 'Solar', Icons.wb_sunny_rounded, const Color(0xFFFF8C00)),
                        const SizedBox(width: 8),
                        _buildServiceTab('photography', 'Photography', Icons.camera_alt_rounded, const Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        _buildServiceTab('transport', 'Transport', Icons.local_shipping_rounded, const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildServiceTab('real-estate', 'Real Estate', Icons.home_work_rounded, const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildServiceTab('website', 'Website', Icons.language_rounded, const Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _themeColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
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
                                _selectedType == 'photography' ? Icons.camera_alt_rounded :
                                _selectedType == 'transport' ? Icons.local_shipping_rounded :
                                _selectedType == 'real-estate' ? Icons.home_work_rounded : Icons.language_rounded,
                                color: _themeColor, size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedType == 'solar' ? "Solar Solution Enquiry" :
                                _selectedType == 'photography' ? "Photography & Events Enquiry" :
                                _selectedType == 'transport' ? "Transport & Logistics Enquiry" :
                                _selectedType == 'real-estate' ? "Real Estate Enquiry" : "Website & Digital Solution Enquiry",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _themeColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedType == 'solar' ? "Home & Commercial Solar Installation" :
                            _selectedType == 'photography' ? "Wedding • Events • Birthday • Corporate & More" :
                            _selectedType == 'transport' ? "Parcel • Full Load • Mini Truck • Container & More" :
                            _selectedType == 'real-estate' ? "Homes • Plots • Commercial Spaces • Buy, Sell & Rent" : "Static, Dynamic, E-Commerce & Custom Web Solutions",
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
                          // 1. Personal Details
                          _buildSectionHeader("1. Your Details"),
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
                              Expanded(child: _buildTextField("Email *", _emailController, isEmail: true, required: _selectedType == 'website')),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Dynamic Form Sections based on Tab
                          if (_selectedType == 'solar') _buildSolarForm(),
                          if (_selectedType == 'photography') _buildPhotographyForm(),
                          if (_selectedType == 'transport') _buildTransportForm(),
                          if (_selectedType == 'real-estate') _buildRealEstateForm(),
                          if (_selectedType == 'website') _buildWebsiteForm(),

                          const SizedBox(height: 20),

                          // Additional Notes
                          Text("Additional Information / Notes", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            style: GoogleFonts.outfit(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Tell us more about your specific requirements, ideas or features...",
                              hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitEnquiry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        Text("Submit Enquiry", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
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
}

  Widget _buildServiceTab(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(width: 6),
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

  // 1. SOLAR FORM WIDGETS
  Widget _buildSolarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("2. Location Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("State", _solarState, ['Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh'], (v) => setState(() => _solarState = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("District", _solarDistrict, ['Coimbatore', 'Tirupur', 'Erode', 'Salem', 'Chennai'], (v) => setState(() => _solarDistrict = v))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("City / Town", _solarCity, ['Coimbatore', 'Tirupur', 'Erode', 'Pollachi', 'Udumalpet'], (v) => setState(() => _solarCity = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Pincode *", _solarPincodeController, isPhone: true, required: true)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Full Address *", _solarFullAddressController, required: true),
        const SizedBox(height: 20),

        _buildSectionHeader("3. Requirement Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Property Type", _solarPropertyType, ['Residential', 'Commercial', 'Industrial', 'Agricultural'], (v) => setState(() => _solarPropertyType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Rooftop / Ground", _solarRooftopOrGround, ['Rooftop', 'Ground Mounted'], (v) => setState(() => _solarRooftopOrGround = v))),
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

        _buildSectionHeader("4. Upload Documents"),
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
        _buildSectionHeader("2. Event Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Event Type", _photoEventType, ['Wedding', 'Pre-Wedding', 'Birthday', 'Baby Shower', 'Corporate Event', 'Model Shoot'], (v) => setState(() => _photoEventType = v))),
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
                          Text(_photoEventDate != null ? DateFormat('dd/MM/yyyy').format(_photoEventDate!) : "Select Date", style: GoogleFonts.outfit(fontSize: 12, color: _photoEventDate != null ? Colors.black87 : Colors.grey[400])),
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
            Expanded(child: _buildDropdown("City", _photoCity, ['Coimbatore', 'Chennai', 'Bangalore', 'Madurai', 'Trichy'], (v) => setState(() => _photoCity = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Google Map Location Link", _photoMapLocationController),
        const SizedBox(height: 20),

        _buildSectionHeader("3. Services & Budget"),
        const SizedBox(height: 12),
        Text("Services Required", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Traditional Photography', 'Candid Photography', 'Traditional Video', 'Cinematography', 'Drone Shoot', 'Album Printing'].map((srv) {
            return _buildCheckboxOption(srv, _photoServicesRequired);
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildDropdown("Budget Range", _photoBudgetRange, ['Under ₹25,000', '₹25,000 - ₹50,000', '₹50,000 - ₹1,00,000', '₹1,00,000 - ₹2,00,000', '₹2,00,000+'], (v) => setState(() => _photoBudgetRange = v)),
        const SizedBox(height: 20),

        _buildSectionHeader("4. Upload Invitation / Reference"),
        const SizedBox(height: 10),
        _buildFileUploadBox("Upload Invitation Card / Sample Image", _invitationFileName, () => _pickImage('invitation')),
      ],
    );
  }

  // 3. TRANSPORT FORM WIDGETS
  Widget _buildTransportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("2. Pickup & Delivery Location"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Pickup Address *", _transPickupAddressController, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Pickup Pincode *", _transPickupPincodeController, isPhone: true, required: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Delivery Address *", _transDeliveryAddressController, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Delivery Pincode *", _transDeliveryPincodeController, isPhone: true, required: true)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("3. Cargo & Vehicle Details"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Material Type", _transMaterialType, ['Boxes / Parcels', 'Furniture & Household', 'Industrial Goods', 'Perishables', 'Heavy Machinery'], (v) => setState(() => _transMaterialType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Estimated Weight", _transWeight, ['Under 100 kg', '100 - 500 kg', '500 kg - 1 Ton', '1 - 3 Tons', '3 - 10 Tons', '10+ Tons'], (v) => setState(() => _transWeight = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown("Vehicle Required", _transVehicleRequired, ['Two Wheeler Express', 'Mini Truck (Tata Ace)', 'Pickup (Bolero)', '14ft Truck', '19ft Container', 'Heavy Trailer'], (v) => setState(() => _transVehicleRequired = v)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRadioOption("Loading Support Required?", _transLoadingRequired, (v) => setState(() => _transLoadingRequired = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Unloading Support Required?", _transUnloadingRequired, (v) => setState(() => _transUnloadingRequired = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildRadioOption("Transit Insurance Required?", _transInsuranceRequired, (v) => setState(() => _transInsuranceRequired = v)),
        const SizedBox(height: 20),

        _buildSectionHeader("4. Schedule"),
        const SizedBox(height: 12),
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

  // 4. REAL ESTATE FORM WIDGETS
  Widget _buildRealEstateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("2. Requirement Type"),
        const SizedBox(height: 12),
        Text("I am looking to *", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Row(
          children: ['Buy', 'Sell', 'Rent', 'Plot'].map((opt) {
            final isSel = _reLookingFor == opt;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _reLookingFor = opt),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _themeColor.withOpacity(0.12) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSel ? _themeColor : Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(opt, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? _themeColor : Colors.grey[800])),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildDropdown("Property Category *", _rePropertyCategory, ['Apartment / Flat', 'Independent House / Villa', 'Commercial Shop / Showroom', 'Office Space', 'Plot / Land', 'Agricultural Land'], (v) => setState(() => _rePropertyCategory = v)),
        const SizedBox(height: 20),

        _buildSectionHeader("3. Property Preference"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("BHK / Type", _reBhkType, ['1 BHK', '2 BHK', '3 BHK', '4+ BHK', 'Commercial', 'Land Parcel'], (v) => setState(() => _reBhkType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Budget Range *", _reBudgetRange, ['Under ₹25 Lakhs', '₹25 - 50 Lakhs', '₹50 Lakhs - 1 Crore', '₹1 - 2 Crores', '₹2+ Crores'], (v) => setState(() => _reBudgetRange = v))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Preferred Location / City *", _rePreferredLocationController, required: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Landmark / Locality", _reLandmarkLocalityController)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("4. Additional Preferences"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Furnishing", _reFurnishing, ['Any', 'Fully Furnished', 'Semi Furnished', 'Unfurnished'], (v) => setState(() => _reFurnishing = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Facing", _reFacing, ['Any', 'East', 'West', 'North', 'South', 'North-East', 'South-East', 'North-West', 'South-West'], (v) => setState(() => _reFacing = v))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Floor Preference", _reFloorPreference, ['Any', 'Ground Floor', 'Lower Floors', 'Middle Floors', 'Top Floor'], (v) => setState(() => _reFloorPreference = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Age of Property", _rePropertyAge, ['Any', 'Under Construction', 'Brand New', '1-5 Years', '5-10 Years', '10+ Years'], (v) => setState(() => _rePropertyAge = v))),
          ],
        ),
        const SizedBox(height: 12),
        Text("Amenities Required (Select all that apply)", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Car Parking', 'Lift', 'Power Backup', 'Security', 'Gym', 'Swimming Pool', 'Play Area', 'Garden', 'Club House', 'Others'].map((amen) {
            return _buildCheckboxOption(amen, _reAmenities);
          }).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("5. Contact Preference & Document"),
        const SizedBox(height: 12),
        _buildDropdown("Preferred Contact Time", _rePreferredContactTime, ['Any Time', 'Morning (9 AM - 12 PM)', 'Afternoon (12 PM - 4 PM)', 'Evening (4 PM - 8 PM)'], (v) => setState(() => _rePreferredContactTime = v)),
        const SizedBox(height: 12),
        _buildFileUploadBox("Upload Property Document / Layout Plan (Optional)", _reDocumentFileName, () => _pickImage('realEstateDoc')),
      ],
    );
  }

  // 5. WEBSITE FORM WIDGETS
  Widget _buildWebsiteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("2. Business & Organization Details"),
        const SizedBox(height: 12),
        _buildTextField("Business / Organization Name *", _webBusinessNameController, required: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Business Type *", _webBusinessType, ['Retail / Shop', 'Service Provider', 'Startup', 'Manufacturer', 'Educational', 'Non-Profit', 'Personal Brand', 'Others'], (v) => setState(() => _webBusinessType = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Industry / Category *", _webIndustryCategory, ['E-Commerce', 'Healthcare', 'Education', 'Real Estate', 'Food & Restaurant', 'Technology', 'Finance', 'Travel', 'Manufacturing', 'Entertainment', 'Others'], (v) => setState(() => _webIndustryCategory = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Existing Website (If any)", _webExistingWebsiteController),
        const SizedBox(height: 20),

        _buildSectionHeader("3. Website Requirements"),
        const SizedBox(height: 12),
        Text("Type of Website *", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Column(
          children: [
            'Static Website (Informational)',
            'Dynamic Website',
            'E-Commerce Website',
            'Custom Website / Web Application'
          ].map((typeOpt) {
            final isSel = _webWebsiteType == typeOpt;
            return InkWell(
              onTap: () => setState(() => _webWebsiteType = typeOpt),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? _themeColor.withOpacity(0.08) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSel ? _themeColor : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Radio<String>(value: typeOpt, groupValue: _webWebsiteType, onChanged: (v) => setState(() => _webWebsiteType = v!), activeColor: _themeColor),
                    Text(typeOpt, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text("Purpose of Website *", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Business / Company Profile', 'Online Store / E-Commerce', 'Booking / Appointment', 'Blog / News / Magazine', 'Portfolio / Personal', 'Other'].map((purp) {
            return _buildCheckboxOption(purp, _webWebsitePurpose);
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text("Features You Need (Select all that apply)", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Responsive (Mobile Friendly)', 'Admin Panel', 'Payment Gateway', 'Live Chat / WhatsApp Integration', 'SEO Optimization', 'Product Management', 'Blog / News Section', 'Multi-language', 'Contact / Enquiry Form', 'Other'].map((feat) {
            return _buildCheckboxOption(feat, _webWebsiteFeatures);
          }).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("4. Design & Content Preferences"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Design Preference *", _webDesignPreference, ['Modern & Sleek', 'Minimalist', 'Corporate / Professional', 'Creative & Vibrant', 'Luxury / Premium'], (v) => setState(() => _webDesignPreference = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Color Preference", _webColorPreferenceController)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Reference Website Link (If any)", _webReferenceWebsiteController),
        const SizedBox(height: 12),
        Text("Content Ready?", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Row(
          children: ['Yes', 'No', 'Partial'].map((opt) {
            final isSel = _webContentReady == opt;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _webContentReady = opt),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _themeColor.withOpacity(0.12) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSel ? _themeColor : Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(opt, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? _themeColor : Colors.grey[800])),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("5. Budget & Timeline"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDropdown("Estimated Budget *", _webEstimatedBudget, ['Under ₹10,000', '₹10,000 - ₹25,000', '₹25,000 - ₹50,000', '₹50,000 - ₹1,00,000', '₹1,00,000+'], (v) => setState(() => _webEstimatedBudget = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown("Required Timeframe *", _webRequiredTimeframe, ['Urgent (within 1 week)', '2-3 Weeks', '1 Month', '1-3 Months', 'Flexible'], (v) => setState(() => _webRequiredTimeframe = v))),
          ],
        ),
        const SizedBox(height: 12),
        Text("Do you have Domain & Hosting?", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Row(
          children: ['Yes', 'No', 'Need Help'].map((opt) {
            final isSel = _webHasDomainHosting == opt;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _webHasDomainHosting = opt),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _themeColor.withOpacity(0.12) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSel ? _themeColor : Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(opt, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? _themeColor : Colors.grey[800])),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildDropdown("Preferred Contact Time", _webPreferredContactTime, ['Any Time', 'Morning (9 AM - 12 PM)', 'Afternoon (12 PM - 4 PM)', 'Evening (4 PM - 8 PM)'], (v) => setState(() => _webPreferredContactTime = v)),
        const SizedBox(height: 12),
        _buildFileUploadBox("Upload Reference / Documents (Optional)", _webReferenceFileName, () => _pickImage('webReference')),
      ],
    );
  }

  // HELPER WIDGETS
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
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Required" : null : null,
          style: GoogleFonts.outfit(fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            errorStyle: GoogleFonts.outfit(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: GoogleFonts.outfit(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? value, ValueChanged<TimeOfDay?> onChanged) {
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

  Widget _buildFileUploadBox(String label, String? fileData, VoidCallback onTap) {
    final bool isSelected = fileData != null && fileData.isNotEmpty;
    final String displayTitle = isSelected 
        ? (fileData.startsWith("data:") ? "Image Attached ✓" : fileData)
        : "Upload Image / Photo";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected ? _themeColor.withOpacity(0.08) : Colors.grey[50], 
              borderRadius: BorderRadius.circular(10), 
              border: Border.all(color: isSelected ? _themeColor : Colors.grey[300]!, style: BorderStyle.solid)
            ),
            child: Column(
              children: [
                Icon(isSelected ? Icons.check_circle_rounded : Icons.cloud_upload_outlined, color: _themeColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  displayTitle,
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? _themeColor : Colors.grey[500]),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(String label, List<String> selectedList) {
    final isChecked = selectedList.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            selectedList.remove(label);
          } else {
            selectedList.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isChecked ? _themeColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isChecked ? _themeColor : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: isChecked ? _themeColor : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: isChecked ? _themeColor : Colors.grey[800])),
          ],
        ),
      ),
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
            return InkWell(
              onTap: () => onChanged(opt),
              child: Row(
                children: [
                  Radio<String>(value: opt, groupValue: selectedVal, onChanged: (v) => onChanged(v!), activeColor: _themeColor),
                  Text(opt, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(width: 12),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
