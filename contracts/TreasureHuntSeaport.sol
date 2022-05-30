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
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract TreasureHuntSeaport is Initializable, ITreasureHuntTrait, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    address public constant Zero = 0x0000000000000000000000000000000000000000; 
    mapping(uint256 => Seaport) public seaportInfo; 
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private playersBySeaport;
    mapping(address => uint256) public onSeaport;
    mapping(uint8 => uint16) public seaportSizeByLevel; 

    //seaport owner setting
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private WL4Seaport;
    mapping(uint256 => uint256) private haki4Seaport;
    mapping(uint256 => bool) private acceptMod;  //true - whitelist  false - haki requirement

    uint256 public mintPrice;
    uint256 public presaleCnt;
    uint256 public saleCnt;
    uint256 public presaleMintMax;
    uint256 public totalMintMax;
    uint256 public kickPrice;
    string public SeaportBaseURI;

    mapping(address => uint256) public mysteryChestAmt;

    address public rewardPool;
    address public treasureHuntFleet;
    address public treasureHuntMarketPlace;

    modifier onlySeaportOwner(uint256 tokenID) {
        require(msg.sender == ownerOf(tokenID), "You are not the Seaport Owner!");
        _;
    }

    modifier _isMarket {
        require(msg.sender == treasureHuntMarketPlace, "You are not MarketPlace!");
        _;
    }

    event ExitSeaport(address account, uint256 tokenID);
    
    function initialize() public initializer {
        __ERC721_init("Seaport NFT", "SEAPORT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        presaleCnt = 0;
        presaleMintMax = 10;
        totalMintMax = 100;
        kickPrice = 10;

        seaportSizeByLevel[1] = 250;
        seaportSizeByLevel[2] = 500;
        seaportSizeByLevel[3] = 1000;
        seaportSizeByLevel[4] = 2000;
        seaportSizeByLevel[5] = 4000;
        seaportSizeByLevel[6] = 10000;
        seaportSizeByLevel[7] = 20000;

        mintPrice = 20000;
    }

    function presaleMint() public {
        require(!isSeaportOwner(msg.sender), "You already own seaport!");
        require(presaleCnt < presaleMintMax, "Presale End!");
        presaleCnt++;
        ITreasureHunt(rewardPool).transferCost(mintPrice);
        mysteryChestAmt[msg.sender] = 1;
    }

    function openBox(string memory name) public {
        require(mysteryChestAmt[msg.sender] > 0, "You have not enough chest!");
        mysteryChestAmt[msg.sender] = 0;
        mint(name);
    }

    function ownerMint(string memory name) public onlyOwner {
        require(saleCnt < totalMintMax, "Can't mint anymore!");
        mint(name);
    }

    function mint(string memory name) private {
        uint256 tokenID = totalSupply() + 1;
        _safeMint(msg.sender, tokenID);
        saleCnt += 1;
        initSeaport(tokenID, name);
    }

    function updateSeaportSize(uint8 num, uint16 size) public onlyOwner {
        seaportSizeByLevel[num] = size;
    }

    function changeName(uint256 tokenID, string memory name) public onlySeaportOwner(tokenID) {
        seaportInfo[tokenID].Name = name;
    }

    function join2Seaport(uint256 tokenID) public {
        require(!isOnSeaport(msg.sender), "You are already on the Seaport");
        require(seaportUseability(tokenID, msg.sender), "Can't join now!");

        playersBySeaport[tokenID].add(msg.sender);
        seaportInfo[tokenID].Current++;
        onSeaport[msg.sender] = tokenID;
    }

    function seaportUseability(uint256 tokenID, address account) public view returns(bool) {
        if (acceptMod[tokenID]) {
            return seaportInfo[tokenID].Current + 1 <= seaportInfo[tokenID].Capacity && WL4Seaport[tokenID].contains(account);
        } else {
            return seaportInfo[tokenID].Current + 1 <= seaportInfo[tokenID].Capacity && ITreasureHunt(treasureHuntFleet).getMaxHakiByOwner(account) >= haki4Seaport[tokenID];
        }
    }

    function writeWL4Seaport(uint256 tokenID, address[] memory _wl) public onlySeaportOwner(tokenID) {
        for(uint i; i < _wl.length; i++) {
            WL4Seaport[tokenID].add(_wl[i]);
        }
    }

    function setPermitOption(bool isWL, uint256 tokenID) public onlySeaportOwner(tokenID) {
        acceptMod[tokenID] = isWL;
    }

    function kickFromSeaport(address user, uint256 tokenID, bool isDirect) public {
        require(playersBySeaport[tokenID].contains(user), "He is not on the Seaport");
        if (isDirect) {
            ITreasureHunt(rewardPool).transferCost(kickPrice);
        } else {
            ITreasureHunt(rewardPool).payUsingReward(msg.sender, kickPrice);
        }
        playersBySeaport[tokenID].remove(user);
        seaportInfo[tokenID].Current--;
        delete onSeaport[user];

        emit ExitSeaport(user, tokenID);
    }

    function exitFromSeaport(uint256 tokenID, bool isDirect) public {
        require(playersBySeaport[tokenID].contains(msg.sender), "You are not on the Seaport");
        if (isDirect) {
            ITreasureHunt(rewardPool).transferCost(kickPrice);
        } else {
            ITreasureHunt(rewardPool).payUsingReward(msg.sender, kickPrice);
        }
        playersBySeaport[tokenID].remove(msg.sender);
        seaportInfo[tokenID].Current--;
        delete onSeaport[msg.sender];

        emit ExitSeaport(msg.sender, tokenID);
    }

    function playersOnSeaport(uint256 tokenID) public view returns(uint256) {
        return playersBySeaport[tokenID].length();
    }

    function playersOfSeaport(uint256 tokenID) public view returns(address[] memory) {
        return playersBySeaport[tokenID].values();
    }

    function getHaki4Seaport(uint256 tokenID) public view returns(uint256) {
        return haki4Seaport[tokenID];
    }

    function setHaki4Seaport(uint256 tokenID, uint256 power) public onlySeaportOwner(tokenID) {
        haki4Seaport[tokenID] = power;
    }

    function getTotalHakiOfSeaport(uint256 tokenID) public view returns(uint256) {
        uint256 haki = 0;
        for(uint i; i < playersBySeaport[tokenID].length(); i++) {
            haki += ITreasureHunt(treasureHuntFleet).getTotalHakiByOwner(playersBySeaport[tokenID].at(i));
        }
        return haki;
    }

    function setApprovalForAll_(address operator) internal _isMarket {
        _setApprovalForAll(tx.origin, operator, true);
    }

    function transferSeaport(uint256 tokenID) public _isMarket {
        require(ownerOf(tokenID) == tx.origin, "You are not tokenOwner!");
        setApprovalForAll_(treasureHuntMarketPlace);
        transferFrom(tx.origin, treasureHuntMarketPlace, tokenID);
    }

    function initSeaport(uint256 tokenID, string memory name) internal {
        seaportInfo[tokenID] = Seaport(name, tokenID, 1, seaportSizeByLevel[1], 0);
        string memory uri = string(abi.encodePacked(SeaportBaseURI, StringsUpgradeable.toString(tokenID)));
        _setTokenURI(tokenID, uri);
    }

    function isSeaportOwner(address acc) public view returns(bool) {
        return  balanceOf(acc) > 0;
    }

    function isOnSeaport(address acc) public view returns(bool) {
        return onSeaport[acc] != 0 || isSeaportOwner(acc);
    }

    function isMarketPlace(address acc) public view returns(bool) {
        return acc == treasureHuntMarketPlace;
    }

    function getSeaportOwnerByPlayer(address acc) public view returns(address) {
        require(isOnSeaport(acc), "This user is not on Seaport!");
        return ownerOf(onSeaport[acc]);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(isSeaportOwner(from) && (!isSeaportOwner(to) || isMarketPlace(to)), "Can't transfer Seaport!"); 
        super.transferFrom(from, to, tokenId);
    }

    function setBaseURI(string memory _SeaportBaseURI) public onlyOwner {
        SeaportBaseURI = _SeaportBaseURI;
    }
    
    function setPresaleCnt(uint256 _presaleCnt) public onlyOwner {
        presaleCnt = _presaleCnt;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setRewardWallet(address rewardWallet) public onlyOwner {
        rewardPool = rewardWallet;
    }
    
    function setTreasureHuntFleet(address _treasureHuntFleet) public onlyOwner {
        treasureHuntFleet = _treasureHuntFleet;
    }

    function setTreasureHuntMarketPlace(address marketPlace) public onlyOwner {
        treasureHuntMarketPlace = marketPlace;
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