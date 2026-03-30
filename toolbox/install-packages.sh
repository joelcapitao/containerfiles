#!/bin/bash
#
# Install packages for toolbox/sandbox environment
# Shared between Containerfile and sandbox cloud-init
#
# Usage:
#   - Containerfile: COPY install-packages.sh /tmp/ && RUN /tmp/install-packages.sh
#   - Sandbox:       curl -fsSL <url>/install-packages.sh | sudo bash
#

set -euxo pipefail

# Disable cisco-openh264 repo if present
if [[ -f /etc/yum.repos.d/fedora-cisco-openh264.repo ]]; then
    sed -i "s/enabled=1/enabled=0/" /etc/yum.repos.d/fedora-cisco-openh264.repo
fi

# Update system
dnf -y update

# Base tools
dnf -y install \
    NetworkManager \
    bind-utils \
    borgbackup \
    fd-find \
    flatpak-spawn \
    fzf \
    gettext-envsubst \
    gh \
    git \
    git-delta \
    hostname \
    inotify-tools \
    jq \
    just \
    make \
    mkpasswd \
    pinentry-tty \
    ripgrep \
    skopeo \
    nvim \
    tmux \
    vifm \
    yq

# Dev tools
dnf -y install \
    ShellCheck \
    black \
    cargo \
    clang-format \
    clippy \
    dosfstools \
    g++ \
    gcc \
    glib2-devel \
    golang \
    golang-github-cpuguy83-md2man \
    gdisk \
    krb5-devel \
    kustomize \
    libzstd-devel \
    openssl \
    openssl-devel \
    ostree-devel \
    pylint \
    python3-pip \
    python3-tox \
    rustfmt \
    yamllint

# Packaging tools
dnf -y install \
    createrepo_c \
    fedpkg \
    mock \
    rpmdevtools

# Multimedia/PDF tools
dnf -y install \
    ImageMagick \
    convert \
    poppler-utils \
    slurp \
    zathura \
    zathura-pdf-poppler

# Storage tools
dnf -y install \
    udiskie \
    zenity

# OpenShift tools (not shipped in Fedora repos)
URLS=(
    "https://mirror.openshift.com/pub/openshift-v4/clients/pipelines/latest/tkn-linux-amd64.tar.gz"
    "https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"
)
tarball="/tmp/tarball.tar.gz"
tmp_dir="/tmp/openshift-bin"
mkdir -p "$tmp_dir"
for url in "${URLS[@]}"; do
    if curl -fsSL "$url" -o "$tarball"; then
        tar -xvf "$tarball" --no-same-owner -C "$tmp_dir"
        rm -f "$tarball"
    fi
done
# Move binaries to /usr/local/bin (ignore errors if some don't exist)
for bin in oc kubectl opc tkn tkn-pac; do
    [[ -f "${tmp_dir}/${bin}" ]] && mv "${tmp_dir}/${bin}" /usr/local/bin/
done
rm -rf "$tmp_dir"

# Remove unused setuid root program
dnf -y remove mlocate || true

# Cleanup
dnf clean all

echo "Package installation complete!"
