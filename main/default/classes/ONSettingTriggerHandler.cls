/*******************************************************************************************
  * @name: ONSettingTriggerHandler
  * @author: 
  * @created: 21-12-2021
  * @description: Handler for all the logic of the trigger for the Outreach Notification Setting object
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  ---------------------------------
  * @version    1.0	  21-12-2021		Paolo Quiambao		  Initial Creation
  * 		    2.0   28-12-2021		Paolo Quiambao		  [CCN1062] Refactor to utilize custom metadata
  *********************************************************************************************/
public class ONSettingTriggerHandler {
    
    /*******************************************************************************************    
    * @name: onBeforeInsert
    * @author: Paolo Quiambao  
    * @created: 21-10-2021    
    * @description: Executes on before insert trigger event for Outreach Notification Setting   
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   21-12-2021   		Paolo Quiambao        [CCN856] Initial version.
	*********************************************************************************************/
    public static void onBeforeInsert(List<Outreach_Notification_Setting__c> newOutreachNotificationSettingList) {
        Map<String, EmailTemplate> typeToEmailTemplateIdMap = generateTypeToEmailTemplateIdMap();
        
        for(Outreach_Notification_Setting__c ons : newOutreachNotificationSettingList) {
            if(typeToEmailTemplateIdMap.containsKey(ons.Type__c)) {
                ons.Email_Template_Id__c = typeToEmailTemplateIdMap.get(ons.Type__c).Id;
                ons.Email_Template_Name__c = typeToEmailTemplateIdMap.get(ons.Type__c).Name;
            }
        }
    }
    
    /*******************************************************************************************    
    * @name: onBeforeUpdate
    * @author: Paolo Quiambao  
    * @created: 21-10-2021    
    * @description: Executes on before update trigger event for Outreach Notification Setting   
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   21-12-2021   		Paolo Quiambao        [CCN856] Initial version.
	*********************************************************************************************/
    public static void onBeforeUpdate(List<Outreach_Notification_Setting__c> newOutreachNotificationSettingList, Map<Id, Outreach_Notification_Setting__c> oldOutreachNotificationSettingMap) {
        Map<String, EmailTemplate> typeToEmailTemplateIdMap = generateTypeToEmailTemplateIdMap();
        
        for(Outreach_Notification_Setting__c ons : newOutreachNotificationSettingList) {
            if(typeToEmailTemplateIdMap.containsKey(ons.Type__c) && ons.Type__c != oldOutreachNotificationSettingMap.get(ons.Id).Type__c) {
                ons.Email_Template_Id__c = typeToEmailTemplateIdMap.get(ons.Type__c).Id;
                ons.Email_Template_Name__c = typeToEmailTemplateIdMap.get(ons.Type__c).Name;
            }    
        }
    }
    
    /*******************************************************************************************    
    * @name: generateTypeToEmailTemplateIdMap
    * @author: Paolo Quiambao  
    * @created: 21-12-2021    
    * @description: returns a map of Type and Email Template   
    *    
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   21-12-2021   		Paolo Quiambao        [CCN856] Initial version.
    * 			  2.0   28-12-2021			Paolo Quiambao		  [CCN1062] Refactor to utilize custom metadata
	*********************************************************************************************/
    public static Map<String, EmailTemplate> generateTypeToEmailTemplateIdMap() {
        Map<String, EmailTemplate> typeToEmailTemplateIdMap = new Map<String, EmailTemplate>();
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        
        for(EmailTemplate emailTemplate : [SELECT Id, Name FROM EmailTemplate WHERE Folder.Name = 'Compass']) {
            emailTemplateMap.put(emailTemplate.Name, emailTemplate);
        }
        
        // Updated by Paolo Quiambao [CCN-1062] Dec282021
        for(ONS_Email_Template_Setting__mdt onsMdt : ONS_Email_Template_Setting__mdt.getAll().values()) {
            if(onsMdt.Default__c) {
                typeToEmailTemplateIdMap.put(onsMdt.Notification_Type__c, emailTemplateMap.get(onsMdt.Email_Template_Name__c));
            }
        }
        
        return typeToEmailTemplateIdMap;
    }
}