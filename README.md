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

The system combines self-reported biometrics, lifestyle and questionnaire data, patient-verified laboratory values, and a structured family health history. These feed calibrated XGBoost models, and SHAP provides local explanations. Each patient receives a transparent risk assessment in plain language, general preventive guidance, and an exportable health report to bring to their own healthcare provider.

The system has **no doctor or clinic role**. The patient is the sole user and the sole human-in-the-loop, and owns their data on an instance the project team controls (a local machine during development, a DigitalOcean droplet for deployment). All outputs are for educational preventive screening and are **not a medical diagnosis**.

---

## System Architecture

The platform uses a modular multi-tier architecture containerized with Docker Compose and deployed on a DigitalOcean droplet behind an Nginx reverse proxy. It separates the presentation layer, the API and business logic, asynchronous document parsing, machine learning inference, and persistent storage.

```
                    [ Patient — Phone or PC Browser ]
                                   │
                                   │  HTTPS (Let's Encrypt certificate)
                                   ▼
              [ Nginx Reverse Proxy — DigitalOcean Droplet ]
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
- 17 tables         - RQ task       - 4x XGBoost models     - Encrypted lab
- Row-Level           queue           (CVD, T2D, CRD,          images / PDFs
  Security          - Idempotency     NEURO)
- Append-only         keys          - SHAP TreeExplainer
  audit log         - Rate limits
                       │
                       ▼
              [ OCR Worker (RQ) ]
              - Chandra OCR parsing
              - Writes extracted values
                for patient review
```

1. **Presentation Tier (Reflex + Radix UI):** A browser-based, responsive patient portal written in pure Python and compiled to React. It handles dynamic forms, vitals charts, questionnaires, document upload, and the side-by-side OCR verification screen. UI state is synchronized with the browser over WebSockets without full-page reloads.
2. **Application Tier (FastAPI):** Reflex state handlers call the FastAPI service over internal REST. The service enforces:
   - JWT authentication and per-patient data isolation (sets the patient identity for Row-Level Security on every request)
   - Idempotency keys
   - Rate limiting
   - Pydantic validation
3. **Asynchronous Worker Tier (Redis + RQ + Chandra OCR):** Runs heavy document parsing outside the web server. Uploaded files are queued, parsed in the background, and their status is updated. When a job finishes, Reflex pushes the update to the patient's screen.
4. **Machine Learning Tier (XGBoost + SHAP):** Four disease-specific models stay loaded in memory and run on the patient's verified inputs. Each model file is checked against its registered SHA-256 checksum before loading. SHAP TreeExplainer produces local feature attributions, shown in plain language (e.g., "Family history of diabetes increased your risk the most").
5. **Persistent Storage Tier (PostgreSQL + Local Volume):** ACID-compliant relational tables hold structured health data, with Row-Level Security on every patient table. Uploaded documents are encrypted and stored on an isolated Docker volume to prevent database bloat.

---

## Functional Modules

| # | Module | Summary |
| :--- | :--- | :--- |
| 1 | **Authentication & Security** | Self-registration with RA 10173 consent, JWT sessions, per-patient isolation (RLS), lockout, rate limiting, idempotency, self-service password reset |
| 2 | **Personal Health Record & Vitals** | Profile (date of birth, biological sex), time-series vitals (blood pressure, heart rate, weight, height, BMI, glucose, SpO2), lifestyle, and health history |
| 3 | **Family Health History Intake** | Pedigree grid of relatives × target diseases, with early-onset weighting into a Family History Risk Score (FHRS) |
| 4 | **Health Questionnaires** | PHQ-9, GAD-7, PSQI, mMRC, CAT, ACT; PHQ-9 item 9 triggers crisis resources (NCMH 1553) |
| 5 | **Document Ingestion & Patient Verification** | Upload of lab documents (≤10 MB), background Chandra OCR, unit conversion, side-by-side review; values are used only after the patient confirms them |
| 6 | **Risk Prediction & Explainability** | Four XGBoost models, SHAP explanations, risk tiers, disclaimers, and a "consult a healthcare provider" prompt for high-risk results |
| 7 | **Preventive Goals & Health Report** | Self-set or suggested goals, PDF health report, data export and permanent account deletion (RA 10173) |

