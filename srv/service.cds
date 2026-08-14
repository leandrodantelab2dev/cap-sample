using { sales } from '../db/schema';

service SalesService @(path: '/odata/v4/SalesService') {
  entity Products  as projection on sales.Products;
  entity Customers as projection on sales.Customers;
}
