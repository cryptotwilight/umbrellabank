// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.0 <0.9.0;

import "./IUmbrellaBank.sol";
import "./UBReferenceData.sol";
import "./Umbrella.sol";
import "./IUmbFaucet.sol";
import "./ISwapper.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/sushiswap/kashi-lending/blob/5b52fd8b2471bf3f44b240bd3c650969d8d95ef1/contracts/flat/SushiSwapSwapperFlat.sol";

contract UmbrellaBank is IUmbrellaBank, IUmbFaucet { 
    
    address self; 
    
    address bankHolder; 
    uint256 ubBalance; 
    
    struct Denomination {
        address currencyAddress; 
        string name; 
        IERC20 erc20; 
    }
    
    struct Txn { 
        uint256 time; 
        uint256 amount; 
        string ref; 
        string erc20name;
        uint256 txnId; 
        address txnPoint; // payer or payee
        string txnType; 
        uint256 denominatedAmount; 
    }


    Denomination denomination; 
    Umbrella umbrella;  
    IERC20 umbrellaToken; 
    UBReferenceData referenceData; 
    ISwapper swapper;
    
    mapping(string=>bool) allowedDenominationStatusByName; 
    mapping(address=>uint256) erc20BalanceByERC20Address;
    
    mapping(string=>bool) supportedERC20StatusByName; 
    
    mapping(string=>IERC20) supportedERC20ByName; 
    
    mapping(string=>uint256) balanceByERC20Name;
    
    Txn [] txns; 
    
    string [] supportedCurrencies; 
    
    constructor(address _bankHolder, 
                address _refrenceData, 
                address _umbrellaAddress,
                address _umTokenAddress, 
                address _swapAddress, 
                string memory _denominationName, 
                uint256 _openingBalance) payable { 
        
        bankHolder = _bankHolder; 
        umbrella = Umbrella(_umbrellaAddress);
        referenceData = UBReferenceData(_refrenceData);
        
        umbrellaToken = IERC20(_umTokenAddress);
        swapper = ISwapper(_swapAddress);
        
        require(referenceData.isDenominationAllowed(_denominationName), "00 - unknown denomination.");
        // set the denomination
        IERC20 erc20_ = IERC20(referenceData.getERC20Address(_denominationName));
        denomination = Denomination({
                                     currencyAddress : referenceData.getERC20Address(_denominationName),
                                     name : _denominationName, 
                                     erc20 : erc20_
                                    });
     
        // transfer the opening balance 
        require(ubTransferIn(_openingBalance), "01 - unable to credit opening balance");
        self = address(this);
    }
    
    function ubTransferIn(uint256 _amount) internal returns (bool _transferred) { 
        if(_amount > 0){
            if(isEqual(denomination.name,"ETH")) {
                ubBalance += _amount; 
                return true; 
            }
            denomination.erc20.transferFrom(msg.sender, address(this), _amount);
            return true; 
        }
        return true; 
    } 
    
    
    function addSupport(string memory _erc20Name) override external returns (bool _supported){
        require(referenceData.isSupported(_erc20Name), "01 - unsupported erc20 ");
        supportedERC20ByName[_erc20Name] = IERC20(referenceData.getERC20Address(_erc20Name));
        supportedCurrencies.push(_erc20Name);
        return true; 
    }
    
    function deposit(string memory _ref, uint256 _amount) override external payable returns (uint256 _txnRef){
        string memory chainCurrencyName = referenceData.getChainCurrencyName();
       
        uint256 denominatedAmount_ = umbrella.getExchangeRate(chainCurrencyName, denomination.name) * _amount;
       
        Txn memory txn = Txn({
                time : block.timestamp,
                amount : _amount, 
                ref : _ref, 
                erc20name : chainCurrencyName,
                txnId : generateTxnId(), 
                txnPoint : msg.sender, 
                txnType : "deposit",
                denominatedAmount : denominatedAmount_             
        });
        
        ubBalance += denominatedAmount_; 
        
        txns.push(txn);
        return txn.txnId; 
    }
    
    function depositERC20(string memory _ref, uint256 _amount, string memory _erc20Name) override external payable returns (uint256 _txnRef){
        require(referenceData.isSupported(_erc20Name), "01 - unsupported erc20 ");

        IERC20 erc20 = supportedERC20ByName[_erc20Name];
        
        erc20.transferFrom(msg.sender, self, _amount);
        
        uint256 denominatedAmount_ = umbrella.getExchangeRate(_erc20Name, denomination.name) * _amount;
        
        Txn memory txn = Txn({
                time : block.timestamp,
                amount : _amount, 
                ref : _ref, 
                erc20name : _erc20Name,
                txnId : generateTxnId(), 
                txnPoint : msg.sender, 
                txnType : "deposit",
                denominatedAmount : denominatedAmount_             
        });
        
        ubBalance += denominatedAmount_; 

        txns.push(txn);
        return txn.txnId; 
    }
        
    function withdraw(string memory _ref, uint256 _amount, address _recipient) override external returns (uint256 _amt, uint256 denominatedAmount_,  uint256 _txnRef){
        require(msg.sender == bankHolder, "00 - unauthorized access ");
        require(self.balance >= _amount, "01 - insufficient balance ");
        string memory chainCurrencyName = referenceData.getChainCurrencyName();

        denominatedAmount_ = umbrella.getExchangeRate(chainCurrencyName, denomination.name) * _amount;
        
        Txn memory txn = Txn({
                time : block.timestamp,
                amount : _amount, 
                ref : _ref, 
                erc20name : chainCurrencyName,
                txnId : generateTxnId(), 
                txnPoint : _recipient, 
                txnType : "withdraw",
                denominatedAmount : denominatedAmount_             
        });
        
        ubBalance -= denominatedAmount_; 
        
        txns.push(txn);
        return (_amount, denominatedAmount_, txn.txnId); 
    }
    
    function withdrawERC20(string memory _ref, uint256 _amount, string memory _erc20Name, address _recipient) override external returns (uint256 _amt,  uint256 denominatedAmount_, uint256 _txnRef){
        require(msg.sender == bankHolder, "00 - unauthorized access ");
        
        IERC20 erc20 = supportedERC20ByName[_erc20Name];

        require(erc20.balanceOf(self) >= _amount, "01 - insufficient balance ");
        
        denominatedAmount_ = umbrella.getExchangeRate(_erc20Name, denomination.name) * _amount;
        
        erc20.transfer(_recipient, _amount);
        
        Txn memory txn = Txn({
                time : block.timestamp,
                amount : _amount, 
                ref : _ref, 
                erc20name : _erc20Name,
                txnId : generateTxnId(), 
                txnPoint : _recipient, 
                txnType : "withdraw",
                denominatedAmount : denominatedAmount_             
        });
        
        ubBalance -= denominatedAmount_;
        
        txns.push(txn);
        return  (_amount, denominatedAmount_, txn.txnId); 
    }
    
    
    function getUBBalance() external override view returns (uint256 _totalBalance, string memory _currency, string [] memory  _breakDownCurrency, uint256 [] memory _balances, uint256 [] memory _dBalances){
        uint256 [] memory balances = new uint256[](supportedCurrencies.length);
        uint256 [] memory dBalances =  new uint256[](supportedCurrencies.length);
        for(uint x = 0 ; x < supportedCurrencies.length; x++) {
            balances[x] = supportedERC20ByName[supportedCurrencies[x]].balanceOf(self);
            dBalances[x] = umbrella.getExchangeRate(supportedCurrencies[x], denomination.name) * balances[x];
        }
        return (ubBalance, denomination.name, supportedCurrencies, balances, dBalances);
    }
    
    
    
    function getUBDenomination() override  external view returns (string memory _currency){
        return denomination.name; 
    }
    
    
    function topUp(uint256 [] memory _minFees, string [] memory _erc20Names) override external returns (uint256 _amountToppedUp){
        for(uint256 x = 0; x < _erc20Names.length; x++ ) {
            IERC20 erc20 = supportedERC20ByName[_erc20Names[x]];
            uint256 minFee = _minFees[x];
            uint256 erc20Balance = erc20.balanceOf(self);
            if(erc20Balance > minFee) {
                erc20.approve(address(swapper), minFee);
                swapper.swap(address(erc20), address(umbrellaToken), self,  minFee, erc20Balance );
                return minFee; 
            }
        }
    }
    
    function generateTxnId() internal view returns (uint256 _txnId) {
        return block.timestamp; 
    }
    
    function isEqual(string memory a, string memory b) public pure returns (bool _isEqual) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}