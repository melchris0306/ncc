/*******************************************************************************************
  * @name: LinktreeController 
  * @author: Minh
  * @created: 01-10-2021
  * @description: Campaign's Event summary page
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *            No.  Date(dd-mm-yyy) Author                Description
  *           ----  ---------       --------------------  -----------------------------
  * @version   1.0  01-10-2021      Minh                  Initial version.
  *********************************************************************************************/
public without sharing class LinktreeController {

    @AuraEnabled (cacheable = true)
    public static Campaign__c getcampaignDetail(String campaignId){
        
        System.debug('campaignId: ' + campaignId);

        if (String.isBlank(campaignId)){
            return null;
        }
        
        Campaign__c objCampaign = new Campaign__c();
        
        try {
           	objCampaign = [SELECT Id, name, Logo_URL__c FROM Campaign__c WHERE id = :campaignId  LIMIT 1];               
        } catch (Exception err) {
            System.Debug('TRY-CATCH-CampaignDetailException-->' + err);
        }
        
        return objCampaign;
    }

    @AuraEnabled (cacheable = true)
    public static List<Event__c> getcampaignEvents(String campaignId){
        
        if (String.isBlank(campaignId)){
            return null;
        }
        
        List<Event__c> EventList = new List<Event__c>();
        
        try {
			EventList = [SELECT Id, name, Event_Page_URL__c, Show_To_Links__c FROM Event__c 
                WHERE Campaign__c = :campaignId and Show_To_Links__c=true and Event_Page_URL__c<>null
                order by name];        
        } catch (Exception err) {
            System.Debug('TRY-CATCH-campaignEventsException-->' + err);
        }
        return EventList; 
        
    }
}