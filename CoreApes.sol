// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COREAPES is ERC721, ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public Devs;
    uint256 public Maxsupply = 10000;
    uint256 public Supply;
    uint256 public cost = 1000000000000000000;
    string public URI;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable PayToken;

    event TransferReceived(address from, uint256 amount);

    constructor(address _devs, IERC20 _PayToken) ERC721("COREAPES", "CAPE") {
        Devs = _devs;
        PayToken = _PayToken;
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

    function SetURI(string memory uri) public onlyOwner {
        URI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function mint(address _to, uint256 _mintAmount) external nonReentrant {
        require(_mintAmount == 1, "MintAmount should be 1");
        require(msg.value >= Cost, "Wrong value");
        require(Maxsupply > Supply, "Max supply exhausted");
        PayToken.transfer(Devs, cost);

        Supply++;
        uint256 tokenId = Supply;
        _safeMint(_to, tokenId);
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
