# Bitcoin Network Architecture Guide

## 🏗️ System Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                    Bitcoin Network Architecture               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│  │    Node 1   │◄────┤    Node 2   │────►│    Node 3   │      │
│  │ :5000       │     │ :5001       │     │ :5002       │      │
│  │             │     │             │     │             │      │
│  │ ┌─────────┐ │     │ ┌─────────┐ │     │ ┌─────────┐ │      │
│  │ │  Chain  │ │     │ │  Chain  │ │     │ │  Chain  │ │      │
│  │ │         │ │     │ │         │ │     │ │         │ │      │
│  │ │  Block 0│ │     │ │  Block 0│ │     │ │  Block 0│ │      │
│  │ │  Block 1│ │     │ │  Block 1│ │     │ │  Block 1│ │      │
│  │ │  Block 2│ │     │ │  Block 2│ │     │ │  Block 2│ │      │
│  │ └─────────┘ │     │ └─────────┘ │     │ └─────────┘ │      │
│  │             │     │             │     │             │      │
│  │ ┌─────────┐ │     │ ┌─────────┐ │     │ ┌─────────┐ │      │
│  │ │TX Pool  │ │     │ │TX Pool  │ │     │ │TX Pool  │ │      │
│  │ │ TX1     │ │     │ │ TX3     │ │     │ │ TX5     │ │      │
│  │ │ TX2     │ │     │ │ TX4     │ │     │ │ TX6     │ │      │
│  │ └─────────┘ │     │ └─────────┘ │     │ └─────────┘ │      │
│  │             │     │             │     │             │      │
│  │ REST API    │     │ REST API    │     │ REST API    │      │
│  │ Mining      │     │ Mining      │     │ Mining      │      │
│  │ P2P Comm    │     │ P2P Comm    │     │ P2P Comm    │      │
│  └─────────────┘     └─────────────┘     └─────────────┘      │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## 🧩 Core Components

### 1. Transaction Class
```python
class Transaction:
    - sender: str           # Transaction sender
    - recipient: str        # Transaction recipient  
    - amount: float         # Transaction amount
    - timestamp: float      # Creation timestamp
```

**Responsibilities:**
- Represent individual money transfers
- Store transaction metadata
- Provide serialization methods

### 2. Block Class
```python
class Block:
    - index: int            # Block number in chain
    - timestamp: float      # Block creation time
    - data: list           # List of transactions
    - previous_hash: str   # Hash of previous block
    - nonce: int          # Proof-of-work nonce
    - hash: str           # Block's SHA-256 hash
```

**Responsibilities:**
- Store transaction data in blocks
- Maintain blockchain integrity via hashing
- Implement Proof-of-Work mining algorithm
- Link to previous blocks

### 3. Blockchain Class
```python
class Blockchain:
    - chain: list          # List of blocks
    - difficulty: int      # Mining difficulty
    - pending_transactions: list  # Transaction pool
    - mining_reward: float # Reward for mining
```

**Responsibilities:**
- Manage the entire blockchain
- Validate new blocks and transactions
- Handle chain synchronization
- Implement longest chain rule
- Manage transaction pool

### 4. BitcoinNode Class
```python
class BitcoinNode:
    - port: int            # Node's network port
    - blockchain: Blockchain  # Node's blockchain copy
    - peers: set          # Connected peer nodes
    - app: Flask          # REST API server
    - node_id: str        # Unique node identifier
```

**Responsibilities:**
- Provide REST API interface
- Handle P2P communication
- Coordinate mining activities
- Manage peer connections
- Synchronize with network

## 🔄 Data Flow Diagrams

### Transaction Processing Flow
```
User/Client
    │
    │ POST /transaction
    ▼
┌─────────────┐
│ REST API    │
│ Endpoint    │
└─────┬───────┘
      │
      │ validate & add
      ▼
┌─────────────┐
│Transaction  │
│Pool         │
└─────┬───────┘
      │
      │ GET /mine
      ▼
┌─────────────┐
│Mining       │
│Process      │
└─────┬───────┘
      │
      │ create block
      ▼
┌─────────────┐
│Blockchain   │
│(local)      │
└─────┬───────┘
      │
      │ broadcast
      ▼
┌─────────────┐
│Peer Nodes   │
│(network)    │
└─────────────┘
```

