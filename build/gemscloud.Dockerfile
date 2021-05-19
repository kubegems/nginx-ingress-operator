FROM harbor.cloudminds.com/library/golang:1.15-stretch as build
WORKDIR /build
ARG GOPATH=/go
RUN apt install -y git
COPY . /build
# RUN go build  -ldflags="-X 'main.GitHash=`git rev-parse HEAD`' -X 'main.BuildTime=`date "+%Y-%m-%d %H:%M:%S"`'" -mod=vendor -o gems-service ./cmd/server/main.go
RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS="-gcflags=-trimpath=/go -asmflags=-trimpath=/go" GOOS=linux go build -trimpath -ldflags "-s -w" -o build/_output/bin/nginx-ingress-operator ./cmd/manager



FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/nginx-ingress-operator \
    USER_UID=1001 \
    USER_NAME=nginx-ingress-operator

# install operator binary
# COPY build/_output/bin/nginx-ingress-operator ${OPERATOR}
COPY --from=build /build/build/_output/bin/nginx-ingress-operator ${OPERATOR}

COPY --from=build /build/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

COPY LICENSE /licenses/
COPY build/kic_crds /kic_crds

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}
LABEL name="NGINX Ingress Operator" \
    description="The NGINX Ingress Operator is a Kubernetes/OpenShift component which deploys and manages one or more NGINX/NGINX Plus Ingress Controllers" \
    summary="The NGINX Ingress Operator is a Kubernetes/OpenShift component which deploys and manages one or more NGINX/NGINX Plus Ingress Controllers" \
    io.openshift.tags="nginx,ingress-controller,ingress,controller,kubernetes,openshift" \
    maintainer="NGINX Inc <kubernetes@nginx.com>" \
    vendor="NGINX Inc <kubernetes@nginx.com>"