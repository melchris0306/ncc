/**
* Description: Test Class for CustomParkingLotFormHelper
* Author: Jester Cabantog
* Version: 1.0
* Last modified date: 12/16/2020
**/
@isTest (SeeAllData = false)
private class CustomParkingLotForm_Test {
    
    @testSetup 
    static void setUp() {
        TestFactory.ParkingLotTestDataFactory df = new TestFactory.ParkingLotTestDataFactory();
        df.make();
        df.persist();
    }
    
    @isTest
    static void getParkingLotDetailsTestNoSessionParticipant_shouldThrowException_whenWithContact(){
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test Con' LIMIT 1];
        Event__c evt = [SELECT Id, Event_Id__c FROM Event__c LIMIT 1];
        evt.Start_Date_Time__c = DateTime.now();
        evt.End_Date_Time__c=DateTime.now().AddDays(1);
        evt.IsActive__c = true;

        update evt;

        Test.startTest();
        try {
            String result = CustomParkingLotFormController.getParkingLotDetails(evt.Event_Id__c, con.Id , null);
        } catch(AuraHandledException e){
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        
        Test.stopTest();
    }

    @isTest
    static void getParkingLotDetailsTestNoSessionParticipant_shouldReturnResult_whenWithNoContact(){
        Event__c evt = [SELECT Id, Event_Id__c FROM Event__c LIMIT 1];
        String result;
        Test.startTest();
        try{
         result = CustomParkingLotFormController.getParkingLotDetails(evt.Event_Id__c, '', null);   
        }catch(exception e){
            
        }
        
        Test.stopTest();

        System.assert(String.isNotBlank(result), 'There should be a result');
    }
    
    @isTest
    static void getParkingLotDetailsTest_withNoContact(){
        OrgWideEmailAddress[] addresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test Con' LIMIT 1];
        Event__c evt = [SELECT Id, Event_Id__c, Email_Sender_Name__c FROM Event__c LIMIT 1];
        evt.Email_Sender_Name__c = addresses[0].DisplayName;
        evt.Email_Sender_Id__c = addresses[0].Id;
        update evt;
        Session__c sess = [SELECT Id FROM Session__c WHERE Event__c =: evt.Id];
        sess.Meeting_URL__c = 'test.teams.com/test';
        update sess;
        
        Session_Participant__c sesPart = new Session_Participant__c(
            Event__c = evt.Id,
            Session__c = sess.Id,
            Contact__c = con.Id
        );
        System.debug('@@@@@@ ' + [SELECT Id, Email_Sender_Name__c FROM Event__c WHERE Id =: sesPart.Event__c]);
        insert sesPart;
        String result;
        Test.startTest();
        try{
           result = CustomParkingLotFormController.getParkingLotDetails(evt.Event_Id__c, '', null); 
        }catch(exception e){
            
        }
        
        Test.stopTest();

        System.assert(String.isNotBlank(result), 'There should be a result');
    }
    
    @isTest
    static void getParkingLotDetailsTest_withContact(){
        OrgWideEmailAddress[] addresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test Con' LIMIT 1];
        Event__c evt = [SELECT Id, Event_Id__c, Email_Sender_Name__c FROM Event__c LIMIT 1];
        evt.Email_Sender_Name__c = addresses[0].DisplayName;
        evt.Email_Sender_Id__c = addresses[0].Id;
        update evt;
        Session__c sess = [SELECT Id FROM Session__c WHERE Event__c =: evt.Id];
        Session_Participant__c sesPart = new Session_Participant__c(
            Event__c = evt.Id,
            Session__c = sess.Id,
            Contact__c = con.Id
        );
        
        insert sesPart;
		String result;
        Test.startTest();
        try{
        result = CustomParkingLotFormController.getParkingLotDetails(evt.Event_Id__c, con.Id, null);
        }catch(exception e){
            
        }
        Test.stopTest();

        System.assert(String.isNotBlank(result), 'There should be a result');
    }
    
    @isTest
    static void createParkingLotTest(){
        String alias = 'tstSysAd';
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User sysad = new User(
            Username=alias+'@Test.com', Alias=alias, CommunityNickname=alias, TimeZoneSidKey='America/Chicago', 
            LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', LanguageLocaleKey='en_US',
            FirstName=alias, LastName=alias, Email=alias+'@Test.com', ProfileId=profile.Id, Department = 'Test');
        insert sysad;

        System.runAs(sysad) {
            Event__c evt = [SELECT Id, Event_Id__c FROM Event__c LIMIT 1];
            Session__c sess = [SELECT Id FROM Session__c WHERE Event__c =: evt.Id];

            Test.startTest();
                CustomParkingLotFormController.createParkingLot(evt.Id, sess.Id, 'test@test.com', '', 'Question', 'Issue', 'Workflow');
                CustomParkingLotFormController.createParkingLot(evt.Id, sess.Id, 'test2@test.com', '', 'Question', 'Issue', 'Workflow');
            Test.stopTest();

            List<Parking_Lot__c> results = [SELECT Id FROM Parking_Lot__c 
            WHERE Raised_By__r.Email = 'test@test.com' OR Raised_By__r.Email = 'test2@test.com'];

            System.assertEquals(2, results.size(), 'There should only be 2 results');
        }
    }
    
    @isTest
    static void updateParkingLotsTest(){
        Parking_Lot__c pl = [SELECT Id, Status__c FROM Parking_Lot__c LIMIT 1];

        Test.startTest();
        CustomParkingLotFormController.updateParkingLots('[{"'+ FLSUtils.prefix + 'Status__c":"Closed","Id":"' + pl.Id + '"}]');
        Test.stopTest();

        Parking_Lot__c result = [SELECT Id, Status__c FROM Parking_Lot__c WHERE Id = :pl.Id];
        System.assertNotEquals(pl.Status__c, result.Status__c, 'Status should already be updated');
    }

    @isTest
    static void updateParkingLotsStatusErrTest(){
        
        Parking_Lot__c pl = [SELECT Id FROM Parking_Lot__c LIMIT 1];
        try{
            Test.startTest();
            CustomParkingLotFormController.updateParkingLots('[{"Status__c":"err","Id":"'+pl.Id+'"}]');
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Script-thrown exception'), 'There should be an exception');
        }
    }
    
    @isTest
    static void updateParkingLotsTypeErrTest(){
        Parking_Lot__c pl = [SELECT Id FROM Parking_Lot__c LIMIT 1];
        try{
            Test.startTest();
            CustomParkingLotFormController.updateParkingLots('[{"Type__c":"err","Id":"'+pl.Id+'"}]');
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Script-thrown exception'), 'There should be an exception');
        }
    }
    
    @isTest
    static void updateParkingLotsDmlErrTest(){
        Parking_Lot__c pl = [SELECT Id FROM Parking_Lot__c LIMIT 1];
        try{
            Test.startTest();
            CustomParkingLotFormController.updateParkingLots('[{"Type__c":"err","Id":"' + pl.Id + '123' + '"}]');
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Script-thrown exception'), 'There should be an exception');
        }
    }
}