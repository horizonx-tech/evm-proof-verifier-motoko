let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.9.8-20230811/package-set.dhall sha256:162f8cfe5f4df8c65d3ef46b6ee2275235476b94290b92dff2626733676fd2db
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { name = "merkle-patricia-trie"
  , version = "main"
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

in  upstream # additions
