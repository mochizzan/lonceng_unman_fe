// Application utilities
// Shared utility functions used across features.

/// Compares two lists for equality.
/// Returns true if both lists have the same length and all elements are equal.
bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
