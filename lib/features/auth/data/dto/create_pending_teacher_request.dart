/// POST `/pending-teacher-request` body — OpenAPI `CreatePendingTeacherRequestDto`.
class CreatePendingTeacherRequestDto {
  const CreatePendingTeacherRequestDto({
    required this.teacherName,
    required this.email,
    required this.password,
    required this.nationality,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.qualification,
    required this.hasCertificate,
    required this.numberOfMemorizedJuz,
    required this.hasIjazahInHifz,
    required this.hasSanadInHifz,
    required this.tajweedLevel,
    required this.teachingAgeGroup,
    required this.availableWorkPeriod,
    required this.centerId,
  });

  final String teacherName;
  final String email;
  final String password;
  final String nationality;
  final String phone;
  final String address;
  final String birthDate;
  final String qualification;
  final bool hasCertificate;
  final int numberOfMemorizedJuz;
  final bool hasIjazahInHifz;
  final bool hasSanadInHifz;
  final String tajweedLevel;
  final List<String> teachingAgeGroup;
  final List<String> availableWorkPeriod;
  final int centerId;

  Map<String, dynamic> toJson() => {
        'teacherName': teacherName,
        'email': email,
        'password': password,
        'nationality': nationality,
        'phone': phone,
        'address': address,
        'birthDate': birthDate,
        'qualification': qualification,
        'hasCertificate': hasCertificate,
        'numberOfMemorizedJuz': numberOfMemorizedJuz,
        'hasIjazahInHifz': hasIjazahInHifz,
        'hasSanadInHifz': hasSanadInHifz,
        'tajweedLevel': tajweedLevel,
        'teachingAgeGroup': teachingAgeGroup,
        'availableWorkPeriod': availableWorkPeriod,
        'centerId': centerId,
      };
}
