class AdminStats {
  final DashboardMetrics metrics;
  final RecentActivity recentActivity;
  final List<StatusBreakdown> appStatusBreakdown;
  final List<WorkModeBreakdown> workModeBreakdown;
  final List<IndustryBreakdown> industryBreakdown;
  final List<TrendingInternship> trendingInternships;

  AdminStats({
    required this.metrics,
    required this.recentActivity,
    required this.appStatusBreakdown,
    required this.workModeBreakdown,
    required this.industryBreakdown,
    required this.trendingInternships,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      metrics: DashboardMetrics.fromJson(json['metrics'] ?? {}),
      recentActivity: RecentActivity.fromJson(json['recentActivity'] ?? {}),
      appStatusBreakdown: (json['appStatusBreakdown'] as List?)
              ?.map((e) => StatusBreakdown.fromJson(e))
              .toList() ??
          [],
      workModeBreakdown: (json['workModeBreakdown'] as List?)
              ?.map((e) => WorkModeBreakdown.fromJson(e))
              .toList() ??
          [],
      industryBreakdown: (json['industryBreakdown'] as List?)
              ?.map((e) => IndustryBreakdown.fromJson(e))
              .toList() ??
          [],
      trendingInternships: (json['trendingInternships'] as List?)
              ?.map((e) => TrendingInternship.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Fallback empty state
  factory AdminStats.empty() {
    return AdminStats(
      metrics: DashboardMetrics.empty(),
      recentActivity: RecentActivity.empty(),
      appStatusBreakdown: [],
      workModeBreakdown: [],
      industryBreakdown: [],
      trendingInternships: [],
    );
  }
}

class DashboardMetrics {
  final int totalStudents;
  final int totalCompanies;
  final int totalInternships;
  final int totalApplications;
  final int pendingCompanies;
  final int approvedCompanies;
  final int suspendedCompanies;
  final int activeInternships;
  final int inactiveInternships;

  DashboardMetrics({
    required this.totalStudents,
    required this.totalCompanies,
    required this.totalInternships,
    required this.totalApplications,
    required this.pendingCompanies,
    required this.approvedCompanies,
    required this.suspendedCompanies,
    required this.activeInternships,
    required this.inactiveInternships,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalStudents: _parseInt(json['totalStudents']),
      totalCompanies: _parseInt(json['totalCompanies']),
      totalInternships: _parseInt(json['totalInternships']),
      totalApplications: _parseInt(json['totalApplications']),
      pendingCompanies: _parseInt(json['pendingCompanies']),
      approvedCompanies: _parseInt(json['approvedCompanies']),
      suspendedCompanies: _parseInt(json['suspendedCompanies']),
      activeInternships: _parseInt(json['activeInternships']),
      inactiveInternships: _parseInt(json['inactiveInternships']),
    );
  }

  factory DashboardMetrics.empty() => DashboardMetrics.fromJson({});
}

class RecentActivity {
  final int applications;
  final int students;
  final int companies;

  RecentActivity({
    required this.applications,
    required this.students,
    required this.companies,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      applications: _parseInt(json['applications']),
      students: _parseInt(json['students']),
      companies: _parseInt(json['companies']),
    );
  }

  factory RecentActivity.empty() => RecentActivity.fromJson({});
}

class StatusBreakdown {
  final String status;
  final int count;

  StatusBreakdown({required this.status, required this.count});

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      status: json['_id']?.toString() ?? 'Unknown',
      count: _parseInt(json['count']),
    );
  }
}

class WorkModeBreakdown {
  final String mode;
  final int count;

  WorkModeBreakdown({required this.mode, required this.count});

  factory WorkModeBreakdown.fromJson(Map<String, dynamic> json) {
    return WorkModeBreakdown(
      mode: json['_id']?.toString() ?? 'Unknown',
      count: _parseInt(json['count']),
    );
  }
}

class IndustryBreakdown {
  final String industry;
  final int count;

  IndustryBreakdown({required this.industry, required this.count});

