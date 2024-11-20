/*******************************************************************************
 * @author       Kyzer Buhay
 * @date         06.19.2021
 * @description  Test class for EmailSenderSchedulable
 *******************************************************************************/
@IsTest
public class EmailSenderSchedulableTest {

    @TestSetup
    static void createData(){
        Email_Settings__c setting = new Email_Settings__c();
        setting.Max_Email_CC_BCC_Number__c = 25;
        setting.Max_Email_To_Number__c = 100;
        insert setting;
        
        // Account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        
        // Contact
        List<Contact> contactList = new List<Contact>();
        for(Integer i = 0; i < 3; i++){
            Contact newContact = new Contact();
            newContact.FirstName = 'Test FirstName' + i;
            newContact.LastName = 'Test LastName' + i;
            newContact.Email = 'testContactEmail' + i + '@testing.com';
            newContact.AccountId = testAccount.Id;
            contactList.add(newContact);
        }
        
        // for contact with HasOptedOutOfEmail set to true
        Contact newContact = new Contact(FirstName = 'Contact', 
                                         LastName = 'HasOptedOutOfEmail',
                                         Email = 'HasOptedOutOfEmail@testing.com',
                                         AccountId = testAccount.Id,
                                         HasOptedOutOfEmail = true);
        contactList.add(newContact);
        insert contactList;

        // Campaign
        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign';
        insert testCampaign;

        // Journey
        List<Journey__c> journeyList = new List<Journey__c>();
        Journey__c testJourneyA = new Journey__c();
        testJourneyA.Name = 'Test Journey A';
        testJourneyA.Campaign__c = testCampaign.Id;
        testJourneyA.Status__c = 'For Review';
        journeyList.add(testJourneyA);

        Journey__c testJourneyB = new Journey__c();
        testJourneyB.Name = 'Test Journey B';
        testJourneyB.Campaign__c = testCampaign.Id;
        testJourneyB.Status__c = 'Approved';
        journeyList.add(testJourneyB);
        insert journeyList;

        // Journey Participant
        List<Journey_Participant__c> journeyParticipantList = new List<Journey_Participant__c>(); 
        for(Contact con : contactList){
            Journey_Participant__c newParticipant = new Journey_Participant__c();
        
            newParticipant.Contact__c = con.Id;
            newParticipant.Journey__c = testJourneyA.Id;
            if(con.HasOptedOutOfEmail == true){
                newParticipant.Journey__c = testJourneyB.Id;
            }
            journeyParticipantList.add(newParticipant);
        }
        insert journeyParticipantList;
        
        // OrgWideEmailAddress
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;

        // Communication
        Communication__c newComms = new Communication__c();
        newComms.Status__c = 'Draft';
        newComms.Campaign__c = testCampaign.Id;
        newComms.Frequency__c = 'Real-time';
        newComms.Organization_Wide_Email_Id__c = emailAddressesId;
        newComms.Email_Recipient_CC__c = 'cctest@testing.com, cctest2@testing.com';
        newComms.Email_Recipient_BCC__c = 'bcctest@testing.com';
        newComms.Subject__c = 'Test Subject';
        newComms.Body__c = 'Test Body';
        newComms.Sender_Name__c = 'Test';
        newComms.Sender_Email_Address__c = 'test@test.com';
        newComms.Sender_Name__c = 'Test';
        newComms.Email_Delivery_Date_Time_Schedule__c = System.now();
        insert newComms;

        // Communication Recipients
        List<Communication_Recipient__c> commsRecipients = new List<Communication_Recipient__c>(); 
        for(Journey_Participant__c jParticipant : journeyParticipantList){
            Communication_Recipient__c newRecipient = new Communication_Recipient__c();
            newRecipient.CC_Communication__c = newComms.Id;
            newRecipient.Journey_Participant__c = jParticipant.Id;
            newRecipient.Contact__c = jParticipant.Contact__c;
            newRecipient.Send_as__c = 'To'; //CCN-1004 Xen Reyes January 25, 2022
            commsRecipients.add(newRecipient);
        }
        insert commsRecipients;
    }
    
    @IsTest
    static void emailSendTestSchedWithNoErrors(){
        Communication__c testCommRec = [SELECT Id, 
                                         Email_Template_Id__c, 
                                         Subject__c, 
                                         Body__c, 
                                         Email_Recipient_CC__c, 
                                         Email_Recipient_BCC__c,
                                         Reply_Email_Address__c,
                                         Organization_Wide_Email_Id__c,
                                         Email_Delivery_Date_Time_Schedule__c FROM Communication__c LIMIT 1];
        List<Communication_Recipient__c> crList = [SELECT Id, 
                                                   Contact__c, 
                                                   Journey_Participant__c,
                                                   Journey_Participant__r.Contact__c FROM Communication_Recipient__c
                                                   WHERE Send_as__c = 'To']; //CCN-1004 Xen Reyes January 25, 2022
        
        Test.startTest();
        	EmailSenderSchedulable emailSenderSched = new EmailSenderSchedulable(JSON.serialize(testCommRec), JSON.serialize(crList), testCommRec.Organization_Wide_Email_Id__c, true, 0);
			
        	String cronExp = '0 0 1 * * ?';
        	System.schedule('Schedule this', cronExp, emailSenderSched);
        
        	List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
    		System.assertEquals(1, jobsScheduled.size(), 'Expecting one scheduled job');
        	System.assertEquals('EmailSenderSchedulable', jobsScheduled[0].ApexClass.Name, 'EmailSenderSchedulable should be the expected scheduled job');
        Test.stopTest();
    }
}