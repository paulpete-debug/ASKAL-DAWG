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
