// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
// import {MyNFT} from "NFTs.sol";
import {VotingTokens} from "VotingTokens.sol";


contract Project is Ownable {
    uint256 public id;
    string public name;
    address public immutable founder;
    //address public immutable NFT;
    uint256 public immutable budget;
    uint256 public immutable duration;
    uint256 public immutable investmentLimit;
    uint256 public immutable daoLimit;
    uint256 public currentInvestedAmount;
    uint256 public daoId = 0;
    address public tokenAddress;

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
    // event UserJoinedDAO(
    //     uint256 indexed daoId,
    //     uint256 userId,
    //     address userWallet
    // );
    event ProposalCreated(
        address indexed ProjectAddress, 
        uint256 daoId, 
        address indexed investor
    );
    // event DocumentUploaded(
    //     uint256 indexed documentId,
    //     uint256 daoId,
    //     address uploaderWallet
    // );
    // event VoteCast(
    //     uint256 indexed proposalId,
    //     uint256 userId,
    //     uint256 voteChoice
    // );
    event QVVoteCast(
        uint256 indexed proposalId,
        uint256 userId,
        uint256 numTokens,
        uint256 voteChoice
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
        //  MyNFT nft = new MyNFT(msg.sender);

        // NFT = address(nft);
    }

    struct dao {
        uint256 project_id;
        string daoName;
        string daoDescription;
        uint256 MembersCount;
        address creator;
        address[] members;
        //mapping (address=>uint256) balances;
    }

    struct proposal {
        uint256 proposalId;
        uint256 proposerId;
        string proposalTitleAndDesc;
        string proposalIpfsHash;
        uint256 votingThreshold;
        address votingTokenAddress;
        uint256 fundsNeeded;
        uint256 beginningTime;
        uint256 daoId;
        uint256 endingTime;
        uint256 passingThreshold;
        bool voteOnce;
    }

    // struct Document {
    //     uint256 documentId;
    //     string documentTitle;
    //     string documentDescription;
    //     string ipfsHash;
    //     uint256 uploaderId;
    //     uint256 daoId;
    // }

    mapping(uint256 => string) public userIdtoUser;
    mapping(address => uint256) public userWallettoUserId;
    mapping(uint256 => dao) public daoIdtoDao;
    mapping(uint256 => proposal) public proposalIdtoProposal;
    mapping(uint256 => uint256[]) public daoIdtoMembers;
    mapping(uint256 => uint256[]) public daoIdtoProposals;
    mapping(uint256 => uint256[]) public proposalIdtoVoters;
    // mapping(uint256 => uint256[]) public proposalIdtoYesVoters;
    // mapping(uint256 => uint256[]) public proposalIdtoNoVoters;
    // mapping(uint256 => uint256[]) public proposalIdtoAbstainVoters;
    mapping(uint256 => uint256[]) public userIdtoDaos;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticYesMappings;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticNoMappings;
    // mapping(uint256 => Document) public documentIdtoDocument;    
    // mapping(uint256 => uint256[]) public daoIdtoDocuments;
    mapping(address=>uint256) public userWallettoAmtInvested;
    mapping (uint256 => bool) public proposalIdToResult;
    // mapping (uint256=>VotingTokens) public userIdtoTokens;

    function invest(string memory userName) public payable {
       require(currentInvestedAmount + msg.value <= budget, "Investment exceeds project budget");
        address userWallet = msg.sender;
        //If user has never invested before, create new user and check investment limit
        if(userWallettoUserId[userWallet]!=0){
        require(msg.value >= investmentLimit, "Investment must meet the minimum investment limit");
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

        //send NFT to user for the current investment       
        //emit invested amount
        emit investmentMade(totalUser, userName, userWallet,msg.value);
    }

    function createUser(string memory _name, address userWallet) public {
        //require(userWallettoUserId[userWallet] == 0, "User already exists");
        totalUser++;
        userIdtoUser[totalUser] = _name;
        userWallettoUserId[userWallet] = totalUser;
    }

    // function sendNFT(address userWallet,uint256 amountInvested) public {
    //     // Logic to send NFTs to investors
    //     // This can involve minting NFTs or transferring pre-minted ones
    // }


    function createProposal(
        string memory proposalTitleAndDesc,
        string memory proposalIpfsHash,
        uint256 votingThreshold,
        address votingTokenAddress,
        uint256 fundsNeeded,
        uint256 beginningTime,
        uint256 endingTime,
        uint256 passingThreshold,
        bool voteOnce
    ) public onlyOwner {
        // require(daoIdtoDao[daoId].creator != address(0), "DAO does not exist");
        // require(endingTime > 0, "The voting period cannot be 0");
        totalProposals++;
        uint256 proposerId = userWallettoUserId[msg.sender];

        proposal memory newProposal = proposal({
            proposalId: totalProposals,
            proposerId: proposerId,
            proposalTitleAndDesc: proposalTitleAndDesc,
            proposalIpfsHash: proposalIpfsHash,
            votingThreshold: votingThreshold,
            votingTokenAddress: votingTokenAddress,
            fundsNeeded: fundsNeeded,
            beginningTime: beginningTime,
            daoId: daoId,
            endingTime: endingTime,
            passingThreshold: passingThreshold,
            voteOnce: voteOnce
        });
        proposalIdtoProposal[totalProposals] = newProposal;
        daoIdtoProposals[daoId].push(totalProposals);

        emit ProposalCreated(address(this), daoId, msg.sender);
    }


    //createDao, add investors, dao can be created only once, only owner can create dao, dao can be created after the dao limit
    function createDao(string memory daoName, string memory daoDescription, uint256 amountTokens, string memory tokenName, string memory tokenSymbol) public onlyOwner{
        // require(bytes(daoName).length > 0 && bytes(daoDescription).length > 0, "DAO name or description cannot be empty");
        // require(currentInvestedAmount > daoLimit && isDaoCreated == false, "DAO limit not reached or dao already created");

        dao memory newDao = dao({
            project_id: id,
            daoName: daoName,
            daoDescription: daoDescription,
            MembersCount: totalUser,
            creator: founder,
            members: users
        });
        daoIdtoDao[daoId] = newDao;
        totalUser++;

        VotingTokens vt = new VotingTokens(tokenName, tokenSymbol);
        tokenAddress = address(vt);
        for(uint i=0;i<totalUser;i++){
            vt.transferTokens(users[i], amountTokens);
        }

        // Emit an event for DAO creation
        emit DAOCreated(daoId, daoName, founder);
        
    }


    function addUsertoDao(address userWallet) public onlyOwner {
        // require(daoIdtoDao[daoId].creator != address(0), "DAO does not exist");
        // require(userWallettoUserId[userWallet] > 0, "User does not exist");

        uint256 userId = userWallettoUserId[userWallet];
        daoIdtoMembers[daoId].push(userId);
        daoIdtoDao[daoId].MembersCount++;
        userIdtoDaos[userId].push(daoId);
        VotingTokens vt = VotingTokens(tokenAddress);
        vt.transferTokens(userWallet, 10);
        // Emit an event for adding a user to the DAO
    }

    // Function to set the result of a proposal
    function setProposalResult(uint256 proposalId, bool result) public onlyOwner {
        require(proposalIdtoProposal[proposalId].proposalId != 0, "Proposal does not exist");
        proposalIdToResult[proposalId] = result;
    }
    
    // Function to withdraw funds based on proposal result
    function withdrawFunds(uint256 proposalId) public onlyOwner {
        require(proposalIdToResult[proposalId] == true, "Proposal did not pass");
        proposal memory selectedProposal = proposalIdtoProposal[proposalId];
        // require(selectedProposal.fundsNeeded <= address(this).balance, "Insufficient contract balance");

        // Transfer the funds to the owner
        payable(msg.sender).transfer(selectedProposal.fundsNeeded);

        // Emit an event for fund withdrawal
        emit FundsWithdrawn(proposalId, selectedProposal.fundsNeeded, msg.sender);
    }

    function getOwner() public view returns(address){
        return founder;
    }

        function checkMembership(
        uint256 _daoId,
        address _callerWalletAddress
    ) public view returns (bool) {
        uint256 tempUserId = userWallettoUserId[_callerWalletAddress];
        uint256 totalMembers = daoIdtoMembers[_daoId].length;
        for (uint256 i = 0; i < totalMembers; i++) {
            if (tempUserId == daoIdtoMembers[_daoId][i]) {
                return true;
            }
        }
        return false;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    function castVote(uint _proposalId, uint numTokens, bool _vote) external {
        address funcCaller = msg.sender;
        uint256 tempDaoId = proposalIdtoProposal[_proposalId].daoId;
        uint256 userId = userWallettoUserId[funcCaller]; // Assumes mapping exists

        require(checkMembership(tempDaoId, funcCaller), "Only members of the DAO can vote");
        require(block.timestamp >= proposalIdtoProposal[_proposalId].beginningTime, "Voting has not started");
        require(block.timestamp < proposalIdtoProposal[_proposalId].endingTime, "Voting time has ended");

        if (proposalIdtoProposal[_proposalId].voteOnce) {
            // require(!hasVoted(userId, _proposalId), "User has already voted");
        }
        VotingTokens vt = VotingTokens(tokenAddress);
        vt.transferFrom(funcCaller,address(this),numTokens);
        // Quadratic Voting: votes = sqrt(numTokens)
        uint256 numVotes = sqrt(numTokens);
        //require(numVotes * numVotes == numTokens, "Tokens must be a perfect square");

        if (_vote) {
            quadraticYesMappings[tempDaoId][_proposalId] += numVotes;
        } else {
            quadraticNoMappings[tempDaoId][_proposalId] += numVotes;
        }

        // Mark user as having voted
        proposalIdtoVoters[_proposalId].push(userId);
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

    uint256 yesVotes = quadraticYesMappings[daoId][_proposalId];
    uint256 noVotes = quadraticNoMappings[daoId][_proposalId];

    if (yesVotes > noVotes) 
        proposalIdToResult[_proposalId] = true;
    else
        proposalIdToResult[_proposalId] = false;
    
}



}

   