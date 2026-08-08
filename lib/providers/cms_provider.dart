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
          'about_us': data['about_us'] ?? 'About Us content not available.',
          'privacy_policy': data['privacy_policy'] ?? 'Privacy Policy content not available.',
          'help_support': data['help_support'] ?? 'Help & Support content not available.',
          'footer_terms_and_conditions': data['footer_terms_and_conditions'] ?? 'Minimum order value Starts from Rs.2000 to Unlimited, Customized Gift Box and Combo Fund Items Available at Reasonable Price, Available for Bulk Orders As per Requirement, Wholesale and Retail Also Available',
          'footer_about_us': data['footer_about_us'] ?? 'Our company lies in manufacturing and supplying colourful Crackers. We are equipped with a state of art infrastructural unit and production facility.',
          'footer_address': data['footer_address'] ?? '3/1322/3/1 , Opposite to SNM Matriculation School, Checkpost, Parapatti, Sivakasi, Tamil Nadu 626 189',
          'footer_phone_1': data['footer_phone_1'] ?? '+91 80720 11455',
          'footer_phone_2': data['footer_phone_2'] ?? '+91 93451 89265',
          'footer_phone_3': data['footer_phone_3'] ?? '+91 70102 55290',
          'footer_email': data['footer_email'] ?? 'festivekart@gmail.com',
          'footer_legal_disclaimer': data['footer_legal_disclaimer'] ?? 'As per 2018 supreme court order, online sale of firecrackers are not permitted! We value our customers and at the same time, respect jurisdiction. We request you to add your products to the cart and submit the required crackers through the enquiry button. We will contact you within 24 hrs and confirm the order through WhatsApp or phone call. Please add and submit your enquiries and enjoy your Diwali with FestiveKart. Our License No.---. FestiveKart as a company following 100% legal & statutory compliances and all our shops, go-downs are maintained as per the explosive acts. We send the parcels through registered and legal transport service providers as like every other major companies in Sivakasi is doing so.',
          'footer_maps_url': data['footer_maps_url'] ?? 'https://maps.google.com/?q=Parapatti,Sivakasi,TamilNadu',
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
