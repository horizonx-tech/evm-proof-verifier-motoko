// @ts-ignore
import { encode, toBuffer } from "eth-util-lite";
// @ts-ignore
import { Receipt } from "eth-object";
import { JsonRpcProvider, Transaction, encodeBytes32String } from "ethers";
import { BaseTrie } from "merkle-patricia-tree";
import { EnvVars } from "./env";

const provider = new JsonRpcProvider(EnvVars.rpcUrl);

const trim0xPrefix = true;

const replacer = (_key: string, val: any) =>
  trim0xPrefix && typeof val === "string" && val.startsWith("0x")
    ? val.replace("0x", "")
    : val;

export const getProof = async (
  address: string,
  keys: string[],
  block: string
) => {
  const proof = await provider.send("eth_getProof", [
    address,
    keys.map(encodeBytes32String),
    block,
  ]);
  return JSON.stringify(proof, replacer, 2);
};

export const getTransactionProof = async (
  txHash: string,
  trustedBlockHash?: string
) => {
  const tx = await provider.send("eth_getTransactionByHash", [txHash]);
  if (!tx?.blockHash) return Promise.reject(`Tx not found: ${txHash}`);
  if (trustedBlockHash && tx.blockHash !== trustedBlockHash)
    return Promise.reject(
      `Block does not match: actual=${tx.blockHash}, expected=${trustedBlockHash}`
    );
  const block = await provider.send("eth_getBlockByHash", [tx.blockHash, true]);
  if (!block) return Promise.reject(`Block not found: ${tx.blockHash}`);

  const tree = new BaseTrie();
  await Promise.all(
    block.transactions.map((siblingTx: any, index: any) => {
      const siblingPath = encode(index);
      const serializedSiblingTx = Transaction.from({
        ...siblingTx,
        type: Number(siblingTx.type || 0),
        gasLimit: siblingTx.gas,
        data: siblingTx.input,
        signature: {
          v: siblingTx.v,
          r: siblingTx.r,
          s: siblingTx.s,
        },
      }).serialized;
      return tree.put(siblingPath, toBuffer(serializedSiblingTx));
    })
  );

  const { stack } = await tree.findPath(encode(tx.transactionIndex));
  const res = {
    // @ts-ignore
    rootHash: block.transactionsRoot,
    txProof: stack.map((node) =>
      node.raw()?.map((v) => v?.toString("hex") || "")
    ),
    txIndex: tx.transactionIndex,
  };
  return JSON.stringify(res, replacer, 2);
};

export const getReceiptProof = async (
  txHash: string,
  trustedBlockHash?: string
) => {
  const tx = await provider.send("eth_getTransactionReceipt", [txHash]);
  if (!tx?.blockHash) return Promise.reject(`Tx not found: ${txHash}`);
  if (trustedBlockHash && tx.blockHash !== trustedBlockHash)
    return Promise.reject(
      `Block does not match: actual=${tx.blockHash}, expected=${trustedBlockHash}`
    );
  const block = await provider.send("eth_getBlockByHash", [
    tx.blockHash,
    false,
  ]);
  if (!block) return Promise.reject(`Block not found: ${tx.blockHash}`);

  const receipts = await Promise.all(
    block.transactions.map((tx: string) =>
      provider.send("eth_getTransactionReceipt", [tx])
    )
  );

  const tree = new BaseTrie();
  await Promise.all(
    receipts.map((siblingReceipt: any, index: any) => {
      const siblingPath = encode(index);
      const serializedSiblingTx = Receipt.fromRpc(siblingReceipt).serialize();
      return tree.put(siblingPath, toBuffer(serializedSiblingTx));
    })
  );
  const { stack } = await tree.findPath(encode(tx.transactionIndex));
  const res = {
    // @ts-ignore
    rootHash: block.transactionsRoot,
    txProof: stack.map((node) =>
      node.raw()?.map((v) => v?.toString("hex") || "")
    ),
    txIndex: tx.transactionIndex,
  };
  return JSON.stringify(res, replacer, 2);
};

export const getReceipt = async (txHash: string) => {
  const receipt = await provider.send("eth_getTransactionReceipt", [txHash]);
  return JSON.stringify(receipt, replacer, 2);
};
