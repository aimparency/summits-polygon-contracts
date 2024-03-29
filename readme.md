# summits contracts for eth/polygon

## compile and deploy contracts
Change directory into the repo root. 

Copy `.env.example` to `.env`. 
Set PRIVATE_KEY to your developer eth account's private key. 


First compile the contracts with `yarn hardhat compile`. 

Then start a local blockchain by executing `yarn hardhat node`.

Deploy your contract with `yarn hardhat run scripts/deploy.ts --network localhost`. `--network localhost` will instruct hardhat to use that local blockchain that was started with `yarn hardhat node`. 

If you want to deploy on goerli or mumbai, open `.env` and fill in the URL and PRIVATE_KEY variables. Then run `yarn hardhat run scripts/deploy.ts` with `--network goerli` or `mumbai`. 

In case you want to deploy on a still different network, have a look into `./hardhat.config.ts`. 

## contract abis
both files `artifacts/contracts/[Aim.sol|Summits.sol]/[Aim.json|Summits.json]` get copied to `./release` and added for new release versions of the contracts. 

## hardhat commands

```shell
yarn hardhat accounts
yarn hardhat compile
yarn hardhat clean
yarn hardhat test
yarn hardhat node
yarn hardhat help
REPORT_GAS=true yarn hardhat test
yarn hardhat coverage
yarn hardhat run scripts/deploy.ts
TS_NODE_FILES=true yarn ts-node scripts/deploy.ts
yarn eslint '**/*.{js,ts}'
yarn eslint '**/*.{js,ts}' --fix
yarn prettier '**/*.{json,sol,md}' --check
yarn prettier '**/*.{json,sol,md}' --write
yarn solhint 'contracts/**/*.sol'
yarn solhint 'contracts/**/*.sol' --fix
```

<!---
## Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
yarn hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

## Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
-->
