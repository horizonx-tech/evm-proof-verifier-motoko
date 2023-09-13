import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import M "mo:matchers/Matchers";
import { run; suite; testLazy } "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Hex "mo:merkle-patricia-trie/util/Hex";
import { keccak } "mo:merkle-patricia-trie/util/Keccak";

import Bloom "../src/Bloom";
import Converter "../src/Converter";
import Utils "../src/Utils";
import { expected1_receipt; input1_receipt } "TestData";
import { textToKeccakBytes } "TestUtils";

run(
  suite(
    "Bloom",
    [
      testLazy(
        "create",
        func() : [Nat8] {
          let bytes = switch (Hex.toArray(input1_receipt.proof[input1_receipt.proof.size() -1][1])) {
            case (#err(error)) {
              Debug.print(debug_show (error));
              return [];
            };
            case (#ok(value)) value;
          };
          let decoded = switch (Converter.decodeReceipt(bytes)) {
            case (#err(error)) {
              Debug.print(debug_show (error));
              return [];
            };
            case (#ok(value)) value;
          };
          Bloom.create(decoded.logs);
        },
        M.equals(T.array(T.nat8Testable, Hex.toArrayUnsafe(expected1_receipt.logsBloom))),
      ),
      testLazy(
        "test",
        func() : Bool {
          let bloom = Hex.toArrayUnsafe(expected1_receipt.logsBloom);

          M.assertThat(Bloom.test(bloom, textToKeccakBytes(expected1_receipt.logs[0].topics[0])), M.equals(T.bool(true)));
          M.assertThat(Bloom.test(bloom, Utils.padBytes(Hex.toArrayUnsafe(expected1_receipt.logs[0].topics[1]), 32)), M.equals(T.bool(true)));

          M.assertThat(Bloom.test(bloom, Hex.toArrayUnsafe(expected1_receipt.logs[0].topics[1])), M.equals(T.bool(false)));

          true;
        },
        M.anything(),
      ),
    ],
  )
);
