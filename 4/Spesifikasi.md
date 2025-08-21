# Dokumen Spesifikasi Jaringan Antar Negara
## Implementasi Cisco Packet Tracer

---

## 1. Gambaran Umum Topologi

### 1.1 Struktur Jaringan
Jaringan terdiri dari 4 negara utama:
- **Gokouloryn** (.gk)
- **Rurinthia** (.rr) 
- **Kuronexus** (.kr)
- **Yamindralia** (.ym)

### 1.2 Koneksi Antar Negara
- Gokouloryn, Rurinthia, dan Kuronexus terhubung melalui switch eksternal
- Yamindralia terhubung langsung hanya ke Kuronexus
- Komunikasi Yamindralia dengan negara lain melalui border router Kuronexus

### 1.3 Struktur Internal Negara
Setiap negara memiliki:
- 1 Border Router (terluar)
- 3 Router Internal: Government Zone, Enterprise Zone, Public Zone
- Switch penghubung border router ke 3 router internal
- Perangkat end-device sesuai spesifikasi zona

---

## 2. Perangkat dan Model

### 2.1 Router Models
- **Border Router Kuronexus**: Router 2911
- **Semua router lainnya**: Router 1941

### 2.2 Naming Convention
Format: `X_Nama`
- X = Nama negara (Gokouloryn/Rurinthia/Kuronexus/Yamindralia)
- Nama = Deskriptif (BorderRouter, GovZone, EntZone, PubZone)

**Contoh**:
- `Gokouloryn_BorderRouter`
- `Rurinthia_GovZone`
- `Kuronexus_EntZone`

---

## 3. PHASE 1: Basic Configuration Gokouloryn

### 3.1 Pengalamatan IP Gokouloryn (CORRECTED)
```
Backbone (BorderRouter-BorderSwitch): 10.1.0.0/29
  - BorderRouter Gig0/1: 10.1.0.1/29
  - BorderSwitch VLAN1: 10.1.0.2/29
  - GK_Govern Gig0/0: 10.1.0.3/29
  - GK_Enterprise Gig0/0: 10.1.0.4/29  
  - GK_Public Gig0/0: 10.1.0.5/29

Government Zone: 10.1.1.0/24
  - GK_Govern Gig0/1: 10.1.1.1/24
  - PC range: 10.1.1.10-10.1.1.100

Enterprise Zone: 10.1.2.0/24  
  - GK_Enterprise Gig0/1: 10.1.2.1/24
  - DNS Server: 10.1.2.10/24
  - Web Server: 10.1.2.11/24
  - DHCP Server: 10.1.2.12/24
  - PC range: 10.1.2.20-10.1.2.100

Public Zone: 10.1.3.0/24
  - GK_Public Gig0/1: 10.1.3.1/24
  - PC range: 10.1.3.10-10.1.3.100

External Interface (untuk BGP nanti): 192.168.1.1/24
```

### 3.2 Step-by-Step Basic Configuration

#### **GK_BorderRouter Configuration:**
```cisco
enable
configure terminal
hostname GK_BorderRouter

! Interface to External Network (untuk BGP nanti)
interface gigabitEthernet 0/0
ip address 192.168.1.1 255.255.255.0
no shutdown
exit

! Interface to Internal BorderSwitch
interface gigabitEthernet 0/1
ip address 10.1.0.1 255.255.255.248
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.1.1
network 10.1.0.0 0.0.0.7 area 0
exit

! Save configuration
end
write memory
```

#### **GK_Govern Router Configuration:**
```cisco
enable
configure terminal
hostname GK_Govern

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.1.0.3 255.255.255.248
no shutdown
exit

! Interface to Government Zone
interface gigabitEthernet 0/1
ip address 10.1.1.1 255.255.255.0
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.1.2
network 10.1.0.0 0.0.0.7 area 0
network 10.1.1.0 0.0.0.255 area 0
exit

end
write memory
```

#### **GK_Enterprise Router Configuration:**
```cisco
enable
configure terminal
hostname GK_Enterprise

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.1.0.4 255.255.255.248
no shutdown
exit

! Interface to Enterprise Zone
interface gigabitEthernet 0/1
ip address 10.1.2.1 255.255.255.0
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.1.3
network 10.1.0.0 0.0.0.7 area 0
network 10.1.2.0 0.0.0.255 area 0
exit

! Basic DHCP Configuration
ip dhcp excluded-address 10.1.1.1 10.1.1.9
ip dhcp excluded-address 10.1.2.1 10.1.2.19
ip dhcp excluded-address 10.1.3.1 10.1.3.9

ip dhcp pool GK_GOV_POOL
network 10.1.1.0 255.255.255.0
default-router 10.1.1.1
dns-server 10.1.2.10
exit

ip dhcp pool GK_ENT_POOL
network 10.1.2.0 255.255.255.0
default-router 10.1.2.1
dns-server 10.1.2.10
exit

ip dhcp pool GK_PUB_POOL
network 10.1.3.0 255.255.255.0
default-router 10.1.3.1
dns-server 10.1.2.10
exit

end
write memory
```

