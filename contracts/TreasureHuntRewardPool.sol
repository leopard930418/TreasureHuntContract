// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasureHunt.sol";

contract TreasureHuntRewardPool is Initializable, OwnableUpgradeable {
    
    uint256 devAmt;
    address devWallet;
    address devWallet1;

    mapping(address => uint256) lastRaidTime;
    mapping(address => uint256) reward;
    mapping(address => uint256) totalReward;
    mapping(uint256 => uint256) repairCost;
    mapping(uint256 => uint8) fleetRaidNum;

    mapping(address => bool) isReleaser;

    uint8 public islandNum;
    mapping(uint8 => uint256) islandsReward;
    mapping(uint8 => mapping(uint8 => uint8)) winPercentage;
    mapping(address => bool) playerDoubleWin;
    mapping(address => bool) playerRaidState;
    mapping(address => uint8) playerWinIsland;

    mapping(address => uint8) playerLevel;
    mapping(address => uint256) playerExp;
    mapping(uint8 => uint32) levelExp;
    mapping(uint8 => uint8) bonus;

    mapping(address => uint256) timeToWithdraw;
    uint256 public withdrawInterval;

    uint8 public fuelPercent;
    uint8 public energyPercent;
    uint8 public repairPercent;

    uint8 public rewardPercentForDev;
    uint8 public rewardFeePercent;
    uint8 public marketPercent;
    uint8 public marketCancelPercent;

    uint8 public dailyPercentForSeaport;
    uint8 public dailyPercentForRewardPool;

    uint8 public seaportClaimFee;
    uint8 public sesaportClaimFeeForDev;
    uint8 public playerClaimPoolFee;
    uint8 public playerClaimDevFee;

    address public treasureHuntFleet;
    address public treasureHuntPicker;
    address public treasureHuntMarketPlace;
    address public tokenUSDT;

    uint256 public lockTime;

    uint8 public decimal;

    bool public seaportActivate;
    uint256 public passiveIncomeThreshold;

    uint16 public islandHakiUnit;

    modifier onlyReleaser(address acc) {
        require(isReleaser[acc], "You are not a releaser!");
        _;
    }

    modifier onlyFleet(address acc) {
        require(acc == treasureHuntFleet, "You are not Fleet!");
        _;
    }

    modifier onlyWinner(address acc) {
        require(playerRaidState[acc], "You are not winner!");
        _;
    }

    modifier onlyMarket {
        require(msg.sender == treasureHuntMarketPlace, "You are not Market!");
        _;
    }

    modifier enoughFund(uint256 tokenID, uint8 islandNumber) {
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Fuel >= islandsReward[islandNumber] * fuelPercent / 100, "You don't have enough fuel!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Energy >= islandsReward[islandNumber] * energyPercent / 100, "You don't have enough energy!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).LifeCycle > 0, "Can't use this fleet anymore!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Contract > 0, "You have no Contract!");
        require(ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Power > islandHakiUnit * islandNumber, "You don't have enough haki power!");
        _;
    }

    modifier onSeaport(address player) {
        require(ITreasureHunt(treasureHuntFleet).isOnSeaport(player), "You are not on seaport!");
        _;
    }

    function initialize(address _treasureHuntFleet, address _treasureHuntPicker) public initializer {
        __Ownable_init();
        islandNum = 50;
        treasureHuntPicker = _treasureHuntPicker;
        treasureHuntFleet = _treasureHuntFleet;
        // decimal = 6; //mainnet
        decimal = 18; //testnet
        
        fuelPercent = 15;
        energyPercent = 15;
        repairPercent = 20;

        rewardPercentForDev = 20;
        rewardFeePercent = 20;
        marketPercent = 20;
        marketCancelPercent = 5;

        dailyPercentForSeaport = 2;
        dailyPercentForRewardPool = 1;

        seaportClaimFee= 15;
        sesaportClaimFeeForDev = 8;
        playerClaimPoolFee= 5;
        playerClaimDevFee= 2;

        withdrawInterval = 7 days;

        levelExp[1] = 10000;
        levelExp[2] = 30000;
        levelExp[3] = 50000;
        levelExp[4] = 75000;
        levelExp[5] = 100000;

        bonus[0] = 0;
        bonus[1] = 10;
        bonus[2] = 15;
        bonus[3] = 20;
        bonus[4] = 25;
        bonus[5] = 30;

        // tokenUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;  //mainnet
        tokenUSDT = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62; //testnet
        
        seaportActivate = false;
        passiveIncomeThreshold = 10000;
        islandHakiUnit = 100;

        devWallet = 0x8E87655fa89f791c89e2c949333A35593DB6c610;
        devWallet1 = 0x7A419820688f895973825D3cCE2f836e78Be1eF4;

        lockTime = block.timestamp + 5 * 365 days;
    }

    function initlevelExp(uint32[] memory exps) public onlyOwner {
        require(exps.length == 5, "Incorrect length!");
        for(uint8 i; i < exps.length; i++) {
            levelExp[i + 1] = exps[i];
        }
    }

    function initBonus(uint8[] memory bonuses) public onlyOwner {
        require(bonuses.length == 5, "Incorrect length!");
        for(uint8 i; i < bonuses.length; i++) {
            bonus[i + 1] = bonuses[i];
        }
    }

    //raid island logic
    function initWinPercentage(
        uint8[] memory percentD
        , uint8[] memory percentC
        , uint8[] memory percentB
        , uint8[] memory percentA
        , uint8[] memory percentS
    ) public onlyOwner{
        require(percentD.length == islandNum, "Enter correct D number!");
        require(percentC.length == islandNum, "Enter correct C number!");
        require(percentB.length == islandNum, "Enter correct B number!");
        require(percentA.length == islandNum, "Enter correct A number!");
        require(percentS.length == islandNum, "Enter correct S number!");
        
        for (uint8 i; i < islandNum; i++) {
            winPercentage[i][1] = percentD[i];
            winPercentage[i][2] = percentC[i];
            winPercentage[i][3] = percentB[i];
            winPercentage[i][4] = percentA[i];
            winPercentage[i][5] = percentS[i];
        }
    }

    function initIslandRewards(uint16[] memory rewards) public onlyOwner {
        require(rewards.length == islandNum, "Enter correct number!");
        for(uint8 i; i < islandNum; i++) {
            islandsReward[i] = rewards[i] * (10 ** decimal);
        }
    }

    function getDecimal() public view returns(uint8) {
        return decimal;
    }

    function setFeePercents(uint8 fuelP, uint8 energyP, uint8 repairP) public onlyOwner {
        require(fuelP + energyP + repairP < 100, "Invalid value!");
        fuelPercent = fuelP;
        energyPercent = energyP;
        repairPercent = repairP;
    }

    function raidIsland(uint256 tokenID, uint8 islandNumber) public enoughFund(tokenID, islandNumber) onSeaport(msg.sender) {
        require( ITreasureHunt(treasureHuntFleet).canRaid(tokenID) , "You have to wait to raid!");
        ITreasureHunt(treasureHuntFleet).setFleetRaidTime(tokenID);

        uint256 random = ITreasureHunt(treasureHuntPicker).random(string(abi.encodePacked(tokenID)), islandNumber);

        uint8 rank = ITreasureHunt(treasureHuntFleet).getFleetInfo(tokenID).Rank;
        uint8 percentage = winPercentage[islandNumber][rank];

        uint8 chance = uint8(random % 100);

        uint256 fuel = islandsReward[islandNumber] * fuelPercent / 100;
        uint256 energy = islandsReward[islandNumber] * fuelPercent / 100;
        if(chance < percentage) {
            playerRaidState[msg.sender] = true;
            playerWinIsland[msg.sender] = islandNumber;

            ITreasureHunt(treasureHuntFleet).updateFleetFund(tokenID, fuel, energy, true);
        } else {
            playerRaidState[msg.sender] = false;
            ITreasureHunt(treasureHuntFleet).updateFleetFund(tokenID, fuel, energy, false);
        }

        repairCost[tokenID] += islandsReward[islandNumber] * repairPercent / 100;
        fleetRaidNum[tokenID] ++;
        if (fleetRaidNum[tokenID] == 5) {
            ITreasureHunt(treasureHuntFleet).setFleetDurability(tokenID, false);
        }

        lastRaidTime[msg.sender] = block.timestamp;
    }

    function readFleetRaidNumber(uint256 tokenID) public view returns(uint8) {
        return fleetRaidNum[tokenID];
    }

    function getRepairCost(uint256 tokenID) public view returns(uint256) {
        return repairCost[tokenID];
    }

    function repairFleet(uint256 tokenID, bool isDirect) public {
        require(fleetRaidNum[tokenID] >= 5, "No need to repair for now!");
        if (isDirect) {
            transferCost(repairCost[tokenID]);
        } else {
            payUsingReward(msg.sender, repairCost[tokenID]);
        }
        fleetRaidNum[tokenID] = 0;
        ITreasureHunt(treasureHuntFleet).setFleetDurability(tokenID, true);
    }

    function getFleetRaidNum(uint256 tokenID) public view returns(uint8) {
        return fleetRaidNum[tokenID];
    }

    function isWin(address acc) public view returns(bool) {
        return playerRaidState[acc];
    }

    function normalReward(address acc) public onlyWinner(acc){
        uint256 nReward = islandsReward[playerWinIsland[acc]] * (100 + bonus[playerLevel[acc]]) / 100; 
        nReward = nReward * (10 ** decimal);
        reward[acc] += nReward;
        totalReward[acc] += nReward;
        updateRaidReward(acc, nReward);
    }

    function doubleReward(address acc) public onlyWinner(acc){
        uint256 random = ITreasureHunt(treasureHuntPicker).random(string(abi.encodePacked(block.coinbase)), block.gaslimit);
        uint8 chance = uint8(random % 100);
        if (chance < 50) {
            uint256 dReward = 2 * islandsReward[playerWinIsland[acc]] * (100 + bonus[playerLevel[acc]]) / 100; 
            dReward = dReward * (10 ** decimal);
            reward[acc] += dReward;
            totalReward[acc] += dReward;
            updateRaidReward(acc, dReward);
            playerDoubleWin[acc] = true;
        } else {
            playerDoubleWin[acc] = false;
        }
    }

    function seaportPassiveIncome(address acc) internal view returns(bool){
        uint256 power = ITreasureHunt(treasureHuntFleet).getTotalHakiByOwner(acc);
        return power >= passiveIncomeThreshold;
    }

    function setPassiveSeaportIncomeThreshold(uint256 threshold) public onlyOwner {
        passiveIncomeThreshold = threshold;
    }

    function isDoubleWin(address acc) public view returns(bool) {
        return playerDoubleWin[acc];
    }

    function getReward(address acc) public view returns(uint256) {
        return reward[acc];
    }

    function getTotalReward(address acc) public view returns(uint256) {
        return totalReward[acc];
    }

    function addReleaser(address acc) public onlyOwner {
        isReleaser[acc] = true;
    }

    function removeReleaser(address acc) public onlyOwner {
        isReleaser[acc] = false;
    }

    function payUsingReward(address acc, uint256 amt) public {
        uint256 realAmt = amt * (10 ** decimal) * (100 + rewardFeePercent) / 100;
        require(tx.origin == acc, "You are not owner of this fund!");
        require(reward[acc] >= realAmt, "Insufficient fund!");
        reward[acc] -= realAmt;
        devAmt += realAmt * rewardPercentForDev / 100;
    }

    function transferBurnReward(address acc, uint256 amt) public onlyReleaser(acc){
        uint256 realAmt = amt * (10 ** decimal);
        reward[acc] += realAmt;
    }

    function transferCost(uint256 amt) public {
        uint256 realAmt = amt * (10 ** decimal);
        require(IERC20(tokenUSDT).balanceOf(tx.origin) >= realAmt, "Insuffient USDC!");

        IERC20(tokenUSDT).transferFrom(tx.origin, address(this), realAmt);
        devAmt += realAmt * rewardPercentForDev / 100;
    }

    function buyNFT(uint256 amt, address to) public onlyMarket {
        uint256 realAmt = amt * (10 ** decimal);
        require(IERC20(tokenUSDT).balanceOf(tx.origin) >= realAmt, "Insuffient USDC!");

        uint256 fee = realAmt * marketPercent / 100;
        devAmt += fee * rewardPercentForDev / 100;
        IERC20(tokenUSDT).transferFrom(tx.origin, address(this), fee);
        IERC20(tokenUSDT).transferFrom(tx.origin, to, realAmt - fee);
    }

    function cancelNFT(uint256 amt) public onlyMarket {
        uint256 realAmt = amt * (10 ** decimal) * marketCancelPercent / 100;
        require(IERC20(tokenUSDT).balanceOf(tx.origin) >= realAmt, "Insuffient USDC!");

        devAmt += realAmt * rewardPercentForDev / 100;

        IERC20(tokenUSDT).transferFrom(tx.origin, address(this), realAmt);
    }

    function updateExperience(address acc, uint256 exp) public onlyFleet(msg.sender) {
        playerExp[acc] += exp;
        if (playerExp[acc] >= levelExp[playerLevel[acc] + 1]) {
            playerLevel[acc] ++;
        }
    }

    function readExperience(address acc) public view returns(uint256) {
        return playerExp[acc];
    }

    function readLevel(address acc) public view returns(uint8) {
        return playerLevel[acc];
    }

    function updateRaidReward(address acc, uint256 amt) private onSeaport(acc){
        if (!ITreasureHunt(treasureHuntFleet).isSeaportOwner(msg.sender)) {
            address ownerOfSeaport = ITreasureHunt(treasureHuntFleet).getSeaportOwnerByPlayer(acc);
            if (seaportActivate && seaportPassiveIncome(ownerOfSeaport)) {
                reward[ownerOfSeaport] += amt * dailyPercentForSeaport / 100;
            } 
            reward[acc] -= amt * (dailyPercentForSeaport + dailyPercentForRewardPool) / 100;
        }
    }

    function setSeaportActivate(bool act) public onlyOwner {
        seaportActivate = act;
    }

    function withdrawReward() public onSeaport(msg.sender) {
        require(timeToWithdraw[msg.sender] == 0 || block.timestamp >= timeToWithdraw[msg.sender], "Can't withdraw now!");
        require(reward[msg.sender] > 0, "No reward now!");
        timeToWithdraw[msg.sender] = block.timestamp + withdrawInterval;
        if(ITreasureHunt(treasureHuntFleet).isSeaportOwner(msg.sender)) {
            uint256 fee = reward[msg.sender] * seaportClaimFee / 100;
            reward[msg.sender] -= fee;
            devAmt += fee;
        } else {
            uint256 poolFee = reward[msg.sender] * playerClaimPoolFee / 100;
            uint256 devFee = reward[msg.sender] * playerClaimDevFee / 100;
            reward[msg.sender] -= (poolFee + devFee);
            devAmt += devFee;
        }
        totalReward[msg.sender] += reward[msg.sender];
        IERC20(tokenUSDT).transfer(msg.sender, reward[msg.sender]);
    }

    function withdrawTime() public view returns(uint256) {
        if (block.timestamp <= timeToWithdraw[msg.sender]) {
            return timeToWithdraw[msg.sender] - block.timestamp;
        } else {
            return 0;
        }
    }

    function setIslandHakiUint(uint16 unit) public onlyOwner {
        islandHakiUnit = unit;
    }

    function readHakiPower(uint8 islandNumber) public view returns(uint32) {
        return islandHakiUnit * islandNumber;
    }

    function setTreasureHuntFleet(address _treasureHuntFleet) public onlyOwner {
        treasureHuntFleet = _treasureHuntFleet;
    }

    function setTreasureHuntPicker(address _treasureHuntPicker) public onlyOwner {
        treasureHuntPicker = _treasureHuntPicker;
    }

    function setTreasureHuntMarketPlace(address _marketPlace) public onlyOwner {
        treasureHuntMarketPlace = _marketPlace;
    }

    function releaseReward() public onlyOwner {
        require(block.timestamp >= lockTime, "You can't release reward now!");
        IERC20(tokenUSDT).transfer(owner(), IERC20(tokenUSDT).balanceOf(address(this)));
    }

    function setRewardPercentForDev(uint8 percent) public onlyOwner {
        rewardPercentForDev = percent;
    }

    function releaseFee() public onlyOwner {
        IERC20(tokenUSDT).transfer(devWallet, devAmt * 3 / 4);
        IERC20(tokenUSDT).transfer(devWallet1, devAmt / 4);
        devAmt = 0;
    }
}