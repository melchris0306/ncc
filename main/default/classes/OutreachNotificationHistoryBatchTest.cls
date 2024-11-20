@isTest
public class OutreachNotificationHistoryBatchTest {
    @testSetup
    public static void testSetup() {
        List<Apex_Trigger_Switch__c> atsList = new List<Apex_Trigger_Switch__c>();
        Apex_Trigger_Switch__c aps_p = new Apex_Trigger_Switch__c();
        aps_p.Name = 'ParticipantTrigger';
        aps_p.Active__c = false;
        atsList.add(aps_p);
        
        Apex_Trigger_Switch__c aps_sp = new Apex_Trigger_Switch__c();
        aps_sp.Name = 'SessionParticipantTrigger';
        aps_sp.Active__c = false; 
        atsList.add(aps_sp);
        
        Apex_Trigger_Switch__c aps_c = new Apex_Trigger_Switch__c();
        aps_c.Name = 'campaignTrigger';
        aps_c.Active__c = false;
        atsList.add(aps_c);
        
        insert atsList;
        
        Contact c = new Contact();
        c.LastName = 'Test Name';
        c.Email = 'test@test.com';
        insert c;    
        
        EmailTemplate et = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert et;
        }
        
        OrgWideEmailAddress addresses = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        Campaign__c cpgn = new Campaign__c();
        cpgn.Name = 'Campaign Test';
        insert cpgn;
        
        Outreach_Notification__c outreachNotif = new Outreach_Notification__c();
        outreachNotif.Name = 'ON Test';
        outreachNotif.Description__c = 'Test';
        outreachNotif.Active__c = true;
        insert outreachNotif;
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c e = new Event__c();
        e.Name = '';
        e.Campaign__c = cpgn.Id;
        e.Outreach_Notification__c = outreachNotif.Id;
        insert e;
        
        Participant__c p = new Participant__c();
        p.Event__c = e.Id;
        insert p;
        
        List<Session__c> sessionList = new List<Session__c>();
        Session__c s = new Session__c();
        s.Name = 'Session Test';
        s.Event__c = e.Id; 
        
        Session__c s2 = new Session__c();
        s2.Name = 'Session Test 2';
        s2.Event__c = e.Id; 

        sessionList.add(s);
        sessionList.add(s2);
        insert sessionList;
        
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = s.Id;
        
        Session_Participant__c sp2 = new Session_Participant__c();
        sp2.Session__c = s2.Id;
        
        sessionParticipantList.add(sp);
        sessionParticipantList.add(sp2);
        insert sessionParticipantList;
        
        Survey__c survey = new Survey__c();
        survey.Name = 'Test';
        insert survey;
        
        Survey_Participant__c surveyParticipant = new Survey_Participant__c();
        surveyParticipant.Survey__c = survey.Id;
        surveyParticipant.Participant__c = c.Id;
        insert surveyParticipant;
        
        Outreach_Notification_Setting__c onsRegistration = new Outreach_Notification_Setting__c();
        onsRegistration.Name = 'ONS Test';
        onsRegistration.Description__c = 'Test';
        onsRegistration.Outreach_Notification__c = outreachNotif.Id;
        onsRegistration.Type__c = 'Invitation Registration Reminder';
        onsRegistration.Email_Template_Name__c = 'Test';
        onsRegistration.Email_Template_Id__c = et.Id;
        onsRegistration.Email_Sender_Id__c = addresses.Id;
        onsRegistration.L1_Days__c = 5;
        onsRegistration.Time__c = Time.newInstance(1, 2, 3, 4);
        
        Outreach_Notification_Setting__c onsConfirmation = new Outreach_Notification_Setting__c();
        onsConfirmation.Name = 'ONS Test';
        onsConfirmation.Description__c = 'Test';
        onsConfirmation.Outreach_Notification__c = outreachNotif.Id;
        onsConfirmation.Type__c = 'Registration Confirmation Reminder';
        onsConfirmation.Email_Template_Name__c = 'Test';
        onsConfirmation.Email_Template_Id__c = et.Id;
        onsConfirmation.Email_Sender_Id__c = addresses.Id;
        onsConfirmation.L1_Days__c = 5;
        onsConfirmation.Time__c = Time.newInstance(1, 2, 3, 4);
        
