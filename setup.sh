#!/usr/bin/env bash
#
# Metapolis first-run setup.
#
# Downloads metapolis_setup, starts the geodata backend (PostGIS by default,
# or QLever, or any SPARQL endpoint you already run) and writes the app's
# repository configuration so ResearchSpace can reach it.
#
#   ./setup.sh                          # PostGIS (default)
#   ./setup.sh --backend qlever         # QLever SPARQL endpoint with GeoSPARQL data
#   ./setup.sh --backend sparql --endpoint https://example.org/sparql
#
# Run ./setup.sh --help for all options.

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="$APP_DIR/config/repositories/metapolis.ttl"
SETUP_REPO_URL="https://github.com/villaitatti/metapolis_setup.git"

BACKEND="postgis"
SETUP_DIR="$(dirname "$APP_DIR")/metapolis_setup"
DATA_HOST="localhost"
ENDPOINT=""
PASSWORD=""
START=1
RS_URL=""
RS_USER="admin"
RS_PASSWORD="admin"
REIMPORT=0

usage() {
  cat <<EOF
Usage: ./setup.sh [options]

Backends:
  --backend postgis     PostgreSQL + PostGIS in Docker (default)
  --backend qlever      QLever SPARQL endpoint in Docker, loaded with GeoSPARQL data
  --backend sparql      An existing SPARQL endpoint (requires --endpoint)

Options:
  --endpoint URL        SPARQL query endpoint (only for --backend sparql)
  --setup-dir DIR       Where to clone metapolis_setup (default: $SETUP_DIR)
  --data-host HOST      Host name ResearchSpace uses to reach the backend
                        (default: localhost; use host.docker.internal if
                        ResearchSpace runs in Docker)
  --password PASSWORD   PostgreSQL password to set in a new .env (postgis only;
                        default: the value in .env.template)
  --no-start            Prepare files only, do not start any container
  -h, --help            Show this help

ResearchSpace (optional, needs a running instance with the app loaded):
  --rs-url URL          e.g. http://localhost:10214. Adds 'metapolis' to the
                        Ephedra federation and imports the ontology and entity
                        configurations through the REST API.
  --rs-user USER        Admin user (default: admin)
  --rs-password PASS    Admin password (default: admin)
  --reimport            Import the .trig files even if they are already loaded
EOF
}

# ---------------------------------------------------------------- helpers ---

info() { printf '\033[34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m ✗\033[0m %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed."; }

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    die "Docker Compose is required (docker compose or docker-compose)."
  fi
}

# Read KEY from a .env file, falling back to a default.
env_get() {
  local file="$1" key="$2" default="${3:-}" value
  value="$(grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- || true)"
  printf '%s' "${value:-$default}"
}

# Set KEY=value in a .env file (portable sed for macOS and Linux).
env_set() {
  local file="$1" key="$2" value="$3" escaped
  escaped="$(printf '%s' "$value" | sed -e 's/[\/&|]/\\&/g')"
  if grep -qE "^${key}=" "$file"; then
    sed -i.bak "s|^${key}=.*|${key}=${escaped}|" "$file" && rm -f "$file.bak"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

wait_healthy() {
  local container="$1" status=""
  for _ in $(seq 1 60); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null || true)"
    [ "$status" = "healthy" ] && return 0
    sleep 2
  done
  die "Container '$container' did not become healthy (last status: ${status:-unknown}). Check: docker logs $container"
}

# Count the rows the app's main query returns from a SPARQL endpoint.
sparql_count() {
  local endpoint="$1"
  curl -fsS "$endpoint" -H 'Accept: application/sparql-results+json' \
    --data-urlencode 'query=PREFIX rs_sql_sail: <http://www.researchspace.org/resource/system/sql#>
PREFIX metapolis_sql: <http://www.researchspace.org/resource/system/service/metapolis_sql#>
SELECT (COUNT(*) AS ?n) WHERE {
  ?s rs_sql_sail:hasQueryId "all_buildings" ;
     metapolis_sql:building_id ?building_id ; metapolis_sql:name ?name ;
     metapolis_sql:function ?function ; metapolis_sql:wkt ?wkt .
}' | grep -oE '"value" *: *"[0-9]+"' | grep -oE '[0-9]+' | head -1
}

