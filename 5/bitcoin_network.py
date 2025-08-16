#!/usr/bin/env python3
"""
Simple Bitcoin Network Implementation
Supports multiple nodes with mining, synchronization, and peer-to-peer communication
"""

import hashlib
import json
from datetime import datetime
import threading
from datetime import datetime
from flask import Flask, request, jsonify
import requests
from urllib.parse import urlparse
import sys
import argparse


class Transaction:
    """Represents a single transaction"""
    def __init__(self, sender, recipient, amount):
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
    
    def to_dict(self):
        return {
            'sender': self.sender,
            'recipient': self.recipient,
            'amount': self.amount,
        }
    
    def __str__(self):
        return json.dumps(self.to_dict())


class Block:
    def __init__(self, index, timestamp, data, previous_hash, nonce=0):
        self.index = index
        self.timestamp = timestamp
        self.data = data
        self.previous_hash = previous_hash
        self.nonce = nonce
        self.hash = self.calculate_hash()
    
    def calculate_hash(self):
        block_string = f"{self.index}{self.timestamp}{json.dumps(self.data, sort_keys=True)}{self.previous_hash}{self.nonce}"
        return hashlib.sha256(block_string.encode()).hexdigest()
    
    def mine_block(self, difficulty):
        target = "0" * difficulty
        print(f"  Mining block {self.index} with difficulty {difficulty}...")
        start_time = datetime.utcnow()
        
        while self.hash[:difficulty] != target:
            self.nonce += 1
            self.hash = self.calculate_hash()
            
            if self.nonce % 10000 == 0:
                print(f"   Nonce: {self.nonce}, Hash: {self.hash[:10]}...")
        
        mining_time = (datetime.utcnow() - start_time).total_seconds()
        print(f" Block mined! Nonce: {self.nonce}, Time: {mining_time:.2f}s")
        print(f"   Hash: {self.hash}")
    
    def to_dict(self):
        return {
            'index': self.index,
            'timestamp': self.timestamp,
            'data': self.data,
            'previous_hash': self.previous_hash,
            'nonce': self.nonce,
            'hash': self.hash
        }


class Blockchain:
    def __init__(self, difficulty=4):
        self.chain = [self.create_genesis_block()]
        self.difficulty = difficulty
        self.pending_transactions = []
        self.mining_reward = 10
    
    # First Block
    def create_genesis_block(self):
        genesis_data = [{
            'sender': 'genesis',
            'recipient': 'genesis',
            'amount': 0,
        }]
        return Block(0, datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), genesis_data, "0")
    
    def get_latest_block(self):
        return self.chain[-1]
    
    def add_transaction(self, transaction):
        self.pending_transactions.append(transaction.to_dict())
        print(f" Transaction added: {transaction.sender} -> {transaction.recipient}: {transaction.amount}")
    
    def mine_pending_transactions(self, mining_reward_address):
        if not self.pending_transactions:
            print("No pending transactions to mine")
            return None
        
        # Reward
        reward_transaction = Transaction("system", mining_reward_address, self.mining_reward)
        self.pending_transactions.append(reward_transaction.to_dict())
        
        # Create block
        new_block = Block(
            len(self.chain),
            datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
            self.pending_transactions,
            self.get_latest_block().hash
        )
        
        # Mine it
        new_block.mine_block(self.difficulty)
        
        self.chain.append(new_block)
        self.pending_transactions = []
        
        return new_block
    
    def is_chain_valid(self):
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i-1]
            
            if current_block.hash != current_block.calculate_hash():
                print(f"Invalid hash at block {i}")
                return False
            
            if current_block.previous_hash != previous_block.hash:
                print(f"Invalid previous hash at block {i}")
                return False
            
            if current_block.hash[:self.difficulty] != "0" * self.difficulty:
                print(f"Invalid proof of work at block {i}")
                return False
        
        return True
    
    def replace_chain(self, new_chain):
        new_blockchain = []
        for block_data in new_chain:
            block = Block(
                block_data['index'],
                block_data['timestamp'],
                block_data['data'],
                block_data['previous_hash'],
                block_data['nonce']
            )
            block.hash = block_data['hash']
            new_blockchain.append(block)
        
        old_chain = self.chain
        self.chain = new_blockchain

        # Longest Chain Rule
        if len(new_blockchain) > len(old_chain) and self.is_chain_valid():
            print(f"Chain replaced! New length: {len(new_blockchain)}")
            return True
        else:
            self.chain = old_chain
            print(f"Chain replacement rejected")
            return False
    
    def to_dict(self):
        return [block.to_dict() for block in self.chain]


