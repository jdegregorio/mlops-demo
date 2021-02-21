# MLOps Experimentation

## Goals
- Modeling Task/Complexity
    - Live data source (i.e. Seattle Open Data)
    - Include hypertuning parameters (want to be able to stress-test MLOps system)
- Data Science Methodology
    - Leverage DSLP repository template/process
    - Tidymodels framework
    - renv for reproducible tracking of environment requirements
    - Full Reproducibility/Time-Travel (DVC)
- MLOps Pipeline
    - Modeling Pipeline (DVC)
        - Extract Data
        - Prepare Data
        - Train Model
        - Evaluate Model
    - Automated Testing (GitHub Actions, CML)
        - Validate Data
        - Validate Model
    - Store/Monitor Run Data (DVC, CML)
        - Run metadata (i.e. date, targets, execution time, etc)
        - Data validation results
        - Model validation results
        - Model metrics
        - Model parameters
    - Build & Push Docker (Docker, Docker Compose)
    - Deploy to Cloud
- Triggers
    - Git push
    - CRON (daily)

## Primary Tools/Stack
- Data Version Control (DVC) - ML Pipelines, Data Versioning/Management, Metric/Parameter Tracking
- GitHub Actions - CI/CD/CT
- Continous Machine Learning (CML)

## Default Directory Structure

```
├── .cloud              # for storing cloud configuration files and templates (e.g. ARM, Terraform, etc)
├── .github
│   ├── ISSUE_TEMPLATE
│   │   ├── Ask.md
│   │   ├── Data.Aquisition.md
│   │   ├── Data.Create.md
│   │   ├── Experiment.md
│   │   ├── Explore.md
│   │   └── Model.md
│   ├── labels.yaml
│   └── workflows
├── .gitignore
├── README.md
├── code
│   ├── datasets        # code for creating or getting datasets
│   ├── deployment      # code for deploying models
│   ├── features        # code for creating features
│   └── models          # code for building and training models
├── data                # directory is for consistent data placement. contents are gitignored by default.
│   ├── README.md
│   ├── interim         # storing intermediate results (mostly for debugging)
│   ├── processed       # storing transformed data used for reporting, modeling, etc
│   └── raw             # storing raw data to use as inputs to rest of pipeline
├── docs
│   ├── code            # documenting everything in the code directory (could be sphinx project for example)
│   ├── data            # documenting datasets, data profiles, behaviors, column definitions, etc
│   ├── media           # storing images, videos, etc, needed for docs.
│   ├── references      # for collecting and documenting external resources relevant to the project
│   └── solution_architecture.md    # describe and diagram solution design and architecture
├── environments
├── notebooks
├── pipelines           # for pipeline orchestrators i.e. AzureML Pipelines, Airflow, Luigi, etc.
├── setup.py            # if using python, for finding all the packages inside of code.
└── tests               # for testing your code, data, and outputs
    ├── data_validation
    └── unit
```
