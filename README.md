# Komodor Terraform Add-on (Cluster-based)

This bundle installs Komodor in AKS clusters using only cluster-name based API key mapping.

## Files
- `variables.tf`         — your original variables plus Komodor API key map
- `aks_spec.tf`          — original spec with Komodor stubs added
- `komodor.tf`           — Helm release and namespace for Komodor (cluster lookup only)
- `values-komodor.yaml`  — non-secret chart values

## Provide API Keys
Example in tfvars:
```hcl
komodor_api_keys_by_cluster = {
  "fnfi-lev-aks-dev-01"  = "dev-xxxxx"
  "fnfi-lev-aks-sbx-01"  = "sbx-yyyyy"
  "fnfi-lev-aks-perf-01" = "perf-zzzzz"
}
```

## Apply
```bash
terraform apply -var='env_ref=dev'
```
