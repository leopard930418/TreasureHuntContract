// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./ITreasureHunt.sol";
import "./ITreasureHuntTrait.sol";

contract TreasureHuntMarketPlace is Initializable, ITreasureHuntTrait, OwnableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    mapping(address => Goods[]) pirateStore;
    mapping(address => Goods[]) shipStore;
    mapping(address => Goods[]) fleetStore;
    mapping(address => Goods[]) seaportStore;

    mapping(uint256 => uint256) pirateIndex;
    mapping(uint256 => uint256) shipIndex;
    mapping(uint256 => uint256) fleetIndex;
    mapping(uint256 => uint256) seaportIndex;

    EnumerableSetUpgradeable.AddressSet private pirateHolders;
    EnumerableSetUpgradeable.AddressSet private shipHolders;
    EnumerableSetUpgradeable.AddressSet private fleetHolders;
    EnumerableSetUpgradeable.AddressSet private seaportHolders;

    address public treasureHuntPirate;
    address public treasureHuntShip;
    address public treasureHuntFleet;
    address public treasureHuntSeaport;
    address public treasureHuntRewardPool;

    event PirateSold(address acc, uint256 tokenID);
    event ShipSold(address acc, uint256 tokenID);
    event FleetSold(address acc, uint256 tokenID);
    event SeaportSold(address acc, uint256 tokenID);

    event PirateCanceled(address acc, uint256 tokenID);
    event ShipCanceled(address acc, uint256 tokenID);
    event FleetCanceled(address acc, uint256 tokenID);
    event SeaportCanceled(address acc, uint256 tokenID);

    function initialize(address _treasureHuntPirate, address _treasureHuntShip, address _treasureHuntFleet, address _treasureHuntSeaport, address _treasureHuntRewardPool) public initializer {
        __Ownable_init();
        treasureHuntPirate = _treasureHuntPirate;
        treasureHuntShip = _treasureHuntShip;
        treasureHuntFleet = _treasureHuntFleet;
        treasureHuntSeaport = _treasureHuntSeaport;
        treasureHuntRewardPool = _treasureHuntRewardPool;
    }

    function getPiratesByOwner() public view returns(Goods[] memory) {
        return pirateStore[msg.sender];
    }

    function getPiratesOnStore() public view returns(Goods[] memory) {

    }

    function sellPirate(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntPirate).transferPirate(tokenID);
        pirateHolders.add(msg.sender);
        Goods memory pirate = Goods(tokenID, msg.sender, price);
        pirateStore[msg.sender].push(pirate);
        pirateIndex[tokenID] = pirateStore[msg.sender].length - 1;
    }

    function removePirateHolder(address acc) internal {
        if (pirateStore[acc].length == 1) {
            pirateHolders.remove(msg.sender);
        }
    }

    function cancelPirate(uint256 tokenID) public {
        require(pirateStore[msg.sender][pirateIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        removePirateHolder(msg.sender);
        Goods memory pirate =  pirateStore[msg.sender][pirateIndex[tokenID]];
        uint256 price = pirate.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntPirate).transferFrom(address(this), msg.sender, tokenID);
        emit PirateCanceled(msg.sender, tokenID);
    }

    function buyPirate(uint256 tokenID, address tokenOwner) public {
        require(pirateStore[tokenOwner][pirateIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory pirate =  pirateStore[tokenOwner][pirateIndex[tokenID]];
        uint256 price = pirate.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntPirate).transferFrom(address(this), msg.sender, tokenID);
        removePirateHolder(tokenOwner);

        pirateIndex[pirateStore[tokenOwner][pirateStore[tokenOwner].length - 1].TokenID] = pirateIndex[tokenID];
        pirateStore[tokenOwner][pirateIndex[tokenID]].TokenID = pirateStore[tokenOwner][pirateStore[tokenOwner].length - 1].TokenID;
        pirateStore[tokenOwner].pop();

        delete pirateIndex[tokenID];

        emit PirateSold(tokenOwner, tokenID);
    }

    function sellShip(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntShip).transferShip(tokenID);
        shipHolders.add(msg.sender);
        Goods memory ship = Goods(tokenID, msg.sender, price);
        shipStore[msg.sender].push(ship);
        shipIndex[tokenID] = shipStore[msg.sender].length - 1;
    }

    function removeShipHolder(address acc) internal {
        if (shipStore[acc].length == 1) {
            shipHolders.remove(msg.sender);
        }
    }

    function cancelShip(uint256 tokenID) public {
        require(shipStore[msg.sender][shipIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        Goods memory ship =  shipStore[msg.sender][shipIndex[tokenID]];
        removeShipHolder(msg.sender);
        uint256 price = ship.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntShip).transferFrom(address(this), msg.sender, tokenID);
        emit ShipCanceled(msg.sender, tokenID);
    }

    function buyShip(uint256 tokenID, address tokenOwner) public {
        require(shipStore[tokenOwner][shipIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory ship =  shipStore[tokenOwner][shipIndex[tokenID]];
        uint256 price = ship.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntShip).transferFrom(address(this), msg.sender, tokenID);
        removeShipHolder(tokenOwner);

        shipIndex[shipStore[tokenOwner][shipStore[tokenOwner].length - 1].TokenID] = shipIndex[tokenID];
        shipStore[tokenOwner][shipIndex[tokenID]].TokenID = shipStore[tokenOwner][shipStore[tokenOwner].length - 1].TokenID;
        shipStore[tokenOwner].pop();

        delete shipIndex[tokenID];
        emit ShipSold(tokenOwner, tokenID);
    }

    function sellFleet(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntFleet).transferFleet(tokenID);
        fleetHolders.add(msg.sender);
        Goods memory fleet = Goods(tokenID, msg.sender, price);
        fleetStore[msg.sender].push(fleet);
        fleetIndex[tokenID] = fleetStore[msg.sender].length - 1;
    }

    function removeFleetHolder(address acc) internal {
        if (fleetStore[acc].length == 1) {
            fleetHolders.remove(msg.sender);
        }
    }

    function cancelFleet(uint256 tokenID) public {
        require(fleetStore[msg.sender][fleetIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        removeFleetHolder(msg.sender);
        Goods memory fleet =  fleetStore[msg.sender][fleetIndex[tokenID]];
        uint256 price = fleet.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntFleet).transferFrom(address(this), msg.sender, tokenID);
        emit FleetCanceled(msg.sender, tokenID);
    }

    function buyFleet(uint256 tokenID, address tokenOwner) public {
        require(fleetStore[tokenOwner][fleetIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory fleet =  fleetStore[tokenOwner][fleetIndex[tokenID]];
        uint256 price = fleet.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntFleet).transferFrom(address(this), msg.sender, tokenID);
        removeFleetHolder(tokenOwner);

        fleetIndex[fleetStore[tokenOwner][fleetStore[tokenOwner].length - 1].TokenID] = fleetIndex[tokenID];
        fleetStore[tokenOwner][fleetIndex[tokenID]].TokenID = fleetStore[tokenOwner][fleetStore[tokenOwner].length - 1].TokenID;
        fleetStore[tokenOwner].pop();

        delete fleetIndex[tokenID];
        emit FleetSold(tokenOwner, tokenID);
    }

    function sellSeaport(uint256 tokenID, uint256 price) public {
        ITreasureHunt(treasureHuntSeaport).transferSeaport(tokenID);
        seaportHolders.add(msg.sender);
        Goods memory seaport = Goods(tokenID, msg.sender, price);
        seaportStore[msg.sender].push(seaport);
        seaportIndex[tokenID] = seaportStore[msg.sender].length - 1;
    }

    function removeSeaportHolder(address acc) internal {
        if (seaportStore[acc].length == 1) {
            seaportHolders.remove(msg.sender);
        }
    }

    function cancelSeaport(uint256 tokenID) public {
        require(seaportStore[msg.sender][seaportIndex[tokenID]].Owner == msg.sender, "You are not the owner of this token!");
        removeSeaportHolder(msg.sender);
        Goods memory seaport =  seaportStore[msg.sender][seaportIndex[tokenID]];
        uint256 price = seaport.Price;
        ITreasureHunt(treasureHuntRewardPool).cancelNFT(price);
        ITreasureHunt(treasureHuntSeaport).transferFrom(address(this), msg.sender, tokenID);
        emit SeaportCanceled(msg.sender, tokenID);
    }

    function buyseaport(uint256 tokenID, address tokenOwner) public {
        require(seaportStore[tokenOwner][seaportIndex[tokenID]].TokenID == tokenID, "Can't find that token!");
        Goods memory seaport =  seaportStore[tokenOwner][seaportIndex[tokenID]];
        uint256 price = seaport.Price;
        ITreasureHunt(treasureHuntRewardPool).buyNFT(price, tokenOwner);
        ITreasureHunt(treasureHuntSeaport).transferFrom(address(this), msg.sender, tokenID);
        removeSeaportHolder(tokenOwner);

        seaportIndex[seaportStore[tokenOwner][seaportStore[tokenOwner].length - 1].TokenID] = seaportIndex[tokenID];
        seaportStore[tokenOwner][seaportIndex[tokenID]].TokenID = seaportStore[tokenOwner][seaportStore[tokenOwner].length - 1].TokenID;
        seaportStore[tokenOwner].pop();

        delete seaportIndex[tokenID];
        emit SeaportSold(tokenOwner, tokenID);
    }

}