import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class CmsProvider with ChangeNotifier {
  Map<String, String> _content = {
    'about_us': 'Loading...',
    'privacy_policy': 'Loading...',
    'help_support': 'Loading...',
  };
  bool _isLoading = false;

  Map<String, String> get content => _content;
  bool get isLoading => _isLoading;

  Future<void> fetchContent() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('cms/content');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _content = {
          'about_us': data['about_us'] ?? 'FESTIVALKART – ONE PLATFORM FOR ALL CELEBRATIONS!\n\nFestivalKart is a booking & enquiry platform for celebration-related services and products, including Fireworks / Crackers, Transportation & Cargo Booking, Wedding Photography, Fireworks Show / Paiyee, and Other Celebration Services.\n\nAny applicable sale, supply, invoicing, transport and delivery will be completed through the appropriate authorised / licensed seller or service provider and in accordance with applicable laws.\n\nMULTIPLE SERVICES – ONE ENQUIRY:\nGo to Enquiry / Services, select the service you need and submit your request. Offers may be available for selected services and booking periods.',
          'privacy_policy': data['privacy_policy'] ?? 'PRIVACY POLICY & CUSTOMER DATA GUARANTEE\n\nAt FestivalKart, we prioritize customer privacy, safety, and compliance with statutory requirements.\n\n1. DATA COLLECTION & USE:\nWe collect customer information (Name, Phone Number, Email, and Delivery Address) solely for processing product enquiries, booking confirmations, and legal transportation compliance.\n\n2. PAYMENT & TRANSACTION PRIVACY:\nCheck your selected products, quantity, final payable amount, and delivery details before payment. Do not make payments to any person or account that is not officially communicated by FestivalKart / authorized seller. Payment confirmations are generated strictly after successful verification.\n\n3. PRODUCT COMPLAINT & SUPPORT PRIVACY:\nIf you receive a product with an issue, contact customer support at 9385757220 with your Order/Booking number, photos, and voice notes. Your submitted photos and documents are strictly used for verifying complaint eligibility and refund/replacement processing.\n\n4. STATUTORY COMPLIANCE:\nFestivalKart follows 100% legal & statutory compliances. Parcels are sent through registered and legal transport service providers in accordance with applicable explosive acts and transport regulations.',
          'help_support': data['help_support'] ?? 'CUSTOMER SUPPORT – "Booking mudinjadhukku apram support mudiyadhu" IS NOT OUR POLICY!\n\nFestivalKart is committed to helping customers with genuine product and service-related issues after booking as well.\n\nCUSTOMER HELPLINE:\n📞 Call / WhatsApp: 9385757220\n\nHOW TO RAISE A COMPLAINT:\nIf you receive a product with an issue, don\'t panic! Send us:\n1. Order / Booking Number\n2. Product photo\n3. Outer package / box photo\n4. Short voice message explaining the issue\n5. Video / photo if required\n\nREPLACEMENT & REFUND POLICY:\n• REPLACEMENT: We may arrange a replacement for eligible products, subject to availability and conditions.\n• REFUND: If replacement is not possible or an eligible refund option is chosen, approved refunds will generally be processed within 1 - 7 working days after confirmation.',
          'footer_terms_and_conditions': data['footer_terms_and_conditions'] ?? '₹4,500 MINIMUM BOOKING VALUE for fireworks bookings. Minimum booking value is maintained to help provide safer and more secure packing and consolidated transportation of goods.',
          'footer_about_us': data['footer_about_us'] ?? 'FestivalKart is a booking & enquiry platform for celebration-related services including Fireworks / Crackers, Transportation & Cargo Booking, Wedding Photography, Fireworks Show / Paiyee, and Other Celebration Services.',
          'footer_address': data['footer_address'] ?? 'Sivakasi, Tamil Nadu, India',
          'footer_phone_1': data['footer_phone_1'] ?? '9385757220',
          'footer_phone_2': data['footer_phone_2'] ?? '+91 9385757220',
          'footer_phone_3': data['footer_phone_3'] ?? '+91 9385757220',
          'footer_email': data['footer_email'] ?? 'festivekart@gmail.com',
          'footer_legal_disclaimer': data['footer_legal_disclaimer'] ?? 'As per 2018 Supreme Court order, online sale of firecrackers is not permitted! We value our customers and respect jurisdiction. Please add products to cart and submit enquiries. We will contact you within 24 hrs to confirm the order. FestivalKart follows 100% legal & statutory compliances and parcels are dispatched via registered & legal transport service providers.',
          'footer_maps_url': data['footer_maps_url'] ?? 'https://maps.google.com/?q=Sivakasi,TamilNadu',
        };
      }
    } catch (e) {
      print('Error fetching CMS content: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
