"""
Setup script for NiFi REST API Client
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="nifi-client",
    version="1.0.0",
    author="NiFi REST Team",
    description="Simple Python client for Apache NiFi REST API",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/wiederMatan/nifi-rest",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.7",
    install_requires=[
        "requests>=2.31.0",
        "urllib3>=2.0.0",
    ],
    entry_points={
        "console_scripts": [
            "nifi-cli=nifi_client.cli:main",
        ],
    },
)
