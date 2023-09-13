import dotenv from "dotenv";

dotenv.config();

export const EnvVars = {
  rpcUrl: process.env.RPC_URL,
  trim0xPrefix: process.env.TRIM_0X_PREFIX === "true",
};
