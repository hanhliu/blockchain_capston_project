// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// liquidation check
contract LiquidationCheck{
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    
    // Cấu trúc lưu thông tin khoản vay của người dùng
    struct UserLoan {
        uint256 usdcCollateral;
        uint256 ethDebt;
        uint256 axsDebt;
    }

    mapping(address => UserLoan) public loans;

    uint256 private collateralFactorUSDC = 90;  // 0.9
    uint256 private collateralFactorETH = 80;   // 0.8
    uint256 private collateralFactorAXS = 70;   // 0.7
    uint256 private ethPrice = 1500; // USDC/ETH
    uint256 private axsPrice = 100;  // AXS/ETH

    event Liquidated(address user, uint256 usdcLost, uint ethLiquidated);

    function addLoan() public {

    }

    function getHealthFactor() public {
        
    }

    function liquidate() public {
        
    }
}