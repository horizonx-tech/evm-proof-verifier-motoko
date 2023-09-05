import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {
    public func padBytes(bytes : [Nat8], size : Nat) : [Nat8] {
        if (bytes.size() >= size) return bytes;
        let buffer = Buffer.Buffer<Nat8>(size);
        for (i in Iter.range(0, size - bytes.size() - 1)) {
            buffer.add(0)
        };
        for (byte in bytes.vals()) {
            buffer.add(byte)
        };
        Buffer.toArray(buffer)
    }
}
