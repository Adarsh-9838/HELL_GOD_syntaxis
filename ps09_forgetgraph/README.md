# FORGETGRAPH — PS09

FORGETGRAPH is a local, deterministic prototype demonstrating dependency-aware deletion in a synthetic machine-learning pipeline. It tracks user-linked artifacts in SQLite, executes deletion steps in dependency order, independently verifies the replacement model, prevents managed re-ingestion of deleted IDs, and creates integrity-hashed deletion evidence certificates.

> **Prototype boundary:** This project uses synthetic data and a local SQLite database. It is not a production erasure service, does not connect to external data stores, and does not prove deletion from backups or systems outside this application.

## Features

- **Lineage-aware impact preview:** shows which pipeline artifacts are linked to a selected synthetic user.
- **Ordered deletion workflow:** removes the source record, recomputes engineered features, invalidates cached predictions, and replaces the Ridge model.
- **Recovery demonstration:** optionally simulates an interruption after a selected stage and resumes from persisted progress.
- **Independent verification:** compares the replacement model with a separately trained reference model, including coefficients, intercept, and retained-user predictions.
- **Tombstone protection:** blocks re-ingestion through the application's managed ingestion method.
- **Deletion evidence certificates:** stores versioned JSON evidence, SHA-256 integrity hashes, and a printable SVG receipt.
- **Audit trail:** displays persisted workflow events without exposing raw user IDs in event details.

## Project structure

```text
ps09_forgetgraph/
├── app.py                         # Streamlit dashboard
├── config.json                    # Model and verification settings
├── data/
│   └── synthetic_users.csv         # Committed synthetic sample data
├── generate_dataset.py            # Regenerate synthetic dataset (if needed)
├── requirements.txt               # Python dependencies
├── setup.ps1                      # Windows environment setup
├── run.ps1                        # Windows dashboard launcher
├── src/forgetgraph/
│   ├── orchestrator.py             # SQLite workflow, lineage, certificates
│   ├── certificate_image.py        # SVG receipt generation
│   ├── config.py                   # Configuration loading
│   ├── features.py                 # Feature engineering
│   ├── reference.py                # Independent reference training
│   └── training.py                 # Replacement model training
└── tests/                          # Backend, certificate, and dashboard tests
```

## Requirements

- Windows 10/11, macOS, or Linux
- Python **3.12 recommended** (Python 3.10 or later is declared by the package)
- Internet access for the first dependency installation only
- No API keys or external services are required to run the app

Python 3.12 is recommended for the smoothest compatibility with scientific Python packages. If you have multiple Python versions on Windows, install Python 3.12 and use the `py -3.12` launcher.

## Windows setup — PowerShell

Open PowerShell in the extracted `ps09_forgetgraph` folder. For example:

```powershell
cd C:\PROJECTS\Syntaxis\achithon-2026-syntaxis\ps09_forgetgraph
```

If PowerShell blocks the setup script, allow it for this terminal session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Run setup:

```powershell
.\setup.ps1
```

The script creates `.venv`, upgrades pip, and installs the dependencies from `requirements.txt`.

### Manual setup alternative

If you do not want to run the script:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

If `py -3.12` is unavailable but `python` points to a compatible Python installation, replace `py -3.12` with `python`.

## Run the dashboard

From the `ps09_forgetgraph` folder:

```powershell
.\run.ps1
```

Or run it directly:

```powershell
.\.venv\Scripts\python.exe -m streamlit run app.py
```

Streamlit normally opens the browser automatically. If it does not, open:

**http://localhost:8501**

Keep the terminal open while using the dashboard. Press `Ctrl+C` in that terminal to stop it.

## Run tests

Run all tests:

```powershell
.\.venv\Scripts\python.exe -m pytest -v
```

Run only the backend and certificate tests:

```powershell
.\.venv\Scripts\python.exe -m pytest -v tests\test_orchestrator.py tests\test_certificate_image.py
```

