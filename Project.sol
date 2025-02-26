// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MyNFT} from "NFTs.sol";

contract Project is Ownable {
    uint256 public id;
    string public name;
    address public immutable founder;
    address public immutable NFT;
    uint256 public immutable budget;
    uint256 public immutable duration;
    uint256 public immutable investmentLimit;
    uint256 public immutable daoLimit;
    uint256 public currentInvestedAmount;
    uint256 public daoId = 0;

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
    event UserJoinedDAO(
        uint256 indexed daoId,
        uint256 userId,
        address userWallet
    );
    event DocumentUploaded(
        uint256 indexed documentId,
        uint256 daoId,
        address uploaderWallet
    );
    event VoteCast(
        uint256 indexed proposalId,
        uint256 userId,
        uint256 voteChoice
    );
    event QVVoteCast(
        uint256 indexed proposalId,
        uint256 userId,
        uint256 numTokens,
        uint256 voteChoice
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

    struct Document {
        uint256 documentId;
        string documentTitle;
        string documentDescription;
        string ipfsHash;
        uint256 uploaderId;
        uint256 daoId;
    }

    mapping(uint256 => string) public userIdtoUser;
    mapping(address => uint256) public userWallettoUserId;
    mapping(uint256 => dao) public daoIdtoDao;
    mapping(uint256 => proposal) public proposalIdtoProposal;
    mapping(uint256 => uint256[]) public daoIdtoMembers;
    mapping(uint256 => uint256[]) public daoIdtoProposals;
    mapping(uint256 => uint256[]) public proposalIdtoVoters;
    mapping(uint256 => uint256[]) public proposalIdtoYesVoters;
    mapping(uint256 => uint256[]) public proposalIdtoNoVoters;
    mapping(uint256 => uint256[]) public proposalIdtoAbstainVoters;
    mapping(uint256 => uint256[]) public userIdtoDaos;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticYesMappings;
    mapping(uint256 => mapping(uint256 => uint256)) public quadraticNoMappings;
    mapping(uint256 => Document) public documentIdtoDocument;    
    mapping(uint256 => uint256[]) public daoIdtoDocuments;
    mapping(address=>uint256) public userWallettoAmtInvested;
    event ProposalCreated(address indexed ProjectAddress, uint256 daoId, address indexed investor);

    function invest(string memory userName) public payable {
        address userWallet = msg.sender;
        //If user has never invested before, create new user and check investment limit
        if(userWallettoUserId[userWallet]!=0){
        require(msg.value >= investmentLimit, "Investment must meet the minimum investment limit");
        createUser(userName,userWallet);
        //emit user creation
        emit UserCreated(totalUser,userName,userWallet);
        }

        require(currentInvestedAmount + msg.value <= budget, "Investment exceeds project budget");
        currentInvestedAmount += msg.value;

        if(isDaoCreated==true)
        addUsertoDao(userWallet);

        //update mapping of userWallet to totalAmountInvested
        if(userWallettoAmtInvested[userWallet]!=0)
        userWallettoAmtInvested[userWallet]+=msg.value;
        else{
            sendNFT(userWallet,msg.value);
            userWallettoAmtInvested[userWallet]=msg.value;
        } 

        //send NFT to user for the current investment       
        //emit invested amount
        emit investmentMade(totalUser, userName, userWallet,msg.value);
    }

    event UserCreated(
        uint256 indexed userId,
        string userName,
        address userWallet
    );

    function sendNFT(address userWallet,uint256 amountInvested) public {
        // Logic to send NFTs to investors
        // This can involve minting NFTs or transferring pre-minted ones
    }

    // function createDao(string memory daoName, string memory daoDescription) public {
    //     require(bytes(daoName).length > 0, "DAO name cannot be empty");
    //     require(bytes(daoDescription).length > 0, "DAO description cannot be empty");

    //     uint256 daoId = totalUser + 1;
    //     dao memory newDao = dao({
    //         project_id: id,
    //         daoName: daoName,
    //         daoDescription: daoDescription,
    //         MembersCount: 0,
    //         creator: msg.sender
    //     });
    //     daoIdtoDao[daoId] = newDao;
    //     totalUser++;
    //     // Emit an event for DAO creation
    // }

    // function addUsertoDao(uint256 daoId, address userWallet) public {
    //     require(daoIdtoDao[daoId].creator != address(0), "DAO does not exist");
    //     require(userWallettoUserId[userWallet] > 0, "User does not exist");

    //     uint256 userId = userWallettoUserId[userWallet];
    //     daoIdtoMembers[daoId].push(userId);
    //     daoIdtoDao[daoId].MembersCount++;
    //     userIdtoDaos[userId].push(daoId);
    //     // Emit an event for adding a user to the DAO
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
        require(daoIdtoDao[daoId].creator != address(0), "DAO does not exist");

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

    function createUser(string memory _name, address userWallet) public {
        require(userWallettoUserId[userWallet] == 0, "User already exists");
        totalUser++;
        userIdtoUser[totalUser] = _name;
        userWallettoUserId[userWallet] = totalUser;
    }

    function getOwner() public view returns(address){
        return founder;
    }
    //createDao, add investors, dao can be created only once, only owner can create dao, dao can be created after the dao limit
    function createDao(string memory daoName, string memory daoDescription) public {
        require(bytes(daoName).length > 0, "DAO name cannot be empty");
        require(bytes(daoDescription).length > 0, "DAO description cannot be empty");
        require(currentInvestedAmount > daoLimit, "DAO cannot be created before the dao limit");
        require(isDaoCreated == false,"DAO can only be created once");

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
        // Emit an event for DAO creation
    }

    function addUsertoDao(address userWallet) public {
        require(daoIdtoDao[daoId].creator != address(0), "DAO does not exist");
        require(userWallettoUserId[userWallet] > 0, "User does not exist");

        uint256 userId = userWallettoUserId[userWallet];
        daoIdtoMembers[daoId].push(userId);
        daoIdtoDao[daoId].MembersCount++;
        userIdtoDaos[userId].push(daoId);
        // Emit an event for adding a user to the DAO
    }
}
