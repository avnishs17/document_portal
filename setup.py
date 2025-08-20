from setuptools import setup, find_packages
from pathlib import Path

__version__ = "0.0.0"

REPO_NAME = "document_portal"
AUTHOR_USER_NAME = "avnishs17"
SRC_REPO = "document_portal"
AUTHOR_EMAIL = "avnish1708@gmail.com"

def parse_requirements(filename):
    with open(filename, encoding="utf-8") as f:
        return [
            line.strip()
            for line in f
            if line.strip() and not line.startswith("#") and not line.startswith("-e")
        ]

setup(
    name=SRC_REPO,
    author=AUTHOR_USER_NAME,
    version=__version__,
    description="An intelligent document analysis and comparison system powered by LLMs",
    long_description=Path("README.md").read_text(encoding="utf-8"),
    long_description_content_type="text/markdown",
    packages=find_packages(exclude=["tests*", "examples*"]),
    include_package_data=True,
    install_requires=parse_requirements("requirements.txt"),
    extras_require={
        "dev": ["pytest", "pylint", "ipykernel"]
    },
    classifiers=[
        "Programming Language :: Python :: 3.10",
        "License :: OSI Approved :: MIT License",
    ],
    python_requires=">=3.10",
)