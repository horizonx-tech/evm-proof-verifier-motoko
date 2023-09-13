import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Hash "mo:merkle-patricia-trie/Hash";
import Hex "mo:merkle-patricia-trie/util/Hex";
import { keccak } "mo:merkle-patricia-trie/util/Keccak";
import RLP "mo:rlp";
import RLPTypes "mo:rlp/types";

module {

  public func encodeRLPHex(input : RLPTypes.Input) : Text {
    let encoded = switch (RLP.encode(input)) {
      case (#err(error)) Debug.trap("RLPEncode failed: " # error);
      case (#ok(value)) value;
    };
    Hex.toText(Buffer.toArray(encoded));
  };

  public func textToKeccakBytes(text : Text) : [Nat8] {
    Hex.toArrayUnsafe(Hash.toHex(keccak(Blob.toArray(Text.encodeUtf8(text)))));
  };

};