# ------------------------------------------------------------------- args ---

while [ $# -gt 0 ]; do
  case "$1" in
    --backend)    BACKEND="${2:-}"; shift 2 ;;
    --endpoint)   ENDPOINT="${2:-}"; shift 2 ;;
    --setup-dir)  SETUP_DIR="${2:-}"; shift 2 ;;
    --data-host)  DATA_HOST="${2:-}"; shift 2 ;;
    --password)   PASSWORD="${2:-}"; shift 2 ;;
    --no-start)   START=0; shift ;;
    --rs-url)     RS_URL="${2%/}"; shift 2 ;;
    --rs-user)    RS_USER="${2:-}"; shift 2 ;;
    --rs-password) RS_PASSWORD="${2:-}"; shift 2 ;;
    --reimport)   REIMPORT=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            usage >&2; die "Unknown option: $1" ;;
  esac
done

case "$BACKEND" in
  postgis|qlever) ;;
  sparql) [ -n "$ENDPOINT" ] || die "--backend sparql needs --endpoint URL" ;;
  *) die "Unknown backend '$BACKEND' (use postgis, qlever or sparql)" ;;
esac

need git
need curl
if [ "$BACKEND" != "sparql" ] && [ "$START" -eq 1 ]; then need docker; fi

# ------------------------------------------------- 1. get metapolis_setup ---

info "Getting metapolis_setup into $SETUP_DIR"
if [ -d "$SETUP_DIR/.git" ]; then
  git -C "$SETUP_DIR" pull --ff-only --quiet || warn "Could not update $SETUP_DIR, using the local copy."
  ok "metapolis_setup is up to date"
else
  git clone --quiet "$SETUP_REPO_URL" "$SETUP_DIR"
  ok "Cloned metapolis_setup"
fi

# --------------------------------------------------- 2. start the backend ---

write_sql_repository() {
  local db="$1" user="$2" password="$3" port="$4"
  cat >"$REPO_CONFIG" <<EOF
# Generated by setup.sh (backend: postgis). Re-run setup.sh to change it.
@prefix repo: <http://www.openrdf.org/config/repository#> .
@prefix reposail: <http://www.openrdf.org/config/repository/sail#> .
@prefix sail: <http://www.openrdf.org/config/sail#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ephedra: <http://www.researchspace.org/resource/system/ephedra#> .
@prefix rsrepo: <http://www.researchspace.org/resource/system/repository#> .
PREFIX : <http://www.researchspace.org/resource/system/repository#>

[] a repo:Repository ;
  repo:repositoryID "metapolis" ;
  rdfs:label "Metapolis geodata (PostGIS via SQL Sail)" ;
  repo:repositoryImpl [
    repo:repositoryType "openrdf:SailRepository" ;
    reposail:sailImpl [
      sail:sailType "researchspace:SQLSail" ;
      ephedra:serviceURL "jdbc:postgresql://${DATA_HOST}:${port}/${db}" ;
      rsrepo:username "${user}" ;
      rsrepo:password "${password}" ;
      ephedra:implementsService :metapolis ;
    ] ;
  ] .
EOF
}

write_sparql_repository() {
  local endpoint="$1"
  cat >"$REPO_CONFIG" <<EOF
# Generated by setup.sh (backend: $BACKEND). Re-run setup.sh to change it.
@prefix repo: <http://www.openrdf.org/config/repository#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix sparqlr: <http://www.openrdf.org/config/repository/sparql#> .

[] a repo:Repository ;
  repo:repositoryID "metapolis" ;
  rdfs:label "Metapolis geodata (SPARQL endpoint)" ;
  repo:repositoryImpl [
    repo:repositoryType "researchspace:SPARQLRepository" ;
    sparqlr:query-endpoint <${endpoint}>
  ] .
EOF
}

