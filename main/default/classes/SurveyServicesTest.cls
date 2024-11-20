@isTest
private class SurveyServicesTest {
  @testSetup
  static void setup() {
    String alias = 'tstSysAd';
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User sysad = new User(
      Username = alias + '@Test.com',
      Alias = alias,
      CommunityNickname = alias,
      TimeZoneSidKey = 'America/Chicago',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      LanguageLocaleKey = 'en_US',
      FirstName = alias,
      LastName = alias,
      Email = alias + '@Test.com',
      ProfileId = profile.Id,
      Department = 'Test'
    );
    insert sysad;

    System.runAs(sysad) {
      Campaign__c campaignRec = new Campaign__c();
      insert campaignRec;
      
      Compass_Setting__c comp = TestDataFactory.createCSData(1);
      insert comp;
      
      Event__c newEvent = new Event__c();
      newEvent.Name = 'TestEventName';
      newEvent.Campaign__c = campaignRec.Id;
      insert newEvent;

      //create Survey__c
      Survey__c oldSurvey = new Survey__c(
        Name = 'TestSurveyName',
        Active__c = true,
        Disclaimer__c = 'TEST DISCLAIMER',
        Event__c = newEvent.Id
      );
      insert oldSurvey;

      List<Survey_Question__c> oldSurveyQuestions = new List<Survey_Question__c>();
      Survey_Question__c question1 = new Survey_Question__c(
        Question_Type__c = 'Text',
        Description__c = 'Question Number 1',
        Sorting_Order__c = 1,
        Survey__c = oldSurvey.Id
      );
      Survey_Question__c question2 = new Survey_Question__c(
        Question_Type__c = 'Range',
        Description__c = 'Question Number 2',
        Sorting_Order__c = 2,
        Min_Value__c = 1,
        Max_Value__c = 10,
        Step__c = 1,
        Survey__c = oldSurvey.Id
      );
      Survey_Question__c question3 = new Survey_Question__c(
        Question_Type__c = 'Radio',
        Description__c = 'Question Number 3',
        Sorting_Order__c = 3,
        Options__c = 'Option 1\nOption 2\nOption 3\nOption 4',
        Survey__c = oldSurvey.Id
      );
      Survey_Question__c question4 = new Survey_Question__c(
        Question_Type__c = 'Picklist',
        Description__c = 'Question Number 4',
        Sorting_Order__c = 4,
        Options__c = 'Option 1\nOption 2\nOption 3\nOption 4',
        Survey__c = oldSurvey.Id
      );
      oldSurveyQuestions.add(question1);
      oldSurveyQuestions.add(question2);
      oldSurveyQuestions.add(question3);
      oldSurveyQuestions.add(question4);

      insert oldSurveyQuestions;
    }
  }

  //happy path test for SurveyServices.getSurveyDetails()
  static testMethod void test_getSurveyDetails_positive() {
    List<Survey__c> existingSurveys = [
      SELECT
        Id,
        Name,
        Active__c,
        Survey_Campaign__c,
        Disclaimer__c,
        Event__c,
        Logo_Image_Id__c,
        OwnerId,
        Survey_Logo__c,
        Survey_Logo_URL__c,
        (
          SELECT
            Id,
            Name,
            Description__c,
            Max_Value__c,
            Min_Value__c,
            Options__c,
            Question_Type__c,
            Sorting_Order__c,
            Step__c,
            Survey__c
          FROM Survey_Questions__r
        )
      FROM Survey__c
    ];
    Test.startTest();
    Map<String, Object> response = SurveyServices.getSurveyDetails(
      existingSurveys[0].Id
    );
    Test.stopTest();

    System.assertEquals(
      existingSurveys[0].Id,
      ((Survey__c) response.get('data')).Id
    );
  }

