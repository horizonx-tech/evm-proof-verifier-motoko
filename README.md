# EVM Proof Verifier Motoko

## Install

### MOPS

```bash
mops add evm-proof-verifier
```

### Vessel

Add the repository to `package-set.dhall`:

```dhall
...
let additions = [
  { name = "evm-proof-verifier"
  , version = "main"
  , repo = "https://github.com/horizonx-tech/evm-proof-verifier"
  , dependencies = [ "base", "rlp", "sha3", "merkle-patricia-trie" ],
  },
  { name = "merkle-patricia-trie"
  , version = "master"
  , repo = "https://github.com/f0i/merkle-patricia-trie.mo"
  , dependencies = [ "base", "rlp", "sha3" ],
  },
  { name = "rlp"
  , version = "master"
  , repo = "https://github.com/relaxed04/rlp-motoko"
  , dependencies = [] : List Text
  },
  { name = "sha3"
  , version = "master"
  , repo = "https://github.com/hanbu97/motoko-sha3"
  , dependencies = [] : List Text
  }
] : List Package
...
```

and to the dependencies in `vessel.dhall`:

```dhall
{
  dependencies = [ "base", "evm-proof-verifier" ],
  compiler = Some "0.8.3"
}
```

## Usage

This package consists 2 main components, [Verifier.mo](/src/Verifier.mo) and [Bloom.mo](/src/Bloom.mo), and utilities.
Here is the example and you can learn more in [tests](/test).

```mo
import Bloom "mo:evm-proof-verifier/Bloom";
import Converter "mo:evm-proof-verifier/Converter";
import Debug "mo:base/Debug";
import Verifier "mo:evm-proof-verifier/Verifier";
import Utils "mo:evm-proof-verifier/Utils";

// Verify Proof
let #ok(storageProof) = Converter.toStorageProof(
    // proof data
    {
      storageHash: "1f2e8062...",
      stroageProof: [{key: "0", proof: ["f90211a0c1c1ab..."], value: "5772..."}, ... ],
    },
    // index of proof to verify
    0
  ) else ...;

let #ok(result_bool) = Verifier.verifyMerkleProof(storageProof) else ...

// Test Bloom
let bool = Bloom.test(logsBloomBytesArr, Utils.padBytes(topicByteArr, 32));

```

## Testing

All test cases can be executed using the Makefile.

```bash
make test
```

## Scripts

Helper scripts to get proof data.

```
git clone https://github.com/horizonx-tech/evm-proof-verifier-motoko
cd evm-proof-verifier-motoko

pnpm install
cp .env.example .env
pnpm run ts-node scripts/getProof.ts
```

You need to fill env vars and parameters before running scripts,

`.env`

```
RPC_URL=required
TRIM_0X_PREFIX=true/false
```

`./scripts/getProof.ts`

```typescript
const address = "0x...";
const keys = ["0x..."];
const block = "latest"; // tag or number or hash
```
