# FlashPoint CDN ⚡️

**FlashPoint** is a distributed Content Delivery Network (CDN) engineered to optimize latency and security for international traffic. Built from scratch using **Varnish Cache** (Edge) and **Nginx** (Origin). This is only the start of the project, more feature coming soon!

## 🏗 Architecture
*   **Origin:** Nginx Web Server (New York, US 🇺🇸)
*   **Edge:** Varnish Cache Node (London, UK 🇬🇧)

## 🛠 Features Implemented
*   **Geo-Distributed Caching:** Serves content from RAM at the edge, eliminating the trans-Atlantic round trip.
*   **Edge Logic (VCL):** Custom Varnish Configuration Language scripts filter traffic at the ingress (`vcl_recv`) to save backend bandwidth.
*   **Access Control Lists (ACLs):** IP-based security blocking unauthorized access to sensitive routes (`/admin`).
*   **Synthetic Responses:** Instant 404 and 403 error handling generated directly at the edge.

## 📸 Proof of Concept

### 1. Cache Performance
*Demonstrating `HIT` status served from Varnish RAM:*
![Cache Hit](cache-hit.png)

### 2. Edge Security (ACLs)
*Blocking unauthorized traffic to `/admin` with a synthetic 403 response:*
![Security Block](security-block.png)

## 💻 Tech Stack
*   **Core:** Varnish Cache 7.1
*   **Language:** VCL (Varnish Configuration Language)
*   **Infrastructure:** DigitalOcean Droplets (Ubuntu 24.04)
*   **Networking:** TCP/IP, HTTP/1.1