class BitcoinNode:
    def __init__(self, port, difficulty=4):
        self.port = port
        self.blockchain = Blockchain(difficulty)
        self.peers = set()
        self.app = Flask(__name__)
        self.node_id = f"node_{port}"
        self.is_mining = False
        
        self.setup_routes()
        
    # Flask  
    def setup_routes(self):
        @self.app.route('/chain', methods=['GET'])
        def get_chain():
            return jsonify({
                'length': len(self.blockchain.chain),
                'chain': self.blockchain.to_dict()
            })
        
        @self.app.route('/transaction', methods=['POST'])
        def add_transaction():
            data = request.get_json()
            
            required_fields = ['sender', 'recipient', 'amount']
            if not all(field in data for field in required_fields):
                return jsonify({'error': 'Missing required fields'}), 400
            
            transaction = Transaction(
                data['sender'],
                data['recipient'],
                data['amount']
            )
            
            self.blockchain.add_transaction(transaction)
            
            return jsonify({
                'message': 'Transaction added to pending transactions',
                'transaction': transaction.to_dict()
            })
        
        @self.app.route('/mine', methods=['GET'])
        def mine():
            if self.is_mining:
                return jsonify({'message': 'Already mining'}), 400
            
            self.is_mining = True
            
            try:
                new_block = self.blockchain.mine_pending_transactions(self.node_id)
                
                if new_block is None:
                    return jsonify({'message': 'No transactions to mine'}), 400
                
                self.broadcast_block(new_block)
                
                return jsonify({
                    'message': 'Block mined successfully',
                    'block': new_block.to_dict()
                })
            
            finally:
                self.is_mining = False
        
        @self.app.route('/peers', methods=['GET'])
        def get_peers():
            return jsonify({'peers': list(self.peers)})
        
        @self.app.route('/peers', methods=['POST'])
        def add_peer():
            data = request.get_json()
            peer_url = data.get('peer_url')
            
            if not peer_url:
                return jsonify({'error': 'peer_url required'}), 400
            
            self.peers.add(peer_url)
            return jsonify({'message': f'Peer {peer_url} added'})
        
        @self.app.route('/block', methods=['POST'])
        def receive_block():
            data = request.get_json()
            
            received_block = Block(
                data['index'],
                data['timestamp'],
                data['data'],
                data['previous_hash'],
                data['nonce']
            )
            received_block.hash = data['hash']
            
            if self.validate_and_add_block(received_block):
                return jsonify({'message': 'Block accepted'})
            else:
                return jsonify({'message': 'Block rejected'}), 400
        
        @self.app.route('/sync', methods=['GET'])
        def sync_chain():
            self.synchronize_with_network()
            return jsonify({
                'message': 'Synchronization completed',
                'chain_length': len(self.blockchain.chain)
            })
        
        @self.app.route('/status', methods=['GET'])
        def get_status():
            return jsonify({
                'node_id': self.node_id,
                'chain_length': len(self.blockchain.chain),
                'pending_transactions': len(self.blockchain.pending_transactions),
                'peers_count': len(self.peers),
                'is_mining': self.is_mining,
                'difficulty': self.blockchain.difficulty
            })
    
    def validate_and_add_block(self, new_block):
        latest_block = self.blockchain.get_latest_block()
        
        if new_block.index == latest_block.index + 1:
            if new_block.previous_hash == latest_block.hash:
                if (new_block.hash == new_block.calculate_hash() and
                    new_block.hash[:self.blockchain.difficulty] == "0" * self.blockchain.difficulty):
                    
                    self.blockchain.chain.append(new_block)
                    print(f"Block {new_block.index} added to chain")
                    
                    block_transactions = [json.dumps(tx, sort_keys=True) for tx in new_block.data]
                    self.blockchain.pending_transactions = [
                        tx for tx in self.blockchain.pending_transactions
                        if json.dumps(tx, sort_keys=True) not in block_transactions
                    ]
                    
                    return True
        
        print(f"Block validation failed or chain behind, requesting synchronization")
        self.synchronize_with_network()
        return False
    
    def broadcast_block(self, block):
        for peer in self.peers:
            try:
                response = requests.post(
                    f"{peer}/block",
                    json=block.to_dict(),
                    timeout=5
                )
                print(f"Block broadcast to {peer}: {response.status_code}")
            except Exception as e:
                print(f"Failed to broadcast to {peer}: {e}")
    
    def synchronize_with_network(self):
        longest_chain = None
        max_length = len(self.blockchain.chain)
        
        for peer in self.peers:
            try:
                response = requests.get(f"{peer}/chain", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    chain_length = data['length']
                    
                    if chain_length > max_length:
                        max_length = chain_length
                        longest_chain = data['chain']
                        print(f"Found longer chain at {peer}: {chain_length} blocks")
            
            except Exception as e:
                print(f"Failed to sync with {peer}: {e}")
        
        if longest_chain:
            if self.blockchain.replace_chain(longest_chain):
                print(f"Blockchain synchronized with network")
            else:
                print(f"Failed to replace chain")
    
    def connect_to_peer(self, peer_url):
        try:
            self.peers.add(peer_url)
            
            requests.post(
                f"{peer_url}/peers",
                json={'peer_url': f'http://localhost:{self.port}'},
                timeout=5
            )
            
            print(f"Connected to peer: {peer_url}")
            
            self.synchronize_with_network()
            
        except Exception as e:
            print(f"Failed to connect to peer {peer_url}: {e}")
    
    def run(self, host='localhost', debug=False):
        print(f"Starting BTC Node on http://{host}:{self.port}")
        print(f"  Node ID: {self.node_id}")
        print(f"  Difficulty: {self.blockchain.difficulty}")
        self.app.run(host=host, port=self.port, debug=debug, threaded=True)


def main():
    parser = argparse.ArgumentParser(description='BTC Network Node')
    parser.add_argument('--port', type=int, default=5000)
    parser.add_argument('--difficulty', type=int, default=4)
    parser.add_argument('--peer', type=str)
    
    args = parser.parse_args()
    
    node = BitcoinNode(args.port, args.difficulty)
    
    if args.peer:
        server_thread = threading.Thread(
            target=lambda: node.run(debug=False),
            daemon=True
        )
        server_thread.start()
        
        time.sleep(5)
        node.connect_to_peer(args.peer)
        
        try:
            server_thread.join()
        except KeyboardInterrupt:
            print("\n Shutting down node...")
    else:
        try:
            node.run(debug=False)
        except KeyboardInterrupt:
            print("\n Shutting down node...")


if __name__ == '__main__':
    main()