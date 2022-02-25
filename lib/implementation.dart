part of kyber;

class Kyber {
  Kyber.k512() : _level = KyberLevel.k512;
  Kyber.k768() : _level = KyberLevel.k768;
  Kyber.k1024() : _level = KyberLevel.k1024;

  final KyberLevel _level;
  KyberLevel get level => _level;

  KyberGenerationResult generateKeys() {
    // IND-CPA keypair
    var keysINDCPA = INDCPA.generateKeys(level);

    var pk = keysINDCPA[0];
    var sk = keysINDCPA[1];

    // FO transform to make IND-CCA2

    // get hash of pk
    var buffer1 = Uint8List.fromList(pk);
    var hash1 = sha3.SHA3(256, sha3.SHA3_PADDING, 256);
    hash1.update(buffer1);
    var pkh = hash1.digest();

    // read 32 random values (0-255) into a 32 byte array
    var rnd = List.filled(32, 0);
    for (int i = 0; i < 32; i++) {
      rnd[i] = nextInt(256);
    }

    // concatenate to form IND-CCA2 private key: sk + pk + h(pk) + rnd
    for (int i = 0; i < pk.length; i++) {
      sk.add(pk[i]);
    }
    for (int i = 0; i < pkh.length; i++) {
      sk.add(pkh[i]);
    }
    for (int i = 0; i < rnd.length; i++) {
      sk.add(rnd[i]);
    }
    return KyberGenerationResult(
      public: KyberDigest(pk),
      private: KyberDigest(sk),
    );
  }

  KyberEncryptionResult encrypt(List<int> pk) {
    // random 32 bytes
    var m = List.filled(32, 0);
    for (int i = 0; i < 32; i++) {
      m[i] = nextInt(256);
    }

    // hash m with SHA3-256
    var buffer1 = Uint8List.fromList(m);
    var hash1 = sha3.SHA3(256, sha3.SHA3_PADDING, 256);
    hash1.update(buffer1);
    var mh = hash1.digest();

    // hash pk with SHA3-256
    var buffer2 = Uint8List.fromList(pk);
    var hash2 = sha3.SHA3(256, sha3.SHA3_PADDING, 256);
    hash2.update(buffer2);
    var pkh = hash2.digest();

    // hash mh and pkh with SHA3-512
    var buffer3 = Uint8List.fromList(mh);
    var buffer4 = Uint8List.fromList(pkh);
    var hash3 = sha3.SHA3(512, sha3.SHA3_PADDING, 512);
    hash3.update(buffer3).update(buffer4);
    var kr = hash3.digest();
    var kr1 = kr.sublist(0, 32);
    var kr2 = kr.sublist(32, 64);

    // generate ciphertext
    var cipherText = INDCPA.encrypt(level, pk, mh, kr2);

    // hash ciphertext with SHA3-256
    var buffer5 = Uint8List.fromList(cipherText);
    var hash4 = sha3.SHA3(256, sha3.SHA3_PADDING, 256);
    hash4.update(buffer5);
    var ch = hash4.digest();

    // hash kr1 and ch with SHAKE-256
    var buffer6 = Uint8List.fromList(kr1);
    var buffer7 = Uint8List.fromList(ch);
    var hash5 = sha3.SHA3(256, sha3.SHAKE_PADDING, 256);
    hash5.update(buffer6).update(buffer7);
    var ss = hash5.digest();

    return KyberEncryptionResult(
      cipherText: KyberDigest(cipherText),
      sharedSecret: KyberDigest(ss),
    );
  }

  KyberDigest decrypt(List<int> cipherText, List<int> privateKey) {
    var end1 = (level == KyberLevel.k1024)
        ? 1536
        : (level == KyberLevel.k768)
            ? 1152
            : 768;
    var end2 = (level == KyberLevel.k1024)
        ? 3104
        : (level == KyberLevel.k768)
            ? 2336
            : 1568;
    var end3 = (level == KyberLevel.k1024)
        ? 3136
        : (level == KyberLevel.k768)
            ? 2368
            : 1600;
    var end4 = (level == KyberLevel.k1024)
        ? 3168
        : (level == KyberLevel.k768)
            ? 2400
            : 1632;
    // extract sk, pk, pkh and z
    var sk = privateKey.sublist(0, end1);
    var pk = privateKey.sublist(end1, end2);
    var pkh = privateKey.sublist(end2, end3);
    var z = privateKey.sublist(end3, end4);

    // IND-CPA decrypt
    var m = INDCPA.decrypt(level, cipherText, sk);

    // hash m and pkh with SHA3-512
    var buffer1 = Uint8List.fromList(m);
    var buffer2 = Uint8List.fromList(pkh);
    var hash1 = sha3.SHA3(512, sha3.SHA3_PADDING, 512);
    hash1.update(buffer1).update(buffer2);
    var kr = hash1.digest();
    var kr1 = kr.sublist(0, 32);
    var kr2 = kr.sublist(32, 64);

    // IND-CPA encrypt
    var cmp = INDCPA.encrypt(level, pk, m, kr2);

    // compare c and cmp
    var fail = !compareArray(cipherText, cmp);

    // hash c with SHA3-256
    var buffer3 = Uint8List.fromList(cipherText);
    var hash2 = sha3.SHA3(256, sha3.SHA3_PADDING, 256);
    hash2.update(buffer3);
    var ch = hash2.digest();

    var ss = <int>[];
    if (!fail) {
      // hash kr1 and ch with SHAKE-256
      var buffer4 = Uint8List.fromList(kr1);
      var buffer5 = Uint8List.fromList(ch);
      var hash3 = sha3.SHA3(256, sha3.SHAKE_PADDING, 256);
      hash3.update(buffer4).update(buffer5);
      ss = hash3.digest();
    } else {
      // hash z and ch with SHAKE-256
      var buffer6 = Uint8List.fromList(z);
      var buffer7 = Uint8List.fromList(ch);
      var hash4 = sha3.SHA3(256, sha3.SHAKE_PADDING, 256);
      hash4.update(buffer6).update(buffer7);
      ss = hash4.digest();
    }
    return KyberDigest(ss);
  }
}
