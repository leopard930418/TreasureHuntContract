// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


interface ITreasureHuntTrait {
    struct Pirate {
        string Name;
        uint256 TokenID;
        uint8 Star;
        uint256 HakiPower;
    }

    struct Ship {
        string Name;
        uint256 TokenID;
        uint8 Star;
    }

    struct Seaport {
        string Name;
        uint256 TokenID;
        uint8 Level;
        uint16 Capacity;
        uint16 Current;
    }

    struct Fleet {
        uint256 TokenID;
        string Name;
        uint256 Energy;
        uint8 Rank;
        uint8 Contract;
        uint256 Fuel;
        bool Durability;
        uint256 RaidClock;
        uint8 LifeCycle;
        uint256 Power;
        uint256[] ships;
        uint256[] pirates; 
    }

    struct Goods {
        uint256 TokenID;
        address Owner;
        uint256 Price;
    }
}
