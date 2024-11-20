@isTest
private class CommunicationTriggerHelperTest {
	
	@testSetup
    static void setup(){
        String alias = 'tstSysAd';
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User sysad = new User(
            Username=alias+'@test.com', Alias=alias, CommunityNickname=alias, TimeZoneSidKey='America/Chicago', 
            LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', LanguageLocaleKey='en_US',
            FirstName=alias, LastName=alias, Email=alias+'@test.com', ProfileId=profile.Id, Department = 'Test');
        insert sysad;
        
		//create email template
		EmailTemplate validEmailTemplate = new EmailTemplate();
		validEmailTemplate.isActive = true;
		validEmailTemplate.Name = 'unique_name_test_emailtemplate';
		validEmailTemplate.DeveloperName = 'unique_name_test_emailtemplate';
		validEmailTemplate.TemplateType = 'text';
		validEmailTemplate.FolderId = UserInfo.getUserId();
		validEmailTemplate.Subject = 'Test Template Subject';
		insert validEmailTemplate;
        
		System.runAs(sysad) {
            //create Account
            Account testAccount = new Account(Name='EmailUtilityTestAccount');
            insert testAccount;
            
            //create Contact
            List<Contact> contactList = new List<Contact>();
            for(Integer i=0;i<10;i++){
                contactList.add(new Contact(FirstName='EmailUtility', LastName='TestContact'+i, AccountId=testAccount.Id, Email='test_'+i+'@testEmailUtility.test'));
            }
            insert contactList;
            
            //create Journey__c
            Journey__c testJourney = new Journey__c(Name='EmailUtilityTestJourney');
            insert testJourney;
            
            //create Journey_Participant__c
            List<Journey_Participant__c> jpList = new List<Journey_Participant__c>();
            for(Contact cnt:contactList){
                jpList.add(new Journey_Participant__c(Journey__c=testJourney.Id, Contact__c=cnt.Id));
            }
            insert jpList;
            
            //create CommunicScheduliation__c record;
            Communication__c testRecord = new Communication__c();
            testRecord.Name = '';
            testRecord.Status__c = 'Draft';
            testRecord.Frequency__c = 'Real-time';
            testRecord.Active__c = true;
            testRecord.Subject__c = 'Test Comm Subject';
            testRecord.Body__c = 'Test Comm HTML Body';
            testRecord.Email_Recipient_CC__c = 'testCC1@testEmailUtility.test, testCC2@testEmailUtility.test, testCC3@testEmailUtility.test, testCC4@testEmailUtility.test';
            testRecord.Email_Recipient_BCC__c = 'testBCC1@testEmailUtility.test, testBCC2@testEmailUtility.test, testBCC3@testEmailUtility.test, testBCC4@testEmailUtility.test';
            testRecord.OwnerId = UserInfo.getUserId();
            insert testRecord;
            
            //create Communication_Recipient__c
            List<Communication_Recipient__c> crList = new List<Communication_Recipient__c>();
            for(Journey_Participant__c jp:jpList){
                //CCN-1004 Xen Reyes January 25, 2022
                crList.add(new Communication_Recipient__c(CC_Communication__c=testRecord.Id, Journey_Participant__c=jp.Id, Send_as__c = 'To'));
            }
            insert crList;
        }
	}
    
    static void populateActiveSettings(){
     	Email_Settings__c settings = new Email_Settings__c();
        settings.Default_Org_Wide_Email_Id__c = 'nicole@ulapp.co';
        settings.Email_BCC_Limit_Error_Message__c = 'Maximum Email BCC Address Count Reached: 25.';
        settings.Email_CC_Limit_Error_Message__c = 'Maximum Email CC Address Count Reached: 25.';
        settings.Email_Disabled_Error_Message__c = 'Email Sending is disabled in settings.';
        settings.Email_Sent_Daily_Limit_Error_Message__c = 'Maximum Daily Email Sent Reached: 5000.';
        settings.Email_To_Limit_Error_Message__c = 'Maximum Email To Address Count Reached: 100.';
        settings.Email_Transaction_Limit_Error_Message__c = 'Maximum Transaction Email Sent Reached: 10.';
        settings.isActive__c = true;
        settings.Max_Email_CC_BCC_Number__c = 5;
        settings.Max_Email_To_Number__c = 11;
        insert settings;
    }
    