### Block Mining Process
```
┌─────────────┐
│Start Mining │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│Collect      │
│Pending TX   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│Create Block │
│(index, data,│
│prev_hash)   │
└─────┬───────┘
      │
      ▼
┌─────────────┐      No
│Check Hash   │──────┐
│Difficulty   │      │
└─────┬───────┘      │
      │ Yes          │
      ▼              │
┌─────────────┐      │
│Add Block to │      │
│Chain        │      │
└─────┬───────┘      │
      │              │
      ▼              │
┌─────────────┐      │
│Broadcast to │      │
│Peers        │      │
└─────────────┘      │
                     │
              ┌─────────────┐
              │Increment    │
              │Nonce &      │
              │Recalculate  │
              └─────┬───────┘
                    │
                    └───────────────┘
```

### Network Synchronization Flow
```
Node A                    Node B                    Node C
  │                        │                        │
  │ Receives new block     │                        │
  ├─ Validate block        │                        │
  ├─ Check prev_hash       │                        │
  ├─ Verify PoW           │                        │
  │                        │                        │
  │ If valid:              │                        │
  ├─ Add to chain         │                        │
  ├─ Clear TX pool        │                        │
  │                        │                        │
  │ If invalid/behind:     │                        │
  ├─ GET /chain           ─┼──────────────────────► │
  │                        │                        ├─ Return full chain
  │ ◄──────────────────────┼────────────────────────┤
  ├─ Validate full chain  │                        │
  ├─ Replace if longer    │                        │
  │   and valid           │                        │
```

## 🔐 Cryptographic Implementation

### SHA-256 Hash Calculation
```python
def calculate_hash(self):
    block_string = f"{self.index}{self.timestamp}{json.dumps(self.data, sort_keys=True)}{self.previous_hash}{self.nonce}"
    return hashlib.sha256(block_string.encode()).hexdigest()
```

**Hash Components:**
1. **Index**: Block number (ensures order)
2. **Timestamp**: Creation time (prevents replay)
3. **Data**: JSON of transactions (ensures data integrity)
4. **Previous Hash**: Links blocks (prevents tampering)
5. **Nonce**: Variable for PoW (enables mining)

### Proof-of-Work Algorithm
```python
def mine_block(self, difficulty):
    target = "0" * difficulty  # e.g., "0000" for difficulty 4
    
    while self.hash[:difficulty] != target:
        self.nonce += 1
        self.hash = self.calculate_hash()
    
    # Block is mined when hash starts with required zeros
```

**Mining Characteristics:**
- **Difficulty 1**: ~1-10 seconds (1 leading zero)
- **Difficulty 2**: ~10-60 seconds (2 leading zeros) 
- **Difficulty 3**: ~1-5 minutes (3 leading zeros)
- **Difficulty 4**: ~5-30 minutes (4 leading zeros)

## 🌐 Network Protocol

### REST API Endpoints

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/status` | Node status | None | Node info, chain length, peers |
| GET | `/chain` | Full blockchain | None | Complete chain data |
| GET | `/peers` | Connected peers | None | List of peer URLs |
| GET | `/mine` | Mine new block | None | Mining result |
| GET | `/sync` | Sync with network | None | Sync status |
| POST | `/transaction` | Add transaction | `{sender, recipient, amount}` | Transaction confirmation |
| POST | `/peers` | Add new peer | `{peer_url}` | Peer addition status |
| POST | `/block` | Receive new block | Block data | Block acceptance status |

### P2P Communication Protocol

#### Block Broadcasting
```http
POST /block HTTP/1.1
Content-Type: application/json

{
  "index": 5,
  "timestamp": 1692181945.327,
  "data": [...],
  "previous_hash": "000a7f0c...",
  "nonce": 15679,
  "hash": "0000cda7..."
}
```

#### Chain Synchronization
```http
GET /chain HTTP/1.1

Response:
{
  "chain": [...],
  "length": 5
}
```

#### Peer Discovery
```http
POST /peers HTTP/1.1
Content-Type: application/json

{
  "peer_url": "http://localhost:5001"
}
```

## 🔄 Consensus Mechanism

### Longest Chain Rule
```python
def replace_chain(self, new_chain):
    # Convert to Block objects
    new_blockchain = [Block(...) for block in new_chain]
    
    # Validate entire chain
    if len(new_blockchain) > len(self.chain) and self.is_chain_valid():
        self.chain = new_blockchain
        return True
    return False
