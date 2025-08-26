## 1. Gambaran Umum Topologi

### 1.1 Struktur Jaringan
Jaringan terdiri dari 4 negara utama:
- **Gokouloryn** (.gk)
- **Rurinthia** (.rr) 
- **Kuronexus** (.kr)
- **Yamindralia** (.ym)

### 1.2 Struktur Internal Negara
Setiap negara memiliki:
- 1 Border Router (terluar)
- 3 Router Internal: Government Zone, Enterprise Zone, Public Zone
- Switch penghubung border router ke 3 router internal
- Perangkat end-device sesuai spesifikasi zona

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

## 3. Basic Configuration
Pada contoh ini <XX> adalah kode negara. <Y> adalah angka yang bersesuaian
Contoh: Gokouloryn = <XX> -> GK dan <Y> -> 1
RR, 2
KR, 3
YM, 4
<XX> = 10.<Y>.x.x dengan external 192.168.1.<Y>
Contoh:
GK = 10.1.x.x dengan external  192.168.1.1
RR = 10.2.x.x dengan external  192.168.1.2
KR = 10.3.x.x dengan external  192.168.1.3
YM = 10.4.x.x dengan external  192.168.1.4

### OSPF multi area
- **Area 0 (Backbone)**: Subnet border router ke internal switch
- **Area 1**: Government Zone
- **Area 2**: Enterprise Zone  
- **Area 3**: Public Zone

### 3.1 Pengalamatan IP
```
Backbone (BorderRouter-BorderSwitch): 10.<Y>.0.0/29
  - <XX>_BorderRouter Gig0/1: 10.<Y>.0.1/29
  - <XX>_BorderSwitch VLAN1: 10.<Y>.0.2/29
  - <XX>_GovZone Gig0/0: 10.<Y>.0.3/29
  - <XX>_EntZone Gig0/0: 10.<Y>.0.4/29  
  - <XX>_PubZone Gig0/0: 10.<Y>.0.5/29

Government Zone: 10.<Y>.1.0/24
  - <XX>_GovZone Gig0/1: 10.<Y>.1.1/24
  - <XX>_PC_Gov range: 10.<Y>.1.10-10.<Y>.1.100

Enterprise Zone: 10.<Y>.2.0/24  
  - <XX>_EntZone Gig0/1: 10.<Y>.2.1/24
  - <XX>_DNS: 10.<Y>.2.10/24
  - <XX>_Web: 10.<Y>.2.11/24
  - <XX>_DHCP: 10.<Y>.2.12/24
  - <XX>_PC_Ent range: 10.<Y>.2.20-10.<Y>.2.100

Public Zone: 10.<Y>.3.0/24
  - <XX>_PubZone Gig0/1: 10.<Y>.3.1/24
  - <XX>_PC_Pub range: 10.<Y>.3.10-10.<Y>.3.100

External Interface: 192.168.1.<Y>/24
```

### **BorderRouter Configuration:**
```cisco
enable
configure terminal
hostname <XX>_BorderRouter

! Interface to External Network
interface gigabitEthernet 0/0
ip address 192.168.1.<Y> 255.255.255.0
no shutdown
exit

! Interface to Internal BorderSwitch
interface gigabitEthernet 0/1
ip address 10.<Y>.0.1 255.255.255.248
ip ospf 1 area 0
no shutdown
exit

! OSPF Configuration
router ospf 1
router-id 1.1.<Y>.1
network 10.<Y>.0.0 0.0.0.7 area 0
redistribute bgp 6500<Y>
exit

! Save configuration
end
write memory
```

#### **Govern Router Configuration:**
```cisco
enable
configure terminal
hostname <XX>_Govern

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.<Y>.0.3 255.255.255.248
ip ospf 1 area 0
no shutdown
exit

! Interface to Government Zone
interface gigabitEthernet 0/1
ip address 10.<Y>.1.1 255.255.255.0
ip helper-address 10.<Y>.0.4
ip ospf 1 area 1
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.<Y>.2
network 10.<Y>.0.0 0.0.0.7 area 0
network 10.<Y>.1.0 0.0.0.255 area 1
exit

end
write memory
```

