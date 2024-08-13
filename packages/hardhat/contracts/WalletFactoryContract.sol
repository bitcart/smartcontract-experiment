// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WalletContract.sol";

contract WalletFactoryContract {
	/**
	 * @dev Event emitted when a new wallet is created.
	 * @param walletAddress The address of the new wallet.
	 * @param owner The address of the owner of the new wallet.
	 */
	event WalletCreated(address walletAddress, address owner);

	/**
	 * @dev Creates a new wallet with a custom salt.
	 * @param _salt The custom salt as a string.
	 * @return The address of the new wallet.
	 */
	function createWallet(
		string memory _salt
	) external returns (address) {
		bytes32 salt = keccak256(abi.encodePacked(_salt));
        address owner = msg.sender;
		WalletContract wallet = new WalletContract{ salt: salt }(owner);
		emit WalletCreated(address(wallet), owner);
		return address(wallet);
	}

	/**
	 * @dev Predicts the address of a wallet before creating it using a custom salt.
	 * @param _salt The custom salt as a string.
	 * @return The predicted address of the wallet.
	 */
	function predictWalletAddress(
		string memory _salt
	) external view returns (address) {
		bytes32 salt = keccak256(abi.encodePacked(_salt));
        address owner = msg.sender;
		bytes memory bytecode = abi.encodePacked(
			type(WalletContract).creationCode,
			abi.encode(owner)
		);
		bytes32 hash = keccak256(
			abi.encodePacked(
				bytes1(0xff),
				address(this),
				salt,
				keccak256(bytecode)
			)
		);
		return address(uint160(uint256(hash)));
	}

	/**
	 * @dev Checks if a contract has already been deployed at a specific address.
	 * @param _address The address to check.
	 * @return True if a contract has already been deployed, false otherwise.
	 */
	function isContractDeployed(address _address) public view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_address)
		}
		return size > 0;
	}

	/**
	 * @dev Withdraws all ETH from multiple specific wallets.
	 * @param _wallets The addresses of the wallets from which to withdraw ETH.
	 * @param _to The address to send the withdrawn ETH to.
	 */
	function withdrawAll(
		address[] calldata _wallets,
		address payable _to
	) external {
        address owner = msg.sender;
		for (uint i = 0; i < _wallets.length; i++) {
			WalletContract wallet = WalletContract(payable(_wallets[i]));
            require(wallet.owner() == owner, "Only owner can call this function");
			wallet.sendEther(_to, address(wallet).balance);
		}
	}

	/**
	 * @dev Withdraws all ERC-20 tokens from multiple specific wallets.
	 * @param _wallets The addresses of the wallets from which to withdraw tokens.
	 * @param _token The address of the ERC-20 token contract.
	 * @param _to The address to send the withdrawn tokens to.
	 */
	function withdrawAllERC20(
		address[] calldata _wallets,
		address _token,
		address _to
	) external {
        address owner = msg.sender;
		for (uint i = 0; i < _wallets.length; i++) {
			WalletContract wallet = WalletContract(payable(_wallets[i]));
			IERC20 token = IERC20(_token);
            require(wallet.owner() == owner, "Only owner can call this function");
			uint256 balance = token.balanceOf(address(wallet));
			wallet.sendERC20(_token, _to, balance);
		}
	}
}
