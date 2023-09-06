import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Hash "mo:merkle-patricia-trie/Hash";
import Key "mo:merkle-patricia-trie/Key";
import Proof "mo:merkle-patricia-trie/Proof";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Keccak "mo:merkle-patricia-trie/util/Keccak";
import RLP "mo:merkle-patricia-trie/util/rlp/encode";
import Value "mo:merkle-patricia-trie/Value";
import RLPTypes "mo:rlp/types";

import Util "Util";

module {
  type ProofType = {
    #account;
    #storage;
  };

  type MerkleProof = {
    rootHash : Hash.Hash;
    key : Key.Key;
    proof : Proof.Proof;
    value : ?[Nat8];
  };

  public func verifyMerkleProof(proof : MerkleProof) : Result.Result<Bool, Text> {
    let value = switch (proof.value) {
      case (null) return #err("Proof.value required.");
      case (?value) value;
    };
    let extracted = switch (extractValue(proof)) {
      case (#err(error)) return #err(error);
      case (#ok(value)) value;
    };
    return #ok(value == Value.toArray(extracted));
  };

  public func extractValue(proof : MerkleProof) : Result.Result<Value.Value, Text> {
    switch (Proof.verify(proof.rootHash, proof.key, proof.proof)) {
      case (#excluded) #err("excluded");
      case (#invalidProof) #err("invalidProof");
      case (#included(value)) #ok(value);
    };
  };

  public func toMerkleProof(
    proofType : ProofType,
    rootHashText : Text,
    keyText : Text,
    proofTextArr : [Text],
    valueInput : ?RLPTypes.Input,
  ) : Result.Result<MerkleProof, Text> {
    let rootHash = switch (Hash.fromHex(rootHashText)) {
      case null return #err("Failed to parse to Hash: " # rootHashText);
      case (?hex) hex;
    };

    let keyBytes = switch (Hex.toArray(keyText)) {
      case (#err(error)) return #err("Failed to parse to Bytes: " # keyText # ", err: " # error);
      case (#ok(keyBytes)) if (proofType == #storage) Util.padBytes(keyBytes, 32) else keyBytes;
    };
    let keyArrHex = Hash.toHex(Keccak.keccak(keyBytes));
    let key = switch (Key.fromHex(keyArrHex)) {
      case null return #err("Failed to parse to Key: " # keyText);
      case (?key) key;
    };
    let proofBuf = Buffer.Buffer<[Nat8]>(proofTextArr.size());
    for (itemText in proofTextArr.vals()) {
      let item = switch (Hex.toArray(itemText)) {
        case (#err(error)) return #err("Failed to parse to Bytes: " # itemText # ", err: " # error);
        case (#ok(item)) item;
      };
      proofBuf.add(item);
    };

    let value = switch (valueInput) {
      case (null) null;
      case (?valueInput) {
        let value = switch (RLP.encode(valueInput)) {
          case (#err(error)) return #err(error);
          case (#ok(value)) ?Buffer.toArray(value);
        };
      };
    };
    return #ok({ rootHash; key; proof = Buffer.toArray(proofBuf); value });
  };

};
