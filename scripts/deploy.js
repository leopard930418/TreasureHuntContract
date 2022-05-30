const { ethers, upgrades } = require('hardhat');

async function main () {
  const Pirate = await ethers.getContractFactory('TreasureHuntPirate');
  const PirateContract = await upgrades.deployProxy(Pirate, [], { initializer: 'initialize' });
  console.log('Pirate deployed to:', PirateContract.address);
  const Ship = await ethers.getContractFactory('TreasureHuntShip');
  const ShipContract = await upgrades.deployProxy(Ship, [], { initializer: 'initialize' });
  console.log('Ship deployed to:', ShipContract.address);
  const Seaport = await ethers.getContractFactory('TreasureHuntSeaport');
  const SeaportContract = await upgrades.deployProxy(Seaport, [], { initializer: 'initialize' });
  console.log('Seaport deployed to:', SeaportContract.address);
  const Fleet = await ethers.getContractFactory('TreasureHuntFleet');
  const FleetContract = await upgrades.deployProxy(Fleet, [PirateContract.address, ShipContract.address], { initializer: 'initialize' });
  console.log('Fleet deployed to:', FleetContract.address);
  const Picker = await ethers.getContractFactory('TreasureHuntPicker');
  const PickerContract = await upgrades.deployProxy(Picker, [PirateContract.address, ShipContract.address], { initializer: 'initialize' });
  console.log('Picker deployed to:', PickerContract.address);
  const Reward = await ethers.getContractFactory('TreasureHuntRewardPool');
  const RewardContract = await upgrades.deployProxy(Reward, [FleetContract.address, PickerContract.address], { initializer: 'initialize' });
  console.log('Reward deployed to:', RewardContract.address);

  const Market = await ethers.getContractFactory('TreasureHuntMarketPlace');
  const MarketContract = await upgrades.deployProxy(Market, [PirateContract.address, ShipContract.address, SeaportContract.address, FleetContract.address, RewardContract.address], { initializer: 'initialize' });
  console.log('Market deployed to:', MarketContract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});