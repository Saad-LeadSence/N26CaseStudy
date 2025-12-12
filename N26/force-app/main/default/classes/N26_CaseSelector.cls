public with sharing class N26_CaseSelector extends fflib_SObjectSelector {
  /**
   * @description Returns the SObjectType handled by this selector.
   */
  public Schema.SObjectType getSObjectType() {
    return Case.SObjectType;
  }

  /**
   * @description Default field list – for our use cases we only need Id + ContactId.
   */
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Case.Id, Case.ContactId };
  }

  /**
   * @description Returns a Case with ContactId populated, using fflib_QueryFactory.
   *              Used by N26ProductInfoService.getProductInfoForCase.
   */
  public Case selectCaseWithContact(Id caseId) {
    if (caseId == null) {
      return null;
    }

    fflib_QueryFactory qf = newQueryFactory();
    qf.setCondition('Id = :caseId');
    qf.setLimit(1);

    // Uses default fields from getSObjectFieldList()
    List<Case> cases = (List<Case>) Database.query(qf.toSOQL());
    return cases.isEmpty() ? null : cases[0];
  }

  /**
   * @description Returns any Case for a given Contact, using fflib_QueryFactory.
   *              Used by N26ContactApi.getAnyCaseForContact.
   */
  public Case selectAnyCaseForContact(Id contactId) {
    if (contactId == null) {
      return null;
    }

    fflib_QueryFactory qf = newQueryFactory();
    qf.setCondition('ContactId = :contactId');
    qf.setLimit(1);

    // Uses default fields from getSObjectFieldList()
    List<Case> cases = (List<Case>) Database.query(qf.toSOQL());
    return cases.isEmpty() ? null : cases[0];
  }
}