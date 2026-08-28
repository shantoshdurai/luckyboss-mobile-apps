import 'package:flutter/material.dart';

/// Which shape of questions a category needs.
///
/// This is the distinction the whole app was missing. A software engineer and a
/// scaffolder are both looking for work, but almost nothing you would ask one is
/// worth asking the other. The engineer has a degree, a stack of named
/// technologies and a notice period. The scaffolder has a trade, a number of
/// years doing it, a safety card, the languages they speak and a date they can
/// start. Asking the scaffolder to type "key skills" into a chip field produces
/// an empty profile and a candidate who assumes the app is not for them.
///
/// Nothing here implies one path is lesser. They are different questions,
/// nothing more.
enum WorkPath {
  /// Trades, site work, driving, care, service. Experience is measured in years
  /// on the job and proven by licences and cards rather than qualifications.
  field,

  /// Desk and professional roles, where a named skill set and an education
  /// history are what an employer screens on.
  professional,
}

/// One job — what it involves and what you need to hold to do it.
///
/// The reason this type exists rather than the lists living on the category:
/// attaching skills and licences to a category means the app offers a plumber a
/// scaffolding certificate and a crane licence, because another trade in the
/// same category needs them. Shantosh caught exactly that — the licence picker
/// showed the same five cards no matter which job had been chosen. Certificates
/// are a claim about a specific person doing a specific job, so they hang off
/// the role.
class WorkRole {
  final String name;

  /// What this job involves, in the words of the trade.
  final List<String> abilities;

  /// Licences, cards and certificates that genuinely apply to this role.
  ///
  /// Empty is a correct and common answer — most office and software roles have
  /// no licence, and offering an invented one is worse than offering none.
  final List<String> certificates;

  const WorkRole({
    required this.name,
    this.abilities = const [],
    this.certificates = const [],
  });
}

/// One job category, with everything the app needs to ask a candidate about it.
///
/// Held together in one object deliberately: when the agency adds a category,
/// the icon, the roles and the vocabulary all arrive with it, and no screen has
/// to be edited to make it work.
class WorkCategory {
  final String name;

  /// Shown on the category grid and the feed strip. Blue-collar candidates
  /// navigate this app by picture far more than by reading, so every category
  /// must be recognisable before its label is read.
  final IconData icon;
  final WorkPath path;

  /// The jobs people actually do in this category. On the [WorkPath.field] path
  /// picking one replaces free-text skill entry — tapping "Plumber" is one
  /// action, and typing it is four with a chance of a typo that no employer's
  /// search will ever match.
  final List<WorkRole> roles;

  const WorkCategory({
    required this.name,
    required this.icon,
    required this.path,
    this.roles = const [],
  });

  bool get isField => path == WorkPath.field;

  List<String> get roleNames => [for (final r in roles) r.name];

  WorkRole? role(String name) {
    for (final r in roles) {
      if (r.name == name) return r;
    }
    return null;
  }

  /// Everything anyone in this category might be able to do. Used when no role
  /// has been chosen yet; once one has, prefer that role's own list.
  List<String> get abilities =>
      _union([for (final r in roles) ...r.abilities]);

  /// Every licence held by anyone in this category. Same rule: once a role is
  /// known, [WorkRole.certificates] is the honest list and this is too broad.
  List<String> get certificates =>
      _union([for (final r in roles) ...r.certificates]);
}

/// Order-preserving dedup. Order matters — the first entries are what a
/// candidate sees before scrolling, so the commonest work stays at the top.
List<String> _union(List<String> items) {
  final seen = <String>{};
  final out = <String>[];
  for (final i in items) {
    if (seen.add(i)) out.add(i);
  }
  return out;
}

class AppData {
  static const List<Map<String, String>> countries = [
    {'code': 'IN', 'name': 'India', 'currency': 'INR', 'symbol': '₹', 'phone': '+91', 'flag': '🇮🇳'},
    {'code': 'SG', 'name': 'Singapore', 'currency': 'SGD', 'symbol': r'S$', 'phone': '+65', 'flag': '🇸🇬'},
    {'code': 'MY', 'name': 'Malaysia', 'currency': 'MYR', 'symbol': 'RM', 'phone': '+60', 'flag': '🇲🇾'},
  ];

  /// Used where a list of categories has to include "no filter".
  static const String allRoles = 'All Roles';

