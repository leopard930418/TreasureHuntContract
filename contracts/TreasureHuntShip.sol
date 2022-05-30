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
contract TreasureHuntShip is Initializable, ITreasureHuntTrait, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    
    mapping(uint256 => Ship) public shipInfo; 
    mapping(address => uint256[]) internal activeShipsByOwner;
    mapping(address => uint256[]) internal inActiveShipsByOwner;
    mapping(uint256 => uint256) tokenIndex;
    mapping(uint256 => bool) isActiveShip;
    
    uint256 public mintPrice;
    uint256 public mintPresalePrice;
    uint256 public burnPrice;
    uint256 public giftFee;
    uint256 public presaleCnt;
    uint256 public presaleMintMax;
    string public mysteryChestURI;
    mapping(uint8 => string) public ShipBaseURI;

    address public treasureHuntPicker;
    address public treasureHuntFleet;
    address public rewardPool;
    address public treasureHuntMarketPlace;
    mapping(address => bool) teamlist;

    mapping(address => uint256) public mysteryChestAmt;
    event ReceiveGift(address sender, address receiver, uint16 amount);

    function initialize() public initializer {
        __ERC721_init("Ship NFT", "SHIP");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        presaleCnt = 0;
        presaleMintMax = 20000;

        mintPrice = 30;
        mintPresalePrice = 15;
        burnPrice = 5;

        teamlist[msg.sender] = true;
    }

    modifier _isFleet {
        require(msg.sender == treasureHuntFleet, "You are not Fleet!");
        _;
    }
    
    modifier _isMarket {
        require(msg.sender == treasureHuntMarketPlace, "You are not MarketPlace!");
        _;
    }

    modifier _isApprover {
        require(msg.sender == treasureHuntFleet || msg.sender == treasureHuntMarketPlace, "You are not Approver!");
        _;
    }
    function massMint(bool presale, uint8 amt) public {
        require(amt <= 10, "Can't exeed 10!");
        require(!presale || (presale && presaleCnt + amt <= presaleMintMax), "Can't mint that amounts!");

        uint256 price = presale ? mintPresalePrice : mintPrice;

        if (!teamlist[msg.sender]) {
            ITreasureHunt(rewardPool).transferCost(price * amt);
        }

        mysteryChestAmt[msg.sender] += amt;
        if (presale) {
            presaleCnt += amt;
        }
    }

    function openBox(uint16 amt, string[] memory names) public {
        require(mysteryChestAmt[msg.sender] >= amt, "You have not enough chest!");
        require(amt == names.length, "Invalid parameters!");
        for (uint8 i = 0; i < amt; i ++) {
            uint256 tokenID = totalSupply() + 1;
            mint(msg.sender, tokenID, names[i]);
        }
        mysteryChestAmt[msg.sender] -= amt;
    }

    function mint(address to, uint256 tokenID, string memory name) internal {
        _safeMint(to, tokenID);
        ITreasureHunt(treasureHuntPicker).randomShip(tokenID, name);
        activeShipsByOwner[to].push(tokenID);
        tokenIndex[tokenID] = activeShipsByOwner[to].length - 1;
        isActiveShip[tokenID] = true;
    }

    function getShip(uint256 tokenID) public view returns(Ship memory) {
        require(msg.sender == treasureHuntFleet, "You are not Fleet!");
        return shipInfo[tokenID];
    }

    function getShips(uint256[] memory tokenIDs) view public returns(Ship[] memory) {
        require(msg.sender == treasureHuntFleet, "You are not Fleet!");
        Ship[] memory ships;
        for(uint8 i = 0; i < tokenIDs.length; i++){
            ships[i] = shipInfo[tokenIDs[i]];
        }
        return ships;
    }

    function airdrop(address[] memory accounts, uint8[] memory cnts) public onlyOwner {
        require(accounts.length == cnts.length, "Invalid Parameters");
        for (uint i; i < accounts.length; i ++) {
            mysteryChestAmt[accounts[i]] += cnts[i];
        }
    }

    function activeShips(address acc) public view returns(uint256[] memory) {
        return activeShipsByOwner[acc];
    }

    function inActiveShips(address acc) public view returns(uint256[] memory) {
        return inActiveShipsByOwner[acc];
    }

    function giveGift(address receiver, uint16 amount, bool isDirect) public {
        require(amount > 0 && mysteryChestAmt[msg.sender] >= amount, "Can't gift chests!");

        if (isDirect) {
            ITreasureHunt(rewardPool).transferCost(giftFee * amount);
        } else {
            ITreasureHunt(rewardPool).payUsingReward(msg.sender, giftFee * amount);
        }
        
        mysteryChestAmt[msg.sender] -= amount;
        mysteryChestAmt[receiver] += amount;

        emit ReceiveGift(msg.sender, receiver, amount);
    }

    function getShipInfo(uint256 tokenID) public view returns (Ship memory) {
        require(msg.sender == ownerOf(tokenID), "You are not the ship owner!");
        Ship memory ship = shipInfo[tokenID];
        return ship;
    } 

    function setShip(uint256 tokenID, uint8 star, string memory name) public {
        require(msg.sender == treasureHuntPicker, "You are not picker!");
        shipInfo[tokenID] = Ship(name, tokenID, star);
        string memory uri = ShipBaseURI[star];
        _setTokenURI(tokenID, uri);
    }

    function setTreasureHuntPicker(address _treasureHuntPicker) public onlyOwner {
        treasureHuntPicker = _treasureHuntPicker;
    }

    function setTreasureHuntFleet(address _treasureHuntFleet) public onlyOwner {
        treasureHuntFleet = _treasureHuntFleet;
    }

    function setRewardWallet(address _rewardWallet) public onlyOwner {
        rewardPool = _rewardWallet;
    }

    function setTreasureHuntMarketPlace(address _marketPlace) public onlyOwner {
        treasureHuntMarketPlace = _marketPlace;
    }

    function setBaseURI(string[] memory _ShipBaseURI) public onlyOwner {
        for(uint8 i = 0; i <= 4; i++ ){
            ShipBaseURI[i + 1] = _ShipBaseURI[i];
        }
    }
    
    function setMysteryURI(string memory _mysteryChestURI) public onlyOwner {
        mysteryChestURI = _mysteryChestURI;
    }

    function setPresaleCnt(uint256 _presaleCnt) public onlyOwner {
        presaleCnt = _presaleCnt;
    }

    function setMintPresalePrice(uint256 _mintPresalePrice) public onlyOwner {
        mintPresalePrice = _mintPresalePrice;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBurnPrice(uint256 _burnPrice) public onlyOwner {
        burnPrice = _burnPrice;
    }

    function setGiftFee(uint256 _giftFee) public onlyOwner {
        giftFee = _giftFee;
    }

    function setTeamMember(address acc) public onlyOwner {
        teamlist[acc] = true;
    }

    function setApprovalForAll_(address operator) internal _isApprover {
        _setApprovalForAll(tx.origin, operator, true);
    }

    function joinShips(uint256[] memory tokenIDs) public _isFleet {
        setApprovalForAll_(treasureHuntFleet);
        for(uint256 i = 0; i < tokenIDs.length; i++) {
            transferFrom(tx.origin, treasureHuntFleet, tokenIDs[i]);
        }
    }

    function disJoinShips(uint256[] memory ships) public _isFleet {
        for (uint256 i = 0; i < ships.length; i++) {
            isActiveShip[ships[i]] = false;
            transferFrom(treasureHuntFleet, tx.origin, ships[i]);
            activeShipsByOwner[tx.origin].pop();
            inActiveShipsByOwner[tx.origin].push(ships[i]);
            tokenIndex[ships[i]] = inActiveShipsByOwner[tx.origin].length - 1;
        }
    }

    function transferShip(uint256 tokenID) public _isMarket {
        require (isActiveShip[tokenID], "Can't sell this ship!");
        require(ownerOf(tokenID) == tx.origin, "You are not tokenOwner!");
        setApprovalForAll_(treasureHuntMarketPlace);
        transferFrom(tx.origin, treasureHuntMarketPlace, tokenID);
    }
    
    function burnShips(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++){
            require(ownerOf(tokenIDs[i]) == msg.sender, "You are not Owner!");
            require(!isActiveShip[tokenIDs[i]], "Only can burn inactive ships!");

            _burn(tokenIDs[i]);

            tokenIndex[inActiveShipsByOwner[msg.sender][inActiveShipsByOwner[msg.sender].length - 1]] = tokenIndex[tokenIDs[i]];
            inActiveShipsByOwner[msg.sender][tokenIndex[tokenIDs[i]]] = inActiveShipsByOwner[msg.sender][inActiveShipsByOwner[msg.sender].length - 1];
            inActiveShipsByOwner[msg.sender].pop();
            delete shipInfo[tokenIDs[i]];
            delete tokenIndex[tokenIDs[i]];
        }

        ITreasureHunt(rewardPool).transferBurnReward(msg.sender, burnPrice * tokenIDs.length);
    }

    function transferFrom(address from, address to, uint256 tokenID) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(isActiveShip[tokenID], "Can't transfer inactive ship!");
        tokenIndex[activeShipsByOwner[from][activeShipsByOwner[from].length - 1]] = tokenIndex[tokenID];
        activeShipsByOwner[from][tokenIndex[tokenID]] = activeShipsByOwner[from][activeShipsByOwner[from].length - 1];
        activeShipsByOwner[from].pop();
        activeShipsByOwner[to].push(tokenID);
        tokenIndex[tokenID] = activeShipsByOwner[to].length - 1;
        super.transferFrom(from, to , tokenID);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
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