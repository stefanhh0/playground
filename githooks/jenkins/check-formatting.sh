#!/bin/bash

set -eu

_REPO_ROOT="$(git rev-parse --show-toplevel)"
. "${_REPO_ROOT}/githooks/inc.sh"

# Delegates to the _check_formatting function in githooks/inc.sh
_check_formatting
