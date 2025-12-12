public with sharing class N26ProductInfoService {
  /**
   * @description DTO returned to LWC with product pricing information.
   */
  public class ProductInfoDTO {
    @AuraEnabled public String planType;
    @AuraEnabled public String country;
    @AuraEnabled public Decimal monthlyFee;
    @AuraEnabled public String monthlyFeeCurrency;
    @AuraEnabled public Decimal atmFeePercent;
    @AuraEnabled public Decimal cardReplacementFee;
    @AuraEnabled public String cardReplacementCurrency;
  }

  // ---------------------------------------------------------------------
  // Simple selector factories (no fflib.newInstance)
  // ---------------------------------------------------------------------
  private static N26_CaseSelector caseSelector() { return new N26_CaseSelector(); }
  private static N26_ContactSelector contactSelector() { return new N26_ContactSelector(); }

  // ---------------------------------------------------------------------
  // LWC entry point (CACHEABLE: no DML, no Logger.saveLog)
  // ---------------------------------------------------------------------
  /**
   * @description Returns product info for the Case's Contact Product__c + Home_Country__c
   */
  @AuraEnabled(cacheable=true)
  public static ProductInfoDTO getProductInfoForCase(Id caseId) {
    try {
      return getProductInfoForCaseCore(caseId);

     } catch (Exception ex) {
      // Unexpected exception: log (no DML) and throw a friendly AuraHandledException
      Logger.error('N26ProductInfoService.getProductInfoForCase – unhandled exception', ex);
      Logger.setTag('caseId', String.valueOf(caseId));
      Logger.setTag('method', 'getProductInfoForCase(cacheable=true)');
      Logger.saveLog();

      throw new AuraHandledException('Something went wrong while loading product information.');
    }
  }

  // ---------------------------------------------------------------------
  // Optional NON-cacheable wrapper (if you want persisted Nebula logs)
  // ---------------------------------------------------------------------
  /**
   * @description Same functionality but allows persisted Nebula logging (DML allowed).
   * Use this only if you REALLY need stored logs from client calls.
   */
  @AuraEnabled
  public static ProductInfoDTO getProductInfoForCaseWithLogging(Id caseId) {
    try {
      ProductInfoDTO dto = getProductInfoForCaseCore(caseId);
      return dto;

    }  catch (Exception ex) {
      Logger.error('N26ProductInfoService.getProductInfoForCaseWithLogging , unhandled exception', ex);
      Logger.setTag('caseId', String.valueOf(caseId));
      Logger.setTag('method', 'getProductInfoForCaseWithLogging');
      Logger.saveLog(); // OK here (non-cacheable)

      throw new AuraHandledException('Something went wrong while loading product information.');
    }
  }

  // ---------------------------------------------------------------------
  // Core logic (shared) - keep this pure & testable
  // ---------------------------------------------------------------------
  /**
   * @description Core implementation for product info resolution (no logging, no side effects).
   */
  private static ProductInfoDTO getProductInfoForCaseCore(Id caseId) {
    if (caseId == null) {
      throw new AuraHandledException('Case Id is required');
    }

    // ---------- CRUD & FLS checks (DATA) ----------
    if (!Schema.sObjectType.Case.isAccessible() || !Schema.sObjectType.Contact.isAccessible()) {
      throw new AuraHandledException('You do not have access to view customer information.');
    }

    if (!Schema.sObjectType.Case.fields.ContactId.isAccessible()
      || !Schema.sObjectType.Contact.fields.Product__c.isAccessible()
      || !Schema.sObjectType.Contact.fields.Home_Country__c.isAccessible()
    ) {
      throw new AuraHandledException('You do not have permission to view customer product information.');
    }

    // ---------- Load Case ----------
    Case c = caseSelector().selectCaseWithContact(caseId);
    if (c == null || c.ContactId == null) {
      return null;
    }

    // ---------- Load Contact ----------
    Contact contactRecord = contactSelector().selectContactForProduct(c.ContactId);
    if (contactRecord == null) {
      return null;
    }

    // Extra safety – strip unreadable fields on Contact
    List<Contact> strippedContacts =
      (List<Contact>) Security.stripInaccessible(AccessType.READABLE, new List<Contact>{ contactRecord })
        .getRecords();

    if (strippedContacts.isEmpty()) {
      return null;
    }

    contactRecord = strippedContacts[0];

    if (String.isBlank(contactRecord.Product__c) || String.isBlank(contactRecord.Home_Country__c)) {
      return null;
    }

    String developerName = contactRecord.Product__c + '_' + contactRecord.Home_Country__c;
    N26_Product_Config__mdt conf = N26_Product_Config__mdt.getInstance(developerName);
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
