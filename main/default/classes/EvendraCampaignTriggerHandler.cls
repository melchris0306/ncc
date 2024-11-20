public class EvendraCampaignTriggerHandler {
    
    public void OnBeforeInsert(List<Campaign> campaigns){
        
        
        for (Campaign campaignRecord : campaigns) {
            generateTokenAndURL(campaignRecord);         
        }
        
    }
    
    public void OnBeforeUpdate(Map<Id, Campaign> newCampaigns, Map<Id, Campaign> oldCampaigns){
        // 09/09/2020 - Jasmine Nguyen - Task: 00201
        // If the Re-Generate URL is updated then call the handler to re-generate the URL
        for (Campaign campaignRecord : newCampaigns.values()) {
            if ((campaignRecord.Re_Generate_URL__c == true) && (campaignRecord.Re_Generate_URL__c != oldCampaigns.get(campaignRecord.Id).Re_Generate_URL__c)){
                generateTokenAndURL(campaignRecord);    
            }         
        }
        
    }
    
    public void generateTokenAndURL(Campaign campaignRecord){
        
        String token =  getToken();
        campaignRecord.Event_Id__c = token;
        
        Id recordtypeId = campaignRecord.RecordTypeId ;
        Id EventrecordtypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        Id SessionrecordtypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Session').getRecordTypeId();
        
        if(recordtypeId == EventrecordtypeId){
            campaignRecord.Event_Page_URL__c =  getCommunityURL('Evendra') + '/s/events?id=' + token;
        }   else if (recordtypeId == SessionrecordtypeId){
            campaignRecord.Event_Page_URL__c =  getCommunityURL('Evendra') + '/s/session?id=' + token;
        }
        campaignRecord.Re_Generate_URL__c = false;
    }
    
    public String getToken(){
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        
        String token = '';
        while (token.length() <= 10) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            token += chars.substring(idx, idx+1);
        }
        
        return token;
    }
    
    public String getCommunityURL(string communityName){
        if (!Test.isRunningTest()){
            /*Network myNetwork = [SELECT Id FROM Network WHERE Name ='Change Cloud Events'];*/
            Network myNetwork = [SELECT Id FROM Network WHERE Name='Compass']; //Changed by: Kyzer Buhay | 01099
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            return myCommunity.siteUrl ;
        } else {
            return 'some random url';   
        }
    }
    
    public void setCampaignMemberStatusDefault(List<Campaign> campaigns){

        List<CampaignMemberStatus> CampaignMemberStatusList = new List<CampaignMemberStatus>();
        List<CampaignMemberStatus> iCampaignMemberStatusList = new List<CampaignMemberStatus>();
        Set<Id> campaignIds = new Set<Id>();
        
        List<RecordType> recordTypeList = [select Id,Name from RecordType where sObjectType = 'Campaign' AND Name ='Event'];
        
        for(Campaign camp : campaigns){
            if(camp.RecordTypeId == recordTypeList[0].Id){
                campaignIds.add(camp.Id);
                CampaignMemberStatus cms1 = new CampaignMemberStatus(CampaignId = camp.Id, HasResponded=false, Label = 'Attended', SortOrder = 3, isDefault = false);
                iCampaignMemberStatusList.add(cms1);  
            }
        }
 
        for (CampaignMemberStatus cm: [Select Id, Label, CampaignID  FROM CampaignMemberStatus WHERE CampaignID IN :campaignIds]){
            if(cm.Label == 'Responded' ){
                cm.Label = 'Registered';
                CampaignMemberStatusList.add(cm);
            }
            if(cm.Label == 'Sent' ){
                cm.Label = 'Invited';
                CampaignMemberStatusList.add(cm);
            }
        }
        
        if(CampaignMemberStatusList.Size() > 0){
            update CampaignMemberStatusList;
        }
        if(iCampaignMemberStatusList.Size() > 0){
            insert iCampaignMemberStatusList;
        }
  
    }

}