---

## Tech Stack

### Tier 1: Application & Deployment

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Reflex (Radix UI components) | Pure-Python, browser-based responsive UI for mobile and PC |
| | httpx | Reflex state calls to the FastAPI backend |
| **Backend** | FastAPI | Business logic and API routing |
| | SQLAlchemy 2 (ORM) | Parameterized queries (SQL injection prevention) |
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
| **Database & Storage** | PostgreSQL 18 (15+ required) | 17 tables with Row-Level Security; schema created by numbered SQL scripts in `database/` |
| | Docker volume | Encrypted lab images and PDFs |
| **Deployment** | Docker Compose | Containerized services: web, api, worker, postgres, redis |
| | Nginx + Let's Encrypt (Certbot) | Reverse proxy, HTTPS, WebSocket upgrade for Reflex |
| | DigitalOcean droplet | Cloud VPS for the deployed system (synthetic data only) |
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
| `scipy.stats` + custom DeLong implementation (`eval_utils.py`) | DeLong test (family-history model vs. clinical-only baseline) and bootstrap 95% CIs |
| `pingouin` | Intraclass correlation (ICC) for expert agreement *(only if physicians give continuous 0–100 scores)* |
| `fairlearn` | Equalized odds difference; subgroup AUROC and calibration by sex and age band |
| `pandas`, `matplotlib`, `seaborn` | Data preparation and Chapter 4 figures |
| JupyterLab / Marimo | Experiment notebooks |

### Evaluation Plan

| Phase | Notebook (`ML/ai_model/`) | Metrics | Purpose |
| :--- | :--- | :--- | :--- |
| 1. Discrimination | `eval_01_discrimination.ipynb` | AUROC, AUPRC, sensitivity, specificity (at chosen thresholds) | How well the model separates at-risk from not-at-risk individuals |
| 2. Calibration | `eval_02_calibration.ipynb` | Brier score, ECE, calibration plots | Whether predicted probabilities match observed outcome rates |
| 3. Statistical significance | `eval_03_significance.ipynb` | DeLong's test, bootstrap 95% CIs | Whether family history features significantly improve AUROC over the baseline |
| 4. Expert agreement *(optional)* | `eval_04_expert_agreement.ipynb` | Weighted Cohen's κ, ICC | Agreement between model risk tiers and physician assessments |
| 5. Fairness | `eval_05_fairness.ipynb` | Equalized odds, subgroup performance | Comparable performance across sex and age groups |
| 6. Usability | — (survey) | ISO/IEC 25010 survey / SUS | Patient-facing usability of the web app |

**Evaluation notes**
- `eval_01` runs each model once on the fixed test set and saves `artifacts/eval_test_predictions.csv` (patient id, true label, baseline probability, full-model probability, sex, age band). Notebooks `eval_02`–`eval_05` read this file, so every metric is computed on the same patients. DeLong's test requires this.
- The baseline (clinical-only, no family-history features) model is trained and saved alongside the full model so `eval_03` can compare the two.
- `eval_04` requires a set of cases labeled by physicians. Even though the app has no doctor role, this data has to be collected separately.
- Fairness results on synthetic data partly reflect the data generator, not only the model. This is noted as a limitation in Chapter 5.

---

## Security & Data Privacy (RA 10173)

The system applies Zero Trust security principles (NIST SP 800-207).

