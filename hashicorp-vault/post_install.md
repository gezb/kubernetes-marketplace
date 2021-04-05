## Hashicorp Vault

## Initialising and unsealing Vault

When the vault application is initially installed the pod will be not ready until you initialise vault

```
kubectl get po -n vault
NAME                                    READY   STATUS    RESTARTS   AGE
vault-agent-injector-84c5757db9-krm62   1/1     Running   0          8m50s
vault-0                                 0/1     Running   0          8m49s
```

To initialise vault run

 `kubectl exec --namespace vault -it vault-0  -- vault operator init -tls-skip-verify`

This will output 5 unseal keys and an initial root token these values should be stored somewhere safe and will only be available at this point

```
Unseal Key 1: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Unseal Key 2: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Unseal Key 3: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Unseal Key 4: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Unseal Key 5: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Initial Root Token: s.YYYYYYYYYYYYYYYYY
```

We can then unseal vault using the 3 of the 5 unseal keys above

```
kubectl exec --namespace vault -it vault-0  -- vault operator unseal  -tls-skip-verify
Unseal Key (will be hidden): 
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       7e4bdf3d-a4bd-a192-ac9a-a622e74c827a
Version            1.6.2
Storage Type       file
HA Enabled         false
```

Repeat the above unseal command 2 more times and the vault should be unsealed

```
kubectl exec --namespace vault -it vault-0  -- vault operator unseal  -tls-skip-verify
Unseal Key (will be hidden): 
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.6.2
Storage Type    file
Cluster Name    vault-cluster-ae3bfbd9
Cluster ID      b6f708b9-8973-2b74-1598-76cfb0756bde
HA Enabled      false
```

Vault should now be ready

```
kubectl get po -n vault
NAME                                    READY   STATUS    RESTARTS   AGE
vault-agent-injector-84c5757db9-krm62   1/1     Running   0          18m50s
vault-0                                 1/1     Running   0          18m49s
```

### Accessing the vault cli using kubectl

To access the `vault` command line run

`kubectl exec --namespace vault -it vault-0  -- /bin/sh`

Then login with the vault token you recorded before 

```
vault login -tls-skip-verify <token>
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.YYYYYYYYYYYYYYYYY
token_accessor       ZZZZZZZZZZZZZZZZZZ
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

### Accessing the vault UI 

### Port forward

`kubectl port-forward -n vault svc/vault-ui 8200:8200`

Vault will now be available at `https://localhost:8200/ui/vault/`

