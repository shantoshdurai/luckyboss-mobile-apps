import 'package:flutter/material.dart';
import '../models/employer_models.dart';

class EmployerProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _companyName = 'Lucky Boss Enterprise Pte Ltd';
  String _phone = '+65 8123 9900';

  final List<EmployerJobModel> _jobs = [
    EmployerJobModel(
      id: 'emp-j1',
      title: 'Lead AI & Flutter Mobile Engineer',
      category: 'IT & Software',
      location: 'Singapore, One-North',
      countryCode: 'SG',
      salaryDisplay: 'SGD 6,500 - 9,000 / mo',
      applicantsCount: 4,
      status: 'published',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    EmployerJobModel(
      id: 'emp-j2',
      title: 'Warehouse Supervisor',
      category: 'Logistics & Warehouse',
      location: 'Singapore, Jurong East',
      countryCode: 'SG',
      salaryDisplay: 'SGD 3,200 - 4,500 / mo',
      applicantsCount: 2,
      status: 'published',
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final List<ApplicantModel> _applicants = [
    ApplicantModel(
      id: 'cand-01',
      jobId: 'emp-j1',
      jobTitle: 'Lead AI & Flutter Mobile Engineer',
      candidateName: 'Alex Rivera',
      candidatePhone: '+65 8921 4455',
      experience: '4 years',
      location: 'Singapore',
      aiMatchScore: 94.0,
      status: 'Interview',
    ),
    ApplicantModel(
      id: 'cand-02',
      jobId: 'emp-j1',
      jobTitle: 'Lead AI & Flutter Mobile Engineer',
      candidateName: 'Maya Tan',
      candidatePhone: '+65 9123 4567',
      experience: '3 years',
      location: 'Singapore',
      aiMatchScore: 77.0,
      status: 'New',
    ),
    ApplicantModel(
      id: 'cand-03',
      jobId: 'emp-j2',
      jobTitle: 'Warehouse Supervisor',
      candidateName: 'Santosh Kumar',
      candidatePhone: '+91 9442 123456',
      experience: '3 years',
      location: 'Singapore / India',
      aiMatchScore: 65.0,
      status: 'Shortlisted',
    ),
  ];

  bool get isAuthenticated => _isAuthenticated;
  String get companyName => _companyName;
  String get phone => _phone;
  List<EmployerJobModel> get jobs => _jobs;
  List<ApplicantModel> get applicants => _applicants;

  void setAuthenticated(bool val, {String? phone}) {
    _isAuthenticated = val;
    if (phone != null) _phone = phone;
    notifyListeners();
  }

  void updateApplicantStatus(String applicantId, String newStatus) {
    final idx = _applicants.indexWhere((a) => a.id == applicantId);
    if (idx != -1) {
      _applicants[idx].status = newStatus;
      notifyListeners();
    }
  }

  void postNewJob({
    required String title,
    required String category,
    required String location,
    required String minSalary,
    required String maxSalary,
    required String currency,
  }) {
    _jobs.insert(
      0,
      EmployerJobModel(
        id: 'emp-j${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        category: category,
        location: location,
        countryCode: 'SG',
        salaryDisplay: '$currency $minSalary - $maxSalary / mo',
        applicantsCount: 0,
        status: 'published',
        postedDate: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}