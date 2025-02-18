// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Liquidation {

    address public owner;

    struct Loan {
        uint256 usdcCollateral;
        uint256 ethDebt;
        uint256 axsDebt;
    }

    mapping(address => Loan) public loans;

    uint256 public collateralRatioUSDC = 90;
    uint256 public collateralRatioETH = 80;
    uint256 public collateralRatioAXS = 70;

    uint256 public ethPriceOnUSDC = 1500; // 1 ETH = 1500 USDC
    uint256 public axsToETHPrice = 100;  // 1 AXS = 0.01 ETH

    event Liquidated(address user, uint256 usdcLost, uint256 ethLiquidated);

    event HealthFactorCalculated(address borrower,uint256 totalCollateral,uint256 totalDebtOnUSDC, uint256 healthFactor);

    constructor() {
        owner = msg.sender;
    }

    function addLoan(address _borrower, uint256 _usdcCollateral, uint256 _ethDebt, uint256 _axsDebt) public {
        require(msg.sender == owner, "Only owner can add loans");
        loans[_borrower] = Loan(_usdcCollateral, _ethDebt, _axsDebt);
    }

    function getHealthFactor(address _borrower) public returns (uint256) {
        Loan memory loan = loans[_borrower];

        // Tính tổng tài sản thế chấp (đã nhân với tỷ lệ thế chấp)
        uint256 totalCollateral = (loan.usdcCollateral * collateralRatioUSDC) / 100;

        // Tính tổng nợ quy về USDC
        uint256 ethDebtInUSDC = (loan.ethDebt * ethPriceOnUSDC) / 10; // Vì bạn nhập 0.2 ETH dưới dạng 2
        uint256 axsDebtInUSDC = (loan.axsDebt * axsToETHPrice * ethPriceOnUSDC) / 10000;
        uint256 totalDebt = ethDebtInUSDC + axsDebtInUSDC;

        if (totalDebt == 0) {
            return type(uint256).max; // Tránh chia cho 0
        }

        // Tính Health Factor
        uint256 healthFactor = (totalCollateral * 100) / totalDebt;

        // Log sự kiện để kiểm tra
        emit HealthFactorCalculated(_borrower, totalCollateral, totalDebt, healthFactor);

        return healthFactor;
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

    function changeETHRate(uint256 _ethPrice) public {
        ethPriceOnUSDC = _ethPrice;
    }

    function changeAXSRate(uint256 _axsPrice) public {
        axsToETHPrice = _axsPrice;
    }
}   
