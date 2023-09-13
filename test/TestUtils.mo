import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import M "mo:matchers/Matchers";
import { run; suite; testLazy } "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Hash "mo:merkle-patricia-trie/Hash";
import Hex "mo:merkle-patricia-trie/util/Hex";
import { keccak } "mo:merkle-patricia-trie/util/Keccak";

module {

  public func textToKeccakBytes(text : Text) : [Nat8] {
    Hex.toArrayUnsafe(Hash.toHex(keccak(Blob.toArray(Text.encodeUtf8(text)))));
  };

};
