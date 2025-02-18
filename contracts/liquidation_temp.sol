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

    // Tính toán lượng tài sản cần thanh lý để đạt HF = 1
    function calculateLiquidationAmount(address _borrower, string memory assetType) public view returns (uint256 usdcToLiquidate, uint256 assetToLiquidate) {
        Loan memory loan = loans[_borrower];
        uint256 totalCollateral = loan.usdcCollateral;
        uint256 ethDebt = loan.ethDebt;
        uint256 axsDebt = loan.axsDebt;

        uint256 totalDebtUSDC = ethDebt * ethPriceOnUSDC + (axsDebt * axsToETHPrice * ethPriceOnUSDC) / 1e6;
        
        // Tính tổng nợ cần đạt được để HF = 1
        uint256 targetDebtUSDC = (totalCollateral * collateralRatioUSDC) / 100;

        if (totalDebtUSDC <= targetDebtUSDC) {
            return (0, 0); // Không cần thanh lý
        }

        uint256 excessDebt = totalDebtUSDC - targetDebtUSDC;

        if (keccak256(bytes(assetType)) == keccak256(bytes("ETH"))) {
            assetToLiquidate = (excessDebt * 1e6) / ethPriceOnUSDC; // ETH là 1e6 để xử lý thập phân
            usdcToLiquidate = (assetToLiquidate * ethPriceOnUSDC) / 1e6;
        } else if (keccak256(bytes(assetType)) == keccak256(bytes("AXS"))) {
            uint256 axsInETH = (excessDebt * 1e6) / (axsToETHPrice * ethPriceOnUSDC);
            assetToLiquidate = axsInETH; // Tính theo số lượng AXS cần thanh lý
            usdcToLiquidate = (assetToLiquidate * axsToETHPrice * ethPriceOnUSDC) / 1e6;
        } else {
            revert("Invalid asset type: Use 'ETH' or 'AXS'");
        }
    }

    // Thực hiện thanh lý
    function liquidate(address _borrower, string memory assetType, uint256 newUSDCPrice) public {
        require(getHealthFactor(_borrower) < 100, "Loan is still healthy");

        Loan storage loan = loans[_borrower];
        uint256 ethToLiquidate;
        uint256 usdcLost;

        if (keccak256(bytes(assetType)) == keccak256(bytes("ETH"))) {
            uint256 path_1 = (loan.ethDebt * ethPriceOnUSDC) / 10 + 
                            (loan.axsDebt * axsToETHPrice * ethPriceOnUSDC) / 10000 - 
                            (collateralRatioUSDC * loan.usdcCollateral) / 100;
            uint256 path_2 = ethPriceOnUSDC - (collateralRatioUSDC * newUSDCPrice) / 100;
            ethToLiquidate = (path_1 * 100) / path_2;
            usdcLost = (ethToLiquidate * newUSDCPrice) / 1000;
        } else {
            ethToLiquidate = loan.ethDebt / 2; // Giả sử liquidator thanh lý một phần ETH
            usdcLost = ethToLiquidate * newUSDCPrice;  // Tỷ giá USDC/ETH khi thanh lý
        }

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
