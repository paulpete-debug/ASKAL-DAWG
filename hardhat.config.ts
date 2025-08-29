import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";


const config: HardhatUserConfig = {
solidity: {
version: "0.8.24",
settings: { optimizer: { enabled: true, runs: 200 } },
},
networks: {
skale_europa: {
url: process.env.RPC_URL || "https://mainnet.skalenodes.com/v1/elated-tan-skat",
accounts: process.env.DEPLOYER_KEY ? [process.env.DEPLOYER_KEY] : [],
},
},
};
export default config;
