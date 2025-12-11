public with sharing class N26ProductInfoService {
  /**
   * @description DTO returned to LWC with product pricing information.
   */
  public class ProductInfoDTO {
    @AuraEnabled
    public String planType;
    @AuraEnabled
    public String country;
    @AuraEnabled
    public Decimal monthlyFee;
    @AuraEnabled
    public String monthlyFeeCurrency;
    @AuraEnabled
    public Decimal atmFeePercent;
    @AuraEnabled
    public Decimal cardReplacementFee;
    @AuraEnabled
    public String cardReplacementCurrency;
  }

  // ---------------------------------------------------------------------
  // Simple selector factories (no fflib.newInstance)
  // ---------------------------------------------------------------------

  private static N26_CaseSelector caseSelector() {
    return new N26_CaseSelector();
  }

  private static N26_ContactSelector contactSelector() {
    return new N26_ContactSelector();
  }

  // ---------------------------------------------------------------------
  // LWC entry point
  // ---------------------------------------------------------------------

  /**
   * @description Returns product info for the Case's Contact Product__c + Home_Country__c
   */
  @AuraEnabled(cacheable=true)
  public static ProductInfoDTO getProductInfoForCase(Id caseId) {
    if (caseId == null) {
      throw new AuraHandledException('Case Id is required');
    }

    // ---------- CRUD & FLS checks (DATA) ----------
    // Object level
    if (
      !Schema.sObjectType.Case.isAccessible() ||
      !Schema.sObjectType.Contact.isAccessible()
    ) {
      throw new AuraHandledException(
        'You do not have access to view customer information.'
      );
    }

    // Field level – only fields we actually use
    if (
      !Schema.sObjectType.Case.fields.ContactId.isAccessible() ||
      !Schema.sObjectType.Contact.fields.Product__c.isAccessible() ||
      !Schema.sObjectType.Contact.fields.Home_Country__c.isAccessible()
    ) {
      throw new AuraHandledException(
        'You do not have permission to view customer product information.'
      );
    }

    // ---------- Load Case via FFLIB selector ----------
    Case c = caseSelector().selectCaseWithContact(caseId);
    if (c == null || c.ContactId == null) {
      return null;
    }

    // ---------- Load Contact via FFLIB selector ----------
    Contact contactRecord = contactSelector()
      .selectContactForProduct(c.ContactId);
    if (contactRecord == null) {
      return null;
    }

    // Extra safety – strip unreadable fields on Contact
    List<Contact> strippedContacts = (List<Contact>) Security.stripInaccessible(
        AccessType.READABLE,
        new List<Contact>{ contactRecord }
      )
      .getRecords();

    if (strippedContacts.isEmpty()) {
      return null;
    }

    contactRecord = strippedContacts[0];

    if (
      String.isBlank(contactRecord.Product__c) ||
      String.isBlank(contactRecord.Home_Country__c)
    ) {
      // Graceful "no data" – LWC shows friendly message
      return null;
    }

    String plan = contactRecord.Product__c;
    String country = contactRecord.Home_Country__c;

    // -----------------------------------------------------------------
    // METADATA QUERY: Custom Metadata retrieve method (no SOQL here)
    // -----------------------------------------------------------------
    // DeveloperName convention: <Plan>_<Country> e.g. "Standard_DE"
    String developerName = plan + '_' + country;

    N26_Product_Config__mdt conf = N26_Product_Config__mdt.getInstance(
      developerName
    );

    if (conf == null) {
      return null;
    }

    ProductInfoDTO dto = new ProductInfoDTO();
    dto.planType = conf.Plan_Type__c;
    dto.country = conf.Country__c;
    dto.monthlyFee = conf.Monthly_Fee__c;
    dto.monthlyFeeCurrency = conf.Monthly_Fee_Currency__c;
    dto.atmFeePercent = conf.ATM_Fee_Percent__c;
    dto.cardReplacementFee = conf.Card_Replacement_Fee__c;
    dto.cardReplacementCurrency = conf.Card_Replacement_Currency__c;

    return dto;
  }
}