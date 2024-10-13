// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

contract SmartLottery is VRFConsumerBaseV2Plus {
    // State variables
    uint256 public interval;
    address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    uint256 s_subscriptionId;
    bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 100000;
    uint32 numWords = 1;
    uint256 public lotteryId = 0;

    struct Lottery {
        uint256 LotteryId;
        address[] players;
        uint256 entryFee;
        address winner;
        uint256 lotteryStartTime;
        uint256 lotteryEndTime;
        uint256 s_requestId;
        address creator;
    }

    // Events
    event LotteryCreated(uint256 indexed lotteryId);
    event LotteryEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // Mapping
    mapping(uint256 => Lottery) public idToLottery;
    mapping(uint256 => uint256) public RequestIdToId;

    // Constructor to initialize the VRF Coordinator, keyHash, and subscriptionId
    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
    }

    // Create a Lottery
    function createLottery(uint256 entryFee, uint256 startTime, uint256 endTime) public payable {
        idToLottery[lotteryId].LotteryId = lotteryId;
        idToLottery[lotteryId].entryFee = entryFee;
        idToLottery[lotteryId].lotteryStartTime = startTime;
        idToLottery[lotteryId].lotteryEndTime = endTime;
        idToLottery[lotteryId].creator = msg.sender;

        emit LotteryCreated(lotteryId);

        lotteryId++;
    }

    // Enter the lottery by paying the entry fee
    function enterLottery(uint256 id) public payable {
        require(id < lotteryId, "Lottery does not exists");
        require(idToLottery[id].lotteryStartTime < block.timestamp, "Lottery still ongoing");
        require(idToLottery[id].lotteryEndTime > block.timestamp, "Lottery has ended");
        require(msg.value >= idToLottery[id].entryFee, "Not enough ETH to enter");
        idToLottery[id].players.push(msg.sender);
        emit LotteryEntered(msg.sender);
    }

    function DrawLotteryWinner(uint256 id) external returns (uint256 requestId) {
        require(msg.sender == idToLottery[id].creator, "Only Lottery creator can draw lottery");
        require(idToLottery[id].lotteryEndTime < block.timestamp, "Lottery still ongoing");

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        RequestIdToId[requestId] = id;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 id = RequestIdToId[_requestId];
        uint256 winnerIndex = _randomWords[0] % idToLottery[id].players.length;
        idToLottery[id].winner = idToLottery[id].players[winnerIndex];
        emit RequestFulfilled(_requestId, _randomWords);
    }

    // View function to get the list of players
    function getLotteryPlayers(uint256 id) public view returns (address[] memory) {
        return idToLottery[id].players;
    }

    function withdrawWinnings(uint256 id) public {
        require(msg.sender == idToLottery[id].winner, "You are not the winner");
        address payable winner = payable(idToLottery[id].winner);
        uint256 amount = idToLottery[id].players.length * idToLottery[id].entryFee;

        (bool sent, bytes memory data) = winner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
