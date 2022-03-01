part of kyber;

class KyberDigest {
  KyberDigest(bytes) : _bytes = bytes;

  final List<int> _bytes;
  List<int> get bytes => _bytes;

  String toHex() {
    return _bytes.map((byte) => byte.toRadixString(16)).join();
  }

  @override
  String toString() {
    return _bytes.toString();
  }
}

class KyberGenerationResult {
  KyberGenerationResult({
    required KyberDigest public,
    required KyberDigest private,
  })  : _private = private,
        _public = public;
  final KyberDigest _private;
  final KyberDigest _public;
  KyberDigest get privateKey => _private;
  KyberDigest get publicKey => _public;
}

class KyberEncryptionResult {
  KyberEncryptionResult({
    required KyberDigest cipherText,
    required KyberDigest sharedSecret,
  })  : _sharedSecret = sharedSecret,
        _cipherText = cipherText;
  final KyberDigest _sharedSecret;
  final KyberDigest _cipherText;
  KyberDigest get cipherText => _cipherText;
  KyberDigest get sharedSecret => _sharedSecret;
}

enum KyberLevel { k512, k768, k1024 }

class RejectionSamplingResult {
  RejectionSamplingResult({
    required this.nttRepresentation,
    required this.position,
  });
  List<int> nttRepresentation;
  int position;
}

extension _FilterNull<T> on List<T?> {
  /// Returns all elements of this list that are not null, as a new list
  List<T> noNull() {
    return where((e) => e != null).map((e) => e!).toList();
  }
}
