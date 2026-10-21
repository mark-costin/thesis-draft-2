# Self-Hosted Personal Health Risk Screening System for Preventive Noncommunicable Disease Assessment

## Title and Purpose of the Study

### Title
**Empowering Preventive Care: Using Predictive Analytics to Translate Family History into Actionable Health Insights**

### Purpose of the Study
The primary purpose of this study is to develop and evaluate a self-hosted, patient-only web application that combines a Personal Health Record (PHR), automated laboratory report extraction, and predictive analytics for preventive chronic noncommunicable disease (NCD) risk screening.

The system screens four chronic condition groups simultaneously:

- **CVD:** Cardiovascular Diseases / Essential Hypertension
- **T2D:** Type 2 Diabetes Mellitus
- **CRD:** Chronic Respiratory Diseases (Asthma / COPD)
- **NEURO:** Selected Mental Health and Neurological Conditions *(define the specific conditions)*

The system combines self-reported biometrics, patient-verified laboratory values, and a structured family health history. These feed calibrated XGBoost models, and SHAP provides local explanations. Each patient receives a transparent risk assessment in plain language, general preventive guidance, and an exportable health report to bring to their own healthcare provider.

The system has **no doctor or clinic role**. The patient is the sole user and the sole human-in-the-loop, and owns their data on their own self-hosted instance. All outputs are for educational preventive screening and are **not a medical diagnosis**.

---

## System Architecture

The platform uses a modular multi-tier architecture containerized with Docker Compose and deployed through Coolify. It separates the presentation layer, the API and business logic, asynchronous document parsing, machine learning inference, and persistent storage.

```
                    [ Patient — Phone or PC Browser ]
                                   │
                                   │  HTTPS via Cloudflare Tunnel
                                   ▼
                   [ Coolify Reverse Proxy (Traefik) ]
                                   │
                                   ▼
                    [ Reflex Web App (UI + State) ]
                                   │
                                   │  Internal REST (JWT + Idempotency-Key)
                                   ▼
                     [ FastAPI Application Layer ]
                                   │
     ┌─────────────────┬───────────┴───────┬─────────────────────────┐
     ▼                 ▼                   ▼                         ▼
[ PostgreSQL ]      [ Redis ]       [ ML Engine ]            [ Local Volume ]
- Patient profile   - RQ task       - 4x XGBoost models     - Encrypted lab
- Vitals              queue           (CVD, T2D, CRD,          images / PDFs
- Family history    - Idempotency     NEURO)
- Lab results         cache         - SHAP TreeExplainer
- Risk assessments  - Rate limits
  + SHAP JSONB
                       │
                       ▼
              [ OCR Worker (RQ) ]
              - Chandra OCR parsing
              - Writes extracted values
                for patient review
```

1. **Presentation Tier (Reflex + Radix UI):** A mobile-first, desktop-compatible patient portal written in pure Python and compiled to React. It handles dynamic forms, vitals charts, document upload, and the side-by-side OCR verification screen. UI state is synchronized with the browser over WebSockets without full-page reloads.
2. **Application Tier (FastAPI):** Reflex state handlers call the FastAPI service over internal REST. The service enforces:
   - JWT authentication and per-patient data isolation
   - Idempotency keys
   - Rate limiting
   - Pydantic validation
3. **Asynchronous Worker Tier (Redis + RQ + Chandra OCR):** Runs heavy document parsing outside the web server. Uploaded files are queued, parsed in the background, and their status is updated. When a job finishes, Reflex pushes the update to the patient's screen.
4. **Machine Learning Tier (XGBoost + SHAP):** Four disease-specific models stay loaded in memory and run on the patient's verified inputs. SHAP TreeExplainer produces local feature attributions, shown in plain language (e.g., "Family history of diabetes increased your risk the most").
5. **Persistent Storage Tier (PostgreSQL + Local Volume):** ACID-compliant relational tables hold structured health data. Uploaded documents are encrypted and stored on an isolated Docker volume to prevent database bloat.

---

## Functional Modules

