// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants{
    uint256 public constant SEPOLIA_ETH_CHAINID = 11155111;
    uint256 public constant LOCAL_ANVIL_CHAINID = 31337;

    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;       
}

contract HelperConfig is Script,  CodeConstants{
    // ===== Errors =====
    error Raffle__InvalidChainID(uint256 chainId);

    constructor(){
        networkConfigs[SEPOLIA_ETH_CHAINID] = getSepoliaEthConfig();
        // networkConfigs[LOCAL_ANVIL_CHAINID] = getAnvilEthConfig();
    }

    VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock;

    struct NetworkConfig{
        uint256 entranceFee; 
        uint256 interval;
        address _vrfCoordinator;
        uint64 subscriptionId;
        bytes32 gasLane;
    }

    NetworkConfig public localNetworkConfig;// for our local chain Anvil
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; // remapping NetworkConfig struct to the chains

 function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
    if(networkConfigs[chainId]._vrfCoordinator != address(0)) 
    return networkConfigs[chainId];
    else if(chainId == LOCAL_ANVIL_CHAINID)
    {
        return getAnvilEthConfig();
    }
    else {
        revert Raffle__InvalidChainID(chainId);
    }
 }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30, //seconds
            _vrfCoordinator : 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId : 0, //we'll come back
            gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
        });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory){
        // check if we are set to any config
        if(localNetworkConfig._vrfCoordinator != address(0))
        return localNetworkConfig;

        vm.startBroadcast();
    vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
    MOCK_BASE_FEE,
    MOCK_GAS_PRICE_LINK,
    MOCK_WEI_PER_UNIT_LINK
    );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30, //seconds
            _vrfCoordinator : address(vrfCoordinatorV2_5Mock),
            // doesn't matter
            gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 0 //we'll come back
        });
        return localNetworkConfig;
    }
    
}