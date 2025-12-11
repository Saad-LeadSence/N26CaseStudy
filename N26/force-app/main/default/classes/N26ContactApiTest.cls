@IsTest
private class N26ContactApiTest {
  private static final String TEST_UUID = 'uuid-123';

  @testSetup
  static void setupData() {
    // Contact with UUID, product, country
    Contact c = new Contact(
      LastName = 'Doe',
      FirstName = 'John',
      Email = 'john@test.com',
      External_UUID__c = TEST_UUID,
      Product__c = 'Standard',
      Home_Country__c = 'DE'
    );
    insert c;

    // Case for that Contact (pricing service needs a Case)
    Case cs = new Case(
      Subject = 'Test Case',
      Status = 'New',
      Origin = 'Phone',
      ContactId = c.Id
    );
    insert cs;
  }

  // ------------------------------------------------------
  // Test: Successful GET /v1/contact?uuid=xxxx
  // ------------------------------------------------------
  @IsTest
  static void testContactApiSuccess() {
    // Get the contact created in @testSetup
    Contact c = [
      SELECT Id, FirstName, LastName, Email, Product__c, Home_Country__c
      FROM Contact
      WHERE External_UUID__c = :TEST_UUID
      LIMIT 1
    ];

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    req.requestUri = '/services/apexrest/v1/contact?uuid=' + TEST_UUID;
    req.addParameter('uuid', TEST_UUID);

    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    N26ContactApi.ContactResponse response = N26ContactApi.doGet();
    Test.stopTest();

    System.assertEquals(TEST_UUID, response.uuid, 'UUID should match');
    System.assertEquals(c.Id, response.contactId, 'Contact Id should match');
    System.assertEquals('John', response.firstName);
    System.assertEquals('Doe', response.lastName);
    System.assertEquals('john@test.com', response.email);
    System.assertEquals('Standard', response.product);
    System.assertEquals('DE', response.homeCountry);

    // ---- Optional pricing asserts, only if CMDT exists ----
    N26_Product_Config__mdt pricing = N26_Product_Config__mdt.getInstance(
      'Standard_DE'
    );
    if (pricing != null) {
      System.assertEquals(pricing.Monthly_Fee__c, response.monthlyFee);
      System.assertEquals(
        pricing.Monthly_Fee_Currency__c,
        response.monthlyFeeCurrency
      );
      System.assertEquals(pricing.ATM_Fee_Percent__c, response.atmFeePercent);
      System.assertEquals(
        pricing.Card_Replacement_Fee__c,
        response.cardReplacementFee
      );
      System.assertEquals(
        pricing.Card_Replacement_Currency__c,
        response.cardReplacementCurrency
      );
    } else {
      // If metadata not present in this org, at least assert no exception & response is returned
      System.assertNotEquals(
        null,
        response,
        'Response should not be null even without CMDT'
      );
    }
  }

  // ------------------------------------------------------
  // Test: Missing UUID → 400 BAD REQUEST
  // ------------------------------------------------------
  @IsTest
  static void testMissingUuid_400() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    req.requestUri = '/services/apexrest/v1/contact';
    // No uuid parameter
    RestContext.request = req;
    RestContext.response = res;

    try {
      Test.startTest();
      N26ContactApi.doGet();
      Test.stopTest();
      System.assert(false, 'Expected exception for missing uuid');
    } catch (N26ContactApi.N26BadRequestException e) {
      System.assertEquals('Parameter "uuid" is required', e.getMessage());
    }
  }

  // ------------------------------------------------------
  // Test: UUID not found → 404 NOT FOUND
  // ------------------------------------------------------
  @IsTest
  static void testContactNotFound_404() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.httpMethod = 'GET';
    req.requestUri = '/services/apexrest/v1/contact?uuid=not-found';
    req.addParameter('uuid', 'not-found');

    RestContext.request = req;
    RestContext.response = res;

    try {
      Test.startTest();
      N26ContactApi.doGet();
      Test.stopTest();
      System.assert(false, 'Expected 404 error');
    } catch (N26ContactApi.N26NotFoundException e) {
      System.assertEquals('Contact not found for given UUID', e.getMessage());
    }
  }
}