@RestResource(urlMapping='/v1/contact')
global with sharing class N26ContactApi {
  global class ContactResponse {
    public String uuid;
    public String contactId;
    public String firstName;
    public String lastName;
    public String email;
    public String product;
    public String homeCountry;

    public Decimal monthlyFee;
    public String monthlyFeeCurrency;
    public Decimal atmFeePercent;
    public Decimal cardReplacementFee;
    public String cardReplacementCurrency;
  }

  // ---------------------------
  // Selector factories
  // ---------------------------
  private static N26_ContactSelector contactSelector() {
    return new N26_ContactSelector();
  }

  private static N26_CaseSelector caseSelector() {
    return new N26_CaseSelector();
  }

  // ---------------------------
  // REST API
  // ---------------------------

  /**
   * @description Return contact + product info based on UUID
   * Example: GET /services/apexrest/v1/contact?uuid=abc-123
   */
  @HttpGet
  global static ContactResponse doGet() {
    RestRequest req = RestContext.request;
    String uuid = req.params.get('uuid');

    // Validate UUID
    if (String.isBlank(uuid)) {
      RestContext.response.statusCode = 400;
      throw new N26BadRequestException('Parameter "uuid" is required');
    }

    // Basic access check
    if (!Schema.sObjectType.Contact.isAccessible()) {
      RestContext.response.statusCode = 403;
      throw new N26BadRequestException('Access denied to Contact records.');
    }

    // Lookup contact using selector
    Contact c = contactSelector().selectByExternalUuid(uuid);

    if (c == null) {
      RestContext.response.statusCode = 404;
      throw new N26NotFoundException('Contact not found for given UUID');
    }

    // Get any case for the contact so we can call the pricing service
    Id caseId = getAnyCaseForContact(c.Id);
    N26ProductInfoService.ProductInfoDTO dto = (caseId != null)
      ? N26ProductInfoService.getProductInfoForCase(caseId)
      : null;

    // Build API response
    ContactResponse resp = new ContactResponse();
    resp.uuid = uuid;
    resp.contactId = c.Id;
    resp.firstName = c.FirstName;
    resp.lastName = c.LastName;
    resp.email = c.Email;
    resp.product = c.Product__c;
    resp.homeCountry = c.Home_Country__c;

    if (dto != null) {
      resp.monthlyFee = dto.monthlyFee;
      resp.monthlyFeeCurrency = dto.monthlyFeeCurrency;
      resp.atmFeePercent = dto.atmFeePercent;
      resp.cardReplacementFee = dto.cardReplacementFee;
      resp.cardReplacementCurrency = dto.cardReplacementCurrency;
    }

    return resp;
  }

  /**
   * @description Returns any Case Id for a Contact using Case Selector.
   */
  private static Id getAnyCaseForContact(Id contactId) {
    if (contactId == null)
      return null;

    Case c = caseSelector().selectAnyCaseForContact(contactId);
    return (c == null) ? null : c.Id;
  }

  global class N26BadRequestException extends Exception {
  }
  global class N26NotFoundException extends Exception {
  }
}