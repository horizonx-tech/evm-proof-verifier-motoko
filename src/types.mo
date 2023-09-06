import Hash "mo:merkle-patricia-trie/Hash";
import Key "mo:merkle-patricia-trie/Key";
import Proof "mo:merkle-patricia-trie/Proof";

module {
    public type ProofType = {
        #account;
        #storage;
    };

    public type MerkleProof = {
        rootHash : Hash.Hash;
        key : Key.Key;
        proof : Proof.Proof;
        value : ?[Nat8];
    };
};
