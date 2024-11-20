public class SignedUpRolesSummaryController {
    
    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    
    @AuraEnabled
    public static mainWrapper getRecords(Id eventId){
        String hasData = 'No';
        
        mainWrapper returnWrapper = new mainWrapper();
        
        try{
            List<sessionParticipantWrapper> sessionPartList = new List<sessionParticipantWrapper>();
            
            Map<String, List<Session_Participant__c>> sessionParticipantMap = new Map<String, List<Session_Participant__c>>();
            Map<String, List<Session_Participant__c>> sessionParticipantMapCancelled = new Map<String, List<Session_Participant__c>>();
            
            //Loop through session participants and get Session-Role : Participant Mapping
            for(Session_Participant__c sessionPartRec : withoutShare.getSessionParticipants(eventId)){
                String mapKey = sessionPartRec.Session__c + '-' + sessionPartRec.Role__c;
                if(!sessionParticipantMap.containsKey(mapKey)){
                    sessionParticipantMap.put(mapKey, new List<Session_Participant__c>());
                }
                sessionParticipantMap.get(mapKey).add(sessionPartRec);
            }      
            
            //Loop through session participants and get Session-Role : Participant Mapping
            for(Session_Participant__c sessionPartRec : withoutShare.getSessionParticipantsCancelled(eventId)){
                String mapKey = sessionPartRec.Session__c + '-' + sessionPartRec.Role__c;
                if(!sessionParticipantMapCancelled.containsKey(mapKey)){
                    sessionParticipantMapCancelled.put(mapKey, new List<Session_Participant__c>());
                }
                sessionParticipantMapCancelled.get(mapKey).add(sessionPartRec);
            }
            
            //Loop through each role and participants(if any) then contruct table
            for(Session_Role__c sessionRoleRec : withoutShare.getSessionRoles(eventId)){
                String mapKey = sessionRoleRec.Session__c + '-' + sessionRoleRec.Role_Title__c;
                for(Integer i = 0; i < sessionRoleRec.Number_of_Role__c; i++){
                    
                    sessionParticipantWrapper sessionPart = new sessionParticipantWrapper();
                    sessionPart.SessionName = sessionRoleRec.Session__r.Name;
                    sessionPart.SessionStartDate = sessionRoleRec.Session__r.Start_Date_Time2__c+'';
                    sessionPart.SessionRole = sessionRoleRec.Role_Title__c;
                    sessionPart.ParticipantFirstName = '';
                    sessionPart.ParticipantLastName = '';
                    sessionPart.ParticipantEmail = '';
                    sessionPart.Status = '';
                    
                    if(!sessionParticipantMap.isEmpty() && sessionParticipantMap.containsKey(mapKey)){
                        hasData = 'Yes';
                        Integer participantSize = sessionParticipantMap.get(mapKey).size();
                        if(i < participantSize){
                            sessionPart.ParticipantFirstName = sessionParticipantMap.get(mapKey)[i].Contact__r.FirstName;
                            sessionPart.ParticipantLastName = sessionParticipantMap.get(mapKey)[i].Contact__r.LastName;
                            sessionPart.ParticipantEmail = sessionParticipantMap.get(mapKey)[i].Contact__r.Email;
                            sessionPart.Status = sessionParticipantMap.get(mapKey)[i].Status__c;
                        }
                    }
                    sessionPartList.add(sessionPart);
                }
                
                if(!sessionParticipantMapCancelled.isEmpty() && sessionParticipantMapCancelled.containsKey(mapKey)){
                    for(Session_Participant__c sessRec : sessionParticipantMapCancelled.get(mapKey)){
                        sessionParticipantWrapper sessionPart = new sessionParticipantWrapper();
                        sessionPart.SessionName = sessionRoleRec.Session__r.Name;
                        sessionPart.SessionStartDate = sessionRoleRec.Session__r.Start_Date_Time2__c+'';
                        sessionPart.SessionRole = sessionRoleRec.Role_Title__c;
                        sessionPart.ParticipantFirstName = sessRec.Contact__r.FirstName;
                        sessionPart.ParticipantLastName = sessRec.Contact__r.LastName;
                        sessionPart.ParticipantEmail = sessRec.Contact__r.Email;
                        sessionPart.Status = sessRec.Status__c;
                        sessionPartList.add(sessionPart);
                    }
                }
            }        
            
            System.debug('Gab: ' + sessionPartList);
            
            //Debugging
            if(!sessionPartList.isEmpty()){
                returnWrapper.message = 'Success';
                returnWrapper.hasData = hasData;
                returnWrapper.tableValues = sessionPartList;
            }
            
            return returnWrapper;
        }catch(Exception e){
            return returnWrapper;
        }
    }
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------       --------------------  -----------------------------
    * @version   1.0  ??              ??                   Initial version.
    * @version   2.0  17-06-2022      Von Pernicia         [CCN-EVE-1773-DV ] - Updated status value from Cancelled to Canceled
    ******************************************************************************/
    public without sharing class WithoutSharingClass{
        public List<Session_Participant__c> getSessionParticipants(String eventId){
            return [SELECT Id, Role__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Status__c, Session__c, Event__c FROM Session_Participant__c 
                    WHERE Event__c =: eventId AND Role__c != null AND Contact__c != null AND Status__c != 'Canceled'];
        }
        
        public List<Session_Participant__c> getSessionParticipantsCancelled(String eventId){
            return [SELECT Id, Role__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Status__c, Session__c, Event__c FROM Session_Participant__c 
                    WHERE Event__c =: eventId AND Rank__c != null AND Role__c != null AND Contact__c != null AND Status__c = 'Canceled'];
        }
        
        public List<Session_Role__c> getSessionRoles(String eventId){
            return [SELECT Id, Role_Title__c, Number_of_Role__c, Session__c, Session__r.Name,Session__r.Start_Date_Time__c,Session__r.Start_Date_Time2__c FROM 
                    Session_Role__c WHERE Session__r.Event__c =: eventId ORDER BY Session__r.Name ASC];
        }
    }
    
    public class mainWrapper{
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String hasData {get;set;}
        @AuraEnabled public List<sessionParticipantWrapper> tableValues {get;set;}
    }
    
    public class sessionParticipantWrapper{
        @AuraEnabled public String SessionName {get;set;}
        @AuraEnabled public String SessionStartDate {get;set;}
        @AuraEnabled public String SessionRole {get;set;}
        @AuraEnabled public String ParticipantFirstName {get;set;}
        @AuraEnabled public String ParticipantLastName {get;set;}
        @AuraEnabled public String ParticipantEmail {get;set;}
        @AuraEnabled public String Status {get;set;}
    }
}