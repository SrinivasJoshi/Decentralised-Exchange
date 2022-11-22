// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{
    address public cryptoDevTokenAddress;

    constructor(address _CryptoDevToken)ERC20("CryptoDev LP Token","CDLP"){
        require(_CryptoDevToken!=address(0),"Token address passed is null");
        cryptoDevTokenAddress = _CryptoDevToken;
    }

    function getReserve() public view returns(uint){
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns(uint){
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        //if reserve is empty
        if(cryptoDevTokenReserve == 0){
            // Transfer the `cryptoDevToken` from the user's account to the contract
            cryptoDevToken.transferFrom(msg.sender,address(this),_amount);
            // Take the current ethBalance and mint `ethBalance` amount of LP tokens to the user.
            liquidity = ethBalance;
            //send LP token to liquidity provider
            _mint(msg.sender,liquidity);
        }
        else{
            uint ethReserve = ethBalance - msg.value;
            // Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract);
            // So doing some maths, (cryptoDevTokenAmount user can add) = (Eth Sent by the user * cryptoDevTokenReserve /Eth Reserve);
            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/(ethReserve);
            require(_amount >= cryptoDevTokenAmount,"CryptoDevToken sent is less than required");
            cryptoDevToken.transferFrom(msg.sender,address(this),cryptoDevTokenAmount);
            // (LP tokens to be sent to the user (liquidity)/ totalSupply of LP tokens in contract) = (Eth sent by the user)/(Eth reserve in the contract)
            // by some maths -> liquidity =  (totalSupply of LP tokens in contract * (Eth sent by the user))/(Eth reserve in the contract)
            liquidity = (totalSupply()*msg.value)/(ethReserve);
            _mint(msg.sender,liquidity);
        }
        return liquidity;
    }

    function removeLiquidity(uint _amount) public returns (uint,uint) {
        // FORMULA : (Eth sent back to the user) / (current Eth reserve) = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens).
        require(_amount > 0,"_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint ethAmount = (ethReserve*_amount)/(_totalSupply);
        uint cryptoDevTokenAmount = (getReserve()*_amount)/(_totalSupply);
        _burn(msg.sender,_amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(cryptoDevTokenAddress).transfer(msg.sender,cryptoDevTokenAmount);
        return(ethAmount,cryptoDevTokenAmount);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns(uint256) {
        // We need to make sure (x + Δx) * (y - Δy) = x * y 
        // So the final formula is Δy = (y * Δx) / (x + Δx)
        require(inputReserve >0 && outputReserve >0,"invalid reserves");
        uint256 inputAmountWithFee = inputAmount*99;
        uint256 numerator = inputAmountWithFee*outputReserve;
        uint256 denominator = (inputReserve*100) + inputAmountWithFee;
        return numerator/denominator;
    }

    function ethToCryptoDevToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance-msg.value,
            tokenReserve);
        require(tokensBought >= _minTokens,"insufficient output amount");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender,tokensBought);
    }

    function cryptoDevTokenToEth(uint _tokensSold, uint _minTokens) public{
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minTokens,"insufficient output amount");
        ERC20(cryptoDevTokenAddress).transferFrom(msg.sender,address(this),_tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

}