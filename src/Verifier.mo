import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
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

  public func verifyStorageProof(proof : StorageProof) : Bool {
    let _ = do ? {
      let #ok(value) = RLP.encode(#Uint8Array(Buffer.fromArray(proof.value!))) else return false;
      let extracted = extractStorageValue(proof)!;
      return Buffer.toArray(value) == Value.toArray(extracted)
    };
    false
  };

  public func extractStorageValue(proof : StorageProof) : ?Value.Value {
    switch (Proof.verify(proof.storageHash, proof.key, proof.proof)) {
      case (#included(value)) ?value;
      case (#excluded) null;
      case (#invalidProof) null
    }
  };

  public func toStorageProof(
    storageHashText : Text,
    keyText : Text,
    proofTextArr : [Text],
    valueText : ?Text,
  ) : ?StorageProof {
    do ? {
      let storageHash = Hash.fromHex(storageHashText)!;
      let #ok(keyArrText) = Hex.toArray(keyText) else null!;
      let key = Key.fromHex(Hash.toHex(Keccak.keccak(keyArrText)))!;
      let proofBuf = Buffer.Buffer<[Nat8]>(proofTextArr.size());
      for (itemText in proofTextArr.vals()) {
        let #ok(item) = Hex.toArray(itemText) else null!;
        proofBuf.add(item)
      };

      let value = switch (valueText) {
        case (null) null;
        case (?valueText) {
          let #ok(value) = Hex.toArray(valueText) else null!;
          ?value
        }
      };

      return ?{ storageHash; key; proof = Buffer.toArray(proofBuf); value }
    }
  }
}