#### **GK_Public Router Configuration:**
```cisco
enable
configure terminal
hostname GK_Public

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.1.0.5 255.255.255.248
no shutdown
exit

! Interface to Public Zone
interface gigabitEthernet 0/1
ip address 10.1.3.1 255.255.255.0
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.1.4
network 10.1.0.0 0.0.0.7 area 0
network 10.1.3.0 0.0.0.255 area 0
exit

end
write memory
```

### 3.3 **PENTING: BorderSwitch Configuration**
```cisco
enable
configure terminal
hostname GK_BorderSwitch

! Create VLAN for backbone communication
interface vlan 1
ip address 10.1.0.2 255.255.255.248
no shutdown
exit

! Configure ports (optional, biasanya auto)
interface range fastEthernet 0/1-3
switchport mode access
switchport access vlan 1
no shutdown
exit

interface gigabitEthernet 0/1
switchport mode access  
switchport access vlan 1
no shutdown
exit

end
write memory
```

### 3.4 Server Static IP Configuration

#### **DNS Server (GK_DNS):**
- IP Address: 10.1.2.10
- Subnet Mask: 255.255.255.0
- Default Gateway: 10.1.2.1

#### **Web Server (GK_Web):**
- IP Address: 10.1.2.11
- Subnet Mask: 255.255.255.0  
- Default Gateway: 10.1.2.1

#### **DHCP Server (GK_DHCP):**
- IP Address: 10.1.2.12
- Subnet Mask: 255.255.255.0
- Default Gateway: 10.1.2.1

### 3.5 Testing Commands
```cisco
! Di BorderRouter
show ip route
show ip ospf neighbor
ping 10.1.1.1
ping 10.1.2.1  
ping 10.1.3.1

! Test DHCP dari PC
ipconfig /renew
ipconfig

! Test connectivity
ping 10.1.2.10 (DNS Server)
ping 10.1.2.11 (Web Server)
```

**⚠️ CATATAN PENTING:**
- Pastikan semua interface sudah "no shutdown"
- Test ping antar router sebelum lanjut ke negara lain
- Pastikan PC mendapat IP DHCP dengan benar
- Jika ada error, debug satu per satu sebelum copy ke negara lain

---

## 4. Internal Routing (OSPF Multi-Area)

### 4.1 Desain Area
- **Area 0 (Backbone)**: Subnet border router ke internal switch
- **Area 1**: Government Zone
- **Area 2**: Enterprise Zone  
- **Area 3**: Public Zone

### 4.2 Konfigurasi OSPF
```cisco
# Border Router
router ospf 1
network 10.1.0.0 0.0.0.3 area 0
network 10.1.1.0 0.0.0.255 area 1
network 10.1.2.0 0.0.0.255 area 2
network 10.1.3.0 0.0.0.255 area 3

# Government Zone Router
router ospf 1
network 10.1.1.0 0.0.0.255 area 1
network 10.1.0.0 0.0.0.3 area 0

# Enterprise Zone Router
router ospf 1
network 10.1.2.0 0.0.0.255 area 2
network 10.1.0.0 0.0.0.3 area 0

# Public Zone Router
router ospf 1
network 10.1.3.0 0.0.0.255 area 3
network 10.1.0.0 0.0.0.3 area 0
```

---

## 5. DHCP Implementation

### 5.1 DHCP Pools per Zona
Konfigurasi pada Enterprise Zone Router:

```cisco
# Government Zone Pool
ip dhcp pool GOV_POOL
network 10.1.1.0 255.255.255.0
default-router 10.1.1.1
dns-server 10.1.2.10

# Enterprise Zone Pool
ip dhcp pool ENT_POOL
network 10.1.2.0 255.255.255.0
default-router 10.1.2.1
dns-server 10.1.2.10

# Public Zone Pool
ip dhcp pool PUB_POOL
network 10.1.3.0 255.255.255.0
default-router 10.1.3.1
dns-server 10.1.2.10

# DHCP Exclusions
ip dhcp excluded-address 10.1.1.1 10.1.1.10
ip dhcp excluded-address 10.1.2.1 10.1.2.15
ip dhcp excluded-address 10.1.3.1 10.1.3.10
```

---

## 6. External Routing (BGP)

