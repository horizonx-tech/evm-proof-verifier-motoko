import { getTransactionProof } from "./lib";

const txHash =
  "0xe2dd3fb9d9b16e0e250aba1a4820eea81fdc7843c4d1ec0a924f58a0b3a6fde1";
const trustedBlockHash =
  "0x04979845434f201c937d95b22946b5d46d4db3e17756ce460b70e4df9a037fde";

getTransactionProof(txHash, trustedBlockHash).then((res) => console.log(res));