#### **Enterprise Router Configuration:**
```cisco
enable
configure terminal
hostname <XX>_Enterprise

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.<Y>.0.4 255.255.255.248
ip ospf 1 area 0
no shutdown
exit

! Interface to Enterprise Zone
interface gigabitEthernet 0/1
ip address 10.<Y>.2.1 255.255.255.0
ip ospf 1 area 2
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.<Y>.3
network 10.<Y>.0.0 0.0.0.7 area 0
network 10.<Y>.2.0 0.0.0.255 area 2
exit

end
write memory
```

#### **Public Router Configuration:**
```cisco
enable
configure terminal
hostname <XX>_Public

! Interface to BorderSwitch
interface gigabitEthernet 0/0
ip address 10.<Y>.0.5 255.255.255.248
ip ospf 1 area 0
no shutdown
exit

! Interface to Public Zone
interface gigabitEthernet 0/1
ip address 10.<Y>.3.1 255.255.255.0
ip helper-address 10.<Y>.0.4
ip ospf 1 area 3
no shutdown
exit

! Basic OSPF Configuration
router ospf 1
router-id 1.1.<Y>.4
network 10.<Y>.0.0 0.0.0.7 area 0
network 10.<Y>.3.0 0.0.0.255 area 3
exit

end
write memory
```

### 3.3 **BorderSwitch Configuration**
```cisco
enable
configure terminal
hostname <XX>_BorderSwitch

! Create VLAN for backbone communication
interface vlan 1
ip address 10.<Y>.0.2 255.255.255.248
no shutdown
exit

! Configure ports
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

#### **DNS:**
- IP Address: 10.<Y>.2.10
- Subnet Mask: 255.255.255.0
- Default Gateway: 10.<Y>.2.1
- Service -> DNS
- Nyalakan (Pastikan On)
- Tambahkan ini semua (Name -> Address) :
  www.gokouloryn.gk → 10.1.2.11
  www.rurinthia.rr → 10.2.2.11
  www.kuronexus.kr → 10.3.2.11
  www.yamindralia.ym → 10.4.2.11
  border.gk -> 10.1.0.1
  border.rr -> 10.2.0.1
  border.kr -> 10.3.0.1
  border.ym -> 10.4.0.1

#### **Web:**
- IP Address: 10.<Y>.2.11
- Subnet Mask: 255.255.255.0  
- Default Gateway: 10.<Y>.2.1
- Service -> HTTP
- Nyalakan (Pastikan On)
- Edit index.html ke yang diinginkan

#### **DHCP:**
- IP Address: 10.<Y>.2.12
- Subnet Mask: 255.255.255.0
- Default Gateway: 10.<Y>.2.1

### 3.5 Access Control Lists (ACL)

#### 3.5.1 Government Zone ACL

this is for GK:

```cisco
ip access-list extended 101
    permit ip 10.2.1.0 0.0.0.255 any
    permit ip 10.3.1.0 0.0.0.255 any
    permit ip 10.4.1.0 0.0.0.255 any
    deny icmp any 10.1.1.0 0.0.0.255 echo
    permit icmp any 10.1.1.0 0.0.0.255
    permit tcp any 10.1.1.0 0.0.0.255 established
    permit udp any eq bootps any eq bootpc
    permit udp any eq domain any gt 1023
    deny ip any any

interface gigabitEthernet 0/1
ip access-group 101 out
```

For RR:
change top 3 to other nation BorderRouter IP (Order Does not matter)
after that change 10.1.x.x to 10.<Y>.x.x

#### 4.3.2 Enterprise Zone ACL
This if for GK
```cisco
ip access-list extended 102
    permit ip 10.1.1.0 0.0.0.255 any
    permit tcp any host 10.1.2.11 eq 443
    permit udp any host 10.1.2.12 eq bootps
    permit udp any host 10.1.2.10 eq domain
    deny icmp any 10.1.2.0 0.0.0.255 echo
    permit icmp any 10.1.2.0 0.0.0.255
    deny ip any any

