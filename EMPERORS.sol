// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EMPERORS is ERC721, ERC721URIStorage, Ownable {

    uint total_value;
    uint256 public Maxsupply = 1000;
    uint256 public Supply;
    uint256 public IDs;
    uint256 public Cost = 1 ether;
    bool public isMintEnabled;

    mapping(uint256 => string) private tokenUri;

    event TransferReceived(address from, uint256 amount);

    constructor() payable ERC721("EMPEROR", "EMPEROR") {
        total_value = msg.value;
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

    function mint(address _to, uint256 _mintAmount) public payable {
        require(isMintEnabled, "Minting not enabled");
        require(_mintAmount == 1, "MintAmount should be 1");
        require(Maxsupply > Supply, "Max supply exhausted");

        if (msg.sender != owner) {
            require(msg.value == Cost, "Wrong value");
        }

        Supply++;
        uint256 tokenId = Supply;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, tokenUri[tokenId]);
    }

    function SetUri(uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        IDs++;
        tokenUri[tokenId] = uri;
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
