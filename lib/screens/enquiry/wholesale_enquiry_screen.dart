import 'package:flutter/material.dart';

class WholesaleEnquiryScreen extends StatefulWidget {
  const WholesaleEnquiryScreen({super.key});

  @override
  State<WholesaleEnquiryScreen> createState() => _WholesaleEnquiryScreenState();
}

class _WholesaleEnquiryScreenState extends State<WholesaleEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wholesale Enquiry")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bulk Order Inquiries",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you a retailer? Contact us for special wholesale pricing on bulk orders.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: "Business Name",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLines: 5,
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: "Your Requirements (Items, Quantity)",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enquiry sent successfully!")),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Submit Enquiry", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
