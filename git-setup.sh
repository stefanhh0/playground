#!/bin/bash

#############
# Functions #
#############

# Shows the help message.
_show_help() {
    echo -e "$(
        cat <<<"${_WHITE}NAME${_RESET}
        git-setup.sh - Script that manages the git repository.

${_WHITE}SYNOPSIS${_RESET}
        ${_WHITE}git-setup.sh${_RESET} [${_UNDERLINE}OPTION${_RESET}...]
        ${_WHITE}git-setup.sh${_RESET} [${_UNDERLINE}COMMAND${_RESET}]
        ${_WHITE}git-setup.sh${_RESET} [${_UNDERLINE}NORMALIZATION COMMAND${_RESET}]

${_WHITE}DESCRIPTION${_RESET}
        Script that manages git repositories. When run without specifying a command the following
        changes are applied:
            - Setup git configuration
            - Install githooks
            - Clean work-tree

        Run a single ${_UNDERLINE}command${_RESET} or ${_UNDERLINE}normalization command${_RESET} and exit.

${_WHITE}ECLIPSE FORMATTER${_RESET}
        The Eclipse formatter is used to format Java files via the pre-commit git hook. The
        formatter can be installed either with the option ${_UNDERLINE}--install-eclipse-formatter${_RESET} or with the
        command ${_UNDERLINE}install-eclipse-formatter${_RESET}.

        The required Eclipse version is: ${_UNDERLINE}${_ECLIPSE_DATE_VERSION}${_RESET}

        The Eclipse formatter default installation directory is:
            ${_UNDERLINE}${_ECLIPSE_FORMATTER_HOME_DEFAULT}${_RESET}

        The installation directory can be changed via specifying the environment variable:
            ${_UNDERLINE}ECLIPSE_FORMATTER_HOME${_RESET}

        It is strongly recommended to install the Eclipse formatter to an exclusive location and
        not to share the installation with the developer IDE. Main reasons for that are:
            - The formatter should be managed by this script, the developer IDE by the user.
            - The formatter has to stay for now on version ${_UNDERLINE}${_ECLIPSE_DATE_VERSION}${_RESET}.
            - The formatter may have to be updated to a different version any time.

        When installing the Eclipse formatter manually it is recommended to use the
        ${_UNDERLINE}Eclipse IDE for Java Developers${_RESET} distribution, since it is the standard distribution and may
        show faster startup time compared to e.g. the enterprise distribution.

${_WHITE}OPTIONS${_RESET}
        ${_WHITE}--install-eclipse-formatter${_RESET} [eclipse-archive]
            Install or update the Eclipse formatter. The option takes an optional argument to the
            Eclipse installer archive (zip on Windows and tar.gz on Unix). When no archive was
            specified the archive is downloaded from the internet.

        ${_WHITE}--no-check-processes${_RESET}
            Windows-only option: Prevent checking for running processes.
            Specifying this option may cause to fail the scripts, use with care.

        ${_WHITE}-h, --help${_RESET}
            Show this help message and exit.

${_WHITE}COMMANDS${_RESET}
        ${_WHITE}install-eclipse-formatter${_RESET} [eclipse-archive]
            Install or update the Eclipse formatter. The command takes an optional argument to the
            Eclipse installer archive (zip on Windows and tar.gz on Unix). When no archive was
            specified the archive is downloaded from the internet.

        ${_WHITE}list-file-extensions${_RESET}
            List all file-extensions in the current branch.

        ${_WHITE}verify${_RESET}
            Verifies the git-setup.

${_WHITE}NORMALIZATION COMMANDS${_RESET}
        ${_WHITE}normalize-all${_RESET}
            Apply all available normalization commands.

        ${_WHITE}normalize-eol${_RESET}
            Normalize end-of-line for all files of the current branch.

        ${_WHITE}normalize-java${_RESET}
            Normalize all java files for the current branch.

        ${_WHITE}normalize-tabs2spaces${_RESET}
            Normalize tabs to spaces for all files of the current branch.

        ${_WHITE}normalize-trailing-blanks${_RESET}
            Normalize trailing blanks for all files of the current branch.

        ${_WHITE}normalize-eof${_RESET}
            Normalize end-of-file for all files of the current branch."
    )" | less -r
}

# Checks that there are no changed files in the work-tree. This is important to prevent that on _clean_work_tree
# changed files are overwritten. And to run the verification. Also important when running one of the normalization commands.
_check_work_tree_clean() {
    if [ -n "$(git diff --name-only)" ]; then
        echo "ERROR: Modified files in the work-tree prevent running the script. Commit, stash or clean the work-tree and rerun the script." >&2
        exit 1
    fi
}