  //happy path test for SurveyServices.cloneSurvey()
  static testMethod void test_cloneSurvey_positive() {
    //retrieve sample records
    List<Survey__c> existingSurveys = [
      SELECT
        Id,
        Name,
        Active__c,
        Survey_Campaign__c,
        Disclaimer__c,
        Event__c,
        Logo_Image_Id__c,
        OwnerId,
        Survey_Logo__c,
        Survey_Logo_URL__c,
        (
          SELECT
            Id,
            Name,
            Description__c,
            Max_Value__c,
            Min_Value__c,
            Options__c,
            Question_Type__c,
            Sorting_Order__c,
            Step__c,
            Survey__c
          FROM Survey_Questions__r
        )
      FROM Survey__c
    ];

    Test.startTest();
    Survey__c surveyToClone = existingSurveys[0].clone(false, true);
    surveyToClone.Name = 'Copy of ' + surveyToClone.Name;
    surveyToClone.Active__c = false;
    String message = SurveyServices.cloneSurvey(
      existingSurveys[0].Id,
      surveyToClone,
      false,
      false
    );
    System.debug(message);
    Test.stopTest();

    List<Survey__c> afterCloning = [
      SELECT
        Id,
        Name,
        Active__c,
        Survey_Campaign__c,
        Disclaimer__c,
        Event__c,
        Logo_Image_Id__c,
        OwnerId,
        Survey_Logo__c,
        Survey_Logo_URL__c,
        (
          SELECT
            Id,
            Name,
            Description__c,
            Max_Value__c,
            Min_Value__c,
            Options__c,
            Question_Type__c,
            Sorting_Order__c,
            Step__c,
            Survey__c
          FROM Survey_Questions__r
        )
      FROM Survey__c
    ];

    System.assertEquals(2, afterCloning.size());
    System.assertEquals(surveyToClone.Name, afterCloning[1].Name);
    System.assertEquals(
      true,
      message.contains(SurveyServices.CLONED_SUCCESS_MESSAGE)
    );
  }

  //happy path test for SurveyServices.cloneSurvey()
  static testMethod void test_cloneSurvey_negative1() {
    //retrieve sample records
    List<Survey__c> existingSurveys = [
      SELECT
        Id,
        Name,
        Active__c,
        Survey_Campaign__c,
        Disclaimer__c,
        Event__c,
        Logo_Image_Id__c,
        OwnerId, //Milestone__c,
        Survey_Logo__c,
        Survey_Logo_URL__c,
        (
          SELECT
            Id,
            Name,
            Description__c,
            Max_Value__c,
            Min_Value__c,
            Options__c,
            Question_Type__c,
            Sorting_Order__c,
            Step__c,
            Survey__c
          FROM Survey_Questions__r
        )
      FROM Survey__c
    ];

    Test.startTest();
    Survey__c surveyToClone = existingSurveys[0];
    String message = SurveyServices.cloneSurvey(
      surveyToClone.Id,
      surveyToClone,
      true,
      true
    );
    Test.stopTest();

    List<Survey__c> afterCloning = [
      SELECT
        Id,
        Name,
        Active__c,
        Survey_Campaign__c,
        Disclaimer__c,
        Event__c,
        Logo_Image_Id__c,
        OwnerId, //Milestone__c,
        Survey_Logo__c,
        Survey_Logo_URL__c,
        (
          SELECT
            Id,
            Name,
            Description__c,
            Max_Value__c,
            Min_Value__c,
            Options__c,
            Question_Type__c,
            Sorting_Order__c,
            Step__c,
            Survey__c
          FROM Survey_Questions__r
        )
      FROM Survey__c
    ];

    //System.assertEquals(false, message.contains('Insert failed.'));
  }

  //happy path test for SurveyServices.test_getObjectAndFieldPrefix()
  static testMethod void test_fetchObjectAndFieldPrefix() {
    Test.startTest();
    SurveyServices.PrefixObjectAndFieldWrapper wrapper = SurveyServices.fetchObjectAndFieldPrefix();

    System.assert(String.isBlank(wrapper.errorMsg));
    Test.stopTest();
  }
}