# run "podman login registry.redhat.io" and use your access.redhat.com credentials

FROM registry.redhat.io/rhel8/support-tools
COPY install_mstflint_deps.sh .
RUN bash install_mstflint_deps.sh
COPY mst_install.sh .
RUN echo install >> mst_install.sh
RUN bash mst_install.sh
