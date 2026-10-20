# Clinical Decision Support System (CDSS) for Preventive Noncommunicable Disease Risk Assessment

## Title and Purpose of the Study

### Title
**Empowering Preventive Care: Using Predictive Analytics to Translate Family History into Actionable Health Insights**

### Purpose of the Study
The primary purpose of this study is to develop and evaluate a locally hosted Clinical Decision Support System (CDSS) that integrates electronic health record management, automated laboratory report extraction, and predictive analytics for preventive chronic noncommunicable disease (NCD) risk assessment. 

The system screens four major chronic conditions simultaneously—Cardiovascular Diseases (CVD / Essential Hypertension), Type 2 Diabetes Mellitus (T2D), Chronic Respiratory Diseases (CRD / Asthma / COPD), and selected Mental Health and Neurological Conditions (NEURO). By combining routine clinical biometrics, verified laboratory findings, and structured family pedigree health history into calibrated machine learning models (XGBoost) with local explainability (SHAP), the platform provides transparent risk stratifications and actionable preventive care plans. Operating under a pure-Python zero-admin architecture, the system enforces strict data privacy, role-based access control, and clinic operational continuity without requiring a traditional non-clinical IT administrator.

---

## System Architecture

The platform employs a modular multi-tier architecture containerized via Docker Compose, separating interactive client presentation, synchronous API business logic, asynchronous document parsing, and persistent storage:

```
                                      [ Patient Portal ]       [ Doctor Workspace ]
                                               │                        │
                                               └───────────┬────────────┘
                                                           ▼
                                                [ Reflex Web UI + shadcn/ui ]
                                                           │
                                                           │ (WebSockets & HTTPS)
                                                           ▼
                                                [ FastAPI Application Layer ]
                                                           │
                   ┌───────────────────────────────────────┼──────────────────────────────────────┐
                   ▼                                       ▼                                      ▼
        [ Relational Persistence ]               [ Asynchronous Workers ]              [ Machine Learning Engine ]
       PostgreSQL (`med_db` schema)            Redis Task Queue (RQ / Celery)          4x XGBoost Risk Classifiers
      - Patient & Pedigree Records            - Background Chandra OCR Pipeline        - CVD / Essential Hypertension
      - Longitudinal Biometrics               - Tabular Lab Extraction                 - Type 2 Diabetes Mellitus
      - Risk Scores & SHAP Audit Logs         - Status Sync via WebSockets             - Chronic Respiratory Disease
      - Local Docker Volume (Images/PDFs)                                              - Neuro / Mental Health
                                                                                       - SHAP TreeExplainer (XAI)
```

1. **Presentation Tier (Reflex + shadcn/ui):** Delivers distinct reactive workspaces for doctors and patients, handling dynamic forms, live clinic queue tickets, and real-time state synchronization over WebSockets without full-page reloads.
2. **Application & Routing Tier (FastAPI):** Orchestrates API endpoints, enforces role-based authorization via JWT, handles request idempotency caching, and validates all input payloads.
3. **Machine Learning & Intelligence Tier (XGBoost + SHAP):** Executes four disease-specific classification models in memory and generates localized SHAP feature attribution bars to explain key clinical drivers behind each assessment.
4. **Asynchronous Worker Tier (Redis + Chandra OCR):** Decouples heavy laboratory document parsing from the web server, extracting text and tables in the background while updating document statuses.
5. **Persistent Storage Tier (PostgreSQL & Local File Volume):** Maintains ACID-compliant relational tables in `med_db` while offloading raw document files and PDFs to an isolated local Docker storage volume.

---

## Tech Stack

