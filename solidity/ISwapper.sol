// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >0.8.0 <0.9.0;


interface ISwapper { 
    
 function swap(address _erc20a, address _erc20b, address recipient,  uint256 minTo, uint256 maxFrom )  external returns (uint256 _amountErc20b);
    
}