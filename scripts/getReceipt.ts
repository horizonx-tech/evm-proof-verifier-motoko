import { getReceipt } from "./lib";

const txHash =
  "0xe2dd3fb9d9b16e0e250aba1a4820eea81fdc7843c4d1ec0a924f58a0b3a6fde1";

getReceipt(txHash).then((res) => console.log(res));
