// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >0.8.0 <0.9.0; 


contract UBReferenceData { 
  
  
  string chainCurrencyName; 
  address chainCurrencyAddress; 
  
  mapping(string=>bool)allowedBaseStatusByName; 
  mapping(string=>bool)allowedQuoteStatusByName;
  mapping(string=>address) erc20AddressByName; 
  
  address sysAdmin; 
  
  constructor(address _sysAdmin, string memory _chainCurrencyName ){
      sysAdmin = _sysAdmin;
      chainCurrencyName = _chainCurrencyName; 
      chainCurrencyAddress = address(0x6c49b00761B020B676B07ABd045048e00eb9CD5a);
      erc20AddressByName[chainCurrencyName] = chainCurrencyAddress;
      
      // NOTE: accounts can't be denominated in chain currency
      allowedBaseStatusByName[chainCurrencyName] = true; 
  }
  
  function isSupported(string memory _currencyName) external view returns (bool)  {
      return allowedBaseStatusByName[_currencyName];
  }
   
  function isDenominationAllowed(string memory _currencyName) external view returns (bool)  {
      return allowedQuoteStatusByName[_currencyName];
  }

  function getERC20Address(string memory _erc20) external view returns (address _erc20Address) {
      return erc20AddressByName[_erc20];
  }
  

  function getChainCurrencyName() external view returns (string memory _name) {
      return chainCurrencyName; 
  }

  function getChainCurrencyAddress() external view returns (address _chainCurrencyAddress) {
      return chainCurrencyAddress;
  }

  function addERC20Address(address _erc20, string memory _erc20Name, string memory _type) external returns (bool _added) {
      require(msg.sender == sysAdmin, "00 - unauthorized access ");
      erc20AddressByName[_erc20Name] = _erc20;
      if(isEqual(_type ,"base")) {
          allowedBaseStatusByName[_erc20Name] = true; 
      }
      
      if(isEqual(_type, "quote")) {
          allowedQuoteStatusByName[_erc20Name] = true; 
      }
      return true; 
  }
  
  function isEqual(string memory a, string memory b) public pure returns (bool _isEqual) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

} 