| # | Module | Summary |
| :--- | :--- | :--- |
| 1 | **Authentication & Security** | Self-registration, consent capture, JWT sessions, per-patient data isolation, rate limiting, idempotency |
| 2 | **Personal Health Record & Vitals** | Demographics (age, biological sex) and time-series vitals (blood pressure, BMI, heart rate, blood glucose) |
| 3 | **Family Health History Intake** | Pedigree grid of relatives × target diseases, with early-onset weighting into familial risk bands |
| 4 | **Document Ingestion & Patient Verification** | Upload of lab documents (≤10 MB), background Chandra OCR, side-by-side review; values are saved only after the patient confirms them |
| 5 | **Risk Prediction & Explainability** | Four XGBoost models, SHAP explanations, risk tiers, disclaimers, and a "consult a healthcare provider" prompt for high-risk results |
| 6 | **Health Report Export** | PDF summary of vitals, family history, verified labs, and risk results for the patient's healthcare provider |
| — | **Data Rights** | Patient can export and permanently delete their account and data (RA 10173) |

---

## Tech Stack

### Tier 1: Application & Deployment

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Reflex (Radix UI components) | Pure-Python, responsive UI for mobile and PC |
| **Backend** | FastAPI | Business logic and API routing |
| | SQLAlchemy 2 (ORM) + Alembic | Parameterized queries (SQL injection prevention) and schema migrations |
| | Pydantic v2 | Input validation and biometric range checks |
| | nh3 + Reflex default escaping | XSS prevention |
| | PyJWT | Session tokens and per-patient data isolation |
| | pwdlib (Argon2id) | Password hashing |
| | CORS (Reflex `cors_allowed_origins` + FastAPI `CORSMiddleware`) | Restricts browser API access to the app's own domain |
| | SlowAPI + Redis | Rate limiting / brute-force protection |
| | FastAPI middleware + Redis (redis-py) | Idempotency keys |
| | RQ + Redis | Background OCR task queue |
| | cryptography (Fernet) | Encryption of uploaded documents at rest |
| | WeasyPrint | PDF health report export |
| **Machine Learning** | XGBoost | Four disease risk models (CVD, T2D, CRD, NEURO) |
| | SHAP (TreeExplainer) | Local feature explanations |
| | Chandra OCR | Lab document text and table extraction |
| **Database & Storage** | PostgreSQL 16+ | Patient records, vitals, family history, lab results, risk assessments |
| | Docker volume | Encrypted lab images and PDFs |
| **Deployment** | Docker Compose | Containerized self-hosting |
| | Coolify | Deployment management, reverse proxy, scheduled database backups |
| | Cloudflare Tunnel | Secure remote access without port forwarding, HTTPS, DDoS protection |
| **Tooling** | uv (Python 3.11) | Package and environment management |
| | DBeaver | Database administration |
| | Git / GitHub, pytest | Version control and testing |

### Tier 2: Offline Research & Training (Chapters 3 & 4)

| Tool | Purpose |
| :--- | :--- |
| `xgboost` | Model training; native missing-value handling; `scale_pos_weight` for class imbalance |
| `scikit-learn` | Stratified K-fold CV, logistic regression baseline, `CalibratedClassifierCV`, AUROC, AUPRC, Brier score, F1, weighted Cohen's κ |
| `optuna` | Bayesian (TPE) hyperparameter search, run inside training folds only to avoid leakage |
| `shap` | Global and local explanations; beeswarm and waterfall plots |
| `mlflow` | Experiment tracking; exports the selected model as XGBoost `.json` |
| `scipy.stats` + custom DeLong implementation | DeLong test (family-history model vs. clinical-only baseline) and bootstrap 95% CIs |
| `pingouin` | Intraclass correlation (ICC) for expert agreement *(if physicians are available)* |
| `fairlearn` | Equalized odds difference; subgroup AUROC and calibration by sex and age band |
| `pandas`, `matplotlib`, `seaborn` | Data preparation and Chapter 4 figures |
| JupyterLab / Marimo | Experiment notebooks |

### Evaluation Plan

| Phase | Metrics | Purpose |
| :--- | :--- | :--- |
| 1. Discrimination | AUROC, AUPRC, sensitivity, specificity (at chosen thresholds) | How well the model separates at-risk from not-at-risk individuals |
| 2. Calibration | Brier score, ECE, calibration plots | Whether predicted probabilities match observed outcome rates |
| 3. Statistical significance | DeLong's test, bootstrap 95% CIs | Whether family history features significantly improve AUROC over the baseline |
| 4. Expert agreement *(optional)* | Weighted Cohen's κ, ICC | Agreement between model risk tiers and physician assessments |
| 5. Fairness | Equalized odds, subgroup performance | Comparable performance across sex and age groups |
| 6. Usability | ISO/IEC 25010 survey / SUS | Patient-facing usability of the web app |

