class CheckInRequest {
  final String numberPlate;
  final String phoneNumber;

  CheckInRequest(this.numberPlate, this.phoneNumber);

  Map<String, dynamic> toJson() {
    return {
      'number_plate': numberPlate,
      'phone_number': phoneNumber,
    };
  }
}
