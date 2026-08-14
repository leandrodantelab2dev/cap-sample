# cap-sample

Minimal SAP CAP (Node.js) project with a Products/Customers model, an OData V4 service, and a Fiori Elements List Report / Object Page app. Uses SQLite in-memory for local dev.

## Run

```bash
npm install
npm run watch     # cds watch
```

`cds watch` starts the server, deploys the SQLite in-memory DB, loads the CSV mock data, and opens the app.

## Test URLs

- Service metadata: http://localhost:4004/odata/v4/SalesService/$metadata
- Products data: http://localhost:4004/odata/v4/SalesService/Products
- Customers data: http://localhost:4004/odata/v4/SalesService/Customers
- Fiori Elements UI: http://localhost:4004/products/webapp/index.html

## Structure

```
db/schema.cds        domain model (sales.Products, sales.Customers)
db/data/*.csv         mock data
srv/service.cds        SalesService projections
srv/annotations.cds    Fiori Elements UI annotations
app/products/webapp    Fiori Elements List Report / Object Page app
mta.yaml               Cloud Foundry deployment descriptor
```

## Deploy to Cloud Foundry (SAP BTP)

One module, no HANA, no auth — the whole project (db/, srv/, app/) is packaged and run as a single Node.js app, same as `cds watch` locally. SQLite runs in-memory, so data resets on every restart/scale — fine for a demo, not for production persistence.

```bash
npm install -g mbt          # Cloud MTA Build Tool, if not already installed
mbt build                   # produces mta_archives/cap-sample_1.0.0.mtar
cf login                    # target your BTP subaccount/org/space
cf deploy mta_archives/cap-sample_1.0.0.mtar
```

After deploy, `cf apps` shows the app's route. Same test URLs as above, just swap `localhost:4004` for that route:

- `https://<route>/odata/v4/SalesService/$metadata`
- `https://<route>/odata/v4/SalesService/Products`
- `https://<route>/products/webapp/index.html`

### Add later if needed

- **Persistent DB**: swap SQLite for SAP HANA Cloud — add `@cap-js/hana`, a `db-deployer` module, and a `hana`/`hdi-container` resource in `mta.yaml`.
- **Auth**: protect the service with XSUAA — add `xs-security.json`, an `xsuaa` resource, `@requires` on the service, and assign the role collection to users in the BTP cockpit.
