## Foundry

Step 1: Run
```
npm install
```

and Install Openzeppline contracts using forge install

```
forge install Openzepplin/openzepplin-contracts/
```

Step 2: Get USDC on Optimism

visit this link and mint some USDC for yourself

https://sepolia-optimism.etherscan.io/address/0x488327236B65C61A6c083e8d811a4E0D3d1D4268#code

Enjoy!!!!!!! But use It wisely.

Step 3: Run the command to test V1

```
forge script script/stargateTransfer.s.sol --rpc-url $OP_SEPOLIA_RPC_URL
forge script script/stargateTransfer.s.sol --rpc-url $OP_SEPOLIA_RPC_URL --broadcast (To deploy as well)
```

Step 4: Run the command to test V2

```
forge script script/StarGateTransferV2.s.sol --rpc-url $OP_SEPOLIA_RPC_URL
```

Step 5: check the transction hash on Layer zero scan

```
https://testnet.layerzeroscan.com/
```

Step 6: To be continued

Adding LzCompose



