import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Result "mo:base/Result";
import M "mo:matchers/Matchers";
import { run; suite; testLazy } "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Hash "mo:merkle-patricia-trie/Hash";
import TrieInternal "mo:merkle-patricia-trie/internal/TrieInternal";
import Key "mo:merkle-patricia-trie/Key";
import Trie "mo:merkle-patricia-trie/Trie";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Keccak "mo:merkle-patricia-trie/util/Keccak";
import Value "mo:merkle-patricia-trie/Value";
import RLP "mo:rlp";
import RLPTypes "mo:rlp/types";

import Utils "../src/Utils";
import Verifier "../src/Verifier";
import { input1_account; input1_receipt; input1_storage; input1_tx } "TestData";

func encodeRLPHex(input : RLPTypes.Input) : Text {
  let encoded = switch (RLP.encode(input)) {
    case (#err(error)) Debug.trap("RLPEncode failed: " # error);
    case (#ok(value)) value;
  };
  Hex.toText(Buffer.toArray(encoded));
};

run(
  suite(
    "Verifier",
    [
      testLazy(
        "extractValue",
        func() : Text {
          let storageProof = switch (Utils.toStorageProof(input1_storage, 0)) {
            case (#err(error)) return error;
            case (#ok(storageProof)) storageProof;
          };
          let value = switch (Verifier.extractValue(storageProof)) {
            case (#err(error)) return error;
            case (#ok(value)) value;
          };
          Value.toHex(value);
        },
        M.equals(T.text(encodeRLPHex(#string("0x" # input1_storage.storageProof[0].value)))),
      ),
      testLazy(
        "verifyMerkleProof: storage",
        func() : Bool {
          let storageProof = switch (Utils.toStorageProof(input1_storage, 0)) {
            case (#err(error)) { Debug.print(error); return false };
            case (#ok(storageProof)) storageProof;
          };
          switch (Verifier.verifyMerkleProof(storageProof)) {
            case (#err(error)) { Debug.print(error); false };
            case (#ok(value)) value;
          };
        },
        M.equals(T.bool(true)),
      ),
      testLazy(
        "verifyMerkleProof: account",
        func() : Bool {
          let accountProof = switch (Utils.toAccountProof(input1_account)) {
            case (#err(error)) { Debug.print(error); return false };
            case (#ok(accountProof)) accountProof;
          };
          switch (Verifier.verifyMerkleProof(accountProof)) {
            case (#err(error)) { Debug.print(error); false };
            case (#ok(value)) value;
          };
        },
        M.equals(T.bool(true)),
      ),
      testLazy(
        "verifyMerkleProof: transaction",
        func() : Bool {
          let txProof = switch (Utils.toTxProof(input1_tx)) {
            case (#err(error)) { Debug.print(error); return false };
            case (#ok(txProof)) txProof;
          };
          switch (Verifier.verifyMerkleProof(txProof)) {
            case (#err(error)) { Debug.print(error); false };
            case (#ok(value)) value;
          };
        },
        M.equals(T.bool(true)),
      ),
      testLazy(
        "verifyMerkleProof: receipt",
        func() : Bool {
          let txProof = switch (Utils.toTxProof(input1_receipt)) {
            case (#err(error)) { Debug.print(error); return false };
            case (#ok(txProof)) txProof;
          };
          switch (Verifier.verifyMerkleProof(txProof)) {
            case (#err(error)) { Debug.print(error); false };
            case (#ok(value)) value;
          };
        },
        M.equals(T.bool(true)),
      ),
    ],
  )
);
