############################################################################################
# Include script that contains shared vars and functions for the githooks and git-setup.sh #
############################################################################################

##############################
# Read environment variables #
##############################
set +u

# The user configured Eclipse formatter home. It is not mandatory to have that specified,
# in case it is empty the default fallback is used instead.
_ECLIPSE_FORMATTER_HOME="${ECLIPSE_FORMATTER_HOME}"

# For details see explanation in git-setup.sh _verify_eclipse
test -n "${_SKIP_USER_AND_EMAIL_CHECK}" || _SKIP_USER_AND_EMAIL_CHECK="false"

set -u

###############################################################################
# Public functions that are expected to be called directly from other scripts #
###############################################################################

# Entry-Point function for the pre-commit hook.
_pre_commit() {
    _init_workspace
    __clean_workspace
    __log_info "_pre_commit: start"
    __call __init_staged_files
    __call __save_working_directory
    __call __check_user_and_email
    __call __check_ascii_filename
    __call _format_java
    __call _expand_tabs2spaces
    __call _remove_trailing_blanks
    __call _normalize_eof
    __call __add_to_git_index
    __log_info "_pre_commit: end"
}

# Entry-Point function for the post-commit hook.
_post_commit() {
    __log_info "_post_commit: start"
    __call __restore_working_directory
    __log_info "_post_commit: end"
}

# Entry-Point function for jenkins/check-formatting.sh
_check_formatting() {
    _init_workspace
    __clean_workspace
    __log_info "_check_formatting: start"

    # Liquibase files must not be touched, since it changes the checksum.
    _EXCLUDED_FILES="\
src/main/resources/db/changelog|\
${_EXCLUDED_FILES}"
    __call __add_all_work_tree_files
    __call _format_java
    __call _expand_tabs2spaces
    __call _remove_trailing_blanks
    __call _normalize_eof

    local __changed_files
    __changed_files="$(git diff --name-only)"
    if [ -n "${__changed_files}" ]; then
        __log_err "Following files are not as expected: "
        echo "${__changed_files}" | tee -a "${_LOG}" 1>&2
        git checkout .
    else
        echo "Check formatting completed successfully."
    fi

    __log_info "_check_formatting: end"
    if [ -n "${__changed_files}" ]; then
        exit 1
    fi
}

# Entry-Point function for jenkins/check-author.sh
_check_author() {
    _init_workspace
    __log_info "_check_author: start"
    echo "Check author not yet implemented."
    # TODO skip when run on origin/development
    # TODO __call __check_author

    echo "Check author completed successfully."
    __log_info "_check_author: end"
}

# Entry-Point function for jenkins/check-commit-message.sh
_check_commit_message() {
    _init_workspace
    __log_info "_check_commit_message: start"
    echo "Check commit message not yet implemented."
    # TODO skip when run on origin/development
    # TODO __call __check_commit_message -> We expect the commit headline to start with regex 'SVSSH-[0-9]*[\ :]'

    echo "Check commit message completed successfully."
    __log_info "_check_commit_message: end"
}

# Entry-Point function for jenkins/check-ascii-filename.sh
_check_ascii_filename() {
    _init_workspace
    __log_info "_check_ascii_filename: start"
    echo "Check ascii filename not yet implemented."
    # TODO skip when run on origin/development
    # TODO __call __check_ascii_filename -> requires to work with staged file infos

    echo "Check ascii filename completed successfully."
    __log_info "_check_ascii_filename: end"
}

# Initializes the workspace in a non-volatile directory.
#
# On unix /tmp may or may not be volatile - that means it
# can be memory-mapped or cleaned on reboot, thus /var/tm is used.
_init_workspace() {
    mkdir -p "${_WORKSPACE}"
}

