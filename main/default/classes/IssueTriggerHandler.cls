/**
@revision Kyzer Buhay - Removed Project in Class name (ProjectIssueTriggerHandler) to IssueTriggerHandler
@revision Rianno Rizarri - Added inner class declared without sharing for guest users to retrieve relevant records.
							For retrieving of existing contacts that matches the email from the issue record.
**/
public class IssueTriggerHandler extends TriggerHandler{
	protected override void beforeInsert(List<SObject> newRecords) {
		defaultRaisedBy(newRecords);
        populateUrl(newRecords);
	}
    
	protected override void beforeUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
		defaultRaisedBy(getUpdatedRecordsWithChangedFields(new List<sObjectField>{
			Issue__c.Raised_By_Email__c,
			Issue__c.Raised_By__c
		}));
        populateUrl(updatedRecordsMap.values());
	}
    
	protected override void afterUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
		issueAddressedNotification(updatedRecordsMap, oldRecordsMap);
	}

	private void issueAddressedNotification(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap){
		Compass_Setting__c cs = new Compass_Setting__c();
		Set<Id> eventIds = new Set<Id>();
		Set<Id> contactIds = new Set<Id>();
        Set<Id> issueIdsToNotify = new Set<Id>();
		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
		
		for(Issue__c issue: (List<Issue__c>) updatedRecordsMap.values()){
            Issue__c oldIssue = (Issue__c) oldRecordsMap.get(issue.Id);
			if(issue.Event__c != null){
				eventIds.add(issue.Event__c);
			}
			if(issue.Raised_By__c != null){
				contactIds.add(issue.Raised_By__c);
			}
            //filter issue id to notify
            if(issue.Status__c != oldIssue.Status__c && issue.Status__c == 'Addressed'){
                issueIdsToNotify.add(issue.Id);
            }
		}
        
        if(!issueIdsToNotify.isEmpty()){
			cs = [SELECT Id, Email_Template_Issue_Id__c FROM Compass_Setting__c LIMIT 1];            
            
            Map<Id,Event__c> eventMap = new Map<Id,Event__c>([SELECT Id, Email_Sender_Id__c, Email_Sender_Name__c FROM Event__c WHERE Id IN:eventIds]);
            Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Email FROM Contact WHERE Id IN: contactIds]);
            Map<Id,OrgWideEmailAddress> orgWideEmailAddressMap = new Map<Id,OrgWideEmailAddress>([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 200]);
    
            for(Issue__c issue: (List<Issue__c>) updatedRecordsMap.values()){
                if(issueIdsToNotify.contains(issue.Id) && eventMap.containsKey(issue.Event__c)){
                    Event__c eventRec = eventMap.get(issue.Event__c);
                    if(eventRec.Email_Sender_Id__c != null){
                        if(orgWideEmailAddressMap.containsKey(eventRec.Email_Sender_Id__c) && contactMap.containsKey(issue.Raised_By__c)){
                            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                            message.setTargetObjectId(issue.Raised_By__c); 
                            message.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(eventRec.Email_Sender_Id__c).Id);
                            message.setReplyTo(orgWideEmailAddressMap.get(eventRec.Email_Sender_Id__c).Address);
                            message.setUseSignature(false); 
                            message.setBccSender(false); 
                            message.setSaveAsActivity(true);
                            message.setWhatId(issue.Id);
                            message.setTemplateID(cs.Email_Template_Issue_Id__c);
                            message.toAddresses = new String[] {contactMap.get(issue.Raised_By__c).Email};
                            messages.add(message);
                        }
                    }
                }
            }
		}
		if(!messages.isEmpty()){
			try{
				if(!Test.isRunningTest()){
				Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
				}
			}catch(EmailException e){
				// IF MESSAGE CONTAINS "UNVERIFIED_SENDER_ADDRESS":
				throw new EmailException('Email Sending Failed: UNVERIFIED_SENDER_ADDRESS');
			}
		}
	}

	private void defaultRaisedBy(List<Issue__c> newRecords){
		
		Set<String> emails = new Set<String>();
		// Updated by rrizarri [CCN-857] Oct152021
		// Added a checker to make sure the newRecordsList is not empty
		if(newRecords <> null && newRecords.size() > 0){
			for (Issue__c issue : (List<Issue__c>) newRecords){
				emails.add(issue.Raised_By_Email__c);
			}
		}// end of Edit for [CCN-857]
		
		// Find contacts if it's existing;
		// Updated by rrizarri [CCN-857] Oct152021
		// We utilized without sharing so we can access the existing contacts that guest user can't access
		WithoutSharingClass withoutSharing = new WithoutSharingClass();
		Map<String, Contact> emailContactMap = new Map<String, Contact>();
		List<Contact> listContactWithEmail = new List<Contact>();
		// Added a checker to make sure the emails set is not empty
		if(emails <> null && emails.size() > 0){
			try{
				listContactWithEmail = withoutSharing.getContact(emails);
			}catch(Exception errorAPI){
				system.debug('TRY-CATCH-EmailException-->' + errorAPI);
			}
			for (Contact con : listContactWithEmail){
				emailContactMap.put(con.Email, con);
			}
		}// end of Edit for [CCN-857]


		// get emails that are not existing as contacts
		Set<String> foundContacts = new Set<String>(emailContactMap.keySet());
		Set<String> newEmails = new Set<String>(emails);
		newEmails.removeAll(foundContacts);

		List<Contact> contactList = new List<Contact>();
		for (String em : newEmails){
			contactList.add(new Contact(Email=em, LastName=Em));
		}

		if (contactList.size() > 0){
			insert contactList;
			for (Contact con : contactList){
				emailcontactMap.put(con.Email, con);
			}
		}

		for (Issue__c issue : (List<Issue__c>) newRecords){
			// Updated by rrizarri [CCN-857] Oct152021
			// Added a checker to make sure the emailContactMap map is not empty
            if(emailContactMap.containsKey(issue.Raised_By_Email__c)){
                issue.Raised_By__c = emailContactMap.get(issue.Raised_By_Email__c).Id;
            }// end of Edit for [CCN-857]
		}
	}
    
    private void populateUrl(List<Issue__c> newRecords){
        Set<Id> evtIds = new Set<Id>();
        for(Issue__c projIssue : newRecords){
            evtIds.add(projIssue.Event__c);
        }
        Map<Id,Event__c> eventMap = new Map<Id,Event__c> ([SELECT Id, OwnerId, Parking_Lot_User__c,Parking_Lot_User__r.Email,Owner.Email,Event_Id__c 
                                                           FROM Event__c 
                                                           WHERE Id IN: evtIds]);
        for(Issue__c projIssue : newRecords){
            projIssue.Issue_Page_URL_c__c =  getCommunityURL('Compass') + '/s/issue-tracker?id=' + eventMap.get(projIssue.Event__c)?.Event_Id__c;
        }
    }
    
     
   private String getCommunityURL(string communityName){
        if (!Test.isRunningTest()){
            Network myNetwork = [SELECT Id FROM Network WHERE Name = :communityName];
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            return myCommunity.siteUrl ;
        } else {
            return 'some random url';   
        }
    }
	/*******************************************************************************************
	* @name: WithoutSharingClass
	* @author: Rianno Rizarri
	* @created: 15-10-2021
	* @description: Needs inner class declared without sharing for guest users to retrieve relevant records
	* 
	* Changes (version)
	* -------------------------------------------------------------------------------------------
*        		No.   Date(dd-mm-yyy) 	Author         			Description
	*        	----  ---------    		--------------------  	-----------------------------
	* @version  1.0   15-10-2021   		Rianno Rizarri  		[CCN-857] Initial version.
	*********************************************************************************************/
    private without sharing class WithoutSharingClass {

        public List<Contact> getContact(Set<String> emails){
            return [SELECT Email FROM Contact WHERE Email IN: emails ];
        }
    }
}