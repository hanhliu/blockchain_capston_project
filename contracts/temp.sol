// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Liquidation {
    address public owner;
    
    // Cấu trúc lưu thông tin khoản vay của người dùng
    struct Loan {
        uint256 usdcCollateral;
        uint256 ethDebt;
        uint256 axsDebt;
    }

    mapping(address => Loan) public loans;

    uint256 public collateralFactorUSDC = 90;  // 0.9
    uint256 public collateralFactorETH = 80;   // 0.8
    uint256 public collateralFactorAXS = 70;   // 0.7

    uint256 public ethPrice = 1500; // USDC/ETH
    uint256 public axsPrice = 100;  // AXS/ETH

    event Liquidated(address user, uint256 usdcLost, uint256 ethLiquidated);

    constructor() {
        owner = msg.sender;
    }

    function addLoan(address _borrower, uint256 _usdcCollateral, uint256 _ethDebt, uint256 _axsDebt) public {
        require(msg.sender == owner, "Only owner can add loans");
        loans[_borrower] = Loan(_usdcCollateral, _ethDebt, _axsDebt);
    }

    function getHealthFactor(address _borrower) public view returns (uint256) {
        Loan memory loan = loans[_borrower];

        uint256 totalCollateral = (loan.usdcCollateral * collateralFactorUSDC) / 100;
        uint256 totalDebt = (loan.ethDebt * ethPrice) + (loan.axsDebt * axsPrice);

        if (totalDebt == 0) {
            return type(uint256).max; // Tránh chia cho 0
        }
        return (totalCollateral * 100) / totalDebt;
    }

    function liquidate(address _borrower) public {
        require(getHealthFactor(_borrower) < 100, "Loan is still healthy");

        Loan storage loan = loans[_borrower];

        uint256 ethToLiquidate = loan.ethDebt / 2; // Giả sử liquidator thanh lý một phần ETH
        uint256 usdcLost = ethToLiquidate * 1520;  // Tỷ giá USDC/ETH khi thanh lý

        require(loan.usdcCollateral >= usdcLost, "Not enough collateral to liquidate");

        loan.usdcCollateral -= usdcLost;
        loan.ethDebt -= ethToLiquidate;

        emit Liquidated(_borrower, usdcLost, ethToLiquidate);
    }
}
