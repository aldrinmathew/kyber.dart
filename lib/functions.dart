part of kyber;

int montgomeryReduce(int value) {
  int u = int16(int32(value) * paramsQInverse);
  int t = u * paramsQ;
  // print('Value ' +
  //     value.toString() +
  //     '   U ' +
  //     u.toString() +
  //     '   T ' +
  //     t.toString());
  t = value - t;
  t >>= 16;
  // if (t != int16(t)) {
  //   print('T Decay for Value $value, u $u, t $t');
  // }
  // print(int16(t));
  return int16(t);
}

List<int> polynomialToMontgomeryDomain(List<int> list) {
  int f = 1353;
  for (int i = 0; i < paramsN; i++) {
    list[i] = montgomeryReduce(int32(list[i]) * int32(f));
  }
  return list;
}

int byte(int value) {
  value = value % 256;
  return value;
}

int int16(int value) {
  int end = -32768;
  int start = 32767;
  if (value >= end && value <= start) {
    return value;
  } else if (value < end) {
    value = value + 32769;
    value = value % 65536;
    value = start + value;
    return value;
  } else if (value > start) {
    value = value - 32768;
    value = value % 65536;
    value = end + value;
    return value;
  } else {
    return value;
  }
}

int uint16(int value) {
  value = value % 65536;
  return value;
}

int int32(int value) {
  int end = -2147483648;
  int start = 2147483647;

  if (value >= end && value <= start) {
    return value;
  } else if (value < end) {
    value = value + 2147483649;
    value = value % 4294967296;
    value = start + value;
    return value;
  } else if (value > start) {
    value = value - 2147483648;
    value = value % 4294967296;
    value = end + value;
    return value;
  } else {
    return value;
  }
}

int uint32(int value) {
  value = value % 4294967296;
  return value;
}

