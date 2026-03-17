// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
// ===== Imports =====
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// ===== Errors =====
error Raffle__SendMoreEthToEnter();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 balance, uint256 numPlayers, uint256 raffleState);

/**
 * @author  . Barnabas Milton
 * @title   . A sample raffle contract
 * @dev     . Implements chainlink VRF v2.5
 * @notice  . This contract allows users to participate in a raffle and one final winner is picked.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Type Declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    // =====State Variables =====
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1; // we only need one random number
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint64 private immutable i_subscriptionId; // subscription ID that this contract uses for funding requests
    bytes32 private i_keyHash; // The gas lane to use, which specifies the maximum gas price to bump to.
    uint32 private i_callbackGasLimit;

    address payable[] private s_players; // keeps track of players
    address private s_recentWinner;
    uint256 private s_lastTimeStamp; // keeps track of last time a winner was picked
    RaffleState private s_raffleState;

    // ===== Events =====
    event Raffle_PlayerEntered(address indexed player);
    event Raffle__winnerPicked(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address _vrfCoordinator, uint64 subscriptionId, bytes32 gasLane) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = gasLane;
        i_callbackGasLimit = 100000; // 100,000 gas limit for the callback function
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnter();
        }
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();

        }

        s_players.push(payable(msg.sender)); //its payable for to have an address receive ETH

        emit Raffle_PlayerEntered(msg.sender);
    }

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasETH = address(this).balance > 0;
        bool stateOfRaffle = s_raffleState == RaffleState.OPEN;

        upkeepNeeded = timeHasPassed && hasPlayers && hasETH && stateOfRaffle; // if any of these fails there upKeep will fail.
        return (upkeepNeeded, "");
    }

    /**
     * @notice  .Select random winner from the players array by getting a random number
     * @dev     .Will use chainlink VRF v2.5 to get a random number
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

            uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
    // what happens when Chainlink returns the random number
    uint256 winnerIndex = randomWords[0] % s_players.length;//here we get the winner after the random number is returned
    address payable recentWinner = s_players[winnerIndex];// identifying the winner to be paid in our S_players array
    s_recentWinner = recentWinner;
    s_raffleState = RaffleState.OPEN; // open up the raffle state
    s_players = new address payable[](0); // reset the players array for the next raffle round
    s_lastTimeStamp = block.timestamp;// resetting the time stamp

    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
        revert Raffle__TransferFailed();
    }
    emit Raffle__winnerPicked(recentWinner);
}


    // ===== Getter Functions =====
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
