part of kyber;

int paramsK(KyberLevel type) {
  switch (type) {
    case KyberLevel.k512:
      {
        return 2;
      }
    case KyberLevel.k768:
      {
        return 3;
      }
    case KyberLevel.k1024:
      {
        return 4;
      }
  }
}

const int paramsN = 256;
const int paramsQ = 3329;
const int paramsQInverse = 62209;
const int paramsETA = 2;
