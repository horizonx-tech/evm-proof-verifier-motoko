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

import Verifier "../src/Verifier";
import { data1 } "TestData";

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
          let storageProof = switch (Verifier.toMerkleProof(#storage, data1.storageHash, data1.storageProof[0].key, data1.storageProof[0].proof, null)) {
            case (#err(error)) return error;
            case (#ok(storageProof)) storageProof;
          };
          let value = switch (Verifier.extractValue(storageProof)) {
            case (#err(error)) return error;
            case (#ok(value)) value;
          };
          Value.toHex(value);
        },
        M.equals(T.text(encodeRLPHex(#string("0x" # data1.storageProof[0].value)))),
      ),
      testLazy(
        "verifyProof: true",
        func() : Bool {
          let storageProof = switch (Verifier.toMerkleProof(#storage, data1.storageHash, data1.storageProof[0].key, data1.storageProof[0].proof, ? #string("0x" # data1.storageProof[0].value))) {
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
        "verify Account Proof",
        func() : Bool {
          let value = #List(Buffer.fromArray<RLPTypes.Input>([#string("0x" # data1.nonce), #string("0x" # data1.balance), #string("0x" # data1.storageHash), #string("0x" # data1.codeHash)]));
          let storageProof = switch (Verifier.toMerkleProof(#account, data1.blockHeader.stateRoot, data1.address, data1.accountProof, ?value)) {
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
    ],
  )
);
