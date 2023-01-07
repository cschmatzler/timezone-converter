# TimezoneConverter

## Deploying to Kubernetes

### Secret templates

The deployments of Postgres and the service require some secrets, so these need to be run first.

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret

metadata:
  name: postgres-env
  namespace: phrase

stringData:
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: Enga6aifoT3OV6aceic8opooNgod4fah3ohcohthahgh3Jae
  TIMEZONE_CONVERTER_PASSWORD: eegh9sheehee4to8Aileipheizu8dei5quie9ahquait8ufu
EOF
```

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret

metadata:
  name: timezone-converter-env
  namespace: phrase

stringData:
  DATABASE_URL: postgres://timezone_converter:eegh9sheehee4to8Aileipheizu8dei5quie9ahquait8ufu@postgres/timezone_converter
  SECRET_KEY_BASE: s1VaVf9mEWJcQLJ4bkqaHWxM8ru4SnZoraogi8GUQIQUrX0YsaEHUZc8tngotCET
  PHX_HOST: timezones.local
EOF
```

### Deploying the actual thing

```
kustomize build manifests | kubectl apply -f -
```

This command also initialises the database and should ensure everything is ready to go.

## Adding cities

Cities can be added by connecting to Postgres via `psql` and running

```
insert into cities(id, name, timezone) values(uuid_generate_v4(), 'Tokyo', 'Asia/Tokyo');
insert into cities(id, name, timezone) values(uuid_generate_v4(), 'Hamburg', 'Europe/Berlin');
insert into cities(id, name, timezone) values(uuid_generate_v4(), 'Porto', 'Europe/Lisbon');
```

The list of correct TZ database names, such as `Asia/Tokyo`, can be found, for example, on [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

