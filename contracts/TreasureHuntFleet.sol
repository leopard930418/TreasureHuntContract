// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasureHuntTrait.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntFleet is
    Initializable,
    ITreasureHuntTrait,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    mapping(uint256 => Fleet) fleetInfo;

    mapping(address => uint256[]) fleetsByOwner;
    mapping(uint256 => uint256) tokenIndex;

    address public treasureHuntPirate;
    address public treasureHuntShip;
    address public rewardPool;
    address public treasureHuntMarketPlace;

    mapping (uint8 => string) fleetBaseURI;


    uint256 public fleetMintPrice;

    uint256 public fleetRaidInterval;

    mapping(address => bool) teamlist;

    modifier fleetOwner(uint256 tokenID) {
        require(ownerOf(tokenID) == msg.sender, "You are not owner!"); _;
    }

    modifier onlyRewardPool() {
        require(msg.sender == rewardPool, "You are not reward pool!"); _;
    }

    modifier _isMarket {
        require(msg.sender == treasureHuntMarketPlace, "You are not MarketPlace!");
        _;
    }

    function initialize(address _treasureHuntPirate, address _treasureHuntShip)
        public
        initializer
    {
        __ERC721_init("Fleet NFT", "FLEET");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();

        treasureHuntPirate = _treasureHuntPirate;
        treasureHuntShip = _treasureHuntShip;
        
        fleetMintPrice = 30;
        fleetRaidInterval = 1 days;

        teamlist[msg.sender] = true;
    }

    function mint(address to, uint256 tokenID) internal {
        fleetsByOwner[to].push(tokenID);
        tokenIndex[tokenID] = fleetsByOwner[to].length - 1;
        _safeMint(to, tokenID);
    }

    function buildFleet(
        uint256[] memory ships,
        uint256[] memory pirates,
        string memory fname
    ) public {
        require(ships.length <= 10, "Exceed maximum ships num!");

        if (!teamlist[msg.sender]) {
            ITreasureHunt(rewardPool).transferCost(fleetMintPrice);
        }

        ITreasureHunt(treasureHuntPirate).boardPirates(pirates);
        ITreasureHunt(treasureHuntShip).joinShips(ships);
        uint256 tokenID = totalSupply() + 1;
        uint8 rank = getRank(ships);
        Fleet memory fleet = Fleet(
            tokenID,
            fname,
            0,
            rank,
            0,
            0,
            true,
            0,
            35,
            getHaki(pirates),
            ships,
            pirates
        );
        fleetInfo[tokenID] = fleet;

        mint(msg.sender, tokenID);
        _setTokenURI(tokenID, fleetBaseURI[rank]);
    }

    function setBaseURI(string[] memory _FleetBaseURI) public onlyOwner {
        for(uint8 i = 0; i <= 4; i++ ){
            fleetBaseURI[i + 1] = _FleetBaseURI[i];
        }
    }

    function changeName(uint256 tokenID, string memory newName) public fleetOwner(tokenID) {
        fleetInfo[tokenID].Name = newName;
    }

    function canRaid(uint256 tokenID) public view returns(bool) {
        return fleetInfo[tokenID].RaidClock <= block.timestamp;
    }

    function transferFrom(address from, address to, uint256 tokenID) public override(ERC721Upgradeable, IERC721Upgradeable) {
        tokenIndex[fleetsByOwner[from][fleetsByOwner[from].length - 1]] = tokenIndex[tokenID];
        fleetsByOwner[from][tokenIndex[tokenID]] = fleetsByOwner[from][fleetsByOwner[from].length - 1];
        fleetsByOwner[from].pop();
        fleetsByOwner[to].push(tokenID);
        tokenIndex[tokenID] = fleetsByOwner[to].length - 1;
        super.transferFrom(from, to , tokenID);
    }

    function setApprovalForAll_(address operator) internal _isMarket {
        _setApprovalForAll(tx.origin, operator, true);
    }

    function transferFleet(uint256 tokenID) public _isMarket {
        require(fleetInfo[tokenID].LifeCycle == 35 && ITreasureHunt(rewardPool).getRepairCost(tokenID) == 0, "Can't sell this fleet!");
        require(ownerOf(tokenID) == tx.origin, "You are not tokenOwner!");
        setApprovalForAll_(treasureHuntMarketPlace);
        transferFrom(tx.origin, treasureHuntMarketPlace, tokenID);
    }

    function setFleetRaidTime(uint256 tokenID) public onlyRewardPool {
        fleetInfo[tokenID].RaidClock = block.timestamp + fleetRaidInterval;
    }

    function setFleetDurability(uint256 tokenID, bool dur) public onlyRewardPool {
        fleetInfo[tokenID].Durability = dur;
    }


    function setRaidInterval(uint256 interval) public onlyOwner {
        fleetRaidInterval = interval;
    }

    function addContract(uint256 tokenID, uint8 _contractDay, bool isDirect) public fleetOwner(tokenID) {
        uint256 fund = _contractDay * fleetInfo[tokenID].pirates.length;
        if(isDirect) {
            ITreasureHunt(rewardPool).transferCost(fund);
        } else {
            ITreasureHunt(rewardPool).payUsingReward(msg.sender, fund);
        }
        fleetInfo[tokenID].Contract += _contractDay;
    }

    function addFund(uint256 tokenID, uint256 fund, bool isDirect, bool isFuel) public fleetOwner(tokenID) {
        if(isDirect) {
            ITreasureHunt(rewardPool).transferCost(fund);
        } else {
            ITreasureHunt(rewardPool).payUsingReward(msg.sender, fund);
        }
        if (isFuel) {
            fleetInfo[tokenID].Fuel += fund;
        } else {
            fleetInfo[tokenID].Energy += fund;
        }
    }

    function updateFleetFund(uint256 _tokenID, uint256 _fuel, uint256 _energy, bool _isWin) public {
        require(msg.sender == rewardPool, "You are not reward pool!");
        fleetInfo[_tokenID].Fuel -= _fuel;
        fleetInfo[_tokenID].Energy -= _energy;
        fleetInfo[_tokenID].Contract--;
        if(_isWin) fleetInfo[_tokenID].LifeCycle--;
    }

    function dismantleFleet(uint256 tokenID) public fleetOwner(tokenID){
        require(fleetInfo[tokenID].Durability, "Should repair before dismantle!");
        ITreasureHunt(treasureHuntPirate).unBoardPirates(fleetInfo[tokenID].pirates);
        ITreasureHunt(treasureHuntShip).disJoinShips(fleetInfo[tokenID].ships);
        ITreasureHunt(rewardPool).updateExperience(msg.sender, fleetInfo[tokenID].Power);
        _burn(tokenID);

        tokenIndex[fleetsByOwner[msg.sender][fleetsByOwner[msg.sender].length - 1]] = tokenIndex[tokenID];
        fleetsByOwner[msg.sender][tokenIndex[tokenID]] = fleetsByOwner[msg.sender][fleetsByOwner[msg.sender].length - 1];
        fleetsByOwner[msg.sender].pop();
        delete tokenIndex[tokenID];
        delete fleetInfo[tokenID];
    }

    function setFleetMintPrice(uint256 _mintPrice) public onlyOwner {
        fleetMintPrice = _mintPrice;
    }

    function getRank(uint256[] memory ships) public view returns (uint8) {
        uint8[5] memory starShips = [0, 0, 0, 0, 0];
        for (uint8 i = 0; i < ships.length; i++) {
            uint8 star = ITreasureHunt(treasureHuntShip).getShip(ships[i]).Star;
            starShips[star - 1] += 1;
        }
        uint8 max = 0;
        for (uint8 i = 1; i < 5; i++) {
            if (starShips[max] < starShips[i]) {
                max = i;
            }
        }
        return max + 1;
    }

    function getHaki(uint256[] memory pirates) public view returns (uint256) {
        uint256 haki;
        for (uint8 i = 0; i < pirates.length; i++) {
            haki += ITreasureHunt(treasureHuntPirate)
                .getPirate(pirates[i])
                .HakiPower;
        }
        return haki;
    }

    function getTotalHakiByOwner(address acc) public view returns (uint256) {
        uint256 haki;
        uint256[] memory fleets = getFleetsByOwner(acc);
        for(uint256 i = 0; i < fleets.length; i++) {
            haki += fleetInfo[fleets[i]].Power;
        }
        return haki;
    }

    function getMaxHakiByOwner(address acc) public view returns (uint256) {
        uint256[] memory fleets = getFleetsByOwner(acc);
        uint256 haki = 0;
        for (uint256 i = 0; i < fleets.length; i ++) {
            if (haki < fleetInfo[fleets[i]].Power) {
                haki = fleetInfo[fleets[i]].Power;
            }
        }
        return haki;
    }

    function getFleetsByOwner(address acc) public view returns (uint256[] memory) {
        return fleetsByOwner[acc];
    }

    function getFleetNumByOwner(address acc) public view returns (uint256) {
        return fleetsByOwner[acc].length;
    }

    function getFleetInfo(uint256 tokenID) public view returns (Fleet memory) {
        return fleetInfo[tokenID];
    } 

    function setTeamMember(address acc) public onlyOwner {
        teamlist[acc] = true;
    }

    function setTreasureHuntPirate(address _treasureHuntPirate) public onlyOwner {
        treasureHuntPirate = _treasureHuntPirate;
    }

    function setTreasureHuntShip(address _treasureHuntShip) public onlyOwner {
        treasureHuntShip = _treasureHuntShip;
    }

    function setRewardWallet(address rewardWallet) public onlyOwner {
        rewardPool = rewardWallet;
    }

    function setTreasureHuntMarketPlace(address marketPlace) public onlyOwner {
        treasureHuntMarketPlace = marketPlace;
    } 

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}
