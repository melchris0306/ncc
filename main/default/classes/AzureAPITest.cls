@isTest
private class AzureAPITest {

    @TestSetup
    static void createTestData() {
        Campaign__c camp = TestDataFactory.createCampaign(1);
        insert camp;
        Event__c event = TestDataFactory.createEvent('Test Event', camp.Id);
        event.Event_Type__c = 'Virtual';
        insert event;
    }


    @isTest
    static void testAzureAPIBatch() {

		Test.startTest();
        Event__c event = [SELECT Id FROM Event__c WHERE Event_Type__c = 'Virtual' LIMIT 1];
        Session__c sess = TestDataFactory.createSession('Test Session One',event.Id);
        sess.Start_Date_Time__c = System.now();
        sess.End_Date_Time__c = System.now().addHours(1);
        sess.Time_Zone__c = 'AFT';
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        insert sess;
        System.assertEquals(sess.Time_Zone__c , 'AFT');
        Test.stopTest();
    } 

    @isTest
    static void testAzureAPIBatchMock() {

		Test.startTest();
        Event__c event = [SELECT Id FROM Event__c WHERE Event_Type__c = 'Virtual' LIMIT 1];
        Session__c sess = TestDataFactory.createSession('Test Session One',event.Id);
        sess.Start_Date_Time__c = System.now();
        sess.End_Date_Time__c = System.now().addHours(1);
        sess.Time_Zone__c = 'AFT';
        insert sess;
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        Database.executeBatch(new AzureAPIBatch('POST',[SELECT Id FROM Session__c]));
        System.assertEquals(sess.Time_Zone__c , 'AFT');
        Test.stopTest();
    } 

    @isTest
    static void testAzureAPIEvent() {

		Test.startTest();
        Event__c event = TestDataFactory.createEvent('Test Event', [SELECT Id FROM Campaign__c LIMIT 1].Id);
        event.Event_Type__c = 'In-Person';
        insert event;
        Session__c sess = TestDataFactory.createSession('Test Session One',event.Id);
        sess.Start_Date_Time__c = System.now();
        sess.End_Date_Time__c = System.now().addHours(1);
        sess.Time_Zone__c = 'AFT';
        insert sess;

        event = [SELECT Id FROM Event__c WHERE Event_Type__c = 'In-Person' LIMIT 1];
        event.Event_Type__c = 'Virtual';
        update event;
        
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        Database.executeBatch(new AzureAPIBatch('POST',[SELECT Id FROM Session__c]));
        System.assertEquals(sess.Time_Zone__c , 'AFT');
        Test.stopTest();
    } 

    @isTest
    static void testAzureAPIGetMeeting() {
        Event__c event = TestDataFactory.createEvent('Test Event', [SELECT Id FROM Campaign__c LIMIT 1].Id);
        event.Event_Type__c = 'In-Person';
        insert event;
        Session__c sess = TestDataFactory.createSession('Test Session One',event.Id);
        sess.MS_Teams_Id__c = 'MSplMmMxNzBmMy0yZjNhLTQyM2YtODU1Yy1mMmQzZDNlZGYyOGUqMCoqMTk6bWVldGluZ19NbVF6WVdRelptRXRPVEZrTlMwME5tWTJMV0ZqWldFdE5HWmlOREZtTkdJME5UaGxAdGhyZWFkLnYy';
        sess.Start_Date_Time__c = System.now();
        sess.End_Date_Time__c = System.now().addHours(1);
        sess.Time_Zone__c = 'AFT';
        insert sess;

        event = [SELECT Id FROM Event__c WHERE Event_Type__c = 'In-Person' LIMIT 1];
        event.Event_Type__c = 'Virtual';
        update event;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        AzureAPI.getMeetingUrl(sess);
        Test.stopTest();
    }
}