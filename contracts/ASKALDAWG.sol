// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ASKALDAWG is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner, uint256 initialSupply)
        ERC20("ASKALDAWG", "ASKALDAWG")
        ERC20Permit("ASKALDAWG")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply);
    }
}# ASKALDAWG — gasless mainnet token (SKALE) without relayer

> Production-ready Hardhat project to deploy **ASKALDAWG** on **SKALE Europa Hub mainnet** (gas-free). No relayer required. Deployment and transactions are executed directly by the deployer wallet using valueless sFUEL.

---

## Project layout

```
askaldawg/
├─ contracts/
│  ├─ ASKALDAWG.sol
├─ scripts/
│  ├─ deploy-all.ts               # deploy forwarder + token using deployer key
├─ hardhat.config.ts
├─ package.json
├─ tsconfig.json
├─ .env.example
└─ README.md
```import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await ethers.getSigners();

  const owner = process.env.OWNER_ADDRESS!;
  const supply = process.env.INITIAL_SUPPLY!;

  const ASKALDAWG = await ethers.getContractFactory("ASKALDAWG");
  const token = await ASKALDAWG.deploy(owner, supply);

  await token.deployed();

  console.log(`ASKALDAWG deployed to: ${token.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    skale: {
      url: process.env.RPC_URL,
      accounts: [process.env.DEPLOYER_KEY!],
      chainId: 2046399126, // SKALE Europa Hub mainnet
    },
  },
};

export default config;npx hardhat run scripts/deploy.ts --network skalenpx hardhat run scripts/deploy.ts --network skale
---{
  "compilerOptions": {
    "target": "es2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true
  }
}

## contracts/ASKALDAWG.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ASKALDAWG — ERC20 with EIP-2612 permit
contract ASKALDAWG is ERC20, ERC20Permit, Ownable {
    constructor(
        address initialOwner,
        uint256 initialSupply
    )
        ERC20("ASKALDAWG", "ASKALDAWG")
        ERC20Permit("ASKALDAWG")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply);
    }
}
```

---

## scripts/deploy-all.ts

```ts
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
```

---

## hardhat.config.ts

```ts
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
```

---

## package.json

```json
{
  "name": "askaldawg",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "hardhat compile",
    "deploy-all": "hardhat run scripts/deploy-all.ts --network skale_europa"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^5.0.0",
    "@openzeppelin/contracts": "^5.0.2",
    "dotenv": "^16.4.5",
    "hardhat": "^2.22.10",
    "ts-node": "^10.9.2",
    "typescript": "^5.5.4"
  },
  "dependencies": {
    "ethers": "^6.13.2"
  }
}
```

---

## .env.example

```bash
# SKALE Europa Hub mainnet RPC (gasless)
RPC_URL=https://mainnet.skalenodes.com/v1/elated-tan-skat

# Deployer key (used to broadcast deployment)
DEPLOYER_KEY=0xYOUR_PRIVATE_KEY

# Owner/recipient of initial supply
OWNER_ADDRESS=0x4B1a58A3057d03888510d93B52ABad9Fee9b351d

# Initial supply in wei (default 1,000,000 ASKALDAWG)
INITIAL_SUPPLY=1000000000000000000000000
```

---

## README.md (quick start)

```md
# ASKALDAWG on SKALE (gasless, no relayer)

## 1) Install
npm install

## 2) Configure
cp .env.example .env
# set DEPLOYER_KEY and OWNER_ADDRESS

## 3) Compile
npm run build

## 4) Deploy (mainnet, gasless)
npm run deploy-all
# Outputs token address

Notes
- SKALE Europa Hub mainnet is gas-free to users & contracts (sFUEL has no monetary value).
- Deployment is done directly by DEPLOYER_KEY; OWNER_ADDRESS receives all tokens.
```
