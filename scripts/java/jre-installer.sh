#!/bin/bash
# ------------------------------------------------
# -- Install JRE from repo                      --
# ------------------------------------------------
#
# ------------------------------------------------

set -e
set -u

# requires sudo
[ "$(id -u)" -ne 0 ] && echo "jre-installer.sh must be run as root" && exit 1


function define(){ 
    IFS=$'\n' read -r -d '' "${1}" || true;
}

function is_java_installed() {
    local current_version
    current_version=$(java -version 2>&1)
    local installed_version
    installed_version=$(echo "${current_version}" | grep "1.8.0_" | wc -l)

    [ "${installed_version}" -gt 0 ] && return 0 || return 1
}

# openjdk signature
#
# java version "1.7.0_141"
# OpenJDK Runtime Environment (amzn-2.6.10.1.73.amzn1-x86_64 u141-b02)
# OpenJDK 64-Bit Server VM (build 24.141-b02, mixed mode)

# oracle jdk signature
#
# java version "1.8.0_144"
# Java(TM) SE Runtime Environment (build 1.8.0_144-b01)
# Java HotSpot(TM) 64-Bit Server VM (build 25.144-b01, mixed mode)



function get_java_version() {

    local current_version
    current_version=$(java -version 2>&1)

    current_version="${current_version#*\(build 1.8.0_}"
    current_version="${current_version%%)*}"
    local minor_version="${current_version%-*}"
    echo "${minor_version}"
}

function jre_installer_install() {

    local usage
    define usage <<EOF

usage:
    jre-installer.sh [ <java_type> <java_major_version> <java_minor_version> <java_build> <java_guid> [ <java_repo_dir> [ <java_target_dir> ] ] ]

   jre-installer.sh
   jre-installer.sh jre 8 144 b01 090f390dda5b47b9b721c7dfaa008135
   jre-installer.sh jre 8 144 b01 /opt/repo/dependencies
   jre-installer.sh jre 8 144 b01 /opt/repo/dependencies /opt/java

if the java tgz file is not found in the repo directory it will attempt to download it from Oracle
EOF

    [ "${#}" -ne 0 ] && [ "${#}" -ne 5 ] && [ "${#}" -ne 6 ] && [ "${#}" -ne 7 ] && echo "${usage}" && return 1

    local java_type="${1:-${java_type:-${TALEND_FACTORY_JAVA_TYPE:-jre}}}"
    local java_major_version="${2:-${java_major_version:-${TALEND_FACTORY_JAVA_MAJOR_VERSION:-8}}}"
    local java_minor_version="${3:-${java_minor_version:-${TALEND_FACTORY_JAVA_MINOR_VERSION:-144}}}"
    local java_build="${4:-${java_build:-${TALEND_FACTORY_JAVA_BUILD:-b01}}}"
    local java_guid="${5:-${java_guid:-${TALEND_FACTORY_JAVA_GUID:-090f390dda5b47b9b721c7dfaa008135}}}"
    local java_repo_dir="${6:-${java_repo_dir:-${TALEND_FACTORY_JAVA_REPO_DIR:-/opt/java}}}"
    local java_target_dir="${7:-${java_target_dir:-${TALEND_FACTORY_JAVA_TARGET_DIR:-/opt/java}}}"

    java_type="${java_type,,}"
    [ "${java_type}" != "jdk" ] && [ "${java_type}" != "jre" ] && echo "Invalid java_type parameter: valid values: [ 'jdk' | 'jre' ]" && exit 1

    local java8_installed
    java8_installed=$(echo "$current_version" | grep "1.8.0" | wc -l)
    if [ "${java8_installed}" -gt 0 ]; then
        current_version=$(get_java_version)

        echo "current_version=${current_version}" 1>&2
        echo "java_minor_version=${java_minor_version}" 1>&2

        [ ! "${java_minor_version}" -gt "${current_version}" ] && echo "Java already installed" && exit 0
    fi

#
# sample file name: jre-8u144-linux-x64.tar.gz
# sample unzip dir: jre1.8.0_144

    local java_full_version="1.${java_major_version}.0_${java_minor_version}"
    local java_filename_version="${java_major_version}u${java_minor_version}"
    local java_tgz_path="${java_repo_dir}/jre-${java_filename_version}-linux-x64.tar.gz"

    mkdir -p "${java_target_dir}/jre${java_full_version}"

    if [ ! -f "${java_tgz_path}" ]; then
        # sample url: http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jre-8u144-linux-x64.tar.gz
        wget --no-cookies --no-check-certificate --no-clobber \
             --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
             --directory-prefix="${java_repo_dir}" \
            "http://download.oracle.com/otn-pub/java/jdk/${java_filename_version}-${java_build}/${java_guid}/${java_type}-${java_filename_version}-linux-x64.tar.gz"
    fi
    tar xzpf "${java_tgz_path}" --directory "${java_target_dir}"

    export JAVA_HOME="/usr/bin/java_home"
    if [ "${java_type}" == "jdk" ]; then
        export JRE_HOME="${JAVA_HOME}/jre"
    else
        export JRE_HOME="${JAVA_HOME}"
    fi

    # append to environment file
    tee /etc/environment <<EOF
JAVA_HOME=${JAVA_HOME}
JRE_HOME=${JRE_HOME}
EOF

    # create profile.d file
    tee /etc/profile.d/jre.sh <<EOF
export JAVA_HOME="${JAVA_HOME}"
export JRE_HOME="${JRE_HOME}"
EOF

    # add alternatives and set priorities
    update-alternatives --install /usr/bin/java_home java_home "${java_target_dir}/jre${java_full_version}" 999 \
        --slave /usr/bin/java java "${java_target_dir}/jre${java_full_version}/bin/java" \
        --slave /usr/bin/javac javac "${java_target_dir}/jre${java_full_version}/bin/javac" \
        --slave /usr/bin/jar jar "${java_target_dir}/jre${java_full_version}/bin/jar"

    # select active alternative
    update-alternatives --set java_home "${java_target_dir}/jre${java_full_version}"
}

jre_installer_install "${@}"