interface gigabitEthernet 0/1
ip access-group 102 out
```

for RR, KR and YM change 10.1.x.x to 10.<Y>.x.x

## 4. Other Configuration

### 4.1. External Routing (BGP)

### 4.1.1 AS Numbers
- **Gokouloryn**: AS 65001
- **Rurinthia**: AS 65002
- **Kuronexus**: AS 65003
- **Yamindralia**: AS 65004

### 4.1.2 BGP Configuration
```cisco
! GK Border Router
router bgp 65001
neighbor 192.168.1.3 remote-as 65003
neighbor 192.168.1.2 remote-as 65002
network 10.1.0.0 mask 255.255.0.0
network 192.168.1.0
redistribute ospf 1
```

```cisco
! RR Border Router
router bgp 65001
neighbor 192.168.1.1 remote-as 65001
neighbor 192.168.1.3 remote-as 65003
network 10.2.0.0 mask 255.255.0.0
redistribute ospf 1
```

```cisco
! KR Border Router
router bgp 65001
neighbor 192.168.1.1 remote-as 65001
neighbor 192.168.1.2 remote-as 65002
neighbor 192.168.1.4 remote-as 65004
network 10.3.0.0 mask 255.255.0.0
redistribute ospf 1
```

```cisco
! Gokouloryn Border Router
router bgp 65001
neighbor 192.168.1.3 remote-as 65003
network 10.4.0.0 mask 255.255.0.0
redistribute ospf 1
```

### 4.2 SSH/Telnet Configuration

#### 4.4.1 Border Router Configuration
```cisco
# Enable SSH/Telnet
line vty 0 15
transport input ssh telnet
login local
password cisco123

username admin privilege 15 secret admin123

# Enable SSH
ip domain-name border.gk
crypto key generate rsa
```

#### 4.4.2 Kredensial Akses
- **Username**: admin
- **Password**: admin123
- **Enable Password**: cisco123

#### 4.4.3 Perintah Akses
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

### 4.3 NAT Implementation

#### 4.5.1 PAT Configuration
```cisco
interface g0/0
ip nat outside

interface g0/1
ip nat inside

access-list 50 permit 10.1.0.0 0.0.255.254

ip nat inside source list 50 interface g0/0 overload
```

### 4.4 VLAN

#### 4.4.1 VLAN Configuration
```cisco
vlan 30
name Academy
vlan 40
name Business
vlan 50
name Communal

# Port Assignment
interface fa0/1
switchport mode access
switchport access vlan 30

interface fa0/2
switchport mode access
switchport access vlan 40

interface fa0/3
switchport mode access
switchport access vlan 50

# Trunk to Router
interface g0/1
switchport mode trunk
switchport trunk allowed vlan 30,40,50
```

#### 4.4.2 Router-on-a-Stick Configuration
```cisco
# Kuronexus Public Zone Router
interface g0/1.30
encapsulation dot1Q 30
ip address 10.3.30.1 255.255.255.0
ip ospf 1 area 30
ip helper-address 10.3.2.12

interface g0/1.40
encapsulation dot1Q 40
ip address 10.3.40.1 255.255.255.0
ip ospf 1 area 40
ip helper-address 10.3.2.12

interface g0/1.50
encapsulation dot1Q 50
ip address 10.3.50.1 255.255.255.0
ip ospf 1 area 50
ip helper-address 10.3.2.12

# OSPF Configuration for VLANs
router ospf 1
network 10.3.30.0 0.0.0.255 area 30
network 10.3.40.0 0.0.0.255 area 40
network 10.3.50.0 0.0.0.255 area 50
```
#### 4.4.3 Wireless config
- Ambil acces point pt, ubah ssid (ex: VLAN50_WIFI)
- Ambil PC, -> Physical, lepas ethernet, tambahkan WMP300N, -> Config, ubash ssid
- Ambil Smartphone, -> Config, -> Wireless 0, ubah ssid