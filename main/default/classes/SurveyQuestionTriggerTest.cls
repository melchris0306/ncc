@isTest
public with sharing class SurveyQuestionTriggerTest {
    
    @TestSetup
    static void makeData(){
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c newCampaign = TestFactory.createEvent('Test Event');
        Survey__c newSurvey = TestFactory.createSurvey(newCampaign.Id, 'Test Survey');
        Survey_Question__c sq = TestFactory.createSurveyQuestion(newSurvey.Id, 'What is your name?', 'Text', 1);
    }

    // Test creating survey question with existing order
    @isTest
    public static void testCreateSurveyQuestionWithExistingOrder(){
        Survey__c sv = [SELECT Id FROM Survey__c WHERE Name = 'Test Survey'];
        Test.startTest();
        try{
            Survey_Question__c newSQ = TestFactory.createSurveyQuestion(sv.Id, 'How old are you?', 'Text', 1);
        } catch(DmlException e){
            System.assertEquals(true, e.getMessage().contains('Another question in this survey already has this order, please enter another order'));
        }
        Test.stopTest();
    }

    // Test updating survey question with existing order
    @isTest
    public static void testUpdateSurveyQuestionWithExistingOrder(){
        Survey__c sv = [SELECT Id FROM Survey__c WHERE Name = 'Test Survey'];
        Survey_Question__c sq = TestFactory.createSurveyQuestion(sv.Id, 'Where do you live?', 'Text', 2);
        Test.startTest();
        try{
            sq.Sorting_Order__c = 1;
            update sq;
        } catch(DmlException e){
            System.assertEquals(true, e.getMessage().contains('Another question in this survey already has this order, please enter another order'));
        }
        Test.stopTest();
    }
}