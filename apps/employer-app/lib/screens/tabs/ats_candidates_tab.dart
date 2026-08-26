import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';

class AtsCandidatesTab extends StatelessWidget {
  const AtsCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployerProvider>(context);
    final applicants = provider.applicants;

    return Scaffold(
      backgroundColor: AppTheme.bgPaper,
      appBar: AppBar(
        title: Text('Candidate ATS Pipeline', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: applicants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = applicants[index];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.candidateName, style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                        Text(a.jobTitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${a.aiMatchScore.toInt()}% AI Fit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Exp: ${a.experience}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    Text('📍 ${a.location}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: a.status,
                      items: ['New', 'Shortlisted', 'Interview', 'Offer', 'Rejected'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) provider.updateApplicantStatus(a.id, val);
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contacting ${a.candidateName} via WhatsApp/Email')));
                      },
                      child: const Text('Connect →'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}