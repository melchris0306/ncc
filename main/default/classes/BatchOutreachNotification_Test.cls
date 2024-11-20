/*******************************************************************************
 * @author       Angelo Rivera
 * @date           18.09.2021
 * @description  Test class for BatchOutreachNotification
 * @revision     18.09.2021 - APRivera - Created
 *******************************************************************************/

@IsTest
private class BatchOutreachNotification_Test {

    @TestSetup
    static void createData() {
        OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Edera' LIMIT 1];

        EmailTemplate e = new EmailTemplate(
                DeveloperName = 'test',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'Text',
                Name = 'test',
                IsActive = true
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert e;
        }

        Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        compSetting.Email_Template_Invitation_Id__c = e.Id;
        compSetting.Email_Template_Registration_Id__c = e.Id;
        compSetting.Active_Outreach_Notifications__c = 'Event__c';
        compSetting.Default__c = true;
        insert compSetting;

        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@email.com';
        insert testContact;

        Contact testContact2 = new Contact();
        testContact2.LastName = 'Test Contact2';
        testContact2.Email = 'test2@email.com';
        insert testContact2;

        Contact testContact3 = new Contact();
        testContact3.LastName = 'Test Contact3';
        testContact3.Email = 'test3@email.com';
        insert testContact3;

        Contact testContact4 = new Contact();
        testContact4.LastName = 'Test Contact4';
        testContact4.Email = 'test4@email.com';
        insert testContact4;

        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign Name';
        insert testCampaign;

        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = testCampaign.Id;
        testJourney.Status__c = 'Approved';
        insert testJourney;

        Outreach_Notification__c outreachNotification = new Outreach_Notification__c(
                Name = 'Test Outreach Notification',
                Description__c = 'Outreach Notification for Test Event');
        insert outreachNotification;

        Outreach_Notification_Setting__c outreachNotificationSetting = new Outreach_Notification_Setting__c(
                Outreach_Notification__c = outreachNotification.Id,
                Name = 'L1 Outreach Notification - Event Registration Reminder',
                Description__c = 'L1 Outreach Notification - Event Registration Reminder',
                Type__c = 'Invitation Registration Reminder',
                Email_Template_Name__c = 'Test',
                L1_Days__c = 5,
                L2_Days__c = 2,
                Time__c = Time.newInstance(13,0, 0,0));
        insert outreachNotificationSetting;

        Outreach_Notification_Setting__c outreachNotificationSetting2 = new Outreach_Notification_Setting__c(
                Outreach_Notification__c = outreachNotification.Id,
                Name = 'L1 Outreach Notification - Event Confirmation Reminder',
                Description__c = 'L1 Outreach Notification - Event Confirmation Reminder',
                Type__c = 'Registration Confirmation Reminder',
                Email_Template_Name__c = 'Test',
                L1_Days__c = 5,
                L2_Days__c = 2,
                Time__c = Time.newInstance(13,0, 0,0));
        insert outreachNotificationSetting2;

        Event__c testEvent = new Event__c();
        testEvent.Campaign__c = testCampaign.Id;
        testEvent.Journey__c = testJourney.Id;
        testEvent.Milestone__c = true;
        testEvent.Email_Sender_Id__c = testContact.Id;
        testEvent.Email_Sender_Id__c = owea.Id;
        testEvent.Start_Date_Time__c = System.today()+6;
        testEvent.End_Date_Time__c = System.today() + 10;
        testEvent.Outreach_Notification__c = outreachNotification.Id;
        testEvent.Time_Zone__c = 'EDT'; 
        insert testEvent;

        Event__c testEvent2 = new Event__c();
        testEvent2.Campaign__c = testCampaign.Id;
        testEvent2.Journey__c = testJourney.Id;
        testEvent2.Milestone__c = true;
        testEvent2.Email_Sender_Id__c = testContact2.Id;
        testEvent2.Email_Sender_Id__c = owea.Id;
        testEvent2.Start_Date_Time__c = System.today()+3;
        testEvent2.End_Date_Time__c = System.today() + 10;
        testEvent2.Outreach_Notification__c = outreachNotification.Id;
        testEvent2.Time_Zone__c = 'EDT'; 
        insert testEvent2;

        Session__c testSession = new Session__c();
        testSession.Name = 'Test CC Session';
        testSession.Event__c = testEvent.Id;
        testSession.Milestone__c = true;
        testSession.Time_Zone__c = 'AKDT';
        testSession.Start_Date_Time__c = System.today()+6;
        testSession.End_Date_Time__c = System.today() + 10;
        testSession.Time_Zone__c = 'EDT'; 
        insert testSession;

        Session__c testSession2 = new Session__c();
        testSession2.Name = 'Test CC Session';
        testSession2.Event__c = testEvent.Id;
        testSession2.Milestone__c = true;
        testSession2.Time_Zone__c = 'AKDT';
        testSession2.Start_Date_Time__c = System.today()+6;
        testSession2.End_Date_Time__c = System.today() + 10;
        insert testSession2;

        Session__c testSession3 = new Session__c();
        testSession3.Name = 'Test CC Session';
        testSession3.Event__c = testEvent2.Id;
        testSession3.Milestone__c = true;
        testSession3.Time_Zone__c = 'AKDT';
        testSession3.Start_Date_Time__c = System.today()+3;
        testSession3.End_Date_Time__c = System.today() + 10;
        insert testSession3;

        Participant__c participantData = new Participant__c();
        participantData.Event__c = testEvent.Id;
        participantData.Member_Contact__c = testContact.Id;
        participantData.Status__c = 'Invited';
        insert participantData;

        Participant__c participantData2 = new Participant__c();
        participantData2.Event__c = testEvent2.Id;
        participantData2.Member_Contact__c = testContact2.Id;
        participantData2.Status__c = 'Invited';
        insert participantData2;

        Participant__c participantData3 = new Participant__c();
        participantData3.Event__c = testEvent.Id;
        participantData3.Member_Contact__c = testContact3.Id;
        participantData3.Status__c = 'Invited';
        insert participantData3;

        Participant__c participantData4 = new Participant__c();
        participantData4.Event__c = testEvent2.Id;
        participantData4.Member_Contact__c = testContact4.Id;
        participantData4.Status__c = 'In Progress';
        insert participantData4;

        Session_Participant__c sessParticipant = new Session_Participant__c();
        sessParticipant.Event__c = testEvent.Id;
        sessParticipant.Contact__c = testContact.Id;
        sessParticipant.Session__c = testSession.Id;
        sessParticipant.Participant__c = participantData.Id;
        sessParticipant.Status__c = 'Registered';
        insert sessParticipant;

        Session_Participant__c sessParticipant2 = new Session_Participant__c();
        sessParticipant2.Event__c = testEvent.Id;
        sessParticipant2.Contact__c = testContact.Id;
        sessParticipant2.Session__c = testSession2.Id;
        sessParticipant2.Participant__c = participantData.Id;
        sessParticipant2.Status__c = 'Declined';
        insert sessParticipant2;

        Session_Participant__c sessParticipant3 = new Session_Participant__c();
        sessParticipant3.Event__c = testEvent2.Id;
        sessParticipant3.Contact__c = testContact4.Id;
        sessParticipant3.Session__c = testSession3.Id;
        sessParticipant3.Participant__c = participantData4.Id;
        sessParticipant3.Status__c = 'Registered';
        insert sessParticipant3;

        Outreach_Notification_History__c outreachNotificationHistory = new Outreach_Notification_History__c(
                Outreach_Notification_Setting__c = outreachNotificationSetting.Id,
                Contact__c = testContact2.Id,
                Outreach_Notification__c = outreachNotification.Id,
                Related_To__c = 'Test Event 2',
                Related_To_Id__c = testEvent2.Id,
                Timezone__c = 'AKDT'
        );
        insert outreachNotificationHistory;

        Outreach_Notification_History__c outreachNotificationHistory2 = new Outreach_Notification_History__c(
                Outreach_Notification_Setting__c = outreachNotificationSetting2.Id,
                Contact__c = testContact4.Id,
                Outreach_Notification__c = outreachNotification.Id,
                Related_To__c = 'Test CC Session',
                Related_To_Id__c = testSession3.Id,
                Timezone__c = 'AKDT'
        );
        insert outreachNotificationHistory2;
    }


    @IsTest
    static void testOutreachNotificationBatch() {
        Test.startTest();

        BatchOutreachNotification  batchObj = new  BatchOutreachNotification ();
        batchObj.strQuery='SELECT Active_Outreach_Notifications__c, Default__c FROM Compass_Setting__c WHERE Default__c = TRUE';
        Id batchProcessId = Database.executeBatch(batchObj,100);


        String CRON_EXP = '0 0 0 3 9 ? 2024';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new BatchOutreachNotification());

        Test.stopTest();

        List<Outreach_Notification_History__c> onh = new List<Outreach_Notification_History__c>();
        onh = [SELECT Id FROM Outreach_Notification_History__c];
        System.assert(onh.size() > 0);

    }
}