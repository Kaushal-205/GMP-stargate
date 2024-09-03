// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IStargate } from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";

contract StargateTransferScript is Script {
    

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the StargateTransfer contract
        StargateIntegration integration = new StargateIntegration();

        // as Alice
        ERC20(sourceChainPoolToken).approve(stargate, amount);

        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
        integration.prepareTakeTaxi(stargate, destinationEndpointId, amount, deployerAddress);

        IStargate(stargate).sendToken{ value: valueToSend }(sendParam, messagingFee, deployerAddress);

        vm.stopBroadcast();
    }
}