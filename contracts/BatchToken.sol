pragma solidity ^0.5.0;

contract BatchToken {
    struct Account {
        address owner;
        uint64 balance;
        uint32 nonce;
    }
    
    struct QueuedTransfer {
        uint256 data;
        uint256 blockNumber;
    }

    uint256 constant MAX_QUEUE_DEPTH = 50;
    uint256 constant SEQUENCER_DEPOSIT = 1 ether;

    address sequencer;
    uint32 numAccounts;
    mapping (uint32 => Account) public accounts;

    uint256 nextQueuedTransfer;
    mapping(uint256 => QueuedTransfer) queuedTransfers;

    uint256 batchesProcessed;
    mapping (uint256 => bytes32) batches;
    
    modifier onlySequencer {
        require(msg.sender == sequencer);
        _;
    }

    constructor () public payable {
        // require(msg.value == SEQUENCER_DEPOSIT);
        sequencer = msg.sender;
        numAccounts++;
        accounts[0].balance = 1000000000000;
        accounts[0].owner = msg.sender;
    }

    function registerAccount() external returns(uint32) {
        numAccounts++;
        accounts[numAccounts - 1].owner = msg.sender;
        return numAccounts - 1;
    }

    function addTransferToQueue(uint data) external {
        uint32 sender;
        uint32 dest;
        uint32 nonce;
        uint64 amount;
        (sender, dest, nonce, amount) = _parseTransfer(data);
        Account storage account = accounts[sender];
        require(msg.sender == account.owner);
        nextQueuedTransfer++;
        queuedTransfers[nextQueuedTransfer] = QueuedTransfer(data, block.number);
    }
    
    function executeFromQueue(uint maxToExecute) external onlySequencer {
        uint256 limit = nextQueuedTransfer + maxToExecute;
        uint256 i;
        for (i = nextQueuedTransfer; i < limit; i++) {
            QueuedTransfer storage transfer = queuedTransfers[i];
            if (transfer.blockNumber == 0) {
                // We have processed all pending transfers
                break;
            }
            (uint32 sender, uint32 dest, uint32 nonce, uint64 amount) = _parseTransfer(transfer.data);
            Account storage account = accounts[sender];
            _transfer(account, dest, nonce, amount);
            delete queuedTransfers[i];
        }
        nextQueuedTransfer = i;
    }

    function sequencerBatchTransfer(bytes calldata /*signatures*/, uint256[] calldata data) external onlySequencer {
        uint256 queueMinBlock = queuedTransfers[nextQueuedTransfer].blockNumber;
        require(queueMinBlock == 0 || block.number - queueMinBlock < MAX_QUEUE_DEPTH, "Must clear messages from queue");

        for (uint i = 0; i < data.length; i++) {
            (uint32 sender, uint32 dest, uint32 nonce, uint64 amount) = _parseTransfer(data[i]);
            Account storage account = accounts[sender];
            require(account.owner == _recoverAddress(bytes32(data[i]), i), "invalid sig");
            _transfer(account, dest, nonce, amount);
        }

        batches[batchesProcessed] = keccak256(msg.data);
        batchesProcessed++;
    }

    function slashSequencer(uint256 batchNum, bytes memory sig) public {
        bytes32 r;
        bytes32 s;
        uint8 v;

        require(sig.length == 65);
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
          v += 27;
        }
        require(v == 27 || v == 28);
        require(ecrecover(batches[batchNum], v, r, s) == sequencer);

        address(0).transfer(SEQUENCER_DEPOSIT);
    }

    function _transfer( Account storage account,  uint32 dest, uint32 nonce, uint64 amount) private returns(bool) {
        if (amount > account.balance || nonce != account.nonce) {
            return false;
        }
        account.nonce++;
        account.balance -= amount;
        accounts[dest].balance += amount;
        return true;
    }
    
    // data:
    //  sender 32 bits
    //  dest 32 bits
    //  nonce 32 bits
    //  amount 64 bits
    function _parseTransfer(uint256 data) private pure returns(uint32 sender,  uint32 dest, uint32 nonce, uint64 amount) {
        sender = uint32(data);
        dest = uint32(data >> 32);
        nonce = uint32(data >> 64);
        amount = uint64(data >> 96);
        
    }

    function _recoverAddress(
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