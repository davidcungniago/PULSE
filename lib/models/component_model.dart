class Component {
  const Component(
      {required this.id,
      required this.scanResultId,
      required this.name,
      required this.version,
      required this.ecosystem,
      required this.purl,
      required this.license});
  final String id;
  final String scanResultId;
  final String name;
  final String version;
  final String ecosystem;
  final String purl;
  final String license;
  factory Component.fromJson(Map<String, dynamic> json) => Component(
        id: json['Id'] as String,
        scanResultId: json['ScanResultId'] as String,
        name: json['Name'] as String,
        version: json['Version'] as String,
        ecosystem: json['Ecosystem'] as String,
        purl: json['Purl'] as String,
        license: json['License'] as String,
      );
  Map<String, dynamic> toJson() => {
        'Id': id,
        'ScanResultId': scanResultId,
        'Name': name,
        'Version': version,
        'Ecosystem': ecosystem,
        'Purl': purl,
        'License': license
      };
}
