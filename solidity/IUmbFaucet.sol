// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.0 <0.9.0;

interface IUmbFaucet { 
    
    function topUp(uint256 [] memory _minFees, string [] memory _erc20Names) external returns (uint256 _amountToppedUp);
} 