  factory IndustryBreakdown.fromJson(Map<String, dynamic> json) {
    return IndustryBreakdown(
      industry: json['_id']?.toString() ?? 'Other',
      count: _parseInt(json['count']),
    );
  }
}

class TrendingInternship {
  final String title;
  final String companyName;
  final int applicationCount;

  TrendingInternship({
    required this.title,
    required this.companyName,
    required this.applicationCount,
  });

  factory TrendingInternship.fromJson(Map<String, dynamic> json) {
    return TrendingInternship(
      title: json['title']?.toString() ?? 'Unknown',
      companyName: json['companyName']?.toString() ?? 'Unknown Company',
      applicationCount: _parseInt(json['applicationCount']),
    );
  }
}

// ----------------------
// ANALYTICS DATA MODELS
// ----------------------

class AdminAnalytics {
  final List<DateTrend> applicationsTrend;
  final List<DateTrend> registrationsTrend; // Simplified if structure is similar
  final double successRate;
  final double avgMatchScore;
  final List<TopSkill> topSkills;

  AdminAnalytics({
    required this.applicationsTrend,
    required this.registrationsTrend,
    required this.successRate,
    required this.avgMatchScore,
    required this.topSkills,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      applicationsTrend: (json['applicationsTrend'] as List?)
              ?.map((e) => DateTrend.fromJson(e))
              .toList() ??
          [],
      registrationsTrend: [], // Add parsing if structure known, else empty
      successRate: _parseDouble(json['successRate']),
      avgMatchScore: _parseDouble(json['avgMatchScore']),
      topSkills: (json['topSkills'] as List?)
              ?.map((e) => TopSkill.fromJson(e))
              .toList() ??
          [],
    );
  }

  factory AdminAnalytics.empty() {
    return AdminAnalytics(
      applicationsTrend: [],
      registrationsTrend: [],
      successRate: 0.0,
      avgMatchScore: 0.0,
      topSkills: [],
    );
  }
}

class DateTrend {
  final String date;
  final int count;

  DateTrend({required this.date, required this.count});

  factory DateTrend.fromJson(Map<String, dynamic> json) {
    // Handle specific structure from backend
    // _id could be the date string if using aggregate $group
    return DateTrend(
      date: json['_id']?.toString() ?? '',
      count: _parseInt(json['count']),
    );
  }
}

class TopSkill {
  final String name;
  final int count;

  TopSkill({required this.name, required this.count});

  factory TopSkill.fromJson(Map<String, dynamic> json) {
    return TopSkill(
      name: json['_id']?.toString() ?? 'Unknown',
      count: _parseInt(json['count']),
    );
  }
}

// Helper functions for safe parsing
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class StudentUser {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String university;
  final String degree;
  final int applicationCount;
  final List<String> skills;

  StudentUser({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.university,
    required this.degree,
    required this.applicationCount,
    required this.skills,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['_id']?.toString() ?? '',
      userId: json['user'] is Map ? (json['user']['_id']?.toString() ?? '') : (json['user']?.toString() ?? ''),
      fullName: json['fullName']?.toString() ?? 'Unknown Student',
      email: json['user'] is Map ? (json['user']['email']?.toString() ?? 'No email') : 'No email',
      university: json['university']?.toString() ?? 'University not specified',
      degree: json['degree']?.toString() ?? '',
      applicationCount: _parseInt(json['applicationCount']),
      skills: (json['skills'] as List?)?.map((e) {
        if (e is Map) return e['name']?.toString() ?? '';
        return e.toString();
      }).where((s) => s.isNotEmpty).toList() ?? [],
    );
  }
}

class CompanyUser {
  final String id;
  final String userId;
  final String companyName;
  final String email;
  final String industry;
  final String location;
  final bool isApproved;
  final bool isSuspended;

  CompanyUser({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.email,
    required this.industry,
    required this.location,
    required this.isApproved,
    required this.isSuspended,
  });

