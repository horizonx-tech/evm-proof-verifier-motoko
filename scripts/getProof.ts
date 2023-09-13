import { getProof } from "./lib";

const address = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const keys = ["0x1"];
const block = "latest";

getProof(address, keys, block).then((res) => console.log(res));
