# ASKALDAWG — gasless mainnet token (SKALE) with ERC-2771 meta-tx support

> Production-ready Hardhat project to deploy **ASKALDAWG** on **SKALE Europa Hub mainnet** (gas-free). Includes ERC-2771 compatibility (via OpenZeppelin `ERC2771Context` + `MinimalForwarder`) so a relayer can sponsor all user tx. The **deployer never pays**: deployments and tx are sent by a relayer key on a gasless chain; the owner address can be an empty wallet.

---

## Project layout

```
askaldawg/
├─ contracts/
│  ├─ ASKALDAWG.sol
│  └─ MinimalForwarder.sol        # imported from OZ for clarity (optional; can import directly)
├─ scripts/
│  ├─ deploy.ts                   # deploy forwarder + token using relayer key
│  ├─ verify.ts                   # optional: print codehash & bytecode metadata
│  └─ relay-transfer.ts           # example: user-signed meta-tx relayed via MinimalForwarder
├─ hardhat.config.ts
├─ package.json
├─ tsconfig.json
├─ .env.example
└─ README.md
```

---

## contracts/ASKALDAWG.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ASKALDAWG — gasless-ready ERC20 with EIP-2612 permit and ERC-2771 meta-tx
/// @dev Trusted forwarder enables relayed calls; deploy on SKALE for zero-fee execution.
contract ASKALDAWG is ERC20, ERC20Permit, ERC2771Context, Ownable {
    constructor(
        address trustedForwarder,
        address initialOwner,
        uint256 initialSupply
    )
        ERC20("ASKALDAWG", "ASKALDAWG")
        ERC20Permit("ASKALDAWG")
        ERC2771Context(trustedForwarder)
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply);
    }

    // --- ERC2771 overrides ---
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
```

---

## contracts/MinimalForwarder.sol (optional local copy)

> You can import directly from `@openzeppelin/contracts/metatx/MinimalForwarder.sol`. Keeping a local copy simplifies verifying sources on explorers that don’t auto-resolve NPM imports.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
// This file is intentionally thin; OZ implementation is used as-is.
```

---

## scripts/deploy.ts

```ts
// scripts/deploy.ts
import "dotenv/config";
import { ethers } from "hardhat";

/**
 * Why relayer key? Ensures deployer wallet never pays; owner can be any EOA with 0 balance.
 */
async function main() {
  const rpc = process.env.RPC_URL!;
  const relayerKey = process.env.RELAYER_KEY!; // used only to broadcast
  const owner = process.env.OWNER_ADDRESS!;
  const supply = BigInt(process.env.INITIAL_SUPPLY || "1000000000000000000000000"); // 1M 18d

  if (!rpc || !relayerKey || !owner) throw new Error("Missing env: RPC_URL, RELAYER_KEY, OWNER_ADDRESS");

  // Connect signer to SKALE RPC
  const provider = new ethers.JsonRpcProvider(rpc);
  const wallet = new ethers.Wallet(relayerKey, provider);

  // 1) Deploy MinimalForwarder
  const Fwd = await ethers.getContractFactory("MinimalForwarder", wallet);
  const fwd = await Fwd.deploy();
  await fwd.waitForDeployment();
  const forwarder = await fwd.getAddress();

  // 2) Deploy ASKALDAWG, owned by `owner`, meta-tx via `forwarder`
  const Token = await ethers.getContractFactory("ASKALDAWG", wallet);
  const token = await Token.deploy(forwarder, owner, supply);
  await token.waitForDeployment();

  console.log("Forwarder:", forwarder);
  console.log("ASKALDAWG:", await token.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

---

## scripts/relay-transfer.ts (example meta-tx relay)

```ts
// scripts/relay-transfer.ts
import "dotenv/config";
import { ethers } from "ethers";
import MinimalForwarderAbi from "@openzeppelin/contracts/build/contracts/MinimalForwarder.json" assert { type: "json" };

/**
 * Why? Demonstrates relayer-sponsored transfer on behalf of a user via ERC-2771 MinimalForwarder.
 */
