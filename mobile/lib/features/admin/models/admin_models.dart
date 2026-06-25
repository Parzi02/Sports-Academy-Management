class AdminProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? profilePhotoBase64;
  final String branchName;
  final String? upiId;

  AdminProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.profilePhotoBase64,
    required this.branchName,
    this.upiId,
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
      upiId: json['upi_id']?.toString(),
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
  final String? coachId;
  final String? coachName;
  final String? paymentStatus;
  final String? membershipEndDate;

  AdminMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.memberId,
    required this.role,
    this.profilePhotoBase64,
    this.coachId,
    this.coachName,
    this.paymentStatus,
    this.membershipEndDate,
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhotoBase64: json['profile_photo_base64']?.toString(),
      coachId: json['coach_id']?.toString(),
      coachName: json['coach_name']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      membershipEndDate: json['membership_end_date']?.toString(),
    );
  }
}

class AdminCoach {
  final String id;
  final String name;
  final String? upiId;

  AdminCoach({
    required this.id,
    required this.name,
    this.upiId,
  });

  factory AdminCoach.fromJson(Map<String, dynamic> json) {
    return AdminCoach(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      upiId: json['upi_id']?.toString(),
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
  final double amountDue;
  final String membershipType;
  final List<MemberAttendanceRecord> attendance;
  final List<MemberPaymentRecord> payments;

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
    required this.amountDue,
    required this.membershipType,
    required this.attendance,
    required this.payments,
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
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0.0,
      membershipType: json['membership_type']?.toString() ?? 'Monthly',
      attendance: (json['attendance'] as List? ?? [])
          .map((e) => MemberAttendanceRecord.fromJson(e))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => MemberPaymentRecord.fromJson(e))
          .toList(),
    );
  }
}


class MemberAttendanceRecord {
  final String id;
  final String date;
  final String status;
  final String batchName;

  MemberAttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.batchName,
  });

  factory MemberAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return MemberAttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
    );
  }
}

class MemberPaymentRecord {
  final String id;
  final String amount;
  final String planType;
  final String utrNumber;
  final String status;
  final String date;

  MemberPaymentRecord({
    required this.id,
    required this.amount,
    required this.planType,
    required this.utrNumber,
    required this.status,
    required this.date,
  });

  factory MemberPaymentRecord.fromJson(Map<String, dynamic> json) {
    return MemberPaymentRecord(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      planType: json['plan_type']?.toString() ?? '',
      utrNumber: json['utr_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}


class AdminBatch {
  final String id;
  final String name;
  final String sport;
  final String startTime;
  final String endTime;
  final String? coachId;

  AdminBatch({
    required this.id,
    required this.name,
    required this.sport,
    required this.startTime,
    required this.endTime,
    this.coachId,
  });

  factory AdminBatch.fromJson(Map<String, dynamic> json) {
    return AdminBatch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sport: json['sport']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      coachId: json['coach_id']?.toString(),
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
