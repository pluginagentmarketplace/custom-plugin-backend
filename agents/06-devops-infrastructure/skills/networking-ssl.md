# Skill: Networking & SSL/TLS Security

## Objective
Master networking fundamentals, implement secure communications with SSL/TLS, configure load balancers and reverse proxies, and secure infrastructure with firewalls and VPNs.

---

## Part 1: TCP/IP Networking Fundamentals

### OSI Model Layers

```
┌─────────────────────────────────────┐
│  7. Application  │ HTTP, FTP, DNS   │
├─────────────────────────────────────┤
│  6. Presentation │ SSL/TLS, ASCII   │
├─────────────────────────────────────┤
│  5. Session      │ NetBIOS, RPC     │
├─────────────────────────────────────┤
│  4. Transport    │ TCP, UDP         │
├─────────────────────────────────────┤
│  3. Network      │ IP, ICMP, Routing│
├─────────────────────────────────────┤
│  2. Data Link    │ Ethernet, MAC    │
├─────────────────────────────────────┤
│  1. Physical     │ Cables, Signals  │
└─────────────────────────────────────┘
```

### TCP/IP Protocol Suite

**IP Addressing**
```
IPv4: 192.168.1.1 (32-bit)
IPv6: 2001:0db8:85a3:0000:0000:8a2e:0370:7334 (128-bit)

Private IP Ranges (RFC 1918):
- 10.0.0.0/8        (10.0.0.0 - 10.255.255.255)
- 172.16.0.0/12     (172.16.0.0 - 172.31.255.255)
- 192.168.0.0/16    (192.168.0.0 - 192.168.255.255)
```

**CIDR Notation**
```
192.168.1.0/24
- Network: 192.168.1.0
- Netmask: 255.255.255.0
- Hosts: 254 (192.168.1.1 - 192.168.1.254)
- Broadcast: 192.168.1.255

Common CIDR Blocks:
/32 = 1 host       (255.255.255.255)
/24 = 254 hosts    (255.255.255.0)
/16 = 65,534 hosts (255.255.0.0)
/8  = 16M hosts    (255.0.0.0)
```

**TCP vs UDP**

| Feature        | TCP                  | UDP                   |
|----------------|----------------------|-----------------------|
| Connection     | Connection-oriented  | Connectionless        |
| Reliability    | Guaranteed delivery  | No guarantee          |
| Ordering       | Ordered packets      | No ordering           |
| Speed          | Slower               | Faster                |
| Use Cases      | HTTP, FTP, SSH       | DNS, VoIP, Streaming  |
| Header Size    | 20 bytes             | 8 bytes               |

### Common Network Commands

```bash
# Check IP address
ip addr show
ifconfig

# Test connectivity
ping 8.8.8.8
ping -c 4 google.com

# Trace route
traceroute google.com
traceroute -n 8.8.8.8

# DNS lookup
nslookup google.com
dig google.com
host google.com

# Check open ports
netstat -tuln              # All listening ports
ss -tuln                   # Modern alternative
lsof -i :80                # Check specific port

# Network statistics
netstat -s                 # Protocol statistics
ss -s                      # Socket statistics

# Check routing table
ip route show
route -n

# Network connections
netstat -an | grep ESTABLISHED
ss -tan state established

# Test port connectivity
telnet example.com 80
nc -zv example.com 80      # Netcat
curl -v telnet://example.com:80

# Packet capture
tcpdump -i eth0 port 80
tcpdump -i eth0 host 192.168.1.1

# Bandwidth monitoring
iftop                      # Interactive
nload                      # Real-time traffic
vnstat                     # Historical stats
```

### Network Troubleshooting Workflow

