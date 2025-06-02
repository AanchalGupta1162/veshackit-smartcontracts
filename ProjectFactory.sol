// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Project} from "Project.sol";

contract ProjectFactory{
    uint256 totalProjects=0;
    mapping (uint256=> address) public projectIdToAddress;
    mapping (string=>uint256) public projectNametoprojectId;

    function createProject(
        string memory _name,
        uint256 _budget,
        uint256 _duration,
        uint256 _investmentLimit,
        uint256 _daoLimit
        ) public {
        totalProjects++;
        require(projectNametoprojectId[_name]==0 && _investmentLimit<_budget && _daoLimit<_budget,"Project with this name already exists or Limits set exceed the project budget");

         

        // Create a new Project instance with the provided parameters.
        Project project = new Project(
            totalProjects,  // The ID will be assigned automatically by Solidity
            _name,
            msg.sender,
            _budget * 1000000000000000000,
            _duration,
            _investmentLimit  * 1000000000000000000,
            _daoLimit * 1000000000000000000
            );
        projectNametoprojectId[_name]=totalProjects;
        projectIdToAddress[totalProjects]=address(project);
}
}