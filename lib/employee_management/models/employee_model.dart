class Employee {
  final String id;
  String name;
  String? phoneNumber;
  String? position;
  String? nid;
  double? salary;
  double? amountToPay; 
  String? imageUrl;
  String? address;
  String? emergencyContact;

  Employee({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.position,
    this.nid,
    this.salary,
    this.amountToPay, 
    this.imageUrl,
    this.address,
    this.emergencyContact,
  });

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'position': position,
      'nid': nid,
      'salary': salary,
      'amountToPay': amountToPay, 
      'imageUrl': imageUrl,
      'address': address,
      'emergencyContact': emergencyContact,
    };
  }

  
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      position: map['position'],
      nid: map['nid'],
      salary: map['salary']?.toDouble(),
      amountToPay: map['amountToPay']?.toDouble(), 
      imageUrl: map['imageUrl'],
      address: map['address'],
      emergencyContact: map['emergencyContact'],
    );
  }
}