| Layer / Domain | Tool / Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | **Reflex** | Pure-Python full-stack web framework compiling to React; manages WebSocket state synchronization. |
| **UI Component System** | **shadcn/ui (Radix UI + Tailwind CSS)** | Accessible, high-contrast component library for clinical tables, modal dialogs, and risk dashboards. |
| **Backend REST API** | **FastAPI** | Asynchronous Python REST API handling routing, middleware, and core business logic. |
| **Data Validation** | **Pydantic (v2)** | Schema validation, type enforcement, and biometric range constraint checks. |
| **ORM & Database Client** | **SQLAlchemy (v2)** | Database abstraction and connection management using parameterized SQL queries to block SQL injection. |
| **Relational Database** | **PostgreSQL (16+)** | Persistent relational storage (`med_db`) for clinical records, pedigree data, risk logs, and audit trails. |
| **File Storage** | **FastAPI-Managed Local Volume** | Isolated local Docker directory mount for uploaded scans and PDFs (up to 10 MB) referenced via file paths. |
| **Task Broker & Queue** | **Redis + RQ / Celery** | In-memory message broker managing asynchronous OCR parsing and 24-hour request idempotency caching. |
| **Document OCR** | **Chandra OCR** | Deep-learning optical character recognition model for parsing text and tabular lab panels from scanned documents. |
| **Risk Prediction Engine** | **XGBoost** | Gradient-boosted decision tree classifiers for CVD, T2D, CRD, and NEURO risk assessment. |
| **Explainable AI (XAI)** | **SHAP (TreeExplainer)** | Local feature attribution explaining individual risk scores to clinicians. |
| **Model Validation & Metrics** | **scikit-learn** | K-Fold cross-validation, baseline comparisons, calibration curves, and performance metrics (AUROC, AUPRC). |
| **Statistical Analysis** | **SciPy & StatsModels** | Hypothesis testing, DeLong tests for AUROC comparisons, and bootstrap confidence intervals. |
| **Package & Env Manager** | **uv** | Fast Python virtual environment resolver and package manager (`Python 3.11`). |
| **Containerization** | **Docker & Docker Compose** | Multi-container microservice isolation with strict CPU and memory resource limits. |
| **Ingress & Networking** | **Cloudflare Tunnel & Nginx** | Encrypted remote access, edge security, and reverse proxy routing without public port-forwarding. |

---

## Project Folder Structure

```text
thesis-draft-2/
├── .gitignore                      # Excludes .venv, cache files, local uploads, and secrets
├── README.md                       # Core project documentation
├── docker-compose.yml              # Multi-container service topology definition
├── pyproject.toml / requirements.txt # Pinned Python dependencies
│
├── BACKEND/
│   ├── app/
│   │   ├── main.py                 # FastAPI application initialization & middleware
│   │   ├── config.py               # System settings, secrets, and volume mount paths
│   │   ├── api/
│   │   │   ├── routes/             # API routes (auth, patients, vitals, risk, ocr, queue)
│   │   │   └── dependencies.py     # Database session providers & authentication context
│   │   ├── models/                 # SQLAlchemy ORM declarative models (clinical schema)
│   │   ├── schemas/                # Pydantic request and response validation schemas
│   │   └── services/               # Core business services & storage adapters
│   └── storage/
│       └── uploads/                # Local Docker volume mount for scanned medical records
│
├── FRONTEND/
│   ├── rxconfig.py                 # Reflex application configuration
│   └── app/
│       ├── app.py                  # Root application entrypoint & routing setup
│       ├── state/                  # Reflex reactive state models (auth, queue, risk, vitals)
│       ├── components/             # shadcn/ui-styled UI widgets (cards, forms, tables)
│       └── pages/
│           ├── index.py            # Authentication gateway
│           ├── doctor/             # Doctor Workspace (queue, OCR verification, risk dashboard)
│           └── patient/            # Patient Portal (dashboard, vitals log, document gallery)
│
├── DATABASE/
│   └── sql_scripts/                # Modular SQL table scripts + database initialization
│       ├── 00_init_database.sql    # Creates med_db database
│       ├── 01_users.sql            # User credentials, roles, lockout tracking
│       ├── ...                     # Clinical metrics, pedigree, and ML result tables
│       └── 20_queue_tickets.sql    # Real-time clinic queue management table
│
└── ML/
    ├── model_registry.py           # Preloaded XGBoost models & SHAP TreeExplainer instances
    ├── feature_builder.py          # Feature assembly (vitals + lab values + pedigree bands)
    ├── ocr_worker.py               # Asynchronous Chandra OCR background worker job
    └── artifacts/                  # Serialized champion model weights (4x .json)
```
