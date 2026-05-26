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
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    VRFV2PlusClient
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/*Errors*/
error Raffle__SendMoreToEnterRaffle();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded( // this error will return the details listed below.
    uint256 balance, uint256 playersLength, uint256 RaffleState
);

/**
 * @title Raffle contract
 * @author Barnabas Mwangi
 * @notice Contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Type Declarations
     */
    //Enums can be used to create custom types
    //  with a finite set of constant values.
    // -are explicitly convertibe to and from all integer types
    //  but implicit conversion is not allowed
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /**
     * state variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_RaffleState; //start as open

    // EVENTS
    event RaffleEntered(address indexed player);
    event winnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_RaffleState = RaffleState.OPEN;
        // s_RaffleState = RaffleState.CALCULATING;
    }

    function enterRaffle() external payable {
        if (msg.value >= i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        // OPTION B for 0.8.26 versions of solidity and above and still not that gas efficient
        // require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());

        if (s_RaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));// adds players to the lottery who have called enterRaffle function 
        // 1. Makes migration easier
        // 2. Makes front end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // CHAINLINK AUTOMATION IMPLEMENTATION
    /**
     * Determins when the winner should be picked
     */
    /**
     * @dev This is the function that Chainlink nodes will call to see
     * if the lottery is ready to have a winner picked.
     * The following should be true inorder for the upkeepNeeded to be true.
     * 1.Time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH(has players)
     * 4. Implicitly your subscription has LINK
     * @param -ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     */
    function checkUpkeep(
        bytes memory /* checkData*/
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool timeHaspassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_RaffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHaspassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    // 1. Get a random number
    // 2. Use random number to pick a player
    // 3. Be automatically called
    function performUpkeep(
        bytes calldata /*performData*/
    )
        external
    {
        // Check to see if enough time has passed
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_RaffleState));
        }

        s_RaffleState = RaffleState.CALCULATING;

        // Get our random number 2.5
        // VRF = Verifiable Random Function
        // 1. Request RNG
        // 2. Get RNG
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        //    This is redundant because vrfCoordinator also emits thr requestId event
        emit RequestedRaffleWinner(requestId);
    }

    //CEI: Checks, Effects, Interactions pattern
    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    )
        internal
        override
    {
        //checks(conditionals)

        //s_players = 10
        // rng = 12
        // 74833999289293802012308409 % 10 = 9

        //Effect (Internal Contract States)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_RaffleState = RaffleState.OPEN;
        s_players = new address payable[](0); //this will reset the players array
        s_lastTimeStamp = block.timestamp;

        emit winnerPicked(s_recentWinner);

        //Interactions (External Contract interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}(""); //here we are paying the lottery winner
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_RaffleState;
    }

    // function getPlayers() external view returns (address payable) {
    //     return  s_players;//TO CHECK ON THIS LATER!

    function getPlayers(uint256 indexOfPlayers) external view returns (address) {
        return s_players[indexOfPlayers];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