# Checks that the index is clean, this check is required for normalizations, since normalizations change the index and
# should not contain any file that is not related to the normalization.
_check_index_clean() {
    if [ -n "$(git diff --cached --name-only)" ]; then
        echo "ERROR: Modified files in the index prevent running the script. Commit, stash or clean the index and rerun the script." >&2
        exit 1
    fi
}

# Checks for blocking processes on Windows. Those processes may hold file locks on jars thus can prevent _clean_work_tree
# from succeeding. Checks for IntelliJ, Eclipse and Java processes.
_check_for_blocking_processes() {
    if [[ "${_WINDOWS}" == "true" && "${_CHECK_PROCESSES}" == "true" ]]; then
        local __tasklist
        __tasklist="$(tasklist)"
        if echo "${__tasklist}" | grep -q "idea64\.exe"; then
            echo "ERROR: IntelliJ IDEA is running, close it and rerun this script." >&2
            exit 1
        fi
        if echo "${__tasklist}" | grep -q "eclipse\.exe"; then
            echo "ERROR: Eclipse is running, close it and rerun this script." >&2
            exit 1
        fi
        if echo "${__tasklist}" | grep -q "java\.exe"; then
            echo "ERROR: Java is running, stop it and rerun this script." >&2
            exit 1
        fi
    fi
}

# Resets the repository local configuration that may conflict with the global settings.
_reset_repository_local_config() {
    if [ -n "$(git config --local --get core.autocrlf)" ]; then
        git config --local --unset core.autocrlf
    fi
    if [ -n "$(git config --local --get core.eol)" ]; then
        git config --local --unset core.eol
    fi
    if [ -n "$(git config --local --get core.safecrlf)" ]; then
        git config --local --unset core.safecrlf
    fi
    if [ -n "$(git config --local --get user.email)" ]; then
        git config --local --unset user.email
    fi
    if [ -n "$(git config --local --get user.name)" ]; then
        git config --local --unset user.name
    fi
}

# Configures the end-of-line git settings.
_configure_eol() {
    if [ "${_WINDOWS}" = "true" ]; then
        git config --global core.autocrlf true
    else
        git config --global core.autocrlf input
    fi
    if [ -n "$(git config --global --get core.eol)" ]; then
        git config --global --unset core.eol
    fi
    if [ -n "$(git config --global --get core.safecrlf)" ]; then
        git config --global --unset core.safecrlf
    fi
    echo "INFO: End-of-line settings have been configured."
}

# Activates the pre-commit and post-commit hook.
_activate_hooks() {
    local __hook
    for __hook in ${_HOOKS}; do
        if [ -f "${_HOOKS_DIR}/${__hook}" ]; then
            rm "${_HOOKS_DIR}/${__hook}"
        fi
        pushd "${_HOOKS_DIR}" >/dev/null
        cp -a "${_GITHOOKS_DIR}/${__hook}" ./
        popd >/dev/null
        echo "INFO: ${__hook} hook has been activated."
    done
}

