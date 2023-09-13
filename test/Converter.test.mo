import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import M "mo:matchers/Matchers";
import { run; suite; testLazy } "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Hex "mo:merkle-patricia-trie/util/Hex";
import { keccak } "mo:merkle-patricia-trie/util/Keccak";

import Converter "../src/Converter";
import Types "../src/types";
import Utils "../src/Utils";
import { expected1_receipt; input1_receipt } "TestData";
import { textToKeccakBytes } "TestUtils";

run(
  suite(
    "Converter",
    [
      testLazy(
        "decodeReceipt",
        func() : ?Types.Receipt {
          let bytes = switch (Hex.toArray(input1_receipt.proof[input1_receipt.proof.size() -1][1])) {
            case (#err(error)) {
              Debug.print(debug_show (error));
              return null;
            };
            case (#ok(value)) value;
          };
          let decoded = switch (Converter.decodeReceipt(bytes)) {
            case (#err(error)) {
              Debug.print(debug_show (error));
              return null;
            };
            case (#ok(value)) value;
          };

          M.assertThat(decoded.status, M.equals(T.nat8(Hex.toArrayUnsafe(expected1_receipt.status)[0])));
          M.assertThat(decoded.cumulativeGasUsed, M.equals(T.array<Nat8>(T.nat8Testable, Hex.toArrayUnsafe(expected1_receipt.cumulativeGasUsed))));
          M.assertThat(decoded.logsBloom, M.equals(T.array<Nat8>(T.nat8Testable, Hex.toArrayUnsafe(expected1_receipt.logsBloom))));
          for (i in Iter.range(0, expected1_receipt.logs.size() - 1)) {
            M.assertThat(decoded.logs[i].contractAddress, M.equals(T.array<Nat8>(T.nat8Testable, Hex.toArrayUnsafe(expected1_receipt.logs[i].contractAddress))));
            for (j in Iter.range(0, expected1_receipt.logs[i].topics.size() - 1)) {
              let expected = if (j == 0) {
                textToKeccakBytes(expected1_receipt.logs[i].topics[j]);
              } else Utils.padBytes(Hex.toArrayUnsafe(expected1_receipt.logs[i].topics[j]), 32);
              M.assertThat(decoded.logs[i].topics[j], M.equals(T.array<Nat8>(T.nat8Testable, expected)));
            };
            M.assertThat(decoded.logs[i].data, M.equals(T.array<Nat8>(T.nat8Testable, Hex.toArrayUnsafe(expected1_receipt.logs[i].data))));
          };
          return ?decoded;
        },
        M.anything(),
      )
    ],
  )
);
