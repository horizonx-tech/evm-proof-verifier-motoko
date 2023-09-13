import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat8 "mo:base/Nat8";

module {

  public func filledBuffer<X>(len : Nat, value : X) : Buffer.Buffer<X> {
    let buf = Buffer.Buffer<X>(len);
    for (_ in Iter.range(0, len - 1)) {
      buf.add(value);
    };
    buf;
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

  public func toNat16(bytes : [Nat8]) : Nat16 {
    var result : Nat16 = 0;
    for (i in Iter.range(0, Nat.min(1, bytes.size() -1))) {
      result += Nat16.fromNat(Nat8.toNat(bytes.get(i))) << Nat16.fromNat((8 * (bytes.size() - 1 - i)));
    };
    result;
  };
};
