// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
 contract VotingTokens is ERC20 {
   constructor(
        string memory _tokenName,
        string memory _tokenSymbol
     //    uint256 _totalSupply
   ) ERC20(_tokenName, _tokenSymbol) {

   } 

   //mapping(address => uint) public balances;
   function transferTokens(address members, uint256 amount) public {
    
        _mint(members, amount * (10 ** decimals()));
    
   }

//    function transferTokesSingle(address members) public {
//     _mint(members, 10 ** decimals());
//      balances[members] = balances[members] + 10 ** decimals();
//    }

//    function burnTokens(address members,uint256 amount) public{
//             _burn(members, amount ** decimals());
//              balances[members] = balances[members] - amount ** decimals();   
//    }

 }