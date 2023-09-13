import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat8 "mo:base/Nat8";
import Hash "mo:merkle-patricia-trie/Hash";
import { keccak } "mo:merkle-patricia-trie/util/Keccak";

import Types "types";
import Utils "Utils";

module {

  type BloomValues = {
    i1 : Nat;
    v1 : Nat8;
    i2 : Nat;
    v2 : Nat8;
    i3 : Nat;
    v3 : Nat8;
  };

  let bloomLength = 256;

  public func create(logs : [Types.Log]) : [Nat8] {
    let buf = Utils.filledBuffer<Nat8>(bloomLength, 0);
    for (log in logs.vals()) {
      add(buf, log.contractAddress);
      for (topic in log.topics.vals()) {
        add(buf, topic);
      };
    };
    Buffer.toArray(buf);
  };

  public func test(bloom : [Nat8], topic : [Nat8]) : Bool {
    let { v1; i1; v2; i2; v3; i3 } = bloomValues(topic);
    v1 == (v1 & bloom[i1]) and v2 == (v2 & bloom[i2]) and v3 == (v3 & bloom[i3]);
  };

  func add(buf : Buffer.Buffer<Nat8>, bytes : [Nat8]) {
    let { i1; v1; i2; v2; i3; v3 } = bloomValues(bytes);
    buf.put(i1, buf.get(i1) | v1);
    buf.put(i2, buf.get(i2) | v2);
    buf.put(i3, buf.get(i3) | v3);
  };

  func bloomValues(bytes : [Nat8]) : BloomValues {
    let hashed = Hash.toArray(keccak(bytes));
    {
      v1 = 1 << (hashed[1] & 0x7);
      v2 = 1 << (hashed[3] & 0x7);
      v3 = 1 << (hashed[5] & 0x7);
      i1 = bloomLength - Nat16.toNat((Utils.toNat16(hashed) & 0x7ff) >> 3) - 1;
      i2 = bloomLength - Nat16.toNat((Utils.toNat16([hashed[2], hashed[3]]) & 0x7ff) >> 3) - 1;
      i3 = bloomLength - Nat16.toNat((Utils.toNat16([hashed[4], hashed[5]]) & 0x7ff) >> 3) - 1;
    };
  };
};