  factory CompanyUser.fromJson(Map<String, dynamic> json) {
    return CompanyUser(
      id: json['_id']?.toString() ?? '',
      userId: json['user'] is Map ? (json['user']['_id']?.toString() ?? '') : (json['user']?.toString() ?? ''),
      companyName: json['companyName']?.toString() ?? 'Unknown Company',
      email: json['user'] is Map ? (json['user']['email']?.toString() ?? 'No email') : 'No email',
      industry: json['industry']?.toString() ?? 'Industry not specified',
      location: json['location']?.toString() ?? '',
      isApproved: json['isApproved'] == true,
      isSuspended: json['isSuspended'] == true,
    );
  }
}

class InternshipModel {
  final String id;
  final String title;
  final String companyName;
  final String companyId;
  final String workMode;
  final String location;
  final String status;
  final bool isActive;
  final bool companySuspended;
  final int applicantCount;
  final Map<String, dynamic>? stipend;
  final List<String> skills;
  final List<dynamic> statusBreakdown;

  InternshipModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyId,
    required this.workMode,
    required this.location,
    required this.status,
    required this.isActive,
    required this.companySuspended,
    required this.applicantCount,
    this.stipend,
    required this.skills,
    required this.statusBreakdown,
  });

  factory InternshipModel.fromJson(Map<String, dynamic> json) {
    return InternshipModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Position',
      companyName: json['company'] is Map ? (json['company']['companyName']?.toString() ?? 'Unknown Company') : 'Unknown Company',
      companyId: json['company'] is Map ? (json['company']['_id']?.toString() ?? '') : (json['company']?.toString() ?? ''),
      workMode: json['workMode']?.toString() ?? 'On-site',
      location: json['location']?.toString() ?? 'Not specified',
      status: json['status']?.toString() ?? 'Open',
      isActive: json['isActive'] == true,
      companySuspended: json['company'] is Map ? (json['company']['isSuspended'] == true) : false,
      applicantCount: _parseInt(json['applicationCount']),
      stipend: json['stipend'] is Map ? json['stipend'] : null,
      skills: (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? [],
      statusBreakdown: (json['statusBreakdown'] as List?) ?? [],
    );
  }
}

class ApplicationModel {
  final String id;
  final String status;
  final DateTime appliedAt;
  final double aiMatchScore;
  final String studentName;
  final String studentEmail;
  final String internshipTitle;
  final String companyName;

  ApplicationModel({
    required this.id,
    required this.status,
    required this.appliedAt,
    required this.aiMatchScore,
    required this.studentName,
    required this.studentEmail,
    required this.internshipTitle,
    required this.companyName,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Applied',
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? '') ?? DateTime.now(),
      aiMatchScore: (json['aiMatchScore'] as num?)?.toDouble() ?? 0.0,
      studentName: json['student'] is Map ? (json['student']['fullName']?.toString() ?? 'Unknown Student') : 'Unknown Student',
      studentEmail: (json['student'] is Map && json['student']['user'] is Map) 
          ? (json['student']['user']['email']?.toString() ?? 'No Email') 
          : 'No Email',
      internshipTitle: json['internship'] is Map ? (json['internship']['title']?.toString() ?? 'Unknown Internship') : 'Unknown Internship',
      companyName: json['company'] is Map ? (json['company']['companyName']?.toString() ?? 'Unknown Company') : 'Unknown Company',
    );
  }
}

class AIConfigModel {
  final Map<String, double> weights;
  final DateTime updatedAt;

  AIConfigModel({
    required this.weights,
    required this.updatedAt,
  });

  factory AIConfigModel.fromJson(Map<String, dynamic> json) {
    final weightsMap = <String, double>{};
    if (json['weights'] is Map) {
      (json['weights'] as Map).forEach((key, value) {
        weightsMap[key.toString()] = (value as num).toDouble();
      });
    }
    return AIConfigModel(
      weights: weightsMap,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static AIConfigModel empty() {
    return AIConfigModel(
      weights: {},
      updatedAt: DateTime.now(),
    );
  }
}