---

## Security & Data Privacy (RA 10173)

- **Per-patient isolation:** Every query is scoped to the `patient_id` in the signed JWT, so patients cannot access each other's records, even on a household instance.
- **Password hashing:** Argon2id via pwdlib.
- **Encryption:** HTTPS in transit (Cloudflare Tunnel). Uploaded documents are encrypted at rest with Fernet.
- **Request protection:**
  - Idempotency keys prevent duplicate writes on unstable mobile connections.
  - Rate limiting blocks brute-force login attempts.
  - CORS is restricted to the app's own domain.
- **Consent and data rights:** Consent is captured at registration. The patient can export or permanently delete their data.
- **Backups:** Coolify scheduled PostgreSQL backups, plus a backup of the uploads volume.
- **Third-party note:** Cloudflare Tunnel terminates TLS at Cloudflare's edge. Tailscale is a private-network alternative.

---

## Project Folder Structure

```text
thesis-draft-2/
├── .gitignore                      # Excludes .venv, caches, uploads, .env, model training data
├── .env.example                    # Template for secrets (JWT key, DB URL, Fernet key, Redis URL)
├── README.md
├── docker-compose.yml              # Services: web (Reflex), api (FastAPI), worker (RQ), postgres, redis
├── pyproject.toml / uv.lock        # Pinned Python dependencies (uv)
│
├── BACKEND/
│   ├── alembic/                    # Database migrations
│   ├── app/
│   │   ├── main.py                 # FastAPI app, CORS, rate limiting, idempotency middleware
│   │   ├── config.py               # Settings, secrets, volume paths
│   │   ├── security.py             # JWT, password hashing, file encryption
│   │   ├── api/
│   │   │   ├── routes/             # auth, profile, vitals, family_history, documents, risk, reports, account
│   │   │   └── dependencies.py     # DB sessions and current-patient context
│   │   ├── models/                 # SQLAlchemy ORM models
│   │   ├── schemas/                # Pydantic request/response schemas
│   │   ├── services/               # Business logic, storage adapter, PDF report builder
│   │   └── workers/
│   │       └── ocr_worker.py       # RQ job: Chandra OCR → unconfirmed lab results
│   └── storage/
│       └── uploads/                # Docker volume mount for encrypted documents
│
├── FRONTEND/
│   ├── rxconfig.py                 # Reflex config (incl. cors_allowed_origins)
│   └── app/
│       ├── app.py                  # Entrypoint and routing
│       ├── state/                  # Reflex state (auth, vitals, family history, documents, risk)
│       ├── components/             # Radix-based UI components (cards, forms, charts, tables)
│       └── pages/
│           ├── index.py            # Login / registration with consent
│           ├── dashboard.py        # Risk summaries and vitals trends
│           ├── vitals.py           # Vitals log and history
│           ├── family_history.py   # Pedigree intake grid
│           ├── documents.py        # Upload and side-by-side verification
│           ├── risk.py             # Four-disease risk and SHAP explanations
│           └── report.py           # PDF export and account data controls
│
└── ML/
    ├── model_registry.py           # Loads the 4 XGBoost models and SHAP explainers at startup
    ├── feature_builder.py          # Builds model inputs (vitals + verified labs + pedigree bands)
    ├── artifacts/                  # Selected model files (4x .json) + feature schema
    ├── notebooks/                  # Training, tuning, and evaluation (Jupyter / Marimo)
    └── evaluation/                 # DeLong, calibration, fairness scripts and figures
```

### Core Database Entities

| Entity | Purpose |
| :--- | :--- |
| `users` | Credentials, age, biological sex, consent timestamp |
| `vitals_records` | Time-series self-reported vitals |
| `family_histories` | Relatives × conditions with onset ages |
| `ocr_documents` | Encrypted file path and parsing status |
| `lab_results` | Extracted lab values; used only when `is_confirmed = TRUE` |
| `risk_assessments` | Probability, risk tier, model version, SHAP values (JSONB) |

---

## Disclaimer

This system is a research prototype for preventive health risk screening. It does not provide medical diagnoses and does not replace consultation with a licensed healthcare provider.
