public with sharing class N26_ContactSelector extends fflib_SObjectSelector {
  /**
   * @description Returns the SObjectType handled by this selector.
   */
  public Schema.SObjectType getSObjectType() {
    return Contact.SObjectType;
  }

  /**
   * @description Default field list – includes Product__c and Home_Country__c
   *              because those are always needed for pricing.
   */
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Contact.Id,
      Contact.FirstName,
      Contact.LastName,
      Contact.Email,
      Contact.Product__c,
      Contact.Home_Country__c
    };
  }

  /**
   * @description Returns a Contact with Product__c + Home_Country__c populated.
   *              Uses fflib_QueryFactory (newQueryFactory, setCondition, setLimit, toSOQL).
   */
  public Contact selectContactForProduct(Id contactId) {
    if (contactId == null) {
      return null;
    }

    fflib_QueryFactory qf = newQueryFactory();
    qf.setCondition('Id = :contactId');
    qf.setLimit(1);

    // Uses default fields defined above
    List<Contact> contacts = (List<Contact>) Database.query(qf.toSOQL());
    return contacts.isEmpty() ? null : contacts[0];
  }
  /**
   * @description Returns a Contact by External_UUID__c
   *              (used by N26ContactApi) using fflib_QueryFactory.
   */
  public Contact selectByExternalUuid(String uuid) {
    if (String.isBlank(uuid)) {
      return null;
    }

    fflib_QueryFactory qf = newQueryFactory();
    qf.setCondition('External_UUID__c = :uuid');
    qf.setLimit(1);

    // Fields come from getSObjectFieldList()
    List<Contact> contacts = (List<Contact>) Database.query(qf.toSOQL());
    return contacts.isEmpty() ? null : contacts[0];
  }
}