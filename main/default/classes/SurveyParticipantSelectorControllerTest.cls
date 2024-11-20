@isTest(IsParallel=true)
public with sharing class SurveyParticipantSelectorControllerTest {
  @testSetup
  public static void setupData() {
    Contact contact1 = TestFactory.createContact(
      'Test Fname',
      'Lname',
      'test@test.com.invalid'
    );
    Contact contact2 = TestFactory.createContact(
      'Diff Test Fname',
      'Diff Lname',
      'test@test.com.invalid2'
    );
    Contact contact3 = TestFactory.createContact(
      'Diff Test Fname1',
      'Diff Lname2',
      'test@test.com.invalid3'
    );
    Contact contact4 = TestFactory.createContact(
      'Diff Test Fname3',
      'Diff Lname4',
      'test@test.com.invalid4'
    );
    Survey__c survey = TestFactory.createSurvey(null, 'Test Survey');

    insert new List<Survey_Participant__c>{
      new Survey_Participant__c(
        Participant__c = contact1.Id,
        Survey__c = survey.Id
      ),
      new Survey_Participant__c(
        Participant__c = contact2.Id,
        Survey__c = survey.Id
      )
    };
  }

  @isTest
  public static void getContactsFromSurveyParticipants_shouldReturnSurveyParticipants_whenValidSurveyIdIsProvided() {
    final Id SURVEY_ID = [SELECT Id FROM Survey__c LIMIT 1].Id;

    Test.startTest();
    List<Contact> participantContacts = SurveyParticipantSelectorController.getContactsFromSurveyParticipants(
      SURVEY_ID
    );
    Test.stopTest();

    System.assertEquals(
      2,
      participantContacts.size(),
      'There should be 2 results returned'
    );
  }

  @isTest
  public static void getContactsFromSurveyParticipants_shouldNotReturnSurveyParticipants_whenInvalidSurveyIdIsProvided() {
    Test.startTest();
    List<Contact> participantContacts = SurveyParticipantSelectorController.getContactsFromSurveyParticipants(
      null
    );
    Test.stopTest();

    System.assert(
      participantContacts.isEmpty(),
      'There should be no results returned'
    );
  }

  @isTest
  public static void saveSelectedParticipants_shouldInsertParticipant_whenNewContactIdIsProvided() {
    final Id SURVEY_ID = [SELECT Id FROM Survey__c LIMIT 1].Id;
    List<String> contactIds = new List<String>();

    for (Contact contactRecord : [
      SELECT Id
      FROM Contact
      WHERE Email IN ('test@test.com.invalid3', 'test@test.com.invalid')
    ]) {
      contactIds.add(contactRecord.Id);
    }

    Test.startTest();
    SurveyParticipantSelectorController.saveSelectedParticipants(
      contactIds,
      SURVEY_ID
    );
    Test.stopTest();

    List<Survey_Participant__c> surveyParticipantList = [
      SELECT Id
      FROM Survey_Participant__c
      WHERE Participant__r.Email = 'test@test.com.invalid3'
    ];

    System.assertEquals(
      1,
      surveyParticipantList.size(),
      'Survey Participant record should have been inserted'
    );
  }

  @isTest
  public static void saveSelectedParticipants_shouldDeleteParticipant_whenExistingContactIdIsNotProvided() {
    final Id SURVEY_ID = [SELECT Id FROM Survey__c LIMIT 1].Id;
    List<String> contactIds = new List<String>();

    for (Contact contactRecord : [
      SELECT Id
      FROM Contact
      WHERE Email IN ('test@test.com.invalid')
    ]) {
      contactIds.add(contactRecord.Id);
    }

    Test.startTest();
    SurveyParticipantSelectorController.saveSelectedParticipants(
      contactIds,
      SURVEY_ID
    );
    Test.stopTest();

    List<Survey_Participant__c> surveyParticipantList = [
      SELECT Id
      FROM Survey_Participant__c
      WHERE Participant__r.Email = 'test@test.com.invalid2'
    ];

    System.assert(
      surveyParticipantList.isEmpty(),
      'Survey Participant record should have been deleted'
    );
  }

  @isTest
  public static void saveSelectedParticipants_shouldDeleteAllParticipants_whenNoExistingContactIdsAreProvided() {
    final Id SURVEY_ID = [SELECT Id FROM Survey__c LIMIT 1].Id;

    Test.startTest();
    SurveyParticipantSelectorController.saveSelectedParticipants(
      new List<String>(),
      SURVEY_ID
    );
    Test.stopTest();

    List<Survey_Participant__c> surveyParticipantList = [
      SELECT Id
      FROM Survey_Participant__c
      WHERE
        Participant__r.Email IN (
          'test@test.com.invalid',
          'test@test.com.invalid2'
        )
    ];

    System.assert(
      surveyParticipantList.isEmpty(),
      'Survey Participant records should have been deleted'
    );
  }
}