- **Per-patient isolation:** Every request sets the `patient_id` from the signed JWT, and PostgreSQL Row-Level Security returns only that patient's rows, even on a shared instance. With no identity set, queries return nothing.
- **Least-privilege database access:** The app connects as `med_app`, which cannot bypass RLS, change the schema, read the audit log, or change the model registry. The `postgres` account is used only for setup and maintenance.
- **Password hashing:** Argon2id via pwdlib.
- **Encryption:** HTTPS in transit (Nginx with a Let's Encrypt certificate). Uploaded documents are encrypted at rest with Fernet.
- **Tamper-evident audit log:** Security events are written through `log_audit()` into a hash-chained, append-only table; `verify_audit_chain()` detects any edit.
- **Request protection:**
  - Idempotency keys prevent duplicate writes on unstable mobile connections.
  - Rate limiting blocks brute-force login attempts.
  - CORS is restricted to the app's own domain.
- **Consent and data rights:** Consent is captured at registration. The patient can export or permanently delete their data; deletion cascades to every patient table.
- **Backups:** Scheduled `pg_dump` of `med_db` plus a backup of the uploads volume.
- **Deployment data:** The DigitalOcean droplet holds synthetic data only. Real patient data on a cloud server would need additional RA 10173 safeguards.

---

## Project Folder Structure

The project uses a flat structure: each top-level folder is at most one level deep, and related files are grouped by filename prefix instead of subfolders.

```text
thesis-draft-2/
├── .gitignore                      # Excludes .venv, caches, uploads, .env, *.dump, generated datasets
├── .env.example                    # Template: DATABASE_URL (med_app), APP_DB_PASSWORD, JWT key, Fernet key, Redis URL
├── README.md
├── docker-compose.yml              # Services: web (Reflex), api (FastAPI), worker (RQ), postgres, redis
├── Dockerfile.web                  # Reflex image
├── Dockerfile.api                  # FastAPI image (includes ML/ for model loading)
├── Dockerfile.worker               # RQ + Chandra OCR image
├── pyproject.toml / uv.lock        # Pinned Python dependencies (uv)
│
├── database/                       # Numbered SQL scripts, run once on an empty database
│   ├── 00_roles.sh                 # Creates the least-privilege med_app login
│   ├── 01_functions.sql … 18_patient_goals.sql   # The 17 tables, in dependency order
│   ├── 99_security.sql             # Row-Level Security and permissions (runs last)
│   └── README.md                   # What each script does
│
├── backend/
│   ├── main.py                     # FastAPI app, CORS, rate limiting, idempotency middleware
│   ├── config.py                   # Settings, secrets, volume paths
│   ├── database.py                 # DB engine (as med_app), sessions, set_request_identity()
│   ├── security.py                 # JWT, password hashing, file encryption
│   ├── models.py                   # SQLAlchemy ORM models for the 17 tables
│   ├── schemas.py                  # Pydantic request/response schemas
│   ├── services.py                 # Business logic, FHRS calculation, unit conversion, PDF report builder
│   ├── ocr_worker.py               # RQ job: Chandra OCR → unconfirmed lab results
│   ├── routes/                     # auth, profile, vitals, lifestyle, health_history, questionnaires,
│   │                               # family_history, documents, risk, goals, reports, account
│   ├── tests/                      # pytest: API, auth, and cross-patient isolation tests
│   └── uploads/                    # Docker volume mount for encrypted documents
│
├── frontend/
│   ├── rxconfig.py                 # Reflex config (app_name="patient_app", cors_allowed_origins)
│   └── patient_app/                # Reflex app package (folder name must match app_name)
│       ├── patient_app.py          # Entrypoint and routing
│       ├── state.py                # Reflex state + API client (JWT, Idempotency-Key)
│       ├── components.py           # Radix-based UI components (cards, forms, charts, tables)
│       ├── login.py                # Screen 1: registration with consent, login, password reset
│       ├── dashboard.py            # Screen 2: risk summaries and vitals trends
│       ├── vitals.py               # Screen 3: vitals, lifestyle, and health history tabs
│       ├── family_history.py       # Screen 4: pedigree intake grid
│       ├── questionnaires.py       # Screen 5: PHQ-9, GAD-7, PSQI, mMRC, CAT, ACT + crisis dialog
│       ├── documents.py            # Screen 6: upload and side-by-side verification
│       ├── risk.py                 # Screen 7: four-disease risk and SHAP explanations
│       └── report.py               # Screen 8: goals, PDF report, data export and deletion
│
├── deploy/
│   ├── nginx.conf                  # Reverse proxy, HTTPS, WebSocket upgrade for Reflex
│   └── backup.sh                   # Scheduled pg_dump + uploads volume backup
│
└── ML/
    ├── model_registry.py           # Loads the 4 models, verifies SHA-256, builds SHAP explainers
    ├── feature_builder.py          # Builds model inputs from vitals, lifestyle, questionnaires,
    │                               # confirmed labs, and FHRS
    │
    ├── synthetic/                  # Synthetic data generator + seed script for demo patients
    ├── OCR/                        # Chandra OCR experiments and lab-value extraction tests
    │
    ├── ai_model/                   # ML notebooks: training, tuning, and evaluation
    │   ├── (training / tuning notebooks)
    │   ├── eval_utils.py           # ECE, DeLong test, bootstrap CI helpers
    │   ├── eval_01_discrimination.ipynb    # AUROC, AUPRC, threshold; writes eval_test_predictions.csv
    │   ├── eval_02_calibration.ipynb       # Brier score, ECE, reliability diagram
    │   ├── eval_03_significance.ipynb      # DeLong test, bootstrap 95% CIs vs. baseline
    │   ├── eval_04_expert_agreement.ipynb  # Weighted Cohen's κ, ICC (optional)
    │   └── eval_05_fairness.ipynb          # Equalized odds, subgroup AUROC and calibration
    │
    └── artifacts/                  # Everything produced: models, splits, figures, reports
        ├── (4x selected model .json + baseline models + feature schema)
        ├── (fixed train/test split or seed)
        └── (evaluation outputs, prefixed by notebook: eval01_*, eval02_*, ..., eval05_*)
```

**ML data flow:** `synthetic/` generates the dataset → `ai_model/` trains and evaluates → `artifacts/` stores the models and outputs → the models are registered in the `model_versions` table → `model_registry.py` loads them from `artifacts/` for the live app.

**Artifact naming:** outputs stay flat in `artifacts/` and are prefixed by the notebook that created them, for example `eval01_roc_cvd.png`, `eval02_calibration_t2d.png`, `eval03_delong.csv`, `eval05_subgroup_auroc.csv`.

### Core Database Entities

| Entity | Purpose |
| :--- | :--- |
| `users` | Login credentials, lockout, session revocation (no health data) |
| `patients` | Minimal profile (name, date of birth, biological sex) and RA 10173 consent |
| `password_reset_tokens` | Hashed, single-use, one-hour reset tokens |
| `audit_ledger` | Hash-chained, append-only security log |
| `documents` | Uploaded lab files (encrypted) and OCR status |
| `vitals_records` | Self-reported vitals; BMI computed automatically |
| `lab_results` | One lab value per row; used only when `is_confirmed = TRUE` |
| `lifestyle_records` | Smoking, activity, sleep, diet, occupational exposure |
| `patient_health_history` | Patient's own past conditions |
| `questionnaire_responses` | PHQ-9, GAD-7, PSQI, mMRC, CAT, ACT with crisis flag |
| `patient_family_history` | Relatives × conditions with onset ages |
| `patient_fhrs_stratification` | Family History Risk Score per disease |
| `model_versions` | Registered model files, checksums, risk thresholds (read-only for the app) |
| `risk_assessments` | One screening run with an input snapshot |
| `risk_results` | Probability and risk tier per disease |
| `shap_explanations` | Ranked SHAP contributions per result |
| `patient_goals` | Preventive goals |

---

## Development Status

Development follows the nine-sprint plan in the shared *Development Sprint Plan* doc.

| Sprint | Focus | Status |
| :--- | :--- | :--- |
| 0 | Project setup; database schema (17 tables, RLS, `med_app`) | Database done |
| 1 | Backend core and authentication · synthetic data design | To do |
| 2 | Health data APIs · baseline models | To do |
| 3 | Documents, OCR worker, reports · tuning, calibration, SHAP | To do |
| 4 | Frontend Screens 1–4 · model evaluation | To do |
| 5 | Frontend Screens 5–8 · risk assessment API | To do |
| 6 | Integration and debugging | To do |
| 7 | System testing and evaluation | To do |
| 8 | Docker, Nginx, DigitalOcean deployment | To do |

---

## Disclaimer

This system is a research prototype for preventive health risk screening. It does not provide medical diagnoses and does not replace consultation with a licensed healthcare provider.
