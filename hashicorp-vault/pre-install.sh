#!/bin/bash

SERVICE=vault 
NAMESPACE=vault
SECRET_NAME=vault-server-tls

TMPDIR=/tmp

openssl genrsa -out ${TMPDIR}/vault.key 2048

cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

# Create a CSR.
openssl req -new -key ${TMPDIR}/vault.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server.csr -config ${TMPDIR}/csr.conf

# Create the certificate
export CSR_NAME=vault-csr
cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create namespace ${NAMESPACE}

kubectl create -f ${TMPDIR}/csr.yaml 
# verify CSR has been created
while true; do
    kubectl get csr ${CSR_NAME}
    if [ "$?" -eq 0 ]; then
        break
    fi
done

kubectl certificate approve ${CSR_NAME}

# verify certificate has been signed
for x in $(seq 10); do
    serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
    if [[ ${serverCert} != '' ]]; then
        break
    fi
    sleep 1
done
if [[ ${serverCert} == '' ]]; then
    echo "ERROR: After approving csr ${CSR_NAME}, the signed certificate did not appear on the resource. Giving up after 10 attempts." >&2
    exit 1
fi

serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

 kubectl create secret generic ${SECRET_NAME} \
         --namespace ${NAMESPACE} \
         --from-file=vault.key=${TMPDIR}/vault.key \
         --from-file=vault.crt=${TMPDIR}/vault.crt \
         --from-file=vault.ca=${TMPDIR}/vault.ca