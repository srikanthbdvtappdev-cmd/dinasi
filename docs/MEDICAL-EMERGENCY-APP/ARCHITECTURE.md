# Medical Emergency App - System Architecture

## 1. High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Citizen App       Ambulance App      Hospital Dashboard       │
│  (Flutter)         (Flutter)          (React/Vue Web)          │
│  ┌─────────────┐   ┌─────────────┐   ┌──────────────────┐    │
│  │ SOS Button  │   │ Assignment  │   │ ETA Tracking     │    │
│  │ GPS Track   │   │ Navigation  │   │ Capacity View    │    │
│  │ Live Update │   │ Status Mgmt  │   │ Patient Triage   │    │
│  └─────────────┘   └─────────────┘   └──────────────────┘    │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP/WebSocket
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              API GATEWAY LAYER                                  │
│         (Azure API Management)                                  │
│  • Request Routing  • Rate Limiting  • Auth Validation         │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Firebase     │  │ SignalR Hub  │  │ Microservices
│ Authentication
│ • Phone OTP  │  │ • Real-time  │  │ Layer
│ • JWT        │  │   Location   │  │
│ • RBAC       │  │ • Broadcasts │  │
└──────────────┘  └──────────────┘  └──────────────┘
                                           │
                ┌──────────────────────────┼──────────────────────────┐
                │                          │                          │
                ▼                          ▼                          ▼
        ┌────────────────┐       ┌────────────────┐      ┌────────────────┐
        │ Incident       │       │ Dispatch       │      │ Hospital       │
        │ Service        │       │ Service        │      │ Service        │
        └────────────────┘       └────────────────┘      └────────────────┘
                │                          │                          │
                ▼                          ▼                          ▼
        ┌────────────────┐       ┌────────────────┐      ┌────────────────┐
        │ Ambulance      │       │ Notification   │      │ Admin Service  │
        │ Service        │       │ Service        │      │                │
        └────────────────┘       └────────────────┘      └────────────────┘
                │                          │                          │
                └──────────────────────────┼──────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              DATA PERSISTENCE LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PostgreSQL (with PostGIS)    │    Redis Cache                │
│  • Incidents                  │    • Ambulance Locations      │
│  • Ambulances                 │    • Session Tokens           │
│  • Hospitals                  │    • Rate Limit Counters      │
│  • Dispatch Records           │                               │
│  • Users & Contacts           │                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              EXTERNAL INTEGRATIONS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Google Maps API         │  Firebase Cloud Messaging          │
│  • Directions            │  • Push Notifications              │
│  • Distance Matrix       │  • Background Delivery             │
│  • Geocoding             │                                    │
│                          │  Analytics Service                │
│                          │  • KPI Dashboards                 │
│                          │  • Performance Reports             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Microservices Breakdown

### Incident Service
```
Responsibilities:
- SOS incident creation
- Incident status lifecycle
- Emergency type classification
- Location persistence
- Incident history

Database: incidents, incident_status_history tables
```

### Dispatch Service
```
Responsibilities:
- Smart ambulance matching
- Distance + traffic calculation
- Vehicle type matching
- Load balancing
- Dispatch scoring

Algorithm:
Score = (Distance × 0.4) + (Traffic × 0.3) + (Load × 0.2) + (Vehicle Match × 0.1)
Select: LOWEST score = BEST response
```

### Hospital Service
```
Responsibilities:
- Hospital registry
- Capacity tracking
- Hospital recommendation
- Facility monitoring
- Hospital-ambulance assignments
```

### Ambulance Service
```
Responsibilities:
- Fleet management
- Real-time location tracking
- Availability status
- Patient load tracking
- Maintenance logging

Location Update Frequency: Every 10 seconds
Redis TTL: 30 seconds
```

### Notification Service
```
Responsibilities:
- Firebase Cloud Messaging (FCM)
- Push notification templates
- Delivery tracking
- Retry logic (exponential backoff)
- SMS fallback (Twilio)

Notification Types:
- SOS Created (CRITICAL)
- Ambulance Assigned (HIGH)
- Hospital Alert (HIGH)
- Citizen Updates (MEDIUM)
```

### Admin Service
```
Responsibilities:
- User management (CRUD)
- Hospital registry management
- Ambulance fleet registry
- Role-based access control
- Audit logging
- System configuration
```

---

## 3. Complete SOS to Handoff Flow