bool compareArray(a, b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

List<int> compress1(KyberLevel level, List<List<int>> u) {
  int rr = 0;
  List<int> r = List.filled(1408, 0); // 4 * 352
  List<int> t = List.filled(8, 0);
  for (int i = 0; i < paramsK(level); i++) {
    for (int j = 0; j < paramsN / 8; j++) {
      for (int k = 0; k < 8; k++) {
        t[k] = uint16(
            (((uint32(u[i][8 * j + k]) << 11 >>> 0) + uint32(paramsQ ~/ 2)) ~/
                    uint32(paramsQ)) &
                0x7ff >>> 0);
      }
      r[rr + 0] = byte((t[0] >> 0));
      r[rr + 1] = byte((t[0] >> 8) | (t[1] << 3));
      r[rr + 2] = byte((t[1] >> 5) | (t[2] << 6));
      r[rr + 3] = byte((t[2] >> 2));
      r[rr + 4] = byte((t[2] >> 10) | (t[3] << 1));
      r[rr + 5] = byte((t[3] >> 7) | (t[4] << 4));
      r[rr + 6] = byte((t[4] >> 4) | (t[5] << 7));
      r[rr + 7] = byte((t[5] >> 1));
      r[rr + 8] = byte((t[5] >> 9) | (t[6] << 2));
      r[rr + 9] = byte((t[6] >> 6) | (t[7] << 5));
      r[rr + 10] = byte((t[7] >> 3));
      rr = rr + 11;
    }
  }
  return r;
}

List<int> compress2(List<int> v) {
  int rr = 0;
  List<int> r = List.filled(160, 0);
  List<int> t = List.filled(8, 0);
  for (int i = 0; i < paramsN / 8; i++) {
    for (int j = 0; j < 8; j++) {
      t[j] = byte(((uint32(v[8 * i + j]) << 5 >>> 0) + uint32(paramsQ ~/ 2)) ~/
              uint32(paramsQ)) &
          31;
    }
    r[rr + 0] = byte((t[0] >> 0) | (t[1] << 5));
    r[rr + 1] = byte((t[1] >> 3) | (t[2] << 2) | (t[3] << 7));
    r[rr + 2] = byte((t[3] >> 1) | (t[4] << 4));
    r[rr + 3] = byte((t[4] >> 4) | (t[5] << 1) | (t[6] << 6));
    r[rr + 4] = byte((t[6] >> 2) | (t[7] << 3));
    rr = rr + 5;
  }
  return r;
}

List<List<int>> decompress1(KyberLevel level, List<int> a) {
  List<List<int>> r = List.filled(paramsK(level), []);
  for (int i = 0; i < paramsK(level); i++) {
    r[i] = List.filled(384, 0);
  }
  int aa = 0;
  List<int> t = List.filled(8, 0);
  for (int i = 0; i < paramsK(level); i++) {
    for (int j = 0; j < paramsN / 8; j++) {
      t[0] = (uint16(a[aa + 0]) >> 0) | (uint16(a[aa + 1]) << 8);
      t[1] = (uint16(a[aa + 1]) >> 3) | (uint16(a[aa + 2]) << 5);
      t[2] = (uint16(a[aa + 2]) >> 6) |
          (uint16(a[aa + 3]) << 2) |
          (uint16(a[aa + 4]) << 10);
      t[3] = (uint16(a[aa + 4]) >> 1) | (uint16(a[aa + 5]) << 7);
      t[4] = (uint16(a[aa + 5]) >> 4) | (uint16(a[aa + 6]) << 4);
      t[5] = (uint16(a[aa + 6]) >> 7) |
          (uint16(a[aa + 7]) << 1) |
          (uint16(a[aa + 8]) << 9);
      t[6] = (uint16(a[aa + 8]) >> 2) | (uint16(a[aa + 9]) << 6);
      t[7] = (uint16(a[aa + 9]) >> 5) | (uint16(a[aa + 10]) << 3);
      aa = aa + 11;
      for (int k = 0; k < 8; k++) {
        r[i][8 * j + k] = (uint32(t[k] & 0x7FF) * paramsQ + 1024) >> 11;
      }
    }
  }
  return r;
}

List<int> subtractQ(List<int> r) {
  for (int i = 0; i < paramsN; i++) {
    r[i] = r[i] - paramsQ; // should result in a negative integer
    // push left most signed bit to right most position
    // Dart does bitwise operations in signed 64 bit
    // add q back again if left most bit was 0 (positive number)
    r[i] = r[i] + ((r[i] >> 63) & paramsQ);
  }
  return r;
}

List<int> decompress2(List<int> a) {
  List<int> r = List.filled(384, 0);
  List<int> t = List.filled(8, 0);
  int aa = 0;
  for (int i = 0; i < paramsN / 8; i++) {
    t[0] = (a[aa + 0] >> 0);
    t[1] = (a[aa + 0] >> 5) | (a[aa + 1] << 3);
    t[2] = (a[aa + 1] >> 2);
    t[3] = (a[aa + 1] >> 7) | (a[aa + 2] << 1);
    t[4] = (a[aa + 2] >> 4) | (a[aa + 3] << 4);
    t[5] = (a[aa + 3] >> 1);
    t[6] = (a[aa + 3] >> 6) | (a[aa + 4] << 2);
    t[7] = (a[aa + 4] >> 3);
    aa = aa + 5;
    for (int j = 0; j < 8; j++) {
      r[8 * i + j] =
          int16(((uint32(t[j] & 31 >>> 0) * uint32(paramsQ)) + 16) >> 5);
    }
  }
  return r;
}

int load32(List<int> x) {
  int r = uint32(x[0]);
  r = (((r | (uint32(x[1]) << 8)) >>> 0) >>> 0);
  r = (((r | (uint32(x[2]) << 16)) >>> 0) >>> 0);
  r = (((r | (uint32(x[3]) << 24)) >>> 0) >>> 0);
  return uint32(r);
}

List<int> distributedCoefficientsCBD(Uint8List buffer) {
  int t, d;
  int a, b;
  List<int> r = List.filled(384, 0);
  for (int i = 0; i < paramsN / 8; i++) {
    t = (load32(buffer.sublist(4 * i, buffer.length)) >>> 0);
    d = ((t & 0x55555555) >>> 0);
    d = (d + ((((t >> 1) >>> 0) & 0x55555555) >>> 0) >>> 0);
    for (int j = 0; j < 8; j++) {
      a = int16((((d >> (4 * j + 0)) >>> 0) & 0x3) >>> 0);
      b = int16((((d >> (4 * j + paramsETA)) >>> 0) & 0x3) >>> 0);
      r[8 * i + j] = a - b;
    }
  }
  return r;
}

Uint8List pseudoRandomFunction(
  int outputLengthInBytes,
  List<int> key,
  int nonce,
) {
  List<int> nonceList = List.filled(1, 0);
  nonceList[0] = nonce;
  var hash = sha3.SHA3(256, sha3.SHAKE_PADDING, outputLengthInBytes * 8);
  hash.reset = true;
  var buffer1 = Uint8List.fromList(key);
  var buffer2 = Uint8List.fromList(nonceList);
  hash = hash.update(buffer1).update(buffer2);
  return Uint8List.fromList(hash.digest()); // 128 long byte array
}

List<int> sample(List<int> seed, int nonce) {
  int l = paramsETA * paramsN ~/ 4;
  Uint8List p = pseudoRandomFunction(l, seed, nonce);
  return distributedCoefficientsCBD(p);
}

List<List<List<int>>> generateMatrixA(
    KyberLevel level, dynamic seed, bool transposed) {
  List<List<List<int>>> a = List.filled(paramsK(level), []);
  // List<int> output = List.filled(3 * 168, 0);

  /// TODO: Check output bits
  var xof = sha3.SHA3(128, sha3.SHAKE_PADDING, 672 * 8);
  int ctr = 0;
  for (int i = 0; i < paramsK(level); i++) {
    a[i] = List.filled(paramsK(level), []);
    List<int> transpose = List.filled(2, 0);

    for (int j = 0; j < paramsK(level); j++) {
      // set if transposed matrix or not
      transpose[0] = j;
      transpose[1] = i;
      if (transposed) {
        transpose[0] = i;
        transpose[1] = j;
      }

      // obtain xof of (seed+i+j) or (seed+j+i) depending on above code
      // output is 672 bytes in length
      // xof.reset = true;
      Uint8List? buffer1;
      Uint8List buffer2 = Uint8List.fromList(transpose);
      if (seed is String) {
        buffer1 = Uint8List.fromList(seed.codeUnits);
      } else if (seed is List<int>) {
        buffer1 = Uint8List.fromList(seed);
      } else if (seed is ByteBuffer) {
        buffer1 = Uint8List.view(seed);
      }
      if (buffer1 == null) {
        throw Exception("Invalid seed datatype");
      }
      xof.finalized = false;
      xof.update(buffer1).update(buffer2);
      List<int> output = xof.digest();

      // run rejection sampling on the output from above
      int outputlen = 3 * 168; // 504
      var result = INDCPA.rejectionSamplingOnUniformRandomBytes(
          output.sublist(0, 504), outputlen, paramsN);
      a[i][j] = result.nttRepresentation;
      ctr = result
          .position; // keeps track of index of output array from sampling function

      while (ctr < paramsN) {
        // if the polynomial hasnt been filled yet with mod q entries

        List<int> outputn = output.sublist(
            504, 672); // take last 168 bytes of byte array from xof

        // run sampling function again
        var result1 = INDCPA.rejectionSamplingOnUniformRandomBytes(
            outputn, 168, paramsN - ctr);
        List<int> missing = result1
            .nttRepresentation; // here is additional mod q polynomial coefficients
        // how many coefficients were accepted and are in the output
        int ctrn = result1.position;
        // starting at last position of output array from first sampling function until 256 is reached
        for (int k = ctr; k < paramsN; k++) {
          // fill rest of array with the additional coefficients until full
          a[i][j][k] = missing[k - ctr];
        }
        ctr = ctr + ctrn; // update index
      }
    }
  }
  return a;
}

List<int> messageToPolynomial(List<int> msg) {
  var r = List.filled(384, 0); // each element is int16 (0-65535)
  int mask = 0; // int16
  for (int i = 0; i < paramsN / 8; i++) {
    for (int j = 0; j < 8; j++) {
      mask = -1 * int16((msg[i] >> j) & 1);
      r[8 * i + j] = mask & int16((paramsQ + 1) ~/ 2);
    }
  }
  return r;
}

/// This is the inverse of [messageToPolynomial]
List<int> polynomialToMessage(List<int> a) {
  var msg = List.filled(32, 0);
  int t = 0;
  List<int> a2 = subtractQ(a);
  for (int i = 0; i < paramsN / 8; i++) {
    msg[i] = 0;
    for (int j = 0; j < 8; j++) {
      t = (((uint16(a2[8 * i + j]) << 1) + uint16(paramsQ ~/ 2)) ~/
              uint16(paramsQ)) &
          1;
      msg[i] |= byte(t << j);
    }
  }
  return msg;
}

List<int> bytesToPolynomial(List<int> bytes) {
  List<int> r = List.filled(384, 0);
  for (int i = 0; i < paramsN / 2; i++) {
    r[2 * i] = int16(
        ((uint16(bytes[3 * i + 0]) >> 0) | (uint16(bytes[3 * i + 1]) << 8)) &
            0xFFF);
    r[2 * i + 1] = int16(
        ((uint16(bytes[3 * i + 1]) >> 4) | (uint16(bytes[3 * i + 2]) << 4)) &
            0xFFF);
  }
  return r;
}

List<int> polynomialToBytes(List<int> poly) {
  int t0 = 0, t1 = 0;
  List<int> r = List.filled(384, 0);
  List<int> a2 = subtractQ(poly);
  // Returns: a - q if a >= q, else a (each coefficient of the polynomial) for 0-127
  for (int i = 0; i < paramsN / 2; i++) {
    // get two coefficient entries in the polynomial
    t0 = uint16(a2[2 * i]);
    t1 = uint16(a2[2 * i + 1]);

    // convert the 2 coefficient into 3 bytes
    r[3 * i + 0] =
        byte(t0 >> 0); // byte() does mod 256 of the input (output value 0-255)
    r[3 * i + 1] = byte(t0 >> 8) | byte(t1 << 4);
    r[3 * i + 2] = byte(t1 >> 4);
  }
  return r;
}

List<List<int>> bytesToVectorOfPolynomials(KyberLevel level, List<int> a) {
  List<List<int>> r = List.filled(paramsK(level), []);
  for (int i = 0; i < paramsK(level); i++) {
    r[i] = List.filled(384, 0);
  }
  int start = 0, end = 0;
  for (int i = 0; i < paramsK(level); i++) {
    start = (i * 384);
    end = (i + 1) * 384;
    r[i] = bytesToPolynomial(a.sublist(start, end));
  }
  return r;
}

int nextInt(int value) {
  return Random.secure().nextInt(1 << 24) * value;
}

int hexToDecimal(String value) {
  return int.parse(value, radix: 16);
}
