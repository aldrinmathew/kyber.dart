part of kyber;

class NTT {
  static const List<int> zetas = [
    2285,
    2571,
    2970,
    1812,
    1493,
    1422,
    287,
    202,
    3158,
    622,
    1577,
    182,
    962,
    2127,
    1855,
    1468,
    573,
    2004,
    264,
    383,
    2500,
    1458,
    1727,
    3199,
    2648,
    1017,
    732,
    608,
    1787,
    411,
    3124,
    1758,
    1223,
    652,
    2777,
    1015,
    2036,
    1491,
    3047,
    1785,
    516,
    3321,
    3009,
    2663,
    1711,
    2167,
    126,
    1469,
    2476,
    3239,
    3058,
    830,
    107,
    1908,
    3082,
    2378,
    2931,
    961,
    1821,
    2604,
    448,
    2264,
    677,
    2054,
    2226,
    430,
    555,
    843,
    2078,
    871,
    1550,
    105,
    422,
    587,
    177,
    3094,
    3038,
    2869,
    1574,
    1653,
    3083,
    778,
    1159,
    3182,
    2552,
    1483,
    2727,
    1119,
    1739,
    644,
    2457,
    349,
    418,
    329,
    3173,
    3254,
    817,
    1097,
    603,
    610,
    1322,
    2044,
    1864,
    384,
    2114,
    3193,
    1218,
    1994,
    2455,
    220,
    2142,
    1670,
    2144,
    1799,
    2051,
    794,
    1819,
    2475,
    2459,
    478,
    3221,
    3021,
    996,
    991,
    958,
    1869,
    1522,
    1628
  ];

  static const List<int> zetasInverse = [
    1701,
    1807,
    1460,
    2371,
    2338,
    2333,
    308,
    108,
    2851,
    870,
    854,
    1510,
    2535,
    1278,
    1530,
    1185,
    1659,
    1187,
    3109,
    874,
    1335,
    2111,
    136,
    1215,
    2945,
    1465,
    1285,
    2007,
    2719,
    2726,
    2232,
    2512,
    75,
    156,
    3000,
    2911,
    2980,
    872,
    2685,
    1590,
    2210,
    602,
    1846,
    777,
    147,
    2170,
    2551,
    246,
    1676,
    1755,
    460,
    291,
    235,
    3152,
    2742,
    2907,
    3224,
    1779,
    2458,
    1251,
    2486,
    2774,
    2899,
    1103,
    1275,
    2652,
    1065,
    2881,
    725,
    1508,
    2368,
    398,
    951,
    247,
    1421,
    3222,
    2499,
    271,
    90,
    853,
    1860,
    3203,
    1162,
    1618,
    666,
    320,
    8,
    2813,
    1544,
    282,
    1838,
    1293,
    2314,
    552,
    2677,
    2106,
    1571,
    205,
    2918,
    1542,
    2721,
    2597,
    2312,
    681,
    130,
    1602,
    1871,
    829,
    2946,
    3065,
    1325,
    2756,
    1861,
    1474,
    1202,
    2367,
    3147,
    1752,
    2707,
    171,
    3127,
    3042,
    1907,
    1836,
    1517,
    359,
    758,
    1441
  ];

  /// Performs multiplication of polynomials in `Zq[X] / (X^2-zeta)`.
  ///
  /// Used for multiplication of elements in `Rq` in the Number Theoretic
  ///  Transformation domain.
  static List<int> baseMultiply(int a0, int a1, int b0, int b1, int zeta) {
    List<int> result = [0, 0];
    result[0] = KyberFunctions.montgomeryReduce(a1 * b1);
    result[0] = KyberFunctions.montgomeryReduce(result[0] * zeta);
    result[0] = result[0] + KyberFunctions.montgomeryReduce(a0 * b0);
    result[1] = KyberFunctions.montgomeryReduce(a0 * b1);
    result[1] = result[1] + KyberFunctions.montgomeryReduce(a1 * b0);
    return result;
  }

