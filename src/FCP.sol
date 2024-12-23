//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

contract FCP is ERC721, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Custom errors
    error EmptyPack();
    error NotPackOwner();
    error PackAlreadyOpened();

    // Struct to store all assets in a pack
    struct Pack {
        address sender;
        address receiverAddress;
        uint96 USDCAmount;
    }

    IERC20 public USDC;

    // Mapping from pack ID to Pack struct
    mapping(uint256 => Pack) public packs;

    // Counter for pack IDs
    uint256 public _nextPackId;

    // Events
    event PackCreated(
        address indexed creator,
        uint256 indexed packId,
        uint256 AssetAmount
    );
    event PackOpened(uint256 indexed packId, address indexed opener);

    constructor(
        address _usdc
    ) ERC721("Christmas Pack", "XPACK") Ownable(msg.sender) {
        USDC = IERC20(_usdc);
        _nextPackId = 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }

    /**
     * @dev Creates a new pack containing the specified assets
 
     * @return packId The ID of the newly created pack
     */
    function buyPack(
        uint256 assetAmount
    ) external nonReentrant returns (uint256 packId) {
        require(assetAmount < type(uint96).max);
        packId = _nextPackId++;
        Pack storage newPack = packs[packId];
        uint fees = 1e6; // 1 USDC
        uint total = assetAmount + fees;
        USDC.safeTransferFrom(msg.sender, address(this), total);
        newPack.sender = msg.sender;
        newPack.USDCAmount = uint96(assetAmount);

        return packId;
    }

    function claim(
        uint256 packId,
        address recipient
    ) external nonReentrant onlyOwner {
        if (isPackOpened(packId)) revert PackAlreadyOpened();

        Pack storage pack = packs[packId];
        pack.receiverAddress = recipient;

        USDC.safeTransfer(recipient, pack.USDCAmount);
        _safeMint(recipient, packId);

        emit PackOpened(packId, recipient);
    }

    function isPackOpened(uint256 packId) public view returns (bool) {
        address recipient = packs[packId].receiverAddress;
        return (recipient != address(0));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert();
    }
    function withdrawTokens(uint256 amount) external onlyOwner{
        USDC.safeTransfer( msg.sender, amount);
    }
}
