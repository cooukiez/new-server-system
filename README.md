
# server-system

nixos home server system

### postgres


access postgres

```sh
podman exec -it postgres psql -U admin -d app_db
```

rewrite postgres config

```sh
cat ~/containers/postgres/init-all-db.sql | podman exec -i postgres psql -U admin -d postgres
```

### podman

get exec command

```sh
podman inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <container_name_or_id>
```

### general

find wrong permissions

```sh
sudo find /opt/ -maxdepth 4 ! -user 10000 -o ! -group 10000
```