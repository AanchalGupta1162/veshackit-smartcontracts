// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
 contract VotingTokens is ERC20 {
   constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply
   ) ERC20(_tokenName, _tokenSymbol) {
    _mint(msg.sender, _totalSupply * 10 ** decimals());
   } 

   mapping(address => uint) public balances;
   function transferTokens(address[] memory members) public {
    for (uint i = 0; i < members.length ;i++){
        _mint(members[i], 10 ** decimals());
        balances[members[i]] = balances[members[i]] + 10 ** decimals();
    }
   }

   function transferTokesSingle(address members) public {
    _mint(members, 10 ** decimals());
     balances[members] = balances[members] + 10 ** decimals();
   }

   function burnTokens(address[] memory members,uint256 amount) public{
        for (uint i = 0; i < members.length ;i++){
            _burn(members[i], amount ** decimals());
             balances[members[i]] = balances[members[i]] - amount ** decimals();   
        }
   }

   function checkBalance(address user) public view returns (uint) {
       return balances[user];
    }
 }