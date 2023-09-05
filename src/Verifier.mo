import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Hash "mo:merkle-patricia-trie/Hash";
import TrieInternal "mo:merkle-patricia-trie/internal/TrieInternal";
import Key "mo:merkle-patricia-trie/Key";
import Proof "mo:merkle-patricia-trie/Proof";
import Util "mo:merkle-patricia-trie/util";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Keccak "mo:merkle-patricia-trie/util/Keccak";
import RLP "mo:merkle-patricia-trie/util/rlp/encode";
import Value "mo:merkle-patricia-trie/Value";

module {

  type StorageProof = {
    storageHash : Hash.Hash;
    key : Key.Key;
    proof : Proof.Proof;
    value : ?[Nat8]
  };

  public func verifyStorageProof(proof : StorageProof) : Result.Result<Bool, Text> {
    let valueBytes = switch (proof.value) {
      case (null) return #err("Proof.value required.");
      case (?value) value
    };
    let value = switch (RLP.encode(#Uint8Array(Buffer.fromArray(valueBytes)))) {
      case (#err(error)) return #err(error);
      case (#ok(value)) value
    };
    let extracted = switch (extractStorageValue(proof)) {
      case (#err(error)) return #err(error);
      case (#ok(value)) value
    };
    return #ok(Buffer.toArray(value) == Value.toArray(extracted))
  };

  public func extractStorageValue(proof : StorageProof) : Result.Result<Value.Value, Text> {
    switch (Proof.verify(proof.storageHash, proof.key, proof.proof)) {
      case (#excluded) #err("excluded");
      case (#invalidProof) #err("invalidProof");
      case (#included(value)) #ok(value)
    }
  };

  public func toStorageProof(
    storageHashText : Text,
    keyText : Text,
    proofTextArr : [Text],
    valueText : ?Text,
  ) : Result.Result<StorageProof, Text> {
    let storageHash = switch (Hash.fromHex(storageHashText)) {
      case null return #err("Failed to parse to Hash: " # storageHashText);
      case (?hex) hex
    };

    let keyBytes = switch (Hex.toArray(keyText)) {
      case (#err(error)) return #err("Failed to parse to Bytes: " # keyText # ", err: " # error);
      case (#ok(keyBytes)) keyBytes
    };
    let keyArrHex = Hash.toHex(Keccak.keccak(keyBytes));
    let key = switch (Key.fromHex(keyArrHex)) {
      case null return #err("Failed to parse to Key: " # keyText);
      case (?key) key
    };
    let proofBuf = Buffer.Buffer<[Nat8]>(proofTextArr.size());
    for (itemText in proofTextArr.vals()) {
      let item = switch (Hex.toArray(itemText)) {
        case (#err(error)) return #err("Failed to parse to Bytes: " # itemText # ", err: " # error);
        case (#ok(item)) item
      };
      proofBuf.add(item)
    };

    let value = switch (valueText) {
      case (null) null;
      case (?valueText) {
        switch (Hex.toArray(valueText)) {
          case (#err(error)) return #err("Failed to parse to Bytes: " # valueText # ", err: " # error);
          case (#ok(value)) ?value
        }
      }
    };

    return #ok({ storageHash; key; proof = Buffer.toArray(proofBuf); value })
  }
}
