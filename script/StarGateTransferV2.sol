// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IStargate } from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";

contract StargateTransferScript is Script {
    

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address stargatePoolUSDC =0xc026395860Db2d07ee33e05fE50ed7bD583189C7;
        uint256 destinationEndpointId =40231; //arbitrum
        uint256 amount =1000000; //1 USDC
        address sourceChainPoolToken =0x488327236B65C61A6c083e8d811a4E0D3d1D4268; //USDC
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the StargateTransfer contract
        StargateIntegration integration = new StargateIntegration();

        // as Alice
        IERC20(sourceChainPoolToken).approve(stargatePoolUSDC, amount);

        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
        integration.prepareTakeTaxi(stargatePoolUSDC, destinationEndpointId, amount, deployerAddress);

        IStargate(stargate).sendToken{ value: valueToSend }(sendParam, messagingFee, deployerAddress);

        vm.stopBroadcast();
    }
}