// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import {VotingTokens} from "VotingTokens.sol";


contract Project is Ownable {
    uint256 public id;
    string public name;
    address public immutable founder;
    uint256 public immutable budget;
    uint256 public immutable duration;
    uint256 public immutable investmentLimit;
    uint256 public immutable daoLimit;
    uint256 public currentInvestedAmount;
    uint256 public daoId = 0;
    address public tokenAddress;
    uint256 public totalTokens;

    uint public totalProposals = 0;
    uint public totalUser = 0;
    address[] public users;
    bool public isDaoCreated=false;

    event investmentMade(
        uint256 indexed userId,
        string userName,
        address userWallet,
        uint256 investedAmount
    );
    event DAOCreated(
        uint256 indexed daoId,
        string daoName,
        address creatorWallet
    );
    event ProposalCreated(
        uint256 indexed proposalId,
        uint256 daoId,
        address proposerWallet
    );
    event MemberAddedToDAO(
        uint256 indexed daoId,
        uint256 userId,
        address userWallet
    );
    event UserCreated(
        uint256 indexed userId,
        string userName,
        address userWallet
    );
    event ProposalCreated(
        address indexed ProjectAddress, 
        uint256 daoId, 
        address indexed investor
    );
    event QVVoteCast(
        uint256 indexed proposalId,
        uint256 userId,
        uint256 numTokens,
        bool voteChoice
    );
    event ResultCalculated(
        uint256 indexed proposalId,
        uint256 userId,
        bool result
    );
    // Add an event for fund withdrawal
    event FundsWithdrawn(
        uint256 indexed proposalId,
        uint256 amountWithdrawn,
        address indexed owner
    );
    constructor(
        uint256 _id,
        string memory _name,
        address _founder,
        uint256 _budget,
        uint256 _duration,
        uint256 _investmentLimit,
        uint256 _daoLimit
    ) Ownable(_founder) {
        id = _id;
        name = _name;
        founder = _founder;
        budget = _budget;
        duration = _duration;
        investmentLimit = _investmentLimit;
        daoLimit = _daoLimit;
    }

    struct dao {
        uint256 project_id;
        string daoName;
        string daoDescription;
        uint256 MembersCount;
        address creator;
        address[] members;
    }

    struct proposal {
        uint256 proposalId;
        uint256 proposerId;
        string proposalTitleAndDesc;
        uint256 votingThreshold;
        uint256 fundsNeeded;
        uint256 beginningTime;
        uint256 daoId;
        uint256 endingTime;
        bool voteOnce;
    }


    mapping(uint256 => string) public userIdtoUser;
    mapping(address => uint256) public userWallettoUserId;
    mapping(uint256 => dao) public daoIdtoDao;
    mapping(uint256 => proposal) public proposalIdtoProposal;
    mapping(uint256 => uint256[]) public daoIdtoMembers;
    mapping(uint256 => uint256[]) public daoIdtoProposals;
    mapping(uint256 => uint256[]) public proposalIdtoVoters;
    //mapping(uint256 => uint256[]) public proposalIdtoYesVoters;
    // mapping(uint256 => uint256[]) public proposalIdtoNoVoters;
    mapping(uint256 => uint256[]) public userIdtoDaos;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticYesMappings;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticNoMappings;
    mapping(address=>uint256) public userWallettoAmtInvested;
    mapping (uint256 => bool) public proposalIdToResult;
    mapping (uint256 => bool) public proposalToResultCalculated;

    
    function invest(string memory userName) public payable {
        require(msg.value >= investmentLimit && currentInvestedAmount + msg.value <= budget, "Investment does not meet the minimum investment limit or it exceeds project budget limit");
        address userWallet = msg.sender;
        //If user has never invested before, create new user and check investment limit
        if(userWallettoUserId[userWallet] == 0){
            createUser(userName,userWallet);
            //emit user creation
            emit UserCreated(totalUser,userName,userWallet);
        }

        currentInvestedAmount += msg.value;

        if(isDaoCreated==true){
            addUsertoDao(userWallet);
        }

        //update mapping of userWallet to totalAmountInvested
        if(userWallettoAmtInvested[userWallet]!=0)
            userWallettoAmtInvested[userWallet]+=msg.value;
        else{
            //sendNFT(userWallet,msg.value);
            userWallettoAmtInvested[userWallet]=msg.value;
        } 

        //emit invested amount
        emit investmentMade(totalUser, userName, userWallet,msg.value);
    }

    function createUser(string memory _name, address userWallet) public {
        //require(userWallettoUserId[userWallet] == 0, "User already exists");
        totalUser++;
        userIdtoUser[totalUser] = _name;
        userWallettoUserId[userWallet] = totalUser;
    }

    //createDao, add investors, dao can be created only once, only owner can create dao, dao can be created after the dao limit
    function createDao(
        string memory daoName, 
        string memory daoDescription, 
        uint256 amountTokens, 
        string memory tokenName, 
        string memory tokenSymbol) public onlyOwner{
        require(currentInvestedAmount > daoLimit && isDaoCreated == false, "DAO limit not reached or dao already created");

        dao memory newDao = dao({
            project_id: id,
            daoName: daoName,
            daoDescription: daoDescription,
            MembersCount: totalUser,
            creator: founder,
            members: users
        });
        daoIdtoDao[++daoId] = newDao;
        totalUser++;

        VotingTokens vt = new VotingTokens(tokenName, tokenSymbol);
        tokenAddress = address(vt);
        totalTokens = amountTokens;
        for(uint i=0;i<totalUser;i++){
            vt.transferTokens(users[i], amountTokens);
        }

        // Emit an event for DAO creation
        emit DAOCreated(daoId, daoName, founder);
        
    }


    function addUsertoDao(address userWallet) internal {

        uint256 userId = userWallettoUserId[userWallet];
        daoIdtoMembers[daoId].push(userId);
        daoIdtoDao[daoId].MembersCount++;
        userIdtoDaos[userId].push(daoId);
        VotingTokens vt = VotingTokens(tokenAddress);
        vt.transferTokens(userWallet, totalTokens);

        // Emit an event for adding a user to the DAO
        emit MemberAddedToDAO(daoId, userId, userWallet);
        
    }


    function createProposal(
        string memory proposalTitleAndDesc,
        uint256 votingThreshold,
        uint256 fundsNeeded,
        uint256 beginningTime,
        uint256 endingTime,
        bool voteOnce
    ) public onlyOwner {
        totalProposals++;
        uint256 proposerId = userWallettoUserId[msg.sender];

        proposal memory newProposal = proposal({
            proposalId: totalProposals,
            proposerId: proposerId,
            proposalTitleAndDesc: proposalTitleAndDesc,
            votingThreshold: votingThreshold * 1000000000000000000,
            fundsNeeded: fundsNeeded * 1000000000000000000,
            beginningTime: beginningTime,
            daoId: daoId,
            endingTime: endingTime,
            voteOnce: voteOnce
        });
        proposalIdtoProposal[totalProposals] = newProposal;
        daoIdtoProposals[daoId].push(totalProposals);

        emit ProposalCreated(address(this), daoId, msg.sender);
    }

    function castVote(uint _proposalId, uint numTokens, bool _vote) external {

        VotingTokens vt = VotingTokens(tokenAddress);
        address funcCaller = msg.sender;
        numTokens = numTokens  * 1000000000000000000;
        uint256 userId = userWallettoUserId[funcCaller]; // Assumes mapping exists
        uint256 tempDaoId = proposalIdtoProposal[_proposalId].daoId;
        if (proposalIdtoProposal[_proposalId].voteOnce) {
            require(!hasVoted(userId, _proposalId) && checkMembership(tempDaoId, funcCaller), "User has already voted or you arent a member");
        }
        require(vt.balanceOf(funcCaller) >= numTokens && numTokens >= proposalIdtoProposal[_proposalId].votingThreshold,"Insufficient tokens");
        require(block.timestamp >= proposalIdtoProposal[_proposalId].beginningTime && block.timestamp < proposalIdtoProposal[_proposalId].endingTime, "Voting isn't available");



        vt.transferFrom(funcCaller,address(this),numTokens);
        // Quadratic Voting: votes = sqrt(numTokens)
        uint256 numVotes = sqrt(numTokens);

        if (_vote) {
            quadraticYesMappings[tempDaoId][_proposalId] += numVotes;
        } else {
            quadraticNoMappings[tempDaoId][_proposalId] += numVotes;
        }
        emit QVVoteCast(_proposalId, userId, numVotes, _vote);
        // Mark user as having voted
        proposalIdtoVoters[_proposalId].push(userId);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function checkMembership( uint256 _daoId, address _callerWalletAddress ) public view returns (bool) {
        uint256 tempUserId = userWallettoUserId[_callerWalletAddress];
        uint256 totalMembers = daoIdtoDao[_daoId].MembersCount;
        for (uint256 i = 0; i < totalMembers; i++) {
            if (tempUserId == daoIdtoMembers[_daoId][i]) {
                return true;
            }
        }
        return false;
    }

    function hasVoted(
        uint256 _userId,
        uint256 _proposalId
    ) public view returns (bool) {
        for (uint256 i = 0; i < proposalIdtoVoters[_proposalId].length; i++) {
            if (_userId == proposalIdtoVoters[_proposalId][i]) {
                return true;
            }
        }
        return false;
    }

    function calculateProposalResult(uint256 _proposalId) public{
        proposal memory tempProposal = proposalIdtoProposal[_proposalId];
        require(block.timestamp > proposalIdtoProposal[_proposalId].endingTime && !proposalToResultCalculated[_proposalId] && tempProposal.proposerId != 0, "Voting hasn't ended or Result is already calculated or proposal does not exist");
        
        uint256 yesVotes = quadraticYesMappings[daoId][_proposalId];
        uint256 noVotes = quadraticNoMappings[daoId][_proposalId];
        bool tempResult;
        if (yesVotes > noVotes) {
            proposalIdToResult[_proposalId] = true;
            tempResult = true;
        }
        else{
            proposalIdToResult[_proposalId] = false;
            tempResult = false;
        }
        proposalToResultCalculated[_proposalId] = true;
        emit ResultCalculated(_proposalId, tempProposal.proposerId, tempResult);
    }

    // Function to withdraw funds based on proposal result
    function withdrawFunds(uint256 proposalId) public onlyOwner {
        proposal memory selectedProposal = proposalIdtoProposal[proposalId];
        require(proposalIdToResult[proposalId] == true || selectedProposal.fundsNeeded <= address(this).balance, "Proposal did not pass or insufficient contract balance");

        // Transfer the funds to the owner
        payable(msg.sender).transfer(selectedProposal.fundsNeeded);

        // Emit an event for fund withdrawal
        emit FundsWithdrawn(proposalId, selectedProposal.fundsNeeded, msg.sender);
    }

    function getOwner() public view returns(address){
        return founder;
    }

    function getProposalResult(uint256 proposalId) public view returns (bool _result) {
        return proposalIdToResult[proposalId];
    }

}