```bash
# 1. Check network interface
ip link show
ip addr show

# 2. Check local connectivity
ping 127.0.0.1            # Localhost
ping $(hostname -I)       # Own IP

# 3. Check gateway
ip route show | grep default
ping <gateway-ip>

# 4. Check DNS
cat /etc/resolv.conf
nslookup google.com
dig google.com

# 5. Check external connectivity
ping 8.8.8.8              # Google DNS
ping google.com

# 6. Check specific service
telnet example.com 80
curl -v http://example.com

# 7. Check firewall
sudo iptables -L -n -v
sudo ufw status

# 8. Check listening services
sudo netstat -tuln
sudo ss -tuln
```

---

## Part 2: DNS (Domain Name System)

### DNS Hierarchy

```
                    [Root Servers]
                          |
        ┌─────────────────┼─────────────────┐
        |                 |                 |
      [.com]            [.org]            [.net]
        |
    [example.com]
        |
  ┌─────┴─────┐
  |           |
[www]       [api]
```

### DNS Record Types

```bash
# A Record (IPv4 Address)
example.com.    A    192.0.2.1

# AAAA Record (IPv6 Address)
example.com.    AAAA 2001:0db8::1

# CNAME Record (Canonical Name / Alias)
www.example.com. CNAME example.com.

# MX Record (Mail Exchange)
example.com.    MX   10 mail.example.com.

# TXT Record (Text information)
example.com.    TXT  "v=spf1 mx ~all"

# NS Record (Name Server)
example.com.    NS   ns1.nameserver.com.

# SOA Record (Start of Authority)
example.com.    SOA  ns1.example.com. admin.example.com. (
                      2024011501 ; Serial
                      7200       ; Refresh
                      3600       ; Retry
                      1209600    ; Expire
                      86400 )    ; Minimum TTL

# PTR Record (Pointer / Reverse DNS)
1.2.0.192.in-addr.arpa. PTR example.com.

# SRV Record (Service)
_service._proto.example.com. SRV 10 5 5060 sipserver.example.com.
```

### DNS Configuration Examples

**BIND DNS Server Configuration**
```bash
# /etc/bind/named.conf.local
zone "example.com" {
    type master;
    file "/etc/bind/zones/db.example.com";
};

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.1";
};
```

```bash
# /etc/bind/zones/db.example.com
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                        2024011501      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.example.com.
@       IN      NS      ns2.example.com.

; A records
@       IN      A       192.168.1.10
ns1     IN      A       192.168.1.1
ns2     IN      A       192.168.1.2
www     IN      A       192.168.1.10
api     IN      A       192.168.1.11
db      IN      A       192.168.1.12

; CNAME records
mail    IN      CNAME   @
ftp     IN      CNAME   @

; MX records
@       IN      MX      10 mail.example.com.

; TXT records
@       IN      TXT     "v=spf1 mx a ~all"
_dmarc  IN      TXT     "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com"
```

**Cloud DNS with Terraform (AWS Route53)**
```hcl
# route53.tf
resource "aws_route53_zone" "main" {
  name = "example.com"

  tags = {
    Environment = "production"
  }
}

# A record
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}

# CNAME record
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["www.example.com"]
}

# Alias record to ALB
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# MX records
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mail1.example.com",
    "20 mail2.example.com"
  ]
}

# TXT records (SPF)
resource "aws_route53_record" "txt_spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 mx a ip4:192.0.2.1 ~all"]
}
```

### DNS Query with dig

```bash
# Basic query
dig example.com

# Query specific record type
dig example.com A
dig example.com AAAA
dig example.com MX
dig example.com TXT
dig example.com NS

# Query specific DNS server
dig @8.8.8.8 example.com

# Reverse DNS lookup
dig -x 8.8.8.8

# Trace DNS resolution path
dig +trace example.com

# Short answer only
dig example.com +short

# Show all information
dig example.com ANY

# Query with no recursion
dig example.com +norecurse
```

---

## Part 3: HTTP/HTTPS Protocols

### HTTP Request/Response

**HTTP Request**
```http
GET /api/users HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0
Accept: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**HTTP Response**
```http
HTTP/1.1 200 OK
Date: Mon, 15 Jan 2024 12:00:00 GMT
Server: nginx/1.25
Content-Type: application/json
Content-Length: 142
Cache-Control: max-age=3600
Connection: keep-alive

