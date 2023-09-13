import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import M "mo:matchers/Matchers";
import { run; suite; test } "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Utils "../src/Utils";

run(
  suite(
    "Utils",
    [
      test(
        "filledBuffer",
        Buffer.toArray(Utils.filledBuffer<Nat>(8, 0)),
        M.equals(T.array(T.natTestable, [0, 0, 0, 0, 0, 0, 0, 0])),
      ),
      test(
        "padBytes",
        Utils.padBytes([1, 2, 3, 4], 8),
        M.equals(T.array(T.nat8Testable, [0, 0, 0, 0, 1, 2, 3, 4] : [Nat8])),
      ),
      test(
        "toNat16: min",
        Utils.toNat16([0]),
        M.equals(T.nat16(0)),
      ),
      test(
        "toNat16: max",
        Utils.toNat16([0xff, 0xff, 0x1]),
        M.equals(T.nat16(0xffff)),
      ),
    ],
  )
);
