import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Hash "mo:merkle-patricia-trie/Hash";
import Key "mo:merkle-patricia-trie/Key";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Keccak "mo:merkle-patricia-trie/util/Keccak";
import RLP "mo:merkle-patricia-trie/util/rlp/encode";
import RLPTypes "mo:rlp/types";

import Types "types";

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
            transactionsRoot : Text;
            proof : [[Text]];
            txIndex : Text;
        }
    ) : Result.Result<Types.MerkleProof, Text> {
        let rootHash = switch (Hash.fromHex(input.transactionsRoot)) {
            case null return #err("Failed to parse to Hash: " # input.transactionsRoot);
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

    public func toMerkleProof(
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
            case (#ok(keyBytes)) if (proofType == #storage) padBytes(keyBytes, 32) else keyBytes;
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

    public func padBytes(bytes : [Nat8], size : Nat) : [Nat8] {
        if (bytes.size() >= size) return bytes;
        let buffer = Buffer.Buffer<Nat8>(size);
        for (i in Iter.range(0, size - bytes.size() - 1)) {
            buffer.add(0);
        };
        for (byte in bytes.vals()) {
            buffer.add(byte);
        };
        Buffer.toArray(buffer);
    };
};
