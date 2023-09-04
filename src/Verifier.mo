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
      let #ok(encoded) = RLP.encode(#Uint8Array(Buffer.fromArray(proof.value!))) else return false;
      let _result = extractStorageValue(proof)!;
      return Buffer.toArray(encoded) == Value.toArray(_result)
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
    _storageHash : Text,
    _key : Text,
    _proof : [Text],
    _value : ?Text,
  ) : ?StorageProof {
    let _ = do ? {
      let storageHash = Hash.fromHex(_storageHash)!;
      let #ok(_keyArr) = Hex.toArray(_key) else return null;
      let key = Key.fromHex(Hash.toHex(Keccak.keccak(_keyArr)))!;
      let _proofBuf = Buffer.Buffer<[Nat8]>(_proof.size());
      for (itemText in _proof.vals()) {
        let #ok(item) = Hex.toArray(itemText) else return null;
        _proofBuf.add(item)
      };

      let value = switch (_value) {
        case (null) null;
        case (?_value) {
          let #ok(value) = Hex.toArray(_value) else return null;
          ?value
        }
      };

      return ?{ storageHash; key; proof = Buffer.toArray(_proofBuf); value }
    };

    null
  }
}
