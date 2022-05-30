// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ITreasureHuntTrait.sol";

interface ITreasureHunt is ITreasureHuntTrait {
    function transferFrom(address, address, uint256) external;
    function setSeaport(uint256, uint8, uint16) external;
    //picker
    function randomPirate(uint256, string memory) external returns(bool);
    function randomShip(uint256, string memory) external returns(bool);
    function random(string memory, uint256) external returns(uint256);
    //pirate
    function boardPirates(uint256[] memory) external;
    function getPirate(uint256) external view returns(Pirate memory);
    function getPirates(uint256[] memory) external view returns(Pirate[] memory);
    function setPirate(uint256, uint8, uint16, string memory) external;
    function unBoardPirates(uint256[] memory) external;
    function transferPirate(uint256) external;
    //ship
    function disJoinShips(uint256[] memory) external;
    function getShip(uint256) external view returns(Ship memory);
    function getShips(uint256[] memory) external view returns(Ship[] memory);
    function joinShips(uint256[] memory) external;
    function setShip(uint256, uint8, string memory) external;
    function transferShip(uint256) external;
    //fleet
    function getFleetNumByOwner(address) external view returns(uint256);
    function getFleetInfo(uint256) external view returns(Fleet memory);
    function updateFleetFund(uint256, uint256, uint256, bool) external;
    function setFleetRaidTime(uint256) external;
    function getTotalHakiByOwner(address) external view returns(uint256);
    function getMaxHakiByOwner(address) external view returns(uint256);
    function setFleetDurability(uint256, bool) external;
    function canRaid(uint256) external view returns(bool);
    function transferFleet(uint256) external;
    //reward pool contract
    function transferBurnReward(address, uint256) external;
    function reward2Player(address, uint256) external;
    function payUsingReward(address, uint256) external;
    function transferCost(uint256) external;
    function updateExperience(address, uint256) external;
    function getDecimal() external view returns(uint8);
    function getRepairCost(uint256) external view returns(uint256);
    function buyNFT(uint256, address) external;
    function cancelNFT(uint256) external;
    //seaport
    function isOnSeaport(address) external view returns(bool);
    function isSeaportOwner(address) external view returns(bool);
    function getSeaportOwnerByPlayer(address) external view returns(address);
    function transferSeaport(uint256) external;
    //random generator
    function getRandomWord() external view returns (uint256);
}
