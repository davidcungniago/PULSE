class ParsedRepositoryUrl {
  const ParsedRepositoryUrl(
      {required this.owner, required this.repositoryName});

  final String owner;
  final String repositoryName;
}

final RegExp _repositoryUrl = RegExp(
  r'^https://(github\.com|gitlab\.com)/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+?)(?:\.git)?/?$',
);

ParsedRepositoryUrl? parseRepositoryUrl(String value) {
  final match = _repositoryUrl.firstMatch(value.trim());
  if (match == null) return null;
  return ParsedRepositoryUrl(
    owner: match.group(2)!,
    repositoryName: match.group(3)!,
  );
}

String? repositoryUrlError(String value) {
  final url = value.trim();
  if (url.isEmpty) return 'URL repositori wajib diisi.';
  if (parseRepositoryUrl(url) == null) {
    return 'Gunakan URL GitHub atau GitLab yang valid.';
  }
  return null;
}
