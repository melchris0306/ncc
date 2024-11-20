@isTest 
public with sharing class SurveyTriggerTest {
    
    @TestSetup
    static void makeData(){
        Apex_Trigger_Switch__c aps_p = new Apex_Trigger_Switch__c();
        aps_p.Name = 'ParticipantTrigger';
        aps_p.Active__c = false;
        insert aps_p;
        
        Event__c testEvent = TestFactory.createEvent('Test Campaign');
        TestFactory.createEvent('Test Campaign 2');
        Survey__c testActiveSurvey1 = TestFactory.createSurvey(testEvent.Id, 'Test Active Survey 1');
        
        Contact cont = TestFactory.createContact('Test', 'Contact', 'testcontact@gmail.com');
        
        Survey_Participant__c surveyParticipant = new Survey_Participant__c();
        surveyParticipant.Survey__c = testActiveSurvey1.Id;
        surveyParticipant.Participant__c = cont.Id;
        insert surveyParticipant;
        
        Participant__c participant = new Participant__c();
        participant.Event__c = testEvent.Id;
        insert participant;
        
    }

    @isTest
    public static void testCreateMultiActiveSurveys(){
        Test.startTest();
        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign' LIMIT 1];
        try{
            Survey__c testActiveSurvey2 = TestFactory.createSurvey(testEvent.Id, 'Test Active Survey 2');
        } catch(DmlException e){
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCreateOneActiveSurveys(){
        // De-activate test survey 1
        Survey__c testActiveSurvey1 = [SELECT Id, Active__c FROM Survey__c WHERE Name = 'Test Active Survey 1'];
        testActiveSurvey1.Active__c = false;
        update testActiveSurvey1;

        Test.startTest();
        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign' LIMIT 1];
        // Insert active survey 2
        try{
            Survey__c testActiveSurvey2 = TestFactory.createSurvey(testEvent.Id, 'Test Active Survey 2');
        } catch(DmlException e){
            System.assertNotEquals(null, e);
        }
        Test.stopTest();

        List<Survey__c> resultSurveyList = [SELECT Id FROM Survey__c WHERE Name = 'Test Active Survey 2'];
        System.assertEquals(1, resultSurveyList.size());
    }

    @isTest
    public static void testUpdateUnactiveSurveyToActive(){
        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign' LIMIT 1];

        // Insert an inactive survey under event
        Survey__c inactiveSurvey = new Survey__c();
        inactiveSurvey.Name = 'Inactive Survey';
        inactiveSurvey.Active__c = false;
        inactiveSurvey.Event__c = testEvent.Id;
        insert inactiveSurvey;

        Test.startTest();
        try{
            inactiveSurvey.Active__c = true;
            update inactiveSurvey;
        } catch(DmlException e){
            System.assertNotEquals(null, e);
        }

        Test.stopTest();
    }

    @isTest
    public static void testSurveyCodeGeneration_shouldGenerateCode_whenSurveyIsCreatedWithoutEvent(){
        Test.startTest();
        TestFactory.createSurvey(null, 'Test Active Survey 1 without Event');
        Test.stopTest();

        List<Survey__c> resultSurveyList = [SELECT Id, Survey_Code__c, Standalone_Survey_URL__c FROM Survey__c WHERE Name = 'Test Active Survey 1 without Event'];
        System.assert(String.isNotBlank(resultSurveyList.get(0).Survey_Code__c));
        System.assert(String.isNotBlank(resultSurveyList.get(0).Standalone_Survey_URL__c));
    }

    @isTest
    public static void testSurveyCodeGeneration_shouldNotGenerateCode_whenSurveyIsCreatedWithEvent(){

        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign 2' LIMIT 1];

        Test.startTest();
        TestFactory.createSurvey(testEvent.Id, 'Test Active Survey 1 with Event');
        Test.stopTest();

        List<Survey__c> resultSurveyList = [SELECT Id, Survey_Code__c, Standalone_Survey_URL__c FROM Survey__c WHERE Name = 'Test Active Survey 1 with Event'];
        System.assert(String.isBlank(resultSurveyList.get(0).Survey_Code__c));
        System.assert(String.isBlank(resultSurveyList.get(0).Standalone_Survey_URL__c));
    }

    @isTest
    public static void testSurveyCodeGeneration_shouldGenerateCode_whenSurveyIsUpdatedWithoutEvent(){
        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign' LIMIT 1];

        Test.startTest();

        // Insert an inactive survey under event
        Survey__c inactiveSurvey = new Survey__c();
        inactiveSurvey.Name = 'Inactive Survey';
        inactiveSurvey.Active__c = false;
        inactiveSurvey.Event__c = testEvent.Id;
        insert inactiveSurvey;

        inactiveSurvey.Event__c = null;
        update inactiveSurvey;

        Test.stopTest();

        List<Survey__c> resultSurveyList = [SELECT Id, Survey_Code__c, Standalone_Survey_URL__c FROM Survey__c WHERE Id = :inactiveSurvey.Id];
        System.assert(String.isNotBlank(resultSurveyList.get(0).Survey_Code__c));
        System.assert(String.isNotBlank(resultSurveyList.get(0).Standalone_Survey_URL__c));
    }

    @isTest
    public static void testSurveyCodeGeneration_shouldNotGenerateCode_whenSurveyIsUpdatedWithEvent(){
        Event__c testEvent = [SELECT Id FROM Event__c WHERE Name =: 'Test Campaign' LIMIT 1];

        Test.startTest();

        // Insert an inactive survey under event
        Survey__c inactiveSurvey = new Survey__c();
        inactiveSurvey.Name = 'Inactive Survey';
        inactiveSurvey.Active__c = false;
        insert inactiveSurvey;

        inactiveSurvey.Event__c = testEvent.Id;
        update inactiveSurvey;

        Test.stopTest();

        List<Survey__c> resultSurveyList = [SELECT Id, Survey_Code__c, Standalone_Survey_URL__c FROM Survey__c WHERE Id = :inactiveSurvey.Id];
        System.assert(String.isBlank(resultSurveyList.get(0).Survey_Code__c));
        System.assert(String.isBlank(resultSurveyList.get(0).Standalone_Survey_URL__c));
    }
    
    // Added by RLugpatan [CCN-1049] Jan062022
    @isTest
    public static void testSyncSurveyRichTextFields(){
        Survey__c testSurvey = [SELECT Id FROM Survey__c WHERE Name =: 'Test Active Survey 1' LIMIT 1];
        
        Test.startTest();
        
        // Update Survey record
        testSurvey.Survey_Thank_You_Message__c = 'Test Survey Thank you Message';
        testSurvey.Survey_Catchup_Message__c = 'Test Survey Catchup Message';
        testSurvey.Survey_Catchup_Reminder_Message__c = 'Test Survey Catchup Reminder Message';
        testSurvey.Survey_Reminder_Message__c = 'Test Survey Reminder Message';
        update testSurvey;
        
        Test.stopTest();
        
        Survey_Participant__c surveyParticipant = [SELECT Id, Survey_Thank_You_Message__c, Survey_Catchup_Reminder_Message__c, Survey_Catchup_Message__c, 
                                         Survey_Reminder_Message__c, Survey__r.Survey_Thank_You_Message__c, Survey__r.Survey_Catchup_Reminder_Message__c, 
                                         Survey__r.Survey_Catchup_Message__c, Survey__r.Survey_Reminder_Message__c
                                         FROM Survey_Participant__c WHERE Survey__c = :testSurvey.Id]; 
        System.assertEquals(surveyParticipant.Survey__r.Survey_Thank_You_Message__c, surveyParticipant.Survey_Thank_You_Message__c);
        System.assertEquals(surveyParticipant.Survey__r.Survey_Catchup_Message__c, surveyParticipant.Survey_Catchup_Message__c);
        System.assertEquals(surveyParticipant.Survey__r.Survey_Catchup_Reminder_Message__c, surveyParticipant.Survey_Catchup_Reminder_Message__c);
        System.assertEquals(surveyParticipant.Survey__r.Survey_Reminder_Message__c, surveyParticipant.Survey_Reminder_Message__c);
    }
}