```

**Consensus Steps:**
1. **Receive** new block from peer
2. **Validate** block structure and PoW
3. **Check** if block extends current chain
4. **Accept** if valid, or request full chain if behind
5. **Replace** local chain if peer's is longer and valid

### Fork Resolution
```
Initial State:
Node A: [Genesis] -> [Block1] -> [Block2]
Node B: [Genesis] -> [Block1] -> [Block2] 
Node C: [Genesis] -> [Block1] -> [Block2]

Network Partition:
Group 1 (A,B): [Genesis] -> [Block1] -> [Block2] -> [Block3a] -> [Block4a]
Group 2 (C):   [Genesis] -> [Block1] -> [Block2] -> [Block3b]

Resolution (Longest Chain Wins):
All Nodes: [Genesis] -> [Block1] -> [Block2] -> [Block3a] -> [Block4a]
```

## 📊 Performance Characteristics

### Memory Usage (Per Node)
- **Genesis Block**: ~500 bytes
- **Transaction**: ~200 bytes
- **Block Header**: ~300 bytes
- **Per 1000 blocks**: ~2-5 MB

### CPU Usage (Mining)
- **Hash Rate**: 10,000-100,000 hashes/second (Python)
- **Mining Time**: Exponential increase with difficulty
- **Network Communication**: Minimal overhead

### Network Bandwidth
- **Block Propagation**: 1-5 KB per block
- **Transaction**: ~200 bytes
- **Chain Sync**: Linear with chain length

## 🔒 Security Model

### Threat Mitigation

#### 1. Double Spending Prevention
- Transactions included in blockchain are immutable
- Longest chain rule prevents conflicting transactions
- Network consensus required for acceptance

#### 2. Chain Integrity
- SHA-256 cryptographic hashing
- Each block references previous block hash
- Tampering detection through hash validation

#### 3. Sybil Attack Resistance
- Proof-of-Work requires computational resources
- Mining difficulty adjusts to maintain consistency
- Network majority consensus required

### Current Limitations
⚠️ **Educational Implementation Notice**

This implementation is for educational purposes and lacks:
- Digital signatures (transactions not cryptographically signed)
- UTXO model (simplified balance tracking)
- Advanced P2P discovery
- DoS protection mechanisms
- Merkle tree optimization

## 🚀 Deployment Architecture

### Single Machine Development
```
localhost:5000  ←─┐
localhost:5001  ←─┼─ All nodes on same machine
localhost:5002  ←─┘   Different ports
```

### Multi-Machine Network
```
192.168.1.10:5000  ←─┐
192.168.1.11:5000  ←─┼─ Distributed across machines
192.168.1.12:5000  ←─┘   Same port, different IPs
```

### Docker Containerization
```yaml
version: '3.8'
services:
  node1:
    build: .
    ports: ["5000:5000"]
  node2:
    build: .
    ports: ["5001:5001"]
  node3:
    build: .
    ports: ["5002:5002"]
```

## 📈 Scalability Considerations

### Current Limitations
- **In-memory storage**: Limited by RAM
- **Single-threaded mining**: No parallel processing
- **Simple P2P protocol**: Not optimized for large networks
- **Full chain validation**: Resource intensive for long chains

### Optimization Opportunities
1. **Database persistence**: PostgreSQL/MongoDB storage
2. **Parallel mining**: Multi-threaded PoW calculation
3. **Advanced P2P**: BitTorrent-style protocol
4. **Merkle trees**: Efficient transaction verification
5. **Light clients**: SPV (Simplified Payment Verification)

## 🎯 Educational Objectives Achieved

### Blockchain Fundamentals
✅ **Hash Chaining**: Understanding block linkage
✅ **Immutability**: Cryptographic data integrity  
✅ **Distributed Ledger**: Multiple node synchronization

### Consensus Mechanisms
✅ **Proof of Work**: Mining and difficulty adjustment
✅ **Longest Chain Rule**: Fork resolution
✅ **Network Agreement**: Distributed consensus

### P2P Networking
✅ **Peer Discovery**: Node connection management
✅ **Message Broadcasting**: Block and transaction propagation
✅ **Network Resilience**: Partition tolerance and recovery

### Cryptography
✅ **SHA-256 Hashing**: Cryptographic integrity
✅ **Nonce-based PoW**: Computational puzzles
✅ **Hash-based Linking**: Chain structure security

This implementation provides a solid foundation for understanding how blockchain networks operate, from individual transactions to network-wide consensus mechanisms.