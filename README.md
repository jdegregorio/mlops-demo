# MLOps Experimentation

## Project Goals
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

## Machine Learning Problem Summary

In order to accomplish the project objectives stated above, we will require a machine learning problem for experimentation and demonstration purposes.  We will be utilizing real-time 911 dispatch data from the Seattle Fire Department, available from the Seattle Open Data Portal ([LINK](https://data.seattle.gov/Public-Safety/Seattle-Real-Time-Fire-911-Calls/kzjm-xkqj)).

### Problem Statement

The 911 call center must be able to properly staff their department in order to adequately respond to 911 calls within a reasonable time.

### Actions/Decisions

The call center can add/decrease staff on a daily, weekly, and seasonal schedule.  

### Data

The only data available are the individual call logs, which contains the datetime, type of response, and location.  

Constraints - No data is available to indicate staffing levels at the call center, the response time of the call, or the duration of each call. 

### Analysis

Due to the data constraints stated above, the ability to advise direction on the available actions/decisions is limited.  However, a forecast of the upcoming n days of call volumes should provide welcome insight into adjustments to staffing levels if necessary.  The initial approach will be to predict the following 7 days of volumes.  However, the framwork should be extensible to include a larger window if needed.

As a baseline, several benchmark experiments will be created to determine if the machine learning model can provide sufficient lift above the status quo:
- Dummy Model - predict the value from the last observed day of call volumes for each day in the prediction window
- Smarter Dummy Model - predice the value from the last observed similar weekday for each day in the prediction window (i.e. use last Tuesday's volume to predict next Tuesday's call volume)

### Evaluation

The experimentation/analysis will be evaluated using the following methodology:
- Resample/split data using a rolling time-series approach
    - Minimum train data - 3 years (i.e. starting sample)
    - Train samples - Data from start until "today" (or split point)
    - Test samples - Next n days after split
- Metrics 
    - Root Mean Squared Error (RSME) calcaulated over each day in the forecast window
    - Time window weighting decay - As an overall model score, a weighted sum of RMSE across the forecast window will be calculated.  The weights will decay linearly as the forecasted date is further from today's date, such that if x is "days from now", then y is `1 - ((x-1) / max(x))`

## Default Directory Structure

```
├── .cloud              # for storing cloud configuration files and templates (e.g. ARM, Terraform, etc)
├── .github
├── .gitignore
├── README.md
├── code                # code for running pipeline, numbered in the order of execution
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
├── eda                 # folder for storing exploratory code and results (only used in explore branches)
└── tests               # for testing your code, data, and outputs
    ├── data_validation
    └── unit
```
