class MemberDashboardData {
  final String attendancePercentage;
  final int attendedSessions;
  final int totalSessions;
  final String feeStatus;
  final String membershipType;
  final String batchName;
  final String batchTime;
  final String sport;
  final String coachName;
  final bool isAttendanceMarkedToday;
  final List<TodaySchedule>? todaySchedule;

  MemberDashboardData({
    required this.isAttendanceMarkedToday,
    required this.attendancePercentage,
    required this.attendedSessions,
    required this.totalSessions,
    required this.feeStatus,
    required this.membershipType,
    required this.batchName,
    required this.batchTime,
    required this.sport,
    required this.coachName,
    this.todaySchedule,
  });

  factory MemberDashboardData.fromJson(Map<String, dynamic> json) {
    return MemberDashboardData(
      isAttendanceMarkedToday: json['isAttendanceMarkedToday'] ?? false,
      attendancePercentage: json['attendancePercentage']?.toString() ?? '0.00',
      attendedSessions: json['attendedSessions'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      feeStatus: json['feeStatus']?.toString() ?? 'due',
      membershipType: json['membershipType']?.toString() ?? 'standard',
      batchName: json['batchName']?.toString() ?? 'No Batch',
      batchTime: json['batchTime']?.toString() ?? 'TBD',
      sport: json['sport']?.toString() ?? 'Academy Training',
      coachName: json['coachName']?.toString() ?? 'Assigned',
      todaySchedule: (json['todaySchedule'] as List?)
          ?.map((e) => TodaySchedule.fromJson(e))
          .toList(),
    );
  }
}

class TodaySchedule {
  final String title;
  final String startTime;
  final String endTime;
  final String coach;
  final String venue;

  TodaySchedule({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.coach,
    required this.venue,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      title: json['title'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      coach: json['coach'] ?? 'Assigned',
      venue: json['venue'] ?? '',
    );
  }
}

class MemberAttendanceLog {
  final String date;
  final String status;

  MemberAttendanceLog({required this.date, required this.status});

  factory MemberAttendanceLog.fromJson(Map<String, dynamic> json) {
    return MemberAttendanceLog(
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class MemberEvent {
  final String id;
  final String title;
  final String sportCategory;
  final String eventCategory;
  final String date;
  final String venue;
  final String status;
  final bool isFavourite;
  final String? imageBase64;

  MemberEvent({
    required this.id,
    required this.title,
    required this.sportCategory,
    required this.eventCategory,
    required this.date,
    required this.venue,
    required this.status,
    this.isFavourite = false,
    this.imageBase64,
  });

  factory MemberEvent.fromJson(Map<String, dynamic> json) {
    return MemberEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      sportCategory: json['sport_category'] ?? '',
      eventCategory: json['event_category'] ?? '',
      date: json['date'] ?? '',
      venue: json['venue'] ?? '',
      status: json['status'] ?? 'upcoming',
      isFavourite: json['is_favourite'] ?? false,
      imageBase64: json['image_base64'],
    );
  }
}

class MemberProfile {
  final String name;
  final String phone;
  final String? email;
  final String? dob;
  final String? gender;
  final String? address;
  final String memberId;
  final String? profilePhotoBase64;
  final String? dateOfJoining;
  final String? sport;
  final String? coachName;

  MemberProfile({
    required this.name,
    required this.phone,
    this.email,
    this.dob,
    this.gender,
    this.address,
    required this.memberId,
    this.profilePhotoBase64,
    this.dateOfJoining,
    this.sport,
    this.coachName,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      memberId: json['member_id'] ?? '',
      profilePhotoBase64: json['profile_photo_base64'],
      dateOfJoining: json['date_of_joining'],
      sport: json['sport'],
      coachName: json['coach_name'] ?? 'Assigned',
    );
  }
}
