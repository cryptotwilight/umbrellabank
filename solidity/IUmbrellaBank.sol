// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.7.0 <0.9.0;


interface IUmbrellaBank {
    
    function addSupport(string memory erc20name) external returns (bool _supported);
    
    function deposit(string memory _ref, uint256 _amount) external payable returns (uint256 _txnRef);
    
    function depositERC20(string memory _ref, uint256 _amount, string memory _erc20Name) external payable returns (uint256 _txnRef);
        
    function withdraw(string memory _ref, uint256 _amount, address _recipient) external returns (uint256 _amt, uint256 _dAmount, uint256 _txnRef);
    
    function withdrawERC20(string memory _ref, uint256 _amount, string memory _erc20Name, address _recipient) external returns (uint256 _amt, uint256 _dAmount, uint256 _txnRef);
    
    function getUBBalance() external returns (uint256 _totalBalance, string memory _currency, string [] memory  _breakDownCurrency, uint256 [] memory _balances, uint256 [] memory _dBalances);
    
    function getUBDenomination() external view returns (string memory _currency);

}