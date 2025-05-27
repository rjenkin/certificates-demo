# Other tools

## Certigo

Certigo is a utility to examine and validate certificates to help with debugging SSL/TLS issues.

Install certigo with:
```bash
brew install certigo
```

Inspect live certificates:
```bash
certigo connect google.com:443

certigo connect google.com:443 --verbose

certigo connect google.com:443 --pem

certigo connect --verbose google.com:443 --json | jq .
```

Inspect certificate on disk:
```bash
certigo dump cert1.pem --verbose
```


## ZLint

ZLint is a X.509 certificate linter written in Go that checks for consistency with standards (e.g. RFC 5280) and other relevant PKI requirements (e.g. CA/Browser Forum Baseline Requirements).

Usage:
```bash
$ zlint cert1.pem | jq .
{
  "e_aia_ca_issuers_must_have_http_only": {
    "result": "pass"
  },
  "e_aia_must_contain_permitted_access_method": {
    "result": "pass"
  },
  "e_aia_ocsp_must_have_http_only": {
    "result": "pass"
  },
  "e_aia_unique_access_locations": {
    "result": "pass"
  },
  "e_algorithm_identifier_improper_encoding": {
    "result": "pass"
  },
  "e_authority_key_identifier_correct": {
    "result": "NA"
  },
  "e_basic_constraints_not_critical": {
    "result": "NA"
  },
  "e_empty_sct_list": {
    "result": "pass"
  },
    ...
  "w_tls_server_cert_valid_time_longer_than_397_days": {
    "result": "pass"
  }
}
```

Check certificate transparency details:
```bash
zlint ../../cert1.pem | jq '{e_empty_sct_list: .e_empty_sct_list,e_scts_missing: .e_scts_missing,e_embedded_sct_not_enough_for_issuance: .e_embedded_sct_not_enough_for_issuance, e_precert_with_sct_list: .e_precert_with_sct_list,w_ct_sct_policy_count_unsatisfied: .w_ct_sct_policy_count_unsatisfied}'
```


## GRP Curl

grpcurl is a command-line tool that lets you interact with gRPC servers. It's basically curl for gRPC servers.

Usage:
```bash
% grpcurl -plaintext localhost:8090 list
grpc.reflection.v1.ServerReflection
grpc.reflection.v1alpha.ServerReflection
trillian.TrillianAdmin
trillian.TrillianLog

% grpcurl -plaintext localhost:8090 list trillian.TrillianLog
trillian.TrillianLog.AddSequencedLeaves
trillian.TrillianLog.GetConsistencyProof
trillian.TrillianLog.GetEntryAndProof
trillian.TrillianLog.GetInclusionProof
trillian.TrillianLog.GetInclusionProofByHash
trillian.TrillianLog.GetLatestSignedLogRoot
trillian.TrillianLog.GetLeavesByRange
trillian.TrillianLog.InitLog
trillian.TrillianLog.QueueLeaf
```
