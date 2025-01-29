#!/bin/bash

# install Poetry
pip install --upgrade pip
pip install poetry==1.8.5

# configure Poetry to avoid virtual environment creation (use the current environment instead)
poetry config virtualenvs.create false

# purging poetry cache
poetry cache clear --all pypi

# install dependencies using Poetry
poetry init
poetry install --no-interaction --no-ansi
poetry shell