async function main() {
  const rpc = process.env.RPC_URL!;
  const relayerKey = process.env.RELAYER_KEY!; // pays (on SKALE it's 0-cost)
  const forwarderAddr = process.env.FORWARDER_ADDRESS!;
  const tokenAddr = process.env.TOKEN_ADDRESS!;
  const userKey = process.env.USER_KEY!; // wallet that signs but never pays
  const to = process.env.TRANSFER_TO!;
  const amount = BigInt(process.env.TRANSFER_AMOUNT || "1000000000000000000"); // 1 token (18d)

  const provider = new ethers.JsonRpcProvider(rpc);
  const relayer = new ethers.Wallet(relayerKey, provider);
  const user = new ethers.Wallet(userKey, provider);

  const forwarder = new ethers.Contract(forwarderAddr, MinimalForwarderAbi.abi, provider);

  // Encode call: token.transfer(to, amount)
  const erc20 = new ethers.Interface([
    "function transfer(address to, uint256 amount) returns (bool)",
  ]);
  const data = erc20.encodeFunctionData("transfer", [to, amount]);

  const from = user.address;
  const nonce: bigint = await forwarder.getNonce(from);

  // EIP-712 ForwardRequest per OZ MinimalForwarder
  const request = {
    from,
    to: tokenAddr,
    value: 0,
    gas: 200_000,
    nonce,
    data,
  };

  const chainId = (await provider.getNetwork()).chainId;

  const domain = {
    name: "MinimalForwarder",
    version: "0.0.1",
    chainId,
    verifyingContract: forwarderAddr,
  } as const;

  const types = {
    ForwardRequest: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "value", type: "uint256" },
      { name: "gas", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "data", type: "bytes" },
    ],
  } as const;

  const signature = await user.signTypedData(domain as any, types as any, request as any);

  // Relayer executes
  const fwdWithRelayer = forwarder.connect(relayer);
  const tx = await fwdWithRelayer.execute(request, signature, { gasLimit: 300_000 });
  console.log("relay tx:", tx.hash);
  await tx.wait();
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
      accounts: process.env.RELAYER_KEY ? [process.env.RELAYER_KEY] : [],
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
    "deploy": "hardhat run scripts/deploy.ts --network skale_europa",
    "relay": "ts-node --transpile-only scripts/relay-transfer.ts"
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

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "esModuleInterop": true,
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "strict": true,
    "skipLibCheck": true,
    "types": ["node", "hardhat"],
    "outDir": "dist"
  },
  "include": ["scripts", "hardhat.config.ts"]
}
```

---

## .env.example

```bash
# SKALE Europa Hub mainnet RPC (gasless)
RPC_URL=https://mainnet.skalenodes.com/v1/elated-tan-skat

# Relayer key that broadcasts deployments/relays (funds not required on SKALE)
RELAYER_KEY=0xYOUR_PRIVATE_KEY

# The owner/recipient of initial supply (can be empty wallet)
OWNER_ADDRESS=0xYourOwnerEOA

# Initial supply in wei (default 1,000,000 ASKALDAWG)
INITIAL_SUPPLY=1000000000000000000000000

# Optional for relay demo
FORWARDER_ADDRESS=0xForwarderAfterDeploy
TOKEN_ADDRESS=0xTokenAfterDeploy
USER_KEY=0xEndUserPrivateKeyNeverPays
TRANSFER_TO=0xReceiver
TRANSFER_AMOUNT=1000000000000000000
```

---

## README.md (quick start)

```md
# ASKALDAWG on SKALE (gasless, ERC-2771 ready)

## 1) Install
pnpm i  # or npm i / yarn

## 2) Configure
cp .env.example .env
# set OWNER_ADDRESS and RELAYER_KEY

## 3) Compile
npm run build

## 4) Deploy (mainnet, gasless)
npm run deploy
# Outputs forwarder + token addresses

## 5) Relay a user transfer (meta-tx)
# Fill FORWARDER_ADDRESS, TOKEN_ADDRESS, USER_KEY, TRANSFER_TO in .env
npm run relay

Notes
- SKALE Europa Hub mainnet is gas-free to users & contracts (sFUEL has no monetary value).
- Deployer never pays: all tx are sent by RELAYER_KEY on a gasless chain; OWNER_ADDRESS holds tokens & ownership.
- For other EVM chains, you can swap RPC and attach a Paymaster/Relayer service.
```
