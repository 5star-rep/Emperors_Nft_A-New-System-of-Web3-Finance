// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COREAPES is ERC721, ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address payable Devs;
    uint total_value;
    uint256 public Maxsupply = 10000;
    uint256 public Stakers;
    uint256 public Supply;
    uint256 public Cost = 1 ether;
    uint256 private Pay = 1 ether;
    bool public isMintEnabled;
    string public URI;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable rewardsToken;

    event TransferReceived(address from, uint256 amount);

    constructor(address payable _devs, IERC20 _rewardsToken) payable ERC721("COREAPES", "CAPE") {
        Devs = _devs;
        total_value = msg.value;
        rewardsToken = _rewardsToken;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Staked token ids
        StakedToken[] stakedTokens;

        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;

        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Rewards per hour per token deposited in wei.
    uint256 private rewardsPerHour = 80000000000000000; // 0.08 token per hour

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256 _tokenId) external nonReentrant {
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        Stakers++;

        // Transfer the token from the wallet to the Smart contract
        _transfer(msg.sender, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        // Add the token to the stakedTokens array
        stakers[msg.sender].stakedTokens.push(stakedToken);

        // Increment the amount staked for this wallet
        stakers[msg.sender].amountStaked++;

        // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;

        // Update the timeOfLastUpdate for the staker   
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }
    
    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256 _tokenId) external nonReentrant {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        
        // Wallet must own the token they are trying to withdraw
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        // Find the index of this token id in the stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        Stakers--;

        // Set this token's .staker to be address 0 to mark it as no longer staked
        stakers[msg.sender].stakedTokens[index].staker = address(0);

        // Decrement the amount staked for this wallet
        stakers[msg.sender].amountStaked--;

        // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);

        // Transfer the token back to the withdrawer
        _transfer(address(this), msg.sender, _tokenId);

        // Update the timeOfLastUpdate for the withdrawer   
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
    }


    //////////
    // View //
    //////////

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        // Check if we know this user
        if (stakers[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    function Team() public pure returns (string memory) {
        return '5 STAR Organization';
    }

    function Founder() public pure returns (string memory) {
        return 'Oge Ifeluo';
    }

    function totalSupply() public view returns (uint256) {
        return Supply;
    }

    receive() payable external {
        total_value += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    function EnableMint() public onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function SetURI(string memory uri) public onlyOwner {
        URI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        require(isMintEnabled, "Minting not enabled");
        require(_mintAmount == 1, "MintAmount should be 1");
        require(msg.value >= Cost, "Wrong value");
        require(Maxsupply > Supply, "Max supply exhausted");
        total_value += msg.value;
        total_value -= Pay;
        Devs.transfer(Pay);

        Supply++;
        uint256 tokenId = Supply;
        _safeMint(_to, tokenId);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
