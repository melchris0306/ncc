public with sharing class RelatedListController {
    
       /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  03-12-2023   GDelavin             CCN-EVE-2633-DV
    ******************************************************************************/
	@AuraEnabled
    public static dataWrapper getData(String parentRecordId) {
        dataWrapper dWrapper = New dataWrapper();
        List<Session__c> listSession = [SELECT Id, Name, Status__c, Start_Date_Time2__c, toLabel(Time_Zone__c), Event_Id__c FROM Session__c where Event__c =: parentRecordId LIMIT 5];
        dWrapper.sessionList = listSession;
        dWrapper.eventId = listSession[0].Event_Id__c;
        return dWrapper;
    }
    @AuraEnabled
    public Static namespaceWrapper handleNameSpace(){
        namespaceWrapper fieldWrapper = New namespaceWrapper();
       
        List<Schema.SObjectType> objects = new List<Schema.SObjectType>{ Session__c.SObjectType};
            for(Schema.SObjectType objType: objects){
                for(Schema.SObjectField fld: objType.getDescribe().fields.getMap().values()){
                    if(fld.getDescribe().getName().contains('Status__c')){
                        fieldWrapper.recStatus = fld.getDescribe().getName();
                    }
                    if(fld.getDescribe().getName().contains('Start_Date_Time2__c')){
                        fieldWrapper.startDateTime = fld.getDescribe().getName();
                    }
                    if(fld.getDescribe().getName().contains('Time_Zone__c') && !fld.getDescribe().getName().contains('User_Time_Zone__c')){
                        fieldWrapper.timeZone = fld.getDescribe().getName();
                    }
                    if(fld.getDescribe().getName().contains('Event_Id__c') && !fld.getDescribe().getName().contains('Event__c')){
                        fieldWrapper.eventId = fld.getDescribe().getName();
                    }
                    //System.debug('API Field Name =  '+fld.getDescribe().getName());
                }
            }
        return fieldWrapper;
    }
    @AuraEnabled
    public static List<Session__c> deleteRec(String parentRecordId, String recordId) {
        
        UserRecordAccess recAccess = [
                SELECT
                        HasEditAccess,
                        HasDeleteAccess,
                        RecordId
                FROM UserRecordAccess
                WHERE UserId =: UserInfo.getUserId()
                AND RecordId =: recordId
        ];

        if (recAccess != null && recAccess.HasDeleteAccess) {
            try {
                sObject sObj = Schema.getGlobalDescribe().get('Session__c').newSObject();
                sObj.Id = recordId;
                delete sObj;
            } catch (DmlException e) {
                throw new AuraHandledException('Error while deleting data.');
            }
        }
        
        List<Session__c> listSession = [SELECT Id, Name, Status__c, Start_Date_Time2__c, toLabel(Time_Zone__c), Event_Id__c FROM Session__c where Event__c =: parentRecordId LIMIT 5];
        
        return listSession;
    }
    Public class namespaceWrapper {
        @AuraEnabled public String recStatus {get; set;}
        @AuraEnabled public String startDateTime {get; set;}
        @AuraEnabled public String timeZone {get; set;}
        @AuraEnabled public String eventId {get; set;}
    }
    Public class dataWrapper {
        @AuraEnabled public List<Session__c> sessionList {get; set;}
        @AuraEnabled public String eventId {get; set;}
       
    }
    
}