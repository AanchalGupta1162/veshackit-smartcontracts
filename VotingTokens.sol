// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
 contract VotingTokens is ERC20 {
   constructor(
        string memory _tokenName,
        string memory _tokenSymbol
   ) ERC20(_tokenName, _tokenSymbol) {

   } 
   function transferTokens(address members, uint256 amount) public {
     _mint(members, amount * (10 ** decimals()));
   }
 }