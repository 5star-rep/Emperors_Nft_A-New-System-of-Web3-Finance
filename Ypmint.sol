// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COREANGELS is ERC721, ERC721URIStorage, Ownable {
    using SafeERC20 for IERC20;

    uint256 public Maxsupply = 5000;
    uint256 public Supply;
    uint256 public IDs;
    uint256 private total_value;
    uint256 public cost = 1 ether;
    uint256 private Share = 1 ether;
    string public URI;

    constructor() ERC721("COREANGELS", "ANGELS") {}

    receive() payable external {
        total_value += msg.value;
    }

    mapping(uint256 => string) private tokenUri;

    function Team() public pure returns (string memory) {
        return '5 STAR Organization';
    }

    function Founder() public pure returns (string memory) {
        return 'Oge Ifeluo';
    }

    function totalSupply() public view returns (uint256) {
        return Supply;
    }

    function SetBaseURI(string memory uri) public onlyOwner {
        URI = uri;
    }

    function SetUri(uint256 ids, string memory uri)
        public
        onlyOwner
    {
        tokenUri[ids] = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function mint(address _to) public payable {
        require(Maxsupply > Supply, "Max supply exhausted");
        total_value += msg.value;

        if (IDs == 100) {
            IDs = 1;
        } else {
                IDs++;
        }

        Supply++;
        uint256 ids = IDs;
        uint256 tokenId = Supply;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, tokenUri[ids]);
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
