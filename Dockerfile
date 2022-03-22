FROM perl:5.30.3-slim-threaded-buster
ADD remote-install.sh scripts sg-server-config.sh /
ADD scripts/* scripts/
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN bash -vx /remote-install.sh