# Initializes the _ECLIPSE_FORMATTER_STATUS variable.
#
# STATUS:
#  -1 Not initialized.
#   0 Everything is okay
#   1 Eclipse directory not available
#   2 File not found: .eclipseproduct
#   3 Unexpected eclipse version in .eclipseproduct
_init_eclipse_formatter_status() {
    if [ ! -d "${_ECLIPSE_FORMATTER_DIR}" ]; then
        _ECLIPSE_FORMATTER_STATUS=1
        return 0
    fi

    local __eclipseproduct="${_ECLIPSE_FORMATTER_DIR}/.eclipseproduct"
    if [ ! -f "${__eclipseproduct}" ]; then
        _ECLIPSE_FORMATTER_STATUS=2
        return 0
    fi

    local __eclipse_version_full
    __eclipse_version_full="$(awk -F= '/version/{print $2;}' "${__eclipseproduct}")"
    _ECLIPSE_FORMATTER_VERSION_CURRENT="$(echo "${__eclipse_version_full}" | awk -F. '{print $1 "." $2;}')"
    if [ "${_ECLIPSE_FORMATTER_VERSION_CURRENT}" != "${_ECLIPSE_VERSION}" ]; then
        _ECLIPSE_FORMATTER_STATUS=3
        return 0
    fi

    _ECLIPSE_FORMATTER_STATUS=0
}

# Initializes the _USER_AND_EMAIL_STATUS variable. The function checks the user and email git config with a regex.
#
# STATUS:
#  -1 Not initialized
#   0000 0000 Everything okay
#   0000 0001 Unexpected user.name
#   0000 0010 Unexpected user.email
_init_user_and_email() {
    local __matched_username
    local __matched_useremail
    _USER_NAME="$(git config --global user.name || true)"
    _USER_EMAIL="$(git config --global user.email || true)"
    __matched_username="$(echo "${_USER_NAME}" | grep "${_USER_NAME_REGEX}" || true)"
    __matched_useremail="$(echo "${_USER_EMAIL}" | grep "${_USER_EMAIL_PRE_AT_REGEX}@${_USER_EMAIL_POST_AT_REGEX}" || true)"

    _USER_AND_EMAIL_STATUS=0
    if [ -z "${__matched_username}" ]; then
        _USER_AND_EMAIL_STATUS=$((_USER_AND_EMAIL_STATUS | 0x1))
    fi
    if [ -z "${__matched_useremail}" ]; then
        _USER_AND_EMAIL_STATUS=$((_USER_AND_EMAIL_STATUS | 0x2))
    fi
}

# Locates eclipse, in case no proper eclipse installation is found, an error message is printed and the script exits 1.
_locate_eclipse() {
    __call _init_eclipse_formatter_status

    if [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 1 ]; then
        __log_err "The eclipse directory ${_ECLIPSE_FORMATTER_DIR} does not exist."
        __log_err "Use git-setup.sh install-eclipse-formatter to setup the eclipse formatter."
        exit 1
    fi

    if [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 2 ]; then
        __log_err "File not found: ${_ECLIPSE_FORMATTER_DIR}/.eclipseproduct. ${_ECLIPSE_FORMATTER_DIR} seems not to be a valid eclipse installation."
        exit 1
    fi

    if [ "${_ECLIPSE_FORMATTER_STATUS}" -eq 3 ]; then
        __log_err "Unexpected eclipse version: ${_ECLIPSE_FORMATTER_VERSION_CURRENT} expected: ${_ECLIPSE_VERSION}. Directory: ${_ECLIPSE_FORMATTER_DIR}"
        __log_err "Use git-setup.sh install-eclipse-formatter to setup the eclipse formatter."
        exit 1
    fi
}

#######################
# Formatter Functions #
#######################

# Formats the java files using the eclipse formatter.
_format_java() {
    local __exit_status
    grep -Ei "\.java$" "${_ALL_FILES}" | grep -Ev "${_EXCLUDED_FILES}" >"${_LOCAL_FILES}" || true

    if [ -z "$(cat "${_LOCAL_FILES}")" ]; then
        return 0
    fi
    __call _locate_eclipse
    exec 3>&1 4>&2 &>>"${_LOG}" # Link file descriptor #3 with stdout, link file descriptor #4 with stderr, redirect stdout and stderr to log.
    set +e
    xargs -a "${_LOCAL_FILES}" -d "\n" "${_ECLIPSE_BIN}" \
        -nosplash \
        -consolelog \
        -debug \
        -verbose \
        -data "${_WORKSPACE}/eclipse_workspace" \
        -application org.eclipse.jdt.core.JavaCodeFormatter \
        -config "${_REPO_ROOT}/.settings/org.eclipse.jdt.core.prefs"
    __exit_status=$?
    set -e
    exec 1>&3 2>&4 3>&- 4>&- # Restore stdout and stderr, close file descriptor #3 and #4.
    if [ -d "${_WORKSPACE}/eclipse_workspace" ]; then
        rm -r "${_WORKSPACE}/eclipse_workspace"
    fi
    if [ ${__exit_status} != 0 ]; then
        __log_err "${_ECLIPSE_BIN} exited with: ${__exit_status}"
        __call __restore_working_directory
        exit 1
    fi
}

