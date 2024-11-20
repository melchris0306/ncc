/*******************************************************************************************
* @name: MassSessionInternalAllocationController
* @author: MMallorca
* @created: 06-19-2023
* @description: Controller communityEventInternalAllocation Page
*
* -------------------------------------------------------------------------------------------
*       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
*       	  ----  ---------------     --------------------  -----------------------------
* @version    1.0   ??           		??                    ??
*********************************************************************************************/
public class MassSessionInternalAllocationController {
    private static WithoutSharingClass withoutShare = new WithoutSharingClass();
    @AuraEnabled
    public static mainWrapper getRoles(Id sessId){

        String hasData = 'No';

        mainWrapper returnWrapper = new mainWrapper();
        List<sessionParticipantWrapper> sessionPartList = new List<sessionParticipantWrapper>();
        Map<String, List<Internal_Resource_Session__c>> roleParticipantMap = new Map<String, List<Internal_Resource_Session__c>>();

        //Loop through session participants and get Role - Participant Mapping
        for(Internal_Resource_Session__c sessionPartRec : withoutShare.getSessionInternalResources(sessId)){
            if(!roleParticipantMap.containsKey(sessionPartRec.Resource_Session_Role__c)){
                roleParticipantMap.put(sessionPartRec.Resource_Session_Role__c, new List<Internal_Resource_Session__c>());
            }
            roleParticipantMap.get(sessionPartRec.Resource_Session_Role__c).add(sessionPartRec);
        }

        //Loop through each role and participants(if any) then contruct table
        for(Internal_Resource_Role__c sessionRoleRec : withoutShare.getInternalResourceRoles(sessId)){
            for(Integer i = 0; i < sessionRoleRec.Internal_Resource_Number_of_Role__c; i++){
                sessionParticipantWrapper sessionPart = new sessionParticipantWrapper();
                sessionPart.Id = 'Dummy_'+sessionRoleRec.Internal_Resource_Role_Title__c+i;
                sessionPart.IdChk = null;
                sessionPart.Role = sessionRoleRec.Internal_Resource_Role_Title__c;
                sessionPart.RoleDescription = sessionRoleRec.Internal_Resource_Role_Description__c;
                sessionPart.RoleAndDesc = sessionRoleRec.Internal_Resource_Role_Title__c + ' \r\n ' + sessionRoleRec.Internal_Resource_Role_Description__c;
                sessionPart.FirstName = '';
                sessionPart.LastName = '';
                sessionPart.Email = '';
                
                if(!roleParticipantMap.isEmpty() && roleParticipantMap.containsKey(sessionRoleRec.Internal_Resource_Role_Title__c)){
                    hasData = 'Yes';
                    Integer participantSize = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c).size();
                    if(i < participantSize){
                        sessionPart.Id = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c)[i].Id;
                        sessionPart.IdChk = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c)[i].Id;
                        sessionPart.FirstName = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c)[i].Contact__r.FirstName;
                        sessionPart.LastName = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c)[i].Contact__r.LastName;
                        sessionPart.Email = roleParticipantMap.get(sessionRoleRec.Internal_Resource_Role_Title__c)[i].Contact__r.Email;
                    }
                }

                sessionPartList.add(sessionPart);
            }
        }

        //Debugging
        if(!sessionPartList.isEmpty()){
            returnWrapper.message = 'Success';
            returnWrapper.hasData = hasData;
            //returnWrapper.signUpInstructions = signUpInstructions;
            returnWrapper.tableValues = sessionPartList;
        }

        return returnWrapper;
    }

    /*******************************************************************************************
    * @name: saveSessionInternalResource
    * @author: MMallorca
    * @created: 06-22-2023
    * @description: Save Session Internal Resource
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *             
	*********************************************************************************************/
    
    @AuraEnabled
    public static String saveSessionInternalResource(String sessionInternalResources, String sessId){
        String message = '';
        try{
            Map<String, String> roleDescriptionMap = new Map<String, String>();
            List<Internal_Resource_Role__c> Roles = withoutShare.getInternalResourceRoles(sessId);
            for(Internal_Resource_Role__c rolerec : Roles){
                roleDescriptionMap.put(rolerec.Internal_Resource_Role_Title__c,rolerec.Internal_Resource_Role_Description__c);
            }
				
            Map<String, Contact> emailToInsertContactMap = new Map<String, Contact>();
            
            Map<String, Internal_Resource__c> emailToInsertInternalResourceMap = new Map<String, Internal_Resource__c>();
            Map<String, Internal_Resource_Session__c> emailToInsertSessionIntResMap = new Map<String, Internal_Resource_Session__c>();

            Map<String, Id> emailContactIdMap = new Map<String, Id>();
            Map<String, Id> emailInternalResourceIdMap = new Map<String, Id>();

            Map<Id, sessionParticipantWrapper> sessionIdMap = new Map<Id, sessionParticipantWrapper>();

            List<Internal_Resource_Session__c> sessionPartToUpdate = new List<Internal_Resource_Session__c>();
            List<Internal_Resource__c> intResToUpdate = new List<Internal_Resource__c>();

            List<sessionParticipantWrapper> sessionInternalResourceList = (List<sessionParticipantWrapper>) JSON.deserialize(sessionInternalResources, List<sessionParticipantWrapper>.class);

            Id eventId = withoutShare.getEventIdOnSave(sessId);

            //Creation Contact, Internal Resource and Session Participant Records
            for(sessionParticipantWrapper sessionPart : sessionInternalResourceList){

                if(!String.isBlank(sessionPart.FirstName) && !String.isBlank(sessionPart.LastName) && !String.isBlank(sessionPart.Email)){
                    //Contact
                    Contact conRecord = new Contact();
                    conRecord.FirstName = sessionPart.FirstName;
                    conRecord.LastName = sessionPart.LastName;

                    sessionPart.Email = sessionPart.Email.toLowerCase();
                    conRecord.Email = sessionPart.Email;

                    if(!emailToInsertContactMap.containsKey(sessionPart.Email)){
                        emailToInsertContactMap.put(sessionPart.Email,conRecord);
                    }

                    //Internal Resource
                    Internal_Resource__c internalRes = new Internal_Resource__c();
                    internalRes.Event__c = eventId;
                    internalRes.Contact__c	 = null;
                    
                    if(!emailToInsertInternalResourceMap.containsKey(sessionPart.Email)){
                        emailToInsertInternalResourceMap.put(sessionPart.Email, internalRes);
                    }

                    //Internal Resource Session
                    Internal_Resource_Session__c sessionRec = new Internal_Resource_Session__c();
                    sessionRec.Resource__c = null;
                    sessionRec.Event__c = eventId;
                    sessionRec.Session__c = sessId;
                    sessionRec.Contact__c = null;
                    sessionRec.Resource_Session_Status__c = 'Registered';
                    sessionRec.Resource_Session_Role__c = sessionPart.Role;
                    sessionRec.Resource_Registration_Date_Time__c = DateTime.now();
                    
                    if(!emailToInsertSessionIntResMap.containsKey(sessionPart.Email+':'+sessionPart.Role)){
                        emailToInsertSessionIntResMap.put(sessionPart.Email+':'+sessionPart.Role,sessionRec);
                    }

                    //Get Exising Session Ids
                    if(!(sessionPart.Id).contains('Dummy_')){
                        sessionIdMap.put(sessionPart.Id,sessionPart);
                    }
                }else{
                    Integer count = 0;
                    List<String> fieldList = new List<String>();
                    if(String.isBlank(sessionPart.FirstName)){
                        count++;
                        fieldList.add('First Name');
                    }
                    if(String.isBlank(sessionPart.LastName)){
                        count++;
                        fieldList.add('Last Name');
                    }
                    
                    if(String.isBlank(sessionPart.Email)){
                        count++;
                        fieldList.add('Email');
                    }

                    if(count < 3){
                        message = 'Error registering internal resource sessions. Please populate all fields. Missing: ' + fieldList + ' on ' + ' one of the ' + sessionPart.Role + 's';
                        return message;
                    }
                }
            }

            //Check for Existing Internal Resource Sessions
            if(!sessionIdMap.isEmpty()){
                for(Internal_Resource_Session__c sessionRec : withoutShare.getSessionPartOnSave(sessionIdMap,sessId)){
                    if(sessionRec.Contact__r.FirstName != sessionIdMap.get(sessionRec.Id).FirstName 
                    || sessionRec.Contact__r.LastName != sessionIdMap.get(sessionRec.Id).LastName
                    || sessionRec.Contact__r.Email != sessionIdMap.get(sessionRec.Id).Email) {
                        Internal_Resource_Session__c updateRec = new Internal_Resource_Session__c();
                        updateRec.Id = sessionRec.Id;
                        updateRec.Resource_Session_Status__c = 'Canceled';
                        sessionPartToUpdate.add(updateRec);
                    }
                }
            }

            //Check for Existing Contacts based on Email, Insert those new Contacts and Get Ids of Existing Ones
            message = checkForExistingContacts(emailToInsertContactMap,emailContactIdMap, message);
            if(message != '') return message;

            //Check for Existing Participants based on existing contacts, Insert those new Participants and Get Ids of Existing Ones. Link to Contacts
            checkForExistingParticipants(eventId,emailToInsertInternalResourceMap,emailInternalResourceIdMap,emailToInsertContactMap,emailContactIdMap);

            //Check for Existing Session Participant based on Exising Participants of the Event, Insert those new Session Participants. Link to Participants
            checkForExistingInternalResource(emailInternalResourceIdMap,emailContactIdMap,emailToInsertSessionIntResMap,
                    sessionPartToUpdate,emailToInsertInternalResourceMap,emailToInsertContactMap,sessId);

            //Update Session Participants
            if(!sessionPartToUpdate.isEmpty()){
               withoutShare.updateSessPart(sessionPartToUpdate);
            }

            //Update Internal Resource
            if(!intResToUpdate.isEmpty()){
                withoutShare.updatePart(intResToUpdate);
            }

        }catch(Exception e){
            message = e.getMessage();
            UTIL_LoggingService.logHandledException(e);
        }

        return message;
    }

    public static String checkForExistingContacts(Map<String, Contact> emailToInsertContactMap,Map<String, Id> emailContactIdMap, String message){
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        for(Contact conRec : withoutShare.getContactOnSave(emailToInsertContactMap)){
            if(emailToInsertContactMap.containsKey(conRec.Email)){
                emailToInsertContactMap.remove(conRec.Email);
                existingContactMap.put(conRec.Email, conRec);
                
                //Add to Email - Contact Id Mapping
                if(!emailContactIdMap.containsKey(conRec.Email)){
                    emailContactIdMap.put(conRec.Email, conRec.Id);
                }
            }
        }
        //Insert Contacts
        if(!emailToInsertContactMap.isEmpty()){
            withoutShare.insertContact(emailToInsertContactMap);
        }
        emailToInsertContactMap.putAll(existingContactMap);
        return '';
    }

    public static void checkForExistingParticipants(Id eventId, Map<String, Internal_Resource__c> emailToInsertParticipantMap, Map<String, Id> emailParticipantIdMap,
            Map<String, Contact> emailToInsertContactMap,Map<String, Id> emailContactIdMap){
        for(Internal_Resource__c partRec : withoutShare.getParticipantsOnSave(eventId,emailContactIdMap)){
            //Remove From Participants to Insert
            emailToInsertParticipantMap.remove(partRec.Contact__r.Email);

            //Add to Email - Contact Id Mapping
            if(!emailParticipantIdMap.containsKey(partRec.Contact__r.Email)){
                emailParticipantIdMap.put(partRec.Contact__r.Email, partRec.Id);
            }
        }

        //Link Participant to Contacts then Insert
        if(!emailToInsertParticipantMap.isEmpty()){
            for(String emailStr : emailToInsertParticipantMap.keySet()){
                if(emailContactIdMap.containsKey(emailStr)){
                    emailToInsertParticipantMap.get(emailStr).Contact__c = emailContactIdMap.get(emailStr);
                }else if(emailToInsertContactMap.containsKey(emailStr)){
                    emailToInsertParticipantMap.get(emailStr).Contact__c = emailToInsertContactMap.get(emailStr).Id;
                }
            }

            withoutShare.insertPart(emailToInsertParticipantMap);
        }
    }

    /*******************************************************************************************
    * @name: checkForExistingInternalResource
    * @author: MMallorca
    * @created: 06-23-2023
    * @description: Check for Existing Session Internal Resource
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *******************************************************************************************/
    public static void checkForExistingInternalResource(Map<String, Id> emailParticipantIdMap,Map<String, Id> emailContactIdMap,
            Map<String, Internal_Resource_Session__c> emailToInsertSessionPartMap,List<Internal_Resource_Session__c> sessionPartToUpdate,
            Map<String, Internal_Resource__c> emailToInsertParticipantMap,Map<String, Contact> emailToInsertContactMap, String sessId){
        for(Internal_Resource_Session__c sessPart : withoutShare.getSessionPartOnSave2(emailContactIdMap,emailParticipantIdMap,sessId)){
            //Remove From Contacts to Insert
            Internal_Resource_Session__c updateRec = new Internal_Resource_Session__c();
            updateRec.Id = sessPart.Id;
            updateRec.Resource_Session_Status__c = 'Registered';
            if(emailToInsertSessionPartMap.containsKey(sessPart.Contact__r.Email+':'+sessPart.Resource_Session_Role__c)){
                updateRec.Resource_Session_Role__c = (emailToInsertSessionPartMap.get(sessPart.Contact__r.Email+':'+sessPart.Resource_Session_Role__c)).Resource_Session_Role__c;
            }
            if(sessPart.Resource_Session_Status__c == 'Canceled' && emailToInsertSessionPartMap.containsKey(sessPart.Contact__r.Email+':'+sessPart.Resource_Session_Role__c)){
                sessionPartToUpdate.add(updateRec);
            }
            emailToInsertSessionPartMap.remove(sessPart.Contact__r.Email+':'+sessPart.Resource_Session_Role__c);
        }

        //Link Session Internal Resource to Contact and Resource then Insert
        if(!emailToInsertSessionPartMap.isEmpty()){
            for(String emailStr : emailToInsertSessionPartMap.keySet()){
                //Populate Contact Id
                if(emailContactIdMap.containsKey(emailStr.substringBefore(':'))){
                    emailToInsertSessionPartMap.get(emailStr).Contact__c = emailContactIdMap.get(emailStr.substringBefore(':'));
                }else if(emailToInsertContactMap.containsKey(emailStr.substringBefore(':'))){
                    emailToInsertSessionPartMap.get(emailStr).Contact__c = emailToInsertContactMap.get(emailStr.substringBefore(':')).Id;
                }

                //Populate Participant Id
                if(emailParticipantIdMap.containsKey(emailStr.substringBefore(':'))){
                    emailToInsertSessionPartMap.get(emailStr).Resource__c = emailParticipantIdMap.get(emailStr.substringBefore(':'));
                }else if(emailToInsertParticipantMap.containsKey(emailStr.substringBefore(':'))){
                    emailToInsertSessionPartMap.get(emailStr).Resource__c = emailToInsertParticipantMap.get(emailStr.substringBefore(':')).Id;
                }
            }

            withoutShare.insertSessPart(emailToInsertSessionPartMap);
        }
    }

    @AuraEnabled
    public static String getEventDetails(String sessId) {
        return withoutShare.getEventDetailsWS(sessId);
    }

    @AuraEnabled
    public static String getEventDetails2(String sessId) {
        return withoutShare.getEventDetails2WS(sessId);
    }

    @AuraEnabled
    public static Session__c getSessionDetails(String sessId) {
        return withoutShare.getSessionDetails(sessId);
    }

    @AuraEnabled
    public static String getEventDetailsId(String sessId) {
        return withoutShare.getEventDetailsIdWS(sessId);
    }

    public without sharing class WithoutSharingClass{
        public void insertContact(Map<String, Contact> emailToInsertContactMap){
            insert emailToInsertContactMap.values();
        }

        public void insertPart(Map<String, Internal_Resource__c> emailToInsertParticipantMap){
            insert emailToInsertParticipantMap.values();
        }

        public void insertSessPart(Map<String, Internal_Resource_Session__c> emailToInsertSessionPartMap){
            insert emailToInsertSessionPartMap.values();
        }

        public void updateSessPart(List<Internal_Resource_Session__c> sessionPartToUpdate){
            update sessionPartToUpdate;
        }

        public void updatePart(List<Internal_Resource__c> partToUpdate){
            update partToUpdate;
        }

        public String getEventDetailsWS(String sessId){
            return [SELECT Id, Name, Start_Date_Time_2__c, Event__r.Name FROM Session__c WHERE Id =: sessId LIMIT 1].Event__r.Name;
        }

        public String getEventDetails2WS(String sessId) {
            return [SELECT Id, Name, Start_Date_Time_2__c,Start_Date_Time2__c,End_Date_Time2__c, Event__r.Name FROM Session__c WHERE Id =: sessId LIMIT 1].Name;
        }

        /*******************************************************************************************
        * @name: getSessionDetails
        * @author: MMallorca
        * @created: 06-22-2023
        * @description: Method to get the Session Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *********************************************************************************************/
        public Session__c getSessionDetails(String sessId) {
            return [SELECT Id, Name, Start_Date_Time_2__c,Start_Date_Time2__c,End_Date_Time2__c, Event__r.Name,Location__c, Time_Zone__c FROM Session__c WHERE Id =: sessId LIMIT 1];
        }

        public String getEventDetailsIdWS(String sessId) {
            return [SELECT Id, Name, Start_Date_Time_2__c, Event__r.Event_Id__c FROM Session__c WHERE Id =: sessId LIMIT 1].Event__r.Event_Id__c;
        }

        /*******************************************************************************************
        * @name: getSessionInternalResources
        * @author: 06-22-2023
        * @created: MMallorca
        * @description: Method to get the Session participant Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *********************************************************************************************/
        public List<Internal_Resource_Session__c> getSessionInternalResources(String sessId){
            return [SELECT Id, Resource_Session_Role__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email FROM Internal_Resource_Session__c
            WHERE Session__c =: sessId AND Contact__c != null AND Resource_Session_Status__c != 'Canceled'
            ORDER BY CreatedDate ASC];
        }
        
        public List<Internal_Resource_Role__c> getInternalResourceRoles(String sessId){
            return [SELECT Id, Internal_Resource_Role_Title__c, Internal_Resource_Role_Description__c, Internal_Resource_Number_of_Role__c, Session__c, Session__r.Sign_Up_Instructions_2__c,Name FROM
                    Internal_Resource_Role__c WHERE Session__c =: sessId ORDER BY Name ASC];
        }
        
        public Id getEventIdOnSave(String sessId){
            return [SELECT Id, Event__c FROM Session__c WHERE Id =: sessId LIMIT 1].Event__c;
        }

        /*******************************************************************************************
        * @name: getSessionPartOnSave
        * @author: MMallorca
        * @created: 06-22-2023
        * @description: Method to get the Session participant Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *********************************************************************************************/
        public List<Internal_Resource_Session__c> getSessionPartOnSave(Map<Id, sessionParticipantWrapper> sessionIdMap, String sessId){
            return [SELECT Id, Resource__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email FROM Internal_Resource_Session__c WHERE ID IN :sessionIdMap.keySet()
            AND Session__c =: sessId];
        }

        public List<Contact> getContactOnSave(Map<String, Contact> emailToInsertContactMap){
            return [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Email IN :emailToInsertContactMap.keySet() ORDER BY LastModifiedDate DESC ];
        }

        public List<Internal_Resource__c> getParticipantsOnSave(Id eventId, Map<String, Id> emailContactIdMap){
            return [SELECT Id, Name, Contact__c, Contact__r.Email FROM Internal_Resource__c WHERE Event__c =: eventId AND
            Contact__c IN :emailContactIdMap.values()];
        }

        public List<Internal_Resource_Session__c> getSessionPartOnSave2(Map<String, Id> emailContactIdMap,Map<String, Id> emailParticipantIdMap, String sessId){
            return [SELECT Id, Resource_Session_Status__c, Contact__r.Email, Resource_Session_Role__c FROM Internal_Resource_Session__c WHERE Contact__c IN: emailContactIdMap.values() AND
            Resource__c IN: emailParticipantIdMap.values() AND Session__c =: sessId];
        }

        /*******************************************************************************************
        * @name: updateInternalResourceSession
        * @author: MMallorca
        * @created: 06-23-2023
        * @description: Update Internal Resource Session to Canceled
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *********************************************************************************************/
        public void updateInternalResourceSession(String partSessionId){
            Internal_Resource_Session__c partSessionRec = [Select Resource_Session_Status__c from Internal_Resource_Session__c where Id =: partSessionId];
            partSessionRec.Resource_Session_Status__c = 'Canceled';
            partSessionRec.Resource_Canceled_Date_Time__c = DateTime.now();
            update partSessionRec;
        }
    }

    public class mainWrapper{
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String hasData {get;set;}
        @AuraEnabled public List<sessionParticipantWrapper> tableValues {get;set;}
    }

    public class sessionParticipantWrapper{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String IdChk {get;set;}
        @AuraEnabled public String Role {get;set;}
        @AuraEnabled public String RoleDescription {get;set;}
        @AuraEnabled public String RoleAndDesc {get;set;}
        @AuraEnabled public String FirstName {get;set;}
        @AuraEnabled public String LastName {get;set;}
        @AuraEnabled public String Email {get;set;}
    }

    @AuraEnabled
    public static void removeRole(String intResId) {
        withoutShare.updateInternalResourceSession(intResId);
    }
}