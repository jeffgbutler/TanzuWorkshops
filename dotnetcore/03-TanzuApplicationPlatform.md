## Add to Tanzu Application Platform

```shell
tanzu apps workload create csharp-payment-calculator \
  --git-repo https://github.com/jeffgbutler/csharp-payment-calculator \
  --git-branch main \
  --type web \
  --label app.kubernetes.io/part-of=csharp-payment-calculator \
  --yes \
  --namespace workload 
```

```shell
tanzu apps workload tail -n workload csharp-payment-calculator --since 10m --timestamp
```

```shell
tanzu apps workload get -n workload csharp-payment-calculator
```
