class Component {
  const Component({required this.id, required this.scanResultId, required this.name, required this.version, required this.ecosystem, required this.purl, required this.license});
  final String id;
  final String scanResultId;
  final String name;
  final String version;
  final String ecosystem;
  final String purl;
  final String license;
  factory Component.fromJson(Map<String, dynamic> json) => Component(
        id: json['id'] as String, scanResultId: json['scanResultId'] as String, name: json['name'] as String,
        version: json['version'] as String, ecosystem: json['ecosystem'] as String, purl: json['purl'] as String,
        license: json['license'] as String,
      );
  Map<String, dynamic> toJson() => {'id': id, 'scanResultId': scanResultId, 'name': name, 'version': version, 'ecosystem': ecosystem, 'purl': purl, 'license': license};
}
