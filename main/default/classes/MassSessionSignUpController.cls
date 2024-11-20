/*******************************************************************************************
* @name: MassSessionSignUpController
* @author: ??
* @created: ??
* @description: Controller for MassSessionSignUp Page
*
* -------------------------------------------------------------------------------------------
*       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
*       	  ----  ---------------     --------------------  -----------------------------
* @version    1.0   ??           		??                    ??
* 			  2.0   07-07-2022			Edison Crisostomo	  [CCN-EVE-14-DV] Updated Query
*             3.0  18-08-2022           Xen Reyes             [CCN-EVE-2067-DV] - Changed references of Sign_Up_Instructions__c to Sign_Up_Instructions_2__c due to field deprecation.
*********************************************************************************************/
public class MassSessionSignUpController {
    private static WithoutSharingClass withoutShare = new WithoutSharingClass();
    @AuraEnabled
    public static mainWrapper getRoles(Id sessId){

        //Add Session Id Later
        //Get Sessions Instructions

        //Checking
        //1. Check if Id supplied is Valid
        //2. Check if there are roles for the session
        //3. Apex Error return

        String signUpInstructions = '';
        String hasData = 'No';

        mainWrapper returnWrapper = new mainWrapper();
        List<sessionParticipantWrapper> sessionPartList = new List<sessionParticipantWrapper>();
        Map<String, List<Session_Participant__c>> roleParticipantMap = new Map<String, List<Session_Participant__c>>();

        //Loop through session participants and get Role - Participant Mapping
        for(Session_Participant__c sessionPartRec : withoutShare.getSessionParticipants(sessId)){
            if(!roleParticipantMap.containsKey(sessionPartRec.Role__c)){
                roleParticipantMap.put(sessionPartRec.Role__c, new List<Session_Participant__c>());
            }
            roleParticipantMap.get(sessionPartRec.Role__c).add(sessionPartRec);
        }

        //Loop through each role and participants(if any) then contruct table
        for(Session_Role__c sessionRoleRec : withoutShare.getSessionRoles(sessId)){
            for(Integer i = 0; i < sessionRoleRec.Number_of_Role__c; i++){
                sessionParticipantWrapper sessionPart = new sessionParticipantWrapper();
                sessionPart.Id = 'Dummy_'+sessionRoleRec.Role_Title__c+i;
                sessionPart.Role = sessionRoleRec.Role_Title__c;
                sessionPart.RoleDescription = sessionRoleRec.Role_Description__c;
                sessionPart.RoleAndDesc = sessionRoleRec.Role_Title__c + ' \r\n ' + sessionRoleRec.Role_Description__c;
                sessionPart.Rank = '';
                sessionPart.BranchOfService = ''; //XEN REYES March 5, 2023 CCN-EVE-2631-DV
                sessionPart.FirstName = '';
                sessionPart.LastName = '';
                sessionPart.Email = '';
                
                if(!roleParticipantMap.isEmpty() && roleParticipantMap.containsKey(sessionRoleRec.Role_Title__c)){
                    hasData = 'Yes';
                    Integer participantSize = roleParticipantMap.get(sessionRoleRec.Role_Title__c).size();
                    if(i < participantSize){
                        sessionPart.Id = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Id;
                        sessionPart.Rank = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Rank__c;
                        sessionPart.BranchOfService = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Branch_of_Service__c; //XEN REYES March 5, 2023 CCN-EVE-2631-DV
                        sessionPart.FirstName = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Contact__r.FirstName;
                        sessionPart.LastName = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Contact__r.LastName;
                        sessionPart.Email = roleParticipantMap.get(sessionRoleRec.Role_Title__c)[i].Contact__r.Email;
                    }
                }

                sessionPartList.add(sessionPart);
            }

            //Start CCN-EVE-2067-DV Xen Reyes
            signUpInstructions = sessionRoleRec.Session__r.Sign_Up_Instructions_2__c;
            //End CCN-EVE-2067-DV Xen Reyes
        }

        //Debugging
        if(!sessionPartList.isEmpty()){
            returnWrapper.message = 'Success';
            returnWrapper.hasData = hasData;
            returnWrapper.signUpInstructions = signUpInstructions;
            returnWrapper.tableValues = sessionPartList;
        }

        return returnWrapper;
    }