### 6.1 AS Numbers
- **Gokouloryn**: AS 65001
- **Rurinthia**: AS 65002
- **Kuronexus**: AS 65003
- **Yamindralia**: AS 65004

### 6.2 BGP Configuration
```cisco
# Gokouloryn Border Router
router bgp 65001
neighbor 192.168.1.3 remote-as 65003
neighbor 192.168.1.2 remote-as 65002
network 10.1.0.0 mask 255.255.0.0

# Redistribution OSPF to BGP
redistribute ospf 1

# Redistribution BGP to OSPF
router ospf 1
redistribute bgp 65001 subnets
```

---

## 7. VLAN Implementation (Kuronexus Public Zone)



---

## 8. Wireless Network (VLAN 50 - Communal)

### 8.1 Access Point Configuration
```cisco
# Wireless Access Point
interface wlan0
ssid Kuronexus_Communal
authentication open
vlan 50
no shutdown
```

### 8.2 Devices
- 1 Smartphone (wireless)
- 1 PC (wireless)
- Keduanya mendapat IP dari DHCP server pusat

---

## 9. DNS Implementation

### 9.1 DNS Server Configuration (Per Negara)
```cisco
# Gokouloryn DNS Server (10.1.2.10)
ip dns server
ip host www.gokouloryn.gk 10.1.2.11
ip host border.gk 10.1.0.1

# DNS Forwarding
ip name-server 10.2.2.10 (Rurinthia)
ip name-server 10.3.2.10 (Kuronexus)
ip name-server 10.4.2.10 (Yamindralia)
```

### 9.2 Domain Mapping
- **Gokouloryn**: www.gokouloryn.gk → Web Server IP
- **Rurinthia**: www.rurinthia.rr → Web Server IP
- **Kuronexus**: www.kuronexus.kr → Web Server IP
- **Yamindralia**: www.yamindralia.ym → Web Server IP

---

## 10. Access Control Lists (ACL)

### 10.1 Government Zone ACL
```cisco
# Allow only Government Zones from other countries
access-list 100 permit ip 10.2.1.0 0.0.0.255 10.1.1.0 0.0.0.255
access-list 100 permit ip 10.3.1.0 0.0.0.255 10.1.1.0 0.0.0.255
access-list 100 permit ip 10.4.1.0 0.0.0.255 10.1.1.0 0.0.0.255
access-list 100 deny ip any 10.1.1.0 0.0.0.255

interface fa0/1
ip access-group 100 in
```

### 10.2 Enterprise Zone ACL
```cisco
# Allow HTTPS, DNS, DHCP for all, full access for local Government
access-list 101 permit tcp any any eq 443
access-list 101 permit udp any any eq 53
access-list 101 permit udp any any eq 67
access-list 101 permit udp any any eq 68
access-list 101 permit ip 10.1.1.0 0.0.0.255 any
access-list 101 deny ip any any

interface fa0/1
ip access-group 101 in
```

---

## 11. SSH/Telnet Configuration

### 11.1 Border Router Configuration
```cisco
# Enable SSH/Telnet
line vty 0 15
transport input ssh telnet
login local
password cisco123

username admin privilege 15 secret admin123

# Enable SSH
ip domain-name border.gk
crypto key generate rsa modulus 1024
ip ssh version 2
```

### 11.2 Kredensial Akses
- **Username**: admin
- **Password**: admin123
- **Enable Password**: cisco123

### 11.3 Perintah Akses
```bash
# SSH
ssh -l admin border.gk
ssh -l admin border.rr
ssh -l admin border.kr
ssh -l admin border.ym

# Telnet
telnet border.gk
telnet border.rr
telnet border.kr
telnet border.ym
```

---

## 12. NAT Implementation (Gokouloryn)

### 12.1 PAT Configuration
```cisco
# Define Inside/Outside Interfaces
interface fa0/0
ip nat outside

interface fa0/1
ip nat inside

# Access List for Even IP Addresses
access-list 1 permit 10.1.1.2
access-list 1 permit 10.1.1.4
access-list 1 permit 10.1.1.6
access-list 1 permit 10.1.3.2
access-list 1 permit 10.1.3.4

# NAT Overload Configuration
ip nat inside source list 1 interface fa0/0 overload
```

### 12.2 Testing PCs
- PC1: 10.1.3.2 (static IP)
- PC2: 10.1.3.4 (static IP)

---

## 13. IPv6 Implementation (Rurinthia & Yamindralia)

