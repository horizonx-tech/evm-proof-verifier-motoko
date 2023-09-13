import Result "mo:base/Result";
import Text "mo:base/Text";
import Proof "mo:merkle-patricia-trie/Proof";
import Value "mo:merkle-patricia-trie/Value";

import Types "types";

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
