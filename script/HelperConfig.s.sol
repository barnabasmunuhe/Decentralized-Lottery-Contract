<<<<<<< HEAD
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_ETH_CHAINID = 11155111;
    uint256 public constant LOCAL_ANVIL_CHAINID = 31337;

    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is Script, CodeConstants {
    // ===== Errors =====
    error Raffle__InvalidChainID(uint256 chainId);

    constructor() {
        networkConfigs[SEPOLIA_ETH_CHAINID] = getSepoliaEthConfig();
        // networkConfigs[LOCAL_ANVIL_CHAINID] = getAnvilEthConfig();
    }

    VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock;
=======
//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock Values*/
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK/ETH price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();
>>>>>>> 236a13eaa1accebbb8ea253dc8637e0ac9c445df

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
<<<<<<< HEAD
        address _vrfCoordinator;
        uint64 subscriptionId;
        bytes32 gasLane;
    }

    NetworkConfig public localNetworkConfig; // for our local chain Anvil
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; // remapping NetworkConfig struct to the chains

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId]._vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_ANVIL_CHAINID) {
            return getAnvilEthConfig();
        } else {
            revert Raffle__InvalidChainID(chainId);
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //seconds
            _vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId: 0, //we'll come back
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
        });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        // check if we are set to any config
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //seconds
            _vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            // doesn't matter
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0 //we'll come back
=======
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callBackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid); // This is a getter function
        // similar to the getter functions in Raffle main contract but this one is in this HelperConfig contract.
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callBackGasLimit: 500000, // 500,000 gas
                subscriptionId: 0,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x002AC9eA2939aA21E0b6231D74494dc4DA7f9f33
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, //1e16
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock),
            // doesn't matter
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callBackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0, // might have to fix this
            link: address(linkToken), // getting the link token address in our config
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
>>>>>>> 236a13eaa1accebbb8ea253dc8637e0ac9c445df
        });
        return localNetworkConfig;
    }
}