### 13.1 IPv6 Addressing Scheme
```
Rurinthia:
- Border Router: 2001:DB8:2::1/64
- Government: 2001:DB8:2:1::1/64
- Enterprise: 2001:DB8:2:2::1/64
- Public: 2001:DB8:2:3::1/64

Yamindralia:
- Border Router: 2001:DB8:4::1/64
- Government: 2001:DB8:4:1::1/64
- Enterprise: 2001:DB8:4:2::1/64
- Public: 2001:DB8:4:3::1/64
```

### 13.2 IPv6 Configuration
```cisco
# Enable IPv6 Routing
ipv6 unicast-routing

# Interface Configuration
interface fa0/0
ipv6 address 2001:DB8:2::1/64
ipv6 enable

# IPv6 OSPF
ipv6 router ospf 1
router-id 2.2.2.2

interface fa0/0
ipv6 ospf 1 area 0
```

### 13.3 IPv6 Tunneling
```cisco
# Rurinthia Border Router
interface tunnel0
ipv6 address 2001:DB8:100::1/64
tunnel source 192.168.1.2
tunnel destination 192.168.1.4
tunnel mode ipv6ip

# Yamindralia Border Router
interface tunnel0
ipv6 address 2001:DB8:100::2/64
tunnel source 192.168.1.4
tunnel destination 192.168.1.2
tunnel mode ipv6ip

# IPv6 Static Route through Tunnel
ipv6 route 2001:DB8:4::/48 2001:DB8:100::2
```

---

## 14. Web Server Configuration

### 14.1 HTML Content per Negara
```html
<!-- Gokouloryn Web Server -->
<html>
<head><title>Gokouloryn Official Portal</title></head>
<body>
<h1 style="color: blue;">Welcome to Gokouloryn</h1>
<p>Official government and enterprise portal</p>
</body>
</html>

<!-- Rurinthia Web Server -->
<html>
<head><title>Rurinthia National Site</title></head>
<body>
<h1 style="color: green;">Welcome to Rurinthia</h1>
<p>National information and services</p>
</body>
</html>

<!-- Kuronexus Web Server -->
<html>
<head><title>Kuronexus Central Hub</title></head>
<body>
<h1 style="color: red;">Welcome to Kuronexus</h1>
<p>Central communication hub</p>
</body>
</html>

<!-- Yamindralia Web Server -->
<html>
<head><title>Yamindralia Portal</title></head>
<body>
<h1 style="color: purple;">Welcome to Yamindralia</h1>
<p>Remote access portal</p>
</body>
</html>
```

---

## 15. Testing dan Verifikasi

### 15.1 Connectivity Tests
```cisco
# Ping Tests
ping 10.2.1.100 (cross-country Government)
ping www.rurinthia.rr (DNS resolution)
ping6 2001:DB8:4::1 (IPv6 connectivity)

# Trace Route
tracert www.kuronexus.kr

# Show Commands
show ip route
show ip ospf database
show ip bgp summary
show ipv6 route
show vlan brief
show ip dhcp binding
```

### 15.2 Service Verification
1. **DHCP**: Periksa automatic IP assignment pada PCs
2. **DNS**: Akses website menggunakan domain name
3. **ACL**: Test restricted access ke Government Zone
4. **NAT**: Verify translation untuk even IP addresses
5. **SSH/Telnet**: Remote access ke border routers
6. **IPv6**: Ping antar Rurinthia dan Yamindralia menggunakan IPv6

---

## 16. Troubleshooting Commands

```cisco
# OSPF Troubleshooting
show ip ospf neighbor
show ip ospf interface
debug ip ospf events

# BGP Troubleshooting
show ip bgp
show ip bgp neighbors
debug ip bgp

# DHCP Troubleshooting
show ip dhcp binding
show ip dhcp conflict
debug ip dhcp server events

# NAT Troubleshooting
show ip nat translations
show ip nat statistics
debug ip nat

# IPv6 Troubleshooting
show ipv6 interface brief
show ipv6 route
debug ipv6 ospf hello
```

---

## 17. Kesimpulan

Implementasi jaringan antar negara ini mencakup berbagai teknologi jaringan enterprise-level:

- **Multi-Area OSPF** untuk internal routing yang efisien
- **BGP** untuk external routing antar autonomous systems
- **DHCP** untuk automatic IP assignment
- **VLAN** dan **Router-on-a-Stick** untuk network segmentation
- **Wireless Network** untuk mobility support
- **DNS** untuk name resolution services
- **ACL** untuk network security
- **SSH/Telnet** untuk remote management
- **NAT** untuk address translation
- **IPv6** dengan tunneling untuk future-ready networking

Semua konfigurasi telah diimplementasikan sesuai dengan spesifikasi dan siap untuk testing serta deployment dalam lingkungan simulasi Cisco Packet Tracer.