        Outreach_Notification_Setting__c onsSession = new Outreach_Notification_Setting__c();
        onsSession.Name = 'ONS Test';
        onsSession.Description__c = 'Test';
        onsSession.Outreach_Notification__c = outreachNotif.Id;
        onsSession.Type__c = 'Session Catchup Reminder';
        onsSession.Email_Template_Name__c = 'Test';
        onsSession.Email_Template_Id__c = et.Id;
        onsSession.Email_Sender_Id__c = addresses.Id;
        onsSession.L1_Days__c = 5;
        onsSession.Time__c = Time.newInstance(1, 2, 3, 4);

        Outreach_Notification_Setting__c onsSurvey = new Outreach_Notification_Setting__c();
        onsSurvey.Name = 'ONS Test';
        onsSurvey.Description__c = 'Test';
        onsSurvey.Outreach_Notification__c = outreachNotif.Id;
        onsSurvey.Type__c = 'Survey Thank You';
        onsSurvey.Email_Template_Name__c = 'Test';
        onsSurvey.Email_Template_Id__c = et.Id;
        onsSurvey.Email_Sender_Id__c = addresses.Id;
        onsSurvey.L1_Days__c = 5;
        onsSurvey.Time__c = Time.newInstance(1, 2, 3, 4);

		List<Outreach_Notification_Setting__c> onsList = new List<Outreach_Notification_Setting__c>();
        onsList.add(onsRegistration);
        onsList.add(onsConfirmation);
        onsList.add(onsSession);
        onsList.add(onsSurvey);
        insert onsList;

        Outreach_Notification_History__c onhRegistration = new Outreach_Notification_History__c();
        onhRegistration.Contact__c = c.Id;
        onhRegistration.Related_To__c = 'Test';
        onhRegistration.Related_To_Id__c = e.Id;
        onhRegistration.Outreach_Notification__c = outreachNotif.Id;
        onhRegistration.Outreach_Notification_Setting__c = onsRegistration.Id;
        onhRegistration.Processed__c = false;
        onhRegistration.Schedule__c = Date.today();
        
        Outreach_Notification_History__c onhConfirmation = new Outreach_Notification_History__c();
        onhConfirmation.Contact__c = c.Id;
        onhConfirmation.Related_To__c = 'Test';
        onhConfirmation.Related_To_Id__c = s.Id;
        onhConfirmation.Outreach_Notification__c = outreachNotif.Id;
        onhConfirmation.Outreach_Notification_Setting__c = onsConfirmation.Id;
        onhConfirmation.Processed__c = false;
        onhConfirmation.Schedule__c = Date.today();
        
        Outreach_Notification_History__c onhSession = new Outreach_Notification_History__c();
        onhSession.Contact__c = c.Id;
        onhSession.Related_To__c = 'Test';
        onhSession.Related_To_Id__c = s2.Id;
        onhSession.Outreach_Notification__c = outreachNotif.Id;
        onhSession.Outreach_Notification_Setting__c = onsSession.Id;
        onhSession.Processed__c = false;
        onhSession.Schedule__c = Date.today();
        
        Outreach_Notification_History__c onhSurvey = new Outreach_Notification_History__c();
        onhSurvey.Contact__c = c.Id;
        onhSurvey.Related_To__c = 'Test';
        onhSurvey.Related_To_Id__c = survey.Id;
        onhSurvey.Outreach_Notification__c = outreachNotif.Id;
        onhSurvey.Outreach_Notification_Setting__c = onsSurvey.Id;
        onhSurvey.Processed__c = false;
        onhSurvey.Schedule__c = Date.today();
        
		List<Outreach_Notification_History__c> onhList = new List<Outreach_Notification_History__c>();
        onhList.add(onhRegistration);
        onhList.add(onhConfirmation);
        onhList.add(onhSession);
        onhList.add(onhSurvey);
        insert onhList;
    }
    
    @isTest
    public static void outreachNotificationHistoryBatchTest() {
        Test.startTest();
        OutreachNotificationHistoryBatch onhb = new OutreachNotificationHistoryBatch();
        Database.executeBatch(onhb, 200);
        Test.stopTest();
        
        List<Outreach_Notification_History__c> onhList = [SELECT Id FROM Outreach_Notification_History__c WHERE Processed__c = true];
        //system.assertEquals(4, onhList.size());
    }

}