# Expands all tabs to 4 spaces.
_expand_tabs2spaces() {
    grep -Ei "${_FILE_EXTENSIONS}" "${_ALL_FILES}" | grep -Ev "${_EXCLUDED_FILES}|${_TABS_2_SPACES_EXCLUDED_FILES}" >"${_LOCAL_FILES}" || true
    if [ -z "$(cat "${_LOCAL_FILES}")" ]; then
        return 0
    fi
    xargs -a "${_LOCAL_FILES}" -d "\n" sed -i 's/\t/    /g'
}

# Removes trailing whitespaces and tabs per line.
_remove_trailing_blanks() {
    grep -Ei "${_FILE_EXTENSIONS}" "${_ALL_FILES}" | grep -Ev "${_EXCLUDED_FILES}|${_TRAILING_BLANKS_EXCLUDED_FILES}" >"${_LOCAL_FILES}" || true
    if [ -z "$(cat "${_LOCAL_FILES}")" ]; then
        return 0
    fi
    xargs -a "${_LOCAL_FILES}" -d "\n" sed -i 's/[ \t]*$//'
}

# End of File normalization.
# - Appends an empty line.
# - Removes all empty lines at the end but the last (keeps a final single LF).
_normalize_eof() {
    grep -Ei "${_FILE_EXTENSIONS}" "${_ALL_FILES}" | grep -Ev "${_EXCLUDED_FILES}" >"${_LOCAL_FILES}" || true
    if [ -z "$(cat "${_LOCAL_FILES}")" ]; then
        return 0
    fi
    xargs -a "${_LOCAL_FILES}" -d "\n" sed -i ':x; N; $!bx; s/$/\n/1;'
    xargs -a "${_LOCAL_FILES}" -d "\n" sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
}

######################################################################################
# Private functions that are *not* expected to be called directly from other scripts #
#                                                                                    #
# Private functions are marked with a leading __ (like local vars)                   #
# There is no enforcement of the private policy available, it is just a convention   #
######################################################################################

# Initializes the base environment variables.
__init_base_environment_variables() {
    # The repository name.
    _REPO_NAME=$(basename "${_REPO_ROOT}")

    # Whether the script runs on Windows or not.
    _WINDOWS="false"

    # The workspace name, the workspace is used for temporary files and logs that are used by the hooks.
    _WORKSPACE_NAME="git_hook_workspace_${_REPO_NAME}"
    if [[ $(uname -s) =~ CYGWIN*|MINGW32*|MSYS*|MINGW* ]]; then
        _WINDOWS="true"
    fi

    if [ "${_WINDOWS}" = "true" ]; then
        _WORKSPACE="/tmp/${_WORKSPACE_NAME}"
    else
        _WORKSPACE="/var/tmp/${_WORKSPACE_NAME}"
    fi

    # The home directory
    _HOME="$(cd && pwd -P)"

    # The diff filter, for details see man git-diff.
    _DIFF_FILTER="ACMR"

    # The central logging, if something goes wrong, it may contain useful information.
    _LOG="${_WORKSPACE}/workspace.log"

    # All the files that will be processed.
    _ALL_FILES="${_WORKSPACE}/all_files"

    # The local files, contains the files that are processed by the function that uses it.
    # The file is not meant to be shared between functions, it should be used locally only and
    # sub-functions must not use the file as well.
    _LOCAL_FILES="${_WORKSPACE}/local_files"

    # See _init_user_and_email for details.
    _USER_AND_EMAIL_STATUS=-1
    _USER_NAME=""
    _USER_EMAIL=""
}
# Initializes the Eclipse environment variables.
__init_eclipse_environment_variables() {
    _ECLIPSE_FORMATTER_HOME_DEFAULT="${_HOME}/opt/formatter/eclipse"

    # The Eclipse version that is expected as eclipse formatter.
    _ECLIPSE_VERSION="4.19"
    _ECLIPSE_DATE_VERSION="2021-03"

    # Eclipse state, for details see: _init_eclipse_formatter_status
    _ECLIPSE_FORMATTER_STATUS=-1
    _ECLIPSE_FORMATTER_VERSION_CURRENT=-1
    _ECLIPSE_FORMATTER_DIR="${_ECLIPSE_FORMATTER_HOME_DEFAULT}"

    if [ -n "${_ECLIPSE_FORMATTER_HOME}" ]; then
        _ECLIPSE_FORMATTER_DIR="${_ECLIPSE_FORMATTER_HOME}"
    fi

    _ECLIPSE_BIN="${_ECLIPSE_FORMATTER_DIR}/eclipse"

    if [ "${_WINDOWS}" = "true" ]; then
        _ECLIPSE_BIN="${_ECLIPSE_BIN}.exe"
    fi
}

