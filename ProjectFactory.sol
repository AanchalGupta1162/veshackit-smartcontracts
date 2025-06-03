// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Project} from "Project.sol";

contract ProjectFactory{
    uint256 totalProjects=0;
    mapping (uint256=> address) public projectIdToAddress;
    mapping (string=>uint256) public projectNametoprojectId;

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed owner
    );

    function createProject(
        string memory _name,
        string memory _founderName,
        uint256 _budget,
        // uint256 _duration,
        uint256 _investmentLimit,
        // string memory daoName, 
        // string memory daoDescription, 
        // uint256 amountTokens,
        string memory tokenName,  
        string memory tokenSymbol
        ) public {
        totalProjects++;
        require(projectNametoprojectId[_name]==0 && _investmentLimit<_budget,"Project with this name already exists or Limits set exceed the project budget");

        // Create a new Project instance with the provided parameters.
        Project project = new Project(
            totalProjects,  // The ID will be assigned automatically by Solidity
            _name,
            _founderName,
            msg.sender,
            _budget,
            // _duration,
            _investmentLimit,
            // daoName, 
            // daoDescription,  
            // amountTokens,
            tokenName,    
            tokenSymbol
        );
        emit ProjectCreated(totalProjects, msg.sender);
        projectNametoprojectId[_name]=totalProjects;
        projectIdToAddress[totalProjects]=address(project);
    }
}