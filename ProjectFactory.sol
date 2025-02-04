// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Project} from "Project.sol";

contract ProjectFactory{
    uint256 totalProjects=0;

    mapping (uint256=> address) public projectIdToAddress;
    mapping (string=>uint256) public projectNametoprojectId;

    function createProject(string memory _name,
        uint256 _budget,
        uint256 _duration,
        uint256 _investmentLimit,
        uint256 _daoLimit
        ) public {
        totalProjects++;
        //require(projectNametoprojectId[_name]==0,"Project with this name already exists");
        //require(_investmentLimit<_budget && _daoLimit<_budget,"Limits set exceed the project budget");

        //creating NFT
         
        // Hardcoded NFT contract address
        address nftAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;

        // Create a new Project instance with the provided parameters
        Project project = new Project(
            totalProjects,
            _name,
            msg.sender,
            _budget,
            _duration,
            _investmentLimit,
            _daoLimit,
            nftAddress // Pass the hardcoded NFT contract address
        );
        projectNametoprojectId[_name]=totalProjects;
        projectIdToAddress[totalProjects]=address(project);


}
}