    //Fetch Rank Values
    @AuraEnabled
    public static List<String> fetchRankValues(){

        //List<SelectOption> options = new List<SelectOption>();
        List<String> rankOptions = new List<String>();

        Schema.DescribeFieldResult fieldResult = Session_Participant__c.Rank__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry entry : picklistEntries){
            rankOptions.add(entry.getValue());
        }

        return rankOptions;
    }

    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    @AuraEnabled
    public static Map<Object,List<String>> getRankAndRankGroupDependencies() {
        Schema.DescribeFieldResult F = Session_Participant__c.Rank__c.getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        return ChangeCloudController.getDependentPicklistValues(T);
    }
    
    
    
    
            
        
    /*******************************************************************************************
        * @name: getEventFieldRegistrationMdt
        * @author: Leif Erickson de Gracia
        * @created: Sept 5, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    private static Map < String, Registration_Field_Configuration__mdt > getEventFieldRegistrationMdt() {
        Map < String, Registration_Field_Configuration__mdt > regFieldConfig = new Map < String, Registration_Field_Configuration__mdt > ();
        for (Registration_Field_Configuration__mdt config: [SELECT Label, Order__c, Field_API_Name__c, Field_Type__c, Is_Required__c, Picklist_Options__c,
                                                            Object_API_Name__c, DeveloperName, Message_when_Required__c, Actual_Field_Type__c,
                                                            Use_event_field__c, Event_Picklist_Field_API_Name__c, //CCN-907 XEN REYES 11032021
                                                            Has_null_picklist_value__c, //CCN-EVE-1881-DV XEN REYES 18072022
                                                            Use_Picklist_Field_from_related_object__c, Related_Object_Field_API__c, Related_Object_Picklist_Field_API__c //XEN REYES CCN-SUR-3235-DV 14 July 2023
                                                            FROM Registration_Field_Configuration__mdt
                                                            WHERE Is_Active__c = true
                                                            ORDER BY Order__c
                                                            LIMIT 5000
                                                           ]) {
                                                               
                                                               //Updated [CCN3301] title override; Since the future plan is to map the TitleRank to the title field in Contact
                                                               regFieldConfig.put(config.DeveloperName + '-' + config.Object_API_Name__c + '|' + config.Field_API_Name__c, config);
                                                               
                                                           }
        return regFieldConfig;
    }
    
        
    /*******************************************************************************************
        * @name: getFieldConfig
        * @author: Leif Erickson de Gracia
        * @created: Sept 5, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    @AuraEnabled
    public static resultWrapper getFieldConfig(String campaignId) {
        
        System.debug('getFieldConfig');
        
        resultWrapper returnResult = new resultWrapper();
        WithoutSharingClass withoutShare = new WithoutSharingClass();
        
        List < Event__c > campaignRec = new List < Event__c > ();
        
        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        
        //CCN-907 XEN REYES 11032021 - Adding the fields defined in the Event_Picklist_Field_API_Name__c from Registration Field Custom Metadata
        Map < String, Registration_Field_Configuration__mdt > regConfigMap = getEventFieldRegistrationMdt();
        Set < String > fieldsToAddSet = new Set < String > (); //to avoid duplicates
        String additionalFieldsToQuery = '';
        
        System.debug(regConfigMap);
        
        if (!regConfigMap.values().isEmpty()) {
            for (Registration_Field_Configuration__mdt regVar: regConfigMap.values()) {
                if (regVar.Event_Picklist_Field_API_Name__c != null) fieldsToAddSet.add(regVar.Event_Picklist_Field_API_Name__c);
                
                //XEN REYES CCN-SUR-3235-DV 14 July 2023
                if(regVar.Field_Type__c == 'Picklist' && regVar.Use_Picklist_Field_from_related_object__c && regVar.Related_Object_Field_API__c != null && regVar.Related_Object_Picklist_Field_API__c != null){
                    fieldsToAddSet.add(regVar.Related_Object_Field_API__c + '.' + regVar.Related_Object_Picklist_Field_API__c);
                }
            }
            
            //Construct the string to append to dynamic query
            if (!fieldsToAddSet.isEmpty()) {
                List < String > fieldsToAddList = new List < String > (fieldsToAddSet);
                additionalFieldsToQuery = ',';
                for (Integer i = 0; i <= fieldsToAddList.size() - 1; i++) {
                    if (i != fieldsToAddSet.size() - 1) {
                        additionalFieldsToQuery += fieldsToAddList[i] + ',';
                    } else {
                        additionalFieldsToQuery += fieldsToAddList[i] + ' ';
                    }
                }
            }
        }
        
        // campaignId = 'g3UZle8Tnj1';
        // Added for CRUD/FLS Enforcement
        if (FlsUtils.isAccessible('Event__c', new List < String > {
            'Name',
                'OwnerId',
                'Contact_Us_User__c',
                'Time_Zone__c',
                'Event_Id__c'
                })) {
                    //CCN-907 XEN REYES 11032021 - added parameter for dynamic query
                    campaignRec = withoutShare.getEvents(campaignId, additionalFieldsToQuery);
                    
                }
        
        //CCN-907 XEN REYES 11032021 - Updated, added new parameter
        List < RegistrationFields > regFieldMappingList = CC_EventRegistrationClass.getRegistrationFieldConfiguration(campaignRec.get(0).Registration_Fields_JSON__c, campaignRec.get(0).Id, campaignRec[0], regConfigMap);
        List < String > contactFieldsToQuery = new List < String > ();
        System.debug(regFieldMappingList);
        for (RegistrationFields regFieldRecord: regFieldMappingList) {
            if (String.isNotBlank(regFieldRecord.fieldName) &&
                regFieldRecord.objectName == 'Contact' &&
                !contactFieldsToQuery.contains(regFieldRecord.fieldName)) {
                    contactFieldsToQuery.add(regFieldRecord.fieldName);
                }
        }
        
        System.debug(campaignRec);
        
        if (!campaignRec.isEmpty()) {
            returnResult.registrationFieldList = regFieldMappingList;
            
            return returnResult;
        } else {
            return null;
        }
    }

    /*******************************************************************************************
    * @name: saveSessionParticipants
    * @author: ??
    * @created: ??
    * @description: Save Session Participants
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *             2.0   17-06-2022           Von Pernicia         [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
                  3.0   22-08-2022          Von Pernicia          [CCN-EVE-2067-DV] - Added sessionRec.Contact__r.Email as part of condition to cancel Session Participant
    *********************************************************************************************/
    @AuraEnabled
    public static String saveSessionParticipants(String sessionParticipants, String sessId){
        String message = '';

        try{

            Map<String, String> roleDescriptionMap = new Map<String, String>();
            List<Session_Role__c> Roles = withoutShare.getSessionRoles(sessId);
            for(Session_Role__c rolerec : Roles){
                roleDescriptionMap.put(rolerec.Role_Title__c,rolerec.Role_Description__c);
            }

            Map<String, Contact> emailToInsertContactMap = new Map<String, Contact>();
            Map<String, Participant__c> emailToInsertParticipantMap = new Map<String, Participant__c>();
            Map<String, Session_Participant__c> emailToInsertSessionPartMap = new Map<String, Session_Participant__c>();

            Map<String, Id> emailContactIdMap = new Map<String, Id>();
            Map<String, Id> emailParticipantIdMap = new Map<String, Id>();

            Map<Id, sessionParticipantWrapper> sessionIdMap = new Map<Id, sessionParticipantWrapper>();

            List<Session_Participant__c> sessionPartToUpdate = new List<Session_Participant__c>();
            List<Participant__c> partToUpdate = new List<Participant__c>();

            List<sessionParticipantWrapper> sessionParticipantList = (List<sessionParticipantWrapper>) JSON.deserialize(sessionParticipants, List<sessionParticipantWrapper>.class);

            Id eventId = withoutShare.getEventIdOnSave(sessId);

            //Creation Contact, Participant and Session Participant Records
            for(sessionParticipantWrapper sessionPart : sessionParticipantList){

                //XEN REYES CCN-2607 16-Feb-2023
                if(!String.isBlank(sessionPart.FirstName) && !String.isBlank(sessionPart.LastName) && !String.isBlank(sessionPart.Email)){
                    //Contact
                    Contact conRecord = new Contact();
                    conRecord.FirstName = sessionPart.FirstName;
                    conRecord.LastName = sessionPart.LastName;
                    //Gab Delavin CCN-EVE-3426-DV 09/24/2023 - Add value to Title from Session Participant Rank Value
					conRecord.Title = sessionPart.Rank;
                    //XEN REYES CCN-1150
                    //Any character case (uuper/lower) difference makes the comparison of 2 email address distinct. So convert both to lower cases before comparing to avoid duplicates.
                    sessionPart.Email = sessionPart.Email.toLowerCase();
                    conRecord.Email = sessionPart.Email;

                    if(!emailToInsertContactMap.containsKey(sessionPart.Email)){
                        emailToInsertContactMap.put(sessionPart.Email,conRecord);
                    }

                    //Participant
                    Participant__c participant = new Participant__c();
                    participant.Event__c = eventId;
                    participant.Member_Contact__c = null;

                    // updated 06/18/2021 - Status will be updated to Responded/Attended/Canceled based on the inserted and current Session Participant/s related to it.
                    /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
                    //participant.Status__c = 'In Progress';
                    
                    participant.Session_Modified__c = true;
                    participant.Rank__c = sessionPart.Rank;
                    participant.Process_from_Event_Page__c = true;
                    if(!emailToInsertParticipantMap.containsKey(sessionPart.Email)){
                        emailToInsertParticipantMap.put(sessionPart.Email,participant);
                    }

                    //Session Participants
                    Session_Participant__c sessionRec = new Session_Participant__c();
                    sessionRec.Participant__c = null;
                    sessionRec.Event__c = eventId;
                    sessionRec.Session__c = sessId;
                    sessionRec.Contact__c = null;
                    sessionRec.Branch_of_Service__c = sessionPart.BranchOfService; //XEN REYES March 5, 2023 CCN-EVE-2631-DV
                    sessionRec.Rank__c = sessionPart.Rank;
                    sessionRec.Role__c = sessionPart.Role;
                    sessionRec.Role_Description__c = roleDescriptionMap.get(sessionPart.Role);
                    if(!emailToInsertSessionPartMap.containsKey(sessionPart.Email+':'+sessionPart.Role)){
                        emailToInsertSessionPartMap.put(sessionPart.Email+':'+sessionPart.Role,sessionRec);
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

                    //XEN REYES CCN-2607 16-Feb-2023
                    /* if(String.isBlank(sessionPart.Rank) || sessionPart.Rank =='--None--'){
                        count++;
                        fieldList.add('Rank');
                    } */
                    
                    if(String.isBlank(sessionPart.Email)){
                        count++;
                        fieldList.add('Email');
                    }

                    //XEN REYES CCN-2607 16-Feb-2023
                    if(count < 3){
                        message = 'Error registering session participants. Please populate all fields. Missing: ' + fieldList + ' on ' + ' one of the ' + sessionPart.Role + 's';
                        return message;
                    }
                }
            }

            //Check for Exsting Session Participants
            if(!sessionIdMap.isEmpty()){
                for(Session_Participant__c sessionRec : withoutShare.getSessionPartOnSave(sessionIdMap,sessId)){
                    // Start CCN-EVE-2067-DV: Von Pernicia - Added sessionRec.Contact__r.Email
                    if(sessionRec.Contact__r.FirstName != sessionIdMap.get(sessionRec.Id).FirstName 
                    || sessionRec.Contact__r.LastName != sessionIdMap.get(sessionRec.Id).LastName
                    || sessionRec.Contact__r.Email != sessionIdMap.get(sessionRec.Id).Email) {
                    // End CCN-EVE-2067-DV: Von Pernicia - Added sessionRec.Contact__r.Email
                        Session_Participant__c updateRec = new Session_Participant__c();
                        updateRec.Id = sessionRec.Id;
                        updateRec.Status__c = 'Canceled';
                        sessionPartToUpdate.add(updateRec);
                    }else if(sessionRec.Rank__c != sessionIdMap.get(sessionRec.Id).Rank){
                        Session_Participant__c updateRec = new Session_Participant__c();
                        updateRec.Id = sessionRec.Id;
                        updateRec.Branch_of_Service__c = sessionIdMap.get(sessionRec.Id).BranchOfService; //XEN REYES March 5, 2023 CCN-EVE-2631-DV
                        updateRec.Rank__c = sessionIdMap.get(sessionRec.Id).Rank;
                        sessionPartToUpdate.add(updateRec);

                        Participant__c participant = new Participant__c();
                        participant.Id = sessionRec.Participant__c;
                        participant.Rank__c = sessionIdMap.get(sessionRec.Id).Rank;
                        partToUpdate.add(participant);

                        //emailToInsertContactMap.remove(sessionIdMap.get(sessionRec.Id).Email);
                        //emailToInsertParticipantMap.remove(sessionIdMap.get(sessionRec.Id).Email);
                        //emailToInsertSessionPartMap.remove(sessionIdMap.get(sessionRec.Id).Email+'-'+sessionIdMap.get(sessionRec.Id).Role);
                    }else{
                        //emailToInsertContactMap.remove(sessionIdMap.get(sessionRec.Id).Email);
                        //emailToInsertParticipantMap.remove(sessionIdMap.get(sessionRec.Id).Email);
                        //emailToInsertSessionPartMap.remove(sessionIdMap.get(sessionRec.Id).Email+'-'+sessionIdMap.get(sessionRec.Id).Role);
                    }
                }
            }

            //Check for Existing Contacts based on Email, Insert those new Contacts and Get Ids of Existing Ones
            message = checkForExistingContacts(emailToInsertContactMap,emailContactIdMap, message);
            if(message != '') return message;

            //Check for Existing Participants based on existing contacts, Insert those new Participants and Get Ids of Existing Ones. Link to Contacts
            checkForExistingParticipants(eventId,emailToInsertParticipantMap,emailParticipantIdMap,emailToInsertContactMap,emailContactIdMap);

            //Check for Existing Session Participant based on Exising Participants of the Event, Insert those new Session Participants. Link to Participants
            checkForExistingSessionPart(emailParticipantIdMap,emailContactIdMap,emailToInsertSessionPartMap,
                    sessionPartToUpdate,emailToInsertParticipantMap,emailToInsertContactMap,sessId);

            //Update Session Participants
            if(!sessionPartToUpdate.isEmpty()){
                withoutShare.updateSessPart(sessionPartToUpdate);
            }

            //Update Participants
            if(!partToUpdate.isEmpty()){
                withoutShare.updatePart(partToUpdate);
            }

        }catch(Exception e){
            UTIL_LoggingService.logHandledException(e);
        }

        return message;
    }

    public static String checkForExistingContacts(Map<String, Contact> emailToInsertContactMap,Map<String, Id> emailContactIdMap, String message){
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        for(Contact conRec : withoutShare.getContactOnSave(emailToInsertContactMap)){
            if(emailToInsertContactMap.containsKey(conRec.Email)){
                //Remove From Contacts to Insert
                //if(!(conRec.FirstName).equalsIgnoreCase(emailToInsertContactMap.get(conRec.Email).FirstName) || !(conRec.LastName).equalsIgnoreCase(emailToInsertContactMap.get(conRec.Email).LastName)){
                //return 'Error registering session participants. Name and Email mismatch, duplicate found';
                emailToInsertContactMap.remove(conRec.Email);
                existingContactMap.put(conRec.Email, conRec);
                //}
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

    public static void checkForExistingParticipants(Id eventId, Map<String, Participant__c> emailToInsertParticipantMap, Map<String, Id> emailParticipantIdMap,
            Map<String, Contact> emailToInsertContactMap,Map<String, Id> emailContactIdMap){
        for(Participant__c partRec : withoutShare.getParticipantsOnSave(eventId,emailContactIdMap)){
            //Remove From Participants to Insert
            emailToInsertParticipantMap.remove(partRec.Member_Contact__r.Email);

            //Add to Email - Contact Id Mapping
            if(!emailParticipantIdMap.containsKey(partRec.Member_Contact__r.Email)){
                emailParticipantIdMap.put(partRec.Member_Contact__r.Email, partRec.Id);
            }
        }

        //Link Participant to Contacts then Insert
        if(!emailToInsertParticipantMap.isEmpty()){
            for(String emailStr : emailToInsertParticipantMap.keySet()){
                if(emailContactIdMap.containsKey(emailStr)){
                    emailToInsertParticipantMap.get(emailStr).Member_Contact__c = emailContactIdMap.get(emailStr);
                }else if(emailToInsertContactMap.containsKey(emailStr)){
                    emailToInsertParticipantMap.get(emailStr).Member_Contact__c = emailToInsertContactMap.get(emailStr).Id;
                }
            }

            withoutShare.insertPart(emailToInsertParticipantMap);
        }
    }

    /*******************************************************************************************
    * @name: checkForExistingSessionPart
    * @author: ??
    * @created: ??
    * @description:
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *             2.0   17-06-2022           Von Pernicia         [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
    *******************************************************************************************/
    public static void checkForExistingSessionPart(Map<String, Id> emailParticipantIdMap,Map<String, Id> emailContactIdMap,
            Map<String, Session_Participant__c> emailToInsertSessionPartMap,List<Session_Participant__c> sessionPartToUpdate,
            Map<String, Participant__c> emailToInsertParticipantMap,Map<String, Contact> emailToInsertContactMap, String sessId){
        for(Session_Participant__c sessPart : withoutShare.getSessionPartOnSave2(emailContactIdMap,emailParticipantIdMap,sessId)){
            //Remove From Contacts to Insert
            Session_Participant__c updateRec = new Session_Participant__c();
            updateRec.Id = sessPart.Id;
            updateRec.Status__c = 'Registered';
            if(emailToInsertSessionPartMap.containsKey(sessPart.Contact__r.Email+':'+sessPart.Role__c)){
                updateRec.Role__c = (emailToInsertSessionPartMap.get(sessPart.Contact__r.Email+':'+sessPart.Role__c)).Role__c;
                updateRec.Rank__c = (emailToInsertSessionPartMap.get(sessPart.Contact__r.Email+':'+sessPart.Role__c)).Rank__c;
            }
            if(sessPart.Status__c == 'Canceled' && emailToInsertSessionPartMap.containsKey(sessPart.Contact__r.Email+':'+sessPart.Role__c)){
                sessionPartToUpdate.add(updateRec);
            }
            emailToInsertSessionPartMap.remove(sessPart.Contact__r.Email+':'+sessPart.Role__c);
        }

        //Link Session Participant to Contact and Participant then Insert
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
                    emailToInsertSessionPartMap.get(emailStr).Participant__c = emailParticipantIdMap.get(emailStr.substringBefore(':'));
                }else if(emailToInsertParticipantMap.containsKey(emailStr.substringBefore(':'))){
                    emailToInsertSessionPartMap.get(emailStr).Participant__c = emailToInsertParticipantMap.get(emailStr.substringBefore(':')).Id;
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

        public void insertPart(Map<String, Participant__c> emailToInsertParticipantMap){
            insert emailToInsertParticipantMap.values();
        }

        public void insertSessPart(Map<String, Session_Participant__c> emailToInsertSessionPartMap){
            insert emailToInsertSessionPartMap.values();
        }

        public void updateSessPart(List<Session_Participant__c> sessionPartToUpdate){
            update sessionPartToUpdate;
        }

        public void updatePart(List<Participant__c> partToUpdate){
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
        * @author: ??
        * @created: ??
        * @description: Method to get the Session Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        * 			  2.0   07-07-2022			Edison Crisostomo	  [CCN-EVE-14-DV] Updated Query
        *             2.0   24-05-2023			JC ESPINO	          [CCN-EVE-2870-DV] Updated Query
        *********************************************************************************************/
        public Session__c getSessionDetails(String sessId) {
            // Updated by Edison Crisostomo [CCN-EVE-14-DV] 07/07/2022
            // UPDATED by JC ESPINO [CCN-EVE-2870-DV] 24/05/23
            return [SELECT Id, Name, Start_Date_Time_2__c,Start_Date_Time2__c,End_Date_Time2__c, Event__r.Name,Location__c, Time_Zone__c FROM Session__c WHERE Id =: sessId LIMIT 1];
        }

        public String getEventDetailsIdWS(String sessId) {
            return [SELECT Id, Name, Start_Date_Time_2__c, Event__r.Event_Id__c FROM Session__c WHERE Id =: sessId LIMIT 1].Event__r.Event_Id__c;
        }

        /*******************************************************************************************
        * @name: getSessionParticipants
        * @author: ??
        * @created: ??
        * @description: Method to get the Session participant Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0  17-06-2022           Von Pernicia               [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
        *             3.0  17-07-2022           Rexie Aaron David     [CCN-EVE-14-DV] - Updated getSessionParticipants - Order By Created Date ASC
        *********************************************************************************************/
        public List<Session_Participant__c> getSessionParticipants(String sessId){

            //XEN REYES CCN-2607 16-Feb-2023, XEN REYES March 5, 2023 CCN-EVE-2631-DV
            return [SELECT Id, Rank__c, Branch_of_Service__c, Role__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email FROM Session_Participant__c
            WHERE Session__c =: sessId AND Role__c != null AND Contact__c != null AND Status__c != 'Canceled'
            ORDER BY CreatedDate ASC];
        }

        //Start CCN-EVE-2067-DV Xen Reyes
        public List<Session_Role__c> getSessionRoles(String sessId){
            return [SELECT Id, Role_Title__c, Role_Description__c, Number_of_Role__c, Session__c, Session__r.Sign_Up_Instructions_2__c,Name FROM
                    Session_Role__c WHERE Session__c =: sessId ORDER BY Name ASC];
        }
        //End CCN-EVE-2067-DV Xen Reyes

        public Id getEventIdOnSave(String sessId){
            return [SELECT Id, Event__c FROM Session__c WHERE Id =: sessId LIMIT 1].Event__c;
        }

        /*******************************************************************************************
        * @name: Contact__r
        * @author: ??
        * @created: ??
        * @description: Method to get the Session participant Detail
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0  22-08-2022           Von Pernicia           [CCN-EVE-2067-DV] - added Contact__r.Email
        *********************************************************************************************/
        public List<Session_Participant__c> getSessionPartOnSave(Map<Id, sessionParticipantWrapper> sessionIdMap, String sessId){
            return [SELECT Id, Rank__c, Participant__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email FROM Session_Participant__c WHERE ID IN :sessionIdMap.keySet()
            AND Session__c =: sessId];
        }

        public List<Contact> getContactOnSave(Map<String, Contact> emailToInsertContactMap){
            return [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Email IN :emailToInsertContactMap.keySet() ORDER BY LastModifiedDate DESC ];
        }

        public List<Participant__c> getParticipantsOnSave(Id eventId, Map<String, Id> emailContactIdMap){
            return [SELECT Id, Name, Status__c, Member_Contact__c, Member_Contact__r.Email FROM Participant__c WHERE Event__c =: eventId AND
            Member_Contact__c IN :emailContactIdMap.values()];
        }

        public List<Session_Participant__c> getSessionPartOnSave2(Map<String, Id> emailContactIdMap,Map<String, Id> emailParticipantIdMap, String sessId){
            return [SELECT Id, Status__c, Contact__r.Email, Role__c FROM Session_Participant__c WHERE Contact__c IN: emailContactIdMap.values() AND
            Participant__c IN: emailParticipantIdMap.values() AND Session__c =: sessId];
        }

        /*******************************************************************************************
        * @name: updatePartSession
        * @author: ??
        * @created: ??
        * @description: Update sessision participant to Canceled
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0  17-06-2022           Von Pernicia               [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
        *********************************************************************************************/
        public void updatePartSession(String partSessionId){
            Session_Participant__c partSessionRec = [Select Status__c from Session_Participant__c where Id =: partSessionId];
            partSessionRec.Status__c = 'Canceled';
            update partSessionRec;
        }
        
        
        /*******************************************************************************************
        * @name: getEvents
        * @author: Leif Erickson de Gracia
        * @created: Sept 5, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
        public List < Event__c > getEvents(String campaignId, String additionalFieldsToQuery) {
            String strQuery = 'SELECT Id, Name, Registration_Tag_Line__c, Registration_Message__c, Registration_Fields_JSON__c ' + additionalFieldsToQuery + 'FROM Event__c WHERE Event_Id__c =: campaignId';
            return Database.query(strQuery);
        }
        
    }
    
    /*******************************************************************************************
        * @name: resultWrapper
        * @author: Leif Erickson de Gracia
        * @created: Sept 5, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    public class resultWrapper {
        @AuraEnabled public Map < String, String > DefaultFieldValueMapping {
            get;
            set;
        }
        @AuraEnabled public List < RegistrationFields > registrationFieldList {
            get;
            set;
        }
    }

    public class mainWrapper{
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String signUpInstructions {get;set;}
        @AuraEnabled public String hasData {get;set;}
        @AuraEnabled public List<sessionParticipantWrapper> tableValues {get;set;}
    }

    public class sessionParticipantWrapper{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String Role {get;set;}
        @AuraEnabled public String RoleDescription {get;set;}
        @AuraEnabled public String RoleAndDesc {get;set;}
        @AuraEnabled public String Rank {get;set;}
        @AuraEnabled public String BranchOfService {get;set;} //XEN REYES March 5, 2023 CCN-EVE-2631-DV
        @AuraEnabled public String FirstName {get;set;}
        @AuraEnabled public String LastName {get;set;}
        @AuraEnabled public String Email {get;set;}
    }

    @AuraEnabled
    public static void removeRole(String partSessionId) {
        withoutShare.updatePartSession(partSessionId);
    }
}