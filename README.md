<h1>Projet TP Kubernetes</h1>

<p>Ce projet dispose d'une API en python (services/products). Tout ce qui concerne Kubernetes est situé sous infra/k8s.</p>

<p>Ligne d'initialisation de la table "products" (nécessaire pour que ça fonctionne, à exécuter dans psql) :</p>

```sql
create table products(id serial primary key,name varchar(50),description varchar(100),price money);
```

<p>Tip : Pour se connecter à la db :</p>

```sh
kubectl exec -it <nom_du_pod> -n python-proj --  psql -h localhost -U admin --password -p 5432 postgresdb
```