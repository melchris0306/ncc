/*******************************************************************************************
  * @name: ONSEmailSenderController
  * @author: Paolo Quiambao
  * @created: 20-10-2021
  * @description: Controller for the ONSEmailSenderControllerTest, used to select an email
  * 			  sender from a Visualforce displayed as a picklist on the Outreach
  * 			  Notification Setting page layout.
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0   20-10-2021   		Paolo Quiambao        [CCN856] Initial version.
  *********************************************************************************************/
public class ONSEmailSenderController {
    public String orgWideAddress{get;set;}
    Outreach_Notification_Setting__c currentRecord;
    
    public ONSEmailSenderController(ApexPages.StandardController controller) {
        if(FlsUtils.isAccessible('Outreach_Notification_Setting__c', new List<String>{'Email_Sender_Id__c'})) {
            currentRecord = [SELECT Id, Email_Sender_Id__c FROM Outreach_Notification_Setting__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        }
    }

    /*******************************************************************************************    
    * @name: getSelectedOrgWideAddress
    * @author: Paolo Quiambao  
    * @created: 20-12-2021    
    * @description: Returns a select option of the Org Wide Addresses  
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
	*********************************************************************************************/    
    public List<SelectOption> getSelectedOrgWideAddress() {
        List<SelectOption> orgWideIdList = new List<selectOption>();
        orgWideIdList.add(new selectOption('- None -', '- None -'));
        try {
            for(OrgWideEmailAddress orgWide : [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 200]) {
                orgWideIdList.add(new selectOption(orgWide.Id, orgWide.Address));
            }
        }
        catch(Exception e) {
            system.debug('No organization address found');
        }
        return orgWideIdList; 
    }
    
	/*******************************************************************************************    
    * @name: save
    * @author: Paolo Quiambao  
    * @created: 21-10-2021    
    * @description: Updates the Email_Sender_Id__c field of the Outreach Notification Setting 
    * 				record with the selected email sender after clicking the Save button  
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
	*********************************************************************************************/
    public PageReference save() {
        try {
            currentRecord.Email_Sender_Id__c = orgWideAddress == '- None -' ? '' : orgWideAddress;
            currentRecord.Email_Sender_Name__c = orgWideAddress == '- None -' ? '' : [SELECT DisplayName FROM OrgWideEmailAddress WHERE Id =:orgWideAddress].DisplayName;
            if(FlsUtils.isUpdateable(currentRecord, new List<String>{'Email_Sender_Id__c'})) {
                try {
                    update currentRecord;
                }
                catch(Exception e) {
                    system.debug('An Exception has occured: ' + e);
                }
            }
        }
        catch(Exception e) {
            system.debug('No organization address found');
        }
        return null;
    }
}