The dashboard tests use Streamlit's `AppTest` and are included in the full test suite.

## Guided demo

1. Open **Overview** and review the current source, feature, cache, and model counts.
2. Open **Deletion workflow** and enter an active synthetic ID such as `user-0002`.
3. Review the affected artifacts shown in the lineage graph before starting.
4. Select **Run deletion**. The workflow executes the required operations in dependency order. In a fresh database, deleting one user reduces source and feature rows by one and clears the prediction cache.
5. Review the separate execution and independent-verification statuses. A completed deletion is not the same thing as a passed verification.
6. Open **Verification** to inspect the checks, model comparison, tolerances, and measured differences.
7. Open **Evidence Certificates** to inspect the certificate status, evidence, integrity validation, SVG receipt, and JSON download.
8. Open **Audit trail** to inspect persisted events.

### Demonstrate recovery

1. Open **Deletion workflow**.
2. Enable **Test recovery by simulating an interruption**.
3. Choose the step after which the workflow should pause.
4. Run the deletion and then select **Resume interrupted deletion**.
5. Confirm that completed stages are not repeated and that the workflow proceeds from its saved state.

### Demonstrate repeated-request and re-ingestion protection

After a user has been deleted, submit the same ID again. The orchestrator should report that it is already deleted without creating another deletion workflow. The managed ingestion method also checks the tombstone registry before inserting a user.

## Data and database behavior

The committed CSV contains the synthetic seed users. On first launch, the orchestrator initializes `data/forgetgraph.sqlite` and populates the database. The database is created locally and is intentionally not included in the source archive.

**Do not delete or replace `data/forgetgraph.sqlite` as a casual reset.** Reinitializing the database from the original CSV removes saved workflows and tombstones and therefore reintroduces synthetic IDs that had previously been deleted in the demo.

To perform a clean demo, make a separate copy of the project folder first and use that copy's database. Do not treat a database reset as proof of persistent deletion.

## Design and verification notes

- User IDs are represented in persisted source keys, lineage, and tombstones by SHA-256 hashes. Hashing is pseudonymization, not anonymization.
- The feature pipeline is recomputed from retained source rows after deletion so group aggregates are recalculated.
- The prediction cache is invalidated because predictions may depend on changed features or model parameters.
- The replacement model and independent reference model use separate training paths. Verification compares the resulting coefficients, intercept, and retained-user predictions using the configured tolerances in `config.json`.
- The old-to-replacement model difference is reported as evidence; a model is not required to differ from its previous version for independent verification to pass.
- Certificates are generated from persisted execution and verification evidence. Revisions retain earlier snapshots. `VERIFIED` requires completed execution, passing independent verification, and complete evidence. Missing evidence remains `INCOMPLETE`.
- The certificate's SHA-256 digest detects changes relative to the stored digest. It is not a digital signature and does not establish who created the certificate.

## Limitations

- Synthetic data only; no external databases, warehouses, caches, model registries, or cloud storage are connected.
- No authentication or authorization is implemented.
- The orchestrator is designed for a **single user and single process**. Do not run overlapping deletion, resume, or verification operations.
- The tombstone guard applies only to ingestion performed through this application's managed ingestion method. Other code paths could bypass it.
- Local SQLite file owners can alter the database. There is no independent external trust anchor for certificate hashes.
- Database backups, replicas, logs, and external copies are outside the demonstrated deletion scope.

## Troubleshooting

**`No module named streamlit`**

Install the dependencies into this project's virtual environment:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

**`No module named pytest`**

The same requirements command installs pytest. Then run tests using the virtual-environment interpreter.

**PowerShell says scripts are disabled**

Run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` in the current PowerShell window, then run `setup.ps1` or `run.ps1` again. Alternatively, use the direct interpreter commands above.

**Port 8501 is already in use**

Run Streamlit on another port:

```powershell
.\.venv\Scripts\python.exe -m streamlit run app.py --server.port 8502
```

Then open `http://localhost:8502`.
