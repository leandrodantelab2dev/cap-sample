namespace sales;

entity Products {
  key ID          : UUID;
      name        : String(100);
      description : String(255);
      price       : Decimal(10,2);
      currency    : String(3) default 'BRL';
      stock       : Integer;
      customer    : Association to Customers;
}

entity Customers {
  key ID       : UUID;
      name     : String(100);
      email    : String(120);
      country  : String(3);
      products : Association to many Products on products.customer = $self;
}