```
┌─────────────────────────────────────┐
│ CITIZEN PRESSES SOS                 │
└────────────────┬────────────────────┘
                 │ Capture GPS + Type
                 ▼
    ┌──────────────────────────────┐
    │ POST /api/v1/incidents       │
    │ {latitude, longitude, type}  │
    └────────────┬─────────────────┘
                 │
                 ▼
    ┌──────────────────────────┐
    │ Incident Service:        │
    │ 1. Create record         │
    │ 2. Save to PostgreSQL    │
    │ 3. Emit Event            │
    └────────┬─────────────────┘
             │
    ┌────────┴─────────────────┬──────────────┐
    ▼                          ▼              ▼
┌──────────┐         ┌──────────────┐  ┌──────────┐
│ Dispatch │         │Notification  │  │ SignalR  │
│ Service  │         │ Service      │  │  Hub     │
└────┬─────┘         └──────┬───────┘  └──────────┘
     │                      │
     ▼                      ▼
Query Ambulances     FCM Alert to
(10km radius)        Ambulance Crews
     │
     ▼
Calculate Scores
(Distance, Traffic,
 Load, Vehicle Type)
     │
     ▼
Select Best Ambulance
(Lowest Score)
     │
     ▼
Create Dispatch Record
Status: ASSIGNED
     │
     ▼
Ambulance Crew Receives
30-second timer
     │
    ┌┴─────────────┐
    │              │
[ACCEPT]       [REJECT]
    │              │
    ▼              ▼
Status:         Try Next
ACCEPTED        Ambulance
    │
    ▼
Location Streaming
Every 10 seconds
to Redis → SignalR
    │
    ▼
Broadcast to:
• Citizen App (map)
• Hospital Dashboard
    │
    ▼
Ambulance En Route
Status updates
    │
    ▼
Arrival at Patient
    │
    ▼
Hospital Selection
(Phase 3 feature)
    │
    ▼
En Route to Hospital
    │
    ▼
Hospital Handoff
    │
    ▼
Citizen Rating
(After 2 hours)
```

---

## 4. Database Schema

```sql
-- USERS TABLE
CREATE TABLE users (
    id UUID PRIMARY KEY,
    phone_number VARCHAR(15) UNIQUE,
    user_type ENUM('CITIZEN', 'AMBULANCE_STAFF', 'HOSPITAL_ADMIN'),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP
);

-- INCIDENTS TABLE
CREATE TABLE incidents (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOMETRY(POINT, 4326),
    emergency_type ENUM('ACCIDENT', 'HEART_ATTACK', 'STROKE', 'PREGNANCY', 'OTHER'),
    status ENUM('CREATED', 'DISPATCHED', 'EN_ROUTE', 'AT_LOCATION', 'COMPLETED'),
    created_at TIMESTAMP,
    INDEX idx_location (location) USING GIST,
    INDEX idx_status (status)
);

-- AMBULANCES TABLE
CREATE TABLE ambulances (
    id UUID PRIMARY KEY,
    ambulance_number VARCHAR(50) UNIQUE,
    hospital_id UUID REFERENCES hospitals(id),
    vehicle_type ENUM('ALS', 'BLS'),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOMETRY(POINT, 4326),
    is_available BOOLEAN DEFAULT true,
    current_patient_count INT DEFAULT 0,
    max_capacity INT DEFAULT 3,
    last_location_update TIMESTAMP,
    INDEX idx_location (location) USING GIST,
    INDEX idx_available (is_available)
);

-- AMBULANCE LOCATIONS (Time Series)
CREATE TABLE ambulance_locations (
    id BIGSERIAL PRIMARY KEY,
    ambulance_id UUID REFERENCES ambulances(id),
    location GEOMETRY(POINT, 4326),
    timestamp TIMESTAMP,
    INDEX idx_timestamp (ambulance_id, timestamp) USING BRIN
);

-- HOSPITALS TABLE
CREATE TABLE hospitals (
    id UUID PRIMARY KEY,
    hospital_name VARCHAR(255),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOMETRY(POINT, 4326),
    icu_beds_available INT,
    emergency_bays_available INT,
    ventilators_available INT,
    INDEX idx_location (location) USING GIST
);

-- DISPATCH RECORDS TABLE
CREATE TABLE dispatch_records (
    id UUID PRIMARY KEY,
    incident_id UUID REFERENCES incidents(id),
    ambulance_id UUID REFERENCES ambulances(id),
    hospital_id UUID REFERENCES hospitals(id),
    dispatch_score DECIMAL(6,3),
    status ENUM('ASSIGNED', 'ACCEPTED', 'REJECTED', 'EN_ROUTE', 'COMPLETED'),
    response_time_seconds INT,
    created_at TIMESTAMP,
    INDEX idx_incident (incident_id),
    INDEX idx_status (status)
);

-- HOSPITAL CAPACITY HISTORY (Time Series)
CREATE TABLE hospital_capacity_history (
    id BIGSERIAL PRIMARY KEY,
    hospital_id UUID REFERENCES hospitals(id),
    icu_beds_available INT,
    emergency_bays_available INT,
    timestamp TIMESTAMP,
    INDEX idx_timestamp (hospital_id, timestamp) USING BRIN
);
```

