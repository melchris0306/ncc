public with sharing class SurveyParticipantSelectorController {
  @AuraEnabled
  public static List<Contact> getContactsFromSurveyParticipants(
    String recordId
  ) {
    List<Contact> contactList = new List<Contact>();

    for (Survey_Participant__c surveyParticipant : [
      SELECT Id, Participant__c, Participant__r.Name, Participant__r.Email
      FROM Survey_Participant__c
      WHERE Survey__c = :recordId
      LIMIT 5000
    ]) {
      contactList.add(surveyParticipant.Participant__r);
    }

    return contactList;
  }

  @AuraEnabled
  public static void saveSelectedParticipants(
    List<String> objectIds,
    String recordId
  ) {
    Set<String> recordsToInsert = new Set<String>(objectIds);
    List<Survey_Participant__c> recordsToDelete = new List<Survey_Participant__c>();

    //check which ids are returned, if a survey participant id is not returned from UI, it will be deleted
    //if contact is new than what is currently in the survey participants, add it as a survey participant
    if (!objectIds.isEmpty()) {
      for (Survey_Participant__c surveyParticipant : [
        SELECT Id, Participant__c
        FROM Survey_Participant__c
        WHERE Survey__c = :recordId
        LIMIT 5000
      ]) {
        if (recordsToInsert.contains(surveyParticipant.Participant__c)) {
          recordsToInsert.remove(surveyParticipant.Participant__c);
        } else {
          recordsToDelete.add(surveyParticipant);
        }
      }

      if (!recordsToInsert.isEmpty()) {
        insertSurveyParticipants(recordsToInsert, recordId);
      }

      if (!recordsToDelete.isEmpty()) {
        try {
          delete recordsToDelete;
        } catch (Exception exc) {
          throw new AuraHandledException(exc.getMessage());
        }
      }
    } else {
      delete [
        SELECT Id, Participant__c
        FROM Survey_Participant__c
        WHERE Survey__c = :recordId
      ];
    }
  }

  private static void insertSurveyParticipants(
    Set<String> recordsToInsert,
    String recordId
  ) {
    List<Survey_Participant__c> newSurveyParticipants = new List<Survey_Participant__c>();

    for (String contactId : recordsToInsert) {
      newSurveyParticipants.add(
        new Survey_Participant__c(
          Participant__c = contactId,
          Survey__c = recordId
        )
      );
    }

    try {
      insert newSurveyParticipants;
    } catch (Exception exc) {
      throw new AuraHandledException(exc.getMessage());
    }
  }
}