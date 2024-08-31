// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStargateRouter.sol";

contract StargateTransfer is Ownable{

    using SafeERC20 for IERC20;

    IStargateRouter public immutable stargateRouter;

    constructor(address _stargateRouter) Ownable(msg.sender) {
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function getFeesQuote(
        uint16 _dstChainId,
        address recipient
    ) public view returns (uint256 nativeFee, uint256 lzFee) {
        IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj({
            dstGasForCall: 200_000,
            dstNativeAmount: 0,
            dstNativeAddr: ""
        });

        bytes memory toAddress = abi.encodePacked(recipient);

        (nativeFee, lzFee) = stargateRouter.quoteLayerZeroFee(
            _dstChainId,
            1, // for Swapping
            toAddress,
            "",  // No payload for simple transfers
            lzTxObj
        );

        return (nativeFee, lzFee);
    }

    function transferToken(
        address token,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint256 amount,
        address recipient,
        uint256 minAmountLD
    ) external payable {
        // Transfer USDC from sender to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Approve Stargate Router to spend USDC
        IERC20(token).approve(address(stargateRouter), amount);

        // Prepare the lzTxObj
        IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj({
            dstGasForCall: 200_000,
            dstNativeAmount: 0,
            dstNativeAddr: ""
        });

        // Encode the recipient address
        bytes memory toAddress = abi.encodePacked(recipient);
    
        // Call Stargate Router's swap function
        stargateRouter.swap{value: msg.value}(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            payable(msg.sender), // refund address
            amount,
            minAmountLD,
            lzTxObj,
            toAddress,
            ""  // no payload
        );
    }

    // Function to withdraw any stuck tokens (including USDC) from the contract
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // Function to withdraw any stuck ETH from the contract
    function withdrawETH() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}
