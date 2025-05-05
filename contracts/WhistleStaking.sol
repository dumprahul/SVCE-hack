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
        string description; // ✅ Added description field
    }

    mapping(address => LoanRequest) public loans;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public totalStaked;
    mapping(address => bool) public isStaker;

    // ✅ New array to store all loan requesters
    address[] public loanRequesters;

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

    // ✅ Modified to accept loan description
    function requestLoan(uint256 amount, string calldata description) external {
        require(amount > 0, "Loan amount must be greater than 0");
        LoanRequest storage loan = loans[msg.sender];
        require(loan.amount == 0, "Existing loan request already present");

        uint256 repaymentAmount = amount + (amount * loanInterestRate) / 100;
        loan.amount = amount;
        loan.repaymentAmount = repaymentAmount;
        loan.startTime = block.timestamp;
        loan.description = description;

        loanRequesters.push(msg.sender); // ✅ Add requester to the list

        emit LoanRequested(msg.sender, amount, repaymentAmount);
    }

    function stakeForLoan(address student) external payable {
        require(msg.value > 0, "Must stake a positive amount");

        stakedAmount[msg.sender] += msg.value;
        totalStaked[student] += msg.value;
        isStaker[msg.sender] = true;

        if (stakedAmount[msg.sender] == msg.value) {
            stakers.push(msg.sender);
        }

        emit Staked(msg.sender, msg.value);
    }

    function repayLoan() external payable {
        LoanRequest storage loan = loans[msg.sender];
        require(loan.amount > 0, "No active loan found");
        require(msg.value >= loan.repaymentAmount, "Insufficient repayment amount");

        loan.isRepaid = true;
        distributeRewards(msg.value);

        emit LoanRepaid(msg.sender, msg.value);
    }

    function distributeRewards(uint256 repaymentAmount) internal {
        uint256 totalStakedAmount = totalStaked[msg.sender];
        require(totalStakedAmount > 0, "No stakers for this loan");

        uint256 totalRewards = (repaymentAmount * 10) / 100;

        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 reward = (stakedAmount[staker] * totalRewards) / totalStakedAmount;
            rewards[staker] += reward;

            require(svceToken.transfer(staker, reward), "Reward transfer failed");

            emit RewardsDistributed(staker, reward);
        }
    }

    function withdrawStake() external {
        require(loans[msg.sender].isRepaid, "Loan must be repaid before withdrawal");
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No staked amount to withdraw");

        stakedAmount[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getLoanStatus(address student) external view returns (uint256 amount, uint256 repaymentAmount, bool isRepaid) {
        LoanRequest storage loan = loans[student];
        return (loan.amount, loan.repaymentAmount, loan.isRepaid);
    }

    function getStakedAmount(address staker) external view returns (uint256) {
        return stakedAmount[staker];
    }

    function getRewardBalance(address staker) external view returns (uint256) {
        return rewards[staker];
    }

    function isUserStaker(address staker) external view returns (bool) {
        return isStaker[staker];
    }

    function getInterestRate() external view returns (uint256) {
        return loanInterestRate;
    }

    function setInterestRate(uint256 newInterestRate) external {
        require(msg.sender == owner, "Only the owner can set the interest rate");
        loanInterestRate = newInterestRate;
    }

    // ✅ New function to fetch all loan requesters
    function getAllLoanRequesters() external view returns (address[] memory) {
        return loanRequesters;
    }

    // ✅ New function to get full loan info with description
    function getLoanDetails(address student) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 repaymentAmount,
        bool isRepaid,
        string memory description
    ) {
        LoanRequest storage loan = loans[student];
        return (loan.amount, loan.startTime, loan.repaymentAmount, loan.isRepaid, loan.description);
    }
}


//contract address- 0xF8afe7f0C815FE336F10f14A21448e036e7a82B2
//tx link - https://seitrace.com/tx/0x213e0935041523ba7c5d67ef053b69c32d7c4df12dff17f43d4d75a028aa714d?chain=atlantic-2