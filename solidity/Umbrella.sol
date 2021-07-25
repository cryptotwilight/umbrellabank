// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.0 <=0.9.0; 

import "@umb-network/toolbox/dist/contracts/IChain.sol";
import "@umb-network/toolbox/dist/contracts/lib/ValueDecoder.sol";
import "@umb-network/toolbox/dist/contracts/IRegistry.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./IUmbFaucet.sol";

contract Umbrella { 
    
    string [] marketsL2 = [ "ADA-USDT",
                            "XRP-USDT",
                            "DOT-USDT",
                            "LTC-USDT",
                            "BUSD-USDT",
                            "EOS-USDT",
                            "TRX-USDT",
                            "IOST-USDT",
                            "XLM-USDT",
                            "DOGE-USDT",
                            "ATOM-USDT",
                            "ZEC-USDT",
                            "ETC-USDT",
                            "NEO-USDT",
                            "SRM-USDT",
                            "BSV-USDT",
                            "USDC-USDT",
                            "DASH-USDT",
                            "SOL-USDT",
                            "ONT-USDT",
                            "HT-USDT",
                            "FTM-USDT",
                            "SUSHI-USDT",
                            "BTT-USDT",
                            "VET-USDT",
                            "ZDEX-USDT",
                            "ETH-BTC",
                            "BNB-BTC",
                            "ADA-BTC",
                            "XRP-BTC",
                            "LTC-BTC",
                            "XEM-BTC",
                            "DOT-BTC",
                            "BCH-BTC",
                            "BNB-BUSD",
                            "BTC-USDC",
                            "DAI-BNB" ]; 

    mapping(string=>bool) supportedMarketStatusByName; 
    address self; 
    IERC20 umbToken; 
    IRegistry registry; 
    uint256 minUmbTokens; 
    
    address sysAdmin;

    
    mapping(string=>uint256) minFeeByErc20Name; 
    
    string [] erc20Names; 

    constructor(address _sysAdmin, address _umbRegistryAddress, address _umbTokenAddress, uint256 _minUmTokens) {
        sysAdmin        = _sysAdmin; 
        loadL2Markets(); 
        registry        = IRegistry(_umbRegistryAddress);
        umbToken        = IERC20(_umbTokenAddress);
        minUmbTokens    = _minUmTokens; 
        self = address(this);
    }
    

    function getExchangeRate(string memory _base, string memory _quote) external returns (uint256 _rate) {
        // if you don't have any money then you need to top up 
        if(umbToken.balanceOf(msg.sender) < minUmbTokens ) {
            IUmbFaucet faucet = IUmbFaucet(msg.sender);
            uint256 [] memory _fees;
            string [] memory _erc20Names;
            (_fees, _erc20Names) = this.getMinFees();
            
            faucet.topUp(_fees, _erc20Names); 
        }
        
        umbToken.transferFrom(msg.sender, self, minUmbTokens);
        
        string memory market_ = createMarket(_base, _quote);
        require(supportedMarketStatusByName[market_], "00 - unsupported L2 market");
        
        bytes32  key_ = convert(market_);
        uint256 ts; 
        (_rate, ts) = _chain().getCurrentValue(key_);
        
        return _rate; 
        
    }
    
    
    function getMinFees() external returns (uint256 [] memory _minFee, string [] memory _erc20Name) {
        
    }
    
    function loadL2Markets() internal  {
        for(uint x = 0; x < marketsL2.length; x++) {
            supportedMarketStatusByName[marketsL2[x]] = true; 
        }
    }
    
    function createMarket(string memory _base, string memory _quote) internal pure returns (string memory _market) {
        return string(abi.encodePacked(_base, "-", _quote));
    }
    
    function _chain() internal view returns (IChain umbChain) {
        umbChain = IChain(registry.getAddress("Chain"));
    }
    
    function convert(string memory _market) internal pure returns (bytes32 _key){
        assembly {
            _key := mload(add(_market, 32))
        }
        return _key;     
    }
} 