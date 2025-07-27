import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeclineReasonSheet extends StatefulWidget {
  @override
  State<DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<DeclineReasonSheet> {
  int? _selectedReasonIndex = 0;
  final TextEditingController _otherController = TextEditingController();
  final List<String> _reasons = [
    'Passenger not at pickup',
    'Unable to contact passenger',
    'Other',
  ];

  String get _selectedReason {
    if (_selectedReasonIndex == 2) {
      return _otherController.text.trim().isNotEmpty
          ? _otherController.text.trim()
          : 'other';
    }
    if (_selectedReasonIndex == 0) return 'passenger_not_at_pickup';
    if (_selectedReasonIndex == 1) return 'unable_to_contact_passenger';
    return 'other';
  }

  void _submit() {
    if (_selectedReasonIndex == 2 && _otherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason.')),
      );
      return;
    }
    Navigator.of(context).pop(_selectedReason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Decline Reason', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            ...List.generate(_reasons.length, (i) {
              if (i < 2) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedReasonIndex = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedReasonIndex == i ? const Color(0xff3E57B4) : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        color: _selectedReasonIndex == i ? const Color(0xffF2F6FF) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedReasonIndex == i,
                            onChanged: (_) => setState(() => _selectedReasonIndex = i),
                            activeColor: const Color(0xff3E57B4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          Text(_reasons[i], style: GoogleFonts.nunito(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _otherController,
                    onTap: () => setState(() => _selectedReasonIndex = i),
                    decoration: InputDecoration(
                      hintText: 'Other',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xff3E57B4)),
                      ),
                    ),
                    minLines: 2,
                    maxLines: 3,
                  ),
                );
              }
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3E57B4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 17, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