case "$BACKEND" in
  postgis)
    DB_DIR="$SETUP_DIR/metapolis-db"
    ENV_FILE="$DB_DIR/.env"
    if [ ! -f "$ENV_FILE" ]; then
      cp "$DB_DIR/.env.template" "$ENV_FILE"
      [ -n "$PASSWORD" ] && env_set "$ENV_FILE" POSTGRES_PASSWORD "$PASSWORD"
      ok "Created $ENV_FILE"
    else
      [ -n "$PASSWORD" ] && warn "$ENV_FILE already exists, ignoring --password (edit the file to change it)."
      ok "Using existing $ENV_FILE"
    fi
    PG_DB="$(env_get "$ENV_FILE" POSTGRES_DB metapolis)"
    PG_USER="$(env_get "$ENV_FILE" POSTGRES_USER postgres)"
    PG_PASSWORD="$(env_get "$ENV_FILE" POSTGRES_PASSWORD)"
    PG_PORT="$(env_get "$ENV_FILE" POSTGRES_PORT 5432)"
    CONTAINER="$(env_get "$ENV_FILE" CONTAINER_NAME metapolis-postgres)"

    if [ "$START" -eq 1 ]; then
      info "Starting PostgreSQL + PostGIS ($CONTAINER, port $PG_PORT)"
      (cd "$DB_DIR" && compose up -d)
      wait_healthy "$CONTAINER"
      # pg_isready can succeed while the init scripts are still running.
      for _ in $(seq 1 30); do
        COUNT="$(docker exec "$CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -tAc \
          'SELECT count(*) FROM metapolis.buildings' 2>/dev/null || true)"
        [ -n "$COUNT" ] && break
        sleep 2
      done
      if [ -z "$COUNT" ]; then
        die "Table metapolis.buildings not found. The data volume probably existed before; see 'Resetting the database' in $DB_DIR/../README.md"
      fi
      ok "PostGIS is up: metapolis.buildings has $COUNT rows"
    fi
    write_sql_repository "$PG_DB" "$PG_USER" "$PG_PASSWORD" "$PG_PORT"
    ;;

  qlever)
    QL_DIR="$SETUP_DIR/metapolis-qlever"
    ENV_FILE="$QL_DIR/.env"
    [ -f "$ENV_FILE" ] || { cp "$QL_DIR/.env.template" "$ENV_FILE"; ok "Created $ENV_FILE"; }
    QL_PORT="$(env_get "$ENV_FILE" QLEVER_PORT 7001)"
    CONTAINER="$(env_get "$ENV_FILE" CONTAINER_NAME metapolis-qlever)"

    if [ "$START" -eq 1 ]; then
      info "Starting QLever ($CONTAINER, port $QL_PORT), indexing $QL_DIR/data/*.ttl"
      (cd "$QL_DIR" && compose up -d --force-recreate)
      wait_healthy "$CONTAINER"
      COUNT="$(sparql_count "http://localhost:$QL_PORT" || true)"
      [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] || die "QLever is up but returns no buildings. Check: docker logs $CONTAINER"
      ok "QLever is up: $COUNT buildings"
    fi
    write_sparql_repository "http://${DATA_HOST}:${QL_PORT}"
    ;;

  sparql)
    info "Checking SPARQL endpoint $ENDPOINT"
    COUNT="$(sparql_count "$ENDPOINT" || true)"
    if [ -z "$COUNT" ]; then
      warn "Could not query $ENDPOINT from this machine. Writing the configuration anyway."
    elif [ "$COUNT" -eq 0 ]; then
      warn "The endpoint answers but exposes no buildings in the Metapolis shape."
      warn "See 'Custom SPARQL endpoints' in README.md for the triples the app expects."
    else
      ok "Endpoint exposes $COUNT buildings"
    fi
    write_sparql_repository "$ENDPOINT"
    ;;
esac
ok "Wrote $REPO_CONFIG"

# ------------------------------------------- 3. configure ResearchSpace ---

CONF_DIR="$SETUP_DIR/configurations"
FEDERATION_DONE=0
IMPORT_DONE=0

rs_curl() { curl -sS -u "$RS_USER:$RS_PASSWORD" "$@"; }

# ASK query against the default repository; prints true or false.
rs_ask() {
  rs_curl "$RS_URL/sparql?repository=default" -H 'Accept: application/sparql-results+json' \
    --data-urlencode "query=$1" | grep -oE '"boolean" *: *(true|false)' | grep -oE 'true|false'
}