  static List<int> polynomialBaseMultiplyMontgomery(List<int> a, List<int> b) {
    List<int> rx = [], ry = [];
    for (int i = 0; i < (paramsN / 4); i++) {
      rx = baseMultiply(
        a[4 * i + 0],
        a[4 * i + 1],
        b[4 * i + 0],
        b[4 * i + 1],
        zetas[64 + i],
      );
      ry = baseMultiply(
        a[4 * i + 2],
        a[4 * i + 3],
        b[4 * i + 2],
        b[4 * i + 3],
        -zetas[64 + i],
      );
      a[4 * i + 0] = rx[0];
      a[4 * i + 1] = rx[1];
      a[4 * i + 2] = ry[0];
      a[4 * i + 3] = ry[1];
    }
    return a;
  }

  static List<int> addPolynomials(List<int> a, List<int> b) {
    List<int> result = List.filled(384, 0);
    for (int i = 0; i < paramsN; i++) {
      result[i] = a[i] + b[i];
    }
    return result;
  }

  static List<int> subtractPolynomials(List<int> a, List<int> b) {
    List<int> result = List.filled(384, 0);
    for (int i = 0; i < paramsN; i++) {
      result[i] = a[i] - b[i];
    }
    return result;
  }

  static int computeBarret(int value) {
    num newVal = (((1 << 24) + paramsQ / 2) / paramsQ);
    int t = (newVal * value).truncate() >> 24;
    t = t * paramsQ;
    return value - t;
  }

  static List<int> barrettReducePolynomial(List<int> p) {
    List<int> list = List.from(p);
    for (int i = 0; i < paramsN; i++) {
      list[i] = computeBarret(list[i]);
    }
    return list;
  }

  static List<int> pointwiseMultiply(
      KyberLevel level, List<List<int>> a, List<List<int>> b) {
    List<int> result = polynomialBaseMultiplyMontgomery(a[0], b[0]);
    List<int> t = [];
    for (int i = 0; i < paramsK(level); i++) {
      t = polynomialBaseMultiplyMontgomery(a[i], b[i]);
      result = addPolynomials(result, t);
    }
    return barrettReducePolynomial(result);
  }

  /// Performs an in-place Number Theoretic Transform in `Rq`. The
  ///  input is in standard order, the output in bit-reversed order
  static List<int> doTransform(List<int> values) {
    List<int> list = List.from(values);
    int j = 0, k = 1, zeta = 0, t = 0;
    for (int l = 128; l >= 2; l >>= 1) {
      for (int start = 0; start < 256; start = j + l) {
        zeta = zetas[k];
        k++;
        for (j = start; j < start + l; j++) {
          t = KyberFunctions.montgomeryReduce(zeta * list[j + l]);
          list[j + l] = list[j] - t;
          list[j] = list[j] + t;
        }
      }
    }
    return list;
  }

  /// Performs an in-place Inverse Number Theoretic Transform in `Rq`
  ///  and multiplication by Montgomery factor 2^16. The input is in
  ///  the bit-reversed order, the output is in the standard order
  static List<int> doInverse(List<int> values) {
    List<int> list = List.from(values);
    int j = 0, k = 0, zeta = 0, t = 0;
    for (int l = 2; l <= 128; l <<= 1) {
      for (int start = 0; start < 256; start = j + l) {
        zeta = zetasInverse[k];
        k++;
        for (j = start; j < start + l; j++) {
          t = list[j];
          list[j] = computeBarret(t + list[j + l]);
          list[j + l] = t - list[j + l];
          list[j + l] = KyberFunctions.montgomeryReduce(zeta * list[j + l]);
        }
      }
    }
    for (j = 0; j < 256; j++) {
      list[j] = KyberFunctions.montgomeryReduce(list[j] * zetasInverse[127]);
    }
    return list;
  }
}
