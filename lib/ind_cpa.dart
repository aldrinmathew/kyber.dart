part of kyber;

class INDCPA {
  static RejectionSamplingResult rejectionSamplingOnUniformRandomBytes(
    List<int> buf,
    int bufl,
    int len,
  ) {
    List<int> r = List.filled(384, 0);
    int val0 = 0, val1 = 0; // d1, d2 in kyber documentation
    int pos = 0; // i
    int ctr = 0; // j
    while (ctr < len && pos + 3 <= bufl) {
      val0 = (KyberFunctions.uint16((buf[pos]) >> 0) |
              (KyberFunctions.uint16(buf[pos + 1]) << 8)) &
          0xFFF;
      val1 = (KyberFunctions.uint16((buf[pos + 1]) >> 4) |
              (KyberFunctions.uint16(buf[pos + 2]) << 4)) &
          0xFFF;
      pos = pos + 3;
      if (val0 < paramsQ) {
        r[ctr] = val0;
        ctr = ctr + 1;
      }
      if (ctr < len && val1 < paramsQ) {
        r[ctr] = val1;
        ctr = ctr + 1;
      }
    }
    var result = RejectionSamplingResult(
      nttRepresentation: r,
      position: ctr,
    );
    return result;
  }

  static List<List<int>> generateKeys(KyberLevel level) {
    var rnd = List.filled(32, 0);
    for (int i = 0; i < 32; i++) {
      rnd[i] = KyberFunctions.nextInt(256);
    }
    var buffer1 = Uint8List.fromList(rnd);
    var hash1 = sha3.SHA3(512, sha3.SHA3_PADDING, 512);
    hash1.update(buffer1);
    var seed = hash1.digest();
    var publicSeed = seed.sublist(0, 32);
    var noiseSeed = seed.sublist(32, 64);
    var a = KyberFunctions.generateMatrixA(level, publicSeed, false);
    var s = List.filled(paramsK(level), <int>[]);
    var nonce = 0;
    for (int i = 0; i < paramsK(level); i++) {
      s[i] = KyberFunctions.sample(noiseSeed, nonce);
      nonce = nonce + 1;
    }
    List<List<int>> e = List.filled(paramsK(level), []);
    for (int i = 0; i < paramsK(level); i++) {
      e[i] = KyberFunctions.sample(noiseSeed, nonce);
      nonce = nonce + 1;
    }
    for (int i = 0; i < paramsK(level); i++) {
      s[i] = NTT.doTransform(s[i]);
    }
    for (int i = 0; i < paramsK(level); i++) {
      e[i] = NTT.doTransform(e[i]);
    }
    for (int i = 0; i < paramsK(level); i++) {
      s[i] = NTT.barrettReducePolynomial(s[i]);
    }
    var pk = List.filled(paramsK(level), <int>[]);
    for (int i = 0; i < paramsK(level); i++) {
      // montgomery reduction
      pk[i] = KyberFunctions.polynomialToMontgomeryDomain(
          NTT.pointwiseMultiply(level, a[i], s));
    }
    for (int i = 0; i < paramsK(level); i++) {
      pk[i] = NTT.addPolynomials(pk[i], e[i]);
    }
    for (int i = 0; i < paramsK(level); i++) {
      pk[i] = NTT.barrettReducePolynomial(pk[i]);
    }

    /// ENCODE KEYS
    List<List<int>> keys = List.filled(2, <int>[]);

    // PUBLIC KEY
    keys[0] = [];
    var bytes = [];
    for (var i = 0; i < paramsK(level); i++) {
      bytes = KyberFunctions.polynomialToBytes(pk[i]);
      for (int j = 0; j < bytes.length; j++) {
        keys[0].add(bytes[j]);
      }
    }
    for (int i = 0; i < publicSeed.length; i++) {
      keys[0].add(publicSeed[i]);
    }

    // PRIVATE KEY
    keys[1] = [];
    bytes = [];
    for (int i = 0; i < paramsK(level); i++) {
      bytes = KyberFunctions.polynomialToBytes(s[i]);
      for (int j = 0; j < bytes.length; j++) {
        keys[1].add(bytes[j]);
      }
    }
    return keys;
  }

  static List<int> encrypt(
    KyberLevel level,
    List<int> pk1,
    List<int> message,
    List<int> coins,
  ) {
    List<List<int>> pk = List.filled(paramsK(level), []);
    int start = 0, end = 0;
    for (int i = 0; i < paramsK(level); i++) {
      start = (i * 384);
      end = (i + 1) * 384;
      pk[i] = KyberFunctions.bytesToPolynomial(pk1.sublist(start, end));
    }
    List<int> seed = pk1.sublist(1536, 1568);
    var at = KyberFunctions.generateMatrixA(level, seed, true);
    List<List<int>> r = List.filled(paramsK(level), []);
    int nonce = 0;
    for (int i = 0; i < paramsK(level); i++) {
      r[i] = KyberFunctions.sample(coins, nonce);
      nonce = nonce + 1;
    }
    List<List<int>> e1 = List.filled(paramsK(level), []);
    for (int i = 0; i < paramsK(level); i++) {
      e1[i] = KyberFunctions.sample(coins, nonce);
      nonce = nonce + 1;
    }
    var e2 = KyberFunctions.sample(coins, nonce);
    for (int i = 0; i < paramsK(level); i++) {
      r[i] = NTT.doTransform(r[i]);
    }
    for (int i = 0; i < paramsK(level); i++) {
      r[i] = NTT.barrettReducePolynomial(r[i]);
    }
    List<List<int>> u = List.filled(paramsK(level), []);
    for (int i = 0; i < paramsK(level); i++) {
      u[i] = NTT.pointwiseMultiply(level, at[i], r);
    }
    for (int i = 0; i < paramsK(level); i++) {
      u[i] = NTT.doInverse(u[i]);
    }
    for (int i = 0; i < paramsK(level); i++) {
      u[i] = NTT.addPolynomials(u[i], e1[i]);
    }
    var m = KyberFunctions.messageToPolynomial(message);
    var v = NTT.pointwiseMultiply(level, pk, r);
    v = NTT.doInverse(v);
    v = NTT.addPolynomials(v, e2);
    v = NTT.addPolynomials(v, m);
    for (int i = 0; i < paramsK(level); i++) {
      u[i] = NTT.barrettReducePolynomial(u[i]);
    }
    v = NTT.barrettReducePolynomial(v);
    var c1 = KyberFunctions.compress1(level, u);
    var c2 = KyberFunctions.compress2(v);
    var returnValue = List<int>.from(c1);
    returnValue.addAll(c2);
    return returnValue;
  }

  static List<int> decrypt(
      KyberLevel level, List<int> c, List<int> privateKey) {
    var u = KyberFunctions.decompress1(level, c.sublist(0, 1408))
        .map((e) => e.noNull())
        .toList();
    var v = KyberFunctions.decompress2(c.sublist(1408, 1568));
    var privateKeyPolyvec =
        KyberFunctions.bytesToVectorOfPolynomials(level, privateKey);
    for (int i = 0; i < paramsK(level); i++) {
      u[i] = NTT.doTransform(u[i]);
    }
    var mp = NTT.pointwiseMultiply(level, privateKeyPolyvec, u);
    mp = NTT.doInverse(mp);
    mp = NTT.subtractPolynomials(v, mp);
    mp = NTT.barrettReducePolynomial(mp);
    return KyberFunctions.polynomialToMessage(mp);
  }
}
