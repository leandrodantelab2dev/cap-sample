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
```
