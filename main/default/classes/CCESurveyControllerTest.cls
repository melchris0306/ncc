@isTest
private with sharing class CCESurveyControllerTest {
	private final static String SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME = 'Test Survey With Event With No Selected Fields';
    private final static String SURVEY_WITH_EVENT_WITH_FIELDS_NAME = 'Test Survey With Event With Selected Fields';
	private final static String SURVEY_WITHOUT_EVENT_WITH_NO_FIELDS_NAME = 'Test Survey Without Event With No Selected Fields';
    private final static String SURVEY_WITHOUT_EVENT_WITH_FIELDS_NAME = 'Test Survey Without Event With Selected Fields';
    private final static String JSON_FOR_WITH_EVENT_SURVEY = '{"Contact|FirstName":true,"Contact|LastName":true,"Contact|Email":true,"Contact|Facility__c":false,"Contact|Contact_Type__c":false,"Survey_Response__c|Session__c":true}';
	private final static String JSON_FOR_WITHOUT_EVENT_SURVEY = '{"Contact|FirstName":true,"Contact|LastName":true,"Contact|Email":true}';
    
    @TestSetup
    static void makeData(){
        
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        System.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = e.Id;
        setting.Email_Template_Registration_Id__c = e.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
        
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;

        Event__c newCampaign = TestFactory.createEvent('Test Campaign');
        Event__c newCampaign1 = TestFactory.createEvent('Test Campaign 2');

        Survey__c newSurvey1 = TestFactory.createSurvey(newCampaign.Id, SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME);
        newSurvey1.Survey_Code__c = '0001';
        update newSurvey1;
        TestFactory.createSurveyQuestion(newSurvey1.Id, 'What is your name?', 'Text', 1);

        Survey__c newSurvey2 = TestFactory.createSurvey(newCampaign1.Id, SURVEY_WITH_EVENT_WITH_FIELDS_NAME);
        newSurvey2.Survey_Code__c = '0002';
        update newSurvey2;
        TestFactory.createSurveyQuestion(newSurvey2.Id, 'What is your name?', 'Text', 1);
        newSurvey2.Survey_Fields_JSON__c = JSON_FOR_WITH_EVENT_SURVEY;
        
        Survey__c newSurvey3 = TestFactory.createSurvey(null, SURVEY_WITHOUT_EVENT_WITH_NO_FIELDS_NAME);
        newSurvey3.Survey_Code__c = '0003';
        update newSurvey3;
        TestFactory.createSurveyQuestion(newSurvey3.Id, 'What is your name?', 'Text', 1);
        
        Survey__c newSurvey4 = TestFactory.createSurvey(null, SURVEY_WITHOUT_EVENT_WITH_FIELDS_NAME);
        newSurvey4.Survey_Code__c = '0004';
        update newSurvey4;
		TestFactory.createSurveyQuestion(newSurvey4.Id, 'What is your name?', 'Text', 1);
        newSurvey4.Survey_Fields_JSON__c = JSON_FOR_WITHOUT_EVENT_SURVEY;
        newSurvey4.Campaign_Logo_URL__c = 'TestURLLogo';
        update new List<Survey__c>{newSurvey2, newSurvey4};
            
        Event__c event = TestFactory.createEvent('Test Event');
        event.Email_Sender_Id__c = owea.Id;
        update event;
            
        TestFactory.createSession('Test Session 1', newCampaign.Id);

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact newContact = new Contact();
        newContact.FirstName = 'Test FirstName';
        newContact.LastName = 'Test LastName';
        newContact.Email = 'testContactEmail@testing.com';
        newContact.AccountId = acc.Id;

        insert newContact;

        //Standalone Survey Participant
        Survey_Participant__c newParticipant = new Survey_Participant__c();
        newParticipant.Participant__c = newContact.Id;
        newParticipant.Survey__c = newSurvey1.Id;
        insert newParticipant;
        
        //Event Survey Participant
        Participant__c participant = new Participant__c();
        participant.Status__c = 'Invited';
        participant.Member_Contact__c = newContact.Id;
        participant.Event__c = event.Id;
        
        insert participant;
    }

    // Test retrieving a survey with an existing record
    @isTest
    private static void getSurvey_shouldReturnResult_whenProvidedValidSurveyCode(){

        Survey__c sv = [SELECT Id, Name, Survey_Campaign__c, 
                        Event__r.Event_Id__c, Survey_Code__c, (SELECT Id, Description__c, Question_Type__c, Min_Value__c, Max_Value__c, Step__c, Options__c FROM Survey_Questions__r ORDER BY Sorting_Order__c)
                        FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_FIELDS_NAME LIMIT 1];

        Test.startTest();
        String result = CCESurveyController.getSurvey(sv.Event__r.Event_Id__c);
        Test.stopTest();

        CCESurveyControllerHelper.SurveyWrapper sw = new CCESurveyControllerHelper.SurveyWrapper();
        CCESurveyControllerHelper.SurveyWrapper resultObj = (CCESurveyControllerHelper.SurveyWrapper)JSON.deserialize(result, CCESurveyControllerHelper.SurveyWrapper.class);
        System.assertEquals(sv.Name, resultObj.Survey.Name);
        System.assertEquals(sv.Survey_Questions__r[0].Description__c, resultObj.Survey.SurveyQuestionList[0].Description);
        System.assertEquals(sv.Survey_Questions__r[0].Question_Type__c, resultObj.Survey.SurveyQuestionList[0].QuestionType);
    }
    
    @isTest
    private static void getSurveyWithRecord_shouldNotReturnesult_whenCodeIsBlank(){

        Test.startTest();
        String result = CCESurveyController.getSurvey('');
        Test.stopTest();

        System.assert(String.isBlank(result), 'Result String should be blank');
    }

    // Test retrieving a survey without an existing record
    @isTest
    private static void testGetSurveyWithoutRecord(){
        final String FAKE_ID = TestFactory.getRecordFakeId(Survey__c.sObjectType.getDescribe().getSobjectType());

        Test.startTest();
        String result = CCESurveyController.getSurvey(FAKE_ID);
        Test.stopTest();

        System.assert(String.isBlank(result), 'Result should not have been returned');
    }

    // Test retrieving a survey using survey code
    @isTest
    private static void testGetSurveyUsingSurveyCode(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c FROM Survey__c WHERE Event__c = '' LIMIT 1];
        
        Test.startTest();
        String result = CCESurveyController.getSurvey(surveyRecord.Survey_Code__c);
        Test.stopTest();

        //System.assert(String.isNotBlank(result), 'Result should have been returned');
    }

    @isTest
    private static void testGetParticipantDetails_EventSurveyWithValidEmail(){
        Participant__c participant = [SELECT Name FROM Participant__c LIMIT 1];
        
        Test.startTest();
        Contact con = CCESurveyController.getParticipantDetails(participant.Name, 'testContactEmail@testing.com', false);
        Test.stopTest();
        
        System.assertNotEquals(null, con, 'Contact should have been returned');
    }
    
    @isTest
    private static void testGetParticipantDetails_EventSurveyWithInvalidEmail(){
        Participant__c participant = [SELECT Name FROM Participant__c LIMIT 1];
        
        Test.startTest();
        Contact con = CCESurveyController.getParticipantDetails(participant.Name, 'testContactEmail1@testing.com', false);
        Test.stopTest();
        
        System.assertEquals(null, con, 'Contact should not have been returned');
    }
    
    // Test creating response with an existing contact
    @isTest
    private static void testCreateResponseWithExistingContact(){
        Contact c = TestFactory.createContact('John', 'Doe', 'john.doe@gmail.com');
        Survey__c sv = [SELECT Id, Event__r.Event_Id__c FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_FIELDS_NAME];
        Survey_Question__c sq = TestFactory.createSurveyQuestion(sv.Id, 'Question Description', 'Text', 12);
        Session__c sessionRec = [SELECT Id FROM Session__c LIMIT 1];
        String contactStr = '{"Contact|FirstName":"John","Contact|LastName":"Doe","Contact|Email":"john.doe@gmail.com","Survey_Response__c|Session__c":"'+ sessionRec.Id +'"}';
        String resultStr = '{"' + sq.Id + '":{"Question":"Select a value between 1 to 5","Answer":"4"}}';
        Event__c cp = [SELECT Id FROM Event__c WHERE Name = 'Test Campaign'];

        Test.startTest();
        CCESurveyController.createResponse(sv.Event__r.Event_Id__c, contactStr, resultStr, '', false);
        Test.stopTest();

        List<Survey_Response__c> srList = [SELECT Id, Contact__c, (SELECT Survey_Question__c, Question__c, Answer__c FROM Survey_Answers__r) FROM Survey_Response__c];
        System.assertEquals(srList[0].Contact__c, c.Id);
    }
    
    // Test creating response with a new contact
    @isTest
    private static void testCreateResponseWithNewContact(){
        Survey__c sv = [SELECT Id, Survey_Code__c FROM Survey__c WHERE Name = :SURVEY_WITHOUT_EVENT_WITH_NO_FIELDS_NAME];
        Survey_Question__c sq = TestFactory.createSurveyQuestion(sv.Id, 'Question Description', 'Text', 10);
        String contactStr = '{"Contact|FirstName":"Jane","Contact|LastName":"Doe","Contact|Email":"jane.doe@gmail.com"}';
        String resultStr = '{"' + sq.Id + '":{"Question":"Select a value between 1 to 5","Answer":"4"}}';
        Event__c cp = [SELECT Id FROM Event__c WHERE Name = 'Test Campaign'];

        Test.startTest();
        CCESurveyController.createResponse(sv.Survey_Code__c, contactStr, resultStr, '', false);
        Test.stopTest();

        //Contact testContact = [SELECT Id FROM Contact WHERE Email = 'jane.doe@gmail.com' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'testContactEmail@testing.com' LIMIT 1];
        List<Survey_Response__c> srList = [SELECT Id, Contact__c, (SELECT Survey_Question__c, Question__c, Answer__c FROM Survey_Answers__r) FROM Survey_Response__c];
        System.assertEquals(srList[0].Contact__c != null, true);
        //System.assertEquals(srList[0].Contact__c, testContact.Id);
    }

    // Test creating response with exception thrown
    @isTest
    private static void testCreateResponseWithException(){
        String contactStr = '{"Contact|FirstName":"John","Contact|LastName":"Doe","Contact|Email":"john.doe@gmail.com"}';
        String resultStr = '{"a1U5B000000VhelUAC":{"Question":"Select a value between 1 to 5","Answer":"4"}}';
        Survey__c sv = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME];
        Event__c cp = [SELECT Id FROM Event__c LIMIT 1];
        CCESurveyControllerHelper.throwFakeException = true;
        Test.startTest();
        try{
            CCESurveyController.createResponse(sv.Id, contactStr, resultStr, '', false);
        } catch(Exception e){
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testCreateResponseWithMissingRequiredField(){
        Contact c = TestFactory.createContact('John', 'Doe', 'john.doe@gmail.com');
        Survey__c sv = [SELECT Id, Event__r.Event_Id__c FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME];
        Survey_Question__c sq = TestFactory.createSurveyQuestion(sv.Id, 'Question Description', 'Text', 12);
        String contactStr = '{"Contact|FirstName":"John","Contact|LastName":"Doe","Contact|Email":"john.doe@gmail.com"}';
        String resultStr = '{"' + sq.Id + '":{"Question":"Select a value between 1 to 5","Answer":"4"}}';

        Test.startTest();
        AuraHandledException exc;
        
        try{
            CCESurveyController.createResponse('', contactStr, resultStr, '', false);
        } catch(AuraHandledException e){
            exc = e;
        }
        
        Test.stopTest();

        System.assertNotEquals(null, exc, 'Exception should have been thrown');
    }

    // Test retrieving survey answers with result
    @isTest
    private static void testGetSurveyAnswersWithResult(){
        Event__c cp = [SELECT Id FROM Event__c LIMIT 1];
        Survey__c sv = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME];
        Account a = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Survey_Response__c testSR = TestFactory.createSurveyResponse(cp.Id, sv.Id, a.Id);
        String result = CCESurveyController.getSurveyAnswers(testSR.Id);
        Test.stopTest();

        List<Survey_Answer__c> saList = (List<Survey_Answer__c>)JSON.deserialize(result, List<Survey_Answer__c>.class);
        System.assertEquals(1, saList.size());
    }
    
    // Test retrieving content version with result
    @isTest
    private static void testGetContentVersionDataWithResult(){
        ContentVersion cv = new ContentVersion();
        cv.Description = 'Test Content Version';
        cv.Title = 'Test Content Version';
        cv.PathOnClient ='test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.VersionData = EncodingUtil.base64Decode('U29tZSBDb250ZW50');
        insert cv;

        CCESurveyControllerHelper.BlobWrapper bw = new CCESurveyControllerHelper.BlobWrapper();

        Test.startTest();
        bw = CCESurveyControllerHelper.getContentVersionData(cv.Id);
        Test.stopTest();

        System.assertEquals('U29tZSBDb250ZW50', bw.VersionData);
    }
    
    // Test retrieving content version without result
    @isTest
    private static void testGetContentVersionDataWithoutResult(){
        CCESurveyControllerHelper.BlobWrapper bw = new CCESurveyControllerHelper.BlobWrapper();

        Test.startTest();
        bw = CCESurveyControllerHelper.getContentVersionData('somerandomID');
        Test.stopTest();

        System.assertEquals(null, bw);
    }
    
    @isTest
    private static void getSurveyFieldConfiguration_shouldReturnResultForSurveyWithEvent_whenValidSurveyCodeGiven(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c, Event__r.Event_Id__c FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_FIELDS_NAME];
		
        CCESurveyControllerHelper.mockFieldConfiguration = setMockFieldConfigValues(true);
        
        Test.startTest();
        String surveyFieldString = CCESurveyController.getSurveyFieldConfiguration(surveyRecord.Event__r.Event_Id__c);
        Test.stopTest();

        List<SurveyFields> surveyFields = (List<SurveyFields>) JSON.deserialize(surveyFieldString, List<SurveyFields>.class);
        System.assert(!surveyFields.isEmpty(), 'Field Configuration for survey should have been returned');
    }
    
    @isTest
    private static void getSurveyFieldConfiguration_shouldNotReturnResultForSurveyWithEvent_whenNoFieldIsSelectedForDisplay(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c, Event__r.Event_Id__c FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_WITH_NO_FIELDS_NAME];
		
        CCESurveyControllerHelper.mockFieldConfiguration = setMockFieldConfigValues(true);
        
        Test.startTest();
        String surveyFieldString = CCESurveyController.getSurveyFieldConfiguration(surveyRecord.Event__r.Event_Id__c);
        Test.stopTest();
        
        List<SurveyFields> surveyFields = (List<SurveyFields>) JSON.deserialize(surveyFieldString, List<SurveyFields>.class);
        System.assert(surveyFields.isEmpty(), 'Field Configuration for survey should have not been returned');
    }
    
    @isTest
    private static void getSurveyFieldConfiguration_shouldReturnResultForSurveyWithoutEvent_whenValidSurveyCodeGiven(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c, Event__r.Event_Id__c FROM Survey__c WHERE Name = :SURVEY_WITHOUT_EVENT_WITH_FIELDS_NAME];
		
        CCESurveyControllerHelper.mockFieldConfiguration = setMockFieldConfigValues(false);
        
        Test.startTest();
        String surveyFieldString = CCESurveyController.getSurveyFieldConfiguration(surveyRecord.Survey_Code__c);
        Test.stopTest();

        List<SurveyFields> surveyFields = (List<SurveyFields>) JSON.deserialize(surveyFieldString, List<SurveyFields>.class);
        System.assert(!surveyFields.isEmpty(), 'Field Configuration for survey should have been returned');
    }
    
    @isTest
    private static void getSurveyFieldConfiguration_shouldNotReturnResultForSurveyWithoutEvent_whenNoFieldIsSelectedForDisplay(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c FROM Survey__c WHERE Name = :SURVEY_WITHOUT_EVENT_WITH_NO_FIELDS_NAME];
		
        CCESurveyControllerHelper.mockFieldConfiguration = setMockFieldConfigValues(false);
        
        Test.startTest();
        String surveyFieldString = CCESurveyController.getSurveyFieldConfiguration(surveyRecord.Survey_Code__c);
        Test.stopTest();
        
        List<SurveyFields> surveyFields = (List<SurveyFields>) JSON.deserialize(surveyFieldString, List<SurveyFields>.class);
        System.assert(surveyFields.isEmpty(), 'Field Configuration for survey should have not been returned');
    }
    
    @isTest
    private static void getSurveyFieldConfiguration_shouldNotReturnResultForSurvey_whenSurveyCodeProvided(){
        Test.startTest();
        final String SURVEY_FIELD_STRING = CCESurveyController.getSurveyFieldConfiguration('');
        Test.stopTest();
        
        System.assert(String.isBlank(SURVEY_FIELD_STRING), 'Field Configuration for survey should have not been returned');
    }

    @isTest
    private static void getSurveyLogo_shouldReturnString_whenSurveyCodeProvided(){
        Survey__c surveyRecord = [SELECT Id, Survey_Code__c FROM Survey__c WHERE Name = :SURVEY_WITHOUT_EVENT_WITH_FIELDS_NAME];

        Test.startTest();
        final String SURVEY_LOGO_STRING = CCESurveyController.getSurveyLogo(surveyRecord.Survey_Code__c);
        Test.stopTest();
        
        //System.assert(String.isNotBlank(SURVEY_LOGO_STRING), 'Logo URL should have been returned');
    }

    @isTest
    private static void getSurveyLogo_shouldReturnNotString_whenSurveyCodeNotProvided(){
        Test.startTest();
        final String SURVEY_LOGO_STRING = CCESurveyController.getSurveyLogo('');
        Test.stopTest();
        
        System.assert(String.isBlank(SURVEY_LOGO_STRING), 'Logo URL should have not been returned');
    }
    
    //sets mock metadata records to avoid dependency on actual metadata records
    private static List<Survey_Field_Configuration__mdt> setMockFieldConfigValues(Boolean isForEvent){
        List<Survey_Field_Configuration__mdt> surveyFieldConfig = new List<Survey_Field_Configuration__mdt>();
        surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 1, Label = 'First Name', Column__c = 'Left', Object_API_Name__c = 'Contact', 
                                                                  Field_API_Name__c = 'FirstName', Form_Field_Type__c = 'Text', Actual_Field_Type__c = 'Text',
                                                                  Message_when_Required__c = 'First Name is required'));
        surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 2, Label = 'Last Name', Column__c = 'Left', Object_API_Name__c = 'Contact', 
                                                                  Field_API_Name__c = 'LastName', Form_Field_Type__c = 'Text', Actual_Field_Type__c = 'Text',
                                                                  Message_when_Required__c = 'Last Name is required'));
        surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 3, Label = 'Email', Column__c = 'Left', Object_API_Name__c = 'Contact', 
                                                                  Field_API_Name__c = 'Email', Form_Field_Type__c = 'Text', Actual_Field_Type__c = 'Text',
                                                                  Message_when_Required__c = 'Email is required'));
        surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 4, Label = 'Facility', Column__c = 'Right', Object_API_Name__c = 'Contact', 
                                                                  Field_API_Name__c = 'Facility__c', Form_Field_Type__c = 'Text', Actual_Field_Type__c = 'Text',
                                                                  Message_when_Required__c = 'Facility is required'));
        
        if (isForEvent){
        	surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 5, Label = 'Session', Column__c = 'Right', Object_API_Name__c = 'Survey_Response__c', 
                                                                  Field_API_Name__c = 'Session__c', Form_Field_Type__c = 'Picklist', Actual_Field_Type__c = 'Lookup',
                                                                  Message_when_Required__c = 'Session is required'));
            //generic picklist test
            surveyFieldConfig.add(new Survey_Field_Configuration__mdt(Order__c = 6, Label = 'Contact Type', Column__c = 'Right', Object_API_Name__c = 'Contact', 
                                                                  Field_API_Name__c = 'Contact_Type__c', Form_Field_Type__c = 'Picklist', Actual_Field_Type__c = 'Picklist',
                                                                  Message_when_Required__c = 'Contact Type is required'));   
        }
        
        return surveyFieldConfig;
    }
}