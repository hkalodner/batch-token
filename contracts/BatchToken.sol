pragma solidity ^0.5.0;

contract BatchToken {
    struct Account {
        address owner;
        uint64 balance;
        uint32 nonce;
    }

    uint32 numAccounts;
    mapping (uint32 => Account) public accounts;

    constructor () public {
        numAccounts++;
        accounts[0].balance = 1000000000000;
        accounts[0].owner = msg.sender;
    }

    function registerAccount() external returns(uint32) {
        numAccounts++;
        accounts[numAccounts - 1].owner = msg.sender;
        return numAccounts - 1;
    }

    // data:
    //  sender 32 bits
    //  dest 32 bits
    //  nonce 32 bits
    //  amount 64 bits
    function batchTransfer(bytes calldata /*signatures*/, uint256[] calldata data) external {
        for (uint i = 0; i < data.length; i++) {
            uint256 item = data[i];
            uint32 sender = uint32(item);
            uint64 amount = uint64(item >> 96);
            Account storage account = accounts[sender];
            address owner = account.owner;
            uint64 balance = account.balance;
            uint32 accountNonce = account.nonce;
            require(owner == recoverAddress(bytes32(item), i));
            require(amount <= balance);
            require(accountNonce == uint32(item >> 64));
            accounts[sender] = Account(
                owner,
                balance - amount,
                accountNonce + 1
            );
            accounts[uint32(item >> 32)].balance += amount;
        }
    }

    function recoverAddress(
        bytes32 _messageHash,
        uint pos
    )
        private
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint offset = 68 + pos * 65;
        assembly {
            r := calldataload(add(32, offset))
            s := calldataload(add(64, offset))
            v := and(calldataload(add(65, offset)), 0xff)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        bytes32 prefixedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _messageHash
        ));
        return ecrecover(
            prefixedHash,
            v,
            r,
            s
        );
    }
}