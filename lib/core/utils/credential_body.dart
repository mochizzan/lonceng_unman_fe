/// Shared request-body builder for LMS credential-passing endpoints.
///
/// Many datasources POST `npm` + `password` (and optionally
/// `tahun_ajaran` / `semester`) in exactly the same shape.
/// This helper eliminates that repetition.
///
/// Set [camelCaseTahunAjaran] to `true` for endpoints that expect
/// `tahunAjaran` (camelCase) instead of the default `tahun_ajaran`
/// (snake_case). The KHS PDF file endpoint uses camelCase.
Map<String, String> lmsCredentialBody({
  required String npm,
  required String password,
  String? tahunAjaran,
  String? semester,
  bool camelCaseTahunAjaran = false,
}) {
  final body = <String, String>{'npm': npm, 'password': password};
  if (tahunAjaran != null) {
    body[camelCaseTahunAjaran ? 'tahunAjaran' : 'tahun_ajaran'] = tahunAjaran;
  }
  if (semester != null) body['semester'] = semester;
  return body;
}
