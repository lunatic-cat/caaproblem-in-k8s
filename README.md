# CAA Problem in Kubernetes

## What

Lets Encrypt will revoke ~3M certificates due a bug in domain validation.
See more: [CAA Rechecking Incident](https://letsencrypt.org/caaproblem/)

This script helps to check if any of certificates created by [cert-manager](https://cert-manager.io/) are affected.

## Usage

```
./caaproblem-in-k8s.sh
```

will loop through all namespaces, find all certificates with `kubectl`, search through [caa-rechecking-incident-affected-serials.txt.gz](https://d4twhgtvn0ff5.cloudfront.net/caa-rechecking-incident-affected-serials.txt.gz) file with bad serial numbers:

```
Pass list of 'LANG=C sort'-ed bad serial nubers as first argument to skip download...
Doing: "curl ...caa-rechecking-incident-affected-serials.txt.gz..."
Getting all certificates from all namespaces, please be patient...
[  OK  ] ns1/secret-with-cert1 [domain1.com] serial=0300000b4e882e2268200dedf16d44eec861
[ FAIL ] ns2/secret-with-cert2 [domain2.com] serial=0300000b4e882e2268200dedf16d44eec864
```

*Script doesn't change anything.*
Handle accordingly to force certificate regeneration

Requirements: `curl`, `openssl`

## TODO

- Automatically fix certificates(?)
- Suggest to apply ingress with a different secretName to force regeneration

## Also see

- https://github.com/hannob/lecaa for checking against list of domain names
- https://checkhost.unboundtest.com manual check a single domain