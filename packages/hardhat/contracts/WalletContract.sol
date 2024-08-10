// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WalletContract {
    address public factory;
    address public owner;

    /**
     * @dev Constructor that initializes the Wallet contract.
     * @param _owner The address of the wallet owner.
     */
    constructor(address _owner) {
        factory = msg.sender;
        owner = _owner;
    }

    /**
     * @dev Modifier that allows only the factory or owner to call the function.
     */
    modifier onlyOwnerOrFactory() {
        require(msg.sender == factory || msg.sender == owner, "Only owner or factory can call this function");
        _;
    }

    /**
     * @dev Sends Ether to a specific address.
     * @param _to The address to send the Ether to.
     * @param _amount The amount of Ether to send.
     */
    function sendEther(address payable _to, uint256 _amount) external onlyOwnerOrFactory {
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.transfer(_amount);
    }

    /**
     * @dev Sends ERC-20 tokens to a specific address.
     * @param _token The address of the ERC-20 token contract.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to send.
     */
    function sendERC20(address _token, address _to, uint256 _amount) external onlyOwnerOrFactory {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * @dev Function to receive Ether.
     */
    receive() external payable {}
}
