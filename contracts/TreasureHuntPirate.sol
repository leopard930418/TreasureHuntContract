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

contract TreasureHuntPirate is Initializable, ITreasureHuntTrait, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    
    mapping(uint256 => Pirate) public pirateInfo; 
    mapping(address => uint256[]) internal activePiratesByOwner;
    mapping(address => uint256[]) internal inActivePiratesByOwner;
    mapping(uint256 => uint256) tokenIndex;
    mapping(uint256 => bool) isActivePirate;
    
    uint256 public mintPrice;
    uint256 public mintPresalePrice;
    uint256 public burnPrice;
    uint256 public giftFee;
    uint256 public presaleCnt;
    uint256 public presaleMintMax;
    mapping(address => uint256) public mysteryChestAmt;
    string public mysteryChestURI;
    mapping(uint8 => string) public pirateBaseURI;

    address public rewardPool;
    address public treasureHuntPicker;
    address public treasureHuntFleet;
    address public treasureHuntMarketPlace;
    mapping(address => bool) teamlist;

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

    event ReceiveGift(address sender, address receiver, uint16 amount);

    function initialize() public initializer {
        __ERC721_init("Pirate NFT", "PIRATE");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        presaleCnt = 0;
        presaleMintMax = 20000;
        mintPrice = 30;
        mintPresalePrice = 15;
        burnPrice = 5;
        teamlist[msg.sender] = true;
        giftFee = 5;
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
        ITreasureHunt(treasureHuntPicker).randomPirate(tokenID, name);
        activePiratesByOwner[to].push(tokenID);
        tokenIndex[tokenID] = activePiratesByOwner[to].length - 1;
        isActivePirate[tokenID] = true;
    }

    function setPirate(uint256 tokenID, uint8 star, uint16 power, string memory name) public {
        require(msg.sender == treasureHuntPicker, "You are not picker!");
        pirateInfo[tokenID] = Pirate(name, tokenID, star, power);
        string memory uri = pirateBaseURI[star];
        _setTokenURI(tokenID, uri);
    }

    function getPirate(uint256 tokenID) public view returns(Pirate memory) {
        return pirateInfo[tokenID];
    }

    function getPirates(uint256[] memory tokenIDs) public view returns(Pirate[] memory) {
        require(msg.sender == treasureHuntFleet, "You are not Fleet!");
        Pirate[] memory pirates;
        for(uint8 i = 0; i < tokenIDs.length; i++){
            pirates[i] = pirateInfo[tokenIDs[i]];
        }
        return pirates;
    }

    function getPirateInfo(uint256 tokenID) public view returns (Pirate memory) {
        require(msg.sender == ownerOf(tokenID), "You are not the pirate owner!");
        Pirate memory pirate = pirateInfo[tokenID];
        return pirate;
    } 

    function activePirates(address acc) public view returns(uint256[] memory) {
        return activePiratesByOwner[acc];
    }

    function inActivePirates(address acc) public view returns(uint256[] memory) {
        return inActivePiratesByOwner[acc];
    }

    function setBaseURI(string[] memory _pirateBaseURI) public onlyOwner {
        for(uint8 i = 0; i <= 4; i++ ){
            pirateBaseURI[i + 1] = _pirateBaseURI[i];
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

    function setApprovalForAll_(address operator) internal _isApprover {
        _setApprovalForAll(tx.origin, operator, true);
    }

    function boardPirates(uint256[] memory tokenIDs) public _isFleet {
        setApprovalForAll_(treasureHuntFleet);
        for(uint256 i = 0; i < tokenIDs.length; i++) {
            transferFrom(tx.origin, treasureHuntFleet, tokenIDs[i]);
        }
    }

    function unBoardPirates(uint256[] memory pirates) public _isFleet {
        for (uint256 i = 0; i < pirates.length; i++) {
            isActivePirate[pirates[i]] = false;
            transferFrom(treasureHuntFleet, tx.origin, pirates[i]);
            activePiratesByOwner[tx.origin].pop();
            inActivePiratesByOwner[tx.origin].push(pirates[i]);
            tokenIndex[pirates[i]] = inActivePiratesByOwner[tx.origin].length - 1;
        }
    }

    function transferPirate(uint256 tokenID) public _isMarket {
        require(isActivePirate[tokenID], "Can't sell this Pirate");
        require(ownerOf(tokenID) == tx.origin, "You are not tokenOwner!");
        setApprovalForAll_(treasureHuntMarketPlace);
        transferFrom(tx.origin, treasureHuntMarketPlace, tokenID);
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

    function transferFrom(address from, address to, uint256 tokenID) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(ownerOf(tokenID) == from, "You are not the nft owner!");
        require(isActivePirate[tokenID], "Can't transfer inactive pirate!");
        tokenIndex[activePiratesByOwner[from][activePiratesByOwner[from].length - 1]] = tokenIndex[tokenID];
        activePiratesByOwner[from][tokenIndex[tokenID]] = activePiratesByOwner[from][activePiratesByOwner[from].length - 1];
        activePiratesByOwner[from].pop();
        activePiratesByOwner[to].push(tokenID);
        tokenIndex[tokenID] = activePiratesByOwner[to].length - 1;
        super.transferFrom(from, to , tokenID);
    }

    function airdrop(address[] memory accounts, uint8[] memory cnts) public onlyOwner {
        require(accounts.length == cnts.length, "Invalid Parameters");
        for (uint i; i < accounts.length; i ++) {
            mysteryChestAmt[accounts[i]] += cnts[i];
        }
    }

    function burnPirates(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++){
            require(ownerOf(tokenIDs[i]) == msg.sender, "You are not Owner!");
            require(!isActivePirate[tokenIDs[i]], "Only can burn inactive pirates!");
            _burn(tokenIDs[i]);
            tokenIndex[inActivePiratesByOwner[msg.sender][inActivePiratesByOwner[msg.sender].length - 1]] = tokenIndex[tokenIDs[i]];
            inActivePiratesByOwner[msg.sender][tokenIndex[tokenIDs[i]]] = inActivePiratesByOwner[msg.sender][inActivePiratesByOwner[msg.sender].length - 1];
            inActivePiratesByOwner[msg.sender].pop();
            delete pirateInfo[tokenIDs[i]];
            delete tokenIndex[tokenIDs[i]];
        }
        ITreasureHunt(rewardPool).transferBurnReward(msg.sender, burnPrice * tokenIDs.length);
    }

    function setTeamMember(address acc) public onlyOwner {
        teamlist[acc] = true;
    }
    
    function setTreasureHuntPicker(address picker) public onlyOwner {
        treasureHuntPicker = picker;
    }

    function setTreasureHuntFleet(address fleet) public onlyOwner {
        treasureHuntFleet = fleet;
    }

    function setRewardWallet(address _rewardWallet) public onlyOwner {
        rewardPool = _rewardWallet;
    }

    function setTreasureHuntMarketPlace(address _marketPlace) public onlyOwner {
        treasureHuntMarketPlace = _marketPlace;
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