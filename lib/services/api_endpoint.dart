String resolveApiEndpoint({
  required String configuredUrl,
  required bool isWeb,
  required Uri pageUri,
}) {
  if (configuredUrl.isNotEmpty) return configuredUrl;
  return isWeb ? pageUri.origin : 'http://localhost:8000';
}