    static void populateLowSettings(){
     	Email_Settings__c settings = new Email_Settings__c();
        settings.Default_Org_Wide_Email_Id__c = 'nicole@ulapp.co';
        settings.Email_BCC_Limit_Error_Message__c = 'Maximum Email BCC Address Count Reached: 25.';
        settings.Email_CC_Limit_Error_Message__c = 'Maximum Email CC Address Count Reached: 25.';
        settings.Email_Disabled_Error_Message__c = 'Email Sending is disabled in settings.';
        settings.Email_Sent_Daily_Limit_Error_Message__c = 'Maximum Daily Email Sent Reached: 5000.';
        settings.Email_To_Limit_Error_Message__c = 'Maximum Email To Address Count Reached: 100.';
        settings.Email_Transaction_Limit_Error_Message__c = 'Maximum Transaction Email Sent Reached: 10.';
        settings.isActive__c = true;
        settings.Max_Email_CC_BCC_Number__c = 5;
        settings.Max_Email_To_Number__c = 5;
        insert settings;
    }
    
    //happy path test for CommunicationTriggerHelper.onBeforeInsert()
    static testMethod void test_onBeforeInsert_positive_withDate(){

        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));
        Communication__c testRecord = new Communication__c();
        testRecord.Name = 'Positive Test Comms';
        testRecord.Status__c = 'Draft';
        testRecord.Frequency__c = 'Real-time';
        testRecord.Active__c = true;
        testRecord.Subject__c = 'Test Subject';
        testRecord.Body__c = 'Test HTML Body';
        testRecord.Email_Date__c = Date.newInstance(2021, 7, 1);
        testRecord.OwnerId = UserInfo.getUserId();

        test.startTest();
        insert testRecord;
        test.stopTest();

        Communication__c afterTestRecord = [SELECT Email_Date__c FROM Communication__c WHERE Id = :testRecord.Id];
        System.assertEquals(Date.newInstance(2021, 7, 1), afterTestRecord.Email_Date__c);
    }

    static testMethod void test_onBeforeInsert_positive_noDate(){

        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));
        Communication__c testRecord = new Communication__c();
        testRecord.Name = 'Positive Test Comms';
        testRecord.Status__c = 'Draft';
        testRecord.Frequency__c = 'Real-time';
        testRecord.Active__c = true;
        testRecord.Subject__c = 'Test Subject';
        testRecord.Body__c = 'Test HTML Body';
        testRecord.OwnerId = UserInfo.getUserId();

        test.startTest();
        insert testRecord;
        test.stopTest();

        Communication__c afterTestRecord = [SELECT Email_Date__c FROM Communication__c WHERE Id = :testRecord.Id];
        System.assertEquals(Date.today().addDays(14), afterTestRecord.Email_Date__c);
    }

    static testMethod void test_onBeforeInsert_negative(){
        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));
        Communication__c testRecord = new Communication__c();
        testRecord.Name = 'Negative Test Comms';
        testRecord.Status__c = 'Sent';
        testRecord.Frequency__c = 'Real-time';
        testRecord.Active__c = true;
        testRecord.Subject__c = 'Test Subject';
        testRecord.Body__c = 'Test HTML Body';
        testRecord.OwnerId = UserInfo.getUserId();

        test.startTest();
        insert testRecord;
        test.stopTest();

        Communication__c afterTestRecord = [SELECT Email_Date__c FROM Communication__c WHERE Id = :testRecord.Id];
        System.assertEquals(null, afterTestRecord.Email_Date__c);
    }
}