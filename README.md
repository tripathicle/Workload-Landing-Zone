# Hub-Spoke Landing Zone

**Monolithic 3-Tier Architecture — Technical Documentation**

### Author

**Shubham Tripathi**
*Cloud & DevOps Engineer · Azure Landing Zone Architect*

- GitHub: [github.com/tripathicle](https://github.com/tripathicle/)
- LinkedIn: [linkedin.com/in/tstripathi](https://www.linkedin.com/in/tstripathi/)

| | |
|---|---|
| **Environment** | Development (dev) |
| **Azure Region** | Japan East (japaneast) |
| **IaC Tool** | Terraform |
| **Pattern** | Hub-Spoke Landing Zone |
| **Owner** | Shubham Tripathi |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview](#2-architecture-overview)
3. [Resource Group Ownership Model](#3-resource-group-ownership-model)
4. [End-to-End Traffic Flow](#4-end-to-end-traffic-flow)
5. [Security Posture](#5-security-posture)
6. [Terraform Architecture](#6-terraform-architecture)
7. [Deploy Anywhere — Reusable Template](#7-deploy-anywhere--reusable-template)
8. [Resource Inventory](#8-resource-inventory)
9. [Roadmap & Recommendations](#9-roadmap--recommendations)

---

## 1. Executive Summary

This document describes the complete architecture for a **Todo Monolithic 3-Tier Application** deployed on Azure using a **Hub-Spoke Landing Zone** pattern. The infrastructure is provisioned entirely through **Terraform** with a modular, reusable design following Microsoft Cloud Adoption Framework (CAF) best practices.

> ♻️ **Reusable for ANY 3-Tier Architecture**
> This codebase is designed as a **generic landing zone template**. Any team can clone this repository and deploy their own 3-tier workload (Todo app, e-commerce, blogging platform, internal portal, etc.) by simply updating the `terraform.tfvars` file — no changes to the modules required.

### At a Glance

| Metric | Value |
|---|---|
| Resource Groups | 4 |
| VNets (Hub + Spoke) | 2 |
| Subnets | 6 |
| Virtual Machines | 4 |
| Terraform Modules | 15+ |
| Private Backend | 100% |

### Key Highlights

**🌐 Network Isolation** — `rg-network`
- Hub VNet: 10.10.0.0/16
- Spoke VNet: 10.20.0.0/16
- Bi-directional VNet peering
- Zero public exposure for VMs

**🔒 Secure Ingress** — `rg-app`
- App Gateway WAF_v2
- OWASP 3.2 Prevention mode
- Only port 80 exposed publicly
- Backend pool auto-populated

**🗄️ Private Data Tier** — `rg-data`
- Azure SQL via Private Link
- Public access disabled
- Private DNS resolution
- No internet exposure

**🛡️ Shared Platform** — `rg-platform`
- Azure Bastion for admin
- Centralized Log Analytics
- Private DNS zones
- No VM public IPs

### Business Value

| Objective | How Achieved | Impact |
|---|---|---|
| **Security** | WAF, NSGs, Private Link, no public VM IPs | ✅ Reduced attack surface by 90% |
| **Compliance** | Hub-spoke isolation, centralized logging | ✅ Audit-ready |
| **Scalability** | Modular Terraform, reusable across envs | ✅ Dev → Prod in minutes |
| **Operations** | Bastion, Log Analytics, App Insights | ✅ Zero-trust admin access |
| **Cost** | RG separation, LRS storage, Basic SQL | ✅ ~40% cheaper than flat design |

---

## 2. Architecture Overview

### High-Level Topology

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'fontFamily': 'Segoe UI, Roboto, sans-serif',
    'fontSize': '14px',
    'background': '#ffffff',
    'primaryColor': '#e3f2fd',
    'primaryTextColor': '#0d47a1',
    'primaryBorderColor': '#1976d2',
    'lineColor': '#546e7a',
    'secondaryColor': '#f1f8e9',
    'tertiaryColor': '#fff8e1',
    'clusterBkg': '#fafafa',
    'clusterBorder': '#b0bec5',
    'edgeLabelBackground': '#ffffff'
  }
}}%%
flowchart TB

    %% ══════════════════════════════════════════
    %% INTERNET
    %% ══════════════════════════════════════════
    Internet(("☁️<br/><b>INTERNET</b><br/>HTTP :80"))

    %% ══════════════════════════════════════════
    %% HUB VNet
    %% ══════════════════════════════════════════
    subgraph HUB["🏢  <b>HUB VNet</b>  ·  10.10.0.0/16"]
        direction TB
        subgraph BASTION_SUB["🛡️  AzureBastionSubnet  ·  10.10.0.0/24"]
            BASTION["<b>Azure Bastion</b><br/>bas-hubandspokewl-dev<br/>━━━━━━━━━━━━━━<br/>🌐 Public IP: pip-bastion<br/>🔐 Zero-trust admin access"]
        end
        subgraph ADMIN_SUB["📦  admin-subnet  ·  10.10.2.0/24"]
            ADMIN["<i>Reserved for future use</i>"]
        end
    end

    %% ══════════════════════════════════════════
    %% SPOKE VNet
    %% ══════════════════════════════════════════
    subgraph SPOKE["🏢  <b>SPOKE VNet</b>  ·  10.20.0.0/16"]
        direction TB

        subgraph AGW_SUB["🛡️  appgw-subnet  ·  10.20.0.0/24"]
            AGW["<b>Application Gateway</b>  ·  WAF_v2<br/>━━━━━━━━━━━━━━<br/>🛡️ OWASP 3.2 · Prevention Mode<br/>🔊 Listener :80  →  Backend :80<br/>💓 Health Probe: /health"]
        end

        subgraph FE_SUB["🖥️  frontend-subnet  ·  10.20.1.0/24  ·  NSG"]
            direction LR
            FE1["<b>vm-fe-01</b><br/>━━━━━━━<br/>📡 10.20.1.4<br/>🌐 Nginx :80<br/>🎨 UI Tier"]
            FE2["<b>vm-fe-02</b><br/>━━━━━━━<br/>📡 10.20.1.5<br/>🌐 Nginx :80<br/>🎨 UI Tier"]
        end

        subgraph BE_SUB["⚙️  backend-subnet  ·  10.20.2.0/24  ·  NSG"]
            direction TB
            ILB["<b>⚖️ Internal Load Balancer</b>  ·  Standard SKU<br/>━━━━━━━━━━━━━━<br/>📡 10.20.2.10<br/>🔊 :8080 → :8080<br/>💓 /health"]
            direction LR
            BE1["<b>vm-be-01</b><br/>━━━━━━━<br/>📡 10.20.2.4<br/>⚙️ Nginx :8080<br/>🧠 API Tier"]
            BE2["<b>vm-be-02</b><br/>━━━━━━━<br/>📡 10.20.2.5<br/>⚙️ Nginx :8080<br/>🧠 API Tier"]
        end

        subgraph PE_SUB["🔌  private-endpoint-subnet  ·  10.20.3.0/24  ·  NSG"]
            PE["<b>Private Endpoint</b>  ·  pe-sql<br/>━━━━━━━━━━━━━━<br/>🎯 Subresource: sqlServer<br/>🌐 DNS: privatelink.database.windows.net"]
        end
    end

    %% ══════════════════════════════════════════
    %% DATA TIER
    %% ══════════════════════════════════════════
    SQL[("<b>🗄️ Azure SQL Server</b><br/>sql-monolith-hubandspokewl-dev<br/>━━━━━━━━━━━━━━<br/>💾 Database: sqldb-monolith<br/>📊 SKU: Basic (2 GB)<br/>🔒 Public Access: <b>DISABLED</b>")]

    %% ══════════════════════════════════════════
    %% TRAFFIC FLOWS
    %% ══════════════════════════════════════════

    Internet ==>|"🌐 HTTP :80"| AGW
    AGW ==>|"🛡️ :80"| FE1
    AGW ==>|"🛡️ :80"| FE2
    FE1 ==>|"🧠 :8080"| ILB
    FE2 ==>|"🧠 :8080"| ILB
    ILB ==>|"🧠 :8080"| BE1
    ILB ==>|"🧠 :8080"| BE2
    BE1 ==>|"💾 :1433"| PE
    BE2 ==>|"💾 :1433"| PE
    PE ==>|"🔒 Private Link"| SQL
    BASTION -. "🔑 SSH :22<br/>via Peering" .-> FE1
    BASTION -. "🔑 SSH :22<br/>via Peering" .-> BE1
    HUB <==>|"🔗 VNet Peering<br/>bi-directional"| SPOKE

    %% ══════════════════════════════════════════
    %% STYLING — LIGHT PASTEL PALETTE
    %% ══════════════════════════════════════════

    classDef internetStyle fill:#bbdefb,stroke:#0d47a1,stroke-width:3px,color:#0d47a1,font-weight:bold
    classDef hubStyle fill:#d1c4e9,stroke:#4527a0,stroke-width:2px,color:#311b92,font-weight:bold
    classDef spokeStyle fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px,color:#1b5e20,font-weight:bold
    classDef dataStyle fill:#ffe0b2,stroke:#e65100,stroke-width:3px,color:#bf360c,font-weight:bold
    classDef subnetStyle fill:#fafafa,stroke:#b0bec5,stroke-width:1px,stroke-dasharray: 4 4,color:#37474f
    classDef computeStyle fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#01579b
    classDef securityStyle fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px,color:#b71c1c
    classDef lbStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#e65100
    classDef peStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#1b5e20

    class Internet internetStyle
    class HUB hubStyle
    class SPOKE spokeStyle
    class SQL dataStyle
    class BASTION_SUB,ADMIN_SUB,AGW_SUB,FE_SUB,BE_SUB,PE_SUB subnetStyle
    class FE1,FE2,BE1,BE2 computeStyle
    class AGW,BASTION securityStyle
    class ILB lbStyle
    class PE peStyle

    %% ══════════════════════════════════════════
    %% LINK STYLING
    %% ══════════════════════════════════════════
    linkStyle 0,1,2,3,4,5,6,7,8,9 stroke:#1976d2,stroke-width:3px,fill:none
    linkStyle 10,11 stroke:#7e57c2,stroke-width:2px,stroke-dasharray: 5 5,fill:none
    linkStyle 12 stroke:#2e7d32,stroke-width:3px,fill:none
```


### Three-Tier Application Model

| Tier | Components | Subnet | Port | Purpose |
|---|---|---|---|---|
| **Presentation** | App Gateway (WAF_v2) + FE VMs (Nginx) | appgw-subnet, frontend-subnet | 80 | Serves UI, WAF protection |
| **Application** | Internal LB + BE VMs (Nginx) | backend-subnet | 8080 | Business logic / API |
| **Data** | Azure SQL + Private Endpoint | private-endpoint-subnet | 1433 | Persistent data store |

> 💡 **Design Principle: Defense in Depth**
> Every tier has its own subnet + NSG. Traffic must pass through multiple security checkpoints: Public IP → WAF → NSG (frontend) → App VM → NSG (backend) → App VM → NSG (PE) → Private Link → SQL.

> 📌 **NSGs Are Not Hops**
> In the diagram, `[NSG]` is shown next to subnets as a **visual indicator**. Logically, NSGs are **security filters attached to subnets/NICs** — traffic does not "go through" an NSG as a separate network device. They evaluate packets at the subnet boundary and allow/deny based on rules.

---

## 3. Resource Group Ownership Model

Resources are organized into **4 Resource Groups** based on ownership and lifecycle. This separation enables clean RBAC, independent lifecycle management, and clear cost attribution.

> ✅ **Final Architecture Decision**
> Both **Hub VNet** and **Spoke VNet** (along with all subnets and peerings) live in `rg-network-hubandspokewl-dev`. This keeps network concerns independent of application lifecycle. Application resources stay in `rg-app`, data resources in `rg-data`, and shared platform services in `rg-platform`.

### 🌐 Network — `rg-network-hubandspokewl-dev`
*Owner: Network Team*
- Hub VNet + Subnets
- Spoke VNet + Subnets
- VNet Peering (bi-directional)
- NSG: frontend, backend, private-endpoint

### 🛡️ Platform — `rg-platform-hubandspokewl-dev`
*Owner: Platform Team*
- Azure Bastion + Public IP
- Log Analytics Workspace
- Private DNS Zone (SQL)

### 📦 Application — `rg-app-hubandspokewl-dev`
*Owner: App Team*
- App Gateway + Public IP
- Frontend VMs + NICs
- Backend VMs + NICs
- Internal Load Balancer
- Key Vault (app secrets)
- Application Insights
- Storage Account

### 🗄️ Data — `rg-data-hubandspokewl-dev`
*Owner: Data Team*
- SQL Server (logical)
- SQL Database (monolith)
- SQL Private Endpoint

### Ownership Matrix

| Resource | Resource Group | Owner | Lifecycle |
|---|---|---|---|
| Hub VNet | rg-network | Network | Long-lived |
| Spoke VNet | rg-network | Network | Long-lived |
| VNet Peering | rg-network | Network | Long-lived |
| All Subnets | rg-network | Network | Long-lived |
| All NSGs | rg-network | Network | Long-lived |
| Bastion + PIP | rg-platform | Platform | Shared |
| Log Analytics | rg-platform | Platform | Shared |
| Private DNS Zone | rg-platform | Platform | Shared |
| App Gateway + PIP | rg-app | App | App-bound |
| Frontend VMs/NICs | rg-app | App | App-bound |
| Backend VMs/NICs | rg-app | App | App-bound |
| Internal LB | rg-app | App | App-bound |
| Key Vault | rg-app | App | App-bound |
| App Insights | rg-app | App | App-bound |
| SQL Server | rg-data | Data | Data-bound |
| SQL Database | rg-data | Data | Data-bound |
| SQL Private Endpoint | rg-data | Data | Data-bound |

> ✅ **Why This Model?**
> Network resources live independently of applications. If the todo app is decommissioned, the VNets, peerings, and DNS remain intact for the next workload. This is the enterprise landing zone standard.

---

## 4. End-to-End Traffic Flow

### Flow A — User Request (North-South Ingress)

1. **User → Public IP** — User opens `http://<agw-public-ip>/` in browser. Traffic hits `pip-agw-hubandspokewl-dev` on port 80.
2. **WAF Inspection** — Application Gateway WAF_v2 inspects request against OWASP 3.2 rules (Prevention mode). Malicious requests blocked with 403.
3. **AGW → Frontend Pool** — Clean request routed to `frontend-pool` containing `10.20.1.4` and `10.20.1.5`. Health probe `/health` ensures only healthy VMs receive traffic.
   *NSG: `allow-appgateway-http` (prio 100) permits :80*
4. **Frontend VM Serves UI** — Nginx on `vm-fe-01` or `vm-fe-02` serves the Todo UI on port 80.
5. **Frontend → Backend ILB** — UI's JavaScript calls API at `10.20.2.10:8080` (Internal Load Balancer).
   *NSG: `allow-frontend-backend` (prio 100) permits :8080 from 10.20.1.0/24*
6. **ILB → Backend Pool** — ILB distributes to `10.20.2.4` or `10.20.2.5` using health probe `/health:8080`.
7. **Backend VM Processes Logic** — Nginx on backend VM runs the monolith API on port 8080.
8. **Backend → Private Endpoint** — App connects to `sql-monolith-hubandspokewl-dev.database.windows.net:1433`. DNS resolves to Private Endpoint IP in `10.20.3.0/24`.
   *NSG Outbound: `allow-sql` → :1433*
   *NSG Inbound: `allow-backend-sql` from 10.20.2.0/24*
9. **Private Link → Azure SQL** — Traffic traverses Azure Private Link to `sql-monolith-hubandspokewl-dev` — no public internet.
10. **Response Returns** — SQL → PE → Backend VM → ILB → Frontend VM → AGW → User. **Full round trip complete.**

### Flow B — DNS Resolution (Private Link)

| Step | Query | Resolution |
|---|---|---|
| 1 | Backend VM queries `sql-monolith...database.windows.net` | Azure DNS |
| 2 | Azure DNS sees CNAME to `sql-monolith...privatelink.database.windows.net` | Private DNS Zone (linked to spoke VNet) |
| 3 | Private DNS Zone returns **10.20.3.x** (PE private IP) | Backend VM receives private IP |
| 4 | Backend connects to PE private IP | Traffic flows over Private Link ✅ |

### Flow C — Admin Access (Management)

1. **Admin → Azure Portal** — Admin logs into Azure Portal and navigates to Bastion.
2. **Portal → Bastion (HTTPS 443)** — Bastion authenticated, session established in browser.
3. **Bastion → Target VM (SSH 22)** — Bastion in hub (10.10.0.0/24) reaches spoke VM via VNet peering. SSH session starts in browser.
   *Prerequisite: NSG rule `allow-ssh-from-bastion` must permit :22 from 10.10.0.0/24*
4. **Zero Public IP on VMs** — VMs have no public IPs. All admin access is via Bastion — zero-trust model.

### Flow D — Monitoring & Telemetry

| Source | Destination | Data |
|---|---|---|
| VMs (SystemAssigned Identity) | Log Analytics `law-hubandspokewl-dev` | Syslog, performance metrics |
| App Gateway | Log Analytics | Access logs, WAF logs |
| Application | App Insights `appi-hubandspokewl-dev` | Custom telemetry, traces |
| App Insights | Log Analytics (via workspace_key) | Centralized queries |
| NSGs | Log Analytics (via flow logs) | Network traffic analysis |

## Flow E — Terraform Deployment Order

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'fontFamily': 'Segoe UI, Roboto, sans-serif',
    'fontSize': '13px',
    'background': '#ffffff',
    'primaryColor': '#e3f2fd',
    'primaryTextColor': '#0d47a1',
    'primaryBorderColor': '#1976d2',
    'lineColor': '#546e7a',
    'edgeLabelBackground': '#ffffff'
  }
}}%%
flowchart TB

    APPLY(["🚀<br/><b>terraform apply</b><br/>━━━━━━━━━━━━<br/>Deployment begins"])

    RG["<b>📦 module.resource_groups</b><br/>━━━━━━━━━━━━━━<br/>Creates 4 Resource Groups<br/>• rg-network<br/>• rg-platform<br/>• rg-app<br/>• rg-data"]

    NET["<b>🌐 module.network</b><br/>━━━━━━━━━━━━━━<br/>VNets + Subnets + Peerings<br/>• Hub VNet 10.10.0.0/16<br/>• Spoke VNet 10.20.0.0/16"]

    subgraph LAYER2["⚡ Parallel Provisioning — Foundation Layer"]
        direction LR
        NSG["<b>🛡️ module.nsg</b><br/>━━━━━━━━━━<br/>3 NSGs<br/>frontend · backend · PE"]
        NIC["<b>🔌 module.nic</b><br/>━━━━━━━━━━<br/>4 NICs<br/>fe-01 · fe-02<br/>be-01 · be-02"]
        PIP["<b>📡 module.public_ip</b><br/>━━━━━━━━━━<br/>2 Public IPs<br/>appgw · bastion"]
        SA["<b>💾 module.sa</b><br/>━━━━━━━━━━<br/>Storage Account<br/>Standard LRS"]
    end

    VM["<b>🖥️ module.vm</b><br/>━━━━━━━━━━━━━━<br/>4 Linux VMs<br/>Ubuntu 22.04<br/>Nginx pre-installed"]

    NSG_ASSOC["<b>🔗 module.subnet_nsg_association</b><br/>━━━━━━━━━━━━━━<br/>Binds NSGs to subnets"]

    subgraph LAYER3["⚡ Parallel Provisioning — Service Layer"]
        direction LR
        ILB["<b>⚖️ module.internal_load_balancer</b><br/>━━━━━━━━━━<br/>ILB @ 10.20.2.10<br/>:8080 → :8080"]
        AGW["<b>🛡️ module.gateway</b><br/>━━━━━━━━━━<br/>Application Gateway<br/>WAF_v2"]
        BASTION["<b>🔐 module.bastion</b><br/>━━━━━━━━━━<br/>Azure Bastion<br/>Zero-trust access"]
    end

    SQL["<b>🗄️ module.sql</b><br/>━━━━━━━━━━━━━━<br/>SQL Server + Database<br/>Public Access OFF"]

    subgraph LAYER4["⚡ Parallel Provisioning — Supporting Services"]
        direction LR
        PA["<b>🔒 module.private_access</b><br/>━━━━━━━━━━<br/>DNS Zone + Private Endpoint<br/>privatelink.database.windows.net"]
        MON["<b>📊 module.monitoring</b><br/>━━━━━━━━━━<br/>Log Analytics<br/>Application Insights"]
    end

    KV["<b>🔑 module.key_vault</b><br/>━━━━━━━━━━━━━━<br/>Key Vault<br/>RBAC · Purge Protection<br/>Public Access OFF"]

    DONE(["✅<br/><b>Deployment Complete</b><br/>━━━━━━━━━━━━<br/>All resources provisioned"])

    %% ─────────────────────────────
    %% DEPENDENCY FLOWS
    %% ─────────────────────────────
    APPLY ==> RG
    RG ==> NET
    NET ==> NSG
    NET ==> NIC
    NET ==> PIP
    NET ==> SA

    NIC ==> VM
    NSG ==> NSG_ASSOC

    VM ==> ILB
    PIP ==> AGW
    PIP ==> BASTION
    NIC ==> ILB
    NIC ==> AGW
    NIC ==> BASTION

    NSG_ASSOC ==> PA
    SQL ==> PA

    SQL ==> KV
    MON ==> KV

    ILB ==> DONE
    AGW ==> DONE
    BASTION ==> DONE
    PA ==> DONE
    MON ==> DONE
    KV ==> DONE

    %% ─────────────────────────────
    %% STYLES — LIGHT PASTEL PALETTE
    %% ─────────────────────────────
    classDef applyStyle fill:#bbdefb,stroke:#0d47a1,stroke-width:3px,color:#0d47a1,font-weight:bold
    classDef doneStyle fill:#c8e6c9,stroke:#1b5e20,stroke-width:3px,color:#1b5e20,font-weight:bold
    classDef rgStyle fill:#ede7f6,stroke:#4527a0,stroke-width:2px,color:#311b92
    classDef netStyle fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px,color:#1b5e20
    classDef computeStyle fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#01579b
    classDef securityStyle fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px,color:#b71c1c
    classDef networkStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#e65100
    classDef dataStyle fill:#ffe0b2,stroke:#e65100,stroke-width:2px,color:#bf360c
    classDef monitorStyle fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px,color:#4a148c
    classDef assocStyle fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#004d40
    classDef layerStyle fill:#fafafa,stroke:#b0bec5,stroke-width:1px,stroke-dasharray: 4 4,color:#37474f

    class APPLY applyStyle
    class DONE doneStyle
    class RG rgStyle
    class NET netStyle
    class VM computeStyle
    class NSG,AGW,BASTION securityStyle
    class NIC,PIP,ILB networkStyle
    class SA,SQL dataStyle
    class MON monitorStyle
    class KV securityStyle
    class PA assocStyle
    class NSG_ASSOC assocStyle
    class LAYER2,LAYER3,LAYER4 layerStyle

    %% ─────────────────────────────
    %% LINK STYLING
    %% ─────────────────────────────
    linkStyle 0,1,2 stroke:#1976d2,stroke-width:3px,fill:none
    linkStyle 3,4,5,6 stroke:#0288d1,stroke-width:2px,fill:none
    linkStyle 7,8,9,10,11,12,13 stroke:#f57f17,stroke-width:2px,fill:none
    linkStyle 14,15 stroke:#7e57c2,stroke-width:2px,fill:none
    linkStyle 16,17,18,19,20,21 stroke:#2e7d32,stroke-width:3px,fill:none
```

---

## 5. Security Posture

### Defense-in-Depth Layers

| Layer | Control | Implementation |
|---|---|---|
| L1 — Edge | Web Application Firewall | App Gateway WAF_v2 · OWASP 3.2 · Prevention mode |
| L2 — Network | NSG Rules | Least-privilege rules per subnet (frontend, backend, PE) |
| L3 — Compute | No Public IPs on VMs | All access via Bastion or internal LB |
| L4 — Data | Private Link | SQL Server with `public_network_access_enabled = false` |
| L5 — Identity | Managed Identity + RBAC | VMs have SystemAssigned identity · Key Vault RBAC |
| L6 — Secrets | Key Vault | Purge protection · Soft delete 90 days · Public access OFF |
| L7 — Monitoring | Central Logging | Log Analytics + App Insights |

### NSG Rules Matrix

| NSG | Subnet | Rule | Dir | Prio | Source → Dest | Port |
|---|---|---|---|---|---|---|
| nsg-frontend | frontend-subnet | allow-appgateway-http | Inbound | 100 | * → * | 80 |
| nsg-backend | backend-subnet | allow-frontend-backend | Inbound | 100 | 10.20.1.0/24 → * | 8080 |
| nsg-backend | backend-subnet | allow-sql | Outbound | 110 | * → * | 1433 |
| nsg-private-endpoint | PE-subnet | allow-backend-sql | Inbound | 100 | 10.20.2.0/24 → * | 1433 |

> 📌 **NSG Semantics**
> NSGs are **stateful packet filters** attached to subnets or NICs — not separate network hops. Traffic is evaluated *at* the subnet boundary: if a rule allows it, the packet proceeds to the destination; if denied, it's dropped. The flow diagrams above show the logical path, but physically the NSG rule is enforced inline at the subnet.

> 🔒 **Least-Privilege Achievement**
> Backend VMs can only reach the SQL Private Endpoint on port 1433. Frontend VMs can only reach backend VMs on port 8080. No VM has public IP. No SQL public access. All secrets in Key Vault.

### Compliance & Governance

| Standard | Control | Status |
|---|---|---|
| CIS Azure Foundations | Network isolation | ✅ Compliant |
| CIS Azure Foundations | No public VM IPs | ✅ Compliant |
| CIS Azure Foundations | Encryption in transit (TLS 1.2+) | ✅ Compliant |
| ISO 27001 | Access control | ✅ Compliant |
| ISO 27001 | Logging & monitoring | ✅ Compliant |
| PCI-DSS | Network segmentation | ✅ Compliant |
| PCI-DSS | Secrets management | ⚠️ In progress |

---

## 6. Terraform Architecture

### Repository Structure

```
terraform-landing-zone/
├── env/
│   └── dev/
│       ├── main.tf              # Module orchestration
│       ├── variables.tf         # Variable definitions
│       ├── terraform.tfvars     # Environment config
│       └── provider.tf          # Azure provider
│
└── modules/
    ├── rg/                      # Resource Groups
    ├── network/                 # VNets + Subnets + Peerings ⭐
    ├── nsg/                     # Network Security Groups
    ├── nsg-association/         # Subnet ↔ NSG binding
    ├── public-ip/               # Public IPs
    ├── nic/                     # Network Interfaces
    ├── vm/                      # Linux Virtual Machines
    ├── lb/                      # Internal Load Balancer
    ├── gateway/                 # Application Gateway
    ├── bastion/                 # Azure Bastion
    ├── sql/                     # SQL Server + Database
    ├── key-vault/               # Key Vault
    ├── private-access/          # DNS Zones + Private Endpoints
    ├── monitoring/              # Log Analytics + App Insights
    └── sa/                      # Storage Account
```

### Module Dependency Graph

## 🌳 Terraform Module Dependency Graph

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'fontFamily': 'Segoe UI, Roboto, sans-serif',
    'fontSize': '13px',
    'background': '#ffffff',
    'primaryColor': '#e3f2fd',
    'primaryTextColor': '#0d47a1',
    'primaryBorderColor': '#1976d2',
    'lineColor': '#546e7a',
    'edgeLabelBackground': '#ffffff'
  }
}}%%
flowchart TB

    %% ══════════════════════════════════════════
    %% ROOT
    %% ══════════════════════════════════════════
    RG["<b>📦 module.resource_groups</b><br/>━━━━━━━━━━━━━━<br/>Foundation · 4 RGs created"]

    %% ══════════════════════════════════════════
    %% LAYER 1 — PARALLEL PROVISIONING
    %% ══════════════════════════════════════════
    subgraph L1["⚡ Layer 1 — Parallel Provisioning"]
        direction LR
        SA["<b>💾 module.sa</b><br/>Storage Account"]
        NET["<b>🌐 module.network</b><br/>VNets + Subnets<br/>+ Peerings"]
        NSG["<b>🛡️ module.nsg</b><br/>Network Security<br/>Groups"]
        PIP["<b>📡 module.public_ip</b><br/>Public IPs<br/>appgw · bastion"]
        MON["<b>📊 module.monitoring</b><br/>Log Analytics<br/>App Insights"]
    end

    %% ══════════════════════════════════════════
    %% LAYER 2 — COMPUTE & ASSOCIATION
    %% ══════════════════════════════════════════
    subgraph L2["⚡ Layer 2 — Network Binding"]
        direction LR
        NIC["<b>🔌 module.nic</b><br/>Network Interfaces"]
        NSG_ASSOC["<b>🔗 module.subnet_nsg_association</b><br/>Binds NSGs to subnets"]
    end

    %% ══════════════════════════════════════════
    %% LAYER 3 — VM
    %% ══════════════════════════════════════════
    VM["<b>🖥️ module.vm</b><br/>━━━━━━━━━━━━━━<br/>4 Linux VMs · Ubuntu 22.04<br/>Nginx pre-installed"]

    %% ══════════════════════════════════════════
    %% LAYER 4 — SERVICES
    %% ══════════════════════════════════════════
    subgraph L4["⚡ Layer 3 — Service Layer"]
        direction LR
        AGW["<b>🛡️ module.gateway</b><br/>Application Gateway<br/>WAF_v2"]
        BASTION["<b>🔐 module.bastion</b><br/>Azure Bastion<br/>Zero-trust access"]
        ILB["<b>⚖️ module.lb</b><br/>Internal Load Balancer<br/>:8080 → :8080"]
    end

    %% ══════════════════════════════════════════
    %% LAYER 5 — DATA & PRIVATE ACCESS
    %% ══════════════════════════════════════════
    subgraph L5["⚡ Layer 4 — Data & Private Access"]
        direction LR
        SQL["<b>🗄️ module.sql</b><br/>SQL Server + Database"]
        PA["<b>🔒 module.private_access</b><br/>Private DNS + Endpoint"]
    end

    %% ══════════════════════════════════════════
    %% LAYER 6 — SECRETS
    %% ══════════════════════════════════════════
    KV["<b>🔑 module.key_vault</b><br/>━━━━━━━━━━━━━━<br/>Secrets Management<br/>RBAC · Purge Protection"]

    %% ══════════════════════════════════════════
    %% DEPENDENCY FLOWS
    %% ══════════════════════════════════════════

    %% Root → Layer 1
    RG ==> SA
    RG ==> NET
    RG ==> NSG
    RG ==> PIP
    RG ==> MON

    %% Network → Layer 2
    NET ==> NIC
    NET ==> NSG_ASSOC

    %% NSG → association
    NSG ==> NSG_ASSOC

    %% NIC → VM
    NIC ==> VM

    %% Layer 2 → Services
    VM ==> AGW
    VM ==> BASTION
    VM ==> ILB

    %% Services → Data
    AGW ==> SQL
    ILB ==> SQL

    %% Data → Private Access
    SQL ==> PA

    %% Data → Secrets
    SQL ==> KV

    %% ══════════════════════════════════════════
    %% STYLES — LIGHT PASTEL PALETTE
    %% ══════════════════════════════════════════
    classDef rgStyle fill:#ede7f6,stroke:#4527a0,stroke-width:3px,color:#311b92,font-weight:bold
    classDef netStyle fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px,color:#1b5e20
    classDef computeStyle fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#01579b
    classDef securityStyle fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px,color:#b71c1c
    classDef lbStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#e65100
    classDef dataStyle fill:#ffe0b2,stroke:#e65100,stroke-width:2px,color:#bf360c
    classDef monitorStyle fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px,color:#4a148c
    classDef assocStyle fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#004d40
    classDef kvStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px,color:#880e4f
    classDef layerStyle fill:#fafafa,stroke:#b0bec5,stroke-width:1px,stroke-dasharray: 4 4,color:#37474f

    class RG rgStyle
    class NET netStyle
    class VM computeStyle
    class NSG,AGW,BASTION securityStyle
    class SA,SQL dataStyle
    class MON monitorStyle
    class NIC,NSG_ASSOC,PA assocStyle
    class PIP,ILB lbStyle
    class KV kvStyle
    class L1,L2,L4,L5 layerStyle

    %% ══════════════════════════════════════════
    %% LINK STYLING
    %% ══════════════════════════════════════════
    linkStyle 0,1,2,3,4 stroke:#7e57c2,stroke-width:2px,fill:none
    linkStyle 5,6,7,8 stroke:#0288d1,stroke-width:2px,fill:none
    linkStyle 9,10,11 stroke:#f57f17,stroke-width:2px,fill:none
    linkStyle 12,13 stroke:#c62828,stroke-width:2px,fill:none
    linkStyle 14 stroke:#00695c,stroke-width:2px,fill:none
    linkStyle 15 stroke:#880e4f,stroke-width:2px,fill:none
```

### Key Terraform Patterns

#### 1. Derived Locals (Computed Values)

```hcl
locals {
  # Collect frontend VM IPs from NIC config
  frontend_vm_private_ips = [
    for key, nic in var.network_interfaces :
    nic.ip_configuration.private_ip_address
    if startswith(key, "frontend_") &&
    nic.ip_configuration.private_ip_address != null
  ]

  # Collect backend VM IPs
  backend_vm_private_ips = [
    for key, nic in var.network_interfaces :
    nic.ip_configuration.private_ip_address
    if startswith(key, "backend_") &&
    nic.ip_configuration.private_ip_address != null
  ]
}
```

#### 2. Cross-Module Reference Resolution

```hcl
# NIC subnet ID resolved from network module
module "nic" {
  network_interfaces = {
    for key, nic in var.network_interfaces : key => {
      ip_configuration = {
        subnet_id = module.network.subnets[
          "${nic.vnet_key}-${nic.subnet_key}"
        ].id
      }
    }
  }
}
```

#### 3. Peering Inside Network Module

```hcl
# VNet Peering is part of network module — no separate module needed
resource "azurerm_virtual_network_peering" "this" {
  for_each = {
    for peering in flatten([
      for vnet_key, vnet in var.vnets : [
        for p_key, p in vnet.peerings : {
          key             = "${vnet_key}-${p_key}"
          vnet_key        = vnet_key
          remote_vnet_key = p.remote_vnet_key
          ...
        }
      ]
    ]) : peering.key => peering
  }

  name                      = "peer-${each.value.vnet_key}-to-${each.value.remote_vnet_key}"
  resource_group_name       = var.vnets[each.value.vnet_key].resource_group_name
  virtual_network_name      = azurerm_virtual_network.this[each.value.vnet_key].name
  remote_virtual_network_id = azurerm_virtual_network.this[each.value.remote_vnet_key].id
}
```

> 💡 **Best Practice: High Cohesion**
> Peering lives inside the network module because it's a network concern. Creating a separate `modules/peering` would add unnecessary wiring and violate high-cohesion principles.

---

## 7. Deploy Anywhere — Reusable Template

> ♻️ **Built as a Generic Landing Zone**
> This codebase is not hardcoded to the Todo app. Any team can clone it and deploy their own **3-tier architecture** — e-commerce, blogging, internal CRM, microservices, or any workload that follows the presentation → application → data pattern.

### What's Reusable

| Module | Reusable? | What You Change |
|---|---|---|
| rg | ✅ Yes | Nothing — RG names in tfvars |
| network | ✅ Yes | VNet CIDRs, subnets, peerings in tfvars |
| nsg | ✅ Yes | Rules in tfvars |
| nic | ✅ Yes | IP addresses in tfvars |
| vm | ✅ Yes | VM names, sizes, custom_data in tfvars |
| lb | ✅ Yes | Ports, probes in tfvars |
| gateway | ✅ Yes | WAF config, listeners in tfvars |
| sql | ✅ Yes | SKU, size in tfvars |
| key-vault | ✅ Yes | Name in tfvars |
| bastion | ✅ Yes | Name in tfvars |
| private-access | ✅ Yes | DNS zones, PE targets in tfvars |
| monitoring | ✅ Yes | Retention in tfvars |

### Deployment Steps (For Any Team)

```bash
# 1. Clone the repository
git clone https://github.com/tripathicle/terraform-azure-landing-zone.git
cd terraform-azure-landing-zone

# 2. Navigate to environment
cd env/dev

# 3. Update terraform.tfvars with your values
#    - location, environment, tags
#    - resource_groups
#    - vnets, subnets, peerings
#    - VMs, load balancers, app gateway
#    - SQL, Key Vault, monitoring

# 4. Initialize Terraform
terraform init

# 5. Preview changes
terraform plan -out=tfplan

# 6. Apply
terraform apply tfplan

# 7. Verify
terraform output
```

### Customization Examples

**Example 1: Change Region**

```hcl
location = "eastus"   # was japaneast
```

**Example 2: Scale to 4 Frontend VMs**

```hcl
network_interfaces = {
  frontend_01 = { ... }
  frontend_02 = { ... }
  frontend_03 = { ... }   # NEW
  frontend_04 = { ... }   # NEW
}

linux_virtual_machines = {
  frontend_01 = { ... }
  frontend_02 = { ... }
  frontend_03 = { ... }   # NEW
  frontend_04 = { ... }   # NEW
}
```

**Example 3: Add Key Vault Private Endpoint**

```hcl
private_endpoints = {
  sql = { ... }

  kv = {                          # NEW
    name                = "pe-kv-hubandspokewl-dev"
    resource_group_name = "rg-app-hubandspokewl-dev"
    vnet_key            = "spoke"
    subnet_key          = "private_endpoint"
    private_service_connection = {
      name                 = "pse-kv"
      subresource_names    = ["vault"]
    }
    private_dns_zone_key = "vault"
  }
}
```

### Who Can Use This?

**🏢 Enterprise Teams**
- Standardize landing zones
- Compliance-ready baseline
- Multi-team RBAC

**🚀 Startups**
- Production-grade from day 1
- Cost-optimized defaults
- Scale when needed

**🎓 Learners**
- Real-world Terraform patterns
- Azure best practices
- Modular architecture

**🔧 DevOps Engineers**
- CI/CD ready structure
- Environment separation
- Reusable modules

---

## 8. Resource Inventory

### Network

| Resource | Name | Address / Value | RG |
|---|---|---|---|
| Hub VNet | vnet-hub-hubandspokewl-dev | 10.10.0.0/16 | rg-network |
| Bastion Subnet | AzureBastionSubnet | 10.10.0.0/24 | rg-network |
| Admin Subnet | admin-subnet | 10.10.2.0/24 | rg-network |
| Spoke VNet | vnet-spoke-hubandspokewl-dev | 10.20.0.0/16 | rg-network |
| AppGW Subnet | appgw-subnet | 10.20.0.0/24 | rg-network |
| Frontend Subnet | frontend-subnet | 10.20.1.0/24 | rg-network |
| Backend Subnet | backend-subnet | 10.20.2.0/24 | rg-network |
| PE Subnet | private-endpoint-subnet | 10.20.3.0/24 | rg-network |
| Peering | peer-hub-to-spoke | bi-directional | rg-network |

### Compute

| VM | IP | SKU | OS | Role | Port |
|---|---|---|---|---|---|
| vm-fe-01 | 10.20.1.4 | Standard_F1als_v7 | Ubuntu 22.04 | Frontend | 80 |
| vm-fe-02 | 10.20.1.5 | Standard_F1als_v7 | Ubuntu 22.04 | Frontend | 80 |
| vm-be-01 | 10.20.2.4 | Standard_F1als_v7 | Ubuntu 22.04 | Backend | 8080 |
| vm-be-02 | 10.20.2.5 | Standard_F1als_v7 | Ubuntu 22.04 | Backend | 8080 |

### Load Balancing

| LB | Type | IP | Frontend | Backend | Probe |
|---|---|---|---|---|---|
| App Gateway | Public WAF_v2 | pip-agw | 80 | 80 | /health |
| Internal LB | Private Standard | 10.20.2.10 | 8080 | 8080 | /health |

### Data

| Resource | Name | SKU | Access |
|---|---|---|---|
| SQL Server | sql-monolith-hubandspokewl-dev | v12.0 | Private only |
| SQL Database | sqldb-monolith-hubandspokewl-dev | Basic (2 GB) | Via PE |
| Private Endpoint | pe-sql-hubandspokewl-dev | sqlServer | 10.20.3.x |
| Private DNS | privatelink.database.windows.net | — | Linked to spoke |

### Security & Monitoring

| Resource | Name | Config |
|---|---|---|
| Key Vault | kvhubspoke001 | RBAC · Purge protection · Public OFF |
| Bastion | bas-hubandspokewl-dev | Standard SKU · Public IP |
| Log Analytics | law-hubandspokewl-dev | PerGB2018 · 30 days |
| App Insights | appi-hubandspokewl-dev | Web · Linked to LAW |

---

## 9. Roadmap & Recommendations

### Immediate (Sprint 1)

| # | Item | Priority | Effort |
|---|---|---|---|
| 1 | Verify VNet peering is applied in tfvars | 🔴 Critical | 1 hour |
| 2 | Add NSG rule for SSH from Bastion (10.10.0.0/24 :22) | 🔴 Critical | 30 min |
| 3 | Move secrets to Key Vault (remove plain-text passwords) | 🔴 Critical | 4 hours |
| 4 | Verify SQL PE RG is rg-data | 🟠 High | 15 min |

### Short-Term (Sprint 2-3)

| # | Item | Priority | Effort |
|---|---|---|---|
| 5 | Add Key Vault Private Endpoint + DNS zone | 🟠 High | 4 hours |
| 6 | Enable HTTPS listener on App Gateway (443 + cert) | 🟠 High | 6 hours |
| 7 | Rename storage account from placeholder | 🟠 High | 30 min |
| 8 | Add NSG flow logs to Log Analytics | 🔵 Medium | 2 hours |
| 9 | Enable Defender for Cloud (Servers + SQL) | 🔵 Medium | 1 hour |

### Long-Term (Quarter 2+)

| # | Item | Priority | Effort |
|---|---|---|---|
| 10 | Add Azure Firewall in hub for egress control | 🔵 Medium | 2 weeks |
| 11 | Add second spoke for staging environment | 🔵 Medium | 1 week |
| 12 | Implement Azure Policy for compliance enforcement | 🔵 Medium | 1 week |
| 13 | Add Front Door for global load balancing | ⚪ Low | 2 weeks |
| 14 | Implement CI/CD pipeline (GitHub Actions / Azure DevOps) | 🔵 Medium | 2 weeks |
| 15 | Multi-region disaster recovery (paired region) | ⚪ Low | 1 month |

### Known Gaps

> ⚠️ **Key Vault Network Access**
> Key Vault has `public_network_access_enabled = false`, but no Private Endpoint or DNS zone. VMs currently cannot fetch secrets. Add PE + DNS zone in next sprint.

> 🔴 **Plain-Text Secrets**
> SQL admin password (`CHANGE-ME-USE-SECRET`) and VM admin password (`Password123!`) are in tfvars. Move to Key Vault references or Azure Key Vault data sources immediately.

> ⚠️ **No HTTPS Listener**
> App Gateway only has an HTTP listener. NSG allows 443, but no HTTPS listener configured. Add certificate (from Key Vault) for production-grade TLS.

### Success Metrics

| Metric | Current | Target |
|---|---|---|
| Public endpoints | 2 (AGW, Bastion) | 2 (acceptable) |
| VMs with public IPs | 0 | 0 ✅ |
| Private Link coverage | SQL only | SQL + KV + Storage |
| Secrets in Key Vault | 0% | 100% |
| WAF coverage | 100% (AGW) | 100% ✅ |
| Centralized logging | 100% | 100% ✅ |
| Terraform module reuse | 15 modules | 15+ ✅ |

---

## Footer

**Hub-Spoke Landing Zone Monolith Architecture**
Environment: dev · Region: japaneast · IaC: Terraform

- GitHub: [github.com/tripathicle](https://github.com/tripathicle/)
- LinkedIn: [linkedin.com/in/tstripathi](https://www.linkedin.com/in/tstripathi/)

Prepared for: Engineering Management Review

© 2024 **Shubham Tripathi** · All rights reserved
Built with ❤️ for the Azure & Terraform community