  // ---------------------------------------------------------------------------
  // CATEGORIES — spec §58 and §59
  //
  // The order is the spec's, not ours: Construction, Manufacturing, Warehouse.
  // The app previously led with IT & Software and carried five categories in
  // total, which quietly made Lucky Boss an IT job board — while the agency it
  // was built for places construction workers, factory labour, warehouse
  // manpower and domestic helpers. §59 lists those first for a reason.
  //
  // Everything a screen needs to know about a category lives here rather than
  // being spread across the UI, so the list can grow without any screen
  // changing.
  // ---------------------------------------------------------------------------
  static final List<WorkCategory> workCategories = [
    WorkCategory(
      name: 'Construction',
      icon: Icons.construction,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'General Worker',
          abilities: const [
            'Site Cleaning',
            'Concreting',
            'Loading & Unloading',
            'Formwork',
          ],
          certificates: const [
            'Safety Orientation Course',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Mason',
          abilities: const [
            'Brickwork',
            'Plastering',
            'Concreting',
            'Reading Drawings',
          ],
          certificates: const [
            'Safety Orientation Course',
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Bar Bender',
          abilities: const [
            'Rebar Tying',
            'Steel Fixing',
            'Reading Drawings',
            'Concreting',
          ],
          certificates: const [
            'Safety Orientation Course',
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Carpenter',
          abilities: const [
            'Formwork',
            'Shuttering',
            'Timber Work',
            'Reading Drawings',
          ],
          certificates: const [
            'Trade Test Certificate',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Plumber',
          abilities: const [
            'Pipe Fitting',
            'Sanitary Installation',
            'Leak Repairs',
            'Water Tank Fitting',
          ],
          certificates: const [
            'Trade Test Certificate',
            'Plumbing Licence',
          ],
        ),
        WorkRole(
          name: 'Electrician',
          abilities: const [
            'Wiring',
            'Conduit Work',
            'Switchboard Installation',
            'Fault Finding',
          ],
          certificates: const [
            'Electrical Wireman Licence',
            'Trade Test Certificate',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Painter',
          abilities: const [
            'Surface Preparation',
            'Spray Painting',
            'Putty Work',
            'Working at Heights',
          ],
          certificates: const [
            'Work at Height Certificate',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Welder',
          abilities: const [
            'Arc Welding',
            'Gas Welding',
            'MIG Welding',
            'Metal Cutting',
          ],
          certificates: const [
            'Welding Trade Test',
            'Hot Work Permit',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Scaffolder',
          abilities: const [
            'Scaffolding',
            'Working at Heights',
            'Load Calculation',
            'Site Safety',
          ],
          certificates: const [
            'Scaffolding Certificate',
            'Work at Height Certificate',
          ],
        ),
        WorkRole(
          name: 'Tiler',
          abilities: const [
            'Tiling',
            'Waterproofing',
            'Surface Preparation',
            'Grouting',
          ],
          certificates: const [
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Crane Operator',
          abilities: const [
            'Crane Operating',
            'Load Calculation',
            'Signalling',
            'Site Safety',
          ],
          certificates: const [
            'Crane Operator Licence',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Excavator Operator',
          abilities: const [
            'Excavator Operating',
            'Earthworks',
            'Site Safety',
          ],
          certificates: const [
            'Heavy Machinery Licence',
            'Safety Orientation Course',
          ],
        ),
        WorkRole(
          name: 'Site Supervisor',
          abilities: const [
            'Reading Drawings',
            'Team Supervision',
            'Site Safety',
            'Progress Reporting',
          ],
          certificates: const [
            'Safety Orientation Course',
            'Supervisor Safety Course',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Safety Officer',
          abilities: const [
            'Site Safety',
            'Risk Assessment',
            'Toolbox Briefing',
            'Incident Reporting',
          ],
          certificates: const [
            'Safety Officer Certificate',
            'First Aid',
            'Confined Space Certificate',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'IT & Software',
      icon: Icons.code,
      path: WorkPath.professional,
      roles: [
        WorkRole(
          name: 'Software Engineer',
          abilities: const [
            'Python',
            'Java',
            'SQL',
            'REST APIs',
            'Git',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Mobile Developer',
          abilities: const [
            'Flutter',
            'Dart',
            'Kotlin',
            'REST APIs',
            'Git',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Web Developer',
          abilities: const [
            'JavaScript',
            'TypeScript',
            'React',
            'Node.js',
            'Git',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Data Analyst',
          abilities: const [
            'SQL',
            'Python',
            'Data Analysis',
            'Excel Modelling',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'IT Support',
          abilities: const [
            'Hardware Support',
            'Network Troubleshooting',
            'Ticketing Systems',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'QA Engineer',
          abilities: const [
            'Test Automation',
            'Manual Testing',
            'SQL',
            'Git',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'DevOps Engineer',
          abilities: const [
            'Docker',
            'AWS',
            'CI/CD',
            'Linux',
            'Git',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'UI/UX Designer',
          abilities: const [
            'Figma',
            'Wireframing',
            'Prototyping',
            'Design Systems',
          ],
          certificates: const [],
        ),
      ],
    ),
    WorkCategory(
      name: 'Manufacturing',
      icon: Icons.precision_manufacturing_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Production Operator',
          abilities: const [
            'Machine Operating',
            'Assembly Line Work',
            'Shift Work',
            'Reading Work Orders',
          ],
          certificates: const [
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Machine Operator',
          abilities: const [
            'Machine Operating',
            'Basic Maintenance',
            'Quality Inspection',
            'Shift Work',
          ],
          certificates: const [
            'ITI Certificate',
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Assembly Worker',
          abilities: const [
            'Assembly Line Work',
            'Soldering',
            'Quality Inspection',
            'Standing Long Hours',
          ],
          certificates: const [
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Quality Checker',
          abilities: const [
            'Quality Inspection',
            'Measuring Instruments',
            'Reading Work Orders',
            'Defect Reporting',
          ],
          certificates: const [
            'ITI Certificate',
          ],
        ),
        WorkRole(
          name: 'Packer',
          abilities: const [
            'Packing',
            'Labelling',
            'Standing Long Hours',
            'Stock Counting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'CNC Operator',
          abilities: const [
            'CNC Machining',
            'Reading Drawings',
            'Measuring Instruments',
            'Tool Setting',
          ],
          certificates: const [
            'ITI Certificate',
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Fitter',
          abilities: const [
            'Fitting',
            'Basic Maintenance',
            'Reading Drawings',
            'Measuring Instruments',
          ],
          certificates: const [
            'ITI Certificate',
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Maintenance Technician',
          abilities: const [
            'Basic Maintenance',
            'Fault Finding',
            'Machine Operating',
            'Electrical Repairs',
          ],
          certificates: const [
            'ITI Certificate',
            'Electrical Wireman Licence',
          ],
        ),
        WorkRole(
          name: 'Line Leader',
          abilities: const [
            'Team Supervision',
            'Assembly Line Work',
            'Quality Inspection',
            'Shift Work',
          ],
          certificates: const [
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Store Keeper',
          abilities: const [
            'Stock Counting',
            'Inventory Records',
            'Reading Work Orders',
            'Packing',
          ],
          certificates: const [],
        ),
      ],
    ),
    WorkCategory(
      name: 'Warehouse & Logistics',
      icon: Icons.warehouse_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Warehouse Assistant',
          abilities: const [
            'Loading & Unloading',
            'Stock Counting',
            'Heavy Lifting',
            'Scanning & Barcodes',
          ],
          certificates: const [
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Picker & Packer',
          abilities: const [
            'Picking & Packing',
            'Scanning & Barcodes',
            'Standing Long Hours',
            'Labelling',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Forklift Driver',
          abilities: const [
            'Forklift Operating',
            'Pallet Jack',
            'Loading & Unloading',
            'Stock Counting',
          ],
          certificates: const [
            'Forklift Licence',
            'Safety Training',
          ],
        ),
        WorkRole(
          name: 'Reach Truck Operator',
          abilities: const [
            'Reach Truck Operating',
            'Pallet Jack',
            'Stock Counting',
          ],
          certificates: const [
            'Reach Truck Licence',
            'Forklift Licence',
          ],
        ),
        WorkRole(
          name: 'Loader',
          abilities: const [
            'Loading & Unloading',
            'Heavy Lifting',
            'Pallet Jack',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Storekeeper',
          abilities: const [
            'Inventory Records',
            'Stock Counting',
            'Scanning & Barcodes',
            'Goods Receiving',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Inventory Clerk',
          abilities: const [
            'Inventory Records',
            'Stock Counting',
            'Data Entry',
            'Cycle Counting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Dispatch Assistant',
          abilities: const [
            'Goods Dispatch',
            'Scanning & Barcodes',
            'Route Planning',
            'Documentation',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Warehouse Supervisor',
          abilities: const [
            'Team Supervision',
            'Inventory Records',
            'Site Safety',
            'Shift Work',
          ],
          certificates: const [
            'Forklift Licence',
            'Safety Training',
            'First Aid',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Healthcare & Nursing',
      icon: Icons.medical_services_outlined,
      path: WorkPath.professional,
      roles: [
        WorkRole(
          name: 'Staff Nurse',
          abilities: const [
            'Patient Care',
            'Medication Administration',
            'Wound Dressing',
            'Ward Rounds',
          ],
          certificates: const [
            'Nursing Registration',
            'BLS / CPR',
          ],
        ),
        WorkRole(
          name: 'Enrolled Nurse',
          abilities: const [
            'Patient Care',
            'Vital Signs Monitoring',
            'Wound Dressing',
            'Medical Records',
          ],
          certificates: const [
            'Nursing Registration',
            'BLS / CPR',
          ],
        ),
        WorkRole(
          name: 'Healthcare Assistant',
          abilities: const [
            'Patient Care',
            'Mobility Assistance',
            'Vital Signs Monitoring',
            'Feeding Assistance',
          ],
          certificates: const [
            'First Aid',
            'Infection Control Training',
          ],
        ),
        WorkRole(
          name: 'Patient Service Associate',
          abilities: const [
            'Medical Records',
            'Appointment Scheduling',
            'Customer Service',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Therapy Assistant',
          abilities: const [
            'Mobility Assistance',
            'Patient Care',
            'Exercise Supervision',
          ],
          certificates: const [
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Lab Technician',
          abilities: const [
            'Sample Handling',
            'Lab Testing',
            'Medical Records',
            'Infection Control',
          ],
          certificates: const [
            'Lab Technician Diploma',
          ],
        ),
        WorkRole(
          name: 'Pharmacy Assistant',
          abilities: const [
            'Dispensing Support',
            'Stock Counting',
            'Medical Records',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Radiographer',
          abilities: const [
            'Imaging',
            'Patient Care',
            'Radiation Safety',
          ],
          certificates: const [
            'Radiography Registration',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Hospitality & F&B',
      icon: Icons.restaurant_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Kitchen Helper',
          abilities: const [
            'Food Preparation',
            'Dishwashing',
            'Kitchen Cleaning',
            'Standing Long Hours',
          ],
          certificates: const [
            'Food Handling Certificate',
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Cook',
          abilities: const [
            'Cooking',
            'Food Preparation',
            'Menu Execution',
            'Stock Rotation',
          ],
          certificates: const [
            'Food Handling Certificate',
            'Food Hygiene Certificate',
          ],
        ),
        WorkRole(
          name: 'Chef',
          abilities: const [
            'Cooking',
            'Menu Planning',
            'Kitchen Supervision',
            'Cost Control',
          ],
          certificates: const [
            'Food Hygiene Certificate',
            'Culinary Certificate',
          ],
        ),
        WorkRole(
          name: 'Waiter / Waitress',
          abilities: const [
            'Table Service',
            'Order Taking',
            'Customer Service',
            'Cash Handling',
          ],
          certificates: const [
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Bartender',
          abilities: const [
            'Drink Preparation',
            'Customer Service',
            'Cash Handling',
            'Stock Rotation',
          ],
          certificates: const [
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Barista',
          abilities: const [
            'Coffee Making',
            'Customer Service',
            'Cash Handling',
            'Machine Cleaning',
          ],
          certificates: const [
            'Barista Certificate',
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Dishwasher',
          abilities: const [
            'Dishwashing',
            'Kitchen Cleaning',
            'Standing Long Hours',
          ],
          certificates: const [
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Housekeeping Attendant',
          abilities: const [
            'Room Cleaning',
            'Bed Making',
            'Linen Handling',
            'Guest Service',
          ],
          certificates: const [
            'Basic Hygiene Course',
          ],
        ),
        WorkRole(
          name: 'Hotel Receptionist',
          abilities: const [
            'Guest Service',
            'Check-in Systems',
            'Cash Handling',
            'Customer Service',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Banquet Staff',
          abilities: const [
            'Table Service',
            'Event Setup',
            'Customer Service',
          ],
          certificates: const [
            'Basic Hygiene Course',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Driving & Delivery',
      icon: Icons.local_shipping_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Delivery Rider',
          abilities: const [
            'Two Wheeler',
            'Navigation Apps',
            'Cash on Delivery',
            'Customer Service',
          ],
          certificates: const [
            'Two Wheeler Licence',
          ],
        ),
        WorkRole(
          name: 'Van Driver',
          abilities: const [
            'Light Vehicle',
            'Route Planning',
            'Loading & Unloading',
            'Navigation Apps',
          ],
          certificates: const [
            'Class 3 Licence',
            'Light Vehicle Licence',
          ],
        ),
        WorkRole(
          name: 'Lorry Driver',
          abilities: const [
            'Heavy Vehicle',
            'Route Planning',
            'Loading & Unloading',
            'Vehicle Maintenance',
          ],
          certificates: const [
            'Class 4 Licence',
            'Heavy Vehicle Licence',
          ],
        ),
        WorkRole(
          name: 'Truck Driver',
          abilities: const [
            'Heavy Vehicle',
            'Long Distance Driving',
            'Night Driving',
            'Vehicle Maintenance',
          ],
          certificates: const [
            'Class 4 Licence',
            'Class 5 Licence',
          ],
        ),
        WorkRole(
          name: 'Bus Driver',
          abilities: const [
            'Heavy Vehicle',
            'Passenger Safety',
            'Route Planning',
          ],
          certificates: const [
            'Class 4 Licence',
            'Vocational Driving Licence',
          ],
        ),
        WorkRole(
          name: 'Taxi / Private Hire Driver',
          abilities: const [
            'Light Vehicle',
            'Navigation Apps',
            'Customer Service',
            'Night Driving',
          ],
          certificates: const [
            'Vocational Driving Licence',
            'Class 3 Licence',
          ],
        ),
        WorkRole(
          name: 'Company Driver',
          abilities: const [
            'Light Vehicle',
            'Route Planning',
            'Vehicle Maintenance',
            'Customer Service',
          ],
          certificates: const [
            'Class 3 Licence',
          ],
        ),
        WorkRole(
          name: 'Courier',
          abilities: const [
            'Two Wheeler',
            'Navigation Apps',
            'Documentation',
            'Cash on Delivery',
          ],
          certificates: const [
            'Two Wheeler Licence',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Retail & Sales',
      icon: Icons.storefront_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Retail Assistant',
          abilities: const [
            'Customer Service',
            'Stock Replenishment',
            'Cash Handling',
            'Standing Long Hours',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Cashier',
          abilities: const [
            'Cash Handling',
            'POS Systems',
            'Customer Service',
            'Billing',
          ],
          certificates: const [
            'Cashier Training',
          ],
        ),
        WorkRole(
          name: 'Sales Assistant',
          abilities: const [
            'Customer Service',
            'Upselling',
            'Product Knowledge',
            'Cash Handling',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Store Supervisor',
          abilities: const [
            'Team Supervision',
            'Inventory Counting',
            'Cash Handling',
            'Rostering',
          ],
          certificates: const [
            'Retail Service Certificate',
          ],
        ),
        WorkRole(
          name: 'Merchandiser',
          abilities: const [
            'Visual Merchandising',
            'Stock Replenishment',
            'Inventory Counting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Stock Assistant',
          abilities: const [
            'Stock Replenishment',
            'Inventory Counting',
            'Heavy Lifting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Promoter',
          abilities: const [
            'Customer Service',
            'Upselling',
            'Product Knowledge',
          ],
          certificates: const [],
        ),
      ],
    ),
    WorkCategory(
      name: 'Maid & Caregiver',
      icon: Icons.volunteer_activism_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Domestic Helper',
          abilities: const [
            'House Cleaning',
            'Cooking',
            'Laundry & Ironing',
            'Marketing & Groceries',
          ],
          certificates: const [
            'Domestic Helper Training',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Live-in Maid',
          abilities: const [
            'House Cleaning',
            'Cooking',
            'Laundry & Ironing',
            'Childcare',
          ],
          certificates: const [
            'Domestic Helper Training',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Part-time Cleaner',
          abilities: const [
            'House Cleaning',
            'Laundry & Ironing',
            'Toilet Cleaning',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Nanny',
          abilities: const [
            'Childcare',
            'Cooking',
            'School Runs',
            'Play & Learning',
          ],
          certificates: const [
            'Infant Care Course',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Elderly Caregiver',
          abilities: const [
            'Elderly Care',
            'Medication Reminders',
            'Feeding Assistance',
            'Mobility Assistance',
          ],
          certificates: const [
            'Caregiver Training',
            'Elderly Care Course',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Confinement Nanny',
          abilities: const [
            'Infant Care',
            'Confinement Cooking',
            'Postnatal Support',
          ],
          certificates: const [
            'Confinement Nanny Course',
            'Infant Care Course',
          ],
        ),
        WorkRole(
          name: 'Cook / Helper',
          abilities: const [
            'Cooking',
            'Marketing & Groceries',
            'House Cleaning',
          ],
          certificates: const [
            'Food Handling Certificate',
          ],
        ),
        WorkRole(
          name: 'Home Nurse Aide',
          abilities: const [
            'Bedridden Care',
            'Medication Reminders',
            'Wound Dressing',
            'Mobility Assistance',
          ],
          certificates: const [
            'Caregiver Training',
            'First Aid',
            'BLS / CPR',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Office & Administration',
      icon: Icons.business_center_outlined,
      path: WorkPath.professional,
      roles: [
        WorkRole(
          name: 'Admin Assistant',
          abilities: const [
            'MS Excel',
            'MS Word',
            'Filing & Records',
            'Scheduling',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Receptionist',
          abilities: const [
            'Customer Support',
            'Scheduling',
            'Email Handling',
            'Call Handling',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Data Entry Clerk',
          abilities: const [
            'Data Entry',
            'MS Excel',
            'Filing & Records',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Operations Executive',
          abilities: const [
            'MS Excel',
            'Scheduling',
            'Vendor Coordination',
            'Reporting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'HR Executive',
          abilities: const [
            'Payroll Support',
            'Recruitment Coordination',
            'MS Excel',
            'Filing & Records',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Accounts Assistant',
          abilities: const [
            'Invoicing',
            'Bookkeeping',
            'MS Excel',
            'Bank Reconciliation',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Customer Service Officer',
          abilities: const [
            'Customer Support',
            'Email Handling',
            'Call Handling',
            'CRM Systems',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Office Manager',
          abilities: const [
            'Scheduling',
            'Vendor Coordination',
            'Reporting',
            'Team Supervision',
          ],
          certificates: const [],
        ),
      ],
    ),
    WorkCategory(
      name: 'Engineering',
      icon: Icons.engineering_outlined,
      path: WorkPath.professional,
      roles: [
        WorkRole(
          name: 'Civil Engineer',
          abilities: const [
            'Civil Engineering',
            'AutoCAD',
            'Site Supervision',
            'Project Planning',
          ],
          certificates: const [
            'Professional Engineer',
          ],
        ),
        WorkRole(
          name: 'Mechanical Engineer',
          abilities: const [
            'Mechanical Design',
            'AutoCAD',
            'Preventive Maintenance',
            'Project Planning',
          ],
          certificates: const [
            'Professional Engineer',
          ],
        ),
        WorkRole(
          name: 'Electrical Engineer',
          abilities: const [
            'Electrical Systems',
            'AutoCAD',
            'Fault Finding',
            'Project Planning',
          ],
          certificates: const [
            'Professional Engineer',
            'Electrical Wireman Licence',
          ],
        ),
        WorkRole(
          name: 'Site Engineer',
          abilities: const [
            'Site Supervision',
            'Reading Drawings',
            'Quality Control',
            'Method Statements',
          ],
          certificates: const [
            'Safety Officer Certificate',
          ],
        ),
        WorkRole(
          name: 'Project Engineer',
          abilities: const [
            'Project Planning',
            'Quality Control',
            'Method Statements',
            'Reporting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'QA/QC Engineer',
          abilities: const [
            'Quality Control',
            'Method Statements',
            'Site Inspection',
            'Reporting',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Maintenance Engineer',
          abilities: const [
            'Preventive Maintenance',
            'Fault Finding',
            'HVAC',
            'Electrical Systems',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Draughtsman',
          abilities: const [
            'AutoCAD',
            'Reading Drawings',
            'BIM',
            'Structural Design',
          ],
          certificates: const [],
        ),
      ],
    ),
    WorkCategory(
      name: 'Security',
      icon: Icons.shield_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Security Guard',
          abilities: const [
            'Patrolling',
            'Access Control',
            'Incident Reporting',
            'Night Shift',
          ],
          certificates: const [
            'Security Licence',
            'Basic Licensing Unit',
          ],
        ),
        WorkRole(
          name: 'Security Officer',
          abilities: const [
            'Patrolling',
            'Access Control',
            'CCTV Monitoring',
            'Report Writing',
          ],
          certificates: const [
            'Security Licence',
            'Fire Safety Certificate',
          ],
        ),
        WorkRole(
          name: 'Senior Security Officer',
          abilities: const [
            'Team Supervision',
            'Incident Reporting',
            'Crowd Control',
            'Fire Safety',
          ],
          certificates: const [
            'Security Licence',
            'Fire Safety Certificate',
            'First Aid',
          ],
        ),
        WorkRole(
          name: 'Site Security Supervisor',
          abilities: const [
            'Team Supervision',
            'Access Control',
            'Report Writing',
            'Crowd Control',
          ],
          certificates: const [
            'Security Licence',
            'Supervisor Safety Course',
          ],
        ),
        WorkRole(
          name: 'CCTV Operator',
          abilities: const [
            'CCTV Monitoring',
            'Incident Reporting',
            'Night Shift',
            'Report Writing',
          ],
          certificates: const [
            'Security Licence',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Cleaning & Facilities',
      icon: Icons.cleaning_services_outlined,
      path: WorkPath.field,
      roles: [
        WorkRole(
          name: 'Cleaner',
          abilities: const [
            'General Cleaning',
            'Toilet Cleaning',
            'Waste Disposal',
            'Floor Polishing',
          ],
          certificates: const [
            'Cleaning Certificate',
          ],
        ),
        WorkRole(
          name: 'Office Cleaner',
          abilities: const [
            'General Cleaning',
            'Waste Disposal',
            'Pantry Upkeep',
          ],
          certificates: const [
            'Cleaning Certificate',
          ],
        ),
        WorkRole(
          name: 'School Cleaner',
          abilities: const [
            'General Cleaning',
            'Toilet Cleaning',
            'Waste Disposal',
          ],
          certificates: const [
            'Cleaning Certificate',
          ],
        ),
        WorkRole(
          name: 'Hospital Cleaner',
          abilities: const [
            'General Cleaning',
            'Infection Control Cleaning',
            'Waste Disposal',
          ],
          certificates: const [
            'Cleaning Certificate',
            'Chemical Handling',
          ],
        ),
        WorkRole(
          name: 'Landscaper / Gardener',
          abilities: const [
            'Gardening',
            'Grass Cutting',
            'Plant Care',
            'Irrigation',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Pest Control Technician',
          abilities: const [
            'Pest Spraying',
            'Chemical Handling',
            'Site Inspection',
          ],
          certificates: const [
            'Pest Control Licence',
            'Chemical Handling',
          ],
        ),
        WorkRole(
          name: 'Handyman',
          abilities: const [
            'Minor Repairs',
            'Plumbing Repairs',
            'Electrical Repairs',
            'Painting',
          ],
          certificates: const [
            'Trade Test Certificate',
          ],
        ),
        WorkRole(
          name: 'Air-Con Technician',
          abilities: const [
            'Air-Con Servicing',
            'Gas Charging',
            'Fault Finding',
            'Working at Heights',
          ],
          certificates: const [
            'Air-Con Servicing Certificate',
            'Work at Height Certificate',
          ],
        ),
        WorkRole(
          name: 'Facilities Technician',
          abilities: const [
            'Minor Repairs',
            'Fault Finding',
            'Preventive Maintenance',
          ],
          certificates: const [
            'Trade Test Certificate',
          ],
        ),
      ],
    ),
    WorkCategory(
      name: 'Finance & Banking',
      icon: Icons.account_balance_outlined,
      path: WorkPath.professional,
      roles: [
        WorkRole(
          name: 'Accounts Executive',
          abilities: const [
            'Bookkeeping',
            'Accounts Payable',
            'Accounts Receivable',
            'Tally',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Accountant',
          abilities: const [
            'Bookkeeping',
            'Financial Analysis',
            'GST Compliance',
            'Bank Reconciliation',
          ],
          certificates: const [
            'CA / CPA',
            'Diploma in Accounting',
          ],
        ),
        WorkRole(
          name: 'Financial Analyst',
          abilities: const [
            'Financial Analysis',
            'Excel Modelling',
            'Reporting',
            'SAP',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Audit Assistant',
          abilities: const [
            'Auditing',
            'Bookkeeping',
            'Documentation',
          ],
          certificates: const [
            'Diploma in Accounting',
          ],
        ),
        WorkRole(
          name: 'Bank Teller',
          abilities: const [
            'Cash Handling',
            'Customer Service',
            'Banking Systems',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Credit Officer',
          abilities: const [
            'Credit Assessment',
            'Documentation',
            'Customer Service',
          ],
          certificates: const [],
        ),
        WorkRole(
          name: 'Payroll Executive',
          abilities: const [
            'Payroll Support',
            'MS Excel',
            'Statutory Filing',
          ],
          certificates: const [],
        ),
      ],
    ),
  ];

  /// Category names, for every dropdown and filter in the app.
  static List<String> get categories =>
      [allRoles, ...workCategories.map((c) => c.name)];

  static WorkCategory? categoryByName(String name) {
    for (final c in workCategories) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// True when the category is field work, so the app asks about trades,
  /// licences and wages rather than skills and degrees. Unknown categories
  /// default to the field path — the majority of Lucky Boss placements are
  /// field work, so that is the safer guess.
  static bool isFieldCategory(String name) =>
      categoryByName(name)?.isField ?? true;

  static const List<String> experienceLevels = [
    'Entry Level (0–2 yrs)',
    'Mid Level (3–5 yrs)',
    'Senior (6–9 yrs)',
    'Lead / Principal (10+ yrs)',
  ];

  /// How a candidate wants their pay quoted. A site worker thinks in a daily
  /// rate and a salaried employee thinks in a monthly figure; showing one of
  /// them the other's unit makes the number meaningless.
  static const List<String> payPeriods = ['Per day', 'Per month', 'Per year'];

  /// Languages that matter across Singapore, Malaysia and India. Spec §31 lists
  /// Languages as part of the complete profile, and for domestic, care and
  /// service work it is often the deciding factor in a placement.
  static const List<String> commonLanguages = [
    'English', 'Tamil', 'Hindi', 'Malay', 'Mandarin', 'Bengali', 'Telugu',
    'Malayalam', 'Kannada', 'Marathi', 'Punjabi', 'Nepali', 'Burmese',
    'Tagalog', 'Indonesian', 'Thai', 'Hokkien', 'Cantonese',
  ];

  /// Work authorisation, which for this agency's markets is a screening
  /// question rather than a detail — spec §31 "Work Permit Information".
  static const List<String> workPermitStatuses = [
    'Citizen',
    'Permanent Resident',
    'Have a valid work permit',
    'Have an employment pass',
    'Need employer to sponsor a permit',
    'Student pass',
    'Not sure',
  ];

  static const List<String> availabilityOptions = [
    'Immediately',
    'Within 1 week',
    'Within 2 weeks',
    'Within 1 month',
    'More than 1 month',
  ];

  /// Flat list of every ability across every category.
  ///
  /// Kept for the profile editor's free-text suggestions. It used to be a
  /// hand-written list of thirty-six entries that were almost entirely
  /// programming languages, which meant a candidate typing "wel" for welding
  /// was offered nothing at all.
  static List<String> get verifiedSkillDictionary =>
      _union([for (final c in workCategories) ...c.abilities]);

  /// Every job title across every category, for search and type-ahead.
  static List<String> get allRoleTitles =>
      _union([for (final c in workCategories) ...c.roleNames]);

  /// The category a job title belongs to, or null when it is not one we know.
  /// Lets a profile that only has a job title still be treated as field work.
  static WorkCategory? categoryForRole(String roleName) {
    for (final c in workCategories) {
      if (c.role(roleName) != null) return c;
    }
    return null;
  }

  /// The abilities worth offering a candidate: their role's if we know it,
  /// otherwise the whole category's.
  static List<String> abilitiesFor({String category = '', String role = ''}) {
    final cat = categoryByName(category) ?? categoryForRole(role);
    if (cat == null) return verifiedSkillDictionary;
    final r = cat.role(role);
    if (r == null || r.abilities.isEmpty) return cat.abilities;
    // The role's own work first, then the rest of the category — a plumber who
    // also lays tiles must still be able to say so.
    return _union([...r.abilities, ...cat.abilities]);
  }

  /// The licences worth offering. Unlike abilities this does **not** fall back
  /// to the whole category once a role is known: showing a plumber a crane
  /// licence is not a harmless extra option, it is the app telling him we do
  /// not know what his job is.
  static List<String> certificatesFor({String category = '', String role = ''}) {
    final cat = categoryByName(category) ?? categoryForRole(role);
    if (cat == null) return const [];
    final r = cat.role(role);
    if (r != null) return r.certificates;
    return cat.certificates;
  }
}
