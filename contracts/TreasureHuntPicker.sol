// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntPicker is Initializable, OwnableUpgradeable {

    address public treasureHuntPirate;
    address public treasureHuntShip;
    function initialize(address _treasureHuntPirate, address _treasureHuntShip) public initializer {
        __Ownable_init();
        treasureHuntPirate = _treasureHuntPirate;
        treasureHuntShip = _treasureHuntShip;
    }

    function random(string memory name, uint256 seed) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.difficulty,
            block.timestamp,
            block.number,
            name,
            seed
        )));
    }

    function randomPirate(uint256 tokenID, string memory name) public returns (bool) {
        require(msg.sender == treasureHuntPirate, "TreasureHuntPirate: You are not Pirate..");
        
        uint256 index = random(name, tokenID);
        uint8 chance = uint8(index % 100);
        uint16 power1 = uint16((index >> 16) % 36);
        uint16 power2 = uint16((index >> 32) % 51);
        uint16 power3 = uint16((index >> 48) % 56);

        if (chance < 48) {
            ITreasureHunt(treasureHuntPirate).setPirate(tokenID, 1, power1 + 15, name);
        } else if (chance < 86 && chance >= 48) {
            ITreasureHunt(treasureHuntPirate).setPirate(tokenID, 2, power2 + 50, name);
        } else if (chance < 96 && chance >= 86) {
            ITreasureHunt(treasureHuntPirate).setPirate(tokenID, 3, power2 + 100, name);
        } else if (chance < 99 && chance >= 96) {
            ITreasureHunt(treasureHuntPirate).setPirate(tokenID, 4, power2 + 150, name);
        } else {
            ITreasureHunt(treasureHuntPirate).setPirate(tokenID, 5, power3 + 200, name);
        }

        return true;
    }
    function randomShip(uint256 tokenID, string memory name) public returns (bool) {
        require(msg.sender == treasureHuntShip, "TreasureHuntShip: You are not Ship..");
        
        uint256 index = random(name, tokenID);
        uint8 chance = uint8(index % 100);
        // uint16 pirateCnt;

        if (chance < 48) {
            ITreasureHunt(treasureHuntShip).setShip(tokenID, 1, name);
        } else if (chance < 86 && chance >= 48) {
            ITreasureHunt(treasureHuntShip).setShip(tokenID, 2, name);
        } else if (chance < 96 && chance >= 86) {
            ITreasureHunt(treasureHuntShip).setShip(tokenID, 3, name);
        } else if (chance < 99 && chance >= 96) {
            ITreasureHunt(treasureHuntShip).setShip(tokenID, 4, name);
        } else {
            ITreasureHunt(treasureHuntShip).setShip(tokenID, 5, name);
        }

        return true;
    }

    function setTreasureHuntPirate(address _treasureHuntPirate) public onlyOwner {
        treasureHuntPirate = _treasureHuntPirate;
    }

    function setTreasureHuntShip(address _treasureHuntShip) public onlyOwner {
        treasureHuntShip = _treasureHuntShip;
    }
}