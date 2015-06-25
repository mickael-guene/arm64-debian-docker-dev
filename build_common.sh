#!/bin/bash -ex

VERSION=$1
if [[ -z "$VERSION" ]]; then
    VERSION="sid"
else
    echo $VERSION
fi

#clean up function
function cleanup() {
rm -Rf $TMPDIR
}

#build script that will be executed in docker file
function build_guest_script() {
cat << EOF > ${TMPDIR}/build_guest.sh
#!/bin/bash -ex
# Since docker has not yet build env this allow to use a proxy
export http_proxy=${http_proxy}
export https_proxy=${https_proxy}

#here are the real docker command
apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    bzr \
    git \
    mercurial \
    openssh-client \
    subversion \
    autoconf \
    build-essential \
	imagemagick \
    libbz2-dev \
    libcurl4-openssl-dev \
    libevent-dev \
    libffi-dev \
    libglib2.0-dev \
    libjpeg-dev \
    liblzma-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    zlib1g-dev \
    clang \
    cmake \
    gdb \
    strace \
    vim
apt-get clean
EOF
chmod +x ${TMPDIR}/build_guest.sh
}

# build dockerfile
function build_docker_file() {
cat << EOF > ${TMPDIR}/Dockerfile
FROM mickaelguene/arm64-debian:${VERSION}
MAINTAINER Mickael Guene <mickael.guene@st.com>
# You need binfmt_misc support so the following work on x86
COPY build_guest.sh /build_guest.sh
RUN /build_guest.sh && rm /build_guest.sh
CMD ["/bin/bash"]
EOF
}

#get script location
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`(cd $SCRIPTDIR ; pwd)`

#create tmp dir
TMPDIR=`mktemp -d -t arm64_debian_docker_dev_XXXXXXXX`
trap cleanup EXIT
cd ${TMPDIR}

#build guest script
build_guest_script

#build docker file
build_docker_file

#build image
docker build -t mickaelguene/arm64-debian-dev:${VERSION} .

