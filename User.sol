// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract User{
    address public userWallet;
    string public userName;
    uint256 public userId;
    string public userProfile;

    uint256 totalUser=0;
    
    mapping (uint256=>string) usernames;
    mapping (uint256=>string) profiles;
    mapping (uint256=>address) usersWallets;
    mapping (uint256=>uint256[]) usertoProjectInvested;
    mapping (uint256=>uint256[]) usertoProjectOwned;

    // getter setter kaise chahiye?

    function addUser(string memory userName, string memory profile) external {
        totalUser++;
        userId=totalUser;
        usernames[userId]=userName;
        profiles[userId]=profile;
        usersWallets[userId] = msg.sender;        
    }

    function changeUsername(uint256 Id,string memory newName) external onlyUser {
        require(msg.sender == usersWallets[Id],"can change username");
        usernames[userId]=newName;
    }
    
    function getUsernameById(uint256 userid) view external returns (string memory){
        return usernames[userid];
    }
    
    modifier onlyUser(){
        require(msg.sender==usersWallets[userId]); _;
    }
}