---

## 5. API Endpoints

```
Authentication:
POST   /api/v1/auth/send-otp
POST   /api/v1/auth/verify-otp
POST   /api/v1/auth/refresh-token
POST   /api/v1/auth/logout

Incidents:
POST   /api/v1/incidents
GET    /api/v1/incidents/{id}
PUT    /api/v1/incidents/{id}/status
GET    /api/v1/incidents/{id}/tracking

Dispatch:
POST   /api/v1/dispatch/assign
GET    /api/v1/dispatch/{id}
PUT    /api/v1/dispatch/{id}/status

Ambulances:
GET    /api/v1/ambulances
POST   /api/v1/ambulances/{id}/location
PUT    /api/v1/ambulances/{id}/availability

Hospitals:
GET    /api/v1/hospitals
GET    /api/v1/hospitals/nearby
GET    /api/v1/hospitals/{id}/capacity
PUT    /api/v1/hospitals/{id}/capacity

Real-Time:
WS     /api/v1/realtime/tracking
WS     /api/v1/realtime/alerts
```

---

## 6. Technology Stack Justification

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile | Flutter | Single codebase, native performance, 60 FPS |
| Backend | ASP.NET Core 9 | Your 15+ years expertise, enterprise-grade |
| Database | PostgreSQL + PostGIS | Best geospatial support, PostGIS for <100ms queries |
| Real-Time | SignalR | Bi-directional streaming, <100ms latency |
| Auth | Firebase | Phone OTP (India optimized), push notifications |
| Maps | Google Maps API | Best coverage in India |
| Cloud | Azure | Enterprise SLAs, HIPAA compliance |
| Orchestration | Kubernetes (AKS) | Production-ready, scalable |

---

## 7. Deployment Architecture

```
Azure Subscription (medical-emergency-prod)
├── AKS Cluster (3 Node Pools)
│   ├── System: Kubernetes internals
│   ├── Apps: Microservices pods
│   └── Data: Database nodes
├── Azure Database PostgreSQL (Business Critical)
├── Azure Cache Redis (Premium, 5GB)
├── Application Gateway + WAF
├── Azure Storage (Blob, Queue, Table)
├── Azure Key Vault (Secrets management)
├── Application Insights (Monitoring)
└── Azure DevOps (CI/CD pipelines)
```

---

## 8. Security Architecture

```
Network Security:
├── VPC with private subnets
├── Network Security Groups (NSGs)
├── WAF with OWASP rules
├── DDoS Protection Standard
└── Private endpoints for databases

Authentication & Authorization:
├── Firebase Phone OTP
├── JWT Tokens (15-min access, 7-day refresh)
├── Role-Based Access Control (RBAC)
└── Multi-factor authentication (MFA)

Data Security:
├── Encryption at Rest (PostgreSQL TDE)
├── Encryption in Transit (TLS 1.2+)
├── Key Vault for secrets
└── Access logging

Application Security:
├── SQL Injection prevention (ORM)
├── XSS protection
├── Rate limiting per endpoint
├── Request validation
└── Audit logging
```

---

## 9. Performance Targets

```
Response Time:
├── Average SOS to dispatch: <2 seconds
├── API response time: <200ms (target <150ms)
├── Location update latency: <5 seconds
├── Page load: <1 second

Reliability:
├── System uptime: >99%
├── Dispatch success rate: >99%
├── Data consistency: 99.99%

Scalability:
├── Concurrent users: 10,000+
├── Locations per second: 1,000+ TPS
├── Database queries: <100ms at 95th percentile
```

---

**This architecture is designed for:**
- ✅ MVP launch in 6 months
- ✅ 5-10 pilot hospitals
- ✅ 20-50 ambulances
- ✅ Response time <8 minutes
- ✅ 99%+ uptime
- ✅ HIPAA compliance
- ✅ Easy scaling to 1000+ ambulances post-pilot
