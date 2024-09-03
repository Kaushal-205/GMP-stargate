// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/stargateTransfer.sol"; 


contract StargateTransferScript is Script {
    // Constants
    address constant STARGATE_ROUTER_OP_SEPOLIA = 0xa2dfFdDc372C6aeC3a8e79aAfa3953e8Bc956D63;
    address constant USDC_OP_SEPOLIA = 0x488327236B65C61A6c083e8d811a4E0D3d1D4268;
    uint16 constant DST_CHAIN_ID_ARB_SEPOLIA = 10231; // Arbitrum Sepolia chain ID
    uint256 constant SRC_POOL_ID = 1; // USDC pool ID on OP Sepolia
    uint256 constant DST_POOL_ID = 1; // USDC pool ID on Arbitrum Sepolia

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the StargateTransfer contract
        StargateTransfer stargateTransfer = new StargateTransfer(STARGATE_ROUTER_OP_SEPOLIA);
        

        // Approve USDC spend
        IERC20(USDC_OP_SEPOLIA).approve(address(stargateTransfer), type(uint256).max);

        // Get fee quote
        (uint256 nativeFee, ) = stargateTransfer.getFeesQuote(DST_CHAIN_ID_ARB_SEPOLIA, deployerAddress);

        // Perform the transfer
        uint256 amountToTransfer = 1 * 1e6; // 10 USDC (assuming 6 decimals)
        uint256 minAmountLD = 0.995 * 1e6; // 9.95 USDC as minimum received (0.5% slippage)

        stargateTransfer.transferToken{value: nativeFee}(
            USDC_OP_SEPOLIA,
            DST_CHAIN_ID_ARB_SEPOLIA,
            SRC_POOL_ID,
            DST_POOL_ID,
            amountToTransfer,
            deployerAddress,
            minAmountLD
        );

        vm.stopBroadcast();
    }
}