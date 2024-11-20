/*******************************************************************************************
  * @name: ONSEmailTemplateController
  * @author: Paolo Quiambao
  * @created: 20-12-2021
  * @description: Controller for the ONSEmailTemplateControllerTest, used to select an email
  * 			  template from a Visualforce displayed as a picklist on the Outreach
  * 			  Notification Setting page layout.
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
  * 			2.0   28-12-2021		Paolo Quiambao		  [CCN-1062] Refactor code to utilize custom metadata and support WF#3
  *********************************************************************************************/
public class ONSEmailTemplateController {
    Public string emailTemplate{get;set;}
    Outreach_Notification_Setting__c currentRecord;
    
    public ONSEmailTemplateController(ApexPages.StandardController controller) {
        if(FlsUtils.isAccessible('Outreach_Notification_Setting__c', new List<String>{'Email_Template_Id__c'})){
            currentRecord = [SELECT Id, Email_Template_Id__c, Type__c FROM Outreach_Notification_Setting__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        }
    }
    
    /*******************************************************************************************    
    * @name: getSelectedEmailTemplates
    * @author: Paolo Quiambao  
    * @created: 21-12-2021    
    * @description: Returns a select option of the Email Templates under the Compass folder   
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
    * 			  2.0	28-12-2021			Paolo Quiambao		  [CCN-1062] Refactor code to utilize custom metadata and support WF#3
	*********************************************************************************************/
    public List<SelectOption> getSelectedEmailTemplates() {
        List<SelectOption> emailTemplateList = new List<selectOption>();
        Map<String, Id> emailTemplateMap = new Map<String, Id>();
        emailTemplateList.add(new selectOption('- None -', '- None -'));
        try {
            for(EmailTemplate emailTemplate : [SELECT Id, Name FROM EmailTemplate WHERE Folder.Name = 'Compass']) {
                emailTemplateMap.put(emailTemplate.Name, emailTemplate.Id);
            }
            
            // Updated by Paolo Quiambao [CCN-1062] Dec282021
            for(ONS_Email_Template_Setting__mdt onsMdt : ONS_Email_Template_Setting__mdt.getAll().values()) {
                if(currentRecord.Type__c == onsMdt.Notification_Type__c) {
                    emailTemplateList.add(new selectOption(emailTemplateMap.get(onsMdt.Email_Template_Name__c), onsMdt.Email_Template_Name__c));
                }                
            }
            emailTemplateList.sort();
        }
        catch(Exception e) {
            system.debug('No email templates found');
        }
        return emailTemplateList; 
    }
    
    /*******************************************************************************************    
    * @name: save
    * @author: Paolo Quiambao  
    * @created: 21-12-2021    
    * @description: Updates the Email_Template_Id__c field of the Outreach Notification Setting 
    * 				record with the selected email template after clicking the Save button  
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
	*********************************************************************************************/
    public PageReference save() {
        try {
            currentRecord.Email_Template_Id__c = emailTemplate == '- None -' ? '' : emailTemplate;
            currentRecord.Email_Template_Name__c =  emailTemplate == '- None -' ? '' : [SELECT Name FROM EmailTemplate WHERE Id =:emailTemplate].Name;
            if(FlsUtils.isUpdateable(currentRecord, new List<String>{'Email_Sender_Id__c'})) {
                try {
                    update currentRecord;
                }
                catch(Exception e) {
                    system.debug('An Exception has occured: ' + e);
                }
            }
        }
        catch(exception e) {
            system.debug('No email templates found');            
        }
        return null;
    }
}