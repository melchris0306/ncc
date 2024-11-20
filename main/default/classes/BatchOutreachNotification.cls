/*******************************************************************************
 * @author       Angelo Rivera
 * @date         18.08.2021
 * @description  [CCN-842, CCN-1059, CCN-1060, CCN-1061] Batch class - sends outreach notification
 * @revision     18.08.2021 - APRivera - Created
 *******************************************************************************/
global class BatchOutreachNotification implements Database.Batchable<SObject>, Schedulable, Database.Stateful{

    public String strQuery;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {
            return Database.getQueryLocator(strQuery);
        }
        catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Compass_Setting__c> lstCompassSettings=(List<Compass_Setting__c>)scope;
        if(!lstCompassSettings.isEmpty()){
            if(lstCompassSettings.get(0).Active_Outreach_Notifications__c != null){
                String str = lstCompassSettings.get(0).Active_Outreach_Notifications__c;
                List<String> lstObjects = str.split(',');
                List<String> lstOutreachObjects = new List<String>();
                for(String strObject : lstObjects){
                    if(isObjectExist(strObject)){
                        lstOutreachObjects.add(strObject);
                    }
                }

                if(!lstOutreachObjects.isEmpty()){
                    try {
                        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Objects: ' + lstOutreachObjects );
                        // Send Notifications
                        BatchOutreachNotificationCC.sendOutreachNotifications(lstOutreachObjects);
                    } catch (Exception e) {
                    }
                }
            }
        }  else{
            System.debug(LoggingLevel.DEBUG, ' !@# ERROR: No Active Outreach Notifications configured on Compass Settings. ');
        }
    }

    global static Boolean isObjectExist(String ObjectNameParam){
        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values() ) {
            String sObjName = String.valueOf(sObjectType);
            if (sObjName == ObjectNameParam ) {
                return true;
            }
        }
        return false;
    }

    global void finish(Database.BatchableContext BC) {

    }

    global void execute(SchedulableContext sc) {
        BatchOutreachNotification  batchObj = new  BatchOutreachNotification ();
        batchObj.strQuery='SELECT Active_Outreach_Notifications__c, Default__c FROM Compass_Setting__c WHERE Default__c = TRUE LIMIT ' + String.valueof(Limits.getLimitQueryRows());
        Id batchProcessId = Database.executeBatch(batchObj,100);
    }
}