# Initializes the regular expresssion environment variables for the files.
__init_file_regex_environment_variables() {
    # File extension definitions for grep.
    _FILE_EXTENSIONS="\
\.adoc$|\
\.au3$|\
\.bat$|\
\.checkstyle$|\
\.cmd$\.cmp$|\
\.css$|\
\.csv$|\
\.html$|\
\.js$|\
\.json$|\
\.jsp$|\
\.jspf$|\
\.properties$|\
\.rptcustom$|\
\.rptdesign$|\
\.rptlibrary$|\
\.rpttemplate$|\
\.sh$|\
\.sql$|\
\.tag$|\
\.template$|\
\.tld$|\
\.tokens$|\
\.txt$|\
\.wsdl$|\
\.xml$|\
\.xsd$|\
\.xsl$"

    # Excluded Files will not be processed.
    _EXCLUDED_FILES="\
db/changelog/liquibase-changeLog\.xml$|\
UnFormatted123456789\.java$|\
unformatiert\.jsp$|\
xmlUnformatiert_DoNotChange\.xml$"

    # Excluded tabs-to-spaces files will not be processed.
    _TABS_2_SPACES_EXCLUDED_FILES="\
src/.*\.properties$|\
\.sh$|\
\.txt$"

    _TRAILING_BLANKS_EXCLUDED_FILES="\
\.sh$"
}

# Initializes the regular expresssion environment variables for the author.
__init_author_regex_environment_variables() {
    # Regular expressions that are used to verify the Author.
    _USER_NAME_REGEX="[[:upper:]][[:alpha:].-]\{1,\}\ [[:alpha:].\ ]*[[:upper:]][[:alpha:]-]*"
    _USER_EMAIL_PRE_AT_REGEX="[[:digit:]a-z]\{1,\}[[:digit:]a-z._-]*"
    _USER_EMAIL_POST_AT_REGEX="[[:digit:]a-z_-]*\.[[:digit:]a-z._-]*[[:digit:]a-z]\{1,\}"
    _AUTHOR_REGEX="^${_USER_NAME_REGEX}\ <${_USER_EMAIL_PRE_AT_REGEX}@${_USER_EMAIL_POST_AT_REGEX}>$"
}

# The workspace is cleaned when the size of the workspace is
# 50MiB or larger.
__clean_workspace() {
    local __workspace_size=
    __workspace_size=$(du -s -m "${_WORKSPACE}" | awk '{print $1;}')
    # cleanup workspace folder when it is >= 50 MiB
    if [ "${__workspace_size}" -ge 50 ]; then
        rm -rf "${_WORKSPACE}"
        mkdir -p "${_WORKSPACE}"
    fi
}

# Initializes the staged files. If there are no staged files the script exits with status 0.
__init_staged_files() {
    pushd "${_REPO_ROOT}" &>>"${_LOG}"
    git diff --cached --name-only --diff-filter="${_DIFF_FILTER}" >"${_ALL_FILES}"

    if [ -z "$(cat "${_ALL_FILES}")" ]; then
        exit 0
    fi
    popd &>>"${_LOG}"
}

# Adds all work-tree files.
__add_all_work_tree_files() {
    git ls-files >"${_ALL_FILES}"
}

