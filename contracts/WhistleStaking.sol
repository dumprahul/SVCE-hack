// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WhistleLoan {
    address public owner;
    IERC20 public svceToken;  // The $SVCE token contract address
    uint256 public loanInterestRate = 10;  // 10% interest per month
    uint256 public stakeDuration = 30 days; // Duration for staking (e.g., 30 days)

    // Loan structure
    struct LoanRequest {
        uint256 amount;
        uint256 startTime;
        uint256 repaymentAmount;
        bool isRepaid;
    }

    mapping(address => LoanRequest) public loans;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public totalStaked;
    mapping(address => bool) public isStaker;

    // Array to hold stakers
    address[] public stakers;

    // Events
    event LoanRequested(address indexed student, uint256 amount, uint256 repaymentAmount);
    event LoanRepaid(address indexed student, uint256 repaymentAmount);
    event Staked(address indexed staker, uint256 amount);
    event RewardsDistributed(address indexed staker, uint256 rewardAmount);

    constructor(address tokenAddress) {
        owner = msg.sender;
        svceToken = IERC20(tokenAddress);
    }

    // Function to request a loan
    function requestLoan(uint256 amount) external {
        require(amount > 0, "Loan amount must be greater than 0");
        LoanRequest storage loan = loans[msg.sender];

        require(loan.amount == 0, "Existing loan request already present");

        uint256 repaymentAmount = amount + (amount * loanInterestRate) / 100;
        loan.amount = amount;
        loan.repaymentAmount = repaymentAmount;
        loan.startTime = block.timestamp;

        emit LoanRequested(msg.sender, amount, repaymentAmount);
    }

    // Function to stake ETH for a loan request
    function stakeForLoan(address student) external payable {
        require(msg.value > 0, "Must stake a positive amount");

        stakedAmount[msg.sender] += msg.value;
        totalStaked[student] += msg.value;
        isStaker[msg.sender] = true;

        // Add staker to the stakers array if they are not already added
        if (stakedAmount[msg.sender] == msg.value) {
            stakers.push(msg.sender);
        }

        emit Staked(msg.sender, msg.value);
    }

    // Function to repay loan
    function repayLoan() external payable {
        LoanRequest storage loan = loans[msg.sender];
        require(loan.amount > 0, "No active loan found");
        require(msg.value >= loan.repaymentAmount, "Insufficient repayment amount");

        // Update the loan status to repaid
        loan.isRepaid = true;

        // Transfer the repayment amount to the stakers
        distributeRewards(msg.value);

        emit LoanRepaid(msg.sender, msg.value);
    }

    // Distribute rewards to stakers after repayment
    function distributeRewards(uint256 repaymentAmount) internal {
        uint256 totalStakedAmount = totalStaked[msg.sender];

        require(totalStakedAmount > 0, "No stakers for this loan");

        uint256 totalRewards = (repaymentAmount * 10) / 100; // 10% of repayment amount as rewards

        // Iterate through all stakers and distribute rewards
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 reward = (stakedAmount[staker] * totalRewards) / totalStakedAmount;
            rewards[staker] += reward;

            // Transfer the reward in $SVCE tokens
            require(svceToken.transfer(staker, reward), "Reward transfer failed");

            emit RewardsDistributed(staker, reward);
        }
    }

    // Function to withdraw the staked ETH (only after loan repayment)
    function withdrawStake() external {
        require(loans[msg.sender].isRepaid, "Loan must be repaid before withdrawal");
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No staked amount to withdraw");

        stakedAmount[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Function to get loan status
    function getLoanStatus(address student) external view returns (uint256 amount, uint256 repaymentAmount, bool isRepaid) {
        LoanRequest storage loan = loans[student];
        return (loan.amount, loan.repaymentAmount, loan.isRepaid);
    }

    // Function to get staked amount
    function getStakedAmount(address staker) external view returns (uint256) {
        return stakedAmount[staker];
    }

    // Function to get the reward balance of a staker
    function getRewardBalance(address staker) external view returns (uint256) {
        return rewards[staker];
    }

    // Function to check if a user is a staker
    function isUserStaker(address staker) external view returns (bool) {
        return isStaker[staker];
    }

    // Function to get the loan interest rate
    function getInterestRate() external view returns (uint256) {
        return loanInterestRate;
    }

    // Function to set the loan interest rate (only owner)
    function setInterestRate(uint256 newInterestRate) external {
        require(msg.sender == owner, "Only the owner can set the interest rate");
        loanInterestRate = newInterestRate;
    }
}

//WhistleStaking.sol- 0x2747596aFF9099988c480E7105c6a30a6fb38E2c
//Tx Link - https://seitrace.com/tx/0x01ad7f5a16c22b5d4808c808fcb8513d8630ea11d6b1c726a8213c693560ff8a?chain=atlantic-2


