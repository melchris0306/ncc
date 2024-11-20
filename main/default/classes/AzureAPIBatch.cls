/******************************************************************************    
* AzureAPIBatch - Class for Batch Processing Azure API
*            No.  Date(dd-mm-yyy) Author            Description
*           ----  ---------   --------------------  -----------------------------
* @version   1.0  23-05-2023   Rex David            [CCN-EVE-3056-DV] Virtual Meeting Integration (POC: Microsoft Teams Link)
******************************************************************************/
global class AzureAPIBatch implements database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
    
    public List<Session__c> sessionListToProcess = new List<Session__c>();
    public List<Session__c> sessionToUpdateList = new List<Session__c>();
    public String integAction = '';

    global AzureAPIBatch(String integAction, List<Session__c> sessionList) { 
        this.integAction = integAction;
        sessionListToProcess = sessionList;
    }

    global Database.querylocator start(Database.BatchableContext BC){
        string query = 'SELECT Id, Event__c, Event__r.ChangeEventTypeAction__c, Time_Zone__c, Start_Date_Time__c, End_Date_Time__c, Name, Meeting_Info__c, Meeting_URL__c, MS_Teams_Id__c FROM Session__c WHERE Id IN: sessionListToProcess';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        List<Session__c> sessionList = (List<Session__c>)scope;
    
        for(Session__c session : sessionList){
           
            if(LIMITS.getCallouts() < LIMITS.getLimitCallouts()){
                session.Meeting_URL__c = AzureAPI.processMeetingUrl(integAction,session).Meeting_URL__c;
                if(session.Meeting_URL__c != 'MSTeamsNotSetup') sessionToUpdateList.add(session);
            }
        }

    }

    global void finish(Database.BatchableContext BC){
        if(!sessionToUpdateList.isEmpty()){
            try{
                update sessionToUpdateList;
            }
            catch (Exception ex){
                System.debug(ex);
            }    
        }
    }
}