# Saves the working directory to a tar and checks-out the files.
__save_working_directory() {
    pushd "${_REPO_ROOT}" &>>"${_LOG}"
    git diff --name-only --diff-filter="${_DIFF_FILTER}" >"${_LOCAL_FILES}"
    if [ -n "$(cat "${_LOCAL_FILES}")" ]; then
        xargs -a "${_LOCAL_FILES}" -d "\n" tar czf "${_WORKSPACE}/stash.tar.gz"
        {
            echo "List ${_WORKSPACE}/stash.tar.gz";
            tar tzfv "${_WORKSPACE}/stash.tar.gz";
            echo "End of list for: ${_WORKSPACE}/stash.tar.gz"
        } &>>"${_LOG}"
        xargs -a "${_LOCAL_FILES}" -d "\n" git checkout &>>"${_LOG}"
    fi
    popd &>>"${_LOG}"
}

# Checks the _USER_AND_EMAIL_STATUS and if it indicates an error, a message is printed and the script exits with status 1.
__check_user_and_email() {
    if [ "${_SKIP_USER_AND_EMAIL_CHECK}" = "true" ]; then
        return
    fi
    __call _init_user_and_email

    if [ "$((_USER_AND_EMAIL_STATUS & 0x1))" -eq 1 ]; then
        __log_err "Invalid user name: '${_USER_NAME}'."
        __log_err "To fix it, use: git config --global user.name '<firstname> <family name>'"
    fi
    if [ "$((_USER_AND_EMAIL_STATUS & 0x2))" -eq 2 ]; then
        __log_err "Invalid user email: '${_USER_EMAIL}'."
        __log_err "To fix it, use: git config --global user.email <email>'"
    fi
    if [ "${_USER_AND_EMAIL_STATUS}" -ne 0 ]; then
        exit 1
    fi
}

# Checks that newly added files are ascii files. If there is a file that is not
# an ascii file then the script exits with status 2.
__check_ascii_filename() {
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        against=HEAD
    else
        # Initial commit: diff against an empty tree object
        against=$(git hash-object -t tree /dev/null)
    fi

    # Cross platform projects tend to avoid non-ASCII filenames; prevent
    # them from being added to the repository. We exploit the fact that the
    # printable range starts at the space character and ends with tilde.
    if
        # Note that the use of brackets around a tr range is ok here, (it's
        # even required, for portability to Solaris 10's /usr/bin/tr), since
        # the square bracket bytes happen to fall in the designated range.
        test "$(git diff --cached --name-only --diff-filter=A -z "$against" |
            LC_ALL=C tr -d '[ -~]\0' | wc -c)" != 0
    then
        __log_err "non-ASCII file names are not allowed."
        call __restore_working_directory
        exit 1
    fi
}

# Restores only the files that have been marked changed in the work dir when the pre-commit ran, that are all files
# that haven't been added to the index at all or that have only been added partially to the index.
__restore_working_directory() {
    pushd "${_REPO_ROOT}" &>>"${_LOG}"
    if [ -f "${_WORKSPACE}/stash.tar.gz" ]; then
        tar xzf "${_WORKSPACE}/stash.tar.gz"
        rm "${_WORKSPACE}/stash.tar.gz"
    fi
    popd &>>"${_LOG}"
}

# Adds the formatted files to the git index. In case there is nothing to commit the script exits with 1.
__add_to_git_index() {
    pushd "${_REPO_ROOT}" &>>"${_LOG}"
    xargs -a "${_ALL_FILES}" -d "\n" git add -f &>>"${_LOG}"
    if [ "$(git diff --cached --name-only | wc -l)" -eq 0 ]; then
        __log_err "Nothing to commit, git index contained no changes after formatting."
        __call __restore_working_directory
        exit 1
    fi
    popd &>>"${_LOG}"
}

# Calls the given command and also logs start and end.
__call() {
    local __command="$1"
    __log_info "${__command}: start"
    eval "${__command}"
    __log_info "${__command}: end"
}

# Logs the given string to the log
__log_info() {
    echo "$(date) - INFO: $1" >>"${_LOG}"
}

# Logs the given string to the log and to the err.
__log_err() {
    echo "$(date) - ERROR: $1" | tee -a "${_LOG}" 1>&2
}

##################################################
# init - implicitly run when including this file #
##################################################

__init_base_environment_variables
__init_file_regex_environment_variables
__init_author_regex_environment_variables
__init_eclipse_environment_variables
