ARG BASE_IMAGE="debian:buster-slim"

FROM $BASE_IMAGE AS builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        libjpeg62-turbo \
        libjpeg62-turbo-dev \
        locales \
        python3 \
        python3-dev \
        python3-distutils \
        zlib1g \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Setup the C.UTF-8 Locale, since otherwise it defaults to an ASCII one
    && locale-gen C.UTF-8

ENV LC_ALL="C.UTF-8"

# Install the latest version of pip.
RUN curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3 - --no-cache-dir \
    # Create virtual environment to make copying of dependencies easier in the second
    # stage of the build.
    && python3 -m pip install --no-cache-dir virtualenv \
    && python3 -m virtualenv /opt/venv

# Use the virtual environment.
ENV PATH="/opt/venv/bin:$PATH"

# Install pywikibot and dependencies.
WORKDIR /srv/pwb
COPY . .
RUN python3 -m pip install --no-cache-dir -r requirements.txt \
    && python3 -m pip install --no-cache-dir -r dev-requirements.txt \
    && python3 -m pip install --no-cache-dir .

# Begin second stage of the build. This starts fresh, and artifacts from the previous
# build stage are copied. This allows us to exclude compile-time dependencies like gcc
# and `-dev` packages.
FROM $BASE_IMAGE

# Copy the installed packages from the virtual environment. This includes pywikibot and
# all of its dependencies.
COPY --from=builder /opt/venv /opt/venv

# Install runtime system dependencies.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        libjpeg62-turbo \
        locales \
        python3 \
        python3-distutils \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen C.UTF-8

ENV LC_ALL="C.UTF-8" \
    PATH="/opt/venv/bin:$PATH"

LABEL maintainer="Pywikibot team <pywikibot@lists.wikimedia.org>"

CMD ["/bin/bash"]
