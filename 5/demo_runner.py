#!/usr/bin/env python3
import subprocess
import time
import requests
import signal
import sys
import os
import json

class NetworkDemo:
    def __init__(self):
        self.processes = []
        self.logfiles = []
        self.nodes = [
            {'port': 5000, 'name': 'Node 1'},
            {'port': 5001, 'name': 'Node 2'},
            {'port': 5002, 'name': 'Node 3'}
        ]
    
    def start_nodes(self):
        print("Starting Demo...")
        for node in self.nodes:
            log_path = f"node_{node['port']}.log"
            logfile = open(log_path, "w")
            proc = subprocess.Popen([
                sys.executable, "bitcoin_network.py",
                "--port", str(node['port']),
                "--difficulty", "3"
            ], stdout=logfile, stderr=logfile)
            self.processes.append(proc)
            self.logfiles.append(log_path)
            time.sleep(1)
        print("All nodes ready")
        return True
    
    def wait_for_nodes(self):
        print(" Waiting for nodes to be ready...")
        for node in self.nodes:
            while True:
                try:
                    response = requests.get(f"http://localhost:{node['port']}/status", timeout=2)
                    if response.status_code == 200:
                        print(f" {node['name']} is ready")
                        break
                except:
                    pass
                time.sleep(1)

    def connect_peer(self, a, b, bidirectional=False):
        try:
            node_a = self.nodes[a - 1]
            node_b = self.nodes[b - 1]
            peer_url = f"http://localhost:{node_b['port']}"
            response = requests.post(
                f"http://localhost:{node_a['port']}/peers",
                json={"peer_url": peer_url},
                timeout=5
            )
            if response.status_code == 200:
                print(f"DEBUG: {node_a['name']} connected to {node_b['name']}")
            else:
                print(f"DEBUG: Failed to connect {node_a['name']} -> {node_b['name']}: {response.text}")
            if bidirectional:
                self.connect_peer(b, a, bidirectional=False)
        except Exception as e:
            print(f"DEBUG: Error connecting nodes: {e}")

    def show_network_status(self):
        print("\n Network Status:")
        print("=" * 60)
        for node in self.nodes:
            self.show_network_status_single(self.nodes.index(node) + 1)

    def show_network_status_single(self, node_idx):
        node = self.nodes[node_idx - 1]
        print(f"\n  {node['name']} (Port {node['port']}):")
        try:
            status_response = requests.get(f"http://localhost:{node['port']}/status", timeout=5)
            chain_response = requests.get(f"http://localhost:{node['port']}/chain", timeout=5)
            if status_response.status_code == 200 and chain_response.status_code == 200:
                status_data = status_response.json()
                chain_data = chain_response.json()
                print(f"   Chain Length: {status_data['chain_length']}")
                print(f"   Pending Transactions: {status_data['pending_transactions']}")
                print(f"   Connected Peers: {status_data['peers_count']}")
                print(f"   Is Mining: {status_data['is_mining']}")
                if len(chain_data['chain']) > 1:
                    latest_block = chain_data['chain'][-1]
                    print(f"   Latest Block Hash: {latest_block['hash'][:16]}...")
                    print(f"   Latest Block Transactions: {len(latest_block['data'])}")
        except Exception as e:
            print(f"   DEBUG: Failed to get status for {node['name']}: {e}")

    def demo_transactions(self, node_idx):
        node = self.nodes[node_idx - 1]
        tx = {'sender': 'Alice', 'recipient': 'Bob', 'amount': 5.0}
        print(f"DEBUG: Adding transaction on {node['name']}")
        try:
            response = requests.post(f"http://localhost:{node['port']}/transaction", json=tx, timeout=5)
            if response.status_code == 200:
                print(" Transaction added")
            else:
                print(" Transaction failed")
        except Exception as e:
            print(f"DEBUG: Error adding transaction: {e}")

    def demo_mine(self, node_idx):
        node = self.nodes[node_idx - 1]
        print(f"DEBUG: Mining on {node['name']}")
        try:
            response = requests.get(f"http://localhost:{node['port']}/mine", timeout=30)
            if response.status_code == 200:
                print(" Mined successfully")
            else:
                print(" Mining failed")
        except Exception as e:
            print(f"DEBUG: Mining error: {e}")

    def demo_sync(self, node_idx):
        node = self.nodes[node_idx - 1]
        print(f"DEBUG: Sync on {node['name']}")
        try:
            response = requests.get(f"http://localhost:{node['port']}/sync", timeout=10)
            if response.status_code == 200:
                print(" Sync successful")
            else:
                print(" Sync failed")
        except Exception as e:
            print(f"DEBUG: Sync error: {e}")
    
    def demo_chain(self, node_idx):
        node = self.nodes[node_idx - 1]
        print(f"DEBUG: Get chain on {node['name']}")
        try:
            response = requests.get(f"http://localhost:{node['port']}/chain", timeout=10)
            if response.status_code == 200:
                chain_data = response.json()
                print(json.dumps(chain_data, indent=2, sort_keys=False))
            else:
                print(f" Chain failed: {response.text}")
        except Exception as e:
            print(f"DEBUG: Chain error: {e}")

    def run_demo(self):
        try:
            if not self.start_nodes():
                return False
            self.wait_for_nodes()
            print("DEBUG: Nodes started successfully. Use tail -f node_<port>.log to watch server logs")

            menu = """
Available commands:
  1. status        - Show network status (node a, 0 for all)
  2. tx            - Add transactions (node a)
  3. mine          - mining (node a)
  4. sync          - sync (node a)
  5. connect       - Connect peer (a -> b)
  6. chain         - Show chain (node a)
  7. exit          - Stop all nodes and cleanup
"""

            while True:
                print(menu)
                choice = input("Enter command: ").strip().lower()

                if choice in ["1", "status"]:
                    node = int(input(" Node number (0 for all): ").strip())
                    if node == 0:
                        self.show_network_status()
                    else:
                        self.show_network_status_single(node)
                elif choice in ["2", "tx"]:
                    node = int(input(" Node number: ").strip())
                    self.demo_transactions(node)
                elif choice in ["3", "mine"]:
                    node = int(input(" Node number: ").strip())
                    self.demo_mine(node)
                elif choice in ["4", "sync"]:
                    node = int(input(" Node number: ").strip())
                    self.demo_sync(node)
                elif choice in ["5", "connect"]:
                    a = int(input(" Enter node number a: ").strip())
                    b = int(input(" Enter node number b: ").strip())
                    self.connect_peer(a, b, bidirectional=False)
                elif choice in ["6", "chain"]:
                    node = int(input(" Node number: ").strip())
                    self.demo_chain(node)
                elif choice in ["7", "exit", "quit"]:
                    break
                else:
                    print("DEBUG: Unknown command")
                time.sleep(1)

        except Exception as e:
            print(f"DEBUG: Demo failed: {e}")
        finally:
            self.cleanup()

    def cleanup(self):
        print("\n Cleaning up...")
        for proc in self.processes:
            proc.terminate()
        time.sleep(2)
        for proc in self.processes:
            if proc.poll() is None:
                proc.kill()
        for log_path in self.logfiles:
            try:
                os.remove(log_path)
                print(f" Removed {log_path}")
            except FileNotFoundError:
                pass
        print("All nodes stopped.")

def main():
    demo = NetworkDemo()
    def signal_handler(sig, frame):
        demo.cleanup()
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)
    demo.run_demo()

if __name__ == '__main__':
    main()