add_to_federation() {
  local current updated code
  current="$(rs_curl -f "$RS_URL/rest/repositories/config/ephedra")" || {
    warn "Could not read the 'ephedra' repository configuration."; return 1; }
  if grep -q 'federation#metapolis' <<<"$current"; then
    ok "'metapolis' is already in the Ephedra federation"; return 0
  fi
  if ! grep -q 'ephedra:defaultMember' <<<"$current" || ! grep -qi 'prefix fedsail:' <<<"$current"; then
    warn "Unexpected 'ephedra' configuration format, not changing it."; return 1
  fi
  # Add a new fedsail:member statement just before ephedra:defaultMember.
  updated="$(awk '
    /ephedra:defaultMember/ && !done {
      print "    fedsail:member ["
      print "      ephedra:delegateRepositoryID \"metapolis\" ;"
      print "      ephedra:serviceReference <http://www.researchspace.org/resource/system/repository/federation#metapolis>"
      print "    ] ;"
      done = 1
    }
    { print }' <<<"$current")"
  code="$(rs_curl -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: text/turtle' \
    --data-binary @- "$RS_URL/rest/repositories/config/ephedra?validate=true" <<<"$updated")"
  case "$code" in
    2??) ok "Added 'metapolis' to the Ephedra federation" ;;
    *)   warn "ResearchSpace refused the federation update (HTTP $code)."; return 1 ;;
  esac
}

import_trig() {
  local file="$1" code
  code="$(rs_curl -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/trig' \
    --data-binary @"$file" "$RS_URL/rdf-graph-store?keepSourceGraphs=true")"
  case "$code" in
    2??) ok "Imported $(basename "$file")" ;;
    *)   warn "Import of $(basename "$file") failed (HTTP $code)."; return 1 ;;
  esac
}

configure_researchspace() {
  local code
  info "Configuring ResearchSpace at $RS_URL"
  code="$(rs_curl -o /dev/null -w '%{http_code}' "$RS_URL/rest/repositories/config/ephedra" 2>/dev/null || true)"
  case "$code" in
    200) ;;
    401|403) warn "ResearchSpace rejected user '$RS_USER' (HTTP $code). Check --rs-user / --rs-password."; return ;;
    *)   warn "ResearchSpace is not reachable at $RS_URL. Skipping this part."; return ;;
  esac

  if rs_curl -fo /dev/null "$RS_URL/rest/repositories/config/metapolis" 2>/dev/null; then
    add_to_federation && FEDERATION_DONE=1
  else
    warn "ResearchSpace does not know the 'metapolis' repository yet."
    warn "Add $APP_DIR as an app, restart ResearchSpace, then run this script again."
  fi

  if [ "$REIMPORT" -eq 0 ] && [ "$(rs_ask 'ASK { <http://metapolis.com#Building> ?p ?o }')" = "true" ]; then
    ok "Metapolis ontology already loaded (use --reimport to load it again)"
    IMPORT_DONE=1
  else
    import_trig "$CONF_DIR/Metapolis_Ontology.trig" &&
      import_trig "$CONF_DIR/Metapolis_Entity.trig" && IMPORT_DONE=1
  fi
}

[ -n "$RS_URL" ] && configure_researchspace

# ---------------------------------------------------------- 4. next steps ---

step=1
next() { printf '  %d. %s\n' "$step" "$1"; step=$((step + 1)); }

printf '\n\033[32mMetapolis backend ready (%s).\033[0m\n\nRemaining steps in ResearchSpace:\n' "$BACKEND"
next "Add this folder as an app (if not done yet): $APP_DIR"
next "Restart ResearchSpace so it picks up config/repositories/metapolis.ttl."
if [ "$FEDERATION_DONE" -eq 0 ]; then
  next "Add 'metapolis' to the Ephedra federation (README, Step 4), or re-run with --rs-url."
fi
if [ "$IMPORT_DONE" -eq 0 ]; then
  next "Import with 'Keep source named graphs' in Data Import & Download (or re-run with --rs-url):"
  printf '       %s\n       %s\n' "$CONF_DIR/Metapolis_Ontology.trig" "$CONF_DIR/Metapolis_Entity.trig"
fi
next "Import the Knowledge Patterns in System Settings → Knowledge Patterns:"
printf '       %s\n' "$CONF_DIR/Metapolis_KP.trig"
