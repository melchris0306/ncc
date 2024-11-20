@isTest(IsParallel = true)
private class SurveyFieldPickerControllerTest {
    
    private final static String SURVEY_CODE = '546hgfh7456';
    private final static String JSON_FOR_WITH_EVENT_SURVEY = '{"Contact|FirstName":true,"Contact|LastName":true,"Contact|Email":true,"Contact|Facility__c":false,"Survey_Response__c|Session__c":true}';
	private final static String JSON_FOR_WITHOUT_EVENT_SURVEY = '{"Contact|FirstName":true,"Contact|LastName":true,"Contact|Email":true}';
	private final static String SURVEY_WITH_EVENT = 'Test Survey with Event';
    private final static String SURVEY_WITH_EVENT_NO_SELECTED_FIELDS = 'Test Survey with Event No Selected Survey Field';
    private final static String SURVEY_NO_EVENT = 'Test Survey No Event';
    
    @TestSetup
    private static void setupData(){
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c newCampaign = TestFactory.createEvent('Test Campaign');
        newCampaign.Event_Id__c = 'zhCoziiBzcb';
        update newCampaign;

        Event__c newCampaign2 = TestFactory.createEvent('Test Campaign2');
        newCampaign.Event_Id__c = 'zhCoziiBzcc';
        update newCampaign2;

        Survey__c newSurvey = TestFactory.createSurvey(newCampaign.Id, SURVEY_WITH_EVENT);
        newSurvey.Survey_Fields_JSON__c = JSON_FOR_WITH_EVENT_SURVEY;
        
        TestFactory.createSurvey(newCampaign2.Id, SURVEY_WITH_EVENT_NO_SELECTED_FIELDS);

        Survey__c newSurvey2 = TestFactory.createSurvey(null, SURVEY_NO_EVENT);
        newSurvey2.Survey_Code__c = SURVEY_CODE;
        newSurvey2.Survey_Fields_JSON__c = JSON_FOR_WITHOUT_EVENT_SURVEY;
        update new List<Survey__c>{newSurvey, newSurvey2};
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldReturnValuesFromMetadata_whenSurveyRecordIdIsProvidedAndNoSelectedFields(){
        Survey__c surveyRecord = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT_NO_SELECTED_FIELDS LIMIT 1];
        
        SurveyFieldPickerController.mockFieldConfiguration = setMockFieldConfigValues(true);
        
        Test.startTest();
        List<SurveyFields> surveyFieldList = SurveyFieldPickerController.getSurveyFieldsFromMetadata(surveyRecord.Id);
        Test.stopTest();
        
        System.assert(!surveyFieldList.isEmpty(), 'Survey Field from metadata should not return blank');
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldThrowExceptionWhileFetchingRecords_whenSurveyRecordIdIsInvalid(){   
        final String FAKE_ID = TestFactory.getRecordFakeId(Survey__c.sObjectType.getDescribe().getSobjectType());
        
        Test.startTest();
        AuraHandledException exc;
        
        try{
            List<SurveyFields> surveyFieldList = SurveyFieldPickerController.getSurveyFieldsFromMetadata(FAKE_ID);
        } catch(AuraHandledException e){
            exc = e;
        }
        
        System.assertNotEquals(null, exc, 'Exception expected');
        
        Test.stopTest();
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldReturnValuesFromSurveyJSONField_whenSurveyLinkedToEvent(){
        Survey__c surveyRecord = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_WITH_EVENT LIMIT 1];
        
        SurveyFieldPickerController.mockFieldConfiguration = setMockFieldConfigValues(true);
        
        Test.startTest();
        List<SurveyFields> surveyFieldList = SurveyFieldPickerController.getSurveyFieldsFromMetadata(surveyRecord.Id);
        Test.stopTest();
        
        System.assertEquals(5, surveyFieldList.size(), 'Survey Field from Survey JSON should have returned 5 results.');
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldReturnValuesFromSurveyJSONField_whenSurveyNotLinkedToEventAndNoFieldsSelected(){
        Survey__c surveyRecord = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_NO_EVENT LIMIT 1];
        
        SurveyFieldPickerController.mockFieldConfiguration = setMockFieldConfigValues(false);
        
        Test.startTest();
        List<SurveyFields> surveyFieldList = SurveyFieldPickerController.getSurveyFieldsFromMetadata(surveyRecord.Id);
        Test.stopTest();
        
        System.assert(!surveyFieldList.isEmpty(), 'Survey Field from Survey JSON should not return blank');
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldReturnValuesFromSurveyJSONField_whenSurveyNotLinkedToEventAndFieldsAreSelected(){
        Survey__c surveyRecord = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_NO_EVENT LIMIT 1];
        
        SurveyFieldPickerController.mockFieldConfiguration = setMockFieldConfigValues(false);
        
        Test.startTest();
        List<SurveyFields> surveyFieldList = SurveyFieldPickerController.getSurveyFieldsFromMetadata(surveyRecord.Id);
        Test.stopTest();
        
        System.assertEquals(4, surveyFieldList.size(), 'Survey Field from Survey JSON should have returned 4 results.');
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldSaveSurvey(){
        Survey__c surveyRecord = [SELECT Id FROM Survey__c WHERE Name = :SURVEY_NO_EVENT LIMIT 1];
   
        Test.startTest();
        SurveyFieldPickerController.saveSelectedFields(JSON_FOR_WITH_EVENT_SURVEY, surveyRecord.Id);
        Test.stopTest();
        
        surveyRecord = [SELECT Id, Survey_Fields_JSON__c FROM Survey__c WHERE Id = :surveyRecord.Id LIMIT 1];
        System.assertEquals(JSON_FOR_WITH_EVENT_SURVEY, surveyRecord.Survey_Fields_JSON__c, 'Survey Fields passed to be updated on the survey should have matched the one on the survey already');
    }
    
    @isTest
    private static void getSurveyFieldsFromMetadata_shouldThrowExceptionWhileSaving_whenSurveyRecordIdIsInvalid(){
        final String FAKE_ID = TestFactory.getRecordFakeId(Survey__c.sObjectType.getDescribe().getSobjectType());
        
        Test.startTest();
        AuraHandledException exc;
        
        try{
            SurveyFieldPickerController.saveSelectedFields(JSON_FOR_WITH_EVENT_SURVEY, FAKE_ID);
        } catch(AuraHandledException e){
            exc = e;
        }
        
        System.assertNotEquals(null, exc, 'Exception expected');
        
        Test.stopTest();
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
        }
                              
        return surveyFieldConfig;
    }
}