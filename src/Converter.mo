import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Hash "mo:merkle-patricia-trie/Hash";
import Key "mo:merkle-patricia-trie/Key";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Keccak "mo:merkle-patricia-trie/util/Keccak";
import RLP "mo:rlp";
import RLPTypes "mo:rlp/types";

import Types "types";
import Utils "Utils";

module {
  public func toAccountProof(
    input : {
      address : Text;
      nonce : Text;
      balance : Text;
      codeHash : Text;
      storageHash : Text;
      accountProof : [Text];
      blockHeader : { stateRoot : Text };
    }
  ) : Result.Result<Types.MerkleProof, Text> {
    let value = Buffer.fromArray<RLPTypes.Input>([
      #string("0x" # input.nonce),
      #string("0x" # input.balance),
      #string("0x" # input.storageHash),
      #string("0x" # input.codeHash),
    ]);
    toMerkleProof(#account, input.blockHeader.stateRoot, input.address, input.accountProof, ? #List(value));
  };

  public func toStorageProof(
    input : {
      storageHash : Text;
      storageProof : [{ key : Text; proof : [Text]; value : Text }];
    },
    index : Nat,
  ) : Result.Result<Types.MerkleProof, Text> {
    let target = input.storageProof[index];
    toMerkleProof(#storage, input.storageHash, target.key, target.proof, ? #string("0x" # target.value));
  };

  public func toTxProof(
    input : {
      rootHash : Text;
      proof : [[Text]];
      txIndex : Text;
    }
  ) : Result.Result<Types.MerkleProof, Text> {
    let rootHash = switch (Hash.fromHex(input.rootHash)) {
      case null return #err("Failed to parse to Hash: " # input.rootHash);
      case (?hash) hash;
    };
    let key = switch (Key.fromHex(input.txIndex)) {
      case null return #err("Failed to parse to Key: " # input.txIndex);
      case (?key) key;
    };

    let proof = Buffer.Buffer<[Nat8]>(input.proof.size());
    for (arr in input.proof.vals()) {
      let value = Buffer.Buffer<RLPTypes.Input>(input.proof.size());
      for (item in arr.vals()) {
        value.add(#string("0x" # item));
      };
      switch (RLP.encode(#List(value))) {
        case (#err(error)) return #err(error);
        case (#ok(encoded)) {
          proof.add(Buffer.toArray(encoded));
        };
      };
    };
    let value = switch (Hex.toArray(input.proof[input.proof.size() -1][1])) {
      case (#err(error)) return #err(error);
      case (#ok(value)) ?value;
    };
    #ok({ rootHash; key; proof = Buffer.toArray(proof); value });
  };

  public func decodeReceipt(bytes : [Nat8]) : Result.Result<Types.Receipt, Text> {
    let buffer = Buffer.fromArray<Nat8>(bytes);
    // remove TransactionType: https://eips.ethereum.org/EIPS/eip-2718
    if (buffer.get(0) <= 0x7f) { let _ = buffer.remove(0) };

    let values = switch (RLP.decode(#Uint8Array(buffer))) {
      case (#ok(#Nested(decoded))) decoded;
      case (#err(error)) return #err("Failed to decode receipt: " # error);
      case (_) return #err("Input is not valid receipt: " # Hex.toText(bytes));
    };

    let receipt = {
      var status : Nat8 = 0;
      var cumulativeGasUsed : [Nat8] = [];
      var logsBloom : [Nat8] = [];
      var logs : [Types.Log] = [];
    };
    label l for (i in Iter.range(0, values.size() - 1)) {
      switch (i) {
        case (0) {
          let #Uint8Array(value) = values.get(i) else return #err("Failed to decode status");
          receipt.status := value.get(0);
        };
        case (1) {
          let #Uint8Array(value) = values.get(i) else return #err("Failed to decode cumulativeGasUsed");
          receipt.cumulativeGasUsed := Buffer.toArray(value);
        };
        case (2) {
          let #Uint8Array(value) = values.get(i) else return #err("Failed to decode logsBloom");
          receipt.logsBloom := Buffer.toArray(value);
        };
        case (3) {
          let #Nested(logsRlp) = values.get(i) else return #err("Failed to decode logs");
          switch (decodeReceiptLogs(logsRlp)) {
            case (#err(error)) return #err("Failed to decode logs: " # error);
            case (#ok(logs)) receipt.logs := logs;
          };
        };
        case (_) { break l };
      };
    };

    #ok({
      status = receipt.status;
      cumulativeGasUsed = receipt.cumulativeGasUsed;
      logsBloom = receipt.logsBloom;
      logs = receipt.logs;
    });
  };

  public func decodeReceiptLogs(logsRlp : Buffer.Buffer<RLPTypes.Decoded>) : Result.Result<[Types.Log], Text> {
    let logsBuf = Buffer.Buffer<Types.Log>(logsRlp.size());
    for (i in Iter.range(0, logsRlp.size() - 1)) {
      let #Nested(values) = logsRlp.get(i) else return #err("log[" # Nat.toText(i) # "]");
      let log = switch (decodeReceiptLog(values)) {
        case (#err(error)) return #err("log[" # Nat.toText(i) # "]." # error);
        case (#ok(log)) log;
      };
      logsBuf.add(log);
    };

    #ok(Buffer.toArray(logsBuf));
  };

  public func decodeReceiptLog(values : Buffer.Buffer<RLPTypes.Decoded>) : Result.Result<Types.Log, Text> {
    let log = {
      var contractAddress : [Nat8] = [];
      var topics : [[Nat8]] = [];
      var data : [Nat8] = [];
    };
    for (i in Iter.range(0, Nat.min(2, values.size() - 1))) {
      switch (i) {
        case (0) {
          let #Uint8Array(value) = values.get(i) else return #err("contractAddress");
          log.contractAddress := Buffer.toArray(value);
        };
        case (1) {
          let #Nested(topics) = values.get(i) else return #err("topics");
          let topicsBuf = Buffer.Buffer<[Nat8]>(topics.size());
          for (j in Iter.range(0, topics.size() - 1)) {
            let #Uint8Array(value) = topics.get(j) else return #err("topics[" # Nat.toText(j) # "]");
            topicsBuf.add(Buffer.toArray(value));
          };
          log.topics := Buffer.toArray(topicsBuf);
        };
        case (2) {
          let #Uint8Array(value) = values.get(i) else return #err("data");
          log.data := Buffer.toArray(value);
        };
        case (_) {};
      };
    };

    #ok({
      contractAddress = log.contractAddress;
      topics = log.topics;
      data = log.data;
    });
  };

  func toMerkleProof(
    proofType : Types.ProofType,
    rootHashText : Text,
    keyText : Text,
    proofTextArr : [Text],
    valueInput : ?RLPTypes.Input,
  ) : Result.Result<Types.MerkleProof, Text> {
    let rootHash = switch (Hash.fromHex(rootHashText)) {
      case null return #err("Failed to parse to Hash: " # rootHashText);
      case (?hash) hash;
    };

    let keyBytes = switch (Hex.toArray(keyText)) {
      case (#err(error)) return #err("Failed to parse to Bytes: " # keyText # ", err: " # error);
      case (#ok(keyBytes)) if (proofType == #storage) Utils.padBytes(keyBytes, 32) else keyBytes;
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
        switch (RLP.encode(valueInput)) {
          case (#err(error)) return #err(error);
          case (#ok(value)) ?Buffer.toArray(value);
        };
      };
    };
    return #ok({ rootHash; key; proof = Buffer.toArray(proofBuf); value });
  };
};