{
  "users": [
    {"id": 1, "name": "John"},
    {"id": 2, "name": "Jane"}
  ]
}
```

### HTTP Methods

```
GET     - Retrieve resource
POST    - Create resource
PUT     - Update/replace resource
PATCH   - Partially update resource
DELETE  - Delete resource
HEAD    - Get headers only
OPTIONS - Get allowed methods
```

### HTTP Status Codes

```
1xx - Informational
100 Continue
101 Switching Protocols

2xx - Success
200 OK
201 Created
204 No Content
206 Partial Content

3xx - Redirection
301 Moved Permanently
302 Found (Temporary Redirect)
304 Not Modified
307 Temporary Redirect
308 Permanent Redirect

4xx - Client Errors
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
405 Method Not Allowed
429 Too Many Requests

5xx - Server Errors
500 Internal Server Error
502 Bad Gateway
503 Service Unavailable
504 Gateway Timeout
```

### HTTP/2 vs HTTP/1.1

| Feature              | HTTP/1.1          | HTTP/2            |
|----------------------|-------------------|-------------------|
| Connection           | Multiple          | Single            |
| Multiplexing         | No                | Yes               |
| Header Compression   | No                | Yes (HPACK)       |
| Server Push          | No                | Yes               |
| Binary Protocol      | No                | Yes               |
| Priority             | No                | Yes               |

### HTTPS (HTTP over TLS)

**HTTPS Handshake Process**
```
Client                                Server
  |                                      |
  |  1. ClientHello                      |
  |------------------------------------->|
  |                                      |
  |  2. ServerHello, Certificate         |
  |<-------------------------------------|
  |                                      |
  |  3. Key Exchange                     |
  |------------------------------------->|
  |                                      |
  |  4. Finished                         |
  |<-------------------------------------|
  |                                      |
  |  5. Encrypted Application Data       |
  |<------------------------------------>|
```

---

## Part 4: SSL/TLS Certificates

### Certificate Components

**X.509 Certificate Structure**
```
Certificate:
  Version: 3
  Serial Number: 04:00:00:00:00:01:15:4b:5a:c3:94
  Signature Algorithm: sha256WithRSAEncryption
  Issuer: C=US, O=Let's Encrypt, CN=R3
  Validity:
    Not Before: Jan 15 00:00:00 2024 GMT
    Not After : Apr 15 23:59:59 2024 GMT
  Subject: CN=example.com
  Subject Public Key Info:
    Public Key Algorithm: rsaEncryption
    RSA Public Key: (2048 bit)
  X509v3 Extensions:
    X509v3 Subject Alternative Name:
      DNS:example.com, DNS:www.example.com
    X509v3 Key Usage: critical
      Digital Signature, Key Encipherment
    X509v3 Extended Key Usage:
      TLS Web Server Authentication
```

### Certificate Types

**1. Domain Validated (DV)**
- Validates domain ownership only
- Issued within minutes
- Free options available (Let's Encrypt)

**2. Organization Validated (OV)**
- Validates organization identity
- Shows organization name
- Takes days to issue

**3. Extended Validation (EV)**
- Highest level of validation
- Shows green address bar (legacy)
- Extensive verification process

**4. Wildcard Certificate**
- Covers all subdomains
- *.example.com covers api.example.com, www.example.com, etc.

**5. Multi-Domain (SAN)**
- Covers multiple domains in single certificate
- example.com, example.org, example.net

### Let's Encrypt with Certbot

**Installation**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

**Obtain Certificate**
```bash
# Standalone mode (stops nginx temporarily)
sudo certbot certonly --standalone -d example.com -d www.example.com

# Nginx plugin (automatic configuration)
sudo certbot --nginx -d example.com -d www.example.com

# Webroot mode (no server downtime)
sudo certbot certonly --webroot -w /var/www/html -d example.com -d www.example.com

