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

import Types "types";
import Util "utils";

module {
  public func verifyMerkleProof(proof : Types.MerkleProof) : Result.Result<Bool, Text> {
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

  public func extractValue(proof : Types.MerkleProof) : Result.Result<Value.Value, Text> {
    switch (Proof.verify(proof.rootHash, proof.key, proof.proof)) {
      case (#excluded) #err("excluded");
      case (#invalidProof) #err("invalidProof");
      case (#included(value)) #ok(value);
    };
  };
};