# Downloads and installs the Eclipse formatter.
_install_eclipse_formatter() {
    if [ "${_INSTALL_ECLIPSE_FORMATTER}" = "false" ]; then
        return
    fi

    _init_eclipse_formatter_status
    if [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 2 ]; then
        echo "ERROR: ${_ECLIPSE_FORMATTER_DIR} exists and seems not to contain an Eclipse installation. Aborting."
        exit 1
    fi

    if [ -z "${_ECLIPSE_INSTALLER_ARCHIVE_SOURCE}" ]; then
        _download_eclipse_formatter
    else
        if [ ! -f "${_ECLIPSE_INSTALLER_ARCHIVE_SOURCE}" ]; then
            echo "ERROR: No such file: ${_ECLIPSE_INSTALLER_ARCHIVE_SOURCE}"
            exit 1
        fi
        echo "INFO: Copying eclipse archive to the workspace... please wait."
        cp "${_ECLIPSE_INSTALLER_ARCHIVE_SOURCE}" "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}"
    fi

    # Seen on linux: tar fails with "No such file", thus the extra wait
    if [ ! -f "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}" ]; then
        sleep 1
    fi

    if [ -d "${_ECLIPSE_FORMATTER_DIR}" ]; then
        rm -r "${_ECLIPSE_FORMATTER_DIR}"
    fi
    mkdir -p "${_ECLIPSE_FORMATTER_DIR}"

    pushd "${_ECLIPSE_FORMATTER_DIR}" &>>"${_LOG}"
    if [ "${_WINDOWS}" = "true" ]; then
        unzip -qq "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}"
        sleep 1
    else
        tar xzf "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}"
    fi

    mv eclipse eclipse_old
    shopt -s dotglob
    mv eclipse_old/* ./
    shopt -u dotglob
    rmdir eclipse_old

    popd &>>"${_LOG}"

    if [ -d "${_WORKSPACE}/eclipse_workspace" ]; then
        rm -r "${_WORKSPACE}/eclipse_workspace"
    fi

    if [ -f "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}" ]; then
        rm "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}"
    fi

    echo "INFO: Eclipse formatter has been installed."
}

# Downloads the Eclipse formatter from an Eclipse mirror.
_download_eclipse_formatter() {
    local __filename="eclipse-java-2021-03-R-linux-gtk-x86_64.tar.gz"
    if [ "${_WINDOWS}" = "true" ]; then
        __filename="eclipse-java-2021-03-R-win32-x86_64.zip"
    fi
    if [ -f "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}" ]; then
        rm "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}"
    fi

    echo "INFO: Downloading Eclipse:"
    curl --output "${_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE}" "https://ftp.halifax.rwth-aachen.de/eclipse/technology/epp/downloads/release/2021-03/R/${__filename}"
}

# In case the end-of-line configuration has been changed, it is required to re-checkout all files
# from the current branch to restore a clean state in the work-tree.
_clean_work_tree() {
    echo "INFO: Force updating work-tree contents from git repository... please wait."
    git ls-files -z | sed "s/${_BASENAME}//" | xargs -0 rm -f
    git checkout .
}

# Common base function for the normalization command functions.
_call_normalize_command() {
    local __normalize_command="$1"
    _check_work_tree_clean
    pushd "${_REPO_ROOT}" &>>"${_LOG}"
    git ls-files >"${_ALL_FILES}"
    eval "${__normalize_command}"
    xargs -a "${_ALL_FILES}" -d "\n" git add -f
    popd &>>"${_LOG}"
}

# Verifies the environment variables.
_verify_environment_variables() {
    if [ "${_WINDOWS}" = "true" ]; then
        # Assumes that bash was started with bash.exe --login -i, only then /usr/bin can be expected to be included 3
        # times. If /usr/bin is not in the WINDOWS Path then eclipse will fail to run the pre-commit hook.
        if [ "$(echo "${PATH}" | grep -o ":/usr/bin:" | wc -l)" -lt 3 ]; then
            _add_setup_error "ERROR: Incomplete PATH: usr/bin from git-bash installation folder is missing."
        fi
    fi
}

# Verifies the eclipse setup.
_verify_eclipse() {
    _init_eclipse_formatter_status

    if [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 1 ]; then
        _add_setup_error "ERROR: The eclipse directory ${_ECLIPSE_FORMATTER_DIR} does not exist."
    elif [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 2 ]; then
        _add_setup_error "ERROR: File not found: ${_ECLIPSE_FORMATTER_DIR}/.eclipseproduct. ${_ECLIPSE_FORMATTER_DIR} seems not to be a valid eclipse installation."
    elif [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 3 ]; then
        _add_setup_error "Unexpected eclipse version: ${_ECLIPSE_FORMATTER_VERSION_CURRENT} expected: ${_ECLIPSE_VERSION}. Directory: ${_ECLIPSE_FORMATTER_DIR}"
    fi
}

# Shows and verifies the user and email settings of the git configuration.
_verify_user_and_email() {
    _init_user_and_email

    echo "INFO: Your current name is: '$(git config --global --get user.name)' if that is not correct, use: git config --global user.name '<firstname> <family name>'"
    echo "INFO: Your current mail is: '$(git config --global --get user.email)' if that is not correct, use: git config --global user.email <email>"

    if [ "$((_USER_AND_EMAIL_STATUS & 0x1))" -eq 1 ]; then
        _add_setup_error "ERROR: Invalid user name: '${_USER_NAME}'. To fix it, use: git config --global user.name '<firstname> <family name>'"
    fi
    if [ "$((_USER_AND_EMAIL_STATUS & 0x2))" -eq 2 ]; then
        _add_setup_error "ERROR: Invalid user email: '${_USER_EMAIL}'. To fix it, use: git config --global user.email <email>'"
    fi
}

# Verifies the git-setup.
_verify() {
    echo "INFO: Verifying the git-setup."

    _verify_environment_variables
    _verify_user_and_email
    _verify_eclipse

    _process_setup_errors

    echo "INFO: The git-setup has been verified successfully."
}

# Print and add an setup error.
_add_setup_error() {
    _SETUP_ERRORS+=("$1")
}

# Checks if a setup error was added and adds all errors to the pre-commit hook.
_process_setup_errors() {
    local __message
    if [ -n "${_SETUP_ERRORS[*]}" ]; then
        sed -i '2 i exit 1' "${_HOOKS_DIR}/pre-commit"
        sed -i '2 i echo "After fixing the problem(s) run git-setup.sh verify" >&2' "${_HOOKS_DIR}/pre-commit"
        for __message in "${_SETUP_ERRORS[@]}"; do
            sed -i '2 i echo "'"${__message}"'" >&2' "${_HOOKS_DIR}/pre-commit"
            echo "${__message}" >&2
        done
        echo "After fixing the problem re-run git-setup.sh" >&2
        exit 1
    fi
}

############
# Commands #
############

# Command to list all file-extensions.
_command_list_file_extensions() {
    git ls-files | sed -E 's/^.*(\.[^.]*)$/\1/1' | grep -e "^\..*" | tr '[:upper:]' '[:lower:]' | tr -d '"' | sort -u
}

# Command to verify the git setup.
_command_verify() {
    _check_work_tree_clean
    _check_index_clean
    _activate_hooks
    _verify
}

##########################
# Normalization Commands #
##########################

# Apply all normalization commands.
_normalize_all() {
    _command_normalize_eol
    _command_normalize_java
    _command_normalize_tabs2spaces
    _command_normalize_trailing_blanks
    _command_normalize_eof
}

# Command to normalize end-of-line for all files of the current branch.
_command_normalize_eol() {
    _check_work_tree_clean
    git add --renormalize .
}

# Command to normalize all java files for the current branch.
_command_normalize_java() {
    _locate_eclipse
    _call_normalize_command _format_java
}

# Command to normalize tabs to 4 spaces for all files of the current branch.
# Note: Not only indentation tabs are normalized but also other tabs.
_command_normalize_tabs2spaces() {
    _call_normalize_command _expand_tabs2spaces
}

# Command to normalize trailing blanks for all files of the current branch.
_command_normalize_trailing_blanks() {
    _call_normalize_command _remove_trailing_blanks
}

# Command to normalize end-of-file for all files of the current branch.
_command_normalize_eof() {
    _call_normalize_command _normalize_eof
}

########
# Main #
########

set -eu

_REPO_ROOT="$(cd "$(dirname "$0")" && pwd -P)"
_BASENAME="$(basename "$0")"
_GIT_DIR="${_REPO_ROOT}/.git"
_HOOKS_DIR="${_GIT_DIR}/hooks"
_GITHOOKS_DIR="../../githooks"
_HOOKS="\
pre-commit \
post-commit"
_WHITE="\e[1;15m"
_UNDERLINE="\e[4m"
_RESET="\e[0m"
_CHECK_PROCESSES="true"
_INSTALL_ECLIPSE_FORMATTER="false"
_ECLIPSE_INSTALLER_ARCHIVE_SOURCE=""
_COMMAND=""
_COMMAND_COUNT=0
declare -a _SETUP_ERRORS

. "${_REPO_ROOT}/githooks/inc.sh"

# Liquibase files must not be normalized, since it changes the checksum.
_EXCLUDED_FILES="\
src/main/resources/db/changelog|\
${_EXCLUDED_FILES}"

_init_workspace
_ECLIPSE_INSTALLER_ARCHIVE_WORKSPACE="${_WORKSPACE}/eclipse_installer_archive"

while [[ $# -gt 0 ]]; do
    _arg="$1"
    shift
    case $_arg in
    -h | --help)
        _show_help
        exit 0
        ;;
    --install-eclipse-formatter)
        _INSTALL_ECLIPSE_FORMATTER="true"
        if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
            _ECLIPSE_INSTALLER_ARCHIVE_SOURCE="$1"
            shift
        fi
        ;;
    --no-check-processes)
        _CHECK_PROCESSES="false"
        ;;
    install-eclipse-formatter)
        _INSTALL_ECLIPSE_FORMATTER="true"
        if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
            _ECLIPSE_INSTALLER_ARCHIVE_SOURCE="$1"
            shift
        fi
        _COMMAND="_install_eclipse_formatter"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    list-file-extensions)
        _COMMAND="_command_list_file_extensions"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    verify)
        _COMMAND="_command_verify"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-all)
        _COMMAND="_normalize_all"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-eol)
        _COMMAND="_command_normalize_eol"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-java)
        _COMMAND="_command_normalize_java"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-tabs2spaces)
        _COMMAND="_command_normalize_tabs2spaces"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-trailing-blanks)
        _COMMAND="_command_normalize_trailing_blanks"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    normalize-eof)
        _COMMAND="_command_normalize_eof"
        _COMMAND_COUNT=$((_COMMAND_COUNT + 1))
        ;;
    *)
        echo "ERROR: Unknown argument: ${_arg}" >&2
        exit 1
        ;;
    esac

    if [ "${_COMMAND_COUNT}" -gt "1" ]; then
        echo "ERROR: Specifying more than one command is not allowed." >&2
        exit 1
    fi
done

if [ -n "${_COMMAND}" ]; then
    eval "${_COMMAND}"
    exit 0
fi

_check_work_tree_clean
_check_index_clean
_check_for_blocking_processes
_reset_repository_local_config
_configure_eol
_activate_hooks
_install_eclipse_formatter
_clean_work_tree
_verify
