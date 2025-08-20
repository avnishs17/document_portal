
# Setup Guide for `document_portal`

## Step 1: Create project directory and virtual environment

```bash
mkdir document_portal
cd document_portal
conda create -p env python=3.10.18 -y
conda activate ./env
pip install uv
```

## Step 2: Create a requirements.txt file

```bash
# Step 3: Create basic project structure and files
# Step 4: Add the following to setup.py

```bash
from setuptools import setup,find_packages

with open("requirements.txt") as f:
    requirements = f.read().splitlines()


__version__ = "0.0.0"

REPO_NAME = "document_portal"
AUTHOR_USER_NAME = "avnishs17"
SRC_REPO = "document_portal"
AUTHOR_EMAIL = "avnish1708@gmail.com"


setup(
    name=SRC_REPO,
    version=__version__,
    author=AUTHOR_USER_NAME,
    author_email=AUTHOR_EMAIL,
    description="Document Portal",
    packages=find_packages(),
    install_requires = requirements,
)
```

## Step 5: Install the package in editable mode

```bash
uv pip install -r requirements.txt
```

# command for executing the fast api
# uvicorn api.main:app --port 8080 --reload    
#uvicorn api.main:app --host 0.0.0.0 --port 8080 --reload