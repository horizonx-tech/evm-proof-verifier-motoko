import Hash "mo:merkle-patricia-trie/Hash";
import Key "mo:merkle-patricia-trie/Key";
import Proof "mo:merkle-patricia-trie/Proof";

module {
  public type ProofType = {
    #account;
    #storage;
    #transaction;
  };

  public type MerkleProof = {
    rootHash : Hash.Hash;
    key : Key.Key;
    proof : Proof.Proof;
    value : ?[Nat8];
  };

  public type Receipt = {
    status : Nat8;
    cumulativeGasUsed : [Nat8];
    logsBloom : [Nat8];
    logs : [Log];
  };

  public type Log = {
    contractAddress : [Nat8];
    topics : [[Nat8]];
    data : [Nat8];
  };

  public type AccountProofInputText = {
    address : Text;
    nonce : Text;
    balance : Text;
    codeHash : Text;
    storageHash : Text;
    accountProof : [Text];
    blockHeader : {
      stateRoot : Text;
    };
  };

  public type StorageProofInputText = {
    storageHash : Text;
    storageProof : [{
      key : Text;
      proof : [Text];
      value : Text;
    }];
  };

  public type TransactionProofInputText = {
    rootHash : Text;
    proof : [[Text]];
    txIndex : Text;
  };
};
