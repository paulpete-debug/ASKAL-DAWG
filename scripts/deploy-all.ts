// scripts/deploy-all.ts
import "dotenv/config";
import { ethers } from "hardhat";
import { writeFileSync } from "fs";


async function main() {
const rpc = process.env.RPC_URL!;
const deployerKey = process.env.DEPLOYER_KEY!;
const owner = process.env.OWNER_ADDRESS!;
const supply = BigInt(
process.env.INITIAL_SUPPLY || "1000000000000000000000000"
);


if (!rpc || !deployerKey || !owner) {
throw new Error("Missing env vars (RPC_URL, DEPLOYER_KEY, OWNER_ADDRESS)");
}


const provider = new ethers.JsonRpcProvider(rpc);
const wallet = new ethers.Wallet(deployerKey, provider);


console.log("Deploying with wallet:", wallet.address);


// Deploy ASKALDAWG
const Token = await ethers.getContractFactory("ASKALDAWG", wallet);
const token = await Token.deploy(owner, supply);
await token.waitForDeployment();
const tokenAddr = await token.getAddress();


console.log("ASKALDAWG deployed:", tokenAddr);


const out = {
token: tokenAddr,
owner,
supply: supply.toString(),
chainId: (await provider.getNetwork()).chainId.toString(),
};
writeFileSync("deployments.json", JSON.stringify(out, null, 2));
console.log("Saved deployments.json");
}


main().catch((e) => {
console.error(e);
process.exit(1);
});
