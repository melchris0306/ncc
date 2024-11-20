/*******************************************************************************************
  * @name: CampaignTriggerHandler 
  * @author: Minh
  * @created: 23-10-2021
  * @description: trigger handler Campaign__c Trigger
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *            No.  Date(dd-mm-yyy) Author                Description
  *           ----  ---------       --------------------  -----------------------------
  * @version   1.0  23-10-2021      Minh                  Initial version.
  *********************************************************************************************/

public class CampaignTriggerHandler {
    
    public static void onBeforeInsert(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
        campaignTriggerUtility.setSiteURL(newCampaignList);  
    }
    
    public static void onBeforeUpdate(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
        campaignTriggerUtility.setSiteURL(newCampaignList);    
    }
    
    public static void onBeforeDelete(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
            
    }
    
    public static void onAfterInsert(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
           
    }
    
    public static void onAfterUpdate(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
            
    }
    
    public static void onAfterDelete(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
            
    }
    
    public static void onAfterUndelete(List<Campaign__c> newCampaignList, Map<Id,Campaign__c> newCampaignMap, List<Campaign__c> oldCampaignList, Map<id,Campaign__c> oldCampaignMap){
            
    }
    
}