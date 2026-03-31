class AdminProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? profilePhotoBase64;
  final String branchName;

  AdminProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.profilePhotoBase64,
    required this.branchName,
  });

  factory AdminProfileData.fromJson(Map<String, dynamic> json) {
    return AdminProfileData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      profilePhotoBase64: json['profile_photo_base64']?.toString(),
      branchName: json['branch_name']?.toString() ?? '',
    );
  }
}

class AdminMember {
  final String id;
  final String name;
  final String phone;
  final String memberId;
  final String role;
  final String? profilePhotoBase64;

  AdminMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.memberId,
    required this.role,
    this.profilePhotoBase64,
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhotoBase64: json['profile_photo_base64']?.toString(),
    );
  }
}

class AdminMemberProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String address;
  final String memberId;
  final String? profilePhotoBase64;
  final String dateOfJoining;
  final String status;
  final String batchName;
  final String batchTime;

  AdminMemberProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address,
    required this.memberId,
    this.profilePhotoBase64,
    required this.dateOfJoining,
    required this.status,
    required this.batchName,
    required this.batchTime,
  });

  factory AdminMemberProfile.fromJson(Map<String, dynamic> json) {
    return AdminMemberProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? 'N/A',
      dob: json['dob']?.toString() ?? 'N/A',
      gender: json['gender']?.toString() ?? 'N/A',
      address: json['address']?.toString() ?? 'N/A',
      memberId: json['member_id']?.toString() ?? '',
      profilePhotoBase64: json['profile_photo_base64']?.toString(),
      dateOfJoining: json['date_of_joining']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      batchName: json['batch_name']?.toString() ?? 'No Batch',
      batchTime: json['batch_time']?.toString() ?? '',
    );
  }
}

class AdminBatch {
  final String id;
  final String name;
  final String sport;
  final String startTime;
  final String endTime;

  AdminBatch({
    required this.id,
    required this.name,
    required this.sport,
    required this.startTime,
    required this.endTime,
  });

  factory AdminBatch.fromJson(Map<String, dynamic> json) {
    return AdminBatch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sport: json['sport']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}

class AdminEvent {
  final String id;
  final String title;
  final String description;
  final String date;
  final String startTime;
  final String endTime;
  final String venue;
  final String sportCategory;
  final String eventCategory;
  final String? imageBase64;

  AdminEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.sportCategory,
    required this.eventCategory,
    this.imageBase64,
  });

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    return AdminEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      sportCategory: json['sport_category']?.toString() ?? '',
      eventCategory: json['event_category']?.toString() ?? '',
      imageBase64: json['image_base64'],
    );
  }
}

class DashboardStats {
  final int totalMembers;
  final int totalEvents;

  DashboardStats({required this.totalMembers, required this.totalEvents});

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalMembers: json['totalMembers'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
    );
  }
}

class AttendanceMember {
  final String id;
  final String name;
  final String memberId;
  final String status; // 'present', 'absent', 'pending'

  AttendanceMember({
    required this.id,
    required this.name,
    required this.memberId,
    required this.status,
  });

  factory AttendanceMember.fromJson(Map<String, dynamic> json) {
    return AttendanceMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
