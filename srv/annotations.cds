using SalesService as service from './service';

annotate service.Products with @(
  UI: {
    HeaderInfo: {
      TypeName      : 'Product',
      TypeNamePlural: 'Products',
      Title         : { Value: name },
      Description   : { Value: description }
    },
    SelectionFields: [ name, customer_ID ],
    LineItem: [
      { Value: name },
      { Value: price },
      { Value: currency },
      { Value: stock },
      { Value: customer.name, Label: 'Customer' }
    ],
    FieldGroup #GeneratedGroup: {
      Data: [
        { Value: name },
        { Value: description },
        { Value: price },
        { Value: currency },
        { Value: stock },
        { Value: customer_ID, Label: 'Customer' }
      ]
    },
    Facets: [
      { $Type: 'UI.ReferenceFacet', Label: 'Product', Target: '@UI.FieldGroup#GeneratedGroup' }
    ]
  }
);

annotate service.Customers with @(
  UI: {
    HeaderInfo: {
      TypeName      : 'Customer',
      TypeNamePlural: 'Customers',
      Title         : { Value: name },
      Description   : { Value: email }
    },
    SelectionFields: [ name, country ],
    LineItem: [
      { Value: name },
      { Value: email },
      { Value: country }
    ],
    FieldGroup #GeneratedGroup: {
      Data: [
        { Value: name },
        { Value: email },
        { Value: country }
      ]
    },
    Facets: [
      { $Type: 'UI.ReferenceFacet', Label: 'Customer', Target: '@UI.FieldGroup#GeneratedGroup' }
    ]
  }
);
