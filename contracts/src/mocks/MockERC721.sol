// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint() public {
        totalSupply = totalSupply + 1;
        _mint(msg.sender, totalSupply);
    }
}
