import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import MHex "mo:merkle-patricia-trie/util/Hex";
import Hex "mo:rlp/hex";
import Utils "mo:rlp/rlp/utils";
import Types "mo:rlp/types";

module {
  type Result<T, E> = Result.Result<T, E>;

  let threshold : Nat8 = 127; // 7f
  let threshold2 : Nat8 = 183; // b7
  let threshold3 : Nat8 = 247; // f7

  let threshold4 : Nat8 = 182; // b6
  let threshold5 : Nat8 = 191; // bf
  let threshold6 : Nat8 = 246; // f6
  let nullbyte : Nat8 = 128; // 80

  public func decode(input : Types.Input) : Result<Types.Decoded, Text> {
    switch (input) {
      case (#string(item)) {
        if (item.size() == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case (#number(item)) {
        if (item == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case (#Uint8Array(item)) {
        if (item.size() == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case (#List(item)) {
        if (item.size() == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case (#Null) {
        return #ok(#Uint8Array(Buffer.Buffer(1)));
      };
      case (#Undefined) {
        return #ok(#Uint8Array(Buffer.Buffer(1)));
      };
    };

    let inputBytes = switch (Utils.toBytes(input)) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    let decoded = _decode(inputBytes);

    switch (_decode(inputBytes)) {
      case (#ok(decoded)) {
        if (decoded.remainder.size() != 0) {
          return #err("invalid RLP: remainder must be zero: " # MHex.toText(Buffer.toArray(decoded.remainder)));
        };
        return #ok(decoded.data);
      };
      case (#err(val)) { return #err(val) };
    };
  };

  private type Output = {
    data : Types.Decoded;
    remainder : Buffer.Buffer<Nat8>;
  };

  private func _decode(input : Types.Uint8Array) : Result<Output, Text> {
    let firstByte = input.get(0);

    if (firstByte <= threshold) {
      // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
      return decodeSingleByte(input);
    } else if (firstByte <= threshold2) {
      // string is 0-55 bytes long. A single byte with value 0x80 plus the length of the string followed by the string
      return decodeShortString(input);
    } else if (firstByte <= threshold5) {
      // string is greater than 55 bytes long. A single byte with the value (0xb7 plus the length of the length), followed by the length, followed by the string
      return decodeLongString(input);
    } else if (firstByte <= threshold3) {
      // a list between  0-55 bytes long
      return decodeShortList(input);
    } else {
      // a list  over 55 bytes long
      return decodeLongList(input);
    };
  };

  private func decodeSingleByte(input : Types.Uint8Array) : Result<Output, Text> {
    let (left, right) = Buffer.split<Nat8>(input, 1);
    return #ok({
      data = #Uint8Array(left);
      remainder = right;
    });
  };

  private func decodeShortString(input : Types.Uint8Array) : Result<Output, Text> {
    let firstByte = input.get(0);
    let length : Nat8 = firstByte - threshold;

    let dataSlice = if (firstByte == nullbyte) {
      Buffer.Buffer<Nat8>(1);
    } else {
      switch (Utils.safeSlice(input, 1, Nat8.toNat(length))) {
        case (#ok(val)) { val };
        case (#err(val)) { return #err(val) };
      };
    };

    if (length == 2 and dataSlice.get(0) < nullbyte) {
      return #err("invalid RLP encoding: invalid prefix, single byte < 0x80 are not prefixed");
    };

    let remainderSlice = switch (Utils.safeSlice(input, Nat8.toNat(length), input.size())) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    return #ok({
      data = #Uint8Array(dataSlice);
      remainder = remainderSlice;
    });
  };

  private func decodeLongString(input : Types.Uint8Array) : Result<Output, Text> {
    let firstByte = input.get(0);
    let llength = firstByte - threshold4;
    if (Nat.sub(input.size(), 1) < Nat8.toNat(llength)) {
      return #err("invalid RLP: not enough bytes for string length");
    };
    let inputSlice = switch (Utils.safeSlice(input, 1, Nat8.toNat(llength))) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    let length = switch (decodeLength(inputSlice)) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    if (length <= 55) {
      return #err("invalid RLP: expected string length to be greater than 55");
    };

    let data = switch (Utils.safeSlice(input, Nat8.toNat(llength), Nat32.toNat(length) + Nat8.toNat(llength))) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    let _remainder = switch (Utils.safeSlice(input, Nat32.toNat(length) + Nat8.toNat(llength), input.size())) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    return #ok({
      data = #Uint8Array(data);
      remainder = _remainder;
    });
  };

  private func decodeShortList(input : Types.Uint8Array) : Result<Output, Text> {
    let firstByte = input.get(0);
    let length = firstByte - threshold5;

    var innerRemainder = switch (Utils.safeSlice(input, 1, Nat8.toNat(length))) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    let decoded = Buffer.Buffer<Types.Decoded>(1);
    while (innerRemainder.size() > 0) {
      let d = switch (_decode(innerRemainder)) {
        case (#ok(val)) { val };
        case (#err(val)) { return #err(val) };
      };
      decoded.add(d.data);
      innerRemainder := d.remainder;
    };

    let _remainder = switch (Utils.safeSlice(input, Nat8.toNat(length), input.size())) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    return #ok({
      data = #Nested(decoded);
      remainder = _remainder;
    });
  };

  private func decodeLongList(input : Types.Uint8Array) : Result<Output, Text> {
    let firstByte = input.get(0);
    let llength = firstByte - threshold6;
    let inputSlice = switch (Utils.safeSlice(input, 1, Nat8.toNat(llength))) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    let length = switch (decodeLength(inputSlice)) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    if (length < 56) {
      return #err("invalid RLP: encoded list too short");
    };
    let totalLength = Nat32.toNat(length) + Nat8.toNat(llength);
    if (totalLength > input.size()) {
      return #err("invalid RLP: total length is larger than the data");
    };

    var innerRemainder = switch (Utils.safeSlice(input, Nat8.toNat(llength), totalLength)) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };
    let decoded = Buffer.Buffer<Types.Decoded>(1);
    while (innerRemainder.size() > 0) {
      let d = switch (_decode(innerRemainder)) {
        case (#ok(val)) { val };
        case (#err(val)) { return #err(val) };
      };
      decoded.add(d.data);
      innerRemainder := d.remainder;
    };
    let _remainder = switch (Utils.safeSlice(input, totalLength, input.size())) {
      case (#ok(val)) { val };
      case (#err(val)) { return #err(val) };
    };

    return #ok({
      data = #Nested(decoded);
      remainder = _remainder;
    });
  };

  /*
  * Parse integers. Check if there is no leading zeros
  * @param v The value to parse
  * @param base The base to parse the integer into
  */
  // private func decodeLength(v : Types.Uint8Array) : Result<Nat8, Text> {
  //   if (v.get(0) == 0 and v.get(1) == 0) {
  //     return #err("invalid RLP: extra zeros");
  //   };
  //   return switch (Hex.decode(Hex.encode(Buffer.toArray(v)))) {
  //     case (#ok(val)) { #ok(val[0]) };
  //     case (#err(err)) { return #err("not a valid hex") };
  //   };
  // };
  public func decodeLength(bytes : Buffer.Buffer<Nat8>) : Result<Nat32, Text> {
    var result : Nat32 = 0;
    for (i in Iter.range(0, bytes.size() - 1)) {
      result += (Nat32.fromNat(Nat8.toNat(bytes.get(i))) << Nat32.fromNat(8 * (bytes.size() -1 -i)));
    };

    #ok(result);
  };
};