# DNS challenge (for wildcard certificates)
sudo certbot certonly --manual --preferred-challenges dns -d example.com -d *.example.com
```

**Certificate Renewal**
```bash
# Test renewal
sudo certbot renew --dry-run

# Renew all certificates
sudo certbot renew

# Renew specific certificate
sudo certbot renew --cert-name example.com

# Auto-renewal (cron job)
# Add to /etc/cron.d/certbot
0 0,12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
```

**Certificate Locations**
```bash
# Certificates stored in:
/etc/letsencrypt/live/example.com/
  ├── cert.pem          # Server certificate
  ├── chain.pem         # Intermediate certificates
  ├── fullchain.pem     # cert.pem + chain.pem
  └── privkey.pem       # Private key
```

### Self-Signed Certificates (Development)

```bash
# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate signing request (CSR)
openssl req -new -key server.key -out server.csr

# Generate self-signed certificate (valid for 365 days)
openssl req -x509 -newkey rsa:2048 -nodes -keyout server.key -out server.crt -days 365

# Generate certificate with SAN
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout server.key \
  -out server.crt \
  -days 365 \
  -subj "/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com,DNS:api.example.com"

# View certificate details
openssl x509 -in server.crt -text -noout

# Verify certificate
openssl verify server.crt
```

### Nginx HTTPS Configuration

```nginx
# /etc/nginx/sites-available/example.com
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # SSL protocols and ciphers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    # SSL session cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Diffie-Hellman parameters
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;

    root /var/www/example.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # Proxy to backend
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Generate DH parameters
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### Testing SSL/TLS Configuration

```bash
# Test SSL certificate
openssl s_client -connect example.com:443 -servername example.com

# Check certificate expiration
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -dates

# Test SSL/TLS configuration
curl -vI https://example.com

# Use SSL Labs for comprehensive testing
# https://www.ssllabs.com/ssltest/

# Test with testssl.sh
git clone https://github.com/drwetter/testssl.sh.git
cd testssl.sh
./testssl.sh example.com
```

---

## Part 5: Load Balancing

### Load Balancing Algorithms

**1. Round Robin**
```
Request 1 → Server A
Request 2 → Server B
Request 3 → Server C
Request 4 → Server A (cycle repeats)
```

**2. Least Connections**
```
Send request to server with fewest active connections
```

**3. IP Hash**
```
Hash client IP to consistently route to same server
Ensures session persistence
```

**4. Weighted Round Robin**
```
Server A (weight: 3) gets 3 requests
Server B (weight: 2) gets 2 requests
Server C (weight: 1) gets 1 request
```

### Nginx Load Balancer Configuration

```nginx
# /etc/nginx/nginx.conf
http {
    # Upstream backend servers
    upstream backend {
        # Load balancing method
        least_conn;  # or: ip_hash, hash $request_uri

        # Servers
        server backend1.example.com:8000 weight=3 max_fails=3 fail_timeout=30s;
        server backend2.example.com:8000 weight=2 max_fails=3 fail_timeout=30s;
        server backend3.example.com:8000 weight=1 max_fails=3 fail_timeout=30s;

        # Backup server
        server backup.example.com:8000 backup;

        # Health check (Nginx Plus)
        # health_check interval=5s fails=3 passes=2;

        # Keepalive connections
        keepalive 32;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    server {
        listen 80;
        server_name example.com;

        # Enable gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

        location / {
            proxy_pass http://backend;

            # Proxy headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Proxy timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # Buffering
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
            proxy_busy_buffers_size 8k;

            # Rate limiting
            limit_req zone=api_limit burst=20 nodelay;
            limit_conn conn_limit 10;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Status page (for monitoring)
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }
    }
}
```

### HAProxy Load Balancer

