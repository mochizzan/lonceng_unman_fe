/// Shared request-body builder for LMS credential-passing endpoints.
///
/// Many datasources POST `npm` + `password` (and optionally
/// `tahun_ajaran` / `semester`) in exactly the same shape.
/// This helper eliminates that repetition.
Map<String, String> lmsCredentialBody({
  required String npm,
  required String password,
  String? tahunAjaran,
  String? semester,
}) {
  final body = <String, String>{'npm': npm, 'password': password};
  if (tahunAjaran != null) body['tahun_ajaran'] = tahunAjaran;
  if (semester != null) body['semester'] = semester;
  return body;
}
