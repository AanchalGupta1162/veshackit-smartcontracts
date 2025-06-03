// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import {VotingTokens} from "VotingTokens.sol";


contract Project is Ownable {
    uint256 public immutable id;
    string public name;
    string public founderName;
    address public immutable founder;
    uint256 public immutable budget;
    //uint256 public immutable duration;
    uint256 public immutable investmentLimit;
    uint256 public currentInvestedAmount;
    uint256 public daoId = 0;
    address public immutable tokenAddress;
    uint256 public immutable proposalLimit;
    uint256 public immutable totalTokens;
    bool isDaoCreated = false;

    uint public totalProposals = 0;
    uint public totalUser = 0;

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
    event MemberAddedToDAO(
        uint256 indexed daoId,
        uint256 userId,
        address userWallet
    );
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed ProjectAddress, 
        string proposalName,
        address indexed creator,
        uint256 fundsNeeded
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
        string memory _founderName,
        address _founder,
        uint256 _budget,
        //uint256 _duration,
        uint256 _proposalLimit,
        uint256 _investmentLimit,
        string memory tokenName,  
        string memory tokenSymbol,
        uint256 _tokenAmount
        )
        Ownable(_founder) {
        id = _id;
        name = _name;
        founderName = _founderName;
        founder = _founder;
        budget = _budget;
        proposalLimit = _proposalLimit;
        totalTokens = _tokenAmount;
        //duration = _duration;
        investmentLimit = _investmentLimit;
        VotingTokens vt = new VotingTokens(tokenName,tokenSymbol);
        tokenAddress = address(vt);
    }

    struct dao {
        uint256 project_id;
        string daoName;
        string daoDescription;
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
    // mapping(uint256 => address) public daoIdtoMembers;
    mapping(uint256 => uint256[]) public daoIdtoProposals;
    mapping(uint256 => uint256[]) public proposalIdtoVoters;
    // mapping(uint256 => uint256[]) public userIdtoDaos;
    mapping(uint256 => uint256) public proposalIdToQuadraticYesMappings;
    mapping(uint256 => uint256) public proposalIdToQuadraticNoMappings;
    mapping(address=>uint256) public userWallettoAmtInvested;
    mapping (uint256 => bool) public proposalIdToResult;
    mapping (uint256 => bool) public proposalToResultCalculated;

    
    function invest(string memory userName) public payable {
        require(isDaoCreated==true,"Dao has not been created.");
        require(msg.value >= investmentLimit , "Investment does not meet the minimum investment limit.");
        address userWallet = msg.sender;
        
        //update mapping of userWallet to totalAmountInvested
        if(userWallettoAmtInvested[userWallet]!=0)
            userWallettoAmtInvested[userWallet]+=msg.value;
        else{
            addUsertoDao(userName,userWallet);
            userWallettoAmtInvested[userWallet]=msg.value;
        } 

        currentInvestedAmount += msg.value;

        //emit invested amount
        emit investmentMade(totalUser, userName, userWallet,msg.value);
    }

    

    //createDao, add investors, dao can be created only once, only owner can create dao, dao can be created after the dao limit
    function createDao(
        string memory daoName, 
        string memory daoDescription
        // string memory tokenName, 
        // string memory tokenSymbol
        ) public onlyOwner{
        require(isDaoCreated == false, "DAO is already created.");
        daoId = id;
        dao memory newDao = dao({
            project_id: id,
            daoName: daoName,
            daoDescription: daoDescription
        });
        daoIdtoDao[daoId] = newDao;
        addUsertoDao(founderName, founder);
        isDaoCreated = true;
        
        // Emit an event for DAO creation
        emit DAOCreated(daoId, daoName, founder);
        
    }


    function addUsertoDao(string memory userName,address userWallet) internal {
        totalUser++;
        userIdtoUser[totalUser]=userName;
        userWallettoUserId[userWallet]=totalUser;
        // daoIdtoMembers[daoId]=userWallet;
        // userIdtoDaos[totalUser].push(daoId);
        VotingTokens vt = VotingTokens(tokenAddress);
        vt.transferTokens(userWallet, totalTokens);

        // Emit an event for adding a user to the DAO
        emit MemberAddedToDAO(daoId, totalUser, userWallet);
        
    }


    function createProposal(
        string memory proposalTitleAndDesc,
        uint256 votingThreshold,
        uint256 fundsNeeded,
        uint256 beginningTime,
        uint256 endingTime,
        bool voteOnce
    ) public onlyOwner {
        require(currentInvestedAmount >= proposalLimit && isDaoCreated == true, "Not enough investment for proposal creation");
        totalProposals++;
        uint256 proposerId = userWallettoUserId[msg.sender];

        proposal memory newProposal = proposal({
            proposalId: totalProposals,
            proposerId: proposerId,
            proposalTitleAndDesc: proposalTitleAndDesc,
            votingThreshold: votingThreshold * 1000000000000000000,
            fundsNeeded: fundsNeeded,
            beginningTime: beginningTime+block.timestamp,
            daoId: daoId,
            endingTime: endingTime+block.timestamp,
            voteOnce: voteOnce
        });
        proposalIdtoProposal[totalProposals] = newProposal;
        daoIdtoProposals[daoId].push(totalProposals);

        emit ProposalCreated(totalProposals, address(this), proposalTitleAndDesc, msg.sender, fundsNeeded);
    }

    function castVote(uint _proposalId, uint numTokens, bool _vote) external {

        VotingTokens vt = VotingTokens(tokenAddress);
        address funcCaller = msg.sender;
        numTokens = numTokens * (10 ** 18);
        uint256 userId = userWallettoUserId[funcCaller]; // Assumes mapping exists
        // uint256 tempDaoId = proposalIdtoProposal[_proposalId].daoId;
        if (proposalIdtoProposal[_proposalId].voteOnce) {
            require(!hasVoted(userId, _proposalId) && checkMembership(funcCaller), "User has already voted or you arent a member");
        }
        require(vt.balanceOf(funcCaller) >= numTokens && numTokens >= proposalIdtoProposal[_proposalId].votingThreshold,"Insufficient tokens");
        require(block.timestamp >= proposalIdtoProposal[_proposalId].beginningTime && block.timestamp < proposalIdtoProposal[_proposalId].endingTime, "Voting isn't available");



        vt.transferFrom(funcCaller,address(this),numTokens);
        // Quadratic Voting: votes = sqrt(numTokens)
        uint256 numVotes = sqrt(numTokens);

        if (_vote) {
            proposalIdToQuadraticYesMappings[_proposalId] += numVotes;
        } else {
            proposalIdToQuadraticNoMappings[_proposalId] += numVotes;
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

    function checkMembership( address _callerWalletAddress ) internal view returns (bool b) {
        return userWallettoUserId[_callerWalletAddress] != 0;
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

    function calculateProposalResult(uint256 _proposalId) external onlyOwner {
        proposal memory tempProposal = proposalIdtoProposal[_proposalId];
        require(block.timestamp > proposalIdtoProposal[_proposalId].endingTime && !proposalToResultCalculated[_proposalId] && tempProposal.proposerId != 0, "Voting hasn't ended or Result is already calculated or proposal does not exist");
        
        uint256 yesVotes = proposalIdToQuadraticYesMappings[_proposalId];
        uint256 noVotes = proposalIdToQuadraticNoMappings[_proposalId];
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
        if(tempResult==true){
            proposal memory selectedProposal = proposalIdtoProposal[_proposalId];
            require( selectedProposal.fundsNeeded <= address(this).balance, "Proposal did not pass or insufficient contract balance");
            payable(msg.sender).transfer(selectedProposal.fundsNeeded);
            emit FundsWithdrawn(_proposalId, selectedProposal.fundsNeeded, msg.sender);
        }
    }

    

    // // Function to withdraw funds based on proposal result
    // function withdrawFunds(uint256 proposalId) external onlyOwner {
    //     proposal memory selectedProposal = proposalIdtoProposal[proposalId];
    //     require(proposalIdToResult[proposalId] == true || selectedProposal.fundsNeeded <= address(this).balance, "Proposal did not pass or insufficient contract balance");

    //     // Transfer the funds to the owner
    //     payable(msg.sender).transfer(selectedProposal.fundsNeeded);

    //     // Emit an event for fund withdrawal
    //     emit FundsWithdrawn(proposalId, selectedProposal.fundsNeeded, msg.sender);
    // }

    // // function renewTokens(address member) external onlyOwner{
    // //     address funcCaller = msg.sender;

    // // }

    function getOwner() public view returns(address){
        return founder;
    }

    function getProposalResult(uint256 proposalId) public view returns (bool _result) {
        return proposalIdToResult[proposalId];
    }

}