```bash
# /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # SSL settings
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Frontend (incoming traffic)
frontend http_front
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/example.com.pem

    # Redirect HTTP to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

    # ACLs
    acl is_api path_beg /api
    acl is_static path_beg /static

    # Route to backends
    use_backend api_backend if is_api
    use_backend static_backend if is_static
    default_backend web_backend

# Backend configurations
backend web_backend
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    server web1 192.168.1.10:8000 check inter 2000 rise 2 fall 3
    server web2 192.168.1.11:8000 check inter 2000 rise 2 fall 3
    server web3 192.168.1.12:8000 check inter 2000 rise 2 fall 3 backup

backend api_backend
    balance leastconn
    option httpchk GET /api/health

    server api1 192.168.1.20:8000 check weight 3
    server api2 192.168.1.21:8000 check weight 2
    server api3 192.168.1.22:8000 check weight 1

backend static_backend
    balance source
    server static1 192.168.1.30:8000 check
    server static2 192.168.1.31:8000 check

# Stats page
listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
```

### Kubernetes Load Balancing

```yaml
# service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  selector:
    app: backend
  ports:
    - name: http
      port: 80
      targetPort: 8000
      protocol: TCP
    - name: https
      port: 443
      targetPort: 8000
      protocol: TCP
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

---

## Part 6: Firewalls & Security

### iptables (Linux Firewall)

```bash
# View current rules
sudo iptables -L -n -v

# Save rules
sudo iptables-save > /etc/iptables/rules.v4

# Restore rules
sudo iptables-restore < /etc/iptables/rules.v4

# Basic firewall setup
# Flush existing rules
sudo iptables -F
sudo iptables -X

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow specific IP range
sudo iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# Rate limiting (prevent DDoS)
sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Block specific IP
sudo iptables -A INPUT -s 203.0.113.0 -j DROP

# Port forwarding
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80

# Log dropped packets
sudo iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: "
sudo iptables -A INPUT -j DROP
```

### UFW (Uncomplicated Firewall)

```bash
# Enable UFW
sudo ufw enable

# Disable UFW
sudo ufw disable

# Check status
sudo ufw status verbose

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8000/tcp

# Allow specific port range
sudo ufw allow 6000:6007/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Allow from subnet
sudo ufw allow from 192.168.1.0/24

# Allow specific IP to specific port
sudo ufw allow from 192.168.1.100 to any port 22

# Deny traffic
sudo ufw deny from 203.0.113.0

# Delete rule
sudo ufw delete allow 8000/tcp
sudo ufw delete allow from 192.168.1.100

# Rate limiting
sudo ufw limit ssh

# Enable logging
sudo ufw logging on

# Reset UFW
sudo ufw reset
```

### firewalld (CentOS/RHEL)

```bash
# Start/enable firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Check status
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# List zones
sudo firewall-cmd --get-zones
sudo firewall-cmd --get-active-zones

# Add service
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent

# Add port
sudo firewall-cmd --add-port=8000/tcp --permanent

# Add port range
sudo firewall-cmd --add-port=6000-6007/tcp --permanent

# Add source IP
sudo firewall-cmd --add-source=192.168.1.0/24 --permanent

# Remove service
sudo firewall-cmd --remove-service=http --permanent

# Reload firewall
sudo firewall-cmd --reload

# Create custom service
sudo firewall-cmd --permanent --new-service=myapp
sudo firewall-cmd --permanent --service=myapp --set-description="My Application"
sudo firewall-cmd --permanent --service=myapp --add-port=8000/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --add-service=myapp --permanent
```

### Cloud Firewall (AWS Security Groups)

```hcl
# security-groups.tf
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # SSH from specific IP
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/32"]
  }

  # HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL from web servers only
  ingress {
    description     = "PostgreSQL from web servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "db-sg"
  }
}
```

---

## Part 7: VPN (Virtual Private Network)

### OpenVPN Server Setup

```bash
# Install OpenVPN
sudo apt update
sudo apt install openvpn easy-rsa

# Setup CA and certificates
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Configure vars
nano vars
# Set KEY_COUNTRY, KEY_PROVINCE, KEY_CITY, KEY_ORG, KEY_EMAIL

