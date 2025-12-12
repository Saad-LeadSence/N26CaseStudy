@IsTest
private class N26ProductInfoServiceTest {
  @testSetup
  static void setupData() {
    // Contact + Case with valid product/country (Standard_DE)
    Contact c1 = new Contact(
      LastName = 'WithConfig',
      FirstName = 'John',
      Email = 'withconfig@test.com',
      Product__c = 'Standard',
      Home_Country__c = 'DE'
    );
    insert c1;

    Case cs1 = new Case(
      Subject = 'Case_WithConfig',
      Status = 'New',
      Origin = 'Phone',
      ContactId = c1.Id
    );
    insert cs1;

    // Contact + Case with missing Product__c (should return null)
    Contact c2 = new Contact(
      LastName = 'NoProduct',
      FirstName = 'Jane',
      Email = 'noproduct@test.com',
      // Product__c = null
      Home_Country__c = 'DE'
    );
    insert c2;

    Case cs2 = new Case(
      Subject = 'Case_NoProduct',
      Status = 'New',
      Origin = 'Phone',
      ContactId = c2.Id
    );
    insert cs2;

    // Case without ContactId (should return null)
    Case cs4 = new Case(
      Subject = 'Case_NoContact',
      Status = 'New',
      Origin = 'Phone'
    );
    insert cs4;
  }

  // ------------------------------------------------------
  // Happy path: valid Case → DTO with pricing (if CMDT exists)
  // ------------------------------------------------------
  @IsTest
  static void testGetProductInfoForCase_success() {
    // Get the "with config" case
    Case cs = [
      SELECT Id, ContactId
      FROM Case
      WHERE Subject = 'Case_WithConfig'
      LIMIT 1
    ];

    Test.startTest();
    N26ProductInfoService.ProductInfoDTO dto = N26ProductInfoService.getProductInfoForCase(
      cs.Id
    );
    Test.stopTest();

    // If CMDT for Standard_DE exists, assert full mapping
    N26_Product_Config__mdt conf = N26_Product_Config__mdt.getInstance(
      'Standard_DE'
    );

    if (conf != null) {
      System.assertNotEquals(
        null,
        dto,
        'DTO should not be null when CMDT exists'
      );
      System.assertEquals(conf.Plan_Type__c, dto.planType);
      System.assertEquals(conf.Country__c, dto.country);
      System.assertEquals(conf.Monthly_Fee__c, dto.monthlyFee);
      System.assertEquals(conf.Monthly_Fee_Currency__c, dto.monthlyFeeCurrency);
      System.assertEquals(conf.ATM_Fee_Percent__c, dto.atmFeePercent);
      System.assertEquals(conf.Card_Replacement_Fee__c, dto.cardReplacementFee);
      System.assertEquals(
        conf.Card_Replacement_Currency__c,
        dto.cardReplacementCurrency
      );
    } else {
      // If CMDT not present in this org, service should gracefully return null
      System.assertEquals(
        null,
        dto,
        'DTO should be null when no CMDT config exists'
      );
    }
  }

  // ------------------------------------------------------
  // Case without ContactId → null
  // ------------------------------------------------------
  @IsTest
  static void testGetProductInfoForCase_noContact() {
    Case cs = [
      SELECT Id, ContactId
      FROM Case
      WHERE Subject = 'Case_NoContact'
      LIMIT 1
    ];

    Test.startTest();
    N26ProductInfoService.ProductInfoDTO dto = N26ProductInfoService.getProductInfoForCase(
      cs.Id
    );
    Test.stopTest();

    System.assertEquals(
      null,
      dto,
      'DTO should be null when Case has no Contact'
    );
  }

  // ------------------------------------------------------
  // Contact with missing Product__c → null
  // ------------------------------------------------------
  @IsTest
  static void testGetProductInfoForCase_missingProduct() {
    Case cs = [
      SELECT Id, ContactId
      FROM Case
      WHERE Subject = 'Case_NoProduct'
      LIMIT 1
    ];

    Test.startTest();
    N26ProductInfoService.ProductInfoDTO dto = N26ProductInfoService.getProductInfoForCase(
      cs.Id
    );
    Test.stopTest();

    System.assertEquals(
      null,
      dto,
      'DTO should be null when Contact.Product__c is blank'
    );
  }
}