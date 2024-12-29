// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uma/core/contracts/optimistic-oracle-v2/interfaces/OptimisticOracleV2Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingContract is ReentrancyGuard {
    enum BetOption { OptionA, OptionB }

    struct Bet {
        uint256 amount;
        BetOption option;
        bool claimed;
    }

    mapping(address => Bet) public bets;
    uint256 public totalPoolOptionA;
    uint256 public totalPoolOptionB;
    uint256 public bettingDeadline;
    bool public outcomeResolved;
    BetOption public winningOption;

    // Oracle variables
    OptimisticOracleV2Interface public oracle;
    bytes32 public identifier;
    uint256 public requestTime;
    bytes public ancillaryData;

    IERC20 public rewardToken;
    uint256 public constant PROPOSAL_REWARD = 0;

    // Events
    event BetPlaced(address indexed user, uint256 amount, BetOption option);
    event OutcomeRequested(bytes32 indexed identifier, uint256 timestamp, bytes ancillaryData);
    event OutcomeSettled(BetOption winningOption);
    event WinningsClaimed(address indexed user, uint256 amount);

    constructor(
        uint256 _bettingDeadline,
        address _oracleAddress,
        bytes32 _identifier,
        bytes memory _ancillaryData,
        address _rewardTokenAddress
    ) {
        require(_bettingDeadline > block.timestamp, "Betting deadline must be in the future");
        bettingDeadline = _bettingDeadline;
        oracle = OptimisticOracleV2Interface(_oracleAddress);
        identifier = _identifier;
        ancillaryData = _ancillaryData;
        rewardToken = IERC20(_rewardTokenAddress);
    }

    modifier beforeDeadline() {
        require(block.timestamp < bettingDeadline, "Betting period is over");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= bettingDeadline, "Action can only be performed after the betting deadline");
        _;
    }

    function placeBet(BetOption _option) external payable beforeDeadline nonReentrant {
        require(msg.value > 0, "Bet amount must be greater than zero");
        require(bets[msg.sender].amount == 0, "You've already placed a bet");

        bets[msg.sender] = Bet({
            amount: msg.value,
            option: _option,
            claimed: false
        });

        if (_option == BetOption.OptionA) {
            totalPoolOptionA += msg.value;
        } else {
            totalPoolOptionB += msg.value;
        }

        emit BetPlaced(msg.sender, msg.value, _option);
    }

    function requestOutcome() external afterDeadline nonReentrant {
        require(!outcomeResolved, "Outcome already resolved");

        requestTime = block.timestamp;

        // Approve the reward token to the oracle
        rewardToken.approve(address(oracle), PROPOSAL_REWARD);

        // Request the price (outcome) from the Optimistic Oracle
        oracle.requestPrice(
            identifier,
            requestTime,
            ancillaryData,
            rewardToken,
            PROPOSAL_REWARD
        );

        // Set custom liveness if desired (optional)
        // oracle.setCustomLiveness(identifier, requestTime, ancillaryData, 7200); // 2 hours

        emit OutcomeRequested(identifier, requestTime, ancillaryData);
    }

    function settleOutcome() external afterDeadline nonReentrant {
        require(!outcomeResolved, "Outcome already resolved");

        // Check if the price is available
        if (oracle.hasPrice(identifier, requestTime, ancillaryData)) {
            int256 outcome = oracle.settleAndGetPrice(identifier, requestTime, ancillaryData);

            // Interpret the outcome: 0 for OptionA, 1 for OptionB
            if (outcome == 0) {
                winningOption = BetOption.OptionA;
            } else if (outcome == 1) {
                winningOption = BetOption.OptionB;
            } else {
                revert("Invalid outcome from oracle");
            }

            outcomeResolved = true;

            emit OutcomeSettled(winningOption);
        } else {
            revert("Price not yet resolved");
        }
    }

    function claimWinnings() external afterDeadline nonReentrant {
        require(outcomeResolved, "Outcome not yet resolved");
        Bet storage userBet = bets[msg.sender];
        require(!userBet.claimed, "Winnings already claimed");
        require(userBet.amount > 0, "No bet placed");

        uint256 reward = 0;
        if (userBet.option == winningOption) {
            // Calculate user's share of the losing pool
            uint256 totalWinningPool = (winningOption == BetOption.OptionA)
                ? totalPoolOptionA
                : totalPoolOptionB;
            uint256 totalLosingPool = (winningOption == BetOption.OptionA)
                ? totalPoolOptionB
                : totalPoolOptionA;
            uint256 userShare = (userBet.amount * totalLosingPool) / totalWinningPool;

            reward = userBet.amount + userShare;
        }

        userBet.claimed = true;

        if (reward > 0) {
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "Transfer failed");
            emit WinningsClaimed(msg.sender, reward);
        }
    }

    // Fallback functions to receive ETH
    receive() external payable {}
    fallback() external payable {}
}