# Build CA
source vars
./clean-all
./build-ca

# Build server certificate
./build-key-server server

# Generate Diffie-Hellman parameters
./build-dh

# Generate HMAC signature
openvpn --genkey --secret keys/ta.key

# Build client certificates
./build-key client1

# Copy files to OpenVPN directory
cd ~/openvpn-ca/keys
sudo cp ca.crt server.crt server.key ta.key dh2048.pem /etc/openvpn/

# Configure OpenVPN server
sudo nano /etc/openvpn/server.conf
```

```bash
# /etc/openvpn/server.conf
port 1194
proto udp
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh2048.pem

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

keepalive 10 120
tls-auth ta.key 0
cipher AES-256-CBC
auth SHA256
compress lz4-v2
push "compress lz4-v2"

user nobody
group nogroup
persist-key
persist-tun

status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
```

```bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo nano /etc/sysctl.conf
# Uncomment: net.ipv4.ip_forward=1

# Configure firewall
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Start OpenVPN
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
```

### WireGuard VPN (Modern Alternative)

```bash
# Install WireGuard
sudo apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Server configuration
sudo nano /etc/wireguard/wg0.conf
```

```ini
# /etc/wireguard/wg0.conf (Server)
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32
```

```ini
# Client configuration
[Interface]
Address = 10.0.0.2/24
PrivateKey = <client-private-key>
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = server-ip:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

```bash
# Start WireGuard
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0

# Check status
sudo wg show
```

---

## Part 8: Troubleshooting Guide

### SSL/TLS Issues

```bash
# Certificate not trusted
# Solution: Check certificate chain
openssl s_client -connect example.com:443 -showcerts

# Certificate expired
# Solution: Renew certificate
sudo certbot renew --force-renewal

# Mixed content warnings
# Solution: Ensure all resources loaded over HTTPS

# SSL handshake failure
# Solution: Check cipher compatibility
openssl s_client -connect example.com:443 -tls1_2
```

### DNS Issues

```bash
# DNS not resolving
dig example.com

# Check DNS propagation
dig example.com @8.8.8.8
dig example.com @1.1.1.1

# Clear DNS cache (local)
sudo systemd-resolve --flush-caches
sudo resolvectl flush-caches

# Test with different DNS
nslookup example.com 8.8.8.8
```

### Network Connectivity

```bash
# No internet connection
ping 8.8.8.8              # Test gateway
traceroute 8.8.8.8        # Trace route
curl -I http://google.com # Test HTTP

# Port not accessible
telnet example.com 80
nc -zv example.com 80
nmap -p 80 example.com

# High latency
ping -c 10 example.com
mtr example.com           # Continuous traceroute
```

## Best Practices

### Security
1. Always use HTTPS in production
2. Keep certificates up to date
3. Use strong ciphers (TLS 1.2+)
4. Implement rate limiting
5. Enable HSTS headers
6. Regular security audits
7. Monitor certificate expiration
8. Use VPN for remote access

### Performance
1. Enable HTTP/2
2. Use CDN for static assets
3. Implement caching headers
4. Compress responses (gzip/brotli)
5. Optimize SSL session cache
6. Use keepalive connections
7. Load balance across regions
8. Monitor latency and throughput

### Reliability
1. Implement health checks
2. Use multiple backend servers
3. Configure failover
4. Monitor server status
5. Set appropriate timeouts
6. Log all errors
7. Implement circuit breakers
8. Regular backup of configurations

## Success Indicators

- [ ] Configured secure HTTPS with valid certificates
- [ ] Implemented load balancing across multiple servers
- [ ] Configured firewalls and security groups
- [ ] Set up VPN for secure remote access
- [ ] Configured DNS with proper records
- [ ] Optimized SSL/TLS configuration
- [ ] Implemented rate limiting
- [ ] Configured reverse proxy
- [ ] Monitored network performance
- [ ] Documented network architecture
