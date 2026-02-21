# API Integration Review or Scaffold

Review an existing API service file or scaffold a new one for HoosierCiv.

## Instructions

The user will either:
- Name an existing service file to review (e.g. `openstates_service.dart`)
- Describe a new API to integrate (e.g. "Indiana Secretary of State voter registration lookup")

### If Reviewing an Existing Service
1. Read the file.
2. Check for:
   - Proper error handling (`try/catch`, typed exceptions)
   - HTTP timeout configuration
   - Response parsing safety (null checks, type coercion)
   - API key exposure (keys must come from environment/constants, never hardcoded)
   - Rate limiting awareness
   - Missing endpoints relative to the feature requirements in `Indiana_Civic_App_Core_Civic_Actions.txt`
3. Provide a prioritized list of issues and suggested fixes.

### If Scaffolding a New Integration
Generate `lib/data/services/<api_name>_service.dart` with:

```dart
class <ApiName>Service {
  final http.Client _client;
  final String _apiKey; // injected, never hardcoded

  <ApiName>Service({required http.Client client, required String apiKey})
      : _client = client,
        _apiKey = apiKey;

  Future<T> fetchSomething() async {
    try {
      final response = await _client.get(
        Uri.parse('...'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }

      return _parseResponse(response.body);
    } on TimeoutException {
      throw ApiException(408, 'Request timed out');
    }
  }
}
```

## Known HoosierCiv APIs
- **Google Civic Info API** — legislator lookup by address
- **OpenStates API** — Indiana bill and legislator data
- **Google News RSS** — bill-related news headlines
- **Supabase** — auth, database, edge functions (use `supabase_flutter` package, not raw HTTP)

## Security Rules
- API keys must be stored in `.env` and accessed via `flutter_dotenv` or compile-time `--dart-define`
- Never commit keys to git — check `.gitignore` includes `.env`
- Warn if any hardcoded credentials are found

$ARGUMENTS
