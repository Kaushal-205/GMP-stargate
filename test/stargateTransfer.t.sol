// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/stargateTransfer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStargateRouter is IStargateRouter {
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable override {}

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view override returns (uint256, uint256) {
        return (0.01 ether, 0.001 ether); // Mock fees
    }
}

contract MockToken is ERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
}

contract StargateTransferTest is Test {
    StargateTransfer public stargateTransfer;
    MockStargateRouter public mockRouter;
    MockToken public mockToken;
    address public user;
    address public recipient;

    uint16 constant DST_CHAIN_ID = 110; // Example destination chain ID
    uint256 constant SRC_POOL_ID = 1;
    uint256 constant DST_POOL_ID = 1;

    function setUp() public {
        mockRouter = new MockStargateRouter();
        stargateTransfer = new StargateTransfer(address(mockRouter));
        mockToken = new MockToken();
        
        user = address(0x1);
        recipient = address(0x2);
        
        vm.label(user, "User");
        vm.label(recipient, "Recipient");
        vm.label(address(mockRouter), "Stargate Router");
        vm.label(address(mockToken), "Mock Token");
    }

    function testGetFeesQuote() public {
        (uint256 nativeFee, uint256 lzFee) = stargateTransfer.getFeesQuote(DST_CHAIN_ID, recipient);
        
        assertEq(nativeFee, 0.01 ether, "Native fee should be 0.01 ETH");
        assertEq(lzFee, 0.001 ether, "LZ fee should be 0.001 ETH");
    }

    function testTransferToken() public {
        uint256 transferAmount = 1000 * 1e6; // 1000 USDC
        uint256 minAmountLD = 995 * 1e6; // 0.5% slippage
        
        // Mint tokens to user
        mockToken.mint(user, transferAmount);
        
        // Approve token spend
        vm.prank(user);
        mockToken.approve(address(stargateTransfer), transferAmount);
        
        // Get fee quote
        (uint256 nativeFee, ) = stargateTransfer.getFeesQuote(DST_CHAIN_ID, recipient);
        
        // Perform transfer
        vm.prank(user);
        vm.deal(user, nativeFee); // Ensure user has enough ETH for fees
        stargateTransfer.transferToken{value: nativeFee}(
            address(mockToken),
            DST_CHAIN_ID,
            SRC_POOL_ID,
            DST_POOL_ID,
            transferAmount,
            recipient,
            minAmountLD
        );
        
        // Assert token has been transferred from user to contract
        assertEq(mockToken.balanceOf(user), 0, "User should have 0 tokens after transfer");
        assertEq(mockToken.balanceOf(address(stargateTransfer)), transferAmount, "Contract should hold transferred tokens");
    }

    function testWithdrawToken() public {
        uint256 amount = 1000 * 1e6; // 1000 USDC
        mockToken.mint(address(stargateTransfer), amount);
        
        uint256 initialBalance = mockToken.balanceOf(address(this));
        
        stargateTransfer.withdrawToken(address(mockToken), amount);
        
        uint256 finalBalance = mockToken.balanceOf(address(this));
        assertEq(finalBalance - initialBalance, amount, "Token withdrawal failed");
    }

    function testWithdrawETH() public {
        uint256 amount = 1 ether;
        vm.deal(address(stargateTransfer), amount);
        
        uint256 initialBalance = address(this).balance;
        
        stargateTransfer.withdrawETH();
        
        uint256 finalBalance = address(this).balance;
        assertEq(finalBalance - initialBalance, amount, "ETH withdrawal failed");
    }

    function testOnlyOwnerWithdrawal() public {
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        stargateTransfer.withdrawToken(address(mockToken), 1000);

        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        stargateTransfer.withdrawETH